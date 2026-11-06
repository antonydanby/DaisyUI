unit Daisy.FMX.Dropdown;

{
  TDaisyFmxDropdownMenu - a button that opens a menu of Items.

  The menu is an overlay control parented to the form (no separate window), so
  it works the same on every FMX platform. While open it owns the mouse
  capture: a click outside the menu closes it, a click on an item runs it. The
  overlay is only created when the menu is first opened.
}

interface

uses
  System.Classes, System.Types, System.SysUtils, System.UITypes, FMX.Types, FMX.Controls,
  Daisy.Theme, Daisy.Items, Daisy.FMX.Control, Daisy.FMX.Button;

type
  TDaisyFmxMenuPopup = class(TDaisyControl)
  strict private
    FItems: TDaisyItems;
    FHotIndex: Integer;
    FOnSelect: TDaisyItemClickEvent;
    FOnClosed: TNotifyEvent;
    procedure SetHotIndex(const Value: Integer);
    function ItemHeight(AItem: TDaisyItem): Single;
    function ItemRect(AIndex: Integer): TRectF;
    function ItemAt(const APoint: TPointF): Integer;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    function MeasureWidth(AItems: TDaisyItems): Single;
    function MeasureHeight(AItems: TDaisyItems): Single;
    procedure Popup(AItems: TDaisyItems; const ALeft, ATop, AWidth: Single);
    procedure Close;
    procedure MoveHot(ADelta: Integer);
    procedure CommitHot;
    property OnSelect: TDaisyItemClickEvent read FOnSelect write FOnSelect;
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
  end;

  TDaisyFmxDropdownMenu = class(TDaisyFmxButton)
  strict private
    FItems: TDaisyItems;
    FPlacement: TDaisyPlacement;
    FPopup: TDaisyFmxMenuPopup;
    FOnItemClick: TDaisyItemClickEvent;
    FOnOpen: TNotifyEvent;
    FOnClose: TNotifyEvent;
    procedure SetItems(const Value: TDaisyItems);
    procedure SetPlacement(const Value: TDaisyPlacement);
    function GetIsOpen: Boolean;
    procedure PopupSelect(Sender: TObject; AItem: TDaisyItem);
    procedure PopupClosed(Sender: TObject);
  protected
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
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
  System.Math, FMX.Forms, FMX.TextLayout, FMX.Graphics;

const
  PopupPadding = 4;

function TextWidthOf(const AText: string; AFontSize: Integer): Single;
var
  LLayout: TTextLayout;
begin
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.Text := AText;
    LLayout.Font.Size := AFontSize;
    Result := LLayout.TextWidth;
  finally
    LLayout.Free;
  end;
end;

{ TDaisyFmxMenuPopup }

constructor TDaisyFmxMenuPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHotIndex := -1;
  Visible := False;
  CanFocus := False;
  AutoCapture := False;
end;

function TDaisyFmxMenuPopup.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxMenuPopup.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.15);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxMenuPopup.ItemHeight(AItem: TDaisyItem): Single;
begin
  if AItem.IsSeparator then
    Result := 9
  else
    Result := DaisyFieldHeight(dzSM);
end;

function TDaisyFmxMenuPopup.ItemRect(AIndex: Integer): TRectF;
var
  I: Integer;
  LTop: Single;
begin
  LTop := PopupPadding;
  for I := 0 to AIndex - 1 do
    LTop := LTop + ItemHeight(FItems[I]);
  Result := RectF(PopupPadding, LTop, Width - PopupPadding, LTop + ItemHeight(FItems[AIndex]));
end;

function TDaisyFmxMenuPopup.ItemAt(const APoint: TPointF): Integer;
var
  I: Integer;
begin
  Result := -1;
  if FItems = nil then
    Exit;
  for I := 0 to FItems.Count - 1 do
    if ItemRect(I).Contains(APoint) then
      Exit(I);
end;

function TDaisyFmxMenuPopup.MeasureWidth(AItems: TDaisyItems): Single;
var
  I: Integer;
  LWidth: Single;
begin
  Result := 0;
  for I := 0 to AItems.Count - 1 do
    if not AItems[I].IsSeparator then
    begin
      LWidth := TextWidthOf(AItems[I].Caption, DaisyFontSize(SizeKind));
      if AItems[I].Description <> '' then
        LWidth := LWidth + 24 + TextWidthOf(AItems[I].Description, DaisyFontSize(SizeKind));
      Result := Max(Result, LWidth);
    end;
  Result := Result + 2 * (PopupPadding + 12);
end;

function TDaisyFmxMenuPopup.MeasureHeight(AItems: TDaisyItems): Single;
var
  I: Integer;
