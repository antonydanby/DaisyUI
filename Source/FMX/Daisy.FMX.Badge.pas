unit Daisy.FMX.Badge;

{
  TDaisyFmxBadge       - a small label: solid, soft, outline, dash or ghost, in
                         any theme colour and size, optionally with an icon or empty.
  TDaisyFmxBadgeButton - a button that carries a badge next to its text.
  Mirrors Daisy.VCL.Badge so both frameworks share one public API.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, Daisy.Theme, Daisy.SVG, Daisy.FMX.Control, Daisy.FMX.Button;

type
  TDaisyFmxBadge = class(TDaisyControl)
  strict private
    FText: string;
    FIcon: TDaisyIconKind;
    FIconPosition: TDaisyBadgeIconPosition;
    FIconPath: string;
    FSVG: TStrings;
    FAutoWidth: Boolean;
    FUpdating: Boolean;
    procedure SetSVG(const Value: TStrings);
    procedure SVGChanged(Sender: TObject);
    procedure SetText(const Value: string);
    procedure SetIconPath(const Value: string);
    procedure SetIcon(const Value: TDaisyIconKind);
    procedure SetIconPosition(const Value: TDaisyBadgeIconPosition);
    procedure SetAutoWidth(const Value: Boolean);
    function ResolvedIcon: TDaisyIconKind;
    procedure UpdateWidth;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // An empty text gives the "empty badge" (a small square dot)
    property Text: string read FText write SetText;
    property Icon: TDaisyIconKind read FIcon write SetIcon default diNone;
    // Paste SVG markup or load an .svg file; replaces Icon when set
    property SVG: TStrings read FSVG write SetSVG;
    property IconPosition: TDaisyBadgeIconPosition read FIconPosition write SetIconPosition default bipLeft;
    // The width follows the text and icon; the height follows SizeKind
    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default True;
  end;

  TDaisyFmxBadgeButton = class(TDaisyFmxButton)
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
    procedure SetBadgeIconPath(const Value: string);
    procedure SetBadgeText(const Value: string);
    procedure SetShowBadge(const Value: Boolean);
    procedure SetBadgeVariant(const Value: TDaisyVariant);
    procedure SetBadgeStyle(const Value: TDaisyStyle);
    procedure SetBadgeSize(const Value: TDaisySize);
    procedure SetBadgeIcon(const Value: TDaisyIconKind);
    function ResolvedBadgeIcon: TDaisyIconKind;
  protected
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
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

{ TDaisyFmxBadge }

constructor TDaisyFmxBadge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIcon := diNone;
  FIconPosition := bipLeft;
  FAutoWidth := True;
  FText := 'Badge';
  FSVG := TStringList.Create;
  TStringList(FSVG).OnChange := SVGChanged;
  SetBounds(Position.X, Position.Y, 64, DaisyBadgeHeight(dzMD));
  UpdateWidth;
end;

destructor TDaisyFmxBadge.Destroy;
begin
  FSVG.Free;
  inherited Destroy;
end;

procedure TDaisyFmxBadge.SetSVG(const Value: TStrings);
begin
  FSVG.Assign(Value);
end;

procedure TDaisyFmxBadge.SVGChanged(Sender: TObject);
begin
  SetIconPath(TDaisySVG.IconPath(FSVG.Text));
end;

procedure TDaisyFmxBadge.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    UpdateWidth;
    Repaint;
  end;
end;

procedure TDaisyFmxBadge.SetIcon(const Value: TDaisyIconKind);
begin
  if FIcon <> Value then
  begin
    FIcon := Value;
    UpdateWidth;
    Repaint;
  end;
end;

procedure TDaisyFmxBadge.SetIconPosition(const Value: TDaisyBadgeIconPosition);
begin
  if FIconPosition <> Value then
  begin
    FIconPosition := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxBadge.SetIconPath(const Value: string);
begin
  if FIconPath <> Value then
  begin
    FIconPath := Value;
    UpdateWidth;
    Repaint;
  end;
end;

procedure TDaisyFmxBadge.SetAutoWidth(const Value: Boolean);
begin
  if FAutoWidth <> Value then
  begin
    FAutoWidth := Value;
    UpdateWidth;
  end;
end;

// diAuto picks the icon that matches the colour; it always yields a real icon
function TDaisyFmxBadge.ResolvedIcon: TDaisyIconKind;
begin
  if FIcon = diAuto then
    Result := DaisyResolveIcon(diAuto, Variant)
  else
    Result := FIcon;
end;

procedure TDaisyFmxBadge.UpdateWidth;
var
  LWidth: Single;
begin
  if (not FAutoWidth) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LWidth := BadgeWidth(FText, SizeKind, ResolvedIcon, FIconPath);
  if SameValue(LWidth, Width) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LWidth, Height);
  finally
    FUpdating := False;
  end;
end;

function TDaisyFmxBadge.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusSelector;
end;

function TDaisyFmxBadge.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  if AState = dstDisabled then
    Result := inherited DefaultStyleColors(AState)
  else
    Result := DaisyBadgeColors(Theme, Variant, Style);
end;

procedure TDaisyFmxBadge.SizeChanged;
begin
  Height := DaisyBadgeHeight(SizeKind);
  UpdateWidth;
