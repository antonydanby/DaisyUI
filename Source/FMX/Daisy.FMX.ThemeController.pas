unit Daisy.FMX.ThemeController;

{
  TDaisyFmxThemeController - the DaisyUI "theme controller": a control that switches the theme
  of the whole application. Unchecked it applies UncheckedTheme, checked it applies
  CheckedTheme. Kind picks the look: a toggle (also with icons), a check box, a sun / moon swap,
  a button or a pair of radio buttons. The controller follows theme changes made elsewhere
  (for example by a TDaisyFmxFormStyler), so it always shows the theme that is current.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Diagnostics, FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets,
  Daisy.Animation, Daisy.Swap, Daisy.ThemeController, Daisy.FMX.Control;

type
  TDaisyFmxThemeController = class(TDaisyControl)
  strict private
    FKind: TDaisyThemeControllerKind;
    FChecked: Boolean;
    FCheckedTheme: TDaisyThemeKind;
    FUncheckedTheme: TDaisyThemeKind;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FSyncing: Boolean;
    FText: string;
    FDownY: Single;
    FPos, FFrom, FTarget: Single;
    FStart: Int64;
    FAnimating: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetKind(const AValue: TDaisyThemeControllerKind);
    procedure SetChecked(const AValue: Boolean);
    procedure SetCheckedTheme(const AValue: TDaisyThemeKind);
    procedure SetUncheckedTheme(const AValue: TDaisyThemeKind);
    procedure SetAutoFit(const AValue: Boolean);
    procedure SetText(const AValue: string);
    function ThemeFor(AChecked: Boolean): TDaisyThemeKind;
    procedure GlobalThemeChanged(Sender: TObject);
    procedure SyncChecked(AValue: Boolean);
    procedure MoveKnob;
    procedure Tick(Sender: TObject);
    procedure StopAnimation;
    function TrackHeight: Single;
    function TrackWidth: Single;
    function IconSide: Single;
    function RowHeight: Single;
    function CaptionWidth: Single;
    function RadioWidth: Single;
    function Tint: TAlphaColor;
    procedure UpdateSize;
    procedure DrawSwitch(AX, AY: Single; AIcons: Boolean);
    procedure DrawCheckBox(AX, AY: Single);
    procedure DrawRadios;
    procedure DrawButton;
    procedure DrawSwapIcon;
    procedure DrawCaption(AX: Single);
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Kind: TDaisyThemeControllerKind read FKind write SetKind default tkToggle;
    // False applies UncheckedTheme, True applies CheckedTheme
    property Checked: Boolean read FChecked write SetChecked default False;
    property CheckedTheme: TDaisyThemeKind read FCheckedTheme write SetCheckedTheme default dtDim;
    property UncheckedTheme: TDaisyThemeKind read FUncheckedTheme write SetUncheckedTheme
      default dtCorporate;
    // Text beside a toggle or check box
    property Text: string read FText write SetText;
    // The size follows Kind, SizeKind and Text; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CTrackHeights: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
  CSlideSeconds = 0.18;
  CMargin = 3;
  CCheckPath = 'M5 12l5 5l10 -10';

{ TDaisyFmxThemeController }

constructor TDaisyFmxThemeController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKind := tkToggle;
  FCheckedTheme := dtDim;
  FUncheckedTheme := dtCorporate;
  FAutoFit := True;
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Position.X, Position.Y, 52, 28);
  UpdateSize;
  if not (csDesigning in ComponentState) then
    DaisyThemes.AddListener(GlobalThemeChanged);
end;

destructor TDaisyFmxThemeController.Destroy;
begin
  DaisyRemoveThemeListener(GlobalThemeChanged);
  StopAnimation;
  inherited Destroy;
end;

function TDaisyFmxThemeController.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxThemeController.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyFmxThemeController.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxThemeController.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxThemeController.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxThemeController.ThemeFor(AChecked: Boolean): TDaisyThemeKind;
begin
  if AChecked then
    Result := FCheckedTheme
  else
    Result := FUncheckedTheme;
