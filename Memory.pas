unit Memory;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure Z_ClearZone(var Zone: TMemoryZone; Size: UInt);
procedure Z_Free(P: Pointer);
function Z_MAlloc(Size: UInt): Pointer;
function Z_TagMAlloc(Size: UInt; Tag: Int32): Pointer;
procedure Z_Print(const Zone: TMemoryZone);
procedure Z_CheckHeap;

procedure Hunk_Check;
procedure Hunk_Print(All: Boolean);
function Hunk_AllocName(Size: UInt; Name: PLChar): Pointer;
function Hunk_Alloc(Size: UInt): Pointer;
function Hunk_LowMark: UInt;
procedure Hunk_FreeToLowMark(Mark: UInt);
function Hunk_HighMark: UInt;
procedure Hunk_FreeToHighMark(Mark: UInt);
function Hunk_HighAllocName(Size: UInt; Name: PLChar): Pointer;
function Hunk_TempAlloc(Size: UInt): Pointer;

procedure Cache_Move(var C: TCacheSystem);
procedure Cache_FreeLow(NewHunk: UInt);
procedure Cache_FreeHigh(NewHunk: UInt);
procedure Cache_UnlinkLRU(var C: TCacheSystem);
procedure Cache_MakeLRU(var C: TCacheSystem);
function Cache_TryAlloc(Size: UInt; NoBottom: Boolean): PCacheSystem;
procedure Cache_Flush;
procedure Cache_Print;
procedure Cache_Force_Flush;
procedure Cache_Report;
procedure Cache_Compact;
procedure Cache_Init;
procedure Cache_Free(var C: TCacheUser);
function Cache_TotalUsed: UInt;
function Cache_Check(var C: TCacheUser): Pointer;
function Cache_Alloc(var C: TCacheUser; Size: UInt; Name: PLChar): Pointer;

procedure SZ_Alloc(Name: PLChar; var Buffer: TSizeBuf; Size: UInt);
procedure SZ_Clear(var Buffer: TSizeBuf);
function SZ_GetSpace(var Buffer: TSizeBuf; Length: UInt): Pointer;
procedure SZ_Write(var Buffer: TSizeBuf; Data: Pointer; Length: UInt);
procedure SZ_Print(var Buffer: TSizeBuf; Data: PLChar);

function Mem_Alloc(Size: UInt): Pointer;
function Mem_AllocN(Size: UInt): Pointer;
function Mem_ZeroAlloc(Size: UInt): Pointer;
function Mem_ReAlloc(Data: Pointer; Size: UInt): Pointer;
function Mem_CAlloc(Count, Size: UInt): Pointer;
function Mem_StrDup(S: PLChar): PLChar;
function Mem_StrDupEx(S: PLChar; ExtraLen: UInt): PLChar;
procedure Mem_Free(Data: Pointer);
procedure Mem_FreeAndNil(var Data);

procedure Cmd_Flush; cdecl;
procedure Cache_Print_Models_And_Totals; cdecl;
procedure Cache_Print_Sounds_And_Totals; cdecl;

procedure Memory_Init(Buffer: Pointer; Size: UInt);

var
 mem_dbgfile: TCVar = (Name: 'mem_dbgfile'; Data: 'mem.txt');
 mem_checkheap: TCVar = (Name: 'mem_checkheap'; Data: '0');

implementation

uses Console, FileSys, Server, SysArgs, SysMain;

const
 ZONE_ID = $1D4A11;
 ZONE_MIN_FRAGMENT = 64;

 HUNK_ID = $1DF001ED;

var
 MainZone: PMemoryZone = nil;

 HunkBase: Pointer;
 HunkSize, HunkLowUsed, HunkHighUsed: UInt;

 HunkTempActive: Boolean = False;
 HunkTempMark: UInt;

 CacheHead: TCacheSystem = ();

procedure Z_ClearZone(var Zone: TMemoryZone; Size: UInt);
var
 Block, BlockList: PMemoryBlock;
