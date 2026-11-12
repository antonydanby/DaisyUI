unit Daisy.FMX.DatePicker;

{
  TDaisyFmxDatePicker - a text input that returns a date picked from a calendar.

  The date is shown as text (DateFormat, empty = the system short date) and can
  be typed as well as picked. The calendar opens from the icon at the end of the
  field, or with F4 / Alt+Down. PopupPlacement chooses where it appears: below
  (default), above, left or right of the field; it flips to the opposite side
  when it does not fit in the form.

  Date is the picked date (0 = no date). The popup is created the first time it
  is opened and lives on the form.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math, System.DateUtils,
  FMX.Types, FMX.Controls, FMX.Forms, Daisy.Theme, Daisy.Widgets, Daisy.Calendars,
  Daisy.FMX.Control, Daisy.FMX.Calendar, Daisy.FMX.TextInput;

type
  TDaisyFmxDatePopup = class(TDaisyFmxCalendar)
  strict private
    FOnClosed: TNotifyEvent;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DatePicked(ADate: TDateTime); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Popup(ALeft, ATop, AWidth, AHeight: Single);
    procedure Close;
    procedure PassKey(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
  end;

  TDaisyFmxDatePicker = class(TDaisyFmxTextInput)
  strict private
    FDate: TDateTime;
    FDateFormat: string;
    FPlacement: TDaisyPopupPlacement;
    FCalVariant: TDaisyVariant;
    FFirstDay: TDaisyWeekDay;
    FShowOutside: Boolean;
    FPopup: TDaisyFmxDatePopup;
    FCalIcon: TDaisyIconSource;
    FSyncing: Boolean;
    FIconDown: Boolean;
    FOnDateChange: TNotifyEvent;
    procedure SetDate(const Value: TDateTime);
    procedure SetDateFormat(const Value: string);
    function IsDateStored: Boolean;
    procedure InternalSetDate(AValue: TDateTime; ASyncText: Boolean);
    procedure SyncText;
    function OnIcon(X, Y: Single): Boolean;
    procedure PopupChange(Sender: TObject);
    procedure PopupClosed(Sender: TObject);
  protected
    function EndIconSource: TDaisyIconSource; override;
    procedure TextEdited; override;
    procedure Loaded; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
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

{ TDaisyFmxDatePopup }

constructor TDaisyFmxDatePopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Visible := False;
  CanFocus := False;
  AutoCapture := False;
end;

procedure TDaisyFmxDatePopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if (X < 0) or (Y < 0) or (X >= Width) or (Y >= Height) then
    Close
  else
    inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDaisyFmxDatePopup.DatePicked(ADate: TDateTime);
begin
  Close;
end;

procedure TDaisyFmxDatePopup.Popup(ALeft, ATop, AWidth, AHeight: Single);
begin
  SetBounds(ALeft, ATop, AWidth, AHeight);
  Visible := True;
  BringToFront;
  Capture;
  Repaint;
end;

procedure TDaisyFmxDatePopup.Close;
begin
  if not Visible then
    Exit;
  ReleaseCapture;
  Visible := False;
  if Assigned(FOnClosed) then
    FOnClosed(Self);
end;

procedure TDaisyFmxDatePopup.PassKey(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  KeyDown(Key, KeyChar, Shift);
end;

{ TDaisyFmxDatePicker }

constructor TDaisyFmxDatePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPlacement := ppShowBelow;
  FFirstDay := wdMonday;
  FCalIcon := TDaisyIconSource.Create;
  FCalIcon.Emoji := #$D83D#$DCC5;
end;

destructor TDaisyFmxDatePicker.Destroy;
begin
  FCalIcon.Free;
  inherited Destroy;
end;

function TDaisyFmxDatePicker.EndIconSource: TDaisyIconSource;
begin
  Result := inherited EndIconSource;
  if (Result = nil) or Result.IsEmpty then
    Result := FCalIcon;
end;

function TDaisyFmxDatePicker.IsDateStored: Boolean;
begin
  Result := FDate <> 0;
end;

procedure TDaisyFmxDatePicker.SetDate(const Value: TDateTime);
begin
  InternalSetDate(DateOf(Value), True);
end;

procedure TDaisyFmxDatePicker.SetDateFormat(const Value: string);
begin
  if FDateFormat <> Value then
  begin
    FDateFormat := Value;
    if (FDate <> 0) and not (csLoading in ComponentState) then
      SyncText;
  end;
end;

procedure TDaisyFmxDatePicker.InternalSetDate(AValue: TDateTime; ASyncText: Boolean);
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

procedure TDaisyFmxDatePicker.SyncText;
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

procedure TDaisyFmxDatePicker.TextEdited;
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

procedure TDaisyFmxDatePicker.Loaded;
var
  LDate: TDateTime;
begin
  inherited Loaded;
  if FDate <> 0 then
    SyncText
  else if (Trim(Text) <> '') and DaisyTryParsePickerDate(Text, FDateFormat, LDate) then
    FDate := DateOf(LDate);
end;

procedure TDaisyFmxDatePicker.DoExit;
begin
  CloseUp;
  inherited DoExit;
  if not (csDestroying in ComponentState) then
    SyncText;
end;

function TDaisyFmxDatePicker.IsOpen: Boolean;
begin
  Result := (FPopup <> nil) and FPopup.Visible;
end;

procedure TDaisyFmxDatePicker.DropDown;
var
  LForm: TCommonCustomForm;
  LField: TRectF;
  LOrigin: TPointF;
begin
  if IsOpen or ReadOnly or not Enabled or (csDesigning in ComponentState) then
    Exit;
  if (Root = nil) or not (Root.GetObject is TCommonCustomForm) then
    Exit;
  LForm := TCommonCustomForm(Root.GetObject);
  if FPopup = nil then
  begin
    FPopup := TDaisyFmxDatePopup.Create(Self);
    FPopup.OnChange := PopupChange;
    FPopup.OnClosed := PopupClosed;
  end;
  if FPopup.Parent <> LForm then
    LForm.AddObject(FPopup);
  FPopup.ThemeKind := ThemeKind;
  FPopup.BiDiMode := BiDiMode;
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
  LField := LocalToAbsoluteRect(FieldRect);
  LOrigin := DaisyPopupOrigin(LField,
    TRectF.Create(0, 0, LForm.ClientWidth, LForm.ClientHeight), CPopupWidth, CPopupHeight, 4,
    FPlacement);
  FPopup.Popup(LOrigin.X, LOrigin.Y, CPopupWidth, CPopupHeight);
  if CanFocus and not IsFocused then
    SetFocus;
  Repaint;
end;

procedure TDaisyFmxDatePicker.CloseUp;
begin
  if IsOpen then
    FPopup.Close;
end;

procedure TDaisyFmxDatePicker.PopupChange(Sender: TObject);
begin
  if not FSyncing then
    InternalSetDate(DateOf(FPopup.SelectedDate), True);
end;

procedure TDaisyFmxDatePicker.PopupClosed(Sender: TObject);
begin
  Repaint;
end;

function TDaisyFmxDatePicker.OnIcon(X, Y: Single): Boolean;
var
  LBox: TRectF;
begin
  LBox := EndIconRect;
  LBox.Inflate(6, 6);
  Result := LBox.Contains(PointF(X, Y));
end;

procedure TDaisyFmxDatePicker.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FIconDown := (Button = TMouseButton.mbLeft) and OnIcon(X, Y);
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDaisyFmxDatePicker.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LHit: Boolean;
begin
  LHit := FIconDown and (Button = TMouseButton.mbLeft) and OnIcon(X, Y);
  FIconDown := False;
  inherited MouseUp(Button, Shift, X, Y);
  if LHit and Enabled and not ReadOnly then
    // opened after the mouse-up has been fully processed so the capture sticks
    TThread.ForceQueue(nil,
      procedure
      begin
        if not (csDestroying in ComponentState) then
          DropDown;
      end);
end;

procedure TDaisyFmxDatePicker.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if IsOpen then
  begin
    case Key of
      vkEscape, vkReturn:
        begin
          CloseUp;
          Key := 0;
          KeyChar := #0;
        end;
      vkUp, vkDown, vkPrior, vkNext:
        begin
          FPopup.PassKey(Key, KeyChar, Shift);
          Key := 0;
          KeyChar := #0;
        end;
    end;
  end
  else if (Key = vkF4) or ((Key = vkDown) and (ssAlt in Shift)) then
  begin
    DropDown;
    Key := 0;
    KeyChar := #0;
  end;
  if (Key <> 0) or (KeyChar <> #0) then
    inherited KeyDown(Key, KeyChar, Shift);
end;

end.
