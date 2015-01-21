unit Network;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS} Windows, Winsock, {$ELSE} Libc, KernelIoctl, {$ENDIF} Default, SDK;

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

function Netchan_CreateFileFragments(var C: TNetchan; Name: PLChar): Boolean;

procedure Netchan_FlushIncoming(var C: TNetchan; Index: UInt);

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

 LocalIP: TNetAdr;

 clockwindow: TCVar = (Name: 'clockwindow'; Data: '0.5');

 NetDrop: UInt32 = 0; // amount of dropped incoming packets

implementation

uses BZip2, Common, Console, FileSys, Memory, MsgBuf, Host, HostCmds, Resource, Server, SVClient, SysArgs, SysMain;

const
 IPTOS_LOWDELAY = 16;
 SD_RECEIVE = 0;
 SD_SEND = 1;
 SD_BOTH = 2;
 INADDR_NONE = -1;

var
 OldConfig: Boolean = False;

 FirstInit: Boolean = True;
 NetInit: Boolean = False;

 IPSockets: array[TNetSrc] of TSocket;

 InMsgBuffer, NetMsgBuffer: array[1..NETMSG_SIZE] of Byte;

 // cvars
 net_address: TCVar = (Name: 'net_address'; Data: '');
 ipname: TCVar = (Name: 'ip'; Data: 'localhost');
 ip_hostport: TCVar = (Name: 'ip_hostport'; Data: '0');
 hostport: TCVar = (Name: 'hostport'; Data: '0');
 defport: TCVar = (Name: 'port'; Data: '27015');

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

 SplitCtx: array[0..MAX_SPLIT_CTX - 1] of TSplitContext;
 CurrentCtx: UInt = Low(SplitCtx);

 SplitSeq: Int32 = 1; // outgoing split sequence

 // netchan stuff
 net_showpackets: TCVar = (Name: 'net_showpackets'; Data: '0');
 net_showdrop: TCVar = (Name: 'net_showdrop'; Data: '0');
 net_chokeloop: TCVar = (Name: 'net_chokeloop'; Data: '0');
 sv_filetransfercompression: TCVar = (Name: 'sv_filetransfercompression'; Data: '1');
 sv_filetransfermaxsize: TCVar = (Name: 'sv_filetransfermaxsize'; Data: '20000000');
 sv_filereceivemaxsize: TCVar = (Name: 'sv_filereceivemaxsize'; Data: '1000000');
 sv_receivedecalsonly: TCVar = (Name: 'sv_receivedecalsonly'; Data: '1');

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

function ntohs(I: UInt16): UInt16;
begin
Result := (I shl 8) or (I shr 8);
end;

function htons(I: UInt16): UInt16;
begin
Result := (I shl 8) or (I shr 8);
end;

procedure NetadrToSockadr(const A: TNetAdr; out S: TSockAddr);
begin
case A.AddrType of
 NA_BROADCAST:
  begin
   S.sin_family := AF_INET;
   S.sin_port := A.Port;
   Int32(S.sin_addr.S_addr) := -1;
   MemSet(S.sin_zero, SizeOf(S.sin_zero), 0);
  end;
 NA_IP:
  begin
   S.sin_family := AF_INET;
   S.sin_port := A.Port;
   Int32(S.sin_addr.S_addr) := PInt32(@A.IP)^;
   MemSet(S.sin_zero, SizeOf(S.sin_zero), 0);
  end;
 else
  MemSet(S, SizeOf(S), 0);
end;  
end;

procedure SockadrToNetadr(const S: TSockAddr; out A: TNetAdr);
begin
if S.sa_family = AF_INET then
 begin
  A.AddrType := NA_IP;
  PInt32(@A.IP)^ := Int32(S.sin_addr.S_addr);
  A.Port := S.sin_port;
 end
else
 MemSet(A, SizeOf(A), 0);
end;

function NET_CompareAdr(const A1, A2: TNetAdr): Boolean;
begin
if A1.AddrType <> A2.AddrType then
 Result := False
else
 case A1.AddrType of
  NA_LOOPBACK: Result := True;
  NA_IP: Result := (PUInt32(@A1.IP)^ = PUInt32(@A2.IP)^) and (A1.Port = A2.Port);
  else Result := False;
 end;
end;

function NET_CompareClassBAdr(const A1, A2: TNetAdr): Boolean;
begin
if A1.AddrType <> A2.AddrType then
 Result := False
else
 case A1.AddrType of
  NA_LOOPBACK: Result := True;
  NA_IP: Result := PUInt16(@A1.IP)^ = PUInt16(@A2.IP)^;
  else Result := False;
 end;
end;

// RFC 1918: 192.168/16
function NET_IsReservedAdr(const A: TNetAdr): Boolean;
begin
case A.AddrType of
 NA_LOOPBACK: Result := True;
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
  NA_IP: Result := PUInt32(@A1.IP)^ = PUInt32(@A2.IP)^;
  else Result := False;
 end;
end;

function NET_AdrToString(const A: TNetAdr; out Buf; L: UInt): PLChar; overload;
var
 I: Int;
 S: PLChar;
 AdrBuf: array[1..64] of LChar;
begin
if (@Buf = nil) or (L = 0) then
 Result := nil
else
 begin
  case A.AddrType of
   NA_LOOPBACK: StrLCopy(@Buf, 'loopback', L - 1);
   NA_IP, NA_BROADCAST:
    begin
     S := @AdrBuf;

     for I := 1 to 4 do
      begin
       S := IntToStrE(A.IP[I], S^, 4);
       S^ := '.';
       Inc(UInt(S));
      end;

     PLChar(UInt(S) - 1)^ := ':';
     IntToStr(ntohs(A.Port), S^, 6);
     StrLCopy(@Buf, @AdrBuf, L - 1);
    end;
   else StrLCopy(@Buf, '(bad address)', L - 1);
  end;

  Result := @Buf;
 end;
end;

