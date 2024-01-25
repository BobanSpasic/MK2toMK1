{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Program description:
 Convert DX7II files (banks and performances) to DX7 banks
}

program MK2toMK1;

{$mode objfpc}{$H+}

uses
 {$DEFINE CMDLINE}
 {$IFDEF UNIX}
  cthreads,
 {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  untDispatcher,
  untDXUtils;

type

  { TMK2toMK1 }

  TMK2toMK1 = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

  { TMK2toMK1 }

  procedure TMK2toMK1.DoRun;
  var
    ErrorMsg: string;
    fVoice: string;
    fOutput: string;
    fSettings: string;
    slReport: TStringList;
    msInputFile: TMemoryStream;
    i: integer;
    iStartPos: integer;
    bVerbose: boolean;
  begin
    fVoice := '';
    bVerbose := False;

    // quick check parameters
    CaseSensitiveOptions := True;
    ErrorMsg := CheckOptions('hi:c:vo:s:',
      'help info: convert: verbose output: settings:');

    if ErrorMsg <> '' then
    begin
      WriteHelp;
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
    end;

    if (ParamCount = 0) or HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;

    if HasOption('v', 'verbose') then bVerbose := True;

    if HasOption('o', 'output') then
    begin
      fOutput := GetOptionValue('o', 'output');
      fOutput := IncludeTrailingPathDelimiter(fOutput);
      fOutput := ExpandFileName(fOutput);
      if bVerbose then WriteLn('Output directory: ' + fOutput);
      if not DirectoryExists(fOutput) then CreateDir(fOutput);
    end
    else
    begin
      fOutput := GetOptionValue('c', 'convert');
      fOutput := ExpandFileName(fOutput);
      if bVerbose then WriteLn('Output directory: ' + fOutput);
      fOutput := IncludeTrailingPathDelimiter(ExtractFileDir(fOutput));
    end;

    if HasOption('s', 'settings') then
    begin
      fSettings := GetOptionValue('s', 'settings');
      fSettings := ExpandFileName(fSettings);
    end;

    if HasOption('i', 'info') then
    begin
      fVoice := GetOptionValue('i', 'info');
      fVoice := ExpandFileName(fVoice);
      if not FileExists(fVoice) then
      begin
        WriteLn('Please specify the target file');
        Terminate;
        Exit;
      end
      else
      begin
        if FileExists(fVoice) then
        begin
          slReport := TStringList.Create;
          msInputFile := TMemoryStream.Create;
          msInputFile.LoadFromFile(fVoice);
          iStartPos := 0;

          if ContainsDX_SixOP_Data(msInputFile, iStartPos, slReport) then
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end
          else
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end;

          msInputFile.Free;
          slReport.Free;
        end;
      end;
    end;

    if HasOption('c', 'convert') then
    begin
      fVoice := GetOptionValue('c', 'convert');
      fVoice := ExpandFileName(fVoice);
      if not FileExists(fVoice) then
      begin
        WriteLn('Please specify the target file');
        Terminate;
        Exit;
      end
      else
      begin
        if FileExists(fVoice) then
        begin
          DispatchCheck(fVoice, fVoice, bVerbose, fOutput, fSettings);
        end;
      end;
    end;
    Terminate;
  end;

  constructor TMK2toMK1.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

  destructor TMK2toMK1.Destroy;
  begin
    inherited Destroy;
  end;

  procedure TMK2toMK1.WriteHelp;
  begin
    writeln('');
    writeln('');
    writeln('Yamaha DX7II to DX7 Converter 1.0');
    writeln('Author: Boban Spasic');
    writeln('https://github.com/BobanSpasic/MK2toMK1');
    writeln('');
    writeln('Usage: ', ExtractFileName(ExeName), ' -parameters');
    writeln('  Parameters (short and long form):');
    writeln('       -h               --help                 This help message');
    writeln('       -i (filename)    --info=(filename)      Information');
    writeln('       -c (filename)    --convert=(filename)   Convert to DX7 bank');
    writeln('       -o (path)        --output=(path)        Output directory');
    writeln('       -s (filename)    --settings=(filename)  Use settings file (see separate doc.)');
    writeln('       -v               --verbose              Detailed info');
    writeLn('');
    writeLn('  Parameters are CASE-SENSITIVE');
    writeLn('');
    writeln('  Example usage:');
    writeln('    Get info from any kind of supported files:');
    writeln('       MK2toMK1 -i VoiceBank.syx');
    writeln('    Convert DX7II bank or performance to DX7 banks:');
    writeln('       MK2toMK1 -c My_DX7II_Dump.syx');
    writeLn('');
    writeLn('');
  end;

var
  Application: TMK2toMK1;

{$R *.res}

begin
  Application := TMK2toMK1.Create(nil);
  Application.Title := 'MK2toMK1 Converter';
  Application.Run;
  Application.Free;
end.
