unit Renderer;

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure R_FlushStudioCache;

function R_StudioHull(var Model: TModel; Frame: Single; Sequence: Int32; const Angles, Origin, Offset: TVec3; Controller, Blending: PByte; HullCount: PInt32; Ent: PEdict; IsCS: Boolean): PHull;
function SV_HitgroupForStudioHull(Index: UInt): Int;
function R_StudioBodyVariations(var M: TModel): UInt;

function SV_HullForStudioModel(const E: TEdict; const MinS, MaxS: TVec3; out VOut: TVec3; out HullNum: Int32): PHull;

function SV_CheckSphereIntersection(const E: TEdict; const VStart, VEnd: TVec3): Boolean;

function PVSNode(const Node: TMNode; const AbsMin, AbsMax: TVec3): PMNode;
procedure PVSMark(const M: TModel; PVS: Pointer);
function PVSFindEntities(const E: TEdict): PEdict;

procedure R_ResetSVBlending;
procedure R_Init;

function R_StudioComputeBounds(Header: PStudioHeader; out MinS, MaxS: TVec3): Boolean;
function R_GetStudioBounds(Name: PLChar; out MinS, MaxS: TVec3): Boolean;

function __Mem_CAlloc(Count, Size: UInt32): Pointer; cdecl;
function __Cache_Check(C: PCacheUser): Pointer; cdecl;
function __COM_LoadCacheFile(Name: PLChar; Cache: PCacheUser): Pointer; cdecl;
function __Mod_ExtraData(var M: TModel): Pointer; cdecl;

procedure SV_StudioSetupBones(var Model: TModel; Frame: Single; Sequence: Int32; var Angles, Origin: TVec3; Controller, Blending: PByte; Bone: Int32; Ent: PEdict); cdecl;

var
 r_cachestudio: TCVar = (Name: 'r_cachestudio'; Data: '1');

 NoTextureMIP: PTexture;
 StudioHdr: PStudioHeader;
 BoneTransform: array[0..MAXSTUDIOBONES - 1, 0..2, 0..3] of Single;
 RotationMatrix: array[0..2, 0..3] of Single;

 SVBlendingDefault: TSVBlendingInterface =
  (Version: SV_BLENDING_INTERFACE_VERSION;
   SV_StudioSetupBones: SV_StudioSetupBones);
 SVBlendingAPI: PSVBlendingInterface = @SVBlendingDefault;

 ServerStudioAPI: TEngineStudioAPI =
  (Mem_CAlloc: __Mem_CAlloc;
   Cache_Check: __Cache_Check;
   COM_LoadCacheFile: __COM_LoadCacheFile;
   Mod_ExtraData: __Mod_ExtraData);

implementation

uses Common, Console, FileSys, Host, MathLib, Memory, Model, SVMain, SVWorld;

var
 VisFrameCount: Int = 0;

 StudioCache: array[0..MAXSTUDIOCACHE - 1] of TStudioCache;
 CacheCurrent: Int = 0;
 CurrentHull: Int32;
 CurrentPlane: Int32;
 CacheHull: array[0..MAXSTUDIOHULL - 1] of THull;
 CacheHullHitgroup: array[0..MAXSTUDIOHULL - 1] of Int32;
 CachePlanes: array[0..MAXSTUDIOHULL * 6 - 1] of TMPlane;

 StudioHull: array[0..MAXSTUDIOHULL - 1] of THull;
 StudioHullHitgroup: array[0..MAXSTUDIOHULL - 1] of Int32;
 StudioClipNodes: array[0..5] of TDClipNode;
 StudioPlanes: array[0..MAXSTUDIOHULL * 6 - 1] of TMPlane;
 
function __Mem_CAlloc(Count, Size: UInt32): Pointer; cdecl;
begin
Result := Mem_CAlloc(Count, Size);
end;

function __Cache_Check(C: PCacheUser): Pointer; cdecl;
begin
Result := Cache_Check(C^);
end;

function __COM_LoadCacheFile(Name: PLChar; Cache: PCacheUser): Pointer; cdecl;
begin
Result := COM_LoadCacheFile(Name, Cache);
end;

function __Mod_ExtraData(var M: TModel): Pointer; cdecl;
begin
Result := Mod_ExtraData(M);
end;







procedure SV_InitStudioHull;
var
 I: UInt;
begin
if StudioHull[0].Planes <> nil then
 Exit;

for I := 0 to High(StudioClipNodes) do
 begin
  StudioClipNodes[I].PlaneNum := I;
  StudioClipNodes[I].Children[I and 1] := CONTENTS_EMPTY;
  if I = High(StudioClipNodes) then
   StudioClipNodes[I].Children[(I and 1) xor 1] := CONTENTS_SOLID
  else
   StudioClipNodes[I].Children[(I and 1) xor 1] := I + 1;
 end;

for I := 0 to MAXSTUDIOHULL - 1 do
 begin
  StudioHull[I].ClipNodes := @StudioClipNodes;
  StudioHull[I].Planes := @StudioPlanes[I * 6];
  StudioHull[I].FirstClipNode := 0;
  StudioHull[I].LastClipNode := High(StudioClipNodes);
 end;
