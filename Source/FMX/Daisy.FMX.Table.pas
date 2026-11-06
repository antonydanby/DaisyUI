unit Daisy.FMX.Table;

{
  TDaisyFmxTable - the DaisyUI "table": columns and rows of text, checkboxes,
  avatars, badges and buttons, with optional zebra stripes, hover and active
  rows, a footer, pinned header / footer rows, pinned columns and a right to
  left layout. Cells may hold emoji; avatars may hold SVG.

  The table is drawn, not built from child controls. The mouse wheel scrolls it
  (Shift + wheel scrolls sideways) when the content is larger than the control.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.Tables,
  Daisy.FMX.Control;

type
  TDaisyFmxTable = class(TDaisyControl)
  strict private
    type
      TCellHit = record
        Row, Col: Integer; // Row: -1 header, -2 footer, >= 0 body, -3 none
      end;
    var
    FColumns: TDaisyTableColumns;
    FRows: TDaisyTableRows;
    FShowHeader: Boolean;
    FShowFooter: Boolean;
    FZebra: Boolean;
    FHoverRows: Boolean;
    FBordered: Boolean;
    FRightToLeft: Boolean;
    FPinRows: Boolean;
    FAutoHeight: Boolean;
    FScrollX, FScrollY: Single;
    FNatural: TArray<Single>;
    FNaturalValid: Boolean;
    FUpdating: Boolean;
    FHotRow, FHotCol: Integer;
    FOnRowClick: TDaisyTableRowEvent;
    FOnButtonClick: TDaisyTableCellEvent;
    procedure SetColumns(const Value: TDaisyTableColumns);
    procedure SetRows(const Value: TDaisyTableRows);
    procedure SetShowHeader(const Value: Boolean);
    procedure SetShowFooter(const Value: Boolean);
    procedure SetZebra(const Value: Boolean);
    procedure SetHoverRows(const Value: Boolean);
    procedure SetBordered(const Value: Boolean);
    procedure SetRightToLeft(const Value: Boolean);
    procedure SetPinRows(const Value: Boolean);
    procedure SetAutoHeight(const Value: Boolean);
    procedure ModelChanged(Sender: TObject);
    procedure Relayout;
    function Inset: Single;
    function Area: TRectF;
    function FontSize: Integer;
    function HeadFontSize: Integer;
    function PadX: Single;
    function PadY: Single;
    function LineHeight: Single;
    function AvatarSize: Single;
    function CheckSize: Single;
    function BadgeSize: TDaisySize;
    function HasAvatar: Boolean;
    function RowHeight: Single;
    function HeaderHeight: Single;
    function FooterHeight: Single;
    function ContentHeight: Single;
    function MaxScrollX: Single;
    function MaxScrollY: Single;
    procedure EnsureNatural;
    function ColumnWidths: TArray<Single>;
    procedure ColumnPositions(out AX, AW: TArray<Single>);
    function Mirror(const ARect: TRectF): TRectF;
    function RowTop(ARow: Integer): Single;
    function RowBackground(ARow: Integer): TAlphaColor;
    function ButtonColors(ARow, ACol: Integer): TDaisyColors;
    function EffectiveAlign(AColumn: TDaisyTableColumn): TDaisyTextAlign;
    function CheckRect(const ACell: TRectF; AAlign: TDaisyTextAlign): TRectF;
    function ButtonRect(const ACell: TRectF; const AText: string): TRectF;
    function BadgeRect(const ACell: TRectF; const AText: string; AAlign: TDaisyTextAlign): TRectF;
    function HitCell(X, Y: Single): TCellHit;
    function CellRect(const AHit: TCellHit): TRectF;
    procedure SetHot(ARow, ACol: Integer);
    procedure SetScroll(AX, AY: Single);
    procedure DrawCheck(const ARect: TRectF; AChecked: Boolean);
    procedure DrawCell(ARow, ACol: Integer; const ACell: TRectF; AHeader: Boolean);
    procedure DrawColumnCells(ACol: Integer; AX, AW: Single);
    procedure DrawBand(AHeader: Boolean; const AX, AW: TArray<Single>);
    procedure UpdateSize;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure DoMouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Columns: TDaisyTableColumns read FColumns write SetColumns;
    property Rows: TDaisyTableRows read FRows write SetRows;
    property ShowHeader: Boolean read FShowHeader write SetShowHeader default True;
    property ShowFooter: Boolean read FShowFooter write SetShowFooter default False;
    // Every other row is shaded
    property Zebra: Boolean read FZebra write SetZebra default False;
    property HoverRows: Boolean read FHoverRows write SetHoverRows default False;
    // Draws the outer border and the base-100 background
    property Bordered: Boolean read FBordered write SetBordered default False;
    // Mirrors the columns and the text alignment
    property RightToLeft: Boolean read FRightToLeft write SetRightToLeft default False;
    // Header and footer stay in view while the rows scroll
    property PinRows: Boolean read FPinRows write SetPinRows default False;
    // The height follows the rows; turn off to scroll inside a fixed height
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default True;
    property OnRowClick: TDaisyTableRowEvent read FOnRowClick write FOnRowClick;
    property OnButtonClick: TDaisyTableCellEvent read FOnButtonClick write FOnButtonClick;
  end;

implementation

const
  CNoHit = -3;

function ToTextAlign(AAlign: TDaisyTextAlign): TTextAlign;
begin
  case AAlign of
    taEnd: Result := TTextAlign.Trailing;
    taCenter: Result := TTextAlign.Center;
  else
    Result := TTextAlign.Leading;
  end;
end;

{ TDaisyFmxTable }

constructor TDaisyFmxTable.Create(AOwner: TComponent);
var
  LRow: TDaisyTableRow;
begin
  inherited Create(AOwner);
  FShowHeader := True;
  FAutoHeight := True;
  FHotRow := CNoHit;
  FHotCol := -1;
  HitTest := True;
  FColumns := TDaisyTableColumns.Create(Self);
  FColumns.OnChange := ModelChanged;
  FRows := TDaisyTableRows.Create(Self);
  FRows.OnChange := ModelChanged;
  FColumns.Add.Caption := 'Name';
  FColumns.Add.Caption := 'Job';
  FColumns.Add.Caption := 'Favorite Color';
  LRow := FRows.Add;
  LRow.Cells.CommaText := '"Cy Ganderton","Quality Control Specialist",Blue';
  LRow := FRows.Add;
  LRow.Cells.CommaText := '"Hart Hagerty","Desktop Support Technician",Purple';
  LRow := FRows.Add;
  LRow.Cells.CommaText := '"Brice Swyre","Tax Accountant",Red';
  SetBounds(Position.X, Position.Y, 480, 150);
  UpdateSize;
end;

destructor TDaisyFmxTable.Destroy;
begin
  FRows.Free;
  FColumns.Free;
  inherited Destroy;
end;

function TDaisyFmxTable.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxTable.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxTable.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxTable.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
  if FBordered then
  begin
    Result.Background := Theme.Base100;
    Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.12);
  end;
