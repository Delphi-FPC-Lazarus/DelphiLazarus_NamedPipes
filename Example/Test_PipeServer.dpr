program Test_PipeServer;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {frmPipeTest},
  pipeserver_unit in '..\pipeserver_unit.pas',
  pipeclient_unit in '..\pipeclient_unit.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown:= True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPipeTest, frmPipeTest);
  Application.Run;
end.
