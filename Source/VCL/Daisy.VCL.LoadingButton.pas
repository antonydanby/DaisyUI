unit Daisy.VCL.LoadingButton;

{
  TDaisyLoadingButton   - button with a loading indicator (spinner, ring, dots...)
  TDaisyAnimationButton - button that plays a timed animation when clicked

  The animation is driven by Daisy.Animation's clock: a background thread
  ticks, the tick is delivered on the main thread and only invalidates the
  control, so painting always happens on the UI thread.
}

interface

uses
  Winapi.Windows, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Daisy.Theme, Daisy.Animation, Daisy.VCL.Control, Daisy.VCL.Button;

type
  TDaisyLoadingButton = class(TDaisyButton)
  strict private
    FLoading: Boolean;
    FLoadingKind: TDaisyLoadingKind;
    FIndicatorPosition: TDaisyIndicatorPosition;
    FLoadingCaption: string;
    procedure SetLoading(const Value: Boolean);
    procedure SetLoadingKind(const Value: TDaisyLoadingKind);
    procedure SetIndicatorPosition(const Value: TDaisyIndicatorPosition);
    procedure SetLoadingCaption(const Value: string);
    procedure AnimationTick(Sender: TObject);
    function DisplayCaption: string;
  protected
    procedure LoadingChanged; virtual;
    procedure Animate(ATime: Double); virtual;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Loading: Boolean read FLoading write SetLoading default False;
    property LoadingKind: TDaisyLoadingKind read FLoadingKind write SetLoadingKind default dlSpinner;
    property IndicatorPosition: TDaisyIndicatorPosition read FIndicatorPosition
      write SetIndicatorPosition default ipLeft;
    // Text shown while loading; empty keeps Caption
    property LoadingCaption: string read FLoadingCaption write SetLoadingCaption;
  end;

  TDaisyAnimationButton = class(TDaisyLoadingButton)
  strict private
    FAnimateOnClick: Boolean;
    FDuration: Integer;
    FStartTime: Double;
    FOnAnimationFinished: TNotifyEvent;
  protected
    procedure LoadingChanged; override;
    procedure Animate(ATime: Double); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;
    // Starts the animation now; it stops by itself after Duration
    procedure StartAnimation;
    procedure StopAnimation;
  published
    property AnimateOnClick: Boolean read FAnimateOnClick write FAnimateOnClick default True;
    // Milliseconds
    property Duration: Integer read FDuration write FDuration default 2000;
    property OnAnimationFinished: TNotifyEvent read FOnAnimationFinished write FOnAnimationFinished;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, System.Math;

{ TDaisyLoadingButton }

constructor TDaisyLoadingButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLoadingKind := dlSpinner;
  FIndicatorPosition := ipLeft;
  Caption := 'Loading';
end;

destructor TDaisyLoadingButton.Destroy;
begin
  if FLoading then
    DaisyAnimationClock.RemoveListener(AnimationTick);
  inherited;
end;

procedure TDaisyLoadingButton.SetLoading(const Value: Boolean);
begin
  if FLoading = Value then
    Exit;
  FLoading := Value;
  if FLoading then
    DaisyAnimationClock.AddListener(AnimationTick)
  else
    DaisyAnimationClock.RemoveListener(AnimationTick);
  LoadingChanged;
  Invalidate;
end;

procedure TDaisyLoadingButton.SetLoadingKind(const Value: TDaisyLoadingKind);
begin
  if FLoadingKind <> Value then
  begin
    FLoadingKind := Value;
    Invalidate;
  end;
end;

procedure TDaisyLoadingButton.SetIndicatorPosition(const Value: TDaisyIndicatorPosition);
begin
  if FIndicatorPosition <> Value then
  begin
    FIndicatorPosition := Value;
    Invalidate;
  end;
end;

procedure TDaisyLoadingButton.SetLoadingCaption(const Value: string);
begin
  if FLoadingCaption <> Value then
  begin
    FLoadingCaption := Value;
    Invalidate;
  end;
end;

procedure TDaisyLoadingButton.LoadingChanged;
begin
end;

procedure TDaisyLoadingButton.Animate(ATime: Double);
begin
end;

