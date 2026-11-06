unit Daisy.VCL.ThemeController;

{
  TDaisyThemeController - the DaisyUI "theme controller": a control that switches the theme of
  the whole application. Unchecked it applies UncheckedTheme, checked it applies
  CheckedTheme. Kind picks the look: a toggle (also with icons), a check box, a sun / moon swap,
  a button or a pair of radio buttons. The controller follows theme changes made elsewhere
  (for example by a TDaisyFormStyler), so it always shows the theme that is current.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Diagnostics, Vcl.Controls, Daisy.Theme, Daisy.Widgets, Daisy.Animation, Daisy.Swap,
  Daisy.ThemeController, Daisy.VCL.Control;

type
  TDaisyThemeController = class(TDaisyControl)
  strict private
    FKind: TDaisyThemeControllerKind;
    FChecked: Boolean;
    FCheckedTheme: TDaisyThemeKind;
    FUncheckedTheme: TDaisyThemeKind;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FSyncing: Boolean;
    FDownY: Integer;
    FPos, FFrom, FTarget: Single;
    FStart: Int64;
    FAnimating: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetKind(const Value: TDaisyThemeControllerKind);
    procedure SetChecked(const Value: Boolean);
    procedure SetCheckedTheme(const Value: TDaisyThemeKind);
    procedure SetUncheckedTheme(const Value: TDaisyThemeKind);
    procedure SetAutoFit(const Value: Boolean);
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    function ThemeFor(AChecked: Boolean): TDaisyThemeKind;
    procedure GlobalThemeChanged(Sender: TObject);
    procedure SyncChecked(AValue: Boolean);
    procedure MoveKnob;
    procedure Tick(Sender: TObject);
    procedure StopAnimation;
    function TrackHeight: Integer;
    function TrackWidth: Integer;
    function IconSide: Integer;
    function Margin: Integer;
    function RowHeight: Integer;
    function CaptionWidth: Integer;
    function RadioWidth: Integer;
    function ButtonWidth: Integer;
    function Tint: TAlphaColor;
    procedure UpdateSize;
    procedure DrawSwitch(AX, AY: Single; AIcons: Boolean);
    procedure DrawCheckBox(AX, AY: Single);
    procedure DrawRadios;
    procedure DrawButton;
    procedure DrawSwapIcon;
    procedure DrawCaption(AX: Integer);
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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
    property Caption: string read GetCaption write SetCaption;
    // The size follows Kind, SizeKind and Caption; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CTrackHeights: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
  CSlideSeconds = 0.18;
  CCheckPath = 'M5 12l5 5l10 -10';

{ TDaisyThemeController }

constructor TDaisyThemeController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKind := tkToggle;
  FCheckedTheme := dtDim;
  FUncheckedTheme := dtCorporate;
  FAutoFit := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Left, Top, 52, 28);
  UpdateSize;
  if not (csDesigning in ComponentState) then
    DaisyThemes.AddListener(GlobalThemeChanged);
end;

destructor TDaisyThemeController.Destroy;
begin
  DaisyRemoveThemeListener(GlobalThemeChanged);
  StopAnimation;
  inherited Destroy;
end;

function TDaisyThemeController.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyThemeController.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyThemeController.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyThemeController.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyThemeController.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyThemeController.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyThemeController.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyThemeController.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
  Invalidate;
end;

procedure TDaisyThemeController.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
end;

function TDaisyThemeController.ThemeFor(AChecked: Boolean): TDaisyThemeKind;
begin
  if AChecked then
    Result := FCheckedTheme
  else
    Result := FUncheckedTheme;
end;

// Follows a theme change made by someone else, without applying anything
procedure TDaisyThemeController.GlobalThemeChanged(Sender: TObject);
var
  LCurrent: TDaisyThemeKind;
begin
  LCurrent := DaisyThemes.Current;
  if LCurrent = FCheckedTheme then
    SyncChecked(True)
  else if LCurrent = FUncheckedTheme then
    SyncChecked(False);
end;

procedure TDaisyThemeController.SyncChecked(AValue: Boolean);
begin
  FSyncing := True;
  try
    SetChecked(AValue);
  finally
    FSyncing := False;
  end;
end;

