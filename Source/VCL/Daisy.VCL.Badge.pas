unit Daisy.VCL.Badge;

{
  TDaisyBadge       - a small label: solid, soft, outline, dash or ghost, in any
                      theme colour and size, optionally with an icon or empty.
  TDaisyBadgeButton - a button that carries a badge next to its caption.
  Both reuse the badge drawing and colour rules of TDaisyControl / Daisy.Theme.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.UITypes,
  System.Math, Vcl.Controls, Daisy.Theme, Daisy.SVG, Daisy.VCL.Control, Daisy.VCL.Button;

type
  TDaisyBadge = class(TDaisyControl)
  strict private
    FIcon: TDaisyIconKind;
    FIconPosition: TDaisyBadgeIconPosition;
    FIconPath: string;
    FSVG: TStrings;
    FAutoWidth: Boolean;
    FUpdating: Boolean;
    procedure SetSVG(const Value: TStrings);
    procedure SVGChanged(Sender: TObject);
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure SetIcon(const Value: TDaisyIconKind);
    procedure SetIconPath(const Value: string);
    procedure SetIconPosition(const Value: TDaisyBadgeIconPosition);
    procedure SetAutoWidth(const Value: Boolean);
    function ResolvedIcon: TDaisyIconKind;
    procedure UpdateWidth;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // An empty caption gives the "empty badge" (a small square dot)
    property Caption: string read GetCaption write SetCaption;
    property Icon: TDaisyIconKind read FIcon write SetIcon default diNone;
    // Paste SVG markup or load an .svg file; replaces Icon when set
    property SVG: TStrings read FSVG write SetSVG;
    property IconPosition: TDaisyBadgeIconPosition read FIconPosition write SetIconPosition default bipLeft;
    // The width follows the caption and icon; the height follows SizeKind
    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default True;
  end;

  TDaisyBadgeButton = class(TDaisyButton)
  strict private
    FBadgeText: string;
    FShowBadge: Boolean;
    FBadgeVariant: TDaisyVariant;
    FBadgeStyle: TDaisyStyle;
    FBadgeSize: TDaisySize;
    FBadgeIcon: TDaisyIconKind;
    FBadgeIconPath: string;
    FBadgeSVG: TStrings;
    procedure SetBadgeSVG(const Value: TStrings);
    procedure BadgeSVGChanged(Sender: TObject);
    procedure SetBadgeText(const Value: string);
    procedure SetShowBadge(const Value: Boolean);
    procedure SetBadgeVariant(const Value: TDaisyVariant);
    procedure SetBadgeStyle(const Value: TDaisyStyle);
    procedure SetBadgeSize(const Value: TDaisySize);
    procedure SetBadgeIcon(const Value: TDaisyIconKind);
    procedure SetBadgeIconPath(const Value: string);
    function ResolvedBadgeIcon: TDaisyIconKind;
  protected
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property BadgeText: string read FBadgeText write SetBadgeText;
    property ShowBadge: Boolean read FShowBadge write SetShowBadge default True;
    property BadgeVariant: TDaisyVariant read FBadgeVariant write SetBadgeVariant default dvDefault;
    property BadgeStyle: TDaisyStyle read FBadgeStyle write SetBadgeStyle default dsSolid;
    property BadgeSize: TDaisySize read FBadgeSize write SetBadgeSize default dzSM;
    property BadgeIcon: TDaisyIconKind read FBadgeIcon write SetBadgeIcon default diNone;
    // Paste SVG markup or load an .svg file; replaces BadgeIcon when set
    property BadgeSVG: TStrings read FBadgeSVG write SetBadgeSVG;
  end;

implementation

{ TDaisyBadge }

constructor TDaisyBadge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIcon := diNone;
  FIconPosition := bipLeft;
  FAutoWidth := True;
  FSVG := TStringList.Create;
  TStringList(FSVG).OnChange := SVGChanged;
  SetBounds(Left, Top, 64, ScaleValue(DaisyBadgeHeight(dzMD)));
  Caption := 'Badge';
end;

destructor TDaisyBadge.Destroy;
begin
  FSVG.Free;
  inherited Destroy;
end;

procedure TDaisyBadge.SetSVG(const Value: TStrings);
begin
  FSVG.Assign(Value);
end;

procedure TDaisyBadge.SVGChanged(Sender: TObject);
begin
  SetIconPath(TDaisySVG.IconPath(FSVG.Text));
end;

function TDaisyBadge.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyBadge.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyBadge.SetIcon(const Value: TDaisyIconKind);
begin
  if FIcon <> Value then
  begin
    FIcon := Value;
    UpdateWidth;
    Invalidate;
  end;
end;

procedure TDaisyBadge.SetIconPath(const Value: string);
begin
  if FIconPath <> Value then
  begin
    FIconPath := Value;
    UpdateWidth;
    Invalidate;
  end;
end;

procedure TDaisyBadge.SetIconPosition(const Value: TDaisyBadgeIconPosition);
begin
  if FIconPosition <> Value then
  begin
    FIconPosition := Value;
    Invalidate;
  end;
end;

procedure TDaisyBadge.SetAutoWidth(const Value: Boolean);
begin
  if FAutoWidth <> Value then
  begin
    FAutoWidth := Value;
    UpdateWidth;
  end;
end;

// diAuto picks the icon that matches the colour; it always yields a real icon
function TDaisyBadge.ResolvedIcon: TDaisyIconKind;
begin
  if FIcon = diAuto then
    Result := DaisyResolveIcon(diAuto, Variant)
  else
    Result := FIcon;
end;

procedure TDaisyBadge.UpdateWidth;
var
  LWidth: Integer;
begin
  if (not FAutoWidth) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LWidth := BadgeWidth(Caption, SizeKind, ResolvedIcon, FIconPath);
  if LWidth = Width then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, LWidth, Height);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyBadge.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateWidth;
