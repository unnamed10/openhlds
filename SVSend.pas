unit SVSend;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SV_LinkNewUserMsgs;

procedure SV_StartParticle(const Origin, Direction: TVec3; Color, Count: UInt);
procedure SV_StartSound(SkipSelf: Boolean; const E: TEdict; Channel: Int; Sample: PLChar; Volume: Int; Attn: Single; Flags: UInt; Pitch: Int);
function SV_BuildSoundMsg(const E: TEdict; Channel: Int; Sample: PLChar; Volume: Int; Attn: Single; Flags: UInt; Pitch: Int; const Origin: TVec3; var SB: TSizeBuf): Boolean;
function SV_HashString(S: PLChar; Entries: UInt): UInt32;
function SV_LookupSoundIndex(Name: PLChar): UInt;
procedure SV_BuildHashedSoundLookupTable;
procedure SV_AddSampleToHashedLookupTable(S: PLChar; Data: UInt);

function SV_ValidClientMulticast(const C: TClient; Leaf, Flags: UInt): Boolean;
procedure SV_Multicast(const E: TEdict; const Origin: TVec3; Flags: UInt; Reliable: Boolean);

procedure SV_SendBan;

var
 UserMsgs, NewUserMsgs: PUserMsg;
 NextUserMsg: UInt = 64;
 
implementation

uses Common, Console, Edict, Host, Memory, Model, MsgBuf, Network, Server, SysMain, SVMove, SVWorld;

var
 HashStringCollisions: UInt = 0;
 PacketSuppressed: UInt = 0;

procedure SV_LinkNewUserMsgs;
var
 P: ^PUserMsg;
begin
if NewUserMsgs <> nil then
 begin
  P := @UserMsgs;
  while P^ <> nil do
   P := @(P^).Prev;

  P^ := NewUserMsgs;
  NewUserMsgs := nil;
 end;
end;

procedure SV_StartParticle(const Origin, Direction: TVec3; Color, Count: UInt);
var
 I: UInt;
 J: Int;
begin
if SV.Datagram.CurrentSize > MAX_DATAGRAM - 16 then
 Exit;

MSG_WriteByte(SV.Datagram, SVC_PARTICLE);
for I := 0 to 2 do
 MSG_WriteCoord(SV.Datagram, Origin[I]);

for I := 0 to 2 do
 begin
  J := Trunc(Direction[I] * 16);
  if J > 127 then
   J := 127
  else
   if J < -128 then
    J := -128;

  MSG_WriteByte(SV.Datagram, J);
 end;

MSG_WriteByte(SV.Datagram, Count);
MSG_WriteByte(SV.Datagram, Color);
end;

procedure SV_StartSound(SkipSelf: Boolean; const E: TEdict; Channel: Int; Sample: PLChar; Volume: Int; Attn: Single; Flags: UInt; Pitch: Int);
var
 I, MFlags: UInt;
 V: TVec3;
begin
for I := 0 to 2 do
 V[I] := E.V.Origin[I] + 0.5 * (E.V.MinS[I] + E.V.MaxS[I]);

if SV_BuildSoundMsg(E, Channel, Sample, Volume, Attn, Flags, Pitch, V, SV.Multicast) then
 begin
  if SkipSelf then
   MFlags := MULTICAST_SKIP_SENDER
  else
   MFlags := 0;

  if (Channel <> CHAN_STATIC) and ((Flags and SND_STOP) = 0) then
   SV_Multicast(E, V, MFlags or MULTICAST_PAS, False)
  else
   SV_Multicast(E, V, MFlags or MULTICAST_ALL, not Host_IsSinglePlayerGame);
 end;
end;

function SV_BuildSoundMsg(const E: TEdict; Channel: Int; Sample: PLChar; Volume: Int; Attn: Single; Flags: UInt; Pitch: Int; const Origin: TVec3; var SB: TSizeBuf): Boolean;
var
 Index: UInt;
begin
Result := False;

if (Volume < 0) or (Volume > 255) then
 Sys_Error(['SV_BuildSoundMsg: Volume = ', Volume, '.'])
