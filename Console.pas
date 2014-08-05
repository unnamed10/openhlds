unit Console;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure Con_PrintF(Msg: PLChar);

procedure Print(Msg: PLChar); overload;
procedure Print(const Msg: array of const); overload;

procedure Con_DPrintF(Msg: PLChar);

procedure DPrint(Msg: PLChar); overload;
procedure DPrint(const Msg: array of const); overload;

procedure CVar_Init;
procedure CVar_Shutdown;
function CVar_FindVar(Name: PLChar): PCVar;
function CVar_FindPrevVar(Name: PLChar): PCVar;
function CVar_VariableValue(Name: PLChar): Single;
function CVar_VariableInt(Name: PLChar): Int;
function CVar_VariableString(Name: PLChar): PLChar;
function CVar_CompleteVariable(Name: PLChar; NextCVar: Boolean): PLChar;
procedure CVar_DirectSet(var C: TCVar; Value: PLChar);
procedure CVar_Set(Name, Value: PLChar);
procedure CVar_SetValue(Name: PLChar; Value: Single);
procedure CVar_RegisterVariable(var C: TCVar);
procedure CVar_RemoveHUDCVars;
function CVar_IsMultipleTokens(Name: PLChar): PLChar;
function CVar_Command: Boolean;
procedure CVar_WriteVariables(F: TFile);
procedure Cmd_CVarList; cdecl;
function CVar_CountServerVariables: UInt;
procedure CVar_UnlinkExternals;
procedure CVar_CmdInit;

procedure CBuf_Init;
procedure CBuf_AddText(Text: PLChar); overload;
procedure CBuf_AddText(const Text: array of const); overload;
procedure CBuf_InsertText(Text: PLChar);
procedure CBuf_InsertTextLines(Text: PLChar);
procedure CBuf_Execute;

procedure Cmd_StuffCmds; cdecl;
procedure Cmd_Exec; cdecl;
procedure Cmd_Echo; cdecl;
procedure Cmd_Alias; cdecl;
procedure Cmd_Wait; cdecl;
procedure Cmd_CmdList; cdecl;
function Cmd_GetFirstCmd: PCommand;

procedure Cmd_Init;
procedure Cmd_Shutdown;
function Cmd_Argc: UInt;
function Cmd_Argv(Index: UInt): PLChar;
function Cmd_Args: PLChar;
procedure Cmd_TokenizeString(Data: PLChar);
function Cmd_FindCmd(Name: PLChar): PCommand;
function Cmd_FindPrevCmd(Name: PLChar): PCommand;
procedure Cmd_AddCommand(Name: PLChar; Func: TCmdFunction);
procedure Cmd_AddMAllocCommand(Name: PLChar; Func: TCmdFunction; Flags: UInt);
procedure Cmd_AddHUDCommand(Name: PLChar; Func: TCmdFunction);
procedure Cmd_AddGameCommand(Name: PLChar; Func: TCmdFunction);
procedure Cmd_AddWrapperCommand(Name: PLChar; Func: TCmdFunction);
procedure Cmd_RemoveMAllocedCmds(Flags: UInt);
procedure Cmd_RemoveHUDCmds;
procedure Cmd_RemoveGameCmds;
procedure Cmd_RemoveWrapperCmds;
function Cmd_Exists(Name: PLChar): Boolean;
function Cmd_CompleteCommand(Name: PLChar; NextCmd: Boolean): PLChar;
procedure Cmd_ExecuteString(Text: PLChar; Source: TCmdSource);
procedure Cmd_ForwardToServer; cdecl;
procedure Cmd_ForwardToServerUnreliable;
function Cmd_CheckParm(Name: PLChar): UInt;

procedure Cmd_Debug_F; cdecl;
procedure Con_DebugLog(FileName, Msg: PLChar); overload;
procedure Con_DebugLog(FileName: PLChar; const Msg: array of const); overload;
procedure Con_SafePrintF(Msg: PLChar); overload;
procedure Con_SafePrintF(const Msg: array of const); overload;

procedure Con_Init;
procedure Con_Shutdown;

procedure LPrint(Msg: PLChar); overload;
procedure LPrint(const Msg: array of const); overload;

procedure Log_PrintF(Msg: PLChar);
procedure Log_PrintServerVars;
procedure Log_Close;
procedure Log_Open;

var
 CmdSource: TCmdSource;
 CVarBase: PCVar = nil;
 CmdBase: PCommand = nil;
 AliasBase: PAlias = nil;

implementation

uses Common, FileSys, Info, Host, Memory, Network, Server, StdUI, SVClient, SysArgs, SysMain, SVCmds, SVRcon;

var
 LastPartialCVar: array[1..516] of LChar;
 FirstToken: array[1..204] of LChar;
 
 CmdArgc: UInt;
 CmdArgv: array[0..MAX_CMD_ARGS - 1] of PLChar;
 CmdArgs: PLChar;

 DebugLog: Boolean = False;

procedure Con_PrintF(Msg: PLChar);
begin
UI_OnPrint(Msg);

if RedirectType <> srNone then
 begin
  if StrLen(Msg) + StrLen(@RedirectBuf) >= SizeOf(RedirectBuf) - 1 then
   SV_FlushRedirect;
  StrLCat(@RedirectBuf, Msg, SizeOf(RedirectBuf) - 1);
 end;

if DebugLog then
 Con_DebugLog('qconsole.log', Msg);
end;

procedure Con_DPrintF(Msg: PLChar);
begin
if developer.Value <> 0 then
 begin
  UI_OnPrint(Msg);
  if DebugLog then
   Con_DebugLog('qconsole.log', Msg);
 end;
end;

procedure Print(Msg: PLChar);
begin
Con_PrintF(Msg);
end;

procedure Print(const Msg: array of const);
begin
Con_PrintF(PLChar(StringFromVarRec(Msg)));
end;

procedure DPrint(Msg: PLChar);
begin
Con_DPrintF(Msg);
end;

procedure DPrint(const Msg: array of const);
begin
if developer.Value <> 0 then
 Con_DPrintF(PLChar(StringFromVarRec(Msg)));
end;


// CVars

procedure CVar_Init;
begin

end;

procedure CVar_Shutdown;
begin
CVarBase := nil;
end;

