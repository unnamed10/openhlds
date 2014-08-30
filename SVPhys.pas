unit SVPhys;

{$I HLDS.inc}

interface

uses Default, SDK;

procedure SV_CheckVelocity(var E: TEdict);
function SV_RunThink(var E: TEdict): Boolean;
function SV_CheckWater(var E: TEdict): Boolean;

procedure SV_Impact(var E1, E2: TEdict; const Trace: TTrace);
procedure SV_Physics;

function SV_Trace_Toss(out Trace: TTrace; const E: TEdict; IgnoreEnt: PEdict): PTrace;
function SV_TraceTexture(E: PEdict; const V1, V2: TVec3): PLChar;

var
 sv_bounce: TCVar = (Name: 'sv_bounce'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_friction: TCVar = (Name: 'sv_friction'; Data: '4'; Flags: [FCVAR_SERVER]); 
 sv_gravity: TCVar = (Name: 'sv_gravity'; Data: '800'; Flags: [FCVAR_SERVER]);
 sv_maxvelocity: TCVar = (Name: 'sv_maxvelocity'; Data: '2000');
 sv_stopspeed: TCVar = (Name: 'sv_stopspeed'; Data: '100'; Flags: [FCVAR_SERVER]);

 sv_maxspeed: TCVar = (Name: 'sv_maxspeed'; Data: '320'; Flags: [FCVAR_SERVER]);
 sv_spectatormaxspeed: TCVar = (Name: 'sv_spectatormaxspeed'; Data: '500');
 sv_airmove: TCVar = (Name: 'sv_airmove'; Data: '1'; Flags: [FCVAR_SERVER]);

 sv_accelerate: TCVar = (Name: 'sv_accelerate'; Data: '10'; Flags: [FCVAR_SERVER]);
 sv_airaccelerate: TCVar = (Name: 'sv_airaccelerate'; Data: '10'; Flags: [FCVAR_SERVER]);
 sv_wateraccelerate: TCVar = (Name: 'sv_wateraccelerate'; Data: '10'; Flags: [FCVAR_SERVER]);  

 sv_stepsize: TCVar = (Name: 'sv_stepsize'; Data: '18'; Flags: [FCVAR_SERVER]);

 edgefriction: TCVar = (Name: 'edgefriction'; Data: '2'; Flags: [FCVAR_SERVER]);
 sv_waterfriction: TCVar = (Name: 'sv_waterfriction'; Data: '1'; Flags: [FCVAR_SERVER]);

 sv_zmax: TCVar = (Name: 'sv_zmax'; Data: '4096'; Flags: [FCVAR_SPONLY]);
 sv_wateramp: TCVar = (Name: 'sv_wateramp'; Data: '0');

 sv_skyname: TCVar = (Name: 'sv_skyname'; Data: 'desert');
 sv_skycolor_r: TCVar = (Name: 'sv_skycolor_r'; Data: '0');
 sv_skycolor_g: TCVar = (Name: 'sv_skycolor_g'; Data: '0');
 sv_skycolor_b: TCVar = (Name: 'sv_skycolor_b'; Data: '0');
 sv_skyvec_x: TCVar = (Name: 'sv_skyvec_x'; Data: '0');
 sv_skyvec_y: TCVar = (Name: 'sv_skyvec_y'; Data: '0');
 sv_skyvec_z: TCVar = (Name: 'sv_skyvec_z'; Data: '0');

 sv_rollangle: TCVar = (Name: 'sv_rollangle'; Data: '2');
 sv_rollspeed: TCVar = (Name: 'sv_rollspeed'; Data: '200');

type
 TMovedEdictArray = array[0..0] of PEdict;
 TMovedFromArray = array[0..0] of TVec3;

var
 MovedEdict: ^TMovedEdictArray;
 MovedFrom: ^TMovedFromArray;
 
implementation

uses Common, Console, Edict, GameLib, Host, MathLib, Model, Server, SVMove, SVSend, SVWorld, SysMain;

procedure SV_CheckVelocity(var E: TEdict);
const
 NaNMask = $7F800000;
 Axis: array[0..2] of LChar = 'XYZ';
var
 I: UInt;
begin
for I := 0 to 2 do
 begin
  if (NaNMask and PUInt32(@E.V.Velocity[I])^) = NaNMask then
   begin
    Print(['Got a NaN velocity at axis ', Axis[I], ' on entity ', PLChar(PRStrings + E.V.ClassName), '.']);
    E.V.Velocity[I] := 0;
   end;

  if (NaNMask and PUInt32(@E.V.Origin[I])^) = NaNMask then
   begin
    Print(['Got a NaN origin at axis ', Axis[I], ' on entity ', PLChar(PRStrings + E.V.ClassName), '.']);
    E.V.Origin[I] := 0;
   end;

  if E.V.Velocity[I] > sv_maxvelocity.Value then
   begin
    DPrint(['Got a velocity too high at axis ', Axis[I], ' on entity ', PLChar(PRStrings + E.V.ClassName), '.']);
    E.V.Velocity[I] := sv_maxvelocity.Value;
   end
  else
   if E.V.Velocity[I] < -sv_maxvelocity.Value then
    begin
     DPrint(['Got a velocity too low at axis ', Axis[I], ' on entity ', PLChar(PRStrings + E.V.ClassName), '.']);
     E.V.Velocity[I] := -sv_maxvelocity.Value;
    end;
 end;
end;

function SV_RunThink(var E: TEdict): Boolean;
begin
if (E.V.Flags and FL_KILLME) > 0 then
 begin
  ED_Free(E);
  Result := E.Free = 0;
  Exit;
 end;

if (E.V.NextThink > 0) and (HostFrameTime + SV.Time >= E.V.NextThink) then
 begin
  if E.V.NextThink < SV.Time then
   GlobalVars.Time := SV.Time
  else
   GlobalVars.Time := E.V.NextThink;

  E.V.NextThink := 0;
  DLLFunctions.Think(E);
  if (E.V.Flags and FL_KILLME) > 0 then
   ED_Free(E);

  Result := E.Free = 0;
 end
else
 Result := True;
end;

procedure SV_Impact(var E1, E2: TEdict; const Trace: TTrace);
begin
GlobalVars.Time := SV.Time;
if ((E1.V.Flags or E2.V.Flags) and FL_KILLME) = 0 then
 begin
  if FilterGroup(E1, E2) then
   Exit;
   
  if E1.V.Solid <> 0 then
   begin
    SV_SetGlobalTrace(Trace);
    DLLFunctions.Touch(E1, E2);
   end;

  if E2.V.Solid <> 0 then
   begin
    SV_SetGlobalTrace(Trace);
    DLLFunctions.Touch(E2, E1);
   end;
 end;
end;

function ClipVelocity(const VIn, Normal: TVec3; out VOut: TVec3; OverBounce: Single): UInt;
var
 Blocked, I: UInt;
 Backoff, F: Double;
begin
if Normal[2] < 0 then
 Blocked := 0
else
 if Normal[2] > 0 then
  Blocked := 1
 else
  Blocked := 2;

Backoff := DotProduct(VIn, Normal) * OverBounce;

for I := 0 to 2 do
 begin
  F := VIn[I] - Normal[I] * Backoff;
  if (F > -0.1) and (F < 0.1) then
   VOut[I] := 0
  else
   VOut[I] := F;
 end;

Result := Blocked;
end;

function SV_FlyMove(var E: TEdict; Time: Single; StepTrace: PTrace): UInt;
const
 NumBumps = 4;
var
 OriginalVelocity, PrimalVelocity, VEnd, NewVelocity, Dir: TVec3;
 UseClip: Boolean;
 BumpCount, I, J, NumPlanes, Blocked: UInt;
 TimeLeft, Bounce: Single;
 Trace, Trace2: TTrace;
 Planes: array[0..MAX_CLIP_PLANES - 1] of TVec3;
begin
OriginalVelocity := E.V.Velocity;
PrimalVelocity := E.V.Velocity;

TimeLeft := Time;
NumPlanes := 0;
Blocked := 0;
UseClip := (E.V.Flags and FL_MONSTERCLIP) > 0;

for BumpCount := 0 to NumBumps - 1 do
 begin
  if (E.V.Velocity[0] = 0) and (E.V.Velocity[1] = 0) and (E.V.Velocity[2] = 0) then
   Break;

  for I := 0 to 2 do
   VEnd[I] := TimeLeft * E.V.Velocity[I] + E.V.Origin[I];

  SV_Move(Trace, E.V.Origin, E.V.MinS, E.V.MaxS, VEnd, MOVE_NORMAL, @E, UseClip);
  if Trace.AllSolid <> 0 then
   begin
    E.V.Velocity := Vec3Origin;
    Result := 4;
    Exit;
   end;

  if Trace.Fraction > 0 then
   begin
    SV_Move(Trace2, Trace.EndPos, E.V.MinS, E.V.MaxS, Trace.EndPos, MOVE_NORMAL, @E, UseClip);
    if Trace2.AllSolid <> 1 then
     begin
      E.V.Origin := Trace.EndPos;
      OriginalVelocity := E.V.Velocity;
      NumPlanes := 0;
     end;
   end;

  if Trace.Fraction = 1 then
   Break
  else
   if Trace.Ent = nil then
    Sys_Error('SV_FlyMove: Invalid trace entity.');

  if Trace.Plane.Normal[2] > 0.7 then
   begin
    Blocked := Blocked or 1;
    if (Trace.Ent.V.Solid = SOLID_BSP) or (Trace.Ent.V.MoveType = MOVETYPE_PUSHSTEP) or
       (Trace.Ent.V.Solid = SOLID_SLIDEBOX) or ((E.V.Flags and FL_CLIENT) > 0) then
     begin
      E.V.GroundEntity := Trace.Ent;
      E.V.Flags := E.V.Flags or FL_ONGROUND;
     end;
   end;

  if Trace.Plane.Normal[2] = 0 then
   begin
    Blocked := Blocked or 2;
    if StepTrace <> nil then
     Move(Trace, StepTrace^, SizeOf(StepTrace^));
   end;

  SV_Impact(E, Trace.Ent^, Trace);
  if E.Free <> 0 then
   Break;

  TimeLeft := TimeLeft - Trace.Fraction * TimeLeft;
  if NumPlanes >= MAX_CLIP_PLANES then
   begin
    E.V.Velocity := Vec3Origin;
    Result := Blocked;
    Exit;
   end;

  Planes[NumPlanes] := Trace.Plane.Normal;
  Inc(NumPlanes);
  if (NumPlanes = 1) and (E.V.MoveType = MOVETYPE_WALK) and (((E.V.Flags and FL_ONGROUND) = 0) or (E.V.Friction <> 1)) then
   begin
    if Planes[0][2] <= 0.7 then
     Bounce := (1 - E.V.Friction) * sv_bounce.Value + 1
    else
     Bounce := 1;

    ClipVelocity(OriginalVelocity, Planes[0], NewVelocity, Bounce);
    E.V.Velocity := NewVelocity;
    OriginalVelocity := NewVelocity;
   end
  else
   begin
    I := 0;
    repeat
     ClipVelocity(OriginalVelocity, Planes[I], NewVelocity, 1);
     J := 0;
     repeat
      if (J <> I) and (DotProduct(NewVelocity, Planes[J]) < 0) then
       Break;

      Inc(J);
     until J = NumPlanes;

     if J = NumPlanes then
      Break
     else
      Inc(I);

    until I = NumPlanes;

    if I <> NumPlanes then
     E.V.Velocity := NewVelocity
    else
     if NumPlanes <> 2 then
      begin
       Result := Blocked;
       Exit;
      end
     else
      begin
       CrossProduct(Planes[0], Planes[1], Dir);
       VectorScale(Dir, DotProduct(Dir, E.V.Velocity), E.V.Velocity);
      end;

    if DotProduct(E.V.Velocity, PrimalVelocity) <= 0 then
     begin
      E.V.Velocity := Vec3Origin;
      Result := Blocked;
      Exit;
     end;
   end;
 end;

Result := Blocked;
end;

procedure SV_AddGravity(var E: TEdict);
var
 F: Single;
begin
if E.V.Gravity = 0 then
 F := 1
else
 F := E.V.Gravity;

E.V.Velocity[2] := (E.V.Velocity[2] - sv_gravity.Value * F * HostFrameTime) + (E.V.BaseVelocity[2] * HostFrameTime);
E.V.BaseVelocity[2] := 0;
SV_CheckVelocity(E);
end;

procedure SV_AddCorrectGravity(var E: TEdict);
var
 F: Single;
begin
if E.V.Gravity = 0 then
 F := 1
else
 F := E.V.Gravity;

E.V.Velocity[2] := (E.V.Velocity[2] - sv_gravity.Value * F * HostFrameTime * 0.5) + (E.V.BaseVelocity[2] * HostFrameTime);
E.V.BaseVelocity[2] := 0;
SV_CheckVelocity(E);
end;

procedure SV_FixupGravityVelocity(var E: TEdict);
var
 F: Single;
begin
if E.V.Gravity = 0 then
 F := 1
else
 F := E.V.Gravity;

E.V.Velocity[2] := E.V.Velocity[2] - sv_gravity.Value * F * HostFrameTime * 0.5;
SV_CheckVelocity(E);
end;

function SV_PushEntity(out Trace: TTrace; var E: TEdict; const Push: TVec3): PTrace;
var
 UseClip: Boolean;
 VEnd: TVec3;
 MoveType: UInt;
begin
UseClip := (E.V.Flags and FL_MONSTERCLIP) > 0;
VectorAdd(E.V.Origin, Push, VEnd);
if E.V.MoveType = MOVETYPE_FLYMISSILE then
 MoveType := MOVE_MISSILE
else
 if (E.V.Solid = SOLID_NOT) or (E.V.Solid = SOLID_TRIGGER) then
  MoveType := MOVE_NOMONSTERS
 else
  MoveType := MOVE_NORMAL;

SV_Move(Trace, E.V.Origin, E.V.MinS, E.V.MaxS, VEnd, MoveType, @E, UseClip);
if Trace.Fraction <> 0 then
 E.V.Origin := Trace.EndPos;

SV_LinkEdict(E, True);
if Trace.Ent <> nil then
 SV_Impact(E, Trace.Ent^, Trace);

Result := @Trace;
end;

procedure SV_PushMove(var E: TEdict; MoveTime: Single);
var
 I: Int;
 PushOrig, Move, MinS, MaxS, EntOrig: TVec3;
 P: PEdict;
 NumMoved, J: UInt;
 Trace: TTrace;
begin
E.V.LTime := E.V.LTime + MoveTime;
if (E.V.Velocity[0] = 0) and (E.V.Velocity[1] = 0) and (E.V.Velocity[2] = 0) then
 Exit;

PushOrig := E.V.Origin;
for I := 0 to 2 do
 begin
  Move[I] := E.V.Velocity[I] * MoveTime;
  MinS[I] := E.V.AbsMin[I] + Move[I];
  MaxS[I] := E.V.AbsMax[I] + Move[I];
  E.V.Origin[I] := E.V.Origin[I] + Move[I];
 end;

SV_LinkEdict(E, False);
if E.V.Solid = SOLID_NOT then
 Exit;

NumMoved := 0;
for I := 1 to SV.NumEdicts - 1 do
 begin
  P := @SV.Edicts[I];
  if (P.Free <> 0) or (P.V.MoveType = MOVETYPE_PUSH) or (P.V.MoveType = MOVETYPE_NONE) or
     (P.V.MoveType = MOVETYPE_FOLLOW) or (P.V.MoveType = MOVETYPE_NOCLIP) then
   Continue;

  if (((P.V.Flags and FL_ONGROUND) = 0) or (P.V.GroundEntity <> @E)) and
     ((P.V.AbsMin[0] >= MaxS[0]) or (P.V.AbsMin[1] >= MaxS[1]) or
      (P.V.AbsMin[2] >= MaxS[2]) or (P.V.AbsMax[0] <= MinS[0]) or
      (P.V.AbsMax[1] <= MinS[1]) or (P.V.AbsMax[2] <= MinS[2]) or
      (SV_TestEntityPosition(P^) = nil)) then
   Continue; 

  if P.V.MoveType <> MOVETYPE_WALK then
   P.V.Flags := P.V.Flags and not FL_ONGROUND;

  EntOrig := P.V.Origin;
  MovedFrom[NumMoved] := P.V.Origin;
  MovedEdict[NumMoved] := P;
  Inc(NumMoved);  
  if NumMoved >= SV.MaxEdicts then
   Sys_Error('SV_PushMove: Out of edicts in simulator.');

  E.V.Solid := SOLID_NOT;
  SV_PushEntity(Trace, P^, Move);
  E.V.Solid := SOLID_BSP;

  if (SV_TestEntityPosition(P^) = nil) or (P.V.MinS[0] = P.V.MaxS[0]) then
   Continue;

  if (P.V.Solid = SOLID_NOT) or (P.V.Solid = SOLID_TRIGGER) then
   begin
    P.V.MinS[0] := 0;
    P.V.MinS[1] := 0;
    P.V.MaxS[0] := 0;
    P.V.MaxS[1] := 0;
    P.V.MaxS[2] := P.V.MinS[2];
    Continue;
   end;

  P.V.Origin := EntOrig;
  SV_LinkEdict(P^, True);
  E.V.Origin := PushOrig;
  SV_LinkEdict(E, False);

  E.V.LTime := E.V.LTime - MoveTime;
  DLLFunctions.Blocked(E, P^);

  for J := 0 to NumMoved - 1 do
   begin
    MovedEdict[J].V.Origin := MovedFrom[J];
    SV_LinkEdict(MovedEdict[J]^, False);
   end;

  Exit;
 end;
end;

function SV_PushRotate(var E: TEdict; MoveTime: Single): Boolean;
var
 I: Int;
 PushAngles, Move, Fwd, Right, Up, TFwd, TRight, TUp, EntOrig, V, V2, V3: TVec3;
 P: PEdict;
 NumMoved, J: UInt;
 Trace: TTrace;
begin
E.V.LTime := E.V.LTime + MoveTime;
if (E.V.AVelocity[0] = 0) and (E.V.AVelocity[1] = 0) and (E.V.AVelocity[2] = 0) then
 begin
  Result := True;
  Exit;
 end;

for I := 0 to 2 do
 Move[I] := E.V.AVelocity[I] * MoveTime;

AngleVectors(E.V.Angles, @Fwd, @Right, @Up);
PushAngles := E.V.Angles;
VectorAdd(E.V.Angles, Move, E.V.Angles); 
AngleVectorsTranspose(E.V.Angles, @TFwd, @TRight, @TUp);

SV_LinkEdict(E, False);
if (E.V.Solid = SOLID_NOT) or (SV.NumEdicts <= 1) then
 begin
  Result := True;
  Exit;
 end;

NumMoved := 0;
for I := 1 to SV.NumEdicts - 1 do
 begin
  P := @SV.Edicts[I];
  if (P.Free <> 0) or (P.V.MoveType = MOVETYPE_PUSH) or (P.V.MoveType = MOVETYPE_NONE) or
     (P.V.MoveType = MOVETYPE_FOLLOW) or (P.V.MoveType = MOVETYPE_NOCLIP) then
   Continue;

  if (((P.V.Flags and FL_ONGROUND) = 0) or (P.V.GroundEntity <> @E)) and
     ((P.V.AbsMin[0] >= E.V.AbsMax[0]) or (P.V.AbsMin[1] >= E.V.AbsMax[1]) or
      (P.V.AbsMin[2] >= E.V.AbsMax[2]) or (P.V.AbsMax[0] <= E.V.AbsMin[0]) or
      (P.V.AbsMax[1] <= E.V.AbsMin[1]) or (P.V.AbsMax[2] <= E.V.AbsMin[2]) or
      (SV_TestEntityPosition(P^) = nil)) then
   Continue; 

  if P.V.MoveType <> MOVETYPE_WALK then
   P.V.Flags := P.V.Flags and not FL_ONGROUND;

  EntOrig := P.V.Origin;
  MovedFrom[NumMoved] := P.V.Origin;
  MovedEdict[NumMoved] := P;
  Inc(NumMoved);
  if NumMoved >= SV.MaxEdicts then
   Sys_Error('SV_PushRotate: Out of edicts in simulator.');

  if P.V.MoveType = MOVETYPE_PUSHSTEP then
   for J := 0 to 2 do
    V[J] := ((P.V.AbsMin[J] + P.V.AbsMax[J]) * 0.5) - E.V.Origin[J]
  else
   for J := 0 to 2 do
    V[J] := P.V.Origin[J] - E.V.Origin[J];

  V2[0] := DotProduct(Fwd, V);
  V2[1] := -DotProduct(Right, V);
  V2[2] := DotProduct(Up, V);
  V3[0] := DotProduct(TFwd, V2);
  V3[1] := DotProduct(TRight, V2);
  V3[2] := DotProduct(TUp, V2);
  VectorSubtract(V3, V, V3);

  E.V.Solid := SOLID_NOT;
  SV_PushEntity(Trace, P^, V3);
  E.V.Solid := SOLID_BSP;

  if P.V.MoveType <> MOVETYPE_PUSHSTEP then
   if (P.V.Flags and FL_CLIENT) > 0 then
    begin
     P.V.AVelocity[1] := P.V.AVelocity[1] + Move[1];
     P.V.FixAngle := 2;
    end
   else
    P.V.Angles[1] := P.V.Angles[1] + Move[1];

  if (SV_TestEntityPosition(P^) = nil) or (P.V.MinS[0] = P.V.MaxS[0]) then
   Continue;

  if (P.V.Solid = SOLID_NOT) or (P.V.Solid = SOLID_TRIGGER) then
   begin
    P.V.MinS[0] := 0;
    P.V.MinS[1] := 0;
    P.V.MaxS[0] := 0;
    P.V.MaxS[1] := 0;
    P.V.MaxS[2] := P.V.MinS[2];
    Continue;
   end;

  P.V.Origin := EntOrig;
  SV_LinkEdict(P^, True);
  E.V.Angles := PushAngles;
  SV_LinkEdict(E, False);

  E.V.LTime := E.V.LTime - MoveTime;
  DLLFunctions.Blocked(E, P^);

  for J := 0 to NumMoved - 1 do
   begin
    P := MovedEdict[J];
    P.V.Origin := MovedFrom[J];
    if (P.V.Flags and FL_CLIENT) > 0 then
     P.V.AVelocity[1] := 0
    else
     if P.V.MoveType <> MOVETYPE_PUSHSTEP then
      P.V.Angles[1] := P.V.Angles[1] - Move[1];

    SV_LinkEdict(P^, False);
   end;

  Result := False;
  Exit;
 end;

Result := True;
end;

procedure SV_Physics_Pusher(var E: TEdict);
var
 OldTime, ThinkTime, MoveTime, F: Single;
begin
OldTime := E.V.LTime;
ThinkTime := E.V.NextThink;

if OldTime + HostFrameTime > ThinkTime then
 begin
  MoveTime := ThinkTime - OldTime;
  if MoveTime < 0 then
   MoveTime := 0;
 end
else
 MoveTime := HostFrameTime;

if MoveTime <> 0 then
 if (E.V.AVelocity[0] = 0) and (E.V.AVelocity[1] = 0) and (E.V.AVelocity[2] = 0) then
  SV_PushMove(E, MoveTime)
 else
  if (E.V.Velocity[0] = 0) and (E.V.Velocity[1] = 0) and (E.V.Velocity[2] = 0) then
   SV_PushRotate(E, MoveTime)
  else
   if SV_PushRotate(E, MoveTime) then
    begin
     F := E.V.LTime;
     E.V.LTime := OldTime;
     SV_PushMove(E, MoveTime);
     if E.V.LTime < F then
      E.V.LTime := F;
    end;

if (ThinkTime > OldTime) and (((E.V.Flags and FL_ALWAYSTHINK) > 0) or (ThinkTime <= E.V.LTime)) then
 begin
  E.V.NextThink := 0;
  GlobalVars.Time := SV.Time;
  DLLFunctions.Think(E);
 end;
end;

function SV_CheckWater(var E: TEdict): Boolean;
const
 CurrentTable: array[0..5] of TVec3 =
 ((1, 0, 0), (0, 1, 0), (-1, 0, 0),
  (0, -1, 0), (0, 0, 1), (0, 0, -1));
var
 V: TVec3;
 C, C2: Int;
begin
V[0] := (E.V.AbsMin[0] + E.V.AbsMax[0]) * 0.5;
V[1] := (E.V.AbsMin[1] + E.V.AbsMax[1]) * 0.5;
V[2] := E.V.AbsMin[2] + 1;

E.V.WaterLevel := 0;
E.V.WaterType := CONTENTS_EMPTY;
GroupMask := E.V.GroupInfo;

C := SV_PointContents(V);
if (C <= CONTENTS_WATER) and (C >= CONTENTS_CURRENT_DOWN) then
 begin
  E.V.WaterType := C;

  if E.V.AbsMin[2] = E.V.AbsMax[2] then
   E.V.WaterLevel := 3
  else
   begin
    E.V.WaterLevel := 1;
    GroupMask := E.V.GroupInfo;
    V[2] := (E.V.AbsMin[2] + E.V.AbsMax[2]) * 0.5;
    C2 := SV_PointContents(V);
    if (C2 <= CONTENTS_WATER) and (C2 >= CONTENTS_CURRENT_DOWN) then
     begin
      E.V.WaterLevel := 2;
      GroupMask := E.V.GroupInfo;
      VectorAdd(V, E.V.ViewOfs, V);
      C2 := SV_PointContents(V);
      if (C2 <= CONTENTS_WATER) and (C2 >= CONTENTS_CURRENT_DOWN) then
       E.V.WaterLevel := 3;
     end;
   end;

  if (C <= CONTENTS_CURRENT_0) and (C >= CONTENTS_CURRENT_DOWN) then
   VectorMA(E.V.BaseVelocity, E.V.WaterLevel * 50, CurrentTable[CONTENTS_CURRENT_0 - C], E.V.BaseVelocity);
 end;

Result := E.V.WaterLevel > 1;
end;

function SV_RecursiveWaterLevel(const P: TVec3; F1, F2: Single; Level: UInt): Double;
var
 Mid: Double;
 V: TVec3;
begin
Mid := (F1 - F2) * 0.5 + F2;
Inc(Level);
if Level > 5 then
 Result := Mid
else
 begin
  V[0] := P[0];
  V[1] := P[1];
  V[2] := P[2] + Mid;
  if SV_PointContents(V) = CONTENTS_WATER then
   Result := SV_RecursiveWaterLevel(P, F1, Mid, Level)
  else
   Result := SV_RecursiveWaterLevel(P, Mid, F2, Level);
 end;
end;

function SV_Submerged(var E: TEdict): Double;
var
 V, V2: TVec3;
 F: Single;
begin
V[0] := (E.V.AbsMin[0] + E.V.AbsMax[0]) * 0.5;
V[1] := (E.V.AbsMin[1] + E.V.AbsMax[1]) * 0.5;
V[2] := (E.V.AbsMin[2] + E.V.AbsMax[2]) * 0.5;
F := E.V.AbsMin[2] - V[2];

case E.V.WaterLevel of
 1: Result := SV_RecursiveWaterLevel(V, 0, F, 0) - F;
 2: Result := SV_RecursiveWaterLevel(V, E.V.AbsMax[2] - V[2], 0, 0) - F;
 3:
  begin
   V2[0] := V[0];
   V2[1] := V[1];
   V2[2] := E.V.AbsMax[2];
   GroupMask := E.V.GroupInfo;
   if SV_PointContents(V2) = CONTENTS_WATER then
    Result := E.V.MaxS[2] - E.V.MinS[2]
   else
    Result := SV_RecursiveWaterLevel(V, E.V.AbsMax[2] - V[2], 0, 0) - F;
  end;
 else Result := 0;
end;
end;

procedure SV_Physics_None(var E: TEdict);
begin
SV_RunThink(E);
end;

procedure SV_Physics_Follow(var E: TEdict);
var
 P: PEdict;
begin
if SV_RunThink(E) then
 begin
  P := E.V.AimEnt;
  if P <> nil then
   begin
    E.V.Angles := P.V.Angles;
    VectorAdd(P.V.Origin, E.V.VAngle, E.V.Origin);
    SV_LinkEdict(E, True);
   end
  else
   begin
    DPrint(['SV_Physics_Follow: MOVETYPE_FOLLOW with invalid aiment at "', PLChar(PRStrings + E.V.ClassName), '".']);
    E.V.MoveType := MOVETYPE_NONE;
   end;
 end;
end;

procedure SV_Physics_Noclip(var E: TEdict);
begin
if SV_RunThink(E) then
 begin
  VectorMA(E.V.Angles, HostFrameTime, E.V.AVelocity, E.V.Angles);
  VectorMA(E.V.Origin, HostFrameTime, E.V.Velocity, E.V.Origin);
  SV_LinkEdict(E, False);  
 end;
end;

procedure SV_CheckWaterTransition(var E: TEdict);
var
 Point: TVec3;
 C: Int;
begin
GroupMask := E.V.GroupInfo;
Point[0] := (E.V.AbsMin[0] + E.V.AbsMax[0]) * 0.5;
Point[1] := (E.V.AbsMin[1] + E.V.AbsMax[1]) * 0.5;
Point[2] := E.V.AbsMin[2] + 1;
C := SV_PointContents(Point);
if E.V.WaterType = 0 then
 begin
  E.V.WaterType := C;
  E.V.WaterLevel := 1;
 end
else
 if (C > CONTENTS_WATER) or (C < CONTENTS_CURRENT_DOWN) then
  begin
   if E.V.WaterType <> CONTENTS_EMPTY then
    SV_StartSound(False, E, CHAN_AUTO, 'player/pl_wade2.wav', 255, 1, 0, PITCH_NORM);
   E.V.WaterType := CONTENTS_EMPTY;
   E.V.WaterLevel := 0;
  end
 else
  begin
   if E.V.WaterType = CONTENTS_EMPTY then
    begin
     SV_StartSound(False, E, CHAN_AUTO, 'player/pl_wade1.wav', 255, 1, 0, PITCH_NORM);
     E.V.Velocity[2] := E.V.Velocity[2] * 0.5;
    end;

   E.V.WaterType := C;
   if E.V.AbsMin[2] = E.V.AbsMax[2] then
    E.V.WaterLevel := 3
   else
    begin
     E.V.WaterLevel := 1;
     GroupMask := E.V.GroupInfo;
     Point[2] := (E.V.AbsMin[2] + E.V.AbsMax[2]) * 0.5;
     C := SV_PointContents(Point);
     if (C <= CONTENTS_WATER) and (C >= CONTENTS_CURRENT_DOWN) then
      begin
       E.V.WaterLevel := 2;
       GroupMask := E.V.GroupInfo;
       VectorAdd(Point, E.V.ViewOfs, Point);
       C := SV_PointContents(Point);
       if (C <= CONTENTS_WATER) and (C >= CONTENTS_CURRENT_DOWN) then
        E.V.WaterLevel := 3;
      end;
    end;
  end;
end;

procedure SV_Physics_Toss(var E: TEdict);
var
 Move: TVec3;
 Trace: TTrace;
 Backoff, F: Single;
begin
SV_CheckWater(E);
if not SV_RunThink(E) then
 Exit;

if (E.V.Velocity[2] > 0) or (E.V.GroundEntity = nil) or ((E.V.GroundEntity.V.Flags and (FL_MONSTER or FL_CLIENT)) > 0) then
 E.V.Flags := E.V.Flags and not FL_ONGROUND;

if ((E.V.Flags and FL_ONGROUND) > 0) and VectorCompare(E.V.Velocity, Vec3Origin) then
 begin
  E.V.AVelocity := Vec3Origin;
  if VectorCompare(E.V.BaseVelocity, Vec3Origin) then
   Exit;
 end;

SV_CheckVelocity(E);
if (E.V.MoveType <> MOVETYPE_FLY) and (E.V.MoveType <> MOVETYPE_FLYMISSILE) and (E.V.MoveType <> MOVETYPE_BOUNCEMISSILE) then
 SV_AddGravity(E);

VectorMA(E.V.Angles, HostFrameTime, E.V.AVelocity, E.V.Angles);

VectorAdd(E.V.Velocity, E.V.BaseVelocity, E.V.Velocity);
SV_CheckVelocity(E);
VectorScale(E.V.Velocity, HostFrameTime, Move);
VectorSubtract(E.V.Velocity, E.V.BaseVelocity, E.V.Velocity);

SV_PushEntity(Trace, E, Move);
SV_CheckVelocity(E);

if Trace.AllSolid <> 0 then
 begin
  E.V.Velocity := Vec3Origin;
  E.V.AVelocity := Vec3Origin;
 end
else
 if Trace.Fraction = 1 then
  SV_CheckWaterTransition(E)
 else
  if E.Free = 0 then
   begin
    if E.V.MoveType = MOVETYPE_BOUNCE then
     Backoff := 2 - E.V.Friction
    else
     if E.V.MoveType = MOVETYPE_BOUNCEMISSILE then
      Backoff := 2
     else
      Backoff := 1;

    ClipVelocity(E.V.Velocity, Trace.Plane.Normal, E.V.Velocity, Backoff);
    if Trace.Plane.Normal[2] > 0.7 then
     begin
      VectorAdd(E.V.BaseVelocity, E.V.Velocity, Move);
      if sv_gravity.Value * HostFrameTime > Move[2] then
       begin
        E.V.GroundEntity := Trace.Ent;
        E.V.Flags := E.V.Flags or FL_ONGROUND;
        E.V.Velocity[2] := 0;
       end;

      if (DotProduct(Move, Move) >= 900) and ((E.V.MoveType = MOVETYPE_BOUNCE) or (E.V.MoveType = MOVETYPE_BOUNCEMISSILE)) then
       begin
        F := (1 - Trace.Fraction) * HostFrameTime * 0.9;
        VectorScale(E.V.Velocity, F, Move);
        VectorMA(Move, F, E.V.BaseVelocity, Move);
        SV_PushEntity(Trace, E, Move);
       end
      else
       begin
        E.V.GroundEntity := Trace.Ent;
        E.V.Flags := E.V.Flags or FL_ONGROUND;
        E.V.Velocity := Vec3Origin;
        E.V.AVelocity := Vec3Origin;
       end;
     end;

    SV_CheckWaterTransition(E);
   end;
end;

procedure SV_WaterMove(var E: TEdict);
var
 DrownLevel: Single;
 Flags, WaterLevel, WaterType: Int;
begin
if E.V.MoveType = MOVETYPE_NOCLIP then
 begin
  E.V.AirFinished := SV.Time + 12;
  Exit;
 end;

if E.V.Health < 0 then
 Exit;

if E.V.DeadFlag = DEAD_NO then
 DrownLevel := 3
else
 DrownLevel := 1;

Flags := E.V.Flags;
WaterLevel := E.V.WaterLevel;
WaterType := E.V.WaterType;

if (Flags and (FL_GODMODE or FL_IMMUNE_WATER)) = 0 then
 if (((Flags and FL_SWIM) > 0) and (WaterLevel < DrownLevel)) or (WaterLevel >= DrownLevel) then
  if (E.V.AirFinished < SV.Time) and (E.V.PainFinished < SV.Time) then
   begin
    E.V.Dmg := E.V.Dmg + 2;
    if E.V.Dmg > 15 then
     E.V.Dmg := 10;
    E.V.PainFinished := SV.Time + 1;
   end
  else
 else
  begin
   E.V.Dmg := 2;
   E.V.AirFinished := SV.Time + 12;
  end;

if WaterLevel = 0 then
 begin
  if (Flags and FL_INWATER) > 0 then
   begin
    case RandomLong(0, 3) of
     0: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade1.wav', 255, ATTN_NORM, 0, PITCH_NORM);
     1: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade2.wav', 255, ATTN_NORM, 0, PITCH_NORM);
     2: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade3.wav', 255, ATTN_NORM, 0, PITCH_NORM);
     3: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade4.wav', 255, ATTN_NORM, 0, PITCH_NORM);
    end;
    E.V.Flags := Flags and not FL_INWATER; 
   end;

  E.V.AirFinished := SV.Time + 12;
  Exit;
 end; 

if WaterType = CONTENTS_LAVA then
 if ((Flags and (FL_IMMUNE_LAVA or FL_GODMODE)) = 0) and (E.V.DmgTime < SV.Time) then
  if E.V.RadSuitFinished < SV.Time then
   E.V.DmgTime := SV.Time + 0.2
  else
   E.V.DmgTime := SV.Time + 1;

if WaterType = CONTENTS_SLIME then
 if ((Flags and (FL_IMMUNE_SLIME or FL_GODMODE)) = 0) and (E.V.DmgTime < SV.Time) and (E.V.RadSuitFinished < SV.Time) then
  E.V.DmgTime := SV.Time + 1;

if (Flags and FL_INWATER) = 0 then
 begin
  if WaterType = CONTENTS_WATER then
   case RandomLong(0, 3) of
    0: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade1.wav', 255, ATTN_NORM, 0, PITCH_NORM);
    1: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade2.wav', 255, ATTN_NORM, 0, PITCH_NORM);
    2: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade3.wav', 255, ATTN_NORM, 0, PITCH_NORM);
    3: SV_StartSound(False, E, CHAN_BODY, 'player/pl_wade4.wav', 255, ATTN_NORM, 0, PITCH_NORM);
   end;

  E.V.DmgTime := 0;
  E.V.Flags := Flags or FL_INWATER;
 end;

if (Flags and FL_WATERJUMP) = 0 then
 VectorMA(E.V.Velocity, E.V.WaterLevel * HostFrameTime * -0.8, E.V.Velocity, E.V.Velocity);
end;

procedure SV_Physics_Step(var E: TEdict);
var
 InWater, WasOnGround: Boolean;
 F, Speed, Friction, Control, NewSpeed: Single;
 Trace: TTrace;
 I, J: UInt;
 MinS, MaxS, Point: TVec3;
begin
SV_WaterMove(E);
SV_CheckVelocity(E);
InWater := SV_CheckWater(E);
WasOnGround := (E.V.Flags and FL_ONGROUND) > 0;

if ((E.V.Flags and FL_FLOAT) > 0) and (E.V.WaterLevel > 0) then
 begin
  F := SV_Submerged(E) * E.V.Skin * HostFrameTime;
  SV_AddGravity(E);
  E.V.Velocity[2] := E.V.Velocity[2] + F;
 end;

if not InWater and not WasOnGround and ((E.V.Flags and FL_FLY) = 0) and
   (((E.V.Flags and FL_SWIM) = 0) or (E.V.WaterLevel <= 0)) then
 SV_AddGravity(E);

if not VectorCompare(E.V.Velocity, Vec3Origin) or not VectorCompare(E.V.BaseVelocity, Vec3Origin) then
 begin
  E.V.Flags := E.V.Flags and not FL_ONGROUND;
  if WasOnGround and ((E.V.Health > 0) or SV_CheckBottom(E)) then
   begin
    Speed := Sqrt(E.V.Velocity[0] * E.V.Velocity[0] + E.V.Velocity[1] * E.V.Velocity[1]);
    if Speed <> 0 then
     begin
      Friction := sv_friction.Value * E.V.Friction;
      E.V.Friction := 1;
      if Speed >= sv_stopspeed.Value then
       Control := Speed
      else
       Control := sv_stopspeed.Value;

      NewSpeed := Speed - Control * Friction * HostFrameTime;
      if NewSpeed < 0 then
       NewSpeed := 0;
      NewSpeed := NewSpeed / Speed;
      E.V.Velocity[0] := E.V.Velocity[0] * NewSpeed;
      E.V.Velocity[1] := E.V.Velocity[1] * NewSpeed;
     end; 
   end;

  VectorAdd(E.V.Velocity, E.V.BaseVelocity, E.V.Velocity);
  SV_CheckVelocity(E);
  SV_FlyMove(E, HostFrameTime, nil);
  SV_CheckVelocity(E);
  VectorSubtract(E.V.Velocity, E.V.BaseVelocity, E.V.Velocity);
  SV_CheckVelocity(E);

  VectorAdd(E.V.MinS, E.V.Origin, MinS);
  VectorAdd(E.V.MaxS, E.V.Origin, MaxS);
  Point[2] := MinS[2] - 1;
    
  for I := 0 to 1 do
   for J := 0 to 1 do
    begin
     if I = 1 then
      Point[0] := MaxS[0]
     else
      Point[0] := MinS[0];
     if J = 1 then
      Point[1] := MaxS[1]
     else
      Point[1] := MinS[1];

     GroupMask := E.V.GroupInfo;
     if SV_PointContents(Point) = CONTENTS_SOLID then
      begin
       E.V.Flags := E.V.Flags or FL_ONGROUND;
       Break;
      end;
    end;

  SV_LinkEdict(E, True); 
 end
else
 if GlobalVars.ForceRetouch <> 0 then
  begin
   SV_Move(Trace, E.V.Origin, E.V.MinS, E.V.MaxS, E.V.Origin, MOVE_NORMAL, @E, (E.V.Flags and FL_MONSTERCLIP) > 0);
   if ((Trace.Fraction < 1) or (Trace.StartSolid <> 0)) and (Trace.Ent <> nil) then
    SV_Impact(E, Trace.Ent^, Trace);    
  end;

SV_RunThink(E);
SV_CheckWaterTransition(E);
end;

procedure SV_Physics;
var
 I: Int;
 E, E2: PEdict;
begin
GlobalVars.Time := SV.Time;
DLLFunctions.StartFrame;
for I := 0 to SV.NumEdicts - 1 do
 begin
  E := @SV.Edicts[I];
  if E.Free <> 0 then
   Continue;

  if GlobalVars.ForceRetouch <> 0 then
   SV_LinkEdict(E^, True);

  if (I >= 1) and (UInt(I) <= SVS.MaxClients) then
   Continue;

  if (E.V.Flags and FL_ONGROUND) > 0 then
   begin
    E2 := E.V.GroundEntity;
    if (E2 <> nil) and ((E2.V.Flags and FL_CONVEYOR) > 0) then
     begin
      if (E.V.Flags and FL_BASEVELOCITY) > 0 then
       VectorMA(E.V.BaseVelocity, E2.V.Speed, E2.V.MoveDir, E.V.BaseVelocity)
      else
       VectorScale(E2.V.MoveDir, E2.V.Speed, E.V.BaseVelocity);

      E.V.Flags := E.V.Flags or FL_BASEVELOCITY;
     end;
   end;

  if (E.V.Flags and FL_BASEVELOCITY) = 0 then
   begin
    VectorMA(E.V.Velocity, HostFrameTime * 0.5 + 1, E.V.BaseVelocity, E.V.Velocity);
    E.V.BaseVelocity := Vec3Origin;
   end;

  E.V.Flags := E.V.Flags and not FL_BASEVELOCITY;
  case E.V.MoveType of
   MOVETYPE_NONE: SV_Physics_None(E^);  
   MOVETYPE_PUSH: SV_Physics_Pusher(E^);
   MOVETYPE_FOLLOW: SV_Physics_Follow(E^);
   MOVETYPE_NOCLIP: SV_Physics_Noclip(E^);
   MOVETYPE_STEP, MOVETYPE_PUSHSTEP: SV_Physics_Step(E^);
   MOVETYPE_TOSS, MOVETYPE_BOUNCE, MOVETYPE_BOUNCEMISSILE,
   MOVETYPE_FLY, MOVETYPE_FLYMISSILE: SV_Physics_Toss(E^);
   else
    Sys_Error(['SV_Physics: Bad movetype ', E.V.MoveType, ' at entity "', PLChar(PRStrings + E.V.ClassName), '".']);
  end;

  if (E.V.Flags and FL_KILLME) > 0 then
   ED_Free(E^);  
 end;

if GlobalVars.ForceRetouch <> 0 then
 GlobalVars.ForceRetouch := GlobalVars.ForceRetouch - 1;
end;

function SV_Trace_Toss(out Trace: TTrace; const E: TEdict; IgnoreEnt: PEdict): PTrace;
var
 SaveFrameTime: Double;
 TempEnt: TEdict;
 V: TVec3;
begin
SaveFrameTime := HostFrameTime;
HostFrameTime := 0.05;
Move(E, TempEnt, SizeOf(TempEnt));

repeat
 SV_CheckVelocity(TempEnt);
 SV_AddGravity(TempEnt);
 VectorMA(TempEnt.V.Angles, HostFrameTime, TempEnt.V.AVelocity, TempEnt.V.Angles);
 VectorScale(TempEnt.V.Velocity, HostFrameTime, V);
 VectorAdd(V, TempEnt.V.Origin, V);
 SV_Move(Trace, TempEnt.V.Origin, TempEnt.V.MinS, TempEnt.V.MaxS, V, MOVE_NORMAL, @TempEnt, False);
 TempEnt.V.Origin := Trace.EndPos;
until (Trace.Ent <> nil) and (Trace.Ent <> IgnoreEnt);

HostFrameTime := SaveFrameTime;
Result := @Trace;
end;

function SV_TraceTexture(E: PEdict; const V1, V2: TVec3): PLChar;
var
 MinS, MaxS, V3, V4, Fwd, Right, Up, VOut: TVec3;
 M: PModel;
 Hull: PHull;
 NodeIndex: UInt;
 Surface: PMSurface;
begin
if E = nil then
 begin
  M := SV.WorldModel;
  MinS := V1;
  MaxS := V2;
  NodeIndex := 0;
 end
else
 begin
  M := SV.PrecachedModels[E.V.ModelIndex];
  if (M = nil) or (M.ModelType <> ModBrush) then
   begin
    Result := nil;
    Exit;
   end;

  Hull := SV_HullForBSP(E^, Vec3Origin, Vec3Origin, VOut);
  VectorSubtract(V1, VOut, MinS);
  VectorSubtract(V2, VOut, MaxS);
  NodeIndex := Hull.FirstClipNode;

  if (E.V.Angles[0] <> 0) or (E.V.Angles[1] <> 0) or (E.V.Angles[2] <> 0) then
   begin
    AngleVectors(E.V.Angles, @Fwd, @Right, @Up);
    V3[0] := DotProduct(MinS, Fwd);
    V3[1] := -DotProduct(MinS, Right);
    V3[2] := DotProduct(MinS, Up);
    V4[0] := DotProduct(MaxS, Fwd);
    V4[1] := -DotProduct(MaxS, Right);
    V4[2] := DotProduct(MaxS, Up);
    MinS := V3;
    MaxS := V4;
   end;
 end;

if (M <> nil) and (M.ModelType = ModBrush) and (M.Nodes <> nil) then
 begin
  Surface := SurfaceAtPoint(M^, M.Nodes[NodeIndex], MinS, MaxS);
  if Surface <> nil then
   begin
    Result := @Surface.TexInfo.Texture.Name;
    Exit;
   end;
 end;

Result := nil;
end;

end.
