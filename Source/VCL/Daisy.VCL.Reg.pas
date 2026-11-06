unit Daisy.VCL.Reg;

interface

procedure Register;

implementation

{$R Daisy.VCL.Reg.dcr}
{$R Daisy.VCL.Reg2.dcr}

uses
  System.Classes, Daisy.VCL.Control, Daisy.VCL.Button, Daisy.VCL.Card, Daisy.VCL.Alert,
  Daisy.VCL.Progress, Daisy.VCL.RadialProgress, Daisy.VCL.Toast, Daisy.VCL.Calendar, Daisy.VCL.DatePicker,
  Daisy.VCL.IconButton, Daisy.VCL.LoadingButton, Daisy.VCL.Dropdown, Daisy.VCL.Fab,
  Daisy.VCL.Accordion, Daisy.VCL.Badge,
  Daisy.VCL.Chat, Daisy.VCL.Countdown, Daisy.VCL.List, Daisy.VCL.Stat,
  Daisy.VCL.Panel, Daisy.VCL.Labels, Daisy.VCL.SVGImage, Daisy.VCL.Status,
  Daisy.VCL.Table, Daisy.VCL.Select, Daisy.VCL.FormStyler, Daisy.VCL.Toggle,
  Daisy.VCL.TextInput, Daisy.VCL.TextArea, Daisy.VCL.Menu, Daisy.VCL.MainMenu,
  Daisy.VCL.PopupMenu, Daisy.VCL.CheckBox, Daisy.VCL.PageControl,
  Daisy.VCL.Indicator, Daisy.VCL.FieldSet, Daisy.VCL.Range, Daisy.VCL.Rating,
  Daisy.VCL.Swap, Daisy.VCL.Stack, Daisy.VCL.ThemeController;

procedure Register;
begin
  RegisterComponents('Daisy VCL', [TDaisyButton, TDaisyCard, TDaisyAlert,
    TDaisySquareButton, TDaisyCircleButton, TDaisyLoadingButton, TDaisyAnimationButton,
    TDaisyDropdownMenu, TDaisyFloatingActionButton, TDaisyAccordion,
    TDaisyBadge, TDaisyBadgeButton,
    TDaisyChatBubble, TDaisyCountdown, TDaisyList, TDaisyStat,
    TDaisyPanel, TDaisyLabel, TDaisySVGImage, TDaisyStatus, TDaisyTable, TDaisySelect,
    TDaisyFormStyler, TDaisyToggle, TDaisyTextInput, TDaisyTextArea,
    TDaisyMenu, TDaisyMainMenu, TDaisyPopupMenu, TDaisyCheckBox,
    TDaisyPageControl, TDaisyTabSheet, TDaisyProgress, TDaisyRadialProgress, TDaisyToast,
    TDaisyCalendar, TDaisyDatePicker, TDaisyIndicator, TDaisyFieldSet, TDaisyRange,
    TDaisyRating, TDaisySwap, TDaisyThemeController, TDaisyStack]);
end;

end.
