unit SDK;

{$I HLDS.inc}

interface
                                                                                              
uses Default;

{$MinEnumSize 4}

const
 ProjectName = 'OpenHLDS';
 ProjectBuild = 10001;
 ProjectVersion = '1.01';

const
 MAX_PLAYERS = 32;

 INVALID_HANDLE_VALUE = {$IFDEF MSWINDOWS}THandle(-1){$ELSE}Pointer(nil){$ENDIF};

 MAX_CMD_ARGS = 80;
 MAX_ARGS = 80;

 MAX_CONFIG_SIZE = 1024*256; // in KB

 MAX_MAP_NAME = 64;

 DEFAULT_GAME = 'valve';

 HUNK_NAME_SIZE = 64;
 CACHE_NAME_SIZE = 64;

 MAX_ALIAS_NAME = 32;

 FCMD_CLIENT = 1;
 FCMD_GAME = 2;
 FCMD_WRAPPER = 4;
 
 // FS
 INVALID_FILE_HANDLE = 0;
 INVALID_FIND_HANDLE = Pointer(-1);
  
 MAX_PATH = 260 deprecated;

 {$IFDEF MSWINDOWS}
 MAX_PATH_A = 260;
 MAX_PATH_W = 32768;
 {$ELSE}
 MAX_PATH_A = 260; // For compatibility reasons
 MAX_PATH_W = 4096;
 {$ENDIF}

 {$IFDEF MSWINDOWS}
  CorrectSlash = '\';
  IncorrectSlash = '/';
 {$ELSE}
  CorrectSlash = '/';
  IncorrectSlash = '\';
 {$ENDIF}

 // Models

 MAX_MODEL_NAME = 64;
 
 MAX_MAP_LEAFS = 8192;

 // contents are confirmed
 CONTENTS_EMPTY = -1;
 CONTENTS_SOLID = -2;
 CONTENTS_WATER = -3;
 CONTENTS_SLIME = -4;
 CONTENTS_LAVA = -5;
 CONTENTS_SKY = -6;
 CONTENTS_ORIGIN = -7;
 CONTENTS_CLIP = -8;
 CONTENTS_CURRENT_0 = -9;
 CONTENTS_CURRENT_90 = -10;
 CONTENTS_CURRENT_180 = -11;
 CONTENTS_CURRENT_270 = -12;
 CONTENTS_CURRENT_UP = -13;
 CONTENTS_CURRENT_DOWN = -14;
 CONTENTS_TRANSLUCENT = -15;
 CONTENTS_LADDER = -16;

 RT_SOUND = 0;
 RT_SKIN = 1;
 RT_MODEL = 2;
 RT_DECAL = 3;
 RT_GENERIC = 4;
 RT_EVENTSCRIPT = 5;
 RT_WORLD = 6;

 // Resources

 MAX_RESOURCE_NAME = 64;

 // WAD

 MAX_LUMP_NAME = 16;
 MIPLEVELS = 4;

 MAX_DECAL_NAMES = 512;

 TYP_NONE = 0;
 TYP_LABEL = 1;
 TYP_LUMPY = 64;
 TYP_PALETTE = 64;
 TYP_QTEX = 65;
 TYP_QPIC = 66;
 TYP_SOUND = 67;
 TYP_MIPTEX = 68;


 // --------
 MAX_CONSISTENCY = 512;

 MAX_LIGHTSTYLES = 64; // cf

 // msgs

 MSG_BROADCAST = 0;
 MSG_ONE = 1;
 MSG_ALL = 2;
 MSG_INIT = 3;
 MSG_PVS = 4;
 MSG_PAS = 5;
 MSG_PVS_R = 6;
 MSG_PAS_R = 7;
 MSG_ONE_UNRELIABLE = 8;
 MSG_SPEC = 9;

 //
 MAX_LOG_FILES = 5000;


 MAX_MODELS = 512;
 MAX_SOUNDS = 512;
 MAX_SOUNDHASH = MAX_SOUNDS * 2 - 1;

 MAX_GENERIC_ITEMS = 512;

 CVOXFILESENTENCEMAX = 1536;
 
 MAX_PACKET_ENTITIES = 256;

 SND_VOLUME = 1;
 SND_ATTN = 2;
 SND_LONG_INDEX = 4;
 SND_PITCH = 8;
 SND_SENTENCE = 16;

 SND_STOP = 32;
 SND_CHANGE_VOL = 64;
 SND_CHANGE_PITCH = 128;
 SND_SPAWNING = 256; // 9 bits

 MULTICAST_ALL = 1;
 MULTICAST_PVS = 2;
 MULTICAST_PAS = 4;
 MULTICAST_SKIP_SENDER = 128; // skip 

 CHAN_AUTO = 0;
 CHAN_WEAPON = 1;
 CHAN_VOICE = 2;
 CHAN_ITEM = 3;
 CHAN_BODY = 4;
 CHAN_STREAM = 5;
 CHAN_STATIC = 6;
 CHAN_NETWORKVOICE_BASE = 7;
 CHAN_NETWORKVOICE_END = 500;

 ATTN_NONE = 0;
 ATTN_NORM = 0.8;
 ATTN_IDLE = 2;
 ATTN_STATIC = 1.25;
 
 PITCH_NORM = 100;
 PITCH_LOW = 95;
 PITCH_HIGH = 120;

 MAX_USER_MESSAGE = 256;

 ENTITY_NORMAL = 1 shl 0;
 ENTITY_BEAM = 1 shl 1;

 MAX_INFO_STRING = 256;

 MAX_RESOURCES = 1280;

 CMD_MAXBACKUP = 30;

 IN_ATTACK = 1 shl 0;
 IN_JUMP = 1 shl 1;
 IN_DUCK = 1 shl 2;
 IN_FORWARD = 1 shl 3;
 IN_BACK = 1 shl 4;
 IN_USE = 1 shl 5;
 IN_CANCEL = 1 shl 6;
 IN_LEFT = 1 shl 7;
 IN_RIGHT = 1 shl 8;
 IN_MOVELEFT = 1 shl 9;
 IN_MOVERIGHT = 1 shl 10;
 IN_ATTACK2 = 1 shl 11;
 IN_RUN = 1 shl 12;
 IN_RELOAD = 1 shl 13;
 IN_ALT1 = 1 shl 14;
 IN_SCORE = 1 shl 15;                                   

{$UNDEF MSME}
{$UNDEF MSMW}

