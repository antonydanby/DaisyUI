unit MainFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types,   FMX.Controls, FMX.ActnList, System.Actions, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation,
  Daisy.Items, Daisy.FMX.Button, Daisy.FMX.IconButton, Daisy.FMX.LoadingButton, Daisy.FMX.Dropdown,
  Daisy.FMX.Fab, Daisy.FMX.Control, Daisy.FMX.Accordion, Daisy.FMX.Select, Daisy.FMX.FormStyler, Daisy.Theme, Daisy.FMX.PageControl,
  Daisy.FMX.CheckBox, Daisy.Toasts, Daisy.FMX.Toast, Daisy.FMX.Range, Daisy.FMX.Rating,
  Daisy.FMX.ThemeController;

type
  TForm13 = class(TForm)
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
    btnSquareXS: TDaisyFmxSquareButton;
    btnSquareSM: TDaisyFmxSquareButton;
    btnSquareMD: TDaisyFmxSquareButton;
    btnSquareLG: TDaisyFmxSquareButton;
    btnSquareXL: TDaisyFmxSquareButton;
    btnSquareGhost: TDaisyFmxSquareButton;
    btnCircleXS: TDaisyFmxCircleButton;
    btnCircleSM: TDaisyFmxCircleButton;
    btnCircleMD: TDaisyFmxCircleButton;
    btnCircleLG: TDaisyFmxCircleButton;
    btnCircleXL: TDaisyFmxCircleButton;
    btnCircleGhost: TDaisyFmxCircleButton;
    btnLoadSpinner: TDaisyFmxLoadingButton;
    btnLoadRing: TDaisyFmxLoadingButton;
    btnLoadDots: TDaisyFmxLoadingButton;
    btnLoadBars: TDaisyFmxLoadingButton;
    btnLoadBall: TDaisyFmxLoadingButton;
    btnLoadRight: TDaisyFmxLoadingButton;
    btnLoadReplace: TDaisyFmxLoadingButton;
    btnLoadCaption: TDaisyFmxLoadingButton;
    btnToggleLoading: TDaisyFmxButton;
    btnAnimDots: TDaisyFmxAnimationButton;
    btnAnimBars: TDaisyFmxAnimationButton;
    btnAnimBall: TDaisyFmxAnimationButton;
    ddMenu: TDaisyFmxDropdownMenu;
    ddEnd: TDaisyFmxDropdownMenu;
    ddTop: TDaisyFmxDropdownMenu;
    ddSide: TDaisyFmxDropdownMenu;
    fabDown: TDaisyFmxFloatingActionButton;
    fabRight: TDaisyFmxFloatingActionButton;
    fabLeft: TDaisyFmxFloatingActionButton;
    fabUp: TDaisyFmxFloatingActionButton;
    fabArc: TDaisyFmxFloatingActionButton;
    accSeparate: TDaisyFmxAccordion;
    accJoined: TDaisyFmxAccordion;
    lblTheme: TLabel;
    selTheme: TDaisyFmxSelect;
    themeCtl: TDaisyFmxThemeController;
    Styler: TDaisyFmxFormStyler;
    chkTitleBar: TDaisyFmxCheckBox;
    alMain: TActionList;
    actTitleBar: TAction;
    actToastClear: TAction;
    actToggleLoading: TAction;
    pcMain: TDaisyFmxPageControl;
    tsButtons: TDaisyFmxTabSheet;
    tsLoading: TDaisyFmxTabSheet;
    tsDropdown: TDaisyFmxTabSheet;
    tsFab: TDaisyFmxTabSheet;
    tsAccordion: TDaisyFmxTabSheet;
    tsToast: TDaisyFmxTabSheet;
    lblToast: TLabel;
    lblToastDuration: TLabel;
    lblToastHorz: TLabel;
    lblToastVert: TLabel;
    lblToastHint: TLabel;
    toastDemo: TDaisyFmxToast;
    selToastDuration: TDaisyFmxSelect;
    selToastHorz: TDaisyFmxSelect;
    selToastVert: TDaisyFmxSelect;
    btnToastInfo: TDaisyFmxButton;
    btnToastSuccess: TDaisyFmxButton;
    btnToastWarning: TDaisyFmxButton;
    btnToastError: TDaisyFmxButton;
    btnToastClear: TDaisyFmxButton;
    tsRange: TDaisyFmxTabSheet;
    lblRange: TLabel;
    lblRangeValue: TLabel;
    rngDefault: TDaisyFmxRange;
    rngPrimary: TDaisyFmxRange;
    rngSecondary: TDaisyFmxRange;
    rngAccent: TDaisyFmxRange;
    rngInfo: TDaisyFmxRange;
    rngSuccess: TDaisyFmxRange;
    rngWarning: TDaisyFmxRange;
    rngError: TDaisyFmxRange;
    rngXS: TDaisyFmxRange;
    rngSM: TDaisyFmxRange;
    rngMD: TDaisyFmxRange;
    rngLG: TDaisyFmxRange;
    rngXL: TDaisyFmxRange;
    rngSteps: TDaisyFmxRange;
    rngNoFill: TDaisyFmxRange;
    rngVertical: TDaisyFmxRange;
    rngVerticalSteps: TDaisyFmxRange;
    tsRating: TDaisyFmxTabSheet;
    lblRating: TLabel;
    lblRatingValue: TLabel;
    ratDefault: TDaisyFmxRating;
    ratHalf: TDaisyFmxRating;
    ratHeart: TDaisyFmxRating;
    ratReadOnly: TDaisyFmxRating;
    ratMulti: TDaisyFmxRating;
    ratClear: TDaisyFmxRating;
    ratXS: TDaisyFmxRating;
    ratSM: TDaisyFmxRating;
    ratMD: TDaisyFmxRating;
    ratLG: TDaisyFmxRating;
    ratXL: TDaisyFmxRating;
    ratThree: TDaisyFmxRating;
    ratTen: TDaisyFmxRating;
    procedure RangeChange(Sender: TObject);
    procedure RatingChange(Sender: TObject);
    procedure ToastPostClick(Sender: TObject);
    procedure ToastClearClick(Sender: TObject);
    procedure ToastDurationChange(Sender: TObject);
    procedure ToastPlacementChange(Sender: TObject);
    procedure ThemeSelectChange(Sender: TObject);
    procedure ThemeControllerChange(Sender: TObject);
    procedure chkTitleBarChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnToggleLoadingClick(Sender: TObject);
    procedure AnimationFinished(Sender: TObject);
    procedure DropdownItemClick(Sender: TObject; AItem: TDaisyItem);
    procedure FabItemClick(Sender: TObject; AItem: TDaisyItem);
    procedure AccordionToggle(Sender: TObject; AIndex: Integer);
  end;

