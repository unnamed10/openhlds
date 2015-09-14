unit SVCmds;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure SV_FreeLogNodes;

procedure SV_SetLogAddress_F; cdecl;
procedure SV_AddLogAddress_F; cdecl;
procedure SV_DelLogAddress_F; cdecl;
procedure SV_ServerLog_F; cdecl;

procedure SV_Serverinfo_F; cdecl;
procedure SV_Localinfo_F; cdecl;
procedure SV_ShowServerinfo_F; cdecl;

procedure SV_User_F; cdecl;
procedure SV_Users_F; cdecl;

procedure SV_Drop_F; cdecl;

procedure SV_New_F; cdecl;
procedure SV_Spawn_F; cdecl;
procedure SV_SendRes_F; cdecl;
procedure SV_SendEnts_F; cdecl;
procedure SV_FullUpdate_F; cdecl;

var
 FirstLog: PLogNode;

implementation

uses Common, Console, FileSys, GameLib, Info, Memory, MsgBuf, Host, Network, SVAuth, SVClient, SVDelta, SVMain, SVRcon, SVSend;

procedure SV_FreeLogNodes;
var
 P, P2: PLogNode;
begin
P := FirstLog;
while P <> nil do
 begin
  P2 := P.Prev;
  Mem_Free(P);
  P := P2;
 end;
end;

procedure SV_SetLogAddress_F; cdecl;
var
 AddrBuf: array[1..64] of LChar;
 IP: PLChar;
 Port: Int;
 Adr: TNetAdr;
begin
if CmdSource <> csServer then
 Exit;

if Cmd_Argc <> 3 then
 begin
  Print('Usage: logaddress <ip> <port>');
  if SVS.LogEnabled then
   Print(['Currently logging data to "', NET_AdrToString(SVS.LogAddr, AddrBuf, SizeOf(AddrBuf)), '".']);
 end
else
 begin
  IP := Cmd_Argv(1);
  Port := StrToInt(Cmd_Argv(2));
  if (Port <= 0) or (Port > High(UInt16)) then
   Print('logaddress: Must specify a valid port.')
  else
   if IP^ = #0 then
    Print('logaddress: Must specify a valid IP address.')
   else
    if not NET_StringToAdr(IP, Adr) then
     Print(['logaddress: Unable to resolve "', IP, ':', Port, '".'])
    else
     begin
      Adr.Port := Port;
      SVS.LogToAddr := True;
      SVS.LogAddr := Adr;
      Print(['logaddress: Logging to "', IP, ':', Port, '".']);
     end;
 end;
end;

procedure SV_AddLogAddress_F; cdecl;
var
 AddrBuf: array[1..64] of LChar;
 P: PLogNode;
 I: UInt;
 IP: PLChar;
 Port: Int;
 Adr: TNetAdr;
begin
if CmdSource <> csServer then
 Exit;

if Cmd_Argc <> 3 then
 begin
  Print('Usage: logaddress_add <ip> <port>');

  if FirstLog <> nil then
   begin
    Print('Currently logging data to:');
    I := 1;
    P := FirstLog;
    while P <> nil do
     begin
      Print(['#', I, ': ', NET_AdrToString(P.Adr, AddrBuf, SizeOf(AddrBuf))]);
      Inc(I);
      P := P.Prev;
     end;
   end;
 end
