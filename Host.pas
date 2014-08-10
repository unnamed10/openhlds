unit Host;

// hostcmds for commands

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

function Host_SaveGameDirectory: PLChar;
procedure Host_ClearSaveDirectory;
function Host_IsSinglePlayerGame: Boolean;
procedure Host_ClearGameState;

procedure Host_Map(Name: PLChar; Save: Boolean);

procedure Host_Say(Team: Boolean);

procedure Host_EndSection(Name: PLChar);
procedure Host_ClearClients(KeepFrames: Boolean);

procedure Host_ClearMemory(B: Boolean);

procedure Host_Error(Msg: PLChar); overload;
procedure Host_Error(const Msg: array of const); overload;

procedure Host_ShutdownServer(SkipNotify: Boolean);
procedure Host_ClientCommands(S: PLChar);

function Host_Frame: Boolean;

procedure Host_Init;
procedure Host_Shutdown;

var
 console_cvar: TCVar = (Name: 'console'; Data: '0');
 developer: TCVar = (Name: 'developer'; Data: '0');
 deathmatch: TCVar = (Name: 'deathmatch'; Data: '0'; Flags: [FCVAR_SERVER]);
 coop: TCVar = (Name: 'coop'; Data: '0'; Flags: [FCVAR_SERVER]);
 hostname: TCVar = (Name: 'hostname'; Data: ProjectName + ' v' + ProjectVersion + ' server');
 skill: TCVar = (Name: 'skill'; Data: '1');

 hostmap: TCVar = (Name: 'HostMap'; Data: '');

 host_killtime: TCVar = (Name: 'host_killtime'; Data: '0');

 sys_ticrate: TCVar = (Name: 'sys_ticrate'; Data: '100'; Flags: [FCVAR_SERVER]);
 sys_maxframetime: TCVar = (Name: 'sys_maxframetime'; Data: '0.25');
 sys_minframetime: TCVar = (Name: 'sys_minframetime'; Data: '0.001');

 sys_timescale: TCVar = (Name: 'sys_timescale'; Data: '1');
 host_limitlocal: TCVar = (Name: 'host_limitlocal'; Data: '0');
 host_framerate: TCVar = (Name: 'host_framerate'; Data: '0');
 host_speeds: TCVar = (Name: 'host_speeds'; Data: '0');
 host_profile: TCVar = (Name: 'host_profile'; Data: '0');


 // custom

 // 0/1: toggle, 2: password
 pausable: TCVar = (Name: 'pausable'; Data: '0'; Flags: [FCVAR_SERVER]);
 // password for pause control
 pausablepwd: TCVar = (Name: 'pausablepwd'; Data: ''; Flags: [FCVAR_PROTECTED]);

 HostInit: Boolean = False;
 HostInfo: THostParms;

 RealTime: Double = 0;
 OldRealTime: Double = 0;

 HostActive: UInt32 = 0; // unused?
 HostSubState: UInt32 = 0;
 HostStateInfo: UInt32 = 0;

 LowViolenceBuild: Boolean = False;
 QuitCommandIssued: Boolean = False;

 // gamedir
 BaseDir: PLChar; // C:\HLDS
 GameDir: PLChar; // cstrike
 DefaultGameDir: PLChar; // valve
 FallbackDir: PLChar;
 LangName: PLChar = 'english';

 UseAddonsDir, UseHDModels: Boolean;

 CSFlagsInitialized: Boolean = False;
 IsCStrike: Boolean = False;
 IsCZero: Boolean = False;
 IsCZeroRitual: Boolean = False;
 IsTerrorStrike: Boolean = False;

 InHostError: Boolean = False;
 InHostShutdown: Boolean = False;

 WADPath: PLChar;

 HostHunkLevel: UInt;

 HostFrameTime: Double;
 HostFrameCount: UInt = 0;
 SCRSkipUpdate: Boolean;

 HostTimes: record
  Cur, Prev, Frame: Double;

  CollectData: Boolean;
  Host, SV, Rcon: Double;
 end = (CollectData: False);

 TimeCount: UInt;
 TimeTotal: Double;

 CmdLineTicrateCheck: Boolean = False;
 CmdLineTicrate: UInt = 0;

 RollingFPS: Double = 0;

implementation

uses Common, Console, Decal, Delta, Edict, Encode, GameLib, HostCmds, HostSave, HPAK, Memory, Model, MsgBuf, Network, Renderer, Resource, Server, StdUI, SVClient, SVEdict, SVEvent, SVExport, SVMain, SVPacket, SVPhys, SVRcon, SVSend, SVWorld, SysMain, SysArgs, SysClock, Texture;

