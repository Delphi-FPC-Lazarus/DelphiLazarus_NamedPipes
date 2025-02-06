unit UnitClient;

interface

uses
  pipeclient_unit,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Samples.Spin;

const
  WM_OUTPUTRECEIVED = WM_USER + 1309;
  csPipeName: string = 'TestPipe';

type
  TfrmPipeTest = class(TForm)
    GroupBox2: TGroupBox;
    btnClientErzeugen: TButton;
    ListBoxReceived: TListBox;
    btnClientSenden: TButton;
    btnClientFreigeben: TButton;
    lblmessagecount: TLabel;
    RadioGroupSendeDaten: TRadioGroup;
    Label3: TLabel;
    btnThreaded: TButton;
    edThreadCount: TSpinEdit;
    procedure btnClientFreigebenClick(Sender: TObject);
    procedure btnClientSendenClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnClientErzeugenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnThreadedClick(Sender: TObject);
  private
    { Private-Deklarationen }
    FPipeClient: TPipeClient;
    FClientMessageCount: integer;
    procedure DoOnClientReceive(Sender: TThread; ReceivedStream: TMemoryStream);
  private
    procedure OutputReceived(Var aMsg: tMessage); message WM_OUTPUTRECEIVED;
  public
    { Public-Deklarationen }
  end;

var
  frmPipeTest: TfrmPipeTest;

implementation

{$R *.dfm}
// ==============================================================================

procedure TfrmPipeTest.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // CanClose:= not cbPipeServerAktiv.Checked;
  FreeAndNil(FPipeClient);
  CanClose := true;
end;

procedure TfrmPipeTest.FormCreate(Sender: TObject);
begin
  Caption:= csPipeName;

  FPipeClient := nil;
  FClientMessageCount := 0;
end;

// ==============================================================================

procedure TfrmPipeTest.btnClientErzeugenClick(Sender: TObject);
begin
  // Hier im Test nur ein Client, können aber auch mehrere sein
  if Assigned(FPipeClient) then
  begin
    FreeAndNil(FPipeClient);
  end;
  FPipeClient := TPipeClient.Create(csPipeName);
  FPipeClient.OnReceive := DoOnClientReceive;
  FPipeClient.Start;
end;

procedure TfrmPipeTest.btnClientFreigebenClick(Sender: TObject);
begin
  FreeAndNil(FPipeClient);
end;

procedure TfrmPipeTest.btnClientSendenClick(Sender: TObject);
var
  s: AnsiString;
  SendStream: TMemoryStream;
  i: integer;
begin
  if not Assigned(FPipeClient) then
    exit;

  for i := 1 to 5 do
  begin
    // hier könnte ein beliebiger Memorystream gesendet werden
    // für den Test einfach ein nullterminierter String, könnte aber auch ein Binary file sein
    // Wenn sich die Pipe im Messagemode befindet, werden diese Messages einzeln vom Pipeserver empfangen und verarbeitet
    SendStream := TMemoryStream.Create;
    try
      // für den Test einfach ein nullterminierter String, oder Payload aus einer Datei
      case RadioGroupSendeDaten.ItemIndex of
        0:
          begin
            s := 'Das ist ein Test ' + AnsiString(inttostr(i)) + #0;
            SendStream.Write(s[Low(s)], length(s));
          end;
        1:
          begin
            SendStream.LoadFromFile('Test_Pipe_Client_Payload.txt');
            SendStream.Seek(0, soFromBeginning);
          end;
      end;
      FPipeClient.SendStream(SendStream);
    finally
      FreeAndNil(SendStream);
    end;
  end;
end;

procedure TfrmPipeTest.DoOnClientReceive(Sender: TThread;
  ReceivedStream: TMemoryStream);
var
  DataStream: TMemoryStream;
begin
  // Datenevent des Cleints, hier bin ich noch im Thread
  // ACHTUNG: hier bin ich noch im Thread, daher kann hier nicht unsynchronisiert auf die UI zugegriffen werden
  // Hier im Testprogramm Übergabe an den Mainthread für die Ausgabe
  ReceivedStream.Position := 0;
  DataStream := TMemoryStream.Create;
  DataStream.LoadFromStream(ReceivedStream);
  DataStream.Position := 0;
  PostMessage(handle, WM_OUTPUTRECEIVED, 0, LParam(DataStream));
end;

procedure TfrmPipeTest.OutputReceived(Var aMsg: tMessage);
var
  DataStream: TMemoryStream;
  s: AnsiString;
begin
  inc(FClientMessageCount);
  lblmessagecount.Caption := inttostr(FClientMessageCount);

  // hier könnte ein beliebiger Memorystream empfangen werden, ich geb ihn einfach als text aus
  DataStream := TMemoryStream(aMsg.LParam);
  if Assigned(DataStream) then
  begin
    SetLength(s, DataStream.Size);
    DataStream.Read(s[Low(s)], DataStream.Size);
    FreeAndNil(DataStream);
    ListBoxReceived.Items.Add(String(s));
  end;
end;

// ==============================================================================

type
  TTestThread = Class(TThread)
  public
    procedure Execute; override;
  End;

procedure TTestThread.Execute;
var
  i: integer;
  Client: TPipeClientSimple;
  s: AnsiString;
  DataStream: TMemoryStream;
begin
  FreeOnTerminate := true;

  Client := TPipeClientSimple.Create(csPipeName);
  try
    for i := 1 to 100 do
    begin
      // Senden
      DataStream := TMemoryStream.Create;
      try
        s := AnsiString(format('Test %d aus Thread %d', [i, self.ThreadID]));
        DataStream.Write(s[Low(s)], length(s));
        Client.SendStream(DataStream);
      finally
        FreeAndNil(DataStream);
      end;

      // Empfangen
      repeat
        DataStream := Client.ReceiveStream;
      until Assigned(DataStream);
      // Quick & dirty ausgeben
      PostMessage(application.MainForm.handle, WM_OUTPUTRECEIVED, 0,
        LParam(DataStream));
    end;
  finally
    FreeAndNil(Client);
  end;

end;

procedure TfrmPipeTest.btnThreadedClick(Sender: TObject);
var
  i: integer;
begin
  for i := 1 to edThreadCount.Value do
  begin
    // Quick & dirty Fire & Forget
    TTestThread.Create;
  end;
end;

// ==============================================================================

end.
