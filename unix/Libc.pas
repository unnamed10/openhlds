{ *********************************************************************** }
{                                                                         }
{  Borland Kylix Runtime Library                                          }
{  Linux API Interface Unit                                               }
{                                                                         }
{  This translation is based on glibc 2.2.1,                              }
{  compiled from sources on a Linux 2.2.16 kernel.                        }
{                                                                         }
{  Copyright (C) 2001 Borland Software Corporation                        }
{                                                                         }
{  Translator: Borland Software Corporation                               }
{                                                                         }
{  This file may be distributed and/or modified under the terms of the    }
{  GNU General Public License version 2 as published by the Free Software }
{  Foundation and appearing at http://www.borland.com/kylix/gpl.html.     }
{                                                                         }
{  Licensees holding a valid Borland No-Nonsense License for this         }
{  Software may use this file in accordance with such license, which      }
{  appears in the file license.txt that came with this software.          }
{                                                                         }
{ *********************************************************************** }

unit Libc;


{ The following functions and identifiers are renamed to avoid name
  conflicts with existing Delphi reserved words or RTL identifiers:


  chdir   =>  __chdir    /   System.ChDir
  mkdir   =>  __mkdir    /   System.MkDir
  rmdir   =>  __rmdir    /   System.RmDir
  rename  =>  __rename   /   System.Rename
  exit    =>  __exit     /   System.Exit
  truncate => __truncate /   System.Truncate
  random  =>  __random   /   System.Random
  EOF     =>  __EOF      /   System.EOF()
  close   =>  __close    /   System.Close

  time    =>  __time     /   SysUtils.Time
  abort   =>  __abort    /   SysUtils.Abort
  strcat  =>  __strcat   /   SysUtils.StrCat
  strlen  =>  __strlen   /   SysUtils.StrLen

  abs     =>  __abs      /   abs operator
  div     =>  __div      /   div operator
  raise   =>  __raise    /   raise statement
  index   =>  __index    /   index keyword
  sleep   =>  __sleep    /   SysUtils.sleep(milliseconds)

  flock   =>  __flock    /   C header naming conflict with flock type
  timercmp => __timercmp /   Slightly different prototype

  read    =>  __read     /   System.Read
  write   =>  __write    /   System.Write
}

interface

uses Default, KernelDefs, KernelIoctl;

{$WEAKPACKAGEUNIT}

{$ALIGN 4}
{$MINENUMSIZE 4}
{$ASSERTIONS OFF}


// Misc Types

type
  UInt64 = 0..High(Int64);      // Create unsigned Int64 (with 63 bits).
//  UInt64 = Int64;
  wchar_t = System.UCS4Char;
  {$EXTERNALSYM wchar_t}
  Pwchar_t = System.PUCS4Char;
  PPwchar_t = ^Pwchar_t;
  size_t = LongWord;            // malloc.h
  {$EXTERNALSYM size_t}
  Psize_t = size_t;
  ptrdiff_t = Integer;          // malloc.h
  {$EXTERNALSYM ptrdiff_t}
  __ptr_t = Pointer;            // sys/cdefs.h
  {$EXTERNALSYM __ptr_t}
  __long_double_t = Extended;   // sys/cdefs.h
  {$EXTERNALSYM __long_double_t}

type
  TFileDescriptor = type Integer;

const
  stdin   = 0;
  stdout  = 1;
  stderr  = 2;
  
// Translated from endian.h and bits/endian.h

{ Definitions for byte order, according to significance of bytes, from low
   addresses to high addresses.  The value is what you get by putting '4'
   in the most significant byte, '3' in the second most significant byte,
   '2' in the second least significant byte, and '1' in the least
   significant byte.  }

const
  __LITTLE_ENDIAN = 1234;
  {$EXTERNALSYM __LITTLE_ENDIAN}
  __BIG_ENDIAN    = 4321;
  {$EXTERNALSYM __BIG_ENDIAN}
  __PDP_ENDIAN    = 3412;
  {$EXTERNALSYM __PDP_ENDIAN}
  __BYTE_ORDER      = __LITTLE_ENDIAN;
  {$EXTERNALSYM __BYTE_ORDER}
  __FLOAT_WORD_ORDER  = __BYTE_ORDER;
  {$EXTERNALSYM __FLOAT_WORD_ORDER}

  LITTLE_ENDIAN   = __LITTLE_ENDIAN;
  {$EXTERNALSYM LITTLE_ENDIAN}
  BIG_ENDIAN      = __BIG_ENDIAN;
  {$EXTERNALSYM BIG_ENDIAN}
  PDP_ENDIAN      = __PDP_ENDIAN;
  {$EXTERNALSYM PDP_ENDIAN}
  BYTE_ORDER      = __BYTE_ORDER;
  {$EXTERNALSYM BYTE_ORDER}


// Translated from bits/types.h

{ Convenience types.  }
type
  __u_char = Byte;
  {$EXTERNALSYM __u_char}
  __u_short = Word;
  {$EXTERNALSYM __u_short}
  __u_int = Cardinal;
  {$EXTERNALSYM __u_int}
  __u_long = LongWord;
  {$EXTERNALSYM __u_long}
  __u_quad_t = UInt64;     
  {$EXTERNALSYM __u_quad_t}
  __quad_t = Int64;
  {$EXTERNALSYM __quad_t}
  __int8_t = Shortint;
  {$EXTERNALSYM __int8_t}
  __uint8_t = Byte;
  {$EXTERNALSYM __uint8_t}
  __int16_t = Smallint;
  {$EXTERNALSYM __int16_t}
  __uint16_t = Word;
  {$EXTERNALSYM __uint16_t}
  __int32_t = Longint;
  {$EXTERNALSYM __int32_t}
  __uint32_t = LongWord;
  {$EXTERNALSYM __uint32_t}
  __int64_t = Int64;
  {$EXTERNALSYM __int64_t}
  __uint64_t = UInt64;
  {$EXTERNALSYM __uint64_t}
  __qaddr_t = ^__quad_t;
  {$EXTERNALSYM __qaddr_t}

  __dev_t = __u_quad_t;                 { Type of device numbers.  }
  {$EXTERNALSYM __dev_t}
  __uid_t = __u_int;                    { Type of user identifications.  }
  {$EXTERNALSYM __uid_t}
  __gid_t = __u_int;                    { Type of group identifications.  }
  {$EXTERNALSYM __gid_t}
  __ino_t = __u_long;                   { Type of file serial numbers.  }
  {$EXTERNALSYM __ino_t}
  __mode_t = __u_int;                   { Type of file attribute bitmasks.  }
  {$EXTERNALSYM __mode_t}
  __nlink_t = __u_int;                  { Type of file link counts.  }
  {$EXTERNALSYM __nlink_t}
  __off_t = Longint;                    { Type of file sizes and offsets.  }
  {$EXTERNALSYM __off_t}
  __loff_t = __quad_t;                  { Type of file sizes and offsets.  }
  {$EXTERNALSYM __loff_t}
  __pid_t = Integer;                    { Type of process identifications.  }
  {$EXTERNALSYM __pid_t}
  __ssize_t = Integer;                  { Type of a byte count, or error.  }
  {$EXTERNALSYM __ssize_t}
  __rlim_t = __u_long;                  { Type of resource counts.  }
  {$EXTERNALSYM __rlim_t}
  __rlim64_t = __u_quad_t;             { Type of resource counts (LFS).  }
  {$EXTERNALSYM __rlim64_t}
  __id_t = __u_int;                     { General type for ID.  }
  {$EXTERNALSYM __id_t}

{ Type of file system IDs.  }
  __fsid_t = {packed} record
    __val: packed array[0..1] of Integer;
  end;
  {$EXTERNALSYM __fsid_t}
  TFsID = __fsid_t;
  PFsID = ^TFsID;

{ Everythin' else.  }
  __daddr_t = Integer;                  { The type of a disk address.  }
  {$EXTERNALSYM __daddr_t}
  __caddr_t = PChar;
  {$EXTERNALSYM __caddr_t}
  __time_t = type Longint;
  {$EXTERNALSYM __time_t}
  __useconds_t = Cardinal;
  {$EXTERNALSYM __useconds_t}
  __suseconds_t = Longint;
  {$EXTERNALSYM __suseconds_t}
  __swblk_t = Longint;                  { Type of a swap block maybe?  }
  {$EXTERNALSYM __swblk_t}

  __clock_t = Longint;
  {$EXTERNALSYM __clock_t}

{ Clock ID used in clock and timer functions.  }
  __clockid_t = Integer;
  {$EXTERNALSYM __clockid_t}

{ Timer ID returned by `timer_create'.  }
  __timer_t = Integer;
  {$EXTERNALSYM __timer_t}

{ One element in the file descriptor mask array.  }
  __fd_mask = LongWord;
  {$EXTERNALSYM __fd_mask}

{ Number of descriptors that can fit in an `fd_set'.  }
const
  __FD_SETSIZE    = 1024;
  {$EXTERNALSYM __FD_SETSIZE}

{ It's easier to assume 8-bit bytes than to get CHAR_BIT.  }
  __NFDBITS       = 8 * sizeof(__fd_mask);
  {$EXTERNALSYM __NFDBITS}

function __FDELT(d: TFileDescriptor): Integer;
{$EXTERNALSYM __FDELT}
function __FDMASK(d: TFileDescriptor): __fd_mask;
{$EXTERNALSYM __FDMASK}

{ fd_set for select and pselect.  }
type
  __fd_set = {packed} record { XPG4.2 requires this member name.  Otherwise avoid the name
       from the global namespace.  }
    fds_bits: packed array[0..(__FD_SETSIZE div __NFDBITS)-1] of __fd_mask;
  end;
  {$EXTERNALSYM __fd_set}
  TFdSet = __fd_set;
  PFdSet = ^TFdSet;

  __key_t = Integer;
  {$EXTERNALSYM __key_t}

{ Used in `struct shmid_ds'.  }
  __ipc_pid_t = Word;
  {$EXTERNALSYM __ipc_pid_t}

{ Type to represent block size.  }
  __blksize_t = Longint;
  {$EXTERNALSYM __blksize_t}

{ Types from the Large File Support interface.  }

{ Type to count number os disk blocks.  }
  __blkcnt_t = Longint;
  {$EXTERNALSYM __blkcnt_t}
  __blkcnt64_t = __quad_t;
  {$EXTERNALSYM __blkcnt64_t}

{ Type to count file system blocks.  }
  __fsblkcnt_t = __u_long;
  {$EXTERNALSYM __fsblkcnt_t}
  __fsblkcnt64_t = __u_quad_t;
  {$EXTERNALSYM __fsblkcnt64_t}

{ Type to count file system inodes.  }
  __fsfilcnt_t = __u_long;
  {$EXTERNALSYM __fsfilcnt_t}
  __fsfilcnt64_t = __u_quad_t; 
  {$EXTERNALSYM __fsfilcnt64_t}

{ Type of file serial numbers.  }
  __ino64_t = __u_quad_t;
  {$EXTERNALSYM __ino64_t}

{ Type of file sizes and offsets.  }
  __off64_t = __loff_t;
  {$EXTERNALSYM __off64_t}

{ Used in XTI.  }
  __t_scalar_t = Longint;
  {$EXTERNALSYM __t_scalar_t}
  __t_uscalar_t = LongWord;
  {$EXTERNALSYM __t_uscalar_t}

  __intptr_t = Integer;
  {$EXTERNALSYM __intptr_t}


  // Type for length arguments in socket calls,
  __socklen_t = Cardinal;
  {$EXTERNALSYM __socklen_t}
  socklen_t = __socklen_t;
  {$EXTERNALSYM socklen_t}
  PSocketLength = ^socklen_t;

// Translated from sys/types.h

type
  u_char = __u_char;
  {$EXTERNALSYM u_char}
  u_short = __u_short;
  {$EXTERNALSYM u_short}
  u_int = __u_int;
  {$EXTERNALSYM u_int}
  u_long = __u_long;
  {$EXTERNALSYM u_long}
  quad_t = __quad_t;
  {$EXTERNALSYM quad_t}
  u_quad_t = __u_quad_t;
  {$EXTERNALSYM u_quad_t}
  fsid_t = __fsid_t;
  {$EXTERNALSYM fsid_t}

  loff_t = __loff_t;
  {$EXTERNALSYM loff_t}

  ino_t = __ino_t;
  {$EXTERNALSYM ino_t}
  ino64_t = __ino64_t;
  {$EXTERNALSYM ino64_t}

  dev_t = __dev_t;
  {$EXTERNALSYM dev_t}

  gid_t = __gid_t;
  {$EXTERNALSYM gid_t}

  mode_t = __mode_t;
  {$EXTERNALSYM mode_t}

  nlink_t = __nlink_t;
  {$EXTERNALSYM nlink_t}

  uid_t = __uid_t;
  {$EXTERNALSYM uid_t}

  off_t = __off_t;
  {$EXTERNALSYM off_t}
  off64_t = __off64_t;
  {$EXTERNALSYM off64_t}

  pid_t = __pid_t;
  {$EXTERNALSYM pid_t}

  id_t = __id_t;
  {$EXTERNALSYM id_t}

  ssize_t = __ssize_t;
  {$EXTERNALSYM ssize_t}

  daddr_t = __daddr_t;
  {$EXTERNALSYM daddr_t}
  caddr_t = __caddr_t;
  {$EXTERNALSYM caddr_t}

  key_t = __key_t;
  {$EXTERNALSYM key_t}

  useconds_t = __useconds_t;
  {$EXTERNALSYM useconds_t}
  // Defined in time.h: suseconds_t = __suseconds_t;
  // Defined in time.h: {$EXTERNALSYM suseconds_t}

{ Old compatibility names for C types.  }
  ulong = LongWord;
  {$EXTERNALSYM ulong}
  ushort = Word;
  {$EXTERNALSYM ushort}
  uint = Cardinal;
  {$EXTERNALSYM uint}

{ These types are defined by the ISO C 9x header <inttypes.h>. }
  int8_t = Shortint;
  {$EXTERNALSYM int8_t}
  int16_t = Smallint;
  {$EXTERNALSYM int16_t}
  int32_t = Integer;
  {$EXTERNALSYM int32_t}
  int64_t = Int64;
  {$EXTERNALSYM int64_t}

{ But these were defined by ISO C without the first `_'.  }
  u_int8_t = Byte;
  {$EXTERNALSYM u_int8_t}
  u_int16_t = Word;
  {$EXTERNALSYM u_int16_t}
  u_int32_t = Cardinal;
  {$EXTERNALSYM u_int32_t}
  u_int64_t = UInt64;
  {$EXTERNALSYM u_int64_t}
  register_t = Integer;
  {$EXTERNALSYM register_t}

  blksize_t = __blksize_t;
  {$EXTERNALSYM blksize_t}

{ Types from the Large File Support interface.  }

  blkcnt_t = __blkcnt_t;         { Type to count number of disk blocks.  }
  {$EXTERNALSYM blkcnt_t}
  fsblkcnt_t = __fsblkcnt_t;     { Type to count file system blocks.  }
  {$EXTERNALSYM fsblkcnt_t}
  fsfilcnt_t = __fsfilcnt_t;     { Type to count file system inodes.  }
  {$EXTERNALSYM fsfilcnt_t}

  blkcnt64_t = __blkcnt64_t;         { Type to count number of disk blocks. }
  {$EXTERNALSYM blkcnt64_t}
  fsblkcnt64_t = __fsblkcnt64_t;     { Type to count file system blocks.  }
  {$EXTERNALSYM fsblkcnt64_t}
  fsfilcnt64_t = __fsfilcnt64_t;     { Type to count file system inodes.  }
  {$EXTERNALSYM fsfilcnt64_t}


// Translated from bits/posix_opt.h

const
{ Job control is supported.  }
  _POSIX_JOB_CONTROL = 1;
  {$EXTERNALSYM _POSIX_JOB_CONTROL}

{ Processes have a saved set-user-ID and a saved set-group-ID.  }
  _POSIX_SAVED_IDS = 1;
  {$EXTERNALSYM _POSIX_SAVED_IDS}

{ Priority scheduling is supported.  }
  _POSIX_PRIORITY_SCHEDULING = 1;
  {$EXTERNALSYM _POSIX_PRIORITY_SCHEDULING}

{ Synchronizing file data is supported.  }
  _POSIX_SYNCHRONIZED_IO = 1;
  {$EXTERNALSYM _POSIX_SYNCHRONIZED_IO}

{ The fsync function is present.  }
  _POSIX_FSYNC = 1;
  {$EXTERNALSYM _POSIX_FSYNC}

{ Mapping of files to memory is supported.  }
  _POSIX_MAPPED_FILES = 1;
  {$EXTERNALSYM _POSIX_MAPPED_FILES}

{ Locking of all memory is supported.  }
  _POSIX_MEMLOCK = 1;
  {$EXTERNALSYM _POSIX_MEMLOCK}

{ Locking of ranges of memory is supported.  }
  _POSIX_MEMLOCK_RANGE = 1;
  {$EXTERNALSYM _POSIX_MEMLOCK_RANGE}

{ Setting of memory protections is supported.  }
  _POSIX_MEMORY_PROTECTION = 1;
  {$EXTERNALSYM _POSIX_MEMORY_PROTECTION}

{ Implementation supports `poll' function.  }
  _POSIX_POLL = 1;
  {$EXTERNALSYM _POSIX_POLL}

{ Implementation supports `select' and `pselect' functions.  }
  _POSIX_SELECT = 1;
  {$EXTERNALSYM _POSIX_SELECT}

{ Only root can change owner of file.  }
  _POSIX_CHOWN_RESTRICTED = 1;
  {$EXTERNALSYM _POSIX_CHOWN_RESTRICTED}

{ `c_cc' member of 'struct termios' structure can be disabled by
   using the value _POSIX_VDISABLE.  }
  _POSIX_VDISABLE = #0;
  {$EXTERNALSYM _POSIX_VDISABLE}

{ Filenames are not silently truncated.  }
  _POSIX_NO_TRUNC = 1;
  {$EXTERNALSYM _POSIX_NO_TRUNC}

{ X/Open realtime support is available.  }
  _XOPEN_REALTIME = 1;
  {$EXTERNALSYM _XOPEN_REALTIME}

{ X/Open realtime thread support is available.  }
  _XOPEN_REALTIME_THREADS = 1;
  {$EXTERNALSYM _XOPEN_REALTIME_THREADS}

{ XPG4.2 shared memory is supported.  }
  _XOPEN_SHM = 1;
  {$EXTERNALSYM _XOPEN_SHM}

{ Tell we have POSIX threads.  }
  _POSIX_THREADS = 1;
  {$EXTERNALSYM _POSIX_THREADS}

{ We have the reentrant functions described in POSIX.  }
  _POSIX_REENTRANT_FUNCTIONS = 1;
  {$EXTERNALSYM _POSIX_REENTRANT_FUNCTIONS}
  _POSIX_THREAD_SAFE_FUNCTIONS = 1;
  {$EXTERNALSYM _POSIX_THREAD_SAFE_FUNCTIONS}

{ We provide priority scheduling for threads.  }
  _POSIX_THREAD_PRIORITY_SCHEDULING = 1;
  {$EXTERNALSYM _POSIX_THREAD_PRIORITY_SCHEDULING}

{ We support user-defined stack sizes.  }
  _POSIX_THREAD_ATTR_STACKSIZE = 1;
  {$EXTERNALSYM _POSIX_THREAD_ATTR_STACKSIZE}

{ We support user-defined stacks.  }
  _POSIX_THREAD_ATTR_STACKADDR = 1;
  {$EXTERNALSYM _POSIX_THREAD_ATTR_STACKADDR}

{ We support POSIX.1b semaphores, but only the non-shared form for now.  }
  _POSIX_SEMAPHORES = 1;
  {$EXTERNALSYM _POSIX_SEMAPHORES}

{ Real-time signals are supported.  }
  _POSIX_REALTIME_SIGNALS = 1;
  {$EXTERNALSYM _POSIX_REALTIME_SIGNALS}

{ We support asynchronous I/O.  }
  _POSIX_ASYNCHRONOUS_IO = 1;
  {$EXTERNALSYM _POSIX_ASYNCHRONOUS_IO}
{ Alternative name for Unix98.  }
  _LFS_ASYNCHRONOUS_IO = 1;
  {$EXTERNALSYM _LFS_ASYNCHRONOUS_IO}

{ The LFS support in asynchronous I/O is also available.  }
  _LFS64_ASYNCHRONOUS_IO = 1;
  {$EXTERNALSYM _LFS64_ASYNCHRONOUS_IO}

{ The rest of the LFS is also available.  }
  _LFS_LARGEFILE = 1;
  {$EXTERNALSYM _LFS_LARGEFILE}
  _LFS64_LARGEFILE = 1;
  {$EXTERNALSYM _LFS64_LARGEFILE}
  _LFS64_STDIO = 1;
  {$EXTERNALSYM _LFS64_STDIO}

{ POSIX shared memory objects are implemented.  }
  _POSIX_SHARED_MEMORY_OBJECTS = 1;
  {$EXTERNALSYM _POSIX_SHARED_MEMORY_OBJECTS}

{ CPU-time clocks supported.  }
  _POSIX_CPUTIME = 200912;
  {$EXTERNALSYM _POSIX_CPUTIME}

{ We support the clock also in threads.  }
  _POSIX_THREAD_CPUTIME = 200912;
  {$EXTERNALSYM _POSIX_THREAD_CPUTIME}

{ GNU libc provides regular expression handling.  }
  _POSIX_REGEXP = 1;
  {$EXTERNALSYM _POSIX_REGEXP}

{ Reader/Writer locks are available.  }
  _POSIX_READER_WRITER_LOCKS = 200912;
  {$EXTERNALSYM _POSIX_READER_WRITER_LOCKS}

{ We have a POSIX shell.  }
  _POSIX_SHELL = 1;
  {$EXTERNALSYM _POSIX_SHELL}

{ We support the Timeouts option.  }
  _POSIX_TIMEOUTS = 200912;
  {$EXTERNALSYM _POSIX_TIMEOUTS}

{ We support spinlocks.  }
  _POSIX_SPIN_LOCKS = 200912;
  {$EXTERNALSYM _POSIX_SPIN_LOCKS}

{ The `spawn' function family is supported.  }
  _POSIX_SPAWN = 200912;
  {$EXTERNALSYM _POSIX_SPAWN}

{ We have POSIX timers.  }
  _POSIX_TIMERS = 1;
  {$EXTERNALSYM _POSIX_TIMERS}

{ The barrier functions are available.  }
  _POSIX_BARRIERS = 200912;
  {$EXTERNALSYM _POSIX_BARRIERS}


// Translated from stdint.h (remaining types not defined yet elsewhere)

{ Exact integral types.  }

{ Signed.  }

{ There is some amount of overlap with <sys/types.h> as known by inet code }
type
  //int8_t = Shortint;
  //{$EXTERNALSYM int8_t}
  //int16_t = Smallint;
  //{$EXTERNALSYM int16_t}
  //int32_t = Longint;
  //{$EXTERNALSYM int32_t}
  //int64_t = Int64;
  //{$EXTERNALSYM int64_t}

{ Unsigned.  }
  uint8_t = Byte;
  {$EXTERNALSYM uint8_t}
  uint16_t = Word;
  {$EXTERNALSYM uint16_t}
  uint32_t = LongWord;
  {$EXTERNALSYM uint32_t}
  uint64_t = UInt64;
  {$EXTERNALSYM uint64_t}

{ Small types.  }

{ Signed.  }
  int_least8_t = Shortint;
  {$EXTERNALSYM int_least8_t}
  int_least16_t = Smallint;
  {$EXTERNALSYM int_least16_t}
  int_least32_t = Longint;
  {$EXTERNALSYM int_least32_t}
  int_least64_t = Int64;
  {$EXTERNALSYM int_least64_t}

{ Unsigned.  }
  uint_least8_t = Byte;
  {$EXTERNALSYM uint_least8_t}
  uint_least16_t = Word;
  {$EXTERNALSYM uint_least16_t}
  uint_least32_t = LongWord;
  {$EXTERNALSYM uint_least32_t}
  uint_least64_t = UInt64;
  {$EXTERNALSYM uint_least64_t}

{ Fast types.  }

{ Signed.  }
  int_fast8_t = Shortint;
  {$EXTERNALSYM int_fast8_t}
  int_fast16_t = Integer;
  {$EXTERNALSYM int_fast16_t}
  int_fast32_t = Integer;
  {$EXTERNALSYM int_fast32_t}
  int_fast64_t = Int64;
  {$EXTERNALSYM int_fast64_t}

{ Unsigned.  }
  uint_fast8_t = Byte;
  {$EXTERNALSYM uint_fast8_t}
  uint_fast16_t = Cardinal;
  {$EXTERNALSYM uint_fast16_t}
  uint_fast32_t = Cardinal;
  {$EXTERNALSYM uint_fast32_t}
  uint_fast64_t = UInt64;
  {$EXTERNALSYM uint_fast64_t}


{ Types for `void *' pointers.  }
  intptr_t = Integer;
  {$EXTERNALSYM intptr_t}
  uintptr_t = Cardinal;
  {$EXTERNALSYM uintptr_t}


{ Largest integral types.  }
  intmax_t = Int64;
  {$EXTERNALSYM intmax_t}
  uintmax_t = UInt64;
  {$EXTERNALSYM uintmax_t}


{ Limits of integral types.  }
const
{ Minimum of signed integral types.  }
  INT8_MIN              = int8_t(-128);
  {$EXTERNALSYM INT8_MIN}
  INT16_MIN             = int16_t(-32767-1);
  {$EXTERNALSYM INT16_MIN}
  INT32_MIN             = int32_t(-2147483647-1);
  {$EXTERNALSYM INT32_MIN}
  INT64_MIN             = int64_t(-int64_t(9223372036854775807)-1);
  {$EXTERNALSYM INT64_MIN}
{ Maximum of signed integral types.  }
  INT8_MAX              = int8_t(127);
  {$EXTERNALSYM INT8_MAX}
  INT16_MAX             = int16_t(32767);
  {$EXTERNALSYM INT16_MAX}
  INT32_MAX             = int32_t(2147483647);
  {$EXTERNALSYM INT32_MAX}
  INT64_MAX             = int64_t(9223372036854775807);
  {$EXTERNALSYM INT64_MAX}

{ Maximum of unsigned integral types.  }
  UINT8_MAX             = uint8_t(255);
  {$EXTERNALSYM UINT8_MAX}
  UINT16_MAX            = uint16_t(65535);
  {$EXTERNALSYM UINT16_MAX}
  UINT32_MAX            = uint32_t(4294967295);
  {$EXTERNALSYM UINT32_MAX}
  UINT64_MAX            = uint64_t(-1);
  {$EXTERNALSYM UINT64_MAX}


{ Minimum of signed integral types having a minimum size.  }
  INT_LEAST8_MIN        = int_least8_t(-128);
  {$EXTERNALSYM INT_LEAST8_MIN}
  INT_LEAST16_MIN       = int_least16_t(-32767-1);
  {$EXTERNALSYM INT_LEAST16_MIN}
  INT_LEAST32_MIN       = int_least32_t(-2147483647-1);
  {$EXTERNALSYM INT_LEAST32_MIN}
  INT_LEAST64_MIN       = int_least64_t(-int64_t(9223372036854775807)-1);
  {$EXTERNALSYM INT_LEAST64_MIN}
{ Maximum of signed integral types having a minimum size.  }
  INT_LEAST8_MAX        = int_least8_t(127);
  {$EXTERNALSYM INT_LEAST8_MAX}
  INT_LEAST16_MAX       = int_least16_t(32767);
  {$EXTERNALSYM INT_LEAST16_MAX}
  INT_LEAST32_MAX       = int_least32_t(2147483647);
  {$EXTERNALSYM INT_LEAST32_MAX}
  INT_LEAST64_MAX       = int_least64_t(9223372036854775807);
  {$EXTERNALSYM INT_LEAST64_MAX}

{ Maximum of unsigned integral types having a minimum size.  }
  UINT_LEAST8_MAX       = uint_least8_t(255);
  {$EXTERNALSYM UINT_LEAST8_MAX}
  UINT_LEAST16_MAX      = uint_least16_t(65535);
  {$EXTERNALSYM UINT_LEAST16_MAX}
  UINT_LEAST32_MAX      = uint_least32_t(4294967295);
  {$EXTERNALSYM UINT_LEAST32_MAX}
  UINT_LEAST64_MAX      = uint_least64_t(-1);
  {$EXTERNALSYM UINT_LEAST64_MAX}


{ Minimum of fast signed integral types having a minimum size.  }
  INT_FAST8_MIN	        = int_fast8_t(-128);
  {$EXTERNALSYM INT_FAST8_MIN}
  INT_FAST16_MIN        = int_fast16_t(-2147483647-1);
  {$EXTERNALSYM INT_FAST16_MIN}
  INT_FAST32_MIN        = int_fast32_t(-2147483647-1);
  {$EXTERNALSYM INT_FAST32_MIN}
  INT_FAST64_MIN        = int_fast64_t(-Int64(9223372036854775807)-1);
  {$EXTERNALSYM INT_FAST64_MIN}
{ Maximum of fast signed integral types having a minimum size.  }
  INT_FAST8_MAX         = int_fast8_t(127);
  {$EXTERNALSYM INT_FAST8_MAX}
  INT_FAST16_MAX        = int_fast16_t(2147483647);
  {$EXTERNALSYM INT_FAST16_MAX}
  INT_FAST32_MAX        = int_fast32_t(2147483647);
  {$EXTERNALSYM INT_FAST32_MAX}
  INT_FAST64_MAX        = int_fast64_t(9223372036854775807);
  {$EXTERNALSYM INT_FAST64_MAX}

{ Maximum of fast unsigned integral types having a minimum size.  }
  UINT_FAST8_MAX        = uint_fast8_t(255);
  {$EXTERNALSYM UINT_FAST8_MAX}
  UINT_FAST16_MAX       = uint_fast16_t(4294967295);
  {$EXTERNALSYM UINT_FAST16_MAX}
  UINT_FAST32_MAX       = uint_fast32_t(4294967295);
  {$EXTERNALSYM UINT_FAST32_MAX}
  UINT_FAST64_MAX       = uint_fast64_t(-1);
  {$EXTERNALSYM UINT_FAST64_MAX}


{ Values to test for integral types holding `void *' pointer.  }
  INTPTR_MIN            = intptr_t(-2147483647-1);
  {$EXTERNALSYM INTPTR_MIN}
  INTPTR_MAX            = intptr_t(2147483647);
  {$EXTERNALSYM INTPTR_MAX}
  UINTPTR_MAX           = uintptr_t(4294967295);
  {$EXTERNALSYM UINTPTR_MAX}


{ Minimum for largest signed integral type.  }
  INTMAX_MIN            = Int64(-Int64(9223372036854775807)-1);
  {$EXTERNALSYM INTMAX_MIN}
{ Maximum for largest signed integral type.  }
  INTMAX_MAX            = Int64(9223372036854775807);
  {$EXTERNALSYM INTMAX_MAX}

{ Maximum for largest unsigned integral type.  }
  UINTMAX_MAX           = UInt64(-1);
  {$EXTERNALSYM UINTMAX_MAX}


{ Limits of other integer types.  }

{ Limits of `ptrdiff_t' type.  }
  PTRDIFF_MIN           = ptrdiff_t(-2147483647-1);
  {$EXTERNALSYM PTRDIFF_MIN}
  PTRDIFF_MAX           = ptrdiff_t(2147483647);
  {$EXTERNALSYM PTRDIFF_MAX}

{ Limits of `sig_atomic_t'.  }
  SIG_ATOMIC_MIN        = Integer(-2147483647-1);
  {$EXTERNALSYM SIG_ATOMIC_MIN}
  SIG_ATOMIC_MAX        = Integer(2147483647);
  {$EXTERNALSYM SIG_ATOMIC_MAX}

{ Limit of `size_t' type.  }
  SIZE_MAX              = size_t(4294967295);
  {$EXTERNALSYM SIZE_MAX}

{ Limits of `wchar_t'.  }
{ These constants have been defined in <wchar.h>.  }

{ Limits of `wint_t'.  }
  WINT_MIN              = Cardinal(0);
  {$EXTERNALSYM WINT_MIN}
  WINT_MAX              = Cardinal(4294967295);
  {$EXTERNALSYM WINT_MAX}


// Translated from bits/wordsize.h

const
  __WORDSIZE = 32;
  {$EXTERNALSYM __WORDSIZE}


// Translated from limits.h

{ ISO C99 Standard: 7.10/5.2.4.2.1 Sizes of integer types }

const
{ Maximum length of any multibyte character in any locale.
   We define this value here since the gcc header does not define
   the correct value.  }
  MB_LEN_MAX = 16;
  {$EXTERNALSYM MB_LEN_MAX}

{ We don't have #include_next.
   Define ANSI <limits.h> for standard 32-bit words.  }

{ These assume 8-bit `char's, 16-bit `short int's,
   and 32-bit `int's and `long int's.  }

{ Number of bits in a `char'.	}
  CHAR_BIT = 8;
  {$EXTERNALSYM CHAR_BIT}

{ Minimum and maximum values a `signed char' can hold.  }
  SCHAR_MIN = -128;
  {$EXTERNALSYM SCHAR_MIN}
  SCHAR_MAX = 127;
  {$EXTERNALSYM SCHAR_MAX}

{ Maximum value an `unsigned char' can hold.  (Minimum is 0.)  }
  UCHAR_MAX = 255;
  {$EXTERNALSYM UCHAR_MAX}

{ Minimum and maximum values a `char' can hold.  }
  CHAR_MIN  = SCHAR_MIN;
  {$EXTERNALSYM CHAR_MIN}
  CHAR_MAX  = SCHAR_MAX;
  {$EXTERNALSYM CHAR_MAX}

{ Minimum and maximum values a `signed short int' can hold.  }
  SHRT_MIN = -32768;
  {$EXTERNALSYM SHRT_MIN}
  SHRT_MAX = 32767;
  {$EXTERNALSYM SHRT_MAX}

{ Maximum value an `unsigned short int' can hold.  (Minimum is 0.)  }
  USHRT_MAX = 65535;
  {$EXTERNALSYM USHRT_MAX}

{ Minimum and maximum values a `signed int' can hold.  }
  INT_MAX = 2147483647;
  {$EXTERNALSYM INT_MAX}
  INT_MIN = (-INT_MAX - 1);
  {$EXTERNALSYM INT_MIN}

{ Maximum value an `unsigned int' can hold.  (Minimum is 0.)  }
  UINT_MAX = LongWord(4294967295);
  {$EXTERNALSYM UINT_MAX}

{ Minimum and maximum values a `signed long int' can hold.  }
  LONG_MAX = 2147483647;
  {$EXTERNALSYM LONG_MAX}
  LONG_MIN = (-LONG_MAX - 1);
  {$EXTERNALSYM LONG_MIN}

{ Maximum value an `unsigned long int' can hold.  (Minimum is 0.)  }
  ULONG_MAX = LongWord(4294967295);
  {$EXTERNALSYM ULONG_MAX}

{ Minimum and maximum values a `signed long long int' can hold.  }
  LLONG_MAX = Int64(9223372036854775807);
  {$EXTERNALSYM LLONG_MAX}
  LLONG_MIN = (-LLONG_MAX - 1);
  {$EXTERNALSYM LLONG_MIN}

{ Maximum value an `unsigned long long int' can hold.  (Minimum is 0.)  }
  ULLONG_MAX = $FFFFFFFFFFFFFFFF;
  {$EXTERNALSYM ULLONG_MAX}


// Translated from bits/posix1_lim.h

{ POSIX Standard: 2.9.2 Minimum Values }

{ These are the standard-mandated minimum values.  }

const
{ Minimum number of operations in one list I/O call.  }
  _POSIX_AIO_LISTIO_MAX         = 2;
  {$EXTERNALSYM _POSIX_AIO_LISTIO_MAX}

{ Minimal number of outstanding asynchronous I/O operations.  }
  _POSIX_AIO_MAX                = 1;
  {$EXTERNALSYM _POSIX_AIO_MAX}

{ Maximum length of arguments to `execve', including environment.  }
  _POSIX_ARG_MAX                = 4096;
  {$EXTERNALSYM _POSIX_ARG_MAX}

{ Maximum simultaneous processes per real user ID.  }
  _POSIX_CHILD_MAX              = 6;
  {$EXTERNALSYM _POSIX_CHILD_MAX}

{ Minimal number of timer expiration overruns.  }
  _POSIX_DELAYTIMER_MAX         = 32;
  {$EXTERNALSYM _POSIX_DELAYTIMER_MAX}

{ Maximum link count of a file.  }
  _POSIX_LINK_MAX               = 8;
  {$EXTERNALSYM _POSIX_LINK_MAX}

{ Number of bytes in a terminal canonical input queue.  }
  _POSIX_MAX_CANON              = 255;
  {$EXTERNALSYM _POSIX_MAX_CANON}

{ Number of bytes for which space will be
   available in a terminal input queue.  }
  _POSIX_MAX_INPUT              = 255;
  {$EXTERNALSYM _POSIX_MAX_INPUT}

{ Maximum number of message queues open for a process.  }
  _POSIX_MQ_OPEN_MAX            = 8;
  {$EXTERNALSYM _POSIX_MQ_OPEN_MAX}

{ Maximum number of supported message priorities.  }
  _POSIX_MQ_PRIO_MAX            = 32;
  {$EXTERNALSYM _POSIX_MQ_PRIO_MAX}

{ Number of simultaneous supplementary group IDs per process.  }
  _POSIX_NGROUPS_MAX            = 0;
  {$EXTERNALSYM _POSIX_NGROUPS_MAX}

{ Number of files one process can have open at once.  }
  _POSIX_OPEN_MAX               = 16;
  {$EXTERNALSYM _POSIX_OPEN_MAX}

{ Number of descriptors that a process may examine with `pselect' or
   `select'.  }
  _POSIX_FD_SETSIZE             = _POSIX_OPEN_MAX;
  {$EXTERNALSYM _POSIX_FD_SETSIZE}

{ Number of bytes in a filename.  }
  _POSIX_NAME_MAX               = 14;
  {$EXTERNALSYM _POSIX_NAME_MAX}

{ Number of bytes in a pathname.  }
  _POSIX_PATH_MAX               = 256;
  {$EXTERNALSYM _POSIX_PATH_MAX}

{ Number of bytes than can be written atomically to a pipe.  }
  _POSIX_PIPE_BUF               = 512;
  {$EXTERNALSYM _POSIX_PIPE_BUF}

{ Minimal number of realtime signals reserved for the application.  }
  _POSIX_RTSIG_MAX              = 8;
  {$EXTERNALSYM _POSIX_RTSIG_MAX}

{ Number of semaphores a process can have.  }
  _POSIX_SEM_NSEMS_MAX          = 256;
  {$EXTERNALSYM _POSIX_SEM_NSEMS_MAX}

{ Maximal value of a semaphore.  }
  _POSIX_SEM_VALUE_MAX          = 32767;
  {$EXTERNALSYM _POSIX_SEM_VALUE_MAX}

{ Number of pending realtime signals.  }
  _POSIX_SIGQUEUE_MAX           = 32;
  {$EXTERNALSYM _POSIX_SIGQUEUE_MAX}

{ Largest value of a `ssize_t'.  }
  _POSIX_SSIZE_MAX              = 32767;
  {$EXTERNALSYM _POSIX_SSIZE_MAX}

{ Number of streams a process can have open at once.  }
  _POSIX_STREAM_MAX             = 8;
  {$EXTERNALSYM _POSIX_STREAM_MAX}

{ Maximum length of a timezone name (element of `tzname').  }
  _POSIX_TZNAME_MAX             = 3;
  {$EXTERNALSYM _POSIX_TZNAME_MAX}

{ Maximum number of connections that can be queued on a socket.  }
  _POSIX_QLIMIT                 = 1;
  {$EXTERNALSYM _POSIX_QLIMIT}

{ Maximum number of bytes that can be buffered on a socket for send
   or receive.  }
  _POSIX_HIWAT                  = _POSIX_PIPE_BUF;
  {$EXTERNALSYM _POSIX_HIWAT}

{ Maximum number of elements in an `iovec' array.  }
  _POSIX_UIO_MAXIOV             = 16;
  {$EXTERNALSYM _POSIX_UIO_MAXIOV}

{ Maximum number of characters in a tty name.  }
  _POSIX_TTY_NAME_MAX           = 9;
  {$EXTERNALSYM _POSIX_TTY_NAME_MAX}

{ Number of timer for a process.  }
  _POSIX_TIMER_MAX              = 32;
  {$EXTERNALSYM _POSIX_TIMER_MAX}

{ Maximum length of login name.  }
  _POSIX_LOGIN_NAME_MAX         = 9;
  {$EXTERNALSYM _POSIX_LOGIN_NAME_MAX}

{ Maximum clock resolution in nanoseconds.  }
  _POSIX_CLOCKRES_MIN           = 20000000;
  {$EXTERNALSYM _POSIX_CLOCKRES_MIN}

{ Get the implementation-specific values for the above.  }
//#include <bits/local_lim.h>

  SSIZE_MAX                     = INT_MAX;
  {$EXTERNALSYM SSIZE_MAX}

{ This value is a guaranteed minimum maximum.
   The current maximum can be got from `sysconf'.  }

  NGROUPS_MAX                   = _POSIX_NGROUPS_MAX;
  {$EXTERNALSYM NGROUPS_MAX}


// Translated from bits/posix2_lim.h

const
{ The maximum `ibase' and `obase' values allowed by the `bc' utility.  }
  _POSIX2_BC_BASE_MAX           = 99;
  {$EXTERNALSYM _POSIX2_BC_BASE_MAX}

{ The maximum number of elements allowed in an array by the `bc' utility.  }
  _POSIX2_BC_DIM_MAX            = 2048;
  {$EXTERNALSYM _POSIX2_BC_DIM_MAX}

{ The maximum `scale' value allowed by the `bc' utility.  }
  _POSIX2_BC_SCALE_MAX          = 99;
  {$EXTERNALSYM _POSIX2_BC_SCALE_MAX}

{ The maximum length of a string constant accepted by the `bc' utility.  }
  _POSIX2_BC_STRING_MAX         = 1000;
  {$EXTERNALSYM _POSIX2_BC_STRING_MAX}

{ The maximum number of weights that can be assigned to an entry of
   the LC_COLLATE `order' keyword in the locale definition file.
   We have no fixed limit, 255 is very high.  }
  _POSIX2_COLL_WEIGHTS_MAX      = 255;
  {$EXTERNALSYM _POSIX2_COLL_WEIGHTS_MAX}

{ The maximum number of expressions that can be nested
   within parentheses by the `expr' utility.  }
  _POSIX2_EXPR_NEST_MAX         = 32;
  {$EXTERNALSYM _POSIX2_EXPR_NEST_MAX}

{ The maximum length, in bytes, of an input line.  }
  _POSIX2_LINE_MAX              = 2048;
  {$EXTERNALSYM _POSIX2_LINE_MAX}

// The maximum number of repeated occurrences of a regular expression
//   permitted when using the interval notation `\{M,N\}'.
  _POSIX2_RE_DUP_MAX            = 255;
  {$EXTERNALSYM _POSIX2_RE_DUP_MAX}

{ The maximum number of bytes in a character class name.  We have no
   fixed limit, 2048 is a high number.  }
  _POSIX2_CHARCLASS_NAME_MAX    = 2048;
  {$EXTERNALSYM _POSIX2_CHARCLASS_NAME_MAX}


{ These values are implementation-specific,
   and may vary within the implementation.
   Their precise values can be obtained from sysconf.  }

  BC_BASE_MAX                   = _POSIX2_BC_BASE_MAX;
  {$EXTERNALSYM BC_BASE_MAX}

  BC_DIM_MAX                    = _POSIX2_BC_DIM_MAX;
  {$EXTERNALSYM BC_DIM_MAX}

  BC_SCALE_MAX                  = _POSIX2_BC_SCALE_MAX;
  {$EXTERNALSYM BC_SCALE_MAX}

  BC_STRING_MAX                 = _POSIX2_BC_STRING_MAX;
  {$EXTERNALSYM BC_STRING_MAX}

  COLL_WEIGHTS_MAX              = _POSIX2_COLL_WEIGHTS_MAX;
  {$EXTERNALSYM COLL_WEIGHTS_MAX}

(* Defect in header file: _POSIX2_EQUIV_CLASS_MAX nowhere defined.
  EQUIV_CLASS_MAX               = _POSIX2_EQUIV_CLASS_MAX;
  {$EXTERNALSYM EQUIV_CLASS_MAX}
*)

  EXPR_NEST_MAX                 = _POSIX2_EXPR_NEST_MAX;
  {$EXTERNALSYM EXPR_NEST_MAX}

  LINE_MAX                      = _POSIX2_LINE_MAX;
  {$EXTERNALSYM LINE_MAX}

  CHARCLASS_NAME_MAX            = _POSIX2_CHARCLASS_NAME_MAX;
  {$EXTERNALSYM CHARCLASS_NAME_MAX}

(* Value is already defined in regex.h
{ This value is defined like this in regex.h.  }
  RE_DUP_MAX = ($7fff);
*)


// Translated from bits/xopen_lim.h

{ Additional definitions from X/Open Portability Guide, Issue 4, Version 2
   System Interfaces and Headers, 4.16 <limits.h>

   Please note only the values which are not greater than the minimum
   stated in the standard document are listed.  The `sysconf' functions
   should be used to obtain the actual value.  }

{ We do not provide fixed values for

   ARG_MAX	Maximum length of argument to the `exec' function
		including environment data.

   ATEXIT_MAX	Maximum number of functions that may be registered
		with `atexit'.

   CHILD_MAX	Maximum number of simultaneous processes per real
		user ID.

   OPEN_MAX	Maximum number of files that one process can have open
		at anyone time.

   PAGESIZE
   PAGE_SIZE	Size of bytes of a page.

   PASS_MAX	Maximum number of significant bytes in a password.

   We only provide a fixed limit for

   IOV_MAX	Maximum number of `iovec' structures that one process has
		available for use with `readv' or writev'.

   if this is indeed fixed by the underlying system.
}


{ Maximum number of `iovec' structures that one process has available
   for use with `readv' or writev'.  }
  _XOPEN_IOV_MAX                = _POSIX_UIO_MAXIOV;
  {$EXTERNALSYM _XOPEN_IOV_MAX}


{ Maximum value of `digit' in calls to the `printf' and `scanf'
   functions.  We have no limit, so return a reasonable value.  }
  NL_ARGMAX                     = _POSIX_ARG_MAX;
  {$EXTERNALSYM NL_ARGMAX}

{ Maximum number of bytes in a `LANG' name.  We have no limit.  }
  NL_LANGMAX                    = _POSIX2_LINE_MAX;
  {$EXTERNALSYM NL_LANGMAX}

{ Maximum message number.  We have no limit.  }
  NL_MSGMAX                     = INT_MAX;
  {$EXTERNALSYM NL_MSGMAX}

{ Maximum number of bytes in N-to-1 collation mapping.  We have no
   limit.  }
  NL_NMAX                       = INT_MAX;
  {$EXTERNALSYM NL_NMAX}

{ Maximum set number.  We have no limit.  }
  NL_SETMAX                     = INT_MAX;
  {$EXTERNALSYM NL_SETMAX}

{ Maximum number of bytes in a message.  We have no limit.  }
  NL_TEXTMAX                    = INT_MAX;
  {$EXTERNALSYM NL_TEXTMAX}

{ Default process priority.  }
  NZERO                         = 20;
  {$EXTERNALSYM NZERO}


{ Number of bits in a word of type `int'.  }
  WORD_BIT                      = 32;
  {$EXTERNALSYM WORD_BIT}

{ Number of bits in a word of type `long int'.  }
  LONG_BIT                      = 32;
  {$EXTERNALSYM LONG_BIT}


// Translated from bits/local_lim.h

{ Minimum guaranteed maximum values for system limits.  Linux version.

{ The number of data keys per process.  }
  _POSIX_THREAD_KEYS_MAX        = 128;
  {$EXTERNALSYM _POSIX_THREAD_KEYS_MAX}
{ This is the value this implementation supports.  }
  PTHREAD_KEYS_MAX              = 1024;
  {$EXTERNALSYM PTHREAD_KEYS_MAX}

{ Controlling the iterations of destructors for thread-specific data.  }
  _POSIX_THREAD_DESTRUCTOR_ITERATIONS = 4;
  {$EXTERNALSYM _POSIX_THREAD_DESTRUCTOR_ITERATIONS}
{ Number of iterations this implementation does.  }
  PTHREAD_DESTRUCTOR_ITERATIONS = _POSIX_THREAD_DESTRUCTOR_ITERATIONS;
  {$EXTERNALSYM PTHREAD_DESTRUCTOR_ITERATIONS}

{ The number of threads per process.  }
  _POSIX_THREAD_THREADS_MAX     = 64;
  {$EXTERNALSYM _POSIX_THREAD_THREADS_MAX}
{ This is the value this implementation supports.  }
  PTHREAD_THREADS_MAX           = 1024;
  {$EXTERNALSYM PTHREAD_THREADS_MAX}

{ Maximum amount by which a process can descrease its asynchronous I/O
   priority level.  }
  AIO_PRIO_DELTA_MAX            = 20;
  {$EXTERNALSYM AIO_PRIO_DELTA_MAX}

{ Minimum size for a thread.  We are free to choose a reasonable value.  }
  PTHREAD_STACK_MIN             = 16384;
  {$EXTERNALSYM PTHREAD_STACK_MIN}

{ Maximum number of POSIX timers available.  }
  TIMER_MAX                     = 256;
  {$EXTERNALSYM TIMER_MAX}


// Translated from inttypes.h

{ ISO C99: 7.8 Format conversion of integer types }

(*
  Not translated:
   { Macros for printing format specifiers.  }
*)


{ We have to define the `uintmax_t' type using `lldiv_t'.  }
type
  imaxdiv_t = {packed} record
    quot: Int64;   { Quotient.  }
    rem: Int64;    { Remainder.  }
  end;
  {$EXTERNALSYM imaxdiv_t}


{ Compute absolute value of N.  }
function imaxabs(__n: intmax_t): intmax_t; cdecl;
{$EXTERNALSYM imaxabs}

{ Return the `imaxdiv_t' representation of the value of NUMER over DENOM. }
function imaxdiv(__numer: intmax_t; __denom: intmax_t): imaxdiv_t; cdecl;
{$EXTERNALSYM imaxdiv}

{ Like `strtol' but convert to `intmax_t'.  }
function strtoimax(__nptr: PChar; __endptr: PPChar; __base: Integer): intmax_t; cdecl;
{$EXTERNALSYM strtoimax}

{ Like `strtoul' but convert to `uintmax_t'.  }
function strtoumax(__nptr: PChar; __endptr: PPChar; __base: Integer): uintmax_t; cdecl;
{$EXTERNALSYM strtoumax}

{ Like `wcstol' but convert to `intmax_t'.  }
function wcstoimax(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): intmax_t; cdecl;
{$EXTERNALSYM wcstoimax}

{ Like `wcstoul' but convert to `uintmax_t'.  }
function wcstoumax(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): uintmax_t; cdecl;
{$EXTERNALSYM wcstoumax}


// Translated from errno.h (more or less)

{ Generic error type.  }
type
  error_t = Integer;
  {$EXTERNALSYM error_t}

function errno: error_t;
{$EXTERNALSYM errno}

function __errno_location: PInteger; cdecl;
{$EXTERNALSYM __errno_location}


// Translated from asm/errno.h included via linux/errno.h via bits/errno.h

const
  EPERM                       = 1;        {  Operation not permitted  }
  {$EXTERNALSYM EPERM}
  ENOENT                      = 2;        {  No such file or directory  }
  {$EXTERNALSYM ENOENT}
  ESRCH                       = 3;        {  No such process  }
  {$EXTERNALSYM ESRCH}
  EINTR                       = 4;        {  Interrupted system call  }
  {$EXTERNALSYM EINTR}
  EIO                         = 5;        {  I/O error  }
  {$EXTERNALSYM EIO}
  ENXIO                       = 6;        {  No such device or address  }
  {$EXTERNALSYM ENXIO}
  E2BIG                       = 7;        {  Arg list too long  }
  {$EXTERNALSYM E2BIG}
  ENOEXEC                     = 8;        {  Exec format error  }
  {$EXTERNALSYM ENOEXEC}
  EBADF                       = 9;        {  Bad file number  }
  {$EXTERNALSYM EBADF}
  ECHILD                     = 10;        {  No child processes  }
  {$EXTERNALSYM ECHILD}
  EAGAIN                     = 11;        {  Try again  }
  {$EXTERNALSYM EAGAIN}
  ENOMEM                     = 12;        {  Out of memory  }
  {$EXTERNALSYM ENOMEM}
  EACCES                     = 13;        {  Permission denied  }
  {$EXTERNALSYM EACCES}
  EFAULT                     = 14;        {  Bad address  }
  {$EXTERNALSYM EFAULT}
  ENOTBLK                    = 15;        {  Block device required  }
  {$EXTERNALSYM ENOTBLK}
  EBUSY                      = 16;        {  Device or resource busy  }
  {$EXTERNALSYM EBUSY}
  EEXIST                     = 17;        {  File exists  }
  {$EXTERNALSYM EEXIST}
  EXDEV                      = 18;        {  Cross-device link  }
  {$EXTERNALSYM EXDEV}
  ENODEV                     = 19;        {  No such device  }
  {$EXTERNALSYM ENODEV}
  ENOTDIR                    = 20;        {  Not a directory  }
  {$EXTERNALSYM ENOTDIR}
  EISDIR                     = 21;        {  Is a directory  }
  {$EXTERNALSYM EISDIR}
  EINVAL                     = 22;        {  Invalid argument  }
  {$EXTERNALSYM EINVAL}
  ENFILE                     = 23;        {  File table overflow  }
  {$EXTERNALSYM ENFILE}
  EMFILE                     = 24;        {  Too many open files  }
  {$EXTERNALSYM EMFILE}
  ENOTTY                     = 25;        {  Not a typewriter  }
  {$EXTERNALSYM ENOTTY}
  ETXTBSY                    = 26;        {  Text file busy  }
  {$EXTERNALSYM ETXTBSY}
  EFBIG                      = 27;        {  File too large  }
  {$EXTERNALSYM EFBIG}
  ENOSPC                     = 28;        {  No space left on device  }
  {$EXTERNALSYM ENOSPC}
  ESPIPE                     = 29;        {  Illegal seek  }
  {$EXTERNALSYM ESPIPE}
  EROFS                      = 30;        {  Read-only file system  }
  {$EXTERNALSYM EROFS}
  EMLINK                     = 31;        {  Too many links  }
  {$EXTERNALSYM EMLINK}
  EPIPE                      = 32;        {  Broken pipe  }
  {$EXTERNALSYM EPIPE}
  EDOM                       = 33;        {  Math argument out of domain of func  }
  {$EXTERNALSYM EDOM}
  ERANGE                     = 34;        {  Math result not representable  }
  {$EXTERNALSYM ERANGE}
  EDEADLK                    = 35;        {  Resource deadlock would occur  }
  {$EXTERNALSYM EDEADLK}
  ENAMETOOLONG               = 36;        {  File name too long  }
  {$EXTERNALSYM ENAMETOOLONG}
  ENOLCK                     = 37;        {  No record locks available  }
  {$EXTERNALSYM ENOLCK}
  ENOSYS                     = 38;        {  Function not implemented  }
  {$EXTERNALSYM ENOSYS}
  ENOTEMPTY                  = 39;        {  Directory not empty  }
  {$EXTERNALSYM ENOTEMPTY}
  ELOOP                      = 40;        {  Too many symbolic links encountered  }
  {$EXTERNALSYM ELOOP}
  EWOULDBLOCK                = EAGAIN;    {  Operation would block  }
  {$EXTERNALSYM EWOULDBLOCK}
  ENOMSG                     = 42;        {  No message of desired type  }
  {$EXTERNALSYM ENOMSG}
  EIDRM                      = 43;        {  Identifier removed  }
  {$EXTERNALSYM EIDRM}
  ECHRNG                     = 44;        {  Channel number out of range  }
  {$EXTERNALSYM ECHRNG}
  EL2NSYNC                   = 45;        {  Level 2; not synchronized  }
  {$EXTERNALSYM EL2NSYNC}
  EL3HLT                     = 46;        {  Level 3; halted  }
  {$EXTERNALSYM EL3HLT}
  EL3RST                     = 47;        {  Level 3; reset  }
  {$EXTERNALSYM EL3RST}
  ELNRNG                     = 48;        {  Link number out of range  }
  {$EXTERNALSYM ELNRNG}
  EUNATCH                    = 49;        {  Protocol driver not attached  }
  {$EXTERNALSYM EUNATCH}
  ENOCSI                     = 50;        {  No CSI structure available  }
  {$EXTERNALSYM ENOCSI}
  EL2HLT                     = 51;        {  Level 2; halted  }
  {$EXTERNALSYM EL2HLT}
  EBADE                      = 52;        {  Invalid exchange  }
  {$EXTERNALSYM EBADE}
  EBADR                      = 53;        {  Invalid request descriptor  }
  {$EXTERNALSYM EBADR}
  EXFULL                     = 54;        {  Exchange full  }
  {$EXTERNALSYM EXFULL}
  ENOANO                     = 55;        {  No anode  }
  {$EXTERNALSYM ENOANO}
  EBADRQC                    = 56;        {  Invalid request code  }
  {$EXTERNALSYM EBADRQC}
  EBADSLT                    = 57;        {  Invalid slot  }
  {$EXTERNALSYM EBADSLT}

  EDEADLOCK                  = EDEADLK;
  {$EXTERNALSYM EDEADLOCK}

  EBFONT                     = 59;        {  Bad font file format  }
  {$EXTERNALSYM EBFONT}
  ENOSTR                     = 60;        {  Device not a stream  }
  {$EXTERNALSYM ENOSTR}
  ENODATA                    = 61;        {  No data available  }
  {$EXTERNALSYM ENODATA}
  ETIME                      = 62;        {  Timer expired  }
  {$EXTERNALSYM ETIME}
  ENOSR                      = 63;        {  Out of streams resources  }
  {$EXTERNALSYM ENOSR}
  ENONET                     = 64;        {  Machine is not on the network  }
  {$EXTERNALSYM ENONET}
  ENOPKG                     = 65;        {  Package not installed  }
  {$EXTERNALSYM ENOPKG}
  EREMOTE                    = 66;        {  Object is remote  }
  {$EXTERNALSYM EREMOTE}
  ENOLINK                    = 67;        {  Link has been severed  }
  {$EXTERNALSYM ENOLINK}
  EADV                       = 68;        {  Advertise error  }
  {$EXTERNALSYM EADV}
  ESRMNT                     = 69;        {  Srmount error  }
  {$EXTERNALSYM ESRMNT}
  ECOMM                      = 70;        {  Communication error on send  }
  {$EXTERNALSYM ECOMM}
  EPROTO                     = 71;        {  Protocol error  }
  {$EXTERNALSYM EPROTO}
  EMULTIHOP                  = 72;        {  Multihop attempted  }
  {$EXTERNALSYM EMULTIHOP}
  EDOTDOT                    = 73;        {  RFS specific error  }
  {$EXTERNALSYM EDOTDOT}
  EBADMSG                    = 74;        {  Not a data message  }
  {$EXTERNALSYM EBADMSG}
  EOVERFLOW                  = 75;        {  Value too large for defined data type  }
  {$EXTERNALSYM EOVERFLOW}
  ENOTUNIQ                   = 76;        {  Name not unique on network  }
  {$EXTERNALSYM ENOTUNIQ}
  EBADFD                     = 77;        {  File descriptor in bad state  }
  {$EXTERNALSYM EBADFD}
  EREMCHG                    = 78;        {  Remote address changed  }
  {$EXTERNALSYM EREMCHG}
  ELIBACC                    = 79;        {  Can not access a needed shared library  }
  {$EXTERNALSYM ELIBACC}
  ELIBBAD                    = 80;        {  Accessing a corrupted shared library  }
  {$EXTERNALSYM ELIBBAD}
  ELIBSCN                    = 81;        {  .lib section in a.out corrupted  }
  {$EXTERNALSYM ELIBSCN}
  ELIBMAX                    = 82;        {  Attempting to link in too many shared libraries  }
  {$EXTERNALSYM ELIBMAX}
  ELIBEXEC                   = 83;        {  Cannot exec a shared library directly  }
  {$EXTERNALSYM ELIBEXEC}
  EILSEQ                     = 84;        {  Illegal byte sequence  }
  {$EXTERNALSYM EILSEQ}
  ERESTART                   = 85;        {  Interrupted system call should be restarted  }
  {$EXTERNALSYM ERESTART}
  ESTRPIPE                   = 86;        {  Streams pipe error  }
  {$EXTERNALSYM ESTRPIPE}
  EUSERS                     = 87;        {  Too many users  }
  {$EXTERNALSYM EUSERS}
  ENOTSOCK                   = 88;        {  Socket operation on non-socket  }
  {$EXTERNALSYM ENOTSOCK}
  EDESTADDRREQ               = 89;        {  Destination address required  }
  {$EXTERNALSYM EDESTADDRREQ}
  EMSGSIZE                   = 90;        {  Message too long  }
  {$EXTERNALSYM EMSGSIZE}
  EPROTOTYPE                 = 91;        {  Protocol wrong type for socket  }
  {$EXTERNALSYM EPROTOTYPE}
  ENOPROTOOPT                = 92;        {  Protocol not available  }
  {$EXTERNALSYM ENOPROTOOPT}
  EPROTONOSUPPORT            = 93;        {  Protocol not supported  }
  {$EXTERNALSYM EPROTONOSUPPORT}
  ESOCKTNOSUPPORT            = 94;        {  Socket type not supported  }
  {$EXTERNALSYM ESOCKTNOSUPPORT}
  EOPNOTSUPP                 = 95;        {  Operation not supported on transport endpoint  }
  {$EXTERNALSYM EOPNOTSUPP}
  EPFNOSUPPORT               = 96;        {  Protocol family not supported  }
  {$EXTERNALSYM EPFNOSUPPORT}
  EAFNOSUPPORT               = 97;        {  Address family not supported by protocol  }
  {$EXTERNALSYM EAFNOSUPPORT}
  EADDRINUSE                 = 98;        {  Address already in use  }
  {$EXTERNALSYM EADDRINUSE}
  EADDRNOTAVAIL              = 99;        {  Cannot assign requested address  }
  {$EXTERNALSYM EADDRNOTAVAIL}
  ENETDOWN                  = 100;        {  Network is down  }
  {$EXTERNALSYM ENETDOWN}
  ENETUNREACH               = 101;        {  Network is unreachable  }
  {$EXTERNALSYM ENETUNREACH}
  ENETRESET                 = 102;        {  Network dropped connection because of reset  }
  {$EXTERNALSYM ENETRESET}
  ECONNABORTED              = 103;        {  Software caused connection abort  }
  {$EXTERNALSYM ECONNABORTED}
  ECONNRESET                = 104;        {  Connection reset by peer  }
  {$EXTERNALSYM ECONNRESET}
  ENOBUFS                   = 105;        {  No buffer space available  }
  {$EXTERNALSYM ENOBUFS}
  EISCONN                   = 106;        {  Transport endpoint is already connected  }
  {$EXTERNALSYM EISCONN}
  ENOTCONN                  = 107;        {  Transport endpoint is not connected  }
  {$EXTERNALSYM ENOTCONN}
  ESHUTDOWN                 = 108;        {  Cannot send after transport endpoint shutdown  }
  {$EXTERNALSYM ESHUTDOWN}
  ETOOMANYREFS              = 109;        {  Too many references: cannot splice  }
  {$EXTERNALSYM ETOOMANYREFS}
  ETIMEDOUT                 = 110;        {  Connection timed out  }
  {$EXTERNALSYM ETIMEDOUT}
  ECONNREFUSED              = 111;        {  Connection refused  }
  {$EXTERNALSYM ECONNREFUSED}
  EHOSTDOWN                 = 112;        {  Host is down  }
  {$EXTERNALSYM EHOSTDOWN}
  EHOSTUNREACH              = 113;        {  No route to host  }
  {$EXTERNALSYM EHOSTUNREACH}
  EALREADY                  = 114;        {  Operation already in progress  }
  {$EXTERNALSYM EALREADY}
  EINPROGRESS               = 115;        {  Operation now in progress  }
  {$EXTERNALSYM EINPROGRESS}
  ESTALE                    = 116;        {  Stale NFS file handle  }
  {$EXTERNALSYM ESTALE}
  EUCLEAN                   = 117;        {  Structure needs cleaning  }
  {$EXTERNALSYM EUCLEAN}
  ENOTNAM                   = 118;        {  Not a XENIX named type file  }
  {$EXTERNALSYM ENOTNAM}
  ENAVAIL                   = 119;        {  No XENIX semaphores available  }
  {$EXTERNALSYM ENAVAIL}
  EISNAM                    = 120;        {  Is a named type file  }
  {$EXTERNALSYM EISNAM}
  EREMOTEIO                 = 121;        {  Remote I/O error  }
  {$EXTERNALSYM EREMOTEIO}
  EDQUOT                    = 122;        {  Quota exceeded  }
  {$EXTERNALSYM EDQUOT}
  ENOMEDIUM                 = 123;        {  No medium found  }
  {$EXTERNALSYM ENOMEDIUM}
  EMEDIUMTYPE               = 124;        {  Wrong medium type  }
  {$EXTERNALSYM EMEDIUMTYPE}

// Translated from bits/errno.h

  {  Linux has no ENOTSUP error code.  }
  ENOTSUP                   = EOPNOTSUPP;
  {$EXTERNALSYM ENOTSUP}

  {  Linux has no ECANCELED error code.  Since it is not used here
     we define it to an invalid value.  }
  ECANCELED                 = 125;
  {$EXTERNALSYM ECANCELED}

  
// Translated from paths.h

const
{ Default search path. }
  _PATH_DEFPATH    = '/usr/bin:/bin';
  {$EXTERNALSYM _PATH_DEFPATH}
{ All standard utilities path. }
  _PATH_STDPATH    = '/usr/bin:/bin:/usr/sbin:/sbin';
  {$EXTERNALSYM _PATH_STDPATH}

  _PATH_BSHELL     = '/bin/sh';
  {$EXTERNALSYM _PATH_BSHELL}
  _PATH_CONSOLE    = '/dev/console';
  {$EXTERNALSYM _PATH_CONSOLE}
  _PATH_CSHELL     = '/bin/csh';
  {$EXTERNALSYM _PATH_CSHELL}
  _PATH_DEVDB      = '/var/run/dev.db';
  {$EXTERNALSYM _PATH_DEVDB}
  _PATH_DEVNULL    = '/dev/null';
  {$EXTERNALSYM _PATH_DEVNULL}
  _PATH_DRUM       = '/dev/drum';
  {$EXTERNALSYM _PATH_DRUM}
  _PATH_KLOG       = '/proc/kmsg';
  {$EXTERNALSYM _PATH_KLOG}
  _PATH_KMEM       = '/dev/kmem';
  {$EXTERNALSYM _PATH_KMEM}
  _PATH_LASTLOG    = '/var/log/lastlog';
  {$EXTERNALSYM _PATH_LASTLOG}
  _PATH_MAILDIR    = '/var/mail';
  {$EXTERNALSYM _PATH_MAILDIR}
  _PATH_MAN        = '/usr/share/man';
  {$EXTERNALSYM _PATH_MAN}
  _PATH_MEM        = '/dev/mem';
  {$EXTERNALSYM _PATH_MEM}
  _PATH_MNTTAB     = '/etc/fstab';
  {$EXTERNALSYM _PATH_MNTTAB}
  _PATH_MOUNTED    = '/etc/mtab';
  {$EXTERNALSYM _PATH_MOUNTED}
  _PATH_NOLOGIN    = '/etc/nologin';
  {$EXTERNALSYM _PATH_NOLOGIN}
  _PATH_PRESERVE   = '/var/lib';
  {$EXTERNALSYM _PATH_PRESERVE}
  _PATH_RWHODIR    = '/var/spool/rwho';
  {$EXTERNALSYM _PATH_RWHODIR}
  _PATH_SENDMAIL   = '/usr/sbin/sendmail';
  {$EXTERNALSYM _PATH_SENDMAIL}
  _PATH_SHADOW     = '/etc/shadow';
  {$EXTERNALSYM _PATH_SHADOW}
  _PATH_SHELLS     = '/etc/shells';
  {$EXTERNALSYM _PATH_SHELLS}
  _PATH_TTY        = '/dev/tty';
  {$EXTERNALSYM _PATH_TTY}
  _PATH_UNIX       = '/boot/vmlinux';
  {$EXTERNALSYM _PATH_UNIX}
  _PATH_UTMP       = '/var/run/utmp';
  {$EXTERNALSYM _PATH_UTMP}
  _PATH_VI         = '/usr/bin/vi';
  {$EXTERNALSYM _PATH_VI}
  _PATH_WTMP       = '/var/log/wtmp';
  {$EXTERNALSYM _PATH_WTMP}

{ Provide trailing slash, since mostly used for building pathnames. }
  _PATH_DEV        = '/dev/';
  {$EXTERNALSYM _PATH_DEV}
  _PATH_TMP        = '/tmp/';
  {$EXTERNALSYM _PATH_TMP}
  _PATH_VARDB      = '/var/db/';
  {$EXTERNALSYM _PATH_VARDB}
  _PATH_VARRUN     = '/var/run/';
  {$EXTERNALSYM _PATH_VARRUN}
  _PATH_VARTMP     = '/var/tmp/';
  {$EXTERNALSYM _PATH_VARTMP}


// Translated from gnu/lib-names.h

const
  LD_LINUX_SO        = 'ld-linux.so.2';
  {$EXTERNALSYM LD_LINUX_SO}
  LD_SO              = 'ld-linux.so.2';
  {$EXTERNALSYM LD_SO}
  LIBBROKENLOCALE_SO = 'libBrokenLocale.so.1';
  {$EXTERNALSYM LIBBROKENLOCALE_SO}
  LIBCRYPT_SO        = 'libcrypt.so.1';
  {$EXTERNALSYM LIBCRYPT_SO}
  LIBC_SO            = 'libc.so.6';
  {$EXTERNALSYM LIBC_SO}
  LIBDL_SO           = 'libdl.so.2';
  {$EXTERNALSYM LIBDL_SO}
  LIBM_SO            = 'libm.so.6';
  {$EXTERNALSYM LIBM_SO}
  LIBNSL_SO          = 'libnsl.so.1';
  {$EXTERNALSYM LIBNSL_SO}
  LIBNSS_COMPAT_SO   = 'libnss_compat.so.2';
  {$EXTERNALSYM LIBNSS_COMPAT_SO}
  LIBNSS_DNS_SO      = 'libnss_dns.so.2';
  {$EXTERNALSYM LIBNSS_DNS_SO}
  LIBNSS_FILES_SO    = 'libnss_files.so.2';
  {$EXTERNALSYM LIBNSS_FILES_SO}
  LIBNSS_HESIOD_SO   = 'libnss_hesiod.so.2';
  {$EXTERNALSYM LIBNSS_HESIOD_SO}
  LIBNSS_LDAP_SO     = 'libnss_ldap.so.2';
  {$EXTERNALSYM LIBNSS_LDAP_SO}
  LIBNSS_NISPLUS_SO  = 'libnss_nisplus.so.2';
  {$EXTERNALSYM LIBNSS_NISPLUS_SO}
  LIBNSS_NIS_SO      = 'libnss_nis.so.2';
  {$EXTERNALSYM LIBNSS_NIS_SO}
  LIBPTHREAD_SO      = 'libpthread.so.0';
  {$EXTERNALSYM LIBPTHREAD_SO}
  LIBRESOLV_SO       = 'libresolv.so.2';
  {$EXTERNALSYM LIBRESOLV_SO}
  LIBRT_SO           = 'librt.so.1';
  {$EXTERNALSYM LIBRT_SO}
  LIBTHREAD_DB_SO    = 'libthread_db.so.1';
  {$EXTERNALSYM LIBTHREAD_DB_SO}
  LIBUTIL_SO         = 'libutil.so.1';
  {$EXTERNALSYM LIBUTIL_SO}


// Translated from xlocale.h

{ Structure for reentrant locale using functions.  This is an
   (almost) opaque type for the user level programs.  The file and
   this data structure is not standardized.  Don't rely on it.  It can
   go away without warning.  }
type
  _locale_data = record end; // Used anonymously in header file.

  TLocaleData = _locale_data;
  PLocaleData = ^TLocaleData;

  __locale_struct = {packed} record
    __locales: packed array[0..13-1] of PLocaleData; { 13 = __LC_LAST. }
    { To increase the speed of this solution we add some special members.  }
    __ctype_b: PWord;
    __ctype_tolower: PInteger;
    __ctype_toupper: PInteger;
  end;
  {$EXTERNALSYM __locale_struct}
  __locale_t = ^__locale_struct;
  {$EXTERNALSYM __locale_t}
  TLocale = __locale_struct;
  PLocale = ^TLocale;


//!! Moved from below (time.h) to resolve dependency
{ POSIX.4 structure for a time value.  This is like a `struct timeval' but
   has nanoseconds instead of microseconds.  }
  timespec = {packed} record
    tv_sec: Longint;            { Seconds.  }
    tv_nsec: Longint;           { Nanoseconds.  }
  end;
  {$EXTERNALSYM timespec}
  TTimeSpec = timespec;
  PTimeSpec = ^TTimeSpec;

  
// Translated from asm/sigcontext.h (from kernel)

type
  _fpreg = {packed} record
    significand: packed array[0..4-1] of Word;
    exponent: Word;
  end;
  {$EXTERNALSYM _fpreg}
  TFPreg = _fpreg;
  PFPreg = ^TFPreg;

  _fpstate = {packed} record
    cw: LongWord;
    sw: LongWord;
    tag: LongWord;
    ipoff: LongWord;
    cssel: LongWord;
    dataoff: LongWord;
    datasel: LongWord;
    _st: packed array[0..8-1] of _fpreg;
    status: LongWord;
  end;
  {$EXTERNALSYM _fpstate}
  TFPstate = _fpstate;
  PFPstate = ^TFPstate;

  sigcontext = {packed} record
    gs, __gsh: Word;
    fs, __fsh: Word;
    es, __esh: Word;
    ds, __dsh: Word;
    edi: LongWord;
    esi: LongWord;
    ebp: LongWord;
    esp: LongWord;
    ebx: LongWord;
    edx: LongWord;
    ecx: LongWord;
    eax: LongWord;
    trapno: LongWord;
    err: LongWord;
    eip: LongWord;
    cs, __csh: Word;
    eflags: LongWord;
    esp_at_signal: LongWord;
    ss, __ssh: Word;
    fpstate: Pfpstate;
    oldmask: LongWord;
    cr2: LongWord;
  end;
  {$EXTERNALSYM sigcontext}
  TSigContext = sigcontext;
  PSigContext = ^TSigContext;


// Translated from bits/sigset.h

type
  __sig_atomic_t = Integer;
  {$EXTERNALSYM __sig_atomic_t}

const
  _SIGSET_NWORDS  = 1024 div (8 * SizeOf(LongWord));
  {$EXTERNALSYM _SIGSET_NWORDS}

type
  __sigset_t = {packed} record
    __val: packed array[0.._SIGSET_NWORDS-1] of LongWord;
  end;
  {$EXTERNALSYM __sigset_t}
  TSigset = __sigset_t;
  PSigset = ^TSigset;

{ These functions needn't check for a bogus signal number -- error
   checking is done in the non __ versions below.  }

function __sigismember(p1: PSigset; p2: Integer): Integer; cdecl;
{$EXTERNALSYM __sigismember}
function __sigaddset(p1: PSigset; p2: Integer): Integer; cdecl;
{$EXTERNALSYM __sigaddset}
function __sigdelset(p1: PSigset; p2: Integer): Integer; cdecl;
{$EXTERNALSYM __sigdelset}


// Translated from bits/signum.h

{ Fake signal functions.  }
const
  SIG_ERR = (-1);             { Error return.  }
  {$EXTERNALSYM SIG_ERR}
  SIG_DFL = (0);              { Default action.  }
  {$EXTERNALSYM SIG_DFL}
  SIG_IGN = (1);              { Ignore signal.  }
  {$EXTERNALSYM SIG_IGN}
  SIG_HOLD = (2);             { Add signal to hold mask.  }
  {$EXTERNALSYM SIG_HOLD}


{ Signals.  }
  SIGHUP          = 1;      { Hangup (POSIX).  }
  {$EXTERNALSYM SIGHUP}
  SIGINT          = 2;      { Interrupt (ANSI).  }
  {$EXTERNALSYM SIGINT}
  SIGQUIT         = 3;      { Quit (POSIX).  }
  {$EXTERNALSYM SIGQUIT}
  SIGILL          = 4;      { Illegal instruction (ANSI).  }
  {$EXTERNALSYM SIGILL}
  SIGTRAP         = 5;      { Trace trap (POSIX).  }
  {$EXTERNALSYM SIGTRAP}
  SIGABRT         = 6;      { Abort (ANSI).  }
  {$EXTERNALSYM SIGABRT}
  SIGIOT          = 6;      { IOT trap (4.2 BSD).  }
  {$EXTERNALSYM SIGIOT}
  SIGBUS          = 7;      { BUS error (4.2 BSD).  }
  {$EXTERNALSYM SIGBUS}
  SIGFPE          = 8;      { Floating-point exception (ANSI).  }
  {$EXTERNALSYM SIGFPE}
  SIGKILL         = 9;      { Kill, unblockable (POSIX).  }
  {$EXTERNALSYM SIGKILL}
  SIGUSR1         = 10;     { User-defined signal 1 (POSIX).  }
  {$EXTERNALSYM SIGUSR1}
  SIGSEGV         = 11;     { Segmentation violation (ANSI).  }
  {$EXTERNALSYM SIGSEGV}
  SIGUSR2         = 12;     { User-defined signal 2 (POSIX).  }
  {$EXTERNALSYM SIGUSR2}
  SIGPIPE         = 13;     { Broken pipe (POSIX).  }
  {$EXTERNALSYM SIGPIPE}
  SIGALRM         = 14;     { Alarm clock (POSIX).  }
  {$EXTERNALSYM SIGALRM}
  SIGTERM         = 15;     { Termination (ANSI).  }
  {$EXTERNALSYM SIGTERM}
  SIGSTKFLT       = 16;     { Stack fault.  }
  {$EXTERNALSYM SIGSTKFLT}
  SIGCHLD         = 17;     { Child status has changed (POSIX).  }
  {$EXTERNALSYM SIGCHLD}
  SIGCLD          = SIGCHLD; { Same as SIGCHLD (System V).  }
  {$EXTERNALSYM SIGCLD}
  SIGCONT         = 18;     { Continue (POSIX).  }
  {$EXTERNALSYM SIGCONT}
  SIGSTOP         = 19;     { Stop, unblockable (POSIX).  }
  {$EXTERNALSYM SIGSTOP}
  SIGTSTP         = 20;     { Keyboard stop (POSIX).  }
  {$EXTERNALSYM SIGTSTP}
  SIGTTIN         = 21;     { Background read from tty (POSIX).  }
  {$EXTERNALSYM SIGTTIN}
  SIGTTOU         = 22;     { Background write to tty (POSIX).  }
  {$EXTERNALSYM SIGTTOU}
  SIGURG          = 23;     { Urgent condition on socket (4.2 BSD).  }
  {$EXTERNALSYM SIGURG}
  SIGXCPU         = 24;     { CPU limit exceeded (4.2 BSD).  }
  {$EXTERNALSYM SIGXCPU}
  SIGXFSZ         = 25;     { File size limit exceeded (4.2 BSD).  }
  {$EXTERNALSYM SIGXFSZ}
  SIGVTALRM       = 26;     { Virtual alarm clock (4.2 BSD).  }
  {$EXTERNALSYM SIGVTALRM}
  SIGPROF         = 27;     { Profiling alarm clock (4.2 BSD).  }
  {$EXTERNALSYM SIGPROF}
  SIGWINCH        = 28;     { Window size change (4.3 BSD, Sun).  }
  {$EXTERNALSYM SIGWINCH}
  SIGIO           = 29;     { I/O now possible (4.2 BSD).  }
  {$EXTERNALSYM SIGIO}
  SIGPOLL         = SIGIO;  { Pollable event occurred (System V).  }
  {$EXTERNALSYM SIGPOLL}
  SIGPWR          = 30;     { Power failure restart (System V).  }
  {$EXTERNALSYM SIGPWR}
  SIGUNUSED       = 31;
  {$EXTERNALSYM SIGUNUSED}

  _NSIG           = 64;     { Biggest signal number + 1 (including real-time signals). }
  {$EXTERNALSYM _NSIG}

function SIGRTMIN: Integer;
{$EXTERNALSYM SIGRTMIN}

function SIGRTMAX: Integer;
{$EXTERNALSYM SIGRTMAX}

const

{ These are the hard limits of the kernel.  These values should not be
   used directly at user level.  }
  __SIGRTMIN      = 32;
  {$EXTERNALSYM __SIGRTMIN}
  __SIGRTMAX      = _NSIG - 1;
  {$EXTERNALSYM __SIGRTMAX}


// Translated from bits/siginfo.h

{ Type for data associated with a signal.  }
type
  sigval_t = {packed} record
    case Integer of
     0: (sival_int: Integer);
     1: (sival_ptr: Pointer);
  end;
  {$EXTERNALSYM sigval_t}
  sigval = sigval_t;
  {$EXTERNALSYM sigval}
  TSigval = sigval_t;
  PSigval = ^TSigval;

const
  __SI_MAX_SIZE      = 128;
  {$EXTERNALSYM __SI_MAX_SIZE}
  __SI_PAD_SIZE      = (__SI_MAX_SIZE div sizeof (Integer)) - 3;
  {$EXTERNALSYM __SI_PAD_SIZE}

type
{ siginfo nested types (_si_*). These are not found in the header file. }

  _si_pad = packed array[0..__SI_PAD_SIZE-1] of Integer;

  { kill().  }
  _si_kill = {packed} record
    si_pid: __pid_t;            { Sending process ID.  }
    si_uid: __uid_t;            { Real user ID of sending process.  }
  end;

  { POSIX.1b timers.  }
  _si_timer = {packed} record
    _timer1: Cardinal;
    _timer2: Cardinal;
  end;

  { POSIX.1b signals.  }
  _si_rt = {packed} record
    si_pid: __pid_t;            { Sending process ID.  }
    si_uid: __uid_t;            { Real user ID of sending process.  }
    si_sigval: sigval_t;        { Signal value.  }
  end;

  { SIGCHLD.  }
  _si_sigchld = {packed} record
    si_pid: __pid_t;            { Which child.  }
    si_uid: __uid_t;            { Real user ID of sending process.  }
    si_status: Integer;         { Exit value or signal.  }
    si_utime: __clock_t;
    si_stime: __clock_t;
  end;

  { SIGILL, SIGFPE, SIGSEGV, SIGBUS.  }
  _si_sigfault = {packed} record
    si_addr: Pointer;           { Faulting insn/memory ref.  }
  end;

  { SIGPOLL.  }
  _si_sigpoll = {packed} record
    si_band: Longint;           { Band event for SIGPOLL.  }
    si_fd: Integer;
  end;

  siginfo = {packed} record
    si_signo: Integer;          { Signal number.  }
    si_errno: Integer;          { If non-zero, an errno value associated with
				   this signal, as defined in <errno.h>.  }
    si_code: Integer;           { Signal code.  }
    case Integer of
     0: (_pad: _si_pad);
     1: (_kill: _si_kill);
     2: (_timer: _si_timer);
     3: (_rt: _si_rt);
     4: (_sigchld: _si_sigchld);
     5: (_sigfault: _si_sigfault);
     6: (_sigpoll: _si_sigpoll);
  end;
  {$EXTERNALSYM siginfo}
  siginfo_t = siginfo;
  {$EXTERNALSYM siginfo_t}
  TSigInfo = siginfo;
  PSigInfo = ^TSigInfo;


{ Values for `si_code'.  Positive values are reserved for kernel-generated
   signals.  }
const
  SI_SIGIO = -5;                { Sent by queued SIGIO. }
  {$EXTERNALSYM SI_SIGIO}
  SI_ASYNCIO = -4;              { Sent by AIO completion.  }
  {$EXTERNALSYM SI_ASYNCIO}
  SI_MESGQ = -3;                { Sent by real time mesq state change.  }
  {$EXTERNALSYM SI_MESGQ}
  SI_TIMER = -2;                { Sent by timer expiration.  }
  {$EXTERNALSYM SI_TIMER}
  SI_QUEUE = -1;                { Sent by sigqueue.  }
  {$EXTERNALSYM SI_QUEUE}
  SI_USER = 0;                  { Sent by kill, sigsend, raise.  }
  {$EXTERNALSYM SI_USER}
  SI_KERNEL = $80;              { Sent by kernel.  }
  {$EXTERNALSYM SI_KERNEL}


{ `si_code' values for SIGILL signal.  }
const
  ILL_ILLOPC = 1;               { Illegal opcode.  }
  {$EXTERNALSYM ILL_ILLOPC}
  ILL_ILLOPN = 2;               { Illegal operand.  }
  {$EXTERNALSYM ILL_ILLOPN}
  ILL_ILLADR = 3;               { Illegal addressing mode.  }
  {$EXTERNALSYM ILL_ILLADR}
  ILL_ILLTRP = 4;               { Illegal trap. }
  {$EXTERNALSYM ILL_ILLTRP}
  ILL_PRVOPC = 5;               { Privileged opcode.  }
  {$EXTERNALSYM ILL_PRVOPC}
  ILL_PRVREG = 6;               { Privileged register.  }
  {$EXTERNALSYM ILL_PRVREG}
  ILL_COPROC = 7;               { Coprocessor error.  }
  {$EXTERNALSYM ILL_COPROC}
  ILL_BADSTK = 8;               { Internal stack error.  }
  {$EXTERNALSYM ILL_BADSTK}

{ `si_code' values for SIGFPE signal.  }
const
  FPE_INTDIV = 1;               { Integer divide by zero.  }
  {$EXTERNALSYM FPE_INTDIV}
  FPE_INTOVF = 2;               { Integer overflow.  }
  {$EXTERNALSYM FPE_INTOVF}
  FPE_FLTDIV = 3;               { Floating point divide by zero.  }
  {$EXTERNALSYM FPE_FLTDIV}
  FPE_FLTOVF = 4;               { Floating point overflow.  }
  {$EXTERNALSYM FPE_FLTOVF}
  FPE_FLTUND = 5;               { Floating point underflow.  }
  {$EXTERNALSYM FPE_FLTUND}
  FPE_FLTRES = 6;               { Floating point inexact result.  }
  {$EXTERNALSYM FPE_FLTRES}
  FPE_FLTINV = 7;               { Floating point invalid operation.  }
  {$EXTERNALSYM FPE_FLTINV}
  FPE_FLTSUB = 8;               { Subscript out of range.  }
  {$EXTERNALSYM FPE_FLTSUB}

{ `si_code' values for SIGSEGV signal.  }
const
  SEGV_MAPERR = 1;              { Address not mapped to object.  }
  {$EXTERNALSYM SEGV_MAPERR}
  SEGV_ACCERR = 2;              { Invalid permissions for mapped object.  }
  {$EXTERNALSYM SEGV_ACCERR}

{ `si_code' values for SIGBUS signal.  }
const
  BUS_ADRALN = 1;               { Invalid address alignment.  }
  {$EXTERNALSYM BUS_ADRALN}
  BUS_ADRERR = 2;               { Non-existant physical address.  }
  {$EXTERNALSYM BUS_ADRERR}
  BUS_OBJERR = 3;               { Object specific hardware error.  }
  {$EXTERNALSYM BUS_OBJERR}

{ `si_code' values for SIGTRAP signal.  }
const
  TRAP_BRKPT = 1;               { Process breakpoint.  }
  {$EXTERNALSYM TRAP_BRKPT}
  TRAP_TRACE = 2;               { Process trace trap.  }
  {$EXTERNALSYM TRAP_TRACE}

{ `si_code' values for SIGCHLD signal.  }
const
  CLD_EXITED = 1;               { Child has exited.  }
  {$EXTERNALSYM CLD_EXITED}
  CLD_KILLED = 2;               { Child was killed.  }
  {$EXTERNALSYM CLD_KILLED}
  CLD_DUMPED = 3;               { Child terminated abnormally.  }
  {$EXTERNALSYM CLD_DUMPED}
  CLD_TRAPPED = 4;              { Traced child has trapped.  }
  {$EXTERNALSYM CLD_TRAPPED}
  CLD_STOPPED = 5;              { Child has stopped.  }
  {$EXTERNALSYM CLD_STOPPED}
  CLD_CONTINUED = 6;            { Stopped child has continued.  }
  {$EXTERNALSYM CLD_CONTINUED}

{ `si_code' values for SIGPOLL signal.  }
const
  POLL_IN = 1;                  { Data input available.  }
  {$EXTERNALSYM POLL_IN}
  POLL_OUT = 2;                 { Output buffers available.  }
  {$EXTERNALSYM POLL_OUT}
  POLL_MSG = 3;                 { Input message available.   }
  {$EXTERNALSYM POLL_MSG}
  POLL_ERR = 4;                 { I/O error.  }
  {$EXTERNALSYM POLL_ERR}
  POLL_PRI = 5;                 { High priority input available.  }
  {$EXTERNALSYM POLL_PRI}
  POLL_HUP = 6;                 { Device disconnected.  }
  {$EXTERNALSYM POLL_HUP}

{ Structure to transport application-defined values with signals.  }
  __SIGEV_MAX_SIZE        = 64;
  {$EXTERNALSYM __SIGEV_MAX_SIZE}
  __SIGEV_PAD_SIZE        = (__SIGEV_MAX_SIZE div SizeOf(Integer)) - 3;
  {$EXTERNALSYM __SIGEV_PAD_SIZE}

type
  _se_pad = packed array[0..__SIGEV_PAD_SIZE-1] of Integer; { Not in header file - anonymous }

  TSignalEventStartProc = procedure(Param: sigval_t); cdecl; { Not in header file - anonymous } 

  _se_sigev_thread = {packed} record { Not in header file - anonymous }
    _function: TSignalEventStartProc;  { Function to start.  }
    _attribute: Pointer;               { Really pthread_attr_t.  }
  end;

  sigevent = {packed} record
    sigev_value: sigval_t;
    sigev_signo: Integer;
    sigev_notify: Integer;
    case Integer of
      0: (_pad: _se_pad);
      1: (_sigev_thread: _se_sigev_thread);
  end;
  {$EXTERNALSYM sigevent}
  sigevent_t = sigevent;
  {$EXTERNALSYM sigevent_t}
  TSigEvent = sigevent;
  PSigEvent = ^TSigEvent;

{ `sigev_notify' values.  }
const
  SIGEV_SIGNAL = 0;             { Notify via signal.  }
  {$EXTERNALSYM SIGEV_SIGNAL}
  SIGEV_NONE = 1;               { Other notification: meaningless.  }
  {$EXTERNALSYM SIGEV_NONE}
  SIGEV_THREAD = 2;             { Deliver via thread creation.  }
  {$EXTERNALSYM SIGEV_THREAD}


// Translated from bits/sigstack.h

{ Structure describing a signal stack (obsolete).  }
type
  _sigstack = {packed} record
    ss_sp: Pointer;             { Signal stack pointer.  }
    ss_onstack: Integer;        { Nonzero if executing on this stack.  }
  end;
  {$EXTERNALSYM _sigstack}
  TSigStack = _sigstack;
  PSigStack = ^TSigStack;

{ Possible values for `ss_flags.'.  }
const
  SS_ONSTACK = 1;
  {$EXTERNALSYM SS_ONSTACK}
  SS_DISABLE = 2;
  {$EXTERNALSYM SS_DISABLE}

{ Minimum stack size for a signal handler.  }
  MINSIGSTKSZ     = 2048;
  {$EXTERNALSYM MINSIGSTKSZ}

{ System default stack size.  }
  SIGSTKSZ        = 8192;
  {$EXTERNALSYM SIGSTKSZ}


{ Alternate, preferred interface.  }
type
  stack_t = {packed} record
    ss_sp: Pointer;
    ss_flags: Integer;
    ss_size: size_t;
  end;
  {$EXTERNALSYM stack_t}
  _sigaltstack = stack_t;
  {.$EXTERNALSYM sigaltstack} // Renamed due to identifier conflict with sigaltstack function
  TStack = stack_t;
  PStack = ^TStack;

// Translated from bits/sigaction.h

type
  TSigActionHandler = procedure(Signal: Integer); cdecl;
  TRestoreHandler = procedure; cdecl;

{ Structure describing the action to be taken when a signal arrives.  }
type
  { Signal handler. }
  __sigaction = {packed} record
    __sigaction_handler: TSigActionHandler;

    { Additional set of signals to be blocked.  }
    sa_mask: __sigset_t;

    { Special flags.  }
    sa_flags: Integer;

    { Restore handler.  }
    sa_restorer: TRestoreHandler;
  end;
  {.$EXTERNALSYM sigaction} // Renamed symbol, not in header file.
  TSigAction = __sigaction;
  PSigAction = ^TSigAction;

{ Bits in `sa_flags'.  }
const
  SA_NOCLDSTOP  = 1;         { Don't send SIGCHLD when children stop.  }
  {$EXTERNALSYM SA_NOCLDSTOP}
  SA_NOCLDWAIT  = 2;         { Don't create zombie on child death.  }
  {$EXTERNALSYM SA_NOCLDWAIT}
  SA_SIGINFO    = 4;         { Invoke signal-catching function with three arguments instead of one.  }
  {$EXTERNALSYM SA_SIGINFO}

  SA_ONSTACK    = $08000000; { Use signal stack by using `sa_restorer'. }
  {$EXTERNALSYM SA_ONSTACK}
  SA_RESTART    = $10000000; { Restart syscall on signal return.  }
  {$EXTERNALSYM SA_RESTART}
  SA_NODEFER    = $40000000; { Don't automatically block the signal when its handler is being executed.  }
  {$EXTERNALSYM SA_NODEFER}
  SA_RESETHAND  = $80000000; { Reset to SIG_DFL on entry to handler.  }
  {$EXTERNALSYM SA_RESETHAND}
  SA_INTERRUPT  = $20000000; { Historical no-op.  }
  {$EXTERNALSYM SA_INTERRUPT}

{ Some aliases for the SA_ constants.  }
  SA_NOMASK     = SA_NODEFER;
  {$EXTERNALSYM SA_NOMASK}
  SA_ONESHOT    = SA_RESETHAND;
  {$EXTERNALSYM SA_ONESHOT}
  SA_STACK      = SA_ONSTACK;
  {$EXTERNALSYM SA_STACK}

{ Values for the HOW argument to `sigprocmask'.  }
  SIG_BLOCK     = 0;         { Block signals.  }
  {$EXTERNALSYM SIG_BLOCK}
  SIG_UNBLOCK   = 1;         { Unblock signals.  }
  {$EXTERNALSYM SIG_UNBLOCK}
  SIG_SETMASK   = 2;         { Set the set of blocked signals.  }
  {$EXTERNALSYM SIG_SETMASK}


// Translated from signal.h

{ An integral type that can be modified atomically, without the
   possibility of a signal arriving in the middle of the operation.  }

type
  sig_atomic_t = __sig_atomic_t;
  {$EXTERNALSYM sig_atomic_t}

  sigset_t = __sigset_t;
  {$EXTERNALSYM sigset_t}

{ Type of a signal handler.  }

  __sighandler_t = procedure(SigNum: Integer); cdecl;
  {$EXTERNALSYM __sighandler_t}
  TSignalHandler = __sighandler_t;

{ The X/Open definition of `signal' specifies the SVID semantic.  Use
   the additional function `sysv_signal' when X/Open compatibility is requested.  }
function sysv_signal(SigNum: Integer; Handler: TSignalHandler): TSignalHandler; cdecl;
{$EXTERNALSYM sysv_signal}

{ Set the handler for the signal SIG to HANDLER, returning the old
   handler, or SIG_ERR on error.  By default `signal' has the BSD semantic.  }
function signal(SigNum: Integer; Handler: TSignalHandler): TSignalHandler; cdecl;
{$EXTERNALSYM signal}

{ Make sure the used `signal' implementation is the SVID version. }

{ The X/Open definition of `signal' conflicts with the BSD version.
   So they defined another function `bsd_signal'.  }
function bsd_signal(SigNum: Integer; Handler: TSignalHandler): TSignalHandler; cdecl;
{$EXTERNALSYM bsd_signal}

{ Send signal SIG to process number PID.  If PID is zero,
   send SIG to all processes in the current process's process group.
   If PID is < -1, send SIG to all processes in process group - PID.  }
function kill(ProcessID: __pid_t; SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM kill}

{ Send SIG to all processes in process group PGRP.
   If PGRP is zero, send SIG to all processes in
   the current process's process group.  }
function killpg(ProcessGrp: __pid_t; SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM killpg}

{ Raise signal SIG, i.e., send SIG to yourself.  }
{ raise renamed to __raise here }
// HTI - Renamed from "raise" to "__raise"
function __raise(SigNum: Integer): Integer; cdecl;
{ $EXTERNALSYM raise}

{ SVID names for the same things.  }
function ssignal(SigNum: Integer; Handler: TSignalHandler): TSignalHandler; cdecl;
{$EXTERNALSYM ssignal}
function gsignal(SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM gsignal}

{ Print a message describing the meaning of the given signal number.  }
procedure psignal(SigNum: Integer; const S: PChar); cdecl;
{$EXTERNALSYM psignal}


{ The `sigpause' function has two different interfaces.  The original
   BSD definition defines the argument as a mask of the signal, while
   the more modern interface in X/Open defines it as the signal
   number.  We go with the BSD version unless the user explicitly
   selects the X/Open version.  }
function __sigpause(sig_or_mask: Integer; is_sig: Integer): Integer; cdecl;
{$EXTERNALSYM __sigpause}

{ Set the mask of blocked signals to MASK,
   wait for a signal to arrive, and then restore the mask.  }
function sigpause(Mask: Integer): Integer; cdecl;
{$EXTERNALSYM sigpause}

{ None of the following functions should be used anymore.  They are here
   only for compatibility.  A single word (`int') is not guaranteed to be
   enough to hold a complete signal mask and therefore these functions
   simply do not work in many situations.  Use `sigprocmask' instead.  }

{Compute mask for signal SIG}
// Not translated

{ Block signals in MASK, returning the old mask.  }
function sigblock(Mask: Integer): Integer; cdecl;
{$EXTERNALSYM sigblock}

{ Set the mask of blocked signals to MASK, returning the old mask.  }
function sigsetmask(Mask: Integer): Integer; cdecl;
{$EXTERNALSYM sigsetmask}

{ Return currently selected signal mask.  }
function siggetmask: Integer; cdecl;
{$EXTERNALSYM siggetmask}

const
  NSIG    = _NSIG;
  {$EXTERNALSYM NSIG}

type
  sighandler_t = __sighandler_t;
  {$EXTERNALSYM sighandler_t}

  sig_t = __sighandler_t;
  {$EXTERNALSYM sig_t}

{ Clear all signals from SET.  }
function sigemptyset(var SigSet: TSigset): Integer; cdecl;
{$EXTERNALSYM sigemptyset}

{ Set all signals in SET.  }
function sigfillset(var SigSet: TSigset): Integer; cdecl;
{$EXTERNALSYM sigfillset}

{ Add SIGNO to SET.  }
function sigaddset(var SigSet: TSigset; SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM sigaddset}

{ Remove SIGNO from SET.  }
function sigdelset(var SigSet: TSigset; SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM sigdelset}

{ Return 1 if SIGNO is in SET, 0 if not.  }
function sigismember(const SigSet: TSigset; SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM sigismember}

{ Return non-empty value is SET is not empty.  }
function sigisemptyset(const SigSet: TSigset): Integer; cdecl;
{$EXTERNALSYM sigisemptyset}

{ Build new signal set by combining the two input sets using logical AND.  }
function sigandset(var SigSet: TSigset; const Left: TSigset;
  const Right: TSigset): Integer; cdecl;
{$EXTERNALSYM sigandset}

{ Build new signal set by combining the two input sets using logical OR.  }
function sigorset(var SigSet: TSigset; const Left: TSigset;
  const Right: TSigset): Integer; cdecl;
{$EXTERNALSYM sigorset}

{ Get the system-specific definitions of `struct sigaction'
   and the `SA_*' and `SIG_*'. constants.  }

{ Get and/or change the set of blocked signals.  }
function sigprocmask(How: Integer; SigSet: PSigset; OldSigSet: PSigset): Integer; cdecl;
{$EXTERNALSYM sigprocmask}

{ Change the set of blocked signals to SET,
   wait until a signal arrives, and restore the set of blocked signals.  }
function sigsuspend(const SigSet: TSigset): Integer; cdecl;
{$EXTERNALSYM sigsuspend}

{ Get and/or set the action for signal SIG.  }
function sigaction(SigNum: Integer; Action: PSigaction; OldAction: PSigaction): Integer; cdecl;
{$EXTERNALSYM sigaction}

{ Put in SET all signals that are blocked and waiting to be delivered.  }
function sigpending(var SigSet: TSigset): Integer; cdecl;
{$EXTERNALSYM sigpending}

{ Select any of pending signals from SET or wait for any to arrive.  }
function sigwait(const SigSet: TSigset; SigNum: PInteger): Integer; cdecl;
{$EXTERNALSYM sigwait}

{ Select any of pending signals from SET and place information in INFO.  }
function sigwaitinfo(const SigSet: TSigset; SigInfo: PSigInfo): Integer; cdecl;
{$EXTERNALSYM sigwaitinfo}

{ Select any of pending signals from SET and place information in INFO.
   Wait the time specified by TIMEOUT if no signal is pending.  }
function sigtimedwait(const SigSet: TSigset; SigInfo: PSigInfo;
  Timeout: PTimeSpec): Integer; cdecl;
{$EXTERNALSYM sigtimedwait}

{ Send signal SIG to the process PID.  Associate data in VAL with the signal.  }
function sigqueue(ProcessID: __pid_t; SigNum: Integer; Val: sigval): Integer; cdecl;
{$EXTERNALSYM sigqueue}

{ Structure passed to `sigvec'.  }
type
  _sigvec = {packed} record
    sv_handler: TSignalHandler; { Signal handler.  }
    sv_mask: Integer;           { Mask of signals to be blocked.  }
    sv_flags: Integer;          { Flags (see below).  }
  end;
  {.$EXTERNALSYM sigvec} // Renamed symbol not in header file.
  TSigVec = _sigvec;
  PSigVec = ^TSigVec;

{ Bits in `sv_flags'.  }
const
  SV_ONSTACK      = 1 shl 0; { Take the signal on the signal stack.  }
  {$EXTERNALSYM SV_ONSTACK}
  SV_INTERRUPT    = 1 shl 1; { Do not restart system calls.  }
  {$EXTERNALSYM SV_INTERRUPT}
  SV_RESETHAND    = 1 shl 2; { Reset handler to SIG_DFL on receipt.  }
  {$EXTERNALSYM SV_RESETHAND}


{ If VEC is non-NULL, set the handler for SIG to the `sv_handler' member
   of VEC.  The signals in `sv_mask' will be blocked while the handler runs.
   If the SV_RESETHAND bit is set in `sv_flags', the handler for SIG will be
   reset to SIG_DFL before `sv_handler' is entered.  If OVEC is non-NULL,
   it is filled in with the old information for SIG.  }
function sigvec(SigNum: Integer; PVector: PSigVec;
  POldVector: PSigVec): Integer; cdecl; overload;
function sigvec(SigNum: Integer; const Vector: TSigVec;
  OldVector: PSigVec): Integer; cdecl; overload;
{$EXTERNALSYM sigvec}


{ Get machine-dependent `struct sigcontext' and signal subcodes.  }

{ Restore the state saved in SCP.  }
function sigreturn(const scp: TSigContext): Integer; cdecl;
{$EXTERNALSYM sigreturn}

{ If INTERRUPT is nonzero, make signal SIG interrupt system calls
   (causing them to fail with EINTR); if INTERRUPT is zero, make system
   calls be restarted after signal SIG.  }
function siginterrupt(SigNum: Integer; Interrupt: Integer): Integer; cdecl;
{$EXTERNALSYM siginterrupt}


{ Run signals handlers on the stack specified by SS (if not NULL).
   If OSS is not NULL, it is filled in with the old signal stack status.
   This interface is obsolete and on many platform not implemented.  }
function sigstack(SS: PSigStack; OSS: PSigStack): Integer; cdecl;
{$EXTERNALSYM sigstack}

{ Alternate signal handler stack interface.
   This interface should always be preferred over `sigstack'.  }
function sigaltstack(SS: PStack; OSS: PStack): Integer; cdecl;
{$EXTERNALSYM sigaltstack}

{ Simplified interface for signal management.  }

{ Add SIG to the calling process' signal mask.  }
function sighold(SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM sighold}

{ Remove SIG from the calling process' signal mask.  }
function sigrelse(SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM sigrelse}

{ Set the disposition of SIG to SIG_IGN.  }
function sigignore(SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM sigignore}

{ Set the disposition of SIG.  }
function sigset(SigNum: Integer; Disp: TSignalHandler): TSignalHandler; cdecl;
{$EXTERNALSYM sigset}

{ The following functions are used internally in the C library and in
   other code which need deep insights.  }

{ Return number of available real-time signal with highest priority.  }
function __libc_current_sigrtmin: Integer; cdecl;
{$EXTERNALSYM __libc_current_sigrtmin}

{ Return number of available real-time signal with lowest priority.  }
function __libc_current_sigrtmax: Integer; cdecl;
{$EXTERNALSYM __libc_current_sigrtmax}


// Translated from bits/time.h

const

{ ISO/IEC 9899:1990 7.12.1: <time.h>
   The macro `CLOCKS_PER_SEC' is the number per second of the value
   returned by the `clock' function. }
{ CAE XSH, Issue 4, Version 2: <time.h>
   The value of CLOCKS_PER_SEC is required to be 1 million on all
   XSI-conformant systems. }
  CLOCKS_PER_SEC    = 1000000;
  {$EXTERNALSYM CLOCKS_PER_SEC}

{ Even though CLOCKS_PER_SEC has such a strange value CLK_TCK
   presents the real value for clock ticks per second for the system.  }
function CLK_TCK: __clock_t; // Calls __sysconf
{$EXTERNALSYM CLK_TCK}

const
{ Identifier for system-wide realtime clock.  }
  CLOCK_REALTIME                = 0;
  {$EXTERNALSYM CLOCK_REALTIME}
{ High-resolution timer from the CPU.  }
  CLOCK_PROCESS_CPUTIME_ID      = 2;
  {$EXTERNALSYM CLOCK_PROCESS_CPUTIME_ID}
{ Thread-specific CPU-time clock.  }
  CLOCK_THREAD_CPUTIME_ID       = 3;
  {$EXTERNALSYM CLOCK_THREAD_CPUTIME_ID}

{ Flag to indicate time is absolute.  }
  TIMER_ABSTIME                 = 1;
  {$EXTERNALSYM TIMER_ABSTIME}

{ A time value that is accurate to the nearest
   microsecond but also has a range of years.  }
type
  timeval = {packed} record
    tv_sec: __time_t;           { Seconds.  }
    tv_usec: __suseconds_t;     { Microseconds.  }
  end;
  {$EXTERNALSYM timeval}
  TTimeVal = timeval;
  PTimeVal = ^TTimeVal;

// Translated from time.h

{ Returned by `clock'.  }
  clock_t = __clock_t;
  {$EXTERNALSYM clock_t}

{ Returned by `time'.  }
  time_t = __time_t;
  {$EXTERNALSYM time_t}
  TTime_T = time_t;
  PTime_T = ^TTime_T;

{ Clock ID used in clock and timer functions.  }
  clockid_t = __clockid_t;
  {$EXTERNALSYM clockid_t}

{ Timer ID returned by `timer_create'.  }
  timer_t = __timer_t;
  {$EXTERNALSYM timer_t}

(* //!! Moved up to resolve dependency
{ POSIX.4 structure for a time value.  This is like a `struct timeval' but
   has nanoseconds instead of microseconds.  }
  timespec = {packed} record
    tv_sec: Longint;            { Seconds.  }
    tv_nsec: Longint;           { Nanoseconds.  }
  end;
  {$EXTERNALSYM timespec}
  TTimeSpec = timespec;
  PTimeSpec = ^TTimeSpec;
*)

{ Used by other time functions.  }
  tm = {packed} record
    tm_sec: Integer;            { Seconds.	[0-60] (1 leap second) }
    tm_min: Integer;            { Minutes.	[0-59] }
    tm_hour: Integer;           { Hours.	[0-23] }
    tm_mday: Integer;           { Day.		[1-31] }
    tm_mon: Integer;            { Month.	[0-11] }
    tm_year: Integer;           { Year	- 1900.  }
    tm_wday: Integer;           { Day of week.	[0-6] }
    tm_yday: Integer;           { Days in year.[0-365]	 }
    tm_isdst: Integer;          { DST.		[-1/0/1] }
    __tm_gmtoff: Integer;       { Seconds east of UTC.  }
    __tm_zone: ^Char;           { Timezone abbreviation.  }
  end;
  {$EXTERNALSYM tm}
  TUnixTime = tm;
  PUnixTime = ^TUnixTime;

{ POSIX.1b structure for timer start values and intervals.  }
  itimerspec = {packed} record
    it_interval: timespec;
    it_value: timespec;
  end;
  {$EXTERNALSYM itimerspec}
  TITimerSpec = itimerspec;
  PITimerSpec = ^TITimerSpec;

{ Time used by the program so far (user time + system time).
   The result / CLOCKS_PER_SECOND is program time in seconds.  }
function clock: clock_t; cdecl;
{$EXTERNALSYM clock}

{ Return the current time and put it in *TIMER if TIMER is not NULL.  }
// HTI - Renamed from "time" to "__time"
function __time(TimeNow: PTime_t): time_t; cdecl;
{ $EXTERNALSYM time}

{ Return the difference between TIME1 and TIME0.  }
function difftime(time1, time0: TTime_t): Double; cdecl;
{$EXTERNALSYM difftime}

{ Return the `time_t' representation of TP and normalize TP.  }
function mktime(var UnixTime: TUnixTime): time_t; cdecl;
{$EXTERNALSYM mktime}

{ Format TP into S according to FORMAT.
   Write no more than MAXSIZE characters and return the number
   of characters written, or 0 if it would exceed MAXSIZE.  }
function strftime(S: PChar; MaxSize: size_t; Format: PChar;
  const UnixTime: TUnixTime): size_t; cdecl;
{$EXTERNALSYM strftime}

{ Parse S according to FORMAT and store binary time information in TP.
   The return value is a pointer to the first unparsed character in S.  }
function strptime(S: PChar; Format: PChar; var UnixTime: TUnixTime): PChar; cdecl;
{$EXTERNALSYM strptime}

{ Return the `struct tm' representation of *TIMER
   in Universal Coordinated Time (aka Greenwich Mean Time).  }
function gmtime(Timer: PTime_t): PUnixTime; cdecl;
{$EXTERNALSYM gmtime}

{ Return the `struct tm' representation
   of *TIMER in the local timezone.  }
function localtime(Timer: PTime_t): PUnixTime; cdecl;
{$EXTERNALSYM localtime}

{ Return the `struct tm' representation of *TIMER in UTC,
   using *TP to store the result.  }
function gmtime_r(Timer: PTime_t; var UnixTime: TUnixTime): PUnixTime; cdecl;
{$EXTERNALSYM gmtime_r}

{ Return the `struct tm' representation of *TIMER in local time,
   using *TP to store the result.  }
function localtime_r(Timer: PTime_t; var UnixTime: TUnixTime): PUnixTime; cdecl;
{$EXTERNALSYM localtime_r}

{ Return a string of the form "Day Mon dd hh:mm:ss yyyy\n"
   that is the representation of TP in this format.  }
function asctime(const UnixTime: TUnixTime; Buf: PChar): PChar; cdecl;
{$EXTERNALSYM asctime}

{ Equivalent to `asctime (localtime (timer))'.  }
function ctime(Timer: PTime_t): PChar; cdecl;
{$EXTERNALSYM ctime}

{ Reentrant versions of the above functions.  }

{ Return in BUF a string of the form "Day Mon dd hh:mm:ss yyyy\n"
   that is the representation of TP in this format.  }
function asctime_r(const UnixTime: TUnixTime; Buf: PChar): PChar; cdecl;
{$EXTERNALSYM asctime_r}

{ Equivalent to `asctime_r (localtime_r (timer, *TMP*), buf)'.  }
function ctime_r(Timer: PTime_t; Buf: PChar): PChar; cdecl;
{$EXTERNALSYM ctime_r}

{ Set time conversion information from the TZ environment variable.
   If TZ is not defined, a locale-dependent default is used.  }
procedure tzset; cdecl;
{$EXTERNALSYM tzset}

{ Set the system time to *WHEN.
   This call is restricted to the superuser.  }
function stime(When: PTime_t): Integer; cdecl;
{$EXTERNALSYM stime}

{ Miscellaneous functions many Unices inherited from the public domain
   localtime package.  These are included only for compatibility.  }

{ Like `mktime', but for TP represents Universal Time, not local time.  }
function timegm(var UnixTime: TUnixTime): time_t; cdecl;
{$EXTERNALSYM timegm}

{ Another name for `mktime'.  }
function timelocal(var UnixTime: TUnixTime): time_t; cdecl;
{$EXTERNALSYM timelocal}

{ Return the number of days in YEAR.  }
function dysize(Year: Integer): Integer; cdecl;
{$EXTERNALSYM dysize}

{ Pause execution for a number of nanoseconds.  }
function nanosleep(const RequestedTime: TTimeSpec; Remaining: PTimeSpec): Integer; cdecl;
{$EXTERNALSYM nanosleep}

{ Get resolution of clock CLOCK_ID.  }
function clock_getres(ClockID: clockid_t; var Resolution: TTimeSpec): Integer; cdecl;
{$EXTERNALSYM clock_getres}

{ Get current value of clock CLOCK_ID and store it in TP.  }
function clock_gettime(ClockID: clockid_t; var Resolution: TTimeSpec): Integer; cdecl;
{$EXTERNALSYM clock_gettime}

{ Set clock CLOCK_ID to value TP.  }
function clock_settime(ClockID: clockid_t; const Resolution: TTimeSpec): Integer; cdecl;
{$EXTERNALSYM clock_settime}

{ High-resolution sleep with the specified clock.  }
function clock_nanosleep(ClockID: clockid_t; Flags: Integer;
  RequestedTime: TTimeSpec; var RemainingTime: TTimeSpec): Integer; cdecl;
{$EXTERNALSYM clock_nanosleep}

{ Return clock ID for CPU-time clock.  }
function clock_getcpuclockid(Pid: pid_t; var ClockID: clockid_t): Integer; cdecl;
{$EXTERNALSYM clock_getcpuclockid}


{ Create new per-process timer using CLOCK_ID.  }
function timer_create(ClockID: clockid_t; var ev: sigevent;
  var TimerID: timer_t): Integer; cdecl; overload;
function timer_create(ClockID: clockid_t; evp: PSigEvent;
  var TimerID: timer_t): Integer; cdecl; overload;
{$EXTERNALSYM timer_create}

{ Delete timer TIMERID.  }
function timer_delete(TimerID: timer_t): Integer; cdecl;
{$EXTERNALSYM timer_delete}

{ Set timer TIMERID to VALUE, returning old value in OVALUE.  }
function timer_settime(TimerID: timer_t; Flags: Integer;
  const Value: TItimerSpec; OldValue: PITimerSpec): Integer; cdecl;
{$EXTERNALSYM timer_settime}

{ Get current value of timer TIMERID and store it in VALUE.  }
function timer_gettime(TimerID: timer_t; var Value: TITimerSpec): Integer; cdecl;
{$EXTERNALSYM timer_gettime}

{* Get expiration overrun for timer TIMERID.  }
function timer_getoverrun(TimerID: timer_t): Integer; cdecl;
{$EXTERNALSYM timer_getoverrun}


{ Set to one of the following values to indicate an error.
     1  the DATEMSK environment variable is null or undefined,
     2  the template file cannot be opened for reading,
     3  failed to get file status information,
     4  the template file is not a regular file,
     5  an error is encountered while reading the template file,
     6  memory allication failed (not enough memory available),
     7  there is no line in the template that matches the input,
     8  invalid input specification Example: February 31 or a time is
        specified that can not be represented in a time_t (representing
	the time in seconds since 00:00:00 UTC, January 1, 1970) }

{ Parse the given string as a date specification and return a value
   representing the value.  The templates from the file identified by
   the environment variable DATEMSK are used.  In case of an error
   `getdate_err' is set.  }
function getdate(DateStr: PChar): PUnixTime; cdecl;
{$EXTERNALSYM getdate}

{ Since `getdate' is not reentrant because of the use of `getdate_err'
   and the static buffer to return the result in, we provide a thread-safe
   variant.  The functionality is the same.  The result is returned in
   the buffer pointed to by RESBUFP and in case of an error the return
   value is != 0 with the same values as given above for `getdate_err'.  }
function getdate_r(DateStr: PChar; ResBuf: PUnixTime): Integer; cdecl;
{$EXTERNALSYM getdate_r}

// Translated from sys/time.h

type
  suseconds_t = __suseconds_t;
  {$EXTERNALSYM suseconds_t}

{  Macros for converting between `struct timeval' and `struct timespec'.  }
procedure TIMEVAL_TO_TIMESPEC(const tv: TTimeVal; var ts: TTimeSpec);
{$EXTERNALSYM TIMEVAL_TO_TIMESPEC}
procedure TIMESPEC_TO_TIMEVAL(var tv: TTimeVal; const ts: TTimeSpec);
{$EXTERNALSYM TIMESPEC_TO_TIMEVAL}

type
{  Structure crudely representing a timezone.
   This is obsolete and should never be used.  }
  timezone = {packed} record
    tz_minuteswest: Integer;    { Minutes west of GMT.  }
    tz_dsttime: Integer;        { Nonzero if DST is ever in effect.  }
  end;
  {$EXTERNALSYM timezone}
  TTimeZone = timezone;
  PTimeZone = ^TTimeZone;

  __timezone_ptr_t = ^timezone;
  {$EXTERNALSYM __timezone_ptr_t}

{  Get the current time of day and timezone information,
   putting it into *TV and *TZ.  If TZ is NULL, *TZ is not filled.
   Returns 0 on success, -1 on errors.
   NOTE: This form of timezone information is obsolete.
   Use the functions and variables declared in <time.h> instead.  }
function gettimeofday(var timeval: TTimeVal; var timezone: TTimeZone): Integer; cdecl; overload;
function gettimeofday(var timeval: TTimeVal; timezone: PTimeZone): Integer; cdecl; overload;
{$EXTERNALSYM gettimeofday}

{  Set the current time of day and timezone information.
   This call is restricted to the super-user.  }
function settimeofday(const timeval: TTimeVal; const timezone: TTimeZone): Integer; cdecl;
{$EXTERNALSYM settimeofday}

{  Adjust the current time of day by the amount in DELTA.
   If OLDDELTA is not NULL, it is filled in with the amount
   of time adjustment remaining to be done from the last `adjtime' call.
   This call is restricted to the super-user.  }
function adjtime(const delta: TTimeVal; var olddelta: TTimeVal): Integer; cdecl; overload;
function adjtime(const delta: TTimeVal; olddelta: PTimeVal): Integer; cdecl; overload;
{$EXTERNALSYM adjtime}

{  Values for the first argument to `getitimer' and `setitimer'.  }
type
  __itimer_which =
  (
    {  Timers run in real time.  }
    ITIMER_REAL = 0,
    {$EXTERNALSYM ITIMER_REAL}
    {  Timers run only when the process is executing.  }
    ITIMER_VIRTUAL = 1,
    {$EXTERNALSYM ITIMER_VIRTUAL}
    {  Timers run when the process is executing and when
       the system is executing on behalf of the process.  }
    ITIMER_PROF = 2
    {$EXTERNALSYM ITIMER_PROF}
  );
  {$EXTERNALSYM __itimer_which}
  __itimer_which_t = __itimer_which;
  {$EXTERNALSYM __itimer_which_t}

{  Type of the second argument to `getitimer' and
   the second and third arguments `setitimer'.  }
  itimerval = {packed} record
    { Value to put into `it_value' when the timer expires.  }
    it_interval: TTimeVal;
    { Time to the next timer expiration.  }
    it_value: TTimeVal;
  end;
  {$EXTERNALSYM itimerval}
  TIntervalTimerValue = itimerval;
  PIntervalTimerValue = ^TIntervalTimerValue;

{  Set *VALUE to the current setting of timer WHICH.
   Return 0 on success, -1 on errors.  }
function getitimer(__which: __itimer_which_t; var __value: TIntervalTimerValue): Integer; cdecl;
{$EXTERNALSYM getitimer}

{  Set the timer WHICH to *NEW.  If OLD is not NULL,
   set *OLD to the old value of timer WHICH.
   Returns 0 on success, -1 on errors.  }
function setitimer(__which: __itimer_which_t; const __new: TIntervalTimerValue; __old: PIntervalTimerValue): Integer; cdecl;
{$EXTERNALSYM setitimer}

{  Change the access time of FILE to TVP[0] and
   the modification time of FILE to TVP[1].  }
function utimes(__file: PChar; __tvp: PTimeVal): Integer; cdecl; overload;
{$EXTERNALSYM utimes}

type
  TAccessModificationTimes = {packed} record
    AccessTime: TTimeVal;
    ModificationTime: TTimeVal;
  end;

function utimes(__file: PChar; const AccessModTimes: TAccessModificationTimes): Integer; cdecl; overload;
{$EXTERNALSYM utimes}

{  Convenience macros for operations on timevals.
   NOTE: `timercmp' does not work for >= or <=.  }
function timerisset(const Value: TTimeVal): Boolean;
{$EXTERNALSYM timerisset}
procedure timerclear(var Value: TTimeVal);
{$EXTERNALSYM timerclear}

// Original defintion of "#define timercmp(a, b, CMP)" does not
// Translate to Object Pascal
function __timercmp(const a, b: TTimeVal): Integer;
{.$EXTERNALSYM timercmp} // Changed implementation and prototype

function timeradd(const a, b: TTimeVal): TTimeVal;
{$EXTERNALSYM timeradd}
function timersub(const a, b: TTimeVal): TTimeVal;
{$EXTERNALSYM timersub}


// Translated from sys/timex.h

{ These definitions from linux/timex.h as of 2.2.0.  *}
type
  ntptimeval = {packed} record
    time: timeval;	{ current time (ro) }
    maxerror: Longint;	{ maximum error (us) (ro) }
    esterror: Longint;	{ estimated error (us) (ro) }
  end;
  {$EXTERNALSYM ntptimeval}

  timex = {packed} record
    modes: Cardinal;    { mode selector }
    offset: Longint;    { time offset (usec) }
    freq: Longint;      { frequency offset (scaled ppm) }
    maxerror: Longint;  { maximum error (usec) }
    esterror: Longint;  { estimated error (usec) }
    status: Integer;    { clock command/status }
    constant: Longint;  { pll time constant }
    precision: Longint; { clock precision (usec) (read only) }
    tolerance: Longint; { clock frequency tolerance (ppm) (read only) }
    time: timeval;      { (read only) }
    tick: Longint;      { (modified) usecs between clock ticks }

    ppsfreq: Longint;   { pps frequency (scaled ppm) (ro) }
    jitter: Longint;    { pps jitter (us) (ro) }
    shift: Integer;     { interval duration (s) (shift) (ro) }
    stabil: Longint;    { pps stability (scaled ppm) (ro) }
    jitcnt: Longint;    { jitter limit exceeded (ro) }
    calcnt: Longint;    { calibration intervals (ro) }
    errcnt: Longint;    { calibration errors (ro) }
    stbcnt: Longint;    { stability limit exceeded (ro) }

    { ??? }
    bitfield11, bitfield12, bitfield13, bitfield14: Integer;
    bitfield21, bitfield22, bitfield23, bitfield24: Integer;
    bitfield31, bitfield32, bitfield33, bitfield34: Integer;
  end;
  {$EXTERNALSYM timex}

const
{ Mode codes (timex.mode) }
  ADJ_OFFSET            = $0001; { time offset }
  {$EXTERNALSYM ADJ_OFFSET}
  ADJ_FREQUENCY         = $0002; { frequency offset }
  {$EXTERNALSYM ADJ_FREQUENCY}
  ADJ_MAXERROR          = $0004; { maximum time error }
  {$EXTERNALSYM ADJ_MAXERROR}
  ADJ_ESTERROR          = $0008; { estimated time error }
  {$EXTERNALSYM ADJ_ESTERROR}
  ADJ_STATUS            = $0010; { clock status }
  {$EXTERNALSYM ADJ_STATUS}
  ADJ_TIMECONST         = $0020; { pll time constant }
  {$EXTERNALSYM ADJ_TIMECONST}
  ADJ_TICK              = $4000; { tick value }
  {$EXTERNALSYM ADJ_TICK}
  ADJ_OFFSET_SINGLESHOT = $8001; { old-fashioned adjtime }
  {$EXTERNALSYM ADJ_OFFSET_SINGLESHOT}

{ xntp 3.4 compatibility names }
  MOD_OFFSET    = ADJ_OFFSET;
  {$EXTERNALSYM MOD_OFFSET}
  MOD_FREQUENCY = ADJ_FREQUENCY;
  {$EXTERNALSYM MOD_FREQUENCY}
  MOD_MAXERROR  = ADJ_MAXERROR;
  {$EXTERNALSYM MOD_MAXERROR}
  MOD_ESTERROR  = ADJ_ESTERROR;
  {$EXTERNALSYM MOD_ESTERROR}
  MOD_STATUS    = ADJ_STATUS;
  {$EXTERNALSYM MOD_STATUS}
  MOD_TIMECONST = ADJ_TIMECONST;
  {$EXTERNALSYM MOD_TIMECONST}
  MOD_CLKB      = ADJ_TICK;
  {$EXTERNALSYM MOD_CLKB}
  MOD_CLKA      = ADJ_OFFSET_SINGLESHOT; { 0x8000 in original }
  {$EXTERNALSYM MOD_CLKA}


{ Status codes (timex.status) }
  STA_PLL       = $0001; { enable PLL updates (rw) }
  {$EXTERNALSYM STA_PLL}
  STA_PPSFREQ   = $0002; { enable PPS freq discipline (rw) }
  {$EXTERNALSYM STA_PPSFREQ}
  STA_PPSTIME   = $0004; { enable PPS time discipline (rw) }
  {$EXTERNALSYM STA_PPSTIME}
  STA_FLL       = $0008; { select frequency-lock mode (rw) }
  {$EXTERNALSYM STA_FLL}

  STA_INS       = $0010; { insert leap (rw) }
  {$EXTERNALSYM STA_INS}
  STA_DEL       = $0020; { delete leap (rw) }
  {$EXTERNALSYM STA_DEL}
  STA_UNSYNC    = $0040; { clock unsynchronized (rw) }
  {$EXTERNALSYM STA_UNSYNC}
  STA_FREQHOLD	= $0080; { hold frequency (rw) }
  {$EXTERNALSYM STA_FREQHOLD}

  STA_PPSSIGNAL = $0100; { PPS signal present (ro) }
  {$EXTERNALSYM STA_PPSSIGNAL}
  STA_PPSJITTER = $0200; { PPS signal jitter exceeded (ro) }
  {$EXTERNALSYM STA_PPSJITTER}
  STA_PPSWANDER = $0400; { PPS signal wander exceeded (ro) }
  {$EXTERNALSYM STA_PPSWANDER}
  STA_PPSERROR  = $0800; { PPS signal calibration error (ro) }
  {$EXTERNALSYM STA_PPSERROR}

  STA_CLOCKERR  = $1000; { clock hardware fault (ro) }
  {$EXTERNALSYM STA_CLOCKERR}

  STA_RONLY     = (STA_PPSSIGNAL or STA_PPSJITTER or STA_PPSWANDER or
    STA_PPSERROR or STA_CLOCKERR); { read-only bits }
  {$EXTERNALSYM STA_RONLY}

{ Clock states (time_state) }
  TIME_OK       = 0;    { clock synchronized, no leap second }
  {$EXTERNALSYM TIME_OK}
  TIME_INS      = 1;    { insert leap second }
  {$EXTERNALSYM TIME_INS}
  TIME_DEL      = 2;    { delete leap second }
  {$EXTERNALSYM TIME_DEL}
  TIME_OOP      = 3;    { leap second in progress }
  {$EXTERNALSYM TIME_OOP}
  TIME_WAIT     = 4;    { leap second has occurred }
  {$EXTERNALSYM TIME_WAIT}
  TIME_ERROR    = 5;    { clock not synchronized }
  {$EXTERNALSYM TIME_ERROR}
  TIME_BAD      = TIME_ERROR; { bw compat }
  {$EXTERNALSYM TIME_BAD}

{ Maximum time constant of the PLL.  }
  MAXTC         = 6;
  {$EXTERNALSYM MAXTC}


function __adjtimex(var __ntx: timex): Integer; cdecl;
{$EXTERNALSYM __adjtimex}
function adjtimex(var __ntx: timex): Integer; cdecl;
{$EXTERNALSYM adjtimex}

function ntp_gettime(var __ntv: ntptimeval): Integer; cdecl;
{$EXTERNALSYM ntp_gettime}
function ntp_adjtime(var __tntx: timex): Integer; cdecl;
{$EXTERNALSYM ntp_adjtime}


// Translated from sys/times.h

{  Structure describing CPU time used by a process and its children.  }
type
  tms = {packed} record
    tms_utime: clock_t;         { User CPU time.  }
    tms_stime: clock_t;         { System CPU time.  }

    tms_cutime: clock_t;        { User CPU time of dead children.  }
    tms_cstime: clock_t;        { System CPU time of dead children.  }
  end;
  {$EXTERNALSYM tms}
  TTimes = tms;
  PTimes = ^TTimes;

{  Store the CPU time used by this process and all its
   dead children (and their dead children) in BUFFER.
   Return the elapsed real time, or (clock_t) -1 for errors.
   All times are in CLK_TCKths of a second.  }
function times(var __buffer: TTimes): clock_t; cdecl;
{$EXTERNALSYM times}


// Translated from bits/sched.h

{ Scheduling algorithms. }
const
  SCHED_OTHER     = 0;
  {$EXTERNALSYM SCHED_OTHER}
  SCHED_FIFO      = 1;
  {$EXTERNALSYM SCHED_FIFO}
  SCHED_RR        = 2;
  {$EXTERNALSYM SCHED_RR}

{ Cloning flags.  }
  CSIGNAL        = $000000ff; { Signal mask to be sent at exit.  }
  {$EXTERNALSYM CSIGNAL}
  CLONE_VM       = $00000100; { Set if VM shared between processes.  }
  {$EXTERNALSYM CLONE_VM}
  CLONE_FS       = $00000200; { Set if fs info shared between processes.  }
  {$EXTERNALSYM CLONE_FS}
  CLONE_FILES    = $00000400; { Set if open files shared between processes.  }
  {$EXTERNALSYM CLONE_FILES}
  CLONE_SIGHAND  = $00000800; { Set if signal handlers shared.  }
  {$EXTERNALSYM CLONE_SIGHAND}
  CLONE_PID      = $00001000; { Set if pid shared.  }
  {$EXTERNALSYM CLONE_PID}
  CLONE_PTRACE   = $00002000; { Set if tracing continues on the child.  }
  {$EXTERNALSYM CLONE_PTRACE}
  CLONE_VFORK    = $00004000; { Set if the parent wants the child to wake it up on mm_release. }
  {$EXTERNALSYM CLONE_VFORK}

{ Data structure to describe a process' schedulability.  }
type
 sched_param = record
  sched_priority, sched_curpriority: int32_t;
  case Boolean of
   False: (reserved: array[0..7] of int32_t);
   True: (__ss_low_priority, __ss_max_repl: int32_t;
          __ss_repl_period, __ss_init_budget: timespec);
 end;

  __sched_param = sched_param;
  TSchedParam = __sched_param;
  PSchedParam = ^__sched_param;


{ Clone current process.  }
  TCloneProc = function(Arg: Pointer): Integer; cdecl; // Not in header file - used anonymously.

function clone(fn: TCloneProc; ChildStack: Pointer; Flags: Integer;
  Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM clone}

// Translated from sched.h

{ Set scheduling parameters for a process.  }
function sched_setparam(ProcessID: __pid_t; Param: PSchedParam): Integer; cdecl;
{$EXTERNALSYM sched_setparam}

{ Retrieve scheduling parameters for a particular process.  }
function sched_getparam(ProcessID: __pid_t; Param: PSchedParam): Integer; cdecl;
{$EXTERNALSYM sched_getparam}

{ Set scheduling algorithm and/or parameters for a process.  }
function sched_setscheduler(ProcessID: __pid_t; Policy: Integer;
  Param: PSchedParam): Integer; cdecl;
{$EXTERNALSYM sched_setscheduler}

{ Retrieve scheduling algorithm for a particular purpose.  }
function sched_getscheduler(ProcessID: __pid_t): Integer; cdecl;
{$EXTERNALSYM sched_getscheduler}

{ Yield the processor.  }
function sched_yield: Integer; cdecl;
{$EXTERNALSYM sched_yield}

{ Get maximum priority value for a scheduler.  }
function sched_get_priority_max(Algorithm: Integer): Integer; cdecl;
{$EXTERNALSYM sched_get_priority_max}

{ Get minimum priority value for a scheduler.  }
function sched_get_priority_min(Algorithm: Integer): Integer; cdecl;
{$EXTERNALSYM sched_get_priority_min}

{ Get the SCHED_RR interval for the named process.  }
function sched_rr_get_interval(ProcessID: __pid_t; TimeSpec: PTimeSpec): Integer; cdecl;
{$EXTERNALSYM sched_rr_get_interval}


// Translated from bits/pthreadtypes.h

type
  _pthread_descr = Pointer;
  {$EXTERNALSYM _pthread_descr}

{ Fast locks (not abstract because mutexes and conditions aren't abstract). }
  _pthread_fastlock = {packed} record
    __status: Longint;          { "Free" or "taken" or head of waiting list }
    __spinlock: Integer;        { For compare-and-swap emulation }
  end;
  {$EXTERNALSYM _pthread_fastlock}
  TPthreadFastlock = _pthread_fastlock;
  PPthreadFastlock = ^TPthreadFastlock;

{ Attributes for threads.  }
  pthread_attr_t = record
   __detachstate, __schedpolicy: Int32;
   __schedparam: sched_param;
   __inheritsched, __scope: Int32;
   __guardsize: size_t;
   __stackaddr_set: Int32;
   __stackaddr: Pointer;
   __stacksize: UInt32;
  end;

  TThreadAttr = pthread_attr_t;
  PThreadAttr = ^TThreadAttr;

{ Conditions (not abstract because of PTHREAD_COND_INITIALIZER }
  pthread_cond_t = {packed} record
    __c_lock: _pthread_fastlock;     { Protect against concurrent access }
    __c_waiting: _pthread_descr;     { Threads waiting on this condition }
  end;
  {$EXTERNALSYM pthread_cond_t}
  TCondVar = pthread_cond_t;
  PCondVar = ^TCondVar;


{ Attribute for conditionally variables.  }
  pthread_condattr_t = {packed} record
    __dummy: Integer;
  end;
  {$EXTERNALSYM pthread_condattr_t}
  TPthreadCondattr = pthread_condattr_t;
  PPthreadCondattr = ^TPthreadCondattr;

{ Keys for thread-specific data }
  pthread_key_t = Cardinal;
  {$EXTERNALSYM pthread_key_t}
  TPThreadKey = pthread_key_t;


{ Mutexes (not abstract because of PTHREAD_MUTEX_INITIALIZER).  }
{ (The layout is unnatural to maintain binary compatibility
    with earlier releases of LinuxThreads.) }
  pthread_mutex_t = {packed} record
    __m_reserved: Integer;        { Reserved for future use }
    __m_count: Integer;           { Depth of recursive locking }
    __m_owner: _pthread_descr;    { Owner thread (if recursive or errcheck) }
    __m_kind: Integer;            { Mutex kind: fast, recursive or errcheck }
    __m_lock: _pthread_fastlock;     { Underlying fast lock }
  end;
  {$EXTERNALSYM pthread_mutex_t}
  TRTLCriticalSection = pthread_mutex_t;
  PRTLCriticalSection = ^TRTLCriticalSection;

{ Attribute for mutex.  }
  pthread_mutexattr_t = {packed} record
    __mutexkind: Integer;
  end;
  {$EXTERNALSYM pthread_mutexattr_t}
  TMutexAttribute = pthread_mutexattr_t;
  PMutexAttribute = ^TMutexAttribute;

{ Once-only execution }
  pthread_once_t = Integer;
  {$EXTERNALSYM pthread_once_t}
  TPThreadOnce = pthread_once_t;
  PPThreadOnce = ^pthread_once_t;


{ Read-write locks.  }
  pthread_rwlock_t = {packed} record
    __rw_lock: _pthread_fastlock;       { Lock to guarantee mutual exclusion }
    __rw_readers: Integer;              { Number of readers }
    __rw_writer: _pthread_descr;        { Identity of writer, or NULL if none }
    __rw_read_waiting: _pthread_descr;  { Threads waiting for reading }
    __rw_write_waiting: _pthread_descr; { Threads waiting for writing }
    __rw_kind: Integer;                 { Reader/Writer preference selection }
    __rw_pshared: Integer;              { Shared between processes or not }
  end;
  {$EXTERNALSYM pthread_rwlock_t}
  TPthreadRWlock = pthread_rwlock_t;
  PPthreadRWlock = ^TPthreadRWlock;


{ Attribute for read-write locks.  }
  pthread_rwlockattr_t = {packed} record
    __lockkind: Integer;
    __pshared: Integer;
  end;
  {$EXTERNALSYM pthread_rwlockattr_t}
  TPthreadRWlockAttribute = pthread_rwlockattr_t;
  PPthreadRWlockAttribute = ^TPthreadRWlockAttribute;

{ POSIX spinlock data type.  }
  pthread_spinlock_t = Integer;
  {$EXTERNALSYM pthread_spinlock_t}
  TPthreadSpinlock = pthread_spinlock_t;

{ POSIX barrier. }
  pthread_barrier_t = {packed} record
    __ba_lock: _pthread_fastlock;  { Lock to guarantee mutual exclusion }
    __ba_required: Integer;        { Threads needed for completion }
    __ba_present: Integer;         { Threads waiting }
    __ba_waiting: _pthread_descr;  { Queue of waiting threads }
  end;
  {$EXTERNALSYM pthread_barrier_t}
  TPthreadBarrier = pthread_barrier_t;
  PPthreadBarrier = ^TPthreadBarrier;

{ Barrier attribute }
  pthread_barrierattr_t = {packed} record
    __pshared: Integer;
  end;
  {$EXTERNALSYM pthread_barrierattr_t}
  TPthreadBarrierAttribute = pthread_barrierattr_t;
  PPthreadBarrierAttribute = ^TPthreadBarrierAttribute;

{ Thread identifiers }
  pthread_t = LongWord;
  {$EXTERNALSYM pthread_t}
  TThreadID = pthread_t;

  
// Translated from pthread.h

{ Values for attributes. }

const
  PTHREAD_CREATE_JOINABLE = 0;
  {$EXTERNALSYM PTHREAD_CREATE_JOINABLE}
  PTHREAD_CREATE_DETACHED = 1;
  {$EXTERNALSYM PTHREAD_CREATE_DETACHED}

const
  PTHREAD_INHERIT_SCHED = 0;
  {$EXTERNALSYM PTHREAD_INHERIT_SCHED}
  PTHREAD_EXPLICIT_SCHED = 1;
  {$EXTERNALSYM PTHREAD_EXPLICIT_SCHED}

const
  PTHREAD_SCOPE_SYSTEM = 0;
  {$EXTERNALSYM PTHREAD_SCOPE_SYSTEM}
  PTHREAD_SCOPE_PROCESS = 1;
  {$EXTERNALSYM PTHREAD_SCOPE_PROCESS}

const
  PTHREAD_MUTEX_TIMED_NP = 0;
  {$EXTERNALSYM PTHREAD_MUTEX_TIMED_NP}
  PTHREAD_MUTEX_RECURSIVE_NP = 1;
  {$EXTERNALSYM PTHREAD_MUTEX_RECURSIVE_NP}
  PTHREAD_MUTEX_ERRORCHECK_NP = 2;
  {$EXTERNALSYM PTHREAD_MUTEX_ERRORCHECK_NP}
  PTHREAD_MUTEX_ADAPTIVE_NP = 3;
  {$EXTERNALSYM PTHREAD_MUTEX_ADAPTIVE_NP}

  PTHREAD_MUTEX_NORMAL = PTHREAD_MUTEX_TIMED_NP;
  {$EXTERNALSYM PTHREAD_MUTEX_NORMAL}
  PTHREAD_MUTEX_RECURSIVE = PTHREAD_MUTEX_RECURSIVE_NP;
  {$EXTERNALSYM PTHREAD_MUTEX_RECURSIVE}
  PTHREAD_MUTEX_ERRORCHECK = PTHREAD_MUTEX_ERRORCHECK_NP;
  {$EXTERNALSYM PTHREAD_MUTEX_ERRORCHECK}
  PTHREAD_MUTEX_DEFAULT = PTHREAD_MUTEX_NORMAL;
  {$EXTERNALSYM PTHREAD_MUTEX_DEFAULT}

  { For compatibility.  }
  PTHREAD_MUTEX_FAST_NP = PTHREAD_MUTEX_ADAPTIVE_NP;
  {$EXTERNALSYM PTHREAD_MUTEX_FAST_NP}

const
  PTHREAD_PROCESS_PRIVATE = 0;
  {$EXTERNALSYM PTHREAD_PROCESS_PRIVATE}
  PTHREAD_PROCESS_SHARED = 1;
  {$EXTERNALSYM PTHREAD_PROCESS_SHARED}

  PTHREAD_RWLOCK_PREFER_READER_NP = 0;
  {$EXTERNALSYM PTHREAD_RWLOCK_PREFER_READER_NP}
  PTHREAD_RWLOCK_PREFER_WRITER_NP = 1;
  {$EXTERNALSYM PTHREAD_RWLOCK_PREFER_WRITER_NP}
  PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP = 2;
  {$EXTERNALSYM PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP}
  PTHREAD_RWLOCK_DEFAULT_NP = PTHREAD_RWLOCK_PREFER_WRITER_NP;
  {$EXTERNALSYM PTHREAD_RWLOCK_DEFAULT_NP}

  PTHREAD_ONCE_INIT = 0;
  {$EXTERNALSYM PTHREAD_ONCE_INIT}


{ Special constants }
const
  { -1 is distinct from 0 and all errno constants }
  PTHREAD_BARRIER_SERIAL_THREAD = -1;
  {$EXTERNALSYM PTHREAD_BARRIER_SERIAL_THREAD}

{ Cleanup buffers }
type
  // Used anonymously in header file.
  TPThreadCleanupRoutine = procedure(Arg: Pointer); cdecl;

  PPthreadCleanupBuffer = ^_pthread_cleanup_buffer;
  _pthread_cleanup_buffer = {packed} record
    __routine: TPThreadCleanupRoutine;    { Function to call.  }
    __arg: Pointer;                       { Its argument.  }
    __canceltype: Integer;                { Saved cancellation type. }
    __prev: PPthreadCleanupBuffer;        { Chaining of cleanup functions.  }
  end;
  {$EXTERNALSYM _pthread_cleanup_buffer}
  TPthreadCleanupBuffer = _pthread_cleanup_buffer;

{ Cancellation }

const
  PTHREAD_CANCEL_ENABLE = 0;
  {$EXTERNALSYM PTHREAD_CANCEL_ENABLE}
  PTHREAD_CANCEL_DISABLE = 1;
  {$EXTERNALSYM PTHREAD_CANCEL_DISABLE}

const
  PTHREAD_CANCEL_DEFERRED = 0;
  {$EXTERNALSYM PTHREAD_CANCEL_DEFERRED}
  PTHREAD_CANCEL_ASYNCHRONOUS = 1;
  {$EXTERNALSYM PTHREAD_CANCEL_ASYNCHRONOUS}
  PTHREAD_CANCELED = Pointer(-1);
  {$EXTERNALSYM PTHREAD_CANCELED}

  // Mutex Kind
  NONRECURSIVE  = 0;
  {$EXTERNALSYM NONRECURSIVE}
  RECURSIVE     = 1;
  {$EXTERNALSYM RECURSIVE}

type
  // Used anonymously in header file.
  TPThreadFunc = function(Parameter: Pointer): Integer; cdecl;

{ Function for handling threads.  }

{ Create a thread with given attributes ATTR (or default attributes
   if ATTR is NULL), and call function START_ROUTINE with given
   arguments ARG.  }

function pthread_create(var ThreadID: TThreadID; Attr: PThreadAttr;
  StartRoutine: TPThreadFunc; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM pthread_create}

{ Obtain the identifier of the current thread.  }
function pthread_self: TThreadID; cdecl;
{$EXTERNALSYM pthread_self}
{ Declare an alias of pthread_self for portability - not present in header file. }
function GetCurrentThreadID: TThreadID; cdecl;

{ Compare two thread identifiers.  }
function pthread_equal(Thread1ID, Thread2ID: TThreadID): Integer; cdecl;
{$EXTERNALSYM pthread_equal}

{ Terminate calling thread.  }
procedure pthread_exit(RetVal: Pointer); cdecl;
{$EXTERNALSYM pthread_exit}

{ Make calling thread wait for termination of the thread TH.  The
   exit status of the thread is stored in *THREAD_RETURN, if THREAD_RETURN
   is not NULL.  }
function pthread_join(ThreadID: TThreadID; ThreadReturn: PPointer): Integer; cdecl;
{$EXTERNALSYM pthread_join}

{ Indicate that the thread TH is never to be joined with PTHREAD_JOIN.
   The resources of TH will therefore be freed immediately when it
   terminates, instead of waiting for another thread to perform PTHREAD_JOIN
   on it. }
function pthread_detach(ThreadID: TThreadID): Integer; cdecl;
{$EXTERNALSYM pthread_detach}


{ Functions for handling attributes.  }

{ Initialize thread attribute *ATTR with default attributes
   (detachstate is PTHREAD_JOINABLE, scheduling policy is SCHED_OTHER,
    no user-provided stack).  }
function pthread_attr_init(var Attr: TThreadAttr): Integer; cdecl;
{$EXTERNALSYM pthread_attr_init}

{ Destroy thread attribute *ATTR.  }
function pthread_attr_destroy(var Attr: TThreadAttr): Integer; cdecl;
{$EXTERNALSYM pthread_attr_destroy}

{ Set the `detachstate' attribute in *ATTR according to DETACHSTATE.  }
function pthread_attr_setdetachstate(var Attr: TThreadAttr;
  DetachState: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setdetachstate}

{ Return in *DETACHSTATE the `detachstate' attribute in *ATTR.  }
function pthread_attr_getdetachstate(const Attr: TThreadAttr;
  var DetachState: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getdetachstate}

{ Set scheduling parameters (priority, etc) in *ATTR according to PARAM.  }
function pthread_attr_setschedparam(var Attr: TThreadAttr;
  Param: PSchedParam): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setschedparam}

{ Return in *PARAM the scheduling parameters of *ATTR.  }
function pthread_attr_getschedparam(const Attr: TThreadAttr;
  var Param: TSchedParam): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getschedparam}

{ Set scheduling policy in *ATTR according to POLICY.  }
function pthread_attr_setschedpolicy(var Attr: TThreadAttr;
  Policy: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setschedpolicy}

{ Return in *POLICY the scheduling policy of *ATTR.  }
function pthread_attr_getschedpolicy(const Attr: TThreadAttr;
  var Policy: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getschedpolicy}

{ Set scheduling inheritance mode in *ATTR according to INHERIT.  }
function pthread_attr_setinheritsched(var Attr: TThreadAttr;
  Inherit: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setinheritsched}

{ Return in *INHERIT the scheduling inheritance mode of *ATTR.  }
function pthread_attr_getinheritsched(const Attr: TThreadAttr;
  var Inherit: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getinheritsched}

{ Set scheduling contention scope in *ATTR according to SCOPE.  }
function pthread_attr_setscope(var Attr: TThreadAttr;
  Scope: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setscope}

{ Return in *SCOPE the scheduling contention scope of *ATTR.  }
function pthread_attr_getscope(const Attr: TThreadAttr;
  var Scope: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getscope}

{ Set the size of the guard area at the bottom of the thread.  }
function pthread_attr_setguardsize(var Attr: TThreadAttr;
  Guardsize: LongWord): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setguardsize}

{ Get the size of the guard area at the bottom of the thread.  }
function pthread_attr_getguardsize(const Attr: TThreadAttr;
  var Guardsize: LongWord): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getguardsize}

{ Set the starting address of the stack of the thread to be created.
   Depending on whether the stack grows up or doen the value must either
   be higher or lower than all the address in the memory block.  The
   minimal size of the block must be PTHREAD_STACK_SIZE.  }
function pthread_attr_setstackaddr(var Attr: TThreadAttr;
  StackAddr: Pointer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setstackaddr}

{ Return the previously set address for the stack.  }
function pthread_attr_getstackaddr(const Attr: TThreadAttr;
  var StackAddr: Pointer): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getstackaddr}

{ The following two interfaces are intended to replace the last two.  They
   require setting the address as well as the size since only setting the
   address will make the implementation on some architectures impossible.  }
function pthread_attr_setstack(var Attr: TThreadAttr; StackAddr: Pointer;
  StackSize: size_t): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setstack}

{ Return the previously set address for the stack.  }
function pthread_attr_getstack(const Attr: TThreadAttr; var StackAddr: Pointer;
  var StackSize: size_t): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getstack}

{ Add information about the minimum stack size needed for the thread
   to be started.  This size must never be less than PTHREAD_STACK_SIZE
   and must also not exceed the system limits.  }
function pthread_attr_setstacksize(var Attr: TThreadAttr;
  StackSize: LongWord): Integer; cdecl;
{$EXTERNALSYM pthread_attr_setstacksize}

{ Return the currently used minimal stack size.  }
function pthread_attr_getstacksize(const Attr: TThreadAttr;
  var StackSize: LongWord): Integer; cdecl;
{$EXTERNALSYM pthread_attr_getstacksize}

{ Functions for scheduling control. }

{ Set the scheduling parameters for TARGET_THREAD according to POLICY
   and *PARAM. }
function pthread_setschedparam(TargetThreadID: TThreadID; Policy: Integer;
  Param: PSchedParam): Integer; cdecl;
{$EXTERNALSYM pthread_setschedparam}

{ Return in *POLICY and *PARAM the scheduling parameters for TARGET_THREAD. }
function pthread_getschedparam(TargetThreadID: TThreadID; var Policy: Integer;
  var Param: TSchedParam): Integer; cdecl;
{$EXTERNALSYM pthread_getschedparam}

{ Determine  level of concurrency.  }
function pthread_getconcurrency: Integer; cdecl;
{$EXTERNALSYM pthread_getconcurrency}

{ Set new concurrency level to LEVEL.  }
function pthread_setconcurrency(Level: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_setconcurrency}

{ Yield the processor to another thread or process.
   This function is similar to the POSIX `sched_yield' function but
   might be differently implemented in the case of a m-on-n thread
   implementation.  }
function pthread_yield(): Integer; cdecl;
{$EXTERNALSYM pthread_yield}

{ Functions for mutex handling. }

{ Initialize MUTEX using attributes in *MUTEX_ATTR, or use the
   default values if later is NULL.  }
function pthread_mutex_init(var Mutex: TRTLCriticalSection;
  var Attr: TMutexAttribute): Integer; cdecl; overload;
function pthread_mutex_init(var Mutex: TRTLCriticalSection;
  Attr: PMutexAttribute): Integer; cdecl; overload;
{$EXTERNALSYM pthread_mutex_init}

{ Destroy MUTEX.  }
function pthread_mutex_destroy(var Mutex: TRTLCriticalSection): Integer; cdecl;
{$EXTERNALSYM pthread_mutex_destroy}

{ Try to lock MUTEX.  }
function pthread_mutex_trylock(var Mutex: TRTLCriticalSection): Integer; cdecl;
{$EXTERNALSYM pthread_mutex_trylock}

{ Wait until lock for MUTEX becomes available and lock it.  }
function pthread_mutex_lock(var Mutex: TRTLCriticalSection): Integer; cdecl;
{$EXTERNALSYM pthread_mutex_lock}

{ Wait until lock becomes available, or specified time passes. }
function pthread_mutex_timedlock(var Mutex: TRTLCriticalSection; const AbsTime: timespec): Integer; cdecl;
{$EXTERNALSYM pthread_mutex_timedlock}

{ Unlock MUTEX.  }
function pthread_mutex_unlock(var Mutex: TRTLCriticalSection): Integer; cdecl;
{$EXTERNALSYM pthread_mutex_unlock}


{ Functions for handling mutex attributes.  }

{ Initialize mutex attribute object ATTR with default attributes
   (kind is PTHREAD_MUTEX_FAST_NP).  }
function pthread_mutexattr_init(var Attr: TMutexAttribute): Integer; cdecl;
{$EXTERNALSYM pthread_mutexattr_init}

{ Destroy mutex attribute object ATTR.  }
function pthread_mutexattr_destroy(var Attr: TMutexAttribute): Integer; cdecl;
{$EXTERNALSYM pthread_mutexattr_destroy}

{ Get the process-shared flag of the mutex attribute ATTR.  }
function pthread_mutexattr_getpshared(var Attr: TMutexAttribute; // Actually __const pthread_mutexattr_t *
  var ProcessShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_mutexattr_getpshared}

{ Set the process-shared flag of the mutex attribute ATTR.  }
function pthread_mutexattr_setpshared(var Attr: TMutexAttribute;
  ProcessShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_mutexattr_setpshared}

{ Set the mutex kind attribute in *ATTR to KIND (either PTHREAD_MUTEX_NORMAL,
   PTHREAD_MUTEX_RECURSIVE, PTHREAD_MUTEX_ERRORCHECK, or
   PTHREAD_MUTEX_DEFAULT).  }
function pthread_mutexattr_settype(var Attr: TMutexAttribute; Kind: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_mutexattr_settype}

{ Return in *KIND the mutex kind attribute in *ATTR. }
function pthread_mutexattr_gettype(var Attr: TMutexAttribute; var Kind: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_mutexattr_gettype}


{ Functions for handling conditional variables.  }

{ Initialize condition variable COND using attributes ATTR, or use
   the default values if later is NULL.  }
function pthread_cond_init(var Cond: TCondVar;
  var CondAttr: TPthreadCondattr): Integer; cdecl; overload;
function pthread_cond_init(var Cond: TCondVar;
  CondAttr: PPthreadCondattr): Integer; cdecl; overload;
{$EXTERNALSYM pthread_cond_init}

{ Destroy condition variable COND.  }
function pthread_cond_destroy(var Cond: TCondVar): Integer; cdecl;
{$EXTERNALSYM pthread_cond_destroy}

{ Wake up one thread waiting for condition variable COND.  }
function pthread_cond_signal(var Cond: TCondVar): Integer; cdecl;
{$EXTERNALSYM pthread_cond_signal}

{ Wake up all threads waiting for condition variables COND.  }
function pthread_cond_broadcast(var Cond: TCondVar): Integer; cdecl;
{$EXTERNALSYM pthread_cond_broadcast}

{ Wait for condition variable COND to be signaled or broadcast.
   MUTEX is assumed to be locked before.  }
function pthread_cond_wait(var Cond: TCondVar;
  var Mutex: TRTLCriticalSection): Integer; cdecl;
{$EXTERNALSYM pthread_cond_wait}

{ Wait for condition variable COND to be signaled or broadcast until
   ABSTIME.  MUTEX is assumed to be locked before.  ABSTIME is an
   absolute time specification; zero is the beginning of the epoch
   (00:00:00 GMT, January 1, 1970). }
function pthread_cond_timedwait(var Cond: TCondVar;
  var Mutex: TRTLCriticalSection; const AbsTime: TTimeSpec): Integer; cdecl;
{$EXTERNALSYM pthread_cond_timedwait}

{ Functions for handling condition variable attributes.  }

{ Initialize condition variable attribute ATTR.  }
function pthread_condattr_init(var Attr: TPthreadCondattr): Integer; cdecl;
{$EXTERNALSYM pthread_condattr_init}

{ Destroy condition variable attribute ATTR.  }
function pthread_condattr_destroy(var Attr: TPthreadCondattr): Integer; cdecl;
{$EXTERNALSYM pthread_condattr_destroy}

{ Get the process-shared flag of the condition variable attribute ATTR.  }
function pthread_condattr_getpshared(var Attr: TPthreadCondattr; // Actually: const *
  var ProcessShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_condattr_getpshared}

{ Set the process-shared flag of the condition variable attribute ATTR.  }
function pthread_condattr_setpshared(var Attr: TPthreadCondattr;
  ProcessShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_condattr_setpshared}


{ Functions for handling read-write locks.  }

{ Initialize read-write lock RWLOCK using attributes ATTR, or use
   the default values if latter is NULL.  }
function pthread_rwlock_init(var RWLock: TPthreadRWlock;
  Attr: PPthreadRWlockAttribute): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_init}

{ Destroy read-write lock RWLOCK.  }
function pthread_rwlock_destroy(var RWLock: TPthreadRWlock): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_destroy}

{ Acquire read lock for RWLOCK.  }
function pthread_rwlock_rdlock(var RWLock: TPthreadRWlock): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_rdlock}

{ Try to acquire read lock for RWLOCK.  }
function pthread_rwlock_tryrdlock(var RWLock: TPthreadRWlock): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_tryrdlock}

{ Try to acquire read lock for RWLOCK or return after specfied time.  }
function pthread_rwlock_timedrdlock(var RWLock: TPthreadRWlock;
  const AbsTime: timespec): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_timedrdlock}

{ Acquire write lock for RWLOCK.  }
function pthread_rwlock_wrlock(var RWLock: TPthreadRWlock): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_wrlock}

{ Try to acquire writelock for RWLOCK.  }
function pthread_rwlock_trywrlock(var RWLock: TPthreadRWlock): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_trywrlock}

{ Try to acquire write lock for RWLOCK or return after specfied time.  }
function pthread_rwlock_timedwrlock(var RWLock: TPthreadRWlock;
  const AbsTime: timespec): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_timedwrlock}

{ Unlock RWLOCK.  }
function pthread_rwlock_unlock(var RWLock: TPthreadRWlock): Integer; cdecl;
{$EXTERNALSYM pthread_rwlock_unlock}


{ Functions for handling read-write lock attributes.  }

{ Initialize attribute object ATTR with default values.  }
function pthread_rwlockattr_init(var Attr: TPthreadRWlockAttribute): Integer; cdecl;
{$EXTERNALSYM pthread_rwlockattr_init}

{ Destroy attribute object ATTR.  }
function pthread_rwlockattr_destroy(var Attr: TPthreadRWlockAttribute): Integer; cdecl;
{$EXTERNALSYM pthread_rwlockattr_destroy}

{ Return current setting of process-shared attribute of ATTR in PSHARED.  }
function pthread_rwlockattr_getpshared(const Attr: TPthreadRWlockAttribute;
  var PShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_rwlockattr_getpshared}

{ Set process-shared attribute of ATTR to PSHARED.  }
function pthread_rwlockattr_setpshared(var Attr: TPthreadRWlockAttribute;
  PShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_rwlockattr_setpshared}

{ Return current setting of reader/writer preference.  }
function pthread_rwlockattr_getkind_np(const Attr: TPthreadRWlockAttribute;
  var Pref: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_rwlockattr_getkind_np}

{ Set reader/write preference.  }
function pthread_rwlockattr_setkind_np(var Attr: TPthreadRWlockAttribute;
  Pref: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_rwlockattr_setkind_np}

{ The IEEE Std. 1003.1j-2000 introduces functions to implement
   spinlocks.  }

{ Initialize the spinlock LOCK.  If PSHARED is nonzero the spinlock can
   be shared between different processes.  }
function pthread_spin_init(var Lock: TPthreadSpinlock; ProcessShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_spin_init}

{ Destroy the spinlock LOCK.  }
function pthread_spin_destroy(var Lock: TPthreadSpinlock): Integer; cdecl;
{$EXTERNALSYM pthread_spin_destroy}

{ Wait until spinlock LOCK is retrieved.  }
function pthread_spin_lock(var Lock: TPthreadSpinlock): Integer; cdecl;
{$EXTERNALSYM pthread_spin_lock}

{ Try to lock spinlock LOCK.  }
function pthread_spin_trylock(var Lock: TPthreadSpinlock): Integer; cdecl;
{$EXTERNALSYM pthread_spin_trylock}

{ Release spinlock LOCK.  }
function pthread_spin_unlock(var Lock: TPthreadSpinlock): Integer; cdecl;
{$EXTERNALSYM pthread_spin_unlock}


{ Barriers are a also a new feature in 1003.1j-2000. }

function pthread_barrier_init(var Barrier: TPthreadBarrier;
  var Attr: TPthreadBarrierAttribute; Count: Cardinal): Integer; cdecl; overload;
function pthread_barrier_init(var Barrier: TPthreadBarrier;
  Attr: PPthreadBarrierAttribute; Count: Cardinal): Integer; cdecl; overload;
{$EXTERNALSYM pthread_barrier_init}

function pthread_barrier_destroy(var Barrier: TPthreadBarrier): Integer; cdecl;
{$EXTERNALSYM pthread_barrier_destroy}

function pthread_barrierattr_init(var Barrier: TPthreadBarrier): Integer; cdecl;
{$EXTERNALSYM pthread_barrierattr_init}

function pthread_barrierattr_destroy(var Barrier: TPthreadBarrier): Integer; cdecl;
{$EXTERNALSYM pthread_barrierattr_destroy}

function pthread_barrierattr_getpshared(var Attr: TPthreadBarrierAttribute;
  var ProcessShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_barrierattr_getpshared}

function pthread_barrierattr_setpshared(var Attr: TPthreadBarrierAttribute;
  ProcessShared: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_barrierattr_setpshared}

function pthread_barrier_wait(var Barrier: TPthreadBarrier): Integer; cdecl;
{$EXTERNALSYM pthread_barrier_wait}

{ Functions for handling thread-specific data }

{ Create a key value identifying a location in the thread-specific data
   area.  Each thread maintains a distinct thread-specific data area.
   DESTR_FUNCTION, if non-NULL, is called with
   the value associated to that key when the key is destroyed.
   DESTR_FUNCTION is not called if the value associated is NULL
   when the key is destroyed. }
type
  // Used anonymously in header file.
  TKeyValueDestructor = procedure(ValueInKey: Pointer); cdecl;

function pthread_key_create(var Key: TPThreadKey;
  DestrFunction: TKeyValueDestructor): Integer; cdecl;
{$EXTERNALSYM pthread_key_create}

{ Destroy KEY.  }
function pthread_key_delete(Key: TPThreadKey): Integer; cdecl;
{$EXTERNALSYM pthread_key_delete}

{ Store POINTER in the thread-specific data slot identified by KEY. }
function pthread_setspecific(Key: TPThreadKey; Ptr: Pointer): Integer; cdecl;
{$EXTERNALSYM pthread_setspecific}

{ Return current value of the thread-specific data slot identified by KEY.  }
function pthread_getspecific(Key: TPThreadKey): Pointer; cdecl;
{$EXTERNALSYM pthread_getspecific}


{ Functions for handling initialization }

{ Guarantee that the initialization function INIT_ROUTINE will be called
   only once, even if pthread_once is executed several times with the
   same ONCE_CONTROL argument. ONCE_CONTROL must point to a static or
   extern variable initialized to PTHREAD_ONCE_INIT. }
type
  TInitOnceProc = procedure; cdecl; // Not in header file - used anonymously.

function pthread_once(var InitOnceSemaphore: TPThreadOnce; InitRoutine: TInitOnceProc): Integer; cdecl;
{$EXTERNALSYM pthread_once}

{ Functions for handling cancellation. }

{ Set cancelability state of current thread to STATE, returning old
   state in *OLDSTATE if OLDSTATE is not NULL.  }
function pthread_setcancelstate(State: Integer; OldState: PInteger): Integer; cdecl;
{$EXTERNALSYM pthread_setcancelstate}

{ Set cancellation state of current thread to TYPE, returning the old
   type in *OLDTYPE if OLDTYPE is not NULL.  }
function pthread_setcanceltype(CancelType: Integer; OldType: PInteger): Integer; cdecl;
{$EXTERNALSYM pthread_setcanceltype}

{ Cancel THREAD immediately or at the next possibility.  }
function pthread_cancel(ThreadID: TThreadID): Integer; cdecl;
{$EXTERNALSYM pthread_cancel}

{ Test for pending cancellation for the current thread and terminate
   the thread as per pthread_exit(PTHREAD_CANCELED) if it has been
   cancelled. }
procedure pthread_testcancel; cdecl;
{$EXTERNALSYM pthread_testcancel}


{ Install a cleanup handler: ROUTINE will be called with arguments ARG
   when the thread is cancelled or calls pthread_exit.  ROUTINE will also
   be called with arguments ARG when the matching pthread_cleanup_pop
   is executed with non-zero EXECUTE argument.
   pthread_cleanup_push and pthread_cleanup_pop are macros and must always
   be used in matching pairs at the same nesting level of braces. }

procedure _pthread_cleanup_push(var Buffer: TPthreadCleanupBuffer;
  Routine: TPthreadCleanupRoutine; Arg: Pointer); cdecl;
{$EXTERNALSYM _pthread_cleanup_push}

{ Remove a cleanup handler installed by the matching pthread_cleanup_push.
   If EXECUTE is non-zero, the handler function is called. }

procedure _pthread_cleanup_pop(var Buffer: TPthreadCleanupBuffer;
  Execute: Integer); cdecl;
{$EXTERNALSYM _pthread_cleanup_pop}

{ Install a cleanup handler as pthread_cleanup_push does, but also
   saves the current cancellation type and set it to deferred cancellation. }

procedure _pthread_cleanup_push_defer(Buffer: PPthreadCleanupBuffer;
  Routine: TPthreadCleanupRoutine; Arg: Pointer); cdecl;
{$EXTERNALSYM _pthread_cleanup_push_defer}

{ Remove a cleanup handler as pthread_cleanup_pop does, but also
   restores the cancellation type that was in effect when the matching
   pthread_cleanup_push_defer was called. }

procedure _pthread_cleanup_pop_restore(Buffer: PPthreadCleanupBuffer;
  Execute: Integer); cdecl;
{$EXTERNALSYM _pthread_cleanup_pop_restore}

{ Get ID of CPU-time clock for thread THREAD_ID.  }
function pthread_getcpuclockid(ThreadID: TThreadID; var ClockID: __clockid_t): Integer; cdecl;
{$EXTERNALSYM pthread_getcpuclockid}


{ Functions for handling process creation and process execution. }

{ Install handlers to be called when a new process is created with FORK.
   The PREPARE handler is called in the parent process just before performing
   FORK. The PARENT handler is called in the parent process just after FORK.
   The CHILD handler is called in the child process.  Each of the three
   handlers can be NULL, meaning that no handler needs to be called at that
   point.
   PTHREAD_ATFORK can be called several times, in which case the PREPARE
   handlers are called in LIFO order (last added with PTHREAD_ATFORK,
   first called before FORK), and the PARENT and CHILD handlers are called
   in FIFO (first added, first called). }

type
  TForkHandler = procedure; cdecl; // Used anonymously in header file.

function pthread_atfork(Prepare: TForkHandler; Parent: TForkHandler;
  Child: TForkHandler): Integer; cdecl;
{$EXTERNALSYM pthread_atfork}

{ Terminate all threads in the program except the calling process.
   Should be called just before invoking one of the exec*() functions. }

procedure pthread_kill_other_threads_np; cdecl;
{$EXTERNALSYM pthread_kill_other_threads_np}


{ This function is called to initialize the pthread library. }
procedure __pthread_initialize; cdecl;
{$EXTERNALSYM __pthread_initialize}

// Translated from bits/sigthread.h

{ Functions for handling signals. }

{ Modify the signal mask for the calling thread.  The arguments have
   the same meaning as for sigprocmask(2). }
function pthread_sigmask(How: Integer; const NewMask: PSigSet;
  OldMask: PSigSet): Integer; cdecl;
{$EXTERNALSYM pthread_sigmask}

{ Send signal SIGNO to the given thread. }
function pthread_kill(ThreadID: TThreadID; SigNum: Integer): Integer; cdecl;
{$EXTERNALSYM pthread_kill}


// Translated from semaphore.h

{ Functions for handling semaphores }

{ System specific semaphore definition.  }
type
  __sem_lock_t = {packed} record { Not in header file - anonymous }
    status: Longint;
    spinlock: Integer;
  end;

  sem_t = {packed} record
    __sem_lock: __sem_lock_t;
    __sem_value: Integer;
    __sem_waiting: _pthread_descr;
  end;
  {$EXTERNALSYM sem_t}
  TSemaphore = sem_t;
  PSemaphore = ^TSemaphore;

const
  { Value returned if `sem_open' failed. }
  SEM_FAILED = PSemaphore(nil);
  {$EXTERNALSYM SEM_FAILED}

  { Maximum value the semaphore can have. }
  SEM_VALUE_MAX = Integer((not 0) shr 1);
  {$EXTERNALSYM SEM_VALUE_MAX}

{ Initialize semaphore object SEM to VALUE.  If PSHARED then share it
  with other processes. }
function sem_init(var __sem: TSemaphore; __pshared: LongBool; __value: LongWord): Integer; cdecl;
{$EXTERNALSYM sem_init}

{ Free resources associated with semaphore object SEM. }
function sem_destroy(var __sem: TSemaphore): Integer; cdecl;
{$EXTERNALSYM sem_destroy}

{ Open a named semaphore NAME with open flag OFLAG. }
function sem_open(__name: PChar; __oflag: Integer): PSemaphore; cdecl; varargs;
{$EXTERNALSYM sem_open}

{ Close descriptor for named semaphore SEM. }
function sem_close(var __sem: TSemaphore): Integer; cdecl;
{$EXTERNALSYM sem_close}

{ Remove named semaphore NAME. }
function sem_unlink(__name: PChar): Integer; cdecl;
{$EXTERNALSYM sem_unlink}

{ Wait for SEM being posted. }
function sem_wait(var __sem: TSemaphore): Integer; cdecl;
{$EXTERNALSYM sem_wait}

{ Similar to `sem_wait' but wait only until ABSTIME.  }
function sem_timedwait(var __sem: TSemaphore; const __abstime: timespec): Integer; cdecl;
{$EXTERNALSYM sem_timedwait}

{ Test whether SEM is posted. }
function sem_trywait(var __sem: TSemaphore): Integer; cdecl;
{$EXTERNALSYM sem_trywait}

{ Post SEM. }
function sem_post(var __sem: TSemaphore): Integer; cdecl;
{$EXTERNALSYM sem_post}

{ Get current value of SEM and store it in *SVAL. }
function sem_getvalue(var __sem: TSemaphore; var __sval: Integer): Integer; cdecl;
{$EXTERNALSYM sem_getvalue}

                      
type
  TPCharArray = packed array[0..(MaxLongint div SizeOf(PChar))-1] of PChar;
  PPCharArray = ^TPCharArray;

// Translated from spawn.h

type
{ Data structure to contain attributes for thread creation.  }
  posix_spawnattr_t = {packed} record
    __flags: Word;
    __pgrp: pid_t;
    __sd: sigset_t;
    __ss: sigset_t;
    __sp: sched_param;
    __policy: Integer;
    __pad: packed array[0..16-1] of Integer;
  end;
  {$EXTERNALSYM posix_spawnattr_t}


{ Data structure to contain information about the actions to be
   performed in the new process with respect to file descriptors.  }

  __spawn_action = record end; // Used anonymously in header file; opaque structure
  TSpawnAction = __spawn_action;
  PSpawnAction = ^TSpawnAction;

  posix_spawn_file_actions_t = {packed} record
    __allocated: Integer;
    __used: Integer;
    __actions: PSpawnAction;
    __pad: packed array[0..16-1] of Integer;
  end;
  {$EXTERNALSYM posix_spawn_file_actions_t}

const
{ Flags to be set in the `posix_spawnattr_t'.  }
  POSIX_SPAWN_RESETIDS          = $01;
  {$EXTERNALSYM POSIX_SPAWN_RESETIDS}
  POSIX_SPAWN_SETPGROUP         = $02;
  {$EXTERNALSYM POSIX_SPAWN_SETPGROUP}
  POSIX_SPAWN_SETSIGDEF         = $04;
  {$EXTERNALSYM POSIX_SPAWN_SETSIGDEF}
  POSIX_SPAWN_SETSIGMASK        = $08;
  {$EXTERNALSYM POSIX_SPAWN_SETSIGMASK}
  POSIX_SPAWN_SETSCHEDPARAM     = $10;
  {$EXTERNALSYM POSIX_SPAWN_SETSCHEDPARAM}
  POSIX_SPAWN_SETSCHEDULER      = $20;
  {$EXTERNALSYM POSIX_SPAWN_SETSCHEDULER}


{ Spawn a new process executing PATH with the attributes describes in *ATTRP.
   Before running the process perform the actions described in FILE-ACTIONS. }
function posix_spawn(var __pid: pid_t; __path: PChar;
  const __file_actions: posix_spawn_file_actions_t; const __attr: posix_spawnattr_t;
  argv: PPCharArray; envp: PPCharArray): Integer; cdecl;
{$EXTERNALSYM posix_spawn}

{ Similar to `posix_spawn' but search for FILE in the PATH.  }
function posix_spawnp(var __pid: pid_t; __file: PChar;
  const __file_actions: posix_spawn_file_actions_t; const __attr: posix_spawnattr_t;
  argv: PPCharArray; envp: PPCharArray): Integer; cdecl;
{$EXTERNALSYM posix_spawnp}

{ Initialize data structure with attributes for `spawn' to default values.  }
function posix_spawnattr_init(var __attr: posix_spawnattr_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_init}

{ Free resources associated with ATTR.  }
function posix_spawnattr_destroy(var __attr: posix_spawnattr_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_destroy}

{ Store signal mask for signals with default handling from ATTR in SIGDEFAULT.  }
function posix_spawnattr_getsigdefault(const __attr: posix_spawnattr_t;
  var __sigdefault: sigset_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_getsigdefault}

{ Set signal mask for signals with default handling in ATTR to SIGDEFAULT.  }
function posix_spawnattr_setsigdefault(var __attr: posix_spawnattr_t;
  const __sigdefault: sigset_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_setsigdefault}

{ Store signal mask for the new process from ATTR in SIGMASK.  }
function posix_spawnattr_getsigmask(const __attr: posix_spawnattr_t;
  var __sigmask: sigset_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_getsigmask}

{ Set signal mask for the new process in ATTR to SIGMASK.  }
function posix_spawnattr_setsigmask(var __attr: posix_spawnattr_t;
  const __sigmask: sigset_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_setsigmask}

{ Get flag word from the attribute structure.  }
function posix_spawnattr_getflags(const __attr: posix_spawnattr_t;
  var __flags: Word): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_getflags}

{ Store flags in the attribute structure.  }
function posix_spawnattr_setflags(var __attr: posix_spawnattr_t;
  __flags: Word): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_setflags}

{ Get process group ID from the attribute structure.  }
function posix_spawnattr_getpgroup(const __attr: posix_spawnattr_t;
  var __pgroup: pid_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_getpgroup}

{ Store process group ID in the attribute structure.  }
function posix_spawnattr_setpgroup(var __attr: posix_spawnattr_t;
  __pgroup: pid_t): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_setpgroup}

{ Get scheduling policy from the attribute structure.  }
function posix_spawnattr_getschedpolicy(const __attr: posix_spawnattr_t;
  var __schedpolicy: Integer): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_getschedpolicy}

{ Store scheduling policy in the attribute structure.  }
function posix_spawnattr_setschedpolicy(var __attr: posix_spawnattr_t;
  __schedpolicy: Integer): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_setschedpolicy}

{ Get scheduling parameters from the attribute structure.  }
function posix_spawnattr_getschedparam(const __attr: posix_spawnattr_t;
  var __schedparam: sched_param): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_getschedparam}

{ Store scheduling parameters in the attribute structure.  }
function posix_spawnattr_setschedparam(var __attr: posix_spawnattr_t;
  const __schedparam: sched_param): Integer; cdecl;
{$EXTERNALSYM posix_spawnattr_setschedparam}


{ Initialize data structure for file attribute for `spawn' call.  }
function posix_spawn_file_actions_init(var __file_actions: posix_spawn_file_actions_t): Integer; cdecl;
{$EXTERNALSYM posix_spawn_file_actions_init}

{ Free resources associated with FILE-ACTIONS.  }
function posix_spawn_file_actions_destroy(var __file_actions: posix_spawn_file_actions_t): Integer; cdecl;
{$EXTERNALSYM posix_spawn_file_actions_destroy}

{ Add an action to FILE-ACTIONS which tells the implementation to call
   `open' for the given file during the `spawn' call.  }
function posix_spawn_file_actions_addopen(var __file_actions: posix_spawn_file_actions_t;
  __fd: Integer; __path: PChar; __oflag: Integer; __mode: mode_t): Integer; cdecl;
{$EXTERNALSYM posix_spawn_file_actions_addopen}

{ Add an action to FILE-ACTIONS which tells the implementation to call
   `close' for the given file descriptor during the `spawn' call.  }
function posix_spawn_file_actions_addclose(var __file_actions: posix_spawn_file_actions_t;
  __fd: Integer): Integer; cdecl;
{$EXTERNALSYM posix_spawn_file_actions_addclose}

{ Add an action to FILE-ACTIONS which tells the implementation to call
   `dup2' for the given file descriptors during the `spawn' call.  }
function posix_spawn_file_actions_adddup2(var __file_actions: posix_spawn_file_actions_t;
  __fd: Integer; __newfd: Integer): Integer; cdecl;
{$EXTERNALSYM posix_spawn_file_actions_adddup2}


// Translated from bits/fcntl.h

{ Get the definitions of O_*, F_*, FD_*: all the
   numbers and flag bits for `open', `fcntl', et al.  }

{ open/fcntl - O_SYNC is only implemented on blocks devices and on files
   located on an ext2 file system }
const
  O_ACCMODE          = $3;
  {$EXTERNALSYM O_ACCMODE}
  O_RDONLY             = 0;
  {$EXTERNALSYM O_RDONLY}
  O_WRONLY             = $1;
  {$EXTERNALSYM O_WRONLY}
  O_RDWR               = $2;
  {$EXTERNALSYM O_RDWR}
  O_CREAT            = $40; { not fcntl }
  {$EXTERNALSYM O_CREAT}
  O_EXCL             = $80; { not fcntl }
  {$EXTERNALSYM O_EXCL}
  O_NOCTTY           = $100; { not fcntl }
  {$EXTERNALSYM O_NOCTTY}
  O_TRUNC           = $200; { not fcntl }
  {$EXTERNALSYM O_TRUNC}
  O_APPEND          = $400;
  {$EXTERNALSYM O_APPEND}
  O_NONBLOCK        = $800;
  {$EXTERNALSYM O_NONBLOCK}
  O_NDELAY        = O_NONBLOCK;
  {$EXTERNALSYM O_NDELAY}
  O_SYNC           = $1000;
  {$EXTERNALSYM O_SYNC}
  O_FSYNC          = O_SYNC;
  {$EXTERNALSYM O_FSYNC}
  O_ASYNC          = $2000;
  {$EXTERNALSYM O_ASYNC}

  O_DIRECT         = $4000; { Direct disk access.  }
  {$EXTERNALSYM O_DIRECT}
  O_DIRECTORY     = $10000; { Must be a directory.  }
  {$EXTERNALSYM O_DIRECTORY}
  O_NOFOLLOW      = $20000; { Do not follow links.  }
  {$EXTERNALSYM O_NOFOLLOW}

{ For now Linux has synchronisity options for data and read operations.
   We define the symbols here but let them do the same as O_SYNC since
   this is a superset.  }

  O_DSYNC         = O_SYNC; { Synchronize data.  }
  {$EXTERNALSYM O_DSYNC}
  O_RSYNC         = O_SYNC; { Synchronize read operations.  }
  {$EXTERNALSYM O_RSYNC}

  O_LARGEFILE     = $8000;
  {$EXTERNALSYM O_LARGEFILE}

{ Values for the second argument to `fcntl'.  }
  F_DUPFD         = 0;      { Duplicate file descriptor.  }
  {$EXTERNALSYM F_DUPFD}
  F_GETFD         = 1;      { Get file descriptor flags.  }
  {$EXTERNALSYM F_GETFD}
  F_SETFD         = 2;      { Set file descriptor flags.  }
  {$EXTERNALSYM F_SETFD}
  F_GETFL         = 3;      { Get file status flags.  }
  {$EXTERNALSYM F_GETFL}
  F_SETFL         = 4;      { Set file status flags.  }
  {$EXTERNALSYM F_SETFL}
  F_GETLK         = 5;      { Get record locking info.  }
  {$EXTERNALSYM F_GETLK}
  F_SETLK         = 6;      { Set record locking info (non-blocking).  }
  {$EXTERNALSYM F_SETLK}
  F_SETLKW        = 7;      { Set record locking info (blocking).  }
  {$EXTERNALSYM F_SETLKW}

  F_GETLK64       = 5;      { Get record locking info.  }
  {$EXTERNALSYM F_GETLK64}
  F_SETLK64       = 6;      { Set record locking info (non-blocking).  }
  {$EXTERNALSYM F_SETLK64}
  F_SETLKW64      = 7;      { Set record locking info (blocking).  }
  {$EXTERNALSYM F_SETLKW64}

  F_SETOWN        = 8;      { Get owner of socket (receiver of SIGIO).  }
  {$EXTERNALSYM F_SETOWN}
  F_GETOWN        = 9;      { Set owner of socket (receiver of SIGIO).  }
  {$EXTERNALSYM F_GETOWN}

  F_SETSIG        = 10;     { Set number of signal to be sent.  }
  {$EXTERNALSYM F_SETSIG}
  F_GETSIG        = 11;     { Get number of signal to be sent.  }
  {$EXTERNALSYM F_GETSIG}

  F_SETLEASE      = 1024;   { Set a lease.	 }
  {$EXTERNALSYM F_SETLEASE}
  F_GETLEASE      = 1025;   { Enquire what lease is active.  }
  {$EXTERNALSYM F_GETLEASE}
  F_NOTIFY        = 1026;   { Request notfications on a directory.	 }
  {$EXTERNALSYM F_NOTIFY}

{ For F_[GET|SET]FL.  }
  FD_CLOEXEC      = 1;      { actually anything with low bit set goes }
  {$EXTERNALSYM FD_CLOEXEC}

{ For posix fcntl() and `l_type' field of a `struct flock' for lockf().  }
  F_RDLCK         = 0;      { Read lock.  }
  {$EXTERNALSYM F_RDLCK}
  F_WRLCK         = 1;      { Write lock.  }
  {$EXTERNALSYM F_WRLCK}
  F_UNLCK         = 2;      { Remove lock.  }
  {$EXTERNALSYM F_UNLCK}

{ For old implementation of bsd flock() }
  F_EXLCK         = 4;      { or 3 }
  {$EXTERNALSYM F_EXLCK}
  F_SHLCK         = 8;      { or 4 }
  {$EXTERNALSYM F_SHLCK}

{ Operations for bsd flock(), also used by the kernel implementation }
  LOCK_SH         = 1;      { shared lock }
  {$EXTERNALSYM LOCK_SH}
  LOCK_EX         = 2;      { exclusive lock }
  {$EXTERNALSYM LOCK_EX}
  LOCK_NB         = 4;      { or'd with one of the above to prevent blocking }
  {$EXTERNALSYM LOCK_NB}
  LOCK_UN         = 8;      { remove lock }
  {$EXTERNALSYM LOCK_UN}

  LOCK_MAND       = 32;     { This is a mandatory flock:	}
  {$EXTERNALSYM LOCK_MAND}
  LOCK_READ       = 64;     { ... which allows concurrent read operations.	 }
  {$EXTERNALSYM LOCK_READ}
  LOCK_WRITE      = 128;    { ... which allows concurrent write operations.  }
  {$EXTERNALSYM LOCK_WRITE}
  LOCK_RW         = 192;    { ... Which allows concurrent read & write operations.	 }
  {$EXTERNALSYM LOCK_RW}

{ Types of directory notifications that may be requested with F_NOTIFY.  }
  DN_ACCESS    = $00000001;     { File accessed.  }
  {$EXTERNALSYM DN_ACCESS}
  DN_MODIFY    = $00000002;     { File modified.  }
  {$EXTERNALSYM DN_MODIFY}
  DN_CREATE    = $00000004;     { File created.  }
  {$EXTERNALSYM DN_CREATE}
  DN_DELETE    = $00000008;     { File removed.  }
  {$EXTERNALSYM DN_DELETE}
  DN_RENAME    = $00000010;     { File renamed.  }
  {$EXTERNALSYM DN_RENAME}
  DN_ATTRIB    = $00000020;     { File changed attibutes.  }
  {$EXTERNALSYM DN_ATTRIB}
  DN_MULTISHOT = $80000000;     { Don't remove notifier.  }
  {$EXTERNALSYM DN_MULTISHOT}

type
  flock = {packed} record
    l_type: Smallint;   { Type of lock: F_RDLCK, F_WRLCK, or F_UNLCK.  }
    l_whence: Smallint; { Where `l_start' is relative to (like `lseek').  }
    l_start: __off_t;   { Offset where the lock begins.  }
    l_len: __off_t;     { Size of the locked area; zero means until EOF.  }
    l_pid: __pid_t;     { Process holding the lock.  }
  end;
  {$EXTERNALSYM flock}
  TFlock = flock;
  PFlock = ^TFlock;

  flock64 = {packed} record
    l_type: Smallint;   { Type of lock: F_RDLCK, F_WRLCK, or F_UNLCK.  }
    l_whence: Smallint; { Where `l_start' is relative to (like `lseek').  }
    l_start: __off64_t; { Offset where the lock begins.  }
    l_len: __off64_t;   { Size of the locked area; zero means until EOF.  }
    l_pid: __pid_t;     { Process holding the lock.  }
  end;
  {$EXTERNALSYM flock64}
  TFlock64 = Flock64;
  PFlock64 = ^TFlock64;

const
{ Define some more compatibility macros to be backward compatible with
   BSD systems which did not managed to hide these kernel macros.  }
  FAPPEND         = O_APPEND;
  {$EXTERNALSYM FAPPEND}
  FFSYNC          = O_FSYNC;
  {$EXTERNALSYM FFSYNC}
  FASYNC          = O_ASYNC;
  {$EXTERNALSYM FASYNC}
  FNONBLOCK       = O_NONBLOCK;
  {$EXTERNALSYM FNONBLOCK}
  FNDELAY         = O_NDELAY;
  {$EXTERNALSYM FNDELAY}

{ Advise to `posix_fadvise'.  }
  POSIX_FADV_NORMAL     = 0;  { No further special treatment.  }
  {$EXTERNALSYM POSIX_FADV_NORMAL}
  POSIX_FADV_RANDOM     = 1;  { Expect random page references.  }
  {$EXTERNALSYM POSIX_FADV_RANDOM}
  POSIX_FADV_SEQUENTIAL = 2;  { Expect sequential page references.	 }
  {$EXTERNALSYM POSIX_FADV_SEQUENTIAL}
  POSIX_FADV_WILLNEED   = 3;  { Will need these pages.  }
  {$EXTERNALSYM POSIX_FADV_WILLNEED}
  POSIX_FADV_DONTNEED   = 4;  { Don't need these pages.  }
  {$EXTERNALSYM POSIX_FADV_DONTNEED}
  POSIX_FADV_NOREUSE    = 5;  { Data will be accessed once.  }
  {$EXTERNALSYM POSIX_FADV_NOREUSE}


// Translated from fcntl.h

(*
  R_OK, W_OK, X_OK, F_OK duplicated from unistd.h - not translated here.
  SEEK_SET, SEEK_CUR, SEEK_END duplicated from stdio.h - not translated here.
*)

{ Do the file control operation described by CMD on FD.
   The remaining arguments are interpreted depending on CMD.  }

function fcntl(Handle: Integer; Command: Integer; var Lock: TFlock): Integer; cdecl; overload;
function fcntl(Handle: Integer; Command: Integer; Arg: Longint): Integer; cdecl; overload;
function fcntl(Handle: Integer; Command: Integer): Integer; cdecl; overload;
{$EXTERNALSYM fcntl}

{ Open FILE and return a new file descriptor for it, or -1 on error.
   OFLAG determines the type of access used.  If O_CREAT is on OFLAG,
   the third argument is taken as a `mode_t', the mode of the created file.  }
function open(PathName: PChar; Flags: Integer): Integer; cdecl; varargs;
{$EXTERNALSYM open}

function open64(PathName: PChar; Flags: Integer): Integer; cdecl; varargs;
{$EXTERNALSYM open64}

{ Create and open FILE, with mode MODE.
   This takes an `int' MODE argument because that is
   what `mode_t' will be widened to.  }

function creat(FileName: PChar; Mode: __mode_t): Integer; cdecl;
{$EXTERNALSYM creat}

function creat64(FileName: PChar; Mode: __mode_t): Integer; cdecl;
{$EXTERNALSYM creat64}

(*
  F_ULOCK, F_LOCK, F_TLOCK, F_TEST duplicated from unistd.h - not translated here.
  lockf, lockf64 duplicated from unistd.h - not translated here.
*)

{ Advise the system about the expected behaviour of the application with
   respect to the file associated with FD.  }
function posix_fadvise(Handle: Integer; __offset: __off_t; __len: size_t; __advise: Integer): Integer; cdecl;
{$EXTERNALSYM posix_fadvise}
function posix_fadvise64(Handle: Integer; __offset: __off64_t; __len: size_t; __advise: Integer): Integer; cdecl;
{$EXTERNALSYM posix_fadvise64}

{ Reserve storage for the data of the file associated with FD.  }
function posix_fallocate(Handle: Integer; __offset: __off_t; __len: size_t): Integer; cdecl;
{$EXTERNALSYM posix_fallocate}
function posix_fallocate64(Handle: Integer; __offset: __off64_t; __len: size_t): Integer; cdecl;
{$EXTERNALSYM posix_fallocate64}


// Translated from sys/file.h

(*
  Constants not translated - already defined elsewhere.
*)

{ Apply or remove an advisory lock, according to OPERATION,
   on the file FD refers to.  }
function __flock(__fd: Integer; __operation: Integer): Integer; cdecl;
{.$EXTERNALSYM flock} // Conflict with type name


// Translated from bits/dirent.h

type
  dirent = {packed} record
    d_ino: __ino_t;
    d_off: __off_t;
    d_reclen: Word;
    d_type: Byte;
    d_name: packed array [0..255] of Char;
  end;
  {$EXTERNALSYM dirent}
  TDirEnt = dirent;
  PDirEnt = ^TDirEnt;
  PPDirEnt = ^PDirEnt;

  dirent64 = {packed} record
    d_ino: __ino64_t;
    d_off: __off64_t;
    d_reclen: Word;
    d_type: Byte;
    d_name: packed array[0..255] of Char;
  end;
  {$EXTERNALSYM dirent64}
  TDirEnt64 = dirent64;
  PDirEnt64 = ^TDirEnt64;
  PPDirEnt64 = ^PDirEnt64;


// Translated from dirent.h

{ File types for `d_type'.  }
const
  DT_UNKNOWN   = 0;
  {$EXTERNALSYM DT_UNKNOWN}
  DT_FIFO   = 1;
  {$EXTERNALSYM DT_FIFO}
  DT_CHR   = 2;
  {$EXTERNALSYM DT_CHR}
  DT_DIR   = 4;
  {$EXTERNALSYM DT_DIR}
  DT_BLK   = 6;
  {$EXTERNALSYM DT_BLK}
  DT_REG   = 8;
  {$EXTERNALSYM DT_REG}
  DT_LNK   = 10;
  {$EXTERNALSYM DT_LNK}
  DT_SOCK   = 12;
  {$EXTERNALSYM DT_SOCK}
  DT_WHT    =14;
  {$EXTERNALSYM DT_WHT}

{ Convert between stat structure types and directory types.  }
function IFTODT(mode: __mode_t): Integer;
{$EXTERNALSYM IFTODT}
function DTTOIF(dirtype: Integer): __mode_t;
{$EXTERNALSYM DTTOIF}

{ This is the data type of directory stream objects.
   The actual structure is opaque to users.  }
type
  __dirstream = {packed} record end; // Opaque record.
  {$EXTERNALSYM __dirstream}
  DIR = __dirstream;
  {$EXTERNALSYM DIR}
  TDirectoryStream = DIR;
  PDirectoryStream = ^TDirectoryStream;

{ Open a directory stream on NAME.
   Return a DIR stream on the directory, or NULL if it could not be opened.  }
function opendir(PathName: PChar): PDirectoryStream; cdecl;
{$EXTERNALSYM opendir}

{ Close the directory stream DIRP.
   Return 0 if successful, -1 if not.  }
function closedir(Handle: PDirectoryStream): Integer; cdecl;
{$EXTERNALSYM closedir}

{ Read a directory entry from DIRP.  Return a pointer to a `struct
   dirent' describing the entry, or NULL for EOF or error.  The
   storage returned may be overwritten by a later readdir call on the
   same DIR stream.

   If the Large File Support API is selected we have to use the
   appropriate interface.  }

function readdir(Handle: PDirectoryStream): PDirent; cdecl;
{$EXTERNALSYM readdir}

function readdir64(Handle: PDirectoryStream): PDirent64; cdecl;
{$EXTERNALSYM readdir64}

{ Reentrant version of `readdir'.  Return in RESULT a pointer to the
   next entry.  }
function readdir_r(Handle: PDirectoryStream; Entry: PDirent;
  var __result: PDirEnt): Integer; cdecl;
{$EXTERNALSYM readdir_r}

function readdir64_r(Handle: PDirectoryStream; Entry: PDirEnt64;
  var __result: PDirEnt64): Integer; cdecl;
{$EXTERNALSYM readdir64_r}

{ Rewind DIRP to the beginning of the directory.  }
procedure rewinddir(Handle: PDirectoryStream); cdecl;
{$EXTERNALSYM rewinddir}

{ Seek to position POS on DIRP.  }
procedure seekdir(Handle: PDirectoryStream; Position: Longint); cdecl;
{$EXTERNALSYM seekdir}

{ Return the current position of DIRP.  }
function telldir(Handle: PDirectoryStream): Longint; cdecl;
{$EXTERNALSYM telldir}

{ Return the file descriptor used by DIRP.  }
function dirfd(Handle: PDirectoryStream): Integer; cdecl;
{$EXTERNALSYM dirfd}

{ Get the definitions of the POSIX.1 limits.  }

const
  MAXNAMLEN       = 255;
  {$EXTERNALSYM MAXNAMLEN}

type
  // Not in header file - used anonymously.
  TSelectorProc = function(const p1: PDirEnt): Integer; cdecl;
  TSelectorProc64 = function(const p1: PDirEnt64): Integer; cdecl;
  TCompareProc = function(const p1, p2: Pointer): Integer; cdecl;

function scandir(PathName: PChar; var NameList: PPdirent; SelProc: TSelectorProc;
  CmpProc: TCompareProc): Integer; cdecl;
{$EXTERNALSYM scandir}

{ This function is like `scandir' but it uses the 64bit dirent structure.
   Please note that the CMP function must now work with struct dirent64 **.  }
function scandir64(PathName: PChar; var NameList: PPdirent64; SelProc: TSelectorProc64;
  CmpProc: TCompareProc): Integer; cdecl;
{$EXTERNALSYM scandir64}

function alphasort(const e1: Pointer; const e2: Pointer): Integer; cdecl;
{$EXTERNALSYM alphasort}

function alphasort64(const e1: Pointer; const e2: Pointer): Integer; cdecl;
{$EXTERNALSYM alphasort64}

function versionsort(const e1: Pointer; const e2: Pointer): Integer; cdecl;
{$EXTERNALSYM versionsort}

function versionsort64(const e1: Pointer; const e2: Pointer): Integer; cdecl;
{$EXTERNALSYM versionsort64}

{ Read directory entries from FD into BUF, reading at most NBYTES.
   Reading starts at offset *BASEP, and *BASEP is updated with the new
   position after reading.  Returns the number of bytes read; zero when at
   end of directory; or -1 for errors.  }
function getdirentries(FileDes: Integer; Buf: PChar; NBytes: size_t;
  var __basep: __off_t): __ssize_t; cdecl;
{$EXTERNALSYM getdirentries}

function getdirentries64(FileDes: Integer; Buf: PChar; NBytes: size_t;
  var __basep: __off64_t): __ssize_t; cdecl;
{$EXTERNALSYM getdirentries64}

// Translated from bits/stat.h

{ Versions of the `struct stat' data structure.  }
const
  _STAT_VER_LINUX_OLD     = 1;
  {$EXTERNALSYM _STAT_VER_LINUX_OLD}
  _STAT_VER_KERNEL        = 1;
  {$EXTERNALSYM _STAT_VER_KERNEL}
  _STAT_VER_SVR4          = 2;
  {$EXTERNALSYM _STAT_VER_SVR4}
  _STAT_VER_LINUX         = 3;
  {$EXTERNALSYM _STAT_VER_LINUX}
  _STAT_VER               = _STAT_VER_LINUX; { The one defined below.  }
  {$EXTERNALSYM _STAT_VER}

{ Versions of the `xmknod' interface.  }
  _MKNOD_VER_LINUX        = 1;
  {$EXTERNALSYM _MKNOD_VER_LINUX}
  _MKNOD_VER_SVR4         = 2;
  {$EXTERNALSYM _MKNOD_VER_SVR4}
  _MKNOD_VER              = _MKNOD_VER_LINUX; { The bits defined below.  }
  {$EXTERNALSYM _MKNOD_VER}


type
  _stat = {packed} record
    st_dev: __dev_t;                    { Device.  }
    __pad1: Word;
    st_ino: __ino_t;                    { File serial number.	 }
    st_mode: __mode_t;                  { File mode.  }
    st_nlink: __nlink_t;                { Link count.  }
    st_uid: __uid_t;                    { User ID of the file's owner.	 }
    st_gid: __gid_t;                    { Group ID of the file's group. }
    st_rdev: __dev_t;                   { Device number, if device.  }
    __pad2: Word;
    st_size: __off_t;                   { Size of file, in bytes.  }
    st_blksize: __blksize_t;            { Optimal block size for I/O.  }
    st_blocks: __blkcnt_t;              { Number 512-byte blocks allocated. }
    st_atime: __time_t;                 { Time of last access.  }
    __unused1: LongWord;
    st_mtime: __time_t;                 { Time of last modification.  }
    __unused2: LongWord;
    st_ctime: __time_t;                 { Time of last status change.  }
    __unused3: LongWord;
    __unused4: LongWord;
    __unused5: LongWord;
  end;
  {.$EXTERNALSYM stat} // Renamed due to conflict with stat function
  TStatBuf = _stat;
  PStatBuf = ^TStatBuf;


  _stat64 = {packed} record
    st_dev: __dev_t;                    { Device.  }
    __pad1: Word;
    __st_ino: __ino_t;                  { 32bit file serial number.	 }
    st_mode: __mode_t;                  { File mode.  }
    st_nlink: __nlink_t;                { Link count.  }
    st_uid: __uid_t;                    { User ID of the file's owner.	 }
    st_gid: __gid_t;                    { Group ID of the file's group. }
    st_rdev: __dev_t;                   { Device number, if device.  }
    __pad2: Word;
    st_size: __off64_t;                 { Size of file, in bytes.  }
    st_blksize: __blksize_t;            { Optimal block size for I/O.  }
    st_blocks: __blkcnt64_t;            { Number 512-byte blocks allocated. }
    st_atime: __time_t;                 { Time of last access.  }
    __unused1: LongWord;
    st_mtime: __time_t;                 { Time of last modification.  }
    __unused2: LongWord;
    st_ctime: __time_t;                 { Time of last status change.  }
    __unused3: LongWord;
    st_ino: __ino64_t;                  { File serial number.		}
  end;
  {.$EXTERNALSYM stat64} // Renamed due to conflict with stat64 function
  TStatBuf64 = _stat64;
  PStatBuf64 = ^TStatBuf64;

const
{ Encoding of the file mode.  }
  __S_IFMT        = $F000;  { These bits determine file type.  }
  {$EXTERNALSYM __S_IFMT}

  { File types.  }
  __S_IFDIR       = $4000;  { Directory.  }
  {$EXTERNALSYM __S_IFDIR}
  __S_IFCHR       = $2000;  { Character device.  }
  {$EXTERNALSYM __S_IFCHR}
  __S_IFBLK       = $6000;  { Block device.  }
  {$EXTERNALSYM __S_IFBLK}
  __S_IFREG       = $8000;  { Regular file.  }
  {$EXTERNALSYM __S_IFREG}
  __S_IFIFO       = $1000;  { FIFO.  }
  {$EXTERNALSYM __S_IFIFO}
  __S_IFLNK       = $A000;  { Symbolic link.  }
  {$EXTERNALSYM __S_IFLNK}
  __S_IFSOCK      = $C000;  { Socket.  }
  {$EXTERNALSYM __S_IFSOCK}

(* // Cannot be translated.
{ POSIX.1b objects.  }
  __S_TYPEISMQ(buf) (0)
  __S_TYPEISSEM(buf) (0)
  __S_TYPEISSHM(buf) (0)
*)

{ Protection bits.  }
  __S_ISUID       = $800;   { Set user ID on execution.  }
  {$EXTERNALSYM __S_ISUID}
  __S_ISGID       = $400;   { Set group ID on execution.  }
  {$EXTERNALSYM __S_ISGID}
  __S_ISVTX       = $200;   { Save swapped text after use (sticky).  }
  {$EXTERNALSYM __S_ISVTX}
  __S_IREAD       = $100;   { Read by owner.  }
  {$EXTERNALSYM __S_IREAD}
  __S_IWRITE      = $80;    { Write by owner.  }
  {$EXTERNALSYM __S_IWRITE}
  __S_IEXEC       = $40;    { Execute by owner.  }
  {$EXTERNALSYM __S_IEXEC}


// Translated from sys/stat.h

const
  S_IFMT          = __S_IFMT;
  {$EXTERNALSYM S_IFMT}
  S_IFDIR         = __S_IFDIR;
  {$EXTERNALSYM S_IFDIR}
  S_IFCHR         = __S_IFCHR;
  {$EXTERNALSYM S_IFCHR}
  S_IFBLK         = __S_IFBLK;
  {$EXTERNALSYM S_IFBLK}
  S_IFREG         = __S_IFREG;
  {$EXTERNALSYM S_IFREG}
  S_IFIFO         = __S_IFIFO;
  {$EXTERNALSYM S_IFIFO}
  S_IFLNK         = __S_IFLNK;
  {$EXTERNALSYM S_IFLNK}
  S_IFSOCK        = __S_IFSOCK;
  {$EXTERNALSYM S_IFSOCK}

{ Test macros for file types.	}

function __S_ISTYPE(mode, mask: __mode_t): Boolean;
{$EXTERNALSYM __S_ISTYPE}

function S_ISDIR(mode: __mode_t): Boolean;
{$EXTERNALSYM S_ISDIR}
function S_ISCHR(mode: __mode_t): Boolean;
{$EXTERNALSYM S_ISCHR}
function S_ISBLK(mode: __mode_t): Boolean;
{$EXTERNALSYM S_ISBLK}
function S_ISREG(mode: __mode_t): Boolean;
{$EXTERNALSYM S_ISREG}
function S_ISFIFO(mode: __mode_t): Boolean;
{$EXTERNALSYM S_ISFIFO}

function S_ISLNK(mode: __mode_t): Boolean;
{$EXTERNALSYM S_ISLNK}

function S_ISSOCK(mode: __mode_t): Boolean;
{$EXTERNALSYM S_ISSOCK}

(* Cannot be translated.
{ These are from POSIX.1b.  If the objects are not implemented using separate
   distinct file types, the macros always will evaluate to zero.  Unlike the
   other S_* macros the following three take a pointer to a `struct stat'
   object as the argument.  }
#ifdef	__USE_POSIX199309
# define S_TYPEISMQ(buf) __S_TYPEISMQ(buf)
# define S_TYPEISSEM(buf) __S_TYPEISSEM(buf)
# define S_TYPEISSHM(buf) __S_TYPEISSHM(buf)
#endif
*)

const
  { Protection bits.  }

  S_ISUID = __S_ISUID;      { Set user ID on execution.  }
  {$EXTERNALSYM S_ISUID}
  S_ISGID = __S_ISGID;      { Set group ID on execution.  }
  {$EXTERNALSYM S_ISGID}

  { Save swapped text after use (sticky bit).  This is pretty well obsolete.  }
  S_ISVTX         = __S_ISVTX;
  {$EXTERNALSYM S_ISVTX}

  S_IRUSR = __S_IREAD;      { Read by owner.  }
  {$EXTERNALSYM S_IRUSR}
  S_IWUSR = __S_IWRITE;     { Write by owner.  }
  {$EXTERNALSYM S_IWUSR}
  S_IXUSR = __S_IEXEC;      { Execute by owner.  }
  {$EXTERNALSYM S_IXUSR}
  { Read, write, and execute by owner.  }
  S_IRWXU = __S_IREAD or __S_IWRITE or __S_IEXEC;
  {$EXTERNALSYM S_IRWXU}

  S_IREAD         = S_IRUSR;
  {$EXTERNALSYM S_IREAD}
  S_IWRITE        = S_IWUSR;
  {$EXTERNALSYM S_IWRITE}
  S_IEXEC         = S_IXUSR;
  {$EXTERNALSYM S_IEXEC}

  S_IRGRP = S_IRUSR shr 3;  { Read by group.  }
  {$EXTERNALSYM S_IRGRP}
  S_IWGRP = S_IWUSR shr 3;  { Write by group.  }
  {$EXTERNALSYM S_IWGRP}
  S_IXGRP = S_IXUSR shr 3;  { Execute by group.  }
  {$EXTERNALSYM S_IXGRP}
  { Read, write, and execute by group.  }
  S_IRWXG = S_IRWXU shr 3;
  {$EXTERNALSYM S_IRWXG}

  S_IROTH = S_IRGRP shr 3;  { Read by others.  }
  {$EXTERNALSYM S_IROTH}
  S_IWOTH = S_IWGRP shr 3;  { Write by others.  }
  {$EXTERNALSYM S_IWOTH}
  S_IXOTH = S_IXGRP shr 3;  { Execute by others.  }
  {$EXTERNALSYM S_IXOTH}
  { Read, write, and execute by others.  }
  S_IRWXO = S_IRWXG shr 3;
  {$EXTERNALSYM S_IRWXO}

  { Macros for common mode bit masks.  }
  ACCESSPERMS  = S_IRWXU or S_IRWXG or S_IRWXO; { 0777 }
  {$EXTERNALSYM ACCESSPERMS}
  ALLPERMS  = S_ISUID or S_ISGID or S_ISVTX or S_IRWXU or S_IRWXG or S_IRWXO; { 07777 }
  {$EXTERNALSYM ALLPERMS}
  DEFFILEMODE  = S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP or S_IROTH or S_IWOTH; { 0666 }
  {$EXTERNALSYM DEFFILEMODE}

  S_BLKSIZE       = 512;    { Block size for `st_blocks'.  }
  {$EXTERNALSYM S_BLKSIZE}


{ Get file attributes for FileName and put them in BUF.  }
function stat(FileName: PChar; var StatBuffer: TStatBuf): Integer; cdecl;
{$EXTERNALSYM stat}

{ Get file attributes for the file, device, pipe, or socket
   that file descriptor FD is open on and put them in BUF.  }
function fstat(FileDes: Integer; var StatBuffer: TStatBuf): Integer; cdecl;
{$EXTERNALSYM fstat}

function stat64(FileName: PChar; var StatBuffer: TStatBuf64): Integer; cdecl;
{$EXTERNALSYM stat64}

function fstat64(FileDes: Integer; var StatBuffer: TStatBuf64): Integer; cdecl;
{$EXTERNALSYM fstat64}

{ Get file attributes about FileName and put them in BUF.
   If FileName is a symbolic link, do not follow it.  }
function lstat(FileName: PChar; var StatBuffer: TStatBuf): Integer; cdecl;
{$EXTERNALSYM lstat}

function lstat64(FileName: PChar; var StatBuffer: TStatBuf64): Integer; cdecl;
{$EXTERNALSYM lstat64}

{ Set file access permissions for FileName to MODE.
   This takes an `int' MODE argument because that
   is what `mode_t's get widened to.  }
function chmod(FileName: PChar; Mode: __mode_t): Integer; cdecl;
{$EXTERNALSYM chmod}

{ Set file access permissions of the file FD is open on to MODE.  }
function fchmod(FileDes: Integer; Mode: __mode_t): Integer; cdecl;
{$EXTERNALSYM fchmod}


{ Set the file creation mask of the current process to MASK,
   and return the old creation mask.  }
function umask(Mask: __mode_t): LongWord; cdecl;
{$EXTERNALSYM umask}

{ Create a new directory named PATH, with permission bits MODE.  }
// HTI - Renamed from "mkdir" to "__mkdir"
function __mkdir(PathName: PChar; Mode: __mode_t): Integer; cdecl;
{.$EXTERNALSYM mkdir} // Renamed

{ Create a device file named PATH, with permission and special bits MODE
   and device number DEV (which can be constructed from major and minor
   device numbers with the `makedev' macro above).  }
function mknod(Pathname: PChar; Mode: __mode_t; Device: __dev_t): Integer; cdecl;
{$EXTERNALSYM mknod}


{ Create a new FIFO named PATH, with permission bits MODE.  }
function mkfifo(PathName: PChar; Mode: __mode_t): Integer; cdecl;
{$EXTERNALSYM mkfifo}

{ To allow the `struct stat' structure and the file type `mode_t'
   bits to vary without changing shared library major version number,
   the `stat' family of functions and `mknod' are in fact inline
   wrappers around calls to `xstat', `fxstat', `lxstat', and `xmknod',
   which all take a leading version-number argument designating the
   data structure and bits used.  <bits/stat.h> defines _STAT_VER with
   the version number corresponding to `struct stat' as defined in
   that file; and _MKNOD_VER with the version number corresponding to
   the S_IF* macros defined therein.  It is arranged that when not
   inlined these function are always statically linked; that way a
   dynamically-linked executable always encodes the version number
   corresponding to the data structures it uses, so the `x' functions
   in the shared library can adapt without needing to recompile all
   callers.  }

{ Wrappers for stat and mknod system calls.  }

function __fxstat(Ver: Integer; FileDes: Integer; var StatBuffer: TStatBuf): Integer; cdecl;
{$EXTERNALSYM __fxstat}

function __xstat(Ver: Integer; FileName: PChar; var StatBuffer: TStatBuf): Integer; cdecl;
{$EXTERNALSYM __xstat}

function __lxstat(Ver: Integer; FileName: PChar; var StatBuffer: TStatBuf): Integer; cdecl;
{$EXTERNALSYM __lxstat}

function __fxstat64(Ver: Integer; FileDes: Integer; var StatBuffer: TStatBuf64): Integer; cdecl;
{$EXTERNALSYM __fxstat64}

function __xstat64(Ver: Integer; FileName: PChar; var StatBuffer: TStatBuf64): Integer; cdecl;
{$EXTERNALSYM __xstat64}

function __lxstat64(Ver: Integer; FileName: PChar; var StatBuffer: TStatBuf64): Integer; cdecl;
{$EXTERNALSYM __lxstat64}

function __xmknod(Ver: Integer; Pathname: PChar; Mode: __mode_t; var Device: __dev_t): Integer; cdecl;
{$EXTERNALSYM __xmknod}


// Translated from fnmatch.h

const

{ Bits set in the FLAGS argument to `fnmatch'.  }
  FNM_PATHNAME    = 1 shl 0; { No wildcard can ever match `/'.  }
  {$EXTERNALSYM FNM_PATHNAME}
  FNM_NOESCAPE    = 1 shl 1; { Backslashes don't quote special chars.  }
  {$EXTERNALSYM FNM_NOESCAPE}
  FNM_PERIOD      = 1 shl 2; { Leading `.' is matched only explicitly.  }
  {$EXTERNALSYM FNM_PERIOD}

  FNM_FILE_NAME    = FNM_PATHNAME;  { Preferred GNU name.  }
  {$EXTERNALSYM FNM_FILE_NAME}
  FNM_LEADING_DIR  = 1 shl 3;       { Ignore `/...' after a match.  }
  {$EXTERNALSYM FNM_LEADING_DIR}
  FNM_CASEFOLD     = 1 shl 4;       { Compare without regard to case.  }
  {$EXTERNALSYM FNM_CASEFOLD}

{ Value returned by `fnmatch' if STRING does not match PATTERN.  }
  FNM_NOMATCH     = 1;
  {$EXTERNALSYM FNM_NOMATCH}

{ This value is returned if the implementation does not support
   `fnmatch'.  Since this is not the case here it will never be
   returned but the conformance test suites still require the symbol
   to be defined.  }
  FNM_NOSYS       = -1;
  {$EXTERNALSYM FNM_NOSYS}

{ Match STRING against the filename pattern PATTERN,
   returning zero if it matches, FNM_NOMATCH if not.  }
function fnmatch(Pattern: PChar; FName: PChar; Flags: Integer): Integer; cdecl;
{$EXTERNALSYM fnmatch}


(*
  Moved from _G_config.h
*)
type
{ Integral type unchanged by default argument promotions that can
   hold any value corresponding to members of the extended character
   set, as well as at least one value that does not correspond to any
   member of the extended character set.  }
  wint_t = Cardinal;
  {$EXTERNALSYM wint_t}

(*
  Moved from wchar.h
*)
type
  __mbstate_t = {packed} record
    count: Integer;              { Number of bytes needed for the current character. }
    case { __value } Integer of  { Value so far.  }
      0: (__wch: wint_t);
      1: (__wchb: packed array[0..4 - 1] of Char);
    end;
  {$EXTERNALSYM __mbstate_t}
  mbstate_t = __mbstate_t;
  {$EXTERNALSYM mbstate_t}
  TMultiByteState = __mbstate_t;
  PMultiByteState = ^TMultiByteState;


// Translated from gconv.h

{ This header provides no interface for a user to the internals of
   the gconv implementation in the libc.  Therefore there is no use
   for these definitions beside for writing additional gconv modules.  }

const
{ ISO 10646 value used to signal invalid value.  }
  __UNKNOWN_10646_CHAR = wchar_t($fffd);
  {$EXTERNALSYM __UNKNOWN_10646_CHAR}

{ Error codes for gconv functions.  }

  __GCONV_OK = 0;
  {$EXTERNALSYM __GCONV_OK}
  __GCONV_NOCONV = 1;
  {$EXTERNALSYM __GCONV_NOCONV}
  __GCONV_NODB = 2;
  {$EXTERNALSYM __GCONV_NODB}
  __GCONV_NOMEM = 3;
  {$EXTERNALSYM __GCONV_NOMEM}

  __GCONV_EMPTY_INPUT = 4;
  {$EXTERNALSYM __GCONV_EMPTY_INPUT}
  __GCONV_FULL_OUTPUT = 5;
  {$EXTERNALSYM __GCONV_FULL_OUTPUT}
  __GCONV_ILLEGAL_INPUT = 6;
  {$EXTERNALSYM __GCONV_ILLEGAL_INPUT}
  __GCONV_INCOMPLETE_INPUT = 7;
  {$EXTERNALSYM __GCONV_INCOMPLETE_INPUT}

  __GCONV_ILLEGAL_DESCRIPTOR = 8;
  {$EXTERNALSYM __GCONV_ILLEGAL_DESCRIPTOR}
  __GCONV_INTERNAL_ERROR = 9;
  {$EXTERNALSYM __GCONV_INTERNAL_ERROR}


{ Flags the `__gconv_open' function can set.  }

  __GCONV_IS_LAST = $0001;
  {$EXTERNALSYM __GCONV_IS_LAST}
  __GCONV_IGNORE_ERRORS = $0002;
  {$EXTERNALSYM __GCONV_IGNORE_ERRORS}

{ Forward declarations.  }
type
  PGConvStep = ^TGConvStep;
  PGConvStepData = ^TGConvStepData;
//  PGConvLoadedObject = ^TGConvLoadedObject;
  PGConvTransData = ^TGConvTransData;

{ Type of a conversion function.  }
  __gconv_fct = function(p1: PGConvStep; p2: PGConvStepData; p3: PPChar;
    p4: PChar; var p5: PByte; var p6: size_t; p7: Integer; p8: Integer): Integer; cdecl;
  {$EXTERNALSYM __gconv_fct}

{ Constructor and destructor for local data for conversion step.  }
  __gconv_init_fct = function(p1: PGConvStep): Integer; cdecl;
  {$EXTERNALSYM __gconv_init_fct}
  __gconv_end_fct = procedure(p1: PGConvStep); cdecl;
  {$EXTERNALSYM __gconv_end_fct}

{ Type of a transliteration/transscription function.  }
  __gconv_trans_fct = function(p1: PGConvStep; p2: PGConvStepData; p3: Pointer;
    p4: PByte; p5: PPChar; p6: PByte; var p7: PByte; var p8: size_t): Integer; cdecl;
  {$EXTERNALSYM __gconv_trans_fct}

{ Function to call to provide transliteration module with context.  }
  __gconv_trans_context_fct = function(p1: Pointer; p2: PByte; p3: PByte;
    p4: PByte; p5: PByte): Integer; cdecl;
  {$EXTERNALSYM __gconv_trans_context_fct}

{ Function to query module about supported encoded character sets.  }
  __gconv_trans_query_fct = function(p1: PChar; var p2: PPChar; var p3: size_t): Integer; cdecl;
  {$EXTERNALSYM __gconv_trans_query_fct}

{ Constructor and destructor for local data for transliteration.  }
  __gconv_trans_init_fct = function(var p1: Pointer; p2: PChar): Integer; cdecl;
  {$EXTERNALSYM __gconv_trans_init_fct}
  __gconv_trans_end_fct = procedure(p1: Pointer); cdecl;
  {$EXTERNALSYM __gconv_trans_end_fct}

  __gconv_trans_data = {packed} record
    { Transliteration/Transscription function.  }
    __trans_fct: __gconv_trans_fct;
    __trans_context_fct: __gconv_trans_context_fct;
    __trans_end_fct: __gconv_trans_end_fct;
    __data: Pointer;
    __next: PGConvTransData;
  end;
  {$EXTERNALSYM __gconv_trans_data}
  TGConvTransData = __gconv_trans_data;

{ Description of a conversion step.  }
  __gconv_step = {packed} record
    __shlib_handle: Pointer; // PGConvLoadedObject;
    __modname: PChar;

    __counter: Integer;

    __from_name: PChar;
    __to_name: PChar;

    __fct: __gconv_fct;
    __init_fct: __gconv_init_fct;
    __end_fct: __gconv_end_fct;

    { Information about the number of bytes needed or produced in this
       step.  This helps optimizing the buffer sizes.  }
    __min_needed_from: Integer;
    __max_needed_from: Integer;
    __min_needed_to: Integer;
    __max_needed_to: Integer;

    { Flag whether this is a stateful encoding or not.  }
    __stateful: Integer;

    __data: Pointer; { Pointer to step-local data.  }
  end;
  {$EXTERNALSYM __gconv_step}
  TGConvStep = __gconv_step;

{ Additional data for steps in use of conversion descriptor.  This is
   allocated by the `init' function.  }
  __gconv_step_data = {packed} record
    __outbuf: PByte;    { Output buffer for this step.  }
    __outbufend: PByte; { Address of first byte after the output buffer.  }

    { Is this the last module in the chain.  }
    __flags: Integer;

    { Counter for number of invocations of the module function for this descriptor.  }
    __invocation_counter: Integer;

    { Flag whether this is an internal use of the module (in the mb*towc*
       and wc*tomb* functions) or regular with iconv(3).  }
    __internal_use: Integer;

    __statep: PMultiByteState;
    __state: TMultiByteState;   { This element must not be used directly by
                                  any module; always use STATEP!  }

    { Transliteration information.  }
    __trans: PGConvTransData;
  end;
  {$EXTERNALSYM __gconv_step_data}
  TGConvStepData = __gconv_step_data;


{ Combine conversion step description with data.  }
  __gconv_info = {packed} record
    __nsteps: size_t;
    __steps: PGConvStep;
    (*
      Cannot be translated
        __extension__ struct __gconv_step_data __data[0];
    *)
  end;
  {$EXTERNALSYM __gconv_info}
  __gconv_t = ^__gconv_info;
  {$EXTERNALSYM __gconv_t}
  TGConvInfo = __gconv_info;


// Translated from _G_config.h

(*
  Moved up to resolved dependency

{ Integral type unchanged by default argument promotions that can
   hold any value corresponding to members of the extended character
   set, as well as at least one value that does not correspond to any
   member of the extended character set.  }
  wint_t = Cardinal;
  {$EXTERNALSYM wint_t}
*)

type
  _G_size_t       = size_t;
  {$EXTERNALSYM _G_size_t}
  _G_fpos_t = {packed} record
    __pos: __off_t;
    __state: __mbstate_t;
  end;
  {$EXTERNALSYM _G_fpos_t}
  _G_fpos64_t = {packed} record
    __pos: __off64_t;
    __state: __mbstate_t;
  end;
  {$EXTERNALSYM _G_fpos64_t}
  _G_ssize_t      = __ssize_t;
  {$EXTERNALSYM _G_ssize_t}
  _G_off_t        = __off_t;
  {$EXTERNALSYM _G_off_t}
  _G_off64_t      = Int64;
  {$EXTERNALSYM _G_off64_t}
  _G_pid_t        = __pid_t;
  {$EXTERNALSYM _G_pid_t}
  _G_uid_t        = __uid_t;
  {$EXTERNALSYM _G_uid_t}
  _G_wchar_t      = wchar_t;
  {$EXTERNALSYM _G_wchar_t}
  _G_wint_t       = Cardinal; // wint_t
  {$EXTERNALSYM _G_wint_t}
  _G_stat64       = _stat64; // struct stat64
  {$EXTERNALSYM _G_stat64}


  _G_iconv_t = {packed} record
    case Integer of
      0: (__cd: __gconv_info);
      1: (__combined: {packed} record
                        __cd: __gconv_info;
                        __data: __gconv_step_data;
                      end);
  end;
  {$EXTERNALSYM _G_iconv_t}

  _G_int16_t = Integer;
  {$EXTERNALSYM _G_int16_t}
  _G_int32_t = Integer;
  {$EXTERNALSYM _G_int32_t}
  _G_uint16_t = Cardinal;
  {$EXTERNALSYM _G_uint16_t}
  _G_uint32_t = Cardinal;
  {$EXTERNALSYM _G_uint32_t}

  _G_va_list = Pointer;
  {$EXTERNALSYM _G_va_list}

  
const
  _G_IO_IO_FILE_VERSION = $20001;
  {$EXTERNALSYM _G_IO_IO_FILE_VERSION}

  _G_BUFSIZ = 8192;
  {$EXTERNALSYM _G_BUFSIZ}

(*
  Next to impossible to translate _G_OPEN64, hence _G_LSEEK64 and
  _G_FSTAT64 not translated either.
*)

// Translated from libio.h

type
  _IO_pos_t = _G_fpos_t; { obsolete }
  {$EXTERNALSYM _IO_pos_t}
  _IO_fpos_t = _G_fpos_t;
  {$EXTERNALSYM _IO_fpos_t}
  _IO_fpos64_t = _G_fpos64_t;
  {$EXTERNALSYM _IO_fpos64_t}
  _IO_size_t = _G_size_t;
  {$EXTERNALSYM _IO_size_t}
  _IO_ssize_t = _G_ssize_t;
  {$EXTERNALSYM _IO_ssize_t}
  _IO_off_t = _G_off_t;
  {$EXTERNALSYM _IO_off_t}
  _IO_off64_t = _G_off64_t;
  {$EXTERNALSYM _IO_off64_t}
  
    P_IO_off64_t = ^_IO_off64_t;

  _IO_pid_t = _G_pid_t;
  {$EXTERNALSYM _IO_pid_t}
  _IO_uid_t = _G_uid_t;
  {$EXTERNALSYM _IO_uid_t}
  _IO_iconv_t = _G_iconv_t;
  {$EXTERNALSYM _IO_iconv_t}
  _IO_va_list = _G_va_list;
  {$EXTERNALSYM _IO_va_list}
  _IO_wint_t = _G_wint_t;
  {$EXTERNALSYM _IO_wint_t}

  
const
  _IO_BUFSIZ = _G_BUFSIZ;
  {$EXTERNALSYM _IO_BUFSIZ}

  __EOF  = -1;
  {$EXTERNALSYM __EOF}
  _IOS_INPUT      = 1;
  {$EXTERNALSYM _IOS_INPUT}
  _IOS_OUTPUT     = 2;
  {$EXTERNALSYM _IOS_OUTPUT}
  _IOS_ATEND      = 4;
  {$EXTERNALSYM _IOS_ATEND}
  _IOS_APPEND     = 8;
  {$EXTERNALSYM _IOS_APPEND}
  _IOS_TRUNC      = 16;
  {$EXTERNALSYM _IOS_TRUNC}
  _IOS_NOCREATE   = 32;
  {$EXTERNALSYM _IOS_NOCREATE}
  _IOS_NOREPLACE  = 64;
  {$EXTERNALSYM _IOS_NOREPLACE}
  _IOS_BIN        = 128;
  {$EXTERNALSYM _IOS_BIN}

{ Magic numbers and bits for the _flags field.
   The magic numbers use the high-order bits of _flags;
   the remaining bits are available for variable flags.
   Note: The magic numbers must all be negative if stdio
   emulation is desired. }

  _IO_MAGIC = $FBAD0000; { Magic number }
  {$EXTERNALSYM _IO_MAGIC}
  _OLD_STDIO_MAGIC = $FABC0000; { Emulate old stdio. }
  {$EXTERNALSYM _OLD_STDIO_MAGIC}
  _IO_MAGIC_MASK = $FFFF0000;
  {$EXTERNALSYM _IO_MAGIC_MASK}
  _IO_USER_BUF = 1; { User owns buffer; don't delete it on close. }
  {$EXTERNALSYM _IO_USER_BUF}
  _IO_UNBUFFERED = 2;
  {$EXTERNALSYM _IO_UNBUFFERED}
  _IO_NO_READS = 4; { Reading not allowed }
  {$EXTERNALSYM _IO_NO_READS}
  _IO_NO_WRITES = 8; { Writing not allowd }
  {$EXTERNALSYM _IO_NO_WRITES}
  _IO_EOF_SEEN = $10;
  {$EXTERNALSYM _IO_EOF_SEEN}
  _IO_ERR_SEEN = $20;
  {$EXTERNALSYM _IO_ERR_SEEN}
  _IO_DELETE_DONT_CLOSE = $40; { Don't call close(_fileno) on cleanup. }
  {$EXTERNALSYM _IO_DELETE_DONT_CLOSE}
  _IO_LINKED = $80; { Set if linked (using _chain) to streambuf::_list_all. }
  {$EXTERNALSYM _IO_LINKED}
  _IO_IN_BACKUP = $100;
  {$EXTERNALSYM _IO_IN_BACKUP}
  _IO_LINE_BUF = $200;
  {$EXTERNALSYM _IO_LINE_BUF}
  _IO_TIED_PUT_GET = $400; { Set if put and get pointer logicly tied. }
  {$EXTERNALSYM _IO_TIED_PUT_GET}
  _IO_CURRENTLY_PUTTING = $800;
  {$EXTERNALSYM _IO_CURRENTLY_PUTTING}
  _IO_IS_APPENDING = $1000;
  {$EXTERNALSYM _IO_IS_APPENDING}
  _IO_IS_FILEBUF = $2000;
  {$EXTERNALSYM _IO_IS_FILEBUF}
  _IO_BAD_SEEN = $4000;
  {$EXTERNALSYM _IO_BAD_SEEN}
  _IO_USER_LOCK = $8000;
  {$EXTERNALSYM _IO_USER_LOCK}

{ These are "formatting flags" matching the iostream fmtflags enum values. }
  _IO_SKIPWS = $1;
  {$EXTERNALSYM _IO_SKIPWS}
  _IO_LEFT = $2;
  {$EXTERNALSYM _IO_LEFT}
  _IO_RIGHT = $4;
  {$EXTERNALSYM _IO_RIGHT}
  _IO_INTERNAL = $8;
  {$EXTERNALSYM _IO_INTERNAL}
  _IO_DEC = $10;
  {$EXTERNALSYM _IO_DEC}
  _IO_OCT = $20;
  {$EXTERNALSYM _IO_OCT}
  _IO_HEX = $40;
  {$EXTERNALSYM _IO_HEX}
  _IO_SHOWBASE = $80;
  {$EXTERNALSYM _IO_SHOWBASE}
  _IO_SHOWPOINT = $100;
  {$EXTERNALSYM _IO_SHOWPOINT}
  _IO_UPPERCASE = $200;
  {$EXTERNALSYM _IO_UPPERCASE}
  _IO_SHOWPOS = $400;
  {$EXTERNALSYM _IO_SHOWPOS}
  _IO_SCIENTIFIC = $800;
  {$EXTERNALSYM _IO_SCIENTIFIC}
  _IO_FIXED = $1000;
  {$EXTERNALSYM _IO_FIXED}
  _IO_UNITBUF = $2000;
  {$EXTERNALSYM _IO_UNITBUF}
  _IO_STDIO = $4000;
  {$EXTERNALSYM _IO_STDIO}
  _IO_DONT_CLOSE = $8000;
  {$EXTERNALSYM _IO_DONT_CLOSE}
  _IO_BOOLALPHA = $10000;
  {$EXTERNALSYM _IO_BOOLALPHA}


{ This is the structure from the libstdc++ codecvt class.  }
type
  __codecvt_result =
  (
    __codecvt_ok = 0,
    {$EXTERNALSYM __codecvt_ok}
    __codecvt_partial = 1,
    {$EXTERNALSYM __codecvt_partial}
    __codecvt_error = 2,
    {$EXTERNALSYM __codecvt_error}
    __codecvt_noconv = 3
    {$EXTERNALSYM __codecvt_noconv}
  );
  {$EXTERNALSYM __codecvt_result}


type
  _IO_jump_t = record end;

type
  _IO_lock_t = record end;
  {$EXTERNALSYM _IO_lock_t}
  TIOLock = _IO_lock_t;
  PIOLock = ^TIOLock;

{ A streammarker remembers a position in a buffer. }

  PIOFile = ^_IO_FILE;
  PIOMarker = ^_IO_marker;
  _IO_marker = {packed} record
    _next: PIOMarker;
    _sbuf: PIOFile;
    _pos: Integer;
  end;
  {$EXTERNALSYM _IO_marker}


{ The order of the elements in the following struct must match the order
   of the virtual functions in the libstdc++ codecvt class.  }

  PIOCodeVect = ^TIOCodeVect;

  // The following function declarations are used anonymously in the header file.
  TCodeCvtDestrProc = procedure(p1: PIOCodeVect); cdecl;

  TCodeCvtDoOutProc = function(p1: PIOCodeVect; p2: PMultiByteState; p3, p4: Pwchar_t;
    p5: PPwchar_t; p6, p7: PChar; p8: PPChar): __codecvt_result; cdecl;

  TCodeCvtDoUnshiftProc = function(p1: PIOCodeVect; p2: PMultiByteState;
    p3: PChar; p4: PChar; p5: PPChar): __codecvt_result; cdecl;

  TCodeCvtDoInProc = function(p1: PIOCodeVect; p2: PMultiByteState; p3: PChar;
    p4: PChar; p5: PPChar; p6: Pwchar_t; p7: Pwchar_t; p8: PPwchar_t): __codecvt_result; cdecl;

  TCodeCvtDoEncodingProc = function(p1: PIOCodeVect): Integer; cdecl;

  TCodeCvtDoAlwaysNoConvProc = function(p1: PIOCodeVect): Integer; cdecl;

  TCodeCvtDoLengthProc = function(p1: PIOCodeVect; p2: PMultiByteState; p3: PChar;
    p4: PChar; p5: _IO_size_t): Integer; cdecl;

  TCodeCvtDoMaxLengthProc = function(p1: PIOCodeVect): Integer; cdecl;

  _IO_codecvt = {packed} record
    __codecvt_destr: TCodeCvtDestrProc;
    __codecvt_do_out: TCodeCvtDoOutProc;
    __codecvt_do_unshift: TCodeCvtDoUnshiftProc;
    __codecvt_do_in: TCodeCvtDoInProc;
    __codecvt_do_encoding: TCodeCvtDoEncodingProc;
    __codecvt_do_always_noconv: TCodeCvtDoAlwaysNoConvProc;
    __codecvt_do_length: TCodeCvtDoLengthProc;
    __codecvt_do_max_length: TCodeCvtDoMaxLengthProc;

    __cd_in: _IO_iconv_t;
    __cd_out: _IO_iconv_t;
  end;
  {$EXTERNALSYM _IO_codecvt}
  TIOCodeVect = _IO_codecvt;

{ Extra data for wide character streams.  }
  _IO_wide_data = {packed} record
    _IO_read_ptr: Pwchar_t;      { Current read pointer }
    _IO_read_end: Pwchar_t;      { End of get area. }
    _IO_read_base: Pwchar_t;     { Start of putback+get area. }
    _IO_write_base: Pwchar_t;    { Start of put area. }
    _IO_write_ptr: Pwchar_t;     { Current put pointer. }
    _IO_write_end: Pwchar_t;     { End of put area. }
    _IO_buf_base: Pwchar_t;      { Start of reserve area. }
    _IO_buf_end: Pwchar_t;       { End of reserve area. }
    { The following fields are used to support backing up and undo. }
    _IO_save_base: Pwchar_t;     { Pointer to start of non-current get area. }
    _IO_backup_base: Pwchar_t;   { Pointer to first valid character of backup area }
    _IO_save_end: Pwchar_t;      { Pointer to end of non-current get area. }

    _IO_state: __mbstate_t;
    _IO_last_state: __mbstate_t;

    _codecvt: _IO_codecvt;

    _shortbuf: packed array[0..1-1] of wchar_t;

    _wide_vtable: ^_IO_jump_t;
  end;
  {$EXTERNALSYM _IO_wide_data}

  _IO_FILE = {packed} record
    _flags: Integer;    { High-order word is _IO_MAGIC; rest is flags. }

    { The following pointers correspond to the C++ streambuf protocol. }
    { Note:  Tk uses the _IO_read_ptr and _IO_read_end fields directly. }
    _IO_read_ptr: PChar;{ Current read pointer }
    _IO_read_end: PChar;{ End of get area. }
    _IO_read_base: PChar;{ Start of putback+get area. }
    _IO_write_base: PChar;{ Start of put area. }
    _IO_write_ptr: PChar;{ Current put pointer. }
    _IO_write_end: PChar;{ End of put area. }
    _IO_buf_base: PChar;{ Start of reserve area. }
    _IO_buf_end: PChar; { End of reserve area. }
    { The following fields are used to support backing up and undo. }
    _IO_save_base: PChar;{ Pointer to start of non-current get area. }
    _IO_backup_base: PChar;{ Pointer to first valid character of backup area }
    _IO_save_end: PChar;{ Pointer to end of non-current get area. }

    _markers: PIOMarker;

    _chain: PIOFile;

    _fileno: Integer;
    _blksize: Integer;
    { This used to be _offset but it's too small.  }
    _old_offset: _IO_off_t;

    { 1+column number of pbase(); 0 is unknown. }
    _cur_column: Word;
    _vtable_offset: Shortint;
    _shortbuf: packed array[0..1-1] of Char; // This is indeed correct.

    {  char* _save_gptr;  char* _save_egptr; }

    _lock: PIOLock;
    _offset: _IO_off64_t;

    { Wide character stream stuff.  }
    _codecvt: ^_IO_codecvt;
    _wide_data: ^_IO_wide_data;

    _mode: Integer;
    { Make sure we don't get into trouble again.  }
    _unused2: packed array[0..(15*SizeOf(Integer) - 2*SizeOf(Pointer))-1] of Byte;
  end;
  {$EXTERNALSYM _IO_FILE}
  TIOFile = _IO_FILE;

{ Functions to do I/O and file management for a stream.  }

type
{ Read NBYTES bytes from COOKIE into a buffer pointed to by BUF.
   Return number of bytes read.  }
  __io_read_fn = function(__cookie: Pointer; __buf: PChar; __nbytes: size_t): __ssize_t; cdecl;
  {$EXTERNALSYM __io_read_fn}

{ Write N bytes pointed to by BUF to COOKIE.  Write all N bytes
   unless there is an error.  Return number of bytes written, or -1 if
   there is an error without writing anything.  If the file has been
   opened for append (__mode.__append set), then set the file pointer
   to the end of the file and then do the write; if not, just write at
   the current file pointer.  }
  __io_write_fn = function(__cookie: Pointer; __buf: PChar; __n: size_t): __ssize_t; cdecl;
  {$EXTERNALSYM __io_write_fn}

{ Move COOKIE's file position to *POS bytes from the
   beginning of the file (if W is SEEK_SET),
   the current position (if W is SEEK_CUR),
   or the end of the file (if W is SEEK_END).
   Set *POS to the new file position.
   Returns zero if successful, nonzero if not.  }
  __io_seek_fn = function(__cookie: Pointer; __pos: P_IO_off64_t; __w: Integer): Integer; cdecl;
  {$EXTERNALSYM __io_seek_fn}

{ Close COOKIE.  }
  __io_close_fn = function(__cookie: Pointer): Integer; cdecl;
  {$EXTERNALSYM __io_close_fn}

{ User-visible names for the above.  }
  cookie_read_function_t = __io_read_fn;
  {$EXTERNALSYM cookie_read_function_t}
  cookie_write_function_t = __io_write_fn;
  {$EXTERNALSYM cookie_write_function_t}
  cookie_seek_function_t = __io_seek_fn;
  {$EXTERNALSYM cookie_seek_function_t}
  cookie_close_function_t = __io_close_fn;
  {$EXTERNALSYM cookie_close_function_t}


{ The structure with the cookie function pointers.  }
type
  _IO_cookie_io_functions_t = {packed} record
    read: __io_read_fn;         { Read bytes.  }
    write: __io_write_fn;       { Write bytes.  }
    seek: __io_seek_fn;         { Seek/tell file position.  }
    close: __io_close_fn;       { Close file.  }
  end;
  {$EXTERNALSYM _IO_cookie_io_functions_t}
  cookie_io_functions_t = _IO_cookie_io_functions_t;
  {$EXTERNALSYM cookie_io_functions_t}
  TIOCookieFunctions = _IO_cookie_io_functions_t;
  PIOCookieFunctions = ^TIOCookieFunctions;

{ Special file type for fopencookie function.  }
  _IO_cookie_file = {packed} record
    _file: _IO_FILE;
    vtable: Pointer;
    cookie: Pointer;
    io_functions: _IO_cookie_io_functions_t;
  end;
  {$EXTERNALSYM _IO_cookie_file}
  TIOCookieFile = _IO_cookie_file;
  PIOCookieFile = ^TIOCookieFile;


(* Declared as a local symbol only
{ Initialize one of those.  }
procedure _IO_cookie_init(__cfile: PIOCookieFile; __read_write: Integer;
  __cookie: Pointer; __fns: _IO_cookie_io_functions_t); cdecl;
{$EXTERNALSYM _IO_cookie_init}
*)

function __underflow(p1: PIOFile): Integer; cdecl;
{$EXTERNALSYM __underflow}
function __uflow(p1: PIOFile): Integer; cdecl;
{$EXTERNALSYM __uflow}
function __overflow(p1: PIOFile; p2: Integer): Integer; cdecl;
{$EXTERNALSYM __overflow}

function __wunderflow(p1: PIOFile): _IO_wint_t; cdecl;
{$EXTERNALSYM __wunderflow}
function __wuflow(p1: PIOFile): _IO_wint_t; cdecl;
{$EXTERNALSYM __wuflow}
function __woverflow(p1: PIOFile; p2: _IO_wint_t): _IO_wint_t; cdecl;
{$EXTERNALSYM __woverflow}

function _IO_getc_unlocked(_fp: PIOFile): Integer;
{$EXTERNALSYM _IO_getc_unlocked}
function _IO_peekc_unlocked(_fp: PIOFile): Integer;
{$EXTERNALSYM _IO_peekc_unlocked}
function _IO_putc_unlocked(_ch: Char; _fp: PIOFile): Integer;
{$EXTERNALSYM _IO_putc_unlocked}

function _IO_getwc_unlocked(_fp: PIOFile): Integer;
{$EXTERNALSYM _IO_getwc_unlocked}
function _IO_putwc_unlocked(_wch: wchar_t; _fp: PIOFile): Integer;
{$EXTERNALSYM _IO_putwc_unlocked}

function _IO_feof_unlocked(_fp: PIOFile): Integer;
{$EXTERNALSYM _IO_feof_unlocked}
function _IO_ferror_unlocked(_fp: PIOFile): Integer;
{$EXTERNALSYM _IO_ferror_unlocked}

function _IO_getc(fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM _IO_getc}
function _IO_putc(c: Integer; fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM _IO_putc}
function _IO_feof(fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM _IO_feof}
function _IO_ferror(fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM _IO_ferror}

function _IO_peekc_locked(fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM _IO_peekc_locked}

{ This one is for Emacs. }
function _IO_PENDING_OUTPUT_COUNT(_fp: PIOFile): Integer; 
{$EXTERNALSYM _IO_PENDING_OUTPUT_COUNT}

procedure _IO_flockfile(p1: PIOFile); cdecl;
{$EXTERNALSYM _IO_flockfile}
procedure _IO_funlockfile(p1: PIOFile); cdecl;
{$EXTERNALSYM _IO_funlockfile}
function _IO_ftrylockfile(p1: PIOFile): Integer; cdecl;
{$EXTERNALSYM _IO_ftrylockfile}

function _IO_vfscanf(p1: PIOFile; p2: PChar; p3: Pointer;
  p4: PInteger): Integer; cdecl;
{$EXTERNALSYM _IO_vfscanf}
function _IO_vfprintf(p1: PIOFile; p2: PChar; p3: Pointer): Integer; cdecl;
{$EXTERNALSYM _IO_vfprintf}
function _IO_padn(p1: PIOFile; p2: Integer; p3: Integer): _IO_size_t; cdecl;
{$EXTERNALSYM _IO_padn}
function _IO_sgetn(p1: PIOFile; p2: Pointer; p3: _IO_size_t): _IO_size_t; cdecl;
{$EXTERNALSYM _IO_sgetn}

function _IO_seekoff(p1: PIOFile; p2: _IO_off64_t; p3, p4: Integer): _IO_off64_t; cdecl;
{$EXTERNALSYM _IO_seekoff}

function _IO_seekpos(p1: PIOFile; p2: _IO_fpos64_t; p3: Integer): _IO_off64_t; cdecl;
{$EXTERNALSYM _IO_seekpos}

procedure _IO_free_backup_area(p1: PIOFile); cdecl;
{$EXTERNALSYM _IO_free_backup_area}

(* Declared as a local symbol only
function _IO_getwc(__fp: PIOFile): _IO_wint_t; cdecl;
{$EXTERNALSYM _IO_getwc}
function _IO_putwc(__wc: wchar_t; __fp: PIOFile): _IO_wint_t; cdecl;
{$EXTERNALSYM _IO_putwc}
function _IO_fwide(__fp: PIOFile; __mode: Integer): Integer; cdecl;
{$EXTERNALSYM _IO_fwide}
*)

(* Declared as a local symbol only
function _IO_vfwscanf(p1: PIOFile; p2: Pwchar_t; p3: _IO_va_list; p4: PInteger): Integer; cdecl;
{$EXTERNALSYM _IO_vfwscanf}
function _IO_vfwprintf(p1: PIOFile; p2: Pwchar_t; Arg: _IO_va_list): Integer; cdecl;
{$EXTERNALSYM _IO_vfwprintf}
function _IO_wpadn(p1: PIOFile; p2: wint_t; p3: _IO_ssize_t): _IO_ssize_t; cdecl;
{$EXTERNALSYM _IO_wpadn}
*)

procedure _IO_free_wbackup_area(p1: PIOFile); cdecl;
{$EXTERNALSYM _IO_free_wbackup_area}


// Translated from stdio.h

{ The type of the second argument to `fgetpos' and `fsetpos'.  }
type
  fpos_t = _G_fpos_t;
  {$EXTERNALSYM fpos_t}
  PFPos = ^fpos_t;

  fpos64_t = _G_fpos64_t;
  {$EXTERNALSYM fpos64_t}
  PFPos64 = ^fpos64_t;

{ The possibilities for the third argument to `setvbuf'.  }
const
  _IOFBF = 0;               { Fully buffered.  }
  {$EXTERNALSYM _IOFBF}
  _IOLBF = 1;               { Line buffered.  }
  {$EXTERNALSYM _IOLBF}
  _IONBF = 2;               { No buffering.  }
  {$EXTERNALSYM _IONBF}


{ Default buffer size.  }
  BUFSIZ  = _IO_BUFSIZ;
  {$EXTERNALSYM BUFSIZ}

(* __EOF, SEEK_SET, SEEK_CUR, SEEK_END declared elsewhere *)

{ Default path prefix for `tempnam' and `tmpnam'.  }
  P_tmpdir        = '/tmp';
  {$EXTERNALSYM P_tmpdir}


{ Get the values:
   L_tmpnam	How long an array of chars must be to be passed to `tmpnam'.
   TMP_MAX	The minimum number of unique filenames generated by tmpnam
   		(and tempnam when it uses tmpnam's name space),
		or tempnam (the two are separate).
   L_ctermid	How long an array to pass to `ctermid'.
   L_cuserid	How long an array to pass to `cuserid'.
   FOPEN_MAX	Minimum number of files that can be open at once.
   FILENAME_MAX	Maximum length of a filename.  }

// Translated from bits/stdio_lim.h (inline in stdio.h)

  L_tmpnam  = 20;
  {$EXTERNALSYM L_tmpnam}
  TMP_MAX  = 238328;
  {$EXTERNALSYM TMP_MAX}
  FILENAME_MAX  = 4095;
  {$EXTERNALSYM FILENAME_MAX}

  L_ctermid   = 9;
  {$EXTERNALSYM L_ctermid}
  L_cuserid   = 9;
  {$EXTERNALSYM L_cuserid}

  FOPEN_MAX  = 16;
  {$EXTERNALSYM FOPEN_MAX}

  IOV_MAX    = 1024;
  {$EXTERNALSYM IOV_MAX}


{ Standard streams.  }


{ Remove file FILENAME.  }
function remove(Filename: PChar): Integer; cdecl;
{$EXTERNALSYM remove}

{ Rename file OLD to NEW.  }
// HTI - Renamed from "rename" to "__rename"
function __rename(OldName, NewName: PChar): Integer; cdecl;
{ $EXTERNALSYM rename}


{ Create a temporary file and open it read/write.  }
function tmpfile: PIOFile; cdecl;
{$EXTERNALSYM tmpfile}

function tmpfile64: PIOFile; cdecl;
{$EXTERNALSYM tmpfile64}

{ Generate a temporary filename.  }
function tmpnam(S: PChar): PChar; cdecl;
{$EXTERNALSYM tmpnam}

{ This is the reentrant variant of `tmpnam'.  The only difference is
   that it does not allow S to be NULL.  }
function tmpnam_r(S: PChar): PChar; cdecl;
{$EXTERNALSYM tmpnam_r}

{ Generate a unique temporary filename using up to five characters of PFX
   if it is not NULL.  The directory to put this file in is searched for
   as follows: First the environment variable "TMPDIR" is checked.
   If it contains the name of a writable directory, that directory is used.
   If not and if DIR is not NULL, that value is checked.  If that fails,
   P_tmpdir is tried and finally "/tmp".  The storage for the filename
   is allocated by `malloc'.  }
function tempnam(Dir, PFX: PChar): PChar; cdecl;
{$EXTERNALSYM tempnam}

{ Close STREAM.  }
function fclose(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fclose}

{ Flush STREAM, or all streams if STREAM is NULL.  }
function fflush(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fflush}

{ Faster versions when locking is not required.  }
function fflush_unlocked(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fflush_unlocked}

{ Close all streams.  }
function fcloseall: Integer; cdecl;
{$EXTERNALSYM fcloseall}

{ Open a file and create a new stream for it.  }
function fopen(FileName: PChar; Modes: PChar): PIOFile; cdecl;
{$EXTERNALSYM fopen}

{ Open a file, replacing an existing stream with it. }
function freopen(FileName: PChar; Modes: PChar; Stream: PIOFile): PIOFile; cdecl;
{$EXTERNALSYM freopen}

function fopen64(FileName: PChar; Modes: PChar): PIOFile; cdecl;
{$EXTERNALSYM fopen64}

function freopen64(FileName: PChar; Modes: PChar; Stream: PIOFile): PIOFile; cdecl;
{$EXTERNALSYM freopen64}

{ Create a new stream that refers to an existing system file descriptor.  }
function fdopen(FileDes: Integer; Modes: PChar): PIOFile; cdecl;
{$EXTERNALSYM fdopen}

{ Create a new stream that refers to the given magic cookie,
   and uses the given functions for input and output.  }
function fopencookie(MagicCookie: Pointer; Modes: PChar;
  IORuncs: TIOCookieFunctions): PIOFile; cdecl;
{$EXTERNALSYM fopencookie}

{ Create a new stream that refers to a memory buffer.  }
function fmemopen(__s: Pointer; __len: size_t; __modes: PChar): PIOFile; cdecl;
{$EXTERNALSYM fmemopen}

{ Open a stream that writes into a malloc'd buffer that is expanded as
   necessary.  *BUFLOC and *SIZELOC are updated with the buffer's location
   and the number of characters written on fflush or fclose.  }
function open_memstream(BufLoc: PPChar; SizeLoc: PLongWord): PIOFile; cdecl;
{$EXTERNALSYM open_memstream}

{ If BUF is NULL, make STREAM unbuffered.
   Else make it use buffer BUF, of size BUFSIZ.  }
procedure setbuf(Stream: PIOFile; Buf: PChar); cdecl;
{$EXTERNALSYM setbuf}

{ Make STREAM use buffering mode MODE.
   If BUF is not NULL, use N bytes of it for buffering;
   else allocate an internal buffer N bytes long.  }
function setvbuf(Stream: PIOFile; Buf: PChar; Modes: Integer; N: size_t): Integer; cdecl;
{$EXTERNALSYM setvbuf}

{ If BUF is NULL, make STREAM unbuffered.
   Else make it use SIZE bytes of BUF for buffering.  }
procedure setbuffer(Stream: PIOFile; Buf: PChar; Size: size_t); cdecl;
{$EXTERNALSYM setbuffer}

{ Make STREAM line-buffered.  }
procedure setlinebuf(Stream: PIOFile); cdecl;
{$EXTERNALSYM setlinebuf}

{ Write formatted output to STREAM.  }
function fprintf(Stream: PIOFile; Format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM fprintf}

{ Write formatted output to stdout.  }
function printf(Format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM printf}

{ Write formatted output to S.  }
function sprintf(S: PChar; Format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM sprintf}

{ Write formatted output to S from argument list ARG.  }
function vfprintf(S: PIOFile; Format: PChar; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vfprintf}

{ Write formatted output to stdout from argument list ARG.  }
function vprintf(Format: PChar; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vprintf}

{ Write formatted output to S from argument list ARG.  }
function vsprintf(S: PChar; Format: PChar; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vsprintf}

{ Maximum chars of output to write in MAXLEN.  }
function snprintf(S: PChar; MaxLen: size_t; Format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM snprintf}

function __vsnprintf(__s: PChar; __maxlen: size_t; __format: PChar;
  __arg: Pointer): Integer; cdecl;
{$EXTERNALSYM __vsnprintf}

function vsnprintf(__s: PChar; __maxlen: size_t; __format: PChar;
  __arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vsnprintf}

{ Write formatted output to a string dynamically allocated with `malloc'.
   Store the address of the string in *PTR.  }
function vasprintf(__ptr: PPChar; __f: PChar; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vasprintf}

function __asprintf(__ptr: PPChar; __fmt: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM __asprintf}

function asprintf(__ptr: PPChar; __fmt: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM asprintf}


{ Write formatted output to a file descriptor.  }
function vdprintf(__fd: Integer; __fmt: PChar; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vdprintf}

function dprintf(__fd: Integer; __fmt: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM dprintf}


{ Read formatted input from STREAM.  }
function fscanf(__stream: PIOFile; __format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM fscanf}

{ Read formatted input from stdin.  }
function scanf(__format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM scanf}

{ Read formatted input from S.  }
function sscanf(__s: PChar; __format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM sscanf}

{ Read formatted input from S into argument list ARG.  }
function vfscanf(__s: PIOFile; __format: PChar; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vfscanf}

{ Read formatted input from stdin into argument list ARG.  }
function vscanf(__format: PChar; __arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vscanf}

{ Read formatted input from S into argument list ARG.  }
function vsscanf(__s: PChar; __format: PChar; __arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vsscanf}


{ Read a character from STREAM.  }
function fgetc(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fgetc}

function getc(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM getc}

{ Read a character from stdin.  }
function getchar: Integer; cdecl;
{$EXTERNALSYM getchar}

{ These are defined in POSIX.1:1996.  }
function getc_unlocked(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM getc_unlocked}

function getchar_unlocked: Integer; cdecl;
{$EXTERNALSYM getchar_unlocked}

{ Faster version when locking is not necessary.  }
function fgetc_unlocked(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fgetc_unlocked}

{ Write a character to STREAM.  }
function fputc(C: Integer; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fputc}
function putc(C: Integer; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM putc}

{ Write a character to stdout.  }
function putchar(C: Integer): Integer; cdecl;
{$EXTERNALSYM putchar}

{ Faster version when locking is not necessary.  }
function fputc_unlocked(C: Integer; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fputc_unlocked}

{ These are defined in POSIX.1:1996.  }
function putc_unlocked(C: Integer; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM putc_unlocked}
function putchar_unlocked(C: Integer): Integer; cdecl;
{$EXTERNALSYM putchar_unlocked}

{ Get a word (int) from STREAM.  }
function getw(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM getw}

{ Write a word (int) to STREAM.  }
function putw(W: Integer; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM putw}

{ Get a newline-terminated string of finite length from STREAM.  }
function fgets(S: PChar; N: Integer; Stream: PIOFile): PChar; cdecl;
{$EXTERNALSYM fgets}

{ This function does the same as `fgets' but does not lock the stream.  }
function fgets_unlocked(S: PChar; N: Integer; Stream: PIOFile): PChar; cdecl;
{$EXTERNALSYM fgets_unlocked}

{ Get a newline-terminated string from stdin, removing the newline.
   DO NOT USE THIS FUNCTION!!  There is no limit on how much it will read.  }
function gets(S: PChar): PChar; cdecl;
{$EXTERNALSYM gets}


{ Read up to (and including) a DELIMITER from STREAM into *LINEPTR
   (and null-terminate it). *LINEPTR is a pointer returned from malloc (or
   NULL), pointing to *N characters of space.  It is realloc'd as
   necessary.  Returns the number of characters read (not including the
   null terminator), or -1 on error or EOF.  }
function getdelim(LinePtr: PPChar; N: PLongWord; Delimiter: Integer;
  Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM getdelim}

{ Like `getdelim', but reads up to a newline.  }
function getline(LinePtr: PPChar; N: PLongWord; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM getline}


{ Write a string to STREAM.  }
function fputs(const S: PChar; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fputs}

{ This function does the same as `fputs' but does not lock the stream.  }
function fputs_unlocked(const S: PChar; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fputs_unlocked}

{ Write a string, followed by a newline, to stdout.  }
function puts(const S: PChar): Integer; cdecl;
{$EXTERNALSYM puts}


{ Push a character back onto the input buffer of STREAM.  }
function ungetc(C: Integer; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM ungetc}


{ Read chunks of generic data from STREAM.  }
function fread(Ptr: Pointer; Size: size_t; N: size_t;
  Stream: PIOFile): size_t; cdecl;
{$EXTERNALSYM fread}

{ Write chunks of generic data to STREAM.  }
function fwrite(const __ptr: Pointer; Size: size_t; N: size_t;
  S: PIOFile): size_t; cdecl;
{$EXTERNALSYM fwrite}

{ Faster versions when locking is not necessary.  }
function fread_unlocked(Ptr: Pointer; Size: size_t; N: size_t;
  Stream: PIOFile): size_t; cdecl;
{$EXTERNALSYM fread_unlocked}

function fwrite_unlocked(const Ptr: Pointer; Size: size_t; N: size_t;
  Stream: PIOFile): size_t; cdecl;
{$EXTERNALSYM fwrite_unlocked}


{ Seek to a certain position on STREAM.  }
function fseek(Stream: PIOFile; Off: Longint;
  Whence: Integer): Integer; cdecl;
{$EXTERNALSYM fseek}

{ Return the current position of STREAM.  }
function ftell(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM ftell}

{ Rewind to the beginning of STREAM.  }
procedure rewind(Stream: PIOFile); cdecl;
{$EXTERNALSYM rewind}

{ Seek to a certain position on STREAM.  }
function fseeko(Stream: PIOFile; Off: __off_t;
  Whence: Integer): Integer; cdecl;
{$EXTERNALSYM fseeko}

{ Return the current position of STREAM.  }
function ftello(Stream: PIOFile): __off_t; cdecl;
{$EXTERNALSYM ftello}

{ Get STREAM's position.  }
function fgetpos(Stream: PIOFile; var Pos: fpos_t): Integer; cdecl;
{$EXTERNALSYM fgetpos}

{ Set STREAM's position.  }
function fsetpos(Stream: PIOFile; const Pos: PFpos): Integer; cdecl;
{$EXTERNALSYM fsetpos}

function fseeko64(Stream: PIOFile; Off: __off64_t; Whence: Integer): Integer; cdecl;
{$EXTERNALSYM fseeko64}

function ftello64(Stream: PIOFile): __off64_t; cdecl;
{$EXTERNALSYM ftello64}

function fgetpos64(Stream: PIOFile; var Pos: fpos64_t): Integer; cdecl;
{$EXTERNALSYM fgetpos64}

function fsetpos64(Stream: PIOFile; const Pos: PFPos64): Integer; cdecl;
{$EXTERNALSYM fsetpos64}

{ Clear the error and EOF indicators for STREAM.  }
procedure clearerr(Stream: PIOFile); cdecl;
{$EXTERNALSYM clearerr}

{ Return the EOF indicator for STREAM.  }
function feof(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM feof}

{ Return the error indicator for STREAM.  }
function ferror(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM ferror}

{ Faster versions when locking is not required.  }
procedure clearerr_unlocked(Stream: PIOFile); cdecl;
{$EXTERNALSYM clearerr_unlocked}

function feof_unlocked(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM feof_unlocked}

function ferror_unlocked(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM ferror_unlocked}

{ Print a message describing the meaning of the value of errno.  }
procedure perror(const S: PChar); cdecl;
{$EXTERNALSYM perror}

{ Return the system file descriptor for STREAM.  }
function fileno(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fileno}

{ Faster version when locking is not required.  }
function fileno_unlocked(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fileno_unlocked}


{ Create a new stream connected to a pipe running the given command.  }
function popen(const Command: PChar; Modes: PChar): PIOFile; cdecl;
{$EXTERNALSYM popen}

{ Close a stream opened by popen and return the status of its child.  }
function pclose(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM pclose}


{ Return the name of the controlling terminal.  }
function ctermid(S: PChar): PChar; cdecl;
{$EXTERNALSYM ctermid}


{ Return the name of the current user.  }
function cuserid(S: PChar): PChar; cdecl;
{$EXTERNALSYM cuserid}

(*
  obstack.h required for these functions

{ Write formatted output to an obstack.  }
function obstack_printf(__obstack: PObstack; __format: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM obstack_printf}

function obstack_vprintf(__obstack: PObstack; __format: PChar;
  __args: Pointer): Integer; cdecl;
{$EXTERNALSYM obstack_vprintf}
*)

{ These are defined in POSIX.1:1996.  }

{ Acquire ownership of STREAM.  }
procedure flockfile(Stream: PIOFile); cdecl;
{$EXTERNALSYM flockfile}

{ Try to acquire ownership of STREAM but do not block if it is not possible. }
function ftrylockfile(Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM ftrylockfile}

{ Relinquish the ownership granted for STREAM.  }
procedure funlockfile(Stream: PIOFile); cdecl;
{$EXTERNALSYM funlockfile}


// Translated from stdio_ext.h

{ Functions to access FILE structure internals. }
const
  { Query current state of the locking status.  }
  FSETLOCKING_QUERY = 0;
  {$EXTERNALSYM FSETLOCKING_QUERY}

  { The library protects all uses of the stream functions, except for
     uses of the *_unlocked functions, by calls equivalent to flockfile().  }
  FSETLOCKING_INTERNAL = 1;
  {$EXTERNALSYM FSETLOCKING_INTERNAL}

  { The user will take care of locking.  }
  FSETLOCKING_BYCALLER = 2;
  {$EXTERNALSYM FSETLOCKING_BYCALLER}


{ Return the size of the buffer of FP in bytes currently in use by
   the given stream.  }
function __fbufsize(__fp: PIOFile): size_t; cdecl;
{$EXTERNALSYM __fbufsize}


{ Return non-zero value iff the stream FP is opened readonly, or if the
   last operation on the stream was a read operation.  }
function __freading(__fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM __freading}

{ Return non-zero value iff the stream FP is opened write-only or
   append-only, or if the last operation on the stream was a write
   operation.  }
function __fwriting(__fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM __fwriting}


{ Return non-zero value iff stream FP is not opened write-only or
   append-only.  }
function __freadable(__fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM __freadable}

{ Return non-zero value iff stream FP is not opened read-only.  }
function __fwritable(__fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM __fwritable}


{ Return non-zero value iff the stream FP is line-buffered.  }
function __flbf(__fp: PIOFile): Integer; cdecl;
{$EXTERNALSYM __flbf}


{ Discard all pending buffered I/O on the stream FP.  }
procedure __fpurge(__fp: PIOFile); cdecl;
{$EXTERNALSYM __fpurge}

{ Return amount of output in bytes pending on a stream FP.  }
function __fpending(__fp: PIOFile): size_t; cdecl;
{$EXTERNALSYM __fpending}

{ Flush all line-buffered files.  }
procedure _flushlbf(); cdecl;
{$EXTERNALSYM _flushlbf}


{ Set locking status of stream FP to TYPE.  }
function __fsetlocking(__fp: PIOFile; __type: Integer): Integer; cdecl;
{$EXTERNALSYM __fsetlocking}


// Translated from bits/confname.h included in unistd.h

{ Get the `_PC_*' symbols for the NAME argument to `pathconf' and `fpathconf';
   the `_SC_*' symbols for the NAME argument to `sysconf';
   and the `_CS_*' symbols for the NAME argument to `confstr'.  }

{  Values for the NAME argument to `pathconf' and `fpathconf'.  }
const
    _PC_LINK_MAX = 0;
    {$EXTERNALSYM _PC_LINK_MAX}
    _PC_MAX_CANON = 1;
    {$EXTERNALSYM _PC_MAX_CANON}
    _PC_MAX_INPUT = 2;
    {$EXTERNALSYM _PC_MAX_INPUT}
    _PC_NAME_MAX = 3;
    {$EXTERNALSYM _PC_NAME_MAX}
    _PC_PATH_MAX = 4;
    {$EXTERNALSYM _PC_PATH_MAX}
    _PC_PIPE_BUF = 5;
    {$EXTERNALSYM _PC_PIPE_BUF}
    _PC_CHOWN_RESTRICTED = 6;
    {$EXTERNALSYM _PC_CHOWN_RESTRICTED}
    _PC_NO_TRUNC = 7;
    {$EXTERNALSYM _PC_NO_TRUNC}
    _PC_VDISABLE = 8;
    {$EXTERNALSYM _PC_VDISABLE}
    _PC_SYNC_IO = 9;
    {$EXTERNALSYM _PC_SYNC_IO}
    _PC_ASYNC_IO = 10;
    {$EXTERNALSYM _PC_ASYNC_IO}
    _PC_PRIO_IO = 11;
    {$EXTERNALSYM _PC_PRIO_IO}
    _PC_SOCK_MAXBUF = 12;
    {$EXTERNALSYM _PC_SOCK_MAXBUF}
    _PC_FILESIZEBITS = 13;
    {$EXTERNALSYM _PC_FILESIZEBITS}


{  Values for the argument to `sysconf'.  }

    _SC_ARG_MAX = 0;
    {$EXTERNALSYM _SC_ARG_MAX}
    _SC_CHILD_MAX = 1;
    {$EXTERNALSYM _SC_CHILD_MAX}
    _SC_CLK_TCK = 2;
    {$EXTERNALSYM _SC_CLK_TCK}
    _SC_NGROUPS_MAX = 3;
    {$EXTERNALSYM _SC_NGROUPS_MAX}
    _SC_OPEN_MAX = 4;
    {$EXTERNALSYM _SC_OPEN_MAX}
    _SC_STREAM_MAX = 5;
    {$EXTERNALSYM _SC_STREAM_MAX}
    _SC_TZNAME_MAX = 6;
    {$EXTERNALSYM _SC_TZNAME_MAX}
    _SC_JOB_CONTROL = 7;
    {$EXTERNALSYM _SC_JOB_CONTROL}
    _SC_SAVED_IDS = 8;
    {$EXTERNALSYM _SC_SAVED_IDS}
    _SC_REALTIME_SIGNALS = 9;
    {$EXTERNALSYM _SC_REALTIME_SIGNALS}
    _SC_PRIORITY_SCHEDULING = 10;
    {$EXTERNALSYM _SC_PRIORITY_SCHEDULING}
    _SC_TIMERS = 11;
    {$EXTERNALSYM _SC_TIMERS}
    _SC_ASYNCHRONOUS_IO = 12;
    {$EXTERNALSYM _SC_ASYNCHRONOUS_IO}
    _SC_PRIORITIZED_IO = 13;
    {$EXTERNALSYM _SC_PRIORITIZED_IO}
    _SC_SYNCHRONIZED_IO = 14;
    {$EXTERNALSYM _SC_SYNCHRONIZED_IO}
    _SC_FSYNC = 15;
    {$EXTERNALSYM _SC_FSYNC}
    _SC_MAPPED_FILES = 16;
    {$EXTERNALSYM _SC_MAPPED_FILES}
    _SC_MEMLOCK = 17;
    {$EXTERNALSYM _SC_MEMLOCK}
    _SC_MEMLOCK_RANGE = 18;
    {$EXTERNALSYM _SC_MEMLOCK_RANGE}
    _SC_MEMORY_PROTECTION = 19;
    {$EXTERNALSYM _SC_MEMORY_PROTECTION}
    _SC_MESSAGE_PASSING = 20;
    {$EXTERNALSYM _SC_MESSAGE_PASSING}
    _SC_SEMAPHORES = 21;
    {$EXTERNALSYM _SC_SEMAPHORES}
    _SC_SHARED_MEMORY_OBJECTS = 22;
    {$EXTERNALSYM _SC_SHARED_MEMORY_OBJECTS}
    _SC_AIO_LISTIO_MAX = 23;
    {$EXTERNALSYM _SC_AIO_LISTIO_MAX}
    _SC_AIO_MAX = 24;
    {$EXTERNALSYM _SC_AIO_MAX}
    _SC_AIO_PRIO_DELTA_MAX = 25;
    {$EXTERNALSYM _SC_AIO_PRIO_DELTA_MAX}
    _SC_DELAYTIMER_MAX = 26;
    {$EXTERNALSYM _SC_DELAYTIMER_MAX}
    _SC_MQ_OPEN_MAX = 27;
    {$EXTERNALSYM _SC_MQ_OPEN_MAX}
    _SC_MQ_PRIO_MAX = 28;
    {$EXTERNALSYM _SC_MQ_PRIO_MAX}
    _SC_VERSION = 29;
    {$EXTERNALSYM _SC_VERSION}
    _SC_PAGESIZE = 30;
    {$EXTERNALSYM _SC_PAGESIZE}
    _SC_PAGE_SIZE = _SC_PAGESIZE;
    {$EXTERNALSYM _SC_PAGE_SIZE}
    _SC_RTSIG_MAX = 31;
    {$EXTERNALSYM _SC_RTSIG_MAX}
    _SC_SEM_NSEMS_MAX = 32;
    {$EXTERNALSYM _SC_SEM_NSEMS_MAX}
    _SC_SEM_VALUE_MAX = 33;
    {$EXTERNALSYM _SC_SEM_VALUE_MAX}
    _SC_SIGQUEUE_MAX = 34;
    {$EXTERNALSYM _SC_SIGQUEUE_MAX}
    _SC_TIMER_MAX = 35;
    {$EXTERNALSYM _SC_TIMER_MAX}


    {  Values for the argument to `sysconf'
       corresponding to _POSIX2_* symbols.  }
    _SC_BC_BASE_MAX = 36;
    {$EXTERNALSYM _SC_BC_BASE_MAX}
    _SC_BC_DIM_MAX = 37;
    {$EXTERNALSYM _SC_BC_DIM_MAX}
    _SC_BC_SCALE_MAX = 38;
    {$EXTERNALSYM _SC_BC_SCALE_MAX}
    _SC_BC_STRING_MAX = 39;
    {$EXTERNALSYM _SC_BC_STRING_MAX}
    _SC_COLL_WEIGHTS_MAX = 40;
    {$EXTERNALSYM _SC_COLL_WEIGHTS_MAX}
    _SC_EQUIV_CLASS_MAX = 41;
    {$EXTERNALSYM _SC_EQUIV_CLASS_MAX}
    _SC_EXPR_NEST_MAX = 42;
    {$EXTERNALSYM _SC_EXPR_NEST_MAX}
    _SC_LINE_MAX = 43;
    {$EXTERNALSYM _SC_LINE_MAX}
    _SC_RE_DUP_MAX = 44;
    {$EXTERNALSYM _SC_RE_DUP_MAX}
    _SC_CHARCLASS_NAME_MAX = 45;
    {$EXTERNALSYM _SC_CHARCLASS_NAME_MAX}

    _SC_2_VERSION = 46;
    {$EXTERNALSYM _SC_2_VERSION}
    _SC_2_C_BIND = 47;
    {$EXTERNALSYM _SC_2_C_BIND}
    _SC_2_C_DEV = 48;
    {$EXTERNALSYM _SC_2_C_DEV}
    _SC_2_FORT_DEV = 49;
    {$EXTERNALSYM _SC_2_FORT_DEV}
    _SC_2_FORT_RUN = 50;
    {$EXTERNALSYM _SC_2_FORT_RUN}
    _SC_2_SW_DEV = 51;
    {$EXTERNALSYM _SC_2_SW_DEV}
    _SC_2_LOCALEDEF = 52;
    {$EXTERNALSYM _SC_2_LOCALEDEF}

    _SC_PII = 53;
    {$EXTERNALSYM _SC_PII}
    _SC_PII_XTI = 54;
    {$EXTERNALSYM _SC_PII_XTI}
    _SC_PII_SOCKET = 55;
    {$EXTERNALSYM _SC_PII_SOCKET}
    _SC_PII_INTERNET = 56;
    {$EXTERNALSYM _SC_PII_INTERNET}
    _SC_PII_OSI = 57;
    {$EXTERNALSYM _SC_PII_OSI}
    _SC_POLL = 58;
    {$EXTERNALSYM _SC_POLL}
    _SC_SELECT = 59;
    {$EXTERNALSYM _SC_SELECT}
    _SC_UIO_MAXIOV = 60;
    {$EXTERNALSYM _SC_UIO_MAXIOV}
    _SC_PII_INTERNET_STREAM = 61;
    {$EXTERNALSYM _SC_PII_INTERNET_STREAM}
    _SC_PII_INTERNET_DGRAM = 62;
    {$EXTERNALSYM _SC_PII_INTERNET_DGRAM}
    _SC_PII_OSI_COTS = 63;
    {$EXTERNALSYM _SC_PII_OSI_COTS}
    _SC_PII_OSI_CLTS = 64;
    {$EXTERNALSYM _SC_PII_OSI_CLTS}
    _SC_PII_OSI_M = 65;
    {$EXTERNALSYM _SC_PII_OSI_M}
    _SC_T_IOV_MAX = 66;
    {$EXTERNALSYM _SC_T_IOV_MAX}

    {  Values according to POSIX 1003.1c (POSIX threads).  }
    _SC_THREADS = 67;
    {$EXTERNALSYM _SC_THREADS}
    _SC_THREAD_SAFE_FUNCTIONS = 68;
    {$EXTERNALSYM _SC_THREAD_SAFE_FUNCTIONS}
    _SC_GETGR_R_SIZE_MAX = 69;
    {$EXTERNALSYM _SC_GETGR_R_SIZE_MAX}
    _SC_GETPW_R_SIZE_MAX = 70;
    {$EXTERNALSYM _SC_GETPW_R_SIZE_MAX}
    _SC_LOGIN_NAME_MAX = 61;
    {$EXTERNALSYM _SC_LOGIN_NAME_MAX}
    _SC_TTY_NAME_MAX = 72;
    {$EXTERNALSYM _SC_TTY_NAME_MAX}
    _SC_THREAD_DESTRUCTOR_ITERATIONS = 73;
    {$EXTERNALSYM _SC_THREAD_DESTRUCTOR_ITERATIONS}
    _SC_THREAD_KEYS_MAX = 74;
    {$EXTERNALSYM _SC_THREAD_KEYS_MAX}
    _SC_THREAD_STACK_MIN = 75;
    {$EXTERNALSYM _SC_THREAD_STACK_MIN}
    _SC_THREAD_THREADS_MAX = 76;
    {$EXTERNALSYM _SC_THREAD_THREADS_MAX}
    _SC_THREAD_ATTR_STACKADDR = 77;
    {$EXTERNALSYM _SC_THREAD_ATTR_STACKADDR}
    _SC_THREAD_ATTR_STACKSIZE = 78;
    {$EXTERNALSYM _SC_THREAD_ATTR_STACKSIZE}
    _SC_THREAD_PRIORITY_SCHEDULING = 79;
    {$EXTERNALSYM _SC_THREAD_PRIORITY_SCHEDULING}
    _SC_THREAD_PRIO_INHERIT = 80;
    {$EXTERNALSYM _SC_THREAD_PRIO_INHERIT}
    _SC_THREAD_PRIO_PROTECT = 81;
    {$EXTERNALSYM _SC_THREAD_PRIO_PROTECT}
    _SC_THREAD_PROCESS_SHARED = 82;
    {$EXTERNALSYM _SC_THREAD_PROCESS_SHARED}

    _SC_NPROCESSORS_CONF = 83;
    {$EXTERNALSYM _SC_NPROCESSORS_CONF}
    _SC_NPROCESSORS_ONLN = 84;
    {$EXTERNALSYM _SC_NPROCESSORS_ONLN}
    _SC_PHYS_PAGES = 85;
    {$EXTERNALSYM _SC_PHYS_PAGES}
    _SC_AVPHYS_PAGES = 86;
    {$EXTERNALSYM _SC_AVPHYS_PAGES}
    _SC_ATEXIT_MAX = 87;
    {$EXTERNALSYM _SC_ATEXIT_MAX}
    _SC_PASS_MAX = 88;
    {$EXTERNALSYM _SC_PASS_MAX}

    _SC_XOPEN_VERSION = 89;
    {$EXTERNALSYM _SC_XOPEN_VERSION}
    _SC_XOPEN_XCU_VERSION = 90;
    {$EXTERNALSYM _SC_XOPEN_XCU_VERSION}
    _SC_XOPEN_UNIX = 91;
    {$EXTERNALSYM _SC_XOPEN_UNIX}
    _SC_XOPEN_CRYPT = 92;
    {$EXTERNALSYM _SC_XOPEN_CRYPT}
    _SC_XOPEN_ENH_I18N = 93;
    {$EXTERNALSYM _SC_XOPEN_ENH_I18N}
    _SC_XOPEN_SHM = 94;
    {$EXTERNALSYM _SC_XOPEN_SHM}

    _SC_2_CHAR_TERM = 95;
    {$EXTERNALSYM _SC_2_CHAR_TERM}
    _SC_2_C_VERSION = 96;
    {$EXTERNALSYM _SC_2_C_VERSION}
    _SC_2_UPE = 97;
    {$EXTERNALSYM _SC_2_UPE}

    _SC_XOPEN_XPG2 = 98;
    {$EXTERNALSYM _SC_XOPEN_XPG2}
    _SC_XOPEN_XPG3 = 99;
    {$EXTERNALSYM _SC_XOPEN_XPG3}
    _SC_XOPEN_XPG4 = 100;
    {$EXTERNALSYM _SC_XOPEN_XPG4}

    _SC_CHAR_BIT = 101;
    {$EXTERNALSYM _SC_CHAR_BIT}
    _SC_CHAR_MAX = 102;
    {$EXTERNALSYM _SC_CHAR_MAX}
    _SC_CHAR_MIN = 103;
    {$EXTERNALSYM _SC_CHAR_MIN}
    _SC_INT_MAX = 104;
    {$EXTERNALSYM _SC_INT_MAX}
    _SC_INT_MIN = 105;
    {$EXTERNALSYM _SC_INT_MIN}
    _SC_LONG_BIT = 106;
    {$EXTERNALSYM _SC_LONG_BIT}
    _SC_WORD_BIT = 107;
    {$EXTERNALSYM _SC_WORD_BIT}
    _SC_MB_LEN_MAX = 108;
    {$EXTERNALSYM _SC_MB_LEN_MAX}
    _SC_NZERO = 109;
    {$EXTERNALSYM _SC_NZERO}
    _SC_SSIZE_MAX = 110;
    {$EXTERNALSYM _SC_SSIZE_MAX}
    _SC_SCHAR_MAX = 111;
    {$EXTERNALSYM _SC_SCHAR_MAX}
    _SC_SCHAR_MIN = 112;
    {$EXTERNALSYM _SC_SCHAR_MIN}
    _SC_SHRT_MAX = 113;
    {$EXTERNALSYM _SC_SHRT_MAX}
    _SC_SHRT_MIN = 114;
    {$EXTERNALSYM _SC_SHRT_MIN}
    _SC_UCHAR_MAX = 115;
    {$EXTERNALSYM _SC_UCHAR_MAX}
    _SC_UINT_MAX = 116;
    {$EXTERNALSYM _SC_UINT_MAX}
    _SC_ULONG_MAX = 117;
    {$EXTERNALSYM _SC_ULONG_MAX}
    _SC_USHRT_MAX = 118;
    {$EXTERNALSYM _SC_USHRT_MAX}

    _SC_NL_ARGMAX = 119;
    {$EXTERNALSYM _SC_NL_ARGMAX}
    _SC_NL_LANGMAX = 120;
    {$EXTERNALSYM _SC_NL_LANGMAX}
    _SC_NL_MSGMAX = 121;
    {$EXTERNALSYM _SC_NL_MSGMAX}
    _SC_NL_NMAX = 122;
    {$EXTERNALSYM _SC_NL_NMAX}
    _SC_NL_SETMAX = 123;
    {$EXTERNALSYM _SC_NL_SETMAX}
    _SC_NL_TEXTMAX = 124;
    {$EXTERNALSYM _SC_NL_TEXTMAX}

    _SC_XBS5_ILP32_OFF32 = 125;
    {$EXTERNALSYM _SC_XBS5_ILP32_OFF32}
    _SC_XBS5_ILP32_OFFBIG = 126;
    {$EXTERNALSYM _SC_XBS5_ILP32_OFFBIG}
    _SC_XBS5_LP64_OFF64 = 127;
    {$EXTERNALSYM _SC_XBS5_LP64_OFF64}
    _SC_XBS5_LPBIG_OFFBIG = 128;
    {$EXTERNALSYM _SC_XBS5_LPBIG_OFFBIG}

    _SC_XOPEN_LEGACY = 129;
    {$EXTERNALSYM _SC_XOPEN_LEGACY}
    _SC_XOPEN_REALTIME = 130;
    {$EXTERNALSYM _SC_XOPEN_REALTIME}
    _SC_XOPEN_REALTIME_THREADS = 131;
    {$EXTERNALSYM _SC_XOPEN_REALTIME_THREADS}

    _SC_ADVISORY_INFO = 132;
    {$EXTERNALSYM _SC_ADVISORY_INFO}
    _SC_BARRIERS = 133;
    {$EXTERNALSYM _SC_BARRIERS}
    _SC_BASE = 134;
    {$EXTERNALSYM _SC_BASE}
    _SC_C_LANG_SUPPORT = 135;
    {$EXTERNALSYM _SC_C_LANG_SUPPORT}
    _SC_C_LANG_SUPPORT_R = 136;
    {$EXTERNALSYM _SC_C_LANG_SUPPORT_R}
    _SC_CLOCK_SELECTION = 137;
    {$EXTERNALSYM _SC_CLOCK_SELECTION}
    _SC_CPUTIME = 138;
    {$EXTERNALSYM _SC_CPUTIME}
    _SC_THREAD_CPUTIME = 139;
    {$EXTERNALSYM _SC_THREAD_CPUTIME}
    _SC_DEVICE_IO = 140;
    {$EXTERNALSYM _SC_DEVICE_IO}
    _SC_DEVICE_SPECIFIC = 141;
    {$EXTERNALSYM _SC_DEVICE_SPECIFIC}
    _SC_DEVICE_SPECIFIC_R = 142;
    {$EXTERNALSYM _SC_DEVICE_SPECIFIC_R}
    _SC_FD_MGMT = 143;
    {$EXTERNALSYM _SC_FD_MGMT}
    _SC_FIFO = 144;
    {$EXTERNALSYM _SC_FIFO}
    _SC_PIPE = 145;
    {$EXTERNALSYM _SC_PIPE}
    _SC_FILE_ATTRIBUTES = 146;
    {$EXTERNALSYM _SC_FILE_ATTRIBUTES}
    _SC_FILE_LOCKING = 147;
    {$EXTERNALSYM _SC_FILE_LOCKING}
    _SC_FILE_SYSTEM = 148;
    {$EXTERNALSYM _SC_FILE_SYSTEM}
    _SC_MONOTONIC_CLOCK = 149;
    {$EXTERNALSYM _SC_MONOTONIC_CLOCK}
    _SC_MULTIPLE_PROCESS = 150;
    {$EXTERNALSYM _SC_MULTIPLE_PROCESS}
    _SC_SINGLE_PROCESS = 151;
    {$EXTERNALSYM _SC_SINGLE_PROCESS}
    _SC_NETWORKING = 152;
    {$EXTERNALSYM _SC_NETWORKING}
    _SC_READER_WRITER_LOCKS = 153;
    {$EXTERNALSYM _SC_READER_WRITER_LOCKS}
    _SC_SPIN_LOCKS = 154;
    {$EXTERNALSYM _SC_SPIN_LOCKS}
    _SC_REGEXP = 155;
    {$EXTERNALSYM _SC_REGEXP}
    _SC_REGEX_VERSION = 156;
    {$EXTERNALSYM _SC_REGEX_VERSION}
    _SC_SHELL = 157;
    {$EXTERNALSYM _SC_SHELL}
    _SC_SIGNALS = 158;
    {$EXTERNALSYM _SC_SIGNALS}
    _SC_SPAWN = 159;
    {$EXTERNALSYM _SC_SPAWN}
    _SC_SPORADIC_SERVER = 160;
    {$EXTERNALSYM _SC_SPORADIC_SERVER}
    _SC_THREAD_SPORADIC_SERVER = 161;
    {$EXTERNALSYM _SC_THREAD_SPORADIC_SERVER}
    _SC_SYSTEM_DATABASE = 162;
    {$EXTERNALSYM _SC_SYSTEM_DATABASE}
    _SC_SYSTEM_DATABASE_R = 163;
    {$EXTERNALSYM _SC_SYSTEM_DATABASE_R}
    _SC_TIMEOUTS = 164;
    {$EXTERNALSYM _SC_TIMEOUTS}
    _SC_TYPED_MEMORY_OBJECTS = 165;
    {$EXTERNALSYM _SC_TYPED_MEMORY_OBJECTS}
    _SC_USER_GROUPS = 166;
    {$EXTERNALSYM _SC_USER_GROUPS}
    _SC_USER_GROUPS_R = 167;
    {$EXTERNALSYM _SC_USER_GROUPS_R}
    _SC_PBS = 168;
    {$EXTERNALSYM _SC_PBS}
    _SC_PBS_ACCOUNTING = 169;
    {$EXTERNALSYM _SC_PBS_ACCOUNTING}
    _SC_PBS_LOCATE = 170;
    {$EXTERNALSYM _SC_PBS_LOCATE}
    _SC_PBS_MESSAGE = 171;
    {$EXTERNALSYM _SC_PBS_MESSAGE}
    _SC_PBS_TRACK = 172;
    {$EXTERNALSYM _SC_PBS_TRACK}
    _SC_SYMLOOP = 173;
    {$EXTERNALSYM _SC_SYMLOOP}


{  Values for the NAME argument to `confstr'.  }

    _CS_PATH = 0;               {  The default search path.  }
    {$EXTERNALSYM _CS_PATH}

    _CS_LFS_CFLAGS = 1000;
    {$EXTERNALSYM _CS_LFS_CFLAGS}
    _CS_LFS_LDFLAGS = 1001;
    {$EXTERNALSYM _CS_LFS_LDFLAGS}
    _CS_LFS_LIBS = 1002;
    {$EXTERNALSYM _CS_LFS_LIBS}
    _CS_LFS_LINTFLAGS = 1003;
    {$EXTERNALSYM _CS_LFS_LINTFLAGS}
    _CS_LFS64_CFLAGS = 1004;
    {$EXTERNALSYM _CS_LFS64_CFLAGS}
    _CS_LFS64_LDFLAGS = 1005;
    {$EXTERNALSYM _CS_LFS64_LDFLAGS}
    _CS_LFS64_LIBS = 1006;
    {$EXTERNALSYM _CS_LFS64_LIBS}
    _CS_LFS64_LINTFLAGS = 1007;
    {$EXTERNALSYM _CS_LFS64_LINTFLAGS}

    _CS_XBS5_ILP32_OFF32_CFLAGS = 1100;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFF32_CFLAGS}
    _CS_XBS5_ILP32_OFF32_LDFLAGS = 1101;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFF32_LDFLAGS}
    _CS_XBS5_ILP32_OFF32_LIBS = 1102;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFF32_LIBS}
    _CS_XBS5_ILP32_OFF32_LINTFLAGS = 1103;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFF32_LINTFLAGS}
    _CS_XBS5_ILP32_OFFBIG_CFLAGS = 1104;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFFBIG_CFLAGS}
    _CS_XBS5_ILP32_OFFBIG_LDFLAGS = 1105;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFFBIG_LDFLAGS}
    _CS_XBS5_ILP32_OFFBIG_LIBS = 1106;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFFBIG_LIBS}
    _CS_XBS5_ILP32_OFFBIG_LINTFLAGS = 1107;
    {$EXTERNALSYM _CS_XBS5_ILP32_OFFBIG_LINTFLAGS}
    _CS_XBS5_LP64_OFF64_CFLAGS = 1108;
    {$EXTERNALSYM _CS_XBS5_LP64_OFF64_CFLAGS}
    _CS_XBS5_LP64_OFF64_LDFLAGS = 1109;
    {$EXTERNALSYM _CS_XBS5_LP64_OFF64_LDFLAGS}
    _CS_XBS5_LP64_OFF64_LIBS = 1110;
    {$EXTERNALSYM _CS_XBS5_LP64_OFF64_LIBS}
    _CS_XBS5_LP64_OFF64_LINTFLAGS = 1111;
    {$EXTERNALSYM _CS_XBS5_LP64_OFF64_LINTFLAGS}
    _CS_XBS5_LPBIG_OFFBIG_CFLAGS = 1112;
    {$EXTERNALSYM _CS_XBS5_LPBIG_OFFBIG_CFLAGS}
    _CS_XBS5_LPBIG_OFFBIG_LDFLAGS = 1113;
    {$EXTERNALSYM _CS_XBS5_LPBIG_OFFBIG_LDFLAGS}
    _CS_XBS5_LPBIG_OFFBIG_LIBS = 1114;
    {$EXTERNALSYM _CS_XBS5_LPBIG_OFFBIG_LIBS}
    _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS = 1115;
    {$EXTERNALSYM _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS}

    
// Translated from unistd.h

const
{ Standard file descriptors.  }
  STDIN_FILENO    = 0;      { Standard input.  }
  {$EXTERNALSYM STDIN_FILENO}
  STDOUT_FILENO   = 1;      { Standard output.  }
  {$EXTERNALSYM STDOUT_FILENO}
  STDERR_FILENO   = 2;      { Standard error output.  }
  {$EXTERNALSYM STDERR_FILENO}

{ All functions that are not declared anywhere else.  }

const
{ Values for the second argument to access.
   These may be OR'd together.  }
  R_OK    = 4;              { Test for read permission.  }
  {$EXTERNALSYM R_OK}
  W_OK    = 2;              { Test for write permission.  }
  {$EXTERNALSYM W_OK}
  X_OK    = 1;              { Test for execute permission.  }
  {$EXTERNALSYM X_OK}
  F_OK    = 0;              { Test for existence.  }
  {$EXTERNALSYM F_OK}

{ Test for access to NAME using the real UID and real GID.  }
function access(Name: PChar; Mode: Integer): Integer; cdecl;
{$EXTERNALSYM access}

{ Test for access to NAME using the effective UID and GID
   (as normal file operations use).  }
function euidaccess(Name: PChar; Mode: Integer): Integer; cdecl;
{$EXTERNALSYM euidaccess}


{ Values for the WHENCE argument to lseek.  }
const
  SEEK_SET        = 0;      { Seek from beginning of file.  }
  {$EXTERNALSYM SEEK_SET}
  SEEK_CUR        = 1;      { Seek from current position.  }
  {$EXTERNALSYM SEEK_CUR}
  SEEK_END        = 2;      { Seek from end of file.  }
  {$EXTERNALSYM SEEK_END}

{ Old BSD names for the same constants; just for compatibility.  }
  L_SET           = SEEK_SET;
  {$EXTERNALSYM L_SET}
  L_INCR          = SEEK_CUR;
  {$EXTERNALSYM L_INCR}
  L_XTND          = SEEK_END;
  {$EXTERNALSYM L_XTND}

{ Move FD's file position to OFFSET bytes from the
   beginning of the file (if WHENCE is SEEK_SET),
   the current position (if WHENCE is SEEK_CUR),
   or the end of the file (if WHENCE is SEEK_END).
   Return the new file position.  }
function lseek(Handle, Offset, Direction: Integer): __off_t; cdecl;
{$EXTERNALSYM lseek}
function __lseek(Handle, Offset, Direction: Integer): __off_t; cdecl;
{$EXTERNALSYM __lseek}

function lseek64(FileDes: Integer; Offset: Int64; Whence: Integer): __off64_t; cdecl;
{$EXTERNALSYM lseek64}
(* Declared but not defined
function __lseek64(FileDes: Integer; Offset: Int64; Whence: Integer): __off64_t; cdecl;
{$EXTERNALSYM __lseek64}
*)

{ Close the file descriptor FD.  }
// HTI - Do not publish "Libc.close" - conflicts with "System.Close"
function __close(Handle: Integer): Integer; cdecl;
{.$EXTERNALSYM __close}

{ Read NBYTES into BUF from FD.  Return the
   number read, -1 for errors or 0 for EOF.  }
// HTI - Do not publish "Libc.read" - conflicts with "System.read"
function __read(Handle: Integer; var Buffer; Count: size_t): ssize_t; cdecl;
{.$EXTERNALSYM __read}

{ Write N bytes of BUF to FD.  Return the number written, or -1.  }
// HTI - Do not publish "Libc.write" - conflicts with "System.write"
function __write(Handle: Integer; const Buffer; Count: size_t): ssize_t; cdecl;
{.$EXTERNALSYM __write}

function pread(__fd: Integer; var Buffer; __nbytes: size_t; __offset: __off_t): ssize_t; cdecl;
{$EXTERNALSYM pread}

function pwrite(__fd: Integer; const Buffer; __n: size_t; __offset: __off_t): ssize_t; cdecl;
{$EXTERNALSYM pwrite}

{ Read NBYTES into BUF from FD at the given position OFFSET without
   changing the file pointer.  Return the number read, -1 for errors
   or 0 for EOF.  }
function pread64(FileDes: Integer; Buf: Pointer; NBytes: size_t;
  Offset: __off64_t): ssize_t; cdecl;
{$EXTERNALSYM pread64}
function __pread64(FileDes: Integer; Buf: Pointer; NBytes: size_t;
  Offset: __off64_t): ssize_t; cdecl;
{$EXTERNALSYM __pread64}

{ Write N bytes of BUF to FD at the given position OFFSET without
   changing the file pointer.  Return the number written, or -1.  }
function pwrite64(FileDes: Integer; const Buf: Pointer; N: LongWord;
  Offset: Int64): Integer; cdecl;
{$EXTERNALSYM pwrite64}
function __pwrite64(FileDes: Integer; const Buf: Pointer; N: LongWord;
  Offset: Int64): Integer; cdecl;
{$EXTERNALSYM __pwrite64}

{ Create a one-way communication channel (pipe).
   If successful, two file descriptors are stored in PIPEDES;
   bytes written on PIPEDES[1] can be read from PIPEDES[0].
   Returns 0 if successful, -1 if not.  }
function pipe(PipeDes: PInteger): Integer; cdecl; overload;
{$EXTERNALSYM pipe}

type
  TPipeDescriptors = {packed} record
    ReadDes: Integer;
    WriteDes: Integer;
  end;

function pipe(var PipeDes: TPipeDescriptors): Integer; cdecl; overload;

{ Schedule an alarm.  In SECONDS seconds, the process will get a SIGALRM.
   If SECONDS is zero, any currently scheduled alarm will be cancelled.
   The function returns the number of seconds remaining until the last
   alarm scheduled would have signaled, or zero if there wasn't one.
   There is no return value to indicate an error, but you can set `errno'
   to 0 and check its value after calling `alarm', and this might tell you.
   The signal may come late due to processor scheduling.  }
function alarm(Seconds: Cardinal): Cardinal; cdecl;
{$EXTERNALSYM alarm}

{ Make the process sleep for SECONDS seconds, or until a signal arrives
   and is not ignored.  The function returns the number of seconds less
   than SECONDS which it actually slept (thus zero if it slept the full time).
   If a signal handler does a `longjmp' or modifies the handling of the
   SIGALRM signal while inside `sleep' call, the handling of the SIGALRM
   signal afterwards is undefined.  There is no return value to indicate
   error, but if `sleep' returns SECONDS, it probably didn't work.

   Renamed to __sleep to avoid confusion with milliseconds based Sleep in SysUtils.}

function __sleep(Seconds: Cardinal): Cardinal; cdecl;
{.$EXTERNALSYM __sleep}

{ Set an alarm to go off (generating a SIGALRM signal) in VALUE
   microseconds.  If INTERVAL is nonzero, when the alarm goes off, the
   timer is reset to go off every INTERVAL microseconds thereafter.
   Returns the number of microseconds remaining before the alarm.  }
function ualarm(Value: __useconds_t; Interval: __useconds_t): __useconds_t; cdecl;
{$EXTERNALSYM ualarm}

{ Sleep USECONDS microseconds, or until a signal arrives that is not blocked
   or ignored.  }
procedure usleep(useconds: __useconds_t); cdecl;
{$EXTERNALSYM usleep}


{ Suspend the process until a signal arrives.
   This always returns -1 and sets `errno' to EINTR.  }
function pause: Integer; cdecl;
{$EXTERNALSYM pause}


{ Change the owner and group of FILE.  }
function chown(FileName: PChar; Owner: __uid_t; Group: __gid_t): Integer; cdecl;
{$EXTERNALSYM chown}

{ Change the owner and group of the file that FD is open on.  }
function fchown(FileDes: Integer; Owner: __uid_t; Group: __gid_t): Integer; cdecl;
{$EXTERNALSYM fchown}

{ Change owner and group of FILE, if it is a symbolic
   link the ownership of the symbolic link is changed.  }
function lchown(const FileName: PChar; Owner: __uid_t; Group: __gid_t): Integer; cdecl;
{$EXTERNALSYM lchown}

{ Change the process's working directory to PATH.  }
// HTI - Renamed from "chdir" to "__chdir"
function __chdir(PathName: PChar): Integer; cdecl;
{ $EXTERNALSYM chdir}

{ Change the process's working directory to the one FD is open on.  }
function fchdir(FileDes: Integer): Integer; cdecl;
{$EXTERNALSYM fchdir}

{ Get the pathname of the current working directory,
   and put it in SIZE bytes of BUF.  Returns NULL if the
   directory couldn't be determined or SIZE was too small.
   If successful, returns BUF.  In GNU, if BUF is NULL,
   an array is allocated with `malloc'; the array is SIZE
   bytes long, unless SIZE == 0, in which case it is as
   big as necessary.  }
function getcwd(Buffer: PChar; BufSize: size_t): PChar; cdecl;
{$EXTERNALSYM getcwd}

{ Return a malloc'd string containing the current directory name.
   If the environment variable `PWD' is set, and its value is correct,
   that value is used.  }
function get_current_dir_name: PChar; cdecl;
{$EXTERNALSYM get_current_dir_name}

{ Put the absolute pathname of the current working directory in BUF.
   If successful, return BUF.  If not, put an error message in
   BUF and return NULL.  BUF should be at least PATH_MAX bytes long.  }
function getwd(Buf: PChar): PChar; cdecl;
{$EXTERNALSYM getwd}


{ Duplicate FD, returning a new file descriptor on the same file.  }
function dup(FileDes: Integer): Integer; cdecl;
{$EXTERNALSYM dup}

{ Duplicate FD to FD2, closing FD2 and making it open on the same file.  }
function dup2(FileDes: Integer; FileDes2: Integer): Integer; cdecl;
{$EXTERNALSYM dup2}

{ Replace the current process, executing PATH with arguments ARGV and
   environment ENVP.  ARGV and ENVP are terminated by NULL pointers.  }
function execve(PathName: PChar; const argv: PPChar;
  const envp: PPChar): Integer; cdecl;
{$EXTERNALSYM execve}

{ Execute the file FD refers to, overlaying the running program image.
   ARGV and ENVP are passed to the new program, as for `execve'.  }
function fexecve(FileDes: Integer; const argv: PPChar;
  const envp: PPChar): Integer; cdecl;
{$EXTERNALSYM fexecve}

{ Execute PATH with arguments ARGV and environment from `environ'.  }
function execv(PathName: PChar; const argv: PPChar): Integer; cdecl;
{$EXTERNALSYM execv}

{ Execute PATH with all arguments after PATH until a NULL pointer,
   and the argument after that for environment.  }
function execle(__path: PChar; __arg: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM execle}

{ Execute PATH with all arguments after PATH until
   a NULL pointer and environment from `environ'.  }
function execl(__path: PChar; __arg: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM execl}

{ Execute FILE, searching in the `PATH' environment variable if it contains
   no slashes, with arguments ARGV and environment from `environ'.  }
function execvp(const FileName: PChar; const argv: PPChar): Integer; cdecl;
{$EXTERNALSYM execvp}

{ Execute FILE, searching in the `PATH' environment variable if
   it contains no slashes, with all arguments after FILE until a
   NULL pointer and environment from `environ'.  }
function execlp(__file: PChar; __arg: PChar): Integer; cdecl; varargs;
{$EXTERNALSYM execlp}


{ Add INC to priority of the current process.  }
function nice(inc: Integer): Integer; cdecl;
{$EXTERNALSYM nice}

//{ Terminate program execution with the low-order 8 bits of STATUS.  }
//extern void _exit (int __status) __attribute__ ((__noreturn__));


{ Get file-specific configuration information about PATH.  }
function pathconf(PathName: PChar; Name: Integer): Longint; cdecl;
{$EXTERNALSYM pathconf}

{ Get file-specific configuration about descriptor FD.  }
function fpathconf(FileDes: Integer; Name: Integer): Longint; cdecl;
{$EXTERNALSYM fpathconf}

{ Get the value of the system variable NAME.  }
function sysconf(Name: Integer): Longint; cdecl;
{$EXTERNALSYM sysconf}

{ Get the value of the string-valued system variable NAME.  }
function confstr(Name: Integer; Buf: PChar; Len: size_t): size_t; cdecl;
{$EXTERNALSYM confstr}

{ Get the process ID of the calling process.  }
function getpid: __pid_t; cdecl;
{$EXTERNALSYM getpid}

{ Get the process ID of the calling process's parent.  }
function getppid: __pid_t; cdecl;
{$EXTERNALSYM getppid}

{ Get the process group ID of the calling process.
   This function is different on old BSD. }
function getpgrp: __pid_t; cdecl;
{$EXTERNALSYM getpgrp}

{ Get the process group ID of process PID.  }
function __getpgid(ProcessID: __pid_t): __pid_t; cdecl;
{$EXTERNALSYM __getpgid}
function getpgid(ProcessID: __pid_t): __pid_t; cdecl;
{$EXTERNALSYM getpgid}


{ Set the process group ID of the process matching PID to PGID.
   If PID is zero, the current process's process group ID is set.
   If PGID is zero, the process ID of the process is used.  }
function setpgid(ProcessID: __pid_t; ProcessGrpID: __pid_t): Integer; cdecl;
{$EXTERNALSYM setpgid}

{ Both System V and BSD have `setpgrp' functions, but with different
   calling conventions.  The BSD function is the same as POSIX.1 `setpgid'
   (above).  The System V function takes no arguments and puts the calling
   process in its on group like `setpgid (0, 0)'.

   New programs should always use `setpgid' instead.

   The default in GNU is to provide the System V function.  The BSD
   function is available under -D_BSD_SOURCE.  }

{ Set the process group ID of the calling process to its own PID.
   This is exactly the same as `setpgid (0, 0)'.  }
function setpgrp: Integer; cdecl;
{$EXTERNALSYM setpgrp}

{ Create a new session with the calling process as its leader.
   The process group IDs of the session and the calling process
   are set to the process ID of the calling process, which is returned.  }
function setsid: __pid_t; cdecl;
{$EXTERNALSYM setsid}

{ Return the session ID of the given process.  }
function getsid(ProcessID: __pid_t): __pid_t; cdecl;
{$EXTERNALSYM getsid}

{ Get the real user ID of the calling process.  }
function getuid: __uid_t; cdecl;
{$EXTERNALSYM getuid}

{ Get the effective user ID of the calling process.  }
function geteuid: __uid_t; cdecl;
{$EXTERNALSYM geteuid}

{ Get the real group ID of the calling process.  }
function getgid: __gid_t; cdecl;
{$EXTERNALSYM getgid}

{ Get the effective group ID of the calling process.  }
function getegid: __gid_t; cdecl;
{$EXTERNALSYM getegid}

{ If SIZE is zero, return the number of supplementary groups
   the calling process is in.  Otherwise, fill in the group IDs
   of its supplementary groups in LIST and return the number written.  }
type
  PGid = ^__gid_t; // Not present in header file; used as __gid_t __list[]

function getgroups(Size: Integer; List: PGid): Integer; cdecl;
{$EXTERNALSYM getgroups}

{ Return nonzero iff the calling process is in group GID.  }
function group_member(GroupID: __gid_t): Integer; cdecl;
{$EXTERNALSYM group_member}

{ Set the user ID of the calling process to UID.
   If the calling process is the super-user, set the real
   and effective user IDs, and the saved set-user-ID to UID;
   if not, the effective user ID is set to UID.  }
function setuid(UID: __uid_t): Integer; cdecl;
{$EXTERNALSYM setuid}

{ Set the real user ID of the calling process to RUID,
   and the effective user ID of the calling process to EUID.  }
function setreuid(RUID: __uid_t; EUID: __uid_t): Integer; cdecl;
{$EXTERNALSYM setreuid}

{ Set the effective user ID of the calling process to UID.  }
function seteuid(UID: __uid_t): Integer; cdecl;
{$EXTERNALSYM seteuid}

{ Set the group ID of the calling process to GID.
   If the calling process is the super-user, set the real
   and effective group IDs, and the saved set-group-ID to GID;
   if not, the effective group ID is set to GID.  }
function setgid(GroupID: __gid_t): Integer; cdecl;
{$EXTERNALSYM setgid}

function setregid(RGID: __gid_t; EGID: __gid_t): Integer; cdecl;
{$EXTERNALSYM setregid}

{ Set the effective group ID of the calling process to GID.  }
function setegid(GroupID: __gid_t): Integer; cdecl;
{$EXTERNALSYM setegid}

{ Clone the calling process, creating an exact copy.
   Return -1 for errors, 0 to the new process,
   and the process ID of the new process to the old process.  }
function fork: __pid_t; cdecl;
{$EXTERNALSYM fork}

{ Clone the calling process, but without copying the whole address space.
   The calling process is suspended until the new process exits or is
   replaced by a call to `execve'.  Return -1 for errors, 0 to the new process,
   and the process ID of the new process to the old process.  }
function vfork: __pid_t; cdecl;
{$EXTERNALSYM vfork}

{ Return the pathname of the terminal FD is open on, or NULL on errors.
   The returned storage is good only until the next call to this function.  }
function ttyname(FileDes: Integer): PChar; cdecl;
{$EXTERNALSYM ttyname}

{ Store at most BUFLEN characters of the pathname of the terminal FD is
   open on in BUF.  Return 0 on success, otherwise an error number.  }
function ttyname_r(FileDes: Integer; Buf: PChar; BufLen: size_t): Integer; cdecl;
{$EXTERNALSYM ttyname_r}

{ Return 1 if FD is a valid descriptor associated
   with a terminal, zero if not.  }
function isatty(FileDes: Integer): Integer; cdecl;
{$EXTERNALSYM isatty}

{ Return the index into the active-logins file (utmp) for
   the controlling terminal.  }
function ttyslot: Integer; cdecl;
{$EXTERNALSYM ttyslot}

{ Make a link to FROM named TO.  }
function link(FromName, ToName: PChar): Integer; cdecl;
{$EXTERNALSYM link}

{ Make a symbolic link to FROM named TO.  }
function symlink(FromName, ToName: PChar): Integer; cdecl;
{$EXTERNALSYM symlink}

{ Read the contents of the symbolic link PATH into no more than
   LEN bytes of BUF.  The contents are not null-terminated.
   Returns the number of characters read, or -1 for errors.  }
function readlink(PathName: PChar; Buf: PChar; Len: size_t): Integer; cdecl;
{$EXTERNALSYM readlink}

{ Remove the link NAME.  }
function unlink(const Name: PChar): Integer; cdecl;
{$EXTERNALSYM unlink}

{ Remove the directory PATH.  }
// HTI - Renamed from "rmdir" to "__rmdir"
function __rmdir(PathName: PChar): Integer; cdecl;
{ $EXTERNALSYM rmdir}

{ Return the foreground process group ID of FD.  }
function tcgetpgrp(FileDes: Integer): __pid_t; cdecl;
{$EXTERNALSYM tcgetpgrp}

{ Set the foreground process group ID of FD set PGRP_ID.  }
function tcsetpgrp(FileDes: Integer; ProcessGrpID: __pid_t): Integer; cdecl;
{$EXTERNALSYM tcsetpgrp}

{ Return the login name of the user.  }
function getlogin: PChar; cdecl;
{$EXTERNALSYM getlogin}

{ Return at most NAME_LEN characters of the login name of the user in NAME.
   If it cannot be determined or some other error occurred, return the error
   code.  Otherwise return 0.  }
function getlogin_r(Name: PChar; NameLen: size_t): Integer; cdecl;
{$EXTERNALSYM getlogin_r}

{ Set the login name returned by `getlogin'.  }
function setlogin(const Name: PChar): Integer; cdecl;
{$EXTERNALSYM setlogin}


{ Put the name of the current host in no more than LEN bytes of NAME.
   The result is null-terminated if LEN is large enough for the full
   name and the terminator.  }
function gethostname(Name: PChar; Len: socklen_t): Integer; cdecl;
{$EXTERNALSYM gethostname}

{ Set the name of the current host to NAME, which is LEN bytes long.
   This call is restricted to the super-user.  }
function sethostname(const Name: PChar; Len: socklen_t): Integer; cdecl;
{$EXTERNALSYM sethostname}

{ Set the current machine's Internet number to ID.
   This call is restricted to the super-user.  }
function sethostid(ID: Longint): Integer; cdecl;
{$EXTERNALSYM sethostid}


{ Get and set the NIS (aka YP) domain name, if any.
   Called just like `gethostname' and `sethostname'.
   The NIS domain name is usually the empty string when not using NIS.  }
function getdomainname(Name: PChar; Len: size_t): Integer; cdecl;
{$EXTERNALSYM getdomainname}

function setdomainname(const Name: PChar; Len: size_t): Integer; cdecl;
{$EXTERNALSYM setdomainname}

{ Make all changes done to FD actually appear on disk.  }
function fsync(FileDes: Integer): Integer; cdecl;
{$EXTERNALSYM fsync}


{ Revoke access permissions to all processes currently communicating
   with the control terminal, and then send a SIGHUP signal to the process
   group of the control terminal.  }
function vhangup: Integer; cdecl;
{$EXTERNALSYM vhangup}

{ Revoke the access of all descriptors currently open on FILE.  }
function revoke(const FileName: PChar): Integer; cdecl;
{$EXTERNALSYM revoke}

{ Enable statistical profiling, writing samples of the PC into at most
   SIZE bytes of SAMPLE_BUFFER; every processor clock tick while profiling
   is enabled, the system examines the user PC and increments
   SAMPLE_BUFFER[((PC - OFFSET) / 2) * SCALE / 65536].  If SCALE is zero,
   disable profiling.  Returns zero on success, -1 on error.  }
function profil(__sample_buffer: PWord; Size: size_t; Offset: size_t;
  Scale: Cardinal): Integer; cdecl;
{$EXTERNALSYM profil}


{ Turn accounting on if NAME is an existing file.  The system will then write
   a record for each process as it terminates, to this file.  If NAME is NULL,
   turn accounting off.  This call is restricted to the super-user.  }
function acct(const Name: PChar): Integer; cdecl;
{$EXTERNALSYM acct}

{ Make PATH be the root directory (the starting point for absolute paths).
   This call is restricted to the super-user.  }
function chroot(PathName: PChar): Integer; cdecl;
{$EXTERNALSYM chroot}


{ Successive calls return the shells listed in `/etc/shells'.  }
function getusershell: PChar; cdecl;
{$EXTERNALSYM getusershell}
procedure endusershell; cdecl; { Discard cached info.  }
{$EXTERNALSYM endusershell}
procedure setusershell; cdecl; { Rewind and re-read the file.  }
{$EXTERNALSYM setusershell}


{ Prompt with PROMPT and read a string from the terminal without echoing.
   Uses /dev/tty if possible; otherwise stderr and stdin.  }
function getpass(Prompt: PChar): PChar; cdecl;
{$EXTERNALSYM getpass}

{ Put the program in the background, and dissociate from the controlling
   terminal.  If NOCHDIR is zero, do `chdir ("/")'.  If NOCLOSE is zero,
   redirects stdin, stdout, and stderr to /dev/null.  }
function daemon(NoChDir: Integer; NoClose: Integer): Integer; cdecl;
{$EXTERNALSYM daemon}

{ Return the current machine's Internet number.  }
function gethostid: Longint; cdecl;
{$EXTERNALSYM gethostid}

{ Make all changes done to all files actually appear on disk.  }
function sync: Integer; cdecl;
{$EXTERNALSYM sync}


{ Return the number of bytes in a page.  This is the system's page size,
   which is not necessarily the same as the hardware page size.  }
function getpagesize: Integer; cdecl;
{$EXTERNALSYM getpagesize}

{ Truncate FILE to LENGTH bytes.  }
function __truncate(const FileName: PChar; Length: __off_t): Integer; cdecl;
{$EXTERNALSYM __truncate}

function truncate64(const FileName: PChar; Length: __off64_t): Integer; cdecl;
{$EXTERNALSYM truncate64}

{ Truncate the file FD is open on to LENGTH bytes.  }
function ftruncate(FileDes: Integer; Length: __off_t): Integer; cdecl;
{$EXTERNALSYM ftruncate}

function ftruncate64(FileDes: Integer; Length: __off64_t): Integer; cdecl;
{$EXTERNALSYM ftruncate64}

{ Return the maximum number of file descriptors
   the current process could possibly have.  }
function getdtablesize: Integer; cdecl;
{$EXTERNALSYM getdtablesize}

{ Set the end of accessible data space (aka "the break") to ADDR.
   Returns zero on success and -1 for errors (with errno set).  }
function brk(Addr: Pointer): Integer; cdecl;
{$EXTERNALSYM brk}

{ Increase or decrease the end of accessible data space by DELTA bytes.
   If successful, returns the address the previous end of data space
   (i.e. the beginning of the new space, if DELTA > 0);
   returns (void *) -1 for errors (with errno set).  }
function sbrk(Delta: intptr_t): Pointer; cdecl;
{$EXTERNALSYM sbrk}


{ Invoke `system call' number SYSNO, passing it the remaining arguments.
   This is completely system-dependent, and not often useful.

   In Unix, `syscall' sets `errno' for all errors and most calls return -1
   for errors; in many systems you cannot pass arguments or get return
   values for all system calls (`pipe', `fork', and `getppid' typically
   among them).

   In Mach, all system calls take normal arguments and always return an
   error code (zero for success).  }

function syscall(SysNo: Longint): Integer; cdecl; varargs;
{$EXTERNALSYM syscall}

{ NOTE: These declarations also appear in <fcntl.h>; be sure to keep both
   files consistent.  Some systems have them there and some here, and some
   software depends on the macros being defined without including both.  }

{ `lockf' is a simpler interface to the locking facilities of `fcntl'.
   LEN is always relative to the current file position.
   The CMD argument is one of the following.  }

const
  F_ULOCK  = 0;     { Unlock a previously locked region.  }
  {$EXTERNALSYM F_ULOCK}
  F_LOCK   = 1;     { Lock a region for exclusive use.  }
  {$EXTERNALSYM F_LOCK}
  F_TLOCK  = 2;     { Test and lock a region for exclusive use.  }
  {$EXTERNALSYM F_TLOCK}
  F_TEST   = 3;     { Test a region for other processes locks.  }
  {$EXTERNALSYM F_TEST}

function lockf(FileDes: Integer; Cmd: Integer; Len: __off_t): Integer; cdecl;
{$EXTERNALSYM lockf}

function lockf64(FileDes: Integer; Cmd: Integer; Len: __off64_t): Integer; cdecl;
{$EXTERNALSYM lockf64}

// Cannot translate
//   TEMP_FAILURE_RETRY(expression)
// due to lack of text macros.

{ Synchronize at least the data part of a file with the underlying
   media.  }
function fdatasync(FileDes: Integer): Integer; cdecl;
{$EXTERNALSYM fdatasync}

{ XPG4.2 specifies that prototypes for the encryption functions must
   be defined here.  }
{ Encrypt at most 8 characters from KEY using salt to perturb DES.  }
function crypt(Key, Salt: PChar): PChar; cdecl;
{$EXTERNALSYM crypt}

{ Setup DES tables according KEY.  }
procedure setkey(Key: PChar); cdecl;
{$EXTERNALSYM setkey}

{ Encrypt data in BLOCK in place if EDFLAG is zero; otherwise decrypt
   block in place.  }
procedure encrypt(Block: PChar; EdFlag: Integer); cdecl;
{$EXTERNALSYM encrypt}


{ Swab pairs bytes in the first N bytes of the area pointed to by
   FROM and copy the result to TO.  The value of TO must not be in the
   range [FROM - N + 1, FROM - 1].  If N is odd the first byte in FROM
   is without partner.  }
procedure swab(FromBytes, ToBytes: Pointer; N: ssize_t); cdecl;
{$EXTERNALSYM swab}

// Declared in and translated for stdio.h
// extern char *ctermid (char *__s) __THROW;

// Declared in and translated for pthreads.h
// extern int pthread_atfork (void (*__prepare) (void),


// Translated from fstab.h

{
 * File system table, see fstab(5).
 *
 * Used by dump, mount, umount, swapon, fsck, df, ...
 *
 * For ufs fs_spec field is the block special name.  Programs that want to
 * use the character special name must create that name by prepending a 'r'
 * after the right most slash.  Quota files are always named "quotas", so
 * if type is "rq", then use concatenation of fs_file and "quotas" to locate
 * quota file.
 }
const
  _PATH_FSTAB     = '/etc/fstab';
  {$EXTERNALSYM _PATH_FSTAB}
  _FSTAB           = '/etc/fstab';   { deprecated }
  {$EXTERNALSYM _FSTAB}

  FSTAB_RW        = 'rw';           { read/write device }
  {$EXTERNALSYM FSTAB_RW}
  FSTAB_RQ        = 'rq';           { read/write with quotas }
  {$EXTERNALSYM FSTAB_RQ}
  FSTAB_RO        = 'ro';           { read-only device }
  {$EXTERNALSYM FSTAB_RO}
  FSTAB_SW        = 'sw';           { swap device }
  {$EXTERNALSYM FSTAB_SW}
  FSTAB_XX        = 'xx';           { ignore totally }
  {$EXTERNALSYM FSTAB_XX}

type
  fstab = {packed} record
    fs_spec: PChar;                     { block special device name }
    fs_file: PChar;                     { file system path prefix }
    fs_vfstype: PChar;                  { File system type, ufs, nfs }
    fs_mntops: PChar;                   { Mount options ala -o }
    fs_type: PChar;                     { FSTAB_* from fs_mntops }
    fs_freq: Integer;                   { dump frequency, in days }
    fs_passno: Integer;                 { pass number on parallel dump }
  end;
  {$EXTERNALSYM fstab}
  TFSTab = fstab;
  PFSTab = ^TFSTab;


function getfsent: Pfstab; cdecl;
{$EXTERNALSYM getfsent}
function getfsspec(const Name: PChar): PFSTab; cdecl;
{$EXTERNALSYM getfsspec}
function getfsfile(const Name: PChar): PFSTab; cdecl;
{$EXTERNALSYM getfsfile}
function setfsent: Integer; cdecl;
{$EXTERNALSYM setfsent}
procedure endfsent; cdecl;
{$EXTERNALSYM endfsent}

// Translated from mntent.h

{ File listing canonical interesting mount points.  }
const
  MNTTAB =        _PATH_MNTTAB;         { Deprecated alias.  }
  {$EXTERNALSYM MNTTAB}

{ File listing currently active mount points.  }
  MOUNTED =       _PATH_MOUNTED;        { Deprecated alias.  }
  {$EXTERNALSYM MOUNTED}

{ General filesystem types.  }
  MNTTYPE_IGNORE = 'ignore';            { Ignore this entry.  }
  {$EXTERNALSYM MNTTYPE_IGNORE}
  MNTTYPE_NFS    = 'nfs';               { Network file system.  }
  {$EXTERNALSYM MNTTYPE_NFS}
  MNTTYPE_SWAP   = 'swap';              { Swap device.  }
  {$EXTERNALSYM MNTTYPE_SWAP}


{ Generic mount options.  }
  MNTOPT_DEFAULTS = 'defaults';         { Use all default options.  }
  {$EXTERNALSYM MNTOPT_DEFAULTS}
  MNTOPT_RO       = 'ro';               { Read only.  }
  {$EXTERNALSYM MNTOPT_RO}
  MNTOPT_RW       = 'rw';               { Read/write.  }
  {$EXTERNALSYM MNTOPT_RW}
  MNTOPT_SUID     = 'suid';             { Set uid allowed.  }
  {$EXTERNALSYM MNTOPT_SUID}
  MNTOPT_NOSUID   = 'nosuid';           { No set uid allowed.  }
  {$EXTERNALSYM MNTOPT_NOSUID}
  MNTOPT_NOAUTO   = 'noauto';           { Do not auto mount.  }
  {$EXTERNALSYM MNTOPT_NOAUTO}


{ Structure describing a mount table entry.  }
type
  mntent = {packed} record
    mnt_fsname: PChar;                  { Device or server for filesystem.  }
    mnt_dir: PChar;                     { Directory mounted on.  }
    mnt_type: PChar;                    { Type of filesystem: ufs, nfs, etc.  }
    mnt_opts: PChar;                    { Comma-separated options for fs.  }
    mnt_freq: Integer;                  { Dump frequency (in days).  }
    mnt_passno: Integer;                { Pass number for `fsck'.  }
  end;
  {$EXTERNALSYM mntent}
  TMountEntry = mntent;
  PMountEntry = ^TMountEntry;

{ Prepare to begin reading and/or writing mount table entries from the
   beginning of FILE.  MODE is as for `fopen'.  }
function setmntent(__file: PChar; __mode: PChar): PIOFile; cdecl;
{$EXTERNALSYM setmntent}

{ Read one mount table entry from STREAM.  Returns a pointer to storage
   reused on the next call, or null for EOF or error (use feof/ferror to
   check).  }
function getmntent(__stream: PIOFile): PMountEntry; cdecl;
{$EXTERNALSYM getmntent}

{ Reentrant version of the above function.  }
function getmntent_r(__stream: PIOFile; var __result: TMountEntry; __buffer: PChar; __bufsize: Integer): PMountEntry; cdecl;
{$EXTERNALSYM getmntent_r}

{ Write the mount table entry described by MNT to STREAM.
   Return zero on success, nonzero on failure.  }
function addmntent(__stream: PIOFile; __mnt: PMountEntry): Integer; cdecl;
{$EXTERNALSYM addmntent}

{ Close a stream opened with `setmntent'.  }
function endmntent(__stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM endmntent}

{ Search MNT->mnt_opts for an option matching OPT.
   Returns the address of the substring, or null if none found.  }
function hasmntopt(__mnt: PMountEntry; __opt: PChar): PChar; cdecl;
{$EXTERNALSYM hasmntopt}


// Translated from bits/ioctls.h

const
{ Routing table calls.  }
  SIOCADDRT            = $890B;    { add routing table entry }
  {$EXTERNALSYM SIOCADDRT}
  SIOCDELRT            = $890C;    { delete routing table entry }
  {$EXTERNALSYM SIOCDELRT}
  SIOCRTMSG            = $890D;    { call to routing system }
  {$EXTERNALSYM SIOCRTMSG}

{ Socket configuration controls. }
  SIOCGIFNAME          = $8910;    { get iface name }
  {$EXTERNALSYM SIOCGIFNAME}
  SIOCSIFLINK          = $8911;    { set iface channel }
  {$EXTERNALSYM SIOCSIFLINK}
  SIOCGIFCONF          = $8912;    { get iface list }
  {$EXTERNALSYM SIOCGIFCONF}
  SIOCGIFFLAGS         = $8913;    { get flags }
  {$EXTERNALSYM SIOCGIFFLAGS}
  SIOCSIFFLAGS         = $8914;    { set flags }
  {$EXTERNALSYM SIOCSIFFLAGS}
  SIOCGIFADDR          = $8915;    { get PA address }
  {$EXTERNALSYM SIOCGIFADDR}
  SIOCSIFADDR          = $8916;    { set PA address }
  {$EXTERNALSYM SIOCSIFADDR}
  SIOCGIFDSTADDR       = $8917;    { get remote PA address }
  {$EXTERNALSYM SIOCGIFDSTADDR}
  SIOCSIFDSTADDR       = $8918;    { set remote PA address }
  {$EXTERNALSYM SIOCSIFDSTADDR}
  SIOCGIFBRDADDR       = $8919;    { get broadcast PA address }
  {$EXTERNALSYM SIOCGIFBRDADDR}
  SIOCSIFBRDADDR       = $891a;    { set broadcast PA address }
  {$EXTERNALSYM SIOCSIFBRDADDR}
  SIOCGIFNETMASK       = $891b;    { get network PA mask }
  {$EXTERNALSYM SIOCGIFNETMASK}
  SIOCSIFNETMASK       = $891c;    { set network PA mask }
  {$EXTERNALSYM SIOCSIFNETMASK}
  SIOCGIFMETRIC        = $891d;    { get metric }
  {$EXTERNALSYM SIOCGIFMETRIC}
  SIOCSIFMETRIC        = $891e;    { set metric }
  {$EXTERNALSYM SIOCSIFMETRIC}
  SIOCGIFMEM           = $891f;    { get memory address (BSD) }
  {$EXTERNALSYM SIOCGIFMEM}
  SIOCSIFMEM           = $8920;    { set memory address (BSD) }
  {$EXTERNALSYM SIOCSIFMEM}
  SIOCGIFMTU           = $8921;    { get MTU size }
  {$EXTERNALSYM SIOCGIFMTU}
  SIOCSIFMTU           = $8922;    { set MTU size }
  {$EXTERNALSYM SIOCSIFMTU}
  SIOCSIFHWADDR        = $8924;    { set hardware address }
  {$EXTERNALSYM SIOCSIFHWADDR}
  SIOCGIFENCAP         = $8925;    { get/set encapsulations }
  {$EXTERNALSYM SIOCGIFENCAP}
  SIOCSIFENCAP         = $8926;
  {$EXTERNALSYM SIOCSIFENCAP}
  SIOCGIFHWADDR        = $8927;    { Get hardware address }
  {$EXTERNALSYM SIOCGIFHWADDR}
  SIOCGIFSLAVE         = $8929;    { Driver slaving support }
  {$EXTERNALSYM SIOCGIFSLAVE}
  SIOCSIFSLAVE         = $8930;
  {$EXTERNALSYM SIOCSIFSLAVE}
  SIOCADDMULTI         = $8931;    { Multicast address lists }
  {$EXTERNALSYM SIOCADDMULTI}
  SIOCDELMULTI         = $8932;
  {$EXTERNALSYM SIOCDELMULTI}
  SIOCGIFINDEX         = $8933;    { name -> if_index mapping }
  {$EXTERNALSYM SIOCGIFINDEX}
  SIOGIFINDEX          = SIOCGIFINDEX; { misprint compatibility :-) }
  {$EXTERNALSYM SIOGIFINDEX}
  SIOCSIFPFLAGS        = $8934;    { set/get extended flags set }
  {$EXTERNALSYM SIOCSIFPFLAGS}
  SIOCGIFPFLAGS        = $8935;
  {$EXTERNALSYM SIOCGIFPFLAGS}
  SIOCDIFADDR          = $8936;    { delete PA address }
  {$EXTERNALSYM SIOCDIFADDR}
  SIOCSIFHWBROADCAST   = $8937;    { set hardware broadcast addr }
  {$EXTERNALSYM SIOCSIFHWBROADCAST}
  SIOCGIFCOUNT         = $8938;    { get number of devices }
  {$EXTERNALSYM SIOCGIFCOUNT}

  SIOCGIFBR            = $8940;    { Bridging support }
  {$EXTERNALSYM SIOCGIFBR}
  SIOCSIFBR            = $8941;    { Set bridging options }
  {$EXTERNALSYM SIOCSIFBR}

  SIOCGIFTXQLEN        = $8942;    { Get the tx queue length }
  {$EXTERNALSYM SIOCGIFTXQLEN}
  SIOCSIFTXQLEN        = $8943;    { Set the tx queue length }
  {$EXTERNALSYM SIOCSIFTXQLEN}


{ ARP cache control calls. }
{  = $8950 - = $8952  * obsolete calls, don't re-use }
  SIOCDARP             = $8953;    { delete ARP table entry }
  {$EXTERNALSYM SIOCDARP}
  SIOCGARP             = $8954;    { get ARP table entry }
  {$EXTERNALSYM SIOCGARP}
  SIOCSARP             = $8955;    { set ARP table entry }
  {$EXTERNALSYM SIOCSARP}

{ RARP cache control calls. }
  SIOCDRARP            = $8960;    { delete RARP table entry }
  {$EXTERNALSYM SIOCDRARP}
  SIOCGRARP            = $8961;    { get RARP table entry }
  {$EXTERNALSYM SIOCGRARP}
  SIOCSRARP            = $8962;    { set RARP table entry }
  {$EXTERNALSYM SIOCSRARP}

{ Driver configuration calls }

  SIOCGIFMAP           = $8970;    { Get device parameters }
  {$EXTERNALSYM SIOCGIFMAP}
  SIOCSIFMAP           = $8971;    { Set device parameters }
  {$EXTERNALSYM SIOCSIFMAP}

{ DLCI configuration calls }

  SIOCADDDLCI          = $8980;    { Create new DLCI device }
  {$EXTERNALSYM SIOCADDDLCI}
  SIOCDELDLCI          = $8981;    { Delete DLCI device	}
  {$EXTERNALSYM SIOCDELDLCI}

{ Device private ioctl calls.  }

{ These 16 ioctls are available to devices via the do_ioctl() device
   vector.  Each device should include this file and redefine these
   names as their own. Because these are device dependent it is a good
   idea _NOT_ to issue them to random objects and hope.  }

  SIOCDEVPRIVATE       = $89F0;    { to 89FF }
  {$EXTERNALSYM SIOCDEVPRIVATE}

{ These 16 ioctl calls are protocol private }

  SIOCPROTOPRIVATE     = $89E0;    { to 89EF }
  {$EXTERNALSYM SIOCPROTOPRIVATE}


// Translated from bits/ioctl-types.h

type
  winsize = {packed} record
    ws_row: Word;
    ws_col: Word;
    ws_xpixel: Word;
    ws_ypixel: Word;
  end;
  {$EXTERNALSYM winsize}
  TWinSize = winsize;
  PWinSize = ^TWinSize;

const
  NCC = 8;
  {$EXTERNALSYM NCC}

type
  termio = {packed} record
    c_iflag: Word;                        { input mode flags }
    c_oflag: Word;                        { output mode flags }
    c_cflag: Word;                        { control mode flags }
    c_lflag: Word;                        { local mode flags }
    c_line: Byte;                         { line discipline }
    c_cc: packed array[0..NCC-1] of Byte; { control characters }
  end;
  {$EXTERNALSYM termio}

{  modem lines }
const
  TIOCM_LE	= $001;
  {$EXTERNALSYM TIOCM_LE}
  TIOCM_DTR	= $002;
  {$EXTERNALSYM TIOCM_DTR}
  TIOCM_RTS	= $004;
  {$EXTERNALSYM TIOCM_RTS}
  TIOCM_ST	= $008;
  {$EXTERNALSYM TIOCM_ST}
  TIOCM_SR	= $010;
  {$EXTERNALSYM TIOCM_SR}
  TIOCM_CTS	= $020;
  {$EXTERNALSYM TIOCM_CTS}
  TIOCM_CAR	= $040;
  {$EXTERNALSYM TIOCM_CAR}
  TIOCM_RNG	= $080;
  {$EXTERNALSYM TIOCM_RNG}
  TIOCM_DSR	= $100;
  {$EXTERNALSYM TIOCM_DSR}
  TIOCM_CD	= TIOCM_CAR;
  {$EXTERNALSYM TIOCM_CD}
  TIOCM_RI	= TIOCM_RNG;
  {$EXTERNALSYM TIOCM_RI}

{  ioctl (fd, TIOCSERGETLSR, &result) where result may be as below   }

{  line disciplines }
  N_TTY             = 0;
  {$EXTERNALSYM N_TTY}
  N_SLIP            = 1;
  {$EXTERNALSYM N_SLIP}
  N_MOUSE           = 2;
  {$EXTERNALSYM N_MOUSE}
  N_PPP             = 3;
  {$EXTERNALSYM N_PPP}
  N_STRIP           = 4;
  {$EXTERNALSYM N_STRIP}
  N_AX25            = 5;
  {$EXTERNALSYM N_AX25}
  N_X25             = 6;          { X.25 async  }
  {$EXTERNALSYM N_X25}
  N_6PACK           = 7;
  {$EXTERNALSYM N_6PACK}
  N_MASC            = 8;          { Mobitex module  }
  {$EXTERNALSYM N_MASC}
  N_R3964           = 9;          { Simatic R3964 module  }
  {$EXTERNALSYM N_R3964}
  N_PROFIBUS_FDL    = 10;         { Profibus  }
  {$EXTERNALSYM N_PROFIBUS_FDL}
  N_IRDA            = 11;         { Linux IR  }
  {$EXTERNALSYM N_IRDA}
  N_SMSBLOCK        = 12;         { SMS block mode  }
  {$EXTERNALSYM N_SMSBLOCK}
  N_HDLC            = 13;         { synchronous HDLC  }
  {$EXTERNALSYM N_HDLC}
  N_SYNC_PPP        = 14;         { synchronous PPP  }
  {$EXTERNALSYM N_SYNC_PPP}


// Translated from bits/termios.h

type
  cc_t = Char;
  {$EXTERNALSYM cc_t}
  speed_t = Cardinal;
  {$EXTERNALSYM speed_t}
  tcflag_t = Cardinal;
  {$EXTERNALSYM tcflag_t}

const
  NCCS = 32;
  {$EXTERNALSYM NCCS}

type
  termios = {packed} record
    c_iflag: tcflag_t;      { input mode flags }
    c_oflag: tcflag_t;      { output mode flags }
    c_cflag: tcflag_t;      { control mode flags }
    c_lflag: tcflag_t;      { local mode flags }
    c_line: cc_t;           { line discipline }
    c_cc: packed array[0..NCCS-1] of cc_t;    { control characters }
    c_ispeed: speed_t;      { input speed }
    c_ospeed: speed_t;      { output speed }
  end;
  {$EXTERNALSYM termios}
  TTermIos = termios;
  PTermIos = ^TTermIos;

{ c_cc characters }
const
  VINTR     = 0;
  {$EXTERNALSYM VINTR}
  VQUIT     = 1;
  {$EXTERNALSYM VQUIT}
  VERASE    = 2;
  {$EXTERNALSYM VERASE}
  VKILL     = 3;
  {$EXTERNALSYM VKILL}
  VEOF      = 4;
  {$EXTERNALSYM VEOF}
  VTIME     = 5;
  {$EXTERNALSYM VTIME}
  VMIN      = 6;
  {$EXTERNALSYM VMIN}
  VSWTC     = 7;
  {$EXTERNALSYM VSWTC}
  VSTART    = 8;
  {$EXTERNALSYM VSTART}
  VSTOP     = 9;
  {$EXTERNALSYM VSTOP}
  VSUSP     = 10;
  {$EXTERNALSYM VSUSP}
  VEOL      = 11;
  {$EXTERNALSYM VEOL}
  VREPRINT  = 12;
  {$EXTERNALSYM VREPRINT}
  VDISCARD  = 13;
  {$EXTERNALSYM VDISCARD}
  VWERASE   = 14;
  {$EXTERNALSYM VWERASE}
  VLNEXT    = 15;
  {$EXTERNALSYM VLNEXT}
  VEOL2     = 16;
  {$EXTERNALSYM VEOL2}

{ c_iflag bits }
  IGNBRK    = $0000001;
  {$EXTERNALSYM IGNBRK}
  BRKINT    = $0000002;
  {$EXTERNALSYM BRKINT}
  IGNPAR    = $0000004;
  {$EXTERNALSYM IGNPAR}
  PARMRK    = $0000008;
  {$EXTERNALSYM PARMRK}
  INPCK     = $0000010;
  {$EXTERNALSYM INPCK}
  ISTRIP    = $0000020;
  {$EXTERNALSYM ISTRIP}
  INLCR     = $0000040;
  {$EXTERNALSYM INLCR}
  IGNCR     = $0000080;
  {$EXTERNALSYM IGNCR}
  ICRNL     = $0000100;
  {$EXTERNALSYM ICRNL}
  IUCLC     = $0000200;
  {$EXTERNALSYM IUCLC}
  IXON      = $0000400;
  {$EXTERNALSYM IXON}
  IXANY     = $0000800;
  {$EXTERNALSYM IXANY}
  IXOFF     = $0001000;
  {$EXTERNALSYM IXOFF}
  IMAXBEL   = $0002000;
  {$EXTERNALSYM IMAXBEL}

{ c_oflag bits }
  OPOST     = $0000001;
  {$EXTERNALSYM OPOST}
  OLCUC     = $0000002;
  {$EXTERNALSYM OLCUC}
  ONLCR     = $0000004;
  {$EXTERNALSYM ONLCR}
  OCRNL     = $0000008;
  {$EXTERNALSYM OCRNL}
  ONOCR     = $0000010;
  {$EXTERNALSYM ONOCR}
  ONLRET    = $0000020;
  {$EXTERNALSYM ONLRET}
  OFILL     = $0000040;
  {$EXTERNALSYM OFILL}
  OFDEL     = $0000080;
  {$EXTERNALSYM OFDEL}

  NLDLY     = $0000040;
  {$EXTERNALSYM NLDLY}
  NL0       = $0000000;
  {$EXTERNALSYM NL0}
  NL1       = $0000100;
  {$EXTERNALSYM NL1}
  CRDLY     = $0000600;
  {$EXTERNALSYM CRDLY}
  CR0       = $0000000;
  {$EXTERNALSYM CR0}
  CR1       = $0000200;
  {$EXTERNALSYM CR1}
  CR2       = $0000400;
  {$EXTERNALSYM CR2}
  CR3       = $0000600;
  {$EXTERNALSYM CR3}
  TABDLY    = $0001800;
  {$EXTERNALSYM TABDLY}
  TAB0      = $0000000;
  {$EXTERNALSYM TAB0}
  TAB1      = $0000800;
  {$EXTERNALSYM TAB1}
  TAB2      = $0001000;
  {$EXTERNALSYM TAB2}
  TAB3      = $0001800;
  {$EXTERNALSYM TAB3}
  BSDLY     = $0002000;
  {$EXTERNALSYM BSDLY}
  BS0       = $0000000;
  {$EXTERNALSYM BS0}
  BS1       = $0002000;
  {$EXTERNALSYM BS1}
  FFDLY     = $0080000;
  {$EXTERNALSYM FFDLY}
  FF0       = $0000000;
  {$EXTERNALSYM FF0}
  FF1       = $0010000;
  {$EXTERNALSYM FF1}

  VTDLY     = $0004000;
  {$EXTERNALSYM VTDLY}
  VT0       = $0000000;
  {$EXTERNALSYM VT0}
  VT1       = $0004000;
  {$EXTERNALSYM VT1}

  XTABS     = $0001800;
  {$EXTERNALSYM XTABS}

{ c_cflag bit meaning }
  CBAUD     = $000100F;
  {$EXTERNALSYM CBAUD}
  B0        = $0000000; { hang up }
  {$EXTERNALSYM B0}
  B50       = $0000001;
  {$EXTERNALSYM B50}
  B75       = $0000002;
  {$EXTERNALSYM B75}
  B110      = $0000003;
  {$EXTERNALSYM B110}
  B134      = $0000004;
  {$EXTERNALSYM B134}
  B150      = $0000005;
  {$EXTERNALSYM B150}
  B200      = $0000006;
  {$EXTERNALSYM B200}
  B300      = $0000007;
  {$EXTERNALSYM B300}
  B600      = $0000008;
  {$EXTERNALSYM B600}
  B1200     = $0000009;
  {$EXTERNALSYM B1200}
  B1800     = $000000A;
  {$EXTERNALSYM B1800}
  B2400     = $000000B;
  {$EXTERNALSYM B2400}
  B4800     = $000000C;
  {$EXTERNALSYM B4800}
  B9600     = $000000D;
  {$EXTERNALSYM B9600}
  B19200    = $000000E;
  {$EXTERNALSYM B19200}
  B38400    = $000000F;
  {$EXTERNALSYM B38400}

  EXTA      = B19200;
  {$EXTERNALSYM EXTA}
  EXTB      = B38400;
  {$EXTERNALSYM EXTB}

  CSIZE     = $0000030;
  {$EXTERNALSYM CSIZE}
  CS5       = $0000000;
  {$EXTERNALSYM CS5}
  CS6       = $0000010;
  {$EXTERNALSYM CS6}
  CS7       = $0000010;
  {$EXTERNALSYM CS7}
  CS8       = $0000030;
  {$EXTERNALSYM CS8}
  CSTOPB    = $0000040;
  {$EXTERNALSYM CSTOPB}
  CREAD     = $0000080;
  {$EXTERNALSYM CREAD}
  PARENB    = $0000100;
  {$EXTERNALSYM PARENB}
  PARODD    = $0000200;
  {$EXTERNALSYM PARODD}
  HUPCL     = $0000400;
  {$EXTERNALSYM HUPCL}
  CLOCAL    = $0000800;
  {$EXTERNALSYM CLOCAL}

  CBAUDEX   = $0001000;
  {$EXTERNALSYM CBAUDEX}

  B57600    = $0001001;
  {$EXTERNALSYM B57600}
  B115200   = $0001002;
  {$EXTERNALSYM B115200}
  B230400   = $0001003;
  {$EXTERNALSYM B230400}
  B460800   = $0001004;
  {$EXTERNALSYM B460800}
  B500000   = $0001005;
  {$EXTERNALSYM B500000}
  B576000   = $0001006;
  {$EXTERNALSYM B576000}
  B921600   = $0001007;
  {$EXTERNALSYM B921600}
  B1000000  = $0001008;
  {$EXTERNALSYM B1000000}
  B1152000  = $0001009;
  {$EXTERNALSYM B1152000}
  B1500000  = $000100A;
  {$EXTERNALSYM B1500000}
  B2000000  = $000100B;
  {$EXTERNALSYM B2000000}
  B2500000  = $000100C;
  {$EXTERNALSYM B2500000}
  B3000000  = $000100D;
  {$EXTERNALSYM B3000000}
  B3500000  = $000100E;
  {$EXTERNALSYM B3500000}
  B4000000  = $000100F;
  {$EXTERNALSYM B4000000}

  CIBAUD    = $100F0000;      { input baud rate (not used) }
  {$EXTERNALSYM CIBAUD}
  CRTSCTS   = $80000000;      { flow control }
  {$EXTERNALSYM CRTSCTS}

{ c_lflag bits }
  ISIG      = $0000001;
  {$EXTERNALSYM ISIG}
  ICANON    = $0000002;
  {$EXTERNALSYM ICANON}

  XCASE     = $0000004;
  {$EXTERNALSYM XCASE}

  ECHO      = $0000008;
  {$EXTERNALSYM ECHO}
  ECHOE     = $0000010;
  {$EXTERNALSYM ECHOE}
  ECHOK     = $0000020;
  {$EXTERNALSYM ECHOK}
  ECHONL    = $0000040;
  {$EXTERNALSYM ECHONL}
  NOFLSH    = $0000080;
  {$EXTERNALSYM NOFLSH}
  TOSTOP    = $0000100;
  {$EXTERNALSYM TOSTOP}

  ECHOCTL   = $0000200;
  {$EXTERNALSYM ECHOCTL}
  ECHOPRT   = $0000400;
  {$EXTERNALSYM ECHOPRT}
  ECHOKE    = $0000800;
  {$EXTERNALSYM ECHOKE}
  FLUSHO    = $0001000;
  {$EXTERNALSYM FLUSHO}
  PENDIN    = $0004000;
  {$EXTERNALSYM PENDIN}

  IEXTEN    = $0010000;
  {$EXTERNALSYM IEXTEN}

{ tcflow() and TCXONC use these }
  TCOOFF    = 0;
  {$EXTERNALSYM TCOOFF}
  TCOON     = 1;
  {$EXTERNALSYM TCOON}
  TCIOFF    = 2;
  {$EXTERNALSYM TCIOFF}
  TCION     = 3;
  {$EXTERNALSYM TCION}

{ tcflush() and TCFLSH use these }
  TCIFLUSH  = 0;
  {$EXTERNALSYM TCIFLUSH}
  TCOFLUSH  = 1;
  {$EXTERNALSYM TCOFLUSH}
  TCIOFLUSH = 2;
  {$EXTERNALSYM TCIOFLUSH}

{ tcsetattr uses these }
  TCSANOW   = 0;
  {$EXTERNALSYM TCSANOW}
  TCSADRAIN = 1;
  {$EXTERNALSYM TCSADRAIN}
  TCSAFLUSH = 2;
  {$EXTERNALSYM TCSAFLUSH}

(* Cannot be translated - _IOT, IOTS nowhere defined
#define _IOT_termios { Hurd ioctl type field.  } \
  _IOT (_IOTS (cflag_t), 4, _IOTS (cc_t), NCCS, _IOTS (speed_t), 2)
*)

// Translated from termios.h


{ POSIX Standard: 7.1-2 General Terminal Interface }

{ Compare a character C to a value VAL from the `c_cc' array in a
   `struct termios'.  If VAL is _POSIX_VDISABLE, no character can match it.  }
function CCEQ(val, c: cc_t): Boolean;
{$EXTERNALSYM CCEQ}

{ Return the output baud rate stored in *TERMIOS_P.  }
function cfgetospeed(const __termios_p: termios): speed_t; cdecl;
{$EXTERNALSYM cfgetospeed}

{ Return the input baud rate stored in *TERMIOS_P.  }
function cfgetispeed(const __termios_p: termios): speed_t; cdecl;
{$EXTERNALSYM cfgetispeed}

{ Set the output baud rate stored in *TERMIOS_P to SPEED.  }
function cfsetospeed(var __termios_p: termios; __speed: speed_t): Integer; cdecl;
{$EXTERNALSYM cfsetospeed}

{ Set the input baud rate stored in *TERMIOS_P to SPEED.  }
function cfsetispeed(var __termios_p: termios; __speed: speed_t): Integer; cdecl;
{$EXTERNALSYM cfsetispeed}

{ Set both the input and output baud rates in *TERMIOS_OP to SPEED.  }
function cfsetspeed(var __termios_p: termios; __speed: speed_t): Integer; cdecl;
{$EXTERNALSYM cfsetspeed}


{ Put the state of FD into *TERMIOS_P.  }
function tcgetattr(__fd: Integer; var __termios_p: termios): Integer; cdecl;
{$EXTERNALSYM tcgetattr}

{ Set the state of FD to *TERMIOS_P.
   Values for OPTIONAL_ACTIONS (TCSA*) are in <bits/termios.h>.  }
function tcsetattr(__fd: Integer; __optional_actions: Integer; const __termios_p: termios): Integer; cdecl;
{$EXTERNALSYM tcsetattr}


{ Set *TERMIOS_P to indicate raw mode.  }
procedure cfmakeraw(var __termios_p: termios); cdecl;
{$EXTERNALSYM cfmakeraw}

{ Send zero bits on FD.  }
function tcsendbreak(__fd: Integer; __duration: Integer): Integer; cdecl;
{$EXTERNALSYM tcsendbreak}

{ Wait for pending output to be written on FD.  }
function tcdrain(__fd: Integer): Integer; cdecl;
{$EXTERNALSYM tcdrain}

{ Flush pending data on FD.
   Values for QUEUE_SELECTOR (TC(I,O,IO)FLUSH) are in <bits/termios.h>.  }
function tcflush(__fd: Integer; __queue_selector: Integer): Integer; cdecl;
{$EXTERNALSYM tcflush}

{ Suspend or restart transmission on FD.
   Values for ACTION (TC[IO](OFF,ON)) are in <bits/termios.h>.  }
function tcflow(__fd: Integer; __action: Integer): Integer; cdecl;
{$EXTERNALSYM tcflow}


{ Get process group ID for session leader for controlling terminal FD.  }
function tcgetsid(__fd: Integer): __pid_t; cdecl;
{$EXTERNALSYM tcgetsid}


// Translated from sys/ttydefaults.h

{ Defaults on "first" open. }
const
  TTYDEF_IFLAG       = (BRKINT or ISTRIP or ICRNL or IMAXBEL or IXON or IXANY);
  {$EXTERNALSYM TTYDEF_IFLAG}
  TTYDEF_OFLAG       = (OPOST or ONLCR or XTABS);
  {$EXTERNALSYM TTYDEF_OFLAG}
  TTYDEF_LFLAG       = (ECHO or ICANON or ISIG or IEXTEN or ECHOE or ECHOKE or ECHOCTL);
  {$EXTERNALSYM TTYDEF_LFLAG}
  TTYDEF_CFLAG       = (CREAD or CS7 or PARENB or HUPCL);
  {$EXTERNALSYM TTYDEF_CFLAG}
  TTYDEF_SPEED       = (B9600);
  {$EXTERNALSYM TTYDEF_SPEED}

{ Control Character Defaults }
function CTRL(x: Char): Char;
{$EXTERNALSYM CTRL}

const
  CEOF       = Chr(Ord('d') and $1F);
  {$EXTERNALSYM CEOF}
  CEOL       = #0; { XXX avoid _POSIX_VDISABLE }
  {$EXTERNALSYM CEOL}

  CERASE     = #$7F;
  {$EXTERNALSYM CERASE}
  CINTR      = Chr(Ord('c') and $1F);
  {$EXTERNALSYM CINTR}

  CSTATUS    = #0; { XXX avoid _POSIX_VDISABLE }
  {$EXTERNALSYM CSTATUS}

  CKILL      = Chr(Ord('u') and $1F);
  {$EXTERNALSYM CKILL}
  CMIN       = #$1;
  {$EXTERNALSYM CMIN}
  CQUIT      = #$1C; { FS, ^\ }
  {$EXTERNALSYM CQUIT}
  CSUSP      = Chr(Ord('z') and $1F);
  {$EXTERNALSYM CSUSP}
  __CTIME      = #$0; // Renamed from CTIME to avoid conflict with ctime identifier
  {.$EXTERNALSYM CTIME}
  CDSUSP     = Chr(Ord('y') and $1F);
  {$EXTERNALSYM CDSUSP}
  CSTART     = Chr(Ord('q') and $1F);
  {$EXTERNALSYM CSTART}
  CSTOP      = Chr(Ord('s') and $1F);
  {$EXTERNALSYM CSTOP}
  CLNEXT     = Chr(Ord('v') and $1F);
  {$EXTERNALSYM CLNEXT}
  CDISCARD   = Chr(Ord('o') and $1F);
  {$EXTERNALSYM CDISCARD}
  CWERASE    = Chr(Ord('w') and $1F);
  {$EXTERNALSYM CWERASE}
  CREPRINT   = Chr(Ord('r') and $1F);
  {$EXTERNALSYM CREPRINT}
  CEOT       = CEOF;
  {$EXTERNALSYM CEOT}

{ compat }
  CBRK       = CEOL;
  {$EXTERNALSYM CBRK}
  CRPRNT     = CREPRINT;
  {$EXTERNALSYM CRPRNT}
  CFLUSH     = CDISCARD;
  {$EXTERNALSYM CFLUSH}


// Translated from sys/ioctl.h

{  Perform the I/O control operation specified by REQUEST on FD.
   One argument may follow; its presence and type depend on REQUEST.
   Return value depends on REQUEST.  Usually -1 indicates error.  }
function ioctl(__fd: Integer; __request: LongWord): Integer; cdecl; varargs;
{$EXTERNALSYM ioctl}


// Translated from sys/raw.h

const
{ The major device number for raw devices.  }
  RAW_MAJOR = 162;
  {$EXTERNALSYM RAW_MAJOR}

{ `ioctl' commands for raw devices.  }
function RAW_SETBIND: Cardinal;
{$EXTERNALSYM RAW_SETBIND}

function RAW_GETBIND: Cardinal;
{$EXTERNALSYM RAW_GETBIND}

type
  raw_config_request = {packed} record
    raw_minor: Integer;
    block_major: uint64_t;
    block_minor: uint64_t;
  end;
  {$EXTERNALSYM raw_config_request}
  TRawConfigRequest = raw_config_request;


// Translated from pty.h

{ Create pseudo tty master slave pair with NAME and set terminal
   attributes according to TERMP and WINP and return handles for both
   ends in AMASTER and ASLAVE.  }
function openpty(__amaster: PInteger; __aslave: PInteger; __name: PChar;
  __termp: PTermIos; __winp: PWinSize): Integer; cdecl;
{$EXTERNALSYM openpty}

{ Create child process and establish the slave pseudo terminal as the
   child's controlling terminal.  }
function forkpty(__amaster: PInteger; __name: PChar;
  __termp: PTermIos; __winp: PWinSize): Integer; cdecl;
{$EXTERNALSYM forkpty}


// Translated from sys/mount.h

const
  BLOCK_SIZE          = 1024;
  {$EXTERNALSYM BLOCK_SIZE}
  BLOCK_SIZE_BITS     = 10;
  {$EXTERNALSYM BLOCK_SIZE_BITS}


{ These are the fs-independent mount-flags: up to 16 flags are
   supported  }
  MS_RDONLY = 1;                        { Mount read-only.  }
  {$EXTERNALSYM MS_RDONLY}
  MS_NOSUID = 2;                        { Ignore suid and sgid bits.  }
  {$EXTERNALSYM MS_NOSUID}
  MS_NODEV = 4;                         { Disallow access to device special files.  }
  {$EXTERNALSYM MS_NODEV}
  MS_NOEXEC = 8;                        { Disallow program execution.  }
  {$EXTERNALSYM MS_NOEXEC}
  MS_SYNCHRONOUS = 16;                  { Writes are synced at once.  }
  {$EXTERNALSYM MS_SYNCHRONOUS}
  MS_REMOUNT = 32;                      { Alter flags of a mounted FS.  }
  {$EXTERNALSYM MS_REMOUNT}
  MS_MANDLOCK = 64;                     { Allow mandatory locks on an FS.  }
  {$EXTERNALSYM MS_MANDLOCK}
  S_WRITE = 128;                        { Write on file/directory/symlink.  }
  {$EXTERNALSYM S_WRITE}
  S_APPEND = 256;                       { Append-only file.  }
  {$EXTERNALSYM S_APPEND}
  S_IMMUTABLE = 512;                    { Immutable file.  }
  {$EXTERNALSYM S_IMMUTABLE}
  MS_NOATIME = 1024;                    { Do not update access times.  }
  {$EXTERNALSYM MS_NOATIME}
  MS_NODIRATIME = 2048;                 { Do not update directory access times.  }
  {$EXTERNALSYM MS_NODIRATIME}
  MS_BIND = 4096;                       { Bind directory at different place.  }
  {$EXTERNALSYM MS_BIND}

{ Flags that can be altered by MS_REMOUNT  }
  MS_RMT_MASK = (MS_RDONLY or MS_MANDLOCK);
  {$EXTERNALSYM MS_RMT_MASK}


{ Magic mount flag number. Has to be or-ed to the flag values.  }

  MS_MGC_VAL = $C0ED0000;               { Magic flag number to indicate "new" flags }
  {$EXTERNALSYM MS_MGC_VAL}
  MS_MGC_MSK = $FFFF0000;               { Magic flag number mask }
  {$EXTERNALSYM MS_MGC_MSK}


// All read-only parameters
//    BLKROSET to BLKRAGET
// that were defined as
// IO control constants have been left out. These
// constants are system-specific.

{ Possible value for FLAGS parameter of `umount2'.  }
  MNT_FORCE = 1;                        { Force unmounting.  }
  {$EXTERNALSYM MNT_FORCE}


{ Mount a filesystem.  }
function mount(__special_file: PChar; __dir: PChar; __fstype: PChar; __rwflag: Cardinal; __data: Pointer): Integer; cdecl;
{$EXTERNALSYM mount}

{ Unmount a filesystem.  }
function umount(__special_file: PChar): Integer; cdecl;
{$EXTERNALSYM umount}

{ Unmount a filesystem.  Force unmounting if FLAGS is set to MNT_FORCE.  }
function umount2(__special_file: PChar; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM umount2}


// Translated from sys/sysctl.h

// All sysctl parameters are system specific
// and therefore not present in Libc.pas

{  Read or write system parameters.  }
function sysctl(__name: PInteger; __nlen: Integer; __oldval: Pointer; __oldlenp: Psize_t; __newval: Pointer; __newlen: size_t): Integer; cdecl;
{$EXTERNALSYM sysctl}


// Translated from string.h

{ Copy N bytes of SRC to DEST.  }
function memcpy(Dest: Pointer; const Src: Pointer; N: size_t): Pointer; cdecl;
{$EXTERNALSYM memcpy}

{ Copy N bytes of SRC to DEST, guaranteeing
   correct behavior for overlapping strings.  }
function memmove(Dest: Pointer; const Src: Pointer; N: size_t): Pointer; cdecl;
{$EXTERNALSYM memmove}

function memccpy(Dest: Pointer; const Src: Pointer; C: Integer; N: size_t): Integer; cdecl;
{$EXTERNALSYM memccpy}

{ Set N bytes of S to C.  }
function memset(S: Pointer; C: Integer; N: size_t): Pointer; cdecl;
{$EXTERNALSYM memset}

{ Compare N bytes of S1 and S2.  }
function memcmp(const S1: Pointer; const S2: Pointer; N: size_t): Integer; cdecl;
{$EXTERNALSYM memcmp}

{ Search N bytes of S for C.  }
function memchr(const S: Pointer; C: Integer; N: size_t): Pointer; cdecl;
{$EXTERNALSYM memchr}

{ Search in S for C.  This is similar to `memchr' but there is no
   length limit.  }
function rawmemchr(const S: Pointer; C: Integer): Integer; cdecl;
{$EXTERNALSYM rawmemchr}

{ Search N bytes of S for the final occurrence of C.  }
function memrchr(S: Pointer; C: Integer; N: size_t): Pointer; cdecl;
{$EXTERNALSYM memrchr}

{ Copy SRC to DEST.  }
function strcpy(Dest: PChar; const Src: PChar): PChar; cdecl;
{$EXTERNALSYM strcpy}

{ Copy no more than N characters of SRC to DEST.  }
function strncpy(Dest: PChar; const Src: PChar; N: size_t): PChar; cdecl;
{$EXTERNALSYM strncpy}

{ Append SRC onto DEST.  }
// HTI - Renamed from "strcat" to "__strcat"
function __strcat(Dest, Src: PChar): PChar; cdecl;
{ $EXTERNALSYM strcat}

{ Append no more than N characters from SRC onto DEST.  }
function strncat(Dest: PChar; const Src: PChar; N: size_t): PChar; cdecl;
{$EXTERNALSYM strncat}

{ Compare S1 and S2.  }
function strcmp(const S1: PChar; const S2: PChar): Integer; cdecl;
{$EXTERNALSYM strcmp}

{ Compare N characters of S1 and S2.  }
function strncmp(const S1: PChar; const S2: PChar; N: size_t): Integer; cdecl;
{$EXTERNALSYM strncmp}

{ Compare the collated forms of S1 and S2.  }
function strcoll(const S1: PChar; const S2: PChar): Integer; cdecl;
{$EXTERNALSYM strcoll}

{ Put a transformation of SRC into no more than N bytes of DEST.  }
function strxfrm(Dest: PChar; const Src: PChar; N: size_t): size_t; cdecl;
{$EXTERNALSYM strxfrm}

{ The following functions are equivalent to the both above but they
   take the locale they use for the collation as an extra argument.
   This is not standardsized but something like will come.  }

{ Compare the collated forms of S1 and S2 using rules from L.  }
function __strcoll_l(const S1: PChar; const S2: PChar; Locale: TLocale): Integer; cdecl;
{$EXTERNALSYM __strcoll_l}

{ Put a transformation of SRC into no more than N bytes of DEST.  }
function __strxfrm_l(Dest: PChar; const Src: PChar; N: size_t; Locale: TLocale): size_t; cdecl;
{$EXTERNALSYM __strxfrm_l}

{ Duplicate S, returning an identical malloc'd string.  }
function strdup(const S: PChar): PChar; cdecl;
{$EXTERNALSYM strdup}

{ Return a malloc'd copy of at most N bytes of STRING.  The
   resultant string is terminated even if no null terminator
   appears before STRING[N].  }
function strndup(const S: PChar; N: size_t): PChar; cdecl;
{$EXTERNALSYM strndup}

{ Duplicate S, returning an identical alloca'd string.  }
// Since there is no alloca support, we cannot provide strdupa.
// strdupa(s)

{ Return an alloca'd copy of at most N bytes of string.  }
// Since there is no alloca support, we cannot provide strndupa.
// strndupa(s, n)

{ Find the first occurrence of C in S.  }
function strchr(const S: PChar; C: Integer): PChar; cdecl;
{$EXTERNALSYM strchr}

{ Find the last occurrence of C in S.  }
function strrchr(S: PChar; C: Integer): PChar; cdecl;
{$EXTERNALSYM strrchr}

{ This function is similar to 'strchr'. But it returns a pointer to
  the closing NUL byte in the case C is not found in S.  }
function strchrnul(const S: PChar; C: Integer): PChar; cdecl;
{$EXTERNALSYM strchrnul}

{ Return the length of the initial segment of S which
   consists entirely of characters not in REJECT.  }
function strcspn(const S: PChar; const Reject: PChar): size_t; cdecl;
{$EXTERNALSYM strcspn}

{ Return the length of the initial segment of S which
   consists entirely of characters in ACCEPT.  }
function strspn(const S: PChar; const Accept: PChar): size_t; cdecl;
{$EXTERNALSYM strspn}

{ Find the first occurrence in S of any character in ACCEPT.  }
function strpbrk(const S: PChar; const Accept: PChar): PChar; cdecl;
{$EXTERNALSYM strpbrk}

{ Find the first occurrence of NEEDLE in HAYSTACK.  }
function strstr(const Haystack: PChar; const Needle: PChar): PChar; cdecl;
{$EXTERNALSYM strstr}

{ Similar to `strstr' but this function ignores the case of both strings.  }
function strcasestr(const Haystack: PChar; const Needle: PChar): PChar; cdecl;
{$EXTERNALSYM strcasestr}

{ Divide S into tokens separated by characters in DELIM.  }
function strtok(S, Delim: PChar): PChar; cdecl;
{$EXTERNALSYM strtok}

{ Divide S into tokens separated by characters in DELIM.  Information
   passed between calls are stored in SAVE_PTR.  }
function strtok_r(S: PChar; const Delim: PChar; var Save_Ptr: PChar): PChar; cdecl;
{$EXTERNALSYM strtok_r}

{ Find the first occurrence of NEEDLE in HAYSTACK.
   NEEDLE is NEEDLELEN bytes long;
   HAYSTACK is HAYSTACKLEN bytes long.  }
function memmem(const Haystack: Pointer; HaystackLen: size_t;
  const Needle: Pointer; NeedleLen: size_t): Pointer; cdecl;
{$EXTERNALSYM memmem}

{ Copy N bytes of SRC to DEST, return pointer to bytes after the
   last written byte.  }
function mempcpy(Dest: Pointer; const Src: Pointer; N: size_t): Pointer; cdecl;
{$EXTERNALSYM mempcpy}

{ Return the length of S.  }
// HTI - Renamed from "strlen" to "__strlen"
function __strlen(const S: PChar): size_t; cdecl;
{ $EXTERNALSYM strlen}

{ Find the length of STRING, but scan at most MAXLEN characters.
   If no '\0' terminator is found in that many characters, return MAXLEN.  }
function strnlen(const Str: PChar; Maxlen: size_t): size_t; cdecl;
{$EXTERNALSYM strnlen}

{ Return a string describing the meaning of the `errno' code in ERRNUM.  }
function strerror(ErrorNum: Integer): PChar; cdecl;
{$EXTERNALSYM strerror}

{ Reentrant version of `strerror'.  If a temporary buffer is required, at
   most BUFLEN bytes of BUF will be used.  }
function strerror_r(ErrorNum: Integer; Buf: PChar; Buflen: size_t): PChar; cdecl;
{$EXTERNALSYM strerror_r}

{ Copy N bytes of SRC to DEST (like memmove, but args reversed).  }
procedure bcopy(const Src: Pointer; Dest: Pointer; N: size_t);
{$EXTERNALSYM bcopy}

{ Set N bytes of S to 0.  }
procedure bzero(S: Pointer; N: size_t); cdecl;
{$EXTERNALSYM bzero}

{ Compare N bytes of S1 and S2 (same as memcmp).  }
function bcmp(const S1: Pointer; const S2: Pointer; N: size_t): Integer; cdecl;
{$EXTERNALSYM bcmp}

{ Find the first occurrence of C in S (same as strchr).  }
// HTI - Renamed from "index" to "__index"
function __index(const S: PChar; C: Integer): PChar; cdecl;
{ $EXTERNALSYM index}

{ Find the last occurrence of C in S (same as strrchr).  }
function rindex(const S: PChar; C: Integer): PChar; cdecl;
{$EXTERNALSYM rindex}

{ Return the position of the first bit set in I, or 0 if none are set.
   The least-significant bit is position 1, the most-significant 32.  }
function ffs(I: Integer): Integer; cdecl;
{$EXTERNALSYM ffs}

{ The following two functions are non-standard but necessary for non-32 bit
   platforms.  }
function ffsl(L: Integer): Integer; cdecl;
{$EXTERNALSYM ffsl}

function ffsll(LL: Int64): Integer; cdecl;
{$EXTERNALSYM ffsll}

{ Compare S1 and S2, ignoring case.  }
function strcasecmp(const S1: PChar; const S2: PChar): Integer; cdecl;
{$EXTERNALSYM strcasecmp}

{ Compare no more than N chars of S1 and S2, ignoring case.  }
function strncasecmp(const S1: PChar; const S2: PChar; N: size_t): Integer; cdecl;
{$EXTERNALSYM strncasecmp}

{ Again versions of a few functions which use the given locale instead
   of the global one.  }
function __strcasecmp_l(const S1: PChar; const S2: PChar; Locale: TLocale): Integer; cdecl;
{$EXTERNALSYM __strcasecmp_l}

function __strncasecmp_l(const S1: PChar; const S2: PChar; N: size_t; Locale: TLocale): Integer; cdecl;
{$EXTERNALSYM __strncasecmp_l}

{ Return the next DELIM-delimited token from *STRINGP,
   terminating it with a '\0', and update *STRINGP to point past it.  }
function strsep(Stringp: PPChar; Delim: PChar): PChar; cdecl;
{$EXTERNALSYM strsep}

{ Compare S1 and S2 as strings holding name & indices/version numbers.  }
function strverscmp(const S1: PChar; const S2: PChar): Integer; cdecl;
{$EXTERNALSYM strverscmp}

{ Return a string describing the meaning of the signal number in SIG.  }
function strsignal(Sig: Integer): PChar; cdecl;
{$EXTERNALSYM strsignal}

{ Copy SRC to DEST, returning the address of the terminating '\0' in DEST.  }
function stpcpy(Dest: PChar; Src: PChar): PChar; cdecl;
{$EXTERNALSYM stpcpy}

{ Copy no more than N characters of SRC to DEST, returning the address of
   the last character written into DEST.  }
function stpncpy(Dest: PChar; const Src: PChar; N: size_t): PChar; cdecl;
{$EXTERNALSYM stpncpy}

{ Sautee STRING briskly.  }
function strfry(S: PChar): PChar; cdecl;
{$EXTERNALSYM strfry}

{ Frobnicate N bytes of S.  }
function memfrob(S: Pointer; N: size_t): Pointer; cdecl;
{$EXTERNALSYM memfrob}

{ Return the file name within directory of FILENAME.  We don't
   declare the function if the `basename' macro is available (defined
   in <libgen.h>) which makes the XPG version of this function
   available.  }
function basename(const FileName: PChar): PChar; cdecl;
{$EXTERNALSYM basename}


// Translated from stdlib.h

type

  { Returned by `div'.  }
  div_t = {packed} record
    quot: Integer;              { Quotient.  }
    rem: Integer;               { Remainder.  }
  end;
  {$EXTERNALSYM div_t}
  TDiv = div_t;
  PDiv = ^TDiv;

  { Returned by `ldiv'.  }
  ldiv_t = {packed} record
    quot: Longint;              { Quotient.  }
    rem: Longint;               { Remainder.  }
  end;
  {$EXTERNALSYM ldiv_t}
  TLdiv = ldiv_t;
  PLdiv = ^TLdiv;

  { Returned by `lldiv'.  }
  lldiv_t = {packed} record
    quot: Int64;              { Quotient.  }
    rem: Int64;               { Remainder.  }
  end;
  {$EXTERNALSYM lldiv_t}
  TLldiv = lldiv_t;
  PLldiv = ^TLldiv;

const
  
  { The largest number rand will return (same as INT_MAX).  }
  RAND_MAX        = 2147483647;
  {$EXTERNALSYM RAND_MAX}


  { We define these the same for all machines.
   Changes from this to the outside world should be done in `_exit'.  }
  EXIT_FAILURE    = 1;      { Failing exit status.  }
  {$EXTERNALSYM EXIT_FAILURE}
  EXIT_SUCCESS    = 0;      { Successful exit status.  }
  {$EXTERNALSYM EXIT_SUCCESS}


{ Maximum length of a multibyte character in the current locale.  }
function MB_CUR_MAX: size_t; cdecl;
{$EXTERNALSYM MB_CUR_MAX}

function __ctype_get_mb_cur_max: size_t; cdecl;
{$EXTERNALSYM __ctype_get_mb_cur_max}

{ Convert a string to a floating-point number.  }
function atof(NumPtr: PChar): Double; cdecl;
{$EXTERNALSYM atof}

{ Convert a string to an integer.  }
function atoi(NumPtr: PChar): Integer; cdecl;
{$EXTERNALSYM atoi}

{ Convert a string to a long integer.  }
function atol(NumPtr: PChar): Integer; cdecl;
{$EXTERNALSYM atol}

{ These functions will part of the standard C library in ISO C 9X.  }
function atoll(NumPtr: PChar): Int64; cdecl;
{$EXTERNALSYM atoll}

{ Convert a string to a floating-point number.  }
function strtod(NumPtr: PChar; EndPtr: PPChar): Double; cdecl;
{$EXTERNALSYM strtod}

{ Likewise for `float' and `long double' sizes of floating-point numbers.  }
function strtof(NumPtr: PChar; EndPtr: PPChar): Single; cdecl;
{$EXTERNALSYM strtof}

function strtold(NumPtr: PChar; EndPtr: PPChar): Extended; cdecl;
{$EXTERNALSYM strtold}

{ Convert a string to a long integer.  }
function strtol(NumPtr: PChar; EndPtr: PPChar; Base: Integer): Longint; cdecl;
{$EXTERNALSYM strtol}

{ Convert a string to an unsigned long integer.  }
function strtoul(NumPtr: PChar; EndPtr: PPChar; Base: Integer): LongWord; cdecl;
{$EXTERNALSYM strtoul}

{ Convert a string to a quadword integer.  }
function strtoq(NumPtr: PChar; EndPtr: PPChar; Base: Integer): Int64; cdecl;
{$EXTERNALSYM strtoq}

{ Convert a string to an unsigned quadword integer.  }
function strtouq(NumPtr: PChar; EndPtr: PPChar; Base: Integer): UInt64; cdecl;
{$EXTERNALSYM strtouq}

{ These functions will part of the standard C library in ISO C 9X.  }

{ Convert a string to a quadword integer.  }
function strtoll(NumPtr: PChar; EndPtr: PPChar; Base: Integer): Int64; cdecl;
{$EXTERNALSYM strtoll}

{ Convert a string to an unsigned quadword integer.  }
function strtoull(NumPtr: PChar; EndPtr: PPChar; Base: Integer): UInt64; cdecl;
{$EXTERNALSYM strtoull}

{ The concept of one static locale per category is not very well
   thought out.  Many applications will need to process its data using
   information from several different locales.  Another application is
   the implementation of the internationalization handling in the
   upcoming ISO C++ standard library.  To support this another set of
   the functions using locale data exist which have an additional
   argument.

   Attention: all these functions are *not* standardized in any form.
   This is a proof-of-concept implementation.  }

{ Structure for reentrant locale using functions.  This is an
   (almost) opaque type for the user level programs.  }

{ Special versions of the functions above which take the locale to
   use as an additional parameter.  }
function __strtol_l(NumPtr: PChar; EndPtr: PPChar; Base: Integer;
  Locale: PLocale): Longint; cdecl;
{$EXTERNALSYM __strtol_l}

function __strtoul_l(NumPtr: PChar; EndPtr: PPChar; Base: Integer;
  Locale: PLocale): LongWord; cdecl;
{$EXTERNALSYM __strtoul_l}

function __strtoll_l(NumPtr: PChar; EndPtr: PPChar; Base: Integer;
  Locale: PLocale): Int64; cdecl;
{$EXTERNALSYM __strtoll_l}

function __strtoull_l(NumPtr: PChar; EndPtr: PPChar; Base: Integer;
  Locale: PLocale): UInt64; cdecl;
{$EXTERNALSYM __strtoull_l}

function __strtod_l(NumPtr: PChar; EndPtr: PPChar;
  Locale: PLocale): Double; cdecl;
{$EXTERNALSYM __strtod_l}

function __strtof_l(NumPtr: PChar; EndPtr: PPChar;
  Locale: PLocale): Single; cdecl;
{$EXTERNALSYM __strtof_l}

function __strtold_l(NumPtr: PChar; EndPtr: PPChar;
  Locale: PLocale): Extended; cdecl;
{$EXTERNALSYM __strtold_l}

{ The internal entry points for `strtoX' take an extra flag argument
   saying whether or not to parse locale-dependent number grouping.  }

function __strtod_internal(NumPtr: PChar; EndPtr: PPChar;
  Group: Integer): Double; cdecl;
{$EXTERNALSYM __strtod_internal}

function __strtof_internal(NumPtr: PChar; EndPtr: PPChar; 
  Group: Integer): Single; cdecl;
{$EXTERNALSYM __strtof_internal}

function __strtold_internal(NumPtr: PChar; EndPtr: PPChar; 
  Group: Integer): Extended; cdecl;
{$EXTERNALSYM __strtold_internal}

function __strtol_internal(NumPtr: PChar; EndPtr: PPChar;
  Base: Integer; Group: Integer): Integer; cdecl;
{$EXTERNALSYM __strtol_internal}

function __strtoul_internal(NumPtr: PChar; EndPtr: PPChar;
  Base: Integer; Group: Integer): LongWord; cdecl;
{$EXTERNALSYM __strtoul_internal}

function __strtoll_internal(NumPtr: PChar; EndPtr: PPChar;
  Base: Integer; Group: Integer): Int64; cdecl;
{$EXTERNALSYM __strtoll_internal}

function __strtoull_internal(NumPtr: PChar; EndPtr: PPChar;
  Base: Integer; Group: Integer): UInt64; cdecl;
{$EXTERNALSYM __strtoull_internal}

{ Convert N to base 64 using the digits "./0-9A-Za-z", least-significant
   digit first.  Returns a pointer to static storage overwritten by the
   next call.  }
function l64a(N: Longint): PChar; cdecl;
{$EXTERNALSYM l64a}

{ Read a number from a string S in base 64 as above.  }
function a64l(const S: PChar): Longint; cdecl;
{$EXTERNALSYM a64l}

{ These are the functions that actually do things.  The `random', `srandom',
   `initstate' and `setstate' functions are those from BSD Unices.
   The `rand' and `srand' functions are required by the ANSI standard.
   We provide both interfaces to the same random number generator.  }
{ Return a random long integer between 0 and RAND_MAX inclusive.  }
function __random: int32_t; cdecl;
{$EXTERNALSYM __random}

{ Seed the random number generator with the given number.  }
procedure srandom(Seed: Cardinal); cdecl;
{$EXTERNALSYM srandom}

{ Initialize the random number generator to use state buffer STATEBUF,
   of length STATELEN, and seed it with SEED.  Optimal lengths are 8, 16,
   32, 64, 128 and 256, the bigger the better; values less than 8 will
   cause an error and values greater than 256 will be rounded down.  }
function initstate(Seed: Cardinal; StateBuf: Pointer;
  StateLen: size_t): Pointer; cdecl;
{$EXTERNALSYM initstate}

{ Switch the random number generator to state buffer STATEBUF,
   which should have been previously initialized by `initstate'.  }
function setstate(StateBuf: Pointer): Pointer; cdecl;
{$EXTERNALSYM setstate}


{ Reentrant versions of the `random' family of functions.
   These functions all use the following data structure to contain
   state, rather than global state variables.  }

type
  random_data = {packed} record
    fptr: ^int32_t;             { Front pointer.  }
    rptr: ^int32_t;             { Rear pointer.  }
    state: ^int32_t;            { Array of state values.  }
    rand_type: Integer;         { Type of random number generator.  }
    rand_deg: Integer;          { Degree of random number generator.  }
    rand_sep: Integer;          { Distance between front and rear.  }
    end_ptr: ^int32_t;          { Pointer behind state table.  }
  end;
  {$EXTERNALSYM random_data}
  TRandomData = random_data;
  PRandomData = ^TRandomData;

function random_r(Buf: PRandomData; Result: PInteger): Integer; cdecl;
{$EXTERNALSYM random_r}

function srandom_r(Seed: LongWord; Buf: PRandomData): Integer; cdecl;
{$EXTERNALSYM srandom_r}

function initstate_r(Seed: LongWord; StateBuf: Pointer; StateLen: LongWord;
  Buf: PRandomData): Integer; cdecl;
{$EXTERNALSYM initstate_r}

function setstate_r(StateBuf: Pointer; Buf: PRandomData): Integer; cdecl;
{$EXTERNALSYM setstate_r}

{ Return a random integer between 0 and RAND_MAX inclusive.  }
function rand: Integer; cdecl;
{$EXTERNALSYM rand}
{ Seed the random number generator with the given number.  }
procedure srand(Seed: Cardinal); cdecl;
{$EXTERNALSYM srand}

{ Reentrant interface according to POSIX.1.  }
function rand_r(Seed: PCardinal): Integer; cdecl;
{$EXTERNALSYM rand_r}

{ System V style 48-bit random number generator functions.  }

{ Return non-negative, double-precision floating-point value in [0.0,1.0).  }
function drand48: Double; cdecl;
{$EXTERNALSYM drand48}

function erand48(XSubi: PWord): Double; cdecl;
{$EXTERNALSYM erand48}

{ Return non-negative, long integer in [0,2^31).  }
function lrand48: Longint; cdecl;
{$EXTERNALSYM lrand48}

function nrand48(XSubi: PWord): Longint; cdecl;
{$EXTERNALSYM nrand48}

{ Return signed, long integers in [-2^31,2^31).  }
function mrand48: Longint; cdecl;
{$EXTERNALSYM mrand48}

function jrand48(XSubi: PWord): Longint; cdecl;
{$EXTERNALSYM jrand48}

{ Seed random number generator.  }
procedure srand48(Seedval: Longint); cdecl;
{$EXTERNALSYM srand48}

function seed48(Seed16v: PWord): PWord; cdecl;
{$EXTERNALSYM seed48}

procedure lcong48(Param: PWord); cdecl;
{$EXTERNALSYM lcong48}

{ Data structure for communication with thread safe versions.  }
type
  drand48_data = {packed} record
    x: packed array[0..3-1] of Word;      { Current state.  }
    a: packed array[0..3-1] of Word;      { Factor in congruential formula.  }
    c: Word;                              { Additive const. in congruential formula.  }
    old_x: packed array[0..3-1] of Word;  { Old state.  }
    init: Integer;                        { Flag for initializing.  }
  end;
  {$EXTERNALSYM drand48_data}
  TDrand48Data = drand48_data;
  PDrand48Data = ^TDrand48Data;

{ Return non-negative, double-precision floating-point value in [0.0,1.0).  }
function drand48_r(Buffer: PDrand48Data; var Result: Double): Integer; cdecl;
{$EXTERNALSYM drand48_r}

function erand48_r(XSubi: PWord; Buffer: PDrand48Data;
  var Result: Double): Integer; cdecl;
{$EXTERNALSYM erand48_r}

{ Return non-negative, long integer in [0,2^31).  }
function lrand48_r(Buffer: PDrand48Data; var Result: Longint): Integer; cdecl;
{$EXTERNALSYM lrand48_r}

function nrand48_r(XSubi: PWord; Buffer: PDrand48Data; var Result: Longint): Integer; cdecl;
{$EXTERNALSYM nrand48_r}

{ Return signed, long integers in [-2^31,2^31).  }
function mrand48_r(Buffer: PDrand48Data; var Result: Longint): Integer; cdecl;
{$EXTERNALSYM mrand48_r}

function jrand48_r(XSubi: PWord; Buffer: PDrand48Data; var Result: Longint): Integer; cdecl;
{$EXTERNALSYM jrand48_r}

{ Seed random number generator.  }
function srand48_r(Seedval: Longint; Buffer: PDrand48Data): Integer; cdecl;
{$EXTERNALSYM srand48_r}

function seed48_r(Seed16v: PWord; Buffer: PDrand48Data): Integer; cdecl;
{$EXTERNALSYM seed48_r}

function lcong48_r(Param: PWord; Buffer: PDrand48Data): Integer; cdecl;
{$EXTERNALSYM lcong48_r}

(*
  Memory allocation functions left out; translated in malloc.h below.
  The sole exception is posix_memalign which is only declared in
  stddlib.h
*)

{ Allocate memory of SIZE bytes with an alignment of ALIGNMENT.  }
function posix_memalign(var memptr: Pointer; alignment, size: size_t): Integer; cdecl;
{$EXTERNALSYM posix_memalign}

{ Abort execution and generate a core-dump.  }
procedure __abort; cdecl;
// HTI - Renamed from "abort" to "__abort";
{ $EXTERNALSYM abort}

{ Register a function to be called when `exit' is called.  }
type
  TAtExitProc = procedure; cdecl;
  TOnExitProc = procedure(Status: Integer; Arg: Pointer); cdecl;
  // Used anonymously in header file

function atexit(ExitProc: TAtExitProc): Integer; cdecl;
{$EXTERNALSYM atexit}

{ Register a function to be called with the status
   given to `exit' and the given argument.  }
function on_exit(ExitProc: TOnExitProc; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM on_exit}

{ Call all functions registered with `atexit' and `on_exit',
   in the reverse of the order in which they were registered
   perform stdio cleanup, and terminate program execution with STATUS.  }
// HTI - Renamed from "exit" to "__exit"
procedure __exit(Status: Integer); cdecl;
{ $EXTERNALSYM exit}

{ Terminate the program with STATUS without calling any of the
   functions registered with `atexit' or `on_exit'.  }
procedure _Exit(__status: Integer); cdecl;
{$EXTERNALSYM _Exit}

{ Return the value of envariable NAME, or NULL if it doesn't exist.  }
function getenv(Name: PChar): PChar; cdecl;
{$EXTERNALSYM getenv}

{ This function is similar to the above but returns NULL if the
   programs is running with SUID or SGID enabled.  }
function __secure_getenv(Name: PChar): PChar; cdecl;
{$EXTERNALSYM __secure_getenv}

{ The SVID says this is in <stdio.h>, but this seems a better place.	 }
{ Put STRING, which is of the form "NAME=VALUE", in the environment.
   If there is no `=', remove NAME from the environment.  }
function putenv(AString: PChar): Integer; cdecl;
{$EXTERNALSYM putenv}

{ Set NAME to VALUE in the environment.
   If REPLACE is nonzero, overwrite an existing value.  }
function setenv(Name: PChar; const Value: PChar; Replace: Integer): Integer; cdecl; overload;
function setenv(Name: PChar; const Value: PChar; Replace: LongBool): Integer; cdecl; overload;
{$EXTERNALSYM setenv}

{ Remove the variable NAME from the environment.  }
procedure unsetenv(Name: PChar); cdecl;
{$EXTERNALSYM unsetenv}

{ The `clearenv' was planned to be added to POSIX.1 but probably
   never made it.  Nevertheless the POSIX.9 standard (POSIX bindings
   for Fortran 77) requires this function.  }
function clearenv: Integer; cdecl;
{$EXTERNALSYM clearenv}


{ Generate a unique temporary file name from TEMPLATE.
   The last six characters of TEMPLATE must be "XXXXXX";
   they are replaced with a string that makes the file name unique.
   Returns TEMPLATE, or a null pointer if it cannot get a unique file name.  }
function mktemp(Template: PChar): PChar; cdecl;
{$EXTERNALSYM mktemp}

{ Generate a unique temporary file name from TEMPLATE.
   The last six characters of TEMPLATE must be "XXXXXX";
   they are replaced with a string that makes the filename unique.
   Returns a file descriptor open on the file for reading and writing,
   or -1 if it cannot create a uniquely-named file.  }
function mkstemp(Template: PChar): Integer; cdecl;
{$EXTERNALSYM mkstemp}

function mkstemp64(Template: PChar): Integer; cdecl;
{$EXTERNALSYM mkstemp64}

{ Create a unique temporary directory from TEMPLATE.
   The last six characters of TEMPLATE must be "XXXXXX";
   they are replaced with a string that makes the directory name unique.
   Returns TEMPLATE, or a null pointer if it cannot get a unique name.
   The directory is created mode 700.  }
function mkdtemp(Template: PChar): PChar; cdecl;
{$EXTERNALSYM mkdtemp}

{ Execute the given line as a shell command.  }
function system(Command: PChar): Integer; cdecl;
{$EXTERNALSYM system}

{ Return a malloc'd string containing the canonical absolute name of the
   named file.  The last file name component need not exist, and may be a
   symlink to a nonexistent file.  }
function canonicalize_file_name(Name: PChar): PChar; cdecl;
{$EXTERNALSYM canonicalize_file_name}

{ Return the canonical absolute name of file NAME.  The last file name
   component need not exist, and may be a symlink to a nonexistent file.
   If RESOLVED is null, the result is malloc'd; otherwise, if the canonical
   name is PATH_MAX chars or more, returns null with `errno' set to
   ENAMETOOLONG; if the name fits in fewer than PATH_MAX chars, returns the
   name in RESOLVED.  }
function realpath(Name, Resolved: PChar): PChar; cdecl;
{$EXTERNALSYM realpath}

{ Shorthand for type of comparison functions.  }
type
  __compar_fn_t = function(p1, p2: Pointer): Integer; cdecl;
  {$EXTERNALSYM __compar_fn_t}
  comparison_fn_t = __compar_fn_t;
  {$EXTERNALSYM comparison_fn_t}
  TCompareFunc = __compar_fn_t;

{ Do a binary search for KEY in BASE, which consists of NMEMB elements
   of SIZE bytes each, using COMPAR to perform the comparisons.  }
function bsearch(Key, Base: Pointer; NMemb, Size: size_t; CompFunc: TCompareFunc): Pointer; cdecl;
{$EXTERNALSYM bsearch}

{ Sort NMEMB elements of BASE, of SIZE bytes each,
   using COMPAR to perform the comparisons.  }
procedure qsort(Base: Pointer; NMemb, Size: size_t; CompFunc: TCompareFunc); cdecl;
{$EXTERNALSYM qsort}

{ Return the absolute value of X.  }
// HTI - Renamed from "abs" to "__abs"
function __abs(X: Integer): Integer; cdecl;
{ $EXTERNALSYM abs}

function labs(X: Longint): Longint; cdecl;
{$EXTERNALSYM labs}

function llabs(X: Int64): Int64; cdecl;
{$EXTERNALSYM llabs}

{ Return the `div_t', `ldiv_t' or `lldiv_t' representation
   of the value of NUMER over DENOM. }
{ GCC may have built-ins for these someday.  }
// HTI - Renamed from "div" to "__div"
function __div(Numer: Integer; Denom: Integer): div_t; cdecl;
{ $EXTERNALSYM div}

function ldiv(Numer: Longint; Denom: Longint): ldiv_t; cdecl;
{$EXTERNALSYM ldiv}

function lldiv(Numer: Int64; Denom: Int64): lldiv_t; cdecl;
{$EXTERNALSYM lldiv}

{ Convert floating point numbers to strings.  The returned values are
   valid only until another call to the same function.  }

{ Convert VALUE to a string with NDIGIT digits and return a pointer to
   this.  Set *DECPT with the position of the decimal character and *SIGN
   with the sign of the number.  }
function ecvt(Value: Double; NDigit: Integer; Decpt: PInteger;
  __sign: PInteger): PChar; cdecl;
{$EXTERNALSYM ecvt}

{ Convert VALUE to a string rounded to NDIGIT decimal digits.  Set *DECPT
   with the position of the decimal character and *SIGN with the sign of
   the number.  }
function fcvt(Value: Double; NDigit: Integer; Decpt: PInteger;
  __sign: PInteger): PChar; cdecl;
{$EXTERNALSYM fcvt}

{ If possible convert VALUE to a string with NDIGIT significant digits.
   Otherwise use exponential representation.  The resulting string will
   be written to BUF.  }
function gcvt(Value: Double; NDigit: Integer; Buf: PChar): PChar; cdecl;
{$EXTERNALSYM gcvt}

{ Long double versions of above functions.  }
function qecvt(Value: Extended; NDigit: Integer; Decpt: PInteger;
  Sign: PInteger): PChar; cdecl;

{$EXTERNALSYM qecvt}
function qfcvt(Value: Extended; NDigit: Integer; Decpt: PInteger;
  Sign: PInteger): PChar; cdecl;

{$EXTERNALSYM qfcvt}
function qgcvt(Value: Extended; NDigit: Integer;
  Buf: PChar): PChar; cdecl;
{$EXTERNALSYM qgcvt}

{ Reentrant version of the functions above which provide their own
   buffers.  }
function ecvt_r(Value: Double; NDigit: Integer; Decpt: PInteger;
  Sign: PInteger; Buf: PChar; Len: size_t): Integer; cdecl;
{$EXTERNALSYM ecvt_r}

function fcvt_r(Value: Double; NDigit: Integer; Decpt: PInteger;
  Sign: PInteger; Buf: PChar; Len: size_t): Integer; cdecl;
{$EXTERNALSYM fcvt_r}

function qecvt_r(Value: Extended; NDigit: Integer; Decpt: PInteger;
  Sign: PInteger; Buf: PChar; Len: size_t): Integer; cdecl;
{$EXTERNALSYM qecvt_r}

function qfcvt_r(Value: Extended; NDigit: Integer; Decpt: PInteger;
  Sign: PInteger; Buf: PChar; Len: size_t): Integer; cdecl;
{$EXTERNALSYM qfcvt_r}

{ Return the length of the multibyte character
   in S, which is no longer than N.  }
function mblen(const S: PChar; N: size_t): Integer; cdecl;
{$EXTERNALSYM mblen}

{ Return the length of the given multibyte character,
   putting its `wchar_t' representation in *PWC.  }
function mbtowc(PWC: Pwchar_t; const S: PChar; N: size_t): Integer; cdecl;
{$EXTERNALSYM mbtowc}

{ Put the multibyte character represented
   by WCHAR in S, returning its length.  }
function wctomb(S: PChar; WChar: wchar_t): Integer; cdecl;
{$EXTERNALSYM wctomb}

{ Convert a multibyte string to a wide char string.  }
function mbstowcs(Dest: Pwchar_t; const Source: PChar; N: size_t): size_t; cdecl;
{$EXTERNALSYM mbstowcs}

{ Convert a wide char string to multibyte string.  }
function wcstombs(Dest: PChar; const Source: Pwchar_t; N: size_t): size_t; cdecl;
{$EXTERNALSYM wcstombs}

{ Determine whether the string value of RESPONSE matches the affirmation
   or negative response expression as specified by the LC_MESSAGES category
   in the program's current locale.  Returns 1 if affirmative, 0 if
   negative, and -1 if not matching.  }
function rpmatch(const Response: PChar): Integer; cdecl;
{$EXTERNALSYM rpmatch}


{ Parse comma separated suboption from *OPTIONP and match against
   strings in TOKENS.  If found return index and set *VALUEP to
   optional value introduced by an equal sign.  If the suboption is
   not part of TOKENS return in *VALUEP beginning of unknown
   suboption.  On exit *OPTIONP is set to the beginning of the next
   token or at the terminating NUL character.  }
function getsubopt(Optionp: PPChar; Tokens: PPChar; Valuep: PPChar): Integer; cdecl;
{$EXTERNALSYM getsubopt}


(*
  setkey function declared elsewhere:
  extern void setkey (__const char *__key) __THROW;
*)

{ X/Open pseudo terminal handling.  }

{ Return a master pseudo-terminal handle.  }
function posix_openpt(__oflag: Integer): Integer; cdecl;
{$EXTERNALSYM posix_openpt}

{ The next four functions all take a master pseudo-tty fd and
   perform an operation on the associated slave:  }

{ Chown the slave to the calling user.  }
function grantpt(FileDes: Integer): Integer; cdecl;
{$EXTERNALSYM grantpt}

{ Release an internal lock so the slave can be opened.
   Call after grantpt().  }
function unlockpt(FileDes: Integer): Integer; cdecl;
{$EXTERNALSYM unlockpt}

{ Return the pathname of the pseudo terminal slave assoicated with
   the master FD is open on, or NULL on errors.
   The returned storage is good until the next call to this function.  }
function ptsname(FileDes: Integer): PChar; cdecl;
{$EXTERNALSYM ptsname}

{ Store at most BUFLEN characters of the pathname of the slave pseudo
   terminal associated with the master FD is open on in BUF.
   Return 0 on success, otherwise an error number.  }
function ptsname_r(FileDes: Integer; Buf: PChar;
  BufLen: size_t): Integer; cdecl;
{$EXTERNALSYM ptsname_r}

{ Open a master pseudo terminal and return its file descriptor.  }
function getpt: Integer; cdecl;
{$EXTERNALSYM getpt}

{ Put the 1 minute, 5 minute and 15 minute load averages into the first
   NELEM elements of LOADAVG.  Return the number written (never more than
   three, but may be less than NELEM), or -1 if an error occurred.  }
function getloadavg(__loadavg: PDouble; __nelem: Integer): Integer;
{$EXTERNALSYM getloadavg}


// Translated from malloc.h

{ Allocate SIZE bytes of memory.  }
function malloc(Size: size_t): Pointer; cdecl;
{$EXTERNALSYM malloc}

{ Allocate NMEMB elements of SIZE bytes each, all initialized to 0.  }
function calloc(NMemb, Size: size_t): Pointer; cdecl;
{$EXTERNALSYM calloc}

{ Re-allocate the previously allocated block
   in P, making the new block SIZE bytes long.  }
function realloc(P: Pointer; Size: size_t): Pointer; cdecl;
{$EXTERNALSYM realloc}

{ Free a block allocated by `malloc', `realloc' or `calloc'.  }
procedure free(P: Pointer); cdecl;
{$EXTERNALSYM free}

{ Free a block allocated by `calloc'. }
procedure cfree(P: Pointer); cdecl;
{$EXTERNALSYM cfree}

{ Allocate SIZE bytes allocated to ALIGNMENT bytes.  }
function memalign(Alignment: size_t; Size: size_t): Pointer; cdecl;
{$EXTERNALSYM memalign}

{ Allocate SIZE bytes on a page boundary.  }
function valloc(Size: size_t): Pointer; cdecl;
{$EXTERNALSYM valloc}

{ Equivalent to valloc(minimum-page-that-holds(n)), that is, round up
   __size to nearest pagesize. }
function pvalloc(Size: size_t): Pointer; cdecl;
{$EXTERNALSYM pvalloc}

{ Default value of `__morecore'.  }
function __default_morecore(Size: ptrdiff_t): Pointer; cdecl;
{$EXTERNALSYM __default_morecore}

{ SVID2/XPG mallinfo structure }
type
  _mallinfo = {packed} record
    arena: Integer;    { total space allocated from system }
    ordblks: Integer;  { number of non-inuse chunks }
    smblks: Integer;   { unused -- always zero }
    hblks: Integer;    { number of mmapped regions }
    hblkhd: Integer;   { total space in mmapped regions }
    usmblks: Integer;  { unused -- always zero }
    fsmblks: Integer;  { unused -- always zero }
    uordblks: Integer; { total allocated space }
    fordblks: Integer; { total non-inuse space }
    keepcost: Integer; { top-most, releasable (via malloc_trim) space }
  end;
  {.$EXTERNALSYM mallinfo} // Renamed from mallinfo to _mallinfo.
  TMallocInfo = _mallinfo;
  PMallocInfo = ^TMallocInfo;

{ Returns a copy of the updated current mallinfo. }
function mallinfo(): TMallocInfo; cdecl; // Returning struct = pass address to struct in gcc and dcc.
{$EXTERNALSYM mallinfo}

{ SVID2/XPG mallopt options }
const
  M_MXFAST  = 1;  { UNUSED in this malloc }
  {$EXTERNALSYM M_MXFAST}
  M_NLBLKS  = 2;  { UNUSED in this malloc }
  {$EXTERNALSYM M_NLBLKS}
  M_GRAIN   = 3;  { UNUSED in this malloc }
  {$EXTERNALSYM M_GRAIN}
  M_KEEP    = 4;  { UNUSED in this malloc }
  {$EXTERNALSYM M_KEEP}

{ mallopt options that actually do something }
const
  M_TRIM_THRESHOLD    = -1;
  {$EXTERNALSYM M_TRIM_THRESHOLD}
  M_TOP_PAD           = -2;
  {$EXTERNALSYM M_TOP_PAD}
  M_MMAP_THRESHOLD    = -3;
  {$EXTERNALSYM M_MMAP_THRESHOLD}
  M_MMAP_MAX          = -4;
  {$EXTERNALSYM M_MMAP_MAX}
  M_CHECK_ACTION      = -5;
  {$EXTERNALSYM M_CHECK_ACTION}

{ General SVID/XPG interface to tunable parameters. }
function mallopt(Parameter: Integer; Value: Integer): Integer; cdecl;
{$EXTERNALSYM mallopt}

{ Release all but pad bytes of freed top-most memory back to the
   system. Return 1 if successful, else 0. }
function malloc_trim(Pad: size_t): Integer; cdecl;
{$EXTERNALSYM malloc_trim}

{ Report the number of usable allocated bytes associated with allocated
   chunk P. }
function malloc_usable_size(P: Pointer): size_t; cdecl;
{$EXTERNALSYM malloc_usable_size}

{ Prints brief summary statistics on stderr. }
procedure malloc_stats(); cdecl;
{$EXTERNALSYM malloc_stats}

{ Record the state of all malloc variables in an opaque data structure. }
function malloc_get_state(): Pointer; cdecl;
{$EXTERNALSYM malloc_get_state}

{ Restore the state of all malloc variables from data obtained with
   malloc_get_state(). }
function malloc_set_state(P: Pointer): Integer; cdecl;
{$EXTERNALSYM malloc_set_state}

(* Declared as a local symbol
{ Activate a standard set of debugging hooks. }
procedure __malloc_check_init(); cdecl;
{$EXTERNALSYM __malloc_check_init}

*)


// Translated from sys/sysinfo.h

const
  SI_LOAD_SHIFT   = 16;
  {$EXTERNALSYM SI_LOAD_SHIFT}

type
  _sysinfo = {packed} record
    uptime: Integer;                    { Seconds since boot }
    loads: packed array[0..2] of LongWord;{ 1, 5, and 15 minute load averages }
    totalram: LongWord;                 { Total usable main memory size }
    freeram: LongWord;                  { Available memory size }
    sharedram: LongWord;                { Amount of shared memory }
    bufferram: LongWord;                { Memory used by buffers }
    totalswap: LongWord;                { Total swap space size }
    freeswap: LongWord;                 { swap space still available }
    procs: Word;                        { Number of current processes }
    _f: packed array[0..21] of Char;    { Pads structure to 64 bytes }
  end;
  TSysInfo = _sysinfo;
  PSysInfo = ^TSysInfo;
  {.$EXTERNALSYM sysinfo} // Renamed due to identifier conflict with sysinfo function

function sysinfo(var Info: TSysInfo): Integer; cdecl;
{$EXTERNALSYM sysinfo}

{ Return number of configured processors.  }
function get_nprocs_conf: Integer; cdecl;
{$EXTERNALSYM get_nprocs_conf}

{ Return number of available processors.  }
function get_nprocs: Integer; cdecl;
{$EXTERNALSYM get_nprocs}


{ Return number of physical pages of memory in the system.  }
function get_phys_pages: Integer; cdecl;
{$EXTERNALSYM get_phys_pages}

{ Return number of available physical pages of memory in the system.  }
function get_avphys_pages: Integer; cdecl;
{$EXTERNALSYM get_avphys_pages}

{ Macros }

function major(dev: dev_t): Integer;
{$EXTERNALSYM major}
function minor(dev: dev_t): Integer;
{$EXTERNALSYM minor}
function makedev(major, minor: Integer): dev_t;
{$EXTERNALSYM makedev}

function InitializeCriticalSection(var lpCriticalSection: TRTLCriticalSection): Integer;
function EnterCriticalSection(var lpCriticalSection: TRTLCriticalSection): Integer; cdecl;
function LeaveCriticalSection(var lpCriticalSection: TRTLCriticalSection): Integer; cdecl;
function TryEnterCriticalSection(var lpCriticalSection: TRTLCriticalSection): Boolean;
function DeleteCriticalSection(var lpCriticalSection: TRTLCriticalSection): Integer; cdecl;


// Translated from bits/dlfcn.h 

{ The MODE argument to `dlopen' contains one of the following: }
const
  RTLD_LAZY = 1;               { Lazy function call binding.  }
  {$EXTERNALSYM RTLD_LAZY}
  RTLD_NOW  = 2;               { Immediate function call binding.  } 
  {$EXTERNALSYM RTLD_NOW}
  RTLD_BINDING_MASK = RTLD_LAZY or RTLD_NOW;
  {$EXTERNALSYM RTLD_BINDING_MASK}

  RTLD_NOLOAD = 4;             { Do not load the object.  }
  {$EXTERNALSYM RTLD_NOLOAD}

{ If the following bit is set in the MODE argument to `dlopen',
   the symbols of the loaded object and its dependencies are made
   visible as if the object were linked directly into the program.  }
  RTLD_GLOBAL = $100;
  {$EXTERNALSYM RTLD_GLOBAL}

{ Unix98 demands the following flag which is the inverse to RTLD_GLOBAL.
   The implementation does this by default and so we can define the
   value to zero.  }
  RTLD_LOCAL  = 0;
  {$EXTERNALSYM RTLD_LOCAL}

{ Do not delete object when closed.  }
  RTLD_NODELETE = $1000;
  {$EXTERNALSYM RTLD_NODELETE}


// Translated from dlfcn.h

const
{ If the first argument of `dlsym' or `dlvsym' is set to RTLD_NEXT
   the run-time address of the symbol called NAME in the next shared
   object is returned.  The "next" relation is defined by the order
   the shared objects were loaded.  }
  RTLD_NEXT = Pointer(-1);
  {$EXTERNALSYM RTLD_NEXT}

{ If the first argument to `dlsym' or `dlvsym' is set to RTLD_DEFAULT
   the run-time address of the symbol called NAME in the global scope
   is returned.  }
  RTLD_DEFAULT = nil;
  {$EXTERNALSYM RTLD_DEFAULT}

type
{ Structure containing information about object searched using
   `dladdr'.  }
  Dl_info = {packed} record
	dli_fname: PChar;   { File name of defining object.  }
	dli_fbase: Pointer; { Load address of that object. }
	dli_sname: PChar;   { Name of nearest symbol. }
	dli_saddr: Pointer; { Exact value of nearest symbol. }
  end;
  {$EXTERNALSYM Dl_info}
  TDLInfo = Dl_info;
  PDLInfo = ^TDLInfo;

{ Open the shared object FILE and map it in; return a handle that can be
   passed to `dlsym' to get symbol values from it.  }
function dlopen(Filename: PChar; Flag: Integer): Pointer; cdecl;
{$EXTERNALSYM dlopen}

{ Unmap and close a shared object opened by `dlopen'.
   The handle cannot be used again after calling `dlclose'.  }
function dlclose(Handle: Pointer): Integer;  cdecl;
{$EXTERNALSYM dlclose}

{ Find the run-time address in the shared object HANDLE refers to
   of the symbol called NAME.  }
function dlsym(Handle: Pointer; Symbol: PChar): Pointer;  cdecl;
{$EXTERNALSYM dlsym}

{ Find the run-time address in the shared object HANDLE refers to
   of the symbol called NAME with VERSION.  }
function dlvsym(Handle: Pointer; Symbol: PChar; Version: PChar): Pointer; cdecl;
{$EXTERNALSYM dlvsym}

{ When any of the above functions fails, call this function
   to return a string describing the error.  Each call resets
   the error string so that a following call returns null.  }
function dlerror: PChar;  cdecl;
{$EXTERNALSYM dlerror}

{ Fill in *INFO with the following information about ADDRESS.
   Returns 0 iff no shared object's segments contain that address.  }
function dladdr(Address: Pointer; var Info: TDLInfo): Integer; cdecl;
{$EXTERNALSYM dladdr}


// Translated from locale.h

const
{  These are the possibilities for the first argument to setlocale.
   The code assumes that the lowest LC_* symbol has the value zero.  }
  LC_CTYPE    = 0;
  {$EXTERNALSYM LC_CTYPE}
  LC_NUMERIC  = 1;
  {$EXTERNALSYM LC_NUMERIC}
  LC_TIME     = 2;
  {$EXTERNALSYM LC_TIME}
  LC_COLLATE  = 3;
  {$EXTERNALSYM LC_COLLATE}
  LC_MONETARY = 4;
  {$EXTERNALSYM LC_MONETARY}
  LC_MESSAGES = 5;
  {$EXTERNALSYM LC_MESSAGES}
  LC_ALL      = 6;
  {$EXTERNALSYM LC_ALL}
  LC_PAPER    = 7;
  {$EXTERNALSYM LC_PAPER}
  LC_NAME     = 8;
  {$EXTERNALSYM LC_NAME}
  LC_ADDRESS  = 9;
  {$EXTERNALSYM LC_ADDRESS}
  LC_TELEPHONE = 10;
  {$EXTERNALSYM LC_TELEPHONE}
  LC_MEASUREMENT = 11;
  {$EXTERNALSYM LC_MEASUREMENT}
  LC_IDENTIFICATION = 12;
  {$EXTERNALSYM LC_IDENTIFICATION}

type
{ Structure giving information about numeric and monetary notation.  }
    PLConv = ^TLConv;
    TLConv = {packed} record
      { Numeric (non-monetary) information.  }

      decimal_point: PChar;             { Decimal point character.  }
      thousands_sep: PChar;             { Thousands separator.  }
      { Each element is the number of digits in each group;
         elements with higher indices are farther left.
         An element with value CHAR_MAX means that no further grouping is done.
         An element with value 0 means that the previous element is used
         for all groups farther left.  }
      grouping: PChar;

      { Monetary information.  }

      { First three chars are a currency symbol from ISO 4217.
         Fourth char is the separator.  Fifth char is '\0'.  }
      int_curr_symbol: PChar;
      currency_symbol: PChar;           { Local currency symbol.  }
      mon_decimal_point: PChar;         { Decimal point character.  }
      mon_thousands_sep: PChar;         { Thousands separator.  }
      mon_grouping: PChar;              { Like `grouping' element (above).  }
      positive_sign: PChar;             { Sign for positive values.  }
      negative_sign: PChar;             { Sign for negative values.  }
      int_frac_digits: Byte;            { Int'l fractional digits.  }
      frac_digits: Byte;                { Local fractional digits.  }
      { 1 if currency_symbol precedes a positive value, 0 if succeeds.  }
      p_cs_precedes: Boolean;
      { 1 iff a space separates currency_symbol from a positive value.  }
      p_sep_by_space: Boolean;
      { 1 if currency_symbol precedes a negative value, 0 if succeeds.  }
      n_cs_precedes: Boolean;
      { 1 iff a space separates currency_symbol from a negative value.  }
      n_sep_by_space: Boolean;
      { Positive and negative sign positions:
         0 Parentheses surround the quantity and currency_symbol.
         1 The sign string precedes the quantity and currency_symbol.
         2 The sign string follows the quantity and currency_symbol.
         3 The sign string immediately precedes the currency_symbol.
         4 The sign string immediately follows the currency_symbol.  }
      p_sign_posn: Byte;
      n_sign_posn: Byte;

      { 1 if int_curr_symbol precedes a positive value, 0 if succeeds.  }
      int_p_cs_precedes: Byte;
      { 1 iff a space separates int_curr_symbol from a positive value.  }
      int_p_sep_by_space: Byte;
      { 1 if int_curr_symbol precedes a negative value, 0 if succeeds.  }
      int_n_cs_precedes: Byte;
      { 1 iff a space separates int_curr_symbol from a negative value.  }
      int_n_sep_by_space: Byte;
      { Positive and negative sign positions:
         0 Parentheses surround the quantity and int_curr_symbol.
         1 The sign string precedes the quantity and int_curr_symbol.
         2 The sign string follows the quantity and int_curr_symbol.
         3 The sign string immediately precedes the int_curr_symbol.
         4 The sign string immediately follows the int_curr_symbol.  }
      int_p_sign_posn: Byte;
      int_n_sign_posn: Byte;
    end;
    lconv = TLConv;
    {$EXTERNALSYM lconv}
    _lconv = TLConv;


{ Set and/or return the current locale.  }
function setlocale(__category: Integer; __locale: PChar): PChar; cdecl;
{$EXTERNALSYM setlocale}

{ Return the numeric/monetary information for the current locale.  }
function localeconv: PLConv; cdecl;
{$EXTERNALSYM localeconv}

{  The concept of one static locale per category is not very well
   thought out.  Many applications will need to process its data using
   information from several different locales.  Another application is
   the implementation of the internationalization handling in the
   upcoming ISO C++ standard library.  To support this another set of
   the functions using locale data exist which have an additional
   argument.

   Attention: all these functions are *not* standardized in any form.
   This is a proof-of-concept implementation.  }

{ Return a reference to a data structure representing a set of locale
   datasets.  Unlike for the CATEGORY parameter for `setlocale' the
   CATEGORY_MASK parameter here uses a single bit for each category.
   I.e., 1 << LC_CTYPE means to load data for this category.  If
   BASE is non-null the appropriate category information in the BASE
   record is replaced.  }
function __newlocale(__category_mask: Integer; __locale: PChar; __base: PLocale): PLocale; cdecl;
{$EXTERNALSYM __newlocale}

{ Return a duplicate of the set of locale in DATASET.  All usage
   counters are increased if necessary.  }
function __duplocale(Dataset: PLocale): PLocale; cdecl;
{$EXTERNALSYM __duplocale}

{ Free the data associated with a locale dataset previously returned
   by a call to `setlocale_r'.  }
procedure __freelocale(Dataset: PLocale);
{$EXTERNALSYM __freelocale}


// Translated from nl_types.h

const
{ The default message set used by the gencat program.  }
  NL_SETD = 1;
  {$EXTERNALSYM NL_SETD}

{ Value for FLAG parameter of `catgets' to say we want XPG4 compliance.  }
  NL_CAT_LOCALE = 1;
  {$EXTERNALSYM NL_CAT_LOCALE}

type
{ Message catalog descriptor type.  }
  nl_catd = Pointer;
  {$EXTERNALSYM nl_catd}

{ Type used by `nl_langinfo'.  }
  nl_item = Integer;
  {$EXTERNALSYM nl_item}

{ Open message catalog for later use, returning descriptor.  }
function catopen(__cat_name: PChar; __flag: Integer): nl_catd; cdecl;
{$EXTERNALSYM catopen}

{ Return translation with NUMBER in SET of CATALOG; if not found
   return STRING.  }
function catgets(__catalog: nl_catd; __set: Integer; __number: Integer;
  __string: PChar): PChar; cdecl;
{$EXTERNALSYM catgets}

{ Close message CATALOG.  }
function catclose(__catalog: nl_catd): Integer; cdecl;
{$EXTERNALSYM catclose}


// Translated from langinfo.h

const
  { Abbreviated days of the week. }
  ABDAY_1 = (LC_TIME shl 16) or 0;      // Sun
  {$EXTERNALSYM ABDAY_1}
  ABDAY_2 = ABDAY_1 + 1;             // Mon
  {$EXTERNALSYM ABDAY_2}
  ABDAY_3 = ABDAY_2 + 1;             // Tue
  {$EXTERNALSYM ABDAY_3}
  ABDAY_4 = ABDAY_3 + 1;             // Wed
  {$EXTERNALSYM ABDAY_4}
  ABDAY_5 = ABDAY_4 + 1;             // Thu
  {$EXTERNALSYM ABDAY_5}
  ABDAY_6 = ABDAY_5 + 1;             // Fri
  {$EXTERNALSYM ABDAY_6}
  ABDAY_7 = ABDAY_6 + 1;             // Sat
  {$EXTERNALSYM ABDAY_7}

  { Long-named days of the week }
  DAY_1 = ABDAY_7 + 1;               // Sunday
  {$EXTERNALSYM DAY_1}
  DAY_2 = DAY_1 + 1;                 // Monday
  {$EXTERNALSYM DAY_2}
  DAY_3 = DAY_2 + 1;                 // Tuesday
  {$EXTERNALSYM DAY_3}
  DAY_4 = DAY_3 + 1;                 // Wednesday
  {$EXTERNALSYM DAY_4}
  DAY_5 = DAY_4 + 1;                 // Thursday
  {$EXTERNALSYM DAY_5}
  DAY_6 = DAY_5 + 1;                 // Friday
  {$EXTERNALSYM DAY_6}
  DAY_7 = DAY_6 + 1;                 // Saturday
  {$EXTERNALSYM DAY_7}

  { Abbreviated month names. }
  ABMON_1  = DAY_7 + 1;              // Jan
  {$EXTERNALSYM ABMON_1}
  ABMON_2  = ABMON_1 + 1;            // Feb
  {$EXTERNALSYM ABMON_2}
  ABMON_3  = ABMON_2 + 1;            // Mar
  {$EXTERNALSYM ABMON_3}
  ABMON_4  = ABMON_3 + 1;            // Apr
  {$EXTERNALSYM ABMON_4}
  ABMON_5  = ABMON_4 + 1;            // May
  {$EXTERNALSYM ABMON_5}
  ABMON_6  = ABMON_5 + 1;            // Jun
  {$EXTERNALSYM ABMON_6}
  ABMON_7  = ABMON_6 + 1;            // Jul
  {$EXTERNALSYM ABMON_7}
  ABMON_8  = ABMON_7 + 1;            // Aug
  {$EXTERNALSYM ABMON_8}
  ABMON_9  = ABMON_8 + 1;            // Sep
  {$EXTERNALSYM ABMON_9}
  ABMON_10 = ABMON_9 + 1;            // Oct
  {$EXTERNALSYM ABMON_10}
  ABMON_11 = ABMON_10 + 1;           // Nov
  {$EXTERNALSYM ABMON_11}
  ABMON_12 = ABMON_11 + 1;           // Dec
  {$EXTERNALSYM ABMON_12}

  { Long month names. }
  MON_1  = ABMON_12 + 1;             // January
  {$EXTERNALSYM MON_1}
  MON_2  = MON_1 + 1;                // February
  {$EXTERNALSYM MON_2}
  MON_3  = MON_2 + 1;                // March
  {$EXTERNALSYM MON_3}
  MON_4  = MON_3 + 1;                // April
  {$EXTERNALSYM MON_4}
  MON_5  = MON_4 + 1;                // May
  {$EXTERNALSYM MON_5}
  MON_6  = MON_5 + 1;                // June
  {$EXTERNALSYM MON_6}
  MON_7  = MON_6 + 1;                // July
  {$EXTERNALSYM MON_7}
  MON_8  = MON_7 + 1;                // August
  {$EXTERNALSYM MON_8}
  MON_9  = MON_8 + 1;                // September
  {$EXTERNALSYM MON_9}
  MON_10 = MON_9 + 1;                // October
  {$EXTERNALSYM MON_10}
  MON_11 = MON_10 + 1;               // November
  {$EXTERNALSYM MON_11}
  MON_12 = MON_11 + 1;               // December
  {$EXTERNALSYM MON_12}

  AM_STR = MON_12 + 1;               // Ante meridian string
  {$EXTERNALSYM AM_STR}
  PM_STR = AM_STR + 1;               // Post meridian string
  {$EXTERNALSYM PM_STR}

  D_T_FMT     = PM_STR + 1;          // Date and time format
  {$EXTERNALSYM D_T_FMT}
  D_FMT       = D_T_FMT + 1;         // Date format
  {$EXTERNALSYM D_FMT}
  T_FMT       = D_T_FMT + 2;         // Time format
  {$EXTERNALSYM T_FMT}
  T_FMT_AMPM  = D_T_FMT + 3;         // 12-hour time format
  {$EXTERNALSYM T_FMT_AMPM}

  ERA         = T_FMT_AMPM + 1;      // Alternate era
  {$EXTERNALSYM ERA}
  ERA_YEAR    = ERA + 1;             // Year in alternate era format
  {$EXTERNALSYM ERA_YEAR}
  ERA_D_FMT   = ERA + 2;             // Date in alternate era format
  {$EXTERNALSYM ERA_D_FMT}
  ALT_DIGITS  = ERA + 3;             // Alternate symbols for digits
  {$EXTERNALSYM ALT_DIGITS}
  ERA_D_T_FMT = ERA + 4;             // Date and time in alternate era format
  {$EXTERNALSYM ERA_D_T_FMT}
  ERA_T_FMT   = ERA + 5;             // Time in alternate era format
  {$EXTERNALSYM ERA_T_FMT}

  _NL_TIME_ERA_NUM_ENTRIES = ERA_T_FMT + 1;    // Number entries in the era arrays.
  {$EXTERNALSYM _NL_TIME_ERA_NUM_ENTRIES}
  _NL_TIME_ERA_ENTRIES     = ERA_T_FMT + 2;    // Structure with era entries in usable form.
  {$EXTERNALSYM _NL_TIME_ERA_ENTRIES}

  _NL_WABDAY_1 = _NL_TIME_ERA_ENTRIES + 1;     { Sun }
  {$EXTERNALSYM _NL_WABDAY_1}
  _NL_WABDAY_2 = _NL_WABDAY_1 + 1;
  {$EXTERNALSYM _NL_WABDAY_2}
  _NL_WABDAY_3 = _NL_WABDAY_1 + 2;
  {$EXTERNALSYM _NL_WABDAY_3}
  _NL_WABDAY_4 = _NL_WABDAY_1 + 3;
  {$EXTERNALSYM _NL_WABDAY_4}
  _NL_WABDAY_5 = _NL_WABDAY_1 + 4;
  {$EXTERNALSYM _NL_WABDAY_5}
  _NL_WABDAY_6 = _NL_WABDAY_1 + 5;
  {$EXTERNALSYM _NL_WABDAY_6}
  _NL_WABDAY_7 = _NL_WABDAY_1 + 6;
  {$EXTERNALSYM _NL_WABDAY_7}

  { Long-named days of the week. }
  _NL_WDAY_1 = _NL_WABDAY_7 + 1;               { Sunday }
  {$EXTERNALSYM _NL_WDAY_1}
  _NL_WDAY_2 = _NL_WDAY_1 + 1;                 { Monday }
  {$EXTERNALSYM _NL_WDAY_2}
  _NL_WDAY_3 = _NL_WDAY_1 + 2;                 { Tuesday }
  {$EXTERNALSYM _NL_WDAY_3}
  _NL_WDAY_4 = _NL_WDAY_1 + 3;                 { Wednesday }
  {$EXTERNALSYM _NL_WDAY_4}
  _NL_WDAY_5 = _NL_WDAY_1 + 4;                 { Thursday }
  {$EXTERNALSYM _NL_WDAY_5}
  _NL_WDAY_6 = _NL_WDAY_1 + 5;                 { Friday }
  {$EXTERNALSYM _NL_WDAY_6}
  _NL_WDAY_7 = _NL_WDAY_1 + 6;                 { Saturday }
  {$EXTERNALSYM _NL_WDAY_7}

  { Abbreviated month names.  }
  _NL_WABMON_1 = _NL_WDAY_7 + 1;               { Jan }
  {$EXTERNALSYM _NL_WABMON_1}
  _NL_WABMON_2 = _NL_WABMON_1 + 1;
  {$EXTERNALSYM _NL_WABMON_2}
  _NL_WABMON_3 = _NL_WABMON_1 + 2;
  {$EXTERNALSYM _NL_WABMON_3}
  _NL_WABMON_4 = _NL_WABMON_1 + 3;
  {$EXTERNALSYM _NL_WABMON_4}
  _NL_WABMON_5 = _NL_WABMON_1 + 4;
  {$EXTERNALSYM _NL_WABMON_5}
  _NL_WABMON_6 = _NL_WABMON_1 + 5;
  {$EXTERNALSYM _NL_WABMON_6}
  _NL_WABMON_7 = _NL_WABMON_1 + 6;
  {$EXTERNALSYM _NL_WABMON_7}
  _NL_WABMON_8 = _NL_WABMON_1 + 7;
  {$EXTERNALSYM _NL_WABMON_8}
  _NL_WABMON_9 = _NL_WABMON_1 + 8;
  {$EXTERNALSYM _NL_WABMON_9}
  _NL_WABMON_10 = _NL_WABMON_1 + 9;
  {$EXTERNALSYM _NL_WABMON_10}
  _NL_WABMON_11 = _NL_WABMON_1 + 10;
  {$EXTERNALSYM _NL_WABMON_11}
  _NL_WABMON_12 = _NL_WABMON_1 + 11;
  {$EXTERNALSYM _NL_WABMON_12}

  { Long month names.  }
  _NL_WMON_1 = _NL_WABMON_12 + 1;              { January }
  {$EXTERNALSYM _NL_WMON_1}
  _NL_WMON_2 = _NL_WMON_1 + 1;
  {$EXTERNALSYM _NL_WMON_2}
  _NL_WMON_3 = _NL_WMON_1 + 2;
  {$EXTERNALSYM _NL_WMON_3}
  _NL_WMON_4 = _NL_WMON_1 + 3;
  {$EXTERNALSYM _NL_WMON_4}
  _NL_WMON_5 = _NL_WMON_1 + 4;
  {$EXTERNALSYM _NL_WMON_5}
  _NL_WMON_6 = _NL_WMON_1 + 5;
  {$EXTERNALSYM _NL_WMON_6}
  _NL_WMON_7 = _NL_WMON_1 + 6;
  {$EXTERNALSYM _NL_WMON_7}
  _NL_WMON_8 = _NL_WMON_1 + 7;
  {$EXTERNALSYM _NL_WMON_8}
  _NL_WMON_9 = _NL_WMON_1 + 8;
  {$EXTERNALSYM _NL_WMON_9}
  _NL_WMON_10 = _NL_WMON_1 + 9;
  {$EXTERNALSYM _NL_WMON_10}
  _NL_WMON_11 = _NL_WMON_1 + 10;
  {$EXTERNALSYM _NL_WMON_11}
  _NL_WMON_12 = _NL_WMON_1 + 11;
  {$EXTERNALSYM _NL_WMON_12}

  _NL_WAM_STR =	_NL_WMON_12 + 1;               { Ante meridian string.  }
  {$EXTERNALSYM _NL_WAM_STR}
  _NL_WPM_STR =	_NL_WAM_STR + 1;               { Post meridian string.  }
  {$EXTERNALSYM _NL_WPM_STR}

  _NL_WD_T_FMT = _NL_WPM_STR + 1;              { Date and time format for strftime.  }
  {$EXTERNALSYM _NL_WD_T_FMT}
  _NL_WD_FMT = _NL_WD_T_FMT + 1;               { Date format for strftime.  }
  {$EXTERNALSYM _NL_WD_FMT}
  _NL_WT_FMT =	_NL_WD_T_FMT + 2;              { Time format for strftime.  }
  {$EXTERNALSYM _NL_WT_FMT}
  _NL_WT_FMT_AMPM = _NL_WD_T_FMT + 3;          { 12-hour time format for strftime.  }
  {$EXTERNALSYM _NL_WT_FMT_AMPM}

  _NL_WERA_YEAR = _NL_WT_FMT_AMPM + 1;         { Year in alternate era format.  }
  {$EXTERNALSYM _NL_WERA_YEAR}
  _NL_WERA_D_FMT = _NL_WERA_YEAR + 1;          { Date in alternate era format.  }
  {$EXTERNALSYM _NL_WERA_D_FMT}
  _NL_WALT_DIGITS = _NL_WERA_YEAR + 2;         { Alternate symbols for digits.  }
  {$EXTERNALSYM _NL_WALT_DIGITS}
  _NL_WERA_D_T_FMT = _NL_WERA_YEAR + 3;        { Date and time in alternate era format.  }
  {$EXTERNALSYM _NL_WERA_D_T_FMT}
  _NL_WERA_T_FMT = _NL_WERA_YEAR + 4;          { Time in alternate era format.  }
  {$EXTERNALSYM _NL_WERA_T_FMT}

  _NL_TIME_WEEK_NDAYS = _NL_WERA_T_FMT + 1;
  {$EXTERNALSYM _NL_TIME_WEEK_NDAYS}
  _NL_TIME_WEEK_1STDAY = _NL_TIME_WEEK_NDAYS + 1;
  {$EXTERNALSYM _NL_TIME_WEEK_1STDAY}
  _NL_TIME_WEEK_1STWEEK = _NL_TIME_WEEK_NDAYS + 2;
  {$EXTERNALSYM _NL_TIME_WEEK_1STWEEK}
  _NL_TIME_FIRST_WEEKDAY = _NL_TIME_WEEK_NDAYS + 3;
  {$EXTERNALSYM _NL_TIME_FIRST_WEEKDAY}
  _NL_TIME_FIRST_WORKDAY = _NL_TIME_WEEK_NDAYS + 4;
  {$EXTERNALSYM _NL_TIME_FIRST_WORKDAY}
  _NL_TIME_CAL_DIRECTION = _NL_TIME_WEEK_NDAYS + 5;
  {$EXTERNALSYM _NL_TIME_CAL_DIRECTION}
  _NL_TIME_TIMEZONE = _NL_TIME_WEEK_NDAYS + 6;
  {$EXTERNALSYM _NL_TIME_TIMEZONE}

  _DATE_FMT = _NL_TIME_TIMEZONE + 1;            { strftime format for date.  }
  {$EXTERNALSYM _DATE_FMT}
  _NL_W_DATE_FMT = _DATE_FMT + 1;
  {$EXTERNALSYM _NL_W_DATE_FMT}

  _NL_NUM_LC_TIME          = _NL_W_DATE_FMT + 1;    // Number of indices in LC_TIME category.
  {$EXTERNALSYM _NL_NUM_LC_TIME}

  {  LC_COLLATE category: text sorting.
     This information is accessed by the strcoll and strxfrm functions.
     These `nl_langinfo' names are used only internally.  }
  _NL_COLLATE_NRULES         = (LC_COLLATE shl 16) or 0;
  {$EXTERNALSYM _NL_COLLATE_NRULES}
  _NL_COLLATE_RULESETS       = _NL_COLLATE_NRULES + 1;
  {$EXTERNALSYM _NL_COLLATE_RULESETS}
  _NL_COLLATE_TABLEMB        = _NL_COLLATE_NRULES + 2;
  {$EXTERNALSYM _NL_COLLATE_TABLEMB}
  _NL_COLLATE_WEIGHTMB       = _NL_COLLATE_NRULES + 3;
  {$EXTERNALSYM _NL_COLLATE_WEIGHTMB}
  _NL_COLLATE_EXTRAMB        = _NL_COLLATE_NRULES + 4;
  {$EXTERNALSYM _NL_COLLATE_EXTRAMB}
  _NL_COLLATE_INDIRECTMB     = _NL_COLLATE_NRULES + 5;
  {$EXTERNALSYM _NL_COLLATE_INDIRECTMB}
  _NL_COLLATE_GAP1           = _NL_COLLATE_NRULES + 6;
  {$EXTERNALSYM _NL_COLLATE_GAP1}
  _NL_COLLATE_GAP2           = _NL_COLLATE_NRULES + 7;
  {$EXTERNALSYM _NL_COLLATE_GAP2}
  _NL_COLLATE_GAP3           = _NL_COLLATE_NRULES + 8;
  {$EXTERNALSYM _NL_COLLATE_GAP3}
  _NL_COLLATE_TABLEWC        = _NL_COLLATE_NRULES + 9;
  {$EXTERNALSYM _NL_COLLATE_TABLEWC}
  _NL_COLLATE_WEIGHTWC       = _NL_COLLATE_NRULES + 10;
  {$EXTERNALSYM _NL_COLLATE_WEIGHTWC}
  _NL_COLLATE_EXTRAWC        = _NL_COLLATE_NRULES + 11;
  {$EXTERNALSYM _NL_COLLATE_EXTRAWC}
  _NL_COLLATE_INDIRECTWC     = _NL_COLLATE_NRULES + 12;
  {$EXTERNALSYM _NL_COLLATE_INDIRECTWC}
  _NL_COLLATE_SYMB_HASH_SIZEMB = _NL_COLLATE_NRULES + 13;
  {$EXTERNALSYM _NL_COLLATE_SYMB_HASH_SIZEMB}
  _NL_COLLATE_SYMB_TABLEMB   = _NL_COLLATE_NRULES + 14;
  {$EXTERNALSYM _NL_COLLATE_SYMB_TABLEMB}
  _NL_COLLATE_SYMB_EXTRAMB   = _NL_COLLATE_NRULES + 15;
  {$EXTERNALSYM _NL_COLLATE_SYMB_EXTRAMB}
  _NL_COLLATE_COLLSEQMB      = _NL_COLLATE_NRULES + 16;
  {$EXTERNALSYM _NL_COLLATE_COLLSEQMB}
  _NL_COLLATE_COLLSEQWC      = _NL_COLLATE_NRULES + 17;
  {$EXTERNALSYM _NL_COLLATE_COLLSEQWC}
  _NL_NUM_LC_COLLATE         = _NL_COLLATE_COLLSEQWC + 1;
  {$EXTERNALSYM _NL_NUM_LC_COLLATE}

  {  LC_CTYPE category: character classification.
     This information is accessed by the functions in <ctype.h>.
     These `nl_langinfo' names are used only internally.  }
  _NL_CTYPE_CLASS        = (LC_CTYPE shl 16) or 0;
  {$EXTERNALSYM _NL_CTYPE_CLASS}
  _NL_CTYPE_TOUPPER      = _NL_CTYPE_CLASS + 1;
  {$EXTERNALSYM _NL_CTYPE_TOUPPER}
  _NL_CTYPE_GAP1         = _NL_CTYPE_CLASS + 2;
  {$EXTERNALSYM _NL_CTYPE_GAP1}
  _NL_CTYPE_TOLOWER      = _NL_CTYPE_CLASS + 3;
  {$EXTERNALSYM _NL_CTYPE_TOLOWER}
  _NL_CTYPE_GAP2         = _NL_CTYPE_CLASS + 4;
  {$EXTERNALSYM _NL_CTYPE_GAP2}
  _NL_CTYPE_CLASS32      = _NL_CTYPE_CLASS + 5;
  {$EXTERNALSYM _NL_CTYPE_CLASS32}
  _NL_CTYPE_GAP3         = _NL_CTYPE_CLASS + 6;
  {$EXTERNALSYM _NL_CTYPE_GAP3}
  _NL_CTYPE_GAP4     = _NL_CTYPE_CLASS + 7;
  {$EXTERNALSYM _NL_CTYPE_GAP4}
  _NL_CTYPE_GAP5    = _NL_CTYPE_CLASS + 8;
  {$EXTERNALSYM _NL_CTYPE_GAP5}
  _NL_CTYPE_GAP6  = _NL_CTYPE_CLASS + 9;
  {$EXTERNALSYM _NL_CTYPE_GAP6}
  _NL_CTYPE_CLASS_NAMES  = _NL_CTYPE_CLASS + 10;
  {$EXTERNALSYM _NL_CTYPE_CLASS_NAMES}
  _NL_CTYPE_MAP_NAMES    = _NL_CTYPE_CLASS + 11;
  {$EXTERNALSYM _NL_CTYPE_MAP_NAMES}
  _NL_CTYPE_WIDTH        = _NL_CTYPE_CLASS + 12;
  {$EXTERNALSYM _NL_CTYPE_WIDTH}
  _NL_CTYPE_MB_CUR_MAX   = _NL_CTYPE_CLASS + 13;
  {$EXTERNALSYM _NL_CTYPE_MB_CUR_MAX}
  _NL_CTYPE_CODESET_NAME = _NL_CTYPE_CLASS + 14;
  {$EXTERNALSYM _NL_CTYPE_CODESET_NAME}
  CODESET = _NL_CTYPE_CODESET_NAME;
  {$EXTERNALSYM CODESET}
  _NL_CTYPE_TOUPPER32 = _NL_CTYPE_CLASS + 15;
  {$EXTERNALSYM _NL_CTYPE_TOUPPER32}
  _NL_CTYPE_TOLOWER32 = _NL_CTYPE_CLASS + 16;
  {$EXTERNALSYM _NL_CTYPE_TOLOWER32}
  _NL_CTYPE_CLASS_OFFSET = _NL_CTYPE_CLASS + 17;
  {$EXTERNALSYM _NL_CTYPE_CLASS_OFFSET}
  _NL_CTYPE_MAP_OFFSET = _NL_CTYPE_CLASS + 18;
  {$EXTERNALSYM _NL_CTYPE_MAP_OFFSET}

  _NL_CTYPE_INDIGITS_MB_LEN = _NL_CTYPE_MAP_OFFSET + 1;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS_MB_LEN}
  _NL_CTYPE_INDIGITS0_MB = _NL_CTYPE_INDIGITS_MB_LEN + 1;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS0_MB}
  _NL_CTYPE_INDIGITS1_MB = _NL_CTYPE_INDIGITS_MB_LEN + 2;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS1_MB}
  _NL_CTYPE_INDIGITS2_MB = _NL_CTYPE_INDIGITS_MB_LEN + 3;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS2_MB}
  _NL_CTYPE_INDIGITS3_MB = _NL_CTYPE_INDIGITS_MB_LEN + 4;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS3_MB}
  _NL_CTYPE_INDIGITS4_MB = _NL_CTYPE_INDIGITS_MB_LEN + 5;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS4_MB}
  _NL_CTYPE_INDIGITS5_MB = _NL_CTYPE_INDIGITS_MB_LEN + 6;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS5_MB}
  _NL_CTYPE_INDIGITS6_MB = _NL_CTYPE_INDIGITS_MB_LEN + 7;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS6_MB}
  _NL_CTYPE_INDIGITS7_MB = _NL_CTYPE_INDIGITS_MB_LEN + 8;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS7_MB}
  _NL_CTYPE_INDIGITS8_MB = _NL_CTYPE_INDIGITS_MB_LEN + 9;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS8_MB}
  _NL_CTYPE_INDIGITS9_MB = _NL_CTYPE_INDIGITS_MB_LEN + 10;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS9_MB}
  _NL_CTYPE_INDIGITS_WC_LEN = _NL_CTYPE_INDIGITS_MB_LEN + 11;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS_WC_LEN}
  _NL_CTYPE_INDIGITS0_WC = _NL_CTYPE_INDIGITS_MB_LEN + 12;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS0_WC}
  _NL_CTYPE_INDIGITS1_WC = _NL_CTYPE_INDIGITS_MB_LEN + 13;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS1_WC}
  _NL_CTYPE_INDIGITS2_WC = _NL_CTYPE_INDIGITS_MB_LEN + 14;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS2_WC}
  _NL_CTYPE_INDIGITS3_WC = _NL_CTYPE_INDIGITS_MB_LEN + 15;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS3_WC}
  _NL_CTYPE_INDIGITS4_WC = _NL_CTYPE_INDIGITS_MB_LEN + 16;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS4_WC}
  _NL_CTYPE_INDIGITS5_WC = _NL_CTYPE_INDIGITS_MB_LEN + 17;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS5_WC}
  _NL_CTYPE_INDIGITS6_WC = _NL_CTYPE_INDIGITS_MB_LEN + 18;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS6_WC}
  _NL_CTYPE_INDIGITS7_WC = _NL_CTYPE_INDIGITS_MB_LEN + 19;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS7_WC}
  _NL_CTYPE_INDIGITS8_WC = _NL_CTYPE_INDIGITS_MB_LEN + 20;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS8_WC}
  _NL_CTYPE_INDIGITS9_WC = _NL_CTYPE_INDIGITS_MB_LEN + 21;
  {$EXTERNALSYM _NL_CTYPE_INDIGITS9_WC}
  _NL_CTYPE_OUTDIGIT0_MB = _NL_CTYPE_INDIGITS_MB_LEN + 22;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT0_MB}
  _NL_CTYPE_OUTDIGIT1_MB = _NL_CTYPE_INDIGITS_MB_LEN + 23;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT1_MB}
  _NL_CTYPE_OUTDIGIT2_MB = _NL_CTYPE_INDIGITS_MB_LEN + 24;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT2_MB}
  _NL_CTYPE_OUTDIGIT3_MB = _NL_CTYPE_INDIGITS_MB_LEN + 25;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT3_MB}
  _NL_CTYPE_OUTDIGIT4_MB = _NL_CTYPE_INDIGITS_MB_LEN + 26;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT4_MB}
  _NL_CTYPE_OUTDIGIT5_MB = _NL_CTYPE_INDIGITS_MB_LEN + 27;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT5_MB}
  _NL_CTYPE_OUTDIGIT6_MB = _NL_CTYPE_INDIGITS_MB_LEN + 28;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT6_MB}
  _NL_CTYPE_OUTDIGIT7_MB = _NL_CTYPE_INDIGITS_MB_LEN + 29;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT7_MB}
  _NL_CTYPE_OUTDIGIT8_MB = _NL_CTYPE_INDIGITS_MB_LEN + 30;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT8_MB}
  _NL_CTYPE_OUTDIGIT9_MB = _NL_CTYPE_INDIGITS_MB_LEN + 31;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT9_MB}
  _NL_CTYPE_OUTDIGIT0_WC = _NL_CTYPE_INDIGITS_MB_LEN + 32;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT0_WC}
  _NL_CTYPE_OUTDIGIT1_WC = _NL_CTYPE_INDIGITS_MB_LEN + 33;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT1_WC}
  _NL_CTYPE_OUTDIGIT2_WC = _NL_CTYPE_INDIGITS_MB_LEN + 34;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT2_WC}
  _NL_CTYPE_OUTDIGIT3_WC = _NL_CTYPE_INDIGITS_MB_LEN + 35;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT3_WC}
  _NL_CTYPE_OUTDIGIT4_WC = _NL_CTYPE_INDIGITS_MB_LEN + 36;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT4_WC}
  _NL_CTYPE_OUTDIGIT5_WC = _NL_CTYPE_INDIGITS_MB_LEN + 37;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT5_WC}
  _NL_CTYPE_OUTDIGIT6_WC = _NL_CTYPE_INDIGITS_MB_LEN + 38;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT6_WC}
  _NL_CTYPE_OUTDIGIT7_WC = _NL_CTYPE_INDIGITS_MB_LEN + 39;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT7_WC}
  _NL_CTYPE_OUTDIGIT8_WC = _NL_CTYPE_INDIGITS_MB_LEN + 40;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT8_WC}
  _NL_CTYPE_OUTDIGIT9_WC = _NL_CTYPE_INDIGITS_MB_LEN + 41;
  {$EXTERNALSYM _NL_CTYPE_OUTDIGIT9_WC}
  _NL_CTYPE_TRANSLIT_TAB_SIZE = _NL_CTYPE_INDIGITS_MB_LEN + 42;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_TAB_SIZE}
  _NL_CTYPE_TRANSLIT_FROM_IDX = _NL_CTYPE_INDIGITS_MB_LEN + 43;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_FROM_IDX}
  _NL_CTYPE_TRANSLIT_FROM_TBL = _NL_CTYPE_INDIGITS_MB_LEN + 44;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_FROM_TBL}
  _NL_CTYPE_TRANSLIT_TO_IDX = _NL_CTYPE_INDIGITS_MB_LEN + 45;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_TO_IDX}
  _NL_CTYPE_TRANSLIT_TO_TBL = _NL_CTYPE_INDIGITS_MB_LEN + 46;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_TO_TBL}
  _NL_CTYPE_TRANSLIT_DEFAULT_MISSING_LEN = _NL_CTYPE_INDIGITS_MB_LEN + 47;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_DEFAULT_MISSING_LEN}
  _NL_CTYPE_TRANSLIT_DEFAULT_MISSING = _NL_CTYPE_INDIGITS_MB_LEN + 48;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_DEFAULT_MISSING}
  _NL_CTYPE_TRANSLIT_IGNORE_LEN = _NL_CTYPE_INDIGITS_MB_LEN + 49;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_IGNORE_LEN}
  _NL_CTYPE_TRANSLIT_IGNORE = _NL_CTYPE_INDIGITS_MB_LEN + 50;
  {$EXTERNALSYM _NL_CTYPE_TRANSLIT_IGNORE}
  _NL_CTYPE_EXTRA_MAP_1 = _NL_CTYPE_INDIGITS_MB_LEN + 51;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_1}
  _NL_CTYPE_EXTRA_MAP_2 = _NL_CTYPE_INDIGITS_MB_LEN + 52;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_2}
  _NL_CTYPE_EXTRA_MAP_3 = _NL_CTYPE_INDIGITS_MB_LEN + 53;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_3}
  _NL_CTYPE_EXTRA_MAP_4 = _NL_CTYPE_INDIGITS_MB_LEN + 54;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_4}
  _NL_CTYPE_EXTRA_MAP_5 = _NL_CTYPE_INDIGITS_MB_LEN + 55;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_5}
  _NL_CTYPE_EXTRA_MAP_6 = _NL_CTYPE_INDIGITS_MB_LEN + 56;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_6}
  _NL_CTYPE_EXTRA_MAP_7 = _NL_CTYPE_INDIGITS_MB_LEN + 57;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_7}
  _NL_CTYPE_EXTRA_MAP_8 = _NL_CTYPE_INDIGITS_MB_LEN + 58;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_8}
  _NL_CTYPE_EXTRA_MAP_9 = _NL_CTYPE_INDIGITS_MB_LEN + 59;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_9}
  _NL_CTYPE_EXTRA_MAP_10 = _NL_CTYPE_INDIGITS_MB_LEN + 60;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_10}
  _NL_CTYPE_EXTRA_MAP_11 = _NL_CTYPE_INDIGITS_MB_LEN + 61;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_11}
  _NL_CTYPE_EXTRA_MAP_12 = _NL_CTYPE_INDIGITS_MB_LEN + 62;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_12}
  _NL_CTYPE_EXTRA_MAP_13 = _NL_CTYPE_INDIGITS_MB_LEN + 63;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_13}
  _NL_CTYPE_EXTRA_MAP_14 = _NL_CTYPE_INDIGITS_MB_LEN + 64;
  {$EXTERNALSYM _NL_CTYPE_EXTRA_MAP_14}

  _NL_NUM_LC_CTYPE       = _NL_CTYPE_EXTRA_MAP_14 + 1;
  {$EXTERNALSYM _NL_NUM_LC_CTYPE}

  {  LC_MONETARY category: formatting of monetary quantities.
     These items each correspond to a member of `struct lconv',
     defined in <locale.h>.  }
  __INT_CURR_SYMBOL   = (LC_MONETARY shl 16) or 0;
  {$EXTERNALSYM __INT_CURR_SYMBOL}
  INT_CURR_SYMBOL = __INT_CURR_SYMBOL;
  {$EXTERNALSYM INT_CURR_SYMBOL}

  __CURRENCY_SYMBOL   = __INT_CURR_SYMBOL + 1;
  {$EXTERNALSYM __CURRENCY_SYMBOL}
  CURRENCY_SYMBOL   = __CURRENCY_SYMBOL;
  {$EXTERNALSYM CURRENCY_SYMBOL}

  __MON_DECIMAL_POINT = __INT_CURR_SYMBOL + 2;
  {$EXTERNALSYM __MON_DECIMAL_POINT}
  MON_DECIMAL_POINT = __MON_DECIMAL_POINT;
  {$EXTERNALSYM MON_DECIMAL_POINT}

  __MON_THOUSANDS_SEP = __INT_CURR_SYMBOL + 3;
  {$EXTERNALSYM __MON_THOUSANDS_SEP}
  MON_THOUSANDS_SEP = __MON_THOUSANDS_SEP;
  {$EXTERNALSYM MON_THOUSANDS_SEP}

  __MON_GROUPING      = __INT_CURR_SYMBOL + 4;
  {$EXTERNALSYM __MON_GROUPING}
  MON_GROUPING      = __MON_GROUPING;
  {$EXTERNALSYM MON_GROUPING}

  __POSITIVE_SIGN     = __INT_CURR_SYMBOL + 5;
  {$EXTERNALSYM __POSITIVE_SIGN}
  POSITIVE_SIGN     = __POSITIVE_SIGN;
  {$EXTERNALSYM POSITIVE_SIGN}

  __NEGATIVE_SIGN     = __INT_CURR_SYMBOL + 6;
  {$EXTERNALSYM __NEGATIVE_SIGN}
  NEGATIVE_SIGN     = __NEGATIVE_SIGN;
  {$EXTERNALSYM NEGATIVE_SIGN}

  __INT_FRAC_DIGITS   = __INT_CURR_SYMBOL + 7;
  {$EXTERNALSYM __INT_FRAC_DIGITS}
  INT_FRAC_DIGITS   = __INT_FRAC_DIGITS;
  {$EXTERNALSYM INT_FRAC_DIGITS}

  __FRAC_DIGITS       = __INT_CURR_SYMBOL + 8;
  {$EXTERNALSYM __FRAC_DIGITS}
  FRAC_DIGITS       = __FRAC_DIGITS;
  {$EXTERNALSYM FRAC_DIGITS}

  __P_CS_PRECEDES     = __INT_CURR_SYMBOL + 9;
  {$EXTERNALSYM __P_CS_PRECEDES}
  P_CS_PRECEDES     = __P_CS_PRECEDES;
  {$EXTERNALSYM P_CS_PRECEDES}

  __P_SEP_BY_SPACE    = __INT_CURR_SYMBOL + 10;
  {$EXTERNALSYM __P_SEP_BY_SPACE}
  P_SEP_BY_SPACE    = __P_SEP_BY_SPACE;
  {$EXTERNALSYM P_SEP_BY_SPACE}

  __N_CS_PRECEDES     = __INT_CURR_SYMBOL + 11;
  {$EXTERNALSYM __N_CS_PRECEDES}
  N_CS_PRECEDES     = __N_CS_PRECEDES;
  {$EXTERNALSYM N_CS_PRECEDES}

  __N_SEP_BY_SPACE    = __INT_CURR_SYMBOL + 12;
  {$EXTERNALSYM __N_SEP_BY_SPACE}
  N_SEP_BY_SPACE    = __N_SEP_BY_SPACE;
  {$EXTERNALSYM N_SEP_BY_SPACE}

  __P_SIGN_POSN       = __INT_CURR_SYMBOL + 13;
  {$EXTERNALSYM __P_SIGN_POSN}
  P_SIGN_POSN       = __P_SIGN_POSN;
  {$EXTERNALSYM P_SIGN_POSN}

  __N_SIGN_POSN       = __INT_CURR_SYMBOL + 14;
  {$EXTERNALSYM __N_SIGN_POSN}
  N_SIGN_POSN       = __N_SIGN_POSN;
  {$EXTERNALSYM N_SIGN_POSN}

  _NL_MONETARY_CRNCYSTR = __INT_CURR_SYMBOL + 15;
  {$EXTERNALSYM _NL_MONETARY_CRNCYSTR}
  CRNCYSTR = _NL_MONETARY_CRNCYSTR;
  {$EXTERNALSYM CRNCYSTR}

  __INT_P_CS_PRECEDES = __INT_CURR_SYMBOL + 16;
  {$EXTERNALSYM __INT_P_CS_PRECEDES}
  INT_P_CS_PRECEDES = __INT_P_CS_PRECEDES;
  {$EXTERNALSYM INT_P_CS_PRECEDES}

  __INT_P_SEP_BY_SPACE = __INT_CURR_SYMBOL + 17;
  {$EXTERNALSYM __INT_P_SEP_BY_SPACE}
  INT_P_SEP_BY_SPACE = __INT_P_SEP_BY_SPACE;
  {$EXTERNALSYM INT_P_SEP_BY_SPACE}

  __INT_N_CS_PRECEDES = __INT_CURR_SYMBOL + 18;
  {$EXTERNALSYM __INT_N_CS_PRECEDES}
  INT_N_CS_PRECEDES = __INT_N_CS_PRECEDES;
  {$EXTERNALSYM INT_N_CS_PRECEDES}

  __INT_N_SEP_BY_SPACE = __INT_CURR_SYMBOL + 19;
  {$EXTERNALSYM __INT_N_SEP_BY_SPACE}
  INT_N_SEP_BY_SPACE = __INT_N_SEP_BY_SPACE;
  {$EXTERNALSYM INT_N_SEP_BY_SPACE}

  __INT_P_SIGN_POSN = __INT_CURR_SYMBOL + 20;
  {$EXTERNALSYM __INT_P_SIGN_POSN}
  INT_P_SIGN_POSN = __INT_P_SIGN_POSN;
  {$EXTERNALSYM INT_P_SIGN_POSN}

  __INT_N_SIGN_POSN = __INT_CURR_SYMBOL + 21;
  {$EXTERNALSYM __INT_N_SIGN_POSN}
  INT_N_SIGN_POSN = __INT_N_SIGN_POSN;
  {$EXTERNALSYM INT_N_SIGN_POSN}

  _NL_MONETARY_DUO_INT_CURR_SYMBOL = __INT_CURR_SYMBOL + 22;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_CURR_SYMBOL}
  _NL_MONETARY_DUO_CURRENCY_SYMBOL = __INT_CURR_SYMBOL + 23;
  {$EXTERNALSYM _NL_MONETARY_DUO_CURRENCY_SYMBOL}
  _NL_MONETARY_DUO_INT_FRAC_DIGITS = __INT_CURR_SYMBOL + 24;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_FRAC_DIGITS}
  _NL_MONETARY_DUO_FRAC_DIGITS = __INT_CURR_SYMBOL + 25;
  {$EXTERNALSYM _NL_MONETARY_DUO_FRAC_DIGITS}
  _NL_MONETARY_DUO_P_CS_PRECEDES = __INT_CURR_SYMBOL + 26;
  {$EXTERNALSYM _NL_MONETARY_DUO_P_CS_PRECEDES}
  _NL_MONETARY_DUO_P_SEP_BY_SPACE = __INT_CURR_SYMBOL + 27;
  {$EXTERNALSYM _NL_MONETARY_DUO_P_SEP_BY_SPACE}
  _NL_MONETARY_DUO_N_CS_PRECEDES = __INT_CURR_SYMBOL + 28;
  {$EXTERNALSYM _NL_MONETARY_DUO_N_CS_PRECEDES}
  _NL_MONETARY_DUO_N_SEP_BY_SPACE = __INT_CURR_SYMBOL + 29;
  {$EXTERNALSYM _NL_MONETARY_DUO_N_SEP_BY_SPACE}
  _NL_MONETARY_DUO_INT_P_CS_PRECEDES = __INT_CURR_SYMBOL + 30;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_P_CS_PRECEDES}
  _NL_MONETARY_DUO_INT_P_SEP_BY_SPACE = __INT_CURR_SYMBOL + 31;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_P_SEP_BY_SPACE}
  _NL_MONETARY_DUO_INT_N_CS_PRECEDES = __INT_CURR_SYMBOL + 32;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_N_CS_PRECEDES}
  _NL_MONETARY_DUO_INT_N_SEP_BY_SPACE = __INT_CURR_SYMBOL + 33;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_N_SEP_BY_SPACE}
  _NL_MONETARY_DUO_P_SIGN_POSN = __INT_CURR_SYMBOL + 34;
  {$EXTERNALSYM _NL_MONETARY_DUO_P_SIGN_POSN}
  _NL_MONETARY_DUO_N_SIGN_POSN = __INT_CURR_SYMBOL + 35;
  {$EXTERNALSYM _NL_MONETARY_DUO_N_SIGN_POSN}
  _NL_MONETARY_DUO_INT_P_SIGN_POSN = __INT_CURR_SYMBOL + 36;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_P_SIGN_POSN}
  _NL_MONETARY_DUO_INT_N_SIGN_POSN = __INT_CURR_SYMBOL + 37;
  {$EXTERNALSYM _NL_MONETARY_DUO_INT_N_SIGN_POSN}
  _NL_MONETARY_UNO_VALID_FROM = __INT_CURR_SYMBOL + 38;
  {$EXTERNALSYM _NL_MONETARY_UNO_VALID_FROM}
  _NL_MONETARY_UNO_VALID_TO = __INT_CURR_SYMBOL + 39;
  {$EXTERNALSYM _NL_MONETARY_UNO_VALID_TO}
  _NL_MONETARY_DUO_VALID_FROM = __INT_CURR_SYMBOL + 40;
  {$EXTERNALSYM _NL_MONETARY_DUO_VALID_FROM}
  _NL_MONETARY_DUO_VALID_TO = __INT_CURR_SYMBOL + 41;
  {$EXTERNALSYM _NL_MONETARY_DUO_VALID_TO}
  _NL_MONETARY_CONVERSION_RATE = __INT_CURR_SYMBOL + 42;
  {$EXTERNALSYM _NL_MONETARY_CONVERSION_RATE}
  _NL_MONETARY_DECIMAL_POINT_WC = __INT_CURR_SYMBOL + 43;
  {$EXTERNALSYM _NL_MONETARY_DECIMAL_POINT_WC}
  _NL_MONETARY_THOUSANDS_SEP_WC = __INT_CURR_SYMBOL + 44;
  {$EXTERNALSYM _NL_MONETARY_THOUSANDS_SEP_WC}

  _NL_NUM_LC_MONETARY = _NL_MONETARY_THOUSANDS_SEP_WC + 1;
  {$EXTERNALSYM _NL_NUM_LC_MONETARY}

  { LC_NUMERIC category: formatting of numbers.
     These also correspond to members of `struct lconv'; see <locale.h>.  }
  __DECIMAL_POINT = (LC_NUMERIC shl 16) or 0;
  {$EXTERNALSYM __DECIMAL_POINT}
  DECIMAL_POINT = __DECIMAL_POINT;
  {$EXTERNALSYM DECIMAL_POINT}
  RADIXCHAR = __DECIMAL_POINT;
  {$EXTERNALSYM RADIXCHAR}
  __THOUSANDS_SEP = __DECIMAL_POINT + 1;
  {$EXTERNALSYM __THOUSANDS_SEP}
  THOUSANDS_SEP = __THOUSANDS_SEP;
  {$EXTERNALSYM THOUSANDS_SEP}
  THOUSEP = __THOUSANDS_SEP;
  {$EXTERNALSYM THOUSEP}
  __GROUPING      = __DECIMAL_POINT + 2;
  {$EXTERNALSYM __GROUPING}
  GROUPING        = __GROUPING;
  {$EXTERNALSYM GROUPING}
  _NL_NUMERIC_DECIMAL_POINT_WC = __DECIMAL_POINT + 3;
  {$EXTERNALSYM _NL_NUMERIC_DECIMAL_POINT_WC}
  _NL_NUMERIC_THOUSANDS_SEP_WC = __DECIMAL_POINT + 4;
  {$EXTERNALSYM _NL_NUMERIC_THOUSANDS_SEP_WC}
  _NL_NUM_LC_NUMERIC = _NL_NUMERIC_THOUSANDS_SEP_WC + 1;
  {$EXTERNALSYM _NL_NUM_LC_NUMERIC}

  { Messages. }
  __YESEXPR = (LC_MESSAGES shl 16) or 0;  // Regex matching ``yes'' input
  {$EXTERNALSYM __YESEXPR}
  YESEXPR = __YESEXPR;
  {$EXTERNALSYM YESEXPR}
  __NOEXPR  = __YESEXPR + 1;  // Regex matching ``no'' input
  {$EXTERNALSYM __NOEXPR}
  NOEXPR  = __NOEXPR;
  {$EXTERNALSYM NOEXPR}
  __YESSTR  = __YESEXPR + 2;  // Output string for ``yes''
  {$EXTERNALSYM __YESSTR}
  YESSTR  = __YESSTR;
  {$EXTERNALSYM YESSTR}
  __NOSTR   = __YESEXPR + 3;  // Output string for ``no''
  {$EXTERNALSYM __NOSTR}
  NOSTR   = __NOSTR;
  {$EXTERNALSYM NOSTR}
  _NL_NUM_LC_MESSAGES = __NOSTR + 1;
  {$EXTERNALSYM _NL_NUM_LC_MESSAGES}

  _NL_PAPER_HEIGHT = (LC_PAPER shl 16) or 0;
  {$EXTERNALSYM _NL_PAPER_HEIGHT}
  _NL_PAPER_WIDTH = _NL_PAPER_HEIGHT + 1;
  {$EXTERNALSYM _NL_PAPER_WIDTH}
  _NL_NUM_LC_PAPER = _NL_PAPER_HEIGHT + 2;
  {$EXTERNALSYM _NL_NUM_LC_PAPER}

  _NL_NAME_NAME_FMT = (LC_NAME shl 16) or 0;
  {$EXTERNALSYM _NL_NAME_NAME_FMT}
  _NL_NAME_NAME_GEN = _NL_NAME_NAME_FMT + 1;
  {$EXTERNALSYM _NL_NAME_NAME_GEN}
  _NL_NAME_NAME_MR = _NL_NAME_NAME_FMT + 2;
  {$EXTERNALSYM _NL_NAME_NAME_MR}
  _NL_NAME_NAME_MRS = _NL_NAME_NAME_FMT + 3;
  {$EXTERNALSYM _NL_NAME_NAME_MRS}
  _NL_NAME_NAME_MISS = _NL_NAME_NAME_FMT + 4;
  {$EXTERNALSYM _NL_NAME_NAME_MISS}
  _NL_NAME_NAME_MS = _NL_NAME_NAME_FMT + 5;
  {$EXTERNALSYM _NL_NAME_NAME_MS}
  _NL_NUM_LC_NAME = _NL_NAME_NAME_FMT + 6;
  {$EXTERNALSYM _NL_NUM_LC_NAME}

  _NL_ADDRESS_POSTAL_FMT = (LC_ADDRESS shl 16) or 0;
  {$EXTERNALSYM _NL_ADDRESS_POSTAL_FMT}
  _NL_ADDRESS_COUNTRY_NAME = _NL_ADDRESS_POSTAL_FMT + 1;
  {$EXTERNALSYM _NL_ADDRESS_COUNTRY_NAME}
  _NL_ADDRESS_COUNTRY_POST = _NL_ADDRESS_POSTAL_FMT + 2;
  {$EXTERNALSYM _NL_ADDRESS_COUNTRY_POST}
  _NL_ADDRESS_COUNTRY_AB2 = _NL_ADDRESS_POSTAL_FMT + 3;
  {$EXTERNALSYM _NL_ADDRESS_COUNTRY_AB2}
  _NL_ADDRESS_COUNTRY_AB3 = _NL_ADDRESS_POSTAL_FMT + 4;
  {$EXTERNALSYM _NL_ADDRESS_COUNTRY_AB3}
  _NL_ADDRESS_COUNTRY_CAR = _NL_ADDRESS_POSTAL_FMT + 5;
  {$EXTERNALSYM _NL_ADDRESS_COUNTRY_CAR}
  _NL_ADDRESS_COUNTRY_NUM = _NL_ADDRESS_POSTAL_FMT + 6;
  {$EXTERNALSYM _NL_ADDRESS_COUNTRY_NUM}
  _NL_ADDRESS_COUNTRY_ISBN = _NL_ADDRESS_POSTAL_FMT + 7;
  {$EXTERNALSYM _NL_ADDRESS_COUNTRY_ISBN}
  _NL_ADDRESS_LANG_NAME = _NL_ADDRESS_POSTAL_FMT + 8;
  {$EXTERNALSYM _NL_ADDRESS_LANG_NAME}
  _NL_ADDRESS_LANG_AB = _NL_ADDRESS_POSTAL_FMT + 9;
  {$EXTERNALSYM _NL_ADDRESS_LANG_AB}
  _NL_ADDRESS_LANG_TERM = _NL_ADDRESS_POSTAL_FMT + 10;
  {$EXTERNALSYM _NL_ADDRESS_LANG_TERM}
  _NL_ADDRESS_LANG_LIB = _NL_ADDRESS_POSTAL_FMT + 11;
  {$EXTERNALSYM _NL_ADDRESS_LANG_LIB}
  _NL_NUM_LC_ADDRESS = _NL_ADDRESS_POSTAL_FMT + 12;
  {$EXTERNALSYM _NL_NUM_LC_ADDRESS}

  _NL_TELEPHONE_TEL_INT_FMT = (LC_TELEPHONE shl 16) or 0;
  {$EXTERNALSYM _NL_TELEPHONE_TEL_INT_FMT}
  _NL_TELEPHONE_TEL_DOM_FMT = _NL_TELEPHONE_TEL_INT_FMT + 1;
  {$EXTERNALSYM _NL_TELEPHONE_TEL_DOM_FMT}
  _NL_TELEPHONE_INT_SELECT = _NL_TELEPHONE_TEL_INT_FMT + 2;
  {$EXTERNALSYM _NL_TELEPHONE_INT_SELECT}
  _NL_TELEPHONE_INT_PREFIX = _NL_TELEPHONE_TEL_INT_FMT + 3;
  {$EXTERNALSYM _NL_TELEPHONE_INT_PREFIX}
  _NL_NUM_LC_TELEPHONE = _NL_TELEPHONE_TEL_INT_FMT + 4;
  {$EXTERNALSYM _NL_NUM_LC_TELEPHONE}

  _NL_MEASUREMENT_MEASUREMENT = (LC_MEASUREMENT shl 16) or 0;
  {$EXTERNALSYM _NL_MEASUREMENT_MEASUREMENT}
  _NL_NUM_LC_MEASUREMENT = _NL_MEASUREMENT_MEASUREMENT + 1;
  {$EXTERNALSYM _NL_NUM_LC_MEASUREMENT}

  _NL_IDENTIFICATION_TITLE = (LC_IDENTIFICATION shl 16) or 0;
  {$EXTERNALSYM _NL_IDENTIFICATION_TITLE}
  _NL_IDENTIFICATION_SOURCE = _NL_IDENTIFICATION_TITLE + 1;
  {$EXTERNALSYM _NL_IDENTIFICATION_SOURCE}
  _NL_IDENTIFICATION_ADDRESS = _NL_IDENTIFICATION_TITLE + 2;
  {$EXTERNALSYM _NL_IDENTIFICATION_ADDRESS}
  _NL_IDENTIFICATION_CONTACT = _NL_IDENTIFICATION_TITLE + 3;
  {$EXTERNALSYM _NL_IDENTIFICATION_CONTACT}
  _NL_IDENTIFICATION_EMAIL = _NL_IDENTIFICATION_TITLE + 4;
  {$EXTERNALSYM _NL_IDENTIFICATION_EMAIL}
  _NL_IDENTIFICATION_TEL = _NL_IDENTIFICATION_TITLE + 5;
  {$EXTERNALSYM _NL_IDENTIFICATION_TEL}
  _NL_IDENTIFICATION_FAX = _NL_IDENTIFICATION_TITLE + 6;
  {$EXTERNALSYM _NL_IDENTIFICATION_FAX}
  _NL_IDENTIFICATION_LANGUAGE = _NL_IDENTIFICATION_TITLE + 7;
  {$EXTERNALSYM _NL_IDENTIFICATION_LANGUAGE}
  _NL_IDENTIFICATION_TERRITORY = _NL_IDENTIFICATION_TITLE + 8;
  {$EXTERNALSYM _NL_IDENTIFICATION_TERRITORY}
  _NL_IDENTIFICATION_AUDIENCE = _NL_IDENTIFICATION_TITLE + 9;
  {$EXTERNALSYM _NL_IDENTIFICATION_AUDIENCE}
  _NL_IDENTIFICATION_APPLICATION = _NL_IDENTIFICATION_TITLE + 10;
  {$EXTERNALSYM _NL_IDENTIFICATION_APPLICATION}
  _NL_IDENTIFICATION_ABBREVIATION = _NL_IDENTIFICATION_TITLE + 11;
  {$EXTERNALSYM _NL_IDENTIFICATION_ABBREVIATION}
  _NL_IDENTIFICATION_REVISION = _NL_IDENTIFICATION_TITLE + 12;
  {$EXTERNALSYM _NL_IDENTIFICATION_REVISION}
  _NL_IDENTIFICATION_DATE = _NL_IDENTIFICATION_TITLE + 13;
  {$EXTERNALSYM _NL_IDENTIFICATION_DATE}
  _NL_IDENTIFICATION_CATEGORY = _NL_IDENTIFICATION_TITLE + 14;
  {$EXTERNALSYM _NL_IDENTIFICATION_CATEGORY}
  _NL_NUM_LC_IDENTIFICATION = _NL_IDENTIFICATION_TITLE + 15;
  {$EXTERNALSYM _NL_NUM_LC_IDENTIFICATION}

  { This marks the highest value used. }
  _NL_NUM = _NL_NUM_LC_IDENTIFICATION + 1;
  {$EXTERNALSYM _NL_NUM}


{  Return the current locale's value for ITEM.
   If ITEM is invalid, an empty string is returned.

   The string returned will not change until `setlocale' is called;
   it is usually in read-only memory and cannot be modified.  }
function nl_langinfo(__item: nl_item): PChar; cdecl;
{$EXTERNALSYM nl_langinfo}

{  This interface is for the extended locale model.  See <locale.h> for
   more information.  }

{ Just like nl_langinfo but get the information from the locale object L.  }
function __nl_langinfo_l(__item: nl_item; l: PLocale): PChar; cdecl;
{$EXTERNALSYM __nl_langinfo_l}


// Translated from wordexp.h

{ Bits set in the FLAGS argument to `wordexp'.  }
const
  WRDE_DOOFFS = 1 shl 0;  { Insert PWORDEXP->we_offs NULLs. }
  {$EXTERNALSYM WRDE_DOOFFS}
  WRDE_APPEND = 1 shl 1;  { Append to results of a previous call. }
  {$EXTERNALSYM WRDE_APPEND}
  WRDE_NOCMD = 1 shl 2;   { Don't do command substitution. }
  {$EXTERNALSYM WRDE_NOCMD}
  WRDE_REUSE = 1 shl 3;   { Reuse storage in PWORDEXP. }
  {$EXTERNALSYM WRDE_REUSE}
  WRDE_SHOWERR = 1 shl 4; { Don't redirect stderr to /dev/null. }
  {$EXTERNALSYM WRDE_SHOWERR}
  WRDE_UNDEF = 1 shl 5;   { Error for expanding undefined variables. }
  {$EXTERNALSYM WRDE_UNDEF}
  __WRDE_FLAGS = WRDE_DOOFFS or WRDE_APPEND or WRDE_NOCMD or
    WRDE_REUSE or WRDE_SHOWERR or WRDE_UNDEF;
  {$EXTERNALSYM __WRDE_FLAGS}

type
{ Structure describing a word-expansion run.  }
  wordexp_t = {packed} record
    we_wordc: Integer;   { Count of words matched. }
    we_wordv: PPChar;    { List of expanded words. }
    we_offs: Integer;    { Slots to reserve in `we_wordv'. }
  end;
  {$EXTERNALSYM wordexp_t}
  TWordExp = wordexp_t;
  PWordExp = ^TWordExp;

const
{ Possible nonzero return values from `wordexp'. }
  WRDE_NOSPACE = 1;	{ Ran out of memory. }
  {$EXTERNALSYM WRDE_NOSPACE}
  WRDE_BADCHAR = 2; { A metachar appears in the wrong place. }
  {$EXTERNALSYM WRDE_BADCHAR}
  WRDE_BADVAL = 3;  { Undefined var reference with WRDE_UNDEF. }
  {$EXTERNALSYM WRDE_BADVAL}
  WRDE_CMDSUB = 4;  { Command substitution with WRDE_NOCMD. }
  {$EXTERNALSYM WRDE_CMDSUB}
  WRDE_SYNTAX = 5;  { Shell syntax error. }
  {$EXTERNALSYM WRDE_SYNTAX}

{ Do word expansion of WORDS into PWORDEXP. }
function wordexp(Words: PChar; var WordExp: TWordExp; Flags: Integer): Integer; cdecl;
{$EXTERNALSYM wordexp}

{ Free the storage allocated by a `wordexp' call.  }
procedure wordfree(var WordExp: TWordExp); cdecl;
{$EXTERNALSYM wordfree}


// Translated from iconv.h

type
  { Identifier for conversion method from one codeset to another.  }
  iconv_t = Pointer;
  {$EXTERNALSYM iconv_t}

{ Allocate descriptor for code conversion from codeset FROMCODE to
   codeset TOCODE.  }
function iconv_open(ToCode: PChar; FromCode: PChar): iconv_t; cdecl;
{$EXTERNALSYM iconv_open}

{ Convert at most *INBYTESLEFT bytes from *INBUF according to the
   code conversion algorithm specified by CD and place up to
   *OUTBYTESLEFT bytes in buffer at *OUTBUF.  }
function iconv(cd: iconv_t; var InBuf: PChar; var InBytesLeft: size_t; var OutBuf: Pointer; var OutBytesLeft: size_t): size_t; cdecl;
{$EXTERNALSYM iconv}

{ Free resources allocated for descriptor CD for code conversion.  }
function iconv_close(cd: iconv_t): Integer; cdecl;
{$EXTERNALSYM iconv_close}


// Translated from bits/resource.h

{ Kinds of resource limit. }
type
  __rlimit_resource =
  (
    { Per-process CPU limit, in seconds.  }
    RLIMIT_CPU = 0,
    {$EXTERNALSYM RLIMIT_CPU}

    { Largest file that can be created, in bytes.  }
    RLIMIT_FSIZE = 1,
    {$EXTERNALSYM RLIMIT_FSIZE}

    { Maximum size of data segment, in bytes.  }
    RLIMIT_DATA = 2,
    {$EXTERNALSYM RLIMIT_DATA}

    { Maximum size of stack segment, in bytes.  }
    RLIMIT_STACK = 3,
    {$EXTERNALSYM RLIMIT_STACK}

    { Largest core file that can be created, in bytes.  }
    RLIMIT_CORE = 4,
    {$EXTERNALSYM RLIMIT_CORE}

    { Largest resident set size, in bytes.
       This affects swapping; processes that are exceeding their
       resident set size will be more likely to have physical memory
       taken from them.  }
    RLIMIT_RSS = 5,
    {$EXTERNALSYM RLIMIT_RSS}

    { Number of open files.  }
    RLIMIT_NOFILE = 7,
    {$EXTERNALSYM RLIMIT_NOFILE}
    RLIMIT_OFILE = RLIMIT_NOFILE, { BSD name for same.  }
    {$EXTERNALSYM RLIMIT_OFILE}

    { Address space limit.  }
    RLIMIT_AS = 9,
    {$EXTERNALSYM RLIMIT_AS = 9}

    { Number of processes.  }
    RLIMIT_NPROC = 6,
    {$EXTERNALSYM RLIMIT_NPROC}

    { Locked-in-memory address space.  }
    RLIMIT_MEMLOCK = 8,
    {$EXTERNALSYM RLIMIT_MEMLOCK}

    { Maximum number of file locks.  }
    RLIMIT_LOCKS = 10,
    {$EXTERNALSYM RLIMIT_LOCKS}

    RLIMIT_NLIMITS = 11,
    {$EXTERNALSYM RLIMIT_NLIMITS}
    RLIM_NLIMITS = RLIMIT_NLIMITS
    {$EXTERNALSYM RLIM_NLIMITS}
  );
  {$EXTERNALSYM __rlimit_resource}
  __rlimit_resource_t = __rlimit_resource;
  {$EXTERNALSYM __rlimit_resource_t}

  { Value to indicate that there is no limit.  }
const
  RLIM_INFINITY = Integer(-1);
  {$EXTERNALSYM RLIM_INFINITY}

  RLIM64_INFINITY = Int64(-1);
  {$EXTERNALSYM RLIM64_INFINITY}

  { We can represent all limits.  }

  RLIM_SAVED_MAX = RLIM_INFINITY;
  {$EXTERNALSYM RLIM_SAVED_MAX}
  RLIM_SAVED_CUR = RLIM_INFINITY;
  {$EXTERNALSYM RLIM_SAVED_CUR}

{ Type for resource quantity measurement.  }
type
  rlim_t = __rlim_t;
  {$EXTERNALSYM rlim_t}
  rlim64_t = __rlim64_t;
  {$EXTERNALSYM rlim64_t}

  rlimit = {packed} record
    { The current (soft) limit.  }
    rlim_cur: rlim_t;
    { The hard limit.  }
    rlim_max: rlim_t;
  end;
  {$EXTERNALSYM rlimit}
  TRLimit = rlimit;
  PRLimit = ^TRLimit;

  rlimit64 = {packed} record
    { The current (soft) limit.  }
    rlim64_cur: rlim_t;
    { The hard limit.  }
    rlim64_max: rlim_t;
  end;
  {$EXTERNALSYM rlimit64}
  TRLimit64 = rlimit64;
  PRLimit64 = ^TRLimit64;

{ Whose usage statistics do you want?  }
type
  __rusage_who =
  (
    { The calling process.  }
    RUSAGE_SELF = 0,
    {$EXTERNALSYM RUSAGE_SELF}

    { All of its terminated child processes.  }
    RUSAGE_CHILDREN = -1,
    {$EXTERNALSYM RUSAGE_CHILDREN}

    { Both.  }
    RUSAGE_BOTH = -2
    {$EXTERNALSYM RUSAGE_BOTH}
  );
  {$EXTERNALSYM __rusage_who}
  __rusage_who_t = __rusage_who;
  {$EXTERNALSYM __rusage_who_t}

{ Structure which says how much of each resource has been used.  }
type
  rusage = {packed} record
    { Total amount of user time used.  }
    ru_utime: timeval;
    { Total amount of system time used.  }
    ru_stime: timeval;
    { Maximum resident set size (in kilobytes).  }
    ru_maxrss: Longint;
    { Amount of sharing of text segment memory
      with other processes (kilobyte-seconds).  }
    ru_ixrss: Longint;
    { Amount of data segment memory used (kilobyte-seconds).  }
    ru_idrss: Longint;
    { Amount of stack memory used (kilobyte-seconds).  }
    ru_isrss: Longint;
    { Number of soft page faults (i.e. those serviced by reclaiming
      a page from the list of pages awaiting reallocation.  }
    ru_minflt: Longint;
    { Number of hard page faults (i.e. those that required I/O).  }
    ru_majflt: Integer;
    { Number of times a process was swapped out of physical memory.  }
    ru_nswap: Integer;
    { Number of input operations via the file system.  Note: This
      and `ru_oublock' do not include operations with the cache.  }
    ru_inblock: Integer;
    { Number of output operations via the file system.  }
    ru_oublock: Integer;
    { Number of IPC messages sent.  }
    ru_msgsnd: Integer;
    { Number of IPC messages received.  }
    ru_msgrcv: Integer;
    { Number of signals delivered.  }
    ru_nsignals: Integer;
    { Number of voluntary context switches, i.e. because the process
      gave up the process before it had to (usually to wait for some
      resource to be available).  }
    ru_nvcsw: Integer;
    { Number of involuntary context switches, i.e. a higher priority process
      became runnable or the current process used up its time slice.  }
    ru_nivcsw: Integer;
  end;
  {$EXTERNALSYM rusage}
  TRUsage = rusage;
  PRUsage = ^TRUsage;

{ Priority limits.  }
const
  PRIO_MIN = -20;       { Minimum priority a process can have.  }
  {$EXTERNALSYM PRIO_MIN}
  PRIO_MAX = 20;        { Maximum priority a process can have.  }
  {$EXTERNALSYM PRIO_MAX}


{  The type of the WHICH argument to `getpriority' and `setpriority',
   indicating what flavor of entity the WHO argument specifies.  }

type
  __priority_which =
  (
    PRIO_PROCESS = 0,             { WHO is a process ID.  }
    {$EXTERNALSYM PRIO_PROCESS}
    PRIO_PGRP = 1,                { WHO is a process group ID.  }
    {$EXTERNALSYM PRIO_PGRP}
    PRIO_USER = 2                 { WHO is a user ID.  }
    {$EXTERNALSYM PRIO_USER}
  );
  {$EXTERNALSYM __priority_which}
  __priority_which_t = __priority_which;
  {$EXTERNALSYM __priority_which_t}


// Translated from sys/resource.h

{  Put the soft and hard limits for RESOURCE in *RLIMITS.
   Returns 0 if successful, -1 if not (and sets errno).  }
function getrlimit(__resource: __rlimit_resource_t; var __rlimits: TRLimit): Integer; cdecl;
{$EXTERNALSYM getrlimit}

function getrlimit64(__resource: __rlimit_resource_t; var __rlimits: TRLimit64): Integer; cdecl;
{$EXTERNALSYM getrlimit64}


{  Set the soft and hard limits for RESOURCE to *RLIMITS.
   Only the super-user can increase hard limits.
   Return 0 if successful, -1 if not (and sets errno).  }
function setrlimit (__resource: __rlimit_resource_t; const __rlimits: TRLimit): Integer; cdecl;
{$EXTERNALSYM setrlimit}

function setrlimit64 (__resource: __rlimit_resource_t; const __rlimits: TRLimit64): Integer; cdecl;
{$EXTERNALSYM setrlimit64}


{  Return resource usage information on process indicated by WHO
   and put it in *USAGE.  Returns 0 for success, -1 for failure.  }
function getrusage (__who: __rusage_who_t; var __usage: TRUsage): Integer; cdecl;
{$EXTERNALSYM getrusage}


{  Return the highest priority of any process specified by WHICH and WHO
   (see above); if WHO is zero, the current process, process group, or user
   (as specified by WHO) is used.  A lower priority number means higher
   priority.  Priorities range from PRIO_MIN to PRIO_MAX (above).  }
function getpriority (__which: __priority_which_t; __who: id_t): Integer; cdecl;
{$EXTERNALSYM getpriority}

{  Set the priority of all processes specified by WHICH and WHO (see above)
   to PRIO.  Returns 0 on success, -1 on errors.  }
function setpriority (__which: __priority_which_t; __who: id_t; __prio: Integer): Integer; cdecl;
{$EXTERNALSYM setpriority}



// Translated from argz.h

{ Make a '\0' separated arg vector from a unix argv vector, returning it in
   ARGZ, and the total length in LEN.  If a memory allocation error occurs,
   ENOMEM is returned, otherwise 0.  The result can be destroyed using free. }
function argz_create(__argv: PChar; var __argz: PChar; var __len: size_t): error_t; cdecl;
{$EXTERNALSYM argz_create}

{ Make a '\0' separated arg vector from a SEP separated list in
   STRING, returning it in ARGZ, and the total length in LEN.  If a
   memory allocation error occurs, ENOMEM is returned, otherwise 0.
   The result can be destroyed using free.  }
function argz_create_sep(__string: PChar; __sep: Integer; var __argz: PChar; var __len: size_t): error_t; cdecl;
{$EXTERNALSYM argz_create_sep}

{ Returns the number of strings in ARGZ.  }
function argz_count(__argz: PChar; __len: size_t): size_t; cdecl;
{$EXTERNALSYM argz_count}

{ Puts pointers to each string in ARGZ into ARGV, which must be large enough
   to hold them all.  }
procedure argz_extract(__argz: PChar; __len: size_t; __argv: PPChar); cdecl;
{$EXTERNALSYM argz_extract}

{ Make '\0' separated arg vector ARGZ printable by converting all the '\0's
   except the last into the character SEP.  }
procedure argz_stringify(__argz: PChar; __len: size_t; __sep: Integer); cdecl;
{$EXTERNALSYM argz_stringify}

{ Append BUF, of length BUF_LEN to the argz vector in ARGZ & ARGZ_LEN.  }
function argz_append(var __argz: PChar; var __argz_len: size_t; __buf: PChar; _buf_len: size_t): error_t; cdecl;
{$EXTERNALSYM argz_append}

{ Append STR to the argz vector in ARGZ & ARGZ_LEN.  }
function argz_add(var __argz: PChar; var __argz_len: size_t; __str: PChar): error_t; cdecl;
{$EXTERNALSYM argz_add}

{ Append SEP separated list in STRING to the argz vector in ARGZ &
   ARGZ_LEN.  }
function argz_add_sep(var __argz: PChar; var __argz_len: size_t; __string: PChar; __delim: Integer): error_t; cdecl;
{$EXTERNALSYM argz_add_sep}

{ Delete ENTRY from ARGZ & ARGZ_LEN, if it appears there.  }
procedure argz_delete(var __argz: PChar; var __argz_len: size_t; __entry: PChar); cdecl;
{$EXTERNALSYM argz_delete}

{ Insert ENTRY into ARGZ & ARGZ_LEN before BEFORE, which should be an
   existing entry in ARGZ; if BEFORE is NULL, ENTRY is appended to the end.
   Since ARGZ's first entry is the same as ARGZ, argz_insert (ARGZ, ARGZ_LEN,
   ARGZ, ENTRY) will insert ENTRY at the beginning of ARGZ.  If BEFORE is not
   in ARGZ, EINVAL is returned, else if memory can't be allocated for the new
   ARGZ, ENOMEM is returned, else 0.  }
function argz_insert(var __argz: PChar; var __argz_len: size_t; __before: PChar; __entry: PChar): error_t; cdecl;
{$EXTERNALSYM argz_insert}

{ Replace any occurrences of the string STR in ARGZ with WITH, reallocating
   ARGZ as necessary.  If REPLACE_COUNT is non-zero, *REPLACE_COUNT will be
   incremented by number of replacements performed.  }
function argz_replace(var __argz: PChar; var __argz_len: size_t; __str, __with: PChar; var __replace_count: LongWord): error_t; cdecl;
{$EXTERNALSYM argz_replace}

{ Returns the next entry in ARGZ & ARGZ_LEN after ENTRY, or NULL if there
   are no more.  If entry is NULL, then the first entry is returned.  This
   behavior allows two convenient iteration styles:

    char *entry = 0;
    while ((entry = argz_next (argz, argz_len, entry)))
      ...;

   or

    char *entry;
    for (entry = argz; entry; entry = argz_next (argz, argz_len, entry))
      ...;
}
function argz_next(__argz: PChar; __argz_len: size_t; __entry: PChar): PChar; cdecl;
{$EXTERNALSYM argz_next}


// Translated from envz.h

{ Envz's are argz's too, and should be created etc., using the same
   routines.  }

{ Returns a pointer to the entry in ENVZ for NAME, or 0 if there is none.  }
function envz_entry(__envz: PChar; __envz_len: size_t; __name: PChar): PChar; cdecl;
{$EXTERNALSYM envz_entry}

{ Returns a pointer to the value portion of the entry in ENVZ for NAME, or 0
   if there is none.  }
function envz_get(__envz: PChar; __envz_len: size_t; __name: PChar): PChar; cdecl;
{$EXTERNALSYM envz_get}

{ Adds an entry for NAME with value VALUE to ENVZ & ENVZ_LEN.  If an entry
   with the same name already exists in ENVZ, it is removed.  If VALUE is
   NULL, then the new entry will a special null one, for which envz_get will
   return NULL, although envz_entry will still return an entry; this is handy
   because when merging with another envz, the null entry can override an
   entry in the other one.  Null entries can be removed with envz_strip ().  }
function envz_add(var __envz: PChar; var __envz_len: size_t; __name, __value: PChar): error_t; cdecl;
{$EXTERNALSYM envz_add}

{ Adds each entry in ENVZ2 to ENVZ & ENVZ_LEN, as if with envz_add().  If
   OVERRIDE is true, then values in ENVZ2 will supersede those with the same
   name in ENV, otherwise not.  }
function envz_merge(var __envz: PChar; var __envz_len: size_t; __envz2: PChar; __envz2_len: size_t; __override: Integer): error_t; cdecl;
{$EXTERNALSYM envz_merge}

{ Remove the entry for NAME from ENVZ & ENVZ_LEN, if any.  }
procedure envz_remove(var __envz: PChar; var __envz_len: size_t; __name: PChar); cdecl;
{$EXTERNALSYM envz_remove}

{ Remove null entries.  }
procedure envz_strip(var __envz: PChar; var __envz_len: size_t); cdecl;
{$EXTERNALSYM envz_strip}


// Translated from sys/ctype.h

{  The following names are all functions:
     int isCHARACTERISTIC(int c);
   which return nonzero iff C has CHARACTERISTIC. }

{ Alphanumeric.  }
function isalnum(c: Integer): Integer; cdecl;
{$EXTERNALSYM isalnum}

{ Alphabetic.  }
function isalpha(c: Integer): Integer; cdecl;
{$EXTERNALSYM isalpha}

{ Control character.  }
function iscntrl(c: Integer): Integer; cdecl;
{$EXTERNALSYM iscntrl}

{ Numeric.  }
function isdigit(c: Integer): Integer; cdecl;
{$EXTERNALSYM isdigit}

{ lowercase.  }
function islower(c: Integer): Integer; cdecl;
{$EXTERNALSYM islower}

{ Graphical.  }
function isgraph(c: Integer): Integer; cdecl;
{$EXTERNALSYM isgraph}

{ Printing.  }
function isprint(c: Integer): Integer; cdecl;
{$EXTERNALSYM isprint}

{ Punctuation.  }
function ispunct(c: Integer): Integer; cdecl;
{$EXTERNALSYM ispunct}

{ Whitespace.  }
function isspace(c: Integer): Integer; cdecl;
{$EXTERNALSYM isspace}

{ UPPERCASE.  }
function isupper(c: Integer): Integer; cdecl;
{$EXTERNALSYM isupper}

{ Hexadecimal numeric.  }
function isxdigit(c: Integer): Integer; cdecl;
{$EXTERNALSYM isxdigit}

{ Blank (usually SPC and TAB) - GNU extension.  }
function isblank(c: Integer): Integer; cdecl;
{$EXTERNALSYM isblank}

{ Return the lowercase version of C.  }
function tolower(c: Integer): Integer; cdecl;
{$EXTERNALSYM tolower}

{ Return the uppercase version of C.  }
function toupper(c: Integer): Integer; cdecl;
{$EXTERNALSYM toupper}

{ Return nonzero iff C is in the ASCII set
   (i.e., is no more than 7 bits wide).  }
function isascii(c: Integer): Integer; cdecl;
{$EXTERNALSYM isascii}

{ Return the part of C that is in the ASCII set
   (i.e., the low-order 7 bits of C).  }
function toascii(c: Integer): Integer; cdecl;
{$EXTERNALSYM toascii}

{ These are the same as `toupper' and `tolower' except that they do not
   check the argument for being in the range of a `char'.  }
function _toupper(c: Integer): Integer; cdecl;
{$EXTERNALSYM _toupper}
function _tolower(c: Integer): Integer; cdecl;
{$EXTERNALSYM _tolower}

{  The concept of one static locale per category is not very well
   thought out.  Many applications will need to process its data using
   information from several different locales.  Another application is
   the implementation of the internationalization handling in the
   upcoming ISO C++ standard library.  To support this another set of
   the functions using locale data exist which have an additional
   argument.

   Attention: all these functions are *not* standardized in any form.
   This is a proof-of-concept implementation.  }

{  The following names are all functions:
     int isCHARACTERISTIC(int c, locale_t *locale);
   which return nonzero iff C has CHARACTERISTIC.
   For the meaning of the characteristic names, see the `enum' above.  }
function __isalnum_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isalnum_l}
function __isalpha_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isalpha_l}
function __iscntrl_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iscntrl_l}
function __isdigit_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isdigit_l}
function __islower_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __islower_l}
function __isgraph_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isgraph_l}
function __isprint_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isprint_l}
function __ispunct_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __ispunct_l}
function __isspace_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isspace_l}
function __isupper_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isupper_l}
function __isxdigit_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isxdigit_l}

function __isblank_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __isblank_l}

{  Return the lowercase version of C in locale L.  }
function __tolower_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __tolower_l}

{  Return the uppercase version of C.  }
function __toupper_l(c: Integer; Locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __toupper_l}

// Translated from wctype.h

{ Scalar type that can hold values which represent locale-specific
   character classifications.  }
type
  wctype_t = LongWord;
  {$EXTERNALSYM wctype_t}

{
 * Wide-character classification functions: 7.15.2.1.
 }

{ Test for any wide character for which `iswalpha' or `iswdigit' is
   true.  }
function iswalnum(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswalnum}

{ Test for any wide character for which `iswupper' or 'iswlower' is
   true, or any wide character that is one of a locale-specific set of
   wide-characters for which none of `iswcntrl', `iswdigit',
   `iswpunct', or `iswspace' is true.  }
function iswalpha(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswalpha}

{ Test for any control wide character.  }
function iswcntrl(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswcntrl}

{ Test for any wide character that corresponds to a decimal-digit
   character.  }
function iswdigit(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswdigit}

{ Test for any wide character for which `iswprint' is true and
   `iswspace' is false.  }
function iswgraph(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswgraph}

{ Test for any wide character that corresponds to a lowercase letter
   or is one of a locale-specific set of wide characters for which
   none of `iswcntrl', `iswdigit', `iswpunct', or `iswspace' is true.  }
function iswlower(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswlower}

{ Test for any printing wide character.  }
function iswprint(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswprint}

{ Test for any printing wide character that is one of a
   locale-specific et of wide characters for which neither `iswspace'
   nor `iswalnum' is true.  }
function iswpunct(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswpunct}

{ Test for any wide character that corresponds to a locale-specific
   set of wide characters for which none of `iswalnum', `iswgraph', or
   `iswpunct' is true.  }
function iswspace(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswspace}

{ Test for any wide character that corresponds to an uppercase letter
   or is one of a locale-specific set of wide character for which none
   of `iswcntrl', `iswdigit', `iswpunct', or `iswspace' is true.  }
function iswupper(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswupper}

{ Test for any wide character that corresponds to a hexadecimal-digit
   character equivalent to that performed be the functions described
   in the previous subclause.  }
function iswxdigit(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswxdigit}

{ Test for any wide character that corresponds to a standard blank
   wide character or a locale-specific set of wide characters for
   which `iswalnum' is false.  }
function iswblank(__wc: wint_t): Integer; cdecl;
{$EXTERNALSYM iswblank}

{
 * Extensible wide-character classification functions: 7.15.2.2.
 }

{ Construct value that describes a class of wide characters identified
   by the string argument PROPERTY.  }
function wctype(__property: PChar): wctype_t; cdecl;
{$EXTERNALSYM wctype}

{ Determine whether the wide-character WC has the property described by
   DESC.  }
function iswctype(__wc: wint_t; __desc: wctype_t): Integer; cdecl;
{$EXTERNALSYM iswctype}


{
 * Wide-character case-mapping functions: 7.15.3.1.
 }

{ Scalar type that can hold values which represent locale-specific
   character mappings.  }
type
  wctrans_t = ^int32_t;
  {$EXTERNALSYM wctrans_t}

{ Converts an uppercase letter to the corresponding lowercase letter.  }
function towlower(__wc: wint_t): wint_t; cdecl;
{$EXTERNALSYM towlower}

{ Converts an lowercase letter to the corresponding uppercase letter.  }
function towupper(__wc: wint_t): wint_t; cdecl;
{$EXTERNALSYM towupper}

{ Map the wide character WC using the mapping described by DESC.  }
function __towctrans(__wc: wint_t; __desc: wctrans_t): wint_t; cdecl;
{$EXTERNALSYM __towctrans}

{
 * Extensible wide-character mapping functions: 7.15.3.2.
 }

{ Construct value that describes a mapping between wide characters
   identified by the string argument PROPERTY.  }
function wctrans(__property: PChar): wctrans_t; cdecl;
{$EXTERNALSYM wctrans}

{ Map the wide character WC using the mapping described by DESC.  }
function towctrans(__wc: wint_t; __desc: wctrans_t): wint_t; cdecl;
{$EXTERNALSYM towctrans}

{ Test for any wide character for which `iswalpha' or `iswdigit' is
   true.  }
function __iswalnum_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswalnum_l}

{ Test for any wide character for which `iswupper' or 'iswlower' is
   true, or any wide character that is one of a locale-specific set of
   wide-characters for which none of `iswcntrl', `iswdigit',
   `iswpunct', or `iswspace' is true.  }
function __iswalpha_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswalpha_l}

{ Test for any control wide character.  }
function __iswcntrl_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswcntrl_l}

{ Test for any wide character that corresponds to a decimal-digit
   character.  }
function __iswdigit_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswdigit_l}

{ Test for any wide character for which `iswprint' is true and
   `iswspace' is false.  }
function __iswgraph_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswgraph_l}

{ Test for any wide character that corresponds to a lowercase letter
   or is one of a locale-specific set of wide characters for which
   none of `iswcntrl', `iswdigit', `iswpunct', or `iswspace' is true.  }
function __iswlower_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswlower_l}

{ Test for any printing wide character.  }
function __iswprint_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswprint_l}

{ Test for any printing wide character that is one of a
   locale-specific et of wide characters for which neither `iswspace'
   nor `iswalnum' is true.  }
function __iswpunct_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswpunct_l}

{ Test for any wide character that corresponds to a locale-specific
   set of wide characters for which none of `iswalnum', `iswgraph', or
   `iswpunct' is true.  }
function __iswspace_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswspace_l}

{ Test for any wide character that corresponds to an uppercase letter
   or is one of a locale-specific set of wide character for which none
   of `iswcntrl', `iswdigit', `iswpunct', or `iswspace' is true.  }
function __iswupper_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswupper_l}

{ Test for any wide character that corresponds to a hexadecimal-digit
   character equivalent to that performed be the functions described
   in the previous subclause.  }
function __iswxdigit_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswxdigit_l}

{ Test for any wide character that corresponds to a standard blank
   wide character or a locale-specific set of wide characters for
   which `iswalnum' is false.  }
function __iswblank_l(__wc: wint_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswblank_l}

{ Construct value that describes a class of wide characters identified
   by the string argument PROPERTY.  }
function __wctype_l(__property: PChar; __locale: __locale_t): wctype_t; cdecl;
{$EXTERNALSYM __wctype_l}

{ Determine whether the wide-character WC has the property described by
   DESC.  }
function __iswctype_l(__wc: wint_t; __desc: wctype_t; __locale: __locale_t): Integer; cdecl;
{$EXTERNALSYM __iswctype_l}


{
 * Wide-character case-mapping functions.
 }

{ Converts an uppercase letter to the corresponding lowercase letter.  }
function __towlower_l(__wc: wint_t; __locale: __locale_t): wint_t; cdecl;
{$EXTERNALSYM __towlower_l}

{ Converts an lowercase letter to the corresponding uppercase letter.  }
function __towupper_l(__wc: wint_t; __locale: __locale_t): wint_t; cdecl;
{$EXTERNALSYM __towupper_l}

{ Construct value that describes a mapping between wide characters
   identified by the string argument PROPERTY.  }
function __wctrans_l(__property: PChar; __locale: __locale_t): wctrans_t; cdecl;
{$EXTERNALSYM __wctrans_l}

{ Map the wide character WC using the mapping described by DESC.  }
function __towctrans_l(__wc: wint_t; __desc: wctrans_t; __locale: __locale_t): wint_t; cdecl;
{$EXTERNALSYM __towctrans_l}


// Translated from wchar.h

{ Conversion state information.  }

(* Moved further up to resolve dependency.

  __mbstate_t = {packed} record
    count: Integer;              { Number of bytes needed for the current character. }
    case { __value } Integer of  { Value so far.  }
      0: (__wch: wint_t);
      1: (__wchb: packed array[0..4 - 1] of Char);
    end;
  {$EXTERNALSYM __mbstate_t}
  mbstate_t = __mbstate_t;
  {$EXTERNALSYM mbstate_t}
  TMultiByteState = __mbstate_t;
  PMultiByteState = ^TMultiByteState;
*)
const
  WCHAR_MIN = wchar_t(0);
  {$EXTERNALSYM WCHAR_MIN}
  WCHAR_MAX = wchar_t($7FFFFFFF);
  {$EXTERNALSYM WCHAR_MAX}
  
{ Constant expression of type `wint_t' whose value does not correspond
   to any member of the extended character set.  }
  WEOF      = wchar_t($FFFFFFFF);
  {$EXTERNALSYM WEOF}

{ Copy SRC to DEST.  }
function wcscpy(__dest: Pwchar_t; __src: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcscpy}
{ Copy no more than N wide-characters of SRC to DEST.  }
function wcsncpy(__dest: Pwchar_t; __src: Pwchar_t; __n: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcsncpy}

{ Append SRC onto DEST.  }
function wcscat(__dest: Pwchar_t; __src: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcscat}
{ Append no more than N wide-characters of SRC onto DEST.  }
function wcsncat(__dest: Pwchar_t; __src: Pwchar_t; __n: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcsncat}

{ Compare S1 and S2.  }
function wcscmp(__s1, __s2: Pwchar_t): Integer; cdecl;
{$EXTERNALSYM wcscmp}
{ Compare N wide-characters of S1 and S2.  }
function wcsncmp(__s1, __s2: Pwchar_t; __n: size_t): Integer; cdecl;
{$EXTERNALSYM wcsncmp}

{ Compare S1 and S2, ignoring case.  }
function wcscasecmp(__s1, __s2: Pwchar_t): Integer; cdecl;
{$EXTERNALSYM wcscasecmp}

{ Compare no more than N chars of S1 and S2, ignoring case.  }
function wcsncasecmp(__s1, __s2: Pwchar_t; __n: size_t): Integer; cdecl;
{$EXTERNALSYM wcsncasecmp}

{ Similar to the two functions above but take the information from
   the provided locale and not the global locale.  }
function __wcscasecmp_l(__s1, __s2: Pwchar_t; __loc: __locale_t): Integer; cdecl;
{$EXTERNALSYM __wcscasecmp_l}
function __wcsncasecmp_l(__s1, __s2: Pwchar_t; __n: size_t; __loc: __locale_t): Integer; cdecl;
{$EXTERNALSYM __wcsncasecmp_l}

{ Compare S1 and S2, both interpreted as appropriate to the
   LC_COLLATE category of the current locale.  }
function wcscoll(__s1, __s2: Pwchar_t): Integer; cdecl;
{$EXTERNALSYM wcscoll}
{ Transform S2 into array pointed to by S1 such that if wcscmp is
   applied to two transformed strings the result is the as applying
   `wcscoll' to the original strings.  }
function wcsxfrm(__s1, __s2: Pwchar_t; __n: size_t): size_t; cdecl;
{$EXTERNALSYM wcsxfrm}

{ Similar to the two functions above but take the information from
   the provided locale and not the global locale.  }

{ Compare S1 and S2, both interpreted as appropriate to the
   LC_COLLATE category of the given locale.  }
function __wcscoll_l(__s1, __s2: Pwchar_t; __loc: __locale_t): Integer; cdecl;
{$EXTERNALSYM __wcscoll_l}

{ Transform S2 into array pointed to by S1 such that if wcscmp is
   applied to two transformed strings the result is the as applying
   `wcscoll' to the original strings.  }
function __wcsxfrm_l(__s1, __s2: Pwchar_t; __n: size_t; __loc: __locale_t): size_t; cdecl;
{$EXTERNALSYM __wcsxfrm_l}

{ Duplicate S, returning an identical malloc'd string.  }
function wcsdup(__s: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcsdup}

{ Find the first occurrence of WC in WCS.  }
function wcschr(__wcs: Pwchar_t; __wc: wchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcschr}
{ Find the last occurrence of WC in WCS.  }
function wcsrchr(__wcs: Pwchar_t; __wc: wchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcsrchr}

{ This funciton is similar to `wcschr'.  But it returns a pointer to
   the closing NUL wide character in case C is not found in S.  }
function wcschrnul(__s: Pwchar_t; __wc: wchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcschrnul}

{ Return the length of the initial segmet of WCS which
   consists entirely of wide characters not in REJECT.  }
function wcscspn(__wcs: Pwchar_t; __reject: Pwchar_t): size_t; cdecl;
{$EXTERNALSYM wcscspn}
{ Return the length of the initial segmet of WCS which
   consists entirely of wide characters in  ACCEPT.  }
function wcsspn(__wcs: Pwchar_t; __accept: Pwchar_t): size_t; cdecl;
{$EXTERNALSYM wcsspn}
{ Find the first occurrence in WCS of any character in ACCEPT.  }
function wcspbrk(__wcs: Pwchar_t; __accept: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcspbrk}
{ Find the first occurrence of NEEDLE in HAYSTACK.  }
function wcsstr(__haystack: Pwchar_t; __needle: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcsstr}

{ Another name for `wcsstr' from XPG4.  }
function wcswcs(__haystack: Pwchar_t; __needle: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcswcs}

{ Divide WCS into tokens separated by characters in DELIM.  }
function wcstok(__s: Pwchar_t; __delim: Pwchar_t; var __ptr: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcstok}

{ Return the number of wide characters in S.  }
function wcslen(__s: Pwchar_t): size_t; cdecl;
{$EXTERNALSYM wcslen}

{ Return the number of wide characters in S, but at most MAXLEN.  }
function wcsnlen(__s: Pwchar_t; __maxlen: size_t): size_t; cdecl;
{$EXTERNALSYM wcsnlen}


{ Search N wide characters of S for C.  }
function wmemchr(__s: Pwchar_t; __c: wchar_t; __n: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wmemchr}

{ Compare N wide characters of S1 and S2.  }
function wmemcmp(__s1, __s2: Pwchar_t; __n: size_t): Integer; cdecl;
{$EXTERNALSYM wmemcmp}

{ Copy N wide characters of SRC to DEST.  }
function wmemcpy(__dest, __src: Pwchar_t; __n: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wmemcpy}

{ Copy N wide characters of SRC to DEST, guaranteeing
   correct behavior for overlapping strings.  }
function wmemmove(__dest, __src: Pwchar_t; __n: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wmemmove}

{ Set N wide characters of S to C.  }
function wmemset(__s: Pwchar_t; __c: wchar_t; __n: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wmemset}

{ Copy N wide characters of SRC to DEST and return pointer to following
   wide character.  }
function wmempcpy(Dest: Pwchar_t; Source: Pwchar_t; Count: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wmempcpy}

{ Determine whether C constitutes a valid (one-byte) multibyte
   character.  }
function btowc(__c: Integer): wint_t; cdecl;
{$EXTERNALSYM btowc}

{ Determine whether C corresponds to a member of the extended
   character set whose multibyte representation is a single byte.  }
function wctob(__c: wint_t): Integer; cdecl;
{$EXTERNALSYM wctob}

{ Determine whether PS points to an object representing the initial
   state.  }
function mbsinit(const __ps: TMultiByteState): Integer; cdecl;
{$EXTERNALSYM mbsinit}

{ Write wide character representation of multibyte character pointed
   to by S to PWC.  }
function mbrtowc(__pwc: Pwchar_t;__s: Pwchar_t; __n: size_t; __p: PMultiByteState): size_t; cdecl;
{$EXTERNALSYM mbrtowc}

{ Write multibyte representation of wide character WC to S.  }
function wcrtomb(__s: PChar; __wc: wchar_t; __ps: PMultiByteState): size_t; cdecl;
{$EXTERNALSYM wcrtomb}

{ Return number of bytes in multibyte character pointed to by S.  }
function mbrlen(__s: PChar; __n: size_t; __ps: PMultiByteState): size_t; cdecl;
{$EXTERNALSYM mbrlen}

{ Write wide character representation of multibyte character string
   SRC to DST.  }
function mbsrtowcs(__dst: Pwchar_t; __src: PPChar; __len: size_t; __ps: PMultiByteState): size_t; cdecl;
{$EXTERNALSYM mbsrtowcs}

{ Write multibyte character representation of wide character string
   SRC to DST.  }
function wcsrtombs(__dst: PChar; __src: PPwchar_t; __len: size_t; __ps: PMultiByteState): size_t; cdecl;
{$EXTERNALSYM wcsrtombs}


{ Write wide character representation of at most NMC bytes of the
   multibyte character string SRC to DST.  }
function mbsnrtowcs(__dst: Pwchar_t; __src: PPChar; __nmc: size_t; __len: size_t; __ps: PMultiByteState): size_t; cdecl;
{$EXTERNALSYM mbsnrtowcs}

{ Write multibyte character representation of at most NWC characters
   from the wide character string SRC to DST.  }
function wcsnrtombs(__dst: PChar; __src: PPwchar_t; __nwc: size_t; __len: size_t; __ps: PMultiByteState): size_t; cdecl;
{$EXTERNALSYM wcsnrtombs}

{ The following two functions are extensions found in X/Open CAE.  }

{ Determine number of column positions required for C.  }
function wcwidth(__c: wint_t): Integer; cdecl;
{$EXTERNALSYM wcwidth}

{ Determine number of column positions required for first N wide
   characters (or fewer if S ends before this) in S.  }
function wcswidth(__s: Pwchar_t; __n: size_t): Integer; cdecl;
{$EXTERNALSYM wcswidth}


{ Convert initial portion of the wide string NPTR to `double'
   representation.  }
function wcstod(__nptr: Pwchar_t; __endptr: PPwchar_t): Double; cdecl;
{$EXTERNALSYM wcstod}

{ Likewise for `float' and `long double' sizes of floating-point numbers.  }
function wcstof(__nptr: Pwchar_t; __endptr: PPwchar_t): Single; cdecl;
{$EXTERNALSYM wcstof}
function wcstold(__nptr: Pwchar_t; __endptr: PPwchar_t): Extended; cdecl;
{$EXTERNALSYM wcstold}


{ Convert initial portion of wide string NPTR to `long int'
   representation.  }
function wcstol(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): LongInt; cdecl;
{$EXTERNALSYM wcstol}

{ Convert initial portion of wide string NPTR to `unsigned long int'
   representation.  }
function wcstoul(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): LongWord; cdecl;
{$EXTERNALSYM wcstoul}

{ Convert initial portion of wide string NPTR to `long long int'
   representation.  }
function wcstoq(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): Int64; cdecl;
{$EXTERNALSYM wcstoq}

{ Convert initial portion of wide string NPTR to `unsigned long long int'
   representation.  }
function wcstouq(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): UInt64; cdecl;
{$EXTERNALSYM wcstouq}

{ Convert initial portion of wide string NPTR to `long long int'
   representation.  }
function wcstoll(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): Int64; cdecl;
{$EXTERNALSYM wcstoll}

{ Convert initial portion of wide string NPTR to `unsigned long long int'
   representation.  }
function wcstoull(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer): UInt64; cdecl;
{$EXTERNALSYM wcstoull}


{  The concept of one static locale per category is not very well
   thought out.  Many applications will need to process its data using
   information from several different locales.  Another application is
   the implementation of the internationalization handling in the
   upcoming ISO C++ standard library.  To support this another set of
   the functions using locale data exist which have an additional
   argument.

   Attention: all these functions are *not* standardized in any form.
   This is a proof-of-concept implementation.  }

{  Special versions of the functions above which take the locale to
   use as an additional parameter.  }
function __wcstol_l(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer; __loc: __locale_t): LongInt; cdecl;
{$EXTERNALSYM __wcstol_l}

function __wcstoul_l(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer; __loc: __locale_t): LongWord; cdecl;
{$EXTERNALSYM __wcstoul_l}

function __wcstoll_l(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer; __loc: __locale_t): Int64; cdecl;
{$EXTERNALSYM __wcstoll_l}

function __wcstoull_l(__nptr: Pwchar_t; __endptr: PPwchar_t; __base: Integer; __loc: __locale_t): UInt64; cdecl;
{$EXTERNALSYM __wcstoull_l}

function __wcstod_l(__nptr: Pwchar_t; __endptr: PPwchar_t; __loc: __locale_t): Double; cdecl;
{$EXTERNALSYM __wcstod_l}

function __wcstof_l(__nptr: Pwchar_t; __endptr: PPwchar_t; __loc: __locale_t): Single; cdecl;
{$EXTERNALSYM __wcstof_l}

function __wcstold_l(__nptr: Pwchar_t; __endptr: PPwchar_t; __loc: __locale_t): Extended; cdecl;
{$EXTERNALSYM __wcstold_l}


{ Copy SRC to DEST, returning the address of the terminating L'\0' in DEST.  }
function wcpcpy(__dest: Pwchar_t; __src: Pwchar_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcpcpy}

{ Copy no more than N characters of SRC to DEST, returning the address of
   the last character written into DEST.  }
function wcpncpy(__dest: Pwchar_t; __src: Pwchar_t; __n: size_t): Pwchar_t; cdecl;
{$EXTERNALSYM wcpncpy}

{ Wide character I/O functions.  }
function fwide(fp: PIOFile; Mode: Integer): Integer; cdecl;
{$EXTERNALSYM fwide}

{ Write formatted output to STREAM.  }
function fwprintf(Stream: PIOFile; Format: Pwchar_t): Integer; cdecl; varargs;
{$EXTERNALSYM fwprintf}

{ Write formatted output to stdout.  }
function wprintf(Format: Pwchar_t): Integer; cdecl; varargs;
{$EXTERNALSYM wprintf}

{ Write formatted output of at most N characters to S.  }
function swprintf(__s: Pwchar_t; __n: size_t; Format: Pwchar_t): Integer; cdecl; varargs;
{$EXTERNALSYM swprintf}


{ Write formatted output to S from argument list ARG.  }
function vfwprintf(s: PIOFile; Format: Pwchar_t; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vfwprintf}

{ Write formatted output to stdout from argument list ARG.  }
function vwprintf(Format: Pwchar_t; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vwprintf}

{ Write formatted output of at most N character to S from argument
   list ARG.  }
function vswprintf(__s: Pwchar_t; __n: size_t; Format: Pwchar_t; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vswprintf}


{ Read formatted input from STREAM.  }
function fwscanf(Stream: PIOFile; Format: Pwchar_t): Integer; cdecl; varargs;
{$EXTERNALSYM fwscanf}

{ Read formatted input from stdin.  }
function wscanf(Format: Pwchar_t): Integer; cdecl; varargs;
{$EXTERNALSYM wscanf}

{ Read formatted input from S.  }
function swscanf(__s: Pwchar_t; Format: Pwchar_t): Integer; cdecl; varargs;
{$EXTERNALSYM swscanf}


{ Read formatted input from S into argument list ARG.  }
function vfwscanf(__s: PIOFile; Format: Pwchar_t; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vfwscanf}

{ Read formatted input from stdin into argument list ARG.  }
function vwscanf(Format: Pwchar_t; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vwscanf}

{ Read formatted input from S into argument list ARG.  }
function vswscanf(__s: Pwchar_t; Format: Pwchar_t; Arg: Pointer): Integer; cdecl;
{$EXTERNALSYM vswscanf}

{ Read a character from STREAM.  }
function fgetwc(Stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM fgetwc}
function getwc(Stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM getwc}

{ Read a character from stdin.  }
function getwchar(): wint_t; cdecl;
{$EXTERNALSYM getwchar}


{ Write a character to STREAM.  }
function fputwc(__wc: wchar_t; __stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM fputwc}
function putwc(__wc: wchar_t; __stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM putwc}

{ Write a character to stdout.  }
function putwchar(__wc: wchar_t): wint_t; cdecl;
{$EXTERNALSYM putwchar}


{ Get a newline-terminated wide character string of finite length
   from STREAM.  }
function fgetws(__ws: Pwchar_t; __n: Integer; Stream: PIOFile): Pwchar_t; cdecl;
{$EXTERNALSYM fgetws}

{ Write a string to STREAM.  }
function fputws(__ws: Pwchar_t; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fputws}


{ Push a character back onto the input buffer of STREAM.  }
function ungetwc(__wc: wint_t; Stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM ungetwc}


{ These are defined to be equivalent to the `char' functions defined
   in POSIX.1:1996.  }
function getwc_unlocked(Stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM getwc_unlocked}
function getwchar_unlocked(): wint_t; cdecl;
{$EXTERNALSYM getwchar_unlocked}

{ This is the wide character version of a GNU extension.  }
function fgetwc_unlocked(Stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM fgetwc_unlocked}

{ Faster version when locking is not necessary.  }
function fputwc_unlocked(__wc: wchar_t; Stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM fputwc_unlocked}

{ These are defined to be equivalent to the `char' functions defined
   in POSIX.1:1996.  }
function putwc_unlocked(__wc: wchar_t; Stream: PIOFile): wint_t; cdecl;
{$EXTERNALSYM putwc_unlocked}
function putwchar_unlocked(__wc: wchar_t): wint_t; cdecl;
{$EXTERNALSYM putwchar_unlocked}


{ This function does the same as `fgetws' but does not lock the stream.  }
function fgetws_unlocked(__ws: Pwchar_t; __n: Integer; Stream: PIOFile): Pwchar_t; cdecl;
{$EXTERNALSYM fgetws_unlocked}

{ This function does the same as `fputws' but does not lock the stream.  }
function fputws_unlocked(__ws: Pwchar_t; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM fputws_unlocked}

{ Format TP into S according to FORMAT.
   Write no more than MAXSIZE wide characters and return the number
   of wide characters written, or 0 if it would exceed MAXSIZE.  }
function wcsftime(__s: Pwchar_t; __maxsize: size_t; Format: Pwchar_t;
  const __tp: TUnixTime): size_t; cdecl;
{$EXTERNALSYM wcsftime}


// Translated from bits/waitflags.h

const
{ Bits in the third argument to `waitpid'.  }
  WNOHANG            = 1;               { Don't block waiting.  }
  {$EXTERNALSYM WNOHANG}
  WUNTRACED          = 2;               { Report status of stopped children.  }
  {$EXTERNALSYM WUNTRACED}

  __WALL             = $40000000;       { Wait for any child.  }
  {$EXTERNALSYM __WALL}
  __WCLONE           = $80000000;       { Wait for cloned process.  }
  {$EXTERNALSYM __WCLONE}

// Translated from bits/waitstatus.h included by sys/wait.h
// These were originally macros.

{ If WEXITSTATUS(STATUS), the low-order 8 bits of the status.  }
function WEXITSTATUS(Status: Integer): Integer;
{$EXTERNALSYM WEXITSTATUS}

{ If WTERMSIG(STATUS), the terminating signal.  }
function WTERMSIG(Status: Integer): Integer;
{$EXTERNALSYM WTERMSIG}

{ If WSTOPSIG(STATUS), the signal that stopped the child.  }
function WSTOPSIG(Status: Integer): Integer;
{$EXTERNALSYM WSTOPSIG}

{ Nonzero if STATUS indicates normal termination.  }
function WIFEXITED(Status: Integer): Boolean; //!! Integer?
{$EXTERNALSYM WIFEXITED}

{ Nonzero if STATUS indicates termination by a signal.  }
function WIFSIGNALED(Status: Integer): Boolean; //!! Integer?
{$EXTERNALSYM WIFSIGNALED}

{ Nonzero if STATUS indicates the child is stopped.  }
function WIFSTOPPED(Status: Integer): Boolean; //!! Integer?
{$EXTERNALSYM WIFSTOPPED}

{ Nonzero if STATUS indicates the child dumped core.  }
function WCOREDUMP(Status: Integer): Boolean; //!! Integer?
{$EXTERNALSYM WCOREDUMP}

{ Macros for constructing status values.  }
function W_EXITCODE(ReturnCode, Signal: Integer): Integer;
{$EXTERNALSYM W_EXITCODE}
function W_STOPCODE(Signal: Integer): Integer;
{$EXTERNALSYM W_STOPCODE}

const
  WCOREFLAG          = $80;
  {$EXTERNALSYM WCOREFLAG}

// Translated from sys/wait.h

{ Wait for a child to die.  When one does, put its status in *STAT_LOC
   and return its process ID.  For errors, return (pid_t) -1.  }
function __wait(__stat_loc: PInteger): pid_t; cdecl;
{$EXTERNALSYM __wait}
function wait(__stat_loc: PInteger): pid_t; cdecl;
{$EXTERNALSYM wait}

{ Special values for the PID argument to `waitpid' and `wait4'.  }
const
  WAIT_ANY           = Integer(-1);      { Any process.  }
  {$EXTERNALSYM WAIT_ANY}
  WAIT_MYPGRP        = 0;                { Any process in my process group.  }
  {$EXTERNALSYM WAIT_MYPGRP}


{ Wait for a child matching PID to die.
   If PID is greater than 0, match any process whose process ID is PID.
   If PID is (pid_t) -1, match any process.
   If PID is (pid_t) 0, match any process with the
   same process group as the current process.
   If PID is less than -1, match any process whose
   process group is the absolute value of PID.
   If the WNOHANG bit is set in OPTIONS, and that child
   is not already dead, return (pid_t) 0.  If successful,
   return PID and store the dead child's status in STAT_LOC.
   Return (pid_t) -1 for errors.  If the WUNTRACED bit is
   set in OPTIONS, return status for stopped children; otherwise don't.  }
function waitpid(__pid: pid_t; __stat_loc: PInteger; __options: Integer): pid_t; cdecl;
{$EXTERNALSYM waitpid}

{ The following values are used by the `waitid' function.  }
type
  idtype_t = (
    P_ALL,       { Wait for any child.  }
    P_PID,       { Wait for specified process.  }
    P_PGID       { Wait for members of process group.  }
    );
  {$EXTERNALSYM idtype_t}

{ Wait for a childing matching IDTYPE and ID to change the status and
   place appropriate information in *INFOP.
   If IDTYPE is P_PID, match any process whose process ID is ID.
   If IDTYPE is P_PGID, match any process whose process group is ID.
   If IDTYPE is P_ALL, match any process.
   If the WNOHANG bit is set in OPTIONS, and that child
   is not already dead, clear *INFOP and return 0.  If successful, store
   exit code and status in *INFOP.  }
function waitid(__idtype: idtype_t; __id: id_t; __infop: PSigInfo; __options: Integer): Integer; cdecl;
{$EXTERNALSYM waitid}

{ Wait for a child to exit.  When one does, put its status in *STAT_LOC and
   return its process ID.  For errors return (pid_t) -1.  If USAGE is not
   nil, store information about the child's resource usage there.  If the
   WUNTRACED bit is set in OPTIONS, return status for stopped children;
   otherwise don't.  }
function wait3(__stat_loc: PInteger; __options: Integer; __usage: PRUsage): pid_t; cdecl;
{$EXTERNALSYM wait3}

{ PID is like waitpid.  Other args are like wait3.  }
function wait4(__pid: pid_t; __stat_loc: PInteger; __options: Integer; __usage: PRUsage): pid_t; cdecl;
{$EXTERNALSYM wait4}


// Translated from bits/utsname.h

{  Length of the entries in `struct utsname' is 65.  }
const
  _UTSNAME_LENGTH = 65;
  {$EXTERNALSYM _UTSNAME_LENGTH}

{  Linux provides as additional information in the `struct utsname'
   the name of the current domain.  Define _UTSNAME_DOMAIN_LENGTH
   to a value != 0 to activate this entry.  }
  _UTSNAME_DOMAIN_LENGTH = _UTSNAME_LENGTH;
  {$EXTERNALSYM _UTSNAME_DOMAIN_LENGTH}

  _UTSNAME_NODENAME_LENGTH = _UTSNAME_LENGTH;
  {$EXTERNALSYM _UTSNAME_NODENAME_LENGTH}


// Translated from sys/utsname.h

{  Structure describing the system and machine.  }
type
  utsname = {packed} record
    { Name of the implementation of the operating system.  }
    sysname: packed array [0.._UTSNAME_LENGTH-1] of Char;

    { Name of this node on the network.  }
    nodename: packed array [0.._UTSNAME_NODENAME_LENGTH-1] of Char;

    { Current release level of this implementation.  }
    release: packed array [0.._UTSNAME_LENGTH-1] of Char;
    { Current version level of this release.  }
    version: packed array [0.._UTSNAME_LENGTH-1] of Char;

    { Name of the hardware type the system is running on.  }
    machine: packed array [0.._UTSNAME_LENGTH-1] of Char;

    { Name of the domain of this node on the network.  }
    domainname: packed array [0.._UTSNAME_DOMAIN_LENGTH-1] of Char;
  end;
  {$EXTERNALSYM utsname}
  TUTSName = utsname;
  PUTSName = ^TUTSName;

{ Put information about the system in NAME.  }
function uname(var __name: TUTSName): Integer; cdecl;
{$EXTERNALSYM uname}


// Translated from bits/mman.h

{  The following definitions basically come from the kernel headers.
   But the kernel header is not namespace clean.  }


{  Protections are chosen from these bits, OR'd together.  The
   implementation does not necessarily support PROT_EXEC or PROT_WRITE
   without PROT_READ.  The only guarantees are that no writing will be
   allowed without PROT_WRITE and no access will be allowed for PROT_NONE. }

const
  PROT_READ       = $1;         { Page can be read.  }
  {$EXTERNALSYM PROT_READ}
  PROT_WRITE      = $2;         { Page can be written.  }
  {$EXTERNALSYM PROT_WRITE}
  PROT_EXEC       = $4;         { Page can be executed.  }
  {$EXTERNALSYM PROT_EXEC}
  PROT_NONE       = $0;         { Page can not be accessed.  }
  {$EXTERNALSYM PROT_NONE}

{ Sharing types (must choose one and only one of these).  }
  MAP_SHARED      = $01;        { Share changes.  }
  {$EXTERNALSYM MAP_SHARED}
  MAP_PRIVATE     = $02;        { Changes are private.  }
  {$EXTERNALSYM MAP_PRIVATE}
  MAP_TYPE        = $0F;        { Mask for type of mapping.  }
  {$EXTERNALSYM MAP_TYPE}

{ Other flags.  }
  MAP_FIXED       = $10;        { Interpret addr exactly.  }
  {$EXTERNALSYM MAP_FIXED}
  MAP_FILE        = $00;
  {$EXTERNALSYM MAP_FILE}
  MAP_ANONYMOUS   = $20;        { Don't use a file.  }
  {$EXTERNALSYM MAP_ANONYMOUS}
  MAP_ANON        = MAP_ANONYMOUS;
  {$EXTERNALSYM MAP_ANON}

{ These are Linux-specific.  }
  MAP_GROWSDOWN   = $0100;      { Stack-like segment.  }
  {$EXTERNALSYM MAP_GROWSDOWN}
  MAP_DENYWRITE   = $0800;      { ETXTBSY }
  {$EXTERNALSYM MAP_DENYWRITE}
  MAP_EXECUTABLE  = $1000;      { Mark it as an executable.  }
  {$EXTERNALSYM MAP_EXECUTABLE}
  MAP_LOCKED      = $2000;      { Lock the mapping.  }
  {$EXTERNALSYM MAP_LOCKED}
  MAP_NORESERVE   = $4000;      { Don't check for reservations.  }
  {$EXTERNALSYM MAP_NORESERVE}

{ Flags to `msync'.  }
  MS_ASYNC        = 1;          { Sync memory asynchronously.  }
  {$EXTERNALSYM MS_ASYNC}
  MS_SYNC         = 4;          { Synchronous memory sync.  }
  {$EXTERNALSYM MS_SYNC}
  MS_INVALIDATE   = 2;          { Invalidate the caches.  }
  {$EXTERNALSYM MS_INVALIDATE}

{ Flags for `mlockall'.  }
  MCL_CURRENT     = 1;          { Lock all currently mapped pages.  }
  {$EXTERNALSYM MCL_CURRENT}
  MCL_FUTURE      = 2;          { Lock all additions to address space.  }
  {$EXTERNALSYM MCL_FUTURE}

{ Flags for `mremap'.  }
  MREMAP_MAYMOVE  = 1;
  {$EXTERNALSYM MREMAP_MAYMOVE}

{ Advice to `madvise'. (BSD)  }
  MADV_NORMAL      = 0;	{ No further special treatment.  }
  {$EXTERNALSYM MADV_NORMAL}
  MADV_RANDOM      = 1;	{ Expect random page references.  }
  {$EXTERNALSYM MADV_RANDOM}
  MADV_SEQUENTIAL  = 2;	{ Expect sequential page references.  }
  {$EXTERNALSYM MADV_SEQUENTIAL}
  MADV_WILLNEED    = 3;	{ Will need these pages.  }
  {$EXTERNALSYM MADV_WILLNEED}
  MADV_DONTNEED    = 4;	{ Don't need these pages.  }
  {$EXTERNALSYM MADV_DONTNEED}

{ The POSIX people had to invent similar names for the same things.  }
  POSIX_MADV_NORMAL     = 0; { No further special treatment.  }
  {$EXTERNALSYM POSIX_MADV_NORMAL}
  POSIX_MADV_RANDOM     = 1; { Expect random page references.  }
  {$EXTERNALSYM POSIX_MADV_RANDOM}
  POSIX_MADV_SEQUENTIAL = 2; { Expect sequential page references.  }
  {$EXTERNALSYM POSIX_MADV_SEQUENTIAL}
  POSIX_MADV_WILLNEED   = 3; { Will need these pages.  }
  {$EXTERNALSYM POSIX_MADV_WILLNEED}
  POSIX_MADV_DONTNEED   = 4; { Don't need these pages.  }
  {$EXTERNALSYM POSIX_MADV_DONTNEED}


// Translated from sys/mmap.h

{  Return value of `mmap' in case of an error.  }
const
  MAP_FAILED	  = __ptr_t(-1);
  {$EXTERNALSYM MAP_FAILED}

{  Map addresses starting near ADDR and extending for LEN bytes.  from
   OFFSET into the file FD describes according to PROT and FLAGS.  If ADDR
   is nonzero, it is the desired mapping address.  If the MAP_FIXED bit is
   set in FLAGS, the mapping will be at ADDR exactly (which must be
   page-aligned); otherwise the system chooses a convenient nearby address.
   The return value is the actual mapping address chosen or MAP_FAILED
   for errors (in which case `errno' is set).  A successful `mmap' call
   deallocates any previous mapping for the affected region.  }


function mmap(__addr: __ptr_t; __len: size_t; __prot: Integer; __flags: Integer; __fd: Integer; __offset: __off_t): __ptr_t; cdecl;
{$EXTERNALSYM mmap}

function mmap64(__addr: __ptr_t; __len: size_t; __prot: Integer; __flags: Integer; __fd: Integer; __offset: __off64_t): __ptr_t; cdecl;
{$EXTERNALSYM mmap64}


{  Deallocate any mapping for the region starting at ADDR and extending LEN
   bytes.  Returns 0 if successful, -1 for errors (and sets errno).  }
function munmap(__addr: __ptr_t; __len: size_t): Integer; cdecl;
{$EXTERNALSYM munmap}

{  Change the memory protection of the region starting at ADDR and
   extending LEN bytes to PROT.  Returns 0 if successful, -1 for errors
   (and sets errno).  }
function mprotect(__addr: __ptr_t; __len: size_t; __prot: Integer): Integer; cdecl;
{$EXTERNALSYM mprotect}

{  Synchronize the region starting at ADDR and extending LEN bytes with the
   file it maps.  Filesystem operations on a file being mapped are
   unpredictable before this is done.  Flags are from the MS_* set.  }
function msync(__addr: __ptr_t; __len: size_t; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM msync}

{ Advise the system about particular usage patterns the program follows
   for the region starting at ADDR and extending LEN bytes.  }
function madvise(__addr: Pointer; __len: size_t; __advice: Integer): Integer; cdecl;
{$EXTERNALSYM madvise}

{ This is the POSIX name for this function.  }
function posix_madvise(__addr: Pointer; __len: size_t; __advice: Integer): Integer; cdecl;
{$EXTERNALSYM posix_madvise}

{  Guarantee all whole pages mapped by the range [ADDR,ADDR+LEN) to
   be memory resident.  }
function mlock(__addr: __ptr_t; __len: size_t): Integer; cdecl;
{$EXTERNALSYM mlock}

{  Unlock whole pages previously mapped by the range [ADDR,ADDR+LEN).  }
function munlock(__addr: __ptr_t; __len: size_t): Integer; cdecl;
{$EXTERNALSYM munlock}

{  Cause all currently mapped pages of the process to be memory resident
   until unlocked by a call to the `munlockall', until the process exits,
   or until the process calls `execve'.  }
function mlockall(__flags: Integer): Integer; cdecl;
{$EXTERNALSYM mlockall}

{ All currently mapped pages of the process' address space become
   unlocked.  }
function munlockall: Integer; cdecl;
{$EXTERNALSYM munlockall}

{  Remap pages mapped by the range [ADDR,ADDR+OLD_LEN) to new length
   NEW_LEN.  If MAY_MOVE is MREMAP_MAYMOVE the returned address may
   differ from ADDR.  }
function mremap(__addr: __ptr_t; __old_len: size_t; __new_len: size_t; __may_move: Integer): __ptr_t; cdecl;
{$EXTERNALSYM mremap}

{ mincore returns the memory residency status of the pages in the
   current process's address space specified by [start, start + len).
   The status is returned in a vector of bytes.  The least significant
   bit of each byte is 1 if the referenced page is in memory, otherwise
   it is zero.  }
function mincore(__start: Pointer; __len: size_t; __vec: PByte): Integer; cdecl;
{$EXTERNALSYM mincore}

{ Open shared memory segment.  }
function shm_open(__name: PChar; __oflag: Integer; __mode: mode_t): Integer; cdecl;
{$EXTERNALSYM shm_open}

{ Remove shared memory segment.  }
function shm_unlink(__name: PChar): Integer; cdecl;
{$EXTERNALSYM shm_unlink}


// Translated from sys/syslog.h

const
  _PATH_LOG = '/dev/log';
  {$EXTERNALSYM _PATH_LOG}

{*
 * priorities/facilities are encoded into a single 32-bit quantity, where the
 * bottom 3 bits are the priority (0-7) and the top 28 bits are the facility
 * (0-big number).  Both the priorities and the facilities map roughly
 * one-to-one to strings in the syslogd(8) source code.  This mapping is
 * included in this file.
 *
 * priorities (these are ordered)
 *}
  LOG_EMERG           = 0;           { system is unusable }
  {$EXTERNALSYM LOG_EMERG}
  LOG_ALERT           = 1;           { action must be taken immediately }
  {$EXTERNALSYM LOG_ALERT}
  LOG_CRIT            = 2;           { critical conditions }
  {$EXTERNALSYM LOG_CRIT}
  LOG_ERR             = 3;           { error conditions }
  {$EXTERNALSYM LOG_ERR}
  LOG_WARNING         = 4;           { warning conditions }
  {$EXTERNALSYM LOG_WARNING}
  LOG_NOTICE          = 5;           { normal but significant condition }
  {$EXTERNALSYM LOG_NOTICE}
  LOG_INFO            = 6;           { informational }
  {$EXTERNALSYM LOG_INFO}
  LOG_DEBUG           = 7;           { debug-level messages }
  {$EXTERNALSYM LOG_DEBUG}

  LOG_PRIMASK         = $07;         { mask to extract priority part (internal) }
  {$EXTERNALSYM LOG_PRIMASK}

{ extract priority }
function LOG_PRI(const Value: Integer): Integer; // Macro.
{$EXTERNALSYM LOG_PRI}
function LOG_MAKEPRI(Facility, Priority: Integer): Integer; // Macro.
{$EXTERNALSYM LOG_MAKEPRI}

const
  INTERNAL_NOPRI      = $10;         { the "no priority" priority }
  {$EXTERNALSYM INTERNAL_NOPRI}
  { mark "facility" }
  INTERNAL_MARK       = 24 shl 3; // LOG_MAKEPRI(LOG_NFACILITIES, 0)
  {$EXTERNALSYM INTERNAL_MARK}

 type
  _code = {packed} record
    c_name: PChar;
    c_val: Integer;
  end;
  {$EXTERNALSYM _code}
  CODE = _code;
  {$EXTERNALSYM CODE}
  TSysLogCode = _code;

const
  prioritynames: packed array[0..13-1] of TSysLogCode =
  (
    ( c_name: 'alert'; c_val: LOG_ALERT ),
    ( c_name: 'crit'; c_val: LOG_CRIT ),
    ( c_name: 'debug'; c_val: LOG_DEBUG ),
    ( c_name: 'emerg'; c_val: LOG_EMERG ),
    ( c_name: 'err'; c_val: LOG_ERR ),
    ( c_name: 'error'; c_val: LOG_ERR ),              { DEPRECATED }
    ( c_name: 'info'; c_val: LOG_INFO ),
    ( c_name: 'none'; c_val: INTERNAL_NOPRI ),        { INTERNAL }
    ( c_name: 'notice'; c_val: LOG_NOTICE ),
    ( c_name: 'panic'; c_val: LOG_EMERG ),            { DEPRECATED }
    ( c_name: 'warn'; c_val: LOG_WARNING ),           { DEPRECATED }
    ( c_name: 'warning'; c_val: LOG_WARNING ),
    ( c_name: nil; c_val: -1 )
  );
  {$EXTERNALSYM prioritynames}

{ facility codes }
  LOG_KERN        = (0 shl 3);      { kernel messages }
  {$EXTERNALSYM LOG_KERN}
  LOG_USER        = (1 shl 3);      { random user-level messages }
  {$EXTERNALSYM LOG_USER}
  LOG_MAIL        = (2 shl 3);      { mail system }
  {$EXTERNALSYM LOG_MAIL}
  LOG_DAEMON      = (3 shl 3);      { system daemons }
  {$EXTERNALSYM LOG_DAEMON}
  LOG_AUTH        = (4 shl 3);      { security/authorization messages }
  {$EXTERNALSYM LOG_AUTH}
  LOG_SYSLOG      = (5 shl 3);      { messages generated internally by syslogd }
  {$EXTERNALSYM LOG_SYSLOG}
  LOG_LPR         = (6 shl 3);      { line printer subsystem }
  {$EXTERNALSYM LOG_LPR}
  LOG_NEWS        = (7 shl 3);      { network news subsystem }
  {$EXTERNALSYM LOG_NEWS}
  LOG_UUCP        = (8 shl 3);      { UUCP subsystem }
  {$EXTERNALSYM LOG_UUCP}
  LOG_CRON        = (9 shl 3);      { clock daemon }
  {$EXTERNALSYM LOG_CRON}
  LOG_AUTHPRIV    = (10 shl 3);     { security/authorization messages (private) }
  {$EXTERNALSYM LOG_AUTHPRIV}
  LOG_FTP         = (11 shl 3);     { ftp daemon }
  {$EXTERNALSYM LOG_FTP}

  { other codes through 15 reserved for system use }
  LOG_LOCAL0      = (16 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL0}
  LOG_LOCAL1      = (17 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL1}
  LOG_LOCAL2      = (18 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL2}
  LOG_LOCAL3      = (19 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL3}
  LOG_LOCAL4      = (20 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL4}
  LOG_LOCAL5      = (21 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL5}
  LOG_LOCAL6      = (22 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL6}
  LOG_LOCAL7      = (23 shl 3);     { reserved for local use }
  {$EXTERNALSYM LOG_LOCAL7}

  LOG_NFACILITIES = 24;             { current number of facilities }
  {$EXTERNALSYM LOG_NFACILITIES}
  LOG_FACMASK     = $03f8;          { mask to extract facility part }
  {$EXTERNALSYM LOG_FACMASK}

{ facility of pri }
function LOG_FAC(Value: Integer): Integer; // Macro.
{$EXTERNALSYM LOG_FAC}

const
  facilitynames: packed array[0..23-1] of TSysLogCode =
  (
    ( c_name: 'auth'; c_val: LOG_AUTH ),
    ( c_name: 'authpriv'; c_val: LOG_AUTHPRIV ),
    ( c_name: 'cron'; c_val: LOG_CRON ),
    ( c_name: 'daemon'; c_val: LOG_DAEMON ),
    ( c_name: 'ftp'; c_val: LOG_FTP ),
    ( c_name: 'kern'; c_val: LOG_KERN ),
    ( c_name: 'lpr'; c_val: LOG_LPR ),
    ( c_name: 'mail'; c_val: LOG_MAIL ),
    ( c_name: 'mark'; c_val: INTERNAL_MARK ),      { INTERNAL }
    ( c_name: 'news'; c_val: LOG_NEWS ),
    ( c_name: 'security'; c_val: LOG_AUTH ),       { DEPRECATED }
    ( c_name: 'syslog'; c_val: LOG_SYSLOG ),
    ( c_name: 'user'; c_val: LOG_USER ),
    ( c_name: 'uucp'; c_val: LOG_UUCP ),
    ( c_name: 'local0'; c_val: LOG_LOCAL0 ),
    ( c_name: 'local1'; c_val: LOG_LOCAL1 ),
    ( c_name: 'local2'; c_val: LOG_LOCAL2 ),
    ( c_name: 'local3'; c_val: LOG_LOCAL3 ),
    ( c_name: 'local4'; c_val: LOG_LOCAL4 ),
    ( c_name: 'local5'; c_val: LOG_LOCAL5 ),
    ( c_name: 'local6'; c_val: LOG_LOCAL6 ),
    ( c_name: 'local7'; c_val: LOG_LOCAL7 ),
    ( c_name: nil; c_val: -1 )
  );
  {$EXTERNALSYM facilitynames}

{
 * arguments to setlogmask.
 }
function LOG_MASK(Priority: Integer): Integer;        { mask for one priority }
{$EXTERNALSYM LOG_MASK}
function LOG_UPTO(Priority: Integer): Integer;        { all priorities through pri }
{$EXTERNALSYM LOG_UPTO}

{
 * Option flags for openlog.
 *
 * LOG_ODELAY no longer does anything.
 * LOG_NDELAY is the inverse of what it used to be.
 }
const
  LOG_PID       = $01;    { log the pid with each message }
  {$EXTERNALSYM LOG_PID}
  LOG_CONS      = $02;    { log on the console if errors in sending }
  {$EXTERNALSYM LOG_CONS}
  LOG_ODELAY    = $04;    { delay open until first syslog() (default) }
  {$EXTERNALSYM LOG_ODELAY}
  LOG_NDELAY    = $08;    { don't delay open }
  {$EXTERNALSYM LOG_NDELAY}
  LOG_NOWAIT    = $10;    { don't wait for console forks: DEPRECATED }
  {$EXTERNALSYM LOG_NOWAIT}
  LOG_PERROR    = $20;    { log to stderr as well }
  {$EXTERNALSYM LOG_PERROR}

{ Close desriptor used to write to system logger.  }
procedure closelog; cdecl;
{$EXTERNALSYM closelog}

{ Open connection to system logger.  }
procedure openlog(__ident: PChar; __option: Integer; __facility: Integer); cdecl;
{$EXTERNALSYM openlog}

{ Set the log mask level.  }
function setlogmask(__mask: Integer): Integer; cdecl;
{$EXTERNALSYM setlogmask}

{ Generate a log message using FMT string and option arguments.  }
procedure syslog(__pri: Integer; __fmt: PChar); cdecl; varargs;
{$EXTERNALSYM syslog}

{ Generate a log message using FMT and using arguments pointed to by AP.  }
procedure vsyslog(__pri: Integer; Fmt: PChar; Arg: Pointer);
{$EXTERNALSYM vsyslog}

// Translated from from gnu/libc-version.h

{ Return string describing release status of currently running GNU libc.  }
function gnu_get_libc_release: PChar; cdecl;
{$EXTERNALSYM gnu_get_libc_release}

{ Return string describing version of currently running GNU libc.  }
function gnu_get_libc_version: PChar; cdecl;
{$EXTERNALSYM gnu_get_libc_version}


// Translated from bits/uio.h

{ We should normally use the Linux kernel header file to define this
   type and macros but this calls for trouble because of the header
   includes other kernel headers.  }

{ Size of object which can be written atomically.

   This macro has different values in different kernel versions.  The
   latest versions of the kernel use 1024 and this is good choice.  Since
   the C library implementation of readv/writev is able to emulate the
   functionality even if the currently running kernel does not support
   this large value the readv/writev call will not fail because of this.  }
const
  UIO_MAXIOV = 1024;
  {$EXTERNALSYM UIO_MAXIOV}


{ Structure for scatter/gather I/O.  }
type
  iovec = {packed} record
    iov_base: Pointer;    { Pointer to data.  }
    iov_len: size_t;      { Length of data.  }
  end;
  {$EXTERNALSYM iovec}
  TIoVector = iovec;
  PIoVector = ^TIoVector;


// Translated from sys/uio.h

{ Read data from file descriptor FD, and put the result in the
   buffers described by VECTOR, which is a vector of COUNT `struct iovec's.
   The buffers are filled in the order specified.
   Operates just like `read' (see <unistd.h>) except that data are
   put in VECTOR instead of a contiguous buffer.  }
function readv(__fd: Integer; __vector: PIoVector; __count: Integer): ssize_t; cdecl;
{$EXTERNALSYM readv}

{ Write data pointed by the buffers described by VECTOR, which
   is a vector of COUNT `struct iovec's, to file descriptor FD.
   The data is written in the order specified.
   Operates just like `write' (see <unistd.h>) except that the data
   are taken from VECTOR instead of a contiguous buffer.  }
function writev(__fd: Integer; __vector: PIoVector; __count: Integer): ssize_t; cdecl;
{$EXTERNALSYM writev}


// Translated from asm/sockios.h
// Taken from SuSE 7.0:
//   cat /proc/version
//   Linux version 2.2.16 (root@Laptop.suse.de) (gcc version 2.95.2 19991024 (release)) #1 Tue Aug 15 23:04:39 GMT 2000

const
{ Socket-level I/O control calls. }
  FIOSETOWN     = $8901;
  {$EXTERNALSYM FIOSETOWN}
  SIOCSPGRP     = $8902;
  {$EXTERNALSYM SIOCSPGRP}
  FIOGETOWN     = $8903;
  {$EXTERNALSYM FIOGETOWN}
  SIOCGPGRP     = $8904;
  {$EXTERNALSYM SIOCGPGRP}
  SIOCATMARK    = $8905;
  {$EXTERNALSYM SIOCATMARK}
  SIOCGSTAMP    = $8906;         { Get stamp }
  {$EXTERNALSYM SIOCGSTAMP}

// Translated from asm/socket.h
// Taken from SuSE 7.0:
//   cat /proc/version
//   Linux version 2.2.16 (root@Laptop.suse.de) (gcc version 2.95.2 19991024 (release)) #1 Tue Aug 15 23:04:39 GMT 2000

const
{ For setsockoptions(2) }
  SOL_SOCKET    = 1;
  {$EXTERNALSYM SOL_SOCKET}

  SO_DEBUG      = 1;
  {$EXTERNALSYM SO_DEBUG}
  SO_REUSEADDR  = 2;
  {$EXTERNALSYM SO_REUSEADDR}
  SO_TYPE       = 3;
  {$EXTERNALSYM SO_TYPE}
  SO_ERROR      = 4;
  {$EXTERNALSYM SO_ERROR}
  SO_DONTROUTE  = 5;
  {$EXTERNALSYM SO_DONTROUTE}
  SO_BROADCAST  = 6;
  {$EXTERNALSYM SO_BROADCAST}
  SO_SNDBUF     = 7;
  {$EXTERNALSYM SO_SNDBUF}
  SO_RCVBUF     = 8;
  {$EXTERNALSYM SO_RCVBUF}
  SO_KEEPALIVE  = 9;
  {$EXTERNALSYM SO_KEEPALIVE}
  SO_OOBINLINE  = 10;
  {$EXTERNALSYM SO_OOBINLINE}
  SO_NO_CHECK   = 11;
  {$EXTERNALSYM SO_NO_CHECK}
  SO_PRIORITY   = 12;
  {$EXTERNALSYM SO_PRIORITY}
  SO_LINGER     = 13;
  {$EXTERNALSYM SO_LINGER}
  SO_BSDCOMPAT  = 14;
  {$EXTERNALSYM SO_BSDCOMPAT}
{ To add : SO_REUSEPORT = 15; }
  SO_PASSCRED   = 16;
  {$EXTERNALSYM SO_PASSCRED}
  SO_PEERCRED   = 17;
  {$EXTERNALSYM SO_PEERCRED}
  SO_RCVLOWAT   = 18;
  {$EXTERNALSYM SO_RCVLOWAT}
  SO_SNDLOWAT   = 19;
  {$EXTERNALSYM SO_SNDLOWAT}
  SO_RCVTIMEO   = 20;
  {$EXTERNALSYM SO_RCVTIMEO}
  SO_SNDTIMEO   = 21;
  {$EXTERNALSYM SO_SNDTIMEO}

{ Security levels - as per NRL IPv6 - don't actually do anything }
  SO_SECURITY_AUTHENTICATION       = 22;
  {$EXTERNALSYM SO_SECURITY_AUTHENTICATION}
  SO_SECURITY_ENCRYPTION_TRANSPORT = 23;
  {$EXTERNALSYM SO_SECURITY_ENCRYPTION_TRANSPORT}
  SO_SECURITY_ENCRYPTION_NETWORK   = 24;
  {$EXTERNALSYM SO_SECURITY_ENCRYPTION_NETWORK}

  SO_BINDTODEVICE                  = 25;
  {$EXTERNALSYM SO_BINDTODEVICE}

{ Socket filtering }
  SO_ATTACH_FILTER = 26;
  {$EXTERNALSYM SO_ATTACH_FILTER}
  SO_DETACH_FILTER = 27;
  {$EXTERNALSYM SO_DETACH_FILTER}


// Translated from bits/socket.h

type
  TSocket = TFileDescriptor;
  PSocket = ^TSocket;

const
  INVALID_SOCKET = -1;
  {$EXTERNALSYM INVALID_SOCKET}
  SOCKET_ERROR = -1;
  {$EXTERNALSYM SOCKET_ERROR}

  // Address to accept any incoming messages.
  INADDR_ANY = 0;
  {$EXTERNALSYM INADDR_ANY}

  // Address to send to all hosts.
  INADDR_BROADCAST = -1;
  {$EXTERNALSYM INADDR_BROADCAST}

  // Address indicating an error return.
  INADDR_NONE = $FFFFFFFF;
  {$EXTERNALSYM INADDR_NONE}


// Translated from bits/socket.h


{ Types of sockets.  }
type
  __socket_type =
  (
    { Sequenced, reliable, connection-based byte streams.  }
    SOCK_STREAM     = 1,               // stream socket
    {$EXTERNALSYM SOCK_STREAM}

    { Connectionless, unreliable datagrams of fixed maximum length.  }
    SOCK_DGRAM      = 2,               // datagram socket
    {$EXTERNALSYM SOCK_DGRAM}

    { Raw protocol interface.  }
    SOCK_RAW        = 3,               // raw-protocol interface
    {$EXTERNALSYM SOCK_RAW}

    { Reliably-delivered messages.  }
    SOCK_RDM        = 4,               // reliably-delivered message
    {$EXTERNALSYM SOCK_RDM}

    { Sequenced, reliable, connection-based, datagrams of fixed maximum length.  }
    SOCK_SEQPACKET  = 5,               // sequenced packet stream
    {$EXTERNALSYM SOCK_SEQPACKET}

    { Linux specific way of getting packets at the dev level.
      For writing rarp and other similar things on the user level. }
    SOCK_PACKET  = 10                  // Linux specific way of getting packets
    {$EXTERNALSYM SOCK_PACKET}
  );
  {$EXTERNALSYM __socket_type}

const
{ Protocol families.  }
  PF_UNSPEC       = 0;               // Unspecified.
  {$EXTERNALSYM PF_UNSPEC}
  PF_LOCAL        = 1;               // Local to host (pipes and file-domain).
  {$EXTERNALSYM PF_LOCAL}
  PF_UNIX         = PF_LOCAL;        // Old BSD name for PF_LOCAL.
  {$EXTERNALSYM PF_UNIX}
  PF_FILE         = PF_LOCAL;        // Another non-standard name for PF_LOCAL.
  {$EXTERNALSYM PF_FILE}
  PF_INET         = 2;               // IP protocol family
  {$EXTERNALSYM PF_INET}
  PF_AX25         = 3;               // Amateur Radio AX.25.
  {$EXTERNALSYM PF_AX25}
  PF_IPX          = 4;               // Novell Internet Protocol.
  {$EXTERNALSYM PF_IPX}
  PF_APPLETALK    = 5;               // Appletalk DDP.
  {$EXTERNALSYM PF_APPLETALK}
  PF_NETROM       = 6;               // Amateur radio NetROM.
  {$EXTERNALSYM PF_NETROM}
  PF_BRIDGE       = 7;               // Multiprotocol bridge.
  {$EXTERNALSYM PF_BRIDGE}
  PF_ATMPVC       = 8;               // ATM PVCs.
  {$EXTERNALSYM PF_ATMPVC}
  PF_X25          = 9;               // Reserved for X.25 project.
  {$EXTERNALSYM PF_X25}
  PF_INET6        = 10;              // IP version 6.
  {$EXTERNALSYM PF_INET6}
  PF_ROSE         = 11;              // Amateur radio X.25 PLP.
  {$EXTERNALSYM PF_ROSE}
  PF_DECnet       = 12;              // Reserved for DECnet project.
  {$EXTERNALSYM PF_DECnet}
  PF_NETBEUI      = 13;              // Reserved for 802.2LLC project.
  {$EXTERNALSYM PF_NETBEUI}
  PF_SECURITY     = 14;              // Security callback pseudo AF.
  {$EXTERNALSYM PF_SECURITY}
  PF_KEY          = 15;              // PFKEY key management API.
  {$EXTERNALSYM PF_KEY}
  PF_NETLINK      = 16;
  {$EXTERNALSYM PF_NETLINK}
  PF_ROUTE        = PF_NETLINK;      // Alias to emulate 4.4BSD.
  {$EXTERNALSYM PF_ROUTE}
  PF_PACKET       = 17;              // Packet family.
  {$EXTERNALSYM PF_PACKET}
  PF_ASH          = 18;              // Ash.
  {$EXTERNALSYM PF_ASH}
  PF_ECONET       = 19;              // Acorn Econet.
  {$EXTERNALSYM PF_ECONET}
  PF_ATMSVC       = 20;              // ATM SVCs.
  {$EXTERNALSYM PF_ATMSVC}
  PF_SNA          = 22;              // Linux SNA project.
  {$EXTERNALSYM PF_SNA}
  PF_IRDA         = 23;              // IRDA sockets.
  {$EXTERNALSYM PF_IRDA}
  PF_PPPOX        = 24;              // PPPoX sockets.
  {$EXTERNALSYM PF_PPPOX}
  PF_MAX          = 32;              // For now ...
  {$EXTERNALSYM PF_MAX}

{ Address families.  }  
  AF_UNSPEC       = PF_UNSPEC;
  {$EXTERNALSYM AF_UNSPEC}
  AF_LOCAL        = PF_LOCAL;
  {$EXTERNALSYM AF_LOCAL}
  AF_UNIX         = PF_UNIX;
  {$EXTERNALSYM AF_UNIX}
  AF_FILE         = PF_FILE;
  {$EXTERNALSYM AF_FILE}
  AF_INET         = PF_INET;
  {$EXTERNALSYM AF_INET}
  AF_AX25         = PF_AX25;
  {$EXTERNALSYM AF_AX25}
  AF_IPX          = PF_IPX;
  {$EXTERNALSYM AF_IPX}
  AF_APPLETALK    = PF_APPLETALK;
  {$EXTERNALSYM AF_APPLETALK}
  AF_NETROM       = PF_NETROM;
  {$EXTERNALSYM AF_NETROM}
  AF_BRIDGE       = PF_BRIDGE;
  {$EXTERNALSYM AF_BRIDGE}
  AF_ATMPVC       = PF_ATMPVC;
  {$EXTERNALSYM AF_ATMPVC}
  AF_X25          = PF_X25;
  {$EXTERNALSYM AF_X25}
  AF_INET6        = PF_INET6;
  {$EXTERNALSYM AF_INET6}
  AF_ROSE         = PF_ROSE;
  {$EXTERNALSYM AF_ROSE}
  AF_DECnet       = PF_DECnet;
  {$EXTERNALSYM AF_DECnet}
  AF_NETBEUI      = PF_NETBEUI;
  {$EXTERNALSYM AF_NETBEUI}
  AF_SECURITY     = PF_SECURITY;
  {$EXTERNALSYM AF_SECURITY}
  AF_KEY          = PF_KEY;
  {$EXTERNALSYM AF_KEY}
  AF_NETLINK      = PF_NETLINK;
  {$EXTERNALSYM AF_NETLINK}
  AF_ROUTE        = PF_ROUTE;
  {$EXTERNALSYM AF_ROUTE}
  AF_PACKET       = PF_PACKET;
  {$EXTERNALSYM AF_PACKET}
  AF_ASH          = PF_ASH;
  {$EXTERNALSYM AF_ASH}
  AF_ECONET       = PF_ECONET;
  {$EXTERNALSYM AF_ECONET}
  AF_ATMSVC       = PF_ATMSVC;
  {$EXTERNALSYM AF_ATMSVC}
  AF_SNA          = PF_SNA;
  {$EXTERNALSYM AF_SNA}
  AF_IRDA         = PF_IRDA;
  {$EXTERNALSYM AF_IRDA}
  AF_PPPOX        = PF_PPPOX;
  {$EXTERNALSYM AF_PPPOX}
  AF_MAX          = PF_MAX;
  {$EXTERNALSYM AF_MAX}


  { Socket level values . Others are defined in the appropriate headers

    XXX These definitions also should go into the appropriate headers as
    far as they are available.  }

  SOL_RAW       = 255;
  {$EXTERNALSYM SOL_RAW}
  SOL_DECNET    = 261;
  {$EXTERNALSYM SOL_DECNET}
  SOL_X25       = 262;
  {$EXTERNALSYM SOL_X25}
  SOL_PACKET    = 263;
  {$EXTERNALSYM SOL_PACKET}
  SOL_ATM       = 264;                  // ATM layer (cell level).
  {$EXTERNALSYM SOL_ATM}
  SOL_AAL       = 265;                  // ATM Adaption Layer (packet level).
  {$EXTERNALSYM SOL_AAL}
  SOL_IRDA      = 266;
  {$EXTERNALSYM SOL_IRDA}

  // Maximum queue length specifiable by listen.
  SOMAXCONN     = 128;
  {$EXTERNALSYM SOMAXCONN}


// Translated from bits/sockaddr.h (inlined in bits/socket.h)

type
  { POSIX.1g specifies this type name for the `sa_family' member. }
  sa_family_t = Word;
  {$EXTERNALSYM sa_family_t}

const
  __SOCKADDR_COMMON_SIZE = SizeOf(Word);
  {$EXTERNALSYM __SOCKADDR_COMMON_SIZE}

{ Return the length of a `sockaddr' structure.  }
function SA_LEN(const UnsafeSockAddrBuffer): Cardinal; // Untyped buffer; this is *unsafe*.
{$EXTERNALSYM SA_LEN}

function __libc_sa_len(__af: sa_family_t): Integer; cdecl;
{$EXTERNALSYM __libc_sa_len}

type
  SunB = {packed} record
    s_b1, s_b2, s_b3, s_b4: u_char;
  end;
  {$EXTERNALSYM SunB}

  SunW = {packed} record
    s_w1, s_w2: u_short;
  end;
  {$EXTERNALSYM SunW}

  in_addr = {packed} record
    case Integer of
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: u_long);
  end;
  {$EXTERNALSYM in_addr}
  TInAddr = in_addr;
  PInAddr = ^TInAddr;

{ Structure describing a generic socket address.  }
type
  sockaddr = {packed} record
    case Integer of
      0: (sa_family: sa_family_t;
          sa_data: packed array[0..13] of Byte);
      1: (sin_family: sa_family_t;
          sin_port: u_short;
          sin_addr: TInAddr;
          sin_zero: packed array[0..7] of Byte);
  end;
  {$EXTERNALSYM sockaddr}
  TSockAddr = sockaddr;
  PSockAddr = ^TSockAddr;

type
  __ss_aligntype = __uint32_t;
  {$EXTERNALSYM __ss_aligntype}

const
  _SS_SIZE = 128;
  {$EXTERNALSYM _SS_SIZE}
  _SS_PADSIZE = _SS_SIZE - (2 * SizeOf(__ss_aligntype));
  {$EXTERNALSYM _SS_PADSIZE}

type
  sockaddr_storage = {packed} record
    __ss__family: sa_family_t;     { Address family, etc.  }
    __ss_align: __ss_aligntype;    { Force desired alignment.  }
    __ss_padding: packed array [0.._SS_PADSIZE-1] of Byte;
  end;
  {$EXTERNALSYM sockaddr_storage}


const
  { Bits in the FLAGS argument to `send', `recv', et al. }
  MSG_OOB       = $01;                  // Process out-of-band data.
  {$EXTERNALSYM MSG_OOB}
  MSG_PEEK      = $02;                  // Peek at incoming messages.
  {$EXTERNALSYM MSG_PEEK}
  MSG_DONTROUTE = $04;                  // Don't use local routing.
  {$EXTERNALSYM MSG_DONTROUTE}
  MSG_TRYHARD   = MSG_DONTROUTE;        // DECnet uses a different name.
  {$EXTERNALSYM MSG_TRYHARD}
  MSG_CTRUNC    = $08;                  // Control data lost before delivery.
  {$EXTERNALSYM MSG_CTRUNC}
  MSG_PROXY     = $10;                  // Supply or ask second address.
  {$EXTERNALSYM MSG_PROXY}
  MSG_TRUNC     = $20;
  {$EXTERNALSYM MSG_TRUNC}
  MSG_DONTWAIT  = $40;                  // Nonblocking IO.
  {$EXTERNALSYM MSG_DONTWAIT}
  MSG_EOR       = $80;                  // End of record.
  {$EXTERNALSYM MSG_EOR}
  MSG_WAITALL   = $100;                 // Wait for a full request.
  {$EXTERNALSYM MSG_WAITALL}
  MSG_FIN= $200;
  {$EXTERNALSYM MSG_FIN}
  MSG_SYN       = $400;
  {$EXTERNALSYM MSG_SYN}
  MSG_CONFIRM   = $800;                 // Confirm path validity.
  {$EXTERNALSYM MSG_CONFIRM}
  MSG_RST       = $1000;
  {$EXTERNALSYM MSG_RST}
  MSG_ERRQUEUE  = $2000;                // Fetch message from error queue.
  {$EXTERNALSYM MSG_ERRQUEUE}
  MSG_NOSIGNAL  = $4000;                // Do not generate SIGPIPE.
  {$EXTERNALSYM MSG_NOSIGNAL}

  
type
  { Structure describing messages sent by
     `sendmsg' and received by `recvmsg'.  }
  msghdr = {packed} record
    msg_name: PChar;                    // Address to send to/receive from.
    msg_namelen: socklen_t;             // Length of address data.

    msg_iov: PIoVector;                 // Vector of data to send/receive into.
    msg_iovlen: size_t;                 // Number of elements in the vector.

    msg_control: Pointer;               // Ancillary data (eg BSD filedesc passing).
    msg_controllen: size_t;             // Ancillary data buffer length.

    msg_flags: Integer;	                // Flags on received message.
  end;
  {$EXTERNALSYM msghdr}
  TMessageHeader = msghdr;
  PMessageHeader = ^TMessageHeader;

{ Structure used for storage of ancillary data object information.  }
  cmsghdr = {packed} record
    cmsg_len: size_t;          { Length of data in cmsg_data plus length
				 of cmsghdr structure.  }
    cmsg_level: Integer;       { Originating protocol.  }
    cmsg_type: Integer;        { Protocol specific type.  }
  end;
  {$EXTERNALSYM cmsghdr}
  TCMessageHeader = cmsghdr;
  PCMessageHeader = ^TCMessageHeader;


{ Ancillary data object manipulation macros.  }
function CMSG_DATA(cmsg: Pointer): PByte;
{$EXTERNALSYM CMSG_DATA}
function CMSG_NXTHDR(mhdr: PMessageHeader; cmsg: PCMessageHeader): PCMessageHeader;
{$EXTERNALSYM CMSG_NXTHDR}
function CMSG_FIRSTHDR(mhdr: PMessageHeader): PCMessageHeader;
{$EXTERNALSYM CMSG_FIRSTHDR}
function CMSG_ALIGN(len: size_t): size_t;
{$EXTERNALSYM CMSG_ALIGN}
function CMSG_SPACE(len: size_t): size_t;
{$EXTERNALSYM CMSG_SPACE}
function CMSG_LEN(len: size_t): size_t;
{$EXTERNALSYM CMSG_LEN}

function __cmsg_nxthdr(__mhdr: PMessageHeader; __cmsg: PCMessageHeader): PCMessageHeader; cdecl;
{$EXTERNALSYM __cmsg_nxthdr}

const
{ Socket level message types.  This must match the definitions in
   <linux/socket.h>.  }
  SCM_RIGHTS    = $01;                  // Transfer file descriptors.
  {$EXTERNALSYM SCM_RIGHTS}
  SCM_CREDENTIALS = $02;                // Credentials passing.
  {$EXTERNALSYM SCM_CREDENTIALS}
  SCM_CONNECT   = $03;                  // Data array is `struct scm_connect'.
  {$EXTERNALSYM SCM_CONNECT}


type
  // User visible structure for SCM_CREDENTIALS message
  ucred = {packed} record
    pid: pid_t;                 // PID of sending process.
    uid: uid_t;	                // UID of sending process.
    gid: gid_t;	                // GID of sending process.
  end;
  {$EXTERNALSYM ucred}

// { Get socket manipulation related informations from kernel headers.  }

// Translated above.

type
  // Structure used to manipulate the SO_LINGER option.
  linger = {packed} record
    l_onoff: Integer;           // Nonzero to linger on close.
    l_linger: Integer;          // Time to linger.
  end;
  {$EXTERNALSYM linger}

type
  { This is the 4.3 BSD `struct sockaddr' format, which is used as wire
     format in the grotty old 4.3 `talk' protocol. }
  osockaddr = sockaddr;                 // case of 0
  {$EXTERNALSYM osockaddr}

  { Other family struc names  }
  sockaddr_in = sockaddr;               // case of 1
  {$EXTERNALSYM sockaddr_in}
  TSockAddrIn = sockaddr_in;
  PSockAddrIn = ^TSockAddrIn;

const
  { The following constants should be used for the second parameter of `shutdown'. }
  SHUT_RD = 0;                  { No more receptions. }
  {$EXTERNALSYM SHUT_RD}
  SHUT_WR = 1;                  { No more transmissions. }
  {$EXTERNALSYM SHUT_WR}
  SHUT_RDWR = 2;                { No more receptions or transmissions. }
  {$EXTERNALSYM SHUT_RDWR}


{ Create a new socket of type TYPE in domain DOMAIN, using
   protocol PROTOCOL.  If PROTOCOL is zero, one is chosen automatically.
   Returns a file descriptor for the new socket, or -1 for errors. }
// Only the "int, int, int" variant is defined in the C header file,
// but appropriate would have been "int, enum __socket_type, int"
function socket(__domain, __type, __protocol: Integer): TSocket; cdecl; overload;
function socket(__domain: Integer; __type: __socket_type; __protocol: Integer): TSocket; cdecl; overload;
{$EXTERNALSYM socket}

{ Create two new sockets, of type TYPE in domain DOMAIN and using
   protocol PROTOCOL, which are connected to each other, and put file
   descriptors for them in FDS[0] and FDS[1].  If PROTOCOL is zero,
   one will be chosen automatically.  Returns 0 on success, -1 for errors. }
type
  TSocketPair = packed array[0..1] of TSocket;

// Only the "int, int, int" variant is defined in the C header file,
// but appropriate would have been "int, enum __socket_type, int"
function socketpair(__domain, __type, __protocol: Integer; var __fds: TSocketPair): Integer; cdecl; overload;
function socketpair(__domain: Integer; __type: __socket_type; __protocol: Integer; var __fds: TSocketPair): Integer; cdecl; overload;
{$EXTERNALSYM socketpair}

{ Give the socket FD the local address ADDR (which is LEN bytes long). }
function bind(__fd: TSocket; const __addr: sockaddr; __len: socklen_t ): Integer; cdecl;
{$EXTERNALSYM bind}

{ Put the local address of FD into *ADDR and its length in *LEN. }
function getsockname(__fd: TSocket; var __addr: sockaddr; var __len: socklen_t): Integer; cdecl;
{$EXTERNALSYM getsockname}

{ Open a connection on socket FD to peer at ADDR (which LEN bytes long).
   For connectionless socket types, just set the default address to send to
   and the only address from which to accept transmissions.
   Return 0 on success, -1 for errors. }
function connect(__fd: TSocket; const __addr: sockaddr; __len: socklen_t): Integer; cdecl;
{$EXTERNALSYM connect}

{ Put the address of the peer connected to socket FD into *ADDR
   (which is *LEN bytes long), and its actual length into *LEN. }
function getpeername(__fd: TSocket; var __addr: sockaddr; var __len: socklen_t): Integer; cdecl;
{$EXTERNALSYM getpeername}

{ Send N bytes of BUF to socket FD.  Returns the number sent or -1. }
function send(__fd: TSocket; const __buf; __n: size_t; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM send}

{ Read N bytes into BUF from socket FD.
   Returns the number read or -1 for errors. }
function recv(__fd: TSocket; var __buf; __n: size_t; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM recv}

{ Send N bytes of BUF on socket FD to peer at address ADDR (which is
   ADDR_LEN bytes long).  Returns the number sent, or -1 for errors. }
function sendto(__fd: TSocket; const __buf; __n: size_t; __flags: Integer;
  const __addr: sockaddr; __addr_len: socklen_t): Integer; cdecl;
{$EXTERNALSYM sendto}

{ Read N bytes into BUF through socket FD.
   If ADDR is not NULL, fill in *ADDR_LEN bytes of it with the address of
   the sender, and store the actual size of the address in *ADDR_LEN.
   Returns the number of bytes read or -1 for errors. }
function recvfrom(__fd: TSocket; var __buf; __n: size_t; __flags: Integer;
  __addr: PSockAddr; __addr_len: PSocketLength): Integer; cdecl;
{$EXTERNALSYM recvfrom}

{ Send a message described MESSAGE on socket FD.
   Returns the number of bytes sent, or -1 for errors. }
function sendmsg(__fd: TSocket; const __message: msghdr; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM sendmsg}

{ Receive a message as described by MESSAGE from socket FD.
   Returns the number of bytes read or -1 for errors. }
function recvmsg(__fd: TSocket; var __message: msghdr; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM recvmsg}

{ Put the current value for socket FD's option OPTNAME at protocol level LEVEL
   into OPTVAL (which is *OPTLEN bytes long), and set *OPTLEN to the value's
   actual length.  Returns 0 on success, -1 for errors. }
function getsockopt(__fd: TSocket; __level, __optname: Integer; __optval: Pointer; var __optlen: socklen_t): Integer; cdecl;
{$EXTERNALSYM getsockopt}

{ Set socket FD's option OPTNAME at protocol level LEVEL
   to *OPTVAL (which is OPTLEN bytes long).
   Returns 0 on success, -1 for errors. }
function setsockopt(__fd: TSocket; __level, __optname: Integer; __optval: Pointer; __optlen: socklen_t): Integer; cdecl;
{$EXTERNALSYM setsockopt}

{ Prepare to accept connections on socket FD.
   N connection requests will be queued before further requests are refused.
   Returns 0 on success, -1 for errors. }
function listen(__fd: TSocket; __n: Cardinal): Integer; cdecl;
{$EXTERNALSYM listen}

{ Await a connection on socket FD.
   When a connection arrives, open a new socket to communicate with it,
   set *ADDR (which is *ADDR_LEN bytes long) to the address of the connecting
   peer and *ADDR_LEN to the address's actual length, and return the
   new socket's descriptor, or -1 for errors. }
function accept(__fd: TSocket; __addr: PSockAddr; __addr_len: PSocketLength): Integer; cdecl;
{$EXTERNALSYM accept}

{ Shut down all or part of the connection open on socket FD.
   HOW determines what to shut down:
     SHUT_RD   = No more receptions;
     SHUT_WR   = No more transmissions;
     SHUT_RDWR = No more receptions or transmissions.
   Returns 0 on success, -1 for errors. }
function shutdown(__fd: TSocket; __how: Integer): Integer; cdecl;
{$EXTERNALSYM shutdown}

{ FDTYPE is S_IFSOCK or another S_IF* macro defined in <sys/stat.h>;
   returns 1 if FD is open on an object of the indicated type, 0 if not,
   or -1 for errors (setting errno). }
function isfdtype (__fd: TFileDescriptor; __fdtype: Integer): Integer; cdecl;
{$EXTERNALSYM isfdtype}

// Translated from sys/un.h

{ Structure describing the address of an AF_LOCAL (aka AF_UNIX) socket.  }
type
  sockaddr_un = {packed} record
    sun_family: sa_family_t;
    sun_path: packed array[0..108-1] of Char;  { Path name.  }
  end;
  {$EXTERNALSYM sockaddr_un}
  TSockAddr_un = sockaddr_un;
  PSockAddr_un = ^TSockAddr_un;

{ Evaluate to actual length of the `sockaddr_un' structure.  }
function SUN_LEN(ptr: PSockAddr_un): Cardinal;
{$EXTERNALSYM SUN_LEN}


// Translated from netinet/in.h

{ Standard well-defined IP protocols.  }
const
  IPPROTO_IP = 0;               // Dummy protocol for TCP.
  {$EXTERNALSYM IPPROTO_IP}
  IPPROTO_HOPOPTS = 0;          // IPv6 Hop-by-Hop options.
  {$EXTERNALSYM IPPROTO_HOPOPTS}
  IPPROTO_ICMP = 1;             // Internet Control Message Protocol.
  {$EXTERNALSYM IPPROTO_ICMP}
  IPPROTO_IGMP = 2;             // Internet Group Management Protocol.
  {$EXTERNALSYM IPPROTO_IGMP}
  IPPROTO_IPIP = 4;             // IPIP tunnels (older KA9Q tunnels use 94).
  {$EXTERNALSYM IPPROTO_IPIP}
  IPPROTO_TCP = 6;              // Transmission Control Protocol.
  {$EXTERNALSYM IPPROTO_TCP}
  IPPROTO_EGP = 8;              // Exterior Gateway Protocol.
  {$EXTERNALSYM IPPROTO_EGP}
  IPPROTO_PUP = 12;             // PUP protocol.
  {$EXTERNALSYM IPPROTO_PUP}
  IPPROTO_UDP = 17;             // User Datagram Protocol.
  {$EXTERNALSYM IPPROTO_UDP}
  IPPROTO_IDP = 22;             // XNS IDP protocol.
  {$EXTERNALSYM IPPROTO_IDP}
  IPPROTO_TP = 29;              // SO Transport Protocol Class 4.
  {$EXTERNALSYM IPPROTO_TP}
  IPPROTO_IPV6 = 41;	        // IPv6 header.
  {$EXTERNALSYM IPPROTO_IPV6}
  IPPROTO_ROUTING = 43;	        // IPv6 routing header.
  {$EXTERNALSYM IPPROTO_ROUTING}
  IPPROTO_FRAGMENT = 44;        // IPv6 fragmentation header.
  {$EXTERNALSYM IPPROTO_FRAGMENT}
  IPPROTO_RSVP = 46;            // Reservation Protocol.
  {$EXTERNALSYM IPPROTO_RSVP}
  IPPROTO_GRE = 47;     	// General Routing Encapsulation.
  {$EXTERNALSYM IPPROTO_GRE}
  IPPROTO_ESP = 50;             // encapsulating security payload.
  {$EXTERNALSYM IPPROTO_ESP}
  IPPROTO_AH = 51;              // authentication header.
  {$EXTERNALSYM IPPROTO_AH}
  IPPROTO_ICMPV6 = 58;          // ICMPv6.
  {$EXTERNALSYM IPPROTO_ICMPV6}
  IPPROTO_NONE = 59;            // IPv6 no next header.
  {$EXTERNALSYM IPPROTO_NONE}
  IPPROTO_DSTOPTS = 60;         // IPv6 destination options.
  {$EXTERNALSYM IPPROTO_DSTOPTS}
  IPPROTO_MTP = 92;             // Multicast Transport Protocol.
  {$EXTERNALSYM IPPROTO_MTP}
  IPPROTO_ENCAP = 98;           // Encapsulation Header.
  {$EXTERNALSYM IPPROTO_ENCAP}
  IPPROTO_PIM = 103;            // Protocol Independent Multicast.
  {$EXTERNALSYM IPPROTO_PIM}
  IPPROTO_COMP = 108;           // Compression Header Protocol.
  {$EXTERNALSYM IPPROTO_COMP}
  IPPROTO_RAW = 255;            // Raw IP packets.
  {$EXTERNALSYM IPPROTO_RAW}
  IPPROTO_MAX = 256;
  {$EXTERNALSYM IPPROTO_MAX}


{ Type to represent a port.  }
type
  in_port_t = uint16_t;
  {$EXTERNALSYM in_port_t}

{ Standard well-known ports.  }
const
  IPPORT_ECHO    =   7;                      { Echo service.  }
  {$EXTERNALSYM IPPORT_ECHO}
  IPPORT_DISCARD =   9;                      { Discard transmissions service.  }
  {$EXTERNALSYM IPPORT_DISCARD}
  IPPORT_SYSTAT  =   11;                     { System status service.  }
  {$EXTERNALSYM IPPORT_SYSTAT}
  IPPORT_DAYTIME =   13;                     { Time of day service.  }
  {$EXTERNALSYM IPPORT_DAYTIME}
  IPPORT_NETSTAT =   15;                     { Network status service.  }
  {$EXTERNALSYM IPPORT_NETSTAT}
  IPPORT_FTP     =   21;                     { File Transfer Protocol.  }
  {$EXTERNALSYM IPPORT_FTP}
  IPPORT_TELNET  =   23;                     { Telnet protocol.  }
  {$EXTERNALSYM IPPORT_TELNET}
  IPPORT_SMTP    =   25;                     { Simple Mail Transfer Protocol.  }
  {$EXTERNALSYM IPPORT_SMTP}
  IPPORT_TIMESERVER  =  37;                  { Timeserver service.  }
  {$EXTERNALSYM IPPORT_TIMESERVER}
  IPPORT_NAMESERVER  =  42;                  { Domain Name Service.  }
  {$EXTERNALSYM IPPORT_NAMESERVER}
  IPPORT_WHOIS       =  43;                  { Internet Whois service.  }
  {$EXTERNALSYM IPPORT_WHOIS}
  IPPORT_MTP         =  57;
  {$EXTERNALSYM IPPORT_MTP}

  IPPORT_TFTP        =  69;                  { Trivial File Transfer Protocol.  }
  {$EXTERNALSYM IPPORT_TFTP}
  IPPORT_RJE         =  77;
  {$EXTERNALSYM IPPORT_RJE}
  IPPORT_FINGER      =  79;                  { Finger service.  }
  {$EXTERNALSYM IPPORT_FINGER}
  IPPORT_TTYLINK     =  87;
  {$EXTERNALSYM IPPORT_TTYLINK}
  IPPORT_SUPDUP      =  95;                  { SUPDUP protocol.  }
  {$EXTERNALSYM IPPORT_SUPDUP}

  IPPORT_EXECSERVER  =  512;                 { execd service.  }
  {$EXTERNALSYM IPPORT_EXECSERVER}
  IPPORT_LOGINSERVER =  513;                 { rlogind service.  }
  {$EXTERNALSYM IPPORT_LOGINSERVER}
  IPPORT_CMDSERVER   =  514;
  {$EXTERNALSYM IPPORT_CMDSERVER}
  IPPORT_EFSSERVER   =  520;
  {$EXTERNALSYM IPPORT_EFSSERVER}

  { UDP ports.  }

  IPPORT_BIFFUDP     =  512;
  {$EXTERNALSYM IPPORT_BIFFUDP}
  IPPORT_WHOSERVER   =  513;
  {$EXTERNALSYM IPPORT_WHOSERVER}
  IPPORT_ROUTESERVER =  520;
  {$EXTERNALSYM IPPORT_ROUTESERVER}

  { Ports less than this value are reserved for privileged processes.  }
  IPPORT_RESERVED    =  1024;
  {$EXTERNALSYM IPPORT_RESERVED}

  { Ports greater this value are reserved for (non-privileged) servers.  }
  IPPORT_USERRESERVED = 5000;
  {$EXTERNALSYM IPPORT_USERRESERVED}

type
  in_addr_t = uint32_t;
  {$EXTERNALSYM in_addr_t}

(*
  in_addr defined above already
*)

{ Definitions of the bits in an Internet address integer.

   On subnets, host and network parts are found according to
   the subnet mask, not these masks.  }

function IN_CLASSA(a: in_addr_t): Boolean;
{$EXTERNALSYM IN_CLASSA}

const
  IN_CLASSA_NET         = $ff000000;
  {$EXTERNALSYM IN_CLASSA_NET}
  IN_CLASSA_NSHIFT      = 24;
  {$EXTERNALSYM IN_CLASSA_NSHIFT}
  IN_CLASSA_HOST        = ($ffffffff and not IN_CLASSA_NET);
  {$EXTERNALSYM IN_CLASSA_HOST}
  IN_CLASSA_MAX         = 128;
  {$EXTERNALSYM IN_CLASSA_MAX}

function IN_CLASSB(a: in_addr_t): Boolean;
{$EXTERNALSYM IN_CLASSB}

const
  IN_CLASSB_NET         = $ffff0000;
  {$EXTERNALSYM IN_CLASSB_NET}
  IN_CLASSB_NSHIFT      = 16;
  {$EXTERNALSYM IN_CLASSB_NSHIFT}
  IN_CLASSB_HOST        = ($ffffffff and not IN_CLASSB_NET);
  {$EXTERNALSYM IN_CLASSB_HOST}
  IN_CLASSB_MAX         = 65536;
  {$EXTERNALSYM IN_CLASSB_MAX}

function IN_CLASSC(a: in_addr_t): Boolean;
{$EXTERNALSYM IN_CLASSC}

const
  IN_CLASSC_NET         = $ffffff00;
  {$EXTERNALSYM IN_CLASSC_NET}
  IN_CLASSC_NSHIFT      = 8;
  {$EXTERNALSYM IN_CLASSC_NSHIFT}
  IN_CLASSC_HOST        = ($ffffffff and not IN_CLASSC_NET);
  {$EXTERNALSYM IN_CLASSC_HOST}

function IN_CLASSD(a: in_addr_t): Boolean;
{$EXTERNALSYM IN_CLASSD}
function IN_MULTICAST(a: in_addr_t): Boolean;
{$EXTERNALSYM IN_MULTICAST}

function IN_EXPERIMENTAL(a: in_addr_t): Boolean;
{$EXTERNALSYM IN_EXPERIMENTAL}
function IN_BADCLASS(a: in_addr_t): Boolean;
{$EXTERNALSYM IN_BADCLASS}

const
(* Redeclared from bits/socket.h
{ Address to accept any incoming messages.  }
  INADDR_ANY = in_addr_t($00000000);
  {$EXTERNALSYM INADDR_ANY}
{ Address to send to all hosts.  }
  INADDR_BROADCAST = in_addr_t($ffffffff);
  {$EXTERNALSYM INADDR_BROADCAST}
{ Address indicating an error return.  }
  INADDR_NONE = in_addr_t($ffffffff);
  {$EXTERNALSYM INADDR_NONE}
*)

{ Network number for local host loopback.  }
  IN_LOOPBACKNET = 127;
  {$EXTERNALSYM IN_LOOPBACKNET}
{ Address to loopback in software to local host.  }
  INADDR_LOOPBACK = in_addr_t($7f000001); { Inet 127.0.0.1.  }
  {$EXTERNALSYM INADDR_LOOPBACK}

{ Defines for Multicast INADDR.  }
  INADDR_UNSPEC_GROUP = in_addr_t($e0000000); { 224.0.0.0 }
  {$EXTERNALSYM INADDR_UNSPEC_GROUP}
  INADDR_ALLHOSTS_GROUP = in_addr_t($e0000001); { 224.0.0.1 }
  {$EXTERNALSYM INADDR_ALLHOSTS_GROUP}
  INADDR_ALLRTRS_GROUP = in_addr_t($0000002); { 224.0.0.2 }
  {$EXTERNALSYM INADDR_ALLRTRS_GROUP}
  INADDR_MAX_LOCAL_GROUP = in_addr_t($e00000ff); { 224.0.0.255 }
  {$EXTERNALSYM INADDR_MAX_LOCAL_GROUP}


{ IPv6 address }
type
  in6_addr = {packed} record
    case Integer of
      0: (s6_addr: packed array [0..16-1] of __uint8_t);
      1: (s6_addr16: packed array [0..8-1] of uint16_t);
      2: (s6_addr32: packed array [0..4-1] of uint32_t);
    end;
  {$EXTERNALSYM in6_addr}

const
  INET_ADDRSTRLEN = 16;
  {$EXTERNALSYM INET_ADDRSTRLEN}
  INET6_ADDRSTRLEN = 46;
  {$EXTERNALSYM INET6_ADDRSTRLEN}


{ Structure describing an Internet socket address.  }
(* Redeclared from socket.h
  sockaddr_in = {packed} record
*)

{ Ditto, for IPv6.  }
type
  sockaddr_in6 = {packed} record
    sin6_family: sa_family_t;
    sin6_port: in_port_t;         { Transport layer port # }
    sin6_flowinfo: uint32_t;      { IPv6 flow information }
    sin6_addr: in6_addr;          { IPv6 address }
    sin6_scope_id: uint32_t;      { IPv6 scope-id }
  end;
  {$EXTERNALSYM sockaddr_in6}

{ IPv6 multicast request.  }
  ipv6_mreq = {packed} record
    { IPv6 multicast address of group }
    ipv6mr_multiaddr: in6_addr;

    { local interface }
    ipv6mr_interface: Cardinal;
  end;
  {$EXTERNALSYM ipv6_mreq}

{ Get system-specific definitions.  }

// Translated from bits/in.h, inlined in netinet/in.h

{ Options for use with `getsockopt' and `setsockopt' at the IP level.
   The first word in the comment at the right is the data type used;
   "bool" means a boolean value stored in an `int'.  }
const
  IP_TOS             = 1;  { int; IP type of service and precedence.  }
  {$EXTERNALSYM IP_TOS}
  IP_TTL             = 2;  { int; IP time to live.  }
  {$EXTERNALSYM IP_TTL}
  IP_HDRINCL         = 3;  { int; Header is included with data.  }
  {$EXTERNALSYM IP_HDRINCL}
  IP_OPTIONS         = 4;  { ip_opts; IP per-packet options.  }
  {$EXTERNALSYM IP_OPTIONS}
  IP_ROUTER_ALERT    = 5;  { bool }
  {$EXTERNALSYM IP_ROUTER_ALERT}
  IP_RECVOPTS        = 6;  { bool }
  {$EXTERNALSYM IP_RECVOPTS}
  IP_RETOPTS         = 7;  { bool }
  {$EXTERNALSYM IP_RETOPTS}
  IP_PKTINFO         = 8;  { bool }
  {$EXTERNALSYM IP_PKTINFO}
  IP_PKTOPTIONS      = 9;
  {$EXTERNALSYM IP_PKTOPTIONS}
  IP_PMTUDISC        = 10; { obsolete name? }
  {$EXTERNALSYM IP_PMTUDISC}
  IP_MTU_DISCOVER    = 10; { int; see below }
  {$EXTERNALSYM IP_MTU_DISCOVER}
  IP_RECVERR         = 11; { bool }
  {$EXTERNALSYM IP_RECVERR}
  IP_RECVTTL         = 12; { bool }
  {$EXTERNALSYM IP_RECVTTL}
  IP_RECVTOS         = 13; { bool }
  {$EXTERNALSYM IP_RECVTOS}
  IP_MULTICAST_IF    = 32; { in_addr; set/get IP multicast i/f }
  {$EXTERNALSYM IP_MULTICAST_IF}
  IP_MULTICAST_TTL   = 33; { u_char; set/get IP multicast ttl }
  {$EXTERNALSYM IP_MULTICAST_TTL}
  IP_MULTICAST_LOOP  = 34; { i_char; set/get IP multicast loopback }
  {$EXTERNALSYM IP_MULTICAST_LOOP}
  IP_ADD_MEMBERSHIP  = 35; { ip_mreq; add an IP group membership }
  {$EXTERNALSYM IP_ADD_MEMBERSHIP}
  IP_DROP_MEMBERSHIP = 36; { ip_mreq; drop an IP group membership }
  {$EXTERNALSYM IP_DROP_MEMBERSHIP}

{ For BSD compatibility.  }
  IP_RECVRETOPTS     = IP_RETOPTS;
  {$EXTERNALSYM IP_RECVRETOPTS}

{ IP_MTU_DISCOVER arguments.  }
  IP_PMTUDISC_DONT = 0; { Never send DF frames.  }
  {$EXTERNALSYM IP_PMTUDISC_DONT}
  IP_PMTUDISC_WANT = 1; { Use per route hints.  }
  {$EXTERNALSYM IP_PMTUDISC_WANT}
  IP_PMTUDISC_DO   = 2; { Always DF.  }
  {$EXTERNALSYM IP_PMTUDISC_DO}

{ To select the IP level.  }
  SOL_IP = 0;
  {$EXTERNALSYM SOL_IP}

  IP_DEFAULT_MULTICAST_TTL        = 1;
  {$EXTERNALSYM IP_DEFAULT_MULTICAST_TTL}
  IP_DEFAULT_MULTICAST_LOOP       = 1;
  {$EXTERNALSYM IP_DEFAULT_MULTICAST_LOOP}
  IP_MAX_MEMBERSHIPS              = 20;
  {$EXTERNALSYM IP_MAX_MEMBERSHIPS}

{ Structure used to describe IP options for IP_OPTIONS. The `ip_dst'
   field is used for the first-hop gateway when using a source route
   (this gets put into the header proper).  }
type
  ip_opts = {packed} record
    ip_dst: in_addr;	                       { First hop; zero without source route.  }
    ip_opts: packed array [0..40-1] of Byte;   { Actually variable in size.  }
  end;
  {$EXTERNALSYM ip_opts}

{ Structure used for IP_ADD_MEMBERSHIP and IP_DROP_MEMBERSHIP. }
  ip_mreq = {packed} record
    imr_multiaddr: in_addr;     { IP multicast address of group }
    imr_interface: in_addr;     { local IP address of interface }
  end;
  {$EXTERNALSYM ip_mreq}

{ As above but including interface specification by index.  }
  ip_mreqn = {packed} record
    imr_multiaddr: in_addr;         { IP multicast address of group }
    imr_address: in_addr;           { local IP address of interface }
    imr_ifindex: Integer;       { Interface index }
  end;
  {$EXTERNALSYM ip_mreqn}

{ Structure used for IP_PKTINFO.  }
  in_pktinfo = {packed} record
    ipi_ifindex: Integer;               { Interface index  }
    ipi_spec_dst: in_addr;              { Routing destination address  }
    ipi_addr: in_addr;                  { Header destination address  }
  end;
  {$EXTERNALSYM in_pktinfo}

{ Options for use with `getsockopt' and `setsockopt' at the IPv6 level.
   The first word in the comment at the right is the data type used;
   "bool" means a boolean value stored in an `int'.  }
const
  IPV6_ADDRFORM         = 1;
  {$EXTERNALSYM IPV6_ADDRFORM}
  IPV6_PKTINFO          = 2;
  {$EXTERNALSYM IPV6_PKTINFO}
  IPV6_HOPOPTS          = 3;
  {$EXTERNALSYM IPV6_HOPOPTS}
  IPV6_DSTOPTS          = 4;
  {$EXTERNALSYM IPV6_DSTOPTS}
  IPV6_RTHDR            = 5;
  {$EXTERNALSYM IPV6_RTHDR}
  IPV6_PKTOPTIONS       = 6;
  {$EXTERNALSYM IPV6_PKTOPTIONS}
  IPV6_CHECKSUM         = 7;
  {$EXTERNALSYM IPV6_CHECKSUM}
  IPV6_HOPLIMIT         = 8;
  {$EXTERNALSYM IPV6_HOPLIMIT}
  IPV6_NEXTHOP          = 9;
  {$EXTERNALSYM IPV6_NEXTHOP}
  IPV6_AUTHHDR          = 10;
  {$EXTERNALSYM IPV6_AUTHHDR}
  IPV6_UNICAST_HOPS     = 16;
  {$EXTERNALSYM IPV6_UNICAST_HOPS}
  IPV6_MULTICAST_IF     = 17;
  {$EXTERNALSYM IPV6_MULTICAST_IF}
  IPV6_MULTICAST_HOPS   = 18;
  {$EXTERNALSYM IPV6_MULTICAST_HOPS}
  IPV6_MULTICAST_LOOP   = 19;
  {$EXTERNALSYM IPV6_MULTICAST_LOOP}
  IPV6_JOIN_GROUP       = 20;
  {$EXTERNALSYM IPV6_JOIN_GROUP}
  IPV6_LEAVE_GROUP      = 21;
  {$EXTERNALSYM IPV6_LEAVE_GROUP}
  IPV6_ROUTER_ALERT     = 22;
  {$EXTERNALSYM IPV6_ROUTER_ALERT}
  IPV6_MTU_DISCOVER     = 23;
  {$EXTERNALSYM IPV6_MTU_DISCOVER}
  IPV6_MTU              = 24;
  {$EXTERNALSYM IPV6_MTU}
  IPV6_RECVERR          = 25;
  {$EXTERNALSYM IPV6_RECVERR}

(* IPV6_RXSRCRT completely undefined. Bug in glibc 2.2?
  SCM_SRCRT             = IPV6_RXSRCRT;
  {$EXTERNALSYM SCM_SRCRT}
*)

{ Obsolete synonyms for the above.  }
  IPV6_RXHOPOPTS        = IPV6_HOPOPTS;
  {$EXTERNALSYM IPV6_RXHOPOPTS}
  IPV6_RXDSTOPTS        = IPV6_DSTOPTS;
  {$EXTERNALSYM IPV6_RXDSTOPTS}
  IPV6_ADD_MEMBERSHIP   = IPV6_JOIN_GROUP;
  {$EXTERNALSYM IPV6_ADD_MEMBERSHIP}
  IPV6_DROP_MEMBERSHIP  = IPV6_LEAVE_GROUP;
  {$EXTERNALSYM IPV6_DROP_MEMBERSHIP}


{ IPV6_MTU_DISCOVER values.  }
  IPV6_PMTUDISC_DONT    = 0;      { Never send DF frames.  }
  {$EXTERNALSYM IPV6_PMTUDISC_DONT}
  IPV6_PMTUDISC_WANT    = 1;      { Use per route hints.  }
  {$EXTERNALSYM IPV6_PMTUDISC_WANT}
  IPV6_PMTUDISC_DO      = 2;      { Always DF.  }
  {$EXTERNALSYM IPV6_PMTUDISC_DO}

{ Socket level values for IPv6.  }
  SOL_IPV6        = 41;
  {$EXTERNALSYM SOL_IPV6}
  SOL_ICMPV6      = 58;
  {$EXTERNALSYM SOL_ICMPV6}

{ Routing header options for IPv6.  }
  IPV6_RTHDR_LOOSE      = 0;      { Hop doesn't need to be neighbour. }
  {$EXTERNALSYM IPV6_RTHDR_LOOSE}
  IPV6_RTHDR_STRICT     = 1;      { Hop must be a neighbour.  }
  {$EXTERNALSYM IPV6_RTHDR_STRICT}

  IPV6_RTHDR_TYPE_0     = 0;      { IPv6 Routing header type 0.  }
  {$EXTERNALSYM IPV6_RTHDR_TYPE_0}

{ Functions to convert between host and network byte order.

   Please note that these functions normally take `unsigned long int' or
   `unsigned short int' values as arguments and also return them.  But
   this was a short-sighted decision since on different systems the types
   may have different representations but the values are always the same.  }

function ntohl(__netlong: uint32_t): uint32_t; cdecl;
{$EXTERNALSYM ntohl}
function ntohs(__netshort: uint16_t): uint16_t; cdecl;
{$EXTERNALSYM ntohs}
function htonl(__hostlong: uint32_t): uint32_t; cdecl;
{$EXTERNALSYM htonl}
function htons(__hostshort: uint16_t): uint16_t; cdecl;
{$EXTERNALSYM htons}

function IN6_IS_ADDR_UNSPECIFIED(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_UNSPECIFIED}

function IN6_IS_ADDR_LOOPBACK(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_LOOPBACK}

function IN6_IS_ADDR_MULTICAST(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_MULTICAST}

function IN6_IS_ADDR_LINKLOCAL(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_LINKLOCAL}

function IN6_IS_ADDR_SITELOCAL(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_SITELOCAL}

function IN6_IS_ADDR_V4MAPPED(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_V4MAPPED}

function IN6_IS_ADDR_V4COMPAT(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_V4COMPAT}

function IN6_ARE_ADDR_EQUAL(const a, b: in6_addr): Boolean;
{$EXTERNALSYM IN6_ARE_ADDR_EQUAL}

{ Bind socket to a privileged IP port.  }
function bindresvport(__sockfd: TSocket; __sock_in: sockaddr_in): Integer; cdecl;
{$EXTERNALSYM bindresvport}

(* Not defined in binary
{ The IPv6 version of this function.  }
function bindresvport6(__sockfd: TSocket; var __sock_in: sockaddr_in6): Integer; cdecl;
{$EXTERNALSYM bindresvport6}
*)

function IN6_IS_ADDR_MC_NODELOCAL(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_MC_NODELOCAL}

function IN6_IS_ADDR_MC_LINKLOCAL(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_MC_LINKLOCAL}

function IN6_IS_ADDR_MC_SITELOCAL(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_MC_SITELOCAL}

function IN6_IS_ADDR_MC_ORGLOCAL(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_MC_ORGLOCAL}

function IN6_IS_ADDR_MC_GLOBAL(const a: in6_addr): Boolean;
{$EXTERNALSYM IN6_IS_ADDR_MC_GLOBAL}

{ IPv6 packet information.  }
type
  in6_pktinfo = {packed} record
    ipi6_addr: in6_addr;         { src/dst IPv6 address }
    ipi6_ifindex: Cardinal;      { send/recv interface index }
  end;
  {$EXTERNALSYM in6_pktinfo}


// Translated from arpa/inet.h
                                              
{ Convert Internet host address from numbers-and-dots notation in CP
   into binary data in network byte order.  }
function inet_addr(__cp: PChar): in_addr_t; cdecl;
{$EXTERNALSYM inet_addr}

{ Return the local host address part of the Internet address in IN.  }
function inet_lnaof(__in: in_addr): in_addr_t; cdecl;
{$EXTERNALSYM inet_lnaof}

{ Make Internet host address in network byte order by combining the
   network number NET with the local address HOST.  }
(*
  Verbatim translation of C prototype would be
    function inet_makeaddr(__net: in_addr_t; __host: in_addr_t): in_addr; cdecl;
  but since SizeOf(in_addr) = 4, dcc will return in_addr in eax,
  despite it being a record.
  The C implementation ignores the size of the returned record and
  always passes a pointer to the record. The (modified) declaration
  takes this into account.
*)
procedure inet_makeaddr(var Result: in_addr; __net: in_addr_t; __host: in_addr_t); cdecl;
{$EXTERNALSYM inet_makeaddr}

{ Return network number part of the Internet address IN.  }
function inet_netof(__in: in_addr): in_addr_t; cdecl;
{$EXTERNALSYM inet_netof}

{ Extract the network number in network byte order from the address
   in numbers-and-dots natation starting at CP.  }
function inet_network(__cp: PChar): in_addr_t; cdecl;
{$EXTERNALSYM inet_network}

{ Convert Internet number in IN to ASCII representation.  The return value
   is a pointer to an internal array containing the string.  }
function inet_ntoa(__in: in_addr): PChar; cdecl;
{$EXTERNALSYM inet_ntoa}

{ Convert from presentation format of an Internet number in buffer
   starting at CP to the binary network format and store result for
   interface type AF in buffer starting at BUF.  }
function inet_pton(__af: Integer; __cp: PChar; __buf: Pointer): Integer; cdecl;
{$EXTERNALSYM inet_pton}

{ Convert a Internet address in binary network format for interface
   type AF in buffer starting at CP to presentation form and place
   result in buffer of length LEN astarting at BUF.  }
function inet_ntop(__af: Integer; __cp: PChar; __buf: Pointer; Len: socklen_t): PChar; cdecl;
{$EXTERNALSYM inet_ntop}


{ The following functions are not part of XNS 5.2.  }

{ Convert Internet host address from numbers-and-dots notation in CP
   into binary data and store the result in the structure INP.  }
function inet_aton(__cp: PChar; var __inp: in_addr): in_addr_t; cdecl;
{$EXTERNALSYM inet_aton}

{ Format a network number NET into presentation format and place result
   in buffer starting at BUF with length of LEN bytes.  }
function inet_neta(__net: in_addr_t; __buf: PChar; __len: size_t): PChar; cdecl;
{$EXTERNALSYM inet_neta}

{ Convert network number for interface type AF in buffer starting at
   CP to presentation format.  The result will specifiy BITS bits of
   the number.  }
function inet_net_ntop(__af: Integer; __cp: Pointer; __bits: Integer;
  __buf: PChar; __len: size_t): PChar; cdecl;
{$EXTERNALSYM inet_net_ntop}

{ Convert network number for interface type AF from presentation in
   buffer starting at CP to network format and store result int
   buffer starting at BUF of size LEN.  }
function inet_net_pton(__af: Integer; __cp: PChar; __buf: Pointer; __len: size_t): Integer; cdecl;
{$EXTERNALSYM inet_net_pton}

{ Convert ASCII representation in hexadecimal form of the Internet
   address to binary form and place result in buffer of length LEN
   starting at BUF.  }
function inet_nsap_addr(__cp: PChar; __buf: PByte; __len: Integer): Cardinal; cdecl;
{$EXTERNALSYM inet_nsap_addr}

{ Convert internet address in binary form in LEN bytes starting at CP
   a presentation form and place result in BUF.  }
function inet_nsap_ntoa(__len: Integer; __cp: PByte; __buf: PChar): PChar; cdecl;
{$EXTERNALSYM inet_nsap_ntoa}


// Translated from bits/netdb.h

{ Description of data base entry for a single network.  NOTE: here a
   poor assumption is made.  The network number is expected to fit
   into an unsigned long int variable.  }
type
  netent = {packed} record
    n_name: PChar;                  { Official name of network.  }
    n_aliases: PPChar;              { Alias list.  }
    n_addrtype: Integer;            { Net address type.  }
    n_net: uint32_t;                { Network number.  }
  end;
  {$EXTERNALSYM netent}
  TNetEnt = netent;
  PNetEnt = ^TNetEnt;

// Translated from netdb.h

{ Absolute file name for network data base files.  }
const
  _PATH_HEQUIV          = '/etc/hosts.equiv';
  {$EXTERNALSYM _PATH_HEQUIV}
  _PATH_HOSTS           = '/etc/hosts';
  {$EXTERNALSYM _PATH_HOSTS}
  _PATH_NETWORKS        = '/etc/networks';
  {$EXTERNALSYM _PATH_NETWORKS}
  _PATH_NSSWITCH_CONF   = '/etc/nsswitch.conf';
  {$EXTERNALSYM _PATH_NSSWITCH_CONF}
  _PATH_PROTOCOLS       = '/etc/protocols';
  {$EXTERNALSYM _PATH_PROTOCOLS}
  _PATH_SERVICES        = '/etc/services';
  {$EXTERNALSYM _PATH_SERVICES}

function h_errno: Integer;
{$EXTERNALSYM h_errno}

{ Function to get address of global `h_errno' variable.  }
function __h_errno_location(): PInteger; cdecl;
{$EXTERNALSYM __h_errno_location}

function __set_h_errno(__err: Integer): Integer;
{$EXTERNALSYM __set_h_errno}

{ Possible values left in `h_errno'.  }
const
  NETDB_INTERNAL        = -1;      { See errno.  }
  {$EXTERNALSYM NETDB_INTERNAL}
  NETDB_SUCCESS         = 0;       { No problem.  }
  {$EXTERNALSYM NETDB_SUCCESS}
  HOST_NOT_FOUND        = 1;       { Authoritative Answer Host not found.  }
  {$EXTERNALSYM HOST_NOT_FOUND}
  TRY_AGAIN             = 2;       { Non-Authoritative Host not found, or SERVERFAIL.  }
  {$EXTERNALSYM TRY_AGAIN}
  NO_RECOVERY           = 3;       { Non recoverable errors, FORMERR, REFUSED, NOTIMP.  }
  {$EXTERNALSYM NO_RECOVERY}
  NO_DATA               = 4;       { Valid name, no data record of requested type.  }
  {$EXTERNALSYM NO_DATA}
  NO_ADDRESS            = NO_DATA; { No address, look for MX record.  }
  {$EXTERNALSYM NO_ADDRESS}

{ Scope delimiter for getaddrinfo(), getnameinfo().  }
  SCOPE_DELIMITER       = '%';
  {$EXTERNALSYM SCOPE_DELIMITER}

{ Print error indicated by `h_errno' variable on standard error.  STR
   if non-null is printed before the error string.  }
procedure herror(__str: PChar); cdecl;
{$EXTERNALSYM herror}

{ Return string associated with error ERR_NUM.  }
function hstrerror(__err_num: Integer): PChar; cdecl;
{$EXTERNALSYM hstrerror}


{ Description of data base entry for a single host.  }
type
  hostent = {packed} record
    h_name: PChar;                  { Official name of host.  }
    h_aliases: PPChar;              { Alias list.  }
    h_addrtype: Integer;            { Host address type.  }
    h_length: socklen_t;            { Length of address.  }
    case Byte of
      0: (h_addr_list: PPChar);     { List of addresses from name server.  }
      1: (h_addr: PPChar);          { Address, for backward compatibility.  }
  end;
  {$EXTERNALSYM hostent}
  THostEnt = hostent;
  PHostEnt = ^THostEnt;


{ Open host data base files and mark them as staying open even after
   a later search if STAY_OPEN is non-zero.  }
procedure sethostent(__stay_open: Integer); cdecl;
{$EXTERNALSYM sethostent}

{ Close host data base files and clear `stay open' flag.  }
procedure endhostent(); cdecl;
{$EXTERNALSYM endhostent}

{ Get next entry from host data base file.  Open data base if
   necessary.  }
function gethostent(): PHostEnt; cdecl;
{$EXTERNALSYM gethostent}

{ Return entry from host data base which address match ADDR with
   length LEN and type TYPE.  }
function gethostbyaddr(__addr: Pointer;  __len: __socklen_t; __type: Integer): PHostEnt; cdecl;
{$EXTERNALSYM gethostbyaddr}

{ Return entry from host data base for host with NAME.  }
function gethostbyname(__name: PChar): PHostEnt; cdecl;
{$EXTERNALSYM gethostbyname}

{ Return entry from host data base for host with NAME.  AF must be
   set to the address type which is `AF_INET' for IPv4 or `AF_INET6'
   for IPv6.  }
function gethostbyname2(__name: PChar; __af: Integer): PHostEnt; cdecl;
{$EXTERNALSYM gethostbyname2}

{ Reentrant versions of the functions above.  The additional
   arguments specify a buffer of BUFLEN starting at BUF.  The last
   argument is a pointer to a variable which gets the value which
   would be stored in the global variable `herrno' by the
   non-reentrant functions.  }
function gethostent_r(__result_buf: PHostEnt; __buf: PChar; __buflen: size_t;
  var __result: PHostEnt; var __h_errno: Integer): Integer; cdecl;
{$EXTERNALSYM gethostent_r}

function gethostbyaddr_r(__addr: Pointer; __len: __socklen_t; __type: Integer;
  __result_buf: PHostEnt; __buf: PChar; __buflen: size_t;
  var __result: PHostEnt; var __h_errno: Integer): Integer; cdecl;
{$EXTERNALSYM gethostbyaddr_r}

function gethostbyname_r(__name: PChar; __result_buf: PHostEnt;  __buf: PChar;
  __buflen: size_t; var __result: PHostEnt; var __h_errno: Integer): Integer; cdecl;
{$EXTERNALSYM gethostbyname_r}

function gethostbyname2_r(__name: PChar; __af: Integer; __result_buf: PHostEnt;  __buf: PChar;
  __buflen: size_t; var __result: PHostEnt; var __h_errno: Integer): Integer; cdecl;
{$EXTERNALSYM gethostbyname2_r}


{ Open network data base files and mark them as staying open even
   after a later search if STAY_OPEN is non-zero.  }
procedure setnetent(__stay_open: Integer); cdecl;
{$EXTERNALSYM setnetent}

{ Close network data base files and clear `stay open' flag.  }
procedure endnetent(); cdecl;
{$EXTERNALSYM endnetent}

{ Get next entry from network data base file.  Open data base if
   necessary.  }
function getnetent(): PNetEnt; cdecl;
{$EXTERNALSYM getnetent}

{ Return entry from network data base which address match NET and
   type TYPE.  }
function getnetbyaddr(__net: uint32_t; __type: Integer): PNetEnt; cdecl;
{$EXTERNALSYM getnetbyaddr}

{ Return entry from network data base for network with NAME.  }
function getnetbyname(__name: PChar): PNetEnt; cdecl;
{$EXTERNALSYM getnetbyname}

{ Reentrant versions of the functions above.  The additional
   arguments specify a buffer of BUFLEN starting at BUF.  The last
   argument is a pointer to a variable which gets the value which
   would be stored in the global variable `herrno' by the
   non-reentrant functions.  }
function getnetent_r(__result_buf: PNetEnt; __buf: PChar; __buflen: size_t;
  var __result: PNetEnt; var __h_errno: Integer): Integer; cdecl;
{$EXTERNALSYM getnetent_r}

function getnetbyaddr_r(__net: uint32_t; __type: Integer;
  __result_buf: PNetEnt; __buf: PChar; __buflen: size_t;
  var __result: PNetEnt; var __h_errno: Integer): Integer; cdecl;
{$EXTERNALSYM getnetbyaddr_r}

function getnetbyname_r(__name: PChar;
  __result_buf: PNetEnt; __buf: PChar; __buflen: size_t;
  var __result: PNetEnt; var __h_errno: Integer): Integer; cdecl;
{$EXTERNALSYM getnetbyname_r}


{ Description of data base entry for a single service.  }
type
  servent = {packed} record
    s_name: PChar;
    s_aliases: PPChar;
    s_port: Integer;
    s_proto: PChar;
  end;
  {$EXTERNALSYM servent}
  TServEnt = servent;
  PServEnt = ^TServEnt;

{ Open service data base files and mark them as staying open even
   after a later search if STAY_OPEN is non-zero.  }
procedure setservent(__stay_open: Integer); cdecl;
{$EXTERNALSYM setservent}

{ Close service data base files and clear `stay open' flag.  }
procedure endservent(); cdecl;
{$EXTERNALSYM endservent}

{ Get next entry from service data base file.  Open data base if
   necessary.  }
function getservent(): PServEnt; cdecl;
{$EXTERNALSYM getservent}

{ Return entry from network data base for network with NAME and
   protocol PROTO.  }
function getservbyname(__name: PChar; __proto: PChar): PServEnt; cdecl;
{$EXTERNALSYM getservbyname}

{ Return entry from service data base which matches port PORT and
   protocol PROTO.  }
function getservbyport(__port: Integer; __proto: PChar): PServEnt; cdecl;
{$EXTERNALSYM getservbyport}


{ Reentrant versions of the functions above.  The additional
   arguments specify a buffer of BUFLEN starting at BUF.  }
function getservent_r(__result_buf: PServEnt; __buf: PChar; __buflen: size_t;
  var __result: PServEnt): Integer; cdecl;
{$EXTERNALSYM getservent_r}

function getservbyname_r(__name: PChar; __proto: PChar;
  __result_buf: PServEnt; __buf: PChar; __buflen: size_t;
  var __result: PServEnt): Integer; cdecl;
{$EXTERNALSYM getservbyname_r}

function getservbyport_r(__port: Integer; __proto: PChar;
  __result_buf: PServEnt; __buf: PChar; __buflen: size_t;
  var __result: PServEnt): Integer; cdecl;
{$EXTERNALSYM getservbyport_r}


{ Description of data base entry for a single service.  }
type
  protoent = {packed} record
    p_name: PChar;
    p_aliases: ^PChar;
    p_proto: u_short;
  end;
  {$EXTERNALSYM protoent}
  TProtoEnt = protoent;
  PProtoEnt = ^TProtoEnt;

{ Open protocol data base files and mark them as staying open even
   after a later search if STAY_OPEN is non-zero.  }
procedure setprotoent(__stay_open: Integer); cdecl;
{$EXTERNALSYM setprotoent}

{ Close protocol data base files and clear `stay open' flag.  }
procedure endprotoent(); cdecl;
{$EXTERNALSYM endprotoent}

{ Get next entry from protocol data base file.  Open data base if
   necessary.  }
function getprotoent(): PProtoEnt; cdecl;
{$EXTERNALSYM getprotoent}

{ Return entry from protocol data base for network with NAME.  }
function getprotobyname(__name: PChar): PProtoEnt; cdecl;
{$EXTERNALSYM getprotobyname}

{ Return entry from protocol data base which number is PROTO.  }
function getprotobynumber(__proto: Integer): PProtoEnt; cdecl;
{$EXTERNALSYM getprotobynumber}


{ Reentrant versions of the functions above.  The additional
   arguments specify a buffer of BUFLEN starting at BUF.  }
function getprotoent_r(__result_buf: PProtoEnt; __buf: PChar; __buflen: size_t;
  var __result: PProtoEnt): Integer; cdecl;
{$EXTERNALSYM getprotoent_r}

function getprotobyname_r(__name: PChar; __result_buf: PProtoEnt; __buf: PChar;
  __buflen: size_t; var __result: PProtoEnt): Integer; cdecl;
{$EXTERNALSYM getprotobyname_r}

function getprotobynumber_r(__proto: Integer; __result_buf: PProtoEnt; __buf: PChar;
  __buflen: size_t; var __result: PProtoEnt): Integer; cdecl;
{$EXTERNALSYM getprotobynumber_r}


{ Establish network group NETGROUP for enumeration.  }
function setnetgrent(__netgroup: PChar): Integer; cdecl;
{$EXTERNALSYM setnetgrent}

{ Free all space allocated by previous `setnetgrent' call.  }
procedure endnetgrent(); cdecl;
{$EXTERNALSYM endnetgrent}

{ Get next member of netgroup established by last `setnetgrent' call
   and return pointers to elements in HOSTP, USERP, and DOMAINP.  }
function getnetgrent(var __hostp, __userp, __domainp: PChar): Integer; cdecl;
{$EXTERNALSYM getnetgrent}

{ Test whether NETGROUP contains the triple (HOST,USER,DOMAIN).  }
function innetgr(__netgroup, __host, __user, domain: PChar): Integer; cdecl;
{$EXTERNALSYM innetgr}

{ Reentrant version of `getnetgrent' where result is placed in BUFFER.  }
function getnetgrent_r(var __hostp, __userp, __domainp: PChar;
  __buffer: PChar; __buflen: size_t): Integer; cdecl;
{$EXTERNALSYM getnetgrent_r}

{ Call `rshd' at port RPORT on remote machine *AHOST to execute CMD.
   The local user is LOCUSER, on the remote machine the command is
   executed as REMUSER.  In *FD2P the descriptor to the socket for the
   connection is returned.  The caller must have the right to use a
   reserved port.  When the function returns *AHOST contains the
   official host name.  }
function rcmd(__ahost: PPChar; __rport: Word; __locuser, __remuser: PChar;
  __cmd: PChar; var __fd2p: TSocket): Integer; cdecl;
{$EXTERNALSYM rcmd}

{ This is the equivalent function where the protocol can be selected
   and which therefore can be used for IPv6.  }
function rcmd_af(__ahost: PPChar; __rport: Word; __locuser, __remuser: PChar;
  __cmd: PChar; var __fd2p: TSocket; __af: sa_family_t): Integer; cdecl;
{$EXTERNALSYM rcmd_af}

{ Call `rexecd' at port RPORT on remote machine *AHOST to execute
   CMD.  The process runs at the remote machine using the ID of user
   NAME whose cleartext password is PASSWD.  In *FD2P the descriptor
   to the socket for the connection is returned.  When the function
   returns *AHOST contains the official host name.  }
function rexec(__ahost: PPChar; __rport: Integer;
  __name, __pass, __cmd: PChar; var __fd2p: TSocket): Integer; cdecl;
{$EXTERNALSYM rexec}

{ This is the equivalent function where the protocol can be selected
   and which therefore can be used for IPv6.  }
function rexec_af(__ahost: PPChar; __rport: Integer;
  __name, __pass, __cmd: PChar; var __fd2p: TSocket; __af: sa_family_t): Integer; cdecl;
{$EXTERNALSYM rexec_af}

{ Check whether user REMUSER on system RHOST is allowed to login as LOCUSER.
   If SUSER is not zero the user tries to become superuser.  Return 0 if
   it is possible.  }
function ruserok(__rhost: PChar; __suser: Integer; __remuser, __locuser: PChar): Integer; cdecl;
{$EXTERNALSYM ruserok}

{ This is the equivalent function where the protocol can be selected
   and which therefore can be used for IPv6.  }
function ruserok_af(__rhost: PChar; __suser: Integer; __remuser, __locuser: PChar;
  __af: sa_family_t): Integer; cdecl;
{$EXTERNALSYM ruserok_af}

{ Try to allocate reserved port, returning a descriptor for a socket opened
   at this port or -1 if unsuccessful.  The search for an available port
   will start at ALPORT and continues with lower numbers.  }
function rresvport(var __alport: Integer): Integer; cdecl;
{$EXTERNALSYM rresvport}

{ This is the equivalent function where the protocol can be selected
   and which therefore can be used for IPv6.  }
function rresvport_af(var __alport: Integer; __af: sa_family_t): Integer; cdecl;
{$EXTERNALSYM rresvport_af}



{ Extension from POSIX.1g.  }

{ Structure to contain information about address of a service provider.  }
type
  PAddressInfo = ^TAddressInfo;
  addrinfo = {packed} record
    ai_flags: Integer;                  { Input flags.  }
    ai_family: Integer;                 { Protocol family for socket.  }
    ai_socktype: Integer;               { Socket type.  }
    ai_protocol: Integer;               { Protocol for socket.  }
    ai_addrlen: socklen_t;              { Length of socket address.  }
    ai_addr: PSockAddr;                 { Socket address for socket.  }
    ai_canonname: PChar;                { Canonical name for service location.  }
    ai_next: PAddressInfo;              { Pointer to next in list.  }
  end;
  {$EXTERNALSYM addrinfo}
  TAddressInfo = addrinfo;


const
{ Possible values for `ai_flags' field in `addrinfo' structure.  }
  AI_PASSIVE      = $0001;  { Socket address is intended for `bind'.  }
  {$EXTERNALSYM AI_PASSIVE}
  AI_CANONNAME    = $0002;  { Request for canonical name.  }
  {$EXTERNALSYM AI_CANONNAME}
  AI_NUMERICHOST  = $0004;  { Don't use name resolution.  }
  {$EXTERNALSYM AI_NUMERICHOST}

{ Error values for `getaddrinfo' function.  }
  EAI_BADFLAGS    = -1;   { Invalid value for `ai_flags' field.  }
  {$EXTERNALSYM EAI_BADFLAGS}
  EAI_NONAME      = -2;   { NAME or SERVICE is unknown.  }
  {$EXTERNALSYM EAI_NONAME}
  EAI_AGAIN       = -3;   { Temporary failure in name resolution.  }
  {$EXTERNALSYM EAI_AGAIN}
  EAI_FAIL        = -4;   { Non-recoverable failure in name res.  }
  {$EXTERNALSYM EAI_FAIL}
  EAI_NODATA      = -5;   { No address associated with NAME.  }
  {$EXTERNALSYM EAI_NODATA}
  EAI_FAMILY      = -6;   { `ai_family' not supported.  }
  {$EXTERNALSYM EAI_FAMILY}
  EAI_SOCKTYPE    = -7;   { `ai_socktype' not supported.  }
  {$EXTERNALSYM EAI_SOCKTYPE}
  EAI_SERVICE     = -8;   { SERVICE not supported for `ai_socktype'.  }
  {$EXTERNALSYM EAI_SERVICE}
  EAI_ADDRFAMILY  = -9;   { Address family for NAME not supported.  }
  {$EXTERNALSYM EAI_ADDRFAMILY}
  EAI_MEMORY      = -10;  { Memory allocation failure.  }
  {$EXTERNALSYM EAI_MEMORY}
  EAI_SYSTEM      = -11;  { System error returned in `errno'.  }
  {$EXTERNALSYM EAI_SYSTEM}

  NI_MAXHOST      = 1025;
  {$EXTERNALSYM NI_MAXHOST}
  NI_MAXSERV      = 32;
  {$EXTERNALSYM NI_MAXSERV}

  NI_NUMERICHOST  = 1;    { Don't try to look up hostname.  }
  {$EXTERNALSYM NI_NUMERICHOST}
  NI_NUMERICSERV  = 2;    { Don't convert port number to name.  }
  {$EXTERNALSYM NI_NUMERICSERV}
  NI_NOFQDN       = 4;    { Only return nodename portion.  }
  {$EXTERNALSYM NI_NOFQDN}
  NI_NAMEREQD     = 8;    { Don't return numeric addresses.  }
  {$EXTERNALSYM NI_NAMEREQD}
  NI_DGRAM        = 16;   { Look up UDP service rather than TCP.  }
  {$EXTERNALSYM NI_DGRAM}

{ Translate name of a service location and/or a service name to set of
   socket addresses.  }
function getaddrinfo(__name, __service: PChar; __req: PAddressInfo;
  var __pai: PAddressInfo): Integer; cdecl;
{$EXTERNALSYM getaddrinfo}

{ Free `addrinfo' structure AI including associated storage.  }
procedure freeaddrinfo(__ai: PAddressInfo); cdecl;
{$EXTERNALSYM freeaddrinfo}

{ Convert error return from getaddrinfo() to a string.  }
function gai_strerror(__ecode: Integer): PChar; cdecl;
{$EXTERNALSYM gai_strerror}

{ Translate a socket address to a location and service name.  }
function getnameinfo(const __sa: sockaddr; __salen: socklen_t;
  __host: PChar; __hostlen: socklen_t; __serv: PChar; __servlen: socklen_t;
  __flags: Integer): Integer; cdecl;
{$EXTERNALSYM getnameinfo}


// Translated from bits/select.h

(* The following functions are defined below without double underscores.
procedure __FD_ZERO(var fdset: TFDSet);
procedure __FD_SET(fd: TFileDescriptor; var fdset: TFDSet);
procedure __FD_CLR(fd: TFileDescriptor; var fdset: TFDSet);
function __FD_ISSET(fd: TFileDescriptor; var fdset: TFDSet): Boolean;
*)

// Translated from sys/select.h

type
  fd_mask = __fd_mask;
  {$EXTERNALSYM fd_mask}

{ Representation of a set of file descriptors.  }
  _fd_set = __fd_set;
  {.$EXTERNALSYM fd_set} // Renamed from fd_set to avoid conflict with FD_SET macro.

{ Maximum number of file descriptors in `fd_set'.  }
const
  FD_SETSIZE = __FD_SETSIZE;
  {$EXTERNALSYM FD_SETSIZE}

{ Number of bits per word of `fd_set' (some code assumes this is 32).  }
  NFDBITS = __NFDBITS;
  {$EXTERNALSYM NFDBITS}


{ Access macros for `fd_set'.  }
procedure FD_ZERO(var fdset: TFDSet);
{$EXTERNALSYM FD_ZERO}
procedure FD_SET(fd: TFileDescriptor; var fdset: TFDSet);
{$EXTERNALSYM FD_SET}
procedure FD_CLR(fd: TFileDescriptor; var fdset: TFDSet);
{$EXTERNALSYM FD_CLR}
function FD_ISSET(fd: TFileDescriptor; var fdset: TFDSet): Boolean;
{$EXTERNALSYM FD_ISSET}


{ Check the first NFDS descriptors each in READFDS (if not NULL) for read
   readiness, in WRITEFDS (if not NULL) for write readiness, and in EXCEPTFDS
   (if not NULL) for exceptional conditions.  If TIMEOUT is not NULL, time out
   after waiting the interval specified therein.  Returns the number of ready
   descriptors, or -1 for errors.  }
function select(__nfds: Integer; __readfds, __writefds, __exceptfds: PFDSet;
  __timeout: Ptimeval): Integer; cdecl;
{$EXTERNALSYM select}

{ XXX Once/if POSIX.1g gets official this prototype will be available
   when defining __USE_POSIX.  }
{ Same as above only that the TIMEOUT value is given with higher
   resolution and a sigmask which is been set temporarily.  This version
   should be used.  }
function pselect(__nfds: Integer; __readfds, __writefds, __exceptfds: PFDSet;
  __timeout: Ptimeval; __sigmask: PSigSet): Integer; cdecl;
{$EXTERNALSYM pselect}


// Translated from pwd.h

{ The passwd structure.  }
type
  passwd = {packed} record
    pw_name: PChar;             { Username.  }
    pw_passwd: PChar;           { Password.  }
    pw_uid: __uid_t;            { User ID.  }
    pw_gid: __gid_t;            { Group ID.  }
    pw_gecos: PChar;            { Real name.  }
    pw_dir: PChar;              { Home directory.  }
    pw_shell: PChar;            { Shell program.  }
  end;
  {$EXTERNALSYM passwd}
  TPasswordRecord = passwd;
  PPasswordRecord = ^TPasswordRecord;

{ Rewind the password-file stream.  }
procedure setpwent(); cdecl;
{$EXTERNALSYM setpwent}

{ Close the password-file stream.  }
procedure endpwent(); cdecl;
{$EXTERNALSYM endpwent}

{ Read an entry from the password-file stream, opening it if necessary.  }
function getpwent(): PPasswordRecord; cdecl;
{$EXTERNALSYM getpwent}

{ Read an entry from STREAM.  }
function fgetpwent(Stream: PIOFile): PPasswordRecord; cdecl;
{$EXTERNALSYM fgetpwent}

{ Write the given entry onto the given stream.  }
function putpwent(const Password: TPasswordRecord; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM putpwent}

{ Search for an entry with a matching user ID.  }
function getpwuid(uid: __uid_t): PPasswordRecord; cdecl;
{$EXTERNALSYM getpwuid}

{ Search for an entry with a matching username.  }
function getpwnam(Name: PChar): PPasswordRecord; cdecl;
{$EXTERNALSYM getpwnam}

{ Reasonable value for the buffer sized used in the reentrant
   functions below.  But better use `sysconf'.  }
const
  NSS_BUFLEN_PASSWD = 1024;
  {$EXTERNALSYM NSS_BUFLEN_PASSWD}

{ Reentrant versions of some of the functions above.

   PLEASE NOTE: the `getpwent_r' function is not (yet) standardized.
   The interface may change in later versions of this library.  But
   the interface is designed following the principals used for the
   other reentrant functions so the chances are good this is what the
   POSIX people would choose.  }

function getpwent_r(var ResultBuf: TPasswordRecord; Buffer: PChar;
  BufLen: size_t; var __result: PPasswordRecord): Integer; cdecl;
{$EXTERNALSYM getpwent_r}

function getpwuid_r(uid: __uid_t; var ResultBuf: TPasswordRecord; Buffer: PChar;
  BufLen: size_t; var __result: PPasswordRecord): Integer; cdecl;
{$EXTERNALSYM getpwuid_r}

function getpwnam_r(Name: PChar; var ResultBuf: TPasswordRecord; Buffer: PChar;
  BufLen: size_t; var __result: PPasswordRecord): Integer; cdecl;
{$EXTERNALSYM getpwnam_r}


{ Read an entry from STREAM.  This function is not standardized and
   probably never will.  }
function fgetpwent_r(Stream: PIOFile; var ResultBuf: TPasswordRecord; Buffer: PChar;
  BufLen: size_t; var __result: PPasswordRecord): Integer; cdecl;
{$EXTERNALSYM fgetpwent_r}

{ Re-construct the password-file line for the given uid
   in the given buffer.  This knows the format that the caller
   will expect, but this need not be the format of the password file.  }
function getpw(uid: __uid_t; Buffer: PChar): Integer; cdecl;
{$EXTERNALSYM getpw}

// Translated from grp.h

{ The group structure.	 }
type
  group = {packed} record
    gr_name: PChar;             { Group name.	}
    gr_passwd: PChar;           { Password.	}
    gr_gid: __gid_t;            { Group ID.	}
    gr_mem: PPChar;             { Member list.	}
  end;
  {$EXTERNALSYM group}
  TGroup = group;
  PGroup = ^TGroup;

{ Rewind the group-file stream.  }
procedure setgrent(); cdecl;
{$EXTERNALSYM setgrent}

{ Close the group-file stream.  }
procedure endgrent(); cdecl;
{$EXTERNALSYM endgrent}

{ Read an entry from the group-file stream, opening it if necessary.  }
function getgrent(): PGroup; cdecl;
{$EXTERNALSYM getgrent}

{ Read a group entry from STREAM.  }
function fgetgrent(Stream: PIOFile): PGroup; cdecl;
{$EXTERNALSYM fgetgrent}

{ Write the given entry onto the given stream.  }
function putgrent(const Group: TGroup; Stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM putgrent}

{ Search for an entry with a matching group ID.  }
function getgrgid(gid: __gid_t): PGroup; cdecl;
{$EXTERNALSYM getgrgid}

{ Search for an entry with a matching group name.  }
function getgrnam(Name: PChar): PGroup; cdecl;
{$EXTERNALSYM getgrnam}

{ Reasonable value for the buffer sized used in the reentrant
   functions below.  But better use `sysconf'.  }
const
  NSS_BUFLEN_GROUP = 1024;
  {$EXTERNALSYM NSS_BUFLEN_GROUP}

{ Reentrant versions of some of the functions above.

   PLEASE NOTE: the `getgrent_r' function is not (yet) standardized.
   The interface may change in later versions of this library.  But
   the interface is designed following the principals used for the
   other reentrant functions so the chances are good this is what the
   POSIX people would choose.  }

function getgrent_r(var ResultBuf: TGroup; Buffer: PChar; BufLen: size_t;
  var __result: PGroup): Integer; cdecl;
{$EXTERNALSYM getgrent_r}

{ Search for an entry with a matching group ID.  }
function getgrgid_r(gid: __gid_t; var ResultBuf: TGroup; Buffer: PChar;
  BufLen: size_t; var __result: PGroup): Integer; cdecl;
{$EXTERNALSYM getgrgid_r}

{ Search for an entry with a matching group name.  }
function getgrnam_r(Name: PChar; var ResultBuf: TGroup; Buffer: PChar;
  BufLen: size_t; var __result: PGroup): Integer; cdecl;
{$EXTERNALSYM getgrnam_r}

{ Read a group entry from STREAM.  This function is not standardized
   an probably never will.  }
function fgetgrent_r(Stream: PIOFile; var ResultBuf: TGroup; Buffer: PChar;
  BufLen: size_t; var __result: PGroup): Integer; cdecl;
{$EXTERNALSYM fgetgrent_r}

{ Set the group set for the current user to GROUPS (N of them).  }
function setgroups(NumGroups: size_t; Groups: PGroup): Integer; cdecl;
{$EXTERNALSYM setgroups}

{ Initialize the group set for the current user
   by reading the group database and using all groups
   of which USER is a member.  Also include GROUP.  }
function initgroups(User: PChar; Group: __gid_t): Integer; cdecl;
{$EXTERNALSYM initgroups}

// Translated from sys/ptrace.h


{  Type of the REQUEST argument to `ptrace.'  }
  {  Indicate that the process making this request should be traced.
     All signals received by this process can be intercepted by its
     parent, and its parent can use the other `ptrace' requests.  }
type
  __ptrace_request =
  (
    PTRACE_TRACEME = 0,
    {$EXTERNALSYM PTRACE_TRACEME}
    PT_TRACE_ME = PTRACE_TRACEME,
    {$EXTERNALSYM PT_TRACE_ME}

    { Return the word in the process's text space at address ADDR.  }
    PTRACE_PEEKTEXT = 1,
    {$EXTERNALSYM PTRACE_PEEKTEXT}
    PT_READ_I = PTRACE_PEEKTEXT,
    {$EXTERNALSYM PT_READ_I}

    { Return the word in the process's data space at address ADDR.  }
    PTRACE_PEEKDATA = 2,
    {$EXTERNALSYM PTRACE_PEEKDATA}
    PT_READ_D = PTRACE_PEEKDATA,
    {$EXTERNALSYM PT_READ_D}

    { Return the word in the process's user area at offset ADDR.  }
    PTRACE_PEEKUSER = 3,
    {$EXTERNALSYM PTRACE_PEEKUSER}
    PT_READ_U = PTRACE_PEEKUSER,
    {$EXTERNALSYM PT_READ_U}

    { Write the word DATA into the process's text space at address ADDR.  }
    PTRACE_POKETEXT = 4,
    {$EXTERNALSYM PTRACE_POKETEXT}
    PT_WRITE_I = PTRACE_POKETEXT,
    {$EXTERNALSYM PT_WRITE_I}

    { Write the word DATA into the process's data space at address ADDR.  }
    PTRACE_POKEDATA = 5,
    {$EXTERNALSYM PTRACE_POKEDATA}
    PT_WRITE_D = PTRACE_POKEDATA,
    {$EXTERNALSYM PT_WRITE_D}

    { Write the word DATA into the process's user area at offset ADDR.  }
    PTRACE_POKEUSER = 6,
    {$EXTERNALSYM PTRACE_POKEUSER}
    PT_WRITE_U = PTRACE_POKEUSER,
    {$EXTERNALSYM PT_WRITE_U}

    { Continue the process.  }
    PTRACE_CONT = 7,
    {$EXTERNALSYM PTRACE_CONT}
    PT_CONTINUE = PTRACE_CONT,
    {$EXTERNALSYM PT_CONTINUE}

    { Kill the process.  }
    PTRACE_KILL = 8,
    {$EXTERNALSYM PTRACE_KILL}
    PT_KILL = PTRACE_KILL,
    {$EXTERNALSYM PT_KILL}

    { Single step the process.
       This is not supported on all machines.  }
    PTRACE_SINGLESTEP = 9,
    {$EXTERNALSYM PTRACE_SINGLESTEP}
    PT_STEP = PTRACE_SINGLESTEP,
    {$EXTERNALSYM PT_STEP}

    { Get all general purpose registers used by a processes.
       This is not supported on all machines.  }
    PTRACE_GETREGS = 12,
    {$EXTERNALSYM PTRACE_GETREGS}
    PT_GETREGS = PTRACE_GETREGS,
    {$EXTERNALSYM PT_GETREGS}

    { Set all general purpose registers used by a processes.
       This is not supported on all machines.  }
    PTRACE_SETREGS = 13,
    {$EXTERNALSYM PTRACE_SETREGS}
    PT_SETREGS = PTRACE_SETREGS,
    {$EXTERNALSYM PT_SETREGS}

    { Get all floating point registers used by a processes.
       This is not supported on all machines.  }
    PTRACE_GETFPREGS = 14,
    {$EXTERNALSYM PTRACE_GETFPREGS}
    PT_GETFPREGS = PTRACE_GETFPREGS,
    {$EXTERNALSYM PT_GETFPREGS}

    { Set all floating point registers used by a processes.
       This is not supported on all machines.  }
    PTRACE_SETFPREGS = 15,
    {$EXTERNALSYM PTRACE_SETFPREGS}
    PT_SETFPREGS = PTRACE_SETFPREGS,
    {$EXTERNALSYM PT_SETFPREGS}

    { Attach to a process that is already running. }
    PTRACE_ATTACH = 16,
    {$EXTERNALSYM PTRACE_ATTACH}
    PT_ATTACH = PTRACE_ATTACH,
    {$EXTERNALSYM PT_ATTACH}

    { Detach from a process attached to with PTRACE_ATTACH.  }
    PTRACE_DETACH = 17,
    {$EXTERNALSYM PTRACE_DETACH}
    PT_DETACH = PTRACE_DETACH,
    {$EXTERNALSYM PT_DETACH}

    { Continue and stop at the next (return from) syscall.  }
    PTRACE_SYSCALL = 24,
    {$EXTERNALSYM PTRACE_SYSCALL}
    PT_SYSCALL = PTRACE_SYSCALL
    {$EXTERNALSYM PT_SYSCALL}
  );
  {$EXTERNALSYM __ptrace_request}

{  Perform process tracing functions.  REQUEST is one of the values
   above, and determines the action to be taken.
   For all requests except PTRACE_TRACEME, PID specifies the process to be
   traced.

   PID and the other arguments described above for the various requests should
   appear (those that are used for the particular request) as:
     pid_t PID, void *ADDR, int DATA, void *ADDR2
   after REQUEST.  }
(*
  Note: According to the ptrace(2) man page, using ptrace with variadic
        arguments makes use of undocumented gcc(1) behaviour.
*)
function ptrace(__request: __ptrace_request): Longint; cdecl; varargs; overload;
{$EXTERNALSYM ptrace}

function ptrace(__request: __ptrace_request; PID: pid_t; Address: Pointer; Data: Integer): Longint; cdecl; overload;

function ptrace(__request: __ptrace_request; PID: pid_t; Address: Pointer; Data: Integer; Addr2: Pointer): Longint; cdecl; overload;


// Translated from ulimit.h

{ Constants used as the first parameter for `ulimit'.  They denote limits
   which can be set or retrieved using this function.  }

const
  UL_GETFSIZE = 1;                      { Return limit on the size of a file,
					   in units of 512 bytes.  }
  {$EXTERNALSYM UL_GETFSIZE}

  UL_SETFSIZE = 2;                      { Set limit on the size of a file to
                                           second argument.  }
  {$EXTERNALSYM UL_SETFSIZE}

  __UL_GETMAXBRK = 3;                   { Return the maximum possible address
                                           of the data segment.  }
  {$EXTERNALSYM __UL_GETMAXBRK}

  __UL_GETOPENMAX = 4;                  { Return the maximum number of files
                                           that the calling process can open.  }
  {$EXTERNALSYM __UL_GETOPENMAX}


{ Control process limits according to CMD.  }
function ulimit(Cmd: Integer): Longint; cdecl; varargs;
{$EXTERNALSYM ulimit}


// Translated from bits/poll.h

const
{ Event types that can be polled for.  These bits may be set in `events'
   to indicate the interesting event types; they will appear in `revents'
   to indicate the status of the file descriptor.  }
  POLLIN       = $001;          { There is data to read.  }
  {$EXTERNALSYM POLLIN}
  POLLPRI      = $002;          { There is urgent data to read.  }
  {$EXTERNALSYM POLLPRI}
  POLLOUT      = $004;          { Writing now will not block.  }
  {$EXTERNALSYM POLLOUT}

{ These values are defined in XPG4.2.  }
  POLLRDNORM   = $040;          { Normal data may be read.  }
  {$EXTERNALSYM POLLRDNORM}
  POLLRDBAND   = $080;          { Priority data may be read.  }
  {$EXTERNALSYM POLLRDBAND}
  POLLWRNORM   = $100;          { Writing now will not block.  }
  {$EXTERNALSYM POLLWRNORM}
  POLLWRBAND   = $200;          { Priority data may be written.  }
  {$EXTERNALSYM POLLWRBAND}

{ This is an extension for Linux.  }
  POLLMSG      = $400;
  {$EXTERNALSYM POLLMSG}

{ Event types always implicitly polled for.  These bits need not be set in
   `events', but they will appear in `revents' to indicate the status of
   the file descriptor.  }
  POLLERR      = $008;          { Error condition.  }
  {$EXTERNALSYM POLLERR}
  POLLHUP      = $010;          { Hung up.  }
  {$EXTERNALSYM POLLHUP}
  POLLNVAL     = $020;          { Invalid polling request.  }
  {$EXTERNALSYM POLLNVAL}

{ Canonical number of polling requests to read in at a time in poll.  }
  NPOLLFILE  = 30;
  {$EXTERNALSYM NPOLLFILE}


// Translated from sys/poll.h

type
{ Data structure describing a polling request.  }
  pollfd = {packed} record
    fd: Integer;        { File descriptor to poll.  }
    events: Smallint;   { Types of events poller cares about.  }
    revents: Smallint;  { Types of events that actually occurred.  }
  end;
  {$EXTERNALSYM pollfd}
  TPollFD = pollfd;
  PPollFD = ^TPollFD;

{ Poll the file descriptors described by the NFDS structures starting at
   FDS.  If TIMEOUT is nonzero and not -1, allow TIMEOUT milliseconds for
   an event to occur; if TIMEOUT is -1, block until an event occurs.
   Returns the number of file descriptors with events, zero if timed out,
   or -1 for errors.  }
function poll(__fds: PPollFD; __nfds: LongWord; __timeout: Integer): Integer; cdecl;
{$EXTERNALSYM poll}


// Translated from utime.h

{ Structure describing file times.  }
type
  utimbuf = {packed} record
    actime: __time_t;           { Access time.  }
    modtime: __time_t;          { Modification time.  }
  end;
  {$EXTERNALSYM utimbuf}
  TUTimeBuffer = utimbuf;
  PUTimeBuffer = ^TUTimeBuffer;

{ Set the access and modification times of FILE to those given in
   *FILE_TIMES.  If FILE_TIMES is NULL, set them to the current time.  }
function utime(FileName: PChar; FileTimes: PUTimeBuffer): Integer; cdecl;
{$EXTERNALSYM utime}


// Translated from sysexits.h

{*
 *  SYSEXITS.H -- Exit status codes for system programs.
 *
 *	This include file attempts to categorize possible error
 *	exit statuses for system programs, notably delivermail
 *	and the Berkeley network.
 *
 *	Error numbers begin at EX__BASE to reduce the possibility of
 *	clashing with other exit statuses that random programs may
 *	already return.  The meaning of the codes is approximately
 *	as follows:
 *
 *	EX_USAGE -- The command was used incorrectly, e.g., with
 *		the wrong number of arguments, a bad flag, a bad
 *		syntax in a parameter, or whatever.
 *	EX_DATAERR -- The input data was incorrect in some way.
 *		This should only be used for user's data & not
 *		system files.
 *	EX_NOINPUT -- An input file (not a system file) did not
 *		exist or was not readable.  This could also include
 *		errors like "No message" to a mailer (if it cared
 *		to catch it).
 *	EX_NOUSER -- The user specified did not exist.  This might
 *		be used for mail addresses or remote logins.
 *	EX_NOHOST -- The host specified did not exist.  This is used
 *		in mail addresses or network requests.
 *	EX_UNAVAILABLE -- A service is unavailable.  This can occur
 *		if a support program or file does not exist.  This
 *		can also be used as a catchall message when something
 *		you wanted to do doesn't work, but you don't know
 *		why.
 *	EX_SOFTWARE -- An internal software error has been detected.
 *		This should be limited to non-operating system related
 *		errors as possible.
 *	EX_OSERR -- An operating system error has been detected.
 *		This is intended to be used for such things as "cannot
 *		fork", "cannot create pipe", or the like.  It includes
 *		things like getuid returning a user that does not
 *		exist in the passwd file.
 *	EX_OSFILE -- Some system file (e.g., /etc/passwd, /etc/utmp,
 *		etc.) does not exist, cannot be opened, or has some
 *		sort of error (e.g., syntax error).
 *	EX_CANTCREAT -- A (user specified) output file cannot be
 *		created.
 *	EX_IOERR -- An error occurred while doing I/O on some file.
 *	EX_TEMPFAIL -- temporary failure, indicating something that
 *		is not really an error.  In sendmail, this means
 *		that a mailer (e.g.) could not create a connection,
 *		and the request should be reattempted later.
 *	EX_PROTOCOL -- the remote system returned something that
 *		was "not possible" during a protocol exchange.
 *	EX_NOPERM -- You did not have sufficient permission to
 *		perform the operation.  This is not intended for
 *		file system problems, which should use NOINPUT or
 *		CANTCREAT, but rather for higher level permissions.
 *}

const
  EX_OK           = 0;         { successful termination }
  {$EXTERNALSYM EX_OK}

  EX__BASE        = 64;        { base value for error messages }
  {$EXTERNALSYM EX__BASE}

  EX_USAGE        = 64;        { command line usage error }
  {$EXTERNALSYM EX_USAGE}
  EX_DATAERR      = 65;        { data format error }
  {$EXTERNALSYM EX_DATAERR}
  EX_NOINPUT      = 66;        { cannot open input }
  {$EXTERNALSYM EX_NOINPUT}
  EX_NOUSER       = 67;        { addressee unknown }
  {$EXTERNALSYM EX_NOUSER}
  EX_NOHOST       = 68;        { host name unknown }
  {$EXTERNALSYM EX_NOHOST}
  EX_UNAVAILABLE  = 69;        { service unavailable }
  {$EXTERNALSYM EX_UNAVAILABLE}
  EX_SOFTWARE     = 70;        { internal software error }
  {$EXTERNALSYM EX_SOFTWARE}
  EX_OSERR        = 71;        { system error (e.g., can't fork) }
  {$EXTERNALSYM EX_OSERR}
  EX_OSFILE       = 72;        { critical OS file missing }
  {$EXTERNALSYM EX_OSFILE}
  EX_CANTCREAT    = 73;        { can't create (user) output file }
  {$EXTERNALSYM EX_CANTCREAT}
  EX_IOERR        = 74;        { input/output error }
  {$EXTERNALSYM EX_IOERR}
  EX_TEMPFAIL     = 75;        { temp failure; user is invited to retry }
  {$EXTERNALSYM EX_TEMPFAIL}
  EX_PROTOCOL     = 76;        { remote error in protocol }
  {$EXTERNALSYM EX_PROTOCOL}
  EX_NOPERM       = 77;        { permission denied }
  {$EXTERNALSYM EX_NOPERM}
  EX_CONFIG       = 78;        { configuration error }
  {$EXTERNALSYM EX_CONFIG}

  EX__MAX         = 78;        { maximum listed value }
  {$EXTERNALSYM EX__MAX}


// Translated from bits/ustat.h

type
  _ustat = {packed} record
    f_tfree: __daddr_t;
    f_tinode: __ino_t;
    f_fname: packed array [0..6-1] of Char;
    f_fpack: packed array [0..6-1] of Char;
  end;
  {.$EXTERNALSYM ustat} // Renamed from header file.
  TUStat = _ustat;
  PUStat = ^TUStat;

// Translated from sys/ustat.h

function ustat (__dev: __dev_t; var __ubuf: TUStat): Integer; cdecl;
{$EXTERNALSYM ustat}


// Translated from err.h


{ Print "program: ", FORMAT, ": ", the standard error string for errno,
   and a newline, on stderr.  }
procedure warn(__format: PChar); cdecl; varargs;
{$EXTERNALSYM warn}
procedure vwarn(__format: PChar; Arg: Pointer); cdecl;
{$EXTERNALSYM vwarn}

{ Likewise, but without ": " and the standard error string.  }
procedure warnx(__format: PChar); cdecl; varargs;
{$EXTERNALSYM warnx}
procedure vwarnx(__format: PChar; Arg: Pointer); cdecl;
{$EXTERNALSYM vwarnx}

{ Likewise, and then exit with STATUS.  }
procedure err(__status: Integer; __format: PChar); cdecl; varargs;
{$EXTERNALSYM err}
procedure verr(__status: Integer; __format: PChar; Arg: Pointer); cdecl;
{$EXTERNALSYM verr}
procedure errx(__status: Integer; __format: PChar); cdecl; varargs;
{$EXTERNALSYM errx}
procedure verrx(__status: Integer; __format: PChar; Arg: Pointer); cdecl;
{$EXTERNALSYM verrx}


// Translated from error.h

{ Print a message with `fprintf (stderr, FORMAT, ...)';
   if ERRNUM is nonzero, follow it with ": " and strerror (ERRNUM).
   If STATUS is nonzero, terminate the program with `exit (STATUS)'.  }

procedure error(status: Integer; errnum: Integer; format: PChar); cdecl; varargs;
{$EXTERNALSYM error}

procedure error_at_line(status: Integer; errnum: Integer; fname: PChar;
  lineno: Cardinal; format: PChar); cdecl; varargs;
{$EXTERNALSYM error_at_line}


// Translated from bits/fenv.h

{ Get the architecture dependend definitions.  The following definitions
   are expected to be done:

   fenv_t	type for object representing an entire floating-point
		environment

   FE_DFL_ENV	macro of type pointer to fenv_t to be used as the argument
		to functions taking an argument of type fenv_t; in this
		case the default environment will be used

   fexcept_t	type for object representing the floating-point exception
		flags including status associated with the flags

   The following macros are defined iff the implementation supports this
   kind of exception.
   FE_INEXACT		inexact result
   FE_DIVBYZERO		division by zero
   FE_UNDERFLOW		result not representable due to underflow
   FE_OVERFLOW		result not representable due to overflow
   FE_INVALID		invalid operation

   FE_ALL_EXCEPT	bitwise OR of all supported exceptions

   The next macros are defined iff the appropriate rounding mode is
   supported by the implementation.
   FE_TONEAREST		round to nearest
   FE_UPWARD		round toward +Inf
   FE_DOWNWARD		round toward -Inf
   FE_TOWARDZERO	round toward 0
}

const
  FE_INVALID = $01;
  {$EXTERNALSYM FE_INVALID}
  __FE_DENORM = $02;
  {$EXTERNALSYM __FE_DENORM}
  FE_DIVBYZERO = $04;
  {$EXTERNALSYM FE_DIVBYZERO}
  FE_OVERFLOW = $08;
  {$EXTERNALSYM FE_OVERFLOW}
  FE_UNDERFLOW = $10;
  {$EXTERNALSYM FE_UNDERFLOW}
  FE_INEXACT = $20;
  {$EXTERNALSYM FE_INEXACT}

  FE_ALL_EXCEPT = (FE_INEXACT or FE_DIVBYZERO or FE_UNDERFLOW or FE_OVERFLOW or FE_INVALID);
  {$EXTERNALSYM FE_ALL_EXCEPT}

{ The ix87 FPU supports all of the four defined rounding modes.  We
   use again the bit positions in the FPU control word as the values
   for the appropriate macros.  }

  FE_TONEAREST = 0;
  {$EXTERNALSYM FE_TONEAREST}
  FE_DOWNWARD = $400;
  {$EXTERNALSYM FE_DOWNWARD}
  FE_UPWARD = $800;
  {$EXTERNALSYM FE_UPWARD}
  FE_TOWARDZERO = $c00;
  {$EXTERNALSYM FE_TOWARDZERO}

{ Type representing exception flags.  }
type
  fexcept_t = Word;
  {$EXTERNALSYM fexcept_t}
  TExceptionFlags = fexcept_t;
  PExceptionFlags = ^TExceptionFlags;

{ Type representing floating-point environment.  This function corresponds
   to the layout of the block written by the `fstenv'.  }
  fenv_t = {packed} record
    __control_word: Word;
    __unused1: Word;
    __status_word: Word;
    __unused2: Word;
    __tags: Word;
    __unused3: Word;
    __eip: Cardinal;
    __cs_selector: Word;
    __opcode_bitfield: Integer;
    __data_offset: Cardinal;
    __data_selector: Word;
    __unused5: Word;
  end;
  {$EXTERNALSYM fenv_t}
  TFloatingPointEnv = fenv_t;
  PFloatingPointEnv = ^TFloatingPointEnv;


{ If the default argument is used we use this value.  }
const
  FE_DFL_ENV = PFloatingPointEnv(-1);
  {$EXTERNALSYM FE_DFL_ENV}

{ Floating-point environment where none of the exception is masked.  }
  FE_NOMASK_ENV = PFloatingPointEnv(-2);
  {$EXTERNALSYM FE_NOMASK_ENV}


// Translated from fenv.h

{ Floating-point exception handling.  }

{ Clear the supported exceptions represented by EXCEPTS.  }
function feclearexcept(__excepts: Integer): Integer; cdecl;
{$EXTERNALSYM feclearexcept}

{ Store implementation-defined representation of the exception flags
   indicated by EXCEPTS in the object pointed to by FLAGP.  }
function fegetexceptflag(var __flagp: TExceptionFlags; __excepts: Integer): Integer; cdecl;
{$EXTERNALSYM fegetexceptflag}

{ Raise the supported exceptions represented by EXCEPTS.  }
function feraiseexcept(__excepts: Integer): Integer; cdecl;
{$EXTERNALSYM feraiseexcept}

{ Set complete status for exceptions indicated by EXCEPTS according to
   the representation in the object pointed to by FLAGP.  }
function fesetexceptflag(__flagp: PExceptionFlags; __excepts: Integer): Integer; cdecl;
{$EXTERNALSYM fesetexceptflag}

{ Determine which of subset of the exceptions specified by EXCEPTS are
   currently set.  }
function fetestexcept(__excepts: Integer): Integer; cdecl;
{$EXTERNALSYM fetestexcept}


{ Rounding control.  }

{ Get current rounding direction.  }
function fegetround(): Integer; cdecl;
{$EXTERNALSYM fegetround}

{ Establish the rounding direction represented by ROUND.  }
function fesetround(__rounding_direction: Integer): Integer; cdecl;
{$EXTERNALSYM fesetround}


{ Floating-point environment.  }

{ Store the current floating-point environment in the object pointed
   to by ENVP.  }
function fegetenv(var __envp: TFloatingPointEnv): Integer; cdecl;
{$EXTERNALSYM fegetenv}

{ Save the current environment in the object pointed to by ENVP, clear
   exception flags and install a non-stop mode (if available) for all
   exceptions.  }
function feholdexcept(var __envp: TFloatingPointEnv): Integer; cdecl;
{$EXTERNALSYM feholdexcept}

{ Establish the floating-point environment represented by the object
   pointed to by ENVP.  }
function fesetenv(const __envp: TFloatingPointEnv): Integer; cdecl;
{$EXTERNALSYM fesetenv}

{ Save current exceptions in temporary storage, install environment
   represented by object pointed to by ENVP and raise exceptions
   according to saved exceptions.  }
function feupdateenv(const __envp: TFloatingPointEnv): Integer; cdecl;
{$EXTERNALSYM feupdateenv}

{ Enable individual exceptions.  Will not enable more exceptions than
   EXCEPTS specifies.  Returns the previous enabled exceptions if all
   exceptions are successfully set, otherwise returns -1.  }
function feenableexcept(__excepts: Integer): Integer; cdecl;
{$EXTERNALSYM feenableexcept}

{ Disable individual exceptions.  Will not disable more exceptions than
   EXCEPTS specifies.  Returns the previous enabled exceptions if all
   exceptions are successfully disabled, otherwise returns -1.  }
function fedisableexcept(__excepts: Integer): Integer; cdecl;
{$EXTERNALSYM fedisableexcept}

{ Return enabled exceptions.  }
function fegetexcept(): Integer; cdecl;
{$EXTERNALSYM fegetexcept}


// Translated from bits/ipc.h

const
{ Mode bits for `msgget', `semget', and `shmget'.  }
  IPC_CREAT     = $200;         { Create key if key does not exist. }
  {$EXTERNALSYM IPC_CREAT}
  IPC_EXCL      = $400;         { Fail if key exists.  }
  {$EXTERNALSYM IPC_EXCL}
  IPC_NOWAIT    = $800;         { Return error on wait.  }
  {$EXTERNALSYM IPC_NOWAIT}

{ Control commands for `msgctl', `semctl', and `shmctl'.  }
  IPC_RMID      = 0;            { Remove identifier.  }
  {$EXTERNALSYM IPC_RMID}
  IPC_SET       = 1;            { Set `ipc_perm' options.  }
  {$EXTERNALSYM IPC_SET}
  IPC_STAT      = 2;            { Get `ipc_perm' options.  }
  {$EXTERNALSYM IPC_STAT}

  IPC_INFO      = 3;            { See ipcs.  }
  {$EXTERNALSYM IPC_INFO}

{ Special key values.  }
  IPC_PRIVATE   = __key_t(0);   { Private key.  }
  {$EXTERNALSYM IPC_PRIVATE}


{ Data structure used to pass permission information to IPC operations.  }
type
  ipc_perm = {packed} record
    __key: __key_t;                     { Key.  }
    uid: __uid_t;                       { Owner's user ID.  }
    gid: __gid_t;                       { Owner's group ID.  }
    cuid: __uid_t;                      { Creator's user ID.  }
    cgid: __gid_t;                      { Creator's group ID.  }
    mode: Smallint;                     { Read/write permission.  }
    __pad1: Smallint;
    __seq: Smallint;                    { Sequence number.  }
    __pad2: Smallint;
    __unused1: LongWord;
    __unused2: LongWord;
  end;
  {$EXTERNALSYM ipc_perm}
  TIpcPermission = ipc_perm;
  PIpcPermission = ^TIpcPermission;


// Translated from sys/ipc.h

{ Generates key for System V style IPC.  }
function ftok(__pathname: PChar; __proj_id: Integer): key_t; cdecl;
{$EXTERNALSYM ftok}


// Translated from bits/shm.h

const
{ Permission flag for shmget.  }
  SHM_R         = $100;           { or S_IRUGO from <linux/stat.h> }
  {$EXTERNALSYM SHM_R}
  SHM_W         = $80;            { or S_IWUGO from <linux/stat.h> }
  {$EXTERNALSYM SHM_W}

{ Flags for `shmat'.  }
  SHM_RDONLY    = $1000;          { attach read-only else read-write }
  {$EXTERNALSYM SHM_RDONLY}
  SHM_RND       = $2000;          { round attach address to SHMLBA }
  {$EXTERNALSYM SHM_RND}
  SHM_REMAP     = $4000;          { take-over region on attach }
  {$EXTERNALSYM SHM_REMAP}

{ Commands for `shmctl'.  }
  SHM_LOCK      = 11;             { lock segment (root only) }
  {$EXTERNALSYM SHM_LOCK}
  SHM_UNLOCK    = 12;             { unlock segment (root only) }
  {$EXTERNALSYM SHM_UNLOCK}


{ Type to count number of attaches.  }
type
  shmatt_t = LongWord;
  {$EXTERNALSYM shmatt_t}

type
{ Data structure describing a set of semaphores.  }
  shmid_ds = {packed} record
    shm_perm: ipc_perm;                 { operation permission struct }
    shm_segsz: size_t;                  { size of segment in bytes }
    shm_atime: __time_t;                { time of last shmat() }
    __unused1: LongWord;
    shm_dtime: __time_t;                { time of last shmdt() }
    __unused2: LongWord;
    shm_ctime: __time_t;                { time of last change by shmctl() }
    __unused3: LongWord;
    shm_cpid: __pid_t;                  { pid of creator }
    shm_lpid: __pid_t;                  { pid of last shmop }
    shm_nattch: shmatt_t;               { number of current attaches }
    __unused4: LongWord;
    __unused5: LongWord;
  end;
  {$EXTERNALSYM shmid_ds}
  TSharedMemIdDescriptor = shmid_ds;
  PSharedMemIdDescriptor = ^TSharedMemIdDescriptor;


const
{ ipcs ctl commands }
  SHM_STAT      = 13;
  {$EXTERNALSYM SHM_STAT}
  SHM_INFO      = 14;
  {$EXTERNALSYM SHM_INFO}

{ shm_mode upper byte flags }
  SHM_DEST      = $200;        { segment will be destroyed on last detach }
  {$EXTERNALSYM SHM_DEST}
  SHM_LOCKED	= $400;        { segment will not be swapped }
  {$EXTERNALSYM SHM_LOCKED}

type
  shminfo = {packed} record
    shmmax: LongWord;
    shmmin: LongWord;
    shmmni: LongWord;
    shmseg: LongWord;
    shmall: LongWord;
    __unused1: LongWord;
    __unused2: LongWord;
    __unused3: LongWord;
    __unused4: LongWord;
  end;
  {$EXTERNALSYM shminfo}
  TSharedMemInfo = shminfo;
  PSharedMemInfo = ^TSharedMemInfo;

  _shm_info = {packed} record
    used_ids: Integer;
    shm_tot: LongWord;       { total allocated shm }
    shm_rss: LongWord;       { total resident shm }
    shm_swp: LongWord;       { total swapped shm }
    swap_attempts: LongWord;
    swap_successes: LongWord;
  end;
  {.$EXTERNALSYM shm_info} // Redeclated from _shm_info because of conflict with SHM_INFO
  TTotalSharedMemInfo = _shm_info;
  PTotalSharedMemInfo = ^TTotalSharedMemInfo;


// Translated from sys/shm.h

{ Segment low boundary address multiple.  }
function SHMLBA: Integer;
{$EXTERNALSYM SHMLBA}
function __getpagesize(): Integer; cdecl;
{$EXTERNALSYM __getpagesize}

{ The following System V style IPC functions implement a shared memory
   facility.  The definition is found in XPG4.2.  }

{ Shared memory control operation.  }
function shmctl(__shmid: Integer; __cmd: Integer; __buf: PSharedMemIdDescriptor): Integer; cdecl;
{$EXTERNALSYM shmctl}

{ Get shared memory segment.  }
function shmget(__key: key_t; __size: size_t; __shmflg: Integer): Integer; cdecl;
{$EXTERNALSYM shmget}

{ Attach shared memory segment.  }
function shmat(__shmid: Integer; __shmaddr: Pointer; __shmflg: Integer): Pointer; cdecl;
{$EXTERNALSYM shmat}

{ Detach shared memory segment.  }
function shmdt(__shmaddr: Pointer): Integer; cdecl;
{$EXTERNALSYM shmdt}


// Translated from bits/sem.h

const
{ Flags for `semop'.  }
  SEM_UNDO       = $1000;               { undo the operation on exit }
  {$EXTERNALSYM SEM_UNDO}

{ Commands for `semctl'.  }
  _GETPID         = 11;          { get sempid }
  {.$EXTERNALSYM GETPID} // Renamed because of identifier conflict 
  GETVAL         = 12;          { get semval }
  {$EXTERNALSYM GETVAL}
  GETALL         = 13;          { get all semval's }
  {$EXTERNALSYM GETALL}
  GETNCNT        = 14;          { get semncnt }
  {$EXTERNALSYM GETNCNT}
  GETZCNT        = 15;          { get semzcnt }
  {$EXTERNALSYM GETZCNT}
  SETVAL         = 16;          { set semval }
  {$EXTERNALSYM SETVAL}
  SETALL         = 17;          { set all semval's }
  {$EXTERNALSYM SETALL}


{ Data structure describing a set of semaphores.  }
type
  semid_ds = {packed} record
    sem_perm: ipc_perm;                 { operation permission struct }
    sem_otime: __time_t;                { last semop() time }
    __unused1: LongWord;
    sem_ctime: __time_t;                { last time changed by semctl() }
    __unused2: LongWord;
    sem_nsems: LongWord;                { number of semaphores in set }
    __unused3: LongWord;
    __unused4: LongWord;
  end;
  {$EXTERNALSYM semid_ds}
  TSemaphoreIdDescriptor = semid_ds;
  PSemaphoreIdDescriptor = ^TSemaphoreIdDescriptor;

(* The user should define a union like the following to use it for arguments
   for `semctl'.

   union semun
   {
     int val;				<= value for SETVAL
     struct semid_ds *buf;		<= buffer for IPC_STAT & IPC_SET
     unsigned short int *array;		<= array for GETALL & SETALL
     struct seminfo *__buf;		<= buffer for IPC_INFO
   };

   Previous versions of this file used to define this union but this is
   incorrect.  One can test the macro _SEM_SEMUN_UNDEFINED to see whether
   one must define the union or not.  *)
const
  _SEM_SEMUN_UNDEFINED = 1;
  {$EXTERNALSYM _SEM_SEMUN_UNDEFINED}


{ ipcs ctl cmds }
const
  SEM_STAT = 18;
  {$EXTERNALSYM SEM_STAT}
  SEM_INFO = 19;
  {$EXTERNALSYM SEM_INFO}

type
  seminfo = {packed} record
    semmap: Integer;
    semmni: Integer;
    semmns: Integer;
    semmnu: Integer;
    semmsl: Integer;
    semopm: Integer;
    semume: Integer;
    semusz: Integer;
    semvmx: Integer;
    semaem: Integer;
  end;
  {$EXTERNALSYM seminfo}
  TSemaphoreInfo = seminfo;
  PSemaphoreInfo = ^TSemaphoreInfo;


// Translated from sys/sem.h

{ The following System V style IPC functions implement a semaphore
   handling.  The definition is found in XPG2.  }

{ Structure used for argument to `semop' to describe operations.  }
type
  sembuf = {packed} record
    sem_num: Smallint;          { semaphore number }
    sem_op: Smallint;           { semaphore operation }
    sem_flg: Smallint;          { operation flag }
  end;
  {$EXTERNALSYM sembuf}
  TSemaphoreBuffer = sembuf;
  PSemaphoreBuffer = ^TSemaphoreBuffer;


{ Semaphore control operation.  }
function semctl(__semid: Integer; __semnum: Integer; __cmd: Integer): Integer; cdecl; varargs;
{$EXTERNALSYM semctl}

{ Get semaphore.  }
function semget(__key: key_t; __nsems: Integer; __semflg: Integer): Integer; cdecl;
{$EXTERNALSYM semget}

{ Operate on semaphore.  }
function semop(__semid: Integer; __sops: PSemaphoreBuffer; __nsops: size_t): Integer; cdecl;
{$EXTERNALSYM semop}


// Translated from libgen.h

{ Return directory part of PATH or "." if none is available.  }
function dirname(__path: PChar): PChar; cdecl;
{$EXTERNALSYM dirname}

{ Return final component of PATH.

   This is the weird XPG version of this function.  It sometimes will
   modify its argument.  Therefore we normally use the GNU version (in
   <string.h>) and only if this header is included make the XPG
   version available under the real name.  }
function __xpg_basename(__path: PChar): PChar; cdecl;
{$EXTERNALSYM __xpg_basename}


// Translated from bits/utmp.h

const
  UT_LINESIZE   = 32;
  {$EXTERNALSYM UT_LINESIZE}
  UT_NAMESIZE   = 32;
  {$EXTERNALSYM UT_NAMESIZE}
  UT_HOSTSIZE   = 256;
  {$EXTERNALSYM UT_HOSTSIZE}


type
{ The structure describing an entry in the database of
   previous logins.  }
  lastlog = {packed} record
    ll_time: __time_t;
    ll_line: packed array[0..UT_LINESIZE-1] of Char;
    ll_host: packed array[0..UT_HOSTSIZE-1] of Char;
  end;
  {$EXTERNALSYM lastlog}


{ The structure describing the status of a terminated process.  This
   type is used in `struct utmp' below.  }
  exit_status = {packed} record
    e_termination: Smallint;    { Process termination status.  }
    e_exit: Smallint;           { Process exit status.  }
  end;
  {$EXTERNALSYM exit_status}


{ The structure describing an entry in the user accounting database.  }
  utmp = {packed} record
    ut_type: Smallint;                               { Type of login.  }
    ut_pid: pid_t;                                   { Process ID of login process.  }
    ut_line: packed array[0..UT_LINESIZE-1] of Char; { Devicename.  }
    ut_id: packed array[0..4-1] of Char;             { Inittab ID.  }
    ut_user: packed array[0..UT_NAMESIZE-1] of Char; { Username.  }
    ut_host: packed array[0..UT_HOSTSIZE-1] of Char; { Hostname for remote login.  }
    ut_exit: exit_status;                            { Exit status of a process marked as DEAD_PROCESS.  }
    ut_session: Longint;                             { Session ID, used for windowing.  }
    ut_tv: timeval;                                  { Time entry was made.  }
    ut_addr_v6: packed array[0..4-1] of int32_t;     { Internet address of remote host.  }
    __unused: packed array[0..20-1] of Char;         { Reserved for future use.  }
  end;
  {$EXTERNALSYM utmp}
  TUserTmp = utmp;
  PUserTmp = ^TUserTmp;

{ Backwards compatibility hacks. --- Have been intentionally left out; macros. }

{ Values for the `ut_type' field of a `struct utmp'.  }
const
  EMPTY          = 0;   { No valid user accounting information.  }
  {$EXTERNALSYM EMPTY}

  RUN_LVL        = 1;   { The system's runlevel.  }
  {$EXTERNALSYM RUN_LVL}
  BOOT_TIME      = 2;   { Time of system boot.  }
  {$EXTERNALSYM BOOT_TIME}
  NEW_TIME       = 3;   { Time after system clock changed.  }
  {$EXTERNALSYM NEW_TIME}
  OLD_TIME       = 4;   { Time when system clock changed.  }
  {$EXTERNALSYM OLD_TIME}

  INIT_PROCESS   = 5;   { Process spawned by the init process.  }
  {$EXTERNALSYM INIT_PROCESS}
  LOGIN_PROCESS  = 6;   { Session leader of a logged in user.  }
  {$EXTERNALSYM LOGIN_PROCESS}
  USER_PROCESS   = 7;   { Normal process.  }
  {$EXTERNALSYM USER_PROCESS}
  DEAD_PROCESS   = 8;   { Terminated process.  }
  {$EXTERNALSYM DEAD_PROCESS}

  ACCOUNTING     = 9;
  {$EXTERNALSYM ACCOUNTING}

{ Old Linux name for the EMPTY type.  }
  UT_UNKNOWN     = EMPTY;
  {$EXTERNALSYM UT_UNKNOWN}


// Translated from utmp.h

{ Compatibility names for the strings of the canonical file names.  }
  UTMP_FILE     = _PATH_UTMP;
  {$EXTERNALSYM UTMP_FILE}
  UTMP_FILENAME = _PATH_UTMP;
  {$EXTERNALSYM UTMP_FILENAME}
  WTMP_FILE     = _PATH_WTMP;
  {$EXTERNALSYM WTMP_FILE}
  WTMP_FILENAME = _PATH_WTMP;
  {$EXTERNALSYM WTMP_FILENAME}


{ Make FD be the controlling terminal, stdin, stdout, and stderr;
   then close FD.  Returns 0 on success, nonzero on error.  }
function login_tty(__fd: Integer): Integer; cdecl;
{$EXTERNALSYM login_tty}


{ Write the given entry into utmp and wtmp.  }
procedure login(const __entry: utmp); cdecl;
{$EXTERNALSYM login}

{ Write the utmp entry to say the user on UT_LINE has logged out.  }
function logout(__ut_line: PChar): Integer; cdecl;
{$EXTERNALSYM logout}

{ Append to wtmp an entry for the current time and the given info.  }
procedure logwtmp(__ut_line, __ut_name, __ut_host: PChar); cdecl;
{$EXTERNALSYM logwtmp}

{ Append entry UTMP to the wtmp-like file WTMP_FILE.  }
procedure updwtmp(__wtmp_file: PChar; const __utmp: utmp); cdecl;
{$EXTERNALSYM updwtmp}

{ Change name of the utmp file to be examined.  }
function utmpname(__file: PChar): Integer; cdecl;
{$EXTERNALSYM utmpname}

{ Read next entry from a utmp-like file.  }
function getutent(): PUserTmp; cdecl;
{$EXTERNALSYM getutent}

{ Reset the input stream to the beginning of the file.  }
procedure setutent(); cdecl;
{$EXTERNALSYM setutent}

{ Close the current open file.  }
procedure endutent(); cdecl;
{$EXTERNALSYM endutent}

{ Search forward from the current point in the utmp file until the
   next entry with a ut_type matching ID->ut_type.  }
function getutid(const __id: utmp): PUserTmp; cdecl;
{$EXTERNALSYM getutid}

{ Search forward from the current point in the utmp file until the
   next entry with a ut_line matching LINE->ut_line.  }
function getutline(const __line: utmp): PUserTmp; cdecl;
{$EXTERNALSYM getutline}

{ Write out entry pointed to by UTMP_PTR into the utmp file.  }
function pututline(const __utmp: utmp): PUserTmp; cdecl;
{$EXTERNALSYM pututline}


{ Reentrant versions of the file for handling utmp files.  }
function getutent_r(var __buffer: utmp; var __result: PUserTmp): Integer; cdecl;
{$EXTERNALSYM getutent_r}

function getutid_r(const __id: utmp; var __buffer: utmp; var __result: PUserTmp): Integer; cdecl;
{$EXTERNALSYM getutid_r}

function getutline_r(const __line: utmp; var __buffer: utmp; var __result: PUserTmp): Integer; cdecl;
{$EXTERNALSYM getutline_r}


// Translated from bits/utmpx.h

const
  _PATH_UTMPX   = _PATH_UTMP;
  {$EXTERNALSYM _PATH_UTMPX}
  _PATH_WTMPX   = _PATH_WTMP;
  {$EXTERNALSYM _PATH_WTMPX}


  __UT_LINESIZE   = 32;
  {$EXTERNALSYM __UT_LINESIZE}
  __UT_NAMESIZE   = 32;
  {$EXTERNALSYM __UT_NAMESIZE}
  __UT_HOSTSIZE   = 256;
  {$EXTERNALSYM __UT_HOSTSIZE}


{ The structure describing the status of a terminated process.  This
   type is used in `struct utmpx' below.  }
type
  __exit_status = {packed} record
    e_termination: Smallint;    { Process termination status.  }
    e_exit: Smallint;           { Process exit status.  }
  end;
  {$EXTERNALSYM __exit_status}


{ The structure describing an entry in the user accounting database.  }
  utmpx = {packed} record
    ut_type: Smallint;                                  { Type of login.  }
    ut_pid: __pid_t;                                    { Process ID of login process.  }
    ut_line: packed array[0..__UT_LINESIZE-1] of Char;  { Devicename.  }
    ut_id: packed array[0..4-1] of Char;                { Inittab ID. }
    ut_user: packed array[0..__UT_NAMESIZE-1] of Char;  { Username.  }
    ut_host: packed array[0..__UT_HOSTSIZE-1] of Char; 	{ Hostname for remote login.  }
    ut_exit: __exit_status;                             { Exit status of a process marked as DEAD_PROCESS.  }
    ut_session: Longint;                                { Session ID, used for windowing.  }
    ut_tv: timeval;                                     { Time entry was made.  }
    ut_addr_v6: packed array[0..4-1] of __int32_t;      { Internet address of remote host.  }
    __unused: packed array[0..20-1] of Char;            { Reserved for future use.  }
  end;
  {$EXTERNALSYM utmpx}
  TUserTmpX = utmpx;
  PUserTmpX = ^TUserTmpX;


// Translated from utmpx.h

const
{ Compatibility names for the strings of the canonical file names.  }
  UTMPX_FILE      = _PATH_UTMPX;
  {$EXTERNALSYM UTMPX_FILE}
  UTMPX_FILENAME  = _PATH_UTMPX;
  {$EXTERNALSYM UTMPX_FILENAME}
  WTMPX_FILE      = _PATH_WTMPX;
  {$EXTERNALSYM WTMPX_FILE}
  WTMPX_FILENAME  = _PATH_WTMPX;
  {$EXTERNALSYM WTMPX_FILENAME}

{ Open user accounting database.  }
procedure setutxent(); cdecl;
{$EXTERNALSYM setutxent}

{ Close user accounting database.  }
procedure endutxent(); cdecl;
{$EXTERNALSYM endutxent}

{ Get the next entry from the user accounting database.  }
function getutxent(): PUserTmpX; cdecl;
{$EXTERNALSYM getutxent}

{ Get the user accounting database entry corresponding to ID.  }
function getutxid(const __id: utmpx): PUserTmpX; cdecl;
{$EXTERNALSYM getutxid}

{ Get the user accounting database entry corresponding to LINE.  }
function getutxline(const __line: utmpx): PUserTmpX; cdecl;
{$EXTERNALSYM getutxline}

{ Write the entry UTMPX into the user accounting database.  }
function pututxline(const __utmpx: utmpx): PUserTmpX; cdecl;
{$EXTERNALSYM pututxline}


{ Change name of the utmpx file to be examined.  }
function utmpxname(__file: PChar): Integer; cdecl;
{$EXTERNALSYM utmpxname}

{ Append entry UTMP to the wtmpx-like file WTMPX_FILE.  }
procedure updwtmpx(__wtmpx_file: PChar; const __utmpx: utmpx); cdecl;
{$EXTERNALSYM updwtmpx}


{ Copy the information in UTMPX to UTMP. }
procedure getutmp(const __utmpx: utmpx; var __utmp: utmp); cdecl;
{$EXTERNALSYM getutmp}

{ Copy the information in UTMP to UTMPX. }
procedure getutmpx(const __utmp: utmp; var __utmpx: utmpx); cdecl;
{$EXTERNALSYM getutmpx}


// Translated from sys/vtimes.h

{ This interface is obsolete; use `getrusage' instead.  }

{ Granularity of the `vm_utime' and `vm_stime' fields of a `struct vtimes'.
   (This is the frequency of the machine's power supply, in Hz.)  }
const
  VTIMES_UNITS_PER_SECOND = 60;
  {$EXTERNALSYM VTIMES_UNITS_PER_SECOND}

type
  _vtimes = {packed} record
    { User time used in units of 1/VTIMES_UNITS_PER_SECOND seconds.  }
    vm_utime: Integer;
    { System time used in units of 1/VTIMES_UNITS_PER_SECOND seconds.  }
    vm_stime: Integer;

    { Amount of data and stack memory used (kilobyte-seconds).  }
    vm_idsrss: Cardinal;
    { Amount of text memory used (kilobyte-seconds).  }
    vm_ixrss: Cardinal;
    { Maximum resident set size (text, data, and stack) (kilobytes).  }
    vm_maxrss: Integer;

    { Number of hard page faults (i.e. those that required I/O).  }
    vm_majflt: Integer;
    { Number of soft page faults (i.e. those serviced by reclaiming
       a page from the list of pages awaiting reallocation.  }
    vm_minflt: Integer;

    { Number of times a process was swapped out of physical memory.  }
    vm_nswap: Integer;

    { Number of input operations via the file system.  Note: This
       and `ru_oublock' do not include operations with the cache.  }
    vm_inblk: Integer;
    { Number of output operations via the file system.  }
    vm_oublk: Integer;
  end;
  {.$EXTERNALSYM vtimes} // Renamed because of name conflict with function
  Tvtimes = _vtimes;
  Pvtimes = ^Tvtimes;

{ If CURRENT is not NULL, write statistics for the current process into
   *CURRENT.  If CHILD is not NULL, write statistics for all terminated child
   processes into *CHILD.  Returns 0 for success, -1 for failure.  }
function vtimes(__current: Pvtimes; __child: Pvtimes): Integer; cdecl;
{$EXTERNALSYM vtimes}


// Translated from vlimit.h

{ This interface is obsolete, and is superseded by <sys/resource.h>.  }

{ Kinds of resource limit.  }
type
  __vlimit_resource =
  (
    { Setting this non-zero makes it impossible to raise limits.
       Only the super-use can set it to zero.

       This is not implemented in recent versions of BSD, nor by
       the GNU C library.  }
    LIM_NORAISE = 0,
    {$EXTERNALSYM LIM_NORAISE}

    { CPU time available for each process (seconds).  }
    LIM_CPU = 1,
    {$EXTERNALSYM LIM_CPU}

    { Largest file which can be created (bytes).  }
    LIM_FSIZE = 2,
    {$EXTERNALSYM LIM_FSIZE}

    { Maximum size of the data segment (bytes).  }
    LIM_DATA = 3,
    {$EXTERNALSYM LIM_DATA}

    { Maximum size of the stack segment (bytes).  }
    LIM_STACK = 4,
    {$EXTERNALSYM LIM_STACK}

    { Largest core file that will be created (bytes).  }
    LIM_CORE = 5,
    {$EXTERNALSYM LIM_CORE}

    { Resident set size (bytes).  }
    LIM_MAXRSS = 6
    {$EXTERNALSYM LIM_MAXRSS}
  );
  {$EXTERNALSYM __vlimit_resource}

const
{ This means no limit.  }
  VLIMIT_INFINITY = $7fffffff;
  {.$EXTERNALSYM INFINITY} // Renamed from header file to avoid namespace pollution


{ Set the soft limit for RESOURCE to be VALUE.
   Returns 0 for success, -1 for failure.  }
function vlimit(__resource: __vlimit_resource; __value: Integer): Integer; cdecl;
{$EXTERNALSYM vlimit}


// Translated from sys/ucontext.h

{ Type for general register.  }
type
  greg_t = Integer;
  {$EXTERNALSYM greg_t}

{ Number of general registers.  }
const
  NGREG = 19;
  {$EXTERNALSYM NGREG}

{ Container for all general registers.  }
type
  gregset_t = packed array[0..NGREG-1] of greg_t;
  {$EXTERNALSYM gregset_t}

{ Number of each register is the `gregset_t' array.  }
const
  REG_GS = 0;
  {$EXTERNALSYM REG_GS}
  REG_FS = 1;
  {$EXTERNALSYM REG_FS}
  REG_ES = 2;
  {$EXTERNALSYM REG_ES}
  REG_DS = 3;
  {$EXTERNALSYM REG_DS}
  REG_EDI = 4;
  {$EXTERNALSYM REG_EDI}
  REG_ESI = 5;
  {$EXTERNALSYM REG_ESI}
  REG_EBP = 6;
  {$EXTERNALSYM REG_EBP}
  REG_ESP = 7;
  {$EXTERNALSYM REG_ESP}
  REG_EBX = 8;
  {$EXTERNALSYM REG_EBX}
  REG_EDX = 9;
  {$EXTERNALSYM REG_EDX}
  REG_ECX = 10;
  {$EXTERNALSYM REG_ECX}
  REG_EAX = 11;
  {$EXTERNALSYM REG_EAX}
  REG_TRAPNO = 12;
  {$EXTERNALSYM REG_TRAPNO}
  REG_ERR = 13;
  {$EXTERNALSYM REG_ERR}
  REG_EIP = 14;
  {$EXTERNALSYM REG_EIP}
  REG_CS = 15;
  {$EXTERNALSYM REG_CS}
  REG_EFL = 16;
  {$EXTERNALSYM REG_EFL}
  REG_UESP = 17;
  {$EXTERNALSYM REG_UESP}
  REG_SS = 18;
  {$EXTERNALSYM REG_SS}


{ Definitions taken from the kernel headers.  }
type
  _libc_fpreg = {packed} record
    significand: packed array[0..4-1] of Word;
    exponent: Word;
  end;
  {$EXTERNALSYM _libc_fpreg}

  _libc_fpstate = {packed} record
    cw: LongWord;
    sw: LongWord;
    tag: LongWord;
    ipoff: LongWord;
    cssel: LongWord;
    dataoff: LongWord;
    datasel: LongWord;
    _st: packed array[0..8-1] of _libc_fpreg;
    status: LongWord;
  end;
  {$EXTERNALSYM _libc_fpstate}

{ Structure to describe FPU registers.  }
  fpregset_t = ^_libc_fpstate;
  {$EXTERNALSYM fpregset_t}

{ Context to describe whole processor state.  }
  mcontext_t = {packed} record
    gregs: gregset_t;
    { Due to Linux's history we have to use a pointer here.  The SysV/i386
       ABI requires a struct with the values.  }
    fpregs: fpregset_t;
    oldmask: LongWord;
    cr2: LongWord;
  end;
  {$EXTERNALSYM mcontext_t}

{ Userlevel context.  }
  PUserContext = ^TUserContext;
  ucontext = {packed} record
    uc_flags: LongWord;
    uc_link: PUserContext;
    uc_stack: stack_t;
    uc_mcontext: mcontext_t;
    uc_sigmask: __sigset_t;
    __fpregs_mem: _libc_fpstate;
  end;
  {$EXTERNALSYM ucontext}
  ucontext_t = ucontext;
  {$EXTERNALSYM ucontext_t}
  TUserContext = ucontext_t;

  
// Translated from ucontext.h

{ Get user context and store it in variable pointed to by UCP.  }
function getcontext(var __ucp: TUserContext): Integer; cdecl;
{$EXTERNALSYM getcontext}

{ Set user context from information of variable pointed to by UCP.  }
function setcontext(const __ucp: TUserContext): Integer; cdecl;
{$EXTERNALSYM setcontext}

{ Save current context in context variable pointed to by OUCP and set
   context from variable pointed to by UCP.  }
function swapcontext(var __oucp: TUserContext; const __ucp: TUserContext): Integer; cdecl;
{$EXTERNALSYM swapcontext}

{ Manipulate user context UCP to continue with calling functions FUNC
   and the ARGC-1 parameters following ARGC when the context is used
   the next time in `setcontext' or `swapcontext'.

   We cannot say anything about the parameters FUNC takes; `void'
   is as good as any other choice.  }

type
  TMakeContextProc = procedure; // Used anonymously in header file.

procedure makecontext(var __ucp: TUserContext; __func: TMakeContextProc; __argc: Integer); cdecl; varargs;
{$EXTERNALSYM makecontext}


// Translated from bits/msq.h

{ Define options for message queue functions.  }
const
  MSG_NOERROR = $1000;  { no error if message is too big }
  {$EXTERNALSYM MSG_NOERROR}
  MSG_EXCEPT  = $2000;  { recv any msg except of specified type }
  {$EXTERNALSYM MSG_EXCEPT}

{ Types used in the structure definition.  }
type
  msgqnum_t = LongWord;
  {$EXTERNALSYM msgqnum_t}
  msglen_t = LongWord;
  {$EXTERNALSYM msglen_t}


{ Structure of record for one message inside the kernel.
   The type `struct msg' is opaque.  }
  msqid_ds = {packed} record
    msg_perm: ipc_perm;         { structure describing operation permission }
    msg_stime: __time_t;        { time of last msgsnd command }
    __unused1: LongWord;
    msg_rtime: __time_t;        { time of last msgrcv command }
    __unused2: LongWord;
    msg_ctime: __time_t;        { time of last change }
    __unused3: LongWord;
    __msg_cbytes: LongWord;     { current number of bytes on queue }
    msg_qnum: msgqnum_t;        { number of messages currently on queue }
    msg_qbytes: msglen_t;       { max number of bytes allowed on queue }
    msg_lspid: __pid_t;         { pid of last msgsnd() }
    msg_lrpid: __pid_t;         { pid of last msgrcv() }
    __unused4: LongWord;
    __unused5: LongWord;
  end;
  {$EXTERNALSYM msqid_ds}
  TMsgQueueIdDesc = msqid_ds;
  PMsgQueueIdDesc = ^TMsgQueueIdDesc;


{ ipcs ctl commands }
const
  MSG_STAT = 11;
  {$EXTERNALSYM MSG_STAT}
  MSG_INFO = 12;
  {$EXTERNALSYM MSG_INFO}

{ buffer for msgctl calls IPC_INFO, MSG_INFO }
type
  msginfo = {packed} record
    msgpool: Integer;
    msgmap: Integer;
    msgmax: Integer;
    msgmnb: Integer;
    msgmni: Integer;
    msgssz: Integer;
    msgtql: Integer;
    msgseg: Word;
  end;
  {$EXTERNALSYM msginfo}


// Translated from sys/msg.h

{ The following System V style IPC functions implement a message queue
   system.  The definition is found in XPG2.  }

type
{ Template for struct to be used as argument for `msgsnd' and `msgrcv'.  }
  msgbuf = {packed} record
    mtype: Longint;                       { type of received/sent message }
    mtext: packed array[0..1-1] of Char;  { text of the message }
  end;
  {$EXTERNALSYM msgbuf}


{ Message queue control operation.  }
function msgctl(__msqid: Integer; __cmd: Integer; __buf: PMsgQueueIdDesc): Integer; cdecl;
{$EXTERNALSYM msgctl}

{ Get messages queue.  }
function msgget(__key: key_t; __msgflg: Integer): Integer; cdecl;
{$EXTERNALSYM msgget}

{ Receive message from message queue.  }
function msgrcv(__msqid: Integer; var Msg; __msgsz: size_t;
  __msgtyp: Longint; __msgflg: Integer): Integer; cdecl;
{$EXTERNALSYM msgrcv}

{ Send message to message queue.  }
function msgsnd(__msqid: Integer; const Msgp; __msgsz: size_t;
  __msgflg: Integer): Integer; cdecl;
{$EXTERNALSYM msgsnd}


// Translated from bits/statfs.h

type
  _statfs = {packed} record
    f_type: Integer;
    f_bsize: Integer;
    f_blocks: __fsblkcnt_t;
    f_bfree: __fsblkcnt_t;
    f_bavail: __fsblkcnt_t;
    f_files: __fsfilcnt_t;
    f_ffree: __fsfilcnt_t;
    f_fsid: __fsid_t;
    f_namelen: Integer;
    f_spare: packed array[0..6-1] of Integer;
  end;
  {.$EXTERNALSYM statfs} // Renamed from original to avoid identifer conflict
  TStatFs = _statfs;
  PStatFs = ^TStatFs;

  _statfs64 = {packed} record
    f_type: Integer;
    f_bsize: Integer;
    f_blocks: __fsblkcnt64_t;
    f_bfree: __fsblkcnt64_t;
    f_bavail: __fsblkcnt64_t;
    f_files: __fsfilcnt64_t;
    f_ffree: __fsfilcnt64_t;
    f_fsid: __fsid_t;
    f_namelen: Integer;
    f_spare: packed array[0..6-1] of Integer;
  end;
  {.$EXTERNALSYM statfs64} // Renamed from original to avoid identifer conflict
  TStatFs64 = _statfs64;
  PStatFs64 = ^TStatFs;


// Translated from sys/statfs.h

{ Return information about the filesystem on which FILE resides.  }
function statfs(__file: PChar; var __buf: TStatFs): Integer; cdecl;
{$EXTERNALSYM statfs}

function statfs64(__file: PChar; var __buf: TStatFs64): Integer; cdecl;
{$EXTERNALSYM statfs64}

{ Return information about the filesystem containing the file FILDES
   refers to.  }
function fstatfs(__fildes: Integer; var __buf: TStatFs): Integer; cdecl;
{$EXTERNALSYM fstatfs}

function fstatfs64(__fildes: Integer; var __buf: TStatFs64): Integer; cdecl;
{$EXTERNALSYM fstatfs64}


// Translated from bits/statvfs.h

type
  _statvfs = {packed} record
    f_bsize: LongWord;
    f_frsize: LongWord;
    f_blocks: __fsblkcnt_t;
    f_bfree: __fsblkcnt_t;
    f_bavail: __fsblkcnt_t;
    f_files: __fsfilcnt_t;
    f_ffree: __fsfilcnt_t;
    f_favail: __fsfilcnt_t;
    f_fsid: __fsid_t;
    f_flag: LongWord;
    f_namemax: LongWord;
    __f_spare: packed array[0..6-1] of Integer;
  end;
  {.$EXTERNALSYM statvfs} // Renamed from original to avoid identifer conflict
  TStatVFs = _statvfs;
  PStatVFs = ^TStatVFs;

  _statvfs64 = {packed} record
    f_bsize: LongWord;
    f_frsize: LongWord;
    f_blocks: __fsblkcnt64_t;
    f_bfree: __fsblkcnt64_t;
    f_bavail: __fsblkcnt64_t;
    f_files: __fsfilcnt64_t;
    f_ffree: __fsfilcnt64_t;
    f_favail: __fsfilcnt64_t;
    f_fsid: __fsid_t;
    f_flag: LongWord;
    f_namemax: LongWord;
    __f_spare: packed array[0..6-1] of Integer;
  end;
  {.$EXTERNALSYM statvfs} // Renamed from original to avoid identifer conflict
  TStatVFs64 = _statvfs64;
  PStatVFs64 = ^TStatVFs64;


{ Definitions for the flag in `f_flag'.  These definitions should be
   kept in sync which the definitions in <sys/mount.h>.  }
const
  ST_RDONLY = 1;                { Mount read-only.  }
  {$EXTERNALSYM ST_RDONLY}
  ST_NOSUID = 2;                { Ignore suid and sgid bits.  }
  {$EXTERNALSYM ST_NOSUID}
  ST_NODEV = 4;                 { Disallow access to device special files.  }
  {$EXTERNALSYM ST_NODEV}
  ST_NOEXEC = 8;                { Disallow program execution.  }
  {$EXTERNALSYM ST_NOEXEC}
  ST_SYNCHRONOUS = 16;          { Writes are synced at once.  }
  {$EXTERNALSYM ST_SYNCHRONOUS}
  ST_MANDLOCK = 64;             { Allow mandatory locks on an FS.  }
  {$EXTERNALSYM ST_MANDLOCK}
  ST_WRITE = 128;               { Write on file/directory/symlink.  }
  {$EXTERNALSYM ST_WRITE}
  ST_APPEND = 256;              { Append-only file.  }
  {$EXTERNALSYM ST_APPEND}
  ST_IMMUTABLE = 512;           { Immutable file.  }
  {$EXTERNALSYM ST_IMMUTABLE}
  ST_NOATIME = 1024;            { Do not update access times.  }
  {$EXTERNALSYM ST_NOATIME}
  ST_NODIRATIME = 1025;         { Do not update directory access times.  }
  {$EXTERNALSYM ST_NODIRATIME}


// Translated from sys/statvfs.h

{ Return information about the filesystem on which FILE resides.  }
function statvfs(__file: PChar; var __buf: TStatVFs): Integer; cdecl;
{$EXTERNALSYM statvfs}

function statvfs64(__file: PChar; var __buf: TStatVFs64): Integer; cdecl;
{$EXTERNALSYM statvfs64}

{ Return information about the filesystem containing the file FILDES refers to.  }
function fstatvfs(__fildes: Integer; var __buf: TStatVFs): Integer; cdecl;
{$EXTERNALSYM fstatvfs}

function fstatvfs64(__fildes: Integer; var __buf: TStatVFs64): Integer; cdecl;
{$EXTERNALSYM fstatvfs64}


// Translated from monetary.h

{ Formatting a monetary value according to the current locale.  }
function strfmon(__s: PChar; __maxsize: size_t; __format: PChar): ssize_t; cdecl; varargs;
{$EXTERNALSYM strfmon}

{ Formatting a monetary value according to the current locale.  }
function __strfmon_l(__s: PChar; __maxsize: size_t; loc: __locale_t; __format: PChar): ssize_t; cdecl; varargs;
{$EXTERNALSYM __strfmon_l}


// Translated from mcheck.h

{ Return values for `mprobe': these are the kinds of inconsistencies that
   `mcheck' enables detection of.  }
type
  mcheck_status =
  (
    MCHECK_DISABLED = -1,       { Consistency checking is not turned on.  }
    {$EXTERNALSYM MCHECK_DISABLED}
    MCHECK_OK = 0,              { Block is fine.  }
    {$EXTERNALSYM MCHECK_OK}
    MCHECK_FREE = 1,            { Block freed twice.  }
    {$EXTERNALSYM MCHECK_FREE}
    MCHECK_HEAD = 2,            { Memory before the block was clobbered.  }
    {$EXTERNALSYM MCHECK_HEAD}
    MCHECK_TAIL = 3             { Memory after the block was clobbered.  }
    {$EXTERNALSYM MCHECK_TAIL}
  );
  {$EXTERNALSYM mcheck_status}


{ Activate a standard collection of debugging hooks.  This must be called
   before `malloc' is ever called.  ABORTFUNC is called with an error code
   (see enum above) when an inconsistency is detected.  If ABORTFUNC is
   null, the standard function prints on stderr and then calls `abort'.  }
type
   TMemCheckAbortProc = procedure(MCheckStatus: mcheck_status); cdecl; // Used anonymously in header file

function mcheck(__abortfunc: TMemCheckAbortProc): Integer; cdecl;
{$EXTERNALSYM mcheck}

{ Similar to `mcheck´ but performs checks for all block whenever one of
   the memory handling functions is called.  This can be very slow.  }
function mcheck_pedantic(__abortfunc: TMemCheckAbortProc): Integer; cdecl;
{$EXTERNALSYM mcheck_pedantic}

{ Force check of all blocks now.  }
procedure mcheck_check_all(); cdecl;
{$EXTERNALSYM mcheck_check_all}

{ Check for aberrations in a particular malloc'd block.  You must have
   called `mcheck' already.  These are the same checks that `mcheck' does
   when you free or reallocate a block.  }
function mprobe(__ptr: Pointer): mcheck_status; cdecl;
{$EXTERNALSYM mprobe}

{ Activate a standard collection of tracing hooks.  }
procedure mtrace(); cdecl;
{$EXTERNALSYM mtrace}
procedure muntrace(); cdecl;
{$EXTERNALSYM muntrace}


// Translated from printf.h

type
  printf_info = {packed} record
    prec: Integer;                      { Precision.  }
    width: Integer;                     { Width.  }
    spec: wchar_t;                      { Format letter.  }
    __bitfield: Cardinal;
    (*
    unsigned int is_long_double:1;      { L flag.  }
    unsigned int is_short:1;            { h flag.  }
    unsigned int is_long:1;             { l flag.  }
    unsigned int alt:1;                 { # flag.  }
    unsigned int space:1;               { Space flag.  }
    unsigned int left:1;                { - flag.  }
    unsigned int showsign:1;            { + flag.  }
    unsigned int group:1;               { ' flag.  }
    unsigned int extra:1;               { For special use.  }
    unsigned int is_char:1;             { hh flag.  }
    unsigned int wide:1;                { Nonzero for wide character streams.  }
    unsigned int i18n:1;                { I flag.  }
    *)
    pad: wchar_t;                       { Padding character.  }
  end;
  {$EXTERNALSYM printf_info}
  TPrintfInfo = printf_info;
  PPrintfInfo = ^TPrintfInfo;


{ Type of a printf specifier-handler function.
   STREAM is the FILE on which to write output.
   INFO gives information about the format specification.
   ARGS is a vector of pointers to the argument data;
   the number of pointers will be the number returned
   by the associated arginfo function for the same INFO.

   The function should return the number of characters written,
   or -1 for errors.  }
type
  printf_function = function(__stream: PIOFile; const __info:
    printf_info; __args: PPointer): Integer; cdecl;
  {$EXTERNALSYM printf_function}

{ Type of a printf specifier-arginfo function.
   INFO gives information about the format specification.
   N, ARGTYPES, and return value are as for printf_parse_format.  }
type
  printf_arginfo_function = function(const __info: printf_info;
    __n: size_t; var __argtypes: Integer): Integer; cdecl;
  {$EXTERNALSYM printf_arginfo_function}


{ Register FUNC to be called to format SPEC specifiers; ARGINFO must be
   specified to determine how many arguments a SPEC conversion requires and
   what their types are.  }
type
  register_printf_function = function(__spec: Integer; __func: printf_function;
    __arginfo: printf_arginfo_function): Integer; cdecl;
  {$EXTERNALSYM register_printf_function}


{ Parse FMT, and fill in N elements of ARGTYPES with the
   types needed for the conversions FMT specifies.  Returns
   the number of arguments required by FMT.

   The ARGINFO function registered with a user-defined format is passed a
   `struct printf_info' describing the format spec being parsed.  A width
   or precision of INT_MIN means a `*' was used to indicate that the
   width/precision will come from an arg.  The function should fill in the
   array it is passed with the types of the arguments it wants, and return
   the number of arguments it wants.  }
type
  parse_printf_format = function(__fmt: PChar; __n: size_t;
    var __argtypes: Integer): size_t; cdecl;
  {$EXTERNALSYM parse_printf_format}


{ Codes returned by `parse_printf_format' for basic types.

   These values cover all the standard format specifications.
   Users can add new values after PA_LAST for their own types.  }
const
                                { C type: }
  PA_INT = 0;                   { int }
  {$EXTERNALSYM PA_INT}
  PA_CHAR = 1;                  { int, cast to char }
  {$EXTERNALSYM PA_CHAR}
  PA_WCHAR = 2;                 { wide char }
  {$EXTERNALSYM PA_WCHAR}
  PA_STRING = 3;                { const char *, a '\0'-terminated string }
  {$EXTERNALSYM PA_STRING}
  PA_WSTRING = 4;               { const wchar_t *, wide character string }
  {$EXTERNALSYM PA_WSTRING}
  PA_POINTER = 5;               { void * }
  {$EXTERNALSYM PA_POINTER}
  PA_FLOAT = 6;                 { float }
  {$EXTERNALSYM PA_FLOAT}
  PA_DOUBLE = 7;                { double }
  {$EXTERNALSYM PA_DOUBLE}
  PA_LAST = 8;
  {$EXTERNALSYM PA_LAST}


{ Flag bits that can be set in a type returned by `parse_printf_format'.  }
  PA_FLAG_MASK          = $ff00;
  {$EXTERNALSYM PA_FLAG_MASK}
  PA_FLAG_LONG_LONG     = (1 shl 8);
  {$EXTERNALSYM PA_FLAG_LONG_LONG}
  PA_FLAG_LONG_DOUBLE   = PA_FLAG_LONG_LONG;
  {$EXTERNALSYM PA_FLAG_LONG_DOUBLE}
  PA_FLAG_LONG          = (1 shl 9);
  {$EXTERNALSYM PA_FLAG_LONG}
  PA_FLAG_SHORT         = (1 shl 10);
  {$EXTERNALSYM PA_FLAG_SHORT}
  PA_FLAG_PTR           = (1 shl 11);
  {$EXTERNALSYM PA_FLAG_PTR}


{ Function which can be registered as `printf'-handlers.  }

{ Print floating point value using using abbreviations for the orders
   of magnitude used for numbers ('k' for kilo, 'm' for mega etc).  If
   the format specifier is a uppercase character powers of 1000 are
   used.  Otherwise powers of 1024.  }
function printf_size(__fp: PIOFile; const __info: printf_info;
  __args: PPointer): Integer; cdecl;
{$EXTERNALSYM printf_size}

{ This is the appropriate argument information function for `printf_size'.  }
function printf_size_info(__info: printf_info; __n: size_t;
  var __argtypes: Integer): Integer; cdecl;
{$EXTERNALSYM printf_size_info}


// Translated from libintl.h

{ Look up MSGID in the current default message catalog for the current
   LC_MESSAGES locale.  If not found, returns MSGID itself (the default
   text).  }
function gettext(__msgid: PChar): PChar; cdecl;
{$EXTERNALSYM gettext}

{ Look up MSGID in the DOMAINNAME message catalog for the current
   LC_MESSAGES locale.  }
function dgettext(__domainname: PChar; __msgid: PChar): PChar; cdecl;
{$EXTERNALSYM dgettext}

function __dgettext(__domainname: PChar; __msgid: PChar): PChar; cdecl;
{$EXTERNALSYM __dgettext}


{ Look up MSGID in the DOMAINNAME message catalog for the current CATEGORY
   locale.  }
function dcgettext(__domainname: PChar; __msgid: PChar; __category: Integer): PChar; cdecl;
{$EXTERNALSYM dcgettext}
function __dcgettext(__domainname: PChar; __msgid: PChar; __category: Integer): PChar; cdecl;
{$EXTERNALSYM __dcgettext}


{ Similar to `gettext' but select the plural form corresponding to the
   number N.  }
function ngettext(__msgid1, __msgid2: PChar; __n: LongWord): PChar; cdecl;
{$EXTERNALSYM ngettext}

{ Similar to `dgettext' but select the plural form corresponding to the
   number N.  }
function dngettext(__domainname: PChar; __msgid1, __msgid2: PChar; __n: LongWord): PChar; cdecl;
{$EXTERNALSYM dngettext}

{ Similar to `dcgettext' but select the plural form corresponding to the
   number N.  }
function dcngettext(__domainname: PChar; __msgid1, __msgid2: PChar;
  __n: LongWord; __category: Integer): PChar; cdecl;
{$EXTERNALSYM dcngettext}


{ Set the current default message catalog to DOMAINNAME.
   If DOMAINNAME is null, return the current default.
   If DOMAINNAME is "", reset to the default of "messages".  }
function textdomain(__domainname: PChar): PChar; cdecl;
{$EXTERNALSYM textdomain}

{ Specify that the DOMAINNAME message catalog will be found
   in DIRNAME rather than in the system locale data base.  }
function bindtextdomain(__domainname: PChar; __dirname: PChar): PChar; cdecl;
{$EXTERNALSYM bindtextdomain}

{ Specify the character encoding in which the messages from the
   DOMAINNAME message catalog will be returned.  }
function bind_textdomain_codeset(__domainname: PChar; __codeset: PChar): PChar; cdecl;
{$EXTERNALSYM bind_textdomain_codeset}


// Translated from shadow.h

const
{ Paths to the user database files.  }
  SHADOW = _PATH_SHADOW;
  {$EXTERNALSYM SHADOW}


{ Structure of the password file.  }
type
  spwd = {packed} record
    sp_namp: PChar;		{ Login name.  }
    sp_pwdp: PChar;		{ Encrypted password.  }
    sp_lstchg: Longint;		{ Date of last change.  }
    sp_min: Longint;		{ Minimum number of days between changes.  }
    sp_max: Longint;		{ Maximum number of days between changes.  }
    sp_warn: Longint;		{ Number of days to warn user to change
				   the password.  }
    sp_inact: Longint;		{ Number of days the account may be
				   inactive.  }
    sp_expire: Longint;		{ Number of days since 1970-01-01 until
				   account expires.  }
    sp_flag: LongWord;	{ Reserved.  }
  end;
  {$EXTERNALSYM spwd}
  TPasswordFileEntry = spwd;
  PPasswordFileEntry = ^TPasswordFileEntry;


{ Open database for reading.  }
procedure setspent(); cdecl;
{$EXTERNALSYM setspent}

{ Close database.  }
procedure endspent(); cdecl;
{$EXTERNALSYM endspent}

{ Get next entry from database, perhaps after opening the file.  }
function getspent(): PPasswordFileEntry; cdecl;
{$EXTERNALSYM getspent}

{ Get shadow entry matching NAME.  }
function getspnam(__name: PChar): PPasswordFileEntry; cdecl;
{$EXTERNALSYM getspnam}

{ Read shadow entry from STRING.  }
function sgetspent(__string: PChar): PPasswordFileEntry; cdecl;
{$EXTERNALSYM sgetspent}

{ Read next shadow entry from STREAM.  }
function fgetspent(__stream: PIOFile): PPasswordFileEntry; cdecl;
{$EXTERNALSYM fgetspent}

{ Write line containing shadow password entry to stream.  }
function putspent(const Entry: TPasswordFileEntry; __stream: PIOFile): Integer; cdecl;
{$EXTERNALSYM putspent}


{ Reentrant versions of some of the functions above.  }
function getspent_r(var __result_buf: spwd; __buffer: PChar;
   __buflen: size_t; var __result: PPasswordFileEntry): Integer; cdecl;
{$EXTERNALSYM getspent_r}

function getspnam_r(__name: PChar; var __result_buf: spwd; __buffer: PChar;
   __buflen: size_t; var __result: PPasswordFileEntry): Integer; cdecl;
{$EXTERNALSYM getspnam_r}

function sgetspent_r(__string: PChar; var __result_buf: spwd; __buffer: PChar;
  __buflen: size_t; var __result: PPasswordFileEntry): Integer; cdecl;
{$EXTERNALSYM sgetspent_r}

function fgetspent_r(__stream: PIOFile; var __result_buf: spwd; __buffer: PChar;
  __buflen: size_t; var __result: PPasswordFileEntry): Integer; cdecl;
{$EXTERNALSYM fgetspent_r}

{ Protect password file against multi writers.  }
function lckpwdf(): Integer; cdecl;
{$EXTERNALSYM lckpwdf}

{ Unlock password file.  }
function ulckpwdf(): Integer; cdecl;
{$EXTERNALSYM ulckpwdf}


// Translated from fmtmsg.h

const
{ Values to control `fmtmsg' function.  }

  MM_HARD = $001;      { Source of the condition is hardware.  }
  {$EXTERNALSYM MM_HARD}
  MM_SOFT = $002;      { Source of the condition is software.  }
  {$EXTERNALSYM MM_SOFT}
  MM_FIRM = $004;      { Source of the condition is firmware.  }
  {$EXTERNALSYM MM_FIRM}
  MM_APPL = $008;      { Condition detected by application.  }
  {$EXTERNALSYM MM_APPL}
  MM_UTIL = $010;      { Condition detected by utility.  }
  {$EXTERNALSYM MM_UTIL}
  MM_OPSYS = $020;     { Condition detected by operating system.  }
  {$EXTERNALSYM MM_OPSYS}
  MM_RECOVER = $040;   { Recoverable error.  }
  {$EXTERNALSYM MM_RECOVER}
  MM_NRECOV = $080;    { Non-recoverable error.  }
  {$EXTERNALSYM MM_NRECOV}
  MM_PRINT = $100;     { Display message in standard error.  }
  {$EXTERNALSYM MM_PRINT}
  MM_CONSOLE = $200;   { Display message on system console.  }
  {$EXTERNALSYM MM_CONSOLE}


{ Values to be for SEVERITY parameter of `fmtmsg'.  }

  MM_NOSEV = 0;         { No severity level provided for the message.  }
  {$EXTERNALSYM MM_NOSEV}
  MM_HALT = 1;          { Error causing application to halt.  }
  {$EXTERNALSYM MM_HALT}
  MM_ERROR = 2;         { Application has encountered a non-fatal fault.  }
  {$EXTERNALSYM MM_ERROR}
  MM_WARNING = 3;       { Application has detected unusual non-error condition.  }
  {$EXTERNALSYM MM_WARNING}
  MM_INFO = 4;          { Informative message.  }
  {$EXTERNALSYM MM_INFO}


{ Macros which can be used as null values for the arguments of `fmtmsg'.  }
  MM_NULLLBL       = PChar(nil);
  {$EXTERNALSYM MM_NULLLBL}
  MM_NULLSEV       = 0;
  {$EXTERNALSYM MM_NULLSEV}
  MM_NULLMC        = Longint(0);
  {$EXTERNALSYM MM_NULLMC}
  MM_NULLTXT       = PChar(0);
  {$EXTERNALSYM MM_NULLTXT}
  MM_NULLACT       = PChar(0);
  {$EXTERNALSYM MM_NULLACT}
  MM_NULLTAG       = PChar(0);
  {$EXTERNALSYM MM_NULLTAG}


{ Possible return values of `fmtmsg'.  }
  MM_NOTOK = -1;
  {$EXTERNALSYM MM_NOTOK}
  MM_OK = 0;
  {$EXTERNALSYM MM_OK}
  MM_NOMSG = 1;
  {$EXTERNALSYM MM_NOMSG}
  MM_NOCON = 4;
  {$EXTERNALSYM MM_NOCON}


{ Print message with given CLASSIFICATION, LABEL, SEVERITY, TEXT, ACTION
   and TAG to console or standard error.  }
function fmtmsg(__classification: Longint; __label: PChar; __severity: Integer;
  __text: PChar; __action: PChar; __tag: PChar): Integer; cdecl;
{$EXTERNALSYM fmtmsg}

{ Add or remove severity level.  }
function addseverity(__severity: Integer; __string: PChar): Integer; cdecl;
{$EXTERNALSYM addseverity}


// Translated from sys/quota.h

{
 * Convert diskblocks to blocks and the other way around.
 * currently only to fool the BSD source. :-)
 }
function dbtob(num: Cardinal): Cardinal;
{$EXTERNALSYM dbtob}
function btodb(num: Cardinal): Cardinal;
{$EXTERNALSYM btodb}

{
 * Convert count of filesystem blocks to diskquota blocks, meant
 * for filesystems where i_blksize != BLOCK_SIZE
 }
function fs_to_dq_blocks(num, blksize: Cardinal): quad_t;
{$EXTERNALSYM fs_to_dq_blocks}

{
 * Definitions for disk quotas imposed on the average user
 * (big brother finally hits Linux).
 *
 * The following constants define the amount of time given a user
 * before the soft limits are treated as hard limits (usually resulting
 * in an allocation failure). The timer is started when the user crosses
 * their soft limit, it is reset when they go below their soft limit.
 }
const
  MAX_IQ_TIME = 604800;  { (7*24*60*60) 1 week }
  {$EXTERNALSYM MAX_IQ_TIME}
  MAX_DQ_TIME = 604800;  { (7*24*60*60) 1 week }
  {$EXTERNALSYM MAX_DQ_TIME}

  MAXQUOTAS = 2;
  {$EXTERNALSYM MAXQUOTAS}
  USRQUOTA  = 0;     { element used for user quotas }
  {$EXTERNALSYM USRQUOTA}
  GRPQUOTA  = 1;     { element used for group quotas }
  {$EXTERNALSYM GRPQUOTA}

{
 * Definitions for the default names of the quotas files.
 }
const (* Not literal, but close *)
  INITQFNAMES: array[0..2] of PChar = (
   'user',     { USRQUOTA }
   'group',    { GRPQUOTA }
   'undefined');
  {$EXTERNALSYM INITQFNAMES}

const
  QUOTAFILENAME = 'quota';
  {$EXTERNALSYM QUOTAFILENAME}
  QUOTAGROUP    = 'staff';
  {$EXTERNALSYM QUOTAGROUP}

  NR_DQHASH  = 43;       { Just an arbitrary number any suggestions ? }
  {$EXTERNALSYM NR_DQHASH}
  NR_DQUOTS  = 256;      { Number of quotas active at one time }
  {$EXTERNALSYM NR_DQUOTS}

{
 * Command definitions for the 'quotactl' system call.
 * The commands are broken into a main command defined below
 * and a subcommand that is used to convey the type of
 * quota that is being manipulated (see above).
 }
  SUBCMDMASK  = $00ff;
  {$EXTERNALSYM SUBCMDMASK}
  SUBCMDSHIFT = 8;
  {$EXTERNALSYM SUBCMDSHIFT}

function QCMD(cmd, _type: Cardinal): Cardinal;
{$EXTERNALSYM QCMD}

const
  Q_QUOTAON  = $0100;   { enable quotas }
  {$EXTERNALSYM Q_QUOTAON}
  Q_QUOTAOFF = $0200;   { disable quotas }
  {$EXTERNALSYM Q_QUOTAOFF}
  Q_GETQUOTA = $0300;   { get limits and usage }
  {$EXTERNALSYM Q_GETQUOTA}
  Q_SETQUOTA = $0400;   { set limits and usage }
  {$EXTERNALSYM Q_SETQUOTA}
  Q_SETUSE   = $0500;   { set usage }
  {$EXTERNALSYM Q_SETUSE}
  Q_SYNC     = $0600;   { sync disk copy of a filesystems quotas }
  {$EXTERNALSYM Q_SYNC}
  Q_SETQLIM  = $0700;   { set limits }
  {$EXTERNALSYM Q_SETQLIM}
  Q_GETSTATS = $0800;   { get collected stats }
  {$EXTERNALSYM Q_GETSTATS}
  Q_RSQUASH  = $1000;   { set root_squash option }
  {$EXTERNALSYM Q_RSQUASH}

{
 * The following structure defines the format of the disk quota file
 * (as it appears on disk) - the file is an array of these structures
 * indexed by user or group number.
 }
type
  dqblk = {packed} record
    dqb_bhardlimit: u_int32_t;  { absolute limit on disk blks alloc }
    dqb_bsoftlimit: u_int32_t;  { preferred limit on disk blks }
    dqb_curblocks: u_int32_t;   { current block count }
    dqb_ihardlimit: u_int32_t;  { maximum # allocated inodes }
    dqb_isoftlimit: u_int32_t;  { preferred inode limit }
    dqb_curinodes: u_int32_t;   { current # allocated inodes }
    dqb_btime: time_t;          { time limit for excessive disk use }
    dqb_itime: time_t;          { time limit for excessive files }
  end;
  {$EXTERNALSYM dqblk}

function dqoff(UID: loff_t): quad_t;
{$EXTERNALSYM dqoff}

type
  dqstats = {packed} record
    lookups: u_int32_t;
    drops: u_int32_t;
    reads: u_int32_t;
    writes: u_int32_t;
    cache_hits: u_int32_t;
    pages_allocated: u_int32_t;
    allocated_dquots: u_int32_t;
    free_dquots: u_int32_t;
    syncs: u_int32_t;
  end;
  {$EXTERNALSYM dqstats}


function quotactl(__cmd: Integer; __special: PChar; __id: Integer; __addr: caddr_t): Integer; cdecl;
{$EXTERNALSYM quotactl}


// Translated from sys/timeb.h

{ Structure returned by the `ftime' function.  }
type
  timeb = {packed} record
    time: time_t;               { Seconds since epoch, as from `time'.  }
    millitm: Word;              { Additional milliseconds.  }
    timezone: Smallint;         { Minutes west of GMT.  }
    dstflag: Smallint;          { Nonzero if Daylight Savings Time used.  }
  end;
  {$EXTERNALSYM timeb}

{ Fill in TIMEBUF with information about the current time.  }

function ftime(var __timebuf: timeb): Integer; cdecl;
{$EXTERNALSYM ftime}


// Translated from perm.h

{ Set port input/output permissions.  }
function ioperm(__from: LongWord; __num: LongWord; __turn_on: Integer): Integer; cdecl;
{$EXTERNALSYM ioperm}

{ Change I/O privilege level.  }
function iopl(__level: Integer): Integer; cdecl;
{$EXTERNALSYM iopl}


// Translated from sys/user.h

(*
  Intentionally left out:
  "The whole purpose of this file is for GDB and GDB only. "
*)


// Translated from sys/swap.h

{ The swap priority is encoded as:
   (prio << SWAP_FLAG_PRIO_SHIFT) & SWAP_FLAG_PRIO_MASK
}
const
  SWAP_FLAG_PREFER      = $8000; { Set if swap priority is specified. }
  {$EXTERNALSYM SWAP_FLAG_PREFER}
  SWAP_FLAG_PRIO_MASK   = $7fff;
  {$EXTERNALSYM SWAP_FLAG_PRIO_MASK}
  SWAP_FLAG_PRIO_SHIFT  = 0;
  {$EXTERNALSYM SWAP_FLAG_PRIO_SHIFT}


{ Make the block special device PATH available to the system for swapping.
   This call is restricted to the super-user.  }
function swapon(__path: PChar; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM swapon}

{ Stop using block special device PATH for swapping.  }
function swapoff(__path: PChar): Integer; cdecl;
{$EXTERNALSYM swapoff}


// Translated from sys/sendfile.h

{ Send COUNT bytes from file associated with IN_FD starting at OFFSET to
   descriptor OUT_FD.  }
function sendfile(__out_fd: Integer; __in_fd: Integer; var offset: off_t;
  __count: size_t): ssize_t; cdecl;
{$EXTERNALSYM sendfile}


// Translated from sys/reboot.h

const
{ Perform a hard reset now.  }
  RB_AUTOBOOT = $01234567;
  {$EXTERNALSYM RB_AUTOBOOT}

{ Halt the system.  }
  RB_HALT_SYSTEM = $cdef0123;
  {$EXTERNALSYM RB_HALT_SYSTEM}

{ Enable reboot using Ctrl-Alt-Delete keystroke.  }
  RB_ENABLE_CAD = $89abcdef;
  {$EXTERNALSYM RB_ENABLE_CAD}

{ Disable reboot using Ctrl-Alt-Delete keystroke.  }
  RB_DISABLE_CAD = 0;
  {$EXTERNALSYM RB_DISABLE_CAD}

{ Stop system and switch power off if possible.  }
  RB_POWER_OFF = $4321fedc;
  {$EXTERNALSYM RB_POWER_OFF}

{ Reboot or halt the system.  }
function reboot(__howto: Integer): Integer; cdecl;
{$EXTERNALSYM reboot}


// Translated from aio.h

type
{ Asynchronous I/O control block.  }
  PAsyncIoCB = ^TPAsyncIoCB;
  aiocb = {packed} record
    aio_fildes: Integer;         { File desriptor.  }
    aio_lio_opcode: Integer;     { Operation to be performed.  }
    aio_reqprio: Integer;        { Request priority offset.  }
    aio_buf: Pointer;            { Location of buffer.  }
    aio_nbytes: size_t;          { Length of transfer.  }
    aio_sigevent: sigevent;      { Signal number and value.  }

    { Internal members.  }
    __next_prio: PAsyncIoCB;
    __abs_prio: Integer;
    __policy: Integer;
    __error_code: Integer;
    __return_value: __ssize_t;

    aio_offset: __off_t;         { File offset.  }
    __pad: packed array[0..SizeOf(__off64_t) - SizeOf(__off_t)-1] of Byte;
    __unused: packed array[0..32-1] of Byte;
  end;
  {$EXTERNALSYM aiocb}
  TPAsyncIoCB = aiocb;
  PPAsyncIoCB = ^PAsyncIoCB;

{ The same for the 64bit offsets.  Please note that the members aio_fildes
   to __return_value have to be the same in aiocb and aiocb64.  }
  PAsyncIoCB64 = ^TAsyncIoCB64;
  aiocb64 = {packed} record
    aio_fildes: Integer;         { File desriptor.  }
    aio_lio_opcode: Integer;     { Operation to be performed.  }
    aio_reqprio: Integer;        { Request priority offset.  }
    aio_buf: Pointer;            { Location of buffer.  }
    aio_nbytes: size_t;          { Length of transfer.  }
    aio_sigevent: sigevent;      { Signal number and value.  }

    { Internal members.  }
    __next_prio: PAsyncIoCB64;
    __abs_prio: Integer;
    __policy: Integer;
    __error_code: Integer;
    __return_value: __ssize_t;

    aio_offset: __off64_t;       { File offset.  }
    __unused: packed array[0..32-1] of Byte;
  end;
  {$EXTERNALSYM aiocb64}
  TAsyncIoCB64 = aiocb64;
  PPAsyncIoCB64 = ^PAsyncIoCB64;

{ To customize the implementation one can use the following struct.
   This implementation follows the one in Irix.  }
  aioinit = {packed} record
    aio_threads: Integer;       { Maximal number of threads.  }
    aio_num: Integer;           { Number of expected simultanious requests. }
    aio_locks: Integer;         { Not used.  }
    aio_usedba: Integer;        { Not used.  }
    aio_debug: Integer;         { Not used.  }
    aio_numusers: Integer;      { Not used.  }
    aio_idle_time: Integer;     { Number of seconds before idle thread terminates.  }
    aio_reserved: Integer;
  end;
  {$EXTERNALSYM aioinit}


const
{ Return values of cancelation function.  }
  AIO_CANCELED = 0;
  {$EXTERNALSYM AIO_CANCELED}
  AIO_NOTCANCELED = 1;
  {$EXTERNALSYM AIO_NOTCANCELED}
  AIO_ALLDONE = 2;
  {$EXTERNALSYM AIO_ALLDONE}


{ Operation codes for `aio_lio_opcode'.  }
  LIO_READ = 0;
  {$EXTERNALSYM LIO_READ}
  LIO_WRITE = 1;
  {$EXTERNALSYM LIO_WRITE}
  LIO_NOP = 2;
  {$EXTERNALSYM LIO_NOP}


{ Synchronization options for `lio_listio' function.  }
  LIO_WAIT = 0;
  {$EXTERNALSYM LIO_WAIT}
  LIO_NOWAIT = 1;
  {$EXTERNALSYM LIO_NOWAIT}


{ Allow user to specify optimization.  }
procedure aio_init(const __init: aioinit); cdecl;
{$EXTERNALSYM aio_init}

{ Enqueue read request for given number of bytes and the given priority.  }
function aio_read(var __aiocbp: aiocb): Integer; cdecl;
{$EXTERNALSYM aio_read}
{ Enqueue write request for given number of bytes and the given priority.  }
function aio_write(var __aiocbp: aiocb): Integer; cdecl;
{$EXTERNALSYM aio_write}

{ Initiate list of I/O requests.  }
function lio_listio(__mode: Integer; __list: PPAsyncIoCB;
  __nent: Integer; var __sig: sigevent): Integer; cdecl;
{$EXTERNALSYM lio_listio}

{ Retrieve error status associated with AIOCBP.  }
function aio_error(const __aiocbp: aiocb): Integer; cdecl;
{$EXTERNALSYM aio_error}
{ Return status associated with AIOCBP.  }
function aio_return(var __aiocbp: aiocb): __ssize_t; cdecl;
{$EXTERNALSYM aio_return}

{ Try to cancel asynchronous I/O requests outstanding against file
   descriptor FILDES.  }
function aio_cancel(__fildes: Integer; var __aiocbp: aiocb): Integer; cdecl;
{$EXTERNALSYM aio_cancel}

{ Suspend calling thread until at least one of the asynchronous I/O
   operations referenced by LIST has completed.  }
function aio_suspend(__list: PPAsyncIoCB; __nent: Integer;
  const __timeout: timespec): Integer; cdecl;
{$EXTERNALSYM aio_suspend}

{ Force all operations associated with file desriptor described by
   `aio_fildes' member of AIOCBP.  }
function aio_fsync(__operation: Integer; var __aiocbp: aiocb): Integer; cdecl;
{$EXTERNALSYM aio_fsync}

function aio_read64(var __aiocbp: aiocb64): Integer; cdecl;
{$EXTERNALSYM aio_read64}
function aio_write64(var __aiocbp: aiocb64): Integer; cdecl;
{$EXTERNALSYM aio_write64}

function lio_listio64(__mode: Integer; __list: PPAsyncIoCB64;
  __nent: Integer; var __sig: sigevent): Integer; cdecl;
{$EXTERNALSYM lio_listio64}

function aio_error64(const __aiocbp: aiocb64): Integer; cdecl;
{$EXTERNALSYM aio_error64}
function aio_return64(var __aiocbp: aiocb64): __ssize_t; cdecl;
{$EXTERNALSYM aio_return64}

function aio_cancel64(__fildes: Integer; var __aiocbp: aiocb64): Integer; cdecl;
{$EXTERNALSYM aio_cancel64}

function aio_suspend64(__list: PPAsyncIoCB64; __nent: Integer;
  const __timeout: timespec): Integer; cdecl;
{$EXTERNALSYM aio_suspend64}

function aio_fsync64(__operation: Integer; var __aiocbp: aiocb64): Integer; cdecl;
{$EXTERNALSYM aio_fsync64}


// Translated from aliases.h

{ Structure to represent one entry of the alias data base.  }
type
  aliasent = {packed} record
    alias_name: PChar;
    alias_members_len: size_t;
    alias_members: PPChar;
    alias_local: Integer;
  end;
  {$EXTERNALSYM aliasent}
  TAliasEntry = aliasent;
  PAliasEntry = ^TAliasEntry;

{ Open alias data base files.  }
procedure setaliasent(); cdecl;
{$EXTERNALSYM setaliasent}

{ Close alias data base files.  }
procedure endaliasent(); cdecl;
{$EXTERNALSYM endaliasent}

{ Get the next entry from the alias data base.  }
function getaliasent(): PAliasEntry; cdecl;
{$EXTERNALSYM getaliasent}

{ Get the next entry from the alias data base and put it in RESULT_BUF.  }
function getaliasent_r(var __result_buf: aliasent; __buffer: PChar; __buflen: size_t;
  var __result: PAliasEntry): Integer; cdecl;
{$EXTERNALSYM getaliasent_r}

{ Get alias entry corresponding to NAME.  }
function getaliasbyname(__name: PChar): PAliasEntry; cdecl;
{$EXTERNALSYM getaliasbyname}

{ Get alias entry corresponding to NAME and put it in RESULT_BUF.  }
function getaliasbyname_r(__name: PChar; var __result_buf: aliasent;
  __buffer: PChar; __buflen: size_t; var __result: PAliasEntry): Integer; cdecl;
{$EXTERNALSYM getaliasbyname_r}


// Translated from glob.h

const
{ Bits set in the FLAGS argument to `glob'.  }
  GLOB_ERR      = (1 shl 0);  { Return on read errors.  }
  {$EXTERNALSYM GLOB_ERR}
  GLOB_MARK     = (1 shl 1);  { Append a slash to each name.  }
  {$EXTERNALSYM GLOB_MARK}
  GLOB_NOSORT   = (1 shl 2);  { Don't sort the names.  }
  {$EXTERNALSYM GLOB_NOSORT}
  GLOB_DOOFFS   = (1 shl 3);  { Insert PGLOB->gl_offs NULLs.  }
  {$EXTERNALSYM GLOB_DOOFFS}
  GLOB_NOCHECK  = (1 shl 4);  { If nothing matches, return the pattern.  }
  {$EXTERNALSYM GLOB_NOCHECK}
  GLOB_APPEND   = (1 shl 5);  { Append to results of a previous call.  }
  {$EXTERNALSYM GLOB_APPEND}
  GLOB_NOESCAPE = (1 shl 6);  { Backslashes don't quote metacharacters.  }
  {$EXTERNALSYM GLOB_NOESCAPE}
  GLOB_PERIOD   = (1 shl 7);  { Leading `.' can be matched by metachars.  }
  {$EXTERNALSYM GLOB_PERIOD}

  GLOB_MAGCHAR  = (1 shl 8);  { Set in gl_flags if any metachars seen.  }
  {$EXTERNALSYM GLOB_MAGCHAR}
  GLOB_ALTDIRFUNC = (1 shl 9);{ Use gl_opendir et al functions.  }
  {$EXTERNALSYM GLOB_ALTDIRFUNC}
  GLOB_BRACE    = (1 shl 10);  // Expand "{a,b}" to "a" "b".
  {$EXTERNALSYM GLOB_BRACE}
  GLOB_NOMAGIC  = (1 shl 11);  { If no magic chars, return the pattern.  }
  {$EXTERNALSYM GLOB_NOMAGIC}
  GLOB_TILDE    = (1 shl 12);  { Expand ~user and ~ to home directories. }
  {$EXTERNALSYM GLOB_TILDE}
  GLOB_ONLYDIR  = (1 shl 13);  { Match only directories.  }
  {$EXTERNALSYM GLOB_ONLYDIR}
  GLOB_TILDE_CHECK = (1 shl 14);{ Like GLOB_TILDE but return an error
                                 if the user name is not available.  }
  {$EXTERNALSYM GLOB_TILDE_CHECK}

  __GLOB_FLAGS = (GLOB_ERR or GLOB_MARK or GLOB_NOSORT or GLOB_DOOFFS or
                  GLOB_NOESCAPE or GLOB_NOCHECK or GLOB_APPEND or
                  GLOB_PERIOD or GLOB_ALTDIRFUNC or GLOB_BRACE or
                  GLOB_NOMAGIC or GLOB_TILDE or GLOB_ONLYDIR or GLOB_TILDE_CHECK);
  {$EXTERNALSYM __GLOB_FLAGS}

{ Error returns from `glob'.  }
  GLOB_NOSPACE = 1;     { Ran out of memory.  }
  {$EXTERNALSYM GLOB_NOSPACE}
  GLOB_ABORTED = 2;     { Read error.  }
  {$EXTERNALSYM GLOB_ABORTED}
  GLOB_NOMATCH = 3;     { No matches found.  }
  {$EXTERNALSYM GLOB_NOMATCH}
  GLOB_NOSYS   = 4;     { Not implemented.  }
  {$EXTERNALSYM GLOB_NOSYS}

{ Previous versions of this file defined GLOB_ABEND instead of
   GLOB_ABORTED.  Provide a compatibility definition here.  }
  GLOB_ABEND   = GLOB_ABORTED;
  {$EXTERNALSYM GLOB_ABEND}


{ Structure describing a globbing run.  }
type
  TGlobClosedirProc = procedure(Param: Pointer); cdecl; // Used anonymously in header file
  TGlobReaddirProc = function(Param: Pointer): PDirEnt; cdecl; // Used anonymously in header file
  TGlobOpendirProc = function(Param: PChar): __ptr_t; cdecl; // Used anonymously in header file
  TGlobStatProc = function(Param1: PChar; Param2: PStatBuf): Integer; cdecl; // Used anonymously in header file

  glob_t = {packed} record
    gl_pathc: size_t;           { Count of paths matched by the pattern.  }
    gl_pathv: PPChar;           { List of matched pathnames.  }
    gl_offs: size_t;            { Slots to reserve in `gl_pathv'.  }
    gl_flags: Integer;          { Set to FLAGS, maybe | GLOB_MAGCHAR.  }

    { If the GLOB_ALTDIRFUNC flag is set, the following functions
       are used instead of the normal file access functions.  }
    gl_closedir: TGlobClosedirProc;
    gl_readdir: TGlobReaddirProc;
    gl_opendir: TGlobOpendirProc;
    gl_lstat: TGlobStatProc;
    gl_stat: TGlobStatProc;
  end;
  {$EXTERNALSYM glob_t}
  TGlobData = glob_t;
  PGlobData = ^TGlobData;

  TGlobReaddir64Proc = function(Param: Pointer): PDirEnt64; cdecl; // Used anonymously in header file
  TGlobStat64Proc = function(Param1: PChar; Param2: PStatBuf64): Integer; cdecl; // Used anonymously in header file

  glob64_t = {packed} record
    gl_pathc: size_t;
    gl_pathv: PPChar;
    gl_offs: size_t;
    gl_flags: Integer;

    { If the GLOB_ALTDIRFUNC flag is set, the following functions
       are used instead of the normal file access functions.  }
    gl_closedir: TGlobClosedirProc;
    gl_readdir: TGlobReaddir64Proc;
    gl_opendir: TGlobOpendirProc;
    gl_lstat: TGlobStat64Proc;
    gl_stat: TGlobStat64Proc;
  end;
  {$EXTERNALSYM glob64_t}
  TGlob64Data = glob_t;
  PGlob64Data = ^TGlob64Data;

  TGlobErrFunc = function(PathName: PChar; ErrNo: Integer): Integer; cdecl; // Used anonymously in header file

{ Do glob searching for PATTERN, placing results in PGLOB.
   The bits defined above may be set in FLAGS.
   If a directory cannot be opened or read and ERRFUNC is not nil,
   it is called with the pathname that caused the error, and the
   `errno' value from the failing call; if it returns non-zero
   `glob' returns GLOB_ABEND; if it returns zero, the error is ignored.
   If memory cannot be allocated for PGLOB, GLOB_NOSPACE is returned.
   Otherwise, `glob' returns zero.  }

function glob(__pattern: PChar; __flags: Integer; __errfunc: TGlobErrFunc;
  __pglob: PGlobData): Integer; cdecl;
{$EXTERNALSYM glob}

{ Free storage allocated in PGLOB by a previous `glob' call.  }
procedure globfree(__pglob: PGlobData); cdecl;
{$EXTERNALSYM globfree}

function glob64(__pattern: PChar; __flags: Integer; __errfunc: TGlobErrFunc;
  __pglob: PGlob64Data): Integer; cdecl;
{$EXTERNALSYM glob64}

procedure globfree64(__pglob: PGlob64Data); cdecl;
{$EXTERNALSYM globfree64}


{ Return nonzero if PATTERN contains any metacharacters.
   Metacharacters can be quoted with backslashes if QUOTE is nonzero.

   This function is not part of the interface specified by POSIX.2
   but several programs want to use it.  }
function glob_pattern_p(__pattern: PChar; __quote: Integer): Integer; cdecl;
{$EXTERNALSYM glob_pattern_p}


// Translated from crypt.h

(*
  A number of functions have been declared elsewhere already:

    extern char *crypt (__const char *__key, __const char *__salt) __THROW;
    extern void setkey (__const char *__key) __THROW;
    extern void encrypt (char *__block, int __edflag) __THROW;
*)

{ Reentrant versions of the functions above.  The additional argument
   points to a structure where the results are placed in.  }
type
  crypt_data = {packed} record
    keysched: packed array[0..(16 * 8)-1] of Byte;
    sb0: packed array[0..32768-1] of Byte;
    sb1: packed array[0..32768-1] of Byte;
    sb2: packed array[0..32768-1] of Byte;
    sb3: packed array[0..32768-1] of Byte;
    { end-of-aligment-critical-data }
    crypt_3_buf: packed array[0..14-1] of Byte;
    current_salt: packed array[0..2-1] of Byte;
    current_saltbits: Longint;
    direction, initialized: Integer;
  end;
  {$EXTERNALSYM crypt_data}
  TCryptData = crypt_data;
  PCryptData = ^TCryptData;

function crypt_r(__key: PChar; __salt: PChar; data: PCryptData): PChar; cdecl;
{$EXTERNALSYM crypt_r}

procedure setkey_r(__key: PChar; data: PCryptData); cdecl;
{$EXTERNALSYM setkey_r}

procedure encrypt_r(__block: PChar; __edflag: Integer; data: PCryptData); cdecl;
{$EXTERNALSYM encrypt_r}


// Translated from sys/fsuid.h

{ Change uid used for file access control to UID, without affecting
   other privileges (such as who can send signals at the process).  }
function setfsuid(__uid: __uid_t): Integer; cdecl;
{$EXTERNALSYM setfsuid}

{ Ditto for group id. }
function setfsgid(__gid: __gid_t): Integer; cdecl;
{$EXTERNALSYM setfsgid}


// Translated from sys/klog.h

{ Control the kernel's logging facility.  This corresponds exactly to
   the kernel's syslog system call, but that name is easily confused
   with the user-level syslog facility, which is something completely
   different.  }
function klogctl(__type: Integer; __bufp: PChar; __len: Integer): Integer; cdecl;
{$EXTERNALSYM klogctl}


// Translated from sys/kdaemon.h

{ Start, flush, or tune the kernel's buffer flushing daemon.  }
function bdflush(__func: Integer; __data: Longint): Integer; cdecl;
{$EXTERNALSYM bdflush}


// Translated from sys/acct.h

const
  ACCT_COMM = 16;
  {$EXTERNALSYM ACCT_COMM}

{
  comp_t is a 16-bit "floating" point number with a 3-bit base 8
  exponent and a 13-bit fraction. See linux/kernel/acct.c for the
  specific encoding system used.
}

type
  comp_t = u_int16_t;
  {$EXTERNALSYM comp_t}

  _acct = {packed} record
    ac_flag: Shortint;        { Accounting flags.  }
    ac_uid: u_int16_t;        { Accounting user ID.  }
    ac_gid: u_int16_t;        { Accounting group ID.  }
    ac_tty: u_int16_t;        { Controlling tty.  }
    ac_btime: u_int32_t;      { Beginning time.  }
    ac_utime: comp_t;         { Accounting user time.  }
    ac_stime: comp_t;         { Accounting system time.  }
    ac_etime: comp_t;         { Accounting elapsed time.  }
    ac_mem: comp_t;           { Accounting average memory usage.  }
    ac_io: comp_t;            { Accounting chars transferred.  }
    ac_rw: comp_t;            { Accounting blocks read or written.  }
    ac_minflt: comp_t;        { Accounting minor pagefaults.  }
    ac_majflt: comp_t;        { Accounting major pagefaults.  }
    ac_swaps: comp_t;         { Accounting number of swaps.  }
    ac_exitcode: u_int32_t;   { Accounting process exitcode.  }
    ac_comm: packed array[0..ACCT_COMM+1 - 1] of Char; { Accounting command name.  }
    ac_pad: packed array[0..10-1] of Byte;			{ Accounting padding bytes.  }
  end;
  {.$EXTERNALSYM _acct} // Renamed from acct in header file
  TAccountingRecord = _acct;

const
  AFORK  = $01;      { Has executed fork, but no exec.  }
  {$EXTERNALSYM AFORK}
  ASU    = $02;      { Used super-user privileges.  }
  {$EXTERNALSYM ASU}
  ACORE  = $08;      { Dumped core.  }
  {$EXTERNALSYM ACORE}
  AXSIG  = $10;      { Killed by a signal.  }
  {$EXTERNALSYM AXSIG}

const
  AHZ = 100;
  {$EXTERNALSYM AHZ}

(*
Already translated as part of unistd.h
{ Switch process accounting on and off.  }
extern int acct (__const char *__filename) __THROW;
*)


// Translated from bits/stropts.h

(* Type moved from stropts.h to resolve dependency. *)
type
  t_uscalar_t = __t_uscalar_t;
  {$EXTERNALSYM t_uscalar_t}

{ Macros used as `request' argument to `ioctl'.  }
const
  __SID        = (Ord('S') shl 8);
  {$EXTERNALSYM __SID}

  I_NREAD      = (__SID or 1);     { Counts the number of data bytes in the data
                                     block in the first message.  }
  {$EXTERNALSYM I_NREAD}
  I_PUSH       = (__SID or 2);     { Push STREAMS module onto top of the current
                                     STREAM, just below the STREAM head.  }
  {$EXTERNALSYM I_PUSH}
  I_POP        = (__SID or 3);     { Remove STREAMS module from just below the
                                     STREAM head.  }
  {$EXTERNALSYM I_POP}
  I_LOOK       = (__SID or 4);     { Retrieve the name of the module just below
                                     the STREAM head and place it in a character
                                     string.  }
  {$EXTERNALSYM I_LOOK}
  I_FLUSH      = (__SID or 5);     { Flush all input and/or output.  }
  {$EXTERNALSYM I_FLUSH}
  I_SRDOPT     = (__SID or 6);     { Sets the read mode.  }
  {$EXTERNALSYM I_SRDOPT}
  I_GRDOPT     = (__SID or 7);     { Returns the current read mode setting.  }
  {$EXTERNALSYM I_GRDOPT}
  I_STR        = (__SID or 8);     { Construct an internal STREAMS `ioctl'
                                     message and send that message downstream. }
  {$EXTERNALSYM I_STR}
  I_SETSIG     = (__SID or 9);     { Inform the STREAM head that the process
                                     wants the SIGPOLL signal issued.  }
  {$EXTERNALSYM I_SETSIG}
  I_GETSIG     = (__SID or 10);    { Return the events for which the calling
                                     process is currently registered to be sent
                                     a SIGPOLL signal.  }
  {$EXTERNALSYM I_GETSIG}
  I_FIND       = (__SID or 11);    { Compares the names of all modules currently
                                     present in the STREAM to the name pointed to
                                     by `arg'.  }
  {$EXTERNALSYM I_FIND}
  I_LINK       = (__SID or 12);    { Connect two STREAMs.  }
  {$EXTERNALSYM I_LINK}
  I_UNLINK     = (__SID or 13);    { Disconnects the two STREAMs.  }
  {$EXTERNALSYM I_UNLINK}
  I_PEEK       = (__SID or 15);    { Allows a process to retrieve the information
                                     in the first message on the STREAM head read
                                     queue without taking the message off the
                                     queue.  }
  {$EXTERNALSYM I_PEEK}
  I_FDINSERT   = (__SID or 16);    { Create a message from the specified
                                     buffer(s), adds information about another
                                     STREAM, and send the message downstream.  }
  {$EXTERNALSYM I_FDINSERT}
  I_SENDFD     = (__SID or 17);    { Requests the STREAM associated with `fildes'
                                     to send a message, containing a file
                                     pointer, to the STREAM head at the other end
                                     of a STREAMS pipe.  }
  {$EXTERNALSYM I_SENDFD}
  I_RECVFD     = (__SID or 14);    { Non-EFT definition.  }
  {$EXTERNALSYM I_RECVFD}
  I_SWROPT     = (__SID or 19);    { Set the write mode.  }
  {$EXTERNALSYM I_SWROPT}
  I_GWROPT     = (__SID or 20);    { Return the current write mode setting.  }
  {$EXTERNALSYM I_GWROPT}
  I_LIST       = (__SID or 21);    { List all the module names on the STREAM, up
                                     to and including the topmost driver name. }
  {$EXTERNALSYM I_LIST}
  I_PLINK      = (__SID or 22);    { Connect two STREAMs with a persistent
                                     link.  }
  {$EXTERNALSYM I_PLINK}
  I_PUNLINK    = (__SID or 23);    { Disconnect the two STREAMs that were
                                     connected with a persistent link.  }
  {$EXTERNALSYM I_PUNLINK}
  I_FLUSHBAND  = (__SID or 28);    { Flush only band specified.  }
  {$EXTERNALSYM I_FLUSHBAND}
  I_CKBAND     = (__SID or 29);    { Check if the message of a given priority
                                     band exists on the STREAM head read
                                     queue.  }
  {$EXTERNALSYM I_CKBAND}
  I_GETBAND    = (__SID or 30);    { Return the priority band of the first
                                     message on the STREAM head read queue.  }
  {$EXTERNALSYM I_GETBAND}
  I_ATMARK     = (__SID or 31);    { See if the current message on the STREAM
                                     head read queue is "marked" by some module
                                     downstream.  }
  {$EXTERNALSYM I_ATMARK}
  I_SETCLTIME  = (__SID or 32);    { Set the time the STREAM head will delay when
                                     a STREAM is closing and there is data on
                                     the write queues.  }
  {$EXTERNALSYM I_SETCLTIME}
  I_GETCLTIME  = (__SID or 33);    { Get current value for closing timeout.  }
  {$EXTERNALSYM I_GETCLTIME}
  I_CANPUT     = (__SID or 34);    { Check if a certain band is writable.  }
  {$EXTERNALSYM I_CANPUT}


{ Used in `I_LOOK' request.  }
  FMNAMESZ     = 8;         { compatibility w/UnixWare/Solaris.  }
  {$EXTERNALSYM FMNAMESZ}

{ Flush options.  }
  FLUSHR       = $01;       { Flush read queues.  }
  {$EXTERNALSYM FLUSHR}
  FLUSHW       = $02;       { Flush write queues.  }
  {$EXTERNALSYM FLUSHW}
  FLUSHRW      = $03;       { Flush read and write queues.  }
  {$EXTERNALSYM FLUSHRW}

  FLUSHBAND    = $04;       { Flush only specified band.  }
  {$EXTERNALSYM FLUSHBAND}

{ Possible arguments for `I_SETSIG'.  }
  S_INPUT      = $0001;     { A message, other than a high-priority
                              message, has arrived.  }
  {$EXTERNALSYM S_INPUT}
  S_HIPRI      = $0002;     { A high-priority message is present.  }
  {$EXTERNALSYM S_HIPRI}
  S_OUTPUT     = $0004;     { The write queue for normal data is no longer
                              full.  }
  {$EXTERNALSYM S_OUTPUT}
  S_MSG        = $0008;     { A STREAMS signal message that contains the
                              SIGPOLL signal reaches the front of the
                              STREAM head read queue.  }
  {$EXTERNALSYM S_MSG}
  S_ERROR      = $0010;     { Notification of an error condition.  }
  {$EXTERNALSYM S_ERROR}
  S_HANGUP     = $0020;     { Notification of a hangup.  }
  {$EXTERNALSYM S_HANGUP}
  S_RDNORM     = $0040;     { A normal message has arrived.  }
  {$EXTERNALSYM S_RDNORM}
  S_WRNORM     = S_OUTPUT;
  {$EXTERNALSYM S_WRNORM}
  S_RDBAND     = $0080;     { A message with a non-zero priority has
                              arrived.  }
  {$EXTERNALSYM S_RDBAND}
  S_WRBAND     = $0100;     { The write queue for a non-zero priority
                              band is no longer full.  }
  {$EXTERNALSYM S_WRBAND}
  S_BANDURG    = $0200;     { When used in conjunction with S_RDBAND,
                              SIGURG is generated instead of SIGPOLL when
                              a priority message reaches the front of the
                              STREAM head read queue.  }
  {$EXTERNALSYM S_BANDURG}

{ Option for `I_PEEK'.  }
  RS_HIPRI     = $01;       { Only look for high-priority messages.  }
  {$EXTERNALSYM RS_HIPRI}

{ Options for `I_SRDOPT'.  }
  RNORM        = $0000;     { Byte-STREAM mode, the default.  }
  {$EXTERNALSYM RNORM}
  RMSGD        = $0001;     { Message-discard mode.   }
  {$EXTERNALSYM RMSGD}
  RMSGN        = $0002;     { Message-nondiscard mode.   }
  {$EXTERNALSYM RMSGN}
  RPROTDAT     = $0004;     { Deliver the control part of a message as
                              data.  }
  {$EXTERNALSYM RPROTDAT}
  RPROTDIS     = $0008;     { Discard the control part of a message,
                              delivering any data part.  }
  {$EXTERNALSYM RPROTDIS}
  RPROTNORM    = $0010;     { Fail `read' with EBADMSG if a message
                              containing a control part is at the front
                              of the STREAM head read queue.  }
  {$EXTERNALSYM RPROTNORM}
  RPROTMASK    = $001C;     { The RPROT bits }
  {$EXTERNALSYM RPROTMASK}

{ Possible mode for `I_SWROPT'.  }
  SNDZERO      = $001;      { Send a zero-length message downstream when a
                              `write' of 0 bytes occurs.  }
  {$EXTERNALSYM SNDZERO}
  SNDPIPE      = $002;      { Send SIGPIPE on write and putmsg if
                              sd_werror is set.  }
  {$EXTERNALSYM SNDPIPE}

{ Arguments for `I_ATMARK'.  }
  ANYMARK      = $01;       { Check if the message is marked.  }
  {$EXTERNALSYM ANYMARK}
  LASTMARK     = $02;       { Check if the message is the last one marked
                              on the queue.  }
  {$EXTERNALSYM LASTMARK}

{ Argument for `I_UNLINK'.  }
  MUXID_ALL    = (-1);      { Unlink all STREAMs linked to the STREAM
                              associated with `fildes'.  }
  {$EXTERNALSYM MUXID_ALL}


{ Macros for `getmsg', `getpmsg', `putmsg' and `putpmsg'.  }
  MSG_HIPRI    = $01;       { Send/receive high priority message.  }
  {$EXTERNALSYM MSG_HIPRI}
  MSG_ANY      = $02;       { Receive any message.  }
  {$EXTERNALSYM MSG_ANY}
  MSG_BAND     = $04;       { Receive message from specified band.  }
  {$EXTERNALSYM MSG_BAND}

{ Values returned by getmsg and getpmsg }
  MORECTL      = 1;         { More control information is left in message.  }
  {$EXTERNALSYM MORECTL}
  MOREDATA     = 2;         { More data is left in message.  }
  {$EXTERNALSYM MOREDATA}

  
type
{ Structure used for the I_FLUSHBAND ioctl on streams.  }
  bandinfo = {packed} record
    bi_pri: Byte;
    bi_flag: Integer;
  end;
  {$EXTERNALSYM bandinfo}

  strbuf = {packed} record
    maxlen: Integer;       { Maximum buffer length.  }
    len: Integer;          { Length of data.  }
    buf: PChar;            { Pointer to buffer.  }
  end;
  {$EXTERNALSYM strbuf}
  TStrBuf = strbuf;
  PStrBuf = ^TStrBuf;

  strpeek = {packed} record
    ctlbuf: strbuf;
    databuf: strbuf;
    flags: t_uscalar_t;    { UnixWare/Solaris compatibility.  }
  end;
  {$EXTERNALSYM strpeek}

  strfdinsert = {packed} record
    ctlbuf: strbuf;
    databuf: strbuf;
    flags: t_uscalar_t;    { UnixWare/Solaris compatibility.  }
    fildes: Integer;
    offset: Integer;
  end;
  {$EXTERNALSYM strfdinsert}

  strioctl = {packed} record
    ic_cmd: Integer;
    ic_timout: Integer;
    ic_len: Integer;
    ic_dp: PChar;
  end;
  {$EXTERNALSYM strioctl}

  strrecvfd = {packed} record
    fd: Integer;
    uid: uid_t;
    gid: gid_t;
    __fill: packed array[0..8-1] of Byte; { UnixWare/Solaris compatibility }
  end;
  {$EXTERNALSYM strrecvfd}


  str_mlist = {packed} record
    l_name: packed array[0..FMNAMESZ + 1 - 1] of Char;
  end;
  {$EXTERNALSYM str_mlist}
  TStrMList = str_mlist;
  PStrMList = ^TStrMList;

  str_list = {packed} record
    sl_nmods: Integer;
    sl_modlist: PStrMList;
  end;
  {$EXTERNALSYM str_list}


// Translated from stropts.h

(* Moved up to bits/stropts.h to resolve dependency
type
  t_uscalar_t = __t_uscalar_t;
*)

{ Test whether FILDES is associated with a STREAM-based file.  }
function isastream(__fildes: Integer): Integer; cdecl;
{$EXTERNALSYM isastream}

{ Receive next message from a STREAMS file.  }
function getmsg(__fildes: Integer; __ctlptr: PStrBuf; __dataptr: PStrBuf;
  __flagsp: PInteger): Integer; cdecl;
{$EXTERNALSYM getmsg}

{ Receive next message from a STREAMS file, with *FLAGSP allowing to
   control which message.  }
function getpmsg(__fildes: Integer; __ctlptr: PStrBuf; __dataptr: PStrBuf;
  __bandp: PInteger; __flagsp: PInteger): Integer; cdecl;
{$EXTERNALSYM getpmsg}

(* ioctl already defined elsewhere.
{ Perform the I/O control operation specified by REQUEST on FD.
   One argument may follow; its presence and type depend on REQUEST.
   Return value depends on REQUEST.  Usually -1 indicates error.  }
function ioctl(__fd: Integer; __request: LongWord): Integer; cdecl; varargs;
{$EXTERNALSYM ioctl}
*)

{ Send a message on a STREAM.  }
function putmsg(__fildes: Integer; __ctlptr: PStrBuf; __dataptr: PStrBuf;
  __flags: Integer): Integer; cdecl;
{$EXTERNALSYM putmsg}

{ Send a message on a STREAM to the BAND.  }
function putpmsg(__fildes: Integer; __ctlptr: PStrBuf; __dataptr: PStrBuf;
  __band: Integer; __flags: Integer): Integer; cdecl;
{$EXTERNALSYM putpmsg}

{ Attach a STREAMS-based file descriptor FILDES to a file PATH in the
   file system name space.  }
function fattach(__fildes: Integer; __path: PChar): Integer; cdecl;
{$EXTERNALSYM fattach}

{ Detach a name PATH from a STREAMS-based file descriptor.  }
function fdetach(__path: PChar): Integer; cdecl;
{$EXTERNALSYM fdetach}


// Translated from alloca.h

(* Intrinsic function, not exposed
{ Allocate a block that will be freed when the calling function exits.  }
function alloca(__size: size_t): Pointer; cdecl;
{$EXTERNALSYM alloca}
*)


// Translated from getopt.h

{ For communication from `getopt' to the caller.
   When `getopt' finds an option that takes an argument,
   the argument value is returned here.
   Also, when `ordering' is RETURN_IN_ORDER,
   each non-option ARGV-element is returned here.  }

(*
extern char *optarg;
*)
function optarg: PChar;
{$EXTERNALSYM optarg}

{ Index in ARGV of the next element to be scanned.
   This is used for communication to and from the caller
   and for communication between successive calls to `getopt'.

   On entry to `getopt', zero means this is the first call; initialize.

   When `getopt' returns -1, this is the index of the first of the
   non-option elements that the caller should itself scan.

   Otherwise, `optind' communicates from one call to the next
   how much of ARGV has been scanned so far.  }

(*
extern int optind;
*)
function optind: Integer;
{$EXTERNALSYM optind}
procedure optind_Assign(Value: Integer);
// This function does not exist in the header

{ Callers store zero here to inhibit the error message `getopt' prints
   for unrecognized options.  }

(*
extern int opterr;
*)
function opterr: Integer;
{$EXTERNALSYM opterr}
procedure opterr_Assign(Value: Integer);
// This function does not exist in the header


{ Set to an option character which was unrecognized.  }

(*
extern int optopt;
*)
function optopt: Integer;
{$EXTERNALSYM optopt}

{ Describe the long-named options requested by the application.
   The LONG_OPTIONS argument to getopt_long or getopt_long_only is a vector
   of `struct option' terminated by an element containing a name which is
   zero.

   The field `has_arg' is:
   no_argument		(or 0) if the option does not take an argument,
   required_argument	(or 1) if the option requires an argument,
   optional_argument 	(or 2) if the option takes an optional argument.

   If the field `flag' is not NULL, it points to a variable that is set
   to the value given in the field `val' when the option is found, but
   left unchanged if the option is not found.

   To have a long-named option do something other than set an `int' to
   a compiled-in constant, such as set a value from `optarg', set the
   option's `flag' field to zero and its `val' field to a nonzero
   value (the equivalent single-letter option character, if there is
   one).  For long options that have a zero `flag' field, `getopt'
   returns the contents of the `val' field.  }

type
  option = {packed} record
    name: PChar;
    { has_arg can't be an enum because some compilers complain about
       type mismatches in all the code that assumes it is an int.  }
    has_arg: Integer;
    flag: PInteger;
    val: Integer;
  end;
  {$EXTERNALSYM option}

{ Names for the values of the `has_arg' field of `struct option'.  }

const
  no_argument            = 0;
  {$EXTERNALSYM no_argument}
  required_argument      = 1;
  {$EXTERNALSYM required_argument}
  optional_argument      = 2;
  {$EXTERNALSYM optional_argument}

{ Get definitions and prototypes for functions to process the
   arguments in ARGV (ARGC of them, minus the program name) for
   options given in OPTS.

   Return the option character from OPTS just read.  Return -1 when
   there are no more options.  For unrecognized options, or options
   missing arguments, `optopt' is set to the option letter, and '?' is
   returned.

   The OPTS string is a list of characters which are recognized option
   letters, optionally followed by colons, specifying that that letter
   takes an argument, to be placed in `optarg'.

   If a letter in OPTS is followed by two colons, its argument is
   optional.  This behavior is specific to the GNU `getopt'.

   The argument `--' causes premature termination of argument
   scanning, explicitly telling `getopt' that there are no more
   options.

   If OPTS begins with `--', then non-option arguments are treated as
   arguments to the option '\0'.  This behavior is specific to the GNU
   `getopt'.  }

function getopt(__argc: Integer; __argv: PPChar; __shortopts: PChar): Integer; cdecl;
{$EXTERNALSYM getopt}

function getopt_long(__argc: Integer; __argv: PPChar; __shortopts: PChar;
  const __longopts: option; var __longind: Integer): Integer; cdecl;
{$EXTERNALSYM getopt_long}

function getopt_long_only(__argc: Integer; __argv: PPChar; __shortopts: PChar;
  const __longopts: option; var __longind: Integer): Integer; cdecl;
{$EXTERNALSYM getopt_long_only}


// Translated from argp.h

{ A description of a particular option.  A pointer to an array of
   these is passed in the OPTIONS field of an argp structure.  Each option
   entry can correspond to one long option and/or one short option; more
   names for the same option can be added by following an entry in an option
   array with options having the OPTION_ALIAS flag set.  }
type
  argp_option = {packed} record
    { The long option name.  For more than one name for the same option, you
       can use following options with the OPTION_ALIAS flag set.  }
    name: PChar;

    { What key is returned for this option.  If > 0 and printable, then it's
       also accepted as a short option.  }
    key: Integer;

    { If non-NULL, this is the name of the argument associated with this
       option, which is required unless the OPTION_ARG_OPTIONAL flag is set. }
    arg: PChar;

    { OPTION_ flags.  }
    flags: Integer;

    { The doc string for this option.  If both NAME and KEY are 0, This string
       will be printed outdented from the normal option column, making it
       useful as a group header (it will be the first thing printed in its
       group); in this usage, it's conventional to end the string with a `:'.  }
    doc: PChar;

    { The group this option is in.  In a long help message, options are sorted
       alphabetically within each group, and the groups presented in the order
       0, 1, 2, ..., n, -m, ..., -2, -1.  Every entry in an options array with
       if this field 0 will inherit the group number of the previous entry, or
       zero if it's the first one, unless its a group header (NAME and KEY both
       0), in which case, the previous entry + 1 is the default.  Automagic
       options such as --help are put into group -1.  }
    group: Integer;
  end;
  {$EXTERNALSYM argp_option}
  TArgPOption = argp_option;
  PArgPOption = ^TArgPOption;


const
{ The argument associated with this option is optional.  }
  OPTION_ARG_OPTIONAL   = $1;
  {$EXTERNALSYM OPTION_ARG_OPTIONAL}

{ This option isn't displayed in any help messages.  }
  OPTION_HIDDEN         = $2;
  {$EXTERNALSYM OPTION_HIDDEN}

{ This option is an alias for the closest previous non-alias option.  This
   means that it will be displayed in the same help entry, and will inherit
   fields other than NAME and KEY from the aliased option.  }
  OPTION_ALIAS          = $4;
  {$EXTERNALSYM OPTION_ALIAS}

{ This option isn't actually an option (and so should be ignored by the
   actual option parser), but rather an arbitrary piece of documentation that
   should be displayed in much the same manner as the options.  If this flag
   is set, then the option NAME field is displayed unmodified (e.g., no `--'
   prefix is added) at the left-margin (where a *short* option would normally
   be displayed), and the documentation string in the normal place.  For
   purposes of sorting, any leading whitespace and puncuation is ignored,
   except that if the first non-whitespace character is not `-', this entry
   is displayed after all options (and OPTION_DOC entries with a leading `-')
   in the same group.  }
  OPTION_DOC            = $8;
  {$EXTERNALSYM OPTION_DOC}

{ This option shouldn't be included in `long' usage messages (but is still
   included in help messages).  This is mainly intended for options that are
   completely documented in an argp's ARGS_DOC field, in which case including
   the option in the generic usage list would be redundant.  For instance,
   if ARGS_DOC is "FOO BAR\n-x BLAH", and the `-x' option's purpose is to
   distinguish these two cases, -x should probably be marked
   OPTION_NO_USAGE.  }
  OPTION_NO_USAGE       = $10;
  {$EXTERNALSYM OPTION_NO_USAGE}

{ What to return for unrecognized keys.  For special ARGP_KEY_ keys, such
   returns will simply be ignored.  For user keys, this error will be turned
   into EINVAL (if the call to argp_parse is such that errors are propagated
   back to the user instead of exiting); returning EINVAL itself would result
   in an immediate stop to parsing in *all* cases.  }
const
  ARGP_ERR_UNKNOWN = E2BIG; { Hurd should never need E2BIG.  XXX }
  {$EXTERNALSYM ARGP_ERR_UNKNOWN}

{ Special values for the KEY argument to an argument parsing function.
   ARGP_ERR_UNKNOWN should be returned if they aren't understood.

   The sequence of keys to a parsing function is either (where each
   uppercased word should be prefixed by `ARGP_KEY_' and opt is a user key):

       INIT opt... NO_ARGS END SUCCESS  -- No non-option arguments at all
   or  INIT (opt | ARG)... END SUCCESS  -- All non-option args parsed
   or  INIT (opt | ARG)... SUCCESS      -- Some non-option arg unrecognized

   The third case is where every parser returned ARGP_KEY_UNKNOWN for an
   argument, in which case parsing stops at that argument (returning the
   unparsed arguments to the caller of argp_parse if requested, or stopping
   with an error message if not).

   If an error occurs (either detected by argp, or because the parsing
   function returned an error value), then the parser is called with
   ARGP_KEY_ERROR, and no further calls are made.  }

{ This is not an option at all, but rather a command line argument.  If a
   parser receiving this key returns success, the fact is recorded, and the
   ARGP_KEY_NO_ARGS case won't be used.  HOWEVER, if while processing the
   argument, a parser function decrements the NEXT field of the state it's
   passed, the option won't be considered processed; this is to allow you to
   actually modify the argument (perhaps into an option), and have it
   processed again.  }
  ARGP_KEY_ARG = 0;
  {$EXTERNALSYM ARGP_KEY_ARG}

{ There are remaining arguments not parsed by any parser, which may be found
   starting at (STATE->argv + STATE->next).  If success is returned, but
   STATE->next left untouched, it's assumed that all arguments were consume,
   otherwise, the parser should adjust STATE->next to reflect any arguments
   consumed.  }
  ARGP_KEY_ARGS = $1000006;
  {$EXTERNALSYM ARGP_KEY_ARGS}

{ There are no more command line arguments at all.  }
  ARGP_KEY_END = $1000001;
  {$EXTERNALSYM ARGP_KEY_END}

{ Because it's common to want to do some special processing if there aren't
   any non-option args, user parsers are called with this key if they didn't
   successfully process any non-option arguments.  Called just before
   ARGP_KEY_END (where more general validity checks on previously parsed
   arguments can take place).  }
  ARGP_KEY_NO_ARGS = $1000002;
  {$EXTERNALSYM ARGP_KEY_NO_ARGS}

{ Passed in before any parsing is done.  Afterwards, the values of each
   element of the CHILD_INPUT field, if any, in the state structure is
   copied to each child's state to be the initial value of the INPUT field.  }
  ARGP_KEY_INIT = $1000003;
  {$EXTERNALSYM ARGP_KEY_INIT}

{ Use after all other keys, including SUCCESS & END.  }
  ARGP_KEY_FINI = $1000007;
  {$EXTERNALSYM ARGP_KEY_FINI}

{ Passed in when parsing has successfully been completed (even if there are
   still arguments remaining).  }
  ARGP_KEY_SUCCESS = $1000004;
  {$EXTERNALSYM ARGP_KEY_SUCCESS}

{ Passed in if an error occurs.  }
  ARGP_KEY_ERROR = $1000005;
  {$EXTERNALSYM ARGP_KEY_ERROR}


type
  PArgPState = ^TArgPState;
  PArgPChild = ^TArgPChild;

{ The type of a pointer to an argp parsing function.  }
  argp_parser_t = function(key: Integer; arg: PChar; state: PArgPState): error_t; cdecl;
  {$EXTERNALSYM argp_parser_t}

{ An argp structure contains a set of options declarations, a function to
   deal with parsing one, documentation string, a possible vector of child
   argp's, and perhaps a function to filter help output.  When actually
   parsing options, getopt is called with the union of all the argp
   structures chained together through their CHILD pointers, with conflicts
   being resolved in favor of the first occurrence in the chain.  }
  argp = {packed} record
    { An array of argp_option structures, terminated by an entry with both
       NAME and KEY having a value of 0.  }
    options: PArgPOption;

    { What to do with an option from this structure.  KEY is the key
       associated with the option, and ARG is any associated argument (NULL if
       none was supplied).  If KEY isn't understood, ARGP_ERR_UNKNOWN should be
       returned.  If a non-zero, non-ARGP_ERR_UNKNOWN value is returned, then
       parsing is stopped immediately, and that value is returned from
       argp_parse().  For special (non-user-supplied) values of KEY, see the
       ARGP_KEY_ definitions below.  }
    parser: argp_parser_t;

    { A string describing what other arguments are wanted by this program.  It
       is only used by argp_usage to print the `Usage:' message.  If it
       contains newlines, the strings separated by them are considered
       alternative usage patterns, and printed on separate lines (lines after
       the first are prefix by `  or: ' instead of `Usage:').  }
    args_doc: PChar;

    { If non-NULL, a string containing extra text to be printed before and
       after the options in a long help message (separated by a vertical tab
       `\v' character).  }
    doc: PChar;

    { A vector of argp_children structures, terminated by a member with a 0
       argp field, pointing to child argps should be parsed with this one.  Any
       conflicts are resolved in favor of this argp, or early argps in the
       CHILDREN list.  This field is useful if you use libraries that supply
       their own argp structure, which you want to use in conjunction with your
       own.  }
    children: PArgPChild;

    { If non-zero, this should be a function to filter the output of help
       messages.  KEY is either a key from an option, in which case TEXT is
       that option's help text, or a special key from the ARGP_KEY_HELP_
       defines, below, describing which other help text TEXT is.  The function
       should return either TEXT, if it should be used as-is, a replacement
       string, which should be malloced, and will be freed by argp, or NULL,
       meaning `print nothing'.  The value for TEXT is *after* any translation
       has been done, so if any of the replacement text also needs translation,
       that should be done by the filter function.  INPUT is either the input
       supplied to argp_parse, or NULL, if argp_help was called directly.  }
    help_filter: function(__key: Integer; __text: PChar; __input: Pointer): PChar; cdecl;

    { If non-zero the strings used in the argp library are translated using
       the domain described by this string.  Otherwise the currently installed
       default domain is used.  }
    argp_domain: PChar;
  end;
  {$EXTERNALSYM argp}
  TArgP = argp;
  PArgP = ^TArgP;


{ When an argp has a non-zero CHILDREN field, it should point to a vector of
   argp_child structures, each of which describes a subsidiary argp.  }
  argp_child = {packed} record
    { The child parser.  }
    argp: PArgP;

    { Flags for this child.  }
    flags: Integer;

    { If non-zero, an optional header to be printed in help output before the
       child options.  As a side-effect, a non-zero value forces the child
       options to be grouped together; to achieve this effect without actually
       printing a header string, use a value of "".  }
    header: PChar;

    { Where to group the child options relative to the other (`consolidated')
       options in the parent argp; the values are the same as the GROUP field
       in argp_option structs, but all child-groupings follow parent options at
       a particular group level.  If both this field and HEADER are zero, then
       they aren't grouped at all, but rather merged with the parent options
       (merging the child's grouping levels with the parents).  }
    group: Integer;
  end;
  {$EXTERNALSYM argp_child}
  TArgPChild = argp_child;


{ Parsing state.  This is provided to parsing functions called by argp,
   which may examine and, as noted, modify fields.  }
  argp_state = {packed} record
    { The top level ARGP being parsed.  }
    root_argp: PArgP;

    { The argument vector being parsed.  May be modified.  }
    argc: Integer;
    argv: PPChar;

    { The index in ARGV of the next arg that to be parsed.  May be modified. }
    next: Integer;

    { The flags supplied to argp_parse.  May be modified.  }
    flags: Cardinal;

    { While calling a parsing function with a key of ARGP_KEY_ARG, this is the
       number of the current arg, starting at zero, and incremented after each
       such call returns.  At all other times, this is the number of such
       arguments that have been processed.  }
    arg_num: Cardinal;

    { If non-zero, the index in ARGV of the first argument following a special
       `--' argument (which prevents anything following being interpreted as an
       option).  Only set once argument parsing has proceeded past this point. }
    quoted: Integer;

    { An arbitrary pointer passed in from the user.  }
    input: Pointer;
    { Values to pass to child parsers.  This vector will be the same length as
       the number of children for the current parser.  }
    child_inputs: PPointer;

    { For the parser's use.  Initialized to 0.  }
    hook: Pointer;

    { The name used when printing messages.  This is initialized to ARGV[0],
       or PROGRAM_INVOCATION_NAME if that is unavailable.  }
    name: PChar;

    { Streams used when argp prints something.  }
    err_stream: PIOFile;    { For errors; initialized to stderr. }
    out_stream: PIOFile;    { For information; initialized to stdout. }

    pstate: Pointer;        { Private, for use by argp.  }
  end;
  {$EXTERNALSYM argp_state}
  TArgPState = argp_state;


const
{ Possible KEY arguments to a help filter function.  }
  ARGP_KEY_HELP_PRE_DOC     = $2000001; { Help text preceeding options. }
  {$EXTERNALSYM ARGP_KEY_HELP_PRE_DOC}
  ARGP_KEY_HELP_POST_DOC    = $2000002; { Help text following options. }
  {$EXTERNALSYM ARGP_KEY_HELP_POST_DOC}
  ARGP_KEY_HELP_HEADER      = $2000003; { Option header string. }
  {$EXTERNALSYM ARGP_KEY_HELP_HEADER}
  ARGP_KEY_HELP_EXTRA       = $2000004; { After all other documentation;
                                          TEXT is NULL for this key.  }
  {$EXTERNALSYM ARGP_KEY_HELP_EXTRA}

{ Explanatory note emitted when duplicate option arguments have been suppressed.  }
  ARGP_KEY_HELP_DUP_ARGS_NOTE = $2000005;
  {$EXTERNALSYM ARGP_KEY_HELP_DUP_ARGS_NOTE}
  ARGP_KEY_HELP_ARGS_DOC      = $2000006; { Argument doc string.  }
  {$EXTERNALSYM ARGP_KEY_HELP_ARGS_DOC}


{ Flags for argp_parse (note that the defaults are those that are
   convenient for program command line parsing): }
const
{ Don't ignore the first element of ARGV.  Normally (and always unless
   ARGP_NO_ERRS is set) the first element of the argument vector is
   skipped for option parsing purposes, as it corresponds to the program name
   in a command line.  }
  ARGP_PARSE_ARGV0        = $01;
  {$EXTERNALSYM ARGP_PARSE_ARGV0}

{ Don't print error messages for unknown options to stderr; unless this flag
   is set, ARGP_PARSE_ARGV0 is ignored, as ARGV[0] is used as the program
   name in the error messages.  This flag implies ARGP_NO_EXIT (on the
   assumption that silent exiting upon errors is bad behaviour).  }
  ARGP_NO_ERRS            = $02;
  {$EXTERNALSYM ARGP_NO_ERRS}

{ Don't parse any non-option args.  Normally non-option args are parsed by
   calling the parse functions with a key of ARGP_KEY_ARG, and the actual arg
   as the value.  Since it's impossible to know which parse function wants to
   handle it, each one is called in turn, until one returns 0 or an error
   other than ARGP_ERR_UNKNOWN; if an argument is handled by no one, the
   argp_parse returns prematurely (but with a return value of 0).  If all
   args have been parsed without error, all parsing functions are called one
   last time with a key of ARGP_KEY_END.  This flag needn't normally be set,
   as the normal behavior is to stop parsing as soon as some argument can't
   be handled.  }
  ARGP_NO_ARGS            = $04;
  {$EXTERNALSYM ARGP_NO_ARGS}

{ Parse options and arguments in the same order they occur on the command
   line -- normally they're rearranged so that all options come first. }
  ARGP_IN_ORDER           = $08;
  {$EXTERNALSYM ARGP_IN_ORDER}

{ Don't provide the standard long option --help, which causes usage and
      option help information to be output to stdout, and exit (0) called. }
  ARGP_NO_HELP            = $10;
  {$EXTERNALSYM ARGP_NO_HELP}

{ Don't exit on errors (they may still result in error messages).  }
  ARGP_NO_EXIT            = $20;
  {$EXTERNALSYM ARGP_NO_EXIT}

{ Use the gnu getopt `long-only' rules for parsing arguments.  }
  ARGP_LONG_ONLY          = $40;
  {$EXTERNALSYM ARGP_LONG_ONLY}

{ Turns off any message-printing/exiting options.  }
  ARGP_SILENT = (ARGP_NO_EXIT or ARGP_NO_ERRS or ARGP_NO_HELP);
  {$EXTERNALSYM ARGP_SILENT}

{ Parse the options strings in ARGC & ARGV according to the options in ARGP.
   FLAGS is one of the ARGP_ flags above.  If ARG_INDEX is non-NULL, the
   index in ARGV of the first unparsed option is returned in it.  If an
   unknown option is present, ARGP_ERR_UNKNOWN is returned; if some parser
   routine returned a non-zero value, it is returned; otherwise 0 is
   returned.  This function may also call exit unless the ARGP_NO_HELP flag
   is set.  INPUT is a pointer to a value to be passed in to the parser.  }
function argp_parse(__argp: PArgP; __argc: Integer; __argv: PPChar; __flags: Cardinal;
  __arg_index: PInteger; __input: Pointer): error_t; cdecl;
{$EXTERNALSYM argp_parse}
function __argp_parse(__argp: PArgP; __argc: Integer; __argv: PPChar; __flags: Cardinal;
  __arg_index: PInteger; __input: Pointer): error_t; cdecl;
{$EXTERNALSYM __argp_parse}

{ Global variables.  }

{ If defined or set by the user program to a non-zero value, then a default
   option --version is added (unless the ARGP_NO_HELP flag is used), which
   will print this string followed by a newline and exit (unless the
   ARGP_NO_EXIT flag is used).  Overridden by ARGP_PROGRAM_VERSION_HOOK.  }
(*
extern __const char *argp_program_version;
*)
function argp_program_version: PChar;
{$EXTERNALSYM argp_program_version}
procedure argp_program_version_Assign(Value: PChar);
// This function does not exist in the header

{ If defined or set by the user program to a non-zero value, then a default
   option --version is added (unless the ARGP_NO_HELP flag is used), which
   calls this function with a stream to print the version to and a pointer to
   the current parsing state, and then exits (unless the ARGP_NO_EXIT flag is
   used).  This variable takes precedent over ARGP_PROGRAM_VERSION.  }

(*
extern void ( *argp_program_version_hook) (FILE *__restrict __stream,
  struct argp_state *__restrict __state);
*)
type
  TArgPProgramVersionHook = procedure(__stream: PIOFile; __state: PArgPState); cdecl;

function argp_program_version_hook: TArgPProgramVersionHook;
{$EXTERNALSYM argp_program_version_hook}
procedure argp_program_version_hook_Assign(Value: TArgPProgramVersionHook);
// This function does not exist in the header


{ If defined or set by the user program, it should point to string that is
   the bug-reporting address for the program.  It will be printed by
   argp_help if the ARGP_HELP_BUG_ADDR flag is set (as it is by various
   standard help messages), embedded in a sentence that says something like
   `Report bugs to ADDR.'.  }
(*
extern __const char *argp_program_bug_address;
*)
function argp_program_bug_address: PChar;
{$EXTERNALSYM argp_program_bug_address}
procedure argp_program_bug_address_Assign(Value: PChar);
// This function does not exist in the header

{ The exit status that argp will use when exiting due to a parsing error.
   If not defined or set by the user program, this defaults to EX_USAGE from
   <sysexits.h>.  }
(*
extern error_t argp_err_exit_status;
*)
function argp_err_exit_status: error_t;
{$EXTERNALSYM argp_err_exit_status}
procedure argp_err_exit_status_Assign(Value: error_t);
// This function does not exist in the header

{ Flags for argp_help.  }
const
  ARGP_HELP_USAGE         = $01; { a Usage: message. }
  {$EXTERNALSYM ARGP_HELP_USAGE}
  ARGP_HELP_SHORT_USAGE   = $02; {  " but don't actually print options. }
  {$EXTERNALSYM ARGP_HELP_SHORT_USAGE}
  ARGP_HELP_SEE           = $04; { a `Try ... for more help' message. }
  {$EXTERNALSYM ARGP_HELP_SEE}
  ARGP_HELP_LONG          = $08; { a long help message. }
  {$EXTERNALSYM ARGP_HELP_LONG}
  ARGP_HELP_PRE_DOC       = $10; { doc string preceding long help.  }
  {$EXTERNALSYM ARGP_HELP_PRE_DOC}
  ARGP_HELP_POST_DOC      = $20; { doc string following long help.  }
  {$EXTERNALSYM ARGP_HELP_POST_DOC}
  ARGP_HELP_DOC           = (ARGP_HELP_PRE_DOC or ARGP_HELP_POST_DOC);
  {$EXTERNALSYM ARGP_HELP_DOC}
  ARGP_HELP_BUG_ADDR      = $40; { bug report address }
  {$EXTERNALSYM ARGP_HELP_BUG_ADDR}
  ARGP_HELP_LONG_ONLY     = $80; { modify output appropriately to
                                   reflect ARGP_LONG_ONLY mode.  }
  {$EXTERNALSYM ARGP_HELP_LONG_ONLY}

{ These ARGP_HELP flags are only understood by argp_state_help.  }
  ARGP_HELP_EXIT_ERR      = $100; { Call exit(1) instead of returning.  }
  {$EXTERNALSYM ARGP_HELP_EXIT_ERR}
  ARGP_HELP_EXIT_OK       = $200; { Call exit(0) instead of returning.  }
  {$EXTERNALSYM ARGP_HELP_EXIT_OK}

{ The standard thing to do after a program command line parsing error, if an
   error message has already been printed.  }
  ARGP_HELP_STD_ERR = (ARGP_HELP_SEE or ARGP_HELP_EXIT_ERR);
  {$EXTERNALSYM ARGP_HELP_STD_ERR}

{ The standard thing to do after a program command line parsing error, if no
   more specific error message has been printed.  }
  ARGP_HELP_STD_USAGE = (ARGP_HELP_SHORT_USAGE or ARGP_HELP_SEE or ARGP_HELP_EXIT_ERR);
  {$EXTERNALSYM ARGP_HELP_STD_USAGE}

{ The standard thing to do in response to a --help option.  }
  ARGP_HELP_STD_HELP = (ARGP_HELP_SHORT_USAGE or ARGP_HELP_LONG or ARGP_HELP_EXIT_OK or
                        ARGP_HELP_DOC or ARGP_HELP_BUG_ADDR);
  {$EXTERNALSYM ARGP_HELP_STD_HELP}

{ Output a usage message for ARGP to STREAM.  FLAGS are from the set ARGP_HELP_*.  }
procedure argp_help(__argp: PArgP; __stream: PIOFile; __flags: Cardinal;
  __name: PChar); cdecl;
{$EXTERNALSYM argp_help}
procedure __argp_help(__argp: PArgP; __stream: PIOFile; __flags: Cardinal;
  __name: PChar); cdecl;
{$EXTERNALSYM __argp_help}

{ The following routines are intended to be called from within an argp
   parsing routine (thus taking an argp_state structure as the first
   argument).  They may or may not print an error message and exit, depending
   on the flags in STATE -- in any case, the caller should be prepared for
   them *not* to exit, and should return an appropiate error after calling
   them.  [argp_usage & argp_error should probably be called argp_state_...,
   but they're used often enough that they should be short]  }

{ Output, if appropriate, a usage message for STATE to STREAM.  FLAGS are
   from the set ARGP_HELP_*.  }
procedure argp_state_help(__state: PArgPState; __stream: PIOFile; __flags: Cardinal); cdecl;
{$EXTERNALSYM argp_state_help}
procedure __argp_state_help(__state: PArgPState; __stream: PIOFile; __flags: Cardinal); cdecl;
{$EXTERNALSYM __argp_state_help}

{ Possibly output the standard usage message for ARGP to stderr and exit.  }
procedure argp_usage(__state: PArgPState); cdecl;
{$EXTERNALSYM argp_usage}
procedure __argp_usage(__state: PArgPState); cdecl;
{$EXTERNALSYM __argp_usage}

{ If appropriate, print the printf string FMT and following args, preceded
   by the program name and `:', to stderr, and followed by a `Try ... --help'
   message, then exit (1).  }
procedure argp_error(__state: PArgPState; __fmt: PChar); cdecl; varargs;
{$EXTERNALSYM argp_error}
procedure __argp_error(__state: PArgPState; __fmt: PChar); cdecl; varargs;
{$EXTERNALSYM __argp_error}

{ Similar to the standard gnu error-reporting function error(), but will
   respect the ARGP_NO_EXIT and ARGP_NO_ERRS flags in STATE, and will print
   to STATE->err_stream.  This is useful for argument parsing code that is
   shared between program startup (when exiting is desired) and runtime
   option parsing (when typically an error code is returned instead).  The
   difference between this function and argp_error is that the latter is for
   *parsing errors*, and the former is for other problems that occur during
   parsing but don't reflect a (syntactic) problem with the input.  }
procedure argp_failure(__state: PArgPState; __status: Integer; __errnum: Integer;
  __fmt: PChar); cdecl; varargs;
{$EXTERNALSYM argp_failure}
procedure __argp_failure(__state: PArgPState; __status: Integer; __errnum: Integer;
  __fmt: PChar); cdecl; varargs;
{$EXTERNALSYM __argp_failure}

(* Local symbol only
{ Returns true if the option OPT is a valid short option.  }
function _option_is_short(__opt: PArgPOption): Integer; cdecl;
function __option_is_short(__opt: PArgPOption): Integer; cdecl;
*)

(* Local symbol only
{ Returns true if the option OPT is in fact the last (unused) entry in an
   options array.  }
function _option_is_end(__opt: PArgPOption): Integer; cdecl;
function __option_is_end(__opt: PArgPOption): Integer; cdecl;
*)

{ Return the input field for ARGP in the parser corresponding to STATE; used
   by the help routines.  }
function __argp_input(__argp: PArgP; __state: PArgPState): Pointer; cdecl;
{$EXTERNALSYM __argp_input}


// Translated from nss.h

{ Define interface to NSS.  This is meant for the interface functions
   and for implementors of new services. }

{ Possible results of lookup using a nss_* function.  }
type
  nss_status =
  (
    NSS_STATUS_TRYAGAIN = -2,
    {$EXTERNALSYM NSS_STATUS_TRYAGAIN}
    NSS_STATUS_UNAVAIL = -1,
    {$EXTERNALSYM NSS_STATUS_UNAVAIL}
    NSS_STATUS_NOTFOUND = 0,
    {$EXTERNALSYM NSS_STATUS_NOTFOUND}
    NSS_STATUS_SUCCESS = 1,
    {$EXTERNALSYM NSS_STATUS_SUCCESS}
    NSS_STATUS_RETURN = 2
    {$EXTERNALSYM NSS_STATUS_RETURN}
  );
  {$EXTERNALSYM nss_status}

{ Overwrite service selection for database DBNAME using specification
   in STRING.
   This function should only be used by system programs which have to
   work around non-existing services (e.e., while booting).
   Attention: Using this function repeatedly will slowly eat up the
   whole memory since previous selection data cannot be freed.  }
function __nss_configure_lookup(__dbname: PChar; __string: PChar): Integer; cdecl;
{$EXTERNALSYM __nss_configure_lookup}


// Translated from regex.h


{ The following two types have to be signed and unsigned integer type

   wide enough to hold a value of a pointer.  For most ANSI compilers
   ptrdiff_t and size_t should be likely OK.  Still size of these two
   types is 2 for Microsoft C.  Ugh... }
type
  s_reg_t = Longint;
  {$EXTERNALSYM s_reg_t}
  active_reg_t = LongWord;
  {$EXTERNALSYM active_reg_t}

{ The following bits are used to determine the regexp syntax we
   recognize.  The set/not-set meanings are chosen so that Emacs syntax
   remains the value 0.  The bits are given in alphabetical order, and
   the definitions shifted by one from the previous bit; thus, when we
   add or remove a bit, only one other definition need change.  }
  reg_syntax_t = LongWord;
  {$EXTERNALSYM reg_syntax_t}

{ If this bit is not set, then \ inside a bracket expression is literal.
   If set, then such a \ quotes the following character.  }
const
  RE_BACKSLASH_ESCAPE_IN_LISTS = LongWord(1);
  {$EXTERNALSYM RE_BACKSLASH_ESCAPE_IN_LISTS}

{ If this bit is not set, then + and ? are operators, and \+ and \? are
     literals.
   If set, then \+ and \? are operators and + and ? are literals.  }
  RE_BK_PLUS_QM = (RE_BACKSLASH_ESCAPE_IN_LISTS shl 1);
  {$EXTERNALSYM RE_BK_PLUS_QM}

{ If this bit is set, then character classes are supported.  They are:
     [:alpha:], [:upper:], [:lower:],  [:digit:], [:alnum:], [:xdigit:],
     [:space:], [:print:], [:punct:], [:graph:], and [:cntrl:].
   If not set, then character classes are not supported.  }
  RE_CHAR_CLASSES = (RE_BK_PLUS_QM shl 1);
  {$EXTERNALSYM RE_CHAR_CLASSES}

{ If this bit is set, then ^ and $ are always anchors (outside bracket
     expressions, of course).
   If this bit is not set, then it depends:
        ^  is an anchor if it is at the beginning of a regular
           expression or after an open-group or an alternation operator;
        $  is an anchor if it is at the end of a regular expression, or
           before a close-group or an alternation operator.

   This bit could be (re)combined with RE_CONTEXT_INDEP_OPS, because
   POSIX draft 11.2 says that * etc. in leading positions is undefined.
   We already implemented a previous draft which made those constructs
   invalid, though, so we haven't changed the code back.  }
  RE_CONTEXT_INDEP_ANCHORS = (RE_CHAR_CLASSES shl 1);
  {$EXTERNALSYM RE_CONTEXT_INDEP_ANCHORS}

{ If this bit is set, then special characters are always special
     regardless of where they are in the pattern.
   If this bit is not set, then special characters are special only in
     some contexts; otherwise they are ordinary.  Specifically,
     * + ? and intervals are only special when not after the beginning,
     open-group, or alternation operator.  }
  RE_CONTEXT_INDEP_OPS = (RE_CONTEXT_INDEP_ANCHORS shl 1);
  {$EXTERNALSYM RE_CONTEXT_INDEP_OPS}

{ If this bit is set, then *, +, ?, and { cannot be first in an re or
     immediately after an alternation or begin-group operator.  }
  RE_CONTEXT_INVALID_OPS = (RE_CONTEXT_INDEP_OPS shl 1);
  {$EXTERNALSYM RE_CONTEXT_INVALID_OPS}

{ If this bit is set, then . matches newline.
   If not set, then it doesn't.  }
  RE_DOT_NEWLINE = (RE_CONTEXT_INVALID_OPS shl 1);
  {$EXTERNALSYM RE_DOT_NEWLINE}

{ If this bit is set, then . doesn't match NUL.
   If not set, then it does.  }
  RE_DOT_NOT_NULL = (RE_DOT_NEWLINE shl 1);
  {$EXTERNALSYM RE_DOT_NOT_NULL}

{ If this bit is set, nonmatching lists [^...] do not match newline.
   If not set, they do.  }
  RE_HAT_LISTS_NOT_NEWLINE = (RE_DOT_NOT_NULL shl 1);
  {$EXTERNALSYM RE_HAT_LISTS_NOT_NEWLINE}

// If this bit is set, either \{...\} or {...} defines an
// interval, depending on RE_NO_BK_BRACES.
// If not set, \{, \}, {, and } are literals.
  RE_INTERVALS = (RE_HAT_LISTS_NOT_NEWLINE shl 1);
  {$EXTERNALSYM RE_INTERVALS}

{ If this bit is set, +, ? and | aren't recognized as operators.
   If not set, they are.  }
  RE_LIMITED_OPS = (RE_INTERVALS shl 1);
  {$EXTERNALSYM RE_LIMITED_OPS}

{ If this bit is set, newline is an alternation operator.
   If not set, newline is literal.  }
  RE_NEWLINE_ALT = (RE_LIMITED_OPS shl 1);
  {$EXTERNALSYM RE_NEWLINE_ALT}

// If this bit is set, then `{...}' defines an interval, and \{ and \}
// are literals.
// If not set, then `\{...\}' defines an interval.  }
  RE_NO_BK_BRACES = (RE_NEWLINE_ALT shl 1);
  {$EXTERNALSYM RE_NO_BK_BRACES}

{ If this bit is set, (...) defines a group, and \( and \) are literals.
   If not set, \(...\) defines a group, and ( and ) are literals.  }
  RE_NO_BK_PARENS = (RE_NO_BK_BRACES shl 1);
  {$EXTERNALSYM RE_NO_BK_PARENS}

{ If this bit is set, then \<digit> matches <digit>.
   If not set, then \<digit> is a back-reference.  }
  RE_NO_BK_REFS = (RE_NO_BK_PARENS shl 1);
  {$EXTERNALSYM RE_NO_BK_REFS}

{ If this bit is set, then | is an alternation operator, and \| is literal.
   If not set, then \| is an alternation operator, and | is literal.  }
  RE_NO_BK_VBAR = (RE_NO_BK_REFS shl 1);
  {$EXTERNALSYM RE_NO_BK_VBAR}

{ If this bit is set, then an ending range point collating higher
     than the starting range point, as in [z-a], is invalid.
   If not set, then when ending range point collates higher than the
     starting range point, the range is ignored.  }
  RE_NO_EMPTY_RANGES = (RE_NO_BK_VBAR shl 1);
  {$EXTERNALSYM RE_NO_EMPTY_RANGES}

{ If this bit is set, then an unmatched ) is ordinary.
   If not set, then an unmatched ) is invalid.  }
  RE_UNMATCHED_RIGHT_PAREN_ORD = (RE_NO_EMPTY_RANGES shl 1);
  {$EXTERNALSYM RE_UNMATCHED_RIGHT_PAREN_ORD}

{ If this bit is set, succeed as soon as we match the whole pattern,
   without further backtracking.  }
  RE_NO_POSIX_BACKTRACKING = (RE_UNMATCHED_RIGHT_PAREN_ORD shl 1);
  {$EXTERNALSYM RE_NO_POSIX_BACKTRACKING}

{ If this bit is set, do not process the GNU regex operators.
   If not set, then the GNU regex operators are recognized. }
  RE_NO_GNU_OPS = (RE_NO_POSIX_BACKTRACKING shl 1);
  {$EXTERNALSYM RE_NO_GNU_OPS}

{ If this bit is set, turn on internal regex debugging.
   If not set, and debugging was on, turn it off.
   This only works if regex.c is compiled -DDEBUG.
   We define this bit always, so that all that's needed to turn on
   debugging is to recompile regex.c; the calling code can always have
   this bit set, and it won't affect anything in the normal case. }
  RE_DEBUG = (RE_NO_GNU_OPS shl 1);
  {$EXTERNALSYM RE_DEBUG}

{ This global variable defines the particular regexp syntax to use (for
   some interfaces).  When a regexp is compiled, the syntax used is
   stored in the pattern buffer, so changing this does not affect
   already-compiled regexps.  }
(* Needed to make this an accessor procedure. *)
procedure re_syntax_options_Assign(const Value: reg_syntax_t);
// This function does not exist in the header
function re_syntax_options: reg_syntax_t;
{$EXTERNALSYM re_syntax_options}

{ Define combinations of the above bits for the standard possibilities.
   (The [[[ comments delimit what gets put into the Texinfo file, so
   don't delete them!)  }
{ [[[begin syntaxes]]] }
const
  RE_SYNTAX_EMACS = 0;
  {$EXTERNALSYM RE_SYNTAX_EMACS}

  RE_SYNTAX_AWK	=
  (RE_BACKSLASH_ESCAPE_IN_LISTS    or RE_DOT_NOT_NULL
   or RE_NO_BK_PARENS              or RE_NO_BK_REFS
   or RE_NO_BK_VBAR                or RE_NO_EMPTY_RANGES
   or RE_DOT_NEWLINE		   or RE_CONTEXT_INDEP_ANCHORS
   or RE_UNMATCHED_RIGHT_PAREN_ORD or RE_NO_GNU_OPS);
  {$EXTERNALSYM RE_SYNTAX_AWK}

{ Syntax bits common to both basic and extended POSIX regex syntax.  }
  _RE_SYNTAX_POSIX_COMMON =
  (RE_CHAR_CLASSES or RE_DOT_NEWLINE      or RE_DOT_NOT_NULL
   or RE_INTERVALS  or RE_NO_EMPTY_RANGES);
  {$EXTERNALSYM _RE_SYNTAX_POSIX_COMMON}

  RE_SYNTAX_POSIX_EXTENDED =
  (_RE_SYNTAX_POSIX_COMMON  or RE_CONTEXT_INDEP_ANCHORS
   or RE_CONTEXT_INDEP_OPS   or RE_NO_BK_BRACES
   or RE_NO_BK_PARENS        or RE_NO_BK_VBAR
   or RE_CONTEXT_INVALID_OPS or RE_UNMATCHED_RIGHT_PAREN_ORD);
  {$EXTERNALSYM RE_SYNTAX_POSIX_EXTENDED}

  RE_SYNTAX_GNU_AWK =
  ((RE_SYNTAX_POSIX_EXTENDED or RE_BACKSLASH_ESCAPE_IN_LISTS or RE_DEBUG)
   and not (RE_DOT_NOT_NULL or RE_INTERVALS or RE_CONTEXT_INDEP_OPS));
  {$EXTERNALSYM RE_SYNTAX_GNU_AWK}

  RE_SYNTAX_POSIX_AWK =
  (RE_SYNTAX_POSIX_EXTENDED or RE_BACKSLASH_ESCAPE_IN_LISTS
   or RE_INTERVALS	    or RE_NO_GNU_OPS);
  {$EXTERNALSYM RE_SYNTAX_POSIX_AWK}

  RE_SYNTAX_GREP =
  (RE_BK_PLUS_QM              or RE_CHAR_CLASSES
   or RE_HAT_LISTS_NOT_NEWLINE or RE_INTERVALS
   or RE_NEWLINE_ALT);
  {$EXTERNALSYM RE_SYNTAX_GREP}

  RE_SYNTAX_EGREP =
  (RE_CHAR_CLASSES         or RE_CONTEXT_INDEP_ANCHORS
   or RE_CONTEXT_INDEP_OPS or RE_HAT_LISTS_NOT_NEWLINE
   or RE_NEWLINE_ALT       or RE_NO_BK_PARENS
   or RE_NO_BK_VBAR);
  {$EXTERNALSYM RE_SYNTAX_EGREP}

  RE_SYNTAX_POSIX_EGREP =
  (RE_SYNTAX_EGREP or RE_INTERVALS or RE_NO_BK_BRACES);
  {$EXTERNALSYM RE_SYNTAX_POSIX_EGREP}

{ P1003.2/D11.2, section 4.20.7.1, lines 5078ff.  }
  RE_SYNTAX_POSIX_BASIC =
  (_RE_SYNTAX_POSIX_COMMON or RE_BK_PLUS_QM);
  {$EXTERNALSYM RE_SYNTAX_POSIX_BASIC}

  RE_SYNTAX_ED = RE_SYNTAX_POSIX_BASIC;
  {$EXTERNALSYM RE_SYNTAX_ED}

  RE_SYNTAX_SED = RE_SYNTAX_POSIX_BASIC;
  {$EXTERNALSYM RE_SYNTAX_SED}

{ Differs from ..._POSIX_BASIC only in that RE_BK_PLUS_QM becomes
   RE_LIMITED_OPS, i.e., \? \+ \| are not recognized.  Actually, this
   isn't minimal, since other operators, such as \`, aren't disabled.  }
  RE_SYNTAX_POSIX_MINIMAL_BASIC =
  (_RE_SYNTAX_POSIX_COMMON or RE_LIMITED_OPS);
  {$EXTERNALSYM RE_SYNTAX_POSIX_MINIMAL_BASIC}

{ Differs from ..._POSIX_EXTENDED in that RE_CONTEXT_INDEP_OPS is
   removed and RE_NO_BK_REFS is added.  }
  RE_SYNTAX_POSIX_MINIMAL_EXTENDED =
  (_RE_SYNTAX_POSIX_COMMON  or RE_CONTEXT_INDEP_ANCHORS
   or RE_CONTEXT_INVALID_OPS or RE_NO_BK_BRACES
   or RE_NO_BK_PARENS        or RE_NO_BK_REFS
   or RE_NO_BK_VBAR	    or RE_UNMATCHED_RIGHT_PAREN_ORD);
  {$EXTERNALSYM RE_SYNTAX_POSIX_MINIMAL_EXTENDED}
{ [[[end syntaxes]]] }

{ If sizeof(int) == 2, then ((1 << 15) - 1) overflows.  }
const
  RE_DUP_MAX = $7fff;
  {$EXTERNALSYM RE_DUP_MAX}


{ POSIX `cflags' bits (i.e., information for `regcomp').  }

const
{ If this bit is set, then use extended regular expression syntax.
   If not set, then use basic regular expression syntax.  }
  REG_EXTENDED = 1;
  {$EXTERNALSYM REG_EXTENDED}

{ If this bit is set, then ignore case when matching.
   If not set, then case is significant.  }
  REG_ICASE = (REG_EXTENDED shl 1);
  {$EXTERNALSYM REG_ICASE}

{ If this bit is set, then anchors do not match at newline
     characters in the string.
   If not set, then anchors do match at newlines.  }
  REG_NEWLINE = (REG_ICASE shl 1);
  {$EXTERNALSYM REG_NEWLINE}

{ If this bit is set, then report only success or fail in regexec.
   If not set, then returns differ between not matching and errors.  }
  REG_NOSUB = (REG_NEWLINE shl 1);
  {$EXTERNALSYM REG_NOSUB}


{ POSIX `eflags' bits (i.e., information for regexec).  }

const
{ If this bit is set, then the beginning-of-line operator doesn't match
     the beginning of the string (presumably because it's not the
     beginning of a line).
   If not set, then the beginning-of-line operator does match the
     beginning of the string.  }
  REG_NOTBOL = 1;
  {$EXTERNALSYM REG_NOTBOL}

{ Like REG_NOTBOL, except for the end-of-line.  }
  REG_NOTEOL = (1 shl 1);
  {$EXTERNALSYM REG_NOTEOL}


{ If any error codes are removed, changed, or added, update the
   `re_error_msg' table in regex.c.  }
type
  reg_errcode_t =
  (
  //#ifdef _XOPEN_SOURCE
    REG_ENOSYS = -1,    { This will never happen for this implementation.  }
    {$EXTERNALSYM REG_ENOSYS}
  //#endif

    REG_NOERROR = 0,    { Success.  }
    {$EXTERNALSYM REG_NOERROR}
    REG_NOMATCH,        { Didn't find a match (for regexec).  }
    {$EXTERNALSYM REG_NOMATCH}

    { POSIX regcomp return error codes.  (In the order listed in the standard.)  }
    REG_BADPAT,         { Invalid pattern.  }
    {$EXTERNALSYM REG_BADPAT}
    REG_ECOLLATE,       { Not implemented.  }
    {$EXTERNALSYM REG_ECOLLATE}
    REG_ECTYPE,         { Invalid character class name.  }
    {$EXTERNALSYM REG_ECTYPE}
    REG_EESCAPE,        { Trailing backslash.  }
    {$EXTERNALSYM REG_EESCAPE}
    REG_ESUBREG,        { Invalid back reference.  }
    {$EXTERNALSYM REG_ESUBREG}
    REG_EBRACK,         { Unmatched left bracket.  }
    {$EXTERNALSYM REG_EBRACK}
    REG_EPAREN,         { Parenthesis imbalance.  }
    {$EXTERNALSYM REG_EPAREN}
    REG_EBRACE,         { Unmatched \{.  }
    {$EXTERNALSYM REG_EBRACE}
    REG_BADBR,          // { Invalid contents of \{\}.  }
    {$EXTERNALSYM REG_BADBR}
    REG_ERANGE,         { Invalid range end.  }
    {$EXTERNALSYM REG_ERANGE}
    REG_ESPACE,         { Ran out of memory.  }
    {$EXTERNALSYM REG_ESPACE}
    REG_BADRPT,         { No preceding re for repetition op.  }
    {$EXTERNALSYM REG_BADRPT}

    { Error codes we've added.  }
    REG_EEND,           { Premature end.  }
    {$EXTERNALSYM REG_EEND}
    REG_ESIZE,          { Compiled pattern bigger than 2^16 bytes.  }
    {$EXTERNALSYM REG_ESIZE}
    REG_ERPAREN         { Unmatched ) or \); not returned from regcomp.  }
    {$EXTERNALSYM REG_ERPAREN}
  );
  {$EXTERNALSYM reg_errcode_t}

{ This data structure represents a compiled pattern.  Before calling
   the pattern compiler, the fields `buffer', `allocated', `fastmap',
   `translate', and `no_sub' can be set.  After the pattern has been
   compiled, the `re_nsub' field is available.  All other fields are
   private to the regex routines.  }

type
  RE_TRANSLATE_TYPE = PChar;
  {$EXTERNALSYM RE_TRANSLATE_TYPE}

const
  REGS_UNALLOCATED = 0;
  {$EXTERNALSYM REGS_UNALLOCATED}
  REGS_REALLOCATE = 1;
  {$EXTERNALSYM REGS_REALLOCATE}
  REGS_FIXED = 2;
  {$EXTERNALSYM REGS_FIXED}

type
  re_pattern_buffer = {packed} record
  {
  { [[[begin pattern_buffer]]] }
          { Space that holds the compiled pattern.  It is declared as
            `unsigned char *' because its elements are
             sometimes used as array indexes.  }
    buffer: PByte;

          { Number of bytes to which `buffer' points.  }
    allocated: LongWord;

          { Number of bytes actually used in `buffer'.  }
    used: LongWord;

          { Syntax setting with which the pattern was compiled.  }
    syntax: reg_syntax_t;

          { Pointer to a fastmap, if any, otherwise zero.  re_search uses
             the fastmap, if there is one, to skip over impossible
             starting points for matches.  }
    fastmap: PChar;

          { Either a translate table to apply to all characters before
             comparing them, or zero for no translation.  The translation
             is applied to a pattern when it is compiled and to a string
             when it is matched.  }
    translate: RE_TRANSLATE_TYPE;

          { Number of subexpressions found by the compiler.  }
    re_nsub: size_t;

    __bitfield: Cardinal;
(*
          { Zero if this pattern cannot match the empty string, one else.
             Well, in truth it's used only in `re_search_2', to see
             whether or not we should use the fastmap, so we don't set
             this absolutely perfectly; see `re_compile_fastmap' (the
             `duplicate' case).  }
    unsigned can_be_null : 1;

          { If REGS_UNALLOCATED, allocate space in the `regs' structure
               for `max (RE_NREGS, re_nsub + 1)' groups.
             If REGS_REALLOCATE, reallocate space if necessary.
             If REGS_FIXED, use what's there.  }
    unsigned regs_allocated : 2;

          { Set to zero when `regex_compile' compiles a pattern; set to one
             by `re_compile_fastmap' if it updates the fastmap.  }
    unsigned fastmap_accurate : 1;

          { If set, `re_match_2' does not return information about
             subexpressions.  }
    unsigned no_sub : 1;

          { If set, a beginning-of-line anchor doesn't match at the
             beginning of the string.  }
    unsigned not_bol : 1;

          { Similarly for an end-of-line anchor.  }
    unsigned not_eol : 1;

          { If true, an anchor at a newline matches.  }
    unsigned newline_anchor : 1;
*)
  { [[[end pattern_buffer]]] }
  end;
  {$EXTERNALSYM re_pattern_buffer}
  TRePatternBuffer = re_pattern_buffer;
  PRePatternBuffer = ^TRePatternBuffer;

type
  regex_t = re_pattern_buffer;
  {$EXTERNALSYM regex_t}
  TRegEx = regex_t;
  PRegEx = ^TRegEx;

{ Type for byte offsets within the string.  POSIX mandates this.  }
type
  regoff_t = Integer;
  {$EXTERNALSYM regoff_t}
  TRegOff = regoff_t;
  PRegOff = ^TRegOff;

{ This is the structure we store register match data in.  See
   regex.texinfo for a full description of what registers match.  }
type
  re_registers = {packed} record
    num_regs: Cardinal;
    start: PRegOff;
    end_: PRegOff;
  end;
  {$EXTERNALSYM re_registers}
  TReRegisters = re_registers;
  PReRegisters = ^TReRegisters;


{ If `regs_allocated' is REGS_UNALLOCATED in the pattern buffer,
   `re_match_2' returns information about at least this many registers
   the first time a `regs' structure is passed.  }
const
  RE_NREGS = 30;
  {$EXTERNALSYM RE_NREGS}


{ POSIX specification for registers.  Aside from the different names than
   `re_registers', POSIX uses an array of structures, instead of a
   structure of arrays.  }
type
  regmatch_t = {packed} record
    rm_so: regoff_t;  { Byte offset from string's start to substring's start.  }
    rm_eo: regoff_t;  { Byte offset from string's start to substring's end.  }
  end;
  {$EXTERNALSYM regmatch_t}
  TRegMatch = regmatch_t;
  PRegMatch = ^TRegMatch;

{ Declarations for routines.  }

{ Sets the current default syntax to SYNTAX, and return the old syntax.
   You can also simply assign to the `re_syntax_options' variable.  }
function re_set_syntax(syntax: reg_syntax_t): reg_syntax_t; cdecl;
{$EXTERNALSYM re_set_syntax}

{ Compile the regular expression PATTERN, with length LENGTH
   and syntax given by the global `re_syntax_options', into the buffer
   BUFFER.  Return NULL if successful, and an error string if not.  }
function re_compile_pattern(pattern: PChar; length: size_t;
  var buffer: re_pattern_buffer): PChar; cdecl;
{$EXTERNALSYM re_compile_pattern}


{ Compile a fastmap for the compiled pattern in BUFFER; used to
   accelerate searches.  Return 0 if successful and -2 if was an
   internal error.  }
function re_compile_fastmap(var buffer: re_pattern_buffer): Integer; cdecl;
{$EXTERNALSYM re_compile_fastmap}


{ Search in the string STRING (with length LENGTH) for the pattern
   compiled into BUFFER.  Start searching at position START, for RANGE
   characters.  Return the starting position of the match, -1 for no
   match, or -2 for an internal error.  Also return register
   information in REGS (if REGS and BUFFER->no_sub are nonzero).  }
function re_search(var buffer: re_pattern_buffer; SourceString: PChar;
  length: Integer; start: Integer; range: Integer; regs: PReRegisters): Integer; cdecl;
{$EXTERNALSYM re_search}


{ Like `re_search', but search in the concatenation of STRING1 and
   STRING2.  Also, stop searching at index START + STOP.  }
function re_search_2(var buffer: re_pattern_buffer; string1: PChar;
  length1: Integer; string2: PChar; length2: Integer;
  start: Integer; range: Integer; regs: PReRegisters; stop: Integer): Integer; cdecl;
{$EXTERNALSYM re_search_2}


{ Like `re_search', but return how many characters in STRING the regexp
   in BUFFER matched, starting at position START.  }
function re_match(var buffer: re_pattern_buffer; SourceString: PChar;
  length: Integer; start: Integer; regs: PReRegisters): Integer; cdecl;
{$EXTERNALSYM re_match}


{ Relates to `re_match' as `re_search_2' relates to `re_search'.  }
function re_match_2(var buffer: re_pattern_buffer; string1: PChar;
  length1: Integer; string2: PChar; length2: Integer;
  start: Integer; regs: PReRegisters; stop: Integer): Integer; cdecl;
{$EXTERNALSYM re_match_2}


{ Set REGS to hold NUM_REGS registers, storing them in STARTS and
   ENDS.  Subsequent matches using BUFFER and REGS will use this memory
   for recording register information.  STARTS and ENDS must be
   allocated with malloc, and must each be at least `NUM_REGS * sizeof
   (regoff_t)' bytes long.

   If NUM_REGS == 0, then subsequent matches should allocate their own
   register data.

   Unless this function is called, the first search or match using
   PATTERN_BUFFER will allocate its own register data, without
   freeing the old data.  }
procedure re_set_registers(var buffer: re_pattern_buffer; var regs: re_registers;
  num_regs: Cardinal; var starts: regoff_t; var ends: regoff_t); cdecl;
{$EXTERNALSYM re_set_registers}

{ 4.2 bsd compatibility.  }
function re_comp(Param: PChar): PChar; cdecl;
{$EXTERNALSYM re_comp}
function re_exec(Param: PChar): Integer; cdecl;
{$EXTERNALSYM re_exec}

{ POSIX compatibility.  }
function regcomp(var __preg: TRegEx; __pattern: PChar; __cflags: Integer): Integer; cdecl;
{$EXTERNALSYM regcomp}

function regexec(const __preg: TRegEx; __string: PChar; __nmatch: size_t;
  __pmatch: PRegMatch; __eflags: Integer): Integer; cdecl;
{$EXTERNALSYM regexec}

function regerror(__errcode: Integer; const __preg: TRegEx;
  __errbuf: PChar; __errbuf_size: size_t): size_t; cdecl;
{$EXTERNALSYM regerror}

procedure regfree(var __preg: regex_t); cdecl;
{$EXTERNALSYM regfree}



// Translated from regexp.h


(* Not translated because of this comment: *)


{ The contents of this header file was first standardized in X/Open

   System Interface and Headers Issue 2, originally coming from SysV.
   In issue 4, version 2, it is marked as TO BE WITDRAWN.

   This code shouldn't be used in any newly written code.  It is
   included only for compatibility reasons.  Use the POSIX definition
   in <regex.h> for portable applications and a reasonable interface.  }


// Translated from net/ethernet.h


(*
#include <linux/if_ether.h>     { IEEE 802.3 Ethernet constants }
*)

{ This is a name for the 48 bit ethernet address available on many systems.  }
type
  ether_addr = {packed} record
    ether_addr_octet: packed array[0..ETH_ALEN-1] of u_int8_t;
  end; // __attribute__ ((__packed__));
  {$EXTERNALSYM ether_addr}
  TEtherAddr = ether_addr;
  PEtherAddr = ^TEtherAddr;

{ 10Mb/s ethernet header }
  ether_header = {packed} record
    ether_dhost: packed array[0..ETH_ALEN-1]of u_int8_t;  { destination eth addr	}
    ether_shost: packed array[0..ETH_ALEN-1] of u_int8_t; { source ether addr	}
    ether_type: u_int16_t;                                { packet type ID field	}
  end; // __attribute__ ((__packed__));
  {$EXTERNALSYM ether_header}

{ Ethernet protocol ID's }
const
  ETHERTYPE_PUP          = $0200;       { Xerox PUP }
  {$EXTERNALSYM ETHERTYPE_PUP}
  ETHERTYPE_IP           = $0800;       { IP }
  {$EXTERNALSYM ETHERTYPE_IP}
  ETHERTYPE_ARP          = $0806;       { Address resolution }
  {$EXTERNALSYM ETHERTYPE_ARP}
  ETHERTYPE_REVARP       = $8035;       { Reverse ARP }
  {$EXTERNALSYM ETHERTYPE_REVARP}

  ETHER_ADDR_LEN         = ETH_ALEN;    { size of ethernet addr }
  {$EXTERNALSYM ETHER_ADDR_LEN}
  ETHER_TYPE_LEN         = 2;           { bytes in type field }
  {$EXTERNALSYM ETHER_TYPE_LEN}
  ETHER_CRC_LEN          = 4;           { bytes in CRC field }
  {$EXTERNALSYM ETHER_CRC_LEN}
  ETHER_HDR_LEN          = ETH_HLEN;    { total octets in header }
  {$EXTERNALSYM ETHER_HDR_LEN}
  // NOTE: ETHER_CRC_LEN used instead of ETH_CRC_LEN (which is defined nowhere)
  ETHER_MIN_LEN          = (ETH_ZLEN + ETHER_CRC_LEN); { min packet length }
  {$EXTERNALSYM ETHER_MIN_LEN}
  // NOTE: ETHER_CRC_LEN used instead of ETH_CRC_LEN (which is defined nowhere)
  ETHER_MAX_LEN          = (ETH_FRAME_LEN + ETHER_CRC_LEN); { max packet length }
  {$EXTERNALSYM ETHER_MAX_LEN}


{ make sure ethenet length is valid }
function ETHER_IS_VALID_LEN(foo: Cardinal): Boolean;
{$EXTERNALSYM ETHER_IS_VALID_LEN}

{
 * The ETHERTYPE_NTRAILER packet types starting at ETHERTYPE_TRAIL have
 * (type-ETHERTYPE_TRAIL)*512 bytes of data followed
 * by an ETHER type (as given above) and then the (variable-length) header.
 }
const
  ETHERTYPE_TRAIL      = $1000;      { Trailer packet }
  {$EXTERNALSYM ETHERTYPE_TRAIL}
  ETHERTYPE_NTRAILER   = 16;
  {$EXTERNALSYM ETHERTYPE_NTRAILER}

  ETHERMTU             = ETH_DATA_LEN;
  {$EXTERNALSYM ETHERMTU}
  ETHERMIN             = (ETHER_MIN_LEN - ETHER_HDR_LEN - ETHER_CRC_LEN);
  {$EXTERNALSYM ETHERMIN}


// Translated from net/if.h

{ Standard interface flags. }
const
  IFF_UP = $1;             { Interface is up.  }
  {$EXTERNALSYM IFF_UP}
  IFF_BROADCAST = $2;      { Broadcast address valid.  }
  {$EXTERNALSYM IFF_BROADCAST}
  IFF_DEBUG = $4;          { Turn on debugging.  }
  {$EXTERNALSYM IFF_DEBUG}
  IFF_LOOPBACK = $8;       { Is a loopback net.  }
  {$EXTERNALSYM IFF_LOOPBACK}
  IFF_POINTOPOINT = $10;   { Interface is point-to-point link.  }
  {$EXTERNALSYM IFF_POINTOPOINT}
  IFF_NOTRAILERS = $20;    { Avoid use of trailers.  }
  {$EXTERNALSYM IFF_NOTRAILERS}
  IFF_RUNNING = $40;       { Resources allocated.  }
  {$EXTERNALSYM IFF_RUNNING}
  IFF_NOARP = $80;         { No address resolution protocol.  }
  {$EXTERNALSYM IFF_NOARP}
  IFF_PROMISC = $100;      { Receive all packets.  }
  {$EXTERNALSYM IFF_PROMISC}

  { Not supported }
  IFF_ALLMULTI = $200;     { Receive all multicast packets.  }
  {$EXTERNALSYM IFF_ALLMULTI}

  IFF_MASTER = $400;       { Master of a load balancer.  }
  {$EXTERNALSYM IFF_MASTER}
  IFF_SLAVE = $800;        { Slave of a load balancer.  }
  {$EXTERNALSYM IFF_SLAVE}

  IFF_MULTICAST = $1000;   { Supports multicast.  }
  {$EXTERNALSYM IFF_MULTICAST}

  IFF_PORTSEL = $2000;     { Can set media type.  }
  {$EXTERNALSYM IFF_PORTSEL}
  IFF_AUTOMEDIA = $4000;   { Auto media select active.  }
  {$EXTERNALSYM IFF_AUTOMEDIA}


{ The ifaddr structure contains information about one address of an
   interface.  They are maintained by the different address families,
   are allocated and attached when an address is set, and are linked
   together so all addresses for an interface can be located.  }
type
  _ifa_ifu = {packed} record
    ifu_broadaddr: sockaddr;
    ifu_dstaddr: sockaddr;
  end;
  // used anonymously in header file

  PIfAddr = ^TIfAddr;

  ifaddr = {packed} record
    ifa_addr: sockaddr;       { Address of interface.  }
    ifa_ifu: _ifa_ifu;
    ifa_ifp: Pointer;         { Back-pointer to interface.  } (* struct iface *ifa_ifp *)
    ifa_next: PIfAddr;        { Next address for interface.  }
  end;
  {$EXTERNALSYM ifaddr}
  TIfAddr = ifaddr;

(* Cannot be translated
#define ifa_broadaddr ifa_ifu.ifu_broadaddr { broadcast address	}
#define ifa_dstaddr   ifa_ifu.ifu_dstaddr   { other end of link	}
*)

{ Device mapping structure. I'd just gone off and designed a
   beautiful scheme using only loadable modules with arguments for
   driver options and along come the PCMCIA people 8)

   Ah well. The get() side of this is good for WDSETUP, and it'll be
   handy for debugging things. The set side is fine for now and being
   very small might be worth keeping for clean configuration.  }

  ifmap = {packed} record
    mem_start: LongWord;
    mem_end: LongWord;
    base_addr: Word;
    irq: Byte;
    dma: Byte;
    port: Byte;
    { 3 bytes spare }
  end;
  {$EXTERNALSYM ifmap}

{ Interface request structure used for socket ioctl's.  All interface
   ioctl's must have parameter definitions which begin with ifr_name.
   The remainder may be interface specific.  }


const
  IFHWADDRLEN = 6;
  {$EXTERNALSYM IFHWADDRLEN}
  IFNAMSIZ    = 16;
  {$EXTERNALSYM IFNAMSIZ}

type
  ifreq = {packed} record
    ifrn_name: packed array[0..IFNAMSIZ-1] of Char; { Interface name, e.g. "en0".  }
    case Integer of
       0:( ifru_addr: sockaddr; );
       1:( ifru_dstaddr: sockaddr; );
       2:( ifru_broadaddr: sockaddr; );
       3:( ifru_netmask: sockaddr; );
       4:( ifru_hwaddr: sockaddr; );
       5:( ifru_flags: Smallint; );
       6:( ifru_ivalue: Integer; );
       7:( ifru_map: ifmap; );
       8:( ifru_slave: packed array[0..IFNAMSIZ-1] of Char; ); { Just fits the size }
       9:( ifru_newname: packed array[0..IFNAMSIZ-1] of Char; );
      10:( ifru_data: __caddr_t; );
    end;
  {$EXTERNALSYM ifreq}
  TIFreq = ifreq;
  PIFreq = ^TIFreq;

(* Cannot be translated
#define ifr_name	ifr_ifrn.ifrn_name	{ interface name 	}
#define ifr_hwaddr	ifr_ifru.ifru_hwaddr	{ MAC address 		}
#define	ifr_addr	ifr_ifru.ifru_addr	{ address		}
#define	ifr_dstaddr	ifr_ifru.ifru_dstaddr	{ other end of p-p lnk	}
#define	ifr_broadaddr	ifr_ifru.ifru_broadaddr	{ broadcast address	}
#define	ifr_netmask	ifr_ifru.ifru_netmask	{ interface net mask	}
#define	ifr_flags	ifr_ifru.ifru_flags	{ flags		}
#define	ifr_metric	ifr_ifru.ifru_ivalue	{ metric		}
#define	ifr_mtu		ifr_ifru.ifru_mtu	{ mtu			}
#define ifr_map		ifr_ifru.ifru_map	{ device map		}
#define ifr_slave	ifr_ifru.ifru_slave	{ slave device		}
#define	ifr_data	ifr_ifru.ifru_data	{ for use by interface	}
#define ifr_ifindex	ifr_ifru.ifru_ivalue    { interface index      }
#define ifr_bandwidth	ifr_ifru.ifru_ivalue	{ link bandwidth	}
#define ifr_qlen	ifr_ifru.ifru_ivalue	{ queue length		}
#define ifr_newname	ifr_ifru.ifru_newname	{ New name		}
*)

(*
#define _IOT_ifreq	_IOT(_IOTS(struct ifreq),1,0,0,0,0) { not right }
*)

{ Structure used in SIOCGIFCONF request.  Used to retrieve interface
   configuration for machine (useful for programs which must know all
   networks accessible).  }
type
  ifconf = {packed} record
    ifc_len: Integer;                 { Size of buffer.  }
    ifc_ifcu: {packed} record
                case Integer of
                  0: (ifcu_buf: __caddr_t);
                  1: (ifcu_req: PIFreq);
                end;
  end;
  {$EXTERNALSYM ifconf}

(* Cannot be translated
#define	ifc_buf	ifc_ifcu.ifcu_buf	{ Buffer address.  }
#define	ifc_req	ifc_ifcu.ifcu_req	{ Array of structures.  }
*)

(*
#define _IOT_ifconf _IOT(_IOTS(struct ifconf),1,0,0,0,0) { not right }
*)

{ Convert an interface name to an index, and vice versa.  }

function if_nametoindex(__ifname: PChar): Cardinal; cdecl;
{$EXTERNALSYM if_nametoindex}
function if_indextoname(__ifindex: Cardinal; __ifname: PChar): PChar; cdecl;
{$EXTERNALSYM if_indextoname}

{ Return a list of all interfaces and their indices.  }

type
  _if_nameindex = {packed} record
    if_index: Cardinal;    { 1, 2, ... }
    if_name: PChar;        { null terminated name: "eth0", ... }
  end;
  {.$EXTERNALSYM if_nameindex} // Renamed from if_nameindex to avoid identifier conflict 
  TIfNameIndex = _if_nameindex;
  PIfNameIndex = ^TIfNameIndex;

function if_nameindex(): PIfNameIndex; cdecl;
{$EXTERNALSYM if_indextoname}

{ Free the data returned from if_nameindex.  }

procedure if_freenameindex(__ptr: PIfNameIndex); cdecl;
{$EXTERNALSYM if_freenameindex}


// Translated from net/if_arp.h

const
{ Some internals from deep down in the kernel.  }
  MAX_ADDR_LEN = 7;
  {$EXTERNALSYM MAX_ADDR_LEN}


{ This structure defines an ethernet arp header.  }

{ ARP protocol opcodes. }
const
  ARPOP_REQUEST    = 1;        { ARP request.  }
  {$EXTERNALSYM ARPOP_REQUEST}
  ARPOP_REPLY      = 2;        { ARP reply.  }
  {$EXTERNALSYM ARPOP_REPLY}
  ARPOP_RREQUEST   = 3;        { RARP request.  }
  {$EXTERNALSYM ARPOP_RREQUEST}
  ARPOP_RREPLY     = 4;        { RARP reply.  }
  {$EXTERNALSYM ARPOP_RREPLY}
  ARPOP_InREQUEST  = 8;        { InARP request.  }
  {$EXTERNALSYM ARPOP_InREQUEST}
  ARPOP_InREPLY    = 9;        { InARP reply.  }
  {$EXTERNALSYM ARPOP_InREPLY}
  ARPOP_NAK        = 10;       { (ATM)ARP NAK.  }
  {$EXTERNALSYM ARPOP_NAK}

{ See RFC 826 for protocol description.  ARP packets are variable
   in size; the arphdr structure defines the fixed-length portion.
   Protocol type values are the same as those for 10 Mb/s Ethernet.
   It is followed by the variable-sized fields ar_sha, arp_spa,
   arp_tha and arp_tpa in that order, according to the lengths
   specified.  Field names used correspond to RFC 826.  }

type
  arphdr = {packed} record
    ar_hrd: Word;      { Format of hardware address.  }
    ar_pro: Word;      { Format of protocol address.  }
    ar_hln: Byte;      { Length of hardware address.  }
    ar_pln: Byte;      { Length of protocol address.  }
    ar_op: Word;       { ARP opcode (command).  }
(* #if 0
    { Ethernet looks like this : This bit is variable sized however...  }
    unsigned char __ar_sha[ETH_ALEN];   { Sender hardware address.  }
    unsigned char __ar_sip[4];          { Sender IP address.  }
    unsigned char __ar_tha[ETH_ALEN];   { Target hardware address.  }
    unsigned char __ar_tip[4];          { Target IP address.  }
#endif *)
  end;
  {$EXTERNALSYM arphdr}


const
{ ARP protocol HARDWARE identifiers. }
  ARPHRD_NETROM     = 0;      { From KA9Q: NET/ROM pseudo. }
  {$EXTERNALSYM ARPHRD_NETROM}
  ARPHRD_ETHER      = 1;      { Ethernet 10/100Mbps.  }
  {$EXTERNALSYM ARPHRD_ETHER}
  ARPHRD_EETHER     = 2;      { Experimental Ethernet.  }
  {$EXTERNALSYM ARPHRD_EETHER}
  ARPHRD_AX25       = 3;      { AX.25 Level 2.  }
  {$EXTERNALSYM ARPHRD_AX25}
  ARPHRD_PRONET     = 4;      { PROnet token ring.  }
  {$EXTERNALSYM ARPHRD_PRONET}
  ARPHRD_CHAOS      = 5;      { Chaosnet.  }
  {$EXTERNALSYM ARPHRD_CHAOS}
  ARPHRD_IEEE802    = 6;      { IEEE 802.2 Ethernet/TR/TB.  }
  {$EXTERNALSYM ARPHRD_IEEE802}
  ARPHRD_ARCNET     = 7;      { ARCnet.  }
  {$EXTERNALSYM ARPHRD_ARCNET}
  ARPHRD_APPLETLK   = 8;      { APPLEtalk.  }
  {$EXTERNALSYM ARPHRD_APPLETLK}
  ARPHRD_DLCI       = 15;     { Frame Relay DLCI.  }
  {$EXTERNALSYM ARPHRD_DLCI}
  ARPHRD_ATM        = 19;     { ATM.  }
  {$EXTERNALSYM ARPHRD_ATM}
  ARPHRD_METRICOM   = 23;     { Metricom STRIP (new IANA id).  }
  {$EXTERNALSYM ARPHRD_METRICOM}

{ Dummy types for non ARP hardware }
  ARPHRD_SLIP       = 256;
  {$EXTERNALSYM ARPHRD_SLIP}
  ARPHRD_CSLIP      = 257;
  {$EXTERNALSYM ARPHRD_CSLIP}
  ARPHRD_SLIP6      = 258;
  {$EXTERNALSYM ARPHRD_SLIP6}
  ARPHRD_CSLIP6     = 259;
  {$EXTERNALSYM ARPHRD_CSLIP6}
  ARPHRD_RSRVD      = 260;    { Notional KISS type.  }
  {$EXTERNALSYM ARPHRD_RSRVD}
  ARPHRD_ADAPT      = 264;
  {$EXTERNALSYM ARPHRD_ADAPT}
  ARPHRD_ROSE       = 270;
  {$EXTERNALSYM ARPHRD_ROSE}
  ARPHRD_X25        = 271;    { CCITT X.25.  }
  {$EXTERNALSYM ARPHRD_X25}
  ARPHDR_HWX25      = 272;    { Boards with X.25 in firmware.  }
  {$EXTERNALSYM ARPHDR_HWX25}
  ARPHRD_PPP        = 512;
  {$EXTERNALSYM ARPHRD_PPP}
  ARPHRD_HDLC       = 513;    { (Cisco) HDLC.  }
  {$EXTERNALSYM ARPHRD_HDLC}
  ARPHRD_LAPB       = 516;    { LAPB.  }
  {$EXTERNALSYM ARPHRD_LAPB}
  ARPHRD_DDCMP      = 517;    { Digital's DDCMP.  }
  {$EXTERNALSYM ARPHRD_DDCMP}

  ARPHRD_TUNNEL     = 768;    { IPIP tunnel.  }
  {$EXTERNALSYM ARPHRD_TUNNEL}
  ARPHRD_TUNNEL6    = 769;    { IPIP6 tunnel.  }
  {$EXTERNALSYM ARPHRD_TUNNEL6}
  ARPHRD_FRAD       = 770;    { Frame Relay Access Device.  }
  {$EXTERNALSYM ARPHRD_FRAD}
  ARPHRD_SKIP       = 771;    { SKIP vif.  }
  {$EXTERNALSYM ARPHRD_SKIP}
  ARPHRD_LOOPBACK   = 772;    { Loopback device.  }
  {$EXTERNALSYM ARPHRD_LOOPBACK}
  ARPHRD_LOCALTLK   = 773;    { Localtalk device.  }
  {$EXTERNALSYM ARPHRD_LOCALTLK}
  ARPHRD_FDDI       = 774;    { Fiber Distributed Data Interface. }
  {$EXTERNALSYM ARPHRD_FDDI}
  ARPHRD_BIF        = 775;    { AP1000 BIF.  }
  {$EXTERNALSYM ARPHRD_BIF}
  ARPHRD_SIT        = 776;    { sit0 device - IPv6-in-IPv4.  }
  {$EXTERNALSYM ARPHRD_SIT}
  ARPHRD_IPDDP      = 777;    { IP-in-DDP tunnel.  }
  {$EXTERNALSYM ARPHRD_IPDDP}
  ARPHRD_IPGRE      = 778;    { GRE over IP.  }
  {$EXTERNALSYM ARPHRD_IPGRE}
  ARPHRD_PIMREG     = 779;    { PIMSM register interface.  }
  {$EXTERNALSYM ARPHRD_PIMREG}
  ARPHRD_HIPPI      = 780;    { High Performance Parallel I'face. }
  {$EXTERNALSYM ARPHRD_HIPPI}
  ARPHRD_ASH        = 781;    { (Nexus Electronics) Ash.  }
  {$EXTERNALSYM ARPHRD_ASH}
  ARPHRD_ECONET     = 782;    { Acorn Econet.  }
  {$EXTERNALSYM ARPHRD_ECONET}
  ARPHRD_IRDA       = 783;    { Linux-IrDA.  }
  {$EXTERNALSYM ARPHRD_IRDA}
  ARPHRD_FCPP       = 784;    { Point to point fibrechanel.  }
  {$EXTERNALSYM ARPHRD_FCPP}
  ARPHRD_FCAL       = 785;    { Fibrechanel arbitrated loop.  }
  {$EXTERNALSYM ARPHRD_FCAL}
  ARPHRD_FCPL       = 786;    { Fibrechanel public loop.  }
  {$EXTERNALSYM ARPHRD_FCPL}
  ARPHRD_FCPFABRIC  = 787;    { Fibrechanel fabric.  }
  {$EXTERNALSYM ARPHRD_FCPFABRIC}
  ARPHRD_IEEE802_TR = 800;    { Magic type ident for TR.  }
  {$EXTERNALSYM ARPHRD_IEEE802_TR}

type
{ ARP ioctl request.  }
  arpreq = {packed} record
    arp_pa: sockaddr;        { Protocol address.  }
    arp_ha: sockaddr;        { Hardware address.  }
    arp_flags: Integer;      { Flags.  }
    arp_netmask: sockaddr;   { Netmask (only for proxy arps).  }
    arp_dev: packed array[0..16-1] of Char;
  end;
  {$EXTERNALSYM arpreq}

  arpreq_old = {packed} record
    arp_pa: sockaddr;       { Protocol address.  }
    arp_ha: sockaddr;       { Hardware address.  }
    arp_flags: Integer;     { Flags.  }
    arp_netmask: sockaddr;  { Netmask (only for proxy arps).  }
  end;
  {$EXTERNALSYM arpreq_old}

{ ARP Flag values.  }
const
  ATF_COM          = $02;   { Completed entry (ha valid).  }
  {$EXTERNALSYM ATF_COM}
  ATF_PERM         = $04;   { Permanent entry.  }
  {$EXTERNALSYM ATF_PERM}
  ATF_PUBL         = $08;   { Publish entry.  }
  {$EXTERNALSYM ATF_PUBL}
  ATF_USETRAILERS  = $10;   { Has requested trailers.  }
  {$EXTERNALSYM ATF_USETRAILERS}
  ATF_NETMASK      = $20;   { Want to use a netmask (only for proxy entries).  }
  {$EXTERNALSYM ATF_NETMASK}
  ATF_DONTPUB      = $40;   { Don't answer this addresses.  }
  {$EXTERNALSYM ATF_DONTPUB}
  ATF_MAGIC        = $80;   { Automatically added entry.  }
  {$EXTERNALSYM ATF_MAGIC}


{ Support for the user space arp daemon, arpd.  }
  ARPD_UPDATE = $01;
  {$EXTERNALSYM ARPD_UPDATE}
  ARPD_LOOKUP = $02;
  {$EXTERNALSYM ARPD_LOOKUP}
  ARPD_FLUSH  = $03;
  {$EXTERNALSYM ARPD_FLUSH}

type
  arpd_request = {packed} record
    req: Word;            { Request type.  }
    ip: u_int32_t;        { IP address of entry.  }
    dev: LongWord;        { Device entry is tied to.  }
    stamp: LongWord;
    updated: LongWord;
    ha: packed array[0..MAX_ADDR_LEN-1] of Byte;  { Hardware address.  }
  end;
  {$EXTERNALSYM arpd_request}


// Translated from net/if_packet.h

{ This is the SOCK_PACKET address structure as used in Linux 2.0.
   From Linux 2.1 the AF_PACKET interface is preferred and you should
   consider using it in place of this one.  }

  sockaddr_pkt = {packed} record
    spkt_family: sa_family_t;
    spkt_device: packed array[0..14-1] of Byte;
    spkt_protocol: Word;
  end;
  {$EXTERNALSYM sockaddr_pkt}


// Translated from net/ppp_defs.h

(*
#include <asm/types.h>
#include <linux/ppp_defs.h>
*)


// Translated from net/if_ppp.h

(*
#include <net/if.h>
#include <sys/ioctl.h>
#include <net/ppp_defs.h>
*)

{ Packet sizes }

const
  PPP_MTU       = 1500;     { Default MTU (size of Info field) }
  {$EXTERNALSYM PPP_MTU}
  PPP_MAXMRU    = 65000;    { Largest MRU we allow }
  {$EXTERNALSYM PPP_MAXMRU}
  PPP_VERSION   = '2.2.0';
  {$EXTERNALSYM PPP_VERSION}
  PPP_MAGIC     = $5002;    { Magic value for the ppp structure }
  {$EXTERNALSYM PPP_MAGIC}
  PROTO_IPX     = $002b;    { protocol numbers }
  {$EXTERNALSYM PROTO_IPX}
  PROTO_DNA_RT  = $0027;    { DNA Routing }
  {$EXTERNALSYM PROTO_DNA_RT}


{ Bit definitions for flags. }

const
  SC_COMP_AC       = $00000002;    { header compression (output) }
  {$EXTERNALSYM SC_COMP_AC}
  SC_COMP_TCP      = $00000004;    { TCP (VJ) compression (output) }
  {$EXTERNALSYM SC_COMP_TCP}
  SC_NO_TCP_CCID   = $00000008;    { disable VJ connection-id comp. }
  {$EXTERNALSYM SC_NO_TCP_CCID}
  SC_REJ_COMP_AC   = $00000010;    { reject adrs/ctrl comp. on input }
  {$EXTERNALSYM SC_REJ_COMP_AC}
  SC_REJ_COMP_TCP  = $00000020;    { reject TCP (VJ) comp. on input }
  {$EXTERNALSYM SC_REJ_COMP_TCP}
  SC_CCP_OPEN      = $00000040;    { Look at CCP packets }
  {$EXTERNALSYM SC_CCP_OPEN}
  SC_CCP_UP        = $00000080;    { May send/recv compressed packets }
  {$EXTERNALSYM SC_CCP_UP}
  SC_ENABLE_IP     = $00000100;    { IP packets may be exchanged }
  {$EXTERNALSYM SC_ENABLE_IP}
  SC_COMP_RUN      = $00001000;    { compressor has been inited }
  {$EXTERNALSYM SC_COMP_RUN}
  SC_DECOMP_RUN    = $00002000;    { decompressor has been inited }
  {$EXTERNALSYM SC_DECOMP_RUN}
  SC_DEBUG         = $00010000;    { enable debug messages }
  {$EXTERNALSYM SC_DEBUG}
  SC_LOG_INPKT     = $00020000;    { log contents of good pkts recvd }
  {$EXTERNALSYM SC_LOG_INPKT}
  SC_LOG_OUTPKT    = $00040000;    { log contents of pkts sent }
  {$EXTERNALSYM SC_LOG_OUTPKT}
  SC_LOG_RAWIN     = $00080000;    { log all chars received }
  {$EXTERNALSYM SC_LOG_RAWIN}
  SC_LOG_FLUSH     = $00100000;    { log all chars flushed }
  {$EXTERNALSYM SC_LOG_FLUSH}
  SC_MASK          = $0fE0ffff;    { bits that user can change }
  {$EXTERNALSYM SC_MASK}

{ state bits }
  SC_ESCAPED       = $80000000;    { saw a PPP_ESCAPE }
  {$EXTERNALSYM SC_ESCAPED}
  SC_FLUSH         = $40000000;    { flush input until next PPP_FLAG }
  {$EXTERNALSYM SC_FLUSH}
  SC_VJ_RESET      = $20000000;    { Need to reset the VJ decompressor }
  {$EXTERNALSYM SC_VJ_RESET}
  SC_XMIT_BUSY     = $10000000;    { ppp_write_wakeup is active }
  {$EXTERNALSYM SC_XMIT_BUSY}
  SC_RCV_ODDP      = $08000000;    { have rcvd char with odd parity }
  {$EXTERNALSYM SC_RCV_ODDP}
  SC_RCV_EVNP      = $04000000;    { have rcvd char with even parity }
  {$EXTERNALSYM SC_RCV_EVNP}
  SC_RCV_B7_1      = $02000000;    { have rcvd char with bit 7 = 1 }
  {$EXTERNALSYM SC_RCV_B7_1}
  SC_RCV_B7_0      = $01000000;    { have rcvd char with bit 7 = 0 }
  {$EXTERNALSYM SC_RCV_B7_0}
  SC_DC_FERROR     = $00800000;    { fatal decomp error detected }
  {$EXTERNALSYM SC_DC_FERROR}
  SC_DC_ERROR      = $00400000;    { non-fatal decomp error detected }
  {$EXTERNALSYM SC_DC_ERROR}

{ Ioctl definitions. }
type
  npioctl = {packed} record
    protocol: Integer;   { PPP protocol, e.g. PPP_IP }
    mode: NPmode;
  end;
  {$EXTERNALSYM npioctl}

  Pu_int8_t = ^u_int8_t;

{ Structure describing a CCP configuration option, for PPPIOCSCOMPRESS }
  ppp_option_data = {packed} record
    ptr: Pu_int8_t;
    length: u_int32_t;
    transmit: Integer;
  end;
  {$EXTERNALSYM ppp_option_data}

  ifpppstatsreq = {packed} record
    b: ifreq;
    stats: ppp_stats;   { statistic information }
  end;
  {$EXTERNALSYM ifpppstatsreq}

  ifpppcstatsreq = {packed} record
    b: ifreq;
    stats: ppp_comp_stats;
  end;
  {$EXTERNALSYM ifpppcstatsreq}

(* Cannot translate this
#define ifr__name       b.ifr_ifrn.ifrn_name
#define stats_ptr       b.ifr_ifru.ifru_data
*)

{ Ioctl definitions. }

function PPPIOCGFLAGS: Cardinal;      { get configuration flags }
{$EXTERNALSYM PPPIOCGFLAGS}
function PPPIOCSFLAGS: Cardinal;      { set configuration flags }
{$EXTERNALSYM PPPIOCSFLAGS}
function PPPIOCGASYNCMAP: Cardinal;   { get async map }
{$EXTERNALSYM PPPIOCGASYNCMAP}
function PPPIOCSASYNCMAP: Cardinal;   { set async map }
{$EXTERNALSYM PPPIOCSASYNCMAP}
function PPPIOCGUNIT: Cardinal;       { get ppp unit number }
{$EXTERNALSYM PPPIOCGUNIT}
function PPPIOCGRASYNCMAP: Cardinal;  { get receive async map }
{$EXTERNALSYM PPPIOCGRASYNCMAP}
function PPPIOCSRASYNCMAP: Cardinal;  { set receive async map }
{$EXTERNALSYM PPPIOCSRASYNCMAP}
function PPPIOCGMRU: Cardinal;        { get max receive unit }
{$EXTERNALSYM PPPIOCGMRU}
function PPPIOCSMRU: Cardinal;        { set max receive unit }
{$EXTERNALSYM PPPIOCSMRU}
function PPPIOCSMAXCID: Cardinal;     { set VJ max slot ID }
{$EXTERNALSYM PPPIOCSMAXCID}
function PPPIOCGXASYNCMAP: Cardinal;  { get extended ACCM }
{$EXTERNALSYM PPPIOCGXASYNCMAP}
function PPPIOCSXASYNCMAP: Cardinal;  { set extended ACCM }
{$EXTERNALSYM PPPIOCSXASYNCMAP}
function PPPIOCXFERUNIT: Cardinal;    { transfer PPP unit }
{$EXTERNALSYM PPPIOCXFERUNIT}
function PPPIOCSCOMPRESS: Cardinal;
{$EXTERNALSYM PPPIOCSCOMPRESS}
function PPPIOCGNPMODE: Cardinal;     { get NP mode }
{$EXTERNALSYM PPPIOCGNPMODE}
function PPPIOCSNPMODE: Cardinal;     { set NP mode }
{$EXTERNALSYM PPPIOCSNPMODE}
function PPPIOCGDEBUG: Cardinal;      { Read debug level }
{$EXTERNALSYM PPPIOCGDEBUG}
function PPPIOCSDEBUG: Cardinal;      { Set debug level }
{$EXTERNALSYM PPPIOCSDEBUG}
function PPPIOCGIDLE: Cardinal;       { get idle time }
{$EXTERNALSYM PPPIOCGIDLE}

const
  SIOCGPPPSTATS  = (SIOCDEVPRIVATE + 0);
  {$EXTERNALSYM SIOCGPPPSTATS}
  SIOCGPPPVER    = (SIOCDEVPRIVATE + 1); { NEVER change this!! }
  {$EXTERNALSYM SIOCGPPPVER}
  SIOCGPPPCSTATS = (SIOCDEVPRIVATE + 2);
  {$EXTERNALSYM SIOCGPPPCSTATS}

(* Cannot translate this
#if !defined(ifr_mtu)
#define ifr_mtu	ifr_ifru.ifru_metric
#endif
*)


// Translated from net/if_shaper.h

(*
#include <features.h>
#include <sys/types.h>
#include <net/if.h>
#include <sys/ioctl.h>
*)

const
  SHAPER_QLEN = 10;
  {$EXTERNALSYM SHAPER_QLEN}
{
 *  This is a bit speed dependant (read it shouldnt be a constant!)
 *
 *  5 is about right for 28.8 upwards. Below that double for every
 *  halving of speed or so. - ie about 20 for 9600 baud.
 }
const
  SHAPER_LATENCY     = (5 * HZ);
  {$EXTERNALSYM SHAPER_LATENCY}
  SHAPER_MAXSLIP     = 2;
  {$EXTERNALSYM SHAPER_MAXSLIP}
  SHAPER_BURST       = (HZ div 50);    { Good for >128K then }
  {$EXTERNALSYM SHAPER_BURST}

  SHAPER_SET_DEV     = $0001;
  {$EXTERNALSYM SHAPER_SET_DEV}
  SHAPER_SET_SPEED   = $0002;
  {$EXTERNALSYM SHAPER_SET_SPEED}
  SHAPER_GET_DEV     = $0003;
  {$EXTERNALSYM SHAPER_GET_DEV}
  SHAPER_GET_SPEED   = $0004;
  {$EXTERNALSYM SHAPER_GET_SPEED}

type
  shaperconf = {packed} record
    ss_cmd: u_int16_t;
    ss_u: {packed} record
            case Integer of
              0: (ssu_name: packed array[0..14-1] of Char);
              1: (ssu_speed: u_int32_t);
            end;
  end;
  {$EXTERNALSYM shaperconf}

(* Cannot translate this
#define ss_speed ss_u.ssu_speed
#define ss_name ss_u.ssu_name
*)

// Translated from net/if_slip.h

{ We can use the kernel header.  }
(*
#include <linux/if_slip.h>
*)

// Translated from net/ppp-comp.h

(*
#include <linux/ppp-comp.h>
*)

// Translated from net/route.h

(*
#include <features.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
*)

type
{ This structure gets passed by the SIOCADDRT and SIOCDELRT calls. }
  rtentry = {packed} record
    rt_pad1: LongWord;
    rt_dst: sockaddr;        { Target address.  }
    rt_gateway: sockaddr;    { Gateway addr (RTF_GATEWAY).  }
    rt_genmask: sockaddr;    { Target network mask (IP).  }
    rt_flags: Word;
    rt_pad2: Smallint;
    rt_pad3: LongWord;
    rt_tos: Byte;
    rt_class: Byte;
    rt_pad4: Smallint;
    rt_metric: Smallint;     { +1 for binary compatibility!  }
    rt_dev: PChar;           { Forcing the device at add.  }
    rt_mtu: LongWord;        { Per route MTU/Window.  }
    rt_window: LongWord;     { Window clamping.  }
    rt_irtt: Word;           { Initial RTT.  }
  end;
  {$EXTERNALSYM rtentry}

(* Cannot translate this
{ Compatibility hack.  }
#define rt_mss	rt_mtu
*)


  in6_rtmsg = {packed} record
    rtmsg_dst: in6_addr;
    rtmsg_src: in6_addr;
    rtmsg_gateway: in6_addr;
    rtmsg_type: u_int32_t;
    rtmsg_dst_len: u_int16_t;
    rtmsg_src_len: u_int16_t;
    rtmsg_metric: u_int32_t;
    rtmsg_info: LongWord;
    rtmsg_flags: u_int32_t;
    rtmsg_ifindex: Integer;
  end;
  {$EXTERNALSYM in6_rtmsg}


const
  RTF_UP            = $0001;       { Route usable.  }
  {$EXTERNALSYM RTF_UP}
  RTF_GATEWAY       = $0002;       { Destination is a gateway.  }
  {$EXTERNALSYM RTF_GATEWAY}

  RTF_HOST	      = $0004;       { Host entry (net otherwise).  }
  {$EXTERNALSYM RTF_HOST}
  RTF_REINSTATE     = $0008;       { Reinstate route after timeout.  }
  {$EXTERNALSYM RTF_REINSTATE}
  RTF_DYNAMIC       = $0010;       { Created dyn. (by redirect).  }
  {$EXTERNALSYM RTF_DYNAMIC}
  RTF_MODIFIED      = $0020;       { Modified dyn. (by redirect).  }
  {$EXTERNALSYM RTF_MODIFIED}
  RTF_MTU           = $0040;       { Specific MTU for this route.  }
  {$EXTERNALSYM RTF_MTU}
  RTF_MSS           = RTF_MTU;     { Compatibility.  }
  {$EXTERNALSYM RTF_MSS}
  RTF_WINDOW        = $0080;       { Per route window clamping.  }
  {$EXTERNALSYM RTF_WINDOW}
  RTF_IRTT          = $0100;       { Initial round trip time.  }
  {$EXTERNALSYM RTF_IRTT}
  RTF_REJECT	      = $0200;       { Reject route.  }
  {$EXTERNALSYM RTF_REJECT}
  RTF_STATIC        = $0400;       { Manually injected route.  }
  {$EXTERNALSYM RTF_STATIC}
  RTF_XRESOLVE      = $0800;       { External resolver.  }
  {$EXTERNALSYM RTF_XRESOLVE}
  RTF_NOFORWARD     = $1000;       { Forwarding inhibited.  }
  {$EXTERNALSYM RTF_NOFORWARD}
  RTF_THROW         = $2000;       { Go to next class.  }
  {$EXTERNALSYM RTF_THROW}
  RTF_NOPMTUDISC    = $4000;       { Do not send packets with DF.  }
  {$EXTERNALSYM RTF_NOPMTUDISC}

{ for IPv6 }
  RTF_DEFAULT       = $00010000;   { default - learned via ND         }
  {$EXTERNALSYM RTF_DEFAULT}
  RTF_ALLONLINK     = $00020000;   { fallback, no routers on link     }
  {$EXTERNALSYM RTF_ALLONLINK}
  RTF_ADDRCONF      = $00040000;   { addrconf route - RA              }
  {$EXTERNALSYM RTF_ADDRCONF}

  RTF_LINKRT        = $00100000;   { link specific - device match     }
  {$EXTERNALSYM RTF_LINKRT}
  RTF_NONEXTHOP     = $00200000;   { route with no nexthop            }
  {$EXTERNALSYM RTF_NONEXTHOP}

  RTF_CACHE         = $01000000;   { cache entry                      }
  {$EXTERNALSYM RTF_CACHE}
  RTF_FLOW          = $02000000;   { flow significant route           }
  {$EXTERNALSYM RTF_FLOW}
  RTF_POLICY        = $04000000;   { policy route                     }
  {$EXTERNALSYM RTF_POLICY}

  RTCF_VALVE        = $00200000;
  {$EXTERNALSYM RTCF_VALVE}
  RTCF_MASQ         = $00400000;
  {$EXTERNALSYM RTCF_MASQ}
  RTCF_NAT          = $00800000;
  {$EXTERNALSYM RTCF_NAT}
  RTCF_DOREDIRECT   = $01000000;
  {$EXTERNALSYM RTCF_DOREDIRECT}
  RTCF_LOG          = $02000000;
  {$EXTERNALSYM RTCF_LOG}
  RTCF_DIRECTSRC    = $04000000;
  {$EXTERNALSYM RTCF_DIRECTSRC}

  RTF_LOCAL         = $80000000;
  {$EXTERNALSYM RTF_LOCAL}
  RTF_INTERFACE     = $40000000;
  {$EXTERNALSYM RTF_INTERFACE}
  RTF_MULTICAST     = $20000000;
  {$EXTERNALSYM RTF_MULTICAST}
  RTF_BROADCAST     = $10000000;
  {$EXTERNALSYM RTF_BROADCAST}
  RTF_NAT           = $08000000;
  {$EXTERNALSYM RTF_NAT}

  RTF_ADDRCLASSMASK = $F8000000;
  {$EXTERNALSYM RTF_ADDRCLASSMASK}

function RT_ADDRCLASS(flags: u_int32_t): u_int32_t;
{$EXTERNALSYM RT_ADDRCLASS}

function RT_TOS(tos: Integer): Integer;
{$EXTERNALSYM RT_TOS}

function RT_LOCALADDR(flags: u_int32_t): Boolean;
{$EXTERNALSYM RT_LOCALADDR}

const
  RT_CLASS_UNSPEC      = 0;
  {$EXTERNALSYM RT_CLASS_UNSPEC}
  RT_CLASS_DEFAULT     = 253;
  {$EXTERNALSYM RT_CLASS_DEFAULT}

  RT_CLASS_MAIN        = 254;
  {$EXTERNALSYM RT_CLASS_MAIN}
  RT_CLASS_LOCAL       = 255;
  {$EXTERNALSYM RT_CLASS_LOCAL}
  RT_CLASS_MAX         = 255;
  {$EXTERNALSYM RT_CLASS_MAX}

(* No header defines these symbols
  RTMSG_ACK            = NLMSG_ACK;
  {$EXTERNALSYM RTMSG_ACK}
  RTMSG_OVERRUN        = NLMSG_OVERRUN;
  {$EXTERNALSYM RTMSG_OVERRUN}
*)

  RTMSG_NEWDEVICE      = $11;
  {$EXTERNALSYM RTMSG_NEWDEVICE}
  RTMSG_DELDEVICE      = $12;
  {$EXTERNALSYM RTMSG_DELDEVICE}
  RTMSG_NEWROUTE       = $21;
  {$EXTERNALSYM RTMSG_NEWROUTE}
  RTMSG_DELROUTE       = $22;
  {$EXTERNALSYM RTMSG_DELROUTE}
  RTMSG_NEWRULE        = $31;
  {$EXTERNALSYM RTMSG_NEWRULE}
  RTMSG_DELRULE        = $32;
  {$EXTERNALSYM RTMSG_DELRULE}
  RTMSG_CONTROL        = $40;
  {$EXTERNALSYM RTMSG_CONTROL}

  RTMSG_AR_FAILED      = $51;  { Address Resolution failed.  }
  {$EXTERNALSYM RTMSG_AR_FAILED}


// Translated from netash/ash.h

type
  sockaddr_ash = {packed} record
    sash_family: sa_family_t;    { Common data: address family etc.  }
    sash_ifindex: Integer;       { Interface to use.  }
    sash_channel: Byte;          { Realtime or control.  }
    sash_plen: Cardinal;
    sash_prefix: packed array[0..16-1] of Byte;
  end;
  {$EXTERNALSYM sockaddr_ash}

{ Values for `channel' member.  }
const
  ASH_CHANNEL_ANY         = 0;
  {$EXTERNALSYM ASH_CHANNEL_ANY}
  ASH_CHANNEL_CONTROL     = 1;
  {$EXTERNALSYM ASH_CHANNEL_CONTROL}
  ASH_CHANNEL_REALTIME    = 2;
  {$EXTERNALSYM ASH_CHANNEL_REALTIME}


// Translated from netatalk/at.h

(*
#include <asm/types.h>
#include <linux/atalk.h>
#include <sys/socket.h>
*)

const
  SOL_ATALK = 258;  { sockopt level for atalk }
  {$EXTERNALSYM SOL_ATALK}


// Translated from netax25/ax25.h

{ Setsockoptions(2) level.  Thanks to BSD these must match IPPROTO_xxx.  }
const
  SOL_AX25 = 257;
  {$EXTERNALSYM SOL_AX25}

{ AX.25 flags: }
  AX25_WINDOW       = 1;
  {$EXTERNALSYM AX25_WINDOW}
  AX25_T1           = 2;
  {$EXTERNALSYM AX25_T1}
  AX25_T2           = 5;
  {$EXTERNALSYM AX25_T2}
  AX25_T3           = 4;
  {$EXTERNALSYM AX25_T3}
  AX25_N2           = 3;
  {$EXTERNALSYM AX25_N2}
  AX25_BACKOFF      = 6;
  {$EXTERNALSYM AX25_BACKOFF}
  AX25_EXTSEQ       = 7;
  {$EXTERNALSYM AX25_EXTSEQ}
  AX25_PIDINCL      = 8;
  {$EXTERNALSYM AX25_PIDINCL}
  AX25_IDLE         = 9;
  {$EXTERNALSYM AX25_IDLE}
  AX25_PACLEN       = 10;
  {$EXTERNALSYM AX25_PACLEN}
  AX25_IPMAXQUEUE   = 11;
  {$EXTERNALSYM AX25_IPMAXQUEUE}
  AX25_IAMDIGI      = 12;
  {$EXTERNALSYM AX25_IAMDIGI}
  AX25_KILL         = 99;
  {$EXTERNALSYM AX25_KILL}

{ AX.25 socket ioctls: }
  SIOCAX25GETUID     = (SIOCPROTOPRIVATE);
  {$EXTERNALSYM SIOCAX25GETUID}
  SIOCAX25ADDUID     = (SIOCPROTOPRIVATE+1);
  {$EXTERNALSYM SIOCAX25ADDUID}
  SIOCAX25DELUID     = (SIOCPROTOPRIVATE+2);
  {$EXTERNALSYM SIOCAX25DELUID}
  SIOCAX25NOUID      = (SIOCPROTOPRIVATE+3);
  {$EXTERNALSYM SIOCAX25NOUID}
  SIOCAX25BPQADDR    = (SIOCPROTOPRIVATE+4);
  {$EXTERNALSYM SIOCAX25BPQADDR}
  SIOCAX25GETPARMS   = (SIOCPROTOPRIVATE+5);
  {$EXTERNALSYM SIOCAX25GETPARMS}
  SIOCAX25SETPARMS   = (SIOCPROTOPRIVATE+6);
  {$EXTERNALSYM SIOCAX25SETPARMS}
  SIOCAX25OPTRT      = (SIOCPROTOPRIVATE+7);
  {$EXTERNALSYM SIOCAX25OPTRT}
  SIOCAX25CTLCON     = (SIOCPROTOPRIVATE+8);
  {$EXTERNALSYM SIOCAX25CTLCON}
  SIOCAX25GETINFO    = (SIOCPROTOPRIVATE+9);
  {$EXTERNALSYM SIOCAX25GETINFO}
  SIOCAX25ADDFWD     = (SIOCPROTOPRIVATE+10);
  {$EXTERNALSYM SIOCAX25ADDFWD}
  SIOCAX25DELFWD     = (SIOCPROTOPRIVATE+11);
  {$EXTERNALSYM SIOCAX25DELFWD}

{ unknown: }
  AX25_NOUID_DEFAULT   = 0;
  {$EXTERNALSYM AX25_NOUID_DEFAULT}
  AX25_NOUID_BLOCK     = 1;
  {$EXTERNALSYM AX25_NOUID_BLOCK}
  AX25_SET_RT_IPMODE   = 2;
  {$EXTERNALSYM AX25_SET_RT_IPMODE}

{ Digipeating flags: }
  AX25_DIGI_INBAND = $01;   { Allow digipeating within port }
  {$EXTERNALSYM AX25_DIGI_INBAND}
  AX25_DIGI_XBAND  = $02;   { Allow digipeating across ports }
  {$EXTERNALSYM AX25_DIGI_XBAND}

{ Maximim number of digipeaters: }
  AX25_MAX_DIGIS = 8;
  {$EXTERNALSYM AX25_MAX_DIGIS}


type
  ax25_address = {packed} record
    ax25_call: packed array[0..7-1] of Char;  { 6 call + SSID (shifted ascii) }
  end;
  {$EXTERNALSYM ax25_address}

  sockaddr_ax25 = {packed} record
    sax25_family: sa_family_t;
    sax25_call: ax25_address;
    sax25_ndigis: Integer;
  end;
  {$EXTERNALSYM sockaddr_ax25}

{ The sockaddr struct with the digipeater adresses: }
  full_sockaddr_ax25 = {packed} record
    fsa_ax25: sockaddr_ax25;
    fsa_digipeater: packed array[0..AX25_MAX_DIGIS-1] of ax25_address;
  end;
  {$EXTERNALSYM full_sockaddr_ax25}

(* Cannot translate this
#define sax25_uid	sax25_ndigis
*)

  ax25_routes_struct = {packed} record
    port_addr: ax25_address;
    dest_addr: ax25_address;
    digi_count: Byte;
    digi_addr: packed array[0..AX25_MAX_DIGIS-1] of ax25_address;
  end;
  {$EXTERNALSYM ax25_routes_struct}

{ The AX.25 ioctl structure: }
  ax25_ctl_struct = {packed} record
    port_addr: ax25_address;
    source_addr: ax25_address;
    dest_addr: ax25_address;
    cmd: Cardinal;
    arg: LongWord;
    digi_count: Byte;
    digi_addr: packed array[0..AX25_MAX_DIGIS-1] of ax25_address;
  end;
  {$EXTERNALSYM ax25_ctl_struct}

  ax25_info_struct = {packed} record
    n2, n2count: Cardinal;
    t1, t1timer: Cardinal;
    t2, t2timer: Cardinal;
    t3, t3timer: Cardinal;
    idle, idletimer: Cardinal;
    state: Cardinal;
    rcv_q, snd_q: Cardinal;
  end;
  {$EXTERNALSYM ax25_info_struct}

  ax25_fwd_struct = {packed} record
    port_from: ax25_address;
    port_to: ax25_address;
  end;
  {$EXTERNALSYM ax25_fwd_struct}

{ AX.25 route structure: }
  ax25_route_opt_struct = {packed} record
    port_addr: ax25_address;
    dest_addr: ax25_address;
    cmd: Integer;
    arg: Integer;
  end;
  {$EXTERNALSYM ax25_route_opt_struct}

{ AX.25 BPQ stuff: }
  ax25_bpqaddr_struct = {packed} record
    dev: packed array[0..16-1] of Char;
    addr: ax25_address;
  end;
  {$EXTERNALSYM ax25_bpqaddr_struct}

{ Definitions for the AX.25 `values' fields: }
const
  AX25_VALUES_IPDEFMODE      = 0;    { 'D'=DG 'V'=VC }
  {$EXTERNALSYM AX25_VALUES_IPDEFMODE}
  AX25_VALUES_AXDEFMODE      = 1;    { 8=Normal 128=Extended Seq Nos }
  {$EXTERNALSYM AX25_VALUES_AXDEFMODE}
  AX25_VALUES_NETROM         = 2;    { Allow NET/ROM  - 0=No 1=Yes }
  {$EXTERNALSYM AX25_VALUES_NETROM}
  AX25_VALUES_TEXT           = 3;    { Allow PID=Text - 0=No 1=Yes }
  {$EXTERNALSYM AX25_VALUES_TEXT}
  AX25_VALUES_BACKOFF        = 4;    { 'E'=Exponential 'L'=Linear }
  {$EXTERNALSYM AX25_VALUES_BACKOFF}
  AX25_VALUES_CONMODE        = 5;    { Allow connected modes - 0=No 1=Yes }
  {$EXTERNALSYM AX25_VALUES_CONMODE}
  AX25_VALUES_WINDOW         = 6;    { Default window size for standard AX.25 }
  {$EXTERNALSYM AX25_VALUES_WINDOW}
  AX25_VALUES_EWINDOW        = 7;    { Default window size for extended AX.25 }
  {$EXTERNALSYM AX25_VALUES_EWINDOW}
  AX25_VALUES_T1             = 8;    { Default T1 timeout value }
  {$EXTERNALSYM AX25_VALUES_T1}
  AX25_VALUES_T2             = 9;    { Default T2 timeout value }
  {$EXTERNALSYM AX25_VALUES_T2}
  AX25_VALUES_T3             = 10;   { Default T3 timeout value }
  {$EXTERNALSYM AX25_VALUES_T3}
  AX25_VALUES_N2             = 11;   { Default N2 value }
  {$EXTERNALSYM AX25_VALUES_N2}
  AX25_VALUES_DIGI           = 12;   { Digipeat mode }
  {$EXTERNALSYM AX25_VALUES_DIGI}
  AX25_VALUES_IDLE           = 13;   { mode vc idle timer }
  {$EXTERNALSYM AX25_VALUES_IDLE}
  AX25_VALUES_PACLEN         = 14;   { AX.25 MTU }
  {$EXTERNALSYM AX25_VALUES_PACLEN}
  AX25_VALUES_IPMAXQUEUE     = 15;   { Maximum number of buffers enqueued }
  {$EXTERNALSYM AX25_VALUES_IPMAXQUEUE}
  AX25_MAX_VALUES            = 20;
  {$EXTERNALSYM AX25_MAX_VALUES}

type
  ax25_parms_struct = {packed} record
    port_addr: ax25_address;
    values: packed array[0..AX25_MAX_VALUES-1] of Word;
  end;
  {$EXTERNALSYM ax25_parms_struct}


// Translated from neteconet/ec.h

type
  ec_addr = {packed} record
    station: Byte;      { Station number.  }
    net: Byte;          { Network number.  }
  end;
  {$EXTERNALSYM ec_addr}

  sockaddr_ec = {packed} record
    sec_family: sa_family_t;
    port: Byte;         { Port number.  }
    cb: Byte;           { Control/flag byte.  }
    __type: Byte;       { Type of message.  } // Renamed from type
    addr: ec_addr;
    cookie: LongWord;
  end;
  {$EXTERNALSYM sockaddr_ec}

const
  ECTYPE_PACKET_RECEIVED          = 0;    { Packet received }
  {$EXTERNALSYM ECTYPE_PACKET_RECEIVED}
  ECTYPE_TRANSMIT_STATUS          = $10;  { Transmit completed }
  {$EXTERNALSYM ECTYPE_TRANSMIT_STATUS}

  ECTYPE_TRANSMIT_OK              = 1;
  {$EXTERNALSYM ECTYPE_TRANSMIT_OK}
  ECTYPE_TRANSMIT_NOT_LISTENING   = 2;
  {$EXTERNALSYM ECTYPE_TRANSMIT_NOT_LISTENING}
  ECTYPE_TRANSMIT_NET_ERROR       = 3;
  {$EXTERNALSYM ECTYPE_TRANSMIT_NET_ERROR}
  ECTYPE_TRANSMIT_NO_CLOCK        = 4;
  {$EXTERNALSYM ECTYPE_TRANSMIT_NO_CLOCK}
  ECTYPE_TRANSMIT_LINE_JAMMED     = 5;
  {$EXTERNALSYM ECTYPE_TRANSMIT_LINE_JAMMED}
  ECTYPE_TRANSMIT_NOT_PRESENT     = 6;
  {$EXTERNALSYM ECTYPE_TRANSMIT_NOT_PRESENT}


// Translated from netipx/ipx.h

const
  SOL_IPX = 256;  { sockopt level }
  {$EXTERNALSYM SOL_IPX}

  IPX_TYPE      = 1;
  {$EXTERNALSYM IPX_TYPE}
  IPX_NODE_LEN  = 6;
  {$EXTERNALSYM IPX_NODE_LEN}
  IPX_MTU       = 576;
  {$EXTERNALSYM IPX_MTU}

type
  sockaddr_ipx = {packed} record
    sipx_family: sa_family_t;
    sipx_port: u_int16_t;
    sipx_network: u_int32_t;
    sipx_node: packed array[0..IPX_NODE_LEN-1] of Byte;
    sipx_type: u_int8_t;
    sipx_zero: Byte;      { 16 byte fill }
  end;
  {$EXTERNALSYM sockaddr_ipx}

{ So we can fit the extra info for SIOCSIFADDR into the address nicely }
(* Cannot translate this
#define sipx_special	sipx_port
#define sipx_action	sipx_zero
*)

const
  IPX_DLTITF  = 0;
  {$EXTERNALSYM IPX_DLTITF}
  IPX_CRTITF  = 1;
  {$EXTERNALSYM IPX_CRTITF}

type
  ipx_route_definition = {packed} record
    ipx_network: LongWord;
    ipx_router_network: LongWord;
    ipx_router_node: packed array[0..IPX_NODE_LEN-1] of Byte;
  end;
  {$EXTERNALSYM ipx_route_definition}

  ipx_interface_definition = {packed} record
    ipx_network: LongWord;
    ipx_device: packed array[0..16-1] of Byte;
    ipx_dlink_type: Byte;
    ipx_special: Byte;
    ipx_node: packed array[0..IPX_NODE_LEN-1] of Byte;
  end;
  {$EXTERNALSYM ipx_interface_definition}

const
  IPX_FRAME_NONE     = 0;
  {$EXTERNALSYM IPX_FRAME_NONE}
  IPX_FRAME_SNAP     = 1;
  {$EXTERNALSYM IPX_FRAME_SNAP}
  IPX_FRAME_8022     = 2;
  {$EXTERNALSYM IPX_FRAME_8022}
  IPX_FRAME_ETHERII  = 3;
  {$EXTERNALSYM IPX_FRAME_ETHERII}
  IPX_FRAME_8023     = 4;
  {$EXTERNALSYM IPX_FRAME_8023}
  IPX_FRAME_TR_8022  = 5;
  {$EXTERNALSYM IPX_FRAME_TR_8022}

  IPX_SPECIAL_NONE   = 0;
  {$EXTERNALSYM IPX_SPECIAL_NONE}
  IPX_PRIMARY	       = 1;
  {$EXTERNALSYM IPX_PRIMARY}
  IPX_INTERNAL       = 2;
  {$EXTERNALSYM IPX_INTERNAL}


type
  ipx_config_data = {packed} record
    ipxcfg_auto_select_primary: Byte;
    ipxcfg_auto_create_interfaces: Byte;
  end;
  {$EXTERNALSYM ipx_config_data}

{ OLD Route Definition for backward compatibility. }

  ipx_route_def = {packed} record
    ipx_network: LongWord;
    ipx_router_network: LongWord;
    ipx_router_node: packed array[0..IPX_NODE_LEN-1] of Byte;
    ipx_device: packed array[0..16-1] of Byte;
    ipx_flags: Word;
  end;
  {$EXTERNALSYM ipx_route_def}

const
  IPX_ROUTE_NO_ROUTER  = 0;
  {$EXTERNALSYM IPX_ROUTE_NO_ROUTER}

  IPX_RT_SNAP          = 8;
  {$EXTERNALSYM IPX_RT_SNAP}
  IPX_RT_8022          = 4;
  {$EXTERNALSYM IPX_RT_8022}
  IPX_RT_BLUEBOOK      = 2;
  {$EXTERNALSYM IPX_RT_BLUEBOOK}
  IPX_RT_ROUTED        = 1;
  {$EXTERNALSYM IPX_RT_ROUTED}

const
  SIOCAIPXITFCRT      = (SIOCPROTOPRIVATE);
  {$EXTERNALSYM SIOCAIPXITFCRT}
  SIOCAIPXPRISLT      = (SIOCPROTOPRIVATE + 1);
  {$EXTERNALSYM SIOCAIPXPRISLT}
  SIOCIPXCFGDATA      = (SIOCPROTOPRIVATE + 2);
  {$EXTERNALSYM SIOCIPXCFGDATA}
  SIOCIPXNCPCONN      = (SIOCPROTOPRIVATE + 3);
  {$EXTERNALSYM SIOCIPXNCPCONN}


// Translated from netpacket/packet.h

type
  sockaddr_ll = {packed} record
    sll_family: Word;
    sll_protocol: Word;
    sll_ifindex: Integer;
    sll_hatype: Word;
    sll_pkttype: Byte;
    sll_halen: Byte;
    sll_addr: packed array[0..8-1] of Byte;
  end;
  {$EXTERNALSYM sockaddr_ll}

{ Packet types.  }
const
  PACKET_HOST        = 0;    { To us.  }
  {$EXTERNALSYM PACKET_HOST}
  PACKET_BROADCAST   = 1;    { To all.  }
  {$EXTERNALSYM PACKET_BROADCAST}
  PACKET_MULTICAST   = 2;    { To group.  }
  {$EXTERNALSYM PACKET_MULTICAST}
  PACKET_OTHERHOST   = 3;    { To someone else.  }
  {$EXTERNALSYM PACKET_OTHERHOST}
  PACKET_OUTGOING    = 4;    { Originated by us . }
  {$EXTERNALSYM PACKET_OUTGOING}
  PACKET_LOOPBACK    = 5;
  {$EXTERNALSYM PACKET_LOOPBACK}
  PACKET_FASTROUTE   = 6;
  {$EXTERNALSYM PACKET_FASTROUTE}

{ Packet socket options.  }

  PACKET_ADD_MEMBERSHIP   = 1;
  {$EXTERNALSYM PACKET_ADD_MEMBERSHIP}
  PACKET_DROP_MEMBERSHIP  = 2;
  {$EXTERNALSYM PACKET_DROP_MEMBERSHIP}
  PACKET_RECV_OUTPUT      = 3;
  {$EXTERNALSYM PACKET_RECV_OUTPUT}
  PACKET_RX_RING          = 5;
  {$EXTERNALSYM PACKET_RX_RING}
  PACKET_STATISTICS       = 6;
  {$EXTERNALSYM PACKET_STATISTICS}

type
  packet_mreq = {packed} record
    mr_ifindex: Integer;
    mr_type: Word;
    mr_alen: Word;
    mr_address: packed array[0..8-1] of Byte;
  end;
  {$EXTERNALSYM packet_mreq}

const
  PACKET_MR_MULTICAST  = 0;
  {$EXTERNALSYM PACKET_MR_MULTICAST}
  PACKET_MR_PROMISC    = 1;
  {$EXTERNALSYM PACKET_MR_PROMISC}
  PACKET_MR_ALLMULTI   = 2;
  {$EXTERNALSYM PACKET_MR_ALLMULTI}


// Translated from netrom/netrom.h

{ Setsockoptions(2) level.  Thanks to BSD these must match IPPROTO_xxx.  }
const
  SOL_NETROM = 259;
  {$EXTERNALSYM SOL_NETROM}

{ NetRom control values: }
const
  NETROM_T1       = 1;
  {$EXTERNALSYM NETROM_T1}
  NETROM_T2       = 2;
  {$EXTERNALSYM NETROM_T2}
  NETROM_N2       = 3;
  {$EXTERNALSYM NETROM_N2}
  NETROM_PACLEN   = 5;
  {$EXTERNALSYM NETROM_PACLEN}
  NETROM_T4       = 6;
  {$EXTERNALSYM NETROM_T4}
  NETROM_IDLE     = 7;
  {$EXTERNALSYM NETROM_IDLE}

  NETROM_KILL     = 99;
  {$EXTERNALSYM NETROM_KILL}

{ Type of route: }
  NETROM_NEIGH    = 0;
  {$EXTERNALSYM NETROM_NEIGH}
  NETROM_NODE     = 1;
  {$EXTERNALSYM NETROM_NODE}

type
  nr_route_struct = {packed} record
    __type: Integer; // Renamed from type
    callsign: ax25_address;
    device: packed array[0..16-1] of Shortint;
    quality: Cardinal;
    mnemonic: packed array[0..7-1] of Char;
    neighbour: ax25_address;
    obs_count: Cardinal;
    ndigis: Cardinal;
    digipeaters: packed array[0..AX25_MAX_DIGIS-1] of ax25_address;
  end;
  {$EXTERNALSYM nr_route_struct}

{ NetRom socket ioctls: }
const
  SIOCNRGETPARMS    = (SIOCPROTOPRIVATE+0);
  {$EXTERNALSYM SIOCNRGETPARMS}
  SIOCNRSETPARMS    = (SIOCPROTOPRIVATE+1);
  {$EXTERNALSYM SIOCNRSETPARMS}
  SIOCNRDECOBS      = (SIOCPROTOPRIVATE+2);
  {$EXTERNALSYM SIOCNRDECOBS}
  SIOCNRRTCTL	      = (SIOCPROTOPRIVATE+3);
  {$EXTERNALSYM SIOCNRRTCTL}
  SIOCNRCTLCON      = (SIOCPROTOPRIVATE+4);
  {$EXTERNALSYM SIOCNRCTLCON}

{ NetRom parameter structure: }
type
  nr_parms_struct = {packed} record
    quality: Cardinal;
    obs_count: Cardinal;
    ttl: Cardinal;
    timeout: Cardinal;
    ack_delay: Cardinal;
    busy_delay: Cardinal;
    tries: Cardinal;
    window: Cardinal;
    paclen: Cardinal;
  end;
  {$EXTERNALSYM nr_parms_struct}

{ NetRom control structure: }
  nr_ctl_struct = {packed} record
    index: Byte;
    id: Byte;
    cmd: Integer;
    arg: LongWord;
  end;
  {$EXTERNALSYM nr_ctl_struct}


// Translated from netrose/rose.h

{ What follows is copied from the 2.1.93 <linux/rose.h>.  }

{ Socket level values.  }
const
  SOL_ROSE = 260;
  {$EXTERNALSYM SOL_ROSE}


{ These are the public elements of the Linux kernel Rose
   implementation.  For kernel AX.25 see the file ax25.h. This file
   requires ax25.h for the definition of the ax25_address structure.  }
const
  ROSE_MTU = 251;
  {$EXTERNALSYM ROSE_MTU}

  ROSE_MAX_DIGIS = 6;
  {$EXTERNALSYM ROSE_MAX_DIGIS}

  ROSE_DEFER     = 1;
  {$EXTERNALSYM ROSE_DEFER}
  ROSE_T1        = 2;
  {$EXTERNALSYM ROSE_T1}
  ROSE_T2        = 3;
  {$EXTERNALSYM ROSE_T2}
  ROSE_T3        = 4;
  {$EXTERNALSYM ROSE_T3}
  ROSE_IDLE      = 5;
  {$EXTERNALSYM ROSE_IDLE}
  ROSE_QBITINCL  = 6;
  {$EXTERNALSYM ROSE_QBITINCL}
  ROSE_HOLDBACK  = 7;
  {$EXTERNALSYM ROSE_HOLDBACK}

  SIOCRSGCAUSE       = (SIOCPROTOPRIVATE + 0);
  {$EXTERNALSYM SIOCRSGCAUSE}
  SIOCRSSCAUSE       = (SIOCPROTOPRIVATE + 1);
  {$EXTERNALSYM SIOCRSSCAUSE}
  SIOCRSL2CALL       = (SIOCPROTOPRIVATE + 2);
  {$EXTERNALSYM SIOCRSL2CALL}
  SIOCRSSL2CALL      = (SIOCPROTOPRIVATE + 2);
  {$EXTERNALSYM SIOCRSSL2CALL}
  SIOCRSACCEPT       = (SIOCPROTOPRIVATE + 3);
  {$EXTERNALSYM SIOCRSACCEPT}
  SIOCRSCLRRT        = (SIOCPROTOPRIVATE + 4);
  {$EXTERNALSYM SIOCRSCLRRT}
  SIOCRSGL2CALL      = (SIOCPROTOPRIVATE + 5);
  {$EXTERNALSYM SIOCRSGL2CALL}
  SIOCRSGFACILITIES  = (SIOCPROTOPRIVATE + 6);
  {$EXTERNALSYM SIOCRSGFACILITIES}

  ROSE_DTE_ORIGINATED       = $00;
  {$EXTERNALSYM ROSE_DTE_ORIGINATED}
  ROSE_NUMBER_BUSY          = $01;
  {$EXTERNALSYM ROSE_NUMBER_BUSY}
  ROSE_INVALID_FACILITY     = $03;
  {$EXTERNALSYM ROSE_INVALID_FACILITY}
  ROSE_NETWORK_CONGESTION   = $05;
  {$EXTERNALSYM ROSE_NETWORK_CONGESTION}
  ROSE_OUT_OF_ORDER         = $09;
  {$EXTERNALSYM ROSE_OUT_OF_ORDER}
  ROSE_ACCESS_BARRED        = $0B;
  {$EXTERNALSYM ROSE_ACCESS_BARRED}
  ROSE_NOT_OBTAINABLE       = $0D;
  {$EXTERNALSYM ROSE_NOT_OBTAINABLE}
  ROSE_REMOTE_PROCEDURE     = $11;
  {$EXTERNALSYM ROSE_REMOTE_PROCEDURE}
  ROSE_LOCAL_PROCEDURE      = $13;
  {$EXTERNALSYM ROSE_LOCAL_PROCEDURE}
  ROSE_SHIP_ABSENT          = $39;
  {$EXTERNALSYM ROSE_SHIP_ABSENT}


type
  rose_address = {packed} record
    rose_addr: packed array[0..5-1] of Byte;
  end;
  {$EXTERNALSYM rose_address}

  sockaddr_rose = {packed} record
    srose_family: sa_family_t;
    srose_addr: rose_address;
    srose_call: ax25_address;
    srose_ndigis: Integer;
    srose_digi: ax25_address;
  end;
  {$EXTERNALSYM sockaddr_rose}

  full_sockaddr_rose = {packed} record
    srose_family: sa_family_t;
    srose_addr: rose_address;
    srose_call: ax25_address;
    srose_ndigis: Cardinal;
    srose_digis: packed array[0..ROSE_MAX_DIGIS-1] of ax25_address;
  end;
  {$EXTERNALSYM full_sockaddr_rose}

  rose_route_struct = {packed} record
    address: rose_address;
    mask: Word;
    neighbour: ax25_address;
    device: packed array[0..16-1] of Char;
    ndigis: Byte;
    digipeaters: packed array[0..AX25_MAX_DIGIS-1] of ax25_address;
  end;
  {$EXTERNALSYM rose_route_struct}

  rose_cause_struct = {packed} record
    cause: Byte;
    diagnostic: Byte;
  end;
  {$EXTERNALSYM rose_cause_struct}

  rose_facilities_struct = {packed} record
    source_addr, dest_addr: rose_address;
    source_call, dest_call: ax25_address;
    source_ndigis, dest_ndigis: Byte;
    source_digis: packed array[0..ROSE_MAX_DIGIS-1] of ax25_address;
    dest_digis: packed array[0..ROSE_MAX_DIGIS-1] of ax25_address;
    rand: Cardinal;
    fail_addr: rose_address;
    fail_call: ax25_address;
  end;
  {$EXTERNALSYM rose_facilities_struct}


// Translated from netinet/if_ether.h
(*
{ Get definitions from kernel header file.  }
#include <linux/if_ether.h>
*)
{
 * Ethernet Address Resolution Protocol.
 *
 * See RFC 826 for protocol description.  Structure below is adapted
 * to resolving internet addresses.  Field names used correspond to
 * RFC 826.
 }
type
  ether_arp = {packed} record
    ea_hdr: arphdr;                                   { fixed-size header }
    arp_sha: packed array[0..ETH_ALEN-1] of u_int8_t; { sender hardware address }
    arp_spa: packed array[0..4-1] of u_int8_t;        { sender protocol address }
    arp_tha: packed array[0..ETH_ALEN-1] of u_int8_t; { target hardware address }
    arp_tpa: packed array[0..4-1] of u_int8_t;        { target protocol address }
  end;
  {$EXTERNALSYM ether_arp}

// Cannot translate this
{
#define	arp_hrd	ea_hdr.ar_hrd
#define	arp_pro	ea_hdr.ar_pro
#define	arp_hln	ea_hdr.ar_hln
#define	arp_pln	ea_hdr.ar_pln
#define	arp_op	ea_hdr.ar_op
}

{
 * Macro to map an IP multicast address to an Ethernet multicast address.
 * The high-order 25 bits of the Ethernet address are statically assigned,
 * and the low-order 23 bits are taken from the low end of the IP address.
 }

 type
   TEthernetAddress = packed array[0..ETH_ALEN-1] of u_char;
   PEthernetAddress = ^TEthernetAddress;

procedure ETHER_MAP_IP_MULTICAST(const ipaddr: in_addr; enaddr: PEthernetAddress);
{$EXTERNALSYM ETHER_MAP_IP_MULTICAST}


// Translated from netinet/ether.h

{ Get definition of `struct ether_addr'.  }

{ Convert 48 bit Ethernet ADDRess to ASCII.  }
function ether_ntoa(const __addr: ether_addr): PChar; cdecl;
{$EXTERNALSYM ether_ntoa}
function ether_ntoa_r(const __addr: ether_addr; Buf: PChar): PChar; cdecl;
{$EXTERNALSYM ether_ntoa_r}

{ Convert ASCII string S to 48 bit Ethernet address.  }
function ether_aton(__asc: PChar): PEtherAddr; cdecl;
{$EXTERNALSYM ether_aton}
function ether_aton_r(__asc: PChar; var __addr: ether_addr): PEtherAddr; cdecl;
{$EXTERNALSYM ether_aton_r}

{ Map 48 bit Ethernet number ADDR to HOSTNAME.  }
function ether_ntohost(__hostname: PChar; const __addr: ether_addr): Integer; cdecl;
{$EXTERNALSYM ether_ntohost}

{ Map HOSTNAME to 48 bit Ethernet address.  }
function ether_hostton(__hostname: PChar; var __addr: ether_addr): Integer; cdecl;
{$EXTERNALSYM ether_hostton}

{ Scan LINE and set ADDR and HOSTNAME.  }
function ether_line(__line: PChar; var __addr: ether_addr; __hostname: PChar): Integer; cdecl;
{$EXTERNALSYM ether_line}



// Translated from netinet/icmp6.h

(*
#include <inttypes.h>
#include <string.h>
#include <sys/types.h>
#include <netinet/in.h>
*)

const
  ICMP6_FILTER                = 1;
  {$EXTERNALSYM ICMP6_FILTER}

  ICMP6_FILTER_BLOCK          = 1;
  {$EXTERNALSYM ICMP6_FILTER_BLOCK}
  ICMP6_FILTER_PASS           = 2;
  {$EXTERNALSYM ICMP6_FILTER_PASS}
  ICMP6_FILTER_BLOCKOTHERS    = 3;
  {$EXTERNALSYM ICMP6_FILTER_BLOCKOTHERS}
  ICMP6_FILTER_PASSONLY       = 4;
  {$EXTERNALSYM ICMP6_FILTER_PASSONLY}

type
  _icmp6_filter = {packed} record
    data: packed array[0..8-1] of uint32_t;
  end;
  {.$EXTERNALSYM icmp6_filter} // Renamed from icmp6_filter
  TICMP6_Filter = _icmp6_filter;
  PICMP6_Filter = ^TICMP6_Filter;

  icmp6_hdr = {packed} record
    icmp6_type: uint8_t;    { type field }
    icmp6_code: uint8_t;    { code field }
    icmp6_cksum: uint16_t;  { checksum field }
    icmp6_dataun: {packed} record
                    case Integer of
                      0: (icmp6_un_data32: packed array[0..1-1] of uint32_t); { type-specific field }
                      1: (icmp6_un_data16: packed array[0..2-1] of uint16_t); { type-specific field }
                      2: (icmp6_un_data8: packed array[0..4-1] of uint8_t);   { type-specific field }
                    end;
  end;
  {$EXTERNALSYM icmp6_hdr}

(* Cannot translate this
#define icmp6_data32    icmp6_dataun.icmp6_un_data32
#define icmp6_data16    icmp6_dataun.icmp6_un_data16
#define icmp6_data8     icmp6_dataun.icmp6_un_data8
#define icmp6_pptr      icmp6_data32[0]  { parameter prob }
#define icmp6_mtu       icmp6_data32[0]  { packet too big }
#define icmp6_id        icmp6_data16[0]  { echo request/reply }
#define icmp6_seq       icmp6_data16[1]  { echo request/reply }
#define icmp6_maxdelay  icmp6_data16[0]  { mcast group membership }
*)

const
  ICMP6_DST_UNREACH             = 1;
  {$EXTERNALSYM ICMP6_DST_UNREACH}
  ICMP6_PACKET_TOO_BIG          = 2;
  {$EXTERNALSYM ICMP6_PACKET_TOO_BIG}
  ICMP6_TIME_EXCEEDED           = 3;
  {$EXTERNALSYM ICMP6_TIME_EXCEEDED}
  ICMP6_PARAM_PROB              = 4;
  {$EXTERNALSYM ICMP6_PARAM_PROB}

  ICMP6_INFOMSG_MASK = $80;    { all informational messages }
  {$EXTERNALSYM ICMP6_INFOMSG_MASK}

  ICMP6_ECHO_REQUEST          = 128;
  {$EXTERNALSYM ICMP6_ECHO_REQUEST}
  ICMP6_ECHO_REPLY            = 129;
  {$EXTERNALSYM ICMP6_ECHO_REPLY}
  ICMP6_MEMBERSHIP_QUERY      = 130;
  {$EXTERNALSYM ICMP6_MEMBERSHIP_QUERY}
  ICMP6_MEMBERSHIP_REPORT     = 131;
  {$EXTERNALSYM ICMP6_MEMBERSHIP_REPORT}
  ICMP6_MEMBERSHIP_REDUCTION  = 132;
  {$EXTERNALSYM ICMP6_MEMBERSHIP_REDUCTION}

  ICMP6_DST_UNREACH_NOROUTE     = 0; { no route to destination }
  {$EXTERNALSYM ICMP6_DST_UNREACH_NOROUTE}
  ICMP6_DST_UNREACH_ADMIN       = 1; { communication with destination administratively prohibited }
  {$EXTERNALSYM ICMP6_DST_UNREACH_ADMIN}
  ICMP6_DST_UNREACH_NOTNEIGHBOR = 2; { not a neighbor }
  {$EXTERNALSYM ICMP6_DST_UNREACH_NOTNEIGHBOR}
  ICMP6_DST_UNREACH_ADDR        = 3; { address unreachable }
  {$EXTERNALSYM ICMP6_DST_UNREACH_ADDR}
  ICMP6_DST_UNREACH_NOPORT      = 4; { bad port }
  {$EXTERNALSYM ICMP6_DST_UNREACH_NOPORT}

  ICMP6_TIME_EXCEED_TRANSIT     = 0; { Hop Limit == 0 in transit }
  {$EXTERNALSYM ICMP6_TIME_EXCEED_TRANSIT}
  ICMP6_TIME_EXCEED_REASSEMBLY  = 1; { Reassembly time out }
  {$EXTERNALSYM ICMP6_TIME_EXCEED_REASSEMBLY}

  ICMP6_PARAMPROB_HEADER        = 0; { erroneous header field }
  {$EXTERNALSYM ICMP6_PARAMPROB_HEADER}
  ICMP6_PARAMPROB_NEXTHEADER    = 1; { unrecognized Next Header }
  {$EXTERNALSYM ICMP6_PARAMPROB_NEXTHEADER}
  ICMP6_PARAMPROB_OPTION        = 2; { unrecognized IPv6 option }
  {$EXTERNALSYM ICMP6_PARAMPROB_OPTION}


function ICMP6_FILTER_WILLPASS(__type: Integer; const filterp: TICMP6_Filter): Boolean;
{$EXTERNALSYM ICMP6_FILTER_WILLPASS}
function ICMP6_FILTER_WILLBLOCK(__type: Integer; const filterp: TICMP6_Filter): Boolean;
{$EXTERNALSYM ICMP6_FILTER_WILLBLOCK}
procedure ICMP6_FILTER_SETPASS(__type: Integer; var filterp: TICMP6_Filter);
{$EXTERNALSYM ICMP6_FILTER_SETPASS}
procedure ICMP6_FILTER_SETBLOCK(__type: Integer; var filterp: TICMP6_Filter);
{$EXTERNALSYM ICMP6_FILTER_SETBLOCK}
procedure ICMP6_FILTER_SETPASSALL(var filterp: TICMP6_Filter);
{$EXTERNALSYM ICMP6_FILTER_SETPASSALL}
procedure ICMP6_FILTER_SETBLOCKALL(var filterp: TICMP6_Filter);
{$EXTERNALSYM ICMP6_FILTER_SETBLOCKALL}

const
  ND_ROUTER_SOLICIT           = 133;
  {$EXTERNALSYM ND_ROUTER_SOLICIT}
  ND_ROUTER_ADVERT            = 134;
  {$EXTERNALSYM ND_ROUTER_ADVERT}
  ND_NEIGHBOR_SOLICIT         = 135;
  {$EXTERNALSYM ND_NEIGHBOR_SOLICIT}
  ND_NEIGHBOR_ADVERT          = 136;
  {$EXTERNALSYM ND_NEIGHBOR_ADVERT}
  ND_REDIRECT                 = 137;
  {$EXTERNALSYM ND_REDIRECT}

type
  _nd_router_solicit = {packed} record      { router solicitation }
    nd_rs_hdr: icmp6_hdr;
    { could be followed by options }
  end;
  {.$EXTERNALSYM nd_router_solicit} // Renamed because of identifier conflict
  TNdRouterSolicit = _nd_router_solicit;
  PNdRouterSolicit = ^TNdRouterSolicit;

(* Cannot translate this
#define nd_rs_type               nd_rs_hdr.icmp6_type
#define nd_rs_code               nd_rs_hdr.icmp6_code
#define nd_rs_cksum              nd_rs_hdr.icmp6_cksum
#define nd_rs_reserved           nd_rs_hdr.icmp6_data32[0]
*)

type
  _nd_router_advert = {packed} record       { router advertisement }
    nd_ra_hdr: icmp6_hdr;
    nd_ra_reachable: uint32_t;   { reachable time }
    nd_ra_retransmit: uint32_t;  { retransmit timer }
    { could be followed by options }
  end;
  {.$EXTERNALSYM nd_router_advert} // Renamed because of identifier conflict
  TNdRouterAdvert = _nd_router_advert;
  PNdRouterAdvert = ^TNdRouterAdvert;


(* Cannot translate this
#define nd_ra_type               nd_ra_hdr.icmp6_type
#define nd_ra_code               nd_ra_hdr.icmp6_code
#define nd_ra_cksum              nd_ra_hdr.icmp6_cksum
#define nd_ra_curhoplimit        nd_ra_hdr.icmp6_data8[0]
#define nd_ra_flags_reserved     nd_ra_hdr.icmp6_data8[1]
*)

const
  ND_RA_FLAG_MANAGED       = $80;
  {$EXTERNALSYM ND_RA_FLAG_MANAGED}
  ND_RA_FLAG_OTHER         = $40;
  {$EXTERNALSYM ND_RA_FLAG_OTHER}
  ND_RA_FLAG_HOME_AGENT    = $20;
  {$EXTERNALSYM ND_RA_FLAG_HOME_AGENT}

(* Cannot translate this
#define nd_ra_router_lifetime    nd_ra_hdr.icmp6_data16[1]
*)

type
  _nd_neighbor_solicit = {packed} record    { neighbor solicitation }
    nd_ns_hdr: icmp6_hdr;
    nd_ns_target: in6_addr; { target address }
    { could be followed by options }
  end;
  {.$EXTERNALSYM nd_neighbor_solicit} // Renamed because of identifier conflict
  TNdNeighborSolicit = _nd_neighbor_solicit;
  PNdNeighborSolicit = ^TNdNeighborSolicit;


(* Cannot translate this
#define nd_ns_type               nd_ns_hdr.icmp6_type
#define nd_ns_code               nd_ns_hdr.icmp6_code
#define nd_ns_cksum              nd_ns_hdr.icmp6_cksum
#define nd_ns_reserved           nd_ns_hdr.icmp6_data32[0]
*)

type
  _nd_neighbor_advert = {packed} record     { neighbor advertisement }
    nd_na_hdr: icmp6_hdr;
    nd_na_target: in6_addr; { target address }
    { could be followed by options }
  end;
  {.$EXTERNALSYM nd_neighbor_advert} // Renamed because of identifier conflict
  TNdNeighborAdvert = _nd_neighbor_advert;
  PNdNeighborAdvert = ^TNdNeighborAdvert;

(* Cannot translate this
#define nd_na_type               nd_na_hdr.icmp6_type
#define nd_na_code               nd_na_hdr.icmp6_code
#define nd_na_cksum              nd_na_hdr.icmp6_cksum
#define nd_na_flags_reserved     nd_na_hdr.icmp6_data32[0]
*)

const
  ND_NA_FLAG_ROUTER        = $00000080;
  {$EXTERNALSYM ND_NA_FLAG_ROUTER}
  ND_NA_FLAG_SOLICITED     = $00000040;
  {$EXTERNALSYM ND_NA_FLAG_SOLICITED}
  ND_NA_FLAG_OVERRIDE      = $00000020;
  {$EXTERNALSYM ND_NA_FLAG_OVERRIDE}

type
  _nd_redirect = {packed} record            { redirect }
    nd_rd_hdr: icmp6_hdr;
    nd_rd_target: in6_addr; { target address }
    nd_rd_dst: in6_addr;    { destination address }
    { could be followed by options }
  end;
  {.$EXTERNALSYM nd_redirect} // Renamed because of identifier conflict
  TNdRedirect = _nd_redirect;
  PNdRedirect = ^TNdRedirect;

(* Cannot translate this
#define nd_rd_type               nd_rd_hdr.icmp6_type
#define nd_rd_code               nd_rd_hdr.icmp6_code
#define nd_rd_cksum              nd_rd_hdr.icmp6_cksum
#define nd_rd_reserved           nd_rd_hdr.icmp6_data32[0]
*)

type
  nd_opt_hdr = {packed} record             { Neighbor discovery option header }
    nd_opt_type: uint8_t;
    nd_opt_len: uint8_t;        { in units of 8 octets }
    { followed by option specific data }
  end;
  {$EXTERNALSYM nd_opt_hdr}

const
  ND_OPT_SOURCE_LINKADDR       = 1;
  {$EXTERNALSYM ND_OPT_SOURCE_LINKADDR}
  ND_OPT_TARGET_LINKADDR       = 2;
  {$EXTERNALSYM ND_OPT_TARGET_LINKADDR}
  ND_OPT_PREFIX_INFORMATION    = 3;
  {$EXTERNALSYM ND_OPT_PREFIX_INFORMATION}
  ND_OPT_REDIRECTED_HEADER     = 4;
  {$EXTERNALSYM ND_OPT_REDIRECTED_HEADER}
  ND_OPT_MTU                   = 5;
  {$EXTERNALSYM ND_OPT_MTU}
  ND_OPT_RTR_ADV_INTERVAL      = 7;
  {$EXTERNALSYM ND_OPT_RTR_ADV_INTERVAL}
  ND_OPT_HOME_AGENT_INFO       = 8;
  {$EXTERNALSYM ND_OPT_HOME_AGENT_INFO}

type
  nd_opt_prefix_info = {packed} record     { prefix information }
    nd_opt_pi_type: uint8_t;
    nd_opt_pi_len: uint8_t;
    nd_opt_pi_prefix_len: uint8_t;
    nd_opt_pi_flags_reserved: uint8_t;
    nd_opt_pi_valid_time: uint32_t;
    nd_opt_pi_preferred_time: uint32_t;
    nd_opt_pi_reserved2: uint32_t;
    nd_opt_pi_prefix: in6_addr;
  end;
  {$EXTERNALSYM nd_opt_prefix_info}

const
  ND_OPT_PI_FLAG_ONLINK        = $80;
  {$EXTERNALSYM ND_OPT_PI_FLAG_ONLINK}
  ND_OPT_PI_FLAG_AUTO          = $40;
  {$EXTERNALSYM ND_OPT_PI_FLAG_AUTO}
  ND_OPT_PI_FLAG_RADDR         = $20;
  {$EXTERNALSYM ND_OPT_PI_FLAG_RADDR}

type
  nd_opt_rd_hdr = {packed} record          { redirected header }
    nd_opt_rh_type: uint8_t;
    nd_opt_rh_len: uint8_t;
    nd_opt_rh_reserved1: uint16_t;
    nd_opt_rh_reserved2: uint32_t;
    { followed by IP header and data }
  end;
  {$EXTERNALSYM nd_opt_rd_hdr}

  _nd_opt_mtu = {packed} record             { MTU option }
    nd_opt_mtu_type: uint8_t;
    nd_opt_mtu_len: uint8_t;
    nd_opt_mtu_reserved: uint16_t;
    nd_opt_mtu_mtu: uint32_t;
  end;
  {.$EXTERNALSYM nd_opt_mtu} // Renamed because of identifier conflict
  TNdOptMtu = _nd_opt_mtu;
  PNdOptMtu = ^TNdOptMtu;

{ Mobile IPv6 extension: Advertisement Interval.  }
  nd_opt_adv_interval = {packed} record
    nd_opt_adv_interval_type: uint8_t;
    nd_opt_adv_interval_len: uint8_t;
    nd_opt_adv_interval_reserved: uint16_t;
    nd_opt_adv_interval_ival: uint32_t;
  end;
  {$EXTERNALSYM nd_opt_adv_interval}

{ Mobile IPv6 extension: Home Agent Info.  }
  _nd_opt_home_agent_info = {packed} record
    nd_opt_home_agent_info_type: uint8_t;
    nd_opt_home_agent_info_len: uint8_t;
    nd_opt_home_agent_info_reserved: uint16_t;
    nd_opt_home_agent_info_preference: int16_t;
    nd_opt_home_agent_info_lifetime: uint16_t;
  end;
  {.$EXTERNALSYM nd_opt_home_agent_info} // Renamed because of identifier conflict
  TNdOptHomeAgentInfo = _nd_opt_home_agent_info;
  PNdOptHomeAgentInfo = ^TNdOptHomeAgentInfo;

// Translated from netinet/if_fddi.h

(*
#include <sys/cdefs.h>
#include <sys/types.h>
#include <asm/types.h>

#include <linux/if_fddi.h>
*)

type
  fddi_header = {packed} record
    fddi_fc: u_int8_t;                                       { Frame Control (FC) value }
    fddi_dhost: packed array[0..FDDI_K_ALEN-1] of u_int8_t;  { Destination host }
    fddi_shost: packed array[0..FDDI_K_ALEN-1] of u_int8_t;   { Source host }
  end;
  {$EXTERNALSYM fddi_header}

// Translated from netinet/if_tr.h

(*
#include <sys/cdefs.h>
#include <sys/types.h>
#include <asm/types.h> end // syntax highlighter tweak

#include <linux/if_tr.h>
*)

type
  trn_hdr = {packed} record
    trn_ac: u_int8_t;                    { access control field }
    trn_fc: u_int8_t;                    { field control field }
    trn_dhost: packed array[0..TR_ALEN-1] of u_int8_t; { destination host }
    trn_shost: packed array[0..TR_ALEN-1] of u_int8_t; { source host }
    trn_rcf: u_int16_t;                  { route control field }
    trn_rseg: packed array[0..8-1] of u_int16_t;       { routing registers }
  end;
  {$EXTERNALSYM trn_hdr}


// Translated from netinet/igmp.h


type
  igmp = {packed} record
    igmp_type: u_int8_t;      { IGMP type }
    igmp_code: u_int8_t;      { routing code }
    igmp_cksum: u_int16_t;    { checksum }
    igmp_group: in_addr;      { group address }
  end;
  {$EXTERNALSYM igmp}

{ Message types, including version number. }
const
  IGMP_MEMBERSHIP_QUERY      = $11;    { membership query         }
  {$EXTERNALSYM IGMP_MEMBERSHIP_QUERY}
  IGMP_V1_MEMBERSHIP_REPORT  = $12;    { Ver. 1 membership report }
  {$EXTERNALSYM IGMP_V1_MEMBERSHIP_REPORT}
  IGMP_V2_MEMBERSHIP_REPORT  = $16;    { Ver. 2 membership report }
  {$EXTERNALSYM IGMP_V2_MEMBERSHIP_REPORT}
  IGMP_V2_LEAVE_GROUP        = $17;    { Leave-group message      }
  {$EXTERNALSYM IGMP_V2_LEAVE_GROUP}


// Translated from netinet/in_systm.h

{
 * Network order versions of various data types. Unfortunately, BSD
 * assumes specific sizes for shorts (16 bit) and longs (32 bit) which
 * don't hold in general. As a consequence, the network order versions
 * may not reflect the actual size of the native data types.
 }

type
  n_short = u_int16_t;      { short as received from the net }
  {$EXTERNALSYM n_short}
  n_long = u_int32_t;       { long as received from the net  }
  {$EXTERNALSYM n_long}
  n_time = u_int32_t;       { ms since 00:00 GMT, byte rev   }
  {$EXTERNALSYM n_time}


// Translated from netinet/ip.h

(*
#include <netinet/in.h>
*)

type
  timestamp = {packed} record
    len: u_int8_t;
    ptr: u_int8_t;

    __bitfield: Cardinal;
(*
#if __BYTE_ORDER == __LITTLE_ENDIAN
    unsigned int flags:4;
    unsigned int overflow:4;
#elif __BYTE_ORDER == __BIG_ENDIAN
    unsigned int overflow:4;
    unsigned int flags:4;
#else
# error	"Please fix <bits/endian.h>"
#endif
*)
    data: packed array[0..9-1] of u_int32_t;
  end;
  {$EXTERNALSYM timestamp}

  iphdr = {packed} record
    __bitfield: Cardinal;
(*
#if __BYTE_ORDER == __LITTLE_ENDIAN
    unsigned int ihl:4;
    unsigned int version:4;
#elif __BYTE_ORDER == __BIG_ENDIAN
    unsigned int version:4;
    unsigned int ihl:4;
#else
# error	"Please fix <bits/endian.h>"
#endif
*)
    tos: u_int8_t;
    tot_len: u_int16_t;
    id: u_int16_t;
    frag_off: u_int16_t;
    ttl: u_int8_t;
    protocol: u_int8_t;
    check: u_int16_t;
    saddr: u_int32_t;
    daddr: u_int32_t;
    {The options start here. }
  end;
  {$EXTERNALSYM iphdr}

{
 * Definitions for internet protocol version 4.
 * Per RFC 791, September 1981.
 }

{ Structure of an internet header, naked of options. }
  ip = {packed} record
    __bitfield: Cardinal;

//#if __BYTE_ORDER == __LITTLE_ENDIAN
//    unsigned int ip_hl:4;		{ header length }
//    unsigned int ip_v:4;		{ version }
//#endif
//#if __BYTE_ORDER == __BIG_ENDIAN
//    unsigned int ip_v:4;		{ version }
//    unsigned int ip_hl:4;		{ header length }
//#endif

    ip_tos: u_int8_t;    { type of service }
    ip_len: u_short;     { total length }
    ip_id: u_short;      { identification }
    ip_off: u_short;     { fragment offset field }
    ip_ttl: u_int8_t;    { time to live }
    ip_p: u_int8_t;      { protocol }
    ip_sum: u_short;     { checksum }
    ip_src, ip_dst: in_addr;    { source and dest address }
  end;
  {$EXTERNALSYM ip}

const
  IP_RF      = $8000;   { reserved fragment flag }
  {$EXTERNALSYM IP_RF}
  IP_DF      = $4000;   { dont fragment flag }
  {$EXTERNALSYM IP_DF}
  IP_MF      = $2000;   { more fragments flag }
  {$EXTERNALSYM IP_MF}
  IP_OFFMASK = $1fff;   { mask for fragmenting bits }
  {$EXTERNALSYM IP_OFFMASK}

{ Time stamp option structure. }
type
  ip_timestamp = {packed} record
    ipt_code: u_int8_t;          { IPOPT_TS }
    ipt_len: u_int8_t;           { size of structure (variable) }
    ipt_ptr: u_int8_t;           { index of current entry }

    __bitfield: Cardinal;

//#if __BYTE_ORDER == __LITTLE_ENDIAN
//    unsigned int ipt_flg:4;		{ flags, see below }
//    unsigned int ipt_oflw:4;		{ overflow counter }
//#endif
//#if __BYTE_ORDER == __BIG_ENDIAN
//    unsigned int ipt_oflw:4;		{ overflow counter }
//    unsigned int ipt_flg:4;		{ flags, see below }
//#endif

    data: packed array[0..9-1] of u_int32_t;
  end;
  {$EXTERNALSYM ip_timestamp}


const
  IPVERSION      = 4;      { IP version number }
  {$EXTERNALSYM IPVERSION}
  IP_MAXPACKET   = 65535;  { maximum packet size }
  {$EXTERNALSYM IP_MAXPACKET}

{ Definitions for IP type of service (ip_tos) }
const
  IPTOS_TOS_MASK     = $1E;
  {$EXTERNALSYM IPTOS_TOS_MASK}
  IPTOS_LOWDELAY     = $10;
  {$EXTERNALSYM IPTOS_LOWDELAY}
  IPTOS_THROUGHPUT   = $08;
  {$EXTERNALSYM IPTOS_THROUGHPUT}
  IPTOS_RELIABILITY  = $04;
  {$EXTERNALSYM IPTOS_RELIABILITY}
  IPTOS_LOWCOST      = $02;
  {$EXTERNALSYM IPTOS_LOWCOST}
  IPTOS_MINCOST      = IPTOS_LOWCOST;
  {$EXTERNALSYM IPTOS_MINCOST}

function IPTOS_TOS(tos: Integer): Integer;
{$EXTERNALSYM IPTOS_TOS}

{ Definitions for IP precedence (also in ip_tos) (hopefully unused) }
const
  IPTOS_PREC_MASK             = $e0;
  {$EXTERNALSYM IPTOS_PREC_MASK}
  IPTOS_PREC_NETCONTROL       = $e0;
  {$EXTERNALSYM IPTOS_PREC_NETCONTROL}
  IPTOS_PREC_INTERNETCONTROL  = $c0;
  {$EXTERNALSYM IPTOS_PREC_INTERNETCONTROL}
  IPTOS_PREC_CRITIC_ECP       = $a0;
  {$EXTERNALSYM IPTOS_PREC_CRITIC_ECP}
  IPTOS_PREC_FLASHOVERRIDE    = $80;
  {$EXTERNALSYM IPTOS_PREC_FLASHOVERRIDE}
  IPTOS_PREC_FLASH            = $60;
  {$EXTERNALSYM IPTOS_PREC_FLASH}
  IPTOS_PREC_IMMEDIATE        = $40;
  {$EXTERNALSYM IPTOS_PREC_IMMEDIATE}
  IPTOS_PREC_PRIORITY         = $20;
  {$EXTERNALSYM IPTOS_PREC_PRIORITY}
  IPTOS_PREC_ROUTINE          = $00;
  {$EXTERNALSYM IPTOS_PREC_ROUTINE}

function IPTOS_PREC(tos: Integer): Integer;
{$EXTERNALSYM IPTOS_PREC}

{ Definitions for options. }
const
  IPOPT_COPY          = $80;
  {$EXTERNALSYM IPOPT_COPY}
  IPOPT_CLASS_MASK    = $60;
  {$EXTERNALSYM IPOPT_CLASS_MASK}
  IPOPT_NUMBER_MASK   = $1f;
  {$EXTERNALSYM IPOPT_NUMBER_MASK}

function IPOPT_COPIED(o: Integer): Integer;
{$EXTERNALSYM IPOPT_COPIED}
function IPOPT_CLASS(o: Integer): Integer;
{$EXTERNALSYM IPOPT_CLASS}
function IPOPT_NUMBER(o: Integer): Integer;
{$EXTERNALSYM IPOPT_NUMBER}

const
  IPOPT_CONTROL       = $00;
  {$EXTERNALSYM IPOPT_CONTROL}
  IPOPT_RESERVED1     = $20;
  {$EXTERNALSYM IPOPT_RESERVED1}
  IPOPT_DEBMEAS       = $40;
  {$EXTERNALSYM IPOPT_DEBMEAS}
  IPOPT_MEASUREMENT   = IPOPT_DEBMEAS;
  {$EXTERNALSYM IPOPT_MEASUREMENT}
  IPOPT_RESERVED2     = $60;
  {$EXTERNALSYM IPOPT_RESERVED2}

  IPOPT_EOL           = 0;                { end of option list }
  {$EXTERNALSYM IPOPT_EOL}
  IPOPT_END           = IPOPT_EOL;
  {$EXTERNALSYM IPOPT_END}
  IPOPT_NOP           = 1;                { no operation }
  {$EXTERNALSYM IPOPT_NOP}
  IPOPT_NOOP          = IPOPT_NOP;
  {$EXTERNALSYM IPOPT_NOOP}

  IPOPT_RR            = 7;                { record packet route }
  {$EXTERNALSYM IPOPT_RR}
  IPOPT_TS            = 68;               { timestamp }
  {$EXTERNALSYM IPOPT_TS}
  IPOPT_TIMESTAMP     = IPOPT_TS;
  {$EXTERNALSYM IPOPT_TIMESTAMP}
  IPOPT_SECURITY      = 130;              { provide s,c,h,tcc }
  {$EXTERNALSYM IPOPT_SECURITY}
  IPOPT_SEC           = IPOPT_SECURITY;
  {$EXTERNALSYM IPOPT_SEC}
  IPOPT_LSRR          = 131;              { loose source route }
  {$EXTERNALSYM IPOPT_LSRR}
  IPOPT_SATID         = 136;              { satnet id }
  {$EXTERNALSYM IPOPT_SATID}
  IPOPT_SID           = IPOPT_SATID;
  {$EXTERNALSYM IPOPT_SID}
  IPOPT_SSRR          = 137;              { strict source route }
  {$EXTERNALSYM IPOPT_SSRR}
  IPOPT_RA            = 148;              { router alert }
  {$EXTERNALSYM IPOPT_RA}

{ Offsets to fields in options other than EOL and NOP. }
  IPOPT_OPTVAL        = 0;                { option ID }
  {$EXTERNALSYM IPOPT_OPTVAL}
  IPOPT_OLEN          = 1;                { option length }
  {$EXTERNALSYM IPOPT_OLEN}
  IPOPT_OFFSET        = 2;                { offset within option }
  {$EXTERNALSYM IPOPT_OFFSET}
  IPOPT_MINOFF        = 4;                { min value of above }
  {$EXTERNALSYM IPOPT_MINOFF}

  MAX_IPOPTLEN        = 40;
  {$EXTERNALSYM MAX_IPOPTLEN}

{ flag bits for ipt_flg }
  IPOPT_TS_TSONLY     = 0;                { timestamps only }
  {$EXTERNALSYM IPOPT_TS_TSONLY}
  IPOPT_TS_TSANDADDR  = 1;                { timestamps and addresses }
  {$EXTERNALSYM IPOPT_TS_TSANDADDR}
  IPOPT_TS_PRESPEC    = 3;                { specified modules only }
  {$EXTERNALSYM IPOPT_TS_PRESPEC}

{ bits for security (not byte swapped) }
  IPOPT_SECUR_UNCLASS = $0000;
  {$EXTERNALSYM IPOPT_SECUR_UNCLASS}
  IPOPT_SECUR_CONFID  = $f135;
  {$EXTERNALSYM IPOPT_SECUR_CONFID}
  IPOPT_SECUR_EFTO    = $789a;
  {$EXTERNALSYM IPOPT_SECUR_EFTO}
  IPOPT_SECUR_MMMM    = $bc4d;
  {$EXTERNALSYM IPOPT_SECUR_MMMM}
  IPOPT_SECUR_RESTR   = $af13;
  {$EXTERNALSYM IPOPT_SECUR_RESTR}
  IPOPT_SECUR_SECRET  = $d788;
  {$EXTERNALSYM IPOPT_SECUR_SECRET}
  IPOPT_SECUR_TOPSECRET = $6bc5;
  {$EXTERNALSYM IPOPT_SECUR_TOPSECRET}

{ Internet implementation parameters. }
  MAXTTL      = 255;    { maximum time to live (seconds) }
  {$EXTERNALSYM MAXTTL}
  IPDEFTTL    = 64;     { default ttl, from RFC 1340 }
  {$EXTERNALSYM IPDEFTTL}
  IPFRAGTTL   = 60;     { time to live for frags, slowhz }
  {$EXTERNALSYM IPFRAGTTL}
  IPTTLDEC    = 1;      { subtracted when forwarding }
  {$EXTERNALSYM IPTTLDEC}

  IP_MSS = 576;         { default maximum segment size }
  {$EXTERNALSYM IP_MSS}


// Translated from netinet/ip6.h

(*
#include <inttypes.h>
#include <netinet/in.h>
*)

type

  ip6_hdrctl = {packed} record
    ip6_un1_flow: uint32_t;   { 24 bits of flow-ID }
    ip6_un1_plen: uint16_t;   { payload length }
    ip6_un1_nxt: uint8_t;    { next header }
    ip6_un1_hlim: uint8_t;   { hop limit }
  end;
  {$EXTERNALSYM ip6_hdrctl}

   TIP6CtlUnion = {packed} record
     ip6_un2_vfc: uint8_t; { 4 bits version, 4 bits priority }
     ip6_un1: ip6_hdrctl;
   end;
  {.$EXTERNALSYM TIP6CtlUnion} // Used anonymously in header file

  ip6_hdr = {packed} record
    ip6_ctlun: TIP6CtlUnion;
    ip6_src: in6_addr;      { source address }
    ip6_dst: in6_addr;      { destination address }
  end;
  {$EXTERNALSYM ip6_hdr}

(* Cannot translate this
#define ip6_vfc   ip6_ctlun.ip6_un2_vfc
#define ip6_flow  ip6_ctlun.ip6_un1.ip6_un1_flow
#define ip6_plen  ip6_ctlun.ip6_un1.ip6_un1_plen
#define ip6_nxt   ip6_ctlun.ip6_un1.ip6_un1_nxt
#define ip6_hlim  ip6_ctlun.ip6_un1.ip6_un1_hlim
#define ip6_hops  ip6_ctlun.ip6_un1.ip6_un1_hlim
*)

{ Hop-by-Hop options header.  }
  ip6_hbh = {packed} record
    ip6h_nxt: uint8_t;        { next hesder.  }
    ip6h_len: uint8_t;        { length in units of 8 octets.  }
    { followed by options }
  end;
  {$EXTERNALSYM ip6_hbh}

{ Destination options header }
  ip6_dest = {packed} record
    ip6d_nxt: uint8_t;        { next header }
    ip6d_len: uint8_t;        { length in units of 8 octets }
    { followed by options }
  end;
  {$EXTERNALSYM ip6_dest}

{ Routing header }
  ip6_rthdr = {packed} record
    ip6r_nxt: uint8_t;        { next header }
    ip6r_len: uint8_t;        { length in units of 8 octets }
    ip6r_type: uint8_t;       { routing type }
    ip6r_segleft: uint8_t;    { segments left }
    { followed by routing type specific data }
  end;
  {$EXTERNALSYM ip6_rthdr}

{ Type 0 Routing header }
  ip6_rthdr0 = {packed} record
    ip6r0_nxt: uint8_t;       { next header }
    ip6r0_len: uint8_t;       { length in units of 8 octets }
    ip6r0_type: uint8_t;      { always zero }
    ip6r0_segleft: uint8_t;   { segments left }
    ip6r0_reserved: uint8_t;  { reserved field }
    ip6r0_slmap: packed array[0..3-1] of uint8_t;  { strict/loose bit map }
    ip6r0_addr: packed array[0..1-1] of in6_addr;  { up to 23 addresses }
  end;
  {$EXTERNALSYM ip6_rthdr0}

{ Fragment header }
  ip6_frag = {packed} record
    ip6f_nxt: uint8_t;        { next header }
    ip6f_reserved: uint8_t;   { reserved field }
    ip6f_offlg: uint16_t;     { offset, reserved, and flag }
    ip6f_ident: uint32_t;     { identification }
  end;
  {$EXTERNALSYM ip6_frag}

const
  IP6F_OFF_MASK       = $f8ff;  { mask out offset from _offlg }
  {$EXTERNALSYM IP6F_OFF_MASK}
  IP6F_RESERVED_MASK  = $0600;  { reserved bits in ip6f_offlg }
  {$EXTERNALSYM IP6F_RESERVED_MASK}
  IP6F_MORE_FRAG      = $0100;  { more-fragments flag }
  {$EXTERNALSYM IP6F_MORE_FRAG}


// Translated from netinet/ip_icmp.h

type
  icmphdr = {packed} record
    __type: u_int8_t;        { message type }
    code: u_int8_t;          { type sub-code }
    checksum: u_int16_t;
    un: {packed} record
          case Integer of
            0: ( echo: {packed} record  { echo datagram }
                   id: u_int16_t;
                   sequence: u_int16_t;
                 end;
               );

            1: (gateway: u_int32_t); { gateway address }

            2: ( frag: {packed} record
                   __unused: u_int16_t;
                   mtu: u_int16_t;
                 end;
               );
          end;
  end;
  {$EXTERNALSYM icmphdr}

const
  ICMP_ECHOREPLY        = 0;    { Echo Reply }
  {$EXTERNALSYM ICMP_ECHOREPLY}
  ICMP_DEST_UNREACH     = 3;    { Destination Unreachable }
  {$EXTERNALSYM ICMP_DEST_UNREACH}
  ICMP_SOURCE_QUENCH    = 4;    { Source Quench }
  {$EXTERNALSYM ICMP_SOURCE_QUENCH}
  ICMP_REDIRECT         = 5;    { Redirect (change route) }
  {$EXTERNALSYM ICMP_REDIRECT}
  ICMP_ECHO             = 8;    { Echo Request }
  {$EXTERNALSYM ICMP_ECHO}
  ICMP_TIME_EXCEEDED    = 11;   { Time Exceeded }
  {$EXTERNALSYM ICMP_TIME_EXCEEDED}
  ICMP_PARAMETERPROB    = 12;   { Parameter Problem }
  {$EXTERNALSYM ICMP_PARAMETERPROB}
  ICMP_TIMESTAMP        = 13;   { Timestamp Request }
  {$EXTERNALSYM ICMP_TIMESTAMP}
  ICMP_TIMESTAMPREPLY   = 14;   { Timestamp Reply }
  {$EXTERNALSYM ICMP_TIMESTAMPREPLY}
  ICMP_INFO_REQUEST     = 15;   { Information Request }
  {$EXTERNALSYM ICMP_INFO_REQUEST}
  ICMP_INFO_REPLY       = 16;   { Information Reply }
  {$EXTERNALSYM ICMP_INFO_REPLY}
  ICMP_ADDRESS          = 17;   { Address Mask Request }
  {$EXTERNALSYM ICMP_ADDRESS}
  ICMP_ADDRESSREPLY     = 18;   { Address Mask Reply }
  {$EXTERNALSYM ICMP_ADDRESSREPLY}
  NR_ICMP_TYPES         = 18;
  {$EXTERNALSYM NR_ICMP_TYPES}


{ Codes for UNREACH. }
  ICMP_NET_UNREACH      = 0;    { Network Unreachable }
  {$EXTERNALSYM ICMP_NET_UNREACH}
  ICMP_HOST_UNREACH     = 1;    { Host Unreachable }
  {$EXTERNALSYM ICMP_HOST_UNREACH}
  ICMP_PROT_UNREACH     = 2;    { Protocol Unreachable }
  {$EXTERNALSYM ICMP_PROT_UNREACH}
  ICMP_PORT_UNREACH     = 3;    { Port Unreachable }
  {$EXTERNALSYM ICMP_PORT_UNREACH}
  ICMP_FRAG_NEEDED      = 4;    { Fragmentation Needed/DF set }
  {$EXTERNALSYM ICMP_FRAG_NEEDED}
  ICMP_SR_FAILED        = 5;    { Source Route failed }
  {$EXTERNALSYM ICMP_SR_FAILED}
  ICMP_NET_UNKNOWN      = 6;
  {$EXTERNALSYM ICMP_NET_UNKNOWN}
  ICMP_HOST_UNKNOWN     = 7;
  {$EXTERNALSYM ICMP_HOST_UNKNOWN}
  ICMP_HOST_ISOLATED    = 8;
  {$EXTERNALSYM ICMP_HOST_ISOLATED}
  ICMP_NET_ANO          = 9;
  {$EXTERNALSYM ICMP_NET_ANO}
  ICMP_HOST_ANO         = 10;
  {$EXTERNALSYM ICMP_HOST_ANO}
  ICMP_NET_UNR_TOS      = 11;
  {$EXTERNALSYM ICMP_NET_UNR_TOS}
  ICMP_HOST_UNR_TOS     = 12;
  {$EXTERNALSYM ICMP_HOST_UNR_TOS}
  ICMP_PKT_FILTERED     = 13;   { Packet filtered }
  {$EXTERNALSYM ICMP_PKT_FILTERED}
  ICMP_PREC_VIOLATION   = 14;   { Precedence violation }
  {$EXTERNALSYM ICMP_PREC_VIOLATION}
  ICMP_PREC_CUTOFF      = 15;   { Precedence cut off }
  {$EXTERNALSYM ICMP_PREC_CUTOFF}
  NR_ICMP_UNREACH       = 15;   { instead of hardcoding immediate value }
  {$EXTERNALSYM NR_ICMP_UNREACH}

{ Codes for REDIRECT. }
  ICMP_REDIR_NET        = 0;    { Redirect Net }
  {$EXTERNALSYM ICMP_REDIR_NET}
  ICMP_REDIR_HOST       = 1;    { Redirect Host }
  {$EXTERNALSYM ICMP_REDIR_HOST}
  ICMP_REDIR_NETTOS     = 2;    { Redirect Net for TOS }
  {$EXTERNALSYM ICMP_REDIR_NETTOS}
  ICMP_REDIR_HOSTTOS    = 3;    { Redirect Host for TOS }
  {$EXTERNALSYM ICMP_REDIR_HOSTTOS}

{ Codes for TIME_EXCEEDED. }
  ICMP_EXC_TTL          = 0;    { TTL count exceeded }
  {$EXTERNALSYM ICMP_EXC_TTL}
  ICMP_EXC_FRAGTIME     = 1;    { Fragment Reass time exceeded }
  {$EXTERNALSYM ICMP_EXC_FRAGTIME}


{ Internal of an ICMP Router Advertisement }
type
  icmp_ra_addr = {packed} record
    ira_addr: u_int32_t;
    ira_preference: u_int32_t;
  end;
  {$EXTERNALSYM icmp_ra_addr}

  ih_rtradv_t = {packed} record
    irt_num_addrs: u_int8_t;
    irt_wpa: u_int8_t;
    irt_lifetime: u_int16_t;
  end;
  // Internally used in struct

  ih_pmtu_t = {packed} record
    ipm_void: u_int16_t;
    ipm_nextmtu: u_int16_t;
  end;
  // Internally used in struct

  ih_idseq_t = {packed} record { echo datagram }
    icd_id: u_int16_t;
    icd_seq: u_int16_t;
  end;
  // Internally used in struct

  id_ts_t = {packed} record
    its_otime: u_int32_t;
    its_rtime: u_int32_t;
    its_ttime: u_int32_t;
  end;
  // Internally used in struct

  id_ip_t = {packed} record
    idi_ip: ip;
    { options and then 64 bits of data }
  end;
  // Internally used in struct

  icmp = {packed} record
    icmp_type: u_int8_t;       { type of message, see below }
    icmp_code: u_int8_t;       { type sub code }
    icmp_cksum: u_int16_t;     { ones complement checksum of struct }
    icmp_hun: {packed} record
                case Integer of
                  0: (ih_pptr: u_char         { ICMP_PARAMPROB });
                  1: (ih_gwaddr: in_addr      { gateway address });
                  2: (ih_idseq: ih_idseq_t    { echo datagram });
                  3: (ih_void: u_int32_t);
                     { ICMP_UNREACH_NEEDFRAG -- Path MTU Discovery (RFC1191) }
                  4: (ih_pmtu: ih_pmtu_t);
                  5: (ih_rtradv: ih_rtradv_t);
                end;

// Cannot translate this
{
#define	icmp_pptr	icmp_hun.ih_pptr
#define	icmp_gwaddr	icmp_hun.ih_gwaddr
#define	icmp_id		icmp_hun.ih_idseq.icd_id
#define	icmp_seq	icmp_hun.ih_idseq.icd_seq
#define	icmp_void	icmp_hun.ih_void
#define	icmp_pmvoid	icmp_hun.ih_pmtu.ipm_void
#define	icmp_nextmtu	icmp_hun.ih_pmtu.ipm_nextmtu
#define	icmp_num_addrs	icmp_hun.ih_rtradv.irt_num_addrs
#define	icmp_wpa	icmp_hun.ih_rtradv.irt_wpa
#define	icmp_lifetime	icmp_hun.ih_rtradv.irt_lifetime
}
    icmp_dun: packed record
                case Integer of
                  0: (id_ts: id_ts_t);
                  1: (id_ip: id_ip_t);
                  2: (id_radv: icmp_ra_addr);
                  3: (id_mask: u_int32_t);
                  4: (id_data: packed array[0..1-1] of u_int8_t);
                end;

// Cannot translate this
{
#define	icmp_otime	icmp_dun.id_ts.its_otime
#define	icmp_rtime	icmp_dun.id_ts.its_rtime
#define	icmp_ttime	icmp_dun.id_ts.its_ttime
#define	icmp_ip		icmp_dun.id_ip.idi_ip
#define	icmp_radv	icmp_dun.id_radv
#define	icmp_mask	icmp_dun.id_mask
#define	icmp_data	icmp_dun.id_data
}

  end;
  {$EXTERNALSYM icmp}

{
 * Lower bounds on packet lengths for various types.
 * For the error advice packets must first insure that the
 * packet is large enough to contain the returned ip header.
 * Only then can we do the check to see if 64 bits of packet
 * data have been returned, since we need to check the returned
 * ip header length.
 }
const
  ICMP_MINLEN = 8; { abs minimum }
  {$EXTERNALSYM ICMP_MINLEN}
  ICMP_TSLEN = (8 + 3 * SizeOf(n_time)); { timestamp }
  {$EXTERNALSYM ICMP_TSLEN}
  ICMP_MASKLEN = 12; { address mask }
  {$EXTERNALSYM ICMP_MASKLEN}
  ICMP_ADVLENMIN = (8 + SizeOf(ip) + 8); { min }
  {$EXTERNALSYM ICMP_ADVLENMIN}


function ICMP_ADVLEN(const p: icmp): Cardinal;
{$EXTERNALSYM ICMP_ADVLEN}
{ N.B.: must separately check that ip_hl >= 5 }


const
{ Definition of type and code fields. }
{ defined above: ICMP_ECHOREPLY, ICMP_REDIRECT, ICMP_ECHO }
  ICMP_UNREACH               = 3;       { dest unreachable, codes: }
  {$EXTERNALSYM ICMP_UNREACH}
  ICMP_SOURCEQUENCH          = 4;       { packet lost, slow down }
  {$EXTERNALSYM ICMP_SOURCEQUENCH}
  ICMP_ROUTERADVERT          = 9;       { router advertisement }
  {$EXTERNALSYM ICMP_ROUTERADVERT}
  ICMP_ROUTERSOLICIT         = 10;      { router solicitation }
  {$EXTERNALSYM ICMP_ROUTERSOLICIT}
  ICMP_TIMXCEED              = 11;      { time exceeded, code: }
  {$EXTERNALSYM ICMP_TIMXCEED}
  ICMP_PARAMPROB             = 12;      { ip header bad }
  {$EXTERNALSYM ICMP_PARAMPROB}
  ICMP_TSTAMP                = 13;      { timestamp request }
  {$EXTERNALSYM ICMP_TSTAMP}
  ICMP_TSTAMPREPLY           = 14;      { timestamp reply }
  {$EXTERNALSYM ICMP_TSTAMPREPLY}
  ICMP_IREQ                  = 15;      { information request }
  {$EXTERNALSYM ICMP_IREQ}
  ICMP_IREQREPLY             = 16;      { information reply }
  {$EXTERNALSYM ICMP_IREQREPLY}
  ICMP_MASKREQ               = 17;      { address mask request }
  {$EXTERNALSYM ICMP_MASKREQ}
  ICMP_MASKREPLY             = 18;      { address mask reply }
  {$EXTERNALSYM ICMP_MASKREPLY}

  ICMP_MAXTYPE               = 18;
  {$EXTERNALSYM ICMP_MAXTYPE}

{ UNREACH codes }
  ICMP_UNREACH_NET           = 0;      { bad net }
  {$EXTERNALSYM ICMP_UNREACH_NET}
  ICMP_UNREACH_HOST          = 1;      { bad host }
  {$EXTERNALSYM ICMP_UNREACH_HOST}
  ICMP_UNREACH_PROTOCOL      = 2;      { bad protocol }
  {$EXTERNALSYM ICMP_UNREACH_PROTOCOL}
  ICMP_UNREACH_PORT          = 3;      { bad port }
  {$EXTERNALSYM ICMP_UNREACH_PORT}
  ICMP_UNREACH_NEEDFRAG      = 4;      { IP_DF caused drop }
  {$EXTERNALSYM ICMP_UNREACH_NEEDFRAG}
  ICMP_UNREACH_SRCFAIL       = 5;      { src route failed }
  {$EXTERNALSYM ICMP_UNREACH_SRCFAIL}
  ICMP_UNREACH_NET_UNKNOWN   = 6;      { unknown net }
  {$EXTERNALSYM ICMP_UNREACH_NET_UNKNOWN}
  ICMP_UNREACH_HOST_UNKNOWN  = 7;      { unknown host }
  {$EXTERNALSYM ICMP_UNREACH_HOST_UNKNOWN}
  ICMP_UNREACH_ISOLATED      = 8;      { src host isolated }
  {$EXTERNALSYM ICMP_UNREACH_ISOLATED}
  ICMP_UNREACH_NET_PROHIB    = 9;      { net denied }
  {$EXTERNALSYM ICMP_UNREACH_NET_PROHIB}
  ICMP_UNREACH_HOST_PROHIB   = 10;     { host denied }
  {$EXTERNALSYM ICMP_UNREACH_HOST_PROHIB}
  ICMP_UNREACH_TOSNET        = 11;     { bad tos for net }
  {$EXTERNALSYM ICMP_UNREACH_TOSNET}
  ICMP_UNREACH_TOSHOST       = 12;     { bad tos for host }
  {$EXTERNALSYM ICMP_UNREACH_TOSHOST}
  ICMP_UNREACH_FILTER_PROHIB = 13;     { admin prohib }
  {$EXTERNALSYM ICMP_UNREACH_FILTER_PROHIB}
  ICMP_UNREACH_HOST_PRECEDENCE = 14;   { host prec vio. }
  {$EXTERNALSYM ICMP_UNREACH_HOST_PRECEDENCE}
  ICMP_UNREACH_PRECEDENCE_CUTOFF = 15; { prec cutoff }
  {$EXTERNALSYM ICMP_UNREACH_PRECEDENCE_CUTOFF}

{ REDIRECT codes }
  ICMP_REDIRECT_NET      = 0;     { for network }
  {$EXTERNALSYM ICMP_REDIRECT_NET}
  ICMP_REDIRECT_HOST     = 1;     { for host }
  {$EXTERNALSYM ICMP_REDIRECT_HOST}
  ICMP_REDIRECT_TOSNET   = 2;     { for tos and net }
  {$EXTERNALSYM ICMP_REDIRECT_TOSNET}
  ICMP_REDIRECT_TOSHOST  = 3;     { for tos and host }
  {$EXTERNALSYM ICMP_REDIRECT_TOSHOST}

{ TIMEXCEED codes }
  ICMP_TIMXCEED_INTRANS  = 0;     { ttl==0 in transit }
  {$EXTERNALSYM ICMP_TIMXCEED_INTRANS}
  ICMP_TIMXCEED_REASS    = 1;     { ttl==0 in reass }
  {$EXTERNALSYM ICMP_TIMXCEED_REASS}

{ PARAMPROB code }
  ICMP_PARAMPROB_OPTABSENT = 1;     { req. opt. absent }
  {$EXTERNALSYM ICMP_PARAMPROB_OPTABSENT}

function ICMP_INFOTYPE(__type: Cardinal): Boolean;
{$EXTERNALSYM ICMP_INFOTYPE}


// Translated from netinet/tcp.h

(* Only defined for __FAVOR_BSD
type
  tcp_seq = u_int32_t;
  {$EXTERNALSYM }
{
 * TCP header.
 * Per RFC 793, September, 1981.
 }
  tcphdr = {packed} record
    th_sport: u_int16_t;   { source port }
    th_dport: u_int16_t;   { destination port }
    th_seq: tcp_seq;       { sequence number }
    th_ack: tcp_seq;       { acknowledgement number }
    __bitfield: u_int8_t;
  {
    u_int8_t th_x2:4;      { (unused) }
    u_int8_t th_off:4;     { data offset }
  }
    th_flags: u_int8_t;
    th_win: u_int16_t;     { window }
    th_sum: u_int16_t;     { checksum }
    th_urp: u_int16_t;     { urgent pointer }
  end;
  {$EXTERNALSYM tcphdr}

const
  TH_FIN    = $01;
  {$EXTERNALSYM TH_FIN}
  TH_SYN    = $02;
  {$EXTERNALSYM TH_SYN}
  TH_RST    = $04;
  {$EXTERNALSYM TH_RST}
  TH_PUSH   = $08;
  {$EXTERNALSYM TH_PUSH}
  TH_ACK    = $10;
  {$EXTERNALSYM TH_ACK}
  TH_URG    = $20;
  {$EXTERNALSYM TH_URG}
*)

type
  tcphdr = {packed} record
    source: u_int16_t;
    dest: u_int16_t;
    seq: u_int32_t;
    ack_seq: u_int32_t;
    __bitfield: u_int16_t;
  (*
    u_int16_t res1:4;
    u_int16_t doff:4;
    u_int16_t fin:1;
    u_int16_t syn:1;
    u_int16_t rst:1;
    u_int16_t psh:1;
    u_int16_t ack:1;
    u_int16_t urg:1;
    u_int16_t res2:2;
  *)
    window: u_int16_t;
    check: u_int16_t;
    urg_ptr: u_int16_t;
  end;
  {$EXTERNALSYM tcphdr}



const
  TCP_ESTABLISHED = 1;
  {$EXTERNALSYM TCP_ESTABLISHED}
  TCP_SYN_SENT = 2;
  {$EXTERNALSYM TCP_SYN_SENT}
  TCP_SYN_RECV = 3;
  {$EXTERNALSYM TCP_SYN_RECV}
  TCP_FIN_WAIT1 = 4;
  {$EXTERNALSYM TCP_FIN_WAIT1}
  TCP_FIN_WAIT2 = 5;
  {$EXTERNALSYM TCP_FIN_WAIT2}
  TCP_TIME_WAIT = 6;
  {$EXTERNALSYM TCP_TIME_WAIT}
  TCP_CLOSE = 7;
  {$EXTERNALSYM TCP_CLOSE}
  TCP_CLOSE_WAIT = 8;
  {$EXTERNALSYM TCP_CLOSE_WAIT}
  TCP_LAST_ACK = 9;
  {$EXTERNALSYM TCP_LAST_ACK}
  TCP_LISTEN = 10;
  {$EXTERNALSYM TCP_LISTEN}
  TCP_CLOSING = 11;   { now a valid state }
  {$EXTERNALSYM TCP_CLOSING}


  TCPOPT_EOL              = 0;
  {$EXTERNALSYM TCPOPT_EOL}
  TCPOPT_NOP              = 1;
  {$EXTERNALSYM TCPOPT_NOP}
  TCPOPT_MAXSEG           = 2;
  {$EXTERNALSYM TCPOPT_MAXSEG}
  TCPOLEN_MAXSEG          = 4;
  {$EXTERNALSYM TCPOLEN_MAXSEG}
  TCPOPT_WINDOW           = 3;
  {$EXTERNALSYM TCPOPT_WINDOW}
  TCPOLEN_WINDOW          = 3;
  {$EXTERNALSYM TCPOLEN_WINDOW}
  TCPOPT_SACK_PERMITTED   = 4; { Experimental }
  {$EXTERNALSYM TCPOPT_SACK_PERMITTED}
  TCPOLEN_SACK_PERMITTED  = 2;
  {$EXTERNALSYM TCPOLEN_SACK_PERMITTED}
  TCPOPT_SACK             = 5; { Experimental }
  {$EXTERNALSYM TCPOPT_SACK}
  TCPOPT_TIMESTAMP        = 8;
  {$EXTERNALSYM TCPOPT_TIMESTAMP}
  TCPOLEN_TIMESTAMP       = 10;
  {$EXTERNALSYM TCPOLEN_TIMESTAMP}
  TCPOLEN_TSTAMP_APPA     = (TCPOLEN_TIMESTAMP+2); { appendix A }
  {$EXTERNALSYM TCPOLEN_TSTAMP_APPA}

  TCPOPT_TSTAMP_HDR =
    (TCPOPT_NOP shl 24) or (TCPOPT_NOP shl 16) or
    (TCPOPT_TIMESTAMP shl 8) or (TCPOLEN_TIMESTAMP);
  {$EXTERNALSYM TCPOPT_TSTAMP_HDR}

{
 * Default maximum segment size for TCP.
 * With an IP MSS of 576, this is 536,
 * but 512 is probably more convenient.
 * This should be defined as MIN(512, IP_MSS - sizeof (struct tcpiphdr)).
 }
const
  TCP_MSS = 512;
  {$EXTERNALSYM TCP_MSS}

  TCP_MAXWIN = 65535; { largest value for (unscaled) window }
  {$EXTERNALSYM TCP_MAXWIN}

  TCP_MAX_WINSHIFT = 14; { maximum window shift }
  {$EXTERNALSYM TCP_MAX_WINSHIFT}

{ User-settable options (used with setsockopt). }
  TCP_NODELAY         = $01;       { Don't delay send to coalesce packets  }
  {$EXTERNALSYM TCP_NODELAY}
  TCP_MAXSEG          = $02;       { Set maximum segment size  }
  {$EXTERNALSYM TCP_MAXSEG}
  TCP_CORK            = $03;       { Control sending of partial frames  }
  {$EXTERNALSYM TCP_CORK}
  TCP_KEEPIDLE        = $04;       { Start keeplives after this period }
  {$EXTERNALSYM TCP_KEEPIDLE}
  TCP_KEEPINTVL       = $05;       { Interval between keepalives }
  {$EXTERNALSYM TCP_KEEPINTVL}
  TCP_KEEPCNT         = $06;       { Number of keepalives before death }
  {$EXTERNALSYM TCP_KEEPCNT}
  TCP_SYNCNT          = $07;       { Number of SYN retransmits }
  {$EXTERNALSYM TCP_SYNCNT}
  TCP_LINGER2         = $08;       { Life time of orphaned FIN-WAIT-2 state }
  {$EXTERNALSYM TCP_LINGER2}
  TCP_DEFER_ACCEPT    = $09;       { Wake up listener only when data arrive }
  {$EXTERNALSYM TCP_DEFER_ACCEPT}
  TCP_WINDOW_CLAMP    = $10;       { Bound advertised window }
  {$EXTERNALSYM TCP_WINDOW_CLAMP}
  TCP_INFO            = $11;       { Information about this connection. }
  {$EXTERNALSYM TCP_INFO}

  SOL_TCP = 6;   { TCP level }
  {$EXTERNALSYM SOL_TCP}


  TCPI_OPT_TIMESTAMPS = 1;
  {$EXTERNALSYM TCPI_OPT_TIMESTAMPS}
  TCPI_OPT_SACK = 2;
  {$EXTERNALSYM TCPI_OPT_SACK}
  TCPI_OPT_WSCALE = 4;
  {$EXTERNALSYM TCPI_OPT_WSCALE}
  TCPI_OPT_ECN = 8;
  {$EXTERNALSYM TCPI_OPT_ECN}

{ Values for tcpi_state.  }
type
  tcp_ca_state =
  (
    TCP_CA_Open = 0,
    {$EXTERNALSYM TCP_CA_Open}
    TCP_CA_Disorder = 1,
    {$EXTERNALSYM TCP_CA_Disorder}
    TCP_CA_CWR = 2,
    {$EXTERNALSYM TCP_CA_CWR}
    TCP_CA_Recovery = 3,
    {$EXTERNALSYM TCP_CA_Recovery}
    TCP_CA_Loss = 4
    {$EXTERNALSYM TCP_CA_Loss}
  );
  {$EXTERNALSYM tcp_ca_state}

type
  _tcp_info = {packed} record
    tcpi_state: u_int8_t;
    tcpi_ca_state: u_int8_t;
    tcpi_retransmits: u_int8_t;
    tcpi_probes: u_int8_t;
    tcpi_backoff: u_int8_t;
    tcpi_options: u_int8_t;
    __bitfield: u_int8_t;
  (*
    u_int8_t tcpi_snd_wscale : 4, tcpi_rcv_wscale : 4;
  *)

    tcpi_rto: u_int32_t;
    tcpi_ato: u_int32_t;
    tcpi_snd_mss: u_int32_t;
    tcpi_rcv_mss: u_int32_t;

    tcpi_unacked: u_int32_t;
    tcpi_sacked: u_int32_t;
    tcpi_lost: u_int32_t;
    tcpi_retrans: u_int32_t;
    tcpi_fackets: u_int32_t;

    { Times. }
    tcpi_last_data_sent: u_int32_t;
    tcpi_last_ack_sent: u_int32_t; { Not remembered, sorry.  }
    tcpi_last_data_recv: u_int32_t;
    tcpi_last_ack_recv: u_int32_t;

    { Metrics. }
    tcpi_pmtu: u_int32_t;
    tcpi_rcv_ssthresh: u_int32_t;
    tcpi_rtt: u_int32_t;
    tcpi_rttvar: u_int32_t;
    tcpi_snd_ssthresh: u_int32_t;
    tcpi_snd_cwnd: u_int32_t;
    tcpi_advmss: u_int32_t;
    tcpi_reordering: u_int32_t;
  end;
  {.$EXTERNALSYM tcp_info} // Renamed because of identifier conflict
  TTcpInfo = _tcp_info;
  PTcpInfo = ^TTcpInfo;


// Translated from netinet/udp.h

{ UDP header as specified by RFC 768, August 1980. }
(* Only defined for __FAVOR_BSD
type
  udphdr = {packed} record
    uh_sport: u_int16_t;  { source port }
    uh_dport: u_int16_t;  { destination port }
    uh_ulen: u_int16_t;   { udp length }
    uh_sum: u_int16_t;    { udp checksum }
  end;
  {$EXTERNALSYM udphdr}
*)

type
  udphdr = {packed} record
    source: u_int16_t;
    dest: u_int16_t;
    len: u_int16_t;
    check: u_int16_t;
  end;
  {$EXTERNALSYM udphdr}


const
  SOL_UDP = 17;      { sockopt level for UDP }
  {$EXTERNALSYM SOL_UDP}


// Translated from protocols/routed.h

(*
#include <sys/socket.h>
*)

{
 * Routing Information Protocol
 *
 * Derived from Xerox NS Routing Information Protocol
 * by changing 32-bit net numbers to sockaddr's and
 * padding stuff to 32-bit boundaries.
 }
const
  RIPVERSION = 1;
  {$EXTERNALSYM RIPVERSION}

type
  netinfo = {packed} record
    rip_dst: sockaddr;      { destination net/host }
    rip_metric: Integer;    { cost of route }
  end;
  {$EXTERNALSYM netinfo}

  __ripun = {packed} record  // Used anonymously in header file
              case Integer of
                0: (ru_nets: packed array[0..1-1] of netinfo);   { variable length... }
                1: (ru_tracefile: packed array[0..1-1] of Char); { ditto ... }
              end;

  rip = {packed} record
    rip_cmd: Byte;      { request/response }
    rip_vers: Byte;     { protocol version # }
    rip_res1: packed array[0..2-1] of Byte; { pad to 32-bit boundary }
    ripun: __ripun;
  end;
  {$EXTERNALSYM rip}


{ Packet types. }
const
  RIPCMD_REQUEST    = 1;    { want info }
  {$EXTERNALSYM RIPCMD_REQUEST}
  RIPCMD_RESPONSE   = 2;    { responding to request }
  {$EXTERNALSYM RIPCMD_RESPONSE}
  RIPCMD_TRACEON    = 3;    { turn tracing on }
  {$EXTERNALSYM RIPCMD_TRACEON}
  RIPCMD_TRACEOFF   = 4;    { turn it off }
  {$EXTERNALSYM RIPCMD_TRACEOFF}

  RIPCMD_MAX        = 5;
  {$EXTERNALSYM RIPCMD_MAX}

const
  (* --- defined array *)
  ripcmds: packed array[0..RIPCMD_MAX-1] of PChar =
  ( '#0', 'REQUEST', 'RESPONSE', 'TRACEON', 'TRACEOFF' );
  {$EXTERNALSYM ripcmds}

const
  HOPCNT_INFINITY   = 16;   { per Xerox NS }
  {$EXTERNALSYM HOPCNT_INFINITY}
  MAXPACKETSIZE     = 512;  { max broadcast size }
  {$EXTERNALSYM MAXPACKETSIZE}

{
 * Timer values used in managing the routing table.
 * Complete tables are broadcast every SUPPLY_INTERVAL seconds.
 * If changes occur between updates, dynamic updates containing only changes
 * may be sent.  When these are sent, a timer is set for a random value
 * between MIN_WAITTIME and MAX_WAITTIME, and no additional dynamic updates
 * are sent until the timer expires.
 *
 * Every update of a routing entry forces an entry's timer to be reset.
 * After EXPIRE_TIME without updates, the entry is marked invalid,
 * but held onto until GARBAGE_TIME so that others may
 * see it "be deleted".
 }
  TIMER_RATE       = 30;    { alarm clocks every 30 seconds }
  {$EXTERNALSYM TIMER_RATE}

  SUPPLY_INTERVAL  = 30;    { time to supply tables }
  {$EXTERNALSYM SUPPLY_INTERVAL}
  MIN_WAITTIME     = 2;     { min. interval to broadcast changes }
  {$EXTERNALSYM MIN_WAITTIME}
  MAX_WAITTIME     = 5;     { max. time to delay changes }
  {$EXTERNALSYM MAX_WAITTIME}

  EXPIRE_TIME      = 180;   { time to mark entry invalid }
  {$EXTERNALSYM EXPIRE_TIME}
  GARBAGE_TIME     = 240;   { time to garbage collect }
  {$EXTERNALSYM GARBAGE_TIME}


// Translated from protocols/rwhod.h

type
{ rwho protocol packet format. }
  outmp = {packed} record
    out_line: packed array[0..8-1] of Char;   { tty name }
    out_name: packed array[0..8-1] of Char;   { user id }
    out_time: int32_t;                        { time on }
  end;
  {$EXTERNALSYM outmp}

  whoent = {packed} record
    we_utmp: outmp;         { active tty info }
    we_idle: Integer;       { tty idle time }
  end;
  {$EXTERNALSYM whoent}

  whod = {packed} record
    wd_vers: Shortint;          { protocol version # }
    wd_type: Shortint;          { packet type, see below }
    wd_pad: packed array[0..2-1] of Shortint;
    wd_sendtime: Integer;       { time stamp by sender }
    wd_recvtime: Integer;       { time stamp applied by receiver }
    wd_hostname: packed array[0..32-1] of Char;    { hosts's name }
    wd_loadav: packed array[0..3-1] of Integer;    { load average as in uptime }
    wd_boottime: Integer;       { time system booted }
    wd_we: packed array[0..(1024 div SizeOf(whoent))-1] of whoent;
  end;
  {$EXTERNALSYM whod}

const
  WHODVERSION = 1;
  {$EXTERNALSYM WHODVERSION}
  WHODTYPE_STATUS = 1;   { host status }
  {$EXTERNALSYM WHODTYPE_STATUS}

(*
{ We used to define _PATH_RWHODIR here but it's now in <paths.h>.  }
#include <paths.h>
*)


// Translated from protocols/talkd.h

{
 * This describes the protocol used by the talk server and clients.
 *
 * The talk server acts a repository of invitations, responding to
 * requests by clients wishing to rendezvous for the purpose of
 * holding a conversation.  In normal operation, a client, the caller,
 * initiates a rendezvous by sending a CTL_MSG to the server of
 * type LOOK_UP.  This causes the server to search its invitation
 * tables to check if an invitation currently exists for the caller
 * (to speak to the callee specified in the message).  If the lookup
 * fails, the caller then sends an ANNOUNCE message causing the server
 * to broadcast an announcement on the callee's login ports requesting
 * contact.  When the callee responds, the local server uses the
 * recorded invitation to respond with the appropriate rendezvous
 * address and the caller and callee client programs establish a
 * stream connection through which the conversation takes place.
 }

{ Client->server request message format. }
type
  CTL_MSG = {packed} record
    vers: u_char;         { protocol version }
    __type: u_char;       { request type, see below }
    answer: u_char;       { not used }
    pad: u_char;
    id_num: u_int32_t;    { message id }
    addr: osockaddr;      { old (4.3) style }
    ctl_addr: osockaddr;  { old (4.3) style }
    pid: int32_t;         { caller's process id }
    l_name: packed array[0..12-1 {NAME_SIZE}] of Char; { caller's name }
    r_name: packed array[0..12-1 {NAME_SIZE}] of Char; { callee's name }
    r_tty: packed array[0..16-1 {TTY_SIZE}] of Char;   { callee's tty name }
  end;
  {$EXTERNALSYM CTL_MSG}

{ Server->client response message format. }
  CTL_RESPONSE = {packed} record
    vers: u_char;           { protocol version }
    __type: u_char;         { type of request message, see below }
    answer: u_char;         { response to request message, see below }
    pad: u_char;
    id_num: u_int32_t;      { message id }
    addr: osockaddr;        { address for establishing conversation }
  end;
  {$EXTERNALSYM CTL_RESPONSE}

const
  TALK_VERSION = 1;         { protocol version }
  {$EXTERNALSYM TALK_VERSION}

{ message type values }
  LEAVE_INVITE      = 0;    { leave invitation with server }
  {$EXTERNALSYM LEAVE_INVITE}
  LOOK_UP           = 1;    { check for invitation by callee }
  {$EXTERNALSYM LOOK_UP}
  __DELETE            = 2;    { delete invitation by caller }
  {.$EXTERNALSYM DELETE}
  ANNOUNCE          = 3;    { announce invitation by caller }
  {$EXTERNALSYM ANNOUNCE}

{ answer values }
  SUCCESS           = 0;    { operation completed properly }
  {$EXTERNALSYM SUCCESS}
  NOT_HERE          = 1;    { callee not logged in }
  {$EXTERNALSYM NOT_HERE}
  FAILED            = 2;    { operation failed for unexplained reason }
  {$EXTERNALSYM FAILED}
  MACHINE_UNKNOWN   = 3;    { caller's machine name unknown }
  {$EXTERNALSYM MACHINE_UNKNOWN}
  PERMISSION_DENIED = 4;    { callee's tty doesn't permit announce }
  {$EXTERNALSYM PERMISSION_DENIED}
  UNKNOWN_REQUEST   = 5;    { request has invalid type value }
  {$EXTERNALSYM UNKNOWN_REQUEST}
  BADVERSION        = 6;    { request has invalid protocol version }
  {$EXTERNALSYM BADVERSION}
  BADADDR           = 7;    { request has invalid addr value }
  {$EXTERNALSYM BADADDR}
  BADCTLADDR        = 8;    { request has invalid ctl_addr value }
  {$EXTERNALSYM BADCTLADDR}

{ Operational parameters. }
  MAX_LIFE = 60;            { max time daemon saves invitations }
  {$EXTERNALSYM MAX_LIFE}
{ RING_WAIT should be 10's of seconds less than MAX_LIFE }
  RING_WAIT = 30;           { time to wait before resending invitation }
  {$EXTERNALSYM RING_WAIT}


// Translated from protocols/timed.h

(*
#include <rpc/types.h>
*)

{ Time Synchronization Protocol }
const
  TSPVERSION = 1;
  {$EXTERNALSYM TSPVERSION}
  ANYADDR = nil;
  {$EXTERNALSYM ANYADDR}

type
  tsp_u = {packed} record
    case Integer of
      0: (tspu_time: timeval);
      1: (tspu_hopcnt: Shortint);
    end;
  {$EXTERNALSYM tsp_u}

  tsp = {packed} record
    tsp_type: u_char;
    tsp_vers: u_char;
    tsp_seq: u_short;
    tspu_data: tsp_u;
    tsp_name: packed array[0..MAXHOSTNAMELEN-1] of Char;
  end;
  {$EXTERNALSYM tsp}


{ Command types. }
const
  TSP_ANY          = 0;     { match any types }
  {$EXTERNALSYM TSP_ANY}
  TSP_ADJTIME      = 1;     { send adjtime }
  {$EXTERNALSYM TSP_ADJTIME}
  TSP_ACK          = 2;     { generic acknowledgement }
  {$EXTERNALSYM TSP_ACK}
  TSP_MASTERREQ    = 3;     { ask for master's name }
  {$EXTERNALSYM TSP_MASTERREQ}
  TSP_MASTERACK    = 4;     { acknowledge master request }
  {$EXTERNALSYM TSP_MASTERACK}
  TSP_SETTIME      = 5;     { send network time }
  {$EXTERNALSYM TSP_SETTIME}
  TSP_MASTERUP     = 6;     { inform slaves that master is up }
  {$EXTERNALSYM TSP_MASTERUP}
  TSP_SLAVEUP      = 7;     { slave is up but not polled }
  {$EXTERNALSYM TSP_SLAVEUP}
  TSP_ELECTION     = 8;     { advance candidature for master }
  {$EXTERNALSYM TSP_ELECTION}
  TSP_ACCEPT       = 9;     { support candidature of master }
  {$EXTERNALSYM TSP_ACCEPT}
  TSP_REFUSE       = 10;    { reject candidature of master }
  {$EXTERNALSYM TSP_REFUSE}
  TSP_CONFLICT     = 11;    { two or more masters present }
  {$EXTERNALSYM TSP_CONFLICT}
  TSP_RESOLVE      = 12;    { masters' conflict resolution }
  {$EXTERNALSYM TSP_RESOLVE}
  TSP_QUIT         = 13;    { reject candidature if master is up }
  {$EXTERNALSYM TSP_QUIT}
  TSP_DATE         = 14;    { reset the time (date command) }
  {$EXTERNALSYM TSP_DATE}
  TSP_DATEREQ      = 15;    { remote request to reset the time }
  {$EXTERNALSYM TSP_DATEREQ}
  TSP_DATEACK      = 16;    { acknowledge time setting  }
  {$EXTERNALSYM TSP_DATEACK}
  TSP_TRACEON      = 17;    { turn tracing on }
  {$EXTERNALSYM TSP_TRACEON}
  TSP_TRACEOFF     = 18;    { turn tracing off }
  {$EXTERNALSYM TSP_TRACEOFF}
  TSP_MSITE        = 19;    { find out master's site }
  {$EXTERNALSYM TSP_MSITE}
  TSP_MSITEREQ     = 20;    { remote master's site request }
  {$EXTERNALSYM TSP_MSITEREQ}
  TSP_TEST         = 21;    { for testing election algo }
  {$EXTERNALSYM TSP_TEST}
  TSP_SETDATE      = 22;    { New from date command }
  {$EXTERNALSYM TSP_SETDATE}
  TSP_SETDATEREQ   = 23;    { New remote for above }
  {$EXTERNALSYM TSP_SETDATEREQ}
  TSP_LOOP         = 24;    { loop detection packet }
  {$EXTERNALSYM TSP_LOOP}

  TSPTYPENUMBER    = 25;
  {$EXTERNALSYM TSPTYPENUMBER}

const
  tsptype: packed array[0..TSPTYPENUMBER-1] of PChar =
  ( 'ANY', 'ADJTIME', 'ACK', 'MASTERREQ', 'MASTERACK', 'SETTIME', 'MASTERUP',
  'SLAVEUP', 'ELECTION', 'ACCEPT', 'REFUSE', 'CONFLICT', 'RESOLVE', 'QUIT',
  'DATE', 'DATEREQ', 'DATEACK', 'TRACEON', 'TRACEOFF', 'MSITE', 'MSITEREQ',
  'TEST', 'SETDATE', 'SETDATEREQ', 'LOOP' );
  {$EXTERNALSYM tsptype}


// Translated from scsi/scsi.h

{ SCSI opcodes }

(*
  All SCSI opcodes have been prefixed with
      __
  to avoid major namespace clashes with the
  System unit; those identifiers that do not
  clash have been renamed for consistency. 
*)

const
  __TEST_UNIT_READY       = $00;
  {.$EXTERNALSYM TEST_UNIT_READY}
  __REZERO_UNIT           = $01;
  {.$EXTERNALSYM REZERO_UNIT}
  __REQUEST_SENSE         = $03;
  {.$EXTERNALSYM REQUEST_SENSE}
  __FORMAT_UNIT           = $04;
  {.$EXTERNALSYM FORMAT_UNIT}
  __READ_BLOCK_LIMITS     = $05;
  {.$EXTERNALSYM READ_BLOCK_LIMITS}
  __REASSIGN_BLOCKS       = $07;
  {.$EXTERNALSYM REASSIGN_BLOCKS}
  __READ_6                = $08;
  {.$EXTERNALSYM READ_6}
  __WRITE_6               = $0a;
  {.$EXTERNALSYM WRITE_6}
  __SEEK_6                = $0b;
  {.$EXTERNALSYM SEEK_6}
  __READ_REVERSE          = $0f;
  {.$EXTERNALSYM READ_REVERSE}
  __WRITE_FILEMARKS       = $10;
  {.$EXTERNALSYM WRITE_FILEMARKS}
  __SPACE                 = $11;
  {.$EXTERNALSYM SPACE}
  __INQUIRY               = $12;
  {.$EXTERNALSYM INQUIRY}
  __RECOVER_BUFFERED_DATA = $14;
  {.$EXTERNALSYM RECOVER_BUFFERED_DATA}
  __MODE_SELECT           = $15;
  {.$EXTERNALSYM MODE_SELECT}
  __RESERVE               = $16;
  {.$EXTERNALSYM RESERVE}
  __RELEASE               = $17;
  {.$EXTERNALSYM RELEASE}
  __COPY                  = $18;
  {.$EXTERNALSYM COPY}
  __ERASE                 = $19;
  {.$EXTERNALSYM ERASE}
  __MODE_SENSE            = $1a;
  {.$EXTERNALSYM MODE_SENSE}
  __START_STOP            = $1b;
  {.$EXTERNALSYM START_STOP}
  __RECEIVE_DIAGNOSTIC    = $1c;
  {.$EXTERNALSYM RECEIVE_DIAGNOSTIC}
  __SEND_DIAGNOSTIC       = $1d;
  {.$EXTERNALSYM SEND_DIAGNOSTIC}
  __ALLOW_MEDIUM_REMOVAL  = $1e;
  {.$EXTERNALSYM ALLOW_MEDIUM_REMOVAL}

  __SET_WINDOW            = $24;
  {.$EXTERNALSYM SET_WINDOW}
  __READ_CAPACITY         = $25;
  {.$EXTERNALSYM READ_CAPACITY}
  __READ_10               = $28;
  {.$EXTERNALSYM READ_10}
  __WRITE_10              = $2a;
  {.$EXTERNALSYM WRITE_10}
  __SEEK_10               = $2b;
  {.$EXTERNALSYM SEEK_10}
  __WRITE_VERIFY          = $2e;
  {.$EXTERNALSYM WRITE_VERIFY}
  __VERIFY                = $2f;
  {.$EXTERNALSYM VERIFY}
  __SEARCH_HIGH           = $30;
  {.$EXTERNALSYM SEARCH_HIGH}
  __SEARCH_EQUAL          = $31;
  {.$EXTERNALSYM SEARCH_EQUAL}
  __SEARCH_LOW            = $32;
  {.$EXTERNALSYM SEARCH_LOW}
  __SET_LIMITS            = $33;
  {.$EXTERNALSYM SET_LIMITS}
  __PRE_FETCH             = $34;
  {.$EXTERNALSYM PRE_FETCH}
  __READ_POSITION         = $34;
  {.$EXTERNALSYM READ_POSITION}
  __SYNCHRONIZE_CACHE     = $35;
  {.$EXTERNALSYM SYNCHRONIZE_CACHE}
  __LOCK_UNLOCK_CACHE     = $36;
  {.$EXTERNALSYM LOCK_UNLOCK_CACHE}
  __READ_DEFECT_DATA      = $37;
  {.$EXTERNALSYM READ_DEFECT_DATA}
  __MEDIUM_SCAN           = $38;
  {.$EXTERNALSYM MEDIUM_SCAN}
  __COMPARE               = $39;
  {.$EXTERNALSYM COMPARE}
  __COPY_VERIFY           = $3a;
  {.$EXTERNALSYM COPY_VERIFY}
  __WRITE_BUFFER          = $3b;
  {.$EXTERNALSYM WRITE_BUFFER}
  __READ_BUFFER           = $3c;
  {.$EXTERNALSYM READ_BUFFER}
  __UPDATE_BLOCK          = $3d;
  {.$EXTERNALSYM UPDATE_BLOCK}
  __READ_LONG             = $3e;
  {.$EXTERNALSYM READ_LONG}
  __WRITE_LONG            = $3f;
  {.$EXTERNALSYM WRITE_LONG}
  __CHANGE_DEFINITION     = $40;
  {.$EXTERNALSYM CHANGE_DEFINITION}
  __WRITE_SAME            = $41;
  {.$EXTERNALSYM WRITE_SAME}
  __READ_TOC              = $43;
  {.$EXTERNALSYM READ_TOC}
  __LOG_SELECT            = $4c;
  {.$EXTERNALSYM LOG_SELECT}
  __LOG_SENSE             = $4d;
  {.$EXTERNALSYM LOG_SENSE}
  __MODE_SELECT_10        = $55;
  {.$EXTERNALSYM MODE_SELECT_10}
  __RESERVE_10            = $56;
  {.$EXTERNALSYM RESERVE_10}
  __RELEASE_10            = $57;
  {.$EXTERNALSYM RELEASE_10}
  __MODE_SENSE_10         = $5a;
  {.$EXTERNALSYM MODE_SENSE_10}
  __PERSISTENT_RESERVE_IN = $5e;
  {.$EXTERNALSYM PERSISTENT_RESERVE_IN}
  __PERSISTENT_RESERVE_OUT = $5f;
  {.$EXTERNALSYM PERSISTENT_RESERVE_OUT}
  __MOVE_MEDIUM           = $a5;
  {.$EXTERNALSYM MOVE_MEDIUM}
  __READ_12               = $a8;
  {.$EXTERNALSYM READ_12}
  __WRITE_12              = $aa;
  {.$EXTERNALSYM WRITE_12}
  __WRITE_VERIFY_12       = $ae;
  {.$EXTERNALSYM WRITE_VERIFY_12}
  __SEARCH_HIGH_12        = $b0;
  {.$EXTERNALSYM SEARCH_HIGH_12}
  __SEARCH_EQUAL_12       = $b1;
  {.$EXTERNALSYM SEARCH_EQUAL_12}
  __SEARCH_LOW_12         = $b2;
  {.$EXTERNALSYM SEARCH_LOW_12}
  __READ_ELEMENT_STATUS   = $b8;
  {.$EXTERNALSYM READ_ELEMENT_STATUS}
  __SEND_VOLUME_TAG       = $b6;
  {.$EXTERNALSYM SEND_VOLUME_TAG}
  __WRITE_LONG_2          = $ea;
  {.$EXTERNALSYM WRITE_LONG_2}

{ Status codes }

  GOOD                 = $00;
  {$EXTERNALSYM GOOD}
  CHECK_CONDITION      = $01;
  {$EXTERNALSYM CHECK_CONDITION}
  CONDITION_GOOD       = $02;
  {$EXTERNALSYM CONDITION_GOOD}
  BUSY                 = $04;
  {$EXTERNALSYM BUSY}
  INTERMEDIATE_GOOD    = $08;
  {$EXTERNALSYM INTERMEDIATE_GOOD}
  INTERMEDIATE_C_GOOD  = $0a;
  {$EXTERNALSYM INTERMEDIATE_C_GOOD}
  RESERVATION_CONFLICT = $0c;
  {$EXTERNALSYM RESERVATION_CONFLICT}
  COMMAND_TERMINATED   = $11;
  {$EXTERNALSYM COMMAND_TERMINATED}
  QUEUE_FULL           = $14;
  {$EXTERNALSYM QUEUE_FULL}

  __STATUS_MASK          = $3e;
  {.$EXTERNALSYM STATUS_MASK}

{ SENSE KEYS }

  NO_SENSE            = $00;
  {$EXTERNALSYM NO_SENSE}
  RECOVERED_ERROR     = $01;
  {$EXTERNALSYM RECOVERED_ERROR}
  NOT_READY           = $02;
  {$EXTERNALSYM NOT_READY}
  MEDIUM_ERROR        = $03;
  {$EXTERNALSYM MEDIUM_ERROR}
  HARDWARE_ERROR      = $04;
  {$EXTERNALSYM HARDWARE_ERROR}
  ILLEGAL_REQUEST     = $05;
  {$EXTERNALSYM ILLEGAL_REQUEST}
  UNIT_ATTENTION      = $06;
  {$EXTERNALSYM UNIT_ATTENTION}
  DATA_PROTECT        = $07;
  {$EXTERNALSYM DATA_PROTECT}
  BLANK_CHECK         = $08;
  {$EXTERNALSYM BLANK_CHECK}
  COPY_ABORTED        = $0a;
  {$EXTERNALSYM COPY_ABORTED}
  ABORTED_COMMAND     = $0b;
  {$EXTERNALSYM ABORTED_COMMAND}
  VOLUME_OVERFLOW     = $0d;
  {$EXTERNALSYM VOLUME_OVERFLOW}
  MISCOMPARE          = $0e;
  {$EXTERNALSYM MISCOMPARE}


{ DEVICE TYPES }

  TYPE_DISK           = $00;
  {$EXTERNALSYM TYPE_DISK}
  TYPE_TAPE           = $01;
  {$EXTERNALSYM TYPE_TAPE}
  TYPE_PROCESSOR      = $03;    { HP scanners use this }
  {$EXTERNALSYM TYPE_PROCESSOR}
  TYPE_WORM           = $04;    { Treated as ROM by our system }
  {$EXTERNALSYM TYPE_WORM}
  TYPE_ROM            = $05;
  {$EXTERNALSYM TYPE_ROM}
  TYPE_SCANNER        = $06;
  {$EXTERNALSYM TYPE_SCANNER}
  TYPE_MOD            = $07;    { Magneto-optical disk - treated as TYPE_DISK }
  {$EXTERNALSYM TYPE_MOD}
  TYPE_MEDIUM_CHANGER = $08;
  {$EXTERNALSYM TYPE_MEDIUM_CHANGER}
  TYPE_ENCLOSURE      = $0d;    { Enclosure Services Device }
  {$EXTERNALSYM TYPE_ENCLOSURE}
  TYPE_NO_LUN         = $7f;
  {$EXTERNALSYM TYPE_NO_LUN}

{
   Standard mode-select header prepended to all mode-select commands

   Moved here from cdrom.h -- kraxel }

type
  ccs_modesel_head = {packed} record
    _r1: Byte;                          { reserved.  }
    medium: Byte;                       { device-specific medium type.  }
    _r2: Byte;                          { reserved.  }
    block_desc_length: Byte;            { block descriptor length.  }
    density: Byte;                      { device-specific density code.  }
    number_blocks_hi: Byte;             { number of blocks in this block desc.  }
    number_blocks_med: Byte;
    number_blocks_lo: Byte;
    _r3: Byte;
    block_length_hi: Byte;              { block length for blocks in this desc.  }
    block_length_med: Byte;
    block_length_lo: Byte;
  end;
  {$EXTERNALSYM ccs_modesel_head}

(*
  All SCSI message codes have been prefixed with
      __
  to avoid major namespace clashes with the
  System unit; those identifiers that do not
  clash have been renamed for consistency.
*)

{ MESSAGE CODES }
const
  __COMMAND_COMPLETE    = $00;
  {.$EXTERNALSYM COMMAND_COMPLETE}
  __EXTENDED_MESSAGE    = $01;
  {.$EXTERNALSYM EXTENDED_MESSAGE}
      __EXTENDED_MODIFY_DATA_POINTER    = $00;
      {.$EXTERNALSYM EXTENDED_MODIFY_DATA_POINTER}
      __EXTENDED_SDTR                   = $01;
      {.$EXTERNALSYM EXTENDED_SDTR}
      __EXTENDED_EXTENDED_IDENTIFY      = $02;    { SCSI-I only }
      {.$EXTERNALSYM EXTENDED_EXTENDED_IDENTIFY}
      __EXTENDED_WDTR                   = $03;
      {.$EXTERNALSYM EXTENDED_WDTR}
  __SAVE_POINTERS       = $02;
  {.$EXTERNALSYM SAVE_POINTERS}
  __RESTORE_POINTERS    = $03;
  {.$EXTERNALSYM RESTORE_POINTERS}
  __DISCONNECT          = $04;
  {.$EXTERNALSYM DISCONNECT}
  __INITIATOR_ERROR     = $05;
  {.$EXTERNALSYM INITIATOR_ERROR}
  __ABORT__             = $06; // Appended underscores, too.
  {.$EXTERNALSYM ABORT}
  __MESSAGE_REJECT      = $07;
  {.$EXTERNALSYM MESSAGE_REJECT}
  __NOP                 = $08;
  {.$EXTERNALSYM NOP}
  __MSG_PARITY_ERROR    = $09;
  {.$EXTERNALSYM MSG_PARITY_ERROR}
  __LINKED_CMD_COMPLETE = $0a;
  {.$EXTERNALSYM LINKED_CMD_COMPLETE}
  __LINKED_FLG_CMD_COMPLETE = $0b;
  {.$EXTERNALSYM LINKED_FLG_CMD_COMPLETE}
  __BUS_DEVICE_RESET    = $0c;
  {.$EXTERNALSYM BUS_DEVICE_RESET}

  __INITIATE_RECOVERY   = $0f;            { SCSI-II only }
  {.$EXTERNALSYM INITIATE_RECOVERY}
  __RELEASE_RECOVERY    = $10;            { SCSI-II only }
  {.$EXTERNALSYM RELEASE_RECOVERY}

  __SIMPLE_QUEUE_TAG    = $20;
  {.$EXTERNALSYM SIMPLE_QUEUE_TAG}
  __HEAD_OF_QUEUE_TAG   = $21;
  {.$EXTERNALSYM HEAD_OF_QUEUE_TAG}
  __ORDERED_QUEUE_TAG   = $22;
  {.$EXTERNALSYM ORDERED_QUEUE_TAG}

{ Here are some scsi specific ioctl commands which are sometimes useful. }
{ These are a few other constants only used by scsi devices.  }

  SCSI_IOCTL_GET_IDLUN = $5382;
  {$EXTERNALSYM SCSI_IOCTL_GET_IDLUN}

{ Used to turn on and off tagged queuing for scsi devices.  }

  SCSI_IOCTL_TAGGED_ENABLE = $5383;
  {$EXTERNALSYM SCSI_IOCTL_TAGGED_ENABLE}
  SCSI_IOCTL_TAGGED_DISABLE = $5384;
  {$EXTERNALSYM SCSI_IOCTL_TAGGED_DISABLE}

{ Used to obtain the host number of a device.  }
  SCSI_IOCTL_PROBE_HOST = $5385;
  {$EXTERNALSYM SCSI_IOCTL_PROBE_HOST}

{ Used to get the bus number for a device.  }
  SCSI_IOCTL_GET_BUS_NUMBER = $5386;
  {$EXTERNALSYM SCSI_IOCTL_GET_BUS_NUMBER}


// Translated from scsi/scsi_ioctl.h

{ IOCTLs for SCSI.  }
  SCSI_IOCTL_SEND_COMMAND        = 1;      { Send a command to the SCSI host.  }
  {$EXTERNALSYM SCSI_IOCTL_SEND_COMMAND}
  SCSI_IOCTL_TEST_UNIT_READY     = 2;      { Test if unit is ready.  }
  {$EXTERNALSYM SCSI_IOCTL_TEST_UNIT_READY}
  SCSI_IOCTL_BENCHMARK_COMMAND   = 3;
  {$EXTERNALSYM SCSI_IOCTL_BENCHMARK_COMMAND}
  SCSI_IOCTL_SYNC                = 4;      { Request synchronous parameters.  }
  {$EXTERNALSYM SCSI_IOCTL_SYNC}
  SCSI_IOCTL_START_UNIT          = 5;
  {$EXTERNALSYM SCSI_IOCTL_START_UNIT}
  SCSI_IOCTL_STOP_UNIT           = 6;
  {$EXTERNALSYM SCSI_IOCTL_STOP_UNIT}
  SCSI_IOCTL_DOORLOCK            = $5380;  { Lock the eject mechanism.  }
  {$EXTERNALSYM SCSI_IOCTL_DOORLOCK}
  SCSI_IOCTL_DOORUNLOCK          = $5381;  { Unlock the mechanism.  }
  {$EXTERNALSYM SCSI_IOCTL_DOORUNLOCK}


// Translated from scsi/sg.h


{ New interface introduced in the 3.x SG drivers follows }

{ Same structure as used by readv() Linux system call. It defines one
   scatter-gather element. }
type
  sg_iovec = {packed} record
    iov_base: Pointer;            { Starting address  }
    iov_len: size_t;              { Length in bytes  }
  end;
  {$EXTERNALSYM sg_iovec}
  sg_iovec_t = sg_iovec;
  {$EXTERNALSYM sg_iovec_t}


  sg_io_hdr = {packed} record
    interface_id: Integer;           { [i] 'S' for SCSI generic (required) }
    dxfer_direction: Integer;        { [i] data transfer direction  }
    cmd_len: Byte;                   { [i] SCSI command length ( <= 16 bytes) }
    mx_sb_len: Byte;                 { [i] max length to write to sbp }
    iovec_count: Word;               { [i] 0 implies no scatter gather }
    dxfer_len: Cardinal;             { [i] byte count of data transfer }
    dxferp: Pointer;                 { [i], [*io] points to data transfer memory
                                            or scatter gather list }
    cmdp: PByte;                     { [i], [*i] points to command to perform }
    sbp: PByte;                      { [i], [*o] points to sense_buffer memory }
    timeout: Cardinal;               { [i] MAX_UINT->no timeout (unit: millisec) }
    flags: Cardinal;                 { [i] 0 -> default, see SG_FLAG... }
    pack_id: Integer;                { [i->o] unused internally (normally) }
    usr_ptr: Pointer;                { [i->o] unused internally }
    status: Byte;                    { [o] scsi status }
    masked_status: Byte;             { [o] shifted, masked scsi status }
    msg_status: Byte;                { [o] messaging level data (optional) }
    sb_len_wr: Byte;                 { [o] byte count actually written to sbp }
    host_status: Word;               { [o] errors from host adapter }
    driver_status: Word;             { [o] errors from software driver }
    resid: Integer;                  { [o] dxfer_len - actual_transferred }
    duration: Cardinal;              { [o] time taken by cmd (unit: millisec) }
    info: Cardinal;                  { [o] auxiliary information }
  end;
  {$EXTERNALSYM sg_io_hdr}
  sg_io_hdr_t = sg_io_hdr;
  {$EXTERNALSYM sg_io_hdr_t}


{ Use negative values to flag difference from original sg_header structure.  }
const
  SG_DXFER_NONE = -1;       { e.g. a SCSI Test Unit Ready command }
  {$EXTERNALSYM SG_DXFER_NONE}
  SG_DXFER_TO_DEV = -2;     { e.g. a SCSI WRITE command }
  {$EXTERNALSYM SG_DXFER_TO_DEV}
  SG_DXFER_FROM_DEV = -3;   { e.g. a SCSI READ command }
  {$EXTERNALSYM SG_DXFER_FROM_DEV}
  SG_DXFER_TO_FROM_DEV = -4;{ treated like SG_DXFER_FROM_DEV with the
                              additional property than during indirect
                              IO the user buffer is copied into the
                              kernel buffers before the transfer }
  {$EXTERNALSYM SG_DXFER_TO_FROM_DEV}


{ The following flag values can be "or"-ed together }
  SG_FLAG_DIRECT_IO = 1;     { default is indirect IO }
  {$EXTERNALSYM SG_FLAG_DIRECT_IO}
  SG_FLAG_LUN_INHIBIT = 2;   { default is to put device's lun into }
                             { the 2nd byte of SCSI command }
  {$EXTERNALSYM SG_FLAG_LUN_INHIBIT}
  SG_FLAG_NO_DXFER = $10000; { no transfer of kernel buffers to/from }
                             { user space (debug indirect IO) }
  {$EXTERNALSYM SG_FLAG_NO_DXFER}

{ The following 'info' values are "or"-ed together.  }
  SG_INFO_OK_MASK   = $1;
  {$EXTERNALSYM SG_INFO_OK_MASK}
  SG_INFO_OK        = $0;    { no sense, host nor driver "noise" }
  {$EXTERNALSYM SG_INFO_OK}
  SG_INFO_CHECK     = $1;    { something abnormal happened }
  {$EXTERNALSYM SG_INFO_CHECK}

  SG_INFO_DIRECT_IO_MASK   = $6;
  {$EXTERNALSYM SG_INFO_DIRECT_IO_MASK}
  SG_INFO_INDIRECT_IO      = $0;        { data xfer via kernel buffers (or no xfer) }
  {$EXTERNALSYM SG_INFO_INDIRECT_IO}
  SG_INFO_DIRECT_IO        = $2;        { direct IO requested and performed }
  {$EXTERNALSYM SG_INFO_DIRECT_IO}
  SG_INFO_MIXED_IO         = $4;        { part direct, part indirect IO }
  {$EXTERNALSYM SG_INFO_MIXED_IO}


{ Request information about a specific SG device, used by
   SG_GET_SCSI_ID ioctl ().  }
type
  sg_scsi_id = {packed} record
    { Host number as in "scsi<n>" where 'n' is one of 0, 1, 2 etc.  }
    host_no: Integer;
    channel: Integer;
    { SCSI id of target device.  }
    scsi_id: Integer;
    lun: Integer;
    { TYPE_... defined in <scsi/scsi.h>.  }
    scsi_type: Integer;
    { Host (adapter) maximum commands per lun.  }
    h_cmd_per_lun: Smallint;
    { Device (or adapter) maximum queue length.  }
    d_queue_depth: Smallint;
    { Unused, set to 0 for now.  }
    unused: packed array[0..2-1] of Integer;
  end;
  {$EXTERNALSYM sg_scsi_id}

{ Used by SG_GET_REQUEST_TABLE ioctl().  }
  sg_req_info = {packed} record
    req_state: Shortint;     { 0 -> not used, 1 -> written, 2 -> ready to read }
    orphan: Shortint;        { 0 -> normal request, 1 -> from interruped SG_IO }
    sg_io_owned: Shortint;   { 0 -> complete with read(), 1 -> owned by SG_IO }
    problem: Shortint;       { 0 -> no problem detected, 1 -> error to report }
    pack_id: Integer;        { pack_id associated with request }
    usr_ptr: Pointer;        { user provided pointer (in new interface) }
    duration: Cardinal;      { millisecs elapsed since written (req_state==1)
                               or request duration (req_state==2) }
    unused: Integer;
  end;
  {$EXTERNALSYM sg_req_info}
  sg_req_info_t = sg_req_info;
  {$EXTERNALSYM sg_req_info_t}


{ IOCTLs: Those ioctls that are relevant to the SG 3.x drivers follow.
 [Those that only apply to the SG 2.x drivers are at the end of the file.]
 (_GET_s yield result via 'int *' 3rd argument unless otherwise indicated) }
const
  SG_EMULATED_HOST = $2203; { true for emulated host adapter (ATAPI) }
  {$EXTERNALSYM SG_EMULATED_HOST}

{ Used to configure SCSI command transformation layer for ATAPI devices }
{ Only supported by the ide-scsi driver }
  SG_SET_TRANSFORM = $2204; { N.B. 3rd arg is not pointer but value: }
                            { 3rd arg = 0 to disable transform, 1 to enable it }
  {$EXTERNALSYM SG_SET_TRANSFORM}
  SG_GET_TRANSFORM = $2205;
  {$EXTERNALSYM SG_GET_TRANSFORM}

  SG_SET_RESERVED_SIZE = $2275;  { request a new reserved buffer size }
  {$EXTERNALSYM SG_SET_RESERVED_SIZE}
  SG_GET_RESERVED_SIZE = $2272;  { actual size of reserved buffer }
  {$EXTERNALSYM SG_GET_RESERVED_SIZE}

{ The following ioctl has a 'sg_scsi_id_t *' object as its 3rd argument. }
  SG_GET_SCSI_ID = $2276;   { Yields fd's bus, chan, dev, lun + type }
  {$EXTERNALSYM SG_GET_SCSI_ID}
{ SCSI id information can also be obtained from SCSI_IOCTL_GET_IDLUN }

{ Override host setting and always DMA using low memory ( <16MB on i386) }
  SG_SET_FORCE_LOW_DMA = $2279;  { 0-> use adapter setting, 1-> force }
  {$EXTERNALSYM SG_SET_FORCE_LOW_DMA}
  SG_GET_LOW_DMA = $227a;   { 0-> use all ram for dma; 1-> low dma ram }
  {$EXTERNALSYM SG_GET_LOW_DMA}

{ When SG_SET_FORCE_PACK_ID set to 1, pack_id is input to read() which
   tries to fetch a packet with a matching pack_id, waits, or returns EAGAIN.
   If pack_id is -1 then read oldest waiting. When ...FORCE_PACK_ID set to 0
   then pack_id ignored by read() and oldest readable fetched. }
  SG_SET_FORCE_PACK_ID = $227b;
  {$EXTERNALSYM SG_SET_FORCE_PACK_ID}
  SG_GET_PACK_ID = $227c; { Yields oldest readable pack_id (or -1) }
  {$EXTERNALSYM SG_GET_PACK_ID}

  SG_GET_NUM_WAITING = $227d; { Number of commands awaiting read() }
  {$EXTERNALSYM SG_GET_NUM_WAITING}

{ Yields max scatter gather tablesize allowed by current host adapter }
  SG_GET_SG_TABLESIZE = $227F;  { 0 implies can't do scatter gather }
  {$EXTERNALSYM SG_GET_SG_TABLESIZE}

  SG_GET_VERSION_NUM = $2282; { Example: version 2.1.34 yields 20134 }
  {$EXTERNALSYM SG_GET_VERSION_NUM}

{ Returns -EBUSY if occupied. 3rd argument pointer to int (see next) }
  SG_SCSI_RESET = $2284;
  {$EXTERNALSYM SG_SCSI_RESET}
{ Associated values that can be given to SG_SCSI_RESET follow }
  SG_SCSI_RESET_NOTHING = 0;
  {$EXTERNALSYM SG_SCSI_RESET_NOTHING}
  SG_SCSI_RESET_DEVICE  = 1;
  {$EXTERNALSYM SG_SCSI_RESET_DEVICE}
  SG_SCSI_RESET_BUS     = 2;
  {$EXTERNALSYM SG_SCSI_RESET_BUS}
  SG_SCSI_RESET_HOST    = 3;
  {$EXTERNALSYM SG_SCSI_RESET_HOST}

{ synchronous SCSI command ioctl, (only in version 3 interface) }
  SG_IO = $2285;   { similar effect as write() followed by read() }
  {$EXTERNALSYM SG_IO}

  SG_GET_REQUEST_TABLE = $2286;   { yields table of active requests }
  {$EXTERNALSYM SG_GET_REQUEST_TABLE}

{ How to treat EINTR during SG_IO ioctl(), only in SG 3.x series }
  SG_SET_KEEP_ORPHAN = $2287; { 1 -> hold for read(), 0 -> drop (def) }
  {$EXTERNALSYM SG_SET_KEEP_ORPHAN}
  SG_GET_KEEP_ORPHAN = $2288;
  {$EXTERNALSYM SG_GET_KEEP_ORPHAN}


  SG_SCATTER_SZ = (8 * 4096);  { PAGE_SIZE not available to user }
  {$EXTERNALSYM SG_SCATTER_SZ}
{ Largest size (in bytes) a single scatter-gather list element can have.
   The value must be a power of 2 and <= (PAGE_SIZE * 32) [131072 bytes on
   i386]. The minimum value is PAGE_SIZE. If scatter-gather not supported
   by adapter then this value is the largest data block that can be
   read/written by a single scsi command. The user can find the value of
   PAGE_SIZE by calling getpagesize() defined in unistd.h . }

  SG_DEFAULT_RETRIES = 1;
  {$EXTERNALSYM SG_DEFAULT_RETRIES}

{ Defaults, commented if they differ from original sg driver }
  SG_DEF_FORCE_LOW_DMA = 0;  { was 1 -> memory below 16MB on i386 }
  {$EXTERNALSYM SG_DEF_FORCE_LOW_DMA}
  SG_DEF_FORCE_PACK_ID = 0;
  {$EXTERNALSYM SG_DEF_FORCE_PACK_ID}
  SG_DEF_KEEP_ORPHAN = 0;
  {$EXTERNALSYM SG_DEF_KEEP_ORPHAN}
  SG_DEF_RESERVED_SIZE = SG_SCATTER_SZ; { load time option }
  {$EXTERNALSYM SG_DEF_RESERVED_SIZE}

{ maximum outstanding requests, write() yields EDOM if exceeded }
  SG_MAX_QUEUE = 16;
  {$EXTERNALSYM SG_MAX_QUEUE}

  SG_BIG_BUFF = SG_DEF_RESERVED_SIZE;    { for backward compatibility }
  {$EXTERNALSYM SG_BIG_BUFF}

{ Alternate style type names, "..._t" variants preferred }
(*
typedef struct sg_io_hdr Sg_io_hdr;
typedef struct sg_io_vec Sg_io_vec;
typedef struct sg_scsi_id Sg_scsi_id;
typedef struct sg_req_info Sg_req_info;
*)

{ vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv }
{   The older SG interface based on the 'sg_header' structure follows.   }
{ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ }
const
  SG_MAX_SENSE = 16;   { this only applies to the sg_header interface }
  {$EXTERNALSYM SG_MAX_SENSE}

type
  sg_header = {packed} record
    { Length of incoming packet (including header).  }
    pack_len: Integer;
    { Maximal length of expected reply.  }
    reply_len: Integer;
    { Id number of packet.  }
    pack_id: Integer;
    { 0==ok, otherwise error number.  }
    result: Integer;

    __bitfield: Cardinal;
  (*
    { Force 12 byte command length for group 6 & 7 commands.  }
    unsigned int twelve_byte:1;
    { SCSI status from target.  }
    unsigned int target_status:5;
    { Host status (see "DID" codes).  }
    unsigned int host_status:8;
    { Driver status+suggestion.  }
    unsigned int driver_status:8;
    { Unused.  }
    unsigned int other_flags:10;
  *)

    { Output in 3 cases:
      when target_status is CHECK_CONDITION or
      when target_status is COMMAND_TERMINATED or
      when (driver_status & DRIVER_SENSE) is true.  }
    sense_buffer: packed array[0..SG_MAX_SENSE-1] of Byte;
  end;
  {$EXTERNALSYM sg_header}


{ IOCTLs: The following are not required (or ignored) when the sg_io_hdr_t
  interface is used. They are kept for backward compatibility with
  the original and version 2 drivers. }
const
  SG_SET_TIMEOUT = $2201;     { Set timeout; *(int *)arg==timeout.  }
  {$EXTERNALSYM SG_SET_TIMEOUT}
  SG_GET_TIMEOUT = $2202;     { Get timeout; return timeout.  }
  {$EXTERNALSYM SG_GET_TIMEOUT}

{ Get/set command queuing state per fd (default is SG_DEF_COMMAND_Q). }
  SG_GET_COMMAND_Q = $2270;   { Yields 0 (queuing off) or 1 (on).  }
  {$EXTERNALSYM SG_GET_COMMAND_Q}
  SG_SET_COMMAND_Q = $2271;   { Change queuing state with 0 or 1.  }
  {$EXTERNALSYM SG_SET_COMMAND_Q}

{ Turn on error sense trace (1..8), dump this device to log/console (9)
   or dump all sg device states ( >9 ) to log/console.  }
  SG_SET_DEBUG     = $227e;   { 0 -> turn off debug }
  {$EXTERNALSYM SG_SET_DEBUG}

  SG_NEXT_CMD_LEN  = $2283;   { Override SCSI command length with given
                                number on the next write() on this file
                                descriptor.  }
  {$EXTERNALSYM SG_NEXT_CMD_LEN}

{ Defaults, commented if they differ from original sg driver }
  SG_DEFAULT_TIMEOUT = (60*HZ); { HZ == 'jiffies in 1 second' }
  {$EXTERNALSYM SG_DEFAULT_TIMEOUT}
  SG_DEF_COMMAND_Q = 0;         { command queuing is always on when
                                  the new interface is used }
  {$EXTERNALSYM SG_DEF_COMMAND_Q}
  SG_DEF_UNDERRUN_FLAG = 0;
  {$EXTERNALSYM SG_DEF_UNDERRUN_FLAG}


// Translated from ttyent.h

const
  _PATH_TTYS    = '/etc/ttys';
  {$EXTERNALSYM _PATH_TTYS}

  _TTYS_OFF     = 'off';
  {$EXTERNALSYM _TTYS_OFF}
  _TTYS_ON      = 'on';
  {$EXTERNALSYM _TTYS_ON}
  _TTYS_SECURE  = 'secure';
  {$EXTERNALSYM _TTYS_SECURE}
  _TTYS_WINDOW  = 'window';
  {$EXTERNALSYM _TTYS_WINDOW}

const
  TTY_ON        = $01;  { enable logins (start ty_getty program) }
  {$EXTERNALSYM TTY_ON}
  TTY_SECURE    = $02;  { allow uid of 0 to login }
  {$EXTERNALSYM TTY_SECURE}

type
  ttyent = {packed} record
    ty_name: PChar;     { terminal device name }
    ty_getty: PChar;    { command to execute, usually getty }
    ty_type: PChar;     { terminal type for termcap }
    ty_status: Integer; { status flags }
    ty_window: PChar;   { command to start up window manager }
    ty_comment: PChar;  { comment field }
  end;
  {$EXTERNALSYM ttyent}
  TTtyEnt = ttyent;
  PTtyEnt = ^TTtyEnt;


function getttyent(): PTtyEnt; cdecl;
{$EXTERNALSYM getttyent}
function getttynam(__tty: PChar): PTtyEnt; cdecl;
{$EXTERNALSYM getttynam}
function setttyent(): Integer; cdecl;
{$EXTERNALSYM setttyent}
function endttyent(): Integer; cdecl;
{$EXTERNALSYM endttyent}


// Translated from sgtty.h

{ On some systems this type is not defined by <bits/ioctl-types.h>;
   in that case, the functions are just stubs that return ENOSYS.  }
type
  sgttyb = {packed} record
    // Opaque.
  end;
  {$EXTERNALSYM sgttyb}
  TSgTTyB = sgttyb;
  PSgTTyB = ^TSgTTyB;

{ Fill in *PARAMS with terminal parameters associated with FD.  }
function gtty(__fd: Integer; __params: PSgTTyB): Integer; cdecl;
{$EXTERNALSYM gtty}

{ Set the terminal parameters associated with FD to *PARAMS.  }
function stty(__fd: Integer; __params: PSgTTyB): Integer; cdecl;
{$EXTERNALSYM stty}


// Translated from search.h

{ Declarations for System V style searching functions. }

{ Prototype structure for a linked-list data structure.
   This is the type used by the `insque' and `remque' functions.  }

type
  PQElement = ^TQElement;
  qelem = {packed} record
    q_forw: PQElement;
    q_back: PQElement;
    q_data: array[0..0] of Byte;
  end;
  {$EXTERNALSYM qelem}
  TQElement = qelem;


{ Insert ELEM into a doubly-linked list, after PREV.  }
procedure insque(__elem: Pointer; __prev: Pointer); cdecl;
{$EXTERNALSYM insque}

{ Unlink ELEM from the doubly-linked list that it is in.  }
procedure remque(__elem: Pointer); cdecl;
{$EXTERNALSYM remque}


{ For use with hsearch(3).  }
(* These types are already defined elsewhere

typedef int (*__compar_fn_t) (__const void *, __const void * );
typedef __compar_fn_t comparison_fn_t;
*)

{ Action which shall be performed in the call to hsearch.  }
type
  hsearch_ACTION = (FIND, ENTER);
  {.$EXTERNALSYM ACTION} // Renamed to avoid serious namespace pollution

type
  hsearch_ENTRY = {packed} record
    key: PChar;
    data: Pointer;
  end;
  {.$EXTERNALSYM ENTRY} // Renamed to avoid serious namespace pollution
  THSearchEntry = hsearch_ENTRY;
  PHSearchEntry = ^THSearchEntry;

{ Opaque type for internal use.  }
  hsearch_ENTRY_opaque = {packed} record
  end;
  {.$EXTERNALSYM _ENTRY} // Renamed to avoid serious namespace pollution
  THSearchEntryOpaque = hsearch_ENTRY_opaque;
  PHSearchEntryOpaque = ^THSearchEntryOpaque;

{ Family of hash table handling functions.  The functions also
   have reentrant counterparts ending with _r.  The non-reentrant
   functions all work on a signle internal hashing table.  }

{ Search for entry matching ITEM.key in internal hash table.  If
   ACTION is `FIND' return found entry or signal error by returning
   NULL.  If ACTION is `ENTER' replace existing data (if any) with
   ITEM.data.  }
function hsearch(__item: THSearchEntry; __action: hsearch_ACTION): PHSearchEntry; cdecl;
{$EXTERNALSYM hsearch}

{ Create a new hashing table which will at most contain NEL elements.  }
function hcreate(__nel: size_t): Integer; cdecl;
{$EXTERNALSYM hcreate}

{ Destroy current internal hashing table.  }
procedure hdestroy(); cdecl;
{$EXTERNALSYM hdestroy}

{ Data type for reentrant functions.  }
type
  hsearch_data = {packed} record
    table: PHSearchEntryOpaque;
    size: Cardinal;
    filled: Cardinal;
  end;
  {$EXTERNALSYM hsearch_data}
  THSearchData = hsearch_data;
  PHSearchData = ^THSearchData;

{ Reentrant versions which can handle multiple hashing tables at the
   same time.  }
function hsearch_r(__item: THSearchEntry; __action: hsearch_ACTION;
  var __retval: PHSearchEntry; __htab: PHSearchData): Integer; cdecl;
{$EXTERNALSYM hsearch_r}
function hcreate_r(__nel: size_t; __htab: PHSearchData): Integer; cdecl;
{$EXTERNALSYM hcreate_r}
procedure hdestroy_r(__htab: PHSearchData); cdecl;
{$EXTERNALSYM hdestroy_r}


{ The tsearch routines are very interesting. They make many
   assumptions about the compiler.  It assumes that the first field
   in node must be the "key" field, which points to the datum.
   Everything depends on that.  }
{ For tsearch }
type
  tsearch_VISIT = (preorder, postorder, endorder, leaf);
  {.$EXTERNALSYM VISIT} // Renamed to avoid serious namespace pollution

{ Search for an entry matching the given KEY in the tree pointed to
   by *ROOTP and insert a new element if not found.  }
function tsearch(__key: Pointer; var __rootp: Pointer;
  __compar: __compar_fn_t): Pointer; cdecl;
{$EXTERNALSYM tsearch}

{ Search for an entry matching the given KEY in the tree pointed to
   by *ROOTP.  If no matching entry is available return NULL.  }
function tfind(__key: Pointer; var __rootp: Pointer;
  __compar: __compar_fn_t): Pointer; cdecl;
{$EXTERNALSYM tfind}

{ Remove the element matching KEY from the tree pointed to by *ROOTP.  }
function tdelete(__key: Pointer; var __rootp: Pointer;
  __compar: __compar_fn_t): Pointer; cdecl;
{$EXTERNALSYM tdelete}

type
  __action_fn_t = procedure(__nodep: Pointer; __value: tsearch_VISIT;
    __level: Integer); cdecl;
  {$EXTERNALSYM __action_fn_t}

{ Walk through the whole tree and call the ACTION callback for every node
   or leaf.  }
procedure twalk(__root: Pointer; __action: __action_fn_t); cdecl;
{$EXTERNALSYM twalk}

{ Callback type for function to free a tree node.  If the keys are atomic
   data this function should do nothing.  }
type
  __free_fn_t = procedure(__nodep: Pointer); cdecl;
  {$EXTERNALSYM __free_fn_t}

{ Destroy the whole tree, call FREEFCT for each node or leaf.  }
procedure tdestroy(__root: Pointer; __freefct: __free_fn_t); cdecl;
{$EXTERNALSYM tdestroy}


{ Perform linear search for KEY by comparing by COMPAR in an array
   [BASE,BASE+NMEMB*SIZE).  }
function lfind(__key: Pointer; __base: Pointer; __nmemb: Psize_t;
  __size: size_t; __compar: __compar_fn_t): Pointer; cdecl;
{$EXTERNALSYM lfind}

{ Perform linear search for KEY by comparing by COMPAR function in
   array [BASE,BASE+NMEMB*SIZE) and insert entry if not found.  }
function lsearch(__key: Pointer; __base: Pointer; __nmemb: Psize_t;
  __size: size_t; __compar: __compar_fn_t): Pointer; cdecl;
{$EXTERNALSYM lsearch}



const
  libcmodulename = 'libc.so.6';
  libcryptmodulename = 'libcrypt.so.1';
  libdlmodulename = 'libdl.so.2';
  libmmodulename = 'libm.so.6';
  libpthreadmodulename = 'libpthread.so.0';
  libresolvmodulename = 'libresolv.so.2';
  librtmodulename = 'librt.so.1';
  libutilmodulename = 'libutil.so.1';

implementation

function __errno_location;              external libcmodulename name '__errno_location';

function errno: Integer;
begin
  Result := __errno_location^;
end;

function asctime;                       external libcmodulename name 'asctime';
function asctime_r;                     external libcmodulename name 'asctime_r';
function clock;                         external libcmodulename name 'clock';
function ctime;                         external libcmodulename name 'ctime';
function ctime_r;                       external libcmodulename name 'ctime_r';
function difftime;                      external libcmodulename name 'difftime';
function dysize;                        external libcmodulename name 'dysize';
function getdate;                       external libcmodulename name 'getdate';
function getdate_r;                     external libcmodulename name 'getdate_r';
function gmtime;                        external libcmodulename name 'gmtime';
function gmtime_r;                      external libcmodulename name 'gmtime_r';
function localtime;                     external libcmodulename name 'localtime';
function localtime_r;                   external libcmodulename name 'localtime_r';
function mktime;                        external libcmodulename name 'mktime';
function nanosleep;                     external libcmodulename name 'nanosleep';
function clock_getres;                  external librtmodulename name 'clock_getres';
function clock_gettime;                 external librtmodulename name 'clock_gettime';
function clock_settime;                 external librtmodulename name 'clock_settime';
function clock_nanosleep;               external librtmodulename name 'clock_nanosleep';
function clock_getcpuclockid;           external librtmodulename name 'clock_getcpuclockid';
function timer_create(ClockID: clockid_t; var ev: sigevent; var TimerID: timer_t): Integer; external librtmodulename name 'timer_create';
function timer_create(ClockID: clockid_t; evp: PSigEvent; var TimerID: timer_t): Integer; external librtmodulename name 'timer_create';
function timer_delete;                  external librtmodulename name 'timer_delete';
function timer_settime;                 external librtmodulename name 'timer_settime';
function timer_gettime;                 external librtmodulename name 'timer_gettime';
function timer_getoverrun;              external librtmodulename name 'timer_getoverrun';
function stime;                         external libcmodulename name 'stime';
function strftime;                      external libcmodulename name 'strftime';
function strptime;                      external libcmodulename name 'strptime';
function __time;                        external libcmodulename name 'time';
function timegm;                        external libcmodulename name 'timegm';
function timelocal;                     external libcmodulename name 'timelocal';
procedure tzset;                        external libcmodulename name 'tzset';
function gettimeofday(var timeval: TTimeVal; var timezone: TTimeZone): Integer; external libcmodulename name 'gettimeofday';
function gettimeofday(var timeval: TTimeVal; timezone: PTimeZone): Integer; external libcmodulename name 'gettimeofday';
function settimeofday;                  external libcmodulename name 'settimeofday';
function adjtime(const delta: TTimeVal; var olddelta: TTimeVal): Integer; cdecl; external libcmodulename name 'adjtime';
function adjtime(const delta: TTimeVal; olddelta: PTimeVal): Integer; cdecl; external libcmodulename name 'adjtime';
function getitimer;                     external libcmodulename name 'getitimer';
function setitimer;                     external libcmodulename name 'setitimer';
function utimes(__file: PChar; __tvp: PTimeVal): Integer; external libcmodulename name 'utimes';
function utimes(__file: PChar; const AccessModTimes: TAccessModificationTimes): Integer; external libcmodulename name 'utimes';

function __adjtimex;                    external libcmodulename name '__adjtimex';
function adjtimex;                      external libcmodulename name 'adjtimex';
function ntp_gettime;                   external libcmodulename name 'ntp_gettime';
function ntp_adjtime;                   external libcmodulename name 'ntp_adjtime';

function times;                         external libcmodulename name 'times';

function clone;                         external libcmodulename name 'clone';

function sched_get_priority_max;        external libcmodulename name 'sched_get_priority_max';
function sched_get_priority_min;        external libcmodulename name 'sched_get_priority_min';
function sched_setparam;                external libcmodulename name 'sched_setparam';
function sched_getparam;                external libcmodulename name 'sched_getparam';
function sched_getscheduler;            external libcmodulename name 'sched_getscheduler';
function sched_rr_get_interval;         external libcmodulename name 'sched_rr_get_interval';
function sched_setscheduler;            external libcmodulename name 'sched_setscheduler';
function sched_yield;                   external libcmodulename name 'sched_yield';
function __sigaddset;                   external libcmodulename name '__sigaddset';
function __sigdelset;                   external libcmodulename name '__sigdelset';
function __sigismember;                 external libcmodulename name '__sigismember';
function __libc_current_sigrtmax;       external libcmodulename name '__libc_current_sigrtmax';
function __libc_current_sigrtmin;       external libcmodulename name '__libc_current_sigrtmin';
function sigaction;                     external libcmodulename name 'sigaction';
function __sigpause;                    external libcmodulename name '__sigpause';
function bsd_signal;                    external libcmodulename name 'bsd_signal';
function gsignal;                       external libcmodulename name 'gsignal';
function kill;                          external libcmodulename name 'kill';
function killpg;                        external libcmodulename name 'killpg';

procedure psignal;                      external libcmodulename name 'psignal';
function __raise;                       external libcmodulename name 'raise';
function sigaddset;                     external libcmodulename name 'sigaddset';
function sigaltstack;                   external libcmodulename name 'sigaltstack';
function sigandset;                     external libcmodulename name 'sigandset';
function sigdelset;                     external libcmodulename name 'sigdelset';
function sigemptyset;                   external libcmodulename name 'sigemptyset';
function sigfillset;                    external libcmodulename name 'sigfillset';
function sighold;                       external libcmodulename name 'sighold';
function sigignore;                     external libcmodulename name 'sigignore';
function siginterrupt;                  external libcmodulename name 'siginterrupt';
function sigisemptyset;                 external libcmodulename name 'sigisemptyset';
function sigismember;                   external libcmodulename name 'sigismember';
function signal;                        external libcmodulename name 'signal';
function sigorset;                      external libcmodulename name 'sigorset';
function sigpause;                      external libcmodulename name 'sigpause';
function sigblock;                      external libcmodulename name 'sigblock';
function sigsetmask;                    external libcmodulename name 'sigsetmask';
function siggetmask;                    external libcmodulename name 'siggetmask';
function sigpending;                    external libcmodulename name 'sigpending';
function sigprocmask;                   external libcmodulename name 'sigprocmask';
function sigqueue;                      external libcmodulename name 'sigqueue';
function sigvec(SigNum: Integer; PVector: PSigVec; POldVector: PSigVec): Integer; cdecl; external libcmodulename name 'sigvec';
function sigvec(SigNum: Integer; const Vector: TSigVec; OldVector: PSigVec): Integer; cdecl; external libcmodulename name 'sigvec';
function sigreturn;                     external libcmodulename name 'sigreturn';
function sigrelse;                      external libcmodulename name 'sigrelse';
function sigset;                        external libcmodulename name 'sigset';
function sigstack;                      external libcmodulename name 'sigstack';
function sigsuspend;                    external libcmodulename name 'sigsuspend';
function sigtimedwait;                  external libcmodulename name 'sigtimedwait';
function sigwait;                       external libcmodulename name 'sigwait';
function sigwaitinfo;                   external libcmodulename name 'sigwaitinfo';
function ssignal;                       external libcmodulename name 'ssignal';
function sysv_signal;                   external libcmodulename name 'sysv_signal';

procedure __pthread_initialize;         external libpthreadmodulename name '__pthread_initialize';
procedure _pthread_cleanup_pop;         external libpthreadmodulename name '_pthread_cleanup_pop';
procedure _pthread_cleanup_pop_restore; external libpthreadmodulename name '_pthread_cleanup_pop_restore';
procedure _pthread_cleanup_push;        external libpthreadmodulename name '_pthread_cleanup_push';
procedure _pthread_cleanup_push_defer;  external libpthreadmodulename name '_pthread_cleanup_push_defer';
function pthread_kill;                  external libpthreadmodulename name 'pthread_kill';
function pthread_sigmask;               external libpthreadmodulename name 'pthread_sigmask';
function pthread_getcpuclockid;         external libpthreadmodulename name 'pthread_getcpuclockid';
function pthread_atfork;                external libpthreadmodulename name 'pthread_atfork';
function pthread_attr_destroy;          external libpthreadmodulename name 'pthread_attr_destroy';
function pthread_attr_getdetachstate;   external libpthreadmodulename name 'pthread_attr_getdetachstate';
function pthread_attr_getguardsize;     external libpthreadmodulename name 'pthread_attr_getguardsize';
function pthread_attr_getinheritsched;  external libpthreadmodulename name 'pthread_attr_getinheritsched';
function pthread_attr_getschedparam;    external libpthreadmodulename name 'pthread_attr_getschedparam';
function pthread_attr_getschedpolicy;   external libpthreadmodulename name 'pthread_attr_getschedpolicy';
function pthread_attr_getscope;         external libpthreadmodulename name 'pthread_attr_getscope';
function pthread_attr_getstackaddr;     external libpthreadmodulename name 'pthread_attr_getstackaddr';
function pthread_attr_getstacksize;     external libpthreadmodulename name 'pthread_attr_getstacksize';
function pthread_attr_init;             external libpthreadmodulename name 'pthread_attr_init';
function pthread_attr_setdetachstate;   external libpthreadmodulename name 'pthread_attr_setdetachstate';
function pthread_attr_setguardsize;     external libpthreadmodulename name 'pthread_attr_setguardsize';
function pthread_attr_setinheritsched;  external libpthreadmodulename name 'pthread_attr_setinheritsched';
function pthread_attr_setschedparam;    external libpthreadmodulename name 'pthread_attr_setschedparam';
function pthread_attr_setschedpolicy;   external libpthreadmodulename name 'pthread_attr_setschedpolicy';
function pthread_attr_setscope;         external libpthreadmodulename name 'pthread_attr_setscope';
function pthread_attr_setstackaddr;     external libpthreadmodulename name 'pthread_attr_setstackaddr';
function pthread_attr_setstack;         external libpthreadmodulename name 'pthread_attr_setstack';
function pthread_attr_getstack;         external libpthreadmodulename name 'pthread_attr_getstack';
function pthread_attr_setstacksize;     external libpthreadmodulename name 'pthread_attr_setstacksize';
function pthread_cancel;                external libpthreadmodulename name 'pthread_cancel';
function pthread_cond_broadcast;        external libpthreadmodulename name 'pthread_cond_broadcast';
function pthread_cond_destroy;          external libpthreadmodulename name 'pthread_cond_destroy';
function pthread_cond_init(var Cond: TCondVar; var CondAttr: TPthreadCondattr): Integer; external libpthreadmodulename name 'pthread_cond_init';
function pthread_cond_init(var Cond: TCondVar; CondAttr: PPthreadCondattr): Integer; external libpthreadmodulename name 'pthread_cond_init';
function pthread_cond_signal;           external libpthreadmodulename name 'pthread_cond_signal';
(* We provide a wrapper around pthread_cond_timedwait
function pthread_cond_timedwait;        external libpthreadmodulename name 'pthread_cond_timedwait';
*)
function pthread_cond_wait;             external libpthreadmodulename name 'pthread_cond_wait';
function pthread_condattr_destroy;      external libpthreadmodulename name 'pthread_condattr_destroy';
function pthread_condattr_getpshared;   external libpthreadmodulename name 'pthread_condattr_getpshared';
function pthread_condattr_setpshared;   external libpthreadmodulename name 'pthread_condattr_setpshared';
function pthread_condattr_init;         external libpthreadmodulename name 'pthread_condattr_init';
function pthread_create;                external libpthreadmodulename name 'pthread_create';
function pthread_detach;                external libpthreadmodulename name 'pthread_detach';
function pthread_equal;                 external libpthreadmodulename name 'pthread_equal';
procedure pthread_exit;                 external libpthreadmodulename name 'pthread_exit';
function pthread_getconcurrency;        external libpthreadmodulename name 'pthread_getconcurrency';
function pthread_getschedparam;         external libpthreadmodulename name 'pthread_getschedparam';
function pthread_getspecific;           external libpthreadmodulename name 'pthread_getspecific';
function pthread_join;                  external libpthreadmodulename name 'pthread_join';
function pthread_spin_init;             external libpthreadmodulename name 'pthread_spin_init';
function pthread_spin_destroy;          external libpthreadmodulename name 'pthread_spin_destroy';
function pthread_spin_lock;             external libpthreadmodulename name 'pthread_spin_lock';
function pthread_spin_trylock;          external libpthreadmodulename name 'pthread_spin_trylock';
function pthread_spin_unlock;           external libpthreadmodulename name 'pthread_spin_unlock';
function pthread_barrier_init(var Barrier: TPthreadBarrier; var Attr: TPthreadBarrierAttribute; Count: Cardinal): Integer; external libpthreadmodulename name 'pthread_barrier_init';
function pthread_barrier_init(var Barrier: TPthreadBarrier; Attr: PPthreadBarrierAttribute; Count: Cardinal): Integer; external libpthreadmodulename name 'pthread_barrier_init';
function pthread_barrier_destroy;       external libpthreadmodulename name 'pthread_barrier_destroy';
function pthread_barrierattr_init;      external libpthreadmodulename name 'pthread_barrierattr_init';
function pthread_barrierattr_destroy;   external libpthreadmodulename name 'pthread_barrierattr_destroy';
function pthread_barrierattr_getpshared;external libpthreadmodulename name 'pthread_barrierattr_getpshared';
function pthread_barrierattr_setpshared;external libpthreadmodulename name 'pthread_barrierattr_setpshared';
function pthread_barrier_wait;          external libpthreadmodulename name 'pthread_barrier_wait';
function pthread_key_create;            external libpthreadmodulename name 'pthread_key_create';
function pthread_key_delete;            external libpthreadmodulename name 'pthread_key_delete';
procedure pthread_kill_other_threads_np;external libpthreadmodulename name 'pthread_kill_other_threads_np';
function pthread_mutex_destroy;         external libpthreadmodulename name 'pthread_mutex_destroy';
function pthread_mutex_init(var Mutex: TRTLCriticalSection; var Attr: TMutexAttribute): Integer; external libpthreadmodulename name 'pthread_mutex_init';
function pthread_mutex_init(var Mutex: TRTLCriticalSection; Attr: PMutexAttribute): Integer; external libpthreadmodulename name 'pthread_mutex_init';
function pthread_mutex_lock;            external libpthreadmodulename name 'pthread_mutex_lock';
function pthread_mutex_timedlock;       external libpthreadmodulename name 'pthread_mutex_timedlock';
function pthread_mutex_trylock;         external libpthreadmodulename name 'pthread_mutex_trylock';
function pthread_mutex_unlock;          external libpthreadmodulename name 'pthread_mutex_unlock';
function pthread_mutexattr_destroy;     external libpthreadmodulename name 'pthread_mutexattr_destroy';
function pthread_mutexattr_getpshared;  external libpthreadmodulename name 'pthread_mutexattr_getpshared';
function pthread_mutexattr_setpshared;  external libpthreadmodulename name 'pthread_mutexattr_setpshared';
function pthread_mutexattr_gettype;     external libpthreadmodulename name 'pthread_mutexattr_gettype';
function pthread_mutexattr_init;        external libpthreadmodulename name 'pthread_mutexattr_init';
function pthread_mutexattr_settype;     external libpthreadmodulename name 'pthread_mutexattr_settype';
function pthread_once;                  external libpthreadmodulename name 'pthread_once';
function pthread_rwlock_destroy;        external libpthreadmodulename name 'pthread_rwlock_destroy';
function pthread_rwlock_init;           external libpthreadmodulename name 'pthread_rwlock_init';
function pthread_rwlock_rdlock;         external libpthreadmodulename name 'pthread_rwlock_rdlock';
function pthread_rwlock_tryrdlock;      external libpthreadmodulename name 'pthread_rwlock_tryrdlock';
function pthread_rwlock_timedrdlock;    external libpthreadmodulename name 'pthread_rwlock_timedrdlock';
function pthread_rwlock_trywrlock;      external libpthreadmodulename name 'pthread_rwlock_trywrlock';
function pthread_rwlock_timedwrlock;    external libpthreadmodulename name 'pthread_rwlock_timedwrlock';
function pthread_rwlock_unlock;         external libpthreadmodulename name 'pthread_rwlock_unlock';
function pthread_rwlock_wrlock;         external libpthreadmodulename name 'pthread_rwlock_wrlock';
function pthread_rwlockattr_destroy;    external libpthreadmodulename name 'pthread_rwlockattr_destroy';
function pthread_rwlockattr_getkind_np; external libpthreadmodulename name 'pthread_rwlockattr_getkind_np';
function pthread_rwlockattr_getpshared; external libpthreadmodulename name 'pthread_rwlockattr_getpshared';
function pthread_rwlockattr_init;       external libpthreadmodulename name 'pthread_rwlockattr_init';
function pthread_rwlockattr_setkind_np; external libpthreadmodulename name 'pthread_rwlockattr_setkind_np';
function pthread_rwlockattr_setpshared; external libpthreadmodulename name 'pthread_rwlockattr_setpshared';
function pthread_self;                  external libpthreadmodulename name 'pthread_self';
function GetCurrentThreadID;            external libpthreadmodulename name 'pthread_self';
function pthread_setcancelstate;        external libpthreadmodulename name 'pthread_setcancelstate';
function pthread_setcanceltype;         external libpthreadmodulename name 'pthread_setcanceltype';
function pthread_setconcurrency;        external libpthreadmodulename name 'pthread_setconcurrency';
function pthread_yield;                 external libpthreadmodulename name 'pthread_yield';
function pthread_setschedparam;         external libpthreadmodulename name 'pthread_setschedparam';
function pthread_setspecific;           external libpthreadmodulename name 'pthread_setspecific';
procedure pthread_testcancel;           external libpthreadmodulename name 'pthread_testcancel';
function sem_init;                      external libpthreadmodulename name 'sem_init';
function sem_destroy;                   external libpthreadmodulename name 'sem_destroy';
function sem_open;                      external libpthreadmodulename name 'sem_open';
function sem_close;                     external libpthreadmodulename name 'sem_close';
function sem_unlink;                    external libpthreadmodulename name 'sem_unlink';
function sem_wait;                      external libpthreadmodulename name 'sem_wait';
function sem_timedwait;                 external libpthreadmodulename name 'sem_timedwait';
function sem_trywait;                   external libpthreadmodulename name 'sem_trywait';
function sem_post;                      external libpthreadmodulename name 'sem_post';
function sem_getvalue;                  external libpthreadmodulename name 'sem_getvalue';

function posix_spawn;                   external libcmodulename name 'posix_spawn';
function posix_spawnp;                  external libcmodulename name 'posix_spawnp';
function posix_spawnattr_init;          external libcmodulename name 'posix_spawnattr_init';
function posix_spawnattr_destroy;       external libcmodulename name 'posix_spawnattr_destroy';
function posix_spawnattr_getsigdefault; external libcmodulename name 'posix_spawnattr_getsigdefault';
function posix_spawnattr_setsigdefault; external libcmodulename name 'posix_spawnattr_setsigdefault';
function posix_spawnattr_getsigmask;    external libcmodulename name 'posix_spawnattr_getsigmask';
function posix_spawnattr_setsigmask;    external libcmodulename name 'posix_spawnattr_setsigmask';
function posix_spawnattr_getflags;      external libcmodulename name 'posix_spawnattr_getflags';
function posix_spawnattr_setflags;      external libcmodulename name 'posix_spawnattr_setflags';
function posix_spawnattr_getpgroup;     external libcmodulename name 'posix_spawnattr_getpgroup';
function posix_spawnattr_setpgroup;     external libcmodulename name 'posix_spawnattr_setpgroup';
function posix_spawnattr_getschedpolicy;external libcmodulename name 'posix_spawnattr_getschedpolicy';
function posix_spawnattr_setschedpolicy;external libcmodulename name 'posix_spawnattr_setschedpolicy';
function posix_spawnattr_getschedparam; external libcmodulename name 'posix_spawnattr_getschedparam';
function posix_spawnattr_setschedparam; external libcmodulename name 'posix_spawnattr_setschedparam';
function posix_spawn_file_actions_init; external libcmodulename name 'posix_spawn_file_actions_init';
function posix_spawn_file_actions_destroy;external libcmodulename name 'posix_spawn_file_actions_destroy';
function posix_spawn_file_actions_addopen;external libcmodulename name 'posix_spawn_file_actions_addopen';
function posix_spawn_file_actions_addclose;external libcmodulename name 'posix_spawn_file_actions_addclose';
function posix_spawn_file_actions_adddup2;external libcmodulename name 'posix_spawn_file_actions_adddup2';

function fcntl(Handle: Integer; Command: Integer; var Lock: TFlock): Integer; external libcmodulename name 'fcntl';
function fcntl(Handle: Integer; Command: Integer; Arg: Longint): Integer; external libcmodulename name 'fcntl';
function fcntl(Handle: Integer; Command: Integer): Integer; external libcmodulename name 'fcntl';
function open;                          external libcmodulename name 'open';
function open64;                        external libcmodulename name 'open64';
function creat;                         external libcmodulename name 'creat';
function creat64;                       external libcmodulename name 'creat64';
function posix_fadvise;                 external libcmodulename name 'posix_fadvise';
function posix_fadvise64;               external libcmodulename name 'posix_fadvise64';
function posix_fallocate;               external libcmodulename name 'posix_fallocate';
function posix_fallocate64;             external libcmodulename name 'posix_fallocate64';

function __flock;                       external libcmodulename name 'flock';

function alphasort;                     external libcmodulename name 'alphasort';
function alphasort64;                   external libcmodulename name 'alphasort64';
function closedir;                      external libcmodulename name 'closedir';
function dirfd;                         external libcmodulename name 'dirfd';
function getdirentries;                 external libcmodulename name 'getdirentries';
function getdirentries64;               external libcmodulename name 'getdirentries64';
function opendir;                       external libcmodulename name 'opendir';
function readdir;                       external libcmodulename name 'readdir';
function readdir_r;                     external libcmodulename name 'readdir_r';
function readdir64;                     external libcmodulename name 'readdir64';
function readdir64_r;                   external libcmodulename name 'readdir64_r';
procedure rewinddir;                    external libcmodulename name 'rewinddir';
function scandir;                       external libcmodulename name 'scandir';
function scandir64;                     external libcmodulename name 'scandir64';
procedure seekdir;                      external libcmodulename name 'seekdir';
function telldir;                       external libcmodulename name 'telldir';
function versionsort;                   external libcmodulename name 'versionsort';
function versionsort64;                 external libcmodulename name 'versionsort64';

function __fxstat;                      external libcmodulename name '__fxstat';
function __fxstat64;                    external libcmodulename name '__fxstat64';
function __lxstat;                      external libcmodulename name '__lxstat';
function __lxstat64;                    external libcmodulename name '__lxstat64';
function __xmknod;                      external libcmodulename name '__xmknod';
function __xstat;                       external libcmodulename name '__xstat';
function __xstat64;                     external libcmodulename name '__xstat64';
function chmod;                         external libcmodulename name 'chmod';
function fchmod;                        external libcmodulename name 'fchmod';
function fstat64;                       external libcmodulename name '__fxstat64';
function lstat64;                       external libcmodulename name '__lxstat64';
function __mkdir;                       external libcmodulename name 'mkdir';
function mkfifo;                        external libcmodulename name 'mkfifo';
function stat64;                        external libcmodulename name '__xstat64';
function umask;                         external libcmodulename name 'umask';

function fnmatch;                       external libcmodulename name 'fnmatch';

procedure endfsent;                     external libcmodulename name 'endfsent';
function getfsent;                      external libcmodulename name 'getfsent';
function getfsfile;                     external libcmodulename name 'getfsfile';
function getfsspec;                     external libcmodulename name 'getfsspec';
function setfsent;                      external libcmodulename name 'setfsent';

function setmntent;                     external libcmodulename name 'setmntent';
function getmntent;                     external libcmodulename name 'getmntent';
function getmntent_r;                   external libcmodulename name 'getmntent_r';
function addmntent;                     external libcmodulename name 'addmntent';
function endmntent;                     external libcmodulename name 'endmntent';
function hasmntopt;                     external libcmodulename name 'hasmntopt';

function cfgetospeed;                   external libcmodulename name 'cfgetospeed';
function cfgetispeed;                   external libcmodulename name 'cfgetispeed';
function cfsetospeed;                   external libcmodulename name 'cfsetospeed';
function cfsetispeed;                   external libcmodulename name 'cfsetispeed';
function cfsetspeed;                    external libcmodulename name 'cfsetspeed';
function tcgetattr;                     external libcmodulename name 'tcgetattr';
function tcsetattr;                     external libcmodulename name 'tcsetattr';
procedure cfmakeraw;                    external libcmodulename name 'cfmakeraw';
function tcsendbreak;                   external libcmodulename name 'tcsendbreak';
function tcdrain;                       external libcmodulename name 'tcdrain';
function tcflush;                       external libcmodulename name 'tcflush';
function tcflow;                        external libcmodulename name 'tcflow';
function tcgetsid;                      external libcmodulename name 'tcgetsid';

function ioctl;                         external libcmodulename name 'ioctl';

(* Declared as a local symbol only
procedure _IO_cookie_init;              external libcmodulename name '_IO_cookie_init';
*)
function __overflow;                    external libcmodulename name '__overflow';
function __uflow;                       external libcmodulename name '__uflow';
function __underflow;                   external libcmodulename name '__underflow';
function __wunderflow;                  external libcmodulename name '__wunderflow';
function __wuflow;                      external libcmodulename name '__wuflow';
function __woverflow;                   external libcmodulename name '__woverflow';
function _IO_feof;                      external libcmodulename name '_IO_feof';
function _IO_ferror;                    external libcmodulename name '_IO_ferror';
procedure _IO_flockfile;                external libcmodulename name '_IO_flockfile';
procedure _IO_free_backup_area;         external libcmodulename name '_IO_free_backup_area';
(* Declared as a local symbol only
function _IO_getwc;                     external libcmodulename name '_IO_getwc';
function _IO_putwc;                     external libcmodulename name '_IO_putwc';
function _IO_fwide;                     external libcmodulename name '_IO_fwide';
*)
(* Declared as a local symbol only
function _IO_vfwscanf;                  external libcmodulename name '_IO_vfwscanf';
function _IO_vfwprintf;                 external libcmodulename name '_IO_vfwprintf';
function _IO_wpadn;                     external libcmodulename name '_IO_wpadn';
*)
procedure _IO_free_wbackup_area;        external libcmodulename name '_IO_free_wbackup_area';
function _IO_ftrylockfile;              external libcmodulename name '_IO_ftrylockfile';
procedure _IO_funlockfile;              external libcmodulename name '_IO_funlockfile';
function _IO_getc;                      external libcmodulename name '_IO_getc';
function _IO_padn;                      external libcmodulename name '_IO_padn';
function _IO_peekc_locked;              external libcmodulename name '_IO_peekc_locked';
function _IO_putc;                      external libcmodulename name '_IO_putc';
function _IO_seekoff;                   external libcmodulename name '_IO_seekoff';
function _IO_seekpos;                   external libcmodulename name '_IO_seekpos';
function _IO_sgetn;                     external libcmodulename name '_IO_sgetn';
function _IO_vfprintf;                  external libcmodulename name '_IO_vfprintf';
function _IO_vfscanf;                   external libcmodulename name '_IO_vfscanf';


procedure clearerr;                     external libcmodulename name 'clearerr';
procedure clearerr_unlocked;            external libcmodulename name 'clearerr_unlocked';
function ctermid;                       external libcmodulename name 'ctermid';
function cuserid;                       external libcmodulename name 'cuserid';
function fclose;                        external libcmodulename name 'fclose';
function fcloseall;                     external libcmodulename name 'fcloseall';
function fdopen;                        external libcmodulename name 'fdopen';
function feof;                          external libcmodulename name 'feof';
function feof_unlocked;                 external libcmodulename name 'feof_unlocked';
function ferror;                        external libcmodulename name 'ferror';
function ferror_unlocked;               external libcmodulename name 'ferror_unlocked';
function fflush;                        external libcmodulename name 'fflush';
function fflush_unlocked;               external libcmodulename name 'fflush_unlocked';
function fgetc_unlocked;                external libcmodulename name 'fgetc_unlocked';
function fgetpos;                       external libcmodulename name 'fgetpos';
function fgetpos64;                     external libcmodulename name 'fgetpos64';
function fgets;                         external libcmodulename name 'fgets';
function fgets_unlocked;                external libcmodulename name 'fgets_unlocked';
function fileno;                        external libcmodulename name 'fileno';
function fileno_unlocked;               external libcmodulename name 'fileno_unlocked';
procedure flockfile;                    external libcmodulename name 'flockfile';
function fopen;                         external libcmodulename name 'fopen';
function fopen64;                       external libcmodulename name 'fopen64';
function fopencookie;                   external libcmodulename name 'fopencookie';
function fmemopen;                      external libcmodulename name 'fmemopen';
function fputc;                         external libcmodulename name 'fputc';
function fputc_unlocked;                external libcmodulename name 'fputc_unlocked';
function fputs;                         external libcmodulename name 'fputs';
function fputs_unlocked;                external libcmodulename name 'fputs_unlocked';
function fread;                         external libcmodulename name 'fread';
function fread_unlocked;                external libcmodulename name 'fread_unlocked';
function freopen;                       external libcmodulename name 'freopen';
function freopen64;                     external libcmodulename name 'freopen64';
function fseek;                         external libcmodulename name 'fseek';
function fseeko;                        external libcmodulename name 'fseeko';
function fseeko64;                      external libcmodulename name 'fseeko64';
function fsetpos;                       external libcmodulename name 'fsetpos';
function fsetpos64;                     external libcmodulename name 'fsetpos64';
function ftell;                         external libcmodulename name 'ftell';
function ftello;                        external libcmodulename name 'ftello';
function ftello64;                      external libcmodulename name 'ftello64';
function ftrylockfile;                  external libcmodulename name 'ftrylockfile';
procedure funlockfile;                  external libcmodulename name 'funlockfile';
function __fbufsize;                    external libcmodulename name '__fbufsize';
function __freading;                    external libcmodulename name '__freading';
function __fwriting;                    external libcmodulename name '__fwriting';
function __freadable;                   external libcmodulename name '__freadable';
function __fwritable;                   external libcmodulename name '__fwritable';
function __flbf;                        external libcmodulename name '__flbf';
procedure __fpurge;                     external libcmodulename name '__fpurge';
function __fpending;                    external libcmodulename name '__fpending';
procedure _flushlbf;                    external libcmodulename name '_flushlbf';
function __fsetlocking;                 external libcmodulename name '__fsetlocking';
function fwrite;                        external libcmodulename name 'fwrite';
function fwrite_unlocked;               external libcmodulename name 'fwrite_unlocked';
function __vsnprintf;                   external libcmodulename name '__vsnprintf';
function vsnprintf;                     external libcmodulename name 'vsnprintf';
function vasprintf;                     external libcmodulename name 'vasprintf';
function __asprintf;                    external libcmodulename name '__asprintf';
function asprintf;                      external libcmodulename name 'asprintf';
function vdprintf;                      external libcmodulename name 'vdprintf';
function dprintf;                       external libcmodulename name 'dprintf';
function fscanf;                        external libcmodulename name 'fscanf';
function scanf;                         external libcmodulename name 'scanf';
function sscanf;                        external libcmodulename name 'sscanf';
function vfscanf;                       external libcmodulename name 'vfscanf';
function vscanf;                        external libcmodulename name 'vscanf';
function vsscanf;                       external libcmodulename name 'vsscanf';
function getc;                          external libcmodulename name 'getc';
function fgetc;                         external libcmodulename name 'fgetc';
function getc_unlocked;                 external libcmodulename name 'getc_unlocked';
function getchar;                       external libcmodulename name 'getchar';
function getchar_unlocked;              external libcmodulename name 'getchar_unlocked';
function getdelim;                      external libcmodulename name 'getdelim';
function getline;                       external libcmodulename name 'getline';
function gets;                          external libcmodulename name 'gets';
function getw;                          external libcmodulename name 'getw';
function open_memstream;                external libcmodulename name 'open_memstream';
function pclose;                        external libcmodulename name 'pclose';
procedure perror;                       external libcmodulename name 'perror';
function popen;                         external libcmodulename name 'popen';
function putc;                          external libcmodulename name 'putc';
function putc_unlocked;                 external libcmodulename name 'putc_unlocked';
function putchar;                       external libcmodulename name 'putchar';
function putchar_unlocked;              external libcmodulename name 'putchar_unlocked';
function puts;                          external libcmodulename name 'puts';
function putw;                          external libcmodulename name 'putw';
function remove;                        external libcmodulename name 'remove';
function __rename;                      external libcmodulename name 'rename';
procedure rewind;                       external libcmodulename name 'rewind';
procedure setbuf;                       external libcmodulename name 'setbuf';
function fprintf;                       external libcmodulename name 'fprintf';
function printf;                        external libcmodulename name 'printf';
function sprintf;                       external libcmodulename name 'sprintf';
function setvbuf;                       external libcmodulename name 'setvbuf';
procedure setbuffer;                    external libcmodulename name 'setbuffer';
procedure setlinebuf;                   external libcmodulename name 'setlinebuf';
function tempnam;                       external libcmodulename name 'tempnam';
function tmpfile;                       external libcmodulename name 'tmpfile';
function tmpfile64;                     external libcmodulename name 'tmpfile64';
function tmpnam;                        external libcmodulename name 'tmpnam';
function tmpnam_r;                      external libcmodulename name 'tmpnam_r';
function ungetc;                        external libcmodulename name 'ungetc';
function vfprintf;                      external libcmodulename name 'vfprintf';
function vprintf;                       external libcmodulename name 'vprintf';
function vsprintf;                      external libcmodulename name 'vsprintf';
function snprintf;                      external libcmodulename name 'snprintf';

function __close;                       external libcmodulename name '__close';
function lseek;                         external libcmodulename name 'lseek';
function __lseek;                       external libcmodulename name '__lseek';
function lseek64;                       external libcmodulename name 'lseek64';
(*
function __lseek64;                     external libcmodulename name '__lseek64';
*)
function pread64;                       external libcmodulename name 'pread64';
function __pread64;                     external libcmodulename name '__pread64';
function pwrite64;                      external libcmodulename name 'pwrite64';
function __pwrite64;                    external libcmodulename name '__pwrite64';
function __read;                        external libcmodulename name '__read';
function __write;                       external libcmodulename name '__write';
function pread;                         external libcmodulename name 'pread';
function pwrite;                        external libcmodulename name 'pwrite';
function access;                        external libcmodulename name 'access';
function acct;                          external libcmodulename name 'acct';
function alarm;                         external libcmodulename name 'alarm';
function brk;                           external libcmodulename name 'brk';
function __chdir;                       external libcmodulename name 'chdir';
function chown;                         external libcmodulename name 'chown';
function chroot;                        external libcmodulename name 'chroot';
function confstr;                       external libcmodulename name 'confstr';

function crypt;                         external libcryptmodulename name 'crypt';
procedure encrypt;                      external libcryptmodulename name 'encrypt';
procedure setkey;                       external libcryptmodulename name 'setkey';

function daemon;                        external libcmodulename name 'daemon';
function dup;                           external libcmodulename name 'dup';
function dup2;                          external libcmodulename name 'dup2';
procedure endusershell;                 external libcmodulename name 'endusershell';
function euidaccess;                    external libcmodulename name 'euidaccess';
function execv;                         external libcmodulename name 'execv';
function execle;                        external libcmodulename name 'execle';
function execl;                         external libcmodulename name 'execl';
function execve;                        external libcmodulename name 'execve';
function execvp;                        external libcmodulename name 'execvp';
function execlp;                        external libcmodulename name 'execlp';
function fchdir;                        external libcmodulename name 'fchdir';
function fchown;                        external libcmodulename name 'fchown';
function fdatasync;                     external libcmodulename name 'fdatasync';
function fexecve;                       external libcmodulename name 'fexecve';
function fork;                          external libcmodulename name 'fork';
function fpathconf;                     external libcmodulename name 'fpathconf';
function fsync;                         external libcmodulename name 'fsync';
function ftruncate;                     external libcmodulename name 'ftruncate';
function ftruncate64;                   external libcmodulename name 'ftruncate64';
function get_current_dir_name;          external libcmodulename name 'get_current_dir_name';
function getcwd;                        external libcmodulename name 'getcwd';
function getdomainname;                 external libcmodulename name 'getdomainname';
function getdtablesize;                 external libcmodulename name 'getdtablesize';
function getegid;                       external libcmodulename name 'getegid';
function geteuid;                       external libcmodulename name 'geteuid';
function getgid;                        external libcmodulename name 'getgid';
function getgroups;                     external libcmodulename name 'getgroups';
function gethostid;                     external libcmodulename name 'gethostid';
function gethostname;                   external libcmodulename name 'gethostname';
function getlogin;                      external libcmodulename name 'getlogin';
function getlogin_r;                    external libcmodulename name 'getlogin_r';
function getpagesize;                   external libcmodulename name 'getpagesize';
function getpass;                       external libcmodulename name 'getpass';
function __getpgid;                     external libcmodulename name '__getpgid';
function getpgid;                       external libcmodulename name 'getpgid';
function getpgrp;                       external libcmodulename name 'getpgrp';
function getpid;                        external libcmodulename name 'getpid';
function getppid;                       external libcmodulename name 'getppid';
function getsid;                        external libcmodulename name 'getsid';
function getuid;                        external libcmodulename name 'getuid';
function getusershell;                  external libcmodulename name 'getusershell';
function getwd;                         external libcmodulename name 'getwd';
function group_member;                  external libcmodulename name 'group_member';
function isatty;                        external libcmodulename name 'isatty';
function lchown;                        external libcmodulename name 'lchown';
function link;                          external libcmodulename name 'link';
function lockf;                         external libcmodulename name 'lockf';
function lockf64;                       external libcmodulename name 'lockf64';
function nice;                          external libcmodulename name 'nice';
function pathconf;                      external libcmodulename name 'pathconf';
function pause;                         external libcmodulename name 'pause';
function pipe(PipeDes: PInteger): Integer;  external libcmodulename name 'pipe';
function pipe(var PipeDes: TPipeDescriptors): Integer; external libcmodulename name 'pipe';
function profil;                        external libcmodulename name 'profil';
function readlink;                      external libcmodulename name 'readlink';
function revoke;                        external libcmodulename name 'revoke';
function __rmdir;                       external libcmodulename name 'rmdir';
function sbrk;                          external libcmodulename name 'sbrk';
function setdomainname;                 external libcmodulename name 'setdomainname';
function setegid;                       external libcmodulename name 'setegid';
function seteuid;                       external libcmodulename name 'seteuid';
function setgid;                        external libcmodulename name 'setgid';
function sethostid;                     external libcmodulename name 'sethostid';
function sethostname;                   external libcmodulename name 'sethostname';
function setlogin;                      external libcmodulename name 'setlogin';
function setpgid;                       external libcmodulename name 'setpgid';
function setpgrp;                       external libcmodulename name 'setpgrp';
function setregid;                      external libcmodulename name 'setregid';
function setreuid;                      external libcmodulename name 'setreuid';
function setsid;                        external libcmodulename name 'setsid';
function setuid;                        external libcmodulename name 'setuid';
procedure setusershell;                 external libcmodulename name 'setusershell';
function __sleep;                       external libcmodulename name 'sleep';
procedure swab;                         external libcmodulename name 'swab';
function symlink;                       external libcmodulename name 'symlink';
function sync;                          external libcmodulename name 'sync';
function syscall;                       external libcmodulename name 'syscall';
function sysconf;                       external libcmodulename name 'sysconf';
function tcgetpgrp;                     external libcmodulename name 'tcgetpgrp';
function tcsetpgrp;                     external libcmodulename name 'tcsetpgrp';
function __truncate;                    external libcmodulename name 'truncate';
function truncate64;                    external libcmodulename name 'truncate64';
function ttyname;                       external libcmodulename name 'ttyname';
function ttyname_r;                     external libcmodulename name 'ttyname_r';
function ttyslot;                       external libcmodulename name 'ttyslot';
function ualarm;                        external libcmodulename name 'ualarm';
function unlink;                        external libcmodulename name 'unlink';
procedure usleep;                       external libcmodulename name 'usleep';
function vfork;                         external libcmodulename name 'vfork';
function vhangup;                       external libcmodulename name 'vhangup';

function __strcasecmp_l;                external libcmodulename name '__strcasecmp_l';
function __strcoll_l;                   external libcmodulename name '__strcoll_l';
function __strncasecmp_l;               external libcmodulename name '__strncasecmp_l';
function __strxfrm_l;                   external libcmodulename name '__strxfrm_l';
function basename;                      external libcmodulename name 'basename';
function bcmp;                          external libcmodulename name 'bcmp';
procedure bcopy;                        external libcmodulename name 'bcopy';
procedure bzero;                        external libcmodulename name 'bzero';
function ffs;                           external libcmodulename name 'ffs';
function ffsl;                          external libcmodulename name 'ffsl';
function ffsll;                         external libcmodulename name 'ffsll';
function __index;                       external libcmodulename name 'index';
function memccpy;                       external libcmodulename name 'memccpy';
function memchr;                        external libcmodulename name 'memchr';
function memcmp;                        external libcmodulename name 'memcmp';
function memcpy;                        external libcmodulename name 'memcpy';
function memfrob;                       external libcmodulename name 'memfrob';
function memmem;                        external libcmodulename name 'memmem';
function memmove;                       external libcmodulename name 'memmove';
function mempcpy;                       external libcmodulename name 'mempcpy';
function memset;                        external libcmodulename name 'memset';
function rawmemchr;                     external libcmodulename name 'rawmemchr';
function memrchr;                       external libcmodulename name 'memrchr';
function rindex;                        external libcmodulename name 'rindex';
function stpcpy;                        external libcmodulename name 'stpcpy';
function stpncpy;                       external libcmodulename name 'stpncpy';
function strcasecmp;                    external libcmodulename name 'strcasecmp';
function strcasestr;                    external libcmodulename name 'strcasestr';
function __strcat;                      external libcmodulename name 'strcat';
function strchr;                        external libcmodulename name 'strchr';
function strcmp;                        external libcmodulename name 'strcmp';
function strcoll;                       external libcmodulename name 'strcoll';
function strcpy;                        external libcmodulename name 'strcpy';
function strcspn;                       external libcmodulename name 'strcspn';
function strdup;                        external libcmodulename name 'strdup';
function strerror;                      external libcmodulename name 'strerror';
function strerror_r;                    external libcmodulename name 'strerror_r';
function strfry;                        external libcmodulename name 'strfry';
function __strlen;                      external libcmodulename name 'strlen';
function strncasecmp;                   external libcmodulename name 'strncasecmp';
function strncat;                       external libcmodulename name 'strncat';
function strncmp;                       external libcmodulename name 'strncmp';
function strncpy;                       external libcmodulename name 'strncpy';
function strndup;                       external libcmodulename name 'strndup';
function strnlen;                       external libcmodulename name 'strnlen';
function strpbrk;                       external libcmodulename name 'strpbrk';
function strrchr;                       external libcmodulename name 'strrchr';
function strchrnul;                     external libcmodulename name 'strchrnul';
function strsep;                        external libcmodulename name 'strsep';
function strsignal;                     external libcmodulename name 'strsignal';
function strspn;                        external libcmodulename name 'strspn';
function strstr;                        external libcmodulename name 'strstr';
function strtok;                        external libcmodulename name 'strtok';
function strtok_r;                      external libcmodulename name 'strtok_r';
function strverscmp;                    external libcmodulename name 'strverscmp';
function strxfrm;                       external libcmodulename name 'strxfrm';

function __ctype_get_mb_cur_max;        external libcmodulename name '__ctype_get_mb_cur_max';
function __secure_getenv;               external libcmodulename name '__secure_getenv';
function __strtod_internal;             external libcmodulename name '__strtod_internal';
function __strtod_l;                    external libcmodulename name '__strtod_l';
function __strtof_internal;             external libcmodulename name '__strtof_internal';
function __strtof_l;                    external libcmodulename name '__strtof_l';
function __strtol_internal;             external libcmodulename name '__strtol_internal';
function __strtol_l;                    external libcmodulename name '__strtol_l';
function __strtold_internal;            external libcmodulename name '__strtold_internal';
function __strtold_l;                   external libcmodulename name '__strtold_l';
function __strtoll_internal;            external libcmodulename name '__strtoll_internal';
function __strtoll_l;                   external libcmodulename name '__strtoll_l';
function __strtoul_internal;            external libcmodulename name '__strtoul_internal';
function __strtoul_l;                   external libcmodulename name '__strtoul_l';
function __strtoull_internal;           external libcmodulename name '__strtoull_internal';
function __strtoull_l;                  external libcmodulename name '__strtoull_l';
function l64a;                          external libcmodulename name 'l64a';
function a64l;                          external libcmodulename name 'a64l';
function posix_memalign;                external libcmodulename name 'posix_memalign';
procedure __abort;                      external libcmodulename name 'abort';
function __abs;                         external libcmodulename name 'abs';
function atexit;                        external libcmodulename name 'atexit';
function atof;                          external libcmodulename name 'atof';
function atoi;                          external libcmodulename name 'atoi';
function atol;                          external libcmodulename name 'atol';
function atoll;                         external libcmodulename name 'atoll';
function calloc;                        external libcmodulename name 'calloc';
function canonicalize_file_name;        external libcmodulename name 'canonicalize_file_name';

procedure cfree;                        external libcmodulename name 'cfree';
function memalign;                      external libcmodulename name 'memalign';
function valloc;                        external libcmodulename name 'valloc';

function pvalloc;                       external libcmodulename name 'pvalloc';
function __default_morecore;            external libcmodulename name '__default_morecore';
function mallinfo;                      external libcmodulename name 'mallinfo';
function mallopt;                       external libcmodulename name 'mallopt';
function malloc_trim;                   external libcmodulename name 'malloc_trim';
function malloc_usable_size;            external libcmodulename name 'malloc_usable_size';
procedure malloc_stats;                 external libcmodulename name 'malloc_stats';
function malloc_get_state;              external libcmodulename name 'malloc_get_state';
function malloc_set_state;              external libcmodulename name 'malloc_set_state';
(*
procedure __malloc_check_init;          external libcmodulename name '__malloc_check_init';
*)
function clearenv;                      external libcmodulename name 'clearenv';
function __div;                         external libcmodulename name 'div';
function drand48;                       external libcmodulename name 'drand48';
function drand48_r;                     external libcmodulename name 'drand48_r';
function ecvt;                          external libcmodulename name 'ecvt';
function ecvt_r;                        external libcmodulename name 'ecvt_r';
function erand48;                       external libcmodulename name 'erand48';
function erand48_r;                     external libcmodulename name 'erand48_r';
procedure __exit;                       external libcmodulename name 'exit';
procedure _Exit;                        external libcmodulename name '_Exit';
function fcvt;                          external libcmodulename name 'fcvt';
function fcvt_r;                        external libcmodulename name 'fcvt_r';
procedure free;                         external libcmodulename name 'free';
function gcvt;                          external libcmodulename name 'gcvt';
function getenv;                        external libcmodulename name 'getenv';
function getpt;                         external libcmodulename name 'getpt';
function getloadavg;                    external libcmodulename name 'getloadavg';
function getsubopt;                     external libcmodulename name 'getsubopt';
function posix_openpt;                  external libcmodulename name 'posix_openpt';
function grantpt;                       external libcmodulename name 'grantpt';
function initstate;                     external libcmodulename name 'initstate';
function initstate_r;                   external libcmodulename name 'initstate_r';
function jrand48;                       external libcmodulename name 'jrand48';
function jrand48_r;                     external libcmodulename name 'jrand48_r';
function labs;                          external libcmodulename name 'labs';
procedure lcong48;                      external libcmodulename name 'lcong48';
function lcong48_r;                     external libcmodulename name 'lcong48_r';
function ldiv;                          external libcmodulename name 'ldiv';
function llabs;                         external libcmodulename name 'llabs';
function lldiv;                         external libcmodulename name 'lldiv';
function lrand48;                       external libcmodulename name 'lrand48';
function lrand48_r;                     external libcmodulename name 'lrand48_r';
function malloc;                        external libcmodulename name 'malloc';
function mblen;                         external libcmodulename name 'mblen';
function mbstowcs;                      external libcmodulename name 'mbstowcs';
function mbtowc;                        external libcmodulename name 'mbtowc';
function mktemp;                        external libcmodulename name 'mktemp';
function mkstemp;                       external libcmodulename name 'mkstemp';
function mkstemp64;                     external libcmodulename name 'mkstemp64';
function mkdtemp;                       external libcmodulename name 'mkdtemp';
function mrand48;                       external libcmodulename name 'mrand48';
function mrand48_r;                     external libcmodulename name 'mrand48_r';
function nrand48;                       external libcmodulename name 'nrand48';
function nrand48_r;                     external libcmodulename name 'nrand48_r';
function on_exit;                       external libcmodulename name 'on_exit';
function ptsname;                       external libcmodulename name 'ptsname';
function ptsname_r;                     external libcmodulename name 'ptsname_r';
function putenv;                        external libcmodulename name 'putenv';
function setenv(Name: PChar; const Value: PChar; Replace: Integer): Integer; cdecl; overload; external libcmodulename name 'setenv';
function setenv(Name: PChar; const Value: PChar; Replace: LongBool): Integer; cdecl; overload; external libcmodulename name 'setenv';
procedure unsetenv;                      external libcmodulename name 'unsetenv';
function qecvt;                         external libcmodulename name 'qecvt';
function qecvt_r;                       external libcmodulename name 'qecvt_r';
function qfcvt;                         external libcmodulename name 'qfcvt';
function qfcvt_r;                       external libcmodulename name 'qfcvt_r';
function qgcvt;                         external libcmodulename name 'qgcvt';
function rand;                          external libcmodulename name 'rand';
function rand_r;                        external libcmodulename name 'rand_r';
function __random;                      external libcmodulename name 'random';
function random_r;                      external libcmodulename name 'random_r';
function realloc;                       external libcmodulename name 'realloc';
function realpath;                      external libcmodulename name 'realpath';
function bsearch;                       external libcmodulename name 'bsearch';
procedure qsort;                        external libcmodulename name 'qsort';
function rpmatch;                       external libcmodulename name 'rpmatch';
function seed48;                        external libcmodulename name 'seed48';
function seed48_r;                      external libcmodulename name 'seed48_r';
function setstate;                      external libcmodulename name 'setstate';
function setstate_r;                    external libcmodulename name 'setstate_r';
procedure srand;                        external libcmodulename name 'srand';
procedure srand48;                      external libcmodulename name 'srand48';
function srand48_r;                     external libcmodulename name 'srand48_r';
procedure srandom;                      external libcmodulename name 'srandom';
function srandom_r;                     external libcmodulename name 'srandom_r';
function strtod;                        external libcmodulename name 'strtod';
function strtof;                        external libcmodulename name 'strtof';
function strtol;                        external libcmodulename name 'strtol';
function strtold;                       external libcmodulename name 'strtold';
function strtoll;                       external libcmodulename name 'strtoll';
function strtoul;                       external libcmodulename name 'strtoul';
function strtoq;                        external libcmodulename name 'strtoq';
function strtouq;                       external libcmodulename name 'strtouq';
function strtoull;                      external libcmodulename name 'strtoull';
function system;                        external libcmodulename name 'system';
function unlockpt;                      external libcmodulename name 'unlockpt';
function wcstombs;                      external libcmodulename name 'wcstombs';
function wctomb;                        external libcmodulename name 'wctomb';

function get_avphys_pages;              external libcmodulename name 'get_avphys_pages';
function get_nprocs;                    external libcmodulename name 'get_nprocs';
function get_nprocs_conf;               external libcmodulename name 'get_nprocs_conf';
function get_phys_pages;                external libcmodulename name 'get_phys_pages';
function sysinfo;                       external libcmodulename name 'sysinfo';

function setlocale;                     external libcmodulename name 'setlocale';
function localeconv;                    external libcmodulename name 'localeconv';
function __newlocale;                   external libcmodulename name '__newlocale';
function __duplocale;                   external libcmodulename name '__duplocale';
procedure __freelocale;                 external libcmodulename name '__freelocale';

function catopen;                       external libcmodulename name 'catopen';
function catgets;                       external libcmodulename name 'catgets';
function catclose;                      external libcmodulename name 'catclose';

function nl_langinfo;                   external libcmodulename name 'nl_langinfo';
function __nl_langinfo_l;               external libcmodulename name '__nl_langinfo_l';

function wordexp;                       external libcmodulename name 'wordexp';
procedure wordfree;                     external libcmodulename name 'wordfree';

function dlopen;                        external libdlmodulename name 'dlopen';
function dlerror;                       external libdlmodulename name 'dlerror';
function dlsym;                         external libdlmodulename name 'dlsym';
function dlvsym;                        external libdlmodulename name 'dlvsym';
function dlclose;                       external libdlmodulename name 'dlclose';
function dladdr;                        external libdlmodulename name 'dladdr';

function iconv_open;                    external libcmodulename name 'iconv_open';
function iconv;                         external libcmodulename name 'iconv';
function iconv_close;                   external libcmodulename name 'iconv_close';

function getrlimit;                     external libcmodulename name 'getrlimit';
function getrlimit64;                   external libcmodulename name 'getrlimit64';
function setrlimit;                     external libcmodulename name 'setrlimit';
function setrlimit64;                   external libcmodulename name 'setrlimit64';
function getrusage;                     external libcmodulename name 'getrusage';
function getpriority;                   external libcmodulename name 'getpriority';
function setpriority;                   external libcmodulename name 'setpriority';

function argz_create;                   external libcmodulename name 'argz_create';
function argz_create_sep;               external libcmodulename name 'argz_create_sep';
function argz_count;                    external libcmodulename name 'argz_count';
procedure argz_extract;                 external libcmodulename name 'argz_extract';
procedure argz_stringify;               external libcmodulename name 'argz_stringify';
function argz_append;                   external libcmodulename name 'argz_append';
function argz_add;                      external libcmodulename name 'argz_add';
function argz_add_sep;                  external libcmodulename name 'argz_add_sep';
procedure argz_delete;                  external libcmodulename name 'argz_delete';
function argz_insert;                   external libcmodulename name 'argz_insert';
function argz_replace;                  external libcmodulename name 'argz_replace';
function argz_next;                     external libcmodulename name 'argz_next';

function envz_entry;                    external libcmodulename name 'envz_entry';
function envz_get;                      external libcmodulename name 'envz_get';
function envz_add;                      external libcmodulename name 'envz_add';
function envz_merge;                    external libcmodulename name 'envz_merge';
procedure envz_remove;                  external libcmodulename name 'envz_remove';
procedure envz_strip;                   external libcmodulename name 'envz_strip';

function isalnum;                       external libcmodulename name 'isalnum';
function isalpha;                       external libcmodulename name 'isalpha';
function iscntrl;                       external libcmodulename name 'iscntrl';
function isdigit;                       external libcmodulename name 'isdigit';
function islower;                       external libcmodulename name 'islower';
function isgraph;                       external libcmodulename name 'isgraph';
function isprint;                       external libcmodulename name 'isprint';
function ispunct;                       external libcmodulename name 'ispunct';
function isspace;                       external libcmodulename name 'isspace';
function isupper;                       external libcmodulename name 'isupper';
function isxdigit;                      external libcmodulename name 'isxdigit';
function isblank;                       external libcmodulename name 'isblank';
function tolower;                       external libcmodulename name 'tolower';
function toupper;                       external libcmodulename name 'toupper';
function isascii;                       external libcmodulename name 'isascii';
function toascii;                       external libcmodulename name 'toascii';
function _toupper;                      external libcmodulename name '_toupper';
function _tolower;                      external libcmodulename name '_tolower';
function __isalnum_l;                   external libcmodulename name '__isalnum_l';
function __isalpha_l;                   external libcmodulename name '__isalpha_l';
function __iscntrl_l;                   external libcmodulename name '__iscntrl_l';
function __isdigit_l;                   external libcmodulename name '__isdigit_l';
function __islower_l;                   external libcmodulename name '__islower_l';
function __isgraph_l;                   external libcmodulename name '__isgraph_l';
function __isprint_l;                   external libcmodulename name '__isprint_l';
function __ispunct_l;                   external libcmodulename name '__ispunct_l';
function __isspace_l;                   external libcmodulename name '__isspace_l';
function __isupper_l;                   external libcmodulename name '__isupper_l';
function __isxdigit_l;                  external libcmodulename name '__isxdigit_l';
function __isblank_l;                   external libcmodulename name '__isblank_l';
function __tolower_l;                   external libcmodulename name '__tolower_l';
function __toupper_l;                   external libcmodulename name '__toupper_l';
function iswalnum;                      external libcmodulename name 'iswalnum';
function iswalpha;                      external libcmodulename name 'iswalpha';
function iswcntrl;                      external libcmodulename name 'iswcntrl';
function iswdigit;                      external libcmodulename name 'iswdigit';
function iswgraph;                      external libcmodulename name 'iswgraph';
function iswlower;                      external libcmodulename name 'iswlower';
function iswprint;                      external libcmodulename name 'iswprint';
function iswpunct;                      external libcmodulename name 'iswpunct';
function iswspace;                      external libcmodulename name 'iswspace';
function iswupper;                      external libcmodulename name 'iswupper';
function iswxdigit;                     external libcmodulename name 'iswxdigit';
function iswblank;                      external libcmodulename name 'iswblank';
function wctype;                        external libcmodulename name 'wctype';
function iswctype;                      external libcmodulename name 'iswctype';
function towupper;                      external libcmodulename name 'towupper';
function towlower;                      external libcmodulename name 'towlower';
function __towctrans;                   external libcmodulename name '__towctrans';
function wctrans;                       external libcmodulename name 'wctrans';
function towctrans;                     external libcmodulename name 'towctrans';
function __iswalnum_l;                  external libcmodulename name '__iswalnum_l';
function __iswalpha_l;                  external libcmodulename name '__iswalpha_l';
function __iswcntrl_l;                  external libcmodulename name '__iswcntrl_l';
function __iswdigit_l;                  external libcmodulename name '__iswdigit_l';
function __iswgraph_l;                  external libcmodulename name '__iswgraph_l';
function __iswlower_l;                  external libcmodulename name '__iswlower_l';
function __iswprint_l;                  external libcmodulename name '__iswprint_l';
function __iswpunct_l;                  external libcmodulename name '__iswpunct_l';
function __iswspace_l;                  external libcmodulename name '__iswspace_l';
function __iswupper_l;                  external libcmodulename name '__iswupper_l';
function __iswxdigit_l;                 external libcmodulename name '__iswxdigit_l';
function __iswblank_l;                  external libcmodulename name '__iswblank_l';
function __wctype_l;                    external libcmodulename name '__wctype_l';
function __iswctype_l;                  external libcmodulename name '__iswctype_l';
function __towlower_l;                  external libcmodulename name '__towlower_l';
function __towupper_l;                  external libcmodulename name '__towupper_l';
function __wctrans_l;                   external libcmodulename name '__wctrans_l';
function __towctrans_l;                 external libcmodulename name '__towctrans_l';

function wcscpy;                        external libcmodulename name 'wcscpy';
function wcsncpy;                       external libcmodulename name 'wcsncpy';
function wcscat;                        external libcmodulename name 'wcscat';
function wcsncat;                       external libcmodulename name 'wcsncat';
function wcscmp;                        external libcmodulename name 'wcscmp';
function wcsncmp;                       external libcmodulename name 'wcsncmp';
function wcscasecmp;                    external libcmodulename name 'wcscasecmp';
function wcsncasecmp;                   external libcmodulename name 'wcsncasecmp';
function __wcscasecmp_l;                external libcmodulename name '__wcscasecmp_l';
function __wcsncasecmp_l;               external libcmodulename name '__wcsncasecmp_l';
function wcscoll;                       external libcmodulename name 'wcscoll';
function wcsxfrm;                       external libcmodulename name 'wcsxfrm';
function __wcscoll_l;                   external libcmodulename name '__wcscoll_l';
function __wcsxfrm_l;                   external libcmodulename name '__wcsxfrm_l';
function wcsdup;                        external libcmodulename name 'wcsdup';
function wcschr;                        external libcmodulename name 'wcschr';
function wcsrchr;                       external libcmodulename name 'wcsrchr';
function wcschrnul;                     external libcmodulename name 'wcschrnul';
function wcscspn;                       external libcmodulename name 'wcscspn';
function wcsspn;                        external libcmodulename name 'wcsspn';
function wcspbrk;                       external libcmodulename name 'wcspbrk';
function wcsstr;                        external libcmodulename name 'wcsstr';
function wcswcs;                        external libcmodulename name 'wcswcs';
function wcstok;                        external libcmodulename name 'wcstok';
function wcslen;                        external libcmodulename name 'wcslen';
function wcsnlen;                       external libcmodulename name 'wcsnlen';
function wmemchr;                       external libcmodulename name 'wmemchr';
function wmemcmp;                       external libcmodulename name 'wmemcmp';
function wmemcpy;                       external libcmodulename name 'wmemcpy';
function wmemmove;                      external libcmodulename name 'wmemmove';
function wmemset;                       external libcmodulename name 'wmemset';
function wmempcpy;                      external libcmodulename name 'wmempcpy';
function btowc;                         external libcmodulename name 'btowc';
function wctob;                         external libcmodulename name 'wctob';
function mbsinit;                       external libcmodulename name 'mbsinit';
function mbrtowc;                       external libcmodulename name 'mbrtowc';
function wcrtomb;                       external libcmodulename name 'wcrtomb';
function mbrlen;                        external libcmodulename name 'mbrlen';
function mbsrtowcs;                     external libcmodulename name 'mbsrtowcs';
function wcsrtombs;                     external libcmodulename name 'wcsrtombs';
function mbsnrtowcs;                    external libcmodulename name 'mbsnrtowcs';
function wcsnrtombs;                    external libcmodulename name 'wcsnrtombs';
function wcwidth;                       external libcmodulename name 'wcwidth';
function wcswidth;                      external libcmodulename name 'wcswidth';
function wcstod;                        external libcmodulename name 'wcstod';
function wcstof;                        external libcmodulename name 'wcstof';
function wcstold;                       external libcmodulename name 'wcstold';
function wcstol;                        external libcmodulename name 'wcstol';
function wcstoul;                       external libcmodulename name 'wcstoul';
function wcstoq;                        external libcmodulename name 'wcstoq';
function wcstouq;                       external libcmodulename name 'wcstouq';
function wcstoll;                       external libcmodulename name 'wcstoll';
function wcstoull;                      external libcmodulename name 'wcstoull';
function __wcstol_l;                    external libcmodulename name '__wcstol_l';
function __wcstoul_l;                   external libcmodulename name '__wcstoul_l';
function __wcstoll_l;                   external libcmodulename name '__wcstoll_l';
function __wcstoull_l;                  external libcmodulename name '__wcstoull_l';

function __wcstod_l;                    external libcmodulename name '__wcstod_l';
function __wcstof_l;                    external libcmodulename name '__wcstof_l';
function __wcstold_l;                   external libcmodulename name '__wcstold_l';
function wcpcpy;                        external libcmodulename name 'wcpcpy';
function wcpncpy;                       external libcmodulename name 'wcpncpy';
function fwide;                         external libcmodulename name 'fwide';
function fwprintf;                      external libcmodulename name 'fwprintf';
function wprintf;                       external libcmodulename name 'wprintf';
function swprintf;                      external libcmodulename name 'swprintf';
function vfwprintf;                     external libcmodulename name 'vfwprintf';
function vwprintf;                      external libcmodulename name 'vwprintf';
function vswprintf;                     external libcmodulename name 'vswprintf';
function fwscanf;                       external libcmodulename name 'fwscanf';
function wscanf;                        external libcmodulename name 'wscanf';
function swscanf;                       external libcmodulename name 'swscanf';
function vfwscanf;                      external libcmodulename name 'vfwscanf';
function vwscanf;                       external libcmodulename name 'vwscanf';
function vswscanf;                      external libcmodulename name 'vswscanf';
function fgetwc;                        external libcmodulename name 'fgetwc';
function getwc;                         external libcmodulename name 'getwc';
function getwchar;                      external libcmodulename name 'getwchar';
function fputwc;                        external libcmodulename name 'fputwc';
function putwc;                         external libcmodulename name 'putwc';
function putwchar;                      external libcmodulename name 'putwchar';
function fgetws;                        external libcmodulename name 'fgetws';
function fputws;                        external libcmodulename name 'fputws';
function ungetwc;                       external libcmodulename name 'ungetwc';
function getwc_unlocked;                external libcmodulename name 'getwc_unlocked';
function getwchar_unlocked;             external libcmodulename name 'getwchar_unlocked';
function fgetwc_unlocked;               external libcmodulename name 'fgetwc_unlocked';
function fputwc_unlocked;               external libcmodulename name 'fputwc_unlocked';
function putwc_unlocked;                external libcmodulename name 'putwc_unlocked';
function putwchar_unlocked;             external libcmodulename name 'putwchar_unlocked';
function fgetws_unlocked;               external libcmodulename name 'fgetws_unlocked';
function fputws_unlocked;               external libcmodulename name 'fputws_unlocked';
function wcsftime;                      external libcmodulename name 'wcsftime';

function __wait;                        external libcmodulename name '__wait';
function wait;                          external libcmodulename name 'wait';
function waitpid;                       external libcmodulename name 'waitpid';
function waitid;                        external libcmodulename name 'waitid';
function wait3;                         external libcmodulename name 'wait3';
function wait4;                         external libcmodulename name 'wait4';

function uname;                         external libcmodulename name 'uname';

function mount;                         external libcmodulename name 'mount';
function umount;                        external libcmodulename name 'umount';
function umount2;                       external libcmodulename name 'umount2';

function sysctl;                        external libcmodulename name 'sysctl';

function mmap;                          external libcmodulename name 'mmap';
function mmap64;                        external libcmodulename name 'mmap64';
function munmap;                        external libcmodulename name 'munmap';
function mprotect;                      external libcmodulename name 'mprotect';
function msync;                         external libcmodulename name 'msync';
function madvise;                       external libcmodulename name 'madvise';
function posix_madvise;                 external libcmodulename name 'posix_madvise';
function mlock;                         external libcmodulename name 'mlock';
function munlock;                       external libcmodulename name 'munlock';
function mlockall;                      external libcmodulename name 'mlockall';
function munlockall;                    external libcmodulename name 'munlockall';
function mremap;                        external libcmodulename name 'mremap';
function mincore;                       external libcmodulename name 'mincore';
function shm_open;                      external librtmodulename name 'shm_open';
function shm_unlink;                    external librtmodulename name 'shm_unlink';

procedure closelog;                     external libcmodulename name 'closelog';
procedure openlog;                      external libcmodulename name 'openlog';
function setlogmask;                    external libcmodulename name 'setlogmask';
procedure syslog;                       external libcmodulename name 'syslog';
procedure vsyslog;                      external libcmodulename name 'vsyslog';

function gnu_get_libc_release;          external libcmodulename name 'gnu_get_libc_release';
function gnu_get_libc_version;          external libcmodulename name 'gnu_get_libc_version';

function readv;                         external libcmodulename name 'readv';
function writev;                        external libcmodulename name 'writev';

function accept;                        external libcmodulename name 'accept';
function bind;                          external libcmodulename name 'bind';
function connect;                       external libcmodulename name 'connect';
function getpeername;                   external libcmodulename name 'getpeername';
function getsockname;                   external libcmodulename name 'getsockname';
function getsockopt;                    external libcmodulename name 'getsockopt';
function htonl;                         external libcmodulename name 'htonl';
function htons;                         external libcmodulename name 'htons';
function bindresvport;                  external libcmodulename name 'bindresvport';
(* Not defined in binary
function bindresvport6;                 external libcmodulename name 'bindresvport6';
*)
function inet_addr;                     external libcmodulename name 'inet_addr';
function inet_lnaof;                    external libcmodulename name 'inet_lnaof';
procedure inet_makeaddr;                external libcmodulename name 'inet_makeaddr';
function inet_netof;                    external libcmodulename name 'inet_netof';
function inet_network;                  external libcmodulename name 'inet_network';
function inet_ntoa;                     external libcmodulename name 'inet_ntoa';
function inet_pton;                     external libcmodulename name 'inet_pton';
function inet_ntop;                     external libcmodulename name 'inet_ntop';
function inet_aton;                     external libcmodulename name 'inet_aton';
function inet_neta;                     external libresolvmodulename name 'inet_neta';
function inet_net_ntop;                 external libresolvmodulename name 'inet_net_ntop';
function inet_net_pton;                 external libresolvmodulename name 'inet_net_pton';
function inet_nsap_addr;                external libcmodulename name 'inet_nsap_addr';
function inet_nsap_ntoa;                external libcmodulename name 'inet_nsap_ntoa';

function __h_errno_location;            external libcmodulename name '__h_errno_location';
procedure herror;                       external libcmodulename name 'herror';
function hstrerror;                     external libcmodulename name 'hstrerror';

function listen;                        external libcmodulename name 'listen';
function ntohl;                         external libcmodulename name 'ntohl';
function ntohs;                         external libcmodulename name 'ntohs';
function recv;                          external libcmodulename name 'recv';
function recvfrom;                      external libcmodulename name 'recvfrom';
function select;                        external libcmodulename name 'select';
function pselect;                       external libcmodulename name 'pselect';
function send;                          external libcmodulename name 'send';
function sendto;                        external libcmodulename name 'sendto';
function setsockopt;                    external libcmodulename name 'setsockopt';
function shutdown;                      external libcmodulename name 'shutdown';

function __libc_sa_len;                 external libcmodulename name '__libc_sa_len';
function __cmsg_nxthdr;                 external libcmodulename name '__cmsg_nxthdr';
function socket(__domain, __type, __protocol: Integer): TSocket; cdecl; overload; external libcmodulename name 'socket';
function socket(__domain: Integer; __type: __socket_type; __protocol: Integer): TSocket; cdecl; overload; external libcmodulename name 'socket';

procedure sethostent;                   external libcmodulename name 'sethostent';
procedure endhostent;                   external libcmodulename name 'endhostent';
function gethostent;                    external libcmodulename name 'gethostent';
function gethostbyaddr;                 external libcmodulename name 'gethostbyaddr';
function gethostbyname;                 external libcmodulename name 'gethostbyname';
function gethostbyname2;                external libcmodulename name 'gethostbyname2';
function gethostent_r;                  external libcmodulename name 'gethostent_r';
function gethostbyaddr_r;               external libcmodulename name 'gethostbyaddr_r';
function gethostbyname_r;               external libcmodulename name 'gethostbyname_r';
function gethostbyname2_r;              external libcmodulename name 'gethostbyname2_r';
procedure setnetent;                    external libcmodulename name 'setnetent';
procedure endnetent;                    external libcmodulename name 'endnetent';
function getnetent;                     external libcmodulename name 'getnetent';
function getnetbyaddr;                  external libcmodulename name 'getnetbyaddr';
function getnetbyname;                  external libcmodulename name 'getnetbyname';
function getnetent_r;                   external libcmodulename name 'getnetent_r';
function getnetbyaddr_r;                external libcmodulename name 'getnetbyaddr_r';
function getnetbyname_r;                external libcmodulename name 'getnetbyname_r';
procedure setservent;                   external libcmodulename name 'setservent';
procedure endservent;                   external libcmodulename name 'endservent';
function getservent;                    external libcmodulename name 'getservent';
function getservbyname;                 external libcmodulename name 'getservbyname';
function getservbyport;                 external libcmodulename name 'getservbyport';
function getservent_r;                  external libcmodulename name 'getservent_r';
function getservbyname_r;               external libcmodulename name 'getservbyname_r';
function getservbyport_r;               external libcmodulename name 'getservbyport_r';
procedure setprotoent;                  external libcmodulename name 'setprotoent';
procedure endprotoent;                  external libcmodulename name 'endprotoent';
function getprotoent;                   external libcmodulename name 'getprotoent';
function getprotobyname;                external libcmodulename name 'getprotobyname';
function getprotobynumber;              external libcmodulename name 'getprotobynumber';
function getprotoent_r;                 external libcmodulename name 'getprotoent_r';
function getprotobyname_r;              external libcmodulename name 'getprotobyname_r';
function getprotobynumber_r;            external libcmodulename name 'getprotobynumber_r';
function setnetgrent;                   external libcmodulename name 'setnetgrent';
procedure endnetgrent;                  external libcmodulename name 'endnetgrent';
function getnetgrent;                   external libcmodulename name 'getnetgrent';
function innetgr;                       external libcmodulename name 'innetgr';
function getnetgrent_r;                 external libcmodulename name 'getnetgrent_r';
function rcmd;                          external libcmodulename name 'rcmd';
function rcmd_af;                       external libcmodulename name 'rcmd_af';
function rexec;                         external libcmodulename name 'rexec';
function rexec_af;                      external libcmodulename name 'rexec_af';
function ruserok;                       external libcmodulename name 'ruserok';
function ruserok_af;                    external libcmodulename name 'ruserok_af';
function rresvport;                     external libcmodulename name 'rresvport';
function rresvport_af;                  external libcmodulename name 'rresvport_af';

function getaddrinfo;                   external libcmodulename name 'getaddrinfo';
procedure freeaddrinfo;                 external libcmodulename name 'freeaddrinfo';
function gai_strerror;                  external libcmodulename name 'gai_strerror';
function getnameinfo;                   external libcmodulename name 'getnameinfo';

function socketpair(__domain, __type, __protocol: Integer; var __fds: TSocketPair): Integer; cdecl; overload; external libcmodulename name 'socketpair';
function socketpair(__domain: Integer; __type: __socket_type; __protocol: Integer; var __fds: TSocketPair): Integer; cdecl; overload; external libcmodulename name 'socketpair';
function sendmsg;                       external libcmodulename name 'sendmsg';
function recvmsg;                       external libcmodulename name 'recvmsg';
function isfdtype;                      external libcmodulename name 'isfdtype';

procedure setpwent;                     external libcmodulename name 'setpwent';
procedure endpwent;                     external libcmodulename name 'endpwent';
function getpwent;                      external libcmodulename name 'getpwent';
function fgetpwent;                     external libcmodulename name 'fgetpwent';
function putpwent;                      external libcmodulename name 'putpwent';
function getpwuid;                      external libcmodulename name 'getpwuid';
function getpwnam;                      external libcmodulename name 'getpwnam';
function getpwent_r;                    external libcmodulename name 'getpwent_r';
function getpwuid_r;                    external libcmodulename name 'getpwuid_r';
function getpwnam_r;                    external libcmodulename name 'getpwnam_r';
function fgetpwent_r;                   external libcmodulename name 'fgetpwent_r';
function getpw;                         external libcmodulename name 'getpw';

procedure setgrent;                     external libcmodulename name 'setgrent';
procedure endgrent;                     external libcmodulename name 'endgrent';
function getgrent;                      external libcmodulename name 'getgrent';
function fgetgrent;                     external libcmodulename name 'fgetgrent';
function putgrent;                      external libcmodulename name 'putgrent';
function getgrgid;                      external libcmodulename name 'getgrgid';
function getgrnam;                      external libcmodulename name 'getgrnam';
function getgrent_r;                    external libcmodulename name 'getgrent_r';
function getgrgid_r;                    external libcmodulename name 'getgrgid_r';
function getgrnam_r;                    external libcmodulename name 'getgrnam_r';
function fgetgrent_r;                   external libcmodulename name 'fgetgrent_r';
function setgroups;                     external libcmodulename name 'setgroups';
function initgroups;                    external libcmodulename name 'initgroups';

function ptrace(__request: __ptrace_request): Longint;             external libcmodulename name 'ptrace';
function ptrace(__request: __ptrace_request; PID: pid_t; Address: Pointer; Data: Integer): Longint;             external libcmodulename name 'ptrace';
function ptrace(__request: __ptrace_request; PID: pid_t; Address: Pointer; Data: Integer; Addr2: Pointer): Longint;             external libcmodulename name 'ptrace';

function ulimit;                        external libcmodulename name 'ulimit';

function poll;                          external libcmodulename name 'poll';

function utime;                         external libcmodulename name 'utime';

function ustat;                         external libcmodulename name 'ustat';

procedure warn;                         external libcmodulename name 'warn';
procedure vwarn;                        external libcmodulename name 'vwarn';
procedure warnx;                        external libcmodulename name 'warnx';
procedure vwarnx;                       external libcmodulename name 'vwarnx';
procedure err;                          external libcmodulename name 'err';
procedure verr;                         external libcmodulename name 'verr';
procedure errx;                         external libcmodulename name 'errx';
procedure verrx;                        external libcmodulename name 'verrx';

procedure error;                        external libcmodulename name 'error';
procedure error_at_line;                external libcmodulename name 'error_at_line';

function feclearexcept;                 external libmmodulename name 'feclearexcept';
function fegetexceptflag;               external libmmodulename name 'fegetexceptflag';
function feraiseexcept;                 external libmmodulename name 'feraiseexcept';
function fesetexceptflag;               external libmmodulename name 'fesetexceptflag';
function fetestexcept;                  external libmmodulename name 'fetestexcept';
function fegetround;                    external libmmodulename name 'fegetround';
function fesetround;                    external libmmodulename name 'fesetround';
function fegetenv;                      external libmmodulename name 'fegetenv';
function feholdexcept;                  external libmmodulename name 'feholdexcept';
function fesetenv;                      external libmmodulename name 'fesetenv';
function feupdateenv;                   external libmmodulename name 'feupdateenv';
function feenableexcept;                external libmmodulename name 'feenableexcept';
function fedisableexcept;               external libmmodulename name 'fedisableexcept';
function fegetexcept;                   external libmmodulename name 'fegetexcept';

function ftok;                          external libcmodulename name 'ftok';

function __getpagesize;                 external libcmodulename name '__getpagesize';
function shmctl;                        external libcmodulename name 'shmctl';
function shmget;                        external libcmodulename name 'shmget';
function shmat;                         external libcmodulename name 'shmat';
function shmdt;                         external libcmodulename name 'shmdt';

function semctl;                        external libcmodulename name 'semctl';
function semget;                        external libcmodulename name 'semget';
function semop;                         external libcmodulename name 'semop';

function dirname;                       external libcmodulename name 'dirname';
function __xpg_basename;                external libcmodulename name '__xpg_basename';
function login_tty;                     external libutilmodulename name 'login_tty';
procedure login;                        external libutilmodulename name 'login';
function logout;                        external libutilmodulename name 'logout';
procedure logwtmp;                      external libutilmodulename name 'logwtmp';
procedure updwtmp;                      external libcmodulename name 'updwtmp';
function utmpname;                      external libcmodulename name 'utmpname';
function getutent;                      external libcmodulename name 'getutent';
procedure setutent;                     external libcmodulename name 'setutent';
procedure endutent;                     external libcmodulename name 'endutent';
function getutid;                       external libcmodulename name 'getutid';
function getutline;                     external libcmodulename name 'getutline';
function pututline;                     external libcmodulename name 'pututline';
function getutent_r;                    external libcmodulename name 'getutent_r';
function getutid_r;                     external libcmodulename name 'getutid_r';
function getutline_r;                   external libcmodulename name 'getutline_r';

procedure setutxent;                    external libcmodulename name 'setutxent';
procedure endutxent;                    external libcmodulename name 'endutxent';
function getutxent;                     external libcmodulename name 'getutxent';
function getutxid;                      external libcmodulename name 'getutxid';
function getutxline;                    external libcmodulename name 'getutxline';
function pututxline;                    external libcmodulename name 'pututxline';
function utmpxname;                     external libcmodulename name 'utmpxname';
procedure updwtmpx;                     external libcmodulename name 'updwtmpx';
procedure getutmp;                      external libcmodulename name 'getutmp';
procedure getutmpx;                     external libcmodulename name 'getutmpx';

function vtimes;                        external libcmodulename name 'vtimes';

function vlimit;                        external libcmodulename name 'vlimit';

function getcontext;                    external libcmodulename name 'getcontext';
function setcontext;                    external libcmodulename name 'setcontext';
function swapcontext;                   external libcmodulename name 'swapcontext';
procedure makecontext;                  external libcmodulename name 'makecontext';

function msgctl;                        external libcmodulename name 'msgctl';
function msgget;                        external libcmodulename name 'msgget';
function msgrcv;                        external libcmodulename name 'msgrcv';
function msgsnd;                        external libcmodulename name 'msgsnd';

function statfs;                        external libcmodulename name 'statfs';
function statfs64;                      external libcmodulename name 'statfs64';
function fstatfs;                       external libcmodulename name 'fstatfs';
function fstatfs64;                     external libcmodulename name 'fstatfs64';

function statvfs;                       external libcmodulename name 'statvfs';
function statvfs64;                     external libcmodulename name 'statvfs64';
function fstatvfs;                      external libcmodulename name 'fstatvfs';
function fstatvfs64;                    external libcmodulename name 'fstatvfs64';

function strfmon;                       external libcmodulename name 'strfmon';
function __strfmon_l;                   external libcmodulename name '__strfmon_l';

function mcheck;                        external libcmodulename name 'mcheck';
function mcheck_pedantic;               external libcmodulename name 'mcheck_pedantic';
procedure mcheck_check_all;             external libcmodulename name 'mcheck_check_all';
function mprobe;                        external libcmodulename name 'mprobe';
procedure mtrace;                       external libcmodulename name 'mtrace';
procedure muntrace;                     external libcmodulename name 'muntrace';

function printf_size;                   external libcmodulename name 'printf_size';
function printf_size_info;              external libcmodulename name 'printf_size_info';

function gettext;                       external libcmodulename name 'gettext';
function dgettext;                      external libcmodulename name 'dgettext';
function __dgettext;                    external libcmodulename name '__dgettext';
function dcgettext;                     external libcmodulename name 'dcgettext';
function __dcgettext;                   external libcmodulename name '__dcgettext';
function ngettext;                      external libcmodulename name 'ngettext';
function dngettext;                     external libcmodulename name 'dngettext';
function dcngettext;                    external libcmodulename name 'dcngettext';
function textdomain;                    external libcmodulename name 'textdomain';
function bindtextdomain;                external libcmodulename name 'bindtextdomain';
function bind_textdomain_codeset;            external libcmodulename name 'bind_textdomain_codeset';

procedure setspent;                     external libcmodulename name 'setspent';
procedure endspent;                     external libcmodulename name 'endspent';
function getspent;                      external libcmodulename name 'getspent';
function getspnam;                      external libcmodulename name 'getspnam';
function sgetspent;                     external libcmodulename name 'sgetspent';
function fgetspent;                     external libcmodulename name 'fgetspent';
function putspent;                      external libcmodulename name 'putspent';
function getspent_r;                    external libcmodulename name 'getspent_r';
function getspnam_r;                    external libcmodulename name 'getspnam_r';
function sgetspent_r;                   external libcmodulename name 'sgetspent_r';
function fgetspent_r;                   external libcmodulename name 'fgetspent_r';
function lckpwdf;                       external libcmodulename name 'lckpwdf';
function ulckpwdf;                      external libcmodulename name 'ulckpwdf';

function fmtmsg;                        external libcmodulename name 'fmtmsg';
function addseverity;                   external libcmodulename name 'addseverity';

function quotactl;                      external libcmodulename name 'quotactl';

function ftime;                         external libcmodulename name 'ftime';

function ioperm;                        external libcmodulename name 'ioperm';
function iopl;                          external libcmodulename name 'iopl';

function swapon;                        external libcmodulename name 'swapon';
function swapoff;                       external libcmodulename name 'swapoff';

function sendfile;                      external libcmodulename name 'sendfile';

function reboot;                        external libcmodulename name 'reboot';

procedure aio_init;                     external librtmodulename name 'aio_init';
function aio_read;                      external librtmodulename name 'aio_read';
function aio_write;                     external librtmodulename name 'aio_write';
function lio_listio;                    external librtmodulename name 'lio_listio';
function aio_error;                     external librtmodulename name 'aio_error';
function aio_return;                    external librtmodulename name 'aio_return';
function aio_cancel;                    external librtmodulename name 'aio_cancel';
function aio_suspend;                   external librtmodulename name 'aio_suspend';
function aio_fsync;                     external librtmodulename name 'aio_fsync';
function aio_read64;                    external librtmodulename name 'aio_read64';
function aio_write64;                   external librtmodulename name 'aio_write64';
function lio_listio64;                  external librtmodulename name 'lio_listio64';
function aio_error64;                   external librtmodulename name 'aio_error64';
function aio_return64;                  external librtmodulename name 'aio_return64';
function aio_cancel64;                  external librtmodulename name 'aio_cancel64';
function aio_suspend64;                 external librtmodulename name 'aio_suspend64';
function aio_fsync64;                   external librtmodulename name 'aio_fsync64';

procedure setaliasent;                  external libcmodulename name 'setaliasent';
procedure endaliasent;                  external libcmodulename name 'endaliasent';
function getaliasent;                   external libcmodulename name 'getaliasent';
function getaliasent_r;                 external libcmodulename name 'getaliasent_r';
function getaliasbyname;                external libcmodulename name 'getaliasbyname';
function getaliasbyname_r;              external libcmodulename name 'getaliasbyname_r';

function glob;                          external libcmodulename name 'glob';
procedure globfree;                     external libcmodulename name 'globfree';
function glob64;                        external libcmodulename name 'glob64';
procedure globfree64;                   external libcmodulename name 'globfree64';
function glob_pattern_p;                external libcmodulename name 'glob_pattern_p';

function crypt_r;                       external libcmodulename name 'crypt_r';
procedure setkey_r;                     external libcmodulename name 'setkey_r';
procedure encrypt_r;                    external libcmodulename name 'encrypt_r';

function setfsuid;                      external libcmodulename name 'setfsuid';
function setfsgid;                      external libcmodulename name 'setfsgid';

function klogctl;                       external libcmodulename name 'klogctl';

function bdflush;                       external libcmodulename name 'bdflush';

function isastream;                     external libcmodulename name 'isastream';
function getmsg;                        external libcmodulename name 'getmsg';
function getpmsg;                       external libcmodulename name 'getpmsg';
function putmsg;                        external libcmodulename name 'putmsg';
function putpmsg;                       external libcmodulename name 'putpmsg';
function fattach;                       external libcmodulename name 'fattach';
function fdetach;                       external libcmodulename name 'fdetach';

(* Intrinsic function, not exposed
function alloca;                        external libcmodulename name 'alloca';
*)

function getopt;                        external libcmodulename name 'getopt';
function getopt_long;                   external libcmodulename name 'getopt_long';
function getopt_long_only;              external libcmodulename name 'getopt_long_only';

function argp_parse;                    external libcmodulename name 'argp_parse';
function __argp_parse;                  external libcmodulename name 'argp_parse';
procedure argp_help;                    external libcmodulename name 'argp_help';
procedure __argp_help;                  external libcmodulename name 'argp_help';
procedure argp_state_help;              external libcmodulename name 'argp_state_help';
procedure __argp_state_help;            external libcmodulename name 'argp_state_help';
procedure argp_usage;                   external libcmodulename name 'argp_usage';
procedure __argp_usage;                 external libcmodulename name 'argp_usage';
procedure argp_error;                   external libcmodulename name 'argp_error';
procedure __argp_error;                 external libcmodulename name 'argp_error';
procedure argp_failure;                 external libcmodulename name 'argp_failure';
procedure __argp_failure;               external libcmodulename name 'argp_failure';
(* Local symbol only
function _option_is_short;              external libcmodulename name '_option_is_short';
function __option_is_short;             external libcmodulename name '__option_is_short';
function _option_is_end;                external libcmodulename name '_option_is_end';
function __option_is_end;               external libcmodulename name '__option_is_end';
*)
function __argp_input;                  external libcmodulename name '__argp_input';

function __nss_configure_lookup;        external libcmodulename name '__nss_configure_lookup';

function imaxabs;                       external libcmodulename name 'imaxabs';
function imaxdiv;                       external libcmodulename name 'imaxdiv';
function strtoimax;                     external libcmodulename name 'strtoimax';
function strtoumax;                     external libcmodulename name 'strtoumax';
function wcstoimax;                     external libcmodulename name 'wcstoimax';
function wcstoumax;                     external libcmodulename name 'wcstoumax';

function re_set_syntax;                 external libcmodulename name 're_set_syntax';
function re_compile_pattern;            external libcmodulename name 're_compile_pattern';
function re_compile_fastmap;            external libcmodulename name 're_compile_fastmap';
function re_search;                     external libcmodulename name 're_search';
function re_search_2;                   external libcmodulename name 're_search_2';
function re_match;                      external libcmodulename name 're_match';
function re_match_2;                    external libcmodulename name 're_match_2';
procedure re_set_registers;             external libcmodulename name 're_set_registers';
function re_comp;                       external libcmodulename name 're_comp';
function re_exec;                       external libcmodulename name 're_exec';
function regcomp;                       external libcmodulename name 'regcomp';
function regexec;                       external libcmodulename name 'regexec';
function regerror;                      external libcmodulename name 'regerror';
procedure regfree;                      external libcmodulename name 'regfree';

function if_nametoindex;                external libcmodulename name 'if_nametoindex';
function if_indextoname;                external libcmodulename name 'if_indextoname';
function if_nameindex;                  external libcmodulename name 'if_nameindex';
procedure if_freenameindex;             external libcmodulename name 'if_freenameindex';
function ether_ntoa;                    external libcmodulename name 'ether_ntoa';
function ether_ntoa_r;                  external libcmodulename name 'ether_ntoa_r';
function ether_aton;                    external libcmodulename name 'ether_aton';
function ether_aton_r;                  external libcmodulename name 'ether_aton_r';
function ether_ntohost;                 external libcmodulename name 'ether_ntohost';
function ether_hostton;                 external libcmodulename name 'ether_hostton';
function ether_line;                    external libcmodulename name 'ether_line';

function openpty;                       external libcmodulename name 'openpty';
function forkpty;                       external libcmodulename name 'forkpty';

function getttyent;                     external libcmodulename name 'getttyent';
function getttynam;                     external libcmodulename name 'getttynam';
function setttyent;                     external libcmodulename name 'setttyent';
function endttyent;                     external libcmodulename name 'endttyent';

function gtty;                          external libcmodulename name 'gtty';
function stty;                          external libcmodulename name 'stty';

procedure insque;                       external libcmodulename name 'insque';
procedure remque;                       external libcmodulename name 'remque';
function hsearch;                       external libcmodulename name 'hsearch';
function hcreate;                       external libcmodulename name 'hcreate';
procedure hdestroy;                     external libcmodulename name 'hdestroy';
function hsearch_r;                     external libcmodulename name 'hsearch_r';
function hcreate_r;                     external libcmodulename name 'hcreate_r';
procedure hdestroy_r;                   external libcmodulename name 'hdestroy_r';
function tsearch;                       external libcmodulename name 'tsearch';
function tfind;                         external libcmodulename name 'tfind';
function tdelete;                       external libcmodulename name 'tdelete';
procedure twalk;                        external libcmodulename name 'twalk';
procedure tdestroy;                     external libcmodulename name 'tdestroy';
function lfind;                         external libcmodulename name 'lfind';
function lsearch;                       external libcmodulename name 'lsearch';


{ Macro Implementations }

// From types.h

function __FDELT(d: TFileDescriptor): Integer;
begin
  Result := d div __NFDBITS;
end;

function __FDMASK(d: TFileDescriptor): __fd_mask;
begin
  Result := 1 shl (d mod __NFDBITS);
end;


// From bits/time.h

function CLK_TCK: __clock_t;
begin
  Result := sysconf(_SC_CLK_TCK);
end;

// Misc.

function MB_CUR_MAX: size_t;
begin
  Result := __ctype_get_mb_cur_max;
end;

function SIGRTMIN: Integer;
begin
  Result := __libc_current_sigrtmin;
end;

function SIGRTMAX: Integer;
begin
  Result := __libc_current_sigrtmax;
end;

// SysLog macros (sys/syslog.h)

function LOG_PRI(const Value: Integer): Integer;
begin
  Result := Value and LOG_PRIMASK;
end;

function LOG_MAKEPRI(Facility, Priority: Integer): Integer;
begin
  Result := (Facility shl 3) or Priority;
end;

function LOG_FAC(Value: Integer):Integer;
begin
  Result := (Value and LOG_FACMASK) shr 3;
end;

function LOG_MASK(Priority: Integer): Integer;
begin
  Result := 1 shl Priority;
end;

function LOG_UPTO(Priority: Integer): Integer;
begin
  Result := (1 shl (Priority + 1)) - 1;
end;

// Wait "macro" functions (wait.h)

function WEXITSTATUS(Status: Integer): Integer;
begin
  Result := (Status and $FF00) shr 8;
end;

function WTERMSIG(Status: Integer): Integer;
begin
  Result := (Status and $7F);
end;

function WSTOPSIG(Status: Integer): Integer;
begin
  Result := WEXITSTATUS(Status);
end;

function WIFEXITED(Status: Integer): Boolean;
begin
  Result := (WTERMSIG(Status) = 0);
end;

function WIFSIGNALED(Status: Integer): Boolean;
begin
  Result := (not WIFSTOPPED(Status)) and (not WIFEXITED(Status));
end;

function WIFSTOPPED(Status: Integer): Boolean;
begin
  Result := ((Status and $FF) = $7F);
end;

function WCOREDUMP(Status: Integer): Boolean;
begin
  Result := ((Status and WCOREFLAG) <> 0);
end;

function W_EXITCODE(ReturnCode, Signal: Integer): Integer;
begin
  Result := (ReturnCode shl 8) or Signal;
end;

function W_STOPCODE(Signal: Integer): Integer;
begin
  Result := (Signal shl 8) or $7F;
end;

// Version macros from sys/sysmacros.h

function major(dev: dev_t): Integer;
begin
  Result := (Integer(dev) shr 8) and $FF;
end;

function minor(dev: dev_t): Integer;
begin
  Result := Integer(dev) and $FF;
end;

function makedev(major, minor: Integer): dev_t;
begin
  Result := (major shl 8) or minor;
end;

// Mutex/CriticalSection wrappers

function InitializeCriticalSection(var lpCriticalSection: TRTLCriticalSection): Integer;
var
  Attribute: TMutexAttribute;
begin
  Result := pthread_mutexattr_init(Attribute);
  if Result <> 0 then Exit;
  try
    Result := pthread_mutexattr_settype(Attribute, PTHREAD_MUTEX_RECURSIVE);
    if Result <> 0 then Exit;

    Result := pthread_mutex_init(lpCriticalSection, Attribute);
  finally
    pthread_mutexattr_destroy(Attribute);
  end;
end;

function EnterCriticalSection;   external libcmodulename name 'pthread_mutex_lock';
function LeaveCriticalSection;   external libcmodulename name 'pthread_mutex_unlock';
function DeleteCriticalSection;  external libcmodulename name 'pthread_mutex_destroy';

function TryEnterCriticalSection(var lpCriticalSection: TRTLCriticalSection): Boolean;
begin
  Result := pthread_mutex_trylock(lpCriticalSection) <> EBUSY;
end;


// Stat functions (sys/stat.h)

function fstat(FileDes: Integer; var StatBuffer: TStatBuf): Integer;
begin
  Result := __fxstat(_STAT_VER, FileDes, StatBuffer);
end;

function lstat(FileName: PChar; var StatBuffer: TStatBuf): Integer;
begin
  Result := __lxstat(_STAT_VER, FileName, StatBuffer);
end;

function stat(FileName: PChar; var StatBuffer: TStatBuf): Integer;
begin
  Result := __xstat(_STAT_VER, FileName, StatBuffer);
end;

function mknod(Pathname: PChar; Mode: __mode_t; Device: __dev_t): Integer;
begin
  Result := __xmknod(_MKNOD_VER, Pathname, Mode, Device);
end;

// stat.h macros

function __S_ISTYPE(mode, mask: __mode_t): Boolean;
begin
  Result := (mode and __S_IFMT) = mask;
end;

function S_ISDIR(mode: __mode_t): Boolean;
begin
  Result := __S_ISTYPE(mode, __S_IFDIR);
end;

function S_ISCHR(mode: __mode_t): Boolean;
begin
  Result := __S_ISTYPE(mode, __S_IFCHR);
end;

function S_ISBLK(mode: __mode_t): Boolean;
begin
  Result := __S_ISTYPE(mode, __S_IFBLK);
end;

function S_ISREG(mode: __mode_t): Boolean;
begin
  Result := __S_ISTYPE(mode, __S_IFREG);
end;

function S_ISFIFO(mode: __mode_t): Boolean;
begin
  Result := __S_ISTYPE(mode, __S_IFIFO);
end;

function S_ISLNK(mode: __mode_t): Boolean;
begin
  Result := __S_ISTYPE(mode, __S_IFLNK);
end;

function S_ISSOCK(mode: __mode_t): Boolean;
begin
  Result := __S_ISTYPE(mode, __S_IFSOCK);
end;

// dirent.h macros

function IFTODT(mode: __mode_t): Integer;
begin
  Result := (mode and $F000) shr  12;
end;

function DTTOIF(dirtype: Integer): __mode_t;
begin
  Result := dirtype shl 12;
end;

// sys/un.h macro

function SUN_LEN(ptr: PSockAddr_un): Cardinal;
begin
  Result := SizeOf(ptr^.sun_family) + __strlen(ptr^.sun_path);
end;

// bits/socket.h macros

function SA_LEN(const UnsafeSockAddrBuffer): Cardinal; // Untyped buffer; this is *unsafe*.
begin
  Result := __libc_sa_len(PSockAddr(@UnsafeSockAddrBuffer)^.sa_family);
end;

function CMSG_DATA(cmsg: Pointer): PByte;
begin
  Result := PByte(Cardinal(cmsg) + SizeOf(PCMessageHeader));
end;

function CMSG_NXTHDR(mhdr: PMessageHeader; cmsg: PCMessageHeader): PCMessageHeader;
begin
   Result := __cmsg_nxthdr(mhdr, cmsg);
end;

function CMSG_FIRSTHDR(mhdr: PMessageHeader): PCMessageHeader;
begin
  if mhdr^.msg_controllen >= SizeOf(cmsghdr) then
    Result := mhdr^.msg_control
  else
    Result := nil;
end;

function CMSG_ALIGN(len: size_t): size_t;
begin
  Result := (len + SizeOf(size_t) - 1) and (not (SizeOf(size_t) - 1));
end;

function CMSG_SPACE(len: size_t): size_t;
begin
  Result := CMSG_ALIGN(len) + CMSG_ALIGN(SizeOf(cmsghdr));
end;

function CMSG_LEN(len: size_t): size_t;
begin
  Result := CMSG_ALIGN(SizeOf(cmsghdr)) + len;
end;

// netinet/net.h macros

function IN_CLASSA(a: in_addr_t): Boolean;
begin
  Result := ((a and $80000000) = 0);
end;

function IN_CLASSB(a: in_addr_t): Boolean;
begin
  Result := ((a and $c0000000) = $80000000);
end;

function IN_CLASSC(a: in_addr_t): Boolean;
begin
  Result := ((a and $e0000000) = $c0000000);
end;

function IN_CLASSD(a: in_addr_t): Boolean;
begin
  Result := ((a and $f0000000) = $e0000000);
end;

function IN_MULTICAST(a: in_addr_t): Boolean;
begin
  Result := IN_CLASSD(a);
end;

function IN_EXPERIMENTAL(a: in_addr_t): Boolean;
begin
  Result := ((a and $e0000000) = $e0000000);
end;

function IN_BADCLASS(a: in_addr_t): Boolean;
begin
  Result := ((a and $f0000000) = $f0000000);
end;


function IN6_IS_ADDR_UNSPECIFIED(const a: in6_addr): Boolean;
begin
  Result := (a.s6_addr32[0] = 0) and
            (a.s6_addr32[1] = 0) and
            (a.s6_addr32[2] = 0) and
            (a.s6_addr32[3] = 0);
end;

function IN6_IS_ADDR_LOOPBACK(const a: in6_addr): Boolean;
begin
  Result := (a.s6_addr32[0] = 0) and
            (a.s6_addr32[1] = 0) and
            (a.s6_addr32[2] = 0) and
            (a.s6_addr32[3] = htonl(1));
end;

function IN6_IS_ADDR_MULTICAST(const a: in6_addr): Boolean;
begin
  Result := (a.s6_addr[0] = $ff);
end;

function IN6_IS_ADDR_LINKLOCAL(const a: in6_addr): Boolean;
begin
  Result := ((a.s6_addr32[0] and htonl($ffc00000)) = htonl($fe800000));
end;

function IN6_IS_ADDR_SITELOCAL(const a: in6_addr): Boolean;
begin
  Result := ((a.s6_addr32[0] and htonl($ffc00000)) = htonl($fec00000))
end;

function IN6_IS_ADDR_V4MAPPED(const a: in6_addr): Boolean;
begin
  Result := (a.s6_addr32[0] = 0) and
            (a.s6_addr32[1] = 0) and
	    (a.s6_addr32[2] = htonl($ffff));
end;

function IN6_IS_ADDR_V4COMPAT(const a: in6_addr): Boolean;
begin
  Result := (a.s6_addr32[0] = 0) and
            (a.s6_addr32[1] = 0) and
	    (a.s6_addr32[2] = 0) and
            (ntohl(a.s6_addr32[3]) > 1);
end;

function IN6_ARE_ADDR_EQUAL(const a, b: in6_addr): Boolean;
begin
  Result := (a.s6_addr32[0] = b.s6_addr32[0]) and
            (a.s6_addr32[1] = b.s6_addr32[1]) and
            (a.s6_addr32[2] = b.s6_addr32[2]) and
            (a.s6_addr32[3] = b.s6_addr32[3]);
end;

function IN6_IS_ADDR_MC_NODELOCAL(const a: in6_addr): Boolean;
begin
  Result := IN6_IS_ADDR_MULTICAST(a) and
            ((a.s6_addr[1] and $f) = $1);
end;

function IN6_IS_ADDR_MC_LINKLOCAL(const a: in6_addr): Boolean;
begin
  Result := IN6_IS_ADDR_MULTICAST(a) and
            ((a.s6_addr[1] and $f) = $2);
end;

function IN6_IS_ADDR_MC_SITELOCAL(const a: in6_addr): Boolean;
begin
  Result := IN6_IS_ADDR_MULTICAST(a) and
            ((a.s6_addr[1] and $f) = $5);
end;

function IN6_IS_ADDR_MC_ORGLOCAL(const a: in6_addr): Boolean;
begin
  Result := IN6_IS_ADDR_MULTICAST(a) and
            ((a.s6_addr[1] and $f) = $8);
end;

function IN6_IS_ADDR_MC_GLOBAL(const a: in6_addr): Boolean;
begin
  Result := IN6_IS_ADDR_MULTICAST(a) and
            ((a.s6_addr[1] and $f) = $e);
end;

// netdb.h macros

function h_errno: Integer;
begin
  Result := __h_errno_location()^;
end;

function __set_h_errno(__err: Integer): Integer;
var
  h_errno_location: PInteger;
begin
  h_errno_location := __h_errno_location();
  Result := h_errno_location^;
  h_errno_location^ := __err;
end;

// socket.h macros

function FD_ISSET(fd: TFileDescriptor; var fdset: TFDSet): Boolean;
begin
  Result := (fdset.fds_bits[__FDELT(fd)] and __FDMASK(fd)) <> 0;
end;

procedure FD_SET(fd: TFileDescriptor; var fdset: TFDSet);
begin
  fdset.fds_bits[__FDELT(fd)] := fdset.fds_bits[__FDELT(fd)] or __FDMASK(fd);
end;

procedure FD_CLR(fd: TFileDescriptor; var fdset: TFDSet);
begin
  fdset.fds_bits[__FDELT(fd)] := fdset.fds_bits[__FDELT(fd)] and (not __FDMASK(fd));
end;

procedure FD_ZERO(var fdset: TFDSet);
var
  I: Integer;
begin
  with fdset do
    for I := Low(fds_bits) to High(fds_bits) do
      fds_bits[I] := 0;
end;

// time.h macros

{  Convenience macros for operations on timevals.
   NOTE: `timercmp' does not work for >= or <=.  }
function timerisset(const Value: TTimeVal): Boolean;
begin
  Result := (Value.tv_sec <> 0) or (Value.tv_usec <> 0);
end;

procedure timerclear(var Value: TTimeVal);
begin
  Value.tv_sec := 0;
  Value.tv_usec := 0;
end;

function __timercmp(const a, b: TTimeVal): Integer;
begin
  if a.tv_sec = b.tv_sec then
  begin
    if a.tv_usec > b.tv_usec then
      Result := 1
    else
    if a.tv_usec < b.tv_usec then
      Result := -1
    else
      Result := 0;
  end
  else
  begin
    if a.tv_sec > b.tv_sec then
      Result := 1
    else
      Result := -1;
  end;
end;

function timeradd(const a, b: TTimeVal): TTimeVal;
begin
  Result.tv_sec := a.tv_sec + b.tv_sec;
  Result.tv_usec := a.tv_usec + b.tv_usec;
  if Result.tv_usec >= 1000000 then
  begin
    Inc(Result.tv_sec);
    Dec(Result.tv_usec, 1000000);
  end;
end;

function timersub(const a, b: TTimeVal): TTimeVal;
begin
  Result.tv_sec := a.tv_sec - b.tv_sec;
  Result.tv_usec := a.tv_usec - b.tv_usec;
  if Result.tv_usec < 0 then
  begin
    Dec(Result.tv_sec);
    Inc(Result.tv_usec, 1000000);
  end;
end;

{  Macros for converting between `struct timeval' and `struct timespec'.  }
procedure TIMEVAL_TO_TIMESPEC(const tv: TTimeVal; var ts: TTimeSpec);
begin
  ts.tv_sec := tv.tv_sec;
  ts.tv_nsec := tv.tv_usec * 1000;
end;

procedure TIMESPEC_TO_TIMEVAL(var tv: TTimeVal; const ts: TTimeSpec);
begin
  tv.tv_sec := ts.tv_sec;
  tv.tv_usec := ts.tv_nsec div 1000;
end;

// sys/shm.h macros

function SHMLBA: Integer;
begin
  Result := __getpagesize();
end;

// sys/quota.h macros

function dbtob(num: Cardinal): Cardinal;
begin
  Result := num shl 10;
end;

function btodb(num: Cardinal): Cardinal;
begin
  Result := num shr 10;
end;

function fs_to_dq_blocks(num, blksize: Cardinal): quad_t;
begin
  Result := (num * blksize) div BLOCK_SIZE;
end;

function QCMD(cmd, _type: Cardinal): Cardinal;
begin
  Result := (cmd shl SUBCMDSHIFT) or (_type and SUBCMDMASK);
end;

function dqoff(UID: loff_t): quad_t;
begin
  Result := UID * SizeOf(dqblk);
end;

// libio.h macros

function _IO_getc_unlocked(_fp: PIOFile): Integer;
begin
  if _fp^._IO_read_ptr >= _fp^._IO_read_end then
    Result := __uflow(_fp)
  else
  begin
    Result := PByte(_fp^._IO_read_ptr)^;
    Inc(_fp^._IO_read_ptr);
  end;
end;

function _IO_peekc_unlocked(_fp: PIOFile): Integer;
begin
  if (_fp^._IO_read_ptr >= _fp^._IO_read_end) and (__underflow(_fp) = __EOF) then
    Result := __EOF
  else
    Result := PByte(_fp^._IO_read_ptr)^;
end;

function _IO_putc_unlocked(_ch: Char; _fp: PIOFile): Integer;
begin
  if _fp^._IO_write_ptr >= _fp^._IO_write_end then
    Result := __overflow(_fp, Byte(_ch))
  else
  begin
    Result := Byte(_ch);
    _fp^._IO_write_ptr^ := _ch;
    Inc(_fp^._IO_write_ptr);
  end;
end;

function _IO_getwc_unlocked(_fp: PIOFile): Integer;
begin
  if Cardinal(_fp^._wide_data^._IO_read_ptr) >= Cardinal(_fp^._wide_data^._IO_read_end) then
    Result := __wuflow(_fp)
  else
  begin
    Result := _fp^._wide_data^._IO_read_ptr^;
    Inc(_fp^._wide_data^._IO_read_ptr);
  end;
end;

function _IO_putwc_unlocked(_wch: wchar_t; _fp: PIOFile): Integer;
begin
  if Cardinal(_fp^._wide_data^._IO_write_ptr) >= Cardinal(_fp^._wide_data^._IO_write_end) then
    Result := __woverflow(_fp, _wch)
  else
  begin
    Result := _wch;
    _fp^._wide_data^._IO_write_ptr^ := _wch;
    Inc(_fp^._wide_data^._IO_write_ptr);
  end;
end;

function _IO_feof_unlocked(_fp: PIOFile): Integer;
begin
  Result := Ord((_fp^._flags and _IO_EOF_SEEN) <> 0);
end;

function _IO_ferror_unlocked(_fp: PIOFile): Integer;
begin
  Result := Ord((_fp^._flags and _IO_ERR_SEEN) <> 0);
end;

function _IO_PENDING_OUTPUT_COUNT(_fp: PIOFile): Integer;
begin
  Result := _fp^._IO_write_ptr - _fp^._IO_write_base;
end;

// Functions for use with getopt.h

function optarg: PChar;
var
  OptargSymbol: Pointer;
begin
  OptargSymbol := dlsym(RTLD_DEFAULT, 'optarg');
  if Assigned(OptargSymbol) then
    Result := PPChar(OptargSymbol)^
  else
    Result := nil;
end;

function optind: Integer;
var
  OptindSymbol: Pointer;
begin
  OptindSymbol := dlsym(RTLD_DEFAULT, 'optind');
  if Assigned(OptindSymbol) then
    Result := PInteger(OptindSymbol)^
  else
    Result := 0;
end;

procedure optind_Assign(Value: Integer);
var
  OptindSymbol: Pointer;
begin
  OptindSymbol := dlsym(RTLD_DEFAULT, 'optind');
  if Assigned(OptindSymbol) then
    PInteger(OptindSymbol)^ := Value;
end;

function opterr: Integer;
var
  OpterrSymbol: Pointer;
begin
  OpterrSymbol := dlsym(RTLD_DEFAULT, 'opterr');
  if Assigned(OpterrSymbol) then
    Result := PInteger(OpterrSymbol)^
  else
    Result := 0;
end;

procedure opterr_Assign(Value: Integer);
var
  OpterrSymbol: Pointer;
begin
  OpterrSymbol := dlsym(RTLD_DEFAULT, 'opterr');
  if Assigned(OpterrSymbol) then
    PInteger(OpterrSymbol)^ := Value;
end;

function optopt: Integer;
var
  OptoptSymbol: Pointer;
begin
  OptoptSymbol := dlsym(RTLD_DEFAULT, 'optopt');
  if Assigned(OptoptSymbol) then
    Result := PInteger(OptoptSymbol)^
  else
    Result := 0;
end;

// Functions for use with argp.h

function argp_program_version: PChar;
var
  ArgPProgramVersionSymbol: Pointer;
begin
  ArgPProgramVersionSymbol := dlsym(RTLD_DEFAULT, 'argp_program_version');
  if Assigned(ArgPProgramVersionSymbol) then
    Result := PPChar(ArgPProgramVersionSymbol)^
  else
    Result := nil;
end;

procedure argp_program_version_Assign(Value: PChar);
var
  ArgPProgramVersionSymbol: Pointer;
begin
  ArgPProgramVersionSymbol := dlsym(RTLD_DEFAULT, 'argp_program_version');
  if Assigned(ArgPProgramVersionSymbol) then
    PPChar(ArgPProgramVersionSymbol)^ := Value;
end;

function argp_program_version_hook: TArgPProgramVersionHook;
var
  ArgPProgramVersionHookSymbol: Pointer;
begin
  ArgPProgramVersionHookSymbol := dlsym(RTLD_DEFAULT, 'argp_program_version_hook');
  if Assigned(ArgPProgramVersionHookSymbol) then
    Result := TArgPProgramVersionHook(ArgPProgramVersionHookSymbol^)
  else
    Result := nil;
end;

procedure argp_program_version_hook_Assign(Value: TArgPProgramVersionHook);
var
  ArgPProgramVersionHookSymbol: Pointer;
begin
  ArgPProgramVersionHookSymbol := dlsym(RTLD_DEFAULT, 'argp_program_version_hook');
  if Assigned(ArgPProgramVersionHookSymbol) then
    TArgPProgramVersionHook(ArgPProgramVersionHookSymbol^) := Value;
end;

function argp_program_bug_address: PChar;
var
  ArgPProgramBugAddressSymbol: Pointer;
begin
  ArgPProgramBugAddressSymbol := dlsym(RTLD_DEFAULT, 'argp_program_bug_address');
  if Assigned(ArgPProgramBugAddressSymbol) then
    Result := PPChar(ArgPProgramBugAddressSymbol)^
  else
    Result := nil;
end;

procedure argp_program_bug_address_Assign(Value: PChar);
var
  ArgPProgramBugAddressSymbol: Pointer;
begin
  ArgPProgramBugAddressSymbol := dlsym(RTLD_DEFAULT, 'argp_program_bug_address');
  if Assigned(ArgPProgramBugAddressSymbol) then
    PPChar(ArgPProgramBugAddressSymbol)^ := Value;
end;

function argp_err_exit_status: error_t;
type
  Perror_t = ^error_t;
var
  ArgPErrExitStatus: Pointer;
begin
  ArgPErrExitStatus := dlsym(RTLD_DEFAULT, 'argp_err_exit_status');
  if Assigned(ArgPErrExitStatus) then
    Result := Perror_t(ArgPErrExitStatus)^
  else
    Result := 0;
end;

procedure argp_err_exit_status_Assign(Value: error_t);
type
  Perror_t = ^error_t;
var
  ArgPErrExitStatus: Pointer;
begin
  ArgPErrExitStatus := dlsym(RTLD_DEFAULT, 'argp_err_exit_status');
  if Assigned(ArgPErrExitStatus) then
    Perror_t(ArgPErrExitStatus)^ := Value;
end;


// Macros from sys/ttydefaults.h

function CTRL(x: Char): Char;
begin
  Result := Char(Ord(x) and $1F);
end;

// Macros from termios.h

function CCEQ(val, c: cc_t): Boolean;
begin
  Result := (c = val) and (val <> _POSIX_VDISABLE);
end;

// Functions for regex.h

procedure re_syntax_options_Assign(const Value: reg_syntax_t);
type
  Preg_syntax_t = ^reg_syntax_t;
var
  re_syntax_options_Symbol: Pointer;
begin
  re_syntax_options_Symbol := dlsym(RTLD_DEFAULT, 're_syntax_options');
  if Assigned(re_syntax_options_Symbol) then
    Preg_syntax_t(re_syntax_options_Symbol)^ := Value;
end;

function re_syntax_options: reg_syntax_t;
type
  Preg_syntax_t = ^reg_syntax_t;
var
  re_syntax_options_Symbol: Pointer;
begin
  re_syntax_options_Symbol := dlsym(RTLD_DEFAULT, 're_syntax_options');
  if Assigned(re_syntax_options_Symbol) then
    Result := Preg_syntax_t(re_syntax_options_Symbol)^
  else
    FillChar(Result, SizeOf(Result), 0);
end;

// Macros from net/ethernet.h

function ETHER_IS_VALID_LEN(foo: Cardinal): Boolean;
begin
  Result := (foo >= ETHER_MIN_LEN) and (foo <= ETHER_MAX_LEN);
end;

function RT_ADDRCLASS(flags: u_int32_t): u_int32_t;
begin
  Result := flags shr 23;
end;

function RT_TOS(tos: Integer): Integer;
begin
  Result := tos and IPTOS_TOS_MASK;
end;

function RT_LOCALADDR(flags: u_int32_t): Boolean;
begin
  Result := (flags and RTF_ADDRCLASSMASK) = (RTF_LOCAL or RTF_INTERFACE);
end;

procedure ETHER_MAP_IP_MULTICAST(const ipaddr: in_addr; enaddr: PEthernetAddress);
begin
  enaddr^[0] := $01;
  enaddr^[1] := $00;
  enaddr^[2] := $5e;
  enaddr^[3] := ipaddr.S_un_b.s_b2 and $7f;
  enaddr^[4] := ipaddr.S_un_b.s_b3;
  enaddr^[5] := ipaddr.S_un_b.s_b4;
end;

function ICMP6_FILTER_WILLPASS(__type: Integer; const filterp: TICMP6_Filter): Boolean;
begin
  Result := (filterp.data[__type shr 5] and (1 shl (__type and 31))) = 0;
end;

function ICMP6_FILTER_WILLBLOCK(__type: Integer; const filterp: TICMP6_Filter): Boolean;
begin
  Result := (filterp.data[__type shr 5] and (1 shl (__type and 31))) <> 0;
end;

procedure ICMP6_FILTER_SETPASS(__type: Integer; var filterp: TICMP6_Filter);
begin
  filterp.data[__type shr 5] := filterp.data[__type shr 5] and not
                                      (1 shl (__type and 31));
end;

procedure ICMP6_FILTER_SETBLOCK(__type: Integer; var filterp: TICMP6_Filter);
begin
  filterp.data[__type shr 5] := filterp.data[__type shr 5] or
                                      (1 shl (__type and 31));
end;

procedure ICMP6_FILTER_SETPASSALL(var filterp: TICMP6_Filter);
begin
  FillChar(filterp, SizeOf(filterp), 0);
end;

procedure ICMP6_FILTER_SETBLOCKALL(var filterp: TICMP6_Filter);
begin
  FillChar(filterp, SizeOf(filterp), $FF);
end;

function IPTOS_TOS(tos: Integer): Integer;
begin
  Result := tos and IPTOS_TOS_MASK;
end;

function IPTOS_PREC(tos: Integer): Integer;
begin
  Result := tos and IPTOS_PREC_MASK;
end;

function IPOPT_COPIED(o: Integer): Integer;
begin
  Result := o and IPOPT_COPY;
end;

function IPOPT_CLASS(o: Integer): Integer;
begin
  Result := o and IPOPT_CLASS_MASK;
end;

function IPOPT_NUMBER(o: Integer): Integer;
begin
  Result := o and IPOPT_NUMBER_MASK;
end;


function PPPIOCGFLAGS: Cardinal;
begin
  Result := __IOR(Ord('t'), 90, SizeOf(Integer));
end;

function PPPIOCSFLAGS: Cardinal;
begin
  Result := __IOW(Ord('t'), 89, SizeOf(Integer));
end;

function PPPIOCGASYNCMAP: Cardinal;
begin
  Result := __IOR(Ord('t'), 88, SizeOf(Integer));
end;

function PPPIOCSASYNCMAP: Cardinal;
begin
  Result := __IOW(Ord('t'), 87, SizeOf(Integer));
end;

function PPPIOCGUNIT: Cardinal;
begin
  Result := __IOR(Ord('t'), 86, SizeOf(Integer));
end;

function PPPIOCGRASYNCMAP: Cardinal;
begin
  Result := __IOR(Ord('t'), 85, SizeOf(Integer));
end;

function PPPIOCSRASYNCMAP: Cardinal;
begin
  Result := __IOW(Ord('t'), 84, SizeOf(Integer));
end;

function PPPIOCGMRU: Cardinal;
begin
  Result := __IOR(Ord('t'), 83, SizeOf(Integer));
end;

function PPPIOCSMRU: Cardinal;
begin
  Result := __IOW(Ord('t'), 82, SizeOf(Integer));
end;

function PPPIOCSMAXCID: Cardinal;
begin
  Result := __IOW(Ord('t'), 81, SizeOf(Integer));
end;

function PPPIOCGXASYNCMAP: Cardinal;
begin
  Result := __IOR(Ord('t'), 80, SizeOf(ext_accm));
end;

function PPPIOCSXASYNCMAP: Cardinal;
begin
  Result := __IOW(Ord('t'), 79, SizeOf(ext_accm));
end;

function PPPIOCXFERUNIT: Cardinal;
begin
  Result := _IO(Ord('t'), 78);
end;

function PPPIOCSCOMPRESS: Cardinal;
begin
  Result := __IOW(Ord('t'), 77, SizeOf(ppp_option_data));
end;

function PPPIOCGNPMODE: Cardinal;
begin
  Result := __IOWR(Ord('t'), 76, SizeOf(npioctl));
end;

function PPPIOCSNPMODE: Cardinal;
begin
  Result := __IOW(Ord('t'), 75, SizeOf(npioctl));
end;

function PPPIOCGDEBUG: Cardinal;
begin
  Result := __IOR(Ord('t'), 65, SizeOf(Integer));
end;

function PPPIOCSDEBUG: Cardinal;
begin
  Result := __IOW(Ord('t'), 64, SizeOf(Integer));
end;

function PPPIOCGIDLE: Cardinal;
begin
  Result := __IOR(Ord('t'), 63, SizeOf(ppp_idle));
end;

// Macros for ip_icmp.h

function ICMP_ADVLEN(const p: icmp): Cardinal;
var
  HeaderLength: Cardinal;
begin
  HeaderLength := p.icmp_dun.id_ip.idi_ip.__bitfield and $F; // Lower four bits
  Result := (8 + (HeaderLength shl 2) + 8);
end;

function ICMP_INFOTYPE(__type: Cardinal): Boolean;
begin
  Result := (__type = ICMP_ECHOREPLY) or (__type = ICMP_ECHO) or
            (__type = ICMP_ROUTERADVERT) or (__type = ICMP_ROUTERSOLICIT) or
            (__type = ICMP_TSTAMP) or (__type = ICMP_TSTAMPREPLY) or
            (__type = ICMP_IREQ) or (__type = ICMP_IREQREPLY) or
            (__type = ICMP_MASKREQ) or (__type = ICMP_MASKREPLY);
end;

// Macros for sys/raw.h

function RAW_SETBIND: Cardinal;
begin
  Result := _IO($ac, 0);
end;

function RAW_GETBIND: Cardinal;
begin
  Result := _IO($ac, 1);
end;

// Definitions for pthread.h

function real_pthread_cond_timedwait(var Cond: TCondVar;
  var Mutex: TRTLCriticalSection; const AbsTime: TTimeSpec): Integer; cdecl;
  external libpthreadmodulename name 'pthread_cond_timedwait';

{ Because of an oddity in the implementation of pthread_cond_timedwait
  which modifies the FPU control word, protect the FPU control
  against any changes. }
function pthread_cond_timedwait(var Cond: TCondVar;
  var Mutex: TRTLCriticalSection; const AbsTime: TTimeSpec): Integer; cdecl;
var
  FpuCW: Word;
begin
  FpuCW := Get8087CW;
  try
    Result := real_pthread_cond_timedwait(Cond, Mutex, AbsTime);
  finally
    Set8087CW(FpuCW);
  end;
end;

end.

