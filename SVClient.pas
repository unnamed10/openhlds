unit SVClient;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

function SV_CountPlayers: UInt;
function SV_CountProxies: UInt;
function SV_CountFakeClients: UInt;
function SV_CalcPing(const C: TClient): UInt;

procedure SV_InitClient(var C: TClient);
procedure SV_ClearClient(var C: TClient);
procedure SV_ClearClients;

procedure SV_DropClient(var C: TClient; SkipNotify: Boolean; Msg: PLChar); overload;
procedure SV_DropClient(var C: TClient; SkipNotify: Boolean; const Msg: array of const); overload;

procedure SV_BroadcastCommand(S: PLChar); overload;
procedure SV_BroadcastCommand(const S: array of const); overload;
procedure SV_BroadcastPrint(Msg: PLChar); overload;
procedure SV_BroadcastPrint(const Msg: array of const); overload;

procedure SV_SkipUpdates;

procedure SV_SendBan;

function SV_FilterPlayerName(Name: PLChar; IgnoreClient: Int = -1): Boolean;

procedure SV_ExtractFromUserInfo(var C: TClient);

procedure SV_FullClientUpdate(const C: TClient; var SB: TSizeBuf);
procedure SV_ForceFullClientsUpdate;

procedure SV_ClientPrint(var C: TClient; Msg: PLChar; LineBreak: Boolean = True); overload;
procedure SV_ClientPrint(var C: TClient; const Msg: array of const; LineBreak: Boolean = True); overload;
procedure SV_ClientPrint(Msg: PLChar; LineBreak: Boolean = True); overload;
procedure SV_ClientPrint(const Msg: array of const; LineBreak: Boolean = True); overload;

procedure SV_CmdPrint(Msg: PLChar); overload;
procedure SV_CmdPrint(const Msg: array of const); overload;

procedure SV_WriteSpawn(var C: TClient; var SB: TSizeBuf);
procedure SV_WriteVoiceCodec(var SB: TSizeBuf);

procedure SV_SendServerInfo(var SB: TSizeBuf; var C: TClient);
procedure SV_SendResources(var SB: TSizeBuf);
procedure SV_BuildReconnect(var SB: TSizeBuf);

function SV_IsPlayerIndex(I: UInt): Boolean;

procedure SV_ClearClientStates;
procedure SV_InactivateClients;

procedure SV_ClearPacketEntities(var Frame: TClientFrame; ForceFree: Boolean);
procedure SV_AllocPacketEntities(var Frame: TClientFrame; NumEnts: UInt);
procedure SV_ClearFrames(var C: TClient);
procedure SV_AllocFrames(var C: TClient);
procedure SV_ClearClientFrames;

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

 sv_defaultupdaterate: TCVar = (Name: 'sv_defaultupdaterate'; Data: '45');
 sv_maxupdaterate: TCVar = (Name: 'sv_maxupdaterate'; Data: '90'; Flags: [FCVAR_SERVER]);
 sv_minupdaterate: TCVar = (Name: 'sv_minupdaterate'; Data: '10'; Flags: [FCVAR_SERVER]);

 sv_defaultrate: TCVar = (Name: 'sv_defaultrate'; Data: '10000');
 sv_maxrate: TCVar = (Name: 'sv_maxrate'; Data: '25000'; Flags: [FCVAR_SERVER]);
 sv_minrate: TCVar = (Name: 'sv_minrate'; Data: '3500'; Flags: [FCVAR_SERVER]);

 sv_failuretime: TCVar = (Name: 'sv_failuretime'; Data: '0.5');

 // how often to send ping reports to the clients
 sv_pinginterval: TCVar = (Name: 'sv_pinginterval'; Data: '1.0');

 // min interval between sending userinfo broadcast updates
 sv_updatetime: TCVar = (Name: 'sv_updatetime'; Data: '1.0');

 // allocate client frames only once, thereby increasing memory consumption,
 // but reducing overhead
 sv_keepframes: TCVar = (Name: 'sv_keepframes'; Data: '1');

var
 CurrentUserID: UInt = 1;

implementation

uses Common, Console, Delta, Edict, Encode, GameLib, Info, Host, Memory, MsgBuf, Network, PMove, Resource, SVMain, SVAuth, SVDelta, SVEdict, SVEvent, SVMove, SVPacket, SVSend, SysArgs, SysMain;

const
 CLCommands: array[1..19] of PLChar =
  ('god', 'notarget', 'noclip', 'new', 'spawn', 'sendents', 'sendres', 'pause', 'setpause', 'unpause',
   'status', 'ping', 'kill', 'name', 'dropclient', 'kick', 'dlfile', 'setinfo', 'fullupdate');

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
   (Index: 9; Name: 'clc_hltv'; Func: nil),
   (Index: 10; Name: 'clc_cvarvalue'; Func: SV_ParseCVarValue),
   (Index: 11; Name: 'clc_cvarvalue2'; Func: SV_ParseCVarValue2));
 
