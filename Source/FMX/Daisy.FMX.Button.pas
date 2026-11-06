unit Daisy.FMX.Button;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, Daisy.Theme, Daisy.SVG, Daisy.FMX.Control;

type
  TDaisyFmxButton = class(TDaisyControl)
  strict private
    FText: string;
    FModalResult: TModalResult;
    FKeyPressed: Boolean;
    FIconPath: string;
    FSVG: TStrings;
    FIconPosition: TDaisyBadgeIconPosition;
    procedure SetSVG(const Value: TStrings);
    procedure SVGChanged(Sender: TObject);
    procedure SetText(const Value: string);
    procedure SetIconPath(const Value: string);
    procedure SetIconPosition(const Value: TDaisyBadgeIconPosition);
  protected
    function IconExtent: Single;
    function IconGapExtent: Single;
    procedure DrawButtonIcon(ALeft: Single; const ARect: TRectF; AColor: TAlphaColor);
    // Normalised icon data derived from SVG (see TDaisySVG)
    property IconPath: string read FIconPath;
    function IsInteractive: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function GetState: TDaisyState; override;
    procedure SizeChanged; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Text: string read FText write SetText;
    // Paste SVG markup or load an .svg file; the icon is drawn next to the text
    property SVG: TStrings read FSVG write SetSVG;
    property IconPosition: TDaisyBadgeIconPosition read FIconPosition write SetIconPosition
      default bipLeft;
    property ModalResult: TModalResult read FModalResult write FModalResult default 0;
  end;

implementation

{ TDaisyFmxButton }

constructor TDaisyFmxButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  FText := 'Button';
  FIconPosition := bipLeft;
  FSVG := TStringList.Create;
  TStringList(FSVG).OnChange := SVGChanged;
  SetBounds(Position.X, Position.Y, 96, DaisyFieldHeight(dzMD));
end;

destructor TDaisyFmxButton.Destroy;
begin
  FSVG.Free;
  inherited Destroy;
end;

procedure TDaisyFmxButton.SetSVG(const Value: TStrings);
begin
  FSVG.Assign(Value);
end;

procedure TDaisyFmxButton.SVGChanged(Sender: TObject);
begin
  SetIconPath(TDaisySVG.IconPath(FSVG.Text));
end;

procedure TDaisyFmxButton.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Repaint;
  end;
end;

function TDaisyFmxButton.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxButton.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyFmxButton.DefaultContentPadding: Integer;
begin
  Result := DaisyFieldPaddingX(SizeKind);
end;

function TDaisyFmxButton.GetState: TDaisyState;
begin
  Result := inherited GetState;
  if FKeyPressed and (Result in [dstNormal, dstHover]) then
    Result := dstPressed;
end;

procedure TDaisyFmxButton.SizeChanged;
begin
  Height := DaisyFieldHeight(SizeKind);
end;

procedure TDaisyFmxButton.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LRect: TRectF;
  LIcon, LGap, LTextW, LTotal, LLeft, LTextLeft, LIconLeft: Single;
begin
  LRect := BodyRect;
  LRect.Inflate(-ResolvedContentPadding, 0);
  LIcon := IconExtent;
  if LIcon = 0 then
  begin
    DrawText(FText, LRect, AColors.Text, DaisyFontSize(SizeKind), False,
      TTextAlign.Center, TTextAlign.Center, False);
    Exit;
  end;

  LTextW := MeasureTextWidth(FText, DaisyFontSize(SizeKind), False);
  LGap := 0;
  if LTextW > 0 then
    LGap := IconGapExtent;
  LTextW := Min(LTextW, Max(0, LRect.Width - LIcon - LGap));
  LTotal := LIcon + LGap + LTextW;
  LLeft := LRect.Left + Max(0, (LRect.Width - LTotal) / 2);
  if FIconPosition = bipLeft then
  begin
    LIconLeft := LLeft;
    LTextLeft := LLeft + LIcon + LGap;
  end
  else
  begin
    LTextLeft := LLeft;
    LIconLeft := LLeft + LTextW + LGap;
  end;
  DrawButtonIcon(LIconLeft, LRect, AColors.Text);
  if LTextW > 0 then
    DrawText(FText, RectF(LTextLeft, LRect.Top, LTextLeft + LTextW, LRect.Bottom), AColors.Text,
      DaisyFontSize(SizeKind), False, TTextAlign.Leading, TTextAlign.Center, False);
end;

procedure TDaisyFmxButton.SetIconPath(const Value: string);
begin
  if FIconPath <> Value then
  begin
    FIconPath := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxButton.SetIconPosition(const Value: TDaisyBadgeIconPosition);
begin
  if FIconPosition <> Value then
  begin
    FIconPosition := Value;
    Repaint;
  end;
end;

function TDaisyFmxButton.IconExtent: Single;
begin
  if FIconPath = '' then
    Result := 0
  else
    Result := DaisyFontSize(SizeKind) + 4;
end;

function TDaisyFmxButton.IconGapExtent: Single;
begin
  Result := 8;
end;

procedure TDaisyFmxButton.DrawButtonIcon(ALeft: Single; const ARect: TRectF; AColor: TAlphaColor);
var
  LSize, LTop: Single;
begin
  LSize := IconExtent;
  if LSize = 0 then
    Exit;
  LTop := ARect.Top + (ARect.Height - LSize) / 2;
  DrawIconPath(FIconPath, RectF(ALeft, LTop, ALeft + LSize, LTop + LSize), AColor);
end;

procedure TDaisyFmxButton.Click;
var
  LForm: TCommonCustomForm;
begin
  inherited Click;
  if (FModalResult <> 0) and (Root <> nil) and (Root.GetObject is TCommonCustomForm) then
  begin
    LForm := TCommonCustomForm(Root.GetObject);
    LForm.ModalResult := FModalResult;
  end;
end;

procedure TDaisyFmxButton.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  inherited KeyDown(Key, KeyChar, Shift);
  if (KeyChar = ' ') or (Key = vkReturn) then
  begin
    FKeyPressed := True;
    Key := 0;
    KeyChar := #0;
    Repaint;
  end;
end;

procedure TDaisyFmxButton.KeyUp(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  LWasPressed: Boolean;
begin
  inherited KeyUp(Key, KeyChar, Shift);
  LWasPressed := FKeyPressed and ((KeyChar = ' ') or (Key = vkReturn) or (Key = vkSpace));
  if LWasPressed then
  begin
    FKeyPressed := False;
    Key := 0;
    KeyChar := #0;
    Repaint;
    Click;
  end;
end;

procedure TDaisyFmxButton.DoExit;
begin
  inherited;
  FKeyPressed := False;
end;

end.
