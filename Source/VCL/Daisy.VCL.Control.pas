unit Daisy.VCL.Control;

{
  TDaisyControl - base class for all DaisyUI VCL components.

  Owns everything the components have in common: theme resolution, variant /
  style / size, spacing, corner radius, shadow, hover / pressed / focus state,
  transparent corners and the GDI+ drawing helpers. Descendants only describe
  their own content by overriding DrawContent (and a few Default* hooks).
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Vcl.Direct2D, Daisy.Theme, Daisy.SVG, Daisy.Animation, Daisy.Widgets;

type
  TDaisyControl = class(TCustomControl)
  strict private
    FThemeKind: TDaisyThemeKind;
    FVariant: TDaisyVariant;
    FStyle: TDaisyStyle;
    FSize: TDaisySize;
    FContentPadding: Integer;
    FCornerRadius: Integer;
    FShadowSize: Integer;
    FHot: Boolean;
    FPressed: Boolean;
    FShowFocus: Boolean;
    procedure SetThemeKind(const Value: TDaisyThemeKind);
    procedure SetVariant(const Value: TDaisyVariant);
    procedure SetStyle(const Value: TDaisyStyle);
    procedure SetSizeKind(const Value: TDaisySize);
    procedure SetContentPadding(const Value: Integer);
    procedure SetCornerRadius(const Value: Integer);
    procedure SetShadowSize(const Value: Integer);
    procedure SetHot(const Value: Boolean);
    procedure SetPressed(const Value: Boolean);
    function GetTheme: TDaisyTheme;
    procedure GlobalThemeChanged(Sender: TObject);
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    class var FThemedTitleBar: Boolean;
    class procedure SetThemedTitleBar(const Value: Boolean); static;
  protected
    procedure CreateWnd; override;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure Paint; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    { Hooks for descendants }
    function IsInteractive: Boolean; virtual;
    // False when a descendant draws its own focus indication
    function DrawsFocusRing: Boolean; virtual;
    function DefaultCornerRadius: Integer; virtual;
    function DefaultShadowSize: Integer; virtual;
    function DefaultContentPadding: Integer; virtual;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; virtual;
    procedure SizeChanged; virtual;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); virtual;

    { State and metrics }
    function GetState: TDaisyState; virtual;
    function ResolveColors: TDaisyColors;
    function ScaleValue(AValue: Integer): Integer;
    function ResolvedCornerRadius: Integer;
    function ResolvedShadowSize: Integer;
    function ResolvedContentPadding: Integer;
    function BodyRect: TRect;
    function ContentRect: TRect;
    property Hot: Boolean read FHot;
    property Pressed: Boolean read FPressed write SetPressed;

    { Drawing helpers }
    function NewGraphics: TGPGraphics;
    procedure DrawText(const AText: string; const ARect: TRect; AColor: TAlphaColor;
      AFontSize: Integer; ABold: Boolean; AFlags: Cardinal);
    function MeasureTextHeight(const AText: string; AWidth, AFontSize: Integer;
      ABold: Boolean): Integer;
    // As DrawText, but text holding emoji goes through Direct2D so it is drawn in colour
    procedure DrawRichText(const AText: string; const ARect: TRect; AColor: TAlphaColor;
      AFontSize: Integer; ABold: Boolean; AFlags: Cardinal);
    // Draws the SVG icon if there is one, otherwise the emoji, centred in ABox
    procedure DrawGlyph(const AIcon: TDaisyIconSource; const ABox: TRect; AColor: TAlphaColor);
    procedure DrawPolylines(AGraphics: TGPGraphics; const APaths: TDaisyIconPaths;
      const ABounds: TRectF; AColor: TAlphaColor; AStrokeWidth: Single);
    // Colour emoji through Direct2D (falls back to GDI when it is unavailable)
    procedure DrawEmoji(const AText: string; const ARect: TRect; AColor: TAlphaColor;
      AFontSize: Integer);
    // Draws the shared animation primitives scaled into ABounds
    procedure DrawPrims(AGraphics: TGPGraphics; const APrims: TDaisyPrims;
      const ABounds: TRectF; AColor: TAlphaColor);
    function MeasureTextWidth(const AText: string; AFontSize: Integer; ABold: Boolean): Integer;
    // Strokes SVG path data (24 x 24 viewBox) into ABox
    procedure DrawIconPath(const AData: string; const ABox: TRectF; AColor: TAlphaColor);
    // Draws coloured SVG layers (TDaisySVG.Layers) into ABox; AColor is used for currentColor
    procedure DrawSVGLayers(const ALayers: TDaisySVGLayers; const ABox: TRectF; AColor: TAlphaColor);
    // Badge pieces shared by TDaisyBadge and badge-carrying controls.
    // A non-empty AIconPath replaces AIcon.
    function BadgeWidth(const AText: string; ASize: TDaisySize; AIcon: TDaisyIconKind;
      const AIconPath: string = ''): Integer;
    procedure DrawBadgeShape(const ARect: TRect; const AColors: TDaisyColors; ARadius: Integer);
    procedure DrawBadgeContent(const ARect: TRect; const AText: string; AColor: TAlphaColor;
      ASize: TDaisySize; AIcon: TDaisyIconKind; AIconPos: TDaisyBadgeIconPosition;
      const AIconPath: string = '');
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    // Re-colours the caption of every open form from the current theme
    class procedure ApplyTitleBars;
    // When True, form title bars (Windows 11+) follow the current Daisy theme
    class property ThemedTitleBar: Boolean read FThemedTitleBar write SetThemedTitleBar;
    property Theme: TDaisyTheme read GetTheme;
    // The text colour this control resolves for itself (used by child labels)
    function ResolvedTextColor: TAlphaColor;
  published
    property ThemeKind: TDaisyThemeKind read FThemeKind write SetThemeKind default dtInherit;
    property Variant: TDaisyVariant read FVariant write SetVariant default dvDefault;
    property Style: TDaisyStyle read FStyle write SetStyle default dsSolid;
    property SizeKind: TDaisySize read FSize write SetSizeKind default dzMD;
    // -1 = use the value defined by the component / theme
    property ContentPadding: Integer read FContentPadding write SetContentPadding default -1;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius default -1;
    property ShadowSize: Integer read FShadowSize write SetShadowSize default -1;

    property Align;
    property Anchors;
    property Constraints;
    property Cursor;
    property Enabled;
    property Font;
    property Hint;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

