unit Daisy.FMX.Stat;

{
  TDaisyFmxStat - the DaisyUI "stat": one or more figures, each with a title, a large
  value, a description, an optional figure (emoji or SVG) and an optional small
  button. Items run horizontally or vertically, optionally centred.
  Mirrors Daisy.VCL.Stat so both frameworks share one public API.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, Daisy.Theme, Daisy.Widgets, Daisy.FMX.Control;

type
  TDaisyFmxStat = class(TDaisyControl)
  strict private
    type
      TStatCell = record
        Cell, Title, Value, Desc, Figure, Action: TRectF;
        ActionWidth: Single;
      end;
    var
    FItems: TDaisyStatItems;
    FDirection: TDaisyStatDirection;
    FCentered: Boolean;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    FHotAction: Integer;
    FOnActionClick: TDaisyStatActionEvent;
    procedure SetItems(const Value: TDaisyStatItems);
    procedure SetDirection(const Value: TDaisyStatDirection);
    procedure SetCentered(const Value: Boolean);
    procedure SetAutoFit(const Value: Boolean);
    procedure ItemsChanged(Sender: TObject);
    function BuildLayout(out ABody: TSizeF): TArray<TStatCell>;
    function ActionAt(X, Y: Single): Integer;
    procedure UpdateSize;
    procedure SetHotAction(AIndex: Integer);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DoMouseLeave; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TDaisyStatItems read FItems write SetItems;
    property Direction: TDaisyStatDirection read FDirection write SetDirection default sdHorizontal;
    property Centered: Boolean read FCentered write SetCentered default False;
    // The size follows the content; when off the items share the available size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property OnActionClick: TDaisyStatActionEvent read FOnActionClick write FOnActionClick;
  end;

implementation

const
  CPadX = 24;
  CPadY = 16;
  CGap = 16;
  CTitleSize = 14;
  CValueSize = 30;
  CDescSize = 12;
  CTitleLine = 20;
  CValueLine = 36;
  CDescLine = 16;
  CFigure = 32;

{ TDaisyFmxStat }

constructor TDaisyFmxStat.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  FHotAction := -1;
  FItems := TDaisyStatItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FItems.Add;
  SetBounds(Position.X, Position.Y, 200, 120);
  UpdateSize;
end;

destructor TDaisyFmxStat.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TDaisyFmxStat.SetItems(const Value: TDaisyStatItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxStat.SetDirection(const Value: TDaisyStatDirection);
begin
  if FDirection <> Value then
  begin
    FDirection := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxStat.SetCentered(const Value: Boolean);
begin
  if FCentered <> Value then
  begin
    FCentered := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxStat.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxStat.ItemsChanged(Sender: TObject);
begin
  UpdateSize;
  Repaint;
end;

function TDaisyFmxStat.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxStat.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxStat.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxStat.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
var
  LPalette: TDaisyPalette;
begin
  Result := Default(TDaisyColors);
  if Variant = dvDefault then
  begin
    Result.Background := Theme.Base100;
    Result.Text := Theme.BaseContent;
    Result.Border := Theme.BorderColor;
  end
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    Result.Background := LPalette.Fill;
    Result.Text := LPalette.Content;
  end;
end;

procedure TDaisyFmxStat.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxStat.Loaded;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyFmxStat.Resize;
begin
  inherited;
  if not FAutoFit then
    Repaint;
end;

function TDaisyFmxStat.BuildLayout(out ABody: TSizeF): TArray<TStatCell>;
var
  LBody: TRectF;
  I: Integer;
  LTextW, LContentW, LRowsH, LW, LH, LX, LY, LExtra, LTextL, LTextR, LFigTop: Single;
  LItem: TDaisyStatItem;
  LWidths, LHeights: array of Single;
  LCell: TStatCell;
  LSmall: Integer;
  LBtnH: Single;
begin
  LBody := BodyRect;
  SetLength(Result, FItems.Count);
  SetLength(LWidths, FItems.Count);
  SetLength(LHeights, FItems.Count);
  ABody := TSizeF.Create(0, 0);
  LSmall := DaisyFontSize(dzSM);
  LBtnH := DaisyFieldHeight(dzSM);

  for I := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[I];
    LTextW := Max(MeasureTextWidth(LItem.Title, CTitleSize, False),
      Max(MeasureTextWidth(LItem.Value, CValueSize, True), MeasureTextWidth(LItem.Description, CDescSize, False)));
    Result[I].ActionWidth := 0;
    if LItem.ActionCaption <> '' then
    begin
      Result[I].ActionWidth := MeasureTextWidth(LItem.ActionCaption, LSmall, False) +
        2 * DaisyFieldPaddingX(dzSM) + 2;
      LTextW := Max(LTextW, Result[I].ActionWidth);
    end;
    LTextW := LTextW + 4;
    LContentW := LTextW;
    if not LItem.Icon.IsEmpty then
      LContentW := LContentW + CGap + CFigure;
    LWidths[I] := LContentW + 2 * CPadX;
    LRowsH := CTitleLine + CValueLine;
    if LItem.Description <> '' then
      LRowsH := LRowsH + CDescLine;
    if LItem.ActionCaption <> '' then
      LRowsH := LRowsH + CGap + LBtnH;
    LHeights[I] := LRowsH + 2 * CPadY;
    if FDirection = sdHorizontal then
    begin
      ABody.cx := ABody.cx + LWidths[I];
      ABody.cy := Max(ABody.cy, LHeights[I]);
    end
    else
    begin
      ABody.cx := Max(ABody.cx, LWidths[I]);
      ABody.cy := ABody.cy + LHeights[I];
    end;
  end;

  if not FAutoFit then
  begin
    LExtra := 0;
    if FItems.Count > 0 then
      if FDirection = sdHorizontal then
        LExtra := Max(0, LBody.Width - ABody.cx) / FItems.Count
      else
        LExtra := Max(0, LBody.Height - ABody.cy) / FItems.Count;
    for I := 0 to FItems.Count - 1 do
      if FDirection = sdHorizontal then
        LWidths[I] := LWidths[I] + LExtra
      else
        LHeights[I] := LHeights[I] + LExtra;
    ABody := TSizeF.Create(Max(LBody.Width, 0), Max(LBody.Height, 0));
    if FDirection = sdHorizontal then
    begin
      ABody.cx := 0;
      for I := 0 to High(LWidths) do
        ABody.cx := ABody.cx + LWidths[I];
      ABody.cx := Max(ABody.cx, LBody.Width);
    end;
  end;

  LX := LBody.Left;
  LY := LBody.Top;
  for I := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[I];
    LCell := Result[I];
    if FDirection = sdHorizontal then
    begin
      LW := LWidths[I];
      LH := ABody.cy;
      LCell.Cell := RectF(LX, LBody.Top, LX + LW, LBody.Top + LH);
      LX := LX + LW;
    end
    else
    begin
      LW := ABody.cx;
      LH := LHeights[I];
      LCell.Cell := RectF(LBody.Left, LY, LBody.Left + LW, LY + LH);
      LY := LY + LH;
    end;
    LTextL := LCell.Cell.Left + CPadX;
    LTextR := LCell.Cell.Right - CPadX;
    LRowsH := CTitleLine + CValueLine;
    if LItem.Description <> '' then
      LRowsH := LRowsH + CDescLine;
    if not LItem.Icon.IsEmpty then
    begin
      LFigTop := LCell.Cell.Top + CPadY + (LRowsH - CFigure) / 2;
      LCell.Figure := RectF(LTextR - CFigure, LFigTop, LTextR, LFigTop + CFigure);
      LTextR := LCell.Figure.Left - CGap;
    end;
    LCell.Title := RectF(LTextL, LCell.Cell.Top + CPadY, LTextR, LCell.Cell.Top + CPadY + CTitleLine);
    LCell.Value := RectF(LTextL, LCell.Title.Bottom, LTextR, LCell.Title.Bottom + CValueLine);
    LCell.Desc := RectF(LTextL, LCell.Value.Bottom, LTextR, LCell.Value.Bottom);
    if LItem.Description <> '' then
      LCell.Desc.Bottom := LCell.Desc.Top + CDescLine;
    if LItem.ActionCaption <> '' then
    begin
      if FCentered then
        LCell.Action.Left := LTextL + (LTextR - LTextL - LCell.ActionWidth) / 2
      else
        LCell.Action.Left := LTextL;
      LCell.Action.Right := LCell.Action.Left + LCell.ActionWidth;
      LCell.Action.Top := LCell.Desc.Bottom + CGap;
      LCell.Action.Bottom := LCell.Action.Top + LBtnH;
    end;
    Result[I] := LCell;
  end;
end;

procedure TDaisyFmxStat.UpdateSize;
var
  LSize: TSizeF;
  LMargin: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  BuildLayout(LSize);
  LMargin := 2 * ResolvedShadowSize;
  if (LSize.cx <= 0) or (SameValue(LSize.cx + LMargin, Width) and SameValue(LSize.cy + LMargin, Height)) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, LSize.cx + LMargin, LSize.cy + LMargin);
  finally
    FUpdating := False;
  end;
end;

function TDaisyFmxStat.ActionAt(X, Y: Single): Integer;
var
  LCells: TArray<TStatCell>;
  LSize: TSizeF;
  I: Integer;
begin
  Result := -1;
  LCells := BuildLayout(LSize);
  for I := 0 to High(LCells) do
    if (LCells[I].Action.Width > 0) and LCells[I].Action.Contains(PointF(X, Y)) then
      Exit(I);
end;

procedure TDaisyFmxStat.SetHotAction(AIndex: Integer);
begin
  if FHotAction <> AIndex then
  begin
    FHotAction := AIndex;
    Repaint;
  end;
end;

procedure TDaisyFmxStat.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;
  SetHotAction(ActionAt(X, Y));
  if FHotAction >= 0 then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TDaisyFmxStat.DoMouseLeave;
begin
  inherited;
  SetHotAction(-1);
  Cursor := crDefault;
end;

procedure TDaisyFmxStat.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LIndex: Integer;
begin
  inherited;
  if Button <> TMouseButton.mbLeft then
    Exit;
  LIndex := ActionAt(X, Y);
  if (LIndex >= 0) and Assigned(FOnActionClick) then
    FOnActionClick(Self, LIndex);
end;

procedure TDaisyFmxStat.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LCells: TArray<TStatCell>;
  LSize: TSizeF;
  LItem: TDaisyStatItem;
  LActColors: TDaisyColors;
  LItemText, LItemDim, LFigure: TAlphaColor;
  LRadius: Single;
  I: Integer;
  LCell: TStatCell;
  LCorners: TCorners;
  LHAlign: TTextAlign;
  LBody: TRectF;
begin
  LCells := BuildLayout(LSize);
  LBody := BodyRect;
  LRadius := ResolvedCornerRadius;
  Canvas.Fill.Kind := TBrushKind.Solid;

  for I := 0 to High(LCells) do
  begin
    LItem := FItems[I];
    if LItem.Variant = dvDefault then
      Continue;
    LCell := LCells[I];
    // only the outer ends keep rounded corners
    LCorners := AllCorners;
    if FDirection = sdHorizontal then
    begin
      if I > 0 then
        LCorners := LCorners - [TCorner.TopLeft, TCorner.BottomLeft];
      if I < High(LCells) then
        LCorners := LCorners - [TCorner.TopRight, TCorner.BottomRight];
    end
    else
    begin
      if I > 0 then
        LCorners := LCorners - [TCorner.TopLeft, TCorner.TopRight];
      if I < High(LCells) then
        LCorners := LCorners - [TCorner.BottomLeft, TCorner.BottomRight];
    end;
    Canvas.Fill.Color := DaisyVariantPalette(Theme, LItem.Variant).Fill;
    Canvas.FillRect(LCell.Cell, LRadius, LRadius, LCorners, AbsoluteOpacity);
  end;

  // dashed dividers between items
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := DaisyWithAlpha(Theme.BaseContent, 0.1);
  Canvas.Stroke.Thickness := 1;
  Canvas.Stroke.Dash := TStrokeDash.Dash;
  for I := 1 to High(LCells) do
    if FDirection = sdHorizontal then
      Canvas.DrawLine(PointF(LCells[I].Cell.Left, LBody.Top + CPadY / 2),
        PointF(LCells[I].Cell.Left, LBody.Bottom - CPadY / 2), AbsoluteOpacity)
    else
      Canvas.DrawLine(PointF(LBody.Left + CPadX / 2, LCells[I].Cell.Top),
        PointF(LBody.Right - CPadX / 2, LCells[I].Cell.Top), AbsoluteOpacity);
  Canvas.Stroke.Dash := TStrokeDash.Solid;

  if FCentered then
    LHAlign := TTextAlign.Center
  else
    LHAlign := TTextAlign.Leading;

  for I := 0 to High(LCells) do
  begin
    LItem := FItems[I];
    LCell := LCells[I];
    if LItem.Variant <> dvDefault then
      LItemText := DaisyVariantPalette(Theme, LItem.Variant).Content
    else
      LItemText := AColors.Text;
    if not Enabled then
      LItemText := DaisyWithAlpha(LItemText, 0.5);
    LItemDim := DaisyWithAlpha(LItemText, 0.6);

    DrawText(LItem.Title, LCell.Title, LItemDim, CTitleSize, False, LHAlign, TTextAlign.Center, False);
    DrawText(LItem.Value, LCell.Value, LItemText, CValueSize, True, LHAlign, TTextAlign.Center, False);
    if LItem.Description <> '' then
      DrawText(LItem.Description, LCell.Desc, LItemDim, CDescSize, False, LHAlign, TTextAlign.Center, False);

    if LCell.Figure.Width > 0 then
    begin
      if LItem.FigureVariant <> dvDefault then
        LFigure := DaisyVariantPalette(Theme, LItem.FigureVariant).Fill
      else
        LFigure := LItemText;
      DrawGlyph(LItem.Icon, LCell.Figure, LFigure);
    end;

    if LCell.Action.Width > 0 then
    begin
      if I = FHotAction then
        LActColors := DaisyResolveColors(Theme, LItem.ActionVariant, dsSolid, dstHover)
      else
        LActColors := DaisyResolveColors(Theme, LItem.ActionVariant, dsSolid, dstNormal);
      DrawBadgeShape(LCell.Action, LActColors, Theme.RadiusField);
      DrawText(LItem.ActionCaption, LCell.Action, LActColors.Text, DaisyFontSize(dzSM), False,
        TTextAlign.Center, TTextAlign.Center, False);
    end;
  end;
end;

end.
