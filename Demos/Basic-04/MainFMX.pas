unit MainFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Edit, FMX.Layouts, FMX.Controls.Presentation, FMX.ActnList, System.Actions,
  Daisy.Theme, Daisy.Widgets, Daisy.FMX.Control, Daisy.FMX.Button, Daisy.FMX.Chat,
  Daisy.FMX.Countdown, Daisy.FMX.List, Daisy.FMX.Stat, Daisy.FMX.Select, Daisy.FMX.FormStyler,
  Daisy.FMX.CheckBox, Daisy.FMX.PageControl, Daisy.FMX.TextInput,
  Daisy.FMX.Labels, Daisy.FMX.Progress, Daisy.FMX.RadialProgress,
  Daisy.FMX.ThemeController;

type
  TForm17 = class(TForm)
    lblTheme: TLabel;
    lblStatus: TLabel;
    selTheme: TDaisyFmxSelect;
    themeCtl: TDaisyFmxThemeController;
    Styler: TDaisyFmxFormStyler;
    chkTitleBar: TDaisyFmxCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actProgAdd: TAction;
    actProgReset: TAction;
    pcMain: TDaisyFmxPageControl;
    tsChat: TDaisyFmxTabSheet;
    tsCountdown: TDaisyFmxTabSheet;
    tsList: TDaisyFmxTabSheet;
    tsStat: TDaisyFmxTabSheet;
    chatStart: TDaisyFmxChatBubble;
    chatEnd: TDaisyFmxChatBubble;
    chatSvg: TDaisyFmxChatBubble;
    chatEmoji: TDaisyFmxChatBubble;
    chatPrimary: TDaisyFmxChatBubble;
    chatSecondary: TDaisyFmxChatBubble;
    chatAccent: TDaisyFmxChatBubble;
    chatInfo: TDaisyFmxChatBubble;
    chatSuccess: TDaisyFmxChatBubble;
    chatWarning: TDaisyFmxChatBubble;
    chatError: TDaisyFmxChatBubble;
    chatNoAvatar: TDaisyFmxChatBubble;
    chatNoAvatarEnd: TDaisyFmxChatBubble;
    cdPlain: TDaisyFmxCountdown;
    cdLarge: TDaisyFmxCountdown;
    cdClock: TDaisyFmxCountdown;
    cdLabels: TDaisyFmxCountdown;
    cdBelow: TDaisyFmxCountdown;
    cdBoxed: TDaisyFmxCountdown;
    cdLive: TDaisyFmxCountdown;
    cdMinutes: TDaisyFmxCountdown;
    lstSecond: TDaisyFmxList;
    lstThird: TDaisyFmxList;
    lstWrap: TDaisyFmxList;
    statBasic: TDaisyFmxStat;
    statIcons: TDaisyFmxStat;
    statCentered: TDaisyFmxStat;
    statVertical: TDaisyFmxStat;
    statCustom: TDaisyFmxStat;
    edtChatText: TDaisyFmxTextInput;
    edtChatHeader: TDaisyFmxTextInput;
    lblChatEdit: TDaisyFmxLabel;
    tsProgress: TDaisyFmxTabSheet;
    lblProgVariants: TDaisyFmxLabel;
    prgDefault: TDaisyFmxProgress;
    prgPrimary: TDaisyFmxProgress;
    prgSecondary: TDaisyFmxProgress;
    prgAccent: TDaisyFmxProgress;
    prgInfo: TDaisyFmxProgress;
    prgSuccess: TDaisyFmxProgress;
    prgWarning: TDaisyFmxProgress;
    prgError: TDaisyFmxProgress;
    lblProgSizes: TDaisyFmxLabel;
    prgXS: TDaisyFmxProgress;
    prgSM: TDaisyFmxProgress;
    prgMD: TDaisyFmxProgress;
    prgLG: TDaisyFmxProgress;
    prgXL: TDaisyFmxProgress;
    lblProgLive: TDaisyFmxLabel;
    prgIndeterminate: TDaisyFmxProgress;
    prgLive: TDaisyFmxProgress;
    btnProgAdd: TDaisyFmxButton;
    btnProgReset: TDaisyFmxButton;
    lblRadial: TDaisyFmxLabel;
    radDefault: TDaisyFmxRadialProgress;
    radPrimary: TDaisyFmxRadialProgress;
    radSecondary: TDaisyFmxRadialProgress;
    radAccent: TDaisyFmxRadialProgress;
    radInfo: TDaisyFmxRadialProgress;
    radSuccess: TDaisyFmxRadialProgress;
    radWarning: TDaisyFmxRadialProgress;
    radError: TDaisyFmxRadialProgress;
    lblRadialCustom: TDaisyFmxLabel;
    radFilled: TDaisyFmxRadialProgress;
    radThick: TDaisyFmxRadialProgress;
    radText: TDaisyFmxRadialProgress;
    radLive: TDaisyFmxRadialProgress;
    chkRTL: TDaisyFmxCheckBox;
    procedure RTLChange(Sender: TObject);
    procedure ProgressAddClick(Sender: TObject);
    procedure ProgressResetClick(Sender: TObject);
    procedure actProgResetUpdate(Sender: TObject);
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListItemClick(Sender: TObject; AIndex, AAction: Integer);
    procedure StatActionClick(Sender: TObject; AIndex: Integer);
    procedure CountdownFinished(Sender: TObject);
    procedure CountdownClick(Sender: TObject);
    procedure ChatEditChange(Sender: TObject);
  end;

