unit HostCmds;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure Host_InitCommands;
procedure Host_InitCVars;

implementation

uses Common, Console, FileSys, GameLib, Host, Info, MathLib, MsgBuf, Network, SVAuth, SVClient, SVEdict, SVExport, SVMain, SVWorld;

procedure Host_KillServer_F; cdecl;
begin
if CmdSource = csServer then
 if SV.Active then
  begin
   Print('Shutting down the server.');
   Host_ShutdownServer(False);
  end
 else
  Print('The server is not active, can''t shutdown.');
end;

procedure Host_Restart_F; cdecl;
var
 Map: array[1..MAX_MAP_NAME] of LChar;
begin
if (CmdSource = csServer) and SV.Active then
 begin
  Host_ClearGameState;
  SV_InactivateClients;
  StrCopy(@Map, @SV.Map);
  SV_ServerDeactivate;
  SV_SpawnServer(@Map, nil);
  SV_LoadEntities;
  SV_ActivateServer(True);
 end;
end;

procedure Host_Status_F; cdecl;
var
 Buf: array[1..1024] of LChar;
 NetAdrBuf: array[1..128] of LChar;
 IntBuf, ExpandBuf: array[1..32] of LChar;
 ExtInfo, ToConsole: Boolean;
 F: TFile;
 S, S2, UniqueID: PLChar;
 I, HSpecs, HSlots, HDelay: Int;
 Time, Players, Hour, Min, Sec: UInt;
 C: PClient;
 AvgTx, AvgRx: Double;

 procedure Host_Status_PrintF(const Msg: array of const);
 begin
  if ToConsole then
   Print(Msg)
  else
   SV_ClientPrint(PLChar(StringFromVarRec(Msg)));

  if F <> nil then
   FS_FPrintF(F, Msg, True);
 end;

begin
ExtInfo := False;
F := nil;
ToConsole := CmdSource = csServer;
for I := 1 to Cmd_Argc - 1 do
 begin
  S := Cmd_Argv(I);
  if (StrIComp(S, 'ext') = 0) or (StrIComp(S, '-ext') = 0) then
   ExtInfo := True
  else
   if ((StrIComp(S, 'log') = 0) or (StrIComp(S, '-log') = 0)) and (F = nil) and ToConsole then
    if not FS_Open(F, 'status.log', 'wo') then
     F := nil;
 end;

Players := SV_CountPlayers;

Host_Status_PrintF(['- Server Status -']);
if hostname.Data^ > #0 then
 Host_Status_PrintF(['Hostname: ', hostname.Data]);

Host_Status_PrintF(['Version:  ', ProjectVersion, '; build ', ProjectBuild, '; 47/48 multi-protocol']);
if not NoIP then
 Host_Status_PrintF(['TCP/IP:   ', NET_AdrToString(LocalIP, NetAdrBuf, SizeOf(NetAdrBuf))]);

if not SV.Active then
 Host_Status_PrintF(['The server is not active.'])
