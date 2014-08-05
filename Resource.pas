unit Resource;    // rename to SVRes

{$I HLDS.inc}

interface

uses SysUtils, Default, SDK;

procedure SV_SetResourceLists(var C: TClient);

procedure COM_ClearCustomizationList(var List: TCustomization);
function COM_CreateCustomization(var List: TCustomization; const Resource: TResource; PlayerIndex: Int32; Flags: TResourceFlags; var Customization: PCustomization; var LumpCount: UInt32): Boolean;
function COM_SizeOfResourceList(const List: TResource; var ResInfo: TResourceInfo): UInt;

procedure SV_ClearResourceLists(var C: TClient);
procedure SV_CreateCustomizationList(var C: TClient);

procedure SV_MoveToOnHandList(var Res: TResource);
procedure SV_AddToResourceList(var Res, List: TResource);
procedure SV_RemoveFromResourceList(var Res: TResource);
procedure SV_ClearResourceList(var Res: TResource);

procedure SV_Send_FileTxferFailed(S: PLChar);
function IsSafeFile(S: PLChar): Boolean;

procedure SV_BeginFileDownload_F; cdecl;

procedure SV_CreateResourceList;
procedure SV_CreateGenericResources;

function SV_RequestMissingResources: Boolean;

function SV_TransferConsistencyInfo: UInt;

procedure SV_ParseResourceList(var C: TClient);
procedure SV_ParseConsistencyResponse(var C: TClient);

procedure SV_ProcessFile(var C: TClient; Name: PLChar);

procedure SV_RequestMissingResourcesFromClients;

var
 sv_allowdownload: TCVar = (Name: 'sv_allowdownload'; Data: '1'; Flags: [FCVAR_SERVER]);
 sv_allowupload: TCVar = (Name: 'sv_allowupload'; Data: '1'; Flags: [FCVAR_SERVER]);

 sv_uploadmax: TCVar = (Name: 'sv_uploadmax'; Data: '0.5'; Flags: [FCVAR_SERVER]);
 sv_uploadmaxnum: TCVar = (Name: 'sv_uploadmaxnum'; Data: '128'; Flags: [FCVAR_SERVER]); // 128 for now, change to 4
 sv_uploadmaxsingle: TCVar = (Name: 'sv_uploadmaxsingle'; Data: '0.128'; Flags: [FCVAR_SERVER]);
 sv_uploaddecalsonly: TCVar = (Name: 'sv_uploaddecalsonly'; Data: '1'; Flags: [FCVAR_SERVER]);

 sv_send_resources: TCVar = (Name: 'sv_send_resources'; Data: '1');
 sv_send_logos: TCVar = (Name: 'sv_send_logos'; Data: '1');

implementation

uses Common, Console, Decal, Encode, FileSys, GameLib, Host, MathLib, Memory, MsgBuf, Network, HPAK, Renderer, Server, SVClient, SVExport, SysMain;

const
 ValidFileExt: array[1..9] of PLChar = ('mdl', 'tga', 'wad', 'spr', 'bsp', 'wav', 'mp3', 'res', 'txt');

procedure SV_SetResourceLists(var C: TClient);
begin
C.DownloadList.Next := @C.DownloadList;
C.DownloadList.Prev := @C.DownloadList;
C.UploadList.Next := @C.UploadList;
C.UploadList.Prev := @C.UploadList;
end;

procedure COM_ClearCustomizationList(var List: TCustomization);
var
 P, P2: PCustomization;
begin
P := List.Next;
while P <> nil do
 begin
  P2 := P.Next;
  if P.InUse then
   begin
    if P.Buffer <> nil then
     Mem_Free(P.Buffer);

    if P.Info <> nil then
     begin
      if P.Resource.ResourceType = RT_DECAL then
       Draw_FreeWAD(P.Info);
      
      Mem_Free(P.Info);
     end;
   end;

  Mem_Free(P);
  P := P2;
 end;

List.Next := nil;
end;

function COM_CreateCustomization(var List: TCustomization; const Resource: TResource; PlayerIndex: Int32; Flags: TResourceFlags; var Customization: PCustomization; var LumpCount: UInt32): Boolean;
var
 P: PCustomization;
 E: Boolean;
 Decal: PCacheWAD;
begin
E := False;
P := Mem_ZeroAlloc(SizeOf(TCustomization));
Move(Resource, P.Resource, SizeOf(P.Resource));

if Resource.DownloadSize = 0 then
 E := True
