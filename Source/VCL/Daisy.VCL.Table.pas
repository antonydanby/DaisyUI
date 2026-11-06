unit Daisy.VCL.Table;

{
  TDaisyTable - the DaisyUI "table": columns and rows of text, checkboxes,
  avatars, badges and buttons, with optional zebra stripes, hover and active
  rows, a footer, pinned header / footer rows, pinned columns and a right to
  left layout. Cells may hold emoji (drawn in colour); avatars may hold SVG.

  The table is drawn, not built from child controls. The mouse wheel scrolls it
  (Shift + wheel scrolls sideways) when the content is larger than the control.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Daisy.Theme, Daisy.Widgets, Daisy.Tables, Daisy.VCL.Control;

type
  TDaisyTable = class(TDaisyControl)
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
    FScrollX, FScrollY: Integer;
    FNatural: TArray<Integer>;
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
    function Inset: Integer;
    function Area: TRect;
    function FontSize: Integer;
    function HeadFontSize: Integer;
    function PadX: Integer;
    function PadY: Integer;
    function LineHeight: Integer;
    function AvatarSize: Integer;
    function CheckSize: Integer;
    function BadgeSize: TDaisySize;
    function HasAvatar: Boolean;
    function RowHeight: Integer;
    function HeaderHeight: Integer;
    function FooterHeight: Integer;
    function ContentHeight: Integer;
    function MaxScrollX: Integer;
    function MaxScrollY: Integer;
    procedure EnsureNatural;
    function ColumnWidths: TArray<Integer>;
    procedure ColumnPositions(out AX, AW: TArray<Integer>);
    function Mirror(const ARect: TRect): TRect;
    function RowTop(ARow: Integer): Integer;
    function RowBackground(ARow: Integer): TAlphaColor;
    function ButtonColors(ARow, ACol: Integer): TDaisyColors;
    function EffectiveAlign(AColumn: TDaisyTableColumn): TDaisyTextAlign;
    function CheckRect(const ACell: TRect; AAlign: TDaisyTextAlign): TRect;
    function ButtonRect(const ACell: TRect; const AText: string): TRect;
    function BadgeRect(const ACell: TRect; const AText: string; AAlign: TDaisyTextAlign): TRect;
    function HitCell(X, Y: Integer): TCellHit;
    procedure SetHot(ARow, ACol: Integer);
    procedure SetScroll(AX, AY: Integer);
    procedure DrawCheck(const ARect: TRect; AChecked: Boolean);
    procedure DrawCell(ARow, ACol: Integer; const ACell: TRect; AHeader: Boolean);
    procedure DrawColumnCells(ACol, AX, AW: Integer);
    procedure DrawBand(AHeader: Boolean; const AX, AW: TArray<Integer>);
    procedure UpdateSize;
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
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
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

{ TDaisyTable }

constructor TDaisyTable.Create(AOwner: TComponent);
var
  LRow: TDaisyTableRow;
begin
  inherited Create(AOwner);
  FShowHeader := True;
  FAutoHeight := True;
  FHotRow := CNoHit;
  FHotCol := -1;
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
  SetBounds(Left, Top, 480, 150);
  UpdateSize;
end;

destructor TDaisyTable.Destroy;
begin
  FRows.Free;
  FColumns.Free;
  inherited Destroy;
end;

function TDaisyTable.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyTable.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyTable.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyTable.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
  if FBordered then
  begin
    Result.Background := Theme.Base100;
    Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.12);
  end;
end;

procedure TDaisyTable.SetColumns(const Value: TDaisyTableColumns);
begin
  FColumns.Assign(Value);
end;

procedure TDaisyTable.SetRows(const Value: TDaisyTableRows);
begin
  FRows.Assign(Value);
end;

procedure TDaisyTable.SetShowHeader(const Value: Boolean);
begin
  if FShowHeader <> Value then
  begin
    FShowHeader := Value;
    Relayout;
  end;
end;

procedure TDaisyTable.SetShowFooter(const Value: Boolean);
begin
  if FShowFooter <> Value then
  begin
    FShowFooter := Value;
    Relayout;
  end;
end;

procedure TDaisyTable.SetZebra(const Value: Boolean);
begin
  if FZebra <> Value then
  begin
    FZebra := Value;
    Invalidate;
  end;
