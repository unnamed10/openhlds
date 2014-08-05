unit Common;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS} Windows, {$ELSE} Libc, {$ENDIF} Default, SDK;

function BuildNumber: UInt;
function GetGameAppID: UInt;
procedure SetCStrikeFlags;

procedure SeedRandomNumberGenerator;
function RandomFloat(Low, High: Single): Single;
function RandomLong(Low, High: Int32): Int32;

function COM_Nibble(C: LChar): Byte;
procedure COM_HexConvert(Input: PLChar; InputLength: UInt; Output: PLChar);
function COM_IntToHex(Val: UInt32; out Buf): PLChar;

function COM_SkipPath(S: PLChar): PLChar;
procedure COM_StripExtension(Source, Dest: PLChar);
function COM_FileExtension(Name: PLChar; Buffer: PLChar; BufLen: UInt): UInt;
function COM_FileBase(Name, Buf: PLChar): PLChar;
procedure COM_DefaultExtension(Name, Extension: PLChar);
procedure COM_StripTrailingSlash(S: PLChar);
function COM_HasExtension(S: PLChar): Boolean;

procedure COM_UngetToken;
function COM_Parse(Data: Pointer): Pointer;
function COM_ParseLine(Data: Pointer): Pointer;
function COM_TokenWaiting(Data: Pointer): Boolean;

procedure COM_WriteFile(Name: PLChar; Buffer: Pointer; Size: UInt);
procedure COM_FixSlashes(S: PLChar);
procedure COM_CreatePath(S: PLChar);
procedure COM_CopyFile(Source, Dest: PLChar);
function COM_FileSize(Name: PLChar): Int64;
function COM_LoadFile(Name: PLChar; AllocType: TFileAllocType; Length: PUInt32): Pointer;
procedure COM_FreeFile(Buffer: Pointer);
procedure COM_CopyFileChunk(Dest, Source: TFile; Size: Int64);
function COM_LoadFileLimit(Name: PLChar; SeekPos, MaxSize: Int64; Length: PInt64; var FilePtr: TFile): Pointer;
function COM_LoadHunkFile(Name: PLChar): Pointer;
function COM_LoadTempFile(Name: PLChar; Length: PUInt32): Pointer;
function COM_LoadCacheFile(Name: PLChar; Cache: PCacheUser): Pointer;
function COM_LoadStackFile(Name: PLChar; Buffer: Pointer; Size: UInt): Pointer;
function COM_LoadFileForMe(Name: PLChar; Length: PUInt32): Pointer;
procedure COM_Log(FileName, Data: PLChar); overload;
procedure COM_Log(FileName: PLChar; const Data: array of const); overload;
function COM_CompareFileTime(S1, S2: PLChar; out CompareResult: Int32): Boolean;

procedure COM_AddAppDirectory(Name: PLChar);
function COM_AddDefaultDir(Name: PLChar): Boolean;
procedure COM_GetGameDir(Buf: PLChar);

procedure COM_ListMaps(S: PLChar);
procedure COM_PrintBSPVersion(Buffer: Pointer; Name: PLChar; WriteOutdated: Boolean);
function IsMapValid(Name: PLChar): Boolean;

procedure COM_Munge(Data: Pointer; Length: UInt; Sequence: Int32);
procedure COM_UnMunge(Data: Pointer; Length: UInt; Sequence: Int32);
procedure COM_Munge2(Data: Pointer; Length: UInt; Sequence: Int32);
procedure COM_UnMunge2(Data: Pointer; Length: UInt; Sequence: Int32);
procedure COM_Munge3(Data: Pointer; Length: UInt; Sequence: Int32);
procedure COM_UnMunge3(Data: Pointer; Length: UInt; Sequence: Int32);

function ShortNoSwap(L: Int16): Int16;
function LongNoSwap(L: Int32): Int32;
function FloatNoSwap(F: Single): Single;

procedure ClearLink(var L: TLink);
procedure RemoveLink(var L: TLink);
procedure InsertLinkBefore(var L, L2: TLink);
procedure InsertLinkAfter(var L, L2: TLink);
function EdictFromArea(const L: TLink): PEdict;
function FilterGroup(const E1, E2: TEdict): Boolean; overload;
function FilterGroup(I1, I2: Int): Boolean; overload;

function COM_EntsForPlayerSlots(Count: UInt): UInt;
procedure COM_NormalizeAngles(var Angles: TVec3);
function COM_GetApproxWavePlayLength(Name: PLChar): UInt;
function PR_IsEmptyString(S: PLChar): Boolean;
procedure TrimSpace(Src, Dst: PLChar);

