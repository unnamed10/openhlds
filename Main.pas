unit Main;

{$I HLDS.inc}

interface

uses Default;

procedure Start;
function Frame: Boolean;
procedure Shutdown;

implementation

uses Common, Console, Host, StdUI, SysMain;

var
 ShutdownCalled: Boolean;

procedure Start;
begin
UI_Init;
Sys_Init;
end;

function Frame: Boolean;
begin
Result := Host_Frame;
end;

procedure Shutdown;
begin
if not ShutdownCalled then
 begin
  ShutdownCalled := True;
  Sys_Shutdown;
  UI_Shutdown;
 end;
end;

initialization

finalization
 if not ShutdownCalled and not InSysError then // unrequested shutdown
  begin
   Writeln('Warning: Unrequested shutdown.');
   Readln;
  end;
  
 Shutdown;

end.
