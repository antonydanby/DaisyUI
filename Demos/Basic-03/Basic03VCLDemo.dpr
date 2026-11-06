program Basic03VCLDemo;

uses
  Vcl.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.VCL.Control in '..\..\Source\VCL\Daisy.VCL.Control.pas',
  Daisy.VCL.Button in '..\..\Source\VCL\Daisy.VCL.Button.pas',
  Daisy.VCL.Badge in '..\..\Source\VCL\Daisy.VCL.Badge.pas',
  Daisy.VCL.IconButton in '..\..\Source\VCL\Daisy.VCL.IconButton.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.VCL.Select in '..\..\Source\VCL\Daisy.VCL.Select.pas',
  Daisy.VCL.PageControl in '..\..\Source\VCL\Daisy.VCL.PageControl.pas',
  Daisy.VCL.CheckBox in '..\..\Source\VCL\Daisy.VCL.CheckBox.pas',
  MainVCL in 'MainVCL.pas' {Form14};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm14, Form14);
  Application.Run;
end.