function DaisyToColor(AColor: TAlphaColor): TColor;
procedure FillRoundRect(AGraphics: TGPGraphics; const ARect: TRectF; ARadius: Single;
  AColor: TAlphaColor);
procedure StrokeRoundRect(AGraphics: TGPGraphics; const ARect: TRectF; ARadius: Single;
  AColor: TAlphaColor; AWidth: Single; ADashed: Boolean);

implementation

uses
  Vcl.Forms;

type
  TTitleBarHook = class
    procedure ThemeChanged(Sender: TObject);
  end;

var
  GTitleBarHook: TTitleBarHook = nil;

procedure TTitleBarHook.ThemeChanged(Sender: TObject);
begin
  TDaisyControl.ApplyTitleBars;
end;

class procedure TDaisyControl.ApplyTitleBars;
var
  I: Integer;
  LTheme: TDaisyTheme;
begin
  LTheme := DaisyGetTheme(dtInherit);
  for I := 0 to Screen.FormCount - 1 do
    if Screen.Forms[I].HandleAllocated then
      DaisySetTitleBarColors(Screen.Forms[I].Handle, FThemedTitleBar, LTheme);
end;

class procedure TDaisyControl.SetThemedTitleBar(const Value: Boolean);
begin
  if FThemedTitleBar = Value then
    Exit;
  FThemedTitleBar := Value;
  if Value then
  begin
    if GTitleBarHook = nil then
      GTitleBarHook := TTitleBarHook.Create;
    DaisyThemes.AddListener(GTitleBarHook.ThemeChanged);
  end
  else if GTitleBarHook <> nil then
    DaisyRemoveThemeListener(GTitleBarHook.ThemeChanged);
  ApplyTitleBars;
end;

procedure TDaisyControl.CreateWnd;
var
  LForm: TCustomForm;
begin
  inherited CreateWnd;
  if FThemedTitleBar then
  begin
    LForm := GetParentForm(Self);
    if (LForm <> nil) and LForm.HandleAllocated then
      DaisySetTitleBarColors(LForm.Handle, True, DaisyGetTheme(dtInherit));
  end;
end;

function DaisyToColor(AColor: TAlphaColor): TColor;
var
  LRec: TAlphaColorRec;
begin
  LRec := TAlphaColorRec(AColor);
  Result := TColor(RGB(LRec.R, LRec.G, LRec.B)); // TAlphaColor does not fit TColor under range checks
end;

{ TDaisyControl }

constructor TDaisyControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque] + [csParentBackground];
  DoubleBuffered := True;
  FThemeKind := dtInherit;
  FVariant := dvDefault;
  FStyle := dsSolid;
  FSize := dzMD;
  FContentPadding := -1;
  FCornerRadius := -1;
  FShadowSize := -1;
  Font.Name := 'Segoe UI';
  DaisyThemes.AddListener(GlobalThemeChanged);
end;

destructor TDaisyControl.Destroy;
begin
  DaisyRemoveThemeListener(GlobalThemeChanged);
  inherited;
end;

procedure TDaisyControl.Loaded;
begin
  inherited;
  Invalidate;
end;

procedure TDaisyControl.GlobalThemeChanged(Sender: TObject);
begin
  if FThemeKind = dtInherit then
    Invalidate;
end;

{ Properties }

