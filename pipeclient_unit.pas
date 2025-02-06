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

  // Pipe Handling
  TPipeClientHelper = class(TObject)
  public
    class function PipeClientCreateInstance(sPipeName: string): THandle;
    class procedure PipeClientCloseInstance(hPipeHandle: THandle);
    class procedure PipeClientSendStream(hPipeHandle: THandle;
      SendStream: TMemoryStream);
    class function PipeClientCheckReceive(hPipeHandle: THandle): TMemoryStream;
  end;

  // Einfacher Client zum Senden/Empfangen
  TPipeClientSimple = class(TObject)
  private
    FPipeName: string;
    FPipeHandleClient: THandle;
  private
  protected
  public
    constructor Create(PipeClientPipeName: string);
    destructor Destroy; override;

    procedure SendStream(SendStream: TMemoryStream);
    function ReceiveStream: TMemoryStream;
  end;

  // Thread Client mit Datenevent
  TPipeClient = class(TThread)
  private
    FPipeName: string;
    FPipeHandleClient: THandle;
    FbFinished: Boolean;
    FPipeClientDataEvent: TPipeClientDataEvent;
  private
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

// ================================================================

class function TPipeClientHelper.PipeClientCreateInstance
  (sPipeName: string): THandle;
(*
  FSA: SECURITY_ATTRIBUTES;
  FSD: SECURITY_DESCRIPTOR;
*)
var
  LERR: Integer;

  I: Integer;
begin
  Result := INVALID_HANDLE_VALUE;

  (*
    https://learn.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-initializesecuritydescriptor
    The InitializeSecurityDescriptor function initializes a new security descriptor.

    https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-setsecuritydescriptordacl
    The SetSecurityDescriptorDacl function sets information in a discretionary access control list (DACL).
    If a DACL is already present in the security descriptor, the DACL is replaced.
  *)
  (*
  InitializeSecurityDescriptor(@FSD, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@FSD, true, nil, false);
  FSA.lpSecurityDescriptor := @FSD;
  FSA.nLength := sizeof(SECURITY_ATTRIBUTES);
  FSA.bInheritHandle := true;
  *)

  I := 0;
  while (Result = INVALID_HANDLE_VALUE) and (I < 25) do
  begin
    (*
      https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilea
      Creates or opens a file or I/O device.
      The most commonly used I/O devices are as follows: file, file stream, directory, physical disk, volume,
      console buffer, tape drive, communications resource, mailslot, and pipe.
      The function returns a handle that can be used to access the file or device for various types of I/O depending
      on the file or device and the flags and attributes specified.
    *)
    Result := CreateFile(PChar('\\.\pipe\' + sPipeName), GENERIC_READ or
      GENERIC_WRITE, // Lesen/Schreiben
      0, // kein Sharing
      Nil(*@FSA*), // Attribute (Sicherheit, ob der Handle an einen Subprozess übergeben werden kann oder nicht)
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

  if Result = INVALID_HANDLE_VALUE then
    raise Exception.Create(rsCouldNotConnectInterfacePipe);
end;

class procedure TPipeClientHelper.PipeClientCloseInstance(hPipeHandle: THandle);
begin
  if hPipeHandle <> INVALID_HANDLE_VALUE then
  begin
    (*
      https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle
      Closes an open object handle.
    *)
    CloseHandle(hPipeHandle);
  end;
end;

class function TPipeClientHelper.PipeClientCheckReceive(hPipeHandle: THandle)
  : TMemoryStream;
var
  lpTotalBytesAvail, lpBytesLeftThisMessage: DWORD;
  dw: DWORD;
begin
  Result := nil;
  (*
    https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-peeknamedpipe
    Copies data from a named or anonymous pipe into a buffer without removing it from the pipe. It also returns information about data in the pipe.
  *)
  if PeekNamedPipe(hPipeHandle, nil, 0, nil, @lpTotalBytesAvail,
    @lpBytesLeftThisMessage) then
  begin
    // lpTotalBytesAvail kann größer sein wenn mehr messages anstehen
    if (lpBytesLeftThisMessage > 0) then
    begin
      Result := TMemoryStream.Create;
      Result.SetSize(lpBytesLeftThisMessage);
      (*
        https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile
        Reads data from the specified file or input/output (I/O) device. Reads occur at the position specified by the file pointer if supported by the device.
      *)
      ReadFile(hPipeHandle, Result.Memory^, lpBytesLeftThisMessage, dw, nil);
    end;
  end;
end;

class procedure TPipeClientHelper.PipeClientSendStream(hPipeHandle: THandle;
  SendStream: TMemoryStream);
var
  dw: DWORD;
begin
  if hPipeHandle <> INVALID_HANDLE_VALUE then
  begin
    (*
      https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile
      Writes data to the specified file or input/output (I/O) device.
    *)
    WriteFile(hPipeHandle, SendStream.Memory^, SendStream.Size, dw, nil);
  end;
end;


// ================================================================

constructor TPipeClientSimple.Create(PipeClientPipeName: string);
begin
  inherited Create;
  FPipeName := PipeClientPipeName;
  FPipeHandleClient := INVALID_HANDLE_VALUE;

  // Pipe verbinden
  FPipeHandleClient := TPipeClientHelper.PipeClientCreateInstance(FPipeName);
end;

destructor TPipeClientSimple.Destroy;
begin
  // Pipe Trennen
  TPipeClientHelper.PipeClientCloseInstance(FPipeHandleClient);
  FPipeHandleClient := INVALID_HANDLE_VALUE;

  inherited;
end;

procedure TPipeClientSimple.SendStream(SendStream: TMemoryStream);
begin
  TPipeClientHelper.PipeClientSendStream(FPipeHandleClient, SendStream);
end;

function TPipeClientSimple.ReceiveStream: TMemoryStream;
begin
  Result := TPipeClientHelper.PipeClientCheckReceive(FPipeHandleClient);
end;

// ================================================================

constructor TPipeClient.Create(PipeClientPipeName: string);
begin
  inherited Create(true);
  FPipeName := PipeClientPipeName;
  FPipeHandleClient := INVALID_HANDLE_VALUE;
  FbFinished := false;
  FPipeClientDataEvent := nil;

  // Pipe verbinden
  FPipeHandleClient := TPipeClientHelper.PipeClientCreateInstance(FPipeName);

  // Start;
end;

destructor TPipeClient.Destroy;
begin
  // Pipe Trennen
  TPipeClientHelper.PipeClientCloseInstance(FPipeHandleClient);
  FPipeHandleClient := INVALID_HANDLE_VALUE;

  inherited;
end;

function TPipeClient.GetTerminated: Boolean;
begin
  Result := inherited Terminated or FbFinished;
end;

procedure TPipeClient.SendStream(SendStream: TMemoryStream);
begin
  TPipeClientHelper.PipeClientSendStream(FPipeHandleClient, SendStream);
end;

procedure TPipeClient.Execute;
var
  LERR: DWORD;
  rcvStream: TMemoryStream;
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

    rcvStream := nil;
    try
      rcvStream := TPipeClientHelper.PipeClientCheckReceive(FPipeHandleClient);
      if Assigned(rcvStream) then
      begin
        if Assigned(FPipeClientDataEvent) then
        begin
          FPipeClientDataEvent(self, rcvStream);
        end;
      end;
    finally
      FreeAndNil(rcvStream);
    end;

    sleep(1);

    // wegen Abbruchprüfung immer den GetLastError prüfen (im Leerlauf durch PeekNamedPipe ausgelöst)
    LERR := GetLastError;
  end;
  FbFinished := true;
end;

// ================================================================

end.
