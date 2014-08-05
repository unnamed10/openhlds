unit SVWorld;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SV_ClearWorld;
procedure SV_UnlinkEdict(var E: TEdict);

function SV_HullForBSP(const E: TEdict; const MinS, MaxS: TVec3; out VOut: TVec3): PHull;
function SV_HullForEntity(const E: TEdict; const MinS, MaxS: TVec3; out VOut: TVec3): PHull;

function SV_PointContents(const P: TVec3): Int;

procedure SV_LinkEdict(var E: TEdict; TouchTriggers: Boolean);
function SV_RecursiveHullCheck(const Hull: THull; Num: Int32; P1F, P2F: Single; const P1, P2: TVec3; out Trace: TTrace): Boolean;

function SV_Move(out Trace: TTrace; const VStart, MinS, MaxS, VEnd: TVec3; MoveType: Int; PassEdict: PEdict; MonsterClip: Boolean): PTrace;
function SV_MoveNoEnts(out Trace: TTrace; const VStart, MinS, MaxS, VEnd: TVec3; MoveType: Int; PassEdict: PEdict): PTrace;
function SV_TestEntityPosition(const E: TEdict): PEdict;

function SV_ClipMoveToEntity(out Trace: TTrace; const E: TEdict; const VStart, MinS, MaxS, VEnd: TVec3): PTrace;

type
 TGroupOp = (GROUP_OP_AND = 0, GROUP_OP_NAND);

var
 GroupOp: TGroupOp = GROUP_OP_AND;
 GroupMask: UInt32 = 0;

 SVAreaNodes: array[0..AREA_NODES - 1] of TAreaNode;
 SVNumAreaNodes: UInt = 0;

implementation

uses Common, Console, GameLib, Host, MathLib, Renderer, Server, SysMain, SVMove;

var
 TouchLinkSemaphore: Boolean = False;

 BoxHull: THull;
 BoxClipNodes: array[0..5] of TDClipNode;
 BoxPlanes: array[0..5] of TMPlane;

procedure SV_InitBoxHull;
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

function SV_HullForBox(const MinS, MaxS: TVec3): PHull;
begin
BoxPlanes[0].Distance := MaxS[0];
BoxPlanes[1].Distance := MinS[0];
BoxPlanes[2].Distance := MaxS[1];
BoxPlanes[3].Distance := MinS[1];
BoxPlanes[4].Distance := MaxS[2];
BoxPlanes[5].Distance := MinS[2];

Result := @BoxHull;
end;

function SV_HullForBSP(const E: TEdict; const MinS, MaxS: TVec3; out VOut: TVec3): PHull;
var
 M: PModel;
 P: Single;
begin
M := SV.PrecachedModels[E.V.ModelIndex];
if (M = nil) or (M.ModelType <> ModBrush) then
 Sys_Error(['Hit a "', PLChar(PRStrings + E.V.ClassName), '" with no model (', PLChar(PRStrings + E.V.Model), ').']);

P := MaxS[0] - MinS[0];
if P > 8 then
 begin
  if P > 36 then
   Result := @M.Hulls[2]
  else
   if MaxS[2] - MinS[2] > 36 then
    Result := @M.Hulls[1]
   else
    Result := @M.Hulls[3];

  VectorSubtract(Result.ClipMinS, MinS, VOut);
 end
else
 begin
  Result := @M.Hulls[0];
  VOut := Result.ClipMinS;
 end;

VectorAdd(VOut, E.V.Origin, VOut);
end;

function SV_HullForEntity(const E: TEdict; const MinS, MaxS: TVec3; out VOut: TVec3): PHull;
var
 HullMinS, HullMaxS: TVec3;
begin
if E.V.Solid = SOLID_BSP then
 begin
  if (E.V.MoveType <> MOVETYPE_PUSH) and (E.V.MoveType <> MOVETYPE_PUSHSTEP) then
   Sys_Error('SV_HullForEntity: SOLID_BSP without MOVETYPE_PUSH/PUSHSTEP.');

  Result := SV_HullForBSP(E, MinS, MaxS, VOut);
 end
