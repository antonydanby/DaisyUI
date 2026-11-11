unit MainVCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.ActnList, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.StrUtils, Daisy.Items, Daisy.VCL.Button,
  Daisy.VCL.IconButton, Daisy.VCL.LoadingButton, Daisy.VCL.Dropdown, Daisy.VCL.Fab,
  Daisy.VCL.Control, Daisy.VCL.Accordion, Daisy.VCL.Select, Daisy.VCL.FormStyler, Daisy.Theme,
  Daisy.VCL.PageControl, Daisy.VCL.CheckBox, Daisy.Toasts, Daisy.VCL.Toast, Daisy.VCL.Range,
  Daisy.VCL.Rating, Daisy.VCL.ThemeController, System.Actions;

type
  TForm12 = class(TForm)
    lblSquare: TLabel;
    lblCircle: TLabel;
    lblLoading: TLabel;
    lblAnimation: TLabel;
    lblAnimStatus: TLabel;
    lblDropdown: TLabel;
    lblDropResult: TLabel;
    lblFab: TLabel;
    lblFabResult: TLabel;
    lblArc: TLabel;
    lblAccordion: TLabel;
    lblJoined: TLabel;
    lblAccResult: TLabel;
    btnSquareXS: TDaisySquareButton;
    btnSquareSM: TDaisySquareButton;
    btnSquareMD: TDaisySquareButton;
    btnSquareLG: TDaisySquareButton;
    btnSquareXL: TDaisySquareButton;
    btnSquareGhost: TDaisySquareButton;
    btnCircleXS: TDaisyCircleButton;
    btnCircleSM: TDaisyCircleButton;
    btnCircleMD: TDaisyCircleButton;
    btnCircleLG: TDaisyCircleButton;
    btnCircleXL: TDaisyCircleButton;
    btnCircleGhost: TDaisyCircleButton;
    btnLoadSpinner: TDaisyLoadingButton;
    btnLoadRing: TDaisyLoadingButton;
    btnLoadDots: TDaisyLoadingButton;
    btnLoadBars: TDaisyLoadingButton;
    btnLoadBall: TDaisyLoadingButton;
    btnLoadRight: TDaisyLoadingButton;
    btnLoadReplace: TDaisyLoadingButton;
    btnLoadCaption: TDaisyLoadingButton;
    btnToggleLoading: TDaisyButton;
    btnAnimDots: TDaisyAnimationButton;
    btnAnimBars: TDaisyAnimationButton;
    btnAnimBall: TDaisyAnimationButton;
    ddMenu: TDaisyDropdownMenu;
    ddEnd: TDaisyDropdownMenu;
    ddTop: TDaisyDropdownMenu;
    ddSide: TDaisyDropdownMenu;
    fabDown: TDaisyFloatingActionButton;
    fabRight: TDaisyFloatingActionButton;
    fabLeft: TDaisyFloatingActionButton;
    fabUp: TDaisyFloatingActionButton;
    fabArc: TDaisyFloatingActionButton;
    accSeparate: TDaisyAccordion;
    accJoined: TDaisyAccordion;
    lblTheme: TLabel;
    selTheme: TDaisySelect;
    themeCtl: TDaisyThemeController;
    Styler: TDaisyFormStyler;
    chkTitleBar: TDaisyCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actToastClear: TAction;
    actToggleLoading: TAction;
    pcMain: TDaisyPageControl;
    tsButtons: TDaisyTabSheet;
    tsLoading: TDaisyTabSheet;
    tsDropdown: TDaisyTabSheet;
    tsFab: TDaisyTabSheet;
    tsAccordion: TDaisyTabSheet;
    tsToast: TDaisyTabSheet;
    lblToast: TLabel;
    lblToastDuration: TLabel;
    lblToastHorz: TLabel;
    lblToastVert: TLabel;
    lblToastHint: TLabel;
    toastDemo: TDaisyToast;
    selToastDuration: TDaisySelect;
    selToastHorz: TDaisySelect;
    selToastVert: TDaisySelect;
    btnToastInfo: TDaisyButton;
    btnToastSuccess: TDaisyButton;
    btnToastWarning: TDaisyButton;
    btnToastError: TDaisyButton;
    btnToastClear: TDaisyButton;
    tsRange: TDaisyTabSheet;
    lblRange: TLabel;
    lblRangeValue: TLabel;
    rngDefault: TDaisyRange;
    rngPrimary: TDaisyRange;
    rngSecondary: TDaisyRange;
    rngAccent: TDaisyRange;
    rngInfo: TDaisyRange;
    rngSuccess: TDaisyRange;
    rngWarning: TDaisyRange;
    rngError: TDaisyRange;
    rngXS: TDaisyRange;
    rngSM: TDaisyRange;
    rngMD: TDaisyRange;
    rngLG: TDaisyRange;
    rngXL: TDaisyRange;
    rngSteps: TDaisyRange;
    rngNoFill: TDaisyRange;
    rngVertical: TDaisyRange;
    rngVerticalSteps: TDaisyRange;
    tsRating: TDaisyTabSheet;
    lblRating: TLabel;
    lblRatingValue: TLabel;
    ratDefault: TDaisyRating;
    ratHalf: TDaisyRating;
    ratHeart: TDaisyRating;
    ratReadOnly: TDaisyRating;
    ratMulti: TDaisyRating;
    ratClear: TDaisyRating;
    ratXS: TDaisyRating;
    ratSM: TDaisyRating;
    ratMD: TDaisyRating;
    ratLG: TDaisyRating;
    ratXL: TDaisyRating;
    ratThree: TDaisyRating;
    ratTen: TDaisyRating;
    procedure RangeChange(Sender: TObject);
    procedure RatingChange(Sender: TObject);
    procedure ToastPostClick(Sender: TObject);
    procedure ToastClearClick(Sender: TObject);
    procedure ToastDurationChange(Sender: TObject);
    procedure ToastPlacementChange(Sender: TObject);
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnToggleLoadingClick(Sender: TObject);
    procedure AnimationFinished(Sender: TObject);
    procedure DropdownItemClick(Sender: TObject; AItem: TDaisyItem);
    procedure FabItemClick(Sender: TObject; AItem: TDaisyItem);
    procedure AccordionToggle(Sender: TObject; AIndex: Integer);
  end;

