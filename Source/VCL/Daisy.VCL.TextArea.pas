unit Daisy.VCL.TextArea;

{
  TDaisyTextArea - the DaisyUI "textarea": a multi-line text field with word
  wrap, a scroll bar when the text is taller than the box, variants, sizes,
  ghost / soft styles, a floating label, a fieldset legend and
  helper text. Colour emoji can be typed and pasted. The focused state only
  darkens the border.
}

interface

uses
  System.Classes, Daisy.VCL.TextInput;

type
  TDaisyTextArea = class(TDaisyCustomTextEdit)
  protected
    function IsMultiLine: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{ TDaisyTextArea }

constructor TDaisyTextArea.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetBounds(Left, Top, 256, ScaleValue(96));
end;

function TDaisyTextArea.IsMultiLine: Boolean;
begin
  Result := True;
end;

end.
