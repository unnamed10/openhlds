unit FilterIP;

{$I HLDS.inc}

interface

uses Default, SDK;

const
 IP_IN_CHAIN = 32;
 
type
 PIPFilterRec = ^TIPFilterRec;
 TIPFilterRec = record
  IP: UInt32; // if 0, filter is inactive
  Ext: Pointer; // Extended data for this particular filter.
 end;

 PIPFilterChain = ^TIPFilterChain;
 TIPFilterChain = record
  IPs: array[1..IP_IN_CHAIN] of TIPFilterRec;

  NumIPs: UInt;

  // Indexes for these IPs. It goes like 1, 17, 33, 49...
  IndexBase: UInt;

  // See if there's a free chain somewhere ahead.
  // NULL if this is the last free chain (need more allocations).
  PrevFree, NextFree: PIPFilterChain; // unlinks

  
  // No free filters? -> nope, don't free.
  // Compression will take care of filters which weren't freed.
  // These chains still can hold filters, even if fully depleted.

  Prev: PIPFilterChain;
  
  // Here comes the EXT data for every filter.
 end;
 // Signalling for Free: just link to the first node.
 // Take node free from the first chain and put it on yourself.

 PIPFilter = ^TIPFilter;
 TIPFilter = record
  // First chain has "next" pointer defined (or not, if there's none).
  Base: array[Byte] of PIPFilterChain;

  BaseFree: array[Byte] of PIPFilterChain;

  LastIndexBase: UInt; // last allocated index base
  TotalIPs: UInt;
  
  Name: PLChar; // just in case

  // Size of extended data
  ExtSize: UInt;
 end;

procedure IPF_Clear(var IPF: TIPFilter; DoCleanup: Boolean);

function IPF_Search(const IPF: TIPFilter; IP: UInt32; out ExtData: Pointer): UInt;
function IPF_Alloc(var IPF: TIPFilter; IP: UInt32; out ExtData: Pointer): UInt;
function IPF_Remove(var IPF: TIPFilter; Index: UInt): Boolean;

procedure IPF_Init(var IPF: TIPFilter; Name: PLChar; ExtSize: UInt);
procedure IPF_Shutdown(var IPF: TIPFilter);

procedure IPF_RemoveOldestChain(var IPF: TIPFilter);

implementation

uses Console, Info, Memory, Server, SVClient, SVAuth, SysMain;

procedure IPF_Clear(var IPF: TIPFilter; DoCleanup: Boolean);
var
 I: UInt;
 P, P2: PIPFilterChain;
begin
if DoCleanup then
 for I := Low(Byte) to High(Byte) do
  begin
   P := IPF.Base[I];
   while P <> nil do
    begin
     P2 := P.Prev;
     Mem_Free(P);
     P := P2;
    end;
  end;

MemSet(IPF.Base, SizeOf(IPF.Base), 0);
MemSet(IPF.BaseFree, SizeOf(IPF.BaseFree), 0);

IPF.LastIndexBase := 1;
IPF.TotalIPs := 0;
end;

// Returns index, or 0 if not found.
function IPF_Search(const IPF: TIPFilter; IP: UInt32; out ExtData: Pointer): UInt;
var
 P: PIPFilterChain;
 P2: PIPFilterRec;
 PEnd: Pointer;
begin
P := IPF.Base[IP and $FF];
while P <> nil do
 begin
  PEnd := Pointer(UInt(@P.IPs) + SizeOf(P.IPs));

  P2 := @P.IPs;
  while UInt(P2) < UInt(PEnd) do
   if P2.IP = IP then
    begin
     if @ExtData <> nil then
      ExtData := P2.Ext;
     Result := P.IndexBase + (UInt(P2) - UInt(@P.IPs)) div SizeOf(P2^);
     Exit;
    end
   else
    Inc(UInt(P2), SizeOf(P2^));

  P := P.Prev;
 end;

if @ExtData <> nil then
 ExtData := nil;
Result := 0;
end;

procedure IPF_SignalForFreeChain(var IPF: TIPFilter; var Base: PIPFilterChain; Cur: PIPFilterChain);
begin
Cur.PrevFree := Base;
Cur.NextFree := nil;

if Base <> nil then
 Base.NextFree := Cur;
Base := Cur;
end;

procedure IPF_SignalForAllocChain(var IPF: TIPFilter; var Base: PIPFilterChain; Chain: PIPFilterChain);
begin
if Base = Chain then
 Base := Chain.PrevFree;

if Chain.PrevFree <> nil then
 begin
  Chain.PrevFree.NextFree := Chain.NextFree;
  Chain.PrevFree := nil;
 end;

if Chain.NextFree <> nil then
 begin
  Chain.NextFree.PrevFree := Chain.PrevFree;
  Chain.NextFree := nil;
 end;
end;

