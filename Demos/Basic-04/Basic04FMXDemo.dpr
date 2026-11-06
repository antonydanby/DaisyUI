program Basic04FMXDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.Items in '..\..\Source\Common\Daisy.Items.pas',
  Daisy.Animation in '..\..\Source\Common\Daisy.Animation.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Daisy.Widgets in '..\..\Source\Common\Daisy.Widgets.pas',
  Daisy.FMX.Control in '..\..\Source\FMX\Daisy.FMX.Control.pas',
  Daisy.FMX.Button in '..\..\Source\FMX\Daisy.FMX.Button.pas',
  Daisy.FMX.Chat in '..\..\Source\FMX\Daisy.FMX.Chat.pas',
  Daisy.FMX.Countdown in '..\..\Source\FMX\Daisy.FMX.Countdown.pas',
  Daisy.FMX.List in '..\..\Source\FMX\Daisy.FMX.List.pas',
  Daisy.FMX.Stat in '..\..\Source\FMX\Daisy.FMX.Stat.pas',
  Daisy.FMX.Select in '..\..\Source\FMX\Daisy.FMX.Select.pas',
  Daisy.FMX.Progress in '..\..\Source\FMX\Daisy.FMX.Progress.pas',
  Daisy.FMX.RadialProgress in '..\..\Source\FMX\Daisy.FMX.RadialProgress.pas',
  Daisy.FMX.CheckBox in '..\..\Source\FMX\Daisy.FMX.CheckBox.pas',
  Daisy.FMX.PageControl in '..\..\Source\FMX\Daisy.FMX.PageControl.pas',
  MainFMX in 'MainFMX.pas' {Form17};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm17, Form17);
  Application.Run;
end.
