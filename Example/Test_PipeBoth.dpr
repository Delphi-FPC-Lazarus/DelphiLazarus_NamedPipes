program Test_PipeBoth;

uses
  Vcl.Forms,
  UnitClient in 'UnitClient.pas' {frmPipeTestClient},
  UnitServer in 'UnitServer.pas' {frmPipeTestServer},
  pipeserver_unit in '..\pipeserver_unit.pas',
  pipeclient_unit in '..\pipeclient_unit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPipeTestClient, frmPipeTestClient);
  Application.CreateForm(TfrmPipeTestServer, frmPipeTestServer);

  frmPipeTestServer.Top:= 100;
  frmPipeTestServer.Left:= 50;
  frmPipeTestClient.Top:= 300;
  frmPipeTestClient.Left:= 50;

  frmPipeTestServer.Visible:= true;
  frmPipeTestClient.Visible:= true;

  Application.Run;
end.
