{
  PipeClient
  https://learn.microsoft.com/de-de/windows/win32/api/namedpipeapi/
  https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/

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
unit pipeclient_unit;

interface

uses
  Classes, Windows, SysUtils, System.Generics.Collections, System.SyncObjs;

type
  TPipeClientDataEvent = procedure(Sender: TThread;
    ReceivedStream: TMemoryStream) of object;

  TPipeClient = class(TThread)
  private
    FPipeName: string;
    FPipeHandleClient: THandle;
    FbFinished: Boolean;
    FPipeClientDataEvent: TPipeClientDataEvent;
  private
    // Pipe
    procedure PipeClientCreateInstance;
    procedure PipeClientCloseInstance;
    procedure PipeClientCheckReceive;
  protected
    function GetTerminated: Boolean;
    procedure Execute; override;
  public
    constructor Create(PipeClientPipeName: string);
    destructor Destroy; override;

    procedure SendStream(SendStream: TMemoryStream);

    property PipeName: string read FPipeName;
    property OnReceive: TPipeClientDataEvent read FPipeClientDataEvent
      write FPipeClientDataEvent;
    property Terminated: Boolean read GetTerminated;
  end;

resourcestring
  rsCouldNotConnectInterfacePipe =
    'Interface Pipe konnte nicht verbunden werden, bitte überprüfen Sie ob die Serveranwendung gestartet wurde';

implementation

constructor TPipeClient.Create(PipeClientPipeName: string);
begin
  inherited Create(true);
  FPipeName := PipeClientPipeName;
  FbFinished := false;
  FPipeClientDataEvent := nil;

  // Pipe verbinden
  FPipeHandleClient := INVALID_HANDLE_VALUE;
  PipeClientCreateInstance;

  // Start;
end;

destructor TPipeClient.Destroy;
begin
  // Pipe Trennen
  PipeClientCloseInstance;

  inherited;
end;

procedure TPipeClient.PipeClientCreateInstance;
var
  FSA: SECURITY_ATTRIBUTES;
  FSD: SECURITY_DESCRIPTOR;
  LERR: Integer;

  I: Integer;
begin
  (*
    https://learn.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-initializesecuritydescriptor
    The InitializeSecurityDescriptor function initializes a new security descriptor.

    https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-setsecuritydescriptordacl
    The SetSecurityDescriptorDacl function sets information in a discretionary access control list (DACL).
    If a DACL is already present in the security descriptor, the DACL is replaced.
  *)
  InitializeSecurityDescriptor(@FSD, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@FSD, true, nil, false);
  FSA.lpSecurityDescriptor := @FSD;
  FSA.nLength := sizeof(SECURITY_ATTRIBUTES);
  FSA.bInheritHandle := true;

  I := 0;
  FPipeHandleClient := INVALID_HANDLE_VALUE;
  while (FPipeHandleClient = INVALID_HANDLE_VALUE) and (I < 10) do
  begin
    (*
      https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilea
      Creates or opens a file or I/O device.
      The most commonly used I/O devices are as follows: file, file stream, directory, physical disk, volume,
      console buffer, tape drive, communications resource, mailslot, and pipe.
      The function returns a handle that can be used to access the file or device for various types of I/O depending
      on the file or device and the flags and attributes specified.
    *)
    FPipeHandleClient := CreateFile(PChar('\\.\pipe\' + FPipeName),
      GENERIC_READ or GENERIC_WRITE, // Lesen/Schreiben
      0, // kein Sharing
      @FSA, // Attribute (Sicherheit)
      OPEN_EXISTING, // nur auf vorhandene Pipe verbinden
      0, // n.v.
      0); // n.v.

    LERR := GetLastError;
    case LERR of
      ERROR_PIPE_BUSY:
        begin
          inc(I);
          sleep(100);
        end;
    else
      I := MaxInt;
    end;
  end;

  if FPipeHandleClient = INVALID_HANDLE_VALUE then
    raise Exception.Create(rsCouldNotConnectInterfacePipe);
end;

procedure TPipeClient.PipeClientCloseInstance;
begin
  if FPipeHandleClient <> INVALID_HANDLE_VALUE then
  begin
    (*
      https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-disconnectnamedpipe
      Disconnects the server end of a named pipe instance from a client process.
    *)
    DisconnectNamedPipe(FPipeHandleClient);
    (*
      https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle
      Closes an open object handle.
    *)
    CloseHandle(FPipeHandleClient);

    FPipeHandleClient := INVALID_HANDLE_VALUE;
  end;
end;

procedure TPipeClient.PipeClientCheckReceive;
var
  lpTotalBytesAvail, lpBytesLeftThisMessage: DWORD;
  dw: DWORD;
  rcv: TMemoryStream;
begin
  (*
    https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-peeknamedpipe
    Copies data from a named or anonymous pipe into a buffer without removing it from the pipe. It also returns information about data in the pipe.
  *)
  if PeekNamedPipe(FPipeHandleClient, nil, 0, nil, @lpTotalBytesAvail,
    @lpBytesLeftThisMessage) then
  begin
    // lpTotalBytesAvail kann größer sein wenn mehr messages anstehen
    if (lpBytesLeftThisMessage > 0) then
    begin
      rcv := TMemoryStream.Create;
      try
        rcv.SetSize(lpBytesLeftThisMessage);
        (*
          https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile
          Reads data from the specified file or input/output (I/O) device. Reads occur at the position specified by the file pointer if supported by the device.
        *)
        ReadFile(FPipeHandleClient, rcv.Memory^,
          lpBytesLeftThisMessage, dw, nil);
        if Assigned(FPipeClientDataEvent) then
        begin
          FPipeClientDataEvent(self, rcv);
        end;
      finally
        FreeAndNil(rcv);
      end;
    end;
  end;
end;

procedure TPipeClient.SendStream(SendStream: TMemoryStream);
var
  dw: DWORD;
begin
  if FPipeHandleClient <> INVALID_HANDLE_VALUE then
  begin
    (*
      https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile
      Writes data to the specified file or input/output (I/O) device.
    *)
    WriteFile(FPipeHandleClient, SendStream.Memory^, SendStream.Size, dw, nil);
  end;
end;

function TPipeClient.GetTerminated: Boolean;
begin
  Result := inherited Terminated or FbFinished;
end;

procedure TPipeClient.Execute;
var
  LERR: DWORD;
begin
  // nicht eigenständig auflösen, darum kümmert sich der Ersteller
  FreeOnTerminate := false;

  FbFinished := false;
  LERR := 0;
  while (not Terminated) and (LERR <> ERROR_BROKEN_PIPE) and
    (LERR <> ERROR_PIPE_NOT_CONNECTED) do
  begin
    if FPipeHandleClient = INVALID_HANDLE_VALUE then
      break;
    PipeClientCheckReceive;

    sleep(10);

    // wegen Abbruchprüfung immer den GetLastError prüfen (im Leerlauf durch PeekNamedPipe ausgelöst)
    LERR := GetLastError;
  end;
  FbFinished := true;
end;

end.
