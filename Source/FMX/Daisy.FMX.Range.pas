unit Daisy.FMX.Range;

{
  TDaisyFmxRange - the DaisyUI "range" slider: a thin track, filled up to a round thumb.
  Variant colours the fill and thumb ring, SizeKind gives xs..xl, Orientation makes it
  vertical, Step snaps the value, TickCount / TickLabels draw the scale under (or
  beside) the track. Mouse and the arrow, Home, End, PgUp and PgDn keys change Value.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Range, Daisy.FMX.Control;

type
  TDaisyFmxRange = class(TDaisyControl)
  strict private
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FStep: Double;
    FOrientation: TDaisyRangeOrientation;
    FShowFill: Boolean;
    FTickCount: Integer;
    FTickLabels: TStrings;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FDragging: Boolean;
    FRingVisible: Boolean;
    FRingTimer: TTimer;
    FOnChange: TNotifyEvent;
    procedure ShowRing;
    procedure RingTimer(Sender: TObject);
    procedure SetMin(const AValue: Double);
    procedure SetMax(const AValue: Double);
    procedure SetValue(const AValue: Double);
    procedure SetStep(const AValue: Double);
    procedure SetOrientation(const AValue: TDaisyRangeOrientation);
    procedure SetShowFill(const AValue: Boolean);
    procedure SetTickCount(const AValue: Integer);
    procedure SetTickLabels(const AValue: TStrings);
    procedure SetAutoFit(const AValue: Boolean);
    procedure TickLabelsChanged(Sender: TObject);
    function ThumbSize: Single;
    function TickExtent: Single;
    function Vertical: Boolean;
    function ThumbCentre(AFraction: Double): Single;
    function ValueAt(X, Y: Single): Double;
    function StepSize: Double;
    procedure UpdateSize;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Min: Double read FMin write SetMin;
    property Max: Double read FMax write SetMax;
    property Value: Double read FValue write SetValue;
    // The value snaps to multiples of Step from Min; 0 means continuous
    property Step: Double read FStep write SetStep;
    property Orientation: TDaisyRangeOrientation read FOrientation write SetOrientation
      default roHorizontal;
    // Colours the track up to the thumb
    property ShowFill: Boolean read FShowFill write SetShowFill default True;
    // Number of marks of the scale (2 or more); 0 hides the scale
    property TickCount: Integer read FTickCount write SetTickCount default 0;
    // One caption per mark, shown beside the scale
    property TickLabels: TStrings read FTickLabels write SetTickLabels;
    // The thickness follows SizeKind and the scale; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CTickLength = 6;
  CTickGap = 6;
  CLabelGap = 4;
  CLabelFont = 12;
  CRingMargin = 4; // room around the thumb for the focus ring
  CRingDuration = 2000;

{ TDaisyFmxRange }

constructor TDaisyFmxRange.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin := 0;
  FMax := 100;
  FStep := 1;
  FShowFill := True;
  FAutoFit := True;
  FTickLabels := TStringList.Create;
  TStringList(FTickLabels).OnChange := TickLabelsChanged;
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Position.X, Position.Y, 200, 24);
  UpdateSize;
end;

destructor TDaisyFmxRange.Destroy;
begin
  FTickLabels.Free;
  inherited Destroy;
end;

function TDaisyFmxRange.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxRange.DrawsFocusRing: Boolean;
begin
  Result := False; // the thumb shows the focus
end;

function TDaisyFmxRange.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRange.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRange.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRange.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxRange.SetMin(const AValue: Double);
begin
  if FMin <> AValue then
  begin
    FMin := AValue;
    if not (csLoading in ComponentState) then
      SetValue(FValue);
    Repaint;
  end;
end;

procedure TDaisyFmxRange.SetMax(const AValue: Double);
begin
  if FMax <> AValue then
  begin
    FMax := AValue;
    if not (csLoading in ComponentState) then
      SetValue(FValue);
    Repaint;
  end;
end;

procedure TDaisyFmxRange.SetValue(const AValue: Double);
var
  LValue: Double;
begin
  if csLoading in ComponentState then
    LValue := AValue // the limits may not be loaded yet; Loaded snaps it
  else
    LValue := DaisyRangeSnap(AValue, FMin, FMax, FStep);
  if FValue <> LValue then
  begin
    FValue := LValue;
    ShowRing;
    Repaint;
    if not (csLoading in ComponentState) and Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TDaisyFmxRange.SetStep(const AValue: Double);
begin
  if FStep <> AValue then
  begin
    FStep := System.Math.Max(0, AValue);
    if not (csLoading in ComponentState) then
      SetValue(FValue);
  end;
