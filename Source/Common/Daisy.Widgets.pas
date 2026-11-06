unit Daisy.Widgets;

{
  Framework neutral building blocks shared by the chat bubble, countdown, list
  and stat components (VCL and FMX).

  * TDaisyIconSource  - an emoji and/or SVG markup; the SVG is converted once
                        by TDaisySVG into the internal icon path.
  * Collections       - countdown segments, list rows and stat cells.
  * DaisyChatBubblePolygon - the speech bubble outline with its tail.
  * DaisyHasEmoji     - tells whether text needs a colour emoji capable renderer.
  Must not reference Vcl.* or FMX.* units.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math, System.Character,
  System.Generics.Collections, Daisy.Theme, Daisy.SVG;

type
  // Emoji (drawn with the colour emoji font) and/or SVG markup (drawn as a vector icon).
  // SVG wins when both are given.
  TDaisyIconSource = class(TPersistent)
  strict private
    FEmoji: string;
    FSVG: TStrings;
    FIconPath: string;
    FOnChange: TNotifyEvent;
    procedure SetEmoji(const Value: string);
    procedure SetSVG(const Value: TStrings);
    procedure SVGChanged(Sender: TObject);
    procedure Changed;
  public
    constructor Create(const AOnChange: TNotifyEvent = nil);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function IsEmpty: Boolean;
    // Internal icon data produced from SVG
    property IconPath: string read FIconPath;
  published
    property Emoji: string read FEmoji write SetEmoji;
    // Paste SVG markup or load an .svg file
    property SVG: TStrings read FSVG write SetSVG;
  end;

  TDaisyChatPlacement = (cpStart, cpEnd);

  TDaisyCountdownLabels = (clNone, clAfter, clBelow);

  TDaisyListLayout = (llSecondGrows, llThirdGrows, llThirdWraps);

  TDaisyStatDirection = (sdHorizontal, sdVertical);

  TDaisyStatusAnimation = (saNone, saPing, saBounce);

  // slmBefore / slmAfter put LabelText inside the select box; slmFloating floats it above
  TDaisySelectLabelMode = (slmNone, slmBefore, slmAfter, slmFloating);

  // How the chosen item is marked in the drop-down list
  TDaisySelectIndicator = (siNone, siBold, siTick);

  TDaisyTextAlign = (taStart, taCenter, taEnd);

  // dtsNone = plain tabs, dtsBox = tabs-box, dtsBorder = tabs-border, dtsLift = tabs-lift
  TDaisyTabStyle = (dtsNone, dtsBox, dtsBorder, dtsLift);

  TDaisyTabPosition = (dtpTop, dtpBottom);

  TDaisyTableColumnKind = (ckText, ckCheckbox, ckAvatar, ckBadge, ckButton);

  { Countdown }

  TDaisyCountdownSegment = class(TCollectionItem)
  strict private
    FValue: Integer;
    FCaption: string;
    procedure SetValue(const Value: Integer);
    procedure SetCaption(const Value: string);
  protected
    function GetDisplayName: string; override;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Value: Integer read FValue write SetValue default 0;
    // The label shown with the number, for example "days"
    property Caption: string read FCaption write SetCaption;
  end;

  TDaisyCountdownSegments = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyCountdownSegment;
    procedure SetItem(Index: Integer; const Value: TDaisyCountdownSegment);
    function GetTotalSeconds: Int64;
    procedure SetTotalSeconds(const Value: Int64);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyCountdownSegment;
    property Items[Index: Integer]: TDaisyCountdownSegment read GetItem write SetItem; default;
    // The segments read from the right as seconds, minutes, hours and days
    property TotalSeconds: Int64 read GetTotalSeconds write SetTotalSeconds;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  { List }

  TDaisyListItem = class(TCollectionItem)
  strict private
    FTitle: string;
    FSubtitle: string;
    FDescription: string;
    FIcon: TDaisyIconSource;
    FAction: TDaisyIconSource;
    FAction2: TDaisyIconSource;
    procedure SetTitle(const Value: string);
    procedure SetSubtitle(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetIcon(const Value: TDaisyIconSource);
    procedure SetAction(const Value: TDaisyIconSource);
    procedure SetAction2(const Value: TDaisyIconSource);
    procedure IconChanged(Sender: TObject);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Title: string read FTitle write SetTitle;
    property Subtitle: string read FSubtitle write SetSubtitle;
    // The third column: grows or wraps under the title, depending on the list Layout
    property Description: string read FDescription write SetDescription;
    // Picture at the start of the row
    property Icon: TDaisyIconSource read FIcon write SetIcon;
    // First and second icon buttons at the end of the row
    property Action: TDaisyIconSource read FAction write SetAction;
    property Action2: TDaisyIconSource read FAction2 write SetAction2;
  end;

  TDaisyListItems = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyListItem;
    procedure SetItem(Index: Integer; const Value: TDaisyListItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyListItem;
    property Items[Index: Integer]: TDaisyListItem read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  // AAction is 0 for the row itself, 1 for Action and 2 for Action2
  TDaisyListClickEvent = procedure(Sender: TObject; AIndex, AAction: Integer) of object;

  { Stat }

  TDaisyStatItem = class(TCollectionItem)
  strict private
    FTitle: string;
    FValue: string;
    FDescription: string;
    FIcon: TDaisyIconSource;
    FFigureVariant: TDaisyVariant;
    FVariant: TDaisyVariant;
    FActionCaption: string;
    FActionVariant: TDaisyVariant;
    procedure SetTitle(const Value: string);
    procedure SetValue(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetIcon(const Value: TDaisyIconSource);
    procedure SetFigureVariant(const Value: TDaisyVariant);
    procedure SetVariant(const Value: TDaisyVariant);
    procedure SetActionCaption(const Value: string);
    procedure SetActionVariant(const Value: TDaisyVariant);
    procedure IconChanged(Sender: TObject);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Title: string read FTitle write SetTitle;
    property Value: string read FValue write SetValue;
    property Description: string read FDescription write SetDescription;
    // The figure at the end of the cell
    property Icon: TDaisyIconSource read FIcon write SetIcon;
    // Colour of the figure; dvDefault follows the text colour
    property FigureVariant: TDaisyVariant read FFigureVariant write SetFigureVariant default dvDefault;
    // dvDefault follows the stat control; any other colour fills just this cell
    property Variant: TDaisyVariant read FVariant write SetVariant default dvDefault;
    // A non-empty caption adds a small button under the description
    property ActionCaption: string read FActionCaption write SetActionCaption;
    property ActionVariant: TDaisyVariant read FActionVariant write SetActionVariant default dvDefault;
  end;

  TDaisyStatItems = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TDaisyStatItem;
    procedure SetItem(Index: Integer; const Value: TDaisyStatItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TDaisyStatItem;
    property Items[Index: Integer]: TDaisyStatItem read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDaisyStatActionEvent = procedure(Sender: TObject; AIndex: Integer) of object;

// True when AText holds characters that need a colour emoji capable renderer
function DaisyHasEmoji(const AText: string): Boolean;

// Outline of a chat bubble in a clockwise-free point list: a rounded rectangle whose
// bottom corner on the tail side is square and continues in a curved tail of ATail
// units. The tail lies outside ABubble (left for cpStart, right for cpEnd).
function DaisyChatBubblePolygon(const ABubble: TRectF; ARadius, ATail: Single;
  APlacement: TDaisyChatPlacement): TArray<TPointF>;

implementation

{ TDaisyIconSource }

constructor TDaisyIconSource.Create(const AOnChange: TNotifyEvent);
begin
  inherited Create;
  FOnChange := AOnChange;
  FSVG := TStringList.Create;
  TStringList(FSVG).OnChange := SVGChanged;
end;

destructor TDaisyIconSource.Destroy;
begin
  FSVG.Free;
  inherited Destroy;
end;

procedure TDaisyIconSource.Assign(Source: TPersistent);
begin
  if Source is TDaisyIconSource then
  begin
    FEmoji := TDaisyIconSource(Source).FEmoji;
    FSVG.Assign(TDaisyIconSource(Source).FSVG);
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TDaisyIconSource.IsEmpty: Boolean;
begin
  Result := (FEmoji = '') and (FIconPath = '');
end;

procedure TDaisyIconSource.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDaisyIconSource.SetEmoji(const Value: string);
begin
  if FEmoji <> Value then
  begin
    FEmoji := Value;
    Changed;
  end;
end;

procedure TDaisyIconSource.SetSVG(const Value: TStrings);
begin
  FSVG.Assign(Value);
end;

procedure TDaisyIconSource.SVGChanged(Sender: TObject);
var
  LPath: string;
begin
  LPath := TDaisySVG.IconPath(FSVG.Text);
  if LPath <> FIconPath then
  begin
    FIconPath := LPath;
    Changed;
  end;
end;

{ TDaisyCountdownSegment }

procedure TDaisyCountdownSegment.Assign(Source: TPersistent);
begin
  if Source is TDaisyCountdownSegment then
  begin
    FValue := TDaisyCountdownSegment(Source).FValue;
    FCaption := TDaisyCountdownSegment(Source).FCaption;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TDaisyCountdownSegment.GetDisplayName: string;
begin
  Result := IntToStr(FValue);
  if FCaption <> '' then
    Result := Result + ' ' + FCaption;
end;

procedure TDaisyCountdownSegment.SetValue(const Value: Integer);
begin
  if FValue <> Value then
  begin
    FValue := Max(0, Value);
    Changed(False);
  end;
end;

procedure TDaisyCountdownSegment.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

{ TDaisyCountdownSegments }

const
  CSecondsPerUnit: array[0..3] of Int64 = (1, 60, 3600, 86400);

constructor TDaisyCountdownSegments.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyCountdownSegment);
end;

function TDaisyCountdownSegments.Add: TDaisyCountdownSegment;
begin
  Result := TDaisyCountdownSegment(inherited Add);
end;

function TDaisyCountdownSegments.GetItem(Index: Integer): TDaisyCountdownSegment;
begin
  Result := TDaisyCountdownSegment(inherited GetItem(Index));
end;

procedure TDaisyCountdownSegments.SetItem(Index: Integer; const Value: TDaisyCountdownSegment);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyCountdownSegments.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TDaisyCountdownSegments.GetTotalSeconds: Int64;
var
  K: Integer;
begin
  Result := 0;
  for K := 0 to Min(Count, 4) - 1 do
    Inc(Result, Int64(Items[Count - 1 - K].Value) * CSecondsPerUnit[K]);
end;

procedure TDaisyCountdownSegments.SetTotalSeconds(const Value: Int64);
var
  K, LMapped: Integer;
  LRest, LValue: Int64;
begin
  LMapped := Min(Count, 4);
  if LMapped = 0 then
    Exit;
  LRest := Max(0, Value);
  BeginUpdate;
  try
    for K := 0 to LMapped - 1 do
    begin
      LValue := LRest div CSecondsPerUnit[K];
      if K < LMapped - 1 then
        LValue := LValue mod (CSecondsPerUnit[K + 1] div CSecondsPerUnit[K]); // the top segment keeps the overflow
      Items[Count - 1 - K].Value := Integer(LValue);
    end;
  finally
    EndUpdate;
  end;
end;

{ TDaisyListItem }

constructor TDaisyListItem.Create(Collection: TCollection);
begin
  FIcon := TDaisyIconSource.Create(IconChanged);
  FAction := TDaisyIconSource.Create(IconChanged);
  FAction2 := TDaisyIconSource.Create(IconChanged);
  inherited Create(Collection);
  FTitle := 'Item ' + IntToStr(ID + 1);
end;

destructor TDaisyListItem.Destroy;
begin
  FAction2.Free;
  FAction.Free;
  FIcon.Free;
  inherited Destroy;
end;

procedure TDaisyListItem.Assign(Source: TPersistent);
var
  LSource: TDaisyListItem;
begin
  if Source is TDaisyListItem then
  begin
    LSource := TDaisyListItem(Source);
    FTitle := LSource.FTitle;
    FSubtitle := LSource.FSubtitle;
    FDescription := LSource.FDescription;
    FIcon.Assign(LSource.FIcon);
    FAction.Assign(LSource.FAction);
    FAction2.Assign(LSource.FAction2);
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TDaisyListItem.GetDisplayName: string;
begin
  Result := FTitle;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

procedure TDaisyListItem.IconChanged(Sender: TObject);
begin
  Changed(False);
end;

procedure TDaisyListItem.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TDaisyListItem.SetSubtitle(const Value: string);
begin
  if FSubtitle <> Value then
  begin
    FSubtitle := Value;
    Changed(False);
  end;
end;

procedure TDaisyListItem.SetDescription(const Value: string);
begin
  if FDescription <> Value then
  begin
    FDescription := Value;
    Changed(False);
  end;
end;

procedure TDaisyListItem.SetIcon(const Value: TDaisyIconSource);
begin
  FIcon.Assign(Value);
end;

procedure TDaisyListItem.SetAction(const Value: TDaisyIconSource);
begin
  FAction.Assign(Value);
end;

procedure TDaisyListItem.SetAction2(const Value: TDaisyIconSource);
begin
  FAction2.Assign(Value);
end;

{ TDaisyListItems }

constructor TDaisyListItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyListItem);
end;

function TDaisyListItems.Add: TDaisyListItem;
begin
  Result := TDaisyListItem(inherited Add);
end;

function TDaisyListItems.GetItem(Index: Integer): TDaisyListItem;
begin
  Result := TDaisyListItem(inherited GetItem(Index));
end;

procedure TDaisyListItems.SetItem(Index: Integer; const Value: TDaisyListItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyListItems.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TDaisyStatItem }

constructor TDaisyStatItem.Create(Collection: TCollection);
begin
  FIcon := TDaisyIconSource.Create(IconChanged);
  FTitle := 'Title';
  FValue := '0';
  inherited Create(Collection);
end;

destructor TDaisyStatItem.Destroy;
begin
  FIcon.Free;
  inherited Destroy;
end;

procedure TDaisyStatItem.Assign(Source: TPersistent);
var
  LSource: TDaisyStatItem;
begin
  if Source is TDaisyStatItem then
  begin
    LSource := TDaisyStatItem(Source);
    FTitle := LSource.FTitle;
    FValue := LSource.FValue;
    FDescription := LSource.FDescription;
    FIcon.Assign(LSource.FIcon);
    FFigureVariant := LSource.FFigureVariant;
    FVariant := LSource.FVariant;
    FActionCaption := LSource.FActionCaption;
    FActionVariant := LSource.FActionVariant;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TDaisyStatItem.GetDisplayName: string;
begin
  Result := FTitle;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

procedure TDaisyStatItem.IconChanged(Sender: TObject);
begin
  Changed(False);
end;

procedure TDaisyStatItem.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TDaisyStatItem.SetValue(const Value: string);
begin
  if FValue <> Value then
  begin
    FValue := Value;
    Changed(False);
  end;
end;

procedure TDaisyStatItem.SetDescription(const Value: string);
begin
  if FDescription <> Value then
  begin
    FDescription := Value;
    Changed(False);
  end;
end;

procedure TDaisyStatItem.SetIcon(const Value: TDaisyIconSource);
begin
  FIcon.Assign(Value);
end;

procedure TDaisyStatItem.SetFigureVariant(const Value: TDaisyVariant);
begin
  if FFigureVariant <> Value then
  begin
    FFigureVariant := Value;
    Changed(False);
  end;
end;

procedure TDaisyStatItem.SetVariant(const Value: TDaisyVariant);
begin
  if FVariant <> Value then
  begin
    FVariant := Value;
    Changed(False);
  end;
end;

procedure TDaisyStatItem.SetActionCaption(const Value: string);
begin
  if FActionCaption <> Value then
  begin
    FActionCaption := Value;
    Changed(False);
  end;
end;

procedure TDaisyStatItem.SetActionVariant(const Value: TDaisyVariant);
begin
  if FActionVariant <> Value then
  begin
    FActionVariant := Value;
    Changed(False);
  end;
end;

{ TDaisyStatItems }

constructor TDaisyStatItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TDaisyStatItem);
end;

function TDaisyStatItems.Add: TDaisyStatItem;
begin
  Result := TDaisyStatItem(inherited Add);
end;

function TDaisyStatItems.GetItem(Index: Integer): TDaisyStatItem;
begin
  Result := TDaisyStatItem(inherited GetItem(Index));
end;

procedure TDaisyStatItems.SetItem(Index: Integer; const Value: TDaisyStatItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDaisyStatItems.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ Helpers }

function DaisyHasEmoji(const AText: string): Boolean;
var
  LChar: Char;
begin
  for LChar in AText do
    if (LChar >= #$2190) and
      (LChar.IsSurrogate or (LChar <= #$2BFF) or (LChar = #$FE0F) or (LChar = #$3030) or
       (LChar = #$303D) or (LChar = #$3297) or (LChar = #$3299)) then
      Exit(True);
  Result := False;
end;

function DaisyChatBubblePolygon(const ABubble: TRectF; ARadius, ATail: Single;
  APlacement: TDaisyChatPlacement): TArray<TPointF>;
const
  CSteps = 12;
var
  LPoints: TList<TPointF>;
  LRadius: Single;
  I: Integer;

  procedure AddArc(ACenterX, ACenterY, ARad, AFrom, ATo: Single);
  var
    K: Integer;
    LAngle: Single;
  begin
    for K := 0 to CSteps do
    begin
      LAngle := DegToRad(AFrom + (ATo - AFrom) * K / CSteps);
      LPoints.Add(PointF(ACenterX + ARad * Cos(LAngle), ACenterY + ARad * Sin(LAngle)));
    end;
  end;

begin
  LRadius := Max(0, Min(ARadius, Min(ABubble.Width / 2, (ABubble.Height - ATail) / 2)));
  LPoints := TList<TPointF>.Create;
  try
    // Built for the tail on the left, then mirrored for cpEnd.
    // The tail is a quarter circle centred above the tip, so it curves in towards the corner.
    LPoints.Add(PointF(ABubble.Left - ATail, ABubble.Bottom));
    AddArc(ABubble.Right - LRadius, ABubble.Bottom - LRadius, LRadius, 90, 0);
    AddArc(ABubble.Right - LRadius, ABubble.Top + LRadius, LRadius, 0, -90);
    AddArc(ABubble.Left + LRadius, ABubble.Top + LRadius, LRadius, 270, 180);
    AddArc(ABubble.Left - ATail, ABubble.Bottom - ATail, ATail, 0, 90);
    Result := LPoints.ToArray;
  finally
    LPoints.Free;
  end;
  if APlacement = cpEnd then
    for I := 0 to High(Result) do
      Result[I].X := ABubble.Left + ABubble.Right - Result[I].X;
end;

end.