end;

// Follows a theme change made by someone else, without applying anything
procedure TDaisyFmxThemeController.GlobalThemeChanged(Sender: TObject);
var
  LCurrent: TDaisyThemeKind;
begin
  LCurrent := DaisyThemes.Current;
  if LCurrent = FCheckedTheme then
    SyncChecked(True)
  else if LCurrent = FUncheckedTheme then
    SyncChecked(False);
end;

procedure TDaisyFmxThemeController.SyncChecked(AValue: Boolean);
begin
  FSyncing := True;
  try
    SetChecked(AValue);
  finally
    FSyncing := False;
  end;
end;

procedure TDaisyFmxThemeController.MoveKnob;
begin
  StopAnimation;
  FFrom := FPos;
  if FChecked then
    FTarget := 1
  else
    FTarget := 0;
  if (csLoading in ComponentState) or (csDesigning in ComponentState) then
  begin
    FPos := FTarget;
    Repaint;
    Exit;
  end;
  FStart := TStopwatch.GetTimeStamp;
  FAnimating := True;
  DaisyAnimationClock.AddListener(Tick);
end;

procedure TDaisyFmxThemeController.StopAnimation;
begin
  if FAnimating then
  begin
    FAnimating := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisyFmxThemeController.Tick(Sender: TObject);
var
  LT: Double;
begin
  LT := (TStopwatch.GetTimeStamp - FStart) / TStopwatch.Frequency / CSlideSeconds;
  if LT >= 1 then
  begin
    FPos := FTarget;
    StopAnimation;
  end
  else
    FPos := FFrom + (FTarget - FFrom) * (1 - Power(1 - LT, 3));
  Repaint;
end;

