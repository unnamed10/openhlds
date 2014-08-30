unit Model;

{$I HLDS.inc}

// 60 is a node size, probably

interface

uses SysUtils, Default, SDK;

procedure Mod_Init;

procedure CM_DecompressPVS(Src, Dst: PByte; Size: UInt);
function CM_LeafPVS(Index: UInt): Pointer;
function CM_LeafPAS(Index: UInt): Pointer;
procedure CM_FreePAS;
procedure CM_CalcPAS(const Model: TModel);
function CM_HeadnodeVisible(Node: PMNode; VisData: PByte; LeafIndex: PUInt32): Boolean;
function Mod_LeafPVS(Leaf: PMLeaf; Model: PModel): PByte;

function Mod_FindName(NeedCRC: Boolean; Name: PLChar): PModel;
function Mod_LoadModel(var M: TModel; Crash, NeedCRC: Boolean): PModel;
function Mod_ForName(Name: PLChar; Crash, NeedCRC: Boolean): PModel;

function Mod_ExtraData(var M: TModel): Pointer;
function ModelFrameIndex(var M: TModel): UInt;

procedure Mod_ClearAll;

function Mod_PointInLeaf(const P: TVec3; const M: TModel): PMLeaf;

function SurfaceAtPoint(const M: TModel; const Node: TMNode; const MinS, MaxS: TVec3): PMSurface;

var
 // must not start from 1
 TexGammaTable: array[Byte] of Byte;

implementation

uses Common, Console, Decal, Encode, FileSys, Host, MathLib, Memory, Renderer, Server, SysArgs, SysClock, SysMain, Texture;

const
 NL_PRESENT = 0;
 NL_NEEDS_LOADED = 1;
 NL_UNREFERENCED = 2;
 NL_CLIENT = 3;

var
 Mod_NoVis, VisDecompressed: array[0..MAX_MAP_LEAFS div 8 - 1] of Byte; // cf
 PASData: PByte = nil;
 PVSData: PByte = nil;

 PVSRowBytes: UInt32 = 0;


 Mod_NumKnown: UInt = 0;
 Mod_Known: array[0..MAX_MOD_KNOWN - 1] of TModel;
 Mod_KnownInfo: array[0..MAX_MOD_KNOWN - 1] of TModelCRCInfo;

 LoadName: array[1..MAX_MODEL_NAME] of LChar;
 ModBase: Pointer;
 LoadModel: PModel;

 AdTested: Boolean = False;
 AdEnabled: Boolean = False;
 AdWAD: PCacheWAD = nil;

procedure Mod_Init;
begin
MemSet(Mod_NoVis, SizeOf(Mod_NoVis), $FF);
end;

function Mod_DecompressVis(Data: PByte; Model: PModel): PByte;
begin
if Data <> nil then
 begin
  CM_DecompressPVS(Data, @VisDecompressed, (Model.NumLeafs + 7) shr 3);
  Result := @VisDecompressed;
 end
else
 Result := @Mod_NoVis;
end;

function Mod_LeafPVS(Leaf: PMLeaf; Model: PModel): PByte;
begin
if Leaf = PMLeaf(Model.Leafs) then
 Result := @Mod_NoVis
else
 if PVSData <> nil then
  Result := CM_LeafPVS((UInt(Leaf) - UInt(Model.Leafs)) div SizeOf(Leaf^))
 else
  Result := Mod_DecompressVis(Leaf.CompressedVis, Model);
end;

procedure CM_DecompressPVS(Src, Dst: PByte; Size: UInt);
var
 DstEnd: PByte;
 RowSize: Byte;
begin
if Src <> nil then
 begin
  DstEnd := Pointer(UInt(Dst) + Size);

  while UInt(Dst) < UInt(DstEnd) do
   if Src^ > 0 then
    begin
     Dst^ := Src^;
     Inc(UInt(Src));
     Inc(UInt(Dst));
    end
   else
    begin
     RowSize := PByte(UInt(Src) + 1)^;
     Inc(UInt(Src), 2);
     if RowSize > 0 then
      begin
       MemSet(Dst^, RowSize, 0);
       Inc(UInt(Dst), RowSize);
      end;
    end;
 end
else
 Move(Mod_NoVis, Dst^, Size);
end;

function CM_LeafPVS(Index: UInt): Pointer;
begin
if PVSData <> nil then
 Result := Pointer(UInt(PVSData) + PVSRowBytes * Index)
else
 Result := @Mod_NoVis;
end;

function CM_LeafPAS(Index: UInt): Pointer;
begin
if PASData <> nil then
 Result := Pointer(UInt(PASData) + PVSRowBytes * Index)
else
 Result := @Mod_NoVis;
end;

procedure CM_FreePAS;
begin
if PASData <> nil then
 Mem_FreeAndNil(PASData);
if PVSData <> nil then
 Mem_FreeAndNil(PVSData);
end;

procedure CM_CalcPAS(const Model: TModel);
var
 K, C, L, M: UInt;
 LeafCount, RowIndex, RowCount: UInt;
 Visible, Audible: UInt;
 PVS, PAS: PByte;
 P, P2: PUInt32;
 B: Byte;

 I, J: UInt;
begin
DPrint('Building PAS...');
CM_FreePAS;

RowCount := (Model.NumLeafs + 7) shr 3;
LeafCount := Model.NumLeafs + 1;
PVSRowBytes := (RowCount + 3) and not 3;
RowIndex := PVSRowBytes shr 2;

Visible := 0;
Audible := 0;

PVSData := Mem_CAlloc(PVSRowBytes, LeafCount);
PVS := PVSData;
for I := 0 to LeafCount - 1 do
 begin
  CM_DecompressPVS(Model.Leafs[I].CompressedVis, PVS, RowCount);
  if I > 0 then
   for J := 0 to LeafCount - 1 do
    if ((1 shl (J and 7)) and PByte(UInt(PVS) + (J shr 3))^) > 0 then
     Inc(Visible);

  Inc(UInt(PVS), PVSRowBytes);
 end;

PASData := Mem_CAlloc(PVSRowBytes, LeafCount);
PVS := PVSData;
PAS := PASData;
for I := 0 to LeafCount - 1 do
 begin
  Move(PVS^, PAS^, PVSRowBytes);
  C := 1;
  if PVSRowBytes > 0 then
   for J := 0 to PVSRowBytes - 1 do
    begin
     B := PByte(UInt(PVS) + J)^;
     if B > 0 then
      for K := 0 to 7 do
       if ((1 shl K) and B) > 0 then
        begin
         L := K + C;
         if (L > 0) and (L < LeafCount) then
          begin
           P := PUInt32(PAS);
           P2 := Pointer(UInt(PVSData) + L * PVSRowBytes);
           for M := 1 to RowIndex do
            begin
             P^ := P^ or P2^;
             Inc(UInt(P), SizeOf(P^));
             Inc(UInt(P2), SizeOf(P2^));
            end;
          end;
        end;

     Inc(C, 8);
    end;

  if I > 0 then
   for J := 0 to LeafCount - 1 do
    if ((1 shl (J and 7)) and PByte(UInt(PAS) + (J shr 3))^) > 0 then
     Inc(Audible);

  Inc(UInt(PVS), PVSRowBytes);
  Inc(UInt(PAS), 4 * RowIndex);
 end;

DPrint(['CM_CalcPAS: ', Visible div LeafCount, ' visible; ',
                        Audible div LeafCount, ' audible; ',
                        LeafCount, ' total.']);
end;

function CM_HeadnodeVisible(Node: PMNode; VisData: PByte; LeafIndex: PUInt32): Boolean;
var
 Index: UInt;
begin
if (Node <> nil) and (Node.Contents <> CONTENTS_SOLID) then
 if Node.Contents < 0 then
  begin
   Index := (UInt(Node) - UInt(SV.WorldModel.Leafs)) div SizeOf(TMLeaf) - 1;
   Result := (Int(Index) <> -1) and (((1 shl (Index and 7)) and PByte(UInt(VisData) + (Index shr 3))^) > 0);
   if Result and (LeafIndex <> nil) then
    LeafIndex^ := Index;
   Exit;
  end
 else
  begin
   Result := CM_HeadnodeVisible(Node.Children[0], VisData, LeafIndex);
   if not Result then
    Result := CM_HeadnodeVisible(Node.Children[1], VisData, LeafIndex);
  end
else
 Result := False;
end;

function ModelFrameIndex(var M: TModel): UInt;
begin
Result := 1;

if @M <> nil then
 begin
  if M.ModelType = ModSprite then
   Result := PMSprite(M.Cache.Data).FrameIndex
  else
   if M.ModelType = ModStudio then
    Result := R_StudioBodyVariations(M);

  if Result < 1 then
   Result := 1;
 end;
end;

procedure Mod_SetParent(Node, Parent: PMNode);
begin
Node.Parent := Parent;
if Node.Contents < 0 then
 Exit;

Mod_SetParent(Node.Children[0], Node);
Mod_SetParent(Node.Children[1], Node);
end;

procedure CalcSurfaceExtents(var S: TMSurface);
var
 MinS, MaxS: array[0..1] of Single;
 BMinS, BMaxS: array[0..1] of Int32;
 I, J: Int;
 E: Int32;
 V: PMVertex;
 Val: Single;
 Tex: PMTexInfo;
