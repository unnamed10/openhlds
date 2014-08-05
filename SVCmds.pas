unit SVCmds;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

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

uses Common, Console, FileSys, GameLib, Info, Memory, MsgBuf, Host, Network, Server, SVAuth, SVClient, SVDelta, SVRcon, SVSend;

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
  Print('Usage: logaddress_add <ip> <port>' + LineBreak +
        'Currently logging data to:');

  I := 1;
  P := FirstLog;
  while P <> nil do
   begin
    Print(['#', I, ': ', NET_AdrToString(P.Adr, AddrBuf, SizeOf(AddrBuf))]);
    Inc(I);
    P := P.Prev;
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
  Print('Usage: logaddress_del <ip> <port>' + LineBreak +
        'Currently logging data to:');

  I := 1;
  P := FirstLog;
  while P <> nil do
   begin
    Print(['#', I, ': ', NET_AdrToString(P.Adr, AddrBuf, SizeOf(AddrBuf))]);
    Inc(I);
    P := P.Prev;
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
          FirstLog := P.Prev;

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
 L: UInt;
begin
if CmdSource = csServer then
 if Cmd_Argc = 1 then
  begin
   Print('Server info settings:');
   Info_Print(Info_ServerInfo);
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
      Info_SetValueForKey(Info_ServerInfo, Key, Value, SizeOf(Info.ServerInfo));
      P := CVar_FindVar(Key);
      if P <> nil then
       begin
        Z_Free(P.Data);
        L := StrLen(Value);
        P.Data := Z_MAlloc(L + 1);
        StrCopy(P.Data, Value);
        P.Value := StrToFloatDef(P.Data, 0);
       end;

      SV_BroadcastCommand(['fullserverinfo "', Info_ServerInfo, '"#10']);
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
 Info_Print(Info_ServerInfo);
end;

procedure SV_User_F; cdecl;
var
 S: PLChar;
 I: Int;
 UserID: UInt;
 C: PClient;
