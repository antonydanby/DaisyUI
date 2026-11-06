unit Daisy.VCL.Alert;

interface

uses
  Winapi.Windows, Winapi.GDIPOBJ, System.Classes, System.Types, System.UITypes, System.Math,
  Daisy.Theme, Daisy.VCL.Control;

type
  TDaisyAlert = class(TDaisyControl)
  strict private
    FIconKind: TDaisyIconKind;
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure SetIconKind(const Value: TDaisyIconKind);
  protected
    function DefaultContentPadding: Integer; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption: string read GetCaption write SetCaption;
    property IconKind: TDaisyIconKind read FIconKind write SetIconKind default diAuto;
  end;

implementation

const
  CIconSize = 24;
  CIconGap = 12;

{ TDaisyAlert }

constructor TDaisyAlert.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIconKind := diAuto;
  SetBounds(Left, Top, 360, ScaleValue(48));
  Caption := 'Alert message';
end;

function TDaisyAlert.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyAlert.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyAlert.SetIconKind(const Value: TDaisyIconKind);
begin
  if FIconKind <> Value then
  begin
    FIconKind := Value;
    Invalidate;
  end;
end;

function TDaisyAlert.DefaultContentPadding: Integer;
begin
  Result := 16;
end;

procedure TDaisyAlert.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LBody, LText: TRect;
  LPaddingX, LPaddingY, LIconSize, LTextHeight: Integer;
  LIcon: TDaisyIconKind;
  LGraphics: TGPGraphics;
  LBounds: TRectF;
begin
  LBody := BodyRect;
  LPaddingX := ResolvedContentPadding;
  LPaddingY := (LPaddingX * 3) div 4;
  LText := LBody;
  InflateRect(LText, -LPaddingX, -LPaddingY);

  LIcon := DaisyResolveIcon(IconKind, Variant);
  if LIcon <> diNone then
  begin
    LIconSize := ScaleValue(CIconSize);
    LBounds := RectF(LText.Left, LBody.Top + (LBody.Height - LIconSize) / 2,
      LText.Left + LIconSize, LBody.Top + (LBody.Height - LIconSize) / 2 + LIconSize);
    LGraphics := NewGraphics;
    try
      DrawPolylines(LGraphics, DaisyIconPaths(LIcon), LBounds, AColors.Text, 2);
    finally
      LGraphics.Free;
    end;
    Inc(LText.Left, LIconSize + ScaleValue(CIconGap));
  end;

  LTextHeight := MeasureTextHeight(Caption, LText.Width, DaisyFontSize(SizeKind), False);
  if LTextHeight < LText.Height then
  begin
    LText.Top := LBody.Top + (LBody.Height - LTextHeight) div 2;
    LText.Bottom := LText.Top + LTextHeight;
  end;
  DrawText(Caption, LText, AColors.Text, DaisyFontSize(SizeKind), False,
    DT_LEFT or DT_TOP or DT_WORDBREAK or DT_END_ELLIPSIS);
end;

end.
