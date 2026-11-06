unit Daisy.FMX.LoadingButton;

{
  TDaisyFmxLoadingButton   - button with a loading indicator (spinner, ring, dots...)
  TDaisyFmxAnimationButton - button that plays a timed animation when clicked

  The animation clock ticks on a background thread but delivers on the main
  thread, where the listener only repaints.
}

interface

uses
  System.Classes, System.Types, System.SysUtils, FMX.Types, Daisy.Theme, Daisy.Animation,
  Daisy.FMX.Control, Daisy.FMX.Button;

type
  TDaisyFmxLoadingButton = class(TDaisyFmxButton)
  strict private
    FLoading: Boolean;
    FLoadingKind: TDaisyLoadingKind;
    FIndicatorPosition: TDaisyIndicatorPosition;
    FLoadingText: string;
    procedure SetLoading(const Value: Boolean);
    procedure SetLoadingKind(const Value: TDaisyLoadingKind);
    procedure SetIndicatorPosition(const Value: TDaisyIndicatorPosition);
    procedure SetLoadingText(const Value: string);
    procedure AnimationTick(Sender: TObject);
    function DisplayText: string;
  protected
    procedure LoadingChanged; virtual;
    procedure Animate(ATime: Double); virtual;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Loading: Boolean read FLoading write SetLoading default False;
    property LoadingKind: TDaisyLoadingKind read FLoadingKind write SetLoadingKind default dlSpinner;
    property IndicatorPosition: TDaisyIndicatorPosition read FIndicatorPosition
      write SetIndicatorPosition default ipLeft;
    // Text shown while loading; empty keeps Text
    property LoadingText: string read FLoadingText write SetLoadingText;
  end;

  TDaisyFmxAnimationButton = class(TDaisyFmxLoadingButton)
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
  System.Math, System.UITypes, FMX.TextLayout, FMX.Graphics;

{ TDaisyFmxLoadingButton }

constructor TDaisyFmxLoadingButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLoadingKind := dlSpinner;
  FIndicatorPosition := ipLeft;
  Text := 'Loading';
end;

destructor TDaisyFmxLoadingButton.Destroy;
begin
  if FLoading then
    DaisyAnimationClock.RemoveListener(AnimationTick);
  inherited;
end;

procedure TDaisyFmxLoadingButton.SetLoading(const Value: Boolean);
begin
  if FLoading = Value then
    Exit;
  FLoading := Value;
  if FLoading then
    DaisyAnimationClock.AddListener(AnimationTick)
  else
    DaisyAnimationClock.RemoveListener(AnimationTick);
  LoadingChanged;
  Repaint;
end;

procedure TDaisyFmxLoadingButton.SetLoadingKind(const Value: TDaisyLoadingKind);
begin
  if FLoadingKind <> Value then
  begin
    FLoadingKind := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxLoadingButton.SetIndicatorPosition(const Value: TDaisyIndicatorPosition);
begin
  if FIndicatorPosition <> Value then
  begin
    FIndicatorPosition := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxLoadingButton.SetLoadingText(const Value: string);
begin
  if FLoadingText <> Value then
  begin
    FLoadingText := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxLoadingButton.LoadingChanged;
begin
end;

procedure TDaisyFmxLoadingButton.Animate(ATime: Double);
begin
end;

procedure TDaisyFmxLoadingButton.AnimationTick(Sender: TObject);
begin
  if not FLoading then
    Exit;
  Animate(DaisyAnimationClock.Time);
  if FLoading and Visible then
    Repaint;
end;

function TDaisyFmxLoadingButton.DisplayText: string;
begin
  if FLoading and (FLoadingText <> '') then
    Result := FLoadingText
  else
    Result := Text;
end;

procedure TDaisyFmxLoadingButton.Click;
begin
  if FLoading then
    Exit; // a busy button ignores clicks
  inherited Click;
end;

procedure TDaisyFmxLoadingButton.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LRect, LText, LIndicator: TRectF;
  LCaption: string;
  LSize, LGap, LTextWidth, LTotal, LLeft: Single;
  LLayout: TTextLayout;
begin
  if not FLoading then
  begin
    inherited DrawContent(AColors, ARect);
    Exit;
  end;

  LRect := BodyRect;
  LRect.Inflate(-ResolvedContentPadding, 0);
  LCaption := DisplayText;
  LSize := DaisyFontSize(SizeKind) + 6;
  LGap := 8;

  LTextWidth := 0;
  if LCaption <> '' then
  begin
    LLayout := TTextLayoutManager.DefaultTextLayout.Create;
    try
      LLayout.Text := LCaption;
      LLayout.Font.Size := DaisyFontSize(SizeKind);
      LTextWidth := LLayout.TextWidth;
    finally
      LLayout.Free;
    end;
  end;

  if (FIndicatorPosition = ipReplace) or (LCaption = '') then
  begin
    LTotal := LSize;
    LTextWidth := 0;
  end
  else
    LTotal := LSize + LGap + LTextWidth;
  LTotal := Min(LTotal, LRect.Width);
  LLeft := LRect.Left + (LRect.Width - LTotal) / 2;

  if (FIndicatorPosition = ipRight) and (LTextWidth > 0) then
  begin
    LText := RectF(LLeft, LRect.Top, LLeft + LTextWidth, LRect.Bottom);
    LIndicator.Left := LText.Right + LGap;
  end
  else
  begin
    LIndicator.Left := LLeft;
    LText := RectF(LLeft + LSize + LGap, LRect.Top, LRect.Right, LRect.Bottom);
  end;
  LIndicator.Top := LRect.Top + (LRect.Height - LSize) / 2;
  LIndicator.Right := LIndicator.Left + LSize;
  LIndicator.Bottom := LIndicator.Top + LSize;

  DrawPrims(DaisyLoadingPrims(FLoadingKind, DaisyAnimationClock.Time), LIndicator, AColors.Text);
  if LTextWidth > 0 then
    DrawText(LCaption, LText, AColors.Text, DaisyFontSize(SizeKind), False,
      TTextAlign.Leading, TTextAlign.Center, False);
end;

{ TDaisyFmxAnimationButton }

constructor TDaisyFmxAnimationButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAnimateOnClick := True;
  FDuration := 2000;
  LoadingKind := dlDots;
  Text := 'Animate';
end;

procedure TDaisyFmxAnimationButton.Click;
var
  LWasIdle: Boolean;
begin
  LWasIdle := not Loading;
  inherited Click;
  if LWasIdle and FAnimateOnClick and not Loading then
    StartAnimation;
end;

procedure TDaisyFmxAnimationButton.StartAnimation;
begin
  FStartTime := DaisyAnimationClock.Time;
  Loading := True;
end;

procedure TDaisyFmxAnimationButton.StopAnimation;
begin
  Loading := False;
end;

procedure TDaisyFmxAnimationButton.LoadingChanged;
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

procedure TDaisyFmxAnimationButton.Animate(ATime: Double);
begin
  if (FDuration > 0) and not (csDesigning in ComponentState) and
     ((ATime - FStartTime) * 1000 >= FDuration) then
    Loading := False;
end;

end.
