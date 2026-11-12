unit MainVCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.ActnList, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Daisy.Theme, Daisy.Widgets, Daisy.Menus,
  Daisy.TextEdit, Daisy.VCL.Control, Daisy.VCL.FormStyler, Daisy.VCL.Panel, Daisy.VCL.Labels,
  Daisy.VCL.Select, Daisy.VCL.Toggle, Daisy.VCL.TextInput, Daisy.VCL.TextArea, Daisy.VCL.MenuPopup,
  Daisy.VCL.Menu, Daisy.VCL.MainMenu, Daisy.VCL.PopupMenu, Daisy.VCL.CheckBox,
  Daisy.VCL.PageControl, Daisy.VCL.Button, Daisy.Calendars, Daisy.VCL.Calendar, Daisy.VCL.DatePicker,
  Daisy.VCL.ThemeController, System.Actions;

type
  TFormEdits = class(TForm)
    pnlTop: TPanel;
    lblTheme: TLabel;
    lblStatusLine: TLabel;
    chkTitleBar: TDaisyCheckBox;
    chkRTL: TDaisyCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actPrimaryToggle: TAction;
    actSuccessToggle: TAction;
    actNew: TAction;
    actAutoSave: TAction;
    pcMain: TDaisyPageControl;
    tsToggle: TDaisyTabSheet;
    tsInput: TDaisyTabSheet;
    tsArea: TDaisyTabSheet;
    tsSelect: TDaisyTabSheet;
    tsMenu: TDaisyTabSheet;
    tsMenuMore: TDaisyTabSheet;
    Styler: TDaisyFormStyler;
    ppMenu: TDaisyPopupMenu;
    mmMain: TDaisyMainMenu;
    selTheme: TDaisySelect;
    themeCtl: TDaisyThemeController;
    tgBasic: TDaisyToggle;
    tgChecked: TDaisyToggle;
    tgDisabled: TDaisyToggle;
    tgDisabledOn: TDaisyToggle;
    tgIcons: TDaisyToggle;
    tgXs: TDaisyToggle;
    tgSm: TDaisyToggle;
    tgMd: TDaisyToggle;
    tgLg: TDaisyToggle;
    tgXl: TDaisyToggle;
    tgNeutral: TDaisyToggle;
    tgPrimary: TDaisyToggle;
    tgSecondary: TDaisyToggle;
    tgAccent: TDaisyToggle;
    tgInfo: TDaisyToggle;
    tgSuccess: TDaisyToggle;
    tgWarning: TDaisyToggle;
    tgError: TDaisyToggle;
    tiBasic: TDaisyTextInput;
    tiGhost: TDaisyTextInput;
    tiPrimary: TDaisyTextInput;
    tiDisabled: TDaisyTextInput;
    tiSearch: TDaisyTextInput;
    tiEmoji: TDaisyTextInput;
    tiPassword: TDaisyTextInput;
    tiEndEmoji: TDaisyTextInput;
    tiXs: TDaisyTextInput;
    tiSm: TDaisyTextInput;
    tiMd: TDaisyTextInput;
    tiLg: TDaisyTextInput;
    tiXl: TDaisyTextInput;
    tiLegend: TDaisyTextInput;
    tiFloating: TDaisyTextInput;
    tiBefore: TDaisyTextInput;
    tiAfter: TDaisyTextInput;
    tiSuccess: TDaisyTextInput;
    tiWarning: TDaisyTextInput;
    tiError: TDaisyTextInput;
    tiSoft: TDaisyTextInput;
    taBasic: TDaisyTextArea;
    taLong: TDaisyTextArea;
    taGhost: TDaisyTextArea;
    selMany: TDaisySelect;
    selScroll: TDaisySelect;
    mnVertical: TDaisyMenu;
    mnIconsOnly: TDaisyMenu;
    mnHorizontal: TDaisyMenu;
    mnSm: TDaisyMenu;
    mnLg: TDaisyMenu;
    mnBadge: TDaisyMenu;
    mnCollapsible: TDaisyMenu;
    pnlRightClick: TDaisyPanel;
    lblRightClick: TDaisyLabel;
    tsCalendar: TDaisyTabSheet;
    lblCalSingle: TDaisyLabel;
    calSingle: TDaisyCalendar;
    lblCalRange: TDaisyLabel;
    calRange: TDaisyCalendar;
    lblCalOptions: TDaisyLabel;
    calOptions: TDaisyCalendar;
    lblFirstDay: TDaisyLabel;
    selFirstDay: TDaisySelect;
    chkOutsideDays: TDaisyCheckBox;
    btnCalToday: TDaisyButton;
    lblCalPicker: TDaisyLabel;
    dpCalendar: TDaisyDatePicker;
    lblPlacement: TDaisyLabel;
    selPlacement: TDaisySelect;
    procedure CalendarChange(Sender: TObject);
    procedure DatePickerChange(Sender: TObject);
    procedure DatePlacementChange(Sender: TObject);
    procedure CalendarOptionChange(Sender: TObject);
    procedure CalendarTodayClick(Sender: TObject);
    procedure ThemeSelectChange(Sender: TObject);
    procedure RTLChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ToggleActionExecute(Sender: TObject);
    procedure MenuActionExecute(Sender: TObject);
    procedure MenuItemClick(Sender: TObject; AItem: TDaisyMenuItem);
  end;

