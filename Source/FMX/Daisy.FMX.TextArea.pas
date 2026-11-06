unit Daisy.FMX.TextArea;

{
  TDaisyFmxTextArea - the DaisyUI "textarea": a multi-line text field with word
  wrap, a scroll bar when the text is taller than the box, variants, sizes,
  ghost / soft styles, a floating label, a fieldset legend and helper text.
  Colour emoji can be typed and pasted. The focused state only darkens the border.
}

interface

uses
  System.Classes, Daisy.FMX.TextInput;

type
  TDaisyFmxTextArea = class(TDaisyFmxCustomTextEdit)
  protected
    function IsMultiLine: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{ TDaisyFmxTextArea }

constructor TDaisyFmxTextArea.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetBounds(Position.X, Position.Y, 256, 96);
end;

function TDaisyFmxTextArea.IsMultiLine: Boolean;
begin
  Result := True;
end;

end.
