unit Daisy.VCL.Pagination;

{
  TDaisyPagination - the DaisyUI "pagination": a row of (usually joined) buttons with previous / next
  buttons, the page numbers around the current page and "..." where pages are left out. With
  ShowPageNumbers off only the previous / next buttons are shown, sharing the width equally.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections,
  Vcl.Controls, Daisy.Theme, Daisy.Navigation, Daisy.VCL.Control;

type

  TDaisyPagination = class(TDaisyControl)
  strict private
    type
      TCellKind = (ckPrev, ckNext, ckPage, ckGap);
      TCell = record
        Kind: TCellKind;
        Page: Integer;
        Rect: TRect;
        Text: string;
        Enabled: Boolean;
        Active: Boolean;
      end;
    var
      FPageCount: Integer;
      FCurrentPage: Integer;
      FSiblings: Integer;
      FBoundary: Integer;
      FShowPageNumbers: Boolean;
      FShowPrevNext: Boolean;
      FPrevCaption: string;
      FNextCaption: string;
      FJoined: Boolean;
      FAlignment: TAlignment;
      FAutoFit: Boolean;
      FUpdating: Boolean;
      FOnChange: TNotifyEvent;
    procedure SetPageCount(const Value: Integer);
    procedure SetCurrentPage(const Value: Integer);
    procedure SetSiblings(const Value: Integer);
    procedure SetBoundary(const Value: Integer);
    procedure SetShowPageNumbers(const Value: Boolean);
    procedure SetShowPrevNext(const Value: Boolean);
    procedure SetPrevCaption(const Value: string);
    procedure SetNextCaption(const Value: string);
    procedure SetJoined(const Value: Boolean);
    procedure SetAlignment(const Value: TAlignment);
    procedure SetAutoFit(const Value: Boolean);
    function DisplayCaption(const ACaption: string): string;
    function BuildCells: TArray<TCell>;
    function ButtonGap: Integer;
    function GroupWidth(const ACells: TArray<TCell>): Integer;
    procedure UpdateSize;
    procedure Activate(const ACell: TCell);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    function TrackedItemAt(const APoint: TPoint): Integer; override;
    procedure TrackedItemChanged; override;
    procedure SizeChanged; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Style;
    property PageCount: Integer read FPageCount write SetPageCount default 10;
    property CurrentPage: Integer read FCurrentPage write SetCurrentPage default 1;
    // Pages shown on each side of the current page
    property Siblings: Integer read FSiblings write SetSiblings default 1;
    // Pages always shown at the start and the end
    property Boundary: Integer read FBoundary write SetBoundary default 1;
    property ShowPageNumbers: Boolean read FShowPageNumbers write SetShowPageNumbers default True;
    property ShowPrevNext: Boolean read FShowPrevNext write SetShowPrevNext default True;
    property PrevCaption: string read FPrevCaption write SetPrevCaption;
    property NextCaption: string read FNextCaption write SetNextCaption;
    property Joined: Boolean read FJoined write SetJoined default True;
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    // The control is as wide as its buttons; its height always follows SizeKind
    property AutoFit: Boolean read FAutoFit write SetAutoFit default False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CGap = 4;
  CPrevDefault = #$00AB;
  CNextDefault = #$00BB;

type
  // Rounded rectangle with independent radii on the leading and trailing sides, so that joined
  // buttons only round the ends of the group
  TDaisySideRoundPath = class
    class function Build(const ARect: TRectF; ALeft, ARight: Single): TGPGraphicsPath;
  end;

class function TDaisySideRoundPath.Build(const ARect: TRectF; ALeft, ARight: Single): TGPGraphicsPath;
var
  LLeft, LRight: Single;
begin
  LLeft := EnsureRange(ALeft, 0, Min(ARect.Width, ARect.Height) / 2);
  LRight := EnsureRange(ARight, 0, Min(ARect.Width, ARect.Height) / 2);
  Result := TGPGraphicsPath.Create;
  Result.StartFigure;
  Result.AddLine(ARect.Left + LLeft, ARect.Top, ARect.Right - LRight, ARect.Top);
  if LRight > 0 then
    Result.AddArc(ARect.Right - 2 * LRight, ARect.Top, 2 * LRight, 2 * LRight, 270, 90);
  Result.AddLine(ARect.Right, ARect.Top + LRight, ARect.Right, ARect.Bottom - LRight);
  if LRight > 0 then
    Result.AddArc(ARect.Right - 2 * LRight, ARect.Bottom - 2 * LRight, 2 * LRight, 2 * LRight, 0, 90);
  Result.AddLine(ARect.Right - LRight, ARect.Bottom, ARect.Left + LLeft, ARect.Bottom);
  if LLeft > 0 then
    Result.AddArc(ARect.Left, ARect.Bottom - 2 * LLeft, 2 * LLeft, 2 * LLeft, 90, 90);
  Result.AddLine(ARect.Left, ARect.Bottom - LLeft, ARect.Left, ARect.Top + LLeft);
  if LLeft > 0 then
    Result.AddArc(ARect.Left, ARect.Top, 2 * LLeft, 2 * LLeft, 180, 90);
  Result.CloseFigure;
end;

{ TDaisyPagination }

constructor TDaisyPagination.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPageCount := 10;
  FCurrentPage := 1;
  FSiblings := 1;
  FBoundary := 1;
  FShowPageNumbers := True;
  FShowPrevNext := True;
  FPrevCaption := CPrevDefault;
  FNextCaption := CNextDefault;
  FJoined := True;
  FAlignment := taLeftJustify;
  SetBounds(Left, Top, 380, ScaleValue(DaisyFieldHeight(SizeKind)));
end;

function TDaisyPagination.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyPagination.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyPagination.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyPagination.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyPagination.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyPagination.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyPagination.SetPageCount(const Value: Integer);
begin
  if Value <> FPageCount then
  begin
    FPageCount := Max(1, Value);
    FCurrentPage := EnsureRange(FCurrentPage, 1, FPageCount);
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetCurrentPage(const Value: Integer);
var
  LValue: Integer;
begin
  if csLoading in ComponentState then
    LValue := Value
  else
    LValue := EnsureRange(Value, 1, FPageCount);
  if FCurrentPage <> LValue then
  begin
    FCurrentPage := LValue;
    UpdateSize;
    Invalidate;
    if Assigned(FOnChange) and not (csLoading in ComponentState) then
      FOnChange(Self);
  end;
end;

procedure TDaisyPagination.SetSiblings(const Value: Integer);
begin
  if FSiblings <> Max(0, Value) then
  begin
    FSiblings := Max(0, Value);
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetBoundary(const Value: Integer);
begin
  if FBoundary <> Max(0, Value) then
  begin
    FBoundary := Max(0, Value);
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetShowPageNumbers(const Value: Boolean);
begin
  if FShowPageNumbers <> Value then
  begin
    FShowPageNumbers := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetShowPrevNext(const Value: Boolean);
begin
  if FShowPrevNext <> Value then
  begin
    FShowPrevNext := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetPrevCaption(const Value: string);
begin
  if FPrevCaption <> Value then
  begin
    FPrevCaption := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetNextCaption(const Value: string);
begin
  if FNextCaption <> Value then
  begin
    FNextCaption := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetJoined(const Value: Boolean);
begin
  if FJoined <> Value then
  begin
    FJoined := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TDaisyPagination.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

function TDaisyPagination.ButtonGap: Integer;
begin
  if FJoined then
    Result := 0
  else
    Result := ScaleValue(CGap);
end;

function TDaisyPagination.DisplayCaption(const ACaption: string): string;
begin
  // the default guillemets point the other way when the order of the buttons is mirrored
  Result := ACaption;
  if IsRTL then
    if ACaption = CPrevDefault then
      Result := CNextDefault
    else if ACaption = CNextDefault then
      Result := CPrevDefault;
end;

function TDaisyPagination.BuildCells: TArray<TCell>;
var
  LList: TList<TCell>;
  LPages: TArray<Integer>;
  LCell: TCell;
  LHeight, LPadX, LFont, LX, LWidth, LGap, LBorderOverlap, I, LLast: Integer;
  LPageText: string;

  function MakeWidth(const AText: string): Integer;
  begin
    Result := Max(LHeight, MeasureTextWidth(AText, LFont, False) + 2 * LPadX);
  end;

  procedure Add(AKind: TCellKind; APage: Integer; const AText: string; AEnabled: Boolean;
    AEqualWidth: Integer);
  begin
    LCell := Default(TCell);
    LCell.Kind := AKind;
    LCell.Page := APage;
    LCell.Text := AText;
    LCell.Enabled := AEnabled and Enabled and (AKind <> ckGap);
    LCell.Active := (AKind = ckPage) and (APage = FCurrentPage);
    if AEqualWidth > 0 then
      LWidth := AEqualWidth
    else
      LWidth := MakeWidth(AText);
    LCell.Rect := Rect(LX, 0, LX + LWidth, LHeight);
    LList.Add(LCell);
    // a joined outline shares its border with the neighbour
    LX := LX + LWidth + LGap;
  end;

begin
  LList := TList<TCell>.Create;
  try
    LHeight := ScaleValue(DaisyFieldHeight(SizeKind));
    LPadX := ScaleValue(DaisyFieldPaddingX(SizeKind));
    LFont := DaisyFontSize(SizeKind);
    LGap := ButtonGap;
    LBorderOverlap := 0;
    if FJoined and (Style <> dsSolid) then
      LBorderOverlap := -ScaleValue(Theme.BorderWidth);
    LGap := LGap + LBorderOverlap;
    LX := 0;
    if FShowPageNumbers then
    begin
      if FShowPrevNext then
        Add(ckPrev, FCurrentPage - 1, DisplayCaption(FPrevCaption), FCurrentPage > 1, 0);
      LPages := DaisyPaginationPages(FCurrentPage, FPageCount, FSiblings, FBoundary);
      for I := 0 to High(LPages) do
        if LPages[I] = CDaisyPageGap then
          Add(ckGap, 0, '...', False, 0)
        else
        begin
          LPageText := IntToStr(LPages[I]);
          Add(ckPage, LPages[I], LPageText, True, 0);
        end;
      if FShowPrevNext then
        Add(ckNext, FCurrentPage + 1, DisplayCaption(FNextCaption), FCurrentPage < FPageCount, 0);
    end
    else if FShowPrevNext then
    begin
      // two equal buttons across the whole control
      LWidth := (Width - LGap) div 2;
      Add(ckPrev, FCurrentPage - 1, FPrevCaption, FCurrentPage > 1, LWidth);
      Add(ckNext, FCurrentPage + 1, FNextCaption, FCurrentPage < FPageCount, LWidth);
    end;
    LLast := LList.Count - 1;
    // align the group inside the control
    if (LLast >= 0) and FShowPageNumbers then
    begin
      LWidth := LList[LLast].Rect.Right;
      case FAlignment of
        taCenter: LX := (Width - LWidth) div 2;
        taRightJustify: LX := Width - LWidth;
      else
        LX := 0;
      end;
      if LX <> 0 then
        for I := 0 to LLast do
        begin
          LCell := LList[I];
          OffsetRect(LCell.Rect, LX, 0);
          LList[I] := LCell;
        end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TDaisyPagination.GroupWidth(const ACells: TArray<TCell>): Integer;
begin
  if Length(ACells) = 0 then
    Result := 0
  else
    Result := ACells[High(ACells)].Rect.Right;
end;

procedure TDaisyPagination.UpdateSize;
var
  LW, LH: Integer;
  LCells: TArray<TCell>;
begin
  if FUpdating or (csLoading in ComponentState) then
    Exit;
  LH := ScaleValue(DaisyFieldHeight(SizeKind));
  LW := Width;
  if FAutoFit and FShowPageNumbers then
  begin
    LCells := BuildCells;
    LW := GroupWidth(LCells);
  end;
  if (Align in [alLeft, alRight, alClient]) then
    LH := Height;
  if (Align in [alTop, alBottom, alClient]) then
    LW := Width;
  if (LW <> Width) or (LH <> Height) then
  begin
    FUpdating := True;
    try
      SetBounds(Left, Top, LW, LH);
    finally
      FUpdating := False;
    end;
  end;
end;

procedure TDaisyPagination.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisyPagination.Resize;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyPagination.Loaded;
begin
  inherited;
  FCurrentPage := EnsureRange(FCurrentPage, 1, FPageCount);
  UpdateSize;
end;

function TDaisyPagination.TrackedItemAt(const APoint: TPoint): Integer;
var
  LCells: TArray<TCell>;
  I: Integer;
begin
  Result := -1;
  LCells := BuildCells;
  for I := 0 to High(LCells) do
    if PtInRect(LCells[I].Rect, APoint) then
      Exit(I);
end;

procedure TDaisyPagination.TrackedItemChanged;
var
  LCells: TArray<TCell>;
begin
  LCells := BuildCells;
  SetItemCursor((TrackedItem >= 0) and (TrackedItem <= High(LCells)) and LCells[TrackedItem].Enabled);
  inherited;
end;

procedure TDaisyPagination.Activate(const ACell: TCell);
begin
  if ACell.Enabled and (ACell.Kind <> ckGap) then
    SetCurrentPage(ACell.Page);
end;

procedure TDaisyPagination.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LCells: TArray<TCell>;
  LIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or (csDesigning in ComponentState) then
    Exit;
  LCells := BuildCells;
  LIndex := TrackedItemAt(MirrorPoint(Point(X, Y)));
  if LIndex >= 0 then
    Activate(LCells[LIndex]);
end;

procedure TDaisyPagination.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TDaisyPagination.KeyDown(var Key: Word; Shift: TShiftState);
var
  LStep: Integer;
begin
  inherited KeyDown(Key, Shift);
  LStep := 0;
  case Key of
    VK_LEFT: LStep := IfThen(IsRTL, 1, -1);
    VK_RIGHT: LStep := IfThen(IsRTL, -1, 1);
    VK_UP: LStep := -1;
    VK_DOWN: LStep := 1;
    VK_HOME:
      begin
        SetCurrentPage(1);
        Key := 0;
      end;
    VK_END:
      begin
        SetCurrentPage(FPageCount);
        Key := 0;
      end;
  end;
  if LStep <> 0 then
  begin
    SetCurrentPage(FCurrentPage + LStep);
    Key := 0;
  end;
end;

procedure TDaisyPagination.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LCells: TArray<TCell>;
  LGraphics: TGPGraphics;
  LColors: array of TDaisyColors;
  LState: TDaisyState;
  LRect: TRectF;
  LPath: TGPGraphicsPath;
  LBrush: TGPSolidBrush;
  LPen: TGPPen;
  LRadius, LBorder, I, LFirst, LLast: Integer;
  LRoundLeft, LRoundRight: Single;
begin
  LCells := BuildCells;
  if Length(LCells) = 0 then
    Exit;
  LRadius := ScaleValue(Theme.RadiusField);
  LBorder := Max(1, ScaleValue(Theme.BorderWidth));
  LFirst := 0;
  LLast := High(LCells);
  SetLength(LColors, Length(LCells));
  for I := 0 to High(LCells) do
  begin
    if not LCells[I].Enabled and not LCells[I].Active then
      LState := dstDisabled
    else if (I = TrackedItem) and Pressed and not LCells[I].Active then
      LState := dstPressed
    else if (I = TrackedItem) and not LCells[I].Active then
      LState := dstHover
    else
      LState := dstNormal;
    if LCells[I].Active then
    begin
      if Variant = dvDefault then
        LColors[I] := DaisyResolveColors(Theme, dvDefault, Style, dstPressed)
      else
        LColors[I] := DaisyResolveColors(Theme, Variant, dsSolid, dstNormal);
    end
    else
      LColors[I] := DaisyResolveColors(Theme, dvDefault, Style, LState);
    if Style = dsGhost then
      LColors[I].Dashed := False;
  end;

  LGraphics := NewGraphics;
  try
    for I := 0 to High(LCells) do
    begin
      LRect := RectF(LCells[I].Rect.Left, LCells[I].Rect.Top, LCells[I].Rect.Right,
        LCells[I].Rect.Bottom);
      if FJoined then
      begin
        if I = LFirst then LRoundLeft := LRadius else LRoundLeft := 0;
        if I = LLast then LRoundRight := LRadius else LRoundRight := 0;
      end
      else
      begin
        LRoundLeft := LRadius;
        LRoundRight := LRadius;
      end;
      if TAlphaColorRec(LColors[I].Background).A > 0 then
      begin
        LPath := TDaisySideRoundPath.Build(LRect, LRoundLeft, LRoundRight);
        LBrush := TGPSolidBrush.Create(LColors[I].Background);
        try
          LGraphics.FillPath(LBrush, LPath);
        finally
          LBrush.Free;
          LPath.Free;
        end;
      end;
      if TAlphaColorRec(LColors[I].Border).A > 0 then
      begin
        LRect.Inflate(-LBorder / 2, -LBorder / 2);
        LPath := TDaisySideRoundPath.Build(LRect, Max(0, LRoundLeft - LBorder / 2),
          Max(0, LRoundRight - LBorder / 2));
        LPen := TGPPen.Create(LColors[I].Border, LBorder);
        try
          if LColors[I].Dashed then
            LPen.SetDashStyle(DashStyleDash);
          LGraphics.DrawPath(LPen, LPath);
        finally
          LPen.Free;
          LPath.Free;
        end;
      end;
    end;
    if Focused then
      for I := 0 to High(LCells) do
        if LCells[I].Active then
          DrawItemFocus(LGraphics, RectF(LCells[I].Rect.Left, LCells[I].Rect.Top,
            LCells[I].Rect.Right, LCells[I].Rect.Bottom), LRadius);
  finally
    LGraphics.Free;
  end;

  for I := 0 to High(LCells) do
    DrawText(LCells[I].Text, LCells[I].Rect, LColors[I].Text, DaisyFontSize(SizeKind), False,
      DT_CENTER or DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS);
end;

end.
