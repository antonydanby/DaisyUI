unit Daisy.VCL.PopupMenu;

{
  TDaisyPopupMenu - a context menu in the DaisyUI look.

  Items holds the menu (items may have an Icon with Emoji or SVG, limited to
  IconSize pixels, a ShortCut text, a Badge, check marks and sub menus).
  Set Target to a control to open the menu on its right click, or call
  Popup(X, Y) yourself (screen coordinates).

  The control itself is only visible at design time; at run time the menu is a
  borderless, non-activating popup window.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  System.Math, Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.VCL.Control, Daisy.VCL.MenuPopup;

type
  TDaisyPopupMenu = class(TDaisyMenuSurface)
  strict private
    FItems: TDaisyMenuItems;
    FIconSize: TDaisyMenuIconSize;
    FTarget: TControl;
    FHooked: Boolean;
    FOldProc: TWndMethod;
    FPopup: TDaisyMenuPopup;
    FOnPopup: TNotifyEvent;
    FOnItemClick: TDaisyMenuItemEvent;
    procedure SetItems(const Value: TDaisyMenuItems);
    procedure SetIconSize(const Value: TDaisyMenuIconSize);
    procedure SetTarget(const Value: TControl);
    procedure ItemsChanged(Sender: TObject);
    procedure Hook;
    procedure Unhook;
    procedure TargetProc(var Message: TMessage);
    procedure PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InitiateAction; override;
    // X and Y are screen coordinates
    procedure Popup(X, Y: Integer);
    procedure PopupAtCursor;
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

constructor TDaisyPopupMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyMenuItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  SetBounds(Left, Top, 36, 36);
end;

destructor TDaisyPopupMenu.Destroy;
begin
  Unhook;
  FTarget := nil;
  FItems.Free;
  inherited Destroy;
end;

procedure TDaisyPopupMenu.InitiateAction;
var
  I: Integer;
begin
  inherited InitiateAction;
  for I := 0 to FItems.Count - 1 do
    FItems[I].UpdateActions;
end;

procedure TDaisyPopupMenu.Loaded;
begin
  inherited;
  if not (csDesigning in ComponentState) then
  begin
    Visible := False;
    Hook;
  end;
end;

procedure TDaisyPopupMenu.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FTarget) then
  begin
    Unhook;
    FTarget := nil;
  end;
end;

function TDaisyPopupMenu.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyPopupMenu.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base200;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.2);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyPopupMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LBox: TRect;
begin
  LBox := ARect;
  InflateRect(LBox, -ScaleValue(8), -ScaleValue(8));
  DrawIconPath('M4 6h16M4 12h16M4 18h16', TRectF.Create(LBox), AColors.Text);
end;

procedure TDaisyPopupMenu.SetItems(const Value: TDaisyMenuItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyPopupMenu.SetIconSize(const Value: TDaisyMenuIconSize);
begin
  FIconSize := Value;
end;

procedure TDaisyPopupMenu.ItemsChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TDaisyPopupMenu.SetTarget(const Value: TControl);
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

procedure TDaisyPopupMenu.Hook;
begin
  if FHooked or (FTarget = nil) or (csDesigning in ComponentState) then
    Exit;
  FOldProc := FTarget.WindowProc;
  FTarget.WindowProc := TargetProc;
  FHooked := True;
end;

procedure TDaisyPopupMenu.Unhook;
var
  LMine, LCurrent: TWndMethod;
begin
  if not FHooked then
    Exit;
  LMine := TargetProc;
  if FTarget <> nil then
  begin
    LCurrent := FTarget.WindowProc;
    if (TMethod(LCurrent).Code = TMethod(LMine).Code) and
      (TMethod(LCurrent).Data = TMethod(LMine).Data) then
      FTarget.WindowProc := FOldProc;
  end;
  FHooked := False;
  FOldProc := nil;
end;

procedure TDaisyPopupMenu.TargetProc(var Message: TMessage);
begin
  if (Message.Msg = WM_CONTEXTMENU) and Enabled then
  begin
    if (Message.LParamLo = $FFFF) and (Message.LParamHi = $FFFF) then
      PopupAtCursor
    else
      Popup(SmallInt(Message.LParamLo), SmallInt(Message.LParamHi));
    Message.Result := 1;
    Exit;
  end;
  FOldProc(Message);
end;

procedure TDaisyPopupMenu.PopupAtCursor;
begin
  Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TDaisyPopupMenu.Popup(X, Y: Integer);
begin
  if FItems.Count = 0 then
    Exit;
  if Assigned(FOnPopup) then
    FOnPopup(Self);
  if FPopup = nil then
  begin
    FPopup := TDaisyMenuPopup.Create(Self);
    FPopup.OnItemClick := PopupItemClick;
  end;
  if FPopup.IsOpen then
    FPopup.CloseAll;
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;
  FPopup.Font.Assign(Font);
  FPopup.Popup(FItems, DaisyMenuIconPixels(FIconSize), Rect(X, Y, X, Y), True, 0);
end;

procedure TDaisyPopupMenu.Close;
begin
  if (FPopup <> nil) and FPopup.IsOpen then
    FPopup.CloseAll;
end;

procedure TDaisyPopupMenu.PopupItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

end.
