unit Daisy.VCL.FieldSet;

{
  TDaisyFieldSet - the DaisyUI "fieldset": a themed group with a legend on top and a
  description underneath. Drop the labelled inputs in the area between the two.
  Style: solid = tinted background and border, outline = border only, soft = background
  only, dash = dashed border, ghost = plain (no background, no border).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.UITypes,
  System.Math, Vcl.Controls, Daisy.Theme, Daisy.VCL.Control;

type
  TDaisyFieldSet = class(TDaisyControl)
  strict private
    FLegend: string;
    FDescription: string;
    procedure SetLegend(const Value: string);
    procedure SetDescription(const Value: string);
    function LegendHeight: Integer;
    function DescriptionHeight: Integer;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

{ TDaisyFieldSet }

constructor TDaisyFieldSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FLegend := 'Fieldset';
  SetBounds(Left, Top, 320, 200);
end;

function TDaisyFieldSet.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFieldSet.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFieldSet.DefaultContentPadding: Integer;
begin
  Result := 16;
end;

function TDaisyFieldSet.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
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

procedure TDaisyFieldSet.SetLegend(const Value: string);
begin
  if FLegend <> Value then
  begin
    FLegend := Value;
    Invalidate;
  end;
end;

procedure TDaisyFieldSet.SetDescription(const Value: string);
begin
  if FDescription <> Value then
  begin
    FDescription := Value;
    Invalidate;
  end;
end;

function TDaisyFieldSet.LegendHeight: Integer;
begin
  if FLegend = '' then
    Result := 0
  else
    Result := MeasureTextHeight(FLegend, Max(1, Width), CLegendFont, True);
end;

function TDaisyFieldSet.DescriptionHeight: Integer;
begin
  if FDescription = '' then
    Result := 0
  else
    Result := MeasureTextHeight(FDescription, Max(1, ContentRect.Width), CDescriptionFont, False);
end;

procedure TDaisyFieldSet.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LArea, LRect: TRect;
begin
  LArea := ContentRect;
  if FLegend <> '' then
  begin
    LRect := LArea;
    LRect.Bottom := LRect.Top + LegendHeight;
    DrawText(FLegend, LRect, AColors.Text, CLegendFont, True,
      DT_LEFT or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);
  end;
  if FDescription <> '' then
  begin
    LRect := LArea;
    LRect.Top := LRect.Bottom - DescriptionHeight;
    DrawText(FDescription, LRect, DaisyWithAlpha(AColors.Text, 0.6), CDescriptionFont, False,
      DT_LEFT or DT_BOTTOM or DT_WORDBREAK);
  end;
end;

end.
