object frmPipeTest: TfrmPipeTest
  Left = 0
  Top = 0
  Caption = 'TestPipeClient'
  ClientHeight = 538
  ClientWidth = 614
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
  object GroupBox2: TGroupBox
    Left = 0
    Top = 0
    Width = 614
    Height = 289
    Align = alTop
    Caption = 'Client'
    TabOrder = 0
    object lblmessagecount: TLabel
      Left = 522
      Top = 101
      Width = 79
      Height = 13
      Caption = 'lblmessagecount'
    end
    object Label3: TLabel
      Left = 451
      Top = 101
      Width = 47
      Height = 13
      Caption = 'Messages'
    end
    object btnClientErzeugen: TButton
      Left = 16
      Top = 24
      Width = 75
      Height = 25
      Caption = 'erzeugen'
      TabOrder = 0
      OnClick = btnClientErzeugenClick
    end
    object ListBoxReceived: TListBox
      Left = 2
      Top = 120
      Width = 610
      Height = 167
      Align = alBottom
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
    object btnClientFreigeben: TButton
      Left = 16
      Top = 89
      Width = 75
      Height = 25
      Caption = 'freigeben'
      TabOrder = 3
      OnClick = btnClientFreigebenClick
    end
    object RadioGroupSendeDaten: TRadioGroup
      Left = 97
      Top = 24
      Width = 184
      Height = 90
      ItemIndex = 0
      Items.Strings = (
        'Text'
        'Test_Pipe_Client_Payload.txt')
      TabOrder = 4
    end
    object btnThreaded: TButton
      Left = 296
      Top = 24
      Width = 75
      Height = 25
      Caption = 'btnThreaded'
      TabOrder = 5
      OnClick = btnThreadedClick
    end
    object edThreadCount: TSpinEdit
      Left = 377
      Top = 26
      Width = 121
      Height = 22
      MaxValue = 99
      MinValue = 1
      TabOrder = 6
      Value = 5
    end
  end
end