function NET_BaseAdrToString(const A: TNetAdr; out Buf; L: UInt): PLChar;
var
 I: Int;
 S: PLChar;
 AdrBuf: array[1..64] of LChar;
begin
if (@Buf = nil) or (L = 0) then
 Result := nil
else
 begin
  case A.AddrType of
   NA_LOOPBACK: StrLCopy(@Buf, 'loopback', L - 1);
   NA_IP, NA_BROADCAST:
    begin
     S := @AdrBuf;

     for I := 1 to 4 do
      begin
       S := IntToStrE(A.IP[I], S^, 4);
       S^ := '.';
       Inc(UInt(S));
      end;

     PLChar(UInt(S) - 1)^ := #0;
     StrLCopy(@Buf, @AdrBuf, L - 1);
    end;
   else StrLCopy(@Buf, '(bad address)', L - 1);
  end;

  Result := @Buf;
 end;
end;

function NET_StringToSockaddr(Name: PLChar; out S: TSockAddr): Boolean;
var
 Buf: array[1..1024] of LChar;
 S2: PLChar;
 I: Int32;
 E: PHostEnt;
begin
Result := True;

S.sin_family := AF_INET;
MemSet(S.sin_zero, SizeOf(S.sin_zero), 0);

StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
S2 := StrPos(@Buf, ':');
if S2 <> nil then
 begin
  S2^ := #0;
  S.sin_port := StrToInt(PLChar(UInt(S2) + 1));
  if S.sin_port <> 0 then
   S.sin_port := htons(S.sin_port);
 end
else
 S.sin_port := 0;

I := inet_addr(@Buf);
if I = INADDR_NONE then
 begin
  E := gethostbyname(@Buf);
  if (E = nil) or (E.h_addr_list = nil) or (E.h_addr_list^ = nil) then
   begin
    S.sin_addr.S_addr := 0;
    Result := False;
   end
  else
   I := PInt32(E.h_addr_list^)^;
 end;

S.sin_addr.S_addr := I;
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
P.Next := nil;
P.Prev := nil;
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
   Mem_Free(P2.Data);
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
if not AllowCheats and (fakelag.Value <> 0) then
 begin
  Print('Server must enable cheats to activate fakelag.');
  CVar_DirectSet(fakelag, '0');
  FakeLagTime := 0;
 end
else
 if AllowCheats and (fakelag.Value <> FakeLagTime) then
  begin
   X := RealTime - LastLagTime;
   if X < 0 then
    X := 0
   else
    if X > 0.1 then
     X := 0.1;

   LastLagTime := RealTime;

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
  NET_ClearLagData(False, True);
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
 AddrLen: Int32;
 Buf: array[1..MAX_NETPACKETLEN] of Byte;
 A: TSockAddr;
begin
S := IPSockets[Source];
if S > 0 then
 begin
  AddrLen := SizeOf(A);
  {$IFDEF MSWINDOWS}
  while recvfrom(S, Buf, SizeOf(Buf), 0, A, AddrLen) > 0 do ;
  {$ELSE}
  while recvfrom(S, Buf, SizeOf(Buf), 0, @A, @AddrLen) > 0 do ;
  {$ENDIF}
 end;
end;

function NET_FindSplitContext(const Addr: TNetAdr): PSplitContext;
var
 I, J, Index: UInt;
 P: PSplitContext; 
 MinTime: Double;
begin
MinTime := RealTime;
Index := 0;

for I := 0 to MAX_SPLIT_CTX - 1 do
 begin
  J := (CurrentCtx - I) and (MAX_SPLIT_CTX - 1);
  P := @SplitCtx[J];
  if NET_CompareAdr(P.Addr, Addr) then
   begin
    Result := P;
    Exit;
   end
  else
   if P.Time < MinTime then
    begin
     MinTime := P.Time;
     Index := J;
    end;
 end;

P := @SplitCtx[Index];
P.Addr := Addr;
P.PacketsLeft := -1;
CurrentCtx := Index;
Result := P;
end;

procedure NET_ClearSplitContexts;
var
 I: UInt;
 P: PSplitContext;
begin
for I := 0 to MAX_SPLIT_CTX - 1 do
 begin
  P := @SplitCtx[I];
  MemSet(P.Addr, SizeOf(P.Addr), 0);
  P.Time := 0;
 end;
end;

function NET_GetLong(Data: Pointer; Size: UInt; var OutSize: UInt32; const Addr: TNetAdr): Boolean;
var
 Header: TSplitHeader;
 CurSplit, MaxSplit: UInt;
 P: PSplitContext;
 I: Int;
begin
Result := False;

Move(Data^, Header, SizeOf(Header));
CurSplit := Header.Index shr 4;
MaxSplit := Header.Index and $F;

if CurSplit >= MAX_SPLIT then
 DPrint(['Malformed split packet current number (', CurSplit, ').'])
