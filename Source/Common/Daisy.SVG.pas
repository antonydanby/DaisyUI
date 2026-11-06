unit Daisy.SVG;

{
  TDaisySVG - turns pasted SVG markup into the icon data the Daisy controls draw.

  No DLLs and no Skia: the markup is scanned for <path>, <circle>, <ellipse>,
  <rect>, <line>, <polyline> and <polygon> elements. Everything is normalised
  into a 24 x 24 box using the viewBox, and flattened to polylines.

  Stroke icons (Tabler, Lucide, Feather, Heroicons outline) are drawn as
  outlines; filled icons (Material, Heroicons solid, Bootstrap) are drawn
  filled. Which one applies is detected from the fill / stroke attributes.
  The result is a plain string, so controls keep it as an internal IconPath.

  Layers() keeps the colours instead: every shape becomes a layer with its own
  fill / stroke colour, opacity and stroke width (fill, stroke, opacity,
  fill-rule, style="..." and <g> inheritance are honoured; currentColor follows
  the control; a gradient is drawn as its first stop colour).

  Not supported: transform attributes, CSS style blocks, real gradients, text.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, Daisy.Theme;

type
  // One drawable shape group in the 24 x 24 box with its own colours
  TDaisySVGLayer = record
    Paths: TDaisyIconPaths;
    HasFill, FillCurrent: Boolean;
    HasStroke, StrokeCurrent: Boolean;
    EvenOdd: Boolean;
    FillColor, StrokeColor: TAlphaColor;
    FillOpacity, StrokeOpacity: Single;
    StrokeWidth: Single; // in the 24 x 24 box
  end;
  TDaisySVGLayers = TArray<TDaisySVGLayer>;

  TDaisySVG = class sealed
  strict private
    type
      TStyle = record
        Fill, Stroke, StrokeWidth, FillOpacity, StrokeOpacity, FillRule: string;
        Opacity: Double;
      end;
    class function Attr(const ATag, AName: string): string; static;
    class function Num(const AText: string; ADefault: Double): Double; static;
    class function Fmt(AValue: Double): string; static;
    class function ShapeToPath(const AName, ATag: string): string; static;
    class function EllipsePath(CX, CY, RX, RY: Double): string; static;
    class function RectPath(const ATag: string): string; static;
    class function PointsPath(const APoints: string; AClose: Boolean): string; static;
    class procedure ReadViewBox(const ATag: string; out AX, AY, AW, AH: Double); static;
    class function Prop(const ATag, AName: string): string; static;
    class procedure ApplyStyle(var AStyle: TStyle; const ATag: string); static;
    class function NextTag(const AText: string; var P: Integer; out ATag: string): Boolean; static;
    class function ParseColor(const AText, AValue: string; out AColor: TAlphaColor;
      out ACurrent: Boolean): Boolean; static;
    class function NamedColor(const AName: string; out AColor: TAlphaColor): Boolean; static;
  public
    // Converts SVG markup to coloured layers (see the unit notes). Bare path
    // data gives one stroked layer in the control colour.
    class function Layers(const ASVG: string): TDaisySVGLayers; static;
    // The colour a layer fill (AFill) or stroke is painted with. ACurrent is
    // the control colour used for currentColor.
    class function LayerColor(const ALayer: TDaisySVGLayer; AFill: Boolean;
      ACurrent: TAlphaColor): TAlphaColor; static;
    // Converts SVG markup to icon data. Plain path data (just the d value) is
    // accepted too and treated as a 24 x 24 stroke icon. Empty or unusable
    // input returns ''.
    class function IconPath(const ASVG: string): string; static;
    // Turns icon data from IconPath back into geometry (24 x 24 box)
    class function ToPaths(const AIconPath: string; out AFilled: Boolean): TDaisyIconPaths; static;
  end;

implementation

uses
  System.Math, System.StrUtils;

const
  CFilledMark = '!';

class function TDaisySVG.Attr(const ATag, AName: string): string;
var
  P, Q: Integer;
  LQuote: Char;
begin
  Result := '';
  P := 1;
  while True do
  begin
    P := PosEx(AName + '=', ATag, P);
    if P = 0 then
      Exit;
    if (P > 1) and CharInSet(ATag[P - 1], [' ', #9, #10, #13]) then
      Break;
    Inc(P); // matched the tail of a longer name such as "id=" for "d="
  end;
  Inc(P, Length(AName) + 1);
  if P > Length(ATag) then
    Exit;
  LQuote := ATag[P];
  if not CharInSet(LQuote, ['"', '''']) then
    Exit;
  Q := PosEx(LQuote, ATag, P + 1);
  if Q > 0 then
    Result := Copy(ATag, P + 1, Q - P - 1);
end;

class function TDaisySVG.Num(const AText: string; ADefault: Double): Double;
var
  LText: string;
begin
  LText := Trim(AText);
  if LText.EndsWith('px') then
    LText := Copy(LText, 1, Length(LText) - 2);
  if (LText = '') or not TryStrToFloat(LText, Result, TFormatSettings.Invariant) then
    Result := ADefault;
end;

class function TDaisySVG.Fmt(AValue: Double): string;
begin
  Result := FormatFloat('0.###', AValue, TFormatSettings.Invariant);
end;

class procedure TDaisySVG.ReadViewBox(const ATag: string; out AX, AY, AW, AH: Double);
var
  LParts: TArray<string>;
begin
  AX := 0;
  AY := 0;
  AW := 24;
  AH := 24;
  LParts := Attr(ATag, 'viewBox').Replace(',', ' ').Split([' ', #9, #10, #13],
    TStringSplitOptions.ExcludeEmpty);
  if Length(LParts) = 4 then
  begin
    AX := Num(LParts[0], 0);
    AY := Num(LParts[1], 0);
    AW := Num(LParts[2], 24);
    AH := Num(LParts[3], 24);
  end
  else
  begin
    AW := Num(Attr(ATag, 'width'), 24);
    AH := Num(Attr(ATag, 'height'), 24);
  end;
  if AW <= 0 then
    AW := 24;
  if AH <= 0 then
    AH := 24;
end;

class function TDaisySVG.EllipsePath(CX, CY, RX, RY: Double): string;
begin
  if (RX <= 0) or (RY <= 0) then
    Exit('');
  Result := Format('M %s %s a %s %s 0 1 0 %s 0 a %s %s 0 1 0 %s 0 z',
    [Fmt(CX - RX), Fmt(CY), Fmt(RX), Fmt(RY), Fmt(2 * RX), Fmt(RX), Fmt(RY), Fmt(-2 * RX)]);
end;

class function TDaisySVG.RectPath(const ATag: string): string;
var
  X, Y, W, H, RX, RY: Double;
  LRX, LRY: string;
begin
  X := Num(Attr(ATag, 'x'), 0);
  Y := Num(Attr(ATag, 'y'), 0);
  W := Num(Attr(ATag, 'width'), 0);
  H := Num(Attr(ATag, 'height'), 0);
  if (W <= 0) or (H <= 0) then
    Exit('');
  LRX := Attr(ATag, 'rx');
  LRY := Attr(ATag, 'ry');
  RX := Num(LRX, Num(LRY, 0));
  RY := Num(LRY, RX);
  RX := Min(RX, W / 2);
  RY := Min(RY, H / 2);
  if (RX <= 0) or (RY <= 0) then
    Exit(Format('M %s %s h %s v %s h %s z', [Fmt(X), Fmt(Y), Fmt(W), Fmt(H), Fmt(-W)]));
  Result := Format(
    'M %s %s h %s a %s %s 0 0 1 %s %s v %s a %s %s 0 0 1 %s %s h %s a %s %s 0 0 1 %s %s ' +
    'v %s a %s %s 0 0 1 %s %s z',
    [Fmt(X + RX), Fmt(Y), Fmt(W - 2 * RX),
     Fmt(RX), Fmt(RY), Fmt(RX), Fmt(RY), Fmt(H - 2 * RY),
     Fmt(RX), Fmt(RY), Fmt(-RX), Fmt(RY), Fmt(-(W - 2 * RX)),
     Fmt(RX), Fmt(RY), Fmt(-RX), Fmt(-RY), Fmt(-(H - 2 * RY)),
     Fmt(RX), Fmt(RY), Fmt(RX), Fmt(-RY)]);
end;

class function TDaisySVG.PointsPath(const APoints: string; AClose: Boolean): string;
var
  LParts: TArray<string>;
  I: Integer;
begin
  LParts := APoints.Replace(',', ' ').Split([' ', #9, #10, #13], TStringSplitOptions.ExcludeEmpty);
  Result := '';
  I := 0;
  while I + 1 < Length(LParts) do
  begin
    if I = 0 then
      Result := 'M ' + LParts[I] + ' ' + LParts[I + 1]
    else
      Result := Result + ' L ' + LParts[I] + ' ' + LParts[I + 1];
    Inc(I, 2);
  end;
  if AClose and (Result <> '') then
    Result := Result + ' z';
end;

class function TDaisySVG.ShapeToPath(const AName, ATag: string): string;
var
  CX, CY, RX, RY: Double;
begin
  Result := '';
  if SameText(AName, 'path') then
    Result := Attr(ATag, 'd')
  else if SameText(AName, 'circle') then
  begin
    RX := Num(Attr(ATag, 'r'), 0);
    Result := EllipsePath(Num(Attr(ATag, 'cx'), 0), Num(Attr(ATag, 'cy'), 0), RX, RX);
  end
  else if SameText(AName, 'ellipse') then
  begin
    CX := Num(Attr(ATag, 'cx'), 0);
    CY := Num(Attr(ATag, 'cy'), 0);
    RX := Num(Attr(ATag, 'rx'), 0);
    RY := Num(Attr(ATag, 'ry'), 0);
    Result := EllipsePath(CX, CY, RX, RY);
  end
  else if SameText(AName, 'rect') then
    Result := RectPath(ATag)
  else if SameText(AName, 'line') then
    Result := Format('M %s %s L %s %s', [Fmt(Num(Attr(ATag, 'x1'), 0)), Fmt(Num(Attr(ATag, 'y1'), 0)),
      Fmt(Num(Attr(ATag, 'x2'), 0)), Fmt(Num(Attr(ATag, 'y2'), 0))])
  else if SameText(AName, 'polyline') then
    Result := PointsPath(Attr(ATag, 'points'), False)
  else if SameText(AName, 'polygon') then
    Result := PointsPath(Attr(ATag, 'points'), True);
end;

class function TDaisySVG.IconPath(const ASVG: string): string;
var
  LText, LName, LTag, LFill, LStroke, LInheritFill, LInheritStroke, LData: string;
  P, Q, N: Integer;
  LQuote: Char;
  LVX, LVY, LVW, LVH, LScale, LOffX, LOffY: Double;
  LFilled, LHaveMode, LElementFilled: Boolean;
  LParsed: TDaisyIconPaths;
  LPoint: TPointF;
  I: Integer;
begin
  Result := '';
  LText := Trim(ASVG);
  if LText = '' then
    Exit;
  if LText[1] <> '<' then
    Exit(LText); // bare path data

  LScale := 1;
  LOffX := 0;
  LOffY := 0;
  LInheritFill := '';
  LInheritStroke := '';
  LFilled := False;
  LHaveMode := False;
  P := 1;
  while True do
  begin
    P := PosEx('<', LText, P);
    if P = 0 then
      Break;
    // find the end of the tag, ignoring '>' inside quoted values
    Q := P + 1;
    LQuote := #0;
    while Q <= Length(LText) do
    begin
      if LQuote <> #0 then
      begin
        if LText[Q] = LQuote then
          LQuote := #0;
      end
      else if CharInSet(LText[Q], ['"', '''']) then
        LQuote := LText[Q]
      else if LText[Q] = '>' then
        Break;
      Inc(Q);
    end;
    if (P + 1 > Length(LText)) or CharInSet(LText[P + 1], ['/', '!', '?']) then
    begin
      P := Q + 1;
      Continue;
    end;
    LTag := Copy(LText, P + 1, Q - P - 1);
    P := Q + 1;

    N := 1;
    while (N <= Length(LTag)) and not CharInSet(LTag[N], [' ', #9, #10, #13, '/']) do
      Inc(N);
    LName := Copy(LTag, 1, N - 1);

    if SameText(LName, 'svg') or SameText(LName, 'g') then
    begin
      if SameText(LName, 'svg') then
      begin
        // scale into the 24 x 24 box, keeping the aspect ratio and centring
        ReadViewBox(LTag, LVX, LVY, LVW, LVH);
        LScale := 24 / Max(LVW, LVH);
        LOffX := -LVX * LScale + (24 - LVW * LScale) / 2;
        LOffY := -LVY * LScale + (24 - LVH * LScale) / 2;
      end;
      if Attr(LTag, 'fill') <> '' then
        LInheritFill := Attr(LTag, 'fill');
      if Attr(LTag, 'stroke') <> '' then
        LInheritStroke := Attr(LTag, 'stroke');
      Continue;
    end;

    LData := ShapeToPath(LName, LTag);
    if LData = '' then
      Continue;

    LFill := Attr(LTag, 'fill');
    if LFill = '' then
      LFill := LInheritFill;
    if LFill = '' then
      LFill := 'black'; // the SVG default
    LStroke := Attr(LTag, 'stroke');
    if LStroke = '' then
      LStroke := LInheritStroke;
    LElementFilled := not SameText(LFill, 'none');
    if (not LElementFilled) and ((LStroke = '') or SameText(LStroke, 'none')) then
      Continue; // invisible, e.g. Tabler's empty bounding box

    if not LHaveMode then
    begin
      LFilled := LElementFilled;
      LHaveMode := True;
    end
    else if LElementFilled <> LFilled then
      Continue;

    LParsed := DaisyParseSvgPath(LData);
    for I := 0 to High(LParsed) do
    begin
      LData := '';
      for LPoint in LParsed[I] do
      begin
        if LData = '' then
          LData := 'M '
        else
          LData := LData + ' L ';
        LData := LData + Fmt(LPoint.X * LScale + LOffX) + ' ' + Fmt(LPoint.Y * LScale + LOffY);
      end;
      if Result <> '' then
        Result := Result + ' ';
      Result := Result + LData;
    end;
  end;
  if LFilled and (Result <> '') then
    Result := CFilledMark + Result;
end;

class function TDaisySVG.ToPaths(const AIconPath: string; out AFilled: Boolean): TDaisyIconPaths;
begin
  AFilled := (AIconPath <> '') and (AIconPath[1] = CFilledMark);
  if AFilled then
    Result := DaisyParseSvgPath(Copy(AIconPath, 2, MaxInt))
  else
    Result := DaisyParseSvgPath(AIconPath);
end;

{ Coloured layers }

class function TDaisySVG.Prop(const ATag, AName: string): string;
var
  LPart: string;
  LColon: Integer;
begin
  Result := Trim(Attr(ATag, AName));
  if Result <> '' then
    Exit;
  for LPart in Attr(ATag, 'style').Split([';']) do
  begin
    LColon := Pos(':', LPart);
    if (LColon > 0) and SameText(Trim(Copy(LPart, 1, LColon - 1)), AName) then
      Exit(Trim(Copy(LPart, LColon + 1, MaxInt)));
  end;
end;

class procedure TDaisySVG.ApplyStyle(var AStyle: TStyle; const ATag: string);
var
  LValue: string;
begin
  LValue := Prop(ATag, 'fill');
  if LValue <> '' then
    AStyle.Fill := LValue;
  LValue := Prop(ATag, 'stroke');
  if LValue <> '' then
    AStyle.Stroke := LValue;
  LValue := Prop(ATag, 'stroke-width');
  if LValue <> '' then
    AStyle.StrokeWidth := LValue;
  LValue := Prop(ATag, 'fill-opacity');
  if LValue <> '' then
    AStyle.FillOpacity := LValue;
  LValue := Prop(ATag, 'stroke-opacity');
  if LValue <> '' then
    AStyle.StrokeOpacity := LValue;
  LValue := Prop(ATag, 'fill-rule');
  if LValue <> '' then
    AStyle.FillRule := LValue;
  LValue := Prop(ATag, 'opacity');
  if LValue <> '' then
    AStyle.Opacity := AStyle.Opacity * EnsureRange(Num(LValue, 1), 0, 1);
end;

class function TDaisySVG.NextTag(const AText: string; var P: Integer; out ATag: string): Boolean;
var
  Q: Integer;
  LQuote: Char;
begin
  Result := False;
  ATag := '';
  while True do
  begin
    P := PosEx('<', AText, P);
    if P = 0 then
      Exit;
    Q := P + 1;
    LQuote := #0;
    while Q <= Length(AText) do
    begin
      if LQuote <> #0 then
      begin
        if AText[Q] = LQuote then
          LQuote := #0;
      end
      else if CharInSet(AText[Q], ['"', '''']) then
        LQuote := AText[Q]
      else if AText[Q] = '>' then
        Break;
      Inc(Q);
    end;
    ATag := Copy(AText, P + 1, Q - P - 1);
    P := Q + 1;
    if (ATag <> '') and not CharInSet(ATag[1], ['!', '?']) then
      Exit(True);
  end;
end;

class function TDaisySVG.NamedColor(const AName: string; out AColor: TAlphaColor): Boolean;
type
  TNamed = record
    Name: string;
    RGB: Cardinal;
  end;
const
  CNames: array[0..39] of TNamed = (
    (Name: 'black'; RGB: $000000), (Name: 'white'; RGB: $FFFFFF),
    (Name: 'red'; RGB: $FF0000), (Name: 'green'; RGB: $008000),
    (Name: 'blue'; RGB: $0000FF), (Name: 'yellow'; RGB: $FFFF00),
    (Name: 'orange'; RGB: $FFA500), (Name: 'purple'; RGB: $800080),
    (Name: 'pink'; RGB: $FFC0CB), (Name: 'gray'; RGB: $808080),
    (Name: 'grey'; RGB: $808080), (Name: 'silver'; RGB: $C0C0C0),
    (Name: 'gold'; RGB: $FFD700), (Name: 'brown'; RGB: $A52A2A),
    (Name: 'cyan'; RGB: $00FFFF), (Name: 'aqua'; RGB: $00FFFF),
    (Name: 'magenta'; RGB: $FF00FF), (Name: 'fuchsia'; RGB: $FF00FF),
    (Name: 'lime'; RGB: $00FF00), (Name: 'navy'; RGB: $000080),
    (Name: 'teal'; RGB: $008080), (Name: 'maroon'; RGB: $800000),
    (Name: 'olive'; RGB: $808000), (Name: 'crimson'; RGB: $DC143C),
    (Name: 'indigo'; RGB: $4B0082), (Name: 'violet'; RGB: $EE82EE),
    (Name: 'coral'; RGB: $FF7F50), (Name: 'salmon'; RGB: $FA8072),
    (Name: 'tomato'; RGB: $FF6347), (Name: 'khaki'; RGB: $F0E68C),
    (Name: 'darkgray'; RGB: $A9A9A9), (Name: 'lightgray'; RGB: $D3D3D3),
    (Name: 'darkblue'; RGB: $00008B), (Name: 'lightblue'; RGB: $ADD8E6),
    (Name: 'darkgreen'; RGB: $006400), (Name: 'lightgreen'; RGB: $90EE90),
    (Name: 'skyblue'; RGB: $87CEEB), (Name: 'turquoise'; RGB: $40E0D0),
    (Name: 'beige'; RGB: $F5F5DC), (Name: 'orangered'; RGB: $FF4500));
var
  I: Integer;
begin
  for I := Low(CNames) to High(CNames) do
    if CNames[I].Name = AName then
    begin
      AColor := TAlphaColor($FF000000 or CNames[I].RGB);
      Exit(True);
    end;
  Result := False;
end;

// False means "paint nothing" (none, transparent, or something not understood)
class function TDaisySVG.ParseColor(const AText, AValue: string; out AColor: TAlphaColor;
  out ACurrent: Boolean): Boolean;
var
  LValue, LId, LStop: string;
  LParts: TArray<string>;
  LHex: Integer;
  P, Q, R, G, B: Integer;
  LAlpha: Double;
begin
  Result := False;
  ACurrent := False;
  AColor := TAlphaColors.Black;
  LValue := LowerCase(Trim(AValue));
  if (LValue = '') or (LValue = 'none') or (LValue = 'transparent') then
    Exit;
  if LValue = 'currentcolor' then
  begin
    ACurrent := True;
    Exit(True);
  end;
  if LValue.StartsWith('url(') then
  begin
    // a gradient is drawn as its first stop colour
    P := Pos('#', LValue);
    Q := Pos(')', LValue);
    if (AText = '') or (P = 0) or (Q <= P) then
      Exit;
    LId := Trim(Copy(AValue, P + 1, Q - P - 1)).Trim(['''', '"']);
    P := Pos('id="' + LId + '"', AText);
    if P = 0 then
      P := Pos('id=''' + LId + '''', AText);
    if P = 0 then
      Exit;
    P := PosEx('<stop', AText, P);
    if P = 0 then
      Exit;
    if not NextTag(AText, P, LStop) then
      Exit;
    LValue := Prop(LStop, 'stop-color');
    Exit(ParseColor('', LValue, AColor, ACurrent));
  end;
  if LValue[1] = '#' then
  begin
    LValue := Copy(LValue, 2, MaxInt);
    if Length(LValue) in [3, 4] then
      LValue := LValue[1] + LValue[1] + LValue[2] + LValue[2] + LValue[3] + LValue[3] +
        IfThen(Length(LValue) = 4, LValue[4] + LValue[4], '');
    LHex := StrToIntDef('$' + Copy(LValue, 1, 6), -1);
    if (LHex < 0) or not (Length(LValue) in [6, 8]) then
      Exit;
    AColor := TAlphaColor($FF000000 or Cardinal(LHex));
    if Length(LValue) = 8 then
      AColor := DaisyWithAlpha(AColor, StrToIntDef('$' + Copy(LValue, 7, 2), 255) / 255);
    Exit(True);
  end;
  if LValue.StartsWith('rgb') then
  begin
    P := Pos('(', LValue);
    Q := Pos(')', LValue);
    if (P = 0) or (Q <= P) then
      Exit;
    LParts := Copy(LValue, P + 1, Q - P - 1).Replace(',', ' ').Replace('/', ' ').Split(
      [' '], TStringSplitOptions.ExcludeEmpty);
    if Length(LParts) < 3 then
      Exit;
    R := EnsureRange(Round(Num(LParts[0].Replace('%', ''), 0) * IfThen(LParts[0].EndsWith('%'), 2.55, 1)), 0, 255);
    G := EnsureRange(Round(Num(LParts[1].Replace('%', ''), 0) * IfThen(LParts[1].EndsWith('%'), 2.55, 1)), 0, 255);
    B := EnsureRange(Round(Num(LParts[2].Replace('%', ''), 0) * IfThen(LParts[2].EndsWith('%'), 2.55, 1)), 0, 255);
    AColor := TAlphaColor($FF000000 or (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B));
    if Length(LParts) > 3 then
    begin
      LAlpha := Num(LParts[3].Replace('%', ''), 1);
      if LParts[3].EndsWith('%') then
        LAlpha := LAlpha / 100;
      AColor := DaisyWithAlpha(AColor, LAlpha);
    end;
    Exit(True);
  end;
  Result := NamedColor(LValue, AColor);
end;

class function TDaisySVG.LayerColor(const ALayer: TDaisySVGLayer; AFill: Boolean;
  ACurrent: TAlphaColor): TAlphaColor;
var
  LCurrent: Boolean;
  LOpacity: Single;
begin
  if AFill then
  begin
    Result := ALayer.FillColor;
    LCurrent := ALayer.FillCurrent;
    LOpacity := ALayer.FillOpacity;
  end
  else
  begin
    Result := ALayer.StrokeColor;
    LCurrent := ALayer.StrokeCurrent;
    LOpacity := ALayer.StrokeOpacity;
  end;
  if LCurrent then
    Result := ACurrent;
  Result := DaisyWithAlpha(Result, LOpacity);
end;

class function TDaisySVG.Layers(const ASVG: string): TDaisySVGLayers;
var
  LText, LTag, LName, LData, LSkip: string;
  LStack: TArray<TStyle>;
  LDepth, P, N, I, J, LCount: Integer;
  LVX, LVY, LVW, LVH, LScale, LOffX, LOffY: Double;
  LHaveBox: Boolean;
  LStyle: TStyle;
  LLayer: TDaisySVGLayer;
  LParsed: TDaisyIconPaths;
begin
  Result := nil;
  LText := Trim(ASVG);
  if LText = '' then
    Exit;
  if LText[1] <> '<' then
  begin
    LLayer := Default(TDaisySVGLayer);
    LLayer.Paths := DaisyParseSvgPath(LText);
    if Length(LLayer.Paths) = 0 then
      Exit;
    LLayer.HasStroke := True;
    LLayer.StrokeCurrent := True;
    LLayer.StrokeOpacity := 1;
    LLayer.StrokeWidth := 2;
    SetLength(Result, 1);
    Result[0] := LLayer;
    Exit;
  end;

  LScale := 1;
  LOffX := 0;
  LOffY := 0;
  LHaveBox := False;
  LSkip := '';
  LStyle := Default(TStyle);
  LStyle.Opacity := 1;
  SetLength(LStack, 1);
  LStack[0] := LStyle;
  LDepth := 0;
  LCount := 0;
  P := 1;
  while NextTag(LText, P, LTag) do
  begin
    if LTag[1] = '/' then
    begin
      LName := LowerCase(Trim(Copy(LTag, 2, MaxInt)));
      if LSkip <> '' then
      begin
        if LName = LSkip then
          LSkip := '';
      end
      else if (LName = 'g') and (LDepth > 0) then
        Dec(LDepth);
      Continue;
    end;

    N := 1;
    while (N <= Length(LTag)) and not CharInSet(LTag[N], [' ', #9, #10, #13, '/']) do
      Inc(N);
    LName := LowerCase(Copy(LTag, 1, N - 1));
    if LSkip <> '' then
      Continue;

    if MatchStr(LName, ['defs', 'clippath', 'mask', 'symbol', 'title', 'desc', 'style',
      'metadata', 'pattern', 'marker', 'lineargradient', 'radialgradient']) then
    begin
      if not LTag.EndsWith('/') then
        LSkip := LName;
      Continue;
    end;

    if LName = 'svg' then
    begin
      if not LHaveBox then
      begin
        ReadViewBox(LTag, LVX, LVY, LVW, LVH);
        LScale := 24 / Max(LVW, LVH);
        LOffX := -LVX * LScale + (24 - LVW * LScale) / 2;
        LOffY := -LVY * LScale + (24 - LVH * LScale) / 2;
        LHaveBox := True;
      end;
      ApplyStyle(LStack[LDepth], LTag);
      Continue;
    end;
    if LName = 'g' then
    begin
      if not LTag.EndsWith('/') then
      begin
        Inc(LDepth);
        if LDepth >= Length(LStack) then
          SetLength(LStack, LDepth + 8);
        LStack[LDepth] := LStack[LDepth - 1];
        ApplyStyle(LStack[LDepth], LTag);
      end;
      Continue;
    end;

    LData := ShapeToPath(LName, LTag);
    if LData = '' then
      Continue;
    LStyle := LStack[LDepth];
    ApplyStyle(LStyle, LTag);

    LLayer := Default(TDaisySVGLayer);
    if LStyle.Fill = '' then
      LStyle.Fill := 'black'; // the SVG default
    LLayer.HasFill := ParseColor(LText, LStyle.Fill, LLayer.FillColor, LLayer.FillCurrent);
    LLayer.HasStroke := ParseColor(LText, LStyle.Stroke, LLayer.StrokeColor, LLayer.StrokeCurrent);
    if not (LLayer.HasFill or LLayer.HasStroke) then
      Continue;
    LLayer.FillOpacity := EnsureRange(Num(LStyle.FillOpacity, 1), 0, 1) * LStyle.Opacity;
    LLayer.StrokeOpacity := EnsureRange(Num(LStyle.StrokeOpacity, 1), 0, 1) * LStyle.Opacity;
    LLayer.StrokeWidth := Max(0.1, Num(LStyle.StrokeWidth, 1)) * LScale;
    LLayer.EvenOdd := SameText(LStyle.FillRule, 'evenodd');

    LParsed := DaisyParseSvgPath(LData);
    if Length(LParsed) = 0 then
      Continue;
    SetLength(LLayer.Paths, Length(LParsed));
    for I := 0 to High(LParsed) do
    begin
      SetLength(LLayer.Paths[I], Length(LParsed[I]));
      for J := 0 to High(LParsed[I]) do
        LLayer.Paths[I][J] := PointF(LParsed[I][J].X * LScale + LOffX,
          LParsed[I][J].Y * LScale + LOffY);
    end;

    if LCount >= Length(Result) then
      SetLength(Result, LCount + 8);
    Result[LCount] := LLayer;
    Inc(LCount);
  end;
  SetLength(Result, LCount);
end;

end.
