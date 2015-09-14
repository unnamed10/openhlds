unit HPAK;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

function HPAK_GetDataPointer(Name: PLChar; const Res: TResource; Buffer: PPointer; Size: PUInt32): Boolean;
function HPAK_FindResource(const DH: THPAKDirectoryHeader; Hash: Pointer; Res: PResource): Boolean;

procedure HPAK_AddLump(ToCache: Boolean; Name: PLChar; Res: PResource; DataPtr: Pointer; FilePtr: PFile);
procedure HPAK_CreatePak(Name: PLChar; Res: PResource; DataPtr: Pointer; FilePtr: PFile);

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
 HPAKQueue: PHPAKQueue;

function HPAK_GetResourceDesc(E: PHPAKDirectory): PLChar;
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

function HPAK_ParseHeaders(Name: PLChar; out F: TFile; out Header: THPAKHeader; out DH: THPAKDirectoryHeader; MinEntries: Int = 1; NeedOpen: Boolean = True): Boolean;
var
 Size: UInt;
begin
if NeedOpen and not FS_Open(F, Name, 'r') then
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
            Print('Error while reading HPAK directory data.')
           else
            begin
             Result := True;
             Exit;
            end;

           Mem_Free(DH.Entries);
          end;
        end;
     end;

  if NeedOpen then
   FS_Close(F);
 end;

Result := False;
end;

function HPAK_GetDataPointer(Name: PLChar; const Res: TResource; Buffer: PPointer; Size: PUInt32): Boolean;
var
 P: PHPAKQueue;
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
     P2 := Mem_Alloc(P.Size);
     Buffer^ := P2;
     if P2 = nil then
      begin
       Print(['HPAK_GetDataPointer: Unable to allocate ', P.Size, ' bytes for HPAK entry.']);
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

        P2 := Mem_Alloc(E.Size);
        Buffer^ := P2;
        if P2 = nil then
         begin
          Print(['HPAK_GetDataPointer: Unable to allocate ', E.Size, ' bytes for HPAK entry.']);
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

function HPAK_FindResource(const DH: THPAKDirectoryHeader; Hash: Pointer; Res: PResource): Boolean;
var
 I: Int;
begin
for I := 0 to DH.NumEntries - 1 do
 if CompareMem(Hash, @DH.Entries[I].Resource.MD5Hash, SizeOf(TMD5Hash)) then
  begin
   if Res <> nil then
    Move(DH.Entries[I].Resource, Res^, SizeOf(TResource));
   Result := True;
   Exit;
  end;

Result := False;
end;

procedure HPAK_AddToQueue(Name: PLChar; Res: PResource; DataPtr: Pointer; FilePtr: PFile);
var
 P: PHPAKQueue;
begin
P := Mem_Alloc(SizeOf(THPAKQueue));
if P = nil then
 Sys_Error(['HPAK_AddToQueue: Unable to allocate ', SizeOf(THPAKQueue), ' bytes for HPAK entry.'])
else
 begin
  P.Name := Mem_StrDup(Name);
  if P.Name = nil then
   Sys_Error(['HPAK_AddToQueue: Unable to allocate ', StrLen(Name), ' bytes for HPAK name.'])
  else
   begin
    Move(Res^, P.Resource, SizeOf(P.Resource));
    P.Size := Res.DownloadSize;
    P.Buffer := Mem_Alloc(P.Size);
    if P.Buffer = nil then
     Sys_Error(['HPAK_AddToQueue: Unable to allocate ', P.Size, ' bytes for HPAK data.'])
    else
     if not ((DataPtr = nil) xor (FilePtr = nil)) then
      Sys_Error('HPAK_AddToQueue: Must specify either Data or File pointer.')
     else
      begin
       if DataPtr <> nil then
        Move(DataPtr^, P.Buffer^, P.Size)
       else
        FS_Read(FilePtr^, P.Buffer, P.Size);

       P.Prev := HPAKQueue;
       HPAKQueue := P;
      end;
   end;
 end;
end;