else
 begin
  IP := Cmd_Argv(1);
  Port := StrToInt(Cmd_Argv(2));
  if (Port <= 0) or (Port > High(UInt16)) then
   Print('logaddress_add: Must specify a valid port.')
  else
   if IP^ = #0 then
    Print('logaddress_add: Must specify a valid IP address.')
   else
    if not NET_StringToAdr(IP, Adr) then
     Print(['logaddress_add: Unable to resolve "', IP, ':', Port, '".'])
    else
     begin
      Adr.Port := Port;

      P := FirstLog;
      while P <> nil do
       if (PUInt32(@P.Adr.IP)^ = PUInt32(@Adr.IP)^) and (P.Adr.Port = Adr.Port) then
        begin
         Print('logaddress_add: Address already in list.');
         Exit;
        end
       else
        P := P.Prev;

      P := Mem_Alloc(SizeOf(P^));
      P.Adr := Adr;
      P.Prev := FirstLog;
      P.Next := nil;
      if FirstLog <> nil then
       FirstLog.Next := P;
      FirstLog := P;
      Print(['logaddress_add: Added "', IP, ':', Port, '".']);
     end;
 end;
end;

procedure SV_DelLogAddress_F; cdecl;
var
 AddrBuf: array[1..64] of LChar;
 P: PLogNode;
 I: UInt;
 IP: PLChar;
 Port: Int;
 Adr: TNetAdr;
begin
if CmdSource <> csServer then
 Exit;

if Cmd_Argc <> 3 then
 begin
  Print('Usage: logaddress_del <ip> <port>');

  if FirstLog <> nil then
   begin
    Print('Currently logging data to:');
    I := 1;
    P := FirstLog;
    while P <> nil do
     begin
      Print(['#', I, ': ', NET_AdrToString(P.Adr, AddrBuf, SizeOf(AddrBuf))]);
      Inc(I);
      P := P.Prev;
     end;
   end;
 end
else
 begin
  IP := Cmd_Argv(1);
  Port := StrToInt(Cmd_Argv(2));
  if (Port <= 0) or (Port > High(UInt16)) then
   Print('logaddress_del: Must specify a valid port.')
  else
   if IP^ = #0 then
    Print('logaddress_del: Must specify a valid IP address.')
   else
    if not NET_StringToAdr(IP, Adr) then
     Print(['logaddress_del: Unable to resolve "', IP, ':', Port, '".'])
    else
     begin
      Adr.Port := Port;

      P := FirstLog;
      while P <> nil do
       if (PUInt32(@P.Adr.IP)^ = PUInt32(@Adr.IP)^) and (P.Adr.Port = Adr.Port) then
        begin
         if P.Prev <> nil then
          P.Prev.Next := P.Next;
         if P.Next <> nil then
          P.Next.Prev := P.Prev;

         if FirstLog = P then
          if P.Prev <> nil then
           FirstLog := P.Prev
          else
           FirstLog := P.Next;

         Print(['logaddress_del: Deleted "', IP, ':', Port, '".']);
         Mem_Free(P);
         Exit;
        end
       else
        P := P.Prev;

      Print('logaddress_del: Couldn''t find address in list.');
     end;
 end;
end;

procedure SV_ServerLog_F; cdecl;
var
 S: PLChar;
begin
if CmdSource = csServer then
 if Cmd_Argc <> 2 then
  begin
   Print('Usage: log <on | off>');
   if SVS.LogEnabled then
    Print('Currently logging.')
   else
    Print('Not currently logging.');
  end
 else
  begin
   S := Cmd_Argv(1);
   if StrIComp(S, 'off') = 0 then
    if SVS.LogEnabled then
     begin
      if SVS.LogFile <> nil then
       Log_Close;
      Print('Server logging disabled.');
      SVS.LogEnabled := False;
     end
    else
   else
    if StrIComp(S, 'on') = 0 then
     begin
      SVS.LogEnabled := True;
      Log_Open;
     end
    else
     Print(['log: Unknown parameter "', S, '"; "on" and "off" are valid.']);
  end;
end;

procedure SV_Serverinfo_F; cdecl;
var
 Key, Value: PLChar;
 P: PCVar;
