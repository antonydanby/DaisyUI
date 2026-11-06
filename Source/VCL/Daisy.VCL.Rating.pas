unit Daisy.VCL.Rating;

{
  TDaisyRating - the DaisyUI "rating": a row of stars (or hearts) the user clicks to pick
  a value. Shape picks star, plump star or heart, AllowHalf gives half steps, MultiColor
  colours the items red to green, ReadOnly shows a value without letting it change.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Daisy.Theme, Daisy.Rating, Daisy.VCL.Control;

type
  TDaisyRating = class(TDaisyControl)
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
    procedure SetValue(const Value: Double);
    procedure SetCount(const Value: Integer);
    procedure SetShape(const Value: TDaisyRatingShape);
    procedure SetAllowHalf(const Value: Boolean);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetMultiColor(const Value: Boolean);
    procedure SetSpacing(const Value: Integer);
    procedure SetAutoFit(const Value: Boolean);
    function ItemSize: Integer;
    function Gap: Integer;
    function NormalizedValue(AValue: Double): Double;
    procedure UpdateSize;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

{ TDaisyRating }

constructor TDaisyRating.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCount := 5;
  FShape := rsStar2;
  FSpacing := -1;
  FAutoFit := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Left, Top, 120, 24);
  UpdateSize;
end;

function TDaisyRating.IsInteractive: Boolean;
begin
  Result := not FReadOnly;
end;

function TDaisyRating.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyRating.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyRating.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyRating.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyRating.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyRating.ItemSize: Integer;
begin
  Result := ScaleValue(CItemSizes[SizeKind]);
end;

function TDaisyRating.Gap: Integer;
begin
  if FSpacing >= 0 then
    Result := ScaleValue(FSpacing)
  else if FShape = rsHeart then
    Result := ScaleValue(4)
  else
    Result := 0;
end;

function TDaisyRating.NormalizedValue(AValue: Double): Double;
begin
  Result := EnsureRange(AValue, 0, FCount);
  if FAllowHalf then
    Result := Round(Result * 2) / 2
  else
    Result := Round(Result);
end;

procedure TDaisyRating.UpdateSize;
var
  LW, LH: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LW := FCount * ItemSize + Max(0, FCount - 1) * Gap;
  LH := ItemSize;
  if (Width = LW) and (Height = LH) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, LW, LH);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyRating.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyRating.Loaded;
begin
  inherited;
  FValue := NormalizedValue(FValue);
  Cursor := IfThen(FReadOnly, crDefault, crHandPoint);
  UpdateSize;
end;

procedure TDaisyRating.SetValue(const Value: Double);
var
  LValue: Double;
begin
  if csLoading in ComponentState then
    LValue := Value
  else
    LValue := NormalizedValue(Value);
  if FValue <> LValue then
  begin
    FValue := LValue;
    Invalidate;
    if not (csLoading in ComponentState) and Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TDaisyRating.SetCount(const Value: Integer);
begin
  if (FCount <> Value) and (Value >= 1) then
  begin
    FCount := Value;
    if not (csLoading in ComponentState) then
      FValue := NormalizedValue(FValue);
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyRating.SetShape(const Value: TDaisyRatingShape);
begin
  if FShape <> Value then
  begin
    FShape := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyRating.SetAllowHalf(const Value: Boolean);
begin
  if FAllowHalf <> Value then
  begin
    FAllowHalf := Value;
    if not (csLoading in ComponentState) then
      FValue := NormalizedValue(FValue);
    Invalidate;
  end;
end;

procedure TDaisyRating.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    if FReadOnly then
      Cursor := crDefault
    else
      Cursor := crHandPoint;
    Invalidate;
  end;
end;

procedure TDaisyRating.SetMultiColor(const Value: Boolean);
begin
  if FMultiColor <> Value then
  begin
    FMultiColor := Value;
    Invalidate;
  end;
end;

procedure TDaisyRating.SetSpacing(const Value: Integer);
begin
  if (FSpacing <> Value) and (Value >= -1) then
  begin
    FSpacing := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyRating.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

procedure TDaisyRating.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TDaisyRating.KeyDown(var Key: Word; Shift: TShiftState);
var
  LStep: Double;
begin
  if FReadOnly or not Enabled then
  begin
    inherited KeyDown(Key, Shift);
    Exit;
  end;
  if FAllowHalf then
    LStep := 0.5
  else
    LStep := 1;
  case Key of
    VK_LEFT, VK_DOWN: SetValue(FValue - LStep);
    VK_RIGHT, VK_UP: SetValue(FValue + LStep);
    VK_HOME: SetValue(0);
    VK_END: SetValue(FCount);
    VK_DELETE: SetValue(0);
  else
    inherited KeyDown(Key, Shift);
    Exit;
  end;
  Key := 0;
end;

procedure TDaisyRating.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LValue: Double;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or FReadOnly or not Enabled or (csDesigning in ComponentState)
    or not PtInRect(ClientRect, Point(X, Y)) then
    Exit;
  if CanFocus and not Focused then
    SetFocus;
  LValue := DaisyRatingValueAt(X, ItemSize, Gap, FCount, FAllowHalf);
  if FAllowClear and (LValue = FValue) then
    LValue := 0;
  SetValue(LValue);
end;

procedure TDaisyRating.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LBrush: TGPSolidBrush;
  LPoints: array of TGPPointF;
  LShape: TArray<TPointF>;
  LTint, LBase: TAlphaColor;
  LPalette: TDaisyPalette;
  LItem, LGapPx, I, J: Integer;
  LBox: TRectF;
  LFill, LFade: Single;
  LClip: Boolean;
begin
  LItem := ItemSize;
  LGapPx := Gap;
  if Variant = dvDefault then
    LBase := Theme.BaseContent
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    LBase := LPalette.Fill;
  end;
  LFade := 1;
  if not Enabled then
    LFade := 0.4;

  LGraphics := NewGraphics;
  try
    for I := 0 to FCount - 1 do
    begin
      LBox := RectF(I * (LItem + LGapPx), 0, I * (LItem + LGapPx) + LItem, LItem);
      LShape := DaisyShapePoints(FShape, LBox);
      SetLength(LPoints, Length(LShape));
      for J := 0 to High(LShape) do
        LPoints[J] := MakePoint(LShape[J].X, LShape[J].Y);
      if FMultiColor then
        LTint := DaisyRatingRainbow(I, FCount)
      else
        LTint := LBase;

      LBrush := TGPSolidBrush.Create(DaisyWithAlpha(LTint, 0.2 * LFade));
      try
        LGraphics.FillPolygon(LBrush, PGPPointF(@LPoints[0]), Length(LPoints));
      finally
        LBrush.Free;
      end;

      LFill := EnsureRange(FValue - I, 0, 1);
      if LFill > 0 then
      begin
        LClip := LFill < 1;
        if LClip then
          LGraphics.SetClip(MakeRect(LBox.Left, LBox.Top, LBox.Width * LFill, LBox.Height));
        LBrush := TGPSolidBrush.Create(DaisyWithAlpha(LTint, LFade));
        try
          LGraphics.FillPolygon(LBrush, PGPPointF(@LPoints[0]), Length(LPoints));
        finally
          LBrush.Free;
        end;
        if LClip then
          LGraphics.ResetClip;
      end;
    end;
    if Focused and not FReadOnly then
      StrokeRoundRect(LGraphics, RectF(0, 0, Width, Height), ScaleValue(4),
        DaisyWithAlpha(Theme.BaseContent, 0.45), ScaleValue(1), False);
  finally
    LGraphics.Free;
  end;
end;

end.
