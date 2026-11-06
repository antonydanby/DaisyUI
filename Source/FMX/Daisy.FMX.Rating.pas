unit Daisy.FMX.Rating;

{
  TDaisyFmxRating - the DaisyUI "rating": a row of stars (or hearts) the user clicks to pick
  a value. Shape picks star, plump star or heart, AllowHalf gives half steps, MultiColor
  colours the items red to green, ReadOnly shows a value without letting it change.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Rating, Daisy.FMX.Control;

type
  TDaisyFmxRating = class(TDaisyControl)
  strict private
    FValue: Double;
    FCount: Integer;
    FShape: TDaisyRatingShape;
    FAllowHalf: Boolean;
    FAllowClear: Boolean;
    FReadOnly: Boolean;
    FMultiColor: Boolean;
    FSpacing: Integer;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetValue(const AValue: Double);
    procedure SetCount(const AValue: Integer);
    procedure SetShape(const AValue: TDaisyRatingShape);
    procedure SetAllowHalf(const AValue: Boolean);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetMultiColor(const AValue: Boolean);
    procedure SetSpacing(const AValue: Integer);
    procedure SetAutoFit(const AValue: Boolean);
    function ItemSize: Single;
    function Gap: Single;
    function NormalizedValue(AValue: Double): Double;
    procedure UpdateSize;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    // 0..Count; whole numbers unless AllowHalf is set
    property Value: Double read FValue write SetValue;
    property Count: Integer read FCount write SetCount default 5;
    property Shape: TDaisyRatingShape read FShape write SetShape default rsStar2;
    property AllowHalf: Boolean read FAllowHalf write SetAllowHalf default False;
    // Clicking the current value sets it back to 0
    property AllowClear: Boolean read FAllowClear write FAllowClear default False;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    // Colours the items red to green instead of using Variant
    property MultiColor: Boolean read FMultiColor write SetMultiColor default False;
    // Gap between items; -1 uses the DaisyUI default for the shape
    property Spacing: Integer read FSpacing write SetSpacing default -1;
    // The size follows SizeKind and Count; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CItemSizes: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);

{ TDaisyFmxRating }

constructor TDaisyFmxRating.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCount := 5;
  FShape := rsStar2;
  FSpacing := -1;
  FAutoFit := True;
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Position.X, Position.Y, 120, 24);
  UpdateSize;
end;

function TDaisyFmxRating.IsInteractive: Boolean;
begin
  Result := not FReadOnly;
end;

function TDaisyFmxRating.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyFmxRating.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRating.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRating.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxRating.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxRating.ItemSize: Single;
begin
  Result := CItemSizes[SizeKind];
end;

function TDaisyFmxRating.Gap: Single;
begin
  if FSpacing >= 0 then
    Result := FSpacing
  else if FShape = rsHeart then
    Result := 4
  else
    Result := 0;
end;

function TDaisyFmxRating.NormalizedValue(AValue: Double): Double;
begin
  Result := EnsureRange(AValue, 0, FCount);
  if FAllowHalf then
    Result := Round(Result * 2) / 2
  else
    Result := Round(Result);
end;

procedure TDaisyFmxRating.UpdateSize;
var
  LW, LH: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LW := FCount * ItemSize + System.Math.Max(0, FCount - 1) * Gap;
  LH := ItemSize;
  if SameValue(Width, LW) and SameValue(Height, LH) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LW, LH);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxRating.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxRating.Loaded;
begin
  inherited;
  FValue := NormalizedValue(FValue);
  if FReadOnly then
    Cursor := crDefault
  else
    Cursor := crHandPoint;
  UpdateSize;
end;

procedure TDaisyFmxRating.SetValue(const AValue: Double);
var
  LValue: Double;
begin
  if csLoading in ComponentState then
    LValue := AValue
  else
    LValue := NormalizedValue(AValue);
  if FValue <> LValue then
  begin
    FValue := LValue;
    Repaint;
    if not (csLoading in ComponentState) and Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TDaisyFmxRating.SetCount(const AValue: Integer);
begin
  if (FCount <> AValue) and (AValue >= 1) then
  begin
    FCount := AValue;
    if not (csLoading in ComponentState) then
      FValue := NormalizedValue(FValue);
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxRating.SetShape(const AValue: TDaisyRatingShape);
begin
  if FShape <> AValue then
  begin
    FShape := AValue;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxRating.SetAllowHalf(const AValue: Boolean);
