unit Daisy.Swap;

{
  Shared logic of the DaisyUI "swap" and "theme controller" controls: the swap effects,
  the icon data they use and the transform that rotates / flips an icon.
}

interface

uses
  System.SysUtils, System.Types, System.Math, Daisy.Theme;

type
  // How the two visuals of a swap are exchanged. Rotate and Flip move icons; text and
  // emoji just fade.
  TDaisySwapEffect = (seFade, seRotate, seFlip, seNone);

const
  // 24 x 24 stroke icons, ready to paste into an icon property
  CDaisyIconSun = 'M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0 -8z M12 2v2 M12 20v2 M4.93 4.93l1.41 1.41 ' +
    'M17.66 17.66l1.41 1.41 M2 12h2 M20 12h2 M6.34 17.66l-1.41 1.41 M19.07 4.93l-1.41 1.41';
  CDaisyIconMoon = 'M12 3a6 6 0 0 0 9 9a9 9 0 1 1 -9 -9z';
  CDaisyIconVolumeOn = 'M3 9h4l5 -4v14l-5 -4h-4z M15.5 8.5a5 5 0 0 1 0 7 M18.5 5.5a9 9 0 0 1 0 13';
  CDaisyIconVolumeOff = 'M3 9h4l5 -4v14l-5 -4h-4z M16 9l5 6 M21 9l-5 6';

// How one visual of a swap is shown at AProgress (0 = the off visual, 1 = the on visual)
procedure DaisySwapLayer(AEffect: TDaisySwapEffect; AProgress: Single; AOn: Boolean;
  out AAlpha, ARotation, AScaleX: Single);

// Rotates (degrees) and squeezes horizontally the 24 x 24 icon geometry about its centre
function DaisyTransformIcon(const APaths: TDaisyIconPaths; ARotation, AScaleX: Single): TDaisyIconPaths;

implementation

procedure DaisySwapLayer(AEffect: TDaisySwapEffect; AProgress: Single; AOn: Boolean;
  out AAlpha, ARotation, AScaleX: Single);
var
  LP: Single;
begin
  if AOn then
    LP := AProgress
  else
    LP := 1 - AProgress;
  AAlpha := LP;
  ARotation := 0;
  AScaleX := 1;
  case AEffect of
    seNone:
      if LP >= 0.5 then
        AAlpha := 1
      else
        AAlpha := 0;
    seRotate:
      begin
        if AOn then
          ARotation := -45 * (1 - LP)
        else
          ARotation := 45 * (1 - LP);
      end;
    seFlip:
      begin
        // the first half turns the old visual edge-on, the second half opens the new one
        if LP > 0.5 then
        begin
          AAlpha := 1;
          AScaleX := Sin((LP - 0.5) * Pi);
        end
        else
        begin
          AAlpha := 0;
          AScaleX := 0;
        end;
      end;
  end;
end;

function DaisyTransformIcon(const APaths: TDaisyIconPaths; ARotation, AScaleX: Single): TDaisyIconPaths;
var
  LSin, LCos, LX, LY: Single;
  I, J: Integer;
begin
  Result := APaths;
  if (ARotation = 0) and (AScaleX = 1) then
    Exit;
  SinCos(DegToRad(ARotation), LSin, LCos);
  SetLength(Result, Length(APaths));
  for I := 0 to High(APaths) do
  begin
    SetLength(Result[I], Length(APaths[I]));
    for J := 0 to High(APaths[I]) do
    begin
      LX := (APaths[I][J].X - 12) * AScaleX;
      LY := APaths[I][J].Y - 12;
      Result[I][J] := PointF(12 + LX * LCos - LY * LSin, 12 + LX * LSin + LY * LCos);
    end;
  end;
end;

end.