function SV_CountPlayers: UInt;
var
 I: Int;
 C: PClient;
begin
Result := 0;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Active or C.Spawned or C.Connected then
   Inc(Result);
 end;
end;

function SV_CountProxies: UInt;
var
 I: Int;
 C: PClient;
begin
Result := 0;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Spawned or C.Connected) and C.HLTV then
   Inc(Result);
 end;
end;

function SV_CountFakeClients: UInt;
var
 I: Int;
 C: PClient; 
begin
Result := 0;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Spawned or C.Connected) and C.FakeClient then
   Inc(Result);
 end;
end;

procedure SV_InitClient(var C: TClient);
begin
SV_SetResourceLists(C);
end;

procedure SV_ClearClient(var C: TClient);
begin
SV_ClearCustomizationList(C.Customization);
SV_ClearResourceLists(C);
SZ_Clear(C.UnreliableMessage);
SV_ClearClientEvents(C);
Netchan_Clear(C.Netchan);

C.Active := False;
C.Spawned := False;
C.SendInfo := False;
C.Connected := False;
C.HasMissingResources := False;
C.UserMsgReady := False;
C.NeedConsistency := False;
C.ChokeCount := 0;
C.UpdateMask := 0;
C.FakeClient := False;
C.HLTV := False;
MemSet(C.UserCmd, SizeOf(C.UserCmd), 0);
C.FirstCmd := 0;
C.LastCmd := 0;
C.NextCmd := 0;
C.Latency := 0;
C.PacketLoss := 0;
C.NextPingTime := 0;
C.ClientTime := 0;
MemSet(C.UnreliableMessage, SizeOf(C.UnreliableMessage), 0);
C.NextUpdateTime := 0;
C.UpdateRate := 0;
C.NeedUpdate := False;
C.SkipThisUpdate := False;
C.Target := nil;
C.UserID := 0;
MemSet(C.Auth, SizeOf(C.Auth), 0);
MemSet(C.UserInfo, SizeOf(C.UserInfo), 0);
C.UpdateInfo := False;
C.UpdateInfoTime := 0;
MemSet(C.CDKey, SizeOf(C.CDKey), 0);
MemSet(C.NetName, SizeOf(C.NetName), 0);
C.TopColor := 0;
C.BottomColor := 0;
C.UploadComplete := False;
C.MapCRC := 0;
C.LW := False;
C.LC := False;
MemSet(C.PhysInfo, SizeOf(C.PhysInfo), 0);
C.VoiceLoopback := False;
C.BlockedVoice := [];

C.SendResTime := 0;
C.SendEntsTime := 0;
C.FullUpdateTime := 0;
C.ConnectSeq := 0;
C.SpawnSeq := 0;
C.NewCmdTime := 0;
C.SpawnCmdTime := 0;
C.FragSizeUpdated := False;

SV_InitClient(C);
end;

procedure SV_ClearClients;
var
 I: Int;
begin
for I := 0 to SVS.MaxClients - 1 do
 SV_ClearClient(SVS.Clients[I]);
end;

procedure SV_ClearPacketEntities(var Frame: TClientFrame; ForceFree: Boolean);
begin
if (Frame.Pack.Ents <> nil) and
   ((sv_keepframes.Value = 0) or ForceFree or (Frame.Pack.EntLimit < MAX_PACKET_ENTITIES)) then
 Mem_FreeAndNil(Frame.Pack.Ents);

Frame.Pack.NumEnts := 0;
end;

procedure SV_AllocPacketEntities(var Frame: TClientFrame; NumEnts: UInt);
begin
if sv_keepframes.Value <> 0 then
 begin
  if (Frame.Pack.Ents <> nil) and (Frame.Pack.EntLimit < MAX_PACKET_ENTITIES) then
   Frame.Pack.Ents := Mem_ReAlloc(Frame.Pack.Ents, SizeOf(TEntityState) * MAX_PACKET_ENTITIES)
  else
   if Frame.Pack.Ents = nil then
    Frame.Pack.Ents := Mem_Alloc(SizeOf(TEntityState) * MAX_PACKET_ENTITIES);

  Frame.Pack.EntLimit := MAX_PACKET_ENTITIES;
 end
else
 begin
  if Frame.Pack.Ents <> nil then
   Mem_Free(Frame.Pack.Ents);

  Frame.Pack.Ents := Mem_Alloc(SizeOf(TEntityState) * Max(NumEnts, 1));
  Frame.Pack.EntLimit := NumEnts;
 end;

