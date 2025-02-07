unit UnitServer;

interface

uses
  pipeserver_unit,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

const
  csPipeName: string = 'TestPipe';

type
  TfrmPipeTestServer = class(TForm)
    GroupBox1: TGroupBox;
    cbPipeServerAktiv: TCheckBox;
    TimerClientcount: TTimer;
    lblclientcount: TLabel;
    Label2: TLabel;
    rgPipeMode: TRadioGroup;
    procedure cbPipeServerAktivClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TimerClientcountTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
    FPipeServer: TPipeServer;
  private
    procedure DoOnServerReceive(Sender: TThread;
      ReceivedStream, SendStream: TMemoryStream);
  public
    { Public-Deklarationen }
  end;

var
  frmPipeTestServer: TfrmPipeTestServer;

implementation

{$R *.dfm}
// ==============================================================================

procedure TfrmPipeTestServer.FormCreate(Sender: TObject);
begin
  Caption := csPipeName;

  FPipeServer := nil;
end;

procedure TfrmPipeTestServer.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  // CanClose:= not cbPipeServerAktiv.Checked;
  if assigned(FPipeServer) then
  begin
    FPipeServer.Terminate;
    Sleep(1000);
    FreeAndNil(FPipeServer);
  end;
  CanClose := true;
end;

// ==============================================================================

procedure TfrmPipeTestServer.cbPipeServerAktivClick(Sender: TObject);
begin
  if cbPipeServerAktiv.Checked then
  begin
    rgPipeMode.Enabled:= False;
    case rgPipeMode.ItemIndex of
      0: FPipeServer := TPipeServer.Create(csPipeName, pipeModeByte);
      1: FPipeServer := TPipeServer.Create(csPipeName, pipeModeMessage);
    end;
    FPipeServer.OnReceive := DoOnServerReceive;
    FPipeServer.Start;
  end
  else
  begin
    rgPipeMode.Enabled:= true;
    FreeAndNil(FPipeServer);
  end;
end;

procedure TfrmPipeTestServer.DoOnServerReceive(Sender: TThread;
  ReceivedStream, SendStream: TMemoryStream);
(* Debug var s:AnsiString; *)
begin
  // Datenevent des Servers
  // ACHTUNG: hier bin ich noch im Thread, daher kann hier nicht unsynchronisiert auf die UI zugegriffen werden
  // Hier im Testprogramm, einfach Echo
  SendStream.CopyFrom(ReceivedStream, SendStream.Size);

  (* Debug
    SendStream.Position:= 0;
    SetLength(s, SendStream.Size);
    SendStream.Read(s[Low(s)], SendStream.Size);
    SendStream.Position:= 0;
  *)
end;

// ==============================================================================

procedure TfrmPipeTestServer.TimerClientcountTimer(Sender: TObject);
begin
  if assigned(FPipeServer) then
  begin
    lblclientcount.Caption := inttostr(FPipeServer.ClientCount);
  end;
end;

// ==============================================================================

end.
