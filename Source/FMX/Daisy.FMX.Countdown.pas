unit Daisy.FMX.Countdown;

{
  TDaisyFmxCountdown - the DaisyUI "countdown": numbers (days, hours, minutes,
  seconds or any list of segments) optionally separated by colons, with labels
  inline or underneath, and optionally in boxes. Set Active to count down.
  Mirrors Daisy.VCL.Countdown so both frameworks share one public API.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math, System.Diagnostics,
  FMX.Types, FMX.Graphics, FMX.Controls, Daisy.Theme, Daisy.Widgets, Daisy.Animation, Daisy.FMX.Control;

type
  TDaisyFmxCountdown = class(TDaisyControl)
  strict private
    type
      TCell = record
        Cell, Number, Caption, Sep: TRectF;
        Text: string;
      end;
    var
    FSegments: TDaisyCountdownSegments;
    FSeparator: string;
    FLabelPlacement: TDaisyCountdownLabels;
    FBoxed: Boolean;
    FDigitCount: Integer;
    FActive: Boolean;
    FAutoFit: Boolean;
    FAnimated: Boolean;
    FShowSeconds: Boolean;
    FTimer: TTimer;
    FStopwatch: TStopwatch;
    FTransitions: TDaisyNumberTransitions;
    FUpdating: Boolean;
    FStartTotal: Int64;
    FStartTime: Double;
    FOnFinished: TNotifyEvent;
    procedure SetSegments(const Value: TDaisyCountdownSegments);
    procedure SetShowSeconds(const Value: Boolean);
    function VisibleCount: Integer;
    procedure MinuteTick(Sender: TObject);
    procedure Finish;
    procedure SetSeparator(const Value: string);
    procedure SetLabelPlacement(const Value: TDaisyCountdownLabels);
    procedure SetBoxed(const Value: Boolean);
    procedure SetDigitCount(const Value: Integer);
    procedure SetActive(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure SegmentsChanged(Sender: TObject);
    procedure SyncTransitions;
    procedure TransitionTick(Sender: TObject);
    procedure SetAnimated(const Value: Boolean);
    procedure DrawNumber(AIndex: Integer; const ACell: TCell; AColor: TAlphaColor);
    procedure Tick(Sender: TObject);
    procedure StartTicking;
    procedure StopTicking;
    function DigitSize: Integer;
    function LabelSize: Integer;
    function BuildLayout(out ASize: TSizeF): TArray<TCell>;
    procedure UpdateSize;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // Numbers shown left to right; the last is seconds, then minutes, hours and days
    property Segments: TDaisyCountdownSegments read FSegments write SetSegments;
    // Drawn between the numbers, for example ":"
    property Separator: string read FSeparator write SetSeparator;
    property LabelPlacement: TDaisyCountdownLabels read FLabelPlacement write SetLabelPlacement default clNone;
    // Each number in its own rounded box
    property Boxed: Boolean read FBoxed write SetBoxed default False;
    // Numbers are zero padded to this many digits
    property DigitCount: Integer read FDigitCount write SetDigitCount default 2;
    // Starts counting down from the current segment values (at run time only)
    property Active: Boolean read FActive write SetActive default False;
    // The size follows the content
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    // Numbers roll to their new value instead of just changing
    property Animated: Boolean read FAnimated write SetAnimated default True;
    // False hides the last (seconds) segment; a running countdown then wakes only once a minute
    property ShowSeconds: Boolean read FShowSeconds write SetShowSeconds default True;
    property OnFinished: TNotifyEvent read FOnFinished write FOnFinished;
  end;

implementation

{ TDaisyFmxCountdown }

constructor TDaisyFmxCountdown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDigitCount := 2;
  FAutoFit := True;
  FAnimated := True;
  FShowSeconds := True;
  FTransitions := TDaisyNumberTransitions.Create;
  FSegments := TDaisyCountdownSegments.Create(Self);
  FSegments.OnChange := SegmentsChanged;
  FSegments.Add.Value := 59;
  SetBounds(Position.X, Position.Y, 40, 40);
  UpdateSize;
end;

destructor TDaisyFmxCountdown.Destroy;
begin
  StopTicking;
  FTimer.Free;
  DaisyAnimationClock.RemoveListener(TransitionTick);
  FSegments.Free;
  FTransitions.Free;
  inherited Destroy;
end;

procedure TDaisyFmxCountdown.SetSegments(const Value: TDaisyCountdownSegments);
begin
  FSegments.Assign(Value);
end;

function TDaisyFmxCountdown.VisibleCount: Integer;
begin
  Result := FSegments.Count;
  if (not FShowSeconds) and (Result > 1) then
    Dec(Result);
end;

procedure TDaisyFmxCountdown.SetShowSeconds(const Value: Boolean);
var
  LWasActive: Boolean;
begin
  if FShowSeconds = Value then
    Exit;
  LWasActive := FActive and not (csDesigning in ComponentState) and not (csLoading in ComponentState);
  if LWasActive then
    StopTicking;
  FShowSeconds := Value;
  SyncTransitions;
  UpdateSize;
  Repaint;
  if LWasActive then
    StartTicking;
end;

procedure TDaisyFmxCountdown.SetSeparator(const Value: string);
begin
  if FSeparator <> Value then
  begin
    FSeparator := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxCountdown.SetLabelPlacement(const Value: TDaisyCountdownLabels);
begin
  if FLabelPlacement <> Value then
  begin
    FLabelPlacement := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxCountdown.SetBoxed(const Value: Boolean);
begin
  if FBoxed <> Value then
  begin
    FBoxed := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxCountdown.SetDigitCount(const Value: Integer);
var
  LWasAnimated: Boolean;
begin
  if (FDigitCount <> Value) and (Value >= 1) and (Value <= 6) then
  begin
    FDigitCount := Value;
    LWasAnimated := FAnimated;
    FAnimated := False; // a different padding is not a new value
    SyncTransitions;
    FAnimated := LWasAnimated;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxCountdown.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyFmxCountdown.SegmentsChanged(Sender: TObject);
begin
  SyncTransitions;
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxCountdown.SyncTransitions;
var
  LTexts: TArray<string>;
  LValues: TArray<Integer>;
  I: Integer;
begin
  SetLength(LTexts, VisibleCount);
  SetLength(LValues, VisibleCount);
  for I := 0 to VisibleCount - 1 do
  begin
    LValues[I] := Max(0, FSegments[I].Value);
    LTexts[I] := IntToStr(LValues[I]).PadLeft(FDigitCount, '0');
  end;
  FTransitions.Update(LTexts, LValues,
    FAnimated and not (csDesigning in ComponentState) and not (csLoading in ComponentState));
  if FTransitions.Busy then
    DaisyAnimationClock.AddListener(TransitionTick);
end;

procedure TDaisyFmxCountdown.TransitionTick(Sender: TObject);
begin
  Repaint;
  if not FTransitions.Busy then
  begin
    DaisyAnimationClock.RemoveListener(TransitionTick);
    Repaint;
  end;
end;

procedure TDaisyFmxCountdown.SetAnimated(const Value: Boolean);
begin
  FAnimated := Value;
end;

procedure TDaisyFmxCountdown.DrawNumber(AIndex: Integer; const ACell: TCell; AColor: TAlphaColor);
var
  LOld: string;
  LDir, I: Integer;
  LProgress: Double;
  LShift, LLeft, LLeft2: Single;
  LRect, LColumn, LVisual: TRectF;
  LState: TCanvasSaveState;
begin
  if not FTransitions.InTransition(AIndex, LOld, LDir, LProgress) then
  begin
    DrawText(ACell.Text, ACell.Number, AColor, DigitSize, False, TTextAlign.Center, TTextAlign.Center, False);
    Exit;
  end;
  // the old number leaves one way while the new one enters from the other, clipped to the number row
  LShift := LProgress * ACell.Number.Height;
  LState := Canvas.SaveState;
  try
    Canvas.IntersectClipRect(ACell.Number);
    if Length(LOld) <> Length(ACell.Text) then
    begin
      LRect := ACell.Number;
      LRect.Offset(0, -LDir * LShift);
      DrawText(LOld, LRect, AColor, DigitSize, False, TTextAlign.Center, TTextAlign.Center, False);
      LRect := ACell.Number;
      LRect.Offset(0, LDir * (ACell.Number.Height - LShift));
      DrawText(ACell.Text, LRect, AColor, DigitSize, False, TTextAlign.Center, TTextAlign.Center, False);
      Exit;
    end;
    // only the digits that changed scroll; the others stay in place
    // digits keep their left-to-right order in RTL: lay the columns out on the mirrored
    // (visual) row and mirror each back, as DrawText mirrors again
    LVisual := ACell.Number;
    if IsRTL then
    begin
      LVisual.Left := Width - ACell.Number.Right;
      LVisual.Right := Width - ACell.Number.Left;
    end;
    LLeft := LVisual.Left + (LVisual.Width - MeasureTextWidth(ACell.Text, DigitSize, False)) / 2;
    for I := 1 to Length(ACell.Text) do
    begin
      LColumn := LVisual;
      LColumn.Left := LLeft + MeasureTextWidth(Copy(ACell.Text, 1, I - 1), DigitSize, False);
      LColumn.Right := LLeft + MeasureTextWidth(Copy(ACell.Text, 1, I), DigitSize, False);
      if IsRTL then
      begin
        LLeft2 := Width - LColumn.Right;
        LColumn.Right := Width - LColumn.Left;
        LColumn.Left := LLeft2;
      end;
      if LOld[I] = ACell.Text[I] then
      begin
        DrawText(ACell.Text[I], LColumn, AColor, DigitSize, False, TTextAlign.Center, TTextAlign.Center, False);
        Continue;
      end;
      LRect := LColumn;
      LRect.Offset(0, -LDir * LShift);
      DrawText(LOld[I], LRect, AColor, DigitSize, False, TTextAlign.Center, TTextAlign.Center, False);
      LRect := LColumn;
      LRect.Offset(0, LDir * (ACell.Number.Height - LShift));
      DrawText(ACell.Text[I], LRect, AColor, DigitSize, False, TTextAlign.Center, TTextAlign.Center, False);
    end;
  finally
    Canvas.RestoreState(LState);
  end;
end;

procedure TDaisyFmxCountdown.SetActive(const Value: Boolean);
begin
  if FActive = Value then
    Exit;
  FActive := Value;
  if csDesigning in ComponentState then
    Exit;
  if FActive and not (csLoading in ComponentState) then
    StartTicking
  else if not FActive then
    StopTicking;
end;

procedure TDaisyFmxCountdown.StartTicking;
begin
  FStartTotal := FSegments.TotalSeconds;
  if FShowSeconds then
  begin
    FStartTime := DaisyAnimationClock.Time;
    DaisyAnimationClock.AddListener(Tick);
  end
  else
  begin
    if FTimer = nil then
    begin
      FTimer := TTimer.Create(nil);
      FTimer.Enabled := False;
      FTimer.OnTimer := MinuteTick;
    end;
    FStopwatch := TStopwatch.StartNew;
    MinuteTick(nil);
  end;
end;

procedure TDaisyFmxCountdown.StopTicking;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  if FTimer <> nil then
    FTimer.Enabled := False;
end;

procedure TDaisyFmxCountdown.Finish;
begin
  FActive := False;
  StopTicking;
  if Assigned(FOnFinished) then
    FOnFinished(Self);
end;

// Wakes only when the displayed minute changes (or the countdown ends)
procedure TDaisyFmxCountdown.MinuteTick(Sender: TObject);
var
  LElapsed: Double;
  LRemaining, LNext: Int64;
begin
  FTimer.Enabled := False;
  LElapsed := FStopwatch.Elapsed.TotalSeconds;
  LRemaining := Max(0, FStartTotal - Trunc(LElapsed));
  if LRemaining <> FSegments.TotalSeconds then
    FSegments.TotalSeconds := LRemaining;
  if LRemaining = 0 then
  begin
    Finish;
    Exit;
  end;
  LNext := Max(0, (LRemaining div 60) * 60 - 1);
  FTimer.Interval := Max(1, Ceil((FStartTotal - LNext - LElapsed) * 1000) + 5);
  FTimer.Enabled := True;
end;

procedure TDaisyFmxCountdown.Tick(Sender: TObject);
var
  LRemaining: Int64;
begin
  LRemaining := Max(0, FStartTotal - Trunc(DaisyAnimationClock.Time - FStartTime));
  if LRemaining <> FSegments.TotalSeconds then
    FSegments.TotalSeconds := LRemaining;
  if LRemaining = 0 then
    Finish;
end;

procedure TDaisyFmxCountdown.Loaded;
begin
  inherited;
  UpdateSize;
  if FActive and not (csDesigning in ComponentState) then
    StartTicking;
end;

procedure TDaisyFmxCountdown.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

function TDaisyFmxCountdown.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxCountdown.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxCountdown.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

function TDaisyFmxCountdown.DigitSize: Integer;
const
  C: array[TDaisySize] of Integer = (16, 24, 36, 48, 60);
begin
  Result := C[SizeKind];
end;

function TDaisyFmxCountdown.LabelSize: Integer;
begin
  if FBoxed then
    Result := 12
  else if DigitSize >= 48 then
    Result := 16
  else
    Result := 14;
end;

function TDaisyFmxCountdown.BuildLayout(out ASize: TSizeF): TArray<TCell>;
var
  I: Integer;
  LX, LNumW, LNumH, LLabW, LLabH, LGap, LSepW, LCellW, LCellH, LPad: Single;
  LCell: TCell;
begin
  SetLength(Result, VisibleCount);
  ASize := TSizeF.Create(0, 0);
  if VisibleCount = 0 then
    Exit;
  LNumW := MeasureTextWidth(StringOfChar('0', FDigitCount), DigitSize, False) + 2;
  LNumH := MeasureTextHeight('0', 1000, DigitSize, False);
  LLabH := MeasureTextHeight('0', 1000, LabelSize, False);
  LGap := 20;
  LSepW := 0;
  if FSeparator <> '' then
  begin
    LSepW := MeasureTextWidth(FSeparator, DigitSize, False) + 4;
    LGap := 0;
  end;
  if FBoxed then
    LPad := 8
  else
    LPad := 0;
  LX := 0;
  for I := 0 to VisibleCount - 1 do
  begin
    LCell := Default(TCell);
    LCell.Text := IntToStr(Max(0, FSegments[I].Value)).PadLeft(FDigitCount, '0');
    LLabW := 0;
    if FSegments[I].Caption <> '' then
      LLabW := MeasureTextWidth(FSegments[I].Caption, LabelSize, False) + 2;
    if (FLabelPlacement = clAfter) and not FBoxed then
    begin
      LCellW := LNumW + IfThen(LLabW > 0, 4 + LLabW, 0.0);
      LCellH := LNumH;
      LCell.Cell := RectF(LX, 0, LX + LCellW, LCellH);
      LCell.Number := RectF(LX, 0, LX + LNumW, LNumH);
      LCell.Caption := RectF(LX + LNumW + 4, 0, LX + LCellW, LNumH);
    end
    else if FBoxed then
    begin
      LCellW := Max(64, Max(LNumW, LLabW) + 2 * LPad);
      LCellH := LNumH + LLabH + 2 * LPad;
      LCell.Cell := RectF(LX, 0, LX + LCellW, LCellH);
      LCell.Number := RectF(LX, LPad, LX + LCellW, LPad + LNumH);
      LCell.Caption := RectF(LX, LPad + LNumH, LX + LCellW, LPad + LNumH + LLabH);
    end
    else
    begin
      LCellW := Max(LNumW, LLabW);
      LCellH := LNumH;
      if FLabelPlacement = clBelow then
        LCellH := LNumH + LLabH;
      LCell.Cell := RectF(LX, 0, LX + LCellW, LCellH);
      LCell.Number := RectF(LX, 0, LX + LCellW, LNumH);
      LCell.Caption := RectF(LX, LNumH, LX + LCellW, LNumH + LLabH);
    end;
    LX := LX + LCellW;
    if I < VisibleCount - 1 then
    begin
      if LSepW > 0 then
      begin
        LCell.Sep := RectF(LX, LPad, LX + LSepW, LPad + LNumH);
        LX := LX + LSepW;
      end
      else
        LX := LX + LGap;
    end;
    ASize.cx := LX;
    ASize.cy := Max(ASize.cy, LCellH);
    Result[I] := LCell;
  end;
  if FBoxed then
    for I := 0 to High(Result) do
      Result[I].Cell.Bottom := ASize.cy;
end;

procedure TDaisyFmxCountdown.UpdateSize;
var
  LSize: TSizeF;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  BuildLayout(LSize);
  if (LSize.cx <= 0) or (SameValue(LSize.cx, Width) and SameValue(LSize.cy, Height)) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LSize.cx, LSize.cy);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxCountdown.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LCells: TArray<TCell>;
  LSize: TSizeF;
  LText: TAlphaColor;
  LCell: TCell;
  LRadius: Single;
  I: Integer;
begin
  LCells := BuildLayout(LSize);
  if FBoxed then
  begin
    if Variant = dvDefault then
    begin
      Canvas.Fill.Color := Theme.Neutral;
      LText := Theme.NeutralContent;
    end
    else
    begin
      Canvas.Fill.Color := DaisyVariantPalette(Theme, Variant).Fill;
      LText := DaisyVariantPalette(Theme, Variant).Content;
    end;
    Canvas.Fill.Kind := TBrushKind.Solid;
    LRadius := ResolvedCornerRadius;
    for LCell in LCells do
      Canvas.FillRect(LCell.Cell, LRadius, LRadius, AllCorners, AbsoluteOpacity);
  end
  else if Variant = dvDefault then
    LText := Theme.BaseContent
  else
    LText := DaisyVariantPalette(Theme, Variant).Fill;
  if not Enabled then
    LText := DaisyWithAlpha(LText, 0.5);

  for I := 0 to High(LCells) do
  begin
    LCell := LCells[I];
    DrawNumber(I, LCell, LText);
    if FSegments[I].Caption <> '' then
    begin
      if FLabelPlacement = clAfter then
        DrawText(FSegments[I].Caption, LCell.Caption, LText, LabelSize, False, TTextAlign.Leading,
          TTextAlign.Center, False)
      else if (FLabelPlacement = clBelow) or FBoxed then
        DrawText(FSegments[I].Caption, LCell.Caption, LText, LabelSize, False, TTextAlign.Center,
          TTextAlign.Center, False);
    end;
    if (FSeparator <> '') and (LCell.Sep.Width > 0) then
      DrawText(FSeparator, LCell.Sep, Theme.BaseContent, DigitSize, False, TTextAlign.Center,
        TTextAlign.Center, False);
  end;
end;

end.
