unit MainFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types,
  FMX.Controls, FMX.ActnList, System.Actions, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, Daisy.Theme, Daisy.Widgets, Daisy.Menus, Daisy.TextEdit,
  Daisy.FMX.Control, Daisy.FMX.FormStyler, Daisy.FMX.Panel, Daisy.FMX.Labels, Daisy.FMX.Select,
  Daisy.FMX.Toggle, Daisy.FMX.TextInput, Daisy.FMX.TextArea, Daisy.FMX.MenuPopup, Daisy.FMX.Menu,
  Daisy.FMX.MainMenu, Daisy.FMX.PopupMenu, Daisy.FMX.CheckBox, Daisy.FMX.PageControl,
  Daisy.FMX.Button, Daisy.Calendars, Daisy.FMX.Calendar, Daisy.FMX.DatePicker,
  Daisy.FMX.ThemeController;

type
  TFormEdits = class(TForm)
    Styler: TDaisyFmxFormStyler;
    ppMenu: TDaisyFmxPopupMenu;
    mmMain: TDaisyFmxMainMenu;
    lyTop: TLayout;
    lblTheme: TLabel;
    lblStatusLine: TLabel;
    chkTitleBar: TDaisyFmxCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actPrimaryToggle: TAction;
    actSuccessToggle: TAction;
    actNew: TAction;
    actAutoSave: TAction;
    selTheme: TDaisyFmxSelect;
    themeCtl: TDaisyFmxThemeController;
    pcMain: TDaisyFmxPageControl;
    tsToggle: TDaisyFmxTabSheet;
    tsInput: TDaisyFmxTabSheet;
    tsArea: TDaisyFmxTabSheet;
    tsSelect: TDaisyFmxTabSheet;
    tsMenu: TDaisyFmxTabSheet;
    tsMenuMore: TDaisyFmxTabSheet;
    tgBasic: TDaisyFmxToggle;
    tgChecked: TDaisyFmxToggle;
    tgDisabled: TDaisyFmxToggle;
    tgDisabledOn: TDaisyFmxToggle;
    tgIcons: TDaisyFmxToggle;
    tgXs: TDaisyFmxToggle;
    tgSm: TDaisyFmxToggle;
    tgMd: TDaisyFmxToggle;
    tgLg: TDaisyFmxToggle;
    tgXl: TDaisyFmxToggle;
    tgNeutral: TDaisyFmxToggle;
    tgPrimary: TDaisyFmxToggle;
    tgSecondary: TDaisyFmxToggle;
    tgAccent: TDaisyFmxToggle;
    tgInfo: TDaisyFmxToggle;
    tgSuccess: TDaisyFmxToggle;
    tgWarning: TDaisyFmxToggle;
    tgError: TDaisyFmxToggle;
    tiBasic: TDaisyFmxTextInput;
    tiGhost: TDaisyFmxTextInput;
    tiPrimary: TDaisyFmxTextInput;
    tiDisabled: TDaisyFmxTextInput;
    tiSearch: TDaisyFmxTextInput;
    tiEmoji: TDaisyFmxTextInput;
    tiPassword: TDaisyFmxTextInput;
    tiEndEmoji: TDaisyFmxTextInput;
    tiXs: TDaisyFmxTextInput;
    tiSm: TDaisyFmxTextInput;
    tiMd: TDaisyFmxTextInput;
    tiLg: TDaisyFmxTextInput;
    tiXl: TDaisyFmxTextInput;
    tiLegend: TDaisyFmxTextInput;
    tiFloating: TDaisyFmxTextInput;
    tiBefore: TDaisyFmxTextInput;
    tiAfter: TDaisyFmxTextInput;
    tiSuccess: TDaisyFmxTextInput;
    tiWarning: TDaisyFmxTextInput;
    tiError: TDaisyFmxTextInput;
    tiSoft: TDaisyFmxTextInput;
    taBasic: TDaisyFmxTextArea;
    taLong: TDaisyFmxTextArea;
    taGhost: TDaisyFmxTextArea;
    selMany: TDaisyFmxSelect;
    selScroll: TDaisyFmxSelect;
    mnVertical: TDaisyFmxMenu;
    mnIconsOnly: TDaisyFmxMenu;
    mnHorizontal: TDaisyFmxMenu;
    mnSm: TDaisyFmxMenu;
    mnLg: TDaisyFmxMenu;
    mnBadge: TDaisyFmxMenu;
    mnCollapsible: TDaisyFmxMenu;
    pnlRightClick: TDaisyFmxPanel;
    lblRightClick: TDaisyFmxLabel;
    tsCalendar: TDaisyFmxTabSheet;
    lblCalSingle: TDaisyFmxLabel;
    calSingle: TDaisyFmxCalendar;
    lblCalRange: TDaisyFmxLabel;
    calRange: TDaisyFmxCalendar;
    lblCalOptions: TDaisyFmxLabel;
    calOptions: TDaisyFmxCalendar;
    lblFirstDay: TDaisyFmxLabel;
    selFirstDay: TDaisyFmxSelect;
    chkOutsideDays: TDaisyFmxCheckBox;
    btnCalToday: TDaisyFmxButton;
    lblCalPicker: TDaisyFmxLabel;
    dpCalendar: TDaisyFmxDatePicker;
    lblPlacement: TDaisyFmxLabel;
    selPlacement: TDaisyFmxSelect;
    procedure CalendarChange(Sender: TObject);
    procedure DatePickerChange(Sender: TObject);
    procedure DatePlacementChange(Sender: TObject);
    procedure CalendarOptionChange(Sender: TObject);
    procedure CalendarTodayClick(Sender: TObject);
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ToggleActionExecute(Sender: TObject);
    procedure MenuActionExecute(Sender: TObject);
    procedure MenuItemClick(Sender: TObject; AItem: TDaisyMenuItem);
  end;

var
  FormEdits: TFormEdits;

implementation

{$R *.fmx}

procedure TFormEdits.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TFormEdits.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TFormEdits.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TFormEdits.chkTitleBarChange(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TFormEdits.CalendarChange(Sender: TObject);
var
  LCalendar: TDaisyFmxCalendar;
begin
  LCalendar := Sender as TDaisyFmxCalendar;
  if LCalendar.SelectionMode = csRange then
    lblStatusLine.Text := Format('%s: %s to %s', [LCalendar.Name,
      DateToStr(LCalendar.RangeStart), DateToStr(LCalendar.RangeEnd)])
  else
    lblStatusLine.Text := Format('%s: %s', [LCalendar.Name, DateToStr(LCalendar.SelectedDate)]);
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
    lblStatusLine.Text := 'dpCalendar: no date'
  else
    lblStatusLine.Text := 'dpCalendar: ' + DateToStr(dpCalendar.Date);
end;

procedure TFormEdits.DatePlacementChange(Sender: TObject);
begin
  dpCalendar.PopupPlacement := TDaisyPopupPlacement(selPlacement.ItemIndex);
end;

procedure TFormEdits.ToggleActionExecute(Sender: TObject);
begin
  lblStatusLine.Text := Format('%s: %s', [(Sender as TAction).Name,
    BoolToStr((Sender as TAction).Checked, True)]);
end;

procedure TFormEdits.MenuActionExecute(Sender: TObject);
begin
  lblStatusLine.Text := Format('Action %s executed', [(Sender as TAction).Name]);
end;

procedure TFormEdits.MenuItemClick(Sender: TObject; AItem: TDaisyMenuItem);
begin
  lblStatusLine.Text := Format('%s: "%s" clicked', [(Sender as TComponent).Name, AItem.Caption]);
end;

end.
