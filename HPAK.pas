unit HPAK;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

function HPAK_GetDataPointer(Name: PLChar; const Res: TResource; Buffer: PPointer; Size: PUInt32): Boolean;
function HPAK_FindResource(DH: PHPAKDirectoryHeader; Hash: Pointer; Res: PResource): Boolean;

procedure HPAK_AddLump(Cache: Boolean; Name: PLChar; Res: PResource; Data: Pointer; F: PFile);
procedure HPAK_CreatePak(Name: PLChar; Res: PResource; Data: Pointer; F: PFile);

procedure HPAK_FlushHostQueue;

procedure HPAK_CheckSize(Name: PLChar);
function HPAK_ResourceForHash(Name: PLChar; Hash: PMD5Hash; Res: PResource): Boolean;

procedure HPAK_Init;
procedure HPAK_CheckIntegrity(Name: PLChar);

var
 // max size of HPAK, in MB.
 hpk_maxsize: TCVar = (Name: 'hpk_maxsize'; Data: '4'; Flags: [FCVAR_ARCHIVE]);

implementation

uses Common, Console, Encode, FileSys, Memory, SysMain;

var
 HPAKQueue: PHPAK = nil;

function HPAK_GetRTDesc(E: PHPAKDirectory): PLChar;
begin
case E.Resource.ResourceType of
 RT_DECAL: Result := 'decal';
 RT_SKIN: Result := 'skin';
 RT_SOUND: Result := 'sound';
 RT_MODEL: Result := 'model';
 RT_GENERIC: Result := 'generic';
 RT_EVENTSCRIPT: Result := 'event';
 RT_WORLD: Result := 'world';
 else Result := '?';
end;
end;

function HPAK_ParseHeaders(Name: PLChar; out F: TFile; out Header: THPAKHeader; out DH: THPAKDirectoryHeader; MinEntries: Int = 1): Boolean;
var
 Size: UInt;
begin
if not FS_Open(F, Name, 'r') then
 Print(['Error: Couldn''t open "', Name, '".'])
else
 begin
  if (FS_Read(F, @Header, SizeOf(Header)) < SizeOf(Header)) or
     (PUInt32(@Header.FileTag)^ <> HPAK_TAG) then
   Print(['Error: "', Name, '" is not a HPAK file.'])
  else
   if Header.Version <> HPAK_VERSION then
    Print('Error: HPAK version mismatch.')
   else
    if (Header.FileOffset < SizeOf(Header)) or (Header.FileOffset >= FS_Size(F)) then
     Print('Error: Invalid HPAK file offset.')
    else
     begin
      FS_Seek(F, Header.FileOffset, SEEK_SET);
      if FS_Read(F, @DH.NumEntries, SizeOf(DH.NumEntries)) < SizeOf(DH.NumEntries) then
       Print('Error while reading HPAK directory list.')
      else
       if (DH.NumEntries < MinEntries) or (DH.NumEntries > HPAK_MAX_ENTRIES) then
        Print('Error: HPAK has invalid number of directory entries.')
       else
        begin
         Size := DH.NumEntries * SizeOf(THPAKDirectory);
         DH.Entries := Mem_Alloc(Size);
         if DH.Entries = nil then
          Print('Error: HPAK_ParseHeaders: Out of memory.')
         else
          begin
           if FS_Read(F, DH.Entries, Size) < Size then
            Print('Error: HPAK_ParseHeaders: File read error.')
           else
            begin
             Result := True;
             Exit;
            end;

           Mem_Free(DH.Entries);
          end;
        end;
     end;

  FS_Close(F);
 end;

Result := False;
end;

function HPAK_GetDataPointer(Name: PLChar; const Res: TResource; Buffer: PPointer; Size: PUInt32): Boolean;
var
 P: PHPAK;
 P2: Pointer;
 Buf: array[1..MAX_PATH_W] of LChar;
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 I: Int;
 E: PHPAKDirectory;
begin
P := HPAKQueue;
while P <> nil do
 if (StrIComp(P.Name, Name) = 0) and CompareMem(@P.Resource.MD5Hash, @Res.MD5Hash, SizeOf(Res.MD5Hash)) then
  begin
   Result := True;
   if (Buffer <> nil) and (P.Size > 0) then
    begin
     P2 := Mem_AllocN(P.Size);
     Buffer^ := P2;
     if P2 = nil then
      begin
       Print(['HPAK_GetDataPointer: Error allocating ', P.Size, ' bytes for HPAK entry.']);
       Result := False;
      end
     else
      Move(P.Buffer^, P2^, P.Size);
    end;

   if Size <> nil then
    Size^ := P.Size;

   Exit;
  end
 else
  P := P.Prev;

