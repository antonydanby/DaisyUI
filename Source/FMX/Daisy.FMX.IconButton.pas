unit Daisy.FMX.IconButton;

{
  TDaisyFmxSquareButton / TDaisyFmxCircleButton - fixed aspect icon buttons.
  The glyph (normally an emoji) comes from Text and is drawn with the
  platform colour-emoji font.
}

interface

uses
  System.Classes, System.Types, Daisy.Theme, Daisy.FMX.Control, Daisy.FMX.Button;

type
  TDaisyFmxIconButton = class(TDaisyFmxButton)
  protected
    procedure SizeChanged; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TDaisyFmxSquareButton = class(TDaisyFmxIconButton)
  protected
    function DefaultCornerRadius: Integer; override;
  end;

  TDaisyFmxCircleButton = class(TDaisyFmxIconButton)
  protected
    function DefaultCornerRadius: Integer; override;
  end;

implementation

{ TDaisyFmxIconButton }

constructor TDaisyFmxIconButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetBounds(Position.X, Position.Y, DaisyFieldHeight(dzMD), DaisyFieldHeight(dzMD));
  Text := #$2605;
end;

procedure TDaisyFmxIconButton.SizeChanged;
begin
  SetBounds(Position.X, Position.Y, DaisyFieldHeight(SizeKind), DaisyFieldHeight(SizeKind));
end;

procedure TDaisyFmxIconButton.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LBody: TRectF;
  LSize: Single;
begin
  if IconPath <> '' then
  begin
    LSize := DaisyFontSize(SizeKind) * 3 div 2;
    LBody := BodyRect;
    DrawIconPath(IconPath, RectF(LBody.CenterPoint.X - LSize / 2, LBody.CenterPoint.Y - LSize / 2,
      LBody.CenterPoint.X + LSize / 2, LBody.CenterPoint.Y + LSize / 2), AColors.Text);
    Exit;
  end;
  DrawEmoji(Text, BodyRect, AColors.Text, DaisyFontSize(SizeKind) * 3 div 2);
end;

{ TDaisyFmxSquareButton }

function TDaisyFmxSquareButton.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

{ TDaisyFmxCircleButton }

function TDaisyFmxCircleButton.DefaultCornerRadius: Integer;
begin
  Result := 999; // clamped by the canvas to half the shortest side
end;

end.
