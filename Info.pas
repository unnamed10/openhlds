unit Info;

{$I HLDS.inc}

interface

uses SysUtils, Default;

function Info_ServerInfo: PLChar;
function Info_ValueForKey(S, Key: PLChar): PLChar;
procedure Info_RemoveKey(S, Key: PLChar);
procedure Info_RemovePrefixedKeys(Start: PLChar; Prefix: LChar);
function Info_IsKeyImportant(S: PLChar): Boolean;
function Info_FindLargestKey(S: PLChar): PLChar;
procedure Info_SetValueForStarKey(S, Key, Value: PLChar; MaxSize: UInt);
procedure Info_SetValueForKey(S, Key, Value: PLChar; MaxSize: UInt);
procedure Info_Print(S: PLChar);
function Info_IsValid(S: PLChar): Boolean;

const
 MAX_KV_LEN = 128;

var
 LocalInfo: array[1..32768] of LChar;
 ServerInfo: array[1..256] of LChar;

implementation

uses Console;

var
 ValueIndex: UInt = 0;
 ValueBuf: array[0..3] of array [1..MAX_KV_LEN] of LChar;
 LargestKey: array[1..MAX_KV_LEN] of LChar;

function Info_ServerInfo: PLChar;
begin
Result := @ServerInfo;
end;

function Info_ValueForKey(S, Key: PLChar): PLChar;
var
 P, P2: PLChar;
 PKey: array[1..MAX_KV_LEN] of LChar;
begin
Result := EmptyString;
ValueIndex := (ValueIndex + 1) and 3;
if S^ = '\' then
 Inc(UInt(S));

