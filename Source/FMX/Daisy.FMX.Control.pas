unit Daisy.FMX.Control;

{
  TDaisyControl - base class for all DaisyUI FMX components.

  Owns everything the components have in common: theme resolution, variant /
  style / size, spacing, corner radius, shadow, hover / pressed / focus state
  and the drawing helpers. Descendants only describe their own content by
  overriding DrawContent (and a few Default* hooks).
  Mirrors Daisy.VCL.Control so both frameworks share one public API.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math, System.Math.Vectors,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.TextLayout, Daisy.Theme, Daisy.SVG, Daisy.Animation, Daisy.Widgets;

type
  TDaisyControl = class(TControl)
  strict private
    FThemeKind: TDaisyThemeKind;
    FVariant: TDaisyVariant;
    FStyle: TDaisyStyle;
    FSizeKind: TDaisySize;
    FContentPadding: Integer;
    FCornerRadius: Integer;
    FShadowSize: Integer;
    FHot: Boolean;
    FPressed: Boolean;
    FShowFocus: Boolean;
    FBiDiMode: TBiDiMode;
    FParentBiDiMode: Boolean;
    FFlipGlyphs: Boolean;
    FUprightDepth: Integer;
    function GetBiDiMode: TBiDiMode;
    procedure SetBiDiMode(const Value: TBiDiMode);
    procedure SetParentBiDiMode(const Value: Boolean);
    function IsBiDiModeStored: Boolean;
    procedure BiDiModeChanged;
    procedure SetThemeKind(const Value: TDaisyThemeKind);
    procedure SetVariant(const Value: TDaisyVariant);
    procedure SetStyle(const Value: TDaisyStyle);
    procedure SetSizeKind(const Value: TDaisySize);
    procedure SetContentPadding(const Value: Integer);
    procedure SetCornerRadius(const Value: Integer);
    procedure SetShadowSize(const Value: Integer);
    procedure SetPressed(const Value: Boolean);
    function GetTheme: TDaisyTheme;
    procedure GlobalThemeChanged(Sender: TObject);
    class var FThemedTitleBar: Boolean;
    class procedure SetThemedTitleBar(const Value: Boolean); static;
  protected
    procedure Paint; override;
    procedure Loaded; override;
    procedure EnabledChanged; override;
    procedure DoMouseEnter; override;
    procedure DoMouseLeave; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;

    { Hooks for descendants }
    function IsInteractive: Boolean; virtual;
    // False when a descendant draws its own focus indication
    function DrawsFocusRing: Boolean; virtual;
    procedure FillRound(const ARect: TRectF; ARadius: Single; AColor: TAlphaColor);
    procedure StrokeRound(const ARect: TRectF; ARadius: Single; AColor: TAlphaColor;
      AWidth: Single; ADashed: Boolean);
    function DefaultCornerRadius: Integer; virtual;
    function DefaultShadowSize: Integer; virtual;
    function DefaultContentPadding: Integer; virtual;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; virtual;
    procedure SizeChanged; virtual;

    { Right-to-left support: components lay out in left-to-right coordinates and
      the canvas and mouse are mirrored when RTL }
    function IsRTL: Boolean;        // layout and alignment are mirrored
    function IsRTLReading: Boolean; // text reads right to left
    function MirrorMatrix: TMatrix;
    // Mirrors the canvas; call first in a Paint override that does not call inherited
    procedure ApplyRTLMatrix;
    // Draws upright (not mirrored) inside ABox while the canvas is mirrored
    function BeginUpright(var ABox: TRectF; AGlyph: Boolean = False): Boolean;
    procedure EndUpright(AActive: Boolean);
    function MirrorX(AX: Single): Single;
    function LocalToAbsoluteRect(const ARect: TRectF): TRectF;
    procedure ParentChanged; override;
    // Directional glyphs (arrows, chevrons) stay mirrored when this is True
    property FlipGlyphs: Boolean read FFlipGlyphs write FFlipGlyphs;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); virtual;

    { State and metrics }
    function GetState: TDaisyState; virtual;
    function ResolveColors: TDaisyColors;
    function ResolvedCornerRadius: Single;
    function ResolvedShadowSize: Integer;
    function ResolvedContentPadding: Single;
    function BodyRect: TRectF;
    function ContentRect: TRectF;
    property Hot: Boolean read FHot;
    property Pressed: Boolean read FPressed write SetPressed;

    { Drawing helpers }
    procedure DrawText(const AText: string; const ARect: TRectF; AColor: TAlphaColor;
      AFontSize: Integer; ABold: Boolean; AHorzAlign, AVertAlign: TTextAlign;
      AWordWrap: Boolean);
    function MeasureTextHeight(const AText: string; AWidth: Single; AFontSize: Integer;
      ABold: Boolean): Single;
    procedure DrawPolylines(const APaths: TDaisyIconPaths; const ABounds: TRectF;
      AColor: TAlphaColor; AStrokeWidth: Single);
    // Text in the platform colour-emoji font
    procedure DrawEmoji(const AText: string; const ARect: TRectF; AColor: TAlphaColor;
      AFontSize: Integer);
    // Draws the SVG icon if there is one, otherwise the emoji, centred in ABox
    procedure DrawGlyph(const AIcon: TDaisyIconSource; const ABox: TRectF; AColor: TAlphaColor);
    // Draws the shared animation primitives scaled into ABounds
    procedure DrawPrims(const APrims: TDaisyPrims; const ABounds: TRectF; AColor: TAlphaColor);
    function MeasureTextWidth(const AText: string; AFontSize: Integer; ABold: Boolean): Single;
    // Strokes SVG path data (24 x 24 viewBox) into ABox
    procedure DrawIconPath(const AData: string; const ABox: TRectF; AColor: TAlphaColor);
    // Draws coloured SVG layers (TDaisySVG.Layers) into ABox; AColor is used for currentColor
    procedure DrawSVGLayers(const ALayers: TDaisySVGLayers; const ABox: TRectF; AColor: TAlphaColor);
    // Badge pieces shared by TDaisyFmxBadge and badge-carrying controls.
    // A non-empty AIconPath replaces AIcon.
    function BadgeWidth(const AText: string; ASize: TDaisySize; AIcon: TDaisyIconKind;
      const AIconPath: string = ''): Single;
    procedure DrawBadgeShape(const ARect: TRectF; const AColors: TDaisyColors; ARadius: Single);
    procedure DrawBadgeContent(const ARect: TRectF; const AText: string; AColor: TAlphaColor;
      ASize: TDaisySize; AIcon: TDaisyIconKind; AIconPos: TDaisyBadgeIconPosition;
      const AIconPath: string = '');
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AbsoluteToLocal(const APoint: TPointF): TPointF; override;
    function LocalToAbsolute(const APoint: TPointF): TPointF; override;
    // Re-colours the caption of every visible form from the current theme (Windows only)
    class procedure ApplyTitleBars;
    // Sets the form's BiDiMode (and optionally flips its child controls) and refreshes every Daisy control
    class procedure ApplyBiDiMode(AForm: TCommonCustomForm; AMode: TBiDiMode;
      AFlipChildren: Boolean = True);
    // When True, form title bars (Windows 11+) follow the current Daisy theme
    class property ThemedTitleBar: Boolean read FThemedTitleBar write SetThemedTitleBar;
    property Theme: TDaisyTheme read GetTheme;
    // The text colour this control resolves for itself (used by child labels)
    function ResolvedTextColor: TAlphaColor;
  published
    property ThemeKind: TDaisyThemeKind read FThemeKind write SetThemeKind default dtInherit;
    property Variant: TDaisyVariant read FVariant write SetVariant default dvDefault;
    property Style: TDaisyStyle read FStyle write SetStyle default dsSolid;
    property SizeKind: TDaisySize read FSizeKind write SetSizeKind default dzMD;
    // -1 = use the value defined by the component / theme
    property ContentPadding: Integer read FContentPadding write SetContentPadding default -1;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius default -1;
    property ShadowSize: Integer read FShadowSize write SetShadowSize default -1;
    // Right-to-left: mirrors the layout and drawing; children inherit when ParentBiDiMode
    property BiDiMode: TBiDiMode read GetBiDiMode write SetBiDiMode stored IsBiDiModeStored;
    property ParentBiDiMode: Boolean read FParentBiDiMode write SetParentBiDiMode default True;

    property Align;
    property Anchors;
    property Cursor;
    property Enabled;
    property Height;
    property Hint;
    property HitTest default True;
    property Margins;
    property Opacity;
    property Position;
    property Size;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible default True;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

