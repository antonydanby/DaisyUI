unit Daisy.VCL.TextInput;

{
  TDaisyCustomTextEdit - the editing engine shared by TDaisyTextInput and
  TDaisyTextArea (see Daisy.VCL.TextArea).

  The control paints and edits its own text: caret, selection, clipboard, undo,
  word / line navigation and mouse selection come from Daisy.TextEdit; text is
  drawn through DrawRichText so colour emoji work (Direct2D). The focused state
  only darkens the border - it never gets thicker.

  TDaisyTextInput - the DaisyUI "input": a single line with variants, sizes,
  ghost / soft styles, SVG or emoji icons at either end, a before / after /
  floating label, a fieldset legend and helper text.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Vcl.Clipbrd, Daisy.Theme, Daisy.Widgets, Daisy.Animation,
  Daisy.TextEdit, Daisy.VCL.Control;

type
  TDaisyCustomTextEdit = class(TDaisyControl)
  strict private
    FModel: TDaisyTextModel;
    FMeasureBmp: TBitmap;
    FMeasureFn: TDaisyMeasureFunc;
    FMeasureKey: string;
    FPlaceholder: string;
    FReadOnly: Boolean;
    FLegend: string;
    FHelperText: string;
    FLabelText: string;
    FLabelMode: TDaisyInputLabelMode;
    FOnChange: TNotifyEvent;
    FLayoutDirty: Boolean;
    FLayoutWidth: Integer;
    FScrollPos: Integer;
    FTopLine: Integer;
    FDesiredX: Single;
    FPendingHigh: Char;
    FDragging: Boolean;
    FBarDrag: Boolean;
    FBarGrab: Integer;
    FBlinkOrigin: Double;
    FBlinkOn: Boolean;
    FTicking: Boolean;
    FField, FTextBox, FStartBox, FEndBox, FLegendRect, FHintRect, FLabelBox, FChip: TRect;
    FTrack, FThumb: TRect;
    FDivX: Integer;
    FLineH: Integer;
    FRows: Integer;
    FFontSize, FSmallSize: Integer;
    FHasBar: Boolean;
    procedure SetPlaceholder(const Value: string);
    procedure SetReadOnly(const Value: Boolean);
    function GetModelText: string;
    procedure SetModelText(const Value: string);
    procedure SetLegend(const Value: string);
    procedure SetHelperText(const Value: string);
    procedure SetLabelText(const Value: string);
    procedure SetLabelMode(const Value: TDaisyInputLabelMode);
    function GetMaxLength: Integer;
    procedure SetMaxLength(const Value: Integer);
    function GetSelStart: Integer;
    procedure SetSelStart(const Value: Integer);
    function GetSelLength: Integer;
    procedure SetSelLength(const Value: Integer);
    function GetSelText: string;
    function MeasureStr(const AText: string): Single;
    function ScrollOffsetPx: Single;
    function PosToX(APos: Integer): Single;
    function PosFromPoint(X, Y: Integer): Integer;
    procedure DoLayout(AWidth: Integer);
    procedure ComputeGeometry;
    procedure Edited;
    procedure CaretMoved(AKeepDesiredX: Boolean = False);
    procedure ResetBlink;
    procedure Tick(Sender: TObject);
    procedure StartTicking;
    procedure StopTicking;
    procedure ScrollBarTo(Y: Integer);
    procedure MoveVertical(ALines: Integer; AExtend: Boolean);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMCursorChanged(var Message: TMessage); message CM_CURSORCHANGED;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure Loaded; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;

    // Hooks for TDaisyTextInput / TDaisyTextArea
    function IsMultiLine: Boolean; virtual;
    function PasswordMask: Char; virtual;
    function StartIconSource: TDaisyIconSource; virtual;
    function EndIconSource: TDaisyIconSource; virtual;
    function PadX: Integer;
    // The field's rectangle and the end icon's rectangle, in client coordinates
    function FieldRect: TRect;
    function EndIconRect: TRect;
    // Called when the text changed through typing, pasting or Text, but not while loading
    procedure TextEdited; virtual;
    // Space above the field (legend and floating label) and below it (helper text)
    function TopOffset: Integer;
    function HintArea: Integer;
    procedure IconsChanged;
    procedure EnsureGeometry;
    procedure ModelChanged;
    property Model: TDaisyTextModel read FModel;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SelectAll;
    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;
    procedure Undo;
    procedure Redo;
    procedure Clear;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelText: string read GetSelText;
  published
    property Text: string read GetModelText write SetModelText;
    // Shown in a dimmed colour while the field is empty
    property Placeholder: string read FPlaceholder write SetPlaceholder;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property MaxLength: Integer read GetMaxLength write SetMaxLength default 0;
    // Fieldset legend above the field
    property Legend: string read FLegend write SetLegend;
    // Small text under the field
    property HelperText: string read FHelperText write SetHelperText;
    // A label before / after the text, or a floating label
    property LabelText: string read FLabelText write SetLabelText;
    property LabelMode: TDaisyInputLabelMode read FLabelMode write SetLabelMode default ilmNone;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

  TDaisyTextInput = class(TDaisyCustomTextEdit)
  strict private
    FStartIcon: TDaisyIconSource;
    FEndIcon: TDaisyIconSource;
    FPasswordChar: Char;
    FAutoFit: Boolean;
    FUpdating: Boolean;
    procedure SetPasswordChar(const Value: Char);
    procedure SetAutoFit(const Value: Boolean);
    function GetStartEmoji: string;
    procedure SetStartEmoji(const Value: string);
    function GetStartSVG: TStrings;
    procedure SetStartSVG(const Value: TStrings);
    function GetEndEmoji: string;
    procedure SetEndEmoji(const Value: string);
    function GetEndSVG: TStrings;
    procedure SetEndSVG(const Value: TStrings);
    procedure IconChanged(Sender: TObject);
    procedure UpdateSize;
  protected
    function PasswordMask: Char; override;
    function StartIconSource: TDaisyIconSource; override;
    function EndIconSource: TDaisyIconSource; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // Hides the text behind this character (#0 = show the text)
    property PasswordChar: Char read FPasswordChar write SetPasswordChar default #0;
    // Icon at the start of the field: an emoji or SVG markup / an .svg file
    property StartEmoji: string read GetStartEmoji write SetStartEmoji;
    property StartSVG: TStrings read GetStartSVG write SetStartSVG;
    // Icon at the end of the field
    property EndEmoji: string read GetEndEmoji write SetEndEmoji;
    property EndSVG: TStrings read GetEndSVG write SetEndSVG;
    // The height follows SizeKind, the legend and the helper text; when off the control keeps its own size
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
  end;

implementation

const
  CBlinkSeconds = 0.53;
  CBarWidth = 10;

{ TDaisyCustomTextEdit }

constructor TDaisyCustomTextEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FModel := TDaisyTextModel.Create;
  FMeasureBmp := TBitmap.Create;
  FMeasureFn := function(const AText: string): Single
    begin
      Result := MeasureStr(AText);
    end;
  FLayoutDirty := True;
  FDesiredX := -1;
  FBlinkOn := True;
  TabStop := True;
  Cursor := crIBeam;
  ControlStyle := ControlStyle + [csCaptureMouse];
end;

destructor TDaisyCustomTextEdit.Destroy;
begin
  StopTicking;
  FMeasureBmp.Free;
  FModel.Free;
  inherited Destroy;
end;

function TDaisyCustomTextEdit.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyCustomTextEdit.DrawsFocusRing: Boolean;
begin
  Result := False; // the border shows the focus, only darker
end;

function TDaisyCustomTextEdit.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyCustomTextEdit.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyCustomTextEdit.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyCustomTextEdit.IsMultiLine: Boolean;
begin
  Result := False;
end;

function TDaisyCustomTextEdit.PasswordMask: Char;
begin
  Result := #0;
end;

function TDaisyCustomTextEdit.StartIconSource: TDaisyIconSource;
begin
  Result := nil;
end;

function TDaisyCustomTextEdit.EndIconSource: TDaisyIconSource;
begin
  Result := nil;
end;

function TDaisyCustomTextEdit.PadX: Integer;
begin
  Result := ScaleValue(Max(8, DaisyFieldPaddingX(SizeKind) * 3 div 4));
end;

function TDaisyCustomTextEdit.TopOffset: Integer;
begin
  Result := 0;
  if FLegend <> '' then
    Inc(Result, ScaleValue(24));
  if (FLabelMode = ilmFloating) and (FLabelText <> '') then
    Inc(Result, ScaleValue(8));
end;

function TDaisyCustomTextEdit.HintArea: Integer;
begin
  if FHelperText <> '' then
    Result := ScaleValue(26)
  else
    Result := 0;
end;

procedure TDaisyCustomTextEdit.IconsChanged;
begin
  Invalidate;
end;

{ Properties }

function TDaisyCustomTextEdit.GetModelText: string;
begin
  Result := StringReplace(FModel.Text, #10, sLineBreak, [rfReplaceAll]);
end;

procedure TDaisyCustomTextEdit.SetModelText(const Value: string);
begin
  if GetModelText = Value then
    Exit;
  FModel.MultiLine := IsMultiLine;
  FModel.Text := Value;
  FModel.Caret := Length(FModel.Text);
  FScrollPos := 0;
  FTopLine := 0;
  FLayoutDirty := True;
  if not (csLoading in ComponentState) then
    Edited
  else
    Invalidate;
end;

procedure TDaisyCustomTextEdit.SetPlaceholder(const Value: string);
begin
  if FPlaceholder <> Value then
  begin
    FPlaceholder := Value;
    Invalidate;
  end;
end;

procedure TDaisyCustomTextEdit.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    Invalidate;
  end;
end;

procedure TDaisyCustomTextEdit.SetLegend(const Value: string);
begin
  if FLegend <> Value then
  begin
    FLegend := Value;
    SizeChanged;
    Invalidate;
  end;
end;

procedure TDaisyCustomTextEdit.SetHelperText(const Value: string);
begin
  if FHelperText <> Value then
  begin
    FHelperText := Value;
    SizeChanged;
    Invalidate;
  end;
end;

procedure TDaisyCustomTextEdit.SetLabelText(const Value: string);
begin
  if FLabelText <> Value then
  begin
    FLabelText := Value;
    FLayoutDirty := True;
    SizeChanged;
    Invalidate;
  end;
end;

procedure TDaisyCustomTextEdit.SetLabelMode(const Value: TDaisyInputLabelMode);
begin
  if FLabelMode <> Value then
  begin
    FLabelMode := Value;
    FLayoutDirty := True;
    SizeChanged;
    Invalidate;
  end;
end;

function TDaisyCustomTextEdit.GetMaxLength: Integer;
begin
  Result := FModel.MaxLength;
end;

procedure TDaisyCustomTextEdit.SetMaxLength(const Value: Integer);
begin
  FModel.MaxLength := Max(0, Value);
end;

function TDaisyCustomTextEdit.GetSelStart: Integer;
begin
  Result := FModel.SelStart;
end;

procedure TDaisyCustomTextEdit.SetSelStart(const Value: Integer);
begin
  FModel.SetCaretPos(Value, False);
  CaretMoved;
end;

function TDaisyCustomTextEdit.GetSelLength: Integer;
begin
  Result := FModel.SelEnd - FModel.SelStart;
end;

procedure TDaisyCustomTextEdit.SetSelLength(const Value: Integer);
var
  LStart: Integer;
begin
  LStart := FModel.SelStart;
  FModel.SetCaretPos(LStart, False);
  FModel.SetCaretPos(LStart + Max(0, Value), True);
  CaretMoved;
end;

function TDaisyCustomTextEdit.GetSelText: string;
begin
  Result := FModel.SelectedText;
end;

procedure TDaisyCustomTextEdit.Loaded;
begin
  inherited;
  FModel.MultiLine := IsMultiLine;
  FLayoutDirty := True;
end;

procedure TDaisyCustomTextEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FLayoutDirty := True;
  Invalidate;
end;

procedure TDaisyCustomTextEdit.CMCursorChanged(var Message: TMessage);
begin
  inherited;
end;

procedure TDaisyCustomTextEdit.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTCHARS;
  if IsMultiLine then
    Message.Result := Message.Result or DLGC_WANTALLKEYS;
end;

{ Measuring and layout }

function TDaisyCustomTextEdit.MeasureStr(const AText: string): Single;
var
  LMask: Char;
begin
  if AText = '' then
    Exit(0);
  LMask := PasswordMask;
  if LMask <> #0 then
    Result := FMeasureBmp.Canvas.TextWidth(StringOfChar(LMask, Length(AText)))
  else
    Result := FMeasureBmp.Canvas.TextWidth(AText);
end;

function TDaisyCustomTextEdit.ScrollOffsetPx: Single;
begin
  if (not IsMultiLine) and (FScrollPos > 0) then
    Result := MeasureStr(Copy(FModel.Text, 1, FScrollPos))
  else
    Result := 0;
end;

function TDaisyCustomTextEdit.PosToX(APos: Integer): Single;
var
  LLine: TDaisyTextLine;
begin
  LLine := FModel.Line(FModel.LineOfPos(APos));
  Result := MeasureStr(Copy(FModel.Text, LLine.Start + 1,
    Min(APos, LLine.Start + LLine.Length) - LLine.Start)) - ScrollOffsetPx;
end;

procedure TDaisyCustomTextEdit.DoLayout(AWidth: Integer);
begin
  FModel.MultiLine := IsMultiLine;
  FModel.Layout(AWidth, IsMultiLine, FMeasureFn);
  FLayoutWidth := AWidth;
  FLayoutDirty := False;
end;

procedure TDaisyCustomTextEdit.ComputeGeometry;
var
  LPad, LIcon, LGap, LTop, LMid, LLabelW, LLeft, LRight, LWidth, LThumbH: Integer;
  LStart, LEnd: TDaisyIconSource;
  LKey: string;
begin
  FFontSize := DaisyFontSize(SizeKind);
  FSmallSize := DaisyFontSize(dzSM);
  LKey := Font.Name + '|' + IntToStr(ScaleValue(FFontSize));
  FMeasureBmp.Canvas.Font.Assign(Font);
  FMeasureBmp.Canvas.Font.Height := -ScaleValue(FFontSize);
  FMeasureBmp.Canvas.Font.Style := [];
  if LKey <> FMeasureKey then
  begin
    FMeasureKey := LKey;
    FLayoutDirty := True;
  end;

  LPad := PadX;
  LGap := ScaleValue(8);
  LTop := TopOffset;
  FLegendRect := Rect(0, 0, 0, 0);
  FHintRect := Rect(0, 0, 0, 0);
  if FLegend <> '' then
    FLegendRect := Rect(0, 0, Width, ScaleValue(20));
  FField := Rect(0, LTop, Width, Max(LTop + ScaleValue(16), Height - HintArea));
  if FHelperText <> '' then
    FHintRect := Rect(0, FField.Bottom + ScaleValue(4), Width, FField.Bottom + ScaleValue(22));
  FLineH := ScaleValue(Round(FFontSize * 1.5));
  LMid := (FField.Top + FField.Bottom) div 2;
  LIcon := ScaleValue(FFontSize + 4);

  LLeft := FField.Left + LPad;
  LRight := FField.Right - LPad;
  FStartBox := Rect(0, 0, 0, 0);
  FEndBox := Rect(0, 0, 0, 0);
  LStart := StartIconSource;
  LEnd := EndIconSource;
  if (LStart <> nil) and not LStart.IsEmpty then
  begin
    FStartBox := Rect(LLeft, LMid - LIcon div 2, LLeft + LIcon, LMid - LIcon div 2 + LIcon);
    LLeft := FStartBox.Right + LGap;
  end;
  if (LEnd <> nil) and not LEnd.IsEmpty then
  begin
    FEndBox := Rect(LRight - LIcon, LMid - LIcon div 2, LRight, LMid - LIcon div 2 + LIcon);
    LRight := FEndBox.Left - LGap;
  end;

  FLabelBox := Rect(0, 0, 0, 0);
  FDivX := -1;
  if (FLabelText <> '') and (FLabelMode in [ilmBefore, ilmAfter]) then
  begin
    FMeasureBmp.Canvas.Font.Height := -ScaleValue(FSmallSize);
    LLabelW := FMeasureBmp.Canvas.TextWidth(FLabelText) + ScaleValue(3);
    FMeasureBmp.Canvas.Font.Height := -ScaleValue(FFontSize);
    if FLabelMode = ilmBefore then
    begin
      FLabelBox := Rect(LLeft, FField.Top, LLeft + LLabelW, FField.Bottom);
      FDivX := FLabelBox.Right + LPad div 2;
      LLeft := FDivX + LPad div 2 + 1;
    end
    else
    begin
      FLabelBox := Rect(LRight - LLabelW, FField.Top, LRight, FField.Bottom);
      FDivX := FLabelBox.Left - LPad div 2;
      LRight := FDivX - LPad div 2;
    end;
  end;

  FChip := Rect(0, 0, 0, 0);
  if (FLabelMode = ilmFloating) and (FLabelText <> '') then
    FChip := Rect(FField.Left + LPad - ScaleValue(4), FField.Top - ScaleValue(8), 0,
      FField.Top + ScaleValue(8));

  if IsMultiLine then
  begin
    FTextBox := Rect(LLeft, FField.Top + ScaleValue(8), LRight, FField.Bottom - ScaleValue(8));
    FRows := Max(1, FTextBox.Height div FLineH);
    LWidth := Max(1, FTextBox.Width - IfThen(FHasBar, ScaleValue(CBarWidth), 0));
    if FLayoutDirty or (FLayoutWidth <> LWidth) then
      DoLayout(LWidth);
    if (FModel.LineCount > FRows) <> FHasBar then
    begin
      FHasBar := not FHasBar;
      LWidth := Max(1, FTextBox.Width - IfThen(FHasBar, ScaleValue(CBarWidth), 0));
      DoLayout(LWidth);
    end;
    if FHasBar then
      Dec(FTextBox.Right, ScaleValue(CBarWidth));
    FTopLine := EnsureRange(FTopLine, 0, Max(0, FModel.LineCount - FRows));
    FTrack := Rect(FField.Right - ScaleValue(CBarWidth) + 2, FField.Top + ScaleValue(6),
      FField.Right - 2, FField.Bottom - ScaleValue(6));
    FThumb := Rect(0, 0, 0, 0);
    if FHasBar then
    begin
      LThumbH := Max(ScaleValue(20), Round(FTrack.Height * FRows / Max(1, FModel.LineCount)));
      FThumb.Left := FTrack.Left;
      FThumb.Right := FTrack.Right;
      FThumb.Top := FTrack.Top;
      if FModel.LineCount > FRows then
        FThumb.Top := FTrack.Top + Round((FTrack.Height - LThumbH) * FTopLine / (FModel.LineCount - FRows));
      FThumb.Bottom := FThumb.Top + LThumbH;
    end;
  end
  else
  begin
    FRows := 1;
    FTextBox := Rect(LLeft, LMid - FLineH div 2, LRight, LMid - FLineH div 2 + FLineH);
    if FLayoutDirty then
      DoLayout(0);
  end;
  if (FLabelMode = ilmFloating) and (FLabelText <> '') then
    FChip.Right := FChip.Left + Round(FMeasureBmp.Canvas.TextWidth(FLabelText) * FSmallSize
      / Max(1, FFontSize)) + ScaleValue(8);
end;

procedure TDaisyCustomTextEdit.EnsureGeometry;
begin
  ComputeGeometry;
end;

procedure TDaisyCustomTextEdit.ModelChanged;
begin
  FLayoutDirty := True;
  Invalidate;
end;

{ Caret, scrolling, blinking }

procedure TDaisyCustomTextEdit.CaretMoved(AKeepDesiredX: Boolean);
var
  LCaret, LLine: Integer;
  LText: string;
begin
  if not AKeepDesiredX then
    FDesiredX := -1;
  ComputeGeometry;
  LCaret := FModel.Caret;
  LText := FModel.Text;
  if IsMultiLine then
  begin
    LLine := FModel.LineOfPos(LCaret);
    if LLine < FTopLine then
      FTopLine := LLine
    else if LLine >= FTopLine + FRows then
      FTopLine := LLine - FRows + 1;
    FTopLine := EnsureRange(FTopLine, 0, Max(0, FModel.LineCount - FRows));
  end
  else
  begin
    if FScrollPos > LCaret then
      FScrollPos := LCaret;
    while (FScrollPos < LCaret) and
      (MeasureStr(Copy(LText, FScrollPos + 1, LCaret - FScrollPos)) > FTextBox.Width - 2) do
      FScrollPos := FModel.NextBoundary(FScrollPos);
    // pull the text back when there is room, e.g. after a deletion
    while (FScrollPos > 0) and
      (MeasureStr(Copy(LText, FModel.PrevBoundary(FScrollPos) + 1, MaxInt)) <= FTextBox.Width - 2) do
      FScrollPos := FModel.PrevBoundary(FScrollPos);
    FScrollPos := Min(FScrollPos, Length(LText));
  end;
  ResetBlink;
  Invalidate;
end;

procedure TDaisyCustomTextEdit.Edited;
begin
  FLayoutDirty := True;
  CaretMoved;
  if not (csLoading in ComponentState) then
  begin
    TextEdited;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TDaisyCustomTextEdit.TextEdited;
begin
end;

function TDaisyCustomTextEdit.FieldRect: TRect;
begin
  ComputeGeometry;
  Result := FField;
end;

function TDaisyCustomTextEdit.EndIconRect: TRect;
begin
  ComputeGeometry;
  Result := FEndBox;
end;

procedure TDaisyCustomTextEdit.ResetBlink;
begin
  FBlinkOrigin := DaisyAnimationClock.Time;
  FBlinkOn := True;
end;

procedure TDaisyCustomTextEdit.StartTicking;
begin
  if (not FTicking) and not (csDesigning in ComponentState) then
  begin
    FTicking := True;
    DaisyAnimationClock.AddListener(Tick);
  end;
end;

procedure TDaisyCustomTextEdit.StopTicking;
begin
  if FTicking then
  begin
    FTicking := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisyCustomTextEdit.Tick(Sender: TObject);
var
  LOn: Boolean;
begin
  LOn := Odd(Floor((DaisyAnimationClock.Time - FBlinkOrigin) / CBlinkSeconds)) = False;
  if LOn <> FBlinkOn then
  begin
    FBlinkOn := LOn;
    Invalidate;
  end;
end;

procedure TDaisyCustomTextEdit.DoEnter;
begin
  inherited DoEnter;
  ResetBlink;
  StartTicking;
  Invalidate;
end;

procedure TDaisyCustomTextEdit.DoExit;
begin
  StopTicking;
  FDragging := False;
  FBarDrag := False;
  FModel.BreakUndo;
  inherited DoExit;
  Invalidate;
end;

{ Clipboard and editing commands }

procedure TDaisyCustomTextEdit.SelectAll;
begin
  FModel.SelectAll;
  CaretMoved;
end;

procedure TDaisyCustomTextEdit.CopyToClipboard;
begin
  if FModel.HasSelection and (PasswordMask = #0) then
    try
      Clipboard.AsText := StringReplace(FModel.SelectedText, #10, sLineBreak, [rfReplaceAll]);
    except
      // the clipboard can be busy; copying is best effort
    end;
end;

procedure TDaisyCustomTextEdit.CutToClipboard;
begin
  if FReadOnly or (PasswordMask <> #0) then
    Exit;
  CopyToClipboard;
  if FModel.DeleteSelection then
    Edited;
end;

procedure TDaisyCustomTextEdit.PasteFromClipboard;
var
  LText: string;
begin
  if FReadOnly then
    Exit;
  try
    LText := Clipboard.AsText;
  except
    LText := '';
  end;
  if (LText <> '') and FModel.InsertText(LText) then
  begin
    FModel.BreakUndo;
    Edited;
  end;
end;

procedure TDaisyCustomTextEdit.Undo;
begin
  if (not FReadOnly) and FModel.Undo then
    Edited;
end;

procedure TDaisyCustomTextEdit.Redo;
begin
  if (not FReadOnly) and FModel.Redo then
    Edited;
end;

procedure TDaisyCustomTextEdit.Clear;
begin
  SetModelText('');
end;

procedure TDaisyCustomTextEdit.MoveVertical(ALines: Integer; AExtend: Boolean);
var
  LLine, LTarget: Integer;
begin
  ComputeGeometry;
  if FDesiredX < 0 then
    FDesiredX := PosToX(FModel.Caret);
  LLine := FModel.LineOfPos(FModel.Caret);
  LTarget := LLine + ALines;
  if LTarget < 0 then
    FModel.SetCaretPos(0, AExtend)
  else if LTarget >= FModel.LineCount then
    FModel.SetCaretPos(Length(FModel.Text), AExtend)
  else
    FModel.SetCaretPos(FModel.PosAtX(LTarget, FDesiredX, FMeasureFn), AExtend);
  CaretMoved(True);
end;

{ Keyboard }

procedure TDaisyCustomTextEdit.KeyDown(var Key: Word; Shift: TShiftState);
var
  LExtend, LCtrl: Boolean;
  LMove: TDaisyTextMove;
begin
  inherited KeyDown(Key, Shift);
  if Key = 0 then
    Exit;
  LExtend := ssShift in Shift;
  LCtrl := ssCtrl in Shift;
  ComputeGeometry;
  case Key of
    VK_LEFT, VK_RIGHT, VK_HOME, VK_END:
      begin
        case Key of
          VK_LEFT: if LCtrl then LMove := tmWordLeft else LMove := tmLeft;
          VK_RIGHT: if LCtrl then LMove := tmWordRight else LMove := tmRight;
          VK_HOME: if LCtrl then LMove := tmDocStart else LMove := tmLineStart;
        else
          if LCtrl then LMove := tmDocEnd else LMove := tmLineEnd;
        end;
        FModel.MoveCaret(LMove, LExtend);
        CaretMoved;
      end;
    VK_UP:
      if IsMultiLine then
        MoveVertical(-1, LExtend)
      else
      begin
        FModel.MoveCaret(tmDocStart, LExtend);
        CaretMoved;
      end;
    VK_DOWN:
      if IsMultiLine then
        MoveVertical(1, LExtend)
      else
      begin
        FModel.MoveCaret(tmDocEnd, LExtend);
        CaretMoved;
      end;
    VK_PRIOR:
      if IsMultiLine then
        MoveVertical(-FRows, LExtend)
      else
        Exit;
    VK_NEXT:
      if IsMultiLine then
        MoveVertical(FRows, LExtend)
      else
        Exit;
    VK_BACK:
      if not FReadOnly then
      begin
        if FModel.DeleteBackward(LCtrl) then
          Edited;
      end;
    VK_DELETE:
      if ssShift in Shift then
        CutToClipboard
      else if not FReadOnly then
      begin
        if FModel.DeleteForward(LCtrl) then
          Edited;
      end;
    VK_INSERT:
      if LCtrl then
        CopyToClipboard
      else if LExtend then
        PasteFromClipboard
      else
        Exit;
    VK_RETURN:
      if IsMultiLine and not FReadOnly then
      begin
        if FModel.InsertText(#10) then
          Edited;
      end
      else
        Exit;
    Ord('A'):
      if LCtrl then
        SelectAll
      else
        Exit;
    Ord('C'):
      if LCtrl then
        CopyToClipboard
      else
        Exit;
    Ord('X'):
      if LCtrl then
        CutToClipboard
      else
        Exit;
    Ord('V'):
      if LCtrl then
        PasteFromClipboard
      else
        Exit;
    Ord('Z'):
      if LCtrl and LExtend then
        Redo
      else if LCtrl then
        Undo
      else
        Exit;
    Ord('Y'):
      if LCtrl then
        Redo
      else
        Exit;
  else
    Exit;
  end;
  Key := 0;
end;

procedure TDaisyCustomTextEdit.KeyPress(var Key: Char);
var
  LText: string;
begin
  inherited KeyPress(Key);
  if Key = #0 then
    Exit;
  if FReadOnly or (not Enabled) then
  begin
    Key := #0;
    Exit;
  end;
  if (Key >= #$D800) and (Key <= #$DBFF) then
  begin
    FPendingHigh := Key; // first half of a surrogate pair (emoji): wait for the second
    Key := #0;
    Exit;
  end;
  if (Key >= #$DC00) and (Key <= #$DFFF) then
  begin
    if FPendingHigh <> #0 then
    begin
      LText := FPendingHigh + Key;
      if FModel.InsertText(LText) then
        Edited;
    end;
    FPendingHigh := #0;
    Key := #0;
    Exit;
  end;
  FPendingHigh := #0;
  if (Key >= #32) and (Key <> #127) then
    if FModel.InsertText(Key) then
      Edited;
  Key := #0;
end;

{ Mouse }

function TDaisyCustomTextEdit.PosFromPoint(X, Y: Integer): Integer;
var
  LLine: Integer;
begin
  if IsMultiLine then
  begin
    LLine := EnsureRange(FTopLine + Floor((Y - FTextBox.Top) / Max(1, FLineH)), 0,
      Max(0, FModel.LineCount - 1));
    Result := FModel.PosAtX(LLine, X - FTextBox.Left, FMeasureFn);
  end
  else
    Result := FModel.PosAtX(0, X - FTextBox.Left + ScrollOffsetPx, FMeasureFn);
end;

procedure TDaisyCustomTextEdit.ScrollBarTo(Y: Integer);
var
  LRange, LThumbH: Integer;
begin
  LThumbH := FThumb.Height;
  LRange := FTrack.Height - LThumbH;
  if (LRange <= 0) or (FModel.LineCount <= FRows) then
    Exit;
  FTopLine := EnsureRange(Round((Y - FBarGrab - FTrack.Top) / LRange * (FModel.LineCount - FRows)), 0,
    FModel.LineCount - FRows);
  Invalidate;
end;

procedure TDaisyCustomTextEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  if CanFocus and not Focused then
    SetFocus;
  ComputeGeometry;
  if IsMultiLine and FHasBar and (X >= FTextBox.Right) then
  begin
    FBarDrag := True;
    if PtInRect(FThumb, Point(X, Y)) then
      FBarGrab := Y - FThumb.Top
    else
    begin
      FBarGrab := FThumb.Height div 2;
      ScrollBarTo(Y);
    end;
    Exit;
  end;
  if ssDouble in Shift then
  begin
    FModel.SelectWordAt(PosFromPoint(X, Y));
    FDragging := False;
  end
  else
  begin
    FModel.SetCaretPos(PosFromPoint(X, Y), ssShift in Shift);
    FDragging := True;
  end;
  CaretMoved;
end;

procedure TDaisyCustomTextEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FBarDrag then
    ScrollBarTo(Y)
  else if FDragging and (ssLeft in Shift) then
  begin
    ComputeGeometry;
    FModel.SetCaretPos(PosFromPoint(X, Y), True);
    CaretMoved;
  end;
end;

procedure TDaisyCustomTextEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
  FBarDrag := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

function TDaisyCustomTextEdit.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result or (not IsMultiLine) then
    Exit;
  ComputeGeometry;
  if FModel.LineCount > FRows then
  begin
    FTopLine := EnsureRange(FTopLine - Sign(WheelDelta) * 3, 0, FModel.LineCount - FRows);
    Invalidate;
    Result := True;
  end;
end;

{ Painting }

procedure TDaisyCustomTextEdit.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LTint, LBorder, LFill, LText, LDim: TAlphaColor;
  LPalette: TDaisyPalette;
  LRadius, LBorderW, I, LLineIdx, LFirst, LS1, LS2, LCaretX: Integer;
  LBordered, LActive, LFloatUp: Boolean;
  LLine: TDaisyTextLine;
  LRow, LSel, LCaretRect: TRect;
  LShown, LMask: string;
  LMaskCh: Char;
  LX1, LX2: Single;
  LFlags: Cardinal;
begin
  ComputeGeometry;
  LRadius := ResolvedCornerRadius;
  LActive := Focused;
  LBorderW := Max(1, ScaleValue(Theme.BorderWidth));

  if Variant = dvDefault then
    LTint := Theme.BaseContent
  else
  begin
    LPalette := DaisyVariantPalette(Theme, Variant);
    LTint := LPalette.Fill;
  end;

  LBordered := Style in [dsSolid, dsOutline, dsDash];
  if Variant = dvDefault then
    LBorder := DaisyWithAlpha(Theme.BaseContent, 0.2)
  else
    LBorder := LTint;
  if LActive then
    LBorder := DaisyMix(LBorder, Theme.BaseContent, 0.3); // a deeper shade, never a thicker line
  if LActive and (Variant = dvDefault) then
    LBorder := DaisyWithAlpha(Theme.BaseContent, 0.5);
  case Style of
    dsGhost: LFill := TAlphaColors.Null;
    dsSoft:
      if Variant = dvDefault then
        LFill := Theme.Base200
      else
        LFill := DaisyMix(Theme.Base100, LTint, 0.1);
  else
    LFill := Theme.Base100;
  end;
  if (Style = dsGhost) and LActive then
    LFill := Theme.Base100;
  LText := Theme.BaseContent;
  if not Enabled then
  begin
    LBorder := DaisyWithAlpha(Theme.BaseContent, 0.1);
    LFill := DaisyWithAlpha(Theme.BaseContent, 0.05);
    LText := DaisyWithAlpha(Theme.BaseContent, 0.3);
  end;
  LDim := DaisyWithAlpha(LText, 0.5);
  LFloatUp := (FLabelMode = ilmFloating) and (FLabelText <> '') and
    (LActive or (FModel.Text <> '') or (FPlaceholder <> ''));
  LFlags := DT_LEFT or DT_VCENTER or DT_SINGLELINE;

  LGraphics := NewGraphics;
  try
    if TAlphaColorRec(LFill).A > 0 then
      FillRoundRect(LGraphics, TRectF.Create(FField), LRadius, LFill);
    if LBordered or LActive then
      StrokeRoundRect(LGraphics, TRectF.Create(FField), LRadius, LBorder, LBorderW,
        (Style = dsDash) and not LActive);
    if FDivX >= 0 then
      FillRoundRect(LGraphics, RectF(FDivX, FField.Top + FField.Height / 4, FDivX + 1,
        FField.Bottom - FField.Height / 4), 0, DaisyWithAlpha(Theme.BaseContent, 0.2));
    if LFloatUp then
      FillRoundRect(LGraphics, TRectF.Create(FChip), 0, Theme.Base100);

    // selection
    if FModel.HasSelection then
      for I := 0 to FRows - 1 do
      begin
        if IsMultiLine then
          LLineIdx := FTopLine + I
        else
          LLineIdx := 0;
        if LLineIdx >= FModel.LineCount then
          Break;
        LLine := FModel.Line(LLineIdx);
        LS1 := Max(FModel.SelStart, LLine.Start);
        LS2 := Min(FModel.SelEnd, LLine.Start + LLine.Length);
        if (LS2 <= LS1) and not ((FModel.SelEnd > LLine.Start + LLine.Length) and
          (FModel.SelStart <= LLine.Start + LLine.Length) and (LLineIdx < FModel.LineCount - 1)
          and IsMultiLine) then
          Continue;
        LX1 := FTextBox.Left + PosToX(Max(LS1, LLine.Start));
        LX2 := FTextBox.Left + PosToX(Max(LS2, LLine.Start));
        if (FModel.SelEnd > LLine.Start + LLine.Length) and IsMultiLine then
          LX2 := LX2 + ScaleValue(4);
        LX1 := Max(LX1, FTextBox.Left);
        LX2 := Min(LX2, FTextBox.Right);
        if LX2 > LX1 then
        begin
          if IsMultiLine then
            LRow := Rect(0, FTextBox.Top + I * FLineH, 0, FTextBox.Top + (I + 1) * FLineH)
          else
            LRow := FTextBox;
          FillRoundRect(LGraphics, RectF(LX1, LRow.Top, LX2, LRow.Bottom), 2,
            DaisyWithAlpha(Theme.Primary, IfThen(Enabled, 0.3, 0.12)));
        end;
      end;

    // scroll bar
    if IsMultiLine and FHasBar then
    begin
      FillRoundRect(LGraphics, TRectF.Create(FTrack), FTrack.Width / 2,
        DaisyWithAlpha(Theme.BaseContent, 0.06));
      FillRoundRect(LGraphics, TRectF.Create(FThumb), FThumb.Width / 2,
        DaisyWithAlpha(Theme.BaseContent, 0.3));
    end;
  finally
    LGraphics.Free; // flush before any GDI text
  end;

  if FLegend <> '' then
    DrawRichText(FLegend, FLegendRect, Theme.BaseContent, FSmallSize, True,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
  if FHelperText <> '' then
    DrawRichText(FHelperText, FHintRect, DaisyWithAlpha(Theme.BaseContent, 0.6), DaisyFontSize(dzXS),
      False, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
  if (FLabelText <> '') and (FLabelMode in [ilmBefore, ilmAfter]) then
    DrawRichText(FLabelText, FLabelBox, LDim, FSmallSize, False, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  if LFloatUp then
    DrawRichText(FLabelText, FChip, LDim, FSmallSize, False, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

  DrawGlyph(StartIconSource, FStartBox, LDim);
  DrawGlyph(EndIconSource, FEndBox, LDim);

  // text
  LMaskCh := PasswordMask;
  if FModel.Text = '' then
  begin
    if (FLabelMode = ilmFloating) and (FLabelText <> '') and not LFloatUp then
      DrawRichText(FLabelText, FTextBox, LDim, FFontSize, False, LFlags)
    else if FPlaceholder <> '' then
      DrawRichText(FPlaceholder, FTextBox, LDim, FFontSize, False, LFlags);
  end
  else if IsMultiLine then
  begin
    for I := 0 to FRows - 1 do
    begin
      LLineIdx := FTopLine + I;
      if LLineIdx >= FModel.LineCount then
        Break;
      LRow := Rect(FTextBox.Left, FTextBox.Top + I * FLineH, FTextBox.Right,
        FTextBox.Top + (I + 1) * FLineH);
      DrawRichText(FModel.LineText(LLineIdx), LRow, LText, FFontSize, False, LFlags);
    end;
  end
  else
  begin
    LFirst := FScrollPos;
    LShown := Copy(FModel.Text, LFirst + 1, MaxInt);
    if LMaskCh <> #0 then
    begin
      LMask := StringOfChar(LMaskCh, Length(LShown));
      LShown := LMask;
    end;
    DrawRichText(LShown, FTextBox, LText, FFontSize, False, LFlags);
  end;

  // caret
  if LActive and FBlinkOn and Enabled then
  begin
    LCaretX := FTextBox.Left + Round(PosToX(FModel.Caret));
    if IsMultiLine then
    begin
      I := FModel.LineOfPos(FModel.Caret) - FTopLine;
      if (I >= 0) and (I < FRows) then
        LCaretRect := Rect(LCaretX, FTextBox.Top + I * FLineH + 2, LCaretX + Max(1, ScaleValue(1)),
          FTextBox.Top + (I + 1) * FLineH - 2)
      else
        LCaretRect := Rect(0, 0, 0, 0);
    end
    else
      LCaretRect := Rect(LCaretX, FTextBox.Top + 2, LCaretX + Max(1, ScaleValue(1)), FTextBox.Bottom - 2);
    if (LCaretRect.Right > LCaretRect.Left) and (LCaretX >= FTextBox.Left) and (LCaretX <= FTextBox.Right) then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := DaisyToColor(Theme.BaseContent);
      Canvas.FillRect(MirrorRect(LCaretRect));
    end;
  end;
  LSel := Rect(0, 0, 0, 0);
end;

{ TDaisyTextInput }

constructor TDaisyTextInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStartIcon := TDaisyIconSource.Create(IconChanged);
  FEndIcon := TDaisyIconSource.Create(IconChanged);
  FAutoFit := True;
  SetBounds(Left, Top, 192, ScaleValue(DaisyFieldHeight(dzMD)));
  UpdateSize;
end;

destructor TDaisyTextInput.Destroy;
begin
  FEndIcon.Free;
  FStartIcon.Free;
  inherited Destroy;
end;

function TDaisyTextInput.PasswordMask: Char;
begin
  Result := FPasswordChar;
end;

function TDaisyTextInput.StartIconSource: TDaisyIconSource;
begin
  Result := FStartIcon;
end;

function TDaisyTextInput.EndIconSource: TDaisyIconSource;
begin
  Result := FEndIcon;
end;

procedure TDaisyTextInput.SetPasswordChar(const Value: Char);
begin
  if FPasswordChar <> Value then
  begin
    FPasswordChar := Value;
    ModelChanged;
  end;
end;

procedure TDaisyTextInput.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

function TDaisyTextInput.GetStartEmoji: string;
begin
  Result := FStartIcon.Emoji;
end;

procedure TDaisyTextInput.SetStartEmoji(const Value: string);
begin
  FStartIcon.Emoji := Value;
end;

function TDaisyTextInput.GetStartSVG: TStrings;
begin
  Result := FStartIcon.SVG;
end;

procedure TDaisyTextInput.SetStartSVG(const Value: TStrings);
begin
  FStartIcon.SVG := Value;
end;

function TDaisyTextInput.GetEndEmoji: string;
begin
  Result := FEndIcon.Emoji;
end;

procedure TDaisyTextInput.SetEndEmoji(const Value: string);
begin
  FEndIcon.Emoji := Value;
end;

function TDaisyTextInput.GetEndSVG: TStrings;
begin
  Result := FEndIcon.SVG;
end;

procedure TDaisyTextInput.SetEndSVG(const Value: TStrings);
begin
  FEndIcon.SVG := Value;
end;

procedure TDaisyTextInput.IconChanged(Sender: TObject);
begin
  ModelChanged;
end;

procedure TDaisyTextInput.UpdateSize;
var
  LHeight: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := TopOffset + ScaleValue(DaisyFieldHeight(SizeKind)) + HintArea;
  if LHeight = Height then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyTextInput.SizeChanged;
begin
  UpdateSize;
  ModelChanged;
end;

procedure TDaisyTextInput.Loaded;
begin
  inherited;
  UpdateSize;
end;

end.