else
 if (MaxSplit > MAX_SPLIT) or (MaxSplit = 0) then
  DPrint(['Malformed split packet max number (', MaxSplit, ').'])
 else
  begin
   P := NET_FindSplitContext(Addr);
   if (P.PacketsLeft < 1) or (P.Sequence <> Header.SplitSeq) then
    begin
     if net_showpackets.Value = 4 then
      if P.PacketsLeft = -1 then
       DPrint(['New split context with ', MaxSplit, ' packets, sequence = ', Header.SplitSeq, '.'])
      else
       DPrint(['Restarting split context with ', MaxSplit, ' packets, sequence = ', Header.SplitSeq, '.']);

     P.Time := RealTime;
     P.PacketsLeft := MaxSplit;
     P.Sequence := Header.SplitSeq;
     P.Size := 0;
     P.Ack := [];
    end
   else
    if net_showpackets.Value = 4 then
     DPrint(['Found existing split context with ', MaxSplit, ' packets, sequence = ', Header.SplitSeq, '.']);

   Dec(Size, SizeOf(Header));
   if CurSplit in P.Ack then
    DPrint(['Received duplicated split fragment (num = ', CurSplit + 1, '/', MaxSplit, ', sequence = ', Header.SplitSeq, '), ignoring.'])
   else
    if P.Size + Size > MAX_NETPACKETLEN then
     DPrint(['Split context overflowed with ', P.Size + Size, ' bytes (num = ', CurSplit + 1, '/', MaxSplit, ', sequence = ', Header.SplitSeq, ').'])
    else
     begin
      if net_showpackets.Value = 4 then
       DPrint(['Received split fragment (num = ', CurSplit + 1, '/', MaxSplit, ', sequence = ', Header.SplitSeq, ').']);

      Dec(P.PacketsLeft);
      Include(P.Ack, CurSplit);
      Move(Pointer(UInt(Data) + SizeOf(Header))^, Pointer(UInt(@P.Data) + P.Size)^, Size);
      Inc(P.Size, Size);

      if P.PacketsLeft = 0 then
       begin
        for I := 0 to MaxSplit - 1 do
         if not (I in P.Ack) then
          begin
           DPrint(['Received a split packet without all ', MaxSplit, ' parts; sequence = ', Header.SplitSeq, ', ignoring.']);
           Exit;
          end;

        DPrint(['Received a split packet with sequence = ', Header.SplitSeq, '.']);

        Move(P.Data, Data^, P.Size);
        OutSize := P.Size;

        MemSet(P.Addr, SizeOf(P.Addr), 0);
        P.Time := 0;
        Result := True;
       end;
     end;
  end;
end;

function NET_QueuePacket(Source: TNetSrc): Boolean;
var
 S: TSocket;
 Buf: array[1..MAX_NETPACKETLEN] of Byte;
 NetAdrBuf: array[1..64] of LChar;
 A: TSockAddr;
 AddrLen: Int32;
 Size: UInt;
 E: Int;
begin
S := IPSockets[Source];
if S > 0 then
 begin
  AddrLen := SizeOf(TSockAddr);
  {$IFDEF MSWINDOWS}
  E := recvfrom(S, Buf, SizeOf(Buf), 0, A, AddrLen);
  {$ELSE}
  E := recvfrom(S, Buf, SizeOf(Buf), 0, @A, @AddrLen);
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
    if E > SizeOf(Buf) then
     DPrint(['NET_QueuePacket: Oversized packet from ', NET_AdrToString(InFrom, NetAdrBuf, SizeOf(NetAdrBuf)), '.'])
    else
     begin
      Size := E;
      NET_TransferRawData(InMessage, @Buf, Size);
      if PInt32(InMessage.Data)^ = SPLIT_TAG then
       if InMessage.CurrentSize >= SizeOf(TSplitHeader) then
        Result := NET_GetLong(InMessage.Data, Size, InMessage.CurrentSize, InFrom)
       else
        begin
         DPrint(['NET_QueuePacket: Invalid incoming split packet length (', InMessage.CurrentSize, '), should be no lesser than ', SizeOf(TSplitHeader), '.']);
         Result := NET_LagPacket(False, Source, nil, nil);
        end
      else
       Result := NET_LagPacket(True, Source, @InFrom, @InMessage);

      Exit;
     end;
   end;
 end;

Result := NET_LagPacket(False, Source, nil, nil);
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

  Sys_Sleep(0);
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
 
function NET_AllocMsg(Size: UInt): PNetQueue;
var
 P: PNetQueue;
begin
if (Size <= NET_QUEUESIZE) and (NormalQueue <> nil) then
 begin
  P := NormalQueue;
  P.Size := Size;
  P.Normal := True;
  NormalQueue := P.Prev;
 end
else
 begin
  P := Mem_ZeroAlloc(SizeOf(P^));
  P.Data := Mem_ZeroAlloc(Size);
  P.Size := Size;
  P.Normal := False;
 end;

Result := P;
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
    Move(P.Data^, NetMessage.Data^, NetMessage.CurrentSize);
    Move(P.Addr, NetFrom, SizeOf(NetFrom));
    NET_FreeMsg(P);
    Result := True;
   end
  else
   Result := False;
 end;

NET_ThreadUnlock;
end;

function NET_SendLong(Source: TNetSrc; Socket: TSocket; Buffer: Pointer; Size: UInt; const NetAdr: TNetAdr; var SockAddr: TSockAddr; AddrLength: UInt): Int;
var
 Buf: packed record
  Header: TSplitHeader;
  Data: array[0..MAX_SPLIT_FRAGLEN - 1] of Byte;
 end;
 CurSplit, MaxSplit, SentBytes, RemainingBytes, ThisBytes: UInt;
 E: Int;
 ShowPackets: Boolean;
 AdrBuf: array[1..64] of LChar;
begin
if (Size <= MAX_FRAGLEN) or (Source <> NS_SERVER) then
 Result := sendto(Socket, Buffer^, Size, 0, SockAddr, AddrLength)
else
 begin
  MaxSplit := (Size + MAX_SPLIT_FRAGLEN - 1) div MAX_SPLIT_FRAGLEN;
  if MaxSplit > MAX_SPLIT then
   begin
    DPrint(['Refusing to send split packet to ', NET_AdrToString(NetAdr, AdrBuf, SizeOf(AdrBuf)), ', the packet is too big (', Size, ' bytes).']);
    Result := 0;    
   end
  else
   begin
    Inc(SplitSeq);
    if SplitSeq < 0 then
     SplitSeq := 1;
    Buf.Header.Seq := SPLIT_TAG;
    Buf.Header.SplitSeq := SplitSeq;

    CurSplit := 0;
    SentBytes := 0;
    ShowPackets := net_showpackets.Value = 4;
    RemainingBytes := Size;
    while RemainingBytes > 0 do
     begin
      if RemainingBytes > MAX_SPLIT_FRAGLEN then
       ThisBytes := MAX_SPLIT_FRAGLEN
      else
       ThisBytes := RemainingBytes;

      Buf.Header.Index := MaxSplit or (CurSplit shl 4);
      Move(Buffer^, Buf.Data, ThisBytes);
      if ShowPackets then
       DPrint(['Sending split packet #', CurSplit + 1, ' of ', MaxSplit, ' (size = ', ThisBytes, ' bytes, sequence = ', SplitSeq, ') to ', NET_AdrToString(NetAdr, AdrBuf, SizeOf(AdrBuf)), '.']);

      E := sendto(Socket, Buf, SizeOf(TSplitHeader) + ThisBytes, 0, SockAddr, AddrLength);
      if E < 0 then
       begin
        Result := E;
        Exit;
       end
      else
       begin
        Inc(SentBytes, E);
        Inc(CurSplit);
        Dec(RemainingBytes, ThisBytes);
        Inc(UInt(Buffer), ThisBytes);
       end;
     end;
     
    Result := SentBytes;
   end;
 end;
