program Basic02VCLDemo;

uses
  Vcl.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.VCL.Control in '..\..\Source\VCL\Daisy.VCL.Control.pas',
  Daisy.VCL.Button in '..\..\Source\VCL\Daisy.VCL.Button.pas',
  Daisy.VCL.IconButton in '..\..\Source\VCL\Daisy.VCL.IconButton.pas',
  Daisy.VCL.LoadingButton in '..\..\Source\VCL\Daisy.VCL.LoadingButton.pas',
  Daisy.VCL.Dropdown in '..\..\Source\VCL\Daisy.VCL.Dropdown.pas',
  Daisy.VCL.Fab in '..\..\Source\VCL\Daisy.VCL.Fab.pas',
  MainVCL in 'MainVCL.pas' {Form12},
  Daisy.VCL.Accordion in '..\..\Source\VCL\Daisy.VCL.Accordion.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.VCL.Select in '..\..\Source\VCL\Daisy.VCL.Select.pas',
  Daisy.Toasts in '..\..\Source\Common\Daisy.Toasts.pas',
  Daisy.VCL.Toast in '..\..\Source\VCL\Daisy.VCL.Toast.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm12, Form12);
  Application.Run;
end.