{$IFDEF MSWINDOWS}
uses
  FMX.Platform.Win;
{$ENDIF}

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
{$IFDEF MSWINDOWS}
var
  I: Integer;
  LTheme: TDaisyTheme;
  LForm: TCommonCustomForm;
begin
  LTheme := DaisyGetTheme(dtInherit);
  for I := 0 to Screen.FormCount - 1 do
  begin
    LForm := Screen.Forms[I];
    if LForm.Visible then
      DaisySetTitleBarColors(NativeUInt(FormToHWND(LForm)), FThemedTitleBar, LTheme);
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

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

{ TDaisyControl }

constructor TDaisyControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeKind := dtInherit;
  FVariant := dvDefault;
  FStyle := dsSolid;
  FSizeKind := dzMD;
  FContentPadding := -1;
  FCornerRadius := -1;
  FShadowSize := -1;
  FBiDiMode := bdLeftToRight;
  FParentBiDiMode := True;
  AutoCapture := True; // keeps the pressed state correct when the mouse leaves
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
  if FThemedTitleBar then
    TThread.ForceQueue(nil, ApplyTitleBars); // the form window exists only after it is shown
  Repaint;
end;

procedure TDaisyControl.GlobalThemeChanged(Sender: TObject);
begin
  if FThemeKind = dtInherit then
    Repaint;