end;

procedure TDaisyFmxTable.SetColumns(const Value: TDaisyTableColumns);
begin
  FColumns.Assign(Value);
end;

procedure TDaisyFmxTable.SetRows(const Value: TDaisyTableRows);
begin
  FRows.Assign(Value);
end;

procedure TDaisyFmxTable.SetShowHeader(const Value: Boolean);
begin
  if FShowHeader <> Value then
  begin
    FShowHeader := Value;
    Relayout;
  end;
end;

procedure TDaisyFmxTable.SetShowFooter(const Value: Boolean);
begin
  if FShowFooter <> Value then
  begin
    FShowFooter := Value;
    Relayout;
  end;
end;

procedure TDaisyFmxTable.SetZebra(const Value: Boolean);
begin
  if FZebra <> Value then
  begin
    FZebra := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxTable.SetHoverRows(const Value: Boolean);
begin
  if FHoverRows <> Value then
  begin
    FHoverRows := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxTable.SetBordered(const Value: Boolean);
begin
  if FBordered <> Value then
  begin
    FBordered := Value;
    Relayout;
  end;
end;

procedure TDaisyFmxTable.SetRightToLeft(const Value: Boolean);
begin
  if FRightToLeft <> Value then
  begin
    FRightToLeft := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxTable.SetPinRows(const Value: Boolean);
begin
  if FPinRows <> Value then
  begin
    FPinRows := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxTable.SetAutoHeight(const Value: Boolean);
begin
  if FAutoHeight <> Value then
  begin
    FAutoHeight := Value;
    Relayout;
  end;
end;

procedure TDaisyFmxTable.ModelChanged(Sender: TObject);
begin
  Relayout;
end;

procedure TDaisyFmxTable.Relayout;
begin
  FNaturalValid := False;
  UpdateSize;
  SetScroll(FScrollX, FScrollY);
  Repaint;
end;

procedure TDaisyFmxTable.SizeChanged;
begin
  Relayout;
end;

procedure TDaisyFmxTable.Loaded;
begin
  inherited;
  Relayout;
end;

procedure TDaisyFmxTable.Resize;
begin
  inherited;
  SetScroll(FScrollX, FScrollY);
end;

