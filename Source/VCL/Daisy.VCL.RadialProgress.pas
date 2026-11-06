unit Daisy.VCL.RadialProgress;

{
  TDaisyRadialProgress - the DaisyUI "radial progress": a ring showing a value with
  the value written in the middle. Filled adds a coloured disc behind the ring.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.VCL.Control;

type
  TDaisyRadialProgress = class(TDaisyControl)
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
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

{ TDaisyRadialProgress }

constructor TDaisyRadialProgress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin := 0;
  FMax := 100;
  FShowValue := True;
  SetBounds(Left, Top, 80, 80);
end;

procedure TDaisyRadialProgress.SetMin(const AValue: Double);
begin
  if FMin <> AValue then
  begin
    FMin := AValue;
    Invalidate;
  end;
end;

procedure TDaisyRadialProgress.SetMax(const AValue: Double);
begin
  if FMax <> AValue then
  begin
    FMax := AValue;
    Invalidate;
  end;
end;

procedure TDaisyRadialProgress.SetValue(const AValue: Double);
begin
  if FValue <> AValue then
  begin
    FValue := AValue;
    Invalidate;
  end;
end;

procedure TDaisyRadialProgress.SetThickness(const AValue: Integer);
begin
  if FThickness <> AValue then
  begin
    FThickness := AValue;
    Invalidate;
  end;
end;

procedure TDaisyRadialProgress.SetShowValue(const AValue: Boolean);
begin
  if FShowValue <> AValue then
  begin
    FShowValue := AValue;
    Invalidate;
  end;
end;

procedure TDaisyRadialProgress.SetDisplayText(const AValue: string);
begin
  if FDisplayText <> AValue then
  begin
    FDisplayText := AValue;
    Invalidate;
  end;
end;

procedure TDaisyRadialProgress.SetFilled(const AValue: Boolean);
begin
  if FFilled <> AValue then
  begin
    FFilled := AValue;
    Invalidate;
  end;
end;

function TDaisyRadialProgress.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyRadialProgress.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyRadialProgress.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyRadialProgress.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

procedure TDaisyRadialProgress.SizeChanged;
begin
  Invalidate;
end;

function TDaisyRadialProgress.RingFraction: Double;
begin
  if FMax > FMin then
    Result := EnsureRange((FValue - FMin) / (FMax - FMin), 0, 1)
  else
    Result := 0;
end;

function TDaisyRadialProgress.ArcColor: TAlphaColor;
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

procedure TDaisyRadialProgress.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LPen: TGPPen;
  LBrush: TGPSolidBrush;
  LSide, LThick: Single;
  LLeft, LTop: Single;
  LFrac: Double;
  LText: string;
  LBox: TRect;
  LDiscColor, LTrackColor, LTextColor: TAlphaColor;
  LPalette: TDaisyPalette;
begin
  LSide := System.Math.Min(Width, Height);
  if LSide < 4 then
    Exit;
  if FThickness > 0 then
    LThick := ScaleValue(FThickness)
  else
    LThick := LSide / 10;
  LLeft := (Width - LSide) / 2;
  LTop := (Height - LSide) / 2;
  LFrac := RingFraction;

  LTextColor := ArcColor;
  LDiscColor := 0;
  LTrackColor := DaisyWithAlpha(LTextColor, 0.2);
  if FFilled then
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    if Variant = dvDefault then
      LDiscColor := Theme.Base300
    else
      LDiscColor := LPalette.Fill;
    LTrackColor := DaisyWithAlpha(LTextColor, 0.25);
  end;

  LGraphics := NewGraphics;
  try
    if FFilled then
    begin
      LBrush := TGPSolidBrush.Create(LDiscColor);
      try
        LGraphics.FillEllipse(LBrush, LLeft, LTop, LSide, LSide);
      finally
        LBrush.Free;
      end;
    end;
    LPen := TGPPen.Create(LTrackColor, LThick);
    try
      LGraphics.DrawEllipse(LPen, LLeft + LThick / 2, LTop + LThick / 2, LSide - LThick, LSide - LThick);
    finally
      LPen.Free;
    end;
    if LFrac > 0 then
    begin
      LPen := TGPPen.Create(ArcColor, LThick);
      try
        LPen.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
        if LFrac >= 1 then
          LGraphics.DrawEllipse(LPen, LLeft + LThick / 2, LTop + LThick / 2, LSide - LThick, LSide - LThick)
        else
          LGraphics.DrawArc(LPen, LLeft + LThick / 2, LTop + LThick / 2, LSide - LThick, LSide - LThick,
            -90, LFrac * 360);
      finally
        LPen.Free;
      end;
    end;
  finally
    LGraphics.Free;
  end;

  if FDisplayText <> '' then
    LText := FDisplayText
  else if FShowValue then
    LText := IntToStr(Round(LFrac * 100)) + '%'
  else
    LText := '';
  if LText <> '' then
  begin
    LBox := Rect(Round(LLeft), Round(LTop), Round(LLeft + LSide), Round(LTop + LSide));
    DrawText(LText, LBox, LTextColor, System.Math.Max(8, Round(LSide / 8)), False,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
end;

end.
