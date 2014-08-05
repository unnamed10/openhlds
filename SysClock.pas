unit SysClock;

{$I HLDS.inc}

interface

uses SysUtils, {$IFDEF MSWINDOWS} Windows, SysMain, {$ELSE} Libc, {$ENDIF} Default;

procedure Sys_InitClock;
procedure Sys_ShutdownClock;

procedure Sys_SetStartTime;

function Sys_FloatTime: Double;

implementation

uses SysArgs;

{$IFDEF MSWINDOWS}
var
 Init: Boolean = False;

 CriticalSection: TCriticalSection;

 TimeSampleShift: Int32;
 ClockFrequency: Double;

 FirstCall: Boolean = True;
 PreviousTime: UInt32;
 CurrentTime, LastCurrentTime: Double;
 SameTimeCount: UInt32;

procedure Sys_InitClock;
var
 PerformanceFreq: TUInt64Rec;
 LowPart, HighPart: UInt32;
begin
if not Init then
 begin
  Sys_InitCS(CriticalSection);
  Init := True;
 end;

if not QueryPerformanceFrequency(Int64(PerformanceFreq)) or
   (Int64(PerformanceFreq) = 0) then
 Sys_Error('Sys_InitClock: No hardware timer available.');

HighPart := PerformanceFreq.High;
LowPart := PerformanceFreq.Low;
TimeSampleShift := 0;

while (HighPart > 0) or (LowPart > 2000000) do
 begin
  Inc(TimeSampleShift);
  LowPart := (HighPart shl 31) or (LowPart shr 1);
  HighPart := HighPart shr 1;
 end;

if LowPart > 0 then
 ClockFrequency := 1 / LowPart
else
 ClockFrequency := 0;

PreviousTime := 0;
SameTimeCount := 0;
end;

procedure Sys_SetStartTime;
var
 Index: UInt;
begin
Sys_FloatTime;

Index := COM_CheckParm('-starttime');
if Index > 0 then
 CurrentTime := StrToFloatDef(COM_ParmValueByIndex(Index), 0)
else
 CurrentTime := 0;

LastCurrentTime := CurrentTime;
end;

function Sys_FloatTime: Double;
var
 PerformanceCount: TUInt64Rec;
 T1, OldTime: UInt32;
begin
if not Init then
 begin
  Result := 1;
  Exit;
 end;

Sys_EnterCS(CriticalSection);

QueryPerformanceCounter(Int64(PerformanceCount));
if TimeSampleShift >= 1 then
 T1 := (PerformanceCount.Low shr TimeSampleShift) or
       (PerformanceCount.High shl (32 - TimeSampleShift))
else
 T1 := PerformanceCount.Low;

OldTime := PreviousTime;
PreviousTime := T1;

if FirstCall then
 FirstCall := False
else
 if (T1 > OldTime) or ((OldTime - T1) >= $10000000) then
  begin
   CurrentTime := CurrentTime + (T1 - OldTime) * ClockFrequency;

   if CurrentTime = LastCurrentTime then
    begin
     Inc(SameTimeCount);
     if SameTimeCount > 100000 then
      begin
       CurrentTime := CurrentTime + 1;
       SameTimeCount := 0;
      end;
    end
   else
    SameTimeCount := 0;

   LastCurrentTime := CurrentTime;
  end;

Sys_LeaveCS(CriticalSection);
Result := CurrentTime;
end;

procedure Sys_ShutdownClock;
begin
LastCurrentTime := 0;
CurrentTime := 0;

if Init then
 begin
  Sys_DeleteCS(CriticalSection);
  Init := False;
 end;
end;

{$ELSE}

var
 SecBase: UInt32 = 0;

function Sys_FloatTime: Double;
var
 TV: TTimeVal;
begin
gettimeofday(TV, nil);
if SecBase > 0 then
 Result := (TV.tv_sec - SecBase) + TV.tv_usec / 1000000
else
 begin
  SecBase := TV.tv_sec;
  Result := TV.tv_usec / 1000000;
 end;
end;

procedure Sys_InitClock;
begin

end;

procedure Sys_ShutdownClock;
begin

end;

procedure Sys_SetStartTime;
var
 Index: UInt;
begin
Sys_FloatTime;

Index := COM_CheckParm('-starttime');
if Index > 0 then
 Inc(SecBase, Trunc(StrToFloatDef(COM_ParmValueByIndex(Index), 0) / 1000));
end;

{$ENDIF}

end.
