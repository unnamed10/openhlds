unit Decal;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure Draw_MiptexTexture(P: PCacheWAD; Data: PTexture);
procedure Draw_CacheWADInit(Name: PLChar; Count: UInt; P: PCacheWAD);
function Draw_CustomCacheWADInit(Count: UInt; P: PCacheWAD; Header: PWADFileHeader; Size: UInt): Boolean;
procedure Draw_FreeWAD(P: PCacheWAD);
procedure Decal_MergeInDecals(P: PCacheWAD; Name: PLChar);
procedure Decal_Init;
function Draw_CacheGet(P: PCacheWAD; Index: UInt): Pointer;
function Draw_ValidateCustomLogo(P: PCacheWAD; Data: Pointer; Decal: PWADFileLump): Boolean;
procedure Draw_Shutdown;
procedure Draw_DecalShutdown;
function CustomDecal_Init(Decal: PCacheWAD; Header: PWADFileHeader; Size: UInt; Index: Int): Boolean;
function CustomDecal_Validate(Header: PWADFileHeader; Size: UInt): Boolean;
function Draw_DecalCount: UInt;
function Draw_DecalName(Index: UInt): PLChar;
function Draw_DecalSize(Index: UInt): UInt;
function Draw_CacheReload(P: PCacheWAD; Index: UInt; Decal: PWADFileLump; Cache: PCacheWADData; CacheName, Name: PLChar): Boolean;
function Draw_CacheLoadFromCustom(Name: PLChar; P: PCacheWAD; Header: PWADFileHeader; Size: UInt; Cache: PCacheWADData): Boolean;
procedure Draw_AllocateCacheSpace(P: PCacheWAD; Count: UInt);
procedure Draw_CacheWADHandler(P: PCacheWAD; Func: Pointer; ExtraOffset: UInt);
function Draw_CustomCacheGet(P: PCacheWAD; Header: PWADFileHeader; Size, Index: UInt): Pointer;
function Draw_CacheIndex(P: PCacheWAD; Name: PLChar): UInt;
procedure Draw_CacheWADInitFromFile(F: TFile; Size: UInt; Name: PLChar; Count: UInt; P: PCacheWAD);
procedure Decal_ReplaceOrAppendLump(var Decal: PWADDecal; Lump: PWADFileLump; Custom: Boolean);
function Decal_CountLumps(Decal: PWADDecal): UInt;
function Decal_SizeLumps(Decal: PWADDecal): UInt;
function Draw_CacheFindIndex(P: PCacheWAD; Name: PLChar): Int;

implementation

uses Common, Console, FileSys, Memory, Model, SVMain, SysMain, Texture;

var
 DrawInitialized: Boolean = False;
 MenuWAD: PCacheWAD = nil;
 DecalWAD: PCacheWAD = nil;

 CustomBuild: Boolean = False;
 CustomName: array[1..10] of LChar; // 11?

procedure Draw_Shutdown;
begin
if DrawInitialized then
 begin
  DrawInitialized := False;
  if MenuWAD <> nil then
   begin
    Draw_FreeWAD(MenuWAD);
    Mem_FreeAndNil(MenuWAD);
   end;
 end;
end;

procedure Draw_DecalShutdown;
begin
if DecalWAD <> nil then
 begin
  Draw_FreeWAD(DecalWAD);
  Mem_FreeAndNil(DecalWAD);
 end;
end;

procedure Draw_FreeWAD(P: PCacheWAD);
var
 I: Int;
 Cache: PCacheUser;
begin
if P = nil then
 Exit;

if P.Decals <> nil then
 Mem_FreeAndNil(P.Decals);

Mem_Free(P.Name);
if P.NameCount > 0 then
 begin
  for I := 0 to P.NameCount - 1 do
   Mem_FreeAndNil(P.NameList[I]);
  Mem_FreeAndNil(P.NameList);
 end;

if P.CustomDecals <> nil then
 Mem_FreeAndNil(P.CustomDecals);

