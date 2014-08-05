unit Texture;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure W_CleanupName(Source, Dest: PLChar);
function W_LoadWADFile(Name: PLChar): Int;
function W_GetLumpInfo(Index: UInt; Name: PLChar; Error: Boolean): PWADFileLump;
function W_GetLumpName(WADIndex: UInt; Name: PLChar): Pointer;
function W_GetLumpNum(WADIndex, Index: UInt): Pointer;
procedure W_Shutdown;
procedure SwapPic(var P: TQPic);

function TEX_InitFromWAD(Name: PLChar): Boolean;
procedure TEX_CleanupWadInfo;
function TEX_LoadLump(Name: PLChar; Buffer: Pointer): Int;
procedure TEX_AddAnimatingTextures;

implementation

uses Console, Common, SysMain, FileSys, Memory;

var
 WADList: array[0..1] of TWADListEntry = ((Loaded: False), (Loaded: False));
 NumMiptex: UInt = 0;
 Miptex: array[0..MAX_MAP_TEXTURES - 1] of TTextureRef;

 NumTexLumps: UInt = 0;
 TexLumps: PTextureLumpArray = nil;

 NumTexFiles: UInt = 0;
 TexFiles: array[0..127] of TFile;

procedure W_CleanupName(Source, Dest: PLChar);
var
 I: Int;
 C: LChar;
begin
for I := 0 to MAX_LUMP_NAME - 1 do
 begin
  C := Source^;
  if C = #0 then
   begin
    MemSet(Dest^, MAX_LUMP_NAME - I, 0);
    Exit;     
   end
  else
   if C in ['A'..'Z'] then
    Inc(C, Ord('a') - Ord('A'));

  Dest^ := C;

  Inc(UInt(Source));
  Inc(UInt(Dest));
 end;
end;

function W_LoadWADFile(Name: PLChar): Int;
var
 I, J: Int;
 E: PWADListEntry;
 L: PWADFileLump;
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
      Print(['Warning: W_LoadWADFile: couldn''t load "', Name, '".']);
     Result := -1;
    end
   else
    begin
     E.Loaded := True;

     StrLCopy(@E.Name, Name, SizeOf(E.Name) - 1);
     if PUInt32(@E.Data.FileTag)^ <> WAD3_TAG then
      Sys_Error('W_LoadWADFile: WAD file doesn''t have WAD3 ID.');

     E.NumEntries := LittleLong(E.Data.NumEntries);
     E.Entries := Pointer(UInt(E.Data) + UInt(LittleLong(E.Data.FileOffset)));

     for J := 0 to E.NumEntries - 1 do
      begin
       L := @E.Entries[J];
       L.FilePos := LittleLong(L.FilePos);
       L.Size := LittleLong(L.Size);
       W_CleanupName(@L.Name, @L.Name);
       if L.LumpType = TYP_QPIC then
        SwapPic(PQPic(UInt(E.Data) + L.FilePos)^);
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
W_CleanupName(Name, @Buf);
if Index > High(WADList) then
 Sys_Error('W_GetLumpInfo: Invalid index.');

E := @WADList[Index];
for I := 0 to E.NumEntries - 1 do
 if StrComp(@Buf, @E.Entries[I].Name) = 0 then
  begin
   Result := @E.Entries[I];
   Exit;
  end;

if Error then
 Sys_Error(['W_GetLumpInfo: "', Name, '" not found.']);
Result := nil;
end;

function W_GetLumpName(WADIndex: UInt; Name: PLChar): Pointer;
var
 P: PWADFileLump;
begin
if WADIndex > High(WADList) then
 Sys_Error('W_GetLumpName: Invalid WAD index.');

P := W_GetLumpInfo(WADIndex, Name, True);
Result := Pointer(UInt(WADList[WADIndex].Data) + P.FilePos);
end;

function W_GetLumpNum(WADIndex, Index: UInt): Pointer;
begin
if WADIndex > High(WADList) then
 Sys_Error('W_GetLumpNum: Invalid WAD index.')
else
 if (Index >= WADList[WADIndex].NumEntries) then
  Sys_Error('W_GetLumpNum: Invalid index.');

Result := Pointer(UInt(WADList[WADIndex].Data) + WADList[WADIndex].Entries[Index].FilePos);
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

procedure SwapPic(var P: TQPic);
begin
P.Width := LittleLong(P.Width);
P.Height := LittleLong(P.Height);
end;



procedure SafeRead(F: TFile; Buf: Pointer; BufSize: UInt);
begin
if FS_Read(F, Buf, BufSize) <> BufSize then
 Sys_Error('SafeRead: File read failure.');
end;

procedure CleanupName(Src, Dst: PLChar);
var
 I: UInt;
