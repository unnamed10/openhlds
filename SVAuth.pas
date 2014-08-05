unit SVAuth;

{$I HLDS.inc}

interface

uses Default, SDK;

function SV_CreateSID(const C: TClient): Int64;

function SV_GetClientIDString(const C: TClient): PLChar;
function SV_GetClientID(const C: TClient): Int64;

function SV_StringToUID(S: PLChar): Int64;
function SV_UIDToString(ID: Int64): PLChar;


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
  if C.Netchan.Addr.AddrType = NA_LOOPBACK then
   Result := 'LOOPBACK'
  else
   if NET_IsReservedAdr(C.Netchan.Addr) then
    Result := 'LAN'
   else
    Result := 'PLAYER';
end;

function SV_GetClientID(const C: TClient): Int64;
begin
Result := 1;
end;

function SV_StringToUID(S: PLChar): Int64;
begin
Result := 1;
end;

function SV_UIDToString(ID: Int64): PLChar;
begin
Result := '';
end;

end.
