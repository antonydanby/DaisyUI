object Form16: TForm16
  Left = 0
  Top = 0
  Caption = 'DaisyUI VCL demo - chat, countdown, list and stat'
  ClientHeight = 600
  ClientWidth = 1260
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object lblTheme: TLabel
    Left = 24
    Top = 21
    Width = 40
    Height = 15
    Caption = 'Theme:'
  end
  object lblStatus: TLabel
    Left = 740
    Top = 21
    Width = 3
    Height = 15
  end
  object selTheme: TDaisySelect
    Left = 80
    Top = 8
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
  object alMain: TActionList
    Left = 1180
    Top = 16
    object actTitleBar: TAction
      AutoCheck = False
      Caption = 'Theme the window title bar'
      Checked = True
      OnExecute = chkTitleBarClick
    end
    object actProgAdd: TAction
      Caption = 'Add 10'
      OnExecute = ProgressAddClick
    end
    object actProgReset: TAction
      Caption = 'Reset'
      OnExecute = ProgressResetClick
      OnUpdate = actProgResetUpdate
    end
  end
  object chkTitleBar: TDaisyCheckBox
    Left = 460
    Top = 16
    Width = 207
    Height = 30
    Cursor = crHandPoint
    TabOrder = 1
    TabStop = True
    Action = actTitleBar
    Checked = True
  end
  object themeCtl: TDaisyThemeController
    Left = 1000
    Top = 16
    Width = 130
    Height = 28
    TabOrder = 90
    Kind = tkCheckBox
    Caption = 'Dark mode'
    OnChange = ThemeControllerChange
  end
  object pcMain: TDaisyPageControl
    Left = 16
    Top = 64
    Width = 1228
    Height = 520
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
    TabStop = True
    ActivePageIndex = 0
    object tsCountdown: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1258
      Height = 502
      TabOrder = 1
      Caption = 'Countdown'
      object cdPlain: TDaisyCountdown
        Left = 24
        Top = 8
        Width = 40
        Height = 48
        Cursor = crHandPoint
        TabOrder = 0
        OnClick = CountdownClick
        Segments = <
          item
            Value = 59
          end>
        Active = True
      end
      object cdLarge: TDaisyCountdown
        Left = 100
        Top = 8
        Width = 66
        Height = 81
        Cursor = crHandPoint
        SizeKind = dzXL
        TabOrder = 1
        OnClick = CountdownClick
        Segments = <
          item
            Value = 42
          end>
        Active = True
      end
      object cdClock: TDaisyCountdown
        Left = 240
        Top = 8
        Width = 144
        Height = 48
        Cursor = crHandPoint
        TabOrder = 2
        OnClick = CountdownClick
        Segments = <
          item
            Value = 10
          end
          item
            Value = 24
          end
          item
            Value = 59
          end>
        Separator = ':'
        Active = True
      end
      object cdLabels: TDaisyCountdown
        Left = 440
        Top = 8
        Width = 349
        Height = 48
        Cursor = crHandPoint
        TabOrder = 3
        OnClick = CountdownClick
        Segments = <
          item
            Value = 15
            Caption = 'days'
          end
          item
            Value = 10
            Caption = 'hours'
          end
          item
            Value = 24
            Caption = 'min'
          end
          item
            Value = 59
            Caption = 'sec'
          end>
        LabelPlacement = clAfter
        Active = True
      end
      object cdBelow: TDaisyCountdown
        Left = 24
        Top = 104
        Width = 160
        Height = 67
        Cursor = crHandPoint
        TabOrder = 4
        OnClick = CountdownClick
        Segments = <
          item
            Value = 10
            Caption = 'hours'
          end
          item
            Value = 24
            Caption = 'min'
          end
          item
            Value = 59
            Caption = 'sec'
          end>
        LabelPlacement = clBelow
        Active = True
      end
      object cdBoxed: TDaisyCountdown
        Left = 320
        Top = 104
        Width = 232
        Height = 79
        Cursor = crHandPoint
        TabOrder = 5
        OnClick = CountdownClick
        Segments = <
          item
            Value = 10
            Caption = 'hours'
          end
          item
            Value = 24
            Caption = 'min'
          end
          item
            Value = 59
            Caption = 'sec'
          end>
        LabelPlacement = clBelow
        Boxed = True
        Active = True
      end
      object cdLive: TDaisyCountdown
        Left = 620
        Top = 104
        Width = 148
        Height = 79
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 6
        OnClick = CountdownClick
        Segments = <
          item
            Caption = 'min'
          end
          item
            Value = 30
            Caption = 'sec'
          end>
        LabelPlacement = clBelow
        Boxed = True
        Active = True
        OnFinished = CountdownFinished
      end
      object cdMinutes: TDaisyCountdown
        Left = 24
        Top = 220
        Width = 148
        Height = 79
        Cursor = crHandPoint
        Variant = dvAccent
        TabOrder = 7
        OnClick = CountdownClick
        Segments = <
          item
            Value = 10
            Caption = 'hours'
          end
          item
            Value = 24
            Caption = 'min'
          end
          item
            Value = 59
            Caption = 'sec'
          end>
        LabelPlacement = clBelow
        Boxed = True
        Active = True
        ShowSeconds = False
      end
    end
    object tsList: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1258
      Height = 502
      TabOrder = 2
      Caption = 'List'
      object lstSecond: TDaisyList
        Left = 24
        Top = 8
        Width = 380
        Height = 256
        TabOrder = 0
        Items = <
          item
            Title = 'Dio Lupa'
            Subtitle = 'Remaining Reason'
            Icon.Emoji = #55356#57269
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M8 5v14l11-7z"/></svg>')
            Action2.SVG.Strings = (
              
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill' +
                '="none" stroke="currentColor">'
              
                '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.12' +
                '6-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.76' +
                '5 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>'
              '</svg>')
          end
          item
            Title = 'Ellie Beilish'
            Subtitle = 'Bears of a fever'
            Icon.Emoji = #55356#57272
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M8 5v14l11-7z"/></svg>')
            Action2.SVG.Strings = (
              
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill' +
                '="none" stroke="currentColor">'
              
                '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.12' +
                '6-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.76' +
                '5 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>'
              '</svg>')
          end
          item
            Title = 'Sabrino Gardener'
            Subtitle = 'Cappuccino'
            Icon.Emoji = #55357#56960
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M8 5v14l11-7z"/></svg>')
            Action2.SVG.Strings = (
              
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill' +
                '="none" stroke="currentColor">'
              
                '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.12' +
                '6-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.76' +
                '5 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>'
              '</svg>')
          end>
        Header = 'Most played songs this week'
        OnItemClick = ListItemClick
      end
      object lstThird: TDaisyList
        Left = 424
        Top = 8
        Width = 380
        Height = 256
        TabOrder = 1
        Items = <
          item
            Title = 'Margherita Pizza'
            Subtitle = 'Order #1042'
            Description = 'Out for delivery, arriving in 10 minutes.'
            Icon.Emoji = #55356#57173
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M9 5l7 7-7 7"/></svg>')
          end
          item
            Title = 'Launch kit'
            Subtitle = 'Order #1043'
            Description = 'Packed and waiting for a courier.'
            Icon.Emoji = #55357#56960
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M9 5l7 7-7 7"/></svg>')
          end
          item
            Title = 'Party supplies'
            Subtitle = 'Order #1044'
            Description = 'Delivered yesterday.'
            Icon.Emoji = #55356#57225
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M9 5l7 7-7 7"/></svg>')
          end>
        Header = 'Third column grows'
        Layout = llThirdGrows
        OnItemClick = ListItemClick
      end
      object lstWrap: TDaisyList
        Left = 824
        Top = 8
        Width = 380
        Height = 259
        TabOrder = 2
        Items = <
          item
            Title = 'Fix login bug'
            Subtitle = 'High priority'
            Description = 
              'Users on older browsers cannot sign in after the latest release.' +
              ' Reproduce, patch and add a regression test.'
            Icon.Emoji = #55357#56613
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M9 5l7 7-7 7"/></svg>')
          end
          item
            Title = 'Automate reports'
            Subtitle = 'Medium priority'
            Description = 'Replace the weekly manual export with a scheduled bot run.'
            Icon.Emoji = #55358#56598
            Action.SVG.Strings = (
              
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path' +
                ' d="M9 5l7 7-7 7"/></svg>')
          end>
        Header = 'Third column wraps'
        Layout = llThirdWraps
        OnItemClick = ListItemClick
      end
    end
    object tsStat: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1258
      Height = 502
      TabOrder = 3
      Caption = 'Stat'
      object statBasic: TDaisyStat
        Left = 24
        Top = 8
        Width = 455
        Height = 104
        TabOrder = 0
        Items = <
          item
            Title = 'Total Page Views'
            Value = '89,400'
            Description = '21% more than last month'
          end
          item
            Title = 'Downloads'
            Value = '31K'
            Description = 'Jan 1st - Feb 1st'
          end
          item
            Title = 'New Users'
            Value = '4,200'
            Description = '+400 (22%)'
          end>
        OnActionClick = StatActionClick
      end
      object statIcons: TDaisyStat
        Left = 24
        Top = 142
        Width = 678
        Height = 104
        TabOrder = 1
        Items = <
          item
            Title = 'Likes'
            Value = '25.6K'
            Description = '21% more than last month'
            Icon.SVG.Strings = (
              
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill' +
                '="none" stroke="currentColor">'
              
                '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.12' +
                '6-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.76' +
                '5 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>'
              '</svg>')
            FigureVariant = dvPrimary
          end
          item
            Title = 'Page Views'
            Value = '2.6M'
            Description = '21% more than last month'
            Icon.Emoji = #55357#56520
            FigureVariant = dvSecondary
          end
          item
            Title = 'Tasks done'
            Value = '86%'
            Description = '31 tasks remaining'
            Icon.Emoji = #9889
          end>
      end
      object statCentered: TDaisyStat
        Left = 24
        Top = 272
        Width = 401
        Height = 104
        TabOrder = 2
        Items = <
          item
            Title = 'Downloads'
            Value = '31K'
            Description = 'Jan 1st - Feb 1st'
          end
          item
            Title = 'New Users'
            Value = '4,200'
            Description = '+400 (22%)'
          end
          item
            Title = 'New Registers'
            Value = '1,200'
            Description = '-90 (14%)'
          end>
        Centered = True
      end
      object statVertical: TDaisyStat
        Left = 780
        Top = 8
        Width = 138
        Height = 312
        TabOrder = 3
        Items = <
          item
            Title = 'Downloads'
            Value = '31K'
            Description = 'Jan 1st - Feb 1st'
          end
          item
            Title = 'New Users'
            Value = '4,200'
            Description = '+400 (22%)'
          end
          item
            Title = 'New Registers'
            Value = '1,200'
            Description = '-90 (14%)'
          end>
        Direction = sdVertical
      end
      object statCustom: TDaisyStat
        Left = 440
        Top = 272
        Width = 324
        Height = 136
        TabOrder = 4
        Items = <
          item
            Title = 'Account balance'
            Value = '$89,400'
            Variant = dvPrimary
            ActionCaption = 'Add funds'
            ActionVariant = dvSuccess
          end
          item
            Title = 'Current balance'
            Value = '$89,400'
            Variant = dvNeutral
            ActionCaption = 'Withdraw'
            ActionVariant = dvError
          end>
        OnActionClick = StatActionClick
      end
    end
    object tsChat: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1258
      Height = 502
      TabOrder = 0
      Caption = 'Chat'
      object chatStart: TDaisyChatBubble
        Left = 24
        Top = 8
        Width = 380
        Height = 76
        TabOrder = 0
        Caption = 'You were the Chosen One!'
        Header = 'Obi-Wan Kenobi'
        HeaderTime = '12:45'
        Footer = 'Delivered'
        AvatarText = #55357#56832
      end
      object chatEnd: TDaisyChatBubble
        Left = 24
        Top = 96
        Width = 380
        Height = 76
        TabOrder = 1
        Caption = 'I hate you!'
        Placement = cpEnd
        Header = 'Anakin'
        HeaderTime = '12:46'
        Footer = 'Seen at 12:46'
        AvatarText = #55357#56845
      end
      object chatSvg: TDaisyChatBubble
        Left = 24
        Top = 184
        Width = 380
        Height = 76
        TabOrder = 2
        Caption = 'SVG avatars work too.'
        Header = 'Heart'
        Footer = 'Sent'
        SVG.Strings = (
          
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill' +
            '="none" stroke="currentColor">'
          
            '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.12' +
            '6-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.76' +
            '5 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>'
          '</svg>')
      end
      object chatEmoji: TDaisyChatBubble
        Left = 24
        Top = 272
        Width = 380
        Height = 44
        TabOrder = 3
        Caption = 'Colour emoji: '#55356#57225' '#55357#56960' '#55357#56613' '#55356#57269
        AvatarText = #55357#56395
      end
      object chatPrimary: TDaisyChatBubble
        Left = 424
        Top = 8
        Width = 380
        Height = 44
        Variant = dvPrimary
        TabOrder = 4
        Caption = 'Primary'
        AvatarText = #55357#56832
      end
      object chatSecondary: TDaisyChatBubble
        Left = 424
        Top = 60
        Width = 380
        Height = 44
        Variant = dvSecondary
        TabOrder = 6
        Caption = 'Secondary'
        Placement = cpEnd
        AvatarText = #55357#56846
      end
      object chatAccent: TDaisyChatBubble
        Left = 424
        Top = 112
        Width = 380
        Height = 44
        Variant = dvAccent
        TabOrder = 8
        Caption = 'Accent'
        AvatarText = #55356#57272
      end
      object chatInfo: TDaisyChatBubble
        Left = 424
        Top = 164
        Width = 380
        Height = 44
        Variant = dvInfo
        TabOrder = 10
        Caption = 'Info'
        Placement = cpEnd
        AvatarText = #55357#56420
      end
      object chatSuccess: TDaisyChatBubble
        Left = 424
        Top = 216
        Width = 380
        Height = 44
        Variant = dvSuccess
        TabOrder = 11
        Caption = 'Success'
        AvatarText = #55356#57173
      end
      object chatWarning: TDaisyChatBubble
        Left = 424
        Top = 268
        Width = 380
        Height = 44
        Variant = dvWarning
        TabOrder = 12
        Caption = 'Warning'
        Placement = cpEnd
        AvatarText = #55357#56613
      end
      object chatError: TDaisyChatBubble
        Left = 424
        Top = 320
        Width = 380
        Height = 44
        Variant = dvError
        TabOrder = 5
        Caption = 'Error'
        AvatarText = #55358#56598
      end
      object chatNoAvatar: TDaisyChatBubble
        Left = 824
        Top = 8
        Width = 380
        Height = 76
        TabOrder = 7
        Caption = 'A bubble without an avatar.'
        Header = 'Anonymous'
        HeaderTime = 'now'
        Footer = 'Delivered'
        ShowAvatar = False
      end
      object chatNoAvatarEnd: TDaisyChatBubble
        Left = 824
        Top = 96
        Width = 380
        Height = 76
        Variant = dvNeutral
        TabOrder = 9
        Caption = 'And one to the end.'
        Placement = cpEnd
        Header = 'Me'
        Footer = 'Seen'
        ShowAvatar = False
      end
      object edtChatText: TDaisyTextInput
        Left = 848
        Top = 237
        Width = 356
        Height = 32
        Cursor = crIBeam
        SizeKind = dzSM
        TabOrder = 13
        TabStop = True
        Text = ''
        OnChange = ChatEditChange
      end
      object edtChatHeader: TDaisyTextInput
        Left = 848
        Top = 280
        Width = 356
        Height = 32
        Cursor = crIBeam
        SizeKind = dzSM
        TabOrder = 14
        TabStop = True
        Text = ''
        OnChange = ChatEditChange
      end
      object lblChatEdit: TDaisyLabel
        Left = 848
        Top = 216
        Width = 125
        Height = 19
        TabOrder = 15
        Caption = 'Edit the first bubble:'
      end
    end
    object tsProgress: TDaisyTabSheet
      Left = 1
      Top = 41
      Width = 1258
      Height = 502
      TabOrder = 4
      Caption = 'Progress'
      object lblProgVariants: TDaisyLabel
        Left = 24
        Top = 8
        Width = 120
        Height = 19
        TabOrder = 0
        Caption = 'Progress variants'
      end
      object prgDefault: TDaisyProgress
        Left = 24
        Top = 40
        Width = 320
        Height = 8
        Value = 40.000000000000000000
      end
      object prgPrimary: TDaisyProgress
        Left = 24
        Top = 64
        Width = 320
        Height = 8
        Variant = dvPrimary
        Value = 50.000000000000000000
      end
      object prgSecondary: TDaisyProgress
        Left = 24
        Top = 88
        Width = 320
        Height = 8
        Variant = dvSecondary
        Value = 60.000000000000000000
      end
      object prgAccent: TDaisyProgress
        Left = 24
        Top = 112
        Width = 320
        Height = 8
        Variant = dvAccent
        Value = 70.000000000000000000
      end
      object prgInfo: TDaisyProgress
        Left = 24
        Top = 136
        Width = 320
        Height = 8
        Variant = dvInfo
        Value = 30.000000000000000000
      end
      object prgSuccess: TDaisyProgress
        Left = 24
        Top = 160
        Width = 320
        Height = 8
        Variant = dvSuccess
        Value = 80.000000000000000000
      end
      object prgWarning: TDaisyProgress
        Left = 24
        Top = 184
        Width = 320
        Height = 8
        Variant = dvWarning
        Value = 90.000000000000000000
      end
      object prgError: TDaisyProgress
        Left = 24
        Top = 208
        Width = 320
        Height = 8
        Variant = dvError
        Value = 20.000000000000000000
      end
      object lblProgSizes: TDaisyLabel
        Left = 400
        Top = 8
        Width = 100
        Height = 19
        TabOrder = 9
        Caption = 'Progress sizes'
      end
      object prgXS: TDaisyProgress
        Left = 400
        Top = 40
        Width = 300
        Height = 2
        SizeKind = dzXS
        Variant = dvPrimary
        Value = 60.000000000000000000
      end
      object prgSM: TDaisyProgress
        Left = 400
        Top = 64
        Width = 300
        Height = 4
        SizeKind = dzSM
        Variant = dvPrimary
        Value = 60.000000000000000000
      end
      object prgMD: TDaisyProgress
        Left = 400
        Top = 88
        Width = 300
        Height = 8
        Variant = dvPrimary
        Value = 60.000000000000000000
      end
      object prgLG: TDaisyProgress
        Left = 400
        Top = 112
        Width = 300
        Height = 12
        SizeKind = dzLG
        Variant = dvPrimary
        Value = 60.000000000000000000
      end
      object prgXL: TDaisyProgress
        Left = 400
        Top = 136
        Width = 300
        Height = 16
        SizeKind = dzXL
        Variant = dvPrimary
        Value = 60.000000000000000000
      end
      object lblProgLive: TDaisyLabel
        Left = 24
        Top = 244
        Width = 250
        Height = 19
        TabOrder = 15
        Caption = 'Indeterminate and value driven'
      end
      object prgIndeterminate: TDaisyProgress
        Left = 24
        Top = 280
        Width = 320
        Height = 8
        Variant = dvAccent
        Indeterminate = True
      end
      object prgLive: TDaisyProgress
        Left = 24
        Top = 312
        Width = 320
        Height = 12
        SizeKind = dzLG
        Variant = dvSuccess
        Value = 25.000000000000000000
      end
      object btnProgAdd: TDaisyButton
        Left = 24
        Top = 344
        Width = 100
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 18
        TabStop = True
        Action = actProgAdd
      end
      object btnProgReset: TDaisyButton
        Left = 136
        Top = 344
        Width = 100
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 19
        TabStop = True
        Action = actProgReset
      end
      object lblRadial: TDaisyLabel
        Left = 780
        Top = 8
        Width = 120
        Height = 19
        TabOrder = 20
        Caption = 'Radial progress'
      end
      object radDefault: TDaisyRadialProgress
        Left = 780
        Top = 40
        Width = 80
        Height = 80
        Value = 70.000000000000000000
      end
      object radPrimary: TDaisyRadialProgress
        Left = 880
        Top = 40
        Width = 80
        Height = 80
        Variant = dvPrimary
        Value = 50.000000000000000000
      end
      object radSecondary: TDaisyRadialProgress
        Left = 980
        Top = 40
        Width = 80
        Height = 80
        Variant = dvSecondary
        Value = 85.000000000000000000
      end
      object radAccent: TDaisyRadialProgress
        Left = 1080
        Top = 40
        Width = 80
        Height = 80
        Variant = dvAccent
        Value = 25.000000000000000000
      end
      object radInfo: TDaisyRadialProgress
        Left = 780
        Top = 140
        Width = 80
        Height = 80
        Variant = dvInfo
        Value = 60.000000000000000000
      end
      object radSuccess: TDaisyRadialProgress
        Left = 880
        Top = 140
        Width = 80
        Height = 80
        Variant = dvSuccess
        Value = 100.000000000000000000
      end
      object radWarning: TDaisyRadialProgress
        Left = 980
        Top = 140
        Width = 80
        Height = 80
        Variant = dvWarning
        Value = 40.000000000000000000
      end
      object radError: TDaisyRadialProgress
        Left = 1080
        Top = 140
        Width = 80
        Height = 80
        Variant = dvError
        Value = 15.000000000000000000
      end
      object lblRadialCustom: TDaisyLabel
        Left = 780
        Top = 244
        Width = 200
        Height = 19
        TabOrder = 29
        Caption = 'Filled, thickness and text'
      end
      object radFilled: TDaisyRadialProgress
        Left = 780
        Top = 280
        Width = 80
        Height = 80
        Variant = dvPrimary
        Filled = True
        Value = 65.000000000000000000
      end
      object radThick: TDaisyRadialProgress
        Left = 880
        Top = 280
        Width = 80
        Height = 80
        Variant = dvSuccess
        Thickness = 3
        Value = 75.000000000000000000
      end
      object radText: TDaisyRadialProgress
        Left = 980
        Top = 280
        Width = 100
        Height = 100
        Variant = dvAccent
        Thickness = 12
        DisplayText = '3 of 4'
        Value = 75.000000000000000000
      end
      object radLive: TDaisyRadialProgress
        Left = 1100
        Top = 280
        Width = 100
        Height = 100
        Variant = dvSuccess
        Thickness = 10
        Value = 25.000000000000000000
      end
    end
  end
  object Styler: TDaisyFormStyler
    Left = 300
    Top = 4
  end
end