begin
if Size < SizeOf(Zone) then
 Sys_Error(['Z_ClearZone: Invalid block size (', Size, ').']);

Block := Pointer(UInt(@Zone) + SizeOf(Zone));

BlockList := @Zone.BlockList;
BlockList.Prev := Block;
BlockList.Next := Block;
BlockList.Tag := 1;
BlockList.ID := 0;
BlockList.Size := 0;
Zone.Rover := Block;

Block.Prev := BlockList;
Block.Next := BlockList;
Block.Tag := 0;
Block.ID := ZONE_ID;
Block.Size := Size - SizeOf(Zone);

Zone.Size := Size;
end;

procedure Z_Free(P: Pointer);
var
 Block, Other: PMemoryBlock;
begin
if UInt(P) <= SizeOf(TMemoryBlock) then
 Sys_Error('Z_Free: Invalid pointer.')
else
 begin
  Block := PMemoryBlock(UInt(P) - SizeOf(TMemoryBlock));
  if Block.ID <> ZONE_ID then
   Sys_Error('Z_Free: Invalid block ID.')
  else
   if Block.Tag = 0 then
    Sys_Error('Z_Free: The pointer was already freed.')
   else
    begin
     Block.Tag := 0;

     Other := Block.Prev;
     if Other.Tag = 0 then
      begin
       Inc(Other.Size, Block.Size);
       Other.Next := Block.Next;
       Other.Next.Prev := Other;
       if Block = MainZone.Rover then
        MainZone.Rover := Other;
       Block := Other;
      end;

     Other := Block.Next;
     if Other.Tag = 0 then
      begin
       Inc(Block.Size, Other.Size);
       Block.Next := Other.Next;
       Block.Next.Prev := Block;
       if Other = MainZone.Rover then
        MainZone.Rover := Block;
      end;
    end;
 end;
end;

function Z_MAlloc(Size: UInt): Pointer;
begin
if Size = 0 then
 Sys_Error('Z_MAlloc: Invalid block size.');

if mem_checkheap.Value >= 1 then
 Z_CheckHeap;

Result := Z_TagMAlloc(Size, 1);
if Result = nil then
 Sys_Error(['Z_MAlloc: Failed to allocate ', Size, ' bytes.'])
else
 MemSet(Result^, Size, 0);
end;

function Z_TagMAlloc(Size: UInt; Tag: Int32): Pointer;
var
 Start, Rover, New, Base: PMemoryBlock;
begin
if Tag = 0 then
 Sys_Error('Z_TagMAlloc: Invalid tag.');

Size := (Size + SizeOf(TMemoryBlock) + 4 + 7) and not Byte(7);

Rover := MainZone.Rover;
Base := Rover;
Start := Base.Prev;

repeat
 if Rover = Start then
  begin
   Result := nil;
   Exit;
  end
 else
  begin
   if Rover.Tag >= 1 then
    Base := Rover.Next;

   Rover := Rover.Next;
  end;
until (Base.Tag = 0) and (Base.Size >= Size);

if Base.Size - Size > ZONE_MIN_FRAGMENT then
 begin
  New := Pointer(UInt(Base) + Size);
  New.Size := Base.Size - Size;
  New.Tag := 0;
  New.Prev := Base;
  New.ID := ZONE_ID;
  New.Next := Base.Next;
  New.Next.Prev := New;
  Base.Next := New;
  Base.Size := Size;
 end;

Base.Tag := Tag;
MainZone.Rover := Base.Next;

Base.ID := ZONE_ID;
PInt32(UInt(Base) + Base.Size - 4)^ := ZONE_ID;

Result := Pointer(UInt(Base) + SizeOf(TMemoryBlock));  
end;

procedure Z_Print(const Zone: TMemoryZone);
var
 Block: PMemoryBlock;
begin
Print(['Zone size: ', MainZone.Size, '; Location: ', MainZone]);

