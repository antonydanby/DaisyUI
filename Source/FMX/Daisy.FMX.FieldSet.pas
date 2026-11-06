unit Daisy.FMX.FieldSet;

{
  TDaisyFmxFieldSet - the DaisyUI "fieldset": a themed group with a legend on top and a
  description underneath. Drop the labelled inputs in the area between the two.
  Style: solid = tinted background and border, outline = border only, soft = background
  only, dash = dashed border, ghost = plain (no background, no border).
}

interface

uses
  System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.FMX.Control;

type
  TDaisyFmxFieldSet = class(TDaisyControl)
  strict private
    FLegend: string;
    FDescription: string;
    procedure SetLegend(const AValue: string);
    procedure SetDescription(const AValue: string);
    function LegendHeight: Single;
    function DescriptionHeight: Single;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Legend: string read FLegend write SetLegend;
    property Description: string read FDescription write SetDescription;
  end;

implementation

const
  CLegendFont = 14;
  CDescriptionFont = 12;

{ TDaisyFmxFieldSet }

constructor TDaisyFmxFieldSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLegend := 'Fieldset';
  SetBounds(Position.X, Position.Y, 320, 200);
end;

function TDaisyFmxFieldSet.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxFieldSet.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxFieldSet.DefaultContentPadding: Integer;
begin
  Result := 16;
end;

function TDaisyFmxFieldSet.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
var
  LTheme: TDaisyTheme;
  LTint: TAlphaColor;
begin
  LTheme := Theme;
  Result := Default(TDaisyColors);
  Result.Text := LTheme.BaseContent;
  if not Enabled then
    Result.Text := DaisyWithAlpha(LTheme.BaseContent, 0.4);

  if Variant = dvDefault then
  begin
    Result.Background := LTheme.Base200;
    Result.Border := LTheme.Base300;
  end
  else
  begin
    LTint := DaisyVariantPalette(LTheme, Variant).Fill;
    Result.Background := DaisyMix(LTheme.Base100, LTint, 0.1);
    Result.Border := DaisyMix(LTheme.Base100, LTint, 0.5);
  end;

  case Style of
    dsOutline: Result.Background := TAlphaColors.Null;
    dsSoft: Result.Border := TAlphaColors.Null;
    dsDash:
      begin
        Result.Background := TAlphaColors.Null;
        Result.Dashed := True;
      end;
    dsGhost:
      begin
        Result.Background := TAlphaColors.Null;
        Result.Border := TAlphaColors.Null;
      end;
  end;
end;

procedure TDaisyFmxFieldSet.SetLegend(const AValue: string);
begin
  if FLegend <> AValue then
  begin
    FLegend := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxFieldSet.SetDescription(const AValue: string);
begin
  if FDescription <> AValue then
  begin
    FDescription := AValue;
    Repaint;
  end;
end;

function TDaisyFmxFieldSet.LegendHeight: Single;
begin
  if FLegend = '' then
    Result := 0
  else
    Result := MeasureTextHeight(FLegend, System.Math.Max(1, Width), CLegendFont, True);
end;

function TDaisyFmxFieldSet.DescriptionHeight: Single;
begin
  if FDescription = '' then
    Result := 0
  else
    Result := MeasureTextHeight(FDescription, System.Math.Max(1, ContentRect.Width),
      CDescriptionFont, False);
end;

procedure TDaisyFmxFieldSet.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LArea, LRect: TRectF;
begin
  LArea := ContentRect;
  if FLegend <> '' then
  begin
    LRect := LArea;
    LRect.Bottom := LRect.Top + LegendHeight;
    DrawText(FLegend, LRect, AColors.Text, CLegendFont, True, TTextAlign.Leading,
      TTextAlign.Leading, False);
  end;
  if FDescription <> '' then
  begin
    LRect := LArea;
    LRect.Top := LRect.Bottom - DescriptionHeight;
    DrawText(FDescription, LRect, DaisyWithAlpha(AColors.Text, 0.6), CDescriptionFont, False,
      TTextAlign.Leading, TTextAlign.Trailing, True);
  end;
end;

end.
