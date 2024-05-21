object FrmMainMenu: TFrmMainMenu
  AlignWithMargins = True
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsNone
  Caption = 'WebSocket Samples'
  ClientHeight = 600
  ClientWidth = 800
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 40
    Width = 800
    Height = 105
    Align = alTop
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      800
      105)
    object lblServer: TLabel
      Left = 7
      Top = 6
      Width = 32
      Height = 13
      Caption = 'Server'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 7947776
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 7
      Top = 52
      Width = 46
      Height = 13
      Caption = 'Message'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 7947776
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtServer: TEdit
      Left = 7
      Top = 25
      Width = 620
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = 'ws://localhost:8080'
    end
    object btnDisconnect: TButton
      Left = 714
      Top = 23
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Disconnect'
      TabOrder = 2
      OnClick = btnDisconnectClick
    end
    object btnConnect: TButton
      Left = 633
      Top = 23
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Connect'
      TabOrder = 1
      OnClick = btnConnectClick
    end
    object btnSend: TButton
      Left = 633
      Top = 69
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Send'
      TabOrder = 4
      OnClick = btnSendClick
    end
    object edtText: TEdit
      Left = 7
      Top = 71
      Width = 620
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
    end
    object btnClear: TButton
      Left = 714
      Top = 69
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Clear'
      TabOrder = 5
      OnClick = btnClearClick
    end
  end
  object Panel7: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      800
      40)
    object imgHeader: TImage
      Left = 0
      Top = 0
      Width = 800
      Height = 40
      Align = alClient
      ExplicitLeft = 344
      ExplicitTop = -32
      ExplicitWidth = 105
      ExplicitHeight = 105
    end
    object imgClose: TImage
      Left = 759
      Top = 5
      Width = 30
      Height = 30
      Cursor = crHandPoint
      Anchors = [akTop, akRight]
      Center = True
      Proportional = True
      Transparent = True
      OnClick = imgCloseClick
    end
  end
  object ListBoxLog: TListBox
    AlignWithMargins = True
    Left = 7
    Top = 145
    Width = 786
    Height = 448
    Margins.Left = 7
    Margins.Top = 0
    Margins.Right = 7
    Margins.Bottom = 7
    Align = alClient
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 7947776
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ItemHeight = 17
    ParentFont = False
    TabOrder = 2
  end
end