end;

procedure TDaisyTable.SetHoverRows(const Value: Boolean);
begin
  if FHoverRows <> Value then
  begin
    FHoverRows := Value;
    Invalidate;
  end;
end;

procedure TDaisyTable.SetBordered(const Value: Boolean);
begin
  if FBordered <> Value then
  begin
    FBordered := Value;
    Relayout;
  end;
end;

procedure TDaisyTable.SetRightToLeft(const Value: Boolean);
begin
  if FRightToLeft <> Value then
  begin
    FRightToLeft := Value;
    Invalidate;
  end;
end;

procedure TDaisyTable.SetPinRows(const Value: Boolean);
begin
  if FPinRows <> Value then
  begin
    FPinRows := Value;
    Invalidate;
  end;
end;

procedure TDaisyTable.SetAutoHeight(const Value: Boolean);
begin
  if FAutoHeight <> Value then
  begin
    FAutoHeight := Value;
    Relayout;
  end;
end;

procedure TDaisyTable.ModelChanged(Sender: TObject);
begin
  Relayout;
end;

procedure TDaisyTable.Relayout;
begin
  FNaturalValid := False;
  UpdateSize;
  SetScroll(FScrollX, FScrollY);
  Invalidate;
end;

procedure TDaisyTable.SizeChanged;
begin
  Relayout;
end;

procedure TDaisyTable.Loaded;
begin
  inherited;
  Relayout;
end;

procedure TDaisyTable.Resize;
begin
  inherited;
  SetScroll(FScrollX, FScrollY);
end;

procedure TDaisyTable.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Relayout;
end;

procedure TDaisyTable.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHot(CNoHit, -1);
  Cursor := crDefault;
end;

{ metrics }

function TDaisyTable.Inset: Integer;
begin
  if FBordered then
    Result := Max(1, ScaleValue(Theme.BorderWidth))
  else
    Result := 0;
end;

function TDaisyTable.Area: TRect;
begin
  Result := Rect(0, 0, Width, Height);
  InflateRect(Result, -Inset, -Inset);
end;

function TDaisyTable.FontSize: Integer;
begin
  Result := DaisyFontSize(SizeKind);
end;

function TDaisyTable.HeadFontSize: Integer;
begin
  Result := Max(10, FontSize - 2);
end;

function TDaisyTable.PadX: Integer;
const
  C: array[TDaisySize] of Integer = (8, 12, 16, 20, 24);
begin
  Result := ScaleValue(C[SizeKind]);
end;

function TDaisyTable.PadY: Integer;
const
  C: array[TDaisySize] of Integer = (4, 8, 12, 16, 20);
begin
  Result := ScaleValue(C[SizeKind]);
end;

function TDaisyTable.LineHeight: Integer;
begin
  Result := Round(ScaleValue(FontSize) * 1.4);
end;

function TDaisyTable.AvatarSize: Integer;
begin
  Result := ScaleValue(DaisyFieldHeight(SizeKind) + 8);
end;

function TDaisyTable.CheckSize: Integer;
begin
  Result := ScaleValue(FontSize + 6);
end;

function TDaisyTable.BadgeSize: TDaisySize;
begin
  if SizeKind >= dzMD then
    Result := dzSM
  else
    Result := dzXS;
end;

function TDaisyTable.HasAvatar: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FColumns.Count - 1 do
    if FColumns[I].Kind = ckAvatar then
      Exit(True);
end;

function TDaisyTable.RowHeight: Integer;
begin
  if HasAvatar then
    Result := AvatarSize + 2 * PadY
  else
    Result := LineHeight + 2 * PadY;
end;

function TDaisyTable.HeaderHeight: Integer;
begin
  if FShowHeader then
    Result := LineHeight + 2 * PadY
  else
    Result := 0;
end;

function TDaisyTable.FooterHeight: Integer;
begin
  if FShowFooter then
    Result := LineHeight + 2 * PadY
  else
    Result := 0;
end;

function TDaisyTable.ContentHeight: Integer;
begin
  Result := HeaderHeight + FRows.Count * RowHeight + FooterHeight;
end;

