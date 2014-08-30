unit Delta;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

function Delta_FindField(const D: TDelta; Name: PLChar): PDeltaField;
function Delta_FindFieldIndex(const D: TDelta; Name: PLChar): Int;
procedure Delta_SetField(var D: TDelta; Name: PLChar);
procedure Delta_UnsetField(var D: TDelta; Name: PLChar);
procedure Delta_SetFieldByIndex(var D: TDelta; Index: UInt);
procedure Delta_UnsetFieldByIndex(var D: TDelta; Index: UInt);
procedure Delta_ClearFlags(var D: TDelta);
function Delta_TestDelta(OS, NS: Pointer; var Delta: TDelta): UInt;
function Delta_CountSendFields(var Delta: TDelta): UInt;
procedure Delta_MarkSendFields(OS, NS: Pointer; var Delta: TDelta);
procedure Delta_SetSendFlagBits(const Delta: TDelta; Dest: Pointer; out BytesWritten: UInt);
procedure Delta_WriteMarkedFields(OS, NS: Pointer; const Delta: TDelta);
function Delta_CheckDelta(OS, NS: Pointer; var Delta: TDelta): UInt;
function Delta_WriteDelta(OS, NS: Pointer; ForceUpdate: Boolean; var Delta: TDelta; Func: TProcedure): Boolean;
function Delta_ParseDelta(OS, NS: Pointer; var Delta: TDelta): Int;

procedure Delta_FreeDescription(var D: PDelta);

procedure Delta_AddEncoder(Name: PLChar; Func: TDeltaEncoder);

function Delta_LookupRegistration(Name: PLChar): PDelta;
function Delta_LookupEncoder(Name: PLChar): TDeltaEncoder;

function Delta_Load(Name: PLChar; var Delta: PDelta; FileName: PLChar): Boolean;

procedure Delta_Init;
procedure Delta_Shutdown;

implementation

uses Console, MsgBuf, Server, SysMain, Memory, Common;

var
 EncoderList: PDeltaEncoderEntry = nil;
 DefList: PDeltaDefinition = nil;
 RegList: PDeltaRegistry = nil;

function Delta_FindField(const D: TDelta; Name: PLChar): PDeltaField;
var
 I: Int;
begin
for I := 0 to D.NumFields - 1 do
 if StrIComp(@D.Fields[I].Name, Name) = 0 then
  begin
   Result := @D.Fields[I];
   Exit;
  end;

Print(['Delta_FindField: Warning - couldn''t find "', Name, '".']);
Result := nil;
end;

function Delta_FindFieldIndex(const D: TDelta; Name: PLChar): Int;
var
 I: Int;
begin
for I := 0 to D.NumFields - 1 do
 if StrIComp(@D.Fields[I].Name, Name) = 0 then
  begin
   Result := I;
   Exit;
  end;

Print(['Delta_FindFieldIndex: Warning - couldn''t find "', Name, '".']);
Result := -1;
end;

procedure Delta_SetField(var D: TDelta; Name: PLChar);
var
 F: PDeltaField;
begin
F := Delta_FindField(D, Name);
if F <> nil then
 Include(F.Flags, ffReady);
end;

procedure Delta_UnsetField(var D: TDelta; Name: PLChar);
var
 F: PDeltaField;
begin
F := Delta_FindField(D, Name);
if F <> nil then
 Exclude(F.Flags, ffReady);
end;

procedure Delta_SetFieldByIndex(var D: TDelta; Index: UInt);
begin
Include(D.Fields[Index].Flags, ffReady);
end;

procedure Delta_UnsetFieldByIndex(var D: TDelta; Index: UInt);
begin
Exclude(D.Fields[Index].Flags, ffReady);
end;

procedure Delta_ClearFlags(var D: TDelta);
var
 I: Int;
begin
for I := 0 to D.NumFields - 1 do
 D.Fields[I].Flags := [];
end;

function Delta_TestDelta(OS, NS: Pointer; var Delta: TDelta): UInt;
var
 I, LastIndex: Int;
 F: PDeltaField;
 B: Boolean;
 Bits: UInt;
begin
Bits := 0;
LastIndex := -1;

