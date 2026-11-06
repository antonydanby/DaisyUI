unit Daisy.FMX.MenuPopup;

{
  Shared drawing and the cascading popup used by TDaisyFmxMenu,
  TDaisyFmxMainMenu and TDaisyFmxPopupMenu.

  * TDaisyFmxMenuSurface - a TDaisyControl that knows how to measure and draw one
    menu row (icon, caption, badge, short cut, check mark, sub menu chevron).
  * TDaisyFmxMenuPopup   - an overlay control parented to the form (no separate
    window, so it behaves the same on every FMX platform). The root popup owns
    the mouse capture and routes the mouse to whichever cascaded sub menu is
    under it.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Graphics, FMX.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.FMX.Control;

type
  TDaisyFmxPointEvent = procedure(Sender: TObject; const APoint: TPointF) of object;

  TDaisyFmxMenuSurface = class(TDaisyControl)
  protected
    function MenuRowHeight(AItem: TDaisyMenuItem; AIconPx: Integer): Single;
    function MenuRowWidth(AItem: TDaisyMenuItem; const AStyle: TDaisyMenuRowStyle): Single;
    procedure DrawMenuRow(AItem: TDaisyMenuItem; const ARect: TRectF;
      const AStyle: TDaisyMenuRowStyle);
    function MenuNeedsIconSlot(AItems: TDaisyMenuItems): Boolean;
  end;

  TDaisyFmxMenuPopup = class(TDaisyFmxMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FShown: TList<TDaisyMenuItem>;
    FRects: TArray<TRectF>;
    FIconPx: Integer;
    FReserve: Boolean;
    FHot: Integer;
    FParentPopup: TDaisyFmxMenuPopup;
    FChild: TDaisyFmxMenuPopup;
    FChildSource: TDaisyMenuItem;
    FOnItemClick: TDaisyMenuItemEvent;
    FOnClosed: TNotifyEvent;
    FOnOutsideMove: TDaisyFmxPointEvent;
    function ItemAt(const APoint: TPointF): Integer;
    function RootPopup: TDaisyFmxMenuPopup;
    function Deepest(const AAbs: TPointF): TDaisyFmxMenuPopup;
    function ContainsAbs(const AAbs: TPointF): Boolean;
    procedure SetHot(AIndex: Integer);
    procedure HideChain;
    procedure OpenChild(AIndex: Integer);
    procedure CloseChild;
    procedure HandleMove(const AAbs: TPointF);
    procedure HandleUp(const AAbs: TPointF);
    procedure Place(const AAnchor: TRectF; ABelow: Boolean; AGap: Single; AForm: TCommonCustomForm);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // AAnchor is in form coordinates. ABelow: show under it (else beside it, as a sub menu)
    procedure Popup(AForm: TCommonCustomForm; AItems: TDaisyMenuItems; AIconPx: Integer;
      const AAnchor: TRectF; ABelow: Boolean; AGap: Single = 2);
    // Closes this popup and every sub menu
    procedure CloseAll;
    function IsOpen: Boolean;
    property OnItemClick: TDaisyMenuItemEvent read FOnItemClick write FOnItemClick;
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    // Mouse moves that land outside every popup (the owner may react, e.g. a menu bar)
    property OnOutsideMove: TDaisyFmxPointEvent read FOnOutsideMove write FOnOutsideMove;
  end;

implementation

{ TDaisyFmxMenuSurface }

function TDaisyFmxMenuSurface.MenuNeedsIconSlot(AItems: TDaisyMenuItems): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to AItems.Count - 1 do
    if AItems[I].Visible and (not AItems[I].Icon.IsEmpty or AItems[I].Checked or
      AItems[I].AutoCheck or ((AItems[I].Items.Count > 0) and
      MenuNeedsIconSlot(AItems[I].Items))) then
      Exit(True);
end;

function TDaisyFmxMenuSurface.MenuRowHeight(AItem: TDaisyMenuItem; AIconPx: Integer): Single;
begin
  if AItem.IsSeparator then
    Exit(9);
  Result := DaisyMenuRowHeight(SizeKind);
  if not AItem.Icon.IsEmpty then
    Result := Max(Result, AIconPx + 8);
end;

function TDaisyFmxMenuSurface.MenuRowWidth(AItem: TDaisyMenuItem;
  const AStyle: TDaisyMenuRowStyle): Single;
var
  LFont: Integer;
begin
  LFont := DaisyFontSize(SizeKind);
  if AStyle.IconsOnly then
    Exit(Max(DaisyMenuRowHeight(SizeKind), AStyle.IconPx + 20));
  Result := 20 + MeasureTextWidth(AItem.Caption, LFont, AItem.Title);
  if AStyle.ReserveIcon then
    Result := Result + AStyle.IconPx + 8;
  if AStyle.ShowExtras then
  begin
    if AItem.ShortCut <> '' then
      Result := Result + 24 + MeasureTextWidth(AItem.ShortCut, LFont - 1, False);
    if AItem.Badge <> '' then
      Result := Result + 22 + MeasureTextWidth(AItem.Badge, LFont - 2, False);
  end;
  if AStyle.Chevron <> mcNone then
    Result := Result + 24;
end;

procedure TDaisyFmxMenuSurface.DrawMenuRow(AItem: TDaisyMenuItem; const ARect: TRectF;
  const AStyle: TDaisyMenuRowStyle);
var
  LText, LFillColor: TAlphaColor;
  LFont: Integer;
  LX, LR, LTextW, LBadgeW: Single;
  LBox: TRectF;
  LFill: Boolean;
  LPath: string;
  LMidY: Single;
begin
  LFont := DaisyFontSize(SizeKind);
  LMidY := (ARect.Top + ARect.Bottom) / 2;
  if AItem.IsSeparator then
  begin
    FillRound(RectF(ARect.Left + 10, LMidY, ARect.Right - 10, LMidY + 1), 0,
      DaisyWithAlpha(Theme.BaseContent, 0.15));
    Exit;
  end;
  if AItem.Title then
  begin
    DrawText(AItem.Caption, RectF(ARect.Left + 10, ARect.Top, ARect.Right - 10, ARect.Bottom),
      DaisyWithAlpha(Theme.BaseContent, 0.55), LFont - 1, True, TTextAlign.Leading,
      TTextAlign.Center, False);
    Exit;
  end;

  LText := Theme.BaseContent;
  LFill := False;
  LFillColor := 0;
  if AStyle.Active then
  begin
    LFill := True;
    LFillColor := Theme.Neutral;
    LText := Theme.NeutralContent;
  end
  else if AStyle.Hot and AItem.Enabled then
  begin
    LFill := True;
    LFillColor := DaisyWithAlpha(Theme.BaseContent, 0.1);
  end;
  if LFill then
    FillRound(ARect, Theme.RadiusField, LFillColor);
  if not AItem.Enabled then
    LText := DaisyWithAlpha(LText, 0.3);

  if AStyle.IconsOnly then
  begin
    LBox := RectF(0, 0, AStyle.IconPx, AStyle.IconPx);
    LBox.SetLocation(ARect.Left + (ARect.Width - LBox.Width) / 2,
      ARect.Top + (ARect.Height - LBox.Height) / 2);
    if AItem.Icon.IsEmpty then
      DrawText(Copy(AItem.Caption, 1, 1), ARect, LText, LFont, True, TTextAlign.Center,
        TTextAlign.Center, False)
    else
      DrawGlyph(AItem.Icon, LBox, LText);
    Exit;
  end;

  LX := ARect.Left + 10;
  LR := ARect.Right - 10;
  if AStyle.ReserveIcon then
  begin
    LBox := RectF(0, 0, AStyle.IconPx, AStyle.IconPx);
    LBox.SetLocation(LX, LMidY - AStyle.IconPx / 2);
    if not AItem.Icon.IsEmpty then
      DrawGlyph(AItem.Icon, LBox, LText)
    else if AItem.Checked then
    begin
      LBox.Inflate(-AStyle.IconPx / 5, -AStyle.IconPx / 5);
      DrawIconPath(CMenuCheckPath, LBox, LText);
    end;
    LX := LX + AStyle.IconPx + 8;
  end;

  if AStyle.Chevron <> mcNone then
  begin
    LBox := RectF(LR - 12, LMidY - 6, LR, LMidY + 6);
    case AStyle.Chevron of
      mcRight: LPath := CMenuRightPath;
      mcDown: LPath := CMenuDownPath;
    else
      LPath := CMenuUpPath;
    end;
    DrawIconPath(LPath, LBox, DaisyWithAlpha(LText, 0.7));
    LR := LR - 20;
  end;

  if AStyle.ShowExtras then
  begin
    if AItem.Checked and not AItem.Icon.IsEmpty then
    begin
      DrawIconPath(CMenuCheckPath, RectF(LR - 14, LMidY - 7, LR, LMidY + 7), LText);
      LR := LR - 22;
    end;
    if AItem.ShortCut <> '' then
    begin
      LTextW := MeasureTextWidth(AItem.ShortCut, LFont - 1, False);
      DrawText(AItem.ShortCut, RectF(LR - LTextW - 2, ARect.Top, LR, ARect.Bottom),
        DaisyWithAlpha(LText, 0.55), LFont - 1, False, TTextAlign.Trailing, TTextAlign.Center,
        False);
      LR := LR - LTextW - 16;
    end;
    if AItem.Badge <> '' then
    begin
      LBadgeW := MeasureTextWidth(AItem.Badge, LFont - 2, False) + 14;
      LBox := RectF(LR - LBadgeW, LMidY - (LFont + 4) / 2, LR, LMidY + (LFont + 4) / 2);
      FillRound(LBox, LBox.Height / 2, DaisyWithAlpha(Theme.BaseContent, 0.12));
      DrawText(AItem.Badge, LBox, LText, LFont - 2, False, TTextAlign.Center,
        TTextAlign.Center, False);
      LR := LR - LBadgeW - 8;
    end;
  end;

  DrawText(AItem.Caption, RectF(LX, ARect.Top, Max(LX, LR), ARect.Bottom), LText, LFont, False,
    TTextAlign.Leading, TTextAlign.Center, False);
end;

{ TDaisyFmxMenuPopup }

constructor TDaisyFmxMenuPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FShown := TList<TDaisyMenuItem>.Create;
  FHot := -1;
  Visible := False;
  CanFocus := False;
  AutoCapture := False;
end;

destructor TDaisyFmxMenuPopup.Destroy;
begin
  FShown.Free;
  inherited Destroy;
end;

function TDaisyFmxMenuPopup.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxMenuPopup.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxMenuPopup.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.15);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxMenuPopup.IsOpen: Boolean;
begin
  Result := Visible;
end;

function TDaisyFmxMenuPopup.RootPopup: TDaisyFmxMenuPopup;
begin
  Result := Self;
  while Result.FParentPopup <> nil do
    Result := Result.FParentPopup;
end;

function TDaisyFmxMenuPopup.ContainsAbs(const AAbs: TPointF): Boolean;
begin
  Result := Visible and AbsoluteRect.Contains(AAbs);
end;

function TDaisyFmxMenuPopup.Deepest(const AAbs: TPointF): TDaisyFmxMenuPopup;
begin
  Result := nil;
  if (FChild <> nil) and FChild.Visible then
    Result := FChild.Deepest(AAbs);
  if (Result = nil) and ContainsAbs(AAbs) then
    Result := Self;
end;

function TDaisyFmxMenuPopup.ItemAt(const APoint: TPointF): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FRects) do
    if FRects[I].Contains(APoint) then
      Exit(I);
