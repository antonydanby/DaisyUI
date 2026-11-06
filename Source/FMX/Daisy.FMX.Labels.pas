unit Daisy.FMX.Labels;

{
  TDaisyFmxLabel - a themed text label. Unlike TLabel it follows the Daisy theme
  (Variant gives the colour). Colour emoji are drawn with the platform emoji font.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.FMX.Control;

type
  TDaisyFmxLabel = class(TDaisyControl)
  strict private
    FText: string;
    FAlignment: TDaisyTextAlign;
    FVerticalAlignment: TDaisyTextAlign;
    FWordWrap: Boolean;
    FAutoFit: Boolean;
    FBold: Boolean;
    FUpdating: Boolean;
    FMuted: Boolean;
    procedure SetText(const Value: string);
    procedure SetAlignment(const Value: TDaisyTextAlign);
    procedure SetVerticalAlignment(const Value: TDaisyTextAlign);
    procedure SetWordWrap(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure SetBold(const Value: Boolean);
    procedure SetMuted(const Value: Boolean);
    procedure UpdateSize;
    function TextColor: TAlphaColor;
    function ToAlign(AValue: TDaisyTextAlign): TTextAlign;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Text: string read FText write SetText;
    property Alignment: TDaisyTextAlign read FAlignment write SetAlignment default taStart;
    property VerticalAlignment: TDaisyTextAlign read FVerticalAlignment write SetVerticalAlignment default taStart;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
    // The size follows the text; with WordWrap only the height follows
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property Bold: Boolean read FBold write SetBold default False;
    // Draws the text at 60% strength, like secondary text
    property Muted: Boolean read FMuted write SetMuted default False;
  end;

implementation

{ TDaisyFmxLabel }

constructor TDaisyFmxLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  FText := 'Label';
  HitTest := False;
  SetBounds(Position.X, Position.Y, 64, 20);
  UpdateSize;
end;

procedure TDaisyFmxLabel.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxLabel.SetAlignment(const Value: TDaisyTextAlign);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxLabel.SetVerticalAlignment(const Value: TDaisyTextAlign);
begin
  if FVerticalAlignment <> Value then
  begin
    FVerticalAlignment := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxLabel.SetWordWrap(const Value: Boolean);
begin
  if FWordWrap <> Value then
  begin
    FWordWrap := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxLabel.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyFmxLabel.SetBold(const Value: Boolean);
begin
  if FBold <> Value then
  begin
    FBold := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxLabel.SetMuted(const Value: Boolean);
begin
  if FMuted <> Value then
  begin
    FMuted := Value;
    Repaint;
  end;
end;

function TDaisyFmxLabel.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxLabel.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxLabel.TextColor: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
  if FMuted then
    Result := DaisyWithAlpha(Result, 0.6);
  if not Enabled then
    Result := DaisyWithAlpha(Theme.BaseContent, 0.3);
end;

function TDaisyFmxLabel.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := TextColor;
end;

function TDaisyFmxLabel.ToAlign(AValue: TDaisyTextAlign): TTextAlign;
begin
  case AValue of
    taCenter: Result := TTextAlign.Center;
    taEnd: Result := TTextAlign.Trailing;
  else
    Result := TTextAlign.Leading;
  end;
end;

procedure TDaisyFmxLabel.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxLabel.Loaded;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyFmxLabel.Resize;
begin
  inherited;
  if FWordWrap then
    UpdateSize;
end;

procedure TDaisyFmxLabel.UpdateSize;
var
  LFont: Integer;
  LWidth, LHeight: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LFont := DaisyFontSize(SizeKind);
  LWidth := Width;
  if FWordWrap then
    LHeight := MeasureTextHeight(FText, Max(1, Width), LFont, FBold)
  else
  begin
    LWidth := MeasureTextWidth(FText, LFont, FBold) + 2;
    LHeight := Max(MeasureTextHeight('Ag', 1000, LFont, FBold),
      MeasureTextHeight(FText, 100000, LFont, FBold));
  end;
  if SameValue(LWidth, Width) and SameValue(LHeight, Height) then
    Exit;
  FUpdating := True;
  try
    if Align in [TAlignLayout.Top, TAlignLayout.Bottom, TAlignLayout.Client] then
      LWidth := Width;
    SetBounds(Position.X, Position.Y, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxLabel.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LFont: Integer;
begin
  LFont := DaisyFontSize(SizeKind);
  DrawText(FText, ARect, AColors.Text, LFont, FBold, ToAlign(FAlignment),
    ToAlign(FVerticalAlignment), FWordWrap);
end;

end.
