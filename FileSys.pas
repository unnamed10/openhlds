unit FileSys;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS} Windows {$ELSE} Libc {$ENDIF}, Default, SDK;

procedure FS_RemoveAllSearchPaths;
procedure FS_AddSearchPath(Path, Name: PLChar; AddToBase: Boolean);
procedure FS_AddSearchPathNoWrite(Path, Name: PLChar; AddToBase: Boolean);
function FS_RemoveSearchPath(Path, Name: PLChar): Boolean;
function FS_SearchListInitialized: Boolean;

function FS_IsAbsolutePath(Name: PLChar): Boolean;
function FS_RemoveFile(Name: PLChar; PathID: PLChar = nil; RemoveReadOnly: Boolean = True): Boolean;
procedure FS_CreateDirHierarchy(Name: PLChar; PathID: PLChar = nil);
function FS_FileExists(Name: PLChar; PathID: PLChar = nil): Boolean;
function FS_IsDirectory(Name: PLChar; PathID: PLChar = nil): Boolean;

function FS_OpenPathID(out F: TFile; Name, Options, PathID: PLChar): Boolean;
function FS_Open(out F: TFile; Name, Options: PLChar): Boolean;
procedure FS_Close(F: TFile);

function FS_Seek(F: TFile; Offset: Int64; SeekType: TFileSeekType): Boolean;
function FS_Tell(F: TFile): Int64;
function FS_Size(F: TFile): Int64;
function FS_SizeByName(Name: PLChar; PathID: PLChar = nil): Int64;
function FS_GetFileTime(Name: PLChar; PathID: PLChar = nil): Int64;
function FS_IsOK(F: TFile): Boolean;
procedure FS_Flush(F: TFile);
function FS_EndOfFile(F: TFile): Boolean;
function FS_Read(F: TFile; Buffer: Pointer; Size: UInt): UInt;
function FS_Write(F: TFile; Buffer: Pointer; Size: UInt): UInt;
function FS_ReadLine(F: TFile; Buffer: Pointer; MaxChars: UInt): PLChar;
procedure FS_WriteLine(F: TFile; S: PLChar; NeedLineBreak: Boolean = True);
function FS_FPrintF(F: TFile; S: PLChar; NeedLineBreak: Boolean  = True): UInt; overload;
function FS_FPrintF(F: TFile; const S: array of const; NeedLineBreak: Boolean = True): UInt; overload;

function FS_FindFirst(Name: PLChar; out H: TFileFindHandle): PLChar;
function FS_FindNext(H: TFileFindHandle): PLChar;
function FS_FindIsDirectory(H: TFileFindHandle): Boolean;
procedure FS_FindClose(H: TFileFindHandle);

procedure FS_GetLocalCopy(Name: PLChar);
function FS_GetLocalPath(Name: PLChar): PLChar;
function FS_ParseFile(Data: Pointer; Token: PLChar; WasQuoted: PBoolean): Pointer;
procedure FS_GetCurrentDirectory(Buf: PLChar; MaxLen: UInt);
procedure FS_SetWarningLevel(Level: TFileWarningLevel);
function FS_GetCharacter(F: TFile): LChar;

procedure FS_LogLevelLoadStarted(Name: PLChar);
procedure FS_LogLevelLoadFinished(Name: PLChar);
function FS_GetInterfaceVersion: PLChar;
procedure FS_Unlink(Name: PLChar);
procedure FS_Rename(OldPath: PLChar; NewPath: PLChar = nil);

function FileSystem_AddFallbackGameDir(Name: PLChar): Boolean;
procedure FileSystem_Init;
procedure FileSystem_Shutdown;

implementation

uses FSNative, Common, Console, Info, Memory, Host, SysArgs, SysMain;

var
 FSInput: PFileSystem;
 WarningLevel: TFileWarningLevel = FSW_SILENT;

procedure FS_Init;
begin
FSInput.Init;
end;

procedure FS_Shutdown;
begin
FSInput.Shutdown;
end;

