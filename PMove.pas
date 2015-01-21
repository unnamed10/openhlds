unit PMove;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure PM_Init(P: PPlayerMove);

function PM_PlayerTrace(out Trace: TPMTrace; const VStart, VEnd: TVec3; TraceFlags, IgnorePE: Int32): PPMTrace;

var
 PlayerMinS: array[0..3] of TVec3 =
             ((-16, -16, -36),
              (-16, -16, -18),
              (0, 0, 0),
              (-32, -32, -32));

 PlayerMaxS: array[0..3] of TVec3 =
             ((16, 16, 36),
              (16, 16, 18),
              (0, 0, 0),
              (32, 32, 32));

 PM: PPlayerMove;

implementation

uses Common, Console, Edict, Info, MathLib, Renderer, Server, SVMove, SVSend, SVWorld, SysClock, SysMain;

function PM_RecursiveHullCheck(const Hull: THull; Num: Int32; P1F, P2F: Single; const P1, P2: TVec3; out Trace: TPMTrace): Boolean; forward;

var
 BoxHull: THull;
 BoxClipNodes: array[0..5] of TDClipNode;
 BoxPlanes: array[0..5] of TMPlane;

 GlobalTL1, GlobalTL2: TPMTrace;

 ContentsResult: Int32;

function PM_AddToTouched(const T: TPMTrace; const ImpactVelocity: TVec3): Boolean;
var
 I: Int;
begin
for I := 0 to PM.NumTouch - 1 do
 if PM.TouchIndex[I].Ent = T.Ent then
  begin
   Result := False;
   Exit;
  end;

if PM.NumTouch >= MAX_PHYSENTS then
 PM.Con_DPrintF('Too many entities were touched!')
else
 begin
  PM.TouchIndex[PM.NumTouch] := T;
  PM.TouchIndex[PM.NumTouch].DeltaVelocity := ImpactVelocity;
  Inc(PM.NumTouch);
 end;

Result := True;
end;

procedure PM_StuckTouch(HitEnt: Int32; const TraceResult: TPMTrace);
begin
if PM.Server <> 0 then
 PM_AddToTouched(TraceResult, PM.Velocity);
end;

function PM_HullForBSP(const E: TPhysEnt; out Offset: TVec3): PHull;
begin
case PM.UseHull of
 1: Result := @E.Model.Hulls[3];
 2: Result := @E.Model.Hulls[0];
 3: Result := @E.Model.Hulls[2];
 else Result := @E.Model.Hulls[1];
end;

VectorSubtract(Result.ClipMinS, PlayerMinS[PM.UseHull], Offset);
VectorAdd(Offset, E.Origin, Offset);
end;

function PM_TraceModel(const E: TPhysEnt; const VStart, VEnd: TVec3; var T: TTrace): Single;
var
 OldHull: Int32;
 H: PHull;
 Offset, P1, P2: TVec3;
begin
OldHull := PM.UseHull;
PM.UseHull := 2;
H := PM_HullForBSP(E, Offset);
PM.UseHull := OldHull;

VectorSubtract(VStart, Offset, P1);
VectorSubtract(VEnd, Offset, P2);

SV_RecursiveHullCheck(H^, H.FirstClipNode, 0, 1, P1, P2, T);
Result := T.Fraction;
T.Ent := nil;
end;

procedure PM_GetModelBounds(const Model: TModel; out MinS, MaxS: TVec3);
begin
MinS := Model.MinS;
MaxS := Model.MaxS;
end;

function PM_GetModelType(const Model: TModel): TModelType;
begin
Result := Model.ModelType;
end;

procedure PM_InitBoxHull;
var
 I: UInt;
begin
BoxHull.ClipNodes := @BoxClipNodes;
BoxHull.Planes := @BoxPlanes;
BoxHull.FirstClipNode := 0;
BoxHull.LastClipNode := High(BoxClipNodes);

