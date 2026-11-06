unit Daisy.VCL.Range;

{
  TDaisyRange - the DaisyUI "range" slider: a thin track, filled up to a round thumb.
  Variant colours the fill and thumb ring, SizeKind gives xs..xl, Orientation makes it
  vertical, Step snaps the value, TickCount / TickLabels draw the scale under (or
  beside) the track. Mouse and the arrow, Home, End, PgUp and PgDn keys change Value.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.ExtCtrls, Daisy.Theme, Daisy.Range, Daisy.VCL.Control;

type
  TDaisyRange = class(TDaisyControl)
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
    procedure SetMin(const Value: Double);
    procedure SetMax(const Value: Double);
    procedure SetValue(const Value: Double);
    procedure SetStep(const Value: Double);
    procedure SetOrientation(const Value: TDaisyRangeOrientation);
    procedure SetShowFill(const Value: Boolean);
    procedure SetTickCount(const Value: Integer);
    procedure SetTickLabels(const Value: TStrings);
    procedure SetAutoFit(const Value: Boolean);
    procedure TickLabelsChanged(Sender: TObject);
    function ThumbSize: Integer;
    function TickExtent: Integer;
    function Vertical: Boolean;
    function ThumbCentre(AFraction: Double): Single;
    function ValueAt(X, Y: Integer): Double;
    function StepSize: Double;
    procedure ApplyPoint(X, Y: Integer);
    procedure UpdateSize;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
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
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

{ TDaisyRange }

constructor TDaisyRange.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin := 0;
  FMax := 100;
  FStep := 1;
  FShowFill := True;
  FAutoFit := True;
  FTickLabels := TStringList.Create;
  TStringList(FTickLabels).OnChange := TickLabelsChanged;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Left, Top, 200, 24);
  UpdateSize;
end;

destructor TDaisyRange.Destroy;
begin
  FTickLabels.Free;
  inherited Destroy;
end;

function TDaisyRange.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyRange.DrawsFocusRing: Boolean;
begin
  Result := False; // the thumb shows the focus
end;

function TDaisyRange.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyRange.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyRange.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyRange.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyRange.SetMin(const Value: Double);
begin
  if FMin <> Value then
  begin
    FMin := Value;
    if not (csLoading in ComponentState) then
      SetValue(FValue);
    Invalidate;
  end;
end;

procedure TDaisyRange.SetMax(const Value: Double);
begin
  if FMax <> Value then
  begin
    FMax := Value;
    if not (csLoading in ComponentState) then
      SetValue(FValue);
    Invalidate;
  end;
end;

procedure TDaisyRange.SetValue(const Value: Double);
var
  LValue: Double;
begin
  if csLoading in ComponentState then
    LValue := Value // the limits may not be loaded yet; Loaded snaps it
  else
    LValue := DaisyRangeSnap(Value, FMin, FMax, FStep);
  if FValue <> LValue then
  begin
    FValue := LValue;
    ShowRing;
    Invalidate;
    if not (csLoading in ComponentState) and Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TDaisyRange.SetStep(const Value: Double);
begin
  if FStep <> Value then
  begin
    FStep := System.Math.Max(0, Value);
    if not (csLoading in ComponentState) then
      SetValue(FValue);
  end;
end;

procedure TDaisyRange.SetOrientation(const Value: TDaisyRangeOrientation);
begin
  if FOrientation = Value then
    Exit;
  FOrientation := Value;
  if not (csLoading in ComponentState) then
  begin
    FUpdating := True;
    try
      SetBounds(Left, Top, Height, Width); // the long side stays the long side
    finally
      FUpdating := False;
    end;
    UpdateSize;
  end;
  Invalidate;
end;

procedure TDaisyRange.SetShowFill(const Value: Boolean);
begin
  if FShowFill <> Value then
  begin
    FShowFill := Value;
    Invalidate;
  end;
end;

procedure TDaisyRange.SetTickCount(const Value: Integer);
begin
  if FTickCount <> Value then
  begin
    FTickCount := System.Math.Max(0, Value);
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyRange.SetTickLabels(const Value: TStrings);
begin
  FTickLabels.Assign(Value);