begin
MinS[0] := 999999;
MinS[1] := 999999;
MaxS[0] := -99999;
MaxS[1] := -99999;

Tex := S.TexInfo;
V := nil;

for I := 0 to S.NumEdges - 1 do
 begin
  E := LoadModel.SurfEdges[S.FirstEdge + I];
  if E >= 0 then
   V := @LoadModel.Vertexes[LoadModel.Edges[E].V[0]]
  else
   V := @LoadModel.Vertexes[LoadModel.Edges[-E].V[1]];

  for J := 0 to 1 do
   begin
    Val := DotProduct(V.Position, PVec3(@Tex.Vecs[J])^) + Tex.Vecs[J][3];
    if Val < MinS[J] then
     MinS[J] := Val;
    if Val > MaxS[J] then
     MaxS[J] := Val;
   end;
 end;

for I := 0 to 1 do
 begin
  BMinS[I] := Floor(MinS[I] / 16);
  BMaxS[I] := Ceil(MaxS[I] / 16);

  S.TextureMinS[I] := BMinS[I] * 16;
  S.Extents[I] := (BMaxS[I] - BMinS[I]) * 16;
  if ((Tex.Flags and TEX_SPECIAL) = 0) and (S.Extents[I] > 256) then
   Sys_Error(['Bad surface extents ', S.Extents[0], '/', S.Extents[1], ' at position (',
              V.Position[0], ', ', V.Position[1], ', ', V.Position[2], ').']);
 end;
end;

function RadiusFromBounds(const MinS, MaxS: TVec3): Single;
var
 Corner: TVec3;
 I: UInt;
 F1, F2: Single;
begin
for I := 0 to 2 do
 begin
  F1 := Abs(MinS[I]);
  F2 := Abs(MaxS[I]);
  if F1 > F2 then
   Corner[I] := F1
  else
   Corner[I] := F2;
 end;

Result := Length(Corner);
end;

procedure Mod_AdInit;
var
 S: PLChar;
begin
if not AdTested then
 begin
  AdTested := True;
  S := COM_ParmValueByName('-ad');
  if S^ > #0 then
   if FS_SizeByName(S) > 0 then
    begin
     Draw_CacheWADInit(S, 16, AdWAD);
     AdEnabled := True;
    end
   else
    Print('Invalid size in -ad file.')
  else
   DPrint('No -ad file specified, skipping.');
 end;
end;

procedure Mod_AdSwap(Tex: PTexture; Size: UInt; NumPalette: Int);
var
 P: PTexture;
 I: Int;
 PIn: PDModelPalette;
 POut: PMModelPalette;
begin
if AdTested and AdEnabled then
 begin
  P := Draw_CacheGet(@AdWAD, Draw_CacheIndex(@AdWAD, 'img'));
  if P <> nil then
   begin
    Move(Pointer(UInt(P) + SizeOf(P^))^, Pointer(UInt(Tex) + SizeOf(Tex^))^, Size);
    PIn := Pointer(UInt(P) + SizeOf(P^) + Size + SizeOf(UInt16));
    POut := Pointer(UInt(Tex) + SizeOf(P^) + Size + SizeOf(UInt16));
    for I := 0 to NumPalette - 1 do
     begin
      POut.R := PIn.B;
      POut.G := PIn.G;
      POut.B := PIn.R;
      POut.A := 0;

      Inc(UInt(PIn), SizeOf(PIn^));
      Inc(UInt(POut), SizeOf(POut^));      
     end;
   end;
 end;
end;


// Alias models

function Mod_LoadAliasSkin(P: Pointer; SkinIndex: PInt32; SkinSize: UInt; Header: PAliasModelHeader): Pointer;
var
 PSkin: Pointer;
begin
PSkin := Hunk_AllocName(SkinSize, @LoadName);
SkinIndex^ := UInt(PSkin) - UInt(Header);
Move(P^, PSkin^, SkinSize);
Result := Pointer(UInt(P) + UInt(SkinSize)); 
end;

function Mod_LoadAliasSkinGroup(P: Pointer; SkinIndex: PInt32; SkinSize: UInt; Header: PAliasModelHeader): Pointer;
var
 PInSkinGroup: PDAliasSkinGroup;
 PSkinGroup: PMAliasSkinGroup;
 NumSkins: Int32;
 I: Int;
 PInSkinIntervals: PDAliasSkinInterval;
 PSkinIntervals: PSingle;
 PSkinDescs: PMAliasSkinDesc;
begin
PInSkinGroup := P;
NumSkins := LittleLong(PInSkinGroup.NumSkins);
PSkinGroup := Hunk_AllocName(SizeOf(TMAliasSkinDesc) * NumSkins + SizeOf(PSkinGroup^), @LoadName);
PSkinGroup.NumSkins := NumSkins;

SkinIndex^ := UInt(PSkinGroup) - UInt(Header);

PInSkinIntervals := Pointer(UInt(PInSkinGroup) + SizeOf(PInSkinGroup^));
PSkinIntervals := Hunk_AllocName(NumSkins * SizeOf(PSkinIntervals^), @LoadName);
PSkinGroup.Intervals := UInt(PSkinIntervals) - UInt(Header);
for I := 0 to NumSkins - 1 do
 begin
  PSkinIntervals^ := LittleFloat(PInSkinIntervals.Interval);
  if PSkinIntervals^ <= 0 then
   Sys_Error('Mod_LoadAliasSkinGroup: Bad interval.');
  Inc(UInt(PSkinIntervals), SizeOf(PSkinIntervals^));
  Inc(UInt(PInSkinIntervals), SizeOf(PInSkinIntervals^));
 end;

PSkinDescs := Pointer(UInt(PSkinGroup) + SizeOf(PSkinGroup^));
P := PInSkinIntervals;
for I := 0 to NumSkins - 1 do
 begin
  P := Mod_LoadAliasSkin(P, @PSkinDescs.Skin, SkinSize, Header);
  Inc(UInt(PSkinDescs), SizeOf(PSkinDescs^));
 end;
Result := P;
end;

function Mod_LoadAliasFrame(P: Pointer; FrameIndex: PInt32; NumV: Int32; out BoxMin, BoxMax: TTriVertX; Header: PAliasModelHeader; Name: PLChar): Pointer;
var
 PInAliasFrame: PDAliasFrame;
 PInFrame, PFrame: PTriVertX;
 I: Int;
begin
PInAliasFrame := P;
StrCopy(Name, @PInAliasFrame.Name);
for I := 0 to 2 do
 begin
  BoxMin.V[I] := PInAliasFrame.BBoxMin.V[I];
  BoxMax.V[I] := PInAliasFrame.BBoxMax.V[I];
 end;

PInFrame := Pointer(UInt(PInAliasFrame) + SizeOf(PInAliasFrame^));
PFrame := Hunk_AllocName(NumV * SizeOf(PFrame^), @LoadName);
FrameIndex^ := UInt(PFrame) - UInt(Header);

for I := 0 to NumV - 1 do
 begin
  PFrame.LightNormalIndex := PInFrame.LightNormalIndex;
  PFrame.V[0] := PInFrame.V[0];
  PFrame.V[1] := PInFrame.V[1];
  PFrame.V[2] := PInFrame.V[2];

  Inc(PFrame, SizeOf(PFrame^));
  Inc(PInFrame, SizeOf(PInFrame^));
 end;

Result := PInFrame;
end;

function Mod_LoadAliasFrameGroup(P: Pointer; FrameIndex: PInt32; NumV: Int32; out BoxMin, BoxMax: TTriVertX; Header: PAliasModelHeader; Name: PLChar): Pointer;
var
 PInAliasGroup: PDAliasGroup;
 PAliasGroup: PMAliasGroup;
 NumFrames: Int32;
 I: Int;
 PInIntervals: PDAliasInterval;
 PIntervals: PSingle;
 PFrameDescs: PMAliasFrameDesc;
begin
PInAliasGroup := P;
NumFrames := LittleLong(PInAliasGroup.NumFrames);
PAliasGroup := Hunk_AllocName(SizeOf(TMAliasGroupFrameDesc) * NumFrames + SizeOf(PAliasGroup^), @LoadName);
PAliasGroup.NumFrames := NumFrames;
for I := 0 to 2 do
 begin
  BoxMin.V[I] := PInAliasGroup.BBoxMin.V[I];
  BoxMax.V[I] := PInAliasGroup.BBoxMax.V[I];
 end;

FrameIndex^ := UInt(PAliasGroup) - UInt(Header);

PInIntervals := Pointer(UInt(PInAliasGroup) + SizeOf(PInAliasGroup^));
PIntervals := Hunk_AllocName(NumFrames * SizeOf(PIntervals^), @LoadName);

PAliasGroup.Intervals := UInt(PIntervals) - UInt(Header);
for I := 0 to NumFrames - 1 do
 begin
  PIntervals^ := LittleFloat(PInIntervals.Interval);
  if PIntervals^ <= 0 then
   Sys_Error('Mod_LoadAliasFrameGroup: Bad interval.');
  Inc(UInt(PIntervals), SizeOf(PIntervals^));
  Inc(UInt(PInIntervals), SizeOf(PInIntervals^));
 end;

