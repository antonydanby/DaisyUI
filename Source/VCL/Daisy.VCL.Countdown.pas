unit Daisy.VCL.Countdown;

{
  TDaisyCountdown - the DaisyUI "countdown": numbers (days, hours, minutes, seconds
  or any list of segments) optionally separated by colons, with labels inline or
  underneath, and optionally in boxes. Set Active to make it count down; the
  numbers are the segments, the last one being seconds.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls, System.Diagnostics, Daisy.Theme, Daisy.Widgets, Daisy.Animation, Daisy.VCL.Control;

type
  TDaisyCountdown = class(TDaisyControl)
  strict private
    type
      TCell = record
        Cell, Number, Caption, Sep: TRect;
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
    function BuildLayout(out ASize: TSize): TArray<TCell>;
    procedure UpdateSize;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

{ TDaisyCountdown }

constructor TDaisyCountdown.Create(AOwner: TComponent);
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
  SetBounds(Left, Top, 40, 40);
  UpdateSize;
end;

destructor TDaisyCountdown.Destroy;
begin
  StopTicking;
  FTimer.Free;
  DaisyAnimationClock.RemoveListener(TransitionTick);
  FSegments.Free;
  FTransitions.Free;
  inherited Destroy;
end;

procedure TDaisyCountdown.SetSegments(const Value: TDaisyCountdownSegments);
begin
  FSegments.Assign(Value);
end;

function TDaisyCountdown.VisibleCount: Integer;
begin
  Result := FSegments.Count;
  if (not FShowSeconds) and (Result > 1) then
    Dec(Result);
end;

procedure TDaisyCountdown.SetShowSeconds(const Value: Boolean);
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
  Invalidate;
  if LWasActive then
    StartTicking;
end;

procedure TDaisyCountdown.SetSeparator(const Value: string);
begin
  if FSeparator <> Value then
  begin
    FSeparator := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyCountdown.SetLabelPlacement(const Value: TDaisyCountdownLabels);
begin
  if FLabelPlacement <> Value then
  begin
    FLabelPlacement := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyCountdown.SetBoxed(const Value: Boolean);
begin
  if FBoxed <> Value then
  begin
    FBoxed := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyCountdown.SetDigitCount(const Value: Integer);
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
    Invalidate;
  end;
end;

procedure TDaisyCountdown.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyCountdown.SegmentsChanged(Sender: TObject);
begin
  SyncTransitions;
  UpdateSize;
  Invalidate;
end;

procedure TDaisyCountdown.SyncTransitions;
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
    FAnimated and HandleAllocated and not (csDesigning in ComponentState) and not (csLoading in ComponentState));
  if FTransitions.Busy then
    DaisyAnimationClock.AddListener(TransitionTick);
end;

procedure TDaisyCountdown.TransitionTick(Sender: TObject);
begin
  Invalidate;
  if not FTransitions.Busy then
  begin
    DaisyAnimationClock.RemoveListener(TransitionTick);
    Invalidate;
  end;
end;

procedure TDaisyCountdown.SetAnimated(const Value: Boolean);
begin
  FAnimated := Value;
end;

procedure TDaisyCountdown.SetActive(const Value: Boolean);
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

procedure TDaisyCountdown.StartTicking;
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

procedure TDaisyCountdown.StopTicking;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  if FTimer <> nil then
    FTimer.Enabled := False;
end;

procedure TDaisyCountdown.Finish;
begin
  FActive := False;
  StopTicking;
  if Assigned(FOnFinished) then
    FOnFinished(Self);
end;

// Wakes only when the displayed minute changes (or the countdown ends)
procedure TDaisyCountdown.MinuteTick(Sender: TObject);
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

procedure TDaisyCountdown.Tick(Sender: TObject);
var
  LRemaining: Int64;
begin
  LRemaining := Max(0, FStartTotal - Trunc(DaisyAnimationClock.Time - FStartTime));
  if LRemaining <> FSegments.TotalSeconds then
    FSegments.TotalSeconds := LRemaining;
  if LRemaining = 0 then
    Finish;
end;

procedure TDaisyCountdown.Loaded;
begin
  inherited;
  UpdateSize;
  if FActive and not (csDesigning in ComponentState) then
    StartTicking;
end;

procedure TDaisyCountdown.SizeChanged;
begin
  UpdateSize;
  Invalidate;
end;

procedure TDaisyCountdown.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
end;

function TDaisyCountdown.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyCountdown.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyCountdown.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