function IPF_Remove(var IPF: TIPFilter; Index: UInt): Boolean;
var
 I: UInt;
 P: PIPFilterChain;
 Rec: PIPFilterRec;
begin
for I := Low(Byte) to High(Byte) do
 begin
  P := IPF.Base[I];
  while P <> nil do
   if (Index >= P.IndexBase) and (P.IndexBase < Index + IP_IN_CHAIN) then
    begin
     Rec := @P.IPs[Index - P.IndexBase + 1];
     if Rec.IP = 0 then
      Result := False
     else
      begin
       if P.NumIPs = IP_IN_CHAIN then
        IPF_SignalForFreeChain(IPF, IPF.BaseFree[I], P);

       Dec(P.NumIPs);
       Dec(IPF.TotalIPs);

       MemSet(Rec^, SizeOf(TIPFilterRec), 0);
       Result := True;
      end;

     Exit;
    end
   else
    P := P.Prev;
 end;

Result := False;
end;

// Allocates a new chain and sets tail accordingly.
function IPF_MakeNewChain(var IPF: TIPFilter; Index: UInt): PIPFilterChain;
var
 P: PIPFilterChain;
 P2: Pointer;
 I: UInt;
begin
P := Mem_ZeroAlloc(SizeOf(P^) + IPF.ExtSize * IP_IN_CHAIN);
if P = nil then
 Sys_Error('IPF_MakeNewChain: Out of memory.');

P.NumIPs := 0;
P.IndexBase := IPF.LastIndexBase;
Inc(IPF.LastIndexBase, IP_IN_CHAIN);

P.Prev := IPF.Base[Index];
IPF.Base[Index] := P;

P2 := Pointer(UInt(P) + SizeOf(P^));
for I := 1 to IP_IN_CHAIN do
 begin
  P.IPs[I].Ext := P2;
  Inc(UInt(P2), IPF.ExtSize);
 end;

IPF_SignalForFreeChain(IPF, IPF.BaseFree[Index], P);
Result := P;
end;

// Allocated if there's no space, returns E #1.
function IPF_FindSpace(var IPF: TIPFilter; Index: UInt; out RecID: UInt): PIPFilterRec;
var
 P: PIPFilterChain;
 I: UInt;
begin
P := IPF.BaseFree[Index];
while P <> nil do
 begin
  for I := 1 to IP_IN_CHAIN do
   if P.IPs[I].IP = 0 then
    begin
     RecID := P.IndexBase + (I - 1);
     Result := @P.IPs[I];

     if P.NumIPs < IP_IN_CHAIN then
      Inc(P.NumIPs);

     Exit;
    end;

  P.NumIPs := IP_IN_CHAIN;
  IPF_SignalForAllocChain(IPF, IPF.BaseFree[Index], P);

  P := P.PrevFree;
 end;

// Alloc now.
P := IPF_MakeNewChain(IPF, Index);
Result := @P.IPs[1];
if IP_IN_CHAIN = 1 then
 begin
  RecID := P.IndexBase;
  Inc(P.NumIPs);
  if P.NumIPs = IP_IN_CHAIN then
   IPF_SignalForAllocChain(IPF, IPF.BaseFree[Index], P);
 end;
end;

function IPF_Alloc(var IPF: TIPFilter; IP: UInt32; out ExtData: Pointer): UInt;
var
 Index: UInt;
 P: PIPFilterRec;
begin
P := IPF_FindSpace(IPF, IP and $FF, Index);
Inc(IPF.TotalIPs);
P.IP := IP;
if @ExtData <> nil then
 ExtData := P.Ext;
Result := Index;
end;

procedure IPF_RemoveOldestChain(var IPF: TIPFilter);
var
 I, J, K, Links: UInt;
 P, Target: PIPFilterChain;
begin
Links := 0;
K := 0;                
Target := nil;

for I := Low(Byte) to High(Byte) do
 begin
  P := IPF.Base[I];
  J := 1;
  while P <> nil do                                  
   begin
    if Links < J then
     begin
      Links := J;
      Target := P;
      K := I;
     end;

    Inc(J);
    P := P.Prev;
   end;
 end;

if Target <> nil then
 begin
  if Target.NumIPs = IP_IN_CHAIN then
   IPF_SignalForFreeChain(IPF, IPF.BaseFree[K], Target);
  MemSet(Target.IPs, SizeOf(Target.IPs), 0);
  Dec(IPF.TotalIPs, Target.NumIPs);
  Target.NumIPs := 0;
 end;
end;

procedure IPF_Init(var IPF: TIPFilter; Name: PLChar; ExtSize: UInt);
begin
IPF_Clear(IPF, False);
IPF.Name := Name;
IPF.ExtSize := ExtSize;
end;

procedure IPF_Shutdown(var IPF: TIPFilter);
begin
IPF_Clear(IPF, True);
IPF.Name := nil;
IPF.ExtSize := 0;
end;

end.