end;

function R_CheckStudioCache(const M: TModel; Frame: Single; Sequence: Int32; const Angles, Origin, Offset: TVec3; Controller, Blending: Pointer): PStudioCache;
var
 I: Int;
 C: PStudioCache;
begin
for I := 0 to MAXSTUDIOCACHE - 1 do
 begin
  C := @StudioCache[UInt((CacheCurrent - I) and (MAXSTUDIOCACHE - 1))];
  if (C.Model = @M) and (C.Frame = Frame) and (C.Sequence = Sequence) and VectorCompare(C.Angles, Angles) and
     VectorCompare(C.Origin, Origin) and VectorCompare(C.Offset, Offset) and (PUInt32(@C.Controller)^ = PUInt32(Controller)^) and
     (PUInt16(@C.Blending)^ = PUInt16(Blending)^) then
   begin
    Result := C;
    Exit;
   end;
 end;

Result := nil;
end;

procedure R_AddToStudioCache(Frame: Single; Sequence: Int32; const Angles, Origin, Offset: TVec3; Controller, Blending: Pointer; const M: TModel; Hull: PHull; HullCount: Int32);
var
 C: PStudioCache;
begin
if CurrentHull + HullCount >= MAXSTUDIOHULL then
 R_FlushStudioCache;

Inc(CacheCurrent);
C := @StudioCache[UInt(CacheCurrent and (MAXSTUDIOCACHE - 1))];
C.Frame := Frame;
C.Sequence := Sequence;
C.Angles := Angles;
C.Origin := Origin;
C.Offset := Offset;
PUInt32(@C.Controller)^ := PUInt32(Controller)^;
PUInt16(@C.Blending)^ := PUInt16(Blending)^;
C.Model := @M;
C.HullIndex := CurrentHull;
C.PlaneIndex := CurrentPlane;
C.HullCount := HullCount;

Move(Hull^, CacheHull[CurrentHull], SizeOf(THull) * HullCount);
Move(StudioPlanes, CachePlanes[CurrentPlane], SizeOf(TMPlane) * 6 * HullCount);
Move(StudioHullHitgroup, CacheHullHitgroup[CurrentHull], SizeOf(Int32) * HullCount);

Inc(CurrentHull, HullCount);
Inc(CurrentPlane, HullCount * 6);
end;

procedure R_StudioCalcBoneAdj(DAdt: Single; Adj: PSingleArray; PController1, PController2: PByteArray; MouthOpen: Byte);
var
 I: Int;
 C: PMStudioBoneController;
 A, B, F: Single;
begin
C := Pointer(UInt(StudioHdr) + UInt(StudioHdr.BoneControllerIndex));
for I := 0 to StudioHdr.NumBoneControllers - 1 do
 begin
  if C.Index > 3 then
   begin
    F := MouthOpen / 64;
    if F > 1 then
     F := 1;
    F := (1 - F) * C.FStart + F * C.FEnd;
   end
  else
   if (C.CType and STUDIO_RLOOP) > 0 then
    if Abs(PController1[C.Index] - PController2[C.Index]) > 128 then
     begin
      A := (PController1[I] + 128) mod 256;
      B := (PController2[I] + 128) mod 256;
      F := (A * DAdt + B * (1 - DAdt) - 128) * (360 / 256) + C.FStart;
     end
    else
     F := (PController1[C.Index] * DAdt + PController2[C.Index] * (1 - DAdt)) * (360 / 256) + C.FStart
   else
    begin
     F := (PController1[C.Index] * DAdt + PController2[C.Index] * (1 - DAdt)) / 255;
     if F < 0 then
      F := 0
     else
      if F > 1 then
       F := 1;
      
     F := (1 - F) * C.FStart + F * C.FEnd;
    end;

   case C.CType and STUDIO_TYPES of
    STUDIO_XR, STUDIO_YR, STUDIO_ZR: Adj[I] := F * (M_PI / 180);
    STUDIO_X, STUDIO_Y, STUDIO_Z: Adj[I] := F;
   end;

  Inc(UInt(C), SizeOf(C^));
 end;
end;

procedure R_StudioCalcBoneQuaterion(Frame: UInt; S: Single; const Bone: TMStudioBone; const Anim: TMStudioAnim; Adj: PSingleArray; out Q: TVec4);
const
 AV_SIZE = UInt(SizeOf(TMStudioAnimValue));
var
 I, K: UInt;
 Angle1, Angle2: TVec3;
 AV: PMStudioAnimValue;
 Q1, Q2: TVec4;