if P.Cache <> nil then
 begin
  for I := 0 to P.ItemsCount - 1 do
   begin
    Cache := @P.Cache[I].CacheUser;
    if Cache_Check(Cache^) <> nil then
     Cache_Free(Cache^);
   end;

  Mem_Free(P.Cache);
 end;
end;

procedure Draw_AllocateCacheSpace(P: PCacheWAD; Count: UInt);
begin
P.Cache := Mem_ZeroAlloc(Count * SizeOf(TCacheWADData));
end;

procedure Draw_CacheWADInitFromFile(F: TFile; Size: UInt; Name: PLChar; Count: UInt; P: PCacheWAD);
var
 Header: TWADFileHeader;
 I: Int;
 S: PLChar;
begin
if FS_Read(F, @Header, SizeOf(Header)) <> SizeOf(Header) then
 Sys_Error('Draw_CacheWADInitFromFile: File read error.')
else
 if PUInt32(@Header.FileTag)^ <> WAD3_TAG then
  Sys_Error(['Draw_CacheWADInitFromFile: WAD file "', Name, '" doesn''t have WAD3 ID.'])
 else
  if Header.FileOffset > Size then
   Sys_Error('Draw_CacheWADInitFromFile: Invalid lump offset.')
  else
   begin
    Dec(Size, Header.FileOffset);
    P.Decals := Mem_Alloc(Size);

    FS_Seek(F, Header.FileOffset, SEEK_SET);
    if FS_Read(F, P.Decals, Size) <> Size then
     Sys_Error('Draw_CacheWADInitFromFile: File read error.');

    for I := 0 to Header.NumEntries - 1 do
     begin
      S := @P.Decals[I].Name;
      W_ToLower(S, S);
     end;

    P.DecalCount := Header.NumEntries;
    P.ItemsCount := 0;
    P.ItemsTotal := Count;
    P.Name := Mem_StrDup(Name);
    Draw_AllocateCacheSpace(P, Count);
    P.LoadCallback := nil;
    P.ExtraOffset := 0;
   end;
end;

procedure Draw_CacheWADInit(Name: PLChar; Count: UInt; P: PCacheWAD);
var
 F: TFile;
begin
if not FS_Open(F, Name, 'r') then
 Sys_Error(['Draw_CacheWADInit: Couldn''t open "', Name, '".'])
else
 begin
  Draw_CacheWADInitFromFile(F, FS_Size(F), Name, Count, P);
  FS_Close(F);
 end;
end;

function Draw_CustomCacheWADInit(Count: UInt; P: PCacheWAD; Header: PWADFileHeader; Size: UInt): Boolean;
var
 Decal: PWADFileLump;
begin
if PUInt32(@Header.FileTag)^ <> WAD3_TAG then
 Print('Custom file doesn''t have WAD3 ID.')
else
 if Header.NumEntries <> 1 then
  Print(['Custom file has wrong number of lumps: ', Header.NumEntries])
 else
  if Header.FileOffset = 0 then
   Print(['Custom file has invalid info table offset: ', Header.FileOffset])
  else
   if Header.FileOffset + SizeOf(TWADFileLump) <> Size then
    Print(['Custom file has invalid info table offset: ', Header.FileOffset + SizeOf(TWADFileLump), ' > ', Size])
   else
    begin
     Dec(Size, Header.FileOffset);
     P.Decals := Mem_Alloc(Size);
     Move(Pointer(UInt(Header) + Header.FileOffset)^, P.Decals^, Size);

     Decal := @P.Decals[Low(P.Decals^)];
     W_ToLower(@Decal.Name, @Decal.Name);

     if Decal.Size <> Decal.DiskSize then
      Print(['Custom file has mismatched lump size: ', Decal.Size, '; ', Decal.DiskSize])
     else
      if Decal.Size = 0 then
       Print(['Custom file has invalid lump size: ', Decal.Size])
      else
       if Decal.FilePos < SizeOf(TWADFileHeader) then
        Print(['Custom file has invalid lump offset: ', Decal.FilePos])
       else
        if Decal.DiskSize + Decal.FilePos > Header.FileOffset then
         Print('Custom file has invalid lump at #0.')
        else
         begin
          P.DecalCount := 1;
          P.ItemsCount := 0;
          P.ItemsTotal := Count;
          P.Name := Mem_StrDup('tempdecal.wad');
          Draw_AllocateCacheSpace(P, Count);
          P.LoadCallback := nil;
          P.ExtraOffset := 0;
          Result := True;
          Exit;
         end;
    end;

