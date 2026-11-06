unit Daisy.FMX.Reg;

interface

procedure Register;

implementation

{$R Daisy.FMX.Reg.dcr}
{$R Daisy.FMX.Reg2.dcr}

uses
  System.Classes, Daisy.FMX.Control, Daisy.FMX.Button, Daisy.FMX.Card, Daisy.FMX.Alert,
  Daisy.FMX.Progress, Daisy.FMX.RadialProgress, Daisy.FMX.Toast, Daisy.FMX.Calendar, Daisy.FMX.DatePicker,
  Daisy.FMX.IconButton, Daisy.FMX.LoadingButton, Daisy.FMX.Dropdown, Daisy.FMX.Fab,
  Daisy.FMX.Accordion, Daisy.FMX.Badge,
  Daisy.FMX.Chat, Daisy.FMX.Countdown, Daisy.FMX.List, Daisy.FMX.Stat,
  Daisy.FMX.Panel, Daisy.FMX.Labels, Daisy.FMX.SVGImage, Daisy.FMX.Status,
  Daisy.FMX.Table, Daisy.FMX.Select, Daisy.FMX.FormStyler, Daisy.FMX.Toggle,
  Daisy.FMX.TextInput, Daisy.FMX.TextArea, Daisy.FMX.Menu, Daisy.FMX.MainMenu,
  Daisy.FMX.PopupMenu, Daisy.FMX.CheckBox, Daisy.FMX.PageControl,
  Daisy.FMX.Indicator, Daisy.FMX.FieldSet, Daisy.FMX.Range, Daisy.FMX.Rating,
  Daisy.FMX.Swap, Daisy.FMX.Stack, Daisy.FMX.ThemeController;

procedure Register;
begin
  RegisterComponents('Daisy FMX', [TDaisyFmxButton, TDaisyFmxCard, TDaisyFmxAlert,
    TDaisyFmxSquareButton, TDaisyFmxCircleButton, TDaisyFmxLoadingButton, TDaisyFmxAnimationButton,
    TDaisyFmxDropdownMenu, TDaisyFmxFloatingActionButton, TDaisyFmxAccordion,
    TDaisyFmxBadge, TDaisyFmxBadgeButton,
    TDaisyFmxChatBubble, TDaisyFmxCountdown, TDaisyFmxList, TDaisyFmxStat,
    TDaisyFmxPanel, TDaisyFmxLabel, TDaisyFmxSVGImage, TDaisyFmxStatus, TDaisyFmxTable,
    TDaisyFmxSelect,
    TDaisyFmxFormStyler, TDaisyFmxToggle, TDaisyFmxTextInput, TDaisyFmxTextArea,
    TDaisyFmxMenu, TDaisyFmxMainMenu, TDaisyFmxPopupMenu, TDaisyFmxCheckBox,
    TDaisyFmxPageControl, TDaisyFmxTabSheet, TDaisyFmxProgress, TDaisyFmxRadialProgress,
    TDaisyFmxToast, TDaisyFmxCalendar, TDaisyFmxDatePicker, TDaisyFmxIndicator,
    TDaisyFmxFieldSet, TDaisyFmxRange, TDaisyFmxRating,
    TDaisyFmxSwap, TDaisyFmxThemeController, TDaisyFmxStack]);
end;

end.
