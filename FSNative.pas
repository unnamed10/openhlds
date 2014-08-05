unit FSNative;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS} Windows, {$ELSE} Libc, {$ENDIF} Default, SDK;

function FS_SetupInterface(const Input: TFileSystemInput): PFileSystem;

implementation

uses Common{$IFDEF MSWINDOWS}, UCWinAPI{$ENDIF};

type
 TSearchPathFlags = set of (sfNoWrite = 0, sfAddToBase);

 PFileSearchPath = ^TFileSearchPath;
 TFileSearchPath = record
  Prev, Next: PFileSearchPath;
  Path: PLChar; // offset - no free
  Name: PLChar; // offset - no free
  Flags: TSearchPathFlags;
 end;

 TFileAccess = (FILE_NO_ACCESS = 0, FILE_READ, FILE_WRITE, FILE_APPEND);
 TFileAccessFlags = set of (FILE_MAPPED = 0, FILE_OVERWRITE, FILE_RANDOM_ACCESS, FILE_SEQUENTIAL_ACCESS);

 TFileInternalHandle = {$IFDEF MSWINDOWS}THandle{$ELSE}UInt32{$ENDIF};

 {$IFDEF MSWINDOWS}
 PFileInternal = ^TFileInternal;
 TFileInternal = record
  Handle: TFileInternalHandle;
  AccessType: TFileAccess;
  AccessFlags: TFileAccessFlags;
  MappedFile: Boolean;

  Size: Int64;
  Position: Int64;
  Data: Pointer;
  MapHandle: THandle;
 end;
 {$ELSE}
 PFileInternal = ^TFileInternal;
 TFileInternal = record
  Handle: TFileInternalHandle;
  AccessType: TFileAccess;
  AccessFlags: TFileAccessFlags;

  Size: Int64;
  Position: Int64;
 end;
 {$ENDIF}

var
 InitDone: Boolean = False;

 SearchBase: PFileSearchPath = nil;
 SearchLast: PFileSearchPath = nil;

 EngineInput: TFileSystemInput;

 WarningLevel: TFileWarningLevel = FSW_WARNING;

function FS_Seek(F: TFile; Offset: Int64; SeekType: TFileSeekType): Boolean; forward;

procedure FS_Warning(Msg: PLChar; Level: TFileWarningLevel); overload;
begin
if (@EngineInput.Warning <> nil) and (Level <= WarningLevel) then
 EngineInput.Warning(Msg);
end;

procedure FS_Warning(const Msg: array of const; Level: TFileWarningLevel); overload;
begin
if (@EngineInput.Warning <> nil) and (Level <= WarningLevel) then
 EngineInput.Warning(PLChar(StringFromVarRec(Msg)));
end;

function FS_MemAlloc(Size: UInt): Pointer;
begin
Result := EngineInput.MemAlloc(Size);
end;

procedure FS_MemFree(P: Pointer);
begin
EngineInput.MemFree(P);
end;

function FS_CheckFile(F: TFile; FuncName: PLChar): Boolean;
begin
if F = nil then
 FS_Warning(['Bad file pointer provided in ', FuncName, '.'], FSW_WARNING)
else
 if PFileInternal(F).Handle = INVALID_FILE_HANDLE then
  FS_Warning(['Bad file handle provided in ', FuncName, '.'], FSW_WARNING)
 else
  begin
   Result := True;
   Exit;
  end;

Result := False;
end;

function FS_FindSearchPath(Path, Name: PLChar): PFileSearchPath;
var
 P: PFileSearchPath;
begin
P := SearchBase;
while P <> nil do
 if ((Path = nil) or (StrComp(P.Path, Path) = 0)) and
    ((Name = nil) or (StrComp(P.Name, Name) = 0)) then
  Break
 else
  P := P.Prev;

Result := P;
end;

procedure FS_RemoveAllSearchPaths; // export
var
 P, P2: PFileSearchPath;
begin
P := SearchBase;
while P <> nil do
 begin
  P2 := P.Prev;
  FS_MemFree(P);
  P := P2;
 end;

SearchBase := nil;
SearchLast := nil;
end;

procedure FS_AddSearchPathInternal(Path, Name: PLChar; Flags: TSearchPathFlags);
var
 PathLen, NameLen: UInt;
 PathNeedSlash: Boolean;
 P: PFileSearchPath;
begin
if Path = nil then
 FS_Warning('Bad path specified in FS_AddSearchPathInternal.', FSW_WARNING)
