unit Daisy.Calendars;

{
  Framework neutral date helpers for TDaisyCalendar (VCL) and TDaisyFmxCalendar (FMX).
  Must not reference Vcl.* or FMX.* units.
}

interface

uses
  System.SysUtils, System.Types, System.Math, System.DateUtils;

type
  TDaisyWeekDay = (wdMonday, wdTuesday, wdWednesday, wdThursday, wdFriday, wdSaturday, wdSunday);

  TDaisyCalendarSelection = (csSingle, csRange);

  // Where a popup opens relative to the control that owns it
  TDaisyPopupPlacement = (ppShowBelow, ppShowAbove, ppShowLeft, ppShowRight);

const
  DaisyCalendarCells = 42; // 6 weeks of 7 days

// Date shown in grid cell AIndex (0..41) for the month containing AMonth
function DaisyCalendarCellDate(AMonth: TDateTime; AFirstDay: TDaisyWeekDay; AIndex: Integer): TDateTime;
function DaisyFirstOfMonth(ADate: TDateTime): TDateTime;
function DaisyMonthTitle(ADate: TDateTime): string;
// Two letter weekday header for the column AColumn (0 = AFirstDay)
function DaisyWeekDayCaption(AFirstDay: TDaisyWeekDay; AColumn: Integer): string;
function DaisySameMonth(A, B: TDateTime): Boolean;

// Top left of a popup of the given size for the anchor rectangle. It flips to the opposite side when the
// requested side does not fit in AWork, and is finally clamped into AWork.
function DaisyPopupOrigin(const AAnchor, AWork: TRectF; APopupWidth, APopupHeight, AGap: Single;
  APlacement: TDaisyPopupPlacement): TPointF;
// '' = the system short date format; a zero date gives ''
function DaisyFormatPickerDate(ADate: TDateTime; const AFormat: string): string;
function DaisyTryParsePickerDate(const AText, AFormat: string; out ADate: TDateTime): Boolean;

implementation

function DaisyPopupOrigin(const AAnchor, AWork: TRectF; APopupWidth, APopupHeight, AGap: Single;
  APlacement: TDaisyPopupPlacement): TPointF;
var
  LPlacement: TDaisyPopupPlacement;

  function Candidate(APlace: TDaisyPopupPlacement): TPointF;
  begin
    case APlace of
      ppShowAbove: Result := PointF(AAnchor.Left, AAnchor.Top - AGap - APopupHeight);
      ppShowLeft: Result := PointF(AAnchor.Left - AGap - APopupWidth, AAnchor.Top);
      ppShowRight: Result := PointF(AAnchor.Right + AGap, AAnchor.Top);
    else
      Result := PointF(AAnchor.Left, AAnchor.Bottom + AGap);
    end;
  end;

  function Fits(APlace: TDaisyPopupPlacement): Boolean;
  var
    LPoint: TPointF;
  begin
    LPoint := Candidate(APlace);
    case APlace of
      ppShowAbove: Result := LPoint.Y >= AWork.Top;
      ppShowLeft: Result := LPoint.X >= AWork.Left;
      ppShowRight: Result := LPoint.X + APopupWidth <= AWork.Right;
    else
      Result := LPoint.Y + APopupHeight <= AWork.Bottom;
    end;
  end;

begin
  LPlacement := APlacement;
  if not Fits(LPlacement) then
  begin
    case LPlacement of
      ppShowAbove: LPlacement := ppShowBelow;
      ppShowLeft: LPlacement := ppShowRight;
      ppShowRight: LPlacement := ppShowLeft;
    else
      LPlacement := ppShowAbove;
    end;
    if not Fits(LPlacement) then
      LPlacement := APlacement;
  end;
  Result := Candidate(LPlacement);
  Result.X := Max(AWork.Left, Min(Result.X, AWork.Right - APopupWidth));
  Result.Y := Max(AWork.Top, Min(Result.Y, AWork.Bottom - APopupHeight));
end;

function DaisyFormatPickerDate(ADate: TDateTime; const AFormat: string): string;
begin
  if ADate = 0 then
    Exit('');
  if AFormat = '' then
    Result := FormatDateTime(FormatSettings.ShortDateFormat, ADate)
  else
    Result := FormatDateTime(AFormat, ADate);
end;

function DaisyTryParsePickerDate(const AText, AFormat: string; out ADate: TDateTime): Boolean;
var
  LSettings: TFormatSettings;
begin
  LSettings := FormatSettings;
  if AFormat <> '' then
    LSettings.ShortDateFormat := AFormat;
  Result := TryStrToDate(Trim(AText), ADate, LSettings);
  if Result then
    ADate := DateOf(ADate);
end;

function DaisyFirstOfMonth(ADate: TDateTime): TDateTime;
begin
  Result := StartOfTheMonth(ADate);
end;

function DaisyCalendarCellDate(AMonth: TDateTime; AFirstDay: TDaisyWeekDay; AIndex: Integer): TDateTime;
var
  LFirst: TDateTime;
  LOffset: Integer;
begin
  LFirst := StartOfTheMonth(AMonth);
  LOffset := (DayOfTheWeek(LFirst) - 1 - Ord(AFirstDay) + 7) mod 7;
  Result := LFirst - LOffset + AIndex;
end;

function DaisyMonthTitle(ADate: TDateTime): string;
begin
  Result := FormatSettings.LongMonthNames[MonthOf(ADate)] + ' ' + IntToStr(YearOf(ADate));
end;

function DaisyWeekDayCaption(AFirstDay: TDaisyWeekDay; AColumn: Integer): string;
var
  LDay: Integer;
begin
  LDay := (Ord(AFirstDay) + AColumn) mod 7; // 0 = Monday
  // FormatSettings day names start on Sunday (1)
  Result := Copy(FormatSettings.ShortDayNames[((LDay + 1) mod 7) + 1], 1, 2);
end;

function DaisySameMonth(A, B: TDateTime): Boolean;
begin
  Result := (YearOf(A) = YearOf(B)) and (MonthOf(A) = MonthOf(B));
end;

end.