for I := 0 to Delta.NumFields - 1 do
 begin
  F := @Delta.Fields[I];
  case F.FieldType and not DT_SIGNED of
   DT_TIMEWINDOW_8:
    B := Trunc(PSingle(UInt(OS) + F.Offset)^ * 100) = Trunc(PSingle(UInt(NS) + F.Offset)^ * 100);
   DT_TIMEWINDOW_BIG:
    B := Trunc(PSingle(UInt(OS) + F.Offset)^ * 1000) = Trunc(PSingle(UInt(NS) + F.Offset)^ * 1000);
   DT_FLOAT, DT_INTEGER, DT_ANGLE:
    B := PUInt32(UInt(OS) + F.Offset)^ = PUInt32(UInt(NS) + F.Offset)^;
   DT_BYTE:
    B := PByte(UInt(OS) + F.Offset)^ = PByte(UInt(NS) + F.Offset)^;
   DT_SHORT:
    B := PUInt16(UInt(OS) + F.Offset)^ = PUInt16(UInt(NS) + F.Offset)^;
   DT_STRING:
    begin
     B := StrIComp(PLChar(UInt(OS) + F.Offset), PLChar(UInt(NS) + F.Offset)) = 0;
     if not B then
      begin
       Include(F.Flags, ffReady);
       Inc(Bits, (StrLen(PLChar(UInt(NS) + F.Offset)) + 1) * 8);
       B := True;
      end;
    end
   else
    begin
     B := False;
     Print(['Delta_TestDelta: Bad field type "', F.FieldType and not DT_SIGNED, '".']);
    end;
  end;

  if not B then
   begin
    LastIndex := I;
    Inc(Bits, F.Bits);
   end;
 end;

if LastIndex <> -1 then
 Inc(Bits, (LastIndex and not 7) + 8);

Result := Bits;
end;

function Delta_CountSendFields(var Delta: TDelta): UInt;
var
 I: Int;
begin
Result := 0;

for I := 0 to Delta.NumFields - 1 do
 if ffReady in Delta.Fields[I].Flags then
  begin
   Inc(Delta.Fields[I].SendCount);
   Inc(Result);
  end;
end;

procedure Delta_MarkSendFields(OS, NS: Pointer; var Delta: TDelta);
var
 I: Int;
 F: PDeltaField;
 B: Boolean;
begin
for I := 0 to Delta.NumFields - 1 do
 begin
  F := @Delta.Fields[I];
  case F.FieldType and not DT_SIGNED of
   DT_TIMEWINDOW_8:
    B := Trunc(PSingle(UInt(OS) + F.Offset)^ * 100) <> Trunc(PSingle(UInt(NS) + F.Offset)^ * 100);
   DT_TIMEWINDOW_BIG:
    B := Trunc(PSingle(UInt(OS) + F.Offset)^ * 1000) <> Trunc(PSingle(UInt(NS) + F.Offset)^ * 1000);
   DT_FLOAT, DT_INTEGER, DT_ANGLE:
    B := PUInt32(UInt(OS) + F.Offset)^ <> PUInt32(UInt(NS) + F.Offset)^;
   DT_BYTE:
    B := PByte(UInt(OS) + F.Offset)^ <> PByte(UInt(NS) + F.Offset)^;
   DT_SHORT:
    B := PUInt16(UInt(OS) + F.Offset)^ <> PUInt16(UInt(NS) + F.Offset)^;
   DT_STRING:
    B := StrIComp(PLChar(UInt(OS) + F.Offset), PLChar(UInt(NS) + F.Offset)) <> 0;
   else
    begin
     B := False;
     Print(['Delta_MarkSendFields: Bad field type "', F.FieldType and not DT_SIGNED, '".']);
    end;
  end;

  if B then
   Include(F.Flags, ffReady);
 end;

if @Delta.ConditionalEncoder <> nil then
 Delta.ConditionalEncoder(@Delta, OS, NS);
end;

procedure Delta_SetSendFlagBits(const Delta: TDelta; Dest: Pointer; out BytesWritten: UInt);
var
 ID, I: Int;
 P: PUInt32;
begin
MemSet(Dest^, 8, 0);
ID := -1;
for I := Delta.NumFields - 1 downto 0 do
 if ffReady in Delta.Fields[I].Flags then
  begin
   if ID = -1 then
    ID := I;
   P := PUInt32(UInt(Dest) + 4 * UInt(I > 31));
   P^ := P^ or UInt(1 shl (I and 31));
  end;

