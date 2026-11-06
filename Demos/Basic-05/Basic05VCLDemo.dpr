program Basic05VCLDemo;

uses
  Vcl.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.Tables in '..\..\Source\Common\Daisy.Tables.pas',
  Daisy.VCL.Control in '..\..\Source\VCL\Daisy.VCL.Control.pas',
  Daisy.VCL.Panel in '..\..\Source\VCL\Daisy.VCL.Panel.pas',
  Daisy.VCL.Labels in '..\..\Source\VCL\Daisy.VCL.Labels.pas',
  Daisy.VCL.SVGImage in '..\..\Source\VCL\Daisy.VCL.SVGImage.pas',
  Daisy.VCL.Status in '..\..\Source\VCL\Daisy.VCL.Status.pas',
  Daisy.VCL.Select in '..\..\Source\VCL\Daisy.VCL.Select.pas',
  Daisy.VCL.Table in '..\..\Source\VCL\Daisy.VCL.Table.pas',
  Daisy.VCL.PageControl in '..\..\Source\VCL\Daisy.VCL.PageControl.pas',
  Daisy.VCL.CheckBox in '..\..\Source\VCL\Daisy.VCL.CheckBox.pas',
  MainVCL in 'MainVCL.pas' {Form18};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm18, Form18);
  Application.Run;
end.
