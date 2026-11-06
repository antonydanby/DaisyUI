unit Daisy.VCL.DatePicker;

{
  TDaisyDatePicker - a text input that returns a date picked from a calendar.

  The date is shown as text (DateFormat, empty = the system short date) and can
  be typed as well as picked. The calendar opens from the icon at the end of the
  field, or with F4 / Alt+Down. PopupPlacement chooses where it appears: below
  (default), above, left or right of the field; it flips to the opposite side
  when it does not fit on the screen.

  Date is the picked date (0 = no date). The popup is a borderless,
  non-activating window, created the first time it is opened.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math, System.DateUtils,
  Vcl.Controls, Vcl.Forms, Daisy.Theme, Daisy.Widgets, Daisy.Calendars, Daisy.VCL.Control,
  Daisy.VCL.Calendar, Daisy.VCL.TextInput;

const
  WM_DAISY_DATEPICK = WM_APP + 43;

type
  TDaisyDatePopup = class(TDaisyCalendar)
  strict private
    FInButtonUp: Boolean;
    FOnClosed: TNotifyEvent;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DatePicked(ADate: TDateTime); override;
  public
    constructor Create(AOwner: TComponent); override;
    function CanFocus: Boolean; override;
    procedure Popup(ALeft, ATop, AWidth, AHeight: Integer);
    procedure Close;
    procedure PassKey(var Key: Word; Shift: TShiftState);
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
  end;

  TDaisyDatePicker = class(TDaisyTextInput)
  strict private
    FDate: TDateTime;
    FDateFormat: string;
    FPlacement: TDaisyPopupPlacement;
    FCalVariant: TDaisyVariant;
    FFirstDay: TDaisyWeekDay;
    FShowOutside: Boolean;
    FPopup: TDaisyDatePopup;
    FCalIcon: TDaisyIconSource;
    FSyncing: Boolean;
    FIconDown: Boolean;
    FClosedTick: Cardinal;
    FOnDateChange: TNotifyEvent;
    procedure SetDate(const Value: TDateTime);
    procedure SetDateFormat(const Value: string);
    function IsDateStored: Boolean;
    procedure InternalSetDate(AValue: TDateTime; ASyncText: Boolean);
    procedure SyncText;
    function OnIcon(X, Y: Integer): Boolean;
    procedure PopupChange(Sender: TObject);
    procedure PopupClosed(Sender: TObject);
    procedure WMDatePick(var Message: TMessage); message WM_DAISY_DATEPICK;
  protected
    function EndIconSource: TDaisyIconSource; override;
    procedure TextEdited; override;
    procedure Loaded; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DropDown;
    procedure CloseUp;
    function IsOpen: Boolean;
  published
    // The picked date; 0 = no date
    property Date: TDateTime read FDate write SetDate stored IsDateStored;
    // Format of the date text (e.g. yyyy-mm-dd); empty = the system short date
    property DateFormat: string read FDateFormat write SetDateFormat;
    // Where the calendar appears relative to the field
    property PopupPlacement: TDaisyPopupPlacement read FPlacement write FPlacement default ppShowBelow;
    // Colour of the selected day in the calendar
    property CalendarVariant: TDaisyVariant read FCalVariant write FCalVariant default dvDefault;
    property FirstDayOfWeek: TDaisyWeekDay read FFirstDay write FFirstDay default wdMonday;
    property ShowOutsideDays: Boolean read FShowOutside write FShowOutside default False;
    property OnDateChange: TNotifyEvent read FOnDateChange write FOnDateChange;
  end;

implementation

const
  CPopupWidth = 304;
  CPopupHeight = 328;

{ TDaisyDatePopup }

constructor TDaisyDatePopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csParentBackground] + [csOpaque];
  Visible := False;
  TabStop := False;
end;

function TDaisyDatePopup.CanFocus: Boolean;
begin
  Result := False;
end;

procedure TDaisyDatePopup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_CLIPCHILDREN;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  Params.WndParent := GetDesktopWindow;
end;

procedure TDaisyDatePopup.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TDaisyDatePopup.WMLButtonUp(var Message: TWMLButtonUp);
begin
  // TControl releases its mouse capture on button-up, which would close the popup
  FInButtonUp := True;
  try
    inherited;
  finally
    FInButtonUp := False;
  end;
  if Visible and HandleAllocated and (GetCapture <> Handle) then
    MouseCapture := True;