PFrameDescs := Pointer(UInt(PAliasGroup) + SizeOf(PAliasGroup^));
P := PInIntervals;
for I := 0 to NumFrames - 1 do
 begin
  P := Mod_LoadAliasFrame(P, @PFrameDescs.Frame, NumV, PFrameDescs.BBoxMin, PFrameDescs.BBoxMax, Header, Name);
  Inc(UInt(PFrameDescs), SizeOf(PFrameDescs^));
 end;
Result := P;
end;

procedure Mod_LoadAliasModel(var M: TModel; P: Pointer);
var
 Header, PModel: PModelHeader;
 I, Start, Total: UInt;
 Version, Size, SkinSize, NumSkins: UInt;
 AliasHeader: PAliasModelHeader;
 PSkinType: PDAliasSkinType;
 PSkinDesc: PMAliasSkinDesc;
 SkinType: TAliasSkinType;
 PSTVerts, PInSTVerts: PSTVert;
 PTri: PMTriangle;
 PInTri: PDTriangle;
 PFrameType: PDAliasFrameType;
 FrameType: TAliasFrameType;
 PAliasFrame: PMAliasFrameDesc;
 PPalette: PMModelPalette;
 PInPalette: PDModelPalette;
begin
Header := P;
Start := Hunk_LowMark;
Version := LittleLong(Header.Version);
if Version <> ALIAS_VERSION then
 Sys_Error(['Mod_LoadAliasModel: "', PLChar(@M.Name), '" has wrong version number (', Version, '; should be ', ALIAS_VERSION, ').']);

Size := LittleLong(Header.NumTris) * SizeOf(TMTriangle) + LittleLong(Header.NumFrames) * SizeOf(TMAliasFrameDesc) +
        LittleLong(Header.NumVerts) * SizeOf(TSTVert) + SizeOf(TModelHeader) + SizeOf(TAliasModelHeader);

AliasHeader := Hunk_AllocName(Size, @LoadName);
PModel := Pointer(UInt(AliasHeader) + SizeOf(AliasHeader^) + UInt(LittleLong(Header.NumFrames) * SizeOf(TMAliasFrameDesc)));

M.Flags := LittleLong(Header.Flags);

PModel.BoundingRadius := LittleFloat(Header.BoundingRadius);
PModel.NumSkins := LittleLong(Header.NumSkins);
PModel.SkinWidth := LittleLong(Header.SkinWidth);
PModel.SkinHeight := LittleLong(Header.SkinHeight);
if PModel.SkinHeight > MAX_LBM_HEIGHT then
 Sys_Error(['Mod_LoadAliasModel: Model "', PLChar(@M.Name), '" has a skin taller than MAX_LBM_HEIGHT (', MAX_LBM_HEIGHT, ').']);

PModel.NumVerts := LittleLong(Header.NumVerts);
if PModel.NumVerts <= 0 then
 Sys_Error(['Mod_LoadAliasModel: Model "', PLChar(@M.Name), '" has no vertices.'])
else
 if PModel.NumVerts > MAXALIASVERTS then
  Sys_Error(['Mod_LoadAliasModel: Model "', PLChar(@M.Name), '" has too many vertices.']);

PModel.NumTris := LittleLong(Header.NumTris);
if PModel.NumTris <= 0 then
 Sys_Error(['Mod_LoadAliasModel: Model "', PLChar(@M.Name), '" has no triangles.']);

PModel.NumFrames := LittleLong(Header.NumFrames);
if PModel.NumFrames <= 0 then
 Sys_Error(['Mod_LoadAliasModel: Model "', PLChar(@M.Name), '" has no frames.']);

PModel.Size := LittleFloat(Header.Size) * ALIAS_BASE_SIZE_RATIO;

M.SyncType := TSyncType(LittleLong(Int32(Header.SyncType)));
M.NumFrames := PModel.NumFrames;

for I := 0 to 2 do
 begin
  PModel.Scale[I] := LittleFloat(Header.Scale[I]);
  PModel.ScaleOrigin[I] := LittleFloat(Header.ScaleOrigin[I]);
  PModel.EyePosition[I] := LittleFloat(Header.EyePosition[I]);
 end;

if (PModel.SkinWidth and 3) > 0 then
 Sys_Error('Mod_LoadAliasModel: SkinWidth should be a multiple of 4.');

if PModel.NumSkins <= 0 then
 Sys_Error(['Mod_LoadAliasModel: Invalid number of skins (', PModel.NumSkins, ').']);

AliasHeader.Model := UInt(PModel) - UInt(AliasHeader);
NumSkins := PModel.NumSkins;
SkinSize := PModel.SkinWidth * PModel.SkinHeight;

PSkinType := Pointer(UInt(Header) + SizeOf(Header^));
PSkinDesc := Hunk_AllocName(SizeOf(TMAliasSkinDesc) * NumSkins, @LoadName);
AliasHeader.SkinDesc := UInt(PSkinDesc) - UInt(AliasHeader);
for I := 0 to NumSkins - 1 do
 begin
  SkinType := TAliasSkinType(LittleLong(UInt(PSkinType.T)));
  PSkinDesc.T := SkinType;
  if SkinType = ALIAS_SKIN_GROUP then
   PSkinType := Mod_LoadAliasSkinGroup(Pointer(UInt(PSkinType) + SizeOf(PSkinType^)), @PSkinDesc.Skin, SkinSize, AliasHeader)
  else
   PSkinType := Mod_LoadAliasSkin(Pointer(UInt(PSkinType) + SizeOf(PSkinType^)), @PSkinDesc.Skin, SkinSize, AliasHeader);
  Inc(UInt(PSkinDesc), SizeOf(PSkinDesc^));
 end;

PSTVerts := Pointer(UInt(PModel) + SizeOf(TModelHeader));
PInSTVerts := PSTVert(PSkinType);
AliasHeader.StVerts := UInt(PSTVerts) - UInt(AliasHeader);
for I := 0 to PModel.NumVerts - 1 do
 begin
  PSTVerts.OnSeam := LittleLong(PInSTVerts.OnSeam);
  PSTVerts.S := LittleLong(PInSTVerts.S) shl 16;
  PSTVerts.T := LittleLong(PInSTVerts.T) shl 16;

  Inc(UInt(PSTVerts), SizeOf(PSTVerts^));
  Inc(UInt(PInSTVerts), SizeOf(PInSTVerts^));
 end;

PTri := PMTriangle(PSTVerts);
PInTri := PDTriangle(PInSTVerts);
AliasHeader.Triangles := UInt(PTri) - UInt(AliasHeader);
for I := 0 to PModel.NumTris - 1 do
 begin
  PTri.FacesFront := LittleLong(PInTri.FacesFront);
  PTri.VertIndex[0] := LittleLong(PInTri.VertIndex[0]);
  PTri.VertIndex[1] := LittleLong(PInTri.VertIndex[1]);
  PTri.VertIndex[2] := LittleLong(PInTri.VertIndex[2]);

  Inc(UInt(PTri), SizeOf(PTri^));
  Inc(UInt(PInTri), SizeOf(PInTri^));
 end;

PFrameType := PDAliasFrameType(PInTri);
PAliasFrame := Pointer(UInt(AliasHeader) + SizeOf(AliasHeader^));
for I := 0 to PModel.NumFrames - 1 do
 begin
  FrameType := TAliasFrameType(LittleLong(UInt(PFrameType.T)));
  PAliasFrame.T := FrameType;
  if FrameType = ALIAS_GROUP then
   PFrameType := Mod_LoadAliasFrameGroup(Pointer(UInt(PFrameType) + SizeOf(PFrameType^)), @PAliasFrame.Frame, PModel.NumVerts, PAliasFrame.BBoxMin, PAliasFrame.BBoxMax, AliasHeader, @PAliasFrame.Name)
  else
   PFrameType := Mod_LoadAliasFrame(Pointer(UInt(PFrameType) + SizeOf(PFrameType^)), @PAliasFrame.Frame, PModel.NumVerts, PAliasFrame.BBoxMin, PAliasFrame.BBoxMax, AliasHeader, @PAliasFrame.Name);
  Inc(UInt(PAliasFrame), SizeOf(PAliasFrame^));
 end;

M.ModelType := ModAlias;
M.MinS[0] := -16;
M.MinS[1] := -16;
M.MinS[2] := -16;
M.MaxS[0] := 16;
M.MaxS[1] := 16;
M.MaxS[2] := 16;

PPalette := Hunk_AllocName(SizeOf(PPalette^) * MAX_PALETTE, @LoadName);
PInPalette := Pointer(PAliasFrame);
AliasHeader.Palette := UInt(PPalette) - UInt(AliasHeader);
for I := 0 to MAX_PALETTE - 1 do
 begin
  PPalette.R := PInPalette.B;
  PPalette.G := PInPalette.G;
  PPalette.B := PInPalette.R;
  PPalette.A := 0;

  Inc(UInt(PPalette), SizeOf(PPalette^));
  Inc(UInt(PInPalette), SizeOf(PInPalette^));
 end;