procedure COM_Init;
procedure COM_Shutdown;

var
 COM_Token: array[1..1024] of LChar;
 COM_IgnoreColons: Boolean = False;

 BigEndian: Boolean;

 BigShort: function(L: Int16): Int16 = ShortNoSwap;
 LittleShort: function(L: Int16): Int16 = ShortNoSwap;
 BigLong: function(L: Int32): Int32 = LongNoSwap;
 LittleLong: function(L: Int32): Int32 = LongNoSwap;
 BigFloat: function(F: Single): Single = FloatNoSwap;
 LittleFloat: function(F: Single): Single = FloatNoSwap;

 com_filewarning: TCVar = (Name: 'com_filewarning'; Data: '0');

implementation

uses Console, FileSys, Host, Memory, MsgBuf, SysArgs, SysMain, SVWorld;

type
 PPacketEncodeTable = ^TPacketEncodeTable;
 TPacketEncodeTable = packed array[0..15] of Byte;

const
 EncodeTable1: TPacketEncodeTable = ($7A, $64, $05, $F1, $1B, $9B, $A0, $B5, $CA, $ED, $61, $0D, $4A, $DF, $8E, $C7);
 EncodeTable2: TPacketEncodeTable = ($05, $61, $7A, $ED, $1B, $CA, $0D, $9B, $4A, $F1, $64, $C7, $B5, $8E, $DF, $A0);
 EncodeTable3: TPacketEncodeTable = ($20, $07, $13, $61, $03, $45, $17, $72, $0A, $2D, $48, $0C, $4A, $12, $A9, $B5);

var
 IR: Int32 = 0;
 IV: array[0..31] of Int32;
 IY: UInt32 = 0;

 UngetToken: Boolean = False;

 LoadCache: PCacheUser;
 LoadSize: UInt;
 LoadBuffer: Pointer;

function BuildNumber: UInt;
begin
Result := ProjectBuild;
end;

procedure SeedRandomNumberGenerator;
var
 I: Int32;
begin
{$IFDEF MSWINDOWS}
 I := -GetTickCount;
{$ELSE}
 I := -Int32(__time(nil));
{$ENDIF};

if I <= 1000 then
 if I > -1000 then
  IR := I - 22261048
 else
  IR := I
else
 IR := -I;
end;

function Random1: Int32;
var
 I: UInt32;
 K: Int32;
begin
if (IR <= 0) or (IY = 0) then
 begin
  if IR < 0 then
   IR := -IR
  else
   IR := 1;

  for I := 39 downto 0 do
   begin
    K := IR div 127773;
    IR := 16807 * (IR - K * 127773) - 2836 * K;
    if IR < 0 then
     Inc(IR, 2147483647);
    if I <= High(IV) then
     IV[I] := IR;
   end;

  IY := IV[Low(IV)];
 end;

K := IR div 127773;
IR := 16807 * (IR - K * 127773) - 2836 * K;
if IR < 0 then
 Inc(IR, 2147483647);

I := IY shr $1A;
IY := IV[I];
IV[I] := IR;
Result := IY;
end;

function FRandom1: Single;
begin
Result := Random1 * (1 / High(Int32));
if Result > (1 - 1.2E-7) then
 Result := 1 - 1.2E-7;
end;

function RandomFloat(Low, High: Single): Single;
begin
Result := (High - Low) * FRandom1 + Low;
end;

function RandomLong(Low, High: Int32): Int32;
var
 Spread: Int32;
 I, K: UInt32;
begin
Spread := High - Low + 1;
if Spread <= 0 then
 Result := Low
else
 begin
  I := $7FFFFFFF - ($80000000 mod UInt32(Spread));
  repeat
   K := Random1;
  until K <= I;
  Result := Low + (Int32(K) mod Spread);
 end;
end;

function GetGameAppID: UInt;
const
 GameIDTable: array[1..11] of packed record ID: UInt; Name: PLChar end =
              ((ID: 10; Name: 'cstrike'),
               (ID: 20; Name: 'tfc'),
               (ID: 30; Name: 'dod'),
               (ID: 40; Name: 'dmc'),
               (ID: 50; Name: 'gearbox'),
               (ID: 60; Name: 'ricochet'),
               (ID: 70; Name: 'valve'),
               (ID: 80; Name: 'czero'),
               (ID: 100; Name: 'czeror'),
               (ID: 130; Name: 'bshift'),
               (ID: 150; Name: 'cstrike_beta'));
