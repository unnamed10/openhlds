unit SVMain;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SV_Frame;

var
 sv_stats: TCVar = (Name: 'sv_stats'; Data: '1'); 
 sv_statsinterval: TCVar = (Name: 'sv_statsinterval'; Data: '30');

implementation

uses Memory, Host, Network, Resource, Server, SVClient, SVEdict, SVMove, SVPacket, SVPhys, SVRcon, SVSend, SysClock;

var
 VoiceCodec: array[1..128] of LChar;
 VoiceQuality: Single;
 VoiceInit: Boolean = False;

 LastMapCheck: Double = 0;

function SV_IsSimulating: Boolean;
begin
Result := not SV.Paused;
end;

procedure SV_CheckVoiceChanges;
var
 SB: TSizeBuf;
 SBData: array[1..256] of LChar;
 I: Int;
 C: PClient;
begin
if not VoiceInit then
 begin
  StrLCopy(@VoiceCodec, sv_voicecodec.Data, SizeOf(VoiceCodec) - 1);
  VoiceQuality := Trunc(sv_voicequality.Value);
  VoiceInit := True;
 end
else
 if (StrLIComp(@VoiceCodec, sv_voicecodec.Data, SizeOf(VoiceCodec) - 1) <> 0) or (VoiceQuality <> Trunc(sv_voicequality.Value)) then
  begin
   StrLCopy(@VoiceCodec, sv_voicecodec.Data, SizeOf(VoiceCodec) - 1);
   VoiceQuality := Trunc(sv_voicequality.Value);

   SB.Name := 'Voice';
   SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
   SB.Data := @SBData;
   SB.MaxSize := SizeOf(SBData);
   SB.CurrentSize := 0;

   SV_WriteVoiceCodec(SB);

   if not (FSB_OVERFLOWED in SB.AllowOverflow) then
    for I := 0 to SVS.MaxClients - 1 do
     begin
      C := @SVS.Clients[I];
      if C.Connected and not C.FakeClient then
       if SB.CurrentSize + C.Netchan.NetMessage.CurrentSize < C.Netchan.NetMessage.MaxSize then
        SZ_Write(C.Netchan.NetMessage, SB.Data, SB.CurrentSize)
       else
        begin
         Netchan_CreateFragments(C.Netchan, SB);
         Netchan_FragSend(C.Netchan);
        end;
     end;
  end;
end;

procedure SV_GatherStatistics;
var
 Players: UInt;
 F: Double;
 I, J: Int;
 C: PClient;
begin
if (sv_stats.Value <> 0) and (sv_statsinterval.Value > 0) and (RealTime >= SVS.Stats.NextStatUpdate) then
 begin
  SVS.Stats.NextStatUpdate := RealTime + sv_statsinterval.Value;
  Inc(SVS.Stats.NumStats);

  Players := SV_CountPlayers;
  if SVS.MaxClients > 0 then
   SVS.Stats.AccumServerFull := SVS.Stats.AccumServerFull + Players / SVS.MaxClients * 100;
  if SVS.Stats.NumStats > 0 then
   SVS.Stats.AvgServerFull := SVS.Stats.AccumServerFull / SVS.Stats.NumStats;

  if Players < SVS.Stats.MinClientsEver then
   SVS.Stats.MinClientsEver := Players
  else
   if Players > SVS.Stats.MaxClientsEver then
    SVS.Stats.MaxClientsEver := Players;

  if Players = SVS.MaxClients then
   Inc(SVS.Stats.TimesFull)
  else
   if Players = 0 then
    Inc(SVS.Stats.TimesEmpty);

  if (SVS.MaxClients > 1) and not ((SVS.MaxClients = 2) and (Players = 1)) then
   if Players >= SVS.MaxClients - 1 then
    Inc(SVS.Stats.TimesNearlyFull)
   else
    if Players <= 1 then
     Inc(SVS.Stats.TimesNearlyEmpty);

  if SVS.Stats.NumStats > 0 then
   begin
    SVS.Stats.NearlyFullPercent := SVS.Stats.TimesNearlyFull / SVS.Stats.NumStats * 100;
    SVS.Stats.NearlyEmptyPercent := SVS.Stats.TimesNearlyEmpty / SVS.Stats.NumStats * 100;
   end;

  F := 0;
  J := 0;
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Active and not C.FakeClient then
     begin
      Inc(J);
      F := F + C.Latency;
     end;
   end;

  if J > 0 then
   F := F / J;

  SVS.Stats.AccumLatency := SVS.Stats.AccumLatency + F;
  if SVS.Stats.NumStats > 0 then
   SVS.Stats.AvgLatency := SVS.Stats.AccumLatency / SVS.Stats.NumStats;

  if SVS.Stats.NumDrops > 0 then
   SVS.Stats.AvgTimePlaying := SVS.Stats.AccumTimePlaying / SVS.Stats.NumDrops;
 end;
end;

procedure SV_Frame;
begin
if SV.Active then
 begin
  GlobalVars.FrameTime := HostFrameTime;
  SV.PrevTime := SV.Time;
  if ToggleCheats then
   AllowCheats := sv_cheats.Value <> 0;

  SV_CheckCmdTimes;
  SV_ReadPackets;
  if SV_IsSimulating then
   begin
    SV_Physics;
    SV.Time := SV.Time + HostFrameTime;
   end;

  SV_QueryMovevarsChanged;
  SV_RequestMissingResourcesFromClients;
  SV_CheckTimeouts;
  SV_CheckVoiceChanges;  
  SV_SendClientMessages;
  SV_GatherStatistics;
 end;
end;

end.
