unit Daisy.VCL.Dropdown;

{
  TDaisyDropdownMenu - a button that opens a menu of Items.

  The menu is a borderless, non-activating popup window so it can extend past
  the parent form. While open it owns the mouse capture: a click outside the
  menu closes it, a click on an item runs it. The menu is only created when it
  is first opened.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Daisy.Theme, Daisy.Items, Daisy.VCL.Control, Daisy.VCL.Button;

const
  WM_DAISY_DROPDOWN = WM_APP + 41;

type
  TDaisyDropdownPopup = class(TDaisyControl)
  strict private
    FItems: TDaisyItems;
    FHotIndex: Integer;
    FOnSelect: TDaisyItemClickEvent;
    FOnClosed: TNotifyEvent;
    procedure SetHotIndex(const Value: Integer);
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    function ItemHeight(AItem: TDaisyItem): Integer;
    function ItemRect(AIndex: Integer): TRect;
    function ItemAt(const APoint: TPoint): Integer;
    function Padding: Integer;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    function MeasureWidth(AItems: TDaisyItems): Integer;
    function MeasureHeight(AItems: TDaisyItems): Integer;
    procedure Popup(AItems: TDaisyItems; const ALeft, ATop, AWidth: Integer);
    procedure Close;
    // Moves the keyboard selection; ADelta is +1 / -1
    procedure MoveHot(ADelta: Integer);
    procedure CommitHot;
    property Items: TDaisyItems read FItems;
    property OnSelect: TDaisyItemClickEvent read FOnSelect write FOnSelect;
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
  end;

  TDaisyDropdownMenu = class(TDaisyButton)
  strict private
    FItems: TDaisyItems;
    FPlacement: TDaisyPlacement;
    FPopup: TDaisyDropdownPopup;
    FClosedTick: Cardinal;
    FOnItemClick: TDaisyItemClickEvent;
    FOnOpen: TNotifyEvent;
    FOnClose: TNotifyEvent;
    procedure SetItems(const Value: TDaisyItems);
    procedure SetPlacement(const Value: TDaisyPlacement);
    function GetIsOpen: Boolean;
    procedure PopupSelect(Sender: TObject; AItem: TDaisyItem);
    procedure PopupClosed(Sender: TObject);
  protected
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure WMDropDown(var Message: TMessage); message WM_DAISY_DROPDOWN;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    procedure DropDown;
    procedure CloseUp;
    property IsOpen: Boolean read GetIsOpen;
  published
    property Items: TDaisyItems read FItems write SetItems;
    property Placement: TDaisyPlacement read FPlacement write SetPlacement default dpBottomStart;
    property OnItemClick: TDaisyItemClickEvent read FOnItemClick write FOnItemClick;
    property OnOpen: TNotifyEvent read FOnOpen write FOnOpen;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, System.Math, System.UITypes, Vcl.Forms, Vcl.Graphics;

{ TDaisyDropdownPopup }

constructor TDaisyDropdownPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHotIndex := -1;
  ControlStyle := ControlStyle - [csParentBackground] + [csOpaque];
  Visible := False;
  TabStop := False;
end;

procedure TDaisyDropdownPopup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_CLIPCHILDREN;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  Params.WndParent := GetDesktopWindow;
end;

procedure TDaisyDropdownPopup.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TDaisyDropdownPopup.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if Visible and (HWND(Message.LParam) <> Handle) then
    Close; // capture was taken away (focus switched, another window...)
end;

function TDaisyDropdownPopup.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyDropdownPopup.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.15);
  Result.Text := Theme.BaseContent;
end;

function TDaisyDropdownPopup.Padding: Integer;
begin
  Result := ScaleValue(4);
end;

function TDaisyDropdownPopup.ItemHeight(AItem: TDaisyItem): Integer;
begin
  if AItem.IsSeparator then
    Result := ScaleValue(9)
  else
    Result := ScaleValue(DaisyFieldHeight(dzSM));
end;

function TDaisyDropdownPopup.ItemRect(AIndex: Integer): TRect;
var
  I, LTop: Integer;
begin
  LTop := Padding;
  for I := 0 to AIndex - 1 do
    Inc(LTop, ItemHeight(FItems[I]));
  Result := Rect(Padding, LTop, ClientWidth - Padding, LTop + ItemHeight(FItems[AIndex]));