if Buffer <> nil then
 Buffer^ := nil;
if Size <> nil then
 Size^ := 0;

Result := False;
if not COM_HasExtension(Name) then
 begin
  Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  COM_DefaultExtension(Name, '.hpk');
 end;

if HPAK_ParseHeaders(Name, F, Header, DH) then
 begin
  for I := 0 to DH.NumEntries - 1 do
   begin
    E := @DH.Entries[I];
    if CompareMem(@E.Resource.MD5Hash, @Res.MD5Hash, SizeOf(Res.MD5Hash)) then
     begin
      Result := True;
      if (Buffer <> nil) and (E.Size > 0) then
       begin
        FS_Seek(F, E.FileOffset, SEEK_SET);

        P2 := Mem_AllocN(E.Size);
        Buffer^ := P2;
        if P2 = nil then
         begin
          Print(['HPAK_GetDataPointer: Error allocating ', E.Size, ' bytes for HPAK entry.']);
          Result := False;
         end
        else
         FS_Read(F, P2, E.Size);
       end;

      if Size <> nil then
       Size^ := E.Size;

      Break;
     end;
   end;

  Mem_Free(DH.Entries);
  FS_Close(F);
 end;
end;

function HPAK_FindResource(DH: PHPAKDirectoryHeader; Hash: Pointer; Res: PResource): Boolean;
var
 I: Int;
begin
for I := 0 to DH.NumEntries - 1 do
 if CompareMem(Hash, @DH.Entries[I].Resource.MD5Hash, SizeOf(TMD5Hash)) then
  begin
   if Res <> nil then
    Move(DH.Entries[I].Resource, Res^, SizeOf(Res^));
   Result := True;
   Exit;
  end;

Result := False;
end;

procedure HPAK_AddToQueue(Name: PLChar; Res: PResource; DataPtr: Pointer; FilePtr: PFile);
var
 P: PHPAK;
begin
P := Mem_ZeroAlloc(SizeOf(P^));
if P = nil then
 Sys_Error(['HPAK_AddToQueue: Unable to allocate ', SizeOf(P^), ' bytes for HPAK entry.']);

P.Name := Mem_StrDup(Name);
if P.Name = nil then
 Sys_Error('HPAK_AddToQueue: Mem_StrDup failed - Not enough memory.');

Move(Res^, P.Resource, SizeOf(P.Resource));
P.Size := Res.DownloadSize;
P.Buffer := Mem_Alloc(P.Size);
if P.Buffer = nil then
 Sys_Error(['HPAK_AddToQueue: Unable to allocate ', P.Size, ' bytes for HPAK entry data.']);

if DataPtr <> nil then
 begin
  Move(DataPtr^, P.Buffer^, P.Size);
  P.Prev := HPAKQueue;
  HPAKQueue := P;
 end
else
 if FilePtr = nil then
  Sys_Error('HPAK_AddToQueue: Called without data or file pointer.')
 else
  begin
   FS_Read(FilePtr^, P.Buffer, P.Size);
   P.Prev := HPAKQueue;
   HPAKQueue := P;
  end;
end;

procedure HPAK_FlushHostQueue;
var
 P: PHPAK;
begin
while HPAKQueue <> nil do
 begin
  P := HPAKQueue;
  HPAKQueue := HPAKQueue.Prev;
  HPAK_AddLump(False, P.Name, @P.Resource, P.Buffer, nil);
  Mem_Free(P.Name);
  Mem_Free(P.Buffer);
  Mem_Free(P);
 end;
end;

procedure HPAK_AddLump(Cache: Boolean; Name: PLChar; Res: PResource; Data: Pointer; F: PFile);
var
 Buf, Buf2: array[1..MAX_PATH_W] of LChar;
 MD5C: TMD5Context;
 FPos: Int64;
 P: Pointer;
 MD5H: TMD5Hash;
 MD5B: TMD5HashStr;
 S, S2: PLChar;
 HF, HF2: TFile;
 Header: THPAKHeader;
 DH, DH2: THPAKDirectoryHeader;
 I, I2: UInt;
 LE: PHPAKDirectory;
 R: Boolean;
