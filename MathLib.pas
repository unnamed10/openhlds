unit MathLib;

{$I HLDS.inc}

interface

uses Default, SDK;

const M_PI = 3.14159265358979323846;

type
 PMatrix3x3 = ^TMatrix3x3;
 TMatrix3x3 = array[1..3] of array[1..3] of Single;

 PMatrix3x4 = ^TMatrix3x4;
 TMatrix3x4 = array[1..3] of array[1..4] of Single;

function AngleMod(X: Single): Single;

function BoxOnPlaneSide(const MinSize, MaxSize: TVec3; Plane: PMPlane): Int;

procedure AngleVectors(const Angles: TVec3; Fwd, Right, Up: PVec3);
procedure AngleVectorsTranspose(const Angles: TVec3; Fwd, Right, Up: PVec3);
procedure AngleMatrix(const Angles: TVec3; Matrix: PMatrix3x4);
procedure AngleIMatrix(const Angles: TVec3; Matrix: PMatrix3x4);

procedure NormalizeAngles(var Angles: TVec3);
procedure InterpolateAngles(var VStart, VEnd: TVec3; out VOut: TVec3; Fraction: Single);

procedure VectorTransform(const VIn: TVec3; Matrix: PMatrix3x4; out VOut: TVec3);

function VectorCompare(const Vec1, Vec2: TVec3): Boolean;
procedure VectorMA(const Vec1: TVec3; Scale: Single; const Vec2: TVec3; out VOut: TVec3);
function DotProduct(const X, Y: TVec3): Single;
procedure VectorSubtract(const Vec1, Vec2: TVec3; out VOut: TVec3);
procedure VectorAdd(const Vec1, Vec2: TVec3; out VOut: TVec3);
procedure VectorCopy(const VIn: TVec3; out VOut: TVec3);
procedure CrossProduct(const Vec1, Vec2: TVec3; out VOut: TVec3);
function Length(const VIn: TVec3): Single;
function VectorNormalize(var VOut: TVec3): Single;
procedure VectorInverse(var VOut: TVec3);
procedure VectorSet(out VOut: TVec3; Value: Single);
procedure VectorScale(const VIn: TVec3; Scale: Single; out VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}

function Q_log2(X: Int): Int;

procedure VectorMatrix(const Fwd: TVec3; var Right, Up: TVec3);
procedure VectorAngles(const Fwd: TVec3; out Angles: TVec3);

procedure R_ConcatRotations(In1, In2, Out1: PMatrix3x3);
procedure R_ConcatTransforms(In1, In2, Out1: PMatrix3x4);

procedure FloorDivMod(X, Denom: Double; Quotient, Remainder: PInt);
function Invert24To16(X: Int): Int;

procedure AngleQuaternion(const Angles: TVec3; out Q: TVec4);
procedure QuaternionSlerp(const P: TVec4; var Q: TVec4; T: Single; out QT: TVec4);
procedure QuaternionMatrix(const Q: TVec4; Matrix: PVec4);

const
 Vec3Origin: TVec3 = (0, 0, 0);

implementation

uses SysMain;

function AngleMod(X: Single): Single;
begin
Result := (Trunc(X * (65536 / 360)) and $FFFF) * (360 / 65536);
end;

function BoxOnPlaneSide(const MinSize, MaxSize: TVec3; Plane: PMPlane): Int;
var
 DX, DY: Single;
begin
case Plane.SignBits of
 0:
  begin
   DX := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MaxSize[2];
   DY := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MinSize[2];
  end;
 1:
  begin
   DX := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MaxSize[2];
   DY := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MinSize[2];
  end;
 2:
  begin
   DX := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MaxSize[2];
   DY := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MinSize[2];
  end;
 3:
  begin
   DX := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MaxSize[2];
   DY := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MinSize[2];
  end;
 4:
  begin
   DX := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MinSize[2];
   DY := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MaxSize[2];
  end;
 5:
  begin
   DX := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MinSize[2];
   DY := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MaxSize[2];
  end;
 6:
  begin
   DX := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MinSize[2];
   DY := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MaxSize[2];
  end;
 7:
  begin
   DX := Plane.Normal[0] * MinSize[0] + Plane.Normal[1] * MinSize[1] + Plane.Normal[2] * MinSize[2];
   DY := Plane.Normal[0] * MaxSize[0] + Plane.Normal[1] * MaxSize[1] + Plane.Normal[2] * MaxSize[2];
  end;
 else
  begin
   DX := 0;
   DY := 0;
   Sys_Error('BoxOnPlaneSide: Bad signbits.');
  end;