procedure TDaisyFmxThemeController.SetChecked(const AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;
  FChecked := AValue;
  MoveKnob;
  UpdateSize;
  if not FSyncing and not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    DaisyThemes.Current := ThemeFor(FChecked);
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyFmxThemeController.SetKind(const AValue: TDaisyThemeControllerKind);
begin
  if FKind <> AValue then
  begin
    FKind := AValue;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxThemeController.SetCheckedTheme(const AValue: TDaisyThemeKind);
begin
  if FCheckedTheme <> AValue then
  begin
    FCheckedTheme := AValue;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxThemeController.SetUncheckedTheme(const AValue: TDaisyThemeKind);
begin
  if FUncheckedTheme <> AValue then
  begin
    FUncheckedTheme := AValue;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxThemeController.SetAutoFit(const AValue: Boolean);
begin
  if FAutoFit <> AValue then
  begin
    FAutoFit := AValue;
    UpdateSize;
  end;
end;

procedure TDaisyFmxThemeController.SetText(const AValue: string);
begin
  if FText <> AValue then
  begin
    FText := AValue;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxThemeController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FDownY := Y;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDaisyFmxThemeController.Click;
begin
  inherited Click;
  if not Enabled then
    Exit;
  if FKind = tkRadio then
    SetChecked(FDownY >= CMargin + RowHeight + 4)
  else
    SetChecked(not FChecked);
end;

procedure TDaisyFmxThemeController.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if ((Key = vkSpace) or (KeyChar = ' ')) and Enabled then
  begin
    SetChecked(not FChecked);
    Key := 0;
    KeyChar := #0;
  end
  else
    inherited KeyDown(Key, KeyChar, Shift);
end;

function TDaisyFmxThemeController.TrackHeight: Single;
begin
  Result := CTrackHeights[SizeKind];
end;

function TDaisyFmxThemeController.TrackWidth: Single;
begin
  Result := 2 * TrackHeight - 4;
end;

function TDaisyFmxThemeController.IconSide: Single;
begin
  if FKind = tkSwap then
    Result := Round(TrackHeight * 1.5)
  else
    Result := Round(TrackHeight * 0.8);
end;

function TDaisyFmxThemeController.RowHeight: Single;
begin
  Result := TrackHeight;
end;

function TDaisyFmxThemeController.CaptionWidth: Single;
begin
  if FText = '' then
    Result := 0
  else
    Result := 8 + MeasureTextWidth(FText, DaisyFontSize(SizeKind), False) + 2;
end;

function TDaisyFmxThemeController.RadioWidth: Single;
begin
  Result := System.Math.Max(MeasureTextWidth(DaisyThemeControllerCaption(FUncheckedTheme),
    DaisyFontSize(SizeKind), False),
    MeasureTextWidth(DaisyThemeControllerCaption(FCheckedTheme), DaisyFontSize(SizeKind), False));
end;

function TDaisyFmxThemeController.Tint: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
end;

procedure TDaisyFmxThemeController.UpdateSize;
var
  LWidth, LHeight: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := TrackHeight + 2 * CMargin;
  case FKind of
    tkToggle, tkToggleIcons:
      LWidth := TrackWidth + 2 * CMargin + CaptionWidth;
    tkSunMoon:
      LWidth := TrackWidth + 2 * IconSide + 16 + 2 * CMargin;
    tkCheckBox:
      LWidth := Round(TrackHeight * 0.9) + 2 * CMargin + CaptionWidth;
    tkSwap:
      begin
        LWidth := IconSide + 2 * CMargin;
        LHeight := LWidth;
      end;
    tkButton:
      begin
        LWidth := RadioWidth + 32;
        LHeight := DaisyFieldHeight(SizeKind);
      end;
  else
    LWidth := Round(TrackHeight * 0.75) + 8 + RadioWidth + 2 * CMargin;
    LHeight := 2 * RowHeight + 4 + 2 * CMargin;
  end;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxThemeController.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxThemeController.Loaded;
begin
  inherited;
  StopAnimation;
  if FChecked then
    FPos := 1
  else
    FPos := 0;
  UpdateSize;
  if not (csDesigning in ComponentState) then
    GlobalThemeChanged(Self);
end;

procedure TDaisyFmxThemeController.DrawCaption(AX: Single);
begin
  if FText = '' then
    Exit;
  DrawText(FText, RectF(AX + 8, 0, Width, Height),
    DaisyWithAlpha(Theme.BaseContent, IfThen(Enabled, 1.0, 0.3)), DaisyFontSize(SizeKind), False,
    TTextAlign.Leading, TTextAlign.Center, False);
end;

procedure TDaisyFmxThemeController.DrawSwitch(AX, AY: Single; AIcons: Boolean);
var
  LTrack, LBox: TRectF;
  LOn, LOffFill, LTrackFill, LBorder, LKnob, LIconColor, LTint: TAlphaColor;
  LH, LW, LInset, LDia, LKnobX, LKnobY, LFade: Single;
begin
  LH := TrackHeight;
  LW := TrackWidth;
  LTrack := RectF(AX, AY, AX + LW, AY + LH);
  LTint := Tint;
  if Variant = dvDefault then
    LOn := Theme.Base100
  else
    LOn := DaisyVariantPalette(Theme, Variant).Content;
  LOffFill := DaisyMix(Theme.Base100, Theme.BaseContent, 0.5);
  LTrackFill := DaisyMix(Theme.Base100, LTint, FPos);
  LBorder := DaisyMix(LOffFill, LTint, FPos);
  LKnob := DaisyMix(LOffFill, LOn, FPos);
  LFade := IfThen(Enabled, 1.0, 0.3);
  LInset := System.Math.Max(2.0, LH / 8);
  LDia := LH - 2 * LInset;
  LKnobX := LTrack.Left + LInset + (LW - LH) * FPos;
  LKnobY := LTrack.Top + LInset;

  FillRound(LTrack, LH / 2, DaisyWithAlpha(LTrackFill, LFade));
  StrokeRound(LTrack, LH / 2, DaisyWithAlpha(LBorder, LFade),
    System.Math.Max(1, Theme.BorderWidth), False);

  if AIcons then
  begin
    LIconColor := DaisyWithAlpha(DaisyMix(Theme.BaseContent, Theme.Base100, FPos), LFade);
    LBox := RectF(LTrack.Left + LInset + LDia * 0.2, LKnobY + LDia * 0.2,
      LTrack.Left + LInset + LDia * 0.8, LKnobY + LDia * 0.8);
    DrawIconPath(CDaisyIconSun, LBox, LIconColor);
    LBox.Offset(LW - LH, 0);
    DrawIconPath(CDaisyIconMoon, LBox, LIconColor);
  end;

  FillRound(RectF(LKnobX, LKnobY, LKnobX + LDia, LKnobY + LDia), LDia / 2,
    DaisyWithAlpha(LKnob, LFade));
  if IsFocused then
  begin
    LBox := LTrack;
    LBox.Inflate(2, 2);
    StrokeRound(LBox, LBox.Height / 2, DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade), 1, False);
  end;
