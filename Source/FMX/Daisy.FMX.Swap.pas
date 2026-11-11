unit Daisy.FMX.Swap;

{
  TDaisyFmxSwap - the DaisyUI "swap": two visuals (text, emoji or a 24 x 24 stroke icon) that
  take each other's place when Active changes, with an optional third one for
  Indeterminate. Effect picks the transition: a fade, a 45 degree rotation or a flip
  (rotation and flip move icons; text fades). Variant colours the visuals.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Diagnostics, System.Actions, FMX.ActnList, FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets,
  Daisy.Animation, Daisy.SVG, Daisy.Swap, Daisy.FMX.Control;

type
  TDaisyFmxSwap = class(TDaisyControl)
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
    procedure SetActive(const AValue: Boolean);
    procedure SetIndeterminate(const AValue: Boolean);
    procedure SetEffect(const AValue: TDaisySwapEffect);
    procedure SetOnText(const AValue: string);
    procedure SetOffText(const AValue: string);
    procedure SetIndeterminateText(const AValue: string);
    procedure SetOnIcon(const AValue: string);
    procedure SetOffIcon(const AValue: string);
    procedure SetIndeterminateIcon(const AValue: string);
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
    procedure ActionChange(Sender: TBasicAction; CheckDefaults: Boolean); override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
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

{ TDaisyFmxSwap }

constructor TDaisyFmxSwap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Position.X, Position.Y, 64, 32);
end;

destructor TDaisyFmxSwap.Destroy;
begin
  StopAnimation;
  inherited Destroy;
end;

function TDaisyFmxSwap.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxSwap.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyFmxSwap.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxSwap.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxSwap.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxSwap.MoveVisuals;
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
  if (csLoading in ComponentState) or (csDesigning in ComponentState) then
  begin
    FPos := FTarget;
    FInd := FIndTarget;
    Repaint;
    Exit;
  end;
  FStart := TStopwatch.GetTimeStamp;
  FAnimating := True;
  DaisyAnimationClock.AddListener(Tick);
end;

procedure TDaisyFmxSwap.StopAnimation;
begin
  if FAnimating then
  begin
    FAnimating := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisyFmxSwap.Tick(Sender: TObject);
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
  Repaint;
end;

procedure TDaisyFmxSwap.Changed;
begin
  MoveVisuals;
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyFmxSwap.SetActive(const AValue: Boolean);
begin
  if (FActive <> AValue) or FIndeterminate then
  begin
    FActive := AValue;
    FIndeterminate := False;
    Changed;
    if ActionClient and (Action is TCustomAction) then
      TCustomAction(Action).Checked := FActive;
  end;
end;

procedure TDaisyFmxSwap.ActionChange(Sender: TBasicAction; CheckDefaults: Boolean);
begin
  inherited ActionChange(Sender, CheckDefaults);
  if (Sender is TCustomAction) and ((not CheckDefaults) or (not FActive)) then
    SetActive(TCustomAction(Sender).Checked);
end;

procedure TDaisyFmxSwap.SetIndeterminate(const AValue: Boolean);
begin
  if FIndeterminate <> AValue then
  begin
    FIndeterminate := AValue;
    Changed;
  end;
end;

procedure TDaisyFmxSwap.SetEffect(const AValue: TDaisySwapEffect);
begin
  if FEffect <> AValue then
  begin
    FEffect := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSwap.SetOnText(const AValue: string);
begin
  if FOnText <> AValue then
  begin
    FOnText := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSwap.SetOffText(const AValue: string);
begin
  if FOffText <> AValue then
  begin
    FOffText := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSwap.SetIndeterminateText(const AValue: string);
begin
  if FIndeterminateText <> AValue then
  begin
    FIndeterminateText := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSwap.SetOnIcon(const AValue: string);
begin
  if FOnIcon <> AValue then
  begin
    FOnIcon := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSwap.SetOffIcon(const AValue: string);
begin
  if FOffIcon <> AValue then
  begin
    FOffIcon := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSwap.SetIndeterminateIcon(const AValue: string);
begin
  if FIndeterminateIcon <> AValue then
  begin
    FIndeterminateIcon := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSwap.Click;
begin
  inherited Click;
  if Enabled then
    SetActive(not FActive);
end;

procedure TDaisyFmxSwap.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if ((Key = vkSpace) or (KeyChar = ' ')) and Enabled then
  begin
    SetActive(not FActive);
    Key := 0;
    KeyChar := #0;
  end
  else
    inherited KeyDown(Key, KeyChar, Shift);
end;

procedure TDaisyFmxSwap.Loaded;
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

procedure TDaisyFmxSwap.DrawVisual(const AText, AIcon: string; AColor: TAlphaColor; AAlpha,
  ARotation, AScaleX: Single);
var
  LPaths: TDaisyIconPaths;
  LFilled: Boolean;
  LSide: Single;
  LBox: TRectF;
begin
  if AAlpha <= 0.01 then
    Exit;
  AColor := DaisyWithAlpha(AColor, AAlpha);
  if AIcon <> '' then
  begin
    LPaths := TDaisySVG.ToPaths(TDaisySVG.IconPath(AIcon), LFilled);
    if Length(LPaths) = 0 then
      Exit;
    LSide := System.Math.Min(Width, Height) * 0.8;
    LBox := RectF((Width - LSide) / 2, (Height - LSide) / 2, (Width + LSide) / 2,
      (Height + LSide) / 2);
    DrawPolylines(DaisyTransformIcon(LPaths, ARotation, AScaleX), LBox, AColor, 2);
  end
  else if AText <> '' then
    DrawText(AText, RectF(0, 0, Width, Height), AColor, DaisyFontSize(SizeKind), False,
      TTextAlign.Center, TTextAlign.Center, False);
end;

procedure TDaisyFmxSwap.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
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
    DrawText(Name, RectF(0, 0, Width, Height), DaisyWithAlpha(LTint, 0.5), 12, False,
      TTextAlign.Center, TTextAlign.Center, False);
end;

end.
