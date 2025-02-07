program Test_PipeClient;

uses
  Vcl.Forms,
  UnitClient in 'UnitClient.pas' {frmPipeTestClient},
  pipeclient_unit in '..\pipeclient_unit.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown:= True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPipeTestClient, frmPipeTestClient);
  Application.Run;
end.
