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

uses Common, Console, Delta, Edict, GameLib, Host, MathLib, Memory, MsgBuf, PMove, Server, SVClient, SVDelta, SVEvent, SVPhys, SVWorld, SysMain;

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
    if StrIComp(Name, SV.PrecachedModelNames[I]) = 0 then
     begin
      Result := I;
      Exit;
     end;
  
  Sys_Error(['SV_ModelIndex: Model "', Name, '" is not precached.']);
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
   Exit
  else
   if (StrIComp(S, 'models\player.mdl') = 0) or (StrIComp(S, 'models/player.mdl') = 0) then
    SVPlayerModel := I;
 end;
end;

procedure SV_CreateBaseline;
var
 B: Boolean;
 OS: TEntityState;
 NS: PEntityState;
 I: Int;
 E: PEdict;
 D: PDelta;
begin
SV.Baseline := @SVInstanceBaselines;
SV_FindModelNumbers;

for I := 0 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  B := (I >= 1) and (UInt(I) <= SVS.MaxClients);
  if (E.Free = 0) and (B or (E.V.ModelIndex <> 0)) then
   begin
    NS := @SV.EntityState[I];
    NS.Number := I;
    if (E.V.Flags and FL_CUSTOMENTITY) > 0 then
     NS.EntityType := ENTITY_BEAM
    else
     NS.EntityType := ENTITY_NORMAL;

    DLLFunctions.CreateBaseline(Int(B), I, NS, E^, SVPlayerModel, PlayerMinS[0][0], PlayerMinS[0][1], PlayerMinS[0][2], PlayerMaxS[0][0], PlayerMaxS[0][1], PlayerMaxS[0][2]);
    SVLastNum := I;
   end;
 end;

DLLFunctions.CreateInstancedBaselines;

MemSet(OS, SizeOf(OS), 0);
MSG_WriteByte(SV.Signon, SVC_SPAWNBASELINE);
MSG_StartBitWriting(SV.Signon);
for I := 0 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  B := (I >= 1) and (UInt(I) <= SVS.MaxClients);
  if (E.Free = 0) and (B or (E.V.ModelIndex <> 0)) then
   begin
    MSG_WriteBits(I, 11);
    
    NS := @SV.EntityState[I];
    MSG_WriteBits(NS.EntityType, 2);

    if NS.EntityType = ENTITY_BEAM then
     D := CustomEntityDelta
    else
     if B then
      D := PlayerDelta
     else
      D := EntityDelta;

    Delta_WriteDelta(@OS, NS, True, D^, nil);
   end;
 end;

MSG_WriteBits(65535, 16);
MSG_WriteBits(SV.Baseline.NumEnts, 6);
for I := 0 to SV.Baseline.NumEnts - 1 do
 begin
  NS := @SV.Baseline.ES[I];
  if NS.EntityType = ENTITY_BEAM then
   D := CustomEntityDelta
  else
   if (NS.Number >= 1) and (UInt(NS.Number) <= SVS.MaxClients) then
    D := PlayerDelta
   else
    D := EntityDelta;

  Delta_WriteDelta(@OS, NS, True, D^, nil);
 end;

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
   Mem_FreeAndNil(MovedEdict);
  MovedEdict := Mem_ZeroAlloc(SizeOf(PEdict) * SV.MaxEdicts);

  if MovedFrom <> nil then
   Mem_FreeAndNil(MovedFrom);
  MovedFrom := Mem_ZeroAlloc(SizeOf(TVec3) * SV.MaxEdicts);
 end
else
 DPrint('SV_ReallocateDynamicData: No edicts.');
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

function SV_FindBestBaseline(PackNum: Int; var Best: PEntityState; ESPack: PEntityStateArray; EntIndex: UInt; Custom: Boolean): Int;
var
 D: PDelta;
 OS, NS: PEntityState;
 BestScore, BestIndex, J, K, Cur: Int;
begin
if Custom then
 D := CustomEntityDelta
else
 if SV_IsPlayerIndex(EntIndex) then
  D := PlayerDelta
 else
  D := EntityDelta;

