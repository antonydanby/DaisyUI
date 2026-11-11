unit MainFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types,   FMX.Controls, FMX.ActnList, System.Actions, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation,
  Daisy.Theme, Daisy.FMX.Control, Daisy.FMX.Button, Daisy.FMX.Badge, Daisy.FMX.IconButton, Daisy.FMX.Select, Daisy.FMX.FormStyler,
  Daisy.FMX.PageControl, Daisy.FMX.CheckBox,
  Daisy.FMX.ThemeController;

type
  TForm15 = class(TForm)
    lblBadge: TLabel;
    lblSizes: TLabel;
    lblColors: TLabel;
    lblSoft: TLabel;
    lblOutline: TLabel;
    lblDash: TLabel;
    lblNeutral: TLabel;
    lblGhost: TLabel;
    lblEmpty: TLabel;
    lblIcon: TLabel;
    lblButton: TLabel;
    lblStatus: TLabel;
    bdgDefault: TDaisyFmxBadge;
    bdgNeutral: TDaisyFmxBadge;
    bdgPrimary: TDaisyFmxBadge;
    bdgSecondary: TDaisyFmxBadge;
    bdgAccent: TDaisyFmxBadge;
    bdgGhost: TDaisyFmxBadge;
    bdgXS: TDaisyFmxBadge;
    bdgSM: TDaisyFmxBadge;
    bdgMD: TDaisyFmxBadge;
    bdgLG: TDaisyFmxBadge;
    bdgXL: TDaisyFmxBadge;
    bdgColNeutral: TDaisyFmxBadge;
    bdgColPrimary: TDaisyFmxBadge;
    bdgColSecondary: TDaisyFmxBadge;
    bdgColAccent: TDaisyFmxBadge;
    bdgColInfo: TDaisyFmxBadge;
    bdgColSuccess: TDaisyFmxBadge;
    bdgColWarning: TDaisyFmxBadge;
    bdgColError: TDaisyFmxBadge;
    bdgSoftNeutral: TDaisyFmxBadge;
    bdgSoftPrimary: TDaisyFmxBadge;
    bdgSoftSecondary: TDaisyFmxBadge;
    bdgSoftAccent: TDaisyFmxBadge;
    bdgSoftInfo: TDaisyFmxBadge;
    bdgSoftSuccess: TDaisyFmxBadge;
    bdgSoftWarning: TDaisyFmxBadge;
    bdgSoftError: TDaisyFmxBadge;
    bdgOutNeutral: TDaisyFmxBadge;
    bdgOutPrimary: TDaisyFmxBadge;
    bdgOutSecondary: TDaisyFmxBadge;
    bdgOutAccent: TDaisyFmxBadge;
    bdgOutInfo: TDaisyFmxBadge;
    bdgOutSuccess: TDaisyFmxBadge;
    bdgOutWarning: TDaisyFmxBadge;
    bdgOutError: TDaisyFmxBadge;
    bdgDashNeutral: TDaisyFmxBadge;
    bdgDashPrimary: TDaisyFmxBadge;
    bdgDashSecondary: TDaisyFmxBadge;
    bdgDashAccent: TDaisyFmxBadge;
    bdgDashInfo: TDaisyFmxBadge;
    bdgDashSuccess: TDaisyFmxBadge;
    bdgDashWarning: TDaisyFmxBadge;
    bdgDashError: TDaisyFmxBadge;
    bdgNeutralOutline: TDaisyFmxBadge;
    bdgNeutralDash: TDaisyFmxBadge;
    bdgGhostMD: TDaisyFmxBadge;
    bdgGhostLG: TDaisyFmxBadge;
    bdgEmptyXS: TDaisyFmxBadge;
    bdgEmptySM: TDaisyFmxBadge;
    bdgEmptyMD: TDaisyFmxBadge;
    bdgEmptyLG: TDaisyFmxBadge;
    bdgEmptyXL: TDaisyFmxBadge;
    bdgIconInfo: TDaisyFmxBadge;
    bdgIconSuccess: TDaisyFmxBadge;
    bdgIconWarning: TDaisyFmxBadge;
    bdgIconError: TDaisyFmxBadge;
    bdgIconAuto: TDaisyFmxBadge;
    btnInbox: TDaisyFmxBadgeButton;
    btnInboxSecondary: TDaisyFmxBadgeButton;
    btnNotify: TDaisyFmxBadgeButton;
    btnBadgeIcon: TDaisyFmxBadgeButton;
    btnBadgeSmall: TDaisyFmxBadgeButton;
    lblSvg: TLabel;
    btnSvgHeart: TDaisyFmxButton;
    btnSvgNext: TDaisyFmxButton;
    btnSvgAdd: TDaisyFmxButton;
    btnSvgBell: TDaisyFmxSquareButton;
    btnSvgCheck: TDaisyFmxCircleButton;
    bdgSvgHeart: TDaisyFmxBadge;
    bdgSvgCheck: TDaisyFmxBadge;
    btnSvgBadge: TDaisyFmxBadgeButton;
    btnSvgSettings: TDaisyFmxButton;
    btnSvgHome: TDaisyFmxButton;
    lblTheme: TLabel;
    selTheme: TDaisyFmxSelect;
    themeCtl: TDaisyFmxThemeController;
    Styler: TDaisyFmxFormStyler;
    chkTitleBar: TDaisyFmxCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actInbox: TAction;
    actNotify: TAction;
    pcMain: TDaisyFmxPageControl;
    tsBadges: TDaisyFmxTabSheet;
    tsStyles: TDaisyFmxTabSheet;
    tsSpecial: TDaisyFmxTabSheet;
    tsButtons: TDaisyFmxTabSheet;
    tsSvg: TDaisyFmxTabSheet;
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BadgeButtonClick(Sender: TObject);
    procedure InboxExecute(Sender: TObject);
    procedure NotifyExecute(Sender: TObject);
  end;

var
  Form15: TForm15;

implementation

{$R *.fmx}

procedure TForm15.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm15.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm15.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm15.chkTitleBarChange(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm15.BadgeButtonClick(Sender: TObject);
var
  LButton: TDaisyFmxBadgeButton;
begin
  LButton := Sender as TDaisyFmxBadgeButton;
  lblStatus.Text := Format('%s clicked (badge: %s)', [LButton.Text, LButton.BadgeText]);
end;

procedure TForm15.InboxExecute(Sender: TObject);
begin
  lblStatus.Text := Format('%s clicked (badge: %s)', [actInbox.Text, btnInbox.BadgeText]);
end;

procedure TForm15.NotifyExecute(Sender: TObject);
begin
  lblStatus.Text := Format('%s clicked (badge: %s)', [actNotify.Text, btnNotify.BadgeText]);
end;

end.
