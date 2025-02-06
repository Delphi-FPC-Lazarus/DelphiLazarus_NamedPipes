{
  PipeServer im NonBlocking Modus ohne Events
  https://learn.microsoft.com/de-de/windows/win32/api/namedpipeapi/
  https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/

  Die Anzahl der Verbindungen ist unlimitiert, die Serverseitigen
  IOHandler werden sofort weggeräumt wenn der Client die Verbindung trennt,
  ansonsten beim Beenden des Servers.

  Der Code für das Datenhandling kann im OnReceive Event eingehängt werden.

  --------------------------------------------------------------------
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  THE SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY

  Last maintainer: Peter Lorenz
  You find the code useful? Donate!
  Paypal webmaster@peter-ebe.de
  --------------------------------------------------------------------

}

{$I ..\share_settings.inc}
unit pipeserver_unit;

interface

uses
  Classes, Windows, SysUtils, System.Generics.Collections, System.SyncObjs;

type
  TPipeServerDataEvent = procedure(Sender: TThread;
    ReceivedStream, SendStream: TMemoryStream) of object;

  TPipeServer = class(TThread)
  private
    FPipeName: string;
    FPipeServerDataEvent: TPipeServerDataEvent;
    FPipeServerIOHandlers: TObjectList<TThread>;
    FPipeServerIOHandlersLock: TCriticalSection;
    function GetClientCount: integer;
  private
    // Pipe
    function PipeServerCreateInstance: THandle;
    procedure PipeServerCloseInstance(PipeHandle: THandle);
  private
    // PipeIOHandler zur Kommunikation über die Pipe
    procedure PipeServerCreateIOHandler(PipeHandle: THandle);
    procedure PipeServeIOHandlerTermianted(Sender: TObject);
  protected
    procedure Execute; override;
  public
    constructor Create(PipeServerPipeName: string);

    property ClientCount: integer read GetClientCount;
    property PipeName: string read FPipeName;
    property OnReceive: TPipeServerDataEvent read FPipeServerDataEvent
      write FPipeServerDataEvent;
  end;

  TPipeServerIOHandler = class(TThread)
  private // durch friendly classes erreichbar
    FPipeServerDataEvent: TPipeServerDataEvent;
    FPipeHandleServer: THandle;
  protected
    procedure Execute; override;
  end;

resourcestring
  rsCouldNotCreateInterfacePipe =
    'Interface Pipe konnte nicht erzeugt werden, bitte schließen Sie alle Instanzen dieses Programmes und starten Sie es erneut';

implementation

// ================================================================

constructor TPipeServer.Create(PipeServerPipeName: string);
begin
  inherited Create(true);
  FPipeName := PipeServerPipeName;
  FPipeServerDataEvent := nil;

  // Start;
end;

function TPipeServer.GetClientCount: integer;
begin
  try
    FPipeServerIOHandlersLock.Enter;
    Result := FPipeServerIOHandlers.count
  finally
    FPipeServerIOHandlersLock.Leave;
  end;
end;

