unit Daisy.VCL.Stack;

{
  TDaisyStack - the DaisyUI "stack": the controls placed in it sit on top of each other and
  the ones behind the front control peek out on the side given by Direction, each smaller
  than the one in front. The control at the top of the z-order is the front one; use
  Bring to Front / Send to Back to change the order. The stack sizes and places its
  children itself.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  Vcl.Controls, Vcl.ExtCtrls, Daisy.Theme, Daisy.Stack, Daisy.VCL.Control;

type
  TDaisyStack = class(TDaisyControl)
  strict private
    FDirection: TDaisyStackDirection;
    FLayerOffset: Integer;
    FAnimated: Boolean;
    FAnimationTime: Integer;
    FCycleOnClick: Boolean;
    FLaying: Boolean;
    FAnimating: Boolean;
    FSwapped: Boolean;
    FTimer: TTimer;
    FStartTick: UInt64;
    FItems: TArray<TControl>;
    FFrom: TArray<TRectF>;
    FTo: TArray<TRectF>;
    procedure SetDirection(const Value: TDaisyStackDirection);
    procedure SetLayerOffset(const Value: Integer);
    procedure SetAnimationTime(const Value: Integer);
    procedure CMControlListChange(var Message: TCMControlListChange); message CM_CONTROLLISTCHANGE;
    procedure HookChildren;
    procedure ChildClick(Sender: TObject);
    procedure AnimationTick(Sender: TObject);
    procedure FinishAnimation;
    procedure ApplyFrame(AAmount: Double);
  protected
    function DefaultCornerRadius: Integer; override;
    function DefaultShadowSize: Integer; override;
    function DefaultContentPadding: Integer; override;
    function DefaultStyleColors(AState: TDaisyState): TDaisyColors; override;
    procedure SizeChanged; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Places the children again; done automatically when the stack changes
    procedure LayoutLayers;
    // Sends the front control to the back so the one underneath comes forward
    procedure Cycle;
  published
    // The side the layers behind the front one peek out on
    property Direction: TDaisyStackDirection read FDirection write SetDirection default sdBottom;
    // How far each layer peeks out, in pixels
    property LayerOffset: Integer read FLayerOffset write SetLayerOffset default 8;
    // Slides the layers when the order changes
    property Animated: Boolean read FAnimated write FAnimated default True;
    // Length of the slide in milliseconds
    property AnimationTime: Integer read FAnimationTime write SetAnimationTime default 300;
    // At run time a click on a child that has no OnClick of its own calls Cycle
    property CycleOnClick: Boolean read FCycleOnClick write FCycleOnClick default True;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TDaisyStack }

constructor TDaisyStack.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FDirection := sdBottom;
  FLayerOffset := 8;
  FAnimated := True;
  FAnimationTime := 300;
  FCycleOnClick := True;
  SetBounds(Left, Top, 200, 140);
end;

destructor TDaisyStack.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

function TDaisyStack.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyStack.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyStack.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyStack.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyStack.LayoutLayers;
var
  I, LCount: Integer;
  LArea, LRect: TRectF;
  LControl: TControl;
begin
  if FLaying or FAnimating or (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  LCount := ControlCount;
  if LCount = 0 then
    Exit;
  FLaying := True;
  try
    LArea := RectF(0, 0, ClientWidth, ClientHeight);
    for I := 0 to LCount - 1 do
    begin
      LControl := Controls[I];
      LRect := DaisyStackLayerRect(FDirection, LCount - 1 - I, LCount, LArea,
        ScaleValue(FLayerOffset));
      LControl.SetBounds(Round(LRect.Left), Round(LRect.Top), Round(LRect.Width),
        Round(LRect.Height));
    end;
  finally
    FLaying := False;
  end;
end;

procedure TDaisyStack.CMControlListChange(var Message: TCMControlListChange);
begin
  inherited;
  if FAnimating then
    Exit;
  HookChildren;
  LayoutLayers;
end;

// The children get a click handler that cycles the stack, unless they have their own
procedure TDaisyStack.HookChildren;
var
  I: Integer;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) then
    Exit;
  for I := 0 to ControlCount - 1 do
    if not Assigned(TControlAccess(Controls[I]).OnClick) then
      TControlAccess(Controls[I]).OnClick := ChildClick;
end;

procedure TDaisyStack.ChildClick(Sender: TObject);
begin
  if FCycleOnClick then
    Cycle;
end;

