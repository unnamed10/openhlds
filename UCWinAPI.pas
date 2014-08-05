unit UCWinAPI;

{$I HLDS.inc}

interface

{$IFDEF MSWINDOWS}

uses Default, Windows;

function CreateFile(Name: PLChar; FileAccess, FileCreation, FileFlags: UInt32): THandle;

function GetFileAttributes(Name: PLChar): UInt32;
function SetFileAttributes(Name: PLChar; Attributes: UInt32): Boolean;
function DeleteFile(Name: PLChar): Boolean;
function CreateFileMapping(Handle: THandle; MemoryAccess: UInt32): UInt32;

function CreateDirectory(Name: PLChar): Boolean;
function GetFileAttributesEx(Name: PLChar; LevelID: TGetFileExInfoLevels; FileInformation: Pointer): Boolean;

var
 GetFileSizeEx: function(hFile: THandle; lpFileSize: PInt64): UInt32 stdcall = nil;
 CreateFileW: function(lpFileName: PWChar; dwDesiredAccess, dwShareMode: UInt32; lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile: THandle): THandle stdcall = nil;
 CreateFileMappingW: function(hFile: THandle; lpFileMappingAttributes: PSecurityAttributes; flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: UInt32; lpName: PWChar): THandle stdcall = nil;
 GetFileAttributesW: function(lpFileName: PWChar): UInt32 stdcall = nil;
 DeleteFileW: function(lpFileName: PWChar): Bool32 stdcall = nil;
 SetFileAttributesW: function(lpFileName: PWChar; dwFileAttributes: UInt32): Bool32 stdcall = nil;

 CreateDirectoryW: function(lpPathName: PWChar; lpSecurityAttributes: PSecurityAttributes): Bool32 stdcall = nil;
 GetFileAttributesExW: function(lpFileName: PWChar; fInfoLevelId: TGetFileExInfoLevels; lpFileInformation: Pointer): Bool32 stdcall = nil;

implementation

function CreateFile(Name: PLChar; FileAccess, FileCreation, FileFlags: UInt32): THandle;
 procedure FA;
 begin
  Result := CreateFileA(Name, FileAccess, 0, nil, FileCreation, FileFlags, 0);
 end;
 procedure FW;
 begin
  Result := CreateFileW(PWChar(WStr(Name)), FileAccess, 0, nil, FileCreation, FileFlags, 0);
 end;
begin
if @CreateFileW = nil then FA else FW;
end;

function GetFileAttributes(Name: PLChar): UInt32;
 procedure FA;
 begin
  Result := GetFileAttributesA(Name);
 end;
 procedure FW;
 begin
  Result := GetFileAttributesW(PWChar(WStr(Name)));
 end;
begin
if @GetFileAttributesW = nil then FA else FW;
end;

function SetFileAttributes(Name: PLChar; Attributes: UInt32): Boolean;
 procedure FA;
 begin
  Result := SetFileAttributesA(Name, Attributes);
 end;
 procedure FW;
 begin
  Result := SetFileAttributesW(PWChar(WStr(Name)), Attributes);
 end;
begin
if @SetFileAttributesW = nil then FA else FW;
end;

function DeleteFile(Name: PLChar): Boolean;
 procedure FA;
 begin
  Result := DeleteFileA(Name);
 end;
 procedure FW;
 begin
  Result := DeleteFileW(PWChar(WStr(Name)));
 end;
begin
if @DeleteFileW = nil then FA else FW;
end;

function CreateFileMapping(Handle: THandle; MemoryAccess: UInt32): UInt32;
begin
if @CreateFileMappingW = nil then
 Result := CreateFileMappingA(Handle, nil, MemoryAccess, 0, 0, nil)
else
 Result := CreateFileMappingW(Handle, nil, MemoryAccess, 0, 0, nil);
end;

function CreateDirectory(Name: PLChar): Boolean;
 procedure FA;
 begin
  Result := CreateDirectoryA(Name, nil);
 end;
 procedure FW;
 begin
  Result := CreateDirectoryW(PWChar(WStr(Name)), nil);
 end;
begin
if @CreateDirectoryW = nil then FA else FW;
end;

function GetFileAttributesEx(Name: PLChar; LevelID: TGetFileExInfoLevels; FileInformation: Pointer): Boolean;
 procedure FA;
 begin
  Result := GetFileAttributesExA(Name, LevelID, FileInformation);
 end;
 procedure FW;
 begin
  Result := GetFileAttributesExW(PWChar(WStr(Name)), LevelID, FileInformation);
 end;
begin
if @GetFileAttributesExW = nil then FA else FW;
end;

procedure InitWrapper;
var
 Handle: THandle;
begin
Handle := LoadLibrary(kernel32);

if Handle > 0 then
 begin
  @GetFileSizeEx := GetProcAddress(Handle, 'GetFileSizeEx');
  @CreateFileW := GetProcAddress(Handle, 'CreateFileW');
  @CreateFileMappingW := GetProcAddress(Handle, 'CreateFileMappingW');
  @GetFileAttributesW := GetProcAddress(Handle, 'GetFileAttributesW');
  @SetFileAttributesW := GetProcAddress(Handle, 'SetFileAttributesW');
  @DeleteFileW := GetProcAddress(Handle, 'DeleteFileW');
  @CreateDirectoryW := GetProcAddress(Handle, 'CreateDirectoryW');
  @GetFileAttributesExW := GetProcAddress(Handle, 'GetFileAttributesExW');
 end;
end;

initialization
 InitWrapper;

finalization

{$ELSE}

// No wstr wrapper on Linux.

implementation

{$ENDIF}

end.
