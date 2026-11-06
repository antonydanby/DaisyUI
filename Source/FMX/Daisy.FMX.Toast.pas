unit Daisy.FMX.Toast;

{
  TDaisyFmxToast - the DaisyUI "toast": alert-style messages stacked in a corner (or the
  middle) of the area the control covers. Call Post to show a message; it fades out
  after Duration seconds (3, 4, 5 or 8). Clicking a message dismisses it.
  Only the messages take mouse input, so what is behind stays usable.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Animation, Daisy.Toasts,
  Daisy.FMX.Control;

type
  TDaisyFmxToast = class(TDaisyControl)
  strict private
    FList: TDaisyToastList;
    FSample: TDaisyToastList;
    FHorizontal: TDaisyToastHPlacement;
    FVertical: TDaisyToastVPlacement;
    FDuration: TDaisyToastDuration;
    FMaxMessages: Integer;
    FTicking: Boolean;
    procedure SetHorizontal(const AValue: TDaisyToastHPlacement);
    procedure SetVertical(const AValue: TDaisyToastVPlacement);
    procedure SetMaxMessages(const AValue: Integer);
    function ActiveList: TDaisyToastList;
    function Layout(AList: TDaisyToastList): TArray<TRectF>;
    procedure Tick(Sender: TObject);
    procedure UpdateTicking;
    procedure ListChanged;
  protected
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function PointInObjectLocal(X, Y: Single): Boolean; override;
    // Shows a message for the length of time set by Duration
    procedure Post(const AText: string; AVariant: TDaisyVariant = dvInfo); overload;
    // Shows a message for ASeconds seconds
    procedure Post(const AText: string; AVariant: TDaisyVariant; ASeconds: Integer); overload;
    procedure Clear;
  published
    property HorizontalPlacement: TDaisyToastHPlacement read FHorizontal write SetHorizontal default thEnd;
    property VerticalPlacement: TDaisyToastVPlacement read FVertical write SetVertical default tvBottom;
    // How long a message stays before it disappears
    property Duration: TDaisyToastDuration read FDuration write FDuration default tdSeconds5;
    // The oldest message goes when more are posted; 0 = no limit
    property MaxMessages: Integer read FMaxMessages write SetMaxMessages default 5;
  end;

implementation

const
  CIconSize = 24;
  CIconGap = 12;

{ TDaisyFmxToast }

constructor TDaisyFmxToast.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList := TDaisyToastList.Create;
  FSample := TDaisyToastList.Create;
  FSample.Add('Toast message', dvInfo, 1E9, 0, 0);
  FHorizontal := thEnd;
  FVertical := tvBottom;
  FDuration := tdSeconds5;
  FMaxMessages := 5;
  SetBounds(Position.X, Position.Y, 320, 200);
end;

destructor TDaisyFmxToast.Destroy;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  FSample.Free;
  FList.Free;
  inherited Destroy;
end;

procedure TDaisyFmxToast.SetHorizontal(const AValue: TDaisyToastHPlacement);
begin
  if FHorizontal <> AValue then
  begin
    FHorizontal := AValue;
    ListChanged;
  end;
end;

procedure TDaisyFmxToast.SetVertical(const AValue: TDaisyToastVPlacement);
begin
  if FVertical <> AValue then
  begin
    FVertical := AValue;
    ListChanged;
  end;
end;

procedure TDaisyFmxToast.SetMaxMessages(const AValue: Integer);
begin
  if FMaxMessages <> AValue then
    FMaxMessages := Max(0, AValue);
end;

function TDaisyFmxToast.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxToast.DefaultContentPadding: Integer;
begin
  Result := 16;
end;

function TDaisyFmxToast.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

function TDaisyFmxToast.ActiveList: TDaisyToastList;
begin
  if (csDesigning in ComponentState) and (FList.Count = 0) then
    Result := FSample
  else
    Result := FList;
end;

procedure TDaisyFmxToast.Post(const AText: string; AVariant: TDaisyVariant);
begin
  Post(AText, AVariant, DaisyToastSeconds(FDuration));
end;

procedure TDaisyFmxToast.Post(const AText: string; AVariant: TDaisyVariant; ASeconds: Integer);
begin
  FList.Add(AText, AVariant, ASeconds, DaisyAnimationClock.Time, FMaxMessages);
  ListChanged;
end;

procedure TDaisyFmxToast.Clear;
begin
  FList.Clear;
  ListChanged;
end;

procedure TDaisyFmxToast.ListChanged;
begin
  UpdateTicking;
  Repaint;
end;

procedure TDaisyFmxToast.UpdateTicking;
var
  LWant: Boolean;
begin
  LWant := (FList.Count > 0) and not (csDesigning in ComponentState);
  if LWant = FTicking then
    Exit;
  FTicking := LWant;
  if LWant then
    DaisyAnimationClock.AddListener(Tick)
  else
    DaisyAnimationClock.RemoveListener(Tick);
end;

procedure TDaisyFmxToast.Tick(Sender: TObject);
begin
  if FList.Prune(DaisyAnimationClock.Time) then
    ListChanged
  else
    Repaint;
end;

function TDaisyFmxToast.Layout(AList: TDaisyToastList): TArray<TRectF>;
var
  I: Integer;
  LMargin, LMaxW, LTextW, LTextH, LW, LH, LTotal, LY, LX, LIconW, LFont: Single;
begin
  SetLength(Result, AList.Count);
  if AList.Count = 0 then
    Exit;
  LFont := DaisyFontSize(SizeKind);
  LMargin := 12;
  LMaxW := System.Math.Max(60, Width - 2 * LMargin);
  LTotal := 0;
  for I := 0 to AList.Count - 1 do
  begin
    if DaisyResolveIcon(diAuto, AList[I].Variant) <> diNone then
      LIconW := CIconSize + CIconGap
    else
      LIconW := 0;
    LTextW := System.Math.Min(MeasureTextWidth(AList[I].Text, Round(LFont), False) + 2,
      LMaxW - 32 - LIconW);
    LTextW := System.Math.Max(LTextW, 1);
    LTextH := MeasureTextHeight(AList[I].Text, LTextW, Round(LFont), False);
    LW := LTextW + 32 + LIconW;
    if LIconW > 0 then
      LH := System.Math.Max(LTextH, CIconSize) + 24
    else
      LH := LTextH + 24;
    Result[I] := RectF(0, 0, LW, LH);
    LTotal := LTotal + LH;
  end;
  LTotal := LTotal + 8 * (AList.Count - 1);

  case FVertical of
    tvTop: LY := LMargin;
    tvMiddle: LY := (Height - LTotal) / 2;
  else
    LY := Height - LMargin - LTotal;
  end;
  for I := 0 to AList.Count - 1 do
  begin
    LW := Result[I].Right;
    LH := Result[I].Bottom;
    case FHorizontal of
      thStart: LX := LMargin;
      thCenter: LX := (Width - LW) / 2;
    else
      LX := Width - LMargin - LW;
    end;
    Result[I] := RectF(LX, LY, LX + LW, LY + LH);
    LY := LY + LH + 8;
  end;
end;

procedure TDaisyFmxToast.SizeChanged;
begin
  Repaint;
end;

function TDaisyFmxToast.PointInObjectLocal(X, Y: Single): Boolean;
var
  LRect: TRectF;
begin
  Result := False;
  if csDesigning in ComponentState then
    Exit(inherited PointInObjectLocal(X, Y));
  for LRect in Layout(FList) do
    if LRect.Contains(PointF(X, Y)) then
      Exit(True);
end;

procedure TDaisyFmxToast.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LRects: TArray<TRectF>;
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if csDesigning in ComponentState then
    Exit;
  LRects := Layout(FList);
  for I := High(LRects) downto 0 do
    if LRects[I].Contains(PointF(X, Y)) then
    begin
      FList.Delete(I);
      ListChanged;
      Break;
    end;
end;

procedure TDaisyFmxToast.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LList: TDaisyToastList;
  LRects: TArray<TRectF>;
  LColors: TDaisyColors;
  LBounds, LText: TRectF;
  LIcon: TDaisyIconKind;
  LOpacity: Single;
  LNow: Double;
  LRadius: Single;
  LFont, I: Integer;
begin
  LList := ActiveList;
  LRects := Layout(LList);
  if Length(LRects) = 0 then
    Exit;
  LNow := DaisyAnimationClock.Time;
  LFont := DaisyFontSize(SizeKind);
  LRadius := ResolvedCornerRadius;
  for I := 0 to High(LRects) do
  begin
    LOpacity := LList.Opacity(I, LNow);
    LColors := DaisyResolveColors(Theme, LList[I].Variant, Style, dstNormal);
    LIcon := DaisyResolveIcon(diAuto, LList[I].Variant);
    FillRound(LRects[I], LRadius, DaisyWithAlpha(LColors.Background, LOpacity));
    if TAlphaColorRec(LColors.Border).A > 0 then
      StrokeRound(LRects[I], LRadius, DaisyWithAlpha(LColors.Border, LOpacity),
        Theme.BorderWidth, LColors.Dashed);
    LText := LRects[I];
    LText.Inflate(-16, -12);
    if LIcon <> diNone then
    begin
      LBounds := RectF(LText.Left, LRects[I].Top + (LRects[I].Height - CIconSize) / 2,
        LText.Left + CIconSize, LRects[I].Top + (LRects[I].Height - CIconSize) / 2 + CIconSize);
      DrawPolylines(DaisyIconPaths(LIcon), LBounds, DaisyWithAlpha(LColors.Text, LOpacity), 2);
      LText.Left := LText.Left + CIconSize + CIconGap;
    end;
    DrawText(LList[I].Text, LText, DaisyWithAlpha(LColors.Text, LOpacity), LFont, False,
      TTextAlign.Leading, TTextAlign.Center, True);
  end;
end;

end.
