unit UnitClient;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Samples.Spin;


const WM_OUTPUTRECEIVED = WM_USER + 1309;
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
    FClientMessageCount: integer;
    procedure OutputReceived(Var aMsg: tMessage); message WM_OUTPUTRECEIVED;
  private
    procedure DoOnClientReceive(Sender: TThread; ReceivedStream: TMemoryStream);
  public
    { Public-Deklarationen }
  end;

var
  frmPipeTest: TfrmPipeTest;

implementation

uses pipeclient_unit;

{$R *.dfm}

const
  csPipeName: string = 'TestPipe';

var
  PipeClient: TPipeClient = nil;

  // ==============================================================================

procedure TfrmPipeTest.btnClientErzeugenClick(Sender: TObject);
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

procedure TfrmPipeTest.btnClientFreigebenClick(Sender: TObject);
begin
  FreeAndNil(PipeClient);
end;

procedure TfrmPipeTest.btnClientSendenClick(Sender: TObject);
var
  s: AnsiString;
  SendStream: TMemoryStream;
  i: integer;
begin
  if not Assigned(PipeClient) then
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
      PipeClient.SendStream(SendStream);
    finally
      FreeAndNil(SendStream);
    end;
  end;
end;

procedure TfrmPipeTest.btnThreadedClick(Sender: TObject);
begin
  // Todo
end;

procedure TfrmPipeTest.DoOnClientReceive(Sender: TThread;
  ReceivedStream: TMemoryStream);
var DataStream:TMemoryStream;
begin
  // Datenevent des Cleints, hier bin ich noch im Thread
  // ACHTUNG: hier bin ich noch im Thread, daher kann hier nicht unsynchronisiert auf die UI zugegriffen werden
  // Hier im Testprogramm Übergabe an den Mainthread für die Ausgabe
  ReceivedStream.Position:= 0;
  DataStream:= TMemoryStream.Create;
  DataStream.LoadFromStream(ReceivedStream);
  DataStream.Position:= 0;
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
  DataStream:= TMemoryStream(aMsg.LParam);
  if Assigned(DataStream) then begin
    SetLength(s, DataStream.Size);
    DataStream.Read(s[Low(s)], DataStream.Size);
    FreeAndNil(DataStream);
    ListBoxReceived.Items.Add(String(s));
  end;
end;

// ==============================================================================

procedure TfrmPipeTest.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // CanClose:= not cbPipeServerAktiv.Checked;
  CanClose := true;
end;

procedure TfrmPipeTest.FormCreate(Sender: TObject);
begin
  FClientMessageCount := 0;
end;

initialization

finalization

FreeAndNil(PipeClient);

end.
