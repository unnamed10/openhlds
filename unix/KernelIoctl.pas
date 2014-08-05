{ *********************************************************************** }
{                                                                         }
{  Borland Kylix Runtime Library                                          }
{  Linux Kernel API Interface Unit                                        }
{                                                                         }
{  This translation is based on include files                             }
{  taken from the Linux 2.2.16 kernel.                                    }
{                                                                         }
{  Copyright (C) 2001 Borland Software Corporation                        }
{                                                                         }
{  Translator: Borland Software Corporation                               }
{                                                                         }
{  This file may be distributed and/or modified under the terms of the    }
{  GNU General Public License version 2 as published by the Free Software }
{  Foundation and appearing at http://www.borland.com/kylix/gpl.html.     }
{                                                                         }
{  Licensees holding valid a valid Borland No-Nonsense License for this   }
{  Software may use this file in accordance with such license, which      }
{  appears in the file license.txt that came with this software.          }
{                                                                         }
{ *********************************************************************** }

unit KernelIoctl;

{$WEAKPACKAGEUNIT}

{$ALIGN 4}
{$MINENUMSIZE 4}
{$ASSERTIONS OFF}

interface

// Translated from linux/include/asm-i386/ioctl.h

{ ioctl command encoding: 32 bits total, command in lower 16 bits,
 * size of the parameter structure in the lower 14 bits of the
 * upper 16 bits.
 * Encoding the size of the parameter structure in the ioctl request
 * is useful for catching programs compiled with old versions
 * and to avoid overwriting user space outside the user buffer area.
 * The highest 2 bits are reserved for indicating the ``access mode''.
 * NOTE: This limits the max parameter size to 16kB -1 !
 }

{
 * The following is for compatibility across the various Linux
 * platforms.  The i386 ioctl numbering scheme doesn't really enforce
 * a type field.  De facto, however, the top 8 bits of the lower 16
 * bits are indeed used as a type field, so we might just as well make
 * this explicit here.  Please be sure to use the decoding macros
 * below from now on.
 }
const
  _IOC_NRBITS              = 8;
  {$EXTERNALSYM _IOC_NRBITS}
  _IOC_TYPEBITS            = 8;
  {$EXTERNALSYM _IOC_TYPEBITS}
  _IOC_SIZEBITS            = 14;
  {$EXTERNALSYM _IOC_SIZEBITS}
  _IOC_DIRBITS             = 2;
  {$EXTERNALSYM _IOC_DIRBITS}

  _IOC_NRMASK              = ((1 shl _IOC_NRBITS)-1);
  {$EXTERNALSYM _IOC_NRMASK}
  _IOC_TYPEMASK            = ((1 shl _IOC_TYPEBITS)-1);
  {$EXTERNALSYM _IOC_TYPEMASK}
  _IOC_SIZEMASK            = ((1 shl _IOC_SIZEBITS)-1);
  {$EXTERNALSYM _IOC_SIZEMASK}
  _IOC_DIRMASK             = ((1 shl _IOC_DIRBITS)-1);
  {$EXTERNALSYM _IOC_DIRMASK}

  _IOC_NRSHIFT             = 0;
  {$EXTERNALSYM _IOC_NRSHIFT}
  _IOC_TYPESHIFT           = (_IOC_NRSHIFT+_IOC_NRBITS);
  {$EXTERNALSYM _IOC_TYPESHIFT}
  _IOC_SIZESHIFT           = (_IOC_TYPESHIFT+_IOC_TYPEBITS);
  {$EXTERNALSYM _IOC_SIZESHIFT}
  _IOC_DIRSHIFT            = (_IOC_SIZESHIFT+_IOC_SIZEBITS);
  {$EXTERNALSYM _IOC_DIRSHIFT}

{ Direction bits. }
  _IOC_NONE                 = 0;
  {$EXTERNALSYM _IOC_NONE}
  _IOC_WRITE                = 1;
  {$EXTERNALSYM _IOC_WRITE}
  _IOC_READ                 = 2;
  {$EXTERNALSYM _IOC_READ}

function _IOC(dir, __type, nr, size: Cardinal): Cardinal;
{$EXTERNALSYM _IOC}

{ used to create numbers }
function _IO(__type, nr: Cardinal): Cardinal;
{$EXTERNALSYM _IO}

// Warning: BufferSize is sizeof(size) !
function __IOR(__type, nr: Cardinal; BufferSize: Cardinal): Cardinal;
{.$EXTERNALSYM __IOR} // Renamed because of implementation change
function __IOW(__type, nr: Cardinal; BufferSize: Cardinal): Cardinal;
{.$EXTERNALSYM __IOW} // Renamed because of implementation change
function __IOWR(__type, nr: Cardinal; BufferSize: Cardinal): Cardinal;
{.$EXTERNALSYM __IOWR} // Renamed because of implementation change

{ used to decode ioctl numbers.. }
function _IOC_DIR(nr: Cardinal): Cardinal;
{$EXTERNALSYM _IOC_DIR}
function _IOC_TYPE(nr: Cardinal): Cardinal;
{$EXTERNALSYM _IOC_TYPE}
function _IOC_NR(nr: Cardinal): Cardinal;
{$EXTERNALSYM _IOC_NR}
function _IOC_SIZE(nr: Cardinal): Cardinal;
{$EXTERNALSYM _IOC_SIZE}

{ ...and for the drivers/sound files... }
const
  IOC_IN               = (_IOC_WRITE shl _IOC_DIRSHIFT);
  {$EXTERNALSYM IOC_IN}
  IOC_OUT              = (_IOC_READ shl _IOC_DIRSHIFT);
  {$EXTERNALSYM IOC_OUT}
  IOC_INOUT            = ((_IOC_WRITE or _IOC_READ) shl _IOC_DIRSHIFT);
  {$EXTERNALSYM IOC_INOUT}
  IOCSIZE_MASK         = (_IOC_SIZEMASK shl _IOC_SIZESHIFT);
  {$EXTERNALSYM IOCSIZE_MASK}
  IOCSIZE_SHIFT        = (_IOC_SIZESHIFT);
  {$EXTERNALSYM IOCSIZE_SHIFT}


// Translated from linux/include/asm-i386/ioctls.h

{ 0x54 is just a magic number to make these relatively unique ('T') }

const
  TCGETS          = $5401;
  {$EXTERNALSYM TCGETS}
  TCSETS          = $5402;
  {$EXTERNALSYM TCSETS}
  TCSETSW         = $5403;
  {$EXTERNALSYM TCSETSW}
  TCSETSF         = $5404;
  {$EXTERNALSYM TCSETSF}
  TCGETA          = $5405;
  {$EXTERNALSYM TCGETA}
  TCSETA          = $5406;
  {$EXTERNALSYM TCSETA}
  TCSETAW         = $5407;
  {$EXTERNALSYM TCSETAW}
  TCSETAF         = $5408;
  {$EXTERNALSYM TCSETAF}
  TCSBRK          = $5409;
  {$EXTERNALSYM TCSBRK}
  TCXONC          = $540A;
  {$EXTERNALSYM TCXONC}
  TCFLSH          = $540B;
  {$EXTERNALSYM TCFLSH}
  TIOCEXCL        = $540C;
  {$EXTERNALSYM TIOCEXCL}
  TIOCNXCL        = $540D;
  {$EXTERNALSYM TIOCNXCL}
  TIOCSCTTY       = $540E;
  {$EXTERNALSYM TIOCSCTTY}
  TIOCGPGRP       = $540F;
  {$EXTERNALSYM TIOCGPGRP}
  TIOCSPGRP       = $5410;
  {$EXTERNALSYM TIOCSPGRP}
  TIOCOUTQ        = $5411;
  {$EXTERNALSYM TIOCOUTQ}
  TIOCSTI         = $5412;
  {$EXTERNALSYM TIOCSTI}
  TIOCGWINSZ      = $5413;
  {$EXTERNALSYM TIOCGWINSZ}
  TIOCSWINSZ      = $5414;
  {$EXTERNALSYM TIOCSWINSZ}
  TIOCMGET        = $5415;
  {$EXTERNALSYM TIOCMGET}
  TIOCMBIS        = $5416;
  {$EXTERNALSYM TIOCMBIS}
  TIOCMBIC        = $5417;
  {$EXTERNALSYM TIOCMBIC}
  TIOCMSET        = $5418;
  {$EXTERNALSYM TIOCMSET}
  TIOCGSOFTCAR    = $5419;
  {$EXTERNALSYM TIOCGSOFTCAR}
  TIOCSSOFTCAR    = $541A;
  {$EXTERNALSYM TIOCSSOFTCAR}
  FIONREAD        = $541B;
  {$EXTERNALSYM FIONREAD}
  TIOCINQ         = FIONREAD;
  {$EXTERNALSYM TIOCINQ}
  TIOCLINUX       = $541C;
  {$EXTERNALSYM TIOCLINUX}
  TIOCCONS        = $541D;
  {$EXTERNALSYM TIOCCONS}
  TIOCGSERIAL     = $541E;
  {$EXTERNALSYM TIOCGSERIAL}
  TIOCSSERIAL     = $541F;
  {$EXTERNALSYM TIOCSSERIAL}
  TIOCPKT         = $5420;
  {$EXTERNALSYM TIOCPKT}
  FIONBIO         = $5421;
  {$EXTERNALSYM FIONBIO}
  TIOCNOTTY       = $5422;
  {$EXTERNALSYM TIOCNOTTY}
  TIOCSETD        = $5423;
  {$EXTERNALSYM TIOCSETD}
  TIOCGETD        = $5424;
  {$EXTERNALSYM TIOCGETD}
  TCSBRKP         = $5425;    { Needed for POSIX tcsendbreak() }
  {$EXTERNALSYM TCSBRKP}
  TIOCTTYGSTRUCT  = $5426;    { For debugging only }
  {$EXTERNALSYM TIOCTTYGSTRUCT}
  TIOCSBRK        = $5427;    { BSD compatibility }
  {$EXTERNALSYM TIOCSBRK}
  TIOCCBRK        = $5428;    { BSD compatibility }
  {$EXTERNALSYM TIOCCBRK}
  TIOCGSID        = $5429;    { Return the session ID of FD }
  {$EXTERNALSYM TIOCGSID}

function TIOCGPTN: Cardinal;   { Get Pty Number (of pty-mux device) }
{$EXTERNALSYM TIOCGPTN}
function TIOCSPTLCK: Cardinal; { Lock/unlock Pty }
{$EXTERNALSYM TIOCSPTLCK}

const
  FIONCLEX        = $5450; { these numbers need to be adjusted. }
  {$EXTERNALSYM FIONCLEX}
  FIOCLEX         = $5451;
  {$EXTERNALSYM FIOCLEX}
  FIOASYNC        = $5452;
  {$EXTERNALSYM FIOASYNC}
  TIOCSERCONFIG   = $5453;
  {$EXTERNALSYM TIOCSERCONFIG}
  TIOCSERGWILD    = $5454;
  {$EXTERNALSYM TIOCSERGWILD}
  TIOCSERSWILD    = $5455;
  {$EXTERNALSYM TIOCSERSWILD}
  TIOCGLCKTRMIOS  = $5456;
  {$EXTERNALSYM TIOCGLCKTRMIOS}
  TIOCSLCKTRMIOS  = $5457;
  {$EXTERNALSYM TIOCSLCKTRMIOS}
  TIOCSERGSTRUCT  = $5458;  { For debugging only }
  {$EXTERNALSYM TIOCSERGSTRUCT}
  TIOCSERGETLSR   = $5459;  { Get line status register }
  {$EXTERNALSYM TIOCSERGETLSR}
  TIOCSERGETMULTI = $545A;  { Get multiport config  }
  {$EXTERNALSYM TIOCSERGETMULTI}
  TIOCSERSETMULTI = $545B;  { Set multiport config }
  {$EXTERNALSYM TIOCSERSETMULTI}

  TIOCMIWAIT      = $545C;  { wait for a change on serial input line(s) }
  {$EXTERNALSYM TIOCMIWAIT}
  TIOCGICOUNT     = $545D;  { read serial port inline interrupt counts }
  {$EXTERNALSYM TIOCGICOUNT}
  TIOCGHAYESESP   = $545E;  { Get Hayes ESP configuration }
  {$EXTERNALSYM TIOCGHAYESESP}
  TIOCSHAYESESP   = $545F;  { Set Hayes ESP configuration }
  {$EXTERNALSYM TIOCSHAYESESP}

{ Used for packet mode }
  TIOCPKT_DATA       = 0;
  {$EXTERNALSYM TIOCPKT_DATA}
  TIOCPKT_FLUSHREAD  = 1;
  {$EXTERNALSYM TIOCPKT_FLUSHREAD}
  TIOCPKT_FLUSHWRITE = 2;
  {$EXTERNALSYM TIOCPKT_FLUSHWRITE}
  TIOCPKT_STOP       = 4;
  {$EXTERNALSYM TIOCPKT_STOP}
  TIOCPKT_START      = 8;
  {$EXTERNALSYM TIOCPKT_START}
  TIOCPKT_NOSTOP     = 16;
  {$EXTERNALSYM TIOCPKT_NOSTOP}
  TIOCPKT_DOSTOP     = 32;
  {$EXTERNALSYM TIOCPKT_DOSTOP}

  TIOCSER_TEMT       = $01;  { Transmitter physically empty }
  {$EXTERNALSYM TIOCSER_TEMT}


implementation

// Macros for ioctl.h

function _IOC(dir, __type, nr, size: Cardinal): Cardinal;
begin
  Result := (dir shl _IOC_DIRSHIFT) or
            (__type shl _IOC_TYPESHIFT) or
            (nr shl _IOC_NRSHIFT) or
            (size shl _IOC_SIZESHIFT);
end;

function _IO(__type, nr: Cardinal): Cardinal;
begin
  Result := _IOC(_IOC_NONE, __type, nr, 0);
end;                       

function __IOR(__type, nr: Cardinal; BufferSize: Cardinal): Cardinal;
begin
  Result := _IOC(_IOC_READ, __type, nr, BufferSize);
end;

function __IOW(__type, nr: Cardinal; BufferSize: Cardinal): Cardinal;
begin
  Result := _IOC(_IOC_WRITE, __type, nr, BufferSize);
end;

function __IOWR(__type, nr: Cardinal; BufferSize: Cardinal): Cardinal;
begin
  Result := _IOC(_IOC_READ or _IOC_WRITE, __type, nr, BufferSize);
end;

function _IOC_DIR(nr: Cardinal): Cardinal;
begin
  Result := (nr shr _IOC_DIRSHIFT) and _IOC_DIRMASK;
end;

function _IOC_TYPE(nr: Cardinal): Cardinal;
begin
  Result := (nr shr _IOC_TYPESHIFT) and _IOC_TYPEMASK;
end;

function _IOC_NR(nr: Cardinal): Cardinal;
begin
  Result := (nr shr _IOC_NRSHIFT) and _IOC_NRMASK;
end;

function _IOC_SIZE(nr: Cardinal): Cardinal;
begin
  Result := (nr shr _IOC_SIZESHIFT) and _IOC_SIZEMASK;
end;

// Macros for ioctls.h

function TIOCGPTN: Cardinal;
begin
  Result := __IOR(Ord('T'), $30, SizeOf(Cardinal));   { Get Pty Number (of pty-mux device) }
end;

function TIOCSPTLCK: Cardinal;
begin
  Result := __IOW(Ord('T'), $31, SizeOf(Integer));  { Lock/unlock Pty }
end;

end.
