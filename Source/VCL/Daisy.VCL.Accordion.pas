unit Daisy.VCL.Accordion;

{
  TDaisyAccordion - a stack of collapsible sections (see daisyui.com/components/accordion).
  Each section has a Title and Content; Icon selects an arrow or a + / - marker.
  Joined = True merges the sections into one block with shared borders (the
  "accordion and join together" look). AllowMultiple = False keeps a single
  section open at a time. The control sizes its own height to fit the sections.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Controls,
  Daisy.Theme, Daisy.Items, Daisy.VCL.Control;

type
  TDaisyAccordion = class(TDaisyControl)
  strict private
    FItems: TDaisyAccordionItems;
    FIcon: TDaisyAccordionIcon;
    FJoined: Boolean;
    FAllowMultiple: Boolean;
    FHotIndex: Integer;
    FFocusIndex: Integer;
    FKeyNav: Boolean;
    FUpdating: Boolean;
    FOnToggle: TDaisyAccordionEvent;
    procedure SetItems(const Value: TDaisyAccordionItems);
    procedure SetIcon(const Value: TDaisyAccordionIcon);
    procedure SetJoined(const Value: Boolean);
    procedure SetAllowMultiple(const Value: Boolean);
    procedure SetHotIndex(const Value: Integer);
    function Gap: Integer;
    function HeaderHeight: Integer;
    function ContentPad: Integer;
    function ContentHeight(AIndex: Integer): Integer;
    function SectionHeight(AIndex: Integer): Integer;
    function TotalHeight: Integer;
    function SectionRect(AIndex: Integer): TRect;
    function HeaderRect(AIndex: Integer): TRect;
    function HitHeader(const APoint: TPoint): Integer;
    procedure UpdateHeight;
    procedure KeepSingleOpen;
    procedure ItemsChanged(Sender: TObject);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure SizeChanged; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ToggleItem(AIndex: Integer);
  published
    property Items: TDaisyAccordionItems read FItems write SetItems;
    property Icon: TDaisyAccordionIcon read FIcon write SetIcon default aiArrow;
    property Joined: Boolean read FJoined write SetJoined default False;
    // False = opening a section closes the others
    property AllowMultiple: Boolean read FAllowMultiple write SetAllowMultiple default False;
    property OnToggle: TDaisyAccordionEvent read FOnToggle write FOnToggle;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SysUtils, System.Math, System.UITypes;

const
  NoHot = -1;

function BuildPath(const ARect: TRectF; ARadius: Single): TGPGraphicsPath;
var
  LRadius, D: Single;
begin
  Result := TGPGraphicsPath.Create;
  LRadius := Min(ARadius, Min(ARect.Width, ARect.Height) / 2);
  if LRadius <= 0.5 then
  begin
    Result.AddRectangle(MakeRect(ARect.Left, ARect.Top, ARect.Width, ARect.Height));
    Exit;
  end;
  D := LRadius * 2;
  Result.AddArc(ARect.Left, ARect.Top, D, D, 180, 90);
  Result.AddArc(ARect.Right - D, ARect.Top, D, D, 270, 90);
  Result.AddArc(ARect.Right - D, ARect.Bottom - D, D, D, 0, 90);
  Result.AddArc(ARect.Left, ARect.Bottom - D, D, D, 90, 90);
  Result.CloseFigure;
end;

{ TDaisyAccordion }

constructor TDaisyAccordion.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TDaisyAccordionItems.Create(Self);
  FItems.OnChange := ItemsChanged;
  FIcon := aiArrow;
  FHotIndex := NoHot;
  FFocusIndex := 0;
  TabStop := True;
  SetBounds(Left, Top, 320, 52);
end;

destructor TDaisyAccordion.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TDaisyAccordion.DefaultCornerRadius: Integer;
begin
  Result := Theme.RadiusBox;
end;

function TDaisyAccordion.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyAccordion.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
var
  LTheme: TDaisyTheme;
begin
  LTheme := Theme;
  Result := DaisyResolveColors(LTheme, Variant, dsSolid, dstNormal);
  if Variant = dvDefault then
  begin
    Result.Background := LTheme.Base100;
    Result.Border := LTheme.BorderColor;
    Result.Text := LTheme.BaseContent;
  end;
end;

{ Layout }

function TDaisyAccordion.Gap: Integer;
begin
  if FJoined then
    Result := 0
  else
    Result := ScaleValue(8);
end;

function TDaisyAccordion.HeaderHeight: Integer;
begin
  Result := ScaleValue(DaisyFieldHeight(SizeKind) + 12);
end;

function TDaisyAccordion.ContentPad: Integer;
begin
  Result := ScaleValue(16);
end;

function TDaisyAccordion.ContentHeight(AIndex: Integer): Integer;
begin
  Result := 0;
  if FItems[AIndex].Content = '' then
    Exit;
  Result := MeasureTextHeight(FItems[AIndex].Content, ClientWidth - 2 * ContentPad,
    DaisyFontSize(SizeKind), False) + ContentPad;
end;

function TDaisyAccordion.SectionHeight(AIndex: Integer): Integer;
begin
  Result := HeaderHeight;
  if FItems[AIndex].Expanded then
    Inc(Result, ContentHeight(AIndex));
end;

function TDaisyAccordion.TotalHeight: Integer;
var
  I: Integer;
begin
  if FItems.Count = 0 then
    Exit(HeaderHeight);
  Result := (FItems.Count - 1) * Gap;
  for I := 0 to FItems.Count - 1 do
    Inc(Result, SectionHeight(I));
end;

function TDaisyAccordion.SectionRect(AIndex: Integer): TRect;
var
  I, LTop: Integer;
begin
  LTop := 0;
  for I := 0 to AIndex - 1 do
    Inc(LTop, SectionHeight(I) + Gap);
  Result := Rect(0, LTop, ClientWidth, LTop + SectionHeight(AIndex));
end;

function TDaisyAccordion.HeaderRect(AIndex: Integer): TRect;
begin
  Result := SectionRect(AIndex);
  Result.Bottom := Result.Top + HeaderHeight;
end;

function TDaisyAccordion.HitHeader(const APoint: TPoint): Integer;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    if PtInRect(HeaderRect(I), APoint) then
      Exit(I);
  Result := NoHot;
end;

procedure TDaisyAccordion.UpdateHeight;
var
  LHeight: Integer;
begin
  if FUpdating or (csLoading in ComponentState) or not HandleAllocated then
    Exit;
  LHeight := TotalHeight;
  if LHeight <> Height then
  begin
    FUpdating := True;
    try
      SetBounds(Left, Top, Width, LHeight);
    finally
      FUpdating := False;
    end;
  end;
end;

procedure TDaisyAccordion.CreateWnd;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyAccordion.Loaded;
begin
  inherited;
  KeepSingleOpen;
  UpdateHeight;
end;

procedure TDaisyAccordion.Resize;
begin
  inherited;
  UpdateHeight;
end;

procedure TDaisyAccordion.SizeChanged;
begin
  UpdateHeight;
end;

{ Properties }

procedure TDaisyAccordion.SetItems(const Value: TDaisyAccordionItems);
begin
  FItems.Assign(Value);
end;

procedure TDaisyAccordion.SetIcon(const Value: TDaisyAccordionIcon);
begin
  if FIcon <> Value then
  begin
    FIcon := Value;
    Invalidate;
  end;
end;

procedure TDaisyAccordion.SetJoined(const Value: Boolean);
begin
  if FJoined <> Value then
  begin
    FJoined := Value;
    UpdateHeight;
    Invalidate;
  end;
end;

procedure TDaisyAccordion.SetAllowMultiple(const Value: Boolean);
begin
  if FAllowMultiple <> Value then
  begin
    FAllowMultiple := Value;
    KeepSingleOpen;
  end;
end;

procedure TDaisyAccordion.SetHotIndex(const Value: Integer);
begin
  if FHotIndex <> Value then
  begin
    FHotIndex := Value;
    Invalidate;
  end;
end;

procedure TDaisyAccordion.KeepSingleOpen;
var
  I: Integer;
  LFound: Boolean;
begin
  if FAllowMultiple or (FItems.Count = 0) then
    Exit;
  LFound := False;
  FItems.BeginUpdate;
  try
    for I := 0 to FItems.Count - 1 do
      if FItems[I].Expanded then
      begin
        if LFound then
          FItems[I].Expanded := False;
        LFound := True;
      end;
  finally
    FItems.EndUpdate;
  end;
end;

procedure TDaisyAccordion.ItemsChanged(Sender: TObject);
begin
  if FFocusIndex >= FItems.Count then
    FFocusIndex := Max(0, FItems.Count - 1);
  UpdateHeight;
  Invalidate;
end;

procedure TDaisyAccordion.ToggleItem(AIndex: Integer);
var
  I: Integer;
  LOpen: Boolean;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) or not FItems[AIndex].Enabled then
    Exit;
  LOpen := not FItems[AIndex].Expanded;
  FItems.BeginUpdate;
  try
    if LOpen and not FAllowMultiple then
      for I := 0 to FItems.Count - 1 do
        FItems[I].Expanded := False;
    FItems[AIndex].Expanded := LOpen;
  finally
    FItems.EndUpdate;
  end;
  if Assigned(FOnToggle) then
    FOnToggle(Self, AIndex);
