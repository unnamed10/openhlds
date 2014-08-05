unit StdUI;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS}Windows, {$ELSE}Libc, {$ENDIF} Default, SDK;

procedure UI_OnPrint(S: PLChar);
procedure UI_OnFrame(Time: Double);
procedure UI_OnEngineReady(const Engine: TEngineFuncs);

procedure UI_Init;
procedure UI_Shutdown;

type
 PExternalUI = ^TExternalUI;
 TExternalUI = record
  OnPrint: procedure(S: PLChar); stdcall;
  OnFrame: procedure(Time: Double); stdcall;
  OnEngineReady: procedure(const Engine: TEngineFuncs); stdcall;

  OnAttach: procedure; stdcall;
  OnUnlink: procedure; stdcall;
 end;

implementation

uses Console, GameLib, Memory, Host, Server, SysMain, SVClient;

const
 MAX_UI_CMD_LEN = 8192;
 
type
 PExternalUIInfo = ^TExternalUIInfo;
 TExternalUIInfo = record
  Handle: THandle;
  UI: PExternalUI;

  Prev, Next: PExternalUIInfo;
 end;

 PUICmdList = ^TUICmdList;
 TUICmdList = record
  Cmd: array[1..MAX_UI_CMD_LEN] of LChar;
  Next: PUICmdList;
 end;

var
 ui_printstats: TCVar = (Name: 'ui_printstats'; Data: '0'); 
 ui_updatetime: TCVar = (Name: 'ui_updatetime'; Data: '1.0'; Flags: [FCVAR_SERVER]);
 LastUpdateTime: Double = 0;

 Externals: PExternalUIInfo = nil;
 CmdList: TUICmdList;
 LastCmd: PUICmdList = @CmdList;

 ThreadHandle: UInt;
 ThreadID: UInt32;
 ConsoleCS: TCriticalSection;

{$IFDEF MSWINDOWS}
var
 TextAttr: Byte;

procedure SetBkColor(Color: UInt);
begin
SetConsoleTextAttribute(TTextRec(Output).Handle, (TextAttr and $F) or ((Color shl 4) and $F0));
end;

procedure SetTextColor(Color: UInt);
begin
SetConsoleTextAttribute(TTextRec(Output).Handle, (TextAttr and $F0) or (Color and $F));
end;

procedure RestoreColor;
begin
SetConsoleTextAttribute(TTextRec(Output).Handle, TextAttr);
end;

procedure WriteStats;
var
 BufferInfo: TConsoleScreenBufferInfo;
 Pos: TCoord;
 Players: UInt;
 IntBuf1, IntBuf2, IntBuf3, ExpandBuf1, ExpandBuf2, ExpandBuf3: array[1..32] of LChar;
 Time, Hour, Min, Sec: UInt;
begin
GetConsoleScreenBufferInfo(TTextRec(Output).Handle, BufferInfo);
TextAttr := BufferInfo.wAttributes;
Pos.X := 0;
Pos.Y := 0;
SetConsoleCursorPosition(TTextRec(Output).Handle, Pos);

SetBkColor(5);
SetTextColor(15);

SV_CountPlayers(Players);
Time := Trunc(RealTime);
Sec := Time mod 60;
Time := Time div 60;
Min := Time mod 60;
Time := Time div 60;
Hour := Time;

Write('Server: ', Players, '/', SVS.MaxClients, ' ',
      ExpandString(IntToStr(Hour, IntBuf1, SizeOf(IntBuf1)), @ExpandBuf1, SizeOf(ExpandBuf1), 2), ':',
      ExpandString(IntToStr(Min, IntBuf2, SizeOf(IntBuf2)), @ExpandBuf2, SizeOf(ExpandBuf2), 2), ':',
      ExpandString(IntToStr(Sec, IntBuf3, SizeOf(IntBuf3)), @ExpandBuf3, SizeOf(ExpandBuf3), 2));

RestoreColor;
SetConsoleCursorPosition(TTextRec(Output).Handle, BufferInfo.dwCursorPosition);
end;

