unit MainVCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.ActnList, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control,
  Daisy.VCL.Panel, Daisy.VCL.Labels, Daisy.VCL.SVGImage, Daisy.VCL.Status, Daisy.VCL.Select,
  Daisy.VCL.Table, Daisy.VCL.FormStyler, Daisy.VCL.PageControl, Daisy.VCL.CheckBox,
  Daisy.VCL.ThemeController, System.Actions;

type
  TForm18 = class(TForm)
    lblTheme: TLabel;
    lblStatusLine: TLabel;
    lblStatusSizes: TLabel;
    lblStatusColors: TLabel;
    lblStatusMore: TLabel;
    chkTitleBar: TDaisyCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    selTheme: TDaisySelect;
    themeCtl: TDaisyThemeController;
    Styler: TDaisyFormStyler;
    pcMain: TDaisyPageControl;
    tsUtilities: TDaisyTabSheet;
    tsStatus: TDaisyTabSheet;
    tsSvg: TDaisyTabSheet;
    tsSelect: TDaisyTabSheet;
    tsTables: TDaisyTabSheet;
    tsTableFeatures: TDaisyTabSheet;
    tsTableSizes: TDaisyTabSheet;
    pnlPlain: TDaisyPanel;
    lblPanelTitle: TDaisyLabel;
    lblPanelText: TDaisyLabel;
    pnlPrimary: TDaisyPanel;
    lblPrimaryTitle: TDaisyLabel;
    lblPrimaryText: TDaisyLabel;
    dlbHeading: TDaisyLabel;
    dlbBody: TDaisyLabel;
    dlbMuted: TDaisyLabel;
    dlbEmoji: TDaisyLabel;
    dlbWrap: TDaisyLabel;
    svgHeart: TDaisySVGImage;
    svgCheck: TDaisySVGImage;
    svgSettings: TDaisySVGImage;
    svgColor: TDaisySVGImage;
    stSizeXs: TDaisyStatus;
    stSizeSm: TDaisyStatus;
    stSizeMd: TDaisyStatus;
    stSizeLg: TDaisyStatus;
    stSizeXl: TDaisyStatus;
    stNeutral: TDaisyStatus;
    stPrimary: TDaisyStatus;
    stSecondary: TDaisyStatus;
    stAccent: TDaisyStatus;
    stInfo: TDaisyStatus;
    stSuccess: TDaisyStatus;
    stWarning: TDaisyStatus;
    stError: TDaisyStatus;
    stPing: TDaisyStatus;
    stBounce: TDaisyStatus;
    stEmoji: TDaisyStatus;
    stSvg: TDaisyStatus;
    selBasic: TDaisySelect;
    selGhost: TDaisySelect;
    selLegend: TDaisySelect;
    selBefore: TDaisySelect;
    selAfter: TDaisySelect;
    selFloating: TDaisySelect;
    selXs: TDaisySelect;
    selSm: TDaisySelect;
    selMd: TDaisySelect;
    selLg: TDaisySelect;
    selXl: TDaisySelect;
    selPrimary: TDaisySelect;
    selSecondary: TDaisySelect;
    selAccent: TDaisySelect;
    selInfo: TDaisySelect;
    selSuccess: TDaisySelect;
    selWarning: TDaisySelect;
    selError: TDaisySelect;
    selDisabled: TDaisySelect;
    selEmoji: TDaisySelect;
    selSvg: TDaisySelect;
    selSoft: TDaisySelect;
    selDash: TDaisySelect;
    tbBasic: TDaisyTable;
    tbActive: TDaisyTable;
    tbBordered: TDaisyTable;
    tbHover: TDaisyTable;
    tbZebra: TDaisyTable;
    tbCheckbox: TDaisyTable;
    tbAvatar: TDaisyTable;
    tbFooter: TDaisyTable;
    tbPinRows: TDaisyTable;
    tbPinCols: TDaisyTable;
    tbXs: TDaisyTable;
    tbSm: TDaisyTable;
    tbMd: TDaisyTable;
    tbLg: TDaisyTable;
    tbXl: TDaisyTable;
    tbRtl: TDaisyTable;
    DaisySVGImage1: TDaisySVGImage;
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TableButtonClick(Sender: TObject; ARow, ACol: Integer);
  end;

var
  Form18: TForm18;

implementation

{$R *.dfm}

procedure TForm18.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm18.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm18.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm18.chkTitleBarClick(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm18.TableButtonClick(Sender: TObject; ARow, ACol: Integer);
var
  LTable: TDaisyTable;
begin
  LTable := Sender as TDaisyTable;
  lblStatusLine.Caption := Format('%s: "%s" details clicked', [LTable.Name,
    LTable.Rows[ARow].CellText(1)]);
end;

end.
