unit Daisy.FMX.Status;

{
  TDaisyFmxStatus - the DaisyUI "status": a small coloured dot that shows the state
  of something, optionally pinging or bouncing. An Emoji or SVG replaces the dot.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.Animation,
  Daisy.FMX.Control;

type
  TDaisyFmxStatus = class(TDaisyControl)
  strict private
    FAnimation: TDaisyStatusAnimation;
    FIcon: TDaisyIconSource;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FTicking: Boolean;
    procedure SetAnimation(const Value: TDaisyStatusAnimation);
    procedure SetAutoFit(const Value: Boolean);
    function GetEmoji: string;
    procedure SetEmoji(const Value: string);
    function GetSVG: TStrings;
    procedure SetSVG(const Value: TStrings);
    procedure IconChanged(Sender: TObject);
    procedure Tick(Sender: TObject);
    procedure UpdateTicking;
    function BaseUnit: Single;
    function CellSize: Single;
    procedure UpdateSize;
    function StatusColor: TAlphaColor;
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
    property Animation: TDaisyStatusAnimation read FAnimation write SetAnimation default saNone;
    // Shown instead of the dot
    property Emoji: string read GetEmoji write SetEmoji;
    // Paste SVG markup or load an .svg file; replaces the dot
    property SVG: TStrings read GetSVG write SetSVG;
    // The size follows SizeKind; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
  end;

implementation

const
  CDotSizes: array[TDaisySize] of Integer = (2, 4, 8, 12, 16);

{ TDaisyFmxStatus }

constructor TDaisyFmxStatus.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  FIcon := TDaisyIconSource.Create(IconChanged);
  HitTest := False;
  SetBounds(Position.X, Position.Y, 16, 16);
  UpdateSize;
end;

destructor TDaisyFmxStatus.Destroy;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  FIcon.Free;
  inherited Destroy;
end;

function TDaisyFmxStatus.GetEmoji: string;
begin
  Result := FIcon.Emoji;
end;

procedure TDaisyFmxStatus.SetEmoji(const Value: string);
begin
  FIcon.Emoji := Value;
end;

function TDaisyFmxStatus.GetSVG: TStrings;
begin
  Result := FIcon.SVG;
end;

procedure TDaisyFmxStatus.SetSVG(const Value: TStrings);
begin
  FIcon.SVG := Value;
end;

procedure TDaisyFmxStatus.IconChanged(Sender: TObject);
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxStatus.SetAnimation(const Value: TDaisyStatusAnimation);
begin
  if FAnimation <> Value then
  begin
    FAnimation := Value;
    UpdateTicking;
    Repaint;
  end;
end;

procedure TDaisyFmxStatus.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyFmxStatus.UpdateTicking;
var
  LWant: Boolean;
begin
  LWant := (FAnimation <> saNone) and not (csDesigning in ComponentState)
    and not (csLoading in ComponentState);
  if LWant = FTicking then
    Exit;
  FTicking := LWant;
  if LWant then
    DaisyAnimationClock.AddListener(Tick)
  else
    DaisyAnimationClock.RemoveListener(Tick);
end;

procedure TDaisyFmxStatus.Tick(Sender: TObject);
begin
  if Visible then
    Repaint;
end;

function TDaisyFmxStatus.BaseUnit: Single;
begin
  if FIcon.IsEmpty then
    Result := CDotSizes[SizeKind]
  else
    Result := Max(12, 2 * CDotSizes[SizeKind]);
end;

function TDaisyFmxStatus.CellSize: Single;
begin
  if FIcon.IsEmpty then
    Result := Max(2 * BaseUnit, 8)
  else
    Result := 1.5 * BaseUnit;
end;

procedure TDaisyFmxStatus.UpdateSize;
var
  LSide: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LSide := CellSize;
  if SameValue(Width, LSide) and SameValue(Height, LSide) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LSide, LSide);
  finally
    FUpdating := False;
  end;
end;

function TDaisyFmxStatus.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxStatus.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxStatus.StatusColor: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := DaisyWithAlpha(Theme.BaseContent, 0.2)
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
  if not Enabled then
    Result := DaisyWithAlpha(Theme.BaseContent, 0.1);
end;

function TDaisyFmxStatus.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := StatusColor;
end;

procedure TDaisyFmxStatus.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxStatus.Loaded;
begin
  inherited;
  UpdateSize;
  UpdateTicking;
end;

procedure TDaisyFmxStatus.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LUnit, LCx, LCy, LT, LP, LEase, LRing: Single;
  LBox: TRectF;
  LHasIcon: Boolean;
begin
  LUnit := BaseUnit;
  LHasIcon := not FIcon.IsEmpty;
  LCx := (ARect.Left + ARect.Right) / 2;
  LCy := (ARect.Top + ARect.Bottom) / 2;
  LT := 0;
  if FAnimation <> saNone then
    LT := Frac(DaisyAnimationClock.Time);

  if FAnimation = saBounce then
    LCy := LCy + LUnit * 0.4 - Abs(Sin(Pi * LT)) * LUnit * 0.8;

  Canvas.Fill.Kind := TBrushKind.Solid;
  if FAnimation = saPing then
  begin
    LP := Min(LT / 0.75, 1);
    LEase := 1 - Power(1 - LP, 3);
    LRing := LUnit * (1 + LEase * (Max(1, Min(ARect.Width, ARect.Height) / LUnit) - 1));
    Canvas.Fill.Color := DaisyWithAlpha(AColors.Text, 0.75 * (1 - LEase));
    Canvas.FillEllipse(RectF(LCx - LRing / 2, LCy - LRing / 2, LCx + LRing / 2, LCy + LRing / 2),
      AbsoluteOpacity);
  end;
  if not LHasIcon then
  begin
    Canvas.Fill.Color := AColors.Text;
    Canvas.FillEllipse(RectF(LCx - LUnit / 2, LCy - LUnit / 2, LCx + LUnit / 2, LCy + LUnit / 2),
      AbsoluteOpacity);
  end
  else
  begin
    LBox := RectF(LCx - LUnit / 2, LCy - LUnit / 2, LCx + LUnit / 2, LCy + LUnit / 2);
    if Variant = dvDefault then
      DrawGlyph(FIcon, LBox, Theme.BaseContent)
    else
      DrawGlyph(FIcon, LBox, AColors.Text);
  end;
end;

end.
