unit Daisy.FMX.Fab;

{
  TDaisyFmxFloatingActionButton - a round main button that expands to a speed
  dial of action buttons (see daisyui.com/components/fab). The control grows in
  Direction when opened and returns to its original bounds when closed, so at
  design time only the main button is shown.
}

interface

uses
  System.Classes, System.Types, System.UITypes, FMX.Types, FMX.Controls,
  Daisy.Theme, Daisy.Items, Daisy.FMX.Control;

type
  TDaisyFmxFloatingActionButton = class(TDaisyControl)
  strict private
    FItems: TDaisyItems;
    FDirection: TDaisyFabDirection;
    FOpen: Boolean;
    FText: string;
    FRestore: TRectF;
    FHotIndex: Integer; // -2 none, -1 main button, 0.. item
    FOnItemClick: TDaisyItemClickEvent;
    procedure SetItems(const Value: TDaisyItems);
    procedure SetDirection(const Value: TDaisyFabDirection);
    procedure SetText(const Value: string);
    procedure SetOpen(const Value: Boolean);
    function Diameter: Single;
    function LabelFontSize: Integer;
    function LabelWidth: Single;
    function MainRect: TRectF;
    function ArcRadius: Single;
    function ItemRect(AIndex: Integer): TRectF;
    function LabelRect(AIndex: Integer): TRectF;
    function HitTestAt(const APoint: TPointF): Integer;
    procedure SetHotIndex(const Value: Integer);
    procedure ItemsChanged(Sender: TObject);
  protected
    function DefaultShadowSize: Integer; override;
    procedure Loaded; override;
    procedure SizeChanged; override;
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DoMouseLeave; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Toggle;
    property IsOpen: Boolean read FOpen write SetOpen;
  published
    property Text: string read FText write SetText;
    property Items: TDaisyItems read FItems write SetItems;
    property Direction: TDaisyFabDirection read FDirection write SetDirection default fdUp;
    property OnItemClick: TDaisyItemClickEvent read FOnItemClick write FOnItemClick;
  end;

implementation

uses
  System.SysUtils, System.Math, FMX.Graphics, FMX.TextLayout;

const
  NoHot = -2;
  MainHot = -1;
  PlusShift = 3; // px to lift the '+' glyph to the visual centre
  ItemGap = 10;
  LabelHeight = 32;

function TextWidthOf(const AText: string; AFontSize: Integer): Single;
var
  LLayout: TTextLayout;
begin
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.Text := AText;
    LLayout.Font.Size := AFontSize;
    Result := LLayout.TextWidth;
  finally
    LLayout.Free;
  end;
end;

{ TDaisyFmxFloatingActionButton }

constructor TDaisyFmxFloatingActionButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FDirection := fdUp;
  FText := '+';
  FHotIndex := NoHot;
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  Variant := dvPrimary;
  SetBounds(Position.X, Position.Y, Diameter + 2 * ResolvedShadowSize, Diameter + 2 * ResolvedShadowSize);
end;

destructor TDaisyFmxFloatingActionButton.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TDaisyFmxFloatingActionButton.DefaultShadowSize: Integer;
begin
  Result := 0; // the floating action button is flat (no shadow)
end;

procedure TDaisyFmxFloatingActionButton.Loaded;
begin
  inherited;
  // SizeKind does not resize while loading, so re-fit the stored bounds
  SizeChanged;
end;

function TDaisyFmxFloatingActionButton.Diameter: Single;
begin
  Result := DaisyFieldHeight(SizeKind) + 8;
end;

function TDaisyFmxFloatingActionButton.LabelFontSize: Integer;
begin
  Result := DaisyFontSize(dzSM);
end;

function TDaisyFmxFloatingActionButton.LabelWidth: Single;
var
  I: Integer;
begin
  Result := 0;
  if not (FDirection in [fdUp, fdDown]) then
    Exit;
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Description <> '' then
      Result := Max(Result, TextWidthOf(FItems[I].Description, LabelFontSize) + 24);
end;

procedure TDaisyFmxFloatingActionButton.SizeChanged;
begin
  if FOpen then
    Exit;
  SetBounds(Position.X, Position.Y, Diameter + 2 * ResolvedShadowSize, Diameter + 2 * ResolvedShadowSize);
end;

function TDaisyFmxFloatingActionButton.MainRect: TRectF;
var
  LShadow, D: Single;
begin
  LShadow := ResolvedShadowSize;
  D := Diameter;
  case FDirection of
    fdUp, fdArc: Result := RectF(Width - LShadow - D, Height - LShadow - D, Width - LShadow, Height - LShadow);
    fdDown, fdLeft: Result := RectF(Width - LShadow - D, LShadow, Width - LShadow, LShadow + D);
  else
    Result := RectF(LShadow, LShadow, LShadow + D, LShadow + D);
  end;