Result := False;
end;

// not exactly a PWADTexture. this thing changes the format in-place, wiping the old one
procedure Draw_MiptexTexture(P: PCacheWAD; Data: PTexture);
var
 Texture: TMiptex;
 I: Int;
 Size: UInt;
 Palette: PWADPalette;
begin
if P.ExtraOffset <> DECAL_EXTRAOFFSET then
 Sys_Error(['Draw_MiptexTexture: Invalid cached WAD file "', P.Name, '".']);

Move(Pointer(UInt(Data) + P.ExtraOffset)^, Texture, SizeOf(Texture));
Move(Texture.Name, Data.Name, SizeOf(Data.Name));

with Data^ do
 begin
  Width := LittleLong(Texture.Width);
  Height := LittleLong(Texture.Height);
  AnimTotal := 0;
  AnimMin := 0;
  AnimMax := 0;
  AnimNext := nil;
  AlternateAnims := nil;
  for I := Low(Offsets) to High(Offsets) do
   Offsets[I] := UInt(LittleLong(Texture.Offsets[I])) + P.ExtraOffset;
 end;

Size := Data.Width * Data.Height +
        (Data.Width * Data.Height) shr 2 +
        (Data.Width * Data.Height) shr 4 +
        (Data.Width * Data.Height) shr 6;

Data.PaletteOffset := Size + Data.Offsets[Low(Data.Offsets)] + SizeOf(UInt16);
Palette := Pointer(UInt(Data) + Data.PaletteOffset);

if CustomBuild then
 begin
  StrLCopy(@Data.Name, @CustomName, SizeOf(Data.Name) - 1);
  Data.Name[High(Data.Name)] := #0;
 end;

with Palette[High(Palette^)] do
 if (R > 0) or (G > 0) or (B <> 255) then
  Data.Name[Low(Data.Name)] := '}'
 else
  Data.Name[Low(Data.Name)] := '{';
end;

procedure Draw_CacheWADHandler(P: PCacheWAD; Func: Pointer; ExtraOffset: UInt);
begin
P.LoadCallback := Func;
P.ExtraOffset := ExtraOffset;
end;

procedure Decal_ReplaceOrAppendLump(var Decal: PWADDecal; Lump: PWADFileLump; Custom: Boolean);
var
 P: PWADDecal;
begin
P := Decal;
                          
while P <> nil do
 if StrIComp(@Lump.Name, @P.Lump.Name) = 0 then
  begin
   Mem_Free(P.Lump);
   P.Lump := Mem_Alloc(SizeOf(P.Lump^));
   Move(Lump^, P.Lump^, SizeOf(P.Lump^));
   P.Custom := Custom;
   Exit;
  end
 else
  P := P.Next;

P := Mem_ZeroAlloc(SizeOf(P^));
P.Lump := Mem_Alloc(SizeOf(P.Lump^));
Move(Lump^, P.Lump^, SizeOf(P.Lump^));
P.Custom := Custom;
P.Next := Decal;
Decal := P;
end;

function Decal_CountLumps(Decal: PWADDecal): UInt;
begin
Result := 0;

while Decal <> nil do
 begin
  Inc(Result);
  Decal := Decal.Next;
 end;
end;

function Decal_SizeLumps(Decal: PWADDecal): UInt;
begin
Result := Decal_CountLumps(Decal) * SizeOf(TWADFileLump);
end;