for I := 0 to High(BoxClipNodes) do
 begin
  BoxClipNodes[I].PlaneNum := I;
  BoxClipNodes[I].Children[I and 1] := CONTENTS_EMPTY;
  if I = High(BoxClipNodes) then
   BoxClipNodes[I].Children[(I and 1) xor 1] := CONTENTS_SOLID
  else
   BoxClipNodes[I].Children[(I and 1) xor 1] := I + 1;

  BoxPlanes[I].PlaneType := I shr 1;
  BoxPlanes[I].Normal[I shr 1] := 1;
 end;
end;

function PM_HullForBox(const MinS, MaxS: TVec3): PHull;
begin
BoxPlanes[0].Distance := MaxS[0];
BoxPlanes[1].Distance := MinS[0];
BoxPlanes[2].Distance := MaxS[1];
BoxPlanes[3].Distance := MinS[1];
BoxPlanes[4].Distance := MaxS[2];
BoxPlanes[5].Distance := MinS[2];

Result := @BoxHull;
end;

function PM_HullPointContents(const Hull: THull; Num: Int32; const P: TVec3): Int32;
var
 Node: PDClipNode;
 Plane: PMPlane;
 D: Single;
begin
if Hull.FirstClipNode < Hull.LastClipNode then
 begin
  while Num >= 0 do
   begin
    if (Num < Hull.FirstClipNode) or (Num > Hull.LastClipNode) then
     Sys_Error('PM_HullPointContents: Bad node number.');

    Node := @Hull.ClipNodes[Num];
    Plane := @Hull.Planes[Node.PlaneNum];

    if Plane.PlaneType >= 3 then
     D := DotProduct(Plane.Normal, P) - Plane.Distance
    else
     D := P[Plane.PlaneType] - Plane.Distance;

    if D >= 0 then
     Num := Node.Children[0]
    else
     Num := Node.Children[1];
   end;

  Result := Num;
 end
else
 Result := CONTENTS_EMPTY;
end;

function PM_LinkContents(const P: TVec3; Info: PInt32): Int32;
var
 I: Int;
 E: PPhysEnt;
 P2: TVec3;
begin
for I := 1 to PM.NumPhysEnt - 1 do
 begin
  E := @PM.PhysEnts[I];
  if (E.Solid = 0) and (E.Model <> nil) then
   begin
    VectorSubtract(P, E.Origin, P2);
    if PM_HullPointContents(E.Model.Hulls[0], E.Model.Hulls[0].FirstClipNode, P2) <> CONTENTS_EMPTY then
     begin
      if Info <> nil then
       Info^ := E.Info;
      Result := E.Skin; 
      Exit;
     end;
   end;
 end;

Result := CONTENTS_EMPTY;
end;

function PM_PointContents(const P: TVec3; TrueContents: PInt32): Int32;
var
 I: Int32;
begin
I := PM_HullPointContents(PM.PhysEnts[0].Model.Hulls[0], PM.PhysEnts[0].Model.Hulls[0].FirstClipNode, P);
if TrueContents <> nil then
 TrueContents^ := I;

if I = CONTENTS_SOLID then
 begin
  Result := I;
  Exit;
 end
else
 if (I <= CONTENTS_CURRENT_0) and (I >= CONTENTS_CURRENT_DOWN) then
  I := CONTENTS_WATER;

Result := PM_LinkContents(P, nil);
if Result = CONTENTS_EMPTY then
 Result := I;
end;

function PM_WaterEntity(const P: TVec3): Int32;
var
 I, I2: Int32;
begin
I := PM_HullPointContents(PM.PhysEnts[0].Model.Hulls[0], PM.PhysEnts[0].Model.Hulls[0].FirstClipNode, P);
if I < CONTENTS_SOLID then
 I2 := 0
else
 I2 := -1;

if I <> CONTENTS_SOLID then
 PM_LinkContents(P, @I2);
Result := I2;
end;

function PM_TruePointContents(const P: TVec3): Int32;
begin
Result := PM_HullPointContents(PM.PhysEnts[0].Model.Hulls[0], PM.PhysEnts[0].Model.Hulls[0].FirstClipNode, P);
end;

