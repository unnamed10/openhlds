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

  BZip2, Common, Console, Decal, Delta, Edict, Encode, FileSys, FilterIP,
  GameLib, Host, HostCmds, HostSave, HPAK, Info, Main, MathLib, Memory, Model,
  MsgBuf, Network, ParseLib, PMove, Renderer, Resource, Server, StdUI,
  SVAuth, SVClient, SVCmds, SVDelta, SVEdict, SVEvent, SVExport, SVMain,
  SVMove, SVPacket, SVPhys, SVRcon, SVSend, SVWorld, SysArgs, SysClock,
  SysMain, Texture;

// stuff to do

// shutdown stuff ET in GameLib!!! (win/linux, check for non-nil, mem_free it) (NOT DONE)
// precached events should be shut down (NOT DONE)

// check fatpas (DONE!)
// svsend has printing in validclientmulticast (DONE!)
// hltv doesn''t show maxclients (DONE!)
// check findentity 'n stuff (DONE!)

// svpacket, check stuff (DONE!)
// add a notice if the server is not active (DONE!)
// allow rcon and queries (NOT DONE)

// decompressing file err (check?)
// Draw_FreeWAD: check all occurences (don't remember)

// check dup names (partially works)

// after round time, game dll calls PF_VGUI2_IsCareerMatch (info)

// node is 52, leaf is 60. (info)

// gamedll says "Could not allocsound() for insertsound() (DLL) (NOT CHECK)

// moveents, CONTENTS_LADDER (check check check)

// clientprintf in ALL commands and server check (sure) (NEEDS WORK)

// NUM_FOR_EDICT (checked probably)
// IndexOfEdict (checked probably)

// SV_ClientPrint: #10

var
 I: Single;
begin
DecimalSeparator := '.';
Writeln;
Writeln('   -- OpenHLDS 1.01 --');
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
