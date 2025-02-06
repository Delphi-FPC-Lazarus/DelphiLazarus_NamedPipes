unit UnitServer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmPipeTest = class(TForm)
    GroupBox1: TGroupBox;
    cbPipeServerAktiv: TCheckBox;
    TimerClientcount: TTimer;
    lblclientcount: TLabel;
    Label2: TLabel;
    procedure cbPipeServerAktivClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TimerClientcountTimer(Sender: TObject);
  private
    { Private-Deklarationen }
  private
    procedure DoOnServerReceive(Sender: TThread;
      ReceivedStream, SendStream: TMemoryStream);
  public
    { Public-Deklarationen }
  end;

var
  frmPipeTest: TfrmPipeTest;

implementation

uses pipeserver_unit;

{$R *.dfm}

const
  csPipeName: string = 'TestPipe';

var
  PipeServer: TPipeServer = nil;

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
  // Datenevent des Servers
  // ACHTUNG: hier bin ich noch im Thread, daher kann hier nicht unsynchronisiert auf die UI zugegriffen werden
  // Hier im Testprogramm, einfach Echo
  SendStream.CopyFrom(ReceivedStream, SendStream.Size);
end;

// ==============================================================================

procedure TfrmPipeTest.TimerClientcountTimer(Sender: TObject);
begin
  if Assigned(PipeServer) then
  begin
    lblclientcount.Caption := inttostr(PipeServer.ClientCount);
  end;
end;

// ==============================================================================

procedure TfrmPipeTest.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // CanClose:= not cbPipeServerAktiv.Checked;
  CanClose := true;
end;

initialization

finalization

FreeAndNil(PipeServer);

end.
