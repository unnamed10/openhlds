unit SysMain;

{$I HLDS.inc}

interface

uses {$IFDEF MSWINDOWS} Windows, {$ELSE} Libc, {$ENDIF} SysUtils, Default, SDK;

function Sys_GetProcAddress(Module: THandle; Name: PLChar): Pointer;
function Sys_LoadModule(Name: PLChar): THandle;
procedure Sys_UnloadModule(Module: THandle);
procedure Sys_Sleep(MS: UInt);

procedure Sys_DebugOutStraight(S: PLChar);

procedure Sys_Init;

procedure Sys_Shutdown;

procedure Sys_Error(Text: PLChar); overload;
procedure Sys_Error(const Text: array of const); overload;

{$IFDEF MSWINDOWS}
function Sys_LastModuleErr: UInt;
{$ELSE}
function Sys_LastModuleErr: PLChar;
{$ENDIF}

type
 TCriticalSection = {$IFDEF MSWINDOWS}TRTLCriticalSection{$ELSE}pthread_mutex_t{$ENDIF};

procedure Sys_InitCS(var CS: TCriticalSection);
procedure Sys_EnterCS(var CS: TCriticalSection);
procedure Sys_LeaveCS(var CS: TCriticalSection);
procedure Sys_DeleteCS(var CS: TCriticalSection);

function Sys_FindFirst(S, Base: PLChar): PLChar;
function Sys_FindNext(Base: PLChar): PLChar;
procedure Sys_FindClose;

var
 InSysError: Boolean;

implementation

uses Common, Console, CoreUI, FileSys, GameLib, Host, Main, Memory, Network,
     SVExport, SVMain, SysArgs, SysClock;

var
 FindHandle: TFileFindHandle = INVALID_FIND_HANDLE;
 ErrorReEntry: Boolean;
 IsNT4, IsWin95, IsWin98: Boolean;

function Sys_GetProcAddress(Module: THandle; Name: PLChar): Pointer;
begin
{$IFDEF MSWINDOWS}
if (Module > 0) and (Module <> INVALID_HANDLE_VALUE) then
 Result := GetProcAddress(Module, Name)
{$ELSE}
if Module <> INVALID_HANDLE_VALUE then
 Result := dlsym(Module, Name)
{$ENDIF}
else
 Result := nil;
end;

function Sys_LoadModule(Name: PLChar): THandle;
{$IFDEF MSWINDOWS}
begin
Result := LoadLibraryA(Name);
if Result = 0 then
 Result := INVALID_HANDLE_VALUE;
{$ELSE}
var
 CWD, Buf: array[1..4096] of LChar;
 L: UInt;
 P: PLChar;
begin
if Name^ = CorrectSlash then
 Result := dlopen(Name, RTLD_NOW)
else
 begin
  getcwd(@CWD, SizeOf(CWD));
  P := StrEnd(@CWD);
  if (P <> @CWD) and (PLChar(UInt(P) - 1)^ = CorrectSlash) then
   PLChar(UInt(P) - 1)^ := #0;

  P := StrECopy(@Buf, @CWD);

  if UInt(P) - UInt(@Buf) < SizeOf(Buf) - 1 then
   begin
    P^ := CorrectSlash;
    StrLCopy(PLChar(UInt(P) + 1), Name, SizeOf(Buf) - 1 - (UInt(P) - UInt(@Buf)));
    Result := dlopen(@Buf, RTLD_NOW);
   end
  else
   begin
    Result := INVALID_HANDLE_VALUE;
    Exit;
   end;
 end;

if Result = INVALID_HANDLE_VALUE then
 begin
  DPrint(['Sys_LoadLibrary: Error loading library ', Name, ': code ', dlerror, '.' + LineBreak,
          'Trying to load the library with a pre-defined extension.']);
  P := StrECopy(@Buf, @CWD);
  if UInt(P) - UInt(@Buf) < SizeOf(Buf) - 1 then
   StrLCopy(P, '.so', SizeOf(Buf) - 1 - (UInt(P) - UInt(@Buf)));
  Result := dlopen(@Buf, RTLD_NOW);
  if Result = INVALID_HANDLE_VALUE then
   DPrint(['Sys_LoadLibrary: Error loading library ', Name, ': code ', dlerror, '.']);
 end;
{$ENDIF}
end;

procedure Sys_UnloadModule(Module: THandle);
begin
{$IFDEF MSWINDOWS}
if (Module > 0) and (Module <> INVALID_HANDLE_VALUE) then
 FreeLibrary(Module);
{$ELSE}
if Module <> INVALID_HANDLE_VALUE then
 dlclose(Module);
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
function Sys_LastModuleErr: UInt;
begin
Result := GetLastError;
end;
{$ELSE}
function Sys_LastModuleErr: PLChar;
begin
Result := dlerror;
end;
{$ENDIF}

function Sys_FindFirst(S, Base: PLChar): PLChar;
begin
if FindHandle <> INVALID_FIND_HANDLE then
 Sys_Error('Sys_FindFirst without close.');

