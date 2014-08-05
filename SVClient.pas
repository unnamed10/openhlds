unit SVClient;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure SV_CountPlayers(out Players: UInt);
procedure SV_CountProxies(out Proxies: UInt);
function SV_GetFakeClientCount: UInt;
function SV_CalcPing(const C: TClient): UInt;

procedure SV_DropClient(var C: TClient; SkipNotify: Boolean; Msg: PLChar); overload;
procedure SV_DropClient(var C: TClient; SkipNotify: Boolean; const Msg: array of const); overload;

procedure SV_BroadcastCommand(S: PLChar); overload;
procedure SV_BroadcastCommand(const S: array of const); overload;
procedure SV_BroadcastPrint(Msg: PLChar); overload;
procedure SV_BroadcastPrint(const Msg: array of const); overload;

procedure SV_SkipUpdates;

function SV_FilterPlayerName(Name: PLChar; IgnoreClient: Int = -1): Boolean;

procedure SV_ClearFrames(var CF: TClientFrameArrayPtr);
procedure SV_ExtractFromUserInfo(var C: TClient);

procedure SV_FullClientUpdate(const C: TClient; var SB: TSizeBuf);
procedure SV_ForceFullClientsUpdate;
function SV_FilterFullClientUpdate(const C: TClient): Boolean;
procedure SV_ClearFullUpdateFilter;

procedure SV_ClientPrint(Msg: PLChar); overload;
procedure SV_ClientPrint(const Msg: array of const); overload;

procedure SV_WriteSpawn(var SB: TSizeBuf);
procedure SV_WriteVoiceCodec(var SB: TSizeBuf);

procedure SV_SendUserReg(var SB: TSizeBuf);
procedure SV_SendServerInfo(var SB: TSizeBuf; var C: TClient);
procedure SV_SendResources(var SB: TSizeBuf);
procedure SV_BuildReconnect(var SB: TSizeBuf);

function SV_IsPlayerIndex(I: UInt): Boolean;

procedure SV_AllocClientFrames;
procedure SV_ClearClientFrames;
procedure SV_ClearClientStates;
procedure SV_InactivateClients;

procedure SV_ClearPacketEntities(var Frame: TClientFrame);
procedure SV_AllocPacketEntities(var Frame: TClientFrame; NumEnts: UInt);

procedure SV_SetMaxClients;

procedure SV_ParseStringCommand(var C: TClient);
procedure SV_ParseVoiceData(var C: TClient);
procedure SV_IgnoreHLTV(var C: TClient);
procedure SV_ParseCVarValue(var C: TClient);
procedure SV_ParseCVarValue2(var C: TClient);

procedure SV_ExecuteClientMessage(var C: TClient);

procedure SV_WriteMoveVarsToClient(var SB: TSizeBuf);

procedure SV_CheckTimeouts;
function SV_ShouldUpdatePing(var C: TClient): Boolean;

procedure SV_EmitPings(var SB: TSizeBuf);

procedure SV_SendClientMessages;

