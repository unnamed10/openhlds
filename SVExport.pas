unit SVExport;

{$I HLDS.inc}

interface

uses {$IFDEF LINUX}Libc, {$ENDIF} Default, SDK;

function PF_PrecacheModel(Name: PLChar): UInt32; cdecl;
function PF_PrecacheSound(Name: PLChar): UInt32; cdecl;
procedure PF_SetModel(var E: TEdict; ModelName: PLChar); cdecl;
function PF_ModelIndex(Name: PLChar): Int32; cdecl;
function PF_ModelFrames(Index: Int32): Int32; cdecl;
procedure PF_SetSize(var E: TEdict; const MinS, MaxS: TVec3); cdecl;
procedure PF_ChangeLevel(S1, S2: PLChar); cdecl;
procedure PF_SetSpawnParms(var E: TEdict); cdecl;
procedure PF_SaveSpawnParms(var E: TEdict); cdecl;
function PF_VecToYaw(const V: TVec3): Double; cdecl;
procedure PF_VecToAngles(const Fwd: TVec3; out Angles: TVec3); cdecl;
procedure PF_MoveToOrigin(var E: TEdict; const Target: TVec3; Distance: Single; MoveType: Int32); cdecl;
procedure PF_ChangeYaw(var E: TEdict); cdecl;
procedure PF_ChangePitch(var E: TEdict); cdecl;
function PF_FindEntityByString(const E: TEdict; Key, Value: PLChar): PEdict; cdecl;
function PF_GetEntityIllum(const E: TEdict): Int32; cdecl;
function PF_FindEntityInSphere(const E: TEdict; const Origin: TVec3; Distance: Single): PEdict; cdecl;
function PF_CheckClient(const E: TEdict): PEdict; cdecl;
function PF_PVSFindEntities(const E: TEdict): PEdict; cdecl;

procedure PF_MakeVectors(const V: TVec3); cdecl;
procedure PF_AngleVectors(const Angles: TVec3; Fwd, Right, Up: PVec3); cdecl;

function PF_Spawn: PEdict; cdecl;
procedure PF_Remove(var E: TEdict); cdecl;
function PF_CreateNamedEntity(ClassName: TStringOfs): PEdict; cdecl;

procedure PF_MakeStatic(var E: TEdict); cdecl;
function PF_CheckBottom(const E: TEdict): Int32; cdecl;
function PF_DropToFloor(var E: TEdict): Int32; cdecl;
function PF_WalkMove(var E: TEdict; Yaw, Distance: Single; Mode: Int32): Int32; cdecl;

