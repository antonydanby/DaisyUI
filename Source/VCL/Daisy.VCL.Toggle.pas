unit Daisy.VCL.Toggle;

{
  TDaisyToggle - the DaisyUI "toggle": an on / off switch. The knob slides when
  Checked changes; Indeterminate parks it in the middle. Variant colours the
  "on" state, SizeKind gives xs..xl, ShowIcons draws a cross / tick in the knob
  and Caption puts text beside the switch.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Diagnostics, Vcl.Controls, Vcl.ActnList, Daisy.Theme, Daisy.Widgets, Daisy.Animation,
  Daisy.VCL.Control;

type
  TDaisyToggle = class(TDaisyControl)
  strict private
    FChecked: Boolean;
    FIndeterminate: Boolean;
    FShowIcons: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
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
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    function TargetPos: Single;
    procedure MoveKnob;
    procedure Tick(Sender: TObject);
    procedure StopAnimation;
    function TrackHeight: Integer;
    function TrackWidth: Integer;
    function Margin: Integer;
    procedure UpdateSize;
    procedure Changed;
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
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    procedure Toggle;
  published
    property Action;
    property Checked: Boolean read FChecked write SetChecked default False;
    // Knob in the middle; the next click makes it checked
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    // Text beside the switch
    property Caption: string read GetCaption write SetCaption;
    // Draws a cross (off) or tick (on) inside the knob
    property ShowIcons: Boolean read FShowIcons write SetShowIcons default False;
    // The size follows SizeKind and Caption; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CTrackHeights: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
  CSlideSeconds = 0.16;
  CCheckPath = 'M5 12l5 5l10 -10';
  CCrossPath = 'M6 6l12 12M18 6l-12 12';

{ TDaisyToggle }

constructor TDaisyToggle.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Left, Top, 52, 28);
  UpdateSize;
end;

destructor TDaisyToggle.Destroy;
begin
  StopAnimation;
  inherited Destroy;
end;

function TDaisyToggle.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyToggle.DrawsFocusRing: Boolean;
begin
  Result := False; // the track outline shows the focus
end;

function TDaisyToggle.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusSelector;
end;

function TDaisyToggle.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyToggle.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyToggle.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyToggle.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyToggle.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
  Invalidate;
end;

procedure TDaisyToggle.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
end;

function TDaisyToggle.TargetPos: Single;
begin
  if FIndeterminate then
    Result := 0.5
  else if FChecked then
    Result := 1
  else
    Result := 0;
end;

procedure TDaisyToggle.MoveKnob;
begin
  if (csLoading in ComponentState) or (csDesigning in ComponentState) or not HandleAllocated then
  begin
    StopAnimation;
    FPos := TargetPos;
    Invalidate;
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

procedure TDaisyToggle.StopAnimation;
begin
  if FAnimating then
  begin
    FAnimating := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisyToggle.Tick(Sender: TObject);
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

procedure TDaisyToggle.Changed;
begin
  MoveKnob;
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyToggle.SetChecked(const Value: Boolean);
begin
  if (FChecked <> Value) or FIndeterminate then
  begin
    FChecked := Value;
    FIndeterminate := False;
    Changed;
    if (Action is TCustomAction) and (TCustomAction(Action).Checked <> FChecked) then
      TCustomAction(Action).Checked := FChecked;
  end;
end;

procedure TDaisyToggle.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited ActionChange(Sender, CheckDefaults);
  if (Sender is TCustomAction) and ((not CheckDefaults) or (not FChecked)) then
    SetChecked(TCustomAction(Sender).Checked);
end;

procedure TDaisyToggle.SetIndeterminate(const Value: Boolean);
begin
  if FIndeterminate <> Value then
  begin
    FIndeterminate := Value;
    Changed;
  end;
end;

procedure TDaisyToggle.SetShowIcons(const Value: Boolean);
begin
  if FShowIcons <> Value then
  begin
    FShowIcons := Value;
    Invalidate;
  end;
end;

procedure TDaisyToggle.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyToggle.Toggle;
begin
  SetChecked(not FChecked);
end;

procedure TDaisyToggle.Click;
begin
  inherited Click;
  if Enabled then
    Toggle;
end;

procedure TDaisyToggle.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and Enabled then
  begin
    Toggle;
    Key := 0;
  end
  else
    inherited KeyDown(Key, Shift);
end;

function TDaisyToggle.TrackHeight: Integer;
begin
  Result := ScaleValue(CTrackHeights[SizeKind]);
end;

function TDaisyToggle.TrackWidth: Integer;
begin
  Result := 2 * TrackHeight - ScaleValue(4);
end;

function TDaisyToggle.Margin: Integer;
begin
  Result := ScaleValue(3);
end;

procedure TDaisyToggle.UpdateSize;
var
  LWidth, LHeight: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := TrackHeight + 2 * Margin;
  LWidth := TrackWidth + 2 * Margin;
  if Caption <> '' then
    Inc(LWidth, ScaleValue(8) + MeasureTextWidth(Caption, DaisyFontSize(SizeKind), False) + ScaleValue(2));
  FUpdating := True;
  try
    SetBounds(Left, Top, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyToggle.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyToggle.Loaded;
begin
  inherited;
  FPos := TargetPos;
  UpdateSize;
end;

procedure TDaisyToggle.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LTrack: TRectF;
  LTint, LOn, LOffFill, LTrackFill, LBorder, LKnob, LIconColor: TAlphaColor;
  LPalette: TDaisyPalette;
  LH, LW, LInset, LDia, LKnobX, LKnobY: Single;
  LFade: Single;
  LBox: TRectF;
  LText: TRect;
begin
  LH := TrackHeight;
  LW := TrackWidth;
  LTrack := RectF(Margin, (ClientHeight - LH) / 2, Margin + LW, (ClientHeight - LH) / 2 + LH);

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

  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LTrack, LH / 2, DaisyWithAlpha(LTrackFill, LFade));
    StrokeRoundRect(LGraphics, LTrack, LH / 2, DaisyWithAlpha(LBorder, LFade),
      Max(1, ScaleValue(Theme.BorderWidth)), False);
    FillRoundRect(LGraphics, RectF(LKnobX, LKnobY, LKnobX + LDia, LKnobY + LDia), LDia / 2,
      DaisyWithAlpha(LKnob, LFade));
    if Focused then
    begin
      LBox := LTrack;
      LBox.Inflate(ScaleValue(2), ScaleValue(2));
      StrokeRoundRect(LGraphics, LBox, LBox.Height / 2, DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade),
        ScaleValue(1), False);
    end;
  finally
    LGraphics.Free;
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

  if Caption <> '' then
  begin
    LText := Rect(Round(LTrack.Right) + ScaleValue(8), 0, ClientWidth, ClientHeight);
    DrawRichText(Caption, LText, DaisyWithAlpha(Theme.BaseContent, LFade), DaisyFontSize(SizeKind),
      False, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;
end;

end.