Total := Hunk_LowMark - Start;
Cache_Alloc(M.Cache, Total, @LoadName);
if M.Cache.Data <> nil then
 begin
  Move(AliasHeader^, M.Cache.Data^, Total);
  Hunk_FreeToLowMark(Start);
 end;
end;





// Sprite models

function Mod_LoadSpriteFrame(P: Pointer; var Frame: PMSpriteFrame): Pointer;
var
 PInFrame: PDSpriteFrame;
 PFrame: PMSpriteFrame;
 Width, Height: Int32;
 Size: UInt;
 Origin: array[0..1] of Int32;
begin
PInFrame := P;
Width := LittleLong(PInFrame.Width);
Height := LittleLong(PInFrame.Height);
Size := Width * Height;

PFrame := Hunk_AllocName(Size + SizeOf(PFrame^), @LoadName);
MemSet(PFrame^, Size + SizeOf(PFrame^), 0);
Frame := PFrame;

PFrame.Width := Width;
PFrame.Height := Height;

Origin[0] := LittleLong(PInFrame.Origin[0]);
Origin[1] := LittleLong(PInFrame.Origin[1]);

PFrame.Up := Origin[1];
PFrame.Down := Origin[1] - Height;
PFrame.Left := Origin[0];
PFrame.Right := Origin[0] + Width;

Move(Pointer(UInt(PInFrame) + SizeOf(PInFrame^))^, Pointer(UInt(PFrame) + SizeOf(PFrame^))^, Size);
Result := Pointer(UInt(PInFrame) + SizeOf(PInFrame^) + Size);
end;

function Mod_LoadSpriteFrameGroup(P: Pointer; var Frame: PMSpriteFrame): Pointer;
var
 PInGroup: PDSpriteGroup;
 PGroup: PMSpriteGroup;
 NumFrames: Int32;
 I: Int;
 PInIntervals: PDSpriteInterval;
 PIntervals: PSingle;
 PFrameDescs: PMSpriteGroupFrameDesc;
begin
PInGroup := P;
NumFrames := LittleLong(PInGroup.NumFrames);
PGroup := Hunk_AllocName(SizeOf(PGroup^) + NumFrames * SizeOf(TMSpriteGroupFrameDesc), @LoadName);
PGroup.NumFrames := NumFrames;
Frame := PMSpriteFrame(PGroup);

PInIntervals := Pointer(UInt(PInGroup) + SizeOf(PInGroup^));
PIntervals := Hunk_AllocName(NumFrames * SizeOf(PIntervals^), @LoadName);
PGroup.Intervals := PIntervals;

for I := 0 to NumFrames - 1 do
 begin
  PIntervals^ := LittleFloat(PInIntervals.Interval);
  if PIntervals^ <= 0 then
   Sys_Error('Mod_LoadSpriteFrameGroup: Bad interval.');

  Inc(UInt(PInIntervals), SizeOf(PInIntervals^));
  Inc(UInt(PIntervals), SizeOf(PIntervals^));
 end;

P := PInIntervals;
PFrameDescs := Pointer(UInt(PGroup) + SizeOf(PGroup^));
for I := 0 to NumFrames - 1 do
 begin
  P := Mod_LoadSpriteFrame(P, PFrameDescs.FramePtr);
  Inc(PFrameDescs, SizeOf(PFrameDescs^));
 end;
Result := P;
end;

procedure Mod_LoadSpriteModel(var M: TModel; P: Pointer);
var
 Header: PSpriteHeader;
 Version, Size: UInt;
 NumFrames: Int32;
 SpriteHeader: PMSprite;
 I, NumPalette: Int;
 PPalette: PMModelPalette;
 PInPalette: PDModelPalette;
 FrameType: TSpriteFrameType;
 PFrameType: PDSpriteFrameType;
 PSpriteFrame: PMSpriteFrameDesc;
begin
Header := P;
Version := LittleLong(Header.Version);
if Version <> SPRITE_VERSION then
 Sys_Error(['Mod_LoadSpriteModel: "', PLChar(@M.Name), '" has wrong version number (', Version, '; should be ', SPRITE_VERSION, ').']);

NumFrames := LittleLong(Header.NumFrames);
if NumFrames <= 0 then
 Sys_Error(['Mod_LoadSpriteModel: Model "', PLChar(@M.Name), '" has no frames.']);

Size := NumFrames * SizeOf(TMSpriteFrameDesc) + SizeOf(TMSprite) +
        LittleLong(Header.NumPalette) * SizeOf(TMModelPalette) + SizeOf(UInt16);
SpriteHeader := Hunk_AllocName(Size, @LoadName);

M.Cache.Data := SpriteHeader;

SpriteHeader.T := LittleLong(Header.SpriteType);
SpriteHeader.FrameIndex := LittleLong(Header.FrameIndex);
SpriteHeader.MaxWidth := LittleLong(Header.Width);
SpriteHeader.MaxHeight := LittleLong(Header.Height);
SpriteHeader.BeamLength := LittleFloat(Header.BeamLength);
SpriteHeader.NumFrames := NumFrames;

M.SyncType := TSyncType(LittleLong(Int32(Header.SyncType)));
M.MinS[0] := SpriteHeader.MaxWidth / -2;
M.MinS[1] := SpriteHeader.MaxWidth / -2;
M.MinS[2] := SpriteHeader.MaxHeight / -2;
M.MaxS[0] := SpriteHeader.MaxWidth / 2;
M.MaxS[1] := SpriteHeader.MaxWidth / 2;
M.MaxS[2] := SpriteHeader.MaxHeight / 2;
SpriteHeader.Palette := SizeOf(TMSprite) + NumFrames * SizeOf(TMSpriteFrameDesc) + SizeOf(UInt16);
NumPalette := LittleLong(Header.NumPalette);
PUInt16(UInt(SpriteHeader) + UInt(SpriteHeader.Palette) - SizeOf(UInt16))^ := NumPalette;

PPalette := Pointer(UInt(SpriteHeader) + UInt(SpriteHeader.Palette));
PInPalette := Pointer(UInt(Header) + SizeOf(Header^));
for I := 0 to NumPalette - 1 do
 begin
  PPalette.R := PInPalette.R;
  PPalette.G := PInPalette.G;
  PPalette.B := PInPalette.B;
  PPalette.A := 0;

  Inc(UInt(PPalette), SizeOf(PPalette^));
  Inc(UInt(PInPalette), SizeOf(PInPalette^));
 end;

M.NumFrames := NumFrames;
M.Flags := 0;

PFrameType := PDSpriteFrameType(PInPalette);
PSpriteFrame := Pointer(UInt(SpriteHeader) + SizeOf(SpriteHeader^));
for I := 0 to NumFrames - 1 do
 begin
  FrameType := TSpriteFrameType(LittleLong(Int32(PFrameType.T)));
  PSpriteFrame.T := FrameType;

  if FrameType = SPR_GROUP then
   PFrameType := Mod_LoadSpriteFrameGroup(Pointer(UInt(PFrameType) + SizeOf(PFrameType^)), PSpriteFrame.FramePtr)
  else
   PFrameType := Mod_LoadSpriteFrame(Pointer(UInt(PFrameType) + SizeOf(PFrameType^)), PSpriteFrame.FramePtr);

  Inc(UInt(PSpriteFrame), SizeOf(PSpriteFrame^));
 end;

M.ModelType := ModSprite;
end;






procedure Mod_LoadStudioModel(var M: TModel; P: Pointer);
var
 Header: PStudioHeader;
 PModel, PInTexture, PTexture: Pointer;
 Size: UInt;
 I, J: Int;
 Tex: PMStudioTexture;
 PInPalette: PDModelPalette;
 PPalette: PMModelPalette;
begin
Header := P;
if LittleLong(Header.Version) <> STUDIO_VERSION then
 begin
  MemSet(Header^, SizeOf(Header^), 0);
  StrCopy(@Header.Name, 'bogus');
  Header.Length := SizeOf(Header^);
  Header.TextureDataIndex := SizeOf(Header^);
 end;

M.ModelType := ModStudio;
M.Flags := Header.Flags;

Cache_Alloc(M.Cache, Header.Length + (256 * 8) * Header.NumTextures, @M.Name);
PModel := M.Cache.Data;
if PModel = nil then
 Exit;

if Header.TextureIndex = 0 then
 Move(P^, PModel^, Header.Length)
else
 begin
  Move(P^, PModel^, Header.TextureDataIndex);
  PInTexture := Pointer(UInt(P) + UInt(Header.TextureDataIndex));
  PTexture := Pointer(UInt(PModel) + UInt(Header.TextureDataIndex));
  for I := 0 to Header.NumTextures - 1 do
   begin
    Tex := Pointer(UInt(PModel) + UInt(Header.TextureIndex + I * SizeOf(Tex^)));
    Tex.Index := UInt(PTexture) - UInt(M.Cache.Data);
    Size := Tex.Width * Tex.Height;
    Move(PInTexture^, PTexture^, Size);

    PInPalette := Pointer(UInt(PInTexture) + Size);
    PPalette := Pointer(UInt(PTexture) + Size);
    for J := 0 to MAX_PALETTE - 1 do
     begin
      PPalette.R := TexGammaTable[PInPalette.R];
      PPalette.G := TexGammaTable[PInPalette.G];
      PPalette.B := TexGammaTable[PInPalette.B];
      PPalette.A := 0;

      Inc(UInt(PPalette), SizeOf(PPalette^));
      Inc(UInt(PInPalette), SizeOf(PInPalette^));
     end;
    PInTexture := PInPalette;
    PTexture := PPalette;
   end;
 end;
