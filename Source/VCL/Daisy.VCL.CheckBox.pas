unit Daisy.VCL.CheckBox;

{
  TDaisyCheckBox - the DaisyUI "checkbox". A rounded box that fills with the
  Variant colour and shows a tick when Checked, or a dash when Indeterminate.
  SizeKind gives xs..xl and Caption puts text beside the box.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.ActnList, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control;

type
  TDaisyCheckBox = class(TDaisyControl)
  strict private
    FChecked: Boolean;
    FIndeterminate: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetChecked(const Value: Boolean);
    procedure SetIndeterminate(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    function BoxSize: Integer;
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
    procedure Click; override;
    procedure Toggle;
  published
    property Action;
    property Checked: Boolean read FChecked write SetChecked default False;
    // Shows a dash; the next click makes the box checked
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    // Text beside the box
    property Caption: string read GetCaption write SetCaption;
    // The size follows SizeKind and Caption; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CBoxSizes: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
  CCheckPath = 'M5 12.5l4.5 4.5l9.5 -10';
  CDashPath = 'M6 12h12';

{ TDaisyCheckBox }

constructor TDaisyCheckBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Left, Top, 28, 28);
  UpdateSize;
end;

function TDaisyCheckBox.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyCheckBox.DrawsFocusRing: Boolean;
begin
  Result := False; // the box outline shows the focus
end;

function TDaisyCheckBox.DefaultCornerRadius: Integer;
begin
  Result := Min(Theme.RadiusSelector, 6);
end;

function TDaisyCheckBox.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyCheckBox.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyCheckBox.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyCheckBox.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyCheckBox.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
  Invalidate;
end;

procedure TDaisyCheckBox.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyCheckBox.Changed;
begin
  Invalidate;
  if not (csLoading in ComponentState) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyCheckBox.SetChecked(const Value: Boolean);
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

procedure TDaisyCheckBox.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited ActionChange(Sender, CheckDefaults);
  if (Sender is TCustomAction) and ((not CheckDefaults) or (not FChecked)) then
    SetChecked(TCustomAction(Sender).Checked);
end;

procedure TDaisyCheckBox.SetIndeterminate(const Value: Boolean);
begin
  if FIndeterminate <> Value then
  begin
    FIndeterminate := Value;
    Changed;
  end;
end;

procedure TDaisyCheckBox.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyCheckBox.Toggle;
begin
  SetChecked(not FChecked);
end;

// Like TCheckBox, the state has changed by the time OnClick runs
procedure TDaisyCheckBox.Click;
begin
  if Enabled then
    Toggle;
  inherited Click;
end;

procedure TDaisyCheckBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and Enabled then
  begin
    Click;
    Key := 0;
  end
  else
    inherited KeyDown(Key, Shift);
end;

function TDaisyCheckBox.BoxSize: Integer;
begin
  Result := ScaleValue(CBoxSizes[SizeKind]);
end;

function TDaisyCheckBox.Margin: Integer;
begin
  Result := ScaleValue(3);
end;

procedure TDaisyCheckBox.UpdateSize;
var
  LWidth, LHeight: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := BoxSize + 2 * Margin;
  LWidth := BoxSize + 2 * Margin;
  if Caption <> '' then
    Inc(LWidth, ScaleValue(8) + MeasureTextWidth(Caption, DaisyFontSize(SizeKind), False) + ScaleValue(2));
  FUpdating := True;
  try
    SetBounds(Left, Top, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyCheckBox.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyCheckBox.Loaded;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyCheckBox.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LBox, LMark: TRectF;
  LTint, LOn, LFillColor, LBorder: TAlphaColor;
  LPalette: TDaisyPalette;
  LSize, LFade: Single;
  LOn2: Boolean;
  LText: TRect;
begin
  LSize := BoxSize;
  LBox := RectF(Margin, (ClientHeight - LSize) / 2, Margin + LSize, (ClientHeight - LSize) / 2 + LSize);
  LOn2 := FChecked or FIndeterminate;

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

  if LOn2 then
  begin
    LFillColor := LTint;
    LBorder := LTint;
  end
  else
  begin
    LFillColor := Theme.Base100;
    LBorder := DaisyMix(Theme.Base100, Theme.BaseContent, 0.35);
  end;

  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LBox, ResolvedCornerRadius, DaisyWithAlpha(LFillColor, LFade));
    StrokeRoundRect(LGraphics, LBox, ResolvedCornerRadius, DaisyWithAlpha(LBorder, LFade),
      Max(1, ScaleValue(Theme.BorderWidth)), False);
    if Focused then
    begin
      LMark := LBox;
      LMark.Inflate(ScaleValue(2), ScaleValue(2));
      StrokeRoundRect(LGraphics, LMark, ResolvedCornerRadius + ScaleValue(2),
        DaisyWithAlpha(Theme.BaseContent, 0.45 * LFade), ScaleValue(1), False);
    end;
  finally
    LGraphics.Free;
  end;

  if LOn2 then
  begin
    LMark := LBox;
    LMark.Inflate(-LSize * 0.14, -LSize * 0.14);
    if FIndeterminate then
      DrawIconPath(CDashPath, LMark, DaisyWithAlpha(LOn, LFade))
    else
      DrawIconPath(CCheckPath, LMark, DaisyWithAlpha(LOn, LFade));
  end;

  if Caption <> '' then
  begin
    LText := Rect(Round(LBox.Right) + ScaleValue(8), 0, ClientWidth, ClientHeight);
    DrawRichText(Caption, LText, DaisyWithAlpha(Theme.BaseContent, LFade), DaisyFontSize(SizeKind),
      False, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;
end;

end.
