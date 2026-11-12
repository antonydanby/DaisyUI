unit Daisy.FMX.Accordion;

{
  TDaisyFmxAccordion - a stack of collapsible sections (see daisyui.com/components/accordion).
  Each section has a Title and Content; Icon selects an arrow or a + / - marker.
  Joined = True merges the sections into one block with shared borders (the
  "accordion and join together" look). AllowMultiple = False keeps a single
  section open at a time. The control sizes its own height to fit the sections.
}

interface

uses
  System.Classes, System.Types, System.UITypes, FMX.Types, FMX.Controls,
  Daisy.Theme, Daisy.Items, Daisy.FMX.Control;

type
  TDaisyFmxAccordion = class(TDaisyControl)
  strict private
    FItems: TDaisyAccordionItems;
    FIcon: TDaisyAccordionIcon;
    FJoined: Boolean;
    FAllowMultiple: Boolean;
    FHotIndex: Integer;
    FFocusIndex: Integer;
    FKeyNav: Boolean;
    FUpdating: Boolean;
    FOnToggle: TDaisyAccordionEvent;
    procedure SetItems(const Value: TDaisyAccordionItems);
    procedure SetIcon(const Value: TDaisyAccordionIcon);
    procedure SetJoined(const Value: Boolean);
    procedure SetAllowMultiple(const Value: Boolean);
    procedure SetHotIndex(const Value: Integer);
    function Gap: Single;
    function HeaderHeight: Single;
    function ContentHeight(AIndex: Integer): Single;
    function SectionHeight(AIndex: Integer): Single;
    function TotalHeight: Single;
    function SectionRect(AIndex: Integer): TRectF;
    function HeaderRect(AIndex: Integer): TRectF;
    function HitHeader(const APoint: TPointF): Integer;
    procedure UpdateHeight;
    procedure KeepSingleOpen;
    procedure ItemsChanged(Sender: TObject);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure SizeChanged; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DoMouseLeave; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ToggleItem(AIndex: Integer);
  published
    property Items: TDaisyAccordionItems read FItems write SetItems;
    property Icon: TDaisyAccordionIcon read FIcon write SetIcon default aiArrow;
    property Joined: Boolean read FJoined write SetJoined default False;
    // False = opening a section closes the others
    property AllowMultiple: Boolean read FAllowMultiple write SetAllowMultiple default False;
    property OnToggle: TDaisyAccordionEvent read FOnToggle write FOnToggle;
  end;

implementation

uses
  System.SysUtils, System.Math, FMX.Graphics;

const
  NoHot = -1;
  ContentPad = 16;

{ TDaisyFmxAccordion }

constructor TDaisyFmxAccordion.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyAccordionItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FIcon := aiArrow;
  FHotIndex := NoHot;
  CanFocus := True;
  TabStop := True;
  SetBounds(Position.X, Position.Y, 320, 52);
end;

destructor TDaisyFmxAccordion.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TDaisyFmxAccordion.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxAccordion.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxAccordion.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
var
  LTheme: TDaisyTheme;
begin
  LTheme := Theme;
  Result := DaisyResolveColors(LTheme, Variant, dsSolid, dstNormal);
  if Variant = dvDefault then
  begin
    Result.Background := LTheme.Base100;
    Result.Border := LTheme.BorderColor;
    Result.Text := LTheme.BaseContent;
  end;
end;

{ Layout }

function TDaisyFmxAccordion.Gap: Single;
begin
  if FJoined then
    Result := 0
  else
    Result := 8;
end;

function TDaisyFmxAccordion.HeaderHeight: Single;
begin
  Result := DaisyFieldHeight(SizeKind) + 12;
end;

function TDaisyFmxAccordion.ContentHeight(AIndex: Integer): Single;
begin
  Result := 0;
  if FItems[AIndex].Content = '' then
    Exit;
  Result := MeasureTextHeight(FItems[AIndex].Content, Width - 2 * ContentPad,
    DaisyFontSize(SizeKind), False) + ContentPad;
end;

function TDaisyFmxAccordion.SectionHeight(AIndex: Integer): Single;
begin
  Result := HeaderHeight;
  if FItems[AIndex].Expanded then
    Result := Result + ContentHeight(AIndex);
end;

function TDaisyFmxAccordion.TotalHeight: Single;
var
  I: Integer;
begin
  if FItems.Count = 0 then
    Exit(HeaderHeight);
  Result := (FItems.Count - 1) * Gap;
  for I := 0 to FItems.Count - 1 do
    Result := Result + SectionHeight(I);
end;

function TDaisyFmxAccordion.SectionRect(AIndex: Integer): TRectF;
var
  I: Integer;
  LTop: Single;
begin
  LTop := 0;
  for I := 0 to AIndex - 1 do
    LTop := LTop + SectionHeight(I) + Gap;
  Result := RectF(0, LTop, Width, LTop + SectionHeight(AIndex));