if ID = -1 then
 BytesWritten := 0
else
 BytesWritten := (UInt(ID) shr 3) + 1;
end;

procedure Delta_WriteMarkedFields(OS, NS: Pointer; const Delta: TDelta);
var
 I: Int;
 F: PDeltaField;
 Signed: Boolean;
 S: PLChar;
begin
for I := 0 to Delta.NumFields - 1 do
 begin
  F := @Delta.Fields[I];
  if ffReady in F.Flags then
   begin
    Signed := (F.FieldType and DT_SIGNED) > 0;
    case F.FieldType and not DT_SIGNED of
     DT_FLOAT:
      if Signed then
       MSG_WriteSBits(Trunc(PSingle(UInt(NS) + F.Offset)^ * F.Scale), F.Bits)
      else
       MSG_WriteBits(Trunc(PSingle(UInt(NS) + F.Offset)^ * F.Scale), F.Bits);
     DT_ANGLE:
      MSG_WriteBitAngle(PSingle(UInt(NS) + F.Offset)^, F.Bits);
     DT_TIMEWINDOW_8:
      MSG_WriteSBits(Trunc(SV.Time * 100) - Trunc(PSingle(UInt(NS) + F.Offset)^ * 100), 8);
     DT_TIMEWINDOW_BIG:
      MSG_WriteSBits(Trunc(SV.Time * F.Scale) - Trunc(PSingle(UInt(NS) + F.Offset)^ * F.Scale), F.Bits);
     DT_BYTE:
      if Signed then
       MSG_WriteSBits(Trunc(PInt8(UInt(NS) + F.Offset)^ * F.Scale) and $FF, F.Bits)
      else
       MSG_WriteBits(Trunc(PUInt8(UInt(NS) + F.Offset)^ * F.Scale) and $FF, F.Bits);
     DT_SHORT:
      if Signed then
       MSG_WriteSBits(Trunc(PInt16(UInt(NS) + F.Offset)^ * F.Scale) and $FFFF, F.Bits)
      else
       MSG_WriteBits(Trunc(PUInt16(UInt(NS) + F.Offset)^ * F.Scale) and $FFFF, F.Bits);
     DT_INTEGER:
      begin
       if Signed then
        if (F.Scale < 0.9999) or (F.Scale > 1.0001) then
         MSG_WriteSBits(Trunc(PInt32(UInt(NS) + F.Offset)^ * F.Scale), F.Bits)
        else
         MSG_WriteSBits(PInt32(UInt(NS) + F.Offset)^, F.Bits)
       else
        if (F.Scale < 0.9999) or (F.Scale > 1.0001) then
         MSG_WriteBits(Trunc(PUInt32(UInt(NS) + F.Offset)^ * F.Scale), F.Bits)
        else
         MSG_WriteBits(PUInt32(UInt(NS) + F.Offset)^, F.Bits)
      end;
     DT_STRING:
      begin
       S := PLChar(UInt(NS) + F.Offset);
       while S^ > #0 do
        begin
         MSG_WriteBits(Byte(S^), 8);
         Inc(UInt(S));
        end;
       MSG_WriteBits(0, 8);
      end;
     else
      Print('Delta_WriteMarkedFields: Unknown send field type.');
    end;
   end;
 end;
end;

function Delta_CheckDelta(OS, NS: Pointer; var Delta: TDelta): UInt;
begin
Delta_ClearFlags(Delta);
Delta_MarkSendFields(OS, NS, Delta);
Result := Delta_CountSendFields(Delta);
end;

function _Delta_WriteDelta(OS, NS: Pointer; ForceUpdate: Boolean; var Delta: TDelta; Func: TProcedure; Fields: UInt): Boolean;
var
 I: Int;
 C: packed array[1..8] of Byte;
begin
if (Fields > 0) or ForceUpdate then
 begin
  Delta_SetSendFlagBits(Delta, @C, Fields);
  if @Func <> nil then
   Func;
  MSG_WriteBits(Fields, 3);
  for I := 1 to Fields do
   MSG_WriteBits(C[I], 8);
  Delta_WriteMarkedFields(OS, NS, Delta);
 end;

