object frmPipeTestClient: TfrmPipeTestClient
  Left = 0
  Top = 0
  Caption = 'TestPipeClient'
  ClientHeight = 344
  ClientWidth = 539
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
  object lblmessagecount: TLabel
    Left = 79
    Top = 325
    Width = 11
    Height = 13
    Caption = '- -'
  end
  object Label3: TLabel
    Left = 8
    Top = 325
    Width = 47
    Height = 13
    Caption = 'Messages'
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 0
    Width = 539
    Height = 321
    Align = alTop
    Caption = 'Client'
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 21
      Width = 260
      Height = 80
      AutoSize = False
      Caption = 
        'Testsender mit aynchonem Empfang um den Unterschied zwischen Byt' +
        'e und Message Modus zu zeigen.'
      WordWrap = True
    end
    object Label2: TLabel
      Left = 303
      Top = 21
      Width = 219
      Height = 80
      AutoSize = False
      Caption = 
        'Testsender Threads mit die je 100x abwechselnd Senden und Empfan' +
        'gen. Mit fest definiertem Protokoll in w'#228're dies in Byte sowie a' +
        'us Message Modus verwendbar.'
      WordWrap = True
    end
    object btnClientErzeugen: TButton
      Left = 3
      Top = 107
      Width = 75
      Height = 25
      Caption = 'erzeugen'
      TabOrder = 0
      OnClick = btnClientErzeugenClick
    end
    object ListBoxReceived: TListBox
      Left = 2
      Top = 200
      Width = 535
      Height = 119
      Align = alBottom
      ItemHeight = 13
      TabOrder = 1
    end
    object btnClientSenden: TButton
      Left = 3
      Top = 138
      Width = 75
      Height = 25
      Caption = 'Senden'
      TabOrder = 2
      OnClick = btnClientSendenClick
    end
    object btnClientFreigeben: TButton
      Left = 3
      Top = 169
      Width = 75
      Height = 25
      Caption = 'freigeben'
      TabOrder = 3
      OnClick = btnClientFreigebenClick
    end
    object RadioGroupSendeDaten: TRadioGroup
      Left = 84
      Top = 107
      Width = 184
      Height = 87
      ItemIndex = 0
      Items.Strings = (
        'Text'
        'Test_Pipe_Client_Payload.txt')
      TabOrder = 4
    end
    object btnThreaded: TButton
      Left = 303
      Top = 107
      Width = 92
      Height = 25
      Caption = 'MultiThreaded'
      TabOrder = 5
      OnClick = btnThreadedClick
    end
    object edThreadCount: TSpinEdit
      Left = 401
      Top = 109
      Width = 121
      Height = 22
      MaxValue = 99
      MinValue = 1
      TabOrder = 6
      Value = 5
    end
  end
  object cbDumpRecivedMessages: TCheckBox
    Left = 337
    Top = 325
    Width = 194
    Height = 17
    Caption = 'Empfangene Nachrichten speichern'
    TabOrder = 1
  end
end
