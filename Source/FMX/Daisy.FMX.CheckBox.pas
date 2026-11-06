unit Daisy.FMX.CheckBox;

{
  TDaisyFmxCheckBox - the DaisyUI "checkbox". A rounded box that fills with the
  Variant colour and shows a tick when Checked, or a dash when Indeterminate.
  SizeKind gives xs..xl and Text puts a caption beside the box.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.FMX.Control;

type
  TDaisyFmxCheckBox = class(TDaisyControl)
  strict private
    FChecked: Boolean;
    FIndeterminate: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FText: string;
    FOnChange: TNotifyEvent;
    procedure SetChecked(const Value: Boolean);
    procedure SetIndeterminate(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure SetText(const Value: string);
    function BoxSize: Single;
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
    procedure Click; override;
    procedure Toggle;
  published
    property Checked: Boolean read FChecked write SetChecked default False;
    // Shows a dash; the next click makes the box checked
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    // Text beside the box
    property Text: string read FText write SetText;
    // The size follows SizeKind and Text; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CBoxSizes: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
  CMargin = 3;
  CCheckPath = 'M5 12.5l4.5 4.5l9.5 -10';
  CDashPath = 'M6 12h12';

{ TDaisyFmxCheckBox }

constructor TDaisyFmxCheckBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Position.X, Position.Y, 28, 28);
  UpdateSize;
end;

function TDaisyFmxCheckBox.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxCheckBox.DrawsFocusRing: Boolean;
begin
  Result := False; // the box outline shows the focus
end;

function TDaisyFmxCheckBox.DefaultCornerRadius: Integer;
begin
  Result := Min(Theme.RadiusSelector, 6);
end;

function TDaisyFmxCheckBox.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxCheckBox.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxCheckBox.Changed;
begin
  Repaint;
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyFmxCheckBox.SetChecked(const Value: Boolean);
begin
  if (FChecked <> Value) or FIndeterminate then
  begin
    FChecked := Value;
    FIndeterminate := False;
    Changed;
  end;
end;

procedure TDaisyFmxCheckBox.SetIndeterminate(const Value: Boolean);
begin
  if FIndeterminate <> Value then
  begin
    FIndeterminate := Value;
    Changed;
  end;
end;

procedure TDaisyFmxCheckBox.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyFmxCheckBox.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxCheckBox.Toggle;
begin
  SetChecked(not FChecked);
end;

// Like TCheckBox, the state has changed by the time OnClick runs
procedure TDaisyFmxCheckBox.Click;
begin
  if Enabled then
    Toggle;
  inherited Click;
end;

procedure TDaisyFmxCheckBox.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if ((Key = vkSpace) or (KeyChar = ' ')) and Enabled then
  begin
    Click;
    Key := 0;
    KeyChar := #0;
  end
  else
    inherited KeyDown(Key, KeyChar, Shift);
end;

function TDaisyFmxCheckBox.BoxSize: Single;
begin
  Result := CBoxSizes[SizeKind];
end;

procedure TDaisyFmxCheckBox.UpdateSize;
var
  LWidth, LHeight: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := BoxSize + 2 * CMargin;
  LWidth := BoxSize + 2 * CMargin;
  if FText <> '' then
    LWidth := LWidth + 8 + MeasureTextWidth(FText, DaisyFontSize(SizeKind), False) + 2;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxCheckBox.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxCheckBox.Loaded;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyFmxCheckBox.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LBox, LMark, LText: TRectF;
  LTint, LOn, LFillColor, LBorder: TAlphaColor;
  LPalette: TDaisyPalette;
  LSize, LFade: Single;
  LMarked: Boolean;
begin
  LSize := BoxSize;
  LBox := RectF(CMargin, (Height - LSize) / 2, CMargin + LSize, (Height - LSize) / 2 + LSize);
  LMarked := FChecked or FIndeterminate;

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
  LFade := 1;
  if not Enabled then
    LFade := 0.3;

  if LMarked then
  begin
    LFillColor := LTint;
    LBorder := LTint;
  end
  else
  begin
    LFillColor := Theme.Base100;
    LBorder := DaisyMix(Theme.Base100, Theme.BaseContent, 0.35);
  end;

  FillRound(LBox, ResolvedCornerRadius, DaisyWithAlpha(LFillColor, LFade));
  StrokeRound(LBox, ResolvedCornerRadius, DaisyWithAlpha(LBorder, LFade),
    Max(1, Theme.BorderWidth), False);
  if IsFocused then
  begin
    LMark := LBox;
    LMark.Inflate(2, 2);
    StrokeRound(LMark, ResolvedCornerRadius + 2, DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade),
      1, False);
  end;

  if LMarked then
  begin
    LMark := LBox;
    LMark.Inflate(-LSize * 0.14, -LSize * 0.14);
    if FIndeterminate then
      DrawIconPath(CDashPath, LMark, DaisyWithAlpha(LOn, LFade))
    else
      DrawIconPath(CCheckPath, LMark, DaisyWithAlpha(LOn, LFade));
  end;

  if FText <> '' then
  begin
    LText := RectF(LBox.Right + 8, 0, Width, Height);
    DrawText(FText, LText, DaisyWithAlpha(Theme.BaseContent, LFade), DaisyFontSize(SizeKind),
      False, TTextAlign.Leading, TTextAlign.Center, False);
  end;
end;

end.