function TPipeServer.PipeServerCreateInstance: THandle;
(*var
  FSA: SECURITY_ATTRIBUTES;
  FSD: SECURITY_DESCRIPTOR;
*)
begin
  (*
    https://learn.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-initializesecuritydescriptor
    The InitializeSecurityDescriptor function initializes a new security descriptor.

    https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-setsecuritydescriptordacl
    The SetSecurityDescriptorDacl function sets information in a discretionary access control list (DACL).
    If a DACL is already present in the security descriptor, the DACL is replaced.
  *)
  (*
  InitializeSecurityDescriptor(@FSD, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@FSD, true, nil, False);
  FSA.lpSecurityDescriptor := @FSD;
  FSA.nLength := sizeof(SECURITY_ATTRIBUTES);
  FSA.bInheritHandle := true;
  *)

  (*
    https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createnamedpipea
    Creates an instance of a named pipe and returns a handle for subsequent pipe operations.
    A named pipe server process uses this function either to create the first instance of a specific named pipe
    and establish its basic attributes or to create a new instance of an existing named pipe.
  *)
  Result := CreateNamedPipe(PChar('\\.\pipe\' + FPipeName),
    PIPE_ACCESS_DUPLEX or // Lesen/Schreiben
    FILE_FLAG_WRITE_THROUGH, // nur für Netzwerk relevant
    PIPE_TYPE_MESSAGE or // jeder Schreibvorgang als MessageEinheit behandeln
    PIPE_READMODE_MESSAGE or // Lesen auch als MessageEinheit
    PIPE_NOWAIT, // nicht blocken
    PIPE_UNLIMITED_INSTANCES,
    // Pipe begrenzung abgeschaltet, 1 erlaubt nur eine paralle Instanz und würde ERROR_PIPE_BUSY liefern
    MAXDWORD, // Ausgangsbuffer vom Betriebssystem verwaltet
    MAXDWORD, // Eingangsbuffer vom Betriebssystem verwaltet
    10000, // Timeout
    Nil(*@FSA*)); // Attribute (Sicherheit, ob der Handle an einen Subprozess übergeben werden kann oder nicht)

  if Result = INVALID_HANDLE_VALUE then
    raise Exception.Create(rsCouldNotCreateInterfacePipe);
end;

procedure TPipeServer.PipeServerCloseInstance(PipeHandle: THandle);
begin
  if PipeHandle <> INVALID_HANDLE_VALUE then
  begin
    (*
      https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-disconnectnamedpipe
      Disconnects the server end of a named pipe instance from a client process.
    *)
    DisconnectNamedPipe(PipeHandle);
    (*
      https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle
      Closes an open object handle.
    *)
    CloseHandle(PipeHandle);
  end;
end;

procedure TPipeServer.PipeServerCreateIOHandler(PipeHandle: THandle);
var
  newPipeServerIOHandler: TPipeServerIOHandler;
begin
  if PipeHandle <> INVALID_HANDLE_VALUE then
  begin
    newPipeServerIOHandler := TPipeServerIOHandler.Create(true);
    newPipeServerIOHandler.FPipeHandleServer := PipeHandle;
    newPipeServerIOHandler.FPipeServerDataEvent := FPipeServerDataEvent;
    newPipeServerIOHandler.OnTerminate := PipeServeIOHandlerTermianted;
    newPipeServerIOHandler.Start;
    try
      FPipeServerIOHandlersLock.Enter;
      FPipeServerIOHandlers.Add(newPipeServerIOHandler);
    finally
      FPipeServerIOHandlersLock.Leave;
    end;
  end;
end;

procedure TPipeServer.PipeServeIOHandlerTermianted(Sender: TObject);
var
  i: integer;
begin
  if not(Sender is TPipeServerIOHandler) then
    exit;

  // aus der IO Handler Liste schmeißen
  try
    FPipeServerIOHandlersLock.Enter;
    i := FPipeServerIOHandlers.IndexOf(Sender as TPipeServerIOHandler);
    if i > -1 then
    begin
      FPipeServerIOHandlers.Delete(i);
    end;
  finally
    FPipeServerIOHandlersLock.Leave;
  end;

  // PipeIsntance im System schließen
  PipeServerCloseInstance((Sender as TPipeServerIOHandler).FPipeHandleServer);
end;

procedure TPipeServer.Execute;
var
  CurrentPendingPipeServerHandle: THandle;
  LERR: DWORD;
  i: integer;
begin
  // nicht eigenständig auflösen, darum kümmert sich der Ersteller
  FreeOnTerminate := False;

  // Organisationsliste IOHandler erstellen
  FPipeServerIOHandlersLock := TCriticalSection.Create;
  FPipeServerIOHandlers := TObjectList<TThread>.Create(False);
  // nicht eigentständig freigeben

  CurrentPendingPipeServerHandle := INVALID_HANDLE_VALUE;
  while not Terminated do
  begin
    // Neue Pipe Instanz aufbauen
    CurrentPendingPipeServerHandle := PipeServerCreateInstance;
    // LERR := GetLastError; ERROR_PIPE_BUSY möglich wenn Instanzen begrenzt, dann gibt es aber auch keine Handle
    if CurrentPendingPipeServerHandle <> INVALID_HANDLE_VALUE then
    begin
      // Auf Client warten
      while not Terminated do
      begin
        (*
          https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-connectnamedpipe
          Enables a named pipe server process to wait for a client process to connect to an instance of a named pipe.
          A client process connects by calling either the CreateFile or CallNamedPipe function.
        *)
        if ConnectNamedPipe(CurrentPendingPipeServerHandle, nil) then
        begin
        end;
        LERR := GetLastError;
        case LERR of
          ERROR_PIPE_LISTENING:
            begin
              // wartet noch auf Verbindung vom Client
            end;
          ERROR_PIPE_CONNECTED:
            begin
              // Client hat verbunden
              // Aktuellen Client Handle an eigenen Thread übergeben der sich um diesen client kümmert
              PipeServerCreateIOHandler(CurrentPendingPipeServerHandle);
              // hier vergesse ich diesen handle da dieser nun vom IO Handler abgehandelt wird
              CurrentPendingPipeServerHandle := INVALID_HANDLE_VALUE;
              // zurück zur übergeordneten threadschleife damit eine neue Instanz erzeugt wird
              break;
            end;
        end;
        sleep(1);
      end;
    end;
    sleep(1);
  end;

  // Aktuell wartende Pipe Instance schließen, damit kann auch keine neuer IOHandler mehr aufgebaut werden
  PipeServerCloseInstance(CurrentPendingPipeServerHandle);

  // IOHandler beenden die noch laufen
  try
    FPipeServerIOHandlersLock.Enter;
    for i := 0 to FPipeServerIOHandlers.count - 1 do
    begin
      FPipeServerIOHandlers.Items[i].Terminate;
    end;
  finally
    FPipeServerIOHandlersLock.Leave;
  end;

  // Warten bis alle IOHandler beenden sind, Liste nicht permanent sperren sonst komm ich nie raus
  While ClientCount > 0 do
  begin
    sleep(100);
  end;

  // Organisationsliste IOHandler auflösen
  FreeAndNil(FPipeServerIOHandlers);
  FreeAndNil(FPipeServerIOHandlersLock);
end;

// ================================================================

procedure TPipeServerIOHandler.Execute;
var
  LERR: DWORD;
  lpTotalBytesAvail, lpBytesLeftThisMessage: DWORD;
  dw: DWORD;
  rcv, snd: TMemoryStream;
begin
  // Eigenständig auflösen, OnTerminate wird vorher aufgerufen
  // was das nötige Handling im PipeServer auslöst
  FreeOnTerminate := true;

  LERR := 0;
  while (not Terminated) and (LERR <> ERROR_BROKEN_PIPE) do
  begin
    if FPipeHandleServer = INVALID_HANDLE_VALUE then
      break;

    (*
      https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-peeknamedpipe
      Copies data from a named or anonymous pipe into a buffer without removing it from the pipe. It also returns information about data in the pipe.
    *)
    if PeekNamedPipe(FPipeHandleServer, nil, 0, nil, @lpTotalBytesAvail,
      @lpBytesLeftThisMessage) then
    begin
      // lpTotalBytesAvail kann größer sein wenn mehr messages anstehen
      if (lpBytesLeftThisMessage > 0) then
      begin
        rcv := TMemoryStream.Create;
        snd := TMemoryStream.Create;
        try
          rcv.SetSize(lpBytesLeftThisMessage);
          (*
            https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile
            Reads data from the specified file or input/output (I/O) device. Reads occur at the position specified by the file pointer if supported by the device.
          *)
          if not ReadFile(FPipeHandleServer, rcv.Memory^,
            lpBytesLeftThisMessage, dw, nil) then
            raise Exception.Create('Read error');

          if Assigned(FPipeServerDataEvent) then
          begin
            FPipeServerDataEvent(Self, rcv, snd);
          end;

          (*
            https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile
            Writes data to the specified file or input/output (I/O) device.
          *)
          if snd.Size > 0 then
          begin
            if not WriteFile(FPipeHandleServer, snd.Memory^, snd.Size, dw, nil)
            then
              raise Exception.Create('Write error');
          end;
        finally
          FreeAndNil(rcv);
          FreeAndNil(snd);
        end;
      end;
    end;

    sleep(10);

    // wegen Abbruchprüfung immer den GetLastError prüfen (im Leerlauf durch PeekNamedPipe ausgelöst)
    LERR := GetLastError;
  end;
end;

// ================================================================

end.
