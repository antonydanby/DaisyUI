unit Daisy.Rating;

{
  Shared maths of the DaisyUI "rating": shape outlines (star, plump star, heart),
  the per-star colours of a multi-colour rating and hit testing.
}

interface

uses
  System.Types, System.UITypes, System.Math;

type
  TDaisyRatingShape = (rsStar, rsStar2, rsHeart);

// Outline of AShape fitted into ABox (a closed polygon)
function DaisyShapePoints(AShape: TDaisyRatingShape; const ABox: TRectF): TArray<TPointF>;

// Colour of star AIndex of ACount in a multi-colour rating (red .. green)
function DaisyRatingRainbow(AIndex, ACount: Integer): TAlphaColor;

// Value selected by a click at APos (0 = start of the first item). A click in the first
// half of an item gives a half value when AHalf is set.
function DaisyRatingValueAt(APos, AItem, AGap: Single; ACount: Integer; AHalf: Boolean): Double;

implementation

function Fit(const APoints: TArray<TPointF>; const ABox: TRectF): TArray<TPointF>;
var
  I: Integer;
  LMinX, LMinY, LMaxX, LMaxY, LScale, LW, LH: Single;
begin
  LMinX := APoints[0].X;
  LMaxX := LMinX;
  LMinY := APoints[0].Y;
  LMaxY := LMinY;
  for I := 1 to High(APoints) do
  begin
    LMinX := Min(LMinX, APoints[I].X);
    LMaxX := Max(LMaxX, APoints[I].X);
    LMinY := Min(LMinY, APoints[I].Y);
    LMaxY := Max(LMaxY, APoints[I].Y);
  end;
  LW := Max(LMaxX - LMinX, 0.0001);
  LH := Max(LMaxY - LMinY, 0.0001);
  LScale := Min(ABox.Width / LW, ABox.Height / LH);
  SetLength(Result, Length(APoints));
  for I := 0 to High(APoints) do
  begin
    Result[I].X := ABox.Left + (ABox.Width - LW * LScale) / 2 + (APoints[I].X - LMinX) * LScale;
    Result[I].Y := ABox.Top + (ABox.Height - LH * LScale) / 2 + (APoints[I].Y - LMinY) * LScale;
  end;
end;

// Corner cutting: each pass replaces every corner by two points a quarter along its edges
function Smooth(const APoints: TArray<TPointF>; APasses: Integer): TArray<TPointF>;
var
  I, N, LPass: Integer;
  LNext: TArray<TPointF>;
begin
  Result := APoints;
  for LPass := 1 to APasses do
  begin
    N := Length(Result);
    SetLength(LNext, N * 2);
    for I := 0 to N - 1 do
    begin
      LNext[I * 2] := PointF(0.75 * Result[I].X + 0.25 * Result[(I + 1) mod N].X,
        0.75 * Result[I].Y + 0.25 * Result[(I + 1) mod N].Y);
      LNext[I * 2 + 1] := PointF(0.25 * Result[I].X + 0.75 * Result[(I + 1) mod N].X,
        0.25 * Result[I].Y + 0.75 * Result[(I + 1) mod N].Y);
    end;
    Result := LNext;
  end;
end;

function StarPoints(AInner: Single): TArray<TPointF>;
var
  I: Integer;
  LAngle, LRadius: Single;
begin
  SetLength(Result, 10);
  for I := 0 to 9 do
  begin
    LAngle := -Pi / 2 + I * Pi / 5;
    if Odd(I) then
      LRadius := AInner
    else
      LRadius := 1;
    Result[I] := PointF(LRadius * Cos(LAngle), LRadius * Sin(LAngle));
  end;
end;

function HeartPoints: TArray<TPointF>;
const
  CSteps = 72;
var
  I: Integer;
  T: Single;
begin
  SetLength(Result, CSteps);
  for I := 0 to CSteps - 1 do
  begin
    T := 2 * Pi * I / CSteps;
    Result[I] := PointF(16 * Power(Sin(T), 3),
      -(13 * Cos(T) - 5 * Cos(2 * T) - 2 * Cos(3 * T) - Cos(4 * T)));
  end;
end;

function DaisyShapePoints(AShape: TDaisyRatingShape; const ABox: TRectF): TArray<TPointF>;
begin
  case AShape of
    rsStar: Result := Fit(StarPoints(0.4), ABox);
    rsStar2: Result := Fit(Smooth(StarPoints(0.55), 2), ABox);
  else
    Result := Fit(HeartPoints, ABox);
  end;
end;

function DaisyRatingRainbow(AIndex, ACount: Integer): TAlphaColor;
const
  CStops: array[0..4] of TAlphaColor = ($FFF87171, $FFFB923C, $FFFACC15, $FFA3E635, $FF4ADE80);
var
  LPos, LFrac: Single;
  LLow: Integer;
  LA, LB: TAlphaColorRec;
  LRec: TAlphaColorRec;
begin
  if ACount <= 1 then
    LPos := 0
  else
    LPos := EnsureRange(AIndex / (ACount - 1), 0, 1) * High(CStops);
  LLow := Min(Trunc(LPos), High(CStops) - 1);
  LFrac := LPos - LLow;
  LA := TAlphaColorRec(CStops[LLow]);
  LB := TAlphaColorRec(CStops[LLow + 1]);
  LRec.A := 255;
  LRec.R := Round(LA.R + (LB.R - LA.R) * LFrac);
  LRec.G := Round(LA.G + (LB.G - LA.G) * LFrac);
  LRec.B := Round(LA.B + (LB.B - LA.B) * LFrac);
  Result := TAlphaColor(LRec);
end;

function DaisyRatingValueAt(APos, AItem, AGap: Single; ACount: Integer; AHalf: Boolean): Double;
var
  LIndex: Integer;
  LInside: Single;
begin
  if (APos < 0) or (AItem <= 0) then
    Exit(0);
  LIndex := Trunc(APos / (AItem + AGap));
  if LIndex >= ACount then
    Exit(ACount);
  LInside := APos - LIndex * (AItem + AGap);
  if AHalf and (LInside < AItem / 2) then
    Result := LIndex + 0.5
  else
    Result := LIndex + 1;
end;

end.
