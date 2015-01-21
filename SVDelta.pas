unit SVDelta;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SV_InitDeltas;
procedure SV_InitEncoders;

procedure SV_ShutdownDeltas;

procedure SV_WriteDeltaDescriptionsToClient(var SB: TSizeBuf);

procedure SV_ParseDelta(var C: TClient);

var
 PlayerDelta, EntityDelta, CustomEntityDelta, ClientDelta, WeaponDelta, EventDelta, UserCmdDelta: PDelta;

implementation

uses Console, Delta, Host, Memory, MsgBuf, Server, SysMain;

const
 MetaDeltaDescription: array[1..7] of TDeltaField =
  ((FieldType: DT_INTEGER; Name: ('f', 'i', 'e', 'l', 'd', 'T', 'y', 'p', 'e', #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
    Offset: 0; Parsed: 1; Bits: 32; Scale: 1; PScale: 1; Flags: []; SendCount: 0; RecvCount: 0),
   (FieldType: DT_STRING;  Name: ('f', 'i', 'e', 'l', 'd', 'N', 'a', 'm', 'e', #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
    Offset: 4; Parsed: 1; Bits: 1; Scale: 1; PScale: 1; Flags: []; SendCount: 0; RecvCount: 0),
   (FieldType: DT_INTEGER; Name: ('f', 'i', 'e', 'l', 'd', 'O', 'f', 'f', 's', 'e', 't', #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
    Offset: 36; Parsed: 1; Bits: 16; Scale: 1; PScale: 1; Flags: []; SendCount: 0; RecvCount: 0),
   (FieldType: DT_INTEGER; Name: ('f', 'i', 'e', 'l', 'd', 'S', 'i', 'z', 'e', #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
    Offset: 40; Parsed: 1; Bits: 8; Scale: 1; PScale: 1; Flags: []; SendCount: 0; RecvCount: 0),
   (FieldType: DT_INTEGER; Name: ('s', 'i', 'g', 'n', 'i', 'f', 'i', 'c', 'a', 'n', 't', '_', 'b', 'i', 't', 's', #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
    Offset: 44; Parsed: 1; Bits: 8; Scale: 1; PScale: 1; Flags: []; SendCount: 0; RecvCount: 0),
   (FieldType: DT_FLOAT;   Name: ('p', 'r', 'e', 'm', 'u', 'l', 't', 'i', 'p', 'l', 'y', #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
    Offset: 48; Parsed: 1; Bits: 32; Scale: 4000; PScale: 1; Flags: []; SendCount: 0; RecvCount: 0),
   (FieldType: DT_FLOAT;   Name: ('p', 'o', 's', 't', 'm', 'u', 'l', 't', 'i', 'p', 'l', 'y', #0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,#0);
    Offset: 52; Parsed: 1; Bits: 32; Scale: 4000; PScale: 1; Flags: []; SendCount: 0; RecvCount: 0));

 MetaDeltaDefinition: array[1..8] of TDeltaOffset =
 ((Name: 'fieldType'; Offset: 0),
  (Name: 'fieldName'; Offset: 4),
  (Name: 'fieldOffset'; Offset: 36),
  (Name: 'fieldSize'; Offset: 40),
  (Name: 'significant_bits'; Offset: 44),
  (Name: 'premultiply'; Offset: 48),
  (Name: 'postmultiply'; Offset: 52),
  (Name: 'flags'; Offset: 56));

var
 MetaDelta: TDelta = (Active: False; NumFields: 7; ConditionalEncoder: nil; Fields: @MetaDeltaDescription);

var
 SVDeltaList: PServerDelta = nil;

function SV_LookupDelta(Name: PLChar): PDelta;
var
 P: PServerDelta;
begin
P := SVDeltaList;
while P <> nil do
 if StrIComp(P.Name, Name) = 0 then
  begin
   Result := P.Delta;
   Exit;
  end
 else
  P := P.Prev;

Sys_Error(['SV_LookupDelta: Couldn''t find delta for "', Name, '".']); 
Result := nil;
end;

procedure SV_RegisterDelta(Name, FileName: PLChar);
var
 D: PDelta;
 P: PServerDelta;
begin
if not Delta_Load(Name, D, FileName) then
 Sys_Error(['SV_RegisterDelta: Error parsing "', Name, '" in "', FileName, '".']);

P := Mem_Alloc(SizeOf(P^));
P.Prev := SVDeltaList;
P.Name := Mem_StrDup(Name);
P.FileName := Mem_StrDup(FileName);
P.Delta := D;

SVDeltaList := P;
end;

procedure SV_InitDeltas;
begin                            
DPrint('Initializing deltas.');
SV_RegisterDelta('clientdata_t', 'delta.lst');
SV_RegisterDelta('entity_state_t', 'delta.lst');
SV_RegisterDelta('entity_state_player_t', 'delta.lst');
SV_RegisterDelta('custom_entity_state_t', 'delta.lst');
SV_RegisterDelta('usercmd_t', 'delta.lst');
SV_RegisterDelta('weapon_data_t', 'delta.lst');
SV_RegisterDelta('event_t', 'delta.lst');

ClientDelta := SV_LookupDelta('clientdata_t');
EntityDelta := SV_LookupDelta('entity_state_t');
PlayerDelta := SV_LookupDelta('entity_state_player_t');
CustomEntityDelta := SV_LookupDelta('custom_entity_state_t');
UserCmdDelta := SV_LookupDelta('usercmd_t');
WeaponDelta := SV_LookupDelta('weapon_data_t');
EventDelta := SV_LookupDelta('event_t');
end;

procedure SV_InitEncoders;
var
 P: PServerDelta;
 D: PDelta;
begin
P := SVDeltaList;
while P <> nil do
 begin
  D := P.Delta;
  if D.Name[Low(D.Name)] > #0 then
   D.ConditionalEncoder := Delta_LookupEncoder(@D.Name);

  P := P.Prev;
 end;
end;

procedure SV_ShutdownDeltas;
var
 P, P2: PServerDelta;
begin
P := SVDeltaList;
while P <> nil do
 begin
  P2 := P.Prev;
  if P.Delta <> nil then
   Delta_FreeDescription(P.Delta);

  Mem_Free(P.Name);
  Mem_Free(P.FileName);
  Mem_Free(P);
  P := P2;
 end;

SVDeltaList := nil;
end;

procedure SV_WriteDeltaDescriptionsToClient(var SB: TSizeBuf);
var
 OS: TDeltaField;
 P: PServerDelta;
 I: Int;
begin
MemSet(OS, SizeOf(OS), 0);
P := SVDeltaList;
while P <> nil do
 begin
  MSG_WriteByte(SB, SVC_DELTADESCRIPTION);
  MSG_WriteString(SB, P.Name);
  MSG_StartBitWriting(SB);
  MSG_WriteBits(P.Delta.NumFields, 16);
  for I := 0 to P.Delta.NumFields - 1 do
   Delta_WriteDelta(@OS, @P.Delta.Fields[I], True, MetaDelta, nil);
  MSG_EndBitWriting;

  P := P.Prev;
 end;
end;

procedure SV_ParseDelta(var C: TClient);
begin
C.UpdateMask := MSG_ReadByte;
if MSG_BadRead then
 C.UpdateMask := -1;
end;

end.
