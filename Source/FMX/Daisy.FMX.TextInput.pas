unit Daisy.FMX.TextInput;

{
  TDaisyFmxCustomTextEdit - the editing engine shared by TDaisyFmxTextInput and
  TDaisyFmxTextArea (see Daisy.FMX.TextArea).

  The control paints and edits its own text: caret, selection, clipboard, undo,
  word / line navigation and mouse selection come from Daisy.TextEdit. Colour
  emoji come from the platform text layout. The focused state only darkens the
  border - it never gets thicker.

  TDaisyFmxTextInput - the DaisyUI "input": a single line with variants, sizes,
  ghost / soft styles, SVG or emoji icons at either end, a before / after /
  floating label, a fieldset legend and helper text.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math, System.Rtti,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Platform, Daisy.Theme, Daisy.Widgets,
  Daisy.Animation, Daisy.TextEdit, Daisy.FMX.Control;

type
  TDaisyFmxCustomTextEdit = class(TDaisyControl)
  strict private
    FModel: TDaisyTextModel;
    FMeasureFn: TDaisyMeasureFunc;
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
    FPendingHigh: WideChar;
    FDragging: Boolean;
    FBarDrag: Boolean;
    FBarGrab: Single;
    FBlinkOrigin: Double;
    FBlinkOn: Boolean;
    FTicking: Boolean;
    FField, FTextBox, FStartBox, FEndBox, FLegendRect, FHintRect, FLabelBox, FChip: TRectF;
    FTrack, FThumb: TRectF;
    FDivX: Single;
    FLineH: Single;
    FRows: Integer;
    FFontSize, FSmallSize: Integer;
    FHasBar: Boolean;
    function GetModelText: string;
    procedure SetModelText(const Value: string);
    procedure SetPlaceholder(const Value: string);
    procedure SetReadOnly(const Value: Boolean);
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
    function PosFromPoint(X, Y: Single): Integer;
    procedure DoLayout(AWidth: Integer);
    procedure ComputeGeometry;
    procedure Edited;
    procedure CaretMoved(AKeepDesiredX: Boolean = False);
    procedure ResetBlink;
    procedure Tick(Sender: TObject);
    procedure StartTicking;
    procedure StopTicking;
    procedure ScrollBarTo(Y: Single);
    procedure MoveVertical(ALines: Integer; AExtend: Boolean);
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure Loaded; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;

    // Hooks for TDaisyFmxTextInput / TDaisyFmxTextArea
    function IsMultiLine: Boolean; virtual;
    function PasswordMask: Char; virtual;
    function StartIconSource: TDaisyIconSource; virtual;
    function EndIconSource: TDaisyIconSource; virtual;
    function PadX: Single;
    // The field's rectangle and the end icon's rectangle, in local coordinates
    function FieldRect: TRectF;
    function EndIconRect: TRectF;
    // Called when the text changed through typing, pasting or Text, but not while loading
    procedure TextEdited; virtual;
    // Space above the field (legend and floating label) and below it (helper text)
    function TopOffset: Single;
    function HintArea: Single;
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
  end;

  TDaisyFmxTextInput = class(TDaisyFmxCustomTextEdit)
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
  CBarWidth = 8;

{ TDaisyFmxCustomTextEdit }

constructor TDaisyFmxCustomTextEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FModel := TDaisyTextModel.Create;
  FMeasureFn := function(const AText: string): Single
    begin
      Result := MeasureStr(AText);
    end;
  FLayoutDirty := True;
  FDesiredX := -1;
  FBlinkOn := True;
  CanFocus := True;
  TabStop := True;
  Cursor := crIBeam;
end;

destructor TDaisyFmxCustomTextEdit.Destroy;
begin
  StopTicking;
  FModel.Free;
  inherited Destroy;
end;

function TDaisyFmxCustomTextEdit.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxCustomTextEdit.DrawsFocusRing: Boolean;
begin
  Result := False; // the border shows the focus, only darker
end;

function TDaisyFmxCustomTextEdit.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyFmxCustomTextEdit.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxCustomTextEdit.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxCustomTextEdit.IsMultiLine: Boolean;
begin
  Result := False;
end;

function TDaisyFmxCustomTextEdit.PasswordMask: Char;
begin
  Result := #0;
end;

function TDaisyFmxCustomTextEdit.StartIconSource: TDaisyIconSource;
begin
  Result := nil;
end;

function TDaisyFmxCustomTextEdit.EndIconSource: TDaisyIconSource;
begin
  Result := nil;
end;

function TDaisyFmxCustomTextEdit.PadX: Single;
begin
  Result := Max(8, DaisyFieldPaddingX(SizeKind) * 3 div 4);
end;

function TDaisyFmxCustomTextEdit.TopOffset: Single;
begin
  Result := 0;
  if FLegend <> '' then
    Result := Result + 24;
  if (FLabelMode = ilmFloating) and (FLabelText <> '') then
    Result := Result + 8;
end;

function TDaisyFmxCustomTextEdit.HintArea: Single;
begin
  if FHelperText <> '' then
    Result := 26
  else
    Result := 0;
end;

{ Properties }

function TDaisyFmxCustomTextEdit.GetModelText: string;
begin
  Result := StringReplace(FModel.Text, #10, sLineBreak, [rfReplaceAll]);
end;

procedure TDaisyFmxCustomTextEdit.SetModelText(const Value: string);
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
    Repaint;
end;

procedure TDaisyFmxCustomTextEdit.SetPlaceholder(const Value: string);
begin
  if FPlaceholder <> Value then
  begin
    FPlaceholder := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxCustomTextEdit.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxCustomTextEdit.SetLegend(const Value: string);
begin
  if FLegend <> Value then
  begin
    FLegend := Value;
    SizeChanged;
    Repaint;
  end;
end;

procedure TDaisyFmxCustomTextEdit.SetHelperText(const Value: string);
begin
  if FHelperText <> Value then
  begin
    FHelperText := Value;
    SizeChanged;
    Repaint;
  end;
end;

procedure TDaisyFmxCustomTextEdit.SetLabelText(const Value: string);
begin
  if FLabelText <> Value then
  begin
    FLabelText := Value;
    FLayoutDirty := True;
    SizeChanged;
    Repaint;
  end;
end;

procedure TDaisyFmxCustomTextEdit.SetLabelMode(const Value: TDaisyInputLabelMode);
begin
  if FLabelMode <> Value then
  begin
    FLabelMode := Value;
    FLayoutDirty := True;
    SizeChanged;
    Repaint;
  end;
end;

function TDaisyFmxCustomTextEdit.GetMaxLength: Integer;
begin
  Result := FModel.MaxLength;
end;

procedure TDaisyFmxCustomTextEdit.SetMaxLength(const Value: Integer);
begin
  FModel.MaxLength := Max(0, Value);
end;

function TDaisyFmxCustomTextEdit.GetSelStart: Integer;
begin
  Result := FModel.SelStart;
end;

procedure TDaisyFmxCustomTextEdit.SetSelStart(const Value: Integer);
begin
  FModel.SetCaretPos(Value, False);
  CaretMoved;
end;

function TDaisyFmxCustomTextEdit.GetSelLength: Integer;
begin
  Result := FModel.SelEnd - FModel.SelStart;
end;

procedure TDaisyFmxCustomTextEdit.SetSelLength(const Value: Integer);
var
  LStart: Integer;
begin
  LStart := FModel.SelStart;
  FModel.SetCaretPos(LStart, False);
  FModel.SetCaretPos(LStart + Max(0, Value), True);
  CaretMoved;
end;

function TDaisyFmxCustomTextEdit.GetSelText: string;
begin
  Result := FModel.SelectedText;
end;

procedure TDaisyFmxCustomTextEdit.Loaded;
begin
  inherited;
  FModel.MultiLine := IsMultiLine;
  FLayoutDirty := True;
end;

procedure TDaisyFmxCustomTextEdit.ModelChanged;
begin
  FLayoutDirty := True;
  Repaint;
end;

{ Measuring and layout }

function TDaisyFmxCustomTextEdit.MeasureStr(const AText: string): Single;
var
  LMask: Char;
begin
  if AText = '' then
    Exit(0);
  LMask := PasswordMask;
  if LMask <> #0 then
    Result := MeasureTextWidth(StringOfChar(LMask, Length(AText)), FFontSize, False)
  else
    Result := MeasureTextWidth(AText, FFontSize, False);
end;

function TDaisyFmxCustomTextEdit.ScrollOffsetPx: Single;
begin
  if (not IsMultiLine) and (FScrollPos > 0) then
    Result := MeasureStr(Copy(FModel.Text, 1, FScrollPos))
  else
    Result := 0;
end;

function TDaisyFmxCustomTextEdit.PosToX(APos: Integer): Single;
var
  LLine: TDaisyTextLine;
begin
  LLine := FModel.Line(FModel.LineOfPos(APos));
  Result := MeasureStr(Copy(FModel.Text, LLine.Start + 1,
    Min(APos, LLine.Start + LLine.Length) - LLine.Start)) - ScrollOffsetPx;
end;

procedure TDaisyFmxCustomTextEdit.DoLayout(AWidth: Integer);
begin
  FModel.MultiLine := IsMultiLine;
  FModel.Layout(AWidth, IsMultiLine, FMeasureFn);
  FLayoutWidth := AWidth;
  FLayoutDirty := False;
end;

procedure TDaisyFmxCustomTextEdit.ComputeGeometry;
var
  LPad, LIcon, LGap, LTop, LMid, LLabelW, LLeft, LRight, LThumbH: Single;
  LWidth: Integer;
  LStart, LEnd: TDaisyIconSource;
begin
  FFontSize := DaisyFontSize(SizeKind);
  FSmallSize := DaisyFontSize(dzSM);
  LPad := PadX;
  LGap := 8;
  LTop := TopOffset;
  FLegendRect := RectF(0, 0, 0, 0);
  FHintRect := RectF(0, 0, 0, 0);
  if FLegend <> '' then
    FLegendRect := RectF(0, 0, Width, 20);
  FField := RectF(0, LTop, Width, Max(LTop + 16, Height - HintArea));
  if FHelperText <> '' then
    FHintRect := RectF(0, FField.Bottom + 4, Width, FField.Bottom + 22);
  FLineH := Round(FFontSize * 1.5);
  LMid := (FField.Top + FField.Bottom) / 2;
  LIcon := FFontSize + 4;

  LLeft := FField.Left + LPad;
  LRight := FField.Right - LPad;
  FStartBox := RectF(0, 0, 0, 0);
  FEndBox := RectF(0, 0, 0, 0);
  LStart := StartIconSource;
  LEnd := EndIconSource;
  if (LStart <> nil) and not LStart.IsEmpty then
  begin
    FStartBox := RectF(LLeft, LMid - LIcon / 2, LLeft + LIcon, LMid + LIcon / 2);
    LLeft := FStartBox.Right + LGap;
  end;
  if (LEnd <> nil) and not LEnd.IsEmpty then
  begin
    FEndBox := RectF(LRight - LIcon, LMid - LIcon / 2, LRight, LMid + LIcon / 2);
    LRight := FEndBox.Left - LGap;
  end;

  FLabelBox := RectF(0, 0, 0, 0);
  FDivX := -1;
  LLabelW := 0;
  if FLabelText <> '' then
    LLabelW := MeasureTextWidth(FLabelText, FSmallSize, False);
  if (FLabelText <> '') and (FLabelMode in [ilmBefore, ilmAfter]) then
  begin
    if FLabelMode = ilmBefore then
    begin
      FLabelBox := RectF(LLeft, FField.Top, LLeft + LLabelW, FField.Bottom);
      FDivX := FLabelBox.Right + LPad / 2;
      LLeft := FDivX + LPad / 2 + 1;
    end
    else
    begin
      FLabelBox := RectF(LRight - LLabelW, FField.Top, LRight, FField.Bottom);
      FDivX := FLabelBox.Left - LPad / 2;
      LRight := FDivX - LPad / 2;
    end;
  end;

  FChip := RectF(0, 0, 0, 0);
  if (FLabelMode = ilmFloating) and (FLabelText <> '') then
    FChip := RectF(FField.Left + LPad - 4, FField.Top - 8, FField.Left + LPad + LLabelW + 4,
      FField.Top + 8);

  if IsMultiLine then
  begin
    FTextBox := RectF(LLeft, FField.Top + 8, LRight, FField.Bottom - 8);
    FRows := Max(1, Trunc(FTextBox.Height / FLineH));
    LWidth := Max(1, Round(FTextBox.Width - IfThen(FHasBar, CBarWidth + 2, 0)));
    if FLayoutDirty or (FLayoutWidth <> LWidth) then
      DoLayout(LWidth);
    if (FModel.LineCount > FRows) <> FHasBar then
    begin
      FHasBar := not FHasBar;
      LWidth := Max(1, Round(FTextBox.Width - IfThen(FHasBar, CBarWidth + 2, 0)));
      DoLayout(LWidth);
    end;
    if FHasBar then
      FTextBox.Right := FTextBox.Right - (CBarWidth + 2);
    FTopLine := EnsureRange(FTopLine, 0, Max(0, FModel.LineCount - FRows));
    FTrack := RectF(FField.Right - CBarWidth, FField.Top + 6, FField.Right - 2, FField.Bottom - 6);
    FThumb := RectF(0, 0, 0, 0);
    if FHasBar then
    begin
      LThumbH := Max(20, FTrack.Height * FRows / Max(1, FModel.LineCount));
      FThumb := RectF(FTrack.Left, FTrack.Top, FTrack.Right, FTrack.Top + LThumbH);
      if FModel.LineCount > FRows then
        FThumb.Offset(0, (FTrack.Height - LThumbH) * FTopLine / (FModel.LineCount - FRows));
    end;
  end
  else
  begin
    FRows := 1;
    FTextBox := RectF(LLeft, LMid - FLineH / 2, LRight, LMid + FLineH / 2);
    if FLayoutDirty then
      DoLayout(0);
  end;
end;

{ Caret, scrolling, blinking }

procedure TDaisyFmxCustomTextEdit.CaretMoved(AKeepDesiredX: Boolean);
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
  Repaint;
end;

procedure TDaisyFmxCustomTextEdit.Edited;
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

procedure TDaisyFmxCustomTextEdit.TextEdited;
begin
end;

function TDaisyFmxCustomTextEdit.FieldRect: TRectF;
begin
  ComputeGeometry;
  Result := FField;
end;

function TDaisyFmxCustomTextEdit.EndIconRect: TRectF;
begin
  ComputeGeometry;
  Result := FEndBox;
end;

procedure TDaisyFmxCustomTextEdit.ResetBlink;
begin
  FBlinkOrigin := DaisyAnimationClock.Time;
  FBlinkOn := True;
end;

procedure TDaisyFmxCustomTextEdit.StartTicking;
begin
  if (not FTicking) and not (csDesigning in ComponentState) then
  begin
    FTicking := True;
    DaisyAnimationClock.AddListener(Tick);
  end;
end;

procedure TDaisyFmxCustomTextEdit.StopTicking;
begin
  if FTicking then
  begin
    FTicking := False;
    DaisyAnimationClock.RemoveListener(Tick);
  end;
end;

procedure TDaisyFmxCustomTextEdit.Tick(Sender: TObject);
var
  LOn: Boolean;
begin
  LOn := not Odd(Floor((DaisyAnimationClock.Time - FBlinkOrigin) / CBlinkSeconds));
  if LOn <> FBlinkOn then
  begin
    FBlinkOn := LOn;
    Repaint;
  end;
end;

procedure TDaisyFmxCustomTextEdit.DoEnter;
begin
  inherited DoEnter;
  ResetBlink;
  StartTicking;
  Repaint;
end;

procedure TDaisyFmxCustomTextEdit.DoExit;
begin
  StopTicking;
  FDragging := False;
  FBarDrag := False;
  FModel.BreakUndo;
  inherited DoExit;
  Repaint;
end;

{ Clipboard and editing commands }

procedure TDaisyFmxCustomTextEdit.SelectAll;
begin
  FModel.SelectAll;
  CaretMoved;
end;

procedure TDaisyFmxCustomTextEdit.CopyToClipboard;
var
  LService: IFMXClipboardService;
begin
  if FModel.HasSelection and (PasswordMask = #0) and
    TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LService) then
    LService.SetClipboard(StringReplace(FModel.SelectedText, #10, sLineBreak, [rfReplaceAll]));
end;

procedure TDaisyFmxCustomTextEdit.CutToClipboard;
begin
  if FReadOnly or (PasswordMask <> #0) then
    Exit;
  CopyToClipboard;
  if FModel.DeleteSelection then
    Edited;
end;

procedure TDaisyFmxCustomTextEdit.PasteFromClipboard;
var
  LService: IFMXClipboardService;
  LValue: TValue;
  LText: string;
begin
  if FReadOnly then
    Exit;
  LText := '';
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LService) then
  begin
    LValue := LService.GetClipboard;
    if (not LValue.IsEmpty) and LValue.IsType<string> then
      LText := LValue.AsString;
  end;
  if (LText <> '') and FModel.InsertText(LText) then
  begin
    FModel.BreakUndo;
    Edited;
  end;
end;

procedure TDaisyFmxCustomTextEdit.Undo;
begin
  if (not FReadOnly) and FModel.Undo then
    Edited;
end;

procedure TDaisyFmxCustomTextEdit.Redo;
begin
  if (not FReadOnly) and FModel.Redo then
    Edited;
end;

procedure TDaisyFmxCustomTextEdit.Clear;
begin
  SetModelText('');
end;

procedure TDaisyFmxCustomTextEdit.MoveVertical(ALines: Integer; AExtend: Boolean);
var
  LTarget: Integer;
begin
  ComputeGeometry;
  if FDesiredX < 0 then
    FDesiredX := PosToX(FModel.Caret);
  LTarget := FModel.LineOfPos(FModel.Caret) + ALines;
  if LTarget < 0 then
    FModel.SetCaretPos(0, AExtend)
  else if LTarget >= FModel.LineCount then
    FModel.SetCaretPos(Length(FModel.Text), AExtend)
  else
    FModel.SetCaretPos(FModel.PosAtX(LTarget, FDesiredX, FMeasureFn), AExtend);
  CaretMoved(True);
end;

{ Keyboard }

procedure TDaisyFmxCustomTextEdit.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  LExtend, LCtrl, LHandled: Boolean;
  LMove: TDaisyTextMove;
begin
  LExtend := ssShift in Shift;
  LCtrl := (ssCtrl in Shift) or (ssCommand in Shift);
  LHandled := True;
  ComputeGeometry;
  case Key of
    vkLeft, vkRight, vkHome, vkEnd:
      begin
        case Key of
          vkLeft: if LCtrl then LMove := tmWordLeft else LMove := tmLeft;
          vkRight: if LCtrl then LMove := tmWordRight else LMove := tmRight;
          vkHome: if LCtrl then LMove := tmDocStart else LMove := tmLineStart;
        else
          if LCtrl then LMove := tmDocEnd else LMove := tmLineEnd;
        end;
        FModel.MoveCaret(LMove, LExtend);
        CaretMoved;
      end;
    vkUp:
      if IsMultiLine then
        MoveVertical(-1, LExtend)
      else
      begin
        FModel.MoveCaret(tmDocStart, LExtend);
        CaretMoved;
      end;
    vkDown:
      if IsMultiLine then
        MoveVertical(1, LExtend)
      else
      begin
        FModel.MoveCaret(tmDocEnd, LExtend);
        CaretMoved;
      end;
    vkPrior:
      if IsMultiLine then
        MoveVertical(-FRows, LExtend)
      else
        LHandled := False;
    vkNext:
      if IsMultiLine then
        MoveVertical(FRows, LExtend)
      else
        LHandled := False;
    vkBack:
      begin
        if (not FReadOnly) and FModel.DeleteBackward(LCtrl) then
          Edited;
      end;
    vkDelete:
      if LExtend then
        CutToClipboard
      else
      begin
        if (not FReadOnly) and FModel.DeleteForward(LCtrl) then
          Edited;
      end;
    vkInsert:
      if LCtrl then
        CopyToClipboard
      else if LExtend then
        PasteFromClipboard
      else
        LHandled := False;
    vkReturn:
      if IsMultiLine and not FReadOnly then
      begin
        if FModel.InsertText(#10) then
          Edited;
      end
      else
        LHandled := False;
    vkA:
      if LCtrl then
        SelectAll
      else
        LHandled := False;
    vkC:
      if LCtrl then
        CopyToClipboard
      else
        LHandled := False;
    vkX:
      if LCtrl then
        CutToClipboard
      else
        LHandled := False;
    vkV:
      if LCtrl then
        PasteFromClipboard
      else
        LHandled := False;
    vkZ:
      if LCtrl and LExtend then
        Redo
      else if LCtrl then
        Undo
      else
        LHandled := False;
    vkY:
      if LCtrl then
        Redo
      else
        LHandled := False;
  else
    LHandled := False;
  end;

  if LHandled then
  begin
    Key := 0;
    KeyChar := #0;
    Exit;
  end;

  if (KeyChar <> #0) and not LCtrl and not FReadOnly and Enabled then
  begin
    if (KeyChar >= #$D800) and (KeyChar <= #$DBFF) then
      FPendingHigh := KeyChar // first half of a surrogate pair (emoji): wait for the second
    else if (KeyChar >= #$DC00) and (KeyChar <= #$DFFF) then
    begin
      if FPendingHigh <> #0 then
        if FModel.InsertText(FPendingHigh + KeyChar) then
          Edited;
      FPendingHigh := #0;
    end
    else
    begin
      FPendingHigh := #0;
      if (KeyChar >= #32) and (KeyChar <> #127) then
        if FModel.InsertText(KeyChar) then
          Edited;
    end;
    Key := 0;
    KeyChar := #0;
    Exit;
  end;
  inherited KeyDown(Key, KeyChar, Shift);
end;

{ Mouse }

function TDaisyFmxCustomTextEdit.PosFromPoint(X, Y: Single): Integer;
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

procedure TDaisyFmxCustomTextEdit.ScrollBarTo(Y: Single);
var
  LRange: Single;
begin
  LRange := FTrack.Height - FThumb.Height;
  if (LRange <= 0) or (FModel.LineCount <= FRows) then
    Exit;
  FTopLine := EnsureRange(Round((Y - FBarGrab - FTrack.Top) / LRange * (FModel.LineCount - FRows)), 0,
    FModel.LineCount - FRows);
  Repaint;
end;

procedure TDaisyFmxCustomTextEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> TMouseButton.mbLeft then
    Exit;
  if CanFocus and not IsFocused then
    SetFocus;
  ComputeGeometry;
  if IsMultiLine and FHasBar and (X >= FTextBox.Right) then
  begin
    FBarDrag := True;
    if FThumb.Contains(PointF(X, Y)) then
      FBarGrab := Y - FThumb.Top
    else
    begin
      FBarGrab := FThumb.Height / 2;
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

procedure TDaisyFmxCustomTextEdit.MouseMove(Shift: TShiftState; X, Y: Single);
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

procedure TDaisyFmxCustomTextEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FDragging := False;
  FBarDrag := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TDaisyFmxCustomTextEdit.MouseWheel(Shift: TShiftState; WheelDelta: Integer;
  var Handled: Boolean);
begin
  inherited MouseWheel(Shift, WheelDelta, Handled);
  if Handled or (not IsMultiLine) then
    Exit;
  ComputeGeometry;
  if FModel.LineCount > FRows then
  begin
    FTopLine := EnsureRange(FTopLine - Sign(WheelDelta) * 3, 0, FModel.LineCount - FRows);
    Repaint;
    Handled := True;
  end;
end;

{ Painting }

procedure TDaisyFmxCustomTextEdit.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LTint, LBorder, LFill, LText, LDim: TAlphaColor;
  LPalette: TDaisyPalette;
  LRadius, LBorderW, LX1, LX2, LCaretX: Single;
  I, LLineIdx, LS1, LS2: Integer;
  LBordered, LActive, LFloatUp: Boolean;
  LLine: TDaisyTextLine;
  LRow, LCaretRect: TRectF;
  LShown: string;
begin
  ComputeGeometry;
  LRadius := ResolvedCornerRadius;
  LActive := IsFocused;
  LBorderW := Max(1, Theme.BorderWidth);

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

  if TAlphaColorRec(LFill).A > 0 then
    FillRound(FField, LRadius, LFill);
  if LBordered or LActive then
    StrokeRound(FField, LRadius, LBorder, LBorderW, (Style = dsDash) and not LActive);
  if FDivX >= 0 then
    FillRound(RectF(FDivX, FField.Top + FField.Height / 4, FDivX + 1, FField.Bottom - FField.Height / 4),
      0, DaisyWithAlpha(Theme.BaseContent, 0.2));
  if LFloatUp then
    FillRound(FChip, 0, Theme.Base100);

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
        LX2 := LX2 + 4;
      LX1 := Max(LX1, FTextBox.Left);
      LX2 := Min(LX2, FTextBox.Right);
      if LX2 > LX1 then
      begin
        if IsMultiLine then
          LRow := RectF(0, FTextBox.Top + I * FLineH, 0, FTextBox.Top + (I + 1) * FLineH)
        else
          LRow := FTextBox;
        FillRound(RectF(LX1, LRow.Top, LX2, LRow.Bottom), 2,
          DaisyWithAlpha(Theme.Primary, IfThen(Enabled, 0.3, 0.12)));
      end;
    end;

  // scroll bar
  if IsMultiLine and FHasBar then
  begin
    FillRound(FTrack, FTrack.Width / 2, DaisyWithAlpha(Theme.BaseContent, 0.06));
    FillRound(FThumb, FThumb.Width / 2, DaisyWithAlpha(Theme.BaseContent, 0.3));
  end;

  if FLegend <> '' then
    DrawText(FLegend, FLegendRect, Theme.BaseContent, FSmallSize, True, TTextAlign.Leading,
      TTextAlign.Center, False);
  if FHelperText <> '' then
    DrawText(FHelperText, FHintRect, DaisyWithAlpha(Theme.BaseContent, 0.6), DaisyFontSize(dzXS),
      False, TTextAlign.Leading, TTextAlign.Center, False);
  if (FLabelText <> '') and (FLabelMode in [ilmBefore, ilmAfter]) then
    DrawText(FLabelText, FLabelBox, LDim, FSmallSize, False, TTextAlign.Leading, TTextAlign.Center, False);
  if LFloatUp then
    DrawText(FLabelText, FChip, LDim, FSmallSize, False, TTextAlign.Center, TTextAlign.Center, False);

  if StartIconSource <> nil then
    DrawGlyph(StartIconSource, FStartBox, LDim);
  if EndIconSource <> nil then
    DrawGlyph(EndIconSource, FEndBox, LDim);

  // text
  if FModel.Text = '' then
  begin
    if (FLabelMode = ilmFloating) and (FLabelText <> '') and not LFloatUp then
      DrawText(FLabelText, FTextBox, LDim, FFontSize, False, TTextAlign.Leading, TTextAlign.Center, False)
    else if FPlaceholder <> '' then
      DrawText(FPlaceholder, FTextBox, LDim, FFontSize, False, TTextAlign.Leading, TTextAlign.Center, False);
  end
  else if IsMultiLine then
  begin
    for I := 0 to FRows - 1 do
    begin
      LLineIdx := FTopLine + I;
      if LLineIdx >= FModel.LineCount then
        Break;
      LRow := RectF(FTextBox.Left, FTextBox.Top + I * FLineH, FTextBox.Right,
        FTextBox.Top + (I + 1) * FLineH);
      DrawText(FModel.LineText(LLineIdx), LRow, LText, FFontSize, False, TTextAlign.Leading,
        TTextAlign.Center, False);
    end;
  end
  else
  begin
    LShown := Copy(FModel.Text, FScrollPos + 1, MaxInt);
    if PasswordMask <> #0 then
      LShown := StringOfChar(PasswordMask, Length(LShown));
    DrawText(LShown, FTextBox, LText, FFontSize, False, TTextAlign.Leading, TTextAlign.Center, False);
  end;

  // caret
  if LActive and FBlinkOn and Enabled then
  begin
    LCaretX := FTextBox.Left + PosToX(FModel.Caret);
    if IsMultiLine then
    begin
      I := FModel.LineOfPos(FModel.Caret) - FTopLine;
      if (I >= 0) and (I < FRows) then
        LCaretRect := RectF(LCaretX, FTextBox.Top + I * FLineH + 2, LCaretX + 1,
          FTextBox.Top + (I + 1) * FLineH - 2)
      else
        LCaretRect := RectF(0, 0, 0, 0);
    end
    else
      LCaretRect := RectF(LCaretX, FTextBox.Top + 2, LCaretX + 1, FTextBox.Bottom - 2);
    if (LCaretRect.Right > LCaretRect.Left) and (LCaretX >= FTextBox.Left) and
      (LCaretX <= FTextBox.Right + 1) then
      FillRound(LCaretRect, 0, Theme.BaseContent);
  end;
end;

{ TDaisyFmxTextInput }

constructor TDaisyFmxTextInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStartIcon := TDaisyIconSource.Create(IconChanged);
  FEndIcon := TDaisyIconSource.Create(IconChanged);
  FAutoFit := True;
  SetBounds(Position.X, Position.Y, 192, DaisyFieldHeight(dzMD));
  UpdateSize;
end;

destructor TDaisyFmxTextInput.Destroy;
begin
  FEndIcon.Free;
  FStartIcon.Free;
  inherited Destroy;
end;

function TDaisyFmxTextInput.PasswordMask: Char;
begin
  Result := FPasswordChar;
end;

function TDaisyFmxTextInput.StartIconSource: TDaisyIconSource;
begin
  Result := FStartIcon;
end;

function TDaisyFmxTextInput.EndIconSource: TDaisyIconSource;
begin
  Result := FEndIcon;
end;

procedure TDaisyFmxTextInput.SetPasswordChar(const Value: Char);
begin
  if FPasswordChar <> Value then
  begin
    FPasswordChar := Value;
    ModelChanged;
  end;
end;

procedure TDaisyFmxTextInput.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

function TDaisyFmxTextInput.GetStartEmoji: string;
begin
  Result := FStartIcon.Emoji;
end;

procedure TDaisyFmxTextInput.SetStartEmoji(const Value: string);
begin
  FStartIcon.Emoji := Value;
end;

function TDaisyFmxTextInput.GetStartSVG: TStrings;
begin
  Result := FStartIcon.SVG;
end;

procedure TDaisyFmxTextInput.SetStartSVG(const Value: TStrings);
begin
  FStartIcon.SVG := Value;
end;

function TDaisyFmxTextInput.GetEndEmoji: string;
begin
  Result := FEndIcon.Emoji;
end;

procedure TDaisyFmxTextInput.SetEndEmoji(const Value: string);
begin
  FEndIcon.Emoji := Value;
end;

function TDaisyFmxTextInput.GetEndSVG: TStrings;
begin
  Result := FEndIcon.SVG;
end;

procedure TDaisyFmxTextInput.SetEndSVG(const Value: TStrings);
begin
  FEndIcon.SVG := Value;
end;

procedure TDaisyFmxTextInput.IconChanged(Sender: TObject);
begin
  ModelChanged;
end;

procedure TDaisyFmxTextInput.UpdateSize;
var
  LHeight: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  LHeight := TopOffset + DaisyFieldHeight(SizeKind) + HintArea;
  if SameValue(LHeight, Height) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxTextInput.SizeChanged;
begin
  UpdateSize;
  ModelChanged;
end;

procedure TDaisyFmxTextInput.Loaded;
begin
  inherited;
  UpdateSize;
end;

end.