function CVar_FindVar(Name: PLChar): PCVar;
begin
if Name <> nil then
 begin
  Result := CVarBase;
  while Result <> nil do
   if StrIComp(Result.Name, Name) = 0 then
    Exit
   else
    Result := Result.Next;
 end
else
 Result := nil;
end;

function CVar_FindPrevVar(Name: PLChar): PCVar;
var
 P: PCVar;
begin
if Name <> nil then
 begin
  Result := CVarBase;

  while Result <> nil do
   begin
    P := Result.Next;
    if P = nil then
     Break
    else
     if StrIComp(P.Name, Name) = 0 then
      Exit
     else
      Result := P;
   end;
 end;

Result := nil;
end;

function CVar_VariableValue(Name: PLChar): Single;
var
 C: PCVar;
begin
C := CVar_FindVar(Name);
if (C <> nil) and (C.Data <> nil) then
 Result := StrToFloatDef(C.Data, 0)
else
 Result := 0;
end;

function CVar_VariableInt(Name: PLChar): Int;
var
 F: Single;
begin
F := CVar_VariableValue(Name);
if Frac(F) = 0 then
 Result := Trunc(F)
else
 Result := 0;
end;

function CVar_VariableString(Name: PLChar): PLChar;
var
 C: PCVar;
begin
C := CVar_FindVar(Name);
if C <> nil then
 Result := C.Data
else
 Result := EmptyString;
end;

function CVar_CompleteVariable(Name: PLChar; NextCVar: Boolean): PLChar;
var
 Buffer: array[1..256] of LChar;
 L: UInt;
 P, P2: PCVar;
begin
StrLCopy(@Buffer, Name, High(Buffer) - 1);
Buffer[High(Buffer)] := #0;

L := StrLen(@Buffer);
if L = 0 then
 Result := nil
else
 begin
  while (L > Low(Buffer)) and (Buffer[L - 1] = ' ') do
   begin
    Buffer[L - 1] := #0;
    Dec(L);
   end;

  if StrIComp(@Buffer, @LastPartialCVar) = 0 then
   begin
    P := CVar_FindVar(@Buffer);
    if P <> nil then
     begin
      if NextCVar then
       P2 := P.Next
      else
       P2 := CVar_FindPrevVar(P.Name);
      if P2 <> nil then
       begin
        StrLCopy(@LastPartialCVar, P2.Name, High(LastPartialCVar) - 1);
        LastPartialCVar[High(LastPartialCVar)] := #0;
        Result := P2.Name;
        Exit;
       end;
     end;
   end;

  P := CVarBase;
  while True do
   if (P = nil) or (P.Next = nil) then
    begin
     Result := nil;
     Exit;
    end
   else
    if StrLComp(@Buffer, P.Name, L) <> 0 then
     P := P.Next
    else
     Break;

  StrLCopy(@LastPartialCVar, P.Name, High(LastPartialCVar) - 1);
  LastPartialCVar[High(LastPartialCVar)] := #0;
  Result := P.Name;
 end;
end;

procedure CVar_DirectSet(var C: TCVar; Value: PLChar);
var
 Buffer: array[1..1024] of LChar;
 S: PLChar;
 L: UInt;
 B: Boolean;
begin
if (@C = nil) or (Value = nil) then
 Exit;

