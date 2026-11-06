unit Daisy.FMX.FormStyler;

{
  TDaisyFmxFormStyler - non-visual component. Drop one on a form to make the form
  follow the current Daisy theme: the form fill, the non-client title bar
  (TDaisyControl.ThemedTitleBar, Windows) and the font colour of standard labels
  and check boxes. ApplyTheme switches the theme for the whole application.
}

interface

uses
  System.SysUtils, System.Classes, System.UITypes, FMX.Types, FMX.Graphics, FMX.Forms,
  FMX.StdCtrls, Daisy.Theme, Daisy.FMX.Control;

type
  TDaisyFmxFormStyler = class(TComponent)
  strict private
    FTheme: TDaisyThemeKind;
    FThemedTitleBar: Boolean;
    FStyleForm: Boolean;
    FStyleStdControls: Boolean;
    procedure SetTheme(const Value: TDaisyThemeKind);
    procedure SetThemedTitleBar(const Value: Boolean);
    procedure SetStyleForm(const Value: Boolean);
    procedure SetStyleStdControls(const Value: Boolean);
    function OwnerForm: TCustomForm;
    function IsRuntime: Boolean;
    procedure GlobalThemeChanged(Sender: TObject);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Makes aTheme the current theme of every Daisy control and restyles the form
    procedure ApplyTheme(const aTheme: TDaisyThemeKind);
    // Re-applies the current theme to the form without changing it
    procedure Refresh;
  published
    property Theme: TDaisyThemeKind read FTheme write SetTheme default dtLight;
    property ThemedTitleBar: Boolean read FThemedTitleBar write SetThemedTitleBar default True;
    // Fills the form background with the theme's base colour
    property StyleForm: Boolean read FStyleForm write SetStyleForm default True;
    // Colours the font of the form's plain TLabel / TCheckBox controls
    property StyleStdControls: Boolean read FStyleStdControls write SetStyleStdControls default True;
  end;

implementation

constructor TDaisyFmxFormStyler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTheme := dtLight;
  FThemedTitleBar := True;
  FStyleForm := True;
  FStyleStdControls := True;
  if not (csDesigning in ComponentState) then
    DaisyThemes.AddListener(GlobalThemeChanged);
end;

destructor TDaisyFmxFormStyler.Destroy;
begin
  DaisyRemoveThemeListener(GlobalThemeChanged);
  inherited;
end;

function TDaisyFmxFormStyler.IsRuntime: Boolean;
begin
  Result := not (csLoading in ComponentState) and not (csDesigning in ComponentState);
end;

function TDaisyFmxFormStyler.OwnerForm: TCustomForm;
begin
  if Owner is TCustomForm then
    Result := TCustomForm(Owner)
  else
    Result := nil;
end;

procedure TDaisyFmxFormStyler.Loaded;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  TDaisyControl.ThemedTitleBar := FThemedTitleBar;
  ApplyTheme(FTheme);
  // the form window only exists once the form is shown
  TThread.ForceQueue(nil, TDaisyControl.ApplyTitleBars);
end;

procedure TDaisyFmxFormStyler.GlobalThemeChanged(Sender: TObject);
begin
  Refresh;
end;

procedure TDaisyFmxFormStyler.ApplyTheme(const aTheme: TDaisyThemeKind);
begin
  if aTheme = dtInherit then
    FTheme := DaisyThemes.Current
  else
    FTheme := aTheme;
  DaisyThemes.Current := FTheme;
  Refresh;
end;

procedure TDaisyFmxFormStyler.Refresh;
var
  LForm: TCustomForm;
  LTheme: TDaisyTheme;
  LComp: TComponent;
  I: Integer;
begin
  LForm := OwnerForm;
  if (LForm = nil) or (csDestroying in LForm.ComponentState) then
    Exit;
  LTheme := DaisyGetTheme(dtInherit);
  if FStyleForm then
  begin
    LForm.Fill.Kind := TBrushKind.Solid;
    LForm.Fill.Color := LTheme.Base100;
  end;
  if FStyleStdControls then
    for I := 0 to LForm.ComponentCount - 1 do
    begin
      LComp := LForm.Components[I];
      if LComp is TLabel then
      begin
        TLabel(LComp).StyledSettings := TLabel(LComp).StyledSettings - [TStyledSetting.FontColor];
        TLabel(LComp).TextSettings.FontColor := LTheme.BaseContent;
      end
      else if LComp is TCheckBox then
      begin
        TCheckBox(LComp).StyledSettings := TCheckBox(LComp).StyledSettings - [TStyledSetting.FontColor];
        TCheckBox(LComp).TextSettings.FontColor := LTheme.BaseContent;
      end;
    end;
  if FThemedTitleBar then
    TDaisyControl.ApplyTitleBars;
  LForm.Invalidate;
end;

procedure TDaisyFmxFormStyler.SetTheme(const Value: TDaisyThemeKind);
begin
  if FTheme = Value then
    Exit;
  FTheme := Value;
  if IsRuntime then
    ApplyTheme(Value);
end;

procedure TDaisyFmxFormStyler.SetThemedTitleBar(const Value: Boolean);
begin
  if FThemedTitleBar = Value then
    Exit;
  FThemedTitleBar := Value;
  if IsRuntime then
    TDaisyControl.ThemedTitleBar := Value;
end;

procedure TDaisyFmxFormStyler.SetStyleForm(const Value: Boolean);
begin
  if FStyleForm <> Value then
  begin
    FStyleForm := Value;
    if IsRuntime then
      Refresh;
  end;
end;

procedure TDaisyFmxFormStyler.SetStyleStdControls(const Value: Boolean);
begin
  if FStyleStdControls <> Value then
  begin
    FStyleStdControls := Value;
    if IsRuntime then
      Refresh;
  end;
end;

end.
