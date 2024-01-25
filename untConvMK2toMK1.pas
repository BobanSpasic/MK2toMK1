{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Conversion from DX7II to DX7 format
}
unit untConvMK2toMK1;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untDX7Bank, untDX7Voice, untDX7IISupplBank,
  untDX7IISupplement, untDX7IIPerformance, untDX7IIPerformanceBank,
  untDXUtils, untParConst, untUtils, IniFiles;

procedure ConvertBigDX7IItoMDX(var ms: TMemoryStream; APath: string; AName: string; AVerbose: boolean; ASettings: string);        // 2xVMEM, 2xAMEM, 1xPMEM
function GetSettingsFromFile(ASettings: string; var aAMS_table: TAMS; var aPEGR_table: TPEGR): boolean;

implementation

procedure ConvertBigDX7IItoMDX(var ms: TMemoryStream; APath: string; AName: string; AVerbose: boolean; ASettings: string);
var
  msA: TMemoryStream;
  msB: TMemoryStream;
  msP: TMemoryStream;
  DXA: TDX7BankContainer;
  DXB: TDX7BankContainer;
  DXAs: TDX7IISupplBankContainer;
  DXBs: TDX7IISupplBankContainer;
  DX7II: TDX7IIPerfBankContainer;

  DX7_VCED_A: TDX7VoiceContainer;
  DX7_VCED_B: TDX7VoiceContainer;
  DX7II_ACED_A: TDX7IISupplementContainer;
  DX7II_ACED_B: TDX7IISupplementContainer;
  DX7II_PCED: TDX7IIPerformanceContainer;

  DX7outA: TDX7BankContainer;
  DX7outB: TDX7BankContainer;
  Report: TStringList;
  ConversionLog: TStringList;

  Params: TDX7II_PCED_Params;
  iVoiceA: integer;
  iVoiceB: integer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i, j: integer;
  sName: string;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;
  AMS_table: TAMS;
  PEGR_table: TPEGR;
