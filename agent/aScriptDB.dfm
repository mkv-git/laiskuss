object aScrKog: TaScrKog
  Left = 368
  Top = 249
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Scripts'
  ClientHeight = 473
  ClientWidth = 692
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
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object main_tpg: TPageControl
    Left = 0
    Top = 0
    Width = 692
    Height = 473
    ActivePage = konf_pg
    Align = alClient
    TabOrder = 0
    object sect_pg: TTabSheet
      Caption = 'Sectors && Sync'
      OnShow = sect_pgShow
      object bgPan1: TPanel
        Left = 0
        Top = 0
        Width = 684
        Height = 445
        Align = alClient
        BevelInner = bvLowered
        BorderWidth = 2
        Color = 15000804
        Ctl3D = True
        ParentCtl3D = False
        TabOrder = 0
        object sectGB: TGroupBox
          Left = 6
          Top = 8
          Width = 290
          Height = 225
          Align = alCustom
          Caption = 'Sector list'
          Color = 15000804
          ParentColor = False
          TabOrder = 0
          object sec_stat: TLabel
            Left = 16
            Top = 200
            Width = 260
            Height = 21
            AutoSize = False
          end
          object sec_list: TListBox
            Left = 16
            Top = 48
            Width = 153
            Height = 145
            Style = lbOwnerDrawFixed
            DragMode = dmAutomatic
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ItemHeight = 15
            ParentFont = False
            TabOrder = 0
            OnClick = sec_listClick
            OnDragDrop = sec_listDragDrop
            OnDragOver = sec_listDragOver
            OnMouseDown = sec_listMouseDown
          end
          object sec_name: TEdit
            Left = 16
            Top = 24
            Width = 153
            Height = 21
            MaxLength = 20
            TabOrder = 1
          end
          object sec_width: TEdit
            Left = 168
            Top = 24
            Width = 33
            Height = 21
            MaxLength = 1
            TabOrder = 2
            Text = '1'
            OnKeyPress = sec_widthKeyPress
          end
          object sec_addB: TButton
            Left = 176
            Top = 48
            Width = 100
            Height = 25
            Caption = 'Add'
            TabOrder = 3
            OnClick = sec_addBClick
          end
          object sec_setB: TButton
            Left = 176
            Top = 80
            Width = 100
            Height = 25
            Caption = 'Change'
            Enabled = False
            TabOrder = 4
            OnClick = sec_setBClick
          end
          object sec_delB: TButton
            Left = 176
            Top = 112
            Width = 100
            Height = 25
            Caption = 'Delete'
            Enabled = False
            TabOrder = 5
            OnClick = sec_delBClick
          end
          object Button1: TButton
            Left = 184
            Top = 184
            Width = 75
            Height = 25
            Caption = 'Button1'
            TabOrder = 6
            Visible = False
            OnClick = Button1Click
          end
        end
        object syncGB: TGroupBox
          Left = 6
          Top = 239
          Width = 674
          Height = 201
          Align = alCustom
          Caption = 'Sync'
          Color = 15000804
          ParentColor = False
          TabOrder = 1
          object syncLog: TMemo
            Left = 1
            Top = 96
            Width = 671
            Height = 105
            ScrollBars = ssVertical
            TabOrder = 0
          end
        end
        object memo1: TRichEdit
          Left = 296
          Top = 8
          Width = 385
          Height = 273
          ScrollBars = ssVertical
          TabOrder = 2
          Visible = False
        end
      end
    end
    object konf_pg: TTabSheet
      Caption = 'Scripts'
      ImageIndex = 1
      OnShow = konf_pgShow
      object bgPan2: TPanel
        Left = 0
        Top = 0
        Width = 684
        Height = 445
        Align = alClient
        BevelInner = bvLowered
        BorderWidth = 2
        Color = 15000804
        TabOrder = 0
      end
    end
    object macr_pg: TTabSheet
      Caption = 'Macros'
      ImageIndex = 2
      OnShow = macr_pgShow
      object mscr: TScrollBox
        Left = 0
        Top = 0
        Width = 684
        Height = 445
        HorzScrollBar.Visible = False
        VertScrollBar.ParentColor = False
        VertScrollBar.Smooth = True
        VertScrollBar.Style = ssFlat
        Align = alCustom
        Color = 15000804
        ParentColor = False
        TabOrder = 0
        OnMouseWheel = mscrMouseWheel
      end
    end
  end
  object test_field: TEdit
    Left = 456
    Top = 0
    Width = 233
    Height = 21
    TabOrder = 1
    Text = 'test_field'
    Visible = False
  end
  object test_field2: TEdit
    Left = 296
    Top = 0
    Width = 161
    Height = 21
    TabOrder = 2
    Text = 'test_field2'
    Visible = False
  end
end
