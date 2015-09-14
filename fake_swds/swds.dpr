library swds;

{$I swds.inc}

uses
 Default in '..\Default.pas',
 SDK in '..\SDK.pas';

var
 EngOrig: TEngineFuncs;

function PrecacheModel(Name: PLChar): UInt32; cdecl;
begin
Result := EngOrig.PrecacheModel(Name);
end;

function PrecacheSound(Name: PLChar): UInt32; cdecl;
begin
Result := EngOrig.PrecacheSound(Name);
end;

procedure SetModel(var E: TEdict; ModelName: PLChar); cdecl;
begin
EngOrig.SetModel(E, ModelName);
end;

function ModelIndex(Name: PLChar): Int32; cdecl;
begin
Result := EngOrig.ModelIndex(Name);
end;

function ModelFrames(Index: Int32): Int32; cdecl;
begin
Result := EngOrig.ModelFrames(Index);
end;

procedure SetSize(var E: TEdict; var MinS, MaxS: TVec3); cdecl;
begin
EngOrig.SetSize(E, MinS, MaxS);
end;

procedure ChangeLevel(S1, S2: PLChar); cdecl;
begin
EngOrig.ChangeLevel(S1, S2);
end;

procedure SetSpawnParms(var E: TEdict); cdecl;
begin
EngOrig.SetSpawnParms(E);
end;

procedure SaveSpawnParms(var E: TEdict); cdecl;
begin
EngOrig.SaveSpawnParms(E);
end;

function VecToYaw(var V: TVec3): Double; cdecl;
begin
Result := EngOrig.VecToYaw(V);
end;

procedure VecToAngles(var Fwd: TVec3; out Angles: TVec3); cdecl;
begin
EngOrig.VecToAngles(Fwd, Angles);
end;

procedure MoveToOrigin(var E: TEdict; var Target: TVec3; Distance: Single; MoveType: Int32); cdecl;
begin
EngOrig.MoveToOrigin(E, Target, Distance, MoveType);
end;

procedure ChangeYaw(var E: TEdict); cdecl;
begin
EngOrig.ChangeYaw(E);
end;

procedure ChangePitch(var E: TEdict); cdecl;
begin
EngOrig.ChangePitch(E);
end;

function FindEntityByString(var E: TEdict; Key, Value: PLChar): PEdict; cdecl;
begin
Result := EngOrig.FindEntityByString(E, Key, Value);
end;

function GetEntityIllum(var E: TEdict): Int32; cdecl;
begin
Result := EngOrig.GetEntityIllum(E);
end;

function FindEntityInSphere(var E: TEdict; var Origin: TVec3; Distance: Single): PEdict; cdecl;
begin
Result := EngOrig.FindEntityInSphere(E, Origin, Distance);
end;

function FindClientInPVS(var E: TEdict): PEdict; cdecl;
begin
Result := EngOrig.FindClientInPVS(E);
end;

function EntitiesInPVS(var E: TEdict): PEdict; cdecl;
begin
Result := EngOrig.EntitiesInPVS(E);
end;

procedure MakeVectors(var V: TVec3); cdecl;
begin
EngOrig.MakeVectors(V);
end;

procedure AngleVectors(var Angles: TVec3; Fwd, Right, Up: PVec3); cdecl;
begin
EngOrig.AngleVectors(Angles, Fwd, Right, Up);
end;

function CreateEntity: PEdict; cdecl;
begin
Result := EngOrig.CreateEntity;
end;

procedure RemoveEntity(var E: TEdict); cdecl;
begin
EngOrig.RemoveEntity(E);
end;

function CreateNamedEntity(ClassName: TStringOfs): PEdict; cdecl;
begin
Result := EngOrig.CreateNamedEntity(ClassName);
end;

procedure MakeStatic(var E: TEdict); cdecl;
begin
EngOrig.MakeStatic(E);
end;

function EntIsOnFloor(var E: TEdict): Int32; cdecl;
begin
Result := EngOrig.EntIsOnFloor(E);
end;

function DropToFloor(var E: TEdict): Int32; cdecl;
begin
Result := EngOrig.DropToFloor(E);
end;

function WalkMove(var E: TEdict; Yaw, Distance: Single; Mode: Int32): Int32; cdecl;
begin
Result := EngOrig.WalkMove(E, Yaw, Distance, Mode);
end;

procedure SetOrigin(var E: TEdict; var Origin: TVec3); cdecl;
begin
EngOrig.SetOrigin(E, Origin);
end;

