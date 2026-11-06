program PeakSVGDemo;

uses
  Vcl.Forms,
  Daisy.Theme in '..\..\Source\Common\Daisy.Theme.pas',
  Daisy.SVG in '..\..\Source\Common\Daisy.SVG.pas',
  Peak.SVG in '..\..\Source\Peak\Peak.SVG.pas',
  Peak.SVG.Base in '..\..\Source\Peak\Peak.SVG.Base.pas',
  Peak.SVGImage in '..\..\Source\Peak\Peak.SVGImage.pas',
  Peak.SVG.Conversion in '..\..\Source\Peak\Peak.SVG.Conversion.pas',
  Peak.SVG.Lists in '..\..\Source\Peak\Peak.SVG.Lists.pas',
  MainPeak in 'MainPeak.pas' {FormPeak};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormPeak, FormPeak);
  Application.Run;
end.
