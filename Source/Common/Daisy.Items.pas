unit Daisy.Items;

{
  Framework neutral item collection shared by the dropdown menu and the
  floating action button, plus the small enums they share.
  Must not reference Vcl.* or FMX.* units.
}

interface

uses
  System.SysUtils, System.Classes;

type
  TDaisyItem = class(TCollectionItem)
  strict private
    FCaption: string;
    FDescription: string;
    FEnabled: Boolean;
    FTag: NativeInt;
    FOnClick: TNotifyEvent;
    procedure SetCaption(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetEnabled(const Value: Boolean);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    // A caption of '-' draws a separator in a dropdown menu
    function IsSeparator: Boolean;
  published
    // Menu text or, for a floating action button, the (emoji) glyph
    property Caption: string read FCaption write SetCaption;
    // Label shown next to a floating action button action
    property Description: string read FDescription write SetDescription;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Tag: NativeInt read FTag write FTag default 0;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  TDaisyItems = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyItem;
    procedure SetItem(Index: Integer; const Value: TDaisyItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyItem;
    property Items[Index: Integer]: TDaisyItem read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDaisyItemClickEvent = procedure(Sender: TObject; AItem: TDaisyItem) of object;

  // One collapsible section of an accordion
  TDaisyAccordionItem = class(TCollectionItem)
  strict private
    FTitle: string;
    FContent: string;
    FExpanded: Boolean;
    FEnabled: Boolean;
    procedure SetTitle(const Value: string);
    procedure SetContent(const Value: string);
    procedure SetExpanded(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Title: string read FTitle write SetTitle;
    property Content: string read FContent write SetContent;
    property Expanded: Boolean read FExpanded write SetExpanded default False;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
  end;

  TDaisyAccordionItems = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyAccordionItem;
    procedure SetItem(Index: Integer; const Value: TDaisyAccordionItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyAccordionItem;
    property Items[Index: Integer]: TDaisyAccordionItem read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDaisyAccordionEvent = procedure(Sender: TObject; AIndex: Integer) of object;

  TDaisyPlacement = (dpBottomStart, dpBottomEnd, dpTopStart, dpTopEnd, dpLeft, dpRight);

  // fdArc fans the actions out on a quarter circle above and to the left of the main button
  TDaisyFabDirection = (fdUp, fdDown, fdLeft, fdRight, fdArc);

  TDaisyAccordionIcon = (aiNone, aiArrow, aiPlusMinus);

implementation

{ TDaisyItem }

constructor TDaisyItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FEnabled := True;
  FCaption := 'Item ' + IntToStr(ID + 1);
end;

procedure TDaisyItem.Assign(Source: TPersistent);
var
  LSource: TDaisyItem;
begin
  if Source is TDaisyItem then
  begin
    LSource := TDaisyItem(Source);
    FCaption := LSource.FCaption;
    FDescription := LSource.FDescription;
    FEnabled := LSource.FEnabled;
    FTag := LSource.FTag;
    FOnClick := LSource.FOnClick;
    Changed(False);
  end
  else
    inherited;
end;

function TDaisyItem.GetDisplayName: string;
begin
  Result := FCaption;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

function TDaisyItem.IsSeparator: Boolean;
begin
  Result := FCaption = '-';
end;

procedure TDaisyItem.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TDaisyItem.SetDescription(const Value: string);
begin
  if FDescription <> Value then
  begin
    FDescription := Value;
    Changed(False);
  end;
end;

procedure TDaisyItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

{ TDaisyItems }

constructor TDaisyItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyItem);
end;

function TDaisyItems.Add: TDaisyItem;
begin
  Result := TDaisyItem(inherited Add);
end;

function TDaisyItems.GetItem(Index: Integer): TDaisyItem;
begin
  Result := TDaisyItem(inherited GetItem(Index));
end;

procedure TDaisyItems.SetItem(Index: Integer; const Value: TDaisyItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyItems.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TDaisyAccordionItem }

constructor TDaisyAccordionItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FEnabled := True;
  FTitle := 'Section ' + IntToStr(ID + 1);
end;

procedure TDaisyAccordionItem.Assign(Source: TPersistent);
var
  LSource: TDaisyAccordionItem;
begin
  if Source is TDaisyAccordionItem then
  begin
    LSource := TDaisyAccordionItem(Source);
    FTitle := LSource.FTitle;
    FContent := LSource.FContent;
    FExpanded := LSource.FExpanded;
    FEnabled := LSource.FEnabled;
    Changed(False);
  end
  else
    inherited;
end;

function TDaisyAccordionItem.GetDisplayName: string;
begin
  Result := FTitle;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

procedure TDaisyAccordionItem.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TDaisyAccordionItem.SetContent(const Value: string);
begin
  if FContent <> Value then
  begin
    FContent := Value;
    Changed(False);
  end;
end;

procedure TDaisyAccordionItem.SetExpanded(const Value: Boolean);
begin
  if FExpanded <> Value then
  begin
    FExpanded := Value;
    Changed(False);
  end;
end;

procedure TDaisyAccordionItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

{ TDaisyAccordionItems }

constructor TDaisyAccordionItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyAccordionItem);
end;

function TDaisyAccordionItems.Add: TDaisyAccordionItem;
begin
  Result := TDaisyAccordionItem(inherited Add);
end;

function TDaisyAccordionItems.GetItem(Index: Integer): TDaisyAccordionItem;
begin
  Result := TDaisyAccordionItem(inherited GetItem(Index));
end;

procedure TDaisyAccordionItems.SetItem(Index: Integer; const Value: TDaisyAccordionItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyAccordionItems.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

end.
