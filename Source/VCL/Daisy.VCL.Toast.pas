unit Daisy.VCL.Toast;

{
  TDaisyToast - the DaisyUI "toast": alert-style messages stacked in a corner (or the
  middle) of the area the control covers. Call Post to show a message; it fades out
  after Duration seconds (3, 4, 5 or 8). Clicking a message dismisses it.
  The control only occupies the pixels of the messages, so what is behind stays usable.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.Animation, Daisy.Toasts, Daisy.VCL.Control;

type
  TDaisyToast = class(TDaisyControl)
  strict private
    FList: TDaisyToastList;
    FSample: TDaisyToastList;
    FHorizontal: TDaisyToastHPlacement;
    FVertical: TDaisyToastVPlacement;
    FDuration: TDaisyToastDuration;
    FMaxMessages: Integer;
    FTicking: Boolean;
    procedure SetHorizontal(const Value: TDaisyToastHPlacement);
    procedure SetVertical(const Value: TDaisyToastVPlacement);
    procedure SetMaxMessages(const Value: Integer);
    function ActiveList: TDaisyToastList;
    function Layout(AList: TDaisyToastList): TArray<TRect>;
    procedure Tick(Sender: TObject);
    procedure UpdateTicking;
    procedure UpdateRegion;
    procedure ListChanged;
  protected
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure CreateWnd; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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

{ TDaisyToast }

constructor TDaisyToast.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList := TDaisyToastList.Create;
  FSample := TDaisyToastList.Create;
  FSample.Add('Toast message', dvInfo, 1E9, 0, 0);
  FHorizontal := thEnd;
  FVertical := tvBottom;
  FDuration := tdSeconds5;
  FMaxMessages := 5;
  SetBounds(Left, Top, 320, 200);
end;

destructor TDaisyToast.Destroy;
begin
  DaisyAnimationClock.RemoveListener(Tick);
  FSample.Free;
  FList.Free;
  inherited Destroy;
end;

procedure TDaisyToast.SetHorizontal(const Value: TDaisyToastHPlacement);
begin
  if FHorizontal <> Value then
  begin
    FHorizontal := Value;
    ListChanged;
  end;
end;

procedure TDaisyToast.SetVertical(const Value: TDaisyToastVPlacement);
begin
  if FVertical <> Value then
  begin
    FVertical := Value;
    ListChanged;
  end;
end;

procedure TDaisyToast.SetMaxMessages(const Value: Integer);
begin
  if FMaxMessages <> Value then
    FMaxMessages := Max(0, Value);
end;

function TDaisyToast.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyToast.DefaultContentPadding: Integer;
begin
  Result := 16;
end;

function TDaisyToast.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

function TDaisyToast.ActiveList: TDaisyToastList;
begin
  if (csDesigning in ComponentState) and (FList.Count = 0) then
    Result := FSample
  else
    Result := FList;
end;

procedure TDaisyToast.Post(const AText: string; AVariant: TDaisyVariant);
begin
  Post(AText, AVariant, DaisyToastSeconds(FDuration));
end;

procedure TDaisyToast.Post(const AText: string; AVariant: TDaisyVariant; ASeconds: Integer);
begin
  FList.Add(AText, AVariant, ASeconds, DaisyAnimationClock.Time, FMaxMessages);
  ListChanged;
end;

procedure TDaisyToast.Clear;
begin
  FList.Clear;
  ListChanged;
end;

procedure TDaisyToast.ListChanged;
begin
  UpdateTicking;
  UpdateRegion;
  Invalidate;
end;

procedure TDaisyToast.UpdateTicking;
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

procedure TDaisyToast.Tick(Sender: TObject);
begin
  if FList.Prune(DaisyAnimationClock.Time) then
    ListChanged
  else
    Invalidate;
end;

function TDaisyToast.Layout(AList: TDaisyToastList): TArray<TRect>;
var
  I, LMargin, LPadX, LPadY, LGap, LIconW, LMaxW, LTextW, LTextH, LW, LH, LTotal, LY, LX: Integer;
  LFont: Integer;
begin
  SetLength(Result, AList.Count);
  if AList.Count = 0 then
    Exit;
  LFont := DaisyFontSize(SizeKind);
  LMargin := ScaleValue(12);
  LPadX := ScaleValue(16);
  LPadY := ScaleValue(12);
  LGap := ScaleValue(8);
  LMaxW := Max(ScaleValue(60), Width - 2 * LMargin);
  LTotal := 0;
  for I := 0 to AList.Count - 1 do
  begin
    if DaisyResolveIcon(diAuto, AList[I].Variant) <> diNone then
      LIconW := ScaleValue(CIconSize) + ScaleValue(CIconGap)
    else
      LIconW := 0;
    LTextW := Min(MeasureTextWidth(AList[I].Text, LFont, False) + 2,
      LMaxW - 2 * LPadX - LIconW);
    LTextW := Max(LTextW, 1);
    LTextH := MeasureTextHeight(AList[I].Text, LTextW, LFont, False);
    LW := LTextW + 2 * LPadX + LIconW;
    LH := Max(LTextH, ScaleValue(CIconSize) * Ord(LIconW > 0)) + 2 * LPadY;
    Result[I] := Rect(0, 0, LW, LH);
    Inc(LTotal, LH);
  end;
  Inc(LTotal, LGap * (AList.Count - 1));

  case FVertical of
    tvTop: LY := LMargin;
    tvMiddle: LY := (Height - LTotal) div 2;
  else
    LY := Height - LMargin - LTotal;
  end;
  for I := 0 to AList.Count - 1 do
  begin
    LW := Result[I].Right;
    LH := Result[I].Bottom;
    case FHorizontal of
      thStart: LX := LMargin;
      thCenter: LX := (Width - LW) div 2;
    else
      LX := Width - LMargin - LW;
    end;
    Result[I] := Rect(LX, LY, LX + LW, LY + LH);
    Inc(LY, LH + LGap);
  end;
end;

procedure TDaisyToast.UpdateRegion;
var
  LRects: TArray<TRect>;
  LRgn, LPart: HRGN;
  LRadius, I: Integer;
begin
  if (not HandleAllocated) or (csDesigning in ComponentState) then
    Exit;
  LRects := Layout(FList);
  LRadius := ResolvedCornerRadius;
  LRgn := CreateRectRgn(0, 0, 0, 0);
  for I := 0 to High(LRects) do
  begin
    LPart := CreateRoundRectRgn(LRects[I].Left, LRects[I].Top, LRects[I].Right + 1,
      LRects[I].Bottom + 1, 2 * LRadius, 2 * LRadius);
    CombineRgn(LRgn, LRgn, LPart, RGN_OR);
    DeleteObject(LPart);
  end;
  SetWindowRgn(Handle, LRgn, True);
end;

procedure TDaisyToast.SizeChanged;
begin
  UpdateRegion;
  Invalidate;
end;

procedure TDaisyToast.CreateWnd;
begin
  inherited CreateWnd;
  UpdateRegion;
end;

procedure TDaisyToast.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LRects: TArray<TRect>;
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if csDesigning in ComponentState then
    Exit;
  LRects := Layout(FList);
  for I := High(LRects) downto 0 do
    if PtInRect(LRects[I], Point(X, Y)) then
    begin
      FList.Delete(I);
      ListChanged;
      Break;
    end;
end;

procedure TDaisyToast.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LList: TDaisyToastList;
  LRects: TArray<TRect>;
  LColors: TDaisyColors;
  LGraphics: TGPGraphics;
  LBounds: TRectF;
  LText: TRect;
  LIcon: TDaisyIconKind;
  LOpacity: Single;
  LNow: Double;
  LFont, LRadius, LPadX, LPadY, I: Integer;
begin
  LList := ActiveList;
  LRects := Layout(LList);
  if Length(LRects) = 0 then
    Exit;
  LNow := DaisyAnimationClock.Time;
  LFont := DaisyFontSize(SizeKind);
  LRadius := ResolvedCornerRadius;
  LPadX := ScaleValue(16);
  LPadY := ScaleValue(12);
  for I := 0 to High(LRects) do
  begin
    LOpacity := LList.Opacity(I, LNow);
    LColors := DaisyResolveColors(Theme, LList[I].Variant, Style, dstNormal);
    LBounds := RectF(LRects[I].Left, LRects[I].Top, LRects[I].Right, LRects[I].Bottom);
    LIcon := DaisyResolveIcon(diAuto, LList[I].Variant);

    LGraphics := NewGraphics;
    try
      FillRoundRect(LGraphics, LBounds, LRadius, DaisyWithAlpha(LColors.Background, LOpacity));
      if TAlphaColorRec(LColors.Border).A > 0 then
        StrokeRoundRect(LGraphics, LBounds, LRadius, DaisyWithAlpha(LColors.Border, LOpacity),
          Theme.BorderWidth, LColors.Dashed);
      LText := LRects[I];
      InflateRect(LText, -LPadX, -LPadY);
      if LIcon <> diNone then
      begin
        LBounds := RectF(LText.Left, LRects[I].Top + (LRects[I].Height - ScaleValue(CIconSize)) / 2,
          LText.Left + ScaleValue(CIconSize),
          LRects[I].Top + (LRects[I].Height - ScaleValue(CIconSize)) / 2 + ScaleValue(CIconSize));
        DrawPolylines(LGraphics, DaisyIconPaths(LIcon), LBounds,
          DaisyWithAlpha(LColors.Text, LOpacity), 2);
        Inc(LText.Left, ScaleValue(CIconSize) + ScaleValue(CIconGap));
      end;
    finally
      LGraphics.Free;
    end;
    DrawText(LList[I].Text, LText, DaisyWithAlpha(LColors.Text, LOpacity), LFont, False,
      DT_LEFT or DT_VCENTER or DT_WORDBREAK or DT_END_ELLIPSIS);
  end;
end;

end.
