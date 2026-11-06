unit Daisy.Range;

{
  Shared maths of the DaisyUI "range" slider: value snapping, the thumb metrics per
  size and the conversion between a value and a position on the track.
}

interface

uses
  System.Types, System.Math, Daisy.Theme;

type
  TDaisyRangeOrientation = (roHorizontal, roVertical);

// Clamps AValue to AMin..AMax and snaps it to AStep (a step of 0 or less means continuous)
function DaisyRangeSnap(AValue, AMin, AMax, AStep: Double): Double;

// Diameter of the thumb for a size
function DaisyRangeThumb(ASize: TDaisySize): Integer;
// Thickness of the track for a size
function DaisyRangeTrack(ASize: TDaisySize): Integer;

// 0..1 position of AValue between AMin and AMax
function DaisyRangeFraction(AValue, AMin, AMax: Double): Double;

implementation

function DaisyRangeSnap(AValue, AMin, AMax, AStep: Double): Double;
begin
  if AMax < AMin then
    Exit(AMin);
  Result := AValue;
  if AStep > 0 then
    Result := AMin + Round((Result - AMin) / AStep) * AStep;
  Result := EnsureRange(Result, AMin, AMax);
  Result := RoundTo(Result, -6); // removes floating point drift from stepping
end;

function DaisyRangeThumb(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
begin
  Result := C[ASize];
end;

function DaisyRangeTrack(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (4, 6, 8, 10, 12);
begin
  Result := C[ASize];
end;

function DaisyRangeFraction(AValue, AMin, AMax: Double): Double;
begin
  if AMax <= AMin then
    Exit(0);
  Result := EnsureRange((AValue - AMin) / (AMax - AMin), 0, 1);
end;

end.
