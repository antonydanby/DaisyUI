unit Daisy.VCL.Chat;

{
  TDaisyChatBubble - a speech bubble in the DaisyUI "chat" style: bubble with a
  tail, optional avatar (picture, SVG or emoji), header (name and time) and footer.
  The message may contain colour emoji. Use Placement for chat-start / chat-end and
  Variant for the bubble colour.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control;

type
  TDaisyChatBubble = class(TDaisyControl)
  strict private
    type
      TChatLayout = record
        Avatar, Header, Bubble, Footer, Text: TRect;
        Height: Integer;
      end;
    var
    FPlacement: TDaisyChatPlacement;
    FHeader: string;
    FHeaderTime: string;
    FFooter: string;
    FShowAvatar: Boolean;
    FAvatarIcon: TDaisyIconSource;
    FAvatar: TPicture;
    FAutoHeight: Boolean;
    FUpdating: Boolean;
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    procedure SetPlacement(const Value: TDaisyChatPlacement);
    procedure SetHeader(const Value: string);
    procedure SetHeaderTime(const Value: string);
    procedure SetFooter(const Value: string);
    procedure SetShowAvatar(const Value: Boolean);
    function GetAvatarText: string;
    procedure SetAvatarText(const Value: string);
    function GetSVG: TStrings;
    procedure SetSVG(const Value: TStrings);
    procedure SetAvatar(const Value: TPicture);
    procedure SetAutoHeight(const Value: Boolean);
    procedure AvatarChanged(Sender: TObject);
    function HasAvatarPicture: Boolean;
    function BuildLayout: TChatLayout;
    procedure UpdateHeight;
    procedure DrawAvatarPicture(const ARect: TRect);
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
    destructor Destroy; override;
  published
    // The message
    property Caption: string read GetCaption write SetCaption;
    property Placement: TDaisyChatPlacement read FPlacement write SetPlacement default cpStart;
    // Name shown above the bubble
    property Header: string read FHeader write SetHeader;
    // Time shown (dimmed) after the header
    property HeaderTime: string read FHeaderTime write SetHeaderTime;
    // Shown (dimmed) under the bubble, for example "Delivered"
    property Footer: string read FFooter write SetFooter;
    property ShowAvatar: Boolean read FShowAvatar write SetShowAvatar default True;
    // A picture avatar; takes precedence over SVG and AvatarText
    property Avatar: TPicture read FAvatar write SetAvatar;
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

{ TDaisyChatBubble }

constructor TDaisyChatBubble.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPlacement := cpStart;
  FShowAvatar := True;
  FAutoHeight := True;
  FAvatarIcon := TDaisyIconSource.Create(AvatarChanged);
  FAvatar := TPicture.Create;
  FAvatar.OnChange := AvatarChanged;
  SetBounds(Left, Top, 280, 68);
  inherited Caption := 'Hello there!';
end;

destructor TDaisyChatBubble.Destroy;
begin
  FAvatar.Free;
  FAvatarIcon.Free;
  inherited Destroy;
end;

function TDaisyChatBubble.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyChatBubble.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyChatBubble.SetPlacement(const Value: TDaisyChatPlacement);
begin
  if FPlacement <> Value then
  begin
    FPlacement := Value;
    Invalidate;
  end;
end;

procedure TDaisyChatBubble.SetHeader(const Value: string);
begin
  if FHeader <> Value then
  begin
    FHeader := Value;
    UpdateHeight;
    Invalidate;
  end;
end;

procedure TDaisyChatBubble.SetHeaderTime(const Value: string);
begin
  if FHeaderTime <> Value then
  begin
    FHeaderTime := Value;
    UpdateHeight;
    Invalidate;
  end;
end;

procedure TDaisyChatBubble.SetFooter(const Value: string);
begin
  if FFooter <> Value then
  begin
    FFooter := Value;
    UpdateHeight;
    Invalidate;
  end;
end;

procedure TDaisyChatBubble.SetShowAvatar(const Value: Boolean);
begin
  if FShowAvatar <> Value then
  begin
    FShowAvatar := Value;
    UpdateHeight;
    Invalidate;
  end;
end;

function TDaisyChatBubble.GetAvatarText: string;
begin
  Result := FAvatarIcon.Emoji;
end;

procedure TDaisyChatBubble.SetAvatarText(const Value: string);
begin
  FAvatarIcon.Emoji := Value;
end;

function TDaisyChatBubble.GetSVG: TStrings;
begin
  Result := FAvatarIcon.SVG;
end;

procedure TDaisyChatBubble.SetSVG(const Value: TStrings);
begin
  FAvatarIcon.SVG := Value;
end;

procedure TDaisyChatBubble.SetAvatar(const Value: TPicture);
begin
  FAvatar.Assign(Value);
end;

procedure TDaisyChatBubble.SetAutoHeight(const Value: Boolean);
begin
  if FAutoHeight <> Value then
  begin
    FAutoHeight := Value;
    UpdateHeight;
  end;
end;

procedure TDaisyChatBubble.AvatarChanged(Sender: TObject);
begin
  Invalidate;
end;

function TDaisyChatBubble.HasAvatarPicture: Boolean;
begin
  Result := (FAvatar.Graphic <> nil) and not FAvatar.Graphic.Empty;
end;

function TDaisyChatBubble.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyChatBubble.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

// The control draws everything itself so the area around the bubble stays transparent
function TDaisyChatBubble.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
end;

procedure TDaisyChatBubble.SizeChanged;
begin
  UpdateHeight;
  Invalidate;
end;

procedure TDaisyChatBubble.Loaded;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyChatBubble.Resize;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyChatBubble.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyChatBubble.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateHeight;
end;

function TDaisyChatBubble.BuildLayout: TChatLayout;
var
  LSide, LAvail, LTextMax, LTextW, LTextH, LBubbleW, LBubbleH, LTop, LMetaW: Integer;
  LAvatarW: Integer;
begin
  Result := Default(TChatLayout);
  if FShowAvatar then
    LAvatarW := ScaleValue(CAvatar)
  else
    LAvatarW := 0;
  LSide := LAvatarW + ScaleValue(CGap);
  LAvail := Max(1, Width - LSide);
  LTextMax := Max(1, LAvail - 2 * ScaleValue(CPadX));

  LTextW := MeasureTextWidth(Caption, CTextSize, False) + ScaleValue(2);
  if DaisyHasEmoji(Caption) then
    Inc(LTextW, ScaleValue(4));
  LTextW := Max(1, Min(LTextW, LTextMax));
  LTextH := MeasureTextHeight(Caption, LTextW, CTextSize, False);
  LBubbleW := LTextW + 2 * ScaleValue(CPadX);
  LBubbleH := Max(ScaleValue(CMinBubble), LTextH + 2 * ScaleValue(CPadY));

  LTop := 0;
  LMetaW := Max(LAvail, 1);
  if (FHeader <> '') or (FHeaderTime <> '') then
  begin
    Result.Header := Rect(0, 0, LMetaW, ScaleValue(CMetaHeight));
    LTop := Result.Header.Bottom;
  end;
  Result.Bubble := Rect(0, LTop, LBubbleW, LTop + LBubbleH);
  Result.Footer := Rect(0, Result.Bubble.Bottom, LMetaW, Result.Bubble.Bottom);
  if FFooter <> '' then
    Result.Footer.Bottom := Result.Footer.Top + ScaleValue(CMetaHeight);
  Result.Height := Max(Result.Footer.Bottom, LAvatarW);

  // Move the column to its side
  if FPlacement = cpStart then
  begin
    OffsetRect(Result.Header, LSide, 0);
    OffsetRect(Result.Bubble, LSide, 0);
    OffsetRect(Result.Footer, LSide, 0);
    if FShowAvatar then
      Result.Avatar := Rect(0, Result.Height - LAvatarW, LAvatarW, Result.Height);
  end
  else
  begin
    Result.Header := Rect(ClientWidth - LSide - LMetaW, Result.Header.Top, ClientWidth - LSide,
      Result.Header.Bottom);
    Result.Footer := Rect(ClientWidth - LSide - LMetaW, Result.Footer.Top, ClientWidth - LSide,
      Result.Footer.Bottom);
    OffsetRect(Result.Bubble, ClientWidth - LSide - LBubbleW, 0);
    if FShowAvatar then
      Result.Avatar := Rect(ClientWidth - LAvatarW, Result.Height - LAvatarW, ClientWidth,
        Result.Height);
  end;
  Result.Text := Rect(Result.Bubble.Left + ScaleValue(CPadX),
    Result.Bubble.Top + (LBubbleH - LTextH) div 2,
    Result.Bubble.Right - ScaleValue(CPadX), 0);
  Result.Text.Bottom := Result.Text.Top + LTextH;
end;

procedure TDaisyChatBubble.UpdateHeight;
var
  LHeight: Integer;
begin
  if (not FAutoHeight) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := BuildLayout.Height;
  if (LHeight <= 0) or (LHeight = Height) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyChatBubble.DrawAvatarPicture(const ARect: TRect);
var
  LSaved: Integer;
  LRegion: HRGN;
  LGraphic: TGraphic;
  LScale: Double;
  LW, LH: Integer;
  LDest: TRect;
begin
  LGraphic := FAvatar.Graphic;
  if (LGraphic.Width <= 0) or (LGraphic.Height <= 0) then
    Exit;
  LScale := Max(ARect.Width / LGraphic.Width, ARect.Height / LGraphic.Height); // cover
  LW := Round(LGraphic.Width * LScale);
  LH := Round(LGraphic.Height * LScale);
  LDest := Rect(ARect.Left + (ARect.Width - LW) div 2, ARect.Top + (ARect.Height - LH) div 2, 0, 0);
  LDest.Right := LDest.Left + LW;
  LDest.Bottom := LDest.Top + LH;
  LDest := MirrorRect(LDest);
  LSaved := SaveDC(Canvas.Handle);
  LRegion := CreateEllipticRgn(MirrorRect(ARect).Left, ARect.Top, MirrorRect(ARect).Right + 1, ARect.Bottom + 1);
  try
    SelectClipRgn(Canvas.Handle, LRegion);
    Canvas.StretchDraw(LDest, LGraphic);
  finally
    RestoreDC(Canvas.Handle, LSaved);
    DeleteObject(LRegion);
  end;
end;

procedure TDaisyChatBubble.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LLayout: TChatLayout;
  LGraphics: TGPGraphics;
  LBrush: TGPSolidBrush;
  LPoints: TArray<TPointF>;
  LGdiPoints: array of TGPPointF;
  LFill, LTextColor, LMeta: TAlphaColor;
  LPalette: TDaisyPalette;
  LBubble: TRectF;
  LName, LTime, LX, I, LInset: Integer;
  LAvatarBox: TRect;
  LHasPicture: Boolean;
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
  LHasPicture := FShowAvatar and HasAvatarPicture;

  LBubble := RectF(LLayout.Bubble.Left, LLayout.Bubble.Top, LLayout.Bubble.Right, LLayout.Bubble.Bottom);
  LPoints := DaisyChatBubblePolygon(LBubble, ResolvedCornerRadius, ScaleValue(CTail), FPlacement);
  SetLength(LGdiPoints, Length(LPoints));
  for I := 0 to High(LPoints) do
    LGdiPoints[I] := MakePoint(LPoints[I].X, LPoints[I].Y);

  LGraphics := NewGraphics;
  try
    LBrush := TGPSolidBrush.Create(LFill);
    try
      LGraphics.FillPolygon(LBrush, PGPPointF(@LGdiPoints[0]), Length(LGdiPoints));
    finally
      LBrush.Free;
    end;
    if FShowAvatar and not LHasPicture then
    begin
      LBrush := TGPSolidBrush.Create(Theme.Base300);
      try
        LGraphics.FillEllipse(LBrush, LLayout.Avatar.Left, LLayout.Avatar.Top,
          LLayout.Avatar.Width, LLayout.Avatar.Height);
      finally
        LBrush.Free;
      end;
    end;
  finally
    LGraphics.Free;
  end;

  if FShowAvatar then
  begin
    if LHasPicture then
      DrawAvatarPicture(LLayout.Avatar)
    else if not FAvatarIcon.IsEmpty then
    begin
      LInset := LLayout.Avatar.Width div 5;
      LAvatarBox := LLayout.Avatar;
      InflateRect(LAvatarBox, -LInset, -LInset);
      DrawGlyph(FAvatarIcon, LAvatarBox, Theme.BaseContent);
    end;
  end;

  DrawRichText(Caption, LLayout.Text, LTextColor, CTextSize, False, DT_LEFT or DT_WORDBREAK);

  if (FHeader <> '') or (FHeaderTime <> '') then
  begin
    LName := MeasureTextWidth(FHeader, CMetaSize, False);
    LTime := MeasureTextWidth(FHeaderTime, CMetaSize, False);
    if FPlacement = cpStart then
      LX := LLayout.Header.Left
    else
      LX := LLayout.Header.Right - (LName + LTime + IfThen((LName > 0) and (LTime > 0), ScaleValue(8)));
    DrawRichText(FHeader, Rect(LX, LLayout.Header.Top, LX + LName + ScaleValue(4), LLayout.Header.Bottom),
      Theme.BaseContent, CMetaSize, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    if LName > 0 then
      Inc(LX, LName + ScaleValue(8));
    DrawText(FHeaderTime, Rect(LX, LLayout.Header.Top, LX + LTime + ScaleValue(4), LLayout.Header.Bottom),
      LMeta, CMetaSize, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;

  if FFooter <> '' then
  begin
    if FPlacement = cpStart then
      DrawRichText(FFooter, LLayout.Footer, LMeta, CMetaSize, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE)
    else
      DrawRichText(FFooter, LLayout.Footer, LMeta, CMetaSize, False, DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;
end;

end.