end;

procedure TDaisyFmxMenuPopup.SetHot(AIndex: Integer);
var
  LItem: TDaisyMenuItem;
begin
  if AIndex = FHot then
    Exit;
  FHot := AIndex;
  if FHot >= 0 then
  begin
    LItem := FShown[FHot];
    if (FChild <> nil) and (FChildSource <> LItem) then
      CloseChild;
    if LItem.HasChildren and LItem.Enabled and not LItem.Title and (FChildSource <> LItem) then
      OpenChild(FHot);
  end;
  Repaint;
end;

procedure TDaisyFmxMenuPopup.OpenChild(AIndex: Integer);
var
  LAnchor: TRectF;
  LForm: TCommonCustomForm;
begin
  if (Root = nil) or not (Root.GetObject is TCommonCustomForm) then
    Exit;
  LForm := TCommonCustomForm(Root.GetObject);
  if FChild = nil then
  begin
    FChild := TDaisyFmxMenuPopup.Create(Self);
    FChild.FParentPopup := Self;
  end;
  FChild.ThemeKind := ThemeKind;
  FChild.SizeKind := SizeKind;
  FChildSource := FShown[AIndex];
  LAnchor.TopLeft := LocalToAbsolute(FRects[AIndex].TopLeft);
  LAnchor.BottomRight := LocalToAbsolute(FRects[AIndex].BottomRight);
  FChild.Popup(LForm, FChildSource.Items, FIconPx, LAnchor, False, 0);
