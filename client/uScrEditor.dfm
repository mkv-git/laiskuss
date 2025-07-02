object uScriptEditor: TuScriptEditor
  Left = 506
  Top = 227
  AutoScroll = False
  BorderStyle = bsSizeToolWin
  Caption = 'Script editor'
  ClientHeight = 540
  ClientWidth = 408
  Color = 15000804
  Constraints.MinWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object scrText: TMemo
    Left = 0
    Top = 0
    Width = 408
    Height = 510
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object script_editor_control_panel: TPanel
    Left = 0
    Top = 510
    Width = 408
    Height = 30
    Align = alBottom
    BevelInner = bvLowered
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      408
      30)
    object sendB: TButton
      Left = 223
      Top = 3
      Width = 100
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Send to telnet'
      TabOrder = 0
      OnClick = sendBClick
    end
    object scrAssCB: TCheckBox
      Left = 5
      Top = 5
      Width = 100
      Height = 22
      Anchors = [akLeft, akBottom]
      Caption = 'Script assistant'
      TabOrder = 1
    end
    object copyB: TButton
      Left = 143
      Top = 3
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Copy'
      TabOrder = 2
      OnClick = copyBClick
    end
    object cancelB: TButton
      Left = 328
      Top = 3
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Cancel'
      TabOrder = 3
      OnClick = cancelBClick
    end
  end
end