procedure TDaisyFmxTable.DoMouseLeave;
begin
  inherited;
  SetHot(CNoHit, -1);
  Cursor := crDefault;
end;

{ metrics }

function TDaisyFmxTable.Inset: Single;
begin
  if FBordered then
    Result := Max(1, Theme.BorderWidth)
  else
    Result := 0;
end;

function TDaisyFmxTable.Area: TRectF;
begin
  Result := RectF(0, 0, Width, Height);
  Result.Inflate(-Inset, -Inset);
end;

function TDaisyFmxTable.FontSize: Integer;
begin
  Result := DaisyFontSize(SizeKind);
end;

function TDaisyFmxTable.HeadFontSize: Integer;
begin
  Result := Max(10, FontSize - 2);
end;

function TDaisyFmxTable.PadX: Single;
const
  C: array[TDaisySize] of Integer = (8, 12, 16, 20, 24);
begin
  Result := C[SizeKind];
end;

function TDaisyFmxTable.PadY: Single;
const
  C: array[TDaisySize] of Integer = (4, 8, 12, 16, 20);
begin
  Result := C[SizeKind];
end;

function TDaisyFmxTable.LineHeight: Single;
begin
  Result := Round(FontSize * 1.4);
end;

function TDaisyFmxTable.AvatarSize: Single;
begin
  Result := DaisyFieldHeight(SizeKind) + 8;
end;

function TDaisyFmxTable.CheckSize: Single;
begin
  Result := FontSize + 6;
end;

function TDaisyFmxTable.BadgeSize: TDaisySize;
begin
  if SizeKind >= dzMD then
    Result := dzSM
  else
    Result := dzXS;
end;

function TDaisyFmxTable.HasAvatar: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FColumns.Count - 1 do
    if FColumns[I].Kind = ckAvatar then
      Exit(True);
end;

function TDaisyFmxTable.RowHeight: Single;
begin
  if HasAvatar then
    Result := AvatarSize + 2 * PadY
  else
    Result := LineHeight + 2 * PadY;
end;

function TDaisyFmxTable.HeaderHeight: Single;
begin
  if FShowHeader then
    Result := LineHeight + 2 * PadY
  else
    Result := 0;
end;

function TDaisyFmxTable.FooterHeight: Single;
begin
  if FShowFooter then
    Result := LineHeight + 2 * PadY
  else
    Result := 0;
end;

function TDaisyFmxTable.ContentHeight: Single;
begin
  Result := HeaderHeight + FRows.Count * RowHeight + FooterHeight;
end;

function TDaisyFmxTable.MaxScrollX: Single;
var
  LWidths: TArray<Single>;
  LTotal: Single;
  I: Integer;
begin
  LWidths := ColumnWidths;
  LTotal := 0;
  for I := 0 to High(LWidths) do
    LTotal := LTotal + LWidths[I];
  Result := Max(0, LTotal - Area.Width);
end;

function TDaisyFmxTable.MaxScrollY: Single;
begin
  Result := Max(0, ContentHeight - Area.Height);
end;

procedure TDaisyFmxTable.EnsureNatural;
var
  I, J: Integer;
  LWidth, LRowW: Single;
  LColumn: TDaisyTableColumn;
  LTitle, LSub, LText: string;
begin
  if FNaturalValid then
    Exit;
  SetLength(FNatural, FColumns.Count);
  for I := 0 to FColumns.Count - 1 do
  begin
    LColumn := FColumns[I];
    LWidth := MeasureTextWidth(LColumn.Caption, HeadFontSize, False);
    for J := 0 to FRows.Count - 1 do
    begin
      LText := FRows[J].CellText(I);
      case LColumn.Kind of
        ckCheckbox: LRowW := CheckSize;
        ckAvatar:
          begin
            DaisySplitCell(LText, LTitle, LSub);
            LRowW := AvatarSize + 12 +
              Max(MeasureTextWidth(LTitle, FontSize, True), MeasureTextWidth(LSub, HeadFontSize, False));
          end;
        ckBadge: LRowW := MeasureTextWidth(LText, DaisyBadgeFontSize(BadgeSize), False) + 16;
        ckButton: LRowW := MeasureTextWidth(LText, HeadFontSize, False) + 20;
      else
        LRowW := MeasureTextWidth(LText, FontSize, False);
      end;
      LWidth := Max(LWidth, LRowW);
    end;
    if LColumn.Kind = ckCheckbox then
      LWidth := Max(LWidth, CheckSize);
    FNatural[I] := Ceil(LWidth) + 2 * PadX;
  end;
  FNaturalValid := True;
end;

