unit SVEdict;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SetMinMaxSize(var E: TEdict; const MinS, MaxS: TVec3);
function SV_ModelIndex(Name: PLChar): UInt;

procedure SV_LoadEntities;
procedure SV_ClearEntities;

procedure SV_GetPlayerHulls;

procedure SV_DeallocateDynamicData;
procedure SV_ReallocateDynamicData;
procedure SV_CreateBaseline;

procedure SV_WriteEntitiesToClient(var C: TClient; var SB: TSizeBuf);

procedure SV_CleanupEnts;

var
 sv_instancedbaseline: TCVar = (Name: 'sv_instancedbaseline'; Data: '1');

 LocalModels: array[0..MAX_MODELS - 1] of array[1..16] of LChar;

implementation

uses Console, Delta, Edict, GameLib, Host, MathLib, Memory, MsgBuf, PMove, Server, SVClient, SVDelta, SVEvent, SVPhys, SVWorld, SysMain;

var
 SVPlayerModel: Int; // signed
 SVLastNum: UInt;
 SVInstanceBaselines: TServerBaseline;

 DeltaCallback: record
  EntNumber: PUInt32; // +0
  Index: UInt; // +4
  NoDelta, Custom: Boolean; // +8, +12
  HasES: Boolean; // +16
  ES: UInt; // +20
  HasBestBaseline: Boolean; // +24
  BaselineIndex: Int; // +28
 end;

procedure SetMinMaxSize(var E: TEdict; const MinS, MaxS: TVec3);
begin
if (MaxS[0] < MinS[0]) or (MaxS[1] < MinS[1]) or (MaxS[2] < MinS[2]) then
 Host_Error(['SetMinMaxSize: Backwards mins/maxs on "', PLChar(PRStrings + E.V.ClassName), '".']);

E.V.MinS := MinS;
E.V.MaxS := MaxS;
VectorSubtract(MaxS, MinS, E.V.Size);
SV_LinkEdict(E, False);
end;

function SV_ModelIndex(Name: PLChar): UInt;
var
 I: UInt;