function PM_HullForStudioModel(var Model: TModel; out Pos: TVec3; Frame: Single; Sequence: Int32; const Angles, Origin: TVec3; Controller, Blending: Pointer; HullNum: PInt32): PHull;
var
 P: TVec3;
begin
VectorSubtract(PlayerMaxS[PM.UseHull], PlayerMinS[PM.UseHull], P);
VectorScale(P, 0.5, P);
Pos[0] := 0;
Pos[1] := 0;
Pos[2] := 0;
Result := R_StudioHull(Model, Frame, Sequence, Angles, Origin, P, Controller, Blending, HullNum, nil, False);
end;

function _PM_PlayerTrace(out Trace: TPMTrace; const VStart, VEnd: TVec3; TraceFlags, NumPhysEnt: Int32; PhysEnts: PPhysEntArray; IgnorePE: Int32; IgnoreFunc: TPhysEntFunc): PPMTrace;
var
 J, LastHull: UInt;
 PE: PPhysEnt;
 Orig, V1, V2, V3, V4, Fwd, Right, Up: TVec3;
 Hull: PHull;
 HullNum: Int32;
 B, B2: Boolean;
 TL, TL2: TPMTrace;
 I: Int;
begin
Hull := nil;
MemSet(Trace, SizeOf(Trace), 0);
Trace.Fraction := 1;
Trace.EndPos := VEnd;
Trace.Ent := -1;

for I := 0 to NumPhysEnt - 1 do
 begin
  PE := @PhysEnts[I];

  if (I > 0) and ((TraceFlags and PM_WORLD_ONLY) > 0) then
   Break; // #0 is world brush entity

  if @IgnoreFunc = nil then
   if IgnorePE = I then
    Continue
   else
  else
   if IgnoreFunc(PE^) <> 0 then
    Continue;

  if (PE.Model <> nil) and (PE.Solid = 0) and (PE.Skin <> 0) then
   Continue;

  if ((TraceFlags and PM_GLASS_IGNORE) > 0) and (PE.RenderMode <> 0) then
   Continue;

  Orig := PE.Origin;
  HullNum := 1;

  if PE.Model <> nil then
   Hull := PM_HullForBSP(PE^, Orig)
  else
   if PE.StudioModel <> nil then
    begin
     if (TraceFlags and PM_STUDIO_IGNORE) > 0 then
      Continue;

     if (PE.StudioModel.ModelType = ModStudio) and (((PE.StudioModel.Flags and $200) > 0) or ((PM.UseHull = 2) and ((TraceFlags and PM_STUDIO_BOX) = 0))) then
      Hull := PM_HullForStudioModel(PE.StudioModel^, Orig, PE.Frame, PE.Sequence, PE.Angles, PE.Origin, @PE.Controller, @PE.Blending, @HullNum)
     else
      begin
       VectorSubtract(PE.MinS, PlayerMaxS[PM.UseHull], V1);
       VectorSubtract(PE.MaxS, PlayerMinS[PM.UseHull], V2);
       Hull := PM_HullForBox(V1, V2);
      end;
    end
   else
    begin
     VectorSubtract(PE.MinS, PlayerMaxS[PM.UseHull], V1);
     VectorSubtract(PE.MaxS, PlayerMinS[PM.UseHull], V2);
     Hull := PM_HullForBox(V1, V2);
    end;

  VectorSubtract(VStart, Orig, V1);
  VectorSubtract(VEnd, Orig, V2);

  if (PE.Solid <> SOLID_BSP) or ((PE.Angles[0] = 0) and (PE.Angles[1] = 0) and (PE.Angles[2] = 0)) then
   B := False
  else
   begin
    B := True;
    AngleVectors(PE.Angles, @Fwd, @Right, @Up);
    V3[0] := DotProduct(V1, Fwd);
    V3[1] := -DotProduct(V1, Right);
    V3[2] := DotProduct(V1, Up);
    V4[0] := DotProduct(V2, Fwd);
    V4[1] := -DotProduct(V2, Right);
    V4[2] := DotProduct(V2, Up);
    V1 := V3;
    V2 := V4;
   end;

  LastHull := 0;
  MemSet(TL, SizeOf(TL), 0);
  TL.Fraction := 1;
  TL.AllSolid := 1;
  TL.EndPos := VEnd;

  if HullNum <= 0 then
   TL.AllSolid := 0
  else
   if HullNum = 1 then
    PM_RecursiveHullCheck(Hull^, Hull.FirstClipNode, 0, 1, V1, V2, TL)
   else
    for J := 0 to HullNum - 1 do
     begin
      MemSet(TL2, SizeOf(TL2), 0);
      TL2.Fraction := 1;
      TL2.AllSolid := 1;
      TL2.EndPos := VEnd;

      PM_RecursiveHullCheck(Hull^, Hull.FirstClipNode, 0, 1, V1, V2, TL2);
      if (J = 0) or (TL2.AllSolid > 0) or (TL2.StartSolid > 0) or (TL2.Fraction < TL.Fraction) then
       begin
        B2 := TL.StartSolid <> 0;
        Move(TL2, TL, SizeOf(TL));
        if B2 then
         TL.StartSolid := 1;
        LastHull := J;
       end;

      TL.HitGroup := SV_HitgroupForStudioHull(LastHull);
      Inc(UInt(Hull), SizeOf(Hull^));
     end;

  if TL.AllSolid > 0 then
   TL.StartSolid := 1;
  if TL.StartSolid > 0 then
   TL.Fraction := 0;

  if TL.Fraction <> 1 then
   begin
    if B then
     begin
      AngleVectorsTranspose(PE.Angles, @Fwd, @Right, @Up);
      V3[0] := DotProduct(TL.Plane.Normal, Fwd);
      V3[1] := DotProduct(TL.Plane.Normal, Right);
      V3[2] := DotProduct(TL.Plane.Normal, Up);
      TL.Plane.Normal := V3;
     end;

    TL.EndPos[0] := (VEnd[0] - VStart[0]) * TL.Fraction + VStart[0];
    TL.EndPos[1] := (VEnd[1] - VStart[1]) * TL.Fraction + VStart[1];
    TL.EndPos[2] := (VEnd[2] - VStart[2]) * TL.Fraction + VStart[2];
   end;

  if TL.Fraction < Trace.Fraction then
   begin
    Move(TL, Trace, SizeOf(Trace));
    Trace.Ent := I;
   end;
 end;