begin
for I := 0 to 2 do
 begin
  if Anim.Offset[I + 3] = 0 then
   begin
    Angle1[I] := Bone.Value[I + 3];
    Angle2[I] := Bone.Value[I + 3];
   end
  else
   begin
    K := Frame;
    AV := Pointer(UInt(@Anim) + Anim.Offset[I + 3]);
    if AV.Total < AV.Valid then
     K := 0;

    while AV.Total <= K do
     begin
      Dec(K, AV.Total);
      Inc(UInt(AV), (AV.Valid + 1) * AV_SIZE);
      if AV.Total < AV.Valid then
       K := 0;
     end;

    if AV.Valid <= K then
     begin
      Angle1[I] := PMStudioAnimValue(UInt(AV) + AV.Valid * AV_SIZE).Value;
      if AV.Total <= K + 1 then
       Angle2[I] := PMStudioAnimValue(UInt(AV) + (AV.Valid + 2) * AV_SIZE).Value
      else
       Angle2[I] := Angle1[I];
     end
    else
     begin
      Angle1[I] := PMStudioAnimValue(UInt(AV) + (K + 1) * AV_SIZE).Value;
      if AV.Valid <= K + 1 then
       if AV.Total <= K + 1 then
        Angle2[I] := PMStudioAnimValue(UInt(AV) + (AV.Valid + 2) * AV_SIZE).Value
       else
        Angle2[I] := Angle1[I]
      else
       Angle2[I] := PMStudioAnimValue(UInt(AV) + (K + 2) * AV_SIZE).Value;
     end;

    Angle1[I] := Angle1[I] * Bone.Scale[I + 3] + Bone.Value[I + 3];
    Angle2[I] := Angle2[I] * Bone.Scale[I + 3] + Bone.Value[I + 3];
   end;

  if Bone.BoneController[I + 3] <> -1 then
   begin
    Angle1[I] := Angle1[I] + Adj[Bone.BoneController[I + 3]];
    Angle2[I] := Angle2[I] + Adj[Bone.BoneController[I + 3]];
   end;
 end;

if VectorCompare(Angle1, Angle2) then
 AngleQuaternion(Angle1, Q)
else
 begin
  AngleQuaternion(Angle1, Q1);
  AngleQuaternion(Angle2, Q2);
  QuaternionSlerp(Q1, Q2, S, Q);
 end;
end;

procedure R_StudioCalcBonePosition(Frame: UInt; S: Single; const Bone: TMStudioBone; const Anim: TMStudioAnim; Adj: PSingleArray; out Pos: TVec3);
const
 AV_SIZE = UInt(SizeOf(TMStudioAnimValue));
var
 I, K: UInt;
 AV: PMStudioAnimValue;
begin
for I := 0 to 2 do
 begin
  Pos[I] := Bone.Value[I];
  if Anim.Offset[I] <> 0 then
   begin
    K := Frame;
    AV := Pointer(UInt(@Anim) + Anim.Offset[I]);
    if AV.Total < AV.Valid then
     K := 0;

    while AV.Total <= K do
     begin
      Dec(K, AV.Total);
      Inc(UInt(AV), (AV.Valid + 1) * AV_SIZE);
      if AV.Total < AV.Valid then
       K := 0;
     end;

    if AV.Valid <= K then
     if AV.Total <= K + 1 then
      Pos[I] := Pos[I] + ((1 - S) * PMStudioAnimValue(UInt(AV) + AV.Valid * AV_SIZE).Value +
                          S * PMStudioAnimValue(UInt(AV) + (AV.Valid + 2) * AV_SIZE).Value) * Bone.Scale[I]
     else
      Pos[I] := Pos[I] + PMStudioAnimValue(UInt(AV) + AV.Valid * AV_SIZE).Value * Bone.Scale[I]
    else
     if AV.Valid <= K + 1 then
      Pos[I] := Pos[I] + PMStudioAnimValue(UInt(AV) + (K + 1) * AV_SIZE).Value * Bone.Scale[I]
     else
      Pos[I] := Pos[I] + ((1 - S) * PMStudioAnimValue(UInt(AV) + (K + 1) * AV_SIZE).Value +
                          S * PMStudioAnimValue(UInt(AV) + (K + 2) * AV_SIZE).Value) * Bone.Scale[I];
   end;

  if (Bone.BoneController[I] <> -1) and (Adj <> nil) then
   Pos[I] := Pos[I] + Adj[Bone.BoneController[I]];
 end;
end;

procedure R_StudioSlerpBones(Q1: PVec4; Pos1: PVec3; Q2: PVec4; Pos2: PVec3; S: Single);
var
 S1: Single;
 I: Int;
 J: UInt;
 Q3: TVec4;
begin
if S < 0 then
 S := 0
else
 if S > 1 then
  S := 1;

S1 := 1 - S;

for I := 0 to StudioHdr.NumBones - 1 do
 begin
  QuaternionSlerp(Q1^, Q2^, S, Q3);
  Q1^ := Q3;
  for J := 0 to 2 do
   Pos1[J] := Pos1[J] * S1 + Pos2[J] * S;

  Inc(UInt(Q1), SizeOf(Q1^));
  Inc(UInt(Q2), SizeOf(Q2^));
  Inc(UInt(Pos1), SizeOf(Pos1^));
  Inc(UInt(Pos2), SizeOf(Pos2^));
 end;
end;