Result := True;
end;

function Delta_WriteDelta(OS, NS: Pointer; ForceUpdate: Boolean; var Delta: TDelta; Func: TProcedure): Boolean;
begin
Delta_ClearFlags(Delta);
Delta_MarkSendFields(OS, NS, Delta);
Result := _Delta_WriteDelta(OS, NS, ForceUpdate, Delta, @Func, Delta_CountSendFields(Delta));
end;

function Delta_ParseDelta(OS, NS: Pointer; var Delta: TDelta): Int;
var
 CB, ByteCount, I: UInt;
 C: packed array[1..8] of Byte;
 F: PDeltaField;
 Signed: Boolean;
 CH: LChar;
 P: PLChar;
 FT: UInt32;
begin
CB := MSG_CurrentBit;
MemSet(C, SizeOf(C), 0);
ByteCount := MSG_ReadBits(3);

for I := 1 to ByteCount do
 C[I] := MSG_ReadBits(8);

for I := 0 to Delta.NumFields - 1 do
 begin
  F := @Delta.Fields[I];
  FT := F.FieldType and not DT_SIGNED;
  if (PUInt32(UInt(@C) + 4 * UInt(I > 31))^ and (1 shl (I and 31))) > 0 then
   begin
    Signed := (F.FieldType and DT_SIGNED) > 0;
    Inc(F.RecvCount);
    case FT of
     DT_FLOAT:
      if Signed then
       PSingle(UInt(NS) + F.Offset)^ := MSG_ReadSBits(F.Bits) / F.Scale * F.PScale
      else
       PSingle(UInt(NS) + F.Offset)^ := MSG_ReadBits(F.Bits) / F.Scale * F.PScale;
     DT_ANGLE:
      PSingle(UInt(NS) + F.Offset)^ := MSG_ReadBitAngle(F.Bits);
     DT_TIMEWINDOW_8:
      PSingle(UInt(NS) + F.Offset)^ := (Trunc(SV.Time * 100) - MSG_ReadSBits(8)) * (1 / 100);
     DT_TIMEWINDOW_BIG:
      PSingle(UInt(NS) + F.Offset)^ := (SV.Time * F.Scale - MSG_ReadSBits(F.Bits)) / F.Scale;
     DT_BYTE:
      if Signed then
       PInt8(UInt(NS) + F.Offset)^ := Trunc(Int8(Trunc(Int8(MSG_ReadSBits(F.Bits)) / F.Scale)) * F.PScale)
      else
       PUInt8(UInt(NS) + F.Offset)^ := Trunc(UInt8(Trunc(UInt8(MSG_ReadBits(F.Bits)) / F.Scale)) * F.PScale);
     DT_SHORT:
      if Signed then
       PInt16(UInt(NS) + F.Offset)^ := Trunc(Int16(Trunc(Int16(MSG_ReadSBits(F.Bits)) / F.Scale)) * F.PScale)
      else
       PUInt16(UInt(NS) + F.Offset)^ := Trunc(UInt16(Trunc(UInt16(MSG_ReadBits(F.Bits)) / F.Scale)) * F.PScale);
     DT_INTEGER:
      if Signed then
       PInt32(UInt(NS) + F.Offset)^ := Trunc(Int32(Trunc(Int32(MSG_ReadSBits(F.Bits)) / F.Scale)) * F.PScale)
      else
       PUInt32(UInt(NS) + F.Offset)^ := Trunc(UInt32(Trunc(UInt32(MSG_ReadBits(F.Bits)) / F.Scale)) * F.PScale);
     DT_STRING:
      begin
       P := PLChar(UInt(NS) + F.Offset);
       repeat
        CH := LChar(MSG_ReadBits(8));
        P^ := CH;
        Inc(UInt(P));
       until CH = #0;
      end;
     else
      Print(['Delta_ParseDelta: Unparseable field type "', FT, '".']);
    end;
   end
  else
   case FT of
    DT_FLOAT, DT_INTEGER, DT_ANGLE, DT_TIMEWINDOW_8, DT_TIMEWINDOW_BIG:
     PUInt32(UInt(NS) + F.Offset)^ := PUInt32(UInt(OS) + F.Offset)^;
    DT_BYTE:
     PUInt8(UInt(NS) + F.Offset)^ := PUInt8(UInt(OS) + F.Offset)^;
    DT_SHORT:
     PUInt16(UInt(NS) + F.Offset)^ := PUInt16(UInt(OS) + F.Offset)^;
    DT_STRING:
     StrCopy(PLChar(UInt(NS) + F.Offset), PLChar(UInt(OS) + F.Offset));
    else
     Print(['Delta_ParseDelta: Unparseable field type "', FT, '".']);
   end;
 end;