var
 I: Int;
begin
for I := Low(GameIDTable) to High(GameIDTable) do
 if StrIComp(GameDir, GameIDTable[I].Name) = 0 then
  begin
   Result := GameIDTable[I].ID;
   Exit;
  end;

Result := 70;
end;

procedure SetCStrikeFlags;
begin
if not CSFlagsInitialized then
 begin
  if (StrIComp(GameDir, 'cstrike') = 0) or (StrIComp(GameDir, 'cstrike_beta') = 0) then
   IsCStrike := True
  else
   if StrIComp(GameDir, 'czero') = 0 then
    IsCZero := True
   else
    if StrIComp(GameDir, 'czeror') = 0 then
     IsCZeroRitual := True
    else
     if StrIComp(GameDir, 'terror') = 0 then
      IsTerrorStrike := True;
  
  CSFlagsInitialized := True;
 end;
end;

function COM_Nibble(C: LChar): Byte;
begin
if (C >= '0') and (C <= '9') then
 Result := Ord(C) - Ord('0')
else
 if (C >= 'A') and (C <= 'F') then
  Result := Ord(C) - Ord('A') + $A
 else
  if (C >= 'a') and (C <= 'f') then
   Result := Ord(C) - Ord('a') + $A
  else
   Result := Ord('0');
end;

procedure COM_HexConvert(Input: PLChar; InputLength: UInt; Output: PLChar);
var
 I: UInt;
begin
I := 0;
while I < InputLength do
 begin
  PByte(Output)^ := (COM_Nibble(PLChar(UInt(Input) + I)^) shl 4) or
                    (COM_Nibble(PLChar(UInt(Input) + I + 1)^));
  Inc(I, 2);
  Inc(UInt(Output));
 end;
end;

function COM_SkipPath(S: PLChar): PLChar;
begin
Result := S;

