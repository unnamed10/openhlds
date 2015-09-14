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

procedure Host_ClearMemory;

procedure Host_Error(Msg: PLChar); overload;
procedure Host_Error(const Msg: array of const); overload;

procedure Host_ShutdownServer(SkipNotify: Boolean);

function Host_Frame: Boolean;

procedure Host_Init;
procedure Host_Shutdown;

const
 LangName = 'english';
 LowViolenceBuild = False;

var
 console_cvar: TCVar = (Name: 'console'; Data: '0');
 developer: TCVar = (Name: 'developer'; Data: '0');
 deathmatch: TCVar = (Name: 'deathmatch'; Data: '0'; Flags: [FCVAR_SERVER]);
 coop: TCVar = (Name: 'coop'; Data: '0'; Flags: [FCVAR_SERVER]);
 hostname: TCVar = (Name: 'hostname'; Data: ProjectName + ' v' + ProjectVersion + ' server');
 skill: TCVar = (Name: 'skill'; Data: '1');
 hostmap: TCVar = (Name: 'hostmap'; Data: '');
 host_killtime: TCVar = (Name: 'host_killtime'; Data: '0');
 sys_ticrate: TCVar = (Name: 'sys_ticrate'; Data: '100'; Flags: [FCVAR_SERVER]);
 sys_maxframetime: TCVar = (Name: 'sys_maxframetime'; Data: '0.25');
 sys_minframetime: TCVar = (Name: 'sys_minframetime'; Data: '0.001');
 sys_timescale: TCVar = (Name: 'sys_timescale'; Data: '1');
 host_limitlocal: TCVar = (Name: 'host_limitlocal'; Data: '0');
 host_framerate: TCVar = (Name: 'host_framerate'; Data: '0');
 host_speeds: TCVar = (Name: 'host_speeds'; Data: '0');
 host_profile: TCVar = (Name: 'host_profile'; Data: '0');
 pausable: TCVar = (Name: 'pausable'; Data: '0'; Flags: [FCVAR_SERVER]);

 HostInit: Boolean = False;
 HostActive, HostSubState, HostStateInfo: UInt;
 QuitCommandIssued: Boolean;
 InHostError: Boolean;
 InHostShutdown: Boolean;
 HostHunkLevel: UInt;
 HostFrameTime: Double;
 HostNumFrames: UInt;
 
 RealTime, OldRealTime: Double;

 BaseDir, GameDir, DefaultGameDir, FallbackDir: PLChar;

 CSFlagsInitialized: Boolean = False;
 IsCStrike, IsCZero, IsCZeroRitual, IsTerrorStrike: Boolean;

 WADPath: PLChar;

 HostTimes: record
  Cur, Prev, Frame: Double;

  CollectData: Boolean;
  Host, SV, Rcon: Double;
 end = (CollectData: False);

 TimeCount: UInt;
 TimeTotal: Double;

 CmdLineTicrateCheck: Boolean = False;
 CmdLineTicrate: UInt;

 RollingFPS: Double;

implementation

uses Common, Console, CoreUI, Decal, Delta, Edict, Encode, GameLib, HostCmds, HostSave, HPAK, Memory, Model, MsgBuf, Network, Renderer, Resource, SVClient, SVEdict, SVEvent, SVExport, SVMain, SVPacket, SVPhys, SVRcon, SVSend, SVWorld, SysMain, SysArgs, SysClock, Texture;

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

procedure Host_ClearMemory;
begin
DPrint('Clearing memory.');

Mod_ClearAll;
CM_FreePAS;
SV_FreePMSimulator;
SV_ClearEntities;
SV_ClearPrecachedEvents;

if HostHunkLevel > 0 then
 Hunk_FreeToLowMark(HostHunkLevel);

SV_ClearClientStates;

MemSet(SV, SizeOf(SV), 0);
end;

procedure Host_Error(Msg: PLChar);
begin
if InHostError then
 Sys_Error('Host_Error: Recursively entered.')
else
 begin
  InHostError := True;
  Print(['Host_Error: ', Msg]);
  if SV.Active then
   Host_ShutdownServer(False);

  Sys_Error(['Host_Error: ', Msg]);
 end;
end;

procedure Host_Error(const Msg: array of const);
begin
Host_Error(PLChar(StringFromVarRec(Msg)));
end;

procedure Host_ShutdownServer(SkipNotify: Boolean);
var
 I: Int;
 C: PClient;
