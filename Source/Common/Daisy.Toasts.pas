unit Daisy.Toasts;

{
  Framework neutral toast message queue shared by TDaisyToast (VCL) and
  TDaisyFmxToast (FMX): messages with a lifetime that fade out at the end.
  Must not reference Vcl.* or FMX.* units.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Daisy.Theme;

type
  TDaisyToastDuration = (tdSeconds3, tdSeconds4, tdSeconds5, tdSeconds8);

  TDaisyToastHPlacement = (thStart, thCenter, thEnd);
  TDaisyToastVPlacement = (tvTop, tvMiddle, tvBottom);

  TDaisyToastMessage = record
    Text: string;
    Variant: TDaisyVariant;
    Born: Double;
    Lifetime: Double;
  end;

  TDaisyToastList = class
  strict private
    FItems: TList<TDaisyToastMessage>;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TDaisyToastMessage;
  public
    const FadeTime = 0.35; // seconds
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AText: string; AVariant: TDaisyVariant; ALifetime, ANow: Double;
      AMaxCount: Integer);
    procedure Clear;
    // Removes message AIndex
    procedure Delete(AIndex: Integer);
    // Removes expired messages; True when something was removed
    function Prune(ANow: Double): Boolean;
    // 1 while visible, fading to 0 during the last FadeTime seconds
    function Opacity(AIndex: Integer; ANow: Double): Single;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TDaisyToastMessage read GetItem; default;
  end;

function DaisyToastSeconds(ADuration: TDaisyToastDuration): Integer;

implementation

function DaisyToastSeconds(ADuration: TDaisyToastDuration): Integer;
begin
  case ADuration of
    tdSeconds3: Result := 3;
    tdSeconds4: Result := 4;
    tdSeconds8: Result := 8;
  else
    Result := 5;
  end;
end;

{ TDaisyToastList }

constructor TDaisyToastList.Create;
begin
  inherited Create;
  FItems := TList<TDaisyToastMessage>.Create;
end;

destructor TDaisyToastList.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TDaisyToastList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TDaisyToastList.GetItem(AIndex: Integer): TDaisyToastMessage;
begin
  Result := FItems[AIndex];
end;

procedure TDaisyToastList.Add(const AText: string; AVariant: TDaisyVariant;
  ALifetime, ANow: Double; AMaxCount: Integer);
var
  LMsg: TDaisyToastMessage;
begin
  LMsg.Text := AText;
  LMsg.Variant := AVariant;
  LMsg.Born := ANow;
  LMsg.Lifetime := ALifetime;
  FItems.Add(LMsg);
  while (AMaxCount > 0) and (FItems.Count > AMaxCount) do
    FItems.Delete(0);
end;

procedure TDaisyToastList.Clear;
begin
  FItems.Clear;
end;

procedure TDaisyToastList.Delete(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    FItems.Delete(AIndex);
end;

function TDaisyToastList.Prune(ANow: Double): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := FItems.Count - 1 downto 0 do
    if ANow - FItems[I].Born >= FItems[I].Lifetime then
    begin
      FItems.Delete(I);
      Result := True;
    end;
end;

function TDaisyToastList.Opacity(AIndex: Integer; ANow: Double): Single;
var
  LLeft: Double;
begin
  LLeft := FItems[AIndex].Born + FItems[AIndex].Lifetime - ANow;
  if LLeft >= FadeTime then
    Result := 1
  else if LLeft <= 0 then
    Result := 0
  else
    Result := LLeft / FadeTime;
end;

end.
