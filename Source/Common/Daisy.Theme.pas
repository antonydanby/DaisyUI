unit Daisy.Theme;

{
  Framework neutral part of the DaisyUI component set (shared by VCL and FMX).
  Holds the themes, the sizing metrics, the colour resolution rules and the
  shared icon geometry so that both frameworks render the same look.
  Must not reference Vcl.* or FMX.* units.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Generics.Collections;

type
  TDaisyThemeKind = (dtInherit, dtLight, dtDark, dtCupcake, dtDracula, dtCorporate, dtPastel,
    dtWireframe, dtCmyk, dtWinter, dtDim, dtNord, dtSilk, dtBumblebee, dtEmerald, dtHalloween,
    dtGarden, dtForest, dtLofi, dtFantasy, dtAutumn);

  TDaisyVariant = (dvDefault, dvNeutral, dvPrimary, dvSecondary, dvAccent,
    dvInfo, dvSuccess, dvWarning, dvError);

  TDaisyStyle = (dsSolid, dsOutline, dsDash, dsSoft, dsGhost);

  TDaisySize = (dzXS, dzSM, dzMD, dzLG, dzXL);

  TDaisyState = (dstNormal, dstHover, dstPressed, dstDisabled);

  TDaisyIconKind = (diAuto, diNone, diInfo, diSuccess, diWarning, diError);

  TDaisyBadgeIconPosition = (bipLeft, bipRight);

  TDaisyTheme = record
    Name: string;
    IsDark: Boolean;
    Base100, Base200, Base300, BaseContent: TAlphaColor;
    BorderColor: TAlphaColor;
    Primary, PrimaryContent: TAlphaColor;
    Secondary, SecondaryContent: TAlphaColor;
    Accent, AccentContent: TAlphaColor;
    Neutral, NeutralContent: TAlphaColor;
    Info, InfoContent: TAlphaColor;
    Success, SuccessContent: TAlphaColor;
    Warning, WarningContent: TAlphaColor;
    Error, ErrorContent: TAlphaColor;
    RadiusSelector, RadiusField, RadiusBox: Integer;
    BorderWidth: Integer;
  end;

  TDaisyPalette = record
    Fill, Content: TAlphaColor;
  end;

  TDaisyColors = record
    Background, Border, Text: TAlphaColor;
    Dashed: Boolean;
  end;

  TDaisyPolyline = TArray<TPointF>;
  TDaisyIconPaths = TArray<TDaisyPolyline>;

  // Global theme selection. Controls with ThemeKind = dtInherit follow it.
  TDaisyThemeManager = class
  strict private
    FCurrent: TDaisyThemeKind;
    FListeners: TList<TNotifyEvent>;
    procedure SetCurrent(const Value: TDaisyThemeKind);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddListener(const AListener: TNotifyEvent);
    procedure RemoveListener(const AListener: TNotifyEvent);
    property Current: TDaisyThemeKind read FCurrent write SetCurrent;
  end;

function DaisyThemes: TDaisyThemeManager;
procedure DaisyRemoveThemeListener(const AListener: TNotifyEvent);

function DaisyGetTheme(AKind: TDaisyThemeKind): TDaisyTheme;
// Display name of a theme ('Light', 'Dark' ...); dtInherit gives the current theme's name
function DaisyThemeCaption(AKind: TDaisyThemeKind): string;

function DaisyMix(AColor, AOther: TAlphaColor; AAmount: Single): TAlphaColor;
function DaisyWithAlpha(AColor: TAlphaColor; AFactor: Single): TAlphaColor;

function DaisyVariantPalette(const ATheme: TDaisyTheme; AVariant: TDaisyVariant): TDaisyPalette;
function DaisyResolveColors(const ATheme: TDaisyTheme; AVariant: TDaisyVariant;
  AStyle: TDaisyStyle; AState: TDaisyState): TDaisyColors;

function DaisyFieldHeight(ASize: TDaisySize): Integer;
function DaisyFieldPaddingX(ASize: TDaisySize): Integer;
function DaisyFontSize(ASize: TDaisySize): Integer;
function DaisyCardPadding(ASize: TDaisySize): Integer;
function DaisyCardTitleSize(ASize: TDaisySize): Integer;

function DaisyBadgeHeight(ASize: TDaisySize): Integer;
function DaisyBadgeFontSize(ASize: TDaisySize): Integer;
// Badge colours differ from the button rules: a solid badge has no darker border,
// the default badge is white with a base-200 border, and ghost ignores the variant.
function DaisyBadgeColors(const ATheme: TDaisyTheme; AVariant: TDaisyVariant;
  AStyle: TDaisyStyle): TDaisyColors;

function DaisyResolveIcon(AKind: TDaisyIconKind; AVariant: TDaisyVariant): TDaisyIconKind;
// Icon outline geometry in a 24 x 24 box, to be stroked (~2 units, round caps/joins).
function DaisyIconPaths(AKind: TDaisyIconKind): TDaisyIconPaths;
// Converts SVG path data (the "d" attribute: M L H V C S Q T A Z, absolute or relative)
// to polylines. Curves are flattened. Coordinates are expected in a 24 x 24 viewBox.
// Malformed data yields whatever was parsed before the error.
function DaisyParseSvgPath(const AData: string): TDaisyIconPaths;

// Colours the native window caption (title bar) of AWnd (an HWND) from ATheme, or restores
// the system colours when AEnabled is False. Needs Windows 11 for colours (Windows 10
// only honours the dark flag); silently does nothing elsewhere.
procedure DaisySetTitleBarColors(AWnd: NativeUInt; AEnabled: Boolean; const ATheme: TDaisyTheme);

implementation

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.Dwmapi,
{$ENDIF}
  System.Math;

procedure DaisySetTitleBarColors(AWnd: NativeUInt; AEnabled: Boolean; const ATheme: TDaisyTheme);
{$IFDEF MSWINDOWS}
const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  DWMWA_CAPTION_COLOR = 35;
  DWMWA_TEXT_COLOR = 36;
  DWMWA_COLOR_DEFAULT = $FFFFFFFF;

  function ToColorRef(AColor: TAlphaColor): DWORD;
  var
    LRec: TAlphaColorRec;
  begin
    LRec := TAlphaColorRec(AColor);
    Result := DWORD(LRec.R) or (DWORD(LRec.G) shl 8) or (DWORD(LRec.B) shl 16);
  end;

var
  LDark: BOOL;
  LCaption, LText: DWORD;
begin
  if AWnd = 0 then
    Exit;
  LDark := AEnabled and ATheme.IsDark;
  if AEnabled then
  begin
    LCaption := ToColorRef(ATheme.Base100);
    LText := ToColorRef(ATheme.BaseContent);
  end
  else
  begin
    LCaption := DWMWA_COLOR_DEFAULT;
    LText := DWMWA_COLOR_DEFAULT;
  end;
  DwmSetWindowAttribute(HWND(AWnd), DWMWA_USE_IMMERSIVE_DARK_MODE, @LDark, SizeOf(LDark));
  DwmSetWindowAttribute(HWND(AWnd), DWMWA_CAPTION_COLOR, @LCaption, SizeOf(LCaption));
  DwmSetWindowAttribute(HWND(AWnd), DWMWA_TEXT_COLOR, @LText, SizeOf(LText));
end;
{$ELSE}
begin
end;
{$ENDIF}

var
  GManager: TDaisyThemeManager = nil;

function DaisyThemes: TDaisyThemeManager;
begin
  if GManager = nil then
    GManager := TDaisyThemeManager.Create;
  Result := GManager;
end;

procedure DaisyRemoveThemeListener(const AListener: TNotifyEvent);
begin
  if GManager <> nil then
    GManager.RemoveListener(AListener);
end;

{ TDaisyThemeManager }

constructor TDaisyThemeManager.Create;
begin
  inherited Create;
  FCurrent := dtLight;
  FListeners := TList<TNotifyEvent>.Create;
end;

destructor TDaisyThemeManager.Destroy;
begin
  FListeners.Free;
  inherited;
end;

procedure TDaisyThemeManager.AddListener(const AListener: TNotifyEvent);
begin
  if not FListeners.Contains(AListener) then
    FListeners.Add(AListener);
end;

procedure TDaisyThemeManager.RemoveListener(const AListener: TNotifyEvent);
begin
  FListeners.Remove(AListener);
end;

procedure TDaisyThemeManager.SetCurrent(const Value: TDaisyThemeKind);
var
  LListeners: TArray<TNotifyEvent>;
  LListener: TNotifyEvent;
  LValue: TDaisyThemeKind;
begin
  LValue := Value;
  if LValue = dtInherit then
    LValue := dtLight;
  if LValue = FCurrent then
    Exit;
  FCurrent := LValue;
  LListeners := FListeners.ToArray; // listeners may unregister while notified
  for LListener in LListeners do
    LListener(Self);
end;

{ Themes }

function DaisyBuildTheme(AKind: TDaisyThemeKind): TDaisyTheme;
begin
  Result := Default(TDaisyTheme);
  Result.BorderWidth := 1;
  Result.RadiusSelector := 8;
  Result.RadiusField := 4;
  Result.RadiusBox := 8;

  case AKind of
    dtDark:
      begin
        Result.Name := 'dark';
        Result.IsDark := True;
        Result.Base100 := $FF1D232A;
        Result.Base200 := $FF191E24;
        Result.Base300 := $FF15191E;
        Result.BaseContent := $FFECF9FF;
        Result.Primary := $FF605DFF;
        Result.PrimaryContent := $FFEDF0FF;
        Result.Secondary := $FFF43098;
        Result.SecondaryContent := $FFFFE8F4;
        Result.Accent := $FF00D3BB;
        Result.AccentContent := $FF084D49;
        Result.Neutral := $FF2A323C;
        Result.NeutralContent := $FFA6ADBB;
        Result.Info := $FF00BAFE;
        Result.InfoContent := $FF042E49;
        Result.Success := $FF00D390;
        Result.SuccessContent := $FF004630;
        Result.Warning := $FFFCB700;
        Result.WarningContent := $FF422006;
        Result.Error := $FFFF627D;
        Result.ErrorContent := $FF4C0519;
      end;
    dtCupcake:
      begin
        Result.Name := 'cupcake';
        Result.Base100 := $FFFAF7F5;
        Result.Base200 := $FFEFEAE6;
        Result.Base300 := $FFE7E2DF;
        Result.BaseContent := $FF291334;
        Result.Primary := $FF65C3C8;
        Result.PrimaryContent := $FF291334;
        Result.Secondary := $FFEF9FBC;
        Result.SecondaryContent := $FF291334;
        Result.Accent := $FFEEAF3A;
        Result.AccentContent := $FF291334;
        Result.Neutral := $FF291334;
        Result.NeutralContent := $FFFAF7F5;
        Result.Info := $FF3ABFF8;
        Result.InfoContent := $FF002B3D;
        Result.Success := $FF36D399;
        Result.SuccessContent := $FF003320;
        Result.Warning := $FFFBBD23;
        Result.WarningContent := $FF382800;
        Result.Error := $FFF87272;
        Result.ErrorContent := $FF470000;
        Result.RadiusSelector := 16;
        Result.RadiusField := 32;
        Result.RadiusBox := 16;
      end;
    dtDracula:
      begin
        Result.Name := 'dracula';
        Result.IsDark := True;
        Result.Base100 := $FF282A36;
        Result.Base200 := $FF232530;
        Result.Base300 := $FF1E1F29;
        Result.BaseContent := $FFF8F8F2;
        Result.Primary := $FFFF79C6;
        Result.PrimaryContent := $FF161A21;
        Result.Secondary := $FFBD93F9;
        Result.SecondaryContent := $FF161A21;
        Result.Accent := $FFFFB86C;
        Result.AccentContent := $FF161A21;
        Result.Neutral := $FF414558;
        Result.NeutralContent := $FFF8F8F2;
        Result.Info := $FF8BE9FD;
        Result.InfoContent := $FF161A21;
        Result.Success := $FF50FA7B;
        Result.SuccessContent := $FF161A21;
        Result.Warning := $FFF1FA8C;
        Result.WarningContent := $FF161A21;
        Result.Error := $FFFF5555;
        Result.ErrorContent := $FF161A21;
      end;
    dtCorporate:
      begin
        Result.Name := 'corporate';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFE8E8E8;
        Result.Base300 := $FFD1D1D1;
        Result.BaseContent := $FF181A2A;
        Result.Primary := $FF0082CE;
        Result.PrimaryContent := $FFFFFFFF;
        Result.Secondary := $FF61738D;
        Result.SecondaryContent := $FFFFFFFF;
        Result.Accent := $FF009689;
        Result.AccentContent := $FFFFFFFF;
        Result.Neutral := $FF000000;
        Result.NeutralContent := $FFFFFFFF;
        Result.Info := $FF0090B5;
        Result.InfoContent := $FFFFFFFF;
        Result.Success := $FF00A43B;
        Result.SuccessContent := $FFFFFFFF;
        Result.Warning := $FFFDC700;
        Result.WarningContent := $FF000000;
        Result.Error := $FFFF6266;
        Result.ErrorContent := $FF000000;
        Result.RadiusSelector := 4;
        Result.RadiusField := 4;
        Result.RadiusBox := 4;
      end;
    dtPastel:
      begin
        Result.Name := 'pastel';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFF9FAFB;
        Result.Base300 := $FFE5E6E7;
        Result.BaseContent := $FF161616;
        Result.Primary := $FFE9D4FF;
        Result.PrimaryContent := $FF8000D9;
        Result.Secondary := $FFFECCD2;
        Result.SecondaryContent := $FFC50035;
        Result.Accent := $FFA3F2CE;
        Result.AccentContent := $FF007853;
        Result.Neutral := $FF61738D;
        Result.NeutralContent := $FFDFE5ED;
        Result.Info := $FF51E8FB;
        Result.InfoContent := $FF007595;
        Result.Success := $FF7AF1A7;
        Result.SuccessContent := $FF008033;
        Result.Warning := $FFFFB667;
        Result.WarningContent := $FFC93400;
        Result.Error := $FFFF9FA0;
        Result.ErrorContent := $FFBF0004;
        Result.RadiusSelector := 16;
        Result.RadiusField := 32;
        Result.RadiusBox := 16;
        Result.BorderWidth := 2;
      end;
    dtWireframe:
      begin
        Result.Name := 'wireframe';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFF5F5F5;
        Result.Base300 := $FFEBEBEB;
        Result.BaseContent := $FF161616;
        Result.Primary := $FFD4D4D4;
        Result.PrimaryContent := $FF242424;
        Result.Secondary := $FFD4D4D4;
        Result.SecondaryContent := $FF242424;
        Result.Accent := $FFD4D4D4;
        Result.AccentContent := $FF242424;
        Result.Neutral := $FFD4D4D4;
        Result.NeutralContent := $FF242424;
        Result.Info := $FF005889;
        Result.InfoContent := $FFB8E6FE;
        Result.Success := $FF006044;
        Result.SuccessContent := $FFA3F2CE;
        Result.Warning := $FF963B00;
        Result.WarningContent := $FFFDE484;
        Result.Error := $FF9D0410;
        Result.ErrorContent := $FFFEC8C8;
        Result.RadiusSelector := 0;
        Result.RadiusField := 4;
        Result.RadiusBox := 4;
      end;
    dtCmyk:
      begin
        Result.Name := 'cmyk';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFEEEEEE;
        Result.Base300 := $FFDEDEDE;
        Result.BaseContent := $FF161616;
        Result.Primary := $FF45AEEE;
        Result.PrimaryContent := $FF020B13;
        Result.Secondary := $FFE8488A;
        Result.SecondaryContent := $FF130207;
        Result.Accent := $FFFFF234;
        Result.AccentContent := $FF161401;
        Result.Neutral := $FF1A1A1A;
        Result.NeutralContent := $FFCBCBCB;
        Result.Info := $FF4BA8C0;
        Result.InfoContent := $FF020A0D;
        Result.Success := $FF823290;
        Result.SuccessContent := $FFE6D5E9;
        Result.Warning := $FFEE8134;
        Result.WarningContent := $FF130601;
        Result.Error := $FFE93F33;
        Result.ErrorContent := $FF130101;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtWinter:
      begin
        Result.Name := 'winter';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFF2F7FE;
        Result.Base300 := $FFE3E9F4;
        Result.BaseContent := $FF394E6A;
        Result.Primary := $FF0069FF;
        Result.PrimaryContent := $FFCEE4FF;
        Result.Secondary := $FF463AA2;
        Result.SecondaryContent := $FFD5D7EE;
        Result.Accent := $FFC148AC;
        Result.AccentContent := $FF0E020B;
        Result.Neutral := $FF021431;
        Result.NeutralContent := $FFC5CBD2;
        Result.Info := $FF94E7FB;
        Result.InfoContent := $FF081315;
        Result.Success := $FF81CFD1;
        Result.SuccessContent := $FF060F10;
        Result.Warning := $FFEFD7BC;
        Result.WarningContent := $FF14110D;
        Result.Error := $FFE58B8B;
        Result.ErrorContent := $FF120707;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtDim:
      begin
        Result.Name := 'dim';
        Result.IsDark := True;
        Result.Base100 := $FF2A303C;
        Result.Base200 := $FF242933;
        Result.Base300 := $FF20252E;
        Result.BaseContent := $FFB2CCD6;
        Result.Primary := $FF9FE88D;
        Result.PrimaryContent := $FF091307;
        Result.Secondary := $FFFF7D5D;
        Result.SecondaryContent := $FF160503;
        Result.Accent := $FFC792E9;
        Result.AccentContent := $FF0E0813;
        Result.Neutral := $FF1C212B;
        Result.NeutralContent := $FFB2CCD6;
        Result.Info := $FF28EBFF;
        Result.InfoContent := $FF011316;
        Result.Success := $FF62EFBD;
        Result.SuccessContent := $FF03140D;
        Result.Warning := $FFEFD057;
        Result.WarningContent := $FF141003;
        Result.Error := $FFFFAE9B;
        Result.ErrorContent := $FF160B09;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtNord:
      begin
        Result.Name := 'nord';
        Result.Base100 := $FFECEFF4;
        Result.Base200 := $FFE5E9F0;
        Result.Base300 := $FFD8DEE9;
        Result.BaseContent := $FF2E3440;
        Result.Primary := $FF5E81AC;
        Result.PrimaryContent := $FF03060B;
        Result.Secondary := $FF81A1C1;
        Result.SecondaryContent := $FF06090D;
        Result.Accent := $FF88C0D0;
        Result.AccentContent := $FF070D10;
        Result.Neutral := $FF4C566A;
        Result.NeutralContent := $FFD8DEE9;
        Result.Info := $FFB48EAD;
        Result.InfoContent := $FF0C070B;
        Result.Success := $FFA3BE8D;
        Result.SuccessContent := $FF0A0D07;
        Result.Warning := $FFEBCB8B;
        Result.WarningContent := $FF130F07;
        Result.Error := $FFBF616A;
        Result.ErrorContent := $FF0D0304;
        Result.RadiusSelector := 16;
        Result.RadiusField := 4;
        Result.RadiusBox := 8;
      end;
    dtSilk:
      begin
        Result.Name := 'silk';
        Result.Base100 := $FFF7F5F3;
        Result.Base200 := $FFF3EDE9;
        Result.Base300 := $FFE2DDD9;
        Result.BaseContent := $FF4B4743;
        Result.Primary := $FF1C1C29;
        Result.PrimaryContent := $FFE1FF00;
        Result.Secondary := $FF1C1C29;
        Result.SecondaryContent := $FFFF7700;
        Result.Accent := $FF1C1C29;
        Result.AccentContent := $FF00FFF8;
        Result.Neutral := $FF161616;
        Result.NeutralContent := $FFC2BDB9;
        Result.Info := $FF78C8FF;
        Result.InfoContent := $FF003162;
        Result.Success := $FFAFD89E;
        Result.SuccessContent := $FF052800;
        Result.Warning := $FFEFC375;
        Result.WarningContent := $FF714900;
        Result.Error := $FFFF7878;
        Result.ErrorContent := $FF800001;
        Result.RadiusSelector := 32;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
        Result.BorderWidth := 2;
      end;
    dtBumblebee:
      begin
        Result.Name := 'bumblebee';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFF5F5F5;
        Result.Base300 := $FFE4E4E4;
        Result.BaseContent := $FF161616;
        Result.Primary := $FFFDC700;
        Result.PrimaryContent := $FF733E0A;
        Result.Secondary := $FFFF8904;
        Result.SecondaryContent := $FF7C2808;
        Result.Accent := $FF000000;
        Result.AccentContent := $FFFFFFFF;
        Result.Neutral := $FF433F3A;
        Result.NeutralContent := $FFE6E4E3;
        Result.Info := $FF00BAFE;
        Result.InfoContent := $FF014A70;
        Result.Success := $FF00D390;
        Result.SuccessContent := $FF004C39;
        Result.Warning := $FFFCB700;
        Result.WarningContent := $FF793205;
        Result.Error := $FFFF6266;
        Result.ErrorContent := $FF801518;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtEmerald:
      begin
        Result.Name := 'emerald';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFE8E8E8;
        Result.Base300 := $FFD1D1D1;
        Result.BaseContent := $FF333C4D;
        Result.Primary := $FF66CC8A;
        Result.PrimaryContent := $FF223D30;
        Result.Secondary := $FF377CFB;
        Result.SecondaryContent := $FFFFFFFF;
        Result.Accent := $FFF68067;
        Result.AccentContent := $FF000000;
        Result.Neutral := $FF333C4D;
        Result.NeutralContent := $FFF9FAFB;
        Result.Info := $FF00B5FF;
        Result.InfoContent := $FF000000;
        Result.Success := $FF00A96E;
        Result.SuccessContent := $FF000000;
        Result.Warning := $FFFFBE00;
        Result.WarningContent := $FF000000;
        Result.Error := $FFFF5861;
        Result.ErrorContent := $FF000000;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtHalloween:
      begin
        Result.Name := 'halloween';
        Result.IsDark := True;
        Result.Base100 := $FF1B1816;
        Result.Base200 := $FF0B0908;
        Result.Base300 := $FF000000;
        Result.BaseContent := $FFCDCDCD;
        Result.Primary := $FFFF8F00;
        Result.PrimaryContent := $FF131616;
        Result.Secondary := $FF7A00C2;
        Result.SecondaryContent := $FFE3D4F6;
        Result.Accent := $FF42AA00;
        Result.AccentContent := $FF000000;
        Result.Neutral := $FF2F1B05;
        Result.NeutralContent := $FFD2CCC7;
        Result.Info := $FF2563EB;
        Result.InfoContent := $FFD2E2FF;
        Result.Success := $FF18A34A;
        Result.SuccessContent := $FF000A02;
        Result.Warning := $FFD97708;
        Result.WarningContent := $FF110500;
        Result.Error := $FFF35248;
        Result.ErrorContent := $FF140202;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtGarden:
      begin
        Result.Name := 'garden';
        Result.Base100 := $FFE9E7E7;
        Result.Base200 := $FFD4D2D2;
        Result.Base300 := $FFBEBDBD;
        Result.BaseContent := $FF100F0F;
        Result.Primary := $FFFE0075;
        Result.PrimaryContent := $FFFFFFFF;
        Result.Secondary := $FF8E4162;
        Result.SecondaryContent := $FFEAD7DE;
        Result.Accent := $FF5C7F67;
        Result.AccentContent := $FFFFFFFF;
        Result.Neutral := $FF291E00;
        Result.NeutralContent := $FFE9E7E7;
        Result.Info := $FF00B5FF;
        Result.InfoContent := $FF000000;
        Result.Success := $FF00A96E;
        Result.SuccessContent := $FF000000;
        Result.Warning := $FFFFBE00;
        Result.WarningContent := $FF000000;
        Result.Error := $FFFF5861;
        Result.ErrorContent := $FF000000;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtForest:
      begin
        Result.Name := 'forest';
        Result.IsDark := True;
        Result.Base100 := $FF1B1717;
        Result.Base200 := $FF161212;
        Result.Base300 := $FF110D0D;
        Result.BaseContent := $FFCAC9C9;
        Result.Primary := $FF1FB854;
        Result.PrimaryContent := $FF000000;
        Result.Secondary := $FF1EB88E;
        Result.SecondaryContent := $FF000C07;
        Result.Accent := $FF1FB8AB;
        Result.AccentContent := $FF010C0B;
        Result.Neutral := $FF19362D;
        Result.NeutralContent := $FFCDD3D1;
        Result.Info := $FF00B5FF;
        Result.InfoContent := $FF000000;
        Result.Success := $FF00A96E;
        Result.SuccessContent := $FF000000;
        Result.Warning := $FFFFBE00;
        Result.WarningContent := $FF000000;
        Result.Error := $FFFF5861;
        Result.ErrorContent := $FF000000;
        Result.RadiusSelector := 16;
        Result.RadiusField := 32;
        Result.RadiusBox := 16;
      end;
    dtLofi:
      begin
        Result.Name := 'lofi';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFF5F5F5;
        Result.Base300 := $FFEBEBEB;
        Result.BaseContent := $FF000000;
        Result.Primary := $FF0D0D0D;
        Result.PrimaryContent := $FFFFFFFF;
        Result.Secondary := $FF1A1919;
        Result.SecondaryContent := $FFFFFFFF;
        Result.Accent := $FF262626;
        Result.AccentContent := $FFFFFFFF;
        Result.Neutral := $FF000000;
        Result.NeutralContent := $FFFFFFFF;
        Result.Info := $FF5FCFDD;
        Result.InfoContent := $FF031011;
        Result.Success := $FF69FEC3;
        Result.SuccessContent := $FF04160E;
        Result.Warning := $FFFFCE69;
        Result.WarningContent := $FF170F04;
        Result.Error := $FFFF9181;
        Result.ErrorContent := $FF180706;
        Result.RadiusSelector := 32;
        Result.RadiusField := 4;
        Result.RadiusBox := 8;
      end;
    dtFantasy:
      begin
        Result.Name := 'fantasy';
        Result.Base100 := $FFFFFFFF;
        Result.Base200 := $FFE8E8E8;
        Result.Base300 := $FFD1D1D1;
        Result.BaseContent := $FF1F2937;
        Result.Primary := $FF6D0076;
        Result.PrimaryContent := $FFE3CEE4;
        Result.Secondary := $FF0075C2;
        Result.SecondaryContent := $FFCFE4F4;
        Result.Accent := $FFFF8600;
        Result.AccentContent := $FF180600;
        Result.Neutral := $FF1F2937;
        Result.NeutralContent := $FFCDD0D3;
        Result.Info := $FF00B5FF;
        Result.InfoContent := $FF000000;
        Result.Success := $FF00A96E;
        Result.SuccessContent := $FF000000;
        Result.Warning := $FFFFBE00;
        Result.WarningContent := $FF000000;
        Result.Error := $FFFF5861;
        Result.ErrorContent := $FF000000;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
    dtAutumn:
      begin
        Result.Name := 'autumn';
        Result.Base100 := $FFF1F1F1;
        Result.Base200 := $FFDBDBDB;
        Result.Base300 := $FFC5C5C5;
        Result.BaseContent := $FF141414;
        Result.Primary := $FF8C0327;
        Result.PrimaryContent := $FFEDD0D0;
        Result.Secondary := $FFD85251;
        Result.SecondaryContent := $FF110202;
        Result.Accent := $FFD59B6B;
        Result.AccentContent := $FF100904;
        Result.Neutral := $FF826A5C;
        Result.NeutralContent := $FFE5E0DD;
        Result.Info := $FF44ADBB;
        Result.InfoContent := $FF020B0D;
        Result.Success := $FF499380;
        Result.SuccessContent := $FF020806;
        Result.Warning := $FFE97F16;
        Result.WarningContent := $FF130600;
        Result.Error := $FFD40014;
        Result.ErrorContent := $FFFFD4D1;
        Result.RadiusSelector := 16;
        Result.RadiusField := 8;
        Result.RadiusBox := 16;
      end;
  else
    Result.Name := 'light';
    Result.Base100 := $FFFFFFFF;
    Result.Base200 := $FFF5F5F5;
    Result.Base300 := $FFEDEDED;
    Result.BaseContent := $FF18181B;
    Result.Primary := $FF422AD5;
    Result.PrimaryContent := $FFE0E7FF;
    Result.Secondary := $FFF43098;
    Result.SecondaryContent := $FFFFE4F1;
    Result.Accent := $FF00D3BB;
    Result.AccentContent := $FF084D49;
    Result.Neutral := $FF09090B;
    Result.NeutralContent := $FFE4E4E7;
    Result.Info := $FF00BAFE;
    Result.InfoContent := $FF042E49;
    Result.Success := $FF00D390;
    Result.SuccessContent := $FF004630;
    Result.Warning := $FFFCB700;
    Result.WarningContent := $FF422006;
    Result.Error := $FFFF627D;
    Result.ErrorContent := $FF4C0519;
  end;
end;

function DaisyGetTheme(AKind: TDaisyThemeKind): TDaisyTheme;
begin
  if AKind = dtInherit then
    AKind := DaisyThemes.Current;

  Result := DaisyBuildTheme(AKind);
  // Base300 is nearly the same as Base100 on dark themes, so borders derive from the content colour.
  if Result.IsDark then
    Result.BorderColor := DaisyMix(Result.Base100, Result.BaseContent, 0.2)
  else
    Result.BorderColor := Result.Base300;
end;

function DaisyThemeCaption(AKind: TDaisyThemeKind): string;
const
  CNames: array[TDaisyThemeKind] of string = ('', 'Light', 'Dark', 'Cupcake', 'Dracula',
    'Corporate', 'Pastel', 'Wireframe', 'CMYK', 'Winter', 'Dim', 'Nord', 'Silk',
    'Bumblebee', 'Emerald', 'Halloween', 'Garden', 'Forest', 'Lofi', 'Fantasy', 'Autumn');
begin
  if AKind = dtInherit then
    AKind := DaisyThemes.Current;
  Result := CNames[AKind];
end;

{ Colours }

function DaisyMix(AColor, AOther: TAlphaColor; AAmount: Single): TAlphaColor;
var
  LA, LB, LR: TAlphaColorRec;

  function Lerp(AFrom, ATo: Byte): Byte;
  begin
    Result := Round(AFrom + (ATo - AFrom) * AAmount);
  end;

begin
  AAmount := EnsureRange(AAmount, 0, 1);
  LA := TAlphaColorRec(AColor);
  LB := TAlphaColorRec(AOther);
  LR.A := Lerp(LA.A, LB.A);
  LR.R := Lerp(LA.R, LB.R);
  LR.G := Lerp(LA.G, LB.G);
  LR.B := Lerp(LA.B, LB.B);
  Result := LR.Color;
end;

function DaisyWithAlpha(AColor: TAlphaColor; AFactor: Single): TAlphaColor;
var
  LRec: TAlphaColorRec;
begin
  LRec := TAlphaColorRec(AColor);
  LRec.A := Round(LRec.A * EnsureRange(AFactor, 0, 1));
  Result := LRec.Color;
end;

function DaisyVariantPalette(const ATheme: TDaisyTheme; AVariant: TDaisyVariant): TDaisyPalette;
begin
  case AVariant of
    dvNeutral:   begin Result.Fill := ATheme.Neutral;   Result.Content := ATheme.NeutralContent; end;
    dvPrimary:   begin Result.Fill := ATheme.Primary;   Result.Content := ATheme.PrimaryContent; end;
    dvSecondary: begin Result.Fill := ATheme.Secondary; Result.Content := ATheme.SecondaryContent; end;
    dvAccent:    begin Result.Fill := ATheme.Accent;    Result.Content := ATheme.AccentContent; end;
    dvInfo:      begin Result.Fill := ATheme.Info;      Result.Content := ATheme.InfoContent; end;
    dvSuccess:   begin Result.Fill := ATheme.Success;   Result.Content := ATheme.SuccessContent; end;
    dvWarning:   begin Result.Fill := ATheme.Warning;   Result.Content := ATheme.WarningContent; end;
    dvError:     begin Result.Fill := ATheme.Error;     Result.Content := ATheme.ErrorContent; end;
  else
    Result.Fill := ATheme.Base200;
    Result.Content := ATheme.BaseContent;
  end;
end;

function DaisyResolveColors(const ATheme: TDaisyTheme; AVariant: TDaisyVariant;
  AStyle: TDaisyStyle; AState: TDaisyState): TDaisyColors;
const
  CBlack = TAlphaColor($FF000000);
var
  LPalette: TDaisyPalette;
  LTint: TAlphaColor;
  LAmount: Single;
begin
  Result := Default(TDaisyColors);
  LPalette := DaisyVariantPalette(ATheme, AVariant);

  if AVariant = dvDefault then
    LTint := ATheme.BaseContent
  else
    LTint := LPalette.Fill;

  if AState = dstDisabled then
  begin
    Result.Background := DaisyWithAlpha(ATheme.BaseContent, 0.1);
    Result.Border := Result.Background;
    Result.Text := DaisyWithAlpha(ATheme.BaseContent, 0.3);
    if AStyle = dsGhost then
      Result.Background := TAlphaColors.Null;
    Exit;
  end;

  case AStyle of
    dsOutline, dsDash:
      begin
        Result.Dashed := AStyle = dsDash;
        Result.Border := LTint;
        if AState = dstNormal then
        begin
          Result.Background := TAlphaColors.Null;
          Result.Text := LTint;
        end
        else
        begin
          Result.Background := LTint;
          if AState = dstPressed then
            Result.Background := DaisyMix(LTint, CBlack, 0.1);
          if AVariant = dvDefault then
            Result.Text := ATheme.Base100
          else
            Result.Text := LPalette.Content;
        end;
      end;

    dsSoft:
      begin
        case AState of
          dstHover: LAmount := 0.16;
          dstPressed: LAmount := 0.24;
        else
          LAmount := 0.08;
        end;
        Result.Background := DaisyMix(ATheme.Base100, LTint, LAmount);
        Result.Border := DaisyMix(ATheme.Base100, LTint, LAmount + 0.04);
        Result.Text := LTint;
      end;

    dsGhost:
      begin
        case AState of
          dstHover: LAmount := 0.1;
          dstPressed: LAmount := 0.18;
        else
          LAmount := 0;
        end;
        Result.Background := DaisyWithAlpha(LTint, LAmount);
        Result.Border := TAlphaColors.Null;
        Result.Text := LTint;
      end;
  else
    // dsSolid
    case AState of
      dstHover: LAmount := 0.07;
      dstPressed: LAmount := 0.14;
    else
      LAmount := 0;
    end;
    Result.Background := DaisyMix(LPalette.Fill, CBlack, LAmount);
    Result.Border := DaisyMix(Result.Background, CBlack, 0.05);
    Result.Text := LPalette.Content;
  end;
end;

{ Metrics }

function DaisyFieldHeight(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (24, 32, 40, 48, 56);
begin
  Result := C[ASize];
end;

function DaisyFieldPaddingX(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (8, 12, 16, 20, 24);
begin
  Result := C[ASize];
end;

function DaisyFontSize(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (11, 12, 14, 18, 22);
begin
  Result := C[ASize];
end;

function DaisyCardPadding(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (8, 16, 24, 32, 40);
begin
  Result := C[ASize];
end;

function DaisyCardTitleSize(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (14, 16, 20, 24, 28);
begin
  Result := C[ASize];
end;

function DaisyBadgeHeight(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (16, 20, 24, 28, 32);
begin
  Result := C[ASize];
end;

function DaisyBadgeFontSize(ASize: TDaisySize): Integer;
const
  C: array[TDaisySize] of Integer = (10, 12, 14, 16, 18);
begin
  Result := C[ASize];
end;

function DaisyBadgeColors(const ATheme: TDaisyTheme; AVariant: TDaisyVariant;
  AStyle: TDaisyStyle): TDaisyColors;
var
  LPalette: TDaisyPalette;
  LTint: TAlphaColor;
begin
  Result := Default(TDaisyColors);
  LPalette := DaisyVariantPalette(ATheme, AVariant);
  if AVariant = dvDefault then
    LTint := ATheme.BaseContent
  else
    LTint := LPalette.Fill;

  if AStyle = dsGhost then
  begin
    Result.Background := ATheme.Base200;
    Result.Border := ATheme.Base200;
    Result.Text := ATheme.BaseContent;
    Exit;
  end;

  case AStyle of
    dsOutline, dsDash:
      begin
        Result.Dashed := AStyle = dsDash;
        Result.Background := TAlphaColors.Null;
        Result.Border := LTint;
        Result.Text := LTint;
      end;
    dsSoft:
      begin
        Result.Background := DaisyMix(ATheme.Base100, LTint, 0.08);
        Result.Border := DaisyMix(ATheme.Base100, LTint, 0.1);
        Result.Text := LTint;
      end;
  else
    if AVariant = dvDefault then
    begin
      Result.Background := ATheme.Base100;
      Result.Border := ATheme.Base200;
      Result.Text := ATheme.BaseContent;
    end
    else
    begin
      Result.Background := LPalette.Fill;
      Result.Border := LPalette.Fill;
      Result.Text := LPalette.Content;
    end;
  end;
end;

{ Icons }

function DaisyResolveIcon(AKind: TDaisyIconKind; AVariant: TDaisyVariant): TDaisyIconKind;
begin
  if AKind <> diAuto then
    Exit(AKind);
  case AVariant of
    dvSuccess: Result := diSuccess;
    dvWarning: Result := diWarning;
    dvError: Result := diError;
  else
    Result := diInfo;
  end;
end;

function Circle(ACx, ACy, ARadius: Single): TDaisyPolyline;
const
  CSegments = 48;
var
  I: Integer;
  LAngle: Single;
begin
  SetLength(Result, CSegments + 1);
  for I := 0 to CSegments do
  begin
    LAngle := 2 * Pi * I / CSegments;
    Result[I] := PointF(ACx + ARadius * Cos(LAngle), ACy + ARadius * Sin(LAngle));
  end;
end;

function DaisyIconPaths(AKind: TDaisyIconKind): TDaisyIconPaths;
begin
  case AKind of
    diInfo:
      Result := [Circle(12, 12, 9),
        [PointF(12, 11), PointF(12, 16)],
        [PointF(12, 7.9), PointF(12, 8)]];
    diSuccess:
      Result := [Circle(12, 12, 9),
        [PointF(8, 12.5), PointF(11, 15.5), PointF(16, 9.5)]];
    diWarning:
      Result := [
        [PointF(12, 3.5), PointF(21.5, 20), PointF(2.5, 20), PointF(12, 3.5)],
        [PointF(12, 10), PointF(12, 14.5)],
        [PointF(12, 17.4), PointF(12, 17.5)]];
    diError:
      Result := [Circle(12, 12, 9),
        [PointF(9, 9), PointF(15, 15)],
        [PointF(15, 9), PointF(9, 15)]];
  else
    Result := nil;
  end;
end;

function DaisyParseSvgPath(const AData: string): TDaisyIconPaths;
const
  CCurveSteps = 14;
var
  LFormat: TFormatSettings;
  LPos: Integer;
  LCmd, LUpper, LPrev: Char;
  LCur, LStart, LCtrl: TPointF;
  LLine: TDaisyPolyline;
  LRel, LFailed: Boolean;

  procedure Flush;
  begin
    if Length(LLine) >= 2 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LLine;
    end;
    LLine := nil;
  end;

  procedure AddPoint(const APoint: TPointF);
  begin
    if Length(LLine) = 0 then
    begin
      SetLength(LLine, 1);
      LLine[0] := LCur;
    end;
    SetLength(LLine, Length(LLine) + 1);
    LLine[High(LLine)] := APoint;
  end;

  procedure SkipSeparators;
  begin
    while (LPos <= Length(AData)) and CharInSet(AData[LPos], [' ', ',', #9, #10, #13]) do
      Inc(LPos);
  end;

  procedure SkipDigits;
  begin
    while (LPos <= Length(AData)) and CharInSet(AData[LPos], ['0'..'9']) do
      Inc(LPos);
  end;

  function ReadNumber: Single;
  var
    LFrom, LSave: Integer;
    LValue: Double;
  begin
    Result := 0;
    SkipSeparators;
    LFrom := LPos;
    if (LPos <= Length(AData)) and CharInSet(AData[LPos], ['+', '-']) then
      Inc(LPos);
    SkipDigits;
    if (LPos <= Length(AData)) and (AData[LPos] = '.') then
    begin
      Inc(LPos);
      SkipDigits;
    end;
    if (LPos <= Length(AData)) and CharInSet(AData[LPos], ['e', 'E']) then
    begin
      LSave := LPos;
      Inc(LPos);
      if (LPos <= Length(AData)) and CharInSet(AData[LPos], ['+', '-']) then
        Inc(LPos);
      if (LPos <= Length(AData)) and CharInSet(AData[LPos], ['0'..'9']) then
        SkipDigits
      else
        LPos := LSave;
    end;
    if TryStrToFloat(Copy(AData, LFrom, LPos - LFrom), LValue, LFormat) then
      Result := LValue
    else
      LFailed := True;
  end;

  // Arc flags may be written without separators, e.g. "a1 1 0 011 1"
  function ReadFlag: Boolean;
  begin
    SkipSeparators;
    Result := False;
    if (LPos <= Length(AData)) and CharInSet(AData[LPos], ['0', '1']) then
    begin
      Result := AData[LPos] = '1';
      Inc(LPos);
    end
    else
      LFailed := True;
  end;

  function ReadPoint: TPointF;
  var
    LX, LY: Single;
  begin
    LX := ReadNumber;
    LY := ReadNumber;
    if LRel then
      Result := PointF(LCur.X + LX, LCur.Y + LY)
    else
      Result := PointF(LX, LY);
  end;

  procedure CubicTo(const AP1, AP2, AP3: TPointF);
  var
    I: Integer;
    T, U: Double;
  begin
    for I := 1 to CCurveSteps do
    begin
      T := I / CCurveSteps;
      U := 1 - T;
      AddPoint(PointF(
        U * U * U * LCur.X + 3 * U * U * T * AP1.X + 3 * U * T * T * AP2.X + T * T * T * AP3.X,
        U * U * U * LCur.Y + 3 * U * U * T * AP1.Y + 3 * U * T * T * AP2.Y + T * T * T * AP3.Y));
    end;
    LCtrl := AP2;
    LCur := AP3;
  end;

  procedure QuadTo(const AP1, AP2: TPointF);
  var
    I: Integer;
    T, U: Double;
  begin
    for I := 1 to CCurveSteps do
    begin
      T := I / CCurveSteps;
      U := 1 - T;
      AddPoint(PointF(U * U * LCur.X + 2 * U * T * AP1.X + T * T * AP2.X,
        U * U * LCur.Y + 2 * U * T * AP1.Y + T * T * AP2.Y));
    end;
    LCtrl := AP1;
    LCur := AP2;
  end;

  // SVG implementation notes F.6.5: endpoint to centre parameterisation
  procedure ArcTo(ARx, ARy, ARotation: Double; ALarge, ASweep: Boolean; const AEnd: TPointF);
  var
    LCos, LSin, LDx, LDy, LX1, LY1, LLambda, LNum, LDen, LCoef, LCxp, LCyp: Double;
    LCx, LCy, LTheta1, LTheta2, LDelta, LAngle: Double;
    I, LSteps: Integer;
  begin
    if (LCur.X = AEnd.X) and (LCur.Y = AEnd.Y) then
      Exit;
    ARx := Abs(ARx);
    ARy := Abs(ARy);
    if (ARx = 0) or (ARy = 0) then
    begin
      AddPoint(AEnd);
      LCur := AEnd;
      Exit;
    end;
    LCos := Cos(DegToRad(ARotation));
    LSin := Sin(DegToRad(ARotation));
    LDx := (LCur.X - AEnd.X) / 2;
    LDy := (LCur.Y - AEnd.Y) / 2;
    LX1 := LCos * LDx + LSin * LDy;
    LY1 := -LSin * LDx + LCos * LDy;
    LLambda := (LX1 * LX1) / (ARx * ARx) + (LY1 * LY1) / (ARy * ARy);
    if LLambda > 1 then
    begin
      ARx := ARx * Sqrt(LLambda);
      ARy := ARy * Sqrt(LLambda);
    end;
    LNum := ARx * ARx * ARy * ARy - ARx * ARx * LY1 * LY1 - ARy * ARy * LX1 * LX1;
    LDen := ARx * ARx * LY1 * LY1 + ARy * ARy * LX1 * LX1;
    LCoef := 0;
    if LDen <> 0 then
      LCoef := Sqrt(Max(0, LNum / LDen));
    if ALarge = ASweep then
      LCoef := -LCoef;
    LCxp := LCoef * ARx * LY1 / ARy;
    LCyp := -LCoef * ARy * LX1 / ARx;
    LCx := LCos * LCxp - LSin * LCyp + (LCur.X + AEnd.X) / 2;
    LCy := LSin * LCxp + LCos * LCyp + (LCur.Y + AEnd.Y) / 2;
    LTheta1 := ArcTan2((LY1 - LCyp) / ARy, (LX1 - LCxp) / ARx);
    LTheta2 := ArcTan2((-LY1 - LCyp) / ARy, (-LX1 - LCxp) / ARx);
    LDelta := LTheta2 - LTheta1;
    if ASweep and (LDelta < 0) then
      LDelta := LDelta + 2 * Pi
    else if (not ASweep) and (LDelta > 0) then
      LDelta := LDelta - 2 * Pi;
    LSteps := Max(4, Ceil(Abs(LDelta) / (Pi / 12)));
    for I := 1 to LSteps - 1 do
    begin
      LAngle := LTheta1 + LDelta * I / LSteps;
      AddPoint(PointF(LCos * ARx * Cos(LAngle) - LSin * ARy * Sin(LAngle) + LCx,
        LSin * ARx * Cos(LAngle) + LCos * ARy * Sin(LAngle) + LCy));
    end;
    AddPoint(AEnd);
    LCur := AEnd;
  end;

  function Reflected(const AFrom: TPointF; AAllowed: Boolean): TPointF;
  begin
    if AAllowed then
      Result := PointF(2 * LCur.X - AFrom.X, 2 * LCur.Y - AFrom.Y)
    else
      Result := LCur;
  end;

var
  LP1, LP2, LP3: TPointF;
  LRx, LRy, LRot: Single;
  LLarge, LSweep: Boolean;
begin
  Result := nil;
  LFormat := TFormatSettings.Invariant;
  LPos := 1;
  LCmd := #0;
  LPrev := #0;
  LFailed := False;
  LCur := PointF(0, 0);
  LStart := LCur;
  LCtrl := LCur;
  while not LFailed do
  begin
    SkipSeparators;
    if LPos > Length(AData) then
      Break;
    if CharInSet(AData[LPos], ['A'..'Z', 'a'..'z']) then
    begin
      LCmd := AData[LPos];
      Inc(LPos);
    end
    else if (LCmd = #0) or (UpCase(LCmd) = 'Z') then
      Break; // numbers without a command

    LRel := CharInSet(LCmd, ['a'..'z']);
    LUpper := UpCase(LCmd);
    case LUpper of
      'M':
        begin
          LP1 := ReadPoint;
          Flush;
          LCur := LP1;
          LStart := LP1;
          SetLength(LLine, 1);
          LLine[0] := LP1;
          if LRel then
            LCmd := 'l'
          else
            LCmd := 'L'; // further pairs are implicit line-tos
        end;
      'L':
        begin
          LP1 := ReadPoint;
          AddPoint(LP1);
          LCur := LP1;
        end;
      'H':
        begin
          LP1 := PointF(ReadNumber, LCur.Y);
          if LRel then
            LP1.X := LP1.X + LCur.X;
          AddPoint(LP1);
          LCur := LP1;
        end;
      'V':
        begin
          LP1 := PointF(LCur.X, ReadNumber);
          if LRel then
            LP1.Y := LP1.Y + LCur.Y;
          AddPoint(LP1);
          LCur := LP1;
        end;
      'C':
        begin
          LP1 := ReadPoint;
          LP2 := ReadPoint;
          LP3 := ReadPoint;
          if not LFailed then
            CubicTo(LP1, LP2, LP3);
        end;
      'S':
        begin
          LP1 := Reflected(LCtrl, CharInSet(LPrev, ['C', 'S']));
          LP2 := ReadPoint;
          LP3 := ReadPoint;
          if not LFailed then
            CubicTo(LP1, LP2, LP3);
        end;
      'Q':
        begin
          LP1 := ReadPoint;
          LP2 := ReadPoint;
          if not LFailed then
            QuadTo(LP1, LP2);
        end;
      'T':
        begin
          LP1 := Reflected(LCtrl, CharInSet(LPrev, ['Q', 'T']));
          LP2 := ReadPoint;
          if not LFailed then
            QuadTo(LP1, LP2);
        end;
      'A':
        begin
          LRx := ReadNumber;
          LRy := ReadNumber;
          LRot := ReadNumber;
          LLarge := ReadFlag;
          LSweep := ReadFlag;
          LP1 := ReadPoint;
          if not LFailed then
            ArcTo(LRx, LRy, LRot, LLarge, LSweep, LP1);
        end;
      'Z':
        begin
          if Length(LLine) > 0 then
            AddPoint(LStart);
          Flush;
          LCur := LStart;
        end;
    else
      LFailed := True;
    end;
    LPrev := LUpper;
  end;
  Flush;
end;

initialization

finalization
  FreeAndNil(GManager);

end.
