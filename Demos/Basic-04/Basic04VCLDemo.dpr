program Basic04VCLDemo;

uses
  Vcl.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.VCL.Control in '..\..\Source\VCL\Daisy.VCL.Control.pas',
  Daisy.VCL.Button in '..\..\Source\VCL\Daisy.VCL.Button.pas',
  Daisy.VCL.Chat in '..\..\Source\VCL\Daisy.VCL.Chat.pas',
  Daisy.VCL.Countdown in '..\..\Source\VCL\Daisy.VCL.Countdown.pas',
  Daisy.VCL.List in '..\..\Source\VCL\Daisy.VCL.List.pas',
  Daisy.VCL.Stat in '..\..\Source\VCL\Daisy.VCL.Stat.pas',
  Daisy.VCL.Select in '..\..\Source\VCL\Daisy.VCL.Select.pas',
  Daisy.VCL.Progress in '..\..\Source\VCL\Daisy.VCL.Progress.pas',
  Daisy.VCL.RadialProgress in '..\..\Source\VCL\Daisy.VCL.RadialProgress.pas',
  MainVCL in 'MainVCL.pas' {Form16};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm16, Form16);
  Application.Run;
end.
