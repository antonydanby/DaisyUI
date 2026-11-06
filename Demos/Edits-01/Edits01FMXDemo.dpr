program Edits01FMXDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.Tables in '..\..\Source\Common\Daisy.Tables.pas',
  Daisy.TextEdit in '..\..\Source\Common\Daisy.TextEdit.pas',
  Daisy.Menus in '..\..\Source\Common\Daisy.Menus.pas',
  Daisy.FMX.Control in '..\..\Source\FMX\Daisy.FMX.Control.pas',
  Daisy.FMX.FormStyler in '..\..\Source\FMX\Daisy.FMX.FormStyler.pas',
  Daisy.FMX.Panel in '..\..\Source\FMX\Daisy.FMX.Panel.pas',
  Daisy.FMX.Labels in '..\..\Source\FMX\Daisy.FMX.Labels.pas',
  Daisy.FMX.Select in '..\..\Source\FMX\Daisy.FMX.Select.pas',
  Daisy.FMX.Toggle in '..\..\Source\FMX\Daisy.FMX.Toggle.pas',
  Daisy.FMX.TextInput in '..\..\Source\FMX\Daisy.FMX.TextInput.pas',
  Daisy.FMX.TextArea in '..\..\Source\FMX\Daisy.FMX.TextArea.pas',
  Daisy.FMX.MenuPopup in '..\..\Source\FMX\Daisy.FMX.MenuPopup.pas',
  Daisy.FMX.Menu in '..\..\Source\FMX\Daisy.FMX.Menu.pas',
  Daisy.FMX.MainMenu in '..\..\Source\FMX\Daisy.FMX.MainMenu.pas',
  Daisy.FMX.PopupMenu in '..\..\Source\FMX\Daisy.FMX.PopupMenu.pas',
  Daisy.FMX.CheckBox in '..\..\Source\FMX\Daisy.FMX.CheckBox.pas',
  Daisy.FMX.PageControl in '..\..\Source\FMX\Daisy.FMX.PageControl.pas',
  Daisy.FMX.Button in '..\..\Source\FMX\Daisy.FMX.Button.pas',
  Daisy.Calendars in '..\..\Source\Common\Daisy.Calendars.pas',
  Daisy.FMX.Calendar in '..\..\Source\FMX\Daisy.FMX.Calendar.pas',
  MainFMX in 'MainFMX.pas' {FormEdits};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormEdits, FormEdits);
  Application.Run;
end.