else
 begin
  Host_Status_PrintF(['Map:      ', PLChar(@SV.Map)]);
  Host_Status_PrintF(['Players:  ', Players, ' connected (', SVS.MaxClients, ' max)']);

  AvgTx := 0;
  AvgRx := 0;
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Active then                              
     begin
      AvgTx := AvgTx + C.Netchan.Flow[FS_TX].KBAvgRate;
      AvgRx := AvgRx + C.Netchan.Flow[FS_RX].KBAvgRate;
     end;
   end;
  Host_Status_PrintF(['Network:  Out = ', RoundTo(AvgTx, -2), ' KBps; In = ', RoundTo(AvgRx, -2), ' KBps']);

  if ExtInfo then
   Host_Status_PrintF(['Sequence: ', SVS.SpawnCount]);

  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Active then
     begin
      Time := Trunc(RealTime - C.ConnectTime);
      Sec := Time mod 60;
      Time := Time div 60;
      Min := Time mod 60;
      Time := Time div 60;
      Hour := Time;

      if C.FakeClient then
       UniqueID := 'BOT'
      else
       UniqueID := SV_GetClientIDString(C^);

      S := StrECopy(@Buf, '#');
      S := StrECopy(S, ExpandString(IntToStr(I + 1, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
      S := StrECopy(S, ': ');
      S := StrECopy(S, @C.NetName);
      S := StrECopy(S, ' (UserID: ');
      S := StrECopy(S, IntToStr(C.UserID, IntBuf, SizeOf(IntBuf)));
      S := StrECopy(S, ', UniqueID: ');
      S := StrECopy(S, UniqueID);
      S := StrECopy(S, ', Time: ');
      if Min > 0 then
       begin
        if Hour > 0 then
         begin
          S := StrECopy(S, ExpandString(IntToStr(Hour, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
          S := StrECopy(S, ':');
         end;

        S := StrECopy(S, ExpandString(IntToStr(Min, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
        S := StrECopy(S, ':');
        S := StrECopy(S, ExpandString(IntToStr(Sec, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
        S := StrECopy(S, ', ');
       end
      else
       begin
        S := StrECopy(S, IntToStr(Sec, IntBuf, SizeOf(IntBuf)));
        S := StrECopy(S, ' sec, ');
       end;

      if C.HLTV then
       begin
        S := StrECopy(S, 'HLTV: ');
        HSpecs := -1;
        HSlots := -1;
        HDelay := -1;

        S2 := Info_ValueForKey(@C.UserInfo, 'hspecs');
        if (S2 <> nil) and (S2^ > #0) then
         HSpecs := StrToIntDef(S2, -1);
        S2 := Info_ValueForKey(@C.UserInfo, 'hslots');
        if (S2 <> nil) and (S2^ > #0) then
         HSlots := StrToIntDef(S2, -1);
        S2 := Info_ValueForKey(@C.UserInfo, 'hdelay');
        if (S2 <> nil) and (S2^ > #0) then
         HDelay := StrToIntDef(S2, -1);

        if (HSpecs < 0) or (HSlots < 0) then
         if HDelay < 0 then
          S := StrECopy(S, 'no data, ')
         else
          begin
           S := StrECopy(S, 'no slot data, delay: ');
           S := StrECopy(S, IntToStr(HDelay, IntBuf, SizeOf(IntBuf)));
           S := StrECopy(S, 's, ');
          end
        else
         begin
          S := StrECopy(S, IntToStr(HSpecs, IntBuf, SizeOf(IntBuf)));
          S := StrECopy(S, '/');
          S := StrECopy(S, IntToStr(HSlots, IntBuf, SizeOf(IntBuf)));
          if HDelay < 0 then
           S := StrECopy(S, ', no delay data, ')
          else
           begin
            S := StrECopy(S, ' with ');
            S := StrECopy(S, IntToStr(HDelay, IntBuf, SizeOf(IntBuf)));
            S := StrECopy(S, 's delay, ');
           end;
         end;
       end
      else
       if C.Entity <> nil then
        begin
         S := StrECopy(S, 'Frags: ');
         S := StrECopy(S, IntToStr(Trunc(C.Entity.V.Frags), IntBuf, SizeOf(IntBuf)));
        end;

      if not C.FakeClient then
       begin
        S := StrECopy(S, ', Protocol: ');
        S := StrECopy(S, IntToStr(C.Protocol, IntBuf, SizeOf(IntBuf)));
        S := StrECopy(S, ', Ping: ');
        S := StrECopy(S, IntToStr(SV_CalcPing(C^), IntBuf, SizeOf(IntBuf)));
        S := StrECopy(S, ', Loss: ');
        S := StrECopy(S, IntToStr(Trunc(C.PacketLoss), IntBuf, SizeOf(IntBuf)));
       end;

      if (ToConsole or C.HLTV) and (C.Netchan.Addr.AddrType = NA_IP) then
       begin
        S := StrECopy(S, ', Addr: ');
        S := StrECopy(S, NET_AdrToString(C.Netchan.Addr, NetAdrBuf, SizeOf(NetAdrBuf)));
       end;

      if ExtInfo then
       begin
        if C.Active then
         S := StrECopy(S, ', active');
        if C.Spawned then
         S := StrECopy(S, ', spawned');
        if C.Connected then
         S := StrECopy(S, ', connected');
       end;

      StrCopy(S, ').');
      Host_Status_PrintF([PLChar(@Buf)]);
     end;
   end;

  Host_Status_PrintF([Players, ' users.']);
 end;

if F <> nil then
 FS_Close(F);
end;

procedure Host_Quit_F; cdecl;
begin
if CmdSource = csServer then
 if Cmd_Argc = 1 then
  begin
   HostActive := 3;
   QuitCommandIssued := True;
   Host_ShutdownServer(False);
  end
 else
  begin
   HostActive := 2;
   HostStateInfo := 4;
  end;
end;

procedure Host_Quit_Restart_F; cdecl;
begin
if CmdSource = csServer then
 begin
  HostActive := 5;
  HostStateInfo := 4;
 end;
end;

procedure Host_Map_F; cdecl;
var
 MapName, MapFullName: array[1..MAX_MAP_NAME] of LChar;
begin
if CmdSource <> csServer then
 Exit;

if Cmd_Argc <> 2 then
 Print('Usage: map <name>')
else
 if not FilterMapName(Cmd_Argv(1), @MapFullName) then
  Print('map: The map name is too big.')
 else
  if not FS_FileExists(@MapFullName) then
   Print(['map: "', PLChar(@MapFullName), '" was not found on the server.'])
  else
   begin
    COM_FileBase(@MapFullName, @MapName);
    CVar_DirectSet(hostmap, @MapName);

    FS_LogLevelLoadStarted('Map_Common');
    if not SVS.InitGameDLL then
     Host_InitializeGameDLL;
    FS_LogLevelLoadStarted(@MapName);
    Host_Map(@MapName, False);
   end;
end;

procedure Host_Maps_F; cdecl;
var
 S: PLChar;
begin
if Cmd_Argc <> 2 then
 Print('Usage: maps <substring>')
else
 begin
  S := Cmd_Argv(1);
  if (S <> nil) and (S^ > #0) then
   if S^ = '*' then
    COM_ListMaps(nil)
   else
    COM_ListMaps(S)
  else
   Print('maps: Bad substring.')   
 end;
end;

procedure Host_Reload_F; cdecl;
begin
if CmdSource = csServer then
 begin
  Host_ClearGameState;
  SV_InactivateClients;
  SV_ServerDeactivate;
  SV_SpawnServer(hostmap.Data, nil);
  SV_LoadEntities;
  SV_ActivateServer(True);
 end;
end;

procedure Host_Changelevel_F; cdecl;
var
 S: PLChar;
 K: UInt;
 MapName, MapFullName: array[1..MAX_MAP_NAME] of LChar;
begin
if CmdSource = csServer then
 begin
  K := Cmd_Argc;
  if (K < 2) or (K > 3) then
   Print('Usage: changelevel <levelname>')
  else
   if not FilterMapName(Cmd_Argv(1), @MapFullName) then
    Print('changelevel: The map name is too big.')
   else
    if not FS_FileExists(@MapFullName) then
     Print(['changelevel: "', PLChar(@MapFullName), '" was not found on the server.'])
    else
     begin
      if K = 2 then
       S := nil
      else
       S := Cmd_Argv(2);

      COM_FileBase(@MapFullName, @MapName);
      CVar_DirectSet(hostmap, @MapName);

      FS_LogLevelLoadStarted('Map_Common');
      if not SVS.InitGameDLL then
       Host_InitializeGameDLL;
      FS_LogLevelLoadStarted(@MapName);

      SV_InactivateClients;
      SV_ServerDeactivate;
      SV_SpawnServer(@MapName, S);
      SV_LoadEntities;
      SV_ActivateServer(True);
     end;
 end;
end;

procedure Host_Changelevel2_F; cdecl;
begin
if CmdSource = csServer then
 begin
  Print('changelevel2: Not implemented.');
 end;
end;

procedure Host_Version_F; cdecl;
begin
if CmdSource = csServer then
 Print(['Protocol version: 47/48 (multi-protocol).', LineBreak,
        'Server build: ', BuildNumber, '; server version ', ProjectVersion, '.']);
end;

procedure Host_Say_F; cdecl;
begin
if CmdSource = csServer then
 Host_Say(False);
end;

procedure Host_Say_Team_F; cdecl;
begin
if CmdSource = csServer then
 Host_Say(True);
end;

procedure Host_Tell_F; cdecl;
begin
if CmdSource = csServer then
 Host_Say(False);
end;

procedure Host_Kill_F; cdecl;
begin
if CmdSource = csClient then
 if SVPlayer.V.Health > 0 then
  begin
   GlobalVars.Time := SV.Time;
   DLLFunctions.ClientKill(SVPlayer^);
  end
 else
  SV_ClientPrint('Can''t suicide - already dead.');
end;

procedure Host_TogglePause_F; cdecl;
var
 S: PLChar;
begin
if not SV.Active then
 SV_CmdPrint('The server is not running.')
else
 if (CmdSource = csClient) and not NET_IsLocalAddress(HostClient.Netchan.Addr) then
  SV_CmdPrint('Only server operators may use this command.')
 else
  if pausable.Value = 0 then
   SV_CmdPrint('Pause is not allowed on this server.')
  else
   begin
    if CmdSource = csClient then
     S := @HostClient.NetName
    else
     S := 'Server operator';

    SV.Paused := not SV.Paused;
    if SV.Paused then
     SV_BroadcastPrint([S, ' paused the game.'#10])
    else
     SV_BroadcastPrint([S, ' unpaused the game.'#10]);

    MSG_WriteByte(SV.ReliableDatagram, SVC_SETPAUSE);
    MSG_WriteByte(SV.ReliableDatagram, Byte(SV.Paused));
   end;
end;

procedure Host_Kick_F; cdecl;
var
 C, C2: PClient;
 I, J, K, UserID: UInt;
 S: PLChar;
 Buf: array[1..1024] of LChar;
begin
K := Cmd_Argc;
if K < 2 then
 SV_CmdPrint('Usage: kick <username or #userid> [reason]')
else
 if (CmdSource = csClient) and not NET_IsLocalAddress(HostClient.Netchan.Addr) then
  SV_CmdPrint('Only server operators may use this command.')
 else
  if not SV.Active then
   SV_CmdPrint('kick: The server is not running.')
  else
   begin
    J := 1;
    S := Cmd_Argv(J);
    if StrComp(S, '#') = 0 then
     begin
      Inc(J);
      UserID := StrToIntDef(Cmd_Argv(J), 0);
      S := nil;
     end
    else
     if S^ = '#' then
      begin
       UserID := StrToIntDef(PLChar(UInt(S) + 1), 0);
       S := nil;
      end
     else
      UserID := 0;

    if (UserID = 0) and (S = nil) then
     begin
      SV_CmdPrint('kick: Bad userid specified.');
      Exit;
     end;

    Buf[Low(Buf)] := #0;
    for I := J + 1 to K - 1 do
     begin
      StrLCat(@Buf, Cmd_Argv(I), SizeOf(Buf) - 1);
      if I < K - 1 then
       StrLCat(@Buf, ' ', SizeOf(Buf) - 1);
     end;

    for I := 0 to SVS.MaxClients - 1 do
     begin
      C := @SVS.Clients[I];
      if C.Connected and (((UserID > 0) and (C.UserID = UserID)) or ((S <> nil) and (StrComp(@C.NetName, S) = 0))) then
       begin
        if CmdSource = csClient then
         S := @HostClient.NetName
        else
         S := 'server operator';

        C2 := HostClient;
        HostClient := C;

        if Buf[Low(Buf)] = #0 then
         begin
          SV_CmdPrint(['Kicked ', PLChar(@C.NetName), '.']);
          SV_ClientPrint(['Kicked by ', S, '.']);
          SV_DropClient(C^, False, 'Kicked by server operator.');
          if CmdSource = csClient then
           LPrint([S, ' kicked ', PLChar(@C.NetName), '.'#10])
          else
           LPrint(['Kicked ', PLChar(@C.NetName), '.'#10]);
         end
        else
         begin
          SV_CmdPrint(['Kicked ', PLChar(@C.NetName), '. Reason: ', PLChar(@Buf)]);
          SV_ClientPrint(['Kicked by ', S, '. Reason: ', PLChar(@Buf)]);
          SV_DropClient(C^, False, PLChar(@Buf));
          if CmdSource = csClient then
           LPrint([S, ' kicked ', PLChar(@C.NetName), ', reason: ', PLChar(@Buf), #10])
          else
           LPrint(['Kicked ', PLChar(@C.NetName), ', reason: ', PLChar(@Buf), #10]);
         end;

        HostClient := C2;
        Exit;
       end;
     end;

    if UserID > 0 then
     SV_CmdPrint(['kick: Couldn''t find #', UserID, '.'])
    else
     SV_CmdPrint(['kick: Couldn''t find "', S, '".'])
   end;
end;

procedure Host_Ping_F; cdecl;
var
 I, Num: Int;
 C: PClient;
begin
SV_CmdPrint('Client ping times:');
Num := 0;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Active then
   begin
    Inc(Num);
    SV_CmdPrint([PLChar(@C.NetName), ': ', SV_CalcPing(C^)]);
   end;
 end;

if Num = 0 then
 SV_CmdPrint('(no clients currently connected)')
else
 SV_CmdPrint([Num, ' total clients.']);
end;

procedure Host_SetInfo_F; cdecl;
begin
if CmdSource = csClient then
 if Cmd_Argc <> 3 then
  SV_ClientPrint('Usage: setinfo [<key> <value>]')
 else
  begin
   Info_SetValueForKey(@HostClient.UserInfo, Cmd_Argv(1), Cmd_Argv(2), MAX_USERINFO_STRING);
   HostClient.UpdateInfo := True;
   HostClient.FragSizeUpdated := False;
  end;
end;

procedure Host_WriteFPS_F; cdecl;
begin
if CmdSource = csServer then
 if RollingFPS = 0 then
  Print('FPS: 0')
 else
  Print(['FPS: ', RoundTo(1 / RollingFPS, -2)]);
end;

procedure Host_Maxplayers_F; cdecl;
var
 I: UInt;
begin
if CmdSource = csServer then
 begin
  I := Cmd_Argc;
  if I < 2 then
   Print(['"maxplayers" is "', SVS.MaxClients, '"'])
  else
   if I > 2 then
    Print('Usage: maxplayers <value>')
   else
    if SV.Active then
     Print('maxplayers: Can''t change maxplayers while a server is running.')
    else
     begin
      I := StrToInt(Cmd_Argv(1));
      if I < 1 then
       I := 1
      else
       if I > SVS.MaxClientsLimit then
        I := SVS.MaxClientsLimit;
       
      Print(['"maxplayers" set to "', I, '"']);

      SVS.MaxClients := I;
      if I > 1 then
       CVar_DirectSet(deathmatch, '1')
      else
       CVar_DirectSet(deathmatch, '0');
     end;
 end;
end;

procedure Host_God_F; cdecl;
begin
if (CmdSource = csClient) and AllowCheats then
 begin
  SVPlayer.V.Flags := SVPlayer.V.Flags xor FL_GODMODE;
  if (SVPlayer.V.Flags and FL_GODMODE) > 0 then
   SV_ClientPrint('god: God mode is now enabled.')
  else
   SV_ClientPrint('god: God mode is now disabled.');
 end;
end;

procedure Host_Notarget_F; cdecl;
begin
if (CmdSource = csClient) and AllowCheats then
 begin
  SVPlayer.V.Flags := SVPlayer.V.Flags xor FL_NOTARGET;
  if (SVPlayer.V.Flags and FL_NOTARGET) > 0 then
   SV_ClientPrint('notarget: No-targeting mode is now enabled.')
  else
   SV_ClientPrint('notarget: No-targeting mode is now disabled.');
 end;
end;

function FindPassableSpace(var E: TEdict; const Angles: TVec3; Dir: Single): Boolean;
var
 I: UInt;
begin
for I := 1 to 32 do
 begin
  VectorMA(E.V.Origin, Dir, Angles, E.V.Origin);
  if SV_TestEntityPosition(E) = nil then
   begin
    E.V.OldOrigin := E.V.Origin;
    Result := True;
    Exit;
   end;
 end;

Result := False;
end;

procedure Host_Noclip_F; cdecl;
var
 Fwd, Right, Up: TVec3;
begin
if (CmdSource = csClient) and AllowCheats then
 if SVPlayer.V.MoveType = MOVETYPE_NOCLIP then
  begin
   SVPlayer.V.MoveType := MOVETYPE_WALK;
   SVPlayer.V.OldOrigin := SVPlayer.V.Origin;

   if SV_TestEntityPosition(SVPlayer^) <> nil then
    begin
     AngleVectors(SVPlayer.V.VAngle, @Fwd, @Right, @Up);
     if not FindPassableSpace(SVPlayer^, Fwd, 1) and
        not FindPassableSpace(SVPlayer^, Fwd, -1) and
        not FindPassableSpace(SVPlayer^, Right, 1) and
        not FindPassableSpace(SVPlayer^, Right, -1) and
        not FindPassableSpace(SVPlayer^, Up, 1) and
        not FindPassableSpace(SVPlayer^, Up, -1) then
      SV_ClientPrint('noclip: Can''t find the world.');

     SVPlayer.V.Origin := SVPlayer.V.OldOrigin;
    end;

   SV_ClientPrint('noclip: No-clipping mode is now disabled.');
  end
 else
  begin
   SVPlayer.V.MoveType := MOVETYPE_NOCLIP;
   SV_ClientPrint('noclip: No-clipping mode is now enabled.');
  end;
end;

procedure Host_InitCommands;
begin
Cmd_AddCommand('maxplayers', @Host_Maxplayers_F);
Cmd_AddCommand('shutdownserver', Host_KillServer_F);
Cmd_AddCommand('status', Host_Status_F);
Cmd_AddCommand('quit', Host_Quit_F);
Cmd_AddCommand('exit', Host_Quit_F);
Cmd_AddCommand('_restart', Host_Quit_Restart_F);
Cmd_AddCommand('map', Host_Map_F);
Cmd_AddCommand('maps', Host_Maps_F);
Cmd_AddCommand('restart', Host_Restart_F);
Cmd_AddCommand('reload', Host_Reload_F);
Cmd_AddCommand('changelevel', Host_Changelevel_F);
Cmd_AddCommand('changelevel2', Host_Changelevel2_F);
Cmd_AddCommand('version', Host_Version_F);
Cmd_AddCommand('say', Host_Say_F);
Cmd_AddCommand('say_team', Host_Say_Team_F);
Cmd_AddCommand('tell', Host_Tell_F);
Cmd_AddCommand('kill', Host_Kill_F);
Cmd_AddCommand('pause', Host_TogglePause_F);
Cmd_AddCommand('kick', Host_Kick_F);
Cmd_AddCommand('ping', Host_Ping_F);
Cmd_AddCommand('setinfo', Host_SetInfo_F);

Cmd_AddCommand('god', Host_God_F);
Cmd_AddCommand('notarget', Host_Notarget_F);
Cmd_AddCommand('noclip', Host_Noclip_F);

Cmd_AddCommand('writefps', Host_WriteFPS_F);

end;

procedure Host_InitCVars;
begin
CVar_RegisterVariable(developer);
CVar_RegisterVariable(console_cvar);
CVar_RegisterVariable(hostmap);
CVar_RegisterVariable(host_killtime);
CVar_RegisterVariable(sys_ticrate);
CVar_RegisterVariable(hostname);
CVar_RegisterVariable(sys_timescale);
CVar_RegisterVariable(host_limitlocal);
CVar_RegisterVariable(host_framerate);
CVar_RegisterVariable(host_speeds);
CVar_RegisterVariable(host_profile);
CVar_RegisterVariable(deathmatch);
CVar_RegisterVariable(coop);
CVar_RegisterVariable(pausable);
CVar_RegisterVariable(skill);

// Custom
CVar_RegisterVariable(sys_maxframetime);
CVar_RegisterVariable(sys_minframetime);
end;

end.
