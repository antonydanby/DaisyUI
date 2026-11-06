# Daisy UI Component Manual

This manual describes every component in the Daisy UI VCL and FMX sets. The two sets are identical: each `TDaisyXxx` (VCL, palette page **Daisy VCL**) has an `TDaisyFmxXxx` twin (FMX, palette page **Daisy FMX**) with the same properties, events and behavior. Both share one palette icon.

The designs are inspired by [daisyUI](https://daisyui.com). They are not exact copies.

## Contents

- [Common features](#common-features)
- [Components (A-Z)](#components-a-z)
- [Tips](#tips)

## Common features

All visual components descend from `TDaisyControl` (VCL) or `TDaisyFmxControl` (FMX). The following published properties are therefore available on every component unless stated otherwise.

| Property | Description |
| --- | --- |
| `ThemeKind` | Theme to use. `dtInherit` (default) takes the theme from the parent control, then from the form's `TDaisyFormStyler`. Others: light, dark, cupcake, dracula, corporate, pastel, wireframe, cmyk, winter, dim, nord, silk, bumblebee, emerald, halloween, garden, forest, lofi, fantasy, autumn. |
| `Variant` | Colour role: `dvDefault`, `dvNeutral`, `dvPrimary`, `dvSecondary`, `dvAccent`, `dvInfo`, `dvSuccess`, `dvWarning`, `dvError`. |
| `Style` | `dsSolid`, `dsOutline`, `dsDash`, `dsSoft`, `dsGhost`. |
| `SizeKind` | `dzXS`, `dzSM`, `dzMD` (default), `dzLG`, `dzXL`. Controls fonts and default metrics. |
| `ContentPadding` | Inner padding in pixels. `-1` uses the theme/size default. |
| `CornerRadius` | Corner radius in pixels. `-1` uses the theme/size default. |
| `ShadowSize` | Shadow size in pixels. `-1` uses the default for the component. |

The usual standard properties (`Align`, `Anchors`, `Constraints`, `Cursor`, `Enabled`, `Font`, `Hint`, `ShowHint`, `PopupMenu`, `TabOrder`, `TabStop`, `Visible`) and events (`OnClick`, `OnDblClick`, `OnEnter`, `OnExit`, `OnMouseDown`, `OnMouseMove`, `OnMouseUp`, `OnMouseEnter`, `OnMouseLeave`, `OnContextPopup`) are published as well.

Common behavior:

- **Theming:** change `ThemeKind` on a parent (for example a `TDaisyPanel` or the form via `TDaisyFormStyler`) and all children set to inherit follow it.
- **AutoFit / AutoHeight:** on components that have it, the control sizes itself to its content.
- **Icons:** `SVG` properties take SVG markup; `Emoji` properties take a text character.
- **Drawing:** all controls are drawn with anti-aliasing and no flicker.
- **Design time:** animations and timers are not started at design time.

## Components (A-Z)

### TDaisyAccordion, TDaisyFmxAccordion

A vertical list of collapsible panels, like daisyUI's *collapse/accordion*. Each item has a title and body text. Clicking a title expands it and, unless `AllowMultiple` is set, collapses the others.

- `Items`: the panels (title, body, expanded state).
- `Icon`: the expand indicator (none, arrow or plus/minus).
- `Joined`: draws the panels as one connected block instead of separate cards.
- `AllowMultiple`: lets several panels stay open.
- `OnToggle`: raised when a panel opens or closes.

### TDaisyAlert, TDaisyFmxAlert

A banner showing a message with an icon, for information, success, warning or error. The colour comes from `Variant` and the look from `Style` (solid, outline, dash, soft).

- `Caption`: the message text.
- `IconKind`: the icon shown at the start (info, success, warning, error, or none).

### TDaisyAnimationButton, TDaisyFmxAnimationButton

A `TDaisyLoadingButton` that automatically plays its loading animation for a short time when clicked, then stops.

- `AnimateOnClick`: enable the click animation.
- `Duration`: how long the animation runs.
- `OnAnimationFinished`: raised when it stops.
- Also has everything from `TDaisyLoadingButton`.

### TDaisyBadge, TDaisyFmxBadge

A small pill used for counts, tags and short status text.

- `Caption`: the text.
- `Icon`, `SVG`: an optional icon, and `IconPosition` (before or after the text).
- `AutoWidth`: sizes the badge to its text.
- Use `Variant`, `Style` and `SizeKind` for the look.

### TDaisyBadgeButton, TDaisyFmxBadgeButton

A `TDaisyButton` with a badge attached to its top corner, for example an inbox button with a message count.

- `BadgeText`, `ShowBadge`: the badge content and visibility.
- `BadgeVariant`, `BadgeStyle`, `BadgeSize`: the badge's own look.
- `BadgeIcon`, `BadgeSVG`: optional badge icon.

### TDaisyButton, TDaisyFmxButton

The standard button. Supports every variant, style and size, hover and pressed states, and keyboard focus.

- `Caption`: button text.
- `SVG`, `IconPosition`: optional icon and its placement.
- `ModalResult`: (VCL) closes a modal form with the given result when clicked.

### TDaisyCalendar, TDaisyFmxCalendar

A month calendar with month navigation, based on daisyUI's calendar.

- `SelectedDate`: the chosen date (single mode).
- `SelectionMode`: `csSingle` or `csRange`.
- `RangeStart`, `RangeEnd`: the chosen range (range mode).
- `FirstDayOfWeek`: Monday to Sunday.
- `ShowOutsideDays`: shows days from the neighbouring months.
- `OnChange`: raised when the selection changes.

### TDaisyCard, TDaisyFmxCard

A container with a title, body text and a soft shadow. It is a panel, so other controls can be placed on it.

- `Title`, `Body`: the heading and the text.
- `ShadowSize` adjusts the shadow.
- Inherits everything from `TDaisyPanel`.

### TDaisyChatBubble, TDaisyFmxChatBubble

A chat message in a bubble, on the left or right.

- `Caption`: the message.
- `Placement`: start (received) or end (sent).
- `Header`, `HeaderTime`, `Footer`: text above and below the bubble.
- `ShowAvatar`, `Avatar`, `SVG`, `AvatarText`: the avatar picture, SVG or initials.
- `AutoHeight`: grows with the message.

### TDaisyCheckBox, TDaisyFmxCheckBox

A check box.

- `Checked`, `Indeterminate`: state.
- `Caption`: the label.
- `AutoFit`: sizes to the caption.
- `OnChange`: raised when the state changes.

### TDaisyCircleButton, TDaisyFmxCircleButton

A round button that shows only an icon. Set `SVG` for the glyph. Same options as `TDaisyButton`.

### TDaisyCountdown, TDaisyFmxCountdown

A display of numeric segments (for example hours, minutes, seconds) with animated digit changes.

- `Segments`: the values shown.
- `Separator`: character between segments.
- `LabelPlacement`: where unit labels appear.
- `Boxed`: draws each segment in a box.
- `DigitCount`: minimum digits per segment.
- `Active`: starts and stops the countdown.
- `Animated`: animates digit changes.
- `ShowSeconds`: includes the seconds segment.
- `AutoFit`: fits to content.
- `OnFinished`: raised when the countdown reaches zero.

### TDaisyDatePicker, TDaisyFmxDatePicker

A text input that opens a calendar popup. The picked date is written back into the text field, and typing a date moves the calendar.

- `Date`: the selected date.
- `DateFormat`: how the date is shown in the text.
- `PopupPlacement`: where the calendar appears: `ppShowBelow` (default), `ppShowAbove`, `ppShowLeft`, `ppShowRight`.
- `CalendarVariant`: colour of the popup calendar.
- `FirstDayOfWeek`, `ShowOutsideDays`: passed to the calendar.
- `OnDateChange`: raised when the date changes.
- Also has the text input properties (`Placeholder`, `LabelText`, `Legend` and others).

### TDaisyDropdownMenu, TDaisyFmxDropdownMenu

A button that opens a popup list of items when clicked.

- `Items`: the menu entries.
- `Placement`: where the popup opens.
- `OnItemClick`: raised when an item is chosen.
- `OnOpen`, `OnClose`: raised as the popup shows and hides.

### TDaisyFieldSet, TDaisyFmxFieldSet

A bordered group container with a legend and an optional description, used to group related input fields. Child controls are placed inside it.

- `Legend`: the group heading.
- `Description`: small text under the group.

### TDaisyFloatingActionButton, TDaisyFmxFloatingActionButton

A round button that expands to show a set of round action buttons (a speed dial).

- `Caption`: the main button text or glyph.
- `Items`: the action buttons.
- `Direction`: the direction in which the items expand.
- `OnItemClick`: raised when an action is clicked.

### TDaisyFormStyler, TDaisyFmxFormStyler

A non-visual component that applies a Daisy theme to its form.

- `Theme`: the theme for the form and every inheriting control.
- `ThemedTitleBar`: also themes the window title bar.
- `StyleForm`: paints the form background.
- `StyleStdControls`: also styles standard controls (such as edit boxes and panels) placed on the form.

### TDaisyIndicator, TDaisyFmxIndicator

A wrapper that attaches a small item (badge, status dot or button) to a corner of the control placed inside it, such as a notification count on a card.

- `ItemKind`: `ikBadge`, `ikStatus` (a solid dot) or `ikButton`.
- `ItemText`: the badge or button text (not used for a status dot).
- `ItemVariant`, `ItemStyle`, `ItemSize`: the item's look.
- `HorizontalPlacement`: `ihStart`, `ihCenter`, `ihEnd`.
- `VerticalPlacement`: `ivTop`, `ivMiddle`, `ivBottom`.
- `ShowItem`: shows or hides the item.
- `OnItemClick`: raised when the item is clicked.

### TDaisyLabel, TDaisyFmxLabel

A themed text label.

- `Caption`, `Alignment`, `VerticalAlignment`, `WordWrap`, `AutoFit`.
- `Muted`: uses a softer text colour.

### TDaisyList, TDaisyFmxList

A list of rows, each with an image or icon, title, subtitle and optional action buttons.

- `Items`: the rows.
- `Header`: an optional heading above the list.
- `Layout`: arrangement of row content.
- `UppercaseSubtitle`: shows subtitles in capitals.
- `AutoHeight`: sizes to the number of rows.
- `OnItemClick`: raised when a row or action is clicked.

### TDaisyLoadingButton, TDaisyFmxLoadingButton

A button that can show a loading indicator while work is running.

- `Loading`: shows or hides the indicator (the button ignores clicks while loading).
- `LoadingKind`: spinner, ring, dots, bars or ball.
- `IndicatorPosition`: before or after the caption.
- `LoadingCaption`: text shown while loading.

### TDaisyMainMenu, TDaisyFmxMainMenu

A themed horizontal menu bar for the top of a form, with drop-down sub menus.

- `Items`: menu entries and sub entries.
- `IconSize`: icon size.
- `OnItemClick`: raised when an entry is clicked.

### TDaisyMenu, TDaisyFmxMenu

A menu that can be vertical or horizontal, with icons, separators, titles and nested items.

- `Items`: the entries.
- `Orientation`: vertical or horizontal.
- `IconSize`, `IconsOnly`: icon display.
- `Bordered`: draws a border.
- `AutoFit`: sizes to its items.
- `AutoActive`: highlights the clicked item.
- `OnItemClick`: raised when an entry is clicked.

### TDaisyPageControl, TDaisyFmxPageControl

A tabbed container. Add pages with **New Page** at design time; each page is a `TDaisyTabSheet` / `TDaisyFmxTabSheet`. Tab headers are styled by `Variant`, `Style` and `SizeKind`. Pages can be selected at design time by clicking them.

### TDaisyPanel, TDaisyFmxPanel

A plain themed container with a background, optional border and a soft shadow. Use it to group controls or to set a theme for everything inside it.

### TDaisyPopupMenu, TDaisyFmxPopupMenu

A themed context menu.

- `Items`: the entries.
- `IconSize`: icon size.
- `Target`: the control the menu belongs to.
- `OnPopup`: raised just before it opens.
- `OnItemClick`: raised when an entry is clicked.

### TDaisyProgress, TDaisyFmxProgress

A horizontal progress bar.

- `Min`, `Max`, `Value`: the range and current position.
- `Indeterminate`: shows a moving bar for unknown progress.
- `AutoFit`: sizes to the theme default.

### TDaisyRadialProgress, TDaisyFmxRadialProgress

A circular progress indicator.

- `Min`, `Max`, `Value`: the range and position.
- `Thickness`: ring width.
- `ShowValue`, `DisplayText`: text shown in the centre.
- `Filled`: fills the centre.

### TDaisyRange, TDaisyFmxRange

A slider.

- `Min`, `Max`, `Value`, `Step`: range and position.
- `Orientation`: `roHorizontal` or `roVertical`.
- `ShowFill`: colours the track up to the thumb.
- `TickCount`, `TickLabels`: tick marks and their labels.
- `AutoFit`: sizes to its content.
- `OnChange`: raised when the value changes.
- A focus ring appears around the thumb while the value is being changed and fades away after about two seconds.

### TDaisyRating, TDaisyFmxRating

A star or heart rating.

- `Value`, `Count`: current rating and number of shapes.
- `Shape`: `rsStar`, `rsStar2` or `rsHeart`.
- `AllowHalf`: half-step ratings.
- `AllowClear`: clicking the current value clears it.
- `ReadOnly`: display only.
- `MultiColor`: gives the shapes different colours.
- `Spacing`: gap between shapes.
- `AutoFit`, `OnChange`.

### TDaisySelect, TDaisyFmxSelect

A drop-down selection box.

- `Items`: the choices.
- `ItemIndex`: the selected index (`-1` for none).
- `Placeholder`: text shown when nothing is selected.
- `LabelText`, `LabelMode`: the label and where it is drawn.
- `Legend`, `Hint`: fieldset-style legend and helper text.
- `SelectedIndicator`: marks the selected item in the list.
- `Emoji`, `SVG`: leading icon.
- `DropDownRows`: how many rows the list shows.
- `AutoFit`, `OnChange`.

### TDaisySquareButton, TDaisyFmxSquareButton

A square button that shows only an icon. Set `SVG` for the glyph. Same options as `TDaisyButton`.

### TDaisyStack, TDaisyFmxStack

Places its child controls in layers like a deck of cards, with the last child on top.

- `Direction`: which side the lower layers peek out: `sdBottom`, `sdTop`, `sdStart`, `sdEnd`.
- `LayerOffset`: the offset of each layer.
- `CycleOnClick`: clicking a child sends the front one to the back (for a card, click its title).
- `Animated`, `AnimationTime`: animates the swap, in milliseconds.
- `Cycle` method: cycles from code.

### TDaisyStat, TDaisyFmxStat

A block of statistics, each with a title, large value, description and optional action.

- `Items`: the statistics.
- `Direction`: horizontal or vertical layout.
- `Centered`: centres the text.
- `AutoFit`: sizes to its content.
- `OnActionClick`: raised when an action is clicked.

### TDaisyStatus, TDaisyFmxStatus

A small dot showing a state, such as online or error.

- `Animation`: none, ping or bounce.
- `Emoji`, `SVG`: shows a glyph instead of a dot.
- `AutoFit`.

### TDaisySVGImage, TDaisyFmxSVGImage

Displays an SVG image.

- `SVG`: the SVG markup.
- `Colored`: keeps the SVG's own colours instead of using the theme text colour.

### TDaisySwap, TDaisyFmxSwap

Toggles between two states (and optionally a third, indeterminate state) by swapping one visual for another.

- `Active`: the on/off state.
- `Indeterminate`: the third state.
- `Effect`: `seFade`, `seRotate`, `seFlip` or `seNone`.
- `OnText`, `OffText`, `IndeterminateText`: text for each state.
- `OnIcon`, `OffIcon`, `IndeterminateIcon`: SVG for each state.
- `OnChange`: raised when the state changes.

### TDaisyTable, TDaisyFmxTable

A data table drawn from `Columns` and `Rows`.

- `Columns`, `Rows`: the content, including cell text, badges, images and buttons.
- `ShowHeader`, `ShowFooter`.
- `Zebra`: alternating row shading.
- `HoverRows`: highlights the row under the mouse.
- `Bordered`: draws a border.
- `RightToLeft`: reverses column order.
- `PinRows`: keeps header and footer visible while scrolling.
- `AutoHeight`: sizes to the row count.
- `OnRowClick`, `OnButtonClick`.

### TDaisyTabSheet, TDaisyFmxTabSheet

A single page of a `TDaisyPageControl`. Place the page's controls on it. Use its `Caption` for the tab text. It is created by the page control and can be selected at design time.

### TDaisyTextArea, TDaisyFmxTextArea

A multi-line text input. It shares the text input properties:

- `Text`, `Placeholder`, `ReadOnly`, `MaxLength`.
- `Legend`, `HelperText`, `LabelText`, `LabelMode`.
- `OnChange`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`.

### TDaisyTextInput, TDaisyFmxTextInput

A single-line text input.

- Everything listed under `TDaisyTextArea`.
- `PasswordChar`: masks the text.
- `StartEmoji`, `StartSVG`, `EndEmoji`, `EndSVG`: icons at either end.
- `AutoFit`: sizes the height to the font.

### TDaisyThemeController, TDaisyFmxThemeController

A toggle that switches the form between two themes, for example *Corporate* and *Dim*. Place it on a form and choose the two themes; it updates the theme of the form and every control that inherits it. The demos each include one.

### TDaisyToast, TDaisyFmxToast

Transient messages that appear in a corner of the parent and disappear after a delay. Place the toast on the parent that should host the messages (for example a tab sheet) and call `Post(Text, Variant)` (or `Post(Text, Variant, Seconds)`) to show a message. `Clear` removes all messages.

- `HorizontalPlacement`: `thStart`, `thCenter`, `thEnd`, measured from the parent's left edge.
- `VerticalPlacement`: `tvTop`, `tvMiddle`, `tvBottom`.
- `Duration`: 3, 4, 5 or 8 seconds.
- `MaxMessages`: the maximum number shown at once; older ones are removed.

### TDaisyToggle, TDaisyFmxToggle

An on/off switch.

- `Checked`, `Indeterminate`: state.
- `Caption`: the label.
- `ShowIcons`: draws tick and cross icons on the switch.
- `AutoFit`, `OnChange`.

## Tips

- Put a `TDaisyFormStyler` on every form so theme changes reach all controls.
- Use `TDaisyThemeController` to let users flip between a light and a dark theme.
- Use `Align` and `Anchors` for layout. Never create Daisy controls at run time just to lay out a form; place them at design time so they can be moved and resized.
- Edit `Source\Common` and `TDaisyControl` to change behavior shared by both sets.
