unit MainPeak;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Types, System.StrUtils, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Samples.Spin,
  Peak.SVG.Conversion, Peak.SVG.Lists, Peak.SVGImage, Peak.SVG.Base;

type
  TFormPeak = class(TForm)
    ImageList: TPeakSVGImageList;
    dlgSVGFile: TOpenDialog;
    dlgSVGFiles: TOpenDialog;
    dlgRasterFiles: TOpenDialog;
    dlgPngFiles: TOpenDialog;
    dlgFolder: TFileOpenDialog;
    pnlLeft: TPanel;
    gbSource: TGroupBox;
    btnAddFile: TButton;
    btnAddFiles: TButton;
    btnAddFolder: TButton;
    chkSubFolders: TCheckBox;
    btnRemove: TButton;
    btnClear: TButton;
    lbImages: TListBox;
    pnlRight: TPanel;
    gbPreview: TGroupBox;
    pnlPreview: TPanel;
    imgPreview: TPeakSVGImage;
    lblCaption: TLabel;
    lblSize: TLabel;
    lblFile: TLabel;
    chkColoured: TCheckBox;
    gbExport: TGroupBox;
    lblOutput: TLabel;
    edOutput: TEdit;
    btnBrowse: TButton;
    lblFormat: TLabel;
    cbFormat: TComboBox;
    lblPixels: TLabel;
    seSize: TSpinEdit;
    btnExportSelected: TButton;
    btnExportAll: TButton;
    gbRaster: TGroupBox;
    lblMode: TLabel;
    cbMode: TComboBox;
    btnRasterFiles: TButton;
    btnRasterFolder: TButton;
    btnPngToIco: TButton;
    chkRasterSub: TCheckBox;
    memLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure btnAddFileClick(Sender: TObject);
    procedure btnAddFilesClick(Sender: TObject);
    procedure btnAddFolderClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure lbImagesClick(Sender: TObject);
    procedure chkColouredClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnExportSelectedClick(Sender: TObject);
    procedure btnExportAllClick(Sender: TObject);
    procedure btnRasterFilesClick(Sender: TObject);
    procedure btnRasterFolderClick(Sender: TObject);
    procedure btnPngToIcoClick(Sender: TObject);
  private
    function OutputFolder: string;
    function TraceOptions: TPeakTraceOptions;
    procedure Log(const AText: string);
    procedure RefreshList(ASelect: Integer);
    procedure ShowItem;
    procedure ExportItem(AItem: TPeakSVGImageListItem; const AFolder: string);
    procedure RasterToSVG(const AFileName: string);
    procedure PngToIco(const AFileName: string);
    function CollectFiles(const AFolder: string; const APatterns: array of string): TArray<string>;
  end;

var
  FormPeak: TFormPeak;

implementation

{$R *.dfm}

procedure TFormPeak.FormCreate(Sender: TObject);
begin
  edOutput.Text := TPath.Combine(TPath.GetDocumentsPath, 'PeakSVG');
  cbFormat.ItemIndex := 0;
  cbMode.ItemIndex := 0;
end;

procedure TFormPeak.Log(const AText: string);
begin
  memLog.Lines.Add(AText);
end;

function TFormPeak.OutputFolder: string;
begin
  Result := Trim(edOutput.Text);
  if Result = '' then
    Result := TPath.Combine(TPath.GetDocumentsPath, 'PeakSVG');
  TDirectory.CreateDirectory(Result);
end;

function TFormPeak.TraceOptions: TPeakTraceOptions;
begin
  Result := TPeakTraceOptions.Default;
  if cbMode.ItemIndex = 1 then
    Result.Mode := tmEmbed
  else
    Result.Mode := tmTrace;
end;

function TFormPeak.CollectFiles(const AFolder: string; const APatterns: array of string): TArray<string>;
var
  LOption: TSearchOption;
  LPattern: string;
  LFile: string;
  LList: TStringList;