Result := MSG_CurrentBit - CB;
end;

procedure Delta_AddEncoder(Name: PLChar; Func: TDeltaEncoder);
var
 P: PDeltaEncoderEntry;
begin
P := Mem_Alloc(SizeOf(P^));
P.Prev := EncoderList;
P.Name := Mem_StrDup(Name);
P.Func := @Func;
EncoderList := P;
end;

procedure Delta_ClearEncoders;
var
 P, P2: PDeltaEncoderEntry;
begin
P := EncoderList;
while P <> nil do
 begin
  P2 := P.Prev;
  Mem_Free(P.Name);
  Mem_Free(P);
  P := P2;
 end;

EncoderList := nil;
end;

function Delta_LookupEncoder(Name: PLChar): TDeltaEncoder;
var
 P: PDeltaEncoderEntry;
begin
P := EncoderList;
while P <> nil do
 if StrIComp(P.Name, Name) = 0 then
  begin
   Result := @P.Func;
   Exit;
  end
 else
  P := P.Prev;

Result := nil;
end;

function Delta_CountLinks(P: PDeltaLinkedField): UInt;
begin
Result := 0;

while P <> nil do
 begin
  P := P.Prev;
  Inc(Result);
 end;
end;

procedure Delta_ReverseLinks(var P: PDeltaLinkedField);
var
 L, P2, P3: PDeltaLinkedField;
begin
L := nil;
P2 := P;
while P2 <> nil do
 begin
  P3 := P2.Prev;
  P2.Prev := L;
  L := P2;
  P2 := P3;
 end;

P := L;
end;

procedure Delta_ClearLinks(var P: PDeltaLinkedField);
var
 P2, P3: PDeltaLinkedField;
begin
P2 := P;
while P2 <> nil do
 begin
  P3 := P2.Prev;
  Mem_Free(P2);
  P2 := P3;
 end;

P := nil;
end;

function Delta_BuildFromLinks(var LF: PDeltaLinkedField): PDelta;
var
 D: PDelta;
 I: Int;
 P: PDeltaLinkedField;
begin
D := Mem_ZeroAlloc(SizeOf(D^));
Delta_ReverseLinks(LF);
D.NumFields := Delta_CountLinks(LF);
D.Fields := Mem_ZeroAlloc(SizeOf(TDeltaField) * D.NumFields);

P := LF;
for I := 0 to D.NumFields - 1 do
 begin
  if P = nil then
   Sys_Error('Delta_BuildFromLinks: Internal assertion failure.');

  Move(P.Field^, D.Fields[I], SizeOf(TDeltaField));
  Mem_Free(P.Field);
  P.Field := nil;
  P := P.Prev;
 end;

Delta_ClearLinks(LF);
D.Active := True;
Result := D;
end;

function Delta_FindOffset(Count: UInt; Base: PDeltaOffsetArray; Name: PLChar): UInt32;
var
 I: Int;
begin
for I := 0 to Count - 1 do
 if StrIComp(Name, Base[I].Name) = 0 then
  begin
   Result := Base[I].Offset;
   Exit;
  end;

Sys_Error(['Delta_FindOffset: Couldn''t find offset for "', Name, '".']);
Result := 0;
end;