end;

procedure TDaisyDatePopup.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if Visible and not FInButtonUp and (HWND(Message.LParam) <> Handle) then
    Close;
end;

procedure TDaisyDatePopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (X < 0) or (Y < 0) or (X >= ClientWidth) or (Y >= ClientHeight) then
    Close
  else
    inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDaisyDatePopup.DatePicked(ADate: TDateTime);
begin
  Close;
end;

procedure TDaisyDatePopup.Popup(ALeft, ATop, AWidth, AHeight: Integer);
var
  LDiameter: Integer;
begin
  Color := DaisyToColor(Theme.Base100);
  HandleNeeded;
  SetBounds(ALeft, ATop, AWidth, AHeight);
  LDiameter := 2 * ResolvedCornerRadius;
  SetWindowRgn(Handle, CreateRoundRectRgn(0, 0, AWidth + 1, AHeight + 1, LDiameter, LDiameter), False);
  Visible := True;
  SetWindowPos(Handle, HWND_TOPMOST, ALeft, ATop, AWidth, AHeight, SWP_NOACTIVATE or SWP_SHOWWINDOW);
  Invalidate;
  MouseCapture := True;
end;

procedure TDaisyDatePopup.Close;
begin
  if not Visible then
    Exit;
  Visible := False;
  if HandleAllocated then
    ShowWindow(Handle, SW_HIDE);
  if GetCapture = Handle then
    ReleaseCapture;
  if Assigned(FOnClosed) then
    FOnClosed(Self);
end;

procedure TDaisyDatePopup.PassKey(var Key: Word; Shift: TShiftState);
begin
  KeyDown(Key, Shift);
end;

{ TDaisyDatePicker }

constructor TDaisyDatePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPlacement := ppShowBelow;
  FFirstDay := wdMonday;
  FCalIcon := TDaisyIconSource.Create;
  FCalIcon.Emoji := #$D83D#$DCC5;
end;

destructor TDaisyDatePicker.Destroy;
begin
  FCalIcon.Free;
  inherited Destroy;
end;

function TDaisyDatePicker.EndIconSource: TDaisyIconSource;
begin
  Result := inherited EndIconSource;
  if (Result = nil) or Result.IsEmpty then
    Result := FCalIcon;
end;

function TDaisyDatePicker.IsDateStored: Boolean;
begin
  Result := FDate <> 0;
end;

procedure TDaisyDatePicker.SetDate(const Value: TDateTime);
begin
  InternalSetDate(DateOf(Value), True);
end;

procedure TDaisyDatePicker.SetDateFormat(const Value: string);
begin
  if FDateFormat <> Value then
  begin
    FDateFormat := Value;
    if (FDate <> 0) and not (csLoading in ComponentState) then
      SyncText;
  end;
end;

procedure TDaisyDatePicker.InternalSetDate(AValue: TDateTime; ASyncText: Boolean);
var
  LChanged, LWas: Boolean;
begin
  LChanged := FDate <> AValue;
  FDate := AValue;
  if ASyncText and not (csLoading in ComponentState) then
    SyncText;
  if IsOpen then
  begin
    LWas := FSyncing;
    FSyncing := True;
    try
      FPopup.SelectedDate := FDate;
      if FDate <> 0 then
        FPopup.ViewMonth := FDate;
    finally
      FSyncing := LWas;
    end;
  end;
  if LChanged and Assigned(FOnDateChange) and not (csLoading in ComponentState) then
    FOnDateChange(Self);
end;

procedure TDaisyDatePicker.SyncText;
var
  LWas: Boolean;
begin
  LWas := FSyncing;
  FSyncing := True;
  try
    Text := DaisyFormatPickerDate(FDate, FDateFormat);
  finally
    FSyncing := LWas;
  end;
end;

procedure TDaisyDatePicker.TextEdited;
var
  LDate: TDateTime;
begin
  inherited TextEdited;
  if FSyncing or (csLoading in ComponentState) then
    Exit;
  if (Trim(Text) <> '') and DaisyTryParsePickerDate(Text, FDateFormat, LDate) then
    InternalSetDate(DateOf(LDate), False)
  else
    InternalSetDate(0, False);
end;

procedure TDaisyDatePicker.Loaded;
var
  LDate: TDateTime;
