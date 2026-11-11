unit MainFMX;

interface

uses
  System.SysUtils, System.StrUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.ActnList, System.Actions, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects,
  Daisy.Theme, Daisy.FMX.Control, Daisy.FMX.Button, Daisy.FMX.Panel, Daisy.FMX.Card, Daisy.FMX.Alert,
  Daisy.FMX.Select, Daisy.FMX.FormStyler, Daisy.FMX.PageControl, Daisy.FMX.CheckBox,
  Daisy.FMX.TextInput, Daisy.FMX.Indicator, Daisy.FMX.FieldSet,
  Daisy.FMX.Swap, Daisy.FMX.Stack, Daisy.FMX.ThemeController,
  FMX.Controls.Presentation;

type
  TForm11 = class(TForm)
    lblTheme: TLabel;
    selTheme: TDaisyFmxSelect;
    Styler: TDaisyFmxFormStyler;
    pcMain: TDaisyFmxPageControl;
    tsVariants: TDaisyFmxTabSheet;
    tsStyles: TDaisyFmxTabSheet;
    tsSizes: TDaisyFmxTabSheet;
    tsCards: TDaisyFmxTabSheet;
    tsAlerts: TDaisyFmxTabSheet;
    lblVariants: TLabel;
    btnDefault: TDaisyFmxButton;
    btnNeutral: TDaisyFmxButton;
    btnPrimary: TDaisyFmxButton;
    btnSecondary: TDaisyFmxButton;
    btnAccent: TDaisyFmxButton;
    btnInfo: TDaisyFmxButton;
    btnSuccess: TDaisyFmxButton;
    btnWarning: TDaisyFmxButton;
    btnError: TDaisyFmxButton;
    lblStyles: TLabel;
    btnOutline: TDaisyFmxButton;
    btnDash: TDaisyFmxButton;
    btnSoft: TDaisyFmxButton;
    btnGhost: TDaisyFmxButton;
    btnDisabled: TDaisyFmxButton;
    lblSizes: TLabel;
    btnXS: TDaisyFmxButton;
    btnSM: TDaisyFmxButton;
    btnMD: TDaisyFmxButton;
    btnLG: TDaisyFmxButton;
    btnXL: TDaisyFmxButton;
    lblCards: TLabel;
    cardDefault: TDaisyFmxCard;
    btnBuyDefault: TDaisyFmxButton;
    cardPrimary: TDaisyFmxCard;
    btnBuyPrimary: TDaisyFmxButton;
    cardBordered: TDaisyFmxCard;
    btnBuyBordered: TDaisyFmxButton;
    lblAlerts: TLabel;
    alertStatus: TDaisyFmxAlert;
    alertSuccess: TDaisyFmxAlert;
    alertWarning: TDaisyFmxAlert;
    alertError: TDaisyFmxAlert;
    alertDefault: TDaisyFmxAlert;
    tsIndicator: TDaisyFmxTabSheet;
    lblIndicator: TLabel;
    lblIndicatorPlacement: TLabel;
    lblIndicatorResult: TLabel;
    indBadge: TDaisyFmxIndicator;
    pnlBadge: TDaisyFmxPanel;
    indStatus: TDaisyFmxIndicator;
    pnlStatus: TDaisyFmxPanel;
    indButton: TDaisyFmxIndicator;
    pnlButton: TDaisyFmxPanel;
    indLarge: TDaisyFmxIndicator;
    pnlLarge: TDaisyFmxPanel;
    indNew: TDaisyFmxIndicator;
    pnlNew: TDaisyFmxPanel;
    indP1: TDaisyFmxIndicator;
    pnlP1: TDaisyFmxPanel;
    indP2: TDaisyFmxIndicator;
    pnlP2: TDaisyFmxPanel;
    indP3: TDaisyFmxIndicator;
    pnlP3: TDaisyFmxPanel;
    indP4: TDaisyFmxIndicator;
    pnlP4: TDaisyFmxPanel;
    indP5: TDaisyFmxIndicator;
    pnlP5: TDaisyFmxPanel;
    indP6: TDaisyFmxIndicator;
    pnlP6: TDaisyFmxPanel;
    tsFieldSet: TDaisyFmxTabSheet;
    lblFieldSet: TLabel;
    fsBasic: TDaisyFmxFieldSet;
    edtFsTitle: TDaisyFmxTextInput;
    fsLogin: TDaisyFmxFieldSet;
    edtFsEmail: TDaisyFmxTextInput;
    edtFsPassword: TDaisyFmxTextInput;
    btnFsLogin: TDaisyFmxButton;
    fsSoft: TDaisyFmxFieldSet;
    chkFsNews: TDaisyFmxCheckBox;
    chkFsTips: TDaisyFmxCheckBox;
    fsOutline: TDaisyFmxFieldSet;
    tsSwap: TDaisyFmxTabSheet;
    lblSwap: TLabel;
    lblSwapText: TLabel;
    lblSwapVolume: TLabel;
    lblSwapRotate: TLabel;
    lblSwapFlip: TLabel;
    lblSwapInd: TLabel;
    lblSwapResult: TLabel;
    swText: TDaisyFmxSwap;
    swVolume: TDaisyFmxSwap;
    swRotate: TDaisyFmxSwap;
    swFlip: TDaisyFmxSwap;
    swInd: TDaisyFmxSwap;
    tsStack: TDaisyFmxTabSheet;
    lblStack: TLabel;
    lblStackBottom: TLabel;
    lblStackTop: TLabel;
    lblStackStart: TLabel;
    lblStackEnd: TLabel;
    stkBottom: TDaisyFmxStack;
    stkBottomC: TDaisyFmxCard;
    stkBottomB: TDaisyFmxCard;
    stkBottomA: TDaisyFmxCard;
    stkTop: TDaisyFmxStack;
    stkTopC: TDaisyFmxCard;
    stkTopB: TDaisyFmxCard;
    stkTopA: TDaisyFmxCard;
    stkStart: TDaisyFmxStack;
    stkStartC: TDaisyFmxCard;
    stkStartB: TDaisyFmxCard;
    stkStartA: TDaisyFmxCard;
    stkEnd: TDaisyFmxStack;
    stkEndC: TDaisyFmxCard;
    stkEndB: TDaisyFmxCard;
    stkEndA: TDaisyFmxCard;
    lblStackHint: TLabel;
    stkPlainBottom: TDaisyFmxStack;
    stkPlainBottomC: TDaisyFmxCard;
    stkPlainBottomB: TDaisyFmxCard;
    stkPlainBottomA: TDaisyFmxCard;
    stkNeutralTop: TDaisyFmxStack;
    stkNeutralTopC: TDaisyFmxCard;
    stkNeutralTopB: TDaisyFmxCard;
    stkNeutralTopA: TDaisyFmxCard;
    stkPlainStart: TDaisyFmxStack;
    stkPlainStartC: TDaisyFmxCard;
    stkPlainStartB: TDaisyFmxCard;
    stkPlainStartA: TDaisyFmxCard;
    stkNeutralEnd: TDaisyFmxStack;
    stkNeutralEndC: TDaisyFmxCard;
    stkNeutralEndB: TDaisyFmxCard;
    stkNeutralEndA: TDaisyFmxCard;
    themeCtl: TDaisyFmxThemeController;
    alMain: TActionList;
    actBuyNow: TAction;
    procedure SwapChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure IndicatorItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ThemeSelectChange(Sender: TObject);
    procedure CardActionClick(Sender: TObject);
  end;

var
  Form11: TForm11;

implementation

{$R *.fmx}

procedure TForm11.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TLabel then
      TLabel(Components[I]).TextSettings.Font.Style := [TFontStyle.fsBold];
end;

procedure TForm11.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm11.CardActionClick(Sender: TObject);
begin
  alertStatus.Variant := dvSuccess;
  alertStatus.Text := 'Thanks! Your order was placed at ' + FormatDateTime('hh:nn:ss', Now) + '.';
end;

procedure TForm11.IndicatorItemClick(Sender: TObject);
begin
  lblIndicatorResult.Text := 'Inbox clicked at ' + FormatDateTime('hh:nn:ss', Now);
end;

procedure TForm11.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm11.SwapChange(Sender: TObject);
begin
  if Sender is TDaisyFmxSwap then
    lblSwapResult.Text := TDaisyFmxSwap(Sender).Name + ' is now ' +
      IfThen(TDaisyFmxSwap(Sender).Active, 'on', 'off');
end;

end.
