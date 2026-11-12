unit Daisy.VCL.MenuPopup;

{
  Shared drawing and the cascading popup window used by TDaisyMenu,
  TDaisyMainMenu and TDaisyPopupMenu.

  * TDaisyMenuSurface - a TDaisyControl that knows how to measure and draw one
    menu row (icon, caption, badge, short cut, check mark, sub menu chevron).
  * TDaisyMenuPopup   - a borderless, non-activating window listing a level of
    menu items. The root popup owns the mouse capture and routes the mouse to
    whichever cascaded sub menu is under it.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.VCL.Control;

type
  TDaisyScreenPointEvent = procedure(Sender: TObject; const APoint: TPoint) of object;

  TDaisyMenuSurface = class(TDaisyControl)
  protected
    function MenuRowHeight(AItem: TDaisyMenuItem; AIconPx: Integer): Integer;
    function MenuRowWidth(AItem: TDaisyMenuItem; const AStyle: TDaisyMenuRowStyle): Integer;
    procedure DrawMenuRow(AItem: TDaisyMenuItem; const ARect: TRect;
      const AStyle: TDaisyMenuRowStyle);
    function MenuNeedsIconSlot(AItems: TDaisyMenuItems): Boolean;
  end;

  TDaisyMenuPopup = class(TDaisyMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FShown: TList<TDaisyMenuItem>;
    FRects: TArray<TRect>;
    FIconPx: Integer;
    FReserve: Boolean;
    FHot: Integer;
    FParentPopup: TDaisyMenuPopup;
    FChild: TDaisyMenuPopup;
    FChildSource: TDaisyMenuItem;
    FOnItemClick: TDaisyMenuItemEvent;
    FOnClosed: TNotifyEvent;
    FOnOutsideMove: TDaisyScreenPointEvent;
    FInButtonUp: Boolean;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    function Pad: Integer;
    function ItemAt(const APoint: TPoint): Integer;
    function Root: TDaisyMenuPopup;
    function Deepest(const AScreen: TPoint): TDaisyMenuPopup;
    function ContainsScreen(const AScreen: TPoint): Boolean;
    procedure SetHot(AIndex: Integer);
    procedure HideChain;
    procedure OpenChild(AIndex: Integer);
    procedure CloseChild;
    procedure HandleMove(const AScreen: TPoint);
    procedure HandleUp(const AScreen: TPoint);
    procedure Place(const AAnchor: TRect; ABelow: Boolean; AGap: Integer);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // AAnchor is in screen coordinates. ABelow: show under it (else beside it, as a sub menu)
    procedure Popup(AItems: TDaisyMenuItems; AIconPx: Integer; const AAnchor: TRect;
      ABelow: Boolean; AGap: Integer = 2);
    // Closes this popup and every sub menu
    procedure CloseAll;
    function IsOpen: Boolean;
    property OnItemClick: TDaisyMenuItemEvent read FOnItemClick write FOnItemClick;
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    // Mouse moves that land outside every popup (the owner may react, e.g. a menu bar)
    property OnOutsideMove: TDaisyScreenPointEvent read FOnOutsideMove write FOnOutsideMove;
  end;

implementation

{ TDaisyMenuSurface }

function TDaisyMenuSurface.MenuNeedsIconSlot(AItems: TDaisyMenuItems): Boolean;
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

function TDaisyMenuSurface.MenuRowHeight(AItem: TDaisyMenuItem; AIconPx: Integer): Integer;
begin
  if AItem.IsSeparator then
    Exit(ScaleValue(9));
  Result := ScaleValue(DaisyMenuRowHeight(SizeKind));
  if not AItem.Icon.IsEmpty then
    Result := Max(Result, ScaleValue(AIconPx + 8));
end;

function TDaisyMenuSurface.MenuRowWidth(AItem: TDaisyMenuItem;
  const AStyle: TDaisyMenuRowStyle): Integer;
var
  LPad, LFont: Integer;
begin
  LPad := ScaleValue(10);
  LFont := DaisyFontSize(SizeKind);
  if AStyle.IconsOnly then
    Exit(Max(ScaleValue(DaisyMenuRowHeight(SizeKind)), ScaleValue(AStyle.IconPx) + 2 * LPad));
  Result := 2 * LPad + MeasureTextWidth(AItem.Caption, LFont, AItem.Title);
  if AStyle.ReserveIcon then
    Inc(Result, ScaleValue(AStyle.IconPx + 8));
  if AStyle.ShowExtras then
  begin
    if AItem.ShortCut <> '' then
      Inc(Result, ScaleValue(24) + MeasureTextWidth(AItem.ShortCut, LFont - 1, False));
    if AItem.Badge <> '' then
      Inc(Result, ScaleValue(22) + MeasureTextWidth(AItem.Badge, LFont - 2, False));
  end;
  if AStyle.Chevron <> mcNone then
    Inc(Result, ScaleValue(24));
end;

procedure TDaisyMenuSurface.DrawMenuRow(AItem: TDaisyMenuItem; const ARect: TRect;
  const AStyle: TDaisyMenuRowStyle);
var
  LGraphics: TGPGraphics;
  LText, LFillColor: TAlphaColor;
  LPad, LFont, LX, LR, LChevron, LBadgeW, LTextW: Integer;
  LBox: TRect;
  LFill: Boolean;
  LPath: string;
begin
  LPad := ScaleValue(10);
  LFont := DaisyFontSize(SizeKind);
  if AItem.IsSeparator then
  begin
    LGraphics := NewGraphics;
    try
      FillRoundRect(LGraphics, RectF(ARect.Left + LPad, ARect.CenterPoint.Y,
        ARect.Right - LPad, ARect.CenterPoint.Y + 1), 0, DaisyWithAlpha(Theme.BaseContent, 0.15));
    finally
      LGraphics.Free;
    end;
    Exit;
  end;
  if AItem.Title then
  begin
    DrawRichText(AItem.Caption, Rect(ARect.Left + LPad, ARect.Top, ARect.Right - LPad,
      ARect.Bottom), DaisyWithAlpha(Theme.BaseContent, 0.55), LFont - 1, True,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
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
  begin
    LGraphics := NewGraphics;
    try
      FillRoundRect(LGraphics, TRectF.Create(ARect), Theme.RadiusField, LFillColor);
    finally
      LGraphics.Free;
    end;
  end;
  if not AItem.Enabled then
    LText := DaisyWithAlpha(LText, 0.3);

  if AStyle.IconsOnly then
  begin
    LBox := Rect(0, 0, ScaleValue(AStyle.IconPx), ScaleValue(AStyle.IconPx));
    OffsetRect(LBox, ARect.Left + (ARect.Width - LBox.Width) div 2,
      ARect.Top + (ARect.Height - LBox.Height) div 2);
    if AItem.Icon.IsEmpty then
      DrawRichText(Copy(AItem.Caption, 1, 1), ARect, LText, LFont, True,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE)
    else
      DrawGlyph(AItem.Icon, LBox, LText);
    Exit;
  end;

  LX := ARect.Left + LPad;
  LR := ARect.Right - LPad;
  if AStyle.ReserveIcon then
  begin
    LBox := Rect(0, 0, ScaleValue(AStyle.IconPx), ScaleValue(AStyle.IconPx));
    OffsetRect(LBox, LX, ARect.Top + (ARect.Height - LBox.Height) div 2);
    if not AItem.Icon.IsEmpty then
      DrawGlyph(AItem.Icon, LBox, LText)
    else if AItem.Checked then
    begin
      InflateRect(LBox, -ScaleValue(AStyle.IconPx div 5), -ScaleValue(AStyle.IconPx div 5));
      DrawIconPath(CMenuCheckPath, TRectF.Create(LBox), LText);
    end;
    Inc(LX, ScaleValue(AStyle.IconPx + 8));
  end;

  if AStyle.Chevron <> mcNone then
  begin
    LChevron := ScaleValue(12);
    LBox := Rect(LR - LChevron, ARect.Top + (ARect.Height - LChevron) div 2, LR,
      ARect.Top + (ARect.Height - LChevron) div 2 + LChevron);
    case AStyle.Chevron of
      mcRight: LPath := CMenuRightPath;
      mcDown: LPath := CMenuDownPath;
    else
      LPath := CMenuUpPath;
    end;
    FlipGlyphs := AStyle.Chevron = mcRight; // submenu arrow follows the reading direction
    try
      DrawIconPath(LPath, TRectF.Create(LBox), DaisyWithAlpha(LText, 0.7));
    finally
      FlipGlyphs := False;
    end;
  end;

  if AStyle.ShowExtras then
  begin
    if (AItem.Checked) and (not AItem.Icon.IsEmpty) then
    begin
      LBox := Rect(LR - ScaleValue(14), ARect.Top + (ARect.Height - ScaleValue(14)) div 2, LR,
        ARect.Top + (ARect.Height - ScaleValue(14)) div 2 + ScaleValue(14));
      DrawIconPath(CMenuCheckPath, TRectF.Create(LBox), LText);
      Dec(LR, ScaleValue(22));
    end;
    if AItem.ShortCut <> '' then
    begin
      LTextW := MeasureTextWidth(AItem.ShortCut, LFont - 1, False);
      DrawRichText(AItem.ShortCut, Rect(LR - LTextW, ARect.Top, LR, ARect.Bottom),
        DaisyWithAlpha(LText, 0.55), LFont - 1, False,
        DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
      Dec(LR, LTextW + ScaleValue(16));
    end;
    if AItem.Badge <> '' then
    begin
      LBadgeW := MeasureTextWidth(AItem.Badge, LFont - 2, False) + ScaleValue(14);
      LBox := Rect(LR - LBadgeW, ARect.Top + (ARect.Height - ScaleValue(LFont + 4)) div 2, LR,
        ARect.Top + (ARect.Height - ScaleValue(LFont + 4)) div 2 + ScaleValue(LFont + 4));
      LGraphics := NewGraphics;
      try
        FillRoundRect(LGraphics, TRectF.Create(LBox), LBox.Height / 2,
          DaisyWithAlpha(Theme.BaseContent, 0.12));
      finally
        LGraphics.Free;
      end;
      DrawRichText(AItem.Badge, LBox, LText, LFont - 2, False,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      Dec(LR, LBadgeW + ScaleValue(8));
    end;
  end;

  DrawRichText(AItem.Caption, Rect(LX, ARect.Top, Max(LX, LR), ARect.Bottom), LText, LFont,
    False, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

{ TDaisyMenuPopup }

constructor TDaisyMenuPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FShown := TList<TDaisyMenuItem>.Create;
  FHot := -1;
  ControlStyle := ControlStyle - [csParentBackground] + [csOpaque];
  Visible := False;
  TabStop := False;
end;

destructor TDaisyMenuPopup.Destroy;
begin
  FShown.Free;
  inherited Destroy;
end;

procedure TDaisyMenuPopup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_CLIPCHILDREN;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  Params.WndParent := GetDesktopWindow;
end;

procedure TDaisyMenuPopup.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TDaisyMenuPopup.WMLButtonUp(var Message: TWMLButtonUp);
begin
  // TControl releases its mouse capture on button-up, which would close the menu
  FInButtonUp := True;
  try
    inherited;
  finally
    FInButtonUp := False;
  end;
  if Visible and (FParentPopup = nil) and HandleAllocated and (GetCapture <> Handle) then
    MouseCapture := True;
end;

procedure TDaisyMenuPopup.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if Visible and (FParentPopup = nil) and (HWND(Message.LParam) <> Handle) and
    not FInButtonUp then
    CloseAll;
end;

function TDaisyMenuPopup.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyMenuPopup.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.15);
  Result.Text := Theme.BaseContent;
end;

function TDaisyMenuPopup.Pad: Integer;
begin
  Result := ScaleValue(6);
end;

function TDaisyMenuPopup.IsOpen: Boolean;
begin
  Result := Visible;
end;

function TDaisyMenuPopup.Root: TDaisyMenuPopup;
begin
  Result := Self;
  while Result.FParentPopup <> nil do
    Result := Result.FParentPopup;
end;

function TDaisyMenuPopup.ContainsScreen(const AScreen: TPoint): Boolean;
begin
  Result := Visible and PtInRect(BoundsRect, AScreen);
end;

function TDaisyMenuPopup.Deepest(const AScreen: TPoint): TDaisyMenuPopup;
begin
  Result := nil;
  if (FChild <> nil) and FChild.Visible then
    Result := FChild.Deepest(AScreen);
  if (Result = nil) and ContainsScreen(AScreen) then
    Result := Self;
end;

function TDaisyMenuPopup.ItemAt(const APoint: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FRects) do
    if PtInRect(FRects[I], APoint) then
      Exit(I);
end;

procedure TDaisyMenuPopup.SetHot(AIndex: Integer);
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
  Invalidate;
end;

procedure TDaisyMenuPopup.OpenChild(AIndex: Integer);
var
  LAnchor: TRect;
begin
  if FChild = nil then
  begin
    FChild := TDaisyMenuPopup.Create(Self);
    FChild.FParentPopup := Self;
  end;
  FChild.ThemeKind := ThemeKind;
  FChild.SizeKind := SizeKind;
  FChild.Font.Assign(Font);
  FChildSource := FShown[AIndex];
  FChild.BiDiMode := BiDiMode;
  LAnchor := LogicalToScreenRect(FRects[AIndex]);
  FChild.Popup(FChildSource.Items, FIconPx, LAnchor, False, 0);
end;

procedure TDaisyMenuPopup.CloseChild;
begin
  if FChild <> nil then
    FChild.HideChain;
  FChildSource := nil;
end;

procedure TDaisyMenuPopup.HideChain;
begin
  CloseChild;
  FHot := -1;
  if Visible then
  begin
    Visible := False;
    if HandleAllocated then
      ShowWindow(Handle, SW_HIDE);
  end;
end;

procedure TDaisyMenuPopup.CloseAll;
var
  LRoot: TDaisyMenuPopup;
  WasOpen: Boolean;
begin
  LRoot := Root;
  WasOpen := LRoot.Visible;
  LRoot.HideChain;
  if LRoot.HandleAllocated and (GetCapture = LRoot.Handle) then
    ReleaseCapture;
  if WasOpen and Assigned(LRoot.FOnClosed) then
    LRoot.FOnClosed(LRoot);
end;

procedure TDaisyMenuPopup.Place(const AAnchor: TRect; ABelow: Boolean; AGap: Integer);
var
  LWork: TRect;
  LX, LY, LWidth, LHeight: Integer;
  LDiameter: Integer;
  LRegion: HRGN;
begin
  LWidth := ClientWidth;
  LHeight := ClientHeight;
  LWork := Screen.MonitorFromPoint(AAnchor.TopLeft).WorkareaRect;
  if ABelow then
  begin
    if IsRTL then
      LX := AAnchor.Right - LWidth
    else
      LX := AAnchor.Left;
    LY := AAnchor.Bottom + ScaleValue(AGap);
    if LX + LWidth > LWork.Right then
      LX := Max(LWork.Left, LWork.Right - LWidth);
    if LX < LWork.Left then
      LX := LWork.Left;
    if LY + LHeight > LWork.Bottom then
      LY := Max(LWork.Top, AAnchor.Top - LHeight - ScaleValue(AGap)); // flip above
  end
  else
  begin
    if IsRTL then
    begin
      LX := AAnchor.Left - LWidth;
      if LX < LWork.Left then
        LX := AAnchor.Right; // flip to the other side
    end
    else
    begin
      LX := AAnchor.Right;
      if LX + LWidth > LWork.Right then
        LX := AAnchor.Left - LWidth; // flip to the other side
    end;
    LY := AAnchor.Top - Pad;
    if LY + LHeight > LWork.Bottom then
      LY := Max(LWork.Top, LWork.Bottom - LHeight);
  end;
  SetBounds(LX, LY, LWidth, LHeight);
  LDiameter := 2 * ResolvedCornerRadius;
  LRegion := CreateRoundRectRgn(0, 0, LWidth + 1, LHeight + 1, LDiameter, LDiameter);
  SetWindowRgn(Handle, LRegion, False);
  Visible := True;
  SetWindowPos(Handle, HWND_TOPMOST, LX, LY, LWidth, LHeight, SWP_NOACTIVATE or SWP_SHOWWINDOW);
end;

procedure TDaisyMenuPopup.Popup(AItems: TDaisyMenuItems; AIconPx: Integer; const AAnchor: TRect;
  ABelow: Boolean; AGap: Integer);
var
  I, LWidth, LY, LHeight: Integer;
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
  Color := DaisyToColor(Theme.Base100);

  LStyle := Default(TDaisyMenuRowStyle);
  LStyle.IconPx := AIconPx;
  LStyle.ReserveIcon := FReserve;
  LStyle.ShowExtras := True;
  LWidth := ScaleValue(160);
  LY := Pad;
  SetLength(FRects, FShown.Count);
  for I := 0 to FShown.Count - 1 do
  begin
    if FShown[I].HasChildren and not FShown[I].Title then
      LStyle.Chevron := mcRight
    else
      LStyle.Chevron := mcNone;
    LWidth := Max(LWidth, MenuRowWidth(FShown[I], LStyle) + 2 * Pad);
    LHeight := MenuRowHeight(FShown[I], AIconPx);
    FRects[I] := Rect(Pad, LY, 0, LY + LHeight);
    Inc(LY, LHeight);
  end;
  for I := 0 to High(FRects) do
    FRects[I].Right := LWidth - Pad;
  HandleNeeded;
  Width := LWidth;
  Height := LY + Pad;
  Place(AAnchor, ABelow, AGap);
  Invalidate;
  if FParentPopup = nil then
    MouseCapture := True;
end;

procedure TDaisyMenuPopup.HandleMove(const AScreen: TPoint);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(ScreenToLogical(AScreen));
  if (LIndex >= 0) and (FShown[LIndex].IsSeparator or FShown[LIndex].Title) then
    LIndex := -1;
  SetHot(LIndex);
end;

procedure TDaisyMenuPopup.HandleUp(const AScreen: TPoint);
var
  LIndex: Integer;
  LItem: TDaisyMenuItem;
  LRoot: TDaisyMenuPopup;
begin
  LIndex := ItemAt(ScreenToLogical(AScreen));
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
  LRoot := Root;
  CloseAll;
  LItem.Click;
  if Assigned(LRoot.FOnItemClick) then
    LRoot.FOnItemClick(LRoot, LItem);
end;

procedure TDaisyMenuPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Deepest(LogicalToScreen(Point(X, Y))) = nil then
    CloseAll;
end;

procedure TDaisyMenuPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LTarget: TDaisyMenuPopup;
  LPoint: TPoint;
begin
  if Button <> mbLeft then
    Exit;
  LPoint := LogicalToScreen(Point(X, Y));
  LTarget := Deepest(LPoint);
  if LTarget <> nil then
    LTarget.HandleUp(LPoint);
end;

procedure TDaisyMenuPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LTarget: TDaisyMenuPopup;
  LPoint: TPoint;
begin
  inherited;
  LPoint := LogicalToScreen(Point(X, Y));
  LTarget := Deepest(LPoint);
  if LTarget <> nil then
    LTarget.HandleMove(LPoint)
  else if Assigned(FOnOutsideMove) then
    FOnOutsideMove(Self, LPoint);
end;

procedure TDaisyMenuPopup.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
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