begin
  inherited Loaded;
  if FDate <> 0 then
    SyncText
  else if (Trim(Text) <> '') and DaisyTryParsePickerDate(Text, FDateFormat, LDate) then
    FDate := DateOf(LDate);
end;

procedure TDaisyDatePicker.DoExit;
begin
  CloseUp;
  inherited DoExit;
  if not (csDestroying in ComponentState) then
    SyncText;
end;

function TDaisyDatePicker.IsOpen: Boolean;
begin
  Result := (FPopup <> nil) and FPopup.Visible;
end;

procedure TDaisyDatePicker.DropDown;
var
  LField: TRect;
  LTopLeft, LBottomRight: TPoint;
  LOrigin: TPointF;
  LWidth, LHeight: Integer;
begin
  if IsOpen or ReadOnly or not Enabled or (csDesigning in ComponentState) or not HandleAllocated then
    Exit;
  if FPopup = nil then
  begin
    FPopup := TDaisyDatePopup.Create(Self);
    FPopup.OnChange := PopupChange;
    FPopup.OnClosed := PopupClosed;
  end;
  FPopup.ThemeKind := ThemeKind;
  FPopup.Font.Assign(Font);
  FPopup.Variant := FCalVariant;
  FPopup.FirstDayOfWeek := FFirstDay;
  FPopup.ShowOutsideDays := FShowOutside;
  FSyncing := True;
  try
    FPopup.SelectedDate := FDate;
    if FDate <> 0 then
      FPopup.ViewMonth := FDate
    else
      FPopup.ViewMonth := DateOf(Now);
  finally
    FSyncing := False;
  end;
  LField := FieldRect;
  LTopLeft := ClientToScreen(LField.TopLeft);
  LBottomRight := ClientToScreen(LField.BottomRight);
  LWidth := ScaleValue(CPopupWidth);
  LHeight := ScaleValue(CPopupHeight);
  LOrigin := DaisyPopupOrigin(TRectF.Create(LTopLeft.X, LTopLeft.Y, LBottomRight.X, LBottomRight.Y),
    TRectF.Create(Screen.MonitorFromWindow(Handle).WorkareaRect), LWidth, LHeight, ScaleValue(4),
    FPlacement);
  FPopup.Popup(Round(LOrigin.X), Round(LOrigin.Y), LWidth, LHeight);
  if CanFocus and not Focused then
    SetFocus;
  Invalidate;
end;

procedure TDaisyDatePicker.CloseUp;
begin
  if IsOpen then
    FPopup.Close;
end;

procedure TDaisyDatePicker.PopupChange(Sender: TObject);
begin
  if not FSyncing then
    InternalSetDate(DateOf(FPopup.SelectedDate), True);
end;

procedure TDaisyDatePicker.PopupClosed(Sender: TObject);
begin
  FClosedTick := GetTickCount;
  Invalidate;
end;

function TDaisyDatePicker.OnIcon(X, Y: Integer): Boolean;
var
  LBox: TRect;
begin
  LBox := EndIconRect;
  InflateRect(LBox, ScaleValue(6), ScaleValue(6));
  Result := PtInRect(LBox, Point(X, Y));
end;

procedure TDaisyDatePicker.WMDatePick(var Message: TMessage);
begin
  DropDown;
end;

procedure TDaisyDatePicker.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIconDown := (Button = mbLeft) and OnIcon(X, Y);
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDaisyDatePicker.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LHit: Boolean;
begin
  LHit := FIconDown and (Button = mbLeft) and OnIcon(X, Y);
  FIconDown := False;
  inherited MouseUp(Button, Shift, X, Y);
  if LHit and Enabled and not ReadOnly and (GetTickCount - FClosedTick > 300) and HandleAllocated then
    PostMessage(Handle, WM_DAISY_DATEPICK, 0, 0); // after the mouse-up so the capture sticks
end;

procedure TDaisyDatePicker.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if IsOpen then
  begin
    case Key of
      VK_ESCAPE, VK_RETURN:
        begin
          CloseUp;
          Key := 0;
        end;
      VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT:
        begin
          FPopup.PassKey(Key, Shift);
          Key := 0;
        end;
    end;
  end
  else if (Key = VK_F4) or ((Key = VK_DOWN) and (ssAlt in Shift)) then
  begin
    DropDown;
    Key := 0;
  end;
  if Key <> 0 then
    inherited KeyDown(Key, Shift);
end;

end.
