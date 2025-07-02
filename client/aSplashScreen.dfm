object aSplash: TaSplash
  Left = 476
  Top = 472
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 95
  ClientWidth = 310
  Color = 15000804
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 310
    Height = 95
    Align = alClient
    BevelInner = bvSpace
    BevelOuter = bvLowered
    ParentColor = True
    TabOrder = 0
    object splashLabel: TLabel
      Left = 8
      Top = 20
      Width = 289
      Height = 21
      Alignment = taCenter
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      Layout = tlCenter
    end
    object splashButton: TButton
      Left = 102
      Top = 55
      Width = 100
      Height = 25
      TabOrder = 0
      Visible = False
      OnClick = splashButtonClick
    end
  end
end