var
  Form12: TForm12;

implementation

{$R *.dfm}

procedure TForm12.RangeChange(Sender: TObject);
begin
  lblRangeValue.Caption := 'Value: ' + FloatToStr(rngDefault.Value);
end;

procedure TForm12.RatingChange(Sender: TObject);
begin
  lblRatingValue.Caption := 'Rating: ' + FloatToStr(ratDefault.Value) + ' / ' +
    IntToStr(ratDefault.Count);
end;

procedure TForm12.ToastPostClick(Sender: TObject);
const
  CNames: array[0..3] of string = ('Information', 'Success', 'Warning', 'Error');
var
  LIndex: Integer;
begin
  LIndex := (Sender as TComponent).Tag;
  toastDemo.Post(CNames[LIndex] + ' message at ' + FormatDateTime('hh:nn:ss', Now),
    TDaisyVariant(Ord(dvInfo) + LIndex));
end;

procedure TForm12.ToastClearClick(Sender: TObject);
begin
  toastDemo.Clear;
end;

procedure TForm12.ToastDurationChange(Sender: TObject);
begin
  toastDemo.Duration := TDaisyToastDuration(selToastDuration.ItemIndex);
end;

procedure TForm12.ToastPlacementChange(Sender: TObject);
begin
  toastDemo.HorizontalPlacement := TDaisyToastHPlacement(selToastHorz.ItemIndex);
  toastDemo.VerticalPlacement := TDaisyToastVPlacement(selToastVert.ItemIndex);
end;

procedure TForm12.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm12.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm12.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm12.chkTitleBarClick(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm12.btnToggleLoadingClick(Sender: TObject);
var
  LLoad: TDaisyLoadingButton;
begin
  for LLoad in [btnLoadSpinner, btnLoadRing, btnLoadDots, btnLoadBars, btnLoadBall,
    btnLoadRight, btnLoadReplace, btnLoadCaption] do
    LLoad.Loading := not LLoad.Loading;
end;

procedure TForm12.AnimationFinished(Sender: TObject);
begin
  lblAnimStatus.Caption := 'Animation finished: ' + TDaisyAnimationButton(Sender).Name;
end;

procedure TForm12.DropdownItemClick(Sender: TObject; AItem: TDaisyItem);
begin
  lblDropResult.Caption := 'Selected: ' + AItem.Caption + ' (from ' + TComponent(Sender).Name + ')';
end;

procedure TForm12.FabItemClick(Sender: TObject; AItem: TDaisyItem);
begin
  lblFabResult.Caption := 'FAB action: ' + IfThen(AItem.Description <> '', AItem.Description,
    'item ' + IntToStr(AItem.Index + 1)) + ' (' + TComponent(Sender).Name + ')';
end;

procedure TForm12.AccordionToggle(Sender: TObject; AIndex: Integer);
var
  LAcc: TDaisyAccordion;
begin
  LAcc := TDaisyAccordion(Sender);
  lblAccResult.Caption := 'Accordion: ' + LAcc.Items[AIndex].Title + IfThen(LAcc.Items[AIndex].Expanded,
    ' opened', ' closed') + ' (' + LAcc.Name + ')';
end;

end.
