unit Daisy.VCL.Labels;

{
  TDaisyLabel - a themed text label. Unlike TLabel it follows the Daisy theme
  (Variant gives the colour) and draws through Direct2D when the text holds
  emoji, so colour emoji work.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.UITypes,
  System.Math, Vcl.Controls, Vcl.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control,
  Daisy.VCL.Panel;

type
  TDaisyLabel = class(TDaisyControl)
  strict private
    FAlignment: TDaisyTextAlign;
    FVerticalAlignment: TDaisyTextAlign;
    FWordWrap: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FMuted: Boolean;
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure SetAlignment(const Value: TDaisyTextAlign);
    procedure SetVerticalAlignment(const Value: TDaisyTextAlign);
    procedure SetWordWrap(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure SetMuted(const Value: Boolean);
    procedure UpdateSize;
    function TextColor: TAlphaColor;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption: string read GetCaption write SetCaption;
    property Alignment: TDaisyTextAlign read FAlignment write SetAlignment default taStart;
    property VerticalAlignment: TDaisyTextAlign read FVerticalAlignment write SetVerticalAlignment default taStart;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
    // The size follows the text; with WordWrap only the height follows
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    // Draws the text at 60% strength, like secondary text
    property Muted: Boolean read FMuted write SetMuted default False;
  end;

implementation

{ TDaisyLabel }

constructor TDaisyLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  SetBounds(Left, Top, 64, 20);
  Caption := 'Label';
end;

function TDaisyLabel.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyLabel.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyLabel.SetAlignment(const Value: TDaisyTextAlign);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TDaisyLabel.SetVerticalAlignment(const Value: TDaisyTextAlign);
begin
  if FVerticalAlignment <> Value then
  begin
    FVerticalAlignment := Value;
    Invalidate;
  end;
end;

procedure TDaisyLabel.SetWordWrap(const Value: Boolean);
begin
  if FWordWrap <> Value then
  begin
    FWordWrap := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyLabel.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyLabel.SetMuted(const Value: Boolean);
begin
  if FMuted <> Value then
  begin
    FMuted := Value;
    Invalidate;
  end;
end;

function TDaisyLabel.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyLabel.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyLabel.TextColor: TAlphaColor;
begin
  if (Variant = dvDefault) and (Parent is TDaisyPanel) then
    Result := TDaisyPanel(Parent).ResolvedTextColor
  else if Variant = dvDefault then
    Result := Theme.BaseContent
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
  if FMuted then
    Result := DaisyWithAlpha(Result, 0.6);
  if not Enabled then
    Result := DaisyWithAlpha(Theme.BaseContent, 0.3);
end;

function TDaisyLabel.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := TextColor;
end;

procedure TDaisyLabel.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyLabel.Loaded;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyLabel.Resize;
begin
  inherited;
  if FWordWrap then
    UpdateSize;
end;

procedure TDaisyLabel.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyLabel.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
  Invalidate;
end;

procedure TDaisyLabel.UpdateSize;
var
  LBold: Boolean;
  LWidth, LHeight, LFont: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LFont := DaisyFontSize(SizeKind);
  LBold := fsBold in Font.Style;
  LWidth := Width;
  if FWordWrap then
    LHeight := MeasureTextHeight(Caption, Max(1, Width), LFont, LBold)
  else
  begin
    LWidth := MeasureTextWidth(Caption, LFont, LBold) + ScaleValue(2);
    LHeight := Max(MeasureTextHeight('Ag', 1000, LFont, LBold),
      MeasureTextHeight(Caption, 100000, LFont, LBold));
  end;
  if (LWidth = Width) and (LHeight = Height) then
    Exit;
  FUpdating := True;
  try
    if Align in [alTop, alBottom, alClient] then
      LWidth := Width;
    SetBounds(Left, Top, LWidth, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyLabel.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LFlags: Cardinal;
  LRect: TRect;
  LFont, LTextHeight: Integer;
  LBold: Boolean;
begin
  LFont := DaisyFontSize(SizeKind);
  LBold := fsBold in Font.Style;
  case FAlignment of
    taCenter: LFlags := DT_CENTER;
    taEnd: LFlags := DT_RIGHT;
  else
    LFlags := DT_LEFT;
  end;
  LRect := ARect;
  if FWordWrap then
  begin
    LFlags := LFlags or DT_WORDBREAK;
    LTextHeight := MeasureTextHeight(Caption, ARect.Width, LFont, LBold);
    case FVerticalAlignment of
      taCenter: LRect.Top := ARect.Top + Max(0, (ARect.Height - LTextHeight) div 2);
      taEnd: LRect.Top := ARect.Bottom - LTextHeight;
    end;
  end
  else
  begin
    LFlags := LFlags or DT_SINGLELINE or DT_END_ELLIPSIS;
    case FVerticalAlignment of
      taCenter: LFlags := LFlags or DT_VCENTER;
      taEnd: LFlags := LFlags or DT_BOTTOM;
    else
      LFlags := LFlags or DT_TOP;
    end;
  end;
  DrawRichText(Caption, LRect, AColors.Text, LFont, LBold, LFlags);
end;

end.