begin
R := False;
S := nil;
S2 := nil;

if Name = nil then
 Print('HPAK_AddLump called with invalid arguments: No HPAK filename.')
else
 if Res = nil then
  Print('HPAK_AddLump called with invalid arguments: No lump to add.')
 else
  if (Data = nil) and (F = nil) then
   Print('HPAK_AddLump called with invalid arguments: No input stream.')
  else
   if (Res.DownloadSize < 1024) or (Res.DownloadSize > $20000) then
    Print(['HPAK_AddLump called with invalid lump, size = ', Res.DownloadSize, '.'])
   else
    begin
     MemSet(MD5C, SizeOf(MD5C), 0);
     MD5Init(MD5C);
     if Data <> nil then
      MD5Update(MD5C, Data, Res.DownloadSize)
     else
      begin
       FPos := FS_Tell(F^);
       P := Mem_Alloc(Res.DownloadSize + 1);
       if P = nil then
        Sys_Error('HPAK_AddLump: Out of memory.');
       if FS_Read(F^, P, Res.DownloadSize) = Res.DownloadSize then
        begin
         FS_Seek(F^, FPos, SEEK_SET);
         MD5Update(MD5C, P, Res.DownloadSize);
        end
       else
        Sys_Error('HPAK_AddLump: File read error.');
       Mem_Free(P);
      end;
     MD5Final(MD5H, MD5C);
     if not CompareMem(@Res.MD5Hash, @MD5H, SizeOf(MD5H)) then
      begin
       Print('HPAK_AddLump called with invalid lump (MD5 mismatch).');
       MD5_Print(Res.MD5Hash, MD5B);
       Print(['Purported: ', PLChar(@MD5B)]);
       MD5_Print(MD5H, MD5B);
       Print(['Actual: ', PLChar(@MD5B)]);
       Print('Ignoring lump addition.');
      end
     else
      if Cache then
       HPAK_AddToQueue(Name, Res, Data, F)
      else
       begin
        S := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
        COM_DefaultExtension(S, '.hpk');
        COM_FixSlashes(S);

        if not FS_Open(HF, S, 'r') then
         HPAK_CreatePak(Name, Res, Data, F)
        else
         begin
          S2 := StrLCopy(@Buf2, S, SizeOf(Buf2) - 1);
          COM_StripExtension(S2, S2);
          COM_DefaultExtension(S2, '.hp2');
          if not FS_Open(HF2, S2, 'wo') then
           Print(['HPAK_AddLump: Error: Couldn''t open "', S2, '".'])
          else
           begin
            FS_Read(HF, @Header, SizeOf(Header));
            if Header.Version <> HPAK_VERSION then
             Print('HPAK_AddLump: Invalid HPAK version.')
            else
             begin
              FS_Seek(HF, 0, SEEK_SET);
              COM_CopyFileChunk(HF2, HF, FS_Size(HF));
              FS_Seek(HF, Header.FileOffset, SEEK_SET);
              FS_Read(HF, @DH.NumEntries, SizeOf(DH.NumEntries));
              if (DH.NumEntries < 0) or (DH.NumEntries > HPAK_MAX_ENTRIES) then
               Print(['HPAK_AddLump: Invalid number of entries - ', DH.NumEntries, '.'])
              else
               begin
                DH.Entries := Mem_ZeroAlloc(SizeOf(THPAKDirectory) * (DH.NumEntries + 1));
                if DH.Entries = nil then
                 Print('HPAK_AddLump: Out of memory.')
                else
                 begin
                  if DH.NumEntries > 0 then
                   FS_Read(HF, DH.Entries, SizeOf(THPAKDirectory) * DH.NumEntries);
                  if not HPAK_FindResource(@DH, @Res.MD5Hash, nil) then
                   begin
                    DH2.NumEntries := DH.NumEntries + 1;
                    DH2.Entries := Mem_ZeroAlloc(SizeOf(THPAKDirectory) * DH2.NumEntries);
                    if DH2.Entries = nil then
                     Print('HPAK_AddLump: Out of memory.')
                    else
                     begin
                      Move(DH.Entries^, DH2.Entries^, SizeOf(THPAKDirectory) * DH.NumEntries);

                      LE := nil;
                      for I := 0 to DH.NumEntries - 1 do
                       if CompareMem(@Res.MD5Hash, @DH.Entries[I].Resource.MD5Hash, SizeOf(Res.MD5Hash)) then
                        begin
                         for I2 := I to DH.NumEntries - 1 do
                          Move(DH.Entries[I2], DH2.Entries[I2 + 1], SizeOf(DH2.Entries[0]));

                         LE := @DH2.Entries[I];
                         Break;
                        end;

                      if LE = nil then
                       LE := @DH2.Entries[DH2.NumEntries - 1];

                      MemSet(LE^, SizeOf(LE^), 0);
                      FS_Seek(HF2, Header.FileOffset, SEEK_SET);
                      Move(LE.Resource, Res^, SizeOf(Res^));
                      LE.FileOffset := UInt32(FS_Tell(HF2));
                      LE.Size := Res.DownloadSize;
                      if Data <> nil then
                       FS_Write(HF2, Data, Res.DownloadSize)
                      else
                       COM_CopyFileChunk(HF2, F^, Res.DownloadSize);

                      Header.FileOffset := UInt32(FS_Tell(HF2));
                      FS_Write(HF2, @DH2.NumEntries, SizeOf(DH2.NumEntries));

                      for I := 0 to DH2.NumEntries - 1 do
                       FS_Write(HF2, @DH2.Entries[I], SizeOf(DH2.Entries[0]));

                      FS_Seek(HF2, 0, SEEK_SET);
                      FS_Write(HF2, @Header, SizeOf(Header));

                      R := True;
                      Mem_Free(DH2.Entries);
                     end;
                   end;

                  Mem_Free(DH.Entries);
                 end;
               end;
             end;

            FS_Close(HF2);
            FS_Unlink(S2);
           end;

          FS_Close(HF);
         end;
       end;
    end;

