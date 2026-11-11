unit Daisy.FMX.PageControl;

{
  TDaisyFmxPageControl / TDaisyFmxTabSheet - the DaisyUI "tabs" with tab content.

  The page control draws the tab strip and the bordered content box; every
  TDaisyFmxTabSheet is a transparent container that fills that box. Drop a
  TDaisyFmxTabSheet on the page control (or create one at run time and set its
  Parent) and it becomes a page; the active page is the only one visible.

  TabStyle selects the look (plain, box, border, lift) and TabPosition puts the
  strip at the top or the bottom. Variant tints the active tab and SizeKind gives
  xs..xl. Each sheet may show an Emoji or SVG icon in front of its Text.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, Daisy.Theme,
  Daisy.Widgets, Daisy.FMX.Control;

type
  TDaisyFmxPageControl = class;

  TDaisyFmxTabChangingEvent = procedure(Sender: TObject; var AllowChange: Boolean) of object;

  TDaisyFmxTabSheet = class(TDaisyControl)
  strict private
    FPageControl: TDaisyFmxPageControl;
    FIcon: TDaisyIconSource;
    FText: string;
    FTabVisible: Boolean;
    FTabColor: TAlphaColor;
    procedure SetTabColor(const Value: TAlphaColor);
    procedure SetText(const Value: string);
    function GetEmoji: string;
    procedure SetEmoji(const Value: string);
    function GetSVG: TStrings;
    procedure SetSVG(const Value: TStrings);
    procedure IconChanged(Sender: TObject);
    procedure SetTabVisible(const Value: Boolean);
    function GetPageIndex: Integer;
    procedure SetPageIndex(const Value: Integer);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure ParentChanged; override;
    procedure EnabledChanged; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property PageControl: TDaisyFmxPageControl read FPageControl;
    property PageIndex: Integer read GetPageIndex write SetPageIndex;
    property Icon: TDaisyIconSource read FIcon;
  published
    // The tab text
    property Text: string read FText write SetText;
    // Shown in front of the text
    property Emoji: string read GetEmoji write SetEmoji;
    // Paste SVG markup or load an .svg file; shown in front of the text
    property SVG: TStrings read GetSVG write SetSVG;
    property TabVisible: Boolean read FTabVisible write SetTabVisible default True;
    // Custom colour of the active tab (fill for box/lift, underline for border); Null uses the theme
    property TabColor: TAlphaColor read FTabColor write SetTabColor default TAlphaColors.Null;
    // Only the active sheet is visible, so this is never streamed
    property Visible stored False;
  end;

  TDaisyFmxPageControl = class(TDaisyControl)
  private
    FPages: TList<TDaisyFmxTabSheet>;
    FActive: TDaisyFmxTabSheet;
    FLoadedIndex: Integer;
    FTabStyle: TDaisyTabStyle;
    FTabPosition: TDaisyTabPosition;
    FHotTab: Integer;
    FTabRects: TArray<TRectF>;
    FStripRect: TRectF;
    FLayoutDirty: Boolean;
    FScrollX: Single;
    FMaxScroll: Single;
    FScrollToActive: Boolean;
    FDestroying: Boolean;
    FOnChange: TNotifyEvent;
    FOnChanging: TDaisyFmxTabChangingEvent;
    procedure SetTabStyle(const Value: TDaisyTabStyle);
    procedure SetTabPosition(const Value: TDaisyTabPosition);
    procedure SetHotTab(const Value: Integer);
    function GetPageCount: Integer;
    function GetPage(AIndex: Integer): TDaisyFmxTabSheet;
    function GetActivePageIndex: Integer;
    procedure SetActivePageIndex(const Value: Integer);
    procedure SetActivePage(const Value: TDaisyFmxTabSheet);
    function TabHeight: Single;
    function StripGap: Single;
    function BoxRectF: TRectF;
    function SheetRect: TRectF;
    function TabTint: TAlphaColor;
    function TabContentWidth(ASheet: TDaisyFmxTabSheet): Single;
    procedure EnsureLayout;
    function TabAt(X, Y: Single): Integer;
    procedure UpdateSheetBounds;
    procedure ApplyActive;
  private
    procedure InsertPage(ASheet: TDaisyFmxTabSheet);
    procedure RemovePage(ASheet: TDaisyFmxTabSheet);
    procedure MovePage(ASheet: TDaisyFmxTabSheet; ANewIndex: Integer);
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
    procedure DoMouseLeave; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FindNextPage(ACurPage: TDaisyFmxTabSheet; AGoForward,
      ACheckTabVisible: Boolean): TDaisyFmxTabSheet;
    procedure SelectNextPage(AGoForward: Boolean);
    property PageCount: Integer read GetPageCount;
    property Pages[AIndex: Integer]: TDaisyFmxTabSheet read GetPage;
    property ActivePage: TDaisyFmxTabSheet read FActive write SetActivePage;
  published
    property ActivePageIndex: Integer read GetActivePageIndex write SetActivePageIndex default -1;
    property TabStyle: TDaisyTabStyle read FTabStyle write SetTabStyle default dtsBorder;
    property TabPosition: TDaisyTabPosition read FTabPosition write SetTabPosition default dtpTop;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TDaisyFmxTabChangingEvent read FOnChanging write FOnChanging;
  end;

implementation

const
  CTabHeights: array[TDaisySize] of Integer = (24, 32, 40, 48, 56);
  CTabPadding: array[TDaisySize] of Integer = (8, 12, 16, 20, 24);

function IfThenColor(ACondition: Boolean; AThen, AElse: TAlphaColor): TAlphaColor;
begin
  if ACondition then
    Result := AThen
  else
    Result := AElse;
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

{ TDaisyFmxTabSheet }

constructor TDaisyFmxTabSheet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTabVisible := True;
  FTabColor := TAlphaColors.Null;
  FIcon := TDaisyIconSource.Create(IconChanged);
  SetBounds(Position.X, Position.Y, 200, 120);
end;

destructor TDaisyFmxTabSheet.Destroy;
begin
  if FPageControl <> nil then
    FPageControl.RemovePage(Self);
  FIcon.Free;
  inherited Destroy;
end;

function TDaisyFmxTabSheet.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxTabSheet.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxTabSheet.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

// The page control draws the content box; the sheet is transparent
function TDaisyFmxTabSheet.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxTabSheet.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
begin
end;

procedure TDaisyFmxTabSheet.ParentChanged;
var
  LNew: TDaisyFmxPageControl;
begin
  inherited ParentChanged;
  if Parent is TDaisyFmxPageControl then
    LNew := TDaisyFmxPageControl(Parent)
  else
    LNew := nil;
  if (FPageControl <> nil) and (FPageControl <> LNew) then
  begin
    FPageControl.RemovePage(Self);
    FPageControl := nil;
  end;
  if (LNew <> nil) and (FPageControl = nil) then
  begin
    FPageControl := LNew;
    FPageControl.InsertPage(Self);
  end;
end;

procedure TDaisyFmxTabSheet.EnabledChanged;
begin
  inherited EnabledChanged;
  if FPageControl <> nil then
    FPageControl.PageChanged;
end;

procedure TDaisyFmxTabSheet.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    if FPageControl <> nil then
      FPageControl.PageChanged;
  end;
end;

function TDaisyFmxTabSheet.GetEmoji: string;
begin
  Result := FIcon.Emoji;
end;

procedure TDaisyFmxTabSheet.SetEmoji(const Value: string);
begin
  FIcon.Emoji := Value;
end;

function TDaisyFmxTabSheet.GetSVG: TStrings;
begin
  Result := FIcon.SVG;
end;

procedure TDaisyFmxTabSheet.SetSVG(const Value: TStrings);
begin
  FIcon.SVG := Value;
end;

procedure TDaisyFmxTabSheet.IconChanged(Sender: TObject);
begin
  if FPageControl <> nil then
    FPageControl.PageChanged;
end;

procedure TDaisyFmxTabSheet.SetTabColor(const Value: TAlphaColor);
begin
  if FTabColor <> Value then
  begin
    FTabColor := Value;
    if FPageControl <> nil then
      FPageControl.PageChanged;
  end;
end;

procedure TDaisyFmxTabSheet.SetTabVisible(const Value: Boolean);
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

function TDaisyFmxTabSheet.GetPageIndex: Integer;
begin
  if FPageControl <> nil then
    Result := FPageControl.FPages.IndexOf(Self)
  else
    Result := -1;
end;

procedure TDaisyFmxTabSheet.SetPageIndex(const Value: Integer);
begin
  if FPageControl <> nil then
    FPageControl.MovePage(Self, Value);
end;

{ TDaisyFmxPageControl }

constructor TDaisyFmxPageControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPages := TList<TDaisyFmxTabSheet>.Create;
  FLoadedIndex := -1;
  FHotTab := -1;
  FTabStyle := dtsBorder;
  FLayoutDirty := True;
  CanFocus := True;
  TabStop := True;
  FDesignInteractive := True; // lets the form designer pass tab clicks to MouseDown so pages can be switched and selected
  SetBounds(Position.X, Position.Y, 360, 240);
end;

destructor TDaisyFmxPageControl.Destroy;
begin
  FDestroying := True;
  FPages.Free;
  inherited Destroy;
end;

function TDaisyFmxPageControl.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxPageControl.DrawsFocusRing: Boolean;
begin
  Result := False; // the active tab shows the focus
end;

function TDaisyFmxPageControl.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxPageControl.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxPageControl.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxPageControl.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxPageControl.PageChanged;
begin
  if not FDestroying then
  begin
    FLayoutDirty := True;
    Repaint;
  end;
end;

function TDaisyFmxPageControl.GetPageCount: Integer;
begin
  Result := FPages.Count;
end;

function TDaisyFmxPageControl.GetPage(AIndex: Integer): TDaisyFmxTabSheet;
begin
  Result := FPages[AIndex];
end;

function TDaisyFmxPageControl.GetActivePageIndex: Integer;
begin
  if csLoading in ComponentState then
    Exit(FLoadedIndex);
  if FActive = nil then
    Result := -1
  else
    Result := FPages.IndexOf(FActive);
end;

procedure TDaisyFmxPageControl.SetActivePageIndex(const Value: Integer);
begin
  if csLoading in ComponentState then
    FLoadedIndex := Value
  else if (Value >= 0) and (Value < FPages.Count) then
    SetActivePage(FPages[Value])
  else
    SetActivePage(nil);
end;

procedure TDaisyFmxPageControl.SetActivePage(const Value: TDaisyFmxTabSheet);
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

procedure TDaisyFmxPageControl.ApplyActive;
var
  LSheet: TDaisyFmxTabSheet;
begin
  for LSheet in FPages do
    LSheet.Visible := LSheet = FActive;
  if FActive <> nil then
    FActive.BringToFront;
  FScrollToActive := True;
  FLayoutDirty := True;
  Repaint;
end;

procedure TDaisyFmxPageControl.SetTabStyle(const Value: TDaisyTabStyle);
begin
  if FTabStyle <> Value then
  begin
    FTabStyle := Value;
    UpdateSheetBounds;
    PageChanged;
  end;
end;

procedure TDaisyFmxPageControl.SetTabPosition(const Value: TDaisyTabPosition);
begin
  if FTabPosition <> Value then
  begin
    FTabPosition := Value;
    UpdateSheetBounds;
    PageChanged;
  end;
end;

procedure TDaisyFmxPageControl.SetHotTab(const Value: Integer);
begin
  if FHotTab <> Value then
  begin
    FHotTab := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxPageControl.InsertPage(ASheet: TDaisyFmxTabSheet);
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
  PageChanged;
end;

procedure TDaisyFmxPageControl.RemovePage(ASheet: TDaisyFmxTabSheet);
var
  LNext: TDaisyFmxTabSheet;
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
  PageChanged;
end;

procedure TDaisyFmxPageControl.MovePage(ASheet: TDaisyFmxTabSheet; ANewIndex: Integer);
var
  LOld: Integer;
begin
  LOld := FPages.IndexOf(ASheet);
  ANewIndex := EnsureRange(ANewIndex, 0, FPages.Count - 1);
  if (LOld >= 0) and (LOld <> ANewIndex) then
  begin
    FPages.Move(LOld, ANewIndex);
    PageChanged;
  end;
end;

function TDaisyFmxPageControl.FindNextPage(ACurPage: TDaisyFmxTabSheet; AGoForward,
  ACheckTabVisible: Boolean): TDaisyFmxTabSheet;
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

procedure TDaisyFmxPageControl.SelectNextPage(AGoForward: Boolean);
var
  LNext: TDaisyFmxTabSheet;
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

function TDaisyFmxPageControl.TabHeight: Single;
begin
  Result := CTabHeights[SizeKind];
end;

function TDaisyFmxPageControl.StripGap: Single;
begin
  if FTabStyle = dtsBox then
    Result := 6
  else
    Result := 0;
end;

function TDaisyFmxPageControl.BoxRectF: TRectF;
begin
  if FTabPosition = dtpTop then
    Result := RectF(0, TabHeight + StripGap, Width, Height)
  else
    Result := RectF(0, 0, Width, Height - TabHeight - StripGap);
end;

function TDaisyFmxPageControl.SheetRect: TRectF;
var
  LBorder: Single;
begin
  Result := BoxRectF;
  LBorder := Max(1, Theme.BorderWidth);
  Result.Inflate(-LBorder, -LBorder);
end;

procedure TDaisyFmxPageControl.UpdateSheetBounds;
var
  LRect: TRectF;
  LSheet: TDaisyFmxTabSheet;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  LRect := SheetRect;
  for LSheet in FPages do
    LSheet.SetBounds(LRect.Left, LRect.Top, Max(0, LRect.Width), Max(0, LRect.Height));
end;

function TDaisyFmxPageControl.TabTint: TAlphaColor;
begin
  if Variant = dvDefault then
    Result := Theme.BaseContent
  else
    Result := DaisyVariantPalette(Theme, Variant).Fill;
end;

function TDaisyFmxPageControl.TabContentWidth(ASheet: TDaisyFmxTabSheet): Single;
var
  LFont: Integer;
begin
  LFont := DaisyFontSize(SizeKind);
  Result := MeasureTextWidth(ASheet.Text, LFont, False);
  if not ASheet.Icon.IsEmpty then
  begin
    Result := Result + LFont * 1.25;
    if ASheet.Text <> '' then
      Result := Result + 6;
  end;
end;

procedure TDaisyFmxPageControl.EnsureLayout;
var
  I: Integer;
  LX, LTop, LBottom, LInset, LStripTop, LStripBottom, LTotal: Single;
  LSheet: TDaisyFmxTabSheet;
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
    LStripTop := Height - TabHeight;
    LStripBottom := Height;
  end;

  LInset := 0;
  LX := 0;
  case FTabStyle of
    dtsBox:
      begin
        LInset := 4;
        LX := LInset;
      end;
    dtsLift:
      LX := Min(Theme.RadiusBox, 16);
  end;
  LTop := LStripTop + LInset;
  LBottom := LStripBottom - LInset;

  for I := 0 to FPages.Count - 1 do
  begin
    LSheet := FPages[I];
    if not LSheet.TabVisible then
    begin
      FTabRects[I] := RectF(0, 0, 0, 0);
      Continue;
    end;
    FTabRects[I] := RectF(LX, LTop, LX + TabContentWidth(LSheet) + 2 * CTabPadding[SizeKind], LBottom);
    LX := FTabRects[I].Right;
  end;
  LTotal := LX + LInset;
  FMaxScroll := Max(0, LTotal - Width);
  if FScrollToActive then
  begin
    FScrollToActive := False;
    I := FPages.IndexOf(FActive);
    if (I >= 0) and FPages[I].TabVisible then
    begin
      if FTabRects[I].Right - FScrollX > Width then
        FScrollX := FTabRects[I].Right + LInset - Width;
      if FTabRects[I].Left - FScrollX < 0 then
        FScrollX := FTabRects[I].Left - LInset;
    end;
  end;
  FScrollX := EnsureRange(FScrollX, 0, FMaxScroll);
  if FScrollX <> 0 then
    for I := 0 to High(FTabRects) do
      FTabRects[I].Offset(-FScrollX, 0);
  FStripRect := RectF(0, LStripTop, Min(LTotal - FScrollX, Width), LStripBottom);
end;

function TDaisyFmxPageControl.TabAt(X, Y: Single): Integer;
var
  I: Integer;
  LHit: TRectF;
begin
  Result := -1;
  EnsureLayout;
  for I := 0 to High(FTabRects) do
    if FPages[I].TabVisible then
    begin
      LHit := RectF(FTabRects[I].Left, FStripRect.Top, FTabRects[I].Right, FStripRect.Bottom);
      if LHit.Contains(PointF(X, Y)) then
        Exit(I);
    end;
end;

procedure TDaisyFmxPageControl.SizeChanged;
begin
  UpdateSheetBounds;
  PageChanged;
end;

procedure TDaisyFmxPageControl.Resize;
begin
  inherited Resize;
  UpdateSheetBounds;
  FLayoutDirty := True;
end;

procedure TDaisyFmxPageControl.Loaded;
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

procedure TDaisyFmxPageControl.DoMouseLeave;
begin
  inherited DoMouseLeave;
  SetHotTab(-1);
end;

procedure TDaisyFmxPageControl.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LTab: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  LTab := TabAt(X, Y);
  if (LTab >= 0) and not FPages[LTab].Enabled then
    LTab := -1;
  SetHotTab(LTab);
end;

procedure TDaisyFmxPageControl.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  LPos: TPointF;
begin
  inherited MouseWheel(Shift, WheelDelta, Handled);
  if Handled or (FMaxScroll <= 0) then
    Exit;
  LPos := ScreenToLocal(Screen.MousePos);
  if (LPos.Y >= FStripRect.Top) and (LPos.Y < FStripRect.Bottom) then
  begin
    FScrollX := EnsureRange(FScrollX - Sign(WheelDelta) * 48, 0, FMaxScroll);
    FLayoutDirty := True;
    Repaint;
    Handled := True;
  end;
end;

procedure TDaisyFmxPageControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LTab: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> TMouseButton.mbLeft then
    Exit;
  LTab := TabAt(X, Y);
  if LTab < 0 then
    Exit;
  if (not (csDesigning in ComponentState)) and CanFocus and not IsFocused then
    SetFocus;
  if FPages[LTab].Enabled or (csDesigning in ComponentState) then
    SetActivePage(FPages[LTab]);
end;

procedure TDaisyFmxPageControl.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  case Key of
    vkLeft, vkUp:
      begin
        SelectNextPage(False);
        Key := 0;
      end;
    vkRight, vkDown:
      begin
        SelectNextPage(True);
        Key := 0;
      end;
  else
    inherited KeyDown(Key, KeyChar, Shift);
  end;
end;

{ Drawing }

procedure TDaisyFmxPageControl.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LBox, LTab, LRect, LIconBox, LText: TRectF;
  LBorder, LFieldRadius, LBoxRadius, LFade, LX, LIconSize, LBar, LHalf: Single;
  LTint, LTextColor, LOnTint, LActiveFill, LTabTint: TAlphaColor;
  LCustom: Boolean;
  LSaved: TCanvasSaveState;
  LPalette: TDaisyPalette;
  LSheet: TDaisyFmxTabSheet;
  LTop: Boolean;
  LCorners: TCorners;
  I, LFont: Integer;
begin
  EnsureLayout;
  LTop := FTabPosition = dtpTop;
  LBorder := Max(1, Theme.BorderWidth);
  LBoxRadius := Theme.RadiusBox;
  LFieldRadius := Theme.RadiusField;
  LBox := BoxRectF;
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

  FillRound(LBox, LBoxRadius, DaisyWithAlpha(Theme.Base100, LFade));
  StrokeRound(LBox, LBoxRadius, DaisyWithAlpha(Theme.BorderColor, LFade), LBorder, False);

  if FTabStyle = dtsBox then
    FillRound(FStripRect, LFieldRadius + 4, DaisyWithAlpha(Theme.Base200, LFade));

  LSaved := Canvas.SaveState;
  Canvas.IntersectClipRect(RectF(0, 0, Width, Height));

  for I := 0 to FPages.Count - 1 do
  begin
    LSheet := FPages[I];
    if (not LSheet.TabVisible) or (LSheet <> FActive) then
      Continue;
    LTab := FTabRects[I];
    LCustom := LSheet.TabColor <> TAlphaColors.Null;
    LTabTint := LTint;
    if LCustom then
      LTabTint := LSheet.TabColor;

    case FTabStyle of
      dtsBox:
        begin
          if LCustom then
            LActiveFill := LTabTint
          else if Variant = dvDefault then
            LActiveFill := Theme.Base100
          else
            LActiveFill := LTint;
          FillRound(LTab, LFieldRadius, DaisyWithAlpha(LActiveFill, LFade));
          if (Variant = dvDefault) and not LCustom then
            StrokeRound(LTab, LFieldRadius, DaisyWithAlpha(Theme.BorderColor, LFade), LBorder, False);
        end;
      dtsBorder:
        begin
          LBar := Max(2, 3);
          if LTop then
            LRect := RectF(LTab.Left, LTab.Bottom - LBar + LBorder, LTab.Right, LTab.Bottom + LBorder)
          else
            LRect := RectF(LTab.Left, LTab.Top - LBorder, LTab.Right, LTab.Top + LBar - LBorder);
          FillRound(LRect, LBar / 2, DaisyWithAlpha(LTabTint, LFade));
        end;
      dtsLift:
        begin
          // The tab outline is drawn full, then its edge on the content box is rubbed out
          LRect := LTab;
          if LTop then
          begin
            LRect.Bottom := LRect.Bottom + LBorder;
            LCorners := [TCorner.TopLeft, TCorner.TopRight];
          end
          else
          begin
            LRect.Top := LRect.Top - LBorder;
            LCorners := [TCorner.BottomLeft, TCorner.BottomRight];
          end;
          LHalf := LFieldRadius + 2;
          Canvas.Fill.Kind := TBrushKind.Solid;
          Canvas.Fill.Color := DaisyWithAlpha(IfThenColor(LCustom, LTabTint, Theme.Base100), LFade);
          Canvas.FillRect(LRect, LHalf, LHalf, LCorners, AbsoluteOpacity);
          Canvas.Stroke.Kind := TBrushKind.Solid;
          Canvas.Stroke.Color := DaisyWithAlpha(Theme.BorderColor, LFade);
          Canvas.Stroke.Thickness := LBorder;
          Canvas.Stroke.Dash := TStrokeDash.Solid;
          LBox := LRect;
          LBox.Inflate(-LBorder / 2, -LBorder / 2);
          Canvas.DrawRect(LBox, Max(0, LHalf - LBorder / 2), Max(0, LHalf - LBorder / 2), LCorners,
            AbsoluteOpacity);
          if LTop then
            LRect := RectF(LTab.Left + LBorder, LTab.Bottom, LTab.Right - LBorder, LTab.Bottom + LBorder)
          else
            LRect := RectF(LTab.Left + LBorder, LTab.Top - LBorder, LTab.Right - LBorder, LTab.Top);
          FillRound(LRect, 0, DaisyWithAlpha(IfThenColor(LCustom, LTabTint, Theme.Base100), LFade));
          LBox := BoxRectF;
        end;
    end;
  end;

  LIconSize := LFont * 1.25;
  for I := 0 to FPages.Count - 1 do
  begin
    LSheet := FPages[I];
    if not LSheet.TabVisible then
      Continue;
    LTab := FTabRects[I];
    if LSheet = FActive then
    begin
      if LSheet.TabColor <> TAlphaColors.Null then
      begin
        LTextColor := Theme.BaseContent;
        if FTabStyle = dtsBorder then
          LTextColor := LSheet.TabColor
        else if FTabStyle = dtsBox then
          LTextColor := ContrastOn(LSheet.TabColor);
      end
      else if (FTabStyle = dtsBox) and (Variant <> dvDefault) then
        LTextColor := LOnTint
      else
        LTextColor := LTint;
    end
    else if I = FHotTab then
      LTextColor := DaisyWithAlpha(Theme.BaseContent, 0.85)
    else
      LTextColor := DaisyWithAlpha(Theme.BaseContent, 0.6);
    if (not LSheet.Enabled) or (not Enabled) then
      LTextColor := DaisyWithAlpha(Theme.BaseContent, 0.25);

    LX := LTab.Left + CTabPadding[SizeKind];
    if not LSheet.Icon.IsEmpty then
    begin
      LIconBox := RectF(LX, (LTab.Top + LTab.Bottom - LIconSize) / 2, LX + LIconSize,
        (LTab.Top + LTab.Bottom - LIconSize) / 2 + LIconSize);
      DrawGlyph(LSheet.Icon, LIconBox, LTextColor);
      LX := LX + LIconSize;
      if LSheet.Text <> '' then
        LX := LX + 6;
    end;
    if LSheet.Text <> '' then
    begin
      LText := RectF(LX, LTab.Top, LTab.Right - CTabPadding[SizeKind] + 4, LTab.Bottom);
      DrawText(LSheet.Text, LText, LTextColor, LFont, False, TTextAlign.Leading, TTextAlign.Center, False);
    end;
  end;
  Canvas.RestoreState(LSaved);
end;

end.