end;

procedure TDaisyFmxRange.SetOrientation(const AValue: TDaisyRangeOrientation);
begin
  if FOrientation = AValue then
    Exit;
  FOrientation := AValue;
  if not (csLoading in ComponentState) then
  begin
    FUpdating := True;
    try
      SetBounds(Position.X, Position.Y, Height, Width); // the long side stays the long side
    finally
      FUpdating := False;
    end;
    UpdateSize;
  end;
  Repaint;
end;

procedure TDaisyFmxRange.SetShowFill(const AValue: Boolean);
begin
  if FShowFill <> AValue then
  begin
    FShowFill := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRange.SetTickCount(const AValue: Integer);
begin
  if FTickCount <> AValue then
  begin
    FTickCount := System.Math.Max(0, AValue);
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxRange.SetTickLabels(const AValue: TStrings);
begin
  FTickLabels.Assign(AValue);
end;

procedure TDaisyFmxRange.TickLabelsChanged(Sender: TObject);
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxRange.SetAutoFit(const AValue: Boolean);
begin
  if FAutoFit <> AValue then
  begin
    FAutoFit := AValue;
    UpdateSize;
  end;
end;

function TDaisyFmxRange.Vertical: Boolean;
begin
  Result := FOrientation = roVertical;
end;

function TDaisyFmxRange.ThumbSize: Single;
begin
  Result := DaisyRangeThumb(SizeKind) + 2 * CRingMargin;
end;

procedure TDaisyFmxRange.ShowRing;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) then
    Exit;
  FRingVisible := True;
  if FRingTimer = nil then
  begin
    FRingTimer := TTimer.Create(Self);
    FRingTimer.OnTimer := RingTimer;
  end;
  FRingTimer.Enabled := False;
  FRingTimer.Interval := CRingDuration;
  FRingTimer.Enabled := True;
end;

procedure TDaisyFmxRange.RingTimer(Sender: TObject);
begin
  FRingTimer.Enabled := False;
  FRingVisible := False;
  Repaint;
end;

// Room taken by the scale beside the track
function TDaisyFmxRange.TickExtent: Single;
var
  I: Integer;
  LBand: Single;
begin
  Result := 0;
  if FTickCount < 2 then
    Exit;
  Result := CTickGap + CTickLength;
  if FTickLabels.Count > 0 then
  begin
    LBand := 0;
    if Vertical then
      for I := 0 to FTickLabels.Count - 1 do
        LBand := System.Math.Max(LBand, MeasureTextWidth(FTickLabels[I], CLabelFont, False))
    else
      LBand := MeasureTextHeight('Ag', 200, CLabelFont, False);
    Result := Result + CLabelGap + LBand;
  end;
end;

procedure TDaisyFmxRange.UpdateSize;
var
  LThickness: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LThickness := ThumbSize + TickExtent;
  if (Vertical and SameValue(Width, LThickness)) or
    (not Vertical and SameValue(Height, LThickness)) then
    Exit;
  FUpdating := True;
  try
    if Vertical then
      SetBounds(Position.X, Position.Y, LThickness, Height)
    else
      SetBounds(Position.X, Position.Y, Width, LThickness);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxRange.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxRange.Resize;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyFmxRange.Loaded;
begin
  inherited;
  FValue := DaisyRangeSnap(FValue, FMin, FMax, FStep);
  UpdateSize;
end;

// Centre of the thumb along the long axis
function TDaisyFmxRange.ThumbCentre(AFraction: Double): Single;
var
  LHalf: Single;
begin
  LHalf := ThumbSize / 2;
  if Vertical then
    Result := Height - LHalf - AFraction * (Height - ThumbSize)
  else
    Result := LHalf + AFraction * (Width - ThumbSize);
end;

function TDaisyFmxRange.ValueAt(X, Y: Single): Double;
var
  LFraction: Double;
begin
  if Vertical then
    LFraction := 1 - (Y - ThumbSize / 2) / System.Math.Max(1, Height - ThumbSize)
  else
    LFraction := (X - ThumbSize / 2) / System.Math.Max(1, Width - ThumbSize);
  Result := FMin + EnsureRange(LFraction, 0, 1) * (FMax - FMin);
end;

function TDaisyFmxRange.StepSize: Double;
begin
  if FStep > 0 then
    Result := FStep
  else
    Result := (FMax - FMin) / 100;
end;

procedure TDaisyFmxRange.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  LStep: Double;
  LHandled: Boolean;