end;

procedure TDaisyBadge.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateWidth;
end;

function TDaisyBadge.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusSelector;
end;

function TDaisyBadge.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  if AState = dstDisabled then
    Result := inherited DefaultStyleColors(AState)
  else
    Result := DaisyBadgeColors(Theme, Variant, Style);
end;

procedure TDaisyBadge.SizeChanged;
begin
  Height := ScaleValue(DaisyBadgeHeight(SizeKind));
  UpdateWidth;
end;

procedure TDaisyBadge.Loaded;
begin
  inherited;
  Height := ScaleValue(DaisyBadgeHeight(SizeKind));
  UpdateWidth;
end;

procedure TDaisyBadge.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
begin
  DrawBadgeContent(BodyRect, Caption, AColors.Text, SizeKind, ResolvedIcon, FIconPosition,
    FIconPath);
end;

{ TDaisyBadgeButton }

constructor TDaisyBadgeButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FShowBadge := True;
  FBadgeVariant := dvDefault;
  FBadgeStyle := dsSolid;
  FBadgeSize := dzSM;
  FBadgeIcon := diNone;
  FBadgeText := '+99';
  FBadgeSVG := TStringList.Create;
  TStringList(FBadgeSVG).OnChange := BadgeSVGChanged;
  SetBounds(Left, Top, 136, Height);
  Caption := 'Inbox';
end;

destructor TDaisyBadgeButton.Destroy;
begin
  FBadgeSVG.Free;
  inherited Destroy;
end;

procedure TDaisyBadgeButton.SetBadgeSVG(const Value: TStrings);
begin
  FBadgeSVG.Assign(Value);
end;

procedure TDaisyBadgeButton.BadgeSVGChanged(Sender: TObject);
begin
  SetBadgeIconPath(TDaisySVG.IconPath(FBadgeSVG.Text));
end;

procedure TDaisyBadgeButton.SetBadgeText(const Value: string);
begin
  if FBadgeText <> Value then
  begin
    FBadgeText := Value;
    Invalidate;
  end;
end;

procedure TDaisyBadgeButton.SetShowBadge(const Value: Boolean);
begin
  if FShowBadge <> Value then
  begin
    FShowBadge := Value;
    Invalidate;
  end;
end;