Result := @Trace;
end;

function PM_PlayerTrace(out Trace: TPMTrace; const VStart, VEnd: TVec3; TraceFlags, IgnorePE: Int32): PPMTrace;
begin
Result := _PM_PlayerTrace(Trace, VStart, VEnd, TraceFlags, PM.NumPhysEnt, @PM.PhysEnts, IgnorePE, nil);
end;

function PM_PlayerTraceEx(out Trace: TPMTrace; const VStart, VEnd: TVec3; TraceFlags: Int32; IgnoreFunc: TPhysEntFunc): PPMTrace;
begin
Result := _PM_PlayerTrace(Trace, VStart, VEnd, TraceFlags, PM.NumPhysEnt, @PM.PhysEnts, -1, IgnoreFunc);
end;

function PM_TraceLine(const VStart, VEnd: TVec3; Flags, UseHull, IgnorePE: Int32): PPMTrace;
var
 OldHull: Int32;
begin
OldHull := PM.UseHull;
PM.UseHull := UseHull;
if Flags <> 0 then
 _PM_PlayerTrace(GlobalTL1, VStart, VEnd, 0, PM.NumVisEnt, @PM.VisEnts, IgnorePE, nil)
else
 _PM_PlayerTrace(GlobalTL1, VStart, VEnd, 0, PM.NumPhysEnt, @PM.PhysEnts, IgnorePE, nil);

PM.UseHull := OldHull;
Result := @GlobalTL1;
end;

