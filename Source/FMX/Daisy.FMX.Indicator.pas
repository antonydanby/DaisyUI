unit Daisy.FMX.Indicator;

{
  TDaisyFmxIndicator - the DaisyUI "indicator": a small item (badge, status dot or button)
  sitting on a corner, edge or the centre of the content placed in the control.
  Put the content inside the indicator, in the area left free around the item (the
  dashed box at design time). The item is drawn above the content; its colours come
  from ItemVariant, ItemStyle and ItemSize.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Indicators, Daisy.FMX.Control;

type
  TDaisyFmxIndicator = class(TDaisyControl)
  strict private
    FItemKind: TDaisyIndicatorKind;
    FItemText: string;
    FItemVariant: TDaisyVariant;
    FItemStyle: TDaisyStyle;
    FItemSize: TDaisySize;
    FHorizontal: TDaisyIndicatorHorz;
    FVertical: TDaisyIndicatorVert;
    FShowItem: Boolean;
    FItemDown: Boolean;
    FOnItemClick: TNotifyEvent;
    procedure SetItemKind(const AValue: TDaisyIndicatorKind);
    procedure SetItemText(const AValue: string);
    procedure SetItemVariant(const AValue: TDaisyVariant);
    procedure SetItemStyle(const AValue: TDaisyStyle);
    procedure SetItemSize(const AValue: TDaisySize);
    procedure SetHorizontal(const AValue: TDaisyIndicatorHorz);
    procedure SetVertical(const AValue: TDaisyIndicatorVert);
    procedure SetShowItem(const AValue: Boolean);
    function ItemSizePx: TSizeF;
    function ItemBox(out AContent: TRectF): TRectF;
    function ItemClickable: Boolean;
    function ItemColors: TDaisyColors;
    procedure DrawItem;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure PaintChildren; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
    function ObjectAtPoint(AScreenPoint: TPointF): IControl; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
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

{ TDaisyFmxIndicator }

constructor TDaisyFmxIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItemKind := ikBadge;
  FItemText := '99';
  FItemVariant := dvSecondary;
  FItemSize := dzMD;
  FHorizontal := ihEnd;
  FVertical := ivTop;
  FShowItem := True;
  SetBounds(Position.X, Position.Y, 120, 88);
end;

function TDaisyFmxIndicator.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxIndicator.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxIndicator.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxIndicator.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxIndicator.ItemSizePx: TSizeF;
begin
  case FItemKind of
    ikStatus:
      begin
        Result.Width := DaisyIndicatorStatusSize(FItemSize);
        Result.Height := Result.Width;
      end;
    ikButton:
      begin
        Result.Height := DaisyFieldHeight(FItemSize);
        Result.Width := System.Math.Max(Result.Height,
          MeasureTextWidth(FItemText, DaisyBadgeFontSize(FItemSize), False) + 24);
      end;
  else
    Result.Height := DaisyBadgeHeight(FItemSize);
    Result.Width := BadgeWidth(FItemText, FItemSize, diNone);
  end;
end;

function TDaisyFmxIndicator.ItemBox(out AContent: TRectF): TRectF;
var
  LSize: TSizeF;
begin
  LSize := ItemSizePx;
  DaisyIndicatorLayout(RectF(0, 0, Width, Height), LSize.Width, LSize.Height, FHorizontal,
    FVertical, AContent, Result);
end;

function TDaisyFmxIndicator.ItemClickable: Boolean;
begin
  Result := FShowItem and (FItemKind = ikButton) and Enabled
    and not (csDesigning in ComponentState);
end;

function TDaisyFmxIndicator.ItemColors: TDaisyColors;
begin
  if (FItemKind = ikStatus) and Enabled then
  begin
    Result := Default(TDaisyColors);
    if FItemVariant = dvDefault then
      Result.Background := DaisyWithAlpha(Theme.BaseContent, 0.2)
    else
      Result.Background := DaisyVariantPalette(Theme, FItemVariant).Fill;
  end
  else
    Result := DaisyBadgeColors(Theme, FItemVariant, FItemStyle);
end;

procedure TDaisyFmxIndicator.DrawItem;
var
  LContent, LBox: TRectF;
  LColors: TDaisyColors;
  LRadius: Single;
begin
  if not FShowItem then
    Exit;
  LBox := ItemBox(LContent);
  LColors := ItemColors;
  case FItemKind of
    ikStatus: LRadius := LBox.Width / 2;
    ikButton: LRadius := System.Math.Min(Theme.RadiusField, LBox.Height / 2);
  else
    LRadius := System.Math.Min(Theme.RadiusSelector, LBox.Height / 2);
  end;
  DrawBadgeShape(LBox, LColors, LRadius);
  if FItemKind <> ikStatus then
    DrawBadgeContent(LBox, FItemText, LColors.Text, FItemSize, diNone, bipLeft);
end;

// The item sits above the content, so it is drawn after the children
procedure TDaisyFmxIndicator.PaintChildren;
begin
  inherited PaintChildren;
  Canvas.SetMatrix(AbsoluteMatrix);
  DrawItem;
end;

// Only a design-time guide: the box the content is meant to fill
procedure TDaisyFmxIndicator.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LContent: TRectF;
begin
  if not (csDesigning in ComponentState) then
    Exit;
  ItemBox(LContent);
  StrokeRound(LContent, 0, DaisyWithAlpha(Theme.BaseContent, 0.25), 1, True);
end;

// A button item overlaps the content, so it must win the click
function TDaisyFmxIndicator.ObjectAtPoint(AScreenPoint: TPointF): IControl;
var
  LContent: TRectF;
begin
  if ItemClickable and ItemBox(LContent).Contains(ScreenToLocal(AScreenPoint)) then
    Result := Self
  else
    Result := inherited ObjectAtPoint(AScreenPoint);
end;

procedure TDaisyFmxIndicator.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LContent: TRectF;
begin
  inherited MouseDown(Button, Shift, X, Y);
  FItemDown := (Button = TMouseButton.mbLeft) and ItemClickable
    and ItemBox(LContent).Contains(PointF(X, Y));
end;

procedure TDaisyFmxIndicator.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LContent: TRectF;
  LFire: Boolean;
begin
  LFire := FItemDown and ItemBox(LContent).Contains(PointF(X, Y));
  FItemDown := False;
  inherited MouseUp(Button, Shift, X, Y);
  if LFire and Assigned(FOnItemClick) then
    FOnItemClick(Self);
end;

procedure TDaisyFmxIndicator.SetItemKind(const AValue: TDaisyIndicatorKind);
begin
  if FItemKind <> AValue then
  begin
    FItemKind := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxIndicator.SetItemText(const AValue: string);
begin
  if FItemText <> AValue then
  begin
    FItemText := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxIndicator.SetItemVariant(const AValue: TDaisyVariant);
begin
  if FItemVariant <> AValue then
  begin
    FItemVariant := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxIndicator.SetItemStyle(const AValue: TDaisyStyle);
begin
  if FItemStyle <> AValue then
  begin
    FItemStyle := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxIndicator.SetItemSize(const AValue: TDaisySize);
begin
  if FItemSize <> AValue then
  begin
    FItemSize := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxIndicator.SetHorizontal(const AValue: TDaisyIndicatorHorz);
begin
  if FHorizontal <> AValue then
  begin
    FHorizontal := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxIndicator.SetVertical(const AValue: TDaisyIndicatorVert);
begin
  if FVertical <> AValue then
  begin
    FVertical := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxIndicator.SetShowItem(const AValue: Boolean);
begin
  if FShowItem <> AValue then
  begin
    FShowItem := AValue;
    Repaint;
  end;
end;

end.