function R_GetAnim(var M: TModel; const Desc: TMStudioSeqDesc): PMStudioAnim;
var
 C: PCacheUser;
 Name: PLChar;
begin
if Desc.SeqGroup = 0 then
 Result := Pointer(UInt(StudioHdr) + Desc.AnimIndex)
else
 begin
  if M.SubModels = nil then
   M.SubModels := Mem_CAlloc(16, SizeOf(TCacheUser));

  C := Pointer(UInt(M.SubModels) + Desc.SeqGroup * SizeOf(TCacheUser));
  if Cache_Check(C^) = nil then
   begin
    Name := @PMStudioSeqGroup(UInt(StudioHdr) + StudioHdr.SeqGroupIndex + Desc.SeqGroup * SizeOf(TMStudioSeqGroup)).Name;
    DPrint(['Loading "', Name, '".']);
    COM_LoadCacheFile(Name, C);
   end;

  Result := Pointer(UInt(C.Data) + Desc.AnimIndex);
 end;
end;

procedure SV_SetStudioHullPlane(var Plane: TMPlane; Bone: Int32; Axis: UInt; F: Single);
begin
Plane.PlaneType := 5;
Plane.Normal[0] := BoneTransform[Bone][0][Axis];
Plane.Normal[1] := BoneTransform[Bone][1][Axis];
Plane.Normal[2] := BoneTransform[Bone][2][Axis];
Plane.Distance := (BoneTransform[Bone][0][3] * Plane.Normal[0] + BoneTransform[Bone][1][3] * Plane.Normal[1] +
                   BoneTransform[Bone][2][3] * Plane.Normal[2]) + F;
end;

function R_StudioHull(var Model: TModel; Frame: Single; Sequence: Int32; const Angles, Origin, Offset: TVec3; Controller, Blending: PByte; HullCount: PInt32; Ent: PEdict; IsCS: Boolean): PHull;
type
 PBBoxArray = ^TBBoxArray;
 TBBoxArray = array[0..0] of TMStudioBBox;
var
 C: PStudioCache;
 V, V2: TVec3;
 I, J, K: Int;
 BBox: PBBoxArray;
begin
SV_InitStudioHull;
if r_cachestudio.Value <> 0 then
 begin
  C := R_CheckStudioCache(Model, Frame, Sequence, Angles, Origin, Offset, Controller, Blending);
  if (C <> nil) then
   begin
    Move(CachePlanes[C.PlaneIndex], StudioPlanes, SizeOf(TMPlane) * 6 * C.HullCount);
    Move(CacheHull[C.HullIndex], StudioHull, SizeOf(THull) * C.HullCount);
    Move(CacheHullHitgroup[C.HullIndex], StudioHullHitgroup, SizeOf(Int32) * C.HullCount);
    HullCount^ := C.HullCount;
    Result := @StudioHull;
    Exit;
   end;
 end;

StudioHdr := Mod_ExtraData(Model);
V[0] := -Angles[0];
V[1] := Angles[1];
V[2] := Angles[2];
V2 := Origin;
SVBlendingAPI.SV_StudioSetupBones(Model, Frame, Sequence, V, V2, Controller, Blending, -1, Ent);

BBox := Pointer(UInt(StudioHdr) + StudioHdr.HitBoxIndex);

for I := 0 to StudioHdr.NumHitBoxes - 1 do
 begin
  J := I * 6;
  if (IsCS <> True) or (I <> 21) then
   begin
    StudioHullHitgroup[I] := BBox[I].Group;
    SV_SetStudioHullPlane(StudioPlanes[J + 0], BBox[I].Bone, 0, BBox[I].BBMax[0]);
    SV_SetStudioHullPlane(StudioPlanes[J + 1], BBox[I].Bone, 0, BBox[I].BBMin[0]);
    SV_SetStudioHullPlane(StudioPlanes[J + 2], BBox[I].Bone, 1, BBox[I].BBMax[1]);
    SV_SetStudioHullPlane(StudioPlanes[J + 3], BBox[I].Bone, 1, BBox[I].BBMin[1]);
    SV_SetStudioHullPlane(StudioPlanes[J + 4], BBox[I].Bone, 2, BBox[I].BBMax[2]);
    SV_SetStudioHullPlane(StudioPlanes[J + 5], BBox[I].Bone, 2, BBox[I].BBMin[2]);

    for K := 0 to 5 do
     if (K and 1) = 0 then
      StudioPlanes[J + K].Distance := StudioPlanes[J + K].Distance +
                                      (Abs(StudioPlanes[J + K].Normal[0] * Offset[0]) + Abs(StudioPlanes[J + K].Normal[1] * Offset[1]) +
                                       Abs(StudioPlanes[J + K].Normal[2] * Offset[2]))
     else
      StudioPlanes[J + K].Distance := StudioPlanes[J + K].Distance -
                                      (Abs(StudioPlanes[J + K].Normal[0] * Offset[0]) + Abs(StudioPlanes[J + K].Normal[1] * Offset[1]) +
                                       Abs(StudioPlanes[J + K].Normal[2] * Offset[2]));
   end;
 end;