procedure PF_SetOrigin(var E: TEdict; const Origin: TVec3); cdecl;
procedure PF_Sound(const E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
procedure PF_AmbientSound(const E: TEdict; const Origin: TVec3; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;

procedure PF_TraceLine(const V1, V2: TVec3; MoveType: Int32; E: PEdict; out Trace: TTraceResult); cdecl;
procedure PF_TraceToss(const E: TEdict; IgnoreEnt: PEdict; out Trace: TTraceResult); cdecl;
function PF_TraceMonsterHull(const E: TEdict; const V1, V2: TVec3; MoveType: Int32; EntityToSkip: PEdict; out Trace: TTraceResult): Int32; cdecl;
procedure PF_TraceHull(const V1, V2: TVec3; MoveType, HullNumber: Int32; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;
procedure PF_TraceModel(const V1, V2: TVec3; HullNumber: Int32; var E: TEdict; out Trace: TTraceResult); cdecl;
function PF_TraceTexture(E: PEdict; const V1, V2: TVec3): PLChar; cdecl;
procedure PF_TraceSphere(const V1, V2: TVec3; MoveType: Int32; Radius: Single; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;

procedure PF_Aim(E: PEdict; Speed: Single; out VOut: TVec3); cdecl;
procedure PF_LocalCmd(S: PLChar); cdecl;
procedure PF_LocalExec; cdecl;
procedure PF_StuffCmd(const E: TEdict; S: PLChar); cdecl; // varargs
procedure PF_Particle(const Origin, Direction: TVec3; Color, Count: Single); cdecl;
procedure PF_LightStyle(Style: Int32; Value: PLChar); cdecl;
function PF_DecalIndex(DecalName: PLChar): Int32; cdecl;
function PF_PointContents(const Point: TVec3): Int32; cdecl;

procedure PF_MessageBegin(Dest, MessageType: Int32; Origin: PVec3; E: PEdict); cdecl;
procedure PF_MessageEnd; cdecl;
procedure PF_WriteByte(Value: Int32); cdecl;
procedure PF_WriteChar(Value: Int32); cdecl;
procedure PF_WriteShort(Value: Int32); cdecl;
procedure PF_WriteLong(Value: Int32); cdecl;
procedure PF_WriteAngle(Value: Single); cdecl;
procedure PF_WriteCoord(Value: Single); cdecl;
procedure PF_WriteString(S: PLChar); cdecl;
procedure PF_WriteEntity(Value: Int32); cdecl;

procedure PF_CVarRegister(var C: TCVar); cdecl;
function PF_CVarGetFloat(Name: PLChar): Single; cdecl;
function PF_CVarGetString(Name: PLChar): PLChar; cdecl;
procedure PF_CVarSetFloat(Name: PLChar; Value: Single); cdecl;
procedure PF_CVarSetString(Name, Value: PLChar); cdecl;

procedure PF_AlertMessage(AlertType: TAlertType; Msg: PChar); cdecl;
procedure PF_EngineFPrintF(F: Pointer; Msg: PLChar); cdecl;

function PF_PvAllocEntPrivateData(var E: TEdict; Size: Int32): Pointer; cdecl;
function PF_PvEntPrivateData(const E: TEdict): Pointer; cdecl;
procedure PF_FreeEntPrivateData(var E: TEdict); cdecl;
function PF_SzFromIndex(Index: TStringOfs): PLChar; cdecl;
function PF_AllocEngineString(S: PLChar): TStringOfs; cdecl;
function PF_GetVarsOfEnt(const E: TEdict): PEntVars; cdecl;
function PF_PEntityOfEntOffset(Offset: UInt32): PEdict; cdecl;
function PF_EntOffsetOfPEntity(const E: TEdict): UInt32; cdecl;
function PF_IndexOfEdict(E: PEdict): Int32; cdecl;
function PF_PEntityOfEntIndex(Index: Int32): PEdict; cdecl;
function PF_FindEntityByVars(const E: TEntVars): PEdict; cdecl;

function PF_GetModelPtr(E: PEdict): Pointer; cdecl;
function PF_RegUserMsg(Name: PLChar; Size: Int32): Int32; cdecl;
procedure PF_AnimationAutomove(var E: TEdict; Time: Single); cdecl;
procedure PF_GetBonePosition(var E: TEdict; Bone: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;
function PF_FunctionFromName(Name: PLChar): Pointer; cdecl;
function PF_NameForFunction(Func: Pointer): PLChar; cdecl;

procedure PF_ClientPrintF(const E: TEdict; PrintType: TPrintType; Msg: PLChar); cdecl;
procedure PF_ServerPrint(Msg: PLChar); cdecl;
function PF_Cmd_Args: PLChar; cdecl;
function PF_Cmd_Argv(I: Int32): PLChar; cdecl;
function PF_Cmd_Argc: Int32; cdecl;

procedure PF_GetAttachment(var E: TEdict; Attachment: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;

procedure PF_CRC32_Init(out CRC: TCRC); cdecl;
procedure PF_CRC32_ProcessBuffer(var CRC: TCRC; Buffer: Pointer; Size: UInt32); cdecl;
procedure PF_CRC32_ProcessByte(var CRC: TCRC; B: Byte); cdecl;
function PF_CRC32_Final(CRC: TCRC): TCRC; cdecl;

function PF_RandomLong(Low, High: Int32): Int32; cdecl;
function PF_RandomFloat(Low, High: Single): Double; cdecl; // single?

procedure PF_SetView(const Entity, Target: TEdict); cdecl;
function PF_Time: Double; cdecl;
procedure PF_CrosshairAngle(const Entity: TEdict; Pitch, Yaw: Single); cdecl;
function PF_LoadFileForMe(Name: PLChar; Length: PUInt32): Pointer; cdecl;
procedure PF_FreeFile(Buffer: Pointer); cdecl;
procedure PF_EndSection(Name: PLChar); cdecl;
function PF_CompareFileTime(S1, S2: PLChar; CompareResult: PInt32): Int32; cdecl;
procedure PF_GetGameDir(Buffer: PLChar); cdecl;

procedure PF_CVar_RegisterVariable(var C: TCVar); cdecl;
procedure PF_FadeVolume(const Entity: TEdict; FadePercent, FadeOutSeconds, HoldTime, FadeInSeconds: Int32); cdecl;
procedure PF_SetClientMaxSpeed(var E: TEdict; Speed: Single); cdecl;

function PF_CreateFakeClient(Name: PLChar): PEdict; cdecl;
procedure PF_RunPlayerMove(const FakeClient: TEdict; const Angles: TVec3; FwdMove, SideMove, UpMove: Single; Buttons: Int16; Impulse, MSec: Byte); cdecl;
function PF_NumberOfEntities: UInt32; cdecl;
function PF_GetInfoKeyBuffer(E: PEdict): PLChar; cdecl;
function PF_InfoKeyValue(Buffer, Key: PLChar): PLChar; cdecl;
procedure PF_SetKeyValue(Buffer, Key, Value: PLChar); cdecl;
procedure PF_SetClientKeyValue(Index: Int32; Buffer, Key, Value: PLChar); cdecl;
function PF_IsMapValid(Name: PLChar): Int32; cdecl;
procedure PF_StaticDecal(const Origin: TVec3; DecalIndex, EntityIndex, ModelIndex: Int32); cdecl;
function PF_PrecacheGeneric(Name: PLChar): UInt32; cdecl;
function PF_GetPlayerUserID(const E: TEdict): Int32; cdecl;
procedure PF_BuildSoundMsg(const E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch, Dest, MessageType: Int32; const Origin: TVec3; MsgEnt: PEdict); cdecl;
function PF_IsDedicatedServer: Int32; cdecl;
function PF_CVarGetPointer(Name: PLChar): PCVar; cdecl;
function PF_GetPlayerWONID(const E: TEdict): Int32; cdecl;

procedure PF_RemoveKey(Data, Key: PLChar); cdecl;
function PF_GetPhysicsKeyValue(const E: TEdict; Key: PLChar): PLChar; cdecl;
procedure PF_SetPhysicsKeyValue(const E: TEdict; Key, Value: PLChar); cdecl;
function PF_GetPhysicsInfoString(const E: TEdict): PLChar; cdecl;
function PF_PrecacheEvent(EventType: Int32; Name: PLChar): UInt16; cdecl;
procedure PF_PlaybackEvent(Flags: UInt32; const E: TEdict; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;

function PF_SetFatPVS(const Origin: TVec3): PByte; cdecl;
function PF_SetFatPAS(const Origin: TVec3): PByte; cdecl;
function PF_CheckVisibility(var E: TEdict; VisSet: PByte): Int32; cdecl;

procedure PF_Delta_SetField(var D: TDelta; FieldName: PLChar); cdecl;
procedure PF_Delta_UnsetField(var D: TDelta; FieldName: PLChar); cdecl;
procedure PF_Delta_AddEncoder(Name: PLChar; Func: TDeltaEncoder); cdecl;
function PF_GetCurrentPlayer: Int32; cdecl;
function PF_CanSkipPlayer(const E: TEdict): Int32; cdecl;
function PF_Delta_FindField(const D: TDelta; FieldName: PLChar): Int32; cdecl;
procedure PF_Delta_SetFieldByIndex(var D: TDelta; FieldNumber: UInt32); cdecl;
procedure PF_Delta_UnsetFieldByIndex(var D: TDelta; FieldNumber: UInt32); cdecl;

procedure PF_SetGroupMask(Mask, Op: Int32); cdecl;
function PF_CreateInstancedBaseline(ClassName: UInt32; const Baseline: TEntityState): Int32; cdecl;
procedure PF_CVar_DirectSet(var C: TCVar; Value: PLChar); cdecl;
procedure PF_ForceUnmodified(FT: TForceType; MinS, MaxS: PVec3; FileName: PLChar); cdecl;
procedure PF_GetPlayerStats(const E: TEdict; out Ping, PacketLoss: Int32); cdecl;
procedure PF_AddServerCommand(Name: PLChar; Func: TCmdFunction); cdecl;
function PF_Voice_GetClientListening(Receiver, Sender: Int32): Int32; cdecl;
function PF_Voice_SetClientListening(Receiver, Sender, IsListening: Int32): Int32; cdecl;

function PF_GetPlayerAuthID(const E: TEdict): PLChar; cdecl;

function PF_SequenceGet(FileName, EntryName: PLChar): Pointer; cdecl;
function PF_SequencePickSentence(GroupName: PLChar; PickMethod: Int32; var Picked: Int32): Pointer; cdecl;

function PF_GetFileSize(FileName: PLChar): UInt32; cdecl;
function PF_GetApproxWavePlayLength(FileName: PLChar): UInt32; cdecl;

function PF_VGUI2_IsCareerMatch: Int32; cdecl;
function PF_VGUI2_GetLocalizedStringLength(S: PLChar): UInt32; cdecl;
procedure PF_RegisterTutorMessageShown(MessageID: Int32); cdecl;
function PF_GetTimesTutorMessageShown(MessageID: Int32): Int32; cdecl;
procedure PF_ProcessTutorMessageDecayBuffer(Buffer: Pointer; Length: UInt32); cdecl;
procedure PF_ConstructTutorMessageDecayBuffer(Buffer: Pointer; Length: UInt32); cdecl;
procedure PF_ResetTutorMessageDecayData; cdecl;

procedure PF_QueryClientCVarValue(var E: TEdict; Name: PLChar); cdecl;
procedure PF_QueryClientCVarValue2(var E: TEdict; Name: PLChar; RequestID: Int32); cdecl;
function PF_EngCheckParm(Token: PLChar; var Next: PLChar): UInt32; cdecl;
function PF_Reserved: Pointer; cdecl;

implementation

uses Common, Console, Delta, Edict, Encode, FileSys, GameLib, Host, Info, MathLib, Memory, Model, MsgBuf, PMove, Renderer, Resource, Server, SVAuth, SVClient, SVEdict, SVEvent, SVMove, SVPhys, SVSend, SVWorld, SysArgs, SysClock, SysMain;

const
 PFHullMinS: array[0..3] of TVec3 =
  ((0, 0, 0), (-16, -16, -36), (-32, -32, -32), (-16, -16, -18));
 PFHullMaxS: array[0..3] of TVec3 =
  ((0, 0, 0), (16, 16, 36), (32, 32, 32), (16, 16, 18));

var
 MsgStarted: Boolean = False;
 MsgType, MsgDest: Int32;
 MsgEntity: PEdict;
 MsgOrigin: TVec3;
 MsgData: array[1..512] of Byte;
 MsgBuffer: TSizeBuf = (Name: 'MessageBegin/End'; AllowOverflow: []; Data: @MsgData; MaxSize: SizeOf(MsgData); CurrentSize: 0);

 LastSpawnCount: Int32;

function PF_PrecacheModel(Name: PLChar): UInt32; cdecl;
var
 B: Boolean;
 I: Int;
begin
if Name = nil then
 Host_Error('PF_PrecacheModel: NULL pointer.')
else
 if PR_IsEmptyString(Name) then
  Host_Error(['PF_PrecacheModel: Bad string "', Name, '".'])
 else
  begin
   B := Name^ = '!';
   if B then
    Inc(UInt(Name));

   if SV.State = SS_LOADING then
    begin
     for I := 0 to MAX_MODELS - 1 do
      if SV.PrecachedModelNames[I] = nil then
       begin
        SV.PrecachedModelNames[I] := Name;
        SV.PrecachedModels[I] := Mod_ForName(Name, True, True);
        if not B then
         Include(SV.PrecachedModelFlags[I], RES_FATALIFMISSING);

        Result := I;
        Exit;
       end
      else
       if StrIComp(SV.PrecachedModelNames[I], Name) = 0 then
        begin
         Result := I;
         Exit;
        end;

     Host_Error(['PF_PrecacheModel: Model "', Name, '" failed to precache because the item count is over the MAX_MODELS (', MAX_MODELS, ') limit.' + LineBreak +
                 'Reduce the number of brush models and/or regular models in the map to correct this.']);
    end
   else
    begin
     for I := 0 to MAX_MODELS - 1 do
      if SV.PrecachedModelNames[I] = nil then
       Break
      else
       if StrIComp(SV.PrecachedModelNames[I], Name) = 0 then
        begin
         Result := I;
         Exit;
        end;

     Host_Error(['PF_PrecacheModel: "', Name, '": Precache can only be done in spawn functions, or when the server is loading.']);
    end;
  end;

Result := 0;
end;

function PF_PrecacheSound(Name: PLChar): UInt32; cdecl;
var
 I: Int;
begin
if Name = nil then
 Host_Error('PF_PrecacheSound: NULL pointer.')
else
 if PR_IsEmptyString(Name) then
  Host_Error(['PF_PrecacheSound: Bad string "', Name, '".'])
 else
  if Name^ = '!' then
   Host_Error(['PF_PrecacheSound: "', Name, '": Can''t precache sentence names.'])
  else
   begin
    if SV.State = SS_LOADING then
     begin
      SV.SoundTableReady := False;
      for I := 0 to MAX_SOUNDS - 1 do
       if SV.PrecachedSoundNames[I] = nil then
        begin
         SV.PrecachedSoundNames[I] := Name;
         Result := I;
         Exit;
        end
       else
        if StrIComp(SV.PrecachedSoundNames[I], Name) = 0 then
         begin
          Result := I;
          Exit;
         end;

      Host_Error(['PF_PrecacheSound: Sound "', Name, '" failed to precache because the item count is over the MAX_SOUNDS (', MAX_SOUNDS, ') limit.' + LineBreak +
                  'Reduce the number of sound entities and ambient sounds in the map to correct this.']);
     end
    else
     begin
      for I := 0 to MAX_SOUNDS - 1 do
       if SV.PrecachedSoundNames[I] = nil then
        Break
       else
        if StrIComp(SV.PrecachedSoundNames[I], Name) = 0 then
         begin
          Result := I;
          Exit;
         end;

      Host_Error(['PF_PrecacheSound: "', Name, '": Precache can only be done in spawn functions, or when the server is loading.']);
     end;
   end;

Result := 0;
end;

procedure PF_SetModel(var E: TEdict; ModelName: PLChar); cdecl;
var
 I: Int;
begin
for I := 0 to MAX_MODELS - 1 do
 if SV.PrecachedModelNames[I] = nil then
  Break
 else
  if StrIComp(SV.PrecachedModelNames[I], ModelName) = 0 then
   begin
    E.V.ModelIndex := I;
    E.V.Model := UInt(ModelName) - PRStrings;
    if SV.PrecachedModels[I] <> nil then
     SetMinMaxSize(E, SV.PrecachedModels[I].MinS, SV.PrecachedModels[I].MaxS)
    else
     SetMinMaxSize(E, Vec3Origin, Vec3Origin);
    Exit;
   end;

Host_Error(['PF_SetModel: "', ModelName, '" is not precached.']);
end;

function PF_ModelIndex(Name: PLChar): Int32; cdecl;
begin
Result := SV_ModelIndex(Name);
end;

function PF_ModelFrames(Index: Int32): Int32; cdecl;
begin
if (Index <= 0) or (Index >= MAX_MODELS) then
 begin
  DPrint('PF_ModelFrames: Bad model index.');
  Result := 1;
 end
else
 Result := ModelFrameIndex(SV.PrecachedModels[Index]^);
end;

procedure PF_SetSize(var E: TEdict; const MinS, MaxS: TVec3); cdecl;
begin
SetMinMaxSize(E, MinS, MaxS);
end;

procedure PF_ChangeLevel(S1, S2: PLChar); cdecl;
begin
if LastSpawnCount <> SVS.SpawnCount then
 begin
  LastSpawnCount := SVS.SpawnCount;
  SV_SkipUpdates;
  if S2 <> nil then
   CBuf_AddText(['changelevel2 ', S1, ' ', S2, #$A])
  else
   CBuf_AddText(['changelevel ', S1, #$A]);
 end;  
end;

procedure PF_SetSpawnParms(var E: TEdict); cdecl;
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I = 0) or (I > SVS.MaxClients) then
 Host_Error('PF_SetSpawnParms: Entity is not a client.');
end;

procedure PF_SaveSpawnParms(var E: TEdict); cdecl;
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I = 0) or (I > SVS.MaxClients) then
 Host_Error('PF_SaveSpawnParms: Entity is not a client.');
end;

function PF_VecToYaw(const V: TVec3): Double; cdecl;
begin
if (V[0] <> 0) or (V[1] <> 0) then
 begin
  Result := Trunc(ArcTan2(V[1], V[0]) * 180 / M_PI);
  if Result < 0 then
   Result := Result + 360;    
 end
else
 Result := 0;
end;

procedure PF_VecToAngles(const Fwd: TVec3; out Angles: TVec3); cdecl;
begin
VectorAngles(Fwd, Angles);
end;

procedure PF_MoveToOrigin(var E: TEdict; const Target: TVec3; Distance: Single; MoveType: Int32); cdecl;
begin
SV_MoveToOrigin(E, Target, Distance, MoveType);
end;

procedure PF_ChangeYaw(var E: TEdict); cdecl;
var
 Ideal, Current, Move, Speed: Single;
begin
Current := AngleMod(E.V.Angles[1]);
Ideal := E.V.IdealYaw;
Speed := E.V.YawSpeed;
if Current = Ideal then
 Exit;

Move := Ideal - Current;
if Ideal <= Current then
 if Move <= -180 then
  Move := Move + 360
 else
else
 if Move >= 180 then
  Move := Move - 360;

if Move > 0 then
 if Move > Speed then
  Move := Speed
 else
else
 if Move < -Speed then
  Move := -Speed;

E.V.Angles[1] := AngleMod(Move + Current);
end;

procedure PF_ChangePitch(var E: TEdict); cdecl;
var
 Ideal, Current, Move, Speed: Single;
begin
Current := AngleMod(E.V.Angles[0]);
Ideal := E.V.IdealPitch;
Speed := E.V.PitchSpeed;
if Current = Ideal then
 Exit;

Move := Ideal - Current;
if Ideal <= Current then
 if Move <= -180 then
  Move := Move + 360
 else
else
 if Move >= 180 then
  Move := Move - 360;

if Move > 0 then
 if Move > Speed then
  Move := Speed
 else
else
 if Move < -Speed then
  Move := -Speed;

E.V.Angles[0] := AngleMod(Move + Current);
end;

function GetIndex(Name: PLChar): Int;
var
 Buffer: array[1..512] of LChar;
begin
if Name = nil then
 Result := -1
else
 begin
  Name := StrLCopy(@Buffer, Name, SizeOf(Buffer) - 1);
  LowerCase(Name);
  if StrComp(Name, 'classname') = 0 then
   Result := UInt(@TEntVars(nil^).ClassName)
  else
   if StrComp(Name, 'model') = 0 then
    Result := UInt(@TEntVars(nil^).Model)
   else
    if StrComp(Name, 'viewmodel') = 0 then
     Result := UInt(@TEntVars(nil^).ViewModel)
    else
     if StrComp(Name, 'weaponmodel') = 0 then
      Result := UInt(@TEntVars(nil^).WeaponModel)
     else
      if StrComp(Name, 'netname') = 0 then
       Result := UInt(@TEntVars(nil^).NetName)
      else
       if StrComp(Name, 'target') = 0 then
        Result := UInt(@TEntVars(nil^).Target)
       else
        if StrComp(Name, 'targetname') = 0 then
         Result := UInt(@TEntVars(nil^).TargetName)
        else
         if StrComp(Name, 'message') = 0 then
          Result := UInt(@TEntVars(nil^).Msg)
         else
          if StrComp(Name, 'noise') = 0 then
           Result := UInt(@TEntVars(nil^).Noise)
          else
           if StrComp(Name, 'noise1') = 0 then
            Result := UInt(@TEntVars(nil^).Noise1)
           else
            if StrComp(Name, 'noise2') = 0 then
             Result := UInt(@TEntVars(nil^).Noise2)
            else
             if StrComp(Name, 'noise3') = 0 then
              Result := UInt(@TEntVars(nil^).Noise3)
             else
              if StrComp(Name, 'globalname') = 0 then
               Result := UInt(@TEntVars(nil^).GlobalName)
              else
               Result := -1;
 end;
end;

function FindEntityByFieldIndex(EntIndex, KeyIndex: UInt; Value: PLChar): PEdict;
var
 E: PEdict;
 S: PLChar;
 I: Int;
begin
for I := EntIndex + 1 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  if E.Free = 0 then
   begin
    S := PLChar(PRStrings + PStringOfs(UInt(@E.V) + KeyIndex)^);
    if (S <> nil) and (UInt(S) <> PRStrings) and (StrComp(S, Value) = 0) then
     begin
      Result := E;
      Exit;
     end;
   end;
 end;

Result := @SV.Edicts[0];
end;  

function PF_FindEntityByString(const E: TEdict; Key, Value: PLChar): PEdict; cdecl;
var
 Index: Int;
begin
Index := GetIndex(Key);
if (Index = -1) or (Value = nil) then
 Result := nil
else
 if @E <> nil then
  Result := FindEntityByFieldIndex(NUM_FOR_EDICT(E), Index, Value)
 else
  Result := FindEntityByFieldIndex(0, Index, Value);
end;

function PF_GetEntityIllum(const E: TEdict): Int32; cdecl;
begin
if @E <> nil then
 if NUM_FOR_EDICT(E) > SVS.MaxClients then
  Result := 128
 else
  Result := E.V.LightLevel
else
 Result := -1;
end;

function PF_FindEntityInSphere(const E: TEdict; const Origin: TVec3; Distance: Single): PEdict; cdecl;
var
 J, K: UInt;
 I: Int;
 P: PEdict;
 F, F2, F3: Single;
begin
if @E <> nil then
 K := NUM_FOR_EDICT(E) + 1
else
 K := 1;

F := Distance * Distance;

for I := K to SV.NumEdicts - 1 do
 begin
  P := @SV.Edicts[I];

  if (P.Free = 0) and (P.V.ClassName > 0) and ((UInt(I) > SVS.MaxClients) or SVS.Clients[I - 1].Active) then
   begin
    F2 := 0;
    for J := 0 to 2 do
     begin
      if F2 > F then
       Break;

      if Origin[J] < P.V.AbsMin[J] then
       F3 := Origin[J] - P.V.AbsMin[J]
      else
       if Origin[J] > P.V.AbsMax[J] then
        F3 := Origin[J] - P.V.AbsMax[J]
       else
        F3 := 0;

      F2 := F2 + F3 * F3;
     end;

    if F2 <= F then
     begin
      Result := P;
      Exit;
     end;
   end;
 end;

Result := @SV.Edicts[0];
end;

var
 CheckPVS: array[0..MAX_MAP_LEAFS div 8 - 1] of Byte;

function PF_NewCheckClient(Check: UInt): UInt;
var
 I: UInt;
 E: PEdict;
 V: TVec3;
 PVS: Pointer;
begin
if Check < 1 then
 Check := 1;
if Check > SVS.MaxClients then
 Check := SVS.MaxClients;

if Check = SVS.MaxClients then
 I := 1
else
 I := Check + 1;

repeat
 if I = SVS.MaxClients + 1 then
  I := 1;

 E := @SV.Edicts[I];
 if (I = Check) or ((E.Free = 0) and (E.PrivateData <> nil) and ((E.V.Flags and FL_NOTARGET) = 0)) then
  Break;

 Inc(I);
until False;

VectorAdd(E.V.Origin, E.V.ViewOfs, V);
PVS := Mod_LeafPVS(Mod_PointInLeaf(V, SV.WorldModel^), SV.WorldModel);
Move(PVS^, CheckPVS, (SV.WorldModel.NumLeafs + 7) shr 3);
Result := I;
end;

function PF_CheckClient(const E: TEdict): PEdict; cdecl;
var
 P: PEdict;
 View: TVec3;
 Leaf: Int;
begin
if SV.Time - SV.LastPVSCheckTime >= 0.1 then
 begin
  SV.LastPVSClient := PF_NewCheckClient(SV.LastPVSClient);
  SV.LastPVSCheckTime := SV.Time;
 end;

P := @SV.Edicts[SV.LastPVSClient];
if (P.Free = 0) and (P.PrivateData <> nil) then
 begin
  VectorAdd(E.V.ViewOfs, E.V.Origin, View);
  Leaf := (UInt(Mod_PointInLeaf(View, SV.WorldModel^)) - UInt(SV.WorldModel.Leafs)) div SizeOf(TMLeaf) - 1;
  if (Leaf >= 0) and (((1 shl (Leaf and 7)) and CheckPVS[Leaf shr 3]) > 0) then
   begin
    Result := P;
    Exit;
   end;
 end;

Result := @SV.Edicts[0];
end;

function PF_PVSFindEntities(const E: TEdict): PEdict; cdecl;
begin
Result := PVSFindEntities(E);
end;

procedure PF_MakeVectors(const V: TVec3); cdecl;
begin
AngleVectors(V, @GlobalVars.Fwd, @GlobalVars.Right, @GlobalVars.Up);
end;

procedure PF_AngleVectors(const Angles: TVec3; Fwd, Right, Up: PVec3); cdecl;
begin
AngleVectors(Angles, Fwd, Right, Up);
end;

function PF_Spawn: PEdict; cdecl;
begin
Result := ED_Alloc;
end;

procedure PF_Remove(var E: TEdict); cdecl;
begin
ED_Free(E);
end;

function PF_CreateNamedEntity(ClassName: TStringOfs): PEdict; cdecl;
var
 E: PEdict;
 F: TEntityInitFunc;
begin
if ClassName = 0 then
 Sys_Error('PF_CreateNamedEntity: Invalid classname.');

E := ED_Alloc;
E.V.ClassName := ClassName;

F := GetDispatch(PLChar(PRStrings + ClassName));
if @F <> nil then
 begin
  F(E.V);
  Result := E;
 end
else
 begin
  ED_Free(E^);
  DPrint(['Can''t create entity: "', PLChar(PRStrings + ClassName), '".']);
  Result := nil;
 end;
end;

procedure PF_MakeStatic(var E: TEdict); cdecl;
var
 I: UInt;
begin
MSG_WriteByte(SV.Signon, SVC_SPAWNSTATIC);
MSG_WriteShort(SV.Signon, SV_ModelIndex(PLChar(PRStrings + E.V.Model)));
MSG_WriteByte(SV.Signon, E.V.Sequence);
MSG_WriteByte(SV.Signon, Trunc(E.V.Frame));
MSG_WriteWord(SV.Signon, E.V.ColorMap);
MSG_WriteByte(SV.Signon, E.V.Skin);
for I := 0 to 2 do
 begin
  MSG_WriteCoord(SV.Signon, E.V.Origin[I]);
  MSG_WriteAngle(SV.Signon, E.V.Angles[I]);
 end;
MSG_WriteByte(SV.Signon, E.V.RenderMode);
if E.V.RenderMode <> 0 then
 begin
  MSG_WriteByte(SV.Signon, Trunc(E.V.RenderAmt));
  MSG_WriteByte(SV.Signon, Trunc(E.V.RenderColor[0]));
  MSG_WriteByte(SV.Signon, Trunc(E.V.RenderColor[1]));
  MSG_WriteByte(SV.Signon, Trunc(E.V.RenderColor[2]));
  MSG_WriteByte(SV.Signon, E.V.RenderFX);
 end;
ED_Free(E);
end;

function PF_CheckBottom(const E: TEdict): Int32; cdecl;
begin
Result := Int32(SV_CheckBottom(E));
end;

function PF_DropToFloor(var E: TEdict): Int32; cdecl;
var
 V: TVec3;
 Trace: TTrace;
begin
V[0] := E.V.Origin[0];
V[1] := E.V.Origin[1];
V[2] := E.V.Origin[2] - 256;

SV_Move(Trace, E.V.Origin, E.V.MinS, E.V.MaxS, V, MOVE_NORMAL, @E, (E.V.Flags and FL_MONSTERCLIP) > 0);
if Trace.AllSolid <> 0 then
 Result := -1
else
 if Trace.Fraction = 1 then
  Result := 0
 else
  begin
   E.V.Origin := Trace.EndPos;
   SV_LinkEdict(E, False);
   E.V.Flags := E.V.Flags or FL_ONGROUND;
   E.V.GroundEntity := Trace.Ent;
   Result := 1; 
  end;
end;

function PF_WalkMove(var E: TEdict; Yaw, Distance: Single; Mode: Int32): Int32; cdecl;
var
 Move: TVec3;
begin
if (E.V.Flags and (FL_ONGROUND or FL_FLY or FL_SWIM)) > 0 then
 begin
  Yaw := Yaw * (M_PI * 2) / 360;
  Move[0] := Cos(Yaw) * Distance;
  Move[1] := Sin(Yaw) * Distance;
  Move[2] := 0;
  if Mode = WALKMOVE_WORLDONLY then
   Result := Int32(SV_MoveTest(E, Move, True))
  else
   if Mode = WALKMOVE_CHECKONLY then
    Result := Int32(SV_MoveStep(E, Move, False))
   else
    Result := Int32(SV_MoveStep(E, Move, True));
 end
else
 Result := 0;
end;

procedure PF_SetOrigin(var E: TEdict; const Origin: TVec3); cdecl;
begin
E.V.Origin := Origin;
SV_LinkEdict(E, False);
end;

procedure PF_Sound(const E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
begin
if (Volume < 0) or (Volume > 1) then
 Sys_Error(['PF_Sound: Volume = ', Volume, '.'])
else
 if (Attn < 0) or (Attn > 4) then
  Sys_Error(['PF_Sound: Attenuation = ', Attn, '.'])
 else
  if (Channel < 0) or (Channel > 7) then
   Sys_Error(['PF_Sound: Channel = ', Channel, '.'])
  else
   if (Pitch < 0) or (Pitch > 255) then
    Sys_Error(['PF_Sound: Pitch = ', Pitch, '.']);

SV_StartSound(False, E, Channel, Sample, Trunc(Volume * 255), Attn, Flags, Pitch);
end;

procedure PF_AmbientSound(const E: TEdict; const Origin: TVec3; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
var
 Index, I: Int;
 SB: PSizeBuf;
begin
if Sample^ = '!' then
 begin
  Flags := Flags or SND_SENTENCE;
  Index := StrToIntDef(PLChar(UInt(Sample) + 1), CVOXFILESENTENCEMAX);
  if Index >= CVOXFILESENTENCEMAX then
   begin
    Print(['Invalid sentence number: ', PLChar(UInt(Sample) + 1), '.']);
    Exit;
   end;
 end
else
 begin
  Index := -1;
  for I := 0 to MAX_SOUNDS - 1 do
   if SV.PrecachedSoundNames[I] = nil then
    Break
   else
    if StrIComp(SV.PrecachedSoundNames[I], Sample) = 0 then
     begin
      Index := I;
      Break;
     end;

  if Index = -1 then
   begin
    Print(['PF_AmbientSound: "', Sample, '" is not precached.']);
    Exit;
   end;
 end;

if (Flags and SND_SPAWNING) > 0 then
 SB := @SV.Signon
else
 SB := @SV.Datagram;

MSG_WriteByte(SB^, SVC_SPAWNSTATICSOUND);
for I := 0 to 2 do
 MSG_WriteCoord(SB^, Origin[I]);

MSG_WriteShort(SB^, Index);
MSG_WriteByte(SB^, Trunc(Volume * 255));
MSG_WriteByte(SB^, Trunc(Attn * 64));
MSG_WriteShort(SB^, NUM_FOR_EDICT(E));
MSG_WriteByte(SB^, Pitch);
MSG_WriteByte(SB^, Flags);
end;

procedure PF_TraceLineShared(const VStart, VEnd: TVec3; MoveType: Int; PassEdict: PEdict);
var
 Trace: TTrace;
begin
SV_Move(Trace, VStart, Vec3Origin, Vec3Origin, VEnd, MoveType, PassEdict, False);
GlobalVars.TraceFlags := 0;
SV_SetGlobalTrace(Trace);
end;

procedure PF_TraceLine(const V1, V2: TVec3; MoveType: Int32; E: PEdict; out Trace: TTraceResult); cdecl;
begin
if E = nil then
 E := @SV.Edicts[0];

PF_TraceLineShared(V1, V2, MoveType, E);

Trace.AllSolid := Trunc(GlobalVars.TraceAllSolid);
Trace.StartSolid := Trunc(GlobalVars.TraceStartSolid);
Trace.InOpen := Trunc(GlobalVars.TraceInOpen);
Trace.InWater := Trunc(GlobalVars.TraceInWater);
Trace.Fraction := GlobalVars.TraceFraction;
Trace.PlaneDist := GlobalVars.TracePlaneDist;
Trace.Entity := GlobalVars.TraceEnt;
Trace.HitGroup := GlobalVars.TraceHitGroup;

Trace.EndPos := GlobalVars.TraceEndPos;
Trace.PlaneNormal := GlobalVars.TracePlaneNormal;
end;

procedure PF_TraceTossShared(const E: TEdict; IgnoreEnt: PEdict);
var
 Trace: TTrace;
begin
SV_Trace_Toss(Trace, E, IgnoreEnt);
SV_SetGlobalTrace(Trace);
end;

procedure PF_TraceToss(const E: TEdict; IgnoreEnt: PEdict; out Trace: TTraceResult); cdecl;
begin
if IgnoreEnt = nil then
 IgnoreEnt := @SV.Edicts[0];

PF_TraceTossShared(E, IgnoreEnt);

Trace.AllSolid := Trunc(GlobalVars.TraceAllSolid);
Trace.StartSolid := Trunc(GlobalVars.TraceStartSolid);
Trace.InOpen := Trunc(GlobalVars.TraceInOpen);
Trace.InWater := Trunc(GlobalVars.TraceInWater);
Trace.Fraction := GlobalVars.TraceFraction;
Trace.PlaneDist := GlobalVars.TracePlaneDist;
Trace.Entity := GlobalVars.TraceEnt;
Trace.HitGroup := GlobalVars.TraceHitGroup;

Trace.EndPos := GlobalVars.TraceEndPos;
Trace.PlaneNormal := GlobalVars.TracePlaneNormal;
end;

function PF_TraceMonsterHull(const E: TEdict; const V1, V2: TVec3; MoveType: Int32; EntityToSkip: PEdict; out Trace: TTraceResult): Int32; cdecl;
var
 T: TTrace;
begin
SV_Move(T, V1, E.V.MinS, E.V.MaxS, V2, MoveType, EntityToSkip, (E.V.Flags and FL_MONSTERCLIP) > 0);
if @Trace <> nil then
 begin
  Trace.AllSolid := T.AllSolid;
  Trace.StartSolid := T.StartSolid;
  Trace.InOpen := T.InOpen;
  Trace.InWater := T.InWater;
  Trace.Fraction := T.Fraction;
  Trace.PlaneDist := T.Plane.Distance;
  Trace.Entity := T.Ent;
  Trace.HitGroup := T.HitGroup;
  Trace.EndPos := T.EndPos;
  Trace.PlaneNormal := T.Plane.Normal;
 end;

Result := Int32((T.AllSolid <> 0) or (T.Fraction <> 1));
end;

procedure PF_TraceHull(const V1, V2: TVec3; MoveType, HullNumber: Int32; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;
var
 T: TTrace;
begin
if (HullNumber < 0) or (HullNumber > 3) then
 HullNumber := 0;

SV_Move(T, V1, PFHullMinS[HullNumber], PFHullMaxS[HullNumber], V2, MoveType, EntityToSkip, False);
Trace.AllSolid := T.AllSolid;
Trace.StartSolid := T.StartSolid;
Trace.InOpen := T.InOpen;
Trace.InWater := T.InWater;
Trace.Fraction := T.Fraction;
Trace.PlaneDist := T.Plane.Distance;
Trace.Entity := T.Ent;
Trace.HitGroup := T.HitGroup;
Trace.EndPos := T.EndPos;
Trace.PlaneNormal := T.Plane.Normal;
end;

procedure PF_TraceModel(const V1, V2: TVec3; HullNumber: Int32; var E: TEdict; out Trace: TTraceResult); cdecl;
var
 P: PModel;
 Solid, MoveType: Int32;
 T: TTrace;
begin
if (HullNumber < 0) or (HullNumber > 3) then
 HullNumber := 0;

P := SV.PrecachedModels[E.V.ModelIndex];
if (P <> nil) and (P.ModelType = ModBrush) then
 begin
  Solid := E.V.Solid;
  MoveType := E.V.MoveType;
  E.V.Solid := SOLID_BSP;
  E.V.MoveType := MOVETYPE_PUSH;
 end
else
 begin
  Solid := SOLID_NOT;
  MoveType := MOVETYPE_NONE;
 end;

SV_ClipMoveToEntity(T, E, V1, PFHullMinS[HullNumber], PFHullMaxS[HullNumber], V2);
if (P <> nil) and (P.ModelType = ModBrush) then
 begin
  E.V.Solid := Solid;
  E.V.MoveType := MoveType;
 end;

Trace.AllSolid := T.AllSolid;
Trace.StartSolid := T.StartSolid;
Trace.InOpen := T.InOpen;
Trace.InWater := T.InWater;
Trace.Fraction := T.Fraction;
Trace.PlaneDist := T.Plane.Distance;
Trace.Entity := T.Ent;
Trace.HitGroup := T.HitGroup;
Trace.EndPos := T.EndPos;
Trace.PlaneNormal := T.Plane.Normal;
end;

function PF_TraceTexture(E: PEdict; const V1, V2: TVec3): PLChar; cdecl;
begin
Result := SV_TraceTexture(E, V1, V2);
end;

procedure PF_TraceSphere(const V1, V2: TVec3; MoveType: Int32; Radius: Single; EntityToSkip: PEdict; out Trace: TTraceResult); cdecl;
begin
Sys_Error('PF_TraceSphere: Obsolete API call.');
end;

procedure PF_Aim(E: PEdict; Speed: Single; out VOut: TVec3); cdecl;
var
 VStart, Dir, VEnd, BestDir: TVec3;
 Trace: TTrace;
 BestDist, Dist: Single;
 I, J: Int;
 P: PEdict;
begin
if (E = nil) or ((E.V.Flags and FL_FAKECLIENT) > 0) then
 begin
  VOut := GlobalVars.Fwd;
  Exit;
 end;

VectorAdd(E.V.Origin, E.V.ViewOfs, VStart);
Dir := GlobalVars.Fwd;
VectorMA(VStart, 2048, Dir, VEnd);

SV_Move(Trace, VStart, Vec3Origin, Vec3Origin, VEnd, MOVE_NORMAL, E, False);
if (Trace.Ent <> nil) and (Trace.Ent.V.TakeDamage = DAMAGE_AIM) and ((E.V.Team <= 0) or (Trace.Ent.V.Team <> E.V.Team)) then
 begin
  VOut := GlobalVars.Fwd;
  Exit;
 end;

BestDir := Dir;
BestDist := sv_aim.Value;

for I := 1 to SV.NumEdicts - 1 do
 begin
  P := @SV.Edicts[I];
  if (P.V.TakeDamage <> DAMAGE_AIM) or ((P.V.Flags and FL_FAKECLIENT) > 0) or (P = E) or
     ((E.V.Team > 0) and (P.V.Team = E.V.Team)) then
   Continue;

  for J := 0 to 2 do
   VEnd[J] := (P.V.MinS[J] + P.V.MaxS[J]) * 0.75 + P.V.Origin[J]; 

  VectorSubtract(VEnd, VStart, Dir);
  VectorNormalize(Dir); 

  Dist := DotProduct(Dir, GlobalVars.Fwd);
  if Dist < BestDist then
   Continue;

  SV_Move(Trace, VStart, Vec3Origin, Vec3Origin, VEnd, MOVE_NORMAL, E, False);
  if Trace.Ent = P then
   begin
    BestDir := Dir;
    BestDist := Dist;
   end;
 end;

VOut := BestDir;
end;

function ValidCmd(S: PLChar): Boolean;
begin
Result := (S <> nil) and (S^ > #0) and (PLChar(UInt(S) + StrLen(S) - 1)^ in [';', #10]); 
end;

procedure PF_LocalCmd(S: PLChar); cdecl;
begin
if ValidCmd(S) then
 CBuf_AddText(S)
else
 if S <> nil then
  Print(['PF_LocalCmd: Bad server command "', S, '"; must end with \n or ";".'])
 else
  Print('PF_LocalCmd: Bad server command.')
end;

procedure PF_LocalExec; cdecl;
begin
CBuf_Execute;
end;

procedure PF_StuffCmd(const E: TEdict; S: PLChar); cdecl;
var
 Buf: array[1..1024] of LChar;
 I: UInt;
 SaveHostClient: PClient;
begin
if S = nil then
 Print('PF_StuffCmd: Invalid command.')
else
 begin
  S := StrLCopy(@Buf, S, SizeOf(Buf) - 1);
  I := NUM_FOR_EDICT(E);
  if (I < 1) or (I > SVS.MaxClients) then
   Print(['PF_StuffCmd: Player index #', I, ' is out of range.'])
  else
   if not ValidCmd(S) then
    Print(['PF_StuffCmd: Tried to stuff invalid command "', S, '" to player #', I, '.'])
   else
    begin
     SaveHostClient := HostClient;
     HostClient := @SVS.Clients[I - 1];
     Host_ClientCommands(S);
     HostClient := SaveHostClient;
    end;
 end;
end;

procedure PF_Particle(const Origin, Direction: TVec3; Color, Count: Single); cdecl;
begin
SV_StartParticle(Origin, Direction, Trunc(Color), Trunc(Count));
end;

procedure PF_LightStyle(Style: Int32; Value: PLChar); cdecl;
var
 I: Int;
 C: PClient;
begin
if (Style < 0) or (Style >= MAX_LIGHTSTYLES) then
 Sys_Error(['PF_LightStyle: Bad lightstyle index (#', Style, ').'])
else
 if Value = nil then
  Sys_Error('PF_LightStyle: Bad lightstyle description.');

SV.LightStyles[Style] := Value;
if SV.State = SS_ACTIVE then
 for I := 0 to SVS.MaxClients - 1 do
  begin
   C := @SVS.Clients[I];
   if (C.Active or C.Spawned) and not C.FakeClient then
    begin
     MSG_WriteByte(C.Netchan.NetMessage, SVC_LIGHTSTYLE);
     MSG_WriteByte(C.Netchan.NetMessage, Style);
     MSG_WriteString(C.Netchan.NetMessage, Value);
    end;
  end;
end;

function PF_DecalIndex(DecalName: PLChar): Int32; cdecl;
var
 I: Int;
begin
for I := 0 to SVDecalNameCount - 1 do
 if StrIComp(DecalName, @SVDecalNames[I]) = 0 then
  begin
   Result := I;
   Exit;
  end;

Result := -1;
end;

function PF_PointContents(const Point: TVec3): Int32; cdecl;
begin
Result := SV_PointContents(Point);
end;

function WriteDest_Parm(Dest: Int): PSizeBuf;
var
 I: UInt;
begin
case Dest of
 MSG_BROADCAST: Result := @SV.Datagram;
 MSG_ONE, MSG_ONE_UNRELIABLE:
  begin
   I := NUM_FOR_EDICT(MsgEntity^);
   if (I < 1) or (I > SVS.MaxClients) then
    Host_Error(['WriteDest_Parm: Tried to send MSG_ONE/MSG_ONE_UNRELIABLE to a client with invalid index #', I, '.']);
   if Dest = MSG_ONE then
    Result := @SVS.Clients[I - 1].Netchan.NetMessage
   else
    Result := @SVS.Clients[I - 1].UnreliableMessage;
  end;
 MSG_ALL: Result := @SV.ReliableDatagram;
 MSG_INIT: Result := @SV.Signon;
 MSG_PVS, MSG_PAS: Result := @SV.Multicast;
 MSG_SPEC: Result := @SV.Spectator;
 else
  begin
   Host_Error(['WriteDest_Parm: Bad message destination "', Dest, '".']);
   Result := nil;
  end;
end;
end;

procedure PF_MessageBegin(Dest, MessageType: Int32; Origin: PVec3; E: PEdict); cdecl;
begin
if ((Dest = MSG_ONE) or (Dest = MSG_ONE_UNRELIABLE)) and (E = nil) then
 Sys_Error('PF_MessageBegin: MSG_ONE or MSG_ONE_UNRELIABLE with no target entity.')
else
 if (Dest <> MSG_ONE) and (Dest <> MSG_ONE_UNRELIABLE) and (E <> nil) then
  Sys_Error('PF_MessageBegin: Cannot use broadcast messages with a target entity.')
 else
  if MsgStarted then
   Sys_Error(['PF_MessageBegin: New message started when message with type "', MsgType, '" has not been sent yet.'])
  else
   if MessageType = 0 then
    Sys_Error('PF_MessageBegin: Tried to create a message with a bogus type "0".');

MsgStarted := True;
MsgType := MessageType;
MsgEntity := E;
MsgDest := Dest;

if ((Dest = MSG_PVS) or (Dest = MSG_PAS)) and (Origin <> nil) then
 MsgOrigin := Origin^;

MsgBuffer.CurrentSize := 0;
MsgBuffer.AllowOverflow := [FSB_ALLOWOVERFLOW];
MsgBuffer.Data := @MsgData;
end;

procedure PF_MessageEnd; cdecl;
var
 NeedSize: Boolean;
 P: PUserMsg;
 SB: PSizeBuf;
 I: UInt;
 C: PClient;
begin
if not MsgStarted then
 Sys_Error('PF_MessageEnd: Called with no active message.');
MsgStarted := False;
if (MsgEntity <> nil) and ((MsgEntity.V.Flags and FL_FAKECLIENT) > 0) then
 Exit;

if FSB_OVERFLOWED in MsgBuffer.AllowOverflow then
 Sys_Error('PF_MessageEnd: Message buffer from game library had overflowed.');

NeedSize := False;
if MsgType > SVC_MESSAGE_END then
 begin
  P := UserMsgs;
  while P <> nil do
   if P.Index = MsgType then
    Break
   else
    P := P.Prev;

  if P = nil then
   begin
    if MsgDest = MSG_INIT then
     begin
      P := NewUserMsgs;
      while P <> nil do
       if P.Index = MsgType then
        Break
       else
        P := P.Prev;
     end;

    if P = nil then
     begin
      DPrint(['PF_MessageEnd: Unknown user message "', MsgType, '".']);
      Exit;
     end;
   end;
    
  if P.Size = -1 then
   begin
    NeedSize := True;
    if MsgBuffer.CurrentSize > 192 then
     Host_Error(['PF_MessageEnd: Refusing to send message "', PLChar(@P.Name), '" from game library with ',
                 MsgBuffer.CurrentSize, ' bytes to client, user message size limit is 192 bytes.']);
   end
  else
   if UInt(P.Size) <> MsgBuffer.CurrentSize then
    Host_Error(['PF_MessageEnd: User message "', PLChar(@P.Name), '": Bad size. Written ', MsgBuffer.CurrentSize,
                ' bytes, expected ', P.Size, ' bytes.']);
 end;

SB := WriteDest_Parm(MsgDest);
if ((MsgDest = MSG_BROADCAST) and (MsgBuffer.CurrentSize + SB.CurrentSize > SB.MaxSize)) or (SB.Data = nil) then
 Exit;

if (MsgType > SVC_MESSAGE_END) and ((MsgDest = MSG_ONE) or (MsgDest = MSG_ONE_UNRELIABLE)) then
 begin
  I := NUM_FOR_EDICT(MsgEntity^);
  if (I < 1) or (I > SVS.MaxClients) then
   Host_Error(['PF_MessageEnd: Entity with index ', I, ' is not a client.']);

  C := @SVS.Clients[I - 1];
  if (not C.Active and not C.Spawned) or not C.UserMsgReady or C.FakeClient then
   Exit;
 end;

MSG_WriteByte(SB^, MsgType);
if NeedSize then
 MSG_WriteByte(SB^, MsgBuffer.CurrentSize);
if MsgBuffer.CurrentSize > 0 then
 MSG_WriteBuffer(SB^, MsgBuffer.CurrentSize, MsgBuffer.Data);
case MsgDest of
 MSG_PVS: SV_Multicast(MsgEntity^, MsgOrigin, MULTICAST_PVS, False);
 MSG_PAS: SV_Multicast(MsgEntity^, MsgOrigin, MULTICAST_PAS, False);
 MSG_PVS_R: SV_Multicast(MsgEntity^, MsgOrigin, MULTICAST_PVS, True);
 MSG_PAS_R: SV_Multicast(MsgEntity^, MsgOrigin, MULTICAST_PAS, True); 
end;
end;

procedure PF_WriteByte(Value: Int32); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteByte: Called with no active message.')
else
 MSG_WriteByte(MsgBuffer, Value);
end;

procedure PF_WriteChar(Value: Int32); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteChar: Called with no active message.')
else
 MSG_WriteChar(MsgBuffer, LChar(Value));
end;

procedure PF_WriteShort(Value: Int32); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteShort: Called with no active message.')
else
 MSG_WriteShort(MsgBuffer, Value);
end;

procedure PF_WriteLong(Value: Int32); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteLong: Called with no active message.')
else
 MSG_WriteLong(MsgBuffer, Value);
end;

procedure PF_WriteAngle(Value: Single); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteAngle: Called with no active message.')
else
 MSG_WriteAngle(MsgBuffer, Value);
end;

procedure PF_WriteCoord(Value: Single); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteCoord: Called with no active message.')
else
 MSG_WriteShort(MsgBuffer, Trunc(Value * 8));
end;

procedure PF_WriteString(S: PLChar); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteString: Called with no active message.')
else
 MSG_WriteString(MsgBuffer, S);
end;

procedure PF_WriteEntity(Value: Int32); cdecl;
begin
if not MsgStarted then
 Sys_Error('PF_WriteEntity: Called with no active message.')
else
 MSG_WriteShort(MsgBuffer, Value);
end;

procedure PF_CVarRegister(var C: TCVar); cdecl;
begin
if @C <> nil then
 begin
  Include(C.Flags, FCVAR_EXTDLL);
  CVar_RegisterVariable(C);
 end;
end;

function PF_CVarGetFloat(Name: PLChar): Single; cdecl;
begin
Result := CVar_VariableValue(Name);
end;

function PF_CVarGetString(Name: PLChar): PLChar; cdecl;
begin
Result := CVar_VariableString(Name);
end;

procedure PF_CVarSetFloat(Name: PLChar; Value: Single); cdecl;
begin
CVar_SetValue(Name, Value);
end;

procedure PF_CVarSetString(Name, Value: PLChar); cdecl;
begin
CVar_Set(Name, Value);
end;

procedure PF_AlertMessage(AlertType: TAlertType; Msg: PChar); cdecl;
var
 Buf: array[1..1024] of LChar;
 L: UInt;
begin
if (AlertType = atLogged) and (SVS.MaxClients > 1) then
 Log_PrintF(Msg)
else
 if developer.Value <> 0 then
  begin
   Buf[Low(Buf)] := #0;
   case AlertType of
    atNotice: StrCopy(@Buf, 'NOTE:  ');
    atConsole: ;
    atAIConsole: if developer.Value < 2 then Exit;
    atWarning: StrCopy(@Buf, 'WARNING:  ');
    atError: StrCopy(@Buf, 'ERROR:  ');
   end;

   L := StrLen(@Buf);
   StrLCopy(PLChar(UInt(@Buf) + L), Msg, SizeOf(Buf) - L - 1);
   Print(@Buf);   
  end; 
end;

procedure PF_EngineFPrintF(F: Pointer; Msg: PLChar); cdecl;
begin
PF_AlertMessage(atConsole, 'EngineFPrintF: Obsolete API call.');
end;

function PF_PvAllocEntPrivateData(var E: TEdict; Size: Int32): Pointer; cdecl;
begin
Result := PvAllocEntPrivateData(E, Size);
end;

function PF_PvEntPrivateData(const E: TEdict): Pointer; cdecl;
begin
Result := PvEntPrivateData(E);
end;

procedure PF_FreeEntPrivateData(var E: TEdict); cdecl;
begin
FreeEntPrivateData(E);
end;

function PF_SzFromIndex(Index: TStringOfs): PLChar; cdecl;
begin
Result := PLChar(PRStrings + Index);
end;

function PF_AllocEngineString(S: PLChar): TStringOfs; cdecl;
begin
Result := UInt(ED_NewString(S)) - PRStrings;
end;

function PF_GetVarsOfEnt(const E: TEdict): PEntVars; cdecl;
begin
Result := @E.V;
end;

function PF_PEntityOfEntOffset(Offset: UInt32): PEdict; cdecl;
begin
Result := Pointer(UInt(SV.Edicts) + Offset);
end;

function PF_EntOffsetOfPEntity(const E: TEdict): UInt32; cdecl;
begin
Result := UInt(@E) - UInt(SV.Edicts);
end;

function PF_IndexOfEdict(E: PEdict): Int32; cdecl;
begin
if E <> nil then
 begin
  Result := (UInt(E) - UInt(SV.Edicts)) div SizeOf(E^);
  if (Result < 0) or (Result >= Int32(SV.MaxEdicts)) then
   Sys_Error('PF_IndexOfEdict: Bad entity.');
 end
else
 Result := 0;
end;

function PF_PEntityOfEntIndex(Index: Int32): PEdict; cdecl;
var
 E: PEdict;
begin
if (Index >= 0) and (UInt32(Index) < SV.MaxEdicts) then
 begin
  E := EDICT_NUM(Index);
  Result := nil;

  if E = nil then
   Exit;

  if (E.Free = 0) and (E.PrivateData <> nil) then
   Result := E;

  if (E.Free = 0) and (UInt(Index) <= SVS.MaxClients) then
   Result := E;
 end
else
 Result := nil;
end;

function PF_FindEntityByVars(const E: TEntVars): PEdict; cdecl;
var
 I: Int;
begin
for I := 0 to SV.NumEdicts - 1 do
 if @SV.Edicts[I].V = @E then
  begin
   Result := @SV.Edicts[I];
   Exit;
  end;

Result := nil;
end;

function PF_GetModelPtr(E: PEdict): Pointer; cdecl;
begin
if E <> nil then
 Result := Mod_ExtraData(SV.PrecachedModels[E.V.ModelIndex]^)
else
 Result := nil;
end;

function PF_RegUserMsg(Name: PLChar; Size: Int32): Int32; cdecl;
var
 P: PUserMsg;
begin
if (NextUserMsg >= MAX_USER_MESSAGE) or (Name = nil) or (StrLen(Name) >= 16) or (Size > 192) then
 begin
  Result := 0;
  Exit;
 end;

P := UserMsgs;
while P <> nil do
 if StrComp(Name, @P.Name) = 0 then
  Break
 else
  P := P.Prev;

if P = nil then
 begin
  P := Mem_ZeroAlloc(SizeOf(P^));
  P.Index := NextUserMsg;
  P.Size := Size;
  StrCopy(@P.Name, Name);
  P.Prev := NewUserMsgs;
  NewUserMsgs := P;
  Inc(NextUserMsg);
 end;

Result := P.Index;
end;

procedure PF_AnimationAutomove(var E: TEdict; Time: Single); cdecl;
begin

end;

procedure PF_GetBonePosition(var E: TEdict; Bone: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;
begin
StudioHdr := Mod_ExtraData(SV.PrecachedModels[E.V.ModelIndex]^);
SVBlendingAPI.SV_StudioSetupBones(SV.PrecachedModels[E.V.ModelIndex]^, E.V.Frame, E.V.Sequence, E.V.Angles, E.V.Origin, @E.V.Controller, @E.V.Blending, Bone, @E);
if @Origin <> nil then
 begin
  Origin[0] := BoneTransform[Bone][0][3];
  Origin[1] := BoneTransform[Bone][1][3];
  Origin[2] := BoneTransform[Bone][2][3];
 end;
end;

{$IFDEF MSWINDOWS}

function PF_FunctionFromName(Name: PLChar): Pointer; cdecl;
var
 I, J: Int;
 P: PExtLibData;
begin
for I := 0 to NumExtDLL - 1 do
 begin
  P := @ExtDLL[I];
  for J := 0 to P.NumExport - 1 do
   if StrComp(Name, P.ExportTable[J].Name) = 0 then
    begin
     Result := P.ExportTable[J].Func;
     Exit;
    end;
 end;

Print(['PF_FunctionFromName: Can''t find "', Name, '".']);
Result := nil;
end;

function PF_NameForFunction(Func: Pointer): PLChar; cdecl;
var
 I, J: Int;
 P: PExtLibData;
begin
for I := 0 to NumExtDLL - 1 do
 begin
  P := @ExtDLL[I];
  for J := 0 to P.NumExport - 1 do
   if Func = P.ExportTable[J].Func then
    begin
     Result := P.ExportTable[J].Name;
     Exit;
    end;
 end;

Print(['PF_NameForFunction: Can''t find function at address ', Func, '.']);
Result := nil;
end;

{$ELSE}

function PF_FunctionFromName(Name: PLChar): Pointer; cdecl;
var
 I: Int;
begin
for I := 0 to NumExtDLL - 1 do
 begin
  Result := dlsym(ExtDLL[I].Handle, Name);
  if Result <> nil then
   Exit;
 end;

Print(['PF_FunctionFromName: Can''t find "', Name, '".']);
Result := nil;
end;

function PF_NameForFunction(Func: Pointer): PLChar; cdecl;
var
 DLInfo: TDLInfo;
begin
if dladdr(Func, DLInfo) <> 0 then
 Result := DLInfo.dli_sname
else
 begin
  Print(['PF_NameForFunction: Can''t find function at address ', Func, '.']);
  Result := nil;
 end;
end;

{$ENDIF}

procedure PF_ClientPrintF(const E: TEdict; PrintType: TPrintType; Msg: PLChar); cdecl;
var
 I: UInt;
 C: PClient;
begin
I := NUM_FOR_EDICT(E);
if (I < 1) or (I > SVS.MaxClients) then
 Print(['PF_ClientPrintF: Tried to print to a non-client (index: ', I, ').'])
else
 begin
  C := @SVS.Clients[I - 1];
  if C.FakeClient then
   Exit;

  case PrintType of
   PrintConsole, PrintChat:
    begin
     MSG_WriteByte(C.Netchan.NetMessage, SVC_PRINT);
     MSG_WriteString(C.Netchan.NetMessage, Msg);
    end;
   PrintCenter:
    begin
     MSG_WriteByte(C.Netchan.NetMessage, SVC_CENTERPRINT);
     MSG_WriteString(C.Netchan.NetMessage, Msg);
    end;
   else
    Print(['PF_ClientPrintF: Invalid print type "', UInt(PrintType), '".']);
  end;
 end;
end;

procedure PF_ServerPrint(Msg: PLChar); cdecl;
var
 Buf: array[1..16384] of LChar;
 S: PLChar;
begin
S := StrLECopy(@Buf, Msg, SizeOf(Buf) - 1);
if UInt(S) > UInt(@Buf) then
 begin
  Dec(UInt(S));
  if S^ = #10 then
   S^ := #0;
 end;

Print(@Buf);
end;

function PF_Cmd_Args: PLChar; cdecl;
begin
Result := Cmd_Args;
end;

function PF_Cmd_Argv(I: Int32): PLChar; cdecl;
begin
Result := Cmd_Argv(I);
end;

function PF_Cmd_Argc: Int32; cdecl;
begin
Result := Cmd_Argc;
end;

procedure PF_GetAttachment(var E: TEdict; Attachment: Int32; out Origin: TVec3; out Angles: TVec3); cdecl;
var
 V: TVec3;
 P: PMStudioAttachment;
begin
StudioHdr := Mod_ExtraData(SV.PrecachedModels[E.V.ModelIndex]^);
V[0] := -E.V.Angles[0];
V[1] := E.V.Angles[1];
V[2] := E.V.Angles[2];

P := Pointer(UInt(StudioHdr) + StudioHdr.AttachmentIndex + UInt(Attachment * SizeOf(P^)));
SVBlendingAPI.SV_StudioSetupBones(SV.PrecachedModels[E.V.ModelIndex]^, E.V.Frame, E.V.Sequence, V, E.V.Origin, @E.V.Controller, @E.V.Blending, P.Bone, @E);
if @Origin <> nil then
 VectorTransform(P.Origin, @BoneTransform[P.Bone], Origin);
end;

procedure PF_CRC32_Init(out CRC: TCRC); cdecl;
begin
CRC32_Init(CRC);
end;

procedure PF_CRC32_ProcessBuffer(var CRC: TCRC; Buffer: Pointer; Size: UInt32); cdecl;
begin
CRC32_ProcessBuffer(CRC, Buffer, Size);
end;

procedure PF_CRC32_ProcessByte(var CRC: TCRC; B: Byte); cdecl;
begin
CRC32_ProcessByte(CRC, B);
end;

function PF_CRC32_Final(CRC: TCRC): TCRC; cdecl;
begin
Result := CRC32_Final(CRC);
end;

function PF_RandomLong(Low, High: Int32): Int32; cdecl;
begin
Result := RandomLong(Low, High);
end;

function PF_RandomFloat(Low, High: Single): Double; cdecl; // single?
begin
Result := RandomFloat(Low, High);
end;

procedure PF_SetView(const Entity, Target: TEdict); cdecl;
var
 I: UInt;
 C: PClient;
begin
I := NUM_FOR_EDICT(Entity);
if (I < 1) or (I > SVS.MaxClients) then
 Host_Error(['PF_SetView: Bad client index (', I, ').'])
else
 begin
  C := @SVS.Clients[I - 1];
  if not C.FakeClient then
   begin
    C.Target := @Target;
    MSG_WriteByte(C.Netchan.NetMessage, SVC_SETVIEW);
    MSG_WriteShort(C.Netchan.NetMessage, NUM_FOR_EDICT(Target));
   end;  
 end;
end;

function PF_Time: Double; cdecl;
begin
Result := Sys_FloatTime;
end;

procedure PF_CrosshairAngle(const Entity: TEdict; Pitch, Yaw: Single); cdecl;
var
 I: UInt;
 C: PClient;
begin
I := NUM_FOR_EDICT(Entity);
if (I >= 1) and (I <= SVS.MaxClients) then
 begin
  C := @SVS.Clients[I - 1];
  if not C.FakeClient then
   begin
    if Pitch > 180 then
     Pitch := Pitch - 360
    else
     if Pitch < -180 then
      Pitch := Pitch + 360;

    if Yaw > 180 then
     Yaw := Yaw - 360
    else
     if Yaw < -180 then
      Yaw := Yaw + 360;

    MSG_WriteByte(C.Netchan.NetMessage, SVC_CROSSHAIRANGLE);
    MSG_WriteByte(C.Netchan.NetMessage, Trunc(Pitch * 5));
    MSG_WriteByte(C.Netchan.NetMessage, Trunc(Yaw * 5));
   end;
 end;
end;

function PF_LoadFileForMe(Name: PLChar; Length: PUInt32): Pointer; cdecl;
begin
Result := COM_LoadFile(Name, FILE_ALLOC_MEMORY, Length);
end;

procedure PF_FreeFile(Buffer: Pointer); cdecl;
begin
COM_FreeFile(Buffer);
end;

procedure PF_EndSection(Name: PLChar); cdecl;
begin
Host_EndSection(Name);
end;

function PF_CompareFileTime(S1, S2: PLChar; CompareResult: PInt32): Int32; cdecl;
begin
Result := Int32(COM_CompareFileTime(S1, S2, CompareResult^));
end;

procedure PF_GetGameDir(Buffer: PLChar); cdecl;
begin
StrLCopy(Buffer, GameDir, MAX_PATH_A - 1);
end;

procedure PF_CVar_RegisterVariable(var C: TCVar); cdecl;
begin
CVar_RegisterVariable(C);
end;

procedure PF_FadeVolume(const Entity: TEdict; FadePercent, FadeOutSeconds, HoldTime, FadeInSeconds: Int32); cdecl;
var
 I: UInt;
 C: PClient;
begin
I := NUM_FOR_EDICT(Entity);
if (I < 1) or (I > SVS.MaxClients) then
 Print(['PF_FadeVolume: Bad client index (', I, ').'])
else
 begin
  C := @SVS.Clients[I - 1];
  if not C.FakeClient then
   begin
    MSG_WriteByte(C.Netchan.NetMessage, SVC_SOUNDFADE);
    MSG_WriteByte(C.Netchan.NetMessage, FadePercent);
    MSG_WriteByte(C.Netchan.NetMessage, HoldTime);
    MSG_WriteByte(C.Netchan.NetMessage, FadeOutSeconds);
    MSG_WriteByte(C.Netchan.NetMessage, FadeInSeconds);
   end;
 end;
end;

procedure PF_SetClientMaxSpeed(var E: TEdict; Speed: Single); cdecl;
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I < 1) or (I > SVS.MaxClients) then
 Print(['PF_SetClientMaxSpeed: Bad client index (', I, ').'])
else
 E.V.MaxSpeed := Speed;
end;

function PF_CreateFakeClient(Name: PLChar): PEdict; cdecl;
var
 I: Int;
 C: PClient;
 E: PEdict;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if not C.Active and not C.Spawned and not C.Connected then
   begin
    E := EDICT_NUM(I + 1);
    if C.Frames <> nil then
     SV_ClearFrames(C.Frames);

    SV_SetResourceLists(C^);

    StrLCopy(@C.NetName, Name, SizeOf(C.NetName) - 1);
    C.Active := True;
    C.Spawned := True;
    C.SendInfo := True;
    C.Connected := True;
    C.UserMsgReady := False;

    C.FakeClient := True;
    C.HLTV := False;
    C.Protocol := 0;    
    C.SendResTime := 0;
    C.SendEntsTime := 0;
    C.UserID := CurrentUserID;
    Inc(CurrentUserID);

    C.Entity := E;
    E.V.NetName := UInt(@C.NetName) - PRStrings;
    E.V.ContainingEntity := E;
    E.V.Flags := (FL_CLIENT or FL_FAKECLIENT);

    Info_SetValueForKey(@C.UserInfo, 'name', Name, MAX_USERINFO_STRING);
    Info_SetValueForKey(@C.UserInfo, 'model', 'gordon', MAX_USERINFO_STRING);
    Info_SetValueForKey(@C.UserInfo, 'topcolor', '1', MAX_USERINFO_STRING);
    Info_SetValueForKey(@C.UserInfo, 'bottomcolor', '1', MAX_USERINFO_STRING);

    C.UpdateInfo := True;
    SV_ExtractFromUserInfo(C^);

    C.Auth.UniqueID := SV_CreateSID(C^);
    C.Auth.AuthType := atSteam;

    Result := E;
    Exit;
   end;
 end;

Result := nil;
end;

procedure PF_RunPlayerMove(const FakeClient: TEdict; const Angles: TVec3; FwdMove, SideMove, UpMove: Single; Buttons: Int16; Impulse, MSec: Byte); cdecl;
var
 OldHostClient: PClient;
 OldSVPlayer: PEdict;
 UserCmd: TUserCmd;
 Index: UInt;
begin
Index := NUM_FOR_EDICT(FakeClient);
if (Index < 1) or (Index > SVS.MaxClients) then
 Print(['PF_RunPlayerMove: Bad client index (#', Index, ').'])
else
 begin
  OldHostClient := HostClient;
  OldSVPlayer := SVPlayer;
  SVPlayer := @FakeClient;
  HostClient := @SVS.Clients[Index - 1];
  PM := @ServerMove;

  HostClient.ClientTime := HostFrameTime + SV.Time - (MSec / 1000);
  MemSet(UserCmd, SizeOf(UserCmd), 0);

  UserCmd.LightLevel := 0;
  UserCmd.ViewAngles := Angles;
  UserCmd.ForwardMove := FwdMove;
  UserCmd.SideMove := SideMove;
  UserCmd.UpMove := UpMove;
  UserCmd.Buttons := Buttons;
  UserCmd.Impulse := Impulse;
  UserCmd.MSec := MSec;
  SV_PreRunCmd;
  SV_RunCmd(UserCmd, 0);

  Move(UserCmd, HostClient.UserCmd, SizeOf(HostClient.UserCmd));
  SVPlayer := OldSVPlayer;
  HostClient := OldHostClient;
 end;
end;

function PF_NumberOfEntities: UInt32; cdecl;
var
 I: Int;
begin
Result := 0;
for I := 0 to SV.NumEdicts - 1 do
 if SV.Edicts[I].Free = 0 then
  Inc(Result);
end;

function PF_GetInfoKeyBuffer(E: PEdict): PLChar; cdecl;
const
 EmptyString: PLChar = '';
var
 I: UInt;
begin
if E <> nil then
 begin
  I := NUM_FOR_EDICT(E^);
  if I > 0 then
   if I > MAX_PLAYERS then
    Result := EmptyString
   else
    Result := @SVS.Clients[I - 1].UserInfo
  else
   Result := Info_ServerInfo;
 end
else
 Result := @LocalInfo;
end;

function PF_InfoKeyValue(Buffer, Key: PLChar): PLChar; cdecl;
begin
Result := Info_ValueForKey(Buffer, Key);
end;

procedure PF_SetKeyValue(Buffer, Key, Value: PLChar); cdecl;
begin
if Buffer = @LocalInfo then
 Info_SetValueForKey(Buffer, Key, Value, SizeOf(@LocalInfo))
else
 if Buffer = @ServerInfo then
  Info_SetValueForKey(Buffer, Key, Value, SizeOf(@ServerInfo))
 else
  Sys_Error('PF_SetKeyValue: Keys can only be set in LocalInfo or ServerInfo.');
end;

procedure PF_SetClientKeyValue(Index: Int32; Buffer, Key, Value: PLChar); cdecl;
begin
if (Buffer <> @LocalInfo) and (Buffer <> @ServerInfo) and (Index > 0) and (UInt(Index) <= SVS.MaxClients) and
   (StrComp(Info_ValueForKey(Buffer, Key), Value) <> 0) then
 begin
  Info_SetValueForKey(Buffer, Key, Value, MAX_USERINFO_STRING);
  SVS.Clients[Index - 1].UpdateInfo := True;
  SVS.Clients[Index - 1].UpdateInfoTime := 0;
 end;
end;

function PF_IsMapValid(Name: PLChar): Int32; cdecl;
begin
Result := Int32(IsMapValid(Name));
end;

procedure PF_StaticDecal(const Origin: TVec3; DecalIndex, EntityIndex, ModelIndex: Int32); cdecl;
begin
MSG_WriteByte(SV.Signon, SVC_TEMPENTITY);
MSG_WriteByte(SV.Signon, TE_BSPDECAL);
MSG_WriteCoord(SV.Signon, Origin[0]);
MSG_WriteCoord(SV.Signon, Origin[1]);
MSG_WriteCoord(SV.Signon, Origin[2]);
MSG_WriteShort(SV.Signon, DecalIndex);
MSG_WriteShort(SV.Signon, EntityIndex);
if ModelIndex <> 0 then
 MSG_WriteShort(SV.Signon, ModelIndex);
end;

function PF_PrecacheGeneric(Name: PLChar): UInt32; cdecl;
var
 I: Int;
begin
if Name = nil then
 Host_Error('PF_PrecacheGeneric: NULL pointer.')
else
 if PR_IsEmptyString(Name) then
  Host_Error(['PF_PrecacheGeneric: Bad string "', Name, '".'])
 else
  if SV.State = SS_LOADING then
   begin
    for I := 0 to MAX_GENERIC_ITEMS - 1 do
     if SV.PrecachedGeneric[I] = nil then
      begin
       SV.PrecachedGeneric[I] := Name;
       Result := I;
       Exit;
      end
     else
      if StrIComp(SV.PrecachedGeneric[I], Name) = 0 then
       begin
        Result := I;
        Exit;
       end;

    Host_Error(['PF_PrecacheGeneric: Generic item "', Name, '" failed to precache because the item count is over the ', MAX_GENERIC_ITEMS, ' limit.']);
   end
  else
   begin
    for I := 0 to MAX_GENERIC_ITEMS - 1 do
     if SV.PrecachedGeneric[I] = nil then
      Break
     else
      if StrIComp(SV.PrecachedGeneric[I], Name) = 0 then
       begin
        Result := I;
        Exit;
       end;

    Host_Error(['PF_PrecacheGeneric: "', Name, '": Precache can only be done in spawn functions, or when the server is loading.']);
   end;

Result := 0;
end;

function PF_GetPlayerUserID(const E: TEdict): Int32; cdecl;
var
 I: Int;
begin
if SV.Active and (@E <> nil) and (SVS.MaxClients > 0) then
 for I := 0 to SVS.MaxClients - 1 do
  if SVS.Clients[I].Entity = @E then
   begin
    Result := SVS.Clients[I].UserID;
    Exit;
   end;

Result := -1;
end;

procedure PF_BuildSoundMsg(const E: TEdict; Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch, Dest, MessageType: Int32; const Origin: TVec3; MsgEnt: PEdict); cdecl;
begin
PF_MessageBegin(Dest, MessageType, @Origin, MsgEnt);
SV_BuildSoundMsg(E, Channel, Sample, Trunc(Volume), Attn, Flags, Pitch, Origin, MsgBuffer);
PF_MessageEnd;
end;

function PF_IsDedicatedServer: Int32; cdecl;
begin
Result := 1;
end;

function PF_CVarGetPointer(Name: PLChar): PCVar; cdecl;
begin
Result := CVar_FindVar(Name);
end;

function PF_GetPlayerWONID(const E: TEdict): Int32; cdecl;
begin
Result := -1;
end;

procedure PF_RemoveKey(Data, Key: PLChar); cdecl;
begin
Info_RemoveKey(Data, Key);
end;

function PF_GetPhysicsKeyValue(const E: TEdict; Key: PLChar): PLChar; cdecl;
const
 EmptyString: PLChar = '';
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I >= 1) and (I <= SVS.MaxClients) then
 Result := Info_ValueForKey(@SVS.Clients[I - 1].PhysInfo, Key)
else
 begin
  Print(['PF_GetPhysicsKeyValue: Bad client index #', I, '.']);
  Result := EmptyString;
 end;
end;

procedure PF_SetPhysicsKeyValue(const E: TEdict; Key, Value: PLChar); cdecl;
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I >= 1) and (I <= SVS.MaxClients) then
 Info_SetValueForKey(@SVS.Clients[I - 1].PhysInfo, Key, Value, MAX_PHYSINFO_STRING)
else
 Print(['PF_SetPhysicsKeyValue: Bad client index #', I, '.']);
end;

function PF_GetPhysicsInfoString(const E: TEdict): PLChar; cdecl;
const
 EmptyString: PLChar = '';
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I >= 1) and (I <= SVS.MaxClients) then
 Result := @SVS.Clients[I - 1].PhysInfo
else
 begin
  Print(['PF_GetPhysicsInfoString: Bad client index #', I, '.']);
  Result := EmptyString;
 end;
end;

function PF_PrecacheEvent(EventType: Int32; Name: PLChar): UInt16; cdecl;
begin
Result := EV_Precache(EventType, Name);
end;

procedure PF_PlaybackEvent(Flags: UInt32; const E: TEdict; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;
begin
EV_Playback(Flags, E, EventIndex, Delay, Origin, Angles, FParam1, FParam2, IParam1, IParam2, BParam1, BParam2);
end;

function PF_SetFatPVS(const Origin: TVec3): PByte; cdecl;
begin
Result := SV_FatPVS(Origin);
end;

function PF_SetFatPAS(const Origin: TVec3): PByte; cdecl;
begin
Result := SV_FatPAS(Origin);
end;

function PF_CheckVisibility(var E: TEdict; VisSet: PByte): Int32; cdecl;
var
 I: Int;
 LeafIndex: UInt32;
begin
if VisSet = nil then
 begin
  Result := 1;
  Exit;
 end;

if E.HeadNode < 0 then
 begin
  for I := 0 to E.NumLeafs - 1 do
   if ((1 shl (E.LeafNums[I] and 7)) and PByte(UInt(VisSet) + UInt(E.LeafNums[I] shr 3))^) > 0 then
    begin
     Result := 1;
     Exit;
    end;

  Result := 0;
 end
else
 begin
  for I := 0 to MAX_ENT_LEAFS - 1 do
   begin
    LeafIndex := I;
    if E.LeafNums[I] = CONTENTS_EMPTY then
     Break;

    if ((1 shl (E.LeafNums[I] and 7)) and PByte(UInt(VisSet) + UInt(E.LeafNums[I] shr 3))^) > 0 then
     begin
      Result := 1;
      Exit;
     end;
   end;

  if CM_HeadnodeVisible(@SV.WorldModel.Nodes[E.HeadNode], VisSet, @LeafIndex) then
   begin
    E.LeafNums[E.NumLeafs] := LeafIndex;
    E.NumLeafs := (E.NumLeafs + 1) mod MAX_ENT_LEAFS;
    Result := 2;
   end
  else
   Result := 0;
 end;
end;

procedure PF_Delta_SetField(var D: TDelta; FieldName: PLChar); cdecl;
begin
Delta_SetField(D, FieldName);
end;

procedure PF_Delta_UnsetField(var D: TDelta; FieldName: PLChar); cdecl;
begin
Delta_UnsetField(D, FieldName);
end;

procedure PF_Delta_AddEncoder(Name: PLChar; Func: TDeltaEncoder); cdecl;
begin
Delta_AddEncoder(Name, Func);
end;

function PF_GetCurrentPlayer: Int32; cdecl;
begin
Result := (UInt(HostClient) - UInt(SVS.Clients)) div SizeOf(TClient);
if (Result < 0) or (UInt(Result) >= SVS.MaxClients) then
 Result := -1;
end;

function PF_CanSkipPlayer(const E: TEdict): Int32; cdecl;
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I >= 1) and (I <= SVS.MaxClients) then
 Result := Int32(SVS.Clients[I - 1].LW)
else
 begin
  Print(['PF_CanSkipPlayer: Bad client index (', I, ').']);
  Result := 0;
 end;
end;

function PF_Delta_FindField(const D: TDelta; FieldName: PLChar): Int32; cdecl;
begin
Result := Delta_FindFieldIndex(D, FieldName);
end;

procedure PF_Delta_SetFieldByIndex(var D: TDelta; FieldNumber: UInt32); cdecl;
begin
Delta_SetFieldByIndex(D, FieldNumber);
end;

procedure PF_Delta_UnsetFieldByIndex(var D: TDelta; FieldNumber: UInt32); cdecl;
begin
Delta_UnsetFieldByIndex(D, FieldNumber);
end;

procedure PF_SetGroupMask(Mask, Op: Int32); cdecl;
begin
GroupMask := Mask;
GroupOp := TGroupOp(Op);
end;

function PF_CreateInstancedBaseline(ClassName: UInt32; const Baseline: TEntityState): Int32; cdecl;
var
 I: UInt;
begin
I := SV.Baseline.NumEnts;
if I < MAX_BASELINES - 1 then
 begin
  SV.Baseline.Classnames[I] := ClassName;
  Move(Baseline, SV.Baseline.ES[I], SizeOf(TEntityState));
  Inc(SV.Baseline.NumEnts);
  Result := SV.Baseline.NumEnts;
 end
else
 Result := 0;
end;

procedure PF_CVar_DirectSet(var C: TCVar; Value: PLChar); cdecl;
begin
CVar_DirectSet(C, Value);
end;

procedure PF_ForceUnmodified(FT: TForceType; MinS, MaxS: PVec3; FileName: PLChar); cdecl;
var
 I: Int;
 C: PConsistency;
begin
if FileName = nil then
 Host_Error('PF_ForceUnmodified: NULL pointer.')
else
 if PR_IsEmptyString(FileName) then
  Host_Error(['PF_ForceUnmodified: Bad string "', FileName, '".'])
 else
  if SV.State = SS_LOADING then
   begin
    for I := 0 to MAX_CONSISTENCY - 1 do
     begin
      C := @SV.PrecachedConsistency[I];
      if C.Name = nil then
       begin
        C.Name := FileName;
        C.ForceType := FT;
        if MinS <> nil then
         C.MinS := MinS^;
        if MaxS <> nil then
         C.MaxS := MaxS^;
        Exit;
       end
      else
       if StrIComp(C.Name, FileName) = 0 then
        Exit;
     end;
     
    Host_Error(['PF_ForceUnmodified: File "', FileName, '" can''t be added to the consistency list because the item count is over the ', MAX_CONSISTENCY, ' limit.']);
   end
  else
   begin
    for I := 0 to MAX_CONSISTENCY - 1 do
     if SV.PrecachedConsistency[I].Name = nil then
      Break
     else
      if StrIComp(SV.PrecachedConsistency[I].Name, FileName) = 0 then
       Exit;

    Host_Error(['PF_ForceUnmodified: "', FileName, '": Precache can only be done in spawn functions, or when the server is loading.']);
   end;
end;

procedure PF_GetPlayerStats(const E: TEdict; out Ping, PacketLoss: Int32); cdecl;
var
 I: UInt;
begin
I := NUM_FOR_EDICT(E);
if (I >= 1) and (I <= SVS.MaxClients) then
 begin
  Ping := Trunc(SVS.Clients[I].Latency * 1000);
  PacketLoss := Trunc(SVS.Clients[I].PacketLoss);  
 end
else
 begin
  Print(['PF_GetPlayerStats: Bad client index #', I, '.']);
  Ping := 0;
  PacketLoss := 0;
 end;
end;

procedure PF_AddServerCommand(Name: PLChar; Func: TCmdFunction); cdecl;
begin
Cmd_AddGameCommand(Name, Func);
end;

function PF_Voice_GetClientListening(Receiver, Sender: Int32): Int32; cdecl;
begin
Dec(Receiver);
Dec(Sender);
if (Receiver < 0) or (Sender < 0) or (UInt(Receiver) >= SVS.MaxClients) or (UInt(Sender) >= SVS.MaxClients) then
 Result := 0
else
 Result := Int32(not (Receiver in SVS.Clients[Sender].BlockedVoice));
end;

function PF_Voice_SetClientListening(Receiver, Sender, IsListening: Int32): Int32; cdecl;
begin
Dec(Receiver);
Dec(Sender);
if (Receiver < 0) or (Sender < 0) or (UInt(Receiver) >= SVS.MaxClients) or (UInt(Sender) >= SVS.MaxClients) then
 Result := 0
else
 begin
  if IsListening <> 0 then
   Exclude(SVS.Clients[Sender].BlockedVoice, Receiver)
  else
   Include(SVS.Clients[Sender].BlockedVoice, Receiver);
  Result := 1;
 end;
end;

var
 AuthIDBuf: array[0..4, 1..64] of LChar;
 AuthIDCount: Int = -1;

function PF_GetPlayerAuthID(const E: TEdict): PLChar; cdecl;
var
 I: Int;
 C: PClient;
begin
AuthIDCount := (AuthIDCount + 1) mod 5;
Result := @AuthIDBuf[AuthIDCount];

if (@E <> nil) and SV.Active then
 for I := 0 to SVS.MaxClients - 1 do
  begin
   C := @SVS.Clients[I];
   if C.Active and (C.Entity = @E) then
    begin
     StrLCopy(Result, SV_GetClientIDString(C^), 63);
     Exit;
    end;
  end;

Result^ := #0;
end;

function PF_SequenceGet(FileName, EntryName: PLChar): Pointer; cdecl;
begin
Result := nil;
end;

function PF_SequencePickSentence(GroupName: PLChar; PickMethod: Int32; var Picked: Int32): Pointer; cdecl;
begin
Result := nil;
end;

function PF_GetFileSize(FileName: PLChar): UInt32; cdecl;
begin
if FileName <> nil then
 Result := COM_FileSize(FileName)
else
 begin
  Print('PF_GetFileSize: NULL filename pointer.');
  Result := 0;
 end;
end;

function PF_GetApproxWavePlayLength(FileName: PLChar): UInt32; cdecl;
begin
if FileName <> nil then
 Result := COM_GetApproxWavePlayLength(FileName)
else
 begin
  Print('PF_GetApproxWavePlayLength: NULL filename pointer.');
  Result := 0;
 end;
end;

function PF_VGUI2_IsCareerMatch: Int32; cdecl;
begin
Result := 0;
end;

function PF_VGUI2_GetLocalizedStringLength(S: PLChar): UInt32; cdecl;
begin
Result := 0;
end;

procedure PF_RegisterTutorMessageShown(MessageID: Int32); cdecl;
begin

end;

function PF_GetTimesTutorMessageShown(MessageID: Int32): Int32; cdecl;
begin
Result := -1;
end;

procedure PF_ProcessTutorMessageDecayBuffer(Buffer: Pointer; Length: UInt32); cdecl;
begin

end;

procedure PF_ConstructTutorMessageDecayBuffer(Buffer: Pointer; Length: UInt32); cdecl;
begin

end;

procedure PF_ResetTutorMessageDecayData; cdecl;
begin

end;

procedure PF_QueryClientCVarValue(var E: TEdict; Name: PLChar); cdecl;
var
 I: UInt;
 C: PClient;
begin
I := NUM_FOR_EDICT(E);
if (I >= 1) and (I <= SVS.MaxClients) then
 begin
  C := @SVS.Clients[I - 1];
  MSG_WriteByte(C.Netchan.NetMessage, SVC_SENDCVARVALUE);
  MSG_WriteString(C.Netchan.NetMessage, Name);
 end
else
 begin
  if @NewDLLFunctions.CVarValue <> nil then
   NewDLLFunctions.CVarValue(E, 'Bad Player');
  Print(['PF_QueryClientCVarValue: Bad client index (', I, ').'])
 end;
end;

procedure PF_QueryClientCVarValue2(var E: TEdict; Name: PLChar; RequestID: Int32); cdecl;
var
 I: UInt;
 C: PClient;
begin
I := NUM_FOR_EDICT(E);
if (I >= 1) and (I <= SVS.MaxClients) then
 begin
  C := @SVS.Clients[I - 1];
  MSG_WriteByte(C.Netchan.NetMessage, SVC_SENDCVARVALUE2);
  MSG_WriteLong(C.Netchan.NetMessage, RequestID);
  MSG_WriteString(C.Netchan.NetMessage, Name);
 end
else
 begin
  if @NewDLLFunctions.CVarValue2 <> nil then
   NewDLLFunctions.CVarValue2(E, RequestID, Name, 'Bad Player');
  Print(['PF_QueryClientCVarValue2: Bad client index (', I, ').'])
 end;
end;

function PF_EngCheckParm(Token: PLChar; var Next: PLChar): UInt32; cdecl;
begin
Result := COM_CheckParm(Token);
if @Next <> nil then
 if (Result > 0) and (Result < COM_GetParmCount - 1) then
  Next := COM_ParmByIndex(Result + 1)
 else
  Next := nil;
end;

function PF_Reserved: Pointer; cdecl;
begin
Sys_Error(['PF_Reserved: One of the reserved engine functions was called.' + LineBreak +
           'This usually means that there''s some discrepancy between engine and game library interface definitions,' + LineBreak +
           'or the engine pointer in the game library is mismatched.' + LineBreak +
           'A memory corruption or subtle errors in the code can also be an issue.' + LineBreak +
           'Engine interface version: ', DLL_INTERFACE_VERSION, '; TEngineFuncs structure size: ', SizeOf(TEngineFuncs), ' bytes' +
           ', number of functions in this structure: ', SizeOf(TEngineFuncs) div SizeOf(Pointer),
           ' (including ', ((UInt(@@TEngineFuncs(nil^).ReservedEnd) - UInt(@@TEngineFuncs(nil^).ReservedStart)) div SizeOf(Pointer)) + 1,
           ' reserved functions).']);

Result := nil;
end;

end.