begin
  Result := 2 * PopupPadding;
  for I := 0 to AItems.Count - 1 do
    Result := Result + ItemHeight(AItems[I]);
end;

procedure TDaisyFmxMenuPopup.Popup(AItems: TDaisyItems; const ALeft, ATop, AWidth: Single);
begin
  FItems := AItems;
  FHotIndex := -1;
  SetBounds(ALeft, ATop, AWidth, MeasureHeight(AItems));
  Visible := True;
  BringToFront;
  Capture;
  Repaint;
end;

procedure TDaisyFmxMenuPopup.Close;
begin
  if not Visible then
    Exit;
  ReleaseCapture;
  Visible := False;
  if Assigned(FOnClosed) then
    FOnClosed(Self);
end;

procedure TDaisyFmxMenuPopup.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxMenuPopup.MoveHot(ADelta: Integer);
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

procedure TDaisyFmxMenuPopup.CommitHot;
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

procedure TDaisyFmxMenuPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if (X < 0) or (Y < 0) or (X >= Width) or (Y >= Height) then
    Close; // click outside the menu
end;

procedure TDaisyFmxMenuPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LIndex: Integer;
begin
  LIndex := ItemAt(PointF(X, Y));
  if (Button = TMouseButton.mbLeft) and (LIndex >= 0) then
  begin
    SetHotIndex(LIndex);
    CommitHot;
  end;
end;

procedure TDaisyFmxMenuPopup.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LIndex: Integer;
begin
  inherited;
  LIndex := ItemAt(PointF(X, Y));
  if (LIndex >= 0) and (FItems[LIndex].IsSeparator or not FItems[LIndex].Enabled) then
    LIndex := -1;
  SetHotIndex(LIndex);
end;

procedure TDaisyFmxMenuPopup.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  I: Integer;
  LRect, LText: TRectF;
  LItem: TDaisyItem;
  LColor: TAlphaColor;
begin
  Canvas.Fill.Kind := TBrushKind.Solid;
  for I := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[I];
    LRect := ItemRect(I);
    if LItem.IsSeparator then
    begin
      Canvas.Fill.Color := DaisyWithAlpha(Theme.BaseContent, 0.12);
      Canvas.FillRect(RectF(LRect.Left, LRect.CenterPoint.Y, LRect.Right, LRect.CenterPoint.Y + 1),
        0, 0, [], 1);
      Continue;
    end;
    if I = FHotIndex then
    begin
      Canvas.Fill.Color := DaisyWithAlpha(Theme.BaseContent, 0.1);
      Canvas.FillRect(LRect, Theme.RadiusField, Theme.RadiusField, AllCorners, 1);
    end;
    if LItem.Enabled then
      LColor := AColors.Text
    else
      LColor := DaisyWithAlpha(AColors.Text, 0.35);
    LText := LRect;
    LText.Inflate(-12, 0);
    DrawText(LItem.Caption, LText, LColor, DaisyFontSize(SizeKind), False,
      TTextAlign.Leading, TTextAlign.Center, False);
    if LItem.Description <> '' then
      DrawText(LItem.Description, LText, DaisyWithAlpha(LColor, 0.6), DaisyFontSize(SizeKind), False,
        TTextAlign.Trailing, TTextAlign.Center, False);
  end;
end;

{ TDaisyFmxDropdownMenu }

constructor TDaisyFmxDropdownMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyItems.Create(Self);
  FPlacement := dpBottomStart;
  Text := 'Click';
  Width := 120;
end;