{$ELSE}

procedure WriteStats;
begin
// Windows only
end;

{$ENDIF}

procedure UI_OnPrint(S: PLChar);
var
 P: PExternalUIInfo;
begin
P := Externals;
if P = nil then
 Writeln(S)
else
 repeat
  if @P.UI.OnPrint <> nil then
   P.UI.OnPrint(S);
  P := P.Next;
 until P = nil;
end;

procedure UI_OnFrame(Time: Double);
var
 P: PExternalUIInfo;
 P2, P3: PUICmdList;
begin
P := Externals;
if P = nil then
 begin
  Sys_EnterCS(ConsoleCS);

  if CmdList.Cmd[1] > #0 then
   Cmd_ExecuteString(@CmdList.Cmd, csServer);

  if LastCmd = nil then
   LastCmd := @CmdList;

  P2 := LastCmd.Next;
  while P2 <> nil do
   begin
    P3 := P2.Next;

    if P2.Cmd[1] > #0 then
     Cmd_ExecuteString(@P2.Cmd, csServer);

    Mem_Free(P2);
    P2 := P3;
   end;

  CmdList.Cmd[1] := #0;
  CmdList.Next := nil;
  LastCmd := @CmdList;

  // Write stats.
  if (ui_printstats.Value <> 0) and (LastUpdateTime < Time) then
   begin
    LastUpdateTime := Time + ui_updatetime.Value;
    WriteStats;
   end;
  
  Sys_LeaveCS(ConsoleCS);
 end
else
 repeat
  if @P.UI.OnFrame <> nil then
   P.UI.OnFrame(Time);
  P := P.Next;
 until P = nil;                                  
end;

function ThreadFunc(Parameter: Pointer): Int32;
var
 Str: LStr;
 S, S2: PLChar;
 P: PUICmdList;
begin
while True do
 begin
  Readln(Str);
  S := PLChar(Str);
  while S^ <= ' ' do
   if S^ = #0 then
    Break
   else
    Inc(UInt(S));

  if (S^ = #0) or (StrLen(S) >= MAX_UI_CMD_LEN) then
   Continue;

  Sys_EnterCS(ConsoleCS);
  if CmdList.Cmd[1] = #0 then // have a single free node
   P := @CmdList
  else // alloc new node
   P := Mem_Alloc(SizeOf(P^));

  if P <> @CmdList then
   begin
    LastCmd.Next := P;
    LastCmd := P;
   end;

  S2 := @P.Cmd;
  while S^ > #0 do
   if S^ < ' ' then
    Break
   else
    begin
     S2^ := S^;
     Inc(UInt(S));
     Inc(UInt(S2));
    end;
  S2^ := #0;
  Sys_LeaveCS(ConsoleCS);
 end;

Result := 0;
end;

procedure UI_OnEngineReady(const Engine: TEngineFuncs);
var
 P: PExternalUIInfo;
begin
P := Externals;
if P = nil then
 begin
  Sys_InitCS(ConsoleCS);
  if ThreadHandle = 0 then
   ThreadHandle := BeginThread(nil, 0, ThreadFunc, nil, 0, ThreadID);

  CVar_RegisterVariable(ui_printstats);
  CVar_RegisterVariable(ui_updatetime);
 end
else
 repeat
  if @P.UI.OnEngineReady <> nil then
   P.UI.OnEngineReady(Engine);
  P := P.Next;
 until P = nil;
end;


procedure UI_Init;
begin

end;

procedure UI_Shutdown;
var
 P, P2: PExternalUIInfo;
begin
{$IFDEF MSWINDOWS}TerminateThread(ThreadHandle, 0){$ELSE}pthread_cancel(ThreadHandle){$ENDIF};
Sys_DeleteCS(ConsoleCS);

P := Externals;
while P <> nil do
 begin
  P2 := P.Next;
  if @P.UI.OnUnlink <> nil then
   P.UI.OnUnlink;
  Mem_Free(P);
  P := P2;                          
 end;
end;

procedure UI_FindExternalHandlers;
begin

end;

end.