function PM_TraceLineEx(const VStart, VEnd: TVec3; Flags, UseHull: Int32; IgnoreFunc: TPhysEntFunc): PPMTrace;
var
 OldHull: Int32;
begin
OldHull := PM.UseHull;
PM.UseHull := UseHull;
if Flags <> 0 then
 _PM_PlayerTrace(GlobalTL2, VStart, VEnd, 0, PM.NumVisEnt, @PM.VisEnts, -1, @IgnoreFunc)
else
 PM_PlayerTraceEx(GlobalTL2, VStart, VEnd, 0, @IgnoreFunc);
 
PM.UseHull := OldHull;
Result := @GlobalTL2;
end;

function _PM_TestPlayerPosition(const Pos: TVec3; Trace: PPMTrace; IgnoreFunc: TPhysEntFunc): Int32;
var
 T: TPMTrace;
 I, J: Int;
 PE: PPhysEnt;
 Hull: PHull;
 Orig, V1, V2, Fwd, Right, Up: TVec3;
 HullNum: Int32;
begin
PM_PlayerTrace(T, PM.Origin, PM.Origin, 0, -1);
if Trace <> nil then
 Move(T, Trace^, SizeOf(Trace^));

for I := 0 to PM.NumPhysEnt - 1 do
 begin
  PE := @PM.PhysEnts[I];
  if (@IgnoreFunc <> nil) and (IgnoreFunc(PE^) <> 0) then
   Continue;

  if (PE.Model <> nil) and (PE.Solid = 0) and (PE.Skin <> 0) then
   Continue;

  Orig := PE.Origin;
  HullNum := 1;
  
  if PE.Model <> nil then
   Hull := PM_HullForBSP(PE^, Orig)
  else
   if (PE.StudioModel <> nil) and (PE.StudioModel.ModelType = ModStudio) and (((PE.StudioModel.Flags and $200) > 0) or (PM.UseHull = 2)) then
    Hull := PM_HullForStudioModel(PE.StudioModel^, Orig, PE.Frame, PE.Sequence, PE.Angles, PE.Origin, @PE.Controller, @PE.Blending, @HullNum)
   else
    begin
     VectorSubtract(PE.MinS, PlayerMaxS[PM.UseHull], V1);
     VectorSubtract(PE.MaxS, PlayerMinS[PM.UseHull], V2);
     Hull := PM_HullForBox(V1, V2);
    end;

  VectorSubtract(Pos, Orig, V1);

  if (PE.Solid = SOLID_BSP) and ((PE.Angles[0] <> 0) or (PE.Angles[1] <> 0) or (PE.Angles[2] <> 0)) then
   begin
    AngleVectors(PE.Angles, @Fwd, @Right, @Up);
    V2[0] := DotProduct(V1, Fwd);
    V2[1] := -DotProduct(V1, Right);
    V2[2] := DotProduct(V1, Up);
    V1 := V2;
   end;

  for J := 0 to HullNum - 1 do
   begin
    ContentsResult := PM_HullPointContents(Hull^, Hull.FirstClipNode, V1);
    if ContentsResult = CONTENTS_SOLID then
     begin
      Result := I;
      Exit;
     end;
    Inc(UInt(Hull), SizeOf(Hull^));
   end;
 end;

Result := -1;
end;

function PM_TestPlayerPosition(const Pos: TVec3; Trace: PPMTrace): Int32;
begin
Result := _PM_TestPlayerPosition(Pos, Trace, nil);
end;

function PM_TestPlayerPositionEx(const Pos: TVec3; Trace: PPMTrace; IgnoreFunc: TPhysEntFunc): Int32;
begin
Result := _PM_TestPlayerPosition(Pos, Trace, @IgnoreFunc);
end;

function PM_RecursiveHullCheck(const Hull: THull; Num: Int32; P1F, P2F: Single; const P1, P2: TVec3; out Trace: TPMTrace): Boolean;
const
 DIST_EPSILON = 0.03125;
var
 Node: PDClipNode;
 Plane: PMPlane;
 T1, T2, Frac, MidF: Single;
 I, Side: UInt;
 Mid: TVec3;
