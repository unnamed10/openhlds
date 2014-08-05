unit BZip2;

{$I HLDS.inc}

interface

uses Default;

const
 {$IFDEF MSWINDOWS}
 bz2lib = 'bzip2.dll';
 {$ELSE}
 bz2lib = 'libbz2.so.1';
 {$ENDIF}
 
 BZIP2_TAG = Ord('B') + Ord('Z') shl 8 + Ord('2') shl 16;

 BZ_OK = 0;
 BZ_RUN_OK = 1;
 BZ_FLUSH_OK = 2;
 BZ_FINISH_OK = 3;
 BZ_STREAM_END = 4;
 BZ_SEQUENCE_ERROR = -1;
 BZ_PARAM_ERROR = -2;
 BZ_MEM_ERROR = -3;
 BZ_DATA_ERROR = -4;
 BZ_DATA_ERROR_MAGIC = -5;
 BZ_IO_ERROR = -6;
 BZ_UNEXPECTED_EOF = -7;
 BZ_OUTBUFF_FULL = -8;
 BZ_CONFIG_ERROR = -9;

function BZ2_bzBuffToBuffCompress(dest: PByte; destLen: PUInt32; source: PByte; sourceLen: UInt32; blockSize100k, verbosity, workFactor: Int32): Int32; cdecl; external bz2lib;
function BZ2_bzBuffToBuffDecompress(dest: PByte; destLen: PUInt32; source: PByte; sourceLen: UInt32; small, verbosity: Int32): Int32 cdecl; external bz2lib;
function BZ2_bzlibVersion: PLChar; cdecl; external bz2lib;

implementation

end.
