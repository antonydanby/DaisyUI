unit Daisy.VCL.Calendar;

{
  TDaisyCalendar - the DaisyUI "calendar": a month grid with previous / next arrows.
  Single date or date range selection. Variant sets the colour of the selection.
  Mouse wheel and PageUp / PageDown change the month, the arrow keys move the date.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math, System.DateUtils,
  Vcl.Controls, Daisy.Theme, Daisy.Calendars, Daisy.VCL.Control;

type
  TDaisyCalendar = class(TDaisyControl)
  strict private
    FViewMonth: TDateTime;
    FSelected: TDateTime;
    FRangeStart: TDateTime;
    FRangeEnd: TDateTime;
    FMode: TDaisyCalendarSelection;
    FFirstDay: TDaisyWeekDay;
    FShowOutside: Boolean;
    FHotItem: Integer;
    FOnChange: TNotifyEvent;
    procedure SetViewMonth(const Value: TDateTime);
    procedure SetSelected(const Value: TDateTime);
    procedure SetRangeStart(const Value: TDateTime);
    procedure SetRangeEnd(const Value: TDateTime);
    procedure SetMode(const Value: TDaisyCalendarSelection);
    procedure SetFirstDay(const Value: TDaisyWeekDay);
    procedure SetShowOutside(const Value: Boolean);
    procedure SetHotItem(const Value: Integer);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    function HeaderHeight: Integer;
    function WeekRowHeight: Integer;
    function ArrowRect(ANext: Boolean): TRect;
    function CellRect(AIndex: Integer): TRectF;
    function CellDate(AIndex: Integer): TDateTime;
    function HitItem(X, Y: Integer): Integer;
    function IsEnd(ADate: TDateTime): Boolean;
    function InRange(ADate: TDateTime): Boolean;
    function AccentPalette: TDaisyPalette;
    procedure PickDate(ADate: TDateTime);
    procedure SelectionChanged;
  protected
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    function DrawsFocusRing: Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
    // Called after a day was clicked, even when it was already the selected date
    procedure DatePicked(ADate: TDateTime); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    // Any day of the month being shown
    property ViewMonth: TDateTime read FViewMonth write SetViewMonth;
    procedure NextMonth;
    procedure PreviousMonth;
    procedure GoToday;
  published
    property SelectedDate: TDateTime read FSelected write SetSelected;
    property SelectionMode: TDaisyCalendarSelection read FMode write SetMode default csSingle;
    property RangeStart: TDateTime read FRangeStart write SetRangeStart;
    property RangeEnd: TDateTime read FRangeEnd write SetRangeEnd;
    property FirstDayOfWeek: TDaisyWeekDay read FFirstDay write SetFirstDay default wdMonday;
    // Dates of the neighbouring months are shown dimmed
    property ShowOutsideDays: Boolean read FShowOutside write SetShowOutside default False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{ TDaisyCalendar }

constructor TDaisyCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFirstDay := wdMonday;
  FHotItem := -1;
  FSelected := DateOf(Now);
  FViewMonth := StartOfTheMonth(FSelected);
  TabStop := True;
  SetBounds(Left, Top, 304, 328);
end;

procedure TDaisyCalendar.SelectionChanged;
begin
  Invalidate;
  if Assigned(FOnChange) and not (csLoading in ComponentState) then
    FOnChange(Self);
end;

procedure TDaisyCalendar.SetViewMonth(const Value: TDateTime);
begin
  if not DaisySameMonth(FViewMonth, Value) then
  begin
    FViewMonth := StartOfTheMonth(Value);
    FHotItem := -1;
    Invalidate;
  end;
end;

procedure TDaisyCalendar.SetSelected(const Value: TDateTime);
begin
  if FSelected <> Value then
  begin
    FSelected := DateOf(Value);
    if FSelected <> 0 then
      FViewMonth := StartOfTheMonth(FSelected);
    SelectionChanged;
  end;
end;

procedure TDaisyCalendar.SetRangeStart(const Value: TDateTime);
begin
  if FRangeStart <> Value then
  begin
    FRangeStart := DateOf(Value);
    if (FRangeStart <> 0) and not (csLoading in ComponentState) then
      FViewMonth := StartOfTheMonth(FRangeStart);
    SelectionChanged;
  end;
end;

procedure TDaisyCalendar.SetRangeEnd(const Value: TDateTime);
begin
  if FRangeEnd <> Value then
  begin
    FRangeEnd := DateOf(Value);
    SelectionChanged;
  end;
end;

procedure TDaisyCalendar.SetMode(const Value: TDaisyCalendarSelection);
begin
  if FMode <> Value then
  begin
    FMode := Value;
    Invalidate;
  end;
end;

procedure TDaisyCalendar.SetFirstDay(const Value: TDaisyWeekDay);
begin
  if FFirstDay <> Value then
  begin
    FFirstDay := Value;
    Invalidate;
  end;
end;

procedure TDaisyCalendar.SetShowOutside(const Value: Boolean);
begin
  if FShowOutside <> Value then
  begin
    FShowOutside := Value;
    Invalidate;
  end;
end;

procedure TDaisyCalendar.SetHotItem(const Value: Integer);
begin
  if FHotItem <> Value then
  begin
    FHotItem := Value;
    Invalidate;
  end;
end;

procedure TDaisyCalendar.NextMonth;
begin
  ViewMonth := IncMonth(FViewMonth, 1);
end;

procedure TDaisyCalendar.PreviousMonth;
begin
  ViewMonth := IncMonth(FViewMonth, -1);
end;

procedure TDaisyCalendar.GoToday;
begin
  ViewMonth := DateOf(Now);
end;

function TDaisyCalendar.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyCalendar.DefaultContentPadding: Integer;
begin
  Result := 12;
end;

function TDaisyCalendar.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := Theme.BorderColor;
  Result.Text := Theme.BaseContent;
end;

function TDaisyCalendar.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

procedure TDaisyCalendar.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TDaisyCalendar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHotItem(-1);
end;

function TDaisyCalendar.HeaderHeight: Integer;
begin
  Result := ScaleValue(36);
end;

function TDaisyCalendar.WeekRowHeight: Integer;
begin
  Result := ScaleValue(28);
end;

function TDaisyCalendar.ArrowRect(ANext: Boolean): TRect;
var
  LInner: TRect;
begin
  LInner := ContentRect;
  if ANext then
    Result := Rect(LInner.Right - HeaderHeight, LInner.Top, LInner.Right, LInner.Top + HeaderHeight)
  else
    Result := Rect(LInner.Left, LInner.Top, LInner.Left + HeaderHeight, LInner.Top + HeaderHeight);
end;

function TDaisyCalendar.CellRect(AIndex: Integer): TRectF;
var
  LInner: TRect;
  LW, LH, LTop: Single;
begin
  LInner := ContentRect;
  LTop := LInner.Top + HeaderHeight + WeekRowHeight;
  LW := LInner.Width / 7;
  LH := (LInner.Bottom - LTop) / 6;
  Result := RectF(LInner.Left + (AIndex mod 7) * LW, LTop + (AIndex div 7) * LH,
    LInner.Left + (AIndex mod 7 + 1) * LW, LTop + (AIndex div 7 + 1) * LH);
end;

function TDaisyCalendar.CellDate(AIndex: Integer): TDateTime;
begin
  Result := DaisyCalendarCellDate(FViewMonth, FFirstDay, AIndex);
end;

function TDaisyCalendar.HitItem(X, Y: Integer): Integer;
var
  I: Integer;
  LPt: TPointF;
begin
  Result := -1;
  if PtInRect(ArrowRect(False), Point(X, Y)) then
    Exit(100);
  if PtInRect(ArrowRect(True), Point(X, Y)) then
    Exit(101);
  LPt := PointF(X, Y);
  for I := 0 to DaisyCalendarCells - 1 do
    if CellRect(I).Contains(LPt) then
    begin
      if FShowOutside or DaisySameMonth(CellDate(I), FViewMonth) then
        Result := I;
      Exit;
    end;
end;

function TDaisyCalendar.IsEnd(ADate: TDateTime): Boolean;
begin
  if FMode = csSingle then
    Result := (FSelected <> 0) and SameDate(ADate, FSelected)
  else
    Result := ((FRangeStart <> 0) and SameDate(ADate, FRangeStart))
      or ((FRangeEnd <> 0) and SameDate(ADate, FRangeEnd));
end;

function TDaisyCalendar.InRange(ADate: TDateTime): Boolean;
begin
  Result := (FMode = csRange) and (FRangeStart <> 0) and (FRangeEnd <> 0)
    and (ADate > FRangeStart) and (ADate < FRangeEnd);
end;

function TDaisyCalendar.AccentPalette: TDaisyPalette;
begin
  if Variant = dvDefault then
  begin
    Result.Fill := Theme.BaseContent;
    Result.Content := Theme.Base100;
  end
  else
    Result := DaisyVariantPalette(Theme, Variant);
end;

procedure TDaisyCalendar.PickDate(ADate: TDateTime);
begin
  ADate := DateOf(ADate);
  if FMode = csSingle then
  begin
    FViewMonth := StartOfTheMonth(ADate);
    if FSelected <> ADate then
      FSelected := ADate;
  end
  else
  begin
    FViewMonth := StartOfTheMonth(ADate);
    if (FRangeStart = 0) or (FRangeEnd <> 0) then
    begin
      FRangeStart := ADate;
      FRangeEnd := 0;
    end
    else if ADate < FRangeStart then
    begin
      FRangeEnd := FRangeStart;
      FRangeStart := ADate;
    end
    else
      FRangeEnd := ADate;
  end;
  SelectionChanged;
end;

procedure TDaisyCalendar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LItem: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button <> mbLeft) or (csDesigning in ComponentState) then
    Exit;
  if CanFocus then
    SetFocus;
  LItem := HitItem(X, Y);
  if LItem = 100 then
    PreviousMonth
  else if LItem = 101 then
    NextMonth
  else if LItem >= 0 then
  begin
    PickDate(CellDate(LItem));
    DatePicked(CellDate(LItem));
  end;