Block := Zone.BlockList.Next;
while Block <> nil do
 begin
  Print(['Block: ', Block, '; Size: ', Block.Size, '; Tag: ', Block.Tag]);
  if Block.Next = @Zone.BlockList then
   Break
  else
   if UInt(Block) + Block.Size <> UInt(Block.Next) then
    Print('Error: Block size does not touch the next block.')
   else
    if (Block.Next = nil) or (Block.Next.Prev <> Block) then
     Print('Error: Next block doesn''t have proper back link.')
    else
     if (Block.Tag = 0) and (Block.Next.Tag = 0) then
      Print('Error: Two consecutive free blocks.');

  Block := Block.Next;
 end;
end;

procedure Z_CheckHeap;
var
 Block: PMemoryBlock;
begin
Block := MainZone.BlockList.Next;

while (Block <> nil) and (Block.Next <> @MainZone.BlockList) do
 if UInt(Block) + Block.Size <> UInt(Block.Next) then
  Sys_Error('Z_CheckHeap: Block size does not touch the next block.')
 else
  if (Block.Next = nil) or (Block.Next.Prev <> Block) then
   Sys_Error('Z_CheckHeap: Next block doesn''t have proper back link.')
  else
   if (Block.Tag = 0) and (Block.Next.Tag = 0) then
    Sys_Error('Z_CheckHeap: Two consecutive free blocks.')
   else
    Block := Block.Next;
end;

procedure Hunk_Check;
var
 Hunk: PHunk;
begin
Hunk := HunkBase;
while Hunk <> Pointer(UInt(HunkBase) + HunkLowUsed) do
 if Hunk.ID <> HUNK_ID then
  Sys_Error('Hunk_Check: Invalid hunk ID.')
 else
  if (Hunk.Size < 16) or ((UInt(Hunk) + Hunk.Size - UInt(HunkBase)) > HunkSize) then
   Sys_Error('Hunk_Check: Invalid size.')
  else
   Hunk := Pointer(UInt(Hunk) + Hunk.Size);
end;

procedure Hunk_Print(All: Boolean);
var
 F: TFile;
 Hunk, Next, EndLow, StartHigh, EndHigh: PHunk;
 Sum, TotalBlocks: UInt;
begin
Sum := 0;
TotalBlocks := 0;

if not FS_Open(F, mem_dbgfile.Data, 'a') then
 Exit;

Hunk := HunkBase;
EndLow := Pointer(UInt(HunkBase) + HunkLowUsed);
StartHigh := Pointer(UInt(HunkBase) + HunkSize - HunkHighUsed);
EndHigh := Pointer(UInt(HunkBase) + HunkSize);

FS_FPrintF(F, ['Total hunk size: ', HunkSize]);
FS_FPrintF(F, '-------------------------');

while True do
 begin
  if Hunk = EndLow then
   begin
    FS_FPrintF(F, '-------------------------');
    FS_FPrintF(F, [' - Remaining: ', HunkSize - HunkLowUsed - HunkHighUsed]);
    FS_FPrintF(F, '-------------------------');
    Hunk := StartHigh;
   end;

  if Hunk = EndHigh then
   Break;

  if Hunk.ID <> HUNK_ID then
   Sys_Error('Hunk_Print: Invalid hunk ID.')
  else
   if (Hunk.Size < 16) or ((UInt(Hunk) + Hunk.Size - UInt(HunkBase)) > HunkSize) then
    Sys_Error('Hunk_Print: Invalid size.');

  Next := Pointer(UInt(Hunk) + Hunk.Size);
  Inc(TotalBlocks);
  Inc(Sum, Hunk.Size);

  if All then
   FS_FPrintF(F, [Hunk, ': Size = ', Hunk.Size, '; Name = ', PLChar(@Hunk.Name)]);

  if (Next = EndLow) or (Next = EndHigh) or
     (StrLComp(@Hunk.Name, @Next.Name, HUNK_NAME_SIZE) <> 0) then
   begin
    if not All then
     FS_FPrintF(F, ['Sum = ', Sum, '; Name = ', PLChar(@Hunk.Name)]);
    Sum := 0;
   end;

  Hunk := Next;
 end;