end;

{ Input }

procedure TDaisyAccordion.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TDaisyAccordion.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHotIndex(NoHot);
end;

procedure TDaisyAccordion.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FKeyNav := False;
  if not Focused and CanFocus then
    SetFocus;
  inherited;
end;

procedure TDaisyAccordion.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LHit: Integer;
begin
  inherited;
  LHit := HitHeader(Point(X, Y));
  if (LHit >= 0) and not FItems[LHit].Enabled then
    LHit := NoHot;
  SetHotIndex(LHit);
  if LHit >= 0 then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TDaisyAccordion.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LHit: Integer;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  LHit := HitHeader(Point(X, Y));
  if LHit >= 0 then
  begin
    FFocusIndex := LHit;
    ToggleItem(LHit);
  end;
end;

procedure TDaisyAccordion.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if FItems.Count = 0 then
    Exit;
  case Key of
    VK_DOWN:
      begin
        FFocusIndex := Min(FItems.Count - 1, FFocusIndex + 1);
        Key := 0;
      end;
    VK_UP:
      begin
        FFocusIndex := Max(0, FFocusIndex - 1);
        Key := 0;
      end;
    VK_SPACE, VK_RETURN:
      begin
        ToggleItem(FFocusIndex);
        Key := 0;
      end;
  else
    Exit;
  end;
  FKeyNav := True;
  Invalidate;