end;

Result := Int(DX >= Plane.Distance) + (Int(DY < Plane.Distance) shl 1);
end;

procedure AngleVectors(const Angles: TVec3; Fwd, Right, Up: PVec3);
var
 Angle, SP, CP, SY, CY, SR, CR: Single;
begin
Angle := Angles[0] * (M_PI * 2 / 360);
SP := Sin(Angle);
CP := Cos(Angle);
Angle := Angles[1] * (M_PI * 2 / 360);
SY := Sin(Angle);
CY := Cos(Angle);
Angle := Angles[2] * (M_PI * 2 / 360);
SR := Sin(Angle);
CR := Cos(Angle);

if Fwd <> nil then
 begin
  Fwd[0] := CP * CY;
  Fwd[1] := CP * SY;
  Fwd[2] := -SP;
 end;

if Right <> nil then
 begin
  Right[0] := CR * SY - SR * SP * CY;
  Right[1] := -(CR * CY + SR * SP * SY);
  Right[2] := -(SR * CP);
 end;

if Up <> nil then
 begin
  Up[0] := CR * SP * CY + SR * SY;
  Up[1] := CR * SP * SY - SR * CY;
  Up[2] := CR * CP;
 end;
end;

procedure AngleVectorsTranspose(const Angles: TVec3; Fwd, Right, Up: PVec3);
var
 Angle, SP, CP, SY, CY, SR, CR: Single;
begin
Angle := Angles[0] * (M_PI * 2 / 360);
SP := Sin(Angle);
CP := Cos(Angle);
Angle := Angles[1] * (M_PI * 2 / 360);
SY := Sin(Angle);
CY := Cos(Angle);
Angle := Angles[2] * (M_PI * 2 / 360);
SR := Sin(Angle);
CR := Cos(Angle);

if Fwd <> nil then
 begin
  Fwd[0] := CP * CY;
  Fwd[1] := SR * SP * CY - CR * SY;
  Fwd[2] := CR * SP * CY + SR * SY;
 end;

if Right <> nil then
 begin
  Right[0] := CP * SY;
  Right[1] := SR * SP * SY + CR * CY;
  Right[2] := CR * SP * SY - SR * CY;
 end;

if Up <> nil then
 begin
  Up[0] := -SP;
  Up[1] := SR * CP;
  Up[2] := CR * CP;
 end;
end;

procedure AngleMatrix(const Angles: TVec3; Matrix: PMatrix3x4);
var
 Angle, SP, CP, SY, CY, SR, CR: Single;
begin
Angle := Angles[0] * (M_PI * 2 / 360);
SP := Sin(Angle);
CP := Cos(Angle);
Angle := Angles[1] * (M_PI * 2 / 360);
SY := Sin(Angle);
CY := Cos(Angle);
Angle := Angles[2] * (M_PI * 2 / 360);
SR := Sin(Angle);
CR := Cos(Angle);

Matrix[1][1] := CP * CY;
Matrix[2][1] := CP * SY;
Matrix[3][1] := -SP;

Matrix[1][2] := SR * SP * CY - CR * SY;
Matrix[2][2] := SR * SP * SY + CR * CY;
Matrix[3][2] := SR * CP;

Matrix[1][3] := CR * SP * CY + SR * SY;
Matrix[2][3] := CR * SP * SY - SR * CY;
Matrix[3][3] := CR * CP;

Matrix[1][4] := 0;
Matrix[2][4] := 0;
Matrix[3][4] := 0;
end;

procedure AngleIMatrix(const Angles: TVec3; Matrix: PMatrix3x4);
var
 Angle, SP, CP, SY, CY, SR, CR: Single;
begin
Angle := Angles[0] * (M_PI * 2 / 360);
SP := Sin(Angle);
CP := Cos(Angle);
Angle := Angles[1] * (M_PI * 2 / 360);
SY := Sin(Angle);
CY := Cos(Angle);
Angle := Angles[2] * (M_PI * 2 / 360);
SR := Sin(Angle);
CR := Cos(Angle);

Matrix[1][1] := CP * CY;
Matrix[1][2] := CP * SY;
Matrix[1][3] := -SP;
Matrix[1][4] := 0;

Matrix[2][1] := SR * SP * CY - CR * SY;
Matrix[2][2] := SR * SP * SY + CR * CY;
Matrix[2][3] := SR * CP;
Matrix[2][4] := 0;