FS_FPrintF(F, '-------------------------');
FS_FPrintF(F, ['Total blocks: ', TotalBlocks]);

FS_Close(F);
end;

function Hunk_AllocName(Size: UInt; Name: PLChar): Pointer;
var
 Hunk: PHunk;
begin
Size := SizeOf(THunk) + ((Size + 15) and not 15);
if HunkSize - HunkLowUsed - HunkHighUsed < Size then
 Sys_Error(['Hunk_AllocName: Couldn''t allocate ', Size, ' bytes.']);

Hunk := Pointer(UInt(HunkBase) + HunkLowUsed);
Inc(HunkLowUsed, Size);
Cache_FreeLow(HunkLowUsed);

MemSet(Hunk^, Size, 0);

Hunk.Size := Size;
Hunk.ID := HUNK_ID;
StrLCopy(@Hunk.Name, Name, HUNK_NAME_SIZE - 1);

Result := Pointer(UInt(Hunk) + SizeOf(THunk));
end;

function Hunk_Alloc(Size: UInt): Pointer;
begin
Result := Hunk_AllocName(Size, 'unknown');
end;

function Hunk_LowMark: UInt;
begin
Result := HunkLowUsed;
end;

procedure Hunk_FreeToLowMark(Mark: UInt);
begin
if Mark > HunkLowUsed then
 Sys_Error(['Hunk_FreeToLowMark: Invalid mark (', Mark, ').'])
else
 HunkLowUsed := Mark;
end;

function Hunk_HighMark: UInt;
begin
if HunkTempActive then
 begin
  HunkTempActive := False;
  Hunk_FreeToHighMark(HunkTempMark);
 end;

Result := HunkHighUsed;
end;

procedure Hunk_FreeToHighMark(Mark: UInt);
begin
if HunkTempActive then
 begin
  HunkTempActive := False;
  Hunk_FreeToHighMark(HunkTempMark);
 end;

if Mark > HunkHighUsed then
 Sys_Error(['Hunk_FreeToHighMark: Invalid mark (', Mark, ').'])
else
 HunkHighUsed := Mark;
end;

function Hunk_HighAllocName(Size: UInt; Name: PLChar): Pointer;
var
 Hunk: PHunk;
begin
if Size = 0 then
 Sys_Error('Hunk_HighAllocName: Invalid block size.');

if HunkTempActive then
 begin
  Hunk_FreeToHighMark(HunkTempMark);
  HunkTempActive := False;
 end;

Size := SizeOf(THunk) + ((Size + 15) and not 15);
if HunkSize - HunkLowUsed - HunkHighUsed < Size then
 begin
  Print(['Hunk_HighAllocName: Couldn''t allocate ', Size, ' bytes.']);
  Result := nil;
 end
else
 begin
  Inc(HunkHighUsed, Size);
  
  // Older HLDS versions skip size addition
  Cache_FreeHigh(Size + HunkHighUsed);

  Hunk := Pointer(UInt(HunkBase) + HunkSize - HunkHighUsed);
  MemSet(Hunk^, Size, 0);

  Hunk.Size := Size;
  Hunk.ID := HUNK_ID;
  StrLCopy(@Hunk.Name, Name, HUNK_NAME_SIZE - 1);

  Result := Pointer(UInt(Hunk) + SizeOf(THunk));
 end;
end;

function Hunk_TempAlloc(Size: UInt): Pointer;
begin
if HunkTempActive then
 begin
  Hunk_FreeToHighMark(HunkTempMark);
  HunkTempActive := False;
 end;

HunkTempMark := HunkHighUsed;
Result := Hunk_HighAllocName((Size + 15) and not 15, 'temp');
HunkTempActive := True;
end;

procedure Cache_Move(var C: TCacheSystem);
var
 New: PCacheSystem;