end;

{ Properties }

procedure TDaisyControl.SetThemeKind(const Value: TDaisyThemeKind);
begin
  if FThemeKind <> Value then
  begin
    FThemeKind := Value;
    Repaint;
  end;
end;

procedure TDaisyControl.SetVariant(const Value: TDaisyVariant);
begin
  if FVariant <> Value then
  begin
    FVariant := Value;
    Repaint;
  end;
end;

procedure TDaisyControl.SetStyle(const Value: TDaisyStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    Repaint;
  end;
end;

procedure TDaisyControl.SetSizeKind(const Value: TDaisySize);
begin
  if FSizeKind <> Value then
  begin
    FSizeKind := Value;
    if not (csLoading in ComponentState) then
      SizeChanged;
    Repaint;
  end;
end;

procedure TDaisyControl.SetContentPadding(const Value: Integer);
begin
  if FContentPadding <> Value then
  begin
    FContentPadding := Max(-1, Value);
    Repaint;
  end;
end;

procedure TDaisyControl.SetCornerRadius(const Value: Integer);
begin
  if FCornerRadius <> Value then
  begin
    FCornerRadius := Max(-1, Value);
    Repaint;
  end;
end;

procedure TDaisyControl.SetShadowSize(const Value: Integer);
begin
  if FShadowSize <> Value then
  begin
    FShadowSize := Max(-1, Value);
    Repaint;
  end;
end;

procedure TDaisyControl.SetPressed(const Value: Boolean);
begin
  if FPressed <> Value then
  begin
    FPressed := Value;
    if IsInteractive then
      Repaint;
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

procedure TDaisyControl.FillRound(const ARect: TRectF; ARadius: Single; AColor: TAlphaColor);
begin
  if TAlphaColorRec(AColor).A = 0 then
    Exit;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := AColor;
  Canvas.FillRect(ARect, ARadius, ARadius, AllCorners, AbsoluteOpacity);
end;

procedure TDaisyControl.StrokeRound(const ARect: TRectF; ARadius: Single; AColor: TAlphaColor;
  AWidth: Single; ADashed: Boolean);
var
  LRect: TRectF;
begin
  if (TAlphaColorRec(AColor).A = 0) or (AWidth <= 0) then
    Exit;
  LRect := ARect;
  LRect.Inflate(-AWidth / 2, -AWidth / 2);
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := AColor;
  Canvas.Stroke.Thickness := AWidth;
  if ADashed then
    Canvas.Stroke.Dash := TStrokeDash.Dash
  else
    Canvas.Stroke.Dash := TStrokeDash.Solid;
  Canvas.DrawRect(LRect, Max(0, ARadius - AWidth / 2), Max(0, ARadius - AWidth / 2),
    AllCorners, AbsoluteOpacity);
  Canvas.Stroke.Dash := TStrokeDash.Solid;
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
  Result := DaisyCardPadding(FSizeKind);
end;

function TDaisyControl.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := DaisyResolveColors(Theme, FVariant, FStyle, AState);
end;

procedure TDaisyControl.SizeChanged;
begin
end;

procedure TDaisyControl.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
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

function TDaisyControl.ResolvedTextColor: TAlphaColor;
begin
  Result := ResolveColors.Text;
end;

function TDaisyControl.ResolveColors: TDaisyColors;
begin
  Result := DefaultStyleColors(GetState);
end;

function TDaisyControl.ResolvedCornerRadius: Single;
begin
  if FCornerRadius >= 0 then
    Result := FCornerRadius
  else
    Result := DefaultCornerRadius;
  Result := Min(Result, Min(Width, Height) / 2);
end;

function TDaisyControl.ResolvedShadowSize: Integer;
begin
  if FShadowSize >= 0 then
    Result := FShadowSize
  else
    Result := DefaultShadowSize;
end;

function TDaisyControl.ResolvedContentPadding: Single;
begin
  if FContentPadding >= 0 then
    Result := FContentPadding
  else
    Result := DefaultContentPadding;
end;

// The visible shape. The control area is reduced so the shadow is never clipped.
function TDaisyControl.BodyRect: TRectF;
var
  LMargin, LOffset: Integer;
begin
  LMargin := ResolvedShadowSize;
  LOffset := LMargin div 2;
  Result := RectF(LMargin, LMargin - LOffset, Width - LMargin, Height - LMargin - LOffset);
end;

function TDaisyControl.ContentRect: TRectF;
var
  LPadding: Single;
begin
  LPadding := ResolvedContentPadding;
  Result := BodyRect;
  Result.Inflate(-LPadding, -LPadding);
end;

{ Right-to-left }

function TDaisyControl.GetBiDiMode: TBiDiMode;
var
  LParent: TFmxObject;
begin
  if not FParentBiDiMode then
    Exit(FBiDiMode);
  LParent := Parent;
  while (LParent <> nil) and not (LParent is TDaisyControl) do
    LParent := LParent.Parent;
  if LParent <> nil then
    Result := TDaisyControl(LParent).BiDiMode
  else if Root <> nil then
    Result := Root.BiDiMode
  else
    Result := FBiDiMode;
end;

function TDaisyControl.IsBiDiModeStored: Boolean;
begin
  Result := not FParentBiDiMode;
end;

procedure TDaisyControl.SetBiDiMode(const Value: TBiDiMode);
begin
  if (FBiDiMode = Value) and not FParentBiDiMode then
    Exit;
  FBiDiMode := Value;
  FParentBiDiMode := False;
  BiDiModeChanged;
end;

procedure TDaisyControl.SetParentBiDiMode(const Value: Boolean);
begin
  if FParentBiDiMode = Value then
    Exit;
  FParentBiDiMode := Value;
  BiDiModeChanged;
end;

procedure TDaisyControl.BiDiModeChanged;

  procedure Notify(AParent: TFmxObject);
  var
    I: Integer;
    LChild: TFmxObject;
  begin
    if AParent.Children = nil then
      Exit;
    for I := 0 to AParent.Children.Count - 1 do
    begin
      LChild := AParent.Children[I];
      if LChild is TDaisyControl then
      begin
        if TDaisyControl(LChild).FParentBiDiMode then
          TDaisyControl(LChild).BiDiModeChanged;
      end
      else
        Notify(LChild);
    end;
  end;

begin
  Notify(Self);
  SizeChanged;
  Repaint;
end;

class procedure TDaisyControl.ApplyBiDiMode(AForm: TCommonCustomForm; AMode: TBiDiMode;
  AFlipChildren: Boolean);

  procedure Notify(AParent: TFmxObject);
  var
    I: Integer;
    LChild: TFmxObject;
  begin
    if AParent.Children = nil then
      Exit;
    for I := 0 to AParent.Children.Count - 1 do
    begin
      LChild := AParent.Children[I];
      if LChild is TDaisyControl then
      begin
        if TDaisyControl(LChild).FParentBiDiMode then
          TDaisyControl(LChild).BiDiModeChanged;
      end
      else
        Notify(LChild);
    end;
  end;

begin
  if AForm.BiDiMode = AMode then
    Exit;
  AForm.BiDiMode := AMode;
  if AFlipChildren then
    AForm.FlipChildren(True);
  Notify(AForm);
  AForm.Invalidate;
end;

procedure TDaisyControl.ParentChanged;
begin
  inherited;
  if FParentBiDiMode then
    Repaint;
end;

function TDaisyControl.IsRTL: Boolean;
begin
  Result := BiDiMode = bdRightToLeft;
end;

function TDaisyControl.IsRTLReading: Boolean;
begin
  Result := BiDiMode <> bdLeftToRight;
end;

function TDaisyControl.MirrorX(AX: Single): Single;
begin
  Result := Width - AX;
end;

function TDaisyControl.MirrorMatrix: TMatrix;
begin
  Result := TMatrix.Identity;
  Result.m11 := -1;
  Result.m31 := Width;
end;

procedure TDaisyControl.ApplyRTLMatrix;
begin
  if IsRTL then
    Canvas.SetMatrix(MirrorMatrix * AbsoluteMatrix);
end;

function TDaisyControl.BeginUpright(var ABox: TRectF; AGlyph: Boolean): Boolean;
var
  LLeft: Single;
begin
  Result := IsRTL and (FUprightDepth = 0) and not (AGlyph and FFlipGlyphs);
  if Result then
  begin
    FUprightDepth := 1;
    Canvas.SetMatrix(AbsoluteMatrix);
    LLeft := Width - ABox.Right;
    ABox.Right := Width - ABox.Left;
    ABox.Left := LLeft;
  end;
end;

procedure TDaisyControl.EndUpright(AActive: Boolean);
begin
  if AActive then
  begin
    FUprightDepth := 0;
    Canvas.SetMatrix(MirrorMatrix * AbsoluteMatrix);
  end;
end;

function TDaisyControl.AbsoluteToLocal(const APoint: TPointF): TPointF;
begin
  Result := inherited AbsoluteToLocal(APoint);
  if IsRTL then
    Result.X := Width - Result.X;
end;

function TDaisyControl.LocalToAbsolute(const APoint: TPointF): TPointF;
var
  LPoint: TPointF;
begin
  LPoint := APoint;
  if IsRTL then
    LPoint.X := Width - LPoint.X;
  Result := inherited LocalToAbsolute(LPoint);
end;

function TDaisyControl.LocalToAbsoluteRect(const ARect: TRectF): TRectF;
var
  LTopLeft, LBottomRight: TPointF;
begin
  LTopLeft := LocalToAbsolute(ARect.TopLeft);
  LBottomRight := LocalToAbsolute(ARect.BottomRight);
  Result := RectF(Min(LTopLeft.X, LBottomRight.X), Min(LTopLeft.Y, LBottomRight.Y),
    Max(LTopLeft.X, LBottomRight.X), Max(LTopLeft.Y, LBottomRight.Y));
end;

{ Painting }

procedure TDaisyControl.Paint;
var
  LColors: TDaisyColors;
  LBody, LLayer: TRectF;
  LRadius: Single;
  LShadow, LOffset, I: Integer;
  LBorder: Single;
begin
  LColors := ResolveColors;
  LRadius := ResolvedCornerRadius;
  LShadow := ResolvedShadowSize;
  LOffset := LShadow div 2;
  LBody := BodyRect;
  LBorder := Theme.BorderWidth;

  ApplyRTLMatrix;
  Canvas.Fill.Kind := TBrushKind.Solid;

  // Soft shadow: stacked translucent rounded rects growing outwards
  if (LShadow > 0) and (TAlphaColorRec(LColors.Background).A = 255) then
    for I := LShadow downto 1 do
    begin
      LLayer := LBody;
      LLayer.Offset(0, LOffset);
      LLayer.Inflate(I, I);
      Canvas.Fill.Color := TAlphaColor(Max(1, Round(46 / LShadow))) shl 24;
      Canvas.FillRect(LLayer, LRadius + I, LRadius + I, AllCorners, AbsoluteOpacity);
    end;

  if TAlphaColorRec(LColors.Background).A > 0 then
  begin
    Canvas.Fill.Color := LColors.Background;
    Canvas.FillRect(LBody, LRadius, LRadius, AllCorners, AbsoluteOpacity);
  end;

  if (TAlphaColorRec(LColors.Border).A > 0) and (LBorder > 0) then
  begin
    LLayer := LBody;
    LLayer.Inflate(-LBorder / 2, -LBorder / 2); // strokes are centred on the path
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := LColors.Border;
    Canvas.Stroke.Thickness := LBorder;
    if LColors.Dashed then
      Canvas.Stroke.Dash := TStrokeDash.Dash
    else
      Canvas.Stroke.Dash := TStrokeDash.Solid;
    Canvas.DrawRect(LLayer, Max(0, LRadius - LBorder / 2), Max(0, LRadius - LBorder / 2),
      AllCorners, AbsoluteOpacity);
    Canvas.Stroke.Dash := TStrokeDash.Solid;
  end;

  if FShowFocus and IsFocused and DrawsFocusRing then
  begin
    LLayer := LBody;
    LLayer.Inflate(-2, -2);
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := DaisyWithAlpha(Theme.BaseContent, 0.6);
    Canvas.Stroke.Thickness := 2;
    Canvas.DrawRect(LLayer, Max(0, LRadius - 2), Max(0, LRadius - 2), AllCorners, AbsoluteOpacity);
  end;

  DrawContent(LColors, ContentRect);
end;

procedure TDaisyControl.DrawText(const AText: string; const ARect: TRectF; AColor: TAlphaColor;
  AFontSize: Integer; ABold: Boolean; AHorzAlign, AVertAlign: TTextAlign; AWordWrap: Boolean);
var
  LLayout: TTextLayout;
  LBox: TRectF;
  LUpright: Boolean;
begin
  if (AText = '') or (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;
  LBox := ARect;
  LUpright := BeginUpright(LBox);
  // Wanted alignment is mirrored when upright; the layout flips Leading/Trailing itself when RightToLeft.
  if LUpright <> IsRTLReading then
    case AHorzAlign of
      TTextAlign.Leading: AHorzAlign := TTextAlign.Trailing;
      TTextAlign.Trailing: AHorzAlign := TTextAlign.Leading;
    end;
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.BeginUpdate;
    try
      LLayout.Text := AText;
      LLayout.Font.Size := AFontSize;
      if ABold then
        LLayout.Font.Style := [TFontStyle.fsBold]
      else
        LLayout.Font.Style := [];
      LLayout.Color := AColor;
      LLayout.Opacity := AbsoluteOpacity;
      LLayout.TopLeft := LBox.TopLeft;
      LLayout.MaxSize := PointF(LBox.Width, LBox.Height);
      LLayout.HorizontalAlign := AHorzAlign;
      LLayout.VerticalAlign := AVertAlign;
      LLayout.WordWrap := AWordWrap;
      LLayout.Trimming := TTextTrimming.Character;
      LLayout.RightToLeft := IsRTLReading;
    finally
      LLayout.EndUpdate;
    end;
    LLayout.RenderLayout(Canvas);
  finally
    LLayout.Free;
    EndUpright(LUpright);
  end;
end;

function TDaisyControl.MeasureTextHeight(const AText: string; AWidth: Single;
  AFontSize: Integer; ABold: Boolean): Single;
var
  LLayout: TTextLayout;
begin
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.BeginUpdate;
    try
      LLayout.Text := AText;
      LLayout.Font.Size := AFontSize;
      if ABold then
        LLayout.Font.Style := [TFontStyle.fsBold];
      LLayout.MaxSize := PointF(Max(1, AWidth), 10000);
      LLayout.WordWrap := True;
    finally
      LLayout.EndUpdate;
    end;
    Result := LLayout.TextHeight;
  finally
    LLayout.Free;
  end;
end;

procedure TDaisyControl.DrawPolylines(const APaths: TDaisyIconPaths; const ABounds: TRectF;
  AColor: TAlphaColor; AStrokeWidth: Single);
var
  LPath: TDaisyPolyline;
  LData: TPathData;
  LScale: Single;
  I: Integer;
  LPoint: TPointF;
  LBox: TRectF;
  LUpright: Boolean;
begin
  LBox := ABounds;
  LUpright := BeginUpright(LBox, True);
  try
    LScale := LBox.Width / 24; // icon geometry lives in a 24 x 24 box
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := AColor;
    Canvas.Stroke.Thickness := AStrokeWidth * LScale;
    Canvas.Stroke.Cap := TStrokeCap.Round;
    Canvas.Stroke.Join := TStrokeJoin.Round;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
    LData := TPathData.Create;
    try
      for LPath in APaths do
        for I := 0 to High(LPath) do
        begin
          LPoint := PointF(LBox.Left + LPath[I].X * LScale, LBox.Top + LPath[I].Y * LScale);
          if I = 0 then
            LData.MoveTo(LPoint)
          else
            LData.LineTo(LPoint);
        end;
      Canvas.DrawPath(LData, AbsoluteOpacity);
    finally
      LData.Free;
    end;
  finally
    EndUpright(LUpright);
  end;
end;

{ Badge helpers }

procedure TDaisyControl.DrawIconPath(const AData: string; const ABox: TRectF; AColor: TAlphaColor);
var
  LPaths: TDaisyIconPaths;
  LFilled: Boolean;
  LData: TPathData;
  LScale: Single;
  I, J: Integer;
  LPoint: TPointF;
  LBox: TRectF;
  LUpright: Boolean;
begin
  LPaths := TDaisySVG.ToPaths(AData, LFilled);
  if Length(LPaths) = 0 then
    Exit;
  if not LFilled then
  begin
    DrawPolylines(LPaths, ABox, AColor, 2);
    Exit;
  end;
  LBox := ABox;
  LUpright := BeginUpright(LBox, True);
  try
    LScale := LBox.Width / 24;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := AColor;
    LData := TPathData.Create;
    try
      for I := 0 to High(LPaths) do
      begin
        for J := 0 to High(LPaths[I]) do
        begin
          LPoint := PointF(LBox.Left + LPaths[I][J].X * LScale, LBox.Top + LPaths[I][J].Y * LScale);
          if J = 0 then
            LData.MoveTo(LPoint)
          else
            LData.LineTo(LPoint);
        end;
        LData.ClosePath;
      end;
      Canvas.FillPath(LData, AbsoluteOpacity);
    finally
      LData.Free;
    end;
  finally
    EndUpright(LUpright);
  end;
end;

procedure TDaisyControl.DrawSVGLayers(const ALayers: TDaisySVGLayers; const ABox: TRectF;
  AColor: TAlphaColor);
var
  LLayer: TDaisySVGLayer;
  LData: TPathData;
  LScale: Single;
  LPoint: TPointF;
  LBox: TRectF;
  LUpright: Boolean;

  procedure BuildPath(AClose: Boolean);
  var
    K, L: Integer;
  begin
    LData.Clear;
    for K := 0 to High(LLayer.Paths) do
    begin
      if Length(LLayer.Paths[K]) < 2 then
        Continue;
      for L := 0 to High(LLayer.Paths[K]) do
      begin
        LPoint := PointF(LBox.Left + LLayer.Paths[K][L].X * LScale,
          LBox.Top + LLayer.Paths[K][L].Y * LScale);
        if L = 0 then
          LData.MoveTo(LPoint)
        else
          LData.LineTo(LPoint);
      end;
      if AClose then
        LData.ClosePath;
    end;
  end;

begin
  if (Length(ALayers) = 0) or (ABox.Width <= 0) then
    Exit;
  LScale := ABox.Width / 24;
  LBox := ABox;
  LUpright := BeginUpright(LBox, True);
  LData := TPathData.Create;
  try
    for LLayer in ALayers do
    begin
      if LLayer.HasFill then
      begin
        BuildPath(True);
        Canvas.Fill.Kind := TBrushKind.Solid;
        Canvas.Fill.Color := TDaisySVG.LayerColor(LLayer, True, AColor);
        Canvas.FillPath(LData, AbsoluteOpacity);
      end;
      if LLayer.HasStroke then
      begin
        BuildPath(False);
        Canvas.Stroke.Kind := TBrushKind.Solid;
        Canvas.Stroke.Color := TDaisySVG.LayerColor(LLayer, False, AColor);
        Canvas.Stroke.Thickness := LLayer.StrokeWidth * LScale;
        Canvas.Stroke.Cap := TStrokeCap.Round;
        Canvas.Stroke.Join := TStrokeJoin.Round;
        Canvas.Stroke.Dash := TStrokeDash.Solid;
        Canvas.DrawPath(LData, AbsoluteOpacity);
      end;
    end;
  finally
    LData.Free;
    EndUpright(LUpright);
  end;
end;

function TDaisyControl.MeasureTextWidth(const AText: string; AFontSize: Integer;
  ABold: Boolean): Single;
var
  LLayout: TTextLayout;
begin
  if AText = '' then
    Exit(0);
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.BeginUpdate;
    try
      LLayout.Text := AText;
      LLayout.Font.Size := AFontSize;
      if ABold then
        LLayout.Font.Style := [TFontStyle.fsBold];
      LLayout.MaxSize := PointF(10000, 10000);
      LLayout.WordWrap := False;
    finally
      LLayout.EndUpdate;
    end;
    Result := Ceil(LLayout.TextWidth);
  finally
    LLayout.Free;
  end;
end;

function TDaisyControl.BadgeWidth(const AText: string; ASize: TDaisySize;
  AIcon: TDaisyIconKind; const AIconPath: string): Single;
var
  LFont: Integer;
  LIconW, LTextW: Single;
begin
  LFont := DaisyBadgeFontSize(ASize);
  LTextW := MeasureTextWidth(AText, LFont, False);
  LIconW := 0;
  if (AIconPath <> '') or not (AIcon in [diAuto, diNone]) then
    LIconW := LFont - 2;
  Result := DaisyBadgeHeight(ASize) + LIconW + LTextW;
  if (LIconW > 0) and (LTextW > 0) then
    Result := Result + LFont div 2;
end;

procedure TDaisyControl.DrawBadgeShape(const ARect: TRectF; const AColors: TDaisyColors;
  ARadius: Single);
var
  LRect: TRectF;
  LBorder: Single;
begin
  LBorder := Theme.BorderWidth;
  Canvas.Fill.Kind := TBrushKind.Solid;
  if TAlphaColorRec(AColors.Background).A > 0 then
  begin
    Canvas.Fill.Color := AColors.Background;
    Canvas.FillRect(ARect, ARadius, ARadius, AllCorners, AbsoluteOpacity);
  end;
  if (TAlphaColorRec(AColors.Border).A > 0) and (LBorder > 0) then
  begin
    LRect := ARect;
    LRect.Inflate(-LBorder / 2, -LBorder / 2);
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := AColors.Border;
    Canvas.Stroke.Thickness := LBorder;
    if AColors.Dashed then
      Canvas.Stroke.Dash := TStrokeDash.Dash
    else
      Canvas.Stroke.Dash := TStrokeDash.Solid;
    Canvas.DrawRect(LRect, Max(0, ARadius - LBorder / 2), Max(0, ARadius - LBorder / 2),
      AllCorners, AbsoluteOpacity);
    Canvas.Stroke.Dash := TStrokeDash.Solid;
  end;
end;

procedure TDaisyControl.DrawBadgeContent(const ARect: TRectF; const AText: string;
  AColor: TAlphaColor; ASize: TDaisySize; AIcon: TDaisyIconKind;
  AIconPos: TDaisyBadgeIconPosition; const AIconPath: string);
var
  LFont: Integer;
  LIconSize, LGap, LTextW, LTotal, LX, LIconX, LTextX, LIconTop: Single;
  LHasIcon: Boolean;
begin
  LFont := DaisyBadgeFontSize(ASize);
  LHasIcon := (AIconPath <> '') or not (AIcon in [diAuto, diNone]);
  LIconSize := 0;
  LGap := 0;
  if LHasIcon then
    LIconSize := LFont - 2;
  LTextW := MeasureTextWidth(AText, LFont, False);
  if LHasIcon and (LTextW > 0) then
    LGap := LFont div 2;

  LTotal := LIconSize + LGap + LTextW;
  LX := ARect.Left + (ARect.Width - LTotal) / 2;
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
    LIconTop := ARect.Top + (ARect.Height - LIconSize) / 2;
    if AIconPath <> '' then
      DrawIconPath(AIconPath, RectF(LIconX, LIconTop, LIconX + LIconSize, LIconTop + LIconSize),
        AColor)
    else
      DrawPolylines(DaisyIconPaths(AIcon),
        RectF(LIconX, LIconTop, LIconX + LIconSize, LIconTop + LIconSize), AColor, 2);
  end;
  DrawText(AText, RectF(LTextX, ARect.Top, LTextX + LTextW + 2, ARect.Bottom), AColor, LFont, False,
    TTextAlign.Leading, TTextAlign.Center, False);
end;

{ Events }

procedure TDaisyControl.DrawEmoji(const AText: string; const ARect: TRectF; AColor: TAlphaColor;
  AFontSize: Integer);
var
  LLayout: TTextLayout;
  LBox: TRectF;
  LUpright: Boolean;
begin
  if (AText = '') or (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;
  LBox := ARect;
  LUpright := BeginUpright(LBox);
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.BeginUpdate;
    try
      LLayout.Text := AText;
      {$IF DEFINED(MSWINDOWS)}
      LLayout.Font.Family := 'Segoe UI Emoji';
      {$ELSEIF DEFINED(MACOS) OR DEFINED(IOS)}
      LLayout.Font.Family := 'Apple Color Emoji';
      {$ELSEIF DEFINED(ANDROID)}
      LLayout.Font.Family := 'Noto Color Emoji';
      {$ENDIF}
      LLayout.Font.Size := AFontSize;
      LLayout.Color := AColor;
      LLayout.Opacity := AbsoluteOpacity;
      LLayout.TopLeft := LBox.TopLeft;
      LLayout.MaxSize := PointF(LBox.Width, LBox.Height);
      LLayout.HorizontalAlign := TTextAlign.Center;
      LLayout.VerticalAlign := TTextAlign.Center;
      LLayout.WordWrap := False;
    finally
      LLayout.EndUpdate;
    end;
    LLayout.RenderLayout(Canvas);
  finally
    LLayout.Free;
    EndUpright(LUpright);
  end;
end;

procedure TDaisyControl.DrawGlyph(const AIcon: TDaisyIconSource; const ABox: TRectF;
  AColor: TAlphaColor);
begin
  if (AIcon = nil) or AIcon.IsEmpty then
    Exit;
  if AIcon.IconPath <> '' then
    DrawIconPath(AIcon.IconPath, ABox, AColor)
  else
    DrawEmoji(AIcon.Emoji, ABox, AColor, Round(ABox.Height * 0.7));
end;

procedure TDaisyControl.DrawPrims(const APrims: TDaisyPrims; const ABounds: TRectF;
  AColor: TAlphaColor);
var
  LPrim: TDaisyPrim;
  LScale: Single;
  LRect: TRectF;
  LColor: TAlphaColor;
  LData: TPathData;
begin
  LScale := ABounds.Width / 24; // primitives live in a 24 x 24 box
  for LPrim in APrims do
  begin
    LRect := RectF(ABounds.Left + LPrim.Bounds.Left * LScale, ABounds.Top + LPrim.Bounds.Top * LScale,
      ABounds.Left + LPrim.Bounds.Right * LScale, ABounds.Top + LPrim.Bounds.Bottom * LScale);
    LColor := DaisyWithAlpha(AColor, LPrim.Alpha);
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := LColor;
    Canvas.Stroke.Thickness := LPrim.StrokeWidth * LScale;
    Canvas.Stroke.Cap := TStrokeCap.Round;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := LColor;
    case LPrim.Kind of
      pkArc:
        begin
          LData := TPathData.Create;
          try
            LData.AddArc(LRect.CenterPoint, PointF(LRect.Width / 2, LRect.Height / 2),
              LPrim.StartAngle, LPrim.SweepAngle);
            Canvas.DrawPath(LData, 1);
          finally
            LData.Free;
          end;
        end;
      pkEllipseStroke:
        begin
          LRect.Inflate(-Canvas.Stroke.Thickness / 2, -Canvas.Stroke.Thickness / 2);
          Canvas.DrawEllipse(LRect, 1);
        end;
      pkEllipseFill:
        Canvas.FillEllipse(LRect, 1);
      pkRoundRectFill:
        Canvas.FillRect(LRect, LRect.Width / 2, LRect.Width / 2, AllCorners, 1);
    end;
  end;
end;

procedure TDaisyControl.EnabledChanged;
begin
  inherited;
  Repaint;
end;

procedure TDaisyControl.DoMouseEnter;
begin
  inherited;
  FHot := True;
  if IsInteractive then
    Repaint;
end;

procedure TDaisyControl.DoMouseLeave;
begin
  inherited;
  FHot := False;
  if IsInteractive then
    Repaint;
end;

procedure TDaisyControl.DoEnter;
begin
  inherited;
  FShowFocus := True;
  Repaint;
end;

procedure TDaisyControl.DoExit;
begin
  inherited;
  FShowFocus := False;
  Repaint;
end;

procedure TDaisyControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if Button = TMouseButton.mbLeft then
  begin
    FShowFocus := False; // focus ring is for keyboard focus only
    SetPressed(True);
  end;
end;

procedure TDaisyControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if Button = TMouseButton.mbLeft then
    SetPressed(False);
end;

end.