procedure TDaisyThemeController.MoveKnob;
begin
  StopAnimation;
  FFrom := FPos;
  if FChecked then
    FTarget := 1
  else
    FTarget := 0;
  if (csLoading in ComponentState) or (csDesigning in ComponentState) or not HandleAllocated then
  begin
    FPos := FTarget;
    Invalidate;
    Exit;
  end;
  FStart := TStopwatch.GetTimeStamp;
  FAnimating := True;
  DaisyAnimationClock.AddListener(Tick);
end;

procedure TDaisyThemeController.StopAnimation;
begin
  if FAnimating then
  begin
    FAnimating := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisyThemeController.Tick(Sender: TObject);
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
  Invalidate;
end;

procedure TDaisyThemeController.SetChecked(const Value: Boolean);
begin
  if FChecked = Value then
    Exit;
  FChecked := Value;
  MoveKnob;
  UpdateSize;
  if not FSyncing and not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    DaisyThemes.Current := ThemeFor(FChecked);
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyThemeController.SetKind(const Value: TDaisyThemeControllerKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyThemeController.SetCheckedTheme(const Value: TDaisyThemeKind);
begin
  if FCheckedTheme <> Value then
  begin
    FCheckedTheme := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyThemeController.SetUncheckedTheme(const Value: TDaisyThemeKind);
begin
  if FUncheckedTheme <> Value then
  begin
    FUncheckedTheme := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyThemeController.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyThemeController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDownY := Y;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDaisyThemeController.Click;
begin
  inherited Click;
  if not Enabled then
    Exit;
  if FKind = tkRadio then
    SetChecked(FDownY >= Margin + RowHeight + ScaleValue(4))
  else
    SetChecked(not FChecked);
end;

procedure TDaisyThemeController.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and Enabled then
  begin
    SetChecked(not FChecked);
    Key := 0;
  end
  else
    inherited KeyDown(Key, Shift);
end;

function TDaisyThemeController.TrackHeight: Integer;
begin
  Result := ScaleValue(CTrackHeights[SizeKind]);
end;

function TDaisyThemeController.TrackWidth: Integer;
begin
  Result := 2 * TrackHeight - ScaleValue(4);
end;

function TDaisyThemeController.IconSide: Integer;
begin
  if FKind = tkSwap then
    Result := Round(TrackHeight * 1.5)
  else
    Result := Round(TrackHeight * 0.8);
end;

function TDaisyThemeController.Margin: Integer;
begin
  Result := ScaleValue(3);
end;

function TDaisyThemeController.RowHeight: Integer;
begin
  Result := TrackHeight;
end;

function TDaisyThemeController.CaptionWidth: Integer;
begin
  if Caption = '' then
    Result := 0
  else
    Result := ScaleValue(8) + MeasureTextWidth(Caption, DaisyFontSize(SizeKind), False) + ScaleValue(2);
end;

function TDaisyThemeController.RadioWidth: Integer;
begin
  Result := Max(MeasureTextWidth(DaisyThemeControllerCaption(FUncheckedTheme),
    DaisyFontSize(SizeKind), False),
    MeasureTextWidth(DaisyThemeControllerCaption(FCheckedTheme), DaisyFontSize(SizeKind), False));
end;

function TDaisyThemeController.ButtonWidth: Integer;
begin
  Result := RadioWidth + 2 * ScaleValue(16);
end;

function TDaisyThemeController.Tint: TAlphaColor;
var
  LPalette: TDaisyPalette;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    Result := LPalette.Fill;
  end;
end;

procedure TDaisyThemeController.UpdateSize;
var
  LWidth, LHeight: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := TrackHeight + 2 * Margin;
  case FKind of
    tkToggle, tkToggleIcons:
      LWidth := TrackWidth + 2 * Margin + CaptionWidth;
    tkSunMoon:
      LWidth := TrackWidth + 2 * IconSide + 2 * ScaleValue(8) + 2 * Margin;
    tkCheckBox:
      LWidth := Round(TrackHeight * 0.9) + 2 * Margin + CaptionWidth;
    tkSwap:
      begin
        LWidth := IconSide + 2 * Margin;
        LHeight := LWidth;
      end;
    tkButton:
      begin
        LWidth := ButtonWidth;
        LHeight := ScaleValue(DaisyFieldHeight(SizeKind));
      end;
  else
    LWidth := Round(TrackHeight * 0.75) + ScaleValue(8) + RadioWidth + 2 * Margin;
    LHeight := 2 * RowHeight + ScaleValue(4) + 2 * Margin;
  end;
  FUpdating := True;
  try
    SetBounds(Left, Top, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyThemeController.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyThemeController.Loaded;
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

procedure TDaisyThemeController.DrawCaption(AX: Integer);
var
  LText: TRect;
begin
  if Caption = '' then
    Exit;
  LText := Rect(AX + ScaleValue(8), 0, ClientWidth, ClientHeight);
  DrawRichText(Caption, LText, DaisyWithAlpha(Theme.BaseContent, IfThen(Enabled, 1.0, 0.3)),
    DaisyFontSize(SizeKind), False, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
end;

procedure TDaisyThemeController.DrawSwitch(AX, AY: Single; AIcons: Boolean);
var
  LGraphics: TGPGraphics;
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

  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LTrack, LH / 2, DaisyWithAlpha(LTrackFill, LFade));
    StrokeRoundRect(LGraphics, LTrack, LH / 2, DaisyWithAlpha(LBorder, LFade),
      System.Math.Max(1, ScaleValue(Theme.BorderWidth)), False);
  finally
    LGraphics.Free;
  end;

  if AIcons then
  begin
    LIconColor := DaisyWithAlpha(DaisyMix(Theme.BaseContent, Theme.Base100, FPos), LFade);
    LDia := LH - 2 * LInset;
    LBox := RectF(LTrack.Left + LInset + LDia * 0.2, LKnobY + LDia * 0.2,
      LTrack.Left + LInset + LDia * 0.8, LKnobY + LDia * 0.8);
    DrawIconPath(CDaisyIconSun, LBox, LIconColor);
    LBox.Offset(LW - LH, 0);
    DrawIconPath(CDaisyIconMoon, LBox, LIconColor);
  end;

  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, RectF(LKnobX, LKnobY, LKnobX + LDia, LKnobY + LDia), LDia / 2,
      DaisyWithAlpha(LKnob, LFade));
    if Focused then
    begin
      LBox := LTrack;
      LBox.Inflate(ScaleValue(2), ScaleValue(2));
      StrokeRoundRect(LGraphics, LBox, LBox.Height / 2,
        DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade), ScaleValue(1), False);
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure TDaisyThemeController.DrawCheckBox(AX, AY: Single);
var
  LGraphics: TGPGraphics;
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
  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LBox, Theme.RadiusSelector, DaisyWithAlpha(LFill, LFade));
    StrokeRoundRect(LGraphics, LBox, Theme.RadiusSelector, DaisyWithAlpha(LBorder, LFade),
      System.Math.Max(1, ScaleValue(Theme.BorderWidth)), False);
    if Focused then
    begin
      LBox.Inflate(ScaleValue(2), ScaleValue(2));
      StrokeRoundRect(LGraphics, LBox, Theme.RadiusSelector + 2,
        DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade), ScaleValue(1), False);
      LBox.Inflate(-ScaleValue(2), -ScaleValue(2));
    end;
  finally
    LGraphics.Free;
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

