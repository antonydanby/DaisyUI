unit Daisy.TextEdit;

{
  TDaisyTextModel - the framework-independent part of the DaisyUI text editors
  (TDaisyTextInput / TDaisyTextArea, VCL and FMX).

  Holds the text, caret and selection, edits it (insert, delete, undo / redo),
  moves the caret by character, word, line and page, and lays the text out in
  lines (optionally word wrapped). Characters are never split: a surrogate
  pair, an emoji with skin tone or variation selector, a ZWJ sequence or a flag
  is one step for the caret and for Backspace / Delete.

  Positions are 0-based offsets between characters: 0 is before the first
  character, Length(Text) after the last. Line breaks are a single #10.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Character, System.Generics.Collections;

type
  // Where a text label sits relative to the field of an input
  TDaisyInputLabelMode = (ilmNone, ilmBefore, ilmAfter, ilmFloating);

  // Width, in pixels, of a piece of text in the editor's font
  TDaisyMeasureFunc = reference to function(const AText: string): Single;

  TDaisyTextLine = record
    Start: Integer;
    Length: Integer; // without the line break
  end;

  TDaisyTextMove = (tmLeft, tmRight, tmWordLeft, tmWordRight, tmLineStart, tmLineEnd, tmUp, tmDown,
    tmPageUp, tmPageDown, tmDocStart, tmDocEnd);

  TDaisyTextModel = class
  strict private
    type
      TState = record
        Text: string;
        Caret, Anchor: Integer;
      end;
    var
      FText: string;
      FCaret: Integer;
      FAnchor: Integer;
      FMultiLine: Boolean;
      FMaxLength: Integer;
      FLines: TArray<TDaisyTextLine>;
      FDesiredX: Single;
      FUndo: TList<TState>;
      FRedo: TList<TState>;
      FUndoOpen: Boolean;
    procedure SetText(const Value: string);
    procedure SetMultiLine(const Value: Boolean);
    procedure SetCaret(const Value: Integer);
    function GetSelStart: Integer;
    function GetSelEnd: Integer;
    function Clean(const AText: string): string;
    procedure PushUndo;
    function CodePointAt(AIndex: Integer; out ALen: Integer): Integer;
    function IsExtender(ACodePoint: Integer): Boolean;
    function ParagraphStart(APos: Integer): Integer;
    function CharClass(APos: Integer): Integer;
    function ReplaceRange(AStart, AEnd: Integer; const AText: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function NextBoundary(APos: Integer): Integer;
    function PrevBoundary(APos: Integer): Integer;
    function NextWord(APos: Integer): Integer;
    function PrevWord(APos: Integer): Integer;

    // Editing. All return True when the text changed.
    function InsertText(const AText: string): Boolean;
    function DeleteBackward(AByWord: Boolean): Boolean;
    function DeleteForward(AByWord: Boolean): Boolean;
    function DeleteSelection: Boolean;
    function Undo: Boolean;
    function Redo: Boolean;
    // Ends a run of typing so the next edit starts a new undo step
    procedure BreakUndo;

    // Caret and selection
    procedure MoveCaret(AMove: TDaisyTextMove; AExtend: Boolean; APageLines: Integer = 1);
    procedure SetCaretPos(APos: Integer; AExtend: Boolean);
    procedure SelectAll;
    procedure SelectWordAt(APos: Integer);
    procedure ClearSelection;
    function HasSelection: Boolean;
    function SelectedText: string;

    // Layout
    procedure Layout(AWidth: Single; AWrap: Boolean; const AMeasure: TDaisyMeasureFunc);
    function LineCount: Integer;
    function Line(AIndex: Integer): TDaisyTextLine;
    function LineText(AIndex: Integer): string;
    function LineOfPos(APos: Integer): Integer;
    function XOfPos(APos: Integer; const AMeasure: TDaisyMeasureFunc): Single;
    function PosAtX(ALine: Integer; AX: Single; const AMeasure: TDaisyMeasureFunc): Integer;

    property Text: string read FText write SetText;
    property Caret: Integer read FCaret write SetCaret;
    property Anchor: Integer read FAnchor;
    property SelStart: Integer read GetSelStart;
    property SelEnd: Integer read GetSelEnd;
    property MultiLine: Boolean read FMultiLine write SetMultiLine;
    property MaxLength: Integer read FMaxLength write FMaxLength;
  end;

implementation

const
  CMaxUndo = 100;

constructor TDaisyTextModel.Create;
begin
  inherited Create;
  FUndo := TList<TState>.Create;
  FRedo := TList<TState>.Create;
  SetLength(FLines, 1);
end;

destructor TDaisyTextModel.Destroy;
begin
  FRedo.Free;
  FUndo.Free;
  inherited Destroy;
end;

{ Characters }

function TDaisyTextModel.CodePointAt(AIndex: Integer; out ALen: Integer): Integer;
var
  LHigh: Integer;
begin
  ALen := 1;
  Result := Ord(FText[AIndex]);
  if (Result >= $D800) and (Result <= $DBFF) and (AIndex < Length(FText)) then
  begin
    LHigh := Ord(FText[AIndex + 1]);
    if (LHigh >= $DC00) and (LHigh <= $DFFF) then
    begin
      Result := $10000 + ((Result - $D800) shl 10) + (LHigh - $DC00);
      ALen := 2;
    end;
  end;
end;

function TDaisyTextModel.IsExtender(ACodePoint: Integer): Boolean;
begin
  Result := ((ACodePoint >= $0300) and (ACodePoint <= $036F)) // combining marks
    or ((ACodePoint >= $FE00) and (ACodePoint <= $FE0F)) // variation selectors
    or (ACodePoint = $20E3) // keycap
    or ((ACodePoint >= $1F3FB) and (ACodePoint <= $1F3FF)) // skin tones
    or ((ACodePoint >= $E0020) and (ACodePoint <= $E007F)); // tag characters
end;

function TDaisyTextModel.NextBoundary(APos: Integer): Integer;
var
  LIndex, LLen, LCode, LNextLen, LNext: Integer;
begin
  if APos >= Length(FText) then
    Exit(Length(FText));
  LIndex := APos + 1;
  LCode := CodePointAt(LIndex, LLen);
  Inc(LIndex, LLen);
  if (LCode >= $1F1E6) and (LCode <= $1F1FF) and (LIndex <= Length(FText)) then
  begin
    LNext := CodePointAt(LIndex, LNextLen); // a flag is two regional indicators
    if (LNext >= $1F1E6) and (LNext <= $1F1FF) then
      Inc(LIndex, LNextLen);
  end;
  while LIndex <= Length(FText) do
  begin
    LNext := CodePointAt(LIndex, LNextLen);
    if IsExtender(LNext) then
      Inc(LIndex, LNextLen)
    else if LNext = $200D then
    begin
      Inc(LIndex, LNextLen); // zero width joiner: the next character belongs to this one
      if LIndex <= Length(FText) then
      begin
        CodePointAt(LIndex, LNextLen);
        Inc(LIndex, LNextLen);
      end;
    end
    else
      Break;
  end;
  Result := LIndex - 1;
end;

function TDaisyTextModel.ParagraphStart(APos: Integer): Integer;
begin
  Result := APos;
  while (Result > 0) and (FText[Result] <> #10) do
    Dec(Result);
end;

function TDaisyTextModel.PrevBoundary(APos: Integer): Integer;
var
  LNext: Integer;
begin
  if APos <= 0 then
    Exit(0);
  Result := ParagraphStart(APos);
  if Result = APos then // just after a line break
    Exit(APos - 1);
  while True do
  begin
    LNext := NextBoundary(Result);
    if (LNext >= APos) or (LNext <= Result) then
      Break;
    Result := LNext;
  end;
end;

function TDaisyTextModel.CharClass(APos: Integer): Integer;
var
  LChar: Char;
begin
  LChar := FText[APos + 1];
  if (LChar = #10) then
    Result := 0
  else if (LChar = ' ') or (LChar = #9) then
    Result := 1
  else if LChar.IsLetterOrDigit or (LChar = '_') then
    Result := 2
  else
    Result := 3;
end;

function TDaisyTextModel.NextWord(APos: Integer): Integer;
var
  LClass: Integer;
begin
  Result := APos;
  if Result >= Length(FText) then
    Exit;
  LClass := CharClass(Result);
  if LClass = 0 then
    Exit(Result + 1);
  while (Result < Length(FText)) and (CharClass(Result) = LClass) do
    Result := NextBoundary(Result);
  while (Result < Length(FText)) and (CharClass(Result) = 1) do
    Result := NextBoundary(Result);
end;

function TDaisyTextModel.PrevWord(APos: Integer): Integer;
var
  LClass: Integer;
begin
  Result := APos;
  while (Result > 0) and (CharClass(PrevBoundary(Result)) = 1) do
    Result := PrevBoundary(Result);
  if Result = 0 then
    Exit;
  LClass := CharClass(PrevBoundary(Result));
  if LClass = 0 then
    Exit(Result - 1);
  while (Result > 0) and (CharClass(PrevBoundary(Result)) = LClass) do
    Result := PrevBoundary(Result);
end;

{ Text, undo }

function TDaisyTextModel.Clean(const AText: string): string;
var
  LText: string;
begin
  LText := StringReplace(AText, #13#10, #10, [rfReplaceAll]);
  LText := StringReplace(LText, #13, #10, [rfReplaceAll]);
  if not FMultiLine then
    LText := StringReplace(LText, #10, ' ', [rfReplaceAll]);
  Result := LText;
end;

procedure TDaisyTextModel.SetText(const Value: string);
begin
  FText := Clean(Value);
  if (FMaxLength > 0) and (Length(FText) > FMaxLength) then
    SetLength(FText, FMaxLength);
  FCaret := Min(FCaret, Length(FText));
  FAnchor := FCaret;
  FUndo.Clear;
  FRedo.Clear;
  FUndoOpen := False;
end;

procedure TDaisyTextModel.SetMultiLine(const Value: Boolean);
begin
  if FMultiLine <> Value then
  begin
    FMultiLine := Value;
    FText := Clean(FText);
    FCaret := Min(FCaret, Length(FText));
    FAnchor := FCaret;
  end;
end;

procedure TDaisyTextModel.SetCaret(const Value: Integer);
begin
  FCaret := EnsureRange(Value, 0, Length(FText));
  FAnchor := FCaret;
end;

procedure TDaisyTextModel.PushUndo;
var
  LState: TState;
begin
  FRedo.Clear;
  if FUndoOpen then
    Exit;
  LState.Text := FText;
  LState.Caret := FCaret;
  LState.Anchor := FAnchor;
  FUndo.Add(LState);
  if FUndo.Count > CMaxUndo then
    FUndo.Delete(0);
  FUndoOpen := True;
end;

procedure TDaisyTextModel.BreakUndo;
begin
  FUndoOpen := False;
end;

function TDaisyTextModel.Undo: Boolean;
var
  LNow, LState: TState;
begin
  Result := FUndo.Count > 0;
  if not Result then
    Exit;
  LNow.Text := FText;
  LNow.Caret := FCaret;
  LNow.Anchor := FAnchor;
  FRedo.Add(LNow);
  LState := FUndo.Last;
  FUndo.Delete(FUndo.Count - 1);
  FText := LState.Text;
  FCaret := LState.Caret;
  FAnchor := LState.Anchor;
  FUndoOpen := False;
end;

function TDaisyTextModel.Redo: Boolean;
var
  LNow, LState: TState;
begin
  Result := FRedo.Count > 0;
  if not Result then
    Exit;
  LNow.Text := FText;
  LNow.Caret := FCaret;
  LNow.Anchor := FAnchor;
  FUndo.Add(LNow);
  LState := FRedo.Last;
  FRedo.Delete(FRedo.Count - 1);
  FText := LState.Text;
  FCaret := LState.Caret;
  FAnchor := LState.Anchor;
  FUndoOpen := False;
end;

function TDaisyTextModel.ReplaceRange(AStart, AEnd: Integer; const AText: string): Boolean;
var
  LText: string;
  LRoom: Integer;
begin
  LText := AText;
  if FMaxLength > 0 then
  begin
    LRoom := FMaxLength - (Length(FText) - (AEnd - AStart));
    if LRoom <= 0 then
      LText := ''
    else if Length(LText) > LRoom then
    begin
      SetLength(LText, LRoom);
      if (LText <> '') and (Ord(LText[Length(LText)]) >= $D800) and (Ord(LText[Length(LText)]) <= $DBFF) then
        SetLength(LText, Length(LText) - 1); // do not leave half a surrogate pair
    end;
  end;
  Result := (AEnd > AStart) or (LText <> '');
  if not Result then
    Exit;
  PushUndo;
  FText := Copy(FText, 1, AStart) + LText + Copy(FText, AEnd + 1, MaxInt);
  FCaret := AStart + Length(LText);
  FAnchor := FCaret;
  FDesiredX := -1;
end;

function TDaisyTextModel.InsertText(const AText: string): Boolean;
begin
  Result := ReplaceRange(SelStart, SelEnd, Clean(AText));
  if Result and (Pos(#10, AText) > 0) then
    BreakUndo;
end;

function TDaisyTextModel.DeleteSelection: Boolean;
begin
  Result := HasSelection and ReplaceRange(SelStart, SelEnd, '');
  BreakUndo;
end;

function TDaisyTextModel.DeleteBackward(AByWord: Boolean): Boolean;
var
  LFrom: Integer;
begin
  if HasSelection then
    Exit(DeleteSelection);
  if FCaret = 0 then
    Exit(False);
  if AByWord then
    LFrom := PrevWord(FCaret)
  else
    LFrom := PrevBoundary(FCaret);
  Result := ReplaceRange(LFrom, FCaret, '');
end;

function TDaisyTextModel.DeleteForward(AByWord: Boolean): Boolean;
var
  LTo: Integer;
begin
  if HasSelection then
    Exit(DeleteSelection);
  if FCaret >= Length(FText) then
    Exit(False);
  if AByWord then
    LTo := NextWord(FCaret)
  else
    LTo := NextBoundary(FCaret);
  Result := ReplaceRange(FCaret, LTo, '');
end;

{ Selection and caret }

function TDaisyTextModel.GetSelStart: Integer;
begin
  Result := Min(FCaret, FAnchor);
end;

function TDaisyTextModel.GetSelEnd: Integer;
begin
  Result := Max(FCaret, FAnchor);
end;

function TDaisyTextModel.HasSelection: Boolean;
begin
  Result := FCaret <> FAnchor;
end;

function TDaisyTextModel.SelectedText: string;
begin
  Result := Copy(FText, SelStart + 1, SelEnd - SelStart);
end;

procedure TDaisyTextModel.ClearSelection;
begin
  FAnchor := FCaret;
end;

procedure TDaisyTextModel.SelectAll;
begin
  FAnchor := 0;
  FCaret := Length(FText);
  BreakUndo;
end;

procedure TDaisyTextModel.SelectWordAt(APos: Integer);
var
  LStart, LEnd: Integer;
begin
  LStart := EnsureRange(APos, 0, Length(FText));
  if Length(FText) = 0 then
    Exit;
  if LStart >= Length(FText) then
    LStart := PrevBoundary(LStart);
  if CharClass(LStart) in [2, 3] then
  begin
    LEnd := LStart;
    while (LStart > 0) and (CharClass(PrevBoundary(LStart)) = CharClass(LEnd)) do
      LStart := PrevBoundary(LStart);
    while (LEnd < Length(FText)) and (CharClass(LEnd) = CharClass(LStart)) do
      LEnd := NextBoundary(LEnd);
  end
  else
    LEnd := NextBoundary(LStart);
  FAnchor := LStart;
  FCaret := LEnd;
  BreakUndo;
end;

procedure TDaisyTextModel.SetCaretPos(APos: Integer; AExtend: Boolean);
begin
  FCaret := EnsureRange(APos, 0, Length(FText));
  if not AExtend then
    FAnchor := FCaret;
  FDesiredX := -1;
  BreakUndo;
end;

procedure TDaisyTextModel.MoveCaret(AMove: TDaisyTextMove; AExtend: Boolean; APageLines: Integer);
var
  LNew, LLine: Integer;
begin
  LNew := FCaret;
  case AMove of
    tmLeft:
      if HasSelection and not AExtend then
        LNew := SelStart
      else
        LNew := PrevBoundary(FCaret);
    tmRight:
      if HasSelection and not AExtend then
        LNew := SelEnd
      else
        LNew := NextBoundary(FCaret);
    tmWordLeft: LNew := PrevWord(FCaret);
    tmWordRight: LNew := NextWord(FCaret);
    tmLineStart: LNew := FLines[LineOfPos(FCaret)].Start;
    tmLineEnd:
      begin
        LLine := LineOfPos(FCaret);
        LNew := FLines[LLine].Start + FLines[LLine].Length;
      end;
    tmDocStart: LNew := 0;
    tmDocEnd: LNew := Length(FText);
    tmUp, tmDown, tmPageUp, tmPageDown:
      begin
        // Up / Down need the layout; the control moves with PosAtX, here only the line is picked
        LLine := LineOfPos(FCaret);
        case AMove of
          tmUp: Dec(LLine);
          tmDown: Inc(LLine);
          tmPageUp: Dec(LLine, APageLines);
          tmPageDown: Inc(LLine, APageLines);
        end;
        if LLine < 0 then
          LNew := 0
        else if LLine >= Length(FLines) then
          LNew := Length(FText)
        else
          LNew := FLines[LLine].Start; // refined by the control through PosAtX
      end;
  end;
  SetCaretPos(LNew, AExtend);
end;

{ Layout }

procedure TDaisyTextModel.Layout(AWidth: Single; AWrap: Boolean; const AMeasure: TDaisyMeasureFunc);
var
  LLines: TList<TDaisyTextLine>;
  LStart, LParaEnd, LPos, LNext, LLastBreak, LPrev: Integer;
  LLine: TDaisyTextLine;
  LTrimmed: string;

  procedure AddLine(AStart, ALength: Integer);
  begin
    LLine.Start := AStart;
    LLine.Length := ALength;
    LLines.Add(LLine);
  end;

begin
  LLines := TList<TDaisyTextLine>.Create;
  try
    LStart := 0;
    while True do
    begin
      LParaEnd := LStart;
      while (LParaEnd < Length(FText)) and (FText[LParaEnd + 1] <> #10) do
        Inc(LParaEnd);
      if (not AWrap) or (AWidth <= 0) or (LParaEnd = LStart) then
        AddLine(LStart, LParaEnd - LStart)
      else
      begin
        LPos := LStart;
        LLastBreak := -1;
        LNext := LStart;
        while LNext < LParaEnd do
        begin
          LPrev := LNext;
          LNext := Min(NextBoundary(LPrev), LParaEnd);
          if (FText[LNext] = ' ') or (FText[LNext] = #9) then
            LLastBreak := LNext;
          LTrimmed := TrimRight(Copy(FText, LPos + 1, LNext - LPos));
          if (AMeasure(LTrimmed) > AWidth) and (LNext - LPos > 1) and (LNext > LPos + 1) then
          begin
            if LLastBreak > LPos then
            begin
              AddLine(LPos, LLastBreak - LPos);
              LPos := LLastBreak;
            end
            else
            begin
              AddLine(LPos, LPrev - LPos);
              LPos := LPrev;
            end;
            LLastBreak := -1;
            LNext := LPos;
          end;
        end;
        AddLine(LPos, LParaEnd - LPos);
      end;
      if LParaEnd >= Length(FText) then
        Break;
      LStart := LParaEnd + 1;
    end;
    FLines := LLines.ToArray;
  finally
    LLines.Free;
  end;
end;

function TDaisyTextModel.LineCount: Integer;
begin
  Result := Length(FLines);
end;

function TDaisyTextModel.Line(AIndex: Integer): TDaisyTextLine;
begin
  Result := FLines[EnsureRange(AIndex, 0, High(FLines))];
end;

function TDaisyTextModel.LineText(AIndex: Integer): string;
var
  LLine: TDaisyTextLine;
begin
  LLine := FLines[EnsureRange(AIndex, 0, High(FLines))];
  Result := Copy(FText, LLine.Start + 1, LLine.Length);
end;

function TDaisyTextModel.LineOfPos(APos: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := High(FLines) downto 0 do
    if FLines[I].Start <= APos then
      Exit(I);
end;

function TDaisyTextModel.XOfPos(APos: Integer; const AMeasure: TDaisyMeasureFunc): Single;
var
  LLine: Integer;
begin
  LLine := LineOfPos(APos);
  Result := AMeasure(Copy(FText, FLines[LLine].Start + 1,
    Min(APos, FLines[LLine].Start + FLines[LLine].Length) - FLines[LLine].Start));
end;

function TDaisyTextModel.PosAtX(ALine: Integer; AX: Single; const AMeasure: TDaisyMeasureFunc): Integer;
var
  LLine: TDaisyTextLine;
  LEnd, LNext: Integer;
  LPrevX, LX: Single;
begin
  LLine := Line(ALine);
  LEnd := LLine.Start + LLine.Length;
  Result := LLine.Start;
  LPrevX := 0;
  while Result < LEnd do
  begin
    LNext := Min(NextBoundary(Result), LEnd);
    LX := AMeasure(Copy(FText, LLine.Start + 1, LNext - LLine.Start));
    if AX < (LPrevX + LX) / 2 then
      Exit;
    LPrevX := LX;
    Result := LNext;
  end;
  // A soft-wrapped line ends in front of the next one: keep the caret on this line
  if (ALine < High(FLines)) and (FLines[ALine + 1].Start = LEnd) and (Result = LEnd) and (LEnd > LLine.Start) then
    Result := PrevBoundary(LEnd);
end;

end.
