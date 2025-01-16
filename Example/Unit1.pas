unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmPipeTest = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    cbPipeServerAktiv: TCheckBox;
    btnClientStart: TButton;
    ListBoxReceived: TListBox;
    btnClientSenden: TButton;
    btnClientStop: TButton;
    TimerClientcount: TTimer;
    lblclientcount: TLabel;
    GroupBox3: TGroupBox;
    btnTest1: TButton;
    btnTest2: TButton;
    Label2: TLabel;
    lblmessagecount: TLabel;
    Label3: TLabel;
    procedure cbPipeServerAktivClick(Sender: TObject);
    procedure btnClientStopClick(Sender: TObject);
    procedure btnClientSendenClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnClientStartClick(Sender: TObject);
    procedure TimerClientcountTimer(Sender: TObject);
    procedure btnTest1Click(Sender: TObject);
    procedure btnTest2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
    FClientMessageCount:integer;
    FClientReceived: string;
    procedure OutputReceived(Var aMsg: tMessage); message WM_USER + 1;
  private
    procedure DoOnServerReceive(Sender: TThread;
      ReceivedStream, SendStream: TMemoryStream);
    procedure DoOnClientReceive(Sender: TThread; ReceivedStream: TMemoryStream);
  public
    { Public-Deklarationen }
  end;

var
  frmPipeTest: TfrmPipeTest;

implementation

uses pipeserver_unit, pipeclient_unit;

{$R *.dfm}

const
  csPipeName: string = 'TestPipe';

var
  PipeServer: TPipeServer = nil;
  PipeClient: TPipeClient = nil;

  // ==============================================================================

procedure TfrmPipeTest.cbPipeServerAktivClick(Sender: TObject);
begin
  if cbPipeServerAktiv.Checked then
  begin
    PipeServer := TPipeServer.Create(csPipeName);
    PipeServer.OnReceive := DoOnServerReceive;
    PipeServer.Start;
  end
  else
  begin
    FreeAndNil(PipeServer);
  end;
end;

procedure TfrmPipeTest.DoOnServerReceive(Sender: TThread;
  ReceivedStream, SendStream: TMemoryStream);
begin
  // Datenevent des Servers, hier bin ich noch im Thread
  SendStream.CopyFrom(ReceivedStream, SendStream.Size); // Echo
end;

// ==============================================================================

procedure TfrmPipeTest.btnClientStartClick(Sender: TObject);
begin
  // Hier im Test nur ein Client, können aber auch mehrere sein
  if Assigned(PipeClient) then
  begin
    FreeAndNil(PipeClient);
  end;
  PipeClient := TPipeClient.Create(csPipeName);
  PipeClient.OnReceive := DoOnClientReceive;
  PipeClient.Start;
end;

procedure TfrmPipeTest.btnClientStopClick(Sender: TObject);
begin
  FreeAndNil(PipeClient);
end;

procedure TfrmPipeTest.OutputReceived(Var aMsg: tMessage);
begin
  inc(FClientMessageCount);
  lblmessagecount.Caption := inttostr(FClientMessageCount);
  ListBoxReceived.Items.Add(FClientReceived);
end;

procedure TfrmPipeTest.TimerClientcountTimer(Sender: TObject);
begin
  if Assigned(PipeServer) then
  begin
    lblclientcount.Caption := inttostr(PipeServer.ClientCount);
  end;
end;

procedure TfrmPipeTest.btnClientSendenClick(Sender: TObject);
var
  s: AnsiString;
  SendStream: TMemoryStream;
  i: Integer;
begin
  if not Assigned(PipeClient) then
    exit;

  for i := 1 to 5 do begin
    // hier könnte ein beliebiger Memorystream gesendet werden
    // für den Test einfach ein nullterminierter String, könnte aber auch ein Binary file sein
    // Wenn sich die Pipe im Messagemode befindet, werden diese Messages einzeln vom Pipeserver empfangen und verarbeitet
    SendStream := TMemoryStream.Create;
    try
      s := 'Das ist ein Test ' + AnsiString(inttostr(random(100))) + #0;
      SendStream.Write(s[Low(s)], length(s));
      PipeClient.SendStream(SendStream);
    finally
      FreeAndNil(SendStream);
    end;
  end;

end;

procedure TfrmPipeTest.btnTest1Click(Sender: TObject);
var
  LPipeClient: TPipeClient;
  Stream: TMemoryStream;
begin
  LPipeClient := TPipeClient.Create(csPipeName);
  LPipeClient.OnReceive := DoOnClientReceive;
  LPipeClient.Start;

  Stream := TMemoryStream.Create;
  Stream.Write(AnsiString('Test'), 4);
  LPipeClient.SendStream(Stream);
  FreeAndNil(Stream);

  showmessage('warte'); // damit der PipeClient auch die Möglichkeit hat was zu empfangen bevor er aufgelöst wird
  FreeAndNil(LPipeClient);
end;

procedure TfrmPipeTest.btnTest2Click(Sender: TObject);
var
  LPipeClient: TPipeClient;
  Stream: TMemoryStream;
begin
  LPipeClient := TPipeClient.Create(csPipeName);
  LPipeClient.OnReceive := DoOnClientReceive;
  LPipeClient.Start;
  Stream := TMemoryStream.Create;
  Stream.LoadFromFile('..\..\Test.XML');
  Stream.Seek(0, soFromBeginning);
  LPipeClient.SendStream(Stream);
  FreeAndNil(Stream);
  showmessage('warte'); // damit der PipeClient auch die Möglichkeit hat was zu empfangen bevor er aufgelöst wird
  FreeAndNil(LPipeClient);
end;


procedure TfrmPipeTest.DoOnClientReceive(Sender: TThread;
  ReceivedStream: TMemoryStream);
var
  s: AnsiString;
begin
  // Datenevent des Cleints, hier bin ich noch im Thread

  // hier könnte ein beliebiger Memorystream empfangen werden
  // für den Test einfach ein nullterminierter String, könnte aber auch ein Binary file sein
  SetLength(s, ReceivedStream.Size);
  ReceivedStream.Read(s[Low(s)], ReceivedStream.Size);

  // Ausgabe im MainThread (hier quick and dirty, nicht threadsave, hier üsse die nachricht in eine lokale queue gelegt oder sofort verarbeitet werden)
  FClientReceived := string(s);
  PostMessage(handle, WM_USER + 1, 0, 0);
end;

// ==============================================================================

procedure TfrmPipeTest.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // CanClose:= not cbPipeServerAktiv.Checked;
  CanClose := true;
end;

procedure TfrmPipeTest.FormCreate(Sender: TObject);
begin
  FClientMessageCount:= 0;
  FClientReceived:= '';
end;

initialization

finalization

FreeAndNil(PipeServer);
FreeAndNil(PipeClient);

end.
