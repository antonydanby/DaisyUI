unit MainVCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.ActnList, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Daisy.Theme, Daisy.VCL.Control,
  Daisy.VCL.Button, Daisy.VCL.Badge, Daisy.VCL.IconButton, Daisy.VCL.Select, Daisy.VCL.FormStyler, Daisy.VCL.PageControl, Daisy.VCL.CheckBox,
  Daisy.VCL.ThemeController;

type
  TForm14 = class(TForm)
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
    bdgDefault: TDaisyBadge;
    bdgNeutral: TDaisyBadge;
    bdgPrimary: TDaisyBadge;
    bdgSecondary: TDaisyBadge;
    bdgAccent: TDaisyBadge;
    bdgGhost: TDaisyBadge;
    bdgXS: TDaisyBadge;
    bdgSM: TDaisyBadge;
    bdgMD: TDaisyBadge;
    bdgLG: TDaisyBadge;
    bdgXL: TDaisyBadge;
    bdgColNeutral: TDaisyBadge;
    bdgColPrimary: TDaisyBadge;
    bdgColSecondary: TDaisyBadge;
    bdgColAccent: TDaisyBadge;
    bdgColInfo: TDaisyBadge;
    bdgColSuccess: TDaisyBadge;
    bdgColWarning: TDaisyBadge;
    bdgColError: TDaisyBadge;
    bdgSoftNeutral: TDaisyBadge;
    bdgSoftPrimary: TDaisyBadge;
    bdgSoftSecondary: TDaisyBadge;
    bdgSoftAccent: TDaisyBadge;
    bdgSoftInfo: TDaisyBadge;
    bdgSoftSuccess: TDaisyBadge;
    bdgSoftWarning: TDaisyBadge;
    bdgSoftError: TDaisyBadge;
    bdgOutNeutral: TDaisyBadge;
    bdgOutPrimary: TDaisyBadge;
    bdgOutSecondary: TDaisyBadge;
    bdgOutAccent: TDaisyBadge;
    bdgOutInfo: TDaisyBadge;
    bdgOutSuccess: TDaisyBadge;
    bdgOutWarning: TDaisyBadge;
    bdgOutError: TDaisyBadge;
    bdgDashNeutral: TDaisyBadge;
    bdgDashPrimary: TDaisyBadge;
    bdgDashSecondary: TDaisyBadge;
    bdgDashAccent: TDaisyBadge;
    bdgDashInfo: TDaisyBadge;
    bdgDashSuccess: TDaisyBadge;
    bdgDashWarning: TDaisyBadge;
    bdgDashError: TDaisyBadge;
    bdgNeutralOutline: TDaisyBadge;
    bdgNeutralDash: TDaisyBadge;
    bdgGhostMD: TDaisyBadge;
    bdgGhostLG: TDaisyBadge;
    bdgEmptyXS: TDaisyBadge;
    bdgEmptySM: TDaisyBadge;
    bdgEmptyMD: TDaisyBadge;
    bdgEmptyLG: TDaisyBadge;
    bdgEmptyXL: TDaisyBadge;
    bdgIconInfo: TDaisyBadge;
    bdgIconSuccess: TDaisyBadge;
    bdgIconWarning: TDaisyBadge;
    bdgIconError: TDaisyBadge;
    bdgIconAuto: TDaisyBadge;
    btnInbox: TDaisyBadgeButton;
    btnInboxSecondary: TDaisyBadgeButton;
    btnNotify: TDaisyBadgeButton;
    btnBadgeIcon: TDaisyBadgeButton;
    btnBadgeSmall: TDaisyBadgeButton;
    lblSvg: TLabel;
    btnSvgHeart: TDaisyButton;
    btnSvgNext: TDaisyButton;
    btnSvgAdd: TDaisyButton;
    btnSvgBell: TDaisySquareButton;
    btnSvgCheck: TDaisyCircleButton;
    bdgSvgHeart: TDaisyBadge;
    bdgSvgCheck: TDaisyBadge;
    btnSvgBadge: TDaisyBadgeButton;
    btnSvgSettings: TDaisyButton;
    btnSvgHome: TDaisyButton;
    lblTheme: TLabel;
    selTheme: TDaisySelect;
    themeCtl: TDaisyThemeController;
    Styler: TDaisyFormStyler;
    chkTitleBar: TDaisyCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actInbox: TAction;
    actNotify: TAction;
    pcMain: TDaisyPageControl;
    tsBadges: TDaisyTabSheet;
    tsStyles: TDaisyTabSheet;
    tsSpecial: TDaisyTabSheet;
    tsButtons: TDaisyTabSheet;
    tsSvg: TDaisyTabSheet;
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BadgeButtonClick(Sender: TObject);
    procedure InboxExecute(Sender: TObject);
    procedure NotifyExecute(Sender: TObject);
  end;

var
  Form14: TForm14;

implementation

{$R *.dfm}

procedure TForm14.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm14.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm14.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm14.chkTitleBarClick(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm14.BadgeButtonClick(Sender: TObject);
var
  LButton: TDaisyBadgeButton;
begin
  LButton := Sender as TDaisyBadgeButton;
  lblStatus.Caption := Format('%s clicked (badge: %s)', [LButton.Caption, LButton.BadgeText]);
end;

procedure TForm14.InboxExecute(Sender: TObject);
begin
  lblStatus.Caption := Format('%s clicked (badge: %s)', [actInbox.Caption, btnInbox.BadgeText]);
end;

procedure TForm14.NotifyExecute(Sender: TObject);
begin
  lblStatus.Caption := Format('%s clicked (badge: %s)', [actNotify.Caption, btnNotify.BadgeText]);
end;

end.
