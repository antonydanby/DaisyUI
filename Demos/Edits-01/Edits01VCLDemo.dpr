program Edits01VCLDemo;

uses
  Vcl.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.Tables in '..\..\Source\Common\Daisy.Tables.pas',
  Daisy.TextEdit in '..\..\Source\Common\Daisy.TextEdit.pas',
  Daisy.Menus in '..\..\Source\Common\Daisy.Menus.pas',
  Daisy.VCL.Control in '..\..\Source\VCL\Daisy.VCL.Control.pas',
  Daisy.VCL.FormStyler in '..\..\Source\VCL\Daisy.VCL.FormStyler.pas',
  Daisy.VCL.Panel in '..\..\Source\VCL\Daisy.VCL.Panel.pas',
  Daisy.VCL.Labels in '..\..\Source\VCL\Daisy.VCL.Labels.pas',
  Daisy.VCL.Select in '..\..\Source\VCL\Daisy.VCL.Select.pas',
  Daisy.VCL.Toggle in '..\..\Source\VCL\Daisy.VCL.Toggle.pas',
  Daisy.VCL.TextInput in '..\..\Source\VCL\Daisy.VCL.TextInput.pas',
  Daisy.VCL.TextArea in '..\..\Source\VCL\Daisy.VCL.TextArea.pas',
  Daisy.VCL.MenuPopup in '..\..\Source\VCL\Daisy.VCL.MenuPopup.pas',
  Daisy.VCL.Menu in '..\..\Source\VCL\Daisy.VCL.Menu.pas',
  Daisy.VCL.MainMenu in '..\..\Source\VCL\Daisy.VCL.MainMenu.pas',
  Daisy.VCL.PopupMenu in '..\..\Source\VCL\Daisy.VCL.PopupMenu.pas',
  Daisy.VCL.CheckBox in '..\..\Source\VCL\Daisy.VCL.CheckBox.pas',
  Daisy.VCL.PageControl in '..\..\Source\VCL\Daisy.VCL.PageControl.pas',
  Daisy.VCL.Button in '..\..\Source\VCL\Daisy.VCL.Button.pas',
  Daisy.Calendars in '..\..\Source\Common\Daisy.Calendars.pas',
  Daisy.VCL.Calendar in '..\..\Source\VCL\Daisy.VCL.Calendar.pas',
  MainVCL in 'MainVCL.pas' {FormEdits};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormEdits, FormEdits);
  Application.Run;
end.
