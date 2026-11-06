unit Daisy.FMX.Calendar;

{
  TDaisyFmxCalendar - the DaisyUI "calendar": a month grid with previous / next arrows.
  Single date or date range selection. Variant sets the colour of the selection.
  Mouse wheel and PageUp / PageDown change the month, the arrow keys move the date.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math, System.DateUtils,
  FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme, Daisy.Calendars, Daisy.FMX.Control;

type
  TDaisyFmxCalendar = class(TDaisyControl)
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
    procedure SetViewMonth(const AValue: TDateTime);
    procedure SetSelected(const AValue: TDateTime);
    procedure SetRangeStart(const AValue: TDateTime);
    procedure SetRangeEnd(const AValue: TDateTime);
    procedure SetMode(const AValue: TDaisyCalendarSelection);
    procedure SetFirstDay(const AValue: TDaisyWeekDay);
    procedure SetShowOutside(const AValue: Boolean);
    procedure SetHotItem(const AValue: Integer);
    function ArrowRect(ANext: Boolean): TRectF;
    function CellRect(AIndex: Integer): TRectF;
    function CellDate(AIndex: Integer): TDateTime;
    function HitItem(X, Y: Single): Integer;
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
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure DoMouseLeave; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
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

const
  CHeaderHeight = 36;
  CWeekRowHeight = 28;

{ TDaisyFmxCalendar }

constructor TDaisyFmxCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFirstDay := wdMonday;
  FHotItem := -1;
  FSelected := DateOf(Now);
  FViewMonth := StartOfTheMonth(FSelected);
  CanFocus := True;
  TabStop := True;
  SetBounds(Position.X, Position.Y, 304, 328);
end;

procedure TDaisyFmxCalendar.SelectionChanged;
begin
  Repaint;
  if Assigned(FOnChange) and not (csLoading in ComponentState) then
    FOnChange(Self);
end;

procedure TDaisyFmxCalendar.SetViewMonth(const AValue: TDateTime);
begin
  if not DaisySameMonth(FViewMonth, AValue) then
  begin
    FViewMonth := StartOfTheMonth(AValue);
    FHotItem := -1;
    Repaint;
  end;
end;

procedure TDaisyFmxCalendar.SetSelected(const AValue: TDateTime);
begin
  if FSelected <> AValue then
  begin
    FSelected := DateOf(AValue);
    if FSelected <> 0 then
      FViewMonth := StartOfTheMonth(FSelected);
    SelectionChanged;
  end;
end;

procedure TDaisyFmxCalendar.SetRangeStart(const AValue: TDateTime);
begin
  if FRangeStart <> AValue then
  begin
    FRangeStart := DateOf(AValue);
    if (FRangeStart <> 0) and not (csLoading in ComponentState) then
      FViewMonth := StartOfTheMonth(FRangeStart);
    SelectionChanged;
  end;
end;

procedure TDaisyFmxCalendar.SetRangeEnd(const AValue: TDateTime);
begin
  if FRangeEnd <> AValue then
  begin
    FRangeEnd := DateOf(AValue);
    SelectionChanged;
  end;
end;

procedure TDaisyFmxCalendar.SetMode(const AValue: TDaisyCalendarSelection);
begin
  if FMode <> AValue then
  begin
    FMode := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxCalendar.SetFirstDay(const AValue: TDaisyWeekDay);
begin
  if FFirstDay <> AValue then
  begin
    FFirstDay := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxCalendar.SetShowOutside(const AValue: Boolean);
begin
  if FShowOutside <> AValue then
  begin
    FShowOutside := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxCalendar.SetHotItem(const AValue: Integer);
begin
  if FHotItem <> AValue then
  begin
    FHotItem := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxCalendar.NextMonth;
begin
  ViewMonth := IncMonth(FViewMonth, 1);
end;

procedure TDaisyFmxCalendar.PreviousMonth;
begin
  ViewMonth := IncMonth(FViewMonth, -1);
end;

procedure TDaisyFmxCalendar.GoToday;
begin
  ViewMonth := DateOf(Now);
end;

function TDaisyFmxCalendar.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxCalendar.DefaultContentPadding: Integer;
begin
  Result := 12;
end;

function TDaisyFmxCalendar.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := Theme.Base300;
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxCalendar.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyFmxCalendar.ArrowRect(ANext: Boolean): TRectF;
var
  LInner: TRectF;
begin
  LInner := ContentRect;
  if ANext then
    Result := RectF(LInner.Right - CHeaderHeight, LInner.Top, LInner.Right, LInner.Top + CHeaderHeight)
  else
    Result := RectF(LInner.Left, LInner.Top, LInner.Left + CHeaderHeight, LInner.Top + CHeaderHeight);
end;

function TDaisyFmxCalendar.CellRect(AIndex: Integer): TRectF;
var
  LInner: TRectF;
  LW, LH, LTop: Single;
begin
  LInner := ContentRect;
  LTop := LInner.Top + CHeaderHeight + CWeekRowHeight;
  LW := LInner.Width / 7;
  LH := (LInner.Bottom - LTop) / 6;
  Result := RectF(LInner.Left + (AIndex mod 7) * LW, LTop + (AIndex div 7) * LH,
    LInner.Left + (AIndex mod 7 + 1) * LW, LTop + (AIndex div 7 + 1) * LH);
end;

function TDaisyFmxCalendar.CellDate(AIndex: Integer): TDateTime;
begin
  Result := DaisyCalendarCellDate(FViewMonth, FFirstDay, AIndex);
end;

function TDaisyFmxCalendar.HitItem(X, Y: Single): Integer;
var
  I: Integer;
  LPt: TPointF;
begin
  Result := -1;
  LPt := PointF(X, Y);
  if ArrowRect(False).Contains(LPt) then
    Exit(100);
  if ArrowRect(True).Contains(LPt) then
    Exit(101);
  for I := 0 to DaisyCalendarCells - 1 do
    if CellRect(I).Contains(LPt) then
    begin
      if FShowOutside or DaisySameMonth(CellDate(I), FViewMonth) then
        Result := I;
      Exit;
    end;
end;

function TDaisyFmxCalendar.IsEnd(ADate: TDateTime): Boolean;
begin
  if FMode = csSingle then
    Result := (FSelected <> 0) and SameDate(ADate, FSelected)
  else
    Result := ((FRangeStart <> 0) and SameDate(ADate, FRangeStart))
      or ((FRangeEnd <> 0) and SameDate(ADate, FRangeEnd));
end;

function TDaisyFmxCalendar.InRange(ADate: TDateTime): Boolean;
begin
  Result := (FMode = csRange) and (FRangeStart <> 0) and (FRangeEnd <> 0)
    and (ADate > FRangeStart) and (ADate < FRangeEnd);
end;

function TDaisyFmxCalendar.AccentPalette: TDaisyPalette;
begin
  if Variant = dvDefault then
  begin
    Result.Fill := Theme.BaseContent;
    Result.Content := Theme.Base100;
  end
  else
    Result := DaisyVariantPalette(Theme, Variant);
end;

procedure TDaisyFmxCalendar.PickDate(ADate: TDateTime);
begin
  ADate := DateOf(ADate);
  FViewMonth := StartOfTheMonth(ADate);
  if FMode = csSingle then
    FSelected := ADate
  else if (FRangeStart = 0) or (FRangeEnd <> 0) then
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
  SelectionChanged;
end;

procedure TDaisyFmxCalendar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LItem: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button <> TMouseButton.mbLeft) or (csDesigning in ComponentState) then
    Exit;
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

