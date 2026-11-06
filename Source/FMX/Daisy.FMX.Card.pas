unit Daisy.FMX.Card;

interface

uses
  System.Classes, System.Types, System.UITypes,
  FMX.Types, FMX.Controls, Daisy.Theme, Daisy.FMX.Control, Daisy.FMX.Panel;

type
  TDaisyFmxCard = class(TDaisyFmxPanel)
  strict private
    FTitle: string;
    FBody: string;
    procedure SetTitle(const Value: string);
    procedure SetBody(const Value: string);
  protected
    function DefaultShadowSize: Integer; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  published
    property Title: string read FTitle write SetTitle;
    property Body: string read FBody write SetBody;
  end;

implementation

const
  CTitleGap = 8;

{ TDaisyFmxCard }

procedure TDaisyFmxCard.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxCard.SetBody(const Value: string);
begin
  if FBody <> Value then
  begin
    FBody := Value;
    Repaint;
  end;
end;

function TDaisyFmxCard.DefaultShadowSize: Integer;
begin
  Result := 2;
end;

procedure TDaisyFmxCard.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LTop, LTitleHeight: Single;
  LTitleSize: Integer;
begin
  LTop := ARect.Top;
  LTitleSize := DaisyCardTitleSize(SizeKind);

  if FTitle <> '' then
  begin
    LTitleHeight := MeasureTextHeight(FTitle, ARect.Width, LTitleSize, True);
    DrawText(FTitle, RectF(ARect.Left, LTop, ARect.Right, LTop + LTitleHeight), AColors.Text,
      LTitleSize, True, TTextAlign.Leading, TTextAlign.Leading, True);
    LTop := LTop + LTitleHeight + CTitleGap;
  end;

  if (FBody <> '') and (LTop < ARect.Bottom) then
    DrawText(FBody, RectF(ARect.Left, LTop, ARect.Right, ARect.Bottom), AColors.Text,
      DaisyFontSize(SizeKind), False, TTextAlign.Leading, TTextAlign.Leading, True);
end;

end.
