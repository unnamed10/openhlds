unit Network;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS} Windows, Winsock, {$ELSE} Libc, KernelIoctl, {$ENDIF} Default, SDK;

function Q_ntohs(I: UInt16): UInt16;

function NET_AdrToString(const A: TNetAdr; out Buf; L: UInt): PLChar; overload;
function NET_BaseAdrToString(const A: TNetAdr; out Buf; L: UInt): PLChar;
function NET_CompareBaseAdr(const A1, A2: TNetAdr): Boolean;

function NET_CompareAdr(const A1, A2: TNetAdr): Boolean;
function NET_StringToAdr(S: PLChar; out A: TNetAdr): Boolean;
function NET_StringToSockaddr(Name: PLChar; out S: TSockAddr): Boolean;
function NET_CompareClassBAdr(const A1, A2: TNetAdr): Boolean;
function NET_IsReservedAdr(const A: TNetAdr): Boolean;
function NET_IsLocalAddress(const A: TNetAdr): Boolean;
procedure NET_Config(EnableNetworking: Boolean);

procedure NET_SendPacket(Source: TNetSrc; Size: UInt; Buffer: Pointer; const Dest: TNetAdr);

procedure NET_ThreadLock;
procedure NET_ThreadUnlock;

function NET_AllocMsg(Size: UInt): PNetQueue;

function NET_GetPacket(Source: TNetSrc): Boolean;

procedure NET_ClearLagData(Client, Server: Boolean);

procedure NET_Init;
procedure NET_Shutdown;

procedure Netchan_OutOfBandPrint(Source: TNetSrc; const Addr: TNetAdr; S: PLChar); overload;
procedure Netchan_OutOfBandPrint(Source: TNetSrc; const Addr: TNetAdr; const S: array of const); overload;

// netchan
procedure Netchan_FragSend(var C: TNetchan);
procedure Netchan_AddBufferToList(var Base: PFragBuf; P: PFragBuf);

procedure Netchan_Clear(var C: TNetchan);

procedure Netchan_CreateFragments(var C: TNetchan; var SB: TSizeBuf);
procedure Netchan_CreateFileFragmentsFromBuffer(var C: TNetchan; Name: PLChar; Buffer: Pointer; Size: UInt);

function Netchan_CreateFileFragments(Server: Boolean; C: PNetchan; Name: PLChar): Boolean;

procedure Netchan_FlushIncoming(var C: TNetchan; Index: UInt);

function Netchan_CompressPacket(SB: PSizeBuf): Int;
function Netchan_DecompressPacket(SB: PSizeBuf): Int;

procedure Netchan_Setup(Source: TNetSrc; var C: TNetchan; const Addr: TNetAdr; ClientID: Int; ClientPtr: PClient; Func: TFragmentSizeFunc);

function Netchan_Process(var C: TNetchan): Boolean;
procedure Netchan_Transmit(var C: TNetchan; Size: UInt; Buffer: Pointer);

function Netchan_IncomingReady(const C: TNetchan): Boolean;

function Netchan_CopyNormalFragments(var C: TNetchan): Boolean;
function Netchan_CopyFileFragments(var C: TNetchan): Boolean;

function Netchan_CanPacket(var C: TNetchan): Boolean;

procedure Netchan_Init;

const
 NETMSG_SIZE = 65536;
 
var
 InMessage, NetMessage: TSizeBuf;
 InFrom, NetFrom: TNetAdr;

 NoIP: Boolean = False;
 NoIPX: Boolean = True;

 LocalIP, LocalIPX: TNetAdr;

 clockwindow: TCVar = (Name: 'clockwindow'; Data: '0.5');

 NetDrop: UInt32 = 0;

implementation

uses BZip2, Common, Console, FileSys, Memory, MsgBuf, Host, HostCmds, Resource, Server, SVClient, SysArgs, SysMain;

type
 ip_mreq = record
  imr_multiaddr: in_addr;
  imr_interface: in_addr;
 end;
 PIpMReq = ^TIpMReq;
 TIpMReq = ip_mreq;

var
 OldConfig: Boolean = False;
 FirstConfig: Boolean = True;
 NetConfigured: Boolean = False;

 IPSockets, IPXSockets: array[TNetSrc] of TSocket;

 InMsgBuffer, NetMsgBuffer: array[1..NETMSG_SIZE] of Byte;

 // cvars
 net_address: TCVar = (Name: 'net_address'; Data: '');
 ipname: TCVar = (Name: 'ip'; Data: 'localhost');
 ip_hostport: TCVar = (Name: 'ip_hostport'; Data: '0');
 hostport: TCVar = (Name: 'hostport'; Data: '0');
 defport: TCVar = (Name: 'port'; Data: '27015');
 ipx_hostport: TCVar = (Name: 'ipx_hostport'; Data: '0');
 
 fakelag: TCVar = (Name: 'fakelag'; Data: '0');
 fakeloss: TCVar = (Name: 'fakeloss'; Data: '0');

 // threading
 UseThread: Boolean = False;
 ThreadInit: Boolean = False;
 ThreadCS: TCriticalSection;
 ThreadHandle: UInt;
 ThreadID: UInt32;

 NormalQueue: PNetQueue = nil;
 NetMessages: array[TNetSrc] of PNetQueue;

 NetSleepForever: Boolean = True;

 // loopbacks
 Loopbacks: array[0..1] of TLoopBack;

 // lagdata
 LagData: array[TNetSrc] of TLagPacket;

 FakeLagTime: Single = 0;
 LastLagTime: Double = 0;

 LossCount: array[TNetSrc] of UInt32 = (0, 0, 0);

 SendSeqNumber: Int32 = 1;
 // split
 SplitCtx: record
  InSeq: Int32;
  TotalPackets, RecvBytes: UInt32;
  Data: array[1..MAX_NETPACKETLEN] of Byte;

  // integrated
  Sequences: array[0..MAX_SPLIT - 1] of Int32;
 end = (Sequences: (-1, -1, -1, -1, -1));

 // netchan stuff
 net_log: TCVar = (Name: 'net_log'; Data: '0'); 
 net_showpackets: TCVar = (Name: 'net_showpackets'; Data: '0');
 net_showdrop: TCVar = (Name: 'net_showdrop'; Data: '0');
 net_chokeloop: TCVar = (Name: 'net_chokeloop'; Data: '0');
 sv_filetransfercompression: TCVar = (Name: 'sv_filetransfercompression'; Data: '1');
 sv_filetransfermaxsize: TCVar = (Name: 'sv_filetransfermaxsize'; Data: '20000000');
 sv_filereceivemaxsize: TCVar = (Name: 'sv_filereceivemaxsize'; Data: '1000000');
 sv_receivedecalsonly: TCVar = (Name: 'sv_receivedecalsonly'; Data: '0');

 // 0 - disabled
 // 1 - normal packets only
 // 2 - files only
 // 3 - packets & files
 net_compress: TCVar = (Name: 'net_compress'; Data: '3');

function NET_LastError: Int;
begin
{$IFDEF MSWINDOWS}
Result := WSAGetLastError;
{$ELSE}
Result := errno; // h_errno
{$ENDIF}
end;

procedure NET_ThreadLock;
begin
if UseThread and ThreadInit then
 Sys_EnterCS(ThreadCS);
end;

procedure NET_ThreadUnlock;
begin
if UseThread and ThreadInit then
 Sys_LeaveCS(ThreadCS);
end;

function Q_ntohs(I: UInt16): UInt16;
begin
Result := (I shl 8) or (I shr 8);
end;

function Q_htons(I: UInt16): UInt16;
begin
Result := (I shl 8) or (I shr 8);
end;

procedure NetadrToSockadr(const A: TNetAdr; out S: TSockAddr);
begin
MemSet(S, SizeOf(S), 0);
case A.AddrType of
 NA_BROADCAST:
  begin
   S.sin_family := AF_INET;
   S.sin_port := A.Port;
   UInt32(S.sin_addr.S_addr) := $FFFFFFFF;
  end;
 NA_IP:
  begin
   S.sin_family := AF_INET;
   S.sin_port := A.Port;
   UInt32(S.sin_addr.S_addr) := UInt32(A.IP);
  end;
 NA_IPX:
  begin
   S.sin_family := AF_IPX;
   Move(A.IPX, S.sa_data[0], SizeOf(A.IPX));
   PUInt16(@S.sa_data[10])^ := A.Port;
  end;
 NA_BROADCAST_IPX:
  begin
   S.sin_family := AF_IPX;
   Move(A.IPX, S.sa_data[0], 4);
   MemSet(Pointer(@A.IPX[5])^, 6, $FF);
   PUInt16(@S.sa_data[10])^ := A.Port;
  end;
end;  
end;

procedure SockadrToNetadr(const S: TSockAddr; out A: TNetAdr);
begin
if S.sa_family = AF_INET then
 begin
  A.AddrType := NA_IP;
  PUInt32(@A.IP)^ := PUInt32(@S.sin_addr)^;
  A.Port := S.sin_port;
 end
else
 if S.sa_family = AF_IPX then
  begin
   A.AddrType := NA_IPX;
   Move(S.sa_data, A.IPX, SizeOf(A.IPX));
   A.Port := PUInt16(@S.sa_data[10])^;
  end;
end;

function NET_CompareAdr(const A1, A2: TNetAdr): Boolean;
begin
if A1.AddrType <> A2.AddrType then
 Result := False
else
 case A1.AddrType of
  NA_LOOPBACK: Result := True;
  NA_IP: Result := (UInt32(A1.IP) = UInt32(A2.IP)) and (A1.Port = A2.Port);
  NA_IPX: Result := CompareMem(@A1.IPX, @A2.IPX, SizeOf(A2.IPX)) and (A1.Port = A2.Port);
  else Result := False;  
 end;
end;

function NET_CompareClassBAdr(const A1, A2: TNetAdr): Boolean;
begin
if A1.AddrType <> A2.AddrType then
 Result := False
else
 case A1.AddrType of
  NA_LOOPBACK, NA_IPX: Result := True;
  NA_IP: Result := (A1.IP[1] = A2.IP[1]) and (A1.IP[2] = A2.IP[2]);
  else Result := False;
 end;
end;

// RFC 1918: 192.168/16
function NET_IsReservedAdr(const A: TNetAdr): Boolean;
begin
case A.AddrType of
 NA_LOOPBACK, NA_IPX: Result := True;
 NA_IP: Result := (A.IP[1] = 10) or (A.IP[1] = 127) or
                  ((A.IP[1] = 172) and (A.IP[2] >= 16) and (A.IP[2] <= 31)) or
                  ((A.IP[1] = 192) and (A.IP[2] = 168));
 else Result := False;
end;
end;

function NET_CompareBaseAdr(const A1, A2: TNetAdr): Boolean;
begin
if A1.AddrType <> A2.AddrType then
 Result := False
else
 case A1.AddrType of
  NA_LOOPBACK: Result := True;
  NA_IP: Result := UInt32(A1.IP) = UInt32(A2.IP);
  NA_IPX: Result := CompareMem(@A1.IPX, @A2.IPX, SizeOf(A2.IPX));
  else Result := False;  
 end;
end;

// not threadsafe, but can be used by gamedll
var
 AdrBuf: array[1..64] of LChar;

function NET_AdrToString2(const A: TNetAdr): PLChar;
var
 I: UInt;
 S: PLChar;
begin
MemSet(AdrBuf, SizeOf(AdrBuf), 0);
if A.AddrType = NA_LOOPBACK then
 StrLCopy(@AdrBuf, 'loopback', SizeOf(AdrBuf) - 1)
else
 if A.AddrType = NA_IP then
  begin
   S := @AdrBuf;

   for I := 1 to 4 do
    begin
     S := IntToStrE(A.IP[I], S^, 4); // 3 + 1
     S^ := '.';
     Inc(UInt(S));
    end;

   PLChar(UInt(S) - 1)^ := ':';
   IntToStr(Q_ntohs(A.Port), S^, 6);
  end
 else
  begin
   S := @AdrBuf;
   for I := 1 to 4 do
    begin
     ByteToHex(A.IPX[I], S);
     Inc(UInt(S), 2);
    end;
   S^ := ':';
   Inc(UInt(S));
   for I := 5 to 10 do
    begin
     ByteToHex(A.IPX[I], S);
     Inc(UInt(S), 2);
    end;
   S^ := ':';
   Inc(UInt(S));
   IntToStr(Q_ntohs(A.Port), S^, 6);
  end;

