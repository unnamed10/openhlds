unit Texture;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure W_ToUpper(Src, Dst: PLChar);
procedure W_ToLower(Src, Dst: PLChar);

function W_LoadWADFile(Name: PLChar): Int;
function W_GetLumpInfo(Index: UInt; Name: PLChar; Error: Boolean): PWADFileLump;
function W_GetLumpName(Index: UInt; Name: PLChar): Pointer;
function W_GetLumpNum(Index, LumpIndex: UInt): Pointer;
procedure W_Shutdown;

function TEX_InitFromWAD(Name: PLChar): Boolean;
procedure TEX_CleanupWadInfo;
function TEX_LoadLump(Name: PLChar; out Buffer: Pointer): Int;

implementation

uses Console, Common, SysMain, FileSys, Memory;

var
 WADList: array[0..1] of TWADListEntry = ((Loaded: False), (Loaded: False));

 NumTexLumps: UInt = 0;
 TexLumps: PTextureLumpArray = nil;

 NumTexFiles: UInt = 0;
 TexFiles: array[0..127] of TFile;

procedure W_ToUpper(Src, Dst: PLChar);
var
 I: UInt;
 C: LChar; 
begin
for I := 0 to MAX_LUMP_NAME - 1 do
 begin
  C := Src^;
  if Src^ = #0 then
   begin
    MemSet(Dst^, MAX_LUMP_NAME - I, 0);
    Exit;
   end
  else
   if C in ['a'..'z'] then
    Dec(C, Ord('a') - Ord('A'));

  Dst^ := C;

  Inc(UInt(Src));
  Inc(UInt(Dst));
 end;
end;

procedure W_ToLower(Src, Dst: PLChar);
var
 I: UInt;
 C: LChar; 
begin
for I := 0 to MAX_LUMP_NAME - 1 do
 begin
  C := Src^;
  if Src^ = #0 then
   begin
    MemSet(Dst^, MAX_LUMP_NAME - I, 0);
    Exit;
   end
  else
   if C in ['A'..'Z'] then
    Inc(C, Ord('a') - Ord('A'));

  Dst^ := C;

  Inc(UInt(Src));
  Inc(UInt(Dst));
 end;
end;

function W_LoadWADFile(Name: PLChar): Int;
var
 I, J: Int;
 E: PWADListEntry;
 L: PWADFileLump;
 P: PQPic;
begin
for I := Low(WADList) to High(WADList) do
 if not WADList[I].Loaded then
  begin
   E := @WADList[I];
   E.Data := COM_LoadHunkFile(Name);
   if E.Data = nil then
    begin
     if I = Low(WADList) then
      Sys_Error(['W_LoadWADFile: Couldn''t load "', Name, '".'])
     else
      Print(['W_LoadWADFile: Couldn''t load "', Name, '".']);
     Result := -1;
    end
   else
    begin
     E.Loaded := True;

     StrLCopy(@E.Name, Name, SizeOf(E.Name) - 1);
     if PUInt32(@E.Data.FileTag)^ <> WAD3_TAG then
      Sys_Error(['W_LoadWADFile: WAD file ", Name, '' doesn''t have WAD3 ID.']);

     E.NumEntries := LittleLong(E.Data.NumEntries);
     E.Entries := Pointer(UInt(E.Data) + UInt(LittleLong(E.Data.FileOffset)));

     for J := 0 to E.NumEntries - 1 do
      begin
       L := @E.Entries[J];
       L.FilePos := LittleLong(L.FilePos);
       L.DiskSize := LittleLong(L.DiskSize);
       L.Size := LittleLong(L.Size);
       W_ToLower(@L.Name, @L.Name);
       if L.LumpType = TYP_QPIC then
        begin
         P := PQPic(UInt(E.Data) + L.FilePos);
         P.Width := LittleLong(P.Width);
         P.Height := LittleLong(P.Height);
        end;
      end;

     Result := I;
    end;

   Exit;
  end;

Print(['No room for WAD file "', Name, '".']);
Result := -1; 
end;

function W_GetLumpInfo(Index: UInt; Name: PLChar; Error: Boolean): PWADFileLump;
var
 Buf: array[1..MAX_LUMP_NAME] of LChar;
 I: Int;
 E: PWADListEntry;
begin
if Index > High(WADList) then
 Sys_Error('W_GetLumpInfo: Invalid index.');

W_ToLower(Name, @Buf);
E := @WADList[Index];
for I := 0 to E.NumEntries - 1 do
 if Compare16(@Buf, @E.Entries[I].Name) then
  begin
   Result := @E.Entries[I];
   Exit;
  end;

if Error then
 Sys_Error(['W_GetLumpInfo: Couldn''t find "', Name, '".']);
Result := nil;
end;

function W_GetLumpName(Index: UInt; Name: PLChar): Pointer;
var
 P: PWADFileLump;
begin
if Index > High(WADList) then
 Sys_Error('W_GetLumpName: Invalid index.');