procedure EmitSound(var E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
begin
EngOrig.EmitSound(E, Channel, Sample, Volume, Attn, Flags, Pitch);
end;

procedure EmitAmbientSound(var E: TEdict; var Origin: TVec3; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
begin
EngOrig.EmitAmbientSound(E, Origin, Sample, Volume, Attn, Flags, Pitch);
end;

procedure TraceLine(var V1, V2: TVec3; MoveType: Int32; E: PEdict; out Trace: TTraceResult); cdecl;
begin
EngOrig.TraceLine(V1, V2, MoveType, E, Trace);
end;

procedure TraceToss(var E: TEdict; IgnoreEnt: PEdict; out Trace: TTraceResult); cdecl;
begin
EngOrig.TraceToss(E, IgnoreEnt, Trace);
end;

function TraceMonsterHull(var E: TEdict; var V1, V2: TVec3; MoveType: Int32; EntityToSkip: PEdict; out Trace: TTraceResult): Int32; cdecl;
begin
Result := EngOrig.TraceMonsterHull(E, V1, V2, MoveType, EntityToSkip, Trace);
end;

procedure TraceHull(var V1, V2: TVec3; MoveType, HullNumber: Int32; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;
begin
EngOrig.TraceHull(V1, V2, MoveType, HullNumber, EntityToSkip, Trace);
end;

procedure TraceModel(var V1, V2: TVec3; HullNumber: Int32; var E: TEdict; out Trace: TTraceResult); cdecl;
begin
EngOrig.TraceModel(V1, V2, HullNumber, E, Trace);
end;

function TraceTexture(E: PEdict; var V1, V2: TVec3): PLChar; cdecl;
begin
Result := EngOrig.TraceTexture(E, V1, V2);
end;

procedure TraceSphere(var V1, V2: TVec3; MoveType: Int32; Radius: Single; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;
begin
EngOrig.TraceSphere(V1, V2, MoveType, Radius, EntityToSkip, Trace);
end;

procedure GetAimVector(E: PEdict; Speed: Single; out VOut: TVec3); cdecl;
begin
EngOrig.GetAimVector(E, Speed, VOut);
end;

procedure ServerCommand(S: PLChar); cdecl;
begin
EngOrig.ServerCommand(S);
end;

procedure ServerExecute; cdecl;
begin
EngOrig.ServerExecute;
end;

procedure ClientCommand; cdecl; // VA
asm
 jmp [EngOrig.ClientCommand]
end;

procedure ParticleEffect(var Origin, Direction: TVec3; Color, Count: Single); cdecl;
begin
EngOrig.ParticleEffect(Origin, Direction, Color, Count);
end;

procedure LightStyle(Style: Int32; Value: PLChar); cdecl;
begin
EngOrig.LightStyle(Style, Value);
end;

function DecalIndex(DecalName: PLChar): Int32; cdecl;
begin
Result := EngOrig.DecalIndex(DecalName);
end;

function PointContents(var Point: TVec3): Int32; cdecl;
begin
Result := EngOrig.PointContents(Point);
end;

procedure MessageBegin(Dest, MessageType: Int32; Origin: PVec3; E: PEdict); cdecl;
begin
EngOrig.MessageBegin(Dest, MessageType, Origin, E);
end;

procedure MessageEnd; cdecl;
begin
EngOrig.MessageEnd;
end;

procedure WriteByte(Value: Int32); cdecl;
begin
EngOrig.WriteByte(Value);
end;

procedure WriteChar(Value: Int32); cdecl;
begin
EngOrig.WriteChar(Value);
end;

procedure WriteShort(Value: Int32); cdecl;
begin
EngOrig.WriteShort(Value);
end;

procedure WriteLong(Value: Int32); cdecl;
begin
EngOrig.WriteLong(Value);
end;

procedure WriteAngle(Value: Single); cdecl;
begin
EngOrig.WriteAngle(Value);
end;

procedure WriteCoord(Value: Single); cdecl;
begin
EngOrig.WriteCoord(Value);
end;

procedure WriteString(S: PLChar); cdecl;
begin
EngOrig.WriteString(S);
end;

procedure WriteEntity(Value: Int32); cdecl;
begin
EngOrig.WriteEntity(Value);
end;

procedure CVarRegister(var C: TCVar); cdecl;
begin
EngOrig.CVarRegister(C);
end;

function CVarGetFloat(Name: PLChar): Single; cdecl;
begin
Result := EngOrig.CVarGetFloat(Name);
end;

function CVarGetString(Name: PLChar): PLChar; cdecl;
begin
Result := EngOrig.CVarGetString(Name);
end;

procedure CVarSetFloat(Name: PLChar; Value: Single); cdecl;
begin
EngOrig.CVarSetFloat(Name, Value);
end;

procedure CVarSetString(Name, Value: PLChar); cdecl;
begin
EngOrig.CVarSetString(Name, Value);
end;

procedure AlertMessage; cdecl; // VA
asm
 jmp [EngOrig.AlertMessage]
end;

procedure EngineFPrintF; cdecl; // VA
asm
 jmp [EngOrig.EngineFPrintF]
end;

function PvAllocEntPrivateData(var E: TEdict; Size: Int32): Pointer; cdecl;
begin
Result := EngOrig.PvAllocEntPrivateData(E, Size);
end;

function PvEntPrivateData(var E: TEdict): Pointer; cdecl;
begin
Result := EngOrig.PvEntPrivateData(E);
end;

procedure FreeEntPrivateData(var E: TEdict); cdecl;
begin
EngOrig.FreeEntPrivateData(E);
end;

function SzFromIndex(Index: TStringOfs): PLChar; cdecl;
begin
Result := EngOrig.SzFromIndex(Index);
end;

function AllocEngineString(S: PLChar): TStringOfs; cdecl;
begin
Result := EngOrig.AllocEngineString(S);
end;

function GetVarsOfEnt(var E: TEdict): PEntVars; cdecl;
begin
Result := EngOrig.GetVarsOfEnt(E);
end;

function PEntityOfEntOffset(Offset: UInt32): PEdict; cdecl;
begin
Result := EngOrig.PEntityOfEntOffset(Offset);
end;

function EntOffsetOfPEntity(var E: TEdict): UInt32; cdecl;
begin
Result := EngOrig.EntOffsetOfPEntity(E);
end;

function IndexOfEdict(E: PEdict): Int32; cdecl;
begin
Result := EngOrig.IndexOfEdict(E);
end;

function PEntityOfEntIndex(Index: Int32): PEdict; cdecl;
begin
Result := EngOrig.PEntityOfEntIndex(Index);
end;

function FindEntityByVars(var E: TEntVars): PEdict; cdecl;
begin
Result := EngOrig.FindEntityByVars(E);
end;

function GetModelPtr(E: PEdict): Pointer; cdecl;
begin
Result := EngOrig.GetModelPtr(E);
end;

function RegUserMsg(Name: PLChar; Size: Int32): Int32; cdecl;
begin
Result := EngOrig.RegUserMsg(Name, Size);
end;

procedure AnimationAutomove(var E: TEdict; Time: Single); cdecl;
begin
EngOrig.AnimationAutomove(E, Time);
end;

procedure GetBonePosition(var E: TEdict; Bone: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;
begin
EngOrig.GetBonePosition(E, Bone, Origin, Angles);
end;

function FunctionFromName(Name: PLChar): Pointer; cdecl;
begin
Result := EngOrig.FunctionFromName(Name);
end;

function NameForFunction(Func: Pointer): PLChar; cdecl;
begin
Result := EngOrig.NameForFunction(Func);
end;

procedure ClientPrintF(var E: TEdict; PrintType: TPrintType; Msg: PLChar); cdecl;
begin
EngOrig.ClientPrintF(E, PrintType, Msg);
end;

procedure ServerPrint(Msg: PLChar); cdecl;
begin
EngOrig.ServerPrint(Msg);
end;

function Cmd_Args: PLChar; cdecl;
begin
Result := EngOrig.Cmd_Args;
end;

function Cmd_Argv(I: Int32): PLChar; cdecl;
begin
Result := EngOrig.Cmd_Argv(I);
end;

function Cmd_Argc: Int32; cdecl;
begin
Result := EngOrig.Cmd_Argc;
end;

procedure GetAttachment(var E: TEdict; Attachment: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;
begin
EngOrig.GetAttachment(E, Attachment, Origin, Angles);
end;

procedure CRC32_Init(out CRC: TCRC); cdecl;
begin
EngOrig.CRC32_Init(CRC);
end;

procedure CRC32_ProcessBuffer(var CRC: TCRC; Buffer: Pointer; Size: UInt32); cdecl;
begin
EngOrig.CRC32_ProcessBuffer(CRC, Buffer, Size);
end;

procedure CRC32_ProcessByte(var CRC: TCRC; B: Byte); cdecl;
begin
EngOrig.CRC32_ProcessByte(CRC, B);
end;

function CRC32_Final(CRC: TCRC): TCRC; cdecl;
begin
Result := EngOrig.CRC32_Final(CRC);
end;

function RandomLong(Low, High: Int32): Int32; cdecl;
begin
Result := EngOrig.RandomLong(Low, High);
end;

function RandomFloat(Low, High: Single): Double; cdecl;
begin
Result := EngOrig.RandomFloat(Low, High);
end;

procedure SetView(var Entity, Target: TEdict); cdecl;
begin
EngOrig.SetView(Entity, Target);
end;

function Time: Double; cdecl;
begin
Result := EngOrig.Time;
end;

procedure CrosshairAngle(var Entity: TEdict; Pitch, Yaw: Single); cdecl;
begin
EngOrig.CrosshairAngle(Entity, Pitch, Yaw);
end;

function LoadFileForMe(Name: PLChar; Length: PUInt32): Pointer; cdecl;
begin
Result := EngOrig.LoadFileForMe(Name, Length);
end;

procedure FreeFile(Buffer: Pointer); cdecl;
begin
EngOrig.FreeFile(Buffer);
end;

procedure EndSection(Name: PLChar); cdecl;
begin
EngOrig.EndSection(Name);
end;

function CompareFileTime(S1, S2: PLChar; CompareResult: PInt32): Int32; cdecl;
begin
Result := EngOrig.CompareFileTime(S1, S2, CompareResult);
end;

procedure GetGameDir(Buffer: PLChar); cdecl;
begin
EngOrig.GetGameDir(Buffer);
end;

procedure CVar_RegisterVariable(var C: TCVar); cdecl;
begin
EngOrig.CVar_RegisterVariable(C);
end;

procedure FadeClientVolume(var Entity: TEdict; FadePercent, FadeOutSeconds, HoldTime, FadeInSeconds: Int32); cdecl;
begin
EngOrig.FadeClientVolume(Entity, FadePercent, FadeOutSeconds, HoldTime, FadeInSeconds);
end;

procedure SetClientMaxSpeed(var E: TEdict; Speed: Single); cdecl;
begin
EngOrig.SetClientMaxSpeed(E, Speed);
end;

function CreateFakeClient(Name: PLChar): PEdict; cdecl;
begin
Result := EngOrig.CreateFakeClient(Name);
end;

procedure RunPlayerMove(var FakeClient: TEdict; var Angles: TVec3; FwdMove, SideMove, UpMove: Single; Buttons: Int16; Impulse, MSec: Byte); cdecl;
begin
EngOrig.RunPlayerMove(FakeClient, Angles, FwdMove, SideMove, UpMove, Buttons, Impulse, MSec);
end;

function NumberOfEntities: UInt32; cdecl;
begin
Result := EngOrig.NumberOfEntities;
end;

function GetInfoKeyBuffer(E: PEdict): PLChar; cdecl;
begin
Result := EngOrig.GetInfoKeyBuffer(E);
end;

function InfoKeyValue(Buffer, Key: PLChar): PLChar; cdecl;
begin
Result := EngOrig.InfoKeyValue(Buffer, Key);
end;

procedure SetKeyValue(Buffer, Key, Value: PLChar); cdecl;
begin
EngOrig.SetKeyValue(Buffer, Key, Value);
end;

procedure SetClientKeyValue(Index: Int32; Buffer, Key, Value: PLChar); cdecl;
begin
EngOrig.SetClientKeyValue(Index, Buffer, Key, Value);
end;

function IsMapValid(Name: PLChar): Int32; cdecl;
begin
Result := EngOrig.IsMapValid(Name);
end;

procedure StaticDecal(var Origin: TVec3; DecalIndex, EntityIndex, ModelIndex: Int32); cdecl;
begin
EngOrig.StaticDecal(Origin, DecalIndex, EntityIndex, ModelIndex);
end;

function PrecacheGeneric(Name: PLChar): UInt32; cdecl;
begin
Result := EngOrig.PrecacheGeneric(Name);
end;

function GetPlayerUserID(var E: TEdict): Int32; cdecl;
begin
Result := EngOrig.GetPlayerUserID(E);
end;

procedure BuildSoundMsg(var E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch, Dest, MessageType: Int32; var Origin: TVec3; MsgEnt: PEdict); cdecl;
begin
EngOrig.BuildSoundMsg(E, Channel, Sample, Volume, Attn, Flags, Pitch, Dest, MessageType, Origin, MsgEnt);
end;

function IsDedicatedServer: Int32; cdecl;
begin
Result := EngOrig.IsDedicatedServer;
end;

function CVarGetPointer(Name: PLChar): PCVar; cdecl;
begin
Result := EngOrig.CVarGetPointer(Name);
end;

function GetPlayerWONID(var E: TEdict): Int32; cdecl;
begin
Result := EngOrig.GetPlayerWONID(E);
end;

procedure Info_RemoveKey(Data, Key: PLChar); cdecl;
begin
EngOrig.Info_RemoveKey(Data, Key);
end;

function GetPhysicsKeyValue(var E: TEdict; Key: PLChar): PLChar; cdecl;
begin
Result := EngOrig.GetPhysicsKeyValue(E, Key);
end;

procedure SetPhysicsKeyValue(var E: TEdict; Key, Value: PLChar); cdecl;
begin
EngOrig.SetPhysicsKeyValue(E, Key, Value);
end;

function GetPhysicsInfoString(var E: TEdict): PLChar; cdecl;
begin
Result := EngOrig.GetPhysicsInfoString(E);
end;

function PrecacheEvent(EventType: Int32; Name: PLChar): UInt16; cdecl;
begin
Result := EngOrig.PrecacheEvent(EventType, Name);
end;

procedure PlaybackEvent(Flags: UInt32; E: PEdict; EventIndex: UInt16; Delay: Single; Origin, Angles: PVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;
begin
EngOrig.PlaybackEvent(Flags, E, EventIndex, Delay, Origin, Angles, FParam1, FParam2, IParam1, IParam2, BParam1, BParam2);
end;

function SetFatPVS(var Origin: TVec3): PByte; cdecl;
begin
Result := EngOrig.SetFatPVS(Origin);
end;

function SetFatPAS(var Origin: TVec3): PByte; cdecl;
begin
Result := EngOrig.SetFatPAS(Origin);
end;

function CheckVisibility(var E: TEdict; VisSet: PByte): Int32; cdecl;
begin
Result := EngOrig.CheckVisibility(E, VisSet);
end;

procedure DeltaSetField(var D: TDelta; FieldName: PLChar); cdecl;
begin
EngOrig.DeltaSetField(D, FieldName);
end;

procedure DeltaUnsetField(var D: TDelta; FieldName: PLChar); cdecl;
begin
EngOrig.DeltaUnsetField(D, FieldName);
end;

procedure DeltaAddEncoder(Name: PLChar; Func: TDeltaEncoder); cdecl;
begin
EngOrig.DeltaAddEncoder(Name, Func);
end;

function GetCurrentPlayer: Int32; cdecl;
begin
Result := EngOrig.GetCurrentPlayer;
end;

function CanSkipPlayer(var E: TEdict): Int32; cdecl;
begin
Result := EngOrig.CanSkipPlayer(E);
end;

function DeltaFindField(var D: TDelta; FieldName: PLChar): Int32; cdecl;
begin
Result := EngOrig.DeltaFindField(D, FieldName);
end;

procedure DeltaSetFieldByIndex(var D: TDelta; FieldNumber: UInt32); cdecl;
begin
EngOrig.DeltaSetFieldByIndex(D, FieldNumber);
end;

procedure DeltaUnsetFieldByIndex(var D: TDelta; FieldNumber: UInt32); cdecl;
begin
EngOrig.DeltaUnsetFieldByIndex(D, FieldNumber);
end;

procedure SetGroupMask(Mask, Op: Int32); cdecl;
begin
EngOrig.SetGroupMask(Mask, Op);
end;

function CreateInstancedBaseline(ClassName: UInt32; var Baseline: TEntityState): Int32; cdecl;
begin
Result := EngOrig.CreateInstancedBaseline(ClassName, Baseline);
end;

procedure CVar_DirectSet(var C: TCVar; Value: PLChar); cdecl;
begin
EngOrig.CVar_DirectSet(C, Value);
end;

procedure ForceUnmodified(FT: TForceType; MinS, MaxS: PVec3; FileName: PLChar); cdecl;
begin
EngOrig.ForceUnmodified(FT, MinS, MaxS, FileName);
end;

procedure GetPlayerStats(var E: TEdict; out Ping, PacketLoss: Int32); cdecl;
begin
EngOrig.GetPlayerStats(E, Ping, PacketLoss);
end;

procedure AddServerCommand(Name: PLChar; Func: TCmdFunction); cdecl;
begin
EngOrig.AddServerCommand(Name, Func);
end;

function Voice_GetClientListening(Receiver, Sender: Int32): Int32; cdecl;
begin
Result := EngOrig.Voice_GetClientListening(Receiver, Sender);
end;

function Voice_SetClientListening(Receiver, Sender, IsListening: Int32): Int32; cdecl;
begin
Result := EngOrig.Voice_SetClientListening(Receiver, Sender, IsListening);
end;

function GetPlayerAuthID(var E: TEdict): PLChar; cdecl;
begin
Result := EngOrig.GetPlayerAuthID(E);
end;

function SequenceGet(FileName, EntryName: PLChar): Pointer; cdecl;
begin
Result := EngOrig.SequenceGet(FileName, EntryName);
end;

function SequencePickSentence(GroupName: PLChar; PickMethod: Int32; var Picked: Int32): Pointer; cdecl;
begin
Result := EngOrig.SequencePickSentence(GroupName, PickMethod, Picked);
end;

function GetFileSize(FileName: PLChar): UInt32; cdecl;
begin
Result := EngOrig.GetFileSize(FileName);
end;

function GetApproxWavePlayLength(FileName: PLChar): UInt32; cdecl;
begin
Result := EngOrig.GetApproxWavePlayLength(FileName);
end;

function IsCareerMatch: Int32; cdecl;
begin
Result := EngOrig.IsCareerMatch;
end;

function GetLocalizedStringLength(S: PLChar): UInt32; cdecl;
begin
Result := EngOrig.GetLocalizedStringLength(S);
end;

procedure RegisterTutorMessageShown(MessageID: Int32); cdecl;
begin
EngOrig.RegisterTutorMessageShown(MessageID);
end;

function GetTimesTutorMessageShown(MessageID: Int32): Int32; cdecl;
begin
Result := EngOrig.GetTimesTutorMessageShown(MessageID);
end;

procedure ProcessTutorMessageDecayBuffer(Buffer: Pointer; Length: UInt32); cdecl;
begin
EngOrig.ProcessTutorMessageDecayBuffer(Buffer, Length);
end;

procedure ConstructTutorMessageDecayBuffer(Buffer: Pointer; Length: UInt32); cdecl;
begin
EngOrig.ConstructTutorMessageDecayBuffer(Buffer, Length);
end;

procedure ResetTutorMessageDecayData; cdecl;
begin
EngOrig.ResetTutorMessageDecayData;
end;

procedure QueryClientCVarValue(var E: TEdict; Name: PLChar); cdecl;
begin
EngOrig.QueryClientCVarValue(E, Name);
end;

procedure QueryClientCVarValue2(var E: TEdict; Name: PLChar; RequestID: Int32); cdecl;
begin
EngOrig.QueryClientCVarValue2(E, Name, RequestID);
end;

function CheckParm(Token: PLChar; var Next: PLChar): UInt32; cdecl;
begin
Result := EngOrig.CheckParm(Token, Next);
end;

function ReservedStart: Pointer; cdecl;
begin
Result := EngOrig.ReservedStart;
end;

function Reserved1: Pointer; cdecl;
begin
Result := EngOrig.Reserved1;
end;

function Reserved2: Pointer; cdecl;
begin
Result := EngOrig.Reserved2;
end;

function Reserved3: Pointer; cdecl;
begin
Result := EngOrig.Reserved3;
end;

function Reserved4: Pointer; cdecl;
begin
Result := EngOrig.Reserved4;
end;

function Reserved5: Pointer; cdecl;
begin
Result := EngOrig.Reserved5;
end;

function Reserved6: Pointer; cdecl;
begin
Result := EngOrig.Reserved6;
end;

function Reserved7: Pointer; cdecl;
begin
Result := EngOrig.Reserved7;
end;

function Reserved8: Pointer; cdecl;
begin
Result := EngOrig.Reserved8;
end;

function Reserved9: Pointer; cdecl;
begin
Result := EngOrig.Reserved9;
end;

function ReservedEnd: Pointer; cdecl;
begin
Result := EngOrig.ReservedEnd;
end;

var
 Init: Boolean = False;
 EngFuncs: TEngineFuncs =
 (PrecacheModel: PrecacheModel;
  PrecacheSound: PrecacheSound;
  SetModel: SetModel;
  ModelIndex: ModelIndex;
  ModelFrames: ModelFrames;
  SetSize: SetSize;
  ChangeLevel: ChangeLevel;
  SetSpawnParms: SetSpawnParms;
  SaveSpawnParms: SaveSpawnParms;
  VecToYaw: VecToYaw;
  VecToAngles: VecToAngles;
  MoveToOrigin: MoveToOrigin;
  ChangeYaw: ChangeYaw;
  ChangePitch: ChangePitch;
  FindEntityByString: FindEntityByString;
  GetEntityIllum: GetEntityIllum;
  FindEntityInSphere: FindEntityInSphere;
  FindClientInPVS: FindClientInPVS;
  EntitiesInPVS: EntitiesInPVS;
  MakeVectors: MakeVectors;
  AngleVectors: AngleVectors;

  CreateEntity: CreateEntity;
  RemoveEntity: RemoveEntity;
  CreateNamedEntity: CreateNamedEntity;

  MakeStatic: MakeStatic;
  EntIsOnFloor: EntIsOnFloor;
  DropToFloor: DropToFloor;
  WalkMove: WalkMove;
  SetOrigin: SetOrigin;
  EmitSound: EmitSound;
  EmitAmbientSound: EmitAmbientSound;

  TraceLine: TraceLine;
  TraceToss: TraceToss;
  TraceMonsterHull: TraceMonsterHull;
  TraceHull: TraceHull;
  TraceModel: TraceModel;
  TraceTexture: TraceTexture;
  TraceSphere: TraceSphere;

  GetAimVector: GetAimVector;
  ServerCommand: ServerCommand;
  ServerExecute: ServerExecute;
  //ClientCommand: ClientCommand;
  ParticleEffect: ParticleEffect;
  LightStyle: LightStyle;
  DecalIndex: DecalIndex;
  PointContents: PointContents;

  MessageBegin: MessageBegin;
  MessageEnd: MessageEnd;
  WriteByte: WriteByte;
  WriteChar: WriteChar;
  WriteShort: WriteShort;
  WriteLong: WriteLong;
  WriteAngle: WriteAngle;
  WriteCoord: WriteCoord;
  WriteString: WriteString;
  WriteEntity: WriteEntity;

  CVarRegister: CVarRegister;
  CVarGetFloat: CVarGetFloat;
  CVarGetString: CVarGetString;
  CVarSetFloat: CVarSetFloat;
  CVarSetString: CVarSetString;
  //AlertMessage: AlertMessage;
  //EngineFPrintF: EngineFPrintF;

  PvAllocEntPrivateData: PvAllocEntPrivateData;
  PvEntPrivateData: PvEntPrivateData;
  FreeEntPrivateData: FreeEntPrivateData;
  SzFromIndex: SzFromIndex;
  AllocEngineString: AllocEngineString;
  GetVarsOfEnt: GetVarsOfEnt;
  PEntityOfEntOffset: PEntityOfEntOffset;
  EntOffsetOfPEntity: EntOffsetOfPEntity;
  IndexOfEdict: IndexOfEdict;
  PEntityOfEntIndex: PEntityOfEntIndex;
  FindEntityByVars: FindEntityByVars;

  GetModelPtr: GetModelPtr;
  RegUserMsg: RegUserMsg;
  AnimationAutomove: AnimationAutomove;
  GetBonePosition: GetBonePosition;
  FunctionFromName: FunctionFromName;
  NameForFunction: NameForFunction;

  ClientPrintF: ClientPrintF;
  ServerPrint: ServerPrint;
  Cmd_Args: Cmd_Args;
  Cmd_Argv: Cmd_Argv;
  Cmd_Argc: Cmd_Argc;

  GetAttachment: GetAttachment;

  CRC32_Init: CRC32_Init;
  CRC32_ProcessBuffer: CRC32_ProcessBuffer;
  CRC32_ProcessByte: CRC32_ProcessByte;
  CRC32_Final: CRC32_Final;

  RandomLong: RandomLong;
  RandomFloat: RandomFloat;

  SetView: SetView;
  Time: Time;
  CrosshairAngle: CrosshairAngle;
  LoadFileForMe: LoadFileForMe;
  FreeFile: FreeFile;
  EndSection: EndSection;
  CompareFileTime: CompareFileTime;
  GetGameDir: GetGameDir;

  CVar_RegisterVariable: CVar_RegisterVariable;
  FadeClientVolume: FadeClientVolume;
  SetClientMaxSpeed: SetClientMaxSpeed;

  CreateFakeClient: CreateFakeClient;
  RunPlayerMove: RunPlayerMove;
  NumberOfEntities: NumberOfEntities;
  GetInfoKeyBuffer: GetInfoKeyBuffer;
  InfoKeyValue: InfoKeyValue;
  SetKeyValue: SetKeyValue;
  SetClientKeyValue: SetClientKeyValue;
  IsMapValid: IsMapValid;
  StaticDecal: StaticDecal;
  PrecacheGeneric: PrecacheGeneric;
  GetPlayerUserID: GetPlayerUserID;
  BuildSoundMsg: BuildSoundMsg;
  IsDedicatedServer: IsDedicatedServer;
  CVarGetPointer: CVarGetPointer;
  GetPlayerWONID: GetPlayerWONID;

  Info_RemoveKey: Info_RemoveKey;
  GetPhysicsKeyValue: GetPhysicsKeyValue;
  SetPhysicsKeyValue: SetPhysicsKeyValue;
  GetPhysicsInfoString: GetPhysicsInfoString;

  PrecacheEvent: PrecacheEvent;
  PlaybackEvent: PlaybackEvent;

  SetFatPVS: SetFatPVS;
  SetFatPAS: SetFatPAS;
  CheckVisibility: CheckVisibility;

  DeltaSetField: DeltaSetField;
  DeltaUnsetField: DeltaUnsetField;
  DeltaAddEncoder: DeltaAddEncoder;
  GetCurrentPlayer: GetCurrentPlayer;
  CanSkipPlayer: CanSkipPlayer;
  DeltaFindField: DeltaFindField;
  DeltaSetFieldByIndex: DeltaSetFieldByIndex;
  DeltaUnsetFieldByIndex: DeltaUnsetFieldByIndex;

  SetGroupMask: SetGroupMask;
  CreateInstancedBaseline: CreateInstancedBaseline;
  CVar_DirectSet: CVar_DirectSet;
  ForceUnmodified: ForceUnmodified;
  GetPlayerStats: GetPlayerStats;
  AddServerCommand: AddServerCommand;
  Voice_GetClientListening: Voice_GetClientListening;
  Voice_SetClientListening: Voice_SetClientListening;

  GetPlayerAuthID: GetPlayerAuthID;

  SequenceGet: SequenceGet;
  SequencePickSentence: SequencePickSentence;

  GetFileSize: GetFileSize;
  GetApproxWavePlayLength: GetApproxWavePlayLength;

  IsCareerMatch: IsCareerMatch;
  GetLocalizedStringLength: GetLocalizedStringLength;
  RegisterTutorMessageShown: RegisterTutorMessageShown;
  GetTimesTutorMessageShown: GetTimesTutorMessageShown;
  ProcessTutorMessageDecayBuffer: ProcessTutorMessageDecayBuffer;
  ConstructTutorMessageDecayBuffer: ConstructTutorMessageDecayBuffer;
  ResetTutorMessageDecayData: ResetTutorMessageDecayData;

  QueryClientCVarValue: QueryClientCVarValue;
  QueryClientCVarValue2: QueryClientCVarValue2;
  CheckParm: CheckParm;

  ReservedStart: ReservedStart;
  Reserved1: Reserved1;
  Reserved2: Reserved2;
  Reserved3: Reserved3;
  Reserved4: Reserved4;
  Reserved5: Reserved5;
  Reserved6: Reserved6;
  Reserved7: Reserved7;
  Reserved8: Reserved8;
  Reserved9: Reserved9;
  ReservedEnd: ReservedEnd;
 );

function SwitchEngineToFakeSwds(const E: TEngineFuncs; Size: UInt): PEngineFuncs;
begin
if Init or (Size <> SizeOf(TEngineFuncs)) then
 Result := nil
else
 begin
  EngFuncs.ClientCommand := @ClientCommand;
  EngFuncs.AlertMessage := @AlertMessage;
  EngFuncs.EngineFPrintF := @EngineFPrintF;
  Move(E, EngOrig, SizeOf(EngOrig));
  Init := True;
  Result := @EngFuncs;
 end;
end;

procedure DestroyFakeSwds;
begin
if Init then
 Init := False;
end;

exports SwitchEngineToFakeSwds, DestroyFakeSwds;

end.
 