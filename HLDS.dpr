program HLDS;

{$APPTYPE CONSOLE}

{$I *.inc}

uses
  // Platform-dependent units
  {$IFDEF MSWINDOWS} Windows, Winsock, UCWinAPI,{$ENDIF}
  {$IFDEF LINUX}KernelDefs in 'unix/kerneldefs.pas', KernelIoctl in 'unix/kernelioctl.pas', Libc in 'unix/libc.pas',{$ENDIF}

  // RTL
  SysUtils,

  // Common utils + header unit
  Default, SDK,
  Main,

  BZip2, Common, Console, Decal, Delta, Edict, Encode, FileSys, FilterIP,
  GameLib, Host, HostCmds, HostSave, HPAK, Info, MathLib, Memory, Model,
  MsgBuf, Network, ParseLib, PMove, Renderer, Resource, Server, StdUI,
  SVAuth, SVClient, SVCmds, SVDelta, SVEdict, SVEvent, SVExport, SVMain,
  SVMove, SVPacket, SVPhys, SVRcon, SVSend, SVWorld, SysArgs, SysClock,
  SysMain, Texture;

// stuff to do

// shutdown stuff ET in GameLib!!! (win/linux, check for non-nil, mem_free it) (NOT DONE)
// precached events should be shut down (NOT DONE)

// allow rcon and queries (NOT DONE)

// decompressing file err (check?)
// Draw_FreeWAD: check all occurences (don't remember)

// after round time, game dll calls PF_VGUI2_IsCareerMatch (info)

// node is 52, leaf is 60. (info)

// clientprintf in ALL commands and server check (sure) (NEEDS WORK)

// SV_ClientPrint: #10

// SV_WriteClientDataToMessage: weapon delta field size is 5 on some outdated clients

// Sys_Error: shutdown host, disconnect clients if necessary
//  - gamedll

// Host_Error: shutdown server

// search for "FSB_ALLOWOVERFLOW in". replace to "FSB_OVERFLOWED in".

begin
DecimalSeparator := '.';
Writeln;
Writeln('   -- OpenHLDS 1.02 --');
Writeln;

Start;
while Frame do             
 Sys_Sleep(1);
Shutdown;

(*{$IFDEF FPC}
 Writeln('Compiled with FPC');
{$ELSE}
 Writeln('Compiled with Delphi');
{$ENDIF}*)

Writeln('Press any key to close the program...');
Readln;
end.
