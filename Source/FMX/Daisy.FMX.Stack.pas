unit Daisy.FMX.Stack;

{
  TDaisyFmxStack - the DaisyUI "stack": the controls placed in it sit on top of each other and
  the ones behind the front control peek out on the side given by Direction, each smaller
  than the one in front. The last child is the front one; use Bring to Front / Send to Back
  to change the order. The stack sizes and places its children itself.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
  FMX.Types, FMX.Controls, FMX.Graphics, System.Diagnostics, Daisy.Theme, Daisy.Stack,
  Daisy.FMX.Control;

type
  TDaisyFmxStack = class(TDaisyControl)
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
    FWatch: TStopwatch;
    FItems: TArray<TControl>;
    FFrom: TArray<TRectF>;
    FTo: TArray<TRectF>;
    procedure SetDirection(const AValue: TDaisyStackDirection);
    procedure SetLayerOffset(const AValue: Integer);
    procedure SetAnimationTime(const AValue: Integer);
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
    procedure Loaded; override;
    procedure DoAddObject(const AObject: TFmxObject); override;
    procedure DoRemoveObject(const AObject: TFmxObject); override;
    procedure DoInsertObject(Index: Integer; const AObject: TFmxObject); override;
    procedure DrawContent(const AColors: TDaisyColors; const ARect: TRectF); override;
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

{ TDaisyFmxStack }

constructor TDaisyFmxStack.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDirection := sdBottom;
  FLayerOffset := 8;
  FAnimated := True;
  FAnimationTime := 300;
  FCycleOnClick := True;
  SetBounds(Position.X, Position.Y, 200, 140);
end;

destructor TDaisyFmxStack.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

function TDaisyFmxStack.DefaultCornerRadius: Integer;
begin
  Result := 0;
end;

function TDaisyFmxStack.DefaultShadowSize: Integer;
begin
  Result := 0;
end;

function TDaisyFmxStack.DefaultContentPadding: Integer;
begin
  Result := 0;
end;

function TDaisyFmxStack.DefaultStyleColors(AState: TDaisyState): TDaisyColors;
begin
  Result := Default(TDaisyColors);
  Result.Text := Theme.BaseContent;
end;

procedure TDaisyFmxStack.LayoutLayers;
var
  I, LCount: Integer;
  LRect: TRectF;
  LControl: TControl;
begin
  if FLaying or FAnimating or (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  LCount := ControlsCount;
  if LCount = 0 then
    Exit;
  FLaying := True;
  try
    for I := 0 to LCount - 1 do
    begin
      LControl := Controls[I];
      LRect := DaisyStackLayerRect(FDirection, LCount - 1 - I, LCount, RectF(0, 0, Width, Height),
        FLayerOffset);
      LControl.SetBounds(Round(LRect.Left), Round(LRect.Top), Round(LRect.Width),
        Round(LRect.Height));
    end;
  finally
    FLaying := False;
  end;
end;

procedure TDaisyFmxStack.DoAddObject(const AObject: TFmxObject);
begin
  inherited DoAddObject(AObject);
  HookChildren;
  LayoutLayers;
end;

procedure TDaisyFmxStack.DoInsertObject(Index: Integer; const AObject: TFmxObject);
begin
  inherited DoInsertObject(Index, AObject);
  HookChildren;
  LayoutLayers;
end;

// The children get a click handler that cycles the stack, unless they have their own
procedure TDaisyFmxStack.HookChildren;
var
  I: Integer;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) or FAnimating then
    Exit;
  for I := 0 to ControlsCount - 1 do
    if not Assigned(Controls[I].OnClick) then
      Controls[I].OnClick := ChildClick;
end;

procedure TDaisyFmxStack.ChildClick(Sender: TObject);
begin
  if FCycleOnClick then
    Cycle;
end;

procedure TDaisyFmxStack.Cycle;
var
  I, LCount: Integer;
  LArea: TRectF;
begin
  LCount := ControlsCount;
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
  LArea := RectF(0, 0, Width, Height);
  SetLength(FItems, LCount);
  SetLength(FFrom, LCount);
  SetLength(FTo, LCount);
  for I := 0 to LCount - 1 do
  begin
    FItems[I] := Controls[I];
    FFrom[I] := RectF(FItems[I].Position.X, FItems[I].Position.Y,
      FItems[I].Position.X + FItems[I].Width, FItems[I].Position.Y + FItems[I].Height);
    // The front control goes to the back; every other one moves a rank forward
    if I = LCount - 1 then
      FTo[I] := DaisyStackLayerRect(FDirection, LCount - 1, LCount, LArea, FLayerOffset)
    else
      FTo[I] := DaisyStackLayerRect(FDirection, LCount - 2 - I, LCount, LArea, FLayerOffset);
  end;
  FSwapped := False;
  FAnimating := True;
  if FTimer = nil then
  begin
    FTimer := TTimer.Create(nil);
    FTimer.OnTimer := AnimationTick;
  end;
  FTimer.Interval := 15;
  FWatch := TStopwatch.StartNew;
  FTimer.Enabled := True;
end;

procedure TDaisyFmxStack.ApplyFrame(AAmount: Double);
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

procedure TDaisyFmxStack.AnimationTick(Sender: TObject);
var
  LTime: Double;
begin
  LTime := FWatch.ElapsedMilliseconds / FAnimationTime;
  if LTime >= 1 then
    FinishAnimation
  else
    ApplyFrame(DaisyStackEase(LTime));
end;

procedure TDaisyFmxStack.FinishAnimation;
begin
  if not FAnimating then
    Exit;
  FTimer.Enabled := False;
  ApplyFrame(1);
  FAnimating := False;
  FItems := nil;
  LayoutLayers;
end;

procedure TDaisyFmxStack.SetAnimationTime(const AValue: Integer);
begin
  FAnimationTime := System.Math.Max(0, AValue);
end;

procedure TDaisyFmxStack.DoRemoveObject(const AObject: TFmxObject);
begin
  inherited DoRemoveObject(AObject);
  LayoutLayers;
end;

procedure TDaisyFmxStack.SizeChanged;
begin
  LayoutLayers;
  Repaint;
end;

procedure TDaisyFmxStack.Loaded;
begin
  inherited;
  HookChildren;
  LayoutLayers;
end;

procedure TDaisyFmxStack.SetDirection(const AValue: TDaisyStackDirection);
begin
  if FDirection <> AValue then
  begin
    FDirection := AValue;
    LayoutLayers;
    Repaint;
  end;
end;

procedure TDaisyFmxStack.SetLayerOffset(const AValue: Integer);
begin
  if (FLayerOffset <> AValue) and (AValue >= 0) then
  begin
    FLayerOffset := AValue;
    LayoutLayers;
    Repaint;
  end;
end;

// Only a design-time guide while the stack is empty
procedure TDaisyFmxStack.DrawContent(const AColors: TDaisyColors; const ARect: TRectF);
begin
  if (csDesigning in ComponentState) and (ControlsCount = 0) then
    StrokeRound(RectF(0, 0, Width, Height), 0, DaisyWithAlpha(Theme.BaseContent, 0.25), 1, True);
end;

end.