procedure FS_RemoveAllSearchPaths;
begin
FSInput.RemoveAllSearchPaths;
end;

procedure FS_AddSearchPath(Path, Name: PLChar; AddToBase: Boolean);
begin
FSInput.AddSearchPath(Path, Name, AddToBase);
end;

procedure FS_AddSearchPathNoWrite(Path, Name: PLChar; AddToBase: Boolean);
begin
FSInput.AddSearchPathNoWrite(Path, Name, AddToBase);
end;

function FS_RemoveSearchPath(Path, Name: PLChar): Boolean;
begin
Result := FSInput.RemoveSearchPath(Path, Name);
end;

function FS_SearchListInitialized: Boolean;
begin
Result := FSInput.SearchListInitialized;
end;

function FS_IsAbsolutePath(Name: PLChar): Boolean;
begin
Result := FSInput.IsAbsolutePath(Name);
end;

function FS_RemoveFile(Name: PLChar; PathID: PLChar = nil; RemoveReadOnly: Boolean = True): Boolean;
begin
Result := FSInput.RemoveFile(Name, PathID, RemoveReadOnly);
end;

procedure FS_CreateDirHierarchy(Name: PLChar; PathID: PLChar = nil);
begin
FSInput.CreateDirHierarchy(Name, PathID);
end;

function FS_FileExists(Name: PLChar; PathID: PLChar = nil): Boolean;
begin
Result := FSInput.FileExists(Name, PathID);
end;

function FS_IsDirectory(Name: PLChar; PathID: PLChar): Boolean;
begin
Result := FSInput.IsDirectory(Name, PathID);
end;

function FS_OpenPathID(out F: TFile; Name, Options, PathID: PLChar): Boolean;
begin
Result := FSInput.OpenPathID(F, Name, Options, PathID);
end;

function FS_Open(out F: TFile; Name, Options: PLChar): Boolean;
begin
Result := FSInput.Open(F, Name, Options);
end;

procedure FS_Close(F: TFile);
begin
FSInput.Close(F);
end;

function FS_Seek(F: TFile; Offset: Int64; SeekType: TFileSeekType): Boolean;
begin
Result := FSInput.Seek(F, Offset, SeekType);
end;

function FS_Tell(F: TFile): Int64;
begin
Result := FSInput.Tell(F);
end;

function FS_Size(F: TFile): Int64;
begin
Result := FSInput.Size(F);
end;

function FS_SizeByName(Name: PLChar; PathID: PLChar): Int64;
begin
Result := FSInput.SizeByName(Name, PathID);
end;

function FS_GetFileTime(Name: PLChar; PathID: PLChar): Int64;
begin
Result := FSInput.GetFileTime(Name, PathID);
end;

function FS_IsOK(F: TFile): Boolean;
begin
Result := FSInput.IsOK(F);
end;

procedure FS_Flush(F: TFile);
begin
FSInput.Flush(F);
end;

function FS_EndOfFile(F: TFile): Boolean;
begin
Result := FSInput.EndOfFile(F);
end;

function FS_Read(F: TFile; Buffer: Pointer; Size: UInt): UInt;
begin
Result := FSInput.Read(F, Buffer, Size);
end;

function FS_Write(F: TFile; Buffer: Pointer; Size: UInt): UInt;
begin
Result := FSInput.Write(F, Buffer, Size);
end;

function FS_ReadLine(F: TFile; Buffer: Pointer; MaxChars: UInt): PLChar;
begin
Result := FSInput.ReadLine(F, Buffer, MaxChars);
end;

procedure FS_WriteLine(F: TFile; S: PLChar; NeedLineBreak: Boolean = True);
begin
FSInput.WriteLine(F, S, NeedLineBreak);
end;

function FS_FPrintF(F: TFile; S: PLChar; NeedLineBreak: Boolean  = True): UInt;
begin
Result := FSInput.FPrintF(F, S, NeedLineBreak);
end;