end;

procedure TDaisyFmxMenuPopup.CloseChild;
begin
  if FChild <> nil then
    FChild.HideChain;
  FChildSource := nil;
end;

procedure TDaisyFmxMenuPopup.HideChain;
begin
  CloseChild;
  FHot := -1;
  Visible := False;
end;

procedure TDaisyFmxMenuPopup.CloseAll;
var
  LRoot: TDaisyFmxMenuPopup;
  WasOpen: Boolean;
begin
  LRoot := RootPopup;
  WasOpen := LRoot.Visible;
  if WasOpen then
    LRoot.ReleaseCapture;
  LRoot.HideChain;
  if WasOpen and Assigned(LRoot.FOnClosed) then
    LRoot.FOnClosed(LRoot);
end;

procedure TDaisyFmxMenuPopup.Place(const AAnchor: TRectF; ABelow: Boolean; AGap: Single;
  AForm: TCommonCustomForm);
var
  LX, LY: Single;
begin
  if ABelow then
  begin
    LX := AAnchor.Left;
    LY := AAnchor.Bottom + AGap;
    if LX + Width > AForm.ClientWidth then
      LX := Max(0, AForm.ClientWidth - Width);
    if LY + Height > AForm.ClientHeight then
      LY := Max(0, AAnchor.Top - Height - AGap); // flip above
  end
  else
  begin
    LX := AAnchor.Right;
    LY := AAnchor.Top - 6;
    if LX + Width > AForm.ClientWidth then
      LX := Max(0, AAnchor.Left - Width); // flip to the other side
    if LY + Height > AForm.ClientHeight then
      LY := Max(0, AForm.ClientHeight - Height);
  end;
  Position.Point := PointF(LX, LY);