end;



procedure Mod_LoadVertexes(const L: TLump);
var
 PIn: PDVertex;
 POut: PMVertex;
 Count: UInt;
 I: Int;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadVertexes: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);
LoadModel.Vertexes := Pointer(POut);
LoadModel.NumVertexes := Count;

for I := 0 to Count - 1 do
 begin
  POut.Position[0] := LittleFloat(PIn.Point[0]);
  POut.Position[1] := LittleFloat(PIn.Point[1]);
  POut.Position[2] := LittleFloat(PIn.Point[2]);

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;
end;

procedure Mod_LoadEdges(const L: TLump);
var
 PIn: PDEdge;
 POut: PMEdge;
 Count: UInt;
 I: Int;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadEdges: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName((Count + 1) * SizeOf(POut^), @LoadName);
LoadModel.Edges := Pointer(POut);
LoadModel.NumEdges := Count;

for I := 0 to Count - 1 do
 begin
  POut.V[0] := LittleShort(PIn.V[0]);
  POut.V[1] := LittleShort(PIn.V[1]);

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;
end;

procedure Mod_LoadSurfEdges(const L: TLump);
var
 PIn, POut: PInt32;
 Count: UInt;
 I: Int;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadSurfEdges: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);
LoadModel.SurfEdges := Pointer(POut);
LoadModel.NumSurfEdges := Count;

for I := 0 to Count - 1 do
 begin
  POut^ := LittleLong(PIn^);

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;
end;

procedure Mod_LoadEntities(const L: TLump);
var
 E, P: Pointer;
begin
if L.FileLength = 0 then
 LoadModel.Entities := nil
else
 begin
  E := Hunk_AllocName(L.FileLength, @LoadName);
  LoadModel.Entities := E;
  Move(Pointer(UInt(ModBase) + L.FileOffset)^, E^, L.FileLength);

  P := COM_Parse(E);
  while (PLChar(P)^ > #0) and (COM_Token[Low(COM_Token)] <> '}') do
   if StrComp(@COM_Token, 'wad') = 0 then
    begin
     COM_Parse(P);
     if WADPath <> nil then
      Mem_Free(WADPath);
     WADPath := Mem_StrDup(@COM_Token);
     Exit;
    end
   else
    P := COM_Parse(P);
 end;
end;

procedure Mod_LoadTextures(const L: TLump);
var
 Start: Double;
 M: PDMiptexLump;
 MT: PMiptex;
 I, J: Int;
 WADLoaded: Boolean;
 LumpBuf: array[1..$55344] of Byte;
 Pixels, NumPalette: UInt;
 TX, TX2: PTexture;
 PIn: PDModelPalette;
 POut: PMModelPalette;
 Anims, AltAnims: array[0..9] of PTexture;
 Max, AltMax, Num: Byte;
begin
WADLoaded := False;
Start := Sys_FloatTime;
if not AdTested then
 Mod_AdInit;

if L.FileLength = 0 then
 begin
  LoadModel.Textures := nil;
  Exit;
 end;

M := Pointer(UInt(ModBase) + L.FileOffset);
M.NumMiptex := LittleLong(M.NumMiptex);

LoadModel.NumTextures := M.NumMiptex;
LoadModel.Textures := Hunk_AllocName(M.NumMiptex * SizeOf(PTexture), @LoadName);

for I := 0 to M.NumMiptex - 1 do
 begin
  M.DataOfs[I] := LittleLong(M.DataOfs[I]);
  if M.DataOfs[I] = -1 then
   Continue;

  MT := Pointer(UInt(M) + UInt(M.DataOfs[I]));
  if LittleLong(MT.Offsets[0]) = 0 then
   begin
    if not WADLoaded then
     begin
      TEX_InitFromWAD(WADPath);
      TEX_AddAnimatingTextures;
      WADLoaded := True;
     end;

    if TEX_LoadLump(@MT.Name, @LumpBuf) = 0 then
     begin
      M.DataOfs[I] := -1;
      Continue;
     end;
    MT := @LumpBuf;
   end;

  for J := 0 to MIPLEVELS - 1 do
   MT.Offsets[J] := LittleLong(MT.Offsets[J]);

  MT.Width := LittleLong(MT.Width);
  MT.Height := LittleLong(MT.Height);

  if ((MT.Width and 15) > 0) or ((MT.Height and 15) > 0) then
   Sys_Error(['Mod_LoadTextures: Texture "', PLChar(@MT.Name), '" is not 16 aligned.']);

  Pixels := ((MT.Width * MT.Height) div 64) * 85;
  NumPalette := PUInt16(UInt(MT) + SizeOf(MT^) + Pixels)^;

  TX := Hunk_AllocName(Pixels + SizeOf(TX^) + SizeOf(UInt16) + NumPalette * SizeOf(TMModelPalette), @LoadName);
  LoadModel.Textures[I] := TX;

  Move(MT.Name, TX.Name, SizeOf(TX.Name));
  if StrScan(@TX.Name, '~') <> nil then
   PLChar(UInt(@TX.Name) + 2)^ := ' ';

  TX.Width := MT.Width;
  TX.Height := MT.Height;

  for J := 0 to MIPLEVELS - 1 do
   TX.Offsets[J] := MT.Offsets[J] + TEX_SIZEDIF;

  Move(Pointer(UInt(MT) + SizeOf(MT^))^, Pointer(UInt(TX) + SizeOf(TX^))^, Pixels + SizeOf(UInt16));
  // initsky

  PIn := Pointer(UInt(MT) + SizeOf(MT^) + Pixels + SizeOf(UInt16));
  POut := Pointer(UInt(TX) + SizeOf(TX^) + Pixels + SizeOf(UInt16));
  for J := 0 to NumPalette - 1 do
   begin
    POut.R := TexGammaTable[PIn.B];
    POut.G := TexGammaTable[PIn.G];
    POut.B := TexGammaTable[PIn.R];
    POut.A := 0;

    Inc(UInt(PIn), SizeOf(PIn^));
    Inc(UInt(POut), SizeOf(POut^));
   end;

  if AdEnabled and (StrIComp(@TX.Name, 'DEFAULT') = 0) then
   Mod_AdSwap(TX, Pixels, NumPalette);
 end;

if WADLoaded then
 TEX_CleanupWadInfo;

for I := 0 to M.NumMiptex - 1 do
 begin
  TX := LoadModel.Textures[I];
  if (TX = nil) or ((TX.Name[Low(TX.Name)] <> '+') and (TX.Name[Low(TX.Name)] <> '-')) or (TX.AnimNext <> nil) then
   Continue;

  MemSet(Anims, SizeOf(Anims), 0);
  MemSet(AltAnims, SizeOf(AltAnims), 0);
  
  AltMax := 0;
  Max := Ord(UpperC(TX.Name[2]));
  if (Max >= Ord('0')) and (Max <= Ord('9')) then
   begin
    Dec(Max, Ord('0'));
    AltMax := 0;
    Anims[Max] := TX;
    Inc(Max);
   end
  else
   if (Max >= Ord('A')) and (Max <= Ord('J')) then
    begin
     AltMax := Ord(Max) - Ord('A');
     Max := 0;
     AltAnims[AltMax] := TX;
     Inc(AltMax);
    end
   else
    Sys_Error(['Bad animating texture "', PLChar(@TX.Name), '".']);

  for J := I + 1 to M.NumMiptex - 1 do
   begin
    TX2 := LoadModel.Textures[J];
    if (TX2 = nil) or ((TX2.Name[Low(TX2.Name)] <> '+') and (TX2.Name[Low(TX2.Name)] <> '-')) or
       (StrComp(@TX2.Name[3], @TX.Name[3]) <> 0) then
     Continue;

    Num := Ord(UpperC(TX2.Name[2]));
    if (Num >= Ord('0')) and (Num <= Ord('9')) then
     begin
      Dec(Num, Ord('0'));
      Anims[Num] := TX2;
      if Num + 1 > Max then
       Max := Num + 1;
     end
    else
     if (Num >= Ord('A')) and (Num <= Ord('J')) then
      begin
       Dec(Num, Ord('A'));
       AltAnims[Num] := TX2;
       if Num + 1 > AltMax then
        AltMax := Num + 1;
      end
     else
      Sys_Error(['Bad animating texture "', PLChar(@TX.Name), '".']);
   end;

  for J := 0 to Max - 1 do
   begin
    TX2 := Anims[J];
    if TX2 = nil then
     Sys_Error(['Missing frame ', J, ' of ', PLChar(@TX.Name), '.']);
    TX2.AnimTotal := Max;
    TX2.AnimMin := J;
    TX2.AnimMax := J + 1;
    TX2.AnimNext := Anims[(J + 1) mod Max];
    if AltMax > 0 then
     TX2.AlternateAnims := AltAnims[0];
   end;

  for J := 0 to AltMax - 1 do
   begin
    TX2 := AltAnims[J];
    if TX2 = nil then
     Sys_Error(['Missing frame ', J, ' of ', PLChar(@TX.Name), '.']);
    TX2.AnimTotal := AltMax;
    TX2.AnimMin := J;
    TX2.AnimMax := J + 1;
    TX2.AnimNext := AltAnims[(J + 1) mod AltMax];
    if Max > 0 then
     TX2.AlternateAnims := Anims[0];
   end;
 end;

DPrint(['Texture load time: ', RoundTo((Sys_FloatTime - Start) * 1000, -1), ' ms.']);
end;

procedure Mod_LoadLighting(const L: TLump);
begin
if L.FileLength > 0 then
 begin
  LoadModel.LightData := Hunk_AllocName(L.FileLength, @LoadName);
  Move(Pointer(UInt(ModBase) + L.FileOffset)^, LoadModel.LightData^, L.FileLength);
 end
else
 LoadModel.LightData := nil;
end;

procedure Mod_LoadPlanes(const L: TLump);
var
 PIn: PDPlane;
 POut: PMPlane;
 Count: UInt;
 I, J: Int;
 Bits: Int32;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadPlanes: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * 2 * SizeOf(POut^), @LoadName);