begin
if CmdSource = csServer then
 if Cmd_Argc = 1 then
  begin
   Print('Server info settings:');
   Info_Print(@ServerInfo);
  end
 else
  if Cmd_Argc <> 3 then
   Print('Usage: serverinfo [<key> <value>]')
  else
   begin
    Key := Cmd_Argv(1);
    if Key^ = '*' then
     Print('serverinfo: Star variables cannot be changed.')
    else
     begin
      Value := Cmd_Argv(2);
      Info_SetValueForKey(@ServerInfo, Key, Value, SizeOf(ServerInfo));
      P := CVar_FindVar(Key);
      if P <> nil then
       CVar_DirectSet(P^, Value);

      SV_BroadcastCommand(['fullserverinfo "', PLChar(@ServerInfo), '"#10']);
     end;
   end;
end;

procedure SV_Localinfo_F; cdecl;
var
 Key: PLChar;
begin
if CmdSource = csServer then
 if Cmd_Argc = 1 then
  begin
   Print('Local info settings:');
   Info_Print(@LocalInfo);
  end
 else
  if Cmd_Argc <> 3 then
   Print('Usage: localinfo [<key> <value>]')
  else
   begin
    Key := Cmd_Argv(1);
    if Key^ = '*' then
     Print('localinfo: Star variables cannot be changed.')
    else
     Info_SetValueForKey(@LocalInfo, Key, Cmd_Argv(2), SizeOf(LocalInfo));
   end;
end;

procedure SV_ShowServerinfo_F; cdecl;
begin
if CmdSource = csServer then
 Info_Print(@ServerInfo);
end;

procedure SV_User_F; cdecl;
const
 Prefix: array[Boolean] of PLChar = ('Userinfo', 'Physinfo');
var
 B: Boolean;
 S: PLChar;
 I: Int;
 K, UserID: UInt;
 C: PClient;