S := Value;
if FCVAR_PRINTABLEONLY in C.Flags then
 begin
  L := 0;
  while (S^ > #0) and (L < High(Buffer) - 1) do
   begin
    if S^ in [' '..'~'] then
     begin
      Inc(L);
      Buffer[L] := S^;
     end;

    Inc(UInt(S));
   end;

  if L = 0 then
   StrCopy(@Buffer, 'empty')
  else
   Buffer[L + 1] := #0;

  S := @Buffer;
 end
else
 L := StrLen(Value);

B := StrComp(C.Data, S) <> 0;
if FCVAR_USERINFO in C.Flags then
 begin
  Info_SetValueForKey(Info_ServerInfo, C.Name, S, SizeOf(ServerInfo));
  SV_BroadcastCommand(['fullserverinfo "', Info_ServerInfo, '"'#10]);
 end;

if (FCVAR_SERVER in C.Flags) and B and not (FCVAR_UNLOGGED in C.Flags) then
 if FCVAR_PROTECTED in C.Flags then
  begin
   LPrint(['Server cvar "', C.Name, '" = "***PROTECTED***"'#10]);
   SV_BroadcastPrint(['"', C.Name, '" changed to "***PROTECTED***"']);
  end
 else
  begin
   LPrint(['Server cvar "', C.Name, '" = "', S, '"'#10]);
   SV_BroadcastPrint(['"', C.Name, '" changed to "', S, '"']);
  end;

Z_Free(C.Data);
C.Data := Z_MAlloc(L + 1);
StrLCopy(C.Data, S, L);
C.Value := StrToFloatDef(C.Data, 0);
end;

procedure CVar_Set(Name, Value: PLChar);
var
 C: PCVar;
begin
C := CVar_FindVar(Name);
if C <> nil then
 CVar_DirectSet(C^, Value)
else
 DPrint(['CVar_Set: Variable "', Name, '" not found.']);
end;

procedure CVar_SetValue(Name: PLChar; Value: Single);
var
 IntBuf: array[1..64] of LChar;
begin
if Frac(Value) > 0 then
 CVar_Set(Name, PLChar(FloatToStr(Value)))
else
 CVar_Set(Name, IntToStr(Trunc(Value), IntBuf, SizeOf(IntBuf)));
end;

procedure CVar_RegisterVariable(var C: TCVar);
var
 P: PLChar;
 C2: PCVar;
begin
if @C = nil then
 Print('CVar_RegisterVariable: Invalid variable pointer.')
else
 if CVar_FindVar(C.Name) <> nil then
  Print(['CVar_RegisterVariable: Can''t register variable "', C.Name, '", already defined.'])
 else
  if Cmd_Exists(C.Name) then
   Print(['CVar_RegisterVariable: "', C.Name, '" is a command.'])
  else
   begin
    P := C.Data;
    C.Data := Z_MAlloc(StrLen(P) + 1);
    StrCopy(C.Data, P);
    C.Value := StrToFloatDef(C.Data, 0);

    if (CVarBase = nil) or (StrIComp(C.Name, CVarBase.Name) <= 0) then
     begin
      C.Next := CVarBase;
      CVarBase := @C;
     end
    else
     begin
      C2 := CVarBase;
      while (C2.Next <> nil) and (StrIComp(C.Name, C2.Next.Name) > 0) do
       C2 := C2.Next;

      C.Next := C2.Next;
      C2.Next := @C;
     end;
   end;
end;

procedure CVar_RemoveHUDCVars;
var
 C, C2, P: PCVar;
begin
C := CVarBase;
P := nil;
while C <> nil do
 begin
  C2 := C.Next;
  if FCVAR_CLIENTDLL in C.Flags then
   begin
    Z_Free(C.Data);
    Z_Free(C);
   end
  else
   begin
    C.Next := P;
    P := C;
   end;

  C := C2;
 end;

CVarBase := nil;
C := nil;

while P <> nil do
 begin
  C2 := P.Next;
  P.Next := C;
  C := C2;
 end;

CVarBase := C;
end;

function CVar_IsMultipleTokens(Name: PLChar): PLChar;
var
 Count: UInt;
begin
Count := 0;
FirstToken[Low(FirstToken)] := #0;

while True do
 begin
  Name := COM_Parse(Name);
  if COM_Token[Low(COM_Token)] = #0 then
   Break;

  if Count = 0 then
   begin
    StrLCopy(@FirstToken, @COM_Token, High(FirstToken) - 1);
    COM_Token[High(COM_Token)] := #0;
   end;
   
  Inc(Count);
 end;

if Count = 1 then
 Result := nil
else
 Result := @FirstToken;
end;

function CVar_Command: Boolean;
var
 C: PCVar;
 P, P2: PLChar;
begin
Result := False;
P := Cmd_Argv(0);
if P <> nil then
 begin
  P2 := CVar_IsMultipleTokens(P);
  if P2 <> nil then
   begin
    C := CVar_FindVar(P2);
    if C <> nil then
     begin
      Print(['"', C.Name, '" is "', C.Data, '"']);
      Result := True;
     end;
   end
  else
   begin
    C := CVar_FindVar(P);
    if C <> nil then
     begin
      if Cmd_Argc <= 1 then
       Print(['"', C.Name, '" is "', C.Data, '"'])
      else
       CVar_Set(C.Name, Cmd_Argv(1));

      Result := True;
     end;
   end;
 end;
end;

procedure CVar_WriteVariables(F: TFile);
var
 C: PCVar;
begin
C := CVarBase;
while C <> nil do
 begin
  if FCVAR_ARCHIVE in C.Flags then
   FS_FPrintF(F, [C.Name, ' "', C.Data, '"'], True);

  C := C.Next;
 end;
end;

procedure Cmd_CVarListPrintCVar(C: PCVar; F: TFile);
var
 Buf: array[1..2048] of LChar;
 IntBuf: array[1..64] of LChar;
begin
if C = nil then
 Exit;

StrLCopy(@Buf, C.Name, SizeOf(Buf) - 1);
StrLCat(@Buf, ': ', SizeOf(Buf) - 1);

if Frac(C.Value) = 0 then
 StrLCat(@Buf, IntToStr(Trunc(C.Value), IntBuf, SizeOf(IntBuf)), SizeOf(Buf) - 1)
else
 StrLCat(@Buf, PLChar(FloatToStr(C.Value)), SizeOf(Buf) - 1);

if FCVAR_ARCHIVE in C.Flags then
 StrLCat(@Buf, ', a', SizeOf(Buf) - 1);
if FCVAR_SERVER in C.Flags then
 StrLCat(@Buf, ', sv', SizeOf(Buf) - 1);
if FCVAR_USERINFO in C.Flags then
 StrLCat(@Buf, ', i', SizeOf(Buf) - 1);

Print(@Buf);
if F <> nil then
 FS_FPrintF(F, @Buf, True);
end;

procedure Cmd_CVarList; cdecl;
var
 Buf: array[1..128] of LChar;
 IntBuf, ExpandBuf: array[1..64] of LChar;
 S, S2: PLChar;
 LogFile, LogArchive, LogServer, LogPartial: Boolean;
 C: PCVar;
 Count, I, L: UInt;
 F: TFile;
begin
LogFile := False;
LogArchive := False;
LogServer := False;
LogPartial := False;
L := 0;

if Cmd_Argc >= 2 then
 begin
  S := Cmd_Argv(1);
  if (S = nil) or (StrComp(S, '?') = 0) then
   begin
    Print('cvarlist: List all cvars;' + LineBreak +
          'cvarlist [Partial]: List cvars starting with "Partial";' + LineBreak +
          'cvarlist log [Partial]: Logs cvars to file "cvarlist.txt" in the gamedir.');
    Exit;
   end
  else
   if StrIComp(S, 'log') = 0 then
    LogFile := True
   else
    if StrIComp(S, '-a') = 0 then
     LogArchive := True
    else
     if StrIComp(S, '-s') = 0 then
      LogServer := True
     else
      begin
       L := StrLen(S);
       LogPartial := L > 0;
      end;

  if LogFile then
   begin
    I := 0;

    while True do
     begin
      S2 := StrECopy(@Buf, 'cvarlist');
      S2 := StrECopy(S2, ExpandString(IntToStr(I, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 3));
      StrCopy(S2, '.txt');

      if FS_FileExists(@Buf) then
       begin
        Inc(I);
        if I >= 1000 then
         begin
          Print('Too many existing cvarlist output files in the gamedir.');
          Exit;
         end;
       end;
     end;

    if not FS_Open(F, @Buf, 'wo') then
     begin
      Print(['"', PLChar(@Buf), '" cannot be opened.']);
      Exit;
     end;
     
    if Cmd_Argc = 3 then
     begin
      S := Cmd_Argv(2);
      L := StrLen(S);
      LogPartial := L > 0;
     end;
   end;
 end
else
 S := EmptyString;

Print('CVar List:' + LineBreak + '--------------');

C := CVarBase;
Count := 0;
while C <> nil do
 begin
  if (not LogArchive or (FCVAR_ARCHIVE in C.Flags)) and
     (not LogServer or (FCVAR_SERVER in C.Flags)) and
     (not LogPartial or ((C.Name <> nil) and (StrLIComp(C.Name, S, L) = 0))) then
   begin
    if LogFile then
     Cmd_CVarListPrintCVar(C, F)
    else
     Cmd_CVarListPrintCVar(C, nil);

    Inc(Count);
   end;

  C := C.Next;
 end;

if LogPartial then
 Print(['--------------' + LineBreak, Count, ' CVars for [', S, ']'])
else
 Print(['--------------' + LineBreak, Count, ' Total CVars']);

if LogFile then
 begin
  FS_Close(F);
  Print(['cvarlist: Logged to "', PLChar(@Buf), '".']);
 end;
end;

function CVar_CountServerVariables: UInt;
var
 C: PCVar;
begin
Result := 0;

C := CVarBase;
while C <> nil do
 begin
  if FCVAR_SERVER in C.Flags then
   Inc(Result);

  C := C.Next;
 end;
end;

procedure CVar_UnlinkExternals;
var
 C: PCVar;
 P: ^PCVar;
begin
C := CVarBase;
P := @CVarBase;
while P^ <> nil do
 begin
  if FCVAR_EXTDLL in C.Flags then
   P^ := C.Next
  else
   P := @C.Next;
  
  C := C.Next;
 end;
end;

procedure CVar_CmdInit;
begin
Cmd_AddCommand('cvarlist', @Cmd_CVarList);
end;

// Commands

var
 CmdWait: Boolean = False;
 CmdText: TSizeBuf = ();
 LastPartialCmd: array[1..256] of LChar;

procedure CBuf_Init;
begin
SZ_Alloc('cmd_text', CmdText, $4000);
end;

procedure CBuf_AddText(Text: PLChar);
var
 L: UInt;
begin
if Text <> nil then
 begin
  L := StrLen(Text);
  if CmdText.CurrentSize + L < CmdText.MaxSize then
   SZ_Write(CmdText, Text, L)
  else
   Print('CBuf_AddText: Buffer overflow.');
 end
else
 Print('CBuf_AddText: Invalid string pointer.')
end;

procedure CBuf_AddText(const Text: array of const);
begin
CBuf_AddText(PLChar(StringFromVarRec(Text)));
end;

procedure CBuf_InsertText(Text: PLChar);
var
 Size: UInt;
 P: Pointer;
begin
if Text = nil then
 Print('CBuf_InsertText: Invalid string pointer.')
else
 if CmdText.CurrentSize + StrLen(Text) >= CmdText.MaxSize then
  Print('CBuf_InsertText: Buffer overflow.')
 else
  begin
   Size := CmdText.CurrentSize;

   if Size >= 1 then
    begin
     P := Z_MAlloc(Size);
     Move(CmdText.Data^, P^, Size);
     SZ_Clear(CmdText);
    end
   else
    P := nil;

   CBuf_AddText(Text);
   
   if Size >= 1 then
    begin
     SZ_Write(CmdText, P, Size);
     Z_Free(P);
    end;
  end;
end;

procedure CBuf_InsertTextLines(Text: PLChar);
var
 Size: UInt;
 P: Pointer;
begin
if Text = nil then
 Print('CBuf_InsertTextLines: Invalid string pointer.')
else
 if CmdText.CurrentSize + StrLen(Text) + SizeOf(Text^) * 2 >= CmdText.MaxSize then
  Print('CBuf_InsertTextLines: Buffer overflow.')
 else
  begin
   Size := CmdText.CurrentSize;
   
   if Size >= 1 then
    begin
     P := Z_MAlloc(Size);
     Move(CmdText.Data^, P^, Size);
     SZ_Clear(CmdText);
    end
   else
    P := nil;

   CBuf_AddText(#$A);
   CBuf_AddText(Text);
   CBuf_AddText(#$A);
   
   if Size >= 1 then
    begin
     SZ_Write(CmdText, P, Size);
     Z_Free(P);
    end;
  end;
end;

procedure CBuf_Execute;
var
 I, L, Quotes, Size: UInt;
 C: LChar;
 Buffer: array[1..1024] of LChar;
begin
while CmdText.CurrentSize >= 1 do
 begin
  I := 0;
  Quotes := 0;

  repeat
   C := PLChar(UInt(CmdText.Data) + I)^;
   if C = '"' then
    Inc(Quotes)
   else
    if ((C = ';') and ((Quotes and 1) = 0)) or (C = #$A) then
     Break;

   Inc(I);
  until I >= CmdText.CurrentSize;

  Size := Min(I, High(Buffer) - 1);
  Move(CmdText.Data^, Buffer, Size);
  Buffer[Size + 1] := #0;

  if Size = CmdText.CurrentSize then
   CmdText.CurrentSize := 0
  else
   begin
    L := Size + 1;
    Dec(CmdText.CurrentSize, L);
    Move(Pointer(UInt(CmdText.Data) + L)^, CmdText.Data^, CmdText.CurrentSize);
   end;

  Cmd_ExecuteString(@Buffer, csServer);
  if CmdWait then
   begin
    CmdWait := False;
    Break;
   end;
 end;
end;

procedure Cmd_StuffCmds; cdecl;
var
 I, J, L, Count: UInt;
 Text, Build, S: PLChar;
 C: LChar;
begin
if Cmd_Argc <> 1 then
 begin
  Print('stuffcmds: Executes command line parameters.');
  Exit;
 end;

// 1: Calculate the buffer length and allocate it.
L := 0;
Count := COM_GetParmCount;
if Count > 1 then
 for I := 1 to Count - 1 do
  begin
   S := COM_ParmByIndex(I);
   if S <> nil then
    Inc(L, StrLen(S) + SizeOf(S^));
  end;

if L = 0 then
 Exit;

Text := Z_MAlloc(L + 1);
Text^ := #0;

// 2: Put all parameters into the buffer.
for I := 1 to Count - 1 do
 begin
  S := COM_ParmByIndex(I);
  if S <> nil then
   begin
    StrCat(Text, S); // No need to do the length check.
    if I < Count - 1 then
     StrCat(Text, ' '); // Last character is always #0.
   end;
 end;

Build := Z_MAlloc(L + 1);
Build^ := #0;

if L > 1 then
 begin
  I := 0;
  repeat
   if PLChar(UInt(Text) + I)^ = '+' then
    begin
     Inc(I);
     J := I;

     while not (PLChar(UInt(Text) + J)^ in ['+', '-', #0]) do
      Inc(J);

     C := PLChar(UInt(Text) + J)^;
     PLChar(UInt(Text) + J)^ := #0;
     StrCat(Build, PLChar(UInt(Text) + I));
     StrCat(Build, #$A);
     PLChar(UInt(Text) + J)^ := C;

     I := J;
    end
   else
    Inc(I);
  until I >= L - 1;
 end;

if Build^ <> #0 then
 CBuf_InsertText(Build);

Z_Free(Text);
Z_Free(Build);
end;

procedure Cmd_Exec; cdecl;
var
 S: PLChar;
 Extension: array[1..512] of LChar;
 F: TFile;
 Size: Int64;
 P: Pointer;
begin
if Cmd_Argc <> 2 then
 begin
  Print('exec <filename>: Execute a script file.');
  Exit;
 end;

S := Cmd_Argv(1);
if (StrPos(S, '\\') <> nil) or (StrScan(S, ':') <> nil) or
   (StrScan(S, '~') <> nil) or (StrPos(S, '..') <> nil) or (S^ in ['\', '/']) or
   (StrScan(S, '.') <> StrRScan(S, '.')) then
 begin
  Print(['exec "', S, '": Invalid path.']);
  Exit;
 end;

COM_FileExtension(S, @Extension, SizeOf(Extension));
if (StrIComp(@Extension, 'cfg') <> 0) and (StrIComp(@Extension, 'rc') <> 0) then
 begin
  Print(['exec "', S, '": Not a .cfg or .rc file.']);
  Exit;
 end;

if FS_OpenPathID(F, S, 'r', 'GAMECONFIG') or FS_OpenPathID(F, S, 'r', 'GAME') or FS_Open(F, S, 'r') then
 begin
  Size := FS_Size(F);
  if Size > 0 then
   if Size <= MAX_CONFIG_SIZE then
    begin
     P := Mem_Alloc(Size + 1);
     FS_Read(F, P, Size);
     PByte(UInt(P) + Size)^ := 0;

     DPrint(['Execing "', S, '".']);
     if CmdText.CurrentSize + Size + 2 >= CmdText.MaxSize then
      while True do
       begin
        CBuf_Execute;
        P := COM_ParseLine(P);
        if COM_Token[Low(COM_Token)] > #0 then
         CBuf_InsertTextLines(@COM_Token)
        else
         Break;
       end
     else
      CBuf_InsertTextLines(P);

     Mem_Free(P);
    end
   else
    Print(['exec "', S, '": The file is too big.'])
  else
   Print(['exec "', S, '": The file is empty.']);
   
  FS_Close(F);
 end
else // no such file
 if (StrIComp(S, 'autoexec.cfg') <> 0) and
    (StrIComp(S, 'userconfig.cfg') <> 0) and
    (StrIComp(S, 'hw/opengl.cfg') <> 0) and
    (StrIComp(S, 'joystick.cfg') <> 0) and
    (StrIComp(S, 'game.cfg') <> 0) then
  Print(['exec "', S, '": The file couldn''t be opened.']);
end;

procedure Cmd_Echo; cdecl;
var
 I: Int;
 Buf: array[1..32767] of LChar;
begin
Buf[Low(Buf)] := #0;

for I := 1 to Cmd_Argc - 1 do
 begin
  StrLCat(@Buf, Cmd_Argv(I), SizeOf(Buf) - 1);
  StrLCat(@Buf, ' ', SizeOf(Buf) - 1);
 end;

Print(@Buf);
end;

function IsBadAlias(Name: PLChar): Boolean;
begin
Result := (Name = nil) or
          (StrIComp(Name, 'cl_autobuy') = 0) or
          (StrIComp(Name, 'cl_rebuy') = 0) or
          (StrIComp(Name, 'special') = 0) or
          (StrIComp(Name, '_special') = 0) or
          (StrIComp(Name, 'gl_ztrick') = 0) or
          (StrIComp(Name, 'gl_ztrick_old') = 0) or
          (StrIComp(Name, 'gl_d3dflip') = 0);                                                  
end;

procedure Cmd_Alias; cdecl;
var
 P: PAlias;
 S, S2: PLChar;
 I, L, Count: UInt;
 Buffer: array[1..1024] of LChar;
begin
Count := Cmd_Argc;
if Count <= 1 then
 begin
  Print('Current alias commands:');
  P := AliasBase;
  while P <> nil do
   begin
    if P.Command <> nil then
     Print([PLChar(@P.Name), ': ', P.Command])
    else
     Print([PLChar(@P.Name), ': (null)']);
    
    P := P.Next;
   end;
 end
else
 begin
  S := Cmd_Argv(1);
  if StrLen(S) >= MAX_ALIAS_NAME then
   Print('Alias name is too long.')
  else
   if CVar_FindVar(S) <> nil then
    Print(['Alias name is invalid ("', S, '" is a cvar).'])
   else
    begin
     SetCStrikeFlags;
     if (IsCStrike or IsCZero) and IsBadAlias(S) then
      Print('Alias name is invalid.')
     else
      begin
       Buffer[Low(Buffer)] := #0;
       L := 0;
       for I := 2 to Count - 1 do
        begin
         S2 := Cmd_Argv(I);
         if S2 = nil then
          Continue
         else
          begin
           Inc(L, StrLen(S2) + 1);
           if L >= High(Buffer) - 1 then
            begin
             Print('Alias command is too long.');
             Exit;
            end;

           StrLCat(@Buffer, S2, High(Buffer) - 2);
           if I < Count - 1 then
            StrLCat(@Buffer, ' ', High(Buffer) - 2);
          end;
        end;
        
       Buffer[L] := #$A;
       Buffer[L + 1] := #0;
       Inc(L);

       P := AliasBase;
       while P <> nil do
        if StrIComp(@P.Name, S) = 0 then
         if StrComp(P.Command, @Buffer) <> 0 then
          begin
           Z_Free(P.Command);
           Break;
          end
         else
          Exit
        else
         P := P.Next;

       if P = nil then
        begin
         P := Z_MAlloc(SizeOf(TAlias));
         P.Next := AliasBase;
         AliasBase := P;
        end;

       StrLCopy(@P.Name, S, MAX_ALIAS_NAME - 1);
       P.Command := Z_MAlloc(L);
       StrLCopy(P.Command, @Buffer, L - 1);
      end;
    end;
 end;
end;

procedure Cmd_ForwardToServer; cdecl;
begin

end;

procedure Cmd_Wait; cdecl;
begin
CmdWait := True;
end;

procedure Cmd_CmdList; cdecl;
var
 Buf: array[1..128] of LChar;
 IntBuf, ExpandBuf: array[1..64] of LChar;
 S, S2: PLChar;
 LogFile, LogPartial: Boolean;
 C: PCommand;
 Count, I, L: UInt;
 F: TFile;
begin
LogFile := False;
LogPartial := False;
L := 0;

if Cmd_Argc >= 2 then
 begin
  S := Cmd_Argv(1);
  if (S = nil) or (StrComp(S, '?') = 0) then
   begin
    Print('cmdlist: List all commands' + #$A +
          'cmdlist [Partial]: List commands starting with "Partial"' + #$A +
          'cmdlist log [Partial]: Logs commands to file "cmdlist.txt" in the gamedir.');
    Exit;
   end
  else
   if StrIComp(S, 'log') = 0 then
    LogFile := True
   else
    begin
     L := StrLen(S);
     LogPartial := L > 0;
    end;

  if LogFile then
   begin
    I := 0;

    while True do
     begin
      S2 := StrECopy(@Buf, 'cmdlist');
      S2 := StrECopy(S2, ExpandString(IntToStr(I, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 3));
      StrCopy(S2, '.txt');

      if FS_FileExists(@Buf) then
       begin
        Inc(I);
        if I >= 1000 then
         begin
          Print('Too many existing cmdlist output files in the gamedir.');
          Exit;
         end;
       end;
     end;

    if not FS_Open(F, @Buf, 'wo') then
     begin
      Print(['"', PLChar(@Buf), '" cannot be opened.']);
      Exit;
     end;
   end;
 end
else
 S := EmptyString;

Print('Command List:' + LineBreak + '--------------');

C := CmdBase;
Count := 0;
while C <> nil do
 begin
  if (not LogPartial or ((C.Name <> nil) and (StrLIComp(C.Name, S, L) = 0))) then
   begin
    Print(C.Name);
    if LogFile then
     FS_FPrintF(F, C.Name);
     
    Inc(Count);
   end;

  C := C.Next;
 end;

if LogPartial then
 Print(['--------------' + LineBreak, Count, ' Commands for [', S, ']'])
else
 Print(['--------------' + LineBreak, Count, ' Total Commands']);

if LogFile then
 begin
  Print(['cmdlist: Logged to "', PLChar(@Buf), '".']);
  FS_Close(F);
 end;
end;

function Cmd_GetFirstCmd: PCommand;
begin
Result := CmdBase;
end;

procedure Cmd_Init;
begin
Cmd_AddCommand('stuffcmds', @Cmd_StuffCmds);
Cmd_AddCommand('exec', @Cmd_Exec);
Cmd_AddCommand('echo', @Cmd_Echo);
Cmd_AddCommand('alias', @Cmd_Alias);
Cmd_AddCommand('cmd', @Cmd_ForwardToServer);
Cmd_AddCommand('wait', @Cmd_Wait);
Cmd_AddCommand('cmdlist', @Cmd_CmdList);
LastPartialCmd[Low(LastPartialCmd)] := #0;
end;

procedure Cmd_Shutdown;
begin
MemSet(CmdArgv, SizeOf(CmdArgv), 0);
CmdBase := nil;
CmdArgc := 0;
CmdArgs := nil;
end;

function Cmd_Argc: UInt;
begin
Result := CmdArgc;
end;

function Cmd_Argv(Index: UInt): PLChar;
begin
if Index < CmdArgc then
 Result := CmdArgv[Index]
else
 Result := EmptyString;
end;

function Cmd_Args: PLChar;
begin
Result := CmdArgs;
end;

procedure Cmd_TokenizeString(Data: PLChar);
var
 I, L: UInt;
 S: PLChar;
begin
if CmdArgc > 0 then
 begin
  for I := 0 to CmdArgc - 1 do
   if CmdArgv[I] <> nil then
    Z_Free(CmdArgv[I]);
  CmdArgc := 0;
 end;

CmdArgs := nil;
S := Data;

while True do
 begin
  while S^ in [#1..' '] do // must use #1 here
   if S^ = #$A then
    Exit
   else
    Inc(UInt(S));

  if S^ = #0 then
   Break;

  if CmdArgc = 1 then
   CmdArgs := S;

  S := COM_Parse(S);
  if S = nil then
   Break;

  L := StrLen(@COM_Token) + 1;
  if L > 515 then
   Break;

  if CmdArgc < MAX_CMD_ARGS then
   begin
    CmdArgv[CmdArgc] := Z_MAlloc(L);
    StrCopy(CmdArgv[CmdArgc], @COM_Token); // Safe to use StrCopy here
    Inc(CmdArgc);
   end;
 end;
end;

function Cmd_FindCmd(Name: PLChar): PCommand;
begin
if Name <> nil then
 begin
  Result := CmdBase;
  while (Result <> nil) and (StrIComp(Result.Name, Name) <> 0) do
   Result := Result.Next;
 end
else
 Result := nil;
end;

function Cmd_FindPrevCmd(Name: PLChar): PCommand;
var
 P: PCommand;
begin
if Name <> nil then
 begin
  Result := CmdBase;

  while Result <> nil do
   begin
    P := Result.Next;
    if P = nil then
     Break
    else
     if (P.Name <> nil) and (StrIComp(P.Name, Name) = 0) then
      Exit
     else
      Result := P;
   end;
 end;

Result := nil;
end;

procedure Cmd_AddCommand(Name: PLChar; Func: TCmdFunction);
var
 C, C2: PCommand;
begin
if HostInit then
 Sys_Error(['Tried to register a command ("', Name, '") after the server was initialized.']);

if CVar_FindVar(Name) <> nil then
 Print(['Cmd_AddCommand: "', Name, '" already defined as a cvar.'])
else
 if Cmd_FindCmd(Name) <> nil then
  Print(['Cmd_AddCommand: "', Name, '" already defined.'])
 else
  begin
   C := Hunk_Alloc(SizeOf(TCommand));
   C.Name := Name;
   if @Func <> nil then
    C.Callback := @Func
   else
    C.Callback := @Cmd_ForwardToServer;
   C.Flags := 0;

   if (CmdBase = nil) or (StrIComp(C.Name, CmdBase.Name) <= 0) then
    begin
     C.Next := CmdBase;
     CmdBase := C;
    end
   else
    begin
     C2 := CmdBase;
     while (C2.Next <> nil) and (StrIComp(C.Name, C2.Next.Name) > 0) do
      C2 := C2.Next;

     C.Next := C2.Next;
     C2.Next := C;
    end;
  end;
end;

procedure Cmd_AddMAllocCommand(Name: PLChar; Func: TCmdFunction; Flags: UInt);
var
 C: PCommand;
begin
if CVar_FindVar(Name) <> nil then
 Print(['Cmd_AddMAllocCommand: "', Name, '" already defined as a cvar.'])
else
 if Cmd_FindCmd(Name) <> nil then
  Print(['Cmd_AddMAllocCommand: "', Name, '" already defined.'])
 else
  begin
   C := Mem_ZeroAlloc(SizeOf(TCommand));
   C.Name := Name;
   if @Func <> nil then
    C.Callback := @Func
   else
    C.Callback := @Cmd_ForwardToServer;
   C.Flags := Flags;
   C.Next := CmdBase;
   CmdBase := C;
  end;
end;

procedure Cmd_AddHUDCommand(Name: PLChar; Func: TCmdFunction);
begin
Cmd_AddMAllocCommand(Name, Func, FCMD_CLIENT);
end;

procedure Cmd_AddGameCommand(Name: PLChar; Func: TCmdFunction);
begin
Cmd_AddMAllocCommand(Name, Func, FCMD_GAME);
end;

procedure Cmd_AddWrapperCommand(Name: PLChar; Func: TCmdFunction);
begin
Cmd_AddMAllocCommand(Name, Func, FCMD_WRAPPER);
end;

procedure Cmd_RemoveMAllocedCmds(Flags: UInt);
var
 C, C2, C3: PCommand;
begin
C3 := nil;
C := CmdBase;
while C <> nil do
 begin
  C2 := C.Next;
  if (Flags and C.Flags) > 0 then
   Mem_Free(C)
  else
   begin
    C.Next := C3;
    C3 := C;
   end;

  C := C2;
 end;

CmdBase := C3;
end;

procedure Cmd_RemoveHUDCmds;
begin
Cmd_RemoveMAllocedCmds(FCMD_CLIENT);
end;

procedure Cmd_RemoveGameCmds;
begin
Cmd_RemoveMAllocedCmds(FCMD_GAME);
end;

procedure Cmd_RemoveWrapperCmds;
begin
Cmd_RemoveMAllocedCmds(FCMD_WRAPPER);
end;

function Cmd_Exists(Name: PLChar): Boolean;
var
 C: PCommand;
begin
C := CmdBase;
while C <> nil do
 if StrIComp(C.Name, Name) = 0 then
  begin
   Result := True;
   Exit;
  end
 else
  C := C.Next;

Result := False;
end;

function Cmd_CompleteCommand(Name: PLChar; NextCmd: Boolean): PLChar;
var
 Buffer: array[1..256] of LChar;
 L: UInt;
 P, P2: PCommand;
begin
StrLCopy(@Buffer, Name, High(Buffer) - 1);
Buffer[High(Buffer)] := #0;

L := StrLen(@Buffer);
if L = 0 then
 Result := nil
else
 begin
  while (L > Low(Buffer)) and (Buffer[L - 1] = ' ') do
   begin
    Buffer[L - 1] := #0;
    Dec(L);
   end;

  if StrIComp(@Buffer, @LastPartialCmd) = 0 then
   begin
    P := Cmd_FindCmd(@Buffer);
    if P <> nil then
     begin
      if NextCmd then
       P2 := P.Next
      else
       P2 := Cmd_FindPrevCmd(P.Name);
      if P2 <> nil then
       begin
        StrLCopy(@LastPartialCmd, P2.Name, High(LastPartialCmd) - 1);
        LastPartialCmd[High(LastPartialCmd)] := #0;
        Result := P2.Name;
        Exit;
       end;
     end;
   end;

  P := CmdBase;
  while True do
   if (P = nil) or (P.Next = nil) then
    begin
     Result := nil;
     Exit;
    end
   else
    if StrLComp(@Buffer, P.Name, L) <> 0 then
     P := P.Next
    else
     Break;

  StrLCopy(@LastPartialCmd, P.Name, High(LastPartialCmd) - 1);
  LastPartialCmd[High(LastPartialCmd)] := #0;
  Result := P.Name;
 end;
end;

// Custom function to simplify alias search
function Cmd_FindAlias(Name: PLChar): PAlias;
begin
Result := AliasBase;
while Result <> nil do
 if StrIComp(Name, @Result.Name) = 0 then
  Exit
 else
  Result := Result.Next;
end;

procedure Cmd_ExecuteString(Text: PLChar; Source: TCmdSource);
var
 S: PLChar;
 P: PCommand;
 P2: PAlias;
begin
CmdSource := Source;
Cmd_TokenizeString(Text);

if Cmd_Argc > 0 then
 begin
  S := Cmd_Argv(0);
  P := Cmd_FindCmd(S);
  if (P <> nil) and (@P.Callback <> nil) then
   P.Callback
  else
   begin
    P2 := Cmd_FindAlias(S);
    if (P2 <> nil) and (P2.Command <> nil) then
     CBuf_InsertText(P2.Command)
    else
     CVar_Command;     
   end;
 end;
end;

function Cmd_ForwardToServerInternal(Buffer: PSizeBuf): Boolean;
begin
Result := False;
end;

procedure Cmd_ForwardToServerUnreliable;
begin

end;

function Cmd_CheckParm(Name: PLChar): UInt;
var
 I, L: UInt;
 S: PLChar;
begin
if Name = nil then
 Sys_Error('Cmd_CheckParm: Invalid name.');

L := Cmd_Argc;
if L > 1 then
 for I := 1 to L - 1 do
  begin
   S := Cmd_Argv(I);
   if (S <> nil) and (StrIComp(S, Name) = 0) then
    begin
     Result := I;
     Exit;
    end;
  end;

Result := 0;
end;

// Console itself

procedure Cmd_Debug_F; cdecl;
begin
if DebugLog then
 Print('Condebug disabled.')
else
 Print('Condebug enabled.');

DebugLog := not DebugLog;
end;

procedure Con_DebugLog(FileName, Msg: PLChar);
var
 F: TFile;
begin
if FS_Open(F, FileName, 'a') then
 begin
  FS_FPrintF(F, Msg);
  FS_Close(F);
 end;
end;

procedure Con_DebugLog(FileName: PLChar; const Msg: array of const);
begin
Con_DebugLog(FileName, PLChar(StringFromVarRec(Msg)));
end;

procedure Con_SafePrintF(Msg: PLChar);
begin
Print(Msg);
end;

procedure Con_SafePrintF(const Msg: array of const);
begin
Con_SafePrintF(PLChar(StringFromVarRec(Msg)));
end;

procedure Con_Init;
begin
DebugLog := COM_CheckParm('-condebug') > 0;
DPrint('Console initialized.');
Cmd_AddCommand('condebug', @Cmd_Debug_F);
end;

procedure Con_Shutdown;
begin

end;


// Logging


procedure Log_PrintF(Msg: PLChar);
var
 ExpandBuf, IntBuf: array[1..32] of LChar;
 Buf: array[1..2048] of LChar;
 Y, M, D, Hour, Min, Sec, MSec: UInt16;
 S: PLChar;
 DT: TDateTime;
 P: PLogNode;
begin
if SVS.LogEnabled or SVS.LogToAddr or (FirstLog <> nil) then
 begin
  DT := Now;
  DecodeDate(DT, Y, M, D);
  DecodeTime(DT, Hour, Min, Sec, MSec);

  S := StrECopy(@Buf, 'L ');
  S := StrECopy(S, ExpandString(IntToStr(M, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
  S := StrECopy(S, '/');
  S := StrECopy(S, ExpandString(IntToStr(D, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
  S := StrECopy(S, '/');
  S := StrECopy(S, ExpandString(IntToStr(Y, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 4));
  S := StrECopy(S, ' - ');

  S := StrECopy(S, ExpandString(IntToStr(Hour, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
  S := StrECopy(S, ':');
  S := StrECopy(S, ExpandString(IntToStr(Min, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
  S := StrECopy(S, ':');
  S := StrECopy(S, ExpandString(IntToStr(Sec, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
  S := StrECopy(S, ': ');

  StrLCopy(S, Msg, SizeOf(Buf) - StrLen(@Buf) - 1); 
  
  if SVS.LogToAddr or (FirstLog <> nil) then
   begin
    if SVS.LogToAddr then
     Netchan_OutOfBandPrint(NS_SERVER, SVS.LogAddr, ['log ', PLChar(@Buf)]);

    P := FirstLog;
    while P <> nil do
     begin
      Netchan_OutOfBandPrint(NS_SERVER, P.Adr, ['log ', PLChar(@Buf)]);
      P := P.Prev;
     end;
   end;

  if SVS.LogEnabled and ((SVS.MaxClients > 1) or (sv_log_singleplayer.Value <> 0)) then
   begin
    if mp_logecho.Value <> 0 then
     Con_PrintF(PLChar(@Buf));

    if (SVS.LogFile <> nil) and (mp_logfile.Value <> 0) then
     FS_FPrintF(SVS.LogFile, PLChar(@Buf), False);
   end;
 end;
end;

procedure LPrint(Msg: PLChar);
begin
Log_PrintF(Msg);
end;

procedure LPrint(const Msg: array of const);
begin
Log_PrintF(PLChar(StringFromVarRec(Msg)));
end;

procedure Log_PrintServerVars;
var
 P: PCVar;
begin
if SVS.LogEnabled then
 begin
  LPrint('Server cvars start'#10);
  P := CVarBase;
  while P <> nil do
   begin
    if FCVAR_SERVER in P.Flags then
     LPrint(['Server cvar "', P.Name, '" = "', P.Data, '"'#10]);

    P := P.Next;
   end;

  LPrint('Server cvars end'#10);
 end;
end;

procedure Log_Close;
begin
if SVS.LogFile <> nil then
 begin
  LPrint('Log file closed'#10);
  FS_Close(SVS.LogFile);
  SVS.LogFile := nil;
 end;
end;

procedure Log_Open;
var
 ExpandBuf, IntBuf: array[1..32] of LChar;
 Buf: array[1..MAX_PATH_W] of LChar;
 DT: TDateTime;
 Y, M, D: UInt16;
 S, S2: PLChar;
 I: UInt;
begin
if SVS.LogEnabled and ((sv_log_onefile.Value = 0) or (SVS.LogFile = nil)) then
 if mp_logfile.Value = 0 then
  Print('Server logging data to console.')
 else
  begin
   Log_Close;

   DT := Now;
   DecodeDate(DT, Y, M, D);

   S := logsdir.Data;
   if (S^ = #0) or (S^ in ['\', '/']) or (StrScan(S, ':') <> nil) or (StrPos(S, '..') <> nil) or (StrLen(S) >= SizeOf(Buf) - 34) then
    S := StrECopy(@Buf, 'logs' + CorrectSlash + 'L')
   else
    begin
     S := StrECopy(@Buf, S);
     S := StrECopy(S, CorrectSlash + 'L');
    end;

   S := StrECopy(S, ExpandString(IntToStr(M, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));
   S := StrECopy(S, ExpandString(IntToStr(D, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 2));

   COM_CreatePath(@Buf);
   
   for I := 0 to MAX_LOG_FILES - 1 do
    begin
     S2 := StrECopy(S, ExpandString(IntToStr(I, IntBuf, SizeOf(IntBuf)), @ExpandBuf, SizeOf(ExpandBuf), 3));
     StrCopy(S2, '.log');
     if not FS_FileExists(@Buf) then
      begin
       if not FS_Open(SVS.LogFile, @Buf, 'wo') then
        begin
         Print(['Can''t open logfile "', PLChar(@Buf), '" for writing.' + LineBreak + 'Logging disabled.']);
         SVS.LogEnabled := False;
         Exit;
        end;

       Print(['Server logging data to file "', PLChar(@Buf), '".']);
       LPrint(['Log file started (file "', PLChar(@Buf), '") (game "', Info_ValueForKey(Info_ServerInfo, '*gamedir'), '") (version "', ProjectName, '/', BuildNumber, '")'#10]);
       Exit;
      end;
    end;

   Print(['Unable to create logfile - too many existing files, the limit is ', MAX_LOG_FILES, '.' + LineBreak +
          'Logging disabled.']);
   SVS.LogEnabled := False;
  end;
end;

end.