procedure HPAK_FlushHostQueue;
var
 P: PHPAKQueue;
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

function HPAK_HashStream(DataPtr: Pointer; FilePtr: PFile; Size: UInt; out Hash: TMD5Hash): Boolean;
var
 MD5C: TMD5Context;
 FilePos: Int64;
 P: Pointer;
begin
Result := False;
MD5Init(MD5C);
if DataPtr <> nil then
 begin
  MD5Update(MD5C, DataPtr, Size);
  MD5Final(Hash, MD5C);
  Result := True;
 end
else
 begin
  FilePos := FS_Tell(FilePtr^);
  P := Mem_Alloc(Size + 1);
  if P = nil then
   Print(['HPAK_HashStream: Unable to allocate ', Size + 1, ' bytes for HPAK data.'])
  else
   if FS_Read(FilePtr^, P, Size) < Size then
    begin
     Print('HPAK_HashStream: File read error.');
     Mem_Free(P);
    end
   else
    begin
     FS_Seek(FilePtr^, FilePos, SEEK_SET);
     MD5Update(MD5C, P, Size);
     Mem_Free(P);
     MD5Final(Hash, MD5C);
     Result := True;
    end;
 end;
end;

procedure HPAK_AddLump(ToCache: Boolean; Name: PLChar; Res: PResource; DataPtr: Pointer; FilePtr: PFile);
var
 Buf, Buf2: array[1..MAX_PATH_W] of LChar;
 S: PLChar;
 Hash: TMD5Hash;
 MD5S: TMD5HashStr;
 SrcFile, DstFile: TFile;
 Header: THPAKHeader;
 DH, DH2: THPAKDirectoryHeader;
 NewDir: PHPAKDirectory;
 I: UInt;
begin
if Name = nil then
 Print('HPAK_AddLump: Bad file name.')
else
 if Res = nil then
  Print('HPAK_AddLump: Bad resource.')
 else
  if not ((DataPtr = nil) xor (FilePtr = nil)) then
   Print('HPAK_AddLump: Must specify either Data or File pointer.')
  else
   if (Res.DownloadSize < HPAK_MIN_LUMP_SIZE) or (Res.DownloadSize > HPAK_MAX_LUMP_SIZE) then
    Print(['HPAK_AddLump: Bad lump size (', Res.DownloadSize, ').'])
   else
    if HPAK_HashStream(DataPtr, FilePtr, Res.DownloadSize, Hash) then
     if not CompareMem(@Res.MD5Hash, @Hash, SizeOf(Hash)) then
      begin
       Print('HPAK_AddLump called with invalid lump (MD5 mismatch).');
       MD5_Print(Res.MD5Hash, MD5S);
       Print(['Purported: ', PLChar(@MD5S)]);
       MD5_Print(Hash, MD5S);
       Print(['Actual: ', PLChar(@MD5S)]);
       Print('Ignoring lump addition.');
      end
     else
      if ToCache then
       HPAK_AddToQueue(Name, Res, DataPtr, FilePtr)
      else
       begin
        if not COM_HasExtension(Name) then
         begin
          Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
          COM_DefaultExtension(Name, '.hpk');
         end;

        if not FS_Open(SrcFile, Name, 'r') then
         begin
          Print(['Creating HPAK "', Name, '".']);
          HPAK_CreatePak(Name, Res, DataPtr, FilePtr);
         end
        else
         begin
          S := @Buf2;
          COM_StripExtension(Name, S);
          COM_DefaultExtension(S, '.hp2');
          if not FS_Open(DstFile, S, 'wo') then
           Print(['HPAK_AddLump: Couldn''t open "', S, '" for writing.'])
          else
           begin
            if HPAK_ParseHeaders(@Buf, SrcFile, Header, DH, 1, False) then
             begin
              FS_Seek(SrcFile, 0, SEEK_SET);
              COM_CopyFileChunk(DstFile, SrcFile, FS_Size(SrcFile));

              if HPAK_FindResource(DH, @Res.MD5Hash, nil) then
               Print('HPAK_AddLump: HPAK already has this resource.')
              else
               begin
                DH2.NumEntries := DH.NumEntries + 1;
                DH2.Entries := Mem_Alloc(SizeOf(THPAKDirectory) * DH2.NumEntries);
                if DH2.Entries = nil then
                 Print('HPAK_AddLump: Out of memory.')
                else
                 begin
                  Move(DH.Entries^, DH2.Entries^, SizeOf(THPAKDirectory) * DH.NumEntries);

                  NewDir := @DH2.Entries[DH2.NumEntries - 1];
                  MemSet(NewDir^, SizeOf(NewDir^), 0);
                  Move(Res^, NewDir.Resource, SizeOf(NewDir.Resource));
                  NewDir.FileOffset := Header.FileOffset;
                  NewDir.Size := Res.DownloadSize;

                  FS_Seek(DstFile, Header.FileOffset, SEEK_SET);
                  if DataPtr <> nil then
                   FS_Write(DstFile, DataPtr, Res.DownloadSize)
                  else
                   COM_CopyFileChunk(DstFile, FilePtr^, Res.DownloadSize);

                  Header.FileOffset := UInt32(FS_Tell(DstFile));
                  FS_Write(DstFile, @DH2.NumEntries, SizeOf(DH2.NumEntries));
                  for I := 0 to DH2.NumEntries - 1 do
                   FS_Write(DstFile, @DH2.Entries[I], SizeOf(THPAKDirectory));

                  FS_Seek(DstFile, 0, SEEK_SET);
                  FS_Write(DstFile, @Header, SizeOf(Header));

                  Mem_Free(DH2.Entries);
                  Mem_Free(DH.Entries);
                  FS_Close(DstFile);
                  FS_Close(SrcFile);
                  FS_Unlink(Name);
                  FS_Rename(S, Name);
                  Exit;
                 end;
               end;

              Mem_Free(DH.Entries);
             end;

            FS_Close(DstFile);
            FS_Unlink(S);
           end;

          FS_Close(SrcFile);
         end;
       end;
