{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Decide the conversion to be done depending on the input files
}

unit untDispatcher;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, untDXUtils, untUtils, untConvMK2toMK1;

procedure DispatchCheck(ABank: string; AName: string; AVerbose: boolean; AOutput, ASettings: string);  //TX7 and DX7II
procedure DispatchCheck(ABankA, ABankB: string; AName: string; AVerbose: boolean; AOutput, ASettings: string); overload; //DX7II big dump
procedure DispatchCheck(ABankA, ABankB, APerf: string; AName: string; AVerbose: boolean; AOutput, ASettings: string); overload; //DX7II with Performance

implementation

procedure DispatchCheck(ABank: string; AName: string; AVerbose: boolean; AOutput, ASettings: string);
var
  msBank: TMemoryStream;
  ms: MemSet;
  sName: string;
begin
  msBank := TMemoryStream.Create;
  msBank.LoadFromFile(ABank);
  ms := ContainsDX_SixOP_MemSet(msBank);
  sName := ExtractFileNameWithoutExt(ExtractFileName(ABank));

  if (VMEM in ms) and (LMPMEM in ms) and (AMEM in ms) then
  begin
    if msBank.Size >= 12114 then
    begin
      WriteLn('It is a DX7II All dump');
      if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
      ConvertBigDX7IItoMDX(msBank, AOutput, sName, AVerbose, ASettings);
    end;
  end;
  if (VMEM in ms) and (LMPMEM in ms) and not (AMEM in ms) then
  begin
    if (msBank.Size >= 9858) and (msBank.Size <= 18108) then
    begin
      WriteLn('It is a INCOMPLETE DX7II All dump');
      WriteLn('Do not expect wonders from this conversion');
      if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
      ConvertBigDX7IItoMDX(msBank, AOutput, sName, AVerbose, ASettings);
    end;
  end;
  msBank.Free;
end;

procedure DispatchCheck(ABankA, ABankB: string; AName: string; AVerbose: boolean; AOutput, ASettings: string); overload;
var
  msBankA: TMemoryStream;
  msBankB: TMemoryStream;
  msAll: TMemoryStream;
  msA: MemSet;
  msB: MemSet;
begin
  msBankA := TMemoryStream.Create;
  msBankA.LoadFromFile(ABankA);
  msBankB := TMemoryStream.Create;
  msBankB.LoadFromFile(ABankB);
  msAll := TMemoryStream.Create;
  msAll.CopyFrom(msBankA, msBankA.Size);
  msAll.CopyFrom(msBankB, msBankB.Size);

  msA := ContainsDX_SixOP_MemSet(msBankA);
  msB := ContainsDX_SixOP_MemSet(msBankB);

  if (VMEM in msA) and (AMEM in msA) and (LMPMEM in msB) and not ((VMEM in msB) or (AMEM in msB) or (LMPMEM in msA)) then
  begin
    //VMEM+AMEM in one file, PMEM in other file
    WriteLn('It is a DX7II set');
    if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
    ConvertBigDX7IItoMDX(msAll, AOutput, AName, AVerbose, ASettings);
  end;

  msBankA.Free;
  msBankB.Free;
  msAll.Free;
end;

procedure DispatchCheck(ABankA, ABankB, APerf: string; AName: string; AVerbose: boolean; AOutput, ASettings: string);
var
  msBankA: TMemoryStream;
  msBankB: TMemoryStream;
  msPerf: TMemoryStream;
  msAll: TMemoryStream;
  msA: MemSet;
  msB: MemSet;
  msP: MemSet;
begin
  msBankA := TMemoryStream.Create;
  msBankA.LoadFromFile(ABankA);
  msBankB := TMemoryStream.Create;
  msBankB.LoadFromFile(ABankB);
  msPerf := TMemoryStream.Create;
  msPerf.LoadFromFile(APerf);
  msAll := TMemoryStream.Create;
  msAll.CopyFrom(msBankA, msBankA.Size);
  msAll.CopyFrom(msBankB, msBankB.Size);
  msAll.CopyFrom(msPerf, msPerf.Size);

  msA := ContainsDX_SixOP_MemSet(msBankA);
  msB := ContainsDX_SixOP_MemSet(msBankB);
  msP := ContainsDX_SixOP_MemSet(msPerf);

  if (VMEM in msA) and (VMEM in msB) and (AMEM in msA) and (AMEM in msB) and
    (LMPMEM in msP) then
  begin
    WriteLn('It is a DX7II performance set');
    if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
    ConvertBigDX7IItoMDX(msAll, AOutput, AName, AVerbose, ASettings);
  end;

  if (VMEM in msA) and (VMEM in msB) and (LMPMEM in msP) and not ((AMEM in msA) or (AMEM in msB)) then
  begin
    WriteLn('It is a INCOMPLETE DX7II performance set without AMEM data');
    WriteLn('Do not expect wonders from this conversion');
    if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
    ConvertBigDX7IItoMDX(msAll, AOutput, AName, AVerbose, ASettings);
  end;

  msBankA.Free;
  msBankB.Free;
  msPerf.Free;
  msAll.Free;
end;

end.
