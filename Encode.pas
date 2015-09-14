unit Encode;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure CRC32_Init(out CRC: TCRC);
function CRC32_Final(CRC: TCRC): TCRC;
procedure CRC32_ProcessByte(var CRC: TCRC; B: Byte);
procedure CRC32_ProcessBuffer(var CRC: TCRC; Buffer: Pointer; Size: UInt);
function CRC_File(var CRC: TCRC; Name: PLChar): Boolean;
function CRC_MapFile(var CRC: TCRC; Name: PLChar): Boolean;

procedure MD5Init(out C: TMD5Context);
procedure MD5Update(var C: TMD5Context; Input: Pointer; Length: UInt);
procedure MD5Final(out Hash: TMD5Hash; var C: TMD5Context);

function MD5_Hash_File(out Hash: TMD5Hash; Name: PLChar; UseFOpen, UseSeed: Boolean; Seed: PMD5Hash): Boolean;
procedure MD5_Print(const Hash; out Buffer: TMD5HashStr);

function MD5_IsValid(S: PLChar): Boolean;

function COM_BlockSequenceCRCByte(Input: Pointer; Size: UInt; Sequence: UInt32): TCRC;

implementation

uses Common, Console, FileSys, Host, SysMain;

procedure MD5Transform(Buffer: PMD5Hash; Input: PMD5Array16); forward;