end;

// Radius at which neighbouring actions on the quarter circle keep a gap between them
function TDaisyFmxFloatingActionButton.ArcRadius: Single;
var
  LMin: Single;
begin
  LMin := Diameter + ItemGap;
  Result := LMin;
  if FItems.Count > 1 then
    Result := Max(Result, LMin / (2 * Sin(Pi / 4 / (FItems.Count - 1))));
end;

function TDaisyFmxFloatingActionButton.ItemRect(AIndex: Integer): TRectF;
var
  LStep: Single;
  LAngle: Single;
begin
  LStep := (AIndex + 1) * (Diameter + ItemGap);
  Result := MainRect;
  if FDirection = fdArc then
  begin
    // 0 = straight up, Pi/2 = straight left
    if FItems.Count > 1 then
      LAngle := AIndex * (Pi / 2) / (FItems.Count - 1)
    else
      LAngle := Pi / 4;
    Result.Offset(-ArcRadius * Sin(LAngle), -ArcRadius * Cos(LAngle));
    Exit;
  end;
  case FDirection of
    fdUp: Result.Offset(0, -LStep);
    fdDown: Result.Offset(0, LStep);
    fdLeft: Result.Offset(-LStep, 0);
  else
    Result.Offset(LStep, 0);
  end;
end;

function TDaisyFmxFloatingActionButton.LabelRect(AIndex: Integer): TRectF;
var
  LItem: TRectF;
  LWidth: Single;
begin
  LItem := ItemRect(AIndex);
  LWidth := TextWidthOf(FItems[AIndex].Description, LabelFontSize) + 24;
  Result := RectF(LItem.Left - ItemGap - LWidth, LItem.Top + (Diameter - LabelHeight) / 2,
    LItem.Left - ItemGap, LItem.Top + (Diameter - LabelHeight) / 2 + LabelHeight);
end;

function TDaisyFmxFloatingActionButton.HitTestAt(const APoint: TPointF): Integer;
var
  I: Integer;
begin
  Result := NoHot;
  if MainRect.Contains(APoint) then
    Exit(MainHot);
  if not FOpen then
    Exit;
  for I := 0 to FItems.Count - 1 do
    if ItemRect(I).Contains(APoint) or
       ((FItems[I].Description <> '') and (FDirection in [fdUp, fdDown]) and LabelRect(I).Contains(APoint)) then
      Exit(I);
end;

procedure TDaisyFmxFloatingActionButton.SetOpen(const Value: Boolean);
var
  LSpan, LLabels, LNewW, LNewH, LRight, LBottom, LNewLeft: Single;
  LAnchorRight: Boolean;
begin
  if (FOpen = Value) or (csDesigning in ComponentState) or (csLoading in ComponentState) then
    Exit;
  if Value and (FItems.Count = 0) then
    Exit;
  if Value then
  begin
    FRestore := RectF(Position.X, Position.Y, Position.X + Width, Position.Y + Height);
    LSpan := FItems.Count * (Diameter + ItemGap);
    LLabels := LabelWidth;
    LNewW := Width;
    LNewH := Height;
    LRight := Position.X + Width;
    LBottom := Position.Y + Height;
    case FDirection of
      fdUp, fdDown:
        begin
          if LLabels > 0 then
            LNewW := Width + LLabels + ItemGap;
          LNewH := Height + LSpan;
        end;
      fdLeft, fdRight:
        LNewW := Width + LSpan;
      fdArc:
        begin
          LNewW := Width + ArcRadius;
          LNewH := Height + ArcRadius;
        end;
    end;
    FOpen := True;
    // Mirroring puts the logical-right main button on the physical left in RTL mode,
    // so the opposite physical edge must stay fixed
    LAnchorRight := (FDirection in [fdUp, fdDown, fdLeft, fdArc]) <> IsRTL;
    if LAnchorRight then
      LNewLeft := LRight - LNewW
    else
      LNewLeft := Position.X;
    if FDirection in [fdUp, fdArc] then
      SetBounds(LNewLeft, LBottom - LNewH, LNewW, LNewH)
    else
      SetBounds(LNewLeft, Position.Y, LNewW, LNewH);
  end
  else
  begin
    FOpen := False;
    SetBounds(FRestore.Left, FRestore.Top, FRestore.Width, FRestore.Height);
  end;
  FHotIndex := NoHot;
  Repaint;
end;

procedure TDaisyFmxFloatingActionButton.Toggle;
begin
  SetOpen(not FOpen);
end;

