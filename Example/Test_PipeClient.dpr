program Test_PipeClient;

uses
  Vcl.Forms,
  UnitClient in 'UnitClient.pas' {frmPipeTest},
  pipeclient_unit in '..\pipeclient_unit.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown:= True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPipeTest, frmPipeTest);
  Application.Run;
end.