if Frame.Pack.Ents = nil then
 Sys_Error(['SV_AllocPacketEntities: Failed to allocate entity states.'])
else
 Frame.Pack.NumEnts := NumEnts;
end;

procedure SV_ClearFrames(var C: TClient);
var
 I: Int;
begin
if C.Frames <> nil then
 begin
  for I := 0 to SVUpdateBackup - 1 do
   SV_ClearPacketEntities(C.Frames[I], True);

  Mem_FreeAndNil(C.Frames);
 end;
end;

procedure SV_AllocFrames(var C: TClient);
begin
C.Frames := Mem_ZeroAlloc(SizeOf(TClientFrame) * SVUpdateBackup);
end;

procedure SV_ClearClientFrames;
var
 I: Int;
begin
if SVS.Clients <> nil then
 for I := 0 to SVS.MaxClientsLimit - 1 do
  SV_ClearFrames(SVS.Clients[I]);
end;

procedure SV_DropClient(var C: TClient; SkipNotify: Boolean; Msg: PLChar);
var
 S: PLChar;
 B: Boolean;
 Buf: array[1..512] of LChar;
 SB: TSizeBuf;
 L: UInt;
 TimePlaying: Single;
begin
if not SkipNotify then
 begin
  L := StrLen(Msg);
  if L > SizeOf(Buf) - 2 then
   L := SizeOf(Buf) - 2;
  S := StrLECopy(PLChar(UInt(@Buf) + 1), Msg, L);

  B := (L > 0) and (PLChar(UInt(S) - 1)^ = #10);
  if B then
   PLChar(UInt(S) - 1)^ := #0;

  if (C.Entity <> nil) and C.Spawned then
   DLLFunctions.ClientDisconnect(C.Entity^);

  if Msg^ > #0 then
   Print(['Dropped "', PLChar(@C.NetName), '" from server.' + LineBreak + 'Reason: ', Msg])
  else
   Print(['Dropped "', PLChar(@C.NetName), '" from server.']);
  
  if B then
   PLChar(UInt(S) - 1)^ := #10;

  if not C.FakeClient then
   begin
    MSG_WriteByte(C.Netchan.NetMessage, SVC_DISCONNECT);
    MSG_WriteString(C.Netchan.NetMessage, Msg);
    
    PByte(@Buf)^ := SVC_DISCONNECT;
    Netchan_Transmit(C.Netchan, L + 2, @Buf);
   end;
 end;

TimePlaying := RealTime - C.ConnectTime;
if TimePlaying > 0 then
 SV_RecordPlayingTime(TimePlaying);

if @C = HostClient then
 MSG_ReadCount := NetMessage.CurrentSize;

MemSet(C.UserInfo, SizeOf(C.UserInfo), 0);

SB.Name := 'dropclient tempbuf';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @Buf;
SB.MaxSize := SizeOf(Buf);
SB.CurrentSize := 0;

SV_FullClientUpdate(C, SB);
if SV.ReliableDatagram.CurrentSize + SB.CurrentSize < SV.ReliableDatagram.MaxSize then
 SZ_Write(SV.ReliableDatagram, SB.Data, SB.CurrentSize);
SV_ClearClient(C);
SV_ClearFrames(C);
C.ConnectTime := RealTime;
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
 if StrLen(S) > 256+32 then // serverinfo size and some extra space
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
begin
if StrLen(Msg) > 512 then
 Print('SV_BroadcastPrint: The message is too long, ignoring.')
else
 begin
  DPrint(Msg, False);
  
  if SV.Active then
   for I := 0 to SVS.MaxClients - 1 do
    begin
     C := @SVS.Clients[I];
     if (C.Active or C.Spawned or C.Connected) and not C.FakeClient then
      begin
       MSG_WriteByte(C.Netchan.NetMessage, SVC_PRINT);
       MSG_WriteString(C.Netchan.NetMessage, Msg);
      end;
    end;
 end;
end;

procedure SV_BroadcastPrint(const Msg: array of const);
begin
SV_BroadcastPrint(PLChar(StringFromVarRec(Msg)));
end;

procedure SV_CmdPrint(Msg: PLChar);
begin
if CmdSource = csClient then
 SV_ClientPrint(Msg)
else
 Print(Msg);
end;

procedure SV_CmdPrint(const Msg: array of const);
begin
SV_CmdPrint(PLChar(StringFromVarRec(Msg)));
end;

procedure SV_SkipUpdates;
var
 I: Int;
 C: PClient;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Spawned or C.Connected) and not C.FakeClient then
   C.SkipThisUpdate := True;
 end;