begin
if CmdSource = csServer then
 if not SV.Active then
  Print('user: The server is not running.')
 else
  begin
   K := Cmd_Argc;
   if (K < 2) or (K > 3) then
    Print('Usage: user <username or #userid> ["physinfo"]' + LineBreak +
          'The userid should be prefixed with a "#".')
   else
    begin
     S := Cmd_Argv(1);
     if S^ = '#' then
      begin
       UserID := StrToIntDef(PLChar(UInt(S) + 1), 0);
       if UserID = 0 then
        begin
         Print('user: Bad userid specified.');
         Exit;
        end;
       S := EmptyString;
      end
     else
      UserID := 0;

     B := (K = 3) and (StrIComp(Cmd_Argv(2), 'physinfo') = 0);

     for I := 0 to SVS.MaxClients - 1 do
      begin
       C := @SVS.Clients[I];
       if C.Connected and (((UserID > 0) and (C.UserID = UserID)) or ((S^ > #0) and (StrComp(@C.NetName, S) = 0))) then
        begin
         if C.FakeClient then
          Print([Prefix[B], ' for fake player "', PLChar(@C.NetName), '" (#', C.UserID, '):'])
         else
          Print([Prefix[B], ' for "', PLChar(@C.NetName), '" (#', C.UserID, '):']);

         if B then
          Info_Print(@C.PhysInfo)
         else
          Info_Print(@C.UserInfo);

         Exit;
        end;
      end;

     if UserID > 0 then
      Print(['user: Couldn''t find user #', UserID, '.'])
     else
      Print(['user: Couldn''t find user "', S, '".'])
    end;
  end;
end;

procedure SV_Users_F; cdecl;
var
 I, J: Int;
 C: PClient;
 Buf: array[1..1024] of LChar;
 S: PLChar;
 IntBuf, ExpandBuf: array[1..32] of LChar;
begin
if CmdSource = csServer then
 if not SV.Active then
  Print('users: The server is not running.')
 else
  begin
   J := 0;
   for I := 0 to SVS.MaxClients - 1 do
    begin
     C := @SVS.Clients[I];
     if C.Connected then
      begin
       S := StrECopy(@Buf, '#');
       S := StrECopy(S, ExpandString(IntToStr(J + 1, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
       S := StrECopy(S, ': ');
       S := StrECopy(S, @C.NetName);

       if C.FakeClient then
        S := StrECopy(S, ' (fake client)')
       else
        if C.HLTV then
         S := StrECopy(S, ' (HLTV)');

       S := StrECopy(S, ' (UserID: ');
       S := StrECopy(S, IntToStr(C.UserID, IntBuf, SizeOf(IntBuf)));
       S := StrECopy(S, '; UniqueID: ');
       S := StrECopy(S, SV_GetClientIDString(C^));
       S := StrECopy(S, '; Out: ');
       S := StrECopy(S, PLChar(FloatToStr(RoundTo(C.Netchan.Flow[FS_RX].KBAvgRate, -2))));
       S := StrECopy(S, ' KBps; In: ');
       S := StrECopy(S, PLChar(FloatToStr(RoundTo(C.Netchan.Flow[FS_TX].KBAvgRate, -2))));
       StrCopy(S, ' KBps).');

       Print(@Buf);
       Inc(J);
      end;
    end;

   Print([J, ' users.']);
  end;
end;

procedure SV_Drop_F; cdecl;
begin
if CmdSource = csClient then
 begin
  SV_EndRedirect;
  SV_BroadcastPrint([PLChar(@HostClient.NetName), ' dropped.'#10]);
  SV_DropClient(HostClient^, False, 'Client sent ''drop''.');
 end;
end;

procedure SV_New_F; cdecl;
var
 SB: TSizeBuf;
 Buf: array[1..1024] of LChar;
 SBData: array[1..MAX_NETBUFLEN] of Byte;
 Name: array[1..MAX_PLAYER_NAME] of LChar;
 Address: array[1..256] of LChar;
 RejectReason: array[1..128] of LChar;
 S: PLChar;
 C: PClient;
 I: Int;
begin
if CmdSource = csServer then
 Exit
else
 if (HostClient.ConnectSeq = SVS.SpawnCount) and (RealTime <= HostClient.NewCmdTime) then
  begin
   SV_DropClient(HostClient^, False, 'Reconnection blocked, not enough time passed since previous attempt.');
   Exit;
  end;

SB.Name := 'New Connection';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.CurrentSize := 0;
SB.MaxSize := SizeOf(SBData);

HostClient.Connected := True;
HostClient.ConnectTime := RealTime;
HostClient.ConnectSeq := SVS.SpawnCount;
HostClient.NewCmdTime := RealTime + 1.5;

SZ_Clear(HostClient.UnreliableMessage);
Netchan_Clear(HostClient.Netchan);

SV_SendServerInfo(SB, HostClient^);

if UserMsgs <> nil then
 SV_SendUserReg(SB, UserMsgs);
HostClient.UserMsgReady := True;

StrCopy(@Name, @HostClient.NetName);
NET_AdrToString(HostClient.Netchan.Addr, Address, SizeOf(Address));
StrCopy(@RejectReason, 'Connection rejected by game.'#10);
if DLLFunctions.ClientConnect(HostClient.Entity^, @Name, @Address, @RejectReason) <> 0 then
 begin
  MSG_WriteByte(SB, SVC_STUFFTEXT);
  S := StrECopy(@Buf, 'fullserverinfo "');
  S := StrECopy(S, @ServerInfo);
  StrCopy(S, '"'#10);
  MSG_WriteString(SB, @Buf);
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Connected then
     SV_FullClientUpdate(C^, SB);
   end;

  if FSB_OVERFLOWED in SB.AllowOverflow then
   SV_DropClient(HostClient^, False, 'Connection buffer overflow.')
  else
   begin
    Netchan_CreateFragments(HostClient.Netchan, SB);
    Netchan_FragSend(HostClient.Netchan);
   end;
 end
else
 begin
  SV_ClientPrint(@RejectReason, False);
  SV_DropClient(HostClient^, False, ['Server refused connection: ', PLChar(@RejectReason), '.']);
 end;
end;

procedure SV_Spawn_F; cdecl;
var
 SB: TSizeBuf;
 SBData: array[1..MAX_NETBUFLEN] of Byte;
 CRC: PCRC;
begin
if (CmdSource = csClient) and (Cmd_Argc = 3) then
 begin
  if (HostClient.ConnectSeq = SVS.SpawnCount) and (HostClient.SpawnSeq = SVS.SpawnCount) and
     (RealTime <= HostClient.SpawnCmdTime) then
   begin
    SV_DropClient(HostClient^, False, 'Reconnection blocked, not enough time passed since previous attempt.');
    Exit;
   end;

  HostClient.SpawnSeq := SVS.SpawnCount;
  HostClient.SpawnCmdTime := RealTime + 1.5;
  
  CRC := @HostClient.MapCRC;
  CRC^ := StrToInt(Cmd_Argv(2));
  COM_UnMunge2(CRC, SizeOf(TCRC), Byte(not SVS.SpawnCount));

  if UInt(StrToInt(Cmd_Argv(1))) <> SVS.SpawnCount then
   SV_New_F
  else
   begin
    SB.Name := 'Spawning';
    SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
    SB.Data := @SBData;
    SB.CurrentSize := 0;
    SB.MaxSize := SizeOf(SBData);

    SZ_Write(SB, SV.Signon.Data, SV.Signon.CurrentSize);
    SV_WriteSpawn(HostClient^, SB);
    SV_WriteVoiceCodec(SB);

    if FSB_OVERFLOWED in SB.AllowOverflow then
     SV_DropClient(HostClient^, False, 'Spawn buffer overflow.')
    else
     begin
      Netchan_CreateFragments(HostClient.Netchan, SB);
      Netchan_FragSend(HostClient.Netchan);
     end;
   end;
 end;
end;

procedure SV_SendRes_F; cdecl;
var
 SB: TSizeBuf;
 SBData: array[1..MAX_NETBUFLEN] of Byte;
begin
if (CmdSource <> csServer) and (HostClient.Active or not HostClient.Spawned) and (RealTime > HostClient.SendResTime) then
 begin
  SB.Name := 'SendResources';
  SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
  SB.Data := @SBData;
  SB.CurrentSize := 0;
  SB.MaxSize := SizeOf(SBData);

  SV_SendResources(SB);
  if FSB_OVERFLOWED in SB.AllowOverflow then
   SV_DropClient(HostClient^, False, 'Resource buffer overflow.')
  else
   begin
    Netchan_CreateFragments(HostClient.Netchan, SB);
    Netchan_FragSend(HostClient.Netchan);
   end;

  if sv_sendresinterval.Value < 0 then
   CVar_DirectSet(sv_sendresinterval, '0');
  HostClient.SendResTime := RealTime + sv_sendresinterval.Value;
 end;
end;

procedure SV_SendEnts_F; cdecl;
begin
if (CmdSource <> csServer) and HostClient.Active and HostClient.Spawned and HostClient.Connected and
   (RealTime > HostClient.SendEntsTime) then
 begin
  HostClient.SendInfo := True;

  if sv_sendentsinterval.Value < 0 then
   CVar_DirectSet(sv_sendentsinterval, '0');
  HostClient.SendEntsTime := RealTime + sv_sendentsinterval.Value;
 end;
end;

procedure SV_FullUpdate_F; cdecl;
begin
if (CmdSource <> csServer) and HostClient.Active and (RealTime > HostClient.FullUpdateTime) then
 begin
  SV_ForceFullClientsUpdate;
  DLLFunctions.ClientCommand(SVPlayer^);

  if sv_fullupdateinterval.Value < 0 then
   CVar_DirectSet(sv_fullupdateinterval, '0');
  HostClient.FullUpdateTime := RealTime + sv_fullupdateinterval.Value;
 end;
end;

end.