LoadModel.Planes := Pointer(POut);
LoadModel.NumPlanes := Count;

for I := 0 to Count - 1 do
 begin
  Bits := 0;
  for J := 0 to 2 do
   begin
    POut.Normal[J] := LittleFloat(PIn.Normal[J]);
    if POut.Normal[J] < 0 then
     Bits := Bits or (1 shl J);
   end;

  POut.Distance := LittleFloat(PIn.Distance);
  POut.PlaneType := LittleLong(PIn.PlaneType);
  POut.SignBits := Bits;

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;
end;

procedure Mod_LoadTexInfo(const L: TLump);
var
 PIn: PDTexInfo;
 POut: PMTexInfo;
 Count: UInt;
 I, J: Int;
 L1, L2: Single;
 Miptex: Int32;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadTexInfo: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

LoadModel.NumTexInfo := Count;
LoadModel.TexInfo := Pointer(POut);

for I := 0 to Count - 1 do
 begin
  for J := 0 to 3 do
   POut.Vecs[0][J] := LittleFloat(PIn.Vecs[0][J]);

  for J := 0 to 3 do
   POut.Vecs[1][J] := LittleFloat(PIn.Vecs[1][J]);

  L1 := Length(PVec3(@POut.Vecs[0])^);
  L2 := Length(PVec3(@POut.Vecs[1])^);
  L1 := (L1 + L2) / 2;
  if L1 < 0.32 then
   POut.MipAdjust := 4
  else
   if L1 < 0.49 then
    POut.MipAdjust := 3
   else
    if L1 < 0.99 then
     POut.MipAdjust := 2
    else
     POut.MipAdjust := 1;

  Miptex := LittleLong(PIn.MipTex);

  if LoadModel.Textures = nil then
   begin
    POut.Texture := NoTextureMIP;
    POut.Flags := 0;
   end
  else
   begin
    if (Miptex < 0) or (UInt(Miptex) >= LoadModel.NumTextures) then
     Sys_Error('Mod_LoadTexInfo: Miptex number is invalid.');

    POut.Texture := LoadModel.Textures[Miptex];
    if POut.Texture = nil then
     begin
      POut.Texture := NoTextureMIP;
      POut.Flags := 0;
     end
    else
     POut.Flags := LittleLong(PIn.Flags);
   end;

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;
end;

procedure Mod_LoadFaces(const L: TLump);
var
 PIn: PDFace;
 POut: PMSurface;
 Count: UInt;
 I, J: Int;
 PlaneNum, LightOfs: Int32;
 TexName: PLChar;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadFaces: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

LoadModel.NumSurfaces := Count;
LoadModel.Surfaces := Pointer(POut);

for I := 0 to Count - 1 do
 begin
  POut.FirstEdge := LittleLong(PIn.FirstEdge);
  POut.NumEdges := LittleShort(PIn.NumEdges);
  POut.Flags := 0;
  POut.Decals := nil;

  PlaneNum := LittleShort(PIn.PlaneNum);
  if LittleShort(PIn.Side) <> 0 then
   POut.Flags := POut.Flags or SURF_PLANEBACK;

  POut.Plane := Pointer(UInt(LoadModel.Planes) + UInt(SizeOf(TMPlane) * PlaneNum));
  POut.TexInfo := Pointer(UInt(LoadModel.TexInfo) + UInt(SizeOf(TMTexInfo) * LittleShort(PIn.TexInfo)));
  CalcSurfaceExtents(POut^);

  for J := 0 to MAXLIGHTMAPS - 1 do
   POut.Styles[J] := PIn.Styles[J];

  LightOfs := LittleLong(PIn.LightOfs);
  if LightOfs = -1 then
   POut.Samples := nil
  else
   POut.Samples := Pointer(UInt(LoadModel.LightData) + UInt(LightOfs));

  TexName := @POut.TexInfo.Texture.Name;
  if StrLComp(TexName, 'sky', 3) = 0 then
   POut.Flags := POut.Flags or (SURF_DRAWTILED or SURF_DRAWSKY)
  else
   if StrLComp(TexName, 'scroll', 6) = 0 then
    begin
     POut.Flags := POut.Flags or SURF_DRAWTILED;
     POut.Extents[0] := POut.TexInfo.Texture.Width;
     POut.Extents[1] := POut.TexInfo.Texture.Height;
    end
   else
    if (TexName^ = '!') or (StrLComp(TexName, 'laser', 5) = 0) or (StrLComp(TexName, 'water', 5) = 0) then
     begin
      POut.Flags := POut.Flags or (SURF_DRAWTILED or SURF_DRAWTURB);
      for J := 0 to 1 do
       begin
        POut.TextureMinS[J] := -8192;
        POut.Extents[J] := 16384;
        POut.TexInfo.Flags := POut.TexInfo.Flags or TEX_SPECIAL;
       end;
     end
    else
     if (POut.TexInfo.Flags and TEX_SPECIAL) > 0 then
      begin
       POut.Flags := POut.Flags or SURF_DRAWTILED;
       POut.Extents[0] := POut.TexInfo.Texture.Width;
       POut.Extents[1] := POut.TexInfo.Texture.Height;
      end;

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end; 
end;

procedure Mod_LoadMarkSurfaces(const L: TLump);
var
 PIn: ^Int16Array;
 POut: ^PMSurfaceArray;
 Count, J: UInt;
 I: Int;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadMarkSurfaces: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

LoadModel.NumMarkSurfaces := Count;
LoadModel.MarkSurfaces := Pointer(POut);
for I := 0 to Count - 1 do
 begin
  J := LittleShort(PIn[I]);
  if J >= LoadModel.NumSurfaces then
   Sys_Error('Mod_LoadMarkSurfaces: Bad surface number.');
  POut[I] := Pointer(UInt(LoadModel.Surfaces) + J * SizeOf(TMSurface));
 end;
end;

procedure Mod_LoadVisibility(const L: TLump);
begin
if L.FileLength > 0 then
 begin
  LoadModel.VisData := Hunk_AllocName(L.FileLength, @LoadName);
  Move(Pointer(UInt(ModBase) + L.FileOffset)^, LoadModel.VisData^, L.FileLength);
 end
else
 LoadModel.VisData := nil;
end;

procedure Mod_LoadLeafs(const L: TLump);
var
 PIn: PDLeaf;
 POut: PMLeaf;
 Count: UInt;
 I, J, P: Int;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadLeafs: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

LoadModel.NumLeafs := Count;
LoadModel.Leafs := Pointer(POut);
for I := 0 to Count - 1 do
 begin
  for J := 0 to 2 do
   begin
    POut.MinMaxS[J] := LittleShort(PIn.MinS[J]);
    POut.MinMaxS[J + 3] := LittleShort(PIn.MaxS[J]);
   end;

  POut.Contents := LittleLong(PIn.Contents);
  POut.FirstMarkSurface := Pointer(UInt(LoadModel.MarkSurfaces) + UInt(LittleShort(PIn.FirstMarkSurface) * SizeOf(PMSurface)));
  POut.NumMarkSurfaces := LittleShort(PIn.NumMarkSurfaces);

  P := LittleLong(PIn.VisOfs);
  if P = -1 then
   POut.CompressedVis := nil
  else
   POut.CompressedVis := Pointer(UInt(LoadModel.VisData) + UInt(P));
  POut.EFrags := nil;

  for J := 0 to 3 do
   POut.AmbientSoundLevel[J] := PIn.AmbientLevel[J];

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));   
 end;
end;

procedure Mod_LoadNodes(const L: TLump);
var
 PIn: PDNode;
 POut: PMNode;
 Count: UInt;
 I, J, P: Int;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadNodes: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

