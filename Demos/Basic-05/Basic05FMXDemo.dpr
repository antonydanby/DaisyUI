program Basic05FMXDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.Tables in '..\..\Source\Common\Daisy.Tables.pas',
  Daisy.FMX.Control in '..\..\Source\FMX\Daisy.FMX.Control.pas',
  Daisy.FMX.Panel in '..\..\Source\FMX\Daisy.FMX.Panel.pas',
  Daisy.FMX.Labels in '..\..\Source\FMX\Daisy.FMX.Labels.pas',
  Daisy.FMX.SVGImage in '..\..\Source\FMX\Daisy.FMX.SVGImage.pas',
  Daisy.FMX.Status in '..\..\Source\FMX\Daisy.FMX.Status.pas',
  Daisy.FMX.Select in '..\..\Source\FMX\Daisy.FMX.Select.pas',
  Daisy.FMX.Table in '..\..\Source\FMX\Daisy.FMX.Table.pas',
  Daisy.FMX.CheckBox in '..\..\Source\FMX\Daisy.FMX.CheckBox.pas',
  Daisy.FMX.PageControl in '..\..\Source\FMX\Daisy.FMX.PageControl.pas',
  MainFMX in 'MainFMX.pas' {Form19};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm19, Form19);
  Application.Run;
end.
