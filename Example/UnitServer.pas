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
  TfrmPipeTest = class(TForm)
    GroupBox1: TGroupBox;
    cbPipeServerAktiv: TCheckBox;
    TimerClientcount: TTimer;
    lblclientcount: TLabel;
    Label2: TLabel;
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
  frmPipeTest: TfrmPipeTest;

implementation

{$R *.dfm}

// ==============================================================================

procedure TfrmPipeTest.FormCreate(Sender: TObject);
begin
  Caption := csPipeName;

  FPipeServer:= nil;
end;

procedure TfrmPipeTest.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // CanClose:= not cbPipeServerAktiv.Checked;
  FreeAndNil(FPipeServer);
  CanClose := true;
end;

// ==============================================================================

procedure TfrmPipeTest.cbPipeServerAktivClick(Sender: TObject);
begin
  if cbPipeServerAktiv.Checked then
  begin
    FPipeServer := TPipeServer.Create(csPipeName);
    FPipeServer.OnReceive := DoOnServerReceive;
    FPipeServer.Start;
  end
  else
  begin
    FreeAndNil(FPipeServer);
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
  if Assigned(FPipeServer) then
  begin
    lblclientcount.Caption := inttostr(FPipeServer.ClientCount);
  end;
end;

// ==============================================================================

end.
