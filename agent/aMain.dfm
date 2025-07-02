object aHost: TaHost
  Left = 569
  Top = 332
  BorderStyle = bsToolWindow
  ClientHeight = 492
  ClientWidth = 705
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 0
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
  end
  object Memo1: TMemo
    Left = 112
    Top = 8
    Width = 569
    Height = 193
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Memo2: TMemo
    Left = 112
    Top = 216
    Width = 569
    Height = 257
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object tiPM: TPopupMenu
    Left = 8
    Top = 8
    object pmTools: TMenuItem
      Caption = 'Tools'
      object pmTlOptions: TMenuItem
        Caption = 'Options'
        OnClick = pmTlOptionsClick
      end
      object pmTlScripts: TMenuItem
        Caption = 'Scripts'
        OnClick = pmTlScriptsClick
      end
      object pmTlIpTools: TMenuItem
        Caption = 'IP Tools'
        Enabled = False
        OnClick = pmTlIpToolsClick
      end
    end
    object pmUpdates: TMenuItem
      Caption = 'Check for updates'
      OnClick = pmUpdatesClick
    end
    object pmAbout: TMenuItem
      Caption = 'About'
      OnClick = pmAboutClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object pmClose: TMenuItem
      Caption = 'Exit'
      OnClick = pmCloseClick
    end
  end
  object aHttp: TIdHTTP
    AuthRetries = 0
    AuthProxyRetries = 0
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentRangeInstanceLength = 0
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 8
    Top = 48
  end
  object aTcpc: TIdTCPClient
    ConnectTimeout = 0
    IPVersion = Id_IPv4
    Port = 0
    ReadTimeout = -1
    Left = 8
    Top = 88
  end
  object syncTimer: TTimer
    Interval = 10800000
    OnTimer = syncTimerTimer
    Left = 8
    Top = 128
  end
end
