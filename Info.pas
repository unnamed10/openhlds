unit Info;

{$I HLDS.inc}

interface

uses SysUtils, Default;

function Info_ValueForKey(S, Key: PLChar): PLChar;
procedure Info_RemoveKey(S, Key: PLChar);
procedure Info_RemovePrefixedKeys(S: PLChar; C: LChar);
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
 ValueBuf: array[0..7] of array [1..MAX_KV_LEN] of LChar;

function Info_ServerInfo: PLChar;
begin
Result := @ServerInfo;
end;

// true:
//   s <> nil: more pairs
//   s = nil: last pair
// false: stop
function Info_ExtractPair(var S: PLChar; Key, Value: PLChar): Boolean;
var
 S2, SEnd: PLChar;
begin
if S^ = #0 then
 begin
  Key^ := #0;
  Value^ := #0;
  S := nil;
  Result := True;
  Exit;
 end;

Result := False;
SEnd := PLChar(UInt(S) + MAX_KV_LEN);
S2 := Key;

while S^ <> '\' do
 if (S = SEnd) or (S^ = #0) then
  begin
   Key^ := #0;
   Exit;
  end
 else
  begin
   S2^ := S^;
   Inc(UInt(S));
   Inc(UInt(S2));
  end;

S2^ := #0;
Inc(UInt(S));

SEnd := PLChar(UInt(S) + MAX_KV_LEN);
S2 := Value;
while S^ <> '\' do
 if S = SEnd then
  begin
   Value^ := #0;
   Exit;
  end
 else
  begin
   S2^ := S^;
   if S^ = #0 then
    begin
     Result := True;
     Exit;
    end
   else
    begin
     Inc(UInt(S));
     Inc(UInt(S2));
    end;
  end;

S2^ := #0;
Inc(UInt(S));
Result := True;
end;

function Info_ValueForKey(S, Key: PLChar): PLChar;
var
 KeyBuf: array[1..MAX_KV_LEN] of LChar;
begin
if (S <> nil) and (Key <> nil) then
 if StrScan(Key, '\') <> nil then
  DPrint('Info_ValueForKey: Can''t use keys with a "\".')
 else
  begin
   ValueIndex := (ValueIndex + 1) and 7;
   if S^ = '\' then
    Inc(UInt(S));

   while Info_ExtractPair(S, @KeyBuf, @ValueBuf[ValueIndex]) and (S <> nil) do
    if StrComp(Key, @KeyBuf) = 0 then
     begin
      Result := @ValueBuf[ValueIndex];
      Exit;
     end;
  end;

Result := EmptyString;
end;

procedure Info_RemoveKey(S, Key: PLChar);
var
 S2: PLChar;
 KeyBuf, ValueBuf: array[1..MAX_KV_LEN] of LChar;
begin
if (S <> nil) and (Key <> nil) then
 if StrScan(Key, '\') <> nil then
  DPrint('Info_RemoveKey: Can''t use keys with a "\".')
 else
  begin
   if S^ = '\' then
    Inc(UInt(S));

   S2 := S;

   while Info_ExtractPair(S, @KeyBuf, @ValueBuf) and (S <> nil) do
    if StrComp(Key, @KeyBuf) = 0 then
     begin
      StrCopy(S2, S);
      if (S^ = #0) and (PLChar(UInt(S2) - 1)^ = '\') then
       PLChar(UInt(S2) - 1)^ := #0;
      Exit;
     end
    else
     S2 := S;
  end;
end;

procedure Info_RemovePrefixedKeys(S: PLChar; C: LChar);
var
 S2: PLChar;
 KeyBuf, ValueBuf: array[1..MAX_KV_LEN] of LChar;
begin
if (S <> nil) and (C > #0) then
 begin
  if S^ = '\' then
   Inc(UInt(S));

  S2 := S;

  while Info_ExtractPair(S, @KeyBuf, @ValueBuf) and (S <> nil) do
   if KeyBuf[1] = C then
    begin
     StrCopy(S2, S);
     if (S^ = #0) and (PLChar(UInt(S2) - 1)^ = '\') then
      PLChar(UInt(S2) - 1)^ := #0;
     S := S2;
    end
   else
    S2 := S;
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
          (StrComp(S, 'cl_lc') = 0) or
          (StrComp(S, 'cl_dlmax') = 0);
end;

function Info_FindLargestKey(S: PLChar; Key: PLChar; var KeyLen: UInt): Boolean;
var
 X: UInt;
 KeyBuf, ValueBuf: array[1..MAX_KV_LEN] of LChar;
begin
if S^ = '\' then
 Inc(UInt(S));

Key^ := #0;
KeyLen := 0;
Result := True;
while Info_ExtractPair(S, @KeyBuf, @ValueBuf) do
 if S = nil then
  Exit
 else
  if not Info_IsKeyImportant(@KeyBuf) then
   begin
    X := StrLen(@KeyBuf) + StrLen(@ValueBuf);
    if X > KeyLen then
     begin
      StrCopy(Key, @KeyBuf);
      KeyLen := X;
     end;
   end;

Result := False;
end;

procedure Info_SetValueForStarKey(S, Key, Value: PLChar; MaxSize: UInt);
var
 NewPair: array[1..MAX_KV_LEN * 3] of LChar;
 KeyBuf: array[1..MAX_KV_LEN] of LChar;
 S2: PLChar;
 L, KeyLen, ValueLen, LargestLen: UInt;
 C: LChar;
begin
if (S <> nil) and (Key <> nil) and (Value <> nil) and (MaxSize > 0) then
 if (StrScan(Key, '\') <> nil) or (StrScan(Value, '\') <> nil) then
  DPrint('Can''t use keys or values with a "\".')
 else
  if (StrPos(Key, '..') <> nil) or (StrPos(Value, '..') <> nil) then
   DPrint('Can''t use keys or values with a "..".')
  else
   if (StrScan(Key, '"') <> nil) or (StrScan(Value, '"') <> nil) then
    DPrint('Can''t use keys or values with a ".".')
   else
    begin
     KeyLen := StrLen(Key);
     ValueLen := StrLen(Value);
     if (Key^ = #0) or (KeyLen >= MAX_KV_LEN) or (ValueLen >= MAX_KV_LEN) then
      DPrint('Keys and values must be lesser than 128 characters.')
     else
      if Value^ = #0 then
       Info_RemoveKey(S, Key)
      else
       begin
        L := KeyLen + ValueLen + 2;
        if StrLen(S) + L >= MaxSize then
         if not Info_IsKeyImportant(Key) then
          begin
           DPrint('Info string length exceeded.');
           Exit;
          end
         else
          begin
           repeat
            if Info_FindLargestKey(S, @KeyBuf, LargestLen) and (LargestLen > 0) then
             Info_RemoveKey(S, @KeyBuf);
           until (LargestLen = 0) or (StrLen(S) + L < MaxSize);

           if LargestLen = 0 then
            begin
             DPrint('Info string length exceeded.');
             Exit;
            end;
          end;

        if S^ > #0 then
         begin
          S2 := PLChar(UInt(S) + StrLen(S) - 1);
          if S2^ = '\' then
           S2^ := #0;
         end;

        S2 := @NewPair;
        S2 := StrECopy(S2, '\');
        S2 := StrLECopy(S2, Key, MAX_KV_LEN - 1);
        S2 := StrECopy(S2, '\');
        StrLCopy(S2, Value, MAX_KV_LEN - 1);

        Info_RemoveKey(S, Key);
        L := StrLen(S);
        Inc(UInt(S), L);

        if StrComp(Key, 'team') = 0 then
         LowerCase(@NewPair);

        S2 := @NewPair;
        while S2^ > #0 do
         begin
          C := S2^;
          if (C >= ' ') and (C <= '~') then
           begin
            S^ := C;
            Inc(UInt(S));
           end;
          Inc(UInt(S2));
         end;
        S^ := #0;
       end;
    end;
end;

procedure Info_SetValueForKey(S, Key, Value: PLChar; MaxSize: UInt);
begin
if Key^ = '*' then
 DPrint('Can''t set * keys.')
else
 Info_SetValueForStarKey(S, Key, Value, MaxSize);
end;

procedure Info_Print(S: PLChar);
const
 Spacing: array[0..19] of LChar = '                   '#0;
var
 S2: PLChar;
 KeyBuf, ValueBuf: array[1..MAX_KV_LEN * 2] of LChar;
 L: UInt;
begin
if S <> nil then
 begin
  if S^ = '\' then
   Inc(UInt(S));
   
  while Info_ExtractPair(S, @KeyBuf, @ValueBuf) and (S <> nil) do
   begin
    L := StrLen(@KeyBuf);
    if L > High(Spacing) - 1 then
     L := High(Spacing) - 1;

    S2 := StrECopy(@KeyBuf[L + 1], @Spacing[L]);
    StrCopy(S2, @ValueBuf);
    Print(@KeyBuf);
   end;
 end;
end;

function Info_IsValid(S: PLChar): Boolean;
var
 KeyBuf, ValueBuf: array[1..MAX_KV_LEN] of LChar;
begin
if S <> nil then
 begin
  Result := True;

  if S^ = '\' then
   Inc(UInt(S));

  while Info_ExtractPair(S, @KeyBuf, @ValueBuf) do
   if S = nil then
    Exit;
 end;

Result := False;
end;

end.