procedure TDaisyFmxCalendar.DatePicked(ADate: TDateTime);
begin
end;

procedure TDaisyFmxCalendar.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited MouseMove(Shift, X, Y);
  SetHotItem(HitItem(X, Y));
end;

procedure TDaisyFmxCalendar.DoMouseLeave;
begin
  inherited DoMouseLeave;
  SetHotItem(-1);
end;

procedure TDaisyFmxCalendar.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  LBase: TDateTime;
  LStep: Integer;
begin
  inherited KeyDown(Key, KeyChar, Shift);
  case Key of
    vkPrior:
      begin
        PreviousMonth;
        Key := 0;
      end;
    vkNext:
      begin
        NextMonth;
        Key := 0;
      end;
    vkLeft, vkRight, vkUp, vkDown:
      begin
        case Key of
          vkLeft: LStep := -1;
          vkRight: LStep := 1;
          vkUp: LStep := -7;
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

procedure TDaisyFmxCalendar.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  inherited MouseWheel(Shift, WheelDelta, Handled);
  if not Handled then
  begin
    if WheelDelta > 0 then
      PreviousMonth
    else
      NextMonth;
    Handled := True;
  end;
end;

procedure TDaisyFmxCalendar.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LAccent: TDaisyPalette;
  LCell, LBox, LBand, LText, LArrow: TRectF;
  LDate: TDateTime;
  LInner: TRectF;
  I, LFont: Integer;
  LRadius: Single;
  LInMonth, LEnd: Boolean;
  LColor: TAlphaColor;
  LPath: TDaisyIconPaths;