var
  Form13: TForm13;

implementation

{$R *.fmx}

procedure TForm13.RangeChange(Sender: TObject);
begin
  lblRangeValue.Text := 'Value: ' + FloatToStr(rngDefault.Value);
end;

procedure TForm13.RatingChange(Sender: TObject);
begin
  lblRatingValue.Text := 'Rating: ' + FloatToStr(ratDefault.Value) + ' / ' +
    IntToStr(ratDefault.Count);
end;

procedure TForm13.ToastPostClick(Sender: TObject);
const
  CNames: array[0..3] of string = ('Information', 'Success', 'Warning', 'Error');
var
  LIndex: Integer;
begin
  LIndex := (Sender as TComponent).Tag;
  toastDemo.Post(CNames[LIndex] + ' message at ' + FormatDateTime('hh:nn:ss', Now),
    TDaisyVariant(Ord(dvInfo) + LIndex));
end;

procedure TForm13.ToastClearClick(Sender: TObject);
begin
  toastDemo.Clear;
end;

procedure TForm13.ToastDurationChange(Sender: TObject);
begin
  toastDemo.Duration := TDaisyToastDuration(selToastDuration.ItemIndex);
end;

procedure TForm13.ToastPlacementChange(Sender: TObject);
begin
  toastDemo.HorizontalPlacement := TDaisyToastHPlacement(selToastHorz.ItemIndex);
  toastDemo.VerticalPlacement := TDaisyToastVPlacement(selToastVert.ItemIndex);
end;

procedure TForm13.FormShow(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm13.ThemeControllerChange(Sender: TObject);
begin
  selTheme.ItemIndex := Ord(DaisyThemes.Current) - 1;
end;

procedure TForm13.ThemeSelectChange(Sender: TObject);
begin
  Styler.ApplyTheme(TDaisyThemeKind(selTheme.ItemIndex + 1));
end;

procedure TForm13.chkTitleBarChange(Sender: TObject);
begin
  Styler.ThemedTitleBar := chkTitleBar.Checked;
end;

procedure TForm13.btnToggleLoadingClick(Sender: TObject);
var
  LLoad: TDaisyFmxLoadingButton;
begin
  for LLoad in [btnLoadSpinner, btnLoadRing, btnLoadDots, btnLoadBars, btnLoadBall,
    btnLoadRight, btnLoadReplace, btnLoadCaption] do
    LLoad.Loading := not LLoad.Loading;
end;

procedure TForm13.AnimationFinished(Sender: TObject);
begin
  lblAnimStatus.Text := 'Animation finished: ' + TDaisyFmxAnimationButton(Sender).Name;
end;

procedure TForm13.DropdownItemClick(Sender: TObject; AItem: TDaisyItem);
begin
  lblDropResult.Text := 'Selected: ' + AItem.Caption + ' (from ' + TComponent(Sender).Name + ')';
end;

procedure TForm13.FabItemClick(Sender: TObject; AItem: TDaisyItem);
var
  LText: string;
begin
  LText := AItem.Description;
  if LText = '' then
    LText := 'item ' + IntToStr(AItem.Index + 1);
  lblFabResult.Text := 'FAB action: ' + LText + ' (' + TComponent(Sender).Name + ')';
end;

procedure TForm13.AccordionToggle(Sender: TObject; AIndex: Integer);
var
  LAcc: TDaisyFmxAccordion;
  LState: string;
begin
  LAcc := TDaisyFmxAccordion(Sender);
  if LAcc.Items[AIndex].Expanded then
    LState := ' opened'
  else
    LState := ' closed';
  lblAccResult.Text := 'Accordion: ' + LAcc.Items[AIndex].Title + LState + ' (' + LAcc.Name + ')';
end;

end.
