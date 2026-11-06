object FormPeak: TFormPeak
  Left = 0
  Top = 0
  Caption = 'Peak SVG - conversion and image list demo'
  ClientHeight = 640
  ClientWidth = 960
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 300
    Height = 640
    Align = alLeft
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 4
    Padding.Bottom = 8
    TabOrder = 0
    object gbSource: TGroupBox
      Left = 8
      Top = 8
      Width = 288
      Height = 150
      Align = alTop
      Caption = ' Source SVG images (0) '
      TabOrder = 0
      object btnAddFile: TButton
        Left = 12
        Top = 24
        Width = 126
        Height = 28
        Caption = 'Add single file...'
        TabOrder = 0
        OnClick = btnAddFileClick
      end
      object btnAddFiles: TButton
        Left = 146
        Top = 24
        Width = 126
        Height = 28
        Caption = 'Add list of files...'
        TabOrder = 1
        OnClick = btnAddFilesClick
      end
      object btnAddFolder: TButton
        Left = 12
        Top = 58
        Width = 126
        Height = 28
        Caption = 'Add folder...'
        TabOrder = 2
        OnClick = btnAddFolderClick
      end
      object chkSubFolders: TCheckBox
        Left = 148
        Top = 64
        Width = 124
        Height = 17
        Caption = 'Include sub-folders'
        TabOrder = 3
      end
      object btnRemove: TButton
        Left = 12
        Top = 100
        Width = 126
        Height = 28
        Caption = 'Remove selected'
        TabOrder = 4
        OnClick = btnRemoveClick
      end
      object btnClear: TButton
        Left = 146
        Top = 100
        Width = 126
        Height = 28
        Caption = 'Clear list'
        TabOrder = 5
        OnClick = btnClearClick
      end
    end
    object lbImages: TListBox
      Left = 8
      Top = 158
      Width = 288
      Height = 474
      Align = alClient
      ItemHeight = 15
      TabOrder = 1
      OnClick = lbImagesClick
    end
  end
  object pnlRight: TPanel
    Left = 300
    Top = 0
    Width = 660
    Height = 640
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 4
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    TabOrder = 1
    object gbPreview: TGroupBox
      Left = 4
      Top = 8
      Width = 648
      Height = 150
      Align = alTop
      Caption = ' Preview '
      TabOrder = 0
      object lblCaption: TLabel
        Left = 144
        Top = 28
        Width = 53
        Height = 15
        Caption = 'Caption: -'
      end
      object lblSize: TLabel
        Left = 144
        Top = 52
        Width = 31
        Height = 15
        Caption = 'Size: -'
      end
      object lblFile: TLabel
        Left = 144
        Top = 76
        Width = 29
        Height = 15
        Caption = 'File: -'
      end
      object pnlPreview: TPanel
        Left = 12
        Top = 22
        Width = 116
        Height = 116
        BevelKind = bkFlat
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object imgPreview: TPeakSVGImage
          Left = 0
          Top = 0
          Width = 112
          Height = 112
          Align = alClient
        end
      end
      object chkColoured: TCheckBox
        Left = 144
        Top = 108
        Width = 200
        Height = 17
        Caption = 'Coloured (keep SVG colours)'
        TabOrder = 1
        OnClick = chkColouredClick
      end
    end
    object gbExport: TGroupBox
      Left = 4
      Top = 158
      Width = 648
      Height = 118
      Align = alTop
      Caption = ' SVG to PNG / BMP / JPG / ICO '
      TabOrder = 1
      object lblOutput: TLabel
        Left = 12
        Top = 27
        Width = 75
        Height = 15
        Caption = 'Output folder:'
      end
      object lblFormat: TLabel
        Left = 12
        Top = 61
        Width = 41
        Height = 15
        Caption = 'Format:'
      end
      object lblPixels: TLabel
        Left = 190
        Top = 61
        Width = 46
        Height = 15
        Caption = 'Size (px):'
      end
      object edOutput: TEdit
        Left = 96
        Top = 24
        Width = 460
        Height = 23
        TabOrder = 0
      end
      object btnBrowse: TButton
        Left = 562
        Top = 22
        Width = 76
        Height = 27
        Caption = 'Browse...'
        TabOrder = 1
        OnClick = btnBrowseClick
      end
      object cbFormat: TComboBox
        Left = 60
        Top = 58
        Width = 110
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 2
        Text = 'PNG'
        Items.Strings = (
          'PNG'
          'BMP'
          'JPG'
          'ICO')
      end
      object seSize: TSpinEdit
        Left = 255
        Top = 58
        Width = 70
        Height = 24
        MaxValue = 1024
        MinValue = 16
        TabOrder = 3
        Value = 256
      end
      object btnExportSelected: TButton
        Left = 350
        Top = 56
        Width = 140
        Height = 28
        Caption = 'Convert selected'
        TabOrder = 4
        OnClick = btnExportSelectedClick
      end
      object btnExportAll: TButton
        Left = 498
        Top = 56
        Width = 140
        Height = 28
        Caption = 'Convert all in list'
        TabOrder = 5
        OnClick = btnExportAllClick
      end
    end
    object gbRaster: TGroupBox
      Left = 4
      Top = 276
      Width = 648
      Height = 118
      Align = alTop
      Caption = ' PNG / BMP / JPG to SVG and PNG to ICO '
      TabOrder = 2
      object lblMode: TLabel
        Left = 12
        Top = 27
        Width = 63
        Height = 15
        Caption = 'SVG output:'
      end
      object cbMode: TComboBox
        Left = 88
        Top = 24
        Width = 270
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 0
        Text = 'Trace to vector shapes'
        Items.Strings = (
          'Trace to vector shapes'
          'Embed as PNG image')
      end
      object chkRasterSub: TCheckBox
        Left = 380
        Top = 27
        Width = 250
        Height = 17
        Caption = 'Include sub-folders (folder conversion)'
        TabOrder = 1
      end
      object btnRasterFiles: TButton
        Left = 12
        Top = 62
        Width = 200
        Height = 28
        Caption = 'Image file(s) to SVG...'
        TabOrder = 2
        OnClick = btnRasterFilesClick
      end
      object btnRasterFolder: TButton
        Left = 220
        Top = 62
        Width = 200
        Height = 28
        Caption = 'Image folder to SVG...'
        TabOrder = 3
        OnClick = btnRasterFolderClick
      end
      object btnPngToIco: TButton
        Left = 428
        Top = 62
        Width = 210
        Height = 28
        Caption = 'PNG file(s) to ICO...'
        TabOrder = 4
        OnClick = btnPngToIcoClick
      end
    end
    object memLog: TMemo
      Left = 4
      Top = 394
      Width = 648
      Height = 238
      Align = alClient
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 3
    end
  end
  object ImageList: TPeakSVGImageList
    Left = 120
    Top = 240
  end
  object dlgSVGFile: TOpenDialog
    Filter = 'SVG files (*.svg)|*.svg|All files (*.*)|*.*'
    Title = 'Select an SVG file'
    Left = 120
    Top = 312
  end
  object dlgSVGFiles: TOpenDialog
    Filter = 'SVG files (*.svg)|*.svg|All files (*.*)|*.*'
    Options = [ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Select SVG files'
    Left = 120
    Top = 400
  end
  object dlgRasterFiles: TOpenDialog
    Filter = 'Images (*.png;*.bmp;*.jpg;*.jpeg)|*.png;*.bmp;*.jpg;*.jpeg'
    Options = [ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Select PNG, BMP or JPG files'
    Left = 128
    Top = 480
  end
  object dlgPngFiles: TOpenDialog
    Filter = 'PNG files (*.png)|*.png'
    Options = [ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Select PNG files'
    Left = 120
    Top = 552
  end
  object dlgFolder: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = [fdoPickFolders, fdoPathMustExist]
    Left = 32
    Top = 480
  end
end