if IsCS then
 HullCount^ := StudioHdr.NumHitBoxes - 1
else
 HullCount^ := StudioHdr.NumHitBoxes;

if r_cachestudio.Value <> 0 then
 R_AddToStudioCache(Frame, Sequence, Angles, Origin, Offset, Controller, Blending, Model, @StudioHull, HullCount^);

Result := @StudioHull;
end;

function SV_HitgroupForStudioHull(Index: UInt): Int;
begin
Result := StudioHullHitgroup[Index];
end;

procedure R_InitStudioCache;
begin
MemSet(StudioCache, SizeOf(StudioCache), 0);
CacheCurrent := 0;
CurrentHull := 0;
CurrentPlane := 0;
end;

procedure R_FlushStudioCache;
begin
R_InitStudioCache;
end;

function R_StudioBodyVariations(var M: TModel): UInt;
var
 I: Int;
 Header: PStudioHeader;
 P: PMStudioBodyParts;
begin
if M.ModelType = ModStudio then
 begin
  Header := Mod_ExtraData(M);
  if Header <> nil then
   begin
    Result := 1;
    P := Pointer(UInt(Header) + UInt(Header.BodyPartIndex));
    for I := 0 to Header.NumBodyParts - 1 do
     begin
      Result := Result * UInt(P.NumModels);
      Inc(UInt(P), SizeOf(P^));
     end;
    Exit;
   end;
 end;

Result := 0;
end;

procedure R_StudioPlayerBlend(const Desc: TMStudioSeqDesc; out Blend: Int32; var Pitch: Single);
begin
Blend := Trunc(Pitch * 3);
if Blend < Desc.BlendStart[0] then
 begin
  Pitch := Pitch - Desc.BlendStart[0] / 3;
  Blend := 0;
 end
else
 if Blend > Desc.BlendEnd[0] then
  begin
   Pitch := Pitch - Desc.BlendEnd[0] / 3;
   Blend := 255;
  end
 else
  begin
   if Desc.BlendEnd[0] - Desc.BlendStart[0] >= 0.1 then
    Blend := Trunc((Blend - Desc.BlendStart[0]) * 255 / (Desc.BlendEnd[0] - Desc.BlendStart[0]))
   else
    Blend := 127;

   Pitch := 0;
  end;
end;

function SV_HullForStudioModel(const E: TEdict; const MinS, MaxS: TVec3; out VOut: TVec3; out HullNum: Int32): PHull;
var
 Offset, Angles: TVec3;
 B, IsCS: Boolean;
 Scale: Single;
 Header: PStudioHeader;
 Blend: Int32;
 Controller: array[0..3] of Byte;
 Blending: array[0..1] of Byte;
begin
B := False;
Scale := 0.5;

VectorSubtract(MaxS, MinS, Offset);
if VectorCompare(Vec3Origin, Offset) and ((GlobalVars.TraceFlags and FTRACE_SIMPLEBOX) = 0) then
 begin
  B := True;
  if (E.V.Flags and FL_CLIENT) > 0 then
   if sv_clienttrace.Value = 0 then
    B := False
   else
    begin
     VectorSet(Offset, 1);
     Scale := sv_clienttrace.Value * 0.5;
    end;
 end;

IsCS := (E.V.GameState = 1) and (IsCStrike or IsCZero or IsTerrorStrike);
if ((SV.PrecachedModels[E.V.ModelIndex].Flags and $200) > 0) or B then
 begin
  VectorScale(Offset, Scale, Offset);
  VectorSet(VOut, 0);
  if (E.V.Flags and FL_CLIENT) > 0 then
   begin
    Header := Mod_ExtraData(SV.PrecachedModels[E.V.ModelIndex]^);
    StudioHdr := Header;

    Angles := E.V.Angles;
    R_StudioPlayerBlend(PMStudioSeqDesc(UInt(Header) + Header.SeqIndex + UInt(SizeOf(TMStudioSeqDesc) * E.V.Sequence))^, Blend, Angles[0]);

    PUInt32(@Controller)^ := $7F7F7F7F;
    Blending[0] := Byte(Blend);
    Blending[1] := 0;

    Result := R_StudioHull(SV.PrecachedModels[E.V.ModelIndex]^, E.V.Frame, E.V.Sequence, Angles, E.V.Origin, Offset, @Controller, @Blending, @HullNum, @E, IsCS);
   end
  else
   Result := R_StudioHull(SV.PrecachedModels[E.V.ModelIndex]^, E.V.Frame, E.V.Sequence, E.V.Angles, E.V.Origin, Offset, @E.V.Controller, @E.V.Blending, @HullNum, @E, IsCS);   
 end
else
 begin
  HullNum := 1;
  Result := SV_HullForEntity(E, MinS, MaxS, VOut);
 end;
end;

function DoesSphereIntersect(const Origin: TVec3; R: Single; const VStart, Ofs: TVec3): Boolean;
var
 V: TVec3;
 F, F2, F3: Single;