end;

function TDaisyFmxAccordion.HeaderRect(AIndex: Integer): TRectF;
begin
  Result := SectionRect(AIndex);
  Result.Bottom := Result.Top + HeaderHeight;
end;

function TDaisyFmxAccordion.HitHeader(const APoint: TPointF): Integer;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    if HeaderRect(I).Contains(APoint) then
      Exit(I);
  Result := NoHot;
end;

procedure TDaisyFmxAccordion.UpdateHeight;
var
  LHeight: Single;
begin
  if FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := Ceil(TotalHeight);
  if not SameValue(LHeight, Height) then
  begin
    FUpdating := True;
    try
      SetBounds(Position.X, Position.Y, Width, LHeight);
    finally
      FUpdating := False;
    end;
  end;
end;

procedure TDaisyFmxAccordion.Loaded;
begin
  inherited;
  KeepSingleOpen;
  UpdateHeight;
end;

procedure TDaisyFmxAccordion.Resize;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyFmxAccordion.SizeChanged;
begin
  UpdateHeight;
end;

{ Properties }

procedure TDaisyFmxAccordion.SetItems(const Value: TDaisyAccordionItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxAccordion.SetIcon(const Value: TDaisyAccordionIcon);
begin
  if FIcon <> Value then
  begin
    FIcon := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxAccordion.SetJoined(const Value: Boolean);
begin
  if FJoined <> Value then
  begin
    FJoined := Value;
    UpdateHeight;
    Repaint;
  end;
end;

procedure TDaisyFmxAccordion.SetAllowMultiple(const Value: Boolean);
begin
  if FAllowMultiple <> Value then
  begin
    FAllowMultiple := Value;
    KeepSingleOpen;
  end;
end;

procedure TDaisyFmxAccordion.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxAccordion.KeepSingleOpen;
var
  I: Integer;
  LFound: Boolean;
begin
  if FAllowMultiple or (FItems.Count = 0) then
    Exit;
  LFound := False;
  FItems.BeginUpdate;
  try
    for I := 0 to FItems.Count - 1 do
      if FItems[I].Expanded then
      begin
        if LFound then
          FItems[I].Expanded := False;
        LFound := True;
      end;
  finally
    FItems.EndUpdate;
  end;
end;

procedure TDaisyFmxAccordion.ItemsChanged(Sender: TObject);
begin
  if FFocusIndex >= FItems.Count then
    FFocusIndex := Max(0, FItems.Count - 1);
  UpdateHeight;
  Repaint;
end;

procedure TDaisyFmxAccordion.ToggleItem(AIndex: Integer);
var
  I: Integer;
  LOpen: Boolean;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) or not FItems[AIndex].Enabled then
    Exit;
  LOpen := not FItems[AIndex].Expanded;
  FItems.BeginUpdate;
  try
    if LOpen and not FAllowMultiple then
      for I := 0 to FItems.Count - 1 do
        FItems[I].Expanded := False;
    FItems[AIndex].Expanded := LOpen;
  finally
    FItems.EndUpdate;
  end;
  if Assigned(FOnToggle) then
    FOnToggle(Self, AIndex);
end;

{ Input }

procedure TDaisyFmxAccordion.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FKeyNav := False;
  inherited;
end;

procedure TDaisyFmxAccordion.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LHit: Integer;
begin
  inherited;
  LHit := HitHeader(PointF(X, Y));
  if (LHit >= 0) and not FItems[LHit].Enabled then
    LHit := NoHot;
  SetHotIndex(LHit);
  if LHit >= 0 then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TDaisyFmxAccordion.DoMouseLeave;
begin
  inherited;
  SetHotIndex(NoHot);
end;

procedure TDaisyFmxAccordion.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LHit: Integer;
begin
  inherited;
  if Button <> TMouseButton.mbLeft then
    Exit;
  LHit := HitHeader(PointF(X, Y));
  if LHit >= 0 then
  begin
    FFocusIndex := LHit;
    ToggleItem(LHit);
  end;
end;

procedure TDaisyFmxAccordion.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  inherited KeyDown(Key, KeyChar, Shift);
  if FItems.Count = 0 then
    Exit;
  if Key = vkDown then
    FFocusIndex := Min(FItems.Count - 1, FFocusIndex + 1)
  else if Key = vkUp then
    FFocusIndex := Max(0, FFocusIndex - 1)
  else if (Key = vkReturn) or (KeyChar = ' ') then
    ToggleItem(FFocusIndex)
  else
    Exit;
  Key := 0;
  KeyChar := #0;
  FKeyNav := True;
  Repaint;
end;

procedure TDaisyFmxAccordion.DoExit;
begin
  inherited;
  FKeyNav := False;
  Repaint;
end;

{ Painting }