begin
if SV.Active then
 begin
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Connected then
     SV_DropClient(C^, SkipNotify, 'Server shutting down.');
   end;

  SV_ServerDeactivate;
  SV.Active := False;

  HPAK_FlushHostQueue;
  Host_ClearMemory;

  SV_ClearClients;
  MemSet(SVS.Clients^, SizeOf(TClient) * SVS.MaxClientsLimit, 0);
  
  NET_ClearLagData(False, True);
  LPrint('Server shutdown'#10);
  Log_Close;
 end;
end;

procedure Host_InitLocal;
begin
Host_InitCommands;
Host_InitCVars;
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
  SVS.ServerFlags := 0;
 end;

if SV_SpawnServer(Name, nil) then
 if Save then
  begin
   if not LoadGamestate(Name, True) then
    SV_LoadEntities;

   SV.Paused := True;
   SV.SavedGame := True;
   SV_ActivateServer(False);
   SV_LinkNewUserMsgs;
  end
 else
  begin
   SV_LoadEntities;
   SV_ActivateServer(True);
   SV_LinkNewUserMsgs;
  end;
end;

procedure Host_SetHostTimes;
begin
HostTimes.Cur := Sys_FloatTime;
HostTimes.Frame := HostTimes.Cur - HostTimes.Prev;
if HostTimes.Frame < 0 then
 begin
  if sys_minframetime.Value <= 0 then
   CVar_DirectSet(sys_minframetime, '0.0001');
  HostTimes.Frame := sys_minframetime.Value;
 end;
HostTimes.Prev := HostTimes.Cur;
end;

procedure Host_CheckTimeCVars;
begin
if sys_minframetime.Value <= 0 then
 CVar_DirectSet(sys_minframetime, '0.0001')
else
 if sys_maxframetime.Value > 2 then
  CVar_DirectSet(sys_maxframetime, '2')
 else
  if sys_timescale.Value <= 0 then
   CVar_DirectSet(sys_timescale, '1');
end;

function Host_FilterTime(Time: Double): Boolean;
var
 F: Double;
begin
Host_CheckTimeCVars;
if sys_timescale.Value <> 1 then
 RealTime := RealTime + Time * sys_timescale.Value
else
 RealTime := RealTime + Time;

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

  if F > sys_maxframetime.Value then
   HostFrameTime := sys_maxframetime.Value
  else
   if F < sys_minframetime.Value then
    HostFrameTime := sys_minframetime.Value
   else
    HostFrameTime := F;

  if HostFrameTime <= 0 then
   HostFrameTime := sys_minframetime.Value;

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
  Inc(HostNumFrames);
  if sv_stats.Value <> 0 then
   Host_UpdateStats;

  if (host_killtime.Value <> 0) and (host_killtime.Value < SV.Time) then
   CBuf_AddText('quit'#10);

  UI_Frame(RealTime);
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

Rand_Init;
CBuf_Init;
Cmd_Init;
CVar_Init;       
Host_InitLocal;
Host_ClearSaveDirectory;
Con_Init;
HPAK_Init;

SV_SetMaxClients;
W_LoadWADFile('gfx.wad');
W_LoadWADFile('fonts.wad');
Decal_Init;
Mod_Init;
R_Init;
NET_Init;
Netchan_Init;
Delta_Init;
SV_Init;

StrLCopy(@Buf, ProjectVersion, SizeOf(Buf) - 1);
StrLCat(@Buf, ',47-48,', SizeOf(Buf) - 1);
StrLCat(@Buf, IntToStr(BuildNumber, IntBuf, SizeOf(IntBuf)), SizeOf(Buf) - 1);
CVar_DirectSet(sv_version, @Buf);

HPAK_CheckIntegrity('custom.hpk');

CBuf_InsertText('exec valve.rc'#10);
Hunk_AllocName(0, '-HOST_HUNKLEVEL-');
HostHunkLevel := Hunk_LowMark;

HostActive := 1;
HostNumFrames := 0;

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
  HostInit := False;

  SV_ServerDeactivate;

  Mod_ClearAll;
  SV_ClearEntities;
  CM_FreePAS;
  SV_FreePMSimulator;

  SV_Shutdown;
  ReleaseEntityDLLs;
  Delta_Shutdown;
  NET_Shutdown;
  if WADPath <> nil then
   Mem_FreeAndNil(WADPath);
  Draw_DecalShutdown;
  W_Shutdown;
  HPAK_FlushHostQueue;
  Con_Shutdown;
  Cmd_RemoveGameCmds;
  Cmd_Shutdown;
  CVar_Shutdown;

  LPrint('Server shutdown'#10);
  Log_Close;
  RealTime := 0;
  SV.Time := 0;
 end;
end;

end.
