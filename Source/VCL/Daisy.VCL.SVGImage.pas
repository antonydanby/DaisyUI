unit Daisy.VCL.SVGImage;

{
  TDaisySVGImage - like TImage, but the picture is SVG markup (paste it into
  the SVG property or load an .svg file). Drawn with GDI+, so no extra DLL is
  needed. The icon takes the colour given by Variant.
}

interface

uses
  Winapi.Windows, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.SVG, Daisy.VCL.Control;

type
  TDaisySVGImage = class(TDaisyControl)
  strict private
    FSVG: TStrings;
    FIconPath: string;
    FLayers: TDaisySVGLayers;
    FColored: Boolean;
    procedure SetSVG(const Value: TStrings);
    procedure SetColored(const Value: Boolean);
    procedure SVGChanged(Sender: TObject);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // Paste SVG markup or load an .svg file
    property SVG: TStrings read FSVG write SetSVG;
    // True keeps the colours written in the SVG; False (default) paints it in one colour from Variant
    property Colored: Boolean read FColored write SetColored default False;
  end;

implementation

{ TDaisySVGImage }

constructor TDaisySVGImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSVG := TStringList.Create;
  TStringList(FSVG).OnChange := SVGChanged;
  SetBounds(Left, Top, 48, 48);
end;

destructor TDaisySVGImage.Destroy;
begin
  FSVG.Free;
  inherited Destroy;
end;

procedure TDaisySVGImage.SetSVG(const Value: TStrings);
begin
  FSVG.Assign(Value);
end;

procedure TDaisySVGImage.SetColored(const Value: Boolean);
begin
  if FColored <> Value then
  begin
    FColored := Value;
    Invalidate;
  end;
end;

procedure TDaisySVGImage.SVGChanged(Sender: TObject);
begin
  FIconPath := TDaisySVG.IconPath(FSVG.Text);
  FLayers := TDaisySVG.Layers(FSVG.Text);
  Invalidate;
end;

function TDaisySVGImage.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisySVGImage.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisySVGImage.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  if not Enabled then
    Result.Text := DaisyWithAlpha(Theme.BaseContent, 0.3)
  else if Variant = dvDefault then
    Result.Text := Theme.BaseContent
  else
    Result.Text := DaisyVariantPalette(Theme, Variant).Fill;
end;

procedure TDaisySVGImage.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LSide: Integer;
  LBox: TRectF;
begin
  if (FIconPath = '') and (Length(FLayers) = 0) then
    Exit;
  LSide := Min(ARect.Width, ARect.Height);
  if LSide <= 0 then
    Exit;
  LBox := RectF(ARect.Left + (ARect.Width - LSide) / 2, ARect.Top + (ARect.Height - LSide) / 2,
    ARect.Left + (ARect.Width - LSide) / 2 + LSide, ARect.Top + (ARect.Height - LSide) / 2 + LSide);
  if FColored then
    DrawSVGLayers(FLayers, LBox, AColors.Text)
  else
    DrawIconPath(FIconPath, LBox, AColors.Text);
end;

end.
