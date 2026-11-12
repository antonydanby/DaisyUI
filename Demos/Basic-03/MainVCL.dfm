object Form14: TForm14
  Left = 0
  Top = 0
  Caption = 'DaisyUI VCL demo - badges'
  ClientHeight = 440
  ClientWidth = 960
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
    Top = 26
    Width = 41
    Height = 15
    Caption = 'Theme:'
  end
  object Styler: TDaisyFormStyler
    Left = 760
    Top = 8
  end
  object selTheme: TDaisySelect
    Left = 80
    Top = 14
    Width = 200
    Height = 40
    TabOrder = 0
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
    OnChange = ThemeSelectChange
  end
  object chkTitleBar: TDaisyCheckBox
    Left = 320
    Top = 22
    Width = 240
    Height = 24
    Cursor = crHandPoint
    TabOrder = 1
    Action = actTitleBar
  end
  object chkRTL: TDaisyCheckBox
    Left = 700
    Top = 22
    Width = 200
    Height = 24
    Cursor = crHandPoint
    TabOrder = 5
    TabStop = True
    Caption = 'Right-to-left'
    OnChange = RTLChange
  end
  object alMain: TActionList
    Left = 570
    Top = 20
    object actTitleBar: TAction
      AutoCheck = False
      Caption = 'Theme the window title bar'
      Checked = True
      OnExecute = chkTitleBarClick
    end
    object actInbox: TAction
      Caption = 'Inbox'
      OnExecute = InboxExecute
    end
    object actNotify: TAction
      Caption = 'Notifications'
      OnExecute = NotifyExecute
    end
  end
  object themeCtl: TDaisyThemeController
    Left = 600
    Top = 20
    Width = 76
    Height = 28
    TabOrder = 90
    Kind = tkSunMoon
    OnChange = ThemeControllerChange
  end
  object pcMain: TDaisyPageControl
    Left = 16
    Top = 64
    Width = 928
    Height = 360
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
    object tsBadges: TDaisyTabSheet
      Caption = 'Badges'
      object lblBadge: TLabel
        Left = 24
        Top = 8
        Width = 48
        Height = 21
        Caption = 'Badge'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSizes: TLabel
        Left = 24
        Top = 84
        Width = 88
        Height = 21
        Caption = 'Badge sizes'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblColors: TLabel
        Left = 24
        Top = 168
        Width = 136
        Height = 21
        Caption = 'Badge with colors'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object bdgDefault: TDaisyBadge
        Left = 24
        Top = 40
        Width = 62
        Height = 24
        TabOrder = 0
        Caption = 'Badge'
      end
      object bdgNeutral: TDaisyBadge
        Left = 128
        Top = 40
        Width = 67
        Height = 24
        Variant = dvNeutral
        TabOrder = 1
        Caption = 'neutral'
      end
      object bdgPrimary: TDaisyBadge
        Left = 232
        Top = 40
        Width = 71
        Height = 24
        Variant = dvPrimary
        TabOrder = 2
        Caption = 'primary'
      end
      object bdgSecondary: TDaisyBadge
        Left = 336
        Top = 40
        Width = 86
        Height = 24
        Variant = dvSecondary
        TabOrder = 3
        Caption = 'secondary'
      end
      object bdgAccent: TDaisyBadge
        Left = 440
        Top = 40
        Width = 63
        Height = 24
        Variant = dvAccent
        TabOrder = 4
        Caption = 'accent'
      end
      object bdgGhost: TDaisyBadge
        Left = 544
        Top = 40
        Width = 59
        Height = 24
        Style = dsGhost
        TabOrder = 5
        Caption = 'ghost'
      end
      object bdgXS: TDaisyBadge
        Left = 24
        Top = 124
        Width = 44
        Height = 16
        Variant = dvPrimary
        SizeKind = dzXS
        TabOrder = 6
        Caption = 'Xsmall'
      end
      object bdgSM: TDaisyBadge
        Left = 128
        Top = 122
        Width = 49
        Height = 20
        Variant = dvPrimary
        SizeKind = dzSM
        TabOrder = 7
        Caption = 'Small'
      end
      object bdgMD: TDaisyBadge
        Left = 232
        Top = 120
        Width = 75
        Height = 24
        Variant = dvPrimary
        TabOrder = 8
        Caption = 'Medium'
      end
      object bdgLG: TDaisyBadge
        Left = 336
        Top = 118
        Width = 67
        Height = 28
        Variant = dvPrimary
        SizeKind = dzLG
        TabOrder = 9
        Caption = 'Large'
      end
      object bdgXL: TDaisyBadge
        Left = 440
        Top = 116
        Width = 82
        Height = 32
        Variant = dvPrimary
        SizeKind = dzXL
        TabOrder = 10
        Caption = 'Xlarge'
      end
      object bdgColNeutral: TDaisyBadge
        Left = 24
        Top = 200
        Width = 67
        Height = 24
        Variant = dvNeutral
        TabOrder = 11
        Caption = 'neutral'
      end
      object bdgColPrimary: TDaisyBadge
        Left = 128
        Top = 200
        Width = 71
        Height = 24
        Variant = dvPrimary
        TabOrder = 12
        Caption = 'primary'
      end
      object bdgColSecondary: TDaisyBadge
        Left = 232
        Top = 200
        Width = 86
        Height = 24
        Variant = dvSecondary
        TabOrder = 13
        Caption = 'secondary'
      end
      object bdgColAccent: TDaisyBadge
        Left = 336
        Top = 200
        Width = 63
        Height = 24
        Variant = dvAccent
        TabOrder = 14
        Caption = 'accent'
      end
      object bdgColInfo: TDaisyBadge
        Left = 440
        Top = 200
        Width = 47
        Height = 24
        Variant = dvInfo
        TabOrder = 15
        Caption = 'info'
      end
      object bdgColSuccess: TDaisyBadge
        Left = 544
        Top = 200
        Width = 69
        Height = 24
        Variant = dvSuccess
        TabOrder = 16
        Caption = 'success'
      end
      object bdgColWarning: TDaisyBadge
        Left = 648
        Top = 200
        Width = 73
        Height = 24
        Variant = dvWarning
        TabOrder = 17
        Caption = 'warning'
      end
      object bdgColError: TDaisyBadge
        Left = 752
        Top = 200
        Width = 54
        Height = 24
        Variant = dvError
        TabOrder = 18
        Caption = 'error'
      end
    end
    object tsStyles: TDaisyTabSheet
      Caption = 'Styles'
      object lblSoft: TLabel
        Left = 24
        Top = 8
        Width = 159
        Height = 21
        Caption = 'Badge with soft style'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblOutline: TLabel
        Left = 24
        Top = 80
        Width = 185
        Height = 21
        Caption = 'Badge with outline style'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblDash: TLabel
        Left = 24
        Top = 152
        Width = 166
        Height = 21
        Caption = 'Badge with dash style'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object bdgSoftNeutral: TDaisyBadge
        Left = 24
        Top = 40
        Width = 67
        Height = 24
        Variant = dvNeutral
        Style = dsSoft
        TabOrder = 0
        Caption = 'neutral'
      end
      object bdgSoftPrimary: TDaisyBadge
        Left = 128
        Top = 40
        Width = 71
        Height = 24
        Variant = dvPrimary
        Style = dsSoft
        TabOrder = 1
        Caption = 'primary'
      end
      object bdgSoftSecondary: TDaisyBadge
        Left = 232
        Top = 40
        Width = 86
        Height = 24
        Variant = dvSecondary
        Style = dsSoft
        TabOrder = 2
        Caption = 'secondary'
      end
      object bdgSoftAccent: TDaisyBadge
        Left = 336
        Top = 40
        Width = 63
        Height = 24
        Variant = dvAccent
        Style = dsSoft
        TabOrder = 3
        Caption = 'accent'
      end
      object bdgSoftInfo: TDaisyBadge
        Left = 440
        Top = 40
        Width = 47
        Height = 24
        Variant = dvInfo
        Style = dsSoft
        TabOrder = 4
        Caption = 'info'
      end
      object bdgSoftSuccess: TDaisyBadge
        Left = 544
        Top = 40
        Width = 69
        Height = 24
        Variant = dvSuccess
        Style = dsSoft
        TabOrder = 5
        Caption = 'success'
      end
      object bdgSoftWarning: TDaisyBadge
        Left = 648
        Top = 40
        Width = 73
        Height = 24
        Variant = dvWarning
        Style = dsSoft
        TabOrder = 6
        Caption = 'warning'
      end
      object bdgSoftError: TDaisyBadge
        Left = 752
        Top = 40
        Width = 54
        Height = 24
        Variant = dvError
        Style = dsSoft
        TabOrder = 7
        Caption = 'error'
      end
      object bdgOutNeutral: TDaisyBadge
        Left = 24
        Top = 112
        Width = 67
        Height = 24
        Variant = dvNeutral
        Style = dsOutline
        TabOrder = 8
        Caption = 'neutral'
      end
      object bdgOutPrimary: TDaisyBadge
        Left = 128
        Top = 112
        Width = 71
        Height = 24
        Variant = dvPrimary
        Style = dsOutline
        TabOrder = 9
        Caption = 'primary'
      end
      object bdgOutSecondary: TDaisyBadge
        Left = 232
        Top = 112
        Width = 86
        Height = 24
        Variant = dvSecondary
        Style = dsOutline
        TabOrder = 10
        Caption = 'secondary'
      end
      object bdgOutAccent: TDaisyBadge
        Left = 336
        Top = 112
        Width = 63
        Height = 24
        Variant = dvAccent
        Style = dsOutline
        TabOrder = 11
        Caption = 'accent'
      end
      object bdgOutInfo: TDaisyBadge
        Left = 440
        Top = 112
        Width = 47
        Height = 24
        Variant = dvInfo
        Style = dsOutline
        TabOrder = 12
        Caption = 'info'
      end
      object bdgOutSuccess: TDaisyBadge
        Left = 544
        Top = 112
        Width = 69
        Height = 24
        Variant = dvSuccess
        Style = dsOutline
        TabOrder = 13
        Caption = 'success'
      end
      object bdgOutWarning: TDaisyBadge
        Left = 648
        Top = 112
        Width = 73
        Height = 24
        Variant = dvWarning
        Style = dsOutline
        TabOrder = 14
        Caption = 'warning'
      end
      object bdgOutError: TDaisyBadge
        Left = 752
        Top = 112
        Width = 54
        Height = 24
        Variant = dvError
        Style = dsOutline
        TabOrder = 15
        Caption = 'error'
      end
      object bdgDashNeutral: TDaisyBadge
        Left = 24
        Top = 184
        Width = 67
        Height = 24
        Variant = dvNeutral
        Style = dsDash
        TabOrder = 16
        Caption = 'neutral'
      end
      object bdgDashPrimary: TDaisyBadge
        Left = 128
        Top = 184
        Width = 71
        Height = 24
        Variant = dvPrimary
        Style = dsDash
        TabOrder = 17
        Caption = 'primary'
      end
      object bdgDashSecondary: TDaisyBadge
        Left = 232
        Top = 184
        Width = 86
        Height = 24
        Variant = dvSecondary
        Style = dsDash
        TabOrder = 18
        Caption = 'secondary'
      end
      object bdgDashAccent: TDaisyBadge
        Left = 336
        Top = 184
        Width = 63
        Height = 24
        Variant = dvAccent
        Style = dsDash
        TabOrder = 19
        Caption = 'accent'
      end
      object bdgDashInfo: TDaisyBadge
        Left = 440
        Top = 184
        Width = 47
        Height = 24
        Variant = dvInfo
        Style = dsDash
        TabOrder = 20
        Caption = 'info'
      end
      object bdgDashSuccess: TDaisyBadge
        Left = 544
        Top = 184
        Width = 69
        Height = 24
        Variant = dvSuccess
        Style = dsDash
        TabOrder = 21
        Caption = 'success'
      end
      object bdgDashWarning: TDaisyBadge
        Left = 648
        Top = 184
        Width = 73
        Height = 24
        Variant = dvWarning
        Style = dsDash
        TabOrder = 22
        Caption = 'warning'
      end
      object bdgDashError: TDaisyBadge
        Left = 752
        Top = 184
        Width = 54
        Height = 24
        Variant = dvError
        Style = dsDash
        TabOrder = 23
        Caption = 'error'
      end
    end
    object tsSpecial: TDaisyTabSheet
      Caption = 'Special'
      object lblNeutral: TLabel
        Left = 24
        Top = 8
        Width = 307
        Height = 21
        Caption = 'Neutral badge with outline or dash style'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblGhost: TLabel
        Left = 440
        Top = 8
        Width = 95
        Height = 21
        Caption = 'Badge ghost'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblEmpty: TLabel
        Left = 24
        Top = 80
        Width = 101
        Height = 21
        Caption = 'Empty badge'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblIcon: TLabel
        Left = 24
        Top = 160
        Width = 123
        Height = 21
        Caption = 'Badge with icon'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object bdgNeutralOutline: TDaisyBadge
        Left = 24
        Top = 40
        Width = 66
        Height = 24
        Variant = dvNeutral
        Style = dsOutline
        TabOrder = 0
        Caption = 'outline'
      end
      object bdgNeutralDash: TDaisyBadge
        Left = 128
        Top = 40
        Width = 53
        Height = 24
        Variant = dvNeutral
        Style = dsDash
        TabOrder = 1
        Caption = 'dash'
      end
      object bdgGhostMD: TDaisyBadge
        Left = 440
        Top = 40
        Width = 59
        Height = 24
        Style = dsGhost
        TabOrder = 2
        Caption = 'ghost'
      end
      object bdgGhostLG: TDaisyBadge
        Left = 544
        Top = 38
        Width = 67
        Height = 28
        Style = dsGhost
        SizeKind = dzLG
        TabOrder = 3
        Caption = 'ghost'
      end
      object bdgEmptyXS: TDaisyBadge
        Left = 24
        Top = 116
        Width = 16
        Height = 16
        Variant = dvPrimary
        SizeKind = dzXS
        TabOrder = 4
        Caption = ''
      end
      object bdgEmptySM: TDaisyBadge
        Left = 72
        Top = 114
        Width = 20
        Height = 20
        Variant = dvSecondary
        SizeKind = dzSM
        TabOrder = 5
        Caption = ''
      end
      object bdgEmptyMD: TDaisyBadge
        Left = 120
        Top = 112
        Width = 24
        Height = 24
        Variant = dvAccent
        TabOrder = 6
        Caption = ''
      end
      object bdgEmptyLG: TDaisyBadge
        Left = 168
        Top = 110
        Width = 28
        Height = 28
        Variant = dvInfo
        SizeKind = dzLG
        TabOrder = 7
        Caption = ''
      end
      object bdgEmptyXL: TDaisyBadge
        Left = 216
        Top = 108
        Width = 32
        Height = 32
        Variant = dvError
        SizeKind = dzXL
        TabOrder = 8
        Caption = ''
      end
      object bdgIconInfo: TDaisyBadge
        Left = 24
        Top = 192
        Width = 67
        Height = 24
        Variant = dvInfo
        TabOrder = 9
        Caption = 'Info'
        Icon = diInfo
      end
      object bdgIconSuccess: TDaisyBadge
        Left = 128
        Top = 192
        Width = 89
        Height = 24
        Variant = dvSuccess
        TabOrder = 10
        Caption = 'Success'
        Icon = diSuccess
      end
      object bdgIconWarning: TDaisyBadge
        Left = 248
        Top = 192
        Width = 95
        Height = 24
        Variant = dvWarning
        TabOrder = 11
        Caption = 'Warning'
        Icon = diWarning
        IconPosition = bipRight
      end
      object bdgIconError: TDaisyBadge
        Left = 368
        Top = 192
        Width = 73
        Height = 24
        Variant = dvError
        TabOrder = 12
        Caption = 'Error'
        Icon = diError
        IconPosition = bipRight
      end
      object bdgIconAuto: TDaisyBadge
        Left = 470
        Top = 192
        Width = 102
        Height = 24
        Variant = dvSuccess
        Style = dsSoft
        TabOrder = 13
        Caption = 'Auto icon'
        Icon = diAuto
      end
    end
    object tsButtons: TDaisyTabSheet
      Caption = 'Badge buttons'
      object lblButton: TLabel
        Left = 24
        Top = 8
        Width = 136
        Height = 21
        Caption = 'Badge in a button'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblStatus: TLabel
        Left = 24
        Top = 96
        Height = 15
        Caption = 'Click a badge button above'
      end
      object btnInbox: TDaisyBadgeButton
        Left = 24
        Top = 40
        Width = 136
        Height = 40
        Cursor = crHandPoint
        TabOrder = 0
        TabStop = True
        Action = actInbox
        BadgeText = '+99'
      end
      object btnInboxSecondary: TDaisyBadgeButton
        Left = 176
        Top = 40
        Width = 136
        Height = 40
        Cursor = crHandPoint
        TabOrder = 1
        TabStop = True
        OnClick = BadgeButtonClick
        Caption = 'Inbox'
        BadgeText = '+99'
        BadgeVariant = dvSecondary
      end
      object btnNotify: TDaisyBadgeButton
        Left = 328
        Top = 40
        Width = 200
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 2
        TabStop = True
        Action = actNotify
        BadgeText = '12'
        BadgeVariant = dvAccent
      end
      object btnBadgeIcon: TDaisyBadgeButton
        Left = 544
        Top = 40
        Width = 160
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 3
        TabStop = True
        OnClick = BadgeButtonClick
        Caption = 'Messages'
        BadgeText = 'New'
        BadgeVariant = dvSuccess
        BadgeIcon = diSuccess
      end
      object btnBadgeSmall: TDaisyBadgeButton
        Left = 720
        Top = 40
        Width = 136
        Height = 32
        Cursor = crHandPoint
        Style = dsOutline
        SizeKind = dzSM
        TabOrder = 4
        TabStop = True
        OnClick = BadgeButtonClick
        Caption = 'Alerts'
        BadgeText = '3'
        BadgeVariant = dvError
        BadgeStyle = dsSoft
        BadgeSize = dzXS
      end
    end
    object tsSvg: TDaisyTabSheet
      Caption = 'SVG icons'
      object lblSvg: TLabel
        Left = 24
        Top = 8
        Width = 159
        Height = 21
        Caption = 'SVG icons (SVG property)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnSvgHeart: TDaisyButton
        Left = 24
        Top = 40
        Width = 112
        Height = 40
        Cursor = crHandPoint
        Variant = dvPrimary
        TabOrder = 0
        TabStop = True
        Caption = 'Like'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>'
          '</svg>')
      end
      object btnSvgNext: TDaisyButton
        Left = 152
        Top = 40
        Width = 112
        Height = 40
        Cursor = crHandPoint
        Variant = dvSecondary
        TabOrder = 1
        TabStop = True
        Caption = 'Next'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>'
          '</svg>')
        IconPosition = bipRight
      end
      object btnSvgAdd: TDaisyButton
        Left = 280
        Top = 40
        Width = 112
        Height = 40
        Cursor = crHandPoint
        Variant = dvSuccess
        Style = dsOutline
        TabOrder = 2
        TabStop = True
        Caption = 'Add'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M12 4.5v15m7.5-7.5h-15"/>'
          '</svg>')
      end
      object btnSvgBell: TDaisySquareButton
        Left = 408
        Top = 40
        Width = 40
        Height = 40
        Cursor = crHandPoint
        Variant = dvAccent
        TabOrder = 3
        TabStop = True
        Caption = ''
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0"/>'
          '</svg>')
      end
      object btnSvgCheck: TDaisyCircleButton
        Left = 464
        Top = 40
        Width = 40
        Height = 40
        Cursor = crHandPoint
        Variant = dvSuccess
        TabOrder = 4
        TabStop = True
        Caption = ''
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M4.5 12.75l6 6 9-13.5"/>'
          '</svg>')
      end
      object bdgSvgHeart: TDaisyBadge
        Left = 520
        Top = 48
        Width = 75
        Height = 24
        Variant = dvPrimary
        TabOrder = 5
        Caption = 'Liked'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z"/>'
          '</svg>')
      end
      object bdgSvgCheck: TDaisyBadge
        Left = 604
        Top = 48
        Width = 76
        Height = 24
        Variant = dvSuccess
        Style = dsSoft
        TabOrder = 6
        Caption = 'Done'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M4.5 12.75l6 6 9-13.5"/>'
          '</svg>')
      end
      object btnSvgBadge: TDaisyBadgeButton
        Left = 688
        Top = 40
        Width = 176
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        TabOrder = 7
        TabStop = True
        OnClick = BadgeButtonClick
        Caption = 'Alerts'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0"/>'
          '</svg>')
        BadgeText = '5'
        BadgeVariant = dvError
        BadgeSVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor">'
          '<path d="M12 4.5v15m7.5-7.5h-15"/>'
          '</svg>')
      end
      object btnSvgSettings: TDaisyButton
        Left = 24
        Top = 92
        Width = 144
        Height = 40
        Cursor = crHandPoint
        Variant = dvNeutral
        Style = dsOutline
        TabOrder = 8
        TabStop = True
        Caption = 'Tabler'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">'
          '<path stroke="none" d="M0 0h24v24H0z" fill="none" />'
          '<path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065" />'
          '<path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" />'
          '</svg>')
      end
      object btnSvgHome: TDaisyButton
        Left = 184
        Top = 92
        Width = 144
        Height = 40
        Cursor = crHandPoint
        Variant = dvInfo
        TabOrder = 9
        TabStop = True
        Caption = 'Material'
        SVG.Strings = (
          '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24">'
          '<path d="M240-200h120v-240h240v240h120v-360L480-740 240-560v360Zm-80 80v-480l320-240 320 240v480H520v-240h-80v240H160Zm320-350Z"/>'
          '</svg>')
      end
    end
  end
end