end;

procedure TDaisyFmxMenuPopup.Popup(AForm: TCommonCustomForm; AItems: TDaisyMenuItems;
  AIconPx: Integer; const AAnchor: TRectF; ABelow: Boolean; AGap: Single);
const
  CPad = 6;
var
  I: Integer;
  LWidth, LY, LHeight: Single;
  LStyle: TDaisyMenuRowStyle;
begin
  FItems := AItems;
  FIconPx := AIconPx;
  FReserve := MenuNeedsIconSlot(AItems);
  FShown.Clear;
  for I := 0 to AItems.Count - 1 do
    if AItems[I].Visible then
      FShown.Add(AItems[I]);
  if FShown.Count = 0 then
    Exit;
  FHot := -1;
  FChildSource := nil;

  LStyle := Default(TDaisyMenuRowStyle);
  LStyle.IconPx := AIconPx;
  LStyle.ReserveIcon := FReserve;
  LStyle.ShowExtras := True;
  LWidth := 160;
  LY := CPad;
  SetLength(FRects, FShown.Count);
  for I := 0 to FShown.Count - 1 do
  begin
    if FShown[I].HasChildren and not FShown[I].Title then
      LStyle.Chevron := mcRight
    else
      LStyle.Chevron := mcNone;
    LWidth := Max(LWidth, MenuRowWidth(FShown[I], LStyle) + 2 * CPad);
    LHeight := MenuRowHeight(FShown[I], AIconPx);
    FRects[I] := RectF(CPad, LY, 0, LY + LHeight);
    LY := LY + LHeight;
  end;
  for I := 0 to High(FRects) do
    FRects[I].Right := LWidth - CPad;
  if Parent <> AForm then
    AForm.AddObject(Self);
  Width := LWidth;
  Height := LY + CPad;
  Place(AAnchor, ABelow, AGap, AForm);
  Visible := True;
  BringToFront;
  if FParentPopup = nil then
    Capture;
  Repaint;