type
 PVec3 = ^TVec3;
 TVec3 = packed array[0..2] of Single;
 {$IF SizeOf(TVec3) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TVec3.'} {$DEFINE MSME} {$IFEND}

 PStringOfs = ^TStringOfs;
 TStringOfs = UInt32; // 4, compatibility reasons
 {$IF SizeOf(TStringOfs) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TStringOfs.'} {$DEFINE MSME} {$IFEND}

 PModInfo = ^TModInfo;    
 TModInfo = record
  CustomGame: Boolean;
  URLInfo, URLDownload: array[1..256] of LChar; // 4, 260
  HLVersion: array[1..32] of LChar; // 516
  Version, Size: UInt;
  SVOnly, ClientDLL, Secure: Boolean; // 548
  GameType: (gtUnknown = 0, gtSingleplayer, gtMultiplayer);
 end;

 PMemoryBlock = ^TMemoryBlock;
 TMemoryBlock = record
  Size: UInt;
  Tag: Int32; // 32 bits
  ID: UInt32; // 32 bits
  Next, Prev: PMemoryBlock;
  Padding: Int32; // 32 bits
 end;

 PMemoryZone = ^TMemoryZone;
 TMemoryZone = record
  Size: UInt;
  BlockList: TMemoryBlock; // +4
  Rover: PMemoryBlock; // +28
 end;

 PHunk = ^THunk;
 THunk = record
  ID: Int32;
  Size: UInt;
  Name: array[1..HUNK_NAME_SIZE] of LChar;
 end;

 PCacheUser = ^TCacheUser;
 TCacheUser = record
  Data: Pointer;
 end;

 PCacheSystem = ^TCacheSystem;
 TCacheSystem = record
  Size: UInt;
  User: PCacheUser;
  Name: array[1..CACHE_NAME_SIZE] of LChar;
  Prev, Next, LRUPrev, LRUNext: PCacheSystem;
 end;

 TCmdFunction = procedure cdecl;
 TCmdSource = (csClient = 0, csServer);

 PCommand = ^TCommand;
 TCommand = record
  Next: PCommand;
  Name: PLChar; 
  Callback: TCmdFunction;
  Flags: UInt32;
 end;
 {$IF SizeOf(TCommand) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TCommand.'} {$DEFINE MSME} {$IFEND}

                         //1                              // 4
 TCVarFlags = set of (FCVAR_ARCHIVE = 0, FCVAR_USERINFO, FCVAR_SERVER, FCVAR_EXTDLL,
                      FCVAR_CLIENTDLL, FCVAR_PROTECTED, FCVAR_SPONLY, FCVAR_PRINTABLEONLY,
                      FCVAR_UNLOGGED, __FCVAR_PADDING = 31);
 {$IF SizeOf(TCVarFlags) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TCVarFlags.'} {$DEFINE MSME} {$IFEND}

 PCVar = ^TCVar;
 TCVar = record
  Name, Data: PLChar;
  Flags: TCVarFlags;
  Value: Single;
  Next: PCVar;
 end;
 {$IF SizeOf(TCVar) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TCVar.'} {$DEFINE MSME} {$IFEND}

 PAlias = ^TAlias;
 TAlias = record
  Next: PAlias;
  Name: array[1..MAX_ALIAS_NAME] of LChar;
  Command: PLChar;
 end;
 {$IF SizeOf(TAlias) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TAlias.'} {$DEFINE MSME} {$IFEND}

 // dp NET_GetLong
 // can be changed
 PSizeBuf = ^TSizeBuf;
 TSizeBuf = record
  Name: PLChar;
  AllowOverflow: set of (FSB_ALLOWOVERFLOW = 0, FSB_OVERFLOWED, __FSB_PADDING = 15); // 16bit boundary
  Data: Pointer;
  MaxSize: UInt32;
  CurrentSize: UInt32;
 end;
 {$IF SizeOf(TSizeBuf) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TSizeBuf.'} {$DEFINE MSME} {$IFEND}

 // COM_LoadFile
 TFileAllocType = (FILE_ALLOC_ZONE = 0, FILE_ALLOC_HUNK, FILE_ALLOC_TEMP_HUNK, FILE_ALLOC_CACHE,
                   FILE_ALLOC_LOADBUF, FILE_ALLOC_MEMORY);

 PUserCmd = ^TUserCmd;
 TUserCmd = packed record
  LerpMSec: Int16; // 0
  MSec: Byte; // 2
  __Padding1: Byte;
  ViewAngles: TVec3; // 4
  ForwardMove, SideMove, UpMove: Single; // 16 20 24
  LightLevel: Byte; // +28
  __Padding2: Byte;
  Buttons: UInt16; // +30 cf
  Impulse, WeaponSelect: Byte; // 32, 33
  __Padding3, __Padding4: Byte; // 34, 35
  ImpactIndex: Int32; // 36
  ImpactPosition: TVec3; // 40
 end;
 TUserCmdArray = array[0..0] of TUserCmd;
 PUserCmdArray = ^TUserCmdArray;
 {$IF SizeOf(TUserCmd) <> 52} {$MESSAGE WARN 'Structure size mismatch @ TUserCmd.'} {$DEFINE MSME} {$IFEND}

 PRGBColor = ^TRGBColor;
 TRGBColor = packed record
  R, G, B: Byte;
 end;
 {$IF SizeOf(TRGBColor) <> 3} {$MESSAGE WARN 'Structure size mismatch @ TRGBColor.'} {$DEFINE MSME} {$IFEND}

 PResourceInfo = ^TResourceInfo;
 TResourceInfo = record
  Info: array[0..7] of record
   Size: UInt32;
  end;
 end;
 {$IF SizeOf(TResourceInfo) <> 32} {$MESSAGE WARN 'Structure size mismatch @ TResourceInfo.'} {$DEFINE MSMW} {$IFEND}

 TResourceFlags = set of (RES_FATALIFMISSING, RES_WASMISSING, RES_CUSTOM, RES_REQUESTED, RES_PRECACHED, RES_ALWAYS, RES_PADDING, RES_CHECKFILE);
 {$IF SizeOf(TResourceFlags) <> 1} {$MESSAGE WARN 'Structure size mismatch @ TResourceFlags.'} {$DEFINE MSMW} {$IFEND}

 PResource = ^TResource;
 TResource = packed record // 136
  Name: array[1..MAX_RESOURCE_NAME] of LChar; // 0
  ResourceType: UInt32; // 64
  Index, DownloadSize: UInt32; // 68, 72
  Flags: TResourceFlags; // +76, byte cf
  MD5Hash: array[1..16] of LChar; // +77 cf , in consistency = 81
  PlayerNum: Int8; // +93 signed
  Reserved: array[1..32] of LChar; // +94 cf
  __Padding1, __Padding2: Byte;
  Next, Prev: PResource; // +128, +132, confirmed
 end;
 {$IF SizeOf(TResource) <> 136} {$MESSAGE WARN 'Structure size mismatch @ TResource.'} {$DEFINE MSMW} {$IFEND}

 PPCustomization = ^PCustomization;
 PCustomization = ^TCustomization;
 TCustomization = packed record
  InUse: Boolean; // +0
  __Padding1, __Padding2, __Padding3: Byte;
  Resource: TResource; // +4
  Translated: Boolean; // +140
  __Padding4, __Padding5, __Padding6: Byte;
  UserData1, UserData2: Int32; // +144, +148
  Info, Buffer: Pointer; // +152, +156
  Next: PCustomization; // +160
 end;
 {$IF SizeOf(TCustomization) <> 164} {$MESSAGE WARN 'Structure size mismatch @ TCustomization.'} {$DEFINE MSMW} {$IFEND}

 // WAD File

const
 WAD2_TAG = Ord('W') + Ord('A') shl 8 + Ord('D') shl 16 + Ord('2') shl 24;
 WAD3_TAG = Ord('W') + Ord('A') shl 8 + Ord('D') shl 16 + Ord('3') shl 24;

type
 PQPic = ^TQPic;
 TQPic = record
  Width, Height: UInt32;
  Data: array[1..4] of UInt8;
 end;
 {$IF SizeOf(TQPic) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TQPic.'} {$DEFINE MSME} {$IFEND}

 PWADFileHeader = ^TWADFileHeader;
 TWADFileHeader = packed record
  FileTag: array[1..4] of LChar; // WAD3
  NumEntries, FileOffset: UInt32;
 end;
 {$IF SizeOf(TWADFileHeader) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TWADFileHeader.'} {$DEFINE MSME} {$IFEND}

 PWADFileLump = ^TWADFileLump; // 32, confirmed
 TWADFileLump = packed record
  FilePos, DiskSize, Size: UInt32; // size confirmed
  LumpType, Compression: Byte;
  __Padding: UInt16;
  Name: array[1..MAX_LUMP_NAME] of LChar; // confirmed
 end;
 TWADFileLumpArray = array[0..0] of TWADFileLump;
 {$IF SizeOf(TWADFileLump) <> 32} {$MESSAGE WARN 'Structure size mismatch @ TWADFileLump.'} {$DEFINE MSME} {$IFEND}

 PMiptex = ^TMiptex; // 40. confirmed on i686.          is miptex_t.
 TMiptex = record
  Name: array[1..MAX_LUMP_NAME] of LChar;
  Width, Height: UInt32;
  Offsets: array[0..MIPLEVELS - 1] of UInt32;
 end;
 {$IF SizeOf(TMiptex) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TMiptex.'} {$DEFINE MSME} {$IFEND}

 PWADPalette = ^TWADPalette;
 TWADPalette = packed array[Byte] of TRGBColor;
 {$IF SizeOf(TWADPalette) <> 768} {$MESSAGE WARN 'Structure size mismatch @ TWADPalette.'} {$DEFINE MSMW} {$IFEND}

 PWADListEntry = ^TWADListEntry;
 TWADListEntry = packed record // 48 for sure
  Loaded: Boolean; // 0. confirmed
  __Padding1, __Padding2, __Padding3: Byte;
  Name: array[1..32] of LChar; // 4. confirmed
  NumEntries: UInt32; // 36
  Entries: ^TWADFileLumpArray; // 40
  Data: PWADFileHeader; // 44, confirmed
 end;
 {$IF SizeOf(TWADListEntry) <> 48} {$MESSAGE WARN 'Structure size mismatch @ TWADListEntry.'} {$DEFINE MSMW} {$IFEND}

 // WAD Cache

 PTexture = ^TTexture; // 64
 TTexture = record
  Name: array[1..MAX_LUMP_NAME] of LChar; // confirmed
  Width, Height: UInt32; // confirmed
  AnimTotal, AnimMin, AnimMax: Int32; // 24, 28, 32
  AnimNext, AlternateAnims: PTexture; // 36 and 40
  Offsets: array[0..MIPLEVELS - 1] of UInt32;
  PaletteOffset: UInt32; // confirmed
 end;
 TTextureArray = array[0..0] of TTexture;
 PTextureArray = array[0..0] of PTexture;
 {$IF SizeOf(TTexture) <> 64} {$MESSAGE WARN 'Structure size mismatch @ TTexture.'} {$DEFINE MSMW} {$IFEND}

 PCacheWADData = ^TCacheWADData; // 68, confirmed
 TCacheWADData = record
  Name: array[1..64] of LChar; // +0. confirmed, i guess
  CacheUser: TCacheUser; // confirmed
 end;
 TCacheWADDataArray = array[0..0] of TCacheWADData;
 {$IF SizeOf(TCacheWADData) <> 68} {$MESSAGE WARN 'Structure size mismatch @ TCacheWADData.'} {$DEFINE MSMW} {$IFEND}

 PWADDecal = ^TWADDecal; // 12, confirmed
 TWADDecal = record
  Lump: PWADFileLump;
  Custom: Boolean;
  Next: PWADDecal;
 end;
 {$IF SizeOf(TWADDecal) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TWADDecal.'} {$DEFINE MSMW} {$IFEND}

 TCacheWADNameList = array[0..1] of PLChar;
 TCacheWADCustomDecalArray = array[0..0] of LongBool;

 PCacheWAD = ^TCacheWAD; // 44
 TCacheWAD = record
  Name: PLChar; // +0, confirmed
  Cache: ^TCacheWADDataArray; // +4, confirmed
  ItemsCount: UInt32; // +8. confirmed, total amount of allocated cache entries
  ItemsTotal: UInt32; // +12, confirmed, total amount of cache entries
  Decals: ^TWADFileLumpArray; // +16, confirmed
  DecalCount: UInt32; // +20. confirmed (it's actually a lump count)

  // seems that it's a difference between file and memory WAD texture structures
  ExtraOffset: UInt32; // +24. this adds to the decal size; unsure about it though...

  // should only be called from native code
  LoadCallback: procedure(const WAD: PCacheWAD; const Data: Pointer); // +28
  NameCount: Int32; // +32, total entries in PathData
  NameList: ^TCacheWADNameList; // +36, contains file names or something

  CustomDecals: ^TCacheWADCustomDecalArray; // +40, capacity is set to total items count
 end;
 {$IF SizeOf(TCacheWAD) <> 44} {$MESSAGE WARN 'Structure size mismatch @ TCacheWAD.'} {$DEFINE MSMW} {$IFEND}

 PMModelPalette = ^TMModelPalette;
 TMModelPalette = packed record
  R, G, B, A: UInt16;
 end;
 {$IF SizeOf(TMModelPalette) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TMModelPalette.'} {$DEFINE MSME} {$IFEND}

 PDModelPalette = ^TDModelPalette;
 TDModelPalette = packed record
  R, G, B: Byte;
 end;
 {$IF SizeOf(TDModelPalette) <> 3} {$MESSAGE WARN 'Structure size mismatch @ TDModelPalette.'} {$DEFINE MSME} {$IFEND}

const
 // yep, it's in Model.pas
 // WADFileTexture is miptex
 DECAL_EXTRAOFFSET = SizeOf(TTexture) - SizeOf(TMiptex);

// Encode.pas

type
 PCRC = ^TCRC;
 TCRC = UInt32;

 PMD5HashStr = ^TMD5HashStr;
 TMD5HashStr = array[1..33] of LChar; // dp @ resource lists
 {$IF SizeOf(TMD5HashStr) <> 33} {$MESSAGE WARN 'Structure size mismatch @ TMD5HashStr.'} {$DEFINE MSME} {$IFEND}

 PMD5Array16 = ^TMD5Array16;
 TMD5Array16 = array[1..16] of UInt32;
 {$IF SizeOf(TMD5Array16) <> 64} {$MESSAGE WARN 'Structure size mismatch @ TMD5Array16.'} {$DEFINE MSMW} {$IFEND}

 PMD5Hash = ^TMD5Hash;
 TMD5Hash = array[1..4] of UInt32;
 {$IF SizeOf(TMD5Hash) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TMD5Hash.'} {$DEFINE MSME} {$IFEND}

 PMD5Context = ^TMD5Context;
 TMD5Context = packed record
  Buffer: TMD5Hash;
  Bits: array[1..2] of UInt32;
  Input: TMD5Array16;
 end;



// FileSystem

type
 PFile = ^TFile;
 TFile = Pointer;

 PFileFindHandle = ^TFileFindHandle;
 TFileFindHandle = Pointer;

 TFileSeekType = (SEEK_SET = 0, SEEK_CURRENT, SEEK_END);

 TFileWarningLevel = (FSW_WARNING = -1, FSW_SILENT = 0, FSW_REPORT_UNCLOSED,
                      FSW_REPORT_USAGE, FSW_REPORT_ALL_ACCESS, FSW_REPORT_ALL_ACCESS_READ,
                      FSW_REPORT_ALL_ACCESS_READ_WRITE);

 TFileSystemInput = record
  MemAlloc: function(Size: UInt): Pointer; 
  MemFree: procedure(P: Pointer);
  Warning: procedure(Data: PLChar);

  AddCommand: procedure(Name: PLChar; Func: TCmdFunction);
  RegisterVariable: procedure(var C: TCVar);
 end;

 PFileSystem = ^TFileSystem;
 TFileSystem = record
  Init, Shutdown: procedure;
  
  RemoveAllSearchPaths: procedure;
  AddSearchPath, AddSearchPathNoWrite: procedure(Path, Name: PLChar; AddToBase: Boolean);
  RemoveSearchPath: function(Path, Name: PLChar): Boolean;
  SearchListInitialized: function: Boolean;  

  IsAbsolutePath: function(Name: PLChar): Boolean;
  RemoveFile: function(Name, PathID: PLChar; RemoveReadOnly: Boolean): Boolean;
  CreateDirHierarchy: procedure(Name, PathID: PLChar);

  FileExists: function(Name: PLChar; PathID: PLChar): Boolean;
  IsDirectory: function(Name: PLChar; PathID: PLChar): Boolean;

  OpenPathID: function(out F: TFile; Name, Options, PathID: PLChar): Boolean;
  Open: function(out F: TFile; Name, Options: PLChar): Boolean;
  Close: procedure(F: TFile);

  Seek: function(F: TFile; Offset: Int64; SeekType: TFileSeekType): Boolean;
  Tell: function(F: TFile): Int64;
  Size: function(F: TFile): Int64;
  SizeByName: function(Name: PLChar; PathID: PLChar): Int64;
  GetFileTime: function(Name: PLChar; PathID: PLChar): Int64;

  IsOK: function(F: TFile): Boolean;
  Flush: procedure(F: TFile);
  EndOfFile: function(F: TFile): Boolean;

  Read: function(F: TFile; Buffer: Pointer; Size: UInt): UInt;
  Write: function(F: TFile; Buffer: Pointer; Size: UInt): UInt;

  ReadLine: function(F: TFile; Buffer: Pointer; MaxChars: UInt): PLChar;
  WriteLine: procedure(F: TFile; S: PLChar; NeedLineBreak: Boolean);

  FPrintF: function(F: TFile; S: PLChar; NeedLineBreak: Boolean): UInt;

  FindFirst: function(Name: PLChar; out H: TFileFindHandle): PLChar;
  FindNext: function(H: TFileFindHandle): PLChar;
  FindIsDirectory: function(H: TFileFindHandle): Boolean;
  FindClose: procedure(H: TFileFindHandle);

  GetLocalCopy: procedure(Name: PLChar);
  GetLocalPath: function(Name: PLChar): PLChar;
  ParseFile: function(Data: Pointer; Token: PLChar; WasQuoted: PBoolean): Pointer;

  GetCurrentDirectory: procedure(Buf: PLChar; MaxLen: UInt);

  SetWarningLevel: procedure(Level: TFileWarningLevel);
  GetCharacter: function(F: TFile): LChar;

  LogLevelLoadStarted: procedure(Name: PLChar);
  LogLevelLoadFinished: procedure(Name: PLChar);

  GetInterfaceVersion: function: PLChar;

  Unlink: procedure(Name: PLChar);
  Rename: procedure(OldPath, NewPath: PLChar);
 end;

// Delta.pas

const
 DT_BYTE = 1 shl 0;
 DT_SHORT = 1 shl 1;
 DT_FLOAT = 1 shl 2;
 DT_INTEGER = 1 shl 3;
 DT_ANGLE = 1 shl 4;
 DT_TIMEWINDOW_8 = 1 shl 5;
 DT_TIMEWINDOW_BIG = 1 shl 6;
 DT_STRING = 1 shl 7;

 DT_SIGNED = 1 shl 31;

type
 PDelta = ^TDelta;

 PDeltaField = ^TDeltaField; // Size is 68. Confirmed.
 TDeltaField = record
  FieldType: UInt32;          // 0. Confirmed.
  Name: array[1..32] of Char; // 4. Confirmed. A field name.
  Offset: UInt32;             // 36. Confirmed. Offset (unsigned).
  Parsed: Word;                 // 40. Sets to "1" when parsing.
  Bits: UInt32;               // 44. Confirmed. How many bits are in offset value.
  Scale: Single;              // 48. Should really be a scale.
  PScale: Single;             // 52. Another scale.
  Flags: set of (ffReady, __ffPadding = 15);    // 56. Unsure about this.
                                                //     Is 16-bit, actually.
  SendCount: UInt32;          // 60. How many times we should "send" this field.
  RecvCount: UInt32;         // 64. Delta_Parse increments it.
 end;
 TDeltaFieldArray = array[0..0] of TDeltaField;
 // dp @ metadelta; dp @ static delta constants 
 {$IF SizeOf(TDeltaField) <> 68} {$MESSAGE WARN 'Structure size mismatch @ TDeltaField.'} {$DEFINE MSME} {$IFEND}

 // Should be declared as "cdecl" for exporting purposes.
 TDeltaEncoder = procedure(Delta: PDelta; OS, NS: Pointer); cdecl;

 TDelta = record
  Active: Boolean;    // 0: If active, fields are written out.
  NumFields: Int32; // 4: Number of delta fields. Signed.
  Name: array[1..32] of LChar; // 8. Confirmed.
  ConditionalEncoder: TDeltaEncoder; // 40. Confirmed.
  Fields: ^TDeltaFieldArray; // 44: Pointer to a field array.
 end;

 PDeltaEncoderEntry = ^TDeltaEncoderEntry; // 12. Confirmed.
 TDeltaEncoderEntry = record
  Prev: PDeltaEncoderEntry;
  Name: PLChar; // through StrDup
  Func: TDeltaEncoder;
 end;

 PDeltaLinkedField = ^TDeltaLinkedField;
 TDeltaLinkedField = record
  Prev: PDeltaLinkedField;
  Field: PDeltaField;
 end;

 PDeltaOffset = ^TDeltaOffset;
 TDeltaOffset = record
  Name: PLChar;
  Offset: UInt32;
 end;
 PDeltaOffsetArray = ^TDeltaOffsetArray;
 TDeltaOffsetArray = array[0..0] of TDeltaOffset;

 PDeltaDefinition = ^TDeltaDefinition; // 16, confirmed.
 TDeltaDefinition = record
  Prev: PDeltaDefinition;
  Name: PLChar;
  Count: UInt32;
  Offsets: PDeltaOffsetArray;
 end;

 PDeltaRegistry = ^TDeltaRegistry;
 TDeltaRegistry = record
  Prev: PDeltaRegistry;
  Name: PLChar;
  Delta: PDelta;
 end;

 PServerDelta = ^TServerDelta;
 TServerDelta = record
  Prev: PServerDelta;
  Name: PLChar;
  FileName: PLChar;
  Delta: PDelta;
 end;

// HPAK
const
 HPAK_VERSION = 1;
 HPAK_MAX_ENTRIES = 32768;

 // Some sort of a refactoring trick
 HPAK_TAG = Ord('H') + Ord('P') shl 8 + Ord('A') shl 16 + Ord('K') shl 24;

type
 PHPAK = ^THPAK;
 THPAK = record
  Name: PLChar; // 0. Confirmed.
  Resource: TResource; // 4

  Size: UInt32; // 140
  Buffer: Pointer; // 144
  Prev: PHPAK; // 148. Confirmed.
 end;

 THPAKHeader = record
  FileTag: array[1..4] of LChar;
  Version, FileOffset: UInt32;
 end;
 {$IF SizeOf(THPAKHeader) <> 12} {$MESSAGE WARN 'Structure size mismatch @ THPAKHeader.'} {$DEFINE MSME} {$IFEND}

 PHPAKDirectory = ^THPAKDirectory;
 THPAKDirectory = record // 144. Confirmed.
  Resource: TResource;
  FileOffset, Size: UInt32; // 136 and 140
 end;
 PHPAKDirectoryArray = ^THPAKDirectoryArray;
 THPAKDirectoryArray = array[0..0] of THPAKDirectory;
 {$IF SizeOf(THPAKDirectory) <> 144} {$MESSAGE WARN 'Structure size mismatch @ THPAKDirectory.'} {$DEFINE MSME} {$IFEND}

 PHPAKDirectoryHeader = ^THPAKDirectoryHeader;
 THPAKDirectoryHeader = record
  NumEntries: Int32;
  Entries: PHPAKDirectoryArray;
 end;
 {$IF SizeOf(THPAKDirectoryHeader) <> 8} {$MESSAGE WARN 'Structure size mismatch @ THPAKDirectoryHeader.'} {$DEFINE MSME} {$IFEND}

 // 136 for Resource.

const
 DT_ClientData_T: array[1..56] of TDeltaOffset =
 ((Name: 'origin[0]'; Offset: 0),
  (Name: 'origin[1]'; Offset: 4),
  (Name: 'origin[2]'; Offset: 8),
  (Name: 'velocity[0]'; Offset: 12),
  (Name: 'velocity[1]'; Offset: 16),
  (Name: 'velocity[2]'; Offset: 20),
  (Name: 'viewmodel'; Offset: 24),
  (Name: 'punchangle[0]'; Offset: 28),
  (Name: 'punchangle[1]'; Offset: 32),
  (Name: 'punchangle[2]'; Offset: 36),
  (Name: 'flags'; Offset: 40),
  (Name: 'waterlevel'; Offset: 44),
  (Name: 'watertype'; Offset: 48),
  (Name: 'view_ofs[0]'; Offset: 52),
  (Name: 'view_ofs[1]'; Offset: 56),
  (Name: 'view_ofs[2]'; Offset: 60),
  (Name: 'health'; Offset: 64),
  (Name: 'bInDuck'; Offset: 68),
  (Name: 'weapons'; Offset: 72),
  (Name: 'flTimeStepSound'; Offset: 76),
  (Name: 'flDuckTime'; Offset: 80),
  (Name: 'flSwimTime'; Offset: 84),
  (Name: 'waterjumptime'; Offset: 88),
  (Name: 'maxspeed'; Offset: 92),
  (Name: 'm_iId'; Offset: 104),
  (Name: 'ammo_nails'; Offset: 112),
  (Name: 'ammo_shells'; Offset: 108),
  (Name: 'ammo_cells'; Offset: 116),
  (Name: 'ammo_rockets'; Offset: 120),
  (Name: 'm_flNextAttack'; Offset: 124),
  (Name: 'physinfo'; Offset: 140),
  (Name: 'fov'; Offset: 96),
  (Name: 'weaponanim'; Offset: 100),
  (Name: 'tfstate'; Offset: 128),
  (Name: 'pushmsec'; Offset: 132),
  (Name: 'deadflag'; Offset: 136),
  (Name: 'iuser1'; Offset: 396),
  (Name: 'iuser2'; Offset: 400),
  (Name: 'iuser3'; Offset: 404),
  (Name: 'iuser4'; Offset: 408),
  (Name: 'fuser1'; Offset: 412),
  (Name: 'fuser2'; Offset: 416),
  (Name: 'fuser3'; Offset: 420),
  (Name: 'fuser4'; Offset: 424),
  (Name: 'vuser1[0]'; Offset: 428),
  (Name: 'vuser1[1]'; Offset: 432),
  (Name: 'vuser1[2]'; Offset: 436),
  (Name: 'vuser2[0]'; Offset: 440),
  (Name: 'vuser2[1]'; Offset: 444),
  (Name: 'vuser2[2]'; Offset: 448),
  (Name: 'vuser3[0]'; Offset: 452),
  (Name: 'vuser3[1]'; Offset: 456),
  (Name: 'vuser3[2]'; Offset: 460),
  (Name: 'vuser4[0]'; Offset: 464),
  (Name: 'vuser4[1]'; Offset: 468),
  (Name: 'vuser4[2]'; Offset: 472));

 DT_WeaponData_T: array[1..22] of TDeltaOffset =
 ((Name: 'm_iId'; Offset: 0),
  (Name: 'm_iClip'; Offset: 4),
  (Name: 'm_flNextPrimaryAttack'; Offset: 8),
  (Name: 'm_flNextSecondaryAttack'; Offset: 12),
  (Name: 'm_flTimeWeaponIdle'; Offset: 16),
  (Name: 'm_fInReload'; Offset: 20),
  (Name: 'm_fInSpecialReload'; Offset: 24),
  (Name: 'm_flNextReload'; Offset: 28),
  (Name: 'm_flPumpTime'; Offset: 32),
  (Name: 'm_fReloadTime'; Offset: 36),
  (Name: 'm_fAimedDamage'; Offset: 40),
  (Name: 'm_fNextAimBonus'; Offset: 44),
  (Name: 'm_fInZoom'; Offset: 48),
  (Name: 'm_iWeaponState'; Offset: 52),
  (Name: 'iuser1'; Offset: 56),
  (Name: 'iuser2'; Offset: 60),
  (Name: 'iuser3'; Offset: 64),
  (Name: 'iuser4'; Offset: 68),
  (Name: 'fuser1'; Offset: 72),
  (Name: 'fuser2'; Offset: 76),
  (Name: 'fuser3'; Offset: 80),
  (Name: 'fuser4'; Offset: 84));

 DT_UserCmd_T: array[1..16] of TDeltaOffset =
 ((Name: 'lerp_msec'; Offset: 0),
  (Name: 'msec'; Offset: 2),
  (Name: 'lightlevel'; Offset: 28),
  (Name: 'viewangles[0]'; Offset: 4),
  (Name: 'viewangles[1]'; Offset: 8),
  (Name: 'viewangles[2]'; Offset: 12),
  (Name: 'buttons'; Offset: 30),
  (Name: 'forwardmove'; Offset: 16),
  (Name: 'sidemove'; Offset: 20),
  (Name: 'upmove'; Offset: 24),
  (Name: 'impulse'; Offset: 32),
  (Name: 'weaponselect'; Offset: 33),
  (Name: 'impact_index'; Offset: 36),
  (Name: 'impact_position[0]'; Offset: 40),
  (Name: 'impact_position[1]'; Offset: 44),
  (Name: 'impact_position[2]'; Offset: 48));

 DT_EntityState_T: array[1..87] of TDeltaOffset =
 ((Name: 'startpos[0]'; Offset: 228),
  (Name: 'startpos[1]'; Offset: 232),
  (Name: 'startpos[2]'; Offset: 236),
  (Name: 'endpos[0]'; Offset: 240),
  (Name: 'endpos[1]'; Offset: 244),
  (Name: 'endpos[2]'; Offset: 248),
  (Name: 'impacttime'; Offset: 252),
  (Name: 'starttime'; Offset: 256),
  (Name: 'origin[0]'; Offset: 16),
  (Name: 'origin[1]'; Offset: 20),
  (Name: 'origin[2]'; Offset: 24),
  (Name: 'angles[0]'; Offset: 28),
  (Name: 'angles[1]'; Offset: 32),
  (Name: 'angles[2]'; Offset: 36),
  (Name: 'modelindex'; Offset: 40),
  (Name: 'frame'; Offset: 48),
  (Name: 'movetype'; Offset: 88),
  (Name: 'colormap'; Offset: 52),
  (Name: 'skin'; Offset: 56),
  (Name: 'solid'; Offset: 58),
  (Name: 'scale'; Offset: 64),
  (Name: 'effects'; Offset: 60),
  (Name: 'sequence'; Offset: 44),
  (Name: 'animtime'; Offset: 92),
  (Name: 'framerate'; Offset: 96),
  (Name: 'controller[0]'; Offset: 104),
  (Name: 'controller[1]'; Offset: 105),
  (Name: 'controller[2]'; Offset: 106),
  (Name: 'controller[3]'; Offset: 107),
  (Name: 'blending[0]'; Offset: 108),
  (Name: 'blending[1]'; Offset: 109),
  (Name: 'body'; Offset: 100),
  (Name: 'owner'; Offset: 152),
  (Name: 'rendermode'; Offset: 72),
  (Name: 'renderamt'; Offset: 76),
  (Name: 'renderfx'; Offset: 84),
  (Name: 'rendercolor.r'; Offset: 80),
  (Name: 'rendercolor.g'; Offset: 81),
  (Name: 'rendercolor.b'; Offset: 82),
  (Name: 'weaponmodel'; Offset: 180),
  (Name: 'gaitsequence'; Offset: 184),
  (Name: 'mins[0]'; Offset: 124),
  (Name: 'mins[1]'; Offset: 128),
  (Name: 'mins[2]'; Offset: 132),
  (Name: 'maxs[0]'; Offset: 136),
  (Name: 'maxs[1]'; Offset: 140),
  (Name: 'maxs[2]'; Offset: 144),
  (Name: 'aiment'; Offset: 148),
  (Name: 'basevelocity[0]'; Offset: 188),
  (Name: 'basevelocity[1]'; Offset: 192),
  (Name: 'basevelocity[2]'; Offset: 196),
  (Name: 'friction'; Offset: 156),
  (Name: 'gravity'; Offset: 160),
  (Name: 'spectator'; Offset: 176),
  (Name: 'velocity[0]'; Offset: 112),
  (Name: 'velocity[1]'; Offset: 116),
  (Name: 'velocity[2]'; Offset: 120),
  (Name: 'team'; Offset: 164),
  (Name: 'playerclass'; Offset: 168),
  (Name: 'health'; Offset: 172),
  (Name: 'usehull'; Offset: 200),
  (Name: 'oldbuttons'; Offset: 204),
  (Name: 'onground'; Offset: 208),
  (Name: 'iStepLeft'; Offset: 212),
  (Name: 'flFallVelocity'; Offset: 216),
  (Name: 'weaponanim'; Offset: 224),
  (Name: 'eflags'; Offset: 68),
  (Name: 'iuser1'; Offset: 260),
  (Name: 'iuser2'; Offset: 264),
  (Name: 'iuser3'; Offset: 268),
  (Name: 'iuser4'; Offset: 272),
  (Name: 'fuser1'; Offset: 276),
  (Name: 'fuser2'; Offset: 280),
  (Name: 'fuser3'; Offset: 284),
  (Name: 'fuser4'; Offset: 288),
  (Name: 'vuser1[0]'; Offset: 292),
  (Name: 'vuser1[1]'; Offset: 296),
  (Name: 'vuser1[2]'; Offset: 300),
  (Name: 'vuser2[0]'; Offset: 304),
  (Name: 'vuser2[1]'; Offset: 308),
  (Name: 'vuser2[2]'; Offset: 312),
  (Name: 'vuser3[0]'; Offset: 316),
  (Name: 'vuser3[1]'; Offset: 320),
  (Name: 'vuser3[2]'; Offset: 324),
  (Name: 'vuser4[0]'; Offset: 328),
  (Name: 'vuser4[1]'; Offset: 332),
  (Name: 'vuser4[2]'; Offset: 336));

 DT_Event_T: array[1..14] of TDeltaOffset =
 ((Name: 'entindex'; Offset: 4),
  (Name: 'origin[0]'; Offset: 8),
  (Name: 'origin[1]'; Offset: 12),
  (Name: 'origin[2]'; Offset: 16),
  (Name: 'angles[0]'; Offset: 20),
  (Name: 'angles[1]'; Offset: 24),
  (Name: 'angles[2]'; Offset: 28),
  (Name: 'fparam1'; Offset: 48),
  (Name: 'fparam2'; Offset: 52),
  (Name: 'iparam1'; Offset: 56),
  (Name: 'iparam2'; Offset: 60),
  (Name: 'bparam1'; Offset: 64),
  (Name: 'bparam2'; Offset: 68),
  (Name: 'ducking'; Offset: 44));

// links
type
 PLink = ^TLink;
 TLink = record
  Prev, Next: PLink;
 end;

// miptex and TEX_*
const
 MAX_MAP_TEXTURES = 512;
 MAX_TEXTUREREF_NAME = 64;

type
 PTextureRef = ^TTextureRef;
 TTextureRef = record // 64, and there are 512 entries
  Name: array[1..MAX_TEXTUREREF_NAME] of LChar;
 end;

 PTextureLump = ^TTextureLump; // 36, confirmed
 TTextureLump = record
  FilePos, DiskSize, Size: UInt32;
  LumpType, Compression: Byte;
  Padding: UInt16;
  Name: array[1..MAX_LUMP_NAME] of LChar;

  FileID: UInt32; // 32, UInt32 for sure, is not pointer, is index
 end;
 PTextureLumpArray = ^TTextureLumpArray;
 TTextureLumpArray = array[0..0] of TTextureLump;
 {$IF SizeOf(TTextureLump) <> 36} {$MESSAGE WARN 'Structure size mismatch @ TTextureLump.'} {$DEFINE MSME} {$IFEND}


// edict

const
 BSPVERSION30 = 30;
 BSPVERSION29 = 29;

 //LUMP_ENTITIES = 1;
 //LUMP_PLANES = 0;
 LUMP_TEXTURES = 2;
 LUMP_VERTEXES = 3;
 LUMP_VISIBILITY = 4;
 LUMP_NODES = 5;
 LUMP_TEXINFO = 6;
 LUMP_FACES = 7;
 LUMP_LIGHTING = 8;
 LUMP_CLIPNODES = 9;
 LUMP_LEAFS = 10;
 LUMP_MARKSURFACES = 11;
 LUMP_EDGES = 12;
 LUMP_SURFEDGES = 13;
 LUMP_MODELS = 14;
 
 HEADER_LUMPS = 15;

type
 TLump = record
  FileOffset, FileLength: UInt32;
 end;
 {$IF SizeOf(TLump) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TLump.'} {$DEFINE MSME} {$IFEND}

 PDHeader = ^TDHeader;
 TDHeader = record
  Version: UInt32;
  Lumps: array[0..HEADER_LUMPS - 1] of TLump;
 end;
 {$IF SizeOf(TDHeader) <> 124} {$MESSAGE WARN 'Structure size mismatch @ TDHeader.'} {$DEFINE MSME} {$IFEND}

 // brush models
 PDVertex = ^TDVertex;
 TDVertex = record
  Point: array[0..2] of Single;
 end;
 PMVertex = ^TMVertex;
 TMVertex = record
  Position: TVec3;
 end;
 TMVertexArray = array[0..0] of TMVertex;
 {$IF SizeOf(TDVertex) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TDVertex.'} {$DEFINE MSME} {$IFEND}


 PDEdge = ^TDEdge;
 TDEdge = packed record
  V: array[0..1] of UInt16;
 end;
 PMEdge = ^TMEdge;
 TMEdge = record
  V: array[0..1] of UInt16;
  CachedEdgeOffset: UInt;
 end;
 TMEdgeArray = array[0..0] of TMEdge;
 {$IF SizeOf(TDEdge) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDEdge.'} {$DEFINE MSME} {$IFEND}


 PDPlane = ^TDPlane;
 TDPlane = record
  Normal: array[0..2] of Single;
  Distance: Single;
  PlaneType: Int32;
 end;
 PMPlane = ^TMPlane;
 TMPlane = packed record
  Normal: TVec3;
  Distance: Single;
  PlaneType, SignBits, Padding1, Padding2: UInt8;
 end;
 TMPlaneArray = array[0..0] of TMPlane;
 {$IF SizeOf(TDPlane) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TDPlane.'} {$DEFINE MSME} {$IFEND}


 PDMiptexLump = ^TDMiptexLump;
 TDMiptexLump = record
  NumMiptex: Int32;
  DataOfs: array[0..3] of Int32;
 end;
 {$IF SizeOf(TDMiptexLump) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TDMiptexLump.'} {$DEFINE MSME} {$IFEND}


// networking

const
 MAX_LOOPBACK = 4;
 MAX_LOOPBACK_PACKETLEN = 4040;

 MAX_FRAGLEN = 1400;
 MAX_NETPACKETLEN = 4010;

 MAX_NET_QUEUES = 40;
 NET_QUEUESIZE = $600;

 OUTOFBAND_TAG = -1;
 SPLIT_TAG = -2;

 MAX_SPLIT = 5;

 MAX_LATENT = 32;

 UDP_OVERHEAD = 28;

 MAX_DATAGRAM = 4000; // max length of unreliable packet, confirmed

 // server to all
 S2C_PRINT = 'l';
 C2S_PING = 'i';
 S2C_CHALLENGE = 'A';
 S2C_CONNECT = 'B';
 S2C_PASSWORD = '8';
 S2C_ERROR = '9';

 S2C_INFO = 'm';
 S2C_PLAYERS = 'D';
 S2C_RULES = 'E';

 C2S_INFO_NEW = 'T';
 S2C_INFO_NEW = 'I';

 C2S_PLAYERS_NEW = 'U';
 C2S_RULES_NEW = 'V';

 C2S_SERVERQUERY_GETCHALLENGE = 'W';

 A2A_ACK = 'i';

type
 TNetAdrType = (NA_UNUSED = 0, NA_LOOPBACK, NA_BROADCAST, NA_IP, NA_IPX, NA_BROADCAST_IPX);

 TNetSrc = (NS_CLIENT = 0, NS_SERVER, NS_MULTICAST);

 PNetAdr = ^TNetAdr; // 20, verified
 TNetAdr = packed record
  AddrType: TNetAdrType;
  IP: array[1..4] of Byte;
  IPX: array[1..10] of Byte;
  Port: UInt16;
 end;
 {$IF SizeOf(TNetAdr) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TNetAdr.'} {$DEFINE MSME} {$IFEND}

 PLoopMsg = ^TLoopMsg;
 TLoopMsg = record // 4044
  Data: array[0..MAX_LOOPBACK_PACKETLEN - 1] of Byte;
  Size: UInt32;
 end;

 PLoopBack = ^TLoopBack;
 TLoopBack = record // 16184
  Msgs: array[0..MAX_LOOPBACK - 1] of TLoopMsg;
  Get: Int32; // 16176
  Send: Int32; // 16180
 end;

 // split

 TSplitHeader = packed record // 9
  OutSeq, InSeq: Int32;
  Index: Byte;
 end;
 {$IF SizeOf(TSplitHeader) <> 9} {$MESSAGE WARN 'Structure size mismatch @ TSplitHeader.'} {$DEFINE MSME} {$IFEND}

 // queues and multithreading
 PNetQueue = ^TNetQueue; // size is 36, confirmed
 TNetQueue = record
  Prev: PNetQueue; // 0. Confirmed.
  Normal: Boolean; // 4. if it's in normal queue
  Data: Pointer; // 8. allocates $600 bytes (1536)
  Addr: TNetAdr; // 12. Confirmed.
  Size: UInt32; // 32. Confirmed.
 end;

 // circular LL
 PLagPacket = ^TLagPacket; // size is 40 (confirmed), indexed by net source.
 TLagPacket = record
  Data: Pointer; // 0, some kind of data, maybe packet contents
  Size: UInt32; // 4, data size
  Addr: TNetAdr; // 8
  Time: Single; // 28
  Prev, Next: PLagPacket; // 32 and 36
 end;


 PFragBuf = ^TFragBuf;
 TFragBuf = record // 1708. confirmed.
  Next: PFragBuf; // +0. or prev?
  Index: UInt32; // +4
  FragMessage: TSizeBuf; // +8
  Data: array[1..MAX_FRAGLEN] of Byte; // +28

  B1: Boolean; // +1428
  __Padding1, __Padding2, __Padding3: Byte;
  B2: Boolean; // +1432
  __Padding4, __Padding5, __Padding6: Byte;
  Compressed: Boolean; // +1436, maybe confirmed
  __Padding7, __Padding8, __Padding9: Byte;

  FileName: array[1..MAX_PATH_A] of LChar; // +1440, confirmed
  FileOffset: UInt32; // +1700, unsure
  FragmentSize: UInt32; // +1704, should be confirmed
 end;

 PFragBufDir = ^TFragBufDir;
 TFragBufDir = record
  Next: PFragBufDir; // +0
  Count: UInt32; // +4, unsure
  FragBuf: PFragBuf; // +8
 end;

 PNetchanFlowStats = ^TNetchanFlowStats; // W 536 L 404
 TNetchanFlowStats = record
  Bytes: UInt32; // +0
  TimeWindow: Double; // +8
 end;

 PNetchanFlowData = ^TNetchanFlowData;
 TNetchanFlowData = record
  // 8432 start of something
  Stats: array[0..MAX_LATENT - 1] of TNetchanFlowStats;           

  InSeq: Int32; // +8948 not very confirmed
  UpdateTime: Double; // +8952 confirmed
  KBRate, KBAvgRate: Single; // +8960 +8964 confirmed so yeah
 end;
 
 // Netchan
 PNetchan = ^TNetchan; // 9504 on hw.dll    9236 linux
 TNetchan = record
  Source: TNetSrc; // +0, fully confirmed: 0, 1, 2 are possible values
  Addr: TNetAdr; // +4, fully confirmed
  ClientIndex: Int32; // +24, fully confirmed client index
  LastReceived, FirstReceived: Single; // +28 and +32

  Rate: Double; // +40 | +36, guess it's confirmed
  ClearTime: Double; // +48 | +44 fully confirmed

  IncomingSequence: Int32; // +56 confirmed fully (2nd step)
  IncomingAcknowledged: Int32; // +60 confirmed fully
  IncomingReliableAcknowledged: Int32; // +64 confirmed fully
  IncomingReliableSequence: Int32; // +68 confirmed fully (2nd step)

  OutgoingSequence: Int32; // W 72   L 68 confirmed fully (2nd step)
  ReliableSequence: Int32; // W 76 L 72  confirmed fully
  LastReliableSequence: Int32; // W 80 L 76 confirmed fully

  Client: Pointer; // +84 | +80, confirmed  pclient
  FragmentFunc: function(Client: Pointer): UInt32; cdecl; // +88 | +84, fully confirmed
  NetMessage: TSizeBuf; // +92 | +88, fully confirmed
  NetMessageBuf: array[1..3990] of Byte; // W 112,  L 108 fully confirmed

  ReliableLength: UInt32; // +4104 yeah confirmed
  ReliableBuf: array[1..3990] of Byte; // W 4108 confirmed   L 4104 confirmed

  // this fragbuf stuff seems to be confirmed
  FragBufDirs: array[1..2] of PFragBufDir; // W 8100   L 8096?
  FragBufActive: array[1..2] of Boolean; // W 8108
  FragBufSequence: array[1..2] of Int32; // W 8116
  FragBufBase: array[1..2] of PFragBuf; // W 8124   L ?8120
  FragBufSplitCount: array[1..2] of UInt32; // W 8132 L 8128
  FragBufOffset: array[1..2] of UInt16; // W 8140
  FragBufSize: array[1..2] of UInt16; // W 8144
  
  IncomingBuf: array[1..2] of PFragBuf; // W 8148 L 8144
  IncomingActive: array[1..2] of Boolean; // W 8156 L 8152

  FileName: array[1..MAX_PATH_A] of LChar; // W 8164 confirmed

  TempBuffer: Pointer; // W 8424
  TempBufferSize: UInt32; // W 8428

  Flow: array[1..2] of TNetchanFlowData; // W 8432    flow data size = 536
 end;

const
 MAX_SPLIT_FRAGLEN = MAX_FRAGLEN - SizeOf(TSplitHeader); // 1391



// PM
const
 SOLID_NOT = 0; // confirmed
 SOLID_TRIGGER = 1; // confirmed
 SOLID_BBOX = 2;
 SOLID_SLIDEBOX = 3; // cf
 SOLID_BSP = 4; // confirmed

 // alias models
 ALIAS_VERSION = 6;
 MAX_LBM_HEIGHT = 480;
 MAXALIASVERTS = 2000;

 ALIAS_BASE_SIZE_RATIO = 1 / 11;
 MAX_PALETTE = 256;

 TEX_SIZEDIF = SizeOf(TTexture) - SizeOf(TMiptex);

 MAXLIGHTMAPS = 4;
 NUM_AMBIENTS = 4;

 TEX_SPECIAL = 1;

 SURF_PLANEBACK = 2;
 SURF_DRAWSKY = 4;
 SURF_DRAWSPRITE = 8;
 SURF_DRAWTURB = 16;
 SURF_DRAWTILED = 32;
 SURF_DRAWBACKGROUND = 64;

 MAX_MAP_HULLS = 4;

 MAX_MOD_KNOWN = 1024;
 
type
// model
 TModelType = (ModBrush = 0, ModSprite, ModAlias, ModStudio);
 TSyncType = (ST_SYNC = 0, ST_RAND);

 PDClipNode = ^TDClipNode; // 8, req
 TDClipNode = packed record
  PlaneNum: Int32;
  Children: array[0..1] of Int16; // yep int16
 end;
 TDClipNodeArray = array[0..0] of TDClipNode;
 {$IF SizeOf(TDClipNode) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TDClipNode.'} {$DEFINE MSME} {$IFEND}


 PHull = ^THull; // 40
 THull = record
  ClipNodes: ^TDClipNodeArray;
  Planes: ^TMPlaneArray;
  FirstClipNode, LastClipNode: Int32;
  ClipMinS, ClipMaxS: TVec3;
 end;


 PDTexInfo = ^TDTexInfo;
 TDTexInfo = record
  Vecs: array[0..1] of array[0..3] of Single;
  MipTex: Int32;
  Flags: Int32;
 end; 
 PMTexInfo = ^TMTexInfo;
 TMTexInfo = record
  Vecs: array[0..1] of array[0..3] of Single;
  MipAdjust: Single;
  Texture: PTexture;
  Flags: Int32;
 end;
 TMTexInfoArray = array[0..0] of TMTexInfo;
 {$IF SizeOf(TDTexInfo) <> 40} {$MESSAGE WARN 'Structure size mismatch @ TDTexInfo.'} {$DEFINE MSME} {$IFEND}


 PDFace = ^TDFace; // 20
 TDFace = packed record
  PlaneNum, Side: Int16;
  FirstEdge: Int32;
  NumEdges, TexInfo: Int16;
  Styles: array[0..MAXLIGHTMAPS - 1] of Byte;
  LightOfs: Int32;
 end;
 PMSurface = ^TMSurface; // 68
 TMSurface = record
  VisFrame, DLightFrame, DLightBits: Int32; // 0, 4, 8
  Plane: PMPlane; // 12
  Flags: Int32; // 16
  FirstEdge, NumEdges: Int32; // 20, 24
  CacheSpots: array[0..MIPLEVELS - 1] of Pointer; // 28

  TextureMinS: array[0..1] of Int16; // 44
  Extents: array[0..1] of Int16; // 48

  TexInfo: PMTexInfo; // 52

  Styles: array[0..MAXLIGHTMAPS - 1] of Byte; // 56

  Samples: Pointer; // 60
  Decals: Pointer; // 64
 end;
 TMSurfaceArray = array[0..0] of TMSurface;
 PMSurfaceArray = array[0..0] of PMSurface;
 {$IF SizeOf(TDFace) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TDFace.'} {$DEFINE MSME} {$IFEND}


 PDNode = ^TDNode;
 TDNode = packed record
  PlaneNum: Int32; // 0
  Children: array[0..1] of Int16; // 4
  MinS, MaxS: array[0..2] of Int16; // 8
  FirstFace, NumFaces: UInt16; // 20, 22
 end;
 PMNode = ^TMNode; // 40
 TMNode = record
  Contents, VisFrame: Int32; // 0, 4
  MinMaxS: array[0..5] of Int16; // 8
  Parent: PMNode; // 20

  Plane: PMPlane; // 24
  Children: array[0..1] of PMNode; // +28
  FirstSurface, NumSurfaces: UInt16; // +36, +38
 end;
 TMNodeArray = array[0..0] of TMNode;
 {$IF SizeOf(TDNode) <> 24} {$MESSAGE WARN 'Structure size mismatch @ TDNode.'} {$DEFINE MSME} {$IFEND}


 PDLeaf = ^TDLeaf;
 TDLeaf = packed record
  Contents, VisOfs: Int32;
  MinS, MaxS: array[0..2] of Int16;
  FirstMarkSurface, NumMarkSurfaces: UInt16;
  AmbientLevel: array[0..NUM_AMBIENTS - 1] of Byte;
 end;
 PMLeaf = ^TMLeaf; // 48
 TMLeaf = record
  Contents, VisFrame: Int32; // 0, 4
  MinMaxS: array[0..5] of Int16; // 8
  Parent: PMNode; // 20

  CompressedVis: PByte; // +24
  EFrags: Pointer;
  FirstMarkSurface: ^PMSurface;
  NumMarkSurfaces, Key: Int32;
  AmbientSoundLevel: array[0..NUM_AMBIENTS - 1] of Byte;
 end;
 TMLeafArray = array[0..0] of TMLeaf;
 {$IF SizeOf(TDLeaf) <> 28} {$MESSAGE WARN 'Structure size mismatch @ TDLeaf.'} {$DEFINE MSME} {$IFEND}


 PDModel = ^TDModel;
 TDModel = record
  MinS, MaxS, Origin: array[0..2] of Single;
  HeadNode: array[0..MAX_MAP_HULLS - 1] of Int32;
  VisLeafs, FirstFace, NumFaces: Int32;
 end;
 TDModelArray = array[0..0] of TDModel;
 {$IF SizeOf(TDModel) <> 64} {$MESSAGE WARN 'Structure size mismatch @ TDModel.'} {$DEFINE MSME} {$IFEND}


 TSurfEdgeArray = array[0..0] of Int32;

 PModel = ^TModel; // 392
 TModel = record
  Name: array[1..MAX_MODEL_NAME] of LChar; // +0
  NeedLoad: Int32; // +64
  ModelType: TModelType; // +68 confirmed int32
  NumFrames: Int32; // +72 confirmed
  SyncType: TSyncType; // +76 confirmed
  Flags: Int32; // +80 confirmed
  MinS, MaxS: TVec3; // +84, +96 confirmed
  Radius: Single; // +108
  FirstModelSurface, NumModelSurfaces: Int32; // +112, +116
  NumSubModels: UInt32; // +120
  SubModels: ^TDModelArray; // +124
  NumPlanes: UInt32; // +128
  Planes: ^TMPlaneArray; // +132
  NumLeafs: UInt32; // +136
  Leafs: ^TMLeafArray; // +140
  NumVertexes: UInt32; // +144
  Vertexes: ^TMVertexArray; // +148
  NumEdges: UInt32; // +152
  Edges: ^TMEdgeArray; // +156
  NumNodes: UInt32; // +160
  Nodes: ^TMNodeArray; // +164
  NumTexInfo: UInt32; // +168
  TexInfo: ^TMTexInfoArray; // +172
  NumSurfaces: UInt32; // +176
  Surfaces: ^TMSurfaceArray; // +180
  NumSurfEdges: UInt32; // +184
  SurfEdges: ^TSurfEdgeArray; // +188
  NumClipNodes: UInt32; // +192
  ClipNodes: ^TDClipNodeArray; // +196
  NumMarkSurfaces: UInt32; // +200
  MarkSurfaces: ^PMSurfaceArray; // +204
  Hulls: array[0..3] of THull; // +208, confirmed
                                  // 248
                                  // 288
                                  // 328
  NumTextures: UInt32; // +368
  Textures: ^PTextureArray; // +372
  VisData: PByte; // +376
  LightData: PByte; // +380
  Entities: Pointer; // +384
  Cache: TCacheUser; // +388 confirmed
 end;
 {$IF SizeOf(TModel) <> 392} {$MESSAGE WARN 'Structure size mismatch @ TModel.'} {$DEFINE MSME} {$IFEND}


 TModelCRCInfo = record // confirmed
  NeedCRC: Boolean;
  Filled: Boolean;
  CRC: TCRC;
 end;

 PMTriangle = ^TMTriangle; // confirmed
 TMTriangle = record
  FacesFront: Int32;
  VertIndex: array[0..2] of Int32;
 end;

 TDTriangle = type TMTriangle;
 PDTriangle = ^TDTriangle;
 {$IF SizeOf(TDTriangle) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TDTriangle.'} {$DEFINE MSME} {$IFEND}


 PSTVert = ^TSTVert;
 TSTVert = record
  OnSeam, S, T: Int32;
 end;
 {$IF SizeOf(TSTVert) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TSTVert.'} {$DEFINE MSME} {$IFEND}


 PTriVertX = ^TTriVertX;
 TTriVertX = packed record
  V: array[0..2] of Byte;
  LightNormalIndex: Byte;
 end;
 {$IF SizeOf(TTriVertX) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TTriVertX.'} {$DEFINE MSME} {$IFEND}


 TAliasFrameType = (ALIAS_SINGLE = 0, ALIAS_GROUP);
 TAliasSkinType = (ALIAS_SKIN_SINGLE = 0, ALIAS_SKIN_GROUP);

 PDAliasFrameType = ^TDAliasFrameType;
 TDAliasFrameType = record
  T: TAliasFrameType;
 end;
 {$IF SizeOf(TDAliasFrameType) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDAliasFrameType.'} {$DEFINE MSME} {$IFEND}

 PDAliasSkinType = ^TDAliasSkinType;
 TDAliasSkinType = record
  T: TAliasSkinType;
 end;
 {$IF SizeOf(TDAliasSkinType) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDAliasSkinType.'} {$DEFINE MSME} {$IFEND}

 PDAliasSkinGroup = ^TDAliasSkinGroup;
 TDAliasSkinGroup = record
  NumSkins: Int32;
 end;
 {$IF SizeOf(TDAliasSkinGroup) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDAliasSkinGroup.'} {$DEFINE MSME} {$IFEND}

 PDAliasSkinInterval = ^TDAliasSkinInterval;
 TDAliasSkinInterval = record
  Interval: Single;
 end;
 {$IF SizeOf(TDAliasSkinInterval) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDAliasSkinInterval.'} {$DEFINE MSME} {$IFEND}

 PDAliasExtraData = ^TDAliasExtraData;
 TDAliasExtraData = packed record
  V: array[0..2] of Byte;
 end;
 {$IF SizeOf(TDAliasExtraData) <> 3} {$MESSAGE WARN 'Structure size mismatch @ TDAliasExtraData.'} {$DEFINE MSME} {$IFEND}

 PDAliasFrame = ^TDAliasFrame;
 TDAliasFrame = packed record
  BBoxMin: TTriVertX;
  BBoxMax: TTriVertX;
  Name: array[1..16] of LChar;
 end;
 {$IF SizeOf(TDAliasFrame) <> 24} {$MESSAGE WARN 'Structure size mismatch @ TDAliasFrame.'} {$DEFINE MSME} {$IFEND}

 PDAliasGroup = ^TDAliasGroup;
 TDAliasGroup = packed record
  NumFrames: Int32;
  BBoxMin: TTriVertX;
  BBoxMax: TTriVertX;
 end;
 {$IF SizeOf(TDAliasGroup) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TDAliasGroup.'} {$DEFINE MSME} {$IFEND}

 PDAliasInterval = ^TDAliasInterval;
 TDAliasInterval = record
  Interval: Single;
 end;
 {$IF SizeOf(TDAliasInterval) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDAliasInterval.'} {$DEFINE MSME} {$IFEND}

 PMAliasSkinDesc = ^TMAliasSkinDesc;
 TMAliasSkinDesc = record
  T: TAliasSkinType;
  CacheSpot: Pointer;
  Skin: Int32;
 end;

 PMAliasFrameDesc = ^TMAliasFrameDesc;
 TMAliasFrameDesc = record // should be 32
  T: TAliasFrameType;
  BBoxMin, BBoxMax: TTriVertX;
  Frame: Int32;
  Name: array[1..16] of LChar;
 end;

 PMAliasExtraData = ^TMAliasExtraData;
 TMAliasExtraData = record
  V: array[0..3] of Int16;
 end;

 PMAliasSkinGroup = ^TMAliasSkinGroup;
 TMAliasSkinGroup = record
  NumSkins, Intervals: Int32;
 end;

 PMAliasGroup = ^TMAliasGroup;
 TMAliasGroup = record
  NumFrames, Intervals: Int32;
 end;

 PMAliasGroupFrameDesc = ^TMAliasGroupFrameDesc;
 TMAliasGroupFrameDesc = record
  BBoxMin, BBoxMax: TTriVertX;
  Frame: Int32;
 end;

 PAliasModelHeader = ^TAliasModelHeader;
 TAliasModelHeader = record // very probably it's 20
  Model, StVerts, SkinDesc, Triangles, Palette: UInt32;
 end;
 {$IF SizeOf(TAliasModelHeader) <> 20} {$MESSAGE WARN 'Structure size mismatch @ TAliasModelHeader.'} {$DEFINE MSME} {$IFEND}

 PModelHeader = ^TModelHeader;
 TModelHeader = record
  FileTag: UInt32; // 0
  Version: UInt32; // 4
  Scale, ScaleOrigin: TVec3; // +8, +20
  BoundingRadius: Single; // +32
  EyePosition: TVec3; // +36  
  NumSkins, SkinWidth, SkinHeight: Int32; // +48, +52, +56
  NumVerts, NumTris, NumFrames: Int32; // +60, +64, +68
  SyncType: TSyncType; // +72
  Flags: Int32; // +76
  Size: Single; // +80
 end;
 {$IF SizeOf(TModelHeader) <> 84} {$MESSAGE WARN 'Structure size mismatch @ TModelHeader.'} {$DEFINE MSME} {$IFEND}


const
 SPRITE_VERSION = 2;
 
type
 PSpriteHeader = ^TSpriteHeader; // 42
 TSpriteHeader = packed record
  FileTag: UInt32; // 0
  Version: UInt32; // 4
  SpriteType: UInt32; // 8
  FrameIndex: Int32; // 12
  BoundingRadius: Single; // 16
  Width, Height: Int32; // +20, +24
  NumFrames: Int32; // +28
  BeamLength: Single; // +32
  SyncType: TSyncType; // +36
  NumPalette: UInt16; // +40 
 end;
 {$IF SizeOf(TSpriteHeader) <> 42} {$MESSAGE WARN 'Structure size mismatch @ TSpriteHeader.'} {$DEFINE MSME} {$IFEND}

 TSpriteFrameType = (SPR_SINGLE = 0, SPR_GROUP);

 PDSpriteFrameType = ^TDSpriteFrameType;
 TDSpriteFrameType = record
  T: TSpriteFrameType;
 end;
 {$IF SizeOf(TDSpriteFrameType) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDSpriteFrameType.'} {$DEFINE MSME} {$IFEND}

 PDSpriteFrame = ^TDSpriteFrame;
 TDSpriteFrame = packed record
  Origin: array[0..1] of Int32;
  Width, Height: Int32;
 end;
 {$IF SizeOf(TDSpriteFrame) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TDSpriteFrame.'} {$DEFINE MSME} {$IFEND}

 PDSpriteGroup = ^TDSpriteGroup;
 TDSpriteGroup = record
  NumFrames: Int32;
 end;
 {$IF SizeOf(TDSpriteGroup) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDSpriteGroup.'} {$DEFINE MSME} {$IFEND}

 PDSpriteInterval = ^TDSpriteInterval;
 TDSpriteInterval = record
  Interval: Single;
 end;
 {$IF SizeOf(TDSpriteInterval) <> 4} {$MESSAGE WARN 'Structure size mismatch @ TDSpriteInterval.'} {$DEFINE MSME} {$IFEND}

 PMSpriteFrame = ^TMSpriteFrame;
 TMSpriteFrame = record
  Width, Height: Int32;
  CacheSpot: Pointer;
  Up, Down, Left, Right: Single;
  Pixels: array[1..4] of Byte;
 end;

 PMSpriteGroup = ^TMSpriteGroup; // 8
 TMSpriteGroup = record
  NumFrames: Int32;
  Intervals: PSingle;
 end;

 PMSpriteFrameDesc = ^TMSpriteFrameDesc;
 TMSpriteFrameDesc = record
  T: TSpriteFrameType;
  FramePtr: PMSpriteFrame;
 end;

 PMSpriteGroupFrameDesc = ^TMSpriteGroupFrameDesc;
 TMSpriteGroupFrameDesc = record
  FramePtr: PMSpriteFrame;
 end;

 PMSprite = ^TMSprite; // 28 confirmed
 TMSprite = record
  T, FrameIndex: UInt16; // +0, +2
  MaxWidth, MaxHeight, NumFrames: Int32; // +4, +8, +12
  Palette: Int32; // +16, offset
  BeamLength: Single; // +20
  Padding: Int32; // +24 can be removed
 end;


// Studio stuff
const
 STUDIO_VERSION = 10;

 STUDIO_X = $1;
 STUDIO_Y = $2;
 STUDIO_Z = $4;
 STUDIO_XR = $8;
 STUDIO_YR = $10;
 STUDIO_ZR = $20;
 STUDIO_TYPES = $7FFF;
 STUDIO_RLOOP = $8000;

 MAXSTUDIOBONES = 128;
 MAXSTUDIOHULL = 128;
 MAXSTUDIOCACHE = 16;
 
type
 PVec4 = ^TVec4;
 TVec4 = packed array[0..3] of Single;
 {$IF SizeOf(TVec4) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TVec4.'} {$DEFINE MSME} {$IFEND}

 PStudioHeader = ^TStudioHeader; // 244 cf
 TStudioHeader = record
  FileTag, Version: Int32; // 0, 4
  Name: array[1..64] of LChar; // 8
  Length: Int32; // 72
  EyePosition, Min, Max: TVec3; // 76, 88, 100
  BBMin, BBMax: TVec3; // 112, 124
  Flags: Int32; // 136

  NumBones: Int32;  // 140
  BoneIndex: UInt32; // 144
  NumBoneControllers, BoneControllerIndex: Int32; // 148, 152
  NumHitBoxes: Int32; // 156
  HitBoxIndex: UInt32; // 160
  NumSeq: Int32; // 164, 168
  SeqIndex: UInt32;
  NumSeqGroups: Int32; // 172
  SeqGroupIndex: UInt32; // 176
  NumTextures, TextureIndex, TextureDataIndex: Int32; // 180, 184, 188
  NumSkinRef, NumSkinFamilies, SkinIndex: Int32;
  NumBodyParts, BodyPartIndex: UInt32;
  NumAttachments: Int32;
  AttachmentIndex: UInt32;
  SoundTable, SoundIndex, SoundGroups, SoundGroupIndex: Int32;
  NumTransitions, TransitionIndex: Int32;
 end;
 {$IF SizeOf(TStudioHeader) <> 244} {$MESSAGE WARN 'Structure size mismatch @ TStudioHeader.'} {$DEFINE MSME} {$IFEND}

 PMStudioModel = ^TMStudioModel;
 TMStudioModel = record
  Name: array[1..64] of LChar;
  ModelType: Int32;
  BoundingRadius: Single;
  NumMesh, MeshIndex: UInt32;
  NumVerts, VertInfoIndex, VertIndex: UInt32;
  NumNorms, NormInfoIndex, NormIndex: UInt32;
  NumGroups, GroupIndex: UInt32;
 end;
 {$IF SizeOf(TMStudioModel) <> 112} {$MESSAGE WARN 'Structure size mismatch @ TMStudioModel.'} {$DEFINE MSME} {$IFEND}

 PMStudioTexture = ^TMStudioTexture; // 80 cf2
 TMStudioTexture = record
  Name: array[1..64] of LChar;
  Flags, Width, Height, Index: Int32;
 end;
 {$IF SizeOf(TMStudioTexture) <> 80} {$MESSAGE WARN 'Structure size mismatch @ TMStudioTexture.'} {$DEFINE MSME} {$IFEND}


 PMStudioBodyParts = ^TMStudioBodyParts; // 76 confirmed
 TMStudioBodyParts = record
  Name: array[1..64] of LChar;
  NumModels, Base, ModelIndex: Int32;
 end;
 {$IF SizeOf(TMStudioBodyParts) <> 76} {$MESSAGE WARN 'Structure size mismatch @ TMStudioBodyParts.'} {$DEFINE MSME} {$IFEND}


 PMStudioSeqDesc = ^TMStudioSeqDesc; // 176
 TMStudioSeqDesc = record
  Name: array[1..32] of LChar;
  FPS: Single; // 32
  Flags: Int32; // 36

  Activity, ActWeight: Int32; // 40, 44
  NumEvents, EventIndex: Int32; // 48, 52
  NumFrames, NumPivots, PivotIndex: Int32; // 56, 60, 64

  MotionType, MotionBone: Int32; // 68, 72
  LinearMovement: TVec3; // 76
  AutoMovePosIndex, AutoMoveAngleIndex: Int32; // 88, 92

  BBMin, BBMax: TVec3; // 96, 108

  NumBlends: Int32;
  AnimIndex: UInt32;
  BlendType: array[0..1] of Int32;
  BlendStart, BlendEnd: array[0..1] of Single;
  BlendParent: Int32;

  SeqGroup: UInt32;

  EntryNode, ExitNode, NodeFlags: Int32;

  NextSeq: Int32;
 end;
 {$IF SizeOf(TMStudioSeqDesc) <> 176} {$MESSAGE WARN 'Structure size mismatch @ TMStudioSeqDesc.'} {$DEFINE MSME} {$IFEND}


 PMStudioBoneController = ^TMStudioBoneController; // 24
 TMStudioBoneController = record
  Bone: Int32;
  CType: Int32;
  FStart, FEnd: Single;
  Rest: Int32;
  Index: UInt32;
 end;
 {$IF SizeOf(TMStudioBoneController) <> 24} {$MESSAGE WARN 'Structure size mismatch @ TMStudioBoneController.'} {$DEFINE MSME} {$IFEND}


 PMStudioAnim = ^TMStudioAnim;
 TMStudioAnim = packed record
  Offset: array[0..5] of UInt16;
 end;
 {$IF SizeOf(TMStudioAnim) <> 12} {$MESSAGE WARN 'Structure size mismatch @ TMStudioAnim.'} {$DEFINE MSME} {$IFEND}


 PMStudioSeqGroup = ^TMStudioSeqGroup;
 TMStudioSeqGroup = record
  SeqLabel: array[1..32] of LChar;
  Name: array[1..64] of LChar;
  Cache: TCacheUser;
  Data: Int32;
 end;
 {$IF SizeOf(TMStudioSeqGroup) <> 104} {$MESSAGE WARN 'Structure size mismatch @ TMStudioSeqGroup.'} {$DEFINE MSME} {$IFEND}


 PMStudioBone = ^TMStudioBone;
 TMStudioBone = record
  Name: array[1..32] of LChar;
  Parent, Flags: Int32;
  BoneController: array[0..5] of Int32;
  Value, Scale: array[0..5] of Single;
 end;
 {$IF SizeOf(TMStudioBone) <> 112} {$MESSAGE WARN 'Structure size mismatch @ TMStudioBone.'} {$DEFINE MSME} {$IFEND}


 PMStudioAnimValue = ^TMStudioAnimValue;
 TMStudioAnimValue = packed record
  case Boolean of
   False: (Valid, Total: Byte);
   True: (Value: UInt16);
 end;
 {$IF SizeOf(TMStudioAnimValue) <> 2} {$MESSAGE WARN 'Structure size mismatch @ TMStudioAnimValue.'} {$DEFINE MSME} {$IFEND}


 PMStudioBBox = ^TMStudioBBox;
 TMStudioBBox = packed record
  Bone, Group: Int32;
  BBMin, BBMax: TVec3;
 end;
 {$IF SizeOf(TMStudioBBox) <> 32} {$MESSAGE WARN 'Structure size mismatch @ TMStudioBBox.'} {$DEFINE MSME} {$IFEND}


 PMStudioAttachment = ^TMStudioAttachment;
 TMStudioAttachment = record
  Name: array[1..32] of LChar;
  AttachmentType, Bone: Int32;
  Origin: TVec3;
  Vectors: array[0..2] of TVec3;
 end;
 {$IF SizeOf(TMStudioAttachment) <> 88} {$MESSAGE WARN 'Structure size mismatch @ TMStudioAttachment.'} {$DEFINE MSME} {$IFEND}


 PStudioCache = ^TStudioCache;
 TStudioCache = record
  Frame: Single;
  Sequence: Int32;
  Angles: TVec3;
  Origin: TVec3;
  Offset: TVec3;
  Controller: array[0..3] of Byte;
  Blending: array[0..1] of Byte;
  Model: PModel; // 52
  HullIndex: UInt32; // 56
  PlaneIndex: UInt32; // 60
  HullCount: UInt32; // 64
 end;

 
// edict.
const
 MAX_ENT_LEAFS = 48; // cf2

 MOVETYPE_NONE = 0; // cf
 MOVETYPE_WALK = 3; // cf
 MOVETYPE_STEP = 4; // cf
 MOVETYPE_FLY = 5; //cf
 MOVETYPE_TOSS = 6;
 MOVETYPE_PUSH = 7; //cf 2
 MOVETYPE_NOCLIP = 8; // cf
 MOVETYPE_FLYMISSILE = 9; // cf
 MOVETYPE_BOUNCE = 10;
 MOVETYPE_BOUNCEMISSILE = 11;
 MOVETYPE_FOLLOW = 12; // confirmed
 MOVETYPE_PUSHSTEP = 13; //cf 2

 AREA_DEPTH = 4; // cf
 AREA_NODES = 32;

 FL_FLY = 1 shl 0; // 1
 FL_SWIM = 1 shl 1; // 2
 FL_CONVEYOR = 1 shl 2; // 4 
 FL_CLIENT = 1 shl 3; // 8
 FL_INWATER = 1 shl 4; // 16 or $10
 FL_MONSTER = 1 shl 5; // 32 or $20
 FL_GODMODE = 1 shl 6; // $40
 FL_NOTARGET = 1 shl 7; // 128 or $80
 FL_ONGROUND = 1 shl 9; // $200
 FL_PARTIALGROUND = 1 shl 10; // $400
 FL_WATERJUMP = 1 shl 11; // $800
 FL_FROZEN = 1 shl 12; // $1000
 FL_FAKECLIENT = 1 shl 13; // $2000
 FL_DUCKING = 1 shl 14; // $4000
 FL_FLOAT = 1 shl 15; // $8000
 FL_IMMUNE_WATER = 1 shl 17; // $20000
 FL_IMMUNE_SLIME = 1 shl 18; // $40000
 FL_IMMUNE_LAVA = 1 shl 19; // $80000
 FL_PROXY = 1 shl 20; // $100000
 FL_ALWAYSTHINK = 1 shl 21; // $200000
 FL_BASEVELOCITY = 1 shl 22; // $400000
 FL_MONSTERCLIP = 1 shl 23; // $800000
 FL_WORLDBRUSH = 1 shl 25; // $2000000
 FL_CUSTOMENTITY = 1 shl 29; // $20000000
 FL_KILLME = 1 shl 30; // $40000000
 FL_DORMANT = 1 shl 31; // $80000000

 WALKMOVE_NORMAL = 0;
 WALKMOVE_WORLDONLY = 1;
 WALKMOVE_CHECKONLY = 2;

 SPAWNFLAG_NOT_DEATHMATCH = 2048;

 // SV_Move movetype
 MOVE_NORMAL = 0; // cf2
 MOVE_NOMONSTERS = 1; // cf2
 MOVE_MISSILE = 2; // cf2

 MAX_CLIP_PLANES = 5;

 DEAD_NO = 0;
 DEAD_DYING = 1;
 DEAD_DEAD = 2;
 DEAD_RESPAWNABLE = 3;
 DEAD_DISCARDBODY = 4;

 DAMAGE_NO = 0;
 DAMAGE_YES = 1;
 DAMAGE_AIM = 2;

 EF_BRIGHTFIELD = 1 shl 0;
 EF_MUZZLEFLASH = 1 shl 1;
 EF_BRIGHTLIGHT = 1 shl 2;
 EF_DIMLIGHT = 1 shl 3;
 EF_INVLIGHT = 1 shl 4;
 EF_NOINTERP = 1 shl 5; // $20, 32
 EF_LIGHT = 1 shl 6;
 EF_NODRAW = 1 shl 7;

 TE_BSPDECAL = 13;

type
 PEdict = ^TEdict; // 804 on linux

 PEntVars = ^TEntVars;
 TEntVars = record
  ClassName, GlobalName: TStringOfs;
  Origin, OldOrigin, Velocity, BaseVelocity, CLBaseVelocity, MoveDir: TVec3;

  Angles, AVelocity, PunchAngle, VAngle: TVec3;

  EndPos, StartPos: TVec3;
  ImpactTime, StartTime: Single;

  FixAngle: Int32;
  IdealPitch, PitchSpeed, IdealYaw, YawSpeed: Single;

  ModelIndex: Int32;
  Model: TStringOfs;

  ViewModel, WeaponModel: Int32;

  AbsMin, AbsMax, MinS, MaxS, Size: TVec3;

  LTime, NextThink: Single;
  MoveType, Solid: Int32;
  Skin, Body, Effects: Int32; // skin: signed
  Gravity, Friction: Single;
  LightLevel: Int32;

  Sequence, GaitSequence: Int32;
  Frame, AnimTime, FrameRate: Single;
  Controller: array[0..3] of Byte;
  Blending: array[0..1] of Byte;

  Scale: Single;
  RenderMode: Int32;
  RenderAmt: Single;
  RenderColor: TVec3;
  RenderFX: Int32;

  Health, Frags: Single;
  Weapons: Int32;
  TakeDamage: Single;

  DeadFlag: Int32;
  ViewOfs: TVec3;

  Button, Impulse: Int32;

  Chain, DmgInflictor, Enemy, AimEnt, Owner, GroundEntity: PEdict;

  SpawnFlags: Int32;
  Flags: UInt32; // unsigned
  ColorMap, Team: Int32;
  MaxHealth, TeleportTime, ArmorType, ArmorValue: Single;
  WaterLevel, WaterType: Int32;

  Target, TargetName, NetName, Msg: TStringOfs;
  DmgTake, DmgSave, Dmg, DmgTime: Single;

  Noise, Noise1, Noise2, Noise3: TStringOfs;

  Speed, AirFinished, PainFinished, RadSuitFinished: Single;

  ContainingEntity: PEdict;

  PlayerClass: Int32;
  MaxSpeed: Single;
  FOV: Single;
  WeaponAnim: Int32;

  PushMSec: Int32;

  InDuck, TimeStepSound, SwimTime, DuckTime, StepLeft: Int32;
  FallVelocity: Single;

  GameState, OldButtons: Int32;
  GroupInfo: UInt32;

  IUser1, IUser2, IUser3, IUser4: Int32;
  FUser1, FUser2, FUser3, FUser4: Single;
  VUser1, VUser2, VUser3, VUser4: TVec3;
  EUser1, EUser2, EUser3, EUser4: PEdict;
 end;
 {$IF SizeOf(TEntVars) <> 676} {$MESSAGE WARN 'Structure size mismatch @ TEntVars.'} {$DEFINE MSME} {$IFEND}

 TEdict = record // 804 L
  Free: UInt32; // +0 signed
  SerialNumber: Int32;
  Area: TLink;
  HeadNode: Int32; // signed
  NumLeafs: Int32;
  LeafNums: array[0..MAX_ENT_LEAFS - 1] of Int16;
  FreeTime: Single;

  PrivateData: Pointer;
  V: TEntVars;
 end;
 TEdictArray = array[0..0] of TEdict;
 {$IF SizeOf(TEdict) <> 804} {$MESSAGE WARN 'Structure size mismatch @ TEdict.'} {$DEFINE MSME} {$IFEND}

 PColor24 = ^TColor24;
 TColor24 = packed record
  R, G, B: Byte;
 end;
 {$IF SizeOf(TColor24) <> 3} {$MESSAGE WARN 'Structure size mismatch @ TColor24.'} {$DEFINE MSME} {$IFEND}

 PEntityState = ^TEntityState; // 340  cf2
 TEntityState = record
  EntityType: Int32;
  Number: UInt32; // revalidate
  MsgTime: Single;

  MessageNum: Int32;

  Origin, Angles: TVec3;

  ModelIndex, Sequence: Int32;
  Frame: Single;
  ColorMap: Int32;
  Skin: UInt16;
  Solid: UInt16;
  Effects: Int32;
  Scale: Single;

  EFlags: Byte;

  RenderMode, RenderAmt: Int32;
  RenderColor: TColor24;
  RenderFX: Int32;

  MoveType: Int32;
  AnimTime, FrameRate: Single;
  Body: Int32;
  Controller: array[0..3] of Byte;
  Blending: array[0..3] of Byte;
  Velocity: TVec3;

  MinS, MaxS: TVec3;

  AimEnt, Owner: Int32;

  Friction, Gravity: Single;

  Team, PlayerClass, Health, Spectator, WeaponModel, GaitSequence: Int32;

  BaseVelocity: TVec3;
  UseHull: Int32;
  OldButtons, OnGround, StepLeft: Int32;

  FallVelocity: Single;

  FOV: Single;
  WeaponAnim: Int32;

  StartPos, EndPos: TVec3;
  ImpactTime, StartTime: Single;

  IUser1, IUser2, IUser3, IUser4: Int32;
  FUser1, FUser2, FUser3, FUser4: Single;
  VUser1, VUser2, VUser3, VUser4: TVec3;
 end;
 TEntityStateArray = array[0..0] of TEntityState;
 PEntityStateArray = ^TEntityStateArray;
 {$IF SizeOf(TEntityState) <> 340} {$MESSAGE WARN 'Structure size mismatch @ TEntityState.'} {$DEFINE MSME} {$IFEND}

 PAreaNode = ^TAreaNode; // 32
 TAreaNode = record
  Axis: Int32;
  Distance: Single;
  Children: array[0..1] of PAreaNode;
  TriggerEdicts, SolidEdicts: TLink;
 end;

 PCachedMove = ^TCachedMove;
 TCachedMove = record // 88
  Active, UpdatePos: Boolean; // 0, 4
  OldOrigin: TVec3; // 8    pos1
  TrueOrigin: TVec3;     // 20    origin
  CurrentOrigin: TVec3;  // 32   pos2
  MinS, MaxS: TVec3; // 44, 56
  NoInterp: Boolean; // +68
  ClientOrigin: TVec3; // +72     neworigin
  FirstFrame: Boolean;  // +84
 end;

// PM. Section confirmed.

const
 MAX_PHYSENTS = 600;
 MAX_MOVEENTS = 64;

 MAX_PHYSINFO_STRING = 256;  // MAX_INFO_STRING

 PM_STUDIO_IGNORE = 1; // cf
 PM_STUDIO_BOX = 2; // cf
 PM_GLASS_IGNORE = 4; // cf
 PM_WORLD_ONLY = 8; // cf

 FTRACE_SIMPLEBOX = 1 shl 0;

type
 PPhysEnt = ^TPhysEnt; // 224
 TPhysEnt = record
  Name: array[1..32] of LChar;
  Player: Int32;  
  Origin: TVec3; // +36
  Model: PModel; // +48
  StudioModel: PModel; // +52
  MinS, MaxS: TVec3; // +56, +68
  Info: Int32; // +80
  Angles: TVec3; // +84
  Solid: Int32; // +96
  Skin: Int32; // +100
  RenderMode: Int32; // +104
  Frame: Single; // +108
  Sequence: Int32; // +112
  Controller: array[0..3] of Byte; // +116
  Blending: array[0..1] of Byte; // +120
  MoveType, TakeDamage, BloodDecal, Team, ClassNumber: Int32;
  IUser1, IUser2, IUser3, IUser4: Int32;
  FUser1, FUser2, FUser3, FUser4: Single;
  VUser1, VUser2, VUser3, VUser4: TVec3;
 end;
 TPhysEntArray = array[0..0] of TPhysEnt;
 PPhysEntArray = ^TPhysEntArray;
 {$IF SizeOf(TPhysEnt) <> 224} {$MESSAGE WARN 'Structure size mismatch @ TPhysEnt.'} {$DEFINE MSME} {$IFEND}


 TPhysEntFunc = function(const E: TPhysEnt): Int32; cdecl;
 
 PMoveVars = ^TMoveVars;
 TMoveVars = record
  Gravity, StopSpeed, MaxSpeed, SpectatorMaxSpeed, Accelerate, AirAccelerate, WaterAccelerate,
  Friction, EdgeFriction, WaterFriction, EntGravity, Bounce, StepSize, MaxVelocity, ZMax,
  WaveHeight: Single;
  Footsteps: Int32;
  SkyName: array[1..32] of LChar;
  RollAngle, RollSpeed, SkyColorR, SkyColorG, SkyColorB,
  SkyVecX, SkyVecY, SkyVecZ: Single;
 end;
 {$IF SizeOf(TMoveVars) <> 132} {$MESSAGE WARN 'Structure size mismatch @ TMoveVars.'} {$DEFINE MSME} {$IFEND}

 PPMPlane = ^TPMPlane;
 TPMPlane = record
  Normal: TVec3;
  Distance: Single;
 end;
 {$IF SizeOf(TPMPlane) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TPMPlane.'} {$DEFINE MSME} {$IFEND}

 PPlane = ^TPlane;
 TPlane = record
  Normal: TVec3;
  Distance: Single;
 end;
 {$IF SizeOf(TPlane) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TPlane.'} {$DEFINE MSME} {$IFEND}

 PPMTrace = ^TPMTrace;
 TPMTrace = record // 68
  AllSolid, StartSolid, InOpen, InWater: Int32;
  Fraction: Single; // +16
  EndPos: TVec3; // +20
  Plane: TPMPlane; // +32
  Ent: Int32; // 48
  DeltaVelocity: TVec3; // 52
  HitGroup: Int32; // 64
 end;
 {$IF SizeOf(TPMTrace) <> 68} {$MESSAGE WARN 'Structure size mismatch @ TPMTrace.'} {$DEFINE MSME} {$IFEND}

 PTrace = ^TTrace;
 TTrace = record
  AllSolid, StartSolid, InOpen, InWater: Int32;
  Fraction: Single;
  EndPos: TVec3;
  Plane: TPlane;
  Ent: PEdict;
  HitGroup: Int32;
 end;
 {$IF SizeOf(TTrace) <> 56} {$MESSAGE WARN 'Structure size mismatch @ TTrace.'} {$DEFINE MSME} {$IFEND}


 PPlayerMove = ^TPlayerMove; // +325068
 TPlayerMove = record
  // Everything's confirmed, if not said otherwise.
  PlayerIndex: Int32; // NC
  Server: Int32; // +4
  Multiplayer: Int32; // NC
  Time, FrameTime: Single; // NC
  Fwd, Right, Up: TVec3; // NC
  Origin: TVec3; // +56
  Angles, OldAngles, Velocity, MoveDir, BaseVelocity, ViewOfs: TVec3; // NC
  DuckTime: Single;
  InDuck: Int32;
  TimeStepSound, StepLeft: Int32;
  FallVelocity: Single;
  PunchAngle: TVec3;
  SwimTime, NextPrimaryAttack: Single;
  Effects, Flags, UseHull: Int32; // 188 for usehull
  Gravity, Friction: Single;
  OldButtons: Int32;
  WaterJumpTime: Single;
  Dead: Int32;
  DeadFlag, Spectator, MoveType: Int32;
  OnGround, WaterLevel, WaterType, OldWaterLevel: Int32;

  TextureName: array[1..256] of LChar;
  TextureType: LChar;

  MaxSpeed, ClientMaxSpeed: Single;
  IUser1, IUser2, IUser3, IUser4: Int32;
  FUser1, FUser2, FUser3, FUser4: Single;
  VUser1, VUser2, VUser3, VUser4: TVec3;

  NumPhysEnt: Int32; // 588
  PhysEnts: array[0..MAX_PHYSENTS - 1] of TPhysEnt; // 592

  NumMoveEnt: Int32; // NC
  MoveEnts: array[0..MAX_MOVEENTS - 1] of TPhysEnt; // NC

  NumVisEnt: Int32; // +149332  confirmed
  VisEnts: array[0..MAX_PHYSENTS - 1] of TPhysEnt; // +149336 confirmed

  Cmd: TUserCmd;
  
  NumTouch: Int32; // +283788
  TouchIndex: array[0..MAX_PHYSENTS - 1] of TPMTrace; // +283792

  PhysInfo: array[1..MAX_PHYSINFO_STRING] of LChar;

  MoveVars: PMoveVars; // +324848
  PlayerMinS, PlayerMaxS: array[0..3] of TVec3; // +324852 and +324900

  // cdecl for compatibility reasons
  // mods have access to this i guess
  PM_Info_ValueForKey: function(S, Key: PLChar): PLChar; cdecl; // +324948
  PM_Particle: procedure(const Origin: TVec3; Color: Int32; Life: Single; ZPos, ZVel: Int32); cdecl; // +324952
  PM_TestPlayerPosition: function(const Pos: TVec3; Trace: PPMTrace): Int32; cdecl; // +324956
  Con_NPrintF: procedure(ID: Int32; S: PLChar); cdecl varargs; // +324960
  Con_DPrintF: procedure(S: PLChar); cdecl varargs; // +324964
  Con_PrintF: procedure(S: PLChar); cdecl varargs; // +324968
  Sys_FloatTime: function: Double; cdecl; // +324972

  PM_StuckTouch: procedure(HitEnt: Int32; const TraceResult: TPMTrace); cdecl;
  PM_PointContents: function(const P: TVec3; TrueContents: PInt32): Int32; cdecl;
  PM_TruePointContents: function(const P: TVec3): Int32; cdecl;
  PM_HullPointContents: function(const Hull: THull; Num: Int32; const P: TVec3): Int32; cdecl;

  PM_PlayerTrace: function(out Trace: TPMTrace; const VStart, VEnd: TVec3; TraceFlags, IgnorePE: Int32): PPMTrace; cdecl;
  PM_TraceLine: function(const VStart, VEnd: TVec3; Flags, UseHull, IgnorePE: Int32): PPMTrace; cdecl;
  RandomLong: function(Low, High: Int32): Int32; cdecl;
  RandomFloat: function(Low, High: Single): Single; cdecl;

  PM_GetModelType: function(const Model: TModel): TModelType; cdecl;
  PM_GetModelBounds: procedure(const Model: TModel; out MinS, MaxS: TVec3); cdecl;
  PM_HullForBSP: function(const E: TPhysEnt; out Offset: TVec3): PHull; cdecl;
  PM_TraceModel: function(const E: TPhysEnt; const VStart, VEnd: TVec3; var T: TTrace): Single; cdecl;

  COM_FileSize: function(Name: PLChar): Int32; cdecl;
  COM_LoadFile: function(Name: PLChar; AllocType: Int32; Length: PUInt32): Pointer; cdecl;
  COM_FreeFile: procedure(Buffer: Pointer); cdecl;

  memfgets: function(MemFile: Pointer; Size: Int32; var FilePos: Int32; Buffer: PLChar; BufferSize: Int32): PLChar; cdecl;

  RunFuncs: Int32; // +325040
  PM_PlaySound: procedure(Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
  PM_TraceTexture: function(Ground: Int32; const VStart, VEnd: TVec3): PLChar; cdecl;
  PM_PlaybackEventFull: procedure(Flags, ClientIndex: Int32; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;

  PM_PlayerTraceEx: function(out Trace: TPMTrace; const VStart, VEnd: TVec3; TraceFlags: Int32; IgnoreFunc: TPhysEntFunc): PPMTrace; cdecl;
  PM_TestPlayerPositionEx: function(const Pos: TVec3; Trace: PPMTrace; IgnoreFunc: TPhysEntFunc): Int32; cdecl;
  PM_TraceLineEx: function(const VStart, VEnd: TVec3; Flags, UseHull: Int32; IgnoreFunc: TPhysEntFunc): PPMTrace; cdecl;
 end;
 {$IF SizeOf(TPlayerMove) <> 325068} {$MESSAGE WARN 'Structure size mismatch @ TPlayerMove.'} {$DEFINE MSME} {$IFEND}



// some stuff from world
 PMoveClip = ^TMoveClip; // 132
 TMoveClip = record
  BoxMinS, BoxMaxS: TVec3; // 0, 12
  MinS, MaxS: PVec3; // 24, 28
  MinS2, MaxS2: TVec3; // 32, 44
  VStart, VEnd: PVec3; // 56, 60
  Trace: TTrace; // 64

  I1, I2: Int16; // 120, 122
  PassEdict: PEdict; // 124 probably
  HullNum: Int32; // 128
 end;

const
 MAX_EVENTS = 256;
 MAX_EVENT_QUEUE = 64;
 
 FEVENT_ORIGIN = 1 shl 0;
 FEVENT_ANGLES = 1 shl 1;
 
 FEV_NOTHOST = 1 shl 0; // 1
 FEV_RELIABLE = 1 shl 1; // 2
 FEV_GLOBAL = 1 shl 2; // 4
 FEV_UPDATE = 1 shl 3; // 8
 FEV_HOSTONLY = 1 shl 4; // 16
 FEV_SERVER = 1 shl 5; // 32
 FEV_CLIENT = 1 shl 6; // 64

type
 PEvent = ^TEvent; // TEventArgs, 72
 TEvent = packed record
  Flags: Int32;
  EntIndex: Int32;

  Origin, Angles, Velocity: TVec3;
  Ducking: Int32;

  FParam1, FParam2: Single;
  IParam1, IParam2: Int32;
  BParam1, BParam2: Int32;
 end;
 {$IF SizeOf(TEvent) <> 72} {$MESSAGE WARN 'Structure size mismatch @ TEvent.'} {$DEFINE MSME} {$IFEND}

 PPrecachedEvent = ^TPrecachedEvent; // 16
 TPrecachedEvent = record
  Index: UInt16;
  Name: PLChar;
  Size: UInt32;
  Data: Pointer;
 end;

 PEventInfo = ^TEventInfo; // 88
 TEventInfo = packed record
  Index: UInt16;
  PacketIndex, EntityIndex: Int16; // signed cf#2 // +2 +4 cf cf
  FireTime: Single; // +6 cf cf
  Args: TEvent; // +10 cf cf
  __Padding: UInt16;
  Flags: UInt32;
 end;
 {$IF SizeOf(TEventInfo) <> 88} {$MESSAGE WARN 'Structure size mismatch @ TEventInfo.'} {$DEFINE MSME} {$IFEND}

 TEventState = array[0..MAX_EVENT_QUEUE - 1] of TEventInfo;

// baseline
const
 MAX_BASELINES = 64;
 
type
 PServerBaseline = ^TServerBaseline;
 TServerBaseline = record
  NumEnts: UInt32; // +0 somewhat confirmed
  Classnames: array[0..MAX_BASELINES - 1] of TStringOfs; // +4 cf
  ES: array[0..MAX_BASELINES - 1] of TEntityState; // +260 cf
 end;



// consistency
type
 PForceType = ^TForceType;
 TForceType = (ftExactFile = 0, ftModelSameBounds, ftModelSpecifyBounds, ftModelSpecifyBoundsIfAvail);

 PConsistency = ^TConsistency; // 44 cf
 TConsistency = record
  Name: PLChar; // 0
  // 4
  // 8
  // 12
  ForceType: TForceType; // 16
  MinS: TVec3; // 20
  MaxS: TVec3; // 32
 end;

 // incoming, from clients
 PPackedConsistency = ^TPackedConsistency;
 TPackedConsistency = packed record
  ForceType: Byte;
  MinS, MaxS: TVec3;
 end;
 {$IF SizeOf(TPackedConsistency) <> 25} {$MESSAGE WARN 'Structure size mismatch @ TPackedConsistency.'} {$DEFINE MSME} {$IFEND}


// clients
const
 MAX_USERINFO_STRING = 256; // client-side dependent

 MAX_PLAYER_NAME = 32; // client-side dependent
 MAX_WEAPON_DATA = 64; // writeclientdatatomessage

 MAX_UNLAG_SAMPLES = 16; // frames to calculate predicted origin against

 // hardcoded limits for both client rates and server cvars.

 MIN_CLIENT_RATE = 1000;
 MAX_CLIENT_RATE = 30000;

 MIN_CLIENT_UPDATERATE = 10;
 MAX_CLIENT_UPDATERATE = 200;

type
 TAuthType = (atUnknown = 0, atSteam, atValve, atHLTV);

 PClientData = ^TClientData; // 476
 TClientData = record
  Origin, Velocity: TVec3;
  ViewModel: Int32;
  PunchAngle: TVec3;
  Flags, WaterLevel, WaterType: Int32;
  ViewOffset: TVec3;
  Health: Single;
  InDuck, Weapons, TimeStepSound, DuckTime, SwimTime, WaterJumpTime: Int32;
  MaxSpeed, FOV: Single;
  WeaponAnim, ID, AmmoShells, AmmoNails, AmmoCells, AmmoRockets: Int32;
  NextAttack: Single;
  TFState, PushMSec, DeadFlag: Int32;
  PhysInfo: array[1..MAX_PHYSINFO_STRING] of LChar;
  IUser1, IUser2, IUser3, IUser4: Int32;
  FUser1, FUser2, FUser3, FUser4: Single;
  VUser1, VUser2, VUser3, VUser4: TVec3;
 end;
 {$IF SizeOf(TClientData) <> 476} {$MESSAGE WARN 'Structure size mismatch @ TClientData.'} {$DEFINE MSME} {$IFEND}

 PWeaponData = ^TWeaponData;
 TWeaponData = record
  ID, Clip: Int32;
  NextPrimaryAttack, NextSecondaryAttack, TimeWeaponIdle: Single;
  InReload, InSpecialReload: Int32;
  NextReload, PumpTime, ReloadTime, AimedDamage, NextAimBonus: Single;
  InZoom, WeaponState: Int32;
  IUser1, IUser2, IUser3, IUser4: Int32;
  FUser1, FUser2, FUser3, FUser4: Single;
 end;         // must be 88
 {$IF SizeOf(TWeaponData) <> 88} {$MESSAGE WARN 'Structure size mismatch @ TWeaponData.'} {$DEFINE MSME} {$IFEND}

 PPacketEntities = ^TPacketEntities;
 TPacketEntities = record
  NumEnts: UInt32; // +0
  
  Ents: PEntityStateArray; // +36
 end;

 PClientFrame = ^TClientFrame; // 6160 cf
 TClientFrame = record
  SentTime: Double;
  PingTime: Single; // +8, cf
  ClientData: TClientData; // +12, cf, size = 476
  WeaponData: array[0..MAX_WEAPON_DATA - 1] of TWeaponData; // +488, cf

  Pack: TPacketEntities; // 6120 cf
 end;
 TClientFrameArray = array[0..0] of TClientFrame;
 PClientFrameArray = array[0..0] of PClientFrame;
 TClientFrameArrayPtr = ^TClientFrameArray;

 PClient = ^TClient; // 20488 W, 20200 L
 TClient = record
  Active: Boolean; // +0, cf
  Spawned: Boolean; // +4, cf
  SendInfo: Boolean; // +8 cf
  Connected: Boolean; // +12 cf
  HasMissingResources: Boolean; // +16 cf (need missing resources)
  UserMsgReady: Boolean; // +20 cf SV_New
  SendConsistency: Boolean; // +24 cf 

  Netchan: TNetchan; // +32?  124 is netmessage (92 + 32)
  ChokeCount: UInt32; // 9536 W, cf, unsigned
  UpdateMask: Int32; // 9540 W, cf signed
  FakeClient: Boolean; // 9272 L 9544 W
  HLTV: Boolean; // 9548 W, cf
  UserCmd: TUserCmd; // 9552 W, cf  size 52

  FirstCmd: Double; // 9608 W, cf
  LastCmd: Double; // 9616 W, cf
  NextCmd: Double; // 9624 W, cf
  Latency: Single; // 9632 W, cf, single (ping)
  PacketLoss: Single; // 9636 W, cf, single

  NextPingTime: Double; // 9648 W, cf, double
  ClientTime: Double;  // 9656 W, cf, double
  UnreliableMessage: TSizeBuf; // 9664 W, yep
  UnreliableMessageData: array[1..MAX_DATAGRAM] of Byte; // 9684.. or more?

  ConnectTime: Double; // +13688 W cf
  NextUpdateTime: Double; // +13696 W cf
  UpdateRate: Double; // +13704 W cf        13424 L

  // ->
  NeedUpdate: Boolean; // 13712 W cf
  SkipThisUpdate: Boolean; // 13436 L  13716 W
  Frames: TClientFrameArrayPtr; // 13720 W
  Events: TEventState; // 13724 W cf

  // client edict pointer
  Entity: PEdict; // 19356 W cf
  Target: PEdict; // view entity, 19360 W cf
  UserID: UInt32; // 19364 W cf

  Auth: record
   AuthType: TAuthType; // +19368 cf
   // ?
   UniqueID: Int64;   // +19376 cf
   IP: array[1..4] of Byte; // +19384 cf
  end;

  // <-

  UserInfo: array[1..MAX_USERINFO_STRING] of LChar; // 19392 W cf
  UpdateInfo: Boolean; // 19648 W cf
  UpdateInfoTime: Single; // 19652 W
  CDKey: array[1..64] of LChar; // +19656 cf
  NetName: array[1..32] of LChar; // 19720 W cf
  TopColor: Int32; // 19752 W cf
  BottomColor: Int32; // 19756 W cf

  DownloadList: TResource; // +19476 L   +19764 W
  UploadList: TResource; // +19612 L   +19900 W
  UploadComplete: Boolean; // +20040 W cf
  Customization: TCustomization; // +20044 W cf

  MapCRC: TCRC; // +20208 W cf
  LW: Boolean; // weapon prediction;  +20212 W
  LC: Boolean; // lag compensation; +20216 W
  PhysInfo: array[1..256] of LChar; // +20220 W cf

  VoiceLoopback: Boolean; // +20476 cf
  BlockedVoice: set of 0..MAX_PLAYERS - 1; // +20480 W cf



  // Custom fields
  Protocol: Byte; // for double-protocol support

  // filters
  SendResTime: Double;
  SendEntsTime: Double;
  FullUpdateTime: Double;

  // an experimental filter for "new" command, it restricts the command to being sent only once during the single server sequence.
  ConnectSeq: UInt32;
  SpawnSeq: UInt32;

 end;
 TClientArray = array[0..0] of TClient;

 TFragmentSizeFunc = function(Client: PClient): UInt32; cdecl;

type
 PLogNode = ^TLogNode;
 TLogNode = record
  Adr: TNetAdr;
  Prev, Next: PLogNode;
 end;


// savegame
const
 MAX_LEVEL_CONNECTIONS = 16;

type
 PLevelList = ^TLevelList;
 TLevelList = record
  MapName, LandmarkName: array[1..32] of LChar;
  LandmarkEntity: PEdict;
  LandmarkOrigin: TVec3;
 end;

 PEntityTable = ^TEntityTable;
 TEntityTable = record
  ID: Int32;
  Entity: PEdict;
  Location, Size, Flags, ClassName: Int32;
 end;
 
 PSaveRestoreData = ^TSaveRestoreData; // 1396 cf!
 TSaveRestoreData = record
  BaseData, CurrentData: PLChar;
  Size, BufferSize, TokenSize, TokenCount: Int32;
  Tokens: ^PLChar;
  CurrentIndex, TableCount, ConnectionCount: Int32;
  Table: PEntityTable;
  LevelList: array[0..MAX_LEVEL_CONNECTIONS - 1] of TLevelList;
  UseLandmark: Int32;
  LandmarkName: array[1..20] of LChar;
  LandmarkOffset: TVec3;
  Time: Single;
  CurrentMapName: array[1..32] of LChar;
 end;


// blending interface
const
 SV_BLENDING_INTERFACE_VERSION = 1;

type
 PSVBlendingInterface = ^TSVBlendingInterface;
 TSVBlendingInterface = record
  Version: Int32;
  SV_StudioSetupBones: procedure(var Model: TModel; Frame: Single; Sequence: Int32; const Angles, Origin: TVec3; Controller, Blending: PByte; Bone: Int32; Ent: PEdict); cdecl;
 end;
 {$IF SizeOf(TSVBlendingInterface) <> 8} {$MESSAGE WARN 'Structure size mismatch @ TSVBlendingInterface.'} {$DEFINE MSME} {$IFEND}

 PEngineStudioAPI = ^TEngineStudioAPI;
 TEngineStudioAPI = record
  Mem_CAlloc: function(Count, Size: UInt32): Pointer; cdecl;
  Cache_Check: function(C: PCacheUser): Pointer; cdecl;
  COM_LoadCacheFile: function(Name: PLChar; Cache: PCacheUser): Pointer; cdecl;
  Mod_ExtraData: function(var M: TModel): Pointer; cdecl;
 end;
 {$IF SizeOf(TEngineStudioAPI) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TEngineStudioAPI.'} {$DEFINE MSME} {$IFEND}

type
 TExtLibExport = record
  Func: Pointer;
  Name: PLChar;
 end;
 TExtLibExportArray = array[0..0] of TExtLibExport;

 PExtLibData = ^TExtLibData;
 TExtLibData = record
  Handle: THandle;
  ExportTable: ^TExtLibExportArray;
  NumExport: UInt32;
 end;
 

 PKeyValueData = ^TKeyValueData;
 TKeyValueData = record
  Classname, Key, Value: PLChar;
  Handled: Int32;
 end;
 {$IF SizeOf(TKeyValueData) <> 16} {$MESSAGE WARN 'Structure size mismatch @ TKeyValueData.'} {$DEFINE MSME} {$IFEND}

 PTypeDescription = ^TTypeDescription;
 TTypeDescription = record

 end;

 PTraceResult = ^TTraceResult;
 TTraceResult = record
  AllSolid, StartSolid, InOpen, InWater: Int32;
  Fraction: Single;
  EndPos: TVec3;
  PlaneDist: Single;
  PlaneNormal: TVec3;
  Entity: PEdict;
  HitGroup: Int32;
 end;
 {$IF SizeOf(TTraceResult) <> 56} {$MESSAGE WARN 'Structure size mismatch @ TTraceResult.'} {$DEFINE MSME} {$IFEND}

 PUserMsg = ^TUserMsg; // 32
 TUserMsg = record
  Index: Int32;
  Size: Int32; // -1
  Name: array[1..16] of LChar;
  Prev: PUserMsg;
  Func: function(Name: PLChar; Size: Int32; Buffer: Pointer): Int32; cdecl;
 end;

 TAlertType = (atNotice = 0, atConsole, atAIConsole, atWarning, atError, atLogged);
 TPrintType = (PrintConsole = 0, PrintCenter, PrintChat);

// gamedll
const
 SVC_BAD = 0;
 SVC_NOP = 1;
 SVC_DISCONNECT = 2;
 SVC_EVENT = 3;
 SVC_SETVIEW = 5;
 SVC_SOUND = 6;
 SVC_TIME = 7;
 SVC_PRINT = 8;
 SVC_STUFFTEXT = 9;
 SVC_SETANGLE = 10;
 SVC_SERVERINFO = 11;
 SVC_LIGHTSTYLE = 12;
 SVC_UPDATEUSERINFO = 13;
 SVC_DELTADESCRIPTION = 14;
 SVC_CLIENTDATA = 15;
 SVC_PINGS = 17;
 SVC_PARTICLE = 18;
 SVC_SPAWNSTATIC = 20;
 SVC_EVENT_RELIABLE = 21;
 SVC_SPAWNBASELINE = 22;
 SVC_TEMPENTITY = 23;
 SVC_SETPAUSE = 24;
 SVC_SIGNONNUM = 25;
 SVC_CENTERPRINT = 26;
 SVC_SPAWNSTATICSOUND = 29;
 SVC_CDTRACK = 32;
 SVC_RESTORE = 33;
 SVC_ADDANGLE = 38;
 SVC_NEWUSERMSG = 39;
 SVC_PACKETENTITIES = 40;
 SVC_DELTAPACKETENTITIES = 41;
 SVC_CHOKE = 42;
 SVC_RESOURCELIST = 43;
 SVC_NEWMOVEVARS = 44;
 SVC_RESOURCEREQUEST = 45;
 SVC_CUSTOMIZATION = 46;
 SVC_CROSSHAIRANGLE = 47;
 SVC_SOUNDFADE = 48;
 SVC_FILETXFERFAILED = 49;
 SVC_VOICEINIT = 52;
 SVC_VOICEDATA = 53;
 SVC_SENDEXTRAINFO = 54;
 SVC_RESOURCELOCATION = 56;
 SVC_SENDCVARVALUE = 57;
 SVC_SENDCVARVALUE2 = 58;

 SVC_MESSAGE_END = SVC_SENDCVARVALUE2;

 CLC_BAD = 0;
 CLC_NOP = 1;
 CLC_MOVE = 2;
 CLC_STRINGCMD = 3;
 CLC_DELTA = 4;
 CLC_RESOURCELIST = 5;
 CLC_TMOVE = 6;
 CLC_FILECONSISTENCY = 7;
 CLC_VOICEDATA = 8;
 CLC_HLTV = 9;
 CLC_CVARVALUE = 10;
 CLC_CVARVALUE2 = 11;

 CLC_MESSAGE_END = CLC_CVARVALUE2;

const
 NEWDLL_INTERFACE_VERSION = 1;
 DLL_INTERFACE_VERSION = 140;

type
 TEntityInitFunc = procedure(var EV: TEntVars); cdecl;

 PEngineFuncs = ^TEngineFuncs;
 TEngineFuncs = record
  PrecacheModel: function(Name: PLChar): UInt32; cdecl;
  PrecacheSound: function(Name: PLChar): UInt32; cdecl;
  SetModel: procedure(var E: TEdict; ModelName: PLChar); cdecl;
  ModelIndex: function(Name: PLChar): Int32; cdecl;
  ModelFrames: function(Index: Int32): Int32; cdecl;
  SetSize: procedure(var E: TEdict; const MinS, MaxS: TVec3); cdecl;
  ChangeLevel: procedure(S1, S2: PLChar); cdecl;
  SetSpawnParms: procedure(var E: TEdict); cdecl;
  SaveSpawnParms: procedure(var E: TEdict); cdecl;
  VecToYaw: function(const V: TVec3): Double; cdecl; // single in SDK
  VecToAngles: procedure(const Fwd: TVec3; out Angles: TVec3); cdecl;
  MoveToOrigin: procedure(var E: TEdict; const Target: TVec3; Distance: Single; MoveType: Int32); cdecl;
  ChangeYaw: procedure(var E: TEdict); cdecl;
  ChangePitch: procedure(var E: TEdict); cdecl;
  FindEntityByString: function(const E: TEdict; Key, Value: PLChar): PEdict; cdecl;
  GetEntityIllum: function(const E: TEdict): Int32; cdecl;
  FindEntityInSphere: function(const E: TEdict; const Origin: TVec3; Distance: Single): PEdict; cdecl;
  FindClientInPVS: function(const E: TEdict): PEdict; cdecl;
  EntitiesInPVS: function(const E: TEdict): PEdict; cdecl;
  MakeVectors: procedure(const V: TVec3); cdecl;
  AngleVectors: procedure(const Angles: TVec3; Fwd, Right, Up: PVec3); cdecl;

  CreateEntity: function: PEdict; cdecl;
  RemoveEntity: procedure(var E: TEdict); cdecl;
  CreateNamedEntity: function(ClassName: TStringOfs): PEdict; cdecl;
  
  MakeStatic: procedure(var E: TEdict); cdecl;
  EntIsOnFloor: function(const E: TEdict): Int32; cdecl;
  DropToFloor: function(var E: TEdict): Int32; cdecl;
  WalkMove: function(var E: TEdict; Yaw, Distance: Single; Mode: Int32): Int32; cdecl;

  SetOrigin: procedure(var E: TEdict; const Origin: TVec3); cdecl;
  EmitSound: procedure(const E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
  EmitAmbientSound: procedure(const E: TEdict; const Origin: TVec3; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
  TraceLine: procedure(const V1, V2: TVec3; MoveType: Int32; E: PEdict; out Trace: TTraceResult); cdecl;
  TraceToss: procedure(const E: TEdict; IgnoreEnt: PEdict; out Trace: TTraceResult); cdecl;
  TraceMonsterHull: function(const E: TEdict; const V1, V2: TVec3; MoveType: Int32; EntityToSkip: PEdict; out Trace: TTraceResult): Int32; cdecl;
  TraceHull: procedure(const V1, V2: TVec3; MoveType, HullNumber: Int32; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;
  TraceModel: procedure(const V1, V2: TVec3; HullNumber: Int32; var E: TEdict; out Trace: TTraceResult); cdecl;
  TraceTexture: function(E: PEdict; const V1, V2: TVec3): PLChar; cdecl;
  TraceSphere: procedure(const V1, V2: TVec3; MoveType: Int32; Radius: Single; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;

  GetAimVector: procedure(E: PEdict; Speed: Single; out VOut: TVec3); cdecl;
  ServerCommand: procedure(S: PLChar); cdecl;
  ServerExecute: procedure; cdecl;
  ClientCommand: procedure(const E: TEdict; S: PLChar); cdecl; // varargs
  ParticleEffect: procedure(const Origin, Direction: TVec3; Color, Count: Single); cdecl;
  LightStyle: procedure(Style: Int32; Value: PLChar); cdecl;
  DecalIndex: function(DecalName: PLChar): Int32; cdecl; // can return -1!
  PointContents: function(const Point: TVec3): Int32; cdecl;
  MessageBegin: procedure(Dest, MessageType: Int32; Origin: PVec3; E: PEdict); cdecl;
  MessageEnd: procedure; cdecl;
  WriteByte: procedure(Value: Int32); cdecl;
  WriteChar: procedure(Value: Int32); cdecl;
  WriteShort: procedure(Value: Int32); cdecl;
  WriteLong: procedure(Value: Int32); cdecl;
  WriteAngle: procedure(Value: Single); cdecl;
  WriteCoord: procedure(Value: Single); cdecl;
  WriteString: procedure(S: PLChar); cdecl;
  WriteEntity: procedure(Value: Int32); cdecl;

  CVarRegister: procedure(var C: TCVar); cdecl;
  CVarGetFloat: function(Name: PLChar): Single; cdecl;  // double?
  CVarGetString: function(Name: PLChar): PLChar; cdecl;
  CVarSetFloat: procedure(Name: PLChar; Value: Single); cdecl;
  CVarSetString: procedure(Name, Value: PLChar); cdecl;
  AlertMessage: procedure(AlertType: TAlertType; Msg: PChar); cdecl;
  EngineFPrintF: procedure(F: Pointer; Msg: PLChar); cdecl;

  PvAllocEntPrivateData: function(var E: TEdict; Size: Int32): Pointer; cdecl;
  PvEntPrivateData: function(const E: TEdict): Pointer; cdecl;
  FreeEntPrivateData: procedure(var E: TEdict); cdecl;
  SzFromIndex: function(Index: TStringOfs): PLChar; cdecl;
  AllocEngineString: function(S: PLChar): TStringOfs; cdecl;
  GetVarsOfEnt: function(const E: TEdict): PEntVars; cdecl;
  PEntityOfEntOffset: function(Offset: UInt32): PEdict; cdecl;
  EntOffsetOfPEntity: function(const E: TEdict): UInt32; cdecl;
  IndexOfEdict: function(E: PEdict): Int32; cdecl;
  PEntityOfEntIndex: function(Index: Int32): PEdict; cdecl;
  FindEntityByVars: function(const E: TEntVars): PEdict; cdecl;

  GetModelPtr: function(E: PEdict): Pointer; cdecl;
  RegUserMsg: function(Name: PLChar; Size: Int32): Int32; cdecl;
  AnimationAutomove: procedure(var E: TEdict; Time: Single); cdecl;
  GetBonePosition: procedure(var E: TEdict; Bone: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;
  FunctionFromName: function(Name: PLChar): Pointer; cdecl;
  NameForFunction: function(Func: Pointer): PLChar; cdecl;

  ClientPrintF: procedure(const E: TEdict; PrintType: TPrintType; Msg: PLChar); cdecl;
  ServerPrint: procedure(Msg: PLChar); cdecl;
  Cmd_Args: function: PLChar; cdecl;
  Cmd_Argv: function(I: Int32): PLChar; cdecl;
  Cmd_Argc: function: Int32; cdecl;

  GetAttachment: procedure(var E: TEdict; Attachment: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;

  CRC32_Init: procedure(out CRC: TCRC); cdecl;
  CRC32_ProcessBuffer: procedure(var CRC: TCRC; Buffer: Pointer; Size: UInt32); cdecl;
  CRC32_ProcessByte: procedure(var CRC: TCRC; B: Byte); cdecl;
  CRC32_Final: function(CRC: TCRC): TCRC; cdecl;

  RandomLong: function(Low, High: Int32): Int32; cdecl;
  RandomFloat: function(Low, High: Single): Double; cdecl; // single?

  SetView: procedure(const Entity, Target: TEdict); cdecl;
  Time: function: Double; cdecl;
  CrosshairAngle: procedure(const Entity: TEdict; Pitch, Yaw: Single); cdecl;
  LoadFileForMe: function(Name: PLChar; Length: PUInt32): Pointer; cdecl;
  FreeFile: procedure(Buffer: Pointer); cdecl;
  EndSection: procedure(Name: PLChar); cdecl;
  CompareFileTime: function(S1, S2: PLChar; CompareResult: PInt32): Int32; cdecl;
  GetGameDir: procedure(Buffer: PLChar); cdecl;
  CVar_RegisterVariable: procedure(var C: TCVar); cdecl;
  FadeClientVolume: procedure(const Entity: TEdict; FadePercent, FadeOutSeconds, HoldTime, FadeInSeconds: Int32); cdecl;
  SetClientMaxSpeed: procedure(var E: TEdict; Speed: Single); cdecl;

  CreateFakeClient: function(Name: PLChar): PEdict; cdecl;
  RunPlayerMove: procedure(const FakeClient: TEdict; const Angles: TVec3; FwdMove, SideMove, UpMove: Single; Buttons: Int16; Impulse, MSec: Byte); cdecl;
  NumberOfEntities: function: UInt32; cdecl;
  GetInfoKeyBuffer: function(E: PEdict): PLChar; cdecl;
  InfoKeyValue: function(Buffer, Key: PLChar): PLChar; cdecl;
  SetKeyValue: procedure(Buffer, Key, Value: PLChar); cdecl;
  SetClientKeyValue: procedure(Index: Int32; Buffer, Key, Value: PLChar); cdecl;
  IsMapValid: function(Name: PLChar): Int32; cdecl;
  StaticDecal: procedure(const Origin: TVec3; DecalIndex, EntityIndex, ModelIndex: Int32); cdecl;
  PrecacheGeneric: function(Name: PLChar): UInt32; cdecl;
  GetPlayerUserID: function(const E: TEdict): Int32; cdecl;
  BuildSoundMsg: procedure(const E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch, Dest, MessageType: Int32; const Origin: TVec3; MsgEnt: PEdict); cdecl;
  IsDedicatedServer: function: Int32; cdecl;
  CVarGetPointer: function(Name: PLChar): PCVar; cdecl;
  GetPlayerWONID: function(const E: TEdict): Int32; cdecl;

  Info_RemoveKey: procedure(Data, Key: PLChar); cdecl;
  GetPhysicsKeyValue: function(const E: TEdict; Key: PLChar): PLChar; cdecl;
  SetPhysicsKeyValue: procedure(const E: TEdict; Key, Value: PLChar); cdecl;
  GetPhysicsInfoString: function(const E: TEdict): PLChar; cdecl;
  PrecacheEvent: function(EventType: Int32; Name: PLChar): UInt16; cdecl;
  PlaybackEvent: procedure(Flags: UInt32; const E: TEdict; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;

  SetFatPVS: function(const Origin: TVec3): PByte; cdecl;
  SetFatPAS: function(const Origin: TVec3): PByte; cdecl;
  CheckVisibility: function(var E: TEdict; VisSet: PByte): Int32; cdecl;

  DeltaSetField: procedure(var D: TDelta; FieldName: PLChar); cdecl;
  DeltaUnsetField: procedure(var D: TDelta; FieldName: PLChar); cdecl;
  DeltaAddEncoder: procedure(Name: PLChar; Func: TDeltaEncoder); cdecl;
  GetCurrentPlayer: function: Int32; cdecl;
  CanSkipPlayer: function(const E: TEdict): Int32; cdecl;
  DeltaFindField: function(const D: TDelta; FieldName: PLChar): Int32; cdecl;
  DeltaSetFieldByIndex: procedure(var D: TDelta; FieldNumber: UInt32); cdecl;
  DeltaUnsetFieldByIndex: procedure(var D: TDelta; FieldNumber: UInt32); cdecl;

  SetGroupMask: procedure(Mask, Op: Int32); cdecl;
  CreateInstancedBaseline: function(ClassName: UInt32; const Baseline: TEntityState): Int32; cdecl;
  CVar_DirectSet: procedure(var C: TCVar; Value: PLChar); cdecl;
  ForceUnmodified: procedure(FT: TForceType; MinS, MaxS: PVec3; FileName: PLChar); cdecl;
  GetPlayerStats: procedure(const E: TEdict; out Ping, PacketLoss: Int32); cdecl;
  AddServerCommand: procedure(Name: PLChar; Func: TCmdFunction); cdecl;
  Voice_GetClientListening: function(Receiver, Sender: Int32): Int32; cdecl;
  Voice_SetClientListening: function(Receiver, Sender, IsListening: Int32): Int32; cdecl;

  GetPlayerAuthID: function(const E: TEdict): PLChar; cdecl;

  SequenceGet: function(FileName, EntryName: PLChar): Pointer; cdecl;
  SequencePickSentence: function(GroupName: PLChar; PickMethod: Int32; var Picked: Int32): Pointer; cdecl;

  GetFileSize: function(FileName: PLChar): UInt32; cdecl;
  GetApproxWavePlayLength: function(FileName: PLChar): UInt32; cdecl;

  IsCareerMatch: function: Int32; cdecl;
  GetLocalizedStringLength: function(S: PLChar): UInt32; cdecl;
  RegisterTutorMessageShown: procedure(MessageID: Int32); cdecl;
  GetTimesTutorMessageShown: function(MessageID: Int32): Int32; cdecl;
  ProcessTutorMessageDecayBuffer: procedure(Buffer: Pointer; Length: UInt32); cdecl;
  ConstructTutorMessageDecayBuffer: procedure(Buffer: Pointer; Length: UInt32); cdecl;
  ResetTutorMessageDecayData: procedure; cdecl;

  QueryClientCVarValue: procedure(var E: TEdict; Name: PLChar); cdecl;
  QueryClientCVarValue2: procedure(var E: TEdict; Name: PLChar; RequestID: Int32); cdecl;
  CheckParm: function(Token: PLChar; var Next: PLChar): UInt32; cdecl;


  // For tracking down mismatched pointers and for possible API expansion
  ReservedStart: function: Pointer; cdecl;
  Reserved1: function: Pointer; cdecl;
  Reserved2: function: Pointer; cdecl;
  Reserved3: function: Pointer; cdecl;
  Reserved4: function: Pointer; cdecl;
  Reserved5: function: Pointer; cdecl;
  Reserved6: function: Pointer; cdecl;
  Reserved7: function: Pointer; cdecl;
  Reserved8: function: Pointer; cdecl;
  Reserved9: function: Pointer; cdecl;
  ReservedEnd: function: Pointer; cdecl;
 end;

 PGlobalVars = ^TGlobalVars;
 TGlobalVars = record
  Time, FrameTime, ForceRetouch: Single;
  MapName, StartSpot: Int32;
  Deathmatch, Coop, Teamplay, ServerFlags, FoundSecrets: Single;
  Fwd, Up, Right: TVec3;
  TraceAllSolid, TraceStartSolid, TraceFraction: Single;
  TraceEndPos, TracePlaneNormal: TVec3;
  TracePlaneDist: Single;
  TraceEnt: PEdict;
  TraceInOpen, TraceInWater: Single;
  TraceHitGroup, TraceFlags: Int32;
  MsgEntity, CDAudioTrack, MaxClients, MaxEntities: Int32;
  StringBase: PLChar;
  SaveData: Pointer;
  LandmarkOffset: TVec3;
 end;
 
 PDLLFunctions = ^TDLLFunctions;
 TDLLFunctions = record
  GameInit: procedure; cdecl; // +0

  Spawn: function(var E: TEdict): Int32; cdecl; // +1
  Think: procedure(var E: TEdict); cdecl; // +2
  Use: procedure(var Used, Other: TEdict); cdecl; // +3 not used?
  Touch: procedure(var Touched, Other: TEdict); cdecl; // +4
  Blocked: procedure(var Blocked, Other: TEdict); cdecl; // +5
  KeyValue: procedure(var E: TEdict; Data: PKeyValueData); cdecl; // +6
  Save: procedure(var E: TEdict; var SaveData: TSaveRestoreData); cdecl;
  Restore: function(var E: TEdict; var SaveData: TSaveRestoreData; GlobalEntity: Int32): Int32; cdecl;
  SetAbsBox: procedure(var E: TEdict); cdecl; // 9
  SaveWriteFields: procedure(SaveData: PSaveRestoreData; Name: PLChar; BaseData: Pointer; Fields: PTypeDescription; FieldCount: Int32); cdecl;
  SaveReadFields: procedure(SaveData: PSaveRestoreData; Name: PLChar; BaseData: Pointer; Fields: PTypeDescription; FieldCount: Int32); cdecl;
  SaveGlobalState: procedure(SaveData: PSaveRestoreData); cdecl;
  RestoreGlobalState: procedure(SaveData: PSaveRestoreData); cdecl;
  ResetGlobalState: procedure cdecl;

  ClientConnect: function(var E: TEdict; Name, Address: PLChar; RejectReason: Pointer): Int32; cdecl;
  ClientDisconnect: procedure(var E: TEdict); cdecl; // 16
  ClientKill: procedure(var E: TEdict); cdecl;
  ClientPutInServer: procedure(var E: TEdict); cdecl;
  ClientCommand: procedure(var E: TEdict); cdecl;
  ClientUserInfoChanged: procedure(var E: TEdict; Buffer: PLChar); cdecl; // +20
  ServerActivate: procedure(var List: TEdict; EntityCount, MaxClients: Int32); cdecl;
  ServerDeactivate: procedure; cdecl; // 22
  PlayerPreThink: procedure(var E: TEdict); cdecl; // +23
  PlayerPostThink: procedure(var E: TEdict); cdecl; // +24
  StartFrame: procedure; cdecl; // +25
  ParmsNewLevel: procedure; cdecl;
  ParmsChangeLevel: procedure; cdecl;

  GetGameDescription: function: PLChar; cdecl; // +28 *4
  PlayerCustomization: procedure(var E: TEdict; Custom: PCustomization); cdecl;
  SpectatorConnect: procedure(var E: TEdict); cdecl;
  SpectatorDisconnect: procedure(var E: TEdict); cdecl;
  SpectatorThink: procedure(var E: TEdict); cdecl;
  Sys_Error: procedure(ErrorString: PLChar); cdecl;
  PM_Move: procedure(var PlayerMove: TPlayerMove; Server: Int32); cdecl; // 34
  PM_Init: procedure(var PlayerMove: TPlayerMove); cdecl; // +35

  PM_FindTextureType: function(Name: PLChar): PLChar; cdecl;
  SetupVisibility: procedure(var Target, Entity: TEdict; var PVS, PAS: PByte); cdecl;
  UpdateClientData: procedure(var E: TEdict; SendWeapons: Int32; var ClientData: TClientData); cdecl;
  AddToFullPack: function(var State: TEntityState; Index: UInt32; var Entity, Host: TEdict; HostFlags, Player: Int32; PackSet: PByte): Int32; cdecl;
  CreateBaseline: procedure(Player, EntityIndex: Int32; BaseLine: Pointer; var E: TEdict; PlayerModelIndex: Int32; PlayerMinS, PlayerMaxS: PVec3); cdecl;
  RegisterEncoders: procedure; cdecl;
  GetWeaponData: function(var E: TEdict; var Info: TWeaponData): Int32; cdecl;
  CmdStart: procedure(var E: TEdict; var Command: TUserCmd; RandomSeed: UInt32); cdecl; // +43
  CmdEnd: procedure(var E: TEdict); cdecl; // +44
  ConnectionlessPacket: function(var Address: TNetAdr; Args, ResponseBuffer: PLChar; var ResponseBufferSize: Int32): Int32; cdecl; // +45
  GetHullBounds: function(HullNumber: Int32; const MinS, MaxS: TVec3): Int32; cdecl;
  CreateInstancedBaselines: procedure; cdecl;
  InconsistentFile: function(var E: TEdict; FileName, DisconnectMessage: PLChar): Int32; cdecl;
  AllowLagCompensation: function: Int32; cdecl; // +49
 end;

 PNewDLLFunctions = ^TNewDLLFunctions;
 TNewDLLFunctions = record
  OnFreeEntPrivateData: procedure(var E: TEdict); cdecl;
  GameShutdown: procedure; cdecl;
  ShouldCollide: function(var Touched, Other: TEdict): Int32; cdecl;
  CVarValue: procedure(var E: TEdict; Value: PLChar); cdecl;
  CVarValue2: procedure(var E: TEdict; RequestID: Int32; CVarName, Value: PLChar); cdecl;
 end;

 THostParms = record
  BaseDir: PLChar;
  ArgCount: UInt;
  ArgData: ^PLChar;
  MemBase: Pointer;
  MemSize: UInt;
 end;

{$IFDEF MSME}
 {$MESSAGE WARN 'One of the fixed-size structures failed to pass validation check.'}
 {$MESSAGE WARN 'This could usually mean that there was a change in one of these structures,'}
 {$MESSAGE WARN 'or the compiler incorrectly assembles the type definitions.'}
 {$MESSAGE WARN 'Compiling under a different platform or architecture can also be the cause.'}

 {$IFDEF FPC}
  {$FATAL The compilation process was stopped.}
 {$ELSE}
  {$MESSAGE FATAL 'The compilation process was stopped.'}
 {$ENDIF}
{$ELSE}
 {$IFDEF MSMW}
  {$MESSAGE WARN 'One of the fixed-size structures failed to pass validation check.'}
  {$MESSAGE WARN 'This could usually mean that there was a change in one of these structures,'}
  {$MESSAGE WARN 'or the compiler incorrectly assembles the type definitions.'}
  {$MESSAGE WARN 'Compiling under a different platform or architecture can also be the cause.'}

  {$MESSAGE WARN 'However, the code that relies on these structures is expected to work fine,'}
  {$MESSAGE WARN 'since there are no observed dependencies on game libraries or third-party components.'}
 {$ENDIF}
{$ENDIF}

implementation

end.