else
 begin
  VectorSubtract(E.V.MinS, MaxS, HullMinS);
  VectorSubtract(E.V.MaxS, MinS, HullMaxS);
  Result := SV_HullForBox(HullMinS, HullMaxS);
  VOut := E.V.Origin; 
 end;
end;

function SV_CreateAreaNode(Depth: Int; const MinS, MaxS: TVec3): PAreaNode;
var
 P: PAreaNode;
 Size, MinS1, MinS2, MaxS1, MaxS2: TVec3;
begin
P := @SVAreaNodes[SVNumAreaNodes];
Inc(SVNumAreaNodes);
ClearLink(P.TriggerEdicts);
ClearLink(P.SolidEdicts);

if Depth = AREA_DEPTH then
 begin
  P.Axis := -1;
  P.Children[0] := nil;
  P.Children[1] := nil;
 end
else
 begin
  VectorSubtract(MaxS, MinS, Size);
  P.Axis := UInt(Size[0] <= Size[1]);
  P.Distance := (MinS[P.Axis] + MaxS[P.Axis]) * 0.5;

  MinS1 := MinS;
  MinS2 := MinS;
  MaxS1 := MaxS;
  MaxS2 := MaxS;
  MinS2[P.Axis] := P.Distance;
  MaxS1[P.Axis] := P.Distance;

  P.Children[0] := SV_CreateAreaNode(Depth + 1, MinS2, MaxS2);
  P.Children[1] := SV_CreateAreaNode(Depth + 1, MinS1, MaxS1);
 end;

Result := P;
end;

function SV_HullPointContents(const Hull: THull; Num: Int32; const P: TVec3): Int;
var
 Node: PDClipNode;
 Plane: PMPlane;
 D: Single;
begin
while Num >= 0 do
 begin
  if (Num < Hull.FirstClipNode) or (Num > Hull.LastClipNode) then
   Sys_Error('SV_HullPointContents: Bad node number.');

  Node := @Hull.ClipNodes[Num];
  Plane := @Hull.Planes[Node.PlaneNum];

  if Plane.PlaneType < 3 then
   D := P[Plane.PlaneType] - Plane.Distance
  else
   D := DotProduct(Plane.Normal, P) - Plane.Distance;

  if D >= 0 then
   Num := Node.Children[0]
  else
   Num := Node.Children[1];
 end;

Result := Num;
end;

procedure SV_ClearWorld;
begin
SV_InitBoxHull;
MemSet(SVAreaNodes, SizeOf(SVAreaNodes), 0);
SVNumAreaNodes := 0;
SV_CreateAreaNode(0, SV.WorldModel.MinS, SV.WorldModel.MaxS);
end;

procedure SV_UnlinkEdict(var E: TEdict);
begin
if E.Area.Prev <> nil then
 begin
  RemoveLink(E.Area);
  E.Area.Prev := nil;
  E.Area.Next := nil;
 end;
end;

procedure SV_TouchLinks(var E: TEdict; const Node: TAreaNode);
var
 L: PLink;
 Touch: PEdict;
 P: PModel;
 Hull: PHull;
 V: TVec3;
begin
L := Node.TriggerEdicts.Next;
while UInt(L) <> UInt(@Node.TriggerEdicts) do
 begin
  Touch := EdictFromArea(L^);
  L := L.Next;

  if Touch = @E then
   Continue;

  if FilterGroup(Touch^, E) then
   Continue;

  if Touch.V.Solid <> SOLID_TRIGGER then
   Continue;

  if (E.V.AbsMin[0] > Touch.V.AbsMax[0]) or
     (E.V.AbsMin[1] > Touch.V.AbsMax[1]) or
     (E.V.AbsMin[2] > Touch.V.AbsMax[2]) or
     (E.V.AbsMax[0] < Touch.V.AbsMin[0]) or
     (E.V.AbsMax[1] < Touch.V.AbsMin[1]) or
     (E.V.AbsMax[2] < Touch.V.AbsMin[2]) then
   Continue;

  P := SV.PrecachedModels[Touch.V.ModelIndex];
  if (P <> nil) and (P.ModelType = ModBrush) then
   begin
    Hull := SV_HullForBSP(Touch^, E.V.MinS, E.V.MaxS, V);
    VectorSubtract(E.V.Origin, V, V);
    if SV_HullPointContents(Hull^, Hull.FirstClipNode, V) <> CONTENTS_SOLID then
     Continue;
   end;

  GlobalVars.Time := SV.Time;
  DLLFunctions.Touch(Touch^, E);
 end;

