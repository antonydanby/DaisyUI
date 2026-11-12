unit Daisy.VCL.Fab;

{
  TDaisyFloatingActionButton - a round main button that expands to a speed dial
  of action buttons (see daisyui.com/components/fab). The control grows in
  Direction when opened and returns to its original bounds when closed, so at
  design time only the main button is shown. Item glyphs (Caption) are drawn
  through Direct2D so emoji work.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Controls,
  Daisy.Theme, Daisy.Items, Daisy.VCL.Control;

type
  TDaisyFloatingActionButton = class(TDaisyControl)
  strict private
    FItems: TDaisyItems;
    FDirection: TDaisyFabDirection;
    FOpen: Boolean;
    FCaption: string;
    FRestore: TRect;
    FHotIndex: Integer; // -2 none, -1 main button, 0.. item
    FOnItemClick: TDaisyItemClickEvent;
    procedure SetItems(const Value: TDaisyItems);
    procedure SetDirection(const Value: TDaisyFabDirection);
    procedure SetCaption(const Value: string);
    procedure SetOpen(const Value: Boolean);
    function Diameter: Integer;
    function Gap: Integer;
    function LabelFontSize: Integer;
    function LabelWidth: Integer;
    function MainRect: TRect;
    function ArcRadius: Integer;
    function ItemRect(AIndex: Integer): TRect;
    function LabelRect(AIndex: Integer): TRect;
    function HitTestAt(const APoint: TPoint): Integer;
    procedure SetHotIndex(const Value: Integer);
    procedure ItemsChanged(Sender: TObject);
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    function DefaultShadowSize: Integer; override;
    procedure Loaded; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Toggle;
    property IsOpen: Boolean read FOpen write SetOpen;
  published
    property Caption: string read FCaption write SetCaption;
    property Items: TDaisyItems read FItems write SetItems;
    property Direction: TDaisyFabDirection read FDirection write SetDirection default fdUp;
    property OnItemClick: TDaisyItemClickEvent read FOnItemClick write FOnItemClick;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SysUtils, System.Math, System.UITypes, Vcl.Graphics;

const
  NoHot = -2;
  PlusShift = 3; // px to lift the '+' glyph to the visual centre
  MainHot = -1;

{ TDaisyFloatingActionButton }

constructor TDaisyFloatingActionButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FDirection := fdUp;
  FCaption := '+';
  FHotIndex := NoHot;
  TabStop := True;
  Variant := dvPrimary;
  SetBounds(Left, Top, Diameter + 2 * ResolvedShadowSize, Diameter + 2 * ResolvedShadowSize);
end;

destructor TDaisyFloatingActionButton.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TDaisyFloatingActionButton.DefaultShadowSize: Integer;
begin
  Result := 0; // the floating action button is flat (no shadow)
end;

procedure TDaisyFloatingActionButton.Loaded;
begin
  inherited;
  // SizeKind does not resize while loading, so re-fit the stored bounds
  SizeChanged;
end;

function TDaisyFloatingActionButton.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := inherited DefaultStyleColors(AState);
end;

function TDaisyFloatingActionButton.Diameter: Integer;
begin
  Result := ScaleValue(DaisyFieldHeight(SizeKind) + 8);
end;

function TDaisyFloatingActionButton.Gap: Integer;
begin
  Result := ScaleValue(10);
end;

function TDaisyFloatingActionButton.LabelFontSize: Integer;
begin
  Result := DaisyFontSize(dzSM);
end;

function TDaisyFloatingActionButton.LabelWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  if not (FDirection in [fdUp, fdDown]) then
    Exit;
  Canvas.Font.Assign(Font);
  Canvas.Font.Height := -ScaleValue(LabelFontSize);
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Description <> '' then
      Result := Max(Result, Canvas.TextWidth(FItems[I].Description) + ScaleValue(24));
end;

procedure TDaisyFloatingActionButton.SizeChanged;
var
  LSize: Integer;
begin
  if FOpen then
    Exit;
  LSize := Diameter + 2 * ResolvedShadowSize;
  SetBounds(Left, Top, LSize, LSize);
end;

{ Layout (client coordinates, main button anchored in a corner) }

function TDaisyFloatingActionButton.MainRect: TRect;
var
  LShadow, D: Integer;
begin
  LShadow := ResolvedShadowSize;
  D := Diameter;
  case FDirection of
    fdUp, fdArc: Result := Rect(ClientWidth - LShadow - D, ClientHeight - LShadow - D, ClientWidth - LShadow, ClientHeight - LShadow);
    fdDown: Result := Rect(ClientWidth - LShadow - D, LShadow, ClientWidth - LShadow, LShadow + D);
    fdLeft: Result := Rect(ClientWidth - LShadow - D, LShadow, ClientWidth - LShadow, LShadow + D);
  else
    Result := Rect(LShadow, LShadow, LShadow + D, LShadow + D);
  end;
end;

// Radius at which neighbouring actions on the quarter circle keep a gap between them
function TDaisyFloatingActionButton.ArcRadius: Integer;
var
  LMin, LHalfStep: Double;
begin
  LMin := Diameter + Gap;
  Result := Ceil(LMin);
  if FItems.Count > 1 then
  begin
    LHalfStep := Pi / 4 / (FItems.Count - 1);
    Result := Max(Result, Ceil(LMin / (2 * Sin(LHalfStep))));
  end;
end;

function TDaisyFloatingActionButton.ItemRect(AIndex: Integer): TRect;
var
  LMain: TRect;
  LStep: Integer;
  LAngle: Double;
begin
  LMain := MainRect;
  LStep := (AIndex + 1) * (Diameter + Gap);
  Result := LMain;
  if FDirection = fdArc then
  begin
    // 0 = straight up, Pi/2 = straight left
    if FItems.Count > 1 then
      LAngle := AIndex * (Pi / 2) / (FItems.Count - 1)
    else
      LAngle := Pi / 4;
    OffsetRect(Result, -Round(ArcRadius * Sin(LAngle)), -Round(ArcRadius * Cos(LAngle)));
    Exit;
  end;
  case FDirection of
    fdUp: OffsetRect(Result, 0, -LStep);
    fdDown: OffsetRect(Result, 0, LStep);
    fdLeft: OffsetRect(Result, -LStep, 0);
  else
    OffsetRect(Result, LStep, 0);
  end;
end;

function TDaisyFloatingActionButton.LabelRect(AIndex: Integer): TRect;
var
  LItem: TRect;
  LWidth: Integer;
begin
  LItem := ItemRect(AIndex);
  Canvas.Font.Assign(Font);
  Canvas.Font.Height := -ScaleValue(LabelFontSize);
  LWidth := Canvas.TextWidth(FItems[AIndex].Description) + ScaleValue(24);
  Result := Rect(LItem.Left - Gap - LWidth, LItem.Top + (Diameter - ScaleValue(32)) div 2,
    LItem.Left - Gap, 0);
  Result.Bottom := Result.Top + ScaleValue(32);
end;

function TDaisyFloatingActionButton.HitTestAt(const APoint: TPoint): Integer;
var
  I: Integer;
begin
  Result := NoHot;
  if PtInRect(MainRect, APoint) then
    Exit(MainHot);
  if not FOpen then
    Exit;
  for I := 0 to FItems.Count - 1 do
    if PtInRect(ItemRect(I), APoint) or
       ((FItems[I].Description <> '') and (FDirection in [fdUp, fdDown]) and PtInRect(LabelRect(I), APoint)) then
      Exit(I);
end;

procedure TDaisyFloatingActionButton.SetOpen(const Value: Boolean);
var
  LSpan, LLabels, LNewW, LNewH: Integer;
  LRight, LBottom, LNewLeft: Integer;
  LAnchorRight: Boolean;
begin
  if (FOpen = Value) or (csDesigning in ComponentState) or (csLoading in ComponentState) then
    Exit;
  if Value and (FItems.Count = 0) then
    Exit;
  if Value then
  begin
    FRestore := BoundsRect;
    LSpan := FItems.Count * (Diameter + Gap);
    LLabels := LabelWidth;
    LNewW := Width;
    LNewH := Height;
    LRight := Left + Width;
    LBottom := Top + Height;
    FOpen := True;
    case FDirection of
      fdUp, fdDown:
        begin
          LNewW := Width + IfThen(LLabels > 0, LLabels + Gap, 0);
          LNewH := Height + LSpan;
        end;
      fdLeft, fdRight:
        LNewW := Width + LSpan;
      fdArc:
        begin
          LNewW := Width + ArcRadius;
          LNewH := Height + ArcRadius;
        end;
    end;
    // The main button sits on the logical right for up/down/arc/left; mirroring puts it on the
    // physical left in right-to-left mode, so the opposite physical edge must stay fixed
    LAnchorRight := (FDirection in [fdUp, fdDown, fdLeft, fdArc]) <> IsRTL;
    if LAnchorRight then
      LNewLeft := LRight - LNewW
    else
      LNewLeft := Left;
    if FDirection in [fdUp, fdArc] then
      SetBounds(LNewLeft, LBottom - LNewH, LNewW, LNewH)
    else
      SetBounds(LNewLeft, Top, LNewW, LNewH);
  end
  else
  begin
    FOpen := False;
    BoundsRect := FRestore;
  end;
  FHotIndex := NoHot;
  Invalidate;
end;

procedure TDaisyFloatingActionButton.Toggle;
begin
  SetOpen(not FOpen);
end;

{ Properties }

procedure TDaisyFloatingActionButton.SetItems(const Value: TDaisyItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFloatingActionButton.SetDirection(const Value: TDaisyFabDirection);
begin
  if FDirection <> Value then
  begin
    SetOpen(False);
    FDirection := Value;
    Invalidate;
  end;
end;

procedure TDaisyFloatingActionButton.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Invalidate;
  end;
end;

procedure TDaisyFloatingActionButton.ItemsChanged(Sender: TObject);
begin
  if FOpen then
    SetOpen(False);
  Invalidate;
end;

procedure TDaisyFloatingActionButton.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Invalidate;
  end;
end;

{ Input }

procedure TDaisyFloatingActionButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SetHotIndex(HitTestAt(Point(X, Y)));
end;

procedure TDaisyFloatingActionButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHotIndex(NoHot);
end;

procedure TDaisyFloatingActionButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LHit: Integer;
  LItem: TDaisyItem;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  LHit := HitTestAt(Point(X, Y));
  if LHit = MainHot then
  begin
    Toggle;
    Click;
  end
  else if (LHit >= 0) and FOpen then
  begin
    LItem := FItems[LHit];
    if LItem.Enabled then
    begin
      SetOpen(False);
      if Assigned(LItem.OnClick) then
        LItem.OnClick(LItem);
      if Assigned(FOnItemClick) then
        FOnItemClick(Self, LItem);
    end;
  end;
end;

procedure TDaisyFloatingActionButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_ESCAPE) and FOpen then
  begin
    SetOpen(False);
    Key := 0;
  end;
end;

procedure TDaisyFloatingActionButton.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if (Key = ' ') or (Key = #13) then
  begin
    Toggle;
    Key := #0;
  end;
end;

procedure TDaisyFloatingActionButton.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  SetOpen(False);
end;

{ Painting }

procedure TDaisyFloatingActionButton.Paint;
var
  LGraphics: TGPGraphics;
  LColors: TDaisyColors;
  LMain, LRect: TRect;
  LRadius: Single;
  I: Integer;
  LItemBack: TAlphaColor;
  LShift: Integer;
begin
  LColors := ResolveColors;
  LMain := MainRect;
  LItemBack := Theme.Base100;

  LGraphics := NewGraphics;
  try
    // Item buttons (and labels) first so the main button sits on top
    if FOpen then
      for I := 0 to FItems.Count - 1 do
      begin
        LRect := ItemRect(I);
        LRadius := Diameter / 2;
        FillRoundRect(LGraphics, RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom), LRadius,
          DaisyMix(Theme.Base300, $FF000000, 0.25));
        FillRoundRect(LGraphics, RectF(LRect.Left + 1, LRect.Top + 1, LRect.Right - 1, LRect.Bottom - 1), LRadius - 1,
          IfThen(I = FHotIndex, DaisyMix(LItemBack, Theme.BaseContent, 0.1), LItemBack));
        if (FItems[I].Description <> '') and (FDirection in [fdUp, fdDown]) then
        begin
          LRect := LabelRect(I);
          FillRoundRect(LGraphics, RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom),
            ScaleValue(Theme.RadiusField), LItemBack);
        end;
      end;

    LRadius := Diameter / 2;
    FillRoundRect(LGraphics, RectF(LMain.Left, LMain.Top, LMain.Right, LMain.Bottom), LRadius, LColors.Background);
  finally
    LGraphics.Free; // flush before Direct2D / GDI text
  end;

  if FOpen then
    for I := 0 to FItems.Count - 1 do
    begin
      LRect := ItemRect(I);
      if FItems[I].Enabled then
        DrawEmoji(FItems[I].Caption, LRect, Theme.BaseContent, DaisyFontSize(SizeKind) * 3 div 2)
      else
        DrawEmoji(FItems[I].Caption, LRect, DaisyWithAlpha(Theme.BaseContent, 0.35), DaisyFontSize(SizeKind) * 3 div 2);
      if (FItems[I].Description <> '') and (FDirection in [fdUp, fdDown]) then
        DrawText(FItems[I].Description, LabelRect(I), Theme.BaseContent, LabelFontSize, False,
          DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;

  if FOpen then
    DrawEmoji(#$2715, LMain, LColors.Text, DaisyFontSize(SizeKind)) // half-size close glyph
  else if FCaption = '+' then
  begin
    // the font's line spacing leaves a text '+' below the true centre
    LShift := ScaleValue(PlusShift);
    DrawEmoji(FCaption, Rect(LMain.Left, LMain.Top - LShift, LMain.Right, LMain.Bottom - LShift),
      LColors.Text, DaisyFontSize(SizeKind) * 2);
  end
  else
    DrawEmoji(FCaption, LMain, LColors.Text, DaisyFontSize(SizeKind) * 2);
end;

end.