var
 sv_defaultplayername: TCVar = (Name: 'sv_defaultplayername'; Data: 'unnamed');
 sv_use2asnameprefix: TCVar = (Name: 'sv_use2asnameprefix'; Data: '0');

 sv_maxupdaterate: TCVar = (Name: 'sv_maxupdaterate'; Data: '30'; Flags: [FCVAR_SERVER]);
 sv_minupdaterate: TCVar = (Name: 'sv_minupdaterate'; Data: '10'; Flags: [FCVAR_SERVER]);
 sv_defaultupdaterate: TCVar = (Name: 'sv_defaultupdaterate'; Data: '20');
 sv_maxrate: TCVar = (Name: 'sv_maxrate'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_minrate: TCVar = (Name: 'sv_minrate'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_defaultrate: TCVar = (Name: 'sv_defaultrate'; Data: '9999');

 sv_filterfullupdate: TCVar = (Name: 'sv_filterfullupdate'; Data: '1');
 sv_fullupdateinterval: TCVar = (Name: 'sv_fullupdateinterval'; Data: '0.45');
 sv_fullupdatemaxcmds: TCVar = (Name: 'sv_fullupdatemaxcmds'; Data: '2');

 sv_failuretime: TCVar = (Name: 'sv_failuretime'; Data: '0.5');

 sv_pinginterval: TCVar = (Name: 'sv_pinginterval'; Data: '1');

var
 CurrentUserID: UInt = 1;

implementation

uses Common, Console, Delta, Edict, Encode, GameLib, Info, Host, Memory, MsgBuf, Network, PMove, Resource, Server, SVAuth, SVDelta, SVEdict, SVMove, SVSend, SysArgs;

const
 CLCommands: array[1..22] of PLChar =
  ('status', 'god', 'notarget', 'fly', 'name', 'noclip', 'kill', 'pause', 'spawn', 'new',
   'sendres', 'dropclient', 'kick', 'ping', 'dlfile', 'nextdl', 'setinfo', 'showinfo', 'sendents', 'fullupdate',
   'setpause', 'unpause');

 CLCFuncs: array[CLC_BAD..CLC_MESSAGE_END] of record Index: UInt; Name: PLChar; Func: procedure(var C: TClient); end =
  ((Index: 0; Name: 'clc_bad'; Func: nil),
   (Index: 1; Name: 'clc_nop'; Func: nil),
   (Index: 2; Name: 'clc_move'; Func: SV_ParseMove),
   (Index: 3; Name: 'clc_stringcmd'; Func: SV_ParseStringCommand),
   (Index: 4; Name: 'clc_delta'; Func: SV_ParseDelta),
   (Index: 5; Name: 'clc_resourcelist'; Func: SV_ParseResourceList),
   (Index: 6; Name: 'clc_tmove'; Func: nil),
   (Index: 7; Name: 'clc_fileconsistency'; Func: SV_ParseConsistencyResponse),
   (Index: 8; Name: 'clc_voicedata'; Func: SV_ParseVoiceData),
   (Index: 9; Name: 'clc_hltv'; Func: SV_IgnoreHLTV),
   (Index: 10; Name: 'clc_cvarvalue'; Func: SV_ParseCVarValue),
   (Index: 11; Name: 'clc_cvarvalue2'; Func: SV_ParseCVarValue2));
 
procedure SV_CountPlayers(out Players: UInt);
var
 I: Int;
 C: PClient;
begin
Players := 0;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Active or C.Spawned or C.Connected then
   Inc(Players);
 end;
end;

procedure SV_CountProxies(out Proxies: UInt);
var
 I: Int;
 C: PClient;
begin
Proxies := 0;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Spawned or C.Connected) and C.HLTV then
   Inc(Proxies);
 end;
end;

function SV_GetFakeClientCount: UInt;
var
 I: Int;
begin
Result := 0;
for I := 0 to SVS.MaxClients - 1 do
 if SVS.Clients[I].FakeClient then
  Inc(Result);
end;

procedure SV_DropClient(var C: TClient; SkipNotify: Boolean; Msg: PLChar);
var
 Buf: array[1..512] of LChar;
 L: UInt;
 TimePlaying: Single;
begin
if not SkipNotify then
 begin
  if not C.FakeClient then
   begin
    MSG_WriteByte(C.Netchan.NetMessage, SVC_DISCONNECT);
    MSG_WriteString(C.Netchan.NetMessage, Msg);
    L := StrLen(Msg);
    if L > SizeOf(Buf) - 2 then
     L := SizeOf(Buf) - 2;

    PByte(@Buf)^ := SVC_DISCONNECT;
    StrLCopy(PLChar(UInt(@Buf) + 1), Msg, L);
   end
  else
   L := 0;

  if (C.Entity <> nil) and C.Spawned then
   DLLFunctions.ClientDisconnect(C.Entity^);

  Print(['Dropped ', PLChar(@C.NetName), ' from server.' + LineBreak +
         'Reason: ', Msg]);

  if not C.FakeClient then
   Netchan_Transmit(C.Netchan, L + 2, @Buf);
 end;

TimePlaying := RealTime - C.Netchan.FirstReceived;
if TimePlaying > 60 then
 begin
  Inc(SVS.Stats.NumDrops);
  SVS.Stats.AccumTimePlaying := SVS.Stats.AccumTimePlaying + TimePlaying;
 end;

SV_FullClientUpdate(C, SV.ReliableDatagram);

COM_ClearCustomizationList(C.Customization);
SV_ClearResourceList(C.UploadList);
SV_ClearResourceList(C.DownloadList);

Netchan_Clear(C.Netchan);

C.ConnectTime := RealTime;
C.Active := False;
C.Spawned := False;
C.SendInfo := False;
C.Connected := False;
C.UserMsgReady := False;
C.FakeClient := False;
C.NetName[Low(C.NetName)] := #0;
C.HLTV := False;
C.BlockedVoice := [];
C.VoiceLoopback := False;
C.Entity := nil;

MemSet(C.UserInfo, SizeOf(C.UserInfo), 0);
MemSet(C.PhysInfo, SizeOf(C.PhysInfo), 0);
end;

procedure SV_DropClient(var C: TClient; SkipNotify: Boolean; const Msg: array of const);
begin
SV_DropClient(C, SkipNotify, PLChar(StringFromVarRec(Msg)));
end;

procedure SV_BroadcastCommand(S: PLChar);
var
 I: Int;
 C: PClient;
begin
if SV.Active then
 if StrLen(S) > 128 then
  Print('SV_BroadcastCommand: The command is too long, ignoring.')
 else
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if (C.Active or C.Spawned or C.Connected) and not C.FakeClient then
     begin
      MSG_WriteByte(C.Netchan.NetMessage, SVC_STUFFTEXT);
      MSG_WriteString(C.Netchan.NetMessage, S);
     end;
   end;
end;

procedure SV_BroadcastCommand(const S: array of const);
begin
SV_BroadcastCommand(PLChar(StringFromVarRec(S)));
end;

procedure SV_BroadcastPrint(Msg: PLChar);
var
 I: Int;
 C: PClient;
 Buf: array[1..258] of LChar;
 S: PLChar;
begin
if StrLen(Msg) > 256 then
 Print('SV_BroadcastPrint: The message is too long, ignoring.')
else
 begin
  DPrint(Msg);

  if SV.Active then
   begin
    S := StrECopy(@Buf, Msg);
    StrCopy(S, #10);

    for I := 0 to SVS.MaxClients - 1 do
     begin
      C := @SVS.Clients[I];
      if (C.Active or C.Spawned or C.Connected) and not C.FakeClient then
       begin
        MSG_WriteByte(C.Netchan.NetMessage, SVC_PRINT);
        MSG_WriteString(C.Netchan.NetMessage, @Buf);
       end;
     end;
   end;
 end;
end;

procedure SV_BroadcastPrint(const Msg: array of const);
begin
SV_BroadcastPrint(PLChar(StringFromVarRec(Msg)));
end;

procedure SV_ClearPacketEntities(var Frame: TClientFrame);
begin
if @Frame <> nil then
 begin
  if Frame.Pack.Ents <> nil then
   Mem_FreeAndNil(Frame.Pack.Ents);
  Frame.Pack.NumEnts := 0;
 end;
end;

procedure SV_AllocPacketEntities(var Frame: TClientFrame; NumEnts: UInt);
var
 I: UInt;
begin
if @Frame <> nil then
 begin
  if Frame.Pack.Ents <> nil then
   Mem_Free(Frame.Pack.Ents);

  if NumEnts = 0 then
   I := 1
  else
   I := NumEnts;

  Frame.Pack.NumEnts := NumEnts;
  Frame.Pack.Ents := Mem_ZeroAlloc(SizeOf(TEntityState) * I);
 end;
end;

procedure SV_ClearFrames(var CF: TClientFrameArrayPtr);
var
 I: Int;
begin
if @CF <> nil then
 begin
  for I := 0 to SVUpdateBackup - 1 do
   SV_ClearPacketEntities(CF[I]);

  Mem_FreeAndNil(CF);
 end;
end;

procedure SV_SkipUpdates;
var
 C: PClient;
 I: Int;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Connected or C.Spawned) and not C.FakeClient then
   C.SkipThisUpdate := True;
 end;
end;

procedure SV_CheckUpdateRate(var P: Double);
var
 F: Double;
begin
if sv_maxupdaterate.Value <> 0 then
 begin
  if sv_maxupdaterate.Value < 1 then
   CVar_DirectSet(sv_maxupdaterate, '30');

  F := 1 / sv_maxupdaterate.Value;
  if P < F then
   P := F;
 end;

if sv_minupdaterate.Value <> 0 then
 begin
  if sv_minupdaterate.Value < 1 then
   CVar_DirectSet(sv_minupdaterate, '1');

  F := 1 / sv_minupdaterate.Value;
  if P > F then
   P := F;
 end;
end;

procedure SV_CheckRate(var P: Double);
begin
if (sv_maxrate.Value > 0) and (sv_maxrate.Value < P) then
 if sv_maxrate.Value > MAX_CLIENT_RATE then
  P := MAX_CLIENT_RATE
 else
  P := sv_maxrate.Value
else
 if P > MAX_CLIENT_RATE then
  P := MAX_CLIENT_RATE;

if (sv_minrate.Value > 0) and (sv_minrate.Value > P) then
 if sv_minrate.Value < MIN_CLIENT_RATE then
  P := MIN_CLIENT_RATE
 else
  P := sv_minrate.Value
else
 if P < MIN_CLIENT_RATE then
  P := MIN_CLIENT_RATE;
end;

function SV_FilterPlayerName(Name: PLChar; IgnoreClient: Int = -1): Boolean;
var
 Buf, OrigBuf: array[1..MAX_PLAYER_NAME] of LChar;
 S: PLChar;
 B: Boolean;
 C: PClient;
 I, J: Int;
begin
S := Name;
B := False;

while S^ > #0 do
 begin
  if (S^ = '#') and not B then
   S^ := ' '
  else
   begin
    if (S^ in [#1..#31, '~'..#$FF, '%', '&']) then
     S^ := ' ';

    B := True;
   end;

  Inc(UInt(S));
 end;

TrimSpace(Name, @Buf);

if (Buf[1] <= ' ') or (StrIComp(@Buf, 'console') = 0) or
   (StrIComp(@Buf, 'loopback') = 0) or (StrPos(@Buf, '..') <> nil) then
 if (sv_defaultplayername.Data <> nil) and (sv_defaultplayername.Data^ > #0) then
  StrCopy(@Buf, sv_defaultplayername.Data)
 else
  StrCopy(@Buf, 'unnamed');

StrCopy(@OrigBuf, @Buf);
I := 0;
Result := False;
if sv_use2asnameprefix.Value = 0 then
 J := 1
else
 J := 2;
while UInt(I) < SVS.MaxClients do
 begin
  C := @SVS.Clients[I];
  if C.Active and C.Spawned and (I <> IgnoreClient) and (StrIComp(@C.NetName, @Buf) = 0) then
   begin
    Buf[1] := '(';
    S := IntToStrE(J, Buf[2], SizeOf(Buf) - 2);
    S^ := ')';
    Inc(UInt(S));
    StrLCopy(S, @OrigBuf, SizeOf(Buf) - 1 - (UInt(S) - UInt(@Buf)));
    Inc(J);
    I := 0;
    Result := True;
   end
  else
   Inc(I);
 end;

StrCopy(Name, @Buf);
end;

procedure SV_ExtractFromUserInfo(var C: TClient);
var
 Val, S: PLChar;
 Name: array[1..MAX_PLAYER_NAME] of LChar;
 I: UInt;
begin
Val := Info_ValueForKey(@C.UserInfo, 'name');

StrLCopy(@Name, Val, SizeOf(Name) - 1);
SV_FilterPlayerName(@Name, (UInt(@C) - UInt(SVS.Clients)) div SizeOf(TClient));

Info_SetValueForKey(@C.UserInfo, 'name', @Name, MAX_USERINFO_STRING);
DLLFunctions.ClientUserInfoChanged(C.Entity^, @C.UserInfo);
StrLCopy(@C.NetName, Info_ValueForKey(@C.UserInfo, 'name'), SizeOf(C.NetName) - 1);

S := Info_ValueForKey(@C.UserInfo, 'rate');
if (S <> nil) and (S^ > #0) then
 begin
  I := StrToInt(S);
  if I = 0 then
   I := AVG_CLIENT_RATE
  else
   if I < MIN_CLIENT_RATE then
    I := MIN_CLIENT_RATE
   else
    if I > MAX_CLIENT_RATE then
     I := MAX_CLIENT_RATE;

  C.Netchan.Rate := I;
 end;

S := Info_ValueForKey(@C.UserInfo, 'topcolor');
if (S <> nil) and (S^ > #0) then
 C.TopColor := StrToInt(S);

S := Info_ValueForKey(@C.UserInfo, 'bottomcolor');
if (S <> nil) and (S^ > #0) then
 C.BottomColor := StrToInt(S);

S := Info_ValueForKey(@C.UserInfo, 'cl_updaterate');
if (S <> nil) and (S^ > #0) then
 begin
  I := StrToInt(S);
  if I < MIN_CLIENT_UPDATERATE then
   I := MIN_CLIENT_UPDATERATE;
  C.UpdateRate := 1 / I;
 end
else
 C.UpdateRate := 1 / sv_defaultupdaterate.Value;

S := Info_ValueForKey(@C.UserInfo, 'cl_lw');
if (S <> nil) and (S^ > #0) then
 C.LW := StrToInt(S) <> 0
else
 C.LW := False;

S := Info_ValueForKey(@C.UserInfo, 'cl_lc');
if (S <> nil) and (S^ > #0) then
 C.LC := StrToInt(S) <> 0
else
 C.LC := False;

S := Info_ValueForKey(@C.UserInfo, '*hltv');
if (S <> nil) and (S^ > #0) then
 C.HLTV := StrToInt(S) = 1
else
 C.HLTV := False;

SV_CheckUpdateRate(C.UpdateRate);
SV_CheckRate(C.Netchan.Rate);
end;

procedure SV_FullClientUpdate(const C: TClient; var SB: TSizeBuf);
var
 Buf: array[1..MAX_USERINFO_STRING] of LChar;
 MD5C: TMD5Context;
 Hash: TMD5Hash;
begin
StrLCopy(@Buf, @C.UserInfo, SizeOf(Buf) - 1);
Info_RemovePrefixedKeys(@Buf, '_');
MSG_WriteByte(SB, SVC_UPDATEUSERINFO);
MSG_WriteByte(SB, (UInt(@C) - UInt(SVS.Clients)) div SizeOf(TClient));
MSG_WriteLong(SB, C.UserID);
MSG_WriteString(SB, @Buf);

MD5Init(MD5C);
MD5Update(MD5C, @C.CDKey, SizeOf(C.CDKey));
MD5Final(Hash, MD5C);
MSG_WriteBuffer(SB, SizeOf(Hash), @Hash);
end;

procedure SV_ForceFullClientsUpdate;
var
 SB: TSizeBuf;
 SBData: array[1..32768] of Byte;
 I: Int;
 C: PClient;
begin
SB.Name := 'Force Update';
SB.AllowOverflow := [];
SB.Data := @SBData;
SB.CurrentSize := 0;
SB.MaxSize := SizeOf(SBData);

for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C = HostClient) or C.Active or C.Spawned or C.Connected then
   SV_FullClientUpdate(C^, SB);
 end;

DPrint(['Client "', PLChar(@HostClient.NetName), '" (index #', (UInt(HostClient) - UInt(SVS.Clients)) div SizeOf(TClient) + 1,
        ') requested fullupdate, sending.']);
Netchan_CreateFragments(HostClient.Netchan, SB);
Netchan_FragSend(HostClient.Netchan);
end;

var
 LF: array[0..MAX_PLAYERS - 1] of record
  Time: Double;
  LastBlock: Double;  
  NumCmds: Int;
 end;

function SV_FilterFullClientUpdate(const C: TClient): Boolean;
var
 I: UInt;
 F: Double;
begin
if sv_filterfullupdate.Value = 0 then
 begin
  Result := True;
  Exit;
 end;

I := (UInt(@C) - UInt(SVS.Clients)) div SizeOf(TClient);

F := SV.Time - LF[I].Time;
if F < 0 then
 if LF[I].NumCmds <= 1 then
  begin
   LF[I].Time := 0;
   F := SV.Time;
  end
 else
  F := 0;

if (F < sv_fullupdateinterval.Value) and (SV.Time >= sv_fullupdateinterval.Value) then
 begin
  if LF[I].NumCmds < sv_fullupdatemaxcmds.Value then
   Inc(LF[I].NumCmds);

  if LF[I].NumCmds > 1 then
   LF[I].Time := SV.Time + (LF[I].NumCmds - 1) * sv_fullupdatemaxcmds.Value
  else
   LF[I].Time := SV.Time;
  
  Result := False;
 end
else
 begin
  LF[I].NumCmds := 0;
  LF[I].Time := SV.Time;
  Result := sv_fullupdatemaxcmds.Value <> 0;
 end;
end;

procedure SV_ClearFullUpdateFilter;
begin
MemSet(LF, SizeOf(LF), 0);
end;

procedure SV_ClientPrint(Msg: PLChar);
begin
if not HostClient.FakeClient then
 begin
  MSG_WriteByte(HostClient.Netchan.NetMessage, SVC_PRINT);
  MSG_WriteBuffer(HostClient.Netchan.NetMessage, StrLen(Msg), Msg);
  MSG_WriteChar(HostClient.Netchan.NetMessage, #10);
  MSG_WriteChar(HostClient.Netchan.NetMessage, #0);
 end;
end;

procedure SV_ClientPrint(const Msg: array of const);
begin
SV_ClientPrint(PLChar(StringFromVarRec(Msg)));
end;

procedure SV_WriteClientDataToMessage(var C: TClient; var SB: TSizeBuf);
var
 CD: TClientData;
 WD: TWeaponData;
 Frame: PClientFrame;
 E: PEdict;
 I: UInt;
 OS: Pointer;
begin
MemSet(CD, SizeOf(CD), 0);
E := C.Entity;
Frame := @C.Frames[SVUpdateMask and C.Netchan.OutgoingSequence];

Frame.SentTime := RealTime;
Frame.PingTime := -1;

if C.ChokeCount > 0 then
 begin
  MSG_WriteByte(SB, SVC_CHOKE);
  C.ChokeCount := 0;
 end;

if E.V.FixAngle <> 0 then
 begin
  if E.V.FixAngle = 2 then
   begin
    MSG_WriteByte(SB, SVC_ADDANGLE);
    MSG_WriteHiResAngle(SB, E.V.AVelocity[1]);
    E.V.AVelocity[1] := 0;
   end
  else
   begin
    MSG_WriteByte(SB, SVC_SETANGLE);
    for I := 0 to 2 do
     MSG_WriteHiResAngle(SB, E.V.Angles[I]);
   end;

  E.V.FixAngle := 0;
 end;

MemSet(Frame.ClientData, SizeOf(Frame.ClientData), 0);
DLLFunctions.UpdateClientData(E^, Int32(HostClient.LW), Frame.ClientData);
MSG_WriteByte(SB, SVC_CLIENTDATA);
if not C.HLTV then
 begin
  MSG_StartBitWriting(SB);
  if HostClient.UpdateMask = -1 then
   begin
    OS := @CD;
    MSG_WriteBits(0, 1);
   end
  else
   begin
    OS := @HostClient.Frames[SVUpdateMask and C.UpdateMask].ClientData;
    MSG_WriteBits(1, 1);
    MSG_WriteBits(HostClient.UpdateMask, 8);
   end;

  Delta_WriteDelta(OS, @Frame.ClientData, True, ClientDelta^, nil);
  if HostClient.LW then
   begin
    MemSet(WD, SizeOf(WD), 0);
    if DLLFunctions.GetWeaponData(HostClient.Entity^, Frame.WeaponData[0]) <> 0 then
     for I := 0 to MAX_WEAPON_DATA - 1 do
      begin
       if HostClient.UpdateMask = -1 then
        OS := @WD
       else
        OS := @HostClient.Frames[SVUpdateMask and C.UpdateMask].WeaponData[I];

       if Delta_CheckDelta(OS, @Frame.WeaponData[I], WeaponDelta^) <> 0 then
        begin
         MSG_WriteBits(1, 1);
         MSG_WriteBits(I, 6); // <- ?   maybe 5?
         Delta_WriteDelta(OS, @Frame.WeaponData[I], True, WeaponDelta^, nil);
        end;
      end;
   end;

  MSG_WriteBits(0, 1);
  MSG_EndBitWriting;
 end;
end;

procedure SV_WriteSpawn(var SB: TSizeBuf);
var
 I: Int;
 C: PClient;
 SRD: TSaveRestoreData;
 Buf: array[1..MAX_PATH_A] of LChar;
begin
if SV.SavedGame then
 begin
  if HostClient.HLTV then
   begin
    Print('SV_WriteSpawn: HLTV proxies can''t work with a saved game.');
    Exit;
   end;

  SV.Paused := False;
 end
else
 begin
  SV.State := SS_LOADING;
  ReleaseEntityDLLFields(SVPlayer^);
  MemSet(SVPlayer.V, SizeOf(SVPlayer.V), 0);
  InitEntityDLLFields(SVPlayer^);
  SVPlayer.V.ColorMap := NUM_FOR_EDICT(SVPlayer^);
  SVPlayer.V.NetName := UInt(@HostClient.NetName) - PRStrings;
  if HostClient.HLTV then
   SVPlayer.V.Flags := SVPlayer.V.Flags or FL_PROXY;

  GlobalVars.Time := SV.Time;
  DLLFunctions.ClientPutInServer(SVPlayer^);
  SV.State := SS_ACTIVE;
 end;

SZ_Clear(HostClient.Netchan.NetMessage);
SZ_Clear(HostClient.UnreliableMessage);

MSG_WriteByte(SB, SVC_TIME);
MSG_WriteFloat(SB, SV.Time);

HostClient.UpdateInfo := True;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C = HostClient) or C.Active or C.Spawned or C.Connected then
   SV_FullClientUpdate(C^, SB);
 end;

for I := 0 to MAX_LIGHTSTYLES - 1 do
 begin
  MSG_WriteByte(SB, SVC_LIGHTSTYLE);
  MSG_WriteByte(SB, I);
  MSG_WriteString(SB, SV.LightStyles[I]);
 end;

if not HostClient.HLTV then
 begin
  MSG_WriteByte(SB, SVC_SETANGLE);
  MSG_WriteHiResAngle(SB, SVPlayer.V.VAngle[0]);
  MSG_WriteHiResAngle(SB, SVPlayer.V.VAngle[1]);
  MSG_WriteHiResAngle(SB, 0);
  SV_WriteClientDataToMessage(HostClient^, SB);
  if SV.SavedGame then
   begin
    MemSet(SRD, SizeOf(SRD), 0);
    GlobalVars.SaveData := @SRD;
    DLLFunctions.ParmsChangeLevel;
    MSG_WriteByte(SB, SVC_RESTORE);

    StrLECopy(@Buf, Host_SaveGameDirectory, SizeOf(Buf) - 1);
    StrLCat(@Buf, @SV.Map, SizeOf(Buf) - 1);
    StrLCat(@Buf, '.HL2', SizeOf(Buf) - 1);
    COM_FixSlashes(@Buf);
    MSG_WriteString(SB, @Buf);
    MSG_WriteByte(SB, SRD.ConnectionCount);
    for I := 0 to SRD.ConnectionCount - 1 do
     MSG_WriteString(SB, @SRD.LevelList[I].MapName);

    SV.SavedGame := False;
    GlobalVars.SaveData := nil;
   end;
 end;

MSG_WriteByte(SB, SVC_SIGNONNUM);
MSG_WriteByte(SB, 1);

HostClient.Active := True;
HostClient.Spawned := True;
HostClient.SendInfo := False;
HostClient.Connected := True;

HostClient.FirstCmd := 0;
HostClient.LastCmd := 0;
HostClient.NextCmd := 0;
end;

procedure SV_WriteVoiceCodec(var SB: TSizeBuf);
begin
MSG_WriteByte(SB, SVC_VOICEINIT);
if SVS.MaxClients > 1 then
 MSG_WriteString(SB, sv_voicecodec.Data)
else
 MSG_WriteString(SB, EmptyString);
MSG_WriteByte(SB, Trunc(sv_voicequality.Value));
end;

procedure SV_SendUserReg(var SB: TSizeBuf);
var
 P: PUserMsg;
begin
P := NewUserMsgs;
while P <> nil do
 begin
  MSG_WriteByte(SB, SVC_NEWUSERMSG);
  MSG_WriteByte(SB, P.Index);
  MSG_WriteByte(SB, P.Size);
  MSG_WriteBuffer(SB, SizeOf(P.Name), @P.Name);
  P := P.Prev;
 end;
end;

procedure SV_WriteMoveVarsToClient(var SB: TSizeBuf);
begin
MSG_WriteByte(SB, SVC_NEWMOVEVARS);
MSG_WriteFloat(SB, MoveVars.Gravity);
MSG_WriteFloat(SB, MoveVars.StopSpeed);
MSG_WriteFloat(SB, MoveVars.MaxSpeed);
MSG_WriteFloat(SB, MoveVars.SpectatorMaxSpeed);
MSG_WriteFloat(SB, MoveVars.Accelerate);
MSG_WriteFloat(SB, MoveVars.AirAccelerate);
MSG_WriteFloat(SB, MoveVars.WaterAccelerate);
MSG_WriteFloat(SB, MoveVars.Friction);
MSG_WriteFloat(SB, MoveVars.EdgeFriction);
MSG_WriteFloat(SB, MoveVars.WaterFriction);
MSG_WriteFloat(SB, MoveVars.EntGravity);
MSG_WriteFloat(SB, MoveVars.Bounce);
MSG_WriteFloat(SB, MoveVars.StepSize);
MSG_WriteFloat(SB, MoveVars.MaxVelocity);
MSG_WriteFloat(SB, MoveVars.ZMax);
MSG_WriteFloat(SB, MoveVars.WaveHeight);
MSG_WriteByte(SB, UInt(MoveVars.Footsteps <> 0));
MSG_WriteFloat(SB, MoveVars.RollAngle);
MSG_WriteFloat(SB, MoveVars.RollSpeed);
MSG_WriteFloat(SB, MoveVars.SkyColorR);
MSG_WriteFloat(SB, MoveVars.SkyColorG);
MSG_WriteFloat(SB, MoveVars.SkyColorB);
MSG_WriteFloat(SB, MoveVars.SkyVecX);
MSG_WriteFloat(SB, MoveVars.SkyVecY);
MSG_WriteFloat(SB, MoveVars.SkyVecZ);
MSG_WriteString(SB, @MoveVars.SkyName);
end;

procedure SV_SendServerInfo(var SB: TSizeBuf; var C: TClient);
var
 GD: array[1..MAX_PATH_A] of LChar;
 Buf: array[1..256] of LChar;
 HexBuf: array[1..16] of LChar;
 S: PLChar;
 CRC: TCRC;
 Index: UInt;
 P: Pointer;
 L: UInt32;
begin
if (developer.Value <> 0) or (SVS.MaxClients > 1) then
 begin
  MSG_WriteByte(SB, SVC_PRINT);
  S := StrECopy(@Buf, #2#10'BUILD ');
  S := IntToStrE(BuildNumber, S^, 32);
  if sv_sendmapcrc.Value = 0 then
   S := StrECopy(S, ' SERVER (0 CRC)'#10'Server # ')
  else
   begin
    S := StrECopy(S, ' SERVER (');
    S := StrECopy(S, COM_IntToHex(SV.WorldModelCRC, HexBuf));
    S := StrECopy(S, ' CRC)'#10'Server # ');
   end;
  S := IntToStrE(SVS.SpawnCount, S^, 32);
  StrCopy(S, #10);
  MSG_WriteString(SB, @Buf);
 end;

MSG_WriteByte(SB, SVC_SERVERINFO);
MSG_WriteLong(SB, C.Protocol);
MSG_WriteLong(SB, SVS.SpawnCount);

Index := NUM_FOR_EDICT(C.Entity^) - 1;
CRC := SV.WorldModelCRC;
COM_Munge3(@CRC, SizeOf(CRC), Byte(not Index));
MSG_WriteLong(SB, CRC);
MSG_WriteBuffer(SB, SizeOf(SV.ClientDLLHash), @SV.ClientDLLHash);

MSG_WriteByte(SB, SVS.MaxClients);
MSG_WriteByte(SB, Index);
MSG_WriteByte(SB, UInt((coop.Value = 0) and (deathmatch.Value <> 0)));
COM_FileBase(GameDir, @GD);
MSG_WriteString(SB, @GD);
MSG_WriteString(SB, hostname.Data);
MSG_WriteString(SB, @SV.MapFileName);

P := COM_LoadFile(mapcyclefile.Data, FILE_ALLOC_MEMORY, @L);
if (P <> nil) and (L > 0) then
 begin
  if L <= sv_mapcycle_length.Value then
   MSG_WriteString(SB, P)
  else
   MSG_WriteString(SB, 'mapcycle failure');

  COM_FreeFile(P);
 end
else
 MSG_WriteString(SB, 'mapcycle failure');

MSG_WriteByte(SB, 0);

MSG_WriteByte(SB, SVC_SENDEXTRAINFO);
MSG_WriteString(SB, FallbackDir);
MSG_WriteByte(SB, UInt(AllowCheats));

SV_WriteDeltaDescriptionsToClient(SB);
SV_SetMoveVars;
SV_WriteMoveVarsToClient(SB);

MSG_WriteByte(SB, SVC_CDTRACK);
MSG_WriteByte(SB, GlobalVars.CDAudioTrack);
MSG_WriteByte(SB, GlobalVars.CDAudioTrack);

MSG_WriteByte(SB, SVC_SETVIEW);
MSG_WriteShort(SB, Index + 1);

C.Spawned := False;
C.SendInfo := False;
C.Connected := True;
end;

function SV_IsPlayerIndex(I: UInt): Boolean;
begin
Result := (I >= 1) and (I <= SVS.MaxClients);
end;

procedure SV_SendConsistencyList;
var
 I, J: Int;
 P: PResource;
begin
if (SVS.MaxClients = 1) or (mp_consistency.Value = 0) or (SV.NumConsistency = 0) or HostClient.HLTV then
 begin
  MSG_WriteBits(0, 1);
  HostClient.SendConsistency := False;
 end
else
 begin
  J := 0;
  MSG_WriteBits(1, 1);
  HostClient.SendConsistency := True;
  for I := 0 to SV.NumResources - 1 do
   begin
    P := @SV.Resources[I];
    if RES_CHECKFILE in P.Flags then
     begin
      MSG_WriteBits(1, 1);
      if I - J >= 32 then
       begin
        MSG_WriteBits(0, 1);
        MSG_WriteBits(I, 10);
       end
      else
       begin
        MSG_WriteBits(1, 1);
        MSG_WriteBits(I - J, 5);
       end;
      J := I;
     end; 
   end;
  
  MSG_WriteBits(0, 1);
 end;
end;

procedure SV_SendResources(var SB: TSizeBuf);
var
 Buf: array[1..32] of LChar;
 P: PResource;
 I: Int;
begin
MemSet(Buf, SizeOf(Buf), 0);
MSG_WriteByte(SB, SVC_RESOURCEREQUEST);
MSG_WriteLong(SB, SVS.SpawnCount);
MSG_WriteLong(SB, 0);

if (sv_downloadurl.Data^ > #0) and (StrLen(sv_downloadurl.Data) < 128) then
 begin
  MSG_WriteByte(SB, SVC_RESOURCELOCATION);
  MSG_WriteString(SB, sv_downloadurl.Data);
 end;

MSG_WriteByte(SB, SVC_RESOURCELIST);
MSG_StartBitWriting(SB);
MSG_WriteBits(SV.NumResources, 12);
for I := 0 to SV.NumResources - 1 do
 begin
  P := @SV.Resources[I];
  MSG_WriteBits(P.ResourceType, 4);
  MSG_WriteBitString(@P.Name);
  MSG_WriteBits(P.Index, 12);
  MSG_WriteBits(P.DownloadSize, 24);
  MSG_WriteBits(PByte(@P.Flags)^ and 3, 3);
  if RES_CUSTOM in P.Flags then
   MSG_WriteBitData(@P.MD5Hash, SizeOf(P.MD5Hash));

  if CompareMem(@P.Reserved, @Buf, SizeOf(P.Reserved)) then
   MSG_WriteBits(0, 1)
  else
   begin
    MSG_WriteBits(1, 1);
    MSG_WriteBitData(@P.Reserved, SizeOf(P.Reserved));
   end;
 end;

SV_SendConsistencyList;
MSG_EndBitWriting;
end;

procedure SV_AllocClientFrames;
var
 I: Int;
begin
for I := 0 to SVS.MaxClientsLimit - 1 do
 begin
  if SVS.Clients[I].Frames <> nil then
   DPrint('SV_AllocClientFrames: Warning: Allocating over frame pointer.');

  SVS.Clients[I].Frames := Mem_ZeroAlloc(SizeOf(TClientFrame) * SVUpdateBackup);
 end;
end;

procedure SV_ClearClientStates;
var
 I: Int;
 C: PClient;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  COM_ClearCustomizationList(C.Customization);
  SV_ClearResourceLists(C^);
 end;
end;

procedure SV_BuildReconnect(var SB: TSizeBuf);
begin
MSG_WriteByte(SB, SVC_STUFFTEXT);
MSG_WriteString(SB, 'reconnect'#10);
end;

procedure SV_InactivateClients;
var
 I: Int;
 C: PClient;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Active or C.Spawned or C.Connected then
   if not C.FakeClient then
    begin
     C.Active := False;
     C.Spawned := False;
     C.SendInfo := False;
     C.Connected := True;
     SZ_Clear(C.Netchan.NetMessage);
     SZ_Clear(C.UnreliableMessage);
     COM_ClearCustomizationList(C.Customization);
     MemSet(C.PhysInfo, SizeOf(C.PhysInfo), 0);
    end
   else
    SV_DropClient(C^, False, 'Dropping fakeclient on level change');
 end;
end;

function SV_CalcPing(const C: TClient): UInt;
var
 I, Frames, TotalFrames: UInt;
 TotalPing: Single;
 Frame: PClientFrame;
begin
Result := 0;

if not C.FakeClient then
 begin
  Frames := SVUpdateBackup div 2;
  if Frames > 16 then
   Frames := 16
  else
   if Frames = 0 then
    Exit;

  TotalFrames := 0;
  TotalPing := 0;
  for I := 0 to Frames - 1 do
   begin
    Frame := @C.Frames[SVUpdateMask and (UInt(C.Netchan.IncomingAcknowledged) - I - 1)];
    if Frame.PingTime > 0 then
     begin
      Inc(TotalFrames);
      TotalPing := TotalPing + Frame.PingTime; 
     end;
   end;

  if TotalFrames > 0 then
   begin
    TotalPing := TotalPing / TotalFrames;
    if TotalPing > 0 then
     Result := Trunc(TotalPing * 1000);
   end;
 end;
end;

procedure SV_ClearClientFrames;
var
 I: Int;
begin
if SVS.Clients <> nil then
 for I := 0 to SVS.MaxClientsLimit - 1 do
  if SVS.Clients[I].Frames <> nil then
   SV_ClearFrames(SVS.Clients[I].Frames);
end;

procedure SV_SetMaxClients;
var
 I: Int;
 S: PLChar;
 C: PClient;
begin
SV_ClearClientFrames;
SVS.MaxClients := 1;

S := COM_ParmValueByName('-maxplayers');
if (S <> nil) and (S^ > #0) then
 begin
  SVS.MaxClients := StrToIntDef(S, 6);
  if SVS.MaxClients < 1 then
   SVS.MaxClients := 6;
 end
else
 SVS.MaxClients := 6;

if SVS.MaxClients > MAX_PLAYERS then
 SVS.MaxClients := MAX_PLAYERS;

SVS.MaxClientsLimit := MAX_PLAYERS;

if SVS.MaxClients <> 1 then
 SVUpdateBackup := 64
else
 SVUpdateBackup := 8;
SVUpdateMask := SVUpdateBackup - 1;

SVS.Clients := Hunk_AllocName(SizeOf(TClient) * SVS.MaxClientsLimit, 'clients');
for I := 0 to SVS.MaxClientsLimit - 1 do
 begin
  C := @SVS.Clients[I];
  C.DownloadList.Next := @C.DownloadList;
  C.DownloadList.Prev := @C.DownloadList;
  C.UploadList.Next := @C.UploadList;
  C.UploadList.Prev := @C.UploadList;
 end;

if SVS.MaxClients <= 1 then
 CVar_DirectSet(deathmatch, '0')
else
 CVar_DirectSet(deathmatch, '1');

SV_AllocClientFrames;
if SVS.MaxClientsLimit < SVS.MaxClients then
 SVS.MaxClients := SVS.MaxClientsLimit;
end;

function SV_ValidateClientCommand(P: Pointer): Boolean;
var
 I: Int;
begin
COM_Parse(P);
for I := Low(CLCommands) to High(CLCommands) do
 if StrIComp(CLCommands[I], @COM_Token) = 0 then
  begin
   Result := True;
   Exit;
  end;

Result := False;
end;

procedure SV_ParseStringCommand(var C: TClient);
var
 S: PLChar;
 Buf: array[1..128] of LChar;
begin
S := MSG_ReadString;
if S^ > #0 then
 if SV_ValidateClientCommand(S) then
  Cmd_ExecuteString(S, csClient)
 else
  begin
   StrLCopy(@Buf, S, SizeOf(Buf) - 1);
   Cmd_TokenizeString(@Buf);
   DLLFunctions.ClientCommand(SVPlayer^);
  end;
end;

procedure SV_ParseVoiceData(var C: TClient);
var
 I, Index: Int;
 J, Size: UInt;
 Buf: array[1..4096] of Byte;
 P: PClient;
begin
Index := (UInt(@C) - UInt(SVS.Clients)) div SizeOf(TClient);
Size := MSG_ReadShort;
if Size > SizeOf(Buf) then
 begin
  DPrint(['SV_ParseVoiceData: Invalid incoming packet from "', PLChar(@C.NetName), '".']);
  SV_DropClient(C, False, 'Invalid voice data.');
 end
else
 begin
  MSG_ReadBuffer(Size, @Buf);
  if sv_voiceenable.Value <> 0 then
   for I := 0 to SVS.MaxClients - 1 do
    begin
     P := @SVS.Clients[I];
     if (P.Active and P.Connected and not (I in C.BlockedVoice)) or (I = Index) then
      begin
       if (I = Index) and not P.VoiceLoopback then
        J := 0
       else
        J := Size;

       if P.UnreliableMessage.CurrentSize + Size + 6 < P.UnreliableMessage.MaxSize then
        begin
         MSG_WriteByte(P.UnreliableMessage, SVC_VOICEDATA);
         MSG_WriteByte(P.UnreliableMessage, Index);
         MSG_WriteShort(P.UnreliableMessage, J);
         MSG_WriteBuffer(P.UnreliableMessage, J, @Buf);
        end;
      end;
    end;    
 end;
end;

procedure SV_IgnoreHLTV(var C: TClient);
begin

end;

procedure SV_ParseCVarValue(var C: TClient);
var
 S: PLChar;
begin
S := MSG_ReadString;
if not MSG_BadRead then
 begin
  if (@NewDLLFunctions.CVarValue <> nil) and (C.Entity <> nil) then
   NewDLLFunctions.CVarValue(C.Entity^, S);

  DPrint(['Client cvar query response from "', PLChar(@C.NetName), '": ', S]);
 end;
end;

procedure SV_ParseCVarValue2(var C: TClient);
var
 ID: UInt;
 Buf: array[1..256] of LChar;
 S: PLChar;
begin
ID := MSG_ReadLong;
StrLCopy(@Buf, MSG_ReadString, SizeOf(Buf) - 1);
S := MSG_ReadString;

if not MSG_BadRead then
 begin
  if (@NewDLLFunctions.CVarValue2 <> nil) and (C.Entity <> nil) then
   NewDLLFunctions.CVarValue2(C.Entity^, ID, @Buf, S);

  DPrint(['Client cvar query response from "', PLChar(@C.NetName), '": request ID = ', ID, '; name = ', PLChar(@Buf), '; value = ', S]);
 end;
end;

procedure SV_ExecuteClientMessage(var C: TClient);
var
 Frame: PClientFrame;
 B: Byte;
begin
AlreadyMoved := False;
Frame := @C.Frames[SVUpdateMask and C.Netchan.IncomingAcknowledged];
Frame.PingTime := RealTime - Frame.SentTime - C.UpdateRate;
if (Frame.SentTime = 0) or ((RealTime - C.ConnectTime < 2) and (Frame.PingTime > 0)) then
 Frame.PingTime := 0;

SV_ComputeLatency(C);

HostClient := @C;
SVPlayer := C.Entity;
C.UpdateMask := -1;
PM := @ServerMove;

while True do
 if MSG_BadRead then
  begin
   Print(['SV_ExecuteClientMessage: badread on "', PLChar(@C.NetName), '".']);
   Break;
  end
 else
  begin
   B := MSG_ReadByte;
   if B = $FF then
    Break
   else
    if B > CLC_MESSAGE_END then
     begin
      Print(['SV_ExecuteClientMessage: Unknown command character "', B, '" on "', PLChar(@C.NetName), '".']);
      SV_DropClient(C, False, 'Bad command character in client command.');
      Break;
     end
    else
     if @CLCFuncs[B].Func <> nil then
      CLCFuncs[B].Func(C);
   end;
end;

procedure SV_CheckTimeouts;
var
 I: Int;
 C: PClient;
 Time: Double;
begin
if sv_timeout.Value < 1.5 then
 CVar_DirectSet(sv_timeout, '60');

Time := RealTime - sv_timeout.Value;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Spawned or C.Connected) and not C.FakeClient and (C.Netchan.LastReceived < Time) then
   begin
    SV_BroadcastPrint(['"', PLChar(@C.NetName), '" timed out.']);
    SV_DropClient(C^, False, 'Timed out.');
   end;
 end;
end;

function SV_ShouldUpdatePing(var C: TClient): Boolean;
begin
Result := (((C.UserCmd.Buttons and IN_SCORE) > 0) or C.HLTV) and (RealTime >= C.NextPingTime);
end;

procedure SV_UpdateToReliableMessages;
var
 I: Int;
 C: PClient;
 P: ^PUserMsg;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  HostClient := @SVS.Clients[I];
  C := HostClient;
  if C.Entity <> nil then
   begin
    if C.UpdateInfo and (C.UpdateInfoTime <= RealTime) then
     begin
      C.UpdateInfo := False;
      C.UpdateInfoTime := RealTime + 1;
      SV_ExtractFromUserInfo(C^);
      SV_FullClientUpdate(C^, SV.ReliableDatagram);
     end;

    if (NewUserMsgs <> nil) and (C.Active or C.Connected) and not C.FakeClient then
     SV_SendUserReg(C.Netchan.NetMessage);
   end;
 end;

if NewUserMsgs <> nil then
 begin
  P := @UserMsgs;
  while P^ <> nil do
   P := @(P^).Prev;

  P^ := NewUserMsgs;
  NewUserMsgs := nil;
 end;

if FSB_OVERFLOWED in SV.Datagram.AllowOverflow then
 begin
  Print('SV_UpdateToReliableMessages: Server datagram buffer overflowed.');
  SZ_Clear(SV.Datagram);
 end;

if FSB_OVERFLOWED in SV.Spectator.AllowOverflow then
 begin
  Print('SV_UpdateToReliableMessages: Server spectator buffer overflowed.');
  SZ_Clear(SV.Spectator);
 end; 

for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Active and not C.FakeClient then
   begin
    if SV.ReliableDatagram.CurrentSize + C.Netchan.NetMessage.CurrentSize < C.Netchan.NetMessage.MaxSize then
     SZ_Write(C.Netchan.NetMessage, SV.ReliableDatagram.Data, SV.ReliableDatagram.CurrentSize)
    else
     Netchan_CreateFragments(C.Netchan, SV.ReliableDatagram);

    if SV.Datagram.CurrentSize + C.UnreliableMessage.CurrentSize < C.UnreliableMessage.MaxSize then
     SZ_Write(C.UnreliableMessage, SV.Datagram.Data, SV.Datagram.CurrentSize)
    else
     DPrint(['Ignoring unreliable datagram for "', PLChar(@C.NetName), '", would overflow.']);

    if C.HLTV and (SV.Spectator.CurrentSize + C.UnreliableMessage.CurrentSize < C.UnreliableMessage.MaxSize) then
     SZ_Write(C.UnreliableMessage, SV.Spectator.Data, SV.Spectator.CurrentSize);
   end;
 end;

SZ_Clear(SV.ReliableDatagram);
SZ_Clear(SV.Datagram);
SZ_Clear(SV.Spectator);
end;

procedure SV_EmitPings(var SB: TSizeBuf);
var
 I: Int;
 C: PClient;
begin
MSG_WriteByte(SB, SVC_PINGS);
MSG_StartBitWriting(SB);
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Active then
   begin
    MSG_WriteBits(1, 1);
    MSG_WriteBits(I, 5); // 64?
    MSG_WriteBits(SV_CalcPing(C^), 12);
    MSG_WriteBits(Trunc(C.PacketLoss), 7);
   end;
 end;

MSG_WriteBits(0, 1);
MSG_EndBitWriting;
end;

function SV_SendClientDatagram(var C: TClient): Boolean;
var
 SB: TSizeBuf;
 SBData: array[1..4000] of Byte;
begin
SB.Name := 'Client Datagram';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

MSG_WriteByte(SB, SVC_TIME);
MSG_WriteFloat(SB, SV.Time);
SV_WriteClientDataToMessage(C, SB);
SV_WriteEntitiesToClient(C, SB);
if FSB_OVERFLOWED in C.UnreliableMessage.AllowOverflow then
 Print(['Warning: Unreliable datagram overflowed for "', PLChar(@C.NetName), '".'])
else
 SZ_Write(SB, C.UnreliableMessage.Data, C.UnreliableMessage.CurrentSize);
SZ_Clear(C.UnreliableMessage);

if FSB_OVERFLOWED in SB.AllowOverflow then
 begin
  Print(['Warning: Message overflowed for "', PLChar(@C.NetName), '".']);
  SZ_Clear(SB);
 end;

Netchan_Transmit(C.Netchan, SB.CurrentSize, SB.Data);
Result := True;
end;

procedure SV_SendClientMessages;
var
 I: Int;
 C: PClient;
begin
SV_UpdateToReliableMessages;
HostClient := @SVS.Clients[0];

for I := 0 to SVS.MaxClients - 1 do
 begin
  HostClient := @SVS.Clients[I];
  C := HostClient;
  if (C.Active or C.Spawned or C.Connected) and not C.FakeClient then
   if C.SkipThisUpdate then
    C.SkipThisUpdate := False
   else
    begin
     if ((host_limitlocal.Value = 0) and (C.Netchan.Addr.AddrType = NA_LOOPBACK)) or
        (C.Active and C.Spawned and C.SendInfo and (HostFrameTime + RealTime >= C.NextUpdateTime)) then
      C.NeedUpdate := True;

     if FSB_OVERFLOWED in C.Netchan.NetMessage.AllowOverflow then
      begin
       SZ_Clear(C.Netchan.NetMessage);
       SZ_Clear(C.UnreliableMessage);
       SV_BroadcastPrint(['"', PLChar(@C.NetName), '" overflowed.']);
       Print(['Warning: Reliable channel overflowed for "', PLChar(@C.NetName), '".']);
       SV_DropClient(C^, False, 'Reliable channel overflowed.');
       C.NeedUpdate := True;
       C.Netchan.ClearTime := 0;
      end
     else
      if C.NeedUpdate and (sv_failuretime.Value < RealTime - C.Netchan.LastReceived) then
       C.NeedUpdate := False;

     if C.NeedUpdate then
      if Netchan_CanPacket(C.Netchan) then
       begin
        C.NeedUpdate := False;
        C.NextUpdateTime := HostFrameTime + RealTime + C.UpdateRate;
        if C.Active and C.Spawned and C.SendInfo then
         SV_SendClientDatagram(C^)
        else
         Netchan_Transmit(C.Netchan, 0, nil);
       end
      else
       Inc(C.ChokeCount);
    end;
 end;

SV_CleanupEnts;
end;

end.
