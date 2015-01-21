unit SVAuth;

{$I HLDS.inc}

interface

uses Default, SDK;

function SV_CreateSID(const C: TClient): Int64;
function SV_GetClientIDString(const C: TClient): PLChar;

implementation

uses Common, Network;

function SV_CreateSID(const C: TClient): Int64;
begin
Result := (RandomLong(MinInt, MaxInt) shl 32) or
          RandomLong(MinInt, MaxInt);  
end;

function SV_GetClientIDString(const C: TClient): PLChar;
begin
if C.FakeClient then
 Result := 'BOT'
else
 if C.HLTV then
  Result := 'HLTV'
 else
  if NET_IsReservedAdr(C.Netchan.Addr) then
   Result := 'STEAM_ID_LAN'
  else
   Result := 'STEAM_0:0:12345';
end;

end.
