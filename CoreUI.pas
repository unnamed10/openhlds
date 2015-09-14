unit CoreUI;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS}Windows, {$ELSE}Libc, {$ENDIF} Default, SDK;

procedure UI_Print(S: PChar);
procedure UI_Frame(Time: Double);
procedure UI_EngineReady(const Engine: TEngineFuncs);
procedure UI_Shutdown;

type
 PUIFuncs = ^TUIFuncs;
 TUIFuncs = record
  OnPrint: procedure(S: PLChar); stdcall;
  OnFrame: procedure(Time: Double); stdcall;
  OnEngineReady: procedure(const Engine: TEngineFuncs); stdcall;

  OnAttach: procedure; stdcall;
  OnUnlink: procedure; stdcall;
 end;
 
function AttachExternalUI(const F: TUIFuncs): Boolean; stdcall;

implementation

type
 PExternalUI = ^TExternalUI;
 TExternalUI = record
  UI: TUIFuncs;
  Prev: PExternalUI;
 end;

var
 Ext: PExternalUI;

procedure UI_Print(S: PLChar);
var
 P: PExternalUI;
begin
P := Ext;
while P <> nil do
 begin
  if @P.UI.OnPrint <> nil then
   P.UI.OnPrint(S);
  P := P.Prev;
 end;
end;

procedure UI_Frame(Time: Double);
var
 P: PExternalUI;
begin
P := Ext;
while P <> nil do
 begin
  if @P.UI.OnFrame <> nil then
   P.UI.OnFrame(Time);
  P := P.Prev;
 end;
end;

procedure UI_EngineReady(const Engine: TEngineFuncs);
var
 P: PExternalUI;
begin
P := Ext;
while P <> nil do
 begin
  if @P.UI.OnEngineReady <> nil then
   P.UI.OnEngineReady(Engine);
  P := P.Prev;
 end;
end;

procedure UI_Shutdown;
var
 P, P2: PExternalUI;
begin
P := Ext;
while P <> nil do
 begin
  P2 := P.Prev;
  if @P.UI.OnUnlink <> nil then
   P.UI.OnUnlink;
  FreeMem(P);
  P := P2;                          
 end;
end;

function IsAlreadyAttached(const F: TUIFuncs): Boolean;
var
 P: PExternalUI;
begin
P := Ext;
while P <> nil do
 if @P.UI = @F then
  begin
   Result := True;
   Exit;
  end
 else
  P := P.Prev;

Result := False;
end;

function AttachExternalUI(const F: TUIFuncs): Boolean; stdcall;
var
 P: PExternalUI;
begin
Result := False;

if not IsAlreadyAttached(F) then
 begin
  GetMem(P, SizeOf(P^));
  if P <> nil then
   begin
    MemSet(P^, SizeOf(P^), 0);
    P.UI := F;
    P.Prev := Ext;
    Ext := P;
    if @F.OnAttach <> nil then
     F.OnAttach;
    Result := True;
   end;
 end;
end;

exports AttachExternalUI;

end.