end;

procedure TDaisyRange.TickLabelsChanged(Sender: TObject);
begin
  UpdateSize;
  Invalidate;
end;

procedure TDaisyRange.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyRange.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
end;

function TDaisyRange.Vertical: Boolean;
begin
  Result := FOrientation = roVertical;
end;

function TDaisyRange.ThumbSize: Integer;
begin
  Result := ScaleValue(DaisyRangeThumb(SizeKind) + 2 * CRingMargin);
end;

procedure TDaisyRange.ShowRing;
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

procedure TDaisyRange.RingTimer(Sender: TObject);
begin
  FRingTimer.Enabled := False;
  FRingVisible := False;
  Invalidate;
end;

// Room taken by the scale beside the track
function TDaisyRange.TickExtent: Integer;
var
  I, LBand: Integer;
begin
  Result := 0;
  if FTickCount < 2 then
    Exit;
  Result := ScaleValue(CTickGap + CTickLength);
  if FTickLabels.Count > 0 then
  begin
    LBand := 0;
    if Vertical then
      for I := 0 to FTickLabels.Count - 1 do
        LBand := System.Math.Max(LBand, MeasureTextWidth(FTickLabels[I], CLabelFont, False))
    else
      LBand := MeasureTextHeight('Ag', 200, CLabelFont, False);
    Inc(Result, ScaleValue(CLabelGap) + LBand);
  end;
end;

procedure TDaisyRange.UpdateSize;
var
  LThickness: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LThickness := ThumbSize + TickExtent;
  if (Vertical and (Width = LThickness)) or (not Vertical and (Height = LThickness)) then
    Exit;
  FUpdating := True;
  try
    if Vertical then
      SetBounds(Left, Top, LThickness, Height)
    else
      SetBounds(Left, Top, Width, LThickness);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyRange.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyRange.Resize;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyRange.Loaded;
begin
  inherited;
  FValue := DaisyRangeSnap(FValue, FMin, FMax, FStep);
  UpdateSize;
end;

// Centre of the thumb along the long axis
function TDaisyRange.ThumbCentre(AFraction: Double): Single;
var
  LHalf: Single;
begin
  LHalf := ThumbSize / 2;
  if Vertical then
    Result := Height - LHalf - AFraction * (Height - ThumbSize)
  else
    Result := LHalf + AFraction * (Width - ThumbSize);
end;

function TDaisyRange.ValueAt(X, Y: Integer): Double;
var
  LSpan, LFraction: Double;
begin
  if Vertical then
  begin
    LSpan := Height - ThumbSize;
    LFraction := 1 - (Y - ThumbSize / 2)     / System.Math.Max(1, LSpan);
  end
  else
  begin
    LSpan := Width - ThumbSize;
    LFraction := (X -     ThumbSize / 2) / System.Math.Max(1, LSpan);
  end;
  Result := FMin + EnsureRange(LFraction, 0, 1) * (FMax - FMin);
end;

function TDaisyRange.StepSize: Double;
begin
  if FStep > 0 then
    Result := FStep
  else
    Result := (FMax - FMin) / 100;
end;

procedure TDaisyRange.ApplyPoint(X, Y: Integer);
begin
  SetValue(ValueAt(X, Y));
end;

procedure TDaisyRange.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TDaisyRange.KeyDown(var Key: Word; Shift: TShiftState);
var
  LStep: Double;
begin
  if not Enabled then
  begin
    inherited KeyDown(Key, Shift);
    Exit;
  end;
  LStep := StepSize;
  case Key of
    VK_LEFT, VK_DOWN: SetValue(FValue - LStep);
    VK_RIGHT, VK_UP: SetValue(FValue + LStep);
    VK_PRIOR: SetValue(FValue + 10 * LStep);
    VK_NEXT: SetValue(FValue - 10 * LStep);
    VK_HOME: SetValue(FMin);
    VK_END: SetValue(FMax);
  else
    inherited KeyDown(Key, Shift);
    Exit;
  end;
  Key := 0;
end;

