unit FilterIP;

{$I HLDS.inc}

interface

uses Default, SDK;

const
 MAX_SEQUENCE = 4;

type
 PIPFilterRec = ^TIPFilterRec;
 TIPFilterRec = record
  IP: UInt32;
  Samples: UInt;  
  Time: Double;
  AvgDiff: Double;
 end;

 PIPFilterSeq = ^TIPFilterSeq;
 TIPFilterSeq = array[1..MAX_SEQUENCE] of TIPFilterRec;

 PIPFilter = ^TIPFilter;
 TIPFilter = record
  Seq: array[Byte] of TIPFilterSeq;
 end;

procedure FlushIPFilter(var F: TIPFilter);
function FindInIPFilter(var F: TIPFilter; IP: UInt32; Timeout: Double): PIPFilterRec;

implementation

uses Host;

procedure FlushIPFilter(var F: TIPFilter);
begin
MemSet(F, SizeOf(F), 0);
end;

function FindInIPFilter(var F: TIPFilter; IP: UInt32; Timeout: Double): PIPFilterRec;
var
 Seq: PIPFilterSeq;
 R, TR: PIPFilterRec;
 MinTime, Diff: Double;
 I: UInt;
begin
MinTime := RealTime;
Seq := @F.Seq[IP and $FF];
TR := @Seq[1];
for I := 1 to MAX_SEQUENCE do
 begin
  R := @Seq[I];
  if R.IP = IP then
   begin
    Diff := RealTime - R.Time;
    if Diff > Timeout then
     begin
      TR := R;
      Break;
     end;

    Inc(R.Samples);
    if R.Samples = 0 then
     begin
      R.Samples := 1;
      R.AvgDiff := 0;
     end
    else
     R.AvgDiff := R.AvgDiff * (7/8) + Diff * (1/8);

    R.Time := RealTime;
    Result := R;
    Exit;
   end
  else
   if R.Time < MinTime then
    begin
     MinTime := R.Time;
     TR := R;
    end;
 end;   

TR.IP := IP;
TR.Time := RealTime;
TR.Samples := 0;
TR.AvgDiff := 0;
Result := nil;
end;

end.
