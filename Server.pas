unit Server;

{$I HLDS.inc}

interface

uses SVExport, Default, SDK;

procedure SV_ServerDeactivate;
procedure SV_ActivateServer(B: Boolean);
function SV_SpawnServer(Map, StartSpot: PLChar): Boolean;

procedure SV_Init;
procedure SV_Shutdown;

var
 sv_aim: TCVar = (Name: 'sv_aim'; Data: '1'; Flags: [FCVAR_ARCHIVE]);
 sv_clienttrace: TCVar = (Name: 'sv_clienttrace'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_lan: TCVar = (Name: 'sv_lan'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_lan_rate: TCVar = (Name: 'sv_lan_rate'; Data: '20000');

 sv_logbans: TCVar = (Name: 'sv_logbans'; Data: '1');
 sv_log_onefile: TCVar = (Name: 'sv_log_onefile'; Data: '0');
 sv_log_singleplayer: TCVar = (Name: 'sv_log_singleplayer'; Data: '0');
 mp_logecho: TCVar = (Name: 'mp_logecho'; Data: '1');
 mp_logfile: TCVar = (Name: 'mp_logfile'; Data: '1');

 logsdir: TCVar = (Name: 'logsdir'; Data: 'logs');
 mapcyclefile: TCVar = (Name: 'mapcyclefile'; Data: 'mapcycle.txt');
 motdfile: TCVar = (Name: 'motdfile'; Data: 'motd.txt');
 servercfgfile: TCVar = (Name: 'servercfgfile'; Data: 'server.cfg');
 mapchangecfgfile: TCVar = (Name: 'mapchangecfgfile'; Data: '');
 lservercfgfile: TCVar = (Name: 'lservercfgfile'; Data: 'listenserver.cfg');
 bannedcfgfile: TCVar = (Name: 'bannedcfgfile'; Data: 'banned.cfg');

 mp_footsteps: TCVar = (Name: 'mp_footsteps'; Data: '1'; Flags: [FCVAR_SERVER]);

 sv_voicecodec: TCVar = (Name: 'sv_voicecodec'; Data: 'voice_speex'; Flags: [FCVAR_SERVER]);
 sv_voiceenable: TCVar = (Name: 'sv_voiceenable'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_voicequality: TCVar = (Name: 'sv_voicequality'; Data: '5'; Flags: [FCVAR_SERVER]);

 mp_consistency: TCVar = (Name: 'mp_consistency'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_downloadurl: TCVar = (Name: 'sv_downloadurl'; Data: ''; Flags: [FCVAR_PROTECTED]);

 sv_filterban: TCVar = (Name: 'sv_filterban'; Data: '1');
 sv_outofdatetime: TCVar = (Name: 'sv_outofdatetime'; Data: '1800'); // outdated?
 sv_visiblemaxplayers: TCVar = (Name: 'sv_visiblemaxplayers'; Data: '-1');
 sv_timeout: TCVar = (Name: 'sv_timeout'; Data: '60'; Flags: [FCVAR_SERVER]);

 sv_newunit: TCVar = (Name: 'sv_newunit'; Data: '0');
 sv_clipmode: TCVar = (Name: 'sv_clipmode'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_password: TCVar = (Name: 'sv_password'; Data: ''; Flags: [FCVAR_SERVER, FCVAR_PROTECTED]);

 sv_cheats: TCVar = (Name: 'sv_cheats'; Data: '0'; Flags: [FCVAR_SERVER]);

 sv_version: TCVar = (Name: 'sv_version'; Data: ''; Flags: [FCVAR_SERVER]);

 // custom
 sv_sendmapcrc: TCVar = (Name: 'sv_sendmapcrc'; Data: '1');
 sv_mapcycle_length: TCVar = (Name: 'sv_mapcycle_length'; Data: '8192');
 sv_secureflag: TCVar = (Name: 'sv_secureflag'; Data: '0'; Flags: [FCVAR_SERVER]);

 sv_sendentsinterval: TCVar = (Name: 'sv_sendentsinterval'; Data: '0.75');
 sv_sendresinterval: TCVar = (Name: 'sv_sendresinterval'; Data: '1.35');
 sv_fullupdateinterval: TCVar = (Name: 'sv_fullupdateinterval'; Data: '1.1');

 NullString: PLChar = #0;

 CurrentSkill: Int;
 AllowCheats: Boolean = False; // SV_SpawnServer
 
 SVDecalNameCount: UInt;
 SVDecalNames: array[0..MAX_DECAL_NAMES - 1] of array[1..MAX_LUMP_NAME + 1] of LChar;
 
 SVUpdateBackup: UInt = 8;
 SVUpdateMask: UInt = 7;

 SVPlayer: PEdict; 

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
  PrecachedGeneric: array[0..MAX_GENERIC_ITEMS - 1] of PLChar; // 209740
  PrecachedResGeneric: array[0..MAX_GENERIC_ITEMS - 1] of array[1..64] of LChar; // 211788
  NumResGeneric: UInt32; // 244556
  LightStyles: array[0..MAX_LIGHTSTYLES - 1] of PLChar; // 244560
  NumEdicts: UInt32; // 244816 L
  MaxEdicts: UInt32; // 244820 L
  Edicts: ^TEdictArray; // 244824 L
  EntityState: ^TEntityStateArray; // 244828 L
  Baseline: PServerBaseline; // 244832, cf
  State: (SS_OFF = 0, SS_LOADING, SS_ACTIVE); // 244836 L
  Datagram: TSizeBuf; // 244840 L
  DatagramData: array[1..4000] of Byte; // 244860 size cf
  ReliableDatagram: TSizeBuf; // 248860 L check check
  ReliableDatagramData: array[1..4000] of Byte; // 248880 L size cf
  Multicast: TSizeBuf; // 252880 L
  MulticastData: array[1..1024] of Byte; // 252900 L size cf
  Spectator: TSizeBuf; // 253924 L
  SpectatorData: array[1..1024] of Byte; // 253944 L size cf
  Signon: TSizeBuf; // 254968 L
  SignonData: array[1..32768] of Byte; // 254988 L size not cf

  // custom fields

  
 end = (Active: False); // 287756 on 48patch

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
   NextStatClear, NextStatUpdate: Double;
   NumStats: UInt32;

   TimesNearlyFull, TimesNearlyEmpty: UInt32;
   NearlyFullPercent, NearlyEmptyPercent: Single;
   MinClientsEver, MaxClientsEver: UInt32;
   AccumServerFull, AvgServerFull: Single;

   NumDrops: UInt32;
   AccumTimePlaying, AvgTimePlaying: Single;
   AccumLatency, AvgLatency: Single;

   TimesFull, TimesEmpty: UInt32;
  end;

  Secure: UInt32;
 end = ();

 HostClient: PClient = nil;

 EngFuncs: TEngineFuncs = (
  PrecacheModel: PF_PrecacheModel;
  PrecacheSound: PF_PrecacheSound;
  SetModel: PF_SetModel;
  ModelIndex: PF_ModelIndex;
  ModelFrames: PF_ModelFrames;
  SetSize: PF_SetSize;
  ChangeLevel: PF_ChangeLevel;
  SetSpawnParms: PF_SetSpawnParms;
  SaveSpawnParms: PF_SaveSpawnParms;
  VecToYaw: PF_VecToYaw;
  VecToAngles: PF_VecToAngles;
  MoveToOrigin: PF_MoveToOrigin;
  ChangeYaw: PF_ChangeYaw;
  ChangePitch: PF_ChangePitch;
  FindEntityByString: PF_FindEntityByString;
  GetEntityIllum: PF_GetEntityIllum;
  FindEntityInSphere: PF_FindEntityInSphere;
  FindClientInPVS: PF_CheckClient;
  EntitiesInPVS: PF_PVSFindEntities;
  MakeVectors: PF_MakeVectors;
  AngleVectors: PF_AngleVectors;
  
  CreateEntity: PF_Spawn;
  RemoveEntity: PF_Remove;
  CreateNamedEntity: PF_CreateNamedEntity;

  MakeStatic: PF_MakeStatic;
  EntIsOnFloor: PF_CheckBottom;
  DropToFloor: PF_DropToFloor;
  WalkMove: PF_WalkMove;
  SetOrigin: PF_SetOrigin;
  EmitSound: PF_Sound;
  EmitAmbientSound: PF_AmbientSound;
  
  TraceLine: PF_TraceLine;
  TraceToss: PF_TraceToss;
  TraceMonsterHull: PF_TraceMonsterHull;
  TraceHull: PF_TraceHull;
  TraceModel: PF_TraceModel;
  TraceTexture: PF_TraceTexture;
  TraceSphere: PF_TraceSphere;

  GetAimVector: PF_Aim;
  ServerCommand: PF_LocalCmd;
  ServerExecute: PF_LocalExec;
  ClientCommand: PF_StuffCmd;
  ParticleEffect: PF_Particle;
  LightStyle: PF_LightStyle;
  DecalIndex: PF_DecalIndex;
  PointContents: PF_PointContents;
  
  MessageBegin: PF_MessageBegin;
  MessageEnd: PF_MessageEnd;
  WriteByte: PF_WriteByte;
  WriteChar: PF_WriteChar;
  WriteShort: PF_WriteShort;
  WriteLong: PF_WriteLong;
  WriteAngle: PF_WriteAngle;
  WriteCoord: PF_WriteCoord;
  WriteString: PF_WriteString;
  WriteEntity: PF_WriteEntity;

  CVarRegister: PF_CVarRegister;
  CVarGetFloat: PF_CVarGetFloat;
  CVarGetString: PF_CVarGetString;
  CVarSetFloat: PF_CVarSetFloat;
  CVarSetString: PF_CVarSetString;
  AlertMessage: PF_AlertMessage;
  EngineFPrintF: PF_EngineFPrintF;

  PvAllocEntPrivateData: PF_PvAllocEntPrivateData;
  PvEntPrivateData: PF_PvEntPrivateData;
  FreeEntPrivateData: PF_FreeEntPrivateData;
  SzFromIndex: PF_SzFromIndex;
  AllocEngineString: PF_AllocEngineString;
  GetVarsOfEnt: PF_GetVarsOfEnt;
  PEntityOfEntOffset: PF_PEntityOfEntOffset;
  EntOffsetOfPEntity: PF_EntOffsetOfPEntity;
  IndexOfEdict: PF_IndexOfEdict;
  PEntityOfEntIndex: PF_PEntityOfEntIndex;
  FindEntityByVars: PF_FindEntityByVars;

  GetModelPtr: PF_GetModelPtr;
  RegUserMsg: PF_RegUserMsg;
  AnimationAutomove: PF_AnimationAutomove;
  GetBonePosition: PF_GetBonePosition;
  FunctionFromName: PF_FunctionFromName;
  NameForFunction: PF_NameForFunction;

  ClientPrintF: PF_ClientPrintF;
  ServerPrint: PF_ServerPrint;
  Cmd_Args: PF_Cmd_Args;
  Cmd_Argv: PF_Cmd_Argv;
  Cmd_Argc: PF_Cmd_Argc;

  GetAttachment: PF_GetAttachment;

  CRC32_Init: PF_CRC32_Init;
  CRC32_ProcessBuffer: PF_CRC32_ProcessBuffer;
  CRC32_ProcessByte: PF_CRC32_ProcessByte;
  CRC32_Final: PF_CRC32_Final;

  RandomLong: PF_RandomLong;
  RandomFloat: PF_RandomFloat;

  SetView: PF_SetView;
  Time: PF_Time;
  CrosshairAngle: PF_CrosshairAngle;
  LoadFileForMe: PF_LoadFileForMe;
  FreeFile: PF_FreeFile;
  EndSection: PF_EndSection;
  CompareFileTime: PF_CompareFileTime;
  GetGameDir: PF_GetGameDir;

  CVar_RegisterVariable: PF_CVar_RegisterVariable;
  FadeClientVolume: PF_FadeVolume;
  SetClientMaxSpeed: PF_SetClientMaxSpeed;

  CreateFakeClient: PF_CreateFakeClient;
  RunPlayerMove: PF_RunPlayerMove;
  NumberOfEntities: PF_NumberOfEntities;
  GetInfoKeyBuffer: PF_GetInfoKeyBuffer;
  InfoKeyValue: PF_InfoKeyValue;
  SetKeyValue: PF_SetKeyValue;
  SetClientKeyValue: PF_SetClientKeyValue;
  IsMapValid: PF_IsMapValid;
  StaticDecal: PF_StaticDecal;
  PrecacheGeneric: PF_PrecacheGeneric;
  GetPlayerUserID: PF_GetPlayerUserID;
  BuildSoundMsg: PF_BuildSoundMsg;
  IsDedicatedServer: PF_IsDedicatedServer;
  CVarGetPointer: PF_CVarGetPointer;
  GetPlayerWONID: PF_GetPlayerWONID;

  Info_RemoveKey: PF_RemoveKey;
  GetPhysicsKeyValue: PF_GetPhysicsKeyValue;
  SetPhysicsKeyValue: PF_SetPhysicsKeyValue;
  GetPhysicsInfoString: PF_GetPhysicsInfoString;

  PrecacheEvent: PF_PrecacheEvent;
  PlaybackEvent: PF_PlaybackEvent;

  SetFatPVS: PF_SetFatPVS;
  SetFatPAS: PF_SetFatPAS;
  CheckVisibility: PF_CheckVisibility;

  DeltaSetField: PF_Delta_SetField;
  DeltaUnsetField: PF_Delta_UnsetField;
  DeltaAddEncoder: PF_Delta_AddEncoder;
  GetCurrentPlayer: PF_GetCurrentPlayer;
  CanSkipPlayer: PF_CanSkipPlayer;
  DeltaFindField: PF_Delta_FindField;
  DeltaSetFieldByIndex: PF_Delta_SetFieldByIndex;
  DeltaUnsetFieldByIndex: PF_Delta_UnsetFieldByIndex;

  SetGroupMask: PF_SetGroupMask;
  CreateInstancedBaseline: PF_CreateInstancedBaseline;
  CVar_DirectSet: PF_CVar_DirectSet;
  ForceUnmodified: PF_ForceUnmodified;
  GetPlayerStats: PF_GetPlayerStats;
  AddServerCommand: PF_AddServerCommand;
  Voice_GetClientListening: PF_Voice_GetClientListening;
  Voice_SetClientListening: PF_Voice_SetClientListening;

  GetPlayerAuthID: PF_GetPlayerAuthID;

  SequenceGet: PF_SequenceGet;
  SequencePickSentence: PF_SequencePickSentence;

  GetFileSize: PF_GetFileSize;
  GetApproxWavePlayLength: PF_GetApproxWavePlayLength;

  IsCareerMatch: PF_VGUI2_IsCareerMatch;
  GetLocalizedStringLength: PF_VGUI2_GetLocalizedStringLength;
  RegisterTutorMessageShown: PF_RegisterTutorMessageShown;
  GetTimesTutorMessageShown: PF_GetTimesTutorMessageShown;
  ProcessTutorMessageDecayBuffer: PF_ProcessTutorMessageDecayBuffer;
  ConstructTutorMessageDecayBuffer: PF_ConstructTutorMessageDecayBuffer;
  ResetTutorMessageDecayData: PF_ResetTutorMessageDecayData;

  QueryClientCVarValue: PF_QueryClientCVarValue;
  QueryClientCVarValue2: PF_QueryClientCVarValue2;
  CheckParm: PF_EngCheckParm;

  ReservedStart: PF_Reserved;
  Reserved1: PF_Reserved;
  Reserved2: PF_Reserved;
  Reserved3: PF_Reserved;
  Reserved4: PF_Reserved;
  Reserved5: PF_Reserved;
  Reserved6: PF_Reserved;
  Reserved7: PF_Reserved;
  Reserved8: PF_Reserved;
  Reserved9: PF_Reserved;
  ReservedEnd: PF_Reserved;
 );

 GlobalVars: TGlobalVars;
 MoveVars: TMoveVars;

 PRStrings: UInt;

implementation

uses Common, Console, Edict, Encode, GameLib, Host, HPAK, Memory, Model, Network, PMove, Resource, SVClient, SVCmds, SVDelta, SVEdict, SVMain, SVMove, SVPacket, SVPhys, SVRcon, SVSend, SVWorld, SysArgs;

procedure SV_ServerDeactivate;
begin
GlobalVars.Time := SV.Time;
if SVS.InitGameDLL and SV.Active then
 DLLFunctions.ServerDeactivate;
end;

procedure SV_ActivateServer(B: Boolean);
var
 SB: TSizeBuf;
 SBData: array[1..65536] of Byte;
 I: Int;
 OldUserMsgs: PUserMsg;
begin
SB.Name := 'Activate Server';
SB.AllowOverflow := [];
SB.Data := @SBData;
SB.CurrentSize := 0;
SB.MaxSize := SizeOf(SBData);

SetCStrikeFlags;
CVar_DirectSet(sv_newunit, '0');
DLLFunctions.ServerActivate(SV.Edicts[0], SV.NumEdicts, SVS.MaxClients);
SV_CreateGenericResources;
SV.Active := True;
SV.State := SS_ACTIVE;

if not B then
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
SV.NumConsistency := SV_TransferConsistencyInfo;

for I := 0 to SVS.MaxClients - 1 do
 begin
  HostClient := @SVS.Clients[I];
  if (HostClient.Active or HostClient.Connected) and not HostClient.FakeClient then
   begin
    Netchan_Clear(HostClient.Netchan);
    if SVS.MaxClients > 1 then
     begin
      SV_BuildReconnect(HostClient.Netchan.NetMessage);
      Netchan_Transmit(HostClient.Netchan, 0, nil);
     end
    else
     SV_SendServerInfo(SB, HostClient^);

    if UserMsgs <> nil then
     begin
      OldUserMsgs := NewUserMsgs;
      NewUserMsgs := UserMsgs;
      SV_SendUserReg(SB);
      NewUserMsgs := OldUserMsgs;
     end;
    HostClient.UserMsgReady := True;

    Netchan_CreateFragments(HostClient.Netchan, SB);
    Netchan_FragSend(HostClient.Netchan);
    SZ_Clear(SB);
   end;
 end;

HPAK_FlushHostQueue;
if SVS.MaxClients <= 1 then
 Print('Game started.')
else
 Print(['Started the server on ', PLChar(@SV.Map), ' with ', SVS.MaxClients, ' max players.']);

LPrint(['Started map "', PLChar(@SV.Map), '" (CRC "', SV.WorldModelCRC, '")'#10]);

if (mapchangecfgfile.Data <> nil) and (mapchangecfgfile.Data^ > #0) then
 begin
  PF_AlertMessage(atConsole, 'Executing map change config file.');
  CBuf_AddText(['exec "', mapchangecfgfile.Data, '"'#10]);
 end;
end;

function SV_SpawnServer(Map, StartSpot: PLChar): Boolean;
var
 I: Int;
 L: UInt;
 C: PClient;
 S: PLChar;
 MapNameBuf: array[1..MAX_MAP_NAME] of LChar;
begin
Result := False;
if SV.Active then
 for I := 0 to SVS.MaxClients - 1 do
  begin
   C := @SVS.Clients[I];
   if (C.Active or C.Spawned or C.Connected) and (C.Entity <> nil) and (C.Entity.Free = 0) then
    if C.Entity.PrivateData <> nil then
     DLLFunctions.ClientDisconnect(C.Entity^)
    else
     DPrint(['SV_SpawnServer: Skipping reconnect on "', PLChar(@C.NetName), '", no private entity data.']);
  end;

L := StrLen(Map);
if L >= MAX_MAP_NAME - 9 then
 begin
  Print('Couldn''t spawn server, map name is too big.');
  SV.Active := False;
  Exit;
 end;

Log_Open;
LPrint(['Loading map "', Map, '"'#10]);
Log_PrintServerVars;
NET_Config(SVS.MaxClients > 1);

if hostname.Data = #0 then
 begin
  S := DLLFunctions.GetGameDescription;
  if S <> nil then
   CVar_DirectSet(hostname, S)
  else
   CVar_DirectSet(hostname, ProjectName);
 end;

if StartSpot <> nil then
 DPrint(['Spawned server ', Map, ': [', StartSpot, '].'])
else
 DPrint(['Spawned server ', Map, '.']);

Inc(SVS.SpawnCount);
if coop.Value <> 0 then
 CVar_DirectSet(deathmatch, '0');

CurrentSkill := Trunc(skill.Value + 0.5);
if CurrentSkill < 0 then
 CurrentSkill := 0
else
 if CurrentSkill > 3 then
  CurrentSkill := 3;
CVar_SetValue('skill', CurrentSkill);

HPAK_CheckSize('custom');
if SV.Map[Low(SV.Map)] > #0 then
 StrCopy(@MapNameBuf, @SV.Map)
else
 MapNameBuf[Low(MapNameBuf)] := #0;

Host_ClearMemory(False);
SV_ClearClientFrames;

if SVS.MaxClients <> 1 then
 SVUpdateBackup := 64
else
 SVUpdateBackup := 8;
SVUpdateMask := SVUpdateBackup - 1;

SV_AllocClientFrames;
MemSet(SV, SizeOf(SV), 0);

StrCopy(@SV.PrevMap, @MapNameBuf);
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
SV_DeallocateDynamicData;
SV_ReallocateDynamicData;

GlobalVars.MaxEntities := SV.MaxEdicts;
GlobalVars.MaxClients := SVS.MaxClients;
SV.Edicts := Hunk_AllocName(SizeOf(TEdict) * SV.MaxEdicts, 'edicts');
SV.EntityState := Hunk_AllocName(SizeOf(TEntityState) * SV.MaxEdicts, 'baselines');

SV.Datagram.Name := 'Server Datagram';
SV.Datagram.Data := @SV.DatagramData;
SV.Datagram.MaxSize := SizeOf(SV.DatagramData);
SV.ReliableDatagram.Name := 'Server Reliable Datagram';
SV.ReliableDatagram.Data := @SV.ReliableDatagramData;
SV.ReliableDatagram.MaxSize := SizeOf(SV.ReliableDatagramData);
SV.Multicast.Name := 'Server Multicast Buffer';
SV.Multicast.Data := @SV.MulticastData;
SV.Multicast.MaxSize := SizeOf(SV.MulticastData);
SV.Spectator.Name := 'Server Spectator Buffer';
SV.Spectator.Data := @SV.SpectatorData;
SV.Spectator.MaxSize := SizeOf(SV.SpectatorData);
SV.Signon.Name := 'Server Signon Buffer';
SV.Signon.Data := @SV.SignonData;
SV.Signon.MaxSize := SizeOf(SV.SignonData);

SV.NumEdicts := SVS.MaxClients + 1;
for I := 0 to SVS.MaxClients - 1 do
 SVS.Clients[I].Entity := @SV.Edicts[I + 1];

SV.State := SS_LOADING;
SV.Paused := False;
SV.Time := 1;
GlobalVars.Time := 1;

S := StrECopy(@SV.MapFileName, 'maps/');
S := StrLECopy(S, Map, SizeOf(SV.MapFileName) - 10);
StrCopy(S, '.bsp');  

SV.WorldModel := Mod_ForName(@SV.MapFileName, False, False);
if SV.WorldModel = nil then
 begin
  Print(['Couldn''t spawn server: "', PLChar(@SV.MapFileName), '" failed to load.']);
  SV.Active := False;
  Exit;
 end;

S := 'cl_dlls' + CorrectSlash + 'client.dll';
if not MD5_Hash_File(SV.ClientDLLHash, S, False, False, nil) then
 DPrint(['Couldn''t CRC client-side DLL: "', S, '", ignoring.']);

if SVS.MaxClients <= 1 then
 SV.WorldModelCRC := 0
else
 begin
  CRC32_Init(SV.WorldModelCRC);
  if not CRC_MapFile(SV.WorldModelCRC, @SV.MapFileName) then
   begin
    Print(['Couldn''t CRC server map: "', PLChar(@SV.MapFileName), '".']);
    SV.Active := False;
    Exit;
   end;
 end;

CM_CalcPAS(SV.WorldModel^);

SV.PrecachedModels[1] := SV.WorldModel;
SV_ClearWorld;
SV.PrecachedSoundNames[0] := Pointer(PRStrings);
SV.PrecachedModelNames[0] := Pointer(PRStrings);
SV.PrecachedModelNames[1] := @SV.MapFileName;
SV.PrecachedGeneric[0] := Pointer(PRStrings);
Include(SV.PrecachedModelFlags[1], RES_FATALIFMISSING);

if SV.WorldModel.NumSubModels >= MAX_MODELS - 2 then
 begin
  Print('Can''t start the server, too many submodels at the map.');
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

if coop.Value = 0 then
 GlobalVars.Deathmatch := deathmatch.Value
else
 GlobalVars.Coop := coop.Value;

GlobalVars.ServerFlags := SVS.ServerFlags;
GlobalVars.MapName := UInt(@SV.Map) - PRStrings;
GlobalVars.StartSpot := UInt(@SV.StartSpot) - PRStrings;
AllowCheats := sv_cheats.Value <> 0;
SV_SetMoveVars;
Result := True;
end;

procedure SV_Init;
var
 I: Int;
 C: PClient;
begin
// banid, removeid, listid, writeid, resetrcon
Cmd_AddCommand('logaddress', @SV_SetLogAddress_F);
Cmd_AddCommand('logaddress_add', @SV_AddLogAddress_F);
Cmd_AddCommand('logaddress_del', @SV_DelLogAddress_F);
Cmd_AddCommand('log', @SV_ServerLog_F);
Cmd_AddCommand('serverinfo', @SV_Serverinfo_F);
Cmd_AddCommand('localinfo', @SV_Localinfo_F);
Cmd_AddCommand('showinfo', @SV_ShowServerinfo_F);
Cmd_AddCommand('user', @SV_User_F);
Cmd_AddCommand('users', @SV_Users_F);
Cmd_AddCommand('dlfile', @SV_BeginFileDownload_F);
// addip, removeip, listip, writeip
Cmd_AddCommand('dropclient', @SV_Drop_F);
Cmd_AddCommand('spawn', @SV_Spawn_F);
Cmd_AddCommand('new', @SV_New_F);
Cmd_AddCommand('sendres', @SV_SendRes_F);
Cmd_AddCommand('sendents', @SV_SendEnts_F);
Cmd_AddCommand('fullupdate', @SV_FullUpdate_F);

// custom
Cmd_AddCommand('entcount', @ED_Count);

// Custom
CVar_RegisterVariable(sv_allow47p);
CVar_RegisterVariable(sv_allow48p);
CVar_RegisterVariable(sv_maxipsessions);
CVar_RegisterVariable(sv_fullservermsg);
CVar_RegisterVariable(sv_limit_queries);
CVar_RegisterVariable(max_query_ips);
CVar_RegisterVariable(sv_enableoldqueries);
CVar_RegisterVariable(sv_mapcycle_length);
CVar_RegisterVariable(sv_secureflag);
CVar_RegisterVariable(sv_sendmapcrc);
CVar_RegisterVariable(sv_fullupdateinterval);
CVar_RegisterVariable(sv_sendentsinterval);
CVar_RegisterVariable(sv_sendresinterval);


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

// SVEdict
CVar_RegisterVariable(sv_instancedbaseline);

// SVMain custom
CVar_RegisterVariable(sv_stats);
CVar_RegisterVariable(sv_statsinterval);
CVar_RegisterVariable(sv_statsmax);

// SVMove
CVar_RegisterVariable(sv_maxunlag);
CVar_RegisterVariable(sv_unlag);
CVar_RegisterVariable(sv_unlagpush);
CVar_RegisterVariable(sv_unlagsamples);
CVar_RegisterVariable(sv_cmdcheckinterval);



// Default

CVar_RegisterVariable(sv_voicecodec);
CVar_RegisterVariable(sv_voiceenable);
CVar_RegisterVariable(sv_voicequality);
CVar_RegisterVariable(rcon_password);
CVar_RegisterVariable(mp_consistency);
CVar_RegisterVariable(sv_contact);
CVar_RegisterVariable(sv_region);
CVar_RegisterVariable(sv_filterban);
CVar_RegisterVariable(sv_logrelay);
CVar_RegisterVariable(sv_lan);
if PF_IsDedicatedServer > 0 then
 CVar_DirectSet(sv_lan, '0')
else
 CVar_DirectSet(sv_lan, '1');

CVar_RegisterVariable(sv_lan_rate);
CVar_RegisterVariable(sv_proxies);
CVar_RegisterVariable(sv_outofdatetime);
CVar_RegisterVariable(sv_visiblemaxplayers);
CVar_RegisterVariable(sv_password);
CVar_RegisterVariable(sv_aim);
// hblood/hgibs skipped
CVar_RegisterVariable(sv_newunit);

CVar_RegisterVariable(sv_gravity);
CVar_RegisterVariable(sv_friction);
CVar_RegisterVariable(edgefriction);
CVar_RegisterVariable(sv_stopspeed);
CVar_RegisterVariable(sv_maxspeed);
CVar_RegisterVariable(mp_footsteps);
CVar_RegisterVariable(sv_accelerate);
CVar_RegisterVariable(sv_stepsize);
CVar_RegisterVariable(sv_clipmode);
CVar_RegisterVariable(sv_bounce);
CVar_RegisterVariable(sv_airmove);
CVar_RegisterVariable(sv_airaccelerate);
CVar_RegisterVariable(sv_wateraccelerate);
CVar_RegisterVariable(sv_waterfriction);

CVar_RegisterVariable(sv_skycolor_r);
CVar_RegisterVariable(sv_skycolor_g);
CVar_RegisterVariable(sv_skycolor_b);
CVar_RegisterVariable(sv_skyvec_x);
CVar_RegisterVariable(sv_skyvec_y);
CVar_RegisterVariable(sv_skyvec_z);

CVar_RegisterVariable(sv_timeout);
CVar_RegisterVariable(sv_clienttrace);
CVar_RegisterVariable(sv_zmax);
CVar_RegisterVariable(sv_wateramp);
CVar_RegisterVariable(sv_skyname);
CVar_RegisterVariable(sv_maxvelocity);
CVar_RegisterVariable(sv_cheats);
if COM_CheckParm('-dev') > 0 then
 CVar_DirectSet(sv_cheats, '1');

CVar_RegisterVariable(sv_spectatormaxspeed);

CVar_RegisterVariable(sv_logbans);
CVar_RegisterVariable(hpk_maxsize);

CVar_RegisterVariable(mapcyclefile);
CVar_RegisterVariable(motdfile);
CVar_RegisterVariable(servercfgfile);
CVar_RegisterVariable(mapchangecfgfile);
CVar_RegisterVariable(lservercfgfile);
CVar_RegisterVariable(logsdir);
CVar_RegisterVariable(bannedcfgfile);
// rcon skipped

CVar_RegisterVariable(max_queries_sec);
CVar_RegisterVariable(max_queries_sec_global);
CVar_RegisterVariable(max_queries_window);

CVar_RegisterVariable(sv_logblocks);
CVar_RegisterVariable(sv_downloadurl);
CVar_RegisterVariable(sv_version);

for I := 0 to MAX_MODELS - 1 do
 begin
  LocalModels[I][1] := '*';
  IntToStr(I, LocalModels[I][2], SizeOf(LocalModels[I]) - 1);
 end;

SVS.Secure := 0;

for I := 0 to SVS.MaxClientsLimit - 1 do
 begin
  C := @SVS.Clients[I];
  SV_ClearFrames(C.Frames);

  MemSet(C^, SizeOf(C^), 0);
  SV_SetResourceLists(C^);
 end;

PM_Init(@ServerMove);
SV_AllocClientFrames;
SV_InitDeltas;
SV_InitRateFilter;
end;

procedure SV_Shutdown;
begin
SV_ShutdownRateFilter;
SV_ShutdownDeltas;
end;

end.
