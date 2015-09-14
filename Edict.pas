unit Edict;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

function PvAllocEntPrivateData(var E: TEdict; Size: Int): Pointer;
function PvEntPrivateData(const E: TEdict): Pointer;
procedure FreeEntPrivateData(var E: TEdict);
procedure FreeAllEntPrivateData;
procedure InitEntityDLLFields(var E: TEdict);
procedure ReleaseEntityDLLFields(var E: TEdict);

function EDICT_NUM(I: UInt): PEdict;
function NUM_FOR_EDICT(const E: TEdict): UInt;

function ED_Alloc: PEdict;
procedure ED_Free(var E: TEdict);
procedure ED_Count_F; cdecl;
function ED_NewString(S: PLChar): PLChar;
procedure ED_LoadFromFile(P: Pointer);

procedure ExtractClassname(P: Pointer; var E: TEdict);

implementation

uses Common, Console, GameLib, Host, MathLib, Memory, SVMain, SysMain, SVWorld;

function PvAllocEntPrivateData(var E: TEdict; Size: Int): Pointer;
begin
FreeEntPrivateData(E);
if Size <= 0 then
 Result := nil
else
 begin
  E.PrivateData := Mem_ZeroAlloc(Size);
  Result := E.PrivateData;
 end;
end;

function PvEntPrivateData(const E: TEdict): Pointer;
begin
if @E <> nil then
 Result := E.PrivateData
else
 Result := nil;
end;

procedure FreeEntPrivateData(var E: TEdict);
begin
if E.PrivateData <> nil then
 begin
  if @NewDLLFunctions.OnFreeEntPrivateData <> nil then
   NewDLLFunctions.OnFreeEntPrivateData(E);
  Mem_FreeAndNil(E.PrivateData);
 end;
end;

procedure FreeAllEntPrivateData;
var
 I: Int;
begin
for I := 0 to SV.NumEdicts - 1 do
 FreeEntPrivateData(SV.Edicts[I]);
end;

procedure InitEntityDLLFields(var E: TEdict);
begin
E.V.ContainingEntity := @E;
end;

procedure ReleaseEntityDLLFields(var E: TEdict);
begin
FreeEntPrivateData(E);
end;

function EDICT_NUM(I: UInt): PEdict;
begin
if I >= SV.MaxEdicts then
 Sys_Error(['EDICT_NUM: Bad edict number #', I, '.']);

Result := @SV.Edicts[I];
end;

function NUM_FOR_EDICT(const E: TEdict): UInt;
begin
Result := (UInt(@E) - UInt(SV.Edicts)) div SizeOf(TEdict);
if Result >= SV.NumEdicts then
 Sys_Error(['NUM_FOR_EDICT: Bad edict pointer.']);
end;

procedure ED_ClearEdict(var E: TEdict);
begin
MemSet(E.V, SizeOf(E.V), 0);
E.Free := 0;
ReleaseEntityDLLFields(E);
InitEntityDLLFields(E);
end;

function ED_Alloc: PEdict;
var
 I: Int;
 E: PEdict;
begin
for I := SVS.MaxClients + 1 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  if (E.Free <> 0) and ((E.FreeTime < 2) or (SV.Time - E.FreeTime > 0.5)) then
   begin
    ED_ClearEdict(E^);
    Result := E;
    Exit;
   end;
 end;

if SV.NumEdicts >= SV.MaxEdicts then
 if SV.MaxEdicts = 0 then
  Sys_Error('ED_Alloc: No edicts yet.')
 else
  Sys_Error('ED_Alloc: No free edicts.');

Result := @SV.Edicts[SV.NumEdicts];
Inc(SV.NumEdicts);
ED_ClearEdict(Result^);
end;

procedure ED_Free(var E: TEdict);
begin
if E.Free = 0 then
 begin
  SV_UnlinkEdict(E);
  FreeEntPrivateData(E);

  E.V.Flags := 0;
  E.V.Model := 0;
  E.V.TakeDamage := 0;
  E.V.ModelIndex := 0;
  E.V.ColorMap := 0;
  E.V.Skin := 0;
  E.V.Frame := 0;
  E.V.Scale := 0;
  E.V.Gravity := 0;
  E.V.Origin := Vec3Origin;
  E.V.Angles := Vec3Origin;
  E.V.Solid := 0;
  E.V.NextThink := -1;
  
  E.Free := 1;
  E.FreeTime := SV.Time;
  Inc(E.SerialNumber);  
 end;
end;

function ED_NewString(S: PLChar): PLChar;
var
 I, L: UInt;
 Dst: PLChar;
begin
L := StrLen(S) + 1;
Dst := Hunk_Alloc(L);
Result := Dst;

for I := 0 to L - 1 do
 begin
  if S^ = '\' then
   begin
    Inc(UInt(S));
    if S^ = 'n' then
     Dst^ := #10
    else
     Dst^ := '\';
   end
  else
   Dst^ := S^;

  Inc(UInt(S));
  Inc(UInt(Dst));
 end;
end;

procedure ExtractClassname(P: Pointer; var E: TEdict);
var
 ClassName: array[1..1024] of LChar;
 KVD: TKeyValueData;
begin
while P <> nil do
 begin
  P := COM_Parse(P);
  if (P = nil) or (COM_Token[Low(COM_Token)] = '}') then
   Break;

  if StrIComp(@COM_Token, 'classname') = 0 then
   begin
    StrLCopy(@ClassName, @COM_Token, SizeOf(ClassName) - 1);
    COM_Parse(P);
    KVD.Classname := nil;
    KVD.Key := @ClassName;
    KVD.Value := @COM_Token;
    KVD.Handled := 0;
    DLLFunctions.KeyValue(E, @KVD);
    if KVD.Handled = 0 then
     Sys_Error('ExtractClassname: Parsing error.' + LineBreak +
               'The game DLL seems to be incorrectly handling the KeyValue calls.');
    Exit;
   end
  else
   P := COM_Parse(P);
 end;