function FS_FPrintF(F: TFile; const S: array of const; NeedLineBreak: Boolean = True): UInt;
begin
Result := FSInput.FPrintF(F, PLChar(StringFromVarRec(S)), NeedLineBreak);
end;

function FS_FindFirst(Name: PLChar; out H: TFileFindHandle): PLChar;
begin
Result := FSInput.FindFirst(Name, H);
end;

function FS_FindNext(H: TFileFindHandle): PLChar;
begin
Result := FSInput.FindNext(H);
end;

function FS_FindIsDirectory(H: TFileFindHandle): Boolean;
begin
Result := FSInput.FindIsDirectory(H);
end;

procedure FS_FindClose(H: TFileFindHandle);
begin
FSInput.FindClose(H);
end;

procedure FS_GetLocalCopy(Name: PLChar);
begin
FSInput.GetLocalCopy(Name);
end;

function FS_GetLocalPath(Name: PLChar): PLChar;
begin
Result := FSInput.GetLocalPath(Name);
end;

function FS_ParseFile(Data: Pointer; Token: PLChar; WasQuoted: PBoolean): Pointer;
begin
Result := FSInput.ParseFile(Data, Token, WasQuoted);
end;

procedure FS_GetCurrentDirectory(Buf: PLChar; MaxLen: UInt);
begin
FSInput.GetCurrentDirectory(Buf, MaxLen);
end;

procedure FS_SetWarningLevel(Level: TFileWarningLevel);
begin
FSInput.SetWarningLevel(Level);
end;

function FS_GetCharacter(F: TFile): LChar;
begin
Result := FSInput.GetCharacter(F);
end;

procedure FS_LogLevelLoadStarted(Name: PLChar);
begin
FSInput.LogLevelLoadStarted(Name);
end;

procedure FS_LogLevelLoadFinished(Name: PLChar);
begin
FSInput.LogLevelLoadFinished(Name);
end;

function FS_GetInterfaceVersion: PLChar;
begin
Result := FSInput.GetInterfaceVersion;
end;

procedure FS_Unlink(Name: PLChar);
begin
FSInput.Unlink(Name);
end;

procedure FS_Rename(OldPath, NewPath: PLChar);
begin
FSInput.Rename(OldPath, NewPath);
end;

procedure RegisterPath(Path, Name: PLChar; AddToBase: Boolean);
var
 FullPath: array[1..MAX_PATH_W] of LChar;
 P: PLChar;
begin
P := StrLECopy(@FullPath, Path, SizeOf(FullPath) - 1);

if LowViolenceBuild then
 begin
  StrCopy(P, '_lv');
  FS_AddSearchPathNoWrite(@FullPath, Name, AddToBase);
  P^ := #0;
 end;

if UseAddonsDir then
 begin
  StrCopy(P, '_addon');
  FS_AddSearchPathNoWrite(@FullPath, Name, AddToBase);
  P^ := #0;
 end;

if UseHDModels then
 begin
  StrCopy(P, '_hd');
  FS_AddSearchPathNoWrite(@FullPath, Name, AddToBase);
  P^ := #0;
 end;

if LangName <> 'english' then
 begin
  StrCopy(P, '_');
  StrCopy(PLChar(UInt(P) + SizeOf(P^)), LangName);
  FS_AddSearchPathNoWrite(@FullPath, Name, AddToBase);
  P^ := #0;
 end;

FS_AddSearchPath(@FullPath, Name, AddToBase);
end;

procedure CheckLiblistForFallbackDir;
var
 F: TFile;
 S, S2, S3: PLChar;
 Buffer: array[1..512] of LChar;