end;

procedure TDaisyFmxMenuPopup.HandleMove(const AAbs: TPointF);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(AbsoluteToLocal(AAbs));
  if (LIndex >= 0) and (FShown[LIndex].IsSeparator or FShown[LIndex].Title) then
    LIndex := -1;
  SetHot(LIndex);
end;

procedure TDaisyFmxMenuPopup.HandleUp(const AAbs: TPointF);
var
  LIndex: Integer;
  LItem: TDaisyMenuItem;
  LRoot: TDaisyFmxMenuPopup;
begin
  LIndex := ItemAt(AbsoluteToLocal(AAbs));
  if LIndex < 0 then
    Exit;
  LItem := FShown[LIndex];
  if LItem.IsSeparator or LItem.Title or not LItem.Enabled then
    Exit;
  if LItem.HasChildren then
  begin
    if FChildSource <> LItem then
      OpenChild(LIndex);
    Exit;
  end;
  LRoot := RootPopup;
  CloseAll;
  LItem.Click;
  if Assigned(LRoot.FOnItemClick) then
    LRoot.FOnItemClick(LRoot, LItem);
end;

procedure TDaisyFmxMenuPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Deepest(LocalToAbsolute(PointF(X, Y))) = nil then
    CloseAll;
end;

procedure TDaisyFmxMenuPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LTarget: TDaisyFmxMenuPopup;
  LPoint: TPointF;
begin
  if Button <> TMouseButton.mbLeft then
    Exit;
  LPoint := LocalToAbsolute(PointF(X, Y));
  LTarget := Deepest(LPoint);
  if LTarget <> nil then
    LTarget.HandleUp(LPoint);
end;

procedure TDaisyFmxMenuPopup.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LTarget: TDaisyFmxMenuPopup;
  LPoint: TPointF;
begin
  inherited;
  LPoint := LocalToAbsolute(PointF(X, Y));
  LTarget := Deepest(LPoint);
  if LTarget <> nil then
    LTarget.HandleMove(LPoint)
  else if Assigned(FOnOutsideMove) then
    FOnOutsideMove(Self, LPoint);
end;

procedure TDaisyFmxMenuPopup.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  I: Integer;
  LStyle: TDaisyMenuRowStyle;
begin
  LStyle := Default(TDaisyMenuRowStyle);
  LStyle.IconPx := FIconPx;
  LStyle.ReserveIcon := FReserve;
  LStyle.ShowExtras := True;
  for I := 0 to FShown.Count - 1 do
  begin
    LStyle.Hot := I = FHot;
    if FShown[I].HasChildren and not FShown[I].Title then
      LStyle.Chevron := mcRight
    else
      LStyle.Chevron := mcNone;
    DrawMenuRow(FShown[I], FRects[I], LStyle);
  end;
end;

end.
