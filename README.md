# Daisy UI for Delphi

A set of **VCL** and **FireMonkey (FMX)** components for Delphi (RAD Studio 11 and later) that bring the look, feel and behavior of [daisyUI](https://daisyui.com) to native Windows applications.

## Credit and disclaimer

All of the visual design ideas come from **[daisyUI](https://daisyui.com)**, the component plugin for Tailwind CSS. Full credit goes to the daisyUI authors and contributors.

These components are **not an exact copy** of daisyUI. They are *inspired by* it: they aim to look and behave similarly, but pixel perfection is not a goal, some components are named differently, and not every daisyUI component has been implemented.

## Two identical sets

There is a VCL set and an FMX set, and **they are identical to each other** in appearance, properties and behavior.

| Set | Palette page | Class prefix | Package |
| --- | --- | --- | --- |
| VCL | Daisy VCL | `TDaisy...` | `DaisyVCLpkg` |
| FMX | Daisy FMX | `TDaisyFmx...` | `DaisyFMXpkg` |

- Every VCL component descends from `TDaisyControl`; every FMX component descends from `TDaisyFmxControl`. These hold everything common: theme, variant, style, size, corner radius, shadow and padding.
- VCL and FMX components share the same palette icon.
- Shared, framework independent logic lives in `Source\Common` (`DaisyCommonpkg`).
- Drawing is anti-aliased (GDI+ / Direct2D for VCL, native canvas for FMX).

## Themes, variants, styles and sizes

- **Themes (21):** light, dark, cupcake, dracula, corporate, pastel, wireframe, cmyk, winter, dim, nord, silk, bumblebee, emerald, halloween, garden, forest, lofi, fantasy, autumn, plus *inherit*.
- **Variants:** default, neutral, primary, secondary, accent, info, success, warning, error.
- **Styles:** solid, outline, dash, soft, ghost.
- **Sizes:** XS, SM, MD, LG, XL.

## Components

Listed alphabetically. See [Manual.md](Manual.md) for full detail.

- **TDaisyAccordion, TDaisyFmxAccordion:** collapsible panels, optionally joined, with single or multiple panels open at once.
- **TDaisyAlert, TDaisyFmxAlert:** a message banner with an icon, coloured by variant.
- **TDaisyAnimationButton, TDaisyFmxAnimationButton:** a loading button that plays a short busy animation when clicked.
- **TDaisyBadge, TDaisyFmxBadge:** a small pill label for counts, tags and status text, with optional icon.
- **TDaisyBadgeButton, TDaisyFmxBadgeButton:** a button with a badge attached to its corner.
- **TDaisyButton, TDaisyFmxButton:** the standard button, with variants, styles, sizes and an optional SVG icon.
- **TDaisyCalendar, TDaisyFmxCalendar:** a month calendar with single date or date range selection.
- **TDaisyCard, TDaisyFmxCard:** a titled container with body text and a soft shadow.
- **TDaisyChatBubble, TDaisyFmxChatBubble:** a chat message bubble with avatar, header and footer.
- **TDaisyCheckBox, TDaisyFmxCheckBox:** a check box with checked and indeterminate states.
- **TDaisyCircleButton, TDaisyFmxCircleButton:** a round icon-only button.
- **TDaisyCountdown, TDaisyFmxCountdown:** a segmented countdown display with animated digits.
- **TDaisyDatePicker, TDaisyFmxDatePicker:** a text input that drops down a calendar and writes the chosen date back into the text.
- **TDaisyDropdownMenu, TDaisyFmxDropdownMenu:** a button that opens a popup list of items.
- **TDaisyFieldSet, TDaisyFmxFieldSet:** a grouping container with a legend and description.
- **TDaisyFloatingActionButton, TDaisyFmxFloatingActionButton:** a round button that expands into a set of action buttons.
- **TDaisyFormStyler, TDaisyFmxFormStyler:** non-visual component that applies a theme to a whole form.
- **TDaisyIndicator, TDaisyFmxIndicator:** attaches a badge, status dot or button to the corner of another control.
- **TDaisyLabel, TDaisyFmxLabel:** a themed text label.
- **TDaisyList, TDaisyFmxList:** a list of rows with title, subtitle and actions.
- **TDaisyLoadingButton, TDaisyFmxLoadingButton:** a button that can show a spinner while work is in progress.
- **TDaisyMainMenu, TDaisyFmxMainMenu:** a themed horizontal main menu bar.
- **TDaisyMenu, TDaisyFmxMenu:** a vertical or horizontal menu with icons and nested items.
- **TDaisyPageControl, TDaisyFmxPageControl:** a tabbed container.
- **TDaisyPanel, TDaisyFmxPanel:** a plain themed container panel.
- **TDaisyPopupMenu, TDaisyFmxPopupMenu:** a themed context menu.
- **TDaisyProgress, TDaisyFmxProgress:** a horizontal progress bar, determinate or indeterminate.
- **TDaisyRadialProgress, TDaisyFmxRadialProgress:** a circular progress indicator.
- **TDaisyRange, TDaisyFmxRange:** a slider with optional ticks and labels.
- **TDaisyRating, TDaisyFmxRating:** a star or heart rating control.
- **TDaisySelect, TDaisyFmxSelect:** a drop-down selection box.
- **TDaisySquareButton, TDaisyFmxSquareButton:** a square icon-only button.
- **TDaisyStack, TDaisyFmxStack:** layers child controls like a deck; click to bring the next one forward.
- **TDaisyStat, TDaisyFmxStat:** a statistics panel showing titles, values and descriptions.
- **TDaisyStatus, TDaisyFmxStatus:** a small status dot, optionally animated.
- **TDaisySVGImage, TDaisyFmxSVGImage:** displays an SVG image.
- **TDaisySwap, TDaisyFmxSwap:** toggles between two (or three) states with a fade, rotate or flip effect.
- **TDaisyTable, TDaisyFmxTable:** a data table with header, footer, zebra rows and hover.
- **TDaisyTabSheet, TDaisyFmxTabSheet:** a page of a `TDaisyPageControl`.
- **TDaisyTextArea, TDaisyFmxTextArea:** a multi-line text input.
- **TDaisyTextInput, TDaisyFmxTextInput:** a single-line text input with label, legend and icons.
- **TDaisyThemeController, TDaisyFmxThemeController:** a toggle that switches a form between two themes.
- **TDaisyToast, TDaisyFmxToast:** transient popup messages stacked in a corner of the parent.
- **TDaisyToggle, TDaisyFmxToggle:** an on/off switch.

## Source layout

| Path | Purpose |
| --- | --- |
| `Source\Common` | Framework independent logic: themes, colours, items, calendars, ranges, SVG and more |
| `Source\VCL` | VCL components and `Daisy.VCL.Reg.pas` registration |
| `Source\FMX` | FMX components and `Daisy.FMX.Reg.pas` registration |
| `Icons` | Component palette icons (shared by VCL and FMX) |
| `Demos` | Demo applications |
| `DaisyCommonpkg`, `DaisyVCLpkg`, `DaisyFMXpkg` | Runtime/design-time packages |
| `DaisyUIGroup.groupproj` | Project group containing the packages |

## Getting started

1. Open `DaisyUIGroup.groupproj` in RAD Studio.
2. Build `DaisyCommonpkg`, then install `DaisyVCLpkg` and/or `DaisyFMXpkg`.
3. Add `Source\Common`, `Source\VCL` and/or `Source\FMX` to your library path.
4. Drop components from the **Daisy VCL** or **Daisy FMX** palette pages onto a form.

## Demos

Each demo exists as a VCL and an FMX application with identical content.

| Demo | Content |
| --- | --- |
| `Basic-01` | Styles, sizes, cards, alerts, indicators, field sets, stacks, swaps, variants |
| `Basic-02` | FAB, toasts, accordion, loading buttons, dropdown, rating, range, buttons |
| `Basic-03` | Badges, styles, badge buttons, SVG icons |
| `Basic-04` | Countdown, list, stat, chat, progress |
| `Basic-05` | Utilities, SVG, status, select, tables |
| `Edits-01` | Menus, text input, text area, select, toggle, calendar and date picker |

Every demo has a Theme Controller to switch between two themes.

## Notes

- Demos use components placed at design time; nothing is created on the fly.
- Change shared behavior in `TDaisyControl` and the `Source\Common` units so both sets stay in step.

# License

This project is licensed under the MIT License - see the LICENSE file for details.
