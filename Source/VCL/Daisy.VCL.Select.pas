unit Daisy.VCL.Select;

{
  TDaisySelect - the DaisyUI "select": a field that opens a list of choices.

  Items holds the choices (a choice may contain emoji, drawn in colour);
  ItemIndex is the chosen one (-1 shows Placeholder). Optional extras: a
  Legend above the field, a Hint below it, a LabelText inside the field
  (before / after the value) or floating on the border, and an Emoji / SVG icon
  at the start of the field.

  The list is a borderless, non-activating popup window, like the dropdown
  menu. It is only created when first opened.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Daisy.Theme, Daisy.Widgets, Daisy.VCL.Control;

const
  WM_DAISY_SELECT = WM_APP + 42;

type
  TDaisyIndexEvent = procedure(Sender: TObject; AIndex: Integer) of object;

  TDaisySelectPopup = class(TDaisyControl)
  strict private
    FItems: TStrings;
    FHotIndex: Integer;
    FSelected: Integer;
    FIndicator: TDaisySelectIndicator;
    FItemHeight: Integer;
    FFirst: Integer;
    FMaxRows: Integer;
    FDragging: Boolean;
    FInButtonUp: Boolean;
    FOnSelect: TDaisyIndexEvent;
    FOnClosed: TNotifyEvent;
    function VisibleRows: Integer;
    function Scrollable: Boolean;
    function ThumbRect: TRect;
    procedure SetFirst(AValue: Integer);
    procedure ScrollToY(AY: Integer);
    procedure SetHotIndex(const Value: Integer);
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    function ItemRect(AIndex: Integer): TRect;
    function ItemAt(const APoint: TPoint): Integer;
    function Padding: Integer;
    procedure DrawTick(const AItemRect: TRect; AColor: TAlphaColor);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    function MeasureHeight(ACount, AItemHeight: Integer): Integer;
    procedure Popup(AItems: TStrings; ASelected, AItemHeight, ALeft, ATop, AWidth: Integer);
    procedure Close;
    procedure MoveHot(ADelta: Integer);
    procedure CommitHot;
    procedure Scroll(ADelta: Integer);
    property MaxRows: Integer read FMaxRows write FMaxRows;
    property Indicator: TDaisySelectIndicator read FIndicator write FIndicator;
    property OnSelect: TDaisyIndexEvent read FOnSelect write FOnSelect;
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
  end;

  TDaisySelect = class(TDaisyControl)
  strict private
    FItems: TStrings;
    FItemIndex: Integer;
    FPlaceholder: string;
    FLabelText: string;
    FLabelMode: TDaisySelectLabelMode;
    FSelectedIndicator: TDaisySelectIndicator;
    FLegend: string;
    FHint: string;
    FIcon: TDaisyIconSource;
    FAutoFit: Boolean;
    FDropDownRows: Integer;
    FUpdating: Boolean;
    FPopup: TDaisySelectPopup;
    FClosedTick: Cardinal;
    FOnChange: TNotifyEvent;
    procedure SetItems(const Value: TStrings);
    procedure SetItemIndex(const Value: Integer);
    procedure SetPlaceholder(const Value: string);
    procedure SetLabelText(const Value: string);
    procedure SetLabelMode(const Value: TDaisySelectLabelMode);
    procedure SetLegend(const Value: string);
    procedure SetHint(const Value: string);
    procedure SetAutoFit(const Value: Boolean);
    function GetEmoji: string;
    procedure SetEmoji(const Value: string);
    function GetSVG: TStrings;
    procedure SetSVG(const Value: TStrings);
    function GetIsOpen: Boolean;
    function GetText: string;
    procedure ItemsChanged(Sender: TObject);
    procedure IconChanged(Sender: TObject);
    procedure PopupSelect(Sender: TObject; AIndex: Integer);
    procedure PopupClosed(Sender: TObject);
    procedure GetLayout(out ALegend, AField, AHint: TRect);
    procedure UpdateSize;
    function PadX: Integer;
    function RowHeight: Integer;
    procedure WMDropDown(var Message: TMessage); message WM_DAISY_SELECT;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
    procedure SetDropDownRows(const Value: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    procedure DropDown;
    procedure CloseUp;
    property IsOpen: Boolean read GetIsOpen;
    // The chosen item, or '' when nothing is chosen
    property Text: string read GetText;
  published
    property Items: TStrings read FItems write SetItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    // Shown while ItemIndex is -1
    property Placeholder: string read FPlaceholder write SetPlaceholder;
    // Text inside the field (before / after the value) or floating on its border
    property LabelText: string read FLabelText write SetLabelText;
    property LabelMode: TDaisySelectLabelMode read FLabelMode write SetLabelMode default slmNone;
    // How the chosen item is marked in the list: nothing, bold text or a tick
    property SelectedIndicator: TDaisySelectIndicator read FSelectedIndicator write FSelectedIndicator default siTick;
    // Fieldset legend above the field
    property Legend: string read FLegend write SetLegend;
    // Small helper text below the field
    property Hint: string read FHint write SetHint;
    // Shown at the start of the field
    property Emoji: string read GetEmoji write SetEmoji;
    // Paste SVG markup or load an .svg file; shown at the start of the field
    property SVG: TStrings read GetSVG write SetSVG;
    // The height follows the field, legend and hint; the width is yours
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    // The list stops growing at this many rows and scrolls
    property DropDownRows: Integer read FDropDownRows write SetDropDownRows default 8;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{ TDaisySelectPopup }

constructor TDaisySelectPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHotIndex := -1;
  FSelected := -1;
  FMaxRows := 8;
  ControlStyle := ControlStyle - [csParentBackground] + [csOpaque];
  Visible := False;
  TabStop := False;
end;

procedure TDaisySelectPopup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_CLIPCHILDREN;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  Params.WndParent := GetDesktopWindow;
end;

procedure TDaisySelectPopup.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TDaisySelectPopup.WMLButtonUp(var Message: TWMLButtonUp);
begin
  // TControl releases its mouse capture on button-up, which would close the list
  FInButtonUp := True;
  try
    inherited;
  finally
    FInButtonUp := False;
  end;
  if Visible and HandleAllocated and (GetCapture <> Handle) then
    MouseCapture := True;
end;

function TDaisySelectPopup.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  Scroll(-Sign(WheelDelta) * 3);
  Result := True;
end;

procedure TDaisySelectPopup.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if Visible and not FInButtonUp and (HWND(Message.LParam) <> Handle) then
    Close;
end;

function TDaisySelectPopup.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisySelectPopup.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.15);
  Result.Text := Theme.BaseContent;
end;

function TDaisySelectPopup.Padding: Integer;
begin
  Result := ScaleValue(4);
end;

function TDaisySelectPopup.VisibleRows: Integer;
begin
  if FItems = nil then
    Exit(0);
  Result := Min(FItems.Count, Max(1, FMaxRows));
end;

function TDaisySelectPopup.Scrollable: Boolean;
begin
  Result := (FItems <> nil) and (FItems.Count > Max(1, FMaxRows));
end;

function TDaisySelectPopup.ThumbRect: TRect;
var
  LTrack, LThumb, LTop: Integer;
begin
  LTrack := VisibleRows * FItemHeight;
  LThumb := Max(ScaleValue(16), LTrack * VisibleRows div Max(1, FItems.Count));
  LTop := Padding + (LTrack - LThumb) * FFirst div Max(1, FItems.Count - VisibleRows);
  Result := Rect(ClientWidth - ScaleValue(8), LTop, ClientWidth - ScaleValue(3), LTop + LThumb);
end;

procedure TDaisySelectPopup.SetFirst(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 0, Max(0, FItems.Count - VisibleRows));
  if AValue <> FFirst then
  begin
    FFirst := AValue;
    Invalidate;
  end;
end;

procedure TDaisySelectPopup.Scroll(ADelta: Integer);
begin
  if Scrollable then
    SetFirst(FFirst + ADelta);
end;

procedure TDaisySelectPopup.ScrollToY(AY: Integer);
var
  LTrack, LThumb: Integer;
begin
  LTrack := VisibleRows * FItemHeight;
  LThumb := ThumbRect.Height;
  SetFirst(Round((AY - Padding - LThumb / 2) / Max(1, LTrack - LThumb) *
    (FItems.Count - VisibleRows)));
end;

function TDaisySelectPopup.ItemRect(AIndex: Integer): TRect;
var
  LRight: Integer;
begin
  LRight := ClientWidth - Padding;
  if Scrollable then
    Dec(LRight, ScaleValue(8));
  Result := Rect(Padding, Padding + (AIndex - FFirst) * FItemHeight, LRight,
    Padding + (AIndex - FFirst + 1) * FItemHeight);
end;

function TDaisySelectPopup.ItemAt(const APoint: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  if FItems = nil then
    Exit;
  for I := FFirst to Min(FItems.Count, FFirst + VisibleRows) - 1 do
    if PtInRect(ItemRect(I), APoint) then
      Exit(I);
end;

function TDaisySelectPopup.MeasureHeight(ACount, AItemHeight: Integer): Integer;
begin
  Result := 2 * Padding + Min(ACount, Max(1, FMaxRows)) * AItemHeight;
end;

procedure TDaisySelectPopup.Popup(AItems: TStrings; ASelected, AItemHeight, ALeft, ATop,
  AWidth: Integer);
var
  LHeight, LDiameter: Integer;
  LRegion: HRGN;
begin
  FItems := AItems;
  FSelected := ASelected;
  FHotIndex := ASelected;
  FItemHeight := AItemHeight;
  FDragging := False;
  FFirst := 0;
  LHeight := MeasureHeight(FItems.Count, FItemHeight);
  if ASelected >= VisibleRows then
    FFirst := EnsureRange(ASelected - VisibleRows div 2, 0, FItems.Count - VisibleRows);
  Color := DaisyToColor(Theme.Base100);
  HandleNeeded;
  SetBounds(ALeft, ATop, AWidth, LHeight);
  LDiameter := 2 * ResolvedCornerRadius;
  LRegion := CreateRoundRectRgn(0, 0, AWidth + 1, LHeight + 1, LDiameter, LDiameter);
  SetWindowRgn(Handle, LRegion, False);
  Visible := True;
  SetWindowPos(Handle, HWND_TOPMOST, ALeft, ATop, AWidth, LHeight,
    SWP_NOACTIVATE or SWP_SHOWWINDOW);
  Invalidate;
  MouseCapture := True;
end;

procedure TDaisySelectPopup.Close;
begin
  if not Visible then
    Exit;
  Visible := False;
  if HandleAllocated then
    ShowWindow(Handle, SW_HIDE);
  if GetCapture = Handle then
    ReleaseCapture;
  if Assigned(FOnClosed) then
    FOnClosed(Self);
end;

procedure TDaisySelectPopup.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Invalidate;
  end;
end;

procedure TDaisySelectPopup.MoveHot(ADelta: Integer);
begin
  if FItems.Count = 0 then
    Exit;
  if FHotIndex < 0 then
    SetHotIndex(IfThen(ADelta > 0, 0, FItems.Count - 1))
  else
    SetHotIndex((FHotIndex + ADelta + FItems.Count) mod FItems.Count);
  if FHotIndex < FFirst then
    SetFirst(FHotIndex)
  else if FHotIndex >= FFirst + VisibleRows then
    SetFirst(FHotIndex - VisibleRows + 1);
end;

procedure TDaisySelectPopup.CommitHot;
var
  LIndex: Integer;
begin
  LIndex := FHotIndex;
  if (LIndex < 0) or (LIndex >= FItems.Count) then
    Exit;
  Close;
  if Assigned(FOnSelect) then
    FOnSelect(Self, LIndex);
end;

procedure TDaisySelectPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (X < 0) or (Y < 0) or (X >= ClientWidth) or (Y >= ClientHeight) then
    Close
  else if Scrollable and (X >= ClientWidth - ScaleValue(10)) then
  begin
    FDragging := True;
    ScrollToY(Y);
  end;
end;

procedure TDaisySelectPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
begin
  if FDragging then
  begin
    FDragging := False;
    Exit;
  end;
  LIndex := ItemAt(Point(X, Y));
  if (Button = mbLeft) and (LIndex >= 0) then
  begin
    SetHotIndex(LIndex);
    CommitHot;
  end;
end;

procedure TDaisySelectPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FDragging then
    ScrollToY(Y)
  else
    SetHotIndex(ItemAt(Point(X, Y)));
end;

procedure TDaisySelectPopup.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  I, LLast: Integer;
  LRect, LText, LThumb: TRect;
  LGraphics: TGPGraphics;
begin
  LLast := Min(FItems.Count, FFirst + VisibleRows) - 1;
  LGraphics := NewGraphics;
  try
    for I := FFirst to LLast do
    begin
      LRect := ItemRect(I);
      if I = FHotIndex then
        FillRoundRect(LGraphics, RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom),
          Theme.RadiusField, DaisyWithAlpha(Theme.BaseContent, 0.1))
      else if I = FSelected then
        FillRoundRect(LGraphics, RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom),
          Theme.RadiusField, DaisyWithAlpha(Theme.BaseContent, 0.05));
    end;
    if Scrollable then
    begin
      LThumb := ThumbRect;
      FillRoundRect(LGraphics, RectF(LThumb.Left, LThumb.Top, LThumb.Right, LThumb.Bottom),
        LThumb.Width / 2, DaisyWithAlpha(Theme.BaseContent, 0.35));
    end;
  finally
    LGraphics.Free;
  end;

  for I := FFirst to LLast do
  begin
    LText := ItemRect(I);
    InflateRect(LText, -ScaleValue(10), 0);
    if FIndicator = siTick then
      Dec(LText.Right, ScaleValue(24));
    DrawRichText(FItems[I], LText, AColors.Text, DaisyFontSize(SizeKind),
      (I = FSelected) and (FIndicator = siBold),
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
  end;

  if (FIndicator = siTick) and (FSelected >= FFirst) and (FSelected <= LLast) then
    DrawTick(ItemRect(FSelected), AColors.Text);
end;

procedure TDaisySelectPopup.DrawTick(const AItemRect: TRect; AColor: TAlphaColor);
var
  LGraphics: TGPGraphics;
  LPen: TGPPen;
  LSize, LX, LY: Single;
begin
  LSize := ScaleValue(12);
  LX := AItemRect.Right - ScaleValue(10) - LSize - IfThen(Scrollable, ScaleValue(8), 0);
  LY := AItemRect.Top + (AItemRect.Height - LSize) / 2;
  LGraphics := NewGraphics;
  try
    LPen := TGPPen.Create(AColor, Max(1.5, ScaleValue(2)));
    try
      LPen.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
      LPen.SetLineJoin(LineJoinRound);
      LGraphics.DrawLine(LPen, LX, LY + LSize * 0.55, LX + LSize * 0.38, LY + LSize * 0.9);
      LGraphics.DrawLine(LPen, LX + LSize * 0.38, LY + LSize * 0.9, LX + LSize, LY + LSize * 0.1);
    finally
      LPen.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;

{ TDaisySelect }

constructor TDaisySelect.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TStringList.Create;
  TStringList(FItems).OnChange := ItemsChanged;
  FIcon := TDaisyIconSource.Create(IconChanged);
  FItemIndex := -1;
  FSelectedIndicator := siTick;
  FPlaceholder := 'Pick one';
  FAutoFit := True;
  FDropDownRows := 8;
  TabStop := True;
  SetBounds(Left, Top, 192, ScaleValue(DaisyFieldHeight(dzMD)));
  UpdateSize;
end;

destructor TDaisySelect.Destroy;
begin
  FIcon.Free;
  FItems.Free;
  inherited Destroy;
end;

function TDaisySelect.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisySelect.DrawsFocusRing: Boolean;
begin
  Result := False; // the field border shows the focus
end;

function TDaisySelect.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisySelect.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisySelect.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisySelect.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TDaisySelect.SetItemIndex(const Value: Integer);
var
  LValue: Integer;
begin
  LValue := Value;
  if not (csLoading in ComponentState) then
    LValue := EnsureRange(Value, -1, FItems.Count - 1);
  if FItemIndex <> LValue then
  begin
    FItemIndex := LValue;
    Invalidate;
    if not (csLoading in ComponentState) and Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TDaisySelect.SetPlaceholder(const Value: string);
begin
  if FPlaceholder <> Value then
  begin
    FPlaceholder := Value;
    Invalidate;
  end;
end;

procedure TDaisySelect.SetLabelText(const Value: string);
begin
  if FLabelText <> Value then
  begin
    FLabelText := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisySelect.SetLabelMode(const Value: TDaisySelectLabelMode);
begin
  if FLabelMode <> Value then
  begin
    FLabelMode := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisySelect.SetLegend(const Value: string);
begin
  if FLegend <> Value then
  begin
    FLegend := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisySelect.SetHint(const Value: string);
begin
  if FHint <> Value then
  begin
    FHint := Value;
    UpdateSize;
    Invalidate;
  end;
end;

procedure TDaisySelect.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

function TDaisySelect.GetEmoji: string;
begin
  Result := FIcon.Emoji;
end;

procedure TDaisySelect.SetEmoji(const Value: string);
begin
  FIcon.Emoji := Value;
end;

function TDaisySelect.GetSVG: TStrings;
begin
  Result := FIcon.SVG;
end;

procedure TDaisySelect.SetSVG(const Value: TStrings);
begin
  FIcon.SVG := Value;
end;

function TDaisySelect.GetIsOpen: Boolean;
begin
  Result := (FPopup <> nil) and FPopup.Visible;
end;

function TDaisySelect.GetText: string;
begin
  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    Result := FItems[FItemIndex]
  else
    Result := '';
end;

procedure TDaisySelect.ItemsChanged(Sender: TObject);
begin
  if (not (csLoading in ComponentState)) and (FItemIndex >= FItems.Count) then
    FItemIndex := FItems.Count - 1;
  Invalidate;
end;

procedure TDaisySelect.IconChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TDaisySelect.SizeChanged;
begin
  UpdateSize;
end;

procedure TDaisySelect.Loaded;
begin
  inherited;
  if FItemIndex >= FItems.Count then
    FItemIndex := FItems.Count - 1;
  UpdateSize;
end;

procedure TDaisySelect.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

function TDaisySelect.PadX: Integer;
begin
  Result := ScaleValue(Max(8, DaisyFieldPaddingX(SizeKind) * 3 div 4));
end;

function TDaisySelect.RowHeight: Integer;
begin
  Result := Max(ScaleValue(24), ScaleValue(DaisyFieldHeight(SizeKind)) - ScaleValue(6));
end;

procedure TDaisySelect.GetLayout(out ALegend, AField, AHint: TRect);
var
  LTop: Integer;
begin
  LTop := 0;
  ALegend := Rect(0, 0, 0, 0);
  AHint := Rect(0, 0, 0, 0);
  if FLegend <> '' then
  begin
    ALegend := Rect(0, 0, Width, ScaleValue(20));
    LTop := ScaleValue(24);
  end;
  if (FLabelMode = slmFloating) and (FLabelText <> '') then
    Inc(LTop, ScaleValue(8));
  AField := Rect(0, LTop, Width, LTop + ScaleValue(DaisyFieldHeight(SizeKind)));
  if FHint <> '' then
    AHint := Rect(0, AField.Bottom + ScaleValue(4), Width, AField.Bottom + ScaleValue(22));
end;

procedure TDaisySelect.UpdateSize;
var
  LLegend, LField, LHint: TRect;
  LHeight: Integer;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  GetLayout(LLegend, LField, LHint);
  if FHint <> '' then
    LHeight := LHint.Bottom
  else
    LHeight := LField.Bottom;
  // Width/Height rather than Client*: reading Client* in the constructor would create the HWND before Parent is set
  if LHeight = Height then
    Exit;
  FUpdating := True;
  try
    SetBounds(Left, Top, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisySelect.DropDown;
var
  LLegend, LField, LHint, LWork: TRect;
  LOrigin: TPoint;
  LHeight, LY, LGap: Integer;
begin
  if IsOpen or (FItems.Count = 0) or (csDesigning in ComponentState) or not HandleAllocated then
    Exit;
  if FPopup = nil then
  begin
    FPopup := TDaisySelectPopup.Create(Self);
    FPopup.OnSelect := PopupSelect;
    FPopup.OnClosed := PopupClosed;
  end;
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;
  FPopup.Font.Assign(Font);
  FPopup.MaxRows := FDropDownRows;
  FPopup.Indicator := FSelectedIndicator;
  GetLayout(LLegend, LField, LHint);
  LGap := ScaleValue(4);
  LHeight := FPopup.MeasureHeight(FItems.Count, RowHeight);
  LOrigin := ClientToScreen(Point(LField.Left, LField.Bottom));
  LWork := Screen.MonitorFromWindow(Handle).WorkareaRect;
  LY := LOrigin.Y + LGap;
  if LY + LHeight > LWork.Bottom then
    LY := ClientToScreen(Point(0, LField.Top)).Y - LHeight - LGap; // flip above
  LY := Max(LWork.Top, Min(LY, LWork.Bottom - LHeight));
  FPopup.Popup(FItems, FItemIndex, RowHeight, LOrigin.X, LY, LField.Width);
  if CanFocus and not Focused then
    SetFocus;
  Invalidate;
end;

procedure TDaisySelect.SetDropDownRows(const Value: Integer);
begin
  FDropDownRows := Max(1, Value);
end;

function TDaisySelect.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if IsOpen then
  begin
    FPopup.Scroll(-Sign(WheelDelta) * 3);
    Result := True;
  end
  else
    Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
end;

procedure TDaisySelect.CloseUp;
begin
  if IsOpen then
    FPopup.Close;
end;

procedure TDaisySelect.PopupSelect(Sender: TObject; AIndex: Integer);
begin
  SetItemIndex(AIndex);
end;

procedure TDaisySelect.PopupClosed(Sender: TObject);
begin
  FClosedTick := GetTickCount;
  Invalidate;
end;

procedure TDaisySelect.Click;
begin
  inherited Click;
  if not Enabled then
    Exit;
  if IsOpen then
    CloseUp
  else if (GetTickCount - FClosedTick > 300) and HandleAllocated then
    PostMessage(Handle, WM_DAISY_SELECT, 0, 0); // after the mouse-up so the capture sticks
end;

procedure TDaisySelect.WMDropDown(var Message: TMessage);
begin
  DropDown;
end;

procedure TDaisySelect.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TDaisySelect.CMExit(var Message: TCMExit);
begin
  inherited;
  CloseUp;
end;

procedure TDaisySelect.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if IsOpen then
  begin
    case Key of
      VK_DOWN: FPopup.MoveHot(1);
      VK_UP: FPopup.MoveHot(-1);
      VK_RETURN, VK_SPACE: FPopup.CommitHot;
      VK_ESCAPE: FPopup.Close;
    else
      inherited KeyDown(Key, Shift);
      Exit;
    end;
    Key := 0;
    Exit;
  end;
  case Key of
    VK_F4, VK_SPACE, VK_RETURN: DropDown;
    VK_DOWN:
      if ssAlt in Shift then
        DropDown
      else
        SetItemIndex(Min(FItemIndex + 1, FItems.Count - 1));
    VK_UP: SetItemIndex(Max(FItemIndex - 1, 0));
  else
    inherited KeyDown(Key, Shift);
    Exit;
  end;
  Key := 0;
end;

procedure TDaisySelect.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LLegend, LField, LHint, LInner, LChevronBox, LLabelBox, LTextBox, LChip: TRect;
  LGraphics: TGPGraphics;
  LPath: TDaisyIconPaths;
  LTint, LBorder, LFill, LText, LDim: TAlphaColor;
  LRadius, LFont, LSmall, LPad, LIcon, LLabelW, LDivX, LBorderW: Integer;
  LBordered, LActive: Boolean;
  LPalette: TDaisyPalette;
  LShown: string;
  LChev: TRectF;
begin
  GetLayout(LLegend, LField, LHint);
  LFont := DaisyFontSize(SizeKind);
  LSmall := DaisyFontSize(dzSM);
  LRadius := ResolvedCornerRadius;
  LPad := PadX;
  LActive := Focused or IsOpen;

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
  if Hot and (Style = dsGhost) then
    LFill := DaisyWithAlpha(Theme.BaseContent, 0.06);
  LText := Theme.BaseContent;
  if not Enabled then
  begin
    LBorder := DaisyWithAlpha(Theme.BaseContent, 0.1);
    LFill := DaisyWithAlpha(Theme.BaseContent, 0.05);
    LText := DaisyWithAlpha(Theme.BaseContent, 0.3);
  end;
  LDim := DaisyWithAlpha(LText, 0.6);
  LBorderW := Max(1, ScaleValue(Theme.BorderWidth));

  // inner geometry
  LInner := LField;
  InflateRect(LInner, -LPad, 0);
  LChevronBox := Rect(LInner.Right - ScaleValue(LFont + 2), LField.Top, LInner.Right, LField.Bottom);
  LChevronBox.Top := LField.Top + (LField.Height - ScaleValue(LFont + 2)) div 2;
  LChevronBox.Bottom := LChevronBox.Top + ScaleValue(LFont + 2);
  LTextBox := Rect(LInner.Left, LField.Top, LChevronBox.Left - ScaleValue(6), LField.Bottom);
  LLabelW := 0;
  LDivX := -1;
  if (FLabelText <> '') and (FLabelMode in [slmBefore, slmAfter]) then
  begin
    LLabelW := MeasureTextWidth(FLabelText, LSmall, False);
    if FLabelMode = slmBefore then
    begin
      LLabelBox := Rect(LTextBox.Left, LField.Top, LTextBox.Left + LLabelW, LField.Bottom);
      LDivX := LLabelBox.Right + LPad div 2;
      LTextBox.Left := LDivX + LPad div 2 + 1;
    end
    else
    begin
      LLabelBox := Rect(LTextBox.Right - LLabelW, LField.Top, LTextBox.Right, LField.Bottom);
      LDivX := LLabelBox.Left - LPad div 2;
      LTextBox.Right := LDivX - LPad div 2;
    end;
  end;
  LIcon := 0;
  if not FIcon.IsEmpty then
  begin
    LIcon := ScaleValue(LFont + 4);
    LText := LText; // colour unchanged
  end;

  LGraphics := NewGraphics;
  try
    if TAlphaColorRec(LFill).A > 0 then
      FillRoundRect(LGraphics, RectF(LField.Left, LField.Top, LField.Right, LField.Bottom),
        LRadius, LFill);
    if LBordered or LActive then
      StrokeRoundRect(LGraphics, RectF(LField.Left, LField.Top, LField.Right, LField.Bottom),
        LRadius, LBorder, LBorderW, (Style = dsDash) and not LActive);

    if LDivX >= 0 then
      FillRoundRect(LGraphics, RectF(LDivX, LField.Top + LField.Height / 4, LDivX + 1,
        LField.Bottom - LField.Height / 4), 0, DaisyWithAlpha(Theme.BaseContent, 0.2));

    SetLength(LPath, 1);
    if IsOpen then
      LPath[0] := [PointF(6, 15), PointF(12, 9), PointF(18, 15)]
    else
      LPath[0] := [PointF(6, 9), PointF(12, 15), PointF(18, 9)];
    LChev := RectF(LChevronBox.Left, LChevronBox.Top, LChevronBox.Right, LChevronBox.Bottom);
    DrawPolylines(LGraphics, LPath, LChev, LDim, 2);

    if (FLabelText <> '') and (FLabelMode = slmFloating) then
    begin
      LChip := Rect(LField.Left + LPad - ScaleValue(4), LField.Top - ScaleValue(8),
        LField.Left + LPad + MeasureTextWidth(FLabelText, LSmall, False) + ScaleValue(4),
        LField.Top + ScaleValue(8));
      FillRoundRect(LGraphics, RectF(LChip.Left, LChip.Top, LChip.Right, LChip.Bottom), 0,
        Theme.Base100);
    end;
  finally
    LGraphics.Free; // flush before any GDI text
  end;

  if FLegend <> '' then
    DrawRichText(FLegend, LLegend, Theme.BaseContent, LSmall, True,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
  if FHint <> '' then
    DrawRichText(FHint, LHint, DaisyWithAlpha(Theme.BaseContent, 0.6), DaisyFontSize(dzXS), False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

  if (FLabelText <> '') and (FLabelMode = slmFloating) then
    DrawRichText(FLabelText, LChip, LDim, LSmall, False,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE)
  else if LLabelW > 0 then
    DrawRichText(FLabelText, LLabelBox, LDim, LSmall, False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  if LIcon > 0 then
  begin
    DrawGlyph(FIcon, Rect(LTextBox.Left, LField.Top + (LField.Height - LIcon) div 2,
      LTextBox.Left + LIcon, LField.Top + (LField.Height - LIcon) div 2 + LIcon), LText);
    LTextBox.Left := LTextBox.Left + LIcon + ScaleValue(8);
  end;

  LShown := GetText;
  if LShown = '' then
    DrawRichText(FPlaceholder, LTextBox, DaisyWithAlpha(LText, 0.5), LFont, False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS)
  else
    DrawRichText(LShown, LTextBox, LText, LFont, False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

end.
