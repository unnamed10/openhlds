unit SVMove;

{$I HLDS.inc}

interface

uses Default, SDK;

function SV_CheckBottom(const E: TEdict): Boolean;
function SV_MoveTest(var E: TEdict; const Move: TVec3; Relink: Boolean): Boolean;
function SV_MoveStep(var E: TEdict; const Move: TVec3; Relink: Boolean): Boolean;

procedure SV_MoveToOrigin(var E: TEdict; const Target: TVec3; Distance: Single; MoveType: Int);

procedure SV_SetGlobalTrace(const T: TTrace);
function SV_PointLeafnum(const P: TVec3): UInt;

procedure SV_GetTrueOrigin(Index: UInt; out Origin: TVec3);
procedure SV_GetTrueMinMax(Index: UInt; out MinS, MaxS: PVec3);

procedure PM_SV_PlaySound(Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
function PM_SV_TraceTexture(Ground: Int32; const VStart, VEnd: TVec3): PLChar; cdecl;
procedure PM_SV_PlaybackEventFull(Flags, ClientIndex: Int32; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;

procedure SV_CheckCmdTimes;
procedure SV_PreRunCmd;
procedure SV_RunCmd(var Cmd: TUserCmd; RandomSeed: UInt32);

procedure SV_SetupMove(var C: TClient);
procedure SV_RestoreMove(var C: TClient);

function SV_FatPVS(const Origin: TVec3): PByte;
function SV_FatPAS(const Origin: TVec3): PByte;

procedure SV_SetMoveVars;
procedure SV_QueryMovevarsChanged;

procedure SV_ComputeLatency(var C: TClient);

procedure SV_EstablishTimeBase(var C: TClient; Cmd: PUserCmdArray; Drop, Backup, NumCmds: UInt);
procedure SV_ParseMove(var C: TClient);

var
 sv_maxunlag: TCVar = (Name: 'sv_maxunlag'; Data: '0.5'; Flags: [FCVAR_SERVER]);
 sv_unlag: TCVar = (Name: 'sv_unlag'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_unlagpush: TCVar = (Name: 'sv_unlagpush'; Data: '0'; Flags: [FCVAR_SERVER]);
 sv_unlagsamples: TCVar = (Name: 'sv_unlagsamples'; Data: '1'; Flags: [FCVAR_SERVER]);

 sv_cmdcheckinterval: TCVar = (Name: 'sv_cmdcheckinterval'; Data: '1');

 ServerMove: TPlayerMove;

 AlreadyMoved: Boolean = False;

implementation

uses Common, Console, Edict, Encode, Host, GameLib, MathLib, Model, MsgBuf, Network, PMove, Server, SVClient, SVEdict, SVEvent, SVPhys, SVSend, SVWorld;

var
 TruePositions: array[0..MAX_PLAYERS - 1] of TCachedMove;

 NoFind: Boolean = False;

 FatPAS, FatPVS: array[0..MAX_MAP_LEAFS div 8 - 1] of Byte;
 FatPASBytes, FatPVSBytes: UInt;

 LastTimeReset: Double = 0;

function SV_CheckBottom(const E: TEdict): Boolean;
var
 MinS, MaxS, Start, Stop: TVec3;
 I, J: UInt;
 MonsterClip: Boolean;
 Trace: TTrace;
 Mid, Bottom: Single;
begin
MonsterClip := (E.V.Flags and FL_MONSTERCLIP) > 0;
VectorAdd(E.V.MinS, E.V.Origin, MinS);
VectorAdd(E.V.MaxS, E.V.Origin, MaxS);

Start[2] := MinS[2] - 1;
for I := 0 to 3 do // x = i&2, y = i&1
 begin
  if (I and 2) > 0 then
   Start[0] := MaxS[0]
  else
   Start[0] := MinS[0];
  if (I and 1) > 0 then
   Start[1] := MaxS[1]
  else
   Start[1] := MinS[1];

  GroupMask := E.V.GroupInfo;
  if SV_PointContents(Start) <> CONTENTS_SOLID then
   begin
    Result := False;
    
    Start[0] := (MinS[0] + MaxS[0]) * 0.5;
    Start[1] := (MinS[1] + MaxS[1]) * 0.5;
    Start[2] := MinS[2] + sv_stepsize.Value;

    Stop[0] := Start[0];
    Stop[1] := Start[1];
    Stop[2] := Start[2] - (sv_stepsize.Value * 2);

    SV_Move(Trace, Start, Vec3Origin, Vec3Origin, Stop, MOVE_NOMONSTERS, @E, MonsterClip);
    if Trace.Fraction <> 1 then
     begin
      Mid := Trace.EndPos[2];
      Bottom := Trace.EndPos[2];
      for J := 0 to 3 do
       begin
        if (J and 2) > 0 then
         Start[0] := MaxS[0]
        else
         Start[0] := MinS[0];
        if (J and 1) > 0 then
         Start[1] := MaxS[1]
        else
         Start[1] := MinS[1];
        Stop[0] := Start[0];
        Stop[1] := Start[1];

        SV_Move(Trace, Start, Vec3Origin, Vec3Origin, Stop, MOVE_NOMONSTERS, @E, MonsterClip);
        if (Trace.Fraction <> 1) and (Trace.EndPos[2] > Bottom) then
         Bottom := Trace.EndPos[2];
        if (Trace.Fraction = 1) or (Mid - Trace.EndPos[2] > sv_stepsize.Value) then
         Exit;
       end;
       
      Result := True;
     end;
    
    Exit;
   end;
 end;

Result := True;
end;

function SV_MoveTest(var E: TEdict; const Move: TVec3; Relink: Boolean): Boolean;
var
 OldOrg, NewOrg, VEnd: TVec3;
 Trace: TTrace;
begin
OldOrg := E.V.Origin;
VectorAdd(OldOrg, Move, NewOrg);
VEnd := NewOrg;
NewOrg[2] := NewOrg[2] + sv_stepsize.Value;
VEnd[2] := NewOrg[2] - (sv_stepsize.Value * 2);

SV_MoveNoEnts(Trace, NewOrg, E.V.MinS, E.V.MaxS, VEnd, MOVE_NORMAL, @E);
Result := False;

if Trace.AllSolid = 0 then
 begin
  if Trace.StartSolid <> 0 then
   begin
    NewOrg[2] := NewOrg[2] - sv_stepsize.Value;
    SV_MoveNoEnts(Trace, NewOrg, E.V.MinS, E.V.MaxS, VEnd, MOVE_NORMAL, @E);
    if (Trace.AllSolid <> 0) or (Trace.StartSolid <> 0) then
     Exit;
   end;

  if Trace.Fraction <> 1 then
   begin
    E.V.Origin := Trace.EndPos;
    if not SV_CheckBottom(E) then
     if (E.V.Flags and FL_PARTIALGROUND) > 0 then
      begin
       if Relink then
        SV_LinkEdict(E, True);
       Result := True;
      end
     else
      begin
       E.V.Origin := OldOrg;
       Result := False;
      end
    else
     begin
      if (E.V.Flags and FL_PARTIALGROUND) > 0 then
       E.V.Flags := E.V.Flags and not FL_PARTIALGROUND;

      E.V.GroundEntity := Trace.Ent;
      if Relink then
       SV_LinkEdict(E, True);

      Result := True;
     end;
   end
  else
   if (E.V.Flags and FL_PARTIALGROUND) = 0 then
    Result := False
   else
    begin
     VectorAdd(E.V.Origin, Move, E.V.Origin);
     if Relink then
      SV_LinkEdict(E, True);

     E.V.Flags := E.V.Flags and not FL_ONGROUND;
     Result := True;
    end;
 end;
end;

function SV_MoveStep(var E: TEdict; const Move: TVec3; Relink: Boolean): Boolean;
var
 OldOrg, NewOrg, VEnd: TVec3;
 I: UInt;
 F: Single;
 Trace: TTrace;
 MonsterClip: Boolean;
begin
MonsterClip := (E.V.Flags and FL_MONSTERCLIP) > 0;

OldOrg := E.V.Origin;
VectorAdd(OldOrg, Move, NewOrg);
if (E.V.Flags and (FL_FLY or FL_SWIM)) > 0 then
 begin
  for I := 0 to 1 do
   begin
    VectorAdd(E.V.Origin, Move, NewOrg);
    if (I = 0) and (E.V.Enemy <> nil) then
     begin
      F := E.V.Origin[2] - E.V.Enemy.V.Origin[2];
      if F > 40 then
       NewOrg[2] := NewOrg[2] - 8
      else
       if F < 30 then
        NewOrg[2] := NewOrg[2] + 8;
     end;

    SV_Move(Trace, E.V.Origin, E.V.MinS, E.V.MaxS, NewOrg, MOVE_NORMAL, @E, MonsterClip);
    if Trace.Fraction = 1 then
     begin
      GroupMask := E.V.GroupInfo;
      if ((E.V.Flags and FL_SWIM) = 0) or (SV_PointContents(Trace.EndPos) <> CONTENTS_EMPTY) then
       begin
        E.V.Origin := Trace.EndPos;
        if Relink then
         SV_LinkEdict(E, True);
        Result := True;
        Exit;   
       end;

      Break;
     end;

    if E.V.Enemy = nil then
     Break;
   end;

  Result := False;
  Exit;
 end;

VEnd := NewOrg;
NewOrg[2] := NewOrg[2] + sv_stepsize.Value;
VEnd[2] := NewOrg[2] - (sv_stepsize.Value * 2);

SV_Move(Trace, NewOrg, E.V.MinS, E.V.MaxS, VEnd, MOVE_NORMAL, @E, MonsterClip);
Result := False;

if Trace.AllSolid = 0 then
 begin
  if Trace.StartSolid <> 0 then
   begin
    NewOrg[2] := NewOrg[2] - sv_stepsize.Value;
    SV_Move(Trace, NewOrg, E.V.MinS, E.V.MaxS, VEnd, MOVE_NORMAL, @E, MonsterClip);
    if (Trace.AllSolid <> 0) or (Trace.StartSolid <> 0) then
     Exit;
   end;

  if Trace.Fraction <> 1 then
   begin
    E.V.Origin := Trace.EndPos;
    if not SV_CheckBottom(E) then
     if (E.V.Flags and FL_PARTIALGROUND) > 0 then
      begin
       if Relink then
        SV_LinkEdict(E, True);
       Result := True;
      end
     else
      begin
       E.V.Origin := OldOrg;
       Result := False;
      end
    else
     begin
      if (E.V.Flags and FL_PARTIALGROUND) > 0 then
       E.V.Flags := E.V.Flags and not FL_PARTIALGROUND;

      E.V.GroundEntity := Trace.Ent;
      if Relink then
       SV_LinkEdict(E, True);

      Result := True;
     end;
   end
  else
   if (E.V.Flags and FL_PARTIALGROUND) = 0 then
    Result := False
   else
    begin
     VectorAdd(E.V.Origin, Move, E.V.Origin);
     if Relink then
      SV_LinkEdict(E, True);

     E.V.Flags := E.V.Flags and not FL_ONGROUND;
     Result := True;
    end;
 end;
end;

function SV_StepDirection(var E: TEdict; Yaw, Dist: Single): Boolean;
var
 Move: TVec3;
begin
Yaw := Yaw * (M_PI * 2) / 360;
Move[0] := Cos(Yaw) * Dist;
Move[1] := Sin(Yaw) * Dist;
Move[2] := 0;
Result := SV_MoveStep(E, Move, False);
SV_LinkEdict(E, True);
end;

function SV_FlyDirection(var E: TEdict; const Move: TVec3): Boolean;
begin
Result := SV_MoveStep(E, Move, False);
SV_LinkEdict(E, True);
end;

procedure SV_FixCheckBottom(var E: TEdict);
begin
E.V.Flags := E.V.Flags or FL_PARTIALGROUND;
end;

procedure SV_NewChaseDir2(var E: TEdict; const P: TVec3; Dist: Single);
var
 OldDir, TurnAround, DX, DY, D1, D2, TD: Single;
begin
OldDir := AngleMod(45 * Trunc(E.V.IdealYaw / 45));
TurnAround := AngleMod(OldDir - 180);

DX := P[0] - E.V.Origin[0];
DY := P[1] - E.V.Origin[1];

if DX > 10 then
 D1 := 0
else
 if DX < -10 then
  D1 := 180
 else
  D1 := -1;

if DY < -10 then
 D2 := 270
else
 if DY > 10 then
  D2 := 90
 else
  D2 := -1;

if (D1 <> -1) and (D2 <> -1) then
 begin
  if D1 = 0 then
   if D2 = 90 then
    TD := 45
   else
    TD := 315
  else
   if D2 = 90 then
    TD := 135
   else
    TD := 215;

  if (TD <> TurnAround) and SV_StepDirection(E, TD, Dist) then
   Exit;
 end;

if (RandomLong(0, 1) = 1) or (Abs(Trunc(DY)) > Abs(Trunc(DX))) then
 begin
  TD := D1;
  D1 := D2;
  D2 := TD;
 end;

if ((D1 <> -1) and (D1 <> TurnAround) and SV_StepDirection(E, D1, Dist)) or
   ((D2 <> -1) and (D2 <> TurnAround) and SV_StepDirection(E, D2, Dist)) or
   ((OldDir <> -1) and SV_StepDirection(E, OldDir, Dist)) then
 Exit;

if RandomLong(0, 1) = 1 then
 begin
  TD := 0;
  while TD <= 315 do
   if (TD <> TurnAround) and SV_StepDirection(E, TD, Dist) then
    Exit
   else
    TD := TD + 45;
 end
else
 begin
  TD := 315;
  while TD >= 0 do
   if (TD <> TurnAround) and SV_StepDirection(E, TD, Dist) then
    Exit
   else
    TD := TD - 45;
 end;

if (TurnAround <> -1) and SV_StepDirection(E, TurnAround, Dist) then
 Exit;

E.V.IdealYaw := OldDir;
if not SV_CheckBottom(E) then
 SV_FixCheckBottom(E);
end;

procedure SV_MoveToOrigin(var E: TEdict; const Target: TVec3; Distance: Single; MoveType: Int);
var
 Ofs: TVec3;
begin
if (E.V.Flags and (FL_ONGROUND or FL_FLY or FL_SWIM)) > 0 then
 if MoveType <> MOVE_NORMAL then
  begin
   VectorSubtract(Target, E.V.Origin, Ofs);
   if (E.V.Flags and (FL_FLY or FL_SWIM)) = 0 then
    Ofs[2] := 0;
   VectorNormalize(Ofs);
   VectorScale(Ofs, Distance, Ofs);
   SV_FlyDirection(E, Ofs);
  end
 else
  if not SV_StepDirection(E, E.V.IdealYaw, Distance) then
   SV_NewChaseDir2(E, Target, Distance);
end;



procedure SV_SetGlobalTrace(const T: TTrace);
begin
GlobalVars.TraceAllSolid := T.AllSolid;
GlobalVars.TraceStartSolid := T.StartSolid;
GlobalVars.TraceFraction := T.Fraction;
GlobalVars.TraceInWater := T.InWater;
GlobalVars.TraceInOpen := T.InOpen;
GlobalVars.TraceEndPos := T.EndPos;
GlobalVars.TracePlaneNormal := T.Plane.Normal;
GlobalVars.TracePlaneDist := T.Plane.Distance;
if T.Ent = nil then
 GlobalVars.TraceEnt := @SV.Edicts[0]
else
 GlobalVars.TraceEnt := T.Ent;
GlobalVars.TraceHitGroup := T.HitGroup;
end;

function SV_PointLeafnum(const P: TVec3): UInt;
var
 Leaf: PMLeaf;
begin
Leaf := Mod_PointInLeaf(P, SV.WorldModel^);
if Leaf <> nil then
 Result := (UInt(Leaf) - UInt(SV.WorldModel.Leafs)) div SizeOf(TMLeaf)
else
 Result := 0;
end;





procedure SV_PreRunCmd;
begin

end;

procedure SV_CopyEdictToPhysent(var PE: TPhysEnt; Index: UInt; const E: TEdict);
var
 P: PModel;
begin
PE.Origin := E.V.Origin;
PE.Info := Int32(Index);
if (Index < 1) or (Index > SVS.MaxClients) then
 PE.Player := 0
else
 begin
  SV_GetTrueOrigin(Index - 1, PE.Origin);
  PE.Player := PE.Info;
 end;

PE.Angles := E.V.Angles;
PE.StudioModel := nil;
PE.RenderMode := E.V.RenderMode;
case E.V.Solid of
 SOLID_NOT:
  if E.V.ModelIndex = 0 then
   PE.Model := nil
  else
   begin
    PE.Model := SV.PrecachedModels[E.V.ModelIndex];
    if PE.Model <> nil then
     StrLCopy(@PE.Name, @PE.Model.Name, SizeOf(PE.Name) - 1);
   end;

 SOLID_BBOX:
  begin
   PE.Model := nil;

   if E.V.ModelIndex > 0 then
    begin
     P := SV.PrecachedModels[E.V.ModelIndex];
     if P <> nil then
      begin
       if (P.Flags and $200) > 0 then
        PE.StudioModel := P;
       StrLCopy(@PE.Name, @P.Name, SizeOf(PE.Name) - 1);
      end;
    end;

   PE.MinS := E.V.MinS;
   PE.MaxS := E.V.MaxS;   
  end;

 SOLID_BSP:
  begin
   PE.Model := SV.PrecachedModels[E.V.ModelIndex];
   if PE.Model <> nil then
    StrLCopy(@PE.Name, @PE.Model.Name, SizeOf(PE.Name) - 1);
  end;

 else
  begin
   PE.Model := nil;
   PE.MinS := E.V.MinS;
   PE.MaxS := E.V.MaxS;
   if E.V.ClassName > 0 then
    StrLCopy(@PE.Name, PLChar(PRStrings + E.V.ClassName), SizeOf(PE.Name) - 1)
   else
    StrCopy(@PE.Name, '?');
  end;
 end;

PE.Skin := E.V.Skin;
PE.Frame := E.V.Frame;
PE.Solid := E.V.Solid;
PE.Sequence := E.V.Sequence;
PUInt32(@PE.Controller)^ := PUInt32(@E.V.Controller)^;
PUInt16(@PE.Blending)^ := PUInt16(@E.V.Blending)^;
PE.MoveType := E.V.MoveType;
PE.IUser1 := E.V.IUser1;
PE.IUser2 := E.V.IUser2;
PE.IUser3 := E.V.IUser3;
PE.IUser4 := E.V.IUser4;
PE.FUser1 := E.V.FUser1;
PE.FUser2 := E.V.FUser2;
PE.FUser3 := E.V.FUser3;
PE.FUser4 := E.V.FUser4;
PE.VUser1 := E.V.VUser1;
PE.VUser2 := E.V.VUser2;
PE.VUser3 := E.V.VUser3;
PE.VUser4 := E.V.VUser4;

PE.TakeDamage := 0;
PE.BloodDecal := 0;
end;

procedure SV_AddLinksToPM_(const Node: TAreaNode; const MinS, MaxS: TVec3);
var
 L: PLink;
 E: PEdict;
 Index: UInt;
 PE: PPhysEnt;
 AbsMin, AbsMax: PVec3;
begin
L := Node.SolidEdicts.Next;
while UInt(L) <> UInt(@Node.SolidEdicts) do
 begin
  E := EdictFromArea(L^);
  L := L.Next;

  if FilterGroup(E^, SVPlayer^) or (E.V.Owner = SVPlayer) or (E.V.Solid = SOLID_TRIGGER) then
   Continue;

  Index := NUM_FOR_EDICT(E^);
  PE := @PM.VisEnts[PM.NumVisEnt];
  Inc(PM.NumVisEnt);
  SV_CopyEdictToPhysent(PE^, Index, E^);

  if (E.V.Solid = SOLID_NOT) and ((E.V.Skin = 0) or (E.V.ModelIndex = 0)) then
   Continue;           

  if ((E.V.Flags and FL_MONSTERCLIP) > 0) and (E.V.Solid = SOLID_BSP) then
   Continue;

  if ((E.V.Flags and FL_CLIENT) > 0) and (E.V.Health <= 0) then
   Continue;

  if (E = SVPlayer) or ((E.V.MinS[2] = 0) and (E.V.MaxS[2] = 1)) or (Length(E.V.Size) = 0) then
   Continue;

  AbsMin := @E.V.AbsMin;
  AbsMax := @E.V.AbsMax;
  if (E.V.Flags and FL_CLIENT) > 0 then
   SV_GetTrueMinMax(Index - 1, AbsMin, AbsMax);

  if (AbsMin[0] > MaxS[0]) or (AbsMin[1] > MaxS[1]) or (AbsMin[2] > MaxS[2]) or
     (AbsMax[0] < MinS[0]) or (AbsMax[1] < MinS[1]) or (AbsMax[2] < MinS[2]) then
   Continue;

  if (E.V.Solid <> SOLID_NOT) or (E.V.Skin <> CONTENTS_LADDER) then
   begin
    if PM.NumPhysEnt >= MAX_PHYSENTS then
     begin
      DPrint('SV_AddLinksToPM_: MAX_PHYSENTS exceeded.');
      Exit;
     end;

    Move(PE^, PM.PhysEnts[PM.NumPhysEnt], SizeOf(TPhysEnt));
    Inc(PM.NumPhysEnt);
   end
  else
   begin
    if PM.NumMoveEnt >= MAX_MOVEENTS then
     begin
      DPrint('SV_AddLinksToPM_: MAX_MOVEENTS exceeded.');
      Continue;
     end;

    Move(PE^, PM.MoveEnts[PM.NumMoveEnt], SizeOf(TPhysEnt));
    Inc(PM.NumMoveEnt);
   end;
 end;

if Node.Axis <> -1 then
 begin
  if MaxS[Node.Axis] > Node.Distance then
   SV_AddLinksToPM_(Node.Children[0]^, MinS, MaxS);
  if MinS[Node.Axis] < Node.Distance then
   SV_AddLinksToPM_(Node.Children[1]^, MinS, MaxS);
 end;
end;

procedure SV_AddLinksToPM(const Node: TAreaNode; const Origin: TVec3);
var
 PE: PPhysEnt;
 I: UInt;
 MinS, MaxS: TVec3;
begin
MemSet(PM.PhysEnts[0], SizeOf(PM.PhysEnts[0]), 0);
PE := @PM.PhysEnts[0];

PE.Model := SV.WorldModel;
if SV.WorldModel <> nil then
 StrLCopy(@PE.Name, @SV.WorldModel.Name, SizeOf(PE.Name) - 1);

PE.Origin := Vec3Origin;
PE.Info := 0;
PE.Solid := SOLID_BSP;
PE.MoveType := MOVETYPE_NONE;
PE.TakeDamage := DAMAGE_YES;
PE.BloodDecal := 0;

PM.NumPhysEnt := 1;
PM.NumVisEnt := 1;
PM.NumMoveEnt := 0;
Move(PM.PhysEnts[0], PM.VisEnts[0], SizeOf(PM.VisEnts[0]));

for I := 0 to 2 do
 begin
  MinS[I] := Origin[I] - 256;
  MaxS[I] := Origin[I] + 256;
 end;

SV_AddLinksToPM_(Node, MinS, MaxS);
end;

procedure SV_PlayerRunPreThink(var E: TEdict; Time: Single);
begin
GlobalVars.Time := Time;
DLLFunctions.PlayerPreThink(E);
end;

function SV_PlayerRunThink(var E: TEdict; Sec, Time: Single): Boolean;
begin
if (E.V.Flags and (FL_KILLME or FL_DORMANT)) = 0 then
 begin
  if (E.V.NextThink <= 0) or (Time + Sec < E.V.NextThink) then
   begin
    Result := True;
    Exit;
   end;

  if E.V.NextThink < Time then
   GlobalVars.Time := Time
  else
   GlobalVars.Time := E.V.NextThink;

  E.V.NextThink := 0;
  DLLFunctions.Think(E);
 end;

if (E.V.Flags and FL_KILLME) > 0 then
 ED_Free(E);

Result := E.Free = 0;
end;

procedure SV_CheckMovingGround(var E: TEdict; Sec: Single);
var
 P: PEdict;
begin
P := E.V.GroundEntity;
if ((E.V.Flags and FL_ONGROUND) > 0) and (P <> nil) and ((P.V.Flags and FL_CONVEYOR) > 0) then
 begin
  if (E.V.Flags and FL_BASEVELOCITY) > 0 then
   VectorMA(E.V.BaseVelocity, P.V.Speed, P.V.MoveDir, E.V.BaseVelocity)
  else
   VectorScale(P.V.MoveDir, P.V.Speed, E.V.BaseVelocity);

  E.V.Flags := E.V.Flags or FL_BASEVELOCITY;
 end;

if (E.V.Flags and FL_BASEVELOCITY) = 0 then
 begin
  VectorMA(E.V.Velocity, Sec * 0.5 + 1, E.V.BaseVelocity, E.V.Velocity);
  E.V.BaseVelocity := Vec3Origin;
 end
else
 E.V.Flags := E.V.Flags and not FL_BASEVELOCITY;
end;

procedure SV_ConvertPMTrace(out Trace: TTrace; const PMTrace: TPMTrace; Ent: PEdict);
begin
Trace.AllSolid := PMTrace.AllSolid;
Trace.StartSolid := PMTrace.StartSolid;
Trace.InOpen := PMTrace.InOpen;
Trace.InWater := PMTrace.InWater;
Trace.Fraction := PMTrace.Fraction;
Trace.EndPos := PMTrace.EndPos;
Trace.Plane.Normal := PMTrace.Plane.Normal;
Trace.Plane.Distance := PMTrace.Plane.Distance;
Trace.HitGroup := PMTrace.HitGroup;
Trace.Ent := Ent;
end;

procedure SV_RunCmd(var Cmd: TUserCmd; RandomSeed: UInt32);
var
 OrigCmd: TUserCmd;
 Sec: Double;
 OldVelocity: TVec3;
 Ent: PEdict;
 I: Int;
 Trace: TTrace;
begin
if RealTime < HostClient.NextCmd then
 HostClient.LastCmd := HostClient.LastCmd + (Cmd.MSec / 1000)
else
 begin
  Move(Cmd, OrigCmd, SizeOf(OrigCmd));
  HostClient.NextCmd := 0;
  if OrigCmd.MSec > 50 then
   begin
    OrigCmd.MSec := Cmd.MSec div 2;
    SV_RunCmd(OrigCmd, RandomSeed);
    OrigCmd.MSec := Cmd.MSec div 2;
    OrigCmd.Impulse := 0;
    SV_RunCmd(OrigCmd, RandomSeed);
   end
  else
   begin
    if not HostClient.FakeClient then
     SV_SetupMove(HostClient^);

    DLLFunctions.CmdStart(SVPlayer^, Cmd, RandomSeed);
    Sec := Cmd.MSec / 1000;
    HostClient.ClientTime := HostClient.ClientTime + Sec;
    HostClient.LastCmd := HostClient.LastCmd + Sec;
    if Cmd.Impulse > 0 then
     begin
      SVPlayer.V.Impulse := Cmd.Impulse;
      if (Cmd.Impulse = 204) and (RealTime >= HostClient.FullUpdateTime) then
       begin
        SV_ForceFullClientsUpdate;
        
        if sv_fullupdateinterval.Value < 0 then
         CVar_DirectSet(sv_fullupdateinterval, '0');
        HostClient.FullUpdateTime := RealTime + sv_fullupdateinterval.Value;
       end;
     end;

    SVPlayer.V.CLBaseVelocity := Vec3Origin;
    SVPlayer.V.Button := Cmd.Buttons;
    SV_CheckMovingGround(SVPlayer^, Sec);
    PM.OldAngles := SVPlayer.V.VAngle;
    if SVPlayer.V.FixAngle = 0 then
     SVPlayer.V.VAngle := Cmd.ViewAngles;

    SV_PlayerRunPreThink(SVPlayer^, HostClient.ClientTime);
    SV_PlayerRunThink(SVPlayer^, Sec, HostClient.ClientTime);
    if Length(SVPlayer.V.BaseVelocity) > 0 then
     SVPlayer.V.CLBaseVelocity := SVPlayer.V.BaseVelocity;

    PM.Server := 1;
    PM.Multiplayer := Int32(SVS.MaxClients > 1);
    PM.Time := 1000 * HostClient.ClientTime;
    PM.UseHull := Int((SVPlayer.V.Flags and FL_DUCKING) > 0);
    PM.MaxSpeed := sv_maxspeed.Value;
    PM.ClientMaxSpeed := SVPlayer.V.MaxSpeed;
    PM.DuckTime := SVPlayer.V.DuckTime;
    PM.InDuck := SVPlayer.V.InDuck;
    PM.TimeStepSound := SVPlayer.V.TimeStepSound;
    PM.StepLeft := SVPlayer.V.StepLeft;
    PM.FallVelocity := SVPlayer.V.FallVelocity;
    PM.SwimTime := SVPlayer.V.SwimTime;
    PM.OldButtons := SVPlayer.V.OldButtons;

    StrLCopy(@PM.PhysInfo, @HostClient.PhysInfo, SizeOf(PM.PhysInfo) - 1);
    PM.Velocity := SVPlayer.V.Velocity;
    PM.MoveDir := SVPlayer.V.MoveDir;
    PM.Angles := SVPlayer.V.VAngle;
    PM.BaseVelocity := SVPlayer.V.BaseVelocity;
    PM.ViewOfs := SVPlayer.V.ViewOfs;
    PM.PunchAngle := SVPlayer.V.PunchAngle;
    PM.DeadFlag := SVPlayer.V.DeadFlag;
    PM.Effects := SVPlayer.V.Effects;
    PM.Gravity := SVPlayer.V.Gravity;
    PM.Friction := SVPlayer.V.Friction;
    PM.Spectator := 0;
    PM.WaterJumpTime := SVPlayer.V.TeleportTime;
    Move(OrigCmd, PM.Cmd, SizeOf(PM.Cmd));
    PM.Dead := Int32(SVPlayer.V.Health <= 0);
    PM.MoveType := SVPlayer.V.MoveType;
    PM.Flags := SVPlayer.V.Flags;
    PM.PlayerIndex := NUM_FOR_EDICT(SVPlayer^) - 1;
    PM.IUser1 := SVPlayer.V.IUser1;
    PM.IUser2 := SVPlayer.V.IUser2;
    PM.IUser3 := SVPlayer.V.IUser3;
    PM.IUser4 := SVPlayer.V.IUser4;
    PM.FUser1 := SVPlayer.V.FUser1;
    PM.FUser2 := SVPlayer.V.FUser2;
    PM.FUser3 := SVPlayer.V.FUser3;
    PM.FUser4 := SVPlayer.V.FUser4;
    PM.VUser1 := SVPlayer.V.VUser1;
    PM.VUser2 := SVPlayer.V.VUser2;
    PM.VUser3 := SVPlayer.V.VUser3;
    PM.VUser4 := SVPlayer.V.VUser4;
    PM.Origin := SVPlayer.V.Origin;

    SV_AddLinksToPM(SVAreaNodes[0], PM.Origin);
    PM.FrameTime := Sec;
    PM.RunFuncs := 1;
    PM.PM_PlaySound := @PM_SV_PlaySound;
    PM.PM_TraceTexture := @PM_SV_TraceTexture;
    PM.PM_PlaybackEventFull := @PM_SV_PlaybackEventFull;
    DLLFunctions.PM_Move(PM^, 1);

    SVPlayer.V.DeadFlag := PM.DeadFlag;
    SVPlayer.V.Effects := PM.Effects;
    SVPlayer.V.TeleportTime := PM.WaterJumpTime;
    SVPlayer.V.WaterLevel := PM.WaterLevel;
    SVPlayer.V.WaterType := PM.WaterType;
    SVPlayer.V.Flags := PM.Flags;
    SVPlayer.V.Friction := PM.Friction;
    SVPlayer.V.MoveType := PM.MoveType;
    SVPlayer.V.MaxSpeed := PM.ClientMaxSpeed;
    SVPlayer.V.StepLeft := PM.StepLeft;
    SVPlayer.V.ViewOfs := PM.ViewOfs;
    SVPlayer.V.MoveDir := PM.MoveDir;
    SVPlayer.V.PunchAngle := PM.PunchAngle;
    if PM.OnGround = -1 then
     SVPlayer.V.Flags := SVPlayer.V.Flags and not FL_ONGROUND
    else
     begin
      SVPlayer.V.Flags := SVPlayer.V.Flags or FL_ONGROUND;
      SVPlayer.V.GroundEntity := EDICT_NUM(PM.PhysEnts[PM.OnGround].Info);
     end;

    SVPlayer.V.Origin := PM.Origin;
    SVPlayer.V.Velocity := PM.Velocity;
    SVPlayer.V.BaseVelocity := PM.BaseVelocity;
    if SVPlayer.V.FixAngle = 0 then
     begin
      SVPlayer.V.VAngle := PM.Angles;
      SVPlayer.V.Angles := PM.Angles;
      SVPlayer.V.Angles[0] := -SVPlayer.V.Angles[0] / 3; 
     end;

    SVPlayer.V.InDuck := PM.InDuck;
    SVPlayer.V.DuckTime := Trunc(PM.DuckTime);
    SVPlayer.V.TimeStepSound := PM.TimeStepSound;
    SVPlayer.V.FallVelocity := PM.FallVelocity;
    SVPlayer.V.SwimTime := Trunc(PM.SwimTime);
    SVPlayer.V.OldButtons := PM.Cmd.Buttons;
    SVPlayer.V.IUser1 := PM.IUser1;
    SVPlayer.V.IUser2 := PM.IUser2;
    SVPlayer.V.IUser3 := PM.IUser3;
    SVPlayer.V.IUser4 := PM.IUser4;
    SVPlayer.V.FUser1 := PM.FUser1;
    SVPlayer.V.FUser2 := PM.FUser2;
    SVPlayer.V.FUser3 := PM.FUser3;
    SVPlayer.V.FUser4 := PM.FUser4;
    SVPlayer.V.VUser1 := PM.VUser1;
    SVPlayer.V.VUser2 := PM.VUser2;
    SVPlayer.V.VUser3 := PM.VUser3;
    SVPlayer.V.VUser4 := PM.VUser4;

    SetMinMaxSize(SVPlayer^, PlayerMinS[PM.UseHull], PlayerMaxS[PM.UseHull]);
    if HostClient.Entity.V.Solid <> 0 then
     begin
      SV_LinkEdict(SVPlayer^, True);
      OldVelocity := SVPlayer.V.Velocity;
      for I := 0 to PM.NumTouch - 1 do
       begin
        Ent := EDICT_NUM(PM.PhysEnts[PM.TouchIndex[I].Ent].Info);
        SV_ConvertPMTrace(Trace, PM.TouchIndex[I], Ent);
        SVPlayer.V.Velocity := PM.TouchIndex[I].DeltaVelocity;
        SV_Impact(Ent^, SVPlayer^, Trace);
       end;
      SVPlayer.V.Velocity := OldVelocity;
     end;

    GlobalVars.Time := HostClient.ClientTime;
    GlobalVars.FrameTime := Sec;
    DLLFunctions.PlayerPostThink(SVPlayer^);
    DLLFunctions.CmdEnd(SVPlayer^);
    if not HostClient.FakeClient then
     SV_RestoreMove(HostClient^);
   end;
 end;
end;

function SV_CalcClientTime(const C: TClient): Double;
var
 I: Int;
 Count, Samples, MaxSamples: UInt;
 P: PClientFrame;
 TotalPing, MinPing, MaxPing: Single;
begin
if sv_unlagsamples.Value < 1 then
 CVar_DirectSet(sv_unlagsamples, '1');

Samples := Trunc(sv_unlagsamples.Value);

if SVUpdateBackup < MAX_UNLAG_SAMPLES then
 MaxSamples := SVUpdateBackup
else
 MaxSamples := MAX_UNLAG_SAMPLES;

if Samples > MaxSamples then
 Samples := MaxSamples;

Count := 0;
TotalPing := 0;
for I := 0 to Samples - 1 do
 begin
  P := @C.Frames[SVUpdateMask and (C.Netchan.IncomingAcknowledged - I)];
  if P.PingTime > 0 then
   begin
    Inc(Count);
    TotalPing := TotalPing + P.PingTime;
   end;
 end;

if Count = 0 then
 Result := 0
else
 begin
  MinPing := 9999;
  MaxPing := -9999;

  if SVUpdateBackup > 4 then
   MaxSamples := 4
  else
   MaxSamples := SVUpdateBackup;

  for I := 0 to MaxSamples - 1 do
   begin
    P := @C.Frames[SVUpdateMask and (C.Netchan.IncomingAcknowledged - I)];
    if P.PingTime > 0 then
     begin
      if P.PingTime < MinPing then
       MinPing := P.PingTime;
      if P.PingTime > MaxPing then
       MaxPing := P.PingTime;
     end;
   end;

  if (MaxPing < MinPing) or (Abs(MaxPing - MinPing) <= 0.2) then
   Result := TotalPing / Count
  else
   Result := 0;
 end;
end;

procedure SV_ComputeLatency(var C: TClient);
begin
C.Latency := SV_CalcClientTime(C);
end;

function SV_UnlagCheckTeleport(const OldPos, NewPos: TVec3): Boolean;
begin
Result := (Abs(OldPos[0] - NewPos[0]) > 128) or
          (Abs(OldPos[1] - NewPos[1]) > 128) or
          (Abs(OldPos[2] - NewPos[2]) > 128);
end;

procedure SV_GetTrueOrigin(Index: UInt; out Origin: TVec3);
begin
if HostClient.LW and HostClient.LC and (sv_unlag.Value <> 0) and (SVS.MaxClients > 1) and
   HostClient.Active and (Index < SVS.MaxClients) and
   TruePositions[Index].Active and TruePositions[Index].UpdatePos then
 Origin := TruePositions[Index].TrueOrigin;
end;

procedure SV_GetTrueMinMax(Index: UInt; out MinS, MaxS: PVec3);
begin
if HostClient.LW and HostClient.LC and (sv_unlag.Value <> 0) and (SVS.MaxClients > 1) and
   HostClient.Active and (Index < SVS.MaxClients) and
   TruePositions[Index].Active and TruePositions[Index].UpdatePos then
 begin
  MinS := @TruePositions[Index].MinS;
  MaxS := @TruePositions[Index].MaxS;
 end;
end;

function SV_FindEntInPack(Index: UInt; const Pack: TPacketEntities): PEntityState;
var
 I: Int;
begin
for I := 0 to Pack.NumEnts - 1 do
 if Pack.Ents[I].Number = Index then
  begin
   Result := @Pack.Ents[I];
   Exit;
  end;

Result := nil;
end;

procedure SV_SetupMove(var C: TClient);
var
 I, J: Int;
 P: PClient;
 TP: PCachedMove;
 F, F2, UnlagTime: Double;
 Frame, NewFrame: PClientFrame;
 ES, P2: PEntityState;
 B: Boolean;
 Scale: Single;
 VOut, V: TVec3;
begin
MemSet(TruePositions, SizeOf(TruePositions), 0);
if (DLLFunctions.AllowLagCompensation = 0) or (sv_unlag.Value = 0) or not C.LW or not C.LC or
   (SVS.MaxClients <= 1) or not C.Active then
 begin
  NoFind := True;
  Exit;
 end
else
 NoFind := False;

for I := 0 to SVS.MaxClients - 1 do
 begin
  P := @SVS.Clients[I];
  if (P <> @C) and P.Active then
   begin
    TP := @TruePositions[I];
    TP.Active := True;
    TP.TrueOrigin := P.Entity.V.Origin;
    TP.MinS := P.Entity.V.AbsMin;
    TP.MaxS := P.Entity.V.AbsMax;
   end;
 end;

if C.Latency <= 1.5 then
 F := C.Latency
else
 F := 1.5;

if sv_maxunlag.Value <> 0 then
 begin
  if sv_maxunlag.Value < 0 then
   CVar_DirectSet(sv_maxunlag, '0');
  if F > sv_maxunlag.Value then
   F := sv_maxunlag.Value;
 end;

F2 := C.UserCmd.LerpMSec / 1000;
if F2 > 0.1 then
 F2 := 0.1;

if F2 < C.UpdateRate then
 F2 := C.UpdateRate;

UnlagTime := RealTime - F - F2 + sv_unlagpush.Value;
if UnlagTime > RealTime then
 UnlagTime := RealTime;

B := False;
Frame := nil;
NewFrame := nil;
for I := 0 to SVUpdateBackup - 1 do
 begin
  Frame := @C.Frames[SVUpdateMask and (C.Netchan.OutgoingSequence - I - 1)];
  for J := 0 to Frame.Pack.NumEnts - 1 do
   begin
    ES := @Frame.Pack.Ents[J];
    if (ES.Number >= 1) and (ES.Number <= SVS.MaxClients) then
     begin
      TP := @TruePositions[ES.Number - 1];
      if not TP.NoInterp then
       begin
        if (ES.Health <= 0) or ((ES.Effects and EF_NOINTERP) > 0) then
         TP.NoInterp := True;

        if not TP.FirstFrame then
         TP.FirstFrame := True
        else
         if SV_UnlagCheckTeleport(ES.Origin, TP.ClientOrigin) then
          TP.NoInterp := True;

        TP.ClientOrigin := ES.Origin;
       end;
     end;
   end;

  if UnlagTime > Frame.SentTime then
   begin
    B := True;
    Break;
   end;

  NewFrame := Frame;
 end;

if not B or (UnlagTime - Frame.SentTime > 1) then
 begin
  MemSet(TruePositions, SizeOf(TruePositions), 0);
  NoFind := True;
  Exit;
 end;

if NewFrame = nil then
 begin
  NewFrame := Frame;
  Scale := 0;
 end
else
 begin
  F := NewFrame.SentTime - Frame.SentTime;
  if F = 0 then
   Scale := 0
  else
   begin
    Scale := (UnlagTime - Frame.SentTime) / F;
    if Scale > 1 then
     Scale := 1
    else
     if Scale < 0 then
      Scale := 0;
   end;
 end;

for I := 0 to Frame.Pack.NumEnts - 1 do
 begin
  ES := @Frame.Pack.Ents[I];
  if (ES.Number >= 1) and (ES.Number <= SVS.MaxClients) then
   begin
    P := @SVS.Clients[ES.Number - 1];
    if (P <> @C) and P.Active then
     begin
      TP := @TruePositions[ES.Number - 1];
      if not TP.NoInterp then
       if TP.Active then
        begin
         P2 := SV_FindEntInPack(ES.Number, NewFrame.Pack);
         if P2 <> nil then
          begin
           VectorSubtract(P2.Origin, ES.Origin, V);
           VectorMA(ES.Origin, Scale, V, VOut);
          end
         else
          VOut := ES.Origin;

         TP.OldOrigin := VOut;
         TP.CurrentOrigin := VOut;

         if not VectorCompare(VOut, P.Entity.V.Origin) then
          begin
           P.Entity.V.Origin := VOut;
           SV_LinkEdict(P.Entity^, False);
           TP.UpdatePos := True;
          end;
        end
       else
        DPrint(['SV_SetupMove: Tried to store position offset of invalid player #', I, ' ("', PLChar(@P.NetName), '").']);
     end;
   end;
 end;
end;

procedure SV_RestoreMove(var C: TClient);
var
 I: Int;
 P: PClient;
 TP: PCachedMove;
begin
if NoFind then
 begin
  NoFind := False;
  Exit;
 end;

if (DLLFunctions.AllowLagCompensation = 0) or (sv_unlag.Value = 0) or not C.LW or not C.LC or
   (SVS.MaxClients <= 1) or not C.Active then
 Exit;

for I := 0 to SVS.MaxClients - 1 do
 begin
  P := @SVS.Clients[I];
  TP := @TruePositions[I];
  if (P <> @C) and P.Active and not VectorCompare(TP.OldOrigin, TP.TrueOrigin) and TP.UpdatePos then
   if not TP.Active then
    DPrint(['SV_RestoreMove: Tried to restore inactive player #', I, ' ("', PLChar(@P.NetName), '").'])
   else
    if VectorCompare(TP.CurrentOrigin, P.Entity.V.Origin) then
     begin
      P.Entity.V.Origin := TP.TrueOrigin;
      SV_LinkEdict(P.Entity^, False);
     end;
 end;
end;

procedure SV_AddToFatPVS(const Origin: TVec3; Node: PMNode);
var
 Plane: PMPlane;
 F: Single;
 PVS: PByte;
 I: UInt;
begin
while Node.Contents >= 0 do
 begin
  Plane := Node.Plane;
  F := DotProduct(Origin, Plane.Normal) - Plane.Distance;
  if F > 8 then
   Node := Node.Children[0]
  else
   if F < -8 then
    Node := Node.Children[1]
   else
    begin
     SV_AddToFatPVS(Origin, Node.Children[0]);
     Node := Node.Children[1];
    end;
 end;

if Node.Contents <> CONTENTS_SOLID then
 begin
  PVS := Mod_LeafPVS(Pointer(Node), SV.WorldModel);
  if FatPVSBytes > 0 then
   for I := 0 to FatPVSBytes - 1 do
    FatPVS[I] := FatPVS[I] or PByte(UInt(PVS) + I)^;
 end;
end;

function SV_FatPVS(const Origin: TVec3): PByte;
begin
FatPVSBytes := (SV.WorldModel.NumLeafs + 31) shr 3;
MemSet(FatPVS, FatPVSBytes, 0);
SV_AddToFatPVS(Origin, @SV.WorldModel.Nodes[0]);
Result := @FatPVS;
end;

procedure SV_AddToFatPAS(const Origin: TVec3; Node: PMNode);
var
 Plane: PMPlane;
 F: Single;
 PAS: PByte;
 I: UInt;
begin
while Node.Contents >= 0 do
 begin
  Plane := Node.Plane;
  F := DotProduct(Origin, Plane.Normal) - Plane.Distance;
  if F > 8 then
   Node := Node.Children[0]
  else
   if F < -8 then
    Node := Node.Children[1]
   else
    begin
     SV_AddToFatPAS(Origin, Node.Children[0]);
     Node := Node.Children[1];
    end;
 end;

if Node.Contents <> CONTENTS_SOLID then
 begin
  PAS := CM_LeafPAS((UInt(Node) - UInt(SV.WorldModel.Leafs)) div SizeOf(TMLeaf));
  if FatPASBytes > 0 then
   for I := 0 to FatPASBytes - 1 do
    FatPAS[I] := FatPAS[I] or PByte(UInt(PAS) + I)^;
 end;
end;

function SV_FatPAS(const Origin: TVec3): PByte;
begin
FatPASBytes := (SV.WorldModel.NumLeafs + 31) shr 3;
MemSet(FatPAS, FatPASBytes, 0);
SV_AddToFatPAS(Origin, @SV.WorldModel.Nodes[0]);
Result := @FatPAS;
end;

procedure PM_SV_PlaySound(Channel: Int32; Sample: PLChar; Volume, Attn: Single; Flags, Pitch: Int32); cdecl;
begin
SV_StartSound(True, HostClient.Entity^, Channel, Sample, Trunc(Volume * 255), Attn, Flags, Pitch);
end;

function PM_SV_TraceTexture(Ground: Int32; const VStart, VEnd: TVec3): PLChar; cdecl;
var
 PE: PPhysEnt;
begin
if (Ground >= 0) and (Ground < PM.NumPhysEnt) then
 begin
  PE := @PM.PhysEnts[Ground];
  if (PE.Model <> nil) and (PE.Info >= 0) and (UInt(PE.Info) < SV.MaxEdicts) then
   begin
    Result := SV_TraceTexture(@SV.Edicts[PE.Info], VStart, VEnd);
    Exit;
   end;
 end;

Result := nil;
end;

procedure PM_SV_PlaybackEventFull(Flags, ClientIndex: Int32; EventIndex: UInt16; Delay: Single; const Origin, Angles: TVec3; FParam1, FParam2: Single; IParam1, IParam2, BParam1, BParam2: Int32); cdecl;
begin
EV_SV_Playback(Flags or FEV_NOTHOST, ClientIndex, EventIndex, Delay, Origin, Angles, FParam1, FParam2, IParam1, IParam2, BParam1, BParam2);
end;

procedure SV_SetMoveVars;
begin
MoveVars.Gravity := sv_gravity.Value;
MoveVars.StopSpeed := sv_stopspeed.Value;
MoveVars.MaxSpeed := sv_maxspeed.Value;
MoveVars.SpectatorMaxSpeed := sv_spectatormaxspeed.Value;
MoveVars.Accelerate := sv_accelerate.Value;
MoveVars.AirAccelerate := sv_airaccelerate.Value;
MoveVars.WaterAccelerate := sv_wateraccelerate.Value;
MoveVars.Friction := sv_friction.Value;
MoveVars.EdgeFriction := edgefriction.Value;
MoveVars.WaterFriction := sv_waterfriction.Value;
MoveVars.EntGravity := 1;
MoveVars.Bounce := sv_bounce.Value;
MoveVars.StepSize := sv_stepsize.Value;
MoveVars.MaxVelocity := sv_maxvelocity.Value;
MoveVars.ZMax := sv_zmax.Value;
MoveVars.WaveHeight := sv_wateramp.Value;
MoveVars.Footsteps := Trunc(mp_footsteps.Value);
StrLCopy(@MoveVars.SkyName, sv_skyname.Data, SizeOf(MoveVars.SkyName) - 1);
MoveVars.RollAngle := sv_rollangle.Value;
MoveVars.RollSpeed := sv_rollspeed.Value;
MoveVars.SkyColorR := sv_skycolor_r.Value;
MoveVars.SkyColorG := sv_skycolor_g.Value;
MoveVars.SkyColorB := sv_skycolor_b.Value;
MoveVars.SkyVecX := sv_skyvec_x.Value;
MoveVars.SkyVecY := sv_skyvec_y.Value;
MoveVars.SkyVecZ := sv_skyvec_z.Value;
end;

procedure SV_QueryMovevarsChanged;
var
 I: Int;
 C: PClient;
begin
if (sv_maxspeed.Value <> MoveVars.MaxSpeed) or
   (sv_gravity.Value <> MoveVars.Gravity) or
   (sv_stopspeed.Value <> MoveVars.StopSpeed) or
   (sv_spectatormaxspeed.Value <> MoveVars.SpectatorMaxSpeed) or
   (sv_accelerate.Value <> MoveVars.Accelerate) or
   (sv_airaccelerate.Value <> MoveVars.AirAccelerate) or
   (sv_wateraccelerate.Value <> MoveVars.WaterAccelerate) or
   (sv_friction.Value <> MoveVars.Friction) or
   (edgefriction.Value <> MoveVars.EdgeFriction) or
   (sv_waterfriction.Value <> MoveVars.WaterFriction) or
   (MoveVars.EntGravity <> 1) or
   (sv_bounce.Value <> MoveVars.Bounce) or
   (sv_stepsize.Value <> MoveVars.StepSize) or
   (sv_maxvelocity.Value <> MoveVars.MaxVelocity) or
   (sv_zmax.Value <> MoveVars.ZMax) or
   (sv_wateramp.Value <> MoveVars.WaveHeight) or
   (mp_footsteps.Value <> MoveVars.Footsteps) or
   (sv_rollangle.Value <> MoveVars.RollAngle) or
   (sv_rollspeed.Value <> MoveVars.RollSpeed) or
   (sv_skycolor_r.Value <> MoveVars.SkyColorR) or
   (sv_skycolor_g.Value <> MoveVars.SkyColorG) or
   (sv_skycolor_b.Value <> MoveVars.SkyColorB) or
   (sv_skyvec_x.Value <> MoveVars.SkyVecX) or
   (sv_skyvec_y.Value <> MoveVars.SkyVecY) or
   (sv_skyvec_z.Value <> MoveVars.SkyVecZ) or
   (StrLComp(sv_skyname.Data, @MoveVars.SkyName, SizeOf(MoveVars.SkyName) - 1) <> 0) then
 begin
  SV_SetMoveVars;
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if (C.Active or C.Spawned or C.Connected) and not C.FakeClient then
     SV_WriteMoveVarsToClient(C.Netchan.NetMessage);
   end;
 end;
end;

procedure SV_CheckCmdTimes;
var
 I: Int;
 C: PClient;
 F: Double;
begin
if sv_cmdcheckinterval.Value <= 0.05 then
 CVar_DirectSet(sv_cmdcheckinterval, '0.05');

if RealTime >= LastTimeReset then
 begin
  LastTimeReset := RealTime + sv_cmdcheckinterval.Value;
  for I := 0 to SVS.MaxClients - 1 do
   begin
    C := @SVS.Clients[I];
    if C.Active and C.Connected then
     begin
      if C.FirstCmd = 0 then
       C.FirstCmd := RealTime;

      F := C.FirstCmd + C.LastCmd - RealTime;
      if F > clockwindow.Value then
       begin
        C.NextCmd := clockwindow.Value + RealTime;
        C.LastCmd := RealTime - C.FirstCmd;
       end
      else
       if F < -clockwindow.Value then
        C.LastCmd := RealTime - C.FirstCmd;
     end;
   end;
 end;
end;

procedure SV_EstablishTimeBase(var C: TClient; Cmd: PUserCmdArray; Drop, Backup, NumCmds: UInt);
var
 I: Int;
 Time: Double;
begin
Time := 0;
if Drop < 24 then
 begin
  for I := Drop - 1 downto NumCmds do
   Time := Time + C.UserCmd.MSec / 1000;

  if Drop > NumCmds then
   Drop := Drop - (Drop - NumCmds);

  for I := Drop - 1 downto 0 do
   Time := Time + Cmd[UInt(I) + NumCmds - 1].MSec / 1000;
 end;

for I := NumCmds - 1 downto 0 do
 Time := Time + Cmd[I].MSec / 1000;

C.ClientTime := HostFrameTime + SV.Time - Time;
end;

procedure SV_ParseMove(var C: TClient);
var
 UserCmds: array[0..CMD_MAXBACKUP - 1] of TUserCmd;
 AdrBuf: array[1..64] of LChar;
 UserCmdNil: TUserCmd;
 Frame: PClientFrame;
 Flags, Size, Backup, Cmds, Total, RC: UInt;
 Checksum: Byte;
 Loss: Single;
 F: Double;
 I: Int;
 P, P2: PUserCmd;
begin
if AlreadyMoved then
 MSG_BadRead := True
else
 begin
  AlreadyMoved := True;
  Frame := @HostClient.Frames[SVUpdateMask and HostClient.Netchan.IncomingAcknowledged];
  MemSet(UserCmdNil, SizeOf(UserCmdNil), 0);
  RC := MSG_ReadCount + 1;

  Size := MSG_ReadByte;
  Checksum := MSG_ReadByte;
  COM_UnMunge(Pointer(UInt(NetMessage.Data) + RC + 1), Size, HostClient.Netchan.IncomingSequence);

  Flags := MSG_ReadByte;
  Loss := Flags and $7F;
  C.VoiceLoopback := (Flags shr 7) > 0;

  Backup := MSG_ReadByte;
  Cmds := MSG_ReadByte;
  Total := Backup + Cmds;
  
  NetDrop := NetDrop + 1 - Cmds;
  if Total > CMD_MAXBACKUP then
   begin
    Print(['SV_ParseMove: Too many commands (', Total, ') sent for user "', PLChar(@HostClient.NetName), '" (', NET_AdrToString(HostClient.Netchan.Addr, AdrBuf, SizeOf(AdrBuf)), ').']);
    SV_DropClient(HostClient^, False, ['Sent ', Total, ' user commands, expected no more than CMD_MAXBACKUP (', CMD_MAXBACKUP - 1, ').']);
    MSG_BadRead := True;
   end
  else
   begin
    P := @UserCmdNil;
    for I := Total - 1 downto 0 do
     begin
      P2 := @UserCmds[I];
      MSG_ReadUserCmd(P2, P);
      P := P2;
     end;

    if SV.Active and (HostClient.Active or HostClient.Spawned) then
     if MSG_BadRead then
      Print(['SV_ParseMove: Client "', PLChar(@HostClient.NetName), '" (', NET_AdrToString(HostClient.Netchan.Addr, AdrBuf, SizeOf(AdrBuf)), ') sent a bogus command packet.'])
     else
     { if Byte(COM_BlockSequenceCRCByte(Pointer(UInt(NetMessage.Data) + RC + 1), MSG_ReadCount - RC - 1, HostClient.Netchan.IncomingSequence)) <> Checksum then
       begin
        Print(['SV_ParseMove: Failed command checksum for client "', PLChar(@HostClient.NetName), '" (', NET_AdrToString(HostClient.Netchan.Addr, AdrBuf, SizeOf(AdrBuf)), ').']);
        MSG_BadRead := True;
       end
      else}
       begin
        HostClient.PacketLoss := Loss;
        if SV.Paused or ((SVPlayer.V.Flags and FL_FROZEN) > 0) then
         begin
          for I := 0 to Cmds - 1 do
           begin
            P := @UserCmds[I];
            P.MSec := 0;
            P.ViewAngles := SVPlayer.V.VAngle;
            P.ForwardMove := 0;
            P.SideMove := 0;
            P.UpMove := 0;
            P.Buttons := 0;
            if (SVPlayer.V.Flags and FL_FROZEN) > 0 then
             P.Impulse := 0;
           end;
          NetDrop := 0; 
         end
        else
         SVPlayer.V.VAngle := UserCmds[0].ViewAngles;
         
        SVPlayer.V.Button := UserCmds[0].Buttons;
        SVPlayer.V.LightLevel := UserCmds[0].LightLevel;
        SV_EstablishTimeBase(HostClient^, @UserCmds, NetDrop, Backup, Cmds);
        SV_PreRunCmd;

        if NetDrop > 24 then
         begin
          while NetDrop > Backup do
           begin
            SV_RunCmd(C.UserCmd, 0);
            Dec(NetDrop);
           end;

          while NetDrop > 0 do
           begin
            I := Cmds + NetDrop - 1;
            SV_RunCmd(UserCmds[I], HostClient.Netchan.IncomingSequence - I);
            Dec(NetDrop);           
           end;
         end;

        for I := Cmds - 1 downto 0 do
         SV_RunCmd(UserCmds[I], HostClient.Netchan.IncomingSequence - I);

        HostClient.UserCmd := UserCmds[0];
        F := Frame.PingTime - HostClient.UserCmd.MSec * 0.5 / 1000;
        if F < 0 then
         Frame.PingTime := 0
        else
         Frame.PingTime := F;

        F := HostFrameTime + SV.Time;
        if SVPlayer.V.AnimTime > F then
         SVPlayer.V.AnimTime := F;
       end;
   end;  
 end;
end;

end.