function TDaisyTable.MaxScrollX: Integer;
var
  LWidths: TArray<Integer>;
  LTotal, I: Integer;
begin
  LWidths := ColumnWidths;
  LTotal := 0;
  for I := 0 to High(LWidths) do
    Inc(LTotal, LWidths[I]);
  Result := Max(0, LTotal - Area.Width);
end;

function TDaisyTable.MaxScrollY: Integer;
begin
  Result := Max(0, ContentHeight - Area.Height);
end;

procedure TDaisyTable.EnsureNatural;
var
  I, J, LWidth, LRowW: Integer;
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
            LRowW := AvatarSize + ScaleValue(12) +
              Max(MeasureTextWidth(LTitle, FontSize, True), MeasureTextWidth(LSub, HeadFontSize, False));
          end;
        ckBadge: LRowW := MeasureTextWidth(LText, DaisyBadgeFontSize(BadgeSize), False) + ScaleValue(16);
        ckButton: LRowW := MeasureTextWidth(LText, HeadFontSize, False) + ScaleValue(20);
      else
        LRowW := MeasureTextWidth(LText, FontSize, False);
      end;
      LWidth := Max(LWidth, LRowW);
    end;
    if (LColumn.Kind = ckCheckbox) then
      LWidth := Max(LWidth, CheckSize);
    FNatural[I] := LWidth + 2 * PadX;
  end;
  FNaturalValid := True;
end;

function TDaisyTable.ColumnWidths: TArray<Integer>;
var
  LNatural, LFixed, LShared: TArray<Single>;
  I: Integer;
begin
  EnsureNatural;
  SetLength(LNatural, FColumns.Count);
  SetLength(LFixed, FColumns.Count);
  for I := 0 to FColumns.Count - 1 do
  begin
    LNatural[I] := FNatural[I];
    LFixed[I] := ScaleValue(FColumns[I].Width);
  end;
  LShared := DaisyTableColumnWidths(LNatural, LFixed, Area.Width);
  SetLength(Result, Length(LShared));
  for I := 0 to High(LShared) do
    Result[I] := Round(LShared[I]);
end;

function TDaisyTable.Mirror(const ARect: TRect): TRect;
var
  LArea: TRect;
begin
  if not FRightToLeft then
    Exit(ARect);
  LArea := Area;
  Result := Rect(LArea.Left + LArea.Right - ARect.Right, ARect.Top,
    LArea.Left + LArea.Right - ARect.Left, ARect.Bottom);
end;

// Final column positions (area relative, before any mirroring): scrolling and pinning applied
procedure TDaisyTable.ColumnPositions(out AX, AW: TArray<Integer>);
var
  I, LX, LTotal, LLeft, LRight, LArea: Integer;
begin
  AW := ColumnWidths;
  SetLength(AX, Length(AW));
  LTotal := 0;
  for I := 0 to High(AW) do
  begin
    AX[I] := LTotal - FScrollX;
    Inc(LTotal, AW[I]);
  end;
  LArea := Area.Width;
  LLeft := 0;
  LRight := 0;
  for I := 0 to High(AW) do
    if FColumns[I].Pinned and (AX[I] + FScrollX + AW[I] div 2 < LTotal div 2) then
    begin
      AX[I] := Max(AX[I], LLeft);
      Inc(LLeft, AW[I]);
    end;
  for I := High(AW) downto 0 do
    if FColumns[I].Pinned and (AX[I] + FScrollX + AW[I] div 2 >= LTotal div 2) then
    begin
      LX := LArea - LRight - AW[I];
      AX[I] := Min(AX[I], LX);
      Inc(LRight, AW[I]);
    end;
end;

function TDaisyTable.RowTop(ARow: Integer): Integer;
var
  LArea: TRect;
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

function TDaisyTable.RowBackground(ARow: Integer): TAlphaColor;
begin
  Result := TAlphaColors.Null;
  if FZebra and Odd(ARow) then
    Result := Theme.Base200;
  if FRows[ARow].Active then
    Result := Theme.Base200;
  if FHoverRows and (ARow = FHotRow) then
    Result := Theme.Base300;
end;

