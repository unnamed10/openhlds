unit SVMain;

{$I HLDS.inc}

interface

uses Default, SDK, FilterIP, SVExport;

procedure SV_Frame;

procedure SV_ServerDeactivate;
procedure SV_ActivateServer(NewUnit: Boolean);
function SV_SpawnServer(Map, StartSpot: PLChar): Boolean;

procedure SV_RecordPlayingTime(Time: Double);

procedure SV_Init;
procedure SV_Shutdown;

var
 AllowCheats: Boolean = False;
 ToggleCheats: Boolean = False;

 SVDecalNameCount: UInt;
 SVDecalNames: array[0..MAX_DECAL_NAMES - 1] of array[1..MAX_LUMP_NAME + 1] of LChar;

 SVUpdateBackup: UInt = 8;
 SVUpdateMask: UInt = 7;
 PrevUpdateBackup: UInt;

 SV: record
  Active: Boolean; // 0 L, 0 W, cf
  Paused: Boolean; // 4 L, 4 W, cf
  SavedGame: Boolean; // 8 L, 8 W, cf
  Time: Double; // 12 L, 16 W, cf
  PrevTime: Double; // 20 L, 24 W, cf
  LastPVSClient: Int32; // 28 L
  LastPVSCheckTime: Double; // 32 L
  Map: array[1..MAX_MAP_NAME] of LChar; // 40 L confirmed
  PrevMap: array[1..MAX_MAP_NAME] of LChar; // 104 L cf
  StartSpot: array[1..64] of LChar; // 168 L, cf
  MapFileName: array[1..MAX_MAP_NAME] of LChar; // 232: maps/%s.bsp / map filename, length = 64
  WorldModel: PModel; // 296, the map pointer
  WorldModelCRC: TCRC; // 300 L, cf
  ClientDLLHash: TMD5Hash; // 304 L, cf
  Resources: array[0..MAX_RESOURCES - 1] of TResource; // 320 L, cf
  NumResources: UInt32;
  PrecachedConsistency: array[0..MAX_CONSISTENCY - 1] of TConsistency; // 174404 probably
  NumConsistency: UInt32; // 196932 L cf
  PrecachedModelNames: array[0..MAX_MODELS - 1] of PLChar; // 196936
  PrecachedModels: array[0..MAX_MODELS - 1] of PModel; // 198984
  PrecachedModelFlags: array[0..MAX_MODELS - 1] of TResourceFlags; // 201032
  PrecachedEvents: array[0..MAX_EVENTS - 1] of TPrecachedEvent;
  PrecachedSoundNames: array[0..MAX_SOUNDS - 1] of PLChar; // 205640
  SoundHashTable: array[0..MAX_SOUNDHASH - 1] of UInt16; // 207688, 1023 entries
  SoundTableReady: Boolean; // 209736: sound hashing needed or something
  PrecachedGeneric: array[0..MAX_GENERICS - 1] of PLChar; // 209740
  PrecachedResGeneric: array[0..MAX_GENERICS - 1] of array[1..64] of LChar; // 211788
  NumResGeneric: UInt32; // 244556
  LightStyles: array[0..MAX_LIGHTSTYLES - 1] of PLChar; // 244560
  NumEdicts: UInt32; // 244816 L
  MaxEdicts: UInt32; // 244820 L
  Edicts: ^TEdictArray; // 244824 L
  EntityState: ^TEntityStateArray; // 244828 L
  Baseline: PServerBaseline; // 244832, cf
  State: (SS_OFF = 0, SS_LOADING, SS_ACTIVE); // 244836 L
  Datagram: TSizeBuf; // 244840 L
  DatagramData: array[1..MAX_DATAGRAM] of Byte; // 244860 size cf
  ReliableDatagram: TSizeBuf; // 248860 L check check
  ReliableDatagramData: array[1..MAX_DATAGRAM] of Byte; // 248880 L size cf
  Multicast: TSizeBuf; // 252880 L
  MulticastData: array[1..1024] of Byte; // 252900 L size cf
  Spectator: TSizeBuf; // 253924 L
  SpectatorData: array[1..1024] of Byte; // 253944 L size cf
  Signon: TSizeBuf; // 254968 L
  SignonData: array[1..32768] of Byte; // 254988 L size not cf

  // custom fields

  SoundHashCollisions: UInt;
  MulticastSuppressed: UInt;
  MulticastOverflowed: UInt;
 end; // 287756 on 48patch

 SVS: record // all confirmed
  InitGameDLL: Boolean; // +0, confirmed
  Clients: ^TClientArray; // +4, confirmed
  MaxClients, MaxClientsLimit: UInt32; // +8, +12; confirmed
  SpawnCount: UInt32; // +16, confirmed
  ServerFlags: UInt32; // +20
  LogEnabled: Boolean; // +24
  LogToAddr: Boolean; // +28
  LogAddr: TNetAdr; // +32
  LogFile: TFile; // +52

  Stats: record
   NumStats: UInt;
   NextStatUpdate: Double;
   
   Fill: array[0..MAX_PLAYERS] of UInt;

   NumDrops: UInt;
   NumLatency: UInt;
   AccumTimePlaying, AccumLatency, AccumFrames: Double;
  end;

  Secure: UInt32;
 end;

 OutOfBandIPF: TIPFilter;

 GlobalVars: TGlobalVars;
 MoveVars: TMoveVars;

 HostClient: PClient;
 SVPlayer: PEdict;

 NullString: PLChar = #0;
 PRStrings: UInt;

 sv_logbans: TCVar = (Name: 'sv_logbans'; Data: '1');
 sv_log_onefile: TCVar = (Name: 'sv_log_onefile'; Data: '0');
 sv_log_singleplayer: TCVar = (Name: 'sv_log_singleplayer'; Data: '0');
 sv_log_altdateformat: TCVar = (Name: 'sv_log_altdateformat'; Data: '0');
 mp_logecho: TCVar = (Name: 'mp_logecho'; Data: '1');
 mp_logfile: TCVar = (Name: 'mp_logfile'; Data: '1');

 logsdir: TCVar = (Name: 'logsdir'; Data: 'logs');
 mapcyclefile: TCVar = (Name: 'mapcyclefile'; Data: 'mapcycle.txt');
 motdfile: TCVar = (Name: 'motdfile'; Data: 'motd.txt');
 servercfgfile: TCVar = (Name: 'servercfgfile'; Data: 'server.cfg');
 mapchangecfgfile: TCVar = (Name: 'mapchangecfgfile'; Data: '');
 lservercfgfile: TCVar = (Name: 'lservercfgfile'; Data: 'listenserver.cfg');
 bannedcfgfile: TCVar = (Name: 'bannedcfgfile'; Data: 'banned.cfg');

 sv_voicecodec: TCVar = (Name: 'sv_voicecodec'; Data: 'voice_speex'; Flags: [FCVAR_SERVER]);
 sv_voiceenable: TCVar = (Name: 'sv_voiceenable'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_voicequality: TCVar = (Name: 'sv_voicequality'; Data: '5'; Flags: [FCVAR_SERVER]);

 mp_consistency: TCVar = (Name: 'mp_consistency'; Data: '1'; Flags: [FCVAR_SERVER]);
 mp_footsteps: TCVar = (Name: 'mp_footsteps'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_downloadurl: TCVar = (Name: 'sv_downloadurl'; Data: ''; Flags: [FCVAR_PROTECTED]);

 sv_aim: TCVar = (Name: 'sv_aim'; Data: '1'; Flags: [FCVAR_ARCHIVE]);
 sv_clienttrace: TCVar = (Name: 'sv_clienttrace'; Data: '1');
 sv_cheats: TCVar = (Name: 'sv_cheats'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_lan: TCVar = (Name: 'sv_lan'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_lan_rate: TCVar = (Name: 'sv_lan_rate'; Data: '20000');
 sv_newunit: TCVar = (Name: 'sv_newunit'; Data: '0');
 sv_filterban: TCVar = (Name: 'sv_filterban'; Data: '1');
 sv_outofdatetime: TCVar = (Name: 'sv_outofdatetime'; Data: '1800'); // outdated?
 sv_password: TCVar = (Name: 'sv_password'; Data: ''; Flags: [FCVAR_SERVER, FCVAR_PROTECTED]);
 sv_timeout: TCVar = (Name: 'sv_timeout'; Data: '60'; Flags: [FCVAR_SERVER]);
 sv_version: TCVar = (Name: 'sv_version'; Data: ''; Flags: [FCVAR_SERVER]);
 sv_visiblemaxplayers: TCVar = (Name: 'sv_visiblemaxplayers'; Data: '-1');

 sv_sendmapcrc: TCVar = (Name: 'sv_sendmapcrc'; Data: '1');
 sv_secureflag: TCVar = (Name: 'sv_secureflag'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_sendentsinterval: TCVar = (Name: 'sv_sendentsinterval'; Data: '0.75');
 sv_sendresinterval: TCVar = (Name: 'sv_sendresinterval'; Data: '1.35');
 sv_fullupdateinterval: TCVar = (Name: 'sv_fullupdateinterval'; Data: '1.1');
 sv_stats: TCVar = (Name: 'sv_stats'; Data: '1');
 sv_statsinterval: TCVar = (Name: 'sv_statsinterval'; Data: '30');

implementation

uses Common, Console, Edict, Encode, GameLib, Host, HPAK, Memory, Model, Network, PMove, Resource, SVClient, SVCmds, SVDelta, SVEdict, SVEvent, SVMove, SVPacket, SVPhys, SVRcon, SVSend, SVWorld, SysArgs, SysClock;

var
 VoiceCodec: array[1..128] of LChar;
 VoiceQuality: UInt;
 VoiceInit: Boolean = False;

 LastMapCheck: Double = 0;

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
       if SB.CurrentSize + C.Netchan.NetMessage.CurrentSize <= C.Netchan.NetMessage.MaxSize then
        SZ_Write(C.Netchan.NetMessage, SB.Data, SB.CurrentSize)
       else
        begin
         Netchan_CreateFragments(C.Netchan, SB);
         Netchan_FragSend(C.Netchan);
        end;
     end;
  end;
end;

procedure SV_FlushStats_F; cdecl;
begin
MemSet(SVS.Stats, SizeOf(SVS.Stats), 0);
end;

procedure SV_RecordPlayingTime(Time: Double);
begin
if sv_stats.Value <> 0 then
 begin
  Inc(SVS.Stats.NumDrops);
  SVS.Stats.AccumTimePlaying := SVS.Stats.AccumTimePlaying + Time * 10;
 end;
end;

procedure SV_GatherStatistics;
var
 Players: UInt;
 I: Int;
 C: PClient;
begin
if (RealTime >= SVS.Stats.NextStatUpdate) and (sv_stats.Value <> 0) and (sv_statsinterval.Value > 0) then
 begin
  SVS.Stats.NextStatUpdate := RealTime + sv_statsinterval.Value;
  Inc(SVS.Stats.NumStats);
  if SVS.Stats.NumStats = 0 then
   SVS.Stats.NumStats := 1;

  Players := SV_CountPlayers;
  Inc(SVS.Stats.Fill[Players]);

  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Active and not C.FakeClient then
     begin
      SVS.Stats.AccumLatency := SVS.Stats.AccumLatency + C.Latency;
      Inc(SVS.Stats.NumLatency);
     end;
   end;

  if RollingFPS > 0 then
   SVS.Stats.AccumFrames := SVS.Stats.AccumFrames + 1 / RollingFPS;
 end;
end;

function WriteTime(F: UInt; out Buf): PLChar;
var
 IntBuf, ExpandBuf: array[1..32] of LChar;
 Hour, Min, Sec: UInt;
 S: PLChar;
begin
Sec := F mod 60;
F := F div 60;
Min := F mod 60;
Hour := F div 60;

S := StrECopy(@Buf, ExpandString(IntToStr(Hour, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
S := StrECopy(S, ':');
S := StrECopy(S, ExpandString(IntToStr(Min, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
S := StrECopy(S, ':');
StrCopy(S, ExpandString(IntToStr(Sec, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));

Result := @Buf;
end;

procedure SV_PrintStats_F; cdecl;
var
 I: Int;
 IntBuf, ExpandBuf, Buf: array[1..128] of LChar;
begin
if SVS.Stats.NumStats = 0 then
 Print('No stat records yet.')
else
 begin
  Print(['Printing stat records from ', SVS.Stats.NumStats, ' samples.']);

  Print('Players:');
  for I := 0 to MAX_PLAYERS do
   Print([ExpandString(IntToStr(I, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2),
          ':', RoundTo(SVS.Stats.Fill[I] / SVS.Stats.NumStats * 100, -2), '%  '], (I+1) mod 5 = 0);
  if MAX_PLAYERS mod 5 > 0 then
   Print('');

  Print(['Players disconnected ', SVS.Stats.NumDrops, ' times.']);
  if SVS.Stats.NumDrops > 0 then
   Print(['Average playing time: ', WriteTime(Round(SVS.Stats.AccumTimePlaying / SVS.Stats.NumDrops), Buf)]);

  if SVS.Stats.NumLatency > 0 then
   Print(['Average player latency with ', SVS.Stats.NumLatency, ' samples: ', SVS.Stats.AccumLatency / SVS.Stats.NumLatency, ' ms.']);

  Print(['Average server FPS: ', RoundTo(SVS.Stats.AccumFrames / SVS.Stats.NumStats, -2), '.']);
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
  if not SV.Paused then
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

procedure SV_ServerDeactivate;
begin
GlobalVars.Time := SV.Time;
if SVS.InitGameDLL and SV.Active and (@DLLFunctions.ServerDeactivate <> nil) then
 DLLFunctions.ServerDeactivate;
end;

procedure SV_ActivateServer(NewUnit: Boolean);
var
 C: PClient;
 SB: TSizeBuf;
 SBData: array[1..MAX_NETBUFLEN] of Byte;
 I: Int;
begin
SB.Name := 'Activate Server';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.CurrentSize := 0;
SB.MaxSize := SizeOf(SBData);

SetCStrikeFlags;
CVar_DirectSet(sv_newunit, '0');
DLLFunctions.ServerActivate(@SV.Edicts[0], SV.NumEdicts, SVS.MaxClients);
SV_CreateGenericResources;

SV.State := SS_ACTIVE;
SV.Active := True;

if not NewUnit then
 begin
  HostFrameTime := 0.001;
  SV_Physics;
 end
else
 if SVS.MaxClients <= 1 then
  begin
   HostFrameTime := 0.1;
   SV_Physics;
   SV_Physics;
  end
 else
  begin
   HostFrameTime := 0.8;
   for I := 1 to 16 do
    SV_Physics;
  end;

SV_CreateBaseline;
SV_CreateResourceList;
SV_TransferConsistencyInfo;
                             
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Connected) and not C.FakeClient then
   begin
    Netchan_Clear(C.Netchan);
    if SVS.MaxClients > 1 then
     begin
      SV_BuildReconnect(C.Netchan.NetMessage);
      Netchan_Transmit(C.Netchan, 0, nil);
     end
    else
     SV_SendServerInfo(SB, C^);

    if UserMsgs <> nil then
     SV_SendUserReg(SB, UserMsgs);

    if FSB_OVERFLOWED in SB.AllowOverflow then
     SV_DropClient(C^, False, 'Message buffer overflowed.')
    else
     begin
      C.UserMsgReady := True;
      Netchan_CreateFragments(C.Netchan, SB);
      Netchan_FragSend(C.Netchan);
     end;
    
    SZ_Clear(SB);
   end;
 end;

HPAK_FlushHostQueue;

LPrint(['Started map "', PLChar(@SV.Map), '" (CRC "', SV.WorldModelCRC, '")'#10]);
if (mapchangecfgfile.Data <> nil) and (mapchangecfgfile.Data^ > #0) then
 begin
  PF_AlertMessage(atConsole, 'Executing map change config file.'#10);
  CBuf_AddText(['exec "', mapchangecfgfile.Data, '"'#10]);
 end;

if SVS.MaxClients <= 1 then
 Print('Game started.')
else
 Print(['Started the server on ', PLChar(@SV.Map), ' with ', SVS.MaxClients, ' max players.']);
end;

function SV_SpawnServer(Map, StartSpot: PLChar): Boolean;
var
 I: Int;
 C: PClient;
 S: PLChar;
 PrevMap: array[1..MAX_MAP_NAME] of LChar;
begin
Result := False;
if SV.Active then
 for I := 0 to SVS.MaxClients - 1 do
  begin
   C := @SVS.Clients[I];
   if (C.Active or C.Spawned or C.Connected) and (C.Entity <> nil) and (C.Entity.Free = 0) and (C.Entity.PrivateData <> nil) then
    DLLFunctions.ClientDisconnect(C.Entity^);
  end;

Log_Open;
LPrint(['Loading map "', Map, '"'#10]);
Log_PrintServerVars;

StrCopy(@PrevMap, @SV.Map);
HPAK_CheckSize('custom');

Host_ClearMemory;

if hostname.Data^ = #0 then
 begin
  S := DLLFunctions.GetGameDescription;
  if S <> nil then
   CVar_DirectSet(hostname, S)
  else
   CVar_DirectSet(hostname, ProjectName);
 end;

if StartSpot = nil then
 DPrint(['Spawned server ', Map, '.'])
else
 DPrint(['Spawned server ', Map, ': [', StartSpot, '].']);

Inc(SVS.SpawnCount);

if deathmatch.Value <> 0 then
 begin
  CVar_DirectSet(deathmatch, '1');
  CVar_DirectSet(coop, '0');
 end
else
 if coop.Value <> 0 then
  begin
   CVar_DirectSet(deathmatch, '0');
   CVar_DirectSet(coop, '1');
  end
 else
  begin
   CVar_DirectSet(deathmatch, '0');
   CVar_DirectSet(coop, '0');
  end;

I := Round(skill.Value);
if I < 0 then
 I := 0
else
 if I > 3 then
  I := 3;
CVar_SetValue('skill', I);

if SVS.MaxClients <> 1 then
 SVUpdateBackup := 64
else
 SVUpdateBackup := 8;
SVUpdateMask := SVUpdateBackup - 1;

StrCopy(@SV.PrevMap, @PrevMap);
StrLCopy(@SV.Map, Map, SizeOf(SV.Map) - 1);
if StartSpot <> nil then
 StrLCopy(@SV.StartSpot, StartSpot, SizeOf(SV.StartSpot) - 1)
else
 SV.StartSpot[Low(SV.StartSpot)] := #0;

PRStrings := UInt(NullString);
GlobalVars.StringBase := NullString;

if SVS.MaxClients = 1 then
 CVar_DirectSet(sv_clienttrace, '1');

SV.MaxEdicts := COM_EntsForPlayerSlots(SVS.MaxClients);
SV_AllocatePMSimulator;

GlobalVars.MaxEntities := SV.MaxEdicts;
GlobalVars.MaxClients := SVS.MaxClients;
SV.Edicts := Hunk_AllocName(SizeOf(TEdict) * SV.MaxEdicts, 'edicts');
SV.EntityState := Hunk_AllocName(SizeOf(TEntityState) * SV.MaxEdicts, 'baselines');

SV.Datagram.Name := 'Server Datagram';
SV.Datagram.AllowOverflow := [FSB_ALLOWOVERFLOW];
SV.Datagram.Data := @SV.DatagramData;
SV.Datagram.MaxSize := SizeOf(SV.DatagramData);
SV.ReliableDatagram.Name := 'Server Reliable Datagram';
SV.ReliableDatagram.AllowOverflow := [];
SV.ReliableDatagram.Data := @SV.ReliableDatagramData;
SV.ReliableDatagram.MaxSize := SizeOf(SV.ReliableDatagramData);
SV.Multicast.Name := 'Server Multicast Buffer';
SV.Multicast.AllowOverflow := [];
SV.Multicast.Data := @SV.MulticastData;
SV.Multicast.MaxSize := SizeOf(SV.MulticastData);
SV.Spectator.Name := 'Server Spectator Buffer';
SV.Spectator.AllowOverflow := [FSB_ALLOWOVERFLOW];
SV.Spectator.Data := @SV.SpectatorData;
SV.Spectator.MaxSize := SizeOf(SV.SpectatorData);
SV.Signon.Name := 'Server Signon Buffer';
SV.Signon.AllowOverflow := [];
SV.Signon.Data := @SV.SignonData;
SV.Signon.MaxSize := SizeOf(SV.SignonData);

SV.NumEdicts := SVS.MaxClients + 1;
for I := 0 to SVS.MaxClients - 1 do
 SVS.Clients[I].Entity := @SV.Edicts[I + 1];

SV.State := SS_LOADING;
SV.Time := 1;
GlobalVars.Time := 1;
ToggleCheats := sv_cheats.Value = 2;
AllowCheats := sv_cheats.Value <> 0;

S := StrECopy(@SV.MapFileName, 'maps/');
S := StrLECopy(S, Map, SizeOf(SV.MapFileName) - 10);
StrCopy(S, '.bsp');  

SV.WorldModel := Mod_ForName(@SV.MapFileName, False, False);
if SV.WorldModel = nil then
 begin
  Print(['Couldn''t spawn server: "', PLChar(@SV.MapFileName), '" failed to load.']);
  SV.State := SS_OFF;
  SV.Active := False;
  Exit;
 end;

S := 'cl_dlls' + CorrectSlash + 'client.dll';
if not MD5_Hash_File(SV.ClientDLLHash, S, True, False, nil) then
 DPrint(['Couldn''t CRC client-side DLL: "', S, '", ignoring.']);

if SVS.MaxClients <= 1 then
 SV.WorldModelCRC := 0
else
 begin
  CRC32_Init(SV.WorldModelCRC);
  if not CRC_MapFile(SV.WorldModelCRC, @SV.MapFileName) then
   begin
    Print(['Couldn''t CRC server map: "', PLChar(@SV.MapFileName), '".']);
    SV.State := SS_OFF;
    SV.Active := False;
    Exit;
   end;
 end;

CM_CalcPAS(SV.WorldModel^);
SV_ClearWorld;

SV.PrecachedModels[1] := SV.WorldModel;
SV.PrecachedSoundNames[0] := Pointer(PRStrings);
SV.PrecachedModelNames[0] := Pointer(PRStrings);
SV.PrecachedModelNames[1] := @SV.MapFileName;
SV.PrecachedGeneric[0] := Pointer(PRStrings);
Include(SV.PrecachedModelFlags[1], RES_FATALIFMISSING);

if SV.WorldModel.NumSubModels >= MAX_MODELS - 2 then
 begin
  Print('Can''t start the server, too many map submodels.');
  SV.State := SS_OFF;
  SV.Active := False;
  Exit;
 end;

for I := 1 to SV.WorldModel.NumSubModels - 1 do
 begin
  SV.PrecachedModelNames[I + 1] := @LocalModels[I];
  SV.PrecachedModels[I + 1] := Mod_ForName(@LocalModels[I], False, False);
  Include(SV.PrecachedModelFlags[I + 1], RES_FATALIFMISSING);
 end;

MemSet(SV.Edicts[0].V, SizeOf(TEntVars), 0);
SV.Edicts[0].Free := 0;
SV.Edicts[0].V.Model := UInt(@SV.WorldModel.Name) - PRStrings;
SV.Edicts[0].V.ModelIndex := 1;
SV.Edicts[0].V.Solid := SOLID_BSP;
SV.Edicts[0].V.MoveType := MOVETYPE_PUSH;

if coop.Value <> 0 then
 GlobalVars.Coop := coop.Value
else
 GlobalVars.Deathmatch := deathmatch.Value;

GlobalVars.ServerFlags := SVS.ServerFlags;
GlobalVars.MapName := UInt(@SV.Map) - PRStrings;
GlobalVars.StartSpot := UInt(@SV.StartSpot) - PRStrings;
SV_SetMoveVars;
Result := True;
end;

procedure SV_Init;
var
 I: Int;
begin
// Missing: banid, removeid, listid, writeid
//          addip, removeip, listip, writeip

Cmd_AddCommand('logaddress', @SV_SetLogAddress_F);
Cmd_AddCommand('logaddress_add', @SV_AddLogAddress_F);
Cmd_AddCommand('logaddress_del', @SV_DelLogAddress_F);
Cmd_AddCommand('log', @SV_ServerLog_F);
Cmd_AddCommand('serverinfo', @SV_Serverinfo_F);
Cmd_AddCommand('localinfo', @SV_Localinfo_F);
Cmd_AddCommand('showinfo', @SV_ShowServerinfo_F);
Cmd_AddCommand('user', @SV_User_F);
Cmd_AddCommand('users', @SV_Users_F);

Cmd_AddCommand('new', @SV_New_F);
Cmd_AddCommand('spawn', @SV_Spawn_F);
Cmd_AddCommand('sendres', @SV_SendRes_F);
Cmd_AddCommand('sendents', @SV_SendEnts_F);
Cmd_AddCommand('fullupdate', @SV_FullUpdate_F);
Cmd_AddCommand('dlfile', @SV_BeginFileDownload_F);
Cmd_AddCommand('dropclient', @SV_Drop_F);
Cmd_AddCommand('resetrcon', @SV_ResetRcon_F);

Cmd_AddCommand('entcount', @ED_Count_F);
Cmd_AddCommand('flushstats', @SV_FlushStats_F);
Cmd_AddCommand('stats', @SV_PrintStats_F);

// Resource
CVar_RegisterVariable(sv_allowdownload);
CVar_RegisterVariable(sv_allowupload);
CVar_RegisterVariable(sv_uploadmax);
CVar_RegisterVariable(sv_uploadmaxnum);
CVar_RegisterVariable(sv_uploadmaxsingle);
CVar_RegisterVariable(sv_uploaddecalsonly);
CVar_RegisterVariable(sv_send_logos);
CVar_RegisterVariable(sv_send_resources);

// SVClient
CVar_RegisterVariable(sv_defaultplayername);
CVar_RegisterVariable(sv_use2asnameprefix);
CVar_RegisterVariable(sv_maxupdaterate);
CVar_RegisterVariable(sv_minupdaterate);
CVar_RegisterVariable(sv_defaultupdaterate);
CVar_RegisterVariable(sv_maxrate);
CVar_RegisterVariable(sv_minrate);
CVar_RegisterVariable(sv_defaultrate);
CVar_RegisterVariable(sv_failuretime);
CVar_RegisterVariable(sv_pinginterval);
CVar_RegisterVariable(sv_updatetime);
CVar_RegisterVariable(sv_keepframes);

// SVEdict
CVar_RegisterVariable(sv_instancedbaseline);

// SVMain
CVar_RegisterVariable(sv_logbans);
CVar_RegisterVariable(sv_log_onefile);
CVar_RegisterVariable(sv_log_singleplayer);
CVar_RegisterVariable(sv_log_altdateformat);
CVar_RegisterVariable(mp_logecho);
CVar_RegisterVariable(mp_logfile);
CVar_RegisterVariable(logsdir);
CVar_RegisterVariable(mapcyclefile);
CVar_RegisterVariable(motdfile);
CVar_RegisterVariable(servercfgfile);
CVar_RegisterVariable(mapchangecfgfile);
CVar_RegisterVariable(lservercfgfile);
CVar_RegisterVariable(bannedcfgfile);
CVar_RegisterVariable(sv_voicecodec);
CVar_RegisterVariable(sv_voiceenable);
CVar_RegisterVariable(sv_voicequality);
CVar_RegisterVariable(mp_consistency);
CVar_RegisterVariable(mp_footsteps);
CVar_RegisterVariable(sv_downloadurl);
CVar_RegisterVariable(sv_aim);
CVar_RegisterVariable(sv_clienttrace);
CVar_RegisterVariable(sv_cheats);
CVar_RegisterVariable(sv_lan);
CVar_RegisterVariable(sv_lan_rate);
CVar_RegisterVariable(sv_newunit);
CVar_RegisterVariable(sv_filterban);
CVar_RegisterVariable(sv_outofdatetime);
CVar_RegisterVariable(sv_password);
CVar_RegisterVariable(sv_timeout);
CVar_RegisterVariable(sv_version);
CVar_RegisterVariable(sv_visiblemaxplayers);
CVar_RegisterVariable(sv_sendmapcrc);
CVar_RegisterVariable(sv_secureflag);
CVar_RegisterVariable(sv_sendentsinterval);
CVar_RegisterVariable(sv_sendresinterval);
CVar_RegisterVariable(sv_fullupdateinterval);
CVar_RegisterVariable(sv_stats);
CVar_RegisterVariable(sv_statsinterval);

// SVMove
CVar_RegisterVariable(sv_maxunlag);
CVar_RegisterVariable(sv_unlag);
CVar_RegisterVariable(sv_unlagpush);
CVar_RegisterVariable(sv_unlagsamples);
CVar_RegisterVariable(sv_unlagjitter);
CVar_RegisterVariable(sv_cmdcheckinterval);

// SVPacket
CVar_RegisterVariable(sv_contact);
CVar_RegisterVariable(sv_region);
CVar_RegisterVariable(sv_logblocks);
CVar_RegisterVariable(sv_logrelay);
CVar_RegisterVariable(sv_proxies);
CVar_RegisterVariable(sv_allow47p);
CVar_RegisterVariable(sv_allow48p);
CVar_RegisterVariable(sv_maxipsessions);
CVar_RegisterVariable(sv_fullservermsg);
CVar_RegisterVariable(ipf_min_samples);
CVar_RegisterVariable(ipf_max_queries_sec);
CVar_RegisterVariable(ipf_timeout);
CVar_RegisterVariable(sv_limit_queries);
CVar_RegisterVariable(sv_enableoldqueries);

// SVPhys
CVar_RegisterVariable(sv_bounce);
CVar_RegisterVariable(sv_friction);
CVar_RegisterVariable(sv_gravity);
CVar_RegisterVariable(sv_maxvelocity);
CVar_RegisterVariable(sv_stopspeed);
CVar_RegisterVariable(sv_maxspeed);
CVar_RegisterVariable(sv_spectatormaxspeed);
CVar_RegisterVariable(sv_airmove);
CVar_RegisterVariable(sv_accelerate);
CVar_RegisterVariable(sv_airaccelerate);
CVar_RegisterVariable(sv_wateraccelerate);
CVar_RegisterVariable(sv_stepsize);
CVar_RegisterVariable(edgefriction);
CVar_RegisterVariable(sv_waterfriction);
CVar_RegisterVariable(sv_zmax);
CVar_RegisterVariable(sv_wateramp);
CVar_RegisterVariable(sv_skyname);
CVar_RegisterVariable(sv_skycolor_r);
CVar_RegisterVariable(sv_skycolor_g);
CVar_RegisterVariable(sv_skycolor_b);
CVar_RegisterVariable(sv_skyvec_x);
CVar_RegisterVariable(sv_skyvec_y);
CVar_RegisterVariable(sv_skyvec_z);
CVar_RegisterVariable(sv_rollangle);
CVar_RegisterVariable(sv_rollspeed);

// SVRcon
CVar_RegisterVariable(rcon_password);
CVar_RegisterVariable(sv_rcon_minfailures);
CVar_RegisterVariable(sv_rcon_maxfailures);
CVar_RegisterVariable(sv_rcon_minfailuretime);
CVar_RegisterVariable(sv_rcon_banpenalty);

if COM_CheckParm('-dev') > 0 then
 CVar_DirectSet(sv_cheats, '1');

for I := 0 to MAX_MODELS - 1 do
 begin
  LocalModels[I][1] := '*';
  IntToStr(I, LocalModels[I][2], SizeOf(LocalModels[0]) - 1);
 end;

SVS.Secure := 0;

for I := 0 to SVS.MaxClientsLimit - 1 do
 SV_InitClient(SVS.Clients[I]);

PM_Init(@ServerMove);
SV_InitDeltas;
end;

procedure SV_Shutdown;
begin
SV_ClearPrecachedEvents;
SV_ClearClientFrames;
SV_ClearClients;
SV_FreeAllUserMsgs;
SV_FreeLogNodes;
end;

end.
