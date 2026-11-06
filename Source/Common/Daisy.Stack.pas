unit Daisy.Stack;

{
  Shared layout of the DaisyUI "stack": the children sit on top of each other and the
  layers behind the front one peek out on the chosen side, each smaller than the one
  in front.
}

interface

uses
  System.Types, System.Math;

type
  // The side the layers behind the front one peek out on
  TDaisyStackDirection = (sdBottom, sdTop, sdStart, sdEnd);

const
  CDaisyStackMaxLayers = 2;

// Rank 0 is the front layer. Layers beyond the second hide behind it.
function DaisyStackLayerRect(ADirection: TDaisyStackDirection; ARank, ACount: Integer;
  const AArea: TRectF; AOffset: Single): TRectF;

// Smooth 0..1 easing and a rectangle blend, used to animate a layer change
function DaisyStackEase(ATime: Double): Double;
function DaisyStackLerpRect(const AFrom, ATo: TRectF; AAmount: Double): TRectF;

implementation

function DaisyStackEase(ATime: Double): Double;
begin
  ATime := EnsureRange(ATime, 0, 1);
  if ATime < 0.5 then
    Result := 4 * ATime * ATime * ATime
  else
    Result := 1 - Power(-2 * ATime + 2, 3) / 2;
end;

function DaisyStackLerpRect(const AFrom, ATo: TRectF; AAmount: Double): TRectF;
begin
  Result.Left := AFrom.Left + (ATo.Left - AFrom.Left) * AAmount;
  Result.Top := AFrom.Top + (ATo.Top - AFrom.Top) * AAmount;
  Result.Right := AFrom.Right + (ATo.Right - AFrom.Right) * AAmount;
  Result.Bottom := AFrom.Bottom + (ATo.Bottom - AFrom.Bottom) * AAmount;
end;

function DaisyStackLayerRect(ADirection: TDaisyStackDirection; ARank, ACount: Integer;
  const AArea: TRectF; AOffset: Single): TRectF;
var
  LFront: TRectF;
  LReserved, LScale, LW, LH, LShift: Single;
  LLayer: Integer;
begin
  LLayer := Min(ARank, CDaisyStackMaxLayers);
  LReserved := Min(Max(ACount - 1, 0), CDaisyStackMaxLayers) * AOffset;
  LFront := AArea;
  case ADirection of
    sdBottom: LFront.Bottom := LFront.Bottom - LReserved;
    sdTop: LFront.Top := LFront.Top + LReserved;
    sdStart: LFront.Left := LFront.Left + LReserved;
    sdEnd: LFront.Right := LFront.Right - LReserved;
  end;
  LScale := 1 - 0.1 * LLayer;
  LW := LFront.Width * LScale;
  LH := LFront.Height * LScale;
  LShift := LLayer * AOffset;
  case ADirection of
    sdBottom, sdTop:
      begin
        Result.Left := LFront.Left + (LFront.Width - LW) / 2;
        Result.Right := Result.Left + LW;
        if ADirection = sdBottom then
        begin
          Result.Bottom := LFront.Bottom + LShift;
          Result.Top := Result.Bottom - LH;
        end
        else
        begin
          Result.Top := LFront.Top - LShift;
          Result.Bottom := Result.Top + LH;
        end;
      end;
  else
    Result.Top := LFront.Top + (LFront.Height - LH) / 2;
    Result.Bottom := Result.Top + LH;
    if ADirection = sdStart then
    begin
      Result.Left := LFront.Left - LShift;
      Result.Right := Result.Left + LW;
    end
    else
    begin
      Result.Right := LFront.Right + LShift;
      Result.Left := Result.Right - LW;
    end;
  end;
end;

end.
