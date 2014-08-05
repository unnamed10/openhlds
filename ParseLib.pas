unit ParseLib;

{$I HLDS.inc}

interface

{$IFDEF MSWINDOWS}

uses Windows, Default, SDK;

procedure WriteExportTable(out ET: TExtLibData; P: Pointer);

implementation

uses Memory, SysMain;

{$IF not Declared(TImageExportDirectory)}
 {$IF not Declared(PImageExportDirectory)}
 type
  PImageExportDirectory = ^TImageExportDirectory;
  TImageExportDirectory = packed record
   Characteristics: UInt32;
   TimeDateStamp: UInt32;
   MajorVersion: UInt16;
   MinorVersion: UInt16;
   Name: UInt32;
   Base: UInt32;
   NumberOfFunctions: UInt32;
   NumberOfNames: UInt32;
   AddressOfFunctions: ^PUInt32;
   AddressOfNames: ^PUInt32;
   AddressOfNameOrdinals: ^PUInt16;
  end;
 {$IFEND}
{$IFEND}

function GetSignature(P: Pointer): UInt16;
var
 I: UInt16;
begin
if PImageDosHeader(P).e_magic = IMAGE_DOS_SIGNATURE then
 begin
  I := PImageNtHeaders(UInt(P) + UInt(PImageDosHeader(P)._lfanew)).Signature;
  if (I = IMAGE_OS2_SIGNATURE) or (I = IMAGE_OS2_SIGNATURE_LE) then
   Result := I
  else
   if I = IMAGE_NT_SIGNATURE then
    Result := IMAGE_NT_SIGNATURE
   else
    Result := IMAGE_DOS_SIGNATURE;
 end
else
 Result := 0;
end;

function GetNumOfSections(P: Pointer): UInt;
begin
Result := PImageNtHeaders(UInt(P) + UInt(PImageDosHeader(P)._lfanew)).FileHeader.NumberOfSections;
end;

function GetDirectoryRawData(P: Pointer; Index: UInt): Pointer;
var
 NTHdr: PImageNtHeaders;
 SectHdr: PImageSectionHeader;
 NumSect, RVA: UInt;
 I: Int;
begin
NTHdr := PImageNtHeaders(UInt(P) + UInt(PImageDosHeader(P)._lfanew));
SectHdr := Pointer(UInt(NtHdr) + SizeOf(NtHdr^));
NumSect := GetNumOfSections(P);

if Index >= NTHdr.OptionalHeader.NumberOfRvaAndSizes then
 Result := nil
else
 begin
  RVA := NTHdr.OptionalHeader.DataDirectory[Index].VirtualAddress;
  for I := 0 to NumSect - 1 do
   if (SectHdr.VirtualAddress <= RVA) and (SectHdr.VirtualAddress + SectHdr.SizeOfRawData > RVA) then
    begin
     Result := Pointer(UInt(P) + RVA + SectHdr.PointerToRawData - SectHdr.VirtualAddress);
     Exit;
    end
   else
    Inc(UInt(SectHdr), SizeOf(SectHdr^));

  Result := nil;
 end;
end;

function GetSectionInfo(P: Pointer; out Sect: TImageSectionHeader; Name: PLChar): Boolean;
var
 NTHdr: PImageNtHeaders;
 SectHdr: PImageSectionHeader;
 NumSect: UInt;
 I: Int;
begin
NTHdr := PImageNtHeaders(UInt(P) + UInt(PImageDosHeader(P)._lfanew));
SectHdr := Pointer(UInt(NtHdr) + SizeOf(NtHdr^));
NumSect := GetNumOfSections(P);
for I := 0 to NumSect - 1 do
 if StrComp(@SectHdr.Name, Name) = 0 then
  begin
   Sect := SectHdr^;
   Result := True;
   Exit;
  end
 else
  Inc(UInt(SectHdr), SizeOf(SectHdr^));

Result := False;
end;

function GetRDataNameTable(P: Pointer): Pointer;
var
 ExportDir: PImageExportDirectory;
 Sect: TImageSectionHeader;
 NameAddr: UInt;
