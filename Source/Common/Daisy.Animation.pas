unit Daisy.Animation;

{
  Framework neutral animation support shared by VCL and FMX.

  * TDaisyAnimationClock ticks on a background thread but only ever notifies
    its listeners on the main thread (TThread.Queue), so controls can
    repaint safely. A tick is never queued while the previous one is still
    pending, which keeps the UI responsive even when painting is slow.
  * DaisyLoadingPrims turns a loading animation and a point in time into a
    list of simple primitives in a 24 x 24 box. Both frameworks only have to
    know how to draw those primitives.
  Must not reference Vcl.* or FMX.* units.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math, System.SyncObjs,
  System.Diagnostics, System.Generics.Collections;

type
  TDaisyLoadingKind = (dlSpinner, dlRing, dlDots, dlBars, dlBall);

  TDaisyIndicatorPosition = (ipLeft, ipRight, ipReplace);

  TDaisyPrimKind = (pkArc, pkEllipseStroke, pkEllipseFill, pkRoundRectFill);

  TDaisyPrim = record
    Kind: TDaisyPrimKind;
    Bounds: TRectF;       // in a 24 x 24 box
    Alpha: Single;        // 0..1, multiplied with the colour alpha
    StartAngle: Single;   // degrees, pkArc only
    SweepAngle: Single;   // degrees, pkArc only
    StrokeWidth: Single;  // box units, stroked kinds only
  end;

  TDaisyPrims = TArray<TDaisyPrim>;

  TDaisyAnimationThread = class;

  // Roll transition between numbers (the daisyUI countdown): when a number changes
  // the old value slides out while the new one slides in from the side it is
  // heading to (below when counting up, above when counting down).
  TDaisyNumberTransitions = class
  strict private
    FTexts: TArray<string>;
    FValues: TArray<Integer>;
    FOld: TArray<string>;
    FDir: TArray<Integer>;
    FStart: TArray<Double>;
  public
    const Duration = 0.7; // seconds
    // Records the displayed numbers; changes start a transition when AAnimate is set
    procedure Update(const ATexts: TArray<string>; const AValues: TArray<Integer>; AAnimate: Boolean);
    // True while cell AIndex is moving; AProgress is eased 0..1, ADir is 1 (up) or -1 (down)
    function InTransition(AIndex: Integer; out AOld: string; out ADir: Integer;
      out AProgress: Double): Boolean;
    function Busy: Boolean;
  end;

  TDaisyAnimationClock = class
  private
    FListeners: TList<TNotifyEvent>;
    FThread: TDaisyAnimationThread;
    FWatch: TStopwatch;
    FActive: Integer;
    FPending: Integer;
    procedure DoTick;
    procedure ThreadTick;
    function GetTime: Double;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddListener(const AListener: TNotifyEvent);
    procedure RemoveListener(const AListener: TNotifyEvent);
    // Seconds since the clock was created
    property Time: Double read GetTime;
  end;

  TDaisyAnimationThread = class(TThread)
  strict private
    FOwner: TDaisyAnimationClock;
    FWake: TEvent;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
  public
    constructor Create(AOwner: TDaisyAnimationClock);
    destructor Destroy; override;
    procedure Wake;
  end;

function DaisyAnimationClock: TDaisyAnimationClock;

// cubic-bezier(1, 0, 0, 1) like feel: fast start, long settle
function DaisyEaseInOutExpo(T: Double): Double;

function DaisyLoadingPrims(AKind: TDaisyLoadingKind; ATime: Double): TDaisyPrims;

implementation

const
  CFrameMs = 33; // about 30 frames per second

var
  GClock: TDaisyAnimationClock = nil;

function DaisyAnimationClock: TDaisyAnimationClock;
begin
  if GClock = nil then
    GClock := TDaisyAnimationClock.Create;
  Result := GClock;
end;

{ TDaisyAnimationClock }

constructor TDaisyAnimationClock.Create;
begin
  inherited Create;
  FListeners := TList<TNotifyEvent>.Create;
  FWatch := TStopwatch.StartNew;
end;

destructor TDaisyAnimationClock.Destroy;
begin
  if FThread <> nil then
  begin
    FThread.Terminate;
    FThread.WaitFor;
    FThread.Free;
  end;
  TThread.RemoveQueuedEvents(nil, DoTick);
  FListeners.Free;
  inherited;
end;

function TDaisyAnimationClock.GetTime: Double;
begin
  Result := FWatch.Elapsed.TotalSeconds;
end;

procedure TDaisyAnimationClock.AddListener(const AListener: TNotifyEvent);
begin
  if not FListeners.Contains(AListener) then
  begin
    FListeners.Add(AListener);
    TInterlocked.Exchange(FActive, FListeners.Count);
    if FThread = nil then
      FThread := TDaisyAnimationThread.Create(Self);
    FThread.Wake;
  end;
end;

procedure TDaisyAnimationClock.RemoveListener(const AListener: TNotifyEvent);
begin
  FListeners.Remove(AListener);
  TInterlocked.Exchange(FActive, FListeners.Count);
end;

procedure TDaisyAnimationClock.ThreadTick;
begin
  // Called on the animation thread. Only one tick may be waiting at a time.
  if (FActive > 0) and (TInterlocked.CompareExchange(FPending, 1, 0) = 0) then
    TThread.Queue(nil, DoTick);
end;

procedure TDaisyAnimationClock.DoTick;
var
  LListeners: TArray<TNotifyEvent>;
  LListener: TNotifyEvent;
begin
  TInterlocked.Exchange(FPending, 0);
  LListeners := FListeners.ToArray; // listeners may unregister while notified
  for LListener in LListeners do
    if FListeners.Contains(LListener) then
      LListener(Self);
end;

{ TDaisyAnimationThread }

constructor TDaisyAnimationThread.Create(AOwner: TDaisyAnimationClock);
begin
  FOwner := AOwner;
  FWake := TEvent.Create(nil, True, False, '');
  inherited Create(False);
end;

destructor TDaisyAnimationThread.Destroy;
begin
  FWake.Free;
  inherited;
end;

procedure TDaisyAnimationThread.TerminatedSet;
begin
  inherited;
  FWake.SetEvent;
end;

procedure TDaisyAnimationThread.Wake;
begin
  FWake.SetEvent;
end;

procedure TDaisyAnimationThread.Execute;
begin
  while not Terminated do
  begin
    if FOwner.FActive = 0 then
    begin
      FWake.ResetEvent;
      if FOwner.FActive = 0 then
        FWake.WaitFor(INFINITE);
    end
    else
      Sleep(CFrameMs);
    if not Terminated then
      FOwner.ThreadTick;
  end;
end;

{ Number transitions }

function DaisyEaseInOutExpo(T: Double): Double;
begin
  if T <= 0 then
    Exit(0);
  if T >= 1 then
    Exit(1);
  if T < 0.5 then
    Result := Power(2, 20 * T - 10) / 2
  else
    Result := (2 - Power(2, -20 * T + 10)) / 2;
end;

procedure TDaisyNumberTransitions.Update(const ATexts: TArray<string>; const AValues: TArray<Integer>;
  AAnimate: Boolean);
var
  I: Integer;
  LNow: Double;
begin
  LNow := DaisyAnimationClock.Time;
  if Length(ATexts) <> Length(FTexts) then
  begin
    SetLength(FOld, Length(ATexts));
    SetLength(FDir, Length(ATexts));
    SetLength(FStart, Length(ATexts));
    for I := 0 to High(FDir) do
      FDir[I] := 0;
  end
  else
    for I := 0 to High(ATexts) do
      if AAnimate and (ATexts[I] <> FTexts[I]) then
      begin
        FOld[I] := FTexts[I];
        if AValues[I] >= FValues[I] then
          FDir[I] := 1
        else
          FDir[I] := -1;
        FStart[I] := LNow;
      end
      else if not AAnimate then
        FDir[I] := 0;
  FTexts := Copy(ATexts);
  FValues := Copy(AValues);
end;

function TDaisyNumberTransitions.InTransition(AIndex: Integer; out AOld: string; out ADir: Integer;
  out AProgress: Double): Boolean;
var
  LElapsed: Double;
begin
  Result := False;
  if (AIndex < 0) or (AIndex > High(FDir)) or (FDir[AIndex] = 0) then
    Exit;
  LElapsed := (DaisyAnimationClock.Time - FStart[AIndex]) / Duration;
  if LElapsed >= 1 then
  begin
    FDir[AIndex] := 0;
    Exit;
  end;
  AOld := FOld[AIndex];
  ADir := FDir[AIndex];
  AProgress := DaisyEaseInOutExpo(LElapsed);
  Result := True;
end;

function TDaisyNumberTransitions.Busy: Boolean;
var
  I: Integer;
  LOld: string;
  LDir: Integer;
  LProgress: Double;
begin
  Result := False;
  for I := 0 to High(FDir) do
    if InTransition(I, LOld, LDir, LProgress) then
      Result := True;
end;

{ Loading primitives }

function Prim(AKind: TDaisyPrimKind; ALeft, ATop, ARight, ABottom, AAlpha: Single;
  AStroke: Single = 0; AStart: Single = 0; ASweep: Single = 0): TDaisyPrim;
begin
  Result.Kind := AKind;
  Result.Bounds := RectF(ALeft, ATop, ARight, ABottom);
  Result.Alpha := AAlpha;
  Result.StartAngle := AStart;
  Result.SweepAngle := ASweep;
  Result.StrokeWidth := AStroke;
end;

function Circle(ACX, ACY, ARadius, AAlpha: Single; AKind: TDaisyPrimKind;
  AStroke: Single = 0): TDaisyPrim;
begin
  Result := Prim(AKind, ACX - ARadius, ACY - ARadius, ACX + ARadius, ACY + ARadius, AAlpha, AStroke);
end;

function DaisyLoadingPrims(AKind: TDaisyLoadingKind; ATime: Double): TDaisyPrims;
var
  I: Integer;
  LPhase, LLift, LHeight: Double;
begin
  Result := nil;
  case AKind of
    dlSpinner:
      begin
        SetLength(Result, 2);
        Result[0] := Circle(12, 12, 9, 0.2, pkEllipseStroke, 3);
        Result[1] := Prim(pkArc, 3, 3, 21, 21, 1, 3, Frac(ATime / 0.9) * 360, 100);
      end;
    dlRing:
      begin
        SetLength(Result, 2);
        for I := 0 to 1 do
        begin
          LPhase := Frac(ATime / 1.2 + I * 0.5);
          Result[I] := Circle(12, 12, 1 + LPhase * 10.5, 1 - LPhase, pkEllipseStroke, 2);
        end;
      end;
    dlDots:
      begin
        SetLength(Result, 3);
        for I := 0 to 2 do
        begin
          LLift := Abs(Sin(Pi * (ATime / 0.8 - I * 0.15)));
          Result[I] := Circle(4.5 + I * 7.5, 17 - 9 * LLift, 2.6, 1, pkEllipseFill);
        end;
      end;
    dlBars:
      begin
        SetLength(Result, 3);
        for I := 0 to 2 do
        begin
          LHeight := 8 + 10 * (0.5 + 0.5 * Sin(2 * Pi * ATime / 0.9 - I * 0.9));
          Result[I] := Prim(pkRoundRectFill, 3.5 + I * 6.5, 12 - LHeight / 2,
            7 + I * 6.5, 12 + LHeight / 2, 1);
        end;
      end;
    dlBall:
      begin
        SetLength(Result, 2);
        LLift := Abs(Sin(Pi * ATime / 0.8));
        Result[0] := Prim(pkEllipseFill, 12 - (5 - 3 * LLift), 20.4, 12 + (5 - 3 * LLift), 22.8,
          0.08 + 0.17 * (1 - LLift));
        Result[1] := Circle(12, 17 - 12 * LLift, 3.4, 1, pkEllipseFill);
      end;
  end;
end;

initialization

finalization
  FreeAndNil(GClock);

end.