end;

procedure TDaisyAccordion.DoExit;
begin
  inherited;
  FKeyNav := False;
  Invalidate;
end;

{ Painting }

procedure TDaisyAccordion.Paint;
var
  LGraphics: TGPGraphics;
  LColors: TDaisyColors;
  LRadius, LBorder: Single;
  LSection, LHead: TRect;
  LPath: TGPGraphicsPath;
  LPen: TGPPen;
  LTextColor: TAlphaColor;
  I, LIconW, LMid, LHalf, LPad: Integer;
  LCx, LCy, LW: Single;
  LOpen: Boolean;

  procedure FillBlock(const ARect: TRect);
  begin
    FillRoundRect(LGraphics, RectF(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom), LRadius, LColors.Border);
    FillRoundRect(LGraphics, RectF(ARect.Left + LBorder, ARect.Top + LBorder, ARect.Right - LBorder,
      ARect.Bottom - LBorder), Max(0, LRadius - LBorder), LColors.Background);
  end;

begin
  LColors := ResolveColors;
  LRadius := ResolvedCornerRadius;
  LBorder := Max(1, ScaleValue(Theme.BorderWidth));
  LPad := ContentPad;
  LIconW := IfThen(FIcon = aiNone, 0, ScaleValue(24));

  LGraphics := NewGraphics;
  try
    if FItems.Count = 0 then
      FillBlock(ClientRect)
    else if FJoined then
    begin
      FillBlock(ClientRect);
      for I := 1 to FItems.Count - 1 do
      begin
        LSection := SectionRect(I);
        FillRoundRect(LGraphics, RectF(LBorder, LSection.Top, ClientWidth - LBorder,
          LSection.Top + LBorder), 0, LColors.Border);
      end;
    end
    else
      for I := 0 to FItems.Count - 1 do
        FillBlock(SectionRect(I));

    // Keyboard focus ring around the header
    if Focused and FKeyNav and (FFocusIndex >= 0) and (FFocusIndex < FItems.Count) then
    begin
      LHead := HeaderRect(FFocusIndex);
      InflateRect(LHead, -ScaleValue(3), -ScaleValue(3));
      LPath := BuildPath(RectF(LHead.Left, LHead.Top, LHead.Right, LHead.Bottom), Max(0, LRadius - 2));
      LPen := TGPPen.Create(DaisyWithAlpha(LColors.Text, 0.5), ScaleValue(2));
      try
        LGraphics.DrawPath(LPen, LPath);
      finally
        LPen.Free;
        LPath.Free;
      end;
    end;

    // Icons
    if FIcon <> aiNone then
      for I := 0 to FItems.Count - 1 do
      begin
        LHead := HeaderRect(I);
        LOpen := FItems[I].Expanded;
        LTextColor := LColors.Text;
        if not FItems[I].Enabled then
          LTextColor := DaisyWithAlpha(LTextColor, 0.4);
        LCx := LHead.Right - LPad - ScaleValue(6);
        LCy := (LHead.Top + LHead.Bottom) / 2;
        LHalf := ScaleValue(5);
        LW := Max(1.5, ScaleValue(2));
        LPen := TGPPen.Create(LTextColor, LW);
        try
          LPen.SetStartCap(LineCapRound);
          LPen.SetEndCap(LineCapRound);
          LPen.SetLineJoin(LineJoinRound);
          if FIcon = aiArrow then
          begin
            // chevron pointing down when closed, up when open
            if LOpen then
            begin
              LGraphics.DrawLine(LPen, LCx - LHalf, LCy + LHalf / 2, LCx, LCy - LHalf / 2);
              LGraphics.DrawLine(LPen, LCx, LCy - LHalf / 2, LCx + LHalf, LCy + LHalf / 2);
            end
            else
            begin
              LGraphics.DrawLine(LPen, LCx - LHalf, LCy - LHalf / 2, LCx, LCy + LHalf / 2);
              LGraphics.DrawLine(LPen, LCx, LCy + LHalf / 2, LCx + LHalf, LCy - LHalf / 2);
            end;
          end
          else
          begin
            LGraphics.DrawLine(LPen, LCx - LHalf, LCy, LCx + LHalf, LCy);
            if not LOpen then
              LGraphics.DrawLine(LPen, LCx, LCy - LHalf, LCx, LCy + LHalf);
          end;
        finally
          LPen.Free;
        end;
      end;
  finally
    LGraphics.Free; // flush before GDI text
  end;

  for I := 0 to FItems.Count - 1 do
  begin
    LTextColor := LColors.Text;
    if not FItems[I].Enabled then
      LTextColor := DaisyWithAlpha(LTextColor, 0.4);
    LHead := HeaderRect(I);
    LMid := LHead.Right - LPad - LIconW;
    DrawText(FItems[I].Title, Rect(LHead.Left + LPad, LHead.Top, Max(LHead.Left + LPad, LMid), LHead.Bottom),
      LTextColor, DaisyFontSize(SizeKind), True, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    if FItems[I].Expanded and (FItems[I].Content <> '') then
    begin
      LSection := SectionRect(I);
      DrawText(FItems[I].Content, Rect(LSection.Left + LPad, LHead.Bottom, LSection.Right - LPad, LSection.Bottom),
        DaisyWithAlpha(LTextColor, 0.8), DaisyFontSize(SizeKind), False, DT_LEFT or DT_TOP or DT_WORDBREAK);
    end;
  end;
end;

end.