function Host_SaveGameDirectory: PLChar;
begin
Result := 'SAVE' + CorrectSlash;
end;

procedure Host_ClearSaveDirectory;
begin

end;

procedure Host_ClearGameState;
begin
Host_ClearSaveDirectory;
DLLFunctions.ResetGlobalState;
end;

function Host_IsSinglePlayerGame: Boolean;
begin
Result := SV.Active and (SVS.MaxClients = 1);
end;

procedure Host_EndSection(Name: PLChar);
begin
HostActive := 2;
HostSubState := 1;
HostStateInfo := 1;

if (Name = nil) or (Name^ = #0) then
 Print('Host_EndSection: EndSection with no arguments.')
else
 if StrIComp(Name, '_oem_end_training') = 0 then
  HostStateInfo := 1
 else
  if StrIComp(Name, '_oem_end_logo') = 0 then
   HostStateInfo := 2
  else
   if StrIComp(Name, '_oem_end_demo') = 0 then
    HostStateInfo := 3
   else
    DPrint('Host_EndSection: EndSection with unknown Section keyvalue.');

CBuf_AddText(#10'disconnect'#10);
end;

procedure Host_ClearClients(KeepFrames: Boolean);
var
 I, J: Int;
 C: PClient;
 Addr: TNetAdr;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  HostClient := C;  
  if C.Frames <> nil then
   for J := 0 to SVUpdateBackup - 1 do
    begin
     SV_ClearPacketEntities(C.Frames[J]);
     C.Frames[J].SentTime := 0;
     C.Frames[J].PingTime := -1;     
    end;

  if C.Netchan.Addr.AddrType <> NA_UNUSED then
   begin
    Addr := C.Netchan.Addr;
    MemSet(C.Netchan, SizeOf(C.Netchan), 0);
    Netchan_Setup(NS_SERVER, C.Netchan, Addr, I, HostClient, SV_GetFragmentSize);
   end;

  COM_ClearCustomizationList(C.Customization);
 end;

if not KeepFrames then
 begin
  SV_ClearClientFrames;
  
  MemSet(SVS.Clients^, SizeOf(TClient) * SVS.MaxClientsLimit, 0);
  SV_AllocClientFrames;
 end;
end;

procedure Host_ClearMemory(B: Boolean);
begin
if not B then
 DPrint('Clearing memory.');

CM_FreePAS;
SV_ClearEntities;
Mod_ClearAll;
if HostHunkLevel > 0 then
 begin
  SV_ClearClientFrames;
  Hunk_FreeToLowMark(HostHunkLevel);
 end;

SV_ClearCaches;
MemSet(SV, SizeOf(SV), 0);
SV_ClearClientStates;
end;

procedure Host_Error(Msg: PLChar);
begin
if InHostError then
 Sys_Error('Host_Error: Recursively entered.');

InHostError := True;
Print(['Host_Error: ', Msg]);
if SV.Active then
 Host_ShutdownServer(False);

Sys_Error(['Host_Error: ', Msg]);
InHostError := False;
end;

procedure Host_Error(const Msg: array of const);
begin
Host_Error(PLChar(StringFromVarRec(Msg)));
end;

procedure Host_ShutdownServer(SkipNotify: Boolean);
var
 I: Int;
begin
if SV.Active then
 begin
  SV_ServerDeactivate;
  SV.Active := False;
  NET_ClearLagData(True, True);
  for I := 0 to SVS.MaxClients - 1 do
   begin
    HostClient := @SVS.Clients[I];
    if HostClient.Active or HostClient.Connected then
     SV_DropClient(HostClient^, SkipNotify, 'Server shutting down.');
   end;
   
  SV_ClearEntities;
  SV_ClearCaches;
  FreeAllEntPrivateData;
  MemSet(SV, SizeOf(SV), 0);
  SV_ClearClientStates;

  Host_ClearClients(False);
  SV_ClearClientFrames;

  MemSet(SVS.Clients^, SizeOf(TClient) * SVS.MaxClientsLimit, 0);
  HPAK_FlushHostQueue;

  LPrint('Server shutdown'#10);
  Log_Close;
 end;
end;

procedure Host_InitLocal;
begin
Host_InitCommands;
Host_InitCVars;
end;

procedure Host_ClientCommands(S: PLChar);
begin
if not HostClient.FakeClient then
 begin
  MSG_WriteByte(HostClient.Netchan.NetMessage, SVC_STUFFTEXT);
  MSG_WriteString(HostClient.Netchan.NetMessage, S);
 end;
end;

procedure Host_Say(Team: Boolean);
var
 Buf: array[1..192] of LChar;
 S, S2: PLChar;
 I: Int;
 C: PClient;
begin
if CmdSource = csServer then
 if Cmd_Argc < 2 then
  Print('Usage: say <message>')  
 else
  begin
   S := Cmd_Args;
   if (S <> nil) and (S^ > #0) and (StrLen(S) <= 96) then
    begin
     S2 := @Buf;
     S2^ := #1;
     Inc(UInt(S2));

     if hostname.Data^ > #0 then
      begin
       S2 := StrECopy(S2, '<');
       S2 := StrLECopy(S2, hostname.Data, 63);
       S2 := StrECopy(S2, '>: ');
      end
     else
      S2 := StrECopy(S2, '<Server>: ');

     if S^ = '"' then
      Inc(UInt(S));
     S2 := StrECopy(S2, S);
     if PLChar(UInt(S2) - 1)^ = '"' then
      Dec(UInt(S2));
     StrCopy(S2, #10);

     for I := 0 to SVS.MaxClients - 1 do
      begin
       C := @SVS.Clients[I];
       if C.Active and not C.FakeClient then
        begin
         PF_MessageBegin(MSG_ONE, PF_RegUserMsg('SayText', -1), nil, @SV.Edicts[I + 1]);
         PF_WriteByte(0);
         PF_WriteString(@Buf);
         PF_MessageEnd;
        end;
      end;

     S2^ := #0;
     Print(['Server say "', PLChar(UInt(@Buf) + 1), '"']);
     LPrint(['Server say "', PLChar(UInt(@Buf) + 1), '"'#10]);
    end;
  end;
end;

procedure Host_Map(Name: PLChar; Save: Boolean);
begin
Host_ShutdownServer(False);
if not Save then
 begin
  Host_ClearGameState;
  SV_InactivateClients;
  SVS.ServerFlags := 0;
 end;

if SV_SpawnServer(Name, nil) then
 begin
  if Save then
   begin
    if not LoadGamestate(Name, True) then
     SV_LoadEntities;

    SV.Paused := True;
    SV.SavedGame := True;
    SV_ActivateServer(False);
   end
  else
   begin
    SV_LoadEntities;
    SV_ActivateServer(True);
    if not SV.Active then
     Exit;
   end;

  SV_LinkNewUserMsgs;
 end;
end;

procedure Host_SetHostTimes;
begin
HostTimes.Cur := Sys_FloatTime;
HostTimes.Frame := HostTimes.Cur - HostTimes.Prev;
if HostTimes.Frame < 0 then
 HostTimes.Frame := 0.001;
HostTimes.Prev := HostTimes.Cur;
end;

function Host_FilterTime(Time: Double): Boolean;
var
 F: Double;
begin
if sys_timescale.Value <= 0 then
 CVar_DirectSet(sys_timescale, '1');

RealTime := RealTime + Time * sys_timescale.Value;

if not CmdLineTicrateCheck then
 begin
  CmdLineTicrateCheck := True;
  CmdLineTicrate := StrToIntDef(COM_ParmValueByName('-sys_ticrate'), 0);
 end;

if CmdLineTicrate = 0 then
 F := sys_ticrate.Value
else
 F := CmdLineTicrate;

if (F > 0) and (RealTime - OldRealTime < (1 / (F + 1))) then
 Result := False
else
 begin
  F := RealTime - OldRealTime;
  OldRealTime := RealTime;
  if sys_maxframetime.Value > 1 then
   sys_maxframetime.Value := 1;

  if F > sys_maxframetime.Value then
   HostFrameTime := sys_maxframetime.Value
  else
   if F < sys_minframetime.Value then
    HostFrameTime := sys_minframetime.Value
   else
    HostFrameTime := F;

  Result := True;
 end;
end;

procedure Host_ComputeFPS(Time: Double);
begin
RollingFPS := RollingFPS * 0.6 + Time * 0.4;
end;

procedure Host_WriteSpeeds;
begin

end;

procedure Host_UpdateStats;
begin

end;

procedure _Host_Frame(Time: Double);
begin
if Host_FilterTime(Time) then
 begin
  Host_ComputeFPS(HostFrameTime);
  CBuf_Execute;
  if HostTimes.CollectData then
   HostTimes.Host := Sys_FloatTime;
  
  SV_Frame;
  if HostTimes.CollectData then
   HostTimes.SV := Sys_FloatTime;

  SV_CheckForRcon;
  if HostTimes.CollectData then
   HostTimes.Rcon := Sys_FloatTime;

  Host_WriteSpeeds;
  Inc(HostFrameCount);
  if sv_stats.Value <> 0 then
   Host_UpdateStats;

  if (host_killtime.Value <> 0) and (host_killtime.Value < SV.Time) then
   CBuf_AddText('quit'#10);

  UI_OnFrame(RealTime);
 end;
end;

function Host_Frame: Boolean;
var
 TimeStart, TimeEnd: Double;
 Profile: Boolean;
 Count: UInt;
 I: Int;
begin
Host_SetHostTimes;

if QuitCommandIssued then
 Result := False
else
 begin
  Profile := host_profile.Value <> 0;
  if not Profile then
   begin
    _Host_Frame(HostTimes.Frame);
    if HostStateInfo <> 0 then
     begin
      HostStateInfo := 0;
      CBuf_Execute;
     end;
   end
  else
   begin
    TimeStart := Sys_FloatTime;
    _Host_Frame(HostTimes.Frame);
    TimeEnd := Sys_FloatTime;

    if HostStateInfo <> 0 then
     begin
      HostStateInfo := 0;
      CBuf_Execute;
     end;

    Inc(TimeCount);
    TimeTotal := TimeTotal + TimeEnd - TimeStart;

    if TimeCount >= 1000 then
     begin
      Count := 0;
      for I := 0 to SVS.MaxClients - 1 do
       if SVS.Clients[I].Active then
        Inc(Count);

      Print(['host_profile: ', Count, ' clients, ', Trunc(TimeTotal * 1000 / TimeCount), ' msec']);
      TimeTotal := 0;
      TimeCount := 0;
     end;
   end;

  Result := True;
 end;
end;

procedure Host_Init;
var
 Buf: array[1..256] of LChar;
 IntBuf: array[1..32] of LChar;
begin
RealTime := 0;
Memory_Init(HostInfo.MemBase, HostInfo.MemSize);

CBuf_Init;
Cmd_Init;
CVar_Init;
CVar_CmdInit;
COM_Init;
Con_Init;

CVar_RegisterVariable(console_cvar);
if (COM_CheckParm('-console') > 0) or (COM_CheckParm('-toconsole') > 0) or (COM_CheckParm('-dev') > 0) then
 CVar_DirectSet(console_cvar, '1');

if COM_CheckParm('-dev') > 0 then
 CVar_DirectSet(developer, '1');

Host_InitLocal;

Host_ClearSaveDirectory;
HPAK_Init;
W_LoadWADFile('gfx.wad');
W_LoadWADFile('fonts.wad');
Decal_Init;
Mod_Init;
NET_Init;
Netchan_Init;
Delta_Init;
SV_Init;

StrLCopy(@Buf, ProjectVersion, SizeOf(Buf) - 1);
StrLCat(@Buf, ',47-48,', SizeOf(Buf) - 1);
StrLCat(@Buf, IntToStr(BuildNumber, IntBuf, SizeOf(IntBuf)), SizeOf(Buf) - 1);
CVar_DirectSet(sv_version, @Buf);

DPrint(['Heap size: ', RoundTo(HostInfo.MemSize div (1024 * 1024), -3), ' MB.']);

R_InitTextures;
CVar_RegisterVariable(r_cachestudio);
HPAK_CheckIntegrity('custom.hpk');

CBuf_InsertText('exec valve.rc'#10);
Hunk_AllocName(0, '-HOST_HUNKLEVEL-');
HostHunkLevel := Hunk_LowMark;

HostActive := 1;
SCRSkipUpdate := False;

HostTimes.Prev := Sys_FloatTime;
HostInit := True;
end;

procedure Host_Shutdown;
begin
if InHostShutdown then
 Sys_DebugOutStraight('Host_Shutdown: Recursive shutdown.')
else
 begin
  InHostShutdown := True;
  SV_ServerDeactivate;
  HostInit := False;

  HPAK_FlushHostQueue;
  SV_DeallocateDynamicData;

  SV_ClearClientFrames;

  SV_Shutdown;
  NET_Shutdown;
  ReleaseEntityDLLs;

  Cmd_RemoveGameCmds;
  Cmd_Shutdown;
  CVar_Shutdown;
  Con_Shutdown;

  CM_FreePAS;
  if WADPath <> nil then
   Mem_FreeAndNil(WADPath);

  Draw_DecalShutdown;
  W_Shutdown;
  LPrint('Server shutdown'#10);
  Log_Close;
  COM_Shutdown;
  Delta_Shutdown;
  RealTime := 0;
  SV.Time := 0;
 end;
end;

end.
