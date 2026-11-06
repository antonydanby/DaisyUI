unit Daisy.VCL.Indicator;

{
  TDaisyIndicator - the DaisyUI "indicator": a small item (badge, status dot or button)
  sitting on a corner, edge or the centre of the content placed in the control.
  Put the content inside the indicator, in the area left free around the item (the
  dashed box at design time). The item is a window of its own so it can overlap the
  content; its colours come from ItemVariant, ItemStyle and ItemSize.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.Indicators, Daisy.VCL.Control, Daisy.VCL.Badge;

type
  // The item drawn on the indicator; created and owned by TDaisyIndicator
  TDaisyIndicatorItem = class(TDaisyBadge)
  strict private
    FKind: TDaisyIndicatorKind;
    procedure SetKind(const Value: TDaisyIndicatorKind);
    function Clickable: Boolean;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    function IsInteractive: Boolean; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    function PreferredSize: TSize;
    property Kind: TDaisyIndicatorKind read FKind write SetKind;
  end;

  TDaisyIndicator = class(TDaisyControl)
  strict private
    FItem: TDaisyIndicatorItem;
    FItemKind: TDaisyIndicatorKind;
    FItemText: string;
    FItemVariant: TDaisyVariant;
    FItemStyle: TDaisyStyle;
    FItemSize: TDaisySize;
    FHorizontal: TDaisyIndicatorHorz;
    FVertical: TDaisyIndicatorVert;
    FShowItem: Boolean;
    FSyncing: Boolean;
    FOnItemClick: TNotifyEvent;
    procedure SetItemKind(const Value: TDaisyIndicatorKind);
    procedure SetItemText(const Value: string);
    procedure SetItemVariant(const Value: TDaisyVariant);
    procedure SetItemStyle(const Value: TDaisyStyle);
    procedure SetItemSize(const Value: TDaisySize);
    procedure SetHorizontal(const Value: TDaisyIndicatorHorz);
    procedure SetVertical(const Value: TDaisyIndicatorVert);
    procedure SetShowItem(const Value: Boolean);
    procedure ItemClicked(Sender: TObject);
    procedure SyncItem;
    function ItemBox(out AContent: TRectF): TRectF;
    procedure CMControlListChange(var Message: TCMControlListChange); message CM_CONTROLLISTCHANGE;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Invalidate; override;
  published
    property ItemKind: TDaisyIndicatorKind read FItemKind write SetItemKind default ikBadge;
    // Caption of a badge or button item; an empty badge is a small dot
    property ItemText: string read FItemText write SetItemText;
    property ItemVariant: TDaisyVariant read FItemVariant write SetItemVariant default dvSecondary;
    property ItemStyle: TDaisyStyle read FItemStyle write SetItemStyle default dsSolid;
    property ItemSize: TDaisySize read FItemSize write SetItemSize default dzMD;
    property HorizontalPlacement: TDaisyIndicatorHorz read FHorizontal write SetHorizontal
      default ihEnd;
    property VerticalPlacement: TDaisyIndicatorVert read FVertical write SetVertical
      default ivTop;
    property ShowItem: Boolean read FShowItem write SetShowItem default True;
    // Fires when a button item is clicked
    property OnItemClick: TNotifyEvent read FOnItemClick write FOnItemClick;
  end;

implementation

{ TDaisyIndicatorItem }

constructor TDaisyIndicatorItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoWidth := False;
  TabStop := False;
  ControlStyle := ControlStyle + [csNoDesignVisible] - [csCaptureMouse];
end;

procedure TDaisyIndicatorItem.SetKind(const Value: TDaisyIndicatorKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    if Clickable then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

function TDaisyIndicatorItem.Clickable: Boolean;
begin
  Result := (FKind = ikButton) and not (csDesigning in ComponentState);
end;

function TDaisyIndicatorItem.IsInteractive: Boolean;
begin
  Result := Clickable;
end;

function TDaisyIndicatorItem.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  if (FKind = ikStatus) and (AState <> dstDisabled) then
  begin
    Result := Default(TDaisyColors);
    if Variant = dvDefault then
      Result.Background := DaisyWithAlpha(Theme.BaseContent, 0.2)
    else
      Result.Background := DaisyVariantPalette(Theme, Variant).Fill;
  end
  else
    Result := inherited DefaultStyleColors(AState);
end;

// Height and radius are set by the indicator
procedure TDaisyIndicatorItem.SizeChanged;
begin
  Invalidate;
end;

function TDaisyIndicatorItem.PreferredSize: TSize;
var
  LBadgeH: Integer;
begin
  LBadgeH := ScaleValue(DaisyBadgeHeight(SizeKind));
  case FKind of
    ikStatus:
      begin
        Result.cx := ScaleValue(DaisyIndicatorStatusSize(SizeKind));
        Result.cy := Result.cx;
      end;
    ikButton:
      begin
        Result.cy := ScaleValue(DaisyFieldHeight(SizeKind));
        Result.cx := MeasureTextWidth(Caption, DaisyBadgeFontSize(SizeKind), False)
          + 2 * ScaleValue(12);
        Result.cx := Max(Result.cx, Result.cy);
      end;
  else
    Result.cy := LBadgeH;
    Result.cx := BadgeWidth(Caption, SizeKind, diNone);
  end;
end;

// A window region would give jagged corners, so the content behind the item (the parent and
// its other children) is painted into the background and the item is drawn anti-aliased on it
procedure TDaisyIndicatorItem.WMEraseBkgnd(var Message: TWMEraseBkgnd);
var
  I: Integer;
  LSibling: TControl;
  LSaved: Integer;
begin
  inherited;
  if Parent = nil then
    Exit;
  LSaved := SaveDC(Message.DC);
  try
    IntersectClipRect(Message.DC, 0, 0, Width, Height);
    for I := 0 to Parent.ControlCount - 1 do
    begin
      LSibling := Parent.Controls[I];
      if (LSibling <> Self) and (LSibling is TWinControl) and LSibling.Visible
        and LSibling.BoundsRect.IntersectsWith(BoundsRect) then
        TWinControl(LSibling).PaintTo(Message.DC, LSibling.Left - Left, LSibling.Top - Top);
    end;
  finally
    RestoreDC(Message.DC, LSaved);
  end;
end;

// Only a button item takes the mouse; the others let it through to the indicator
procedure TDaisyIndicatorItem.WMNCHitTest(var Message: TWMNCHitTest);
begin
  if Clickable then
    inherited
  else
    Message.Result := HTTRANSPARENT;
end;

{ TDaisyIndicator }

constructor TDaisyIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FItemKind := ikBadge;
  FItemText := '99';
  FItemVariant := dvSecondary;
  FItemSize := dzMD;
  FHorizontal := ihEnd;
  FVertical := ivTop;
  FShowItem := True;
  SetBounds(Left, Top, 120, 88);
  FItem := TDaisyIndicatorItem.Create(Self);
  FItem.Parent := Self;
  FItem.OnClick := ItemClicked;
  SyncItem;
end;

procedure TDaisyIndicator.ItemClicked(Sender: TObject);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self);
end;

function TDaisyIndicator.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyIndicator.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyIndicator.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyIndicator.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

// Keeps the item above the content, which may be added or reordered at any time
procedure TDaisyIndicator.CMControlListChange(var Message: TCMControlListChange);
begin
  inherited;
  if (FItem <> nil) and not FSyncing and not (csDestroying in ComponentState) then
  begin
    FSyncing := True;
    try
      FItem.BringToFront;
    finally
      FSyncing := False;
    end;
  end;
end;

function TDaisyIndicator.ItemBox(out AContent: TRectF): TRectF;
var
  LSize: TSize;
begin
  LSize := FItem.PreferredSize;
  DaisyIndicatorLayout(RectF(0, 0, Width, Height), LSize.cx, LSize.cy, FHorizontal, FVertical,
    AContent, Result);
end;

procedure TDaisyIndicator.SyncItem;
var
  LContent, LBox: TRectF;
  LRadius: Integer;
begin
  if (FItem = nil) or FSyncing or (csDestroying in ComponentState) then
    Exit;
  FSyncing := True;
  try
    FItem.ThemeKind := ThemeKind;
    FItem.Variant := FItemVariant;
    FItem.Style := FItemStyle;
    FItem.SizeKind := FItemSize;
    FItem.Kind := FItemKind;
    if FItemKind = ikStatus then
      FItem.Caption := '' // a status dot is a plain solid circle
    else
      FItem.Caption := FItemText;
    if FItemKind = ikButton then
      LRadius := Theme.RadiusField
    else
      LRadius := Theme.RadiusSelector;
    FItem.CornerRadius := LRadius;
    FItem.Enabled := Enabled;
    LBox := ItemBox(LContent);
    FItem.SetBounds(Round(LBox.Left), Round(LBox.Top), Round(LBox.Width), Round(LBox.Height));
    FItem.Visible := FShowItem;
    FItem.BringToFront;
  finally
    FSyncing := False;
  end;
end;

procedure TDaisyIndicator.Invalidate;
begin
  SyncItem;
  inherited Invalidate;
end;

procedure TDaisyIndicator.SizeChanged;
begin
  SyncItem;
end;

procedure TDaisyIndicator.Resize;
begin
  SyncItem;
  inherited;
end;

procedure TDaisyIndicator.Loaded;
begin
  inherited;
  SyncItem;
end;

procedure TDaisyIndicator.SetItemKind(const Value: TDaisyIndicatorKind);
begin
  if FItemKind <> Value then
  begin
    FItemKind := Value;
    Invalidate;
  end;
end;

procedure TDaisyIndicator.SetItemText(const Value: string);
begin
  if FItemText <> Value then
  begin
    FItemText := Value;
    Invalidate;
  end;
end;

procedure TDaisyIndicator.SetItemVariant(const Value: TDaisyVariant);
begin
  if FItemVariant <> Value then
  begin
    FItemVariant := Value;
    Invalidate;
  end;
end;

procedure TDaisyIndicator.SetItemStyle(const Value: TDaisyStyle);
begin
  if FItemStyle <> Value then
  begin
    FItemStyle := Value;
    Invalidate;
  end;
end;

procedure TDaisyIndicator.SetItemSize(const Value: TDaisySize);
begin
  if FItemSize <> Value then
  begin
    FItemSize := Value;
    Invalidate;
  end;
end;

procedure TDaisyIndicator.SetHorizontal(const Value: TDaisyIndicatorHorz);
begin
  if FHorizontal <> Value then
  begin
    FHorizontal := Value;
    Invalidate;
  end;
end;

procedure TDaisyIndicator.SetVertical(const Value: TDaisyIndicatorVert);
begin
  if FVertical <> Value then
  begin
    FVertical := Value;
    Invalidate;
  end;
end;

procedure TDaisyIndicator.SetShowItem(const Value: Boolean);
begin
  if FShowItem <> Value then
  begin
    FShowItem := Value;
    Invalidate;
  end;
end;

// Only a design-time guide: the box the content is meant to fill
procedure TDaisyIndicator.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LContent: TRectF;
begin
  if not (csDesigning in ComponentState) then
    Exit;
  ItemBox(LContent);
  LGraphics := NewGraphics;
  try
    StrokeRoundRect(LGraphics, LContent, 0, DaisyWithAlpha(Theme.BaseContent, 0.25), 1, True);
  finally
    LGraphics.Free;
  end;
end;

end.
