object frmPipeTest: TfrmPipeTest
  Left = 0
  Top = 0
  Caption = 'frmPipeTest'
  ClientHeight = 602
  ClientWidth = 927
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 305
    Height = 497
    Caption = 'Server'
    TabOrder = 0
    object lblclientcount: TLabel
      Left = 16
      Top = 64
      Width = 62
      Height = 13
      Caption = 'lblclientcount'
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
  end
  object GroupBox2: TGroupBox
    Left = 328
    Top = 8
    Width = 305
    Height = 497
    Caption = 'Client'
    TabOrder = 1
    object btnClientStart: TButton
      Left = 16
      Top = 24
      Width = 75
      Height = 25
      Caption = 'starten'
      TabOrder = 0
      OnClick = btnClientStartClick
    end
    object ListBoxReceived: TListBox
      Left = 16
      Top = 144
      Width = 265
      Height = 337
      ItemHeight = 13
      TabOrder = 1
    end
    object btnClientSenden: TButton
      Left = 16
      Top = 55
      Width = 75
      Height = 25
      Caption = 'Senden'
      TabOrder = 2
      OnClick = btnClientSendenClick
    end
    object btnClientStop: TButton
      Left = 16
      Top = 88
      Width = 75
      Height = 25
      Caption = 'stoppen'
      TabOrder = 3
      OnClick = btnClientStopClick
    end
    object btnTest2: TButton
      Left = 120
      Top = 55
      Width = 75
      Height = 25
      Caption = 'btnTest2'
      TabOrder = 4
      OnClick = btnTest2Click
    end
    object btnTest1: TButton
      Left = 120
      Top = 24
      Width = 75
      Height = 25
      Caption = 'btnTest1'
      TabOrder = 5
      OnClick = btnTest1Click
    end
  end
  object TimerClientcount: TTimer
    Interval = 100
    OnTimer = TimerClientcountTimer
    Left = 24
    Top = 104
  end
end
