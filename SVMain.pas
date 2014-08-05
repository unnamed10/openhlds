unit SVMain;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SV_Frame;

implementation

uses Host, Network, Resource, Server, SVClient, SVEdict, SVMove, SVPacket, SVPhys, SVRcon, SVSend, SysClock;

var
 VoiceCodec: array[1..128] of LChar;
 VoiceQuality: Single;
 VoiceInit: Boolean = False;

 LastMapCheck: Double = 0;

function SV_IsSimulating: Boolean;
begin
Result := not SV.Paused and (SVS.MaxClients > 1);
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
   SB.AllowOverflow := [];
   SB.Data := @SBData;
   SB.MaxSize := SizeOf(SBData);
   SB.CurrentSize := 0;

   SV_WriteVoiceCodec(SB);

   for I := 0 to SVS.MaxClients - 1 do
    begin
     C := @SVS.Clients[I];
     if C.Connected and not C.FakeClient then
      begin
       Netchan_CreateFragments(C.Netchan, SB);
       Netchan_FragSend(C.Netchan);
      end;
    end;
  end;
end;

procedure SV_CheckMapDifferences;
var
 I: Int;
 C: PClient;
begin
if RealTime - LastMapCheck >= 5 then
 begin
  LastMapCheck := RealTime;
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Active and (C.MapCRC > 0) and (C.Netchan.Addr.AddrType <> NA_LOOPBACK) and (C.MapCRC <> SV.WorldModelCRC) then
     Include(C.Netchan.NetMessage.AllowOverflow, FSB_OVERFLOWED);
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
if RealTime >= SVS.Stats.NextStatClear then
 begin
  MemSet(SVS.Stats, SizeOf(SVS.Stats), 0);
  SVS.Stats.NextStatClear := RealTime + 60 * 60;
  SVS.Stats.NextStatUpdate := RealTime + 60;
  SV_CountPlayers(Players);
  SVS.Stats.MinClientsEver := Players;
  SVS.Stats.MaxClientsEver := Players;  
 end
else
 if RealTime >= SVS.Stats.NextStatUpdate then
  begin
   Inc(SVS.Stats.NumStats);
   SVS.Stats.NextStatUpdate := RealTime + 60;
   SV_CountPlayers(Players);
   if SVS.MaxClients > 0 then
    SVS.Stats.AccumServerFull := SVS.Stats.AccumServerFull + (Players * 100) / SVS.MaxClients;
   if SVS.Stats.NumStats > 0 then
    SVS.Stats.AvgServerFull := SVS.Stats.AccumServerFull / SVS.Stats.NumStats;

   if Players < SVS.Stats.MinClientsEver then
    SVS.Stats.MinClientsEver := Players
   else
    if Players > SVS.Stats.MaxClientsEver then
     SVS.Stats.MaxClientsEver := Players;

   if Players >= SVS.MaxClients - 1 then
    Inc(SVS.Stats.TimesNearlyFull);
   if Players <= 1 then
    Inc(SVS.Stats.TimesNearlyEmpty);

   if SVS.Stats.NumStats > 0 then
    begin
     SVS.Stats.NearlyFullPercent := SVS.Stats.TimesNearlyFull * 100 / SVS.Stats.NumStats;
     SVS.Stats.NearlyEmptyPercent := SVS.Stats.TimesNearlyEmpty * 100 / SVS.Stats.NumStats;
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
  SV_SendClientMessages;
  SV_CheckMapDifferences;
  SV_GatherStatistics;
  SV_CheckVoiceChanges;
 end;
end;

end.
