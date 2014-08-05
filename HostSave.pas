unit HostSave;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure Host_SaveGameComment(Buf: PLChar; MaxLength: Int32); cdecl;
function LoadGamestate(Name: PLChar; B: Boolean): Boolean;

var
 SaveGameCommentFunc: procedure(Buf: PLChar; MaxLength: Int32); cdecl = Host_SaveGameComment;

implementation

procedure Host_SaveGameComment(Buf: PLChar; MaxLength: Int32); cdecl;
begin
// Not implemented as for now
end;

function LoadGamestate(Name: PLChar; B: Boolean): Boolean;
begin
Result := False;
end;

end.
