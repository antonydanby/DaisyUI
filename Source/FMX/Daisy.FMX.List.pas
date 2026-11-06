unit Daisy.FMX.List;

{
  TDaisyFmxList - the DaisyUI "list": a card of rows, each with an optional leading
  picture (emoji or SVG), a title and subtitle, an optional description and up to
  two icon buttons. Layout chooses which column grows or wraps.
  Mirrors Daisy.VCL.List so both frameworks share one public API.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, Daisy.Theme, Daisy.Widgets, Daisy.FMX.Control;

type
  TDaisyFmxList = class(TDaisyControl)
  strict private
    type
      TRowInfo = record
        Row, Tile, Title, Subtitle, Desc: TRectF;
        Act: array[1..2] of TRectF;
      end;
    var
    FItems: TDaisyListItems;
    FHeader: string;
    FLayout: TDaisyListLayout;
    FUppercaseSubtitle: Boolean;
    FAutoHeight: Boolean;
    FUpdating: Boolean;
    FHotRow: Integer;
    FHotAction: Integer;
    FOnItemClick: TDaisyListClickEvent;
    procedure SetItems(const Value: TDaisyListItems);
    procedure SetHeader(const Value: string);
    procedure SetLayout(const Value: TDaisyListLayout);
    procedure SetUppercaseSubtitle(const Value: Boolean);
    procedure SetAutoHeight(const Value: Boolean);
    procedure ItemsChanged(Sender: TObject);
    function BuildLayout(out ABodyHeight: Single; out AHeaderRect: TRectF): TArray<TRowInfo>;
    procedure UpdateHeight;
    procedure HitTest(X, Y: Single; out ARow, AAction: Integer);
    procedure SetHot(ARow, AAction: Integer);
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
    property Items: TDaisyListItems read FItems write SetItems;
    // Small dimmed title above the first row
    property Header: string read FHeader write SetHeader;
    property Layout: TDaisyListLayout read FLayout write SetLayout default llSecondGrows;
    property UppercaseSubtitle: Boolean read FUppercaseSubtitle write SetUppercaseSubtitle default True;
    // The height follows the number of rows
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default True;
    // Fires for a click on a row (AAction = 0) or on one of its two buttons (1 or 2)
    property OnItemClick: TDaisyListClickEvent read FOnItemClick write FOnItemClick;
  end;

implementation

const
  CPad = 16;
  CTile = 40;
  CGap = 16;
  CTitleSize = 14;
  CSubSize = 12;
  CTitleLine = 20;
  CSubLine = 16;

{ TDaisyFmxList }

constructor TDaisyFmxList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLayout := llSecondGrows;
  FUppercaseSubtitle := True;
  FAutoHeight := True;
  FHotRow := -1;
  FItems := TDaisyListItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  SetBounds(Position.X, Position.Y, 360, 160);
end;

destructor TDaisyFmxList.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TDaisyFmxList.SetItems(const Value: TDaisyListItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxList.SetHeader(const Value: string);
begin
  if FHeader <> Value then
  begin
    FHeader := Value;
    UpdateHeight;
    Repaint;
  end;
end;

procedure TDaisyFmxList.SetLayout(const Value: TDaisyListLayout);
begin
  if FLayout <> Value then
  begin
    FLayout := Value;
    UpdateHeight;
    Repaint;
  end;
end;

procedure TDaisyFmxList.SetUppercaseSubtitle(const Value: Boolean);
begin
  if FUppercaseSubtitle <> Value then
  begin
    FUppercaseSubtitle := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxList.SetAutoHeight(const Value: Boolean);
begin
  if FAutoHeight <> Value then
  begin
    FAutoHeight := Value;
    UpdateHeight;
  end;
end;

procedure TDaisyFmxList.ItemsChanged(Sender: TObject);
begin
  UpdateHeight;
  Repaint;
end;

function TDaisyFmxList.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxList.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxList.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxList.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Text := Theme.BaseContent;
  Result.Border := Theme.Base300;
end;

procedure TDaisyFmxList.SizeChanged;
begin
  UpdateHeight;
  Repaint;
end;

procedure TDaisyFmxList.Loaded;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyFmxList.Resize;
begin
  inherited;
  UpdateHeight;
end;

function TDaisyFmxList.BuildLayout(out ABodyHeight: Single; out AHeaderRect: TRectF): TArray<TRowInfo>;
var
  LBody: TRectF;
  LItem: TDaisyListItem;
  LInfo: TRowInfo;
  I: Integer;
  LY, LX, LXR, LTitleW, LBlockH, LRowH, LDescH, LTop: Single;
begin
  LBody := BodyRect;
  LY := LBody.Top;
  AHeaderRect := RectF(0, 0, 0, 0);
  if FHeader <> '' then
  begin
    AHeaderRect := RectF(LBody.Left + CPad, LY + CPad, LBody.Right - CPad, LY + CPad + CSubLine);
    LY := AHeaderRect.Bottom + 8;
  end;
  SetLength(Result, FItems.Count);
  for I := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[I];
    LInfo := Default(TRowInfo);
    LX := LBody.Left + CPad;
    LXR := LBody.Right - CPad;
    LTop := LY + CPad;

    if not LItem.Icon.IsEmpty then
    begin
      LInfo.Tile := RectF(LX, LTop, LX + CTile, LTop + CTile);
      LX := LX + CTile + CGap;
    end;
    if not LItem.Action2.IsEmpty then
    begin
      LInfo.Act[2] := RectF(LXR - CTile, LTop, LXR, LTop + CTile);
      LXR := LXR - CTile - CGap;
    end;
    if not LItem.Action.IsEmpty then
    begin
      LInfo.Act[1] := RectF(LXR - CTile, LTop, LXR, LTop + CTile);
      LXR := LXR - CTile - CGap;
    end;
    if LXR < LX then
      LXR := LX + 1;

    LBlockH := CTitleLine;
    if LItem.Subtitle <> '' then
      LBlockH := LBlockH + CSubLine;
    LTitleW := LXR - LX;
    LDescH := 0;
    if (FLayout = llThirdGrows) and (LItem.Description <> '') then
    begin
      LTitleW := Max(MeasureTextWidth(LItem.Title, CTitleSize, False),
        MeasureTextWidth(LItem.Subtitle, CSubSize, True)) + 6;
      LTitleW := Min(LTitleW, LXR - LX);
      LInfo.Desc := RectF(LX + LTitleW + CGap, LTop, Max(LX + LTitleW + CGap, LXR), LTop + CTile);
    end;

    LInfo.Title := RectF(LX, LTop + (CTile - LBlockH) / 2, LX + LTitleW, LTop + (CTile - LBlockH) / 2 + CTitleLine);
    if LItem.Subtitle <> '' then
      LInfo.Subtitle := RectF(LX, LInfo.Title.Bottom, LX + LTitleW, LInfo.Title.Bottom + CSubLine);

    if (FLayout = llThirdWraps) and (LItem.Description <> '') then
    begin
      LDescH := Ceil(MeasureTextHeight(LItem.Description, LXR - LX, CSubSize, False));
      LInfo.Desc := RectF(LX, LTop + CTile, LXR, LTop + CTile + LDescH);
    end;

    LRowH := 2 * CPad + CTile + LDescH;
    LInfo.Row := RectF(LBody.Left, LY, LBody.Right, LY + LRowH);
    LY := LY + LRowH;
    Result[I] := LInfo;
  end;
  if FItems.Count = 0 then
    LY := LY + CPad;
  ABodyHeight := LY - LBody.Top;
end;

procedure TDaisyFmxList.UpdateHeight;
var
  LBodyH, LHeight: Single;
  LHeader: TRectF;
begin
  if (not FAutoHeight) or FUpdating or (csLoading in ComponentState) then
    Exit;
  BuildLayout(LBodyH, LHeader);
  LHeight := LBodyH + 2 * ResolvedShadowSize;
  if SameValue(LHeight, Height) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxList.HitTest(X, Y: Single; out ARow, AAction: Integer);
var
  LRows: TArray<TRowInfo>;
  LBodyH: Single;
  LHeader: TRectF;
  I, A: Integer;
begin
  ARow := -1;
  AAction := 0;
  LRows := BuildLayout(LBodyH, LHeader);
  for I := 0 to High(LRows) do
    if LRows[I].Row.Contains(PointF(X, Y)) then
    begin
      ARow := I;
      for A := 1 to 2 do
        if (LRows[I].Act[A].Width > 0) and LRows[I].Act[A].Contains(PointF(X, Y)) then
          AAction := A;
      Exit;
    end;
end;

procedure TDaisyFmxList.SetHot(ARow, AAction: Integer);
begin
  if (ARow <> FHotRow) or (AAction <> FHotAction) then
  begin
    FHotRow := ARow;
    FHotAction := AAction;
    Repaint;
  end;
end;

procedure TDaisyFmxList.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LRow, LAction: Integer;
begin
  inherited;
  HitTest(X, Y, LRow, LAction);
  if LAction = 0 then
    LRow := -1;
  SetHot(LRow, LAction);
  if LAction > 0 then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TDaisyFmxList.DoMouseLeave;
begin
  inherited;
  SetHot(-1, 0);
  Cursor := crDefault;
end;

procedure TDaisyFmxList.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LRow, LAction: Integer;
begin
  inherited;
  if Button <> TMouseButton.mbLeft then
    Exit;
  HitTest(X, Y, LRow, LAction);
  if (LRow >= 0) and Assigned(FOnItemClick) then
    FOnItemClick(Self, LRow, LAction);
end;

procedure TDaisyFmxList.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LRows: TArray<TRowInfo>;
  LHeader, LBox: TRectF;
  LBodyH: Single;
  I, A: Integer;
  LItem: TDaisyListItem;
  LText, LDim: TAlphaColor;
  LHover: TDaisyColors;
  LSubtitle: string;
  LRadius: Single;
begin
  LRows := BuildLayout(LBodyH, LHeader);
  LText := Theme.BaseContent;
  LDim := DaisyWithAlpha(LText, 0.6);
  LHover := DaisyResolveColors(Theme, dvDefault, dsGhost, dstHover);
  Canvas.Fill.Kind := TBrushKind.Solid;

  for I := 0 to High(LRows) do
  begin
    if LRows[I].Tile.Width > 0 then
    begin
      LRadius := Theme.RadiusBox;
      Canvas.Fill.Color := Theme.Base200;
      Canvas.FillRect(LRows[I].Tile, LRadius, LRadius, AllCorners, AbsoluteOpacity);
    end;
    for A := 1 to 2 do
      if (LRows[I].Act[A].Width > 0) and (I = FHotRow) and (A = FHotAction) then
      begin
        LRadius := Theme.RadiusField;
        Canvas.Fill.Color := LHover.Background;
        Canvas.FillRect(LRows[I].Act[A], LRadius, LRadius, AllCorners, AbsoluteOpacity);
      end;
    if I < High(LRows) then
    begin
      Canvas.Fill.Color := DaisyWithAlpha(LText, 0.05);
      Canvas.FillRect(RectF(LRows[I].Row.Left + CPad, LRows[I].Row.Bottom - 1,
        LRows[I].Row.Right - CPad, LRows[I].Row.Bottom), 0, 0, AllCorners, AbsoluteOpacity);
    end;
  end;

  if FHeader <> '' then
    DrawText(FHeader, LHeader, LDim, CSubSize, False, TTextAlign.Leading, TTextAlign.Center, False);

  for I := 0 to High(LRows) do
  begin
    LItem := FItems[I];
    if LRows[I].Tile.Width > 0 then
    begin
      LBox := LRows[I].Tile;
      LBox.Inflate(-6, -6);
      DrawGlyph(LItem.Icon, LBox, LText);
    end;
    for A := 1 to 2 do
      if LRows[I].Act[A].Width > 0 then
      begin
        LBox := LRows[I].Act[A];
        LBox.Inflate(-8, -8);
        if A = 1 then
          DrawGlyph(LItem.Action, LBox, LText)
        else
          DrawGlyph(LItem.Action2, LBox, LText);
      end;
    DrawText(LItem.Title, LRows[I].Title, LText, CTitleSize, False, TTextAlign.Leading,
      TTextAlign.Center, False);
    if LItem.Subtitle <> '' then
    begin
      LSubtitle := LItem.Subtitle;
      if FUppercaseSubtitle then
        LSubtitle := LSubtitle.ToUpper;
      DrawText(LSubtitle, LRows[I].Subtitle, LDim, CSubSize, True, TTextAlign.Leading,
        TTextAlign.Center, False);
    end;
    if (LItem.Description <> '') and (LRows[I].Desc.Width > 0) then
    begin
      if FLayout = llThirdWraps then
        DrawText(LItem.Description, LRows[I].Desc, LText, CSubSize, False, TTextAlign.Leading,
          TTextAlign.Leading, True)
      else
        DrawText(LItem.Description, LRows[I].Desc, LText, CSubSize, False, TTextAlign.Leading,
          TTextAlign.Center, False);
    end;
  end;
end;

end.
