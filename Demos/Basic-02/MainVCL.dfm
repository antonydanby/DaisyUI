object Form12: TForm12
  Left = 0
  Top = 0
  Caption = 'DaisyUI VCL demo - buttons, dropdown, FAB, accordion'
  ClientHeight = 520
  ClientWidth = 1124
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  DesignSize = (
    1124
    520)
  TextHeight = 15
  object lblTheme: TLabel
    Left = 16
    Top = 24
    Width = 40
    Height = 15
    Caption = 'Theme:'
  end
  object selTheme: TDaisySelect
    Left = 72
    Top = 12
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
  object chkTitleBar: TDaisyCheckBox
    Left = 300
    Top = 20
    Width = 207
    Height = 30
    Cursor = crHandPoint
    TabOrder = 1
    TabStop = True
    Action = actTitleBar
    Checked = True
    Caption = 'Theme the window title bar'
  end
  object themeCtl: TDaisyThemeController
    Left = 528
    Top = 20
    Width = 50
    Height = 30
    Cursor = crHandPoint
    TabOrder = 3
    TabStop = True
    Kind = tkToggleIcons
    Caption = ''
    OnChange = ThemeControllerChange
  end
  object pcMain: TDaisyPageControl
    Left = 8
    Top = 64
    Width = 1108
    Height = 448
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
    TabStop = True
    ActivePageIndex = 0
    object tsToast: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 5
      Caption = 'Toast'
      object lblToast: TLabel
        Left = 16
        Top = 8
        Width = 40
        Height = 21
        Caption = 'Toast'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblToastDuration: TLabel
        Left = 16
        Top = 52
        Width = 87
        Height = 15
        Caption = 'Disappears after:'
      end
      object lblToastHorz: TLabel
        Left = 16
        Top = 132
        Width = 58
        Height = 15
        Caption = 'Horizontal:'
      end
      object lblToastVert: TLabel
        Left = 16
        Top = 212
        Width = 41
        Height = 15
        Caption = 'Vertical:'
      end
      object lblToastHint: TLabel
        Left = 520
        Top = 8
        Width = 297
        Height = 15
        Caption = 'Messages appear in the toast area on this side of the tab.'
      end
      object selToastDuration: TDaisySelect
        Left = 16
        Top = 72
        Width = 200
        Height = 40
        Hint = ''
        TabOrder = 1
        TabStop = True
        Items.Strings = (
          '3 seconds'
          '4 seconds'
          '5 seconds'
          '8 seconds')
        ItemIndex = 2
        Placeholder = 'Pick one'
        OnChange = ToastDurationChange
      end
      object selToastHorz: TDaisySelect
        Left = 16
        Top = 152
        Width = 200
        Height = 40
        Hint = ''
        TabOrder = 2
        TabStop = True
        Items.Strings = (
          'Start'
          'Center'
          'End')
        ItemIndex = 2
        Placeholder = 'Pick one'
        OnChange = ToastPlacementChange
      end
      object selToastVert: TDaisySelect
        Left = 16
        Top = 232
        Width = 200
        Height = 40
        Hint = ''
        TabOrder = 3
        TabStop = True
        Items.Strings = (
          'Top'
          'Middle'
          'Bottom')
        ItemIndex = 2
        Placeholder = 'Pick one'
        OnChange = ToastPlacementChange
      end
      object btnToastInfo: TDaisyButton
        Left = 280
        Top = 72
        Width = 200
        Height = 40
        Cursor = crHandPoint
        Variant = dvInfo
        TabOrder = 4
        TabStop = True
        OnClick = ToastPostClick
        Caption = 'Post info'
      end
      object btnToastSuccess: TDaisyButton
        Tag = 1
        Left = 280
        Top = 128
        Width = 200
        Height = 40
        Cursor = crHandPoint
        Variant = dvSuccess
        TabOrder = 5
        TabStop = True
        OnClick = ToastPostClick
        Caption = 'Post success'
      end
      object btnToastWarning: TDaisyButton
        Tag = 2
        Left = 280
        Top = 184
        Width = 200
        Height = 40
        Cursor = crHandPoint
        Variant = dvWarning
        TabOrder = 6
        TabStop = True
        OnClick = ToastPostClick
        Caption = 'Post warning'
      end
      object btnToastError: TDaisyButton
        Tag = 3
        Left = 280
        Top = 240
        Width = 200
        Height = 40
        Cursor = crHandPoint
        Variant = dvError
        TabOrder = 7
        TabStop = True
        OnClick = ToastPostClick
        Caption = 'Post error'
      end
      object btnToastClear: TDaisyButton
        Left = 280
        Top = 296
        Width = 200
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 8
        TabStop = True
        Action = actToastClear
        Caption = 'Clear all'
      end
      object toastDemo: TDaisyToast
        Left = 0
        Top = 0
        Width = 1106
        Height = 406
        Align = alClient
        TabOrder = 0
      end
    end
    object tsAccordion: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 4
      Caption = 'Accordion'
      object lblAccordion: TLabel
        Left = 16
        Top = 8
        Width = 138
        Height = 21
        Caption = 'Accordion (arrow)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblJoined: TLabel
        Left = 440
        Top = 8
        Width = 183
        Height = 21
        Caption = 'Accordion (+ / -, joined)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblAccResult: TLabel
        Left = 16
        Top = 300
        Width = 117
        Height = 15
        Caption = 'Accordion: no change'
      end
      object accSeparate: TDaisyAccordion
        Left = 16
        Top = 44
        Width = 370
        Height = 226
        TabOrder = 0
        TabStop = True
        Items = <
          item
            Title = 'How do I create an account?'
            Content = 
              'Click the Sign Up button in the top right corner and follow the ' +
              'on-screen steps.'
            Expanded = True
          end
          item
            Title = 'I forgot my password'
            Content = 
              'Use the Forgot password link on the sign in page to receive a re' +
              'set email.'
          end
          item
            Title = 'How do I update my profile?'
            Content = 'Open Settings, choose Profile and edit your details, then save.'
          end>
        OnToggle = AccordionToggle
      end
      object accJoined: TDaisyAccordion
        Left = 440
        Top = 44
        Width = 370
        Height = 210
        Variant = dvPrimary
        TabOrder = 1
        TabStop = True
        Items = <
          item
            Title = 'Joined section one'
            Content = 'Joined sections share one outline, with a divider between each.'
            Expanded = True
          end
          item
            Title = 'Joined section two'
            Content = 'Only one section is open at a time unless AllowMultiple is set.'
          end
          item
            Title = 'Joined section three'
            Content = 'The + changes to a - while a section is open.'
          end>
        Icon = aiPlusMinus
        Joined = True
        OnToggle = AccordionToggle
      end
    end
    object tsLoading: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 1
      Caption = 'Loading'
      object lblLoading: TLabel
        Left = 16
        Top = 8
        Width = 125
        Height = 21
        Caption = 'Loading buttons'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblAnimation: TLabel
        Left = 16
        Top = 168
        Width = 144
        Height = 21
        Caption = 'Animation buttons'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblAnimStatus: TLabel
        Left = 16
        Top = 252
        Width = 81
        Height = 15
        Caption = 'Animation: idle'
      end
      object btnLoadSpinner: TDaisyLoadingButton
        Left = 16
        Top = 48
        Width = 128
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 0
        TabStop = True
        Caption = 'Spinner'
        Loading = True
      end
      object btnLoadRing: TDaisyLoadingButton
        Left = 156
        Top = 48
        Width = 128
        Height = 40
        Cursor = crHandPoint
        Variant = dvSecondary
        TabOrder = 1
        TabStop = True
        Caption = 'Ring'
        Loading = True
        LoadingKind = dlRing
      end
      object btnLoadDots: TDaisyLoadingButton
        Left = 296
        Top = 48
        Width = 128
        Height = 40
        Cursor = crHandPoint
        Variant = dvAccent
        TabOrder = 2
        TabStop = True
        Caption = 'Dots'
        Loading = True
        LoadingKind = dlDots
      end
      object btnLoadBars: TDaisyLoadingButton
        Left = 436
        Top = 48
        Width = 128
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 3
        TabStop = True
        Caption = 'Bars'
        Loading = True
        LoadingKind = dlBars
      end
      object btnLoadBall: TDaisyLoadingButton
        Left = 576
        Top = 48
        Width = 128
        Height = 40
        Cursor = crHandPoint
        Variant = dvInfo
        TabOrder = 4
        TabStop = True
        Caption = 'Ball'
        Loading = True
        LoadingKind = dlBall
      end
      object btnLoadRight: TDaisyLoadingButton
        Left = 16
        Top = 104
        Width = 160
        Height = 40
        Cursor = crHandPoint
        Variant = dvSuccess
        Style = dsOutline
        TabOrder = 5
        TabStop = True
        Caption = 'Indicator right'
        Loading = True
        IndicatorPosition = ipRight
      end
      object btnLoadReplace: TDaisyLoadingButton
        Left = 188
        Top = 104
        Width = 120
        Height = 40
        Cursor = crHandPoint
        Variant = dvWarning
        TabOrder = 6
        TabStop = True
        Caption = 'Replace'
        Loading = True
        IndicatorPosition = ipReplace
      end
      object btnLoadCaption: TDaisyLoadingButton
        Left = 324
        Top = 104
        Width = 160
        Height = 40
        Cursor = crHandPoint
        Variant = dvError
        Style = dsSoft
        TabOrder = 7
        TabStop = True
        Caption = 'Save'
        Loading = True
        LoadingCaption = 'Saving...'
      end
      object btnToggleLoading: TDaisyButton
        Left = 496
        Top = 104
        Width = 208
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 8
        TabStop = True
        Action = actToggleLoading
        Caption = 'Toggle loading on all'
      end
      object btnAnimDots: TDaisyAnimationButton
        Left = 16
        Top = 200
        Width = 140
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 9
        TabStop = True
        Caption = 'Run (dots)'
        LoadingKind = dlDots
        OnAnimationFinished = AnimationFinished
      end
      object btnAnimBars: TDaisyAnimationButton
        Left = 172
        Top = 200
        Width = 140
        Height = 40
        Cursor = crHandPoint
        Variant = dvSecondary
        TabOrder = 10
        TabStop = True
        Caption = 'Run (bars)'
        LoadingKind = dlBars
        Duration = 3000
        OnAnimationFinished = AnimationFinished
      end
      object btnAnimBall: TDaisyAnimationButton
        Left = 328
        Top = 200
        Width = 140
        Height = 40
        Cursor = crHandPoint
        Variant = dvAccent
        Style = dsOutline
        TabOrder = 11
        TabStop = True
        Caption = 'Run (ball)'
        LoadingKind = dlBall
        Duration = 1500
        OnAnimationFinished = AnimationFinished
      end
    end
    object tsDropdown: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 2
      Caption = 'Dropdown'
      object lblDropdown: TLabel
        Left = 16
        Top = 8
        Width = 81
        Height = 21
        Caption = 'Dropdown'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblDropResult: TLabel
        Left = 16
        Top = 300
        Width = 77
        Height = 15
        Caption = 'Selected: none'
      end
      object ddMenu: TDaisyDropdownMenu
        Left = 16
        Top = 48
        Width = 120
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 0
        TabStop = True
        Caption = 'File'
        Items = <
          item
            Caption = 'New'
            Description = 'Ctrl+N'
          end
          item
            Caption = 'Open...'
            Description = 'Ctrl+O'
          end
          item
            Caption = '-'
          end
          item
            Caption = 'Save'
            Description = 'Ctrl+S'
          end
          item
            Caption = 'Save as...'
            Enabled = False
          end
          item
            Caption = '-'
          end
          item
            Caption = 'Exit'
          end>
        OnItemClick = DropdownItemClick
      end
      object ddEnd: TDaisyDropdownMenu
        Left = 160
        Top = 48
        Width = 140
        Height = 40
        Cursor = crHandPoint
        Variant = dvSecondary
        Style = dsOutline
        TabOrder = 1
        TabStop = True
        Caption = 'Bottom end'
        Items = <
          item
            Caption = 'Profile'
          end
          item
            Caption = 'Settings'
          end
          item
            Caption = 'Logout'
          end>
        Placement = dpBottomEnd
        OnItemClick = DropdownItemClick
      end
      object ddTop: TDaisyDropdownMenu
        Left = 324
        Top = 120
        Width = 120
        Height = 40
        Cursor = crHandPoint
        Variant = dvAccent
        Style = dsSoft
        TabOrder = 2
        TabStop = True
        Caption = 'Top'
        Items = <
          item
            Caption = 'Alpha'
          end
          item
            Caption = 'Beta'
          end
          item
            Caption = 'Gamma'
          end>
        Placement = dpTopStart
        OnItemClick = DropdownItemClick
      end
      object ddSide: TDaisyDropdownMenu
        Left = 468
        Top = 48
        Width = 90
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 3
        TabStop = True
        Caption = 'Right'
        Items = <
          item
            Caption = 'One'
          end
          item
            Caption = 'Two'
          end>
        Placement = dpRight
        OnItemClick = DropdownItemClick
      end
    end
    object tsRating: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 7
      Caption = 'Rating'
      object lblRating: TLabel
        Left = 16
        Top = 8
        Width = 50
        Height = 21
        Caption = 'Rating'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblRatingValue: TLabel
        Left = 16
        Top = 288
        Width = 63
        Height = 15
        Caption = 'Rating: 3 / 5'
      end
      object ratDefault: TDaisyRating
        Left = 16
        Top = 40
        Width = 120
        Height = 24
        Cursor = crHandPoint
        TabOrder = 0
        TabStop = True
        Value = 3.000000000000000000
        OnChange = RatingChange
      end
      object ratHalf: TDaisyRating
        Left = 16
        Top = 80
        Width = 120
        Height = 24
        Cursor = crHandPoint
        TabOrder = 1
        TabStop = True
        Value = 2.500000000000000000
        AllowHalf = True
      end
      object ratHeart: TDaisyRating
        Left = 16
        Top = 120
        Width = 136
        Height = 24
        Cursor = crHandPoint
        Variant = dvError
        TabOrder = 2
        TabStop = True
        Value = 4.000000000000000000
        Shape = rsHeart
      end
      object ratReadOnly: TDaisyRating
        Left = 16
        Top = 160
        Width = 120
        Height = 24
        TabOrder = 3
        TabStop = True
        Value = 4.000000000000000000
        ReadOnly = True
      end
      object ratMulti: TDaisyRating
        Left = 16
        Top = 200
        Width = 120
        Height = 24
        Cursor = crHandPoint
        TabOrder = 4
        TabStop = True
        Value = 3.000000000000000000
        Shape = rsStar
        MultiColor = True
      end
      object ratClear: TDaisyRating
        Left = 16
        Top = 240
        Width = 120
        Height = 24
        Cursor = crHandPoint
        TabOrder = 5
        TabStop = True
        Value = 2.000000000000000000
        AllowClear = True
      end
      object ratXS: TDaisyRating
        Left = 340
        Top = 40
        Width = 80
        Height = 16
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzXS
        TabOrder = 6
        TabStop = True
        Value = 3.000000000000000000
      end
      object ratSM: TDaisyRating
        Left = 340
        Top = 72
        Width = 100
        Height = 20
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzSM
        TabOrder = 7
        TabStop = True
        Value = 3.000000000000000000
      end
      object ratMD: TDaisyRating
        Left = 340
        Top = 108
        Width = 120
        Height = 24
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 8
        TabStop = True
        Value = 3.000000000000000000
      end
      object ratLG: TDaisyRating
        Left = 340
        Top = 148
        Width = 140
        Height = 28
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzLG
        TabOrder = 9
        TabStop = True
        Value = 3.000000000000000000
      end
      object ratXL: TDaisyRating
        Left = 340
        Top = 192
        Width = 160
        Height = 32
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzXL
        TabOrder = 10
        TabStop = True
        Value = 3.000000000000000000
      end
      object ratThree: TDaisyRating
        Left = 640
        Top = 40
        Width = 72
        Height = 24
        Cursor = crHandPoint
        TabOrder = 11
        TabStop = True
        Value = 2.000000000000000000
        Count = 3
      end
      object ratTen: TDaisyRating
        Left = 640
        Top = 80
        Width = 276
        Height = 24
        Cursor = crHandPoint
        Variant = dvSecondary
        TabOrder = 12
        TabStop = True
        Value = 7.000000000000000000
        Count = 10
        Shape = rsHeart
      end
    end
    object tsRange: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 6
      Caption = 'Range'
      object lblRange: TLabel
        Left = 16
        Top = 8
        Width = 48
        Height = 21
        Caption = 'Range'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblRangeValue: TLabel
        Left = 16
        Top = 304
        Width = 46
        Height = 15
        Caption = 'Value: 40'
      end
      object rngDefault: TDaisyRange
        Left = 16
        Top = 40
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 0
        TabStop = True
        Max = 100.000000000000000000
        Value = 40.000000000000000000
        Step = 1.000000000000000000
        OnChange = RangeChange
      end
      object rngPrimary: TDaisyRange
        Left = 16
        Top = 72
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 1
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 1.000000000000000000
      end
      object rngSecondary: TDaisyRange
        Left = 16
        Top = 104
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvSecondary
        TabOrder = 2
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 1.000000000000000000
      end
      object rngAccent: TDaisyRange
        Left = 16
        Top = 136
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvAccent
        TabOrder = 3
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 1.000000000000000000
      end
      object rngInfo: TDaisyRange
        Left = 16
        Top = 168
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvInfo
        TabOrder = 4
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 1.000000000000000000
      end
      object rngSuccess: TDaisyRange
        Left = 16
        Top = 200
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvSuccess
        TabOrder = 5
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 1.000000000000000000
      end
      object rngWarning: TDaisyRange
        Left = 16
        Top = 232
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvWarning
        TabOrder = 6
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 1.000000000000000000
      end
      object rngError: TDaisyRange
        Left = 16
        Top = 264
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvError
        TabOrder = 7
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 1.000000000000000000
      end
      object rngXS: TDaisyRange
        Left = 340
        Top = 40
        Width = 300
        Height = 24
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzXS
        TabOrder = 8
        TabStop = True
        Max = 100.000000000000000000
        Value = 30.000000000000000000
        Step = 1.000000000000000000
      end
      object rngSM: TDaisyRange
        Left = 340
        Top = 72
        Width = 300
        Height = 28
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzSM
        TabOrder = 9
        TabStop = True
        Max = 100.000000000000000000
        Value = 30.000000000000000000
        Step = 1.000000000000000000
      end
      object rngMD: TDaisyRange
        Left = 340
        Top = 104
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 10
        TabStop = True
        Max = 100.000000000000000000
        Value = 30.000000000000000000
        Step = 1.000000000000000000
      end
      object rngLG: TDaisyRange
        Left = 340
        Top = 136
        Width = 300
        Height = 36
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzLG
        TabOrder = 11
        TabStop = True
        Max = 100.000000000000000000
        Value = 30.000000000000000000
        Step = 1.000000000000000000
      end
      object rngXL: TDaisyRange
        Left = 340
        Top = 172
        Width = 300
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzXL
        TabOrder = 12
        TabStop = True
        Max = 100.000000000000000000
        Value = 30.000000000000000000
        Step = 1.000000000000000000
      end
      object rngSteps: TDaisyRange
        Left = 340
        Top = 216
        Width = 300
        Height = 63
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 13
        TabStop = True
        Max = 100.000000000000000000
        Value = 50.000000000000000000
        Step = 25.000000000000000000
        TickCount = 5
        TickLabels.Strings = (
          '0'
          '25'
          '50'
          '75'
          '100')
      end
      object rngNoFill: TDaisyRange
        Left = 340
        Top = 287
        Width = 300
        Height = 32
        Cursor = crHandPoint
        Variant = dvAccent
        TabOrder = 14
        TabStop = True
        Max = 100.000000000000000000
        Value = 70.000000000000000000
        Step = 1.000000000000000000
        ShowFill = False
      end
      object rngVertical: TDaisyRange
        Left = 680
        Top = 40
        Width = 32
        Height = 240
        Cursor = crHandPoint
        Variant = dvSecondary
        TabOrder = 15
        TabStop = True
        Max = 100.000000000000000000
        Value = 60.000000000000000000
        Step = 1.000000000000000000
        Orientation = roVertical
      end
      object rngVerticalSteps: TDaisyRange
        Left = 740
        Top = 40
        Width = 44
        Height = 240
        Cursor = crHandPoint
        Variant = dvSuccess
        TabOrder = 16
        TabStop = True
        Max = 100.000000000000000000
        Value = 40.000000000000000000
        Step = 20.000000000000000000
        Orientation = roVertical
        TickCount = 6
      end
    end
    object tsButtons: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 0
      Caption = 'Buttons'
      object lblSquare: TLabel
        Left = 16
        Top = 8
        Width = 116
        Height = 21
        Caption = 'Square buttons'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblCircle: TLabel
        Left = 16
        Top = 112
        Width = 106
        Height = 21
        Caption = 'Circle buttons'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnSquareXS: TDaisySquareButton
        Left = 16
        Top = 48
        Width = 24
        Height = 24
        Cursor = crHandPoint
        Variant = dvError
        SizeKind = dzXS
        TabOrder = 0
        TabStop = True
        Caption = #10084
      end
      object btnSquareSM: TDaisySquareButton
        Left = 64
        Top = 48
        Width = 32
        Height = 32
        Cursor = crHandPoint
        Variant = dvNeutral
        Style = dsOutline
        SizeKind = dzSM
        TabOrder = 1
        TabStop = True
        Caption = #55357#56589
      end
      object btnSquareMD: TDaisySquareButton
        Left = 120
        Top = 48
        Width = 40
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 2
        TabStop = True
        Caption = #55357#56596
      end
      object btnSquareLG: TDaisySquareButton
        Left = 184
        Top = 48
        Width = 48
        Height = 48
        Cursor = crHandPoint
        Variant = dvSecondary
        Style = dsSoft
        SizeKind = dzLG
        TabOrder = 3
        TabStop = True
        Caption = #55357#56960
      end
      object btnSquareXL: TDaisySquareButton
        Left = 256
        Top = 48
        Width = 56
        Height = 56
        Cursor = crHandPoint
        Variant = dvAccent
        Style = dsDash
        SizeKind = dzXL
        TabOrder = 4
        TabStop = True
        Caption = #9881
      end
      object btnSquareGhost: TDaisySquareButton
        Left = 336
        Top = 48
        Width = 40
        Height = 40
        Cursor = crHandPoint
        Style = dsGhost
        TabOrder = 5
        TabStop = True
        Caption = #55357#56397
      end
      object btnCircleXS: TDaisyCircleButton
        Left = 16
        Top = 152
        Width = 24
        Height = 24
        Cursor = crHandPoint
        Variant = dvWarning
        SizeKind = dzXS
        TabOrder = 6
        TabStop = True
        Caption = #11088
      end
      object btnCircleSM: TDaisyCircleButton
        Left = 64
        Top = 152
        Width = 32
        Height = 32
        Cursor = crHandPoint
        Variant = dvNeutral
        Style = dsOutline
        SizeKind = dzSM
        TabOrder = 7
        TabStop = True
        Caption = #55357#56832
      end
      object btnCircleMD: TDaisyCircleButton
        Left = 120
        Top = 152
        Width = 40
        Height = 40
        Cursor = crHandPoint
        Variant = dvError
        Style = dsSoft
        TabOrder = 8
        TabStop = True
        Caption = #55357#56613
      end
      object btnCircleLG: TDaisyCircleButton
        Left = 184
        Top = 152
        Width = 48
        Height = 48
        Cursor = crHandPoint
        Variant = dvSuccess
        SizeKind = dzLG
        TabOrder = 9
        TabStop = True
        Caption = #10003
      end
      object btnCircleXL: TDaisyCircleButton
        Left = 256
        Top = 152
        Width = 56
        Height = 56
        Cursor = crHandPoint
        Variant = dvPrimary
        SizeKind = dzXL
        TabOrder = 10
        TabStop = True
        Caption = #55357#56960
      end
      object btnCircleGhost: TDaisyCircleButton
        Left = 336
        Top = 152
        Width = 40
        Height = 40
        Cursor = crHandPoint
        Variant = dvError
        Style = dsGhost
        TabOrder = 11
        TabStop = True
        Caption = #10084
      end
    end
    object tsFab: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1106
      Height = 406
      TabOrder = 3
      Caption = 'FAB'
      object lblFab: TLabel
        Left = 16
        Top = 8
        Width = 178
        Height = 21
        Caption = 'Floating action buttons'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblFabResult: TLabel
        Left = 16
        Top = 340
        Width = 89
        Height = 15
        Caption = 'FAB action: none'
      end
      object lblArc: TLabel
        Left = 940
        Top = 8
        Width = 120
        Height = 21
        Caption = 'FAB flower (arc)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object fabDown: TDaisyFloatingActionButton
        Left = 188
        Top = 48
        Width = 48
        Height = 48
        Variant = dvPrimary
        TabOrder = 0
        TabStop = True
        Caption = '+'
        Items = <
          item
            Caption = #55357#56589
            Description = 'Search'
          end
          item
            Caption = #55357#56596
            Description = 'Notify'
          end
          item
            Caption = #9881
            Description = 'Settings'
          end>
        Direction = fdDown
        OnItemClick = FabItemClick
      end
      object fabRight: TDaisyFloatingActionButton
        Left = 16
        Top = 48
        Width = 56
        Height = 56
        Variant = dvSecondary
        SizeKind = dzLG
        TabOrder = 1
        TabStop = True
        Caption = '+'
        Items = <
          item
            Caption = #10084
          end
          item
            Caption = #11088
          end
          item
            Caption = #55357#56832
          end>
        Direction = fdRight
        OnItemClick = FabItemClick
      end
      object fabLeft: TDaisyFloatingActionButton
        Left = 560
        Top = 48
        Width = 56
        Height = 56
        Variant = dvAccent
        SizeKind = dzLG
        TabOrder = 2
        TabStop = True
        Caption = '+'
        Items = <
          item
            Caption = #55357#56960
          end
          item
            Caption = #55357#56613
          end
          item
            Caption = #55357#56397
          end>
        Direction = fdLeft
        OnItemClick = FabItemClick
      end
      object fabUp: TDaisyFloatingActionButton
        Left = 760
        Top = 300
        Width = 56
        Height = 56
        Variant = dvSuccess
        SizeKind = dzLG
        TabOrder = 3
        TabStop = True
        Caption = #55357#56960
        Items = <
          item
            Caption = #10003
            Description = 'Done'
          end
          item
            Caption = #55357#56596
            Description = 'Remind me'
          end
          item
            Caption = #10084
            Description = 'Favourite'
          end>
        OnItemClick = FabItemClick
      end
      object fabArc: TDaisyFloatingActionButton
        Left = 980
        Top = 300
        Width = 56
        Height = 56
        Variant = dvAccent
        SizeKind = dzLG
        TabOrder = 4
        TabStop = True
        Caption = '+'
        Items = <
          item
            Caption = #55357#56589
            Description = 'Search'
          end
          item
            Caption = #55357#56596
            Description = 'Notify'
          end
          item
            Caption = #10084
            Description = 'Like'
          end
          item
            Caption = #9881
            Description = 'Settings'
          end>
        Direction = fdArc
        OnItemClick = FabItemClick
      end
    end
  end
  object alMain: TActionList
    Left = 510
    Top = 20
    object actTitleBar: TAction
      Caption = 'Theme the window title bar'
      Checked = True
      OnExecute = chkTitleBarClick
    end
    object actToastClear: TAction
      Caption = 'Clear all'
      OnExecute = ToastClearClick
    end
    object actToggleLoading: TAction
      Caption = 'Toggle loading on all'
      OnExecute = btnToggleLoadingClick
    end
  end
  object Styler: TDaisyFormStyler
    Left = 640
    Top = 16
  end
end