function TDaisyFmxTable.ColumnWidths: TArray<Single>;
var
  LNatural, LFixed: TArray<Single>;
  I: Integer;
begin
  EnsureNatural;
  SetLength(LNatural, FColumns.Count);
  SetLength(LFixed, FColumns.Count);
  for I := 0 to FColumns.Count - 1 do
  begin
    LNatural[I] := FNatural[I];
    LFixed[I] := FColumns[I].Width;
  end;
  Result := DaisyTableColumnWidths(LNatural, LFixed, Area.Width);
end;

function TDaisyFmxTable.Mirror(const ARect: TRectF): TRectF;
var
  LArea: TRectF;
begin
  if not FRightToLeft then
    Exit(ARect);
  LArea := Area;
  Result := RectF(LArea.Left + LArea.Right - ARect.Right, ARect.Top,
    LArea.Left + LArea.Right - ARect.Left, ARect.Bottom);
end;

// Final column positions (area relative, before mirroring): scrolling and pinning applied
procedure TDaisyFmxTable.ColumnPositions(out AX, AW: TArray<Single>);
var
  I: Integer;
  LTotal, LLeft, LRight, LArea: Single;
begin
  AW := ColumnWidths;
  SetLength(AX, Length(AW));
  LTotal := 0;
  for I := 0 to High(AW) do
  begin
    AX[I] := LTotal - FScrollX;
    LTotal := LTotal + AW[I];
  end;
  LArea := Area.Width;
  LLeft := 0;
  LRight := 0;
  for I := 0 to High(AW) do
    if FColumns[I].Pinned and (AX[I] + FScrollX + AW[I] / 2 < LTotal / 2) then
    begin
      AX[I] := Max(AX[I], LLeft);
      LLeft := LLeft + AW[I];
    end;
  for I := High(AW) downto 0 do
    if FColumns[I].Pinned and (AX[I] + FScrollX + AW[I] / 2 >= LTotal / 2) then
    begin
      AX[I] := Min(AX[I], LArea - LRight - AW[I]);
      LRight := LRight + AW[I];
    end;
end;

function TDaisyFmxTable.RowTop(ARow: Integer): Single;
var
  LArea: TRectF;
begin
  LArea := Area;
  case ARow of
    -1:
      if FPinRows then
        Result := LArea.Top
      else
        Result := LArea.Top - FScrollY;
    -2:
      if FPinRows then
        Result := LArea.Top + Min(LArea.Height, ContentHeight) - FooterHeight
      else
        Result := LArea.Top + HeaderHeight + FRows.Count * RowHeight - FScrollY;
  else
    Result := LArea.Top + HeaderHeight + ARow * RowHeight - FScrollY;
  end;
end;

function TDaisyFmxTable.RowBackground(ARow: Integer): TAlphaColor;
begin
  Result := TAlphaColors.Null;
  if FZebra and Odd(ARow) then
    Result := Theme.Base200;
  if FRows[ARow].Active then
    Result := Theme.Base200;
  if FHoverRows and (ARow = FHotRow) then
    Result := Theme.Base300;
end;

function TDaisyFmxTable.EffectiveAlign(AColumn: TDaisyTableColumn): TDaisyTextAlign;
begin
  Result := AColumn.Alignment;
  if FRightToLeft then
    case Result of
      taStart: Result := taEnd;
      taEnd: Result := taStart;
    end;
end;

function TDaisyFmxTable.CheckRect(const ACell: TRectF; AAlign: TDaisyTextAlign): TRectF;
var
  LSize, LX: Single;
begin
  LSize := CheckSize;
  case AAlign of
    taEnd: LX := ACell.Right - PadX - LSize;
    taCenter: LX := ACell.Left + (ACell.Width - LSize) / 2;
  else
    LX := ACell.Left + PadX;
  end;
  Result := RectF(LX, ACell.Top + (ACell.Height - LSize) / 2, LX + LSize,
    ACell.Top + (ACell.Height - LSize) / 2 + LSize);
end;

function TDaisyFmxTable.ButtonRect(const ACell: TRectF; const AText: string): TRectF;
var
  LW, LH, LX: Single;
begin
  LW := MeasureTextWidth(AText, HeadFontSize, False) + 20;
  LH := DaisyFieldHeight(dzXS);
  LX := ACell.Left + PadX;
  Result := RectF(LX, ACell.Top + (ACell.Height - LH) / 2, LX + LW,
    ACell.Top + (ACell.Height - LH) / 2 + LH);
end;

function TDaisyFmxTable.BadgeRect(const ACell: TRectF; const AText: string;
  AAlign: TDaisyTextAlign): TRectF;
var
  LW, LH, LX: Single;