procedure TDaisyControl.SetThemeKind(const Value: TDaisyThemeKind);
begin
  if FThemeKind <> Value then
  begin
    FThemeKind := Value;
    Invalidate;
  end;
end;

procedure TDaisyControl.SetVariant(const Value: TDaisyVariant);
begin
  if FVariant <> Value then
  begin
    FVariant := Value;
    Invalidate;
  end;
end;

procedure TDaisyControl.SetStyle(const Value: TDaisyStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    Invalidate;
  end;
end;

procedure TDaisyControl.SetSizeKind(const Value: TDaisySize);
begin
  if FSize <> Value then
  begin
    FSize := Value;
    if not (csLoading in ComponentState) then
      SizeChanged;
    Invalidate;
  end;
end;

procedure TDaisyControl.SetContentPadding(const Value: Integer);
begin
  if FContentPadding <> Value then
  begin
    FContentPadding := Max(-1, Value);
    Invalidate;
  end;
end;

procedure TDaisyControl.SetCornerRadius(const Value: Integer);
begin
  if FCornerRadius <> Value then
  begin
    FCornerRadius := Max(-1, Value);
    Invalidate;
  end;
end;

procedure TDaisyControl.SetShadowSize(const Value: Integer);
begin
  if FShadowSize <> Value then
  begin
    FShadowSize := Max(-1, Value);
    Invalidate;
  end;
end;

procedure TDaisyControl.SetHot(const Value: Boolean);
begin
  if FHot <> Value then
  begin
    FHot := Value;
    if IsInteractive then
      Invalidate;
  end;
end;

procedure TDaisyControl.SetPressed(const Value: Boolean);
begin
  if FPressed <> Value then
  begin
    FPressed := Value;
    if IsInteractive then
      Invalidate;
  end;
end;

function TDaisyControl.GetTheme: TDaisyTheme;
begin
  Result := DaisyGetTheme(FThemeKind);
end;

{ Hooks }

function TDaisyControl.IsInteractive: Boolean;
begin
  Result := False;
end;

function TDaisyControl.DrawsFocusRing: Boolean;
begin
  Result := True;
end;

function TDaisyControl.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyControl.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyControl.DefaultContentPadding: Integer;
begin
  Result := DaisyCardPadding(FSize);
end;

function TDaisyControl.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := DaisyResolveColors(Theme, FVariant, FStyle, AState);
end;

procedure TDaisyControl.SizeChanged;
begin
end;

procedure TDaisyControl.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
begin
end;

{ State and metrics }

function TDaisyControl.GetState: TDaisyState;
begin
  if not Enabled then
    Exit(dstDisabled);
  if not IsInteractive then
    Exit(dstNormal);
  if FPressed and FHot then
    Result := dstPressed
  else if FHot then
    Result := dstHover
  else
    Result := dstNormal;
end;

function TDaisyControl.ResolveColors: TDaisyColors;
begin
  Result := DefaultStyleColors(GetState);
end;

function TDaisyControl.ResolvedTextColor: TAlphaColor;
begin
  Result := ResolveColors.Text;
end;

function TDaisyControl.ScaleValue(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, 96);
end;

function TDaisyControl.ResolvedCornerRadius: Integer;
begin
  if FCornerRadius >= 0 then
    Result := FCornerRadius
  else
    Result := DefaultCornerRadius;
  Result := ScaleValue(Result);
end;

function TDaisyControl.ResolvedShadowSize: Integer;
begin
  if FShadowSize >= 0 then
    Result := FShadowSize
  else
    Result := DefaultShadowSize;
  Result := ScaleValue(Result);
end;

function TDaisyControl.ResolvedContentPadding: Integer;
begin
  if FContentPadding >= 0 then
    Result := FContentPadding
  else
    Result := DefaultContentPadding;
  Result := ScaleValue(Result);
end;

// The visible shape. The client area is reduced so the shadow is never clipped.
function TDaisyControl.BodyRect: TRect;
var
  LMargin, LOffset: Integer;
begin
  LMargin := ResolvedShadowSize;
  LOffset := LMargin div 2;
  Result := Rect(LMargin, LMargin - LOffset, Width - LMargin, Height - LMargin - LOffset); // no ClientWidth: it would create the window early
end;

function TDaisyControl.ContentRect: TRect;
var
  LPadding: Integer;
begin
  LPadding := ResolvedContentPadding;
  Result := BodyRect;
  InflateRect(Result, -LPadding, -LPadding);
end;

{ Drawing helpers }

function TDaisyControl.NewGraphics: TGPGraphics;
begin
  Result := TGPGraphics.Create(Canvas.Handle);
  Result.SetSmoothingMode(SmoothingModeAntiAlias);
  Result.SetPixelOffsetMode(PixelOffsetModeHalf); // keeps 1px strokes on whole pixels instead of straddling two rows
end;

function CreateRoundRectPath(const ARect: TRectF; ARadius: Single): TGPGraphicsPath;
var
  LRadius, LDiameter: Single;
begin
  Result := TGPGraphicsPath.Create;
  LRadius := Min(ARadius, Min(ARect.Width, ARect.Height) / 2);
  if LRadius <= 0.5 then
  begin
    Result.AddRectangle(MakeRect(ARect.Left, ARect.Top, ARect.Width, ARect.Height));
    Exit;
  end;
  LDiameter := LRadius * 2;
  Result.AddArc(ARect.Left, ARect.Top, LDiameter, LDiameter, 180, 90);
  Result.AddArc(ARect.Right - LDiameter, ARect.Top, LDiameter, LDiameter, 270, 90);
  Result.AddArc(ARect.Right - LDiameter, ARect.Bottom - LDiameter, LDiameter, LDiameter, 0, 90);
  Result.AddArc(ARect.Left, ARect.Bottom - LDiameter, LDiameter, LDiameter, 90, 90);
  Result.CloseFigure;
end;

procedure FillRoundRect(AGraphics: TGPGraphics; const ARect: TRectF; ARadius: Single;
  AColor: TAlphaColor);
var
  LPath: TGPGraphicsPath;
  LBrush: TGPSolidBrush;
begin
  LPath := CreateRoundRectPath(ARect, ARadius);
  LBrush := TGPSolidBrush.Create(AColor);
  try
    AGraphics.FillPath(LBrush, LPath);
  finally
    LBrush.Free;
    LPath.Free;
  end;
end;

procedure StrokeRoundRect(AGraphics: TGPGraphics; const ARect: TRectF; ARadius: Single;
  AColor: TAlphaColor; AWidth: Single; ADashed: Boolean);
var
  LPath: TGPGraphicsPath;
  LPen: TGPPen;
  LRect: TRectF;
begin
  LRect := ARect;
  LRect.Inflate(-AWidth / 2, -AWidth / 2); // strokes are centred on the path
  LPath := CreateRoundRectPath(LRect, Max(0, ARadius - AWidth / 2));
  LPen := TGPPen.Create(AColor, AWidth);
  try
    if ADashed then
      LPen.SetDashStyle(DashStyleDash);
    AGraphics.DrawPath(LPen, LPath);
  finally
    LPen.Free;
    LPath.Free;
  end;
end;

procedure TDaisyControl.Paint;
var
  LGraphics: TGPGraphics;
  LColors: TDaisyColors;
  LBody: TRectF;
  LRadius, LShadow, LOffset, I: Integer;
  LLayer: TRectF;
  LBorder: Single;
begin
  LColors := ResolveColors;
  LRadius := ResolvedCornerRadius;
  LShadow := ResolvedShadowSize;
  LOffset := LShadow div 2;
  LBody := RectF(BodyRect.Left, BodyRect.Top, BodyRect.Right, BodyRect.Bottom);
  LBorder := ScaleValue(Theme.BorderWidth);

  LGraphics := NewGraphics;
  try
    // Soft shadow: stacked translucent rounded rects growing outwards
    if (LShadow > 0) and (TAlphaColorRec(LColors.Background).A = 255) then
      for I := LShadow downto 1 do
      begin
        LLayer := LBody;
        LLayer.Offset(0, LOffset);
        LLayer.Inflate(I, I);
        FillRoundRect(LGraphics, LLayer, LRadius + I,
          TAlphaColor(MakeColor(Max(1, Round(46 / LShadow)), 0, 0, 0)));
      end;

    if TAlphaColorRec(LColors.Background).A > 0 then
      FillRoundRect(LGraphics, LBody, LRadius, LColors.Background);
    if (TAlphaColorRec(LColors.Border).A > 0) and (LBorder > 0) then
      StrokeRoundRect(LGraphics, LBody, LRadius, LColors.Border, LBorder, LColors.Dashed);

    if FShowFocus and Focused and DrawsFocusRing then
    begin
      LLayer := LBody;
      LLayer.Inflate(-ScaleValue(2), -ScaleValue(2));
      StrokeRoundRect(LGraphics, LLayer, Max(0, LRadius - ScaleValue(2)),
        DaisyWithAlpha(Theme.BaseContent, 0.6), ScaleValue(2), False);
    end;
  finally
    LGraphics.Free; // flushes the GDI+ batch before any GDI text is drawn
  end;

  DrawContent(LColors, ContentRect);
end;

procedure TDaisyControl.DrawText(const AText: string; const ARect: TRect; AColor: TAlphaColor;
  AFontSize: Integer; ABold: Boolean; AFlags: Cardinal);
var
  LRect: TRect;
  LColor: TAlphaColor;
  LRec: TAlphaColorRec;
begin
  if AText = '' then
    Exit;
  LColor := AColor;
  if TAlphaColorRec(LColor).A < 255 then // GDI text has no alpha: flatten on the page colour
    LColor := DaisyMix(Theme.Base100, LColor or $FF000000, TAlphaColorRec(LColor).A / 255);
  LRec := TAlphaColorRec(LColor);

  Canvas.Font.Assign(Font);
  Canvas.Font.Height := -ScaleValue(AFontSize);
  Canvas.Font.Color := TColor(RGB(LRec.R, LRec.G, LRec.B));
  if ABold then
    Canvas.Font.Style := Canvas.Font.Style + [fsBold]
  else
    Canvas.Font.Style := Canvas.Font.Style - [fsBold];
  Canvas.Brush.Style := bsClear;

  LRect := ARect;
  SetBkMode(Canvas.Handle, Winapi.Windows.TRANSPARENT);
  Winapi.Windows.DrawText(Canvas.Handle, PChar(AText), Length(AText), LRect,
    AFlags or DT_NOPREFIX);
end;

function TDaisyControl.MeasureTextHeight(const AText: string; AWidth, AFontSize: Integer;
  ABold: Boolean): Integer;
var
  LRect: TRect;
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create; // no window handle needed, so this also works while loading
  try
    LBitmap.Canvas.Font.Assign(Font);
    LBitmap.Canvas.Font.Height := -ScaleValue(AFontSize);
    if ABold then
      LBitmap.Canvas.Font.Style := LBitmap.Canvas.Font.Style + [fsBold]
    else
      LBitmap.Canvas.Font.Style := LBitmap.Canvas.Font.Style - [fsBold];
    LRect := Rect(0, 0, Max(1, AWidth), 0);
    Winapi.Windows.DrawText(LBitmap.Canvas.Handle, PChar(AText), Length(AText), LRect,
      DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
    Result := LRect.Bottom;
  finally
    LBitmap.Free;
  end;
end;

procedure TDaisyControl.DrawRichText(const AText: string; const ARect: TRect;
  AColor: TAlphaColor; AFontSize: Integer; ABold: Boolean; AFlags: Cardinal);
var
  LD2D: TDirect2DCanvas;
  LRect: TRect;
  LText: string;
  LFormats: TTextFormat;
  LColor: TAlphaColor;
begin
  if AText = '' then
    Exit;
  if (not DaisyHasEmoji(AText)) or (not TDirect2DCanvas.Supported) then
  begin
    DrawText(AText, ARect, AColor, AFontSize, ABold, AFlags);
    Exit;
  end;
  LColor := AColor;
  if TAlphaColorRec(LColor).A < 255 then
    LColor := DaisyMix(Theme.Base100, LColor or $FF000000, TAlphaColorRec(LColor).A / 255);
  LFormats := [];
  if AFlags and DT_CENTER <> 0 then
    Include(LFormats, tfCenter)
  else if AFlags and DT_RIGHT <> 0 then
    Include(LFormats, tfRight);
  if AFlags and DT_VCENTER <> 0 then
    Include(LFormats, tfVerticalCenter)
  else if AFlags and DT_BOTTOM <> 0 then
    Include(LFormats, tfBottom);
  if AFlags and DT_SINGLELINE <> 0 then
    Include(LFormats, tfSingleLine)
  else if AFlags and DT_WORDBREAK <> 0 then
    Include(LFormats, tfWordBreak);
  LRect := ARect;
  LText := AText;
  LD2D := TDirect2DCanvas.Create(Canvas, ClientRect);
  try
    LD2D.BeginDraw;
    try
      LD2D.Font.Name := Font.Name;
      LD2D.Font.Height := -ScaleValue(AFontSize);
      if ABold then
        LD2D.Font.Style := [fsBold]
      else
        LD2D.Font.Style := [];
      LD2D.Font.Color := DaisyToColor(LColor);
      LD2D.Brush.Style := bsClear;
      LD2D.TextRect(LRect, LText, LFormats);
    finally
      LD2D.EndDraw;
    end;
  finally
    LD2D.Free;
  end;
end;

procedure TDaisyControl.DrawGlyph(const AIcon: TDaisyIconSource; const ABox: TRect;
  AColor: TAlphaColor);
begin
  if (AIcon = nil) or AIcon.IsEmpty then
    Exit;
  if AIcon.IconPath <> '' then
    DrawIconPath(AIcon.IconPath, TRectF.Create(ABox), AColor)
  else
    DrawEmoji(AIcon.Emoji, ABox, AColor, Round(ABox.Height * 70 / Max(1, ScaleValue(100))));
end;

procedure TDaisyControl.DrawPolylines(AGraphics: TGPGraphics; const APaths: TDaisyIconPaths;
  const ABounds: TRectF; AColor: TAlphaColor; AStrokeWidth: Single);
var
  LPen: TGPPen;
  LPath: TDaisyPolyline;
  LFrom, LTo: TGPPointF;
  LScale: Single;
  I: Integer;
begin
  LScale := ABounds.Width / 24; // icon geometry lives in a 24 x 24 box
  LPen := TGPPen.Create(AColor, AStrokeWidth * LScale);
  try
    LPen.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
    LPen.SetLineJoin(LineJoinRound);
    for LPath in APaths do
      for I := 1 to High(LPath) do
      begin
        LFrom := MakePoint(ABounds.Left + LPath[I - 1].X * LScale, ABounds.Top + LPath[I - 1].Y * LScale);
        LTo := MakePoint(ABounds.Left + LPath[I].X * LScale, ABounds.Top + LPath[I].Y * LScale);
        AGraphics.DrawLine(LPen, LFrom, LTo); // round caps make the joins round
      end;
  finally
    LPen.Free;
  end;
end;

{ Badge helpers }

procedure TDaisyControl.DrawIconPath(const AData: string; const ABox: TRectF; AColor: TAlphaColor);
var
  LGraphics: TGPGraphics;
  LPaths: TDaisyIconPaths;
  LFilled: Boolean;
  LPath: TGPGraphicsPath;
  LBrush: TGPSolidBrush;
  LPoints: array of TGPPointF;
  LScale: Single;
  I, J: Integer;
begin
  LPaths := TDaisySVG.ToPaths(AData, LFilled);
  if Length(LPaths) = 0 then
    Exit;
  LGraphics := NewGraphics;
  try
    if not LFilled then
      DrawPolylines(LGraphics, LPaths, ABox, AColor, 2)
    else
    begin
      LScale := ABox.Width / 24;
      LPath := TGPGraphicsPath.Create(FillModeWinding);
      LBrush := TGPSolidBrush.Create(AColor);
      try
        for I := 0 to High(LPaths) do
        begin
          SetLength(LPoints, Length(LPaths[I]));
          for J := 0 to High(LPaths[I]) do
            LPoints[J] := MakePoint(ABox.Left + LPaths[I][J].X * LScale,
              ABox.Top + LPaths[I][J].Y * LScale);
          LPath.StartFigure;
          LPath.AddPolygon(PGPPointF(@LPoints[0]), Length(LPoints));
        end;
        LGraphics.FillPath(LBrush, LPath);
      finally
        LBrush.Free;
        LPath.Free;
      end;
    end;
  finally
    LGraphics.Free; // flush before any GDI text
  end;
end;

procedure TDaisyControl.DrawSVGLayers(const ALayers: TDaisySVGLayers; const ABox: TRectF;
  AColor: TAlphaColor);
var
  LGraphics: TGPGraphics;
  LLayer: TDaisySVGLayer;
  LPath: TGPGraphicsPath;
  LBrush: TGPSolidBrush;
  LPen: TGPPen;
  LPoints: array of TGPPointF;
  LScale: Single;
  I, J: Integer;

  procedure LoadPoints(const APolyline: TDaisyPolyline);
  var
    K: Integer;
  begin
    SetLength(LPoints, Length(APolyline));
    for K := 0 to High(APolyline) do
      LPoints[K] := MakePoint(ABox.Left + APolyline[K].X * LScale, ABox.Top + APolyline[K].Y * LScale);
  end;

begin
  if (Length(ALayers) = 0) or (ABox.Width <= 0) then
    Exit;
  LScale := ABox.Width / 24;
  LGraphics := NewGraphics;
  try
    for LLayer in ALayers do
    begin
      if LLayer.HasFill then
      begin
        if LLayer.EvenOdd then
          LPath := TGPGraphicsPath.Create(FillModeAlternate)
        else
          LPath := TGPGraphicsPath.Create(FillModeWinding);
        LBrush := TGPSolidBrush.Create(TDaisySVG.LayerColor(LLayer, True, AColor));
        try
          for I := 0 to High(LLayer.Paths) do
          begin
            if Length(LLayer.Paths[I]) < 3 then
              Continue;
            LoadPoints(LLayer.Paths[I]);
            LPath.StartFigure;
            LPath.AddPolygon(PGPPointF(@LPoints[0]), Length(LPoints));
          end;
          LGraphics.FillPath(LBrush, LPath);
        finally
          LBrush.Free;
          LPath.Free;
        end;
      end;
      if LLayer.HasStroke then
      begin
        LPath := TGPGraphicsPath.Create;
        LPen := TGPPen.Create(TDaisySVG.LayerColor(LLayer, False, AColor), LLayer.StrokeWidth * LScale);
        try
          LPen.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
          LPen.SetLineJoin(LineJoinRound);
          for J := 0 to High(LLayer.Paths) do
          begin
            if Length(LLayer.Paths[J]) < 2 then
              Continue;
            LoadPoints(LLayer.Paths[J]);
            LPath.StartFigure;
            LPath.AddLines(PGPPointF(@LPoints[0]), Length(LPoints));
          end;
          LGraphics.DrawPath(LPen, LPath);
        finally
          LPen.Free;
          LPath.Free;
        end;
      end;
    end;
  finally
    LGraphics.Free; // flush before any GDI text
  end;
end;

function TDaisyControl.MeasureTextWidth(const AText: string; AFontSize: Integer;
  ABold: Boolean): Integer;
var
  LBitmap: TBitmap;
begin
  if AText = '' then
    Exit(0);
  LBitmap := TBitmap.Create; // measuring needs no window handle, so it works at design time too
  try
    LBitmap.Canvas.Font.Assign(Font);
    LBitmap.Canvas.Font.Height := -ScaleValue(AFontSize);
    if ABold then
      LBitmap.Canvas.Font.Style := LBitmap.Canvas.Font.Style + [fsBold]
    else
      LBitmap.Canvas.Font.Style := LBitmap.Canvas.Font.Style - [fsBold];
    Result := LBitmap.Canvas.TextWidth(AText);
  finally
    LBitmap.Free;
  end;
end;

function TDaisyControl.BadgeWidth(const AText: string; ASize: TDaisySize;
  AIcon: TDaisyIconKind; const AIconPath: string): Integer;
var
  LFont, LIconW, LTextW: Integer;
begin
  LFont := DaisyBadgeFontSize(ASize);
  LTextW := MeasureTextWidth(AText, LFont, False);
  LIconW := 0;
  if (AIconPath <> '') or not (AIcon in [diAuto, diNone]) then
    LIconW := ScaleValue(LFont - 2);
  Result := ScaleValue(DaisyBadgeHeight(ASize)) + LIconW + LTextW;
  if (LIconW > 0) and (LTextW > 0) then
    Inc(Result, ScaleValue(LFont div 2));
end;

procedure TDaisyControl.DrawBadgeShape(const ARect: TRect; const AColors: TDaisyColors;
  ARadius: Integer);
var
  LGraphics: TGPGraphics;
  LRect: TRectF;
  LBorder: Single;
begin
  LBorder := ScaleValue(Theme.BorderWidth);
  LRect := RectF(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
  LGraphics := NewGraphics;
  try
    if TAlphaColorRec(AColors.Background).A > 0 then
      FillRoundRect(LGraphics, LRect, ARadius, AColors.Background);
    if (TAlphaColorRec(AColors.Border).A > 0) and (LBorder > 0) then
      StrokeRoundRect(LGraphics, LRect, ARadius, AColors.Border, LBorder, AColors.Dashed);
  finally
    LGraphics.Free;
  end;
end;

procedure TDaisyControl.DrawBadgeContent(const ARect: TRect; const AText: string;
  AColor: TAlphaColor; ASize: TDaisySize; AIcon: TDaisyIconKind;
  AIconPos: TDaisyBadgeIconPosition; const AIconPath: string);
var
  LFont, LIconSize, LGap, LTextW, LTotal, LX, LIconX, LTextX: Integer;
  LHasIcon: Boolean;
  LGraphics: TGPGraphics;
  LIconTop: Single;
begin
  LFont := DaisyBadgeFontSize(ASize);
  LHasIcon := (AIconPath <> '') or not (AIcon in [diAuto, diNone]);
  LIconSize := 0;
  LGap := 0;
  if LHasIcon then
    LIconSize := ScaleValue(LFont - 2);
  LTextW := MeasureTextWidth(AText, LFont, False);
  if LHasIcon and (LTextW > 0) then
    LGap := ScaleValue(LFont div 2);

  LTotal := LIconSize + LGap + LTextW;
  LX := ARect.Left + ((ARect.Right - ARect.Left) - LTotal) div 2;
  if (AIconPos = bipLeft) or not LHasIcon then
  begin
    LIconX := LX;
    LTextX := LX + LIconSize + LGap;
  end
  else
  begin
    LTextX := LX;
    LIconX := LX + LTextW + LGap;
  end;

  if LHasIcon then
  begin
    LIconTop := ARect.Top + ((ARect.Bottom - ARect.Top) - LIconSize) / 2;
    if AIconPath <> '' then
      DrawIconPath(AIconPath, RectF(LIconX, LIconTop, LIconX + LIconSize, LIconTop + LIconSize),
        AColor)
    else
    begin
      LGraphics := NewGraphics;
      try
        DrawPolylines(LGraphics, DaisyIconPaths(AIcon),
          RectF(LIconX, LIconTop, LIconX + LIconSize, LIconTop + LIconSize), AColor, 2);
      finally
        LGraphics.Free; // flush before the GDI text below
      end;
    end;
  end;
  DrawText(AText, Rect(LTextX, ARect.Top, LTextX + LTextW + 2, ARect.Bottom), AColor, LFont, False,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);
end;

{ Events / messages }

procedure TDaisyControl.DrawEmoji(const AText: string; const ARect: TRect; AColor: TAlphaColor;
  AFontSize: Integer);
const
  CEmojiFont = 'Segoe UI Emoji';
var
  LD2D: TDirect2DCanvas;
  LRect: TRect;
  LText: string;
  LColor: TAlphaColor;
begin
  if AText = '' then
    Exit;
  LColor := AColor;
  if TAlphaColorRec(LColor).A < 255 then
    LColor := DaisyMix(Theme.Base100, LColor or $FF000000, TAlphaColorRec(LColor).A / 255);

  if not TDirect2DCanvas.Supported then
  begin
    Canvas.Font.Name := CEmojiFont;
    DrawText(AText, ARect, LColor, AFontSize, False,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    Exit;
  end;

  LRect := ARect;
  LText := AText;
  LD2D := TDirect2DCanvas.Create(Canvas, ClientRect);
  try
    LD2D.BeginDraw;
    try
      LD2D.Font.Name := CEmojiFont;
      LD2D.Font.Height := -ScaleValue(AFontSize);
      LD2D.Font.Color := DaisyToColor(LColor);
      LD2D.Brush.Style := bsClear;
      LD2D.TextRect(LRect, LText, [tfCenter, tfVerticalCenter, tfSingleLine]);
    finally
      LD2D.EndDraw;
    end;
  finally
    LD2D.Free;
  end;
end;

procedure TDaisyControl.DrawPrims(AGraphics: TGPGraphics; const APrims: TDaisyPrims;
  const ABounds: TRectF; AColor: TAlphaColor);
var
  LPrim: TDaisyPrim;
  LScale, LX, LY, LW, LH: Single;
  LPen: TGPPen;
  LBrush: TGPSolidBrush;
  LColor: TAlphaColor;
begin
  LScale := ABounds.Width / 24; // primitives live in a 24 x 24 box
  for LPrim in APrims do
  begin
    LX := ABounds.Left + LPrim.Bounds.Left * LScale;
    LY := ABounds.Top + LPrim.Bounds.Top * LScale;
    LW := LPrim.Bounds.Width * LScale;
    LH := LPrim.Bounds.Height * LScale;
    LColor := DaisyWithAlpha(AColor, LPrim.Alpha);
    case LPrim.Kind of
      pkArc, pkEllipseStroke:
        begin
          LPen := TGPPen.Create(LColor, LPrim.StrokeWidth * LScale);
          try
            LPen.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
            if LPrim.Kind = pkArc then
              AGraphics.DrawArc(LPen, LX, LY, LW, LH, LPrim.StartAngle, LPrim.SweepAngle)
            else
              AGraphics.DrawEllipse(LPen, LX, LY, LW, LH);
          finally
            LPen.Free;
          end;
        end;
      pkEllipseFill:
        begin
          LBrush := TGPSolidBrush.Create(LColor);
          try
            AGraphics.FillEllipse(LBrush, LX, LY, LW, LH);
          finally
            LBrush.Free;
          end;
        end;
      pkRoundRectFill:
        FillRoundRect(AGraphics, RectF(LX, LY, LX + LW, LY + LH), LW / 2, LColor);
    end;
  end;
end;

{ Events / messages }

procedure TDaisyControl.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TDaisyControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FShowFocus := False;
    SetPressed(True);
  end;
end;

procedure TDaisyControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
    SetPressed(False);
end;

// Repaint without erasing on screen: the double buffer already paints the parent
// background into memory, so a screen erase only causes flicker.
procedure TDaisyControl.Invalidate;
begin
  if HandleAllocated and Visible and not (csDesigning in ComponentState) then
    InvalidateRect(Handle, nil, False)
  else
    inherited Invalidate;
end;

// Parent surface is painted into our background so rounded corners are transparent.
procedure TDaisyControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
var
  LSaved: Integer;
  LOrigin: TPoint;
begin
  if Parent <> nil then
  begin
    LSaved := SaveDC(Message.DC);
    try
      GetViewportOrgEx(Message.DC, LOrigin);
      SetViewportOrgEx(Message.DC, LOrigin.X - Left, LOrigin.Y - Top, nil);
      IntersectClipRect(Message.DC, 0, 0, Parent.ClientWidth, Parent.ClientHeight);
      Parent.Perform(WM_ERASEBKGND, WPARAM(Message.DC), 0);
      if Parent is TCustomControl then
        Parent.Perform(WM_PRINTCLIENT, WPARAM(Message.DC), PRF_CLIENT);
    finally
      RestoreDC(Message.DC, LSaved);
    end;
  end
  else
    FillRect(Message.DC, ClientRect, Brush.Handle);
  Message.Result := 1;
end;

procedure TDaisyControl.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  // Only show the focus ring when focus arrived via Tab, not a click or the initial form focus
  FShowFocus := GetKeyState(VK_TAB) < 0;
  Invalidate;
end;

procedure TDaisyControl.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FShowFocus := False;
  Invalidate;
end;

procedure TDaisyControl.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  SetHot(True);
end;

procedure TDaisyControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHot(False);
end;

procedure TDaisyControl.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TDaisyControl.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

end.
