unit StdUI;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS}Windows, {$ELSE}Libc, {$ENDIF} Default, SDK;

procedure StdUI_Init;

implementation

uses Console, CoreUI;

type
 PUICmdList = ^TUICmdList;
 TUICmdList = record
  Cmd: array[1..1024] of LChar;
  Next: PUICmdList;
 end;

var
 std_ui_colorprint: TCVar = (Name: 'std_ui_colorprint'; Data: '0');
 
 CmdList: TUICmdList;
 ThreadHandle: THandle;
 MustExit: Boolean;

const
 DEF_CC = $10;
 
function TransformColorCode(var S: PLChar): Int;
const
 L: array[$0..$10] of PLChar =
    ('black', 'blue', 'green', 'aqua', 'red', 'purple', 'yellow', 'white',
     'ltblack', 'ltblue', 'ltgreen', 'ltaqua', 'ltred', 'ltpurple', 'ltyellow', 'ltwhite', 'def');
var
 I: Int;
 J: UInt;
begin
for I := Low(L) to High(L) do
 begin
  J := Length(L[I]);
  if (StrLComp(S, L[I], J) = 0) and (PLChar(UInt(S) + J)^ in [#0..' ']) then
   begin
    S := PLChar(UInt(S) + J + 1);
    Result := I;
    Exit;
   end;
 end;

if S^ in ['0'..'9'] then
 Result := Ord(S^) - Ord('0')
else
 if S^ in ['A'..'F'] then
  Result := Ord(S^) - Ord('A') + $A
 else
  if S^ = '^' then
   Result := DEF_CC
  else
   Result := -1;

if Result >= 0 then
 Inc(UInt(S));
end;

procedure OnPrint(Msg: PLChar); stdcall;
var
 S, S2, S3: PLChar;
 CB: TConsoleScreenBufferInfo;
 I: Int;
 H: THandle;
 CP: Boolean;

 procedure SetTextColor(C: UInt);
 begin
  if CP then
   SetConsoleTextAttribute(H, CB.wAttributes);
 end;
 
begin
S := StrPos(Msg, '^^');
if S = nil then
 Write(Msg)
else
 begin
  H := TTextRec(Output).Handle;
  CP := (std_ui_colorprint.Value <> 0) and GetConsoleScreenBufferInfo(H, CB);

  S2 := Msg;
  repeat
   S3 := PChar(UInt(S) + 2);
   I := TransformColorCode(S3);
   if I >= 0 then
    begin
     if S > S2 then
      Write(Copy(S2, 1, S - S2));

     if I = DEF_CC then
      SetTextColor(CB.wAttributes)
     else
      SetTextColor(I);
    end
   else
    Write(Copy(S2, 1, S - S2 + 2));

   S2 := S3;
   S := StrPos(S3, '^^');
  until S = nil;
  Write(S2);

  SetTextColor(CB.wAttributes);
 end;
end;

procedure ClearAllPendingCmds;
var
 P, P2: PUICmdList;
begin
P := CmdList.Next;
while P <> nil do
 begin
  P2 := P.Next;
  FreeMem(P);
  P := P2;
 end;

CmdList.Next := nil;
end;

procedure OnFrame(Time: Double); stdcall;
var
 P: PUICmdList;
begin
P := @CmdList;
while P <> nil do
 begin
  if P.Cmd[1] > #0 then
   Cmd_ExecuteString(@P.Cmd, csConsole);

  P := P.Next;
 end;

if CmdList.Next <> nil then
 ClearAllPendingCmds;
CmdList.Cmd[1] := #0;
end;

function SkipToEnd: PUICmdList;
var
 P: PUICmdList;
begin
Result := @CmdList;
P := CmdList.Next;
while P <> nil do
 begin
  Result := P;
  P := P.Next;
 end;
end;

function ThreadFunc(Parm: Pointer): Int32;
var
 Str: LStr;
 S: PLChar;
 P: PUICmdList;
begin
repeat
 Readln(Str);
 S := PLChar(Str);
 while S^ <= ' ' do
  if S^ = #0 then
   Break
  else
   Inc(UInt(S));

 if S^ > #0 then
  begin
   if CmdList.Next = nil then
    P := @CmdList
   else
    begin
     GetMem(P, SizeOf(P^));
     SkipToEnd.Next := P;
    end;

   StrLCopy(@P.Cmd, S, SizeOf(P.Cmd) - 1);
  end;
until MustExit;

Result := 0;
EndThread(0);
end;

procedure OnEngineReady(const Engine: TEngineFuncs); stdcall;
begin
CVar_RegisterVariable(std_ui_colorprint);
MustExit := False;
ThreadHandle := BeginThread(nil, 0, ThreadFunc, nil, 0, PUInt32(nil)^);
end;

procedure OnUnlink; stdcall;
begin
MustExit := True;
{$IFDEF MSWINDOWS}TerminateThread(ThreadHandle, 0){$ELSE}pthread_cancel(ThreadHandle){$ENDIF};
ClearAllPendingCmds;
end;

const
 UIFuncs: TUIFuncs =
  (OnPrint: OnPrint;
   OnFrame: OnFrame;
   OnEngineReady: OnEngineReady;
   OnAttach: nil;
   OnUnlink: OnUnlink);

procedure StdUI_Init;
begin
AttachExternalUI(UIFuncs);
end;

end.