end;

procedure TDaisyFmxThemeController.DrawCheckBox(AX, AY: Single);
var
  LBox: TRectF;
  LTint, LFill, LBorder: TAlphaColor;
  LSide, LFade: Single;
begin
  LSide := Round(TrackHeight * 0.9);
  LBox := RectF(AX, AY, AX + LSide, AY + LSide);
  LTint := Tint;
  LFade := IfThen(Enabled, 1.0, 0.3);
  LFill := DaisyMix(Theme.Base100, LTint, FPos);
  LBorder := DaisyMix(DaisyMix(Theme.Base100, Theme.BaseContent, 0.5), LTint, FPos);
  FillRound(LBox, Theme.RadiusSelector, DaisyWithAlpha(LFill, LFade));
  StrokeRound(LBox, Theme.RadiusSelector, DaisyWithAlpha(LBorder, LFade),
    System.Math.Max(1, Theme.BorderWidth), False);
  if IsFocused then
  begin
    LBox.Inflate(2, 2);
    StrokeRound(LBox, Theme.RadiusSelector + 2, DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade),
      1, False);
    LBox.Inflate(-2, -2);
  end;
  if FPos > 0.05 then
  begin
    LBox.Inflate(-LSide * 0.12, -LSide * 0.12);
    if Variant = dvDefault then
      LFill := Theme.Base100
    else
      LFill := DaisyVariantPalette(Theme, Variant).Content;
    DrawIconPath(CCheckPath, LBox, DaisyWithAlpha(LFill, FPos * LFade));
  end;
end;

procedure TDaisyFmxThemeController.DrawRadios;
var
  LCircle: TRectF;
  LTint, LBorder: TAlphaColor;
  LSide, LFade, LTop: Single;
  I: Integer;
  LSelected: Boolean;
begin
  LSide := Round(TrackHeight * 0.75);
  LTint := Tint;
  LFade := IfThen(Enabled, 1.0, 0.3);
  for I := 0 to 1 do
  begin
    LSelected := FChecked = (I = 1);
    LTop := CMargin + I * (RowHeight + 4);
    LCircle := RectF(CMargin, LTop + (RowHeight - LSide) / 2, CMargin + LSide,
      LTop + (RowHeight + LSide) / 2);
    if LSelected then
      LBorder := LTint
    else
      LBorder := DaisyMix(Theme.Base100, Theme.BaseContent, 0.5);
    FillRound(LCircle, LSide / 2, DaisyWithAlpha(Theme.Base100, LFade));
    StrokeRound(LCircle, LSide / 2, DaisyWithAlpha(LBorder, LFade),
      System.Math.Max(1, Theme.BorderWidth), False);
    if LSelected then
    begin
      LCircle.Inflate(-LSide * 0.25, -LSide * 0.25);
      FillRound(LCircle, LCircle.Width / 2, DaisyWithAlpha(LTint, LFade));
    end;
    DrawText(DaisyThemeControllerCaption(ThemeFor(I = 1)),
      RectF(CMargin + LSide + 8, LTop, Width, LTop + RowHeight),
      DaisyWithAlpha(Theme.BaseContent, LFade), DaisyFontSize(SizeKind), False,
      TTextAlign.Leading, TTextAlign.Center, False);
  end;
