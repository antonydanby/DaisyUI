unit Daisy.FMX.Toggle;

{
  TDaisyFmxToggle - the DaisyUI "toggle": an on / off switch. The knob slides when
  Checked changes; Indeterminate parks it in the middle. Variant colours the
  "on" state, SizeKind gives xs..xl, ShowIcons draws a cross / tick in the knob
  and Text puts a caption beside the switch.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Diagnostics, FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets,
  Daisy.Animation, Daisy.FMX.Control;

type
  TDaisyFmxToggle = class(TDaisyControl)
  strict private
    FChecked: Boolean;
    FIndeterminate: Boolean;
    FShowIcons: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FText: string;
    FPos: Single;
    FFrom: Single;
    FTarget: Single;
    FStart: Int64;
    FAnimating: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetChecked(const Value: Boolean);
    procedure SetIndeterminate(const Value: Boolean);
    procedure SetShowIcons(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure SetText(const Value: string);
    function TargetPos: Single;
    procedure MoveKnob;
    procedure Tick(Sender: TObject);
    procedure StopAnimation;
    function TrackHeight: Single;
    function TrackWidth: Single;
    procedure UpdateSize;
    procedure Changed;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    procedure Toggle;
  published
    property Checked: Boolean read FChecked write SetChecked default False;
    // Knob in the middle; the next click makes it checked
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    // Text beside the switch
    property Text: string read FText write SetText;
    // Draws a cross (off) or tick (on) inside the knob
    property ShowIcons: Boolean read FShowIcons write SetShowIcons default False;
    // The size follows SizeKind and Text; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CTrackHeights: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
  CSlideSeconds = 0.16;
  CMargin = 3;
  CCheckPath = 'M5 12l5 5l10 -10';
  CCrossPath = 'M6 6l12 12M18 6l-12 12';

{ TDaisyFmxToggle }

constructor TDaisyFmxToggle.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Position.X, Position.Y, 52, 28);
  UpdateSize;
end;

destructor TDaisyFmxToggle.Destroy;
begin
  StopAnimation;
  inherited Destroy;
end;

function TDaisyFmxToggle.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxToggle.DrawsFocusRing: Boolean;
begin
  Result := False; // the track outline shows the focus
end;

function TDaisyFmxToggle.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusSelector;
end;

function TDaisyFmxToggle.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxToggle.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxToggle.TargetPos: Single;
begin
  if FIndeterminate then
    Result := 0.5
  else if FChecked then
    Result := 1
  else
    Result := 0;
end;

procedure TDaisyFmxToggle.MoveKnob;
begin
  if (csLoading in ComponentState) or (csDesigning in ComponentState) then
  begin
    StopAnimation;
    FPos := TargetPos;
    Repaint;
    Exit;
  end;
  FFrom := FPos;
  FTarget := TargetPos;
  FStart := TStopwatch.GetTimeStamp;
  if not FAnimating then
  begin
    FAnimating := True;
    DaisyAnimationClock.AddListener(Tick);
  end;
end;

procedure TDaisyFmxToggle.StopAnimation;
begin
  if FAnimating then
  begin
    FAnimating := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisyFmxToggle.Tick(Sender: TObject);
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

procedure TDaisyFmxToggle.Changed;
begin
  MoveKnob;
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyFmxToggle.SetChecked(const Value: Boolean);
begin
  if (FChecked <> Value) or FIndeterminate then
  begin
    FChecked := Value;
    FIndeterminate := False;
    Changed;
  end;
end;

procedure TDaisyFmxToggle.SetIndeterminate(const Value: Boolean);
begin
  if FIndeterminate <> Value then
  begin
    FIndeterminate := Value;
    Changed;
  end;
end;

procedure TDaisyFmxToggle.SetShowIcons(const Value: Boolean);
begin
  if FShowIcons <> Value then
  begin
    FShowIcons := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxToggle.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyFmxToggle.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxToggle.Toggle;
begin
  SetChecked(not FChecked);
end;

procedure TDaisyFmxToggle.Click;
begin
  inherited Click;
  if Enabled then
    Toggle;
end;

procedure TDaisyFmxToggle.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if ((Key = vkSpace) or (KeyChar = ' ')) and Enabled then
  begin
    Toggle;
    Key := 0;
    KeyChar := #0;
  end
  else
    inherited KeyDown(Key, KeyChar, Shift);
end;

function TDaisyFmxToggle.TrackHeight: Single;
begin
  Result := CTrackHeights[SizeKind];
end;

function TDaisyFmxToggle.TrackWidth: Single;
begin
  Result := 2 * TrackHeight - 4;
end;

procedure TDaisyFmxToggle.UpdateSize;
var
  LWidth, LHeight: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := TrackHeight + 2 * CMargin;
  LWidth := TrackWidth + 2 * CMargin;
  if FText <> '' then
    LWidth := LWidth + 8 + MeasureTextWidth(FText, DaisyFontSize(SizeKind), False) + 2;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxToggle.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxToggle.Loaded;
begin
  inherited;
  FPos := TargetPos;
  UpdateSize;
end;

procedure TDaisyFmxToggle.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LTrack, LBox, LText: TRectF;
  LTint, LOn, LOffFill, LTrackFill, LBorder, LKnob, LIconColor: TAlphaColor;
  LPalette: TDaisyPalette;
  LH, LW, LInset, LDia, LKnobX, LKnobY, LFade: Single;
begin
  LH := TrackHeight;
  LW := TrackWidth;
  LTrack := RectF(CMargin, (Height - LH) / 2, CMargin + LW, (Height - LH) / 2 + LH);

  if Variant = dvDefault then
  begin
    LTint := Theme.BaseContent;
    LOn := Theme.Base100;
  end
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    LTint := LPalette.Fill;
    LOn := LPalette.Content;
  end;
  LOffFill := DaisyMix(Theme.Base100, Theme.BaseContent, 0.5);
  LTrackFill := DaisyMix(Theme.Base100, LTint, FPos);
  LBorder := DaisyMix(LOffFill, LTint, FPos);
  LKnob := DaisyMix(LOffFill, LOn, FPos);
  LFade := 1;
  if not Enabled then
    LFade := 0.3;

  LInset := Max(2, LH / 8);
  LDia := LH - 2 * LInset;
  LKnobX := LTrack.Left + LInset + (LW - LH) * FPos;
  LKnobY := LTrack.Top + LInset;

  FillRound(LTrack, LH / 2, DaisyWithAlpha(LTrackFill, LFade));
  StrokeRound(LTrack, LH / 2, DaisyWithAlpha(LBorder, LFade), Max(1, Theme.BorderWidth), False);
  FillRound(RectF(LKnobX, LKnobY, LKnobX + LDia, LKnobY + LDia), LDia / 2,
    DaisyWithAlpha(LKnob, LFade));
  if IsFocused then
  begin
    LBox := LTrack;
    LBox.Inflate(2, 2);
    StrokeRound(LBox, LBox.Height / 2, DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade), 1, False);
  end;

  if FShowIcons and not FIndeterminate then
  begin
    LBox := RectF(LKnobX + LDia * 0.18, LKnobY + LDia * 0.18, LKnobX + LDia * 0.82,
      LKnobY + LDia * 0.82);
    LIconColor := DaisyWithAlpha(LTrackFill, LFade);
    if FPos >= 0.5 then
      DrawIconPath(CCheckPath, LBox, LIconColor)
    else
      DrawIconPath(CCrossPath, LBox, LIconColor);
  end;

  if FText <> '' then
  begin
    LText := RectF(LTrack.Right + 8, 0, Width, Height);
    DrawText(FText, LText, DaisyWithAlpha(Theme.BaseContent, LFade), DaisyFontSize(SizeKind),
      False, TTextAlign.Leading, TTextAlign.Center, False);
  end;
end;

end.