function TDaisyTable.EffectiveAlign(AColumn: TDaisyTableColumn): TDaisyTextAlign;
begin
  Result := AColumn.Alignment;
  if FRightToLeft then
    case Result of
      taStart: Result := taEnd;
      taEnd: Result := taStart;
    end;
end;

function TDaisyTable.CheckRect(const ACell: TRect; AAlign: TDaisyTextAlign): TRect;
var
  LSize, LX: Integer;
begin
  LSize := CheckSize;
  case AAlign of
    taEnd: LX := ACell.Right - PadX - LSize;
    taCenter: LX := ACell.Left + (ACell.Width - LSize) div 2;
  else
    LX := ACell.Left + PadX;
  end;
  Result := Rect(LX, ACell.Top + (ACell.Height - LSize) div 2, LX + LSize,
    ACell.Top + (ACell.Height - LSize) div 2 + LSize);
end;

function TDaisyTable.ButtonRect(const ACell: TRect; const AText: string): TRect;
var
  LW, LH, LX: Integer;
begin
  LW := MeasureTextWidth(AText, HeadFontSize, False) + ScaleValue(20);
  LH := ScaleValue(DaisyFieldHeight(dzXS));
  LX := ACell.Left + PadX;
  Result := Rect(LX, ACell.Top + (ACell.Height - LH) div 2, LX + LW,
    ACell.Top + (ACell.Height - LH) div 2 + LH);
end;

function TDaisyTable.BadgeRect(const ACell: TRect; const AText: string;
  AAlign: TDaisyTextAlign): TRect;
var
  LW, LH, LX: Integer;
begin
  LW := MeasureTextWidth(AText, DaisyBadgeFontSize(BadgeSize), False) + ScaleValue(16);
  LH := ScaleValue(DaisyBadgeHeight(BadgeSize));
  case AAlign of
    taEnd: LX := ACell.Right - PadX - LW;
    taCenter: LX := ACell.Left + (ACell.Width - LW) div 2;
  else
    LX := ACell.Left + PadX;
  end;
  Result := Rect(LX, ACell.Top + (ACell.Height - LH) div 2, LX + LW,
    ACell.Top + (ACell.Height - LH) div 2 + LH);
end;

function TDaisyTable.ButtonColors(ARow, ACol: Integer): TDaisyColors;
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

function TDaisyTable.HitCell(X, Y: Integer): TCellHit;
var
  LX, LW: TArray<Integer>;
  LArea: TRect;
  I, LRow: Integer;
  LRect: TRect;
  LPass: Integer;
begin
  Result.Row := CNoHit;
  Result.Col := -1;
  LArea := Area;
  if not PtInRect(LArea, Point(X, Y)) then
    Exit;
  if FShowHeader and (Y >= RowTop(-1)) and (Y < RowTop(-1) + HeaderHeight) and
    (FPinRows or (Y >= LArea.Top)) then
    Result.Row := -1
  else if FShowFooter and (Y >= RowTop(-2)) and (Y < RowTop(-2) + FooterHeight) then
    Result.Row := -2
  else
  begin
    LRow := (Y - LArea.Top - HeaderHeight + FScrollY) div RowHeight;
    if (Y - LArea.Top - HeaderHeight + FScrollY >= 0) and (LRow < FRows.Count) and
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
        LRect := Mirror(Rect(LArea.Left + LX[I], 0, LArea.Left + LX[I] + LW[I], 1));
        if (X >= LRect.Left) and (X < LRect.Right) then
        begin
          Result.Col := I;
          Exit;
        end;
      end;
end;

procedure TDaisyTable.SetHot(ARow, ACol: Integer);
begin
  if (FHotRow <> ARow) or (FHotCol <> ACol) then
  begin
    FHotRow := ARow;
    FHotCol := ACol;
    Invalidate;
  end;
end;

procedure TDaisyTable.SetScroll(AX, AY: Integer);
var
  LX, LY: Integer;
begin
  LX := EnsureRange(AX, 0, MaxScrollX);
  LY := EnsureRange(AY, 0, MaxScrollY);
  if (LX <> FScrollX) or (LY <> FScrollY) then
  begin
    FScrollX := LX;
    FScrollY := LY;
    Invalidate;
  end;
end;

procedure TDaisyTable.UpdateSize;
var
  LHeight: Integer;