end;

procedure NET_SendPacket(Source: TNetSrc; Size: UInt; Buffer: Pointer; const Dest: TNetAdr);
var
 AddrType: TNetAdrType;
 S: TSocket;
 A: TSockAddr;
 E: Int;
begin
AddrType := Dest.AddrType;
if (AddrType = NA_BROADCAST) or (AddrType = NA_IP) then
 begin
  S := IPSockets[Source];
  if S > 0 then
   begin
    NetadrToSockadr(Dest, A);
    if NET_SendLong(Source, S, Buffer, Size, Dest, A, SizeOf(A)) = SOCKET_ERROR then
     begin
      E := NET_LastError;
      {$IFDEF MSWINDOWS}
      if (E <> WSAEWOULDBLOCK) and (E <> WSAECONNREFUSED) and (E <> WSAECONNRESET) and
         ((E <> WSAEADDRNOTAVAIL) or (Dest.AddrType <> NA_BROADCAST)) then
      {$ELSE}
      if (E <> EAGAIN) and (E <> ECONNREFUSED) and (E <> ECONNRESET) and
         ((E <> EADDRNOTAVAIL) or (Dest.AddrType <> NA_BROADCAST)) then
      {$ENDIF}
       Print(['NET_SendPacket: Network error "', NET_ErrorString(E), '".']);
     end;
   end;
 end
else
 if AddrType = NA_LOOPBACK then
  NET_SendLoopPacket(Source, Size, Buffer)
 else
  Sys_Error(['NET_SendPacket: Bad address type (', UInt(AddrType), ').']);
end;

function NET_IPSocket(IP: PLChar; Port: UInt16; Reuse: Boolean): TSocket;
var
 S: TSocket;
 A: TSockAddr;
 I: Int32;
 E: Int;
begin
S := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
if S = INVALID_SOCKET then
 begin
  E := NET_LastError;
  if E <> {$IFDEF MSWINDOWS}WSAEAFNOSUPPORT{$ELSE}EAFNOSUPPORT{$ENDIF} then
   Print(['Error: Can''t allocate socket on port ', Port, ' - ', NET_ErrorString(E), '.']);
 end