var
  Form17: TForm17;

implementation

{$R *.fmx}

procedure TForm17.RTLChange(Sender: TObject);
const
  Modes: array[Boolean] of TBiDiMode = (bdLeftToRight, bdRightToLeft);
begin
  TDaisyControl.ApplyBiDiMode(Self, Modes[chkRTL.Checked]);
end;

procedure TForm17.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm17.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm17.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm17.chkTitleBarChange(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm17.ListItemClick(Sender: TObject; AIndex, AAction: Integer);
var
  LList: TDaisyFmxList;
begin
  LList := Sender as TDaisyFmxList;
  if AAction = 0 then
    lblStatus.Text := Format('%s: row %d clicked', [LList.Name, AIndex])
  else
    lblStatus.Text := Format('%s: row %d, button %d clicked', [LList.Name, AIndex, AAction]);
end;

procedure TForm17.StatActionClick(Sender: TObject; AIndex: Integer);
var
  LStat: TDaisyFmxStat;
begin
  LStat := Sender as TDaisyFmxStat;
  lblStatus.Text := Format('%s: "%s" clicked', [LStat.Name, LStat.Items[AIndex].ActionCaption]);
end;

procedure TForm17.CountdownFinished(Sender: TObject);
begin
  lblStatus.Text := 'Countdown finished';
end;

procedure TForm17.CountdownClick(Sender: TObject);
var
  LCountdown: TDaisyFmxCountdown;
begin
  LCountdown := Sender as TDaisyFmxCountdown;
  LCountdown.Active := not LCountdown.Active;
  if LCountdown.Active then
    lblStatus.Text := LCountdown.Name + ' started'
  else
    lblStatus.Text := LCountdown.Name + ' paused';
end;

procedure TForm17.ProgressAddClick(Sender: TObject);
begin
  if prgLive.Value >= prgLive.Max then
    prgLive.Value := prgLive.Min
  else
    prgLive.Value := prgLive.Value + 10;
  radLive.Value := prgLive.Value;
end;

procedure TForm17.ProgressResetClick(Sender: TObject);
begin
  prgLive.Value := prgLive.Min;
  radLive.Value := prgLive.Min;
end;

procedure TForm17.actProgResetUpdate(Sender: TObject);
begin
  actProgReset.Enabled := prgLive.Value > prgLive.Min;
end;

procedure TForm17.ChatEditChange(Sender: TObject);
begin
  chatStart.Text := edtChatText.Text;
  chatStart.Header := edtChatHeader.Text;
end;

end.
