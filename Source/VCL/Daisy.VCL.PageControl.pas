unit Daisy.VCL.PageControl;

{
  TDaisyPageControl / TDaisyTabSheet - the DaisyUI "tabs" with tab content.

  The page control draws the tab strip and the bordered content box; every
  TDaisyTabSheet is a transparent container that fills that box. Drop a
  TDaisyTabSheet on the page control (or create one at run time and set its
  Parent) and it becomes a page; the active page is the only one visible.

  TabStyle selects the look (plain, box, border, lift) and TabPosition puts the
  strip at the top or the bottom. Variant tints the active tab and SizeKind gives
  xs..xl. Each sheet may show an Emoji or SVG icon in front of its Caption.

  Why not TCustomTabControl: it is a native Windows control and does not derive
  from TDaisyControl, so none of the shared theme, sizing and drawing code
  could be reused. Drawing the strip ourselves is little code and keeps both
  frameworks identical.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control;

type
  TDaisyPageControl = class;

  TDaisyTabChangingEvent = procedure(Sender: TObject; var AllowChange: Boolean) of object;

  TDaisyTabSheet = class(TDaisyControl)
  strict private
    FPageControl: TDaisyPageControl;
    FIcon: TDaisyIconSource;
    FTabVisible: Boolean;
    FTabColor: TColor;
    procedure SetTabColor(const Value: TColor);
    function GetCaption: string;
    procedure SetCaption(const Value: string);
    function GetEmoji: string;
    procedure SetEmoji(const Value: string);
    function GetSVG: TStrings;
    procedure SetSVG(const Value: TStrings);
    procedure IconChanged(Sender: TObject);
    procedure SetTabVisible(const Value: Boolean);
    function GetPageIndex: Integer;
    procedure SetPageIndex(const Value: Integer);
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SetParent(AParent: TWinControl); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property PageControl: TDaisyPageControl read FPageControl;
    property PageIndex: Integer read GetPageIndex write SetPageIndex;
    property Icon: TDaisyIconSource read FIcon;
  published
    // The tab text
    property Caption: string read GetCaption write SetCaption;
    // Shown in front of the caption
    property Emoji: string read GetEmoji write SetEmoji;
    // Paste SVG markup or load an .svg file; shown in front of the caption
    property SVG: TStrings read GetSVG write SetSVG;
    property TabVisible: Boolean read FTabVisible write SetTabVisible default True;
    // Custom colour of the active tab (fill for box/lift, underline for border); clNone uses the theme
    property TabColor: TColor read FTabColor write SetTabColor default Vcl.Graphics.clNone;
    // Only the active sheet is visible, so this is never streamed
    property Visible stored False;
  end;

  TDaisyPageControl = class(TDaisyControl)
  private
    FPages: TList<TDaisyTabSheet>;
    FActive: TDaisyTabSheet;
    FLoadedIndex: Integer;
    FTabStyle: TDaisyTabStyle;
    FTabPosition: TDaisyTabPosition;
    FHotTab: Integer;
    FTabRects: TArray<TRect>;
    FStripRect: TRect;
    FLayoutDirty: Boolean;
    FScrollX: Integer;
    FMaxScroll: Integer;
    FScrollToActive: Boolean;
    FDestroying: Boolean;
    FOnChange: TNotifyEvent;
    FOnChanging: TDaisyTabChangingEvent;
    procedure SetTabStyle(const Value: TDaisyTabStyle);
    procedure SetTabPosition(const Value: TDaisyTabPosition);
    procedure SetHotTab(const Value: Integer);
    function GetPageCount: Integer;
    function GetPage(AIndex: Integer): TDaisyTabSheet;
    function GetActivePageIndex: Integer;
    procedure SetActivePageIndex(const Value: Integer);
    procedure SetActivePage(const Value: TDaisyTabSheet);
    function TabHeight: Integer;
    function StripGap: Integer;
    function BoxRect: TRect;
    function SheetRect: TRect;
    function TabTint: TAlphaColor;
    function TabContentWidth(ASheet: TDaisyTabSheet): Integer;
    procedure EnsureLayout;
    function TabAt(X, Y: Integer): Integer;
    procedure UpdateSheetBounds;
    procedure ApplyActive;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  private
    procedure InsertPage(ASheet: TDaisyTabSheet);
    procedure RemovePage(ASheet: TDaisyTabSheet);
    procedure MovePage(ASheet: TDaisyTabSheet; ANewIndex: Integer);
    procedure PageChanged;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    function FindNextPage(ACurPage: TDaisyTabSheet; AGoForward, ACheckTabVisible: Boolean): TDaisyTabSheet;
    procedure SelectNextPage(AGoForward: Boolean);
    property PageCount: Integer read GetPageCount;
    property Pages[AIndex: Integer]: TDaisyTabSheet read GetPage;
    property ActivePage: TDaisyTabSheet read FActive write SetActivePage;
  published
    property ActivePageIndex: Integer read GetActivePageIndex write SetActivePageIndex default -1;
    property TabStyle: TDaisyTabStyle read FTabStyle write SetTabStyle default dtsBorder;
    property TabPosition: TDaisyTabPosition read FTabPosition write SetTabPosition default dtpTop;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TDaisyTabChangingEvent read FOnChanging write FOnChanging;
  end;

implementation

const
  CTabHeights: array[TDaisySize] of Integer = (24, 32, 40, 48, 56);
  CTabPadding: array[TDaisySize] of Integer = (8, 12, 16, 20, 24);

function VclToAlpha(AColor: TColor): TAlphaColor;
var
  LRGB: Integer;
begin
  LRGB := ColorToRGB(AColor);
  Result := TAlphaColor($FF000000) or TAlphaColor((LRGB and $FF) shl 16)
    or TAlphaColor(LRGB and $FF00) or TAlphaColor((LRGB shr 16) and $FF);
end;

// Black or white, whichever reads better on AColor
function ContrastOn(AColor: TAlphaColor): TAlphaColor;
var
  LRec: TAlphaColorRec;
begin
  LRec := TAlphaColorRec(AColor);
  if 0.299 * LRec.R + 0.587 * LRec.G + 0.114 * LRec.B > 150 then
    Result := TAlphaColors.Black
  else
    Result := TAlphaColors.White;
end;

{ TDaisyTabSheet }

constructor TDaisyTabSheet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FTabVisible := True;
  FTabColor := Vcl.Graphics.clNone;
  FIcon := TDaisyIconSource.Create(IconChanged);
  SetBounds(Left, Top, 200, 120);
end;

destructor TDaisyTabSheet.Destroy;
begin
  if FPageControl <> nil then
    FPageControl.RemovePage(Self);
  FIcon.Free;
  inherited Destroy;
end;

function TDaisyTabSheet.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyTabSheet.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyTabSheet.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

// The page control draws the content box; the sheet is transparent
function TDaisyTabSheet.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyTabSheet.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
begin
end;

procedure TDaisyTabSheet.SetParent(AParent: TWinControl);
begin
  if (AParent <> nil) and not (AParent is TDaisyPageControl) then
    raise EInvalidOperation.Create('A TDaisyTabSheet can only be placed on a TDaisyPageControl');
  if (FPageControl <> nil) and (FPageControl <> AParent) then
  begin
    FPageControl.RemovePage(Self);
    FPageControl := nil;
  end;
  inherited SetParent(AParent);
  if (AParent <> nil) and (FPageControl = nil) then
  begin
    FPageControl := TDaisyPageControl(AParent);
    FPageControl.InsertPage(Self);
  end;
end;

function TDaisyTabSheet.GetCaption: string;
begin
  Result := inherited Caption;
end;

procedure TDaisyTabSheet.SetCaption(const Value: string);
begin
  inherited Caption := Value;
end;

procedure TDaisyTabSheet.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if FPageControl <> nil then
    FPageControl.PageChanged;
end;

procedure TDaisyTabSheet.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if FPageControl <> nil then
    FPageControl.PageChanged;
end;

function TDaisyTabSheet.GetEmoji: string;
begin
  Result := FIcon.Emoji;
end;

procedure TDaisyTabSheet.SetEmoji(const Value: string);
begin
  FIcon.Emoji := Value;
end;

function TDaisyTabSheet.GetSVG: TStrings;
begin
  Result := FIcon.SVG;
end;

procedure TDaisyTabSheet.SetSVG(const Value: TStrings);
begin
  FIcon.SVG := Value;
end;

procedure TDaisyTabSheet.IconChanged(Sender: TObject);
begin
  if FPageControl <> nil then
    FPageControl.PageChanged;
end;

procedure TDaisyTabSheet.SetTabColor(const Value: TColor);
begin
  if FTabColor <> Value then
  begin
    FTabColor := Value;
    if FPageControl <> nil then
      FPageControl.PageChanged;
  end;
end;

procedure TDaisyTabSheet.SetTabVisible(const Value: Boolean);
begin
  if FTabVisible <> Value then
  begin
    FTabVisible := Value;
    if FPageControl <> nil then
    begin
      if (not Value) and (FPageControl.ActivePage = Self) then
        FPageControl.ActivePage := FPageControl.FindNextPage(Self, True, True);
      FPageControl.PageChanged;
    end;
  end;
end;

function TDaisyTabSheet.GetPageIndex: Integer;
begin
  if FPageControl <> nil then
    Result := FPageControl.FPages.IndexOf(Self)
  else
    Result := -1;
end;

procedure TDaisyTabSheet.SetPageIndex(const Value: Integer);
begin
  if FPageControl <> nil then
    FPageControl.MovePage(Self, Value);
end;

{ TDaisyPageControl }

constructor TDaisyPageControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FPages := TList<TDaisyTabSheet>.Create;
  FLoadedIndex := -1;
  FHotTab := -1;
  FTabStyle := dtsBorder;
  FLayoutDirty := True;
  TabStop := True;
  SetBounds(Left, Top, 360, 240);
end;

destructor TDaisyPageControl.Destroy;
begin
  FDestroying := True;
  FPages.Free;
  inherited Destroy;
end;

function TDaisyPageControl.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyPageControl.DrawsFocusRing: Boolean;
begin
  Result := False; // the active tab shows the focus
end;

function TDaisyPageControl.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyPageControl.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyPageControl.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyPageControl.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyPageControl.Invalidate;
begin
  FLayoutDirty := True;
  inherited Invalidate;
end;

procedure TDaisyPageControl.PageChanged;
begin
  if not FDestroying then
    Invalidate;
end;

function TDaisyPageControl.GetPageCount: Integer;
begin
  Result := FPages.Count;
end;

function TDaisyPageControl.GetPage(AIndex: Integer): TDaisyTabSheet;
begin
  Result := FPages[AIndex];
end;

function TDaisyPageControl.GetActivePageIndex: Integer;
begin
  if csLoading in ComponentState then
    Exit(FLoadedIndex);
  if FActive = nil then
    Result := -1
  else
    Result := FPages.IndexOf(FActive);
end;

procedure TDaisyPageControl.SetActivePageIndex(const Value: Integer);
begin
  if csLoading in ComponentState then
    FLoadedIndex := Value
  else if (Value >= 0) and (Value < FPages.Count) then
    SetActivePage(FPages[Value])
  else
    SetActivePage(nil);
end;

procedure TDaisyPageControl.SetActivePage(const Value: TDaisyTabSheet);
var
  LAllow: Boolean;
begin
  if (Value = FActive) or ((Value <> nil) and (FPages.IndexOf(Value) < 0)) then
    Exit;
  if (Value <> nil) and not Value.TabVisible then
    Exit;
  LAllow := True;
  if (not (csLoading in ComponentState)) and Assigned(FOnChanging) then
    FOnChanging(Self, LAllow);
  if not LAllow then
    Exit;
  FActive := Value;
  ApplyActive;
  if (not (csLoading in ComponentState)) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyPageControl.ApplyActive;
var
  LSheet: TDaisyTabSheet;
begin
  for LSheet in FPages do
    LSheet.Visible := LSheet = FActive;
  if FActive <> nil then
    FActive.BringToFront;
  FScrollToActive := True;
  Invalidate;
end;

procedure TDaisyPageControl.SetTabStyle(const Value: TDaisyTabStyle);
begin
  if FTabStyle <> Value then
  begin
    FTabStyle := Value;
    UpdateSheetBounds;
    Invalidate;
  end;
end;

procedure TDaisyPageControl.SetTabPosition(const Value: TDaisyTabPosition);
begin
  if FTabPosition <> Value then
  begin
    FTabPosition := Value;
    UpdateSheetBounds;
    Invalidate;
  end;
end;

procedure TDaisyPageControl.SetHotTab(const Value: Integer);
begin
  if FHotTab <> Value then
  begin
    FHotTab := Value;
    Invalidate;
  end;
end;

procedure TDaisyPageControl.InsertPage(ASheet: TDaisyTabSheet);
begin
  if FPages.IndexOf(ASheet) >= 0 then
    Exit;
  FPages.Add(ASheet);
  if csLoading in ComponentState then
    Exit;
  UpdateSheetBounds;
  if (FActive = nil) or (csDesigning in ComponentState) then
    SetActivePage(ASheet)
  else
    ASheet.Visible := False;
  Invalidate;
end;

procedure TDaisyPageControl.RemovePage(ASheet: TDaisyTabSheet);
var
  LNext: TDaisyTabSheet;
begin
  if FDestroying then
    Exit;
  if FActive = ASheet then
  begin
    LNext := FindNextPage(ASheet, True, True);
    if LNext = ASheet then
      LNext := nil;
    FActive := LNext;
    ApplyActive;
  end;
  FPages.Remove(ASheet);
  Invalidate;
end;

procedure TDaisyPageControl.MovePage(ASheet: TDaisyTabSheet; ANewIndex: Integer);
var
  LOld: Integer;
begin
  LOld := FPages.IndexOf(ASheet);
  ANewIndex := EnsureRange(ANewIndex, 0, FPages.Count - 1);
  if (LOld >= 0) and (LOld <> ANewIndex) then
  begin
    FPages.Move(LOld, ANewIndex);
    Invalidate;
  end;
end;

function TDaisyPageControl.FindNextPage(ACurPage: TDaisyTabSheet; AGoForward,
  ACheckTabVisible: Boolean): TDaisyTabSheet;
var
  I, LStart, LStep: Integer;
begin
  Result := nil;
  if FPages.Count = 0 then
    Exit;
  LStart := FPages.IndexOf(ACurPage);
  if AGoForward then
    LStep := 1
  else
    LStep := -1;
  if LStart < 0 then
    LStart := IfThen(AGoForward, FPages.Count - 1, 0);
  I := LStart;
  repeat
    I := (I + LStep + FPages.Count) mod FPages.Count;
    if (not ACheckTabVisible) or FPages[I].TabVisible then
      Exit(FPages[I]);
  until I = LStart;
end;

procedure TDaisyPageControl.SelectNextPage(AGoForward: Boolean);
var
  LNext: TDaisyTabSheet;
  LTries: Integer;
begin
  LNext := FActive;
  for LTries := 1 to FPages.Count do
  begin
    LNext := FindNextPage(LNext, AGoForward, True);
    if (LNext = nil) or LNext.Enabled then
      Break;
  end;
  if (LNext <> nil) and LNext.Enabled then
    SetActivePage(LNext);
end;

{ Layout }

function TDaisyPageControl.TabHeight: Integer;
begin
  Result := ScaleValue(CTabHeights[SizeKind]);
end;

function TDaisyPageControl.StripGap: Integer;
begin
  if FTabStyle = dtsBox then
    Result := ScaleValue(6)
  else
    Result := 0;
end;

function TDaisyPageControl.BoxRect: TRect;
begin
  if FTabPosition = dtpTop then
    Result := Rect(0, TabHeight + StripGap, ClientWidth, ClientHeight)
  else
    Result := Rect(0, 0, ClientWidth, ClientHeight - TabHeight - StripGap);
end;

function TDaisyPageControl.SheetRect: TRect;
var
  LBorder: Integer;
begin
  Result := BoxRect;
  LBorder := Max(1, ScaleValue(Theme.BorderWidth));
  InflateRect(Result, -LBorder, -LBorder);
end;

procedure TDaisyPageControl.UpdateSheetBounds;
var
  LRect: TRect;
  LSheet: TDaisyTabSheet;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  LRect := SheetRect;
  for LSheet in FPages do
    LSheet.SetBounds(LRect.Left, LRect.Top, Max(0, LRect.Width), Max(0, LRect.Height));
end;

function TDaisyPageControl.TabTint: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
end;

function TDaisyPageControl.TabContentWidth(ASheet: TDaisyTabSheet): Integer;
var
  LFont: Integer;
begin
  LFont := DaisyFontSize(SizeKind);
  Result := MeasureTextWidth(ASheet.Caption, LFont, False);
  if not ASheet.Icon.IsEmpty then
  begin
    Inc(Result, Round(ScaleValue(LFont) * 1.25));
    if ASheet.Caption <> '' then
      Inc(Result, ScaleValue(6));
  end;
end;

procedure TDaisyPageControl.EnsureLayout;
var
  I, LX, LTop, LBottom, LInset, LStripTop, LStripBottom, LTotal: Integer;
  LSheet: TDaisyTabSheet;
begin
  if not FLayoutDirty then
    Exit;
  FLayoutDirty := False;
  SetLength(FTabRects, FPages.Count);

  if FTabPosition = dtpTop then
  begin
    LStripTop := 0;
    LStripBottom := TabHeight;
  end
  else
  begin
    LStripTop := ClientHeight - TabHeight;
    LStripBottom := ClientHeight;
  end;

  LInset := 0;
  LX := 0;
  case FTabStyle of
    dtsBox:
      begin
        LInset := ScaleValue(4);
        LX := LInset;
      end;
    dtsLift:
      LX := Min(ScaleValue(Theme.RadiusBox), ScaleValue(16));
  end;
  LTop := LStripTop + LInset;
  LBottom := LStripBottom - LInset;

  for I := 0 to FPages.Count - 1 do
  begin
    LSheet := FPages[I];
    if not LSheet.TabVisible then
    begin
      FTabRects[I] := Rect(0, 0, 0, 0);
      Continue;
    end;
    FTabRects[I] := Rect(LX, LTop, LX + TabContentWidth(LSheet) + 2 * ScaleValue(CTabPadding[SizeKind]),
      LBottom);
    LX := FTabRects[I].Right;
  end;
  LTotal := LX + LInset;
  FMaxScroll := Max(0, LTotal - ClientWidth);
  if FScrollToActive then
  begin
    FScrollToActive := False;
    I := FPages.IndexOf(FActive);
    if (I >= 0) and FPages[I].TabVisible then
    begin
      if FTabRects[I].Right - FScrollX > ClientWidth then
        FScrollX := FTabRects[I].Right + LInset - ClientWidth;
      if FTabRects[I].Left - FScrollX < 0 then
        FScrollX := FTabRects[I].Left - LInset;
    end;
  end;
  FScrollX := EnsureRange(FScrollX, 0, FMaxScroll);
  if FScrollX <> 0 then
    for I := 0 to High(FTabRects) do
      OffsetRect(FTabRects[I], -FScrollX, 0);
  FStripRect := Rect(0, LStripTop, Min(LTotal - FScrollX, ClientWidth), LStripBottom);
end;

function TDaisyPageControl.TabAt(X, Y: Integer): Integer;
var
  I: Integer;
  LHit: TRect;
begin
  Result := -1;
  EnsureLayout;
  for I := 0 to High(FTabRects) do
    if FPages[I].TabVisible then
    begin
      LHit := Rect(FTabRects[I].Left, FStripRect.Top, FTabRects[I].Right, FStripRect.Bottom);
      if PtInRect(LHit, Point(X, Y)) then
        Exit(I);
    end;
end;

procedure TDaisyPageControl.SizeChanged;
begin
  UpdateSheetBounds;
  Invalidate;
end;

procedure TDaisyPageControl.Resize;
begin
  inherited Resize;
  UpdateSheetBounds;
end;

procedure TDaisyPageControl.Loaded;
begin
  inherited Loaded;
  UpdateSheetBounds;
  if (FLoadedIndex >= 0) and (FLoadedIndex < FPages.Count) and FPages[FLoadedIndex].TabVisible then
    FActive := FPages[FLoadedIndex]
  else
    FActive := FindNextPage(nil, True, True);
  FLoadedIndex := -1;
  ApplyActive;
end;

{ Input }

procedure TDaisyPageControl.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TDaisyPageControl.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  Message.Result := Ord(TabAt(Message.XPos, Message.YPos) >= 0);
end;

procedure TDaisyPageControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHotTab(-1);
end;

procedure TDaisyPageControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LTab: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  LTab := TabAt(X, Y);
  if (LTab >= 0) and not FPages[LTab].Enabled then
    LTab := -1;
  SetHotTab(LTab);
end;

function TDaisyPageControl.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  LPos: TPoint;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result or (FMaxScroll <= 0) then
    Exit;
  LPos := ScreenToClient(MousePos);
  if (LPos.Y >= FStripRect.Top) and (LPos.Y < FStripRect.Bottom) then
  begin
    FScrollX := EnsureRange(FScrollX - Sign(WheelDelta) * ScaleValue(48), 0, FMaxScroll);
    FLayoutDirty := True;
    Invalidate;
    Result := True;
  end;
end;

procedure TDaisyPageControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LTab: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  LTab := TabAt(X, Y);
  if LTab < 0 then
    Exit;
  if (not (csDesigning in ComponentState)) and CanFocus and not Focused then
    SetFocus;
  if FPages[LTab].Enabled or (csDesigning in ComponentState) then
    SetActivePage(FPages[LTab]);
end;

procedure TDaisyPageControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_LEFT, VK_UP:
      begin
        SelectNextPage(False);
        Key := 0;
      end;
    VK_RIGHT, VK_DOWN:
      begin
        SelectNextPage(True);
        Key := 0;
      end;
  else
    inherited KeyDown(Key, Shift);
  end;
end;

{ Drawing }

procedure TDaisyPageControl.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LPath: TGPGraphicsPath;
  LPen: TGPPen;
  LBrush: TGPSolidBrush;
  LBox: TRectF;
  LTab: TRect;
  LBorder, LRadius, LFieldRadius, LHalf: Single;
  LTint, LTextColor, LOnTint: TAlphaColor;
  LFade: Single;
  LPalette: TDaisyPalette;
  LActiveFill: TAlphaColor;
  LTabTint: TAlphaColor;
  LCustom: Boolean;
  I, LFont, LIconSize, LX, LExt: Integer;
  LSheet: TDaisyTabSheet;
  LActiveTab: Boolean;
  LIconBox, LText: TRect;
  LTop: Boolean;
  L, T, R, B: Single;
begin
  EnsureLayout;
  LTop := FTabPosition = dtpTop;
  LBorder := Max(1, ScaleValue(Theme.BorderWidth));
  LRadius := ScaleValue(Theme.RadiusBox);
  LFieldRadius := ScaleValue(Theme.RadiusField);
  LBox := TRectF.Create(BoxRect);
  LTint := TabTint;
  LOnTint := Theme.Base100;
  if Variant <> dvDefault then
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    LOnTint := LPalette.Content;
  end;
  LFade := 1;
  if not Enabled then
    LFade := 0.4;
  LFont := DaisyFontSize(SizeKind);

  LGraphics := NewGraphics;
  try
    FillRoundRect(LGraphics, LBox, LRadius, DaisyWithAlpha(Theme.Base100, LFade));
    StrokeRoundRect(LGraphics, LBox, LRadius, DaisyWithAlpha(Theme.BorderColor, LFade), LBorder, False);

    if FTabStyle = dtsBox then
      FillRoundRect(LGraphics, TRectF.Create(FStripRect), LFieldRadius + ScaleValue(4),
        DaisyWithAlpha(Theme.Base200, LFade));

    for I := 0 to FPages.Count - 1 do
    begin
      LSheet := FPages[I];
      if not LSheet.TabVisible then
        Continue;
      LTab := FTabRects[I];
      LActiveTab := LSheet = FActive;
      if not LActiveTab then
        Continue;
      LCustom := LSheet.TabColor <> Vcl.Graphics.clNone;
      LTabTint := LTint;
      if LCustom then
        LTabTint := VclToAlpha(LSheet.TabColor);

      case FTabStyle of
        dtsBox:
          begin
            if LCustom then
              LActiveFill := LTabTint
            else if Variant = dvDefault then
              LActiveFill := Theme.Base100
            else
              LActiveFill := LTint;
            FillRoundRect(LGraphics, TRectF.Create(LTab), LFieldRadius, DaisyWithAlpha(LActiveFill, LFade));
            if (Variant = dvDefault) and not LCustom then
              StrokeRoundRect(LGraphics, TRectF.Create(LTab), LFieldRadius,
                DaisyWithAlpha(Theme.BorderColor, LFade), LBorder, False);
          end;
        dtsBorder:
          begin
            LExt := Max(2, ScaleValue(3));
            if LTop then
              FillRoundRect(LGraphics, RectF(LTab.Left, LTab.Bottom - LExt + LBorder, LTab.Right,
                LTab.Bottom + LBorder), LExt / 2, DaisyWithAlpha(LTabTint, LFade))
            else
              FillRoundRect(LGraphics, RectF(LTab.Left, LTab.Top - LBorder, LTab.Right,
                LTab.Top + LExt - LBorder), LExt / 2, DaisyWithAlpha(LTabTint, LFade));
          end;
        dtsLift:
          begin
            LHalf := LBorder / 2;
            L := LTab.Left + LHalf;
            R := LTab.Right - LHalf;
            T := LTab.Top + LHalf;
            B := LTab.Bottom - LHalf;
            LExt := Round(LBorder);
            LPath := TGPGraphicsPath.Create;
            try
              LRadius := Min(LFieldRadius + ScaleValue(2), (R - L) / 2);
              if LTop then
              begin
                LPath.AddLine(L, B + LExt, L, T + LRadius);
                LPath.AddArc(L, T, 2 * LRadius, 2 * LRadius, 180, 90);
                LPath.AddLine(L + LRadius, T, R - LRadius, T);
                LPath.AddArc(R - 2 * LRadius, T, 2 * LRadius, 2 * LRadius, 270, 90);
                LPath.AddLine(R, T + LRadius, R, B + LExt);
              end
              else
              begin
                LPath.AddLine(L, T - LExt, L, B - LRadius);
                LPath.AddArc(L, B - 2 * LRadius, 2 * LRadius, 2 * LRadius, 180, -90);
                LPath.AddLine(L + LRadius, B, R - LRadius, B);
                LPath.AddArc(R - 2 * LRadius, B - 2 * LRadius, 2 * LRadius, 2 * LRadius, 90, -90);
                LPath.AddLine(R, B - LRadius, R, T - LExt);
              end;
              if LCustom then
                LActiveFill := LTabTint
              else
                LActiveFill := Theme.Base100;
              LBrush := TGPSolidBrush.Create(DaisyWithAlpha(LActiveFill, LFade));
              LPen := TGPPen.Create(DaisyWithAlpha(Theme.BorderColor, LFade), LBorder);
              try
                LGraphics.FillPath(LBrush, LPath);
                LGraphics.DrawPath(LPen, LPath);
              finally
                LPen.Free;
                LBrush.Free;
              end;
            finally
              LPath.Free;
            end;
          end;
      end;
    end;
  finally
    LGraphics.Free;
  end;

  LIconSize := Round(ScaleValue(LFont) * 1.25);
  for I := 0 to FPages.Count - 1 do
  begin
    LSheet := FPages[I];
    if not LSheet.TabVisible then
      Continue;
    LTab := FTabRects[I];
    LActiveTab := LSheet = FActive;
    if LActiveTab then
    begin
      if LSheet.TabColor <> Vcl.Graphics.clNone then
      begin
        LTextColor := Theme.BaseContent;
        if FTabStyle = dtsBorder then
          LTextColor := VclToAlpha(LSheet.TabColor)
        else if FTabStyle = dtsBox then
          LTextColor := ContrastOn(VclToAlpha(LSheet.TabColor));
      end
      else if (FTabStyle = dtsBox) and (Variant <> dvDefault) then
        LTextColor := LOnTint
      else
        LTextColor := LTint;
    end
    else if (I = FHotTab) then
      LTextColor := DaisyWithAlpha(Theme.BaseContent, 0.85)
    else
      LTextColor := DaisyWithAlpha(Theme.BaseContent, 0.6);
    if (not LSheet.Enabled) or (not Enabled) then
      LTextColor := DaisyWithAlpha(Theme.BaseContent, 0.25);

    LX := LTab.Left + ScaleValue(CTabPadding[SizeKind]);
    if not LSheet.Icon.IsEmpty then
    begin
      LIconBox := Rect(LX, (LTab.Top + LTab.Bottom - LIconSize) div 2, LX + LIconSize,
        (LTab.Top + LTab.Bottom - LIconSize) div 2 + LIconSize);
      DrawGlyph(LSheet.Icon, LIconBox, LTextColor);
      Inc(LX, LIconSize);
      if LSheet.Caption <> '' then
        Inc(LX, ScaleValue(6));
    end;
    if LSheet.Caption <> '' then
    begin
      LText := Rect(LX, LTab.Top, LTab.Right - ScaleValue(CTabPadding[SizeKind]) + ScaleValue(4), LTab.Bottom);
      DrawRichText(LSheet.Caption, LText, LTextColor, LFont, False,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;
  end;
end;

end.