procedure Decal_MergeInDecals(P: PCacheWAD; Name: PLChar);
var
 I: Int;
 P2: PCacheWAD;
 Decal: PWADDecal;
 DecalNext: PWADDecal;
begin
if P = nil then
 Sys_Error('Decal_MergeInDecals called with invalid WAD pointer.');

Decal := nil;

if DecalWAD <> nil then
 begin
  P2 := Mem_ZeroAlloc(SizeOf(P2^));

  for I := 0 to DecalWAD.DecalCount - 1 do
   Decal_ReplaceOrAppendLump(Decal, @DecalWAD.Decals[I], False);

  for I := 0 to P.DecalCount - 1 do
   Decal_ReplaceOrAppendLump(Decal, @P.Decals[I], True);

  P2.DecalCount := Decal_CountLumps(Decal);
  P2.ItemsCount := 0;
  P2.ItemsTotal := DecalWAD.ItemsTotal;
  P2.Name := Mem_StrDup(DecalWAD.Name);
  Draw_AllocateCacheSpace(P2, P2.ItemsTotal);
  P2.LoadCallback := @DecalWAD.LoadCallback;
  P2.ExtraOffset := DecalWAD.ExtraOffset;
  P2.CustomDecals := Mem_ZeroAlloc(P2.ItemsTotal * SizeOf(PLChar));
  P2.NameCount := 2;
  P2.NameList := Mem_Alloc(P2.NameCount * SizeOf(PLChar)); 
  P2.NameList[0] := Mem_StrDup(DecalWAD.NameList[0]);
  P2.NameList[1] := Mem_StrDup(Name);
  P2.Decals := Mem_Alloc(Decal_SizeLumps(Decal));

  I := Low(P2.Decals^);
  while Decal <> nil do
   begin
    DecalNext := Decal.Next;
    Move(Decal.Lump^, P2.Decals[I], SizeOf(P2.Decals[I]));
    Mem_FreeAndNil(Decal.Lump);

    P2.CustomDecals[I] := Decal.Custom;
    Mem_Free(Decal);
    Inc(I);
    Decal := DecalNext;
   end;    

  if DecalWAD <> nil then
   begin
    Draw_FreeWAD(DecalWAD);
    Mem_Free(DecalWAD);
   end;

  DecalWAD := P2;
  if P <> nil then
   begin
    Draw_FreeWAD(P);
    Mem_Free(P);
   end;
 end
else
 begin
  DecalWAD := P;
  P.NameCount := 1;
  P.NameList := Mem_Alloc(SizeOf(PLChar));
  P.NameList[0] := Mem_StrDup(Name);
  P.CustomDecals := Mem_ZeroAlloc(P.ItemsTotal * SizeOf(PLChar));
 end;
end;

function Draw_DecalCount: UInt;
begin
if DecalWAD <> nil then
 Result := DecalWAD.DecalCount
else
 Result := 0;
end;

function Draw_DecalName(Index: UInt): PLChar;
begin
if DecalWAD <> nil then
 if Index >= DecalWAD.DecalCount then
  Result := nil
 else
  Result := @DecalWAD.Decals[Index].Name
else
 Result := nil;
end;

function Draw_DecalSize(Index: UInt): UInt;
begin
if DecalWAD <> nil then
 if Index >= DecalWAD.DecalCount then
  Result := 0
 else
  Result := DecalWAD.Decals[Index].Size
else
 Result := 0;
end;