begin
  LW := MeasureTextWidth(AText, DaisyBadgeFontSize(BadgeSize), False) + 16;
  LH := DaisyBadgeHeight(BadgeSize);
  case AAlign of
    taEnd: LX := ACell.Right - PadX - LW;
    taCenter: LX := ACell.Left + (ACell.Width - LW) / 2;
  else
    LX := ACell.Left + PadX;
  end;
  Result := RectF(LX, ACell.Top + (ACell.Height - LH) / 2, LX + LW,
    ACell.Top + (ACell.Height - LH) / 2 + LH);
end;

function TDaisyFmxTable.ButtonColors(ARow, ACol: Integer): TDaisyColors;
var
  LVariant: TDaisyVariant;
  LState: TDaisyState;
begin
  LVariant := FColumns[ACol].Variant;
  if (ARow >= 0) and (FRows[ARow].Variant <> dvDefault) then
    LVariant := FRows[ARow].Variant;
  if (ARow = FHotRow) and (ACol = FHotCol) then
    LState := dstHover
  else
    LState := dstNormal;
  Result := DaisyResolveColors(Theme, LVariant, dsGhost, LState);
end;

{ hit testing }

function TDaisyFmxTable.HitCell(X, Y: Single): TCellHit;
var
  LX, LW: TArray<Single>;
  LArea: TRectF;
  I, LRow, LPass: Integer;
  LRect: TRectF;
  LOffset: Single;
begin
  Result.Row := CNoHit;
  Result.Col := -1;
  LArea := Area;
  if not LArea.Contains(PointF(X, Y)) then
    Exit;
  if FShowHeader and (Y >= RowTop(-1)) and (Y < RowTop(-1) + HeaderHeight) and
    (FPinRows or (Y >= LArea.Top)) then
    Result.Row := -1
  else if FShowFooter and (Y >= RowTop(-2)) and (Y < RowTop(-2) + FooterHeight) then
    Result.Row := -2
  else
  begin
    LOffset := Y - LArea.Top - HeaderHeight + FScrollY;
    LRow := Trunc(LOffset / RowHeight);
    if (LOffset >= 0) and (LRow < FRows.Count) and
      (RowTop(LRow) + RowHeight > LArea.Top + IfThen(FPinRows, HeaderHeight, 0)) then
      Result.Row := LRow;
  end;
  if Result.Row = CNoHit then
    Exit;
  ColumnPositions(LX, LW);
  for LPass := 0 to 1 do // pinned columns are drawn on top, so they are hit first
    for I := 0 to High(LW) do
      if FColumns[I].Pinned = (LPass = 0) then
      begin
        LRect := Mirror(RectF(LArea.Left + LX[I], 0, LArea.Left + LX[I] + LW[I], 1));
        if (X >= LRect.Left) and (X < LRect.Right) then
        begin
          Result.Col := I;
          Exit;
        end;
      end;
end;

function TDaisyFmxTable.CellRect(const AHit: TCellHit): TRectF;
var
  LX, LW: TArray<Single>;
begin
  ColumnPositions(LX, LW);
  Result := Mirror(RectF(Area.Left + LX[AHit.Col], RowTop(AHit.Row),
    Area.Left + LX[AHit.Col] + LW[AHit.Col], RowTop(AHit.Row) + RowHeight));
end;

procedure TDaisyFmxTable.SetHot(ARow, ACol: Integer);
begin
  if (FHotRow <> ARow) or (FHotCol <> ACol) then
  begin
    FHotRow := ARow;
    FHotCol := ACol;
    Repaint;
  end;
end;

procedure TDaisyFmxTable.SetScroll(AX, AY: Single);
var
  LX, LY: Single;
begin
  LX := EnsureRange(AX, 0, MaxScrollX);
  LY := EnsureRange(AY, 0, MaxScrollY);
  if (LX <> FScrollX) or (LY <> FScrollY) then
  begin
    FScrollX := LX;
    FScrollY := LY;
    Repaint;
  end;
end;

procedure TDaisyFmxTable.UpdateSize;
var
  LHeight: Single;
begin
  if (not FAutoHeight) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := ContentHeight + 2 * Inset;
  if SameValue(LHeight, Height) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxTable.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LHit: TCellHit;
  LHand: Boolean;
  LCell: TRectF;