while S^ > #0 do
 begin
  if S^ in ['/', '\'] then
   Result := PLChar(UInt(S) + SizeOf(LChar));

  Inc(UInt(S));
 end;
end;

procedure COM_StripExtension(Source, Dest: PLChar);
var
 C: LChar;
 I, L: UInt;
begin
L := StrLen(Source);
PLChar(UInt(Dest) + L)^ := #0;

if L > 0 then
 begin
  for I := L - 1 downto 0 do
   begin
    C := PLChar(UInt(Source) + I)^;
    PLChar(UInt(Dest) + I)^ := #0;
    if C = '.' then
     begin
      Move(Source^, Dest^, I);
      Exit;
     end
    else
     if (C = '\') or (C = '/') then
      Break;
   end;
   
  Move(Source^, Dest^, L + 1);
 end
else
 MemSet(Dest^, L + 1, 0);
end;

function COM_FileExtension(Name: PLChar; Buffer: PLChar; BufLen: UInt): UInt;
var
 I, L: UInt;
begin
if (Name = nil) or (Buffer = nil) or (BufLen = 0) then
 Sys_Error('COM_FileExtension: Invalid parameters.');

Buffer^ := #0;
Result := 0;

L := StrLen(Name);
for I := L downto 1 do
 case PLChar(UInt(Name) + I - 1)^ of
  '\', '/', ':': Break;
  '.':
   begin
    if I < L then
     begin
      Result := L - I; // actual extension length
      L := Min(Result, BufLen - 1); // req length
      Move(PLChar(UInt(Name) + I)^, Buffer^, L);
      PLChar(UInt(Buffer) + L)^ := #0;
     end;
    Break;
   end;
 end;
end;

function COM_FileBase(Name, Buf: PLChar): PLChar;
var
 I, L, B, E: UInt;
 C: LChar;
begin
L := StrLen(Name);
if L = 0 then
 Buf^ := #0
else
 begin
  B := 0;
  E := L - 1;
  for I := L - 1 downto 0 do
   begin
    C := PLChar(UInt(Name) + I)^;
    if (C = '\') or (C = '/') then
     begin
      B := I + 1;
      Break;
     end
    else
     if (C = '.') and (E = L - 1) then
      if I = 0 then
       E := 0
      else
       E := I - 1;
   end;

  L := E - B + 1;
  Move(PLChar(UInt(Name) + B)^, Buf^, L);
  PLChar(UInt(Buf) + L)^ := #0;
 end;

Result := Buf;
end;

procedure COM_DefaultExtension(Name, Extension: PLChar);
var
 I, L: UInt;
begin
L := StrLen(Name);
if L > 0 then
 for I := L - 1 downto 0 do
  case PLChar(UInt(Name) + I)^ of
   '\', '/', ':': Break;
   '.': Exit;
  end;

StrLCat(Name, Extension, MAX_PATH_W - 1);
end;

procedure COM_UngetToken;
begin
UngetToken := True;
end;

function COM_Parse(Data: Pointer): Pointer;
var
 C: LChar;
 L: UInt;
begin
if UngetToken then
 begin
  UngetToken := False;
  Result := Data;
 end
else
 begin
  COM_Token[Low(COM_Token)] := #0;
  if Data = nil then
   Result := nil
  else
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

      if (C = '/') and (PLChar(UInt(Data) + 1)^ = '/') then
       while C <> #0 do
        if C = #$A then
         Break
        else
         begin
          Inc(UInt(Data));
          C := PLChar(Data)^;
         end
      else
       Break;
     end;

    if C = '"' then
     begin
      L := Low(COM_Token);
      
      while True do
       begin
        Inc(UInt(Data));

        if (PLChar(Data)^ = '"') or (L >= High(COM_Token) - 1) then
         Break
        else
         begin
          COM_Token[L] := PLChar(Data)^;
          Inc(L);
         end;
       end;

      COM_Token[L] := #0;
      Result := Pointer(UInt(Data) + 1);
     end
    else
     if (C in ['{', '}', ')', '(', '\', ',']) or
        (not COM_IgnoreColons and (C = ':')) then
      begin
       COM_Token[Low(COM_Token)] := C;
       COM_Token[Low(COM_Token) + 1] := #0;
       Result := Pointer(UInt(Data) + 1);
      end
     else
      begin
       L := 1;

       while not ((C in ['{', '}', ')', '(', '\', ',', #0..' ']) or
                  (not COM_IgnoreColons and (C = ':'))) do
        if L >= High(COM_Token) - 1 then
         Break
        else
         begin
          COM_Token[L] := C;
          
          Inc(L);
          Inc(UInt(Data));
          C := PLChar(Data)^;
         end;

       COM_Token[L] := #0;
       Result := Data;
      end;
   end;
 end;
end;

function COM_ParseLine(Data: Pointer): Pointer;
var
 I: UInt;
 C: LChar;
begin
if UngetToken then
 begin
  UngetToken := False;
  Result := Data;
 end
else
 if Data <> nil then
  begin
   I := Low(COM_Token);

   C := PLChar(Data)^;
   while (C >= ' ') and (I < High(COM_Token)) do
    begin
     COM_Token[I] := C;

     Inc(UInt(Data));
     C := PLChar(Data)^;
     Inc(I);
    end;

   COM_Token[I] := #0;

   if C < ' ' then
    while C > #0 do
     begin
      Inc(UInt(Data));
      C := PLChar(Data)^;
      if C >= ' ' then
       Break;
     end;

   Result := Data;
  end
 else
  begin
   COM_Token[Low(COM_Token)] := #0;
   Result := nil;
  end;
end;

function COM_TokenWaiting(Data: Pointer): Boolean;
begin
if Data <> nil then
 while True do
  case PLChar(Data)^ of
   #0, #$A: Break;
   '!'..'~':
    begin
     Result := True;
     Exit;
    end;
   else
    Inc(UInt(Data));
  end;

Result := False;
end;

function ShortSwap(L: Int16): Int16;
begin
Result := Swap16(L);
end;

function ShortNoSwap(L: Int16): Int16;
begin
Result := L;
end;

function LongSwap(L: Int32): Int32;
begin
Result := Swap32(L);
end;

function LongNoSwap(L: Int32): Int32;
begin
Result := L;
end;

function FloatSwap(F: Single): Single;
begin
Result := Swap32(PInt32(@F)^);
end;

function FloatNoSwap(F: Single): Single;
begin
Result := F;
end;

procedure COM_WriteFile(Name: PLChar; Buffer: Pointer; Size: UInt);
var
 Buf: array[1..MAX_PATH_W] of LChar;
 F: TFile;
begin
Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
COM_FixSlashes(Name);
COM_CreatePath(Name);
if FS_Open(F, Name, 'wo') then
 begin
  FS_Write(F, Buffer, Size);
  FS_Close(F);
 end
else
 Print(['COM_WriteFile: Failed to create file "', Name, '".']);
end;

procedure COM_FixSlashes(S: PLChar);
begin
while True do
 begin
  case S^ of
   #0: Exit;
   IncorrectSlash: S^ := CorrectSlash;
  end;
  Inc(UInt(S));
 end;
end;

procedure COM_CreatePath(S: PLChar);
begin
FS_CreateDirHierarchy(S);
end;

procedure COM_CopyFile(Source, Dest: PLChar);
var
 F, F2: TFile;
 Size: Int64;
 Buffer: array[1..4096] of LChar;
begin
if FS_Open(F, Source, 'r') then
 begin
  Size := FS_Size(F);
  COM_CreatePath(Dest);
  if FS_Open(F2, Dest, 'wo') then
   begin
    while Size > 0 do
     begin
      FS_Write(F2, @Buffer, FS_Read(F, @Buffer, Min(Size, SizeOf(Buffer))));
      Dec(Size, SizeOf(Buffer));
     end;

    FS_Close(F2);
   end;
  FS_Close(F);
 end;
end;

function COM_FileSize(Name: PLChar): Int64;
var
 F: TFile;
begin
if FS_Open(F, Name, 'r') then
 begin
  Result := FS_Size(F);
  FS_Close(F);
 end
else
 Result := -1;
end;

function COM_LoadFile(Name: PLChar; AllocType: TFileAllocType; Length: PUInt32): Pointer;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 F: TFile;
 Size: UInt32;
begin
Result := nil;

if FS_Open(F, Name, 'r') then
 begin
  Size := FS_Size(F);
  Name := COM_FileBase(Name, @Buf);

  case AllocType of
   FILE_ALLOC_ZONE: Result := Z_MAlloc(Size + 1);
   FILE_ALLOC_HUNK: Result := Hunk_AllocName(Size + 1, Name);
   FILE_ALLOC_TEMP_HUNK: Result := Hunk_TempAlloc(Size + 1);
   FILE_ALLOC_CACHE: Result := Cache_Alloc(LoadCache^, Size + 1, Name);
   FILE_ALLOC_LOADBUF:
    if Size + 1 <= LoadSize then
     Result := LoadBuffer
    else
     Result := Hunk_TempAlloc(Size + 1);
   FILE_ALLOC_MEMORY: Result := Mem_Alloc(Size + 1);
   else
    Sys_Error('COM_LoadFile: Invalid file allocation type.');
  end;

  if Result <> nil then
   begin
    PByte(UInt(Result) + Size)^ := 0;
    FS_Read(F, Result, Size);
    if Length <> nil then
     Length^ := Size;
   end
  else
   Sys_Error(['COM_LoadFile: Not enough space for "', Name, '".']);

  FS_Close(F);
 end
else
 if Length <> nil then
  Length^ := 0;
end;

procedure COM_FreeFile(Buffer: Pointer);
begin
if Buffer <> nil then
 Mem_Free(Buffer);
end;

procedure COM_CopyFileChunk(Dest, Source: TFile; Size: Int64);
var
 Buffer: array[1..4096] of LChar;
 ThisSize: Int64;
begin
while Size > 0 do
 begin
  ThisSize := Min(Size, SizeOf(Buffer));
  FS_Write(Dest, @Buffer, FS_Read(Source, @Buffer, ThisSize));
  Dec(Size, ThisSize);
 end;

FS_Flush(Source);
FS_Flush(Dest);
end;

function COM_LoadFileLimit(Name: PLChar; SeekPos, MaxSize: Int64; Length: PInt64; var FilePtr: TFile): Pointer;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 F: TFile;
 Size: Int64;
begin
if FilePtr = nil then
 if not FS_Open(F, Name, 'r') then
  begin
   Result := nil;
   Exit;
  end
 else
  FilePtr := F;

Size := FS_Size(FilePtr);
if SeekPos > Size then
 begin
  FS_Close(FilePtr);
  Sys_Error(['COM_LoadFileLimit: Invalid seek position for file "', Name, '".']);
 end;

FS_Seek(FilePtr, SeekPos, SEEK_SET);
if Size > MaxSize then
 Size := MaxSize;

if Length <> nil then
 Length^ := Size;

Name := COM_FileBase(Name, @Buf);
Result := Hunk_TempAlloc(Size + 1);
if Result <> nil then
 begin
  PByte(UInt(Result) + Size)^ := 0;
  FS_Read(FilePtr, Result, Size);
 end
else
 begin
  FS_Close(FilePtr);
  Sys_Error(['COM_LoadFileLimit: Not enough space for "', Name, '".']);
 end;
end;

function COM_LoadHunkFile(Name: PLChar): Pointer;
begin
Result := COM_LoadFile(Name, FILE_ALLOC_HUNK, nil);
end;

function COM_LoadTempFile(Name: PLChar; Length: PUInt32): Pointer;
begin
Result := COM_LoadFile(Name, FILE_ALLOC_TEMP_HUNK, Length);
end;

function COM_LoadCacheFile(Name: PLChar; Cache: PCacheUser): Pointer;
begin
LoadCache := Cache;
Result := COM_LoadFile(Name, FILE_ALLOC_CACHE, nil);
end;

function COM_LoadStackFile(Name: PLChar; Buffer: Pointer; Size: UInt): Pointer;
begin
LoadBuffer := Buffer;
LoadSize := Size;
Result := COM_LoadFile(Name, FILE_ALLOC_LOADBUF, nil);
end;

procedure COM_AddAppDirectory(Name: PLChar);
begin
FS_AddSearchPath(Name, 'PLATFORM', True);
end;

function COM_AddDefaultDir(Name: PLChar): Boolean;
begin
if (Name <> nil) and (Name^ > #0) then
 Result := FileSystem_AddFallbackGameDir(Name)
else
 Result := False;
end;

procedure COM_StripTrailingSlash(S: PLChar);
var
 L: UInt;
begin
if S <> nil then
 begin
  L := StrLen(S);
  if L > 0 then
   begin
    S := PLChar(UInt(S) + L - 1);
    if S^ in ['\', '/'] then
     S^ := #0;
   end;
 end;
end;

procedure COM_ListMaps(S: PLChar);
begin
Sys_Error('COM_ListMaps: Not implemented.');
end;

procedure COM_PrintBSPVersion(Buffer: Pointer; Name: PLChar; WriteOutdated: Boolean);
begin
if PUInt32(Buffer)^ = BSPVERSION30 then
 if not WriteOutdated then
  Print(Name)
 else
else
 if WriteOutdated then
  Print(['Outdated: ', Name]);
end;

procedure COM_Log(FileName, Data: PLChar);
var
 F: TFile;
begin
if FileName = nil then
 FileName := 'hllog.txt';

if FS_Open(F, FileName, 'a') then
 begin
  FS_FPrintF(F, Data);
  FS_Close(F);
 end;
end;

procedure COM_Log(FileName: PLChar; const Data: array of const);
begin
COM_Log(FileName, PLChar(StringFromVarRec(Data)));
end;

function COM_LoadFileForMe(Name: PLChar; Length: PUInt32): Pointer;
begin
Result := COM_LoadFile(Name, FILE_ALLOC_MEMORY, Length);
end;

function COM_CompareFileTime(S1, S2: PLChar; out CompareResult: Int32): Boolean;
var
 F1, F2: Int64;
begin
if (S1 <> nil) and (S2 <> nil) then
 begin
  F1 := FS_GetFileTime(S1);
  F2 := FS_GetFileTime(S2);
  if (F1 > 0) and (F2 > 0) then
   begin
    if F1 >= F2 then
     if F1 > F2 then
      CompareResult := 1
     else
      CompareResult := 0
    else
     CompareResult := -1;

    Result := True;
    Exit;
   end;
 end;

Result := False;
CompareResult := 0;
end;

procedure COM_GetGameDir(Buf: PLChar);
begin
if Buf <> nil then
 StrLCopy(Buf, GameDir, MAX_PATH_A - 1);
end;

function COM_EntsForPlayerSlots(Count: UInt): UInt;
var
 S: PLChar;
 I: UInt;
begin
S := COM_ParmValueByName('-num_edicts');
if (S = nil) or (S^ = #0) then
 I := 900
else
 I := Max(StrToIntDef(S, 900), 900);

Result := 15 * (Count - 1) + I;
end;

procedure COM_NormalizeAngles(var Angles: TVec3);
var
 I: Int;
begin
for I := 0 to 2 do
 if Angles[I] > 180 then
  Angles[I] := Angles[I] - 360
 else
  if Angles[I] < -180 then
   Angles[I] := Angles[I] + 360;
end;

procedure COM_Munge_Internal(Data: Pointer; Length: UInt; Sequence: Int32; EncodeTable: PPacketEncodeTable);
type
 T = array[0..3] of Byte;
var
 I, K: UInt;
 P: PInt32;
 C: Int32;
begin
Length := (Length and not 3) shr 2;

if Length > 0 then
 for I := 0 to Length - 1 do
  begin
   P := Pointer(UInt(Data) + (I shl 2));
   C := Swap32(P^ xor not Sequence);

   for K := Low(T) to High(T) do
    T(C)[K] := T(C)[K] xor ($A5 or (K shl K) or K or EncodeTable[(I + K) and High(EncodeTable^)]);

   C := C xor Sequence;
   P^ := C;
  end;
end;

procedure COM_UnMunge_Internal(Data: Pointer; Length: UInt; Sequence: Int32; DecodeTable: PPacketEncodeTable);
type
 T = array[0..3] of Byte;
var
 I, K: UInt;
 P: PInt32;
 C: Int32;
begin
Length := (Length and not 3) shr 2;

if Length > 0 then
 for I := 0 to Length - 1 do
  begin
   P := Pointer(UInt(Data) + (I shl 2));
   C := P^ xor Sequence;
 
   for K := 0 to High(T) do
    T(C)[K] := T(C)[K] xor ($A5 or (K shl K) or K or DecodeTable[(I + K) and High(DecodeTable^)]);

   C := Swap32(C) xor not Sequence;
   P^ := C;
  end;
end;

procedure COM_Munge(Data: Pointer; Length: UInt; Sequence: Int32);
begin
COM_Munge_Internal(Data, Length, Sequence, @EncodeTable1);
end;

procedure COM_UnMunge(Data: Pointer; Length: UInt; Sequence: Int32);
begin
COM_UnMunge_Internal(Data, Length, Sequence, @EncodeTable1);
end;

procedure COM_Munge2(Data: Pointer; Length: UInt; Sequence: Int32);
begin
COM_Munge_Internal(Data, Length, Sequence, @EncodeTable2);
end;

procedure COM_UnMunge2(Data: Pointer; Length: UInt; Sequence: Int32);
begin
COM_UnMunge_Internal(Data, Length, Sequence, @EncodeTable2);
end;

procedure COM_Munge3(Data: Pointer; Length: UInt; Sequence: Int32);
begin
COM_Munge_Internal(Data, Length, Sequence, @EncodeTable3);
end;

procedure COM_UnMunge3(Data: Pointer; Length: UInt; Sequence: Int32);
begin
COM_UnMunge_Internal(Data, Length, Sequence, @EncodeTable3);
end;

function COM_GetApproxWavePlayLength(Name: PLChar): UInt;
type
 TWaveHeader = packed record
  ChunkID: array[1..4] of LChar;
  ChunkSize: UInt32;
  Format: array[1..4] of LChar;

  SubChunk1ID: array[1..4] of LChar;
  SubChunk1Size: UInt32;
  AudioFormat, NumChannels: UInt16;
  SampleRate, ByteRate: UInt32;
  BlockAlign, BitsPerSample: UInt16;
  
  SubChunk2ID: array[1..4] of LChar;
  SubChunk2Size: UInt32;
 end;
const
 RIFF_TAG = Ord('R') + Ord('I') shl 8 + Ord('F') shl 16 + Ord('F') shl 24;
 WAVE_TAG = Ord('W') + Ord('A') shl 8 + Ord('V') shl 16 + Ord('E') shl 24;
 FMT_TAG = Ord('f') + Ord('m') shl 8 + Ord('t') shl 16 + Ord(' ') shl 24;
var
 F: TFile;
 Size: Int64;
 Header: TWaveHeader;
begin
if FS_Open(F, Name, 'r') then
 begin
  Size := FS_Size(F);
  if (FS_Read(F, @Header, SizeOf(Header)) = SizeOf(Header)) and
     (PUInt32(@Header.ChunkID)^ = RIFF_TAG) and (PUInt32(@Header.Format)^ = WAVE_TAG) and (PUInt32(@Header.SubChunk1ID)^ = FMT_TAG) then
   begin
    Dec(Size, SizeOf(Header));
    if Header.ByteRate / 1000 > 0 then
     Result := Trunc(Size / (Header.ByteRate / 100))
    else
     Result := Trunc(1000 * Size / Header.ByteRate);
   end
  else
   Result := 0;

  FS_Close(F);
 end
else
 Result := 0;
end;

function COM_HasExtension(S: PLChar): Boolean;
var
 C: LChar;
begin
Result := False;

repeat
 C := S^;
 if C = '.' then
  Result := True
 else
  if (C = '\') or (C = '/') or (C = ':') then
   Result := False;
 Inc(UInt(S));
until C = #0;
end;

procedure COM_Init;
const
 SwapTest: packed array[1..SizeOf(Int16)] of Byte = (1, 0);
begin
BigEndian := Int16(SwapTest) <> 1;
if not BigEndian then
 begin
  BigShort := @ShortSwap;
  LittleShort := @ShortNoSwap;
  BigLong := @LongSwap;
  LittleLong := @LongNoSwap;
  BigFloat := @FloatSwap;
  LittleFloat := @FloatNoSwap;
 end
else
 begin
  BigShort := @ShortNoSwap;
  LittleShort := @ShortSwap;
  BigLong := @LongNoSwap;
  LittleLong := @LongSwap;
  BigFloat := @FloatNoSwap;
  LittleFloat := @FloatSwap;
 end;

CVar_RegisterVariable(com_filewarning);

MemSet(BFWrite, SizeOf(BFWrite), 0);
MemSet(BFRead, SizeOf(BFRead), 0);
end;

procedure COM_Shutdown;
begin

end;

procedure ClearLink(var L: TLink);
begin
L.Prev := @L;
L.Next := @L;
end;

procedure RemoveLink(var L: TLink);
begin
L.Next.Prev := L.Prev;
L.Prev.Next := L.Next;
end;

procedure InsertLinkBefore(var L, L2: TLink);
begin
L.Next := @L2;
L.Prev := L2.Prev;
L.Prev.Next := @L;
L.Next.Prev := @L;
end;

procedure InsertLinkAfter(var L, L2: TLink);
begin
L.Next := L2.Next;
L.Prev := @L2;
L.Prev.Next := @L;
L.Next.Prev := @L;
end;

function PR_IsEmptyString(S: PLChar): Boolean;
begin
Result := S^ <= ' ';
end;

function EdictFromArea(const L: TLink): PEdict;
begin
Result := Pointer(UInt(@L) - UInt(@PEdict(nil).Area));
end;

function FilterGroup(const E1, E2: TEdict): Boolean;
begin
Result := (@E1 <> nil) and (@E2 <> nil) and (E1.V.GroupInfo <> 0) and (E2.V.GroupInfo <> 0) and
          (((GroupOp = GROUP_OP_AND) and ((E1.V.GroupInfo and E2.V.GroupInfo) = 0)) or
           ((GroupOp = GROUP_OP_NAND) and ((E1.V.GroupInfo and E2.V.GroupInfo) <> 0)));
end;

function FilterGroup(I1, I2: Int): Boolean;
begin
Result := (I1 <> 0) and (I2 <> 0) and
          (((GroupOp = GROUP_OP_AND) and ((I1 and I2) = 0)) or
           ((GroupOp = GROUP_OP_NAND) and ((I1 and I2) <> 0)));
end;

procedure TrimSpace(Src, Dst: PLChar);
var
 L: UInt;
 SrcEnd: PLChar;
begin
L := StrLen(Src);

SrcEnd := PLChar(UInt(Src) + L);
while UInt(Src) < UInt(SrcEnd) do
 if Src^ > ' ' then
  Break
 else
  Inc(UInt(Src));

Dec(UInt(SrcEnd));
while UInt(SrcEnd) >= UInt(Src) do
 if SrcEnd^ > ' ' then
  Break
 else
   Dec(UInt(SrcEnd));

if UInt(SrcEnd) >= UInt(Src) then
 StrLCopy(Dst, Src, UInt(SrcEnd) - UInt(Src) + 1)
else
 Dst^ := #0;
end;

function IsMapValid(Name: PLChar): Boolean;
var
 Buf: array[1..MAX_PATH_A] of LChar;
begin
if (Name <> nil) and (Name^ > #0) then
 begin
  StrCopy(StrLECopy(StrECopy(@Buf, ('maps' + CorrectSlash)), Name, MAX_MAP_NAME), '.bsp');
  Result := FS_FileExists(@Buf);
 end
else
 Result := False;
end;

function COM_IntToHex(Val: UInt32; out Buf): PLChar;
var
 I: UInt;
begin
for I := 3 downto 0 do
 begin
  PUInt16(UInt(@Buf) + (I shl 1))^ := Byte(HexLookupTable[(Val shr 4) and $F]) + (Byte(HexLookupTable[Val and $F]) shl 8);
  Val := Val shr 8;
 end;

PLChar(UInt(@Buf) + 8)^ := #0;
Result := @Buf;
end;

end.
