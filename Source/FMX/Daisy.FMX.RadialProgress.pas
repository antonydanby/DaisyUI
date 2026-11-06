unit Daisy.FMX.RadialProgress;

{
  TDaisyFmxRadialProgress - the DaisyUI "radial progress": a ring showing a value with
  the value written in the middle. Filled adds a coloured disc behind the ring.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.FMX.Control;

type
  TDaisyFmxRadialProgress = class(TDaisyControl)
  strict private
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FThickness: Integer;
    FShowValue: Boolean;
    FDisplayText: string;
    FFilled: Boolean;
    procedure SetMin(const AValue: Double);
    procedure SetMax(const AValue: Double);
    procedure SetValue(const AValue: Double);
    procedure SetThickness(const AValue: Integer);
    procedure SetShowValue(const AValue: Boolean);
    procedure SetDisplayText(const AValue: string);
    procedure SetFilled(const AValue: Boolean);
    function ArcColor: TAlphaColor;
    function RingFraction: Double;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Min: Double read FMin write SetMin;
    property Max: Double read FMax write SetMax;
    property Value: Double read FValue write SetValue;
    // Ring thickness in pixels; 0 = a tenth of the size
    property Thickness: Integer read FThickness write SetThickness default 0;
    property ShowValue: Boolean read FShowValue write SetShowValue default True;
    // Replaces the percentage written in the middle
    property DisplayText: string read FDisplayText write SetDisplayText;
    // A coloured disc is drawn behind the ring
    property Filled: Boolean read FFilled write SetFilled default False;
  end;

implementation

{ TDaisyFmxRadialProgress }

constructor TDaisyFmxRadialProgress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin := 0;
  FMax := 100;
  FShowValue := True;
  HitTest := False;
  SetBounds(Position.X, Position.Y, 80, 80);
end;

procedure TDaisyFmxRadialProgress.SetMin(const AValue: Double);
begin
  if FMin <> AValue then
  begin
    FMin := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRadialProgress.SetMax(const AValue: Double);
begin
  if FMax <> AValue then
  begin
    FMax := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRadialProgress.SetValue(const AValue: Double);
begin
  if FValue <> AValue then
  begin
    FValue := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRadialProgress.SetThickness(const AValue: Integer);
begin
  if FThickness <> AValue then
  begin
    FThickness := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRadialProgress.SetShowValue(const AValue: Boolean);
begin
  if FShowValue <> AValue then
  begin
    FShowValue := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRadialProgress.SetDisplayText(const AValue: string);
begin
  if FDisplayText <> AValue then
  begin
    FDisplayText := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRadialProgress.SetFilled(const AValue: Boolean);
begin
  if FFilled <> AValue then
  begin
    FFilled := AValue;
    Repaint;
  end;
end;

function TDaisyFmxRadialProgress.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRadialProgress.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRadialProgress.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRadialProgress.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

procedure TDaisyFmxRadialProgress.SizeChanged;
begin
  Repaint;
end;

function TDaisyFmxRadialProgress.RingFraction: Double;
begin
  if FMax > FMin then
    Result := EnsureRange((FValue - FMin) / (FMax - FMin), 0, 1)
  else
    Result := 0;
end;

function TDaisyFmxRadialProgress.ArcColor: TAlphaColor;
var
  LPalette: TDaisyPalette;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    if FFilled then
      Result := LPalette.Content
    else
      Result := LPalette.Fill;
  end;
  if not Enabled then
    Result := DaisyWithAlpha(Result, 0.4);
end;

procedure TDaisyFmxRadialProgress.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LSide, LThick: Single;
  LRing, LBox: TRectF;
  LFrac: Double;
  LText: string;
  LTextColor, LDiscColor, LTrackColor: TAlphaColor;
  LPalette: TDaisyPalette;
  LData: TPathData;
begin
  LSide := System.Math.Min(Width, Height);
  if LSide < 4 then
    Exit;
  if FThickness > 0 then
    LThick := FThickness
  else
    LThick := LSide / 10;
  LBox := RectF((Width - LSide) / 2, (Height - LSide) / 2, (Width + LSide) / 2, (Height + LSide) / 2);
  LRing := LBox;
  LRing.Inflate(-LThick / 2, -LThick / 2);
  LFrac := RingFraction;

  LTextColor := ArcColor;
  LTrackColor := DaisyWithAlpha(LTextColor, 0.2);
  if FFilled then
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    if Variant = dvDefault then
      LDiscColor := Theme.Base300
    else
      LDiscColor := LPalette.Fill;
    LTrackColor := DaisyWithAlpha(LTextColor, 0.25);
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := LDiscColor;
    Canvas.FillEllipse(LBox, AbsoluteOpacity);
  end;

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Thickness := LThick;
  Canvas.Stroke.Dash := TStrokeDash.Solid;
  Canvas.Stroke.Cap := TStrokeCap.Round;
  Canvas.Stroke.Color := LTrackColor;
  Canvas.DrawEllipse(LRing, AbsoluteOpacity);
  if LFrac > 0 then
  begin
    Canvas.Stroke.Color := LTextColor;
    if LFrac >= 1 then
      Canvas.DrawEllipse(LRing, AbsoluteOpacity)
    else
    begin
      LData := TPathData.Create;
      try
        LData.AddArc(LRing.CenterPoint, PointF(LRing.Width / 2, LRing.Height / 2), -90, LFrac * 360);
        Canvas.DrawPath(LData, AbsoluteOpacity);
      finally
        LData.Free;
      end;
    end;
  end;

  if FDisplayText <> '' then
    LText := FDisplayText
  else if FShowValue then
    LText := IntToStr(Round(LFrac * 100)) + '%'
  else
    LText := '';
  if LText <> '' then
    DrawText(LText, LBox, LTextColor, System.Math.Max(8, Round(LSide / 8)), False,
      TTextAlign.Center, TTextAlign.Center, False);
end;

end.
