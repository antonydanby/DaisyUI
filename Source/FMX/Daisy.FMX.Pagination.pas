unit Daisy.FMX.Pagination;

{
  TDaisyFmxPagination - the DaisyUI "pagination": a row of (usually joined) buttons with previous / next
  buttons, the page numbers around the current page and "..." where pages are left out. With
  ShowPageNumbers off only the previous / next buttons are shown, sharing the width equally.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Graphics, Daisy.Theme,
  Daisy.Navigation, Daisy.FMX.Control;

type
  TDaisyFmxPagination = class(TDaisyControl)
  strict private
    type
      TCellKind = (ckPrev, ckNext, ckPage, ckGap);
      TCell = record
        Kind: TCellKind;
        Page: Integer;
        Rect: TRectF;
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
      FAlignment: TTextAlign;
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
    procedure SetAlignment(const Value: TTextAlign);
    procedure SetAutoFit(const Value: Boolean);
    function DisplayCaption(const ACaption: string): string;
    function BuildCells: TArray<TCell>;
    function ButtonGap: Single;
    procedure UpdateSize;
    procedure Activate(const ACell: TCell);
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    function TrackedItemAt(const APoint: TPointF): Integer; override;
    procedure TrackedItemChanged; override;
    procedure SizeChanged; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
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
    property Alignment: TTextAlign read FAlignment write SetAlignment default TTextAlign.Leading;
    // The control is as wide as its buttons; its height always follows SizeKind
    property AutoFit: Boolean read FAutoFit write SetAutoFit default False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  CGap = 4;
  CPrevDefault = #$00AB;
  CNextDefault = #$00BB;

// Rounded rectangle with independent radii on the leading and trailing sides, so that joined
// buttons only round the ends of the group
procedure BuildSideRoundPath(APath: TPathData; const ARect: TRectF; ALeft, ARight: Single);
var
  LLeft, LRight: Single;
begin
  LLeft := EnsureRange(ALeft, 0, System.Math.Min(ARect.Width, ARect.Height) / 2);
  LRight := EnsureRange(ARight, 0, System.Math.Min(ARect.Width, ARect.Height) / 2);
  APath.Clear;
  APath.MoveTo(PointF(ARect.Left + LLeft, ARect.Top));
  APath.LineTo(PointF(ARect.Right - LRight, ARect.Top));
  if LRight > 0 then
    APath.AddArc(PointF(ARect.Right - LRight, ARect.Top + LRight), PointF(LRight, LRight), 270, 90);
  APath.LineTo(PointF(ARect.Right, ARect.Bottom - LRight));
  if LRight > 0 then
    APath.AddArc(PointF(ARect.Right - LRight, ARect.Bottom - LRight), PointF(LRight, LRight), 0, 90);
  APath.LineTo(PointF(ARect.Left + LLeft, ARect.Bottom));
  if LLeft > 0 then
    APath.AddArc(PointF(ARect.Left + LLeft, ARect.Bottom - LLeft), PointF(LLeft, LLeft), 90, 90);
  APath.LineTo(PointF(ARect.Left, ARect.Top + LLeft));
  if LLeft > 0 then
    APath.AddArc(PointF(ARect.Left + LLeft, ARect.Top + LLeft), PointF(LLeft, LLeft), 180, 90);
  APath.ClosePath;
end;

{ TDaisyFmxPagination }

constructor TDaisyFmxPagination.Create(AOwner: TComponent);
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
  FAlignment := TTextAlign.Leading;
  CanFocus := True;
  TabStop := True;
  SetBounds(Position.X, Position.Y, 380, DaisyFieldHeight(SizeKind));
end;

function TDaisyFmxPagination.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxPagination.DrawsFocusRing: Boolean;
begin
  Result := False;
end;

function TDaisyFmxPagination.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxPagination.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxPagination.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxPagination.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxPagination.SetPageCount(const Value: Integer);
begin
  if Value <> FPageCount then
  begin
    FPageCount := System.Math.Max(1, Value);
    FCurrentPage := EnsureRange(FCurrentPage, 1, FPageCount);
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetCurrentPage(const Value: Integer);
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
    Repaint;
    if Assigned(FOnChange) and not (csLoading in ComponentState) then
      FOnChange(Self);
  end;
end;

procedure TDaisyFmxPagination.SetSiblings(const Value: Integer);
begin
  if FSiblings <> System.Math.Max(0, Value) then
  begin
    FSiblings := System.Math.Max(0, Value);
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetBoundary(const Value: Integer);
begin
  if FBoundary <> System.Math.Max(0, Value) then
  begin
    FBoundary := System.Math.Max(0, Value);
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetShowPageNumbers(const Value: Boolean);
begin
  if FShowPageNumbers <> Value then
  begin
    FShowPageNumbers := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetShowPrevNext(const Value: Boolean);
begin
  if FShowPrevNext <> Value then
  begin
    FShowPrevNext := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetPrevCaption(const Value: string);
begin
  if FPrevCaption <> Value then
  begin
    FPrevCaption := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetNextCaption(const Value: string);
begin
  if FNextCaption <> Value then
  begin
    FNextCaption := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetJoined(const Value: Boolean);
begin
  if FJoined <> Value then
  begin
    FJoined := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetAlignment(const Value: TTextAlign);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxPagination.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

function TDaisyFmxPagination.ButtonGap: Single;
begin
  if FJoined then
    Result := 0
  else
    Result := CGap;
end;

function TDaisyFmxPagination.DisplayCaption(const ACaption: string): string;
begin
  // the default guillemets point the other way when the order of the buttons is mirrored
  Result := ACaption;
  if IsRTL then
    if ACaption = CPrevDefault then
      Result := CNextDefault
    else if ACaption = CNextDefault then
      Result := CPrevDefault;
end;

function TDaisyFmxPagination.BuildCells: TArray<TCell>;
var
  LList: TList<TCell>;
  LPages: TArray<Integer>;
  LCell: TCell;
  LHeight, LPadX, LX, LWidth, LGap: Single;
  LFont, I, LLast: Integer;

  function MakeWidth(const AText: string): Single;
  begin
    Result := System.Math.Max(LHeight, MeasureTextWidth(AText, LFont, False) + 2 * LPadX);
  end;

  procedure Add(AKind: TCellKind; APage: Integer; const AText: string; AEnabled: Boolean;
    AEqualWidth: Single);
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
    LCell.Rect := RectF(LX, 0, LX + LWidth, LHeight);
    LList.Add(LCell);
    LX := LX + LWidth + LGap;
  end;

begin
  LList := TList<TCell>.Create;
  try
    LHeight := DaisyFieldHeight(SizeKind);
    LPadX := DaisyFieldPaddingX(SizeKind);
    LFont := DaisyFontSize(SizeKind);
    LGap := ButtonGap;
    // a joined outline shares its border with the neighbour
    if FJoined and (Style <> dsSolid) then
      LGap := LGap - Theme.BorderWidth;
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
          Add(ckPage, LPages[I], IntToStr(LPages[I]), True, 0);
      if FShowPrevNext then
        Add(ckNext, FCurrentPage + 1, DisplayCaption(FNextCaption), FCurrentPage < FPageCount, 0);
    end
    else if FShowPrevNext then
    begin
      // two equal buttons across the whole control
      LWidth := (Width - LGap) / 2;
      Add(ckPrev, FCurrentPage - 1, FPrevCaption, FCurrentPage > 1, LWidth);
      Add(ckNext, FCurrentPage + 1, FNextCaption, FCurrentPage < FPageCount, LWidth);
    end;
    LLast := LList.Count - 1;
    // align the group inside the control
    if (LLast >= 0) and FShowPageNumbers then
    begin
      LWidth := LList[LLast].Rect.Right;
      case FAlignment of
        TTextAlign.Center: LX := (Width - LWidth) / 2;
        TTextAlign.Trailing: LX := Width - LWidth;
      else
        LX := 0;
      end;
      if LX <> 0 then
        for I := 0 to LLast do
        begin
          LCell := LList[I];
          LCell.Rect.Offset(LX, 0);
          LList[I] := LCell;
        end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure TDaisyFmxPagination.UpdateSize;
var
  LW, LH: Single;
  LCells: TArray<TCell>;
begin
  if FUpdating or (csLoading in ComponentState) then
    Exit;
  LH := DaisyFieldHeight(SizeKind);
  LW := Width;
  if FAutoFit and FShowPageNumbers then
  begin
    LCells := BuildCells;
    if Length(LCells) > 0 then
      LW := LCells[High(LCells)].Rect.Right - LCells[0].Rect.Left;
  end;
  if Align in [TAlignLayout.Left, TAlignLayout.Right, TAlignLayout.Client] then
    LH := Height;
  if Align in [TAlignLayout.Top, TAlignLayout.Bottom, TAlignLayout.Client] then
    LW := Width;
  if not (SameValue(LW, Width) and SameValue(LH, Height)) then
  begin
    FUpdating := True;
    try
      SetBounds(Position.X, Position.Y, LW, LH);
    finally
      FUpdating := False;
    end;
  end;
end;

procedure TDaisyFmxPagination.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxPagination.Resize;
begin
  inherited;
  UpdateSize;
end;

procedure TDaisyFmxPagination.Loaded;
begin
  inherited;
  FCurrentPage := EnsureRange(FCurrentPage, 1, FPageCount);
  UpdateSize;
end;

function TDaisyFmxPagination.TrackedItemAt(const APoint: TPointF): Integer;
var
  LCells: TArray<TCell>;
  I: Integer;
begin
  Result := -1;
  LCells := BuildCells;
  for I := 0 to High(LCells) do
    if LCells[I].Rect.Contains(APoint) then
      Exit(I);
end;

procedure TDaisyFmxPagination.TrackedItemChanged;
var
  LCells: TArray<TCell>;
begin
  LCells := BuildCells;
  SetItemCursor((TrackedItem >= 0) and (TrackedItem <= High(LCells)) and LCells[TrackedItem].Enabled);
  inherited;
end;

procedure TDaisyFmxPagination.Activate(const ACell: TCell);
begin
  if ACell.Enabled and (ACell.Kind <> ckGap) then
    SetCurrentPage(ACell.Page);
end;

procedure TDaisyFmxPagination.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LCells: TArray<TCell>;
  LIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> TMouseButton.mbLeft) or (csDesigning in ComponentState) then
    Exit;
  SetFocus;
  LCells := BuildCells;
  LIndex := TrackedItemAt(PointF(X, Y));
  if LIndex >= 0 then
    Activate(LCells[LIndex]);