begin
if CmdSource = csServer then
 if not SV.Active then
  Print('user: The server is not running.')
 else
  if Cmd_Argc <> 2 then
   Print('Usage: user <username or #userid>')
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

    for I := 0 to SVS.MaxClients - 1 do
     begin
      C := @SVS.Clients[I];
      if (C.Active or C.Spawned or C.Connected) and not C.FakeClient and
         (((UserID > 0) and (C.UserID = UserID)) or ((S^ > #0) and (StrComp(@C.NetName, S) = 0))) then
       begin
        Info_Print(@C.UserInfo);
        Exit;
       end;
     end;

    Print('user: User not in server.');
   end;
end;

procedure SV_Users_F; cdecl;
const
 IndexPadding: array[0..10] of LChar = '    '#0#0#0#0#0#0#0;
 UserIDPadding: array[0..11] of LChar = '     '#0#0#0#0#0#0#0;
var
 I, J: Int;
 C: PClient;
begin
if CmdSource = csServer then
 if not SV.Active then
  Print('users: The server is not running.')
 else
  begin
   Print('index | userid | uniqueid | name' + LineBreak +
         '----- | ------ | -------- | ----');

   J := 0;
   for I := 1 to SVS.MaxClients do
    begin
     C := @SVS.Clients[I - 1];
     if (C.Active or C.Spawned or C.Connected) and not C.FakeClient and (C.NetName[Low(C.NetName)] > #0) then
      begin
       Inc(J);
       Print([PLChar(@IndexPadding[Trunc(Log10(I))]), I, '   ', C.UserID, PLChar(@UserIDPadding[Trunc(Log10(C.UserID))]), '   ', SV_GetClientIDString(C^), '   ', PLChar(@C.NetName)]);
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
  SV_BroadcastPrint([PLChar(@HostClient.NetName), ' dropped.']);
  SV_DropClient(HostClient^, False, 'Client sent ''drop''.');
 end;
end;

procedure SV_New_F; cdecl;
var
 SB: TSizeBuf;
 Buf: array[1..1024] of LChar;
 SBData: array[1..65536] of Byte;
 Name: array[1..MAX_PLAYER_NAME] of LChar;
 Address: array[1..256] of LChar;
 RejectReason: array[1..128] of LChar;
 OldUserMsgs: PUserMsg; 
 S: PLChar;
 C: PClient;
 I: Int;
begin
if (CmdSource = csServer) or (not HostClient.Active and HostClient.Spawned) then
 Exit;

SB.Name := 'New Connection';
SB.AllowOverflow := [];
SB.Data := @SBData;
SB.CurrentSize := 0;
SB.MaxSize := SizeOf(SBData);

HostClient.Connected := True;
HostClient.ConnectTime := RealTime;
SZ_Clear(HostClient.Netchan.NetMessage);
SZ_Clear(HostClient.UnreliableMessage);
Netchan_Clear(HostClient.Netchan);

SV_SendServerInfo(SB, HostClient^);
if UserMsgs <> nil then
 begin
  OldUserMsgs := NewUserMsgs;
  NewUserMsgs := UserMsgs;
  SV_SendUserReg(SB);
  NewUserMsgs := OldUserMsgs;
 end;

HostClient.UserMsgReady := True;
if (HostClient.Active or HostClient.Spawned) and (HostClient.Entity <> nil) then
 DLLFunctions.ClientDisconnect(HostClient.Entity^);

StrCopy(@Name, @HostClient.NetName);
NET_AdrToString(HostClient.Netchan.Addr, Address, SizeOf(Address));
StrCopy(@RejectReason, 'Connection rejected by game.'#10);
if DLLFunctions.ClientConnect(HostClient.Entity^, @Name, @Address, @RejectReason) <> 0 then
 begin
  MSG_WriteByte(SB, SVC_STUFFTEXT);
  S := StrECopy(@Buf, 'fullserverinfo "');
  S := StrECopy(S, Info_ServerInfo);
  StrCopy(S, '"'#10);
  MSG_WriteString(SB, @Buf);
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if (C = HostClient) or C.Active or C.Spawned or C.Connected then
     SV_FullClientUpdate(C^, SB);
   end;

  Netchan_CreateFragments(HostClient.Netchan, SB);
  Netchan_FragSend(HostClient.Netchan);
 end
else
 begin
  RejectReason[High(RejectReason)] := #0;
  
  MSG_WriteByte(HostClient.Netchan.NetMessage, SVC_STUFFTEXT);
  S := StrECopy(@Buf, 'echo ');
  S := StrECopy(S, @RejectReason);
  StrCopy(S, #10);
  MSG_WriteString(HostClient.Netchan.NetMessage, @Buf);
  SV_DropClient(HostClient^, False, ['Server refused connection because: ', PLChar(@RejectReason), '.']);
 end;
end;

procedure SV_Spawn_F; cdecl;
var
 SB: TSizeBuf;
 SBData: array[1..65536] of Byte;
 CRC: PCRC;
begin
if CmdSource = csClient then
 if Cmd_Argc <> 3 then
  SV_ClientPrint('Usage: spawn <seq> <crc>')
 else
  begin
   CRC := @HostClient.MapCRC;
   CRC^ := StrToInt(Cmd_Argv(2));
   COM_UnMunge2(CRC, SizeOf(CRC^), Byte(not SVS.SpawnCount));

   if StrToInt(Cmd_Argv(1)) <> SVS.SpawnCount then
    SV_New_F
   else
    begin
     SB.Name := 'Spawning';
     SB.AllowOverflow := [];
     SB.Data := @SBData;
     SB.CurrentSize := 0;
     SB.MaxSize := SizeOf(SBData);

     SZ_Write(SB, SV.Signon.Data, SV.Signon.CurrentSize);

     SV_WriteSpawn(SB);
     SV_WriteVoiceCodec(SB);
     Netchan_CreateFragments(HostClient.Netchan, SB);
     Netchan_FragSend(HostClient.Netchan);
    end;
  end;
end;

procedure SV_SendRes_F; cdecl;
var
 SB: TSizeBuf;
 SBData: array[1..65536] of Byte;
begin
if (CmdSource <> csServer) and (HostClient.Active or not HostClient.Spawned) and (RealTime >= HostClient.SendResTime) then
 begin
  SB.Name := 'SendResources';
  SB.AllowOverflow := [];
  SB.Data := @SBData;
  SB.CurrentSize := 0;
  SB.MaxSize := SizeOf(SBData);

  SV_SendResources(SB);
  Netchan_CreateFragments(HostClient.Netchan, SB);
  Netchan_FragSend(HostClient.Netchan);

  if sv_sendresinterval.Value < 0 then
   CVar_DirectSet(sv_sendresinterval, '0');
  HostClient.SendResTime := RealTime + sv_sendresinterval.Value;
 end;
end;

procedure SV_SendEnts_F; cdecl;
begin
if (CmdSource <> csServer) and HostClient.Active and HostClient.Spawned and HostClient.Connected and
   (RealTime >= HostClient.SendEntsTime) then
 begin
  HostClient.SendInfo := True;

  if sv_sendentsinterval.Value < 0 then
   CVar_DirectSet(sv_sendentsinterval, '0');
  HostClient.SendEntsTime := RealTime + sv_sendentsinterval.Value;
 end;
end;

procedure SV_FullUpdate_F; cdecl;
begin
if (CmdSource <> csServer) and HostClient.Active and SV_FilterFullClientUpdate(HostClient^) then
 begin
  SV_ForceFullClientsUpdate;
  DLLFunctions.ClientCommand(SVPlayer^);
 end;
end;

end.
