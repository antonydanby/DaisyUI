unit Daisy.FMX.MainMenu;

{
  TDaisyFmxMainMenu - a menu bar in the DaisyUI look.

  Items are the top level entries; entries that have child Items open a
  cascading popup menu, the others click straight away. Every item may have an
  Icon (Emoji or SVG) drawn at IconSize pixels (16, 24 or 32).
  Align defaults to Top so the bar docks like a TMainMenu.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.FMX.Control, Daisy.FMX.MenuPopup;

type
  TDaisyFmxMainMenu = class(TDaisyFmxMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FIconSize: TDaisyMenuIconSize;
    FPopup: TDaisyFmxMenuPopup;
    FHotIndex: Integer;
    FOpenIndex: Integer;
    FClosedTick: UInt64;
    FOnItemClick: TDaisyMenuItemEvent;
    procedure SetItems(const Value: TDaisyMenuItems);
    procedure SetIconSize(const Value: TDaisyMenuIconSize);
    procedure ItemsChanged(Sender: TObject);
    function BarHeight: Single;
    function ItemRect(AIndex: Integer): TRectF;
    function ItemAt(const APoint: TPointF): Integer;
    function RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
    procedure OpenItem(AIndex: Integer);
    procedure PopupClosed(Sender: TObject);
    procedure PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
    procedure PopupOutsideMove(Sender: TObject; const APoint: TPointF);
    procedure SetHot(AIndex: Integer);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
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
    // Icons are drawn at 16, 24 or 32 pixels
    property IconSize: TDaisyMenuIconSize read FIconSize write SetIconSize default mis16;
    property OnItemClick: TDaisyMenuItemEvent read FOnItemClick write FOnItemClick;
  end;

implementation

uses
  System.Diagnostics;

constructor TDaisyFmxMainMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyMenuItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FHotIndex := -1;
  FOpenIndex := -1;
  SetBounds(Position.X, Position.Y, 320, DaisyMenuRowHeight(dzMD) + 8);
  Align := TAlignLayout.Top;
end;

destructor TDaisyFmxMainMenu.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TDaisyFmxMainMenu.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxMainMenu.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxMainMenu.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base200;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.08);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxMainMenu.Loaded;
begin
  inherited;
  SizeChanged;
end;

procedure TDaisyFmxMainMenu.SizeChanged;
begin
  if csLoading in ComponentState then
    Exit;
  if not SameValue(Height, BarHeight) then
    Height := BarHeight;
end;

function TDaisyFmxMainMenu.BarHeight: Single;
var
  I: Integer;
  LMax: Single;
begin
  LMax := DaisyMenuRowHeight(SizeKind);
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible and not FItems[I].Icon.IsEmpty then
      LMax := Max(LMax, DaisyMenuIconPixels(FIconSize) + 8);
  Result := LMax + 8;
end;

procedure TDaisyFmxMainMenu.SetItems(const Value: TDaisyMenuItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxMainMenu.SetIconSize(const Value: TDaisyMenuIconSize);
begin
  if FIconSize <> Value then
  begin
    FIconSize := Value;
    SizeChanged;
    Repaint;
  end;
end;

procedure TDaisyFmxMainMenu.ItemsChanged(Sender: TObject);
begin
  SizeChanged;
  Repaint;
end;

function TDaisyFmxMainMenu.RowStyle(AIndex: Integer): TDaisyMenuRowStyle;
begin
  Result := Default(TDaisyMenuRowStyle);
  Result.IconPx := DaisyMenuIconPixels(FIconSize);
  Result.ReserveIcon := not FItems[AIndex].Icon.IsEmpty;
  Result.Hot := (AIndex = FHotIndex) or (AIndex = FOpenIndex);
end;

function TDaisyFmxMainMenu.ItemRect(AIndex: Integer): TRectF;
var
  I: Integer;
  LX: Single;
begin
  LX := 4;
  for I := 0 to FItems.Count - 1 do
  begin
    if not FItems[I].Visible then
      Continue;
    Result := RectF(LX, 4, LX + MenuRowWidth(FItems[I], RowStyle(I)), Height - 4);
    if I = AIndex then
      Exit;
    LX := Result.Right + 2;
  end;
  Result := RectF(0, 0, 0, 0);
end;

function TDaisyFmxMainMenu.ItemAt(const APoint: TPointF): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible and not FItems[I].IsSeparator and ItemRect(I).Contains(APoint) then
      Exit(I);
end;

procedure TDaisyFmxMainMenu.SetHot(AIndex: Integer);
begin
  if AIndex <> FHotIndex then
  begin
    FHotIndex := AIndex;
    Repaint;
  end;
end;

procedure TDaisyFmxMainMenu.DoMouseLeave;
begin
  inherited;
  SetHot(-1);
end;

procedure TDaisyFmxMainMenu.OpenItem(AIndex: Integer);
var
  LForm: TCommonCustomForm;
  LRect: TRectF;
begin
  if (csDesigning in ComponentState) or (Root = nil) or
    not (Root.GetObject is TCommonCustomForm) then
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
  FPopup.BiDiMode := BiDiMode;
  LRect := LocalToAbsoluteRect(ItemRect(AIndex));
  FPopup.Popup(LForm, FItems[AIndex].Items, DaisyMenuIconPixels(FIconSize), LRect, True, 2);
  Repaint;
end;

procedure TDaisyFmxMainMenu.CloseUp;
begin
  if (FPopup <> nil) and FPopup.IsOpen then
    FPopup.CloseAll;
end;

procedure TDaisyFmxMainMenu.PopupClosed(Sender: TObject);
begin
  FOpenIndex := -1;
  FClosedTick := TStopwatch.GetTimeStamp div (TStopwatch.Frequency div 1000);
  Repaint;
end;

procedure TDaisyFmxMainMenu.PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

procedure TDaisyFmxMainMenu.PopupOutsideMove(Sender: TObject; const APoint: TPointF);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(AbsoluteToLocal(APoint));
  if (LIndex >= 0) and (LIndex <> FOpenIndex) and FItems[LIndex].HasChildren and
    FItems[LIndex].Enabled then
    OpenItem(LIndex);
end;

procedure TDaisyFmxMainMenu.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LIndex: Integer;
  LNow: UInt64;
begin
  inherited;
  if Button <> TMouseButton.mbLeft then
    Exit;
  LIndex := ItemAt(PointF(X, Y));
  if (LIndex < 0) or not FItems[LIndex].Enabled or FItems[LIndex].Title then
    Exit;
  if FItems[LIndex].HasChildren then
  begin
    LNow := TStopwatch.GetTimeStamp div (TStopwatch.Frequency div 1000);
    if LNow - FClosedTick > 300 then
      // opened after the mouse-up has been fully processed so the capture sticks
      TThread.ForceQueue(nil,
        procedure
        begin
          if not (csDestroying in ComponentState) then
            OpenItem(LIndex);
        end);
  end
  else
  begin
    FItems[LIndex].Click;
    if Assigned(FOnItemClick) then
      FOnItemClick(Self, FItems[LIndex]);
  end;
end;

procedure TDaisyFmxMainMenu.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;
  SetHot(ItemAt(PointF(X, Y)));
end;

procedure TDaisyFmxMainMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  I: Integer;
begin
  if FItems.Count = 0 then
  begin
    DrawText('DaisyFmxMainMenu', ARect, DaisyWithAlpha(AColors.Text, 0.4), DaisyFontSize(SizeKind),
      False, TTextAlign.Center, TTextAlign.Center, False);
    Exit;
  end;
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible then
      DrawMenuRow(FItems[I], ItemRect(I), RowStyle(I));
end;

end.
