unit SVPacket;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure SV_RejectConnection(const Addr: TNetAdr; Msg: PLChar); overload;
procedure SV_RejectConnection(const Addr: TNetAdr; const Msg: array of const); overload;

function SV_GetFragmentSize(C: PClient): UInt32; cdecl;

procedure SV_HandleRconPacket;
function SV_FilterPacket: Boolean;

procedure SV_ReadPackets;

procedure SV_InitRateFilter;
procedure SV_ShutdownRateFilter;

var
 sv_contact: TCVar = (Name: 'sv_contact'; Data: ''; Flags: [FCVAR_SERVER]);
 sv_region: TCVar = (Name: 'sv_region'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_logblocks: TCVar = (Name: 'sv_logblocks'; Data: '0');
 sv_logrelay: TCVar = (Name: 'sv_logrelay'; Data: '0');
 sv_proxies: TCVar = (Name: 'sv_proxies'; Data: '2'; Flags: [FCVAR_SERVER]);

 sv_allow47p: TCVar = (Name: 'sv_allow47p'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_allow48p: TCVar = (Name: 'sv_allow48p'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_maxipsessions: TCVar = (Name: 'sv_maxipsessions'; Data: '5');
 sv_fullservermsg: TCVar = (Name: 'sv_fullservermsg'; Data: 'Server is full.');

 max_queries_sec: TCVar = (Name: 'max_queries_sec'; Data: '3'; Flags: [FCVAR_SERVER, FCVAR_PROTECTED]);
 max_queries_sec_global: TCVar = (Name: 'max_queries_sec_global'; Data: '30'; Flags: [FCVAR_SERVER, FCVAR_PROTECTED]);
 max_queries_window: TCVar = (Name: 'max_queries_window'; Data: '60'; Flags: [FCVAR_SERVER, FCVAR_PROTECTED]);

 sv_limit_queries: TCVar = (Name: 'sv_limit_queries'; Data: '0');
 max_query_ips: TCVar = (Name: 'max_query_ips'; Data: '2048');

 sv_enableoldqueries: TCVar = (Name: 'sv_enableoldqueries'; Data: '0');

implementation

uses Common, Console, Edict, FilterIP, GameLib, Host, Info, Memory, MsgBuf, Network, Resource, Server, SVAuth, SVClient, SVDelta, SVRcon, SVSend;

const
 MAX_CHALLENGES = 1024;

type
 PChallenge = ^TChallenge;
 TChallenge = record
  Addr: TNetAdr;
  Challenge: UInt32;
  Time: UInt32;
 end;

 PIPRate = ^TIPRate;
 TIPRate = record
  TimeStamp: Double;
  NumSent: UInt;
 end;

var
 Challenges: array[0..MAX_CHALLENGES - 1] of TChallenge;

 RateChecker: record
  IPF: TIPFilter;
  Global: TIPRate;
 end;

function CheckIP(const Addr: TNetAdr): Boolean;
var
 IR: PIPRate;
begin
if sv_limit_queries.Value = 0 then
 Result := True
else
 begin
  if max_query_ips.Value > 0 then
   while RateChecker.IPF.TotalIPs > max_query_ips.Value do
    IPF_RemoveOldestChain(RateChecker.IPF);

  if IPF_Search(RateChecker.IPF, PUInt32(@Addr.IP)^, Pointer(IR)) = 0 then
   begin
    IPF_Alloc(RateChecker.IPF, PUInt32(@Addr.IP)^, Pointer(IR));
    IR.TimeStamp := RealTime;
    IR.NumSent := 1;
   end
  else
   if max_queries_window.Value < RealTime - IR.TimeStamp then
    begin
     IR.TimeStamp := RealTime;
     IR.NumSent := 1;
    end
   else
    begin
     Inc(IR.NumSent);
     if IR.NumSent / max_queries_window.Value > max_queries_sec.Value then
      begin
       Result := False;
       Exit;
      end;
    end;

  if max_queries_window.Value < RealTime - RateChecker.Global.TimeStamp then
   begin
    RateChecker.Global.TimeStamp := RealTime;
    RateChecker.Global.NumSent := 1;
    Result := True;
   end
  else
   begin
    Inc(IR.NumSent);
    Result := IR.NumSent / max_queries_window.Value <= max_queries_sec_global.Value;
   end;
 end;
end;

procedure SV_RejectConnection(const Addr: TNetAdr; Msg: PLChar);
begin
SZ_Clear(NetMessage);
MSG_WriteLong(NetMessage, OUTOFBAND_TAG);
MSG_WriteChar(NetMessage, S2C_ERROR);
MSG_WriteString(NetMessage, Msg);
NET_SendPacket(NS_SERVER, NetMessage.CurrentSize, NetMessage.Data, Addr);
SZ_Clear(NetMessage);
end;

procedure SV_RejectConnection(const Addr: TNetAdr; const Msg: array of const);
begin
SV_RejectConnection(Addr, PLChar(StringFromVarRec(Msg)));
end;

procedure SV_RejectConnectionForPassword(const Addr: TNetAdr);
begin
SZ_Clear(NetMessage);
MSG_WriteLong(NetMessage, OUTOFBAND_TAG);
MSG_WriteChar(NetMessage, S2C_PASSWORD);
MSG_WriteString(NetMessage, 'BADPASSWORD');
NET_SendPacket(NS_SERVER, NetMessage.CurrentSize, NetMessage.Data, Addr);
SZ_Clear(NetMessage);
end;

function SV_GetFragmentSize(C: PClient): UInt32; cdecl;
var
 S: PLChar;
begin
if C.Active and C.Spawned and C.SendInfo and C.Connected then
 begin
  S := Info_ValueForKey(@C.UserInfo, 'cl_dlmax');
  if (S = nil) or (S^ = #0) then
   Result := 128
  else
   begin
    Result := StrToInt(S);
    if Result = 0 then
     Result := 128
    else
     if Result < 64 then
      Result := 64
     else
      if Result > 1024 then
       Result := 1024;
   end;
 end
else
 Result := 1024;
end;

function SV_CheckProtocol(const Addr: TNetAdr; Protocol: Int): Boolean;
begin
Result := False;
if (sv_allow47p.Value = 0) and (sv_allow48p.Value = 0) then
 begin
  CVar_DirectSet(sv_allow47p, '1');
  CVar_DirectSet(sv_allow48p, '1');
 end;

if (Protocol = 47) and (sv_allow47p.Value = 0) then
 SV_RejectConnection(Addr, '47 protocol is restricted on this server.'#10)
else
 if (Protocol = 48) and (sv_allow48p.Value = 0) then
  SV_RejectConnection(Addr, '48 protocol is restricted on this server.'#10)
 else
  if (Protocol < 47) or (Protocol > 48) then
   if sv_contact.Data^ = #0 then
    SV_RejectConnection(Addr, ['This server can only support clients with 47/48 protocol, your client is using ', Protocol, '.'#10])
   else
    SV_RejectConnection(Addr, ['This server can only support clients with 47/48 protocol, your client is using ', Protocol, '.'#10 +
                               'If you believe this server is outdated, you can contact the server administrator at ', sv_contact.Data, '.'#10])
  else
   Result := True;
end;

function SV_CheckChallenge(const Addr: TNetAdr; Challenge: UInt32; Reject: Boolean): Boolean;
var
 I: Int;
begin
if NET_IsLocalAddress(Addr) then
 Result := True
else
 begin
  for I := 0 to MAX_CHALLENGES - 1 do
   if NET_CompareBaseAdr(NetFrom, Challenges[I].Addr) then
    begin
     Result := Challenge = Challenges[I].Challenge;
     if not Result and Reject then
      SV_RejectConnection(Addr, 'Bad challenge.'#10);
     Exit;
    end;

  if Reject then
   SV_RejectConnection(Addr, 'No challenge for your address.'#10);
  Result := False;
 end;
end;

function SV_CheckIPRestrictions(const Addr: TNetAdr; Prot: UInt): Boolean;
begin
Result := (sv_lan.Value = 0) or NET_IsReservedAdr(Addr) or NET_CompareClassBAdr(LocalIP, Addr);
end;

function SV_CheckIPConnectionReuse(const Addr: TNetAdr): Boolean;
var
 I: Int;
 J: UInt;
 C: PClient;
 Buf: array[1..64] of LChar;
begin
J := 1;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Connected and not C.SendInfo and NET_CompareBaseAdr(Addr, C.Netchan.Addr) then
   Inc(J);
 end;

Result := J <= sv_maxipsessions.Value;
if not Result then
 LPrint(['Too many active sessions (connect packets) from ', NET_AdrToString(Addr, Buf, SizeOf(Buf)), '; can''t have more than ', Trunc(sv_maxipsessions.Value), ' (sv_maxipsessions).'#10]);
end;

function SV_FinishCertificateCheck(const Addr: TNetAdr; Prot: UInt; CDKey: PLChar; UserInfo: PLChar): Boolean;
begin
Result := True;
end;

function SV_CheckKeyInfo(const Addr: TNetAdr; ProtInfo: PLChar; out Port: UInt16; out Prot: UInt; AuthHash, CDKey: PLChar): Boolean;
var
 S: PLChar;
begin
Prot := StrToInt(Info_ValueForKey(ProtInfo, 'prot'));
if (Prot < 1) or (Prot > 4) then
 begin
  SV_RejectConnection(Addr, 'Invalid authentication type.'#10);
  Result := False;
 end
else
 begin
  Result := True;
  S := Info_ValueForKey(ProtInfo, 'raw');
  if (S = nil) or (S^ = #0) then
   AuthHash^ := #0
  else
   StrLCopy(AuthHash, S, 32);

  S := Info_ValueForKey(ProtInfo, 'cdkey');
  if (S = nil) or (S^ = #0) then
   CDKey^ := #0
  else
   if StrLen(S) <> 32 then
    begin
     SV_RejectConnection(Addr, 'Invalid hashed CD key.'#10);
     Result := False;
    end
   else
    StrCopy(CDKey, S);

  Port := 27005;
 end;
end;

function SV_CheckUserInfo(const Addr: TNetAdr; UserInfo: PLChar; Reconnect: Boolean; UserIndex: UInt; Name: PLChar): Boolean;
var
 S: PLChar;
 AddrBuf: array[1..64] of LChar;
 Buf: array[1..MAX_PLAYER_NAME] of LChar;
 I: UInt;
begin
if (sv_password.Data <> nil) and (sv_password.Data^ > #0) and
   (StrComp(sv_password.Data, 'none') <> 0) and not NET_IsLocalAddress(Addr) then
 begin
  S := Info_ValueForKey(UserInfo, 'password');
  if (S = nil) or (S^ = #0) or (StrComp(sv_password.Data, S) <> 0) then
   begin
    if (S <> nil) and (S^ > #0) then
     Print([NET_AdrToString(Addr, AddrBuf, SizeOf(AddrBuf)), ': password failed (', S, ').'])
    else
     Print([NET_AdrToString(Addr, AddrBuf, SizeOf(AddrBuf)), ': password failed.']);

    SV_RejectConnectionForPassword(Addr);
    Result := False;
    Exit;
   end; 
 end;

if (UserInfo^ = #0) or (StrPos(UserInfo, '\\') <> nil) or (PLChar(UInt(UserInfo) + StrLen(UserInfo) - 1)^ = '\') then
 begin
  SV_RejectConnection(Addr, 'Invalid userinfo.'#10);
  Result := False;
 end
else
 begin
  Info_RemoveKey(UserInfo, 'password');
  S := Info_ValueForKey(UserInfo, 'name');
  if (S <> nil) and (S^ > #0) then
   StrLCopy(@Buf, S, SizeOf(Buf) - 1)
  else
   Buf[1] := #0;

  if Reconnect then
   SV_FilterPlayerName(@Buf, UserIndex)
  else
   SV_FilterPlayerName(@Buf, -1);

  StrCopy(Name, @Buf);
  Info_SetValueForKey(UserInfo, 'name', @Buf, MAX_USERINFO_STRING);

  Result := True;
  S := Info_ValueForKey(UserInfo, '*hltv');
  if (S <> nil) and (S^ > #0) then
   begin
    I := StrToInt(S);
    if I = 1 then
     begin
      I := SV_CountProxies;
      if (I >= sv_proxies.Value) and not Reconnect then
       begin
        if sv_proxies.Value <> 0 then
         SV_RejectConnection(Addr, ['HLTV proxy slots are full (', I, '/', Trunc(sv_proxies.Value), ').'#10])
        else
         SV_RejectConnection(Addr, 'HLTV proxies are not allowed on this server.'#10);

        Result := False;
       end;
     end
    else
     begin
      if I = 2 then
       SV_RejectConnection(Addr, 'Please connect to HLTV master proxy.'#10)
      else
       SV_RejectConnection(Addr, 'Unknown HLTV client type.'#10);
      Result := False;       
     end;
   end;
 end;
end;

function SV_FindEmptySlot(const Addr: TNetAdr; out Index: UInt; out Client: PClient): Boolean;
var
 I: Int;
 C: PClient;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if not C.Active and not C.Spawned and not C.Connected then
   begin
    Index := I;
    Client := C;
    Result := True;
    Exit;
   end;
 end;

if (sv_fullservermsg.Data <> nil) and (sv_fullservermsg.Data^ > #0) then
 SV_RejectConnection(Addr, [sv_fullservermsg.Data, #10])
else
 SV_RejectConnection(Addr, 'Server is full.'#10);
Result := False;
end;

procedure SV_ConnectClient;
var
 Protocol, I: Int;
 Challenge: UInt32;
 AuthHash, CDKey: array[1..33] of LChar;
 ProtInfo, S: PLChar;
 Port: UInt16;
 Prot, ClientIndex: UInt;
 UserInfo: array[1..MAX_USERINFO_STRING] of LChar;
 Reconnect: Boolean;
 UserName: array[1..MAX_PLAYER_NAME] of LChar;
 C: PClient;
 AddrBuf: array[1..64] of LChar;
begin
if Cmd_Argc < 5 then
 SV_RejectConnection(NetFrom, 'Insufficient connection info.'#10)
else
 begin
  Protocol := StrToIntDef(Cmd_Argv(1), -1);
  if Protocol < 0 then
   SV_RejectConnection(NetFrom, 'Invalid client protocol.'#10)
  else
   begin
    if not SV_CheckProtocol(NetFrom, Protocol) then
     Exit;

    Challenge := StrToInt(Cmd_Argv(2));
    if not SV_CheckChallenge(NetFrom, Challenge, True) then
     Exit;

    ProtInfo := Cmd_Argv(3);
    if not Info_IsValid(ProtInfo) then
     begin
      SV_RejectConnection(NetFrom, 'Invalid protinfo in connect command.'#10);
      Exit;
     end;

    MemSet(AuthHash, SizeOf(AuthHash), 0);
    MemSet(CDKey, SizeOf(CDKey), 0);
    if not SV_CheckKeyInfo(NetFrom, ProtInfo, Port, Prot, @AuthHash, @CDKey) then
     Exit;

    if not SV_CheckIPRestrictions(NetFrom, Prot) then
     begin
      SV_RejectConnection(NetFrom, 'LAN servers are restricted only to local clients (class C).'#10);
      Exit;
     end;

    S := Cmd_Argv(4);
    if (StrLen(S) >= MAX_USERINFO_STRING) or not Info_IsValid(S) then
     begin
      SV_RejectConnection(NetFrom, 'Invalid userinfo in connect command.'#10);
      Exit;
     end;

    StrLCopy(@UserInfo, S, MAX_USERINFO_STRING - 1);

    Reconnect := False;
    ClientIndex := 0;
    for I := 0 to SVS.MaxClients - 1 do
     if NET_CompareAdr(SVS.Clients[I].Netchan.Addr, NetFrom) then
      begin
       Reconnect := True;
       ClientIndex := I;
       Break;
      end;

    MemSet(UserName, SizeOf(UserName), 0);
    if not SV_CheckUserInfo(NetFrom, @UserInfo, Reconnect, ClientIndex, @UserName) or
       not SV_FinishCertificateCheck(NetFrom, Prot, @AuthHash, @UserInfo) then
     Exit;

    if Reconnect then
     begin
      C := @SVS.Clients[ClientIndex];
      if (C.Active or C.Spawned) and (C.Entity <> nil) then
       DLLFunctions.ClientDisconnect(C.Entity^);
       
      Print([NET_AdrToString(NetFrom, AddrBuf, SizeOf(AddrBuf)), ': reconnect.']);
     end
    else
     if not SV_FindEmptySlot(NetFrom, ClientIndex, C) then
      Exit;

    if not SV_CheckIPConnectionReuse(NetFrom) then
     Exit;

    HostClient := C;
    C.UserID := CurrentUserID;
    Inc(CurrentUserID);

    S := Info_ValueForKey(@UserInfo, '*hltv');
    if (S <> nil) and (S^ > #0) then
     begin
      C.Auth.AuthType := atHLTV;
      C.Auth.UniqueID := 0;
      PUInt32(@C.Auth.IP)^ := PUInt32(@NetFrom.IP)^;
     end
    else
     begin
      C.Auth.AuthType := atSteam;
      C.Auth.UniqueID := 0;

      if NetFrom.AddrType = NA_LOOPBACK then
       if sv_lan.Value = 0 then
        PUInt32(@C.Auth.IP)^ := PUInt32(@LocalIP.IP)^
       else
        PUInt32(@C.Auth.IP)^ := $7F000001
      else
       PUInt32(@C.Auth.IP)^ := PUInt32(@NetFrom.IP)^;
     end;

    if NetFrom.Port <> 0 then
     Port := NetFrom.Port;
    C.Netchan.Addr.Port := Port;

    SV_ClearResourceLists(C^);
    if C.Frames <> nil then
     SV_ClearFrames(C.Frames);
    C.Frames := Mem_ZeroAlloc(SVUpdateBackup * SizeOf(TClientFrame));

    C.DownloadList.Next := @C.DownloadList;
    C.DownloadList.Prev := @C.DownloadList;
    C.UploadList.Next := @C.UploadList;
    C.UploadList.Prev := @C.UploadList;
    C.Entity := EDICT_NUM(ClientIndex + 1);

    C.FakeClient := False;
    C.Protocol := Protocol;

    C.SendResTime := 0;
    C.SendEntsTime := 0;
    C.FullUpdateTime := 0;

    Netchan_Setup(NS_SERVER, C.Netchan, NetFrom, ClientIndex, C, SV_GetFragmentSize);

    C.UpdateRate := 0.05;
    C.NextUpdateTime := RealTime + 0.05;
    C.UpdateMask := -1;
    MemSet(C.UserCmd, SizeOf(C.UserCmd), 0);
    C.NextPingTime := 0;
    StrLCopy(@C.CDKey, @CDKey, SizeOf(C.CDKey) - 1);

    NET_AdrToString(C.Netchan.Addr, AddrBuf, SizeOf(AddrBuf));
    
    if C.Netchan.Addr.AddrType = NA_LOOPBACK then
     DPrint('Local connection.')
    else
     DPrint(['Client ', PLChar(@UserName), ' connected (', PLChar(@AddrBuf), ').']);

    C.Active := False;
    C.Spawned := False;
    C.SendInfo := False;
    C.Connected := True;
    C.HasMissingResources := False;

    C.ConnectSeq := 0;
    C.SpawnSeq := 0;

    Netchan_OutOfBandPrint(NS_SERVER, C.Netchan.Addr, [LChar(S2C_CONNECT), ' ', C.UserID, ' "', PLChar(@AddrBuf), '" 0']);
    LPrint(['"', PLChar(@UserName), '<', C.UserID, '><', SV_GetClientIDString(C^), '><>" connected (', PLChar(@AddrBuf), ').'#10]);

    StrLCopy(@C.UserInfo, @UserInfo, SizeOf(C.UserInfo) - 1);
    SV_ExtractFromUserInfo(C^);

    Info_SetValueForStarKey(@C.UserInfo, '*sid', PLChar(IntToStr(C.Auth.UniqueID)), MAX_USERINFO_STRING);

    C.UnreliableMessage.AllowOverflow := [FSB_ALLOWOVERFLOW];
    C.UnreliableMessage.Name := PLChar(@C.NetName);
    C.UnreliableMessage.Data := @C.UnreliableMessageData;
    C.UnreliableMessage.MaxSize := SizeOf(C.UnreliableMessageData);
    C.UnreliableMessage.CurrentSize := 0;

    C.UpdateInfoTime := 0;
   end;
 end;
end;

procedure SVC_Ping;
const
 Buffer: array[1..6] of Byte =
  ($FF, $FF, $FF, $FF, Byte(A2A_ACK), 0);
begin
NET_SendPacket(NS_SERVER, SizeOf(Buffer), @Buffer, NetFrom);
end;

function SV_DispatchChallenge(const Addr: TNetAdr): PChallenge;
var
 I, J: Int;
 C: PChallenge;
 MinTime: UInt32;
begin
J := 0;
MinTime := $FFFFFFFF;

for I := 0 to MAX_CHALLENGES - 1 do
 begin
  C := @Challenges[I];
  if NET_CompareBaseAdr(Addr, C.Addr) then
   begin
    Result := C;
    Exit;
   end
  else
   if C.Time < MinTime then
    begin
     MinTime := C.Time;
     J := I;
    end;
 end;

Result := @Challenges[J];

Result.Addr := Addr;
Result.Challenge := RandomLong(0, 65535) or (RandomLong(0, 36863) shl 16);
Result.Time := Trunc(RealTime);
end;

procedure SVC_GetChallenge;
var
 B: Boolean;
 Buf: array[1..128] of LChar;
 S: PLChar;
begin
B := (Cmd_Argc = 2) and (StrIComp(Cmd_Argv(1), 'steam') = 0);

S := StrECopy(@Buf, (#$FF#$FF#$FF#$FF + S2C_CHALLENGE + '00000000 '));
S := UIntToStrE(SV_DispatchChallenge(NetFrom).Challenge, S^, 32);

if B then
 if sv_secureflag.Value <> 0 then
  StrCopy(S, ' 3 0 1'#10)
 else
  StrCopy(S, ' 3 0 0'#10)
else
 StrCopy(S, ' 2'#10);

NET_SendPacket(NS_SERVER, StrLen(@Buf) + 1, @Buf, NetFrom);
end;

procedure SVC_ServiceChallenge;
var
 Buf: array[1..128] of LChar;
 S, S2: PLChar;
begin
if Cmd_Argc = 2 then
 begin
  S := Cmd_Argv(1);
  if (S <> nil) and (S^ > #0) and (StrIComp(S, 'rcon') = 0) and (StrLen(S) <= 64) then
   begin
    S2 := StrECopy(@Buf, (#$FF#$FF#$FF#$FF + 'challenge '));
    S2 := StrECopy(S2, S);
    S2 := StrECopy(S2, ' ');
    S2 := UIntToStrE(SV_DispatchChallenge(NetFrom).Challenge, S2^, 32);
    StrCopy(S2, #10);

    NET_SendPacket(NS_SERVER, StrLen(@Buf) + 1, @Buf, NetFrom);
   end;
 end;
end;

function SVC_GameDllQuery(S: PLChar): Int;
var
 Buf: packed record Seq: Int32; Data: array[1..2044] of Byte; end;
 Size: Int32;
begin
if SV.Active and (SVS.MaxClients > 1) then
 begin
  Buf.Seq := -1;
  Size := SizeOf(Buf.Data);
  MemSet(Buf.Data, Size, 0);
  Result := DLLFunctions.ConnectionlessPacket(NetFrom, S, @Buf.Data, Size);
  if (Size > 0) and (Size <= SizeOf(Buf.Data)) then
   NET_SendPacket(NS_SERVER, Size + SizeOf(Buf.Seq), @Buf, NetFrom);
 end
else
 Result := 0;
end;

procedure SVC_Info;
var
 SBData: array[1..1400] of Byte;
 NetAdrBuf: array[1..64] of LChar;
 SB: TSizeBuf;
begin
SB.Name := 'SVC_Info';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

MSG_WriteLong(SB, OUTOFBAND_TAG);
MSG_WriteChar(SB, S2C_INFO);
if NoIP then
 if NoIPX then
  MSG_WriteString(SB, 'LOOPBACK')
 else
  MSG_WriteString(SB, NET_AdrToString(LocalIPX, NetAdrBuf, SizeOf(NetAdrBuf)))
else
 MSG_WriteString(SB, NET_AdrToString(LocalIP, NetAdrBuf, SizeOf(NetAdrBuf)));

MSG_WriteString(SB, hostname.Data);
if PLChar(@SV.Map)^ > #0 then
 MSG_WriteString(SB, @SV.Map)
else
 MSG_WriteString(SB, 'inactive');

MSG_WriteString(SB, GameDir);
MSG_WriteString(SB, DLLFunctions.GetGameDescription);

MSG_WriteByte(SB, Min(SV_CountPlayers, High(Byte)));
if sv_visiblemaxplayers.Value < 0 then
 MSG_WriteByte(SB, Min(SVS.MaxClients, High(Byte)))
else
 MSG_WriteByte(SB, Min(Trunc(sv_visiblemaxplayers.Value), High(Byte)));

MSG_WriteByte(SB, 48);
MSG_WriteChar(SB, 'd');
MSG_WriteChar(SB, {$IFDEF MSWINDOWS}'w'{$ELSE}'l'{$ENDIF});

if (sv_password.Data^ > #0) and (StrComp(sv_password.Data, 'none') <> 0) then 
 MSG_WriteByte(SB, 1)
else
 MSG_WriteByte(SB, 0);

if ModInfo.CustomGame then
 begin
  MSG_WriteByte(SB, 1);
  MSG_WriteString(SB, @ModInfo.URLInfo);
  MSG_WriteString(SB, @ModInfo.URLDownload);
  MSG_WriteString(SB, EmptyString);
  MSG_WriteLong(SB, ModInfo.Version);
  MSG_WriteLong(SB, ModInfo.Size);
  MSG_WriteByte(SB, UInt(ModInfo.SVOnly));
  MSG_WriteByte(SB, UInt(ModInfo.ClientDLL));
 end
else
 MSG_WriteByte(SB, 0);

MSG_WriteByte(SB, UInt(sv_secureflag.Value <> 0));
MSG_WriteByte(SB, Min(SV_GetFakeClientCount, High(Byte)));

if not (FSB_OVERFLOWED in SB.AllowOverflow) then
 NET_SendPacket(NS_SERVER, SB.CurrentSize, SB.Data, NetFrom);
end;

procedure SVC_InfoString;
var
 SBData: array[1..8192] of Byte;
 NetAdrBuf: array[1..64] of LChar;
 SB: TSizeBuf;
 Players, Proxies, FakeClients: UInt;
 I: Int;
 C: PClient;
 S: PLChar;
begin
SB.Name := 'SVC_InfoString';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

Players := 0;
Proxies := 0;
FakeClients := 0;

for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.FakeClient then
   Inc(FakeClients)
  else
   if C.HLTV then
    Inc(Proxies)
   else
    if C.Active or C.Spawned or C.Connected then
     Inc(Players);
 end;

MSG_WriteLong(SB, OUTOFBAND_TAG);
MSG_WriteString(SB, 'infostringresponse');

S := PLChar(UInt(@SBData) + SB.CurrentSize);
S := StrECopy(S, '\protocol\48\address\');

if NoIP then
 if NoIPX then
  S := StrECopy(S, 'LOOPBACK')
 else
  S := StrECopy(S, NET_AdrToString(LocalIPX, NetAdrBuf, SizeOf(NetAdrBuf)))
else
 S := StrECopy(S, NET_AdrToString(LocalIP, NetAdrBuf, SizeOf(NetAdrBuf)));

S := StrECopy(S, '\players\');
S := IntToStrE(Players, S^, 16);
if Proxies > 0 then
 begin
  S := StrECopy(S, '\proxytarget\');
  S := IntToStrE(Proxies, S^, 16);
 end;

if sv_lan.Value <> 0 then
 S := StrECopy(S, '\lan\1\max\')
else
 S := StrECopy(S, '\lan\0\max\');

if sv_visiblemaxplayers.Value < 0 then
 S := IntToStrE(SVS.MaxClients, S^, 16)
else
 S := IntToStrE(Trunc(sv_visiblemaxplayers.Value), S^, 16);

S := StrECopy(S, '\bots\');
S := IntToStrE(FakeClients, S^, 16);

S := StrECopy(S, '\gamedir\');
S := StrLECopy(S, GameDir, 128);

S := StrECopy(S, '\description\');
S := StrLECopy(S, DLLFunctions.GetGameDescription, 256);

S := StrECopy(S, '\hostname\');
S := StrLECopy(S, hostname.Data, 256);

S := StrECopy(S, '\map\');
if PLChar(@SV.Map)^ > #0 then
 S := StrLECopy(S, @SV.Map, 64)
else
 S := StrECopy(S, 'inactive');

if (sv_password.Data^ > #0) and (StrComp(sv_password.Data, 'none') <> 0) then
 S := StrECopy(S, '\type\d\password\1\os\')
else
 S := StrECopy(S, '\type\d\password\0\os\');

{$IFDEF MSWINDOWS}
 S := StrECopy(S, 'w\secure\');
{$ELSE}
 S := StrECopy(S, 'l\secure\');
{$ENDIF}

if sv_secureflag.Value <> 0 then
 S := StrECopy(S, '1')
else
 S := StrECopy(S, '0');

if ModInfo.CustomGame then
 begin
  S := StrECopy(S, '\mod\1\modversion\');
  S := IntToStrE(ModInfo.Version, S^, 16);
  S := StrECopy(S, '\svonly\');
  S := IntToStrE(UInt(ModInfo.SVOnly), S^, 16);
  S := StrECopy(S, '\cldll\');
  S := IntToStrE(UInt(ModInfo.ClientDLL), S^, 16);
 end;

SB.CurrentSize := UInt(S) - UInt(@SBData); 
NET_SendPacket(NS_SERVER, SB.CurrentSize, SB.Data, NetFrom);
end;

procedure SVC_PlayerInfo;
var
 SBData: array[1..8192] of Byte;
 SB: TSizeBuf;
 Players: UInt;
 I: Int;
 C: PClient;
begin
SB.Name := 'SVC_PlayerInfo';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

MSG_WriteLong(SB, OUTOFBAND_TAG);
MSG_WriteChar(SB, S2C_PLAYERS);

if not SV.Active then
 MSG_WriteByte(SB, 0)
else
 begin
  Players := 0;
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if (C.Active or C.Spawned or C.Connected) and (C.Entity <> nil) then
     Inc(Players);
   end;

  MSG_WriteByte(SB, Min(Players, High(Byte)));

  Players := 0;
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if (C.Active or C.Spawned or C.Connected) and (C.Entity <> nil) then
     begin
      Inc(Players);
      MSG_WriteByte(SB, Players);
      MSG_WriteString(SB, @C.NetName);
      MSG_WriteLong(SB, Trunc(C.Entity.V.Frags));
      MSG_WriteFloat(SB, RealTime - C.Netchan.FirstReceived);
     end;
   end;
 end;

if not (FSB_OVERFLOWED in SB.AllowOverflow) then
 NET_SendPacket(NS_SERVER, SB.CurrentSize, SB.Data, NetFrom);
end;

procedure SVC_RuleInfo;
var
 SBData: array[1..8192] of Byte;
 SB: TSizeBuf;
 Num: UInt;
 P: PCVar;
begin
SB.Name := 'SVC_RuleInfo';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

MSG_WriteLong(SB, OUTOFBAND_TAG);
MSG_WriteChar(SB, S2C_RULES);

if not SV.Active then
 MSG_WriteShort(SB, 0)
else
 begin
  Num := CVar_CountServerVariables;
  MSG_WriteShort(SB, Num);

  P := CVarBase;
  while P <> nil do
   begin
    if FCVAR_SERVER in P.Flags then
     begin
      MSG_WriteString(SB, P.Name);
      if FCVAR_PROTECTED in P.Flags then
       if (P.Data^ = #0) or (StrComp(P.Data, 'none') = 0) then
        MSG_WriteString(SB, '0')
       else
        MSG_WriteString(SB, '1')
      else
       MSG_WriteString(SB, P.Data);
     end;

    P := P.Next;
   end;

  if not (FSB_OVERFLOWED in SB.AllowOverflow) then
   NET_SendPacket(NS_SERVER, SB.CurrentSize, SB.Data, NetFrom);
 end;
end;

procedure SVC_GetChallenge_New;
var
 SBData: array[1..32] of Byte;
 SB: TSizeBuf;
begin
SB.Name := 'SVC_GetChallenge_New';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

MSG_WriteLong(SB, OUTOFBAND_TAG);
MSG_WriteChar(SB, S2C_CHALLENGE);
MSG_WriteLong(SB, SV_DispatchChallenge(NetFrom).Challenge);

if not (FSB_OVERFLOWED in SB.AllowOverflow) then
 NET_SendPacket(NS_SERVER, SB.CurrentSize, SB.Data, NetFrom);
end;

procedure SVC_Info_New;
var
 SBData: array[1..1400] of Byte;
 SB: TSizeBuf;
 Payload: PLChar;
begin
Payload := MSG_ReadString;
if MSG_BadRead or (StrComp(Payload, 'Source Engine Query') <> 0) then
 Exit;

SB.Name := 'SVC_Info_New';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

MSG_WriteLong(SB, OUTOFBAND_TAG);
MSG_WriteChar(SB, S2C_INFO_NEW);
MSG_WriteByte(SB, 48);

MSG_WriteString(SB, hostname.Data);
if PLChar(@SV.Map)^ > #0 then
 MSG_WriteString(SB, @SV.Map)
else
 MSG_WriteString(SB, 'inactive');

MSG_WriteString(SB, GameDir);
MSG_WriteString(SB, DLLFunctions.GetGameDescription);
MSG_WriteShort(SB, GetGameAppID);

MSG_WriteByte(SB, Min(SV_CountPlayers, High(Byte)));
if sv_visiblemaxplayers.Value < 0 then
 MSG_WriteByte(SB, Min(SVS.MaxClients, High(Byte)))
else
 MSG_WriteByte(SB, Min(Trunc(sv_visiblemaxplayers.Value), High(Byte)));

MSG_WriteByte(SB, Min(SV_GetFakeClientCount, High(Byte)));
MSG_WriteChar(SB, 'd');
MSG_WriteChar(SB, {$IFDEF MSWINDOWS}'w'{$ELSE}'l'{$ENDIF});

if (sv_password.Data^ > #0) and (StrComp(sv_password.Data, 'none') <> 0) then
 MSG_WriteByte(SB, 1)
else
 MSG_WriteByte(SB, 0);

MSG_WriteByte(SB, UInt(sv_secureflag.Value <> 0));

if not (FSB_OVERFLOWED in SB.AllowOverflow) then
 NET_SendPacket(NS_SERVER, SB.CurrentSize, SB.Data, NetFrom);
end;

procedure SVC_PlayerInfo_New;
var
 Challenge: UInt32;
begin
Challenge := MSG_ReadLong;
if Challenge = $FFFFFFFF then
 SVC_GetChallenge_New
else
 if SV_CheckChallenge(NetFrom, Challenge, False) then
  SVC_PlayerInfo;
end;

procedure SVC_RuleInfo_New;
var
 Challenge: UInt32;
begin
Challenge := MSG_ReadLong;
if Challenge = $FFFFFFFF then
 SVC_GetChallenge_New
else
 if SV_CheckChallenge(NetFrom, Challenge, False) then
  SVC_RuleInfo;
end;

function SV_NewRequestQuery: Boolean;
var
 C: LChar;
begin
C := MSG_ReadChar;
if MSG_BadRead then
 Result := False
else
 case C of
  C2S_INFO_NEW: begin SVC_Info_New; Result := True; end;
  C2S_PLAYERS_NEW: begin SVC_PlayerInfo_New; Result := True; end;
  C2S_RULES_NEW: begin SVC_RuleInfo_New; Result := True; end;
  C2S_SERVERQUERY_GETCHALLENGE: begin SVC_GetChallenge_New; Result := True; end;
  else Result := False;
 end;

if not Result and not MSG_BadRead then
 Dec(MSG_ReadCount);
end;

procedure SV_ConnectionlessPacket;
var
 NetAdrBuf: array[1..128] of LChar;
 S, S2: PLChar;
 C: LChar;
begin
if CheckIP(NetFrom) then
 begin
  MSG_BeginReading;
  if (MSG_ReadLong <> OUTOFBAND_TAG) or MSG_BadRead then
   Exit;

  if SV_NewRequestQuery then
   Exit;

  S2 := MSG_ReadStringLine;
  Cmd_TokenizeString(S2);
  S := Cmd_Argv(0);
  if (S = nil) or (S^ = #0) or MSG_BadRead then
   Exit;
  C := PLChar(UInt(S) + 1)^;

  if (StrComp(S, 'ping') = 0) or ((S^ = C2S_PING) and ((C = #0) or (C = #10))) then
   SVC_Ping
  else
   if ((S^ = A2A_ACK) and ((C = #0) or (C = #10))) or (S^ in ['R', 'O', 's']) then
    Exit
   else
    if StrIComp(S, 'log') = 0 then
     if sv_logrelay.Value = 0 then
      Exit
     else
      begin
       if (S2 <> nil) and (StrLen(S2) > 4) then
        begin
         S2 := PLChar(UInt(S2) + 4);
         if S2^ > #0 then
          Print(S2);
        end;
      end
     else
      if StrComp(S, 'getchallenge') = 0 then
       SVC_GetChallenge
      else
       if StrIComp(S, 'challenge') = 0 then
        SVC_ServiceChallenge
       else
        if StrComp(S, 'connect') = 0 then
         SV_ConnectClient
        else
         if StrComp(S, 'pstat') = 0 then
          Exit
         else
          if StrComp(S, 'rcon') = 0 then
           SV_Rcon(NetFrom)
          else
           begin
            if sv_enableoldqueries.Value <> 0 then
             if StrComp(S, 'players') = 0 then
              begin
               SVC_PlayerInfo;
               Exit;
              end
             else
              if StrComp(S, 'rules') = 0 then
               begin
                SVC_RuleInfo;
                Exit;
               end;

            SVC_GameDllQuery(S2);
           end;
 end
else
 if sv_logblocks.Value <> 0 then
  LPrint(['Traffic from ', NET_AdrToString(NetFrom, NetAdrBuf, SizeOf(NetAdrBuf)), ' was blocked for exceeding rate limits.'#10]);
end;

procedure SVC_BlockConnect;
begin
SV_RejectConnection(NetFrom, 'The server isn''t running any map.');
end;

procedure SV_HandleRconPacket;
var
 S: PLChar;
 C: LChar;
begin
if CheckIP(NetFrom) then
 begin
  MSG_BeginReading;
  if (MSG_ReadLong <> OUTOFBAND_TAG) or MSG_BadRead then
   Exit;

  if SV_NewRequestQuery then
   Exit;

  Cmd_TokenizeString(MSG_ReadStringLine);
  S := Cmd_Argv(0);
  if (S = nil) or (S^ = #0) or MSG_BadRead then
   Exit;

  C := PLChar(UInt(S) + 1)^;
  if (StrComp(S, 'ping') = 0) or ((S^ = C2S_PING) and ((C = #0) or (C = #10))) then
   SVC_Ping
  else
   if StrComp(S, 'getchallenge') = 0 then
    SVC_GetChallenge
   else
    if StrIComp(S, 'challenge') = 0 then
     SVC_ServiceChallenge
    else
     if StrComp(S, 'connect') = 0 then
      SVC_BlockConnect
     else
      if StrComp(S, 'rcon') = 0 then
       SV_Rcon(NetFrom)
      else
       if sv_enableoldqueries.Value <> 0 then
        if StrComp(S, 'players') = 0 then
         SVC_PlayerInfo
        else
         if StrComp(S, 'rules') = 0 then
          SVC_RuleInfo;
 end;
end;

function SV_FilterPacket: Boolean;
begin
Result := False;
end;

procedure SV_ReadPackets;
var
 I: Int;
 C: PClient;
begin
while NET_GetPacket(NS_SERVER) do
 if SV_FilterPacket then
  SV_SendBan
 else
  if PInt32(NetMessage.Data)^ = OUTOFBAND_TAG then
   SV_ConnectionlessPacket
  else
   for I := 0 to SVS.MaxClients - 1 do
    begin
     C := @SVS.Clients[I];
     if (C.Active or C.Spawned or C.Connected) and NET_CompareAdr(NetFrom, C.Netchan.Addr) then
      begin
       if Netchan_Process(C.Netchan) then
        begin
         if (SVS.MaxClients = 1) or not C.Active or not C.Spawned or not C.SendInfo then
          C.NeedUpdate := True;

         SV_ExecuteClientMessage(C^);
         GlobalVars.FrameTime := HostFrameTime;
        end;

       if Netchan_IncomingReady(C.Netchan) then
        begin
         if Netchan_CopyNormalFragments(C.Netchan) then
          begin
           MSG_BeginReading;
           SV_ExecuteClientMessage(C^);
          end;

         if Netchan_CopyFileFragments(C.Netchan) then
          begin
           HostClient := C;
           SV_ProcessFile(C^, @C.Netchan.FileName);
          end;
        end;
      end;
    end;    
end;

procedure SV_InitRateFilter;
begin
IPF_Init(RateChecker.IPF, nil, SizeOf(TIPRate));
RateChecker.Global.TimeStamp := 0;
RateChecker.Global.NumSent := 0;
end;

procedure SV_ShutdownRateFilter;
begin
IPF_Shutdown(RateChecker.IPF);
end;

end.