end;

procedure SV_CheckUpdateRate(var P: Double);
var
 F: Double;
begin
// Keep the server cvars in hard-coded limits.
if sv_defaultupdaterate.Value < MIN_CLIENT_UPDATERATE then
 CVar_SetValue('sv_defaultupdaterate', MIN_CLIENT_UPDATERATE)
else
 if sv_defaultupdaterate.Value > MAX_CLIENT_UPDATERATE then
  CVar_SetValue('sv_defaultupdaterate', MAX_CLIENT_UPDATERATE);

if sv_maxupdaterate.Value < MIN_CLIENT_UPDATERATE then
 CVar_SetValue('sv_maxupdaterate', MIN_CLIENT_UPDATERATE)
else
 if sv_maxupdaterate.Value > MAX_CLIENT_UPDATERATE then
  CVar_SetValue('sv_maxupdaterate', MAX_CLIENT_UPDATERATE);

if sv_minupdaterate.Value < MIN_CLIENT_UPDATERATE then
 CVar_SetValue('sv_minupdaterate', MIN_CLIENT_UPDATERATE)
else
 if sv_minupdaterate.Value > MAX_CLIENT_UPDATERATE then
  CVar_SetValue('sv_minupdaterate', MAX_CLIENT_UPDATERATE);

if sv_minupdaterate.Value > sv_maxupdaterate.Value then
 begin
  Print('Warning: sv_minupdaterate is greater than sv_maxupdaterate. Swapping the values.');
  F := sv_minupdaterate.Value;
  CVar_SetValue('sv_minupdaterate', sv_maxupdaterate.Value);
  CVar_SetValue('sv_maxupdaterate', F);
 end;

F := 1 / sv_maxupdaterate.Value;
if P < F then
 P := F
else
 begin
  F := 1 / sv_minupdaterate.Value;
  if P > F then
   P := F;
 end;
end;

procedure SV_CheckRate(var P: Double);
var
 F: Single;
begin
if sv_defaultrate.Value < MIN_CLIENT_RATE then
 CVar_SetValue('sv_defaultrate', MIN_CLIENT_RATE)
else
 if sv_defaultrate.Value > MAX_CLIENT_RATE then
  CVar_SetValue('sv_defaultrate', MAX_CLIENT_RATE);

if sv_maxrate.Value < MIN_CLIENT_RATE then
 CVar_SetValue('sv_maxrate', MIN_CLIENT_RATE)
else
 if sv_maxrate.Value > MAX_CLIENT_RATE then
  CVar_SetValue('sv_maxrate', MAX_CLIENT_RATE);

if sv_minrate.Value < MIN_CLIENT_RATE then
 CVar_SetValue('sv_minrate', MIN_CLIENT_RATE)
else
 if sv_minrate.Value > MAX_CLIENT_RATE then
  CVar_SetValue('sv_minrate', MAX_CLIENT_RATE);

if sv_minrate.Value > sv_maxrate.Value then
 begin
  Print('Warning: sv_minrate is greater than sv_maxrate. Swapping the values.');
  F := sv_minrate.Value;
  CVar_SetValue('sv_minrate', sv_maxrate.Value);
  CVar_SetValue('sv_maxrate', F);
 end;

if P > sv_maxrate.Value then
 P := sv_maxrate.Value
else
 if P < sv_minrate.Value then
  P := sv_minrate.Value;
end;

function SV_FilterPlayerName(Name: PLChar; IgnoreClient: Int = -1): Boolean;
var
 Buf, OrigBuf: array[1..MAX_PLAYER_NAME] of LChar;
 S: PLChar;
 C: PClient;
 I, J: Int;
begin
S := Name;