begin
if (Name <> nil) and (Name^ > #0) then
 begin
  for I := 0 to MAX_MODELS - 1 do
   if SV.PrecachedModelNames[I] = nil then
    Break
   else
    if StrIComp(SV.PrecachedModelNames[I], Name) = 0 then
     begin
      Result := I;
      Exit;
     end;
  
  Sys_Error(['SV_ModelIndex: Model "', Name, '" was not precached.']);
 end;

Result := 0;
end;

procedure SV_LoadEntities;
begin
ED_LoadFromFile(SV.WorldModel.Entities);
end;

procedure SV_ClearEntities;
var
 I: Int;
begin
for I := 0 to SV.NumEdicts - 1 do
 if SV.Edicts[I].Free = 0 then
  ReleaseEntityDLLFields(SV.Edicts[I]);
end;

procedure SV_FindModelNumbers;
var
 I: UInt;
 S: PLChar;
begin
SVPlayerModel := -1;
for I := 0 to MAX_MODELS - 1 do
 begin
  S := SV.PrecachedModelNames[I];
  if S = nil then
   Break
  else
   if (StrIComp(S, 'models\player.mdl') = 0) or (StrIComp(S, 'models/player.mdl') = 0) then
    SVPlayerModel := I;
 end;
end;

procedure SV_CreateBaseline;
var
 ES: TEntityState;
 P: PEntityState;
 I: Int;
 E: PEdict;
 D: PDelta;
begin
SV.Baseline := @SVInstanceBaselines;
MemSet(ES, SizeOf(ES), 0);
SV_FindModelNumbers;

for I := 0 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  if (E.Free = 0) and ((UInt(I) <= SVS.MaxClients) or (E.V.ModelIndex <> 0)) then
   begin
    P := @SV.EntityState[I];
    P.Number := I;
    if (E.V.Flags and FL_CUSTOMENTITY) > 0 then
     P.EntityType := ENTITY_BEAM
    else
     P.EntityType := ENTITY_NORMAL;

    DLLFunctions.CreateBaseline(Int((I >= 1) and (UInt(I) <= SVS.MaxClients)), I, P, E^, SVPlayerModel, @PlayerMinS, @PlayerMaxS);
    SVLastNum := I;
   end;
 end;

DLLFunctions.CreateInstancedBaselines;
MSG_WriteByte(SV.Signon, SVC_SPAWNBASELINE);
MSG_StartBitWriting(SV.Signon);
for I := 0 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  if (E.Free = 0) and ((UInt(I) <= SVS.MaxClients) or (E.V.ModelIndex <> 0)) then
   begin
    P := @SV.EntityState[I];
    MSG_WriteBits(I, 11);
    MSG_WriteBits(P.EntityType, 2);

    if (not P.EntityType and 1) <> 0 then
     D := CustomEntityDelta
    else
     if SV_IsPlayerIndex(I) then
      D := PlayerDelta
     else
      D := EntityDelta;

    Delta_WriteDelta(@ES, P, True, D^, nil);
   end;
 end;

MSG_WriteBits(65535, 16);
MSG_WriteBits(SV.Baseline.NumEnts, 6);
for I := 0 to SV.Baseline.NumEnts - 1 do
 Delta_WriteDelta(@ES, @SV.Baseline.ES[I], True, EntityDelta^, nil);

MSG_EndBitWriting;
end;

procedure SV_GetPlayerHulls;
var
 I: UInt;
begin
for I := 0 to 3 do
 if DLLFunctions.GetHullBounds(I, PlayerMinS[I], PlayerMaxS[I]) = 0 then
  Break;
end;

procedure SV_DeallocateDynamicData;
begin
if MovedEdict <> nil then
 Mem_FreeAndNil(MovedEdict);
if MovedFrom <> nil then
 Mem_FreeAndNil(MovedFrom);
end;

procedure SV_ReallocateDynamicData;
begin
if SV.MaxEdicts > 0 then
 begin
  if MovedEdict <> nil then
   Print('SV_ReallocateDynamicData: Memory leak on MovedEdict.');
  MovedEdict := Mem_ZeroAlloc(SizeOf(PEdict) * SV.MaxEdicts);

  if MovedFrom <> nil then
   Print('SV_ReallocateDynamicData: Memory leak on MovedFrom.');
  MovedFrom := Mem_ZeroAlloc(SizeOf(TVec3) * SV.MaxEdicts);
 end
else
 Print('SV_ReallocateDynamicData: No edicts.');
end;

procedure SV_SetCallback(Index: UInt; NoDelta, Custom: Boolean; EntNumber: PUInt32; HasBestBaseline: Boolean; BaselineIndex: Int);
begin
DeltaCallback.EntNumber := EntNumber;
DeltaCallback.Index := Index;
DeltaCallback.NoDelta := NoDelta;
DeltaCallback.Custom := Custom;
DeltaCallback.HasES := False;
DeltaCallback.ES := 0;
DeltaCallback.HasBestBaseline := HasBestBaseline;
DeltaCallback.BaselineIndex := BaselineIndex;
end;

procedure SV_SetNewInfo(ES: UInt);
begin
DeltaCallback.HasES := True;
DeltaCallback.ES := ES;
end;

procedure SV_WriteDeltaHeader(Index: UInt; NoDelta, Custom: Boolean; EntNumber: PUInt32; HasES: Boolean; ES: UInt; HasBestBaseline: Boolean; BaselineIndex: Int);
var
 ID: Int;
 B: Boolean;
begin
ID := Index - EntNumber^;
B := False;
if not HasBestBaseline then
 MSG_WriteBits(UInt(NoDelta), 1)
else
 if ID <> 1 then
  MSG_WriteBits(0, 1)
 else
  begin
   MSG_WriteBits(1, 1);
   B := True;
  end;

if not B then
 if (ID > 0) and (ID < MAX_BASELINES) then
  begin
   MSG_WriteBits(0, 1);
   MSG_WriteBits(ID, 6);
  end
 else
  begin
   MSG_WriteBits(1, 1);
   MSG_WriteBits(Index, 11);
  end;

EntNumber^ := Index;
if not NoDelta then
 begin
  MSG_WriteBits(UInt(Custom), 1);
  if SV.Baseline.NumEnts > 0 then
   if HasES then
    begin
     MSG_WriteBits(1, 1);
     MSG_WriteBits(ES, 6);
    end
   else
    MSG_WriteBits(0, 1);

  if not HasES and HasBestBaseline then
   if BaselineIndex <> 0 then
    begin
     MSG_WriteBits(1, 1);
     MSG_WriteBits(BaselineIndex, 6);
    end
   else
    MSG_WriteBits(0, 1);
 end;
end;

procedure SV_InvokeCallback;
begin
SV_WriteDeltaHeader(DeltaCallback.Index, DeltaCallback.NoDelta, DeltaCallback.Custom, DeltaCallback.EntNumber,
                    DeltaCallback.HasES, DeltaCallback.ES, DeltaCallback.HasBestBaseline, DeltaCallback.BaselineIndex);
end;

function SV_FindBestBaseline(Num: Int; var Best: PEntityState; ESPack: PEntityStateArray; Index: UInt; Custom: Boolean): Int;
var
 D: PDelta;
 P, P2: PEntityState;
 I, J, K, Cur, Found: Int;
begin
if Custom then
 D := CustomEntityDelta
else
 if SV_IsPlayerIndex(Index) then
  D := PlayerDelta
 else
  D := EntityDelta;

Cur := Num - 1;
Found := Num;
J := Num - Cur;

P := @ESPack[Num];
I := Delta_TestDelta(Best, P, D^) - 6;
while (I > 0) and (Cur >= 0) and (J < MAX_BASELINES - 1) do
 begin
  P2 := @ESPack[Cur];
  if P.EntityType = P2.EntityType then
   begin
    K := Delta_TestDelta(P2, P, D^);
    if K < I then
     begin
      I := K;
      Found := Cur;
     end;
   end;
  Dec(Cur);
  Inc(J);
 end;

Result := Num - Found;
if Num <> Found then
 Best := @ESPack[Found];
end;

procedure SV_CreatePacketEntities(DeltaCompression: Boolean; var C: TClient; var DstPack: TPacketEntities; var SB: TSizeBuf);
var
 SrcPack: PPacketEntities;
 EntsInPack, I, J, DstEntNum, SrcEntNum: UInt;
 K: Int;
 B: Boolean;
 ESIndex: UInt32;
 D: PDelta;
 DstEdict: PEdict;
 Best: PEntityState;
begin
if DeltaCompression then
 begin
  SrcPack := @C.Frames[SVUpdateMask and C.UpdateMask].Pack;
  EntsInPack := SrcPack.NumEnts;
  MSG_WriteByte(SB, SVC_DELTAPACKETENTITIES);
  MSG_WriteShort(SB, DstPack.NumEnts);
  MSG_WriteByte(SB, C.UpdateMask);
 end
else
 begin
  SrcPack := nil;
  EntsInPack := 0;
  MSG_WriteByte(SB, SVC_PACKETENTITIES);
  MSG_WriteShort(SB, DstPack.NumEnts);
 end;

I := 0;
J := 0;
DstEntNum := 0;

MSG_StartBitWriting(SB);
while True do
 begin
  if I < DstPack.NumEnts then
   DstEntNum := DstPack.Ents[I].Number
  else
   if J >= EntsInPack then
    Break
   else
    DstEntNum := 9999;
  
  if J < EntsInPack then
   SrcEntNum := SrcPack.Ents[J].Number
  else
   SrcEntNum := 9999;

  if DstEntNum = SrcEntNum then
   begin
    B := ((DstPack.Ents[I].EntityType shr 1) and 1) > 0;
    SV_SetCallback(DstEntNum, False, B, @ESIndex, False, 0);
    if B then
     D := CustomEntityDelta
    else
     if SV_IsPlayerIndex(DstEntNum) then
      D := PlayerDelta
     else
      D := EntityDelta;

    Delta_WriteDelta(@SrcPack.Ents[J], @DstPack.Ents[I], False, D^, SV_InvokeCallback);
    Inc(J);
   end
  else
   if DstEntNum > SrcEntNum then
    begin
     SV_WriteDeltaHeader(SrcEntNum, True, False, @ESIndex, False, 0, False, 0);
     Inc(J);
     Continue; // <- check this
    end
   else
    begin
     DstEdict := EDICT_NUM(DstEntNum);
     B := ((DstPack.Ents[I].EntityType shr 1) and 1) > 0;
     SV_SetCallback(DstEntNum, False, B, @ESIndex, SrcPack = nil, 0);

     Best := @SV.EntityState[DstEntNum];
     if (sv_instancedbaseline.Value = 0) or (SV.Baseline.NumEnts = 0) or (DstEntNum <= SVLastNum) then
      if SrcPack = nil then
       begin
        K := SV_FindBestBaseline(I, Best, DstPack.Ents, DstEntNum, B);
        if K <> 0 then
         SV_SetCallback(DstEntNum, False, B, @ESIndex, True, K);
       end
      else
     else
      for K := 0 to SV.BaseLine.NumEnts - 1 do
       if SV.Baseline.Classnames[K] = DstEdict.V.ClassName then
        begin
         SV_SetNewInfo(K);
         Best := @SV.Baseline.ES[K];
        end;

     if B then
      D := CustomEntityDelta
     else
      if SV_IsPlayerIndex(DstEntNum) then
       D := PlayerDelta
      else
       D := EntityDelta;

     Delta_WriteDelta(Best, @DstPack.Ents[I], True, D^, SV_InvokeCallback);
    end;

  Inc(I);
 end;

MSG_WriteBits(0, 16);
MSG_EndBitWriting;
//Result := SB.CurrentSize;
end;

procedure SV_EmitPacketEntities(var C: TClient; var Dst: TPacketEntities; var SB: TSizeBuf);
begin
SV_CreatePacketEntities(C.UpdateMask <> -1, C, Dst, SB);
end;

procedure SV_WriteEntitiesToClient(var C: TClient; var SB: TSizeBuf);
var
 Frame: PClientFrame;
 PVS, PAS: PByte;
 IsPlayer: Boolean;
 I: Int;
 P: PClient;
 InPack: UInt;
 ES: array[0..MAX_PACKET_ENTITIES - 1] of TEntityState;
begin
Frame := @C.Frames[SVUpdateMask and C.Netchan.OutgoingSequence];
PVS := nil;
PAS := nil;
InPack := 0;

DLLFunctions.SetupVisibility(C.Target^, C.Entity^, PVS, PAS);
SV_ClearPacketEntities(Frame^);

for I := 1 to SV.NumEdicts - 1 do
 begin
  IsPlayer := UInt(I) <= SVS.MaxClients;
  if IsPlayer then
   begin
    P := @SVS.Clients[I - 1];
    if (not P.Active and not P.Spawned) or P.HLTV then
     Continue;
   end;
   
  if InPack >= MAX_PACKET_ENTITIES then
   begin
    DPrint('Too many entities in visible packet list.');
    Break;
   end
  else
   if DLLFunctions.AddToFullPack(ES[InPack], I, SV.Edicts[I], HostClient.Entity^, UInt(C.LW), UInt(IsPlayer), PVS) <> 0 then
    Inc(InPack);
 end;

SV_AllocPacketEntities(Frame^, InPack);
if Frame.Pack.NumEnts > 0 then
 Move(ES, Frame.Pack.Ents^, SizeOf(TEntityState) * Frame.Pack.NumEnts);

SV_EmitPacketEntities(C, Frame.Pack, SB);
SV_EmitEvents(C, Frame.Pack, SB);

if SV_ShouldUpdatePing(C) then
 begin
  SV_EmitPings(SB);
  C.NextPingTime := RealTime + sv_pinginterval.Value;
 end;
end;

procedure SV_CleanupEnts;
var
 I: Int;
 E: PEdict;
begin
for I := 1 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  E.V.Effects := E.V.Effects and not (EF_MUZZLEFLASH or EF_NOINTERP);
 end;
end;

end.