begin
if FS_Open(F, 'liblist.gam', 'r') then
 begin
  while not FS_EndOfFile(F) do
   begin
    S := FS_ReadLine(F, @Buffer, SizeOf(Buffer) - 1);
    if StrLIComp(S, 'fallback_dir', Length('fallback_dir')) = 0 then
     begin
      S2 := StrScan(S, '"');
      S3 := StrRScan(S, '"');
      if (S2 <> nil) and (S3 <> nil) and (S2 <> S3) then
       begin
        S := PLChar(UInt(S2) + 1);
        S3^ := #0;

        if StrIComp(S, GameDir) <> 0 then
         begin
          RegisterPath(PLChar(BaseDir + CorrectSlash + S), 'GAME_FALLBACK', False);
          Break;
         end;
       end;
     end;
   end;

  FS_Close(F);
 end;
end;

procedure ParseDirectoryFromCmd(Name: PLChar; out Directory: PLChar; Default: PLChar);
begin
Directory := COM_ParmValueByName(Name);
if (Directory <> nil) and (Directory^ > #0) then
 begin
  Directory := Mem_StrDup(Directory);
  COM_FixSlashes(Directory);
  COM_StripTrailingSlash(Directory);
 end
else
 Directory := Mem_StrDup(Default);
end;

function FileSystem_SetGameDirectory(DefaultGameDir, GameDir: PLChar): Boolean;
begin
FS_RemoveAllSearchPaths;

FS_AddSearchPathNoWrite(BaseDir, 'BASE', True);
FS_AddSearchPath(PLChar(BaseDir + CorrectSlash + 'platform'), 'PLATFORM', True);

RegisterPath(PLChar(BaseDir + CorrectSlash + DefaultGameDir), 'DEFAULTGAME', True);
RegisterPath(PLChar(BaseDir + CorrectSlash + GameDir), 'GAME', True);

FS_AddSearchPath(PLChar(BaseDir + CorrectSlash + GameDir), 'GAMECONFIG', True);

CheckLiblistForFallbackDir;
Result := True;
end;

function FileSystem_AddFallbackGameDir(Name: PLChar): Boolean;
begin
if StrIComp(LangName, 'english') <> 0 then
 FS_AddSearchPath(PLChar(BaseDir + CorrectSlash + Name + '_' + LangName), 'GAME', True);

FS_AddSearchPath(Name, 'GAME', True);
Result := True;
end;

procedure FS_Warning(Msg: PLChar);
begin
Print(['FileSystem: ', Msg]);
end;

procedure FileSystem_Init;
const
 EngineOutput: TFileSystemInput =
  (MemAlloc: Memory.Mem_Alloc;
   MemFree: Memory.Mem_Free;
   Warning: FS_Warning;
   AddCommand: Console.Cmd_AddCommand;
   RegisterVariable: Console.CVar_RegisterVariable);
var
 {$IFNDEF MSWINDOWS} Buf: array[1..MAX_PATH_W] of LChar; {$ENDIF}
 L: UInt;
begin
FSInput := FS_SetupInterface(EngineOutput);
if FSInput = nil then
 Sys_Error('Couldn''t initialize file system.');

FS_Init;

{$IFDEF MSWINDOWS}
 L := GetCurrentDirectoryA(0, nil);
 BaseDir := Mem_Alloc(L);
 GetCurrentDirectoryA(L, BaseDir);
{$ELSE}
 if getcwd(@Buf, SizeOf(Buf)) = nil then
  Sys_Error('Couldn''t get current working directory.');
 BaseDir := Mem_StrDup(@Buf);
{$ENDIF}
COM_FixSlashes(BaseDir);
COM_StripTrailingSlash(BaseDir);

FallbackDir := EmptyString;

ParseDirectoryFromCmd('-basedir', DefaultGameDir, DEFAULT_GAME);
ParseDirectoryFromCmd('-game', GameDir, DefaultGameDir);

FileSystem_SetGameDirectory(DefaultGameDir, GameDir);

Info_SetValueForStarKey(Info_ServerInfo, '*gamedir', GameDir, SizeOf(ServerInfo));
end;

procedure FileSystem_Shutdown;
begin
FS_Shutdown;

Mem_FreeAndNil(GameDir);
Mem_FreeAndNil(DefaultGameDir);
Mem_FreeAndNil(BaseDir);
end;

end.