while S^ > #0 do
 begin
  if (S^ in [#1..#31, '#', '~'..#$FF, '%', '&']) then
   S^ := ' ';

  Inc(UInt(S));
 end;

TrimSpace(Name, @Buf);

if (Buf[1] <= ' ') or (StrIComp(@Buf, 'console') = 0) or (StrIComp(@Buf, 'server') = 0) or
   (StrIComp(@Buf, 'loopback') = 0) or (StrPos(@Buf, '..') <> nil) then
 if (sv_defaultplayername.Data^ > #0) and (Length(sv_defaultplayername.Data) < MAX_PLAYER_NAME) then
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
  if C.Connected and (I <> IgnoreClient) and (StrIComp(@C.NetName, @Buf) = 0) then
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
 C.Netchan.Rate := StrToInt(S)
else
 C.Netchan.Rate := sv_defaultrate.Value;
SV_CheckRate(C.Netchan.Rate);

S := Info_ValueForKey(@C.UserInfo, 'topcolor');
if (S <> nil) and (S^ > #0) then
 C.TopColor := StrToInt(S)
else
 C.TopColor := 0;

S := Info_ValueForKey(@C.UserInfo, 'bottomcolor');
if (S <> nil) and (S^ > #0) then
 C.BottomColor := StrToInt(S)
else
 C.BottomColor := 0;

if sv_defaultupdaterate.Value = 0 then
 CVar_SetValue('sv_defaultupdaterate', 30);

S := Info_ValueForKey(@C.UserInfo, 'cl_updaterate');
if (S <> nil) and (S^ > #0) then
 begin
  I := StrToInt(S);
  if I > 0 then
   C.UpdateRate := 1 / I
  else
   C.UpdateRate := 1 / sv_defaultupdaterate.Value;
 end
else
 C.UpdateRate := 1 / sv_defaultupdaterate.Value;
SV_CheckUpdateRate(C.UpdateRate);

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
 SBData: array[1..(256+1+1+4+16) * MAX_PLAYERS + 32] of Byte;
 I: Int;
 C: PClient;
begin
SB.Name := 'Force Update';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.CurrentSize := 0;
SB.MaxSize := SizeOf(SBData);

for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Connected or (C = HostClient) then
   begin
    SV_FullClientUpdate(C^, SB);
    if FSB_OVERFLOWED in SB.AllowOverflow then
     begin
      DPrint(['Client "', PLChar(@HostClient.NetName), '" (index #', (UInt(HostClient) - UInt(SVS.Clients)) div SizeOf(TClient) + 1,
              ') requested fullupdate, but the temporary buffer had overflowed. Ignoring the request.']);
      Exit;
     end;
   end;
 end;

DPrint(['Client "', PLChar(@HostClient.NetName), '" (index #', (UInt(HostClient) - UInt(SVS.Clients)) div SizeOf(TClient) + 1,
        ') requested fullupdate, sending.']);
Netchan_CreateFragments(HostClient.Netchan, SB);
Netchan_FragSend(HostClient.Netchan);
end;

procedure SV_ClientPrint(var C: TClient; Msg: PLChar; LineBreak: Boolean = True);
begin
if not C.FakeClient then
 begin
  MSG_WriteByte(C.Netchan.NetMessage, SVC_PRINT);
  if LineBreak then
   begin
    MSG_WriteBuffer(C.Netchan.NetMessage, StrLen(Msg), Msg);
    MSG_WriteChar(C.Netchan.NetMessage, #10);
    MSG_WriteChar(C.Netchan.NetMessage, #0);
   end
  else
   MSG_WriteString(C.Netchan.NetMessage, Msg);
 end;
end;

procedure SV_ClientPrint(var C: TClient; const Msg: array of const; LineBreak: Boolean = True);
begin
SV_ClientPrint(C, PLChar(StringFromVarRec(Msg)), LineBreak);
end;

procedure SV_ClientPrint(Msg: PLChar; LineBreak: Boolean = True);
begin
SV_ClientPrint(HostClient^, Msg, LineBreak);
end;

procedure SV_ClientPrint(const Msg: array of const; LineBreak: Boolean = True);
begin
SV_ClientPrint(HostClient^, PLChar(StringFromVarRec(Msg)), LineBreak);
end;

procedure SV_WriteClientDataToMessage(var C: TClient; var SB: TSizeBuf);
var
 E: PEdict;
 Frame: PClientFrame;
 OS: Pointer;
 I, Fields: UInt;
 NoDelta: Boolean;
 CD: TClientData;
 WD: TWeaponData;
begin
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
DLLFunctions.UpdateClientData(E^, Int32(C.LW), Frame.ClientData);
if not C.HLTV then
 begin
  NoDelta := C.UpdateMask = -1;
  MSG_WriteByte(SB, SVC_CLIENTDATA);
  MSG_StartBitWriting(SB);
  if NoDelta then
   begin
    MemSet(CD, SizeOf(CD), 0);  
    OS := @CD;
    MSG_WriteBits(0, 1);
   end
  else
   begin
    OS := @C.Frames[SVUpdateMask and C.UpdateMask].ClientData;
    MSG_WriteBits(1, 1);
    MSG_WriteBits(C.UpdateMask, 8);
   end;

  Delta_WriteDelta(OS, @Frame.ClientData, True, ClientDelta^, nil);
  if C.LW and (DLLFunctions.GetWeaponData(E^, Frame.WeaponData[0]) <> 0) then
   begin
    if NoDelta then
     MemSet(WD, SizeOf(WD), 0);

    for I := 0 to MAX_WEAPON_DATA - 1 do
     begin
      if NoDelta then
       OS := @WD
      else
       OS := @C.Frames[SVUpdateMask and C.UpdateMask].WeaponData[I];

      Fields := Delta_CheckDelta(OS, @Frame.WeaponData[I], WeaponDelta^);
      if Fields > 0 then
       begin
        MSG_WriteBits(1, 1);
        MSG_WriteBits(I, 6); // <- ?
        Delta_WriteMarkedDelta(OS, @Frame.WeaponData[I], True, WeaponDelta^, Fields, nil);
       end;
     end;
   end;

  MSG_WriteBits(0, 1);
  MSG_EndBitWriting;
 end;
end;

procedure SV_WriteSpawn(var C: TClient; var SB: TSizeBuf);
var
 I: Int;
 E: PEdict;
 P: PClient;
 SRD: TSaveRestoreData;
 Buf: array[1..MAX_PATH_A] of LChar;
begin
SZ_Clear(C.Netchan.NetMessage);
SZ_Clear(C.UnreliableMessage);
E := C.Entity;

if SV.SavedGame then
 begin
  if C.HLTV then
   begin
    SV_DropClient(C, False, 'HLTV proxies can''t connect to a saved game.');
    Exit;
   end;

  SV.Paused := False;
 end
else
 begin
  SV.State := SS_LOADING;
  ReleaseEntityDLLFields(E^);
  MemSet(E.V, SizeOf(E.V), 0);
  InitEntityDLLFields(E^);
  E.V.ColorMap := NUM_FOR_EDICT(E^);
  E.V.NetName := UInt(@C.NetName) - PRStrings;
  if C.HLTV then
   E.V.Flags := E.V.Flags or FL_PROXY;

  GlobalVars.Time := SV.Time;
  DLLFunctions.ClientPutInServer(E^);
  SV.State := SS_ACTIVE;
 end;

MSG_WriteByte(SB, SVC_TIME);
MSG_WriteFloat(SB, SV.Time);

C.UpdateInfo := True;

for I := 0 to SVS.MaxClients - 1 do
 begin
  P := @SVS.Clients[I];
  if (@C = P) or P.Active or P.Spawned or P.Connected then
   SV_FullClientUpdate(P^, SB);
 end;

for I := 0 to MAX_LIGHTSTYLES - 1 do
 begin
  MSG_WriteByte(SB, SVC_LIGHTSTYLE);
  MSG_WriteByte(SB, I);
  if SV.LightStyles[I] = nil then
   MSG_WriteString(SB, EmptyString)
  else
   MSG_WriteString(SB, SV.LightStyles[I]);
 end;

if not C.HLTV then
 begin
  MSG_WriteByte(SB, SVC_SETANGLE);
  MSG_WriteHiResAngle(SB, E.V.VAngle[0]);
  MSG_WriteHiResAngle(SB, E.V.VAngle[1]);
  MSG_WriteHiResAngle(SB, 0);
  SV_WriteClientDataToMessage(C, SB);
  if SV.SavedGame then
   begin
    MemSet(SRD, SizeOf(SRD), 0);
    GlobalVars.SaveData := @SRD;
    DLLFunctions.ParmsChangeLevel;
    MSG_WriteByte(SB, SVC_RESTORE);

    StrLCopy(@Buf, Host_SaveGameDirectory, SizeOf(Buf) - 1);
    StrLCat(PLChar(@Buf), @SV.Map, SizeOf(Buf) - 1);
    StrLCat(PLChar(@Buf), '.HL2', SizeOf(Buf) - 1);
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

C.Active := True;
C.Spawned := True;
C.Connected := True;
C.SendInfo := False;
C.FirstCmd := 0;
C.LastCmd := 0;
C.NextCmd := 0;
end;

procedure SV_WriteVoiceCodec(var SB: TSizeBuf);
begin
MSG_WriteByte(SB, SVC_VOICEINIT);
MSG_WriteString(SB, sv_voicecodec.Data);
MSG_WriteByte(SB, Trunc(sv_voicequality.Value));
end;

procedure SV_SendBan;
begin
SZ_Clear(NetMessage);
MSG_WriteLong(NetMessage, OUTOFBAND_TAG);
MSG_WriteChar(NetMessage, S2C_PRINT);
MSG_WriteString(NetMessage, 'You have been banned from this server.'#10);
NET_SendPacket(NS_SERVER, NetMessage.CurrentSize, NetMessage.Data, NetFrom);
SZ_Clear(NetMessage);
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
    S := StrECopy(S, ' SERVER (0x');
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

Index := (UInt(@C) - UInt(SVS.Clients)) div SizeOf(TClient);
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
 MSG_WriteString(SB, P)
else
 MSG_WriteString(SB, 'mapcycle failure');

if P <> nil then
 COM_FreeFile(P);

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
  HostClient.NeedConsistency := False;
 end
else
 begin
  J := 0;
  MSG_WriteBits(1, 1);
  HostClient.NeedConsistency := True;
  for I := 0 to SV.NumResources - 1 do
   begin
    P := @SV.Resources[I];
    if (P <> nil) and (RES_CHECKFILE in P.Flags) then
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
  MSG_WriteBits(Byte(P.ResourceType), 4);
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

procedure SV_ClearClientStates;
var
 I: Int;
 C: PClient;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  SV_ClearCustomizationList(C.Customization);
  SV_ClearResourceLists(C^);
  SV_SetResourceLists(C^);
  // netchan clear?
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
     Netchan_Clear(C.Netchan);
     SZ_Clear(C.UnreliableMessage);
     SV_ClearCustomizationList(C.Customization);
     MemSet(C.PhysInfo, SizeOf(C.PhysInfo), 0);
     C.SendResTime := 0;
     C.SendEntsTime := 0;
     C.FullUpdateTime := 0;
     C.NewCmdTime := 0;
     C.SpawnCmdTime := 0;
    end
   else
    SV_DropClient(C^, False, 'Dropping fakeclient on level change');
 end;
end;

function SV_CalcPing(const C: TClient): UInt;
var
 I, Frames, TotalFrames: UInt;
 TotalPing: Double;
 Frame: PClientFrame;
begin
Result := 0;

if C.Connected and not C.FakeClient then
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
    Frame := @C.Frames[(UInt(C.Netchan.IncomingAcknowledged) - I - 1) and SVUpdateMask];
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
     Result := Round(TotalPing * 1000);
   end;

  if Result = 0 then
   Result := 1;
 end;
end;

procedure SV_SetMaxClients;
var
 I: Int;
 S: PLChar;
begin
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

if SVS.MaxClients > 1 then
 SVUpdateBackup := 64
else
 SVUpdateBackup := 8;
SVUpdateMask := SVUpdateBackup - 1;

SVS.Clients := Hunk_AllocName(SizeOf(TClient) * SVS.MaxClientsLimit, 'clients');
for I := 0 to SVS.MaxClientsLimit - 1 do
 SV_SetResourceLists(SVS.Clients[I]);

if SVS.MaxClients <= 1 then
 CVar_DirectSet(deathmatch, '0')
else
 CVar_DirectSet(deathmatch, '1');
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
if (S^ > #0) and not MSG_BadRead then
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
 Size: UInt;
 Buf: array[1..4096] of Byte;
 P: PClient;
begin
Index := (UInt(@C) - UInt(SVS.Clients)) div SizeOf(TClient);
Size := MSG_ReadShort;
if (Size > SizeOf(Buf)) or MSG_BadRead then
 begin
  DPrint(['SV_ParseVoiceData: Invalid incoming packet from "', PLChar(@C.NetName), '".']);
  SV_DropClient(C, False, 'Invalid voice data.');
 end
else
 if Size > 0 then
  begin
   MSG_ReadBuffer(Size, @Buf);
   if not MSG_BadRead and (sv_voiceenable.Value <> 0) then
    for I := 0 to SVS.MaxClients - 1 do
     begin
      P := @SVS.Clients[I];
      if (P.Active and P.Connected and not (I in C.BlockedVoice)) or ((I = Index) and C.VoiceLoopback) then
       if P.UnreliableMessage.CurrentSize + Size + 4 < P.UnreliableMessage.MaxSize then
        begin
         MSG_WriteByte(P.UnreliableMessage, SVC_VOICEDATA);
         MSG_WriteByte(P.UnreliableMessage, Index);
         MSG_WriteShort(P.UnreliableMessage, Size);
         MSG_WriteBuffer(P.UnreliableMessage, Size, @Buf);
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
if (Frame.SentTime = 0) or (RealTime - C.ConnectTime < 2) then
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
   SV_DropClient(C, False, 'Bad client message.');
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
      SV_DropClient(C, False, ['Bad command character (', B, ') in client command.']);
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
 CVar_DirectSet(sv_timeout, '1.5');

Time := RealTime - sv_timeout.Value;
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Spawned or C.Connected) and not C.FakeClient and (C.Netchan.LastReceived < Time) then
   begin
    SV_BroadcastPrint(['"', PLChar(@C.NetName), '" timed out.'#10]);
    SV_DropClient(C^, False, 'Timed out.');
   end;
 end;
end;

function SV_ShouldUpdatePing(var C: TClient): Boolean;
begin
Result := (((C.UserCmd.Buttons and IN_SCORE) > 0) or C.HLTV) and (RealTime > C.NextPingTime);
end;

procedure SV_UpdateToReliableMessages;
var
 I: Int;
 C: PClient;
 SB: TSizeBuf;
 SBData: array[1..MAX_DATAGRAM] of Byte;
begin
SB.Name := 'Reliable tempbuffer';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData);
SB.CurrentSize := 0;

if sv_updatetime.Value < 0.1 then
 CVar_DirectSet(sv_updatetime, '1');
 
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if C.Connected then
   begin
    if C.UpdateInfo and (RealTime > C.UpdateInfoTime) then
     begin
      SV_ExtractFromUserInfo(C^);
      SV_FullClientUpdate(C^, SB);

      if FSB_OVERFLOWED in SB.AllowOverflow then
       C.UpdateInfoTime := RealTime + sv_updatetime.Value
      else
       if SV.ReliableDatagram.CurrentSize + SB.CurrentSize < SV.ReliableDatagram.MaxSize then
        begin
         SZ_Write(SV.ReliableDatagram, SB.Data, SB.CurrentSize);
         C.UpdateInfo := False;
         C.UpdateInfoTime := RealTime + sv_updatetime.Value;
        end
       else
        C.UpdateInfoTime := RealTime + sv_updatetime.Value / (4 / 3);

      SZ_Clear(SB);
     end;

    if (NewUserMsgs <> nil) and not C.FakeClient then
     SV_SendUserReg(C.Netchan.NetMessage, NewUserMsgs);
   end;
 end;

SV_LinkNewUserMsgs;

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
     begin
      SZ_Clear(SB);
      SZ_Write(SB, SV.ReliableDatagram.Data, SV.ReliableDatagram.CurrentSize);
      Netchan_CreateFragments(C.Netchan, SB);
     end;

    if SV.Datagram.CurrentSize + C.UnreliableMessage.CurrentSize < C.UnreliableMessage.MaxSize then
     SZ_Write(C.UnreliableMessage, SV.Datagram.Data, SV.Datagram.CurrentSize)
    else
     DPrint(['Ignoring unreliable datagram for "', PLChar(@C.NetName), '", would overflow.']);

    if C.HLTV then
     if SV.Spectator.CurrentSize + C.UnreliableMessage.CurrentSize < C.UnreliableMessage.MaxSize then
      SZ_Write(C.UnreliableMessage, SV.Spectator.Data, SV.Spectator.CurrentSize)
     else
      DPrint(['Ignoring unreliable spectator datagram for "', PLChar(@C.NetName), '", would overflow.']);
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
  if C.Active and C.Connected then
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
 SBData: array[1..MAX_DATAGRAM] of Byte;
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
 DPrint(['Warning: Unreliable datagram overflowed for "', PLChar(@C.NetName), '".'])
else
 SZ_Write(SB, C.UnreliableMessage.Data, C.UnreliableMessage.CurrentSize);
SZ_Clear(C.UnreliableMessage);

if FSB_OVERFLOWED in SB.AllowOverflow then
 DPrint(['Warning: Message overflowed for "', PLChar(@C.NetName), '".'])
else
 Netchan_Transmit(C.Netchan, SB.CurrentSize, SB.Data);
 
Result := True;
end;

procedure SV_SendClientMessages;
var
 I: Int;
 C: PClient;
begin
SV_UpdateToReliableMessages;

if sv_failuretime.Value < 0.1 then
 CVar_SetValue('sv_failuretime', 0.1);

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
        (C.Active and C.Spawned and C.SendInfo and (RealTime + HostFrameTime >= C.NextUpdateTime)) then
      C.NeedUpdate := True;

     if FSB_OVERFLOWED in C.Netchan.NetMessage.AllowOverflow then
      begin
       SZ_Clear(C.Netchan.NetMessage);
       SZ_Clear(C.UnreliableMessage);
       SV_BroadcastPrint(['"', PLChar(@C.NetName), '" overflowed.'#10]);
       DPrint(['Warning: Reliable channel overflowed for "', PLChar(@C.NetName), '".']);
       SV_DropClient(C^, False, 'Reliable channel overflowed.');
       C.NeedUpdate := False;
       C.Netchan.ClearTime := 0;
      end
     else
      if C.NeedUpdate and (RealTime - C.Netchan.LastReceived > sv_failuretime.Value) then
       C.NeedUpdate := False;

     if C.NeedUpdate then
      if Netchan_CanPacket(C.Netchan) then
       begin
        C.NeedUpdate := False;
        C.NextUpdateTime := RealTime + HostFrameTime + C.UpdateRate;
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