end;

procedure HPAK_RemoveLump(Name: PLChar; Res: PResource);
var
 Buf, Buf2: array[1..MAX_PATH_W] of LChar;
 DstName: PLChar;
 SrcFile, DstFile: TFile;
 Header: THPAKHeader;
 DH, DH2: THPAKDirectoryHeader;
 I, J: Int;
begin
HPAK_FlushHostQueue;

if (Name = nil) or (Name^ = #0) then
 Print('HPAK_RemoveLump: Bad file name.')
else
 begin
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;
   
  if not FS_Open(SrcFile, Name, 'r') then
   Print(['HPAK_RemoveLump: Couldn''t open HPAK file "', Name, '".'])
  else
   begin
    DstName := @Buf2;
    COM_StripExtension(Name, DstName);
    COM_DefaultExtension(DstName, '.hp2');
    if not FS_Open(DstFile, DstName, 'wo') then
     Print(['HPAK_RemoveLump: Couldn''t create HPAK file "', DstName, '".'])
    else
     begin
      if HPAK_ParseHeaders(Name, SrcFile, Header, DH, 1, False) then
       begin
        if not HPAK_FindResource(DH, @Res.MD5Hash, nil) then
         Print(['HPAK_RemoveLump: HPAK doesn''t contain specified lump - "', PLChar(@Res.Name), '".'])
        else
         begin
          if DH.NumEntries = 1 then
           begin
            Print(['HPAK_RemoveLump: Removing final lump from HPAK, deleting HPAK: "', Name, '".']);
            Mem_Free(DH.Entries);
            FS_Close(DstFile);
            FS_Close(SrcFile);
            FS_Unlink(DstName);
            FS_Unlink(Name);
            Exit;
           end;

          FS_Write(DstFile, @Header, SizeOf(Header));
          DH2.NumEntries := DH.NumEntries - 1;
          DH2.Entries := Mem_Alloc(SizeOf(THPAKDirectory) * DH2.NumEntries);
          if DH2.Entries = nil then
           Print('HPAK_RemoveLump: Out of memory.')
          else
           begin
            Print(['Removing "', PLChar(@Res.Name), '" from HPAK "', Name, '".']);

            J := 0;
            for I := 0 to DH.NumEntries - 1 do
             if not CompareMem(@DH.Entries[I].Resource.MD5Hash, @Res.MD5Hash, SizeOf(Res.MD5Hash)) then
              begin
               Move(DH.Entries[I], DH2.Entries[J], SizeOf(THPAKDirectory));
               DH2.Entries[J].FileOffset := FS_Tell(DstFile);
               FS_Seek(SrcFile, DH.Entries[I].FileOffset, SEEK_SET);
               COM_CopyFileChunk(DstFile, SrcFile, DH2.Entries[J].Size);
               Inc(J);
              end;

            Header.FileOffset := UInt32(FS_Tell(DstFile));
            FS_Write(DstFile, @DH2.NumEntries, SizeOf(DH2.NumEntries));
            for I := 0 to DH2.NumEntries - 1 do
             FS_Write(DstFile, @DH2.Entries[I], SizeOf(THPAKDirectory));

            FS_Seek(DstFile, 0, SEEK_SET);
            FS_Write(DstFile, @Header, SizeOf(Header));

            Mem_Free(DH2.Entries);
            Mem_Free(DH.Entries);
            FS_Close(DstFile);
            FS_Close(SrcFile);
            FS_Unlink(Name);
            FS_Rename(DstName, Name);
            Exit;
           end;
         end;

        Mem_Free(DH.Entries);
       end;

      FS_Close(DstFile);
      FS_Unlink(DstName);
     end;

    FS_Close(SrcFile);
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

if not COM_HasExtension(Name) then
 begin
  Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  COM_DefaultExtension(Name, '.hpk');
 end;

if HPAK_ParseHeaders(Name, F, Header, DH) then
 begin
  if (Index < 0) or (Index >= DH.NumEntries) then
   Print(['The lump index is out of bounds (', Index + 1, '/', DH.NumEntries, ').'])
  else
   begin
    if Res <> nil then
     Move(DH.Entries[Index].Resource, Res^, SizeOf(TResource));
    Result := True;
   end;

  Mem_Free(DH.Entries);
  FS_Close(F);
 end;
end;

function HPAK_ResourceForHash(Name: PLChar; Hash: PMD5Hash; Res: PResource): Boolean;
var
 Buf: array[1..MAX_PATH_W] of LChar;
 P: PHPAKQueue;
 F: TFile;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
begin
P := HPAKQueue;
while P <> nil do
 if (StrIComp(P.Name, Name) = 0) and CompareMem(@P.Resource.MD5Hash, Hash, SizeOf(TMD5Hash)) then
  begin
   if Res <> nil then
    Move(P.Resource, Res^, SizeOf(TResource));
   Result := True;
   Exit;
  end
 else
  P := P.Prev;

if not COM_HasExtension(Name) then
 begin
  Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  COM_DefaultExtension(Name, '.hpk');
 end;

if HPAK_ParseHeaders(Name, F, Header, DH) then
 begin
  Result := HPAK_FindResource(DH, Hash, Res);
  Mem_Free(DH.Entries);
  FS_Close(F);
 end
else
 Result := False;
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
 MD5S: TMD5HashStr;
begin
if CmdSource <> csServer then
 Exit;

if Cmd_Argc <> 2 then
 Print('Usage: hpklist <hpkname> - List contents of HPAK file')
else
 begin
  HPAK_FlushHostQueue;
  Name := Cmd_Argv(1);
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;

  Print(['Listing contents for "', Name, '".']);
  if HPAK_ParseHeaders(Name, F, Header, DH) then
   begin
    Print(['| Number of entries: ', DH.NumEntries, '/', HPAK_MAX_ENTRIES, LineBreak +
           '| Type Size FileName : MD5 Hash']);
    for I := 0 to DH.NumEntries - 1 do
     begin
      E := @DH.Entries[I];
      Size := RoundTo(E.Resource.DownloadSize / 1024, -2);
      MD5_Print(E.Resource.MD5Hash, MD5S);
      Print(['#', I, ': ', HPAK_GetResourceDesc(E), ', size = ', Size, 'K, name = "', COM_FileBase(@E.Resource.Name, @Buf), '" : ', PLChar(@MD5S)]);
     end;

    Mem_Free(DH.Entries);
    FS_Close(F);
   end;
 end;
end;

procedure HPAK_CreatePak(Name: PLChar; Res: PResource; DataPtr: Pointer; FilePtr: PFile);
var
 F: TFile;
 Hash: TMD5Hash;
 MD5S: TMD5HashStr;
 I: Int;
 Header: THPAKHeader;
 DH: THPAKDirectoryHeader;
 E: PHPAKDirectory;
begin
if not FS_Open(F, Name, 'wo') then
 Print(['HPAK_CreatePak: Couldn''t open HPAK "', Name, '" for writing.'])
else
 begin
  if HPAK_HashStream(DataPtr, FilePtr, Res.DownloadSize, Hash) then
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
     FS_Write(F, @Header, SizeOf(Header));
     DH.NumEntries := 1;
     DH.Entries := Mem_Alloc(SizeOf(THPAKDirectory));
     if DH.Entries = nil then
      Print('HPAK_CreatePak: Out of memory.')
     else
      begin
       E := @DH.Entries[0];
       Move(Res^, E.Resource, SizeOf(E.Resource));
       E.FileOffset := UInt32(FS_Tell(F));
       E.Size := Res.DownloadSize;

       if DataPtr <> nil then
        FS_Write(F, DataPtr, Res.DownloadSize)
       else
        COM_CopyFileChunk(F, FilePtr^, Res.DownloadSize);

       Header.FileOffset := FS_Tell(F);
       FS_Write(F, @DH.NumEntries, SizeOf(DH.NumEntries));
       for I := 0 to DH.NumEntries - 1 do
        FS_Write(F, @DH.Entries[I], SizeOf(THPAKDirectory));

       FS_Seek(F, 0, SEEK_SET);
       FS_Write(F, @Header, SizeOf(Header));

       Mem_Free(DH.Entries);
      end;
    end;

  FS_Close(F);
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
 Print('Usage: hpkremove <hpkname> <lump index>')
else
 begin
  Name := Cmd_Argv(1);
  Index := StrToIntDef(Cmd_Argv(2), -1);
  if (Name^ = #0) or (Index < 0) then
   Print('Invalid lump index.')
  else
   HPAK_RemoveLump(Name, @Res);
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
    Print(['| Entries: ', DH.NumEntries, '/', HPAK_MAX_ENTRIES, LineBreak + '| Type Size FileName']);
    for I := 0 to DH.NumEntries - 1 do
     begin
      E := @DH.Entries[I];

      Size := RoundTo(E.Resource.DownloadSize / 1024, -2);
      Print(['#', I, ': ', HPAK_GetResourceDesc(E), ', size = ', Size, 'K, name = "', COM_FileBase(@E.Resource.Name, @Buf), '", '], False);

      if (E.Size < HPAK_MIN_LUMP_SIZE) or (E.Size > HPAK_MAX_LUMP_SIZE) then
       Print(['lump size is invalid'])
      else
       begin
        P := Mem_Alloc(E.Size + 1);
        FS_Seek(F, E.FileOffset, SEEK_SET);
        FS_Read(F, P, E.Size);
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
         Print(['MD5: OK']);
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
 Print('Usage: hpkextract <hpkname> <"all" | lump index>')
else
 begin
  Name := Cmd_Argv(1);
  if not COM_HasExtension(Name) then
   begin
    Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
    COM_DefaultExtension(Name, '.hpk');
   end;
  
  if StrIComp(Cmd_Argv(2), 'all') = 0 then
   begin
    Index := -1;
    Print(['Extracting all lumps from "', Name, '".']);
   end
  else
   begin
    Index := StrToIntDef(Cmd_Argv(2), -1);
    if Index < 0 then
     begin
      Print('Bad lump index, must be an unsigned integer value or "all".');
      Exit;
     end;

    Print(['Extracting lump #', Index, ' from "', Name, '".']);
   end;

  if HPAK_ParseHeaders(Name, F, Header, DH) then
   begin
    Print(['| Entries: ', DH.NumEntries, '/', HPAK_MAX_ENTRIES, LineBreak + '| Type Size FileName']);
    for I := 0 to DH.NumEntries - 1 do
     if (Index = -1) or (I = Index) then
      begin
       E := @DH.Entries[I];

       Size := RoundTo(E.Resource.DownloadSize / 1024, -2);
       Print(['Extracting lump #', I, ': ', HPAK_GetResourceDesc(E), ', size = ', Size, 'K, name = "', COM_FileBase(@E.Resource.Name, @Buf), '"']);

       if (E.Size < HPAK_MIN_LUMP_SIZE) or (E.Size > HPAK_MAX_LUMP_SIZE) then
        Print(['Unable to extract data, size is invalid: ', E.Size, '.'])
       else
        begin
         P := Mem_Alloc(E.Size + 1);
         FS_Seek(F, E.FileOffset, SEEK_SET);
         FS_Read(F, P, E.Size);

         S := StrECopy(@Buf, 'hpklmps' + CorrectSlash + 'lmp');
         S := StrECopy(S, ExpandString(IntToStr(I, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 4));
         StrCopy(S, '.wad');

         COM_FixSlashes(@Buf);
         COM_CreatePath(@Buf);
         if FS_Open(F2, @Buf, 'wo') then
          begin
           FS_Write(F2, P, E.Size);
           FS_Close(F2);
          end
         else
          Print(['Error creating WAD file "', PLChar(@Buf), '".']);

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
 S: PLChar;
begin
HPAK_FlushHostQueue;

if HPAK_ParseHeaders('custom.hpk', F, Header, DH) then
 begin
  if Index > DH.NumEntries - 1 then
   Index := DH.NumEntries - 1;
  MD5_Print(DH.Entries[Index].Resource.MD5Hash, MD5S);

  if L > 36 then
   begin
    S := StrECopy(Buffer, '!MD5');
    StrCopy(S, @MD5S);
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

if Size > 0 then
 begin
  Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  COM_FixSlashes(Name);  
  COM_DefaultExtension(Name, '.hpk');

  if FS_SizeByName(Name) >= Size * (1024 * 1024) then
   begin
    DPrint(['Size of HPAK "', Name, '" is greater than ', Size, ' MB, deleting.']);
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

procedure HPAK_CheckIntegrity(Name: PLChar);
var
 Buf: array[1..MAX_PATH_W] of LChar;
 DataBuf: array[1..HPAK_MAX_LUMP_SIZE] of Byte;
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

if not COM_HasExtension(Name) then
 begin
  Name := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  COM_DefaultExtension(Name, '.hpk');
 end;

if HPAK_ParseHeaders(Name, F, Header, DH) then
 begin
  B := False;
  
  for I := 0 to DH.NumEntries - 1 do
   begin
    E := @DH.Entries[I];
    if (E.Size < HPAK_MIN_LUMP_SIZE) or (E.Size > HPAK_MAX_LUMP_SIZE) then
     begin
      B := True;
      Print(['Invalid data lump size in HPAK "', Name, '" at #', I, ': ', E.Size, '.']);
      Break;
     end;

    FS_Seek(F, E.FileOffset, SEEK_SET);
    FS_Read(F, @DataBuf, E.Size);
    DataBuf[E.Size + 1] := 0;

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

procedure HPAK_Init;
begin
CVar_RegisterVariable(hpk_maxsize);
Cmd_AddCommand('hpklist', @HPAK_List_f);
Cmd_AddCommand('hpkremove', @HPAK_Remove_f);
Cmd_AddCommand('hpkval', @HPAK_Validate_f);
Cmd_AddCommand('hpkextract', @HPAK_Extract_f);
HPAKQueue := nil;
end;

end.              