else
 begin
  I := 1;
  if {$IFDEF MSWINDOWS}ioctlsocket{$ELSE}ioctl{$ENDIF}(S, FIONBIO, I) = SOCKET_ERROR then
   Print(['Error: Can''t set non-blocking I/O for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
  else
   begin
    I := 1;
    if setsockopt(S, SOL_SOCKET, SO_BROADCAST, @I, SizeOf(I)) = SOCKET_ERROR then
     Print(['Warning: Can''t enable broadcast capability for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.']);

    I := 1;
    if (Reuse or (COM_CheckParm('-reuse') > 0)) and (setsockopt(S, SOL_SOCKET, SO_REUSEADDR, @I, SizeOf(I)) = SOCKET_ERROR) then
     Print(['Warning: Can''t allow address reuse for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.']);

    I := Int32(COM_CheckParm('-loopback') > 0);
    if setsockopt(S, IPPROTO_IP, IP_MULTICAST_LOOP, @I, SizeOf(I)) = SOCKET_ERROR then
     Print(['Warning: Can''t set multicast loopback for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.']);
    
    if COM_CheckParm('-tos') > 0 then
     begin
      I := IPTOS_LOWDELAY;
      if setsockopt(S, IPPROTO_IP, IP_TOS, @I, SizeOf(I)) = SOCKET_ERROR then
       Print(['Warning: Can''t set LOWDELAY TOS for socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
      else
       Print('LOWDELAY TOS option enabled.');
     end;

    MemSet(A, SizeOf(A), 0);
    A.sin_family := AF_INET;
    if (IP^ > #0) and (StrIComp(IP, 'localhost') <> 0) then
     NET_StringToSockaddr(IP, A);
    A.sin_port := htons(Port);

    if bind(S, A, SizeOf(A)) = SOCKET_ERROR then
     Print(['Error: Can''t bind socket on port ', Port, ' - ', NET_ErrorString(NET_LastError), '.'])
    else
     begin
      Result := S;
      Exit;
     end;
   end;

  {$IFDEF MSWINDOWS}shutdown(S, SD_BOTH); closesocket(S);
  {$ELSE}shutdown(S, SHUT_RDWR); __close(S);{$ENDIF};
 end;

Result := 0;
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
      if P = 0 then
       P := NET_SERVERPORT;
     end;
   end;

  IPSockets[NS_SERVER] := NET_IPSocket(ipname.Data, Trunc(P), False);
  if IPSockets[NS_SERVER] = 0 then
   Sys_Error(['Couldn''t allocate dedicated server IP on port ', Trunc(P), '.' + LineBreak +
              'Try using a different port by specifying either -port X or +hostport X in the commandline parameters.']);
 end;
NET_ThreadUnlock;
end;

procedure NET_GetLocalAddress;
var
 Buf: array[1..256] of LChar;
 AdrBuf: array[1..32] of LChar;
 NL: {$IFDEF MSWINDOWS}Int32{$ELSE}UInt32{$ENDIF};
 S: TSockAddr;
begin
if not NoIP then
 begin
  if StrIComp(ipname.Data, 'localhost') = 0 then
   begin
    gethostname(@Buf, SizeOf(Buf));
    Buf[High(Buf)] := #0;
   end
  else
   StrLCopy(@Buf, ipname.Data, SizeOf(Buf) - 1);

  NET_StringToAdr(@Buf, LocalIP);
  NL := SizeOf(TSockAddr);
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
    Exit;
   end;
 end
else
 Print('TCP/IP disabled.');

MemSet(LocalIP, SizeOf(LocalIP), 0);
end;

function NET_IsConfigured: Boolean;
begin
Result := NetInit;
end;

procedure NET_Config(EnableNetworking: Boolean);
var
 I: TNetSrc;
 S: TSocket;
begin
if OldConfig <> EnableNetworking then
 begin
  OldConfig := EnableNetworking;
  if EnableNetworking then
   begin
    if not NoIP then
     NET_OpenIP;

    if FirstInit then
     begin
      FirstInit := False;
      NET_GetLocalAddress;
     end;

    NET_ClearSplitContexts;
    NetInit := True;
   end
  else
   begin
    NET_ThreadLock;

    for I := Low(TNetSrc) to High(TNetSrc) do
     begin
      S := IPSockets[I];
      if S > 0 then
       begin
        {$IFDEF MSWINDOWS}shutdown(S, SD_RECEIVE); closesocket(S);
        {$ELSE}shutdown(S, SHUT_RD); __close(S);{$ENDIF}
        IPSockets[I] := 0;
       end;
     end;

    NET_ThreadUnlock;
    NetInit := False;
   end;
 end;
end;

procedure NET_Init;
var
 I: UInt;
 J: TNetSrc;
 P: PLagPacket;
begin
CVar_RegisterVariable(clockwindow);
CVar_RegisterVariable(net_address);
CVar_RegisterVariable(ipname);
CVar_RegisterVariable(ip_hostport);
CVar_RegisterVariable(hostport);
CVar_RegisterVariable(defport);
CVar_RegisterVariable(fakelag);
CVar_RegisterVariable(fakeloss);

UseThread := COM_CheckParm('-netthread') > 0;
NetSleepForever := COM_CheckParm('-netsleep') = 0;
NoIP := COM_CheckParm('-noip') > 0;

I := COM_CheckParm('-port');
if I > 0 then
 CVar_DirectSet(hostport, COM_ParmValueByIndex(I));

I := COM_CheckParm('-clockwindow');
if I > 0 then
 CVar_DirectSet(clockwindow, COM_ParmValueByIndex(I));

NetMessage.Name := 'net_message';
NetMessage.AllowOverflow := [FSB_ALLOWOVERFLOW];
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
NET_ClearSplitContexts;
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
NET_ClearLagData(True, True);
NET_Config(False);
NET_FlushQueues;
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
if not (FSB_OVERFLOWED in SB.AllowOverflow) then
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
  C.ReliableLength := 0;
  C.ReliableSequence := C.ReliableSequence xor 1;
 end;

SZ_Clear(C.NetMessage);
C.ClearTime := 0;
MemSet(C.Flow, SizeOf(C.Flow), 0);

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
Netchan_ClearFragments(C);
if C.TempBuffer <> nil then
 Mem_Free(C.TempBuffer);

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
if (C.Addr.AddrType = NA_LOOPBACK) and (net_chokeloop.Value = 0) then
 begin
  C.ClearTime := RealTime;
  Result := True;
 end
else
 Result := C.ClearTime < RealTime;
end;

procedure Netchan_UpdateFlow(var C: TNetchan);
var
 Seq: Int32;
 I, J, BytesTotal: UInt;
 F: PNetchanFlowData;
 FS: PNetchanFlowStats;
 PrevTime, Time: Double;
begin
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
 SBData: array[1..4040] of Byte;
 NetAdrBuf: array[1..64] of Byte;
 FileNameBuf: array[1..MAX_PATH_W] of LChar;
 SendReliable, HasPendingNetMsg, HasPendingFrag, B, Fragmented: Boolean;
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
 DPrint([NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ': Outgoing message overflow.'])
else
 begin
  SendReliable := (C.IncomingAcknowledged > C.LastReliableSequence) and
                  (C.IncomingReliableAcknowledged <> C.ReliableSequence);

  if C.ReliableLength = 0 then
   begin
    Netchan_FragSend(C);
    for I := 1 to 2 do
     HasPendingData[I] := C.FragBufBase[I] <> nil;

    HasPendingNetMsg := C.NetMessage.CurrentSize > 0;
    if HasPendingNetMsg and HasPendingData[1] then
     begin
      HasPendingNetMsg := False;
      if C.NetMessage.CurrentSize > 1200 then
       begin
        Netchan_CreateFragments(C, C.NetMessage);
        C.NetMessage.CurrentSize := 0;
       end;
     end;

    HasPendingFrag := False;
    for I := 1 to 2 do
     begin
      C.FragBufOffset[I] := 0;
      C.FragBufActive[I] := False;
      C.FragBufSequence[I] := 0;
      C.FragBufSize[I] := 0;
      if HasPendingData[I] then
       HasPendingFrag := True;
     end;

    if HasPendingNetMsg or HasPendingFrag then
     begin
      C.ReliableSequence := C.ReliableSequence xor 1;
      SendReliable := True;
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
       if FB.FileFrag and not FB.FileBuffer then
        FS := FB.FragmentSize
       else
        FS := FB.FragMessage.CurrentSize
      else
       FS := 0;

      if HasPendingData[I] and (FB <> nil) and (FS + C.ReliableLength < 1200) then
       begin
        C.FragBufSequence[I] := (FB.Index shl 16) or (C.FragBufSplitCount[I] and $FFFF);
        if FB.FileFrag and not FB.FileBuffer then
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

  // writing
  Fragmented := C.FragBufActive[1] or C.FragBufActive[2];

  Seq := C.OutgoingSequence or (Int(SendReliable) shl 31);
  Seq2 := C.IncomingSequence or (C.IncomingReliableSequence shl 31);
  if SendReliable and Fragmented then
   Seq := Seq or $40000000;

  MSG_WriteLong(SB, Seq);
  MSG_WriteLong(SB, Seq2);

  if SendReliable then
   begin
    if Fragmented then
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
    C.LastReliableSequence := C.OutgoingSequence;
   end;

  Inc(C.OutgoingSequence);

  if not SendReliable then
   I := SB.MaxSize
  else
   I := MAX_FRAGLEN;

  if SB.CurrentSize + Size > I then
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

  COM_Munge2(Pointer(UInt(SB.Data) + 8), SB.CurrentSize - 8, Byte(C.OutgoingSequence - 1));
  NET_SendPacket(C.Source, SB.CurrentSize, SB.Data, C.Addr);

  if SV.Active and (sv_lan.Value <> 0) and (sv_lan_rate.Value > 1000) then
   Rate := 1 / sv_lan_rate.Value
  else
   Rate := 1 / C.Rate;

  if C.ClearTime <= RealTime then
   C.ClearTime := RealTime + (SB.CurrentSize + UDP_OVERHEAD) * Rate
  else
   C.ClearTime := C.ClearTime + (SB.CurrentSize + UDP_OVERHEAD) * Rate;
  
  if (net_showpackets.Value <> 0) and (net_showpackets.Value <> 2) then
   Print([' s --> sz=', SB.CurrentSize, ' seq=', C.OutgoingSequence - 1, ' ack=', C.IncomingSequence, ' rel=',
          Int(SendReliable), ' tm=', SV.Time]);
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
  if P <> nil then
   begin
    P.Index := Index;
    P.FragMessage.Name := 'Frag Buffer';
    P.FragMessage.AllowOverflow := [FSB_ALLOWOVERFLOW];
    P.FragMessage.Data := @P.Data;
    P.FragMessage.MaxSize := SizeOf(P.Data);
    P.FragMessage.CurrentSize := 0;
    Netchan_AddBufferToList(Base, P);
    Result := P;
    Exit;
   end;
 end;

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

function Netchan_ValidateHeader(Ready: Boolean; Seq, Offset, Size: UInt): Boolean;
var
 Index, Count: UInt;
begin
Index := Seq shr 16;
Count := Seq and $FFFF;

if not Ready then
 Result := True
else
 Result := (Index <= 25000) and (Count <= 25000) and (Size <= 2048) and (Offset <= 16384) and
           (MSG_ReadCount + Offset + Size <= NetMessage.CurrentSize);
end;

function Netchan_Process(var C: TNetchan): Boolean;
var
 Seq, Ack: Int32;
 I: UInt;
 Rel, Fragmented, RelAck, Security: Boolean;
 FragReady: array[1..2] of Boolean;
 FragSeq: array[1..2] of UInt32;
 FragOffset, FragSize: array[1..2] of UInt16;
 NetAdrBuf: array[1..64] of LChar;
 FP: PNetchanFlowStats;
 P: PFragBuf;
begin
Result := False;

if not NET_CompareAdr(NetFrom, C.Addr) then
 Exit;

C.LastReceived := RealTime;

MSG_BeginReading;
Seq := MSG_ReadLong;
Ack := MSG_ReadLong;

Rel := (Seq and $80000000) > 0;
Fragmented := (Seq and $40000000) > 0;
RelAck := (Ack and $80000000) > 0;
Security := (Ack and $40000000) > 0;
Seq := Seq and $3FFFFFFF;
Ack := Ack and $3FFFFFFF;

if MSG_BadRead or Security then
 Exit;

COM_UnMunge2(Pointer(UInt(NetMessage.Data) + 8), NetMessage.CurrentSize - 8, Byte(Seq));
if Fragmented then
 begin
  for I := 1 to 2 do
   if MSG_ReadByte > 0 then
    begin
     FragReady[I] := True;
     FragSeq[I] := MSG_ReadLong;
     FragOffset[I] := MSG_ReadShort;
     FragSize[I] := MSG_ReadShort;
    end
   else
    begin
     FragReady[I] := False;
     FragSeq[I] := 0;
     FragOffset[I] := 0;
     FragSize[I] := 0;
    end;

  for I := 1 to 2 do
   if not Netchan_ValidateHeader(FragReady[I], FragSeq[I], FragOffset[I], FragSize[I]) then
    begin
     DPrint('Received a packet with invalid fragment header, ignoring.');
     Exit;
    end;

  if FragReady[1] and FragReady[2] and (FragOffset[2] < FragSize[1]) then
   begin
    DPrint('Received a packet with invalid fragment offset pair, ignoring.');
    Exit;
   end;
 end;

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

  if not Fragmented then
   Result := True
  else
   begin
    for I := 1 to 2 do
     if FragReady[I] then
      begin
       if FragSeq[I] > 0 then
        begin
         P := Netchan_FindBufferByID(C.IncomingBuf[I], FragSeq[I], True);
         if P = nil then
          DPrint(['Netchan_Process: Couldn''t allocate or find buffer #', FragSeq[I] shr 16, '.'])
         else
          begin
           SZ_Clear(P.FragMessage);
           SZ_Write(P.FragMessage, Pointer(UInt(NetMessage.Data) + MSG_ReadCount + FragOffset[I]), FragSize[I]);
           if FSB_OVERFLOWED in P.FragMessage.AllowOverflow then
            begin
             DPrint('Fragment buffer overflowed.');
             Include(C.NetMessage.AllowOverflow, FSB_OVERFLOWED);
             Exit;
            end;
          end;

         Netchan_CheckForCompletion(C, I, FragSeq[I] and $FFFF);
        end;

       Move(Pointer(UInt(NetMessage.Data) + MSG_ReadCount + FragOffset[I] + FragSize[I])^,
            Pointer(UInt(NetMessage.Data) + MSG_ReadCount + FragOffset[I])^,
            NetMessage.CurrentSize - FragSize[I] - FragOffset[I] - MSG_ReadCount);

       Dec(NetMessage.CurrentSize, FragSize[I]);
       if I = 1 then
        Dec(FragOffset[2], FragSize[1]);
      end;
     
    if NetMessage.CurrentSize > 16 then
     Result := True;
   end;
 end
else
 begin
  NetDrop := 0;
  if net_showdrop.Value <> 0 then
   if Seq = C.IncomingSequence then
    Print([NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ': Duplicate packet ', Seq, ' at ', C.IncomingSequence, '.'])
   else
    Print([NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ': Out of order packet ', Seq, ' at ', C.IncomingSequence, '.'])
 end;    
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
    if (P2.Next.Index shr 16) > (P.Index shr 16) then
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
P.FragMessage.AllowOverflow := [FSB_ALLOWOVERFLOW];
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
    SZ_Clear(SB);
    SZ_Write(SB, @Buf, DstLen);
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
    DPrint('Couldn''t allocate fragment buffer.');
    Netchan_ClearFragBufs(Dir.FragBuf);
    Mem_Free(Dir);

    if C.Client <> nil then
     SV_DropClient(PClient(C.Client)^, False, 'Server failed to allocate a fragment buffer.');
    Exit;
   end;

  FB.Index := FragIndex;
  Inc(FragIndex);
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
    DPrint('Couldn''t allocate fragment buffer.');
    Netchan_ClearFragBufs(Dir.FragBuf);
    Mem_Free(Dir);

    if Compressed then
     Mem_Free(Buffer);

    if C.Client <> nil then
     SV_DropClient(PClient(C.Client)^, False, 'Server failed to allocate a fragment buffer.');
    Exit;
   end;

  FB.Index := FragIndex;
  Inc(FragIndex);

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
  FB.FileFrag := True;
  FB.FileBuffer := True;

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

function Netchan_CreateFileFragments(var C: TNetchan; Name: PLChar): Boolean;
var
 FileNameBuf: array[1..MAX_PATH_W] of LChar;
 NetAdrBuf: array[1..64] of LChar;
 Compressed, NeedHeader: Boolean;
 F: TFile;
 SrcBuf, DstBuf: Pointer;
 Size, DstLen, ClientFragSize, FragIndex, ThisSize, FileOffset, RemainingSize, HeaderOverhead: UInt;
 Dir, P: PFragBufDir;
 FB: PFragBuf;
begin
Result := False;
Compressed := False;

StrLCopy(@FileNameBuf, Name, SizeOf(FileNameBuf) - 1);
StrLCat(@FileNameBuf, '.ztmp', SizeOf(FileNameBuf) - 1);
if FS_Open(F, @FileNameBuf, 'r') and (FS_GetFileTime(@FileNameBuf) >= FS_GetFileTime(Name)) then
 begin
  RemainingSize := FS_Size(F);
  FS_Close(F);

  if not FS_Open(F, Name, 'r') then
   begin
    Print(['Warning: Unable to open "', Name, '" for transfer.']);
    Exit;
   end;

  Size := FS_Size(F);
  FS_Close(F);
  if Size > sv_filetransfermaxsize.Value then
   begin
    Print(['Warning: File "', Name, '" is too big to transfer to ', NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), '.']);
    Exit;
   end;

  Compressed := True;
 end
else
 begin
  if not FS_Open(F, Name, 'r') then
   begin
    Print(['Warning: Unable to open "', Name, '" for transfer.']);
    Exit;
   end;

  Size := FS_Size(F);
  RemainingSize := Size;  
  if Size > sv_filetransfermaxsize.Value then
   begin
    Print(['Warning: File "', Name, '" is too big to transfer to ', NET_AdrToString(C.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), '.']);
    FS_Close(F);
    Exit;
   end;

  if (sv_filetransfercompression.Value = 0) and (net_compress.Value <> 2) and (net_compress.Value <> 3) then
   FS_Close(F)
  else
   begin
    SrcBuf := Mem_Alloc(Size);
    if FS_Read(F, SrcBuf, Size) <> Size then
     begin
      Print(['Warning: File read error in "', Name, '".']);
      Mem_Free(SrcBuf);
      FS_Close(F);
      Exit;
     end;

    DstBuf := Mem_Alloc(Size);
    DstLen := Size;
    if BZ2_bzBuffToBuffCompress(DstBuf, @DstLen, SrcBuf, Size, 9, 0, 30) = BZ_OK then
     begin
      FS_Close(F);

      if FS_Open(F, @FileNameBuf, 'wo') then
       begin
        DPrint(['Creating compressed version of file "', Name, '" (', Size, ' -> ', DstLen, ').']);
        FS_Write(F, DstBuf, DstLen);
        FS_Close(F);
        RemainingSize := DstLen;
        Compressed := True;
       end;
     end;

    Mem_Free(DstBuf);
    Mem_Free(SrcBuf);     
   end;
 end;

if (@C.FragmentFunc <> nil) and (C.Client <> nil) then
 ClientFragSize := C.FragmentFunc(C.Client)
else
 ClientFragSize := 1024;

Dir := Mem_ZeroAlloc(SizeOf(Dir^));
FragIndex := 1;
NeedHeader := True;
FileOffset := 0;

while RemainingSize > 0 do
 begin
  if RemainingSize < ClientFragSize then
   ThisSize := RemainingSize
  else
   ThisSize := ClientFragSize;

  FB := Netchan_AllocFragBuf;
  if FB = nil then
   begin
    DPrint('Couldn''t allocate fragment buffer.');
    Netchan_ClearFragBufs(Dir.FragBuf);
    Mem_Free(Dir);

    if C.Client <> nil then
     SV_DropClient(PClient(C.Client)^, False, 'Server failed to allocate a fragment buffer.');
    Exit;
   end;

  FB.Index := FragIndex;
  Inc(FragIndex);

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
  FB.FileFrag := True;
  FB.Compressed := Compressed;
  StrLCopy(@FB.FileName, Name, MAX_PATH_A - 1);

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
 Buf: array[1..65536+256+32] of Byte;
begin
Result := False;

if C.IncomingActive[1] then
 if C.IncomingBuf[1] <> nil then
  begin
   SZ_Clear(NetMessage);

   P := C.IncomingBuf[1];
   while P <> nil do
    begin
     P2 := P.Next;
     SZ_Write(NetMessage, P.FragMessage.Data, P.FragMessage.CurrentSize);
     Mem_Free(P);
     P := P2;
    end;
   
   if FSB_OVERFLOWED in NetMessage.AllowOverflow then
    DPrint('Netchan_CopyNormalFragments: Fragment buffer overflowed, ignoring.')
   else
    if PUInt32(NetMessage.Data)^ = BZIP2_TAG then
     begin
      DL := SizeOf(Buf);
      if BZ2_bzBuffToBuffDecompress(@Buf, @DL, Pointer(UInt(NetMessage.Data) + SizeOf(UInt32)), NetMessage.CurrentSize - SizeOf(UInt32), 1, 0) = BZ_OK then
       begin
        Move(Buf, NetMessage.Data^, DL);
        NetMessage.CurrentSize := DL;
        Result := True;
       end
      else
       NetMessage.CurrentSize := 0;
     end
    else
     Result := True;

   if not Result then
    begin
     SZ_Clear(NetMessage);
     MSG_BeginReading;
    end;

   C.IncomingBuf[1] := nil;
   C.IncomingActive[1] := False;
  end
 else
  begin
   DPrint('Netchan_CopyNormalFragments: Called with no fragments readied.');
   C.IncomingActive[1] := False;
  end;
end;

function Netchan_DecompressIncoming(FileName: PLChar; var Src: Pointer; var TotalSize: UInt; IncomingSize: UInt): Boolean;
var
 P: Pointer;
begin
Result := False;
if IncomingSize >= sv_filereceivemaxsize.Value then
 DPrint(['Incoming decompressed size for file "', PLChar(FileName), '" is too big, ignoring.'])
else
 begin
  P := Mem_Alloc(IncomingSize + 1);
  DPrint(['Decompressing file "', PLChar(FileName), '" (', TotalSize, ' -> ', IncomingSize, ').']);
  if BZ2_bzBuffToBuffDecompress(P, @IncomingSize, Src, TotalSize, 1, 0) <> BZ_OK then
   begin
    DPrint(['Decompression failed for incoming file "', PLChar(FileName), '".']);
    Mem_Free(P);
   end
  else
   begin
    Mem_Free(Src);
    Src := P;
    TotalSize := IncomingSize;
    Result := True;
   end;
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
 if C.IncomingBuf[2] <> nil then
  begin
   SZ_Clear(NetMessage);
   MSG_BeginReading;

   P := C.IncomingBuf[2];
   if P.FragMessage.CurrentSize > NetMessage.MaxSize then
    DPrint('File fragment buffer overflowed.')
   else
    begin
     if P.FragMessage.CurrentSize > 0 then
      SZ_Write(NetMessage, P.FragMessage.Data, P.FragMessage.CurrentSize);

     StrLCopy(@FileName, MSG_ReadString, SizeOf(FileName) - 1);
     Compressed := StrIComp(MSG_ReadString, 'bz2') = 0;
     IncomingSize := MSG_ReadLong;

     if MSG_BadRead then
      DPrint('File fragment received with invalid header.')
     else
      if FileName[1] = #0 then
       DPrint('File fragment received with no filename.')
      else
       if not IsSafeFile(@FileName) then
        DPrint('File fragment received with unsafe path.')
       else
        begin
         StrLCopy(@C.FileName, @FileName, SizeOf(C.FileName) - 1);

         if FileName[1] <> '!' then
          begin
           if sv_receivedecalsonly.Value <> 0 then
            begin
             DPrint(['Received a non-decal file "', PLChar(@FileName), '", ignored.']);
             Netchan_FlushIncoming(C, 2);
             Exit;
            end;

           if FS_FileExists(@FileName) then
            begin
             DPrint(['Can''t download "', PLChar(@FileName), '", already exists.']);
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
          DPrint(['Buffer allocation failed on ', TotalSize + 1, ' bytes.'])
         else
          begin
           CurrentSize := 0;

           P := C.IncomingBuf[2];
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

           C.IncomingBuf[2] := nil;
           C.IncomingActive[2] := False;

           if not Compressed or Netchan_DecompressIncoming(@FileName, Src, TotalSize, IncomingSize) then
            begin
             if FileName[1] = '!' then
              begin
               if C.TempBuffer <> nil then
                Mem_FreeAndNil(C.TempBuffer);
               C.TempBuffer := Src;
               C.TempBufferSize := TotalSize;
              end
             else
              begin
               COM_WriteFile(@FileName, Src, TotalSize);
               Mem_Free(Src);
              end;

             SZ_Clear(NetMessage);
             MSG_BeginReading;
             C.IncomingBuf[2] := nil;
             C.IncomingActive[2] := False;
             Result := True;
             Exit;
            end;

           Mem_Free(Src);
          end;
        end;
    end;

   Netchan_FlushIncoming(C, 2);
  end
 else
  begin
   DPrint('Netchan_CopyFileFragments: Called with no fragments readied.');
   C.IncomingActive[2] := False;
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
CVar_RegisterVariable(net_showpackets);
CVar_RegisterVariable(net_showdrop);
CVar_RegisterVariable(net_chokeloop);
CVar_RegisterVariable(sv_filetransfercompression);
CVar_RegisterVariable(sv_filetransfermaxsize);
CVar_RegisterVariable(sv_filereceivemaxsize);
CVar_RegisterVariable(sv_receivedecalsonly);
CVar_RegisterVariable(net_compress);
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
