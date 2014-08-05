unit SVRcon;

{$I HLDS.inc}

interface

uses Default, SDK;

type
 TRedirectType = (srNone = 0, srClient, srRemote);

procedure SV_FlushRedirect;
procedure SV_BeginRedirect(RT: TRedirectType; const Addr: TNetAdr);
procedure SV_EndRedirect;

procedure SV_CheckForRcon;

procedure SV_Rcon(const Addr: TNetAdr);

var
 rcon_password: TCVar = (Name: 'rcon_password'; Data: ''); 

 RedirectType: TRedirectType;
 RedirectBuf: array[1..MAX_FRAGLEN - 6] of LChar;
 RedirectTo: TNetAdr;

implementation

uses Console, Host, Memory, MsgBuf, Network, Server, SVPacket, SVSend;

procedure SV_FlushRedirect;
var
 SB: TSizeBuf;
 Buf: array[1..MAX_FRAGLEN] of LChar;
begin
if RedirectType = srRemote then
 begin
  SB.Name := 'Redirected Text';
  SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
  SB.Data := @Buf;
  SB.MaxSize := StrLen(@RedirectBuf) + 7;
  SB.CurrentSize := 0;

  MSG_WriteLong(SB, OUTOFBAND_TAG);
  MSG_WriteChar(SB, S2C_PRINT);
  MSG_WriteString(SB, @RedirectBuf);
  MSG_WriteChar(SB, #0);

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

procedure SV_CheckForRcon;
begin
if not SV.Active and not QuitCommandIssued and HostInit then
 while NET_GetPacket(NS_SERVER) do
  if SV_FilterPacket then
   SV_SendBan
  else
   SV_HandleRconPacket;
end;

procedure SV_Rcon(const Addr: TNetAdr);
begin

end;

end.
