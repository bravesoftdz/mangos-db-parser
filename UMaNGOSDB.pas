unit UMaNGOSDB;

interface

uses
    SysUtils, Classes, IniFiles,
    UMainDataModule;

type
    TParseType = (ptNone = 0, ptByPK = 1, ptByPos = 2, ptByField = 3);

    TTableInfo = record
        name: string;
        parseType: TParseType;
        byField: string;
        clearFieldIndx: integer;
    end;

    TMaNGOSDB = class (TObject)
    private
        tables: array of TTableInfo;
    public
        constructor Create;
        destructor Destroy;
        procedure DoParse;
    end;

var
    DM: TMainDataModule;

implementation

uses OtherFunctions;

procedure parse_byMainKey;
begin
    //DI.TableName := tablename;
    DM := TMainDataModule.Create(nil);
    try
        //DM.Tmp1(DI);
    finally
        FreeAndNil (DM);
    end;
end;

{ TMaNGOSDB }

constructor TMaNGOSDB.Create;
var
    IniFile: TIniFile;
    Sections: TStrings;
    i: integer;
begin
    IniFile := TIniFile.Create(ExtractFilePath(paramStr(0)) + 'bases.ini');
    Sections := TStringList.Create;
    try
        IniFile.ReadSections (Sections);

        if (Sections.Count) < 1 then begin
            WriteLn ('No Tables in Conf-file. Exit.'); Exit;
        end else
            WriteLn ('Found ' + IntToStr (Sections.Count) + ' tables in INI-file.');

        for i := 0 to Sections.Count - 1 do begin
            SetLength (tables, i + 1);
            tables[i].name := Sections.Strings[i];
            tables[i].parseType := TParseType (IniFile.ReadInteger (Sections.Strings[i],'type',0));
            tables[i].byField := IniFile.ReadString(Sections.Strings[i],'byField','');
            tables[i].clearFieldIndx := IniFile.ReadInteger(Sections.Strings[i],'clearFieldIndx',-1);
        end;

        WriteLn ('Tables List:');
        for i := 0 to Length (tables) - 1 do begin
            WriteLn ('id: ' + IntToStr (i) + ' - ' + tables[i].name);
        end;
        printHR;

    finally
        FreeAndNil (IniFile);
        FreeAndNil (Sections);
    end;
end;

destructor TMaNGOSDB.Destroy;
begin
    SetLength (tables, 0);
end;

procedure TMaNGOSDB.DoParse;
var
    DI: TDataInfo;
    DM: TMainDataModule;
    i: integer;
begin
    printH1 ('Starting Parse tables...');
    for i := 0 to Length (tables) - 1 do begin
        printH2 ('Parsing table: ' + tables[i].name);
        DI.TableName := tables[i].name;
        DI.byField   := tables[i].byField;
        DI.clearFieldIndx := tables[i].clearFieldIndx;
        DM := TMainDataModule.Create(nil);
        try
            case tables[i].parseType of
                ptByPK: DM.ParseByPrimaryKey (DI);
                ptByPos: DM.ParseByPosition(DI);
                ptByField: DM.ParseByPrimaryKey(DI, false);
                else WriteLn ('Action not specified');
            end;
        finally
            FreeAndNil (DM);
        end;
    end;
    printHR;
end;

end.
