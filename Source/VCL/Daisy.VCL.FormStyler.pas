unit Daisy.VCL.FormStyler;

{
  TDaisyFormStyler - non-visual component. Drop one on a form to make the form
  follow the current Daisy theme: the form colour, the non-client title bar
  (TDaisyControl.ThemedTitleBar) and the font colour of standard labels and
  check boxes. ApplyTheme switches the theme for the whole application.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.UITypes, Vcl.Controls, Vcl.Graphics,
  Vcl.Forms, Vcl.StdCtrls, Daisy.Theme, Daisy.VCL.Control;

type
  TDaisyFormStyler = class(TComponent)
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
    // Paints the form background with the theme's base colour
    property StyleForm: Boolean read FStyleForm write SetStyleForm default True;
    // Colours the font of the form's plain TLabel / TCheckBox / TRadioButton controls
    property StyleStdControls: Boolean read FStyleStdControls write SetStyleStdControls default True;
  end;

implementation

constructor TDaisyFormStyler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTheme := dtLight;
  FThemedTitleBar := True;
  FStyleForm := True;
  FStyleStdControls := True;
  if not (csDesigning in ComponentState) then
    DaisyThemes.AddListener(GlobalThemeChanged);
end;

destructor TDaisyFormStyler.Destroy;
begin
  DaisyRemoveThemeListener(GlobalThemeChanged);
  inherited;
end;

function TDaisyFormStyler.OwnerForm: TCustomForm;
begin
  if Owner is TCustomForm then
    Result := TCustomForm(Owner)
  else
    Result := nil;
end;

procedure TDaisyFormStyler.Loaded;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  TDaisyControl.ThemedTitleBar := FThemedTitleBar;
  ApplyTheme(FTheme);
  // the form window only exists once the form is shown
  TThread.ForceQueue(nil, TDaisyControl.ApplyTitleBars);
end;

procedure TDaisyFormStyler.GlobalThemeChanged(Sender: TObject);
begin
  Refresh;
end;

procedure TDaisyFormStyler.ApplyTheme(const aTheme: TDaisyThemeKind);
begin
  if aTheme = dtInherit then
    FTheme := DaisyThemes.Current
  else
    FTheme := aTheme;
  DaisyThemes.Current := FTheme;
  Refresh;
end;

procedure TDaisyFormStyler.Refresh;
var
  LForm: TCustomForm;
  LTheme: TDaisyTheme;
  I: Integer;
  LColor: TColor;
begin
  LForm := OwnerForm;
  if (LForm = nil) or (csDestroying in LForm.ComponentState) then
    Exit;
  LTheme := DaisyGetTheme(dtInherit);
  if FStyleForm then
    LForm.Color := DaisyToColor(LTheme.Base100);
  if FStyleStdControls then
  begin
    LColor := DaisyToColor(LTheme.BaseContent);
    for I := 0 to LForm.ComponentCount - 1 do
      if LForm.Components[I] is TLabel then
        TLabel(LForm.Components[I]).Font.Color := LColor
      else if LForm.Components[I] is TCheckBox then
        TCheckBox(LForm.Components[I]).Font.Color := LColor
      else if LForm.Components[I] is TRadioButton then
        TRadioButton(LForm.Components[I]).Font.Color := LColor
      else if FStyleForm and (LForm.Components[I] is TScrollBox) then
        TScrollBox(LForm.Components[I]).Color := DaisyToColor(LTheme.Base100);
  end;
  if FThemedTitleBar then
    TDaisyControl.ApplyTitleBars;
  LForm.Invalidate;
end;

procedure TDaisyFormStyler.SetTheme(const Value: TDaisyThemeKind);
begin
  if FTheme = Value then
    Exit;
  FTheme := Value;
  if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    ApplyTheme(Value);
end;

procedure TDaisyFormStyler.SetThemedTitleBar(const Value: Boolean);
begin
  if FThemedTitleBar = Value then
    Exit;
  FThemedTitleBar := Value;
  if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    TDaisyControl.ThemedTitleBar := Value;
end;

procedure TDaisyFormStyler.SetStyleForm(const Value: Boolean);
begin
  if FStyleForm <> Value then
  begin
    FStyleForm := Value;
    if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
      Refresh;
  end;
end;

procedure TDaisyFormStyler.SetStyleStdControls(const Value: Boolean);
begin
  if FStyleStdControls <> Value then
  begin
    FStyleStdControls := Value;
    if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
      Refresh;
  end;
end;

end.