function Delta_ParseType(var FieldType: UInt32; var F: Pointer): Boolean;
begin
while True do
 begin
  repeat
   F := COM_Parse(F);
   if COM_Token[Low(COM_Token)] = #0 then
    begin
     Print('Delta_ParseType: Expecting fieldtype info.');
     Result := False;
     Exit;
    end;
  until StrComp(@COM_Token, '|') <> 0;

  if StrComp(@COM_Token, ',') = 0 then
   Break;

  if StrIComp(@COM_Token, 'DT_SIGNED') = 0 then
   FieldType := FieldType or UInt32(DT_SIGNED)
  else
   if StrIComp(@COM_Token, 'DT_BYTE') = 0 then
    FieldType := FieldType or DT_BYTE
   else
    if StrIComp(@COM_Token, 'DT_SHORT') = 0 then
     FieldType := FieldType or DT_SHORT
    else
     if StrIComp(@COM_Token, 'DT_FLOAT') = 0 then
      FieldType := FieldType or DT_FLOAT
     else
      if StrIComp(@COM_Token, 'DT_INTEGER') = 0 then
       FieldType := FieldType or DT_INTEGER
      else
       if StrIComp(@COM_Token, 'DT_ANGLE') = 0 then
        FieldType := FieldType or DT_ANGLE
       else
        if StrIComp(@COM_Token, 'DT_TIMEWINDOW_8') = 0 then
         FieldType := FieldType or DT_TIMEWINDOW_8
        else
         if StrIComp(@COM_Token, 'DT_TIMEWINDOW_BIG') = 0 then
          FieldType := FieldType or DT_TIMEWINDOW_BIG
         else
          if StrIComp(@COM_Token, 'DT_STRING') = 0 then
           FieldType := FieldType or DT_STRING
          else
           Sys_Error(['Delta_ParseField: Unknown type or type flag "', PLChar(@COM_Token), '".']);
 end;

Result := True;
end;

function Delta_ParseField(Count: UInt; Base: PDeltaOffsetArray; LF: PDeltaLinkedField; var F: Pointer): Boolean;
var
 Post: Boolean;
 DF: PDeltaField;
begin
if StrIComp(@COM_Token, 'DEFINE_DELTA') <> 0 then
 begin
  if StrIComp(@COM_Token, 'DEFINE_DELTA_POST') <> 0 then
   Sys_Error(['Delta_ParseField: Expecting DEFINE_*, got "', PLChar(@COM_Token), '".']);
  Post := True;
 end
else
 Post := False;

F := COM_Parse(F);
if StrComp(@COM_Token, '(') <> 0 then
 Sys_Error(['Delta_ParseField: Expecting "(", got "', PLChar(@COM_Token), '".']);

F := COM_Parse(F);
if COM_Token[Low(COM_Token)] = #0 then
 Sys_Error('Delta_ParseField: Expecting fieldname.');
 
DF := LF.Field;
StrLCopy(@DF.Name, @COM_Token, SizeOf(DF.Name) - 1);
DF.Offset := Delta_FindOffset(Count, Base, @COM_Token);

F := COM_Parse(F);
if Delta_ParseType(DF.FieldType, F) then
 begin
  F := COM_Parse(F);
  DF.Parsed := 1;
  DF.Bits := StrToInt(@COM_Token);
  F := COM_Parse(F);
  F := COM_Parse(F);
  DF.Scale := StrToFloatDef(PLChar(@COM_Token), 0);
  if Post then
   begin
    F := COM_Parse(F);
    F := COM_Parse(F);
    DF.PScale := StrToFloatDef(PLChar(@COM_Token), 0);
   end
  else
   DF.PScale := 1;

  F := COM_Parse(F);
  if StrComp(@COM_Token, ')') <> 0 then
   Sys_Error(['Delta_ParseField: Expecting ")", got "', PLChar(@COM_Token), '".'])
  else
   begin
    F := COM_Parse(F);
    if StrComp(@COM_Token, ',') <> 0 then
     COM_UngetToken;
   end;

  Result := True;
 end
else
 Result := False;
end;

procedure Delta_FreeDescription(var D: PDelta);
begin
if (@D <> nil) and (D <> nil) then
 begin
  if D.Active and (D.Fields <> nil) then
   Mem_Free(D.Fields);
  Mem_Free(D);
  D := nil;
 end;
end;

procedure Delta_AddDefinition(Name: PLChar; Data: PDeltaOffsetArray; Count: UInt);
var
 D: PDeltaDefinition;
begin
D := DefList;
while (D <> nil) and (StrIComp(Name, D.Name) <> 0) do
 D := D.Prev;

if D = nil then
 begin
  D := Mem_ZeroAlloc(SizeOf(D^));
  D.Prev := DefList;
  D.Name := Mem_StrDup(Name);
  DefList := D;
 end;

