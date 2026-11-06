unit Daisy.VCL.Status;

{
  TDaisyStatus - the DaisyUI "status": a small coloured dot that shows the state
  of something, optionally pinging or bouncing. An Emoji or SVG replaces the dot.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.Widgets, Daisy.Animation, Daisy.VCL.Control;

type
  TDaisyStatus = class(TDaisyControl)
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
    function BaseUnit: Integer;
    function CellSize: Integer;
    procedure UpdateSize;
    function StatusColor: TAlphaColor;
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

{ TDaisyStatus }

constructor TDaisyStatus.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  FIcon := TDaisyIconSource.Create(IconChanged);
  SetBounds(Left, Top, 16, 16);
  UpdateSize;
end;

destructor TDaisyStatus.Destroy;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  FIcon.Free;
  inherited Destroy;
end;

function TDaisyStatus.GetEmoji: string;
begin
  Result := FIcon.Emoji;
end;

procedure TDaisyStatus.SetEmoji(const Value: string);
begin
  FIcon.Emoji := Value;
end;

function TDaisyStatus.GetSVG: TStrings;
begin
  Result := FIcon.SVG;
end;

procedure TDaisyStatus.SetSVG(const Value: TStrings);
begin
  FIcon.SVG := Value;
end;

procedure TDaisyStatus.IconChanged(Sender: TObject);
begin
  UpdateSize;
  Invalidate;
end;

procedure TDaisyStatus.SetAnimation(const Value: TDaisyStatusAnimation);
begin
  if FAnimation <> Value then
  begin
    FAnimation := Value;
    UpdateTicking;
    Invalidate;
  end;
end;

procedure TDaisyStatus.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyStatus.UpdateTicking;
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

procedure TDaisyStatus.Tick(Sender: TObject);
begin
  if HandleAllocated and Visible then
    Invalidate;
end;

function TDaisyStatus.BaseUnit: Integer;
begin
  if FIcon.IsEmpty then
    Result := ScaleValue(CDotSizes[SizeKind])
  else
    Result := ScaleValue(Max(12, 2 * CDotSizes[SizeKind]));
end;

function TDaisyStatus.CellSize: Integer;
begin
  if FIcon.IsEmpty then
    Result := Max(2 * BaseUnit, ScaleValue(8))
  else
    Result := Round(1.5 * BaseUnit);
end;

procedure TDaisyStatus.UpdateSize;
var
  LSide: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LSide := CellSize;
  if (Width = LSide) and (Height = LSide) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, LSide, LSide);
  finally
    FUpdating := False;
  end;
end;

function TDaisyStatus.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyStatus.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyStatus.StatusColor: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := DaisyWithAlpha(Theme.BaseContent, 0.2)
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
  if not Enabled then
    Result := DaisyWithAlpha(Theme.BaseContent, 0.1);
end;

function TDaisyStatus.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := StatusColor;
end;

procedure TDaisyStatus.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyStatus.Loaded;
begin
  inherited;
  UpdateSize;
  UpdateTicking;
end;

procedure TDaisyStatus.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LBrush: TGPSolidBrush;
  LUnit, LCx, LCy, LT, LP, LEase, LRing: Double;
  LBox: TRect;
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

  LGraphics := NewGraphics;
  try
    if FAnimation = saPing then
    begin
      LP := Min(LT / 0.75, 1);
      LEase := 1 - Power(1 - LP, 3);
      LRing := LUnit * (1 + LEase * (Max(1, Min(ARect.Width, ARect.Height) / LUnit) - 1));
      LBrush := TGPSolidBrush.Create(DaisyWithAlpha(AColors.Text, 0.75 * (1 - LEase)));
      try
        LGraphics.FillEllipse(LBrush, LCx - LRing / 2, LCy - LRing / 2, LRing, LRing);
      finally
        LBrush.Free;
      end;
    end;
    if not LHasIcon then
    begin
      LBrush := TGPSolidBrush.Create(AColors.Text);
      try
        LGraphics.FillEllipse(LBrush, LCx - LUnit / 2, LCy - LUnit / 2, LUnit, LUnit);
      finally
        LBrush.Free;
      end;
    end;
  finally
    LGraphics.Free;
  end;

  if LHasIcon then
  begin
    LBox := Rect(Round(LCx - LUnit / 2), Round(LCy - LUnit / 2), Round(LCx + LUnit / 2),
      Round(LCy + LUnit / 2));
    if Variant = dvDefault then
      DrawGlyph(FIcon, LBox, Theme.BaseContent)
    else
      DrawGlyph(FIcon, LBox, AColors.Text);
  end;
end;

end.
