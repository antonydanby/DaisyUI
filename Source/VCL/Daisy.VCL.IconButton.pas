unit Daisy.VCL.IconButton;

{
  TDaisySquareButton / TDaisyCircleButton - fixed aspect icon buttons.
  The glyph (normally an emoji) comes from Caption and is drawn through
  Direct2D so colour emoji fonts work. When IconPath is set, that SVG icon is
  drawn instead of the Caption glyph.
}

interface

uses
  System.Classes, System.Types, Daisy.Theme, Daisy.VCL.Control, Daisy.VCL.Button;

type
  TDaisyIconButton = class(TDaisyButton)
  protected
    procedure SizeChanged; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TDaisySquareButton = class(TDaisyIconButton)
  protected
    function DefaultCornerRadius: Integer; override;
  end;

  TDaisyCircleButton = class(TDaisyIconButton)
  protected
    function DefaultCornerRadius: Integer; override;
  end;

implementation

{ TDaisyIconButton }

constructor TDaisyIconButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetBounds(Left, Top, ScaleValue(DaisyFieldHeight(dzMD)), ScaleValue(DaisyFieldHeight(dzMD)));
  Caption := #$2605;
end;

procedure TDaisyIconButton.SizeChanged;
begin
  SetBounds(Left, Top, ScaleValue(DaisyFieldHeight(SizeKind)), ScaleValue(DaisyFieldHeight(SizeKind)));
end;

procedure TDaisyIconButton.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LBody: TRect;
  LSize, LLeft, LTop: Integer;
begin
  if IconPath <> '' then
  begin
    LSize := ScaleValue(DaisyFontSize(SizeKind) * 3 div 2);
    LBody := BodyRect;
    LLeft := LBody.Left + ((LBody.Right - LBody.Left) - LSize) div 2;
    LTop := LBody.Top + ((LBody.Bottom - LBody.Top) - LSize) div 2;
    DrawIconPath(IconPath, RectF(LLeft, LTop, LLeft + LSize, LTop + LSize), AColors.Text);
    Exit;
  end;
  DrawEmoji(Caption, BodyRect, AColors.Text, DaisyFontSize(SizeKind) * 3 div 2);
end;

{ TDaisySquareButton }

function TDaisySquareButton.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

{ TDaisyCircleButton }

function TDaisyCircleButton.DefaultCornerRadius: Integer;
begin
  Result := 999; // clamped to half the shortest side when drawn
end;

end.
