unit SVEvent;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure EV_PlayReliableEvent(var C: TClient; Index: Int; EventIndex: UInt16; Delay: Single; const Event: TEvent);
procedure EV_Playback(Flags: UInt; const E: TEdict; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32);
procedure EV_SV_Playback(Flags, ClientIndex: UInt; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32);
function EV_Precache(EventType: UInt; Name: PLChar): UInt16;

procedure SV_ClearPrecachedEvents;

procedure SV_EmitEvents(var C: TClient; const Pack: TPacketEntities; var SB: TSizeBuf);

procedure SV_ClearClientEvents(var C: TClient);

implementation

uses Common, Console, Delta, Edict, Host, MathLib, Memory, MsgBuf, Network, SVDelta, SVMain, SVMove, SVSend;

procedure EV_PlayReliableEvent(var C: TClient; Index: Int; EventIndex: UInt16; Delay: Single; const Event: TEvent);
var
 SB: TSizeBuf;
 SBData: array[1..2048] of Byte;
 OldEvent, NewEvent: TEvent;
begin
if not C.FakeClient then
 begin
  SB.Name := 'Reliable Event';
  SB.AllowOverflow := [FSB_ALLOWOVERFLOW];
  SB.Data := @SBData;
  SB.CurrentSize := 0;
  SB.MaxSize := SizeOf(SBData);
  MemSet(OldEvent, SizeOf(OldEvent), 0);
  Move(Event, NewEvent, SizeOf(NewEvent));
  NewEvent.EntIndex := Index;

  MSG_WriteByte(SB, SVC_EVENT_RELIABLE);
  MSG_StartBitWriting(SB);
  MSG_WriteBits(EventIndex, 10);
  Delta_WriteDelta(@OldEvent, @NewEvent, True, EventDelta^, nil);
  if Delay = 0 then
   MSG_WriteBits(0, 1)
  else
   begin
    MSG_WriteBits(1, 1);
    MSG_WriteBits(Trunc(Delay * 100), 16);
   end;
  MSG_EndBitWriting;

  if not (FSB_OVERFLOWED in SB.AllowOverflow) then
   if SB.CurrentSize + C.Netchan.NetMessage.CurrentSize < C.Netchan.NetMessage.MaxSize then
    SZ_Write(C.Netchan.NetMessage, SB.Data, SB.CurrentSize)
   else
    Netchan_CreateFragments(C.Netchan, SB);
 end;
end;

procedure EV_Playback(Flags: UInt; const E: TEdict; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32);
var
 Event: TEvent;
 Point: TVec3;
 LeafNum: UInt;
 I, J, EntityNum: Int;
 C: PClient;
 CE: PEventInfo;
 B: Boolean;
begin
if (Flags and FEV_CLIENT) > 0 then
 Exit;

MemSet(Event, SizeOf(Event), 0);

if (@Origin <> nil) and not VectorCompare(Origin, Vec3Origin) then
 begin
  Event.Flags := Event.Flags or FEVENT_ORIGIN;
  Event.Origin := Origin;
 end;
if (@Angles <> nil) and not VectorCompare(Angles, Vec3Origin) then
 begin
  Event.Flags := Event.Flags or FEVENT_ANGLES;
  Event.Angles := Angles;
 end;

Event.FParam1 := FParam1;
Event.FParam2 := FParam2;
Event.IParam1 := IParam1;
Event.IParam2 := IParam2;
Event.BParam1 := BParam1;
Event.BParam2 := BParam2;

if (EventIndex < 1) or (EventIndex >= MAX_EVENTS) then
 DPrint(['EV_Playback: Event index out of range (', EventIndex, ').'])