procedure TDaisyBadgeButton.SetBadgeVariant(const Value: TDaisyVariant);
begin
  if FBadgeVariant <> Value then
  begin
    FBadgeVariant := Value;
    Invalidate;
  end;
end;

procedure TDaisyBadgeButton.SetBadgeStyle(const Value: TDaisyStyle);
begin
  if FBadgeStyle <> Value then
  begin
    FBadgeStyle := Value;
    Invalidate;
  end;
end;

procedure TDaisyBadgeButton.SetBadgeSize(const Value: TDaisySize);
begin
  if FBadgeSize <> Value then
  begin
    FBadgeSize := Value;
    Invalidate;
  end;
end;

procedure TDaisyBadgeButton.SetBadgeIcon(const Value: TDaisyIconKind);
begin
  if FBadgeIcon <> Value then
  begin
    FBadgeIcon := Value;
    Invalidate;
  end;
end;

procedure TDaisyBadgeButton.SetBadgeIconPath(const Value: string);
begin
  if FBadgeIconPath <> Value then
  begin
    FBadgeIconPath := Value;
    Invalidate;
  end;
end;

function TDaisyBadgeButton.ResolvedBadgeIcon: TDaisyIconKind;
begin
  if FBadgeIcon = diAuto then
    Result := DaisyResolveIcon(diAuto, FBadgeVariant)
  else
    Result := FBadgeIcon;
end;

procedure TDaisyBadgeButton.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LBody, LBadgeRect: TRect;
  LBadgeColors: TDaisyColors;
  LIcon: TDaisyIconKind;
  LFont, LCaptionW, LBadgeW, LBadgeH, LGap, LX, LTop: Integer;
  LIconW, LIconGap, LIconX, LCaptionX, LBadgeX: Integer;
begin
  if not FShowBadge then
  begin
    inherited DrawContent(AColors, ARect);
    Exit;
  end;

  LBody := BodyRect;
  InflateRect(LBody, -ResolvedContentPadding, 0);
  LFont := DaisyFontSize(SizeKind);
  LIcon := ResolvedBadgeIcon;
  LCaptionW := MeasureTextWidth(Caption, LFont, False);
  LBadgeW := BadgeWidth(FBadgeText, FBadgeSize, LIcon, FBadgeIconPath);
  LBadgeH := ScaleValue(DaisyBadgeHeight(FBadgeSize));
  LGap := 0;
  if LCaptionW > 0 then
    LGap := ScaleValue(6);
  LIconW := IconExtent;
  LIconGap := 0;
  if (LIconW > 0) and (LCaptionW > 0) then
    LIconGap := IconGapExtent;

  // Icon, caption and badge are centred together as one group
  LX := LBody.Left + Max(0, (LBody.Right - LBody.Left -
    (LIconW + LIconGap + LCaptionW + LGap + LBadgeW)) div 2);
  if IconPosition = bipLeft then
  begin
    LIconX := LX;
    LCaptionX := LX + LIconW + LIconGap;
  end
  else
  begin
    LCaptionX := LX;
    LIconX := LX + LCaptionW + LIconGap;
  end;
  DrawButtonIcon(LIconX, LBody, AColors.Text);
  DrawText(Caption, Rect(LCaptionX, LBody.Top, LCaptionX + LCaptionW + 2, LBody.Bottom),
    AColors.Text, LFont, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  LBadgeX := LX + LIconW + LIconGap + LCaptionW + LGap;
  LTop := (LBody.Top + LBody.Bottom - LBadgeH) div 2;
  LBadgeRect := Rect(LBadgeX, LTop, LBadgeX + LBadgeW, LTop + LBadgeH);
  if Enabled then
    LBadgeColors := DaisyBadgeColors(Theme, FBadgeVariant, FBadgeStyle)
  else
    LBadgeColors := DaisyResolveColors(Theme, dvDefault, dsSolid, dstDisabled);
  DrawBadgeShape(LBadgeRect, LBadgeColors, ScaleValue(Theme.RadiusSelector));
  DrawBadgeContent(LBadgeRect, FBadgeText, LBadgeColors.Text, FBadgeSize, LIcon, bipLeft,
    FBadgeIconPath);
end;

end.