end;

procedure TDaisyFmxThemeController.DrawButton;
var
  LBody: TRectF;
  LFade: Single;
begin
  LFade := IfThen(Enabled, 1.0, 0.3);
  LBody := RectF(0, 0, Width, Height);
  LBody.Inflate(-0.5, -0.5);
  FillRound(LBody, Theme.RadiusField,
    DaisyWithAlpha(DaisyMix(Theme.Base200, Theme.BaseContent, IfThen(Hot, 0.06, 0.0)), LFade));
  StrokeRound(LBody, Theme.RadiusField, DaisyWithAlpha(Theme.Base300, LFade),
    System.Math.Max(1, Theme.BorderWidth), False);
  DrawText(DaisyThemeControllerCaption(ThemeFor(FChecked)), RectF(0, 0, Width, Height),
    DaisyWithAlpha(Theme.BaseContent, LFade), DaisyFontSize(SizeKind), False,
    TTextAlign.Center, TTextAlign.Center, False);
end;

procedure TDaisyFmxThemeController.DrawSwapIcon;
var
  LBox: TRectF;
  LAlpha, LRotation, LScaleX: Single;
  LOn: Boolean;
  LData: string;
begin
  LBox := RectF((Width - IconSide) / 2, (Height - IconSide) / 2, (Width + IconSide) / 2,
    (Height + IconSide) / 2);
  for LOn := False to True do
  begin
    DaisySwapLayer(seRotate, FPos, LOn, LAlpha, LRotation, LScaleX);
    if LAlpha <= 0.01 then
      Continue;
    if LOn then
      LData := CDaisyIconMoon
    else
      LData := CDaisyIconSun;
    DrawPolylines(DaisyTransformIcon(DaisyParseSvgPath(LData), LRotation, LScaleX), LBox,
      DaisyWithAlpha(Tint, LAlpha * IfThen(Enabled, 1.0, 0.3)), 2);
  end;
end;

procedure TDaisyFmxThemeController.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LY: Single;
  LBox: TRectF;
  LFade: Single;
begin
  LY := (Height - TrackHeight) / 2;
  LFade := IfThen(Enabled, 1.0, 0.3);
  case FKind of
    tkToggle:
      begin
        DrawSwitch(CMargin, LY, False);
        DrawCaption(CMargin + TrackWidth);
      end;
    tkToggleIcons:
      begin
        DrawSwitch(CMargin, LY, True);
        DrawCaption(CMargin + TrackWidth);
      end;
    tkSunMoon:
      begin
        LBox := RectF(CMargin, (Height - IconSide) / 2, CMargin + IconSide,
          (Height + IconSide) / 2);
        DrawIconPath(CDaisyIconSun, LBox, DaisyWithAlpha(Theme.BaseContent, LFade));
        DrawSwitch(CMargin + IconSide + 8, LY, False);
        LBox.Offset(IconSide + TrackWidth + 16, 0);
        DrawIconPath(CDaisyIconMoon, LBox, DaisyWithAlpha(Theme.BaseContent, LFade));
      end;
    tkCheckBox:
      begin
        DrawCheckBox(CMargin, (Height - Round(TrackHeight * 0.9)) / 2);
        DrawCaption(CMargin + Round(TrackHeight * 0.9));
      end;
    tkSwap: DrawSwapIcon;
    tkButton: DrawButton;
    tkRadio: DrawRadios;
  end;
end;

end.
