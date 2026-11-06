unit Daisy.FMX.Panel;

{
  TDaisyFmxPanel - a themed container. It looks like a card but has no title or
  body; drop other controls on it.
}

interface

uses
  System.Classes, System.Types, System.UITypes,
  FMX.Types, FMX.Controls, Daisy.Theme, Daisy.FMX.Control;

type
  TDaisyFmxPanel = class(TDaisyControl)
  protected
    function DefaultShadowSize: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{ TDaisyFmxPanel }

constructor TDaisyFmxPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetBounds(Position.X, Position.Y, 320, 200);
end;

function TDaisyFmxPanel.DefaultShadowSize: Integer;
begin
  Result := 2;
end;

function TDaisyFmxPanel.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
var
  LTheme: TDaisyTheme;
begin
  LTheme := Theme;
  Result := DaisyResolveColors(LTheme, Variant, Style, dstNormal);
  if not Enabled then
    Exit;

  // A panel is not a button: its neutral look sits on base-100 and has no hover state
  case Style of
    dsSolid:
      begin
        Result.Border := TAlphaColors.Null;
        if Variant = dvDefault then
        begin
          Result.Background := LTheme.Base100;
          Result.Text := LTheme.BaseContent;
        end;
      end;
    dsOutline, dsDash:
      begin
        Result.Background := LTheme.Base100;
        Result.Text := LTheme.BaseContent;
        if Variant = dvDefault then
          Result.Border := LTheme.Base300;
      end;
    dsSoft:
      begin
        Result.Border := TAlphaColors.Null;
        if Variant = dvDefault then
          Result.Background := LTheme.Base200;
        Result.Text := LTheme.BaseContent;
      end;
  end;
end;

end.