begin
  msFoundPosition := 0;

  msA := TMemoryStream.Create;
  msA.LoadFromStream(ms);
  msB := TMemoryStream.Create;
  msB.LoadFromStream(ms);
  msP := TMemoryStream.Create;
  msP.LoadFromStream(ms);

  DXA := TDX7BankContainer.Create;
  DXB := TDX7BankContainer.Create;
  DXAs := TDX7IISupplBankContainer.Create;
  DXBs := TDX7IISupplBankContainer.Create;
  DX7II := TDX7IIPerfBankContainer.Create;

  DX7outA := TDX7BankContainer.Create;
  DX7outB := TDX7BankContainer.Create;
  Report := TStringList.Create;
  ConversionLog := TStringList.Create;
  ConversionLog.Add('Yamaha DX7II to DX7 Converter 1.0');
  ConversionLog.Add('Author: Boban Spasic');
  ConversionLog.Add('https://github.com/BobanSpasic/MK2toMK1');
  ConversionLog.Add('');
  ConversionLog.Add('Converting ' + AName + ' from DX7II VMEM+AMEM to DX7 VMEM format');
  ConversionLog.Add('=================================');

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXA.LoadBankFromStream(msA, msFoundPosition);
    ConversionLog.Add('VMEM A loaded from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      ConversionLog.Add(Format('%.2d', [i]) + ': ' + DXA.GetVoiceName(i));
    ConversionLog.Add('=================================');
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB.LoadBankFromStream(msB, msFoundPosition);
    ConversionLog.Add('VMEM B loaded from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      ConversionLog.Add(Format('%.2d', [i]) + ': ' + DXB.GetVoiceName(i));
    ConversionLog.Add('=================================');
  end
  else
  begin
    ConversionLog.Add('VMEM B not found, using INIT parameters');
    ConversionLog.Add('=================================');
    DXB.InitBank;
    msFoundPosition := 0;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXAs.LoadSupplBankFromStream(msA, msFoundPosition);
    ConversionLog.Add('AMEM A loaded from position ' +
      IntToStr(msFoundPosition));
    ConversionLog.Add('=================================');
  end
  else
  begin
    ConversionLog.Add('AMEM A not found, using INIT parameters');
    ConversionLog.Add('=================================');
    DXAs.InitSupplBank;
    msFoundPosition := 0;
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(AMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXBs.LoadSupplBankFromStream(msB, msFoundPosition);
    ConversionLog.Add('AMEM B loaded from position ' +
      IntToStr(msFoundPosition));
    ConversionLog.Add('=================================');
  end
  else
  begin
    ConversionLog.Add('AMEM B not found, using INIT parameters');
    ConversionLog.Add('=================================');
    DXBs.InitSupplBank;
    msFoundPosition := 0;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(LMPMEM, msP, msSearchPosition, msFoundPosition) then
  begin
    DX7II.LoadPerfBankFromStream(msP, msFoundPosition);
    ConversionLog.Add('LM_PMEM loaded from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      ConversionLog.Add(Format('%.2d', [i]) + ': ' + DX7II.GetPerformanceName(i));
    ConversionLog.Add('=================================');
  end;

  ConversionLog.Add('Used conversion parameters:');
  if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
  begin
    ConversionLog.Add(#9 + 'AMS0 = ' + FloatToStr(AMS_table[0]));
    ConversionLog.Add(#9 + 'AMS1 = ' + FloatToStr(AMS_table[1]));
    ConversionLog.Add(#9 + 'AMS2 = ' + FloatToStr(AMS_table[2]));
    ConversionLog.Add(#9 + 'AMS3 = ' + FloatToStr(AMS_table[3]));
    ConversionLog.Add(#9 + 'AMS4 = ' + FloatToStr(AMS_table[4]));
    ConversionLog.Add(#9 + 'AMS5 = ' + FloatToStr(AMS_table[5]));
    ConversionLog.Add(#9 + 'AMS6 = ' + FloatToStr(AMS_table[6]));
    ConversionLog.Add(#9 + 'AMS7 = ' + FloatToStr(AMS_table[7]));
    ConversionLog.Add(#9 + 'PEGR0 = ' + FloatToStr(PEGR_table[0]));
    ConversionLog.Add(#9 + 'PEGR1 = ' + FloatToStr(PEGR_table[1]));
    ConversionLog.Add(#9 + 'PEGR2 = ' + FloatToStr(PEGR_table[2]));
    ConversionLog.Add(#9 + 'PEGR3 = ' + FloatToStr(PEGR_table[3]));
  end
  else
  begin
    ConversionLog.Add(#9 + 'AMS0 = 0');
    ConversionLog.Add(#9 + 'AMS1 = 1');
    ConversionLog.Add(#9 + 'AMS2 = 2');
    ConversionLog.Add(#9 + 'AMS3 = 3');
    ConversionLog.Add(#9 + 'AMS4 = 3');
    ConversionLog.Add(#9 + 'AMS5 = 3');
    ConversionLog.Add(#9 + 'AMS6 = 3');
    ConversionLog.Add(#9 + 'AMS7 = 3');
    ConversionLog.Add(#9 + 'PEGR0 = 50');
    ConversionLog.Add(#9 + 'PEGR1 = 25');
    ConversionLog.Add(#9 + 'PEGR2 = 6.25');
    ConversionLog.Add(#9 + 'PEGR3 = 3.125');
  end;
  for i := 0 to ConversionLog.Count - 1 do
    WriteLn(ConversionLog[i]);
  WriteLn('=================================');

  //here goes the bank conversion
  for i := 1 to 32 do
  begin
    DX7_VCED_A := TDX7VoiceContainer.Create;
    DX7_VCED_B := TDX7VoiceContainer.Create;
    DX7II_ACED_A := TDX7IISupplementContainer.Create;
    DX7II_ACED_B := TDX7IISupplementContainer.Create;

    DXA.GetVoice(i, DX7_VCED_A);
    DXAs.GetSupplement(i, DX7II_ACED_A);
    perg := DX7II_ACED_A.Get_ACED_Params.Pitch_EG_Range;
    ams1 := DX7II_ACED_A.Get_ACED_Params.OP1_AM_Sensitivity;
    ams2 := DX7II_ACED_A.Get_ACED_Params.OP2_AM_Sensitivity;
    ams3 := DX7II_ACED_A.Get_ACED_Params.OP3_AM_Sensitivity;
    ams4 := DX7II_ACED_A.Get_ACED_Params.OP4_AM_Sensitivity;
    ams5 := DX7II_ACED_A.Get_ACED_Params.OP5_AM_Sensitivity;
    ams6 := DX7II_ACED_A.Get_ACED_Params.OP6_AM_Sensitivity;
    if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
      DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
    else
      DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    DX7outA.SetVoice(i, DX7_VCED_A);

    DXB.GetVoice(i, DX7_VCED_B);
    DXBs.GetSupplement(i, DX7II_ACED_B);
    perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
    ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
    ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
    ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
    ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
    ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
    ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
    if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
      DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
    else
      DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    DX7outB.SetVoice(i, DX7_VCED_B);

    DX7_VCED_A.Free;
    DX7_VCED_B.Free;
    DX7II_ACED_A.Free;
    DX7II_ACED_B.Free;
  end;
  DX7outA.SaveBankToSysExFile(IncludeTrailingPathDelimiter(APath) + AName + '_A.syx');
  DX7outB.SaveBankToSysExFile(IncludeTrailingPathDelimiter(APath) + AName + '_B.syx');

  for i := 1 to 32 do
  begin
    Report.Clear;
    DX7_VCED_A := TDX7VoiceContainer.Create;
    DX7_VCED_B := TDX7VoiceContainer.Create;
    DX7II_ACED_A := TDX7IISupplementContainer.Create;
    DX7II_ACED_B := TDX7IISupplementContainer.Create;
    DX7II_PCED := TDX7IIPerformanceContainer.Create;

    DX7II.GetPerformance(i, DX7II_PCED);
    sName := Format('%.2d', [i]) + '_' + Trim(GetValidFileName(DX7II.GetPerformanceName(i)));

    Report.Add('Performance name: ' + DX7II.GetPerformanceName(i));

    Params := DX7II_PCED.Get_PCED_Params;

    iVoiceA := Params.VoiceANumber;
    iVoiceB := Params.VoiceBNumber;

    // 0 - 63 - Internal
    // 64-127 - Cartridge
    //WriteLn('Debug: VoiceA ' + IntToStr(iVoiceA) + ' ; ' + 'VoiceB ' + IntToStr(iVoiceB));
    if iVoiceA < 64 then iVoiceA := iVoiceA + 1
    else
    if iVoiceA > 63 then iVoiceA := iVoiceA - 63;
    if iVoiceB < 64 then iVoiceB := iVoiceB + 1
    else
    if iVoiceB > 63 then iVoiceB := iVoiceB - 63;

    if iVoiceA < 33 then
      Report.Add('VoiceA: Bank ' + AName + '_A Voice ' + IntToStr(iVoiceA) + ' - ' + DXA.GetVoiceName(iVoiceA))
    else
      Report.Add('VoiceA: Bank ' + AName + '_B, Voice ' + IntToStr(iVoiceA - 32) + ' - ' + DXB.GetVoiceName(iVoiceA - 32));

    if Params.PerformanceLayerMode <> 0 then
    begin
      if iVoiceB < 33 then
        Report.Add('VoiceB: Bank ' + AName + '_A, Voice ' + IntToStr(iVoiceB) + ' - ' + DXA.GetVoiceName(iVoiceB))
      else
        Report.Add('VoiceB: Bank ' + AName + '_B, Voice ' + IntToStr(iVoiceB - 32) + ' - ' + DXB.GetVoiceName(iVoiceB - 32));
    end;

    case Params.PerformanceLayerMode of
      0: Report.Add('Performance is using single voice');
      1: Report.Add('Performance is using dual layered mode');
      2: begin
        Report.Add('Performance is using split layered mode');
        Report.Add('Split point is at ' + Nr2Note(Params.SplitPoint));
      end;
    end;
    Report.Add('Note shift VoiceA: ' + IntToStr(Params.NoteShiftRangeA - 24));
    if Params.PerformanceLayerMode <> 0 then
    begin
      Report.Add('Note shift VoiceB: ' + IntToStr(Params.NoteShiftRangeB - 24));
      Report.Add('Dual detune: ' + IntToStr(Params.DualDetune));
    end;
    for j := 0 to Report.Count - 1 do
      WriteLn(Report[j]);

    //WriteLn('Writting ' + sName + '.txt');
    Report.SaveToFile(IncludeTrailingPathDelimiter(APath) + sName + '.txt');
    ConversionLog.SaveToFile(IncludeTrailingPathDelimiter(APath) + AName + '.log');
    WriteLn('=================================');
    DX7_VCED_A.Free;
    DX7_VCED_B.Free;
    DX7II_ACED_A.Free;
    DX7II_ACED_B.Free;
    DX7II_PCED.Free;
  end;

  msA.Free;
  msB.Free;
  msP.Free;
  DXA.Free;
  DXB.Free;
  DXAs.Free;
  DXBs.Free;
  DX7II.Free;
  DX7outA.Free;
  DX7outB.Free;
  Report.Free;
  ConversionLog.Free;
end;

function GetSettingsFromFile(ASettings: string; var aAMS_table: TAMS; var aPEGR_table: TPEGR): boolean;
var
  ini: TIniFile;
begin
  if FileExists(ASettings) then
  begin
    try
      try
        ini := TIniFile.Create(ASettings);
        aAMS_Table[0] := byte(ini.ReadInteger('AMS', 'AMS0', 0));
        aAMS_Table[1] := byte(ini.ReadInteger('AMS', 'AMS1', 1));
        aAMS_Table[2] := byte(ini.ReadInteger('AMS', 'AMS2', 2));
        aAMS_Table[3] := byte(ini.ReadInteger('AMS', 'AMS3', 3));
        aAMS_Table[4] := byte(ini.ReadInteger('AMS', 'AMS4', 3));
        aAMS_Table[5] := byte(ini.ReadInteger('AMS', 'AMS5', 3));
        aAMS_Table[6] := byte(ini.ReadInteger('AMS', 'AMS6', 3));
        aAMS_Table[7] := byte(ini.ReadInteger('AMS', 'AMS7', 3));
        aPEGR_table[0] := single(ini.ReadFloat('PEGR', 'PEGR0', 50));
        aPEGR_table[1] := single(ini.ReadFloat('PEGR', 'PEGR1', 25));
        aPEGR_table[2] := single(ini.ReadFloat('PEGR', 'PEGR2', 6.25));
        aPEGR_table[3] := single(ini.ReadFloat('PEGR', 'PEGR3', 3.125));
      finally
        ini.Free;
        Result := True;
      end;
    except
      on e: Exception do Result := False;
    end;
  end
  else
    Result := False;
end;

end.
