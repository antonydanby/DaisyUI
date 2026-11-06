unit Daisy.VCL.Menu;

{
  TDaisyMenu - the DaisyUI "menu": a list of links, vertical or horizontal.

  Items may carry an Icon (Emoji or SVG), a Badge, a ShortCut text, be Active,
  disabled, be a Title (a heading whose child items are always shown beneath it)
  or hold child Items. In a vertical menu child items collapse and expand in
  place (Expanded); in a horizontal menu, and in a vertical IconsOnly menu, they
  open as a cascading popup. IconsOnly shows just the icons (the caption becomes
  the hint).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  System.Math, System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.VCL.Control, Daisy.VCL.MenuPopup;

type
  TDaisyMenu = class(TDaisyMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FOrientation: TDaisyMenuOrientation;
    FIconSize: TDaisyMenuIconSize;
    FIconsOnly: Boolean;
    FBordered: Boolean;
    FAutoFit: Boolean;
    FAutoActive: Boolean;
    FRows: TList<TDaisyMenuRow>;
    FRects: TArray<TRect>;
    FReserve: Boolean;
    FHotIndex: Integer;
    FOpenIndex: Integer;
    FUpdating: Boolean;
    FClosedTick: Cardinal;
    FPopup: TDaisyMenuPopup;
    FOnItemClick: TDaisyMenuItemEvent;
    procedure SetItems(const Value: TDaisyMenuItems);
    procedure SetOrientation(const Value: TDaisyMenuOrientation);
    procedure SetIconSize(const Value: TDaisyMenuIconSize);
    procedure SetIconsOnly(const Value: Boolean);
    procedure SetBordered(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure ItemsChanged(Sender: TObject);
    function Pad: Integer;
    function IconPx: Integer;
    function RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
    procedure Relayout;
    function ItemAt(const APoint: TPoint): Integer;
    procedure SetHot(AIndex: Integer);
    procedure ClearActive(AItems: TDaisyMenuItems);
    procedure OpenPopup(AIndex: Integer);
    procedure PopupClosed(Sender: TObject);
    procedure PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
    procedure PopupOutsideMove(Sender: TObject; const APoint: TPoint);
    procedure ItemClicked(AItem: TDaisyMenuItem);
    function UsesFlyout: Boolean;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

constructor TDaisyMenu.Create(AOwner: TComponent);
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
  TabStop := False;
  SetBounds(Left, Top, 208, 120);
end;

destructor TDaisyMenu.Destroy;
begin
  FRows.Free;
  FItems.Free;
  inherited Destroy;
end;

function TDaisyMenu.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyMenu.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  if FBordered then
    Result.Background := Theme.Base200;
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyMenu.Loaded;
begin
  inherited;
  Relayout;
end;

procedure TDaisyMenu.SizeChanged;
begin
  Relayout;
end;

procedure TDaisyMenu.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Relayout;
  Invalidate;
end;

function TDaisyMenu.Pad: Integer;
begin
  Result := ScaleValue(8);
end;

function TDaisyMenu.IconPx: Integer;
begin
  Result := DaisyMenuIconPixels(FIconSize);
end;

function TDaisyMenu.UsesFlyout: Boolean;
begin
  Result := (FOrientation = moHorizontal) or FIconsOnly;
end;

procedure TDaisyMenu.SetItems(const Value: TDaisyMenuItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyMenu.SetOrientation(const Value: TDaisyMenuOrientation);
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    Relayout;
    Invalidate;
  end;
end;

procedure TDaisyMenu.SetIconSize(const Value: TDaisyMenuIconSize);
begin
  if FIconSize <> Value then
  begin
    FIconSize := Value;
    Relayout;
    Invalidate;
  end;
end;

procedure TDaisyMenu.SetIconsOnly(const Value: Boolean);
begin
  if FIconsOnly <> Value then
  begin
    FIconsOnly := Value;
    Relayout;
    Invalidate;
  end;
end;

procedure TDaisyMenu.SetBordered(const Value: Boolean);
begin
  if FBordered <> Value then
  begin
    FBordered := Value;
    Invalidate;
  end;
end;

procedure TDaisyMenu.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    Relayout;
  end;
end;

procedure TDaisyMenu.ItemsChanged(Sender: TObject);
begin
  Relayout;
  Invalidate;
end;

function TDaisyMenu.RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
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

procedure TDaisyMenu.Relayout;
var
  I, LX, LY, LWidth, LHeight, LIndent, LRowW: Integer;
  LRow: TDaisyMenuRow;
  LStyle: TDaisyMenuRowStyle;
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
  LIndent := ScaleValue(16);
  if FOrientation = moHorizontal then
  begin
    LX := Pad;
    LHeight := ScaleValue(DaisyMenuRowHeight(SizeKind));
    for I := 0 to FRows.Count - 1 do
      if not FRows[I].Item.Icon.IsEmpty then
        LHeight := Max(LHeight, ScaleValue(IconPx + 8));
    for I := 0 to FRows.Count - 1 do
    begin
      LStyle := RowStyle(I);
      LRowW := MenuRowWidth(FRows[I].Item, LStyle);
      FRects[I] := Rect(LX, Pad, LX + LRowW, Pad + LHeight);
      LX := FRects[I].Right + ScaleValue(2);
    end;
    LWidth := LX + Pad - ScaleValue(2);
    LHeight := LHeight + 2 * Pad;
  end
  else
  begin
    LWidth := 0;
    LY := Pad;
    for I := 0 to FRows.Count - 1 do
    begin
      LStyle := RowStyle(I);
      LRowW := MenuRowWidth(FRows[I].Item, LStyle) + FRows[I].Level * LIndent;
      LWidth := Max(LWidth, LRowW);
      FRects[I] := Rect(Pad, LY, 0, LY + MenuRowHeight(FRows[I].Item, IconPx));
      LY := FRects[I].Bottom + ScaleValue(2);
    end;
    LHeight := LY + Pad - ScaleValue(2);
    if FRows.Count = 0 then
      LHeight := 2 * Pad + ScaleValue(DaisyMenuRowHeight(SizeKind));
    LWidth := Max(LWidth, ScaleValue(DaisyMenuRowHeight(SizeKind))) + 2 * Pad;
    if not FAutoFit then
      LWidth := Width;
    for I := 0 to FRows.Count - 1 do
    begin
      FRects[I].Left := Pad + FRows[I].Level * LIndent;
      FRects[I].Right := LWidth - Pad;
    end;
  end;

  if FAutoFit and ((LWidth <> Width) or (LHeight <> Height)) and (Align = alNone) then
  begin
    FUpdating := True;
    try
      if (FOrientation = moVertical) and not FAutoFit then
        SetBounds(Left, Top, Width, LHeight)
      else
        SetBounds(Left, Top, LWidth, LHeight);
    finally
      FUpdating := False;
    end;
  end;
end;

function TDaisyMenu.ItemAt(const APoint: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FRects) do
    if (I < FRows.Count) and PtInRect(FRects[I], APoint) and not FRows[I].Item.IsSeparator and
      not FRows[I].Item.Title then
      Exit(I);
end;

procedure TDaisyMenu.SetHot(AIndex: Integer);
begin
  if AIndex = FHotIndex then
    Exit;
  FHotIndex := AIndex;
  if FIconsOnly and (AIndex >= 0) then
  begin
    Hint := FRows[AIndex].Item.Caption;
    ShowHint := True;
    Application.CancelHint;
  end;
  Invalidate;
end;

procedure TDaisyMenu.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHot(-1);
end;

procedure TDaisyMenu.ClearActive(AItems: TDaisyMenuItems);
var
  I: Integer;
begin
  for I := 0 to AItems.Count - 1 do
  begin
    AItems[I].Active := False;
    ClearActive(AItems[I].Items);
  end;
end;

procedure TDaisyMenu.ItemClicked(AItem: TDaisyMenuItem);
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

procedure TDaisyMenu.OpenPopup(AIndex: Integer);
var
  LRect: TRect;
begin
  if (csDesigning in ComponentState) or not HandleAllocated then
    Exit;
  if FPopup = nil then
  begin
    FPopup := TDaisyMenuPopup.Create(Self);
    FPopup.OnClosed := PopupClosed;
    FPopup.OnItemClick := PopupItemClick;
    FPopup.OnOutsideMove := PopupOutsideMove;
  end;
  if FPopup.IsOpen then
    FPopup.CloseAll;
  FOpenIndex := AIndex;
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;
  FPopup.Font.Assign(Font);
  LRect := FRects[AIndex];
  LRect.TopLeft := ClientToScreen(LRect.TopLeft);
  LRect.BottomRight := ClientToScreen(LRect.BottomRight);
  FPopup.Popup(FRows[AIndex].Item.Items, IconPx, LRect, FOrientation = moHorizontal, 2);
  Invalidate;
end;

procedure TDaisyMenu.CloseUp;
begin
  if (FPopup <> nil) and FPopup.IsOpen then
    FPopup.CloseAll;
end;

procedure TDaisyMenu.PopupClosed(Sender: TObject);
begin
  FOpenIndex := -1;
  FClosedTick := GetTickCount;
  Invalidate;
end;

procedure TDaisyMenu.PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

procedure TDaisyMenu.PopupOutsideMove(Sender: TObject; const APoint: TPoint);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(ScreenToClient(APoint));
  if (LIndex >= 0) and (LIndex <> FOpenIndex) and FRows[LIndex].Item.HasChildren and
    FRows[LIndex].Item.Enabled then
    OpenPopup(LIndex);
end;

procedure TDaisyMenu.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
  LItem: TDaisyMenuItem;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  LIndex := ItemAt(Point(X, Y));
  if LIndex < 0 then
    Exit;
  LItem := FRows[LIndex].Item;
  if not LItem.Enabled then
    Exit;
  if LItem.HasChildren then
  begin
    if UsesFlyout then
    begin
      if GetTickCount - FClosedTick > 300 then
        OpenPopup(LIndex);
    end
    else
      LItem.Expanded := not LItem.Expanded;
  end
  else
    ItemClicked(LItem);
end;

procedure TDaisyMenu.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SetHot(ItemAt(Point(X, Y)));
end;

procedure TDaisyMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  I: Integer;
  LRect: TRect;
begin
  if FItems.Count = 0 then
  begin
    DrawText('DaisyMenu', ARect, DaisyWithAlpha(AColors.Text, 0.4), DaisyFontSize(SizeKind),
      False, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    Exit;
  end;
  if Length(FRects) <> FRows.Count then
    Exit;
  for I := 0 to FRows.Count - 1 do
  begin
    LRect := FRects[I];
    DrawMenuRow(FRows[I].Item, LRect, RowStyle(I));
  end;
end;

end.