begin
VectorSubtract(VStart, Origin, V);
F := DotProduct(Ofs, Ofs);
F2 := DotProduct(V, Ofs) * 2;
F3 := DotProduct(V, V) - R;

Result := (F2 * F2 - 4 * F3 * F) > 0.000001;
end;

function SV_CheckSphereIntersection(const E: TEdict; const VStart, VEnd: TVec3): Boolean;
var
 Ofs: TVec3;
 M: PModel;
 Header: PStudioHeader;
 Desc: PMStudioSeqDesc;
 F1, F2, R: Single;
 I: Int;
begin
if (E.V.Flags and FL_CLIENT) > 0 then
 begin
  VectorSubtract(VEnd, VStart, Ofs);
  M := SV.PrecachedModels[E.V.ModelIndex];
  if (M <> nil) and (M.ModelType = ModStudio) then
   begin
    R := 0;
    Header := Mod_ExtraData(M^);
    Desc := PMStudioSeqDesc(UInt(Header) + Header.SeqIndex + UInt(SizeOf(TMStudioSeqDesc) * E.V.Sequence));
    for I := 0 to 2 do
     begin
      F1 := Abs(Desc.BBMin[I]);
      F2 := Abs(Desc.BBMax[I]);
      if F2 >= F1 then
       R := R + F2 * F2
      else
       R := R + F1 * F1;
     end;

    Result := DoesSphereIntersect(E.V.Origin, R, VStart, Ofs);
   end
  else
   Result := False
 end
else
 Result := True;
end;

function PVSNode(const Node: TMNode; const AbsMin, AbsMax: TVec3): PMNode;
var
 Plane: PMPlane;
 Sides: Int;
begin
if Node.VisFrame <> VisFrameCount then
 Result := nil
else
 if Node.Contents < 0 then
  if Node.Contents <> CONTENTS_SOLID then
   Result := @Node
  else
   Result := nil
 else
  begin
   Plane := Node.Plane;
   if Plane.PlaneType >= 3 then
    Sides := BoxOnPlaneSide(AbsMin, AbsMax, Plane)
   else
    if Plane.Distance <= AbsMin[Plane.PlaneType] then
     Sides := 1
    else
     if Plane.Distance >= AbsMax[Plane.PlaneType] then
      Sides := 2
     else
      Sides := 3;

   Result := nil;
   if (Sides and 1) > 0 then
    Result := PVSNode(Node.Children[0]^, AbsMin, AbsMax);

   if ((Sides and 2) > 0) and (Result = nil) then
    Result := PVSNode(Node.Children[1]^, AbsMin, AbsMax);
  end;
end;

procedure PVSMark(const M: TModel; PVS: Pointer);
var
 I: Int;
 Leaf: PMLeaf;
begin
Inc(VisFrameCount);

for I := 0 to M.NumLeafs - 1 do
 if ((1 shl (I and 7)) and PByte(UInt(PVS) + (UInt(I) shr 3))^) > 0 then
  begin
   Leaf := @M.Leafs[I + 1];
   repeat
    if Leaf.VisFrame = VisFrameCount then
     Break;

    Leaf.VisFrame := VisFrameCount;
    Leaf := @Leaf.Parent;
   until Leaf = nil;
  end;
end;

function PVSFindEntities(const E: TEdict): PEdict;
var
 V: TVec3;
 PVS: Pointer;
 I: Int;
 P, P2, P3: PEdict;
begin
VectorAdd(E.V.Origin, E.V.ViewOfs, V);
PVS := Mod_LeafPVS(Mod_PointInLeaf(V, SV.WorldModel^), SV.WorldModel);
PVSMark(SV.WorldModel^, PVS);
P3 := @SV.Edicts[0];

for I := 1 to SV.NumEdicts - 1 do
 begin
  P := @SV.Edicts[I];
  if P.Free = 0 then
   begin
    if (P.V.MoveType = MOVETYPE_FOLLOW) and (P.V.AimEnt <> nil) then
     P2 := P.V.AimEnt
    else
     P2 := P;

    if PVSNode(SV.WorldModel.Nodes[0], P2.V.AbsMin, P2.V.AbsMax) <> nil then
     begin
      P.V.Chain := P3;
      P3 := P;
     end;
   end;
 end;

Result := P3;
end;

procedure R_ResetSVBlending;
begin
SVBlendingAPI := @SVBlendingDefault;
end;

procedure SV_StudioSetupBones(var Model: TModel; Frame: Single; Sequence: Int32; var Angles, Origin: TVec3; Controller, Blending: PByte; Bone: Int32; Ent: PEdict); cdecl;
var
 PSeqDesc: PMStudioSeqDesc;
 PBone: PMStudioBone;
 PAnim: PMStudioAnim;
 I, J, K: Int;
 BoneMatrix: array[0..2, 0..3] of Single;
 Adj: array[0..7] of Single;
 BT: array[0..MAXSTUDIOBONES - 1] of UInt32;
 F, F2: Single;
 NB: UInt;
 Q1, Q2: array[0..MAXSTUDIOBONES - 1] of TVec4;
 Pos1, Pos2: array[0..MAXSTUDIOBONES - 1] of TVec3; 
