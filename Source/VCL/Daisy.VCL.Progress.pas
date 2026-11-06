unit Daisy.VCL.Progress;

{
  TDaisyProgress - the DaisyUI "progress" bar: a rounded track with a filled part.
  Variant sets the colour, SizeKind the thickness. Indeterminate shows a sliding bar.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.Animation, Daisy.VCL.Control;

type
  TDaisyProgress = class(TDaisyControl)
  strict private
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FIndeterminate: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FTicking: Boolean;
    procedure SetMin(const Value: Double);
    procedure SetMax(const Value: Double);
    procedure SetValue(const Value: Double);
    procedure SetIndeterminate(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure Tick(Sender: TObject);
    procedure UpdateTicking;
    function BarHeight: Integer;
    procedure UpdateSize;
    function FillColor: TAlphaColor;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Min: Double read FMin write SetMin;
    property Max: Double read FMax write SetMax;
    property Value: Double read FValue write SetValue;
    // Shows a bar sliding back and forth instead of the position
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    // The height follows SizeKind; when off the control keeps its own height
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
  end;

implementation

const
  CBarHeights: array[TDaisySize] of Integer = (2, 4, 8, 12, 16);

{ TDaisyProgress }

constructor TDaisyProgress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin := 0;
  FMax := 100;
  FAutoFit := True;
  SetBounds(Left, Top, 224, 8);
  UpdateSize;
end;

destructor TDaisyProgress.Destroy;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  inherited Destroy;
end;

procedure TDaisyProgress.SetMin(const Value: Double);
begin
  if FMin <> Value then
  begin
    FMin := Value;
    Invalidate;
  end;
end;

procedure TDaisyProgress.SetMax(const Value: Double);
begin
  if FMax <> Value then
  begin
    FMax := Value;
    Invalidate;
  end;
end;

procedure TDaisyProgress.SetValue(const Value: Double);
begin
  if FValue <> Value then
  begin
    FValue := Value;
    Invalidate;
  end;
end;

procedure TDaisyProgress.SetIndeterminate(const Value: Boolean);
begin
  if FIndeterminate <> Value then
  begin
    FIndeterminate := Value;
    UpdateTicking;
    Invalidate;
  end;
end;

procedure TDaisyProgress.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyProgress.UpdateTicking;
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

procedure TDaisyProgress.Tick(Sender: TObject);
begin
  if HandleAllocated and Visible then
    Invalidate;
end;

function TDaisyProgress.BarHeight: Integer;
begin
  Result := ScaleValue(CBarHeights[SizeKind]);
end;

procedure TDaisyProgress.UpdateSize;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  if Height = BarHeight then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, Width, BarHeight);
  finally
    FUpdating := False;
  end;
end;

function TDaisyProgress.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyProgress.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyProgress.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyProgress.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

function TDaisyProgress.FillColor: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
  if not Enabled then
    Result := DaisyWithAlpha(Result, 0.4);
end;

procedure TDaisyProgress.SizeChanged;
begin
  UpdateSize;
  Invalidate;
end;

procedure TDaisyProgress.Loaded;
begin
  inherited;
  UpdateSize;
  UpdateTicking;
end;

procedure TDaisyProgress.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LTrack, LBar: TRectF;
  LFrac, LSeg, LPhase: Single;
begin
  LTrack := RectF(0, 0, Width, Height);
  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LTrack, LTrack.Height / 2, DaisyWithAlpha(Theme.BaseContent, 0.2));
    if FIndeterminate then
    begin
      // The bar slides across the track and is clipped by it, like the CSS version
      LSeg := LTrack.Width * 0.4;
      LPhase := Frac(DaisyAnimationClock.Time / 1.5);
      LPhase := LPhase * LPhase * (3 - 2 * LPhase);
      LGraphics.SetClip(MakeRect(LTrack.Left, LTrack.Top, LTrack.Width, LTrack.Height));
      LBar := RectF(-LSeg + LPhase * (LTrack.Width + LSeg), 0,
        LPhase * (LTrack.Width + LSeg), LTrack.Height);
      FillRoundRect(LGraphics, LBar, LTrack.Height / 2, FillColor);
    end
    else if FMax > FMin then
    begin
      LFrac := EnsureRange((FValue - FMin) / (FMax - FMin), 0, 1);
      if LFrac > 0 then
      begin
        LBar := RectF(0, 0, System.Math.Max(LTrack.Height, LTrack.Width * LFrac), LTrack.Height);
        FillRoundRect(LGraphics, LBar, LBar.Height / 2, FillColor);
      end;
    end;
  finally
    LGraphics.Free;
  end;
end;

end.