end;

procedure TDaisyFmxPagination.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  LStep: Integer;
  LHandled: Boolean;
begin
  LHandled := Enabled;
  LStep := 0;
  if LHandled then
    case Key of
      vkLeft: LStep := IfThen(IsRTL, 1, -1);
      vkRight: LStep := IfThen(IsRTL, -1, 1);
      vkUp: LStep := -1;
      vkDown: LStep := 1;
      vkHome: SetCurrentPage(1);
      vkEnd: SetCurrentPage(FPageCount);
    else
      LHandled := False;
    end;
  if LStep <> 0 then
    SetCurrentPage(FCurrentPage + LStep);
  if LHandled then
  begin
    Key := 0;
    KeyChar := #0;
  end
  else
    inherited KeyDown(Key, KeyChar, Shift);
end;

procedure TDaisyFmxPagination.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LCells: TArray<TCell>;
  LColors: array of TDaisyColors;
  LState: TDaisyState;
  LRect: TRectF;
  LPath: TPathData;
  LRadius, LBorder, LRoundLeft, LRoundRight: Single;
  I, LLast: Integer;
begin
  LCells := BuildCells;
  if Length(LCells) = 0 then
    Exit;
  LRadius := Theme.RadiusField;
  LBorder := System.Math.Max(1, Theme.BorderWidth);
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

  LPath := TPathData.Create;
  try
    for I := 0 to High(LCells) do
    begin
      LRect := LCells[I].Rect;
      if FJoined then
      begin
        if I = 0 then LRoundLeft := LRadius else LRoundLeft := 0;
        if I = LLast then LRoundRight := LRadius else LRoundRight := 0;
      end
      else
      begin
        LRoundLeft := LRadius;
        LRoundRight := LRadius;
      end;
      if TAlphaColorRec(LColors[I].Background).A > 0 then
      begin
        BuildSideRoundPath(LPath, LRect, LRoundLeft, LRoundRight);
        Canvas.Fill.Kind := TBrushKind.Solid;
        Canvas.Fill.Color := LColors[I].Background;
        Canvas.FillPath(LPath, AbsoluteOpacity);
      end;
      if TAlphaColorRec(LColors[I].Border).A > 0 then
      begin
        LRect.Inflate(-LBorder / 2, -LBorder / 2);
        BuildSideRoundPath(LPath, LRect, System.Math.Max(0, LRoundLeft - LBorder / 2),
          System.Math.Max(0, LRoundRight - LBorder / 2));
        Canvas.Stroke.Kind := TBrushKind.Solid;
        Canvas.Stroke.Color := LColors[I].Border;
        Canvas.Stroke.Thickness := LBorder;
        Canvas.Stroke.Join := TStrokeJoin.Round;
        if LColors[I].Dashed then
          Canvas.Stroke.Dash := TStrokeDash.Dash
        else
          Canvas.Stroke.Dash := TStrokeDash.Solid;
        Canvas.DrawPath(LPath, AbsoluteOpacity);
      end;
    end;
  finally
    LPath.Free;
  end;
  Canvas.Stroke.Dash := TStrokeDash.Solid;
  if IsFocused then
    for I := 0 to High(LCells) do
      if LCells[I].Active then
        DrawItemFocus(LCells[I].Rect, LRadius);

  for I := 0 to High(LCells) do
    DrawText(LCells[I].Text, LCells[I].Rect, LColors[I].Text, DaisyFontSize(SizeKind), False,
      TTextAlign.Center, TTextAlign.Center, False);
end;

end.