begin
  inherited;
  LHit := HitCell(X, Y);
  SetHot(LHit.Row, LHit.Col);
  LHand := False;
  if (LHit.Row >= 0) and (LHit.Col >= 0) and (FColumns[LHit.Col].Kind in [ckCheckbox, ckButton]) then
  begin
    LCell := CellRect(LHit);
    if FColumns[LHit.Col].Kind = ckButton then
      LHand := ButtonRect(LCell, FRows[LHit.Row].CellText(LHit.Col)).Contains(PointF(X, Y))
    else
      LHand := CheckRect(LCell, EffectiveAlign(FColumns[LHit.Col])).Contains(PointF(X, Y));
  end
  else if (LHit.Row = -1) and (LHit.Col >= 0) and (FColumns[LHit.Col].Kind = ckCheckbox) then
    LHand := True;
  if LHand then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TDaisyFmxTable.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LHit: TCellHit;
  LCell: TRectF;
  LAll: Boolean;
  I: Integer;
begin
  inherited;
  if Button <> TMouseButton.mbLeft then
    Exit;
  LHit := HitCell(X, Y);
  if LHit.Row = CNoHit then
    Exit;
  if (LHit.Row = -1) and (LHit.Col >= 0) and (FColumns[LHit.Col].Kind = ckCheckbox) then
  begin
    LAll := FRows.Count > 0;
    for I := 0 to FRows.Count - 1 do
      LAll := LAll and FRows[I].Checked;
    FRows.BeginUpdate;
    try
      for I := 0 to FRows.Count - 1 do
        FRows[I].Checked := not LAll;
    finally
      FRows.EndUpdate;
    end;
    Exit;
  end;
  if LHit.Row < 0 then
    Exit;
  if LHit.Col >= 0 then
  begin
    LCell := CellRect(LHit);
    case FColumns[LHit.Col].Kind of
      ckCheckbox:
        if CheckRect(LCell, EffectiveAlign(FColumns[LHit.Col])).Contains(PointF(X, Y)) then
        begin
          FRows[LHit.Row].Checked := not FRows[LHit.Row].Checked;
          Exit;
        end;
      ckButton:
        if ButtonRect(LCell, FRows[LHit.Row].CellText(LHit.Col)).Contains(PointF(X, Y)) then
        begin
          if Assigned(FOnButtonClick) then
            FOnButtonClick(Self, LHit.Row, LHit.Col);
          Exit;
        end;
    end;
  end;
  if Assigned(FOnRowClick) then
    FOnRowClick(Self, LHit.Row);
end;

procedure TDaisyFmxTable.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  LStep: Single;
begin
  inherited;
  if Handled then
    Exit;
  LStep := -(WheelDelta / 120) * RowHeight;
  if (ssShift in Shift) or (MaxScrollY = 0) then
  begin
    if MaxScrollX > 0 then
    begin
      SetScroll(FScrollX + LStep, FScrollY);
      Handled := True;
    end;
  end
  else
  begin
    SetScroll(FScrollX, FScrollY + LStep);
    Handled := True;
  end;
end;

{ drawing }

procedure TDaisyFmxTable.DrawCheck(const ARect: TRectF; AChecked: Boolean);
var
  LPaths: TDaisyIconPaths;
begin
  if AChecked then
  begin
    FillRound(ARect, Theme.RadiusSelector, Theme.BaseContent);
    SetLength(LPaths, 1);
    LPaths[0] := [PointF(5, 12.5), PointF(10, 17), PointF(19, 7.5)];
    DrawPolylines(LPaths, ARect, Theme.Base100, 2);
  end
  else
    StrokeRound(ARect, Theme.RadiusSelector, DaisyWithAlpha(Theme.BaseContent, 0.3),
      Max(1, Theme.BorderWidth), False);
end;

procedure TDaisyFmxTable.DrawCell(ARow, ACol: Integer; const ACell: TRectF; AHeader: Boolean);
var
  LColumn: TDaisyTableColumn;
  LText, LTitle, LSub, LInitial: string;
  LAlign: TDaisyTextAlign;
  LHorz: TTextAlign;
  LTextBox, LBox, LCircle: TRectF;
  LColors: TDaisyColors;
  LDim, LInk: TAlphaColor;
  LAll, LRight: Boolean;
  I: Integer;
  LGap, LHalf: Single;
