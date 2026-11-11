unit Daisy.VCL.Swap;

{
  TDaisySwap - the DaisyUI "swap": two visuals (text, emoji or a 24 x 24 stroke icon) that
  take each other's place when Active changes, with an optional third one for
  Indeterminate. Effect picks the transition: a fade, a 45 degree rotation or a flip
  (rotation and flip move icons; text fades). Variant colours the visuals.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Diagnostics, Vcl.Controls, Vcl.ActnList, Daisy.Theme, Daisy.Widgets, Daisy.Animation, Daisy.SVG,
  Daisy.Swap, Daisy.VCL.Control;

type
  TDaisySwap = class(TDaisyControl)
  strict private
    FActive: Boolean;
    FIndeterminate: Boolean;
    FEffect: TDaisySwapEffect;
    FOnText, FOffText, FIndeterminateText: string;
    FOnIcon, FOffIcon, FIndeterminateIcon: string;
    FPos, FFrom, FTarget: Single;
    FInd, FIndFrom, FIndTarget: Single;
    FStart: Int64;
    FAnimating: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetActive(const Value: Boolean);
    procedure SetIndeterminate(const Value: Boolean);
    procedure SetEffect(const Value: TDaisySwapEffect);
    procedure SetOnText(const Value: string);
    procedure SetOffText(const Value: string);
    procedure SetIndeterminateText(const Value: string);
    procedure SetOnIcon(const Value: string);
    procedure SetOffIcon(const Value: string);
    procedure SetIndeterminateIcon(const Value: string);
    procedure Changed;
    procedure MoveVisuals;
    procedure Tick(Sender: TObject);
    procedure StopAnimation;
    procedure DrawVisual(const AText, AIcon: string; AColor: TAlphaColor; AAlpha, ARotation,
      AScaleX: Single);
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure Loaded; override;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Action;
    // True shows the "on" visual
    property Active: Boolean read FActive write SetActive default False;
    // Shows the indeterminate visual; the next click makes the swap active
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    property Effect: TDaisySwapEffect read FEffect write SetEffect default seFade;
    // Text or emoji of the three visuals; an icon, when set, is drawn instead
    property OnText: string read FOnText write SetOnText;
    property OffText: string read FOffText write SetOffText;
    property IndeterminateText: string read FIndeterminateText write SetIndeterminateText;
    // Icon data: SVG path data (or <svg> markup) of a 24 x 24 stroke icon
    property OnIcon: string read FOnIcon write SetOnIcon;
    property OffIcon: string read FOffIcon write SetOffIcon;
    property IndeterminateIcon: string read FIndeterminateIcon write SetIndeterminateIcon;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CSwapSeconds = 0.2;

{ TDaisySwap }

constructor TDaisySwap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Left, Top, 64, 32);
end;

destructor TDaisySwap.Destroy;
begin
  StopAnimation;
  inherited Destroy;
end;

function TDaisySwap.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisySwap.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisySwap.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisySwap.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisySwap.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisySwap.MoveVisuals;
begin
  StopAnimation;
  FFrom := FPos;
  FIndFrom := FInd;
  if FActive then
    FTarget := 1
  else
    FTarget := 0;
  if FIndeterminate then
    FIndTarget := 1
  else
    FIndTarget := 0;
  if (csLoading in ComponentState) or (csDesigning in ComponentState) or not HandleAllocated then
  begin
    FPos := FTarget;
    FInd := FIndTarget;
    Invalidate;
    Exit;
  end;
  FStart := TStopwatch.GetTimeStamp;
  FAnimating := True;
  DaisyAnimationClock.AddListener(Tick);
end;

procedure TDaisySwap.StopAnimation;
begin
  if FAnimating then
  begin
    FAnimating := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisySwap.Tick(Sender: TObject);
var
  LT: Double;
begin
  LT := (TStopwatch.GetTimeStamp - FStart) / TStopwatch.Frequency / CSwapSeconds;
  if LT >= 1 then
  begin
    FPos := FTarget;
    FInd := FIndTarget;
    StopAnimation;
  end
  else
  begin
    LT := 1 - Power(1 - LT, 3);
    FPos := FFrom + (FTarget - FFrom) * LT;
    FInd := FIndFrom + (FIndTarget - FIndFrom) * LT;
  end;
  Invalidate;
end;

procedure TDaisySwap.Changed;
begin
  MoveVisuals;
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisySwap.SetActive(const Value: Boolean);
begin
  if (FActive <> Value) or FIndeterminate then
  begin
    FActive := Value;
    FIndeterminate := False;
    Changed;
    if (Action is TCustomAction) and (TCustomAction(Action).Checked <> FActive) then
      TCustomAction(Action).Checked := FActive;
  end;
end;

