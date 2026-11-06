unit Daisy.FMX.Menu;

{
  TDaisyFmxMenu - the DaisyUI "menu": a list of links, vertical or horizontal.

  Items may carry an Icon (Emoji or SVG), a Badge, a ShortCut text, be Active,
  disabled, be a Title (a heading whose child items are always shown beneath it)
  or hold child Items. In a vertical menu child items collapse and expand in
  place (Expanded); in a horizontal menu, and in a vertical IconsOnly menu, they
  open as a cascading popup. IconsOnly shows just the icons (the caption becomes
  the hint).
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, System.Diagnostics,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.FMX.Control, Daisy.FMX.MenuPopup;

type
  TDaisyFmxMenu = class(TDaisyFmxMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FOrientation: TDaisyMenuOrientation;
    FIconSize: TDaisyMenuIconSize;
    FIconsOnly: Boolean;
    FBordered: Boolean;
    FAutoFit: Boolean;
    FAutoActive: Boolean;
    FRows: TList<TDaisyMenuRow>;
    FRects: TArray<TRectF>;
    FReserve: Boolean;
    FHotIndex: Integer;
    FOpenIndex: Integer;
    FUpdating: Boolean;
    FClosedTick: UInt64;
    FPopup: TDaisyFmxMenuPopup;
    FOnItemClick: TDaisyMenuItemEvent;
    procedure SetItems(const Value: TDaisyMenuItems);
    procedure SetOrientation(const Value: TDaisyMenuOrientation);
    procedure SetIconSize(const Value: TDaisyMenuIconSize);
    procedure SetIconsOnly(const Value: Boolean);
    procedure SetBordered(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure ItemsChanged(Sender: TObject);
    function IconPx: Integer;
    function RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
    procedure Relayout;
    function ItemAt(const APoint: TPointF): Integer;
    procedure SetHot(AIndex: Integer);
    procedure ClearActive(AItems: TDaisyMenuItems);
    procedure OpenPopup(AIndex: Integer);
    procedure PopupClosed(Sender: TObject);
    procedure PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
    procedure PopupOutsideMove(Sender: TObject; const APoint: TPointF);
    procedure ItemClicked(AItem: TDaisyMenuItem);
    function UsesFlyout: Boolean;
    function NowMs: UInt64;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DoMouseLeave; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CloseUp;
  published
    property Items: TDaisyMenuItems read FItems write SetItems;
    property Orientation: TDaisyMenuOrientation read FOrientation write SetOrientation
      default moVertical;
    // Icons are drawn at 16, 24 or 32 pixels
    property IconSize: TDaisyMenuIconSize read FIconSize write SetIconSize default mis16;
    property IconsOnly: Boolean read FIconsOnly write SetIconsOnly default False;
    // A rounded base-200 box behind the items
    property Bordered: Boolean read FBordered write SetBordered default True;
    // The size follows the items
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    // Clicking an item makes it the Active one
    property AutoActive: Boolean read FAutoActive write FAutoActive default True;
    property OnItemClick: TDaisyMenuItemEvent read FOnItemClick write FOnItemClick;
  end;

implementation

const
  CPad = 8;
  CGap = 2;
  CIndent = 16;

constructor TDaisyFmxMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyMenuItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FRows := TList<TDaisyMenuRow>.Create;
  FBordered := True;
  FAutoFit := True;
  FAutoActive := True;
  FHotIndex := -1;
  FOpenIndex := -1;
  SetBounds(Position.X, Position.Y, 208, 120);
  HitTest := True;
end;

destructor TDaisyFmxMenu.Destroy;
begin
  FRows.Free;
  FItems.Free;
  inherited Destroy;
end;

function TDaisyFmxMenu.NowMs: UInt64;
begin
  Result := TStopwatch.GetTimeStamp div (TStopwatch.Frequency div 1000);
end;

function TDaisyFmxMenu.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxMenu.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  if FBordered then
    Result.Background := Theme.Base200;
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxMenu.Loaded;
begin
  inherited;
  Relayout;
end;

procedure TDaisyFmxMenu.SizeChanged;
begin
  Relayout;
end;

function TDaisyFmxMenu.IconPx: Integer;
begin
  Result := DaisyMenuIconPixels(FIconSize);
end;

function TDaisyFmxMenu.UsesFlyout: Boolean;
begin
  Result := (FOrientation = moHorizontal) or FIconsOnly;
end;

procedure TDaisyFmxMenu.SetItems(const Value: TDaisyMenuItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxMenu.SetOrientation(const Value: TDaisyMenuOrientation);
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    Relayout;
    Repaint;
  end;
end;

procedure TDaisyFmxMenu.SetIconSize(const Value: TDaisyMenuIconSize);
begin
  if FIconSize <> Value then
  begin
    FIconSize := Value;
    Relayout;
    Repaint;
  end;
end;

procedure TDaisyFmxMenu.SetIconsOnly(const Value: Boolean);
begin
  if FIconsOnly <> Value then
  begin
    FIconsOnly := Value;
    Relayout;
    Repaint;
  end;
end;

procedure TDaisyFmxMenu.SetBordered(const Value: Boolean);
begin
  if FBordered <> Value then
  begin
    FBordered := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxMenu.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    Relayout;
  end;
end;

procedure TDaisyFmxMenu.ItemsChanged(Sender: TObject);
begin
  Relayout;
  Repaint;
end;

function TDaisyFmxMenu.RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
var
  LItem: TDaisyMenuItem;
begin
  LItem := FRows[AIndex].Item;
  Result := Default(TDaisyMenuRowStyle);
  Result.IconPx := IconPx;
  Result.IconsOnly := FIconsOnly;
  Result.Hot := (AIndex = FHotIndex) or (AIndex = FOpenIndex);
  Result.Active := LItem.Active;
  if FOrientation = moHorizontal then
  begin
    Result.ReserveIcon := not LItem.Icon.IsEmpty;
    if LItem.HasChildren and not LItem.Title then
      Result.Chevron := mcDown;
  end
  else
  begin
    Result.ReserveIcon := FReserve;
    Result.ShowExtras := not FIconsOnly;
    if LItem.HasChildren and not LItem.Title and not FIconsOnly then
      if LItem.Expanded then
        Result.Chevron := mcUp
      else
        Result.Chevron := mcDown;
  end;
end;

procedure TDaisyFmxMenu.Relayout;
var
  I: Integer;
  LX, LY, LWidth, LHeight, LRowW: Single;
  LRow: TDaisyMenuRow;
begin
  if (csLoading in ComponentState) or FUpdating then
    Exit;
  FRows.Clear;
  FReserve := MenuNeedsIconSlot(FItems);
  if FOrientation = moHorizontal then
  begin
    for I := 0 to FItems.Count - 1 do
      if FItems[I].Visible then
      begin
        LRow.Item := FItems[I];
        LRow.Level := 0;
        FRows.Add(LRow);
      end;
  end
  else
    DaisyFlattenMenu(FItems, FRows);

  SetLength(FRects, FRows.Count);
  if FOrientation = moHorizontal then
  begin
    LX := CPad;
    LHeight := DaisyMenuRowHeight(SizeKind);
    for I := 0 to FRows.Count - 1 do
      if not FRows[I].Item.Icon.IsEmpty then
        LHeight := Max(LHeight, IconPx + 8);
    for I := 0 to FRows.Count - 1 do
    begin
      LRowW := MenuRowWidth(FRows[I].Item, RowStyle(I));
      FRects[I] := RectF(LX, CPad, LX + LRowW, CPad + LHeight);
      LX := FRects[I].Right + CGap;
    end;
    LWidth := LX + CPad - CGap;
    LHeight := LHeight + 2 * CPad;
  end
  else
  begin
    LWidth := 0;
    LY := CPad;
    for I := 0 to FRows.Count - 1 do
    begin
      LRowW := MenuRowWidth(FRows[I].Item, RowStyle(I)) + FRows[I].Level * CIndent;
      LWidth := Max(LWidth, LRowW);
      FRects[I] := RectF(CPad, LY, 0, LY + MenuRowHeight(FRows[I].Item, IconPx));
      LY := FRects[I].Bottom + CGap;
    end;
    LHeight := LY + CPad - CGap;
    if FRows.Count = 0 then
      LHeight := 2 * CPad + DaisyMenuRowHeight(SizeKind);
    LWidth := Max(LWidth, DaisyMenuRowHeight(SizeKind)) + 2 * CPad;
    if not FAutoFit then
      LWidth := Width;
    for I := 0 to FRows.Count - 1 do
    begin
      FRects[I].Left := CPad + FRows[I].Level * CIndent;
      FRects[I].Right := LWidth - CPad;
    end;
  end;

  if FAutoFit and (Align = TAlignLayout.None) and
    (not SameValue(LWidth, Width) or not SameValue(LHeight, Height)) then
  begin
    FUpdating := True;
    try
      SetBounds(Position.X, Position.Y, LWidth, LHeight);
    finally
      FUpdating := False;
    end;
  end;
end;

function TDaisyFmxMenu.ItemAt(const APoint: TPointF): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FRects) do
    if (I < FRows.Count) and FRects[I].Contains(APoint) and not FRows[I].Item.IsSeparator and
      not FRows[I].Item.Title then
      Exit(I);
end;

procedure TDaisyFmxMenu.SetHot(AIndex: Integer);
begin
  if AIndex = FHotIndex then
    Exit;
  FHotIndex := AIndex;
  if FIconsOnly and (AIndex >= 0) then
  begin
    Hint := FRows[AIndex].Item.Caption;
    ShowHint := True;
  end;
  Repaint;
end;

procedure TDaisyFmxMenu.DoMouseLeave;
begin
  inherited;
  SetHot(-1);
end;

procedure TDaisyFmxMenu.ClearActive(AItems: TDaisyMenuItems);
var
  I: Integer;
begin
  for I := 0 to AItems.Count - 1 do
  begin
    AItems[I].Active := False;
    ClearActive(AItems[I].Items);
  end;
end;

procedure TDaisyFmxMenu.ItemClicked(AItem: TDaisyMenuItem);
begin
  if FAutoActive and not AItem.HasChildren then
  begin
    ClearActive(FItems);
    AItem.Active := True;
  end;
  AItem.Click;
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

procedure TDaisyFmxMenu.OpenPopup(AIndex: Integer);
var
  LForm: TCommonCustomForm;
  LRect: TRectF;
begin
  if (csDesigning in ComponentState) or (Root = nil) or
    not (Root.GetObject is TCommonCustomForm) or (AIndex >= Length(FRects)) then
    Exit;
  LForm := TCommonCustomForm(Root.GetObject);
  if FPopup = nil then
  begin
    FPopup := TDaisyFmxMenuPopup.Create(Self);
    FPopup.OnClosed := PopupClosed;
    FPopup.OnItemClick := PopupItemClick;
    FPopup.OnOutsideMove := PopupOutsideMove;
  end;
  if FPopup.IsOpen then
    FPopup.CloseAll;
  FOpenIndex := AIndex;
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;
  LRect := FRects[AIndex];
  LRect.TopLeft := LocalToAbsolute(LRect.TopLeft);
  LRect.BottomRight := LocalToAbsolute(LRect.BottomRight);
  FPopup.Popup(LForm, FRows[AIndex].Item.Items, IconPx, LRect, FOrientation = moHorizontal, CGap);
  Repaint;
end;

procedure TDaisyFmxMenu.CloseUp;
begin
  if (FPopup <> nil) and FPopup.IsOpen then
    FPopup.CloseAll;
end;

procedure TDaisyFmxMenu.PopupClosed(Sender: TObject);
begin
  FOpenIndex := -1;
  FClosedTick := NowMs;
  Repaint;
end;

procedure TDaisyFmxMenu.PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

procedure TDaisyFmxMenu.PopupOutsideMove(Sender: TObject; const APoint: TPointF);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(AbsoluteToLocal(APoint));
  if (LIndex >= 0) and (LIndex <> FOpenIndex) and FRows[LIndex].Item.HasChildren and
    FRows[LIndex].Item.Enabled then
    OpenPopup(LIndex);
end;

procedure TDaisyFmxMenu.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LIndex: Integer;
  LItem: TDaisyMenuItem;
begin
  inherited;
  if Button <> TMouseButton.mbLeft then
    Exit;
  LIndex := ItemAt(PointF(X, Y));
  if LIndex < 0 then
    Exit;
  LItem := FRows[LIndex].Item;
  if not LItem.Enabled then
    Exit;
  if LItem.HasChildren then
  begin
    if UsesFlyout then
    begin
      if NowMs - FClosedTick > 300 then
        // opened after the mouse-up has been fully processed so the capture sticks
        TThread.ForceQueue(nil,
          procedure
          begin
            if not (csDestroying in ComponentState) then
              OpenPopup(LIndex);
          end);
    end
    else
      LItem.Expanded := not LItem.Expanded;
  end
  else
    ItemClicked(LItem);
end;

procedure TDaisyFmxMenu.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;
  SetHot(ItemAt(PointF(X, Y)));
end;

procedure TDaisyFmxMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  I: Integer;
begin
  if FItems.Count = 0 then
  begin
    DrawText('DaisyFmxMenu', ARect, DaisyWithAlpha(AColors.Text, 0.4), DaisyFontSize(SizeKind),
      False, TTextAlign.Center, TTextAlign.Center, False);
    Exit;
  end;
  if Length(FRects) <> FRows.Count then
    Exit;
  for I := 0 to FRows.Count - 1 do
    DrawMenuRow(FRows[I].Item, FRects[I], RowStyle(I));
end;

end.
