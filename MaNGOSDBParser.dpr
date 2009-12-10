program MaNGOSDBParser;

{$APPTYPE CONSOLE}

uses
  //FastMM4,
  SysUtils,
  Windows,
  UMainDataModule in 'UMainDataModule.pas' {MainDataModule: TDataModule},
  UConsole in 'UConsole.pas',
  UMaNGOSDB in 'UMaNGOSDB.pas',
  UMaNGOSDB2 in 'UMaNGOSDB2.pas',
  USQLDataModule in 'USQLDataModule.pas' {SQLDataModule: TDataModule},
  UDataTypes in 'UDataTypes.pas';

var
    MangosDB2: TMangosDB2;

begin
    {$ifdef Debug}
        ReportMemoryLeaksOnShutdown := DebugHook <> 0;
    {$endif}
    try
        printH1 ('Loaded...');

        MangosDB2 := TMangosDB2.Create (tblsCreature);
        FreeAndNil (MangosDB2);

        Writeln;
        WriteLn ('Press any key to exit...');
        ReadLn;
    except
        on E:Exception do
            Writeln(E.Classname, ': ', E.Message);
    end;
end.
