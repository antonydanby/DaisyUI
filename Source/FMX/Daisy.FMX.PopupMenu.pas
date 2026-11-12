unit Daisy.FMX.PopupMenu;

{
  TDaisyFmxPopupMenu - a context menu in the DaisyUI look.

  Items holds the menu (items may have an Icon with Emoji or SVG, limited to
  IconSize pixels, a ShortCut text, a Badge, check marks and sub menus).
  Set Target to a control to open the menu on its right click, or call
  Popup(X, Y) yourself (form coordinates) / PopupFor(Control, X, Y).

  The control itself is only visible at design time; at run time the menu is an
  overlay parented to the form.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.FMX.Control, Daisy.FMX.MenuPopup;

type
  TDaisyFmxPopupMenu = class(TDaisyFmxMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FIconSize: TDaisyMenuIconSize;
    FTarget: TControl;
    FHooked: Boolean;
    FOldMouseUp: TMouseEvent;
    FPopup: TDaisyFmxMenuPopup;
    FOnPopup: TNotifyEvent;
    FOnItemClick: TDaisyMenuItemEvent;
    procedure SetItems(const Value: TDaisyMenuItems);
    procedure SetIconSize(const Value: TDaisyMenuIconSize);
    procedure SetTarget(const Value: TControl);
    procedure ItemsChanged(Sender: TObject);
    procedure Hook;
    procedure Unhook;
    procedure TargetMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    procedure PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // X and Y are form coordinates
    procedure Popup(X, Y: Single);
    // X and Y are local to AControl
    procedure PopupFor(AControl: TControl; X, Y: Single);
    procedure Close;
  published
    property Items: TDaisyMenuItems read FItems write SetItems;
    // Icons are drawn at 16, 24 or 32 pixels
    property IconSize: TDaisyMenuIconSize read FIconSize write SetIconSize default mis16;
    // The control that opens this menu when it is right clicked
    property Target: TControl read FTarget write SetTarget;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
    property OnItemClick: TDaisyMenuItemEvent read FOnItemClick write FOnItemClick;
  end;

implementation

constructor TDaisyFmxPopupMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyMenuItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  SetBounds(Position.X, Position.Y, 36, 36);
  HitTest := False;
end;

destructor TDaisyFmxPopupMenu.Destroy;
begin
  Unhook;
  FTarget := nil;
  FItems.Free;
  inherited Destroy;
end;

procedure TDaisyFmxPopupMenu.Loaded;
begin
  inherited;
  if not (csDesigning in ComponentState) then
  begin
    Visible := False;
    Hook;
  end;
end;

procedure TDaisyFmxPopupMenu.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FTarget) then
  begin
    Unhook;
    FTarget := nil;
  end;
end;

function TDaisyFmxPopupMenu.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyFmxPopupMenu.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxPopupMenu.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base200;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.2);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxPopupMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LBox: TRectF;
begin
  LBox := ARect;
  LBox.Inflate(-8, -8);
  DrawIconPath('M4 6h16M4 12h16M4 18h16', LBox, AColors.Text);
end;

procedure TDaisyFmxPopupMenu.SetItems(const Value: TDaisyMenuItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxPopupMenu.SetIconSize(const Value: TDaisyMenuIconSize);
begin
  FIconSize := Value;
end;

procedure TDaisyFmxPopupMenu.ItemsChanged(Sender: TObject);
begin
  Repaint;
end;

procedure TDaisyFmxPopupMenu.SetTarget(const Value: TControl);
begin
  if Value = FTarget then
    Exit;
  Unhook;
  if FTarget <> nil then
    FTarget.RemoveFreeNotification(Self);
  FTarget := Value;
  if FTarget <> nil then
    FTarget.FreeNotification(Self);
  if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    Hook;
end;

procedure TDaisyFmxPopupMenu.Hook;
begin
  if FHooked or (FTarget = nil) or (csDesigning in ComponentState) then
    Exit;
  FOldMouseUp := FTarget.OnMouseUp;
  FTarget.OnMouseUp := TargetMouseUp;
  FHooked := True;
end;

procedure TDaisyFmxPopupMenu.Unhook;
var
  LMine, LCurrent: TMouseEvent;
begin
  if not FHooked then
    Exit;
  LMine := TargetMouseUp;
  if FTarget <> nil then
  begin
    LCurrent := FTarget.OnMouseUp;
    if (TMethod(LCurrent).Code = TMethod(LMine).Code) and
      (TMethod(LCurrent).Data = TMethod(LMine).Data) then
      FTarget.OnMouseUp := FOldMouseUp;
  end;
  FHooked := False;
  FOldMouseUp := nil;
end;

procedure TDaisyFmxPopupMenu.TargetMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Assigned(FOldMouseUp) then
    FOldMouseUp(Sender, Button, Shift, X, Y);
  if (Button = TMouseButton.mbRight) and Enabled and (Sender is TControl) then
    PopupFor(TControl(Sender), X, Y);
end;

procedure TDaisyFmxPopupMenu.PopupFor(AControl: TControl; X, Y: Single);
var
  LPoint: TPointF;
begin
  LPoint := AControl.LocalToAbsolute(PointF(X, Y));
  Popup(LPoint.X, LPoint.Y);
end;

procedure TDaisyFmxPopupMenu.Popup(X, Y: Single);
var
  LForm: TCommonCustomForm;
begin
  if (FItems.Count = 0) or (Root = nil) or not (Root.GetObject is TCommonCustomForm) then
    Exit;
  LForm := TCommonCustomForm(Root.GetObject);
  if Assigned(FOnPopup) then
    FOnPopup(Self);
  if FPopup = nil then
  begin
    FPopup := TDaisyFmxMenuPopup.Create(Self);
    FPopup.OnItemClick := PopupItemClick;
  end;
  if FPopup.IsOpen then
    FPopup.CloseAll;
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;
  FPopup.BiDiMode := BiDiMode;
  FPopup.Popup(LForm, FItems, DaisyMenuIconPixels(FIconSize), RectF(X, Y, X, Y), True, 0);
end;

procedure TDaisyFmxPopupMenu.Close;
begin
  if (FPopup <> nil) and FPopup.IsOpen then
    FPopup.CloseAll;
end;

procedure TDaisyFmxPopupMenu.PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

end.