begin
if Num < 0 then
 begin
  if Num = CONTENTS_SOLID then
   Trace.StartSolid := 1
  else
   begin
    Trace.AllSolid := 0;
    if Num = CONTENTS_EMPTY then
     Trace.InOpen := 1
    else
     Trace.InWater := 1;
   end;

  Result := True;
 end
else
 if Hull.FirstClipNode >= Hull.LastClipNode then
  begin
   Trace.AllSolid := 0;
   Trace.InOpen := 1;                      
   Result := True;
  end
 else
  begin
   Node := @Hull.ClipNodes[Num];
   Plane := @Hull.Planes[Node.PlaneNum];

   if Plane.PlaneType >= 3 then
    begin
     T1 := DotProduct(Plane.Normal, P1) - Plane.Distance;
     T2 := DotProduct(Plane.Normal, P2) - Plane.Distance;     
    end
   else
    begin
     T1 := P1[Plane.PlaneType] - Plane.Distance;
     T2 := P2[Plane.PlaneType] - Plane.Distance;
    end;

   if (T1 >= 0) and (T2 >= 0) then
    begin
     Result := PM_RecursiveHullCheck(Hull, Node.Children[0], P1F, P2F, P1, P2, Trace);
     Exit;
    end
   else
    if (T1 < 0) and (T2 < 0) then
     begin
      Result := PM_RecursiveHullCheck(Hull, Node.Children[1], P1F, P2F, P1, P2, Trace);
      Exit;
     end;

   if T1 >= 0 then
    Frac := (T1 - DIST_EPSILON) / (T1 - T2)
   else
    Frac := (T1 + DIST_EPSILON) / (T1 - T2);

   if Frac > 1 then
    Frac := 1
   else
    if Frac < 0 then
     Frac := 0;

   MidF := (P2F - P1F) * Frac + P1F;
    
   for I := 0 to 2 do
    Mid[I] := (P2[I] - P1[I]) * Frac + P1[I];

   Side := UInt(T1 < 0);
    
   if not PM_RecursiveHullCheck(Hull, Node.Children[Side], P1F, MidF, P1, Mid, Trace) then
    Result := False
   else
    if PM_HullPointContents(Hull, Node.Children[Side xor 1], Mid) <> CONTENTS_SOLID then
     Result := PM_RecursiveHullCheck(Hull, Node.Children[Side xor 1], MidF, P2F, Mid, P2, Trace)
    else
     if Trace.AllSolid <> 0 then
      Result := False
     else
      begin
       if Side > 0 then
        begin
         VectorSubtract(Vec3Origin, Plane.Normal, Trace.Plane.Normal); // chs?
         Trace.Plane.Distance := -Plane.Distance;
        end
       else
        begin
         VectorCopy(Plane.Normal, Trace.Plane.Normal);
         Trace.Plane.Distance := Plane.Distance;
        end;

       while PM_HullPointContents(Hull, Hull.FirstClipNode, Mid) = CONTENTS_SOLID do
        begin
         Frac := Frac - 0.05;
         if Frac < 0 then
          begin
           Trace.Fraction := MidF;
           Trace.EndPos := Mid;
           Result := False;
           Exit;
          end;

         MidF := (P2F - P1F) * Frac + P1F;
         for I := 0 to 2 do
          Mid[I] := (P2[I] - P1[I]) * Frac + P1[I];
        end;
        
       Trace.Fraction := MidF;
       Trace.EndPos := Mid;
       Result := False;
      end;
  end;
end;

function memfgets(MemFile: Pointer; Size: Int32; var FilePos: Int32; Buffer: PLChar; BufferSize: Int32): PLChar;
var
 I: Int32;
begin
Result := nil;