Matrix[3][1] := CR * SP * CY + SR * SY;
Matrix[3][2] := CR * SP * SY - SR * CY;
Matrix[3][3] := CR * CP;
Matrix[3][4] := 0;
end;

procedure NormalizeAngles(var Angles: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
var
 I: UInt;
begin
for I := 0 to 2 do
 if Angles[I] > 180 then
  Angles[I] := Angles[I] - 360
 else
  if Angles[I] < -180 then
   Angles[I] := Angles[I] + 360;
end;

procedure InterpolateAngles(var VStart, VEnd: TVec3; out VOut: TVec3; Fraction: Single);
var
 I: Int;
 X: Single;
begin
NormalizeAngles(VStart);
NormalizeAngles(VEnd);

for I := 0 to 2 do
 begin
  X := VEnd[I] - VStart[I];
  if X > 180 then
   X := X - 360
  else
   if X < 180 then
    X := X + 360;

  VOut[I] := VStart[I] + X * Fraction;
 end;

NormalizeAngles(VOut);
end;

procedure VectorTransform(const VIn: TVec3; Matrix: PMatrix3x4; out VOut: TVec3);
begin
VOut[0] := DotProduct(VIn, PVec3(@Matrix[1])^) + Matrix[1][4];
VOut[1] := DotProduct(VIn, PVec3(@Matrix[2])^) + Matrix[2][4];
VOut[2] := DotProduct(VIn, PVec3(@Matrix[3])^) + Matrix[3][4];
end;

function VectorCompare(const Vec1, Vec2: TVec3): Boolean; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
Result := (Vec1[0] = Vec2[0]) and (Vec1[1] = Vec2[1]) and (Vec1[2] = Vec2[2]);
end;

procedure VectorMA(const Vec1: TVec3; Scale: Single; const Vec2: TVec3; out VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut[0] := Vec1[0] + Scale * Vec2[0];
VOut[1] := Vec1[1] + Scale * Vec2[1];
VOut[2] := Vec1[2] + Scale * Vec2[2];
end;

function DotProduct(const X, Y: TVec3): Single; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
Result := X[0] * Y[0] + X[1] * Y[1] + X[2] * Y[2];
end;

procedure VectorSubtract(const Vec1, Vec2: TVec3; out VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut[0] := Vec1[0] - Vec2[0];
VOut[1] := Vec1[1] - Vec2[1];
VOut[2] := Vec1[2] - Vec2[2];
end;

procedure VectorAdd(const Vec1, Vec2: TVec3; out VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut[0] := Vec1[0] + Vec2[0];
VOut[1] := Vec1[1] + Vec2[1];
VOut[2] := Vec1[2] + Vec2[2];
end;

procedure VectorCopy(const VIn: TVec3; out VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut := VIn;
end;

procedure CrossProduct(const Vec1, Vec2: TVec3; out VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut[0] := Vec2[2] * Vec1[1] - Vec1[2] * Vec2[1];
VOut[1] := Vec2[0] * Vec1[2] - Vec1[0] * Vec2[2];
VOut[2] := Vec2[1] * Vec1[0] - Vec1[1] * Vec2[0];
end;

function Length(const VIn: TVec3): Single; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
Result := Sqrt(VIn[0] * VIn[0] + VIn[1] * VIn[1] + VIn[2] * VIn[2]);
end;

function VectorNormalize(var VOut: TVec3): Single; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
var
 L: Single;
begin
Result := Length(VOut);
if Result <> 0 then
 begin
  L := 1 / Result;
  VOut[0] := VOut[0] * L;
  VOut[1] := VOut[1] * L;
  VOut[2] := VOut[2] * L;
 end;
end;

procedure VectorInverse(var VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut[0] := -VOut[0];
VOut[1] := -VOut[1];
VOut[2] := -VOut[2];
end;

procedure VectorSet(out VOut: TVec3; Value: Single); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut[0] := Value;
VOut[1] := Value;
VOut[2] := Value;
end; 

procedure VectorScale(const VIn: TVec3; Scale: Single; out VOut: TVec3); {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
begin
VOut[0] := Scale * VIn[0];
VOut[1] := Scale * VIn[1];
VOut[2] := Scale * VIn[2];
end;

function Q_log2(X: Int): Int;
begin
Result := 0;
X := X shr 1;

while X > 0 do
 begin
  Inc(Result);
  X := X shr 1;
 end;
end;

procedure VectorMatrix(const Fwd: TVec3; var Right, Up: TVec3);
var
 Vec: TVec3;
begin
if (Fwd[0] <> 0) or (Fwd[1] <> 0) then
 begin
  Vec[0] := 0;
  Vec[1] := 0;
  Vec[2] := 1;
  CrossProduct(Fwd, Vec, Right);
  VectorNormalize(Right);
  CrossProduct(Right, Fwd, Up);
  VectorNormalize(Up);
 end
else
 begin
  Right[0] := 1;
  Right[1] := 0;
  Right[2] := 0;
  Up[0] := -Fwd[2];
  Up[1] := 0;
  Up[2] := 0;
 end;
end;

procedure VectorAngles(const Fwd: TVec3; out Angles: TVec3);
begin
if (Fwd[0] <> 0) or (Fwd[1] <> 0) then
 begin
  Angles[1] := Trunc(ArcTan2(Fwd[1], Fwd[0]) * 180 / M_PI);
  if Angles[1] < 0 then
   Angles[1] := Angles[1] + 360;

  Angles[0] := Trunc(ArcTan2(Fwd[2], Sqrt(Fwd[0] * Fwd[0] + Fwd[1] * Fwd[1])) * 180 / M_PI);
  if Angles[0] < 0 then
   Angles[0] := Angles[0] + 360;
 end
else
 begin
  if Fwd[2] <= 0 then
   Angles[0] := 270
  else
   Angles[0] := 90;

  Angles[1] := 0;
 end;

Angles[2] := 0;
end;

procedure R_ConcatRotations(In1, In2, Out1: PMatrix3x3);
begin
Out1[1][1] := In1[1][1] * In2[1][1] + In1[1][2] * In2[2][1] + In1[1][3] * In2[3][1];
Out1[1][2] := In1[1][1] * In2[1][2] + In1[1][2] * In2[2][2] + In1[1][3] * In2[3][2];
Out1[1][3] := In1[1][1] * In2[1][3] + In1[1][2] * In2[2][3] + In1[1][3] * In2[3][3];
Out1[2][1] := In1[2][1] * In2[1][1] + In1[2][2] * In2[2][1] + In1[2][3] * In2[3][1];
Out1[2][2] := In1[2][1] * In2[1][2] + In1[2][2] * In2[2][2] + In1[2][3] * In2[3][2];
Out1[2][3] := In1[2][1] * In2[1][3] + In1[2][2] * In2[2][3] + In1[2][3] * In2[3][3];
Out1[3][1] := In1[3][1] * In2[1][1] + In1[3][2] * In2[2][1] + In1[3][3] * In2[3][1];
Out1[3][2] := In1[3][1] * In2[1][2] + In1[3][2] * In2[2][2] + In1[3][3] * In2[3][2];
Out1[3][3] := In1[3][1] * In2[1][3] + In1[3][2] * In2[2][3] + In1[3][3] * In2[3][3];
end;

procedure R_ConcatTransforms(In1, In2, Out1: PMatrix3x4);
begin
Out1[1][1] := In1[1][1] * In2[1][1] + In1[1][2] * In2[2][1] + In1[1][3] * In2[3][1];
Out1[1][2] := In1[1][1] * In2[1][2] + In1[1][2] * In2[2][2] + In1[1][3] * In2[3][2];
Out1[1][3] := In1[1][1] * In2[1][3] + In1[1][2] * In2[2][3] + In1[1][3] * In2[3][3];
Out1[1][4] := In1[1][1] * In2[1][4] + In1[1][2] * In2[2][4] + In1[1][3] * In2[3][4] + In1[1][4];
Out1[2][1] := In1[2][1] * In2[1][1] + In1[2][2] * In2[2][1] + In1[2][3] * In2[3][1];
Out1[2][2] := In1[2][1] * In2[1][2] + In1[2][2] * In2[2][2] + In1[2][3] * In2[3][2];
Out1[2][3] := In1[2][1] * In2[1][3] + In1[2][2] * In2[2][3] + In1[2][3] * In2[3][3];
Out1[2][4] := In1[2][1] * In2[1][4] + In1[2][2] * In2[2][4] + In1[2][3] * In2[3][4] + In1[2][4];
Out1[3][1] := In1[3][1] * In2[1][1] + In1[3][2] * In2[2][1] + In1[3][3] * In2[3][1];
Out1[3][2] := In1[3][1] * In2[1][2] + In1[3][2] * In2[2][2] + In1[3][3] * In2[3][2];
Out1[3][3] := In1[3][1] * In2[1][3] + In1[3][2] * In2[2][3] + In1[3][3] * In2[3][3];
Out1[3][4] := In1[3][1] * In2[1][4] + In1[3][2] * In2[2][4] + In1[3][3] * In2[3][4] + In1[3][4];
end;

procedure FloorDivMod(X, Denom: Double; Quotient, Remainder: PInt);
var
 V: Double;
 Q, R: Int;
begin
if Denom <= 0 then
 Sys_Error(['FloorDivMod: Bad denominator ', RoundTo(Denom, 3), '.']);

if X < 0 then
 begin
  V := Trunc(-X / Denom);
  Q := -Trunc(V);
  R := Trunc(-X - V * Denom);
  if R <> 0 then
   begin
    Dec(Q);
    R := Trunc(Denom) - R;
   end;
 end
else
 begin
  V := Trunc(X / Denom);
  Q := Trunc(V);
  R := Trunc(X - V * Denom);
 end;

Quotient^ := Q;
Remainder^ := R;
end;

function Invert24To16(X: Int): Int;
begin
if X <= 255 then
 Result := -1
else
 Result := Trunc($10000000000 / X + 0.5);
end;

procedure AngleQuaternion(const Angles: TVec3; out Q: TVec4);
var
 Angle, SR, CR, SP, CP, SY, CY: Single;
begin
Angle := Angles[0] * 0.5;
SR := Sin(Angle);
CR := Cos(Angle);
Angle := Angles[1] * 0.5;
SP := Sin(Angle);
CP := Cos(Angle);
Angle := Angles[2] * 0.5;
SY := Sin(Angle);
CY := Cos(Angle);

Q[0] := SR * CP * CY - CR * SP * SY;
Q[1] := CR * SP * CY + SR * CP * SY;
Q[2] := CR * CP * SY - SR * SP * CY;
Q[3] := SR * SP * SY + CR * CP * CY;
end;

procedure QuaternionSlerp(const P: TVec4; var Q: TVec4; T: Single; out QT: TVec4);
var
 I: UInt;
 O, CO, SO, SP, SQ, A, B, F: Single;
begin
A := 0;
B := 0;
for I := 0 to 3 do
 begin
  F := P[I] - Q[I];
  A := A + F * F;
  F := P[I] + Q[I];
  B := B + F * F;
 end;

if A > B then
 for I := 0 to 3 do
  Q[I] := -Q[I];

CO := P[0] * Q[0] + P[1] * Q[1] + P[2] * Q[2] + P[3] * Q[3];
if 1 + CO <= 0.000001 then
 begin
  QT[0] := -Q[1];
  QT[2] := -Q[3];
  QT[1] := Q[0];
  QT[3] := Q[2];
  SP := Sin((1 - T) * (M_PI / 2));
  SQ := Sin(T * (M_PI / 2));
  for I := 0 to 2 do
   QT[I] := SP * P[I] + SQ * QT[I];
 end
else
 begin
  if 1 - CO <= 0.000001 then
   begin
    SP := 1 - T;
    SQ := T;
   end
  else
   begin
    O := ArcCos(CO);
    SO := Sin(O);
    SP := Sin((1 - T) * O) / SO;
    SQ := Sin(T * O) / SO;
   end;

  for I := 0 to 3 do
   QT[I] := SP * P[I] + SQ * QT[I];
 end;
end;

procedure QuaternionMatrix(const Q: TVec4; Matrix: PVec4);
begin
Matrix[0] := 1 - (Q[1] + Q[1]) * Q[1] - (Q[2] + Q[2]) * Q[2];
Matrix[1] :=     (Q[0] + Q[0]) * Q[1] - (Q[3] + Q[3]) * Q[2];
Matrix[2] :=     (Q[0] + Q[0]) * Q[2] + (Q[3] + Q[3]) * Q[1];
Inc(UInt(Matrix), SizeOf(Matrix^));

Matrix[0] :=     (Q[0] + Q[0]) * Q[1] + (Q[3] + Q[3]) * Q[2];
Matrix[1] := 1 - (Q[0] + Q[0]) * Q[0] - (Q[2] + Q[2]) * Q[2];
Matrix[2] :=     (Q[1] + Q[1]) * Q[2] - (Q[3] + Q[3]) * Q[0];
Inc(UInt(Matrix), SizeOf(Matrix^));

Matrix[0] :=     (Q[0] + Q[0]) * Q[2] - (Q[3] + Q[3]) * Q[1];
Matrix[1] :=     (Q[1] + Q[1]) * Q[2] + (Q[3] + Q[3]) * Q[0];
Matrix[2] := 1 - (Q[0] + Q[0]) * Q[0] - (Q[1] + Q[1]) * Q[1];
end;

end.