else
 begin
  if Name = nil then
   begin
    Name := 'path';
    NameLen := 4;
   end
  else
   NameLen := StrLen(Name);

  PathLen := StrLen(Path);
  PathNeedSlash := not (PLChar(UInt(Path) + PathLen - 1)^ in ['\', '/']);

  P := FS_MemAlloc(SizeOf(P^) + PathLen + NameLen + 2 + UInt(PathNeedSlash));
  if P = nil then
   FS_Warning('Can''t add a search path, out of memory.', FSW_WARNING)
  else
   begin
    P.Path := Pointer(UInt(P) + SizeOf(P^));
    StrLCopy(P.Path, Path, PathLen);
    COM_FixSlashes(P.Path);
    if PathNeedSlash then
     begin
      PUInt16(UInt(P.Path) + PathLen)^ := UInt16(CorrectSlash); // and trailing 0
      Inc(PathLen);
     end;

    P.Name := Pointer(UInt(P.Path) + PathLen + 1);
    StrLCopy(P.Name, Name, NameLen);

    if FS_FindSearchPath(P.Path, P.Name) <> nil then
     begin
      FS_Warning(['Already have a search path named "', P.Name, '".'], FSW_WARNING);
      FS_MemFree(P);
     end
    else
     begin
      if sfAddToBase in Flags then
       begin
        if SearchBase <> nil then
         SearchBase.Next := P;
        P.Prev := SearchBase;
        P.Next := nil;
        SearchBase := P;
       end
      else
       begin
        if SearchLast <> nil then
         SearchLast.Prev := P;
        P.Prev := nil;
        P.Next := SearchLast;
        SearchLast := P;
       end;
      P.Flags := Flags;
     end;
   end;
 end;
end;

procedure FS_AddSearchPath(Path, Name: PLChar; AddToBase: Boolean); // export
begin
if not AddToBase then
 FS_AddSearchPathInternal(Path, Name, [])
else
 FS_AddSearchPathInternal(Path, Name, [sfAddToBase]);
end;

procedure FS_AddSearchPathNoWrite(Path, Name: PLChar; AddToBase: Boolean); // export
begin
if not AddToBase then
 FS_AddSearchPathInternal(Path, Name, [sfNoWrite])
else
 FS_AddSearchPathInternal(Path, Name, [sfNoWrite, sfAddToBase]);
end;

function FS_RemoveSearchPath(Path, Name: PLChar): Boolean; // export
var
 PathLen: UInt;
 PathBuf: array[1..MAX_PATH_W] of LChar;
 P: PFileSearchPath;
begin
if Path <> nil then
 begin
  PathLen := StrLen(Path);
  if (PathLen > 0) and not (PLChar(UInt(Path) + PathLen - 1)^ in ['\', '/']) then
   begin
    Path := StrLCopy(@PathBuf, Path, SizeOf(PathBuf) - 1);
    PUInt16(UInt(Path) + PathLen)^ := UInt16(CorrectSlash);
    COM_FixSlashes(Path);
   end;
 end;

P := FS_FindSearchPath(Path, Name);
Result := P <> nil;
if Result then
 begin
  if SearchBase = P then
   SearchBase := P.Prev;
  if SearchLast = P then
   SearchLast := P.Next;
   
  if P.Prev <> nil then
   P.Prev.Next := P.Next;
  if P.Next <> nil then
   P.Next.Prev := P.Prev;

  FS_MemFree(P);
 end;
end;

function FS_SearchListInitialized: Boolean; // export
begin
Result := SearchBase <> nil;
end;



function FS_FileExists_Internal(Name: PLChar): Boolean;
{$IFDEF MSWINDOWS}
var
 Attributes: UInt32;
begin
SetLastError(ERROR_SUCCESS);
Attributes := UCWinAPI.GetFileAttributes(Name);
Result := (Attributes <> High(Attributes)) and ((Attributes and FILE_ATTRIBUTE_DIRECTORY) = 0) and
          (GetLastError <> ERROR_FILE_NOT_FOUND);
end;
{$ELSE}
begin
__errno_location^ := 0;
Result := (access(Name, F_OK) = 0) and (errno <> ENOENT);
end;
{$ENDIF}

function FS_DirectoryExists_Internal(Name: PLChar): Boolean;
{$IFDEF MSWINDOWS}
var
 Attributes: UInt32;
begin
Attributes := UCWinAPI.GetFileAttributes(Name);
Result := (Attributes <> High(Attributes)) and ((Attributes and FILE_ATTRIBUTE_DIRECTORY) > 0);
end;
{$ELSE}
var
 P: Pointer;
begin
P := opendir(Name);
Result := P <> nil;
if Result then
 closedir(P);
end;
{$ENDIF}

function FS_FindFileByPathID(Name, FullName: PLChar; NeedWrite: Boolean; PathID: PLChar): Boolean;
var
 P: PFileSearchPath;
 S: PLChar;
begin
P := SearchBase;
while P <> nil do
 begin
  if (StrComp(P.Name, PathID) = 0) and (not NeedWrite or not (sfNoWrite in P.Flags)) then
   begin
    S := StrLECopy(FullName, P.Path, MAX_PATH_W - 1);
    StrLCopy(S, Name, MAX_PATH_W - 1 - (UInt(S) - UInt(FullName)));
    if NeedWrite or FS_FileExists_Internal(FullName) then
     begin
      Result := True;
      Exit;
     end;
   end;
  P := P.Prev;
 end;

Result := False;
end;

function FS_FindFileByListScan(Name, FullName: PLChar; NeedWrite: Boolean): Boolean;
var
 P: PFileSearchPath;
 S: PLChar;
begin
if NeedWrite then
 begin
  S := StrLECopy(FullName, SearchBase.Path, MAX_PATH_W - 1);
  StrLCopy(S, Name, MAX_PATH_W - 1 - (UInt(S) - UInt(FullName)));
  Result := True;
 end
else
 begin
  P := SearchBase;
  while P <> nil do
   begin
    S := StrLECopy(FullName, P.Path, MAX_PATH_W - 1);
    StrLCopy(S, Name, MAX_PATH_W - 1 - (UInt(S) - UInt(FullName)));
    if FS_FileExists_Internal(FullName) then
     begin
      Result := True;
      Exit;
     end;
    P := P.Prev;
   end;

  Result := False;
 end;
end;

function FS_IsAbsolutePath(Name: PLChar): Boolean; // export
begin
if Name = nil then
 begin
  FS_Warning('Bad name provided in FS_IsAbsolutePath.', FSW_WARNING);
  Result := False;
 end
else
{$IFDEF MSWINDOWS}
 Result := ((Name[1] = '\') and (Name[2] = '\')) or
           ((Name[1] = '/') and (Name[2] = '/')) or
           (StrScan(Name, ':') <> nil);
{$ELSE}
 Result := (Name[1] = '/') or (Name[1] = '\');
{$ENDIF}
end;

function FS_FindFile(Name: PLChar; out FullName; NeedWrite: Boolean; PathID: PLChar): Boolean;
var
 NameBuf: array[1..MAX_PATH_W] of LChar;
 P: PLChar;
begin
Result := False;
P := PLChar(@FullName);
if P = nil then
 FS_Warning('Bad buffer provided in FS_FindFile.', FSW_WARNING)
else
 begin
  P^ := #0;
  if (Name <> nil) and (Name^ > #0) then
   begin
    Name := StrLCopy(@NameBuf, Name, SizeOf(NameBuf) - 1);
    COM_FixSlashes(Name);

    if FS_IsAbsolutePath(Name) then
     begin
      StrLCopy(P, Name, MAX_PATH_W - 1);
      Result := NeedWrite or FS_FileExists_Internal(Name);
     end
    else
     if FS_SearchListInitialized then
      if PathID <> nil then
       Result := FS_FindFileByPathID(Name, P, NeedWrite, PathID)
      else
       Result := FS_FindFileByListScan(Name, P, NeedWrite);
   end;
 end;
end;

function FS_RemoveFile(Name: PLChar; PathID: PLChar = nil; RemoveReadOnly: Boolean = True): Boolean; // export
{$IFDEF MSWINDOWS}
var
 FullName: array[1..MAX_PATH_W] of LChar;
begin
Result := False;

if Name = nil then
 FS_Warning('Bad filename provided in FS_RemoveFile.', FSW_WARNING)
else
 if FS_FindFile(Name, FullName, True, PathID) then
  begin
   SetLastError(ERROR_SUCCESS);
   Result := DeleteFile(@FullName);
   if not Result and RemoveReadOnly and (GetLastError = ERROR_ACCESS_DENIED) then
    begin
     SetFileAttributes(@FullName, GetFileAttributes(@FullName) and not FILE_ATTRIBUTE_READONLY);
     Result := DeleteFile(@FullName);
    end;
  end;
end;
{$ELSE}
var
 FullName: array[1..MAX_PATH_W] of LChar;
begin
Result := False;

if Name = nil then
 FS_Warning('Bad filename provided in FS_RemoveFile.', FSW_WARNING)
else
 if FS_FindFile(Name, FullName, True, PathID) then
  Result := unlink(@FullName) = 0;
end;
{$ENDIF}

procedure FS_CreateDirHierarchy(Name: PLChar; PathID: PLChar = nil);
var
 FullName: array[1..MAX_PATH_W] of LChar;
 P: PLChar;
 C: LChar;
begin
if FS_FindFile(Name, FullName, True, PathID) and (FullName[1] > #0) then
 begin
  P := @FullName[2];
  repeat
   C := P^;
   if P^ = CorrectSlash then
    begin
     Inc(UInt(P));
     C := P^;
     P^ := #0;
     if not FS_DirectoryExists_Internal(@FullName) then
     {$IFDEF MSWINDOWS}
      CreateDirectory(@FullName);
     {$ELSE}
      __mkdir(@FullName, S_IRWXU or S_IRWXG or S_IRWXO);
     {$ENDIF}

     P^ := C;
     Continue;
    end;
   Inc(UInt(P));
  until C = #0;
 end;
end;

function FS_FileExists(Name: PLChar; PathID: PLChar = nil): Boolean;
var
 FullName: array[1..MAX_PATH_W] of LChar;
begin
if Name <> nil then
 Result := FS_FindFile(Name, FullName, False, PathID) and (FullName[1] > #0)
else
 begin
  FS_Warning('Bad filename provided in FS_FileExists.', FSW_WARNING);
  Result := False;
 end;
end;

function FS_IsDirectory(Name: PLChar; PathID: PLChar = nil): Boolean;
var
 FullName: array[1..MAX_PATH_W] of LChar;
begin
if Name <> nil then
 if FS_FindFile(Name, FullName, False, PathID) and (FullName[1] > #0) then
  Result := not COM_HasExtension(@FullName)
 else
  Result := False
else
 begin
  FS_Warning('Bad filename provided in FS_IsDirectory.', FSW_WARNING);
  Result := False;
 end;
end;

function FS_WriteSize_Internal(Handle: TFileInternalHandle; out Size: Int64): Boolean;
{$IFDEF MSWINDOWS}
begin
if @UCWinAPI.GetFileSizeEx = nil then
 begin
  SetLastError(ERROR_SUCCESS);
  TInt64Rec(Size).Low := GetFileSize(Handle, @TInt64Rec(Size).High);
  Result := GetLastError = ERROR_SUCCESS;
 end
else
 Result := UCWinAPI.GetFileSizeEx(Handle, @Size) > 0;

if not Result then
 Size := 0;
end;
{$ELSE}
var
 Pos: __off_t;
begin
__errno_location^ := 0;
Pos := lseek(Handle, 0, Libc.SEEK_END);
Result := errno = 0;
if Result then
 Size := PInt64(@Pos)^
else
 Size := 0;
lseek(Handle, 0, Libc.SEEK_SET);
end;
{$ENDIF}

procedure FS_WriteSettings(S: PLChar; out AccessType: TFileAccess; out AccessFlags: TFileAccessFlags);
begin
AccessType := FILE_NO_ACCESS;
AccessFlags := [];
while True do
 begin
  case S^ of
   'r': AccessType := FILE_READ;
   'w': AccessType := FILE_WRITE;
   'a': AccessType := FILE_APPEND;

   'm': Include(AccessFlags, FILE_MAPPED);
   'o': Include(AccessFlags, FILE_OVERWRITE);

   'f':
    case PLChar(UInt(S) + SizeOf(S^))^ of
     '1': Include(AccessFlags, FILE_RANDOM_ACCESS);
     '2': Include(AccessFlags, FILE_SEQUENTIAL_ACCESS);
    end;
   #0: Break;
  end;
  
  Inc(UInt(S));
 end;
end;

{$IFDEF MSWINDOWS}
function FS_OpenMapped(F: TFile; Name: PLChar; AccessType: TFileAccess; AccessFlags: TFileAccessFlags): Boolean;
var
 Handle, MapHandle: THandle;
 Data: Pointer;
 P: PFileInternal;
begin
SetLastError(ERROR_SUCCESS);
Handle := UCWinAPI.CreateFile(Name, GENERIC_READ, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL);
if (Handle <> INVALID_HANDLE_VALUE) and (GetLastError = ERROR_SUCCESS) then
 begin
  MapHandle := UCWinAPI.CreateFileMapping(Handle, PAGE_READONLY);
  if MapHandle > 0 then
   begin
    Data := MapViewOfFile(MapHandle, FILE_MAP_READ, 0, 0, 0);
    if Data <> nil then
     begin
      P := F;
      if FS_WriteSize_Internal(Handle, P.Size) then
       begin
        P.Handle := Handle;
        P.AccessType := AccessType;
        P.AccessFlags := AccessFlags;
        P.Position := 0;
        P.MappedFile := True;
        P.Data := Data;
        P.MapHandle := MapHandle;
        Result := True;
        Exit;
       end;
      UnmapViewOfFile(Data);
     end;
    CloseHandle(MapHandle);
   end;
  CloseHandle(Handle);
 end;

Result := False;
end;
{$ELSE}
// no OpenMapped on Linux.
{$ENDIF}

function FS_OpenDefault(F: TFile; Name: PLChar; AccessType: TFileAccess; AccessFlags: TFileAccessFlags): Boolean;
{$IFDEF MSWINDOWS}
type
 TFileOpenSettings = record
  FileAccess, FileCreation: UInt32;
 end;
const
 LookupTable: array[TFileAccess] of TFileOpenSettings =
              ((), // FILE_NO_ACCESS
               (FileAccess: GENERIC_READ; FileCreation: OPEN_EXISTING),
               (FileAccess: GENERIC_WRITE; FileCreation: CREATE_NEW),
               (FileAccess: GENERIC_WRITE; FileCreation: OPEN_EXISTING));
var
 P: PFileInternal;
 Entry: ^TFileOpenSettings;
 FileFlags, FileCreation: UInt32;
 Handle: THandle;
 ErrorCode: UInt32;
begin
Entry := @LookupTable[AccessType];

if (AccessType = FILE_WRITE) and (FILE_OVERWRITE in AccessFlags) then
 FileCreation := CREATE_ALWAYS
else
 if (AccessType = FILE_APPEND) and not FS_FileExists_Internal(Name) then
  FileCreation := CREATE_NEW
 else
  FileCreation := Entry.FileCreation;

FileFlags := FILE_ATTRIBUTE_NORMAL or
             (UInt32(FILE_RANDOM_ACCESS in AccessFlags) * FILE_FLAG_RANDOM_ACCESS) or
             (UInt32(FILE_SEQUENTIAL_ACCESS in AccessFlags) * FILE_FLAG_SEQUENTIAL_SCAN);

if (AccessType = FILE_WRITE) or (AccessType = FILE_APPEND) then
 FS_CreateDirHierarchy(Name);

SetLastError(ERROR_SUCCESS);
Handle := UCWinAPI.CreateFile(Name, Entry.FileAccess, FileCreation, FileFlags);
ErrorCode := GetLastError;

P := F;
if ((ErrorCode = ERROR_SUCCESS) or (ErrorCode = ERROR_ALREADY_EXISTS) or
    (ErrorCode = ERROR_FILE_EXISTS)) and (Handle <> INVALID_HANDLE_VALUE) and
    FS_WriteSize_Internal(Handle, P.Size) then
 begin
  P.Handle := Handle;
  P.AccessType := AccessType;
  P.AccessFlags := AccessFlags;
  P.MappedFile := False;
  P.Position := 0;
  P.Data := nil;
  P.MapHandle := 0;

  if AccessType = FILE_APPEND then
   FS_Seek(F, P.Size, SEEK_SET);
   
  Result := True;
 end
else
 begin
  CloseHandle(Handle);
  Result := False;
 end;
end;
{$ELSE}
var
 Handle: TFileInternalHandle;
 Flags, Mode, ErrorCode: UInt;
 P: PFileInternal;
begin
if (AccessType = FILE_WRITE) or (AccessType = FILE_APPEND) then
 begin
  Flags := O_WRONLY;
  FS_CreateDirHierarchy(Name);
 end
else
 Flags := O_RDONLY;

if FILE_OVERWRITE in AccessFlags then
 Flags := Flags or O_CREAT or O_TRUNC
else
 Flags := Flags or O_EXCL;

__errno_location^ := 0;
Handle := open(Name, Flags, S_IRWXU);
ErrorCode := errno;

P := F;
if (ErrorCode = 0) and (Handle <> High(Handle)) and FS_WriteSize_Internal(Handle, P.Size) then
 begin
  P.Handle := Handle;
  P.AccessType := AccessType;
  P.AccessFlags := AccessFlags;
  P.Position := 0;

  if AccessType = FILE_APPEND then
   FS_Seek(F, P.Size, SEEK_SET);
   
  Result := True;
 end
else
 begin
  if Handle <> High(Handle) then
   __close(Handle);
  Result := False;
 end;
end;
{$ENDIF}

function FS_OpenPathID(out F: TFile; Name, Options, PathID: PLChar): Boolean; // export
var
 FullName: array[1..MAX_PATH_W] of LChar;
 AccessType: TFileAccess;
 AccessFlags: TFileAccessFlags;
begin
Result := False;

if (@F = nil) or (Name = nil) or (Options = nil) then
 FS_Warning('Bad parameters specified in FS_OpenPathID.', FSW_WARNING)
else
 begin
  F := EngineInput.MemAlloc(SizeOf(TFileInternal));
  MemSet(F^, SizeOf(TFileInternal), 0);
  if F = nil then
   FS_Warning('FS_OpenPathID: Out of memory.', FSW_WARNING)
  else
   begin
    FS_WriteSettings(Options, AccessType, AccessFlags);

    if (AccessType <> FILE_NO_ACCESS) and FS_FindFile(Name, FullName, (AccessType = FILE_WRITE) or (AccessType = FILE_APPEND), PathID) and
       (FullName[1] > #0) then {$IFDEF MSWINDOWS}
     if (FILE_MAPPED in AccessFlags) and (AccessType = FILE_READ) then
      Result := FS_OpenMapped(F, @FullName, AccessType, AccessFlags)
     else {$ENDIF}
      Result := FS_OpenDefault(F, @FullName, AccessType, AccessFlags);

    if not Result then
     begin
      EngineInput.MemFree(F);
      F := nil;
     end;
   end;
 end;
end;

function FS_Open(out F: TFile; Name, Options: PLChar): Boolean;
begin
Result := FS_OpenPathID(F, Name, Options, nil);
end;

procedure FS_Close(F: TFile);
{$IFDEF MSWINDOWS}
var
 P: PFileInternal;
begin
if F = nil then
 FS_Warning('Bad file handle specified in FS_Close.', FSW_WARNING)
else
 begin
  P := F;
  if P.MappedFile then
   begin
    if P.Data <> nil then
     UnmapViewOfFile(P.Data);
    if P.MapHandle > 0 then
     CloseHandle(P.MapHandle);
   end;

  if P.Handle > 0 then
   CloseHandle(P.Handle);

  EngineInput.MemFree(P);
 end;
end;
{$ELSE}
var
 P: PFileInternal;
begin
if F = nil then
 FS_Warning('Bad file handle specified in FS_Close.', FSW_WARNING)
else
 begin
  P := F;
  if P.Handle > 0 then
   __close(P.Handle);
  EngineInput.MemFree(P);
 end;
end;
{$ENDIF}

function FS_Seek(F: TFile; Offset: Int64; SeekType: TFileSeekType): Boolean;
{$IFDEF MSWINDOWS}
var
 HighPart: UInt32;
 P: PFileInternal;
begin
Result := False;

if FS_CheckFile(F, 'FS_Seek') then
 if (SeekType < Low(SeekType)) or (SeekType > High(SeekType)) then
  FS_Warning('Bad seek type specified in FS_Seek.', FSW_WARNING)
 else
  begin
   P := F;
   if SeekType = SEEK_CURRENT then
    Inc(Offset, P.Position)
   else
    if SeekType = SEEK_END then
     Inc(Offset, P.Size);

   if (Offset < 0) or (P.MappedFile and (Offset >= P.Size)) then
    Result := False
   else
    begin
     if P.MappedFile then
      P.Position := Offset
     else
      begin
       HighPart := TInt64Rec(Offset).High;
       PInt64Rec(@P.Position).Low := SetFilePointer(P.Handle, TInt64Rec(Offset).Low, @HighPart, FILE_BEGIN);
       PInt64Rec(@P.Position).High := HighPart;
      end;

     Result := True;
    end;
  end;
end;
{$ELSE}
var
 P: PFileInternal;
 Pos: __off_t;
begin
Result := False;

if FS_CheckFile(F, 'FS_Seek') then
 if (SeekType < Low(SeekType)) or (SeekType > High(SeekType)) then
  FS_Warning('Bad seek type specified in FS_Seek.', FSW_WARNING)
 else
  begin
   P := F;
   if SeekType = SEEK_CURRENT then
    Inc(Offset, P.Position)
   else
    if SeekType = SEEK_END then
     Inc(Offset, P.Size);

   if Offset >= 0 then
    begin
     {$IF SizeOf(__off_t) = 4)}
      Pos := lseek(P.Handle, TInt64Rec(Offset).Low, Libc.SEEK_SET);
      if Pos <> __off_t(-1) then
       begin
        PInt64Rec(@P.Position).Low := PInt64Rec(@Pos).Low;
        PInt64Rec(@P.Position).High := 0;
       end;
     {$ELSE}
      Pos := lseek64(P.Handle, TOff(Offset), Libc.SEEK_SET);
      if Pos <> __off_t(-1) then
       begin
        PInt64Rec(@P.Position).Low := PInt64Rec(@Pos).Low;
        PInt64Rec(@P.Position).High := PInt64Rec(@Pos).High;
       end;
     {$IFEND}

     P.Position := Offset;
     Result := True;
    end;
  end;
end;
{$ENDIF}

function FS_Tell(F: TFile): Int64;
begin
if FS_CheckFile(F, 'FS_Seek') then
 Result := PFileInternal(F).Position
else
 Result := 0;
end;

function FS_Size(F: TFile): Int64;
begin
if FS_CheckFile(F, 'FS_Size') then
 Result := PFileInternal(F).Size
else
 Result := 0;
end;

function FS_SizeByName(Name: PLChar; PathID: PLChar): Int64;
{$IFDEF MSWINDOWS}
var
 FullName: array[1..MAX_PATH_W] of LChar;
 Handle: THandle;
 SearchRec: TWin32FindDataA;
begin
Result := 0;

if Name = nil then
 FS_Warning('Bad filename specified in FS_Size.', FSW_WARNING)
else
 if FS_FindFile(Name, FullName, False, PathID) and (FullName[Low(FullName)] > #0) then
  begin
   SetLastError(ERROR_SUCCESS);
   Handle := FindFirstFileA(@FullName, SearchRec);
   if Handle <> INVALID_HANDLE_VALUE then
    begin
     if GetLastError = ERROR_SUCCESS then
      begin
       TInt64Rec(Result).Low := SearchRec.nFileSizeLow;
       TInt64Rec(Result).High := SearchRec.nFileSizeHigh;
      end;

     Windows.FindClose(Handle);
    end;
  end;
end;
{$ELSE}
var
 FullName: array[1..MAX_PATH_W] of LChar;
 Buf: _stat;
begin
Result := 0;

if Name = nil then
 FS_Warning('Bad filename specified in FS_Size.', FSW_WARNING)
else
 if FS_FindFile(Name, FullName, False, PathID) and (FullName[Low(FullName)] > #0) then
  begin
   __errno_location^ := 0;
   if (stat(@FullName, Buf) = 0) and (errno = 0) then
    Result := Buf.st_size;
  end;
end;
{$ENDIF}

function FS_GetFileTime(Name: PLChar; PathID: PLChar = nil): Int64;
{$IFDEF MSWINDOWS}
var
 FullName: array[1..MAX_PATH_W] of LChar;
 Data: TWin32FileAttributeData;
begin
Result := 0;

if Name = nil then
 FS_Warning('Bad filename specified in FS_GetFileTime.', FSW_WARNING)
else
 if FS_FindFile(Name, FullName, False, PathID) and (FullName[Low(FullName)] > #0) and
    GetFileAttributesEx(@FullName, GetFileExInfoStandard, @Data) then
  begin
   Result := Int64(Data.ftLastWriteTime);
   if Result = 0 then
    Result := 1;
  end;
end;
{$ELSE}
var
 FullName: array[1..MAX_PATH_W] of LChar;
 Buf: _stat;
begin
Result := 0;

if Name = nil then
 FS_Warning('Bad filename specified in FS_GetFileTime.', FSW_WARNING)
else
 if FS_FindFile(Name, FullName, False, PathID) and (FullName[Low(FullName)] > #0) then
  begin
   __errno_location^ := 0;
   if (stat(@FullName, Buf) = 0) and (errno = 0) then
    Result := Buf.st_mtime;
  end;
end;
{$ENDIF}

function FS_IsOK(F: TFile): Boolean;
var
 P: PFileInternal;
begin
P := F;
Result := (F <> nil) and (P.Handle > 0){$IFDEF MSWINDOWS} and (not P.MappedFile or (P.MapHandle > 0)){$ENDIF};
end;

procedure FS_Flush(F: TFile);
{$IFDEF MSWINDOWS}
var
 P: PFileInternal;
begin
P := F;
if FS_CheckFile(F, 'FS_Flush') then
 if P.MappedFile then
  FlushViewOfFile(P.Data, 0)
 else
  FlushFileBuffers(P.Handle);
end;
{$ELSE}
begin
if FS_CheckFile(F, 'FS_Flush') then
 fsync(PFileInternal(F).Handle);
end;
{$ENDIF}

function FS_EndOfFile(F: TFile): Boolean;
begin
if FS_CheckFile(F, 'FS_EndOfFile') then
 Result := PFileInternal(F).Position >= PFileInternal(F).Size
else
 Result := False;
end;

function FS_Read(F: TFile; Buffer: Pointer; Size: UInt): UInt;
const
 SingleRead = 8192;
var
 BytesRead, RemainingBytes, BytesInThisRead: UInt;
 BytesActuallyRead: UInt32;
 P: PFileInternal;
begin
BytesRead := 0;
P := F;

if (Buffer = nil) or (Size = 0) then
 FS_Warning('Bad parameters provided in FS_Read.', FSW_WARNING)
else
 if not FS_CheckFile(F, 'FS_Read') then
  MemSet(Buffer^, Size, 0)
 else
  begin
   {$IFDEF MSWINDOWS}
   if P.MappedFile then
    begin
     BytesRead := Min(Size, P.Size - P.Position);
     if BytesRead > 0 then
      begin
       Move(Pointer(UInt(P.Data) + P.Position)^, Buffer^, BytesRead);
       Inc(P.Position, BytesRead);
      end;
    end
   else
   {$ENDIF}
    begin
     RemainingBytes := Size;
             
     while RemainingBytes > 0 do
      begin
       if RemainingBytes >= SingleRead then
        BytesInThisRead := SingleRead
       else
        BytesInThisRead := RemainingBytes;

       {$IFDEF MSWINDOWS}
        ReadFile(P.Handle, Pointer(UInt(Buffer) + BytesRead)^, BytesInThisRead, BytesActuallyRead, nil);
       {$ELSE}
        BytesActuallyRead := __read(P.Handle, Pointer(UInt(Buffer) + BytesRead)^, BytesInThisRead);
       {$ENDIF}
       
       if BytesActuallyRead = 0 then
        Break;
       Inc(P.Position, BytesActuallyRead);
       Inc(BytesRead, BytesActuallyRead);
       Dec(RemainingBytes, BytesInThisRead);
      end;
    end;

   if BytesRead < Size then
    MemSet(Pointer(UInt(Buffer) + BytesRead)^, Size - BytesRead, 0);
  end;

Result := BytesRead;
end;

function FS_Write(F: TFile; Buffer: Pointer; Size: UInt): UInt;
const
 SingleWrite = 8192;
var
 BytesWritten, RemainingBytes, BytesInThisWrite: UInt;
 BytesActuallyWritten: UInt32;
 P: PFileInternal;
begin
BytesWritten := 0;
P := F;

if (Buffer = nil) or (Size = 0) then
 FS_Warning('Bad parameters provided in FS_Write.', FSW_WARNING)
else
 if FS_CheckFile(F, 'FS_Write') then
  {$IFDEF MSWINDOWS}
  if P.MappedFile then
   FS_Warning('Can''t write data in mapped file.', FSW_WARNING)
  else {$ENDIF}
   begin
    RemainingBytes := Size;

    while RemainingBytes > 0 do
     begin
      if RemainingBytes >= SingleWrite then
       BytesInThisWrite := SingleWrite
      else
       BytesInThisWrite := RemainingBytes;

      {$IFDEF MSWINDOWS}
       WriteFile(P.Handle, Pointer(UInt(Buffer) + BytesWritten)^, BytesInThisWrite, BytesActuallyWritten, nil);
      {$ELSE}
       BytesActuallyWritten := __write(P.Handle, Pointer(UInt(Buffer) + BytesWritten)^, BytesInThisWrite);
      {$ENDIF}
      if BytesActuallyWritten = 0 then
       Break;
      Inc(P.Position, BytesActuallyWritten);
      Inc(BytesWritten, BytesActuallyWritten);
      Dec(RemainingBytes, BytesInThisWrite);
     end;

    FS_WriteSize_Internal(P.Handle, P.Size); 
   end;

Result := BytesWritten;
end;

function FS_ReadLine(F: TFile; Buffer: Pointer; MaxChars: UInt): PLChar;
var
 BytesRead, I: UInt;
 Pos: Int64;
begin
Result := nil;

if (Buffer = nil) or (MaxChars = 0) then
 FS_Warning('Bad parameters provided in FS_ReadLine.', FSW_WARNING)
else
 if FS_CheckFile(F, 'FS_ReadLine') then
  begin
   Pos := FS_Tell(F);
   BytesRead := FS_Read(F, Buffer, MaxChars);
   if BytesRead < MaxChars then
    PLChar(UInt(Buffer) + BytesRead)^ := #0
   else
    PLChar(UInt(Buffer) + MaxChars - 1)^ := #0;

   for I := 0 to MaxChars - 1 do
    if PLChar(UInt(Buffer) + I)^ < ' ' then
     begin
      FS_Seek(F, Pos + I + 1, SEEK_SET);
      PLChar(UInt(Buffer) + I)^ := #0;
      Break;
     end;

   Result := Buffer;
  end;
end;

procedure FS_WriteLine(F: TFile; S: PLChar; NeedLineBreak: Boolean = True);
const
 LineBreak: UInt16 = {$IFDEF MSWINDOWS}$A0D{$ELSE}$A{$ENDIF};
var
 BytesWritten, L: UInt;
begin
if FS_CheckFile(F, 'FS_WriteString') then
 begin
  if S <> nil then
   begin
    L := StrLen(S);
    BytesWritten := FS_Write(F, S, L);
    if BytesWritten < L then
     Exit;
   end;

  if NeedLineBreak then
   FS_Write(F, @LineBreak, SizeOf(LineBreak));
 end;
end;

function FS_FPrintF(F: TFile; S: PLChar; NeedLineBreak: Boolean = True): UInt; overload;
begin
FS_WriteLine(F, S, NeedLineBreak);
Result := StrLen(S);
end;

function FS_FindFirst(Name: PLChar; out H: TFileFindHandle): PLChar;
begin
Result := nil;

if Name = nil then
 FS_Warning('Bad filename specified in FS_FindFirst.', FSW_WARNING)
else
 if @H = nil then
  FS_Warning('Bad find handle specified in FS_FindFirst.', FSW_WARNING)
 else
  begin
   FS_Warning('FS_FindFirst: Not implemented.', FSW_WARNING);
  end;
end;

function FS_FindNext(H: TFileFindHandle): PLChar;
begin
Result := nil;
if H = nil then
 FS_Warning('Bad find handle specified in FS_FindNext.', FSW_WARNING)
else
 begin
  FS_Warning('FS_FindNext: Not implemented.', FSW_WARNING);
 end;
end;

function FS_FindIsDirectory(H: TFileFindHandle): Boolean;
begin
Result := False;
if H = nil then
 FS_Warning('Bad find handle specified in FS_FindIsDirectory.', FSW_WARNING)
else
 begin
  FS_Warning('FS_FindIsDirectory: Not implemented.', FSW_WARNING);
 end;
end;

procedure FS_FindClose(H: TFileFindHandle);
begin
if H = nil then
 FS_Warning('Bad find handle specified in FS_FindClose.', FSW_WARNING)
else
 begin
  FS_Warning('FS_FindClose: Not implemented.', FSW_WARNING);
 end;
end;

procedure FS_GetLocalCopy(Name: PLChar);
begin

end;

function FS_GetLocalPath(Name: PLChar): PLChar;
var
 P: PFileSearchPath;
 NameBuf, FullNameBuf: array[1..MAX_PATH_W] of LChar;
 S: PLChar;
begin
if Name = nil then
 FS_Warning('Bad file name provided in FS_GetLocalPath.', FSW_WARNING)
else
 begin
  Name := StrLCopy(@NameBuf, Name, SizeOf(NameBuf) - 1);
  COM_FixSlashes(Name);

  P := SearchBase;
  while P <> nil do
   begin
    S := StrLECopy(@FullNameBuf, P.Path, SizeOf(FullNameBuf) - 1);
    StrLCopy(S, @NameBuf, SizeOf(FullNameBuf) - 1 - (UInt(S) - UInt(@FullNameBuf)));
    if FS_FileExists_Internal(@FullNameBuf) then
     begin
      Result := P.Path;
      Exit;
     end;

    P := P.Prev;
   end;
 end;

Result := nil;
end;

function FS_ParseFile(Data: Pointer; Token: PLChar; WasQuoted: PBoolean): Pointer;
const
 BreakSetColons: set of LChar = ['{', '}', '(', ')', '''', ':'];
var
 C: LChar;
 L: UInt;
 P: Pointer;
begin
if WasQuoted <> nil then
 WasQuoted^ := False;

if (Data <> nil) and (Token <> nil) then
 begin
  C := #0;

  while True do
   begin
    C := PLChar(Data)^;
    while C <= ' ' do
     if C = #0 then
      begin
       Result := nil;
       Exit;
      end
     else
      begin
       Inc(UInt(Data));
       C := PLChar(Data)^;
      end;

    if C = '/' then
     if PLChar(UInt(Data) + 1)^ = '/' then
      while C <> #$A do
       if C = #0 then
        begin
         Result := nil;
         Exit;
        end
       else
        begin
         Inc(UInt(Data));
         C := PLChar(Data)^;
        end
     else
      if PLChar(UInt(Data) + 1)^ = '*' then
       begin
        Inc(UInt(Data), 2);
        C := PLChar(Data)^;

        while (C <> '*') or (PLChar(UInt(Data) + 1)^ <> '/') do
         if C = #0 then
          begin
           Result := nil;
           Exit;
          end
         else
          begin
           Inc(UInt(Data));
           C := PLChar(Data)^;
          end;

        Inc(UInt(Data), 2);
        C := PLChar(Data)^;
       end
      else
       Break
    else
     Break;
   end;

  L := 0;

  if C = '"' then
   begin
    if WasQuoted <> nil then
     WasQuoted^ := True;

    P := Pointer(UInt(Data) + 1);

    while True do
     begin
      Inc(UInt(Data));
      C := PLChar(Data)^;

      if (C = #0) or (C = '"') then
       begin
        if L > 0 then
         Move(P^, Token^, L)
        else
         Token^ := #0;

        Result := Data;
        Exit;
       end;

      Inc(L);
     end;
   end;

  if C in BreakSetColons then
   begin
    PUInt16(Token)^ := UInt16(C);
    Result := Pointer(UInt(Data) + 1);    
   end
  else
   begin
    P := Data;
    
    repeat
     Inc(UInt(Data));
     C := PLChar(Data)^;
     Inc(L);
    until (C <= ' ') or (C in BreakSetColons);

    Move(P^, Token^, L);
    Result := Data;
   end;
 end
else
 Result := Data;
end;

procedure FS_GetCurrentDirectory(Buf: PLChar; MaxLen: UInt);
begin
FS_Warning('FS_GetCurrentDirectory is not yet implemented.', FSW_WARNING)
end;

procedure FS_SetWarningLevel(Level: TFileWarningLevel);
begin
if (Level >= Low(Level)) and (Level <= High(Level)) then
 WarningLevel := Level
else
 FS_Warning('Bad warning level specified in FS_SetWarningLevel.', FSW_WARNING)
end;

function FS_GetCharacter(F: TFile): LChar;
begin
if FS_Read(F, @Result, SizeOf(Result)) < SizeOf(Result) then
 Result := #0;
end;

procedure FS_LogLevelLoadStarted(Name: PLChar);
begin

end;

procedure FS_LogLevelLoadFinished(Name: PLChar);
begin

end;

function FS_GetInterfaceVersion: PLChar;
begin
{$IFDEF MSWINDOWS}
 {$IFDEF CPU64}
  Result := 'Native (built-in) win64';
 {$ELSE}
  Result := 'Native (built-in) win32';
 {$ENDIF}                              
{$ELSE}
 {$IFDEF CPU64}
  Result := 'Native (built-in) linux64 libc';
 {$ELSE}
  Result := 'Native (built-in) linux32 libc';
 {$ENDIF}
{$ENDIF}
end;

procedure FS_Unlink(Name: PLChar);
begin
FS_RemoveFile(Name, nil);
end;

procedure FS_Rename(OldPath, NewPath: PLChar);
var
 OldPathBuf, NewPathBuf, FullNameBuf: array[1..MAX_PATH_W] of LChar;
 S, S2: PLChar;
 P: PFileSearchPath;
begin
if (OldPath = nil) or (NewPath = nil) then
 FS_Warning('Bad parameters provided in FS_Rename', FSW_WARNING)
else
 begin
  StrLCopy(@OldPathBuf, OldPath, SizeOf(OldPathBuf) - 1);
  COM_FixSlashes(@OldPathBuf);
  StrLCopy(@NewPathBuf, NewPath, SizeOf(NewPathBuf) - 1);
  COM_FixSlashes(@NewPathBuf);

  P := SearchBase;
  while P <> nil do
   begin
    S := StrLECopy(@FullNameBuf, P.Path, MAX_PATH_W - 1);
    StrLCopy(S, @OldPathBuf, MAX_PATH_W - 1 - (UInt(S) - UInt(@FullNameBuf)));
    if FS_FileExists_Internal(S) then
     begin
      S2 := StrLECopy(@OldPathBuf, P.Path, MAX_PATH_W - 1);
      StrLCopy(S2, @NewPathBuf, MAX_PATH_W - 1 - (UInt(S2) - UInt(@OldPathBuf)));
      {$IFDEF MSWINDOWS}
       RenameFile(S, S2);
      {$ELSE}
       __rename(S, S2);
      {$ENDIF}
      Exit;
     end;
   end;
 end;
end;

procedure FS_PrintSP_F; cdecl;
var
 P: PFileSearchPath;
 I: UInt;
begin
P := SearchBase;
I := 1;
while P <> nil do
 begin
  FS_Warning(['#', I, ': Path = ', P.Path, '; Name = ', P.Name, '; NW = ', UInt(sfNoWrite in P.Flags), '; AL = ', UInt(sfAddToBase in P.Flags), '.'], FSW_SILENT);
  Inc(I);
  P := P.Prev;
 end;
end;

procedure FS_PrintFiles_F; cdecl;
begin

end;

procedure FS_Init; // export
begin
InitDone := True;
end;

procedure FS_Shutdown; // export
begin
if InitDone then
 begin
  MemSet(EngineInput, SizeOf(EngineInput), 0);
  InitDone := False;
 end;
end;

var
 FSInterface: TFileSystem =
  (Init: FS_Init;
   Shutdown: FS_Shutdown;
   RemoveAllSearchPaths: FS_RemoveAllSearchPaths;
   AddSearchPath: FS_AddSearchPath;
   AddSearchPathNoWrite: FS_AddSearchPathNoWrite;
   RemoveSearchPath: FS_RemoveSearchPath;
   SearchListInitialized: FS_SearchListInitialized;
   IsAbsolutePath: FS_IsAbsolutePath;
   RemoveFile: FS_RemoveFile;
   CreateDirHierarchy: FS_CreateDirHierarchy;
   FileExists: FS_FileExists;
   IsDirectory: FS_IsDirectory;
   OpenPathID: FS_OpenPathID;
   Open: FS_Open;
   Close: FS_Close;
   Seek: FS_Seek;
   Tell: FS_Tell;
   Size: FS_Size;
   SizeByName: FS_SizeByName;
   GetFileTime: FS_GetFileTime;
   IsOK: FS_IsOK;
   Flush: FS_Flush;
   EndOfFile: FS_EndOfFile;
   Read: FS_Read;
   Write: FS_Write;
   ReadLine: FS_ReadLine;
   WriteLine: FS_WriteLine;
   FPrintF: FS_FPrintF;
   FindFirst: FS_FindFirst;
   FindNext: FS_FindNext;
   FindIsDirectory: FS_FindIsDirectory;
   FindClose: FS_Close;
   GetLocalCopy: FS_GetLocalCopy;
   GetLocalPath: FS_GetLocalPath;
   ParseFile: FS_ParseFile;
   GetCurrentDirectory: FS_GetCurrentDirectory;
   SetWarningLevel: FS_SetWarningLevel;
   GetCharacter: FS_GetCharacter;
   LogLevelLoadStarted: FS_LogLevelLoadStarted;
   LogLevelLoadFinished: FS_LogLevelLoadFinished;
   GetInterfaceVersion: FS_GetInterfaceVersion;
   Unlink: FS_Unlink;
   Rename: FS_Rename);

function FS_SetupInterface(const Input: TFileSystemInput): PFileSystem;
begin
if (@Input = nil) or (@Input.MemAlloc = nil) or (@Input.MemFree = nil) then
 Result := nil
else
 begin
  Move(Input, EngineInput, SizeOf(EngineInput));
  Result := @FSInterface;
 end;
end;

end.