else
 begin
  P.InUse := True;
  if not (RES_FATALIFMISSING in Flags) then
   begin
    P.Buffer := COM_LoadFile(@Resource.Name, FILE_ALLOC_MEMORY, nil);
    if P.Buffer = nil then
     E := True;
   end
  else
   if not HPAK_GetDataPointer('custom.hpk', Resource, @P.Buffer, nil) then
    E := True;

  if not E then
   if (RES_CUSTOM in P.Resource.Flags) and (P.Resource.ResourceType = RT_DECAL) then
    begin
     P.Resource.PlayerNum := PlayerIndex;
     if not CustomDecal_Validate(P.Buffer, Resource.DownloadSize) then
      E := True
     else
      if not (RES_CUSTOM in Flags) then
       begin
        Decal := Mem_ZeroAlloc(SizeOf(TCacheWAD));
        P.Info := Decal;
        if (Resource.DownloadSize >= 1024) and (Resource.DownloadSize <= 20480) and
            CustomDecal_Init(Decal, P.Buffer, Resource.DownloadSize, PlayerIndex) and
           (Decal.DecalCount > 0) then
         begin
          if @LumpCount <> nil then
           LumpCount := Decal.DecalCount;

          P.Translated := True;
          P.UserData1 := 0;
          P.UserData2 := Decal.DecalCount;
          if RES_WASMISSING in Flags then
           begin
            Draw_FreeWAD(P.Info);
            Mem_FreeAndNil(P.Info);
           end;
         end
        else
         E := True;
       end;
    end;
 end;

if E then
 begin
  if P.Buffer <> nil then
   Mem_Free(P.Buffer);
  if P.Info <> nil then
   Mem_Free(P.Info);
  Mem_Free(P);

  if @Customization <> nil then
   Customization := nil;
  if @LumpCount <> nil then
   LumpCount := 0;
 end
else
 begin
  if @Customization <> nil then
   Customization := P;

  P.Next := List.Next;
  List.Next := P;
 end;

Result := not E;
end;

function COM_SizeOfResourceList(const List: TResource; var ResInfo: TResourceInfo): UInt;
var
 P: PResource;
begin
Result := 0;
MemSet(ResInfo, SizeOf(ResInfo), 0);

P := List.Next;
while P <> @List do
 begin
  if P.ResourceType <= RT_WORLD then
   begin
    Inc(Result, P.DownloadSize);
    if (P.ResourceType <> RT_MODEL) or (P.Index <> 1) then
     Inc(ResInfo.Info[Byte(P.ResourceType)].Size, P.DownloadSize)
    else
     Inc(ResInfo.Info[Byte(RT_WORLD)].Size, P.DownloadSize);
   end;

  P := P.Next;
 end;
end;

procedure SV_PropagateCustomizations;
var
 I: Int;
 P: PCustomization;
 C: PClient;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  C := @SVS.Clients[I];
  if (C.Active or C.Spawned) and not C.FakeClient then
   begin
    P := C.Customization.Next;
    while P <> nil do
     begin
      if P.InUse then
       begin
        MSG_WriteByte(C.Netchan.NetMessage, SVC_CUSTOMIZATION);
        MSG_WriteByte(C.Netchan.NetMessage, I);
        MSG_WriteByte(C.Netchan.NetMessage, P.Resource.ResourceType);
        MSG_WriteString(C.Netchan.NetMessage, @P.Resource.Name);
        MSG_WriteShort(C.Netchan.NetMessage, P.Resource.Index);
        MSG_WriteLong(C.Netchan.NetMessage, P.Resource.DownloadSize);
        MSG_WriteByte(C.Netchan.NetMessage, Byte(P.Resource.Flags));
        if RES_CUSTOM in P.Resource.Flags then
         SZ_Write(C.Netchan.NetMessage, @P.Resource.MD5Hash, SizeOf(P.Resource.MD5Hash));
       end;
       
      P := P.Next;
     end;
   end;
 end;
end;

function SV_CheckFile(var SB: TSizeBuf; Name: PLChar): Boolean;
var
 Buf: array[1..128] of LChar;
 S: PLChar;
 Res: TResource;
 MD5S: TMD5HashStr;
begin
MemSet(Res, SizeOf(Res), 0);
if (StrLen(Name) = 36) and (StrLComp(Name, '!MD5', 4) = 0) and MD5_IsValid(PLChar(UInt(Name) + 4)) then
 begin
  COM_HexConvert(PLChar(UInt(Name) + 4), 32, @Res.MD5Hash);
  if HPAK_GetDataPointer('custom.hpk', Res, nil, nil) then
   begin
    Result := True;
    Exit;
   end;
 end;

if sv_allowupload.Value = 0 then
 Result := True