end;

function ED_ParseEdict(P: Pointer; var E: TEdict): Pointer;
var
 ClassName: PLChar;
 F: TEntityInitFunc;
 KVD: TKeyValueData;
 Key: array[1..256] of LChar;
 I: UInt;
 J: Single;
begin
if @E <> @SV.Edicts[0] then
 MemSet(E.V, SizeOf(E.V), 0);

InitEntityDLLFields(E);
ExtractClassname(P, E);

ClassName := PLChar(PRStrings + E.V.ClassName);
F := GetDispatch(ClassName);
if @F <> nil then
 F(E.V)
else
 begin
  F := GetDispatch('custom');
  if @F <> nil then
   begin
    F(E.V);
    KVD.Classname := 'custom';
    KVD.Key := 'customclass';
    KVD.Value := ClassName;
    KVD.Handled := 0;
    DLLFunctions.KeyValue(E, @KVD);    
   end
  else
   DPrint(['Can''t init entity "', ClassName, '".']);
 end;

while True do
 begin
  P := COM_Parse(P);
  if P = nil then
   Sys_Error('ED_ParseEdict: EOF without closing brace.')
  else
   if COM_Token[Low(COM_Token)] = '}' then
    Break;

  StrLCopy(@Key, @COM_Token, SizeOf(Key) - 1);
  for I := StrLen(@Key) downto 1 do
   if Key[I] = ' ' then
    Key[I] := #0
   else
    Break;

  P := COM_Parse(P);
  if P = nil then
   Sys_Error('ED_ParseEdict: EOF without closing brace.')
  else
   if COM_Token[Low(COM_Token)] = '}' then
    Sys_Error('ED_ParseEdict: Closing brace without data.');

  if StrIComp(@Key, 'angle') = 0 then
   begin
    J := StrToFloatDef(PLChar(@COM_Token), 0);
    if J = -1 then
     StrCopy(@COM_Token, '-90 0 0')
    else
     if J < 0 then
      StrCopy(@COM_Token, '90 0 0')
     else
      FormatBuf(COM_Token, SizeOf(COM_Token), '%f %f %f%s', StrLen('%f %f %f%s'), [E.V.Angles[0], J, E.V.Angles[2], #0]);
    StrCopy(@Key, 'angles');
   end;

  if StrIComp(@Key, ClassName) <> 0 then
   begin
    KVD.Classname := ClassName;
    KVD.Key := @Key;
    KVD.Value := @COM_Token;
    KVD.Handled := 0;
    DLLFunctions.KeyValue(E, @KVD);
   end;  
 end;

if @F = nil then
 begin
  E.Free := 1;
  Inc(E.SerialNumber);
 end;

Result := P;
end;

procedure ED_LoadFromFile(P: Pointer);
var
 E: PEdict;
 I: UInt;
begin
GlobalVars.Time := SV.Time;
E := nil;
I := 0;

while True do
 begin
  P := COM_Parse(P);
  if P = nil then
   Break
  else
   if COM_Token[Low(COM_Token)] <> '{' then
    Sys_Error(['ED_LoadFromFile: Found "', PLChar(@COM_Token), '" when expecting {.']);

  if E <> nil then
   E := ED_Alloc
  else
   begin
    E := @SV.Edicts[0];
    ReleaseEntityDLLFields(E^);
    InitEntityDLLFields(E^);
   end;

  P := ED_ParseEdict(P, E^);
  if E.Free = 0 then
   if (deathmatch.Value <> 0) and ((E.V.SpawnFlags and SPAWNFLAG_NOT_DEATHMATCH) > 0) then
    begin
     ED_Free(E^);
     Inc(I);
    end
   else
    if E.V.ClassName = 0 then
     begin
      Print('ED_LoadFromFile: No classname for entity.');
      ED_Free(E^);
     end
    else
     if (DLLFunctions.Spawn(E^) < 0) or ((E.V.Flags and FL_KILLME) > 0) then
      ED_Free(E^);
 end;

if I > 0 then
 DPrint([I, ' entities inhibited.']); 
end;

procedure ED_Count_F; cdecl;
var
 I: Int;
 E: PEdict;
 Active, Free, View, Touch, Step, Push: UInt;
 Ext: Boolean;
begin
Active := 0;
Free := 0;
View := 0;
Touch := 0;
Step := 0;
Push := 0;
Ext := (Cmd_Argc = 2) and (StrIComp(Cmd_Argv(1), 'ext') = 0);

for I := 0 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  if E.Free = 0 then
   begin
    Inc(Active);
    if E.V.Model <> 0 then
     Inc(View);
    if E.V.Solid <> 0 then
     Inc(Touch);
    if E.V.MoveType = MOVETYPE_STEP then
     Inc(Step)
    else
     if E.V.MoveType = MOVETYPE_PUSH then
      Inc(Push);

    if Ext then
     Print(['#', I + 1, ': ', PLChar(PRStrings + E.V.Classname)]);
   end
  else
   Inc(Free);
 end;

Print(['Edicts:' + LineBreak +
       '- Total: ', SV.NumEdicts, ';' + LineBreak +
       '- Alloc: ', Active, ';' + LineBreak +
       '- Free: ', Free, ';' + LineBreak +
       '- View: ', View, ';' + LineBreak +
       '- Touch: ', Touch, ';' + LineBreak +
       '- Step: ', Step, ';' + LineBreak +
       '- Push: ', Push, '.']);
end;

end.
