object FrmMainMenu: TFrmMainMenu
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'WebSocket Samples'
  ClientHeight = 561
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 784
    Height = 561
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Panel4: TPanel
      Left = 0
      Top = 65
      Width = 784
      Height = 25
      Align = alTop
      Alignment = taLeftJustify
      BevelOuter = bvNone
      Caption = '  Log'
      Color = 16091980
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
    end
    object DBGridLog: TDBGrid
      Left = 0
      Top = 90
      Width = 784
      Height = 471
      Align = alClient
      DataSource = dsServerLog
      GradientEndColor = 15658734
      GradientStartColor = 15658734
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Segoe UI'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'DATE'
          Title.Caption = 'Date'
          Width = 121
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'MESSAGE'
          Title.Caption = 'Message'
          Width = 625
          Visible = True
        end>
    end
    object Panel5: TPanel
      Left = 0
      Top = 0
      Width = 784
      Height = 65
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 2
      DesignSize = (
        784
        65)
      object Panel6: TPanel
        Left = 0
        Top = 0
        Width = 784
        Height = 25
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = '  Send'
        Color = 16091980
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
      end
      object btnSend: TButton
        Left = 698
        Top = 34
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Send'
        TabOrder = 1
        OnClick = btnSendClick
      end
      object edtText: TEdit
        Left = 10
        Top = 36
        Width = 682
        Height = 21
        Anchors = [akTop, akRight]
        TabOrder = 2
      end
    end
  end
  object mtServerLog: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 384
    Top = 288
    object mtServerLogID: TIntegerField
      AutoGenerateValue = arAutoInc
      FieldName = 'ID'
    end
    object mtServerLogMESSAGE: TStringField
      FieldName = 'MESSAGE'
      Size = 500
    end
    object mtServerLogDATE: TDateField
      FieldName = 'DATE'
    end
  end
  object dsServerLog: TDataSource
    AutoEdit = False
    DataSet = mtServerLog
    Left = 464
    Top = 288
  end
end