var
  FormEdits: TFormEdits;

implementation

{$R *.dfm}

procedure TFormEdits.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TFormEdits.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TFormEdits.RTLChange(Sender: TObject);
const
  Modes: array[Boolean] of TBiDiMode = (bdLeftToRight, bdRightToLeft);
begin
  if BiDiMode = Modes[chkRTL.Checked] then
    Exit;
  TDaisyControl.ApplyBiDiMode(Self, Modes[chkRTL.Checked]);
end;

procedure TFormEdits.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TFormEdits.chkTitleBarClick(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TFormEdits.CalendarChange(Sender: TObject);
var
  LCalendar: TDaisyCalendar;
begin
  LCalendar := Sender as TDaisyCalendar;
  if LCalendar.SelectionMode = csRange then
    lblStatusLine.Caption := Format('%s: %s to %s', [LCalendar.Name,
      DateToStr(LCalendar.RangeStart), DateToStr(LCalendar.RangeEnd)])
  else
    lblStatusLine.Caption := Format('%s: %s', [LCalendar.Name, DateToStr(LCalendar.SelectedDate)]);
end;

procedure TFormEdits.CalendarOptionChange(Sender: TObject);
begin
  calOptions.FirstDayOfWeek := TDaisyWeekDay(selFirstDay.ItemIndex);
  calOptions.ShowOutsideDays := chkOutsideDays.Checked;
end;

procedure TFormEdits.CalendarTodayClick(Sender: TObject);
begin
  calOptions.GoToday;
end;

procedure TFormEdits.DatePickerChange(Sender: TObject);
begin
  if dpCalendar.Date = 0 then
    lblStatusLine.Caption := 'dpCalendar: no date'
  else
    lblStatusLine.Caption := 'dpCalendar: ' + DateToStr(dpCalendar.Date);
end;

procedure TFormEdits.DatePlacementChange(Sender: TObject);
begin
  dpCalendar.PopupPlacement := TDaisyPopupPlacement(selPlacement.ItemIndex);
end;

procedure TFormEdits.ToggleActionExecute(Sender: TObject);
begin
  lblStatusLine.Caption := Format('%s: %s', [(Sender as TAction).Name,
    BoolToStr((Sender as TAction).Checked, True)]);
end;

procedure TFormEdits.MenuActionExecute(Sender: TObject);
begin
  lblStatusLine.Caption := Format('Action %s executed', [(Sender as TAction).Name]);
end;

procedure TFormEdits.MenuItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  lblStatusLine.Caption := Format('%s: "%s" clicked', [(Sender as TComponent).Name, AItem.Caption]);
end;

end.
