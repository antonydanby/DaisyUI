program Basic02FMXDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.FMX.Control in '..\..\Source\FMX\Daisy.FMX.Control.pas',
  Daisy.FMX.Button in '..\..\Source\FMX\Daisy.FMX.Button.pas',
  Daisy.FMX.IconButton in '..\..\Source\FMX\Daisy.FMX.IconButton.pas',
  Daisy.FMX.LoadingButton in '..\..\Source\FMX\Daisy.FMX.LoadingButton.pas',
  Daisy.FMX.Dropdown in '..\..\Source\FMX\Daisy.FMX.Dropdown.pas',
  Daisy.FMX.Fab in '..\..\Source\FMX\Daisy.FMX.Fab.pas',
  MainFMX in 'MainFMX.pas' {Form13},
  Daisy.FMX.Accordion in '..\..\Source\FMX\Daisy.FMX.Accordion.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.FMX.Select in '..\..\Source\FMX\Daisy.FMX.Select.pas',
  Daisy.Toasts in '..\..\Source\Common\Daisy.Toasts.pas',
  Daisy.FMX.Toast in '..\..\Source\FMX\Daisy.FMX.Toast.pas',
  Daisy.FMX.PageControl in '..\..\Source\FMX\Daisy.FMX.PageControl.pas',
  Daisy.FMX.CheckBox in '..\..\Source\FMX\Daisy.FMX.CheckBox.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm13, Form13);
  Application.Run;
end.