end;

procedure TDaisyCalendar.DatePicked(ADate: TDateTime);
begin
end;

procedure TDaisyCalendar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  SetHotItem(HitItem(X, Y));
end;

procedure TDaisyCalendar.KeyDown(var Key: Word; Shift: TShiftState);
var
  LBase: TDateTime;
  LStep: Integer;
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_PRIOR: begin PreviousMonth; Key := 0; end;
    VK_NEXT: begin NextMonth; Key := 0; end;
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN:
      begin
        case Key of
          VK_LEFT: LStep := -1;
          VK_RIGHT: LStep := 1;
          VK_UP: LStep := -7;
        else
          LStep := 7;
        end;
        if FMode = csSingle then
          LBase := FSelected
        else if FRangeEnd <> 0 then
          LBase := FRangeEnd
        else
          LBase := FRangeStart;
        if LBase = 0 then
          LBase := DateOf(Now);
        if FMode = csSingle then
          SetSelected(LBase + LStep)
        else
          PickDate(LBase + LStep);
        Key := 0;
      end;
  end;
end;

function TDaisyCalendar.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if not Result then
  begin
    if WheelDelta > 0 then
      PreviousMonth
    else
      NextMonth;
    Result := True;
  end;
end;

procedure TDaisyCalendar.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
  LAccent: TDaisyPalette;
  LCell, LBox, LBand: TRectF;
  LDate: TDateTime;
  LInner, LText: TRect;
  I, LRadius, LFont: Integer;
  LInMonth, LEnd, LToday: Boolean;
  LColor: TAlphaColor;
  LArrow: TRect;
  LPath: TDaisyIconPaths;
