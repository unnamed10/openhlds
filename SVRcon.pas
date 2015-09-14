unit SVRcon;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

type
 TRedirectType = (srNone = 0, srClient, srRemote);

procedure SV_FlushRedirect;
procedure SV_BeginRedirect(RT: TRedirectType; const Addr: TNetAdr);
procedure SV_EndRedirect;

function SV_RedirectPrint(S: PLChar): Boolean;

procedure SV_CheckForRcon;
procedure SV_ResetRcon_F; cdecl;
procedure SV_Rcon(const Addr: TNetAdr);

var
 rcon_password: TCVar = (Name: 'rcon_password'; Data: '');
 sv_rcon_minfailures: TCVar = (Name: 'sv_rcon_minfailures'; Data: '5');
 sv_rcon_maxfailures: TCVar = (Name: 'sv_rcon_maxfailures'; Data: '10');
 sv_rcon_minfailuretime: TCVar = (Name: 'sv_rcon_minfailuretime'; Data: '30');
 sv_rcon_banpenalty: TCVar = (Name: 'sv_rcon_banpenalty'; Data: '0');

 RedirectType: TRedirectType;
 RedirectBuf: array[1..MAX_FRAGLEN - 7] of LChar;
 RedirectTo: TNetAdr;

implementation

uses Common, Console, Host, Memory, MsgBuf, Network, SVClient, SVMain, SVPacket;

const
 MAX_RCON_FAILURE_TIMES = 20;
 MAX_RCON_FAILURES = 32;

type
 PFailedRcon = ^TFailedRcon;
 TFailedRcon = record
  Active: Boolean;
  ShouldReject: Boolean;
  Addr: TNetAdr;
  NumFailures: UInt;
  Time: Single;
  FailureTimes: array[0..MAX_RCON_FAILURE_TIMES - 1] of Single;
 end;

var
 RconFailures: array[0..MAX_RCON_FAILURES - 1] of TFailedRcon;

procedure SV_FlushRedirect;
var
 SB: TSizeBuf;
 Buf: array[1..MAX_FRAGLEN] of LChar;