begin
  if (not FAutoHeight) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := ContentHeight + 2 * Inset;
  if LHeight = Height then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyTable.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LHit: TCellHit;
  LHand: Boolean;
  LX, LW: TArray<Integer>;
  LCell: TRect;
begin
  inherited;
  LHit := HitCell(X, Y);
  SetHot(LHit.Row, LHit.Col);
  LHand := False;
  if (LHit.Row >= 0) and (LHit.Col >= 0) and (FColumns[LHit.Col].Kind in [ckCheckbox, ckButton]) then
  begin
    ColumnPositions(LX, LW);
    LCell := Mirror(Rect(Area.Left + LX[LHit.Col], RowTop(LHit.Row),
      Area.Left + LX[LHit.Col] + LW[LHit.Col], RowTop(LHit.Row) + RowHeight));
    if FColumns[LHit.Col].Kind = ckButton then
      LHand := PtInRect(ButtonRect(LCell, FRows[LHit.Row].CellText(LHit.Col)), Point(X, Y))
    else
      LHand := PtInRect(CheckRect(LCell, EffectiveAlign(FColumns[LHit.Col])), Point(X, Y));
  end
  else if (LHit.Row = -1) and (LHit.Col >= 0) and (FColumns[LHit.Col].Kind = ckCheckbox) then
    LHand := True;
  if LHand then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TDaisyTable.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LHit: TCellHit;
  LX, LW: TArray<Integer>;
  LCell: TRect;
  LAll: Boolean;
  I: Integer;
begin
  inherited;
  if Button <> mbLeft then
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
  ColumnPositions(LX, LW);
  if LHit.Col >= 0 then
  begin
    LCell := Mirror(Rect(Area.Left + LX[LHit.Col], RowTop(LHit.Row),
      Area.Left + LX[LHit.Col] + LW[LHit.Col], RowTop(LHit.Row) + RowHeight));
    case FColumns[LHit.Col].Kind of
      ckCheckbox:
        if PtInRect(CheckRect(LCell, EffectiveAlign(FColumns[LHit.Col])), Point(X, Y)) then
        begin
          FRows[LHit.Row].Checked := not FRows[LHit.Row].Checked;
          Exit;
        end;
      ckButton:
        if PtInRect(ButtonRect(LCell, FRows[LHit.Row].CellText(LHit.Col)), Point(X, Y)) then
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

function TDaisyTable.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  LStep: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result then
    Exit;
  LStep := -(WheelDelta div 120) * RowHeight;
  if (ssShift in Shift) or (MaxScrollY = 0) then
  begin
    if MaxScrollX > 0 then
    begin
      SetScroll(FScrollX + LStep, FScrollY);
      Result := True;
    end;
  end
  else
  begin
    SetScroll(FScrollX, FScrollY + LStep);
    Result := True;
  end;
end;

{ drawing }

procedure TDaisyTable.DrawCheck(const ARect: TRect; AChecked: Boolean);
var
  LGraphics: TGPGraphics;
  LPaths: TDaisyIconPaths;
  LBox: TRectF;
