unit Daisy.FMX.Progress;

{
  TDaisyFmxProgress - the DaisyUI "progress" bar: a rounded track with a filled part.
  Variant sets the colour, SizeKind the thickness. Indeterminate shows a sliding bar.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Animation,
  Daisy.FMX.Control;

type
  TDaisyFmxProgress = class(TDaisyControl)
  strict private
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FIndeterminate: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FTicking: Boolean;
    procedure SetMin(const AValue: Double);
    procedure SetMax(const AValue: Double);
    procedure SetValue(const AValue: Double);
    procedure SetIndeterminate(const AValue: Boolean);
    procedure SetAutoFit(const AValue: Boolean);
    procedure Tick(Sender: TObject);
    procedure UpdateTicking;
    function BarHeight: Single;
    procedure UpdateSize;
    function FillColor: TAlphaColor;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Min: Double read FMin write SetMin;
    property Max: Double read FMax write SetMax;
    property Value: Double read FValue write SetValue;
    // Shows a bar sliding back and forth instead of the value
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    // The height follows SizeKind; when off the control keeps its own height
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
  end;

implementation

const
  CBarHeights: array[TDaisySize] of Integer = (2, 4, 8, 12, 16);

{ TDaisyFmxProgress }

constructor TDaisyFmxProgress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin := 0;
  FMax := 100;
  FAutoFit := True;
  HitTest := False;
  SetBounds(Position.X, Position.Y, 224, 8);
  UpdateSize;
end;

destructor TDaisyFmxProgress.Destroy;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  inherited Destroy;
end;

procedure TDaisyFmxProgress.SetMin(const AValue: Double);
begin
  if FMin <> AValue then
  begin
    FMin := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxProgress.SetMax(const AValue: Double);
begin
  if FMax <> AValue then
  begin
    FMax := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxProgress.SetValue(const AValue: Double);
begin
  if FValue <> AValue then
  begin
    FValue := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxProgress.SetIndeterminate(const AValue: Boolean);
begin
  if FIndeterminate <> AValue then
  begin
    FIndeterminate := AValue;
    UpdateTicking;
    Repaint;
  end;
end;

procedure TDaisyFmxProgress.SetAutoFit(const AValue: Boolean);
begin
  if FAutoFit <> AValue then
  begin
    FAutoFit := AValue;
    UpdateSize;
  end;
end;

procedure TDaisyFmxProgress.UpdateTicking;
var
  LWant: Boolean;
begin
  LWant := FIndeterminate and not (csDesigning in ComponentState)
    and not (csLoading in ComponentState);
  if LWant = FTicking then
    Exit;
  FTicking := LWant;
  if LWant then
    DaisyAnimationClock.AddListener(Tick)
  else
    DaisyAnimationClock.RemoveListener(Tick);
end;

procedure TDaisyFmxProgress.Tick(Sender: TObject);
begin
  if Visible then
    Repaint;
end;

function TDaisyFmxProgress.BarHeight: Single;
begin
  Result := CBarHeights[SizeKind];
end;

procedure TDaisyFmxProgress.UpdateSize;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  if SameValue(Height, BarHeight) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, Width, BarHeight);
  finally
    FUpdating := False;
  end;
end;

function TDaisyFmxProgress.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxProgress.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxProgress.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxProgress.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

function TDaisyFmxProgress.FillColor: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
  if not Enabled then
    Result := DaisyWithAlpha(Result, 0.4);
end;

procedure TDaisyFmxProgress.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxProgress.Loaded;
begin
  inherited;
  UpdateSize;
  UpdateTicking;
end;

procedure TDaisyFmxProgress.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LTrack, LBar: TRectF;
  LFrac, LSeg, LPhase: Single;
  LState: TCanvasSaveState;
begin
  LTrack := RectF(0, 0, Width, Height);
  FillRound(LTrack, LTrack.Height / 2, DaisyWithAlpha(Theme.BaseContent, 0.2));
  if FIndeterminate then
  begin
    // The bar slides across the track and is clipped by it, like the CSS version
    LSeg := LTrack.Width * 0.4;
    LPhase := Frac(DaisyAnimationClock.Time / 1.5);
    LPhase := LPhase * LPhase * (3 - 2 * LPhase);
    LBar := RectF(-LSeg + LPhase * (LTrack.Width + LSeg), 0,
      LPhase * (LTrack.Width + LSeg), LTrack.Height);
    LState := Canvas.SaveState;
    try
      Canvas.IntersectClipRect(LTrack);
      FillRound(LBar, LTrack.Height / 2, FillColor);
    finally
      Canvas.RestoreState(LState);
    end;
  end
  else if FMax > FMin then
  begin
    LFrac := EnsureRange((FValue - FMin) / (FMax - FMin), 0, 1);
    if LFrac > 0 then
    begin
      LBar := RectF(0, 0, System.Math.Max(LTrack.Height, LTrack.Width * LFrac), LTrack.Height);
      FillRound(LBar, LBar.Height / 2, FillColor);
    end;
  end;
end;

end.
