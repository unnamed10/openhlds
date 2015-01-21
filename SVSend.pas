unit SVSend;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SV_LinkNewUserMsgs;

procedure SV_StartParticle(const Origin, Direction: TVec3; Color, Count: UInt);
procedure SV_StartSound(SkipSelf: Boolean; const E: TEdict; Channel: Int; Sample: PLChar; Volume: Int; Attn: Single; Flags: UInt; Pitch: Int);
function SV_BuildSoundMsg(const E: TEdict; Channel: Int; Sample: PLChar; Volume: Int; Attn: Single; Flags: UInt; Pitch: Int; const Origin: TVec3; var SB: TSizeBuf): Boolean;
function SV_LookupSoundIndex(Name: PLChar): UInt;

function SV_ValidClientMulticast(const C: TClient; Leaf, Flags: UInt): Boolean;
procedure SV_Multicast(const E: TEdict; const Origin: TVec3; Flags: UInt; Reliable: Boolean);

var
 UserMsgs, NewUserMsgs: PUserMsg;
 NextUserMsg: UInt = 64;
 
implementation

uses Common, Console, Edict, Host, Memory, Model, MsgBuf, Network, Server, SysMain, SVMove, SVWorld;

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
if SV.Datagram.CurrentSize > SV.Datagram.MaxSize - 16 then
 begin
  DPrint('SV_StartParticle call ignored, would overflow.');
  Exit;
 end;

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
   MFlags := MULTICAST_SKIP_SELF
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

Flags := Flags and not (SND_VOLUME or SND_ATTN or SND_PITCH or SND_LONG_INDEX);
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
if (Flags and SND_LONG_INDEX) > 0 then
 MSG_WriteBits(Index, 16)
else
 MSG_WriteBits(Index, 8);
MSG_WriteBitVec3Coord(Origin);
if (Flags and SND_PITCH) > 0 then
 MSG_WriteBits(Pitch, 8);
MSG_EndBitWriting;
Result := True;
end;

procedure SV_AddToSoundTable(S: PLChar; Index: UInt);
var
 I, I2: UInt;
begin
I := HashString(S, MAX_SOUNDHASH);
I2 := I;

while SV.SoundHashTable[I] > 0 do
 begin
  Inc(I);
  if I = MAX_SOUNDHASH then
   I := 0;
  if I = I2 then
   Sys_Error('SV_AddToSoundTable: No free slots in sound lookup table.');

  Inc(SV.SoundHashCollisions);
 end;

SV.SoundHashTable[I] := Index;
end;

procedure SV_BuildSoundTable;
var
 I, J: UInt;
 S: PLChar;
begin
MemSet(SV.SoundHashTable, SizeOf(SV.SoundHashTable), 0);
SV.SoundHashCollisions := 0;

J := MAX_SOUNDS;
for I := 0 to MAX_SOUNDS - 1 do
 begin
  S := SV.PrecachedSoundNames[I];
  if S = nil then
   begin
    J := I;
    Break;
   end
  else
   SV_AddToSoundTable(S, I);
 end;

DPrint(['Sound hash table: ', SV.SoundHashCollisions, ' collisions, ', J, ' total sounds.']);
SV.SoundTableReady := True;
end;

function SV_LookupSoundIndexOld(Name: PLChar): UInt;
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

function SV_LookupSoundIndex(Name: PLChar): UInt;
var
 I, I2: UInt;
begin
I := HashString(Name, MAX_SOUNDHASH);
I2 := I;

if not SV.SoundTableReady then
 if SV.State = SS_LOADING then
  begin
   Result := SV_LookupSoundIndexOld(Name);
   Exit;
  end
 else
  SV_BuildSoundTable;

while SV.SoundHashTable[I] > 0 do
 begin
  if StrIComp(Name, SV.PrecachedSoundNames[SV.SoundHashTable[I]]) = 0 then
   begin
    Result := SV.SoundHashTable[I];
    Exit;
   end;

  Inc(I);
  if I = MAX_SOUNDHASH then
   I := 0;
  if I = I2 then
   Break;
 end;

Result := 0;
end;

function SV_ValidClientMulticast(const C: TClient; Leaf, Flags: UInt): Boolean;
var
 P: Pointer;
 I: UInt;
begin
Flags := Flags and not MULTICAST_SKIP_SELF;

if Host_IsSinglePlayerGame or C.HLTV or ((Flags and MULTICAST_ALL) > 0) then
 Result := True
else
 begin
  if (Flags and MULTICAST_PAS) > 0 then
   P := CM_LeafPAS(Leaf)
  else
   if (Flags and MULTICAST_PVS) > 0 then
    P := CM_LeafPVS(Leaf)
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
     begin
      Dec(I);
      Result := ((1 shl (I and 7)) and PByte(UInt(P) + (I shr 3))^) > 0;
     end;
   end;
 end;                         
end;

procedure SV_Multicast(const E: TEdict; const Origin: TVec3; Flags: UInt; Reliable: Boolean);
var
 Src, Dst: PClient;
 LeafNum: UInt;
 I: Int;
 SB: PSizeBuf;
begin
Src := HostClient;
LeafNum := SV_PointLeafnum(Origin);

if (@E <> nil) and ((Src = nil) or (Src.Entity <> @E)) then
 for I := 0 to SVS.MaxClients - 1 do
  if SVS.Clients[I].Entity = @E then
   begin
    Src := @SVS.Clients[I];
    Break;
   end;

for I := 0 to SVS.MaxClients - 1 do
 begin
  Dst := @SVS.Clients[I];
  if not Dst.Active then
   Continue;

  if ((Flags and MULTICAST_SKIP_SELF) <> 0) and (Src = Dst) then
   Continue;

  if (@E <> nil) and (Dst.Entity <> nil) and FilterGroup(E, Dst.Entity^) then
   Continue;

  if SV_ValidClientMulticast(Dst^, LeafNum, Flags) then
   begin
    if Reliable then
     SB := @Dst.Netchan.NetMessage
    else
     SB := @Dst.UnreliableMessage;

    if SB.MaxSize - SB.CurrentSize >= SV.Multicast.CurrentSize then
     SZ_Write(SB^, SV.Multicast.Data, SV.Multicast.CurrentSize)
    else
     Inc(SV.MulticastOverflowed, SV.Multicast.CurrentSize);
   end
  else
   Inc(SV.MulticastSuppressed, SV.Multicast.CurrentSize);
 end;

SZ_Clear(SV.Multicast);
end;

end.