begin
New := Cache_TryAlloc(C.Size, True);
if New <> nil then
 begin
  Move(Pointer(UInt(@C) + SizeOf(C))^, Pointer(UInt(New) + SizeOf(New^))^, C.Size - SizeOf(C));
  New.User := C.User;
  Move(C.Name, New.Name, SizeOf(C.Name));
  Cache_Free(C.User^);
  New.User.Data := Pointer(UInt(New) + SizeOf(New^));
 end
else
 Cache_Free(C.User^);
end;

procedure Cache_FreeLow(NewHunk: UInt);
var
 C: PCacheSystem;
begin
while True do
 begin
  C := CacheHead.Next;
  if (C <> @CacheHead) and (UInt(C) < UInt(HunkBase) + NewHunk) then
   Cache_Move(C^)
  else
   Break;
 end;
end;

procedure Cache_FreeHigh(NewHunk: UInt);
var
 C, Prev: PCacheSystem;
begin
Prev := nil;
while True do
 begin
  C := CacheHead.Prev;
  if (C <> @CacheHead) and (UInt(C) + C.Size > UInt(HunkBase) + HunkSize - NewHunk) then
   if C = Prev then
    Cache_Free(C.User^)
   else
    begin
     Cache_Move(C^);
     Prev := C;
    end
  else
   Break;
 end;
end;

procedure Cache_UnlinkLRU(var C: TCacheSystem);
begin
if (C.LRUNext = nil) or (C.LRUPrev = nil) then
 Sys_Error('Cache_UnlinkLRU: Inactive link.')
else
 begin
  C.LRUNext.LRUPrev := C.LRUPrev;
  C.LRUPrev.LRUNext := C.LRUNext;

  C.LRUPrev := nil;
  C.LRUNext := nil;
 end;
end;

procedure Cache_MakeLRU(var C: TCacheSystem);
begin
if (C.LRUNext <> nil) or (C.LRUPrev <> nil) then
 Sys_Error('Cache_MakeLRU: Active link.')
else
 begin
  CacheHead.LRUNext.LRUPrev := @C;
  C.LRUNext := CacheHead.LRUNext;
  C.LRUPrev := @CacheHead;
  CacheHead.LRUNext := @C;
 end;
end;

function Cache_TryAlloc(Size: UInt; NoBottom: Boolean): PCacheSystem;
var
 C, New: PCacheSystem;
begin
New := Pointer(UInt(HunkBase) + HunkLowUsed);

if not NoBottom and (CacheHead.Prev = @CacheHead) then
 begin
  if HunkSize - HunkHighUsed - HunkLowUsed < Size then
   Sys_Error(['Cache_TryAlloc: ', Size, ' is greater than free hunk.']);

  MemSet(New^, SizeOf(New^), 0);
  New.Size := Size;

  CacheHead.Prev := New;
  CacheHead.Next := New;
  New.Prev := @CacheHead;
  New.Next := @CacheHead;
  Cache_MakeLRU(New^);

  Result := New;
 end
else
 begin
  C := CacheHead.Next;
  repeat
   if (not NoBottom or (C <> CacheHead.Next)) and
      (UInt(C) - UInt(New) >= Size) then
    begin
     MemSet(New^, SizeOf(New^), 0);
     New.Size := Size;

     New.Next := C;
     New.Prev := C.Prev;
     C.Prev.Next := New;
     C.Prev := New;
     Cache_MakeLRU(New^);

     Result := New;
     Exit;
    end;

   New := Pointer(UInt(C) + C.Size);
   C := C.Next;
  until C = @CacheHead;

  if UInt(HunkBase) + HunkSize - HunkHighUsed - UInt(New) >= Size then
   begin
    MemSet(New^, SizeOf(New^), 0);
    New.Size := Size;

    New.Next := @CacheHead;
    New.Prev := CacheHead.Prev;
    CacheHead.Prev.Next := New;
    CacheHead.Prev := New;
    Cache_MakeLRU(New^);

    Result := New;
   end
  else
   Result := nil;
 end;