LoadModel.NumNodes := Count;
LoadModel.Nodes := Pointer(POut);
for I := 0 to Count - 1 do
 begin
  for J := 0 to 2 do
   begin
    POut.MinMaxS[J] := LittleShort(PIn.MinS[J]);
    POut.MinMaxS[J + 3] := LittleShort(PIn.MaxS[J]);
   end;

  POut.Plane := Pointer(UInt(LoadModel.Planes) + UInt(LittleLong(PIn.PlaneNum) * SizeOf(TMPlane)));
  POut.FirstSurface := LittleShort(PIn.FirstFace);
  POut.NumSurfaces := LittleShort(PIn.NumFaces);

  for J := 0 to 1 do
   begin
    P := LittleShort(PIn.Children[J]);
    if P >= 0 then
     POut.Children[J] := Pointer(UInt(LoadModel.Nodes) + UInt(P) * SizeOf(TMNode))
    else
     POut.Children[J] := Pointer(UInt(LoadModel.Leafs) + UInt(-1 - P) * SizeOf(TMLeaf));
   end;

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;

if Count > 0 then
 Mod_SetParent(Pointer(LoadModel.Nodes), nil);
end;

procedure Mod_LoadClipNodes(const L: TLump);
var
 PIn, POut: PDClipNode;
 Count: UInt;
 I: Int;
 Hull: PHull;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadClipNodes: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

LoadModel.NumClipNodes := Count;
LoadModel.ClipNodes := Pointer(POut);

for I := 1 to 3 do // yep, 1 to 3
 begin
  Hull := @LoadModel.Hulls[I];
  Hull.ClipNodes := Pointer(POut);
  Hull.FirstClipNode := 0;
  Hull.LastClipNode := Count - 1;
  Hull.Planes := Pointer(LoadModel.Planes);
 end;

Hull := @LoadModel.Hulls[1];
Hull.ClipMinS[0] := -16;
Hull.ClipMinS[1] := -16;
Hull.ClipMinS[2] := -36;
Hull.ClipMaxS[0] := 16;
Hull.ClipMaxS[1] := 16;
Hull.ClipMaxS[2] := 36;
Hull := @LoadModel.Hulls[2];
Hull.ClipMinS[0] := -32;
Hull.ClipMinS[1] := -32;
Hull.ClipMinS[2] := -32;
Hull.ClipMaxS[0] := 32;
Hull.ClipMaxS[1] := 32;
Hull.ClipMaxS[2] := 32;
Hull := @LoadModel.Hulls[3];
Hull.ClipMinS[0] := -16;
Hull.ClipMinS[1] := -16;
Hull.ClipMinS[2] := -18;
Hull.ClipMaxS[0] := 16;
Hull.ClipMaxS[1] := 16;
Hull.ClipMaxS[2] := 18;

for I := 0 to Count - 1 do
 begin
  POut.PlaneNum := LittleLong(PIn.PlaneNum);
  POut.Children[0] := LittleShort(PIn.Children[0]);
  POut.Children[1] := LittleShort(PIn.Children[1]);

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;
end;

procedure Mod_LoadSubModels(const L: TLump);
var
 PIn, POut: PDModel;
 Count: UInt;
 I, J: Int;
begin
PIn := Pointer(UInt(ModBase) + L.FileOffset);
if (L.FileLength mod SizeOf(PIn^)) > 0 then
 Sys_Error(['Mod_LoadSubModels: Bad lump size in "', PLChar(@LoadModel.Name), '".']);
Count := L.FileLength div SizeOf(PIn^);
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

LoadModel.NumSubModels := Count;
LoadModel.SubModels := Pointer(POut);

for I := 0 to Count - 1 do
 begin
  for J := 0 to 2 do
   begin
    POut.MinS[J] := LittleFloat(PIn.MinS[J]) - 1;
    POut.MaxS[J] := LittleFloat(PIn.MaxS[J]) + 1;
    POut.Origin[J] := LittleFloat(PIn.Origin[J]);
   end;

  for J := 0 to MAX_MAP_HULLS - 1 do
   POut.HeadNode[J] := LittleLong(PIn.HeadNode[J]);

  POut.VisLeafs := LittleLong(PIn.VisLeafs);
  POut.FirstFace := LittleLong(PIn.FirstFace);
  POut.NumFaces := LittleLong(PIn.NumFaces);

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));  
 end;
end;

procedure Mod_MakeHull0;
var
 PIn, Child: PMNode;
 POut: PDClipNode;
 Hull: PHull;
 Count: UInt;
 I, J: Int;
begin
PIn := Pointer(LoadModel.Nodes);
Count := LoadModel.NumNodes;
POut := Hunk_AllocName(Count * SizeOf(POut^), @LoadName);

Hull := @LoadModel.Hulls[0];
Hull.ClipNodes := Pointer(POut);
Hull.Planes := Pointer(LoadModel.Planes);
Hull.FirstClipNode := 0;
Hull.LastClipNode := Count - 1;

for I := 0 to Count - 1 do
 begin
  POut.PlaneNum := (UInt(PIn.Plane) - UInt(LoadModel.Planes)) div SizeOf(PIn.Plane^);

  for J := 0 to 1 do
   begin
    Child := PIn.Children[J];
    if Child.Contents < 0 then
     POut.Children[J] := Child.Contents
    else
     POut.Children[J] := (UInt(Child) - UInt(LoadModel.Nodes)) div SizeOf(Child^);
   end;

  Inc(UInt(PIn), SizeOf(PIn^));
  Inc(UInt(POut), SizeOf(POut^));
 end;
end;

procedure Mod_LoadBrushModel(var M: TModel; P: Pointer);
var
 Header: PDHeader;
 I, J: Int;
 SM: PDModel;
 M2: PModel;
 SMName: array[1..MAX_MODEL_NAME] of LChar;
begin
LoadModel.ModelType := ModBrush;
Header := P;
Header.Version := LittleLong(Header.Version);
for I := 0 to HEADER_LUMPS - 1 do
 begin
  Header.Lumps[I].FileOffset := LittleLong(Header.Lumps[I].FileOffset);
  Header.Lumps[I].FileLength := LittleLong(Header.Lumps[I].FileLength);
 end;

if (Header.Version <> BSPVERSION29) and (Header.Version <> BSPVERSION30) then
 Sys_Error(['Mod_LoadBrushModel: "', PLChar(@M.Name), '" has wrong version number (', Header.Version, '; should be ', BSPVERSION30, ').']);

ModBase := P;
Mod_LoadVertexes(Header.Lumps[LUMP_VERTEXES]);
Mod_LoadEdges(Header.Lumps[LUMP_EDGES]);
Mod_LoadSurfEdges(Header.Lumps[LUMP_SURFEDGES]);
if StrIComp(GameDir, 'bshift') <> 0 then
 begin
  Mod_LoadEntities(Header.Lumps[0]);
  Mod_LoadTextures(Header.Lumps[LUMP_TEXTURES]);
  Mod_LoadLighting(Header.Lumps[LUMP_LIGHTING]);
  Mod_LoadPlanes(Header.Lumps[1]);
 end
else
 begin
  Mod_LoadEntities(Header.Lumps[1]);
  Mod_LoadTextures(Header.Lumps[LUMP_TEXTURES]);
  Mod_LoadLighting(Header.Lumps[LUMP_LIGHTING]);
  Mod_LoadPlanes(Header.Lumps[0]);
 end;
Mod_LoadTexInfo(Header.Lumps[LUMP_TEXINFO]);
Mod_LoadFaces(Header.Lumps[LUMP_FACES]);
Mod_LoadMarkSurfaces(Header.Lumps[LUMP_MARKSURFACES]);
Mod_LoadVisibility(Header.Lumps[LUMP_VISIBILITY]);
Mod_LoadLeafs(Header.Lumps[LUMP_LEAFS]);
Mod_LoadNodes(Header.Lumps[LUMP_NODES]);
Mod_LoadClipNodes(Header.Lumps[LUMP_CLIPNODES]);
Mod_LoadSubModels(Header.Lumps[LUMP_MODELS]);
Mod_MakeHull0;

M.NumFrames := 2;
M.Flags := 0;
M2 := @M;
for I := 0 to M.NumSubModels - 1 do
 begin
  SM := @M2.SubModels[I];
  M2.Hulls[0].FirstClipNode := SM.HeadNode[0];
  for J := 1 to MAX_MAP_HULLS - 1 do
   begin
    M2.Hulls[J].FirstClipNode := SM.HeadNode[J];
    M2.Hulls[J].LastClipNode := M2.NumClipNodes - 1;
   end;

  M2.FirstModelSurface := SM.FirstFace;
  M2.NumModelSurfaces := SM.NumFaces;

  M2.MinS := PVec3(@SM.MinS)^;
  M2.MaxS := PVec3(@SM.MaxS)^;
  M2.Radius := RadiusFromBounds(M2.MinS, M2.MaxS);

  M2.NumLeafs := SM.VisLeafs;
  if UInt(I) < M2.NumSubModels - 1 then
   begin
    SMName[1] := '*';
    IntToStr(I + 1, SMName[2], SizeOf(SMName));
    LoadModel := Mod_FindName(False, @SMName);
    Move(M2^, LoadModel^, SizeOf(LoadModel^));
    StrLCopy(@LoadModel.Name, @SMName, MAX_MODEL_NAME - 1);
    M2 := LoadModel;
   end;
 end;
end;