Result := FS_FindFirst(S, FindHandle);
if (Base <> nil) and (Result <> nil) then
 COM_FileBase(Result, Base);
end;

function Sys_FindNext(Base: PLChar): PLChar;
begin
Result := FS_FindNext(FindHandle);
if (Base <> nil) and (Result <> nil) then
 COM_FileBase(Result, Base);
end;

procedure Sys_FindClose;
begin
if FindHandle <> INVALID_FIND_HANDLE then
 begin
  FS_FindClose(FindHandle);
  FindHandle := INVALID_FIND_HANDLE;
 end;
end;

procedure Sys_MakeCodeWriteable(P: Pointer; Size: UInt);
var
 OldProtect: UInt32;
begin
{$IFDEF MSWINDOWS}
VirtualProtect(P, Size, PAGE_READWRITE, OldProtect);
{$ELSE}
mprotect(P, Size, PROT_READ or PROT_WRITE);
{$ENDIF}
end;

procedure Sys_Sleep(MS: UInt);
begin
{$IFDEF MSWINDOWS}
 Windows.Sleep(MS);
{$ELSE}
 usleep(1000 * MS);
{$ENDIF}
end;

procedure Sys_DebugOutStraight(S: PLChar);
begin
{$IFDEF MSWINDOWS}
OutputDebugStringA(S);
{$ELSE}
Writeln(ErrOutput, S);
{$ENDIF}
end;

procedure Sys_Error(Text: PLChar);
begin
if ErrorReEntry then
 Sys_DebugOutStraight(Text)
else
 begin
  ErrorReEntry := True;
  InSysError := True;

  if SVS.InitGameDLL and (@DLLFunctions.Sys_Error <> nil) then
   DLLFunctions.Sys_Error(Text);

  LPrint(['FATAL ERROR (shutting down): ', Text, #10]);
  {$IFDEF MSWINDOWS}
   MessageBoxA(0, PLChar('FATAL ERROR (shutting down): ' + Text), 'Error', MB_OK or MB_ICONERROR or MB_SYSTEMMODAL);
  {$ELSE}
   Writeln('FATAL ERROR (shutting down): ' + Text);
  {$ENDIF}
 end;

Halt;
end;

procedure Sys_Error(const Text: array of const);
begin
Sys_Error(PLChar(StringFromVarRec(Text)));
end;

procedure Sys_InitCS(var CS: TCriticalSection);
{$IFDEF MSWINDOWS}
begin
InitializeCriticalSection(CS);
{$ELSE}
var
 Attr: pthread_mutexattr_t;                    
begin
if pthread_mutexattr_init(Attr) = 0 then
 begin
  pthread_mutexattr_settype(Attr, PTHREAD_MUTEX_RECURSIVE_NP);
  pthread_mutex_init(CS, Attr);
  pthread_mutexattr_destroy(Attr);
 end;
{$ENDIF}
end;

procedure Sys_EnterCS(var CS: TCriticalSection);
begin
{$IFDEF MSWINDOWS}
EnterCriticalSection(CS);
{$ELSE}
pthread_mutex_lock(CS);
{$ENDIF}
end;

procedure Sys_LeaveCS(var CS: TCriticalSection);
begin
{$IFDEF MSWINDOWS}
LeaveCriticalSection(CS);
{$ELSE}
pthread_mutex_unlock(CS);
{$ENDIF}
end;

procedure Sys_DeleteCS(var CS: TCriticalSection);
begin
{$IFDEF MSWINDOWS}
DeleteCriticalSection(CS);
{$ELSE}
pthread_mutex_destroy(CS);
{$ENDIF}
end;

procedure Sys_CheckOSVersion;
{$IFDEF MSWINDOWS}
var
 Info: TOSVersionInfoA;
begin
MemSet(Info, SizeOf(Info), 0);
Info.dwOSVersionInfoSize := SizeOf(Info);

if not GetVersionExA(Info) then
 Sys_Error('Sys_GetOSInfo: Couldn''t get OS info.')
else
 with Info do
  begin
   IsNT4 := dwMajorVersion >= 4;
   if (dwPlatformId = VER_PLATFORM_WIN32_WINDOWS) and (dwMajorVersion = 4) then
    if dwMinorVersion = 0 then
     IsWin95 := True
    else
     if dwMinorVersion < 90 then
      IsWin98 := True;
  end;
end;
{$ELSE}
begin

end;
{$ENDIF}

procedure Sys_Init;
begin
HostInit := False;

Sys_InitArgs;
if COM_CheckParm('-dev') > 0 then
 begin
  developer.Data := '1';
  developer.Value := 1;
 end;

Sys_InitClock;
Sys_CheckOSVersion;
Sys_SetStartTime;

Memory_Init;
FileSystem_Init;
Host_Init;

if HostInit then
 begin
  UI_EngineReady(EngFuncs);
  NET_Config(True);
  Host_InitializeGameDLL;
 end;
end;

procedure Sys_Shutdown;
begin
Host_Shutdown;
FileSystem_Shutdown;
Memory_Shutdown;
Sys_ShutdownClock;
Sys_ShutdownArgs;
end;

end.