begin
  if FAllowHalf <> AValue then
  begin
    FAllowHalf := AValue;
    if not (csLoading in ComponentState) then
      FValue := NormalizedValue(FValue);
    Repaint;
  end;
end;

procedure TDaisyFmxRating.SetReadOnly(const AValue: Boolean);
begin
  if FReadOnly <> AValue then
  begin
    FReadOnly := AValue;
    if FReadOnly then
      Cursor := crDefault
    else
      Cursor := crHandPoint;
    Repaint;
  end;
end;

procedure TDaisyFmxRating.SetMultiColor(const AValue: Boolean);
begin
  if FMultiColor <> AValue then
  begin
    FMultiColor := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxRating.SetSpacing(const AValue: Integer);
begin
  if (FSpacing <> AValue) and (AValue >= -1) then
  begin
    FSpacing := AValue;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxRating.SetAutoFit(const AValue: Boolean);
begin
  if FAutoFit <> AValue then
  begin
    FAutoFit := AValue;
    UpdateSize;
  end;
end;

procedure TDaisyFmxRating.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  LStep: Double;
  LHandled: Boolean;
begin
  LHandled := Enabled and not FReadOnly;
  if LHandled then
  begin
    if FAllowHalf then
      LStep := 0.5
    else
      LStep := 1;
    case Key of
      vkLeft, vkDown: SetValue(FValue - LStep);
      vkRight, vkUp: SetValue(FValue + LStep);
      vkHome, vkDelete: SetValue(0);
      vkEnd: SetValue(FCount);
    else
      LHandled := False;
    end;
  end;
  if LHandled then
  begin
    Key := 0;
    KeyChar := #0;
  end
  else
    inherited KeyDown(Key, KeyChar, Shift);
end;

procedure TDaisyFmxRating.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LValue: Double;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> TMouseButton.mbLeft) or FReadOnly or not Enabled
    or (csDesigning in ComponentState) or not LocalRect.Contains(PointF(X, Y)) then
    Exit;
  SetFocus;
  LValue := DaisyRatingValueAt(X, ItemSize, Gap, FCount, FAllowHalf);
  if FAllowClear and (LValue = FValue) then
    LValue := 0;
  SetValue(LValue);
end;

procedure TDaisyFmxRating.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LShape: TArray<TPointF>;
  LPath: TPathData;
  LTint, LBase: TAlphaColor;
  LItem, LGapPx, LFill, LFade: Single;
  LBox: TRectF;
  LState: TCanvasSaveState;
  I, J: Integer;

  procedure FillShape(AColor: TAlphaColor);
  begin
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := AColor;
    Canvas.FillPath(LPath, AbsoluteOpacity);
  end;

begin
  LItem := ItemSize;
  LGapPx := Gap;
  if Variant = dvDefault then
    LBase := Theme.BaseContent
  else
    LBase := DaisyVariantPalette(Theme, Variant).Fill;
  LFade := 1;
  if not Enabled then
    LFade := 0.4;

  LPath := TPathData.Create;
  try
    for I := 0 to FCount - 1 do
    begin
      LBox := RectF(I * (LItem + LGapPx), 0, I * (LItem + LGapPx) + LItem, LItem);
      LShape := DaisyShapePoints(FShape, LBox);
      LPath.Clear;
      LPath.MoveTo(LShape[0]);
      for J := 1 to High(LShape) do
        LPath.LineTo(LShape[J]);
      LPath.ClosePath;
      if FMultiColor then
        LTint := DaisyRatingRainbow(I, FCount)
      else
        LTint := LBase;

      FillShape(DaisyWithAlpha(LTint, 0.2 * LFade));
      LFill := EnsureRange(FValue - I, 0, 1);
      if LFill >= 1 then
        FillShape(DaisyWithAlpha(LTint, LFade))
      else if LFill > 0 then
      begin
        LState := Canvas.SaveState;
        try
          Canvas.IntersectClipRect(RectF(LBox.Left, LBox.Top, LBox.Left + LBox.Width * LFill,
            LBox.Bottom));
          FillShape(DaisyWithAlpha(LTint, LFade));
        finally
          Canvas.RestoreState(LState);
        end;
      end;
    end;
  finally
    LPath.Free;
  end;
  if IsFocused and not FReadOnly then
    StrokeRound(RectF(0, 0, Width, Height), 4, DaisyWithAlpha(Theme.BaseContent, 0.45), 1, False);
end;

end.