begin
if (Sequence < 0) or (Sequence >= StudioHdr.NumSeq) then
 begin
  DPrint(['SV_StudioSetupBones: Sequence ', Sequence, '/', StudioHdr.NumSeq, ' out of range for model "', PLChar(@StudioHdr.Name), '".']);
  Sequence := 0;
 end;

PBone := Pointer(UInt(StudioHdr) + StudioHdr.BoneIndex);
PSeqDesc := Pointer(UInt(StudioHdr) + StudioHdr.SeqIndex + UInt(Sequence * SizeOf(PSeqDesc^)));
PAnim := R_GetAnim(Model, PSeqDesc^);
if (Bone < -1) or (Bone >= StudioHdr.NumBones) then
 Bone := 0;

if Bone = -1 then
 begin
  NB := StudioHdr.NumBones;
  for I := 0 to NB - 1 do
   BT[MAXSTUDIOBONES - 1 - I] := I;
 end
else
 begin
  NB := 0;
  repeat
   BT[NB] := Bone;
   Bone := PMStudioBone(UInt(PBone) + UInt(Bone) * SizeOf(PBone^)).Parent;
   Inc(NB);
  until Bone = -1;
 end;

if PSeqDesc.NumFrames > 1 then
 F := (PSeqDesc.NumFrames - 1) * Frame / 256
else
 F := 0;

K := Trunc(F);
F2 := Frac(F);
R_StudioCalcBoneAdj(0, @Adj, Pointer(Controller), Pointer(Controller), 0);

for I := NB - 1 downto 0 do
 begin
  R_StudioCalcBoneQuaterion(K, F2, PMStudioBone(UInt(PBone) + BT[I] * SizeOf(PBone^))^, PMStudioAnim(UInt(PAnim) + BT[I] * SizeOf(PAnim^))^, @Adj, Q1[BT[I]]);
  R_StudioCalcBonePosition(K, F2, PMStudioBone(UInt(PBone) + BT[I] * SizeOf(PBone^))^, PMStudioAnim(UInt(PAnim) + BT[I] * SizeOf(PAnim^))^, @Adj, Pos1[BT[I]]);
 end;

if PSeqDesc.NumBlends > 1 then
 begin
  PAnim := Pointer(UInt(R_GetAnim(Model, PSeqDesc^)) + UInt(SizeOf(PAnim^) * StudioHdr.NumBones));
  for I := NB - 1 downto 0 do
   begin
    R_StudioCalcBoneQuaterion(K, F2, PMStudioBone(UInt(PBone) + BT[I] * SizeOf(PBone^))^, PMStudioAnim(UInt(PAnim) + BT[I] * SizeOf(PAnim^))^, @Adj, Q2[BT[I]]);
    R_StudioCalcBonePosition(K, F2, PMStudioBone(UInt(PBone) + BT[I] * SizeOf(PBone^))^, PMStudioAnim(UInt(PAnim) + BT[I] * SizeOf(PAnim^))^, @Adj, Pos2[BT[I]]);
   end;

  R_StudioSlerpBones(@Q1, @Pos1, @Q2, @Pos2, PByte(Blending)^ / 255);
 end;

AngleMatrix(Angles, @RotationMatrix);
RotationMatrix[0][3] := Origin[0];
RotationMatrix[1][3] := Origin[1];
RotationMatrix[2][3] := Origin[2];

for I := NB - 1 downto 0 do
 begin
  QuaternionMatrix(Q1[BT[I]], @BoneMatrix);
  BoneMatrix[0][3] := Pos1[BT[I]][0];
  BoneMatrix[1][3] := Pos1[BT[I]][1];
  BoneMatrix[2][3] := Pos1[BT[I]][2];

  J := PMStudioBone(UInt(PBone) + BT[I] * SizeOf(PBone^))^.Parent;
  if J = -1 then
   R_ConcatTransforms(@RotationMatrix, @BoneMatrix, @BoneTransform[BT[I]])
  else
   R_ConcatTransforms(@BoneTransform[J], @BoneMatrix, @BoneTransform[BT[I]]);
 end;
end;

procedure R_Init;
var
 P: PTexture;
begin
CVar_RegisterVariable(r_cachestudio);

P := Hunk_AllocName(SizeOf(TTexture) + 256 + 64 + 16 + 4, 'notexture');
StrCopy(@P.Name, 'notexture');
P.Width := 16;
P.Height := 16;
P.Offsets[0] := SizeOf(TTexture);
P.Offsets[1] := P.Offsets[0] + 256;
P.Offsets[2] := P.Offsets[1] + 64;
P.Offsets[3] := P.Offsets[2] + 16;
MemSet(Pointer(UInt(P) + SizeOf(TTexture))^, 256 + 64 + 16 + 4, $FF);
NoTextureMIP := P;
end;

procedure R_StudioBoundVertex(var MinS, MaxS: TVec3; var NumBound: UInt; const Mid: TVec3);
var
 I: UInt;
