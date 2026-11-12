unit MainVCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ActnList, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control,
  Daisy.VCL.Button, Daisy.VCL.Chat, Daisy.VCL.Countdown, Daisy.VCL.List, Daisy.VCL.Stat, Daisy.VCL.Select, Daisy.VCL.FormStyler,
  Daisy.VCL.CheckBox, Daisy.VCL.PageControl, Daisy.VCL.Labels,
  Daisy.VCL.TextInput, Daisy.VCL.Progress, Daisy.VCL.RadialProgress,
  Daisy.VCL.ThemeController;

type
  TForm16 = class(TForm)
    lblTheme: TLabel;
    lblStatus: TLabel;
    selTheme: TDaisySelect;
    themeCtl: TDaisyThemeController;
    Styler: TDaisyFormStyler;
    chkTitleBar: TDaisyCheckBox;
    chkRTL: TDaisyCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actProgAdd: TAction;
    actProgReset: TAction;
    pcMain: TDaisyPageControl;
    tsChat: TDaisyTabSheet;
    tsCountdown: TDaisyTabSheet;
    tsList: TDaisyTabSheet;
    tsStat: TDaisyTabSheet;
    chatStart: TDaisyChatBubble;
    chatEnd: TDaisyChatBubble;
    chatSvg: TDaisyChatBubble;
    chatEmoji: TDaisyChatBubble;
    chatPrimary: TDaisyChatBubble;
    chatSecondary: TDaisyChatBubble;
    chatAccent: TDaisyChatBubble;
    chatInfo: TDaisyChatBubble;
    chatSuccess: TDaisyChatBubble;
    chatWarning: TDaisyChatBubble;
    chatError: TDaisyChatBubble;
    chatNoAvatar: TDaisyChatBubble;
    chatNoAvatarEnd: TDaisyChatBubble;
    cdPlain: TDaisyCountdown;
    cdLarge: TDaisyCountdown;
    cdClock: TDaisyCountdown;
    cdLabels: TDaisyCountdown;
    cdBelow: TDaisyCountdown;
    cdBoxed: TDaisyCountdown;
    cdLive: TDaisyCountdown;
    cdMinutes: TDaisyCountdown;
    lstSecond: TDaisyList;
    lstThird: TDaisyList;
    lstWrap: TDaisyList;
    statBasic: TDaisyStat;
    statIcons: TDaisyStat;
    statCentered: TDaisyStat;
    statVertical: TDaisyStat;
    statCustom: TDaisyStat;
    edtChatText: TDaisyTextInput;
    edtChatHeader: TDaisyTextInput;
    lblChatEdit: TDaisyLabel;
    tsProgress: TDaisyTabSheet;
    lblProgVariants: TDaisyLabel;
    prgDefault: TDaisyProgress;
    prgPrimary: TDaisyProgress;
    prgSecondary: TDaisyProgress;
    prgAccent: TDaisyProgress;
    prgInfo: TDaisyProgress;
    prgSuccess: TDaisyProgress;
    prgWarning: TDaisyProgress;
    prgError: TDaisyProgress;
    lblProgSizes: TDaisyLabel;
    prgXS: TDaisyProgress;
    prgSM: TDaisyProgress;
    prgMD: TDaisyProgress;
    prgLG: TDaisyProgress;
    prgXL: TDaisyProgress;
    lblProgLive: TDaisyLabel;
    prgIndeterminate: TDaisyProgress;
    prgLive: TDaisyProgress;
    btnProgAdd: TDaisyButton;
    btnProgReset: TDaisyButton;
    lblRadial: TDaisyLabel;
    radDefault: TDaisyRadialProgress;
    radPrimary: TDaisyRadialProgress;
    radSecondary: TDaisyRadialProgress;
    radAccent: TDaisyRadialProgress;
    radInfo: TDaisyRadialProgress;
    radSuccess: TDaisyRadialProgress;
    radWarning: TDaisyRadialProgress;
    radError: TDaisyRadialProgress;
    lblRadialCustom: TDaisyLabel;
    radFilled: TDaisyRadialProgress;
    radThick: TDaisyRadialProgress;
    radText: TDaisyRadialProgress;
    radLive: TDaisyRadialProgress;
    procedure ProgressAddClick(Sender: TObject);
    procedure ProgressResetClick(Sender: TObject);
    procedure actProgResetUpdate(Sender: TObject);
    procedure RTLChange(Sender: TObject);
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListItemClick(Sender: TObject; AIndex, AAction: Integer);
    procedure StatActionClick(Sender: TObject; AIndex: Integer);
    procedure CountdownFinished(Sender: TObject);
    procedure CountdownClick(Sender: TObject);
    procedure ChatEditChange(Sender: TObject);
  end;

var
  Form16: TForm16;

implementation

{$R *.dfm}

procedure TForm16.RTLChange(Sender: TObject);
const
  Modes: array[Boolean] of TBiDiMode = (bdLeftToRight, bdRightToLeft);
begin
  if BiDiMode = Modes[chkRTL.Checked] then
    Exit;
  TDaisyControl.ApplyBiDiMode(Self, Modes[chkRTL.Checked]);
end;

procedure TForm16.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm16.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm16.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm16.chkTitleBarClick(Sender: TObject);
begin
  Styler.ThemedTitleBar := actTitleBar.Checked;
end;

procedure TForm16.actProgResetUpdate(Sender: TObject);
begin
  actProgReset.Enabled := prgLive.Value > prgLive.Min;
end;

procedure TForm16.ListItemClick(Sender: TObject; AIndex, AAction: Integer);
var
  LList: TDaisyList;
begin
  LList := Sender as TDaisyList;
  if AAction = 0 then
    lblStatus.Caption := Format('%s: row %d clicked', [LList.Name, AIndex])
  else
    lblStatus.Caption := Format('%s: row %d, button %d clicked', [LList.Name, AIndex, AAction]);
end;

procedure TForm16.StatActionClick(Sender: TObject; AIndex: Integer);
var
  LStat: TDaisyStat;
begin
  LStat := Sender as TDaisyStat;
  lblStatus.Caption := Format('%s: "%s" clicked', [LStat.Name, LStat.Items[AIndex].ActionCaption]);
end;

procedure TForm16.CountdownFinished(Sender: TObject);
begin
  lblStatus.Caption := 'Countdown finished';
end;

procedure TForm16.CountdownClick(Sender: TObject);
var
  LCountdown: TDaisyCountdown;
begin
  LCountdown := Sender as TDaisyCountdown;
  LCountdown.Active := not LCountdown.Active;
  if LCountdown.Active then
    lblStatus.Caption := LCountdown.Name + ' started'
  else
    lblStatus.Caption := LCountdown.Name + ' paused';
end;

procedure TForm16.ProgressAddClick(Sender: TObject);
begin
  if prgLive.Value >= prgLive.Max then
    prgLive.Value := prgLive.Min
  else
    prgLive.Value := prgLive.Value + 10;
  radLive.Value := prgLive.Value;
end;

procedure TForm16.ProgressResetClick(Sender: TObject);
begin
  prgLive.Value := prgLive.Min;
  radLive.Value := prgLive.Min;
end;

procedure TForm16.ChatEditChange(Sender: TObject);
begin
  chatStart.Caption := edtChatText.Text;
  chatStart.Header := edtChatHeader.Text;
end;

end.