if (MemFile <> nil) and (Buffer <> nil) and (FilePos < BufferSize) then
 begin
  I := FilePos;
  if Size - I > BufferSize - 1 then
   Size := I + BufferSize - 1;

  while (I < Size) do
   if PLChar(UInt(MemFile) + UInt(I))^ = #$A then
    begin
     Inc(I);
     Break;                     
    end
   else
    Inc(I);

   if I <> FilePos then
    begin
     Move(Pointer(UInt(MemFile) + UInt(FilePos))^, Buffer^, I - FilePos);
     if I - FilePos < BufferSize then
      PLChar(UInt(Buffer) + UInt(I - FilePos))^ := #0;
     FilePos := I;
     Result := Buffer;
    end;
 end;
end;

function __PM_Info_ValueForKey(S, Key: PLChar): PLChar; cdecl;
begin Result := Info_ValueForKey(S, Key); end;

procedure __PM_Particle(var Origin: TVec3; Color: Int32; Life: Single; ZPos, ZVel: Int32); cdecl;
begin end;
                                     
function __PM_TestPlayerPosition(var Pos: TVec3; Trace: PPMTrace): Int32; cdecl;
begin Result := PM_TestPlayerPosition(Pos, Trace); end;

procedure __Con_NPrintF(ID: Int32; S: PLChar); cdecl; // for now, just print the contents
begin end;

procedure __Con_DPrintF(S: PLChar); cdecl;
begin DPrint(S); end;

procedure __Con_PrintF(S: PLChar); cdecl;
begin Print(S); end;

function __Sys_FloatTime: Double; cdecl;
begin Result := Sys_FloatTime; end;

procedure __PM_StuckTouch(HitEnt: Int32; var TraceResult: TPMTrace); cdecl;
begin PM_StuckTouch(HitEnt, TraceResult); end;

function __PM_PointContents(var P: TVec3; TrueContents: PInt32): Int32; cdecl;
begin Result := PM_PointContents(P, TrueContents); end;

function __PM_TruePointContents(var P: TVec3): Int32; cdecl;
begin Result := PM_TruePointContents(P); end;

function __PM_HullPointContents(var Hull: THull; Num: Int32; var P: TVec3): Int32; cdecl;
begin Result := PM_HullPointContents(Hull, Num, P); end;

function __PM_PlayerTrace(out Trace: TPMTrace; var VStart, VEnd: TVec3; TraceFlags, IgnorePE: Int32): PPMTrace; cdecl;
begin Result := PM_PlayerTrace(Trace, VStart, VEnd, TraceFlags, IgnorePE); end;

function __PM_TraceLine(var VStart, VEnd: TVec3; Flags, UseHull, IgnorePE: Int32): PPMTrace; cdecl;
begin Result := PM_TraceLine(VStart, VEnd, Flags, UseHull, IgnorePE); end;

function __RandomLong(Low, High: Int32): Int32; cdecl;
begin Result := RandomLong(Low, High); end;

function __RandomFloat(Low, High: Single): Single; cdecl;
begin Result := RandomFloat(Low, High); end;

function __PM_GetModelType(var Model: TModel): TModelType; cdecl;
begin Result := PM_GetModelType(Model); end;

procedure __PM_GetModelBounds(var Model: TModel; out MinS, MaxS: TVec3); cdecl;
begin PM_GetModelBounds(Model, MinS, MaxS); end;

function __PM_HullForBSP(var E: TPhysEnt; out Offset: TVec3): PHull; cdecl;
begin Result := PM_HullForBSP(E, Offset); end;

function __PM_TraceModel(var E: TPhysEnt; var VStart, VEnd: TVec3; var T: TTrace): Single; cdecl;
begin Result := PM_TraceModel(E, VStart, VEnd, T); end;

function __COM_FileSize(Name: PLChar): Int32; cdecl;
begin Result := COM_FileSize(Name); end;

function __COM_LoadFile(Name: PLChar; AllocType: Int32; Length: PUInt32): Pointer; cdecl;
begin Result := COM_LoadFile(Name, TFileAllocType(AllocType), Length); end;

procedure __COM_FreeFile(Buffer: Pointer); cdecl;
begin COM_FreeFile(Buffer); end;

