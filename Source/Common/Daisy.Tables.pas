unit Daisy.Tables;

{
  Framework neutral model of the DaisyUI table: columns and rows.
  Must not reference Vcl.* or FMX.* units.

  Cell text of an avatar column is "Title|Subtitle". The avatar picture is the
  row Icon (emoji and/or SVG).
}

interface

uses
  System.SysUtils, System.Classes, System.Math, Daisy.Theme, Daisy.Widgets;

type
  TDaisyTableColumn = class(TCollectionItem)
  strict private
    FCaption: string;
    FWidth: Integer;
    FAlignment: TDaisyTextAlign;
    FKind: TDaisyTableColumnKind;
    FPinned: Boolean;
    FVariant: TDaisyVariant;
    procedure SetCaption(const Value: string);
    procedure SetWidth(const Value: Integer);
    procedure SetAlignment(const Value: TDaisyTextAlign);
    procedure SetKind(const Value: TDaisyTableColumnKind);
    procedure SetPinned(const Value: Boolean);
    procedure SetVariant(const Value: TDaisyVariant);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Caption: string read FCaption write SetCaption;
    // 0 sizes the column to its content (and shares out spare room)
    property Width: Integer read FWidth write SetWidth default 0;
    property Alignment: TDaisyTextAlign read FAlignment write SetAlignment default taStart;
    property Kind: TDaisyTableColumnKind read FKind write SetKind default ckText;
    // Stays in view while the table scrolls sideways
    property Pinned: Boolean read FPinned write SetPinned default False;
    // Colour of the badges / buttons of this column
    property Variant: TDaisyVariant read FVariant write SetVariant default dvDefault;
  end;

  TDaisyTableColumns = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyTableColumn;
    procedure SetItem(Index: Integer; const Value: TDaisyTableColumn);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyTableColumn;
    property Items[Index: Integer]: TDaisyTableColumn read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDaisyTableRow = class(TCollectionItem)
  strict private
    FCells: TStrings;
    FActive: Boolean;
    FChecked: Boolean;
    FIcon: TDaisyIconSource;
    FVariant: TDaisyVariant;
    procedure SetCells(const Value: TStrings);
    procedure SetActive(const Value: Boolean);
    procedure SetChecked(const Value: Boolean);
    procedure SetIcon(const Value: TDaisyIconSource);
    procedure SetVariant(const Value: TDaisyVariant);
    procedure SubChanged(Sender: TObject);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    // Empty when the row has fewer cells than the column index
    function CellText(AColumn: Integer): string;
  published
    property Cells: TStrings read FCells write SetCells;
    property Active: Boolean read FActive write SetActive default False;
    property Checked: Boolean read FChecked write SetChecked default False;
    // Picture of an avatar column
    property Icon: TDaisyIconSource read FIcon write SetIcon;
    // Overrides the column colour of badges / buttons when not dvDefault
    property Variant: TDaisyVariant read FVariant write SetVariant default dvDefault;
  end;

  TDaisyTableRows = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyTableRow;
    procedure SetItem(Index: Integer; const Value: TDaisyTableRow);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyTableRow;
    property Items[Index: Integer]: TDaisyTableRow read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDaisyTableRowEvent = procedure(Sender: TObject; ARow: Integer) of object;
  TDaisyTableCellEvent = procedure(Sender: TObject; ARow, AColumn: Integer) of object;

// Splits "Title|Subtitle"
procedure DaisySplitCell(const AText: string; out ATitle, ASubtitle: string);

// Shares AAvailable over the columns: ANatural holds the content width of each column,
// AFixed >= 0 forces a width. Spare room goes to the content-sized columns.
function DaisyTableColumnWidths(const ANatural, AFixed: TArray<Single>;
  AAvailable: Single): TArray<Single>;

implementation

procedure DaisySplitCell(const AText: string; out ATitle, ASubtitle: string);
var
  LPos: Integer;
begin
  LPos := Pos('|', AText);
  if LPos > 0 then
  begin
    ATitle := Copy(AText, 1, LPos - 1);
    ASubtitle := Copy(AText, LPos + 1, MaxInt);
  end
  else
  begin
    ATitle := AText;
    ASubtitle := '';
  end;
end;

function DaisyTableColumnWidths(const ANatural, AFixed: TArray<Single>;
  AAvailable: Single): TArray<Single>;
var
  I, LAuto: Integer;
  LTotal, LExtra: Single;
begin
  SetLength(Result, Length(ANatural));
  LTotal := 0;
  LAuto := 0;
  for I := 0 to High(ANatural) do
  begin
    if AFixed[I] > 0 then
      Result[I] := AFixed[I]
    else
    begin
      Result[I] := ANatural[I];
      Inc(LAuto);
    end;
    LTotal := LTotal + Result[I];
  end;
  if (LAuto > 0) and (LTotal < AAvailable) then
  begin
    LExtra := (AAvailable - LTotal) / LAuto;
    for I := 0 to High(Result) do
      if AFixed[I] <= 0 then
        Result[I] := Result[I] + LExtra;
  end;
