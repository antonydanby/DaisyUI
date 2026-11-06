unit Daisy.FMX.Chat;

{
  TDaisyFmxChatBubble - a speech bubble in the DaisyUI "chat" style: bubble with a
  tail, optional avatar (picture, SVG or emoji), header (name and time) and footer.
  Mirrors Daisy.VCL.Chat so both frameworks share one public API.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.FMX.Control;

type
  TDaisyFmxChatBubble = class(TDaisyControl)
  strict private
    type
      TChatLayout = record
        Avatar, Header, Bubble, Footer, Text: TRectF;
        Height: Single;
      end;
    var
    FText: string;
    FPlacement: TDaisyChatPlacement;
    FHeader: string;
    FHeaderTime: string;
    FFooter: string;
    FShowAvatar: Boolean;
    FAvatarIcon: TDaisyIconSource;
    FAvatar: TBitmap;
    FAvatarCache: TBitmap;
    FAutoHeight: Boolean;
    FUpdating: Boolean;
    procedure SetText(const Value: string);
    procedure SetPlacement(const Value: TDaisyChatPlacement);
    procedure SetHeader(const Value: string);
    procedure SetHeaderTime(const Value: string);
    procedure SetFooter(const Value: string);
    procedure SetShowAvatar(const Value: Boolean);
    function GetAvatarText: string;
    procedure SetAvatarText(const Value: string);
    function GetSVG: TStrings;
    procedure SetSVG(const Value: TStrings);
    procedure SetAvatar(const Value: TBitmap);
    procedure SetAutoHeight(const Value: Boolean);
    procedure AvatarChanged(Sender: TObject);
    procedure PictureChanged(Sender: TObject);
    function HasAvatarPicture: Boolean;
    function BuildLayout: TChatLayout;
    procedure UpdateHeight;
    procedure DrawAvatarPicture(const ARect: TRectF);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // The message
    property Text: string read FText write SetText;
    property Placement: TDaisyChatPlacement read FPlacement write SetPlacement default cpStart;
    // Name shown above the bubble
    property Header: string read FHeader write SetHeader;
    // Time shown (dimmed) after the header
    property HeaderTime: string read FHeaderTime write SetHeaderTime;
    // Shown (dimmed) under the bubble, for example "Delivered"
    property Footer: string read FFooter write SetFooter;
    property ShowAvatar: Boolean read FShowAvatar write SetShowAvatar default True;
    // A picture avatar; takes precedence over SVG and AvatarText
    property Avatar: TBitmap read FAvatar write SetAvatar;
    // Paste SVG markup or load an .svg file to use as the avatar
    property SVG: TStrings read GetSVG write SetSVG;
    // An emoji used as the avatar when there is no picture or SVG
    property AvatarText: string read GetAvatarText write SetAvatarText;
    // The height follows the message, header and footer
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default True;
  end;

implementation

const
  CAvatar = 40;
  CGap = 12;
  CTail = 12;
  CPadX = 16;
  CPadY = 8;
  CMinBubble = 44;
  CMetaHeight = 16;
  CTextSize = 14;
  CMetaSize = 12;

{ TDaisyFmxChatBubble }

constructor TDaisyFmxChatBubble.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPlacement := cpStart;
  FShowAvatar := True;
  FAutoHeight := True;
  FText := 'Hello there!';
  FAvatarIcon := TDaisyIconSource.Create(AvatarChanged);
  FAvatar := TBitmap.Create;
  FAvatar.OnChange := PictureChanged;
  SetBounds(Position.X, Position.Y, 280, 68);
end;

destructor TDaisyFmxChatBubble.Destroy;
begin
  FAvatarCache.Free;
  FAvatar.Free;
  FAvatarIcon.Free;
  inherited Destroy;
end;

procedure TDaisyFmxChatBubble.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    UpdateHeight;
    Repaint;
  end;
end;

procedure TDaisyFmxChatBubble.SetPlacement(const Value: TDaisyChatPlacement);
begin
  if FPlacement <> Value then
  begin
    FPlacement := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxChatBubble.SetHeader(const Value: string);
begin
  if FHeader <> Value then
  begin
    FHeader := Value;
    UpdateHeight;
    Repaint;
  end;
end;

procedure TDaisyFmxChatBubble.SetHeaderTime(const Value: string);
begin
  if FHeaderTime <> Value then
  begin
    FHeaderTime := Value;
    UpdateHeight;
    Repaint;
  end;
end;

procedure TDaisyFmxChatBubble.SetFooter(const Value: string);
begin
  if FFooter <> Value then
  begin
    FFooter := Value;
    UpdateHeight;
    Repaint;
  end;
end;

procedure TDaisyFmxChatBubble.SetShowAvatar(const Value: Boolean);
begin
  if FShowAvatar <> Value then
  begin
    FShowAvatar := Value;
    UpdateHeight;
    Repaint;
  end;
end;

function TDaisyFmxChatBubble.GetAvatarText: string;
begin
  Result := FAvatarIcon.Emoji;
end;

procedure TDaisyFmxChatBubble.SetAvatarText(const Value: string);
begin
  FAvatarIcon.Emoji := Value;
end;

function TDaisyFmxChatBubble.GetSVG: TStrings;
begin
  Result := FAvatarIcon.SVG;
end;

procedure TDaisyFmxChatBubble.SetSVG(const Value: TStrings);
begin
  FAvatarIcon.SVG := Value;
end;

procedure TDaisyFmxChatBubble.SetAvatar(const Value: TBitmap);
begin
  FAvatar.Assign(Value);
end;

procedure TDaisyFmxChatBubble.SetAutoHeight(const Value: Boolean);
begin
  if FAutoHeight <> Value then
  begin
    FAutoHeight := Value;
    UpdateHeight;
  end;
end;

procedure TDaisyFmxChatBubble.AvatarChanged(Sender: TObject);
begin
  Repaint;
end;

procedure TDaisyFmxChatBubble.PictureChanged(Sender: TObject);
begin
  FreeAndNil(FAvatarCache);
  Repaint;
end;

function TDaisyFmxChatBubble.HasAvatarPicture: Boolean;
begin
  Result := not FAvatar.IsEmpty;
end;

function TDaisyFmxChatBubble.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyFmxChatBubble.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

// The control draws everything itself so the area around the bubble stays transparent
function TDaisyFmxChatBubble.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

procedure TDaisyFmxChatBubble.SizeChanged;
begin
  UpdateHeight;
  Repaint;
end;

procedure TDaisyFmxChatBubble.Loaded;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyFmxChatBubble.Resize;
begin
  inherited;
  UpdateHeight;
end;

function TDaisyFmxChatBubble.BuildLayout: TChatLayout;
var
  LSide, LAvail, LTextMax, LTextW, LTextH, LBubbleW, LBubbleH, LTop, LAvatarW: Single;
begin
  Result := Default(TChatLayout);
  if FShowAvatar then
    LAvatarW := CAvatar
  else
    LAvatarW := 0;
  LSide := LAvatarW + CGap;
  LAvail := Max(1, Width - LSide);
  LTextMax := Max(1, LAvail - 2 * CPadX);

  LTextW := MeasureTextWidth(FText, CTextSize, False) + 2;
  LTextW := Max(1, Min(LTextW, LTextMax));
  LTextH := MeasureTextHeight(FText, LTextW, CTextSize, False);
  LBubbleW := LTextW + 2 * CPadX;
  LBubbleH := Max(CMinBubble, LTextH + 2 * CPadY);

  LTop := 0;
  if (FHeader <> '') or (FHeaderTime <> '') then
  begin
    Result.Header := RectF(0, 0, LAvail, CMetaHeight);
    LTop := CMetaHeight;
  end;
  Result.Bubble := RectF(0, LTop, LBubbleW, LTop + LBubbleH);
  Result.Footer := RectF(0, Result.Bubble.Bottom, LAvail, Result.Bubble.Bottom);
  if FFooter <> '' then
    Result.Footer.Bottom := Result.Footer.Top + CMetaHeight;
  Result.Height := Max(Result.Footer.Bottom, LAvatarW);

  if FPlacement = cpStart then
  begin
    Result.Header.Offset(LSide, 0);
    Result.Bubble.Offset(LSide, 0);
    Result.Footer.Offset(LSide, 0);
    if FShowAvatar then
      Result.Avatar := RectF(0, Result.Height - LAvatarW, LAvatarW, Result.Height);
  end
  else
  begin
    Result.Header := RectF(Width - LSide - LAvail, Result.Header.Top, Width - LSide, Result.Header.Bottom);
    Result.Footer := RectF(Width - LSide - LAvail, Result.Footer.Top, Width - LSide, Result.Footer.Bottom);
    Result.Bubble.Offset(Width - LSide - LBubbleW, 0);
    if FShowAvatar then
      Result.Avatar := RectF(Width - LAvatarW, Result.Height - LAvatarW, Width, Result.Height);
  end;
  Result.Text := RectF(Result.Bubble.Left + CPadX, Result.Bubble.Top + (LBubbleH - LTextH) / 2,
    Result.Bubble.Right - CPadX, Result.Bubble.Top + (LBubbleH - LTextH) / 2 + LTextH);
end;

procedure TDaisyFmxChatBubble.UpdateHeight;
var
  LHeight: Single;
begin
  if (not FAutoHeight) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := BuildLayout.Height;
  if (LHeight <= 0) or SameValue(LHeight, Height) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxChatBubble.DrawAvatarPicture(const ARect: TRectF);
const
  CCache = 96;
var
  LSide: Single;
  LSource: TRectF;
begin
  if FAvatarCache = nil then
  begin
    FAvatarCache := TBitmap.Create(CCache, CCache);
    LSide := Min(FAvatar.Width, FAvatar.Height); // cover: crop the centre square
    LSource := RectF((FAvatar.Width - LSide) / 2, (FAvatar.Height - LSide) / 2,
      (FAvatar.Width + LSide) / 2, (FAvatar.Height + LSide) / 2);
    if FAvatarCache.Canvas.BeginScene then
      try
        FAvatarCache.Canvas.Clear(0);
        FAvatarCache.Canvas.DrawBitmap(FAvatar, LSource, RectF(0, 0, CCache, CCache), 1);
      finally
        FAvatarCache.Canvas.EndScene;
      end;
  end;
  Canvas.Fill.Kind := TBrushKind.Bitmap;
  Canvas.Fill.Bitmap.Bitmap.Assign(FAvatarCache);
  Canvas.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
  Canvas.FillEllipse(ARect, AbsoluteOpacity);
  Canvas.Fill.Kind := TBrushKind.Solid;
end;

procedure TDaisyFmxChatBubble.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LLayout: TChatLayout;
  LPoints: TArray<TPointF>;
  LPath: TPathData;
  LFill, LTextColor, LMeta: TAlphaColor;
  LPalette: TDaisyPalette;
  LName, LTime, LX: Single;
  LBox: TRectF;
  I: Integer;
begin
  LLayout := BuildLayout;
  if Variant = dvDefault then
  begin
    LFill := Theme.Base300;
    LTextColor := Theme.BaseContent;
  end
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    LFill := LPalette.Fill;
    LTextColor := LPalette.Content;
  end;
  if not Enabled then
    LTextColor := DaisyWithAlpha(LTextColor, 0.5);
  LMeta := DaisyWithAlpha(Theme.BaseContent, 0.5);

  LPoints := DaisyChatBubblePolygon(LLayout.Bubble, ResolvedCornerRadius, CTail, FPlacement);
  LPath := TPathData.Create;
  try
    for I := 0 to High(LPoints) do
      if I = 0 then
        LPath.MoveTo(LPoints[I])
      else
        LPath.LineTo(LPoints[I]);
    LPath.ClosePath;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := LFill;
    Canvas.FillPath(LPath, AbsoluteOpacity);
  finally
    LPath.Free;
  end;

  if FShowAvatar then
  begin
    if HasAvatarPicture then
      DrawAvatarPicture(LLayout.Avatar)
    else
    begin
      Canvas.Fill.Kind := TBrushKind.Solid;
      Canvas.Fill.Color := Theme.Base300;
      Canvas.FillEllipse(LLayout.Avatar, AbsoluteOpacity);
      if not FAvatarIcon.IsEmpty then
      begin
        LBox := LLayout.Avatar;
        LBox.Inflate(-LBox.Width / 5, -LBox.Height / 5);
        DrawGlyph(FAvatarIcon, LBox, Theme.BaseContent);
      end;
    end;
  end;

  DrawText(FText, LLayout.Text, LTextColor, CTextSize, False, TTextAlign.Leading,
    TTextAlign.Leading, True);

  if (FHeader <> '') or (FHeaderTime <> '') then
  begin
    LName := MeasureTextWidth(FHeader, CMetaSize, False);
    LTime := MeasureTextWidth(FHeaderTime, CMetaSize, False);
    if FPlacement = cpStart then
      LX := LLayout.Header.Left
    else
      LX := LLayout.Header.Right - (LName + LTime + IfThen((LName > 0) and (LTime > 0), 8.0));
    DrawText(FHeader, RectF(LX, LLayout.Header.Top, LX + LName + 4, LLayout.Header.Bottom),
      Theme.BaseContent, CMetaSize, False, TTextAlign.Leading, TTextAlign.Center, False);
    if LName > 0 then
      LX := LX + LName + 8;
    DrawText(FHeaderTime, RectF(LX, LLayout.Header.Top, LX + LTime + 4, LLayout.Header.Bottom),
      LMeta, CMetaSize, False, TTextAlign.Leading, TTextAlign.Center, False);
  end;

  if FFooter <> '' then
  begin
    if FPlacement = cpStart then
      DrawText(FFooter, LLayout.Footer, LMeta, CMetaSize, False, TTextAlign.Leading, TTextAlign.Center, False)
    else
      DrawText(FFooter, LLayout.Footer, LMeta, CMetaSize, False, TTextAlign.Trailing, TTextAlign.Center, False);
  end;
end;

end.