while True do
 begin
  P := @PKey;
  P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);

  while (S^ <> '\') and (UInt(P) < UInt(P2)) do
   begin
    if S^ = #0 then
     Exit;

    P^ := S^;
    Inc(UInt(S));
    Inc(UInt(P));
   end;

  if P = P2 then
   begin
    Print('Info_ValueForKey: Oversized key.');
    Exit;
   end;

  P^ := #0;
  Inc(UInt(S));

  P := @ValueBuf[ValueIndex];
  P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
  while (S^ <> '\') and (S^ > #0) and (UInt(P) < UInt(P2)) do
   begin
    P^ := S^;
    Inc(UInt(S));
    Inc(UInt(P));
   end;

  if P = P2 then
   begin
    Print('Info_ValueForKey: Oversized value.');
    Exit;
   end;

  P^ := #0;

  if StrComp(Key, @PKey) = 0 then
   begin
    Result := @ValueBuf[ValueIndex];
    Exit;
   end
  else
   if S^ = #0 then
    begin
     Result := EmptyString;
     Exit;
    end;

  Inc(S);
 end;
end;

procedure Info_RemoveKey(S, Key: PLChar);
var
 L: UInt;
 S2, P, P2: PLChar;
 PKey, Value: array[1..MAX_KV_LEN] of LChar;
begin
L := StrLen(Key);
if L >= MAX_KV_LEN - 1 then
 L := MAX_KV_LEN - 1;

if StrScan(Key, '\') <> nil then
 Print('Can''t use a key with a "\".')
else
 while True do
  begin
   S2 := S;
   if S^ = '\' then
    Inc(UInt(S));

   P := @PKey;
   P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
   while (S^ <> '\') and (UInt(P) < UInt(P2)) do
    begin
     if S^ = #0 then
      Exit;

     P^ := S^;
     Inc(UInt(S));
     Inc(UInt(P));
    end;

   if P = P2 then
    begin
     Print('Info_RemoveKey: Oversized key.');
     Exit;
    end;

   P^ := #0;
   Inc(UInt(S));

   P := @Value;
   P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
   while (S^ <> '\') and (S^ > #0) and (UInt(P) < UInt(P2)) do
    begin
     P^ := S^;
     Inc(UInt(S));
     Inc(UInt(P));
    end;

   if P = P2 then
    begin
     Print('Info_RemoveKey: Oversized value.');
     Exit;
    end;

   P^ := #0;

   if StrLComp(Key, @PKey, L) = 0 then
    begin
     StrCopy(S2, S);
     Exit;
    end
   else
    if S^ = #0 then
     Exit;
  end;
end;

procedure Info_RemovePrefixedKeys(Start: PLChar; Prefix: LChar);
var
 S, P, P2: PLChar;
 PKey, Value: array[1..MAX_KV_LEN] of LChar;
begin
S := Start;
while True do
 begin
  if S^ = '\' then
   Inc(UInt(S));

  P := @PKey;
  P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
  while (S^ <> '\') and (UInt(P) < UInt(P2)) do
   begin
    if S^ = #0 then
     Exit;

    P^ := S^;
    Inc(UInt(S));
    Inc(UInt(P));
   end;

  P^ := #0;
  Inc(UInt(S));

  P := @Value;
  P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
  while (S^ <> '\') and (S^ > #0) and (UInt(P) < UInt(P2)) do
   begin
    P^ := S^;
    Inc(UInt(S));
    Inc(UInt(P));
   end;
  P^ := #0;

  if PKey[Low(PKey)] = Prefix then
   begin
    Info_RemoveKey(Start, @PKey);
    S := Start;
   end;

  if S^ = #0 then
   Exit;
 end;
end;

function Info_IsKeyImportant(S: PLChar): Boolean;
begin
Result := (S^ = '*') or
          (StrComp(S, 'name') = 0) or
          (StrComp(S, 'model') = 0) or
          (StrComp(S, 'rate') = 0) or
          (StrComp(S, 'topcolor') = 0) or
          (StrComp(S, 'bottomcolor') = 0) or
          (StrComp(S, 'cl_updaterate') = 0) or
          (StrComp(S, 'cl_lw') = 0) or
          (StrComp(S, 'cl_lc') = 0);
end;

function Info_FindLargestKey(S: PLChar): PLChar;
var
 P, P2: PLChar;
 PKey, Value: array[1..MAX_KV_LEN] of LChar;
 Size, LargestSize: UInt;
begin
LargestKey[Low(LargestKey)] := #0;
Result := @LargestKey;
LargestSize := 0;
if S^ = '\' then
 Inc(UInt(S));

while S^ > #0 do
 begin
  P := @PKey;
  P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
  while (S^ <> '\') and (UInt(P) < UInt(P2)) do
   begin
    if S^ = #0 then
     Exit;

    P^ := S^;
    Inc(UInt(S));
    Inc(UInt(P));
   end;

  P^ := #0;
  Size := StrLen(@PKey);
  if S^ = #0 then
   Break;
  Inc(UInt(S));

  P := @Value;
  P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
  while (S^ <> '\') and (S^ > #0) and (UInt(P) < UInt(P2)) do
   begin
    P^ := S^;
    Inc(UInt(S));
    Inc(UInt(P));
   end;
  P^ := #0;

  if S^ > #0 then
   Inc(UInt(S));

  Inc(Size, StrLen(@Value));
  if (Size > LargestSize) and not Info_IsKeyImportant(@PKey) then
   begin
    LargestSize := Size;
    StrLCopy(@LargestKey, @PKey, MAX_KV_LEN - 1);
   end;
 end;
end;

procedure Info_SetValueForStarKey(S, Key, Value: PLChar; MaxSize: UInt);
var
 NewKV: array[1..1024] of LChar;
 P: PLChar;
 L: UInt;
 B: Boolean;
 C: LChar;
begin
if (StrScan(Key, '\') <> nil) or (StrScan(Value, '\') <> nil) then
 Print('Can''t use keys or values with a "\".')
else
 if (StrPos(Key, '..') <> nil) or (StrPos(Value, '..') <> nil) then
  Print('Can''t use keys or values with a "..".')
 else
  if (StrScan(Key, '"') <> nil) or (StrScan(Value, '"') <> nil) then
   Print('Can''t use keys or values with a ".')
  else
   if (Key^ = #0) or (StrLen(Key) >= MAX_KV_LEN) or (StrLen(Value) >= MAX_KV_LEN) then
    Print('Keys and values must be lesser than 128 characters and greater than 0.')
   else
    begin
     Info_RemoveKey(S, Key);
     if Value^ > #0 then
      begin
       NewKV[1] := '\';
       P := StrLECopy(@NewKV[2], Key, SizeOf(NewKV) - 3);
       P^ := '\';
       Inc(UInt(P));
       StrLCopy(P, Value, UInt(@NewKV[High(NewKV)]) - UInt(P));
       L := StrLen(@NewKV);
       if StrLen(S) + L >= MaxSize then
        if not Info_IsKeyImportant(Key) then
         begin
          Print('Info string length exceeded.');
          Exit;
         end
        else
         begin
          repeat
           P := Info_FindLargestKey(S);
           if (P <> nil) and (P^ > #0) then
            Info_RemoveKey(S, P);       
          until (StrLen(S) + L < MaxSize) or (P^ = #0);

          if P^ = #0 then
           begin
            Print('Info string length exceeded.');
            Exit;
           end;
         end;

        Inc(UInt(S), StrLen(S));
        P := @NewKV;
        B := StrComp(Key, 'team') = 0;
        while P^ > #0 do
         begin
          C := P^;
          if (C >= ' ') and (C < #$7F) then
           if B then
            S^ := LowerC(C)
           else
            S^ := C;
          Inc(UInt(S));
          Inc(UInt(P));
         end;
        S^ := #0;
      end;
    end;
end;

procedure Info_SetValueForKey(S, Key, Value: PLChar; MaxSize: UInt);
begin
if Key^ = '*' then
 Print('Can''t set * keys.')
else
 Info_SetValueForStarKey(S, Key, Value, MaxSize);
end;

procedure Info_Print(S: PLChar);
var
 P, P2: PLChar;
 Buffer: array[1..1024] of LChar;
begin
if S^ = '\' then
 Inc(UInt(S));

while S^ > #0 do
 begin
  P := @Buffer;
  P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
  while (S^ <> '\') and (S^ > #0) and (UInt(P) < UInt(P2)) do
   begin
    P^ := S^;
    Inc(UInt(S));
    Inc(UInt(P));
   end;

  if UInt(P) - UInt(@Buffer) < 20 then
   begin
    MemSet(P^, 20 - (UInt(P) - UInt(@Buffer)), Ord(' '));
    P := @Buffer[Low(Buffer) + 20];
   end;

  if S^ = #0 then
   StrCopy(P, 'MISSING VALUE')
  else
   begin
    Inc(UInt(S));

    P2 := PLChar(UInt(P) + MAX_KV_LEN - 1);
    while (S^ <> '\') and (S^ > #0) and (UInt(P) < UInt(P2)) do
     begin
      P^ := S^;
      Inc(UInt(S));
      Inc(UInt(P));
     end;
    P^ := #0;

    if S^ > #0 then
     Inc(UInt(S));
   end;

  Print(@Buffer);
 end;
end;

function Info_IsValid(S: PLChar): Boolean;
var
 I: UInt;
begin
Result := False;

if S^ = '\' then
 Inc(UInt(S));

while S^ > #0 do
 begin
  I := 1;
  
  while S^ <> '\' do
   if (S = #0) or (I = MAX_KV_LEN) then
    Exit
   else
    begin
     Inc(UInt(S));
     Inc(I);
    end;

  if I = 1 then
   Exit;

  Inc(UInt(S));

  I := 1;
  while (S^ <> '\') and (S^ > #0) do
   if I = MAX_KV_LEN then
    Exit
   else
    begin
     Inc(UInt(S));
     Inc(I);
    end;
  
  if I = 1 then
   Exit;

  if S^ > #0 then
   Inc(UInt(S));

  if S^ = #0 then
   begin
    Result := True;
    Exit;
   end;
 end;
end;

end.
