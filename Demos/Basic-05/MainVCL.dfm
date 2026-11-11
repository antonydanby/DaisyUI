object Form18: TForm18
  Left = 0
  Top = 0
  Caption = 
    'DaisyUI VCL demo - panel, label, SVG image, status, select and t' +
    'able'
  ClientHeight = 706
  ClientWidth = 1280
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  DesignSize = (
    1280
    706)
  TextHeight = 15
  object lblTheme: TLabel
    Left = 24
    Top = 18
    Width = 40
    Height = 15
    Caption = 'Theme:'
  end
  object lblStatusLine: TLabel
    Left = 560
    Top = 18
    Width = 3
    Height = 15
  end
  object chkTitleBar: TDaisyCheckBox
    Left = 300
    Top = 17
    Width = 156
    Height = 30
    Cursor = crHandPoint
    TabOrder = 1
    TabStop = True
    Action = actTitleBar
    Checked = True
    Caption = 'Theme the title bar'
  end
  object selTheme: TDaisySelect
    Left = 80
    Top = 4
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
    Top = 14
    Width = 42
    Height = 42
    Cursor = crHandPoint
    TabOrder = 3
    TabStop = True
    Kind = tkSwap
    Caption = 'Dark mode'
    OnChange = ThemeControllerChange
  end
  object pcMain: TDaisyPageControl
    Left = 16
    Top = 64
    Width = 1248
    Height = 626
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
    TabStop = True
    ActivePageIndex = 0
    object tsSelect: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1278
      Height = 608
      TabOrder = 3
      Caption = 'Select'
      object selBasic: TDaisySelect
        Left = 24
        Top = 16
        Width = 190
        Height = 40
        Hint = ''
        TabOrder = 0
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Pick one'
      end
      object selGhost: TDaisySelect
        Left = 230
        Top = 16
        Width = 190
        Height = 40
        Hint = ''
        Style = dsGhost
        TabOrder = 1
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Pick one'
      end
      object selLegend: TDaisySelect
        Left = 436
        Top = 16
        Width = 190
        Height = 86
        Hint = 'Pick the best one'
        TabOrder = 2
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Pick one'
        Legend = 'Browsers'
      end
      object selBefore: TDaisySelect
        Left = 642
        Top = 16
        Width = 190
        Height = 40
        Hint = ''
        TabOrder = 3
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Pick one'
        LabelText = 'Type'
        LabelMode = slmBefore
      end
      object selAfter: TDaisySelect
        Left = 848
        Top = 16
        Width = 190
        Height = 40
        Hint = ''
        TabOrder = 4
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Pick one'
        LabelText = 'Colour'
        LabelMode = slmAfter
      end
      object selFloating: TDaisySelect
        Left = 1054
        Top = 24
        Width = 190
        Height = 48
        Hint = ''
        TabOrder = 5
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Pick one'
        LabelText = 'Colour'
        LabelMode = slmFloating
      end
      object selXs: TDaisySelect
        Left = 24
        Top = 116
        Width = 190
        Height = 24
        Hint = ''
        SizeKind = dzXS
        TabOrder = 6
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Extra small'
      end
      object selSm: TDaisySelect
        Left = 230
        Top = 116
        Width = 190
        Height = 32
        Hint = ''
        SizeKind = dzSM
        TabOrder = 7
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Small'
      end
      object selMd: TDaisySelect
        Left = 436
        Top = 116
        Width = 190
        Height = 40
        Hint = ''
        TabOrder = 8
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Medium'
      end
      object selLg: TDaisySelect
        Left = 642
        Top = 116
        Width = 190
        Height = 48
        Hint = ''
        SizeKind = dzLG
        TabOrder = 9
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Large'
      end
      object selXl: TDaisySelect
        Left = 848
        Top = 116
        Width = 190
        Height = 56
        Hint = ''
        SizeKind = dzXL
        TabOrder = 10
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Extra large'
      end
      object selPrimary: TDaisySelect
        Left = 24
        Top = 196
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvPrimary
        TabOrder = 11
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Primary'
      end
      object selSecondary: TDaisySelect
        Left = 230
        Top = 196
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvSecondary
        TabOrder = 12
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Secondary'
      end
      object selAccent: TDaisySelect
        Left = 436
        Top = 196
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvAccent
        TabOrder = 13
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Accent'
      end
      object selInfo: TDaisySelect
        Left = 642
        Top = 196
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvInfo
        TabOrder = 14
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Info'
      end
      object selSuccess: TDaisySelect
        Left = 848
        Top = 196
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvSuccess
        TabOrder = 15
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Success'
      end
      object selWarning: TDaisySelect
        Left = 1054
        Top = 196
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvWarning
        TabOrder = 16
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Warning'
      end
      object selError: TDaisySelect
        Left = 24
        Top = 252
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvError
        TabOrder = 17
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Error'
      end
      object selDisabled: TDaisySelect
        Left = 230
        Top = 252
        Width = 190
        Height = 40
        Hint = ''
        Enabled = False
        TabOrder = 18
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Disabled'
      end
      object selEmoji: TDaisySelect
        Left = 436
        Top = 252
        Width = 190
        Height = 40
        Hint = ''
        TabOrder = 19
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'With emoji'
        Emoji = #55356#57256
      end
      object selSvg: TDaisySelect
        Left = 642
        Top = 252
        Width = 190
        Height = 40
        Hint = ''
        TabOrder = 20
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'With SVG'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
          'fill="none" stroke="currentColor" stroke-width="2">'
          '<path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/>'
          '</svg>')
      end
      object selSoft: TDaisySelect
        Left = 848
        Top = 252
        Width = 190
        Height = 40
        Hint = ''
        Variant = dvPrimary
        Style = dsSoft
        TabOrder = 21
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Soft'
      end
      object selDash: TDaisySelect
        Left = 1054
        Top = 252
        Width = 190
        Height = 40
        Hint = ''
        Style = dsDash
        TabOrder = 22
        TabStop = True
        Items.Strings = (
          'Crimson'
          'Amber'
          'Emerald'
          'Azure')
        Placeholder = 'Dashed'
      end
    end
    object tsTables: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1278
      Height = 608
      TabOrder = 4
      Caption = 'Tables'
      object tbBasic: TDaisyTable
        Left = 24
        Top = 16
        Width = 580
        Height = 176
        TabOrder = 0
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end>
      end
      object tbActive: TDaisyTable
        Left = 640
        Top = 16
        Width = 580
        Height = 176
        TabOrder = 1
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
            Active = True
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end>
      end
      object tbBordered: TDaisyTable
        Left = 24
        Top = 208
        Width = 580
        Height = 178
        TabOrder = 2
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end>
        Bordered = True
      end
      object tbHover: TDaisyTable
        Left = 640
        Top = 208
        Width = 580
        Height = 176
        TabOrder = 3
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end>
        HoverRows = True
      end
      object tbZebra: TDaisyTable
        Left = 24
        Top = 400
        Width = 580
        Height = 176
        TabOrder = 4
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end>
        Zebra = True
      end
      object tbCheckbox: TDaisyTable
        Left = 640
        Top = 400
        Width = 580
        Height = 176
        TabOrder = 5
        Columns = <
          item
            Caption = 'Column 4'
            Kind = ckCheckbox
          end
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              ''
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              ''
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
            Checked = True
          end
          item
            Cells.Strings = (
              ''
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end>
      end
    end
    object tsTableFeatures: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1278
      Height = 608
      TabOrder = 5
      Caption = 'Table features'
      object tbAvatar: TDaisyTable
        Left = 24
        Top = 16
        Width = 580
        Height = 260
        TabOrder = 0
        Columns = <
          item
            Caption = 'Column 4'
            Kind = ckCheckbox
          end
          item
            Caption = 'Name'
            Kind = ckAvatar
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
            Kind = ckBadge
          end
          item
            Caption = 'Column 8'
            Kind = ckButton
          end>
        Rows = <
          item
            Cells.Strings = (
              ''
              'Hart Hagerty|United States'
              'Desktop Support Technician'
              'Purple'
              'details')
            Icon.Emoji = #55357#56832
            Variant = dvPrimary
          end
          item
            Cells.Strings = (
              ''
              'Brice Swyre|China'
              'Tax Accountant'
              'Red'
              'details')
            Icon.Emoji = #55358#56598
            Variant = dvError
          end
          item
            Cells.Strings = (
              ''
              'Marjy Ferencz|Russia'
              'Office Assistant I'
              'Crimson'
              'details')
            Icon.Emoji = #55357#56420
            Variant = dvAccent
          end>
        OnButtonClick = TableButtonClick
      end
      object tbFooter: TDaisyTable
        Left = 640
        Top = 16
        Width = 580
        Height = 220
        TabOrder = 1
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end>
        ShowFooter = True
      end
      object tbPinRows: TDaisyTable
        Left = 24
        Top = 300
        Width = 580
        Height = 220
        TabOrder = 2
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Red')
          end
          item
            Cells.Strings = (
              'Marjy Ferencz'
              'Office Assistant I'
              'Crimson')
          end
          item
            Cells.Strings = (
              'Yancy Tear'
              'Community Outreach Specialist'
              'Indigo')
          end
          item
            Cells.Strings = (
              'Irma Vasilik'
              'Editor'
              'Orange')
          end
          item
            Cells.Strings = (
              'Meghann Durtnal'
              'Staff Accountant IV'
              'Yellow')
          end
          item
            Cells.Strings = (
              'Sammy Seston'
              'Accountant I'
              'Teal')
          end>
        ShowFooter = True
        PinRows = True
        AutoHeight = False
      end
      object tbPinCols: TDaisyTable
        Left = 640
        Top = 300
        Width = 580
        Height = 220
        TabOrder = 3
        Columns = <
          item
            Caption = 'Name'
            Pinned = True
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Company'
          end
          item
            Caption = 'Location'
          end
          item
            Caption = 'Last Login'
          end
          item
            Caption = 'Favorite Color'
            Pinned = True
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Littel, Schaden and Vandervort'
              'Canada'
              '12/16/2020'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Zemlak, Daniel and Leannon'
              'United States'
              '12/5/2020'
              'Purple')
          end
          item
            Cells.Strings = (
              'Brice Swyre'
              'Tax Accountant'
              'Carroll Group'
              'China'
              '8/15/2020'
              'Red')
          end
          item
            Cells.Strings = (
              'Marjy Ferencz'
              'Office Assistant I'
              'Rowe-Schoen'
              'Russia'
              '3/25/2021'
              'Crimson')
          end
          item
            Cells.Strings = (
              'Yancy Tear'
              'Community Outreach Specialist'
              'Wyman-Ledner'
              'Brazil'
              '5/22/2020'
              'Indigo')
          end>
        PinRows = True
        AutoHeight = False
      end
    end
    object tsTableSizes: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1278
      Height = 608
      TabOrder = 6
      Caption = 'Table sizes'
      object tbXs: TDaisyTable
        Left = 24
        Top = 16
        Width = 580
        Height = 69
        SizeKind = dzXS
        TabOrder = 0
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end>
      end
      object tbSm: TDaisyTable
        Left = 640
        Top = 16
        Width = 580
        Height = 99
        SizeKind = dzSM
        TabOrder = 1
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end>
      end
      object tbMd: TDaisyTable
        Left = 24
        Top = 140
        Width = 580
        Height = 132
        TabOrder = 2
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end>
      end
      object tbLg: TDaisyTable
        Left = 640
        Top = 140
        Width = 580
        Height = 171
        SizeKind = dzLG
        TabOrder = 3
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end>
      end
      object tbXl: TDaisyTable
        Left = 24
        Top = 336
        Width = 580
        Height = 213
        SizeKind = dzXL
        TabOrder = 4
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end>
      end
      object tbRtl: TDaisyTable
        Left = 640
        Top = 336
        Width = 580
        Height = 132
        TabOrder = 5
        Columns = <
          item
            Caption = 'Name'
          end
          item
            Caption = 'Job'
          end
          item
            Caption = 'Favorite Color'
          end>
        Rows = <
          item
            Cells.Strings = (
              'Cy Ganderton'
              'Quality Control Specialist'
              'Blue')
          end
          item
            Cells.Strings = (
              'Hart Hagerty'
              'Desktop Support Technician'
              'Purple')
          end>
        RightToLeft = True
      end
    end
    object tsUtilities: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1278
      Height = 608
      TabOrder = 0
      Caption = 'Utilities'
      object pnlPlain: TDaisyPanel
        Left = 24
        Top = 16
        Width = 280
        Height = 120
        TabOrder = 0
        object lblPanelTitle: TDaisyLabel
          Left = 16
          Top = 16
          Width = 105
          Height = 25
          SizeKind = dzLG
          TabOrder = 0
          Caption = 'A plain panel'
        end
        object lblPanelText: TDaisyLabel
          Left = 16
          Top = 52
          Width = 248
          Height = 38
          TabOrder = 1
          Caption = 'Panels accept child controls, so they can hold anything.'
          WordWrap = True
          Muted = True
        end
      end
      object pnlPrimary: TDaisyPanel
        Left = 320
        Top = 16
        Width = 280
        Height = 120
        Variant = dvPrimary
        TabOrder = 1
        object lblPrimaryTitle: TDaisyLabel
          Left = 16
          Top = 16
          Width = 128
          Height = 25
          SizeKind = dzLG
          TabOrder = 0
          Caption = 'A primary panel'
        end
        object lblPrimaryText: TDaisyLabel
          Left = 16
          Top = 52
          Width = 248
          Height = 19
          TabOrder = 1
          Caption = 'The label picks up the panel colours.'
          WordWrap = True
        end
      end
      object dlbHeading: TDaisyLabel
        Left = 640
        Top = 16
        Width = 189
        Height = 30
        SizeKind = dzXL
        TabOrder = 2
        Caption = 'A big heading label'
      end
      object dlbBody: TDaisyLabel
        Left = 640
        Top = 56
        Width = 220
        Height = 19
        TabOrder = 3
        Caption = 'A normal label in the current theme'
      end
      object dlbMuted: TDaisyLabel
        Left = 640
        Top = 84
        Width = 201
        Height = 19
        TabOrder = 4
        Caption = 'A muted label for secondary text'
        Muted = True
      end
      object dlbEmoji: TDaisyLabel
        Left = 640
        Top = 112
        Width = 288
        Height = 25
        SizeKind = dzLG
        TabOrder = 5
        Caption = 'Colour emoji: '#55357#56832' '#55357#56960' '#55356#57225' '#55357#56613' '#55356#57173' '#55358#56598
      end
      object dlbWrap: TDaisyLabel
        Left = 640
        Top = 148
        Width = 560
        Height = 38
        TabOrder = 6
        Caption = 
          'Labels can wrap long text over several lines, and they are drawn' +
          ' with Direct2D so emoji such as '#55357#56832' stay in colour.'
        WordWrap = True
      end
    end
    object tsSvg: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1278
      Height = 608
      TabOrder = 1
      Caption = 'SVG'
      object svgHeart: TDaisySVGImage
        Left = 24
        Top = 16
        Width = 64
        Height = 64
        Variant = dvError
        TabOrder = 0
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
          'fill="none" stroke="currentColor" stroke-width="1.5">'
          
            '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.12' +
            '6-4.312 2.733'
          
            ' -.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7' +
            '.22 9 12 9 12s9-4.78 9-12Z"/>'
          '</svg>')
      end
      object svgCheck: TDaisySVGImage
        Left = 104
        Top = 16
        Width = 64
        Height = 64
        Variant = dvSuccess
        TabOrder = 1
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
          'fill="none" stroke="currentColor" stroke-width="2">'
          '<path d="M4.5 12.75l6 6 9-13.5"/>'
          '</svg>')
      end
      object svgSettings: TDaisySVGImage
        Left = 184
        Top = 16
        Width = 64
        Height = 64
        Variant = dvPrimary
        TabOrder = 2
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
          'fill="none" stroke="currentColor" stroke-width="2" '
          'stroke-linecap="round" stroke-linejoin="round">'
          '<path d="M6 9l6 6l6 -6"/>'
          '<path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/>'
          '</svg>')
      end
      object svgColor: TDaisySVGImage
        Left = 264
        Top = 16
        Width = 64
        Height = 64
        TabOrder = 3
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
          '<circle cx="12" cy="12" r="10" fill="#FFC107"/>'
          '<circle cx="8.5" cy="10" r="1.5" fill="#333333"/>'
          '<circle cx="15.5" cy="10" r="1.5" fill="#333333"/>'
          
            '<path d="M7 14.5c1.2 2.5 8.8 2.5 10 0" fill="none" stroke="#E651' +
            '00" '
          'stroke-width="1.8" stroke-linecap="round"/>'
          '</svg>')
        Colored = True
      end
      object DaisySVGImage1: TDaisySVGImage
        Left = 344
        Top = 16
        Width = 128
        Height = 105
        TabOrder = 4
        SVG.Strings = (
          
            '<svg viewBox="0 0 1024 1024" class="icon" version="1.1" xmlns="h' +
            'ttp://www.w3.org/2000/svg" fill="#000000"><g id="SVGRepo_bgCarri' +
            'er" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-li' +
            'necap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCar' +
            'rier"><path d="M543.74 255c210.2-42.94 322.79 28.73 346.37 214C9' +
            '04.38 652.15 874 930.76 563 930.76q-35.73-0.9-108.27 0C178.08 90' +
            '3 132.15 652.15 146.43 469 170 283.73 282.6 212.06 492.8 255c5.8' +
            '6 1.49 15.78 1.55 20.37 0 14.83 1.54 24.71 1.48 30.57 0z" fill="' +
            '#FFFFFF"></path><path d="M885.45 439.64q2.73 14.16 4.66 29.34C90' +
            '4.38 652.15 874 930.76 563 930.76q-35.73-0.9-108.27 0c-88.34-8.8' +
            '6-153.15-40.47-200-85.36-20.43-72.24-23.51-150.22-18.17-218.74 2' +
            '3.58-185.26 136.17-256.93 346.37-214 5.86 1.49 15.78 1.55 20.37 ' +
            '0 14.78 1.55 24.7 1.49 30.56 0 110.33-22.54 193.77-13.5 251.57 2' +
            '7z" fill="#FFC6C6"></path><path d="M687.43 244.66c118.81 12.08 1' +
            '85.2 87 202.68 224.32C904.38 652.15 874 930.76 563 930.76q-35.73' +
            '-0.9-108.27 0c-58-5.82-105.92-21.46-145.22-44.24 223.8 24.26 333' +
            '.76-44.77 395.87-262.59 32.82-115.12 28.75-256-18-379.27z" fill=' +
            '"#FF9368"></path><path d="M405.59 339.46a135.21 61.95 0 1 0 270.' +
            '42 0 135.21 61.95 0 1 0-270.42 0Z" fill="#FFC6C6"></path><path d' +
            '="M453.84 951.26l-1.15-0.12c-68.87-6.91-128.3-27.68-176.65-61.74' +
            'C233 859 198.34 818 173.14 767.27c-50.37-101.34-53.43-219-47.13-' +
            '299.87l0.1-1c5.83-45.76 17.1-85.6 33.52-118.42 17-33.9 39.88-61.' +
            '34 68.11-81.56 31.69-22.69 70.78-36.75 116.17-41.8 44.05-4.9 95.' +
            '52-1.43 153 10.31l0.93 0.21a31.48 31.48 0 0 0 9.21 0.31l3.82-1.2' +
            '9 4.45 0.47c17.13 1.79 22.49 0.75 23.4 0.52l0.93-0.21c57.46-11.7' +
            '4 108.94-15.21 153-10.31 45.39 5 84.47 19.11 116.17 41.8 28.18 2' +
            '0.21 51.13 47.65 68.09 81.57 16.41 32.81 27.69 72.65 33.52 118.4' +
            '2l0.1 1c9.32 119.51 0.32 283.71-95.45 387.23C755.77 918.74 671 9' +
            '51.24 563 951.24h-0.52c-23.45-0.59-59.62-0.59-107.5 0zM518 909.8' +
            '4c18.15 0 33.27 0.15 45.25 0.45 50.49 0 95.42-7.82 133.56-23.18 ' +
            '34.28-13.8 63.95-34.09 88.19-60.3 47.27-51.1 100.32-154.3 84.72-' +
            '355.73-5.26-41-15.17-76.21-29.45-104.77-13.94-27.88-32.56-50.31-' +
            '55.27-66.58-25.92-18.56-58.51-30.13-96.85-34.4-39.7-4.42-86.76-1' +
            '.17-139.87 9.65-8 1.92-18.5 2.15-33.69 0.73a70 70 0 0 1-26.22-0.' +
            '73c-53.12-10.82-100.18-14.07-139.88-9.65-38.34 4.26-70.93 15.84-' +
            '96.85 34.4-22.76 16.3-41.38 38.7-55.33 66.58-14.29 28.56-24.2 63' +
            '.81-29.45 104.77-3.8 49.11-2.73 96.45 3.17 140.73 6.89 51.73 20.' +
            '3 97.9 39.85 137.23 47.26 95.07 130 149.31 245.83 161.24 23.58-0' +
            '.28 44.41-0.44 62.29-0.44z" fill=""></path><path d="M516.59 388.' +
            '26c-36.82 0-73.57-14.47-109.24-43a22.53 22.53 0 1 1 28.15-35.18c' +
            '55.32 44.27 106.86 44.27 162.18 0a22.53 22.53 0 1 1 28.15 35.18c' +
            '-35.66 28.53-72.42 43-109.24 43z" fill=""></path><path d="M518.2' +
            '8 363.59a22.55 22.55 0 0 1-21.66-28.77c32.47-112.64 71.48-185.13' +
            ' 119.27-221.62a22.53 22.53 0 1 1 27.35 35.8c-39.27 30-74 96.71-1' +
            '03.32 198.29a22.54 22.54 0 0 1-21.64 16.3z" fill=""></path><path' +
            ' d="M412.75 277.52q87.12 0 157.75-78.84-70.63-78.84-157.75-78.84' +
            'T255 198.68q70.62 78.84 157.75 78.84z" fill="#89D66D"></path><pa' +
            'th d="M416.86 298c-63.88 0-122.09-28.82-173-85.66l-12.24-13.67L2' +
            '43.85 185c50.92-56.84 109.12-85.65 173-85.65s122.09 28.82 173 85' +
            '.65l12.24 13.67-12.24 13.67C538.95 269.18 480.74 298 416.86 298z' +
            ' m-129.48-99.32c17.84 17.55 36.49 31.25 55.63 40.81a164.13 164.1' +
            '3 0 0 0 147.69 0c19.14-9.57 37.79-23.26 55.63-40.81-17.84-17.55-' +
            '36.49-31.25-55.63-40.81a164.13 164.13 0 0 0-147.69 0c-19.13 9.56' +
            '-37.79 23.25-55.63 40.81z" fill=""></path><path d="M396.72 182.1' +
            '6h143.35a15.36 15.36 0 0 1 15.36 15.36 15.36 15.36 0 0 1-15.36 1' +
            '5.36H396.72a15.36 15.36 0 0 1-15.36-15.36 15.36 15.36 0 0 1 15.3' +
            '6-15.36z" fill="#015200"></path></g></svg>')
        Colored = True
      end
    end
    object tsStatus: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1278
      Height = 608
      TabOrder = 2
      Caption = 'Status'
      object lblStatusSizes: TLabel
        Left = 24
        Top = 16
        Width = 25
        Height = 15
        Caption = 'Sizes'
      end
      object lblStatusColors: TLabel
        Left = 300
        Top = 16
        Width = 34
        Height = 15
        Caption = 'Colors'
      end
      object lblStatusMore: TLabel
        Left = 660
        Top = 16
        Width = 153
        Height = 15
        Caption = 'Ping, bounce, emoji and SVG'
      end
      object stSizeXs: TDaisyStatus
        Left = 24
        Top = 48
        Width = 8
        Height = 8
        SizeKind = dzXS
        TabOrder = 0
      end
      object stSizeSm: TDaisyStatus
        Left = 64
        Top = 48
        Width = 8
        Height = 8
        SizeKind = dzSM
        TabOrder = 1
      end
      object stSizeMd: TDaisyStatus
        Left = 104
        Top = 48
        Width = 16
        Height = 16
        TabOrder = 2
      end
      object stSizeLg: TDaisyStatus
        Left = 144
        Top = 48
        Width = 24
        Height = 24
        SizeKind = dzLG
        TabOrder = 3
      end
      object stSizeXl: TDaisyStatus
        Left = 184
        Top = 48
        Width = 32
        Height = 32
        SizeKind = dzXL
        TabOrder = 4
      end
      object stNeutral: TDaisyStatus
        Left = 300
        Top = 48
        Width = 16
        Height = 16
        Variant = dvNeutral
        TabOrder = 5
      end
      object stPrimary: TDaisyStatus
        Left = 336
        Top = 48
        Width = 16
        Height = 16
        Variant = dvPrimary
        TabOrder = 6
      end
      object stSecondary: TDaisyStatus
        Left = 372
        Top = 48
        Width = 16
        Height = 16
        Variant = dvSecondary
        TabOrder = 7
      end
      object stAccent: TDaisyStatus
        Left = 408
        Top = 48
        Width = 16
        Height = 16
        Variant = dvAccent
        TabOrder = 8
      end
      object stInfo: TDaisyStatus
        Left = 444
        Top = 48
        Width = 16
        Height = 16
        Variant = dvInfo
        TabOrder = 9
      end
      object stSuccess: TDaisyStatus
        Left = 480
        Top = 48
        Width = 16
        Height = 16
        Variant = dvSuccess
        TabOrder = 10
      end
      object stWarning: TDaisyStatus
        Left = 516
        Top = 48
        Width = 16
        Height = 16
        Variant = dvWarning
        TabOrder = 11
      end
      object stError: TDaisyStatus
        Left = 552
        Top = 48
        Width = 16
        Height = 16
        Variant = dvError
        TabOrder = 12
      end
      object stPing: TDaisyStatus
        Left = 660
        Top = 48
        Width = 16
        Height = 16
        Variant = dvInfo
        TabOrder = 13
        Animation = saPing
      end
      object stBounce: TDaisyStatus
        Left = 700
        Top = 44
        Width = 16
        Height = 16
        Variant = dvPrimary
        TabOrder = 14
        Animation = saBounce
      end
      object stEmoji: TDaisyStatus
        Left = 740
        Top = 44
        Width = 36
        Height = 36
        SizeKind = dzLG
        TabOrder = 15
        Emoji = #55357#56613
      end
      object stSvg: TDaisyStatus
        Left = 780
        Top = 44
        Width = 36
        Height = 36
        Variant = dvSuccess
        SizeKind = dzLG
        TabOrder = 16
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
          'fill="none" stroke="currentColor" stroke-width="3">'
          '<path d="M4.5 12.75l6 6 9-13.5"/>'
          '</svg>')
      end
    end
  end
  object alMain: TActionList
    Left = 480
    Top = 20
    object actTitleBar: TAction
      Caption = 'Theme the title bar'
      Checked = True
      OnExecute = chkTitleBarClick
    end
  end
  object Styler: TDaisyFormStyler
    Left = 540
    Top = 4
  end
end