function __memfgets(MemFile: Pointer; Size: Int32; var FilePos: Int32; Buffer: PLChar; BufferSize: Int32): PLChar; cdecl;
begin Result := memfgets(MemFile, Size, FilePos, Buffer, BufferSize); end;

procedure __PM_PlaySound(Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
begin PM_SV_PlaySound(Channel, Sample, Volume, Attn, Flags, Pitch); end;

function __PM_TraceTexture(Ground: Int32; var VStart, VEnd: TVec3): PLChar; cdecl;
begin Result := PM_SV_TraceTexture(Ground, VStart, VEnd); end;

procedure __PM_PlaybackEventFull(Flags, ClientIndex: Int32; EventIndex: UInt16; Delay: Single; var Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;
begin PM_SV_PlaybackEventFull(Flags, ClientIndex, EventIndex, Delay, Origin, Angles, FParam1, FParam2, IParam1, IParam2, BParam1, BParam2); end;

function __PM_PlayerTraceEx(out Trace: TPMTrace; var VStart, VEnd: TVec3; TraceFlags: Int32; IgnoreFunc: TPhysEntFunc): PPMTrace; cdecl;
begin Result := PM_PlayerTraceEx(Trace, VStart, VEnd, TraceFlags, IgnoreFunc); end;

function __PM_TestPlayerPositionEx(var Pos: TVec3; Trace: PPMTrace; IgnoreFunc: TPhysEntFunc): Int32; cdecl;
begin Result := PM_TestPlayerPositionEx(Pos, Trace, IgnoreFunc); end;

function __PM_TraceLineEx(var VStart, VEnd: TVec3; Flags, UseHull: Int32; IgnoreFunc: TPhysEntFunc): PPMTrace; cdecl;
begin Result := PM_TraceLineEx(VStart, VEnd, Flags, UseHull, IgnoreFunc); end;

procedure PM_Init(P: PPlayerMove);
var
 I: UInt;
begin
PM_InitBoxHull;

for I := Low(P.PlayerMinS) to High(P.PlayerMinS) do
 begin
  P.PlayerMinS[I] := PlayerMinS[I];
  P.PlayerMaxS[I] := PlayerMaxS[I];
 end;

P.MoveVars := @Server.MoveVars;
P.PM_Info_ValueForKey := @__PM_Info_ValueForKey;
P.PM_Particle := @__PM_Particle;
P.PM_TestPlayerPosition := @__PM_TestPlayerPosition;

P.Con_NPrintF := @__Con_NPrintF;
P.Con_DPrintF := @__Con_DPrintF;
P.Con_PrintF := @__Con_PrintF;
P.Sys_FloatTime := @__Sys_FloatTime;

P.PM_StuckTouch := @__PM_StuckTouch;
P.PM_PointContents := @__PM_PointContents;
P.PM_TruePointContents := @__PM_TruePointContents;
P.PM_HullPointContents := @__PM_HullPointContents;

P.PM_PlayerTrace := @__PM_PlayerTrace;
P.PM_TraceLine := @__PM_TraceLine;
P.RandomLong := @__RandomLong;
P.RandomFloat := @__RandomFloat;

P.PM_GetModelType := @__PM_GetModelType;
P.PM_GetModelBounds := @__PM_GetModelBounds;
P.PM_HullForBSP := @__PM_HullForBSP;
P.PM_TraceModel := @__PM_TraceModel;

P.COM_FileSize := @__COM_FileSize;
P.COM_LoadFile := @__COM_LoadFile;
P.COM_FreeFile := @__COM_FreeFile;

P.memfgets := @__memfgets;
P.RunFuncs := 0;

P.PM_PlaySound := @__PM_PlaySound;
P.PM_TraceTexture := @__PM_TraceTexture;
P.PM_PlaybackEventFull := @__PM_PlaybackEventFull;
P.PM_PlayerTraceEx := @__PM_PlayerTraceEx;
P.PM_TestPlayerPositionEx := @__PM_TestPlayerPositionEx;
P.PM_TraceLineEx := @__PM_TraceLineEx;
end;

end.