if Node.Axis <> -1 then
 begin
  if E.V.AbsMax[Node.Axis] > Node.Distance then
   SV_TouchLinks(E, Node.Children[0]^);
  if E.V.AbsMin[Node.Axis] < Node.Distance then
   SV_TouchLinks(E, Node.Children[1]^);
 end;
end;

procedure SV_FindTouchedLeafs(var E: TEdict; const Node: TMNode; var LeafNum: Int32);
var
 Sides: Int;
begin
if Node.Contents <> CONTENTS_SOLID then
 if Node.Contents < 0 then
  begin
   if E.NumLeafs < MAX_ENT_LEAFS then
    begin
     E.LeafNums[E.NumLeafs] := (UInt(@Node) - UInt(SV.WorldModel.Leafs)) div SizeOf(TMLeaf) - 1;
     Inc(E.NumLeafs);
    end
   else
    E.NumLeafs := MAX_ENT_LEAFS + 1;
  end
 else
  begin
   if Node.Plane.PlaneType > 2 then
    Sides := BoxOnPlaneSide(E.V.AbsMin, E.V.AbsMax, Node.Plane)
   else
    if Node.Plane.Distance <= E.V.AbsMin[Node.Plane.PlaneType] then
     Sides := 1
    else
     if Node.Plane.Distance >= E.V.AbsMax[Node.Plane.PlaneType] then
      Sides := 2
     else
      Sides := 3;

   if (Sides = 3) and (LeafNum = -1) then
    LeafNum := (UInt(@Node) - UInt(SV.WorldModel.Nodes)) div SizeOf(TMNode);

   if (Sides and 1) > 0 then
    SV_FindTouchedLeafs(E, Node.Children[0]^, LeafNum);
   if (Sides and 2) > 0 then
    SV_FindTouchedLeafs(E, Node.Children[1]^, LeafNum);
  end;
end;

procedure SV_LinkEdict(var E: TEdict; TouchTriggers: Boolean);
var
 LeafNum: Int32;
 P: PAreaNode;
begin
if E.Area.Prev <> nil then
 SV_UnlinkEdict(E);