else
 if SV.PrecachedEvents[EventIndex].Data = nil then
  DPrint(['EV_Playback: No event for index ', EventIndex, '.'])
 else
  begin
   if @E = nil then
    begin
     Point := Event.Origin;
     EntityNum := -1;
    end
   else
    begin
     Point := E.V.Origin;
     EntityNum := NUM_FOR_EDICT(E);
     if (EntityNum >= 1) and (UInt(EntityNum) <= SVS.MaxClients) and ((E.V.Flags and FL_DUCKING) > 0) then
      Event.Ducking := 1;

     if (Event.Flags and FEVENT_ORIGIN) = 0 then
      Event.Origin := E.V.Origin;
     if (Event.Flags and FEVENT_ANGLES) = 0 then
      Event.Angles := E.V.Angles;
    end;

   LeafNum := SV_PointLeafnum(Point);
   for I := 0 to SVS.MaxClients - 1 do
    begin
     C := @SVS.Clients[I];
     if not C.Active or not C.Spawned or not C.SendInfo or not C.Connected or C.FakeClient then
      Continue;

     if FilterGroup(E, C.Entity^) then
      Continue;

     if ((Flags and FEV_GLOBAL) = 0) and (@E <> nil) and not SV_ValidClientMulticast(C^, LeafNum, MULTICAST_PAS) then
      Continue;

     if ((C = HostClient) and ((Flags and FEV_NOTHOST) > 0) and C.LW) or
        ((C.Entity <> @E) and ((Flags and FEV_HOSTONLY) > 0)) then
      Continue;

     if (Flags and FEV_RELIABLE) > 0 then
      begin
       if @E <> nil then
        EV_PlayReliableEvent(C^, EntityNum, EventIndex, Delay, Event)
       else
        EV_PlayReliableEvent(C^, 0, EventIndex, Delay, Event);

       Continue;
      end;

     B := False;
     if (Flags and FEV_UPDATE) > 0 then
      for J := 0 to MAX_EVENT_QUEUE - 1 do
       begin
        CE := @C.Events[J];
        if (CE.Index = EventIndex) and (EntityNum <> -1) and (CE.EntityIndex = EntityNum) then
         begin
          CE.PacketIndex := -1;
          CE.EntityIndex := EntityNum;
          CE.FireTime := Delay;
          Move(Event, CE.Args, SizeOf(CE.Args));
          B := True;
          Break;
         end;
       end;

     if not B then
      for J := 0 to MAX_EVENT_QUEUE - 1 do
       begin
        CE := @C.Events[J];
        if CE.Index = 0 then
         begin
          CE.Index := EventIndex;
          CE.PacketIndex := -1;
          if @E <> nil then
           CE.EntityIndex := EntityNum
          else
           CE.EntityIndex := -1;
          CE.FireTime := Delay;           
          Move(Event, CE.Args, SizeOf(CE.Args));
          Break;
         end;
       end;
    end;
  end;
end;

procedure EV_SV_Playback(Flags, ClientIndex: UInt; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32);
begin
if (Flags and FEV_CLIENT) = 0 then
 if ClientIndex >= SVS.MaxClients then
  Host_Error(['EV_SV_Playback: Client index #', ClientIndex, ' is out of range.'])
 else
  EV_Playback(Flags, SVS.Clients[ClientIndex].Entity^, EventIndex, Delay, Origin, Angles, FParam1, FParam2, IParam1, IParam2, BParam1, BParam2);
end;

function EV_Precache(EventType: UInt; Name: PLChar): UInt16;
var
 I: Int;
 E: PPrecachedEvent;
 Buf: array[1..MAX_PATH_W] of LChar;
 P: Pointer;
 Size: UInt32;
begin
if Name = nil then
 Host_Error('EV_Precache: NULL pointer.')
else
 if Name^ <= ' ' then
  Host_Error(['EV_Precache: Bad string "', Name, '".'])
 else
  begin
   for I := 1 to MAX_EVENTS - 1 do
    begin
     E := @SV.PrecachedEvents[I];
     if E.Name = nil then
      if SV.State <> SS_LOADING then
       Break
      else
       begin
        if EventType <> 1 then
         Host_Error('EV_Precache: The event type must be "1".');

        StrLCopy(@Buf, Name, SizeOf(Buf) - 1);
        COM_FixSlashes(@Buf);
        P := COM_LoadFile(@Buf, FILE_ALLOC_MEMORY, @Size);
        if P = nil then
         Host_Error(['EV_Precache: File "', PLChar(@Buf), '" is missing from server.']);

        E.Index := I;
        E.Name := Hunk_StrDup(Name);
        E.Size := Size;
        E.Data := P;
        Result := I;
        Exit;
       end
     else
      if StrIComp(E.Name, Name) = 0 then
       begin
        Result := I;
        Exit;
       end;
    end;

   if SV.State = SS_LOADING then
    Host_Error(['EV_Precache: Event "', Name, '" failed to precache because the item count is over the ', MAX_EVENTS - 1, ' limit.'])
   else
    Host_Error(['EV_Precache: "', Name, '": Precache can only be done in spawn functions.']);
  end;

