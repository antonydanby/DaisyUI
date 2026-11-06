unit Daisy.FMX.Select;

{
  TDaisyFmxSelect - the DaisyUI "select": a field that opens a list of choices.

  Items holds the choices (a choice may contain emoji); ItemIndex is the chosen
  one (-1 shows Placeholder). Optional extras: a Legend above the field, a Hint
  below it, a LabelText inside the field (before / after the value) or floating
  on the border, and an Emoji / SVG icon at the start of the field.

  The list is an overlay control parented to the form (no separate window), so
  it works the same on every FMX platform. It is only created when first opened.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Forms, Daisy.Theme, Daisy.Widgets,
  Daisy.FMX.Control;

type
  TDaisyFmxIndexEvent = procedure(Sender: TObject; AIndex: Integer) of object;

  TDaisyFmxSelectPopup = class(TDaisyControl)
  strict private
    FItems: TStrings;
    FHotIndex: Integer;
    FSelected: Integer;
    FIndicator: TDaisySelectIndicator;
    FItemHeight: Single;
    FFirst: Integer;
    FMaxRows: Integer;
    FDragging: Boolean;
    FOnSelect: TDaisyFmxIndexEvent;
    FOnClosed: TNotifyEvent;
    function VisibleRows: Integer;
    function Scrollable: Boolean;
    function ThumbRect: TRectF;
    procedure SetFirst(AValue: Integer);
    procedure ScrollToY(AY: Single);
    procedure SetHotIndex(const Value: Integer);
    function ItemRect(AIndex: Integer): TRectF;
    function ItemAt(const APoint: TPointF): Integer;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    function MeasureHeight(ACount: Integer; AItemHeight: Single): Single;
    procedure Popup(AItems: TStrings; ASelected: Integer; AItemHeight, ALeft, ATop, AWidth: Single);
    procedure Close;
    procedure MoveHot(ADelta: Integer);
    procedure CommitHot;
    procedure Scroll(ADelta: Integer);
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    property MaxRows: Integer read FMaxRows write FMaxRows;
    property Indicator: TDaisySelectIndicator read FIndicator write FIndicator;
    property OnSelect: TDaisyFmxIndexEvent read FOnSelect write FOnSelect;
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
  end;

  TDaisyFmxSelect = class(TDaisyControl)
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
    FPopup: TDaisyFmxSelectPopup;
    FOnChange: TNotifyEvent;
    procedure SetItems(const Value: TStrings);
    procedure SetItemIndex(const Value: Integer);
    procedure SetPlaceholder(const Value: string);
    procedure SetLabelText(const Value: string);
    procedure SetLabelMode(const Value: TDaisySelectLabelMode);
    procedure SetLegend(const Value: string);
    procedure SetHintText(const Value: string);
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
    procedure GetLayout(out ALegend, AField, AHint: TRectF);
    procedure UpdateSize;
    function PadX: Single;
    function RowHeight: Single;
    procedure SetDropDownRows(const Value: Integer);
  protected
    function IsInteractive: Boolean; override;
    function DrawsFocusRing: Boolean; override;
    function DefaultCornerRadius: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Loaded; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
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
    property Hint: string read FHint write SetHintText;
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

const
  CPopupPadding = 4;

{ TDaisyFmxSelectPopup }

constructor TDaisyFmxSelectPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHotIndex := -1;
  FSelected := -1;
  FMaxRows := 8;
  Visible := False;
  CanFocus := False;
  AutoCapture := False;
end;

function TDaisyFmxSelectPopup.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyFmxSelectPopup.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxSelectPopup.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Background := Theme.Base100;
  Result.Border := DaisyWithAlpha(Theme.BaseContent, 0.15);
  Result.Text := Theme.BaseContent;
end;

function TDaisyFmxSelectPopup.VisibleRows: Integer;
begin
  if FItems = nil then
    Exit(0);
  Result := Min(FItems.Count, Max(1, FMaxRows));
end;

function TDaisyFmxSelectPopup.Scrollable: Boolean;
begin
  Result := (FItems <> nil) and (FItems.Count > Max(1, FMaxRows));
end;

function TDaisyFmxSelectPopup.ThumbRect: TRectF;
var
  LTrack, LThumb, LTop: Single;
begin
  LTrack := VisibleRows * FItemHeight;
  LThumb := Max(16, LTrack * VisibleRows / Max(1, FItems.Count));
  LTop := CPopupPadding + (LTrack - LThumb) * FFirst / Max(1, FItems.Count - VisibleRows);
  Result := RectF(Width - 8, LTop, Width - 3, LTop + LThumb);
end;

procedure TDaisyFmxSelectPopup.SetFirst(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 0, Max(0, FItems.Count - VisibleRows));
  if AValue <> FFirst then
  begin
    FFirst := AValue;
    Repaint;
  end;
end;

procedure TDaisyFmxSelectPopup.Scroll(ADelta: Integer);
begin
  if Scrollable then
    SetFirst(FFirst + ADelta);
end;

procedure TDaisyFmxSelectPopup.MouseWheel(Shift: TShiftState; WheelDelta: Integer;
  var Handled: Boolean);
begin
  Scroll(-Sign(WheelDelta) * 3);
  Handled := True;
end;

procedure TDaisyFmxSelectPopup.ScrollToY(AY: Single);
var
  LTrack, LThumb: Single;
begin
  LTrack := VisibleRows * FItemHeight;
  LThumb := ThumbRect.Height;
  SetFirst(Round((AY - CPopupPadding - LThumb / 2) / Max(1, LTrack - LThumb) *
    (FItems.Count - VisibleRows)));
end;

function TDaisyFmxSelectPopup.ItemRect(AIndex: Integer): TRectF;
var
  LRight: Single;
begin
  LRight := Width - CPopupPadding;
  if Scrollable then
    LRight := LRight - 8;
  Result := RectF(CPopupPadding, CPopupPadding + (AIndex - FFirst) * FItemHeight, LRight,
    CPopupPadding + (AIndex - FFirst + 1) * FItemHeight);
end;

function TDaisyFmxSelectPopup.ItemAt(const APoint: TPointF): Integer;
var
  I: Integer;
begin
  Result := -1;
  if FItems = nil then
    Exit;
  for I := FFirst to Min(FItems.Count, FFirst + VisibleRows) - 1 do
    if ItemRect(I).Contains(APoint) then
      Exit(I);
end;

function TDaisyFmxSelectPopup.MeasureHeight(ACount: Integer; AItemHeight: Single): Single;
begin
  Result := 2 * CPopupPadding + Min(ACount, Max(1, FMaxRows)) * AItemHeight;
end;

procedure TDaisyFmxSelectPopup.Popup(AItems: TStrings; ASelected: Integer; AItemHeight, ALeft, ATop,
  AWidth: Single);
begin
  FItems := AItems;
  FSelected := ASelected;
  FHotIndex := ASelected;
  FItemHeight := AItemHeight;
  FDragging := False;
  FFirst := 0;
  if ASelected >= VisibleRows then
    FFirst := EnsureRange(ASelected - VisibleRows div 2, 0, FItems.Count - VisibleRows);
  SetBounds(ALeft, ATop, AWidth, MeasureHeight(FItems.Count, FItemHeight));
  Visible := True;
  BringToFront;
  Capture;
  Repaint;
end;

procedure TDaisyFmxSelectPopup.Close;
begin
  if not Visible then
    Exit;
  ReleaseCapture;
  Visible := False;
  if Assigned(FOnClosed) then
    FOnClosed(Self);
end;

procedure TDaisyFmxSelectPopup.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxSelectPopup.MoveHot(ADelta: Integer);
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

procedure TDaisyFmxSelectPopup.CommitHot;
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

procedure TDaisyFmxSelectPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if (X < 0) or (Y < 0) or (X >= Width) or (Y >= Height) then
    Close
  else if Scrollable and (X >= Width - 10) then
  begin
    FDragging := True;
    ScrollToY(Y);
  end;
end;

procedure TDaisyFmxSelectPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LIndex: Integer;
begin
  if FDragging then
  begin
    FDragging := False;
    Exit;
  end;
  LIndex := ItemAt(PointF(X, Y));
  if (Button = TMouseButton.mbLeft) and (LIndex >= 0) then
  begin
    SetHotIndex(LIndex);
    CommitHot;
  end;
end;

procedure TDaisyFmxSelectPopup.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if FDragging then
    ScrollToY(Y)
  else
    SetHotIndex(ItemAt(PointF(X, Y)));
end;

procedure TDaisyFmxSelectPopup.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  I: Integer;
  LRect, LText, LThumb: TRectF;
begin
  for I := FFirst to Min(FItems.Count, FFirst + VisibleRows) - 1 do
  begin
    LRect := ItemRect(I);
    if I = FHotIndex then
      FillRound(LRect, Theme.RadiusField, DaisyWithAlpha(Theme.BaseContent, 0.1))
    else if I = FSelected then
      FillRound(LRect, Theme.RadiusField, DaisyWithAlpha(Theme.BaseContent, 0.05));
    LText := LRect;
    LText.Inflate(-10, 0);
    if FIndicator = siTick then
    begin
      LText.Right := LText.Right - 24;
      if I = FSelected then
      begin
        LThumb := RectF(LRect.Right - 10 - 16 - IfThen(Scrollable, 8, 0), LRect.Top + (LRect.Height - 16) / 2,
          LRect.Right - 10 - IfThen(Scrollable, 8, 0), 0);
        LThumb.Bottom := LThumb.Top + 16;
        DrawIconPath('M5 12.5l4.5 4.5l9.5 -10', LThumb, AColors.Text);
      end;
    end;
    DrawText(FItems[I], LText, AColors.Text, DaisyFontSize(SizeKind),
      (I = FSelected) and (FIndicator = siBold),
      TTextAlign.Leading, TTextAlign.Center, False);
  end;
  if Scrollable then
  begin
    LThumb := ThumbRect;
    FillRound(LThumb, LThumb.Width / 2, DaisyWithAlpha(Theme.BaseContent, 0.35));
  end;
end;

{ TDaisyFmxSelect }

constructor TDaisyFmxSelect.Create(AOwner: TComponent);
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
  CanFocus := True;
  TabStop := True;
  Cursor := crHandPoint;
  SetBounds(Position.X, Position.Y, 192, DaisyFieldHeight(dzMD));
  UpdateSize;
end;

destructor TDaisyFmxSelect.Destroy;
begin
  FIcon.Free;
  FItems.Free;
  inherited Destroy;
end;

function TDaisyFmxSelect.IsInteractive: Boolean;
begin
  Result := True;
end;

function TDaisyFmxSelect.DrawsFocusRing: Boolean;
begin
  Result := False; // the field border shows the focus
end;

function TDaisyFmxSelect.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusField;
end;

function TDaisyFmxSelect.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxSelect.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxSelect.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TDaisyFmxSelect.SetItemIndex(const Value: Integer);
var
  LValue: Integer;
begin
  LValue := Value;
  if not (csLoading in ComponentState) then
    LValue := EnsureRange(Value, -1, FItems.Count - 1);
  if FItemIndex <> LValue then
  begin
    FItemIndex := LValue;
    Repaint;
    if not (csLoading in ComponentState) and Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TDaisyFmxSelect.SetPlaceholder(const Value: string);
begin
  if FPlaceholder <> Value then
  begin
    FPlaceholder := Value;
    Repaint;
  end;
end;

procedure TDaisyFmxSelect.SetLabelText(const Value: string);
begin
  if FLabelText <> Value then
  begin
    FLabelText := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxSelect.SetLabelMode(const Value: TDaisySelectLabelMode);
begin
  if FLabelMode <> Value then
  begin
    FLabelMode := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxSelect.SetLegend(const Value: string);
begin
  if FLegend <> Value then
  begin
    FLegend := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxSelect.SetHintText(const Value: string);
begin
  if FHint <> Value then
  begin
    FHint := Value;
    UpdateSize;
    Repaint;
  end;
end;

procedure TDaisyFmxSelect.SetAutoFit(const Value: Boolean);
begin
  if FAutoFit <> Value then
  begin
    FAutoFit := Value;
    UpdateSize;
  end;
end;

function TDaisyFmxSelect.GetEmoji: string;
begin
  Result := FIcon.Emoji;
end;

procedure TDaisyFmxSelect.SetEmoji(const Value: string);
begin
  FIcon.Emoji := Value;
end;

function TDaisyFmxSelect.GetSVG: TStrings;
begin
  Result := FIcon.SVG;
end;

procedure TDaisyFmxSelect.SetSVG(const Value: TStrings);
begin
  FIcon.SVG := Value;
end;

function TDaisyFmxSelect.GetIsOpen: Boolean;
begin
  Result := (FPopup <> nil) and FPopup.Visible;
end;

function TDaisyFmxSelect.GetText: string;
begin
  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    Result := FItems[FItemIndex]
  else
    Result := '';
end;

procedure TDaisyFmxSelect.ItemsChanged(Sender: TObject);
begin
  if (not (csLoading in ComponentState)) and (FItemIndex >= FItems.Count) then
    FItemIndex := FItems.Count - 1;
  Repaint;
end;

procedure TDaisyFmxSelect.IconChanged(Sender: TObject);
begin
  Repaint;
end;

procedure TDaisyFmxSelect.SizeChanged;
begin
  UpdateSize;
  Repaint;
end;

procedure TDaisyFmxSelect.Loaded;
begin
  inherited;
  if FItemIndex >= FItems.Count then
    FItemIndex := FItems.Count - 1;
  UpdateSize;
end;

function TDaisyFmxSelect.PadX: Single;
begin
  Result := Max(8, DaisyFieldPaddingX(SizeKind) * 3 div 4);
end;

function TDaisyFmxSelect.RowHeight: Single;
begin
  Result := Max(24, DaisyFieldHeight(SizeKind) - 6);
end;

procedure TDaisyFmxSelect.GetLayout(out ALegend, AField, AHint: TRectF);
var
  LTop: Single;
begin
  LTop := 0;
  ALegend := RectF(0, 0, 0, 0);
  AHint := RectF(0, 0, 0, 0);
  if FLegend <> '' then
  begin
    ALegend := RectF(0, 0, Width, 20);
    LTop := 24;
  end;
  if (FLabelMode = slmFloating) and (FLabelText <> '') then
    LTop := LTop + 8;
  AField := RectF(0, LTop, Width, LTop + DaisyFieldHeight(SizeKind));
  if FHint <> '' then
    AHint := RectF(0, AField.Bottom + 4, Width, AField.Bottom + 22);
end;

procedure TDaisyFmxSelect.UpdateSize;
var
  LLegend, LField, LHint: TRectF;
  LHeight: Single;
begin
  if (not FAutoFit) or FUpdating or (csLoading in ComponentState) then
    Exit;
  GetLayout(LLegend, LField, LHint);
  if FHint <> '' then
    LHeight := LHint.Bottom
  else
    LHeight := LField.Bottom;
  if SameValue(LHeight, Height) then
    Exit;
  FUpdating := True;
  try
    SetBounds(Position.X, Position.Y, Width, LHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TDaisyFmxSelect.DropDown;
var
  LForm: TCommonCustomForm;
  LLegend, LField, LHint: TRectF;
  LOrigin: TPointF;
  LHeight, LY, LX: Single;
begin
  if IsOpen or (FItems.Count = 0) or (csDesigning in ComponentState) then
    Exit;
  if (Root = nil) or not (Root.GetObject is TCommonCustomForm) then
    Exit;
  LForm := TCommonCustomForm(Root.GetObject);
  if FPopup = nil then
  begin
    FPopup := TDaisyFmxSelectPopup.Create(Self);
    FPopup.OnSelect := PopupSelect;
    FPopup.OnClosed := PopupClosed;
  end;
  if FPopup.Parent <> LForm then
    LForm.AddObject(FPopup);
  FPopup.ThemeKind := ThemeKind;
  FPopup.SizeKind := SizeKind;
  FPopup.MaxRows := FDropDownRows;
  FPopup.Indicator := FSelectedIndicator;
  GetLayout(LLegend, LField, LHint);
  LHeight := FPopup.MeasureHeight(FItems.Count, RowHeight);
  LOrigin := LocalToAbsolute(PointF(LField.Left, LField.Bottom));
  LX := LOrigin.X;
  LY := LOrigin.Y + 4;
  if LY + LHeight > LForm.ClientHeight then
    LY := LocalToAbsolute(PointF(0, LField.Top)).Y - LHeight - 4; // flip above
  LX := Max(0, Min(LX, LForm.ClientWidth - LField.Width));
  LY := Max(0, Min(LY, LForm.ClientHeight - LHeight));
  FPopup.Popup(FItems, FItemIndex, RowHeight, LX, LY, LField.Width);
  if CanFocus and not IsFocused then
    SetFocus;
  Repaint;
end;

procedure TDaisyFmxSelect.SetDropDownRows(const Value: Integer);
begin
  FDropDownRows := Max(1, Value);
end;

procedure TDaisyFmxSelect.CloseUp;
begin
  if IsOpen then
    FPopup.Close;
end;

procedure TDaisyFmxSelect.PopupSelect(Sender: TObject; AIndex: Integer);
begin
  SetItemIndex(AIndex);
end;

procedure TDaisyFmxSelect.PopupClosed(Sender: TObject);
begin
  Repaint;
end;

procedure TDaisyFmxSelect.Click;
begin
  inherited Click;
  if not Enabled then
    Exit;
  // opened after the mouse-up has been fully processed so the capture sticks
  TThread.ForceQueue(nil,
    procedure
    begin
      if not (csDestroying in ComponentState) then
        DropDown;
    end);
end;

procedure TDaisyFmxSelect.DoExit;
begin
  inherited;
  CloseUp;
end;

procedure TDaisyFmxSelect.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if IsOpen then
  begin
    case Key of
      vkDown: FPopup.MoveHot(1);
      vkUp: FPopup.MoveHot(-1);
      vkReturn, vkSpace: FPopup.CommitHot;
      vkEscape: FPopup.Close;
    else
      inherited KeyDown(Key, KeyChar, Shift);
      Exit;
    end;
    Key := 0;
    KeyChar := #0;
    Exit;
  end;
  case Key of
    vkF4, vkSpace, vkReturn: DropDown;
    vkDown: SetItemIndex(Min(FItemIndex + 1, FItems.Count - 1));
    vkUp: SetItemIndex(Max(FItemIndex - 1, 0));
  else
    inherited KeyDown(Key, KeyChar, Shift);
    Exit;
  end;
  Key := 0;
  KeyChar := #0;
end;

procedure TDaisyFmxSelect.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
var
  LLegend, LField, LHint, LInner, LChevronBox, LLabelBox, LTextBox, LChip: TRectF;
  LPath: TDaisyIconPaths;
  LTint, LBorder, LFill, LText, LDim: TAlphaColor;
  LRadius, LPad, LIcon, LLabelW, LDivX, LBorderW: Single;
  LFont, LSmall: Integer;
  LBordered, LActive: Boolean;
  LPalette: TDaisyPalette;
  LShown: string;
begin
  GetLayout(LLegend, LField, LHint);
  LFont := DaisyFontSize(SizeKind);
  LSmall := DaisyFontSize(dzSM);
  LRadius := ResolvedCornerRadius;
  LPad := PadX;
  LActive := IsFocused or IsOpen;

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
  LBorderW := Max(1, Theme.BorderWidth);

  LInner := LField;
  LInner.Inflate(-LPad, 0);
  LChevronBox := RectF(LInner.Right - (LFont + 2), LField.Top + (LField.Height - (LFont + 2)) / 2,
    LInner.Right, LField.Top + (LField.Height - (LFont + 2)) / 2 + (LFont + 2));
  LTextBox := RectF(LInner.Left, LField.Top, LChevronBox.Left - 6, LField.Bottom);
  LLabelW := 0;
  LDivX := -1;
  LLabelBox := RectF(0, 0, 0, 0);
  if (FLabelText <> '') and (FLabelMode in [slmBefore, slmAfter]) then
  begin
    LLabelW := MeasureTextWidth(FLabelText, LSmall, False);
    if FLabelMode = slmBefore then
    begin
      LLabelBox := RectF(LTextBox.Left, LField.Top, LTextBox.Left + LLabelW, LField.Bottom);
      LDivX := LLabelBox.Right + LPad / 2;
      LTextBox.Left := LDivX + LPad / 2 + 1;
    end
    else
    begin
      LLabelBox := RectF(LTextBox.Right - LLabelW, LField.Top, LTextBox.Right, LField.Bottom);
      LDivX := LLabelBox.Left - LPad / 2;
      LTextBox.Right := LDivX - LPad / 2;
    end;
  end;

  FillRound(LField, LRadius, LFill);
  if LBordered or LActive then
    StrokeRound(LField, LRadius, LBorder, LBorderW, (Style = dsDash) and not LActive);

  if LDivX >= 0 then
    FillRound(RectF(LDivX, LField.Top + LField.Height / 4, LDivX + 1, LField.Bottom - LField.Height / 4),
      0, DaisyWithAlpha(Theme.BaseContent, 0.2));

  SetLength(LPath, 1);
  if IsOpen then
    LPath[0] := [PointF(6, 15), PointF(12, 9), PointF(18, 15)]
  else
    LPath[0] := [PointF(6, 9), PointF(12, 15), PointF(18, 9)];
  DrawPolylines(LPath, LChevronBox, LDim, 2);

  if (FLabelText <> '') and (FLabelMode = slmFloating) then
  begin
    LChip := RectF(LField.Left + LPad - 4, LField.Top - 8,
      LField.Left + LPad + MeasureTextWidth(FLabelText, LSmall, False) + 4, LField.Top + 8);
    FillRound(LChip, 0, Theme.Base100);
    DrawText(FLabelText, LChip, LDim, LSmall, False, TTextAlign.Center, TTextAlign.Center, False);
  end
  else if LLabelW > 0 then
    DrawText(FLabelText, LLabelBox, LDim, LSmall, False, TTextAlign.Leading, TTextAlign.Center, False);

  if FLegend <> '' then
    DrawText(FLegend, LLegend, Theme.BaseContent, LSmall, True, TTextAlign.Leading,
      TTextAlign.Center, False);
  if FHint <> '' then
    DrawText(FHint, LHint, DaisyWithAlpha(Theme.BaseContent, 0.6), DaisyFontSize(dzXS), False,
      TTextAlign.Leading, TTextAlign.Center, False);

  if not FIcon.IsEmpty then
  begin
    LIcon := LFont + 4;
    DrawGlyph(FIcon, RectF(LTextBox.Left, LField.Top + (LField.Height - LIcon) / 2,
      LTextBox.Left + LIcon, LField.Top + (LField.Height - LIcon) / 2 + LIcon), LText);
    LTextBox.Left := LTextBox.Left + LIcon + 8;
  end;

  LShown := GetText;
  if LShown = '' then
    DrawText(FPlaceholder, LTextBox, DaisyWithAlpha(LText, 0.5), LFont, False, TTextAlign.Leading,
      TTextAlign.Center, False)
  else
    DrawText(LShown, LTextBox, LText, LFont, False, TTextAlign.Leading, TTextAlign.Center, False);
end;

end.