procedure TDaisyThemeController.DrawRadios;
var
  LGraphics: TGPGraphics;
  LCircle: TRectF;
  LText: TRect;
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
    LTop := Margin + I * (RowHeight + ScaleValue(4));
    LCircle := RectF(Margin, LTop + (RowHeight - LSide) / 2, Margin + LSide,
      LTop + (RowHeight + LSide) / 2);
    if LSelected then
      LBorder := LTint
    else
      LBorder := DaisyMix(Theme.Base100, Theme.BaseContent, 0.5);
    LGraphics := NewGraphics;
    try
      FillRoundRect(LGraphics, LCircle, LSide / 2, DaisyWithAlpha(Theme.Base100, LFade));
      StrokeRoundRect(LGraphics, LCircle, LSide / 2, DaisyWithAlpha(LBorder, LFade),
        System.Math.Max(1, ScaleValue(Theme.BorderWidth)), False);
      if LSelected then
      begin
        LCircle.Inflate(-LSide * 0.25, -LSide * 0.25);
        FillRoundRect(LGraphics, LCircle, LCircle.Width / 2, DaisyWithAlpha(LTint, LFade));
      end;
    finally
      LGraphics.Free;
    end;
    LText := Rect(Margin + Round(LSide) + ScaleValue(8), Round(LTop),
      ClientWidth, Round(LTop) + RowHeight);
    DrawRichText(DaisyThemeControllerCaption(ThemeFor(I = 1)), LText,
      DaisyWithAlpha(Theme.BaseContent, LFade), DaisyFontSize(SizeKind), False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;
end;

procedure TDaisyThemeController.DrawButton;
var
  LGraphics: TGPGraphics;
  LBody: TRectF;
  LFade: Single;
begin
  LFade := IfThen(Enabled, 1.0, 0.3);
  LBody := RectF(0, 0, ClientWidth, ClientHeight);
  LBody.Inflate(-0.5, -0.5);
  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LBody, Theme.RadiusField,
      DaisyWithAlpha(DaisyMix(Theme.Base200, Theme.BaseContent, IfThen(Hot, 0.06, 0.0)), LFade));
    StrokeRoundRect(LGraphics, LBody, Theme.RadiusField, DaisyWithAlpha(Theme.Base300, LFade),
      System.Math.Max(1, ScaleValue(Theme.BorderWidth)), False);
  finally
    LGraphics.Free;
  end;
  DrawRichText(DaisyThemeControllerCaption(ThemeFor(FChecked)),
    Rect(0, 0, ClientWidth, ClientHeight), DaisyWithAlpha(Theme.BaseContent, LFade),
    DaisyFontSize(SizeKind), False, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

procedure TDaisyThemeController.DrawSwapIcon;
var
  LGraphics: TGPGraphics;
  LPaths: TDaisyIconPaths;
  LBox: TRectF;
  LAlpha, LRotation, LScaleX: Single;
  LColor: TAlphaColor;
  LOn: Boolean;
  LData: string;
begin
  LBox := RectF((ClientWidth - IconSide) / 2, (ClientHeight - IconSide) / 2,
    (ClientWidth + IconSide) / 2, (ClientHeight + IconSide) / 2);
  for LOn := False to True do
  begin
    DaisySwapLayer(seRotate, FPos, LOn, LAlpha, LRotation, LScaleX);
    if LAlpha <= 0.01 then
      Continue;
    if LOn then
      LData := CDaisyIconMoon
    else
      LData := CDaisyIconSun;
    LColor := DaisyWithAlpha(Tint, LAlpha * IfThen(Enabled, 1.0, 0.3));
    LPaths := DaisyTransformIcon(DaisyParseSvgPath(LData), LRotation, LScaleX);
    LGraphics := NewGraphics;
    try
      DrawPolylines(LGraphics, LPaths, LBox, LColor, 2);
    finally
      LGraphics.Free;
    end;
  end;
end;

procedure TDaisyThemeController.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LY: Single;
  LBox: TRectF;
  LFade: Single;
begin
  LY := (ClientHeight - TrackHeight) / 2;
  LFade := IfThen(Enabled, 1.0, 0.3);
  case FKind of
    tkToggle:
      begin
        DrawSwitch(Margin, LY, False);
        DrawCaption(Margin + TrackWidth);
      end;
    tkToggleIcons:
      begin
        DrawSwitch(Margin, LY, True);
        DrawCaption(Margin + TrackWidth);
      end;
    tkSunMoon:
      begin
        LBox := RectF(Margin, (ClientHeight - IconSide) / 2, Margin + IconSide,
          (ClientHeight + IconSide) / 2);
        DrawIconPath(CDaisyIconSun, LBox, DaisyWithAlpha(Theme.BaseContent, LFade));
        DrawSwitch(Margin + IconSide + ScaleValue(8), LY, False);
        LBox.Offset(IconSide + TrackWidth + 2 * ScaleValue(8), 0);
        DrawIconPath(CDaisyIconMoon, LBox, DaisyWithAlpha(Theme.BaseContent, LFade));
      end;
    tkCheckBox:
      begin
        DrawCheckBox(Margin, (ClientHeight - Round(TrackHeight * 0.9)) / 2);
        DrawCaption(Margin + Round(TrackHeight * 0.9));
      end;
    tkSwap: DrawSwapIcon;
    tkButton: DrawButton;
    tkRadio: DrawRadios;
  end;
end;

end.