Result := 0;
end;

procedure SV_ClearPrecachedEvents;
var
 I: Int;
 E: PPrecachedEvent;
begin
for I := 1 to MAX_EVENTS - 1 do
 begin
  E := @SV.PrecachedEvents[I];
  if E.Name = nil then
   Exit
  else
   if E.Data <> nil then
    begin
     COM_FreeFile(E.Data);
     E.Data := nil;
    end;
 end;
end;

procedure SV_EmitEvents(var C: TClient; const Pack: TPacketEntities; var SB: TSizeBuf);
var
 OS: TEvent;
 Count: UInt;
 I, J, K: Int;
 E: PEventInfo;
begin
Count := 0;
for I := 0 to MAX_EVENT_QUEUE - 1 do
 begin
  E := @C.Events[I];
  if E.Index > 0 then
   begin
    Inc(Count);

    K := -1;
    if E.EntityIndex <> -1 then
     for J := 0 to Pack.NumEnts - 1 do
      if Pack.Ents[J].Number = UInt(E.EntityIndex) then
       begin
        K := J;
        Break;
       end;

    if K = -1 then
     begin
      E.PacketIndex := Pack.NumEnts;
      E.Args.EntIndex := E.EntityIndex;
     end
    else
     begin
      E.PacketIndex := K;
      E.Args.Ducking := 0;
      if (E.Args.Flags and FEVENT_ORIGIN) = 0 then
       E.Args.Origin := Vec3Origin;
      if (E.Args.Flags and FEVENT_ANGLES) = 0 then
       E.Args.Angles := Vec3Origin;
     end;
   end;
 end;

if Count = 0 then
 Exit
else
 if Count > 31 then
  Count := 31;

MemSet(OS, SizeOf(OS), 0);
MSG_WriteByte(SB, SVC_EVENT);
MSG_StartBitWriting(SB);
MSG_WriteBits(Count, 5);

K := 0;
for I := 0 to MAX_EVENT_QUEUE - 1 do
 begin
  E := @C.Events[I];
  if E.Index = 0 then
   begin
    E.PacketIndex := -1;
    E.EntityIndex := -1;
   end
  else
   if UInt(K) < Count then
    begin
     MSG_WriteBits(E.Index, 10);

     if E.PacketIndex = -1 then
      MSG_WriteBits(0, 1)
     else
      begin
       MSG_WriteBits(1, 1);
       MSG_WriteBits(E.PacketIndex, 11);

       if CompareMem(@OS, @E.Args, SizeOf(E.Args)) then
        MSG_WriteBits(0, 1)
       else
        begin
         MSG_WriteBits(1, 1);
         Delta_WriteDelta(@OS, @E.Args, True, EventDelta^, nil);
        end;
      end;

     if E.FireTime = 0 then
      MSG_WriteBits(0, 1)
     else
      begin
       MSG_WriteBits(1, 1);
       MSG_WriteBits(Trunc(E.FireTime * 100), 16);
      end;

     E.Index := 0;
     E.PacketIndex := -1;
     E.EntityIndex := -1;

     Inc(K);
    end;
 end;

MSG_EndBitWriting;
end;

procedure SV_ClearClientEvents(var C: TClient);
var
 I: Int;
 E: PEventInfo;
begin
for I := 0 to MAX_EVENT_QUEUE - 1 do
 begin
  E := @C.Events[I];
  E.Index := 0;
  E.PacketIndex := -1;
  E.EntityIndex := -1;
 end;
end;

end.
