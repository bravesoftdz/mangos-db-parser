unit USQLDataModule;

interface

uses
  SysUtils, Classes, DB, DBAccess, MyAccess, MemDS, UDataTypes, UConsole;

type
  PFields = ^TFields;
  TSQLDataModule = class (TDataModule)
    tSRC: TMyTable;
    tDST: TMyTable;
    connDST: TMyConnection;
    connSRC: TMyConnection;
  private
    function ExportData (Fields: TFields; DataInfo: TParseInfo): string;
    function CompareData (Fields: TFields; DataInfo: TParseInfo): boolean;
    function IsPosNear (coordS, coordD: TGameCoord; dst: integer): boolean;
    function GetPosData (Data: PFields): TGameCoord;
  public
    constructor CreateExt (const ParseInfo: TParseInfo; mergeInfo: PMergeInfo);
    function ParseData (ParseInfo: TParseInfo): TMergeInfo;
  end;

var
  SQLDataModule: TSQLDataModule;

implementation

{$R *.dfm}

uses UMaNGOSDB2;

{ TSQLDataModule }

constructor TSQLDataModule.CreateExt (const ParseInfo: TParseInfo; mergeInfo: PMergeInfo);
begin
    inherited Create (nil);
    if (mergeInfo <> nil)
        then mergeInfo^ := ParseData (ParseInfo)
        else ParseData(ParseInfo);
end;

function TSQLDataModule.ExportData (Fields: TFields; DataInfo: TParseInfo): string;
var
    OutS: TStringBuilder;
    i, tmp: integer;