begin
  if chkRasterSub.Checked then
    LOption := TSearchOption.soAllDirectories
  else
    LOption := TSearchOption.soTopDirectoryOnly;
  LList := TStringList.Create;
  try
    for LPattern in APatterns do
      for LFile in TDirectory.GetFiles(AFolder, LPattern, LOption) do
        LList.Add(LFile);
    LList.Sort;
    Result := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

procedure TFormPeak.RefreshList(ASelect: Integer);
var
  LItem: TPeakSVGImageListItem;
begin
  lbImages.Items.BeginUpdate;
  try
    lbImages.Items.Clear;
    for LItem in ImageList.Items do
      lbImages.Items.Add(LItem.Caption);
  finally
    lbImages.Items.EndUpdate;
  end;
  if ASelect >= lbImages.Count then
    ASelect := lbImages.Count - 1;
  lbImages.ItemIndex := ASelect;
  ShowItem;
  gbSource.Caption := Format(' Source SVG images (%d) ', [ImageList.Count]);
end;

procedure TFormPeak.ShowItem;
var
  LItem: TPeakSVGImageListItem;
begin
  if lbImages.ItemIndex < 0 then
  begin
    imgPreview.SVG.Clear;
    lblCaption.Caption := 'Caption: -';
    lblSize.Caption := 'Size: -';
    lblFile.Caption := 'File: -';
    Exit;
  end;
  LItem := ImageList.Items[lbImages.ItemIndex];
  imgPreview.Colored := LItem.Coloured;
  chkColoured.Checked := LItem.Coloured;
  imgPreview.SVG.Text := LItem.SVG;
  lblCaption.Caption := 'Caption: ' + LItem.Caption;
  lblSize.Caption := Format('Size: %d x %d', [LItem.Width, LItem.Height]);
  lblFile.Caption := 'File: ' + LItem.FileName;
end;

procedure TFormPeak.lbImagesClick(Sender: TObject);
begin
  ShowItem;
end;

procedure TFormPeak.chkColouredClick(Sender: TObject);
begin
  if lbImages.ItemIndex >= 0 then
    ImageList.Items[lbImages.ItemIndex].Coloured := chkColoured.Checked;
  imgPreview.Colored := chkColoured.Checked;
end;

procedure TFormPeak.btnAddFileClick(Sender: TObject);
begin
  if not dlgSVGFile.Execute then
    Exit;
  ImageList.Load(dlgSVGFile.FileName);
  Log('Loaded ' + dlgSVGFile.FileName);
  RefreshList(ImageList.Count - 1);
end;

procedure TFormPeak.btnAddFilesClick(Sender: TObject);
var
  LCount: Integer;
begin
  if not dlgSVGFiles.Execute then
    Exit;
  LCount := ImageList.LoadFiles(dlgSVGFiles.Files);
  Log(Format('Loaded %d file(s)', [LCount]));
  RefreshList(ImageList.Count - 1);
end;

procedure TFormPeak.btnAddFolderClick(Sender: TObject);
var
  LCount: Integer;
begin
  if not dlgFolder.Execute then
    Exit;
  LCount := ImageList.LoadFolder(dlgFolder.FileName, chkSubFolders.Checked);
  Log(Format('Loaded %d file(s) from %s%s', [LCount, dlgFolder.FileName,
    IfThen(chkSubFolders.Checked, ' (including sub-folders)', '')]));
  RefreshList(ImageList.Count - 1);
end;