begin
  LHandled := Enabled;
  if LHandled then
  begin
    LStep := StepSize;
    case Key of
      vkLeft, vkDown: SetValue(FValue - LStep);
      vkRight, vkUp: SetValue(FValue + LStep);
      vkPrior: SetValue(FValue + 10 * LStep);
      vkNext: SetValue(FValue - 10 * LStep);
      vkHome: SetValue(FMin);
      vkEnd: SetValue(FMax);
    else
      LHandled := False;
    end;
  end;
  if LHandled then
  begin
    Key := 0;
    KeyChar := #0;
  end
  else
    inherited KeyDown(Key, KeyChar, Shift);
end;

procedure TDaisyFmxRange.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = TMouseButton.mbLeft) and Enabled and not (csDesigning in ComponentState) then
  begin
    SetFocus;
    FDragging := True;
    SetValue(ValueAt(X, Y));
  end;
end;

procedure TDaisyFmxRange.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited MouseMove(Shift, X, Y);
  if FDragging then
    SetValue(ValueAt(X, Y));
end;

procedure TDaisyFmxRange.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FDragging := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TDaisyFmxRange.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LTint, LTickColor: TAlphaColor;
  LD, LT, LCentre, LRing, LFade, LPos: Single;
  LTrack, LFill, LThumb, LBox, LText: TRectF;
  LFraction: Double;
  I: Integer;
begin
  if Variant = dvDefault then
    LTint := Theme.BaseContent
  else
    LTint := DaisyVariantPalette(Theme, Variant).Fill;
  LFade := 1;
  if not Enabled then
    LFade := 0.3;
  LD := ThumbSize;
  LT := DaisyRangeTrack(SizeKind);
  LFraction := DaisyRangeFraction(FValue, FMin, FMax);
  LCentre := ThumbCentre(LFraction);

  if Vertical then
  begin
    LTrack := RectF((LD - LT) / 2, 0, (LD + LT) / 2, Height);
    LFill := RectF(LTrack.Left, LCentre, LTrack.Right, Height);
    LThumb := RectF(0, LCentre - LD / 2, LD, LCentre + LD / 2);
  end
  else
  begin
    LTrack := RectF(0, (LD - LT) / 2, Width, (LD + LT) / 2);
    LFill := RectF(0, LTrack.Top, LCentre, LTrack.Bottom);
    LThumb := RectF(LCentre - LD / 2, 0, LCentre + LD / 2, LD);
  end;

  FillRound(LTrack, LT / 2, DaisyWithAlpha(Theme.BaseContent, 0.1 * LFade));
  if FShowFill and (LFraction > 0) then
    FillRound(LFill, LT / 2, DaisyWithAlpha(LTint, LFade));

  LRing := System.Math.Max(2, LD / 6);
  LThumb.Inflate(-CRingMargin, -CRingMargin);
  FillRound(LThumb, LThumb.Width / 2, DaisyWithAlpha(LTint, LFade));
  LBox := LThumb;
  LBox.Inflate(-LRing, -LRing);
  FillRound(LBox, LBox.Width / 2, DaisyWithAlpha(Theme.Base100, LFade));
  if IsFocused and FRingVisible then
  begin
    LBox := LThumb;
    LBox.Inflate(3, 3);
    StrokeRound(LBox, LBox.Width / 2, DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade), 1, False);
  end;

  if FTickCount < 2 then
    Exit;
  LTickColor := DaisyWithAlpha(Theme.BaseContent, 0.7 * LFade);
  for I := 0 to FTickCount - 1 do
  begin
    LPos := ThumbCentre(I / (FTickCount - 1));
    if Vertical then
      LBox := RectF(LD + CTickGap, LPos - 0.5, LD + CTickGap + CTickLength, LPos + 0.5)
    else
      LBox := RectF(LPos - 0.5, LD + CTickGap, LPos + 0.5, LD + CTickGap + CTickLength);
    FillRound(LBox, 0, LTickColor);

    if I < FTickLabels.Count then
    begin
      if Vertical then
      begin
        LText := RectF(LD + CTickGap + CTickLength + CLabelGap, LPos - 10, Width, LPos + 10);
        DrawText(FTickLabels[I], LText, DaisyWithAlpha(Theme.BaseContent, LFade), CLabelFont,
          False, TTextAlign.Leading, TTextAlign.Center, False);
      end
      else
      begin
        LText := RectF(LPos - 40, LD + CTickGap + CTickLength + CLabelGap, LPos + 40, Height);
        DrawText(FTickLabels[I], LText, DaisyWithAlpha(Theme.BaseContent, LFade), CLabelFont,
          False, TTextAlign.Center, TTextAlign.Leading, False);
      end;
    end;
  end;
end;

end.
