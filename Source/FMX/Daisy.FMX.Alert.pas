unit Daisy.FMX.Alert;

interface

uses
  System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, Daisy.Theme, Daisy.FMX.Control;

type
  TDaisyFmxAlert = class(TDaisyControl)
  strict private
    FText: string;
    FIconKind: TDaisyIconKind;
    procedure SetText(const Value: string);
    procedure SetIconKind(const Value: TDaisyIconKind);
  protected
    function DefaultContentPadding: Integer; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Text: string read FText write SetText;
    property IconKind: TDaisyIconKind read FIconKind write SetIconKind default diAuto;
  end;

implementation

const
  CIconSize = 24;
  CIconGap = 12;

{ TDaisyFmxAlert }

constructor TDaisyFmxAlert.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIconKind := diAuto;
  FText := 'Alert message';
  SetBounds(Position.X, Position.Y, 360, 48);
end;

procedure TDaisyFmxAlert.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxAlert.SetIconKind(const Value: TDaisyIconKind);
begin
  if FIconKind <> Value then
  begin
    FIconKind := Value;
    Repaint;
  end;
end;

function TDaisyFmxAlert.DefaultContentPadding: Integer;
begin
  Result := 16;
end;

procedure TDaisyFmxAlert.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LBody, LText: TRectF;
  LPaddingX, LPaddingY, LIconTop, LTextHeight: Single;
  LIcon: TDaisyIconKind;
begin
  LBody := BodyRect;
  LPaddingX := ResolvedContentPadding;
  LPaddingY := LPaddingX * 3 / 4;
  LText := LBody;
  LText.Inflate(-LPaddingX, -LPaddingY);

  LIcon := DaisyResolveIcon(IconKind, Variant);
  if LIcon <> diNone then
  begin
    LIconTop := LBody.Top + (LBody.Height - CIconSize) / 2;
    DrawPolylines(DaisyIconPaths(LIcon),
      RectF(LText.Left, LIconTop, LText.Left + CIconSize, LIconTop + CIconSize),
      AColors.Text, 2);
    LText.Left := LText.Left + CIconSize + CIconGap;
  end;

  LTextHeight := MeasureTextHeight(FText, LText.Width, DaisyFontSize(SizeKind), False);
  if LTextHeight < LText.Height then
  begin
    LText.Top := LBody.Top + (LBody.Height - LTextHeight) / 2;
    LText.Bottom := LText.Top + LTextHeight;
  end;
  DrawText(FText, LText, AColors.Text, DaisyFontSize(SizeKind), False,
    TTextAlign.Leading, TTextAlign.Leading, True);
end;

end.
