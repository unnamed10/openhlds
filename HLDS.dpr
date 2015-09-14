program HLDS;

{$APPTYPE CONSOLE}

{$I *.inc}

uses
  FastMM4,
  {$IFDEF WINDOWS} Windows, Winsock, UCWinAPI,{$ENDIF}
  {$IFDEF LINUX}KernelDefs in 'unix/kerneldefs.pas', KernelIoctl in 'unix/kernelioctl.pas', Libc in 'unix/libc.pas',{$ENDIF}

  // RTL
  SysUtils,

  // Common utils + header unit
  Default, SDK,
  Main,

  BZip2, Common, Console, CoreUI, Decal, Delta, Edict, Encode, FileSys, FilterIP,
  GameLib, Host, HostCmds, HostSave, HPAK, Info, MathLib, Memory, Model,
  MsgBuf, Network, ParseLib, PMove, Renderer, Resource, StdUI,
  SVAuth, SVClient, SVCmds, SVDelta, SVEdict, SVEvent, SVExport, SVMain,
  SVMove, SVPacket, SVPhys, SVRcon, SVSend, SVWorld, SysArgs, SysClock,
  SysMain, Texture;

// stuff to do

// shutdown stuff ET in GameLib!!! (win/linux, check for non-nil, mem_free it) (NOT DONE)

// decompressing file err (check?)
// Draw_FreeWAD: check all occurences (don't remember)

// Sys_Error: shutdown host, disconnect clients if necessary
//  - gamedll

// Host_Error: shutdown server

// Host_Error: disconnect all clients and shutdown
// Sys_Error: shutdown immediately without disconnecting

// mp.dll+8d091 FP OP

// a better voice relay, maybe 50% of chan max, 75% of chan max and such
// optimize parsemove
// fix createpacketentities, origin[z], demo recording
// add banlist!

// also find out why players have random viewangles after respawn

// demo recorder!

// FIX:   if SendFrag[I] and (FB <> nil) and (Size + C.ReliableLength <= MAX_FRAGDATA) then
// was   if SendFrag[I] and (FB <> nil) and (Size + C.ReliableLength < MAX_FRAGDATA) then

// Netchan_CreateFileFragments check

begin
DecimalSeparator := '.';

Start;
while Frame do
 Sys_Sleep(0);
Shutdown;

Writeln('Press any key to close the program...');
Readln;
end.