function TDaisyCountdown.DigitSize: Integer;
const
  C: array[TDaisySize] of Integer = (16, 24, 36, 48, 60);
begin
  Result := C[SizeKind];
end;

function TDaisyCountdown.LabelSize: Integer;
begin
  if FBoxed then
    Result := 12
  else if DigitSize >= 48 then
    Result := 16
  else
    Result := 14;
end;

function TDaisyCountdown.BuildLayout(out ASize: TSize): TArray<TCell>;
var
  I, LX, LNumW, LNumH, LLabW, LLabH, LGap, LSepW, LCellW, LCellH, LPad, LInner: Integer;
  LCell: TCell;
  LZeros: string;
begin
  SetLength(Result, VisibleCount);
  ASize := TSize.Create(0, 0);
  if VisibleCount = 0 then
    Exit;
  LZeros := StringOfChar('0', FDigitCount);
  LNumW := MeasureTextWidth(LZeros, DigitSize, False) + ScaleValue(2);
  LNumH := MeasureTextHeight('0', 1000, DigitSize, False);
  LLabH := MeasureTextHeight('0', 1000, LabelSize, False);
  LGap := ScaleValue(20);
  LSepW := 0;
  if FSeparator <> '' then
  begin
    LSepW := MeasureTextWidth(FSeparator, DigitSize, False) + ScaleValue(4);
    LGap := 0;
  end;
  LPad := IfThen(FBoxed, ScaleValue(8), 0);
  LX := 0;
  for I := 0 to VisibleCount - 1 do
  begin
    LCell := Default(TCell);
    LCell.Text := IntToStr(Max(0, FSegments[I].Value)).PadLeft(FDigitCount, '0');
    LLabW := MeasureTextWidth(FSegments[I].Caption, LabelSize, False) + ScaleValue(2);
    if FSegments[I].Caption = '' then
      LLabW := 0;
    if (FLabelPlacement = clAfter) and not FBoxed then
    begin
      LInner := LNumW + IfThen(LLabW > 0, ScaleValue(4) + LLabW);
      LCellW := LInner;
      LCellH := LNumH;
      LCell.Cell := Rect(LX, 0, LX + LCellW, LCellH);
      LCell.Number := Rect(LX, 0, LX + LNumW, LNumH);
      LCell.Caption := Rect(LX + LNumW + ScaleValue(4), 0, LX + LCellW, LNumH);
    end
    else
    begin
      LInner := Max(LNumW, LLabW);
      if FBoxed then
      begin
        LCellW := Max(ScaleValue(64), LInner + 2 * LPad);
        LCellH := LNumH + LLabH + 2 * LPad;
        LCell.Cell := Rect(LX, 0, LX + LCellW, LCellH);
        LCell.Number := Rect(LX, LPad, LX + LCellW, LPad + LNumH);
        LCell.Caption := Rect(LX, LPad + LNumH, LX + LCellW, LPad + LNumH + LLabH);
      end
      else
      begin
        LCellW := LInner;
        if FLabelPlacement = clBelow then
          LCellH := LNumH + LLabH
        else
          LCellH := LNumH;
        LCell.Cell := Rect(LX, 0, LX + LCellW, LCellH);
        LCell.Number := Rect(LX, 0, LX + LCellW, LNumH);
        LCell.Caption := Rect(LX, LNumH, LX + LCellW, LNumH + LLabH);
      end;
    end;
    Inc(LX, LCellW);
    if I < VisibleCount - 1 then
    begin
      if LSepW > 0 then
      begin
        LCell.Sep := Rect(LX, 0, LX + LSepW, LNumH + LPad);
        if FBoxed then
          LCell.Sep.Top := LPad; // colon sits against the number row of the box
        Inc(LX, LSepW);
      end
      else
        Inc(LX, LGap);
    end;
    ASize.cx := LX;
    ASize.cy := Max(ASize.cy, LCellH);
    Result[I] := LCell;
  end;
  // all boxes share the tallest height
  for I := 0 to High(Result) do
    if FBoxed then
      Result[I].Cell.Bottom := ASize.cy;
end;

procedure TDaisyCountdown.UpdateSize;
var
  LSize: TSize;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  BuildLayout(LSize);
  if (LSize.cx <= 0) or ((LSize.cx = Width) and (LSize.cy = Height)) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, LSize.cx, LSize.cy);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyCountdown.DrawNumber(AIndex: Integer; const ACell: TCell; AColor: TAlphaColor);