procedure TFormPeak.btnRemoveClick(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := lbImages.ItemIndex;
  if LIndex < 0 then
    Exit;
  ImageList.Delete(LIndex);
  RefreshList(LIndex);
end;

procedure TFormPeak.btnClearClick(Sender: TObject);
begin
  ImageList.Clear;
  RefreshList(-1);
end;

procedure TFormPeak.btnBrowseClick(Sender: TObject);
begin
  dlgFolder.FileName := '';
  if dlgFolder.Execute then
    edOutput.Text := dlgFolder.FileName;
end;

procedure TFormPeak.ExportItem(AItem: TPeakSVGImageListItem; const AFolder: string);
var
  LName: string;
  LSize: Integer;
begin
  LName := TPath.Combine(AFolder, TPath.GetFileNameWithoutExtension(AItem.Caption));
  LSize := seSize.Value;
  case cbFormat.ItemIndex of
    0: TPeakSVGConversion.SVGToPNG(AItem.SVG, LName + '.png', LSize, LSize);
    1: TPeakSVGConversion.SVGToBMP(AItem.SVG, LName + '.bmp', LSize, LSize);
    2: TPeakSVGConversion.SVGToJPG(AItem.SVG, LName + '.jpg', LSize, LSize);
  else
    TPeakSVGConversion.SVGToICO(AItem.SVG, LName + '.ico');
  end;
  Log(Format('%s -> %s.%s', [AItem.Caption, ExtractFileName(LName), LowerCase(cbFormat.Text)]));
end;

procedure TFormPeak.btnExportSelectedClick(Sender: TObject);
begin
  if lbImages.ItemIndex < 0 then
  begin
    Log('Select an image first');
    Exit;
  end;
  ExportItem(ImageList.Items[lbImages.ItemIndex], OutputFolder);
end;

procedure TFormPeak.btnExportAllClick(Sender: TObject);
var
  LItem: TPeakSVGImageListItem;
  LFolder: string;
begin
  LFolder := OutputFolder;
  for LItem in ImageList.Items do
    try
      ExportItem(LItem, LFolder);
    except
      on E: Exception do
        Log(LItem.Caption + ': ' + E.Message);
    end;
  Log(Format('Exported %d image(s) to %s', [ImageList.Count, LFolder]));
end;

procedure TFormPeak.RasterToSVG(const AFileName: string);
var
  LTarget: string;
begin
  LTarget := TPath.Combine(OutputFolder, TPath.GetFileNameWithoutExtension(AFileName) + '.svg');
  TFile.WriteAllText(LTarget, TPeakSVGConversion.ImageToSVG(AFileName, TraceOptions), TEncoding.UTF8);
  Log(ExtractFileName(AFileName) + ' -> ' + ExtractFileName(LTarget));
end;

procedure TFormPeak.PngToIco(const AFileName: string);
var
  LTarget: string;
begin
  LTarget := TPath.Combine(OutputFolder, TPath.GetFileNameWithoutExtension(AFileName) + '.ico');
  TPeakSVGConversion.PNGToICO(AFileName, LTarget);
  Log(ExtractFileName(AFileName) + ' -> ' + ExtractFileName(LTarget));
end;

procedure TFormPeak.btnRasterFilesClick(Sender: TObject);
var
  LFile: string;
begin
  if not dlgRasterFiles.Execute then
    Exit;
  for LFile in dlgRasterFiles.Files do
    try
      RasterToSVG(LFile);
    except
      on E: Exception do
        Log(ExtractFileName(LFile) + ': ' + E.Message);
    end;
end;

procedure TFormPeak.btnRasterFolderClick(Sender: TObject);
var
  LFile: string;
begin
  if not dlgFolder.Execute then
    Exit;
  for LFile in CollectFiles(dlgFolder.FileName, ['*.png', '*.bmp', '*.jpg', '*.jpeg']) do
    try
      RasterToSVG(LFile);
    except
      on E: Exception do
        Log(ExtractFileName(LFile) + ': ' + E.Message);
    end;
end;

procedure TFormPeak.btnPngToIcoClick(Sender: TObject);
var
  LFile: string;
begin
  if not dlgPngFiles.Execute then
    Exit;
  for LFile in dlgPngFiles.Files do
    try
      PngToIco(LFile);
    except
      on E: Exception do
        Log(ExtractFileName(LFile) + ': ' + E.Message);
    end;
end;

end.