begin
  LBox := RectF(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
  LGraphics := NewGraphics;
  try
    if AChecked then
    begin
      FillRoundRect(LGraphics, LBox, Theme.RadiusSelector, Theme.BaseContent);
      SetLength(LPaths, 1);
      LPaths[0] := [PointF(5, 12.5), PointF(10, 17), PointF(19, 7.5)];
      DrawPolylines(LGraphics, LPaths, LBox, Theme.Base100, 2);
    end
    else
      StrokeRoundRect(LGraphics, LBox, Theme.RadiusSelector,
        DaisyWithAlpha(Theme.BaseContent, 0.3), Max(1, ScaleValue(Theme.BorderWidth)), False);
  finally
    LGraphics.Free;
  end;
end;

procedure TDaisyTable.DrawCell(ARow, ACol: Integer; const ACell: TRect; AHeader: Boolean);
var
  LColumn: TDaisyTableColumn;
  LText, LTitle, LSub: string;
  LAlign: TDaisyTextAlign;
  LFlags: Cardinal;
  LTextBox, LBox, LCircle: TRect;
  LGraphics: TGPGraphics;
  LColors: TDaisyColors;
  LDim, LInk: TAlphaColor;
  LAll, LRight: Boolean;
  I, LGap, LHalf: Integer;
  LInitial: string;
begin
  LColumn := FColumns[ACol];
  LAlign := EffectiveAlign(LColumn);
  LDim := DaisyWithAlpha(Theme.BaseContent, 0.6);
  LInk := Theme.BaseContent;
  LFlags := DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS;
  case LAlign of
    taEnd: LFlags := LFlags or DT_RIGHT;
    taCenter: LFlags := LFlags or DT_CENTER;
  else
    LFlags := LFlags or DT_LEFT;
  end;
  LTextBox := ACell;
  InflateRect(LTextBox, -PadX, 0);

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
      DrawRichText(LColumn.Caption, LTextBox, LDim, HeadFontSize, False, LFlags);
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
        LGap := ScaleValue(12);
        if LRight then
          LCircle := Rect(ACell.Right - PadX - AvatarSize, ACell.Top + (ACell.Height - AvatarSize) div 2,
            ACell.Right - PadX, ACell.Top + (ACell.Height - AvatarSize) div 2 + AvatarSize)
        else
          LCircle := Rect(ACell.Left + PadX, ACell.Top + (ACell.Height - AvatarSize) div 2,
            ACell.Left + PadX + AvatarSize, ACell.Top + (ACell.Height - AvatarSize) div 2 + AvatarSize);
        LGraphics := NewGraphics;
        try
          FillRoundRect(LGraphics, RectF(LCircle.Left, LCircle.Top, LCircle.Right, LCircle.Bottom),
            AvatarSize / 2, Theme.Base200);
        finally
          LGraphics.Free;
        end;
        if not FRows[ARow].Icon.IsEmpty then
        begin
          LBox := LCircle;
          InflateRect(LBox, -ScaleValue(6), -ScaleValue(6));
          DrawGlyph(FRows[ARow].Icon, LBox, LInk);
        end
        else
        begin
          LInitial := Copy(LTitle, 1, 1);
          DrawRichText(LInitial, LCircle, LInk, FontSize, True,
            DT_CENTER or DT_VCENTER or DT_SINGLELINE);
        end;
        if LRight then
          LTextBox := Rect(ACell.Left + PadX, ACell.Top, LCircle.Left - LGap, ACell.Bottom)
        else
          LTextBox := Rect(LCircle.Right + LGap, ACell.Top, ACell.Right - PadX, ACell.Bottom);
        LHalf := LineHeight;
        if LSub = '' then
          DrawRichText(LTitle, LTextBox, LInk, FontSize, True, DT_VCENTER or DT_SINGLELINE or
            DT_END_ELLIPSIS or IfThen(LRight, DT_RIGHT, DT_LEFT))
        else
        begin
          LBox := Rect(LTextBox.Left, ACell.Top + (ACell.Height - 2 * LHalf) div 2, LTextBox.Right,
            ACell.Top + (ACell.Height - 2 * LHalf) div 2 + LHalf);
          DrawRichText(LTitle, LBox, LInk, FontSize, True, DT_VCENTER or DT_SINGLELINE or
            DT_END_ELLIPSIS or IfThen(LRight, DT_RIGHT, DT_LEFT));
          OffsetRect(LBox, 0, LHalf);
          DrawRichText(LSub, LBox, LDim, HeadFontSize, False, DT_VCENTER or DT_SINGLELINE or
            DT_END_ELLIPSIS or IfThen(LRight, DT_RIGHT, DT_LEFT));
        end;
      end;
    ckBadge:
      if LText <> '' then
      begin
        LBox := BadgeRect(ACell, LText, LAlign);
        if (FRows[ARow].Variant <> dvDefault) then
          LColors := DaisyBadgeColors(Theme, FRows[ARow].Variant, dsSolid)
        else if LColumn.Variant <> dvDefault then
          LColors := DaisyBadgeColors(Theme, LColumn.Variant, dsSolid)
        else
          LColors := DaisyBadgeColors(Theme, dvDefault, dsGhost);
        DrawBadgeShape(LBox, LColors, LBox.Height div 2);
        DrawRichText(LText, LBox, LColors.Text, DaisyBadgeFontSize(BadgeSize), False,
          DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
    ckButton:
      if LText <> '' then
      begin
        LBox := ButtonRect(ACell, LText);
        LColors := ButtonColors(ARow, ACol);
        DrawBadgeShape(LBox, LColors, ScaleValue(Theme.RadiusField));
        DrawRichText(LText, LBox, LColors.Text, HeadFontSize, False,
          DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
  else
    DrawRichText(LText, LTextBox, LInk, FontSize, False, LFlags);
  end;
end;

// One column of the visible rows. Pinned columns first get an opaque backdrop.
procedure TDaisyTable.DrawColumnCells(ACol, AX, AW: Integer);
var
  LArea: TRect;
  LFirst, LLast, R, LTop: Integer;
  LCell: TRect;
  LGraphics: TGPGraphics;
  LColor: TAlphaColor;
begin
  LArea := Area;
  if FRows.Count = 0 then
    Exit;
  LFirst := Max(0, (FScrollY - 1) div Max(1, RowHeight));
  LLast := Min(FRows.Count - 1, (FScrollY + LArea.Height) div Max(1, RowHeight));
  for R := LFirst to LLast do
  begin
    LTop := RowTop(R);
    if (LTop + RowHeight < LArea.Top) or (LTop > LArea.Bottom) then
      Continue;
    LCell := Mirror(Rect(LArea.Left + AX, LTop, LArea.Left + AX + AW, LTop + RowHeight));
    if FColumns[ACol].Pinned then
    begin
      LGraphics := NewGraphics;
      try
        FillRoundRect(LGraphics, RectF(LCell.Left, LCell.Top, LCell.Right, LCell.Bottom), 0,
          Theme.Base100);
        LColor := RowBackground(R);
        if TAlphaColorRec(LColor).A > 0 then
          FillRoundRect(LGraphics, RectF(LCell.Left, LCell.Top, LCell.Right, LCell.Bottom), 0, LColor);
        FillRoundRect(LGraphics, RectF(LCell.Left, LCell.Bottom - 1, LCell.Right, LCell.Bottom), 0,
          DaisyWithAlpha(Theme.BaseContent, 0.08));
      finally
        LGraphics.Free;
      end;
    end;
    DrawCell(R, ACol, LCell, False);
  end;
end;

procedure TDaisyTable.DrawBand(AHeader: Boolean; const AX, AW: TArray<Integer>);
var
  LArea, LBand, LCell: TRect;
  LGraphics: TGPGraphics;
  I, LRow, LPass: Integer;
begin
  LArea := Area;
  if AHeader then
    LRow := -1
  else
    LRow := -2;
  LBand := Rect(LArea.Left, RowTop(LRow), LArea.Right, 0);
  LBand.Bottom := LBand.Top + IfThen(AHeader, HeaderHeight, FooterHeight);
  if (LBand.Bottom < LArea.Top) or (LBand.Top > LArea.Bottom) then
    Exit;
  LGraphics := NewGraphics;
  try
    if FPinRows then
      FillRoundRect(LGraphics, RectF(LBand.Left, LBand.Top, LBand.Right, LBand.Bottom), 0,
        Theme.Base100);
    if AHeader then
      FillRoundRect(LGraphics, RectF(LBand.Left, LBand.Bottom - 1, LBand.Right, LBand.Bottom), 0,
        DaisyWithAlpha(Theme.BaseContent, 0.1))
    else
      FillRoundRect(LGraphics, RectF(LBand.Left, LBand.Top, LBand.Right, LBand.Top + 1), 0,
        DaisyWithAlpha(Theme.BaseContent, 0.1));
  finally
    LGraphics.Free;
  end;
  for LPass := 0 to 1 do
    for I := 0 to High(AW) do
      if FColumns[I].Pinned = (LPass = 1) then
      begin
        LCell := Mirror(Rect(LArea.Left + AX[I], LBand.Top, LArea.Left + AX[I] + AW[I], LBand.Bottom));
        if FColumns[I].Pinned then
        begin
          LGraphics := NewGraphics;
          try
            FillRoundRect(LGraphics, RectF(LCell.Left, LCell.Top, LCell.Right, LCell.Bottom), 0,
              Theme.Base100);
          finally
            LGraphics.Free;
          end;
        end;
        DrawCell(-1, I, LCell, True);
      end;
end;

procedure TDaisyTable.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LArea, LRowArea: TRect;
  LGraphics: TGPGraphics;
  LX, LW: TArray<Integer>;
  LSaved, I, R, LTop, LPass, LRadius: Integer;
  LColor: TAlphaColor;
  LRegion: HRGN;
  LTrack: TRectF;
  LBar: Integer;
begin
  LArea := Area;
  if FColumns.Count = 0 then
    Exit;
  ColumnPositions(LX, LW);

  LSaved := SaveDC(Canvas.Handle);
  try
    if FBordered then
    begin
      LRadius := Max(0, 2 * (ResolvedCornerRadius - Inset));
      LRegion := CreateRoundRectRgn(LArea.Left, LArea.Top, LArea.Right + 1, LArea.Bottom + 1,
        LRadius, LRadius);
      SelectClipRgn(Canvas.Handle, LRegion);
      DeleteObject(LRegion);
    end
    else
      IntersectClipRect(Canvas.Handle, LArea.Left, LArea.Top, LArea.Right, LArea.Bottom);

    // Body: clip between pinned header and footer
    LRowArea := LArea;
    if FPinRows then
    begin
      Inc(LRowArea.Top, HeaderHeight);
      Dec(LRowArea.Bottom, FooterHeight);
      if LRowArea.Bottom < LRowArea.Top then
        LRowArea.Bottom := LRowArea.Top;
    end;
    I := SaveDC(Canvas.Handle);
    try
      IntersectClipRect(Canvas.Handle, LRowArea.Left, LRowArea.Top, LRowArea.Right, LRowArea.Bottom);

      LGraphics := NewGraphics;
      try
        for R := 0 to FRows.Count - 1 do
        begin
          LTop := RowTop(R);
          if (LTop + RowHeight < LArea.Top) or (LTop > LArea.Bottom) then
            Continue;
          LColor := RowBackground(R);
          if TAlphaColorRec(LColor).A > 0 then
            FillRoundRect(LGraphics, RectF(LArea.Left, LTop, LArea.Right, LTop + RowHeight), 0, LColor);
          if (not FZebra) and ((R < FRows.Count - 1) or FShowFooter) then
            FillRoundRect(LGraphics, RectF(LArea.Left, LTop + RowHeight - 1, LArea.Right,
              LTop + RowHeight), 0, DaisyWithAlpha(Theme.BaseContent, 0.08));
        end;
      finally
        LGraphics.Free;
      end;

      for LPass := 0 to 1 do
        for R := 0 to High(LW) do
          if FColumns[R].Pinned = (LPass = 1) then
            DrawColumnCells(R, LX[R], LW[R]);
    finally
      RestoreDC(Canvas.Handle, I);
    end;

    if FShowHeader then
      DrawBand(True, LX, LW);
    if FShowFooter then
      DrawBand(False, LX, LW);

    // Thin scroll indicators
    LGraphics := NewGraphics;
    try
      LBar := ScaleValue(4);
      if MaxScrollY > 0 then
      begin
        LTrack := RectF(LArea.Right - LBar - 2, LArea.Top + HeaderHeight + FScrollY / MaxScrollY *
          (LArea.Height - HeaderHeight - FooterHeight) * 0.7, LArea.Right - 2, 0);
        LTrack.Bottom := LTrack.Top + (LArea.Height - HeaderHeight - FooterHeight) * 0.3;
        FillRoundRect(LGraphics, LTrack, LBar / 2, DaisyWithAlpha(Theme.BaseContent, 0.3));
      end;
      if MaxScrollX > 0 then
      begin
        LTrack := RectF(LArea.Left + FScrollX / MaxScrollX * LArea.Width * 0.7, LArea.Bottom - LBar - 2,
          0, LArea.Bottom - 2);
        LTrack.Right := LTrack.Left + LArea.Width * 0.3;
        FillRoundRect(LGraphics, LTrack, LBar / 2, DaisyWithAlpha(Theme.BaseContent, 0.3));
      end;
    finally
      LGraphics.Free;
    end;
  finally
    RestoreDC(Canvas.Handle, LSaved);
  end;
end;

end.