D.Count := Count;
D.Offsets := Data;
end;

procedure Delta_ClearDefinitions;
var
 P, P2: PDeltaDefinition;
begin
P := DefList;
while P <> nil do
 begin
  P2 := P.Prev;
  Mem_Free(P.Name);
  Mem_Free(P);
  P := P2;
 end;

DefList := nil;
end;

function Delta_FindDefinition(Name: PLChar; out Count: UInt32): PDeltaOffsetArray;
var
 P: PDeltaDefinition;
begin
P := DefList;
while P <> nil do
 if StrIComp(Name, P.Name) = 0 then
  begin
   Result := P.Offsets;
   Count := P.Count;
   Exit;
  end
 else
  P := P.Prev;

Result := nil;
Count := 0;
end;

procedure Delta_SkipDescription(var F: Pointer);
begin
F := COM_Parse(F);
repeat
 F := COM_Parse(F);
 if COM_Token[Low(COM_Token)] = #0 then
  Sys_Error('Delta_SkipDescription: Error during description skip.');
until StrComp(@COM_Token, '}') = 0;
end;

function Delta_ParseOneField(var F: Pointer; out LinkBase: PDeltaLinkedField; Count: UInt; Base: PDeltaOffsetArray): Boolean;
var
 X: TDeltaLinkedField;
 P: PDeltaLinkedField;
begin
Result := True;

while True do
 begin
  if StrComp(@COM_Token, '}') = 0 then
   begin
    COM_UngetToken;
    Exit;
   end;

  F := COM_Parse(F);
  if COM_Token[Low(COM_Token)] = #0 then
   Exit;
  
  X.Prev := nil;
  X.Field := Mem_ZeroAlloc(SizeOf(X.Field^));
  if not Delta_ParseField(Count, Base, @X, F) then
   Break;

  P := Mem_ZeroAlloc(SizeOf(P^));
  P.Field := X.Field;
  P.Prev := LinkBase;
  LinkBase := P;
 end;

Result := False;
end;

function Delta_ParseDescription(Name: PLChar; var Delta: PDelta; F: Pointer): Boolean;
var
 Def: PDeltaOffsetArray;
 DefCount: UInt32;
 LinkBase: PDeltaLinkedField;
 S: array[1..32] of LChar;
begin
LinkBase := nil;

if @Delta = nil then
 Sys_Error('Delta_ParseDescription: Invalid description.');

Delta := nil;
if F = nil then
 Sys_Error('Delta_ParseDescription called with no data stream.');