if R then
 begin
  FS_Unlink(S);
  FS_Rename(S2, S);
  Mem_Free(S2);
  Mem_Free(S);
 end;
end;

procedure HPAK_RemoveLump(Name: PLChar; Res: PResource);
var
 Buf, Buf2: array[1..MAX_PATH_W] of LChar;
 S, S2, SN: PLChar;
 F1, F2: TFile;
 Header: THPAKHeader;
 DH, DH2: THPAKDirectoryHeader;
 B1, B2: Boolean;
 I, J: Int;
begin
B1 := False;
B2 := False;

if (Name = nil) or (Name^ = #0) then
 Print('HPAK_RemoveLump: Invalid arguments.')
else
 begin
  HPAK_FlushHostQueue;
  
  SN := Cmd_Argv(1);
  S := StrLCopy(@Buf, SN, SizeOf(Buf) - 1);
  COM_DefaultExtension(S, '.hpk');

  if not FS_Open(F1, S, 'r') then
   Print(['HPAK_RemoveLump: Couldn''t open HPAK file "', S, '".'])
  else
   begin
    S2 := StrLCopy(@Buf2, SN, SizeOf(Buf2) - 1);
    COM_StripExtension(S2, S2);
    COM_DefaultExtension(S2, '.hp2');
    if not FS_Open(F2, S2, 'wo') then
     Print(['HPAK_RemoveLump: Couldn''t create "', S2, '".'])
    else
     begin
      FS_Read(F1, @Header, SizeOf(Header));
      if PUInt32(@Header.FileTag)^ <> HPAK_TAG then
       Print(['HPAK_RemoveLump: "', S, '" is not a HPAK file.'])
      else
       if Header.Version <> HPAK_VERSION then
        Print('HPAK_RemoveLump: HPAK version is outdated.')
       else
        begin
         FS_Seek(F1, Header.FileOffset, SEEK_SET);
         FS_Read(F1, @DH.NumEntries, SizeOf(DH.NumEntries));
         if (DH.NumEntries < 1) or (DH.NumEntries > HPAK_MAX_ENTRIES) then
          Print(['HPAK_RemoveLump: HPAK has invalid number of directory entries - ', DH.NumEntries, '.'])
         else
          if DH.NumEntries = 1 then
           begin
            Print(['HPAK_RemoveLump: Removing final lump from HPAK, deleting HPAK: "', S, '".']);
            B1 := True;
           end
          else
           begin
            FS_Write(F2, @Header, SizeOf(Header));
            DH.Entries := Mem_Alloc(SizeOf(THPAKDirectory) * DH.NumEntries);
            if DH.Entries = nil then
             Print('HPAK_RemoveLump: Out of memory.')
            else
             begin
              FS_Read(F1, DH.Entries, SizeOf(THPAKDirectory) * DH.NumEntries);
              DH2.NumEntries := DH.NumEntries - 1;
              DH2.Entries := Mem_Alloc(SizeOf(THPAKDirectory) * DH2.NumEntries);
              if DH2.Entries = nil then
               Print('HPAK_RemoveLump: Out of memory.')
              else
               begin
                if not HPAK_FindResource(@DH, @Res.MD5Hash, nil) then
                 Print(['HPAK_RemoveLump: HPAK doesn''t contain specified lump - ', PLChar(@Res.Name), '.'])
                else
                 begin
                  Print(['Removing "', PLChar(@Res.Name), '" from HPAK "', S, '".']);

                  J := 0;
                  for I := 0 to DH.NumEntries - 1 do
                   if not CompareMem(@DH.Entries[I].Resource.MD5Hash, @Res.MD5Hash, SizeOf(Res.MD5Hash)) then
                    begin
                     Move(DH.Entries[I], DH2.Entries[J], SizeOf(DH.Entries[0]));
                     DH2.Entries[J].FileOffset := FS_Tell(F2);
                     FS_Seek(F1, DH.Entries[I].FileOffset, SEEK_SET);
                     COM_CopyFileChunk(F2, F1, DH2.Entries[J].Size);
                     Inc(J);
                    end;

                  Header.FileOffset := FS_Tell(F2);
                  FS_Write(F2, @DH2.NumEntries, SizeOf(DH2.NumEntries));
                  for I := 0 to DH2.NumEntries - 1 do
                   FS_Write(F2, @DH2.Entries[I], SizeOf(DH2.Entries[0]));

                  FS_Seek(F2, 0, SEEK_SET);
                  FS_Write(F2, @Header, SizeOf(Header));
                  B2 := True;
                 end;
                 
                Mem_Free(DH2.Entries);
               end;

              Mem_Free(DH.Entries);
             end;
           end;
        end;

      FS_Close(F2);
      if not B2 then
       FS_Unlink(S2);
     end;

    FS_Close(F1);
    if B1 or B2 then
     FS_Unlink(S);
    if B2 then
     FS_Rename(S2, S);
   end;
 end;
end;

function HPAK_ResourceForIndex(Name: PLChar; Index: Int; Res: PResource): Boolean;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
begin
Result := False;

if CmdSource = csServer then
 begin
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;

  if HPAK_ParseHeaders(Name, F, Header, DH) then
   begin
    Move(DH.Entries[Index - 1].Resource, Res^, SizeOf(Res^));
    Mem_Free(DH.Entries);
    FS_Close(F);
    Result := True;
   end;
 end;
end;

function HPAK_ResourceForHash(Name: PLChar; Hash: PMD5Hash; Res: PResource): Boolean;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 P: PHPAK;
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
begin
P := HPAKQueue;
while P <> nil do
 if (StrIComp(P.Name, Name) = 0) and CompareMem(@P.Resource.MD5Hash, Hash, SizeOf(TMD5Hash)) then
  begin
   if Res <> nil then
    Move(P.Resource, Res^, SizeOf(Res^));
   Result := True;
   Exit;
  end
 else
  P := P.Prev;

Result := False;

if not COM_HasExtension(Name) then
 begin
  Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  COM_DefaultExtension(Name, '.hpk');
 end;

if HPAK_ParseHeaders(Name, F, Header, DH) then
 begin
  Result := HPAK_FindResource(@DH, Hash, Res);
  Mem_Free(DH.Entries);
  FS_Close(F);
 end;
end;

procedure HPAK_List_f; cdecl;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 Name: PLChar;
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 I: Int;
 E: PHPAKDirectory;
 Size: Double;
 MD5B: TMD5HashStr;
begin
if CmdSource <> csServer then
 Exit;

if Cmd_Argc <> 2 then
 Print('Usage: hpklist <hpkname>')
else
 begin
  HPAK_FlushHostQueue;
  Name := Cmd_Argv(1);
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;

  Print(['Contents for "', Name, '".']);
  if HPAK_ParseHeaders(Name, F, Header, DH) then
   begin
    Print(['# of Entries: ', DH.NumEntries]);
    Print('# Type Size FileName : MD5 Hash');
    for I := 0 to DH.NumEntries - 1 do
     begin
      E := @DH.Entries[I];
      Size := RoundTo(E.Resource.DownloadSize / 1024, -2);
      MD5_Print(E.Resource.MD5Hash, MD5B);
      Print([I, ': ', HPAK_GetRTDesc(E), ' ', Size, 'K ', COM_FileBase(@E.Resource.Name, @Buf), ' : ', PLChar(@MD5B)]);
     end;

    Mem_Free(DH.Entries);
    FS_Close(F);
   end;
 end;
end;

procedure HPAK_CreatePak(Name: PLChar; Res: PResource; Data: Pointer; F: PFile);
var
 Buf: array[1..MAX_PATH_W] of LChar;
 FW: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 MD5C: TMD5Context;
 Hash: TMD5Hash;
 MD5S: TMD5HashStr;
 FP: Int64;
 P: Pointer;
 E: PHPAKDirectory;
 I: Int;
begin
if not ((Data <> nil) xor (F <> nil)) then
 Print('HPAK_CreatePak: Must specify either Data or File pointer.')
else
 begin
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;

  Print(['Creating HPAK "', Name, '".']);
  if not FS_Open(FW, Name, 'wo') then
   Print('HPAK_CreatePak: Couldn''t open HPAK file for writing.')
  else
   begin
    MemSet(MD5C, SizeOf(MD5C), 0);
    MD5Init(MD5C);
    if Data <> nil then
     MD5Update(MD5C, Data, Res.DownloadSize)
    else
     begin
      FP := FS_Tell(F^);
      P := Mem_Alloc(Res.DownloadSize + 1);
      FS_Read(F^, P, Res.DownloadSize);
      FS_Seek(F^, FP, SEEK_SET);
      MD5Update(MD5C, P, Res.DownloadSize);
      Mem_Free(P);
     end;

    MD5Final(Hash, MD5C);
    if not CompareMem(@Res.MD5Hash, @Hash, SizeOf(Hash)) then
     begin
      Print('HPAK_CreatePak called with invalid lump (MD5 mismatch).');
      MD5_Print(Res.MD5Hash, MD5S);
      Print(['Purported: ', PLChar(@MD5S)]);
      MD5_Print(Hash, MD5S);
      Print(['Actual: ', PLChar(@MD5S)]);
      Print('Ignoring lump addition.');
     end
    else
     begin
      PUInt32(@Header.FileTag)^ := HPAK_TAG;
      Header.Version := HPAK_VERSION;
      Header.FileOffset := 0;
      FS_Write(FW, @Header, SizeOf(Header));
      DH.NumEntries := 1;
      DH.Entries := Mem_ZeroAlloc(SizeOf(THPAKDirectory));
      if DH.Entries = nil then
       Print('HPAK_CreatePak: Out of memory.')
      else
       begin
        E := @DH.Entries[Low(DH.Entries^)];
        Move(Res^, E.Resource, SizeOf(E.Resource));
        E.FileOffset := UInt32(FS_Tell(FW));
        E.Size := Res.DownloadSize;

        if Data <> nil then
         FS_Write(FW, Data, Res.DownloadSize)
        else
         COM_CopyFileChunk(FW, F^, Res.DownloadSize);

        FP := FS_Tell(FW);
        FS_Write(FW, @DH.NumEntries, SizeOf(DH.NumEntries));
        for I := 0 to DH.NumEntries - 1 do
         FS_Write(FW, @DH.Entries[I], SizeOf(DH.Entries[0]));

        Header.FileOffset := FP;
        FS_Seek(FW, 0, SEEK_SET);
        FS_Write(FW, @Header, SizeOf(Header));

        FreeMem(DH.Entries);
       end;
     end;

    FS_Close(FW);
   end;
 end;
end;

procedure HPAK_Remove_f; cdecl;
var
 Res: TResource;
 Index: Int;
 Name: PLChar;
begin
if CmdSource <> csServer then
 Exit;

HPAK_FlushHostQueue;
if Cmd_Argc <> 3 then
 Print('Usage: hpkremove <hpk> <index>')
else
 begin
  Name := Cmd_Argv(1);
  Index := StrToIntDef(Cmd_Argv(2), -1);
  if Index <= 0 then
   Print('hpkremove: Bad lump index.')
  else
   if HPAK_ResourceForIndex(Name, Index, @Res) then
    begin
     Print(['Removing lump #', Index, ' from ', Name, '.']);
     HPAK_RemoveLump(Name, @Res);
    end
   else
    Print(['Couldn''t locate resource #', Index, ' in ', Name, '.'])
 end;
end;

procedure HPAK_Validate_f; cdecl;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 Name: PLChar;
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 I: Int;
 E: PHPAKDirectory;
 P: Pointer;
 MD5C: TMD5Context;
 Hash: TMD5Hash;
 MD5S: TMD5HashStr;
 Size: Double;
begin
if CmdSource <> csServer then
 Exit;

HPAK_FlushHostQueue;
if Cmd_Argc <> 2 then
 Print('Usage: hpkval <hpkname>')
else
 begin
  Name := Cmd_Argv(1);
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;

  Print(['Validating "', Name, '".']);
  if HPAK_ParseHeaders(Name, F, Header, DH) then
   begin
    Print(['# of Entries: ', DH.NumEntries, LineBreak + '# Type Size FileName' + LineBreak]);
    for I := 0 to DH.NumEntries - 1 do
     begin
      E := @DH.Entries[I];

      Size := RoundTo(E.Resource.DownloadSize / 1024, -2);
      Print([I, ': ', HPAK_GetRTDesc(E), ' ', Size, 'K ', COM_FileBase(@E.Resource.Name, @Buf)]);

      if (E.Size = 0) or (E.Size >= $20000) then
       Print(['Unable to get MD5 hash of the data, size is invalid: ', E.Size, '.'])
      else
       begin
        P := Mem_Alloc(E.Size + 1);
        FS_Seek(F, E.FileOffset, SEEK_SET);
        FS_Read(F, P, E.Size);
        MemSet(MD5C, SizeOf(MD5C), 0);
        MD5Init(MD5C);
        MD5Update(MD5C, P, E.Size);
        MD5Final(Hash, MD5C);
        if not CompareMem(@Hash, @E.Resource.MD5Hash, SizeOf(Hash)) then
         begin
          Print('MD5: Mismatched');
          Print('---------------');
          MD5_Print(E.Resource.MD5Hash, MD5S);
          Print(['File: ', PLChar(@MD5S)]);
          MD5_Print(Hash, MD5S);
          Print(['Actual: ', PLChar(@MD5S)]);
          Print('---------------');
         end
        else
         Print('MD5: OK');
        Mem_Free(P);
       end;
     end;

    FS_Close(F);
    Mem_Free(DH.Entries);
   end;
 end;
end;

procedure HPAK_Extract_f; cdecl;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 Buf2: array[1..128] of LChar;
 IntBuf, ExpandBuf: array[1..32] of LChar;
 S, Name: PLChar;
 Index, I: Int;
 F, F2: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 E: PHPAKDirectory;
 P: Pointer;
 Size: Double;
begin
if CmdSource <> csServer then
 Exit;

HPAK_FlushHostQueue;
if Cmd_Argc <> 3 then
 Print('Usage: hpkextract <hpkname> [all | single index]')
else
 begin
  Name := Cmd_Argv(1);
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;
  
  if StrComp(Cmd_Argv(2), 'all') = 0 then
   begin
    Index := -1;
    Print(['Extracting all lumps from "', Name, '".']);
   end
  else
   begin
    Index := StrToIntDef(Cmd_Argv(2), -1);
    if Index < 0 then
     begin
      Print('hpkextract: Bad lump index.');
      Exit;
     end;

    Print(['Extracting lump #', Index, ' from "', Name, '".']);
   end;

  if HPAK_ParseHeaders(Name, F, Header, DH) then
   begin
    Print(['# of Entries: ', DH.NumEntries, LineBreak + '# Type Size FileName' + LineBreak]);
    for I := 0 to DH.NumEntries - 1 do
     if (Index = -1) or (I = Index) then
      begin
       E := @DH.Entries[I];

       Size := RoundTo(E.Resource.DownloadSize / 1024, -2);
       Print(['Extracting ', I, ': ', HPAK_GetRTDesc(E), ' ', Size, 'K ', COM_FileBase(@E.Resource.Name, @Buf)]);

       if (E.Size = 0) or (E.Size >= $20000) then
        Print(['Unable to extract data, size is invalid: ', E.Size, '.'])
       else
        begin
         P := Mem_Alloc(E.Size + 1);
         FS_Seek(F, E.FileOffset, SEEK_SET);
         FS_Read(F, P, E.Size);

         S := StrECopy(@Buf2, 'hpklmps' + CorrectSlash + 'lmp');
         S := StrECopy(S, ExpandString(IntToStr(I, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 4));
         StrCopy(S, '.wad');

         COM_FixSlashes(@Buf2);
         COM_CreatePath(@Buf2);
         if FS_Open(F2, @Buf2, 'wo') then
          begin
           FS_Write(F2, P, E.Size);
           FS_Close(F2);
          end
         else
          Print(['Error creating lump file "', PLChar(@Buf2), '".']);

         Mem_Free(P);
        end;
      end;

    FS_Close(F);
    Mem_Free(DH.Entries);
   end;
 end;
end;

procedure HPAK_GetItem(Index: Int; Buffer: PLChar; L: UInt);
var
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 MD5S: TMD5HashStr;
begin
HPAK_FlushHostQueue;

if HPAK_ParseHeaders('custom.hpk', F, Header, DH) then
 begin
  if Index >= DH.NumEntries - 1 then
   Index := DH.NumEntries - 1;
  MD5_Print(DH.Entries[Index].Resource.MD5Hash, MD5S);

  if L > 0 then
   begin
    StrLCopy(Buffer, '!MD5', L - 1);
    if L > 5 then
     StrLCopy(PLChar(UInt(Buffer) + 4), @MD5S, L - 5);
   end;

  Mem_Free(DH.Entries);
  FS_Close(F);
 end;
end;

procedure HPAK_CheckSize(Name: PLChar);
var
 Buf: array[1..MAX_PATH_W] of LChar;
 Size: Single;
begin
Size := hpk_maxsize.Value;
if (Name = nil) or (Size = 0) then
 Exit;

if Size >= 0 then
 begin
  Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  COM_DefaultExtension(Name, '.hpk');
  COM_FixSlashes(Name);

  if FS_SizeByName(Name) >= Size * (1024 * 1024) then
   begin
    DPrint(['Server: Size of HPAK "', Name, '" is greater than ', Size, ' MB, deleting.']);
    LPrint(['Server: Size of HPAK "', Name, '" > ', Size, ' MB, deleting.'#10]);
    FS_RemoveFile(Name);
   end;
 end
else
 begin
  Print('hpk_maxsize < 0, setting to 0.');
  CVar_DirectSet(hpk_maxsize, '0');
 end;
end;

procedure HPAK_ValidatePak(Name: PLChar);
var
 Buf: array[1..MAX_PATH_W] of LChar;
 DataBuf: array[0..$20000] of Byte;
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 I: Int;
 B: Boolean;
 E: PHPAKDirectory;
 MD5C: TMD5Context;
 Hash: TMD5Hash;
begin
HPAK_FlushHostQueue;

Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
COM_DefaultExtension(Name, '.hpk');
COM_FixSlashes(Name);

if HPAK_ParseHeaders(Name, F, Header, DH) then
 begin
  B := False;
  
  for I := 0 to DH.NumEntries - 1 do
   begin
    E := @DH.Entries[I];
    if (E.Size = 0) or (E.Size >= SizeOf(DataBuf) - 1) then
     begin
      B := True;
      Print(['Invalid data lump size in HPAK "', Name, '" at #', I, '.']);
      Break;
     end;

    FS_Seek(F, E.FileOffset, SEEK_SET);
    FS_Read(F, @DataBuf, E.Size);
    DataBuf[E.Size] := 0;

    MD5Init(MD5C);
    MD5Update(MD5C, @DataBuf, E.Size);
    MD5Final(Hash, MD5C);
    
    if not CompareMem(@E.Resource.MD5Hash, @Hash, SizeOf(Hash)) then
     begin
      B := True;
      Print(['Invalid MD5 hash in HPAK "', Name, '" at #', I, '.']);
      Break;
     end;
   end;

  Mem_Free(DH.Entries);
  FS_Close(F);
  if not B then
   begin
    DPrint(['HPAK "', Name, '" validated, no errors.']);
    Exit;
   end;
 end;

if FS_FileExists(Name) then
 begin
  Print(['Deleting HPAK "', Name, '".']);
  FS_RemoveFile(Name);
 end;
end;

procedure HPAK_CheckIntegrity(Name: PLChar);
begin
HPAK_ValidatePak(Name);
end;

procedure HPAK_Init;
begin
Cmd_AddCommand('hpklist', @HPAK_List_f);
Cmd_AddCommand('hpkremove', @HPAK_Remove_f);
Cmd_AddCommand('hpkval', @HPAK_Validate_f);
Cmd_AddCommand('hpkextract', @HPAK_Extract_f);
HPAKQueue := nil;
end;

end.