begin
  LColumn := FColumns[ACol];
  LAlign := EffectiveAlign(LColumn);
  LHorz := ToTextAlign(LAlign);
  LDim := DaisyWithAlpha(Theme.BaseContent, 0.6);
  LInk := Theme.BaseContent;
  LTextBox := ACell;
  LTextBox.Inflate(-PadX, 0);

  if AHeader then
  begin
    if LColumn.Kind = ckCheckbox then
    begin
      LAll := FRows.Count > 0;
      for I := 0 to FRows.Count - 1 do
        LAll := LAll and FRows[I].Checked;
      DrawCheck(CheckRect(ACell, LAlign), LAll);
    end
    else
      DrawText(LColumn.Caption, LTextBox, LDim, HeadFontSize, False, LHorz, TTextAlign.Center, False);
    Exit;
  end;

  LText := FRows[ARow].CellText(ACol);
  case LColumn.Kind of
    ckCheckbox:
      DrawCheck(CheckRect(ACell, LAlign), FRows[ARow].Checked);
    ckAvatar:
      begin
        DaisySplitCell(LText, LTitle, LSub);
        LRight := LAlign = taEnd;
        LGap := 12;
        if LRight then
          LCircle := RectF(ACell.Right - PadX - AvatarSize, ACell.Top + (ACell.Height - AvatarSize) / 2,
            ACell.Right - PadX, ACell.Top + (ACell.Height - AvatarSize) / 2 + AvatarSize)
        else
          LCircle := RectF(ACell.Left + PadX, ACell.Top + (ACell.Height - AvatarSize) / 2,
            ACell.Left + PadX + AvatarSize, ACell.Top + (ACell.Height - AvatarSize) / 2 + AvatarSize);
        FillRound(LCircle, AvatarSize / 2, Theme.Base200);
        if not FRows[ARow].Icon.IsEmpty then
        begin
          LBox := LCircle;
          LBox.Inflate(-6, -6);
          DrawGlyph(FRows[ARow].Icon, LBox, LInk);
        end
        else
        begin
          LInitial := Copy(LTitle, 1, 1);
          DrawText(LInitial, LCircle, LInk, FontSize, True, TTextAlign.Center, TTextAlign.Center, False);
        end;
        if LRight then
          LTextBox := RectF(ACell.Left + PadX, ACell.Top, LCircle.Left - LGap, ACell.Bottom)
        else
          LTextBox := RectF(LCircle.Right + LGap, ACell.Top, ACell.Right - PadX, ACell.Bottom);
        if LRight then
          LHorz := TTextAlign.Trailing
        else
          LHorz := TTextAlign.Leading;
        LHalf := LineHeight;
        if LSub = '' then
          DrawText(LTitle, LTextBox, LInk, FontSize, True, LHorz, TTextAlign.Center, False)
        else
        begin
          LBox := RectF(LTextBox.Left, ACell.Top + (ACell.Height - 2 * LHalf) / 2, LTextBox.Right,
            ACell.Top + (ACell.Height - 2 * LHalf) / 2 + LHalf);
          DrawText(LTitle, LBox, LInk, FontSize, True, LHorz, TTextAlign.Center, False);
          LBox.Offset(0, LHalf);
          DrawText(LSub, LBox, LDim, HeadFontSize, False, LHorz, TTextAlign.Center, False);
        end;
      end;
    ckBadge:
      if LText <> '' then
      begin
        LBox := BadgeRect(ACell, LText, LAlign);
        if FRows[ARow].Variant <> dvDefault then
          LColors := DaisyBadgeColors(Theme, FRows[ARow].Variant, dsSolid)
        else if LColumn.Variant <> dvDefault then
          LColors := DaisyBadgeColors(Theme, LColumn.Variant, dsSolid)
        else
          LColors := DaisyBadgeColors(Theme, dvDefault, dsGhost);
        DrawBadgeShape(LBox, LColors, LBox.Height / 2);
        DrawText(LText, LBox, LColors.Text, DaisyBadgeFontSize(BadgeSize), False,
          TTextAlign.Center, TTextAlign.Center, False);
      end;
    ckButton:
      if LText <> '' then
      begin
        LBox := ButtonRect(ACell, LText);
        LColors := ButtonColors(ARow, ACol);
        DrawBadgeShape(LBox, LColors, Theme.RadiusField);
        DrawText(LText, LBox, LColors.Text, HeadFontSize, False, TTextAlign.Center,
          TTextAlign.Center, False);
      end;
  else
    DrawText(LText, LTextBox, LInk, FontSize, False, LHorz, TTextAlign.Center, False);
  end;
end;

// One column of the visible rows. Pinned columns first get an opaque backdrop.
procedure TDaisyFmxTable.DrawColumnCells(ACol: Integer; AX, AW: Single);
var
  LArea, LCell: TRectF;
  R: Integer;
  LTop: Single;
begin
  LArea := Area;
  for R := 0 to FRows.Count - 1 do
  begin
    LTop := RowTop(R);
    if (LTop + RowHeight < LArea.Top) or (LTop > LArea.Bottom) then
      Continue;
    LCell := Mirror(RectF(LArea.Left + AX, LTop, LArea.Left + AX + AW, LTop + RowHeight));
    if FColumns[ACol].Pinned then
    begin
      FillRound(LCell, 0, Theme.Base100);
      FillRound(LCell, 0, RowBackground(R));
      FillRound(RectF(LCell.Left, LCell.Bottom - 1, LCell.Right, LCell.Bottom), 0,
        DaisyWithAlpha(Theme.BaseContent, 0.08));
    end;
    DrawCell(R, ACol, LCell, False);
  end;
