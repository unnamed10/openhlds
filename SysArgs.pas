unit SysArgs;

{$I HLDS.inc}

interface

uses {$IFDEF MSWINDOWS} Windows, {$ENDIF} Default;

procedure Sys_InitArgs;
procedure Sys_ShutdownArgs;

function COM_CheckParm(Name: PLChar): UInt;
function COM_ParmByIndex(Index: UInt): PLChar;
function COM_ParmValueByIndex(Index: UInt): PLChar;
function COM_ParmValueByName(Name: PLChar): PLChar;
function COM_GetParmCount: UInt;
function COM_GetLocalDir: PLChar;
function COM_ParmInBounds(Index: UInt): Boolean;

implementation

uses Memory, SysMain;

var
 ArgList: array of PLChar = nil;

 ArgCount: UInt = 0;
 ArgBuffer, ArgString: PLChar;

 InitDone: Boolean = False;

function GetArgCount(S: PLChar): UInt;
var
 C: LChar;
 SubCommand, ParseWord: Boolean;
begin
Result := 0;
if S = nil then
 Exit;

SubCommand := False;
ParseWord := False;

C := S^;

while True do
 begin
  case C of
   #0: Break;

   '"':
    if ParseWord then
     if SubCommand and (PLChar(UInt(S) + SizeOf(S^))^ in [#0..' ']) then
      begin
       ParseWord := False;
       SubCommand := False;
      end
     else
    else
     if not SubCommand then
      begin
       Inc(Result);
       SubCommand := True;
       ParseWord := True;
      end;
     
   ' ':
    if not SubCommand and ParseWord then
     ParseWord := False;

   else
    if not ParseWord then
     begin
      Inc(Result);
      ParseWord := True;
     end;
   end;

  Inc(UInt(S));
  C := S^;
 end;
end;

procedure WriteArgs(S: PLChar);
var
 C: LChar;
 SubCommand, ParseWord: Boolean;
 I: UInt;
 P: PLChar;
begin
if S = nil then
 Exit;

SubCommand := False;
ParseWord := False;

C := S^;
I := 0;

while True do
 begin
  case C of
   #0: Break; // unterminated string or string end

   '"':
    if ParseWord then
     if SubCommand and (PLChar(UInt(S) + SizeOf(S^))^ in [#0..' ']) then // subcommand end
      begin
       S^ := #0;
       ParseWord := False;
       SubCommand := False;
      end
     else // skip this character
    else
     if not SubCommand then
      begin
       P := PLChar(UInt(S) + SizeOf(S^));
       if P^ = #0 then
        ArgList[I] := EmptyString
       else
        ArgList[I] := P;
        
       Inc(I);

       SubCommand := True;
       ParseWord := True;
      end;

   ' ':
    if not SubCommand and ParseWord then
     begin
      S^ := #0;
      ParseWord := False;
     end;

   else
    if not ParseWord then
     begin
      ArgList[I] := S;
      Inc(I);
      ParseWord := True;
     end;
   end;

  Inc(UInt(S));
  C := S^;
 end;

// Last argument should be set to whitespace character.
ArgList[ArgCount - 1] := ' ';
end;

{$IFDEF LINUX}
procedure WriteArgsFromShell;
var
 I: Int;
 P: ^PLChar;
begin
P := System.argv;
for I := 0 to ArgCount - 2 do
 begin
  if P^ <> nil then
   ArgList[I] := Mem_StrDup(P^)
  else
   ArgList[I] := EmptyString;

  Inc(UInt(P), SizeOf(P));
 end;

ArgList[ArgCount - 1] := ' ';
end;
{$ENDIF}

procedure Sys_InitArgs;
begin
if InitDone then
 begin
  Sys_Error('Sys_InitArgs: Already initialized.');
  Exit;
 end;

{$IFDEF MSWINDOWS}
ArgBuffer := GetCommandLineA;
if ArgBuffer <> nil then
 begin
  ArgBuffer := Mem_StrDup(ArgBuffer);
  ArgString := Mem_StrDup(ArgBuffer);
 end
else
 ArgString := nil;

ArgCount := GetArgCount(ArgBuffer) + 1;
SetLength(ArgList, ArgCount);
WriteArgs(ArgBuffer);
{$ELSE}
ArgBuffer := nil;
ArgString := nil;

ArgCount := System.argc + 1;
SetLength(ArgList, ArgCount);
WriteArgsFromShell;
{$ENDIF}

InitDone := True;
end;

procedure Sys_ShutdownArgs;
{$IFDEF LINUX}
var
 I: Int;
{$ENDIF}
begin
if not InitDone then
 begin
  Sys_Error('Sys_InitArgs: Not initialized.');
  Exit;
 end;

{$IFDEF MSWINDOWS}
Mem_Free(ArgBuffer);
Mem_Free(ArgString);
{$ELSE}
for I := 0 to ArgCount - 2 do
 if ArgList[I] <> nil then
  Mem_Free(ArgList[I]);
{$ENDIF}

ArgList := nil;
InitDone := False;
end;


function COM_CheckParm(Name: PLChar): UInt;
var
 I: UInt;
begin
if (Name <> nil) and (ArgCount > 1) then
 for I := 1 to ArgCount - 1 do
  if StrComp(Name, ArgList[I]) = 0 then
   begin
    Result := I;
    Exit;
   end;

Result := 0;
end;

function COM_ParmByIndex(Index: UInt): PLChar;
begin
if (Index > 0) and (Index < ArgCount) then
 Result := ArgList[Index]
else
 Result := EmptyString;
end;

function COM_ParmValueByIndex(Index: UInt): PLChar;
begin
if (Index > 0) and (ArgCount > 2) and (Index < ArgCount - 1) then
 begin
  Result := ArgList[Index + 1];
  if (Result <> nil) and (Result^ in ['+', '-']) then
   Result := EmptyString;
 end
else
 Result := EmptyString;
end;

function COM_ParmValueByName(Name: PLChar): PLChar;
begin
if Name <> nil then
 Result := COM_ParmValueByIndex(COM_CheckParm(Name))
else
 Result := EmptyString;
end;

function COM_GetParmCount: UInt;
begin
Result := ArgCount;
end;

function COM_GetLocalDir: PLChar;
begin
Result := ArgList[Low(ArgList)];
end;

function COM_ParmInBounds(Index: UInt): Boolean;
begin
Result := (Index > 0) and (Index < ArgCount);
end;

end.
