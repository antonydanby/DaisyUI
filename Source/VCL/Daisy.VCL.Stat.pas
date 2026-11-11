unit Daisy.VCL.Stat;

{
  TDaisyStat - the DaisyUI "stat": one or more figures, each with a title, a large
  value, a description, an optional figure (emoji or SVG) and an optional small
  button. Items run horizontally or vertically, optionally centred.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control;

type
  TDaisyStat = class(TDaisyControl)
  strict private
    type
      TStatCell = record
        Cell, Title, Value, Desc, Figure, Action: TRect;
        ActionWidth: Integer;
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
    function BuildLayout(out ABody: TSize): TArray<TStatCell>;
    function ActionAt(X, Y: Integer): Integer;
    procedure UpdateSize;
    procedure SetHotAction(AIndex: Integer);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

{ TDaisyStat }

constructor TDaisyStat.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFit := True;
  FHotAction := -1;
  FItems := TDaisyStatItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FItems.Add;
  SetBounds(Left, Top, 200, 120);
  UpdateSize;
end;

destructor TDaisyStat.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TDaisyStat.SetItems(const Value: TDaisyStatItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyStat.SetDirection(const Value: TDaisyStatDirection);
begin
  if FDirection <> Value then
  begin
    FDirection := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyStat.SetCentered(const Value: Boolean);
begin
  if FCentered <> Value then
  begin
    FCentered := Value;
    Invalidate;
  end;
end;

procedure TDaisyStat.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyStat.ItemsChanged(Sender: TObject);
begin
  UpdateSize;
  Invalidate;
end;

function TDaisyStat.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyStat.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyStat.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyStat.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
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

procedure TDaisyStat.SizeChanged;
begin
  UpdateSize;
  Invalidate;
end;

procedure TDaisyStat.Loaded;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyStat.Resize;
begin
  inherited;
  if not FAutoFit then
    Invalidate;
end;

procedure TDaisyStat.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSize;
end;

function TDaisyStat.BuildLayout(out ABody: TSize): TArray<TStatCell>;
var
  LBody: TRect;
  I, LPadX, LPadY, LGap, LFig, LRowsH, LTextW, LContentW, LW, LH, LX, LY, LExtra, LSmall: Integer;
  LItem: TDaisyStatItem;
  LWidths, LHeights: array of Integer;
  LCell: TStatCell;
  LTextL, LTextR: Integer;
begin
  LBody := BodyRect;
  LPadX := ScaleValue(CPadX);
  LPadY := ScaleValue(CPadY);
  LGap := ScaleValue(CGap);
  LFig := ScaleValue(CFigure);
  SetLength(Result, FItems.Count);
  SetLength(LWidths, FItems.Count);
  SetLength(LHeights, FItems.Count);
  ABody := TSize.Create(0, 0);
  LSmall := DaisyFontSize(dzSM);

  for I := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[I];
    LTextW := Max(MeasureTextWidth(LItem.Title, CTitleSize, False),
      Max(MeasureTextWidth(LItem.Value, CValueSize, True), MeasureTextWidth(LItem.Description, CDescSize, False)));
    Result[I].ActionWidth := 0;
    if LItem.ActionCaption <> '' then
    begin
      Result[I].ActionWidth := MeasureTextWidth(LItem.ActionCaption, LSmall, False) +
        2 * ScaleValue(DaisyFieldPaddingX(dzSM)) + ScaleValue(2);
      LTextW := Max(LTextW, Result[I].ActionWidth);
    end;
    LTextW := LTextW + ScaleValue(4);
    LContentW := LTextW;
    if not LItem.Icon.IsEmpty then
      Inc(LContentW, LGap + LFig);
    LWidths[I] := LContentW + 2 * LPadX;
    LRowsH := ScaleValue(CTitleLine + CValueLine) + IfThen(LItem.Description <> '', ScaleValue(CDescLine));
    if LItem.ActionCaption <> '' then
      Inc(LRowsH, LGap + ScaleValue(DaisyFieldHeight(dzSM)));
    LHeights[I] := LRowsH + 2 * LPadY;
    if FDirection = sdHorizontal then
    begin
      Inc(ABody.cx, LWidths[I]);
      ABody.cy := Max(ABody.cy, LHeights[I]);
    end
    else
    begin
      ABody.cx := Max(ABody.cx, LWidths[I]);
      Inc(ABody.cy, LHeights[I]);
    end;
  end;

  if not FAutoFit then
  begin
    LExtra := 0;
    if FItems.Count > 0 then
      if FDirection = sdHorizontal then
        LExtra := Max(0, LBody.Width - ABody.cx) div FItems.Count
      else
        LExtra := Max(0, LBody.Height - ABody.cy) div FItems.Count;
    for I := 0 to FItems.Count - 1 do
      if FDirection = sdHorizontal then
        Inc(LWidths[I], LExtra)
      else
        Inc(LHeights[I], LExtra);
    ABody := TSize.Create(Max(LBody.Width, 0), Max(LBody.Height, 0));
    if FDirection = sdHorizontal then
    begin
      ABody.cx := 0;
      for I := 0 to High(LWidths) do
        Inc(ABody.cx, LWidths[I]);
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
      LCell.Cell := Rect(LX, LBody.Top, LX + LW, LBody.Top + LH);
      Inc(LX, LW);
    end
    else
    begin
      LW := ABody.cx;
      LH := LHeights[I];
      LCell.Cell := Rect(LBody.Left, LY, LBody.Left + LW, LY + LH);
      Inc(LY, LH);
    end;
    LTextL := LCell.Cell.Left + LPadX;
    LTextR := LCell.Cell.Right - LPadX;
    LRowsH := ScaleValue(CTitleLine + CValueLine) + IfThen(LItem.Description <> '', ScaleValue(CDescLine));
    if not LItem.Icon.IsEmpty then
    begin
      LCell.Figure := Rect(LTextR - LFig, LCell.Cell.Top + LPadY + (LRowsH - LFig) div 2, LTextR,
        LCell.Cell.Top + LPadY + (LRowsH - LFig) div 2 + LFig);
      LTextR := LCell.Figure.Left - LGap;
    end;
    LCell.Title := Rect(LTextL, LCell.Cell.Top + LPadY, LTextR, LCell.Cell.Top + LPadY + ScaleValue(CTitleLine));
    LCell.Value := Rect(LTextL, LCell.Title.Bottom, LTextR, LCell.Title.Bottom + ScaleValue(CValueLine));
    LCell.Desc := Rect(LTextL, LCell.Value.Bottom, LTextR,
      LCell.Value.Bottom + IfThen(LItem.Description <> '', ScaleValue(CDescLine)));
    if LItem.ActionCaption <> '' then
    begin
      LCell.Action.Left := IfThen(FCentered, LTextL + (LTextR - LTextL - LCell.ActionWidth) div 2, LTextL);
      LCell.Action.Right := LCell.Action.Left + LCell.ActionWidth;
      LCell.Action.Top := LCell.Desc.Bottom + LGap;
      LCell.Action.Bottom := LCell.Action.Top + ScaleValue(DaisyFieldHeight(dzSM));
    end;
    Result[I] := LCell;
  end;
end;

procedure TDaisyStat.UpdateSize;
var
  LSize: TSize;
  LMargin: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  BuildLayout(LSize);
  LMargin := 2 * ResolvedShadowSize;
  if (LSize.cx <= 0) or ((LSize.cx + LMargin = Width) and (LSize.cy + LMargin = Height)) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, LSize.cx + LMargin, LSize.cy + LMargin);
  finally
    FUpdating := False;
  end;
end;

function TDaisyStat.ActionAt(X, Y: Integer): Integer;
var
  LCells: TArray<TStatCell>;
  LSize: TSize;
  I: Integer;
begin
  Result := -1;
  LCells := BuildLayout(LSize);
  for I := 0 to High(LCells) do
    if (not LCells[I].Action.IsEmpty) and PtInRect(LCells[I].Action, Point(X, Y)) then
      Exit(I);
end;

procedure TDaisyStat.SetHotAction(AIndex: Integer);
begin
  if FHotAction <> AIndex then
  begin
    FHotAction := AIndex;
    Invalidate;
  end;
end;

procedure TDaisyStat.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SetHotAction(ActionAt(X, Y));
  if FHotAction >= 0 then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TDaisyStat.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHotAction(-1);
  Cursor := crDefault;
end;

procedure TDaisyStat.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  LIndex := ActionAt(X, Y);
  if (LIndex >= 0) and Assigned(FOnActionClick) then
    FOnActionClick(Self, LIndex);
end;

procedure TDaisyStat.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LCells: TArray<TStatCell>;
  LSize: TSize;
  LGraphics: TGPGraphics;
  LPen: TGPPen;
  LItem: TDaisyStatItem;
  LPalette: TDaisyPalette;
  LActColors: TDaisyColors;
  LItemText, LItemDim, LFigure: TAlphaColor;
  LRadius, I, LHalf: Integer;
  LCell: TStatCell;
  LFlags: Cardinal;
  LBody: TRect;
begin
  LCells := BuildLayout(LSize);
  LBody := BodyRect;
  LRadius := ResolvedCornerRadius;

  LGraphics := NewGraphics;
  try
    for I := 0 to High(LCells) do
    begin
      LItem := FItems[I];
      LCell := LCells[I];
      if LItem.Variant <> dvDefault then
      begin
        LPalette := DaisyVariantPalette(Theme, LItem.Variant);
        FillRoundRect(LGraphics, RectF(LCell.Cell.Left, LCell.Cell.Top, LCell.Cell.Right, LCell.Cell.Bottom),
          LRadius, LPalette.Fill);
        // square off the sides that touch a neighbour
        LHalf := IfThen(FDirection = sdHorizontal, LCell.Cell.Width, LCell.Cell.Height) div 2;
        if FDirection = sdHorizontal then
        begin
          if I > 0 then
            FillRoundRect(LGraphics, RectF(LCell.Cell.Left, LCell.Cell.Top, LCell.Cell.Left + LHalf, LCell.Cell.Bottom), 0, LPalette.Fill);
          if I < High(LCells) then
            FillRoundRect(LGraphics, RectF(LCell.Cell.Right - LHalf, LCell.Cell.Top, LCell.Cell.Right, LCell.Cell.Bottom), 0, LPalette.Fill);
        end
        else
        begin
          if I > 0 then
            FillRoundRect(LGraphics, RectF(LCell.Cell.Left, LCell.Cell.Top, LCell.Cell.Right, LCell.Cell.Top + LHalf), 0, LPalette.Fill);
          if I < High(LCells) then
            FillRoundRect(LGraphics, RectF(LCell.Cell.Left, LCell.Cell.Bottom - LHalf, LCell.Cell.Right, LCell.Cell.Bottom), 0, LPalette.Fill);
        end;
      end;
    end;

    // dashed dividers between items
    LPen := TGPPen.Create(DaisyWithAlpha(Theme.BaseContent, 0.1), 1);
    try
      LPen.SetDashStyle(DashStyleDash);
      for I := 1 to High(LCells) do
        if FDirection = sdHorizontal then
          LGraphics.DrawLine(LPen, LCells[I].Cell.Left + 0.5, LBody.Top + ScaleValue(CPadY) / 2,
            LCells[I].Cell.Left + 0.5, LBody.Bottom - ScaleValue(CPadY) / 2)
        else
          LGraphics.DrawLine(LPen, LBody.Left + ScaleValue(CPadX) / 2, LCells[I].Cell.Top + 0.5,
            LBody.Right - ScaleValue(CPadX) / 2, LCells[I].Cell.Top + 0.5);
    finally
      LPen.Free;
    end;
  finally
    LGraphics.Free;
  end;

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
    if FCentered then
      LFlags := DT_CENTER
    else
      LFlags := DT_LEFT;
    LFlags := LFlags or DT_VCENTER or DT_SINGLELINE;

    DrawRichText(LItem.Title, LCell.Title, LItemDim, CTitleSize, False, LFlags);
    DrawRichText(LItem.Value, LCell.Value, LItemText, CValueSize, True, LFlags);
    if LItem.Description <> '' then
      DrawRichText(LItem.Description, LCell.Desc, LItemDim, CDescSize, False, LFlags);

    if not LCell.Figure.IsEmpty then
    begin
      if LItem.FigureVariant <> dvDefault then
        LFigure := DaisyVariantPalette(Theme, LItem.FigureVariant).Fill
      else
        LFigure := LItemText;
      DrawGlyph(LItem.Icon, LCell.Figure, LFigure);
    end;

    if not LCell.Action.IsEmpty then
    begin
      if I = FHotAction then
        LActColors := DaisyResolveColors(Theme, LItem.ActionVariant, dsSolid, dstHover)
      else
        LActColors := DaisyResolveColors(Theme, LItem.ActionVariant, dsSolid, dstNormal);
      DrawBadgeShape(LCell.Action, LActColors, ScaleValue(Theme.RadiusField));
      DrawText(LItem.ActionCaption, LCell.Action, LActColors.Text, DaisyFontSize(dzSM), False,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    end;
  end;
end;

end.