const
  Flags = DT_CENTER or DT_VCENTER or DT_SINGLELINE;
var
  LOld: string;
  LDir, LShift, LSaved, LLeft, I: Integer;
  LProgress: Double;
  LRect, LColumn, LVisual: TRect;
begin
  if not FTransitions.InTransition(AIndex, LOld, LDir, LProgress) then
  begin
    DrawText(ACell.Text, ACell.Number, AColor, DigitSize, False, Flags);
    Exit;
  end;
  // the old number leaves one way while the new one enters from the other, clipped to the number row
  LShift := Round(LProgress * ACell.Number.Height);
  LSaved := SaveDC(Canvas.Handle);
  try
    LRect := MirrorRect(ACell.Number);
    IntersectClipRect(Canvas.Handle, LRect.Left, LRect.Top, LRect.Right, LRect.Bottom);
    if Length(LOld) <> Length(ACell.Text) then
    begin
      LRect := ACell.Number;
      OffsetRect(LRect, 0, -LDir * LShift);
      DrawText(LOld, LRect, AColor, DigitSize, False, Flags);
      LRect := ACell.Number;
      OffsetRect(LRect, 0, LDir * (ACell.Number.Height - LShift));
      DrawText(ACell.Text, LRect, AColor, DigitSize, False, Flags);
      Exit;
    end;
    // only the digits that changed scroll; the others stay in place
    // digits keep their left-to-right order in RTL, so lay the columns out on the mirrored
    // (visual) row and mirror each back, as DrawText mirrors again
    LVisual := MirrorRect(ACell.Number);
    LLeft := LVisual.Left + (LVisual.Width - MeasureTextWidth(ACell.Text, DigitSize, False)) div 2;
    for I := 1 to Length(ACell.Text) do
    begin
      LColumn := LVisual;
      LColumn.Left := LLeft + MeasureTextWidth(Copy(ACell.Text, 1, I - 1), DigitSize, False);
      LColumn.Right := LLeft + MeasureTextWidth(Copy(ACell.Text, 1, I), DigitSize, False);
      LColumn := MirrorRect(LColumn);
      if LOld[I] = ACell.Text[I] then
      begin
        DrawText(ACell.Text[I], LColumn, AColor, DigitSize, False, Flags);
        Continue;
      end;
      LRect := LColumn;
      OffsetRect(LRect, 0, -LDir * LShift);
      DrawText(LOld[I], LRect, AColor, DigitSize, False, Flags);
      LRect := LColumn;
      OffsetRect(LRect, 0, LDir * (ACell.Number.Height - LShift));
      DrawText(ACell.Text[I], LRect, AColor, DigitSize, False, Flags);
    end;
  finally
    RestoreDC(Canvas.Handle, LSaved);
  end;
end;

procedure TDaisyCountdown.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LCells: TArray<TCell>;
  LSize: TSize;
  LGraphics: TGPGraphics;
  LPalette: TDaisyPalette;
  LBox, LText: TAlphaColor;
  LCell: TCell;
  I: Integer;
  LRect: TRect;
begin
  LCells := BuildLayout(LSize);
  if FBoxed then
  begin
    if Variant = dvDefault then
      LPalette.Fill := Theme.Neutral
    else
      LPalette.Fill := DaisyVariantPalette(Theme, Variant).Fill;
    if Variant = dvDefault then
      LPalette.Content := Theme.NeutralContent
    else
      LPalette.Content := DaisyVariantPalette(Theme, Variant).Content;
    LBox := LPalette.Fill;
    LText := LPalette.Content;
    LGraphics := NewGraphics;
    try
      for LCell in LCells do
        FillRoundRect(LGraphics, RectF(LCell.Cell.Left, LCell.Cell.Top, LCell.Cell.Right,
          LCell.Cell.Bottom), ResolvedCornerRadius, LBox);
    finally
      LGraphics.Free;
    end;
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
      LRect := LCell.Caption;
      if FLabelPlacement = clAfter then
        DrawText(FSegments[I].Caption, LRect, LText, LabelSize, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE)
      else if (FLabelPlacement = clBelow) or FBoxed then
        DrawText(FSegments[I].Caption, LRect, LText, LabelSize, False, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    end;
    if (FSeparator <> '') and (not LCell.Sep.IsEmpty) then
      DrawText(FSeparator, LCell.Sep, Theme.BaseContent, DigitSize, False,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
end;

end.