begin
ExportDir := GetDirectoryRawData(P, IMAGE_DIRECTORY_ENTRY_EXPORT);
if (ExportDir <> nil) and GetSectionInfo(P, Sect, '.rdata') then
 begin
  NameAddr := PUInt32(UInt(P) + Sect.PointerToRawData - Sect.VirtualAddress + UInt(ExportDir.AddressOfNames))^;
  Result := Pointer(UInt(P) + Sect.PointerToRawData - Sect.VirtualAddress + NameAddr);
 end
else
 Result := nil; 
end;

function GetNameTableSize(P: Pointer; out RData: Pointer): UInt;
var
 ExportDir: PImageExportDirectory;
 NameTable: Pointer;
 I: Int;
begin
ExportDir := GetDirectoryRawData(P, IMAGE_DIRECTORY_ENTRY_EXPORT);
if ExportDir <> nil then
 begin
  NameTable := GetRDataNameTable(P);
  if NameTable <> nil then
   begin
    RData := NameTable;
    P := NameTable;
    for I := 0 to ExportDir.NumberOfNames - 1 do
     begin
      while PLChar(P)^ > #0 do
       Inc(UInt(P));
      Inc(UInt(P));
     end;

    Result := UInt(P) - UInt(NameTable);
    Exit;
   end;
 end;

RData := nil;
Result := 0;
end;

function EnumLibExports(P: Pointer; out NameTable: Pointer): UInt;
var
 RData: Pointer;
 Size: UInt;
begin
Size := GetNameTableSize(P, RData);
if (Size > 0) and (RData <> nil) then
 begin
  NameTable := Mem_Alloc(Size);
  Move(RData^, NameTable^, Size);
  Result := Size;
 end
else
 begin
  NameTable := nil;
  Result := 0;
 end;
end;

procedure FixRelativeName(Src, Dst: PLChar);
var
 I: UInt;
begin
if Src^ > #0 then
 begin
  Inc(UInt(Src));
  I := 0;
  while (Src^ > #0) and (I < 2) do
   begin
    Dst^ := Src^;
    if Src^ = '@' then
     Inc(I);
    Inc(UInt(Src));
    Inc(UInt(Dst));
   end;

  if I = 2 then
   PLChar(UInt(Dst) - SizeOf(Dst^))^ := #0;
 end;

Dst^ := #0;
end;

procedure WriteExportTable(out ET: TExtLibData; P: Pointer);
var
 Size, NumExport, SizeExport, I: UInt;
 NT, NP: Pointer;
 Src, SrcEnd: PLChar;
 Buf: array[1..256] of LChar;
begin
ET.ExportTable := nil;
ET.NumExport := 0;
if P = nil then
 Exit;

Size := EnumLibExports(P, NT);
if NT = nil then
 Exit;

NumExport := 0;
SizeExport := 0;

Src := NT;
SrcEnd := Pointer(UInt(Src) + Size);
while UInt(Src) < UInt(SrcEnd) do
 begin
  if Src^ = '?' then
   begin
    FixRelativeName(Src, @Buf);
    Inc(NumExport);
    Inc(SizeExport, StrLen(@Buf) + 1);
   end;

  Inc(UInt(Src), StrLen(Src) + 1);
 end;

ET.ExportTable := Mem_Alloc(SizeExport + NumExport * SizeOf(TExtLibExport));
ET.NumExport := NumExport;

NP := Pointer(UInt(ET.ExportTable) + NumExport * SizeOf(TExtLibExport));
Src := NT;
I := 0;
while UInt(Src) < UInt(SrcEnd) do
 begin
  if Src^ = '?' then
   begin
    FixRelativeName(Src, NP);
    ET.ExportTable[I].Name := NP;
    ET.ExportTable[I].Func := Sys_GetProcAddress(ET.Handle, Src);
    Inc(I);
    Inc(UInt(NP), StrLen(NP) + 1);
   end;

  Inc(UInt(Src), StrLen(Src) + 1);
 end;

Mem_Free(NT);
end;

{$ELSE}

implementation

{$ENDIF}

end.
