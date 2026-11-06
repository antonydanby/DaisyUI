unit Daisy.VCL.MainMenu;

{
  TDaisyMainMenu - a menu bar in the DaisyUI look.

  Items are the top level entries; entries that have child Items open a
  cascading popup menu, the others click straight away. Every item may have an
  Icon (Emoji or SVG) drawn at IconSize pixels (16, 24 or 32).
  Align defaults to alTop so the bar docks like a TMainMenu.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  System.Math, Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.VCL.Control, Daisy.VCL.MenuPopup;

type
  TDaisyMainMenu = class(TDaisyMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FIconSize: TDaisyMenuIconSize;
    FPopup: TDaisyMenuPopup;
    FHotIndex: Integer;
    FOpenIndex: Integer;
    FClosedTick: Cardinal;
    FOnItemClick: TDaisyMenuItemEvent;
    procedure SetItems(const Value: TDaisyMenuItems);
    procedure SetIconSize(const Value: TDaisyMenuIconSize);
    procedure ItemsChanged(Sender: TObject);
    function BarHeight: Integer;
    function ItemRect(AIndex: Integer): TRect;
    function ItemAt(const APoint: TPoint): Integer;
    function RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
    procedure OpenItem(AIndex: Integer);
    procedure PopupClosed(Sender: TObject);
    procedure PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
    procedure PopupOutsideMove(Sender: TObject; const APoint: TPoint);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure SetHot(AIndex: Integer);
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
    // Icons are drawn at 16, 24 or 32 pixels
    property IconSize: TDaisyMenuIconSize read FIconSize write SetIconSize default mis16;
    property OnItemClick: TDaisyMenuItemEvent read FOnItemClick write FOnItemClick;
  end;

implementation

constructor TDaisyMainMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyMenuItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FHotIndex := -1;
  FOpenIndex := -1;
  SetBounds(Left, Top, 320, ScaleValue(DaisyMenuRowHeight(dzMD) + 8));
  Align := alTop;
end;

destructor TDaisyMainMenu.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TDaisyMainMenu.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyMainMenu.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base200;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.08);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyMainMenu.Loaded;
begin
  inherited;
  SizeChanged;
end;

procedure TDaisyMainMenu.SizeChanged;
begin
  if csLoading in ComponentState then
    Exit;
  if Height <> BarHeight then
    Height := BarHeight;
end;

function TDaisyMainMenu.BarHeight: Integer;
var
  I, LMax: Integer;
begin
  LMax := ScaleValue(DaisyMenuRowHeight(SizeKind));
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible and not FItems[I].Icon.IsEmpty then
      LMax := Max(LMax, ScaleValue(DaisyMenuIconPixels(FIconSize) + 8));
  Result := LMax + ScaleValue(8);
end;

procedure TDaisyMainMenu.SetItems(const Value: TDaisyMenuItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyMainMenu.SetIconSize(const Value: TDaisyMenuIconSize);
begin
  if FIconSize <> Value then
  begin
    FIconSize := Value;
    SizeChanged;
    Invalidate;
  end;
end;

procedure TDaisyMainMenu.ItemsChanged(Sender: TObject);
begin
  SizeChanged;
  Invalidate;
end;

function TDaisyMainMenu.RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
begin
  Result := Default(TDaisyMenuRowStyle);
  Result.IconPx := DaisyMenuIconPixels(FIconSize);
  Result.ReserveIcon := not FItems[AIndex].Icon.IsEmpty;
  Result.Hot := (AIndex = FHotIndex) or (AIndex = FOpenIndex);
end;

function TDaisyMainMenu.ItemRect(AIndex: Integer): TRect;
var
  I, LX, LPad: Integer;
  LStyle: TDaisyMenuRowStyle;
begin
  LPad := ScaleValue(4);
  LX := LPad;
  Result := Rect(0, 0, 0, 0);
  for I := 0 to FItems.Count - 1 do
  begin
    if not FItems[I].Visible then
      Continue;
    LStyle := RowStyle(I);
    Result := Rect(LX, LPad, LX + MenuRowWidth(FItems[I], LStyle), Height - LPad);
    if I = AIndex then
      Exit;
    LX := Result.Right + ScaleValue(2);
  end;
  Result := Rect(0, 0, 0, 0);
end;

function TDaisyMainMenu.ItemAt(const APoint: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible and not FItems[I].IsSeparator and PtInRect(ItemRect(I), APoint) then
      Exit(I);
end;

procedure TDaisyMainMenu.SetHot(AIndex: Integer);
begin
  if AIndex <> FHotIndex then
  begin
    FHotIndex := AIndex;
    Invalidate;
  end;
end;

procedure TDaisyMainMenu.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHot(-1);
end;

procedure TDaisyMainMenu.OpenItem(AIndex: Integer);
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
  LRect := ItemRect(AIndex);
  LRect.TopLeft := ClientToScreen(LRect.TopLeft);
  LRect.BottomRight := ClientToScreen(LRect.BottomRight);
  FPopup.Popup(FItems[AIndex].Items, DaisyMenuIconPixels(FIconSize), LRect, True, 2);
  Invalidate;
end;

procedure TDaisyMainMenu.CloseUp;
begin
  if (FPopup <> nil) and FPopup.IsOpen then
    FPopup.CloseAll;
end;

procedure TDaisyMainMenu.PopupClosed(Sender: TObject);
begin
  FOpenIndex := -1;
  FClosedTick := GetTickCount;
  Invalidate;
end;

procedure TDaisyMainMenu.PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

procedure TDaisyMainMenu.PopupOutsideMove(Sender: TObject; const APoint: TPoint);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(ScreenToClient(APoint));
  if (LIndex >= 0) and (LIndex <> FOpenIndex) and FItems[LIndex].HasChildren and
    FItems[LIndex].Enabled then
    OpenItem(LIndex);
end;

procedure TDaisyMainMenu.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  LIndex := ItemAt(Point(X, Y));
  if (LIndex < 0) or not FItems[LIndex].Enabled or FItems[LIndex].Title then
    Exit;
  if FItems[LIndex].HasChildren then
  begin
    if GetTickCount - FClosedTick > 300 then
      OpenItem(LIndex);
  end
  else
  begin
    FItems[LIndex].Click;
    if Assigned(FOnItemClick) then
      FOnItemClick(Self, FItems[LIndex]);
  end;
end;

procedure TDaisyMainMenu.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SetHot(ItemAt(Point(X, Y)));
end;

procedure TDaisyMainMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  I: Integer;
begin
  if FItems.Count = 0 then
  begin
    DrawText('DaisyMainMenu', ARect, DaisyWithAlpha(AColors.Text, 0.4), DaisyFontSize(SizeKind),
      False, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    Exit;
  end;
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible then
      DrawMenuRow(FItems[I], ItemRect(I), RowStyle(I));
end;

end.