const
 CRCTable: array[Byte] of UInt32 =
           ($00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3,
            $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
            $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
            $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
            $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
            $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
            $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
            $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
            $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
            $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
            $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
            $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
            $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
            $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
            $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
            $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
            $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
            $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
            $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7,
            $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
            $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
            $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
            $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F,
            $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
            $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
            $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
            $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
            $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
            $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB,
            $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
            $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
            $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

procedure CRC32_Init(out CRC: TCRC);
begin
CRC := $FFFFFFFF;
end;

function CRC32_Final(CRC: TCRC): TCRC;
begin
Result := not CRC;
end;

procedure CRC32_ProcessByte(var CRC: TCRC; B: Byte);
var
 I: TCRC;
begin
I := CRC xor B;
CRC := CRCTable[Byte(I)] xor (I shr 8);
end;

procedure CRC32_ProcessBuffer(var CRC: TCRC; Buffer: Pointer; Size: UInt);
const
 BitTable: array[0..7] of UInt = (0, 7, 6, 5, 4, 3, 2, 1);
var
 I, J, X: UInt;
 C: TCRC;
begin
C := CRC;

X := BitTable[UInt(Buffer) and Byte(7)];
if X >= Size then
 X := Size;
Size := Size - X;

for I := 1 to X do
 begin
  J := C xor PByte(Buffer)^;
  C := CRCTable[Byte(J)] xor (J shr 8);
  Inc(UInt(Buffer));
 end;

while Size >= 8 do
 begin
  C := C xor PUInt32(Buffer)^;
  C := CRCTable[Byte(C)] xor (C shr 8);
  C := CRCTable[Byte(C)] xor (C shr 8);
  C := CRCTable[Byte(C)] xor (C shr 8);
  C := CRCTable[Byte(C)] xor (C shr 8);

  C := C xor PUInt32(UInt(Buffer) + SizeOf(UInt32))^;
  C := CRCTable[Byte(C)] xor (C shr 8);
  C := CRCTable[Byte(C)] xor (C shr 8);
  C := CRCTable[Byte(C)] xor (C shr 8);
  C := CRCTable[Byte(C)] xor (C shr 8);

  Inc(UInt(Buffer), 8);
  Dec(Size, 8);
 end;

for I := 1 to Size do
 begin
  J := C xor PByte(Buffer)^;
  C := CRCTable[Byte(J)] xor (J shr 8);
  Inc(UInt(Buffer));
 end;

CRC := C;
end;

function COM_BlockSequenceCRCByte(Input: Pointer; Size: UInt; Sequence: UInt32): TCRC;
var
 Buf: array[0..63] of Byte;
 K: array[0..3] of Byte;
 I: TCRC;
begin
if Size > 60 then
 Size := 60;

Move(Input^, Buf, Size);
PUInt32(@K)^ := PUInt32(UInt(@CRCTable) + Sequence mod 1020)^;
Buf[Size + 0] := K[0];
Buf[Size + 1] := K[1];
Buf[Size + 2] := K[2];
Buf[Size + 3] := K[3];
Inc(Size, 4);

I := Sequence;
CRC32_Init(I);
CRC32_ProcessBuffer(I, @Buf, Size);
Result := CRC32_Final(I);
end;

function CRC_File(var CRC: TCRC; Name: PLChar): Boolean;
var
 F: TFile;
 Size: Int64;
 I: UInt;
 Buf: array[1..1024] of Byte;
begin
Result := FS_Open(F, Name, 'r');
if Result then
 begin
  Size := FS_Size(F);
  while Size > 0 do
   begin
    if Size > SizeOf(Buf) then
     I := FS_Read(F, @Buf, SizeOf(Buf))
    else
     I := FS_Read(F, @Buf, Size);

    if I = 0 then
     Break
    else
     begin
      Dec(Size, I);
      CRC32_ProcessBuffer(CRC, @Buf, I);
     end;

    if FS_EndOfFile(F) then
     Break;
   end;
  FS_Close(F);
 end;
end;

function CRC_MapFile(var CRC: TCRC; Name: PLChar): Boolean;
var
 BShift: Boolean;
 F: TFile;
 Header: TDHeader;
 I, L, BytesRead: UInt;
 Buf: array[1..1024] of Byte;
begin
Result := False;
BShift := StrIComp(PLChar(GameDir), 'bshift') = 0;
if FS_Open(F, Name, 'r') then
 begin
  if FS_Read(F, @Header, SizeOf(Header)) < SizeOf(Header) then
   Print(['Couldn''t read BSP header for map "', Name, '".'])
  else
   begin
    Header.Version := LittleLong(Header.Version);
    if (Header.Version <> 29) and (Header.Version <> 30) then
     Print(['Map "', Name, '" has incorrect BSP version: got ', Header.Version, ', should be 30.'])
    else
     begin
      for I := 0 to HEADER_LUMPS - 1 do
       if (UInt(BShift) <> I) and (Header.Lumps[I].FileLength > 0) then
        begin
         FS_Seek(F, Header.Lumps[I].FileOffset, SEEK_SET);
         L := Header.Lumps[I].FileLength;

         while L > 0 do
          begin
           if L > SizeOf(Buf) then
            BytesRead := FS_Read(F, @Buf, SizeOf(Buf))
           else
            BytesRead := FS_Read(F, @Buf, L);

           if BytesRead > 0 then
            begin
             Dec(L, BytesRead);
             CRC32_ProcessBuffer(CRC, @Buf, BytesRead);
            end
           else
            Break;
          end;
        end;
      Result := True;
     end;
   end;

  FS_Close(F);
 end;
end;

procedure MD5Step1(var W: UInt32; X, Y, Z, Data, S: UInt32); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
Inc(W, (Z xor (X and (Y xor Z))) + Data);
W := ((W shl S) or (W shr (32 - S))) + X;
end;

procedure MD5Step2(var W: UInt32; X, Y, Z, Data, S: UInt32); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
Inc(W, (Y xor (Z and (X xor Y))) + Data);
W := ((W shl S) or (W shr (32 - S))) + X;
end;

procedure MD5Step3(var W: UInt32; X, Y, Z, Data, S: UInt32); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
Inc(W, (X xor Y xor Z) + Data);
W := ((W shl S) or (W shr (32 - S))) + X;
end;

procedure MD5Step4(var W: UInt32; X, Y, Z, Data, S: UInt32); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
Inc(W, (Y xor (X or not Z)) + Data);
W := ((W shl S) or (W shr (32 - S))) + X;
end;

procedure MD5Transform(Buffer: PMD5Hash; Input: PMD5Array16);
var
 A, B, C, D: UInt32;
begin
A := Buffer[1];
B := Buffer[2];
C := Buffer[3];
D := Buffer[4];

MD5Step1(A, B, C, D, Input[1] + $D76AA478, 7);
MD5Step1(D, A, B, C, Input[2] + $E8C7B756, 12);
MD5Step1(C, D, A, B, Input[3] + $242070DB, 17);
MD5Step1(B, C, D, A, Input[4] + $C1BDCEEE, 22);
MD5Step1(A, B, C, D, Input[5] + $F57C0FAF, 7);
MD5Step1(D, A, B, C, Input[6] + $4787C62A, 12);
MD5Step1(C, D, A, B, Input[7] + $A8304613, 17);
MD5Step1(B, C, D, A, Input[8] + $FD469501, 22);
MD5Step1(A, B, C, D, Input[9] + $698098D8, 7);
MD5Step1(D, A, B, C, Input[10] + $8B44F7AF, 12);
MD5Step1(C, D, A, B, Input[11] + $FFFF5BB1, 17);
MD5Step1(B, C, D, A, Input[12] + $895CD7BE, 22);
MD5Step1(A, B, C, D, Input[13] + $6B901122, 7);
MD5Step1(D, A, B, C, Input[14] + $FD987193, 12);
MD5Step1(C, D, A, B, Input[15] + $A679438E, 17);
MD5Step1(B, C, D, A, Input[16] + $49B40821, 22);

MD5Step2(A, B, C, D, Input[2] + $F61E2562, 5);
MD5Step2(D, A, B, C, Input[7] + $C040B340, 9);
MD5Step2(C, D, A, B, Input[12] + $265E5A51, 14);
MD5Step2(B, C, D, A, Input[1] + $E9B6C7AA, 20);
MD5Step2(A, B, C, D, Input[6] + $D62F105D, 5);
MD5Step2(D, A, B, C, Input[11] + $02441453, 9);
MD5Step2(C, D, A, B, Input[16] + $D8A1E681, 14);
MD5Step2(B, C, D, A, Input[5] + $E7D3FBC8, 20);
MD5Step2(A, B, C, D, Input[10] + $21E1CDE6, 5);
MD5Step2(D, A, B, C, Input[15] + $C33707D6, 9);
MD5Step2(C, D, A, B, Input[4] + $F4D50D87, 14);
MD5Step2(B, C, D, A, Input[9] + $455A14ED, 20);
MD5Step2(A, B, C, D, Input[14] + $A9E3E905, 5);
MD5Step2(D, A, B, C, Input[3] + $FCEFA3F8, 9);
MD5Step2(C, D, A, B, Input[8] + $676F02D9, 14);
MD5Step2(B, C, D, A, Input[13] + $8D2A4C8A, 20);

MD5Step3(A, B, C, D, Input[6] + $FFFA3942, 4);
MD5Step3(D, A, B, C, Input[9] + $8771F681, 11);
MD5Step3(C, D, A, B, Input[12] + $6D9D6122, 16);
MD5Step3(B, C, D, A, Input[15] + $FDE5380C, 23);
MD5Step3(A, B, C, D, Input[2] + $A4BEEA44, 4);
MD5Step3(D, A, B, C, Input[5] + $4BDECFA9, 11);
MD5Step3(C, D, A, B, Input[8] + $F6BB4B60, 16);
MD5Step3(B, C, D, A, Input[11] + $BEBFBC70, 23);
MD5Step3(A, B, C, D, Input[14] + $289B7EC6, 4);
MD5Step3(D, A, B, C, Input[1] + $EAA127FA, 11);
MD5Step3(C, D, A, B, Input[4] + $D4EF3085, 16);
MD5Step3(B, C, D, A, Input[7] + $04881D05, 23);
MD5Step3(A, B, C, D, Input[10] + $D9D4D039, 4);
MD5Step3(D, A, B, C, Input[13] + $E6DB99E5, 11);
MD5Step3(C, D, A, B, Input[16] + $1FA27CF8, 16);
MD5Step3(B, C, D, A, Input[3] + $C4AC5665, 23);

MD5Step4(A, B, C, D, Input[1] + $F4292244, 6);
MD5Step4(D, A, B, C, Input[8] + $432AFF97, 10);
MD5Step4(C, D, A, B, Input[15] + $AB9423A7, 15);
MD5Step4(B, C, D, A, Input[6] + $FC93A039, 21);
MD5Step4(A, B, C, D, Input[13] + $655B59C3, 6);
MD5Step4(D, A, B, C, Input[4] + $8F0CCC92, 10);
MD5Step4(C, D, A, B, Input[11] + $FFEFF47D, 15);
MD5Step4(B, C, D, A, Input[2] + $85845DD1, 21);
MD5Step4(A, B, C, D, Input[9] + $6FA87E4F, 6);
MD5Step4(D, A, B, C, Input[16] + $FE2CE6E0, 10);
MD5Step4(C, D, A, B, Input[7] + $A3014314, 15);
MD5Step4(B, C, D, A, Input[14] + $4E0811A1, 21);
MD5Step4(A, B, C, D, Input[5] + $F7537E82, 6);
MD5Step4(D, A, B, C, Input[12] + $BD3AF235, 10);
MD5Step4(C, D, A, B, Input[3] + $2AD7D2BB, 15);
MD5Step4(B, C, D, A, Input[10] + $EB86D391, 21);

Inc(Buffer[1], A);
Inc(Buffer[2], B);
Inc(Buffer[3], C);
Inc(Buffer[4], D);
end;

procedure MD5Init(out C: TMD5Context);
begin
with C do
 begin
  MemSet(Input, SizeOf(Input), 0);
  Buffer[1] := $67452301;
  Buffer[2] := $EFCDAB89;
  Buffer[3] := $98BADCFE;
  Buffer[4] := $10325476;
  Bits[1] := 0;
  Bits[2] := 0;
 end;
end;

procedure MD5Update(var C: TMD5Context; Input: Pointer; Length: UInt);
var
 X: UInt32;
begin
X := C.Bits[1];
Inc(C.Bits[1], Length * 8);
if C.Bits[1] < X then
 Inc(C.Bits[2]);

X := (X shr 3) and 63;
Inc(C.Bits[2], Length shr 29);

if X > 0 then
 if Length < 64 - X then
  begin
   Move(Input^, Pointer(UInt(@C.Input) + X)^, Length);
   Exit;
  end
 else
  begin
   Move(Input^, Pointer(UInt(@C.Input) + X)^, 64 - X);
   MD5Transform(@C.Buffer, @C.Input);
   Inc(UInt(Input), 64 - X);
   Dec(Length, 64 - X);
  end;

while Length >= 64 do
 begin
  Move(Input^, C.Input, 64);
  MD5Transform(@C.Buffer, @C.Input);
  Inc(UInt(Input), 64);
  Dec(Length, 64);
 end;

Move(Input^, C.Input, Length);
end;

procedure MD5Final(out Hash: TMD5Hash; var C: TMD5Context);
var
 N: UInt32;
 P: PLChar;
begin
N := (C.Bits[1] shr 3) and 63;
P := PLChar(UInt(@C.Input) + N);
P^ := #$80;
Inc(UInt(P));

N := 63 - N;
if N >= 8 then
 MemSet(P^, N - 8, 0)
else
 begin
  MemSet(P^, N, 0);
  MD5Transform(@C.Buffer, @C.Input);
  MemSet(C.Input, 64 - 8, 0);
 end;

C.Input[15] := C.Bits[1];
C.Input[16] := C.Bits[2];

MD5Transform(@C.Buffer, @C.Input);
Move(C.Buffer, Hash, SizeOf(Hash));
MemSet(C, SizeOf(C), 0);
end;

function MD5_Hash_File(out Hash: TMD5Hash; Name: PLChar; UseFOpen, UseSeed: Boolean; Seed: PMD5Hash): Boolean;
const
 BufSize = 2048;
var
 F: TFile;
 Size, BSize: Int;
 MD5C: TMD5Context;
 Buf: array[1..BufSize] of Byte;
begin
Result := False;

if FS_Open(F, Name, 'r') then
 begin
  Size := FS_Size(F);
  if Size > 0 then
   begin
    MemSet(MD5C, SizeOf(MD5C), 0);
    MD5Init(MD5C);
    if UseSeed then
     MD5Update(MD5C, Seed, SizeOf(Seed^));

    while True do
     begin
      BSize := FS_Read(F, @Buf, Min(Size, BufSize));
      if BSize > 0 then
       begin
        Dec(Size, BSize);
        MD5Update(MD5C, @Buf, BSize);
       end;

      if (Size <= 0) or (FS_EndOfFile(F)) then
       Break;
     end;

    MD5Final(Hash, MD5C);
    Result := True;
   end;

  FS_Close(F);
 end;
end;

procedure MD5_Print(const Hash; out Buffer: TMD5HashStr);
var
 I: UInt;
 C: Byte;
begin
I := 0;
while I < SizeOf(TMD5Hash) do
 begin
  C := PByte(UInt(@Hash) + I)^;
  PUInt16(UInt(@Buffer) + I shl 1)^ := (Byte(HexLookupTable[C and $F]) shl 8) or
                                        Byte(HexLookupTable[C shr 4]);
  Inc(I);
 end;
PLChar(UInt(@Buffer) + SizeOf(Buffer) - 1)^ := #0;
end;

function MD5_IsValid(S: PLChar): Boolean;
var
 S2: PLChar;
begin
S2 := S;
if S <> nil then
 while S^ > #0 do
  if not (S^ in ['0'..'9', 'a'..'f', 'A'..'F']) then
   begin
    Result := False;
    Exit;
   end
  else
   Inc(UInt(S));

Result := UInt(S) - UInt(S2) = 32;
end;

end.
