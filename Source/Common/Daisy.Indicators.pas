unit Daisy.Indicators;

{
  Shared types and layout of the DaisyUI "indicator": a small item (badge, status dot
  or button) placed on a corner of the content it wraps.
}

interface

uses
  System.Types, Daisy.Theme;

type
  TDaisyIndicatorHorz = (ihStart, ihCenter, ihEnd);
  TDaisyIndicatorVert = (ivTop, ivMiddle, ivBottom);
  // ikBadge: text (or an empty dot), ikStatus: a status dot, ikButton: a small button
  TDaisyIndicatorKind = (ikBadge, ikStatus, ikButton);

// Edge length of the status dot per size
function DaisyIndicatorStatusSize(ASize: TDaisySize): Integer;

// Splits AClient into the content box and the item. The item is centred on the
// corner (or edge middle) of the content box, so half of it sticks out; the client
// is therefore inset by half the item where the item sticks out.
procedure DaisyIndicatorLayout(const AClient: TRectF; AItemW, AItemH: Single;
  AHorz: TDaisyIndicatorHorz; AVert: TDaisyIndicatorVert; out AContent, AItem: TRectF);

implementation

function DaisyIndicatorStatusSize(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (4, 6, 8, 12, 16);
begin
  Result := C[ASize];
end;

procedure DaisyIndicatorLayout(const AClient: TRectF; AItemW, AItemH: Single;
  AHorz: TDaisyIndicatorHorz; AVert: TDaisyIndicatorVert; out AContent, AItem: TRectF);
var
  LInsetX, LInsetY, LCX, LCY: Single;
begin
  LInsetX := 0;
  LInsetY := 0;
  if AHorz <> ihCenter then
    LInsetX := AItemW / 2;
  if AVert <> ivMiddle then
    LInsetY := AItemH / 2;
  AContent := RectF(AClient.Left + LInsetX, AClient.Top + LInsetY, AClient.Right - LInsetX,
    AClient.Bottom - LInsetY);

  case AHorz of
    ihStart: LCX := AContent.Left;
    ihCenter: LCX := (AContent.Left + AContent.Right) / 2;
  else
    LCX := AContent.Right;
  end;
  case AVert of
    ivTop: LCY := AContent.Top;
    ivMiddle: LCY := (AContent.Top + AContent.Bottom) / 2;
  else
    LCY := AContent.Bottom;
  end;
  AItem := RectF(LCX - AItemW / 2, LCY - AItemH / 2, LCX + AItemW / 2, LCY + AItemH / 2);
end;

end.