begin
  LAccent := AccentPalette;
  LInner := ContentRect;
  LRadius := Theme.RadiusField;
  LFont := DaisyFontSize(SizeKind);

  for I := 0 to 1 do
  begin
    LArrow := ArrowRect(I = 1);
    if FHotItem = 100 + I then
      FillRound(LArrow, LRadius, Theme.Base200);
    LBox := LArrow;
    LBox.Inflate(-LBox.Width * 0.3, -LBox.Height * 0.3);
    if I = 0 then
      LPath := [[PointF(15, 5), PointF(8, 12), PointF(15, 19)]]
    else
      LPath := [[PointF(9, 5), PointF(16, 12), PointF(9, 19)]];
    DrawPolylines(LPath, LBox, Theme.BaseContent, 2);
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
    if InRange(LDate) then
    begin
      LBand := RectF(LCell.Left, LBox.Top, LCell.Right, LBox.Bottom);
      FillRound(LBand, 0, DaisyWithAlpha(LAccent.Fill, 0.18));
    end;
    if LEnd then
      FillRound(LBox, LRadius, LAccent.Fill)
    else if FHotItem = I then
      FillRound(LBox, LRadius, Theme.Base200);
    if SameDate(LDate, Now) and not LEnd then
      StrokeRound(LBox, LRadius, DaisyWithAlpha(Theme.BaseContent, 0.5), 1, False);
  end;

  LText := RectF(LInner.Left + CHeaderHeight, LInner.Top, LInner.Right - CHeaderHeight,
    LInner.Top + CHeaderHeight);
  DrawText(DaisyMonthTitle(FViewMonth), LText, Theme.BaseContent, LFont, True,
    TTextAlign.Center, TTextAlign.Center, False);

  for I := 0 to 6 do
  begin
    LCell := CellRect(I);
    LText := RectF(LCell.Left, LInner.Top + CHeaderHeight, LCell.Right,
      LInner.Top + CHeaderHeight + CWeekRowHeight);
    DrawText(DaisyWeekDayCaption(FFirstDay, I), LText, DaisyWithAlpha(Theme.BaseContent, 0.6),
      LFont - 2, False, TTextAlign.Center, TTextAlign.Center, False);
  end;

  for I := 0 to DaisyCalendarCells - 1 do
  begin
    LDate := CellDate(I);
    LInMonth := DaisySameMonth(LDate, FViewMonth);
    if (not LInMonth) and (not FShowOutside) then
      Continue;
    LCell := CellRect(I);
    if IsEnd(LDate) then
      LColor := LAccent.Content
    else if LInMonth then
      LColor := Theme.BaseContent
    else
      LColor := DaisyWithAlpha(Theme.BaseContent, 0.35);
    DrawText(IntToStr(DayOf(LDate)), LCell, LColor, LFont, SameDate(LDate, Now) and IsEnd(LDate),
      TTextAlign.Center, TTextAlign.Center, False);
  end;
end;

end.