else
 begin
  S := StrECopy(@Buf, 'upload "!MD5');
  MD5_Print(Res.MD5Hash, MD5S);
  S := StrECopy(S, @MD5S);
  StrCopy(S, '"'#10);

  MSG_WriteByte(SB, SVC_STUFFTEXT);
  MSG_WriteString(SB, @Buf);
  Result := False;
 end;
end;

procedure SV_ClearResourceLists(var C: TClient);
begin
if @C = nil then
 Sys_Error('SV_ClearResourceLists: Bad client pointer.')
else
 begin
  SV_ClearResourceList(C.UploadList);
  SV_ClearResourceList(C.DownloadList);
 end;
end;

procedure SV_CreateCustomizationList(var C: TClient);
var
 C2, C3: PCustomization;
 P: PResource;
 LumpCount: UInt32;
begin
P := C.DownloadList.Next;
C.Customization.Next := nil;

while P <> @C.DownloadList do
 begin
  C2 := C.Customization.Next;
  while C2 <> nil do
   if CompareMem(@C2.Resource.MD5Hash, @P.MD5Hash, SizeOf(P.MD5Hash)) then
    begin
     DPrint(['SV_CreateCustomizationList: Ignoring duplicate resource for player "', PLChar(@C.NetName), '".']);
     P := P.Next;
     Continue;
    end
   else
    C2 := C2.Next;

  LumpCount := 0;
  if COM_CreateCustomization(C.Customization, P^, -1, [RES_WASMISSING, RES_FATALIFMISSING], C3, LumpCount) then
   begin
    C3.UserData2 := LumpCount;
    DLLFunctions.PlayerCustomization(C.Entity^, C3);
   end
  else
   if sv_allowupload.Value = 0 then
    Print(['Ignoring custom decal from "', PLChar(@C.NetName), '", sv_allowupload is set to 0.'])
   else
    Print(['Ignoring invalid custom decal from "', PLChar(@C.NetName), '".']);

  P := P.Next;
 end;
end;

procedure SV_Customization(var C: TClient; const Res: TResource; SkipHost: Boolean);
var
 I: Int;
 Index: UInt;
 P: PClient;
begin
Index := (UInt(@C) - UInt(SVS.Clients)) div SizeOf(TClient);

for I := 0 to SVS.MaxClients - 1 do
 begin
  P := @SVS.Clients[I];
  if (P.Active or P.Spawned) and not P.FakeClient and ((UInt(I) <> Index) or not SkipHost) then
   begin
    MSG_WriteByte(P.Netchan.NetMessage, SVC_CUSTOMIZATION);
    MSG_WriteByte(P.Netchan.NetMessage, Index);
    MSG_WriteByte(P.Netchan.NetMessage, Res.ResourceType);
    MSG_WriteString(P.Netchan.NetMessage, @Res.Name);
    MSG_WriteShort(P.Netchan.NetMessage, Res.Index);
    MSG_WriteLong(P.Netchan.NetMessage, Res.DownloadSize);
    MSG_WriteByte(P.Netchan.NetMessage, Byte(Res.Flags));
    if RES_CUSTOM in Res.Flags then
     SZ_Write(P.Netchan.NetMessage, @Res.MD5Hash, SizeOf(Res.MD5Hash));
   end;
 end;
end;

procedure SV_RegisterResources;
var
 C: PClient;
 P, P2: PResource;
begin
C := HostClient;
C.HasMissingResources := False;

P := C.DownloadList.Next;
while P <> @C.DownloadList do
 begin
  P2 := P.Next;
  SV_CreateCustomizationList(C^);
  SV_Customization(C^, P^, True);
  P := P2;
 end;

HostClient := C;
end;

procedure SV_MoveToOnHandList(var Res: TResource);
begin
if @Res <> nil then
 begin
  SV_RemoveFromResourceList(Res);
  SV_AddToResourceList(Res, HostClient.DownloadList);
 end
else
 DPrint('SV_MoveToOnHandList: Bad resource pointer.');
end;

procedure SV_AddToResourceList(var Res, List: TResource);
begin
if (Res.Prev <> nil) or (Res.Next <> nil) then
 Print('SV_AddToResourceList: Resource already linked.')
else
 begin
  Res.Prev := List.Prev; // cf?
  List.Prev.Next := @Res; // cf
  List.Prev := @Res; // cf  
  Res.Next := @List; // cf
 end;
end;

procedure SV_ClearResourceList(var Res: TResource);
var
 P, P2: PResource;
begin
P := Res.Next;
while P <> nil do
 if P = @Res then
  Break
 else
  begin
   P2 := P.Next;
   SV_RemoveFromResourceList(P^);
   Mem_Free(P);
   P := P2;
  end;

Res.Prev := @Res;
Res.Next := @Res;
end;

procedure SV_RemoveFromResourceList(var Res: TResource);
begin
Res.Prev.Next := Res.Next;
Res.Next.Prev := Res.Prev;
Res.Prev := nil;
Res.Next := nil;
end;

function SV_EstimateNeededResources: UInt;
var
 P: PResource;
begin
Result := 0;
P := HostClient.UploadList.Next;
while P <> @HostClient.UploadList do
 begin
  if (P.ResourceType = RT_DECAL) and not HPAK_ResourceForHash('custom.hpk', @P.MD5Hash, nil) and
     (P.DownloadSize > 0) then
   begin
    Inc(Result, P.DownloadSize);
    Include(P.Flags, RES_WASMISSING);
   end;

  P := P.Next;
 end;
end;

procedure SV_RequestMissingResourcesFromClients;
var
 I: Int;
begin
for I := 0 to SVS.MaxClients - 1 do
 begin
  HostClient := @SVS.Clients[I];
  if (HostClient.Active or HostClient.Spawned) and not HostClient.FakeClient then
   while SV_RequestMissingResources do
    ;
 end;
end;

function SV_UploadComplete(var C: TClient): Boolean;
begin
if C.UploadList.Next = @C.UploadList then
 begin
  SV_RegisterResources;
  SV_PropagateCustomizations;
  if sv_allowupload.Value <> 0 then
   DPrint('Custom resource propagation complete.');

  C.UploadComplete := True;
  Result := True;
 end
else
 Result := False;
end;

procedure SV_BatchUploadRequest(var C: TClient);
var
 P, P2: PResource;
 Buf: array[1..128] of LChar;
 MD5S: TMD5HashStr;
 S: PLChar;
begin                                     
P := C.UploadList.Next;
while P <> @C.UploadList do
 begin
  P2 := P.Next;
  if not (RES_WASMISSING in P.Flags) then
   SV_MoveToOnHandList(P^)
  else
   if P.ResourceType = RT_DECAL then
    if RES_CUSTOM in P.Flags then
     begin
      MD5_Print(P.MD5Hash, MD5S);
      S := StrECopy(@Buf, '!MD5');
      StrCopy(S, @MD5S);
      if SV_CheckFile(C.Netchan.NetMessage, @Buf) then
       SV_MoveToOnHandList(P^);
     end
    else
     begin
      Print('SV_BatchUploadRequest: Non-customization in upload queue.');
      SV_MoveToOnHandList(P^);
     end;

  P := P2;
 end;
end;

function SV_RequestMissingResources: Boolean;
begin
if HostClient.HasMissingResources and not HostClient.UploadComplete then
 SV_UploadComplete(HostClient^);

Result := False;
end;

// these are checked

procedure SV_CheckUploadCVars;
begin
if sv_uploadmaxsingle.Value < 0 then
 CVar_DirectSet(sv_uploadmaxsingle, '0');
if sv_uploadmax.Value < 0 then
 CVar_DirectSet(sv_uploadmax, '0');
if sv_uploadmaxnum.Value < 0 then
 CVar_DirectSet(sv_uploadmaxnum, '0');
end;

procedure SV_ParseResourceList(var C: TClient);
var
 DecalsOnly: Boolean;
 I, J, NumRes, MaxAllowed: Int;
 ResInfo: TResourceInfo;
 Size, EstSize, MaxSize: UInt;
 Res: TResource;
 P: PResource;
begin
SV_CheckUploadCVars;

SV_ClearResourceList(C.UploadList);
SV_ClearResourceList(C.DownloadList);

MaxSize := Trunc(sv_uploadmaxsingle.Value * 1024 * 1024);
DecalsOnly := sv_uploaddecalsonly.Value <> 0;
MaxAllowed := Trunc(sv_uploadmaxnum.Value);
J := 0;

NumRes := MSG_ReadShort;
for I := 0 to NumRes - 1 do
 begin
  MemSet(Res, SizeOf(Res), 0);
  StrLCopy(@Res.Name, MSG_ReadString, SizeOf(Res.Name) - 1);
  Res.ResourceType := MSG_ReadByte;
  Res.Index := MSG_ReadShort;
  Res.DownloadSize := MSG_ReadLong;
  Byte(Res.Flags) := MSG_ReadByte;
  Exclude(Res.Flags, RES_WASMISSING);
  if RES_CUSTOM in Res.Flags then
   MSG_ReadBuffer(SizeOf(Res.MD5Hash), @Res.MD5Hash);

  if MSG_BadRead then
   begin
    DPrint(['SV_ParseResourceList: "', PLChar(@C.NetName), '" sent bad resource data.']);
    SV_DropClient(C, False, 'Invalid resource data.');
    Exit;
   end
  else
   if Res.ResourceType >= RT_WORLD then
    begin
     DPrint(['SV_ParseResourceList: "', PLChar(@C.NetName), '" sent bad resource type.']);
     SV_DropClient(C, False, 'Invalid resource type.');
     Exit;
    end
   else
    if Res.DownloadSize > MaxSize then
     DPrint(['SV_ParseResourceList: "', PLChar(@C.NetName), '" sent an oversized resource, ignoring.'])
    else
     if DecalsOnly and (Res.ResourceType <> RT_DECAL) then
      DPrint(['SV_ParseResourceList: "', PLChar(@C.NetName), '" sent a non-decal resource, ignoring.'])
     else
      if MaxAllowed <= 0 then
       MaxAllowed := -1
      else
       if sv_allowupload.Value <> 0 then
        begin
         Dec(MaxAllowed);
         P := Mem_Alloc(SizeOf(P^));
         Move(Res, P^, SizeOf(P^));
         SV_AddToResourceList(P^, C.UploadList);
         Inc(J);
        end;
 end;

if MaxAllowed = -1 then
 DPrint(['SV_ParseResourceList: "', PLChar(@C.NetName), '" sent too many resources, ignoring ', NumRes - Trunc(sv_uploadmaxnum.Value), ' of ', NumRes, '.']);

if (J > 0) and (sv_allowupload.Value <> 0) then
 begin
  DPrint(['Verifying and uploading resources for "', PLChar(@C.NetName), '".']);

  Size := COM_SizeOfResourceList(C.UploadList, ResInfo);
  if Size = 0 then
   DPrint(['No resources for "', PLChar(@C.NetName), '".'])
  else
   begin
    DPrint('----------------------');
    DPrint(['Custom resources total for "', PLChar(@C.NetName), '": ', RoundTo(Size / 1024, -3), ' KB, including:']);
    if ResInfo.Info[RT_MODEL].Size > 0 then
     DPrint([' -> Models: ', RoundTo(ResInfo.Info[RT_MODEL].Size / 1024, -3), ' KB.']);
    if ResInfo.Info[RT_SOUND].Size > 0 then
     DPrint([' -> Sounds: ', RoundTo(ResInfo.Info[RT_SOUND].Size / 1024, -3), ' KB.']);
    if ResInfo.Info[RT_DECAL].Size > 0 then
     DPrint([' -> Decals: ', RoundTo(ResInfo.Info[RT_DECAL].Size / 1024, -3), ' KB.']);
    if ResInfo.Info[RT_SKIN].Size > 0 then
     DPrint([' -> Skins: ', RoundTo(ResInfo.Info[RT_SKIN].Size / 1024, -3), ' KB.']);
    if ResInfo.Info[RT_GENERIC].Size > 0 then
     DPrint([' -> Generic: ', RoundTo(ResInfo.Info[RT_GENERIC].Size / 1024, -3), ' KB.']);
    if ResInfo.Info[RT_EVENTSCRIPT].Size > 0 then
     DPrint([' -> Events: ', RoundTo(ResInfo.Info[RT_EVENTSCRIPT].Size / 1024, -3), ' KB.']);
    DPrint('----------------------');

    EstSize := SV_EstimateNeededResources;
    if EstSize > sv_uploadmax.Value * 1024 * 1024 then
     begin
      SV_ClearResourceList(C.UploadList);
      SV_ClearResourceList(C.DownloadList);
      Exit;
     end;

    if EstSize > 1024 then
     DPrint(['Resources to request: ', RoundTo(EstSize / 1024, -3), ' KB.'])
    else
     DPrint(['Resources to request: ', EstSize, ' bytes.']);

    C.HasMissingResources := True;
    C.UploadComplete := False;
    SV_BatchUploadRequest(C);
    Exit;
   end;
 end;

C.HasMissingResources := False;
C.UploadComplete := True;
end;

procedure SV_ParseConsistencyResponse(var C: TClient);
var
 Reserved, ReservedNil: array[1..32] of Byte;
 NetAdrBuf: array[1..64] of LChar;
 Buf: array[1..256] of LChar;
 FailedRes: Int;
 I, Size, InResNum, NumConsistency: UInt;
 Res: PResource;
 MinS, MaxS, InMinS, InMaxS: TVec3;
 P: PPackedConsistency;
begin
FailedRes := 0;
NumConsistency := 0;
MemSet(ReservedNil, SizeOf(ReservedNil), 0);

Size := MSG_ReadShort;
if MSG_ReadCount + Size > NETMSG_SIZE then // buffer overrun prevention 
 begin
  SV_DropClient(C, False, 'Bad consistency response.');
  Exit;
 end;

COM_UnMunge(Pointer(UInt(NetMessage.Data) + MSG_ReadCount), Size, SVS.SpawnCount);
MSG_StartBitReading(NetMessage);
while MSG_ReadBits(1) = 1 do
 begin
  InResNum := MSG_ReadBits(12);
  if InResNum >= SV.NumResources then
   begin
    FailedRes := -1;
    Break;
   end;

  Res := @SV.Resources[InResNum];
  if not (RES_CHECKFILE in Res.Flags) then
   begin
    FailedRes := -1;
    Break;
   end;
  
  if CompareMem(@Res.Reserved, @ReservedNil, SizeOf(ReservedNil)) then
   if MSG_ReadBits(32) <> PUInt32(@Res.MD5Hash)^ then
    FailedRes := InResNum + 1
   else
  else
   begin
    MSG_ReadBitData(@MinS, SizeOf(MinS));
    MSG_ReadBitData(@MaxS, SizeOf(MaxS));
    Move(Res.Reserved, Reserved, SizeOf(Reserved));
    COM_UnMunge(@Reserved, SizeOf(Reserved), SVS.SpawnCount);
    P := @Reserved;

    case TForceType(P.ForceType) of
     ftModelSameBounds:
      begin
       InMinS := P.MinS;
       InMaxS := P.MaxS;

       if not VectorCompare(MinS, InMinS) or not VectorCompare(MaxS, InMaxS) then
        FailedRes := InResNum + 1;
      end;

     ftModelSpecifyBounds:
      begin
       InMinS := P.MinS;
       InMaxS := P.MaxS;

       for I := 0 to 2 do
        if (MinS[I] < InMinS[I]) or (MaxS[I] > InMaxS[I]) then
         begin
          FailedRes := InResNum + 1;
          Break;
         end;
      end;

     ftModelSpecifyBoundsIfAvail:
      begin
       InMinS := P.MinS;
       InMaxS := P.MaxS;

       if (MinS[0] <> -1) or (MinS[1] <> -1) or (MinS[2] <> -1) or (MaxS[0] <> -1) or (MaxS[1] <> -1) or (MaxS[2] <> -1) then
        for I := 0 to 2 do
         if (MinS[I] < InMinS[I]) or (MaxS[I] > InMaxS[I]) then
          begin
           FailedRes := InResNum + 1;
           Break;
          end;
      end;

     else
      MSG_BadRead := True;
    end;
   end;

  if MSG_BadRead then
   FailedRes := -1;

  if FailedRes = -1 then
   Break
  else
   Inc(NumConsistency);
 end;

MSG_EndBitReading(NetMessage);
if (FailedRes < 0) or (NumConsistency <> SV.NumConsistency) then
 begin
  MSG_BadRead := True;
  Print(['SV_ParseConsistencyResponse: "', PLChar(@HostClient.NetName), '" (', NET_AdrToString(HostClient.Netchan.Addr, NetAdrBuf, SizeOf(NetAdrBuf)), ') ',
         'sent bad file data.']);
  SV_DropClient(HostClient^, False, 'Bad file data.'); 
 end
else
 if FailedRes = 0 then
  HostClient.SendConsistency := False
 else
  begin
   Buf[1] := #0;
   if (HostClient.Entity <> nil) and (DLLFunctions.InconsistentFile(HostClient.Entity^, @SV.Resources[FailedRes - 1].Name, @Buf) <> 0) then
    if Buf[1] > #0 then
     begin
      SV_ClientPrint(@Buf);
      SV_DropClient(HostClient^, False, ['Bad file "', PLChar(@Buf), '".']); 
     end
    else
     SV_DropClient(HostClient^, False, 'Bad file.');
  end;
end;

function SV_FileInConsistencyList(Name: PLChar; out C: PConsistency): Boolean;
var
 I: Int;
 P: PConsistency;
begin
for I := 0 to MAX_CONSISTENCY - 1 do
 begin
  P := @SV.PrecachedConsistency[I];
  if P.Name = nil then
   Break
  else
   if StrIComp(Name, P.Name) = 0 then
    begin
     C := P;
     Result := True;
     Exit;
    end;
 end;

Result := False;
end;

function SV_TransferConsistencyInfo: UInt;
var
 I: Int;
 Res: PResource;
 C: PConsistency;
 Buf: array[1..MAX_PATH_A] of LChar;
 Hash: TMD5Hash;
 MinS, MaxS: TVec3;
 P: PPackedConsistency;
begin
Result := 0;

for I := 0 to SV.NumResources - 1 do
 begin
  Res := @SV.Resources[I];
  if not (RES_CHECKFILE in Res.Flags) and SV_FileInConsistencyList(@Res.Name, C) then
   begin
    Include(Res.Flags, RES_CHECKFILE);
    if Res.ResourceType = RT_SOUND then
     StrCopy(StrECopy(@Buf, 'sound' + CorrectSlash), @Res.Name)
    else
     StrCopy(@Buf, @Res.Name);

    MD5_Hash_File(Hash, @Buf, False, False, nil);
    Move(Hash, Res.MD5Hash, SizeOf(Res.MD5Hash));
    P := @Res.Reserved;

    if Res.ResourceType = RT_MODEL then
     case C.ForceType of
      ftModelSameBounds:
       begin
        if not R_GetStudioBounds(@Buf, MinS, MaxS) then
         begin
          Host_Error(['SV_TransferConsistencyInfo: Unable to get bounds for "', PLChar(@Buf), '".']);
          Result := 0;
          Exit;
         end;

        P.ForceType := Byte(C.ForceType);
        P.MinS := MinS;
        P.MaxS := MaxS;
        COM_Munge(@Res.Reserved, SizeOf(Res.Reserved), SVS.SpawnCount);
       end;

      ftModelSpecifyBounds, ftModelSpecifyBoundsIfAvail:
       begin
        P.ForceType := Byte(C.ForceType);
        P.MinS := C.MinS;
        P.MaxS := C.MaxS;
        COM_Munge(@Res.Reserved, SizeOf(Res.Reserved), SVS.SpawnCount);
       end;
     end;

    Inc(Result);
   end;
 end;
end;

procedure SV_Send_FileTxferFailed(S: PLChar);
begin
if (S <> nil) and (S^ > #0) then
 begin
  MSG_WriteByte(HostClient.Netchan.NetMessage, SVC_FILETXFERFAILED);
  MSG_WriteString(HostClient.Netchan.NetMessage, S);
 end;
end;

function IsSafeFile(S: PLChar): Boolean;
var
 S2: PLChar;
 I: UInt;
begin
if S = nil then
 Result := False
else
 if StrLComp(S, '!MD5', 4) = 0 then
  Result := MD5_IsValid(PLChar(UInt(S) + 4))
 else
  if (S^ in ['\', '/', '.']) or (StrScan(S, ':') <> nil) or (StrPos(S, '..') <> nil) or
     (StrPos(S, '//') <> nil) or (StrPos(S, '\\') <> nil) or (StrPos(S, '~/') <> nil) or
     (StrPos(S, '~\') <> nil) then
   Result := False
  else
   begin
    S2 := StrScan(S, '.');
    if (StrLen(S) < 3) or (S2 = nil) or (StrRScan(S, '.') <> S2) or (StrLen(S2) <= 1) then
     Result := False
    else
     begin
      Inc(UInt(S2));
      for I := Low(ValidFileExt) to High(ValidFileExt) do
       if StrIComp(S2, ValidFileExt[I]) = 0 then
        begin
         Result := True;
         Exit;
        end;

      Result := False;
     end;
   end;
end;

procedure SV_BeginFileDownload_F; cdecl;
var
 S: PLChar;
 Res: TResource;
 Hash: TMD5Hash;
 Buffer: Pointer;
 Size: UInt32;
begin
if (Cmd_Argc <> 2) or (CmdSource = csServer) then
 Exit;

S := Cmd_Argv(1);
if (S = nil) or (S^ = #0) then
 Exit;

if (sv_allowdownload.Value = 0) or not IsSafeFile(S) then
 SV_Send_FileTxferFailed(S)
else
 if StrLComp(S, '!MD5', 4) <> 0 then
  if (sv_send_resources.Value <> 0) and Netchan_CreateFileFragments(True, @HostClient.Netchan, S) then
   Netchan_FragSend(HostClient.Netchan)
  else
   SV_Send_FileTxferFailed(S)
 else
  if (sv_send_logos.Value = 0) or not MD5_IsValid(PLChar(UInt(S) + 4)) then
   SV_Send_FileTxferFailed(S)
  else
   begin
    MemSet(Res, SizeOf(Res), 0);
    Buffer := nil;
    Size := 0;
    COM_HexConvert(PLChar(UInt(S) + 4), 32, @Hash);
    if HPAK_ResourceForHash('custom.hpk', @Hash, @Res) and
       HPAK_GetDataPointer('custom.hpk', Res, @Buffer, @Size) and (Buffer <> nil) and (Size > 0) then
     begin
      Netchan_CreateFileFragmentsFromBuffer(HostClient.Netchan, S, Buffer, Size);
      Netchan_FragSend(HostClient.Netchan);
      Mem_Free(Buffer);
     end;
   end;
end;

procedure SV_AddResource(ResType: UInt; FileName: PLChar; DownloadSize: UInt; Flags: TResourceFlags; Index: UInt);
var
 P: PResource;
begin
if SV.NumResources >= MAX_RESOURCES then
 Sys_Error('SV_AddResource: Too many resources on server.');

P := @SV.Resources[SV.NumResources];
Inc(SV.NumResources);

P.ResourceType := ResType;
StrLCopy(@P.Name, FileName, SizeOf(P.Name) - 1);
P.DownloadSize := DownloadSize;
P.Flags := Flags;
P.Index := Index;
end;

procedure SV_CreateResourceList;
var
 I: Int;
 S: PLChar;
 Buf: array[1..MAX_PATH_A * 2] of LChar;
 B: Boolean;
 P: PPrecachedEvent;
begin
SV.NumResources := 0;
for I := 1 to MAX_GENERIC_ITEMS - 1 do
 begin
  S := SV.PrecachedGeneric[I];
  if S = nil then
   Break;

  if SVS.MaxClients > 1 then
   SV_AddResource(RT_GENERIC, S, FS_SizeByName(S), [], I)
  else
   SV_AddResource(RT_GENERIC, S, 0, [], I);
 end;

B := False;
for I := 1 to MAX_SOUNDS - 1 do
 begin
  S := SV.PrecachedSoundNames[I];
  if S = nil then
   Break;

  if S^ <> '!' then
   if SVS.MaxClients > 1 then
    begin
     StrCopy(StrECopy(@Buf, 'sound' + CorrectSlash), S);
     SV_AddResource(RT_SOUND, S, FS_SizeByName(@Buf), [], I)
    end
   else
    SV_AddResource(RT_SOUND, S, 0, [], I)
  else
   if not B then
    begin
     B := True;
     SV_AddResource(RT_SOUND, '!', 0, [RES_FATALIFMISSING], I);
    end;
 end;

for I := 1 to MAX_MODELS - 1 do
 begin
  S := SV.PrecachedModelNames[I];
  if S = nil then
   Break;

  if SVS.MaxClients > 1 then
   if S^ = '*' then
    SV_AddResource(RT_MODEL, S, 0, SV.PrecachedModelFlags[I], I)
   else
    SV_AddResource(RT_MODEL, S, FS_SizeByName(S), SV.PrecachedModelFlags[I], I)
  else
   SV_AddResource(RT_MODEL, S, 0, SV.PrecachedModelFlags[I], I);
 end;

for I := 0 to SVDecalNameCount - 1 do
 SV_AddResource(RT_DECAL, @SVDecalNames[I], Draw_DecalSize(I), [], I);

for I := 1 to MAX_EVENTS - 1 do
 begin
  P := @SV.PrecachedEvents[I];
  if P.Data = nil then
   Break;
  
  SV_AddResource(RT_EVENTSCRIPT, P.Name, P.Size, [RES_FATALIFMISSING], I);
 end;
end;

procedure SV_CreateGenericResources;
var
 Buf: array[1..MAX_MAP_NAME] of LChar;
 P, P2: Pointer;
 S: PLChar;
begin
COM_StripExtension(@SV.MapFileName, @Buf);
COM_DefaultExtension(@Buf, '.res');
COM_FixSlashes(@Buf);

P := COM_LoadFile(@Buf, FILE_ALLOC_MEMORY, nil);
if P <> nil then
 begin
  P2 := P;

  DPrint(['Precaching from "', PLChar(@Buf), '".' + LineBreak +
          '----------------------------------']);
  SV.NumResGeneric := 0;
  
  while True do
   begin
    P := COM_Parse(P);
    if COM_Token[Low(COM_Token)] = #0 then
     Break
    else
     if not IsSafeFile(@COM_Token) then
      Print(['Resource "', PLChar(@COM_Token), '" from "', PLChar(@Buf), '" cannot be precached.'])
     else
      begin
       S := @SV.PrecachedResGeneric[SV.NumResGeneric];
       StrLCopy(S, @COM_Token, SizeOf(SV.PrecachedResGeneric[0]) - 1);
       PF_PrecacheGeneric(S);
       DPrint(['  ', S]);
       Inc(SV.NumResGeneric);
      end;      
   end;

  DPrint('----------------------------------');
  COM_FreeFile(P2);
 end;
end;

procedure SV_ProcessFile(var C: TClient; Name: PLChar);
var
 MD5Hash: TMD5Hash;
 P, P2: PResource;
 P3: PCustomization;
begin
if Name = nil then
 Print('SV_ProcessFile: Bad name pointer.')
else
 if Name^ <> '!' then
  Print(['SV_ProcessFile: Non-customization file upload of "', Name, '".'])
 else
  if (StrLComp(Name, '!MD5', 4) <> 0) or not MD5_IsValid(PLChar(UInt(Name) + 4)) then
   Print('SV_ProcessFile: Bad customization hash.')
  else
   begin
    COM_HexConvert(PLChar(UInt(Name) + 4), 32, @MD5Hash);
    P := C.UploadList.Next;
    while P <> @C.UploadList do
     begin
      P2 := P.Next;
      if CompareMem(@P.MD5Hash, @MD5Hash, SizeOf(P.MD5Hash)) then
       begin
        if P.DownloadSize <> C.Netchan.TempBufferSize then
         Print(['SV_ProcessFile: Downloaded ', C.Netchan.TempBufferSize, ' bytes for ', P.DownloadSize, ' byte file (size mismatch) on "', PLChar(@C.NetName), '".'])
        else
         begin
          HPAK_AddLump(True, 'custom.hpk', P, C.Netchan.TempBuffer, nil);
          Exclude(P.Flags, RES_WASMISSING);
          SV_MoveToOnHandList(P^);

          P3 := C.Customization.Next;
          while P3 <> nil do
           if CompareMem(@P.MD5Hash, @P3.Resource.MD5Hash, SizeOf(P.MD5Hash)) then
            begin
             DPrint('Duplicate resource received and ignored.');
             Exit;
            end
           else
            P3 := P3.Next;

          if not COM_CreateCustomization(C.Customization, P^, -1, [RES_FATALIFMISSING, RES_WASMISSING, RES_CUSTOM], PCustomization(nil^), PUInt32(nil)^) then
           Print(['Error parsing custom decal from "', PLChar(@C.NetName), '".']);
         end;

        Exit;
       end;

      P := P2;
     end;
    
    Print('SV_ProcessFile: Unrequested decal.')
   end;
end;

end.