if (@E <> SV.Edicts) and (E.Free = 0) then
 begin
  DLLFunctions.SetAbsBox(E);
  if (E.V.MoveType = MOVETYPE_FOLLOW) and (E.V.AimEnt <> nil) then
   begin
    E.HeadNode := E.V.AimEnt.HeadNode;
    E.NumLeafs := E.V.AimEnt.NumLeafs;
    Move(E.V.AimEnt.LeafNums, E.LeafNums, SizeOf(E.LeafNums));
   end
  else
   begin
    E.NumLeafs := 0;
    E.HeadNode := -1;
    LeafNum := -1;
    if E.V.ModelIndex <> 0 then
     SV_FindTouchedLeafs(E, PMNode(SV.WorldModel.Nodes)^, LeafNum);

    if E.NumLeafs > MAX_ENT_LEAFS then
     begin
      E.HeadNode := LeafNum;
      E.NumLeafs := 0;
      MemSet(E.LeafNums, SizeOf(E.LeafNums), $FF);
     end;
   end;

  if (E.V.Solid <> SOLID_NOT) or (E.V.Skin < -1) then
   if (E.V.Solid = SOLID_BSP) and (SV.PrecachedModels[E.V.ModelIndex] = nil) and (PLChar(PRStrings + E.V.Model)^ = #0) then
    DPrint(['Inserted "', PLChar(PRStrings + E.V.ClassName), '" with no model.'])
   else
    begin
     P := @SVAreaNodes[0];
     while P.Axis <> -1 do
      if E.V.AbsMin[P.Axis] > P.Distance then
       P := P.Children[0]
      else
       if E.V.AbsMax[P.Axis] < P.Distance then
        P := P.Children[1]
       else
        Break;

     if E.V.Solid = SOLID_TRIGGER then
      InsertLinkBefore(E.Area, P.TriggerEdicts)
     else
      InsertLinkBefore(E.Area, P.SolidEdicts);

     if TouchTriggers and not TouchLinkSemaphore then
      begin
       TouchLinkSemaphore := True;
       SV_TouchLinks(E, SVAreaNodes[0]);
       TouchLinkSemaphore := False;
      end;
    end;
 end;
end;

function SV_LinkContents(const Node: TAreaNode; const P: TVec3): Int;
var
 L: PLink;
 E: PEdict;
 M: PModel;
 Hull: PHull;
 V: TVec3;
begin
L := Node.SolidEdicts.Next;
while UInt(L) <> UInt(@Node.SolidEdicts) do
 begin
  E := EdictFromArea(L^);
  L := L.Next;

  if E.V.Solid <> SOLID_NOT then
   Continue;

  if (E.V.GroupInfo <> 0) and
     (((GroupOp = GROUP_OP_AND) and ((E.V.GroupInfo and GroupMask) = 0)) or
      ((GroupOp = GROUP_OP_NAND) and ((E.V.GroupInfo and GroupMask) > 0))) then
   Continue;

  M := SV.PrecachedModels[E.V.ModelIndex];
  if (M <> nil) and (M.ModelType = ModBrush) and
     (P[0] <= E.V.AbsMax[0]) and
     (P[1] <= E.V.AbsMax[1]) and
     (P[2] <= E.V.AbsMax[2]) and
     (P[0] >= E.V.AbsMin[0]) and
     (P[1] >= E.V.AbsMin[1]) and
     (P[2] >= E.V.AbsMin[2]) then
   begin
    if (E.V.Skin < -100) or (E.V.Skin > 100) then
     DPrint(['Invalid contents on trigger field: ', PLChar(PRStrings + E.V.ClassName), '.']);

    Hull := SV_HullForBSP(E^, Vec3Origin, Vec3Origin, V);
    VectorSubtract(P, V, V);
    if SV_HullPointContents(Hull^, Hull.FirstClipNode, V) <> CONTENTS_EMPTY then
     begin
      Result := E.V.Skin;
      Exit;
     end;
   end;
 end;

if (Node.Axis = -1) or (P[Node.Axis] = Node.Distance) then
 Result := -1
else
 if P[Node.Axis] > Node.Distance then
  Result := SV_LinkContents(Node.Children[0]^, P)
 else
  Result := SV_LinkContents(Node.Children[1]^, P);
end;

function SV_PointContents(const P: TVec3): Int;
var
 I: Int;
begin
I := SV_HullPointContents(SV.WorldModel.Hulls[0], 0, P);
if I <> CONTENTS_SOLID then
 begin
  if (I <= CONTENTS_CURRENT_0) and (I >= CONTENTS_CURRENT_DOWN) then
   I := CONTENTS_WATER;

  Result := SV_LinkContents(SVAreaNodes[0], P);
  if Result = CONTENTS_EMPTY then
   Result := I;
 end
else
 Result := I;
end;

function SV_TestEntityPosition(const E: TEdict): PEdict;
var
 Trace: TTrace;
begin
SV_Move(Trace, E.V.Origin, E.V.MinS, E.V.MaxS, E.V.Origin, MOVE_NORMAL, @E, (E.V.Flags and FL_MONSTERCLIP) > 0);
if Trace.StartSolid <> 0 then
 begin
  SV_SetGlobalTrace(Trace);
  Result := Trace.Ent;
 end
else
 Result := nil;
end;

function SV_RecursiveHullCheck(const Hull: THull; Num: Int32; P1F, P2F: Single; const P1, P2: TVec3; out Trace: TTrace): Boolean;
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
     if Num <> CONTENTS_TRANSLUCENT then
      Trace.InWater := 1;
   end;
  Result := True;
 end
else
 begin
  if (Num < Hull.FirstClipNode) or (Num > Hull.LastClipNode) or (Hull.Planes = nil) then
   Sys_Error('SV_RecursiveHullCheck: Bad node number.');

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
    Result := SV_RecursiveHullCheck(Hull, Node.Children[0], P1F, P2F, P1, P2, Trace);
    Exit;
   end
  else
   if (T1 < 0) and (T2 < 0) then
    begin
     Result := SV_RecursiveHullCheck(Hull, Node.Children[1], P1F, P2F, P1, P2, Trace);
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

  if not SV_RecursiveHullCheck(Hull, Node.Children[Side], P1F, MidF, P1, Mid, Trace) then
   Result := False
  else
   if SV_HullPointContents(Hull, Node.Children[Side xor 1], Mid) <> CONTENTS_SOLID then
    Result := SV_RecursiveHullCheck(Hull, Node.Children[Side xor 1], MidF, P2F, Mid, P2, Trace)
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

      while SV_HullPointContents(Hull, Hull.FirstClipNode, Mid) = CONTENTS_SOLID do
       begin
        Frac := Frac - 0.1;
        if Frac < 0 then
         begin
          Trace.Fraction := MidF;
          Trace.EndPos := Mid;
          DPrint('Backup past 0.');
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

procedure SV_SingleClipMoveToEntity(const E: TEdict; const VStart, MinS, MaxS, VEnd: TVec3; out Trace: TTrace);
var
 P: PModel;
 Hull: PHull;
 VOut, StartL, EndL, Fwd, Right, Up, V1, V2: TVec3;
 HullNum: Int32;
 B, B2: Boolean;
 I: Int;
 T: TTrace;
 LastHull: UInt;
begin
MemSet(Trace, SizeOf(Trace), 0);
Trace.Fraction := 1;
Trace.AllSolid := 1;
Trace.EndPos := VEnd;

P := SV.PrecachedModels[E.V.ModelIndex];
if P = nil then
 begin
  Sys_Error(['SV_SingleClipMoveToEntity: No model for "', PLChar(PRStrings + E.V.ClassName), '".']);
  Exit;
 end
else
 if P.ModelType = ModStudio then
  Hull := SV_HullForStudioModel(E, MinS, MaxS, VOut, HullNum)
 else
  begin
   Hull := SV_HullForEntity(E, MinS, MaxS, VOut);
   HullNum := 1;
  end;

VectorSubtract(VStart, VOut, StartL);
VectorSubtract(VEnd, VOut, EndL);
if (E.V.Solid <> SOLID_BSP) or ((E.V.Angles[0] = 0) and (E.V.Angles[1] = 0) and (E.V.Angles[2] = 0)) then
 B := False
else
 begin
  B := True;
  AngleVectors(E.V.Angles, @Fwd, @Right, @Up);
  V1[0] := DotProduct(StartL, Fwd);
  V1[1] := -DotProduct(StartL, Right);
  V1[2] := DotProduct(StartL, Up);
  V2[0] := DotProduct(EndL, Fwd);
  V2[1] := -DotProduct(EndL, Right);
  V2[2] := DotProduct(EndL, Up);
  StartL := V1;
  EndL := V2;
 end;

if HullNum = 1 then
 SV_RecursiveHullCheck(Hull^, Hull.FirstClipNode, 0, 1, StartL, EndL, Trace)
else
 begin
  LastHull := 0;
  for I := 0 to HullNum - 1 do
   begin
    MemSet(T, SizeOf(T), 0);
    T.Fraction := 1;    
    T.AllSolid := 1;
    T.EndPos := VEnd;
    SV_RecursiveHullCheck(Hull^, Hull.FirstClipNode, 0, 1, StartL, EndL, T);
    if (I = 0) or (T.AllSolid > 0) or (T.StartSolid > 0) or (T.Fraction < Trace.Fraction) then
     begin
      B2 := Trace.StartSolid <> 0;
      Move(T, Trace, SizeOf(Trace));
      if B2 then
       Trace.StartSolid := 1;
      LastHull := I;
     end;
    Inc(UInt(Hull), SizeOf(Hull^));
   end;
  Trace.HitGroup := SV_HitgroupForStudioHull(LastHull);
 end;

if Trace.Fraction <> 1 then
 begin
  if B then
   begin
    AngleVectorsTranspose(E.V.Angles, @Fwd, @Right, @Up);
    V1[0] := DotProduct(Trace.Plane.Normal, Fwd);
    V1[1] := DotProduct(Trace.Plane.Normal, Right);
    V1[2] := DotProduct(Trace.Plane.Normal, Up); // is this way
    Trace.Plane.Normal := V1;
   end;

  Trace.EndPos[0] := (VEnd[0] - VStart[0]) * Trace.Fraction + VStart[0];
  Trace.EndPos[1] := (VEnd[1] - VStart[1]) * Trace.Fraction + VStart[1];
  Trace.EndPos[2] := (VEnd[2] - VStart[2]) * Trace.Fraction + VStart[2];
 end;

if (Trace.Fraction < 1) or (Trace.StartSolid <> 0) then
 Trace.Ent := @E;
end;

function SV_ClipMoveToEntity(out Trace: TTrace; const E: TEdict; const VStart, MinS, MaxS, VEnd: TVec3): PTrace;
begin
SV_SingleClipMoveToEntity(E, VStart, MinS, MaxS, VEnd, Trace);
Result := @Trace;
end;

procedure SV_ClipToLinks(const Node: TAreaNode; var Clip: TMoveClip);
var
 L: PLink;
 E: PEdict;
 Trace: TTrace;
 B: Boolean;
begin
L := Node.SolidEdicts.Next;
while UInt(L) <> UInt(@Node.SolidEdicts) do
 begin
  E := EdictFromArea(L^);
  L := L.Next;

  if (Clip.PassEdict <> nil) and FilterGroup(E.V.GroupInfo, Clip.PassEdict.V.GroupInfo) then
   Continue;

  if (E.V.Solid = SOLID_NOT) or (Clip.PassEdict = E) then
   Continue;

  if E.V.Solid = SOLID_TRIGGER then
   Sys_Error('SV_ClipToLinks: Trigger in clipping list.');

  if (@NewDLLFunctions.ShouldCollide <> nil) and (NewDLLFunctions.ShouldCollide(E^, Clip.PassEdict^) = 0) then
   Exit; // maybe "continue" would be better

  if ((E.V.Solid = SOLID_BSP) and ((E.V.Flags and FL_MONSTERCLIP) > 0) and (Clip.HullNum = 0)) or
     ((E.V.Solid <> SOLID_BSP) and (Clip.I1 = 1) and (E.V.MoveType <> MOVETYPE_PUSHSTEP)) then
   Continue;

  if (Clip.I2 <> 0) and (E.V.RenderMode <> 0) and ((E.V.Flags and FL_WORLDBRUSH) = 0) then
   Continue;

  if (Clip.BoxMinS[0] > E.V.AbsMax[0]) or
     (Clip.BoxMinS[1] > E.V.AbsMax[1]) or
     (Clip.BoxMinS[2] > E.V.AbsMax[2]) or
     (Clip.BoxMaxS[0] < E.V.AbsMin[0]) or
     (Clip.BoxMaxS[1] < E.V.AbsMin[1]) or
     (Clip.BoxMaxS[2] < E.V.AbsMin[2]) then
   Continue;

  if (E.V.Solid <> SOLID_SLIDEBOX) and not SV_CheckSphereIntersection(E^, Clip.VStart^, Clip.VEnd^) then
   Continue;

  if (Clip.PassEdict <> nil) and (Clip.PassEdict.V.Size[0] <> 0) and (E.V.Size[0] = 0) then
   Continue;

  if Clip.Trace.AllSolid <> 0 then
   Exit;

  if (Clip.PassEdict <> nil) and ((E.V.Owner = Clip.PassEdict) or (Clip.PassEdict.V.Owner = E)) then
   Continue;

  if (E.V.Flags and FL_MONSTER) > 0 then
   SV_ClipMoveToEntity(Trace, E^, Clip.VStart^, Clip.MinS2, Clip.MaxS2, Clip.VEnd^)
  else
   SV_ClipMoveToEntity(Trace, E^, Clip.VStart^, Clip.MinS^, Clip.MaxS^, Clip.VEnd^);

  if (Trace.AllSolid <> 0) or (Trace.StartSolid <> 0) or (Trace.Fraction < Clip.Trace.Fraction) then
   begin
    B := Clip.Trace.StartSolid <> 0;
    Trace.Ent := E;
    Move(Trace, Clip.Trace, SizeOf(Clip.Trace));
    if B then
     Clip.Trace.StartSolid := 1;
   end;
 end;

if Node.Axis <> -1 then
 begin
  if Clip.BoxMaxS[Node.Axis] > Node.Distance then
   SV_ClipToLinks(Node.Children[0]^, Clip);
  if Clip.BoxMinS[Node.Axis] < Node.Distance then
   SV_ClipToLinks(Node.Children[1]^, Clip);
 end;
end;

procedure SV_ClipToWorldBrush(const Node: TAreaNode; var Clip: TMoveClip);
var
 L: PLink;
 E: PEdict;
 Trace: TTrace;
 B: Boolean;
begin
L := Node.SolidEdicts.Next;
while UInt(L) <> UInt(@Node.SolidEdicts) do
 begin
  E := EdictFromArea(L^);
  L := L.Next;

  if (E.V.Solid <> SOLID_BSP) or (Clip.PassEdict = E) or ((E.V.Flags and FL_WORLDBRUSH) = 0) then
   Continue;

  if (Clip.BoxMinS[0] > E.V.AbsMax[0]) or
     (Clip.BoxMinS[1] > E.V.AbsMax[1]) or
     (Clip.BoxMinS[2] > E.V.AbsMax[2]) or
     (Clip.BoxMaxS[0] < E.V.AbsMin[0]) or
     (Clip.BoxMaxS[1] < E.V.AbsMin[1]) or
     (Clip.BoxMaxS[2] < E.V.AbsMin[2]) then
   Continue;

  if Clip.Trace.AllSolid <> 0 then
   Exit;

  SV_ClipMoveToEntity(Trace, E^, Clip.VStart^, Clip.MinS^, Clip.MaxS^, Clip.VEnd^);

  if (Trace.AllSolid <> 0) or (Trace.StartSolid <> 0) or (Trace.Fraction < Clip.Trace.Fraction) then
   begin
    B := Clip.Trace.StartSolid <> 0;
    Trace.Ent := E;
    Move(Trace, Clip.Trace, SizeOf(Clip.Trace));
    if B then
     Clip.Trace.StartSolid := 1;
   end;
 end;

if Node.Axis <> -1 then
 begin
  if Clip.BoxMaxS[Node.Axis] > Node.Distance then
   SV_ClipToWorldBrush(Node.Children[0]^, Clip);
  if Clip.BoxMinS[Node.Axis] < Node.Distance then
   SV_ClipToWorldBrush(Node.Children[1]^, Clip);
 end;
end;

procedure SV_MoveBounds(const VStart, MinS, MaxS, VEnd: TVec3; out BoxMinS, BoxMaxS: TVec3);
var
 I: UInt;
begin
for I := 0 to 2 do
 if VEnd[I] > VStart[I] then
  begin
   BoxMinS[I] := VStart[I] + MinS[I] - 1;
   BoxMaxS[I] := VEnd[I] + MaxS[I] + 1;
  end
 else
  begin
   BoxMinS[I] := VEnd[I] + MinS[I] - 1;
   BoxMaxS[I] := VStart[I] + MaxS[I] + 1;
  end;
end;

function SV_MoveNoEnts(out Trace: TTrace; const VStart, MinS, MaxS, VEnd: TVec3; MoveType: Int; PassEdict: PEdict): PTrace;
var
 Clip: TMoveClip;
 ClipEnd: TVec3;
 F: Single;
begin
MemSet(Clip, SizeOf(Clip), 0);
SV_ClipMoveToEntity(Clip.Trace, SV.Edicts[0], VStart, MinS, MaxS, VEnd);
if Clip.Trace.Fraction <> 0 then
 begin
  ClipEnd := Clip.Trace.EndPos;
  F := Clip.Trace.Fraction;
  Clip.Trace.Fraction := 1;

  Clip.VEnd := @ClipEnd;
  Clip.VStart := @VStart;
  Clip.MinS := @MinS;
  Clip.MaxS := @MaxS;
  Clip.MinS2 := MinS;
  Clip.MaxS2 := MaxS;  
  Clip.PassEdict := PassEdict;
  Clip.HullNum := 0;
  Clip.I1 := MoveType and $FF;
  Clip.I2 := MoveType shr 8;

  SV_MoveBounds(VStart, Clip.MinS2, Clip.MaxS2, ClipEnd, Clip.BoxMinS, Clip.BoxMaxS);
  SV_ClipToWorldBrush(SVAreaNodes[0], Clip);
  GlobalVars.TraceEnt := Clip.Trace.Ent;
  Clip.Trace.Fraction := Clip.Trace.Fraction * F;
 end;

Trace := Clip.Trace;
Result := @Trace;
end;

function SV_Move(out Trace: TTrace; const VStart, MinS, MaxS, VEnd: TVec3; MoveType: Int; PassEdict: PEdict; MonsterClip: Boolean): PTrace;
var
 Clip: TMoveClip;
 ClipEnd: TVec3;
 OldFraction: Single;
 I: UInt;
begin
MemSet(Clip, SizeOf(Clip), 0);
SV_ClipMoveToEntity(Clip.Trace, SV.Edicts[0], VStart, MinS, MaxS, VEnd);
if Clip.Trace.Fraction <> 0 then
 begin
  ClipEnd := Clip.Trace.EndPos;
  OldFraction := Clip.Trace.Fraction;
  Clip.Trace.Fraction := 1;

  Clip.VEnd := @ClipEnd;
  Clip.VStart := @VStart;
  Clip.MinS := @MinS;
  Clip.MaxS := @MaxS;
  Clip.PassEdict := PassEdict;
  Clip.HullNum := UInt(MonsterClip);
  Clip.I1 := MoveType and $FF;
  Clip.I2 := MoveType shr 8;

  if MoveType = MOVE_MISSILE then
   for I := 0 to 2 do
    begin
     Clip.MinS2[I] := -15;
     Clip.MaxS2[I] := 15;     
    end
  else
   begin
    Clip.MinS2 := MinS;
    Clip.MaxS2 := MaxS;
   end;

  SV_MoveBounds(VStart, Clip.MinS2, Clip.MaxS2, ClipEnd, Clip.BoxMinS, Clip.BoxMaxS);
  SV_ClipToLinks(SVAreaNodes[0], Clip);
  GlobalVars.TraceEnt := Clip.Trace.Ent;
  Clip.Trace.Fraction := Clip.Trace.Fraction * OldFraction;
 end;

Trace := Clip.Trace;
Result := @Trace;
end;

end.
