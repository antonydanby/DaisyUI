object FormEdits: TFormEdits
  Left = 0
  Top = 0
  Caption = 
    'DaisyUI VCL demo - toggle, text input, text area, select and men' +
    'us'
  ClientHeight = 600
  ClientWidth = 1284
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object ppMenu: TDaisyPopupMenu
    Left = 1240
    Top = 60
    Width = 36
    Height = 36
    TabOrder = 1
    Items = <
      item
        Caption = 'Cut'
        Icon.Emoji = #9986
        ShortCut = 'Ctrl+X'
        Items = <>
      end
      item
        Caption = 'Copy'
        Icon.Emoji = #55357#56523
        ShortCut = 'Ctrl+C'
        Items = <>
      end
      item
        Caption = 'Paste'
        Icon.Emoji = #55357#56523
        ShortCut = 'Ctrl+V'
        Items = <>
      end
      item
        Caption = '-'
        Items = <>
      end
      item
        Caption = 'Delete'
        Icon.Emoji = #55357#56785
        Items = <>
      end>
    Target = pnlRightClick
    OnItemClick = MenuItemClick
  end
  object mmMain: TDaisyMainMenu
    Left = 0
    Top = 0
    Width = 1284
    Height = 44
    Align = alTop
    TabOrder = 3
    Items = <
      item
        Caption = 'File'
        Items = <
          item
            Caption = 'New'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><path' +
                ' d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21h-10a2 2 0 0 1 -2 -' +
                '2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2"/></svg>')
            ShortCut = 'Ctrl+N'
            Items = <>
          end
          item
            Caption = 'Open'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><path' +
                ' d="M5 4h4l3 3h7a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2' +
                ' -2v-11a2 2 0 0 1 2 -2"/></svg>')
            ShortCut = 'Ctrl+O'
            Items = <>
          end
          item
            Caption = 'Save'
            Icon.Emoji = #55357#56510
            ShortCut = 'Ctrl+S'
            Items = <>
          end
          item
            Caption = '-'
            Items = <>
          end
          item
            Caption = 'Exit'
            ShortCut = 'Alt+F4'
            Items = <>
          end>
      end
      item
        Caption = 'Edit'
        Items = <
          item
            Caption = 'Cut'
            ShortCut = 'Ctrl+X'
            Items = <>
          end
          item
            Caption = 'Copy'
            ShortCut = 'Ctrl+C'
            Items = <>
          end
          item
            Caption = 'Paste'
            ShortCut = 'Ctrl+V'
            Items = <>
          end
          item
            Caption = 'Auto save'
            Checked = True
            AutoCheck = True
            Items = <>
          end>
      end
      item
        Caption = 'View'
        Items = <
          item
            Caption = 'Zoom in'
            Items = <>
          end
          item
            Caption = 'Zoom out'
            Items = <>
          end
          item
            Caption = 'Disabled option'
            Enabled = False
            Items = <>
          end>
      end
      item
        Caption = 'Help'
        Items = <
          item
            Caption = 'About'
            Icon.Emoji = #8505
            Items = <>
          end>
      end>
    OnItemClick = MenuItemClick
  end
  object pnlTop: TPanel
    Left = 0
    Top = 44
    Width = 1284
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    object lblTheme: TLabel
      Left = 24
      Top = 22
      Width = 40
      Height = 15
      Caption = 'Theme:'
    end
    object lblStatusLine: TLabel
      Left = 560
      Top = 22
      Width = 3
      Height = 15
    end
    object chkTitleBar: TDaisyCheckBox
      Left = 300
      Top = 16
      Width = 156
      Height = 30
      Cursor = crHandPoint
      TabOrder = 1
      TabStop = True
      OnClick = chkTitleBarClick
      Checked = True
      Caption = 'Theme the title bar'
    end
    object selTheme: TDaisySelect
      Left = 80
      Top = 10
      Width = 200
      Height = 40
      Hint = ''
      TabOrder = 0
      TabStop = True
      Items.Strings = (
        'Light'
        'Dark'
        'Cupcake'
        'Dracula'
        'Corporate'
        'Pastel'
        'Wireframe'
        'CMYK'
        'Winter'
        'Dim'
        'Nord'
        'Silk'
        'Bumblebee'
        'Emerald'
        'Halloween'
        'Garden'
        'Forest'
        'Lofi'
        'Fantasy'
        'Autumn')
      ItemIndex = 0
      Placeholder = 'Pick one'
      OnChange = ThemeSelectChange
    end
    object themeCtl: TDaisyThemeController
      Left = 1000
      Top = 4
      Width = 130
      Height = 52
      TabOrder = 3
      Kind = tkRadio
      OnChange = ThemeControllerChange
    end
  end
  object pcMain: TDaisyPageControl
    Left = 0
    Top = 104
    Width = 1284
    Height = 496
    Align = alClient
    TabOrder = 2
    TabStop = True
    ActivePageIndex = 1
    object tsMenuMore: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1282
      Height = 454
      TabOrder = 5
      Caption = 'Menu badges'
      object mnBadge: TDaisyMenu
        Left = 24
        Top = 12
        Width = 159
        Height = 128
        TabOrder = 0
        Items = <
          item
            Caption = 'Inbox'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><rect' +
                ' x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6l9 ' +
                '-6"/></svg>')
            Badge = '99+'
            Items = <>
          end
          item
            Caption = 'Updates'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><path' +
                ' d="M10 5a2 2 0 1 1 4 0a7 7 0 0 1 4 6v3a4 4 0 0 0 2 3h-16a4 4 0 ' +
                '0 0 2 -3v-3a7 7 0 0 1 4 -6"/><path d="M9 17v1a3 3 0 0 0 6 0v-1"/' +
                '></svg>')
            Badge = 'NEW'
            Items = <>
          end
          item
            Caption = 'Stats'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><path' +
                ' d="M3 12h4l3 8l4 -16l3 8h4"/></svg>')
            Badge = 'new'
            Items = <>
          end>
        OnItemClick = MenuItemClick
      end
      object mnCollapsible: TDaisyMenu
        Left = 284
        Top = 12
        Width = 128
        Height = 318
        TabOrder = 1
        Items = <
          item
            Caption = 'Item 1'
            Items = <>
          end
          item
            Caption = 'Parent'
            Items = <
              item
                Caption = 'Submenu 1'
                Items = <>
              end
              item
                Caption = 'Submenu 2'
                Items = <>
              end
              item
                Caption = 'Parent 2'
                Items = <
                  item
                    Caption = 'Deep 1'
                    Items = <>
                  end
                  item
                    Caption = 'Deep 2'
                    Items = <>
                  end>
              end>
          end
          item
            Caption = 'Item 3'
            Items = <>
          end>
        OnItemClick = MenuItemClick
      end
    end
    object tsSelect: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1282
      Height = 454
      TabOrder = 3
      Caption = 'Select'
      object selMany: TDaisySelect
        Left = 24
        Top = 12
        Width = 260
        Height = 40
        Hint = ''
        TabOrder = 0
        TabStop = True
        Items.Strings = (
          'Argentina'
          'Australia'
          'Austria'
          'Belgium'
          'Brazil'
          'Canada'
          'Chile'
          'China'
          'Denmark'
          'Egypt'
          'Finland'
          'France'
          'Germany'
          'Greece'
          'India'
          'Ireland'
          'Italy'
          'Japan'
          'Kenya'
          'Mexico'
          'Norway'
          'Peru'
          'Poland'
          'Spain')
        Placeholder = 'Pick a country (scrolls)'
      end
      object selScroll: TDaisySelect
        Left = 324
        Top = 12
        Width = 260
        Height = 40
        Hint = ''
        Variant = dvPrimary
        TabOrder = 1
        TabStop = True
        Items.Strings = (
          'One'
          'Two'
          'Three'
          'Four'
          'Five'
          'Six'
          'Seven'
          'Eight'
          'Nine'
          'Ten')
        Placeholder = 'Only 4 rows show'
        DropDownRows = 4
      end
    end
    object tsArea: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1282
      Height = 454
      TabOrder = 2
      Caption = 'Text area'
      object taBasic: TDaisyTextArea
        Left = 24
        Top = 12
        Width = 380
        Height = 112
        Cursor = crIBeam
        TabOrder = 0
        TabStop = True
        Text = ''
        Placeholder = 'Bio'
      end
      object taLong: TDaisyTextArea
        Left = 424
        Top = 12
        Width = 380
        Height = 112
        Cursor = crIBeam
        Variant = dvPrimary
        TabOrder = 1
        TabStop = True
        Text = 
          'Line 1 - scroll me'#13#10'Line 2'#13#10'Line 3'#13#10'Line 4'#13#10'Line 5'#13#10'Line 6'#13#10'Line' +
          ' 7'#13#10'Line 8 '#55357#56832#13#10'Line 9'#13#10'Line 10'
      end
      object taGhost: TDaisyTextArea
        Left = 824
        Top = 12
        Width = 380
        Height = 112
        Cursor = crIBeam
        Style = dsGhost
        TabOrder = 2
        TabStop = True
        Text = ''
        Placeholder = 'Ghost text area'
      end
    end
    object tsMenu: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1282
      Height = 454
      TabOrder = 4
      Caption = 'Menu'
      object mnVertical: TDaisyMenu
        Left = 24
        Top = 12
        Width = 152
        Height = 280
        TabOrder = 0
        Items = <
          item
            Caption = 'Home'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><path' +
                ' d="M3 12l9 -9l9 9"/><path d="M5 10v10h14v-10"/></svg>')
            Active = True
            Items = <>
          end
          item
            Caption = 'Search'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><circ' +
                'le cx="11" cy="11" r="7"/><path d="M21 21l-5 -5"/></svg>')
            Badge = 'new'
            Items = <>
          end
          item
            Caption = 'Account'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><circ' +
                'le cx="12" cy="8" r="4"/><path d="M4 21c0 -4 4 -6 8 -6s8 2 8 6"/' +
                '></svg>')
            Items = <
              item
                Caption = 'Profile'
                Items = <>
              end
              item
                Caption = 'Security'
                Items = <>
              end
              item
                Caption = 'Notifications'
                Items = <>
              end>
          end
          item
            Caption = 'Disabled'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><rect' +
                ' x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6l9 ' +
                '-6"/></svg>')
            Enabled = False
            Items = <>
          end>
        OnItemClick = MenuItemClick
      end
      object mnIconsOnly: TDaisyMenu
        Left = 284
        Top = 12
        Width = 60
        Height = 128
        TabOrder = 1
        Items = <
          item
            Caption = 'Home'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><path' +
                ' d="M3 12l9 -9l9 9"/><path d="M5 10v10h14v-10"/></svg>')
            Active = True
            Items = <>
          end
          item
            Caption = 'Search'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><circ' +
                'le cx="11" cy="11" r="7"/><path d="M21 21l-5 -5"/></svg>')
            Items = <>
          end
          item
            Caption = 'Mail'
            Icon.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
                'e-width="2" stroke-linecap="round" stroke-linejoin="round"><rect' +
                ' x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6l9 ' +
                '-6"/></svg>')
            Items = <>
          end>
        IconSize = mis24
        IconsOnly = True
        OnItemClick = MenuItemClick
      end
      object mnHorizontal: TDaisyMenu
        Left = 364
        Top = 12
        Width = 282
        Height = 52
        TabOrder = 2
        Items = <
          item
            Caption = 'Home'
            Active = True
            Items = <>
          end
          item
            Caption = 'Products'
            Items = <>
          end
          item
            Caption = 'Pricing'
            Badge = '3'
            Items = <>
          end
          item
            Caption = 'Contact'
            Items = <>
          end>
        Orientation = moHorizontal
        OnItemClick = MenuItemClick
      end
      object mnSm: TDaisyMenu
        Left = 364
        Top = 82
        Width = 95
        Height = 110
        SizeKind = dzSM
        TabOrder = 3
        Items = <
          item
            Caption = 'Small one'
            Active = True
            Items = <>
          end
          item
            Caption = 'Small two'
            Items = <>
          end
          item
            Caption = 'Small three'
            Items = <>
          end>
        OnItemClick = MenuItemClick
      end
      object mnLg: TDaisyMenu
        Left = 584
        Top = 82
        Width = 124
        Height = 152
        SizeKind = dzLG
        TabOrder = 4
        Items = <
          item
            Caption = 'Large one'
            Active = True
            Items = <>
          end
          item
            Caption = 'Large two'
            Items = <>
          end
          item
            Caption = 'Large three'
            Items = <>
          end>
        OnItemClick = MenuItemClick
      end
      object pnlRightClick: TDaisyPanel
        Left = 900
        Top = 12
        Width = 300
        Height = 140
        TabOrder = 5
        object lblRightClick: TDaisyLabel
          Left = 16
          Top = 16
          Width = 256
          Height = 19
          TabOrder = 0
          Caption = 'Right-click this panel for the popup menu'
        end
      end
    end
    object tsInput: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1282
      Height = 454
      TabOrder = 1
      Caption = 'Text input'
      object tiBasic: TDaisyTextInput
        Left = 24
        Top = 12
        Width = 280
        Height = 40
        Cursor = crIBeam
        TabOrder = 0
        TabStop = True
        Text = ''
        Placeholder = 'Type here'
      end
      object tiGhost: TDaisyTextInput
        Left = 324
        Top = 12
        Width = 280
        Height = 40
        Cursor = crIBeam
        Style = dsGhost
        TabOrder = 1
        TabStop = True
        Text = ''
        Placeholder = 'Ghost'
      end
      object tiPrimary: TDaisyTextInput
        Left = 624
        Top = 12
        Width = 280
        Height = 40
        Cursor = crIBeam
        Variant = dvPrimary
        TabOrder = 2
        TabStop = True
        Text = ''
        Placeholder = 'Primary'
      end
      object tiDisabled: TDaisyTextInput
        Left = 924
        Top = 12
        Width = 280
        Height = 40
        Cursor = crIBeam
        Enabled = False
        TabOrder = 3
        TabStop = True
        Text = ''
        Placeholder = 'Disabled'
      end
      object tiSearch: TDaisyTextInput
        Left = 24
        Top = 68
        Width = 280
        Height = 40
        Cursor = crIBeam
        TabOrder = 4
        TabStop = True
        Text = ''
        Placeholder = 'Search'
        StartSVG.Strings = (
          
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
            'e-width="2" stroke-linecap="round" stroke-linejoin="round"><circ' +
            'le cx="11" cy="11" r="7"/><path d="M21 21l-5 -5"/></svg>')
      end
      object tiEmoji: TDaisyTextInput
        Left = 324
        Top = 68
        Width = 280
        Height = 40
        Cursor = crIBeam
        TabOrder = 5
        TabStop = True
        Text = 'Emoji '#55357#56832#55357#56960
        StartEmoji = #55357#56589
      end
      object tiPassword: TDaisyTextInput
        Left = 624
        Top = 68
        Width = 280
        Height = 40
        Cursor = crIBeam
        TabOrder = 6
        TabStop = True
        Text = 'secret'
        Placeholder = 'Password'
        PasswordChar = '*'
        StartSVG.Strings = (
          
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strok' +
            'e-width="2" stroke-linecap="round" stroke-linejoin="round"><circ' +
            'le cx="8" cy="15" r="4"/><path d="M10.85 12.15l8.15 -8.15"/><pat' +
            'h d="M15 8l3 3"/></svg>')
      end
      object tiEndEmoji: TDaisyTextInput
        Left = 924
        Top = 68
        Width = 280
        Height = 40
        Cursor = crIBeam
        TabOrder = 7
        TabStop = True
        Text = ''
        Placeholder = 'Email'
        EndEmoji = #55357#56551
      end
      object tiXs: TDaisyTextInput
        Left = 24
        Top = 124
        Width = 200
        Height = 24
        Cursor = crIBeam
        SizeKind = dzXS
        TabOrder = 8
        TabStop = True
        Text = ''
        Placeholder = 'Xsmall'
      end
      object tiSm: TDaisyTextInput
        Left = 244
        Top = 124
        Width = 200
        Height = 32
        Cursor = crIBeam
        SizeKind = dzSM
        TabOrder = 9
        TabStop = True
        Text = ''
        Placeholder = 'Small'
      end
      object tiMd: TDaisyTextInput
        Left = 464
        Top = 124
        Width = 200
        Height = 40
        Cursor = crIBeam
        TabOrder = 10
        TabStop = True
        Text = ''
        Placeholder = 'Medium'
      end
      object tiLg: TDaisyTextInput
        Left = 684
        Top = 124
        Width = 240
        Height = 48
        Cursor = crIBeam
        SizeKind = dzLG
        TabOrder = 11
        TabStop = True
        Text = ''
        Placeholder = 'Large'
      end
      object tiXl: TDaisyTextInput
        Left = 944
        Top = 124
        Width = 260
        Height = 56
        Cursor = crIBeam
        SizeKind = dzXL
        TabOrder = 12
        TabStop = True
        Text = ''
        Placeholder = 'Xlarge'
      end
      object tiLegend: TDaisyTextInput
        Left = 24
        Top = 204
        Width = 280
        Height = 90
        Cursor = crIBeam
        TabOrder = 13
        TabStop = True
        Text = ''
        Placeholder = 'Type here'
        Legend = 'Your name'
        HelperText = 'Optional'
      end
      object tiFloating: TDaisyTextInput
        Left = 324
        Top = 212
        Width = 280
        Height = 48
        Cursor = crIBeam
        TabOrder = 14
        TabStop = True
        Text = ''
        Placeholder = 'mail@site.com'
        LabelText = 'Email'
        LabelMode = ilmFloating
      end
      object tiBefore: TDaisyTextInput
        Left = 624
        Top = 212
        Width = 280
        Height = 40
        Cursor = crIBeam
        TabOrder = 15
        TabStop = True
        Text = ''
        Placeholder = 'URL'
        LabelText = 'https://'
        LabelMode = ilmBefore
      end
      object tiAfter: TDaisyTextInput
        Left = 924
        Top = 212
        Width = 280
        Height = 40
        Cursor = crIBeam
        TabOrder = 16
        TabStop = True
        Text = ''
        Placeholder = 'domain'
        LabelText = '.com'
        LabelMode = ilmAfter
      end
      object tiSuccess: TDaisyTextInput
        Left = 24
        Top = 316
        Width = 280
        Height = 40
        Cursor = crIBeam
        Variant = dvSuccess
        TabOrder = 17
        TabStop = True
        Text = ''
        Placeholder = 'Success'
      end
      object tiWarning: TDaisyTextInput
        Left = 324
        Top = 316
        Width = 280
        Height = 40
        Cursor = crIBeam
        Variant = dvWarning
        TabOrder = 18
        TabStop = True
        Text = ''
        Placeholder = 'Warning'
      end
      object tiError: TDaisyTextInput
        Left = 624
        Top = 316
        Width = 280
        Height = 40
        Cursor = crIBeam
        Variant = dvError
        TabOrder = 19
        TabStop = True
        Text = ''
        Placeholder = 'Error'
      end
      object tiSoft: TDaisyTextInput
        Left = 924
        Top = 316
        Width = 280
        Height = 40
        Cursor = crIBeam
        Variant = dvSecondary
        Style = dsSoft
        TabOrder = 20
        TabStop = True
        Text = ''
        Placeholder = 'Soft'
      end
    end
    object tsCalendar: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1282
      Height = 454
      TabOrder = 6
      Caption = 'Calendar'
      object lblCalSingle: TDaisyLabel
        Left = 24
        Top = 8
        Width = 69
        Height = 19
        TabOrder = 0
        Caption = 'Single date'
      end
      object calSingle: TDaisyCalendar
        Left = 24
        Top = 36
        Width = 304
        Height = 328
        Cursor = crHandPoint
        TabOrder = 1
        TabStop = True
        SelectedDate = 46331.000000000000000000
        OnChange = CalendarChange
      end
      object lblCalRange: TDaisyLabel
        Left = 364
        Top = 8
        Width = 70
        Height = 19
        TabOrder = 2
        Caption = 'Date range'
      end
      object calRange: TDaisyCalendar
        Left = 364
        Top = 36
        Width = 304
        Height = 328
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 3
        TabStop = True
        SelectedDate = 46331.000000000000000000
        SelectionMode = csRange
        OnChange = CalendarChange
      end
      object lblCalOptions: TDaisyLabel
        Left = 704
        Top = 8
        Width = 51
        Height = 19
        TabOrder = 4
        Caption = 'Options'
      end
      object calOptions: TDaisyCalendar
        Left = 704
        Top = 36
        Width = 304
        Height = 328
        Cursor = crHandPoint
        Variant = dvAccent
        TabOrder = 5
        TabStop = True
        SelectedDate = 46331.000000000000000000
        OnChange = CalendarChange
      end
      object lblFirstDay: TDaisyLabel
        Left = 1040
        Top = 36
        Width = 108
        Height = 19
        TabOrder = 6
        Caption = 'First day of week:'
      end
      object selFirstDay: TDaisySelect
        Left = 1040
        Top = 60
        Width = 200
        Height = 40
        Hint = ''
        TabOrder = 7
        TabStop = True
        Items.Strings = (
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
          'Saturday'
          'Sunday')
        ItemIndex = 0
        Placeholder = 'Pick one'
        OnChange = CalendarOptionChange
      end
      object chkOutsideDays: TDaisyCheckBox
        Left = 1040
        Top = 116
        Width = 154
        Height = 30
        Cursor = crHandPoint
        TabOrder = 8
        TabStop = True
        OnClick = CalendarOptionChange
        Caption = 'Show outside days'
      end
      object btnCalToday: TDaisyButton
        Left = 1040
        Top = 160
        Width = 200
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 9
        TabStop = True
        OnClick = CalendarTodayClick
        Caption = 'Go to today'
      end
      object lblCalPicker: TDaisyLabel
        Left = 1040
        Top = 240
        Width = 74
        Height = 19
        TabOrder = 10
        Caption = 'Date picker'
      end
      object dpCalendar: TDaisyDatePicker
        Left = 1040
        Top = 264
        Width = 200
        Height = 40
        TabOrder = 11
        TabStop = True
        Placeholder = 'Pick a date'
        OnDateChange = DatePickerChange
      end
      object lblPlacement: TDaisyLabel
        Left = 1040
        Top = 328
        Width = 118
        Height = 19
        TabOrder = 12
        Caption = 'Popup placement:'
      end
      object selPlacement: TDaisySelect
        Left = 1040
        Top = 352
        Width = 200
        Height = 40
        Hint = ''
        TabOrder = 13
        TabStop = True
        Items.Strings = (
          'Show below'
          'Show above'
          'Show on left'
          'Show on right')
        ItemIndex = 0
        Placeholder = 'Pick one'
        OnChange = DatePlacementChange
      end
    end
    object tsToggle: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1282
      Height = 454
      TabOrder = 0
      Caption = 'Toggle'
      object tgBasic: TDaisyToggle
        Left = 24
        Top = 12
        Width = 101
        Height = 30
        Cursor = crHandPoint
        TabOrder = 0
        TabStop = True
        Caption = 'Toggle'
      end
      object tgChecked: TDaisyToggle
        Left = 150
        Top = 12
        Width = 112
        Height = 30
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 1
        TabStop = True
        Checked = True
        Caption = 'Checked'
      end
      object tgDisabled: TDaisyToggle
        Left = 290
        Top = 12
        Width = 112
        Height = 30
        Cursor = crHandPoint
        Enabled = False
        TabOrder = 2
        TabStop = True
        Caption = 'Disabled'
      end
      object tgDisabledOn: TDaisyToggle
        Left = 430
        Top = 12
        Width = 132
        Height = 30
        Cursor = crHandPoint
        Enabled = False
        TabOrder = 3
        TabStop = True
        Checked = True
        Caption = 'Disabled on'
      end
      object tgIcons: TDaisyToggle
        Left = 590
        Top = 12
        Width = 124
        Height = 30
        Cursor = crHandPoint
        Variant = dvSuccess
        TabOrder = 4
        TabStop = True
        Checked = True
        Caption = 'With icons'
        ShowIcons = True
      end
      object tgXs: TDaisyToggle
        Left = 24
        Top = 60
        Width = 34
        Height = 22
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzXS
        TabOrder = 5
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgSm: TDaisyToggle
        Left = 110
        Top = 60
        Width = 42
        Height = 26
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzSM
        TabOrder = 6
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgMd: TDaisyToggle
        Left = 200
        Top = 60
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 7
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgLg: TDaisyToggle
        Left = 300
        Top = 60
        Width = 58
        Height = 34
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzLG
        TabOrder = 8
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgXl: TDaisyToggle
        Left = 410
        Top = 60
        Width = 66
        Height = 38
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzXL
        TabOrder = 9
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgNeutral: TDaisyToggle
        Left = 24
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 10
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgPrimary: TDaisyToggle
        Left = 110
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 11
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgSecondary: TDaisyToggle
        Left = 196
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvSecondary
        TabOrder = 12
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgAccent: TDaisyToggle
        Left = 282
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvAccent
        TabOrder = 13
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgInfo: TDaisyToggle
        Left = 368
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvInfo
        TabOrder = 14
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgSuccess: TDaisyToggle
        Left = 454
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvSuccess
        TabOrder = 15
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgWarning: TDaisyToggle
        Left = 540
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvWarning
        TabOrder = 16
        TabStop = True
        Checked = True
        Caption = ''
      end
      object tgError: TDaisyToggle
        Left = 626
        Top = 104
        Width = 50
        Height = 30
        Cursor = crHandPoint
        Variant = dvError
        TabOrder = 17
        TabStop = True
        Checked = True
        Caption = ''
      end
    end
  end
  object Styler: TDaisyFormStyler
    Left = 1200
    Top = 60
  end
end