procedure TDaisyStack.Cycle;
var
  I, LCount: Integer;
  LArea: TRectF;
begin
  LCount := ControlCount;
  if LCount < 2 then
    Exit;
  if FAnimating then
    FinishAnimation;
  if not FAnimated or (csDesigning in ComponentState) or (FAnimationTime <= 0) then
  begin
    Controls[LCount - 1].SendToBack;
    LayoutLayers;
    Exit;
  end;
  LArea := RectF(0, 0, ClientWidth, ClientHeight);
  SetLength(FItems, LCount);
  SetLength(FFrom, LCount);
  SetLength(FTo, LCount);
  for I := 0 to LCount - 1 do
  begin
    FItems[I] := Controls[I];
    FFrom[I] := RectF(FItems[I].Left, FItems[I].Top, FItems[I].Left + FItems[I].Width,
      FItems[I].Top + FItems[I].Height);
    // The front control goes to the back; every other one moves a rank forward
    if I = LCount - 1 then
      FTo[I] := DaisyStackLayerRect(FDirection, LCount - 1, LCount, LArea, ScaleValue(FLayerOffset))
    else
      FTo[I] := DaisyStackLayerRect(FDirection, LCount - 2 - I, LCount, LArea,
        ScaleValue(FLayerOffset));
  end;
  FSwapped := False;
  FAnimating := True;
  if FTimer = nil then
  begin
    FTimer := TTimer.Create(nil);
    FTimer.OnTimer := AnimationTick;
  end;
  FTimer.Interval := 15;
  FStartTick := GetTickCount64;
  FTimer.Enabled := True;
end;

procedure TDaisyStack.ApplyFrame(AAmount: Double);
var
  I: Integer;
  LRect: TRectF;
begin
  FLaying := True;
  try
    for I := 0 to High(FItems) do
    begin
      LRect := DaisyStackLerpRect(FFrom[I], FTo[I], AAmount);
      FItems[I].SetBounds(Round(LRect.Left), Round(LRect.Top), Round(LRect.Width),
        Round(LRect.Height));
    end;
    // Half way the moving control passes behind the one coming forward
    if (AAmount >= 0.5) and not FSwapped then
    begin
      FSwapped := True;
      FItems[High(FItems)].SendToBack;
    end;
  finally
    FLaying := False;
  end;
end;

procedure TDaisyStack.AnimationTick(Sender: TObject);
var
  LTime: Double;
begin
  LTime := (GetTickCount64 - FStartTick) / FAnimationTime;
  if LTime >= 1 then
    FinishAnimation
  else
    ApplyFrame(DaisyStackEase(LTime));
end;

procedure TDaisyStack.FinishAnimation;
begin
  if not FAnimating then
    Exit;
  FTimer.Enabled := False;
  ApplyFrame(1);
  FAnimating := False;
  FItems := nil;
  LayoutLayers;
end;

procedure TDaisyStack.SetAnimationTime(const Value: Integer);
begin
  FAnimationTime := System.Math.Max(0, Value);
end;

procedure TDaisyStack.SizeChanged;
begin
  LayoutLayers;
  Invalidate;
end;

procedure TDaisyStack.Resize;
begin
  LayoutLayers;
  inherited;
end;

procedure TDaisyStack.Loaded;
begin
  inherited;
  HookChildren;
  LayoutLayers;
end;

procedure TDaisyStack.SetDirection(const Value: TDaisyStackDirection);
begin
  if FDirection <> Value then
  begin
    FDirection := Value;
    LayoutLayers;
    Invalidate;
  end;
end;

procedure TDaisyStack.SetLayerOffset(const Value: Integer);
begin
  if (FLayerOffset <> Value) and (Value >= 0) then
  begin
    FLayerOffset := Value;
    LayoutLayers;
    Invalidate;
  end;
end;

// Only a design-time guide while the stack is empty
procedure TDaisyStack.DrawContent(const AColors: TDaisyColors; const ARect: TRect);
var
  LGraphics: TGPGraphics;
begin
  if not (csDesigning in ComponentState) or (ControlCount > 0) then
    Exit;
  LGraphics := NewGraphics;
  try
    StrokeRoundRect(LGraphics, RectF(0.5, 0.5, ClientWidth - 1, ClientHeight - 1), 0,
      DaisyWithAlpha(Theme.BaseContent, 0.25), 1, True);
  finally
    LGraphics.Free;
  end;
end;

end.