Result := @AdrBuf;
end;

function NET_AdrToString(const A: TNetAdr; out Buf; L: UInt): PLChar; overload;
begin
if (@Buf = nil) or (L = 0) then
 Result := nil
else
 begin
  case A.AddrType of
   NA_LOOPBACK: StrLCopy(@Buf, 'loopback', L - 1);
   NA_IP, NA_BROADCAST: FormatBuf(Buf, L, '%d.%d.%d.%d:%d%s', Length('%d.%d.%d.%d:%d%s'),
                                  [A.IP[1], A.IP[2], A.IP[3], A.IP[4], Q_ntohs(A.Port), #0]);
   NA_IPX, NA_BROADCAST_IPX: FormatBuf(Buf, L, '%02x%02x%02x%02x:%02x%02x%02x%02x%02x%02x:%d%s', Length('%02x%02x%02x%02x:%02x%02x%02x%02x%02x%02x:%d%s'),
                             [A.IPX[1], A.IPX[2], A.IPX[3], A.IPX[4], A.IPX[5], A.IPX[6], A.IPX[7], A.IPX[8], A.IPX[9], A.IPX[10], Q_ntohs(A.Port), #0]);
   else StrLCopy(@Buf, '(bad address)', L - 1);
  end;

  PLChar(UInt(@Buf) + L - 1)^ := #0;
  Result := @Buf;
 end;
end;

function NET_BaseAdrToString(const A: TNetAdr; out Buf; L: UInt): PLChar;
begin
if L = 0 then
 begin
  Result := nil;
  Exit;
 end;

if A.AddrType = NA_LOOPBACK then
 StrLCopy(@Buf, 'loopback', L - 1)
else
 if A.AddrType = NA_IP then
  FormatBuf(Buf, L, '%d.%d.%d.%d%s', Length('%d.%d.%d.%d%s'),
            [A.IP[1], A.IP[2], A.IP[3], A.IP[4], #0])
 else
  FormatBuf(Buf, L, '%02x%02x%02x%02x:%02x%02x%02x%02x%02x%02x%s', Length('%02x%02x%02x%02x:%02x%02x%02x%02x%02x%02x%s'),
            [A.IPX[1], A.IPX[2], A.IPX[3], A.IPX[4], A.IPX[5], A.IPX[6], A.IPX[7], A.IPX[8], A.IPX[9], A.IPX[10], #0]);

Result := @Buf;
end;

function NET_StringToSockaddr(Name: PLChar; out S: TSockAddr): Boolean;
const
 Ofs: array[0..9] of UInt =
      (0, 2, 4, 6, 9, 11, 13, 15, 17, 19);
var
 I: UInt;
 Buf: array[1..256] of LChar;
 P: PLChar;
 J: UInt32;
 E: PHostEnt;
begin
Result := True;
MemSet(S, SizeOf(S), 0);
if (StrLen(Name) > 24) and (PLChar(UInt(Name) + 8)^ = ':') and
   (PLChar(UInt(Name) + 21)^ = ':') then
 begin
  S.sin_family := AF_IPX;
  for I := Low(Ofs) to High(Ofs) do
   PByte(@S.sa_data[I])^ := HexToByte(PLChar(UInt(Name) + Ofs[I]));
  PUInt16(@S.sa_data[High(Ofs) + 1])^ := Q_htons(StrToInt(PLChar(UInt(Name) + 22)));
 end
else
 begin
  S.sin_family := AF_INET;
  S.sin_port := 0;
  P := StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
  Buf[High(Buf)] := #0;

  while P^ > #0 do
   begin
    if P^ = ':' then
     begin
      P^ := #0;
      S.sin_port := Q_htons(StrToInt(PLChar(UInt(P) + 1)));
     end;

    Inc(UInt(P));
   end;
   
  J := UInt32(inet_addr(@Buf));
  if J = UInt32(INADDR_NONE) then
   begin
    E := gethostbyname(@Buf);
    if E = nil then
     Result := False
    else
     J := PUInt32(PPointer(E.h_addr_list)^)^;
   end;

  PUInt32(@S.sin_addr)^ := J;
 end;
end;

function NET_StringToAdr(S: PLChar; out A: TNetAdr): Boolean;
var
 SAdr: TSockAddr;
begin         
if StrComp(S, 'localhost') = 0 then
 begin
  MemSet(A, SizeOf(A), 0);
  A.AddrType := NA_LOOPBACK;
  Result := True;
 end
else
 begin
  Result := NET_StringToSockaddr(S, SAdr);
  if Result then
   SockadrToNetadr(SAdr, A);
 end;
end;

function NET_IsLocalAddress(const A: TNetAdr): Boolean;
begin
Result := A.AddrType = NA_LOOPBACK;
end;

function NET_ErrorString(E: UInt): PLChar;
begin
{$IFDEF MSWINDOWS}
case E of
 WSAEINTR: Result := 'WSAEINTR';
 WSAEBADF: Result := 'WSAEBADF';
 WSAEACCES: Result := 'WSAEACCES';
 WSAEFAULT: Result := 'WSAEFAULT';
 WSAEINVAL: Result := 'WSAEINVAL';
 WSAEMFILE: Result := 'WSAEMFILE';
 WSAEWOULDBLOCK: Result := 'WSAEWOULDBLOCK';
 WSAEINPROGRESS: Result := 'WSAEINPROGRESS';
 WSAEALREADY: Result := 'WSAEALREADY';
 WSAENOTSOCK: Result := 'WSAENOTSOCK';
 WSAEDESTADDRREQ: Result := 'WSAEDESTADDRREQ';
 WSAEMSGSIZE: Result := 'WSAEMSGSIZE';
 WSAEPROTOTYPE: Result := 'WSAEPROTOTYPE';
 WSAENOPROTOOPT: Result := 'WSAENOPROTOOPT';
 WSAEPROTONOSUPPORT: Result := 'WSAEPROTONOSUPPORT';
 WSAESOCKTNOSUPPORT: Result := 'WSAESOCKTNOSUPPORT';
 WSAEOPNOTSUPP: Result := 'WSAEOPNOTSUPP';
 WSAEPFNOSUPPORT: Result := 'WSAEPFNOSUPPORT';
 WSAEAFNOSUPPORT: Result := 'WSAEAFNOSUPPORT';
 WSAEADDRINUSE: Result := 'WSAEADDRINUSE';
 WSAEADDRNOTAVAIL: Result := 'WSAEADDRNOTAVAIL';
 WSAENETDOWN: Result := 'WSAENETDOWN';
 WSAENETUNREACH: Result := 'WSAENETUNREACH';
 WSAENETRESET: Result := 'WSAENETRESET';
 WSAECONNABORTED: Result := 'WSAECONNABORTED';
 WSAECONNRESET: Result := 'WSAECONNRESET';
 WSAENOBUFS: Result := 'WSAENOBUFS';
 WSAEISCONN: Result := 'WSAEISCONN';
 WSAENOTCONN: Result := 'WSAENOTCONN';
 WSAESHUTDOWN: Result := 'WSAESHUTDOWN';
 WSAETOOMANYREFS: Result := 'WSAETOOMANYREFS';
 WSAETIMEDOUT: Result := 'WSAETIMEDOUT';
 WSAECONNREFUSED: Result := 'WSAECONNREFUSED';
 WSAELOOP: Result := 'WSAELOOP';
 WSAENAMETOOLONG: Result := 'WSAENAMETOOLONG';
 WSAEHOSTDOWN: Result := 'WSAEHOSTDOWN';
 WSAEHOSTUNREACH: Result := 'WSAEHOSTUNREACH';
 WSAENOTEMPTY: Result := 'WSAENOTEMPTY';
 WSAEPROCLIM: Result := 'WSAEPROCLIM';
 WSAEUSERS: Result := 'WSAEUSERS';
 WSAEDQUOT: Result := 'WSAEDQUOT';
 WSAESTALE: Result := 'WSAESTALE';
 WSAEREMOTE: Result := 'WSAEREMOTE';
 WSASYSNOTREADY: Result := 'WSASYSNOTREADY';
 WSAVERNOTSUPPORTED: Result := 'WSAVERNOTSUPPORTED';
 WSANOTINITIALISED: Result := 'WSANOTINITIALISED';
 WSAEDISCON: Result := 'WSAEDISCON';
 WSAHOST_NOT_FOUND: Result := 'WSAHOST_NOT_FOUND';
 WSATRY_AGAIN: Result := 'WSATRY_AGAIN';
 WSANO_RECOVERY: Result := 'WSANO_RECOVERY';
 WSANO_DATA: Result := 'WSANO_DATA';
 else
  Result := 'NO ERROR';
end;
{$ELSE}
 Result := strerror(E);
{$ENDIF}
end;

procedure NET_TransferRawData(var S: TSizeBuf; Data: Pointer; Size: UInt);
begin
Move(Data^, S.Data^, Size);
S.CurrentSize := Size;
end;

function NET_GetLoopPacket(Source: TNetSrc; var A: TNetAdr; var SB: TSizeBuf): Boolean;
var
 P: PLoopBack;
 I: Int;
begin
if Source > NS_SERVER then
 Result := False
else
 begin
  P := @Loopbacks[UInt(Source)];
  if P.Send - P.Get > MAX_LOOPBACK then
   P.Get := P.Send - MAX_LOOPBACK;

  if P.Get < P.Send then
   begin
    I := P.Get and (MAX_LOOPBACK - 1);
    Inc(P.Get);

    NET_TransferRawData(SB, @P.Msgs[I].Data, P.Msgs[I].Size);
    MemSet(A, SizeOf(A), 0);
    A.AddrType := NA_LOOPBACK;
    Result := True;
   end
  else
   Result := False;
 end;
end;

procedure NET_SendLoopPacket(Source: TNetSrc; Size: UInt; Buffer: Pointer);
var
 P: PLoopBack;
 I: Int;
begin
NET_ThreadLock;
P := @Loopbacks[UInt(Source) xor 1];
I := P.Send and (MAX_LOOPBACK - 1);
Inc(P.Send);
Move(Buffer^, P.Msgs[I].Data, Size);
P.Msgs[I].Size := Size;
NET_ThreadUnlock;
end;

procedure NET_RemoveFromPacketList(P: PLagPacket);
begin
P.Next.Prev := P.Prev;
P.Prev.Next := P.Next;
P.Prev := nil;
P.Next := nil;
end;

function NET_CountLaggedList(P: PLagPacket): Int;
var
 P2: PLagPacket;
begin
Result := 0;
if P <> nil then
 begin
  P2 := P.Prev;
  while (P2 <> nil) and (P2 <> P) do
   begin
    Inc(Result);
    P2 := P2.Prev;
   end;
 end;
end;

procedure NET_ClearLaggedList(P: PLagPacket);
var
 P2, P3: PLagPacket;
begin
P2 := P.Prev;
while (P2 <> nil) and (P2 <> P) do
 begin
  P3 := P2.Prev;
  NET_RemoveFromPacketList(P2);
  if P2.Data <> nil then
   Mem_FreeAndNil(P2.Data);
  Mem_Free(P2);
  P2 := P3;
 end;

P.Next := P;
P.Prev := P;
end;

procedure NET_AddToLagged(Source: TNetSrc; Base, New: PLagPacket; const A: TNetAdr; const SB: TSizeBuf; Time: Single);
begin
if (New.Prev <> nil) or (New.Next <> nil) then
 Print('NET_AddToLagged: Packet already linked.')
else
 begin
  New.Prev := Base;
  New.Next := Base.Next;
  Base.Next.Prev := New;
  Base.Next := New;

  New.Data := Mem_Alloc(SB.CurrentSize);
  New.Size := SB.CurrentSize;

  Move(SB.Data^, New.Data^, New.Size);
  New.Addr := A;
  New.Time := Time;
 end;
end;

procedure NET_AdjustLag;
var
 X, D, SD: Double;
begin
X := RealTime - LastLagTime;
if X < 0 then
 X := 0
else
 if X > 0.1 then
  X := 0.1;

LastLagTime := RealTime;
if not AllowCheats and (fakelag.Value <> 0) then
 begin
  Print('Server must enable cheats to activate fakelag.');
  CVar_DirectSet(fakelag, '0');
  FakeLagTime := 0;
 end
else
 if AllowCheats and (fakelag.Value <> FakeLagTime) then
  begin
   D := fakelag.Value - FakeLagTime;
   SD := X * 200;
   if Abs(D) < SD then
    SD := Abs(D);
   if D < 0 then
    SD := -SD;
   FakeLagTime := FakeLagTime + SD;
  end;
end;

function NET_LagPacket(Add: Boolean; Source: TNetSrc; A: PNetAdr; SB: PSizeBuf): Boolean;
var
 S: Single;
 P, P2: PLagPacket;
begin
if FakeLagTime <= 0 then
 begin
  NET_ClearLagData(True, True);
  Result := Add;
  Exit;
 end;

Result := False;

if Add then
 begin
  S := fakeloss.Value;
  if S <> 0 then
   if AllowCheats then
    begin
     Inc(LossCount[Source]);
     if S < 0 then
      begin
       S := Trunc(Abs(S));
       if S < 2 then
        S := 2;
       if (LossCount[Source] mod Trunc(S)) = 0 then
        Exit;
      end
     else
      if RandomLong(0, 100) <= Trunc(S) then
       Exit;
    end
   else
    CVar_DirectSet(fakeloss, '0');

  NET_AddToLagged(Source, @LagData[Source], Mem_ZeroAlloc(SizeOf(TLagPacket)), A^, SB^, RealTime);
 end;

P := LagData[Source].Prev;
P2 := @LagData[Source];

if P = P2 then
 Exit;

S := RealTime - FakeLagTime / 1000;
while P.Time > S do
 begin
  P := P.Prev;
  if P = P2 then
   Exit;
 end;

NET_RemoveFromPacketList(P);
if P.Data <> nil then
 NET_TransferRawData(InMessage, P.Data, P.Size);
Move(P.Addr, InFrom, SizeOf(InFrom));
if P.Data <> nil then
 Mem_Free(P.Data);
Mem_Free(P);
Result := True;
end;

procedure NET_FlushSocket(Source: TNetSrc);
var
 S: TSocket;
 FL: Int32;
 Buf: array[1..MAX_NETPACKETLEN] of Byte;
 A: TSockAddr;
begin
S := IPSockets[Source];
if S > 0 then
 begin
  FL := SizeOf(A);
  {$IFDEF MSWINDOWS}
  while recvfrom(S, Buf, SizeOf(Buf), 0, A, FL) > 0 do ;
  {$ELSE}
  while recvfrom(S, Buf, SizeOf(Buf), 0, @A, @FL) > 0 do ;
  {$ENDIF}
 end;
end;

function NET_GetLong(Data: Pointer; Size: UInt; PSize: PUInt32): Boolean;
var
 Header: TSplitHeader;
 CurSplit, MaxSplit: UInt;
 I: Int;
begin
Result := False;

Move(Data^, Header, SizeOf(Header));
CurSplit := Header.Index shr 4;
MaxSplit := Header.Index and $F;

if CurSplit >= MAX_SPLIT then
 DPrint(['Malformed split packet current number (', CurSplit, ').'])
else
 if MaxSplit > MAX_SPLIT then
  DPrint(['Malformed split packet max number (', MaxSplit, ').'])
 else
  begin
   if (SplitCtx.InSeq = OUTOFBAND_TAG) or (SplitCtx.InSeq <> Header.InSeq) then
    begin
     SplitCtx.InSeq := Header.InSeq;
     SplitCtx.TotalPackets := MaxSplit;
     if net_showpackets.Value = 4 then
      DPrint(['Restarting split packet context. Number of packets = ', MaxSplit, ', sequence = ', Header.InSeq, '.']);
    end;

   Dec(Size, SizeOf(Header));
   if SplitCtx.Sequences[CurSplit] = Header.InSeq then
    DPrint(['Ignoring duplicated split packet #', CurSplit + 1, ' of ', MaxSplit, ' (size = ', Size, ' bytes, sequence = ', Header.InSeq, ').'])
   else
    begin
     if CurSplit = MaxSplit - 1 then
      SplitCtx.RecvBytes := Size + (MaxSplit - 1) * MAX_SPLIT_FRAGLEN;

     Dec(SplitCtx.TotalPackets);
     SplitCtx.Sequences[CurSplit] := Header.InSeq;
     if net_showpackets.Value = 4 then
      Print(['Incoming split packet #', CurSplit + 1, ' of ', MaxSplit, ' (size = ', Size, ' bytes, sequence = ', Header.InSeq, ').']);

     if Size + MAX_SPLIT_FRAGLEN * CurSplit > MAX_NETPACKETLEN then
      begin
       DPrint(['Malformed split packet size (got ', Size, ' bytes, have ', MAX_SPLIT_FRAGLEN * CurSplit, ' bytes).']);
       Exit;
      end
     else
      Move(Pointer(UInt(Data) + SizeOf(Header))^, Pointer(UInt(@SplitCtx.Data) + MAX_SPLIT_FRAGLEN * CurSplit)^, Size);
    end;

   if SplitCtx.TotalPackets = 0 then // All packets were received.
    begin
     for I := 0 to MaxSplit - 1 do
      if SplitCtx.Sequences[I] <> SplitCtx.InSeq then
       begin
        DPrint(['Received a split packet without all ', MaxSplit, ' parts; part #', I + 1, ' had wrong sequence: ', SplitCtx.Sequences[I], ' (should be ', SplitCtx.InSeq, ').']);
        Exit;
       end;

     SplitCtx.InSeq := OUTOFBAND_TAG;
     if SplitCtx.RecvBytes <= MAX_NETPACKETLEN then
      begin
       Move(SplitCtx.Data, Data^, SplitCtx.RecvBytes);
       if PSize <> nil then
        PSize^ := SplitCtx.RecvBytes;
       Result := True;
      end
     else
      DPrint(['Received a split packet too large (', SplitCtx.RecvBytes, ' bytes, allowed no more than ', MAX_NETPACKETLEN, ').']);
    end;
  end;
end;

function NET_QueuePacket(Source: TNetSrc): Boolean;
var
 S: TSocket;
 Buf: array[1..MAX_NETPACKETLEN] of Byte;
 NetAdrBuf: array[1..64] of LChar;
 A: TSockAddr;
 FL: Int32;
 I, Size: UInt;
 E: Int;
begin
Size := 0;
for I := 1 to 2 do
 begin
  if I = 1 then
   S := IPSockets[Source]
  else
   S := IPXSockets[Source];
  
  if S > 0 then
   begin
    FL := 16;
    {$IFDEF MSWINDOWS}
    E := recvfrom(S, Buf, SizeOf(Buf), 0, A, FL);
    {$ELSE}
    E := recvfrom(S, Buf, SizeOf(Buf), 0, @A, @FL);
    {$ENDIF}
    if E = SOCKET_ERROR then
     begin
      E := NET_LastError;
      if E = {$IFDEF MSWINDOWS}WSAEMSGSIZE{$ELSE}EMSGSIZE{$ENDIF} then
       DPrint(['NET_QueuePacket: Ignoring oversized network message, allowed no more than ', MAX_NETPACKETLEN, ' bytes.'])
      else
       {$IFDEF MSWINDOWS}
       if (E <> WSAEWOULDBLOCK) and (E <> WSAECONNRESET) and (E <> WSAECONNREFUSED) then
       {$ELSE}
       if (E <> EAGAIN) and (E <> ECONNRESET) and (E <> ECONNREFUSED) then
       {$ENDIF}
        Print(['NET_QueuePacket: Network error "', NET_ErrorString(E), '".']);
     end
    else
     begin
      SockadrToNetadr(A, InFrom);
      if E >= SizeOf(Buf) then
       DPrint(['NET_QueuePacket: Oversized packet from ', NET_AdrToString(InFrom, NetAdrBuf, SizeOf(NetAdrBuf)), '.'])
      else
       begin
        Size := E;
        Break;
       end;
     end;
   end;

  if I = 2 then
   begin
    Result := NET_LagPacket(False, Source, nil, nil);
    Exit;
   end;
 end;

NET_TransferRawData(InMessage, @Buf, Size);
if PInt32(InMessage.Data)^ = SPLIT_TAG then
 if InMessage.CurrentSize >= SizeOf(TSplitHeader) then
  Result := NET_GetLong(InMessage.Data, Size, @InMessage.CurrentSize)
 else
  begin
   DPrint(['NET_QueuePacket: Invalid incoming split packet length (', InMessage.CurrentSize, ', should be no lesser than ', SizeOf(TSplitHeader), ').']);
   Result := False; 
  end
else
 Result := NET_LagPacket(True, Source, @InFrom, @InMessage);
end;

function NET_Sleep: Int;
var
 I: TNetSrc;
 FDSet: TFDSet;
 Num, S: TSocket;
 A: TTimeVal;
 P: PTimeVal;
begin
Num := 0;
FD_ZERO(FDSet);

for I := Low(I) to High(I) do
 begin
  S := IPSockets[I];
  if S > 0 then
   begin
    FD_SET(S, FDSet);
    if S > Num then
     Num := S;
   end;

  S := IPXSockets[I];
  if S > 0 then
   begin
    FD_SET(S, FDSet);
    if S > Num then
     Num := S;
   end;
 end;

if NetSleepForever then
 P := nil
else
 begin
  A.tv_sec := 0;
  A.tv_usec := 20000;
  P := @A;
 end;

Result := select(Num + 1, @FDSet, nil, nil, P);
end;

function ThreadProc(Parameter: Pointer): Int32;
var
 B: Boolean;
 I: TNetSrc;
 NewMsg, P: PNetQueue;
begin
while True do
 begin
  while NET_Sleep > 0 do
   begin
    B := True;
    for I := Low(I) to High(I) do
     begin
      NET_ThreadLock;
      if NET_QueuePacket(I) then
       begin
        B := False;
        NewMsg := NET_AllocMsg(InMessage.CurrentSize);
        Move(InMessage.Data^, NewMsg.Data^, InMessage.CurrentSize);
        Move(InFrom, NewMsg.Addr, SizeOf(NewMsg.Addr));
        NewMsg.Prev := nil;
        P := NetMessages[I];
        if P <> nil then
         begin
          while P.Prev <> nil do
           P := P.Prev;
          P.Prev := NewMsg;
         end
        else
         NetMessages[I] := NewMsg;
       end;
      NET_ThreadUnlock;
     end;
    
    if not B then
     Break;
   end;

  Sys_Sleep(1);
 end;

Result := 0;
EndThread(0);
end;

procedure NET_StartThread;
begin
if UseThread and not ThreadInit then
 begin
  Sys_InitCS(ThreadCS);
  ThreadHandle := BeginThread(nil, 0, @ThreadProc, nil, 0, ThreadID);
  if ThreadHandle = 0 then
   begin
    Sys_DeleteCS(ThreadCS);
    UseThread := False;
    Sys_Error('Couldn''t initialize network thread - run without -netthread.');
   end
  else
   ThreadInit := True;
 end;
end;

procedure NET_StopThread;
begin
if UseThread and ThreadInit then
 begin
  {$IFDEF MSWINDOWS}TerminateThread(ThreadHandle, 0){$ELSE}pthread_cancel(UInt(ThreadHandle)){$ENDIF};
  Sys_DeleteCS(ThreadCS);
  ThreadInit := False;
 end;
end;

var
 FirstNotice: Boolean = True;
 
function NET_AllocMsg(Size: UInt): PNetQueue;
var
 P: PNetQueue;
begin
if (Size <= NET_QUEUESIZE) and (NormalQueue <> nil) then
 begin
  Result := NormalQueue;
  Result.Size := Size;
  Result.Normal := True;
  NormalQueue := NormalQueue.Prev;
 end
else
 begin
  P := Mem_ZeroAlloc(SizeOf(P^));
  P.Data := Mem_ZeroAlloc(Size);
  P.Size := Size;
  P.Normal := False;
  Result := P;
 end;
end;

procedure NET_FreeMsg(P: PNetQueue);
begin
if P.Normal then
 begin
  P.Prev := NormalQueue;
  NormalQueue := P;
 end
else
 begin
  Mem_Free(P.Data);
  Mem_Free(P);
 end;
end;

function NET_GetPacket(Source: TNetSrc): Boolean;
var
 B: Boolean;
 P: PNetQueue;
begin
NET_AdjustLag;
NET_ThreadLock;
if NET_GetLoopPacket(Source, InFrom, InMessage) then
 B := NET_LagPacket(True, Source, @InFrom, @InMessage)
else
 if UseThread or not NET_QueuePacket(Source) then
  B := NET_LagPacket(False, Source, nil, nil)
 else
  B := True;

if B then
 begin
  NetMessage.CurrentSize := InMessage.CurrentSize;
  Move(InMessage.Data^, NetMessage.Data^, NetMessage.CurrentSize);
  Move(InFrom, NetFrom, SizeOf(NetFrom));
  Result := True;
 end
else
 begin
  P := NetMessages[Source];
  if P <> nil then
   begin
    NetMessages[Source] := P.Prev;
    NetMessage.CurrentSize := P.Size;
    Move(P.Data^, NetMessage.Data^, P.Size);
    Move(P.Addr, NetFrom, SizeOf(NetFrom));
    MSG_ReadCount := 0;
    NET_FreeMsg(P);
    Result := True;
   end
  else
   Result := False;
 end;

NET_ThreadUnlock;
end;

procedure NET_AllocateQueues;
var
 I: UInt;
 P: PNetQueue;
begin
for I := 1 to MAX_NET_QUEUES do
 begin
  P := Mem_ZeroAlloc(SizeOf(P^));
  P.Prev := NormalQueue;
  P.Normal := True;
  P.Data := Mem_ZeroAlloc(NET_QUEUESIZE);
  NormalQueue := P;
 end;

NET_StartThread;
end;

procedure NET_FlushQueues;
var
 I: TNetSrc;
 P, P2: PNetQueue;
begin
NET_StopThread;

for I := Low(I) to High(I) do
 begin
  P := NetMessages[I];
  while P <> nil do
   begin
    P2 := P.Prev;
    Mem_Free(P.Data);
    Mem_Free(P);
    P := P2;
   end;
  NetMessages[I] := nil;
 end;

P := NormalQueue;
while P <> nil do
 begin
  P2 := P.Prev;
  Mem_Free(P.Data);
  Mem_Free(P);
  P := P2;
 end;
NormalQueue := nil;
end;

function NET_SendLong(Source: TNetSrc; Socket: TSocket; Buffer: Pointer; Size: UInt; Flags: Int; var SockAddr: TSockAddr; SLength: UInt): Int;
var
 Buf: packed record
  Header: TSplitHeader;
  Data: array[0..MAX_SPLIT_FRAGLEN - 1] of Byte;
 end;
 CurSplit, MaxSplit, SentBytes, RemainingBytes, ThisBytes: UInt;
 I: Int;
 A: TNetAdr;
 AdrBuf: array[1..64] of LChar;
begin
if (Source <> NS_SERVER) or (Size <= MAX_FRAGLEN) then
 Result := sendto(Socket, Buffer^, Size, Flags, SockAddr, SLength)
else
 begin
  Inc(SendSeqNumber);
  if SendSeqNumber < 0 then
   SendSeqNumber := 1;
  Buf.Header.OutSeq := SPLIT_TAG;
  Buf.Header.InSeq := SendSeqNumber;

  CurSplit := 0;
  MaxSplit := (Size + MAX_SPLIT_FRAGLEN - 1) div MAX_SPLIT_FRAGLEN;

  SentBytes := 0;
  RemainingBytes := Size;
  while RemainingBytes > 0 do
   begin
    if RemainingBytes > MAX_SPLIT_FRAGLEN then
     ThisBytes := MAX_SPLIT_FRAGLEN
    else
     ThisBytes := RemainingBytes;

    Buf.Header.Index := MaxSplit or (CurSplit shl 4);
    Move(Buffer^, Buf.Data, ThisBytes);
    if net_showpackets.Value = 4 then
     begin
      SockadrToNetadr(SockAddr, A);
      DPrint(['Sending split packet #', CurSplit + 1, ' of ', MaxSplit, ' (size = ', ThisBytes, ' bytes, sequence = ', SendSeqNumber, ') to ', NET_AdrToString(A, AdrBuf, SizeOf(AdrBuf)), '.']);
     end;

    I := sendto(Socket, Buf, ThisBytes + SizeOf(Buf.Header), Flags, SockAddr, SLength);
    if I < 0 then
     begin
      Result := I;
      Exit;
     end;

    if UInt(I) >= ThisBytes then
     Inc(SentBytes, ThisBytes);

    Inc(CurSplit);
    Dec(RemainingBytes, ThisBytes);
    Inc(UInt(Buffer), ThisBytes);
   end;

  Result := SentBytes;
 end;
end;

procedure NET_SendPacket(Source: TNetSrc; Size: UInt; Buffer: Pointer; const Dest: TNetAdr);
var
 S: TSocket;
 A: TSockAddr;
 I: Int;
begin
S := 0;
case Dest.AddrType of
 NA_LOOPBACK:
  begin
   NET_SendLoopPacket(Source, Size, Buffer);
   Exit;
  end;
 NA_BROADCAST, NA_IP:
  S := IPSockets[Source];
 NA_IPX, NA_BROADCAST_IPX:
  S := IPXSockets[Source];
 else
  Sys_Error(['NET_SendPacket: Bad address type (', UInt(Dest.AddrType), ').']);
end;

if S > 0 then
 begin
  NetadrToSockadr(Dest, A);
  if NET_SendLong(Source, S, Buffer, Size, 0, A, SizeOf(A)) = SOCKET_ERROR then
   begin
    I := NET_LastError;
    {$IFDEF MSWINDOWS}
    if (I <> WSAEWOULDBLOCK) and (I <> WSAECONNREFUSED) and (I <> WSAECONNRESET) and
       ((I <> WSAEADDRNOTAVAIL) or ((Dest.AddrType <> NA_BROADCAST) and (Dest.AddrType <> NA_BROADCAST_IPX))) then
    {$ELSE}
    if (I <> EAGAIN) and (I <> ECONNREFUSED) and (I <> ECONNRESET) and
       ((I <> EADDRNOTAVAIL) or ((Dest.AddrType <> NA_BROADCAST) and (Dest.AddrType <> NA_BROADCAST_IPX))) then
    {$ENDIF}
     Print(['NET_SendPacket ERROR: ', NET_ErrorString(I)]);
   end;
 end;
end;

function NET_IPSocket(IP: PLChar; Port: UInt16; Reuse: Boolean): TSocket;
var
 S: TSocket;
 A: TSockAddr;
 I: Int32;
begin
Result := 0;
I := 1;
S := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
if S = INVALID_SOCKET then
 begin
  I := NET_LastError;
  if I <> {$IFDEF MSWINDOWS}WSAEAFNOSUPPORT{$ELSE}EAFNOSUPPORT{$ENDIF} then
   Print(['Warning: NET_IPSocket: Can''t allocate socket on port ', Port, ' - ', NET_ErrorString(I), '.']);
 end
else
 if {$IFDEF MSWINDOWS}ioctlsocket{$ELSE}ioctl{$ENDIF}(S, FIONBIO, I) = SOCKET_ERROR then
  Print(['Warning: NET_IPSocket: Can''t set non-blocking I/O for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
 else
  if setsockopt(S, SOL_SOCKET, SO_BROADCAST, @I, SizeOf(I)) = SOCKET_ERROR then
   Print(['Warning: NET_IPSocket: Can''t disable broadcast sending for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
  else
   if (Reuse or (COM_CheckParm('-reuse') > 0)) and (setsockopt(S, SOL_SOCKET, SO_REUSEADDR, @I, SizeOf(I)) = SOCKET_ERROR) then
    Print(['Warning: NET_IPSocket: Can''t allow local address reuse for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
   else
    begin
     if COM_CheckParm('-tos') > 0 then
      begin
       I := 16;
       Print('Enabling LOWDELAY TOS option.');
       if setsockopt(S, IPPROTO_IP, 1, @I, SizeOf(I)) = SOCKET_ERROR then
        begin
         Print(['Warning: NET_IPSocket: Can''t set LOWDELAY TOS for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.']);
         Exit;
        end;
      end;

     MemSet(A, SizeOf(A), 0);
     A.sin_family := AF_INET;
     if (IP <> nil) and (IP^ > #0) and (StrIComp(IP, 'localhost') <> 0) then
      NET_StringToSockaddr(IP, A);

     if Port < High(Port) then
      A.sin_port := Q_htons(Port);

     if bind(S, A, SizeOf(A)) = SOCKET_ERROR then
      begin
       Print(['Warning: NET_IPSocket: Can''t bind socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.']);
       {$IFDEF MSWINDOWS}closesocket(S){$ELSE}__close(S){$ENDIF};
      end
     else
      begin
       I := Int(COM_CheckParm('-loopback') > 0);
       if setsockopt(S, 0, IP_MULTICAST_LOOP, @I, SizeOf(I)) = SOCKET_ERROR then
        DPrint(['Warning: NET_IPSocket: Can''t set multicast loopback for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.']);
       Result := S;
      end;
    end;
end;

procedure NET_OpenIP;
var
 P: Single;
begin
NET_ThreadLock;
if IPSockets[NS_SERVER] = 0 then
 begin
  P := ip_hostport.Value;
  if P = 0 then
   begin
    P := hostport.Value;
    if P = 0 then
     begin
      CVar_SetValue('hostport', defport.Value);
      P := defport.Value;
     end;
   end;

  if Frac(P) <> 0 then
   Print('Warning: NET_OpenIP: Port value has float fraction, truncating.'); 

  IPSockets[NS_SERVER] := NET_IPSocket(ipname.Data, Trunc(P), False);
  if IPSockets[NS_SERVER] = 0 then
   Sys_Error(['Couldn''t allocate dedicated server IP on port ', Trunc(P), '.' + LineBreak +
              'Try using a different port by specifying either -port X or +hostport X in the commandline parameters.']);
 end;
NET_ThreadUnlock;
end;

function NET_IPXSocket(Port: UInt16): TSocket;
var
 S: TSocket;
 A: TSockAddr;
 I: Int32;
begin
Result := 0;
I := 1;
S := socket(AF_IPX, SOCK_DGRAM, 1000);
if S = INVALID_SOCKET then
 begin
  I := NET_LastError;
  if I <> {$IFDEF MSWINDOWS}WSAEAFNOSUPPORT{$ELSE}EAFNOSUPPORT{$ENDIF} then
   Print(['Warning: NET_IPXSocket: Can''t allocate socket on port ', Port, ' - ', NET_ErrorString(I), '.']);
 end
else
 if {$IFDEF MSWINDOWS}ioctlsocket{$ELSE}ioctl{$ENDIF}(S, FIONBIO, I) = SOCKET_ERROR then
  Print(['Warning: NET_IPXSocket: Can''t set non-blocking I/O for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
 else
  if setsockopt(S, SOL_SOCKET, SO_BROADCAST, @I, SizeOf(I)) = SOCKET_ERROR then
   Print(['Warning: NET_IPXSocket: Can''t disable broadcast sending for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
  else
   if setsockopt(S, SOL_SOCKET, SO_REUSEADDR, @I, SizeOf(I)) = SOCKET_ERROR then
    Print(['Warning: NET_IPXSocket: Can''t allow local address reuse for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
   else
    begin
     MemSet(A, SizeOf(A), 0);
     A.sin_family := AF_IPX;

     if Port < High(Port) then
      PUInt16(@A.sa_data[10])^ := Q_htons(Port);

     if bind(S, A, 14) = SOCKET_ERROR then
      begin
       Print(['Warning: NET_IPXSocket: Can''t bind socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.']);
       {$IFDEF MSWINDOWS}closesocket(S){$ELSE}__close(S){$ENDIF};
      end
     else
      Result := S;
    end;
end;

procedure NET_OpenIPX;
var
 P: Single;
begin
NET_ThreadLock;
if IPXSockets[NS_SERVER] = 0 then
 begin
  P := ipx_hostport.Value;
  if P = 0 then
   begin
    P := hostport.Value;
    if P = 0 then
     begin
      CVar_SetValue('hostport', defport.Value);
      P := defport.Value;
     end;
   end;

  if Frac(P) <> 0 then
   Print('Warning: NET_OpenIPX: Port value has float fraction, truncating.');
      
  IPXSockets[NS_SERVER] := NET_IPXSocket(Trunc(P));
 end;
NET_ThreadUnlock;
end;

procedure NET_GetLocalAddress;
var
 Buf: array[1..256] of LChar;
 AdrBuf: array[1..64] of LChar;
 NL: {$IFDEF MSWINDOWS}Int32{$ELSE}UInt32{$ENDIF};
 S: TSockAddr;
begin
MemSet(LocalIP, SizeOf(LocalIP), 0);
MemSet(LocalIPX, SizeOf(LocalIPX), 0);

if NoIP then
 Print('TCP/IP disabled.')
else
 begin
  if StrIComp(ipname.Data, 'localhost') <> 0 then
   StrLCopy(@Buf, ipname.Data, SizeOf(Buf) - 1)
  else
   gethostname(@Buf, SizeOf(Buf));
  Buf[High(Buf)] := #0;

  NET_StringToAdr(@Buf, LocalIP);
  NL := 16;
  if getsockname(IPSockets[NS_SERVER], S, NL) <> 0 then
   begin
    NoIP := True;
    Print(['Couldn''t get TCP/IP address, TCP/IP disabled.' + LineBreak +
          'Reason: ', NET_ErrorString(NET_LastError), '.']);
   end
  else
   begin
    LocalIP.Port := S.sin_port;
    Print(['Server IP address: ', NET_AdrToString(LocalIP, AdrBuf, SizeOf(AdrBuf)), '.']);
    CVar_DirectSet(net_address, @Buf);
   end;
 end;

if not NoIPX then
 begin
  NL := 14;
  if getsockname(IPXSockets[NS_SERVER], S, NL) <> 0 then
   NoIPX := True
  else
   begin
    SockadrToNetadr(S, LocalIPX);
    Print(['Server IPX address: ', NET_AdrToString(LocalIPX, AdrBuf, SizeOf(AdrBuf)), '.']);
   end;
 end;
end;

function NET_IsConfigured: Boolean;
begin
Result := NetConfigured;
end;

procedure NET_Config(EnableNetworking: Boolean);
var
 I: TNetSrc;
begin
if OldConfig <> EnableNetworking then
 begin
  OldConfig := EnableNetworking;
  if EnableNetworking then
   begin
    if not NoIP then
     NET_OpenIP;
    if not NoIPX then
     NET_OpenIPX;
    if FirstConfig then
     begin
      FirstConfig := False;
      NET_GetLocalAddress;
     end;

    NetConfigured := True;
   end
  else
   begin
    NET_ThreadLock;

    for I := Low(TNetSrc) to High(TNetSrc) do
     begin
      if IPSockets[I] > 0 then
       begin
        {$IFDEF MSWINDOWS}closesocket(IPSockets[I]);{$ELSE}__close(IPSockets[I]);{$ENDIF}
        IPSockets[I] := 0;
       end;
      if IPXSockets[I] > 0 then
       begin
        {$IFDEF MSWINDOWS}closesocket(IPXSockets[I]);{$ELSE}__close(IPXSockets[I]);{$ENDIF}
        IPXSockets[I] := 0;
       end;
     end;

    NET_ThreadUnlock;
    NetConfigured := False;
   end;
 end;
end;

procedure NET_Init;
var
 I: UInt;
 J: TNetSrc;
 P: PLagPacket;
begin
Cmd_AddCommand('maxplayers', @Cmd_Maxplayers_F);

CVar_RegisterVariable(clockwindow);

CVar_RegisterVariable(net_address);
CVar_RegisterVariable(ipname);
CVar_RegisterVariable(ip_hostport);
CVar_RegisterVariable(hostport);
CVar_RegisterVariable(defport);
CVar_RegisterVariable(ipx_hostport);
CVar_RegisterVariable(fakelag);
CVar_RegisterVariable(fakeloss);

UseThread := COM_CheckParm('-netthread') > 0;
NetSleepForever := COM_CheckParm('-netsleep') = 0;
NoIPX := COM_CheckParm('-noipx') > 0;
NoIP := COM_CheckParm('-noip') > 0;

I := COM_CheckParm('-port');
if I > 0 then
 CVar_DirectSet(hostport, COM_ParmValueByIndex(I));

I := COM_CheckParm('-clockwindow');
if I > 0 then
 CVar_DirectSet(clockwindow, COM_ParmValueByIndex(I));

NetMessage.Name := 'net_message';
NetMessage.AllowOverflow := [];
NetMessage.Data := @NetMsgBuffer;
NetMessage.MaxSize := SizeOf(NetMsgBuffer);
NetMessage.CurrentSize := 0;

InMessage.Name := 'in_message';
InMessage.AllowOverflow := [];
InMessage.Data := @InMsgBuffer;
InMessage.MaxSize := SizeOf(InMsgBuffer);
InMessage.CurrentSize := 0;

for J := Low(LagData) to High(LagData) do
 begin
  P := @LagData[J];
  P.Prev := P;
  P.Next := P;
 end;

NET_AllocateQueues;
DPrint('Base networking initialized.');
end;

procedure NET_ClearLagData(Client, Server: Boolean);
begin
NET_ThreadLock;
if Client then
 begin
  NET_ClearLaggedList(@LagData[NS_CLIENT]);
  NET_ClearLaggedList(@LagData[NS_MULTICAST]);
 end;
if Server then
 NET_ClearLaggedList(@LagData[NS_SERVER]);
NET_ThreadUnlock;
end;

procedure NET_Shutdown;
begin
NET_ThreadLock;
NET_ClearLaggedList(@LagData[NS_CLIENT]);
NET_ClearLaggedList(@LagData[NS_SERVER]);
NET_ThreadUnlock;
NET_Config(False);
NET_FlushQueues;
end;

function NET_JoinGroup(Source: TNetSrc; const A: TNetAdr): Boolean;
var
 Req: TIpMReq;
 E: Int;
begin
PUInt32(@Req.imr_multiaddr)^ := PUInt32(@A.IP)^;
PUInt32(@Req.imr_interface)^ := 0;

if setsockopt(IPSockets[Source], IPPROTO_IP, IP_ADD_MEMBERSHIP, @Req, SizeOf(Req)) = SOCKET_ERROR then
 begin
  E := NET_LastError;
  if E <> {$IFDEF MSWINDOWS}WSAEAFNOSUPPORT{$ELSE}EAFNOSUPPORT{$ENDIF} then
   Print(['Warning: NET_JoinGroup: IP_ADD_MEMBERSHIP: ', NET_ErrorString(E)]);
  Result := False;
 end
else
 Result := True;
end;

function NET_LeaveGroup(Source: TNetSrc; const A: TNetAdr): Boolean;
var
 Req: TIpMReq;
begin
PUInt32(@Req.imr_multiaddr)^ := PUInt32(@A.IP)^;
PUInt32(@Req.imr_interface)^ := 0;

Result := (setsockopt(IPSockets[Source], IPPROTO_IP, IP_ADD_MEMBERSHIP, @Req, SizeOf(Req)) <> SOCKET_ERROR) or
          (NET_LastError = {$IFDEF MSWINDOWS}WSAEAFNOSUPPORT{$ELSE}EAFNOSUPPORT{$ENDIF});
end;



procedure Netchan_OutOfBand(Source: TNetSrc; const Addr: TNetAdr; Size: UInt; Data: Pointer);
var
 SB: TSizeBuf;
 Buf: array[1..4040] of Byte;
begin
SB.Name := 'Netchan_OutOfBand';
SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
SB.Data := @Buf;
SB.MaxSize := SizeOf(Buf);
SB.CurrentSize := 0;

MSG_WriteLong(SB, OUTOFBAND_TAG);
SZ_Write(SB, Data, Size);
NET_SendPacket(Source, SB.CurrentSize, SB.Data, Addr);
end;

procedure Netchan_UnlinkFragment(Frag: PFragBuf; var Base: PFragBuf);
var
 P: PFragBuf;
begin
if Base = nil then
 Print('Netchan_UnlinkFragment: Asked to unlink fragment from empty list, ignored.')
else
 if Frag = Base then
  begin
   Base := Frag.Next;
   Mem_Free(Frag);
  end
 else
  begin
   P := Base;
   while P.Next <> nil do
    if P.Next = Frag then
     begin
      P.Next := Frag.Next;
      Mem_Free(Frag);
      Exit;
     end
    else
     P := P.Next;

   Print('Netchan_UnlinkFragment: Couldn''t find fragment.');
  end;
end;

procedure Netchan_OutOfBandPrint(Source: TNetSrc; const Addr: TNetAdr; S: PLChar);
begin
Netchan_OutOfBand(Source, Addr, StrLen(S) + 1, S);
end;

procedure Netchan_OutOfBandPrint(Source: TNetSrc; const Addr: TNetAdr; const S: array of const);
begin
Netchan_OutOfBandPrint(Source, Addr, PLChar(StringFromVarRec(S)));
end;

procedure Netchan_ClearFragBufs(var P: PFragBuf);
var
 P2, P3: PFragBuf;
begin
P2 := P;
while P2 <> nil do
 begin
  P3 := P2.Next;
  Mem_Free(P2);
  P2 := P3;
 end;

P := nil;
end;

procedure Netchan_ClearFragments(var C: TNetchan);
var
 I: UInt;
 P, P2: PFragBufDir;
begin
for I := 1 to 2 do
 begin
  P := C.FragBufDirs[I];
  while P <> nil do
   begin
    P2 := P.Next;
    Netchan_ClearFragBufs(P.FragBuf);
    Mem_Free(P);
    P := P2;
   end;
  C.FragBufDirs[I] := nil;

  Netchan_ClearFragBufs(C.FragBufBase[I]);
  Netchan_FlushIncoming(C, I);
 end;
end;

procedure Netchan_Clear(var C: TNetchan);
var
 I: UInt;
begin
Netchan_ClearFragments(C);
if C.ReliableLength > 0 then
 begin
  DPrint(['Netchan_Clear: Reliable length = ', C.ReliableLength, '; incoming reliable acknowledged = ', C.IncomingReliableAcknowledged, '.']);
  C.ReliableLength := 0;
  C.ReliableSequence := C.ReliableSequence xor 1;
 end;

C.ClearTime := 0;

for I := 1 to 2 do
 begin
  C.FragBufSequence[I] := 0;
  C.FragBufActive[I] := False;
  C.FragBufSplitCount[I] := 0;
  C.FragBufOffset[I] := 0;
  C.FragBufSize[I] := 0;
  C.IncomingActive[I] := False;
 end;

if C.TempBuffer <> nil then
 Mem_FreeAndNil(C.TempBuffer);
C.TempBufferSize := 0;
end;

procedure Netchan_Setup(Source: TNetSrc; var C: TNetchan; const Addr: TNetAdr; ClientID: Int; ClientPtr: PClient; Func: TFragmentSizeFunc);
begin
Netchan_Clear(C);
MemSet(C, SizeOf(C), 0);
C.Source := Source;
C.Addr := Addr;
C.ClientIndex := ClientID + 1;
C.FirstReceived := RealTime;
C.LastReceived := RealTime;
C.Rate := 9999;
C.OutgoingSequence := 1;
C.Client := ClientPtr;
C.FragmentFunc := @Func;

C.NetMessage.Name := 'netchan->message';
C.NetMessage.AllowOverflow := [FSB_ALLOWOVERFLOW];
C.NetMessage.Data := @C.NetMessageBuf;
C.NetMessage.MaxSize := SizeOf(C.NetMessageBuf);
end;

function Netchan_CanPacket(var C: TNetchan): Boolean;
begin
if (net_chokeloop.Value <> 0) or (C.Addr.AddrType <> NA_LOOPBACK) then
 Result := C.ClearTime < RealTime
else
 begin
  C.ClearTime := RealTime;
  Result := True;
 end;
end;

procedure Netchan_UpdateFlow(var C: TNetchan);
var
 Seq: Int32;
 I, J, BytesTotal: UInt;
 F: PNetchanFlowData;
 FS: PNetchanFlowStats;
 PrevTime, Time: Double;
begin
if @C = nil then
 Exit;

BytesTotal := 0;
Time := 0;

for I := 1 to 2 do
 begin
  F := @C.Flow[I];
  if RealTime - F.UpdateTime >= 0.1 then
   begin
    F.UpdateTime := RealTime + 0.1;
    FS := @F.Stats[(F.InSeq - 1) and High(F.Stats)];
    Seq := F.InSeq - 2;
    for J := High(F.Stats) downto Low(F.Stats) + 1 do
     begin
      PrevTime := FS.TimeWindow;
      FS := @F.Stats[Seq and High(F.Stats)];
      Inc(BytesTotal, FS.Bytes);
      Dec(Seq);
      Time := Time + (PrevTime - FS.TimeWindow);
     end;                   

    if Time = 0 then
     F.KBRate := 0
    else
     F.KBRate := BytesTotal / Time / 1024;

    F.KBAvgRate := F.KBAvgRate * (2 / 3) + F.KBRate * (1 / 3);
   end;
 end;
end;

procedure Netchan_Transmit(var C: TNetchan; Size: UInt; Buffer: Pointer);
var
 SB: TSizeBuf;
 SBData: array[1..MAX_LOOPBACK_PACKETLEN] of Byte;
 NetAdrBuf: array[1..64] of Byte;
 FileNameBuf: array[1..MAX_PATH_W] of LChar;
 Reliable, HasPendingNetMsg, HasPendingAny, B, B2: Boolean;
 I, FS: UInt;
 HasPendingData: array[1..2] of Boolean;
 FB: PFragBuf;
 F: TFile;
 Seq, Seq2: Int;
 FP: PNetchanFlowStats;
 Rate: Double;
begin
SB.Name := 'Netchan_Transmit';
SB.AllowOverflow := [];
SB.Data := @SBData;
SB.MaxSize := SizeOf(SBData) - 3;
SB.CurrentSize := 0;

if FSB_OVERFLOWED in C.NetMessage.AllowOverflow then
 Print([NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ': Outgoing message overflow.'])
else
 begin
  Reliable := (C.IncomingAcknowledged > C.LastReliableSequence) and
                  (C.IncomingReliableAcknowledged <> C.ReliableSequence);
  B2 := Reliable;

  if C.ReliableLength = 0 then
   begin
    Netchan_FragSend(C);
    for I := 1 to 2 do
     HasPendingData[I] := C.FragBufBase[I] <> nil;

    HasPendingNetMsg := C.NetMessage.CurrentSize <> 0;
    if HasPendingNetMsg and HasPendingData[1] then
     begin
      HasPendingNetMsg := False;
      if C.NetMessage.CurrentSize > 1200 then
       begin
        Netchan_CreateFragments(C, C.NetMessage);
        C.NetMessage.CurrentSize := 0;
       end;
     end;

    HasPendingAny := False;
    for I := 1 to 2 do
     begin
      C.FragBufOffset[I] := 0;
      C.FragBufActive[I] := False;
      C.FragBufSequence[I] := 0;
      C.FragBufSize[I] := 0;
      if HasPendingData[I] then
       HasPendingAny := True;
     end;

    if HasPendingNetMsg or HasPendingAny then
     begin
      C.ReliableSequence := C.ReliableSequence xor 1;
      Reliable := True;
     end;

    if HasPendingNetMsg then
     begin
      Move(C.NetMessageBuf, C.ReliableBuf, C.NetMessage.CurrentSize);
      C.ReliableLength := C.NetMessage.CurrentSize;
      C.NetMessage.CurrentSize := 0;
      for I := 1 to 2 do
       C.FragBufOffset[I] := C.ReliableLength;
     end;

    for I := 1 to 2 do
     begin
      FB := C.FragBufBase[I];
      if FB <> nil then
       if FB.B1 and not FB.B2 then
        FS := FB.FragmentSize
       else
        FS := FB.FragMessage.CurrentSize
      else
       FS := 0;

      if HasPendingData[I] and (FB <> nil) and (FS + C.ReliableLength < 1200) then
       begin
        C.FragBufSequence[I] := (FB.Index shl 16) or (C.FragBufSplitCount[I] and $FFFF);
        if FB.B1 and not FB.B2 then
         begin
          if FB.Compressed then
           begin
            StrLCopy(@FileNameBuf, @FB.FileName, SizeOf(FileNameBuf) - 1);
            StrLCat(@FileNameBuf, '.ztmp', SizeOf(FileNameBuf) - 1);
            B := FS_Open(F, @FileNameBuf, 'r');
           end
          else
           B := FS_Open(F, @FB.FileName, 'r');

          if not B then
           Sys_Error(['Netchan_Transmit: Couldn''t open "', PLChar(@FB.FileName), '".']);

          FS_Seek(F, FB.FileOffset, SEEK_SET);
          FS_Read(F, Pointer(UInt(FB.FragMessage.Data) + FB.FragMessage.CurrentSize), FB.FragmentSize);
          Inc(FB.FragMessage.CurrentSize, FB.FragmentSize);
          FS_Close(F);
         end;

        Move(FB.FragMessage.Data^, Pointer(UInt(@C.ReliableBuf) + C.ReliableLength)^, FB.FragMessage.CurrentSize);
        Inc(C.ReliableLength, FB.FragMessage.CurrentSize);
        C.FragBufSize[I] := FB.FragMessage.CurrentSize;
        Netchan_UnlinkFragment(FB, C.FragBufBase[I]);
        if I = 1 then
         Inc(C.FragBufOffset[2], C.FragBufSize[1]); // look it up

        C.FragBufActive[I] := True;
       end;
     end;
   end;

  // Fragbufs are in order now. This is the outermost level.
  B := False;
  for I := 1 to 2 do
   if C.FragBufActive[I] then
    begin
     B := True;
     Break;
    end;

  Seq := C.OutgoingSequence or (Int(Reliable) shl 31);
  Seq2 := C.IncomingSequence or (C.IncomingReliableSequence shl 31);
  if Reliable and B then
   Seq := Seq or $40000000;

  Inc(C.OutgoingSequence);
  MSG_WriteLong(SB, Seq);
  MSG_WriteLong(SB, Seq2);
  
  if Reliable then
   begin
    if B then
     for I := 1 to 2 do
      if C.FragBufActive[I] then
       begin
        MSG_WriteByte(SB, 1);
        MSG_WriteLong(SB, C.FragBufSequence[I]);
        MSG_WriteShort(SB, C.FragBufOffset[I]);
        MSG_WriteShort(SB, C.FragBufSize[I]);
       end
      else
       MSG_WriteByte(SB, 0);

    SZ_Write(SB, @C.ReliableBuf, C.ReliableLength);
    C.LastReliableSequence := C.OutgoingSequence - 1;
   end;

  if not B2 then
   I := SB.MaxSize
  else
   I := MAX_FRAGLEN;

  if (SB.CurrentSize > I) or (I - SB.CurrentSize < Size) then
   DPrint('Netchan_Transmit: Unreliable message would overflow, ignoring.')
  else
   if (Buffer <> nil) and (Size > 0) then
    SZ_Write(SB, Buffer, Size);

  for I := SB.CurrentSize to 15 do
   MSG_WriteByte(SB, SVC_NOP);

  FP := @C.Flow[1].Stats[C.Flow[1].InSeq and High(C.Flow[1].Stats)];
  FP.Bytes := SB.CurrentSize + UDP_OVERHEAD;
  FP.TimeWindow := RealTime;
  Inc(C.Flow[1].InSeq);
  Netchan_UpdateFlow(C);

  Netchan_CompressPacket(@SB);
  COM_Munge2(Pointer(UInt(SB.Data) + 8), SB.CurrentSize - 8, (C.OutgoingSequence - 1) and $FF);
  NET_SendPacket(C.Source, SB.CurrentSize, SB.Data, C.Addr);

  if SV.Active and (sv_lan.Value <> 0) and (sv_lan_rate.Value > 1000) then
   Rate := 1 / sv_lan_rate.Value
  else
   Rate := 1 / C.Rate;

  if C.ClearTime < RealTime then
   C.ClearTime := RealTime;

  C.ClearTime := C.ClearTime + (SB.CurrentSize + UDP_OVERHEAD) * Rate;

  if (net_showpackets.Value <> 0) and (net_showpackets.Value <> 2) then
   Print([' s --> sz=', SB.CurrentSize, ' seq=', C.OutgoingSequence - 1, ' ack=', C.IncomingSequence, ' rel=',
          Int(Reliable), ' tm=', SV.Time]);
 end;
end;

function Netchan_FindBufferByID(var Base: PFragBuf; Index: UInt32; Alloc: Boolean): PFragBuf;
var
 P: PFragBuf;
begin
P := Base;
while P <> nil do
 if P.Index = Index then
  begin
   Result := P;
   Exit;
  end
 else
  P := P.Next;

if Alloc then
 begin
  P := Mem_ZeroAlloc(SizeOf(P^));
  P.Index := Index;
  P.FragMessage.Name := 'Frag Buffer';
  P.FragMessage.AllowOverflow := [FSB_ALLOWOVERFLOW];
  P.FragMessage.Data := @P.Data;
  P.FragMessage.MaxSize := SizeOf(P.Data);
  P.FragMessage.CurrentSize := 0;
  Netchan_AddBufferToList(Base, P);
  Result := P;
 end
else
 Result := nil;
end;

procedure Netchan_CheckForCompletion(var C: TNetchan; Index, Total: UInt);
var
 P: PFragBuf;
 I: UInt;
begin
P := C.IncomingBuf[Index];
I := 0;

if P <> nil then
 begin
  repeat
   Inc(I);
   P := P.Next;
  until P = nil;
  
  if I = Total then
   C.IncomingActive[Index] := True;
 end;
end;

function Netchan_Validate(var C: TNetchan; Frag: PBoolArray; Seq: PInt32Array; Offset, Size: PInt16Array): Boolean;
var
 I: UInt;
 Index, SplitCount: Int16;
begin
for I := Low(BoolArray) to Low(BoolArray) + 1 do
 if Frag[I] then
  begin
   Index := Seq[I] shr 16;
   SplitCount := Seq[I] and $FFFF;
   Result := (Index >= 0) and (Index <= 25000) and (SplitCount >= 0) and (SplitCount <= 25000) and
             (Size[I] >= 0) and (Size[I] <= 2048) and (Offset[I] >= 0) and (Offset[I] <= 16384);
   if not Result then
    Exit;
  end;

Result := True;
end;

function Netchan_Process(var C: TNetchan): Boolean;
var
 Seq, Ack: Int32;
 I: UInt;
 Rel, Validate, RelAck, Security: Boolean;
 A1: array[1..2] of Boolean;
 A2: array[1..2] of UInt32;
 A3, A4: array[1..2] of UInt16;
 NetAdrBuf: array[1..64] of LChar;
 FP: PNetchanFlowStats;
 FB: PFragBuf;
begin
Result := False;

if not NET_CompareAdr(NetFrom, C.Addr) then
 Exit;

C.LastReceived := RealTime;
MSG_BeginReading;

Seq := MSG_ReadLong;
Ack := MSG_ReadLong;

Rel := (Seq and $80000000) > 0;
Validate := (Seq and $40000000) > 0;
RelAck := (Ack and $80000000) > 0;
Security := (Ack and $40000000) > 0;

if Security or MSG_BadRead then
 Exit;

COM_UnMunge2(Pointer(UInt(NetMessage.Data) + 8), NetMessage.CurrentSize - 8, Seq and $FF);
Netchan_DecompressPacket(@NetMessage);
if Validate then
 begin
  for I := 1 to 2 do
   if MSG_ReadByte > 0 then
    begin
     A1[I] := True;
     A2[I] := MSG_ReadLong;
     A3[I] := MSG_ReadShort;
     A4[I] := MSG_ReadShort;
    end
   else
    begin
     A1[I] := False;
     A2[I] := 0;
     A3[I] := 0;
     A4[I] := 0;
    end;

  if not Netchan_Validate(C, @A1, @A2, @A3, @A4) then
   Exit;
 end;

Seq := Seq and $3FFFFFFF;
Ack := Ack and $3FFFFFFF;

if (net_showpackets.Value <> 0) and (net_showpackets.Value <> 3) then
 Print([' s <-- sz=', NetMessage.CurrentSize, ' seq=', Seq, ' ack=', Ack, ' rel=',
        Int(Rel), ' tm=', SV.Time]);

if Seq > C.IncomingSequence then
 begin
  NetDrop := Seq - C.IncomingSequence - 1;
  if (NetDrop > 0) and (net_showdrop.Value <> 0) then
   Print([NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ': Dropped ', NetDrop, ' packets at ', Seq, '.']);

  if (Int(RelAck) = C.ReliableSequence) and (C.IncomingAcknowledged + 1 >= C.LastReliableSequence) then
   C.ReliableLength := 0;

  C.IncomingSequence := Seq;
  C.IncomingAcknowledged := Ack;
  C.IncomingReliableAcknowledged := Int(RelAck);
  if Rel then
   C.IncomingReliableSequence := C.IncomingReliableSequence xor 1;

  FP := @C.Flow[2].Stats[C.Flow[2].InSeq and High(C.Flow[2].Stats)];
  FP.Bytes := NetMessage.CurrentSize + UDP_OVERHEAD;
  FP.TimeWindow := RealTime;
  Inc(C.Flow[2].InSeq);
  Netchan_UpdateFlow(C);

  if Validate then
   begin
    for I := 1 to 2 do
     if A1[I] then
      begin
       if A2[I] > 0 then
        begin
         FB := Netchan_FindBufferByID(C.IncomingBuf[I], A2[I], True);
         if FB <> nil then
          begin
           SZ_Clear(FB.FragMessage);
           // Check this line for something like A3 is 16384
           SZ_Write(FB.FragMessage, Pointer(UInt(NetMessage.Data) + MSG_ReadCount + A3[I]), A4[I]);
           if FSB_OVERFLOWED in FB.FragMessage.AllowOverflow then
            begin
             Include(C.NetMessage.AllowOverflow, FSB_OVERFLOWED);
             Exit;
            end;
          end
         else
          Print(['Netchan_Process: Couldn''t allocate or find buffer ', A2[I] shr 16, '.']);
         Netchan_CheckForCompletion(C, I, A2[I] and $FFFF);
        end;

       Move(Pointer(UInt(NetMessage.Data) + MSG_ReadCount + A3[I] + A4[I])^,
            Pointer(UInt(NetMessage.Data) + MSG_ReadCount + A3[I])^,
            NetMessage.CurrentSize - A4[I] - A3[I] - MSG_ReadCount);

       Dec(NetMessage.CurrentSize, A4[I]);
       if I = 1 then
        Dec(A3[2], A4[1]);
      end;
    if NetMessage.CurrentSize > 16 then
     Result := True;
   end
  else
   Result := True;
 end
else
 if net_showdrop.Value <> 0 then
  if Seq = C.IncomingSequence then
   Print([NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ': Duplicate packet ', Seq, ' at ', C.IncomingSequence, '.'])
  else
   Print([NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ': Out of order packet ', Seq, ' at ', C.IncomingSequence, '.'])
end;

procedure Netchan_FragSend(var C: TNetchan);
var
 I: UInt;
 P: PFragBufDir;
begin
for I := 1 to 2 do
 if (C.FragBufDirs[I] <> nil) and (C.FragBufBase[I] = nil) then
  begin
   P := C.FragBufDirs[I];
   C.FragBufDirs[I] := P.Next;
   P.Next := nil;

   C.FragBufBase[I] := P.FragBuf;
   C.FragBufSplitCount[I] := P.Count;
   Mem_Free(P);
  end;
end;

procedure Netchan_AddBufferToList(var Base: PFragBuf; P: PFragBuf);
var
 P2: PFragBuf;
begin
P.Next := nil;
if @Base <> nil then
 if Base = nil then
  Base := P
 else
  begin
   P2 := Base;
   while P2.Next <> nil do
    if ((P2.Next.Index shr 16) and $FFFF) > ((P.Index shr 16) and $FFFF) then
     begin
      P.Next := P2.Next.Next;
      P2.Next := P;
      Exit;
     end
    else
     P2 := P2.Next;

   P2.Next := P;
 end;
end;

function Netchan_AllocFragBuf: PFragBuf;
var
 P: PFragBuf;
begin
P := Mem_ZeroAlloc(SizeOf(P^));
P.FragMessage.Name := 'Frag Buffer Alloc''d';
P.FragMessage.Data := @P.Data;
P.FragMessage.MaxSize := SizeOf(P.Data);
Result := P;
end;

procedure Netchan_AddFragBufToTail(Dir: PFragBufDir; P: PFragBuf);
var
 P2: PFragBuf;
begin
P.Next := nil;
Inc(Dir.Count);

P2 := Dir.FragBuf;
if P2 <> nil then
 begin
  while P2.Next <> nil do
   P2 := P2.Next;
  P2.Next := P;
 end
else
 Dir.FragBuf := P;
end;

procedure Netchan_CreateFragments_(var C: TNetchan; var SB: TSizeBuf);
var
 Buf: packed record
  Tag: UInt32;
  Data: array[1..65536] of Byte;
 end;
 DstLen, ClientFragSize, ThisSize, RemainingSize, FragIndex, DataOffset: UInt;
 Dir, P: PFragBufDir;
 FB: PFragBuf;
begin
if SB.CurrentSize = 0 then
 Exit;

if (net_compress.Value = 1) or (net_compress.Value = 3) then
 begin
  DstLen := SizeOf(Buf.Data);
  Buf.Tag := BZIP2_TAG;
  if BZ2_bzBuffToBuffCompress(@Buf.Data, @DstLen, SB.Data, SB.CurrentSize, 9, 0, 30) = BZ_OK then
   begin
    Inc(DstLen, SizeOf(Buf.Tag));
    DPrint(['Compressing split packet (', SB.CurrentSize, ' -> ', DstLen, ' bytes).']);
    Move(Buf, SB.Data^, DstLen);
    SB.CurrentSize := DstLen;
   end;
 end;

if (@C.FragmentFunc <> nil) and (C.Client <> nil) then
 ClientFragSize := C.FragmentFunc(C.Client)
else
 ClientFragSize := 1024;

Dir := Mem_ZeroAlloc(SizeOf(Dir^));
FragIndex := 1;
DataOffset := 0;

RemainingSize := SB.CurrentSize;
while RemainingSize > 0 do
 begin
  if RemainingSize < ClientFragSize then
   ThisSize := RemainingSize
  else
   ThisSize := ClientFragSize;

  FB := Netchan_AllocFragBuf;
  if FB = nil then
   begin
    Print('Couldn''t allocate fragment buffer.');
    Netchan_ClearFragBufs(Dir.FragBuf);
    Mem_Free(Dir);

    SV_DropClient(HostClient^, False, 'Memory allocation problem on the server.');
    Exit;
   end;

  FB.Index := FragIndex;
  Inc(FragIndex);
  SZ_Clear(FB.FragMessage);

  SZ_Write(FB.FragMessage, Pointer(UInt(SB.Data) + DataOffset), ThisSize);
  Inc(DataOffset, ThisSize);
  Dec(RemainingSize, ThisSize);

  Netchan_AddFragBufToTail(Dir, FB);
 end;

if C.FragBufDirs[1] <> nil then
 begin
  P := C.FragBufDirs[1];
  while P.Next <> nil do
   P := P.Next;
  P.Next := Dir;
 end
else
 C.FragBufDirs[1] := Dir;
end;

procedure Netchan_CreateFragments(var C: TNetchan; var SB: TSizeBuf);
begin
if C.NetMessage.CurrentSize > 0 then
 begin
  Netchan_CreateFragments_(C, C.NetMessage);
  C.NetMessage.CurrentSize := 0;
 end;

Netchan_CreateFragments_(C, SB);
end;

procedure Netchan_CreateFileFragmentsFromBuffer(var C: TNetchan; Name: PLChar; Buffer: Pointer; Size: UInt);
var
 Compressed, NeedHeader: Boolean;
 DstBuf: Pointer;
 DstLen, ClientFragSize, FragIndex, ThisSize, FileOffset, RemainingSize, HeaderOverhead: UInt;
 Dir, P: PFragBufDir;
 FB: PFragBuf;
begin
if Size = 0 then
 Exit;

if (net_compress.Value = 2) or (net_compress.Value = 3) then
 begin
  DstBuf := Mem_Alloc(Size);
  DstLen := Size;
  if (DstBuf = nil) or (BZ2_bzBuffToBuffCompress(DstBuf, @DstLen, Buffer, Size, 9, 0, 30) <> BZ_OK) then
   begin
    Compressed := False;
    if DstBuf <> nil then
     Mem_Free(DstBuf);
   end
  else
   begin
    Compressed := True;
    Buffer := DstBuf;
    Size := DstLen;
    DPrint(['Compressed "', Name, '" for transmission (', Size, ' -> ', DstLen, ').']);
   end;
 end
else
 Compressed := False;

if (@C.FragmentFunc <> nil) and (C.Client <> nil) then
 ClientFragSize := C.FragmentFunc(C.Client)
else
 ClientFragSize := 1024;

Dir := Mem_ZeroAlloc(SizeOf(Dir^));
FragIndex := 1;
NeedHeader := True;
FileOffset := 0;

RemainingSize := Size;
while RemainingSize > 0 do
 begin
  if RemainingSize < ClientFragSize then
   ThisSize := RemainingSize
  else
   ThisSize := ClientFragSize;

  FB := Netchan_AllocFragBuf;
  if FB = nil then
   begin
    Print('Couldn''t allocate fragment buffer.');
    Netchan_ClearFragBufs(Dir.FragBuf);
    Mem_Free(Dir);

    if Compressed then
     Mem_Free(Buffer);

    SV_DropClient(HostClient^, False, 'Memory allocation problem on the server.');
    Exit;
   end;

  FB.Index := FragIndex;
  Inc(FragIndex);
  SZ_Clear(FB.FragMessage);

  if NeedHeader then
   begin
    NeedHeader := False;
    MSG_WriteString(FB.FragMessage, Name);
    if Compressed then
     MSG_WriteString(FB.FragMessage, 'bz2')
    else
     MSG_WriteString(FB.FragMessage, 'uncompressed');

    MSG_WriteLong(FB.FragMessage, Size);
    HeaderOverhead := FB.FragMessage.CurrentSize;
   end
  else
   HeaderOverhead := 0;

  if ThisSize > HeaderOverhead then
   Dec(ThisSize, HeaderOverhead);

  FB.FragmentSize := ThisSize;
  FB.FileOffset := FileOffset;
  FB.B1 := True;
  FB.B2 := True;

  MSG_WriteBuffer(FB.FragMessage, ThisSize, Pointer(UInt(Buffer) + FileOffset));
  Inc(FileOffset, ThisSize);
  Dec(RemainingSize, ThisSize);
  
  Netchan_AddFragBufToTail(Dir, FB);
 end;

if C.FragBufDirs[2] <> nil then
 begin
  P := C.FragBufDirs[2];
  while P.Next <> nil do
   P := P.Next;
  P.Next := Dir;
 end
else
 C.FragBufDirs[2] := Dir;

if Compressed then
 Mem_Free(Buffer);
end;

function Netchan_CreateFileFragments(Server: Boolean; C: PNetchan; Name: PLChar): Boolean;
var
 FileNameBuf: array[1..MAX_PATH_W] of LChar;
 NetAdrBuf: array[1..64] of LChar;
 Compressed, NeedHeader: Boolean;
 F: TFile;
 SrcP, DstP: Pointer;
 FileSizeC, FileSizeUC, DL, FuncFragSize, FragIndex, ThisFragSize, TotalSize: UInt;
 Dir, P: PFragBufDir;
 FB: PFragBuf;
begin
Result := False;
Compressed := False;
StrLCopy(@FileNameBuf, Name, SizeOf(FileNameBuf) - 1);
StrLCat(@FileNameBuf, '.ztmp', SizeOf(FileNameBuf) - 1);

if FS_Open(F, @FileNameBuf, 'r') and (FS_GetFileTime(@FileNameBuf) >= FS_GetFileTime(Name)) then
 begin
  FileSizeC := FS_Size(F);
  FS_Close(F);
  Compressed := True;

  if not FS_Open(F, Name, 'r') then
   begin
    Print(['Warning: Unable to open "', Name, '" for transfer.']);
    Exit;
   end;

  FileSizeUC := FS_Size(F);
  if FileSizeUC > sv_filetransfermaxsize.Value then
   begin
    Print(['Warning: File "', Name, '" is too big to transfer from host ', NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), '.']);
    Exit;
   end;

  FS_Close(F);
 end
else
 begin
  if not FS_Open(F, Name, 'r') then
   begin
    Print(['Warning: Unable to open "', Name, '" for transfer.']);
    Exit;
   end;

  FileSizeC := FS_Size(F);
  FileSizeUC := FileSizeC;

  if FileSizeUC > sv_filetransfermaxsize.Value then
   begin
    Print(['Warning: File "', Name, '" is too big to transfer from host ', NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), '.']);
    Exit;
   end;

  if (sv_filetransfercompression.Value <> 0) or (net_compress.Value = 2) or (net_compress.Value = 3) then
   begin
    SrcP := Mem_Alloc(FileSizeUC);
    if FS_Read(F, SrcP, FileSizeUC) <> FileSizeUC then
     begin
      Print(['Warning: File read error in "', Name, '".']);
      Mem_Free(SrcP);
      FS_Close(F);
      Exit;
     end;

    DstP := Mem_Alloc(FileSizeUC);
    DL := FileSizeUC;
    if BZ2_bzBuffToBuffCompress(DstP, @DL, SrcP, FileSizeUC, 9, 0, 30) = BZ_OK then
     begin
      FS_Close(F);

      if FS_Open(F, @FileNameBuf, 'wo') then
       begin
        DPrint(['Creating compressed version of file "', Name, '" (', FileSizeUC, ' -> ', DL, ').']);
        FS_Write(F, DstP, DL);
        FS_Close(F);
        FileSizeC := DL;
        Compressed := True;
       end;
     end;
    Mem_Free(DstP);
    Mem_Free(SrcP);     
   end
  else
   FS_Close(F);
 end;

FuncFragSize := C.FragmentFunc(C.Client);
Dir := Mem_ZeroAlloc(SizeOf(Dir^));
FragIndex := 1;
NeedHeader := True;
TotalSize := 0;

while FileSizeC > 0 do
 begin
  ThisFragSize := FileSizeC;
  if ThisFragSize >= FuncFragSize then
   ThisFragSize := FuncFragSize;

  FB := Netchan_AllocFragBuf;
  if FB = nil then
   begin
    Print('Couldn''t allocate fragment buffer.');
    Mem_Free(Dir);
    if Server then
     SV_DropClient(HostClient^, False, 'MAlloc problem.');
    Exit;
   end;

  FB.Index := FragIndex;
  Inc(FragIndex);
  SZ_Clear(FB.FragMessage);

  if NeedHeader then
   begin
    NeedHeader := False;
    MSG_WriteString(FB.FragMessage, Name);
    if Compressed then
     MSG_WriteString(FB.FragMessage, 'bz2')
    else
     MSG_WriteString(FB.FragMessage, 'uncompressed');

    MSG_WriteLong(FB.FragMessage, FileSizeUC);
    Dec(ThisFragSize, FB.FragMessage.CurrentSize);
   end;

  FB.B1 := True;
  FB.Compressed := True;
  FB.FileOffset := TotalSize;
  FB.FragmentSize := ThisFragSize;
  StrLCopy(@FB.FileName, Name, MAX_PATH_A - 1);
  FB.FileName[High(FB.FileName)] := #0;

  Inc(TotalSize, ThisFragSize);
  if FileSizeC > ThisFragSize then
   Dec(FileSizeC, ThisFragSize)
  else
   FileSizeC := 0;

  Netchan_AddFragBufToTail(Dir, FB);
 end;

if C.FragBufDirs[2] <> nil then
 begin
  P := C.FragBufDirs[2];
  while P.Next <> nil do
   P := P.Next;
  P.Next := Dir;
 end
else
 C.FragBufDirs[2] := Dir;

Result := True;
end;

procedure Netchan_FlushIncoming(var C: TNetchan; Index: UInt);
var
 P, P2: PFragBuf;
begin
SZ_Clear(NetMessage);
MSG_ReadCount := 0;

P := C.IncomingBuf[Index];
while P <> nil do
 begin
  P2 := P.Next;
  Mem_Free(P);
  P := P2;
 end;

C.IncomingBuf[Index] := nil;
C.IncomingActive[Index] := False;
end;

function Netchan_CopyNormalFragments(var C: TNetchan): Boolean;
var
 P, P2: PFragBuf;
 DL: UInt;
 Buf: array[1..65536] of Byte;
begin
Result := False;

if C.IncomingActive[1] then
 if C.IncomingBuf[1] <> nil then
  begin
   SZ_Clear(NetMessage);
   MSG_BeginReading;

   P := C.IncomingBuf[1];
   while P <> nil do
    begin
     P2 := P.Next;
     SZ_Write(NetMessage, P.FragMessage.Data, P.FragMessage.CurrentSize);
     Mem_Free(P);
     P := P2;
    end;

   if PUInt32(NetMessage.Data)^ = BZIP2_TAG then
    begin
     DL := SizeOf(Buf);
     if BZ2_bzBuffToBuffDecompress(@Buf, @DL, Pointer(UInt(NetMessage.Data) + SizeOf(UInt32)), NetMessage.CurrentSize - SizeOf(UInt32), 1, 0) = BZ_OK then
      begin
       Move(Buf, NetMessage.Data^, DL);
       NetMessage.CurrentSize := DL;
      end
     else
      NetMessage.CurrentSize := 0;
    end;

   C.IncomingBuf[1] := nil;
   C.IncomingActive[1] := False;
   Result := True;
  end
 else
  begin
   Print('Netchan_CopyNormalFragments: Called with no fragments readied.');
   C.IncomingActive[1] := False;
  end;
end;

function Netchan_CopyFileFragments(var C: TNetchan): Boolean;
var
 P, P2: PFragBuf;
 IncomingSize, TotalSize, CurrentSize: UInt;
 FileName: array[1..MAX_PATH_A] of LChar;
 Compressed: Boolean;
 Src, Data: Pointer;
begin
Result := False;

if C.IncomingActive[2] then
 if C.IncomingBuf[2] = nil then
  begin
   Print('Netchan_CopyFileFragments: Called with no fragments readied.');
   C.IncomingActive[2] := False;
  end
 else
  begin
   P := C.IncomingBuf[2];

   SZ_Clear(NetMessage);
   MSG_BeginReading;
   if P.FragMessage.CurrentSize > 0 then
    SZ_Write(NetMessage, P.FragMessage.Data, P.FragMessage.CurrentSize);
   
   StrLCopy(@FileName, MSG_ReadString, SizeOf(FileName) - 1);
   Compressed := StrIComp(MSG_ReadString, 'bz2') = 0;
   IncomingSize := MSG_ReadLong;

   if MSG_BadRead then
    begin
     Print('File fragment received with invalid header.' + LineBreak + 'Flushing input queue.');
     Netchan_FlushIncoming(C, 2);
    end
   else
    if FileName[1] = #0 then
     begin
      Print('File fragment received with no filename.' + LineBreak + 'Flushing input queue.');
      Netchan_FlushIncoming(C, 2);
     end
    else
     if not IsSafeFile(@FileName) then
      begin
       Print('File fragment received with unsafe path, ignoring.' + LineBreak + 'Flushing input queue.');
       Netchan_FlushIncoming(C, 2);
      end
     else
      begin
       StrLCopy(@C.FileName, @FileName, SizeOf(C.FileName) - 1);

       if FileName[1] <> '!' then
        begin
         if sv_receivedecalsonly.Value <> 0 then
          begin
           Print(['Received a non-decal file "', PLChar(@FileName), '", ignored.']);
           Netchan_FlushIncoming(C, 2);
           Exit;
          end;

         if FS_FileExists(@FileName) then
          begin
           Print(['Can''t download "', PLChar(@FileName), '", already exists.']);
           Netchan_FlushIncoming(C, 2);
           Result := True;
           Exit;
          end;

         COM_CreatePath(@FileName);
        end;

       TotalSize := 0;
       while P <> nil do
        begin
         Inc(TotalSize, P.FragMessage.CurrentSize);
         if P = C.IncomingBuf[2] then
          Dec(TotalSize, MSG_ReadCount);
         P := P.Next;
        end;

       Src := Mem_ZeroAlloc(TotalSize + 1);
       if Src = nil then
        begin
         Print(['Buffer allocation failed on ', TotalSize + 1, ' bytes.']);
         Netchan_FlushIncoming(C, 2);
         Exit;
        end;

       P := C.IncomingBuf[2];
       CurrentSize := 0;
       while P <> nil do
        begin
         P2 := P.Next;
         if P = C.IncomingBuf[2] then
          begin
           Dec(P.FragMessage.CurrentSize, MSG_ReadCount);
           Data := Pointer(UInt(P.FragMessage.Data) + MSG_ReadCount);
          end
         else
          Data := P.FragMessage.Data;

         Move(Data^, Pointer(UInt(Src) + CurrentSize)^, P.FragMessage.CurrentSize);
         Inc(CurrentSize, P.FragMessage.CurrentSize);
         Mem_Free(P);
         P := P2;
        end;

       if Compressed then
        if IncomingSize >= sv_filereceivemaxsize.Value then
         begin
          Print(['Incoming decompressed size for file "', PLChar(@C.FileName), '" is too big, ignoring.']);
          C.IncomingBuf[2] := nil;
          C.IncomingActive[2] := False;
          Netchan_FlushIncoming(C, 2);
          Mem_Free(Src);
          Exit;
         end
        else
         begin
          Data := Mem_Alloc(IncomingSize + 1);
          DPrint(['Decompressing file "', PLChar(@FileName), '" (', TotalSize, ' -> ', IncomingSize, ').']);
          if BZ2_bzBuffToBuffDecompress(Data, @IncomingSize, Src, TotalSize, 1, 0) <> BZ_OK then
           begin
            Print(['Decompression failed for incoming file "', PLChar(@C.FileName), '".']);
            C.IncomingBuf[2] := nil;
            C.IncomingActive[2] := False;
            Netchan_FlushIncoming(C, 2);
            Mem_Free(Src);
            Mem_Free(Data);
            Exit;
           end
          else
           begin
            Mem_Free(Src);
            TotalSize := IncomingSize;
            Src := Data;
           end;
         end;

       if FileName[1] = '!' then
        begin
         if C.TempBuffer <> nil then
          begin
           DPrint('Netchan_CopyFileFragments: Freeing holdover tempbuffer.');
           Mem_Free(C.TempBuffer);
          end;

         C.TempBuffer := Src;
         C.TempBufferSize := TotalSize;
        end
       else
        begin
         COM_WriteFile(@FileName, Src, TotalSize);
         Mem_Free(Src);
        end;

       SZ_Clear(NetMessage);
       MSG_ReadCount := 0;
       C.IncomingBuf[2] := nil;
       C.IncomingActive[2] := False;
       Result := True;
      end;
  end;
end;

function Netchan_IsSending(const C: TNetchan): Boolean;
begin
Result := (C.FragBufBase[1] <> nil) or (C.FragBufBase[2] <> nil);
end;

function Netchan_IsReceiving(const C: TNetchan): Boolean;
begin
Result := (C.IncomingBuf[1] <> nil) or (C.IncomingBuf[2] <> nil);
end;

function Netchan_IncomingReady(const C: TNetchan): Boolean;
begin
Result := C.IncomingActive[1] or C.IncomingActive[2];
end;

procedure Netchan_Init;
begin
CVar_RegisterVariable(net_log);
CVar_RegisterVariable(net_showpackets);
CVar_RegisterVariable(net_showdrop);
CVar_RegisterVariable(net_chokeloop);
CVar_RegisterVariable(sv_filetransfercompression);
CVar_RegisterVariable(sv_filetransfermaxsize);
CVar_RegisterVariable(sv_filereceivemaxsize);
CVar_RegisterVariable(sv_receivedecalsonly);

CVar_RegisterVariable(net_compress);
end;

function Netchan_CompressPacket(SB: PSizeBuf): Int;
begin
Result := 0;
end;

function Netchan_DecompressPacket(SB: PSizeBuf): Int;
begin
Result := 0;
end;

{$IFDEF MSWINDOWS}
var
 WSA: TWSAData;

initialization
 WSAStartup($202, WSA);

finalization
 WSACleanup;
{$ENDIF}
                    
end.
