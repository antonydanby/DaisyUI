# Working with IconPath

----------

**If i wanted to use SVG icons in these components would I have to enable Skia ad then distribute the skia DLL or is there a way around this ?**

---

Not necessarily. It depends on the framework.

**FMX**
- FMX has no built-in SVG support apart from path data. The `TPath` and `TPathData` classes take SVG path strings (the `d="..."` attribute) with no extra dependencies.
- The `TDaisyIconKind` icons are probably already drawn this way, as stroked path outlines.
- For full SVG files, use Skia4Delphi. It ships with Delphi 12+ and needs its native library. It is statically linked on mobile and macOS, but on Windows you distribute `sk4d.dll`.

**VCL**
- Delphi 13 includes `TSVGIconImageList` / `TSVGImage` support through Skia, which needs the same DLL.
- Without Skia, you can parse SVG path data yourself and draw it with GDI+ or Direct2D. `ID2D1PathGeometry` can be built from path commands.
- Direct2D in Windows 10+ also supports SVG natively through `ID2D1DeviceContext5::CreateSvgDocument` and `DrawSvgDocument`. No DLL is needed, but it is Windows 10 Creators Update or later only, and the Delphi wrapper units are thin.
- Third-party options such as the pure-Delphi SVGIconImageList (Ethea) avoid Skia as well.

**What I'd recommend:** support the SVG path-data subset in `Daisy.Theme` (`M L H V C S Q A Z`) and render it with GDI+/Direct2D in VCL and `TPathData` in FMX. That gives you one icon format shared by both frameworks, with no DLL. Icons would be single-colour, stroke-style shapes, which is what DaisyUI/Heroicons use.

Should I add an `IconPath` property to the buttons and badges for that?

----------

# SVG icons, IconPath d= extraction

I went to tabler and the SVG icons were nice, but how do I extract the path from this SVG example:

<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-settings">
        <path stroke="none" d="M0 0h24v24H0z" fill="none" />
        <path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065" />
        <path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" />
</svg>

or this:

<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-chevron-down">
        <path stroke="none" d="M0 0h24v24H0z" fill="none" />
        <path d="M6 9l6 6l6 -6" />
</svg>

---

Tabler icons often contain several <path> elements. Here is how to read them.
Rule

Ignore any path with stroke="none". It is an invisible 24×24 bounding box (M0 0h24v24H0z) and would draw a square.
Take the d="..." value from every remaining path.
If there is more than one, join them with a single space into one IconPath value.

Chevron-down (one real path):

M6 9l6 6l6 -6

Settings (two real paths, joined):

M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065 M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0

----------

**if I was searching for SVG's on https://fonts.google.com/icons how would i work out the IconPath value?**

---

Google's Material Symbols are filled shapes on a 24×24 grid (they use a 960×960 viewBox in the newer downloads). Your IconPath strokes outlines instead of filling, so most Material icons will look wrong. Here is how to get the value and what to expect.
Getting the path data

On fonts.google.com/icons, pick an icon and open the SVG download (or copy it from the side panel).
Open the .svg file in a text editor.
Copy the text inside d="..." on the <path> element. That string is the IconPath value.
Caveats

Filled shapes: they will render as thin outlines of the shape, not solid. Simple icons such as add, close and check may look acceptable. Complex ones such as home or star will look messy.
Coordinate scale: newer Material downloads use viewBox="0 -960 960 960". My parser assumes 0–24, so these will draw far too large and off-position. Choose the 24px size, or use the older "Material Icons" set, which is 24×24.
Several paths: icons with more than one <path> need their d values joined. Concatenate them into one string with a space between each.
Better sources Stroke-style sets match this feature directly:

Lucide (lucide.dev)
Heroicons (outline set)
Feather
Tabler

Copy the d value from any of these and it will look right.

*If you want true filled Material icons, I can add an IconFilled option and viewBox support. Do you want that for both VCL and FMX?*

----------

# SVG files/content versus IconPath

Ok, I get how the IconPath works, but I will be giving this component set away to the wider Delphi community eventually.
This wider community will mean that junior or mid range developers will pick this up. 
To those people working out the contents of the IconPath will be confusing and time consuming.

- I think it would be better if .IconPath remained as a private property 
- All components that now have .IconPath should instead expose a public .SVG property where the SVG contents are loaded via a file or pasted into the property
- We add a simple class in DaisyCommon with the name TDaisySVG with a class function to return the IconPath from passed in SVG contents
- If you can add support for true filled Material icons via IconFilled option and viewBox support then please add this to TDaisySVG also  
  - **HOWEVER**: Only do this if you can do so without adding any DLL's such as Ski DLL's to the development
  - IconFilled and viewBox support need to be private members in TDaisySVG
  - I hope it's clear, but only add the common elements that are common to both VCL and SVG to the TDaisySVG; 
    - otherwise add to existing logic in Daisy.VCL.Control and Daisy.FMX.Control

- Please ensure all components are updated with the new property / properties
- Please ensure any demos's that need updating are updated