begin
if NumBound > 0 then
 for I := 0 to 2 do
  begin
   if MinS[I] > Mid[I] then
    MinS[I] := Mid[I];
   if MaxS[I] < Mid[I] then
    MaxS[I] := Mid[I];
  end
else
 begin
  MinS := Mid;
  MaxS := Mid;
 end;

Inc(NumBound);
end;

procedure R_StudioBoundBone(var MinS, MaxS: TVec3; var NumBound: UInt; var Mid: TVec3);
var
 I: UInt;
begin
if NumBound > 0 then
 for I := 0 to 2 do
  begin
   if MinS[I] > Mid[I] then
    MinS[I] := Mid[I];
   if MaxS[I] < Mid[I] then
    MaxS[I] := Mid[I];
  end
else
 begin
  MinS := Mid;
  MaxS := Mid;
 end;

Inc(NumBound);
end;

procedure R_StudioAccumulateBoneVerts(var VertMinS, VertMaxS: TVec3; var VertBound: UInt; var BoneMinS, BoneMaxS: TVec3; var BoneBound: UInt);
var
 Mid: TVec3;
begin
if BoneBound > 0 then
 begin
  VectorSubtract(BoneMaxS, BoneMinS, Mid);
  VectorScale(Mid, 0.5, Mid);
  R_StudioBoundVertex(VertMinS, VertMaxS, VertBound, Mid);
  VectorScale(Mid, -1, Mid);
  R_StudioBoundVertex(VertMinS, VertMaxS, VertBound, Mid);

  VectorSet(BoneMinS, 0);
  VectorSet(BoneMaxS, 0);
  BoneBound := 0;
 end;
end;

function R_StudioComputeBounds(Header: PStudioHeader; out MinS, MaxS: TVec3): Boolean;
var
 I, J, K: Int;
 BodyParts: PMStudioBodyParts;
 StudioModel: PMStudioModel;
 Vertexes: PVec3;
 Seq: PMStudioSeqDesc;
 Bone, Bone2: PMStudioBone;
 Anim: PMStudioAnim;

 VertMinS, VertMaxS, BoneMinS, BoneMaxS, Pos: TVec3;
 TotalModels, VertNumBound, BoneNumBound: UInt;
begin
VectorSet(VertMinS, 0);
VectorSet(VertMaxS, 0);
VertNumBound := 0;
VectorSet(BoneMinS, 0);
VectorSet(BoneMaxS, 0);
BoneNumBound := 0;

TotalModels := 0;
BodyParts := Pointer(UInt(Header) + Header.BodyPartIndex);
for I := 0 to Header.NumBodyParts - 1 do
 begin
  Inc(TotalModels, BodyParts.NumModels);
  Inc(UInt(BodyParts), SizeOf(BodyParts^));
 end;

StudioModel := Pointer(BodyParts);
for I := 0 to TotalModels - 1 do
 begin
  Vertexes := Pointer(UInt(Header) + StudioModel.VertIndex);
  for J := 0 to StudioModel.NumVerts - 1 do
   begin
    R_StudioBoundVertex(VertMinS, VertMaxS, VertNumBound, Vertexes^);
    Inc(UInt(Vertexes), SizeOf(Vertexes^));
   end;

  Inc(UInt(StudioModel), SizeOf(StudioModel^));
 end;

Seq := Pointer(UInt(Header) + Header.SeqIndex);
Bone := Pointer(UInt(Header) + Header.BoneIndex);

for I := 0 to Header.NumSeq - 1 do
 begin
  Anim := Pointer(UInt(Header) + Seq.AnimIndex);
  Bone2 := Bone;
  for J := 0 to Header.NumBones - 1 do
   begin
    for K := 0 to Seq.NumFrames - 1 do
     begin
      R_StudioCalcBonePosition(K, 0, Bone2^, Anim^, nil, Pos);
      R_StudioBoundBone(BoneMinS, BoneMaxS, BoneNumBound, Pos);
     end;

    Inc(UInt(Bone2), SizeOf(Bone2^));
   end;

  R_StudioAccumulateBoneVerts(VertMinS, VertMaxS, VertNumBound, BoneMinS, BoneMaxS, BoneNumBound);
  Inc(UInt(Seq), SizeOf(Seq^));
 end;

MinS := VertMinS;
MaxS := VertMaxS;
Result := True;
end;

function R_GetStudioBounds(Name: PLChar; out MinS, MaxS: TVec3): Boolean;
var
 P: Pointer;
begin
Result := False;
MinS := Vec3Origin;
MaxS := Vec3Origin;

if (StrPos(Name, 'models') <> nil) and (StrPos(Name, '.mdl') <> nil) then
 begin
  P := COM_LoadFile(Name, FILE_ALLOC_MEMORY, nil);
  if P <> nil then
   begin
    if LittleLong(PUInt32(P)^) = Ord('I') + Ord('D') shl 8 + Ord('S') shl 16 + Ord('T') shl 24 then
     Result := R_StudioComputeBounds(P, MinS, MaxS);

    COM_FreeFile(P);
   end;
 end;
end;
 
end.
