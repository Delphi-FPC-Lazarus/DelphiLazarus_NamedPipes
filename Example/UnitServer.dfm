object frmPipeTestServer: TfrmPipeTestServer
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'PipeTest Server'
  ClientHeight = 167
  ClientWidth = 363
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 347
    Height = 151
    Caption = 'Server (Echo)'
    TabOrder = 0
    object lblclientcount: TLabel
      Left = 90
      Top = 125
      Width = 62
      Height = 13
      Caption = 'lblclientcount'
    end
    object Label2: TLabel
      Left = 16
      Top = 124
      Width = 32
      Height = 13
      Caption = 'Clients'
    end
    object cbPipeServerAktiv: TCheckBox
      Left = 16
      Top = 28
      Width = 177
      Height = 17
      Caption = 'cbPipeServerAktiv'
      TabOrder = 0
      OnClick = cbPipeServerAktivClick
    end
    object rgPipeMode: TRadioGroup
      Left = 16
      Top = 56
      Width = 281
      Height = 49
      Caption = 'PipeModus'
      Columns = 2
      ItemIndex = 0
      Items.Strings = (
        'BYTE'
        'MESSAGE')
      TabOrder = 1
    end
  end
  object TimerClientcount: TTimer
    Interval = 100
    OnTimer = TimerClientcountTimer
    Left = 240
    Top = 48
  end
end