end;

procedure Cache_Flush;
begin
if AllowCheats or (SVS.MaxClients <= 1) then
 Cache_Force_Flush
else
 Print('Cache_Flush: Server must enable sv_cheats to activate the flush command in multiplayer games.');
end;

procedure Cache_Print;
var
 F: TFile;
 C: PCacheSystem;
begin
if not FS_Open(F, mem_dbgfile.Data, 'a') then
 Exit;

FS_FPrintF(F, 'Cache:');
C := CacheHead.Next;
while (C <> @CacheHead) and (C <> nil) do
 begin
  FS_FPrintF(F, [PLChar(@C.Name), ': ', C.Size]);
  C := C.Next;
 end;

FS_Close(F);
end;

function CacheSystemCompare(var C1, C2: TCacheSystem): Int32;
begin
Result := StrIComp(@C1.Name, @C2.Name);
end;

function ComparePath1(S1, S2: PLChar): Boolean;
begin
while not (S1^ in [#0, '\', '/']) and (S2^ > #0) do
 if S1^ <> S2^ then
  begin
   Result := False;
   Exit;
  end
 else
  begin
   Inc(UInt(S1));
   Inc(UInt(S2));
  end;

Result := True;
end;

procedure Cache_Force_Flush;
begin
while (CacheHead.Next <> @CacheHead) and (CacheHead.Next <> nil) do
 Cache_Free(CacheHead.Next.User^)
end;

procedure Cache_Report;
begin
DPrint(['Data cache: ', RoundTo((HunkSize - HunkLowUsed - HunkHighUsed) / (1024 * 1024), -3), ' MB.']);
end;

procedure Cache_Compact;
begin

end;

procedure Cmd_Flush; cdecl;
begin
Cache_Flush;
end;

procedure Cache_Init;
begin
CacheHead.Next := @CacheHead;
CacheHead.Prev := @CacheHead;
CacheHead.LRUNext := @CacheHead;
CacheHead.LRUPrev := @CacheHead;

Cmd_AddCommand('flush', @Cmd_Flush);
end;

procedure Cache_Free(var C: TCacheUser);
var
 C2: PCacheSystem;
begin
if C.Data = nil then
 Sys_Error('Cache_Free: Not allocated.');

C2 := Pointer(UInt(C.Data) - SizeOf(C2^));
C2.Prev.Next := C2.Next;
C2.Next.Prev := C2.Prev;
C2.Next := nil;
C2.Prev := nil;

C.Data := nil;

Cache_UnlinkLRU(C2^);
end;

function Cache_TotalUsed: UInt;
var
 C: PCacheSystem;
begin
Result := 0;
C := CacheHead.Next;
while (C <> @CacheHead) and (C <> nil) do
 begin
  Inc(Result, C.Size);
  C := C.Next;
 end;
end;

function Cache_Check(var C: TCacheUser): Pointer;
var
 C2: PCacheSystem;
begin
if (@C <> nil) and (C.Data <> nil) then
 begin
  C2 := Pointer(UInt(C.Data) - SizeOf(C2^));
  Cache_UnlinkLRU(C2^);
  Cache_MakeLRU(C2^);

  Result := C.Data;
 end
else
 Result := nil;
end;

function Cache_Alloc(var C: TCacheUser; Size: UInt; Name: PLChar): Pointer;
var
 C2: PCacheSystem;
begin
if C.Data <> nil then
 Sys_Error('Cache_Alloc: Already allocated.')
else
 if Size = 0 then
  Sys_Error('Cache_Alloc: Invalid size.');

Size := (Size + SizeOf(C2^) + 15) and not Byte(15);

repeat
 C2 := Cache_TryAlloc(Size, False);
 if C2 <> nil then
  Break;

 if CacheHead.LRUPrev = @CacheHead then
  Sys_Error('Cache_Alloc: Out of memory.');

 Cache_Free(CacheHead.LRUPrev.User^);
until False;

StrLCopy(@C2.Name, Name, CACHE_NAME_SIZE - 1);
C.Data := Pointer(UInt(C2) + SizeOf(C2^));
C2.User := @C;

Result := Cache_Check(C);
end;

procedure Cache_Print_Models_And_Totals; cdecl;
var
 F: TFile;
 C: PCacheSystem;
 Total: UInt;
begin
if not FS_Open(F, mem_dbgfile.Data, 'a') then
 Exit;

Total := 0;
FS_FPrintF(F, 'Cached models:');

C := CacheHead.Next;
repeat
 if StrPos(@C.Name, '.mdl') <> nil then
  begin
   Inc(Total, C.Size);
   FS_FPrintF(F, ['"', PLChar(@C.Name), '": ', C.Size]);
  end;

 C := C.Next;
until (C = @CacheHead) or (C = nil);

FS_FPrintF(F, ['Total bytes in cache used by models: ', Total, '.']);
FS_Close(F);
end;

procedure Cache_Print_Sounds_And_Totals; cdecl;
var
 F: TFile;
 C: PCacheSystem;
 Total: UInt;
begin
if not FS_Open(F, mem_dbgfile.Data, 'a') then
 Exit;

Total := 0;
FS_FPrintF(F, 'Cached sounds:');

C := CacheHead.Next;
repeat
 if StrPos(@C.Name, '.wav') <> nil then
  begin
   Inc(Total, C.Size);
   FS_FPrintF(F, ['"', PLChar(@C.Name), '": ', C.Size]);
  end;

 C := C.Next;
until (C = @CacheHead) or (C = nil);

FS_FPrintF(F, ['Total bytes in cache used by sounds: ', Total, '.']);
FS_Close(F);
end;

procedure SZ_Alloc(Name: PLChar; var Buffer: TSizeBuf; Size: UInt);
begin
if Size < 256 then
 Size := 256;

Buffer.Name := Name;
Buffer.AllowOverflow := [];
Buffer.Data := Hunk_AllocName(Size, Name);
Buffer.MaxSize := Size;
Buffer.CurrentSize := 0;
end;

procedure SZ_Clear(var Buffer: TSizeBuf);
begin
Buffer.CurrentSize := 0;
Exclude(Buffer.AllowOverflow, FSB_OVERFLOWED);
end;

function SZ_GetSpace(var Buffer: TSizeBuf; Length: UInt): Pointer;
var
 P: PLChar;
begin
if Buffer.CurrentSize + Length > Buffer.MaxSize then
 begin
  if Buffer.Name <> nil then
   P := Buffer.Name
  else
   P := '???';

  if not (FSB_ALLOWOVERFLOW in Buffer.AllowOverflow) then
   if Buffer.MaxSize >= 1 then
    Sys_Error(['SZ_GetSpace: Overflow without FSB_ALLOWOVERFLOW set on "', P, '".'])
   else
    Sys_Error(['SZ_GetSpace: Tried to write to an uninitialized sizebuf: "', P, '".']);

  if Length > Buffer.MaxSize then
   if FSB_ALLOWOVERFLOW in Buffer.AllowOverflow then
    DPrint(['SZ_GetSpace: ', Length ,' is > full buffer size on "', P, '", ignoring.'])
   else
    Sys_Error(['SZ_GetSpace: ', Length ,' is > full buffer size on "', P, '".']);

  Print(['SZ_GetSpace: overflow on "', P , '".']);
  Buffer.CurrentSize := 0;
  Include(Buffer.AllowOverflow, FSB_OVERFLOWED);
 end;

Result := Pointer(UInt(Buffer.Data) + Buffer.CurrentSize);
Inc(Buffer.CurrentSize, Length);
end;

procedure SZ_Write(var Buffer: TSizeBuf; Data: Pointer; Length: UInt);
begin
if (Data <> nil) and (Length > 0) then
 Move(Data^, SZ_GetSpace(Buffer, Length)^, Length);
end;

procedure SZ_Print(var Buffer: TSizeBuf; Data: PLChar);
var
 L: UInt;
 P: Pointer;
begin
if Data <> nil then
 L := StrLen(Data) + SizeOf(Data^)
else
 L := SizeOf(Data^);

if (Buffer.CurrentSize = 0) or
   (PLChar(UInt(Buffer.Data) + Buffer.CurrentSize - 1)^ > #0) then
 Move(Data^, SZ_GetSpace(Buffer, L)^, L)
else
 if L > 1 then
  begin
   P := SZ_GetSpace(Buffer, L - 1);
   if UInt(P) > UInt(Buffer.Data) then // prevent writing before the buffer
    Move(Data^, Pointer(UInt(P) - SizeOf(LChar))^, L);
  end;
end;

function Mem_Alloc(Size: UInt): Pointer;
begin
if Size > 0 then
 begin
  GetMem(Result, Size);
  if Result = nil then
   Sys_Error(['Mem_Alloc: Cannot allocate ', Size, ' bytes.']);
 end
else
 Result := nil;
end;

function Mem_AllocN(Size: UInt): Pointer;
begin
if Size > 0 then
 GetMem(Result, Size)
else
 Result := nil;
end;

function Mem_ZeroAlloc(Size: UInt): Pointer;
begin
if Size > 0 then
 begin
  GetMem(Result, Size);
  if Result <> nil then
   MemSet(Result^, Size, 0)
  else
   Sys_Error(['Mem_ZeroAlloc: Cannot allocate ', Size, ' bytes.']);
 end
else
 Result := nil;
end;

function Mem_ReAlloc(Data: Pointer; Size: UInt): Pointer;
begin
ReallocMem(Data, Size);
Result := Data;
end;

function Mem_CAlloc(Count, Size: UInt): Pointer;
begin
Result := Mem_ZeroAlloc(Count * Size);
end;

function Mem_StrDup(S: PLChar): PLChar;
var
 L: UInt;
begin
if S <> nil then
 begin
  L := StrLen(S);
  Result := Mem_Alloc(L + SizeOf(S^));
  Result^ := #0;
  StrLCopy(Result, S, L);
 end
else
 Result := nil;
end;

function Mem_StrDupEx(S: PLChar; ExtraLen: UInt): PLChar;
var
 L: UInt;
begin
if S <> nil then
 begin
  L := StrLen(S);
  Result := Mem_Alloc(L + ExtraLen + SizeOf(S^));
  Result^ := #0;
  StrLCopy(Result, S, L);
  if ExtraLen > 0 then
   MemSet(Pointer(UInt(Result) + L + SizeOf(S^))^, ExtraLen, 0);
 end
else
 Result := nil;
end;

procedure Mem_Free(Data: Pointer);
begin
if Data <> nil then
 FreeMem(Data);
end;

procedure Mem_FreeAndNil(var Data);
begin
if Pointer(Data) <> nil then
 begin
  FreeMem(Pointer(Data));
  Pointer(Data) := nil;
 end;
end;

procedure Memory_Init(Buffer: Pointer; Size: UInt);
var
 Index: UInt;
begin
HunkBase := Buffer;
HunkSize := Size;
HunkLowUsed := 0;
HunkHighUsed := 0;

// Not initialized in HLDS
HunkTempActive := False;
HunkTempMark := 0;

Cache_Init;

Index := COM_CheckParm('-zone');
if (Index > 0) and COM_ParmInBounds(Index + 1) then
 begin
  Size := StrToInt(COM_ParmValueByIndex(Index));
  if Size = 0 then
   Sys_Error('Memory_Init: You must specify a size in KB after "-zone".')
  else
   Size := Size shl 10;
 end
else
 Size := $200000;

MainZone := Hunk_AllocName(Size, 'zone');
Z_ClearZone(MainZone^, Size);

CVar_RegisterVariable(mem_dbgfile);
CVar_RegisterVariable(mem_checkheap);
end;

end.