procedure TDaisyRange.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled and not (csDesigning in ComponentState) then
  begin
    if CanFocus and not Focused then
      SetFocus;
    FDragging := True;
    ApplyPoint(X, Y);
  end;
end;

procedure TDaisyRange.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FDragging then
    ApplyPoint(X, Y);
end;

procedure TDaisyRange.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TDaisyRange.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LPalette: TDaisyPalette;
  LTint, LTrackColor, LTickColor: TAlphaColor;
  LD, LT, LCentre, LRing, LFade, LPos: Single;
  LTrack, LFill, LThumb, LBox: TRectF;
  LFraction: Double;
  I, LLabelFont: Integer;
  LText: TRect;
begin
  if Variant = dvDefault then
    LTint := Theme.BaseContent
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    LTint := LPalette.Fill;
  end;
  LFade := 1;
  if not Enabled then
    LFade := 0.3;
  LD := ThumbSize;
  LT := ScaleValue(DaisyRangeTrack(SizeKind));
  LFraction := DaisyRangeFraction(FValue, FMin, FMax);
  LCentre := ThumbCentre(LFraction);
  LTrackColor := DaisyWithAlpha(Theme.BaseContent, 0.1 * LFade);

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

  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LTrack, LT / 2, LTrackColor);
    if FShowFill and (LFraction > 0) then
      FillRoundRect(LGraphics, LFill, LT / 2, DaisyWithAlpha(LTint, LFade));

    LRing := System.Math.Max(2, LD / 6);
    LThumb.Inflate(-ScaleValue(CRingMargin), -ScaleValue(CRingMargin));
    FillRoundRect(LGraphics, LThumb, LThumb.Width / 2, DaisyWithAlpha(LTint, LFade));
    LBox := LThumb;
    LBox.Inflate(-LRing, -LRing);
    FillRoundRect(LGraphics, LBox, LBox.Width / 2, DaisyWithAlpha(Theme.Base100, LFade));
    if Focused and FRingVisible then
    begin
      LBox := LThumb;
      LBox.Inflate(ScaleValue(3), ScaleValue(3));
      StrokeRoundRect(LGraphics, LBox, LBox.Width / 2,
        DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade), ScaleValue(1), False);
    end;

    if FTickCount >= 2 then
    begin
      LTickColor := DaisyWithAlpha(Theme.BaseContent, 0.7 * LFade);
      for I := 0 to FTickCount - 1 do
      begin
        LPos := ThumbCentre(I / (FTickCount - 1));
        if Vertical then
          LBox := RectF(LD + ScaleValue(CTickGap), LPos - 0.5, LD + ScaleValue(CTickGap + CTickLength),
            LPos + 0.5)
        else
          LBox := RectF(LPos - 0.5, LD + ScaleValue(CTickGap), LPos + 0.5,
            LD + ScaleValue(CTickGap + CTickLength));
        FillRoundRect(LGraphics, LBox, 0, LTickColor);
      end;
    end;
  finally
    LGraphics.Free;
  end;

  if (FTickCount >= 2) and (FTickLabels.Count > 0) then
    for I := 0 to System.Math.Min(FTickCount, FTickLabels.Count) - 1 do
    begin
      LPos := ThumbCentre(I / (FTickCount - 1));
      LLabelFont := CLabelFont;
      if Vertical then
      begin
        LText := Rect(Round(LD) + ScaleValue(CTickGap + CTickLength + CLabelGap),
          Round(LPos) - ScaleValue(10), Width, Round(LPos) + ScaleValue(10));
        DrawText(FTickLabels[I], LText, DaisyWithAlpha(Theme.BaseContent, LFade), LLabelFont, False,
          DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      end
      else
      begin
        LText := Rect(Round(LPos) - ScaleValue(40), Round(LD) + ScaleValue(CTickGap + CTickLength + CLabelGap),
          Round(LPos) + ScaleValue(40), Height);
        DrawText(FTickLabels[I], LText, DaisyWithAlpha(Theme.BaseContent, LFade), LLabelFont, False,
          DT_CENTER or DT_TOP or DT_SINGLELINE);
      end;
    end;
end;

end.