P := W_GetLumpInfo(Index, Name, True);
Result := Pointer(UInt(WADList[Index].Data) + P.FilePos);
end;

function W_GetLumpNum(Index, LumpIndex: UInt): Pointer;
begin
if Index > High(WADList) then
 Sys_Error('W_GetLumpNum: Invalid WAD index.')
else
 if (LumpIndex >= WADList[Index].NumEntries) then
  Sys_Error('W_GetLumpNum: Invalid lump index.');

Result := Pointer(UInt(WADList[Index].Data) + WADList[Index].Entries[LumpIndex].FilePos);
end;

procedure W_Shutdown;
var
 E: PWADListEntry;
 I: UInt;
begin
for I := Low(WADList) to High(WADList) do
 begin
  E := @WADList[I];
  if not E.Loaded then
   Break
  else
   MemSet(E^, SizeOf(E^), 0);
 end;
end;

function TEX_InitFromWAD(Name: PLChar): Boolean;
var
 Buf, Buf2: array[1..MAX_PATH_W] of LChar;
 P, P2: PLChar;
 F: TFile;
 Header: TWADFileHeader;
 I: Int;
 L: PTextureLump;
 ID: UInt;
begin
P := StrLCopy(@Buf, Name, SizeOf(Buf) - 2);

repeat
 P2 := StrScan(P, ';');
 if P2 <> nil then
  P2^ := #0
 else
  Break;

 P := COM_FileBase(P, @Buf2);
 COM_FixSlashes(P);
 COM_DefaultExtension(P, '.wad');
 if (StrPos(P, 'pldecal') = nil) and (StrPos(P, 'tempdecal') = nil) then
  if not FS_Open(F, P, 'r') then
   Sys_Error(['TEX_InitFromWAD: Couldn''t open "', P, '".'])
  else
   begin
    TexFiles[NumTexFiles] := F;
    ID := NumTexFiles;
    Inc(NumTexFiles);
    DPrint(['Using WAD file: "', P, '".']);
    if FS_Read(F, @Header, SizeOf(Header)) < SizeOf(Header) then
     Sys_Error(['TEX_InitFromWAD: "', P, '": File read error.'])
    else
     if (PUInt32(@Header.FileTag)^ <> WAD2_TAG) and (PUInt32(@Header.FileTag)^ <> WAD3_TAG) then
      Sys_Error(['TEX_InitFromWAD: "', P, '" doesn''t have WAD2/WAD3 tag.'])
     else
      begin
       Header.NumEntries := LittleLong(Header.NumEntries);
       Header.FileOffset := LittleLong(Header.FileOffset);
       FS_Seek(F, Header.FileOffset, SEEK_SET);
       TexLumps := Mem_ReAlloc(TexLumps, SizeOf(TTextureLump) * (NumTexLumps + Header.NumEntries));

       for I := NumTexLumps to NumTexLumps + Header.NumEntries - 1 do
        begin
         L := @TexLumps[I];
         FS_Read(F, @L.Lump, SizeOf(L.Lump));
         W_ToUpper(@L.Lump.Name, @L.Lump.Name);
         L.Lump.FilePos := LittleLong(L.Lump.FilePos);
         L.Lump.DiskSize := LittleLong(L.Lump.DiskSize);
         L.Lump.Size := LittleLong(L.Lump.Size);
         L.FileID := ID;
        end;

       Inc(NumTexLumps, Header.NumEntries);
      end;
   end;

 P := PLChar(UInt(P2) + SizeOf(P2^));
until P^ = #0;

Result := True;
end;

procedure TEX_CleanupWadInfo;
var
 I: Int;
begin
if TexLumps <> nil then
 Mem_FreeAndNil(TexLumps);

for I := 0 to NumTexFiles - 1 do
 FS_Close(TexFiles[I]);

NumTexFiles := 0;
NumTexLumps := 0;
end;

function TEX_LoadLump(Name: PLChar; out Buffer: Pointer): Int;
var
 I: Int;
 Buf: array[1..MAX_LUMP_NAME] of LChar;
 P: PTextureLump;
begin
Result := 0;
W_ToUpper(Name, @Buf);

for I := 0 to NumTexLumps - 1 do
 begin
  P := @TexLumps[I];
  if Compare16(@Buf, @P.Lump.Name) then
   begin
    FS_Seek(TexFiles[P.FileID], P.Lump.FilePos, SEEK_SET);

    Buffer := Mem_Alloc(P.Lump.DiskSize);
    if Buffer = nil then
     Sys_Error('TEX_LoadLump: Out of memory.')
    else
     if FS_Read(TexFiles[P.FileID], Buffer, P.Lump.DiskSize) < P.Lump.DiskSize then
      Sys_Error('TEX_LoadLump: File read error.')
     else
      Result := P.Lump.DiskSize;

    Exit;
   end;
 end;

Buffer := nil;
Print(['TEX_LoadLump: Warning: Texture lump "', Name, '" was not found.']);
end;

end.