while True do
 begin
  F := COM_Parse(F);
  if COM_Token[Low(COM_Token)] = #0 then
   Break
  else
   if StrIComp(@COM_Token, Name) <> 0 then
    Delta_SkipDescription(F)
   else
    begin
     Def := Delta_FindDefinition(@COM_Token, DefCount);
     if Def = nil then
      Sys_Error(['Delta_ParseDescription: Unknown data type - "', PLChar(@COM_Token), '".']);

     F := COM_Parse(F);
     if COM_Token[Low(COM_Token)] = #0 then
      Sys_Error('Delta_ParseDescription: Unknown encoder. Valid values are:' + LineBreak +
                'none,' + LineBreak + 'gamedll funcname,' + LineBreak + 'clientdll funcname')
     else
      if StrIComp(@COM_Token, 'none') <> 0 then
       begin
        F := COM_Parse(F);
        if COM_Token[Low(COM_Token)] = #0 then
         Sys_Error('Delta_ParseDescription: Expecting encoder.');

        StrLCopy(@S, @COM_Token, SizeOf(S) - 1);
       end;

     while True do
      begin
       F := COM_Parse(F);
       if (COM_Token[Low(COM_Token)] = #0) or (StrComp(@COM_Token, '}') = 0) then
        Break
       else
        if StrComp(@COM_Token, '{') <> 0 then
         begin
          Print(['Delta_ParseDescription: Expecting "{", got "', PLChar(@COM_Token), '".']);
          Result := False;
          Exit;
         end
        else
         if not Delta_ParseOneField(F, LinkBase, DefCount, Def) then
          begin
           Result := False;
           Exit;
          end;
      end;
    end;
 end;

Delta := Delta_BuildFromLinks(LinkBase);
if StrLen(@S) > 0 then
 begin
  StrLCopy(@Delta.Name, @S, SizeOf(S) - 1);
  Delta.ConditionalEncoder := nil;
 end;

Result := True;
end;

function Delta_Load(Name: PLChar; var Delta: PDelta; FileName: PLChar): Boolean;
var
 P: Pointer;
begin
P := COM_LoadFile(FileName, FILE_ALLOC_MEMORY, nil);
if P = nil then
 begin
  Sys_Error(['Delta_Load: Couldn''t load file "', FileName, '".']);
  Result := False;
 end
else
 begin
  Result := Delta_ParseDescription(Name, Delta, P);
  COM_FreeFile(P);
 end;
end;

procedure Delta_RegisterDescription(Name: PLChar);
var
 P: PDeltaRegistry;
begin
P := Mem_ZeroAlloc(SizeOf(P^));
P.Prev := RegList;
RegList := P;
P.Name := Mem_StrDup(Name);
P.Delta := nil;
end;

procedure Delta_ClearRegistrations;
var
 P, P2: PDeltaRegistry;
begin
P := RegList;
while P <> nil do
 begin
  P2 := P.Prev;
  Mem_Free(P.Name);
  if P.Delta <> nil then
   Delta_FreeDescription(P.Delta);
  Mem_Free(P);
  P := P2;
 end;

RegList := nil;
end;

function Delta_LookupRegistration(Name: PLChar): PDelta;
var
 P: PDeltaRegistry;
begin
P := RegList;
while P <> nil do
 if StrComp(Name, P.Name) = 0 then
  begin
   Result := P.Delta;
   Exit;
  end
 else
  P := P.Prev;

Result := nil;
end; 

procedure Delta_ClearStats(D: PDelta);
var
 I: Int;
begin
if D <> nil then
 for I := 0 to D.NumFields - 1 do
  begin
   D.Fields[I].SendCount := 0;
   D.Fields[I].RecvCount := 0;
  end;
end;

procedure Delta_ClearStats_f; cdecl;
var
 P: PDeltaRegistry;
begin
Print('Clearing delta stats...');
P := RegList;
while P <> nil do
 begin
  Delta_ClearStats(P.Delta);
  P := P.Prev;
 end;
Print('Done.');
end;

procedure Delta_PrintStats(Name: PLChar; D: PDelta);
var
 I: Int;
 F: PDeltaField;
begin
if D <> nil then
 begin
  Print(['Stats for "', Name, '":']);
  for I := 0 to D.NumFields - 1 do
   begin
    F := @D.Fields[I];
    Print(['#', I + 1, ' (', PLChar(@F.Name), '): send ', F.SendCount, ' recv ', F.RecvCount]); 
   end;
  Print('');
 end;
end;

procedure Delta_DumpStats_f; cdecl;
var
 P: PDeltaRegistry;
begin
Print('Delta stats:');
P := RegList;
while P <> nil do
 begin
  Delta_PrintStats(P.Name, P.Delta);
  P := P.Prev;
 end;
end;

procedure Delta_Init;
begin
Cmd_AddCommand('delta_stats', @Delta_DumpStats_f);
Cmd_AddCommand('delta_clear', @Delta_ClearStats_f);
Delta_AddDefinition('clientdata_t', @DT_ClientData_T, High(DT_ClientData_T));
Delta_AddDefinition('weapon_data_t', @DT_WeaponData_T, High(DT_WeaponData_T));
Delta_AddDefinition('usercmd_t', @DT_UserCmd_T, High(DT_UserCmd_T));
Delta_AddDefinition('entity_state_t', @DT_EntityState_T, High(DT_EntityState_T));
Delta_AddDefinition('entity_state_player_t', @DT_EntityState_T, High(DT_EntityState_T));
Delta_AddDefinition('custom_entity_state_t', @DT_EntityState_T, High(DT_EntityState_T));
Delta_AddDefinition('event_t', @DT_Event_T, High(DT_Event_T));
end;

procedure Delta_Shutdown;
begin
Delta_ClearEncoders;
Delta_ClearDefinitions;
Delta_ClearRegistrations;
end;

end.
