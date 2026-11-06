unit Daisy.Menus;

{
  Framework neutral menu item model shared by TDaisyMenu, TDaisyMainMenu and
  TDaisyPopupMenu (VCL and FMX).
  Must not reference Vcl.* or FMX.* units.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Daisy.Theme, Daisy.Widgets;

type
  // Icons in menus are limited to these sizes (pixels)
  TDaisyMenuIconSize = (mis16, mis24, mis32);

  TDaisyMenuOrientation = (moVertical, moHorizontal);

  TDaisyMenuItems = class;

  TDaisyMenuItem = class(TCollectionItem)
  strict private
    FCaption: string;
    FIcon: TDaisyIconSource;
    FShortCut: string;
    FBadge: string;
    FEnabled: Boolean;
    FChecked: Boolean;
    FAutoCheck: Boolean;
    FActive: Boolean;
    FExpanded: Boolean;
    FVisible: Boolean;
    FTitle: Boolean;
    FTag: NativeInt;
    FItems: TDaisyMenuItems;
    FOnClick: TNotifyEvent;
    procedure SetCaption(const Value: string);
    procedure SetIcon(const Value: TDaisyIconSource);
    procedure SetShortCut(const Value: string);
    procedure SetBadge(const Value: string);
    procedure SetEnabled(const Value: Boolean);
    procedure SetChecked(const Value: Boolean);
    procedure SetActive(const Value: Boolean);
    procedure SetExpanded(const Value: Boolean);
    procedure SetVisible(const Value: Boolean);
    procedure SetTitle(const Value: Boolean);
    procedure SetItems(const Value: TDaisyMenuItems);
    procedure IconChanged(Sender: TObject);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function IsSeparator: Boolean;
    function HasChildren: Boolean;
    // Runs OnClick (and flips Checked when AutoCheck is set)
    procedure Click;
  published
    // A caption of '-' is a separator
    property Caption: string read FCaption write SetCaption;
    property Icon: TDaisyIconSource read FIcon write SetIcon;
    // Display text only, for example 'Ctrl+S'
    property ShortCut: string read FShortCut write SetShortCut;
    property Badge: string read FBadge write SetBadge;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Checked: Boolean read FChecked write SetChecked default False;
    property AutoCheck: Boolean read FAutoCheck write FAutoCheck default False;
    // Highlights the item in a TDaisyMenu
    property Active: Boolean read FActive write SetActive default False;
    // Whether the child items of a TDaisyMenu entry are shown
    property Expanded: Boolean read FExpanded write SetExpanded default True;
    property Visible: Boolean read FVisible write SetVisible default True;
    // A heading: not clickable, its child items are always shown beneath it
    property Title: Boolean read FTitle write SetTitle default False;
    property Tag: NativeInt read FTag write FTag default 0;
    property Items: TDaisyMenuItems read FItems write SetItems;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  TDaisyMenuItems = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyMenuItem;
    procedure SetItem(Index: Integer; const Value: TDaisyMenuItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyMenuItem;
    function AddItem(const ACaption: string): TDaisyMenuItem;
    property Items[Index: Integer]: TDaisyMenuItem read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDaisyMenuItemEvent = procedure(Sender: TObject; AItem: TDaisyMenuItem) of object;

  TDaisyMenuRow = record
    Item: TDaisyMenuItem;
    Level: Integer;
  end;

  TDaisyMenuChevron = (mcNone, mcRight, mcDown, mcUp);

  // How one menu row is drawn; shared by the menu, menu bar and popup menu
  TDaisyMenuRowStyle = record
    Hot: Boolean;
    Active: Boolean;
    IconPx: Integer;
    // Leave room for an icon / check mark even when this item has none
    ReserveIcon: Boolean;
    IconsOnly: Boolean;
    ShowExtras: Boolean; // short cut and badge
    Chevron: TDaisyMenuChevron;
  end;

const
  CMenuCheckPath = 'M5 12l5 5l10 -10';
  CMenuRightPath = 'M9 6l6 6l-6 6';
  CMenuDownPath = 'M6 9l6 6l6 -6';
  CMenuUpPath = 'M6 15l6 -6l6 6';

function DaisyMenuIconPixels(ASize: TDaisyMenuIconSize): Integer;
// Row height used by every menu at a given size (logical pixels)
function DaisyMenuRowHeight(ASize: TDaisySize): Integer;
// The visible items of AItems as a flat list; collapsed branches are skipped
procedure DaisyFlattenMenu(AItems: TDaisyMenuItems; ARows: TList<TDaisyMenuRow>);

implementation

function DaisyMenuIconPixels(ASize: TDaisyMenuIconSize): Integer;
begin
  case ASize of
    mis16: Result := 16;
    mis24: Result := 24;
  else
    Result := 32;
  end;
end;

function DaisyMenuRowHeight(ASize: TDaisySize): Integer;
begin
  case ASize of
    dzXS: Result := 24;
    dzSM: Result := 30;
    dzMD: Result := 36;
    dzLG: Result := 44;
  else
    Result := 52;
  end;
end;

procedure DaisyFlattenMenu(AItems: TDaisyMenuItems; ARows: TList<TDaisyMenuRow>);

  procedure Walk(AList: TDaisyMenuItems; ALevel: Integer);
  var
    I: Integer;
    LRow: TDaisyMenuRow;
  begin
    for I := 0 to AList.Count - 1 do
    begin
      if not AList[I].Visible then
        Continue;
      LRow.Item := AList[I];
      LRow.Level := ALevel;
      ARows.Add(LRow);
      if AList[I].HasChildren and (AList[I].Title or AList[I].Expanded) then
        Walk(AList[I].Items, ALevel + 1);
    end;
  end;

begin
  ARows.Clear;
  Walk(AItems, 0);
end;

{ TDaisyMenuItem }

constructor TDaisyMenuItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FEnabled := True;
  FExpanded := True;
  FVisible := True;
  FCaption := 'Item ' + IntToStr(ID + 1);
  FIcon := TDaisyIconSource.Create(IconChanged);
  FItems := TDaisyMenuItems.Create(Self);
end;

destructor TDaisyMenuItem.Destroy;
begin
  FItems.Free;
  FIcon.Free;
  inherited Destroy;
end;

procedure TDaisyMenuItem.Assign(Source: TPersistent);
var
  LSource: TDaisyMenuItem;
begin
  if Source is TDaisyMenuItem then
  begin
    LSource := TDaisyMenuItem(Source);
    FCaption := LSource.FCaption;
    FIcon.Assign(LSource.FIcon);
    FShortCut := LSource.FShortCut;
    FBadge := LSource.FBadge;
    FEnabled := LSource.FEnabled;
    FChecked := LSource.FChecked;
    FAutoCheck := LSource.FAutoCheck;
    FActive := LSource.FActive;
    FExpanded := LSource.FExpanded;
    FVisible := LSource.FVisible;
    FTitle := LSource.FTitle;
    FTag := LSource.FTag;
    FItems.Assign(LSource.FItems);
    FOnClick := LSource.FOnClick;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TDaisyMenuItem.GetDisplayName: string;
begin
  Result := FCaption;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

function TDaisyMenuItem.IsSeparator: Boolean;
begin
  Result := FCaption = '-';
end;

function TDaisyMenuItem.HasChildren: Boolean;
begin
  Result := FItems.Count > 0;
end;

procedure TDaisyMenuItem.Click;
begin
  if FAutoCheck then
    SetChecked(not FChecked);
  if Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TDaisyMenuItem.IconChanged(Sender: TObject);
begin
  Changed(False);
end;

procedure TDaisyMenuItem.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetIcon(const Value: TDaisyIconSource);
begin
  FIcon.Assign(Value);
end;

procedure TDaisyMenuItem.SetShortCut(const Value: string);
begin
  if FShortCut <> Value then
  begin
    FShortCut := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetBadge(const Value: string);
begin
  if FBadge <> Value then
  begin
    FBadge := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetChecked(const Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetExpanded(const Value: Boolean);
begin
  if FExpanded <> Value then
  begin
    FExpanded := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetTitle(const Value: Boolean);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TDaisyMenuItem.SetItems(const Value: TDaisyMenuItems);
begin
  FItems.Assign(Value);
end;

{ TDaisyMenuItems }

constructor TDaisyMenuItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyMenuItem);
end;

function TDaisyMenuItems.Add: TDaisyMenuItem;
begin
  Result := TDaisyMenuItem(inherited Add);
end;

function TDaisyMenuItems.AddItem(const ACaption: string): TDaisyMenuItem;
begin
  Result := Add;
  Result.Caption := ACaption;
end;

function TDaisyMenuItems.GetItem(Index: Integer): TDaisyMenuItem;
begin
  Result := TDaisyMenuItem(inherited GetItem(Index));
end;

procedure TDaisyMenuItems.SetItem(Index: Integer; const Value: TDaisyMenuItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyMenuItems.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
  // A change deep in the tree must reach the control that owns the root collection
  if GetOwner is TDaisyMenuItem then
    TDaisyMenuItem(GetOwner).Changed(False);
end;

end.
