object LoginForm: TLoginForm
  Left = 561
  Top = 387
  BorderStyle = bsToolWindow
  Caption = ' telnet.estpak.ee'
  ClientHeight = 115
  ClientWidth = 210
  Color = 15129296
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object username_label: TLabel
    Left = 15
    Top = 15
    Width = 60
    Height = 21
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Username:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object password_label: TLabel
    Left = 15
    Top = 45
    Width = 60
    Height = 21
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Password:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object username_edit: TEdit
    Left = 80
    Top = 15
    Width = 105
    Height = 21
    TabOrder = 0
  end
  object password_edit: TEdit
    Left = 80
    Top = 45
    Width = 105
    Height = 21
    PasswordChar = '*'
    TabOrder = 1
    OnKeyPress = password_editKeyPress
  end
  object login_button: TButton
    Left = 67
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Login'
    TabOrder = 2
    OnClick = login_buttonClick
  end
end
