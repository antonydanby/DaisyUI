unit Daisy.VCL.List;

{
  TDaisyList - the DaisyUI "list": a card of rows, each with an optional leading
  picture (emoji or SVG), a title and subtitle, an optional description and up to
  two icon buttons. Layout chooses which column grows or wraps.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control;

type
  TDaisyList = class(TDaisyControl)
  strict private
    type
      TRowInfo = record
        Row, Tile, Title, Subtitle, Desc: TRect;
        Act: array[1..2] of TRect;
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
    function BuildLayout(out ABodyHeight: Integer; out AHeaderRect: TRect): TArray<TRowInfo>;
    procedure UpdateHeight;
    procedure HitTest(X, Y: Integer; out ARow, AAction: Integer);
    procedure SetHot(ARow, AAction: Integer);
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

{ TDaisyList }

constructor TDaisyList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLayout := llSecondGrows;
  FUppercaseSubtitle := True;
  FAutoHeight := True;
  FHotRow := -1;
  FHotAction := 0;
  FItems := TDaisyListItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  SetBounds(Left, Top, 360, 160);
end;

destructor TDaisyList.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TDaisyList.SetItems(const Value: TDaisyListItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyList.SetHeader(const Value: string);
begin
  if FHeader <> Value then
  begin
    FHeader := Value;
    UpdateHeight;
    Invalidate;
  end;
end;

procedure TDaisyList.SetLayout(const Value: TDaisyListLayout);
begin
  if FLayout <> Value then
  begin
    FLayout := Value;
    UpdateHeight;
    Invalidate;
  end;
end;

procedure TDaisyList.SetUppercaseSubtitle(const Value: Boolean);
begin
  if FUppercaseSubtitle <> Value then
  begin
    FUppercaseSubtitle := Value;
    Invalidate;
  end;
end;

procedure TDaisyList.SetAutoHeight(const Value: Boolean);
begin
  if FAutoHeight <> Value then
  begin
    FAutoHeight := Value;
    UpdateHeight;
  end;
end;

procedure TDaisyList.ItemsChanged(Sender: TObject);
begin
  UpdateHeight;
  Invalidate;
end;

function TDaisyList.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyList.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyList.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyList.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Text := Theme.BaseContent;
  Result.Border := Theme.BorderColor;
end;

procedure TDaisyList.SizeChanged;
begin
  UpdateHeight;
  Invalidate;
end;

procedure TDaisyList.Loaded;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyList.Resize;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyList.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateHeight;
end;

function TDaisyList.BuildLayout(out ABodyHeight: Integer; out AHeaderRect: TRect): TArray<TRowInfo>;
var
  LBody: TRect;
  LItem: TDaisyListItem;
  LInfo: TRowInfo;
  I, LY, LX, LXR, LPad, LGap, LTile, LTitleW, LBlockH, LRowH, LDescH, LContentH, LTop: Integer;
begin
  LBody := BodyRect;
  LPad := ScaleValue(CPad);
  LGap := ScaleValue(CGap);
  LTile := ScaleValue(CTile);
  LY := LBody.Top;
  AHeaderRect := Rect(0, 0, 0, 0);
  if FHeader <> '' then
  begin
    AHeaderRect := Rect(LBody.Left + LPad, LY + LPad, LBody.Right - LPad, LY + LPad + ScaleValue(CSubLine));
    LY := AHeaderRect.Bottom + ScaleValue(8);
  end;
  SetLength(Result, FItems.Count);
  for I := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[I];
    LInfo := Default(TRowInfo);
    LX := LBody.Left + LPad;
    LXR := LBody.Right - LPad;
    LTop := LY + LPad;
    LContentH := LTile;

    if not LItem.Icon.IsEmpty then
    begin
      LInfo.Tile := Rect(LX, LTop, LX + LTile, LTop + LTile);
      Inc(LX, LTile + LGap);
    end;
    if not LItem.Action2.IsEmpty then
    begin
      LInfo.Act[2] := Rect(LXR - LTile, LTop, LXR, LTop + LTile);
      Dec(LXR, LTile + LGap);
    end;
    if not LItem.Action.IsEmpty then
    begin
      LInfo.Act[1] := Rect(LXR - LTile, LTop, LXR, LTop + LTile);
      Dec(LXR, LTile + LGap);
    end;
    if LXR < LX then
      LXR := LX + 1;

    LBlockH := ScaleValue(CTitleLine);
    if LItem.Subtitle <> '' then
      Inc(LBlockH, ScaleValue(CSubLine));
    LTitleW := LXR - LX;
    LDescH := 0;
    if (FLayout = llThirdGrows) and (LItem.Description <> '') then
    begin
      LTitleW := Max(MeasureTextWidth(LItem.Title, CTitleSize, False),
        MeasureTextWidth(LItem.Subtitle, CSubSize, True)) + ScaleValue(6);
      LTitleW := Min(LTitleW, LXR - LX);
      LInfo.Desc := Rect(LX + LTitleW + LGap, LTop, LXR, LTop + LContentH);
      if LInfo.Desc.Right < LInfo.Desc.Left then
        LInfo.Desc.Right := LInfo.Desc.Left;
    end;

    LInfo.Title := Rect(LX, LTop + (LContentH - LBlockH) div 2, LX + LTitleW, 0);
    LInfo.Title.Bottom := LInfo.Title.Top + ScaleValue(CTitleLine);
    if LItem.Subtitle <> '' then
      LInfo.Subtitle := Rect(LX, LInfo.Title.Bottom, LX + LTitleW, LInfo.Title.Bottom + ScaleValue(CSubLine));

    if (FLayout = llThirdWraps) and (LItem.Description <> '') then
    begin
      LDescH := MeasureTextHeight(LItem.Description, LXR - LX, CSubSize, False);
      LInfo.Desc := Rect(LX, LTop + LContentH, LXR, LTop + LContentH + LDescH);
    end;

    LRowH := 2 * LPad + LContentH + LDescH;
    LInfo.Row := Rect(LBody.Left, LY, LBody.Right, LY + LRowH);
    Inc(LY, LRowH);
    Result[I] := LInfo;
  end;
  if FItems.Count = 0 then
    Inc(LY, LPad);
  ABodyHeight := LY - LBody.Top;
end;

procedure TDaisyList.UpdateHeight;
var
  LBodyH: Integer;
  LHeader: TRect;
  LHeight: Integer;
begin
  if (not FAutoHeight) or FUpdating or (csLoading in ComponentState) then
    Exit;
  BuildLayout(LBodyH, LHeader);
  LHeight := LBodyH + 2 * ResolvedShadowSize;
  if LHeight = Height then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyList.HitTest(X, Y: Integer; out ARow, AAction: Integer);
var
  LRows: TArray<TRowInfo>;
  LBodyH: Integer;
  LHeader: TRect;
  I, A: Integer;
begin
  ARow := -1;
  AAction := 0;
  LRows := BuildLayout(LBodyH, LHeader);
  for I := 0 to High(LRows) do
    if PtInRect(LRows[I].Row, Point(X, Y)) then
    begin
      ARow := I;
      for A := 1 to 2 do
        if PtInRect(LRows[I].Act[A], Point(X, Y)) then
          AAction := A;
      Exit;
    end;
end;

procedure TDaisyList.SetHot(ARow, AAction: Integer);
begin
  if (ARow <> FHotRow) or (AAction <> FHotAction) then
  begin
    FHotRow := ARow;
    FHotAction := AAction;
    Invalidate;
  end;
end;

procedure TDaisyList.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TDaisyList.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHot(-1, 0);
  Cursor := crDefault;
end;

procedure TDaisyList.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LRow, LAction: Integer;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  HitTest(X, Y, LRow, LAction);
  if (LRow >= 0) and Assigned(FOnItemClick) then
    FOnItemClick(Self, LRow, LAction);
end;

procedure TDaisyList.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LRows: TArray<TRowInfo>;
  LHeader: TRect;
  LBodyH, I, A, LPad: Integer;
  LGraphics: TGPGraphics;
  LBrush: TGPSolidBrush;
  LItem: TDaisyListItem;
  LText, LDim: TAlphaColor;
  LHover: TDaisyColors;
  LBox: TRect;
  LSubtitle: string;
begin
  LRows := BuildLayout(LBodyH, LHeader);
  LPad := ScaleValue(CPad);
  LText := Theme.BaseContent;
  LDim := DaisyWithAlpha(LText, 0.6);
  LHover := DaisyResolveColors(Theme, dvDefault, dsGhost, dstHover);

  LGraphics := NewGraphics;
  try
    LBrush := TGPSolidBrush.Create(0);
    try
      for I := 0 to High(LRows) do
      begin
        if not LRows[I].Tile.IsEmpty then
          FillRoundRect(LGraphics, RectF(LRows[I].Tile.Left, LRows[I].Tile.Top, LRows[I].Tile.Right,
            LRows[I].Tile.Bottom), ScaleValue(Theme.RadiusBox), Theme.Base200);
        for A := 1 to 2 do
          if (not LRows[I].Act[A].IsEmpty) and (I = FHotRow) and (A = FHotAction) then
            FillRoundRect(LGraphics, RectF(LRows[I].Act[A].Left, LRows[I].Act[A].Top,
              LRows[I].Act[A].Right, LRows[I].Act[A].Bottom), ScaleValue(Theme.RadiusField),
              LHover.Background);
        if I < High(LRows) then
        begin
          LBrush.SetColor(DaisyWithAlpha(LText, 0.05));
          LGraphics.FillRectangle(LBrush, LRows[I].Row.Left + LPad, LRows[I].Row.Bottom - 1,
            LRows[I].Row.Width - 2 * LPad, 1);
        end;
      end;
    finally
      LBrush.Free;
    end;
  finally
    LGraphics.Free;
  end;

  if FHeader <> '' then
    DrawRichText(FHeader, LHeader, LDim, CSubSize, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

  for I := 0 to High(LRows) do
  begin
    LItem := FItems[I];
    if not LRows[I].Tile.IsEmpty then
    begin
      LBox := LRows[I].Tile;
      InflateRect(LBox, -ScaleValue(6), -ScaleValue(6));
      DrawGlyph(LItem.Icon, LBox, LText);
    end;
    for A := 1 to 2 do
      if not LRows[I].Act[A].IsEmpty then
      begin
        LBox := LRows[I].Act[A];
        InflateRect(LBox, -ScaleValue(8), -ScaleValue(8));
        if A = 1 then
          DrawGlyph(LItem.Action, LBox, LText)
        else
          DrawGlyph(LItem.Action2, LBox, LText);
      end;
    DrawRichText(LItem.Title, LRows[I].Title, LText, CTitleSize, False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    if LItem.Subtitle <> '' then
    begin
      LSubtitle := LItem.Subtitle;
      if FUppercaseSubtitle then
        LSubtitle := LSubtitle.ToUpper;
      DrawRichText(LSubtitle, LRows[I].Subtitle, LDim, CSubSize, True,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;
    if (LItem.Description <> '') and not LRows[I].Desc.IsEmpty then
    begin
      if FLayout = llThirdWraps then
        DrawRichText(LItem.Description, LRows[I].Desc, LText, CSubSize, False, DT_LEFT or DT_WORDBREAK)
      else
        DrawRichText(LItem.Description, LRows[I].Desc, LText, CSubSize, False,
          DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;
  end;
end;

end.