OS := Best;
NS := @ESPack[PackNum];
BestScore := Delta_TestDelta(OS, NS, D^); // how many bits should be sent
BestIndex := PackNum;

Cur := PackNum - 1;
J := 1;
while (BestScore > 0) and (Cur >= 0) and (J < MAX_BASELINES - 1) do
 begin
  OS := @ESPack[Cur];
  if OS.EntityType = NS.EntityType then
   begin
    K := Delta_TestDelta(OS, NS, D^);
    if K < BestScore then
     begin
      BestScore := K;
      BestIndex := Cur;
     end;
   end;
  Dec(Cur);
  Inc(J);
 end;

Result := PackNum - BestIndex;
if PackNum <> BestIndex then
 Best := @ESPack[BestIndex];
end;

procedure SV_CreatePacketEntities(DeltaCompression: Boolean; var C: TClient; var DstPack: TPacketEntities; var SB: TSizeBuf);
var
 SrcPack: PPacketEntities;
 SrcNumEnts, I, J, DstEntNum, SrcEntNum: UInt;
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
  SrcNumEnts := SrcPack.NumEnts;
  MSG_WriteByte(SB, SVC_DELTAPACKETENTITIES);
  MSG_WriteShort(SB, DstPack.NumEnts);
  MSG_WriteByte(SB, C.UpdateMask);
 end
else
 begin
  SrcPack := nil;
  SrcNumEnts := 0;
  MSG_WriteByte(SB, SVC_PACKETENTITIES);
  MSG_WriteShort(SB, DstPack.NumEnts);
 end;
MSG_StartBitWriting(SB);

I := 0;
J := 0;
while (I < DstPack.NumEnts) or (J < SrcNumEnts) do
 begin
  if I < DstPack.NumEnts then
   DstEntNum := DstPack.Ents[I].Number
  else
   DstEntNum := 9999;

  if J < SrcNumEnts then
   SrcEntNum := SrcPack.Ents[J].Number
  else
   SrcEntNum := 9999;

  if SrcEntNum = DstEntNum then
   begin
    B := DstPack.Ents[I].EntityType = ENTITY_BEAM;
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
    Inc(I);
   end
  else
   if SrcEntNum < DstEntNum then
    begin
     SV_WriteDeltaHeader(SrcEntNum, True, SrcPack.Ents[J].EntityType = ENTITY_BEAM, @ESIndex, False, 0, False, 0);
     Inc(J);
     Continue;
    end
   else
    begin
     B := DstPack.Ents[I].EntityType = ENTITY_BEAM;
     SV_SetCallback(DstEntNum, False, B, @ESIndex, SrcPack = nil, 0);

     Best := @SV.EntityState[DstEntNum];
     if (sv_instancedbaseline.Value = 0) or (SV.Baseline.NumEnts = 0) or (SVLastNum > DstEntNum) then
      if SrcPack = nil then
       begin
        K := SV_FindBestBaseline(I, Best, DstPack.Ents, DstEntNum, B);
        if K <> 0 then
         SV_SetCallback(DstEntNum, False, B, @ESIndex, True, K);
       end
      else
     else
      begin
       DstEdict := @SV.Edicts[DstEntNum];
       for K := 0 to SV.Baseline.NumEnts - 1 do
        if SV.Baseline.Classnames[K] = DstEdict.V.ClassName then
         begin
          SV_SetNewInfo(K);
          Best := @SV.Baseline.ES[K];
          Break;
         end;
      end;

     if B then
      D := CustomEntityDelta
     else
      if SV_IsPlayerIndex(DstEntNum) then
       D := PlayerDelta
      else
       D := EntityDelta;

     Delta_WriteDelta(Best, @DstPack.Ents[I], True, D^, SV_InvokeCallback);
     Inc(I);
    end;
 end;

MSG_WriteBits(0, 16);
MSG_EndBitWriting;
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
SV_ClearPacketEntities(Frame^, False);

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
   if DLLFunctions.AddToFullPack(ES[InPack], I, SV.Edicts[I], C.Entity^, UInt(C.LW), UInt(IsPlayer), PVS) <> 0 then
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