function Mod_LoadModel(var M: TModel; Crash, NeedCRC: Boolean): PModel;
var
 Index, L: UInt;
 P: Pointer;
 CRC: TCRC;
begin
if (M.ModelType = ModAlias) or (M.ModelType = ModStudio) then
 if Cache_Check(M.Cache) <> nil then
  begin
   M.NeedLoad := NL_PRESENT;
   Result := @M;
   Exit;
  end
 else
else
 if (M.NeedLoad = NL_PRESENT) or (M.NeedLoad = NL_CLIENT) then
  begin
   Result := @M;
   Exit;
  end;

L := 0; // required
P := COM_LoadFile(@M.Name, FILE_ALLOC_MEMORY, @L);
if P = nil then
 begin
  if Crash then
   Sys_Error(['Mod_LoadModel: ', PLChar(@M.Name), ' not found.']);
  Result := nil;
  Exit;
 end;

if NeedCRC then
 begin
  Index := (UInt(@M) - UInt(@Mod_Known)) div SizeOf(TModel);
  if Mod_KnownInfo[Index].NeedCRC then
   begin
    CRC32_Init(CRC);
    CRC32_ProcessBuffer(CRC, P, L);
    CRC := CRC32_Final(CRC);

    if not Mod_KnownInfo[Index].Filled then
     begin
      Mod_KnownInfo[Index].Filled := True;
      Mod_KnownInfo[Index].CRC := CRC;
     end
    else
     if CRC <> Mod_KnownInfo[Index].CRC then
      begin
       Sys_Error(['"', PLChar(@M.Name), '" has been modified since starting the engine. Consider running system diagnostics to check for faulty hardware.']);
       Result := nil;
       Exit;
      end;
   end;
 end;

if developer.Value >= 1 then
 DPrint(['Loading "', PLChar(@M.Name), '".']);

COM_FileBase(@M.Name, @LoadName);
LoadModel := @M;
M.NeedLoad := NL_PRESENT;

case LittleLong(PModelHeader(P).FileTag) of
 Ord('I') + Ord('D') shl 8 + Ord('P') shl 16 + Ord('O') shl 24: Mod_LoadAliasModel(M, P);
 Ord('I') + Ord('D') shl 8 + Ord('S') shl 16 + Ord('P') shl 24: Mod_LoadSpriteModel(M, P);
 Ord('I') + Ord('D') shl 8 + Ord('S') shl 16 + Ord('T') shl 24: Mod_LoadStudioModel(M, P);
 else Mod_LoadBrushModel(M, P);
end;

COM_FreeFile(P);
Result := @M;
end;

function Mod_ExtraData(var M: TModel): Pointer;
begin
if @M <> nil then
 begin
  Result := Cache_Check(M.Cache);
  if Result = nil then
   begin
    Mod_LoadModel(M, True, False);
    if M.Cache.Data = nil then
     Sys_Error('Mod_ExtraData: Caching failed.');

    Result := M.Cache.Data;
   end;
 end
else
 Result := nil;
end;

function Mod_PointInLeaf(const P: TVec3; const M: TModel): PMLeaf;
var
 Node: PMNode;
 Plane: PMPlane;
 D: Single;
begin
if (@M = nil) or (M.Nodes = nil) then
 Sys_Error('Mod_PointInLeaf: Bad model.');

Node := Pointer(M.Nodes);
while Node.Contents >= 0 do
 begin
  Plane := Node.Plane;
  if Plane.PlaneType > 2 then
   D := DotProduct(Plane.Normal, P) - Plane.Distance
  else
   D := P[Plane.PlaneType] - Plane.Distance;

  if D > 0 then
   Node := Node.Children[0]
  else
   Node := Node.Children[1];
 end;

Result := PMLeaf(Node);
end;

procedure Mod_ClearAll;
var
 I: Int;
 P: PModel;
begin
for I := 0 to Mod_NumKnown - 1 do
 begin
  P := @Mod_Known[I];
  if P.NeedLoad <> NL_CLIENT then
   begin
    P.NeedLoad := NL_UNREFERENCED;
    if P.ModelType = ModSprite then
     P.Cache.Data := nil;
   end;
 end;
end;

procedure Mod_FillInCRCInfo(NeedCRC: Boolean; Index: UInt);
begin
Mod_KnownInfo[Index].NeedCRC := NeedCRC;
Mod_KnownInfo[Index].Filled := False;
Mod_KnownInfo[Index].CRC := 0;
end;

function Mod_FindName(NeedCRC: Boolean; Name: PLChar): PModel;
var
 I, J: Int;
 P, Avail: PModel;
begin
if (Name = nil) or (Name^ = #0) then
 Sys_Error('Mod_FindName: Invalid name.');

J := -1;
Avail := nil;
P := @Mod_Known[Low(Mod_Known)];

for I := 0 to Mod_NumKnown - 1 do
 begin
  P := @Mod_Known[I];
  if StrComp(@P.Name, Name) = 0 then
   begin
    J := I;
    Break;
   end
  else
   if (P.NeedLoad = NL_UNREFERENCED) and ((Avail = nil) or ((P.ModelType <> ModAlias) and (P.ModelType <> ModStudio))) then
    Avail := P;
 end;

if J = -1 then
 begin
  P := @Mod_Known[Mod_NumKnown];

  if Mod_NumKnown < MAX_MOD_KNOWN then
   begin
    Mod_FillInCRCInfo(NeedCRC, Mod_NumKnown);
    Inc(Mod_NumKnown);
   end
  else
   begin
    if Avail = nil then
     Sys_Error('No avaliable space in model cache.');
    P := Avail;
    Mod_FillInCRCInfo(NeedCRC, (UInt(P) - UInt(@Mod_Known)) div SizeOf(TModel));
   end;

  StrLCopy(@P.Name, Name, MAX_MODEL_NAME - 1);
  if P.NeedLoad <> NL_CLIENT then
   P.NeedLoad := NL_NEEDS_LOADED;
 end;
 
Result := P;
end;

function Mod_ValidateCRC(Name: PLChar; CRC: TCRC): Boolean;
var
 Index: UInt;
begin
Index := (UInt(Mod_FindName(True, Name)) - UInt(@Mod_Known)) div SizeOf(TModel);
if Mod_KnownInfo[Index].Filled then
 Result := CRC = Mod_KnownInfo[Index].CRC
else
 Result := True;
end;

procedure Mod_NeedCRC(Name: PLChar; NeedCRC: Boolean);
var
 Index: UInt;
begin
Index := (UInt(Mod_FindName(False, Name)) - UInt(@Mod_Known)) div SizeOf(TModel);
Mod_KnownInfo[Index].NeedCRC := NeedCRC;
end;

function Mod_ForName(Name: PLChar; Crash, NeedCRC: Boolean): PModel;
begin
Result := Mod_FindName(NeedCRC, Name);
if Result <> nil then
 Result := Mod_LoadModel(Result^, Crash, NeedCRC);
end;

procedure Mod_MarkClient(var M: TModel);
begin
M.NeedLoad := NL_CLIENT;
end;

function SurfaceAtPoint(const M: TModel; const Node: TMNode; const MinS, MaxS: TVec3): PMSurface;
var
 F1, F2, F3, F4, D: Single;
 V: TVec3;
 I: Int;
 Surface: PMSurface;
 TexInfo: PMTexInfo;
begin
if Node.Contents < 0 then
 Result := nil
else
 begin
  F1 := DotProduct(MinS, Node.Plane.Normal) - Node.Plane.Distance;
  F2 := DotProduct(MaxS, Node.Plane.Normal) - Node.Plane.Distance;

  if ((F1 < 0) and (F2 < 0)) or ((F1 >= 0) and (F2 >= 0)) then
   Result := SurfaceAtPoint(M, Node.Children[UInt(F1 < 0)]^, MinS, MaxS)
  else
   begin
    D := F1 / (F1 - F2);
    for I := 0 to 2 do
     V[I] := (MaxS[I] - MinS[I]) * D + MinS[I];
    Result := SurfaceAtPoint(M, Node.Children[UInt(F1 < 0)]^, MinS, V);
    if (Result = nil) and (((F1 >= 0) or (F2 >= 0)) and ((F1 < 0) or (F2 < 0))) then
     begin
      Surface := @M.Surfaces[Node.FirstSurface];
      for I := 1 to Node.NumSurfaces do
       begin
        TexInfo := Surface.TexInfo;
        F3 := DotProduct(V, PVec3(@TexInfo.Vecs[0])^) + TexInfo.Vecs[0][3];
        F4 := DotProduct(V, PVec3(@TexInfo.Vecs[1])^) + TexInfo.Vecs[1][3];
        if (F3 >= Surface.TextureMinS[0]) and (F4 >= Surface.TextureMinS[1]) and
           (F3 - Surface.TextureMinS[0] <= Surface.Extents[0]) and
           (F4 - Surface.TextureMinS[1] <= Surface.Extents[1]) then
         begin
          Result := Surface;
          Exit;
         end;
        Inc(UInt(Surface), SizeOf(Surface^));
       end;

      Result := SurfaceAtPoint(M, Node.Children[UInt(F1 >= 0)]^, V, MaxS);
     end;
   end;
 end;
end;

end.