begin
for I := 0 to MAX_LUMP_NAME - 1 do
 if Src^ = #0 then
  begin
   MemSet(Dst^, MAX_LUMP_NAME - I, 0);
   Exit;
  end
 else
  begin
   Dst^ := UpperC(Src^);

   Inc(UInt(Src));
   Inc(UInt(Dst));
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

 COM_FixSlashes(P);
 P := COM_FileBase(P, @Buf2);
 COM_DefaultExtension(P, '.wad');
 if (StrPos(P, 'pldecal') = nil) and (StrPos(P, 'tempdecal') = nil) then
  begin
   if not FS_Open(F, P, 'r') then
    Sys_Error(['TEX_InitFromWAD: Couldn''t open "', P, '".'])
   else
    begin
     TexFiles[NumTexFiles] := F;
     ID := NumTexFiles;
     Inc(NumTexFiles);
     DPrint(['Using WAD file: "', P, '".']);
     SafeRead(F, @Header, SizeOf(Header));
     if (PUInt32(@Header.FileTag)^ <> WAD2_TAG) and (PUInt32(@Header.FileTag)^ <> WAD3_TAG) then
      begin
       FS_Close(F);
       Sys_Error(['TEX_InitFromWAD: "', P, '" doesn''t have WAD2/3 tag.']);
      end;

     Header.NumEntries := LittleLong(Header.NumEntries);
     Header.FileOffset := LittleLong(Header.FileOffset);
     FS_Seek(F, Header.FileOffset, SEEK_SET);
     TexLumps := Mem_ReAlloc(TexLumps, SizeOf(TTextureLump) * (NumTexLumps + Header.NumEntries));

     for I := NumTexLumps to NumTexLumps + Header.NumEntries - 1 do
      begin
       L := @TexLumps[NumTexLumps];
       SafeRead(F, L, SizeOf(TTextureLump) - SizeOf(UInt32)); // 32, actually.
       CleanupName(@L.Name, @L.Name);
       L.FilePos := LittleLong(L.FilePos);
       L.DiskSize := LittleLong(L.DiskSize);
       L.FileID := ID;
       Inc(NumTexLumps);
      end;
    end;
  end;
 
 P := PLChar(UInt(P2) + SizeOf(P2^));
until P2 = nil;

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

function TEX_LoadLump(Name: PLChar; Buffer: Pointer): Int;
var
 I: Int;
 Buf: array[1..MAX_LUMP_NAME] of LChar;
 P: PTextureLump;
begin
CleanupName(Name, @Buf);
for I := 0 to NumTexLumps - 1 do
 begin
  P := @TexLumps[I];
  if StrComp(@Buf, @P.Name) = 0 then
   begin
    FS_Seek(TexFiles[P.FileID], P.FilePos, SEEK_SET);
    SafeRead(TexFiles[P.FileID], Buffer, P.DiskSize);
    Result := P.DiskSize; 
    Exit;
   end;
 end;

Con_SafePrintF(['TEX_LoadLump: Warning: Texture lump "', Name, '" is not found.']);
Result := 0;
end;

function FindMiptex(Name: PLChar): Int;
var
 I: Int;
begin
for I := 0 to NumMiptex - 1 do
 if StrComp(Name, @Miptex[I].Name) = 0 then
  begin
   Result := I;
   Exit;
  end;

Result := NumMiptex;
if NumMiptex = MAX_MAP_TEXTURES then
 Sys_Error('FindMiptex: Exceeded MAX_MAP_TEXTURES.');

StrLCopy(@Miptex[NumMiptex].Name, Name, MAX_TEXTUREREF_NAME - 1);
Miptex[NumMiptex].Name[MAX_TEXTUREREF_NAME] := #0;
Inc(NumMiptex);
end;

procedure TEX_AddAnimatingTextures;
const
 T: array[0..19] of LChar = '0123456789ABCDEFGHIJ';
var
 I, K: Int;
 N, J: UInt;
 P: PTextureRef;
 Buf: array[1..MAX_TEXTUREREF_NAME] of LChar;
begin
N := NumMiptex;
for I := 0 to NumMiptex - 1 do
 begin
  P := @Miptex[I];
  if P.Name[Low(P.Name)] in ['+', '-'] then
   begin
    StrLCopy(@Buf, @P.Name, SizeOf(Buf) - 1);
    Buf[High(Buf)] := #0;
    for J := Low(T) to High(T) do
     begin
      Buf[Low(Buf) + 1] := T[J];
      for K := 0 to NumTexLumps - 1 do
       if StrComp(@Buf, @TexLumps[K].Name) = 0 then
        begin
         FindMiptex(@Buf);
         Break;
        end;
     end;
   end;
 end;

if NumMiptex < N then
 DPrint(['Added ', NumMiptex - N, ' texture frames.']);
end;

end.
