unit Daisy.ThemeController;

{
  Shared parts of the DaisyUI "theme controller": the looks a controller can take and
  the captions it shows.
}

interface

uses
  System.SysUtils, Daisy.Theme;

type
  TDaisyThemeControllerKind = (
    tkToggle,       // a toggle, with the Caption beside it
    tkToggleIcons,  // a toggle with a sun and a moon inside
    tkSunMoon,      // sun icon, toggle, moon icon
    tkCheckBox,     // a check box, with the Caption beside it
    tkSwap,         // a sun / moon swap icon that turns over
    tkButton,       // a button showing the name of the current theme
    tkRadio         // one radio button per theme
  );

// The caption a radio button or button shows for ATheme
function DaisyThemeControllerCaption(ATheme: TDaisyThemeKind): string;

implementation

function DaisyThemeControllerCaption(ATheme: TDaisyThemeKind): string;
begin
  Result := DaisyThemeCaption(ATheme);
  if Result = '' then
    Result := 'Theme';
end;

end.