else
 if (Attn < 0) or (Attn > 4) then
  Sys_Error(['SV_BuildSoundMsg: Attenuation = ', Attn, '.'])
 else
  if (Channel < 0) or (Channel > 7) then
   Sys_Error(['SV_BuildSoundMsg: Channel = ', Channel, '.'])
  else
   if (Pitch < 0) or (Pitch > 255) then
    Sys_Error(['SV_BuildSoundMsg: Pitch = ', Pitch, '.'])
   else
    if Sample = nil then
     Exit;

if Sample^ = '!' then
 begin
  Flags := Flags or SND_SENTENCE;
  Index := StrToIntDef(PLChar(UInt(Sample) + 1), CVOXFILESENTENCEMAX);
  if Index >= CVOXFILESENTENCEMAX then
   begin
    Print(['Invalid sentence number: ', PLChar(UInt(Sample) + 1), '.']);
    Exit;
   end;
 end
else
 if Sample^ = '#' then
  begin
   Flags := Flags or SND_SENTENCE;
   Index := StrToInt(PLChar(UInt(Sample) + 1)) + CVOXFILESENTENCEMAX;
  end
 else
  begin
   Index := SV_LookupSoundIndex(Sample);
   if (Index = 0) or (SV.PrecachedSoundNames[Index] = nil) then
    begin
     Print(['SV_StartSound: "', Sample, '" is not precached.']);
     Exit;
    end; 
  end;

if Volume <> 255 then
 Flags := Flags or SND_VOLUME;
if Attn <> 1 then
 Flags := Flags or SND_ATTN;
if Pitch <> 100 then
 Flags := Flags or SND_PITCH;
if Index > 255 then
 Flags := Flags or SND_LONG_INDEX;

MSG_WriteByte(SB, SVC_SOUND);
MSG_StartBitWriting(SB);
MSG_WriteBits(Flags, 9);
if (Flags and SND_VOLUME) > 0 then
 MSG_WriteBits(Volume, 8);
if (Flags and SND_ATTN) > 0 then
 MSG_WriteBits(Trunc(Attn * 64), 8);

MSG_WriteBits(Channel, 3);
MSG_WriteBits(NUM_FOR_EDICT(E), 11);
if Index <= 255 then
 MSG_WriteBits(Index, 8)
else
 MSG_WriteBits(Index, 16);
MSG_WriteBitVec3Coord(Origin);
if (Flags and SND_PITCH) > 0 then
 MSG_WriteBits(Pitch, 8);
MSG_EndBitWriting;
Result := True;
end;

function SV_HashString(S: PLChar; Entries: UInt): UInt32;
begin
Result := 0;
while S^ > #0 do
 begin
  Result := (Result shl 1) + Ord(LowerC(S^));
  Inc(UInt(S));
 end;

Result := Result mod Entries;
end;

{function SV_LookupSoundIndex(Name: PLChar): UInt;
var
 Hash, Entry: UInt32;
 I: UInt;
 S: PLChar;
begin
Hash := SV_HashString(Name, MAX_SOUNDHASH);
Entry := Hash;
Result := 0;

if not SV.SoundTableReady then
 if SV.State = SS_LOADING then
  begin
   for I := 1 to MAX_SOUNDS - 1 do
    begin
     S := SV.PrecachedSoundNames[I];
     if S = nil then
      Break
     else
      if StrIComp(Name, S) = 0 then
       begin
        Result := I;
        Exit;
       end;
    end;
   Exit;
  end
 else
  SV_BuildHashedSoundLookupTable;

while SV.SoundHashTable[Entry] > 0 do
 begin
  if StrIComp(Name, SV.PrecachedSoundNames[SV.SoundHashTable[Entry]]) = 0 then
   begin
    Result := SV.SoundHashTable[Entry];
    Exit;
   end;
  
  Inc(Entry);
  if Entry >= MAX_SOUNDHASH then
   Entry := 0;
  if Entry = Hash then
   Break;
 end;
end;       }

function SV_LookupSoundIndex(Name: PLChar): UInt;
var
 I: UInt;
 S: PLChar;
begin
for I := 1 to MAX_SOUNDS - 1 do
 begin
  S := SV.PrecachedSoundNames[I];
  if S = nil then
   Break
  else
   if StrIComp(Name, S) = 0 then
    begin
     Result := I;
     Exit;
    end;
 end;