begin
  LAccent := AccentPalette;
  LInner := ContentRect;
  LRadius := ScaleValue(Theme.RadiusField);
  LFont := DaisyFontSize(SizeKind);

  LGraphics := NewGraphics;
  try
    // Arrows
    for I := 0 to 1 do
    begin
      LArrow := ArrowRect(I = 1);
      LBox := RectF(LArrow.Left, LArrow.Top, LArrow.Right, LArrow.Bottom);
      if FHotItem = 100 + I then
        FillRoundRect(LGraphics, LBox, LRadius, Theme.Base200);
      LBox.Inflate(-LBox.Width * 0.3, -LBox.Height * 0.3);
      if I = 0 then
        LPath := [[PointF(15, 5), PointF(8, 12), PointF(15, 19)]]
      else
        LPath := [[PointF(9, 5), PointF(16, 12), PointF(9, 19)]];
      FlipGlyphs := True; // prev/next arrows keep their mirrored direction
      try
        DrawPolylines(LGraphics, LPath, LBox, Theme.BaseContent, 2);
      finally
        FlipGlyphs := False;
      end;
    end;

    for I := 0 to DaisyCalendarCells - 1 do
    begin
      LDate := CellDate(I);
      LInMonth := DaisySameMonth(LDate, FViewMonth);
      if (not LInMonth) and (not FShowOutside) then
        Continue;
      LCell := CellRect(I);
      LBox := LCell;
      LBox.Inflate(-2, -2);
      if LBox.Width > LBox.Height then
        LBox.Inflate(-(LBox.Width - LBox.Height) / 2, 0)
      else
        LBox.Inflate(0, -(LBox.Height - LBox.Width) / 2);
      LEnd := IsEnd(LDate);
      LToday := SameDate(LDate, Now);
      if InRange(LDate) then
      begin
        LBand := RectF(LCell.Left, LBox.Top, LCell.Right, LBox.Bottom);
        FillRoundRect(LGraphics, LBand, 0, DaisyWithAlpha(LAccent.Fill, 0.18));
      end;
      if LEnd then
        FillRoundRect(LGraphics, LBox, LRadius, LAccent.Fill)
      else if FHotItem = I then
        FillRoundRect(LGraphics, LBox, LRadius, Theme.Base200);
      if LToday and not LEnd then
        StrokeRoundRect(LGraphics, LBox, LRadius, DaisyWithAlpha(Theme.BaseContent, 0.5), 1, False);
    end;
  finally
    LGraphics.Free;
  end;

  // Month and year
  LText := Rect(LInner.Left + HeaderHeight, LInner.Top, LInner.Right - HeaderHeight,
    LInner.Top + HeaderHeight);
  DrawText(DaisyMonthTitle(FViewMonth), LText, Theme.BaseContent, LFont, True,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);

  // Weekday names
  for I := 0 to 6 do
  begin
    LCell := CellRect(I);
    LText := Rect(Round(LCell.Left), LInner.Top + HeaderHeight, Round(LCell.Right),
      LInner.Top + HeaderHeight + WeekRowHeight);
    DrawText(DaisyWeekDayCaption(FFirstDay, I), LText, DaisyWithAlpha(Theme.BaseContent, 0.6),
      LFont - 2, False, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;

  // Day numbers
  for I := 0 to DaisyCalendarCells - 1 do
  begin
    LDate := CellDate(I);
    LInMonth := DaisySameMonth(LDate, FViewMonth);
    if (not LInMonth) and (not FShowOutside) then
      Continue;
    LCell := CellRect(I);
    LText := Rect(Round(LCell.Left), Round(LCell.Top), Round(LCell.Right), Round(LCell.Bottom));
    if IsEnd(LDate) then
      LColor := LAccent.Content
    else if LInMonth then
      LColor := Theme.BaseContent
    else
      LColor := DaisyWithAlpha(Theme.BaseContent, 0.35);
    DrawText(IntToStr(DayOf(LDate)), LText, LColor, LFont, SameDate(LDate, Now) and IsEnd(LDate),
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
end;

end.
