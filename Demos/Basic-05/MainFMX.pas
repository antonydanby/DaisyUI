unit MainFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types,
  FMX.Controls, FMX.ActnList, System.Actions, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, Daisy.Theme, Daisy.Widgets, Daisy.Tables, Daisy.FMX.Control,
  Daisy.FMX.Panel, Daisy.FMX.Labels, Daisy.FMX.SVGImage, Daisy.FMX.Status, Daisy.FMX.Select,
  Daisy.FMX.Table, Daisy.FMX.FormStyler, Daisy.FMX.CheckBox, Daisy.FMX.PageControl,
  Daisy.FMX.ThemeController;

type
  TForm19 = class(TForm)
    lblTheme: TLabel;
    lblStatusLine: TLabel;
    lblStatusSizes: TLabel;
    lblStatusColors: TLabel;
    lblStatusMore: TLabel;
    chkTitleBar: TDaisyFmxCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    selTheme: TDaisyFmxSelect;
    themeCtl: TDaisyFmxThemeController;
    Styler: TDaisyFmxFormStyler;
    pcMain: TDaisyFmxPageControl;
    tsUtilities: TDaisyFmxTabSheet;
    tsStatus: TDaisyFmxTabSheet;
    tsSelect: TDaisyFmxTabSheet;
    tsTable: TDaisyFmxTabSheet;
    tsTableMore: TDaisyFmxTabSheet;
    tsTableSizes: TDaisyFmxTabSheet;
    tsSvg: TDaisyFmxTabSheet;
    pnlPlain: TDaisyFmxPanel;
    lblPanelTitle: TDaisyFmxLabel;
    lblPanelText: TDaisyFmxLabel;
    pnlPrimary: TDaisyFmxPanel;
    lblPrimaryTitle: TDaisyFmxLabel;
    lblPrimaryText: TDaisyFmxLabel;
    dlbHeading: TDaisyFmxLabel;
    dlbBody: TDaisyFmxLabel;
    dlbMuted: TDaisyFmxLabel;
    dlbEmoji: TDaisyFmxLabel;
    dlbWrap: TDaisyFmxLabel;
    svgHeart: TDaisyFmxSVGImage;
    svgCheck: TDaisyFmxSVGImage;
    svgSettings: TDaisyFmxSVGImage;
    svgColor: TDaisyFmxSVGImage;
    stSizeXs: TDaisyFmxStatus;
    stSizeSm: TDaisyFmxStatus;
    stSizeMd: TDaisyFmxStatus;
    stSizeLg: TDaisyFmxStatus;
    stSizeXl: TDaisyFmxStatus;
    stNeutral: TDaisyFmxStatus;
    stPrimary: TDaisyFmxStatus;
    stSecondary: TDaisyFmxStatus;
    stAccent: TDaisyFmxStatus;
    stInfo: TDaisyFmxStatus;
    stSuccess: TDaisyFmxStatus;
    stWarning: TDaisyFmxStatus;
    stError: TDaisyFmxStatus;
    stPing: TDaisyFmxStatus;
    stBounce: TDaisyFmxStatus;
    stEmoji: TDaisyFmxStatus;
    stSvg: TDaisyFmxStatus;
    selBasic: TDaisyFmxSelect;
    selGhost: TDaisyFmxSelect;
    selLegend: TDaisyFmxSelect;
    selBefore: TDaisyFmxSelect;
    selAfter: TDaisyFmxSelect;
    selFloating: TDaisyFmxSelect;
    selXs: TDaisyFmxSelect;
    selSm: TDaisyFmxSelect;
    selMd: TDaisyFmxSelect;
    selLg: TDaisyFmxSelect;
    selXl: TDaisyFmxSelect;
    selPrimary: TDaisyFmxSelect;
    selSecondary: TDaisyFmxSelect;
    selAccent: TDaisyFmxSelect;
    selInfo: TDaisyFmxSelect;
    selSuccess: TDaisyFmxSelect;
    selWarning: TDaisyFmxSelect;
    selError: TDaisyFmxSelect;
    selDisabled: TDaisyFmxSelect;
    selEmoji: TDaisyFmxSelect;
    selSvg: TDaisyFmxSelect;
    selSoft: TDaisyFmxSelect;
    selDash: TDaisyFmxSelect;
    tbBasic: TDaisyFmxTable;
    tbActive: TDaisyFmxTable;
    tbBordered: TDaisyFmxTable;
    tbHover: TDaisyFmxTable;
    tbZebra: TDaisyFmxTable;
    tbCheckbox: TDaisyFmxTable;
    tbAvatar: TDaisyFmxTable;
    tbFooter: TDaisyFmxTable;
    tbPinRows: TDaisyFmxTable;
    tbPinCols: TDaisyFmxTable;
    tbXs: TDaisyFmxTable;
    tbSm: TDaisyFmxTable;
    tbMd: TDaisyFmxTable;
    tbLg: TDaisyFmxTable;
    tbXl: TDaisyFmxTable;
    tbRtl: TDaisyFmxTable;
    DaisyFmxSVGImage1: TDaisyFmxSVGImage;
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TableButtonClick(Sender: TObject; ARow, ACol: Integer);
  end;

var
  Form19: TForm19;

implementation

{$R *.fmx}

procedure TForm19.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm19.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm19.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm19.chkTitleBarChange(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm19.TableButtonClick(Sender: TObject; ARow, ACol: Integer);
var
  LTable: TDaisyFmxTable;
begin
  LTable := Sender as TDaisyFmxTable;
  lblStatusLine.Text := Format('%s: "%s" details clicked', [LTable.Name,
    LTable.Rows[ARow].CellText(1)]);
end;

end.
