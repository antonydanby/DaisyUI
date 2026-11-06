unit Daisy.VCL.Button;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Forms, Daisy.Theme, Daisy.SVG, Daisy.VCL.Control;

type
  TDaisyButton = class(TDaisyControl)
  strict private
    FModalResult: TModalResult;
    FKeyPressed: Boolean;
    FIconPath: string;
    FSVG: TStrings;
    FIconPosition: TDaisyBadgeIconPosition;
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure SetSVG(const Value: TStrings);
    procedure SVGChanged(Sender: TObject);
    procedure SetIconPath(const Value: string);
    procedure SetIconPosition(const Value: TDaisyBadgeIconPosition);
  protected
    function IsInteractive: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function GetState: TDaisyState; override;
    procedure SizeChanged; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    // Size of the SVG icon box and the gap to the caption (0 when there is no IconPath)
    function IconExtent: Integer;
    function IconGapExtent: Integer;
    // Draws the SVG icon with its left edge at ALeft, centred vertically in ARect
    procedure DrawButtonIcon(ALeft: Integer; const ARect: TRect; AColor: TAlphaColor);
    // Normalised icon data derived from SVG (see TDaisySVG)
    property IconPath: string read FIconPath;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Caption: string read GetCaption write SetCaption;
    // Paste SVG markup or load an .svg file; the icon is drawn next to the caption
    property SVG: TStrings read FSVG write SetSVG;
    property IconPosition: TDaisyBadgeIconPosition read FIconPosition write SetIconPosition
      default bipLeft;
    property ModalResult: TModalResult read FModalResult write FModalResult default 0;
  end;

implementation

{ TDaisyButton }

constructor TDaisyButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TabStop := True;
  Cursor := crHandPoint;
  FIconPosition := bipLeft;
  FSVG := TStringList.Create;
  TStringList(FSVG).OnChange := SVGChanged;
  SetBounds(Left, Top, 96, ScaleValue(DaisyFieldHeight(dzMD)));
  Caption := 'Button';
end;

destructor TDaisyButton.Destroy;
begin
  FSVG.Free;
  inherited Destroy;
end;

procedure TDaisyButton.SetSVG(const Value: TStrings);
begin
  FSVG.Assign(Value);
end;

procedure TDaisyButton.SVGChanged(Sender: TObject);
begin
  SetIconPath(TDaisySVG.IconPath(FSVG.Text));
end;

function TDaisyButton.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyButton.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

function TDaisyButton.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyButton.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyButton.DefaultContentPadding: Integer;
begin
  Result := DaisyFieldPaddingX(SizeKind);
end;

function TDaisyButton.GetState: TDaisyState;
begin
  Result := inherited GetState;
  if FKeyPressed and (Result in [dstNormal, dstHover]) then
    Result := dstPressed;
end;

procedure TDaisyButton.SizeChanged;
begin
  Height := ScaleValue(DaisyFieldHeight(SizeKind));
end;

procedure TDaisyButton.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LRect: TRect;
  LFont, LIcon, LGap, LTextW, LTotal, LLeft, LTextLeft, LIconLeft: Integer;
begin
  LRect := BodyRect;
  InflateRect(LRect, -ResolvedContentPadding, 0);
  LIcon := IconExtent;
  if LIcon = 0 then
  begin
    DrawText(Caption, LRect, AColors.Text, DaisyFontSize(SizeKind), False,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    Exit;
  end;

  LFont := DaisyFontSize(SizeKind);
  LTextW := MeasureTextWidth(Caption, LFont, False);
  LGap := 0;
  if LTextW > 0 then
    LGap := IconGapExtent;
  LTextW := Min(LTextW, Max(0, LRect.Right - LRect.Left - LIcon - LGap));
  LTotal := LIcon + LGap + LTextW;
  LLeft := LRect.Left + Max(0, (LRect.Right - LRect.Left - LTotal) div 2);
  if FIconPosition = bipLeft then
  begin
    LIconLeft := LLeft;
    LTextLeft := LLeft + LIcon + LGap;
  end
  else
  begin
    LTextLeft := LLeft;
    LIconLeft := LLeft + LTextW + LGap;
  end;
  DrawButtonIcon(LIconLeft, LRect, AColors.Text); // GDI+ first, then GDI text
  if LTextW > 0 then
    DrawText(Caption, Rect(LTextLeft, LRect.Top, LTextLeft + LTextW, LRect.Bottom), AColors.Text,
      LFont, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

procedure TDaisyButton.SetIconPath(const Value: string);
begin
  if FIconPath <> Value then
  begin
    FIconPath := Value;
    Invalidate;
  end;
end;

procedure TDaisyButton.SetIconPosition(const Value: TDaisyBadgeIconPosition);
begin
  if FIconPosition <> Value then
  begin
    FIconPosition := Value;
    Invalidate;
  end;
end;

function TDaisyButton.IconExtent: Integer;
begin
  if FIconPath = '' then
    Result := 0
  else
    Result := ScaleValue(DaisyFontSize(SizeKind) + 4);
end;

function TDaisyButton.IconGapExtent: Integer;
begin
  Result := ScaleValue(8);
end;

procedure TDaisyButton.DrawButtonIcon(ALeft: Integer; const ARect: TRect; AColor: TAlphaColor);
var
  LSize: Integer;
  LTop: Single;
begin
  LSize := IconExtent;
  if LSize = 0 then
    Exit;
  LTop := ARect.Top + ((ARect.Bottom - ARect.Top) - LSize) / 2;
  DrawIconPath(FIconPath, RectF(ALeft, LTop, ALeft + LSize, LTop + LSize), AColor);
end;

procedure TDaisyButton.Click;
var
  LForm: TCustomForm;
begin
  inherited Click;
  if FModalResult <> 0 then
  begin
    LForm := GetParentForm(Self);
    if LForm <> nil then
      LForm.ModalResult := FModalResult;
  end;
end;

procedure TDaisyButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_SPACE) and (Shift = []) then
  begin
    FKeyPressed := True;
    Invalidate;
  end;
end;

procedure TDaisyButton.KeyUp(var Key: Word; Shift: TShiftState);
var
  LWasPressed: Boolean;
begin
  inherited KeyUp(Key, Shift);
  if (Key = VK_SPACE) and FKeyPressed then
  begin
    LWasPressed := FKeyPressed;
    FKeyPressed := False;
    Invalidate;
    if LWasPressed then
      Click;
  end;
end;

procedure TDaisyButton.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FKeyPressed := False;
end;

end.