procedure TDaisyLoadingButton.AnimationTick(Sender: TObject);
begin
  if not FLoading then
    Exit;
  Animate(DaisyAnimationClock.Time);
  if FLoading and HandleAllocated and Visible then
    Invalidate;
end;

function TDaisyLoadingButton.DisplayCaption: string;
begin
  if FLoading and (FLoadingCaption <> '') then
    Result := FLoadingCaption
  else
    Result := Caption;
end;

procedure TDaisyLoadingButton.Click;
begin
  if FLoading then
    Exit; // a busy button ignores clicks
  inherited Click;
end;

procedure TDaisyLoadingButton.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LRect, LText, LIndicator: TRect;
  LGraphics: TGPGraphics;
  LCaption: string;
  LSize, LGap, LTextWidth, LTotal, LLeft: Integer;
begin
  if not FLoading then
  begin
    inherited DrawContent(AColors, ARect);
    Exit;
  end;

  LRect := BodyRect;
  InflateRect(LRect, -ResolvedContentPadding, 0);
  LCaption := DisplayCaption;
  LSize := ScaleValue(DaisyFontSize(SizeKind) + 6);
  LGap := ScaleValue(8);

  Canvas.Font.Assign(Font);
  Canvas.Font.Height := -ScaleValue(DaisyFontSize(SizeKind));
  LTextWidth := Canvas.TextWidth(LCaption);

  if (FIndicatorPosition = ipReplace) or (LCaption = '') then
  begin
    LTotal := LSize;
    LTextWidth := 0;
  end
  else
    LTotal := LSize + LGap + LTextWidth;
  LTotal := Min(LTotal, LRect.Width);
  LLeft := LRect.Left + (LRect.Width - LTotal) div 2;

  if (FIndicatorPosition = ipRight) and (LTextWidth > 0) then
  begin
    LText := Rect(LLeft, LRect.Top, LLeft + LTextWidth, LRect.Bottom);
    LIndicator := Rect(LText.Right + LGap, 0, 0, 0);
  end
  else
  begin
    LIndicator := Rect(LLeft, 0, 0, 0);
    LText := Rect(LLeft + LSize + LGap, LRect.Top, LRect.Right, LRect.Bottom);
  end;
  LIndicator.Top := LRect.Top + (LRect.Height - LSize) div 2;
  LIndicator.Right := LIndicator.Left + LSize;
  LIndicator.Bottom := LIndicator.Top + LSize;

  LGraphics := NewGraphics;
  try
    DrawPrims(LGraphics, DaisyLoadingPrims(FLoadingKind, DaisyAnimationClock.Time),
      RectF(LIndicator.Left, LIndicator.Top, LIndicator.Right, LIndicator.Bottom), AColors.Text);
  finally
    LGraphics.Free; // flush before GDI text
  end;

  if LTextWidth > 0 then
    DrawText(LCaption, LText, AColors.Text, DaisyFontSize(SizeKind), False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

{ TDaisyAnimationButton }

constructor TDaisyAnimationButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAnimateOnClick := True;
  FDuration := 2000;
  LoadingKind := dlDots;
  Caption := 'Animate';
end;

procedure TDaisyAnimationButton.Click;
var
  LWasIdle: Boolean;
begin
  LWasIdle := not Loading;
  inherited Click;
  if LWasIdle and FAnimateOnClick and not Loading then
    StartAnimation;
end;

procedure TDaisyAnimationButton.StartAnimation;
begin
  FStartTime := DaisyAnimationClock.Time;
  Loading := True;
end;

procedure TDaisyAnimationButton.StopAnimation;
begin
  Loading := False;
end;

procedure TDaisyAnimationButton.LoadingChanged;
begin
  inherited;
  if Loading and (FStartTime = 0) then
    FStartTime := DaisyAnimationClock.Time;
  if not Loading then
  begin
    FStartTime := 0;
    if not (csDesigning in ComponentState) and Assigned(FOnAnimationFinished) then
      FOnAnimationFinished(Self);
  end;
end;

procedure TDaisyAnimationButton.Animate(ATime: Double);
begin
  // At design time the animation just runs so it can be previewed
  if (FDuration > 0) and not (csDesigning in ComponentState) and
     ((ATime - FStartTime) * 1000 >= FDuration) then
    Loading := False;
end;

end.