destructor TDaisyFmxDropdownMenu.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TDaisyFmxDropdownMenu.SetItems(const Value: TDaisyItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxDropdownMenu.SetPlacement(const Value: TDaisyPlacement);
begin
  FPlacement := Value;
end;

function TDaisyFmxDropdownMenu.GetIsOpen: Boolean;
begin
  Result := (FPopup <> nil) and FPopup.Visible;
end;

procedure TDaisyFmxDropdownMenu.DropDown;
var
  LForm: TCommonCustomForm;
  LOrigin: TPointF;
  LWidth, LHeight, LX, LY: Single;
begin
  if IsOpen or (FItems.Count = 0) or (csDesigning in ComponentState) then
    Exit;
  if (Root = nil) or not (Root.GetObject is TCommonCustomForm) then
    Exit;
  LForm := TCommonCustomForm(Root.GetObject);
  if FPopup = nil then
  begin
    FPopup := TDaisyFmxMenuPopup.Create(Self);
    FPopup.OnSelect := PopupSelect;
    FPopup.OnClosed := PopupClosed;
  end;
  if FPopup.Parent <> LForm then
    LForm.AddObject(FPopup);
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;

  LWidth := Max(FPopup.MeasureWidth(FItems), 160);
  LHeight := FPopup.MeasureHeight(FItems);
  LOrigin := LocalToAbsolute(PointF(0, 0));

  case FPlacement of
    dpBottomStart: begin LX := LOrigin.X; LY := LOrigin.Y + Height + 4; end;
    dpBottomEnd:   begin LX := LOrigin.X + Width - LWidth; LY := LOrigin.Y + Height + 4; end;
    dpTopStart:    begin LX := LOrigin.X; LY := LOrigin.Y - LHeight - 4; end;
    dpTopEnd:      begin LX := LOrigin.X + Width - LWidth; LY := LOrigin.Y - LHeight - 4; end;
    dpLeft:        begin LX := LOrigin.X - LWidth - 4; LY := LOrigin.Y; end;
  else
    LX := LOrigin.X + Width + 4;
    LY := LOrigin.Y;
  end;

  if (FPlacement in [dpBottomStart, dpBottomEnd]) and (LY + LHeight > LForm.ClientHeight) then
    LY := LOrigin.Y - LHeight - 4; // flip above when there is no room below
  LX := Max(0, Min(LX, LForm.ClientWidth - LWidth));
  LY := Max(0, Min(LY, LForm.ClientHeight - LHeight));

  FPopup.Popup(FItems, LX, LY, LWidth);
  if Assigned(FOnOpen) then
    FOnOpen(Self);
  Repaint;
end;

procedure TDaisyFmxDropdownMenu.CloseUp;
begin
  if IsOpen then
    FPopup.Close;
end;

procedure TDaisyFmxDropdownMenu.PopupSelect(Sender: TObject; AItem: TDaisyItem);
begin
  if Assigned(AItem.OnClick) then
    AItem.OnClick(AItem);
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, AItem);
end;

procedure TDaisyFmxDropdownMenu.PopupClosed(Sender: TObject);
begin
  if Assigned(FOnClose) then
    FOnClose(Self);
  Repaint;
end;

procedure TDaisyFmxDropdownMenu.Click;
begin
  inherited Click;
  // opened after the mouse-up has been fully processed so the capture sticks
  TThread.ForceQueue(nil,
    procedure
    begin
      if not (csDestroying in ComponentState) then
        DropDown;
    end);
end;

procedure TDaisyFmxDropdownMenu.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if IsOpen then
  begin
    case Key of
      vkDown: FPopup.MoveHot(1);
      vkUp: FPopup.MoveHot(-1);
      vkReturn: FPopup.CommitHot;
      vkEscape: FPopup.Close;
    else
      inherited KeyDown(Key, KeyChar, Shift);
      Exit;
    end;
    Key := 0;
    KeyChar := #0;
    Exit;
  end;
  if (Key = vkDown) and (Shift = []) then
  begin
    DropDown;
    Key := 0;
    Exit;
  end;
  inherited KeyDown(Key, KeyChar, Shift);
end;

procedure TDaisyFmxDropdownMenu.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LRect: TRectF;
  LTextWidth, LIcon, LGap, LTotal, LLeft, LLead, LLeadGap, LIconX, LTextX: Single;
  LPath: TDaisyIconPaths;
begin
  LRect := BodyRect;
  LRect.Inflate(-ResolvedContentPadding, 0);
  LIcon := DaisyFontSize(SizeKind) + 2;
  LGap := 6;
  LLead := IconExtent;
  LLeadGap := 0;
  if (LLead > 0) and (Text <> '') then
    LLeadGap := IconGapExtent;
  LTextWidth := Min(TextWidthOf(Text, DaisyFontSize(SizeKind)),
    Max(0, LRect.Width - LIcon - LGap - LLead - LLeadGap));
  LTotal := LLead + LLeadGap + LTextWidth + LGap + LIcon;
  LLeft := LRect.Left + (LRect.Width - LTotal) / 2;
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
  DrawButtonIcon(LIconX, LRect, AColors.Text);
  DrawPolylines(LPath, RectF(LLeft + LTotal - LIcon, LRect.CenterPoint.Y - LIcon / 2,
    LLeft + LTotal, LRect.CenterPoint.Y + LIcon / 2), AColors.Text, 2);
  DrawText(Text, RectF(LTextX, LRect.Top, LTextX + LTextWidth, LRect.Bottom), AColors.Text,
    DaisyFontSize(SizeKind), False, TTextAlign.Leading, TTextAlign.Center, False);
end;

end.