end;

procedure TDaisyFmxTable.DrawBand(AHeader: Boolean; const AX, AW: TArray<Single>);
var
  LArea, LBand, LCell: TRectF;
  I, LRow, LPass: Integer;
begin
  LArea := Area;
  if AHeader then
    LRow := -1
  else
    LRow := -2;
  LBand := RectF(LArea.Left, RowTop(LRow), LArea.Right, 0);
  LBand.Bottom := LBand.Top + IfThen(AHeader, HeaderHeight, FooterHeight);
  if (LBand.Bottom < LArea.Top) or (LBand.Top > LArea.Bottom) then
    Exit;
  if FPinRows then
    FillRound(LBand, 0, Theme.Base100);
  if AHeader then
    FillRound(RectF(LBand.Left, LBand.Bottom - 1, LBand.Right, LBand.Bottom), 0,
      DaisyWithAlpha(Theme.BaseContent, 0.1))
  else
    FillRound(RectF(LBand.Left, LBand.Top, LBand.Right, LBand.Top + 1), 0,
      DaisyWithAlpha(Theme.BaseContent, 0.1));
  for LPass := 0 to 1 do
    for I := 0 to High(AW) do
      if FColumns[I].Pinned = (LPass = 1) then
      begin
        LCell := Mirror(RectF(LArea.Left + AX[I], LBand.Top, LArea.Left + AX[I] + AW[I], LBand.Bottom));
        if FColumns[I].Pinned then
          FillRound(LCell, 0, Theme.Base100);
        DrawCell(-1, I, LCell, True);
      end;
end;

procedure TDaisyFmxTable.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LArea, LTrack: TRectF;
  LX, LW: TArray<Single>;
  R, LPass: Integer;
  LTop, LBar: Single;
  LColor: TAlphaColor;
  LState: TCanvasSaveState;
begin
  LArea := Area;
  if FColumns.Count = 0 then
    Exit;
  ColumnPositions(LX, LW);

  LState := Canvas.SaveState;
  try
    Canvas.IntersectClipRect(LArea);

    for R := 0 to FRows.Count - 1 do
    begin
      LTop := RowTop(R);
      if (LTop + RowHeight < LArea.Top) or (LTop > LArea.Bottom) then
        Continue;
      LColor := RowBackground(R);
      FillRound(RectF(LArea.Left, LTop, LArea.Right, LTop + RowHeight), 0, LColor);
      if (not FZebra) and ((R < FRows.Count - 1) or FShowFooter) then
        FillRound(RectF(LArea.Left, LTop + RowHeight - 1, LArea.Right, LTop + RowHeight), 0,
          DaisyWithAlpha(Theme.BaseContent, 0.08));
    end;

    for LPass := 0 to 1 do
      for R := 0 to High(LW) do
        if FColumns[R].Pinned = (LPass = 1) then
          DrawColumnCells(R, LX[R], LW[R]);
  finally
    Canvas.RestoreState(LState);
  end;

  LState := Canvas.SaveState;
  try
    Canvas.IntersectClipRect(LArea);
    if FShowHeader then
      DrawBand(True, LX, LW);
    if FShowFooter then
      DrawBand(False, LX, LW);

    // Thin scroll indicators
    LBar := 4;
    if MaxScrollY > 0 then
    begin
      LTrack := RectF(LArea.Right - LBar - 2, LArea.Top + HeaderHeight + FScrollY / MaxScrollY *
        (LArea.Height - HeaderHeight - FooterHeight) * 0.7, LArea.Right - 2, 0);
      LTrack.Bottom := LTrack.Top + (LArea.Height - HeaderHeight - FooterHeight) * 0.3;
      FillRound(LTrack, LBar / 2, DaisyWithAlpha(Theme.BaseContent, 0.3));
    end;
    if MaxScrollX > 0 then
    begin
      LTrack := RectF(LArea.Left + FScrollX / MaxScrollX * LArea.Width * 0.7, LArea.Bottom - LBar - 2,
        0, LArea.Bottom - 2);
      LTrack.Right := LTrack.Left + LArea.Width * 0.3;
      FillRound(LTrack, LBar / 2, DaisyWithAlpha(Theme.BaseContent, 0.3));
    end;
  finally
    Canvas.RestoreState(LState);
  end;
end;

end.