end;

procedure TDaisyFmxBadge.Loaded;
begin
  inherited;
  Height := DaisyBadgeHeight(SizeKind);
  UpdateWidth;
end;

procedure TDaisyFmxBadge.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
begin
  DrawBadgeContent(BodyRect, FText, AColors.Text, SizeKind, ResolvedIcon, FIconPosition, FIconPath);
end;

{ TDaisyFmxBadgeButton }

constructor TDaisyFmxBadgeButton.Create(AOwner: TComponent);
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
  SetBounds(Position.X, Position.Y, 136, Height);
  Text := 'Inbox';
end;

destructor TDaisyFmxBadgeButton.Destroy;
begin
  FBadgeSVG.Free;
  inherited Destroy;
end;

procedure TDaisyFmxBadgeButton.SetBadgeSVG(const Value: TStrings);
begin
  FBadgeSVG.Assign(Value);
end;

procedure TDaisyFmxBadgeButton.BadgeSVGChanged(Sender: TObject);
begin
  SetBadgeIconPath(TDaisySVG.IconPath(FBadgeSVG.Text));
end;

procedure TDaisyFmxBadgeButton.SetBadgeText(const Value: string);
begin
  if FBadgeText <> Value then
  begin
    FBadgeText := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxBadgeButton.SetShowBadge(const Value: Boolean);
begin
  if FShowBadge <> Value then
  begin
    FShowBadge := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxBadgeButton.SetBadgeVariant(const Value: TDaisyVariant);
begin
  if FBadgeVariant <> Value then
  begin
    FBadgeVariant := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxBadgeButton.SetBadgeStyle(const Value: TDaisyStyle);
begin
  if FBadgeStyle <> Value then
  begin
    FBadgeStyle := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxBadgeButton.SetBadgeSize(const Value: TDaisySize);
begin
  if FBadgeSize <> Value then
  begin
    FBadgeSize := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxBadgeButton.SetBadgeIcon(const Value: TDaisyIconKind);
begin
  if FBadgeIcon <> Value then
  begin
    FBadgeIcon := Value;
    Repaint;
  end;
end;

function TDaisyFmxBadgeButton.ResolvedBadgeIcon: TDaisyIconKind;
begin
  if FBadgeIcon = diAuto then
    Result := DaisyResolveIcon(diAuto, FBadgeVariant)
  else
    Result := FBadgeIcon;
end;

procedure TDaisyFmxBadgeButton.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LBody, LBadgeRect: TRectF;
  LBadgeColors: TDaisyColors;
  LIcon: TDaisyIconKind;
  LFont: Integer;
  LCaptionW, LBadgeW, LBadgeH, LGap, LX, LTop: Single;
  LIconW, LIconGap, LIconX, LCaptionX, LBadgeX: Single;
begin
  if not FShowBadge then
  begin
    inherited DrawContent(AColors, ARect);
    Exit;
  end;

  LBody := BodyRect;
  LBody.Inflate(-ResolvedContentPadding, 0);
  LFont := DaisyFontSize(SizeKind);
  LIcon := ResolvedBadgeIcon;
  LCaptionW := MeasureTextWidth(Text, LFont, False);
  LBadgeW := BadgeWidth(FBadgeText, FBadgeSize, LIcon, FBadgeIconPath);
  LBadgeH := DaisyBadgeHeight(FBadgeSize);
  LGap := 0;
  if LCaptionW > 0 then
    LGap := 6;
  LIconW := IconExtent;
  LIconGap := 0;
  if (LIconW > 0) and (LCaptionW > 0) then
    LIconGap := IconGapExtent;

  // Icon, text and badge are centred together as one group
  LX := LBody.Left + Max(0, (LBody.Width - (LIconW + LIconGap + LCaptionW + LGap + LBadgeW)) / 2);
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
  DrawText(Text, RectF(LCaptionX, LBody.Top, LCaptionX + LCaptionW + 2, LBody.Bottom), AColors.Text,
    LFont, False, TTextAlign.Leading, TTextAlign.Center, False);

  LBadgeX := LX + LIconW + LIconGap + LCaptionW + LGap;
  LTop := LBody.Top + (LBody.Height - LBadgeH) / 2;
  LBadgeRect := RectF(LBadgeX, LTop, LBadgeX + LBadgeW, LTop + LBadgeH);
  if Enabled then
    LBadgeColors := DaisyBadgeColors(Theme, FBadgeVariant, FBadgeStyle)
  else
    LBadgeColors := DaisyResolveColors(Theme, dvDefault, dsSolid, dstDisabled);
  DrawBadgeShape(LBadgeRect, LBadgeColors, Min(Theme.RadiusSelector, LBadgeH / 2));
  DrawBadgeContent(LBadgeRect, FBadgeText, LBadgeColors.Text, FBadgeSize, LIcon, bipLeft,
    FBadgeIconPath);
end;

procedure TDaisyFmxBadgeButton.SetBadgeIconPath(const Value: string);
begin
  if FBadgeIconPath <> Value then
  begin
    FBadgeIconPath := Value;
    Repaint;
  end;
end;

end.