procedure Decal_Init;
const
 PathIDTable: array[1..2] of array[0..15] of LChar =
              ('DEFAULTGAME'#0, 'GAME'#0);
var
 I: Int;
 F: TFile;
 P: PCacheWAD;
 S: PLChar;
begin
Draw_DecalShutdown;

for I := Low(PathIDTable) to High(PathIDTable) do
 if FS_OpenPathID(F, 'decals.wad', 'r', PathIDTable[I]) then
  begin
   P := Mem_ZeroAlloc(SizeOf(P^));
   Draw_CacheWADInitFromFile(F, FS_Size(F), 'decals.wad', 512, P);
   Draw_CacheWADHandler(P, @Draw_MiptexTexture, DECAL_EXTRAOFFSET);
   Decal_MergeInDecals(P, PathIDTable[I]); // double check it
   FS_Close(F);
  end
 else
  if I = Low(PathIDTable) then
   Sys_Error('Couldn''t find "decals.wad" in default search path.');

SVDecalNameCount := Draw_DecalCount;
if SVDecalNameCount > MAX_DECAL_NAMES then
 Sys_Error(['Too many decals: ', SVDecalNameCount, ' / ', MAX_DECAL_NAMES, '.']);

for I := 0 to SVDecalNameCount - 1 do
 begin
  MemSet(SVDecalNames[I], SizeOf(SVDecalNames[I]), 0);
  S := Draw_DecalName(I);
  if S <> nil then
   StrLCopy(@SVDecalNames[I], S, SizeOf(SVDecalNames[I]) - 2);
 end;
end;

function Draw_CacheReload(P: PCacheWAD; Index: UInt; Decal: PWADFileLump; Cache: PCacheWADData; CacheName, Name: PLChar): Boolean;
var
 F: TFile;
 Data: Pointer;
begin
if P.NameCount <= 0 then
 Result := FS_Open(F, P.Name, 'r')
else
 Result := FS_OpenPathID(F, P.Name, 'r', P.NameList[UInt(P.CustomDecals[Index])]);

if Result then
 begin
  Data := Cache_Alloc(Cache.CacheUser, Decal.Size + P.ExtraOffset + 1, CacheName);
  if Data = nil then
   Sys_Error(['Draw_CacheReload: Not enough space for "', Name, '" in "', P.Name, '".']);

  PLChar(UInt(Data) + Decal.Size + P.ExtraOffset)^ := #0;
  FS_Seek(F, Decal.FilePos, SEEK_SET);
  if FS_Read(F, Pointer(UInt(Data) + P.ExtraOffset), Decal.Size) <> Decal.Size then
   begin
    FS_Close(F);
    Sys_Error('Draw_CacheReload: File read error.');
   end
  else
   FS_Close(F);

  if @P.LoadCallback <> nil then
   P.LoadCallback(P, Data);
 end;
end;

function Draw_CacheGet(P: PCacheWAD; Index: UInt): Pointer;
var
 Data: PCacheWADData;
 Name: array[1..MAX_LUMP_NAME] of LChar;
 I: Int;
 Buf: array[1..MAX_PATH_W] of LChar;
begin
if Index >= P.ItemsCount then
 Sys_Error(['Draw_CacheGet: WAD file "', P.Name, '" was indexed before load (index = ', Index, ').']);

Data := @P.Cache[Index];
Result := Cache_Check(Data.CacheUser);
if Result = nil then
 begin
  W_ToLower(COM_FileBase(@Data.Name, @Buf), @Name);
  for I := 0 to P.DecalCount - 1 do
   if Compare16(@Name, @P.Decals[I].Name) then
    begin
     if not Draw_CacheReload(P, I, @P.Decals[I], Data, @Name, @Data.Name) then
      Result := nil
     else
      begin
       Result := Data.CacheUser.Data;
       if Result = nil then
        Sys_Error(['Draw_CacheGet: Failed to load "', PLChar(@Data.Name), '".']);
      end;

     Exit;
    end;
    
  Result := nil;
 end;
end;

function Draw_ValidateCustomLogo(P: PCacheWAD; Data: Pointer; Decal: PWADFileLump): Boolean;
var
 FT: TMiptex;
 MT: TTexture;
 I, Size, ImageSize: UInt;
 PaletteCount: UInt16;
begin
Result := False;

if P.ExtraOffset <> DECAL_EXTRAOFFSET then
 begin
  Print(['Draw_ValidateCustomLogo: Invalid cached WAD file "', P.Name, '".']);
  Exit;
 end;

Move(Pointer(UInt(Data) + P.ExtraOffset)^, FT, SizeOf(FT));
Move(Data^, MT, SizeOf(MT));
Move(FT.Name, MT.Name, SizeOf(MT.Name));

for I := Low(FT.Offsets) to High(FT.Offsets) do
 FT.Offsets[I] := LittleLong(FT.Offsets[I]);

with MT do
 begin
  Width := LittleLong(FT.Width);
  Height := LittleLong(FT.Height);
  AnimTotal := 0;
  AnimMin := 0;
  AnimMax := 0;
  AnimNext := nil;
  AlternateAnims := nil;
  for I := Low(Offsets) to High(Offsets) do
   Offsets[I] := FT.Offsets[I] + P.ExtraOffset;
 end;

Size := MT.Width * MT.Height +
        (MT.Width * MT.Height) shr 2 +
        (MT.Width * MT.Height) shr 4 +
        (MT.Width * MT.Height) shr 6;
ImageSize := MT.Width * MT.Height;

PaletteCount := PUInt16(UInt(Data) + DECAL_EXTRAOFFSET + SizeOf(TMiptex) + Size)^;
if (MT.Width = 0) or (MT.Height = 0) or (MT.Width > 256) or (MT.Height > 256) then
 begin
  Print(['Draw_ValidateCustomLogo: Invalid cached WAD file "', P.Name, '".']);
  Exit;
 end;

for I := 0 to MIPLEVELS - 2 do
 begin
  if FT.Offsets[I] + ImageSize <> FT.Offsets[I + 1] then
   begin
    Print(['Draw_ValidateCustomLogo: Invalid cached WAD file "', P.Name, '".']);
    Exit;
   end;

  ImageSize := ImageSize shr 2;
 end;

if PaletteCount > SizeOf(TWADPalette) then
 begin
  Print(['Draw_ValidateCustomLogo: Invalid palette size (', PaletteCount, ') in WAD file "', P.Name, '".']);
  Exit;
 end;

if SizeOf(TRGBColor) * PaletteCount + SizeOf(PaletteCount) + Size + FT.Offsets[Low(FT.Offsets)] > Decal.DiskSize then
 Print(['Draw_ValidateCustomLogo: Invalid cached WAD file "', P.Name, '".'])
else
 Result := True;
end;

function Draw_CacheByIndex(P: PCacheWAD; DecalIndex, PlayerIndex: Int): UInt;
var
 IntBuf, ExpandBuf: array[1..32] of LChar;
 Buf: array[1..64] of LChar;
 S: PLChar;
 I: UInt;
begin
S := StrECopy(@Buf, ExpandString(IntToStr(PlayerIndex, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 3));
StrCopy(S, ExpandString(IntToStr(DecalIndex, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));

I := 0;
while (I < P.ItemsCount) and (StrComp(@Buf, @P.Cache[I].Name) <> 0) do
 Inc(I);

if I = P.ItemsCount then
 begin
  if I = P.ItemsTotal then
   Sys_Error(['Cached WAD "', P.Name, '" out of ', P.ItemsCount, ' entries.']);

  Inc(P.ItemsCount);
  StrLCopy(@P.Cache[I].Name, @Buf, SizeOf(P.Cache[I].Name) - 1);
 end;

Result := I;
end;

function Draw_CacheLoadFromCustom(Name: PLChar; P: PCacheWAD; Header: PWADFileHeader; Size: UInt; Cache: PCacheWADData): Boolean;
var
 Index: UInt;
 Decal: PWADFileLump;
 Data: Pointer;
begin
if StrLen(Name) >= 5 then
 begin
  Index := StrToInt(PLChar(UInt(Name) + 3));
  if Index >= P.DecalCount then
   begin
    Result := False;
    Exit;
   end;
 end
else
 Index := 0;

Decal := @P.Decals[Index];

Data := Cache_Alloc(Cache.CacheUser, Decal.Size + P.ExtraOffset + 1, Name);
if Data = nil then
 Sys_Error(['Draw_CacheLoadFromCustom: Not enough space for "', Name, '" in "', P.Name, '".']);

PByte(UInt(Data) + Decal.Size + P.ExtraOffset)^ := 0;
Move(Pointer(UInt(Header) + Decal.FilePos)^, Pointer(UInt(Data) + P.ExtraOffset)^, Decal.Size);
if not Draw_ValidateCustomLogo(P, Data, Decal) then
 begin
  Result := False;
  Exit;
 end;

CustomBuild := True;
CustomName[1] := 'T';
StrLCopy(PLChar(UInt(@CustomName) + 1), Name, 5);
CustomName[7] := #0;

if @P.LoadCallback <> nil then
 P.LoadCallback(P, Data);

CustomBuild := False;
Result := True;
end;

function Draw_CustomCacheGet(P: PCacheWAD; Header: PWADFileHeader; Size, Index: UInt): Pointer;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 Cache: PCacheWADData;
 Name, FileName: array[1..MAX_LUMP_NAME] of LChar;
begin
if Index >= P.ItemsCount then
 Sys_Error(['Draw_CustomCacheGet: WAD file "', P.Name, '" was indexed before load (index = ', Index, ').']);

Cache := @P.Cache[Index];
Result := Cache_Check(Cache.CacheUser);
if Result = nil then
 begin
  StrLCopy(@FileName, COM_FileBase(@Cache.Name, @Buf), MAX_LUMP_NAME - 1);
  W_ToLower(@FileName, @Name);
  if Draw_CacheLoadFromCustom(@Name, P, Header, Size, Cache) then
   begin
    Result := Cache.CacheUser.Data;
    if Result = nil then
     Sys_Error(['Draw_CustomCacheGet: Failed to load "', PLChar(@Cache.Name), '".']);
   end;
 end;
end;

function CustomDecal_Validate(Header: PWADFileHeader; Size: UInt): Boolean;
var
 P: PCacheWAD;
begin
P := Mem_ZeroAlloc(SizeOf(P^));
if P <> nil then
 begin
  if CustomDecal_Init(P, Header, Size, -2) then
   Result := Draw_CustomCacheGet(P, Header, Size, 0) <> nil
  else
   Result := False;

  Draw_FreeWAD(P);
  Mem_Free(P);
 end
else
 Result := False;
end;

function CustomDecal_Init(Decal: PCacheWAD; Header: PWADFileHeader; Size: UInt; Index: Int): Boolean;
var
 I: Int;
begin
Result := Draw_CustomCacheWADInit(16, Decal, Header, Size);
if Result then
 begin
  Draw_CacheWADHandler(Decal, @Draw_MiptexTexture, DECAL_EXTRAOFFSET);
  for I := 0 to Decal.DecalCount - 1 do
   Draw_CacheByIndex(Decal, I, Index);
 end;
end;

function Draw_CacheIndex(P: PCacheWAD; Name: PLChar): UInt;
var
 I: UInt;
begin
I := 0;
while (I < P.ItemsCount) and (StrComp(Name, @P.Cache[I].Name) <> 0) do
 Inc(I);

if I = P.ItemsCount then
 begin
  if I = P.ItemsTotal then
   Sys_Error(['Cached WAD "', P.Name, '" out of ', P.ItemsTotal, ' entries.']);

  Inc(P.ItemsCount);
  StrLCopy(@P.Cache[I].Name, Name, SizeOf(P.Cache[I].Name) - 1);
 end;

Result := I;
end;

function Draw_CacheFindIndex(P: PCacheWAD; Name: PLChar): Int;
var
 I: Int;
begin
for I := 0 to P.ItemsCount - 1 do
 if StrComp(Name, @P.Cache[I].Name) = 0 then
  begin
   Result := I;
   Exit;
  end;

Result := -1;
end;

end.