end;

function TDaisyDropdownPopup.ItemAt(const APoint: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  if FItems = nil then
    Exit;
  for I := 0 to FItems.Count - 1 do
    if PtInRect(ItemRect(I), APoint) then
      Exit(I);
end;

function TDaisyDropdownPopup.MeasureWidth(AItems: TDaisyItems): Integer;
var
  I, LWidth: Integer;
begin
  Canvas.Font.Assign(Font);
  Canvas.Font.Height := -ScaleValue(DaisyFontSize(SizeKind));
  Result := 0;
  for I := 0 to AItems.Count - 1 do
    if not AItems[I].IsSeparator then
    begin
      LWidth := Canvas.TextWidth(AItems[I].Caption);
      if AItems[I].Description <> '' then
        Inc(LWidth, ScaleValue(24) + Canvas.TextWidth(AItems[I].Description));
      Result := Max(Result, LWidth);
    end;
  Inc(Result, 2 * (Padding + ScaleValue(12)));
end;

function TDaisyDropdownPopup.MeasureHeight(AItems: TDaisyItems): Integer;
var
  I: Integer;
begin
  Result := 2 * Padding;
  for I := 0 to AItems.Count - 1 do
    Inc(Result, ItemHeight(AItems[I]));
end;

procedure TDaisyDropdownPopup.Popup(AItems: TDaisyItems; const ALeft, ATop, AWidth: Integer);
var
  LHeight: Integer;
  LRegion: HRGN;
  LDiameter: Integer;
begin
  FItems := AItems;
  FHotIndex := -1;
  LHeight := MeasureHeight(FItems);
  Color := DaisyToColor(Theme.Base100);
  HandleNeeded;
  SetBounds(ALeft, ATop, AWidth, LHeight);
  LDiameter := 2 * ResolvedCornerRadius;
  LRegion := CreateRoundRectRgn(0, 0, AWidth + 1, LHeight + 1, LDiameter, LDiameter);
  SetWindowRgn(Handle, LRegion, False); // the system owns the region from here on
  Visible := True;
  SetWindowPos(Handle, HWND_TOPMOST, ALeft, ATop, AWidth, LHeight,
    SWP_NOACTIVATE or SWP_SHOWWINDOW);
  Invalidate;
  MouseCapture := True;
end;

procedure TDaisyDropdownPopup.Close;
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

procedure TDaisyDropdownPopup.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Invalidate;
  end;
end;

procedure TDaisyDropdownPopup.MoveHot(ADelta: Integer);
var
  LIndex, LTries: Integer;
begin
  if FItems.Count = 0 then
    Exit;
  LIndex := FHotIndex;
  for LTries := 1 to FItems.Count do
  begin
    LIndex := (LIndex + ADelta + FItems.Count) mod FItems.Count;
    if FItems[LIndex].Enabled and not FItems[LIndex].IsSeparator then
    begin
      SetHotIndex(LIndex);
      Exit;
    end;
  end;
end;

procedure TDaisyDropdownPopup.CommitHot;
var
  LItem: TDaisyItem;
begin
  if (FHotIndex < 0) or (FHotIndex >= FItems.Count) then
    Exit;
  LItem := FItems[FHotIndex];
  if not LItem.Enabled or LItem.IsSeparator then
    Exit;
  Close;
  if Assigned(FOnSelect) then
    FOnSelect(Self, LItem);
end;

procedure TDaisyDropdownPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (X < 0) or (Y < 0) or (X >= ClientWidth) or (Y >= ClientHeight) then
    Close; // click outside the menu
end;

procedure TDaisyDropdownPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(Point(X, Y));
  if (Button = mbLeft) and (LIndex >= 0) then
  begin
    SetHotIndex(LIndex);
    CommitHot;
  end;
end;

procedure TDaisyDropdownPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LIndex: Integer;
begin
  inherited;
  LIndex := ItemAt(Point(X, Y));
  if (LIndex >= 0) and (FItems[LIndex].IsSeparator or not FItems[LIndex].Enabled) then
    LIndex := -1;
  SetHotIndex(LIndex);
end;

procedure TDaisyDropdownPopup.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  I: Integer;
  LRect, LText: TRect;
  LGraphics: TGPGraphics;
  LItem: TDaisyItem;
  LColor: TAlphaColor;
begin
  LGraphics := NewGraphics;
  try
    for I := 0 to FItems.Count - 1 do
    begin
      LRect := ItemRect(I);
      if FItems[I].IsSeparator then
      begin
        LRect.Top := LRect.Top + LRect.Height div 2;
        LRect.Bottom := LRect.Top + 1;
        FillRoundRect(LGraphics, RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom), 0,
          DaisyWithAlpha(Theme.BaseContent, 0.12));
      end
      else if I = FHotIndex then
        FillRoundRect(LGraphics, RectF(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom),
          Theme.RadiusField, DaisyWithAlpha(Theme.BaseContent, 0.1));
    end;
  finally
    LGraphics.Free; // flush before GDI text
  end;

  for I := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[I];
    if LItem.IsSeparator then
      Continue;
    LRect := ItemRect(I);
    LText := LRect;
    InflateRect(LText, -ScaleValue(12), 0);
    if LItem.Enabled then
      LColor := AColors.Text
    else
      LColor := DaisyWithAlpha(AColors.Text, 0.35);
    DrawText(LItem.Caption, LText, LColor, DaisyFontSize(SizeKind), False,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    if LItem.Description <> '' then
      DrawText(LItem.Description, LText, DaisyWithAlpha(LColor, 0.6), DaisyFontSize(SizeKind), False,
        DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
  end;
end;

{ TDaisyDropdownMenu }

constructor TDaisyDropdownMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyItems.Create(Self);
  FPlacement := dpBottomStart;
  SetBounds(Left, Top, 120, Height);
  Caption := 'Click';
end;

destructor TDaisyDropdownMenu.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TDaisyDropdownMenu.SetItems(const Value: TDaisyItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyDropdownMenu.SetPlacement(const Value: TDaisyPlacement);
begin
  FPlacement := Value;
end;

function TDaisyDropdownMenu.GetIsOpen: Boolean;
begin
  Result := (FPopup <> nil) and FPopup.Visible;
end;

procedure TDaisyDropdownMenu.DropDown;
var
  LOrigin: TPoint;
  LWidth, LHeight, LX, LY, LGap: Integer;
  APlace: TDaisyPlacement;
  LWork: TRect;
begin
  if IsOpen or (FItems.Count = 0) or (csDesigning in ComponentState) then
    Exit;
  if FPopup = nil then
  begin
    FPopup := TDaisyDropdownPopup.Create(Self);
    FPopup.OnSelect := PopupSelect;
    FPopup.OnClosed := PopupClosed;
  end;
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;
  FPopup.Font.Assign(Font);
  FPopup.BiDiMode := BiDiMode;

  LGap := ScaleValue(4);
  LWidth := Max(FPopup.MeasureWidth(FItems), ScaleValue(160));
  LHeight := FPopup.MeasureHeight(FItems);
  LOrigin := ClientToScreen(Point(0, 0));

  APlace := FPlacement;
  if IsRTL then
    case FPlacement of
      dpBottomStart: APlace := dpBottomEnd;
      dpBottomEnd: APlace := dpBottomStart;
      dpTopStart: APlace := dpTopEnd;
      dpTopEnd: APlace := dpTopStart;
      dpLeft: APlace := dpRight;
      dpRight: APlace := dpLeft;
    end;

  case APlace of
    dpBottomStart: begin LX := LOrigin.X; LY := LOrigin.Y + Height + LGap; end;
    dpBottomEnd:   begin LX := LOrigin.X + Width - LWidth; LY := LOrigin.Y + Height + LGap; end;
    dpTopStart:    begin LX := LOrigin.X; LY := LOrigin.Y - LHeight - LGap; end;
    dpTopEnd:      begin LX := LOrigin.X + Width - LWidth; LY := LOrigin.Y - LHeight - LGap; end;
    dpLeft:        begin LX := LOrigin.X - LWidth - LGap; LY := LOrigin.Y; end;
  else
    LX := LOrigin.X + Width + LGap;
    LY := LOrigin.Y;
  end;

  LWork := Screen.MonitorFromWindow(Handle).WorkareaRect;
  if (APlace in [dpBottomStart, dpBottomEnd]) and (LY + LHeight > LWork.Bottom) then
    LY := LOrigin.Y - LHeight - LGap; // flip above when there is no room below
  LX := Max(LWork.Left, Min(LX, LWork.Right - LWidth));
  LY := Max(LWork.Top, Min(LY, LWork.Bottom - LHeight));
  FPopup.Popup(FItems, LX, LY, LWidth);

  if Assigned(FOnOpen) then
    FOnOpen(Self);
  Invalidate;
end;

procedure TDaisyDropdownMenu.CloseUp;
begin
  if IsOpen then
    FPopup.Close;
end;

procedure TDaisyDropdownMenu.PopupSelect(Sender: TObject; AItem: TDaisyItem);
begin
  if Assigned(AItem.OnClick) then
    AItem.OnClick(AItem);
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

procedure TDaisyDropdownMenu.PopupClosed(Sender: TObject);
begin
  FClosedTick := GetTickCount;
  if Assigned(FOnClose) then
    FOnClose(Self);
  Invalidate;
end;

procedure TDaisyDropdownMenu.Click;
begin
  inherited Click;
  if IsOpen then
    CloseUp
  else if (GetTickCount - FClosedTick > 300) and HandleAllocated then
    // opened after the mouse-up has been fully processed so the capture sticks
    PostMessage(Handle, WM_DAISY_DROPDOWN, 0, 0);
end;

procedure TDaisyDropdownMenu.WMDropDown(var Message: TMessage);
begin
  DropDown;
end;

procedure TDaisyDropdownMenu.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if IsOpen then
  begin
    case Key of
      VK_DOWN: FPopup.MoveHot(1);
      VK_UP: FPopup.MoveHot(-1);
      VK_RETURN: FPopup.CommitHot;
      VK_ESCAPE: FPopup.Close;
    else
      inherited KeyDown(Key, Shift);
      Exit;
    end;
    Key := 0;
    Exit;
  end;
  if (Key = VK_DOWN) and (Shift = []) then
  begin
    DropDown;
    Key := 0;
    Exit;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TDaisyDropdownMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LRect: TRect;
  LGraphics: TGPGraphics;
  LTextWidth, LIcon, LGap, LTotal, LLeft, LLead, LLeadGap, LIconX, LTextX: Integer;
  LPath: TDaisyIconPaths;
  LChevron: TRectF;
begin
  LRect := BodyRect;
  InflateRect(LRect, -ResolvedContentPadding, 0);
  LIcon := ScaleValue(DaisyFontSize(SizeKind) + 2);
  LGap := ScaleValue(6);
  LLead := IconExtent;
  LLeadGap := 0;
  if (LLead > 0) and (Caption <> '') then
    LLeadGap := IconGapExtent;
  Canvas.Font.Assign(Font);
  Canvas.Font.Height := -ScaleValue(DaisyFontSize(SizeKind));
  LTextWidth := Min(Canvas.TextWidth(Caption),
    Max(0, LRect.Width - LIcon - LGap - LLead - LLeadGap));
  LTotal := LLead + LLeadGap + LTextWidth + LGap + LIcon;
  LLeft := LRect.Left + (LRect.Width - LTotal) div 2;
  if IconPosition = bipLeft then
  begin
    LIconX := LLeft;
    LTextX := LLeft + LLead + LLeadGap;
  end
  else
  begin
    LTextX := LLeft;
    LIconX := LLeft + LTextWidth + LLeadGap;
  end;

  SetLength(LPath, 1);
  if IsOpen then
    LPath[0] := [PointF(6, 15), PointF(12, 9), PointF(18, 15)]
  else
    LPath[0] := [PointF(6, 9), PointF(12, 15), PointF(18, 9)];
  LChevron := RectF(LLeft + LTotal - LIcon, LRect.Top + (LRect.Height - LIcon) / 2,
    LLeft + LTotal, LRect.Top + (LRect.Height - LIcon) / 2 + LIcon);

  DrawButtonIcon(LIconX, LRect, AColors.Text);
  LGraphics := NewGraphics;
  try
    DrawPolylines(LGraphics, LPath, LChevron, AColors.Text, 2);
  finally
    LGraphics.Free; // flush before GDI text
  end;
  DrawText(Caption, Rect(LTextX, LRect.Top, LTextX + LTextWidth, LRect.Bottom), AColors.Text,
    DaisyFontSize(SizeKind), False, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

end.