procedure TDaisyFmxAccordion.Paint;
var
  LColors: TDaisyColors;
  LRadius, LBorder, LCx, LCy, LHalf, LIconW, LRight: Single;
  LRect, LHead, LSection: TRectF;
  LTextColor: TAlphaColor;
  I: Integer;
  LOpen: Boolean;

  procedure FillBlock(const ARect: TRectF);
  begin
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := LColors.Border;
    Canvas.FillRect(ARect, LRadius, LRadius, AllCorners, AbsoluteOpacity);
    LRect := ARect;
    LRect.Inflate(-LBorder, -LBorder);
    Canvas.Fill.Color := LColors.Background;
    Canvas.FillRect(LRect, Max(0, LRadius - LBorder), Max(0, LRadius - LBorder), AllCorners, AbsoluteOpacity);
  end;

  procedure Line(const AFrom, ATo: TPointF);
  begin
    Canvas.DrawLine(AFrom, ATo, AbsoluteOpacity);
  end;

begin
  ApplyRTLMatrix;
  LColors := ResolveColors;
  LRadius := ResolvedCornerRadius;
  LBorder := Max(1, Theme.BorderWidth);

  if FItems.Count = 0 then
    FillBlock(RectF(0, 0, Width, Height))
  else if FJoined then
  begin
    FillBlock(RectF(0, 0, Width, Height));
    Canvas.Fill.Color := LColors.Border;
    for I := 1 to FItems.Count - 1 do
    begin
      LSection := SectionRect(I);
      Canvas.FillRect(RectF(LBorder, LSection.Top, Width - LBorder, LSection.Top + LBorder), 0, 0, [], AbsoluteOpacity);
    end;
  end
  else
    for I := 0 to FItems.Count - 1 do
      FillBlock(SectionRect(I));

  // Keyboard focus ring around the header
  if IsFocused and FKeyNav and (FFocusIndex >= 0) and (FFocusIndex < FItems.Count) then
  begin
    LHead := HeaderRect(FFocusIndex);
    LHead.Inflate(-3, -3);
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
    Canvas.Stroke.Color := DaisyWithAlpha(LColors.Text, 0.5);
    Canvas.Stroke.Thickness := 2;
    Canvas.DrawRect(LHead, Max(0, LRadius - 2), Max(0, LRadius - 2), AllCorners, AbsoluteOpacity);
  end;

  LIconW := 0;
  if FIcon <> aiNone then
    LIconW := 24;

  for I := 0 to FItems.Count - 1 do
  begin
    LTextColor := LColors.Text;
    if not FItems[I].Enabled then
      LTextColor := DaisyWithAlpha(LTextColor, 0.4);
    LHead := HeaderRect(I);
    LOpen := FItems[I].Expanded;

    if FIcon <> aiNone then
    begin
      LCx := LHead.Right - ContentPad - 6;
      LCy := (LHead.Top + LHead.Bottom) / 2;
      LHalf := 5;
      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Dash := TStrokeDash.Solid;
      Canvas.Stroke.Cap := TStrokeCap.Round;
      Canvas.Stroke.Join := TStrokeJoin.Round;
      Canvas.Stroke.Color := LTextColor;
      Canvas.Stroke.Thickness := 2;
      if FIcon = aiArrow then
      begin
        // chevron pointing down when closed, up when open
        if LOpen then
        begin
          Line(PointF(LCx - LHalf, LCy + LHalf / 2), PointF(LCx, LCy - LHalf / 2));
          Line(PointF(LCx, LCy - LHalf / 2), PointF(LCx + LHalf, LCy + LHalf / 2));
        end
        else
        begin
          Line(PointF(LCx - LHalf, LCy - LHalf / 2), PointF(LCx, LCy + LHalf / 2));
          Line(PointF(LCx, LCy + LHalf / 2), PointF(LCx + LHalf, LCy - LHalf / 2));
        end;
      end
      else
      begin
        Line(PointF(LCx - LHalf, LCy), PointF(LCx + LHalf, LCy));
        if not LOpen then
          Line(PointF(LCx, LCy - LHalf), PointF(LCx, LCy + LHalf));
      end;
    end;

    LRight := Max(LHead.Left + ContentPad, LHead.Right - ContentPad - LIconW);
    DrawText(FItems[I].Title, RectF(LHead.Left + ContentPad, LHead.Top, LRight, LHead.Bottom),
      LTextColor, DaisyFontSize(SizeKind), True, TTextAlign.Leading, TTextAlign.Center, False);
    if LOpen and (FItems[I].Content <> '') then
    begin
      LSection := SectionRect(I);
      DrawText(FItems[I].Content, RectF(LSection.Left + ContentPad, LHead.Bottom,
        LSection.Right - ContentPad, LSection.Bottom), DaisyWithAlpha(LTextColor, 0.8),
        DaisyFontSize(SizeKind), False, TTextAlign.Leading, TTextAlign.Leading, True);
    end;
  end;
end;

end.
