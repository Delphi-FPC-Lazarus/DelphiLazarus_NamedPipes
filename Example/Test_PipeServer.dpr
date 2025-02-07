program Test_PipeServer;

uses
  Vcl.Forms,
  UnitServer in 'UnitServer.pas' {frmPipeTestServer},
  pipeserver_unit in '..\pipeserver_unit.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown:= True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPipeTestServer, frmPipeTestServer);
  Application.Run;
end.