begin
if RedirectBuf[Low(RedirectBuf)] > #0 then
 if RedirectType = srRemote then
  begin
   SB.Name := 'Redirected Text';
   SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
   SB.Data := @Buf;
   SB.MaxSize := SizeOf(Buf);
   SB.CurrentSize := 0;

   MSG_WriteLong(SB, OUTOFBAND_TAG);
   MSG_WriteChar(SB, S2C_PRINT);
   MSG_WriteString(SB, @RedirectBuf);
   MSG_WriteChar(SB, #0);

   if not (FSB_OVERFLOWED in SB.AllowOverflow) then
    NET_SendPacket(NS_SERVER, SB.CurrentSize, SB.Data, RedirectTo);
  end
 else
  if RedirectType = srClient then
   begin
    MSG_WriteByte(HostClient.Netchan.NetMessage, SVC_PRINT);
    MSG_WriteString(HostClient.Netchan.NetMessage, @RedirectBuf);
   end;

RedirectBuf[Low(RedirectBuf)] := #0;
end;

procedure SV_BeginRedirect(RT: TRedirectType; const Addr: TNetAdr);
begin
RedirectTo := Addr;
RedirectType := RT;
RedirectBuf[Low(RedirectBuf)] := #0;
end;

procedure SV_EndRedirect;
begin
SV_FlushRedirect;
RedirectType := srNone;
end;

function SV_RedirectPrint(S: PLChar): Boolean;
begin
Result := RedirectType <> srNone;
if Result then
 begin
  if StrLen(@RedirectBuf) + StrLen(S) >= SizeOf(RedirectBuf) then
   SV_FlushRedirect;

  StrLCat(@RedirectBuf, S, SizeOf(RedirectBuf) - 1);
 end;
end;

procedure SV_ResetRcon_F; cdecl;
begin
MemSet(RconFailures, SizeOf(RconFailures), 0);
end;

procedure SV_CheckRconCVars;
var
 F: Single;
begin
if sv_rcon_minfailures.Value < 1 then
 CVar_DirectSet(sv_rcon_minfailures, '1')
else
 if sv_rcon_minfailures.Value > 20 then
  CVar_DirectSet(sv_rcon_minfailures, '20');

if sv_rcon_maxfailures.Value < 1 then
 CVar_DirectSet(sv_rcon_maxfailures, '1')
else
 if sv_rcon_maxfailures.Value > 20 then
  CVar_DirectSet(sv_rcon_maxfailures, '20');

if sv_rcon_maxfailures.Value < sv_rcon_minfailures.Value then
 begin
  F := sv_rcon_maxfailures.Value;
  CVar_SetValue('sv_rcon_maxfailures', sv_rcon_minfailures.Value);
  CVar_SetValue('sv_rcon_minfailures', F);
 end;

if sv_rcon_minfailuretime.Value < 1 then
 CVar_DirectSet(sv_rcon_minfailuretime, '1');
end;

procedure SV_AddFailedRcon(const Addr: TNetAdr);
var
 AddrBuf: array[1..64] of LChar;
 I: Int;
 R, R2: PFailedRcon;
 Time: Single;
 J: UInt;
begin
SV_CheckRconCVars;

R2 := @RconFailures[0];
Time := RealTime;

for I := 0 to MAX_RCON_FAILURES - 1 do
 begin
  R := @RconFailures[I];
  if not R.Active then
   Break
  else
   if NET_CompareAdr(Addr, R.Addr) then
    begin
     R2 := nil;
     Break;
    end
   else
    if R.Time < Time then
     begin
      Time := R.Time;
      R2 := R;
     end;
 end;

if R2 <> nil then
 begin
  R := R2;
  R.ShouldReject := False;
  R.NumFailures := 0;
  R.Addr := Addr;
 end
else
 if R.ShouldReject then
  Exit;

R.Active := True;
R.Time := RealTime;

J := Trunc(sv_rcon_maxfailures.Value);
if R.NumFailures >= J then
 begin
  for I := 0 to J - 2 do
   R.FailureTimes[I] := R.FailureTimes[I + 1];
  R.NumFailures := J - 1;
 end;

R.FailureTimes[R.NumFailures] := RealTime;
Inc(R.NumFailures);

J := 0;
for I := 0 to R.NumFailures - 2 do
 if RealTime - R.FailureTimes[I] <= sv_rcon_minfailuretime.Value then
  Inc(J);

if J >= Trunc(sv_rcon_minfailures.Value) then
 begin
  Print(['User ', NET_AdrToString(Addr, AddrBuf, SizeOf(AddrBuf)), ' will be banned for rcon hacking attempts.']);
  R.ShouldReject := True;
 end;
end;

function SV_CheckRconFailure(const Addr: TNetAdr): Boolean;
var
 I: Int;
 R: PFailedRcon;
begin
for I := 0 to MAX_RCON_FAILURES - 1 do
 begin
  R := @RconFailures[I];
  if R.Active and NET_CompareAdr(Addr, R.Addr) and R.ShouldReject then
   begin
    Result := True;
    Exit;
   end;
 end;

Result := False;
end;

function SV_Rcon_Validate: Boolean;
var
 AddrBuf: array[1..64] of LChar;
begin
Result := False;

if (Cmd_Argc >= 3) and (rcon_password.Data^ > #0) then
 begin
  if sv_rcon_banpenalty.Value < 0 then
   CVar_DirectSet(sv_rcon_banpenalty, '0');

  if SV_CheckRconFailure(NetFrom) then
   begin
    Print(['Banning "', NET_AdrToString(NetFrom, AddrBuf, SizeOf(AddrBuf)), '" for rcon hacking attempts.']);
    CBuf_AddText(['addip ', Trunc(sv_rcon_banpenalty.Value), ' ', NET_BaseAdrToString(NetFrom, AddrBuf, SizeOf(AddrBuf))]);
   end
  else
   if SV_CheckChallenge(NetFrom, StrToInt(Cmd_Argv(1)), True) then
    if StrComp(Cmd_Argv(2), rcon_password.Data) <> 0 then
     SV_AddFailedRcon(NetFrom)
    else
     Result := True;
 end;
end;

procedure SV_Rcon(const Addr: TNetAdr);
var
 CmdBuf: array[1..1024] of LChar;
 AddrBuf: array[1..64] of LChar;
 B: Boolean;
 Cmd, Pwd: PLChar;
begin
B := SV_Rcon_Validate;

Cmd := COM_Parse(COM_Parse(Cmd_Args));
if Cmd = nil then
 Cmd := EmptyString
else
 while Cmd^ in [#1..' '] do
  Inc(UInt(Cmd));

if Cmd_Argc >= 3 then
 Pwd := Cmd_Argv(2)
else
 Pwd := 'No password specified';

if not B then
 begin
  Print(['Bad rcon from ', NET_AdrToString(NetFrom, AddrBuf, SizeOf(AddrBuf)), ' ("', Pwd, '"): ', Cmd]);
  LPrint(['Bad Rcon: "', Cmd_Args, '" from "', NET_AdrToString(NetFrom, AddrBuf, SizeOf(AddrBuf)), #10]);
 end
else
 begin
  Print(['Rcon from ', NET_AdrToString(NetFrom, AddrBuf, SizeOf(AddrBuf)), ': ', Cmd]);
  LPrint(['Rcon: "', Cmd_Args, '" from "', NET_AdrToString(NetFrom, AddrBuf, SizeOf(AddrBuf)), #10]);
 end;

SV_BeginRedirect(srRemote, NetFrom);

if not B then
 if rcon_password.Data^ = #0 then
  SV_RedirectPrint('Bad rcon_password.'#10'No password set for this server.'#10)
 else
  SV_RedirectPrint('Bad rcon_password.'#10)
else
 if Cmd^ > #0 then
  begin
   StrLCopy(@CmdBuf, Cmd, SizeOf(CmdBuf) - 1);
   Cmd_ExecuteString(@CmdBuf, csServer);
  end;

SV_EndRedirect;
end;

procedure SV_CheckForRcon;
begin
if not SV.Active and not QuitCommandIssued and HostInit then
 while NET_GetPacket(NS_SERVER) do
  if SV_FilterPacket then
   SV_SendBan
  else
   SV_HandleRconPacket;
end;

end.
