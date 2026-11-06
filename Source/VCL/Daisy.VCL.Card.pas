unit Daisy.VCL.Card;

interface

uses
  Winapi.Windows, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.VCL.Control, Daisy.VCL.Panel;

type
  TDaisyCard = class(TDaisyPanel)
  strict private
    FTitle: string;
    FBody: string;
    procedure SetTitle(const Value: string);
    procedure SetBody(const Value: string);
  protected
    function DefaultShadowSize: Integer; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  published
    property Title: string read FTitle write SetTitle;
    property Body: string read FBody write SetBody;
  end;

implementation

const
  CTitleGap = 8;

{ TDaisyCard }

procedure TDaisyCard.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Invalidate;
  end;
end;

procedure TDaisyCard.SetBody(const Value: string);
begin
  if FBody <> Value then
  begin
    FBody := Value;
    Invalidate;
  end;
end;

function TDaisyCard.DefaultShadowSize: Integer;
begin
  Result := 2;
end;

procedure TDaisyCard.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LTop: Integer;
  LTitleSize: Integer;
  LRect: TRect;
begin
  LTop := ARect.Top;
  LTitleSize := DaisyCardTitleSize(SizeKind);

  if FTitle <> '' then
  begin
    LRect := Rect(ARect.Left, LTop, ARect.Right, ARect.Bottom);
    DrawText(FTitle, LRect, AColors.Text, LTitleSize, True,
      DT_LEFT or DT_TOP or DT_WORDBREAK);
    Inc(LTop, MeasureTextHeight(FTitle, ARect.Width, LTitleSize, True) + ScaleValue(CTitleGap));
  end;

  if (FBody <> '') and (LTop < ARect.Bottom) then
  begin
    LRect := Rect(ARect.Left, LTop, ARect.Right, ARect.Bottom);
    DrawText(FBody, LRect, AColors.Text, DaisyFontSize(SizeKind), False,
      DT_LEFT or DT_TOP or DT_WORDBREAK or DT_END_ELLIPSIS);
  end;
end;

end.