begin
    OutS := TStringBuilder.Create ('insert into ' + DataInfo.tableName + ' values (');
    try
        for i := 0 to Fields.Count - 1 do begin
            if (i = DataInfo.clearFieldIndex) then
                OutS.Append ('''''')
            else if (Fields[i].FieldName = DataInfo.incFieldName) then begin
                if (Fields[i].AsInteger = 0)
                    then tmp := 0
                    else tmp := Fields[i].AsInteger + DataInfo.incFieldCount;
                OutS.Append ('''' + IntToStr (tmp) + ''', ');
            end else begin
                OutS.Append('''');
                OutS.Append (StringReplace (Fields[i].AsString, '''', '\''', [rfReplaceAll]));
                OutS.Append(''', ');
            end;
        end;
        OutS.Remove (OutS.Length - 2, 2);
        OutS.Append (');');
        Result := OutS.ToString;
    finally
        FreeAndNil (OutS);
    end;
end;

function TSQLDataModule.GetPosData(Data: PFields): TGameCoord;
begin
    Result.map := Data.FieldByName ('map').AsInteger;
    Result.x   := Data.FieldByName ('position_x').AsInteger;
    Result.y   := Data.FieldByName ('position_y').AsInteger;
    Result.z   := Data.FieldByName ('position_z').AsInteger;
end;

function TSQLDataModule.CompareData(Fields: TFields; DataInfo: TParseInfo): boolean;
begin
    //
end;

function TSQLDataModule.IsPosNear (coordS, coordD: TGameCoord; dst: integer): boolean;
function IsCoordNear (c1, c2: integer): boolean;
begin
    //Result := ((c1 < c2) and (c1 + dst < c2)) or ((c1 > c2) and (c1 - dst > c2));
    Result := (Abs (c1 - c2) < dst);
end;
begin
    Result := false;
    if (coordS.map = coordD.map)
        then if (IsCoordNear (coordS.x, coordD.x))
            then if (IsCoordNear (coordS.y, coordD.y))
                then if (IsCoordNear (coordS.z, coordD.z))
                    then Result := true;
    {if (
        (coordS.map = coordD.map) and
        (abs (coordS.x - coordD.x) < dst) and
        (abs (coordS.y - coordD.y) < dst) and
        (abs (coordS.z - coordD.z) < dst)
    ) then Result := true
    else Result := false;}
end;

function TSQLDataModule.ParseData (ParseInfo: TParseInfo): TMergeInfo;
var
    i, k: integer;
    parseKeys, compareKeys: TStrings;
    filterString: TStringBuilder;
    IDsDiffs, IDsUnique: TStringBuilder;
    countCommon, countUniqueSRC, countUniqueDST: integer;
    isRowsEqual: boolean;
    OutFile: TextFile;
begin
    WriteLn;
    PrintH2 ('Parsing table: ' + ParseInfo.tableName + ' by Primary Key' + #10#13#10#13);

    // ќткрываем исходную таблицу, примен€€ фильтр, если он указан
    tSRC.TableName := ParseInfo.tableName;
    tSRC.OrderFields := ParseInfo.parseKey;
    if (ParseInfo.sqlFilter <> '')
        then tSRC.FilterSQL := ParseInfo.sqlFilter;
    tSRC.Open;
    WriteLn ('SRC table rows count: ', IntToStr (tSRC.RecordCount));

    // ќткрываем доп. таблицу, примен€€ фильтр, если он указан
    tDST.TableName := ParseInfo.tableName;
    tDST.OrderFields := ParseInfo.parseKey;
    if (ParseInfo.sqlFilter <> '')
        then tDST.FilterSQL := ParseInfo.sqlFilter;
    tDST.Open;
    WriteLn ('DST table rows count: ', IntToStr (tDST.RecordCount));

    // »нформируем о ключах
    Writeln;
    WriteLn ('PRIMARY key is: ', tSRC.IndexDefs.Find('PRIMARY').Fields);

    parseKeys := TStringList.Create;
    parseKeys.Delimiter := ';';
    if (ParseInfo.parseKey <> '')
        then parseKeys.DelimitedText := ParseInfo.parseKey
        else parseKeys.DelimitedText := tSRC.IndexDefs.Find('PRIMARY').Fields;

    compareKeys := TStringList.Create;
    compareKeys.Delimiter := ';';
    compareKeys.DelimitedText := ParseInfo.compareKey;

    for i := 0 to parseKeys.Count - 1 do WriteLn ('Using Key ' + IntToStr (i+1) + ': ' + parseKeys.Strings [i]);

    IDsDiffs := TStringBuilder.Create;
    IDsUnique := TStringBuilder.Create;

    AssignFile (OutFile, ExtractFilePath (paramStr (0)) + 'sql\' + ParseInfo.tableName + '.sql');
    Rewrite (OutFile);

    tSRC.Filtered := true;

    for i := 1 to tDST.RecordCount do begin
        tDST.RecNo := i;
        updateProgress (i, tDST.RecordCount);

        //  онструируем фильтр дл€ парсера
        filterString := TStringBuilder.Create;
        for k := 0 to parseKeys.Count - 1 do begin
            filterString.Append (parseKeys.Strings[k]);
            filterString.Append (' = ''');
            filterString.Append (StringReplace (tDST.FieldByName(parseKeys.Strings[k]).AsString, '''', '''''', [rfReplaceAll]));
            filterString.Append (''' and ');
        end;
        filterString.Remove (filterString.Length - 5, 5);

        tSRC.Filter := filterString.ToString;

        if (ParseInfo.parseType = ptypeByKey) then begin
            if (tSRC.RecordCount = 0) then begin
                IDsUnique.Append (tDST.FieldByName(ParseInfo.mergeInfoKey).AsString + ', ');
                Inc (Result.countUnique);
                WriteLn (OutFile, ExportData (tDST.Fields, ParseInfo));
            end else if (tSRC.RecordCount = 1) then begin
                isRowsEqual := true;
                for k := 0 to compareKeys.Count - 1 do
                    if (tSRC.FieldByName(compareKeys.Strings[k]).AsString <> tDST.FieldByName(compareKeys.Strings[k]).AsString)
                        then isRowsEqual := false;
                if (not isRowsEqual) then begin
                    IDsDiffs.Append (tDST.FieldByName(ParseInfo.mergeInfoKey).AsString + ', ');
                    Inc (Result.countDiffs);
                end;
            end;
        end else if (ParseInfo.parseType = ptypeByPos) then begin
            if (tSRC.RecordCount = 0) then begin
                IDsUnique.Append (tDST.FieldByName(ParseInfo.mergeInfoKey).AsString + ', ');
                Inc (Result.countUnique);
                WriteLn (OutFile, ExportData (tDST.Fields, ParseInfo));
            end else begin
                isRowsEqual := false;
                for k := 1 to tSRC.RecordCount do begin
                    tSRC.RecNo := k;
                    if (IsPosNear (GetPosData (@(tSRC.Fields)), GetPosData (@(tDST.Fields)), 20)) then begin
                        isRowsEqual := true;
                        break;
                    end;
                end;
                if (not isRowsEqual) then begin
                    IDsUnique.Append (tDST.FieldByName(ParseInfo.mergeInfoKey).AsString + ', ');
                    Inc (Result.countUnique);
                    WriteLn (OutFile, ExportData (tDST.Fields, ParseInfo));
                end;
            end;
        end else if (ParseInfo.parseType = ptypeAll) then begin
            WriteLn (OutFile, ExportData (tDST.Fields, ParseInfo));
        end;

        FreeAndNil (filterString);
    end;

    if (IDsUnique.Length > 2)
        then IDsUnique.Remove(IDsUnique.Length - 2, 2);
    if (IDsDiffs.Length > 2)
        then IDsDiffs.Remove(IDsDiffs.Length - 2, 2);

    Result.listUnique := IDsUnique.ToString;
    Result.listDiffs := IDsDiffs.ToString;

    WriteLn (OutFile);
    WriteLn (OutFile, '# Unique IDs: ', Result.listUnique);
    WriteLn (OutFile, '# Diffs IDs: ', Result.listDiffs);

    CloseFile (OutFile);
    FreeAndNil (parseKeys);
    FreeAndNil (compareKeys);
    FreeAndNil (IDsDiffs);
    FreeAndNil (IDsUnique);
end;

end.