procedure TDaisySwap.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited ActionChange(Sender, CheckDefaults);
  if (Sender is TCustomAction) and ((not CheckDefaults) or (not FActive)) then
    SetActive(TCustomAction(Sender).Checked);
end;

procedure TDaisySwap.SetIndeterminate(const Value: Boolean);
begin
  if FIndeterminate <> Value then
  begin
    FIndeterminate := Value;
    Changed;
  end;
end;

procedure TDaisySwap.SetEffect(const Value: TDaisySwapEffect);
begin
  if FEffect <> Value then
  begin
    FEffect := Value;
    Invalidate;
  end;
end;

procedure TDaisySwap.SetOnText(const Value: string);
begin
  if FOnText <> Value then
  begin
    FOnText := Value;
    Invalidate;
  end;
end;

procedure TDaisySwap.SetOffText(const Value: string);
begin
  if FOffText <> Value then
  begin
    FOffText := Value;
    Invalidate;
  end;
end;

procedure TDaisySwap.SetIndeterminateText(const Value: string);
begin
  if FIndeterminateText <> Value then
  begin
    FIndeterminateText := Value;
    Invalidate;
  end;
end;

procedure TDaisySwap.SetOnIcon(const Value: string);
begin
  if FOnIcon <> Value then
  begin
    FOnIcon := Value;
    Invalidate;
  end;
end;

procedure TDaisySwap.SetOffIcon(const Value: string);
begin
  if FOffIcon <> Value then
  begin
    FOffIcon := Value;
    Invalidate;
  end;
end;

procedure TDaisySwap.SetIndeterminateIcon(const Value: string);
begin
  if FIndeterminateIcon <> Value then
  begin
    FIndeterminateIcon := Value;
    Invalidate;
  end;
end;

procedure TDaisySwap.Click;
begin
  inherited Click;
  if Enabled then
    SetActive(not FActive);
end;

procedure TDaisySwap.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and Enabled then
  begin
    SetActive(not FActive);
    Key := 0;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure TDaisySwap.Loaded;
begin
  inherited;
  StopAnimation;
  if FActive then
    FPos := 1
  else
    FPos := 0;
  if FIndeterminate then
    FInd := 1
  else
    FInd := 0;
end;

procedure TDaisySwap.DrawVisual(const AText, AIcon: string; AColor: TAlphaColor; AAlpha,
  ARotation, AScaleX: Single);
var
  LGraphics: TGPGraphics;
  LPaths: TDaisyIconPaths;
  LFilled: Boolean;
  LSide: Single;
  LBox: TRectF;
  LRect: TRect;
begin
  if AAlpha <= 0.01 then
    Exit;
  AColor := DaisyWithAlpha(AColor, AAlpha);
  if AIcon <> '' then
  begin
    LPaths := TDaisySVG.ToPaths(TDaisySVG.IconPath(AIcon), LFilled);
    if Length(LPaths) = 0 then
      Exit;
    LSide := System.Math.Min(ClientWidth, ClientHeight) * 0.8;
    LBox := RectF((ClientWidth - LSide) / 2, (ClientHeight - LSide) / 2,
      (ClientWidth + LSide) / 2, (ClientHeight + LSide) / 2);
    LGraphics := NewGraphics;
    try
      DrawPolylines(LGraphics, DaisyTransformIcon(LPaths, ARotation, AScaleX), LBox, AColor, 2);
    finally
      LGraphics.Free;
    end;
  end
  else if AText <> '' then
  begin
    LRect := Rect(0, 0, ClientWidth, ClientHeight);
    DrawRichText(AText, LRect, AColor, DaisyFontSize(SizeKind), False,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
end;

procedure TDaisySwap.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LTint: TAlphaColor;
  LAlpha, LRotation, LScaleX, LFade: Single;
begin
  if Variant = dvDefault then
    LTint := Theme.BaseContent
  else
    LTint := DaisyVariantPalette(Theme, Variant).Fill;
  if not Enabled then
    LTint := DaisyWithAlpha(LTint, 0.3);
  LFade := 1 - FInd;

  DaisySwapLayer(FEffect, FPos, False, LAlpha, LRotation, LScaleX);
  DrawVisual(FOffText, FOffIcon, LTint, LAlpha * LFade, LRotation, LScaleX);
  DaisySwapLayer(FEffect, FPos, True, LAlpha, LRotation, LScaleX);
  DrawVisual(FOnText, FOnIcon, LTint, LAlpha * LFade, LRotation, LScaleX);
  DrawVisual(FIndeterminateText, FIndeterminateIcon, LTint, FInd, 0, 1);

  if (csDesigning in ComponentState) and (FOnText = '') and (FOffText = '') and (FOnIcon = '')
    and (FOffIcon = '') then
    DrawRichText(Name, Rect(0, 0, ClientWidth, ClientHeight), DaisyWithAlpha(LTint, 0.5), 12,
      False, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

end.