end;

{ TDaisyTableColumn }

constructor TDaisyTableColumn.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FCaption := 'Column ' + IntToStr(ID + 1);
end;

procedure TDaisyTableColumn.Assign(Source: TPersistent);
var
  LSource: TDaisyTableColumn;
begin
  if Source is TDaisyTableColumn then
  begin
    LSource := TDaisyTableColumn(Source);
    FCaption := LSource.FCaption;
    FWidth := LSource.FWidth;
    FAlignment := LSource.FAlignment;
    FKind := LSource.FKind;
    FPinned := LSource.FPinned;
    FVariant := LSource.FVariant;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TDaisyTableColumn.GetDisplayName: string;
begin
  Result := FCaption;
end;

procedure TDaisyTableColumn.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TDaisyTableColumn.SetWidth(const Value: Integer);
begin
  if FWidth <> Value then
  begin
    FWidth := Max(0, Value);
    Changed(False);
  end;
end;

procedure TDaisyTableColumn.SetAlignment(const Value: TDaisyTextAlign);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Changed(False);
  end;
end;

procedure TDaisyTableColumn.SetKind(const Value: TDaisyTableColumnKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Changed(False);
  end;
end;

procedure TDaisyTableColumn.SetPinned(const Value: Boolean);
begin
  if FPinned <> Value then
  begin
    FPinned := Value;
    Changed(False);
  end;
end;

procedure TDaisyTableColumn.SetVariant(const Value: TDaisyVariant);
begin
  if FVariant <> Value then
  begin
    FVariant := Value;
    Changed(False);
  end;
end;

{ TDaisyTableColumns }

constructor TDaisyTableColumns.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyTableColumn);
end;

function TDaisyTableColumns.Add: TDaisyTableColumn;
begin
  Result := TDaisyTableColumn(inherited Add);
end;

function TDaisyTableColumns.GetItem(Index: Integer): TDaisyTableColumn;
begin
  Result := TDaisyTableColumn(inherited GetItem(Index));
end;

procedure TDaisyTableColumns.SetItem(Index: Integer; const Value: TDaisyTableColumn);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyTableColumns.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TDaisyTableRow }

constructor TDaisyTableRow.Create(Collection: TCollection);
begin
  FCells := TStringList.Create;
  TStringList(FCells).OnChange := SubChanged;
  FIcon := TDaisyIconSource.Create(SubChanged);
  inherited Create(Collection);
end;

destructor TDaisyTableRow.Destroy;
begin
  FIcon.Free;
  FCells.Free;
  inherited Destroy;
end;

procedure TDaisyTableRow.Assign(Source: TPersistent);
var
  LSource: TDaisyTableRow;
begin
  if Source is TDaisyTableRow then
  begin
    LSource := TDaisyTableRow(Source);
    FCells.Assign(LSource.FCells);
    FActive := LSource.FActive;
    FChecked := LSource.FChecked;
    FIcon.Assign(LSource.FIcon);
    FVariant := LSource.FVariant;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TDaisyTableRow.CellText(AColumn: Integer): string;
begin
  if (AColumn >= 0) and (AColumn < FCells.Count) then
    Result := FCells[AColumn]
  else
    Result := '';
end;

function TDaisyTableRow.GetDisplayName: string;
begin
  if FCells.Count > 0 then
    Result := FCells[0]
  else
    Result := 'Row ' + IntToStr(Index + 1);
end;

procedure TDaisyTableRow.SubChanged(Sender: TObject);
begin
  if Collection <> nil then
    Changed(False);
end;

procedure TDaisyTableRow.SetCells(const Value: TStrings);
begin
  FCells.Assign(Value);
end;

procedure TDaisyTableRow.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    Changed(False);
  end;
end;

procedure TDaisyTableRow.SetChecked(const Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Changed(False);
  end;
end;

procedure TDaisyTableRow.SetIcon(const Value: TDaisyIconSource);
begin
  FIcon.Assign(Value);
end;

procedure TDaisyTableRow.SetVariant(const Value: TDaisyVariant);
begin
  if FVariant <> Value then
  begin
    FVariant := Value;
    Changed(False);
  end;
end;

{ TDaisyTableRows }

constructor TDaisyTableRows.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyTableRow);
end;

function TDaisyTableRows.Add: TDaisyTableRow;
begin
  Result := TDaisyTableRow(inherited Add);
end;

function TDaisyTableRows.GetItem(Index: Integer): TDaisyTableRow;
begin
  Result := TDaisyTableRow(inherited GetItem(Index));
end;

procedure TDaisyTableRows.SetItem(Index: Integer; const Value: TDaisyTableRow);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyTableRows.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

end.