procedure TDaisyFmxFloatingActionButton.SetItems(const Value: TDaisyItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxFloatingActionButton.SetDirection(const Value: TDaisyFabDirection);
begin
  if FDirection <> Value then
  begin
    SetOpen(False);
    FDirection := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxFloatingActionButton.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxFloatingActionButton.ItemsChanged(Sender: TObject);
begin
  if FOpen then
    SetOpen(False);
  Repaint;
end;

procedure TDaisyFmxFloatingActionButton.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxFloatingActionButton.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;
  SetHotIndex(HitTestAt(PointF(X, Y)));
end;

procedure TDaisyFmxFloatingActionButton.DoMouseLeave;
begin
  inherited;
  SetHotIndex(NoHot);
end;

procedure TDaisyFmxFloatingActionButton.DoExit;
begin
  inherited;
  SetOpen(False);
end;

procedure TDaisyFmxFloatingActionButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LHit: Integer;
  LItem: TDaisyItem;
begin
  inherited;
  if Button <> TMouseButton.mbLeft then
    Exit;
  LHit := HitTestAt(PointF(X, Y));
  if LHit = MainHot then
  begin
    Toggle;
    Click;
  end
  else if (LHit >= 0) and FOpen then
  begin
    LItem := FItems[LHit];
    if LItem.Enabled then
    begin
      SetOpen(False);
      if Assigned(LItem.OnClick) then
        LItem.OnClick(LItem);
      if Assigned(FOnItemClick) then
        FOnItemClick(Self, LItem);
    end;
  end;
end;

procedure TDaisyFmxFloatingActionButton.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  inherited KeyDown(Key, KeyChar, Shift);
  if (Key = vkEscape) and FOpen then
  begin
    SetOpen(False);
    Key := 0;
  end
  else if (KeyChar = ' ') or (Key = vkReturn) then
  begin
    Toggle;
    Key := 0;
    KeyChar := #0;
  end;
end;

procedure TDaisyFmxFloatingActionButton.Paint;
var
  LColors: TDaisyColors;
  LMain, LRect, LLayer: TRectF;
  I: Integer;
  LItemBack: TAlphaColor;
  LItemColor: TAlphaColor;

  procedure FillCircle(const ARect: TRectF; AColor: TAlphaColor);
  begin
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := AColor;
    Canvas.FillEllipse(ARect, AbsoluteOpacity);
  end;

  // flat outline instead of a shadow so the buttons stay visible on light backgrounds;
  // drawn inside the item bounds so the control never clips it
  procedure DrawOutline(const ARect: TRectF);
  begin
    FillCircle(ARect, DaisyMix(Theme.Base300, TAlphaColors.Black, 0.25));
  end;

begin
  ApplyRTLMatrix;
  LColors := ResolveColors;
  LMain := MainRect;
  LItemBack := Theme.Base100;

  if FOpen then
    for I := 0 to FItems.Count - 1 do
    begin
      LRect := ItemRect(I);
      DrawOutline(LRect);
      LLayer := LRect;
      LLayer.Inflate(-1, -1);
      if I = FHotIndex then
        FillCircle(LLayer, DaisyMix(LItemBack, Theme.BaseContent, 0.1))
      else
        FillCircle(LLayer, LItemBack);
      if (FItems[I].Description <> '') and (FDirection in [fdUp, fdDown]) then
      begin
        LRect := LabelRect(I);
        Canvas.Fill.Kind := TBrushKind.Solid;
        Canvas.Fill.Color := LItemBack;
        Canvas.FillRect(LRect, Theme.RadiusField, Theme.RadiusField, AllCorners, AbsoluteOpacity);
      end;
    end;

  FillCircle(LMain, LColors.Background);

  if FOpen then
    for I := 0 to FItems.Count - 1 do
    begin
      if FItems[I].Enabled then
        LItemColor := Theme.BaseContent
      else
        LItemColor := DaisyWithAlpha(Theme.BaseContent, 0.35);
      DrawEmoji(FItems[I].Caption, ItemRect(I), LItemColor, DaisyFontSize(SizeKind) * 3 div 2);
      if (FItems[I].Description <> '') and (FDirection in [fdUp, fdDown]) then
        DrawText(FItems[I].Description, LabelRect(I), Theme.BaseContent, LabelFontSize, False,
          TTextAlign.Center, TTextAlign.Center, False);
    end;

  if FOpen then
    DrawEmoji(#$2715, LMain, LColors.Text, DaisyFontSize(SizeKind)) // half-size close glyph
  else if FText = '+' then
  begin
    // the font's line spacing leaves a text '+' below the true centre
    LRect := LMain;
    LRect.Offset(0, -PlusShift);
    DrawEmoji(FText, LRect, LColors.Text, DaisyFontSize(SizeKind) * 2);
  end
  else
    DrawEmoji(FText, LMain, LColors.Text, DaisyFontSize(SizeKind) * 2);
end;

end.