Result := 0;
end;

procedure SV_BuildHashedSoundLookupTable;
var
 I: UInt;
 S: PLChar;
begin
MemSet(SV.SoundHashTable, SizeOf(SV.SoundHashTable), 0);
for I := 0 to MAX_SOUNDS - 1 do
 begin
  S := SV.PrecachedSoundNames[I];
  if S = nil then
   Break
  else
   SV_AddSampleToHashedLookupTable(S, I);
 end;

SV.SoundTableReady := True;
end;

procedure SV_AddSampleToHashedLookupTable(S: PLChar; Data: UInt);
var
 Hash, Entry: UInt32;
begin
Hash := SV_HashString(S, MAX_SOUNDHASH);
Entry := Hash;

while SV.SoundHashTable[Entry] > 0 do
 begin
  Inc(Entry);
  Inc(HashStringCollisions);
  if Entry >= MAX_SOUNDHASH then
   Entry := 0;

  if Entry = Hash then
   Sys_Error('SV_AddSampleToHashedLookupTable: No free slots in sound lookup table.');
 end;

SV.SoundHashTable[Entry] := Data;
end;

function SV_ValidClientMulticast(const C: TClient; Leaf, Flags: UInt): Boolean;
var
 P: Pointer;
 I: UInt;
begin
Flags := Flags and not MULTICAST_SKIP_SENDER;

if Host_IsSinglePlayerGame or C.HLTV or ((Flags and MULTICAST_ALL) > 0) then
 Result := True
else
 begin
  if (Flags and MULTICAST_PVS) > 0 then
   P := CM_LeafPVS(Leaf)
  else
   if (Flags and MULTICAST_PAS) > 0 then
    P := CM_LeafPAS(Leaf)
   else
    begin
     Print(['SV_ValidClientMulticast: Invalid multicast flags: ', Flags, '.']);
     Result := False;
     Exit; 
    end;

  if P = nil then
   Result := True
  else
   begin
    I := SV_PointLeafnum(C.Entity.V.Origin);
    if I = 0 then
     Result := True
    else
     Result := ((1 shl ((I - 1) and 7)) and PByte(UInt(P) + ((I - 1) shr 3))^) > 0;
   end;
 end;
end;

procedure SV_Multicast(const E: TEdict; const Origin: TVec3; Flags: UInt; Reliable: Boolean);
var
 OrigClient, P: PClient;
 LeafNum: UInt;
 I: Int;
 SB: PSizeBuf;
begin
OrigClient := HostClient;
LeafNum := SV_PointLeafnum(Origin);
if (@E <> nil) and ((HostClient = nil) or (HostClient.Entity <> @E)) then
 for I := 0 to SVS.MaxClients - 1 do
  if SVS.Clients[I].Entity = @E then
   begin
    HostClient := @SVS.Clients[I];
    Break;
   end;

for I := 0 to SVS.MaxClients - 1 do
 begin
  P := @SVS.Clients[I];
  if P.Active and (((Flags and MULTICAST_SKIP_SENDER) = 0) or (P <> HostClient)) then
   begin
    if (@E <> nil) and (P.Entity <> nil) and FilterGroup(E, P.Entity^) then
     Continue;

    if SV_ValidClientMulticast(P^, LeafNum, Flags) then
     begin
      if Reliable then
       SB := @P.Netchan.NetMessage
      else
       SB := @P.UnreliableMessage;

      if SB.MaxSize - SB.CurrentSize > SV.Multicast.CurrentSize then
       SZ_Write(SB^, SV.Multicast.Data, SV.Multicast.CurrentSize);
     end
    else
     Inc(PacketSuppressed, SV.Multicast.CurrentSize);
   end;
 end;

SZ_Clear(SV.Multicast);
HostClient := OrigClient;
end;

procedure SV_SendBan;
begin
SZ_Clear(NetMessage);
MSG_WriteLong(NetMessage, OUTOFBAND_TAG);
MSG_WriteChar(NetMessage, S2C_PRINT);
MSG_WriteString(NetMessage, 'You have been banned from this server.'#10);
NET_SendPacket(NS_SERVER, NetMessage.CurrentSize, NetMessage.Data, NetFrom);
SZ_Clear(NetMessage);
end;

end.
