unit UMainDataModule;

interface

uses
  SysUtils, Classes, Variants, DB, DBAccess, MyAccess, MemDS;

type
  TDataInfo = record
      tableName: string;
      byField: string;
      clearFieldIndx: integer;
  end;

  TMainDataModule = class(TDataModule)
        connSRC: TMyConnection;
        connDST: TMyConnection;
        tSRC: TMyTable;
        tDST: TMyTable;
  private
        function ExportString (Fields: TFields; DI: TDataInfo): string;
  public
        procedure ParseByPrimaryKey (DI: TDataInfo; isPK: boolean = true);
        procedure ParseByPosition (DI: TDataInfo);
        procedure Tmp1 (DI: TDataInfo);
  end;

implementation

{$R *.dfm}

uses
    OtherFunctions;

{ TMainDataModule }

procedure TMainDataModule.ParseByPrimaryKey (DI: TDataInfo; isPK: boolean = true);
var
    i, j: integer;
    PKeys: TStrings;
    FilterString: string;
    OutString: TStringBuilder;
    OutFile: TextFile;
begin
    WriteLn ('Parsing table: ' + DI.TableName + ' by Primary Key'); WriteLn;

    tSRC.TableName := DI.TableName;
    tSRC.Open;
    WriteLn ('SRC table rows count: ' + IntToStr (tSRC.RecordCount));

    tDST.TableName := DI.TableName;
    tDST.Open;
    WriteLn ('DST table rows count: ' + IntToStr (tDST.RecordCount));

    Writeln;
    WriteLn ('PRIMARY key is: ' + tSRC.IndexDefs.Find('PRIMARY').Fields);

    PKeys := TStringList.Create;
    PKeys.Delimiter := ';';
    if (isPK)
        then PKeys.DelimitedText := tSRC.IndexDefs.Find('PRIMARY').Fields
        else PKeys.DelimitedText := DI.byField;

    for i := 0 to PKeys.Count - 1 do WriteLn ('Key ' + IntToStr (i) + ': ' + PKeys.Strings[i]);

    AssignFile (OutFile, ExtractFilePath (paramStr (0)) + DI.TableName + '.sql');
    ReWrite (OutFile);

    for i := 0 to tDST.RecordCount - 1 do begin
        tSRC.RecNo := 0;
        tDST.RecNo := i;
        updateProgress (i, tDST.RecordCount);

        case PKeys.Count of
            1: FilterString := PKeys.Strings[0] + ' = ' + tDST.FieldByName(PKeys.Strings[0]).AsString;
            2: FilterString := PKeys.Strings[0] + ' = ' + tDST.FieldByName(PKeys.Strings[0]).AsString + ' and ' +
                               PKeys.Strings[1] + ' = ' + tDST.FieldByName(PKeys.Strings[1]).AsString;
            else begin WriteLn ('Error ! Count of Keys bigger than 2 ! Exit...'); break; end;
        end;

        tSRC.Filtered := false;
        tSRC.Filter := FilterString;
        tSRC.Filtered := true;

        if (tSRC.RecordCount = 0) then begin
            OutString := TStringBuilder.Create ('insert into ' + DI.TableName + ' values (');
            for j := 0 to tDST.FieldCount - 1 do begin
                OutString.Append ('''');
                OutString.Append (StringReplace (tDST.Fields[j].AsString, '''', '\''', [rfReplaceAll]));
                OutString.Append (''', ');
            end;
            OutString.Remove (OutString.Length - 2, 2);
            OutString.Append (');');
            WriteLn (OutFile, OutString.ToString);
            FreeAndNil (OutString);
        end;
    end;

    CloseFile (OutFile);
    FreeAndNil (PKeys);
end;

procedure TMainDataModule.ParseByPosition(DI: TDataInfo);
type
    gameCoord = record
        map: integer;
        x, y, z: Extended;
    end;
var
    OutFile: TextFile;
    PKeys: TStrings;
    i, j, k: integer;
    FilterString: string;
    OutString: TStringBuilder;
    coordSRC, coordDST: gameCoord;
    NeedExport: boolean;
begin
    WriteLn ('Parsing table: ' + DI.TableName + ' by Position'); WriteLn;

    tSRC.TableName := DI.TableName;
    tSRC.OrderFields := DI.byField;
    tSRC.Open;
    WriteLn ('SRC table rows count: ' + IntToStr (tSRC.RecordCount));

    tDST.TableName := DI.TableName;
    tDST.OrderFields := DI.byField;
    tDST.Open;
    WriteLn ('DST table rows count: ' + IntToStr (tDST.RecordCount));

    Writeln;
    WriteLn ('PRIMARY key is: ' + tSRC.IndexDefs.Find('PRIMARY').Fields);

    PKeys := TStringList.Create;
    PKeys.Delimiter := ';';
    PKeys.DelimitedText := DI.byField;
    for i := 0 to PKeys.Count - 1 do WriteLn ('Passed Key ' + IntToStr (i) + ': ' + PKeys.Strings[i]);

    AssignFile (OutFile, ExtractFilePath (paramStr (0)) + DI.TableName + '.sql');
    ReWrite (OutFile);

    for i := 1 to tDST.RecordCount do begin
        tDST.RecNo := i;
        updateProgress (i, tDST.RecordCount);

        case PKeys.Count of
            1: FilterString := PKeys.Strings[0] + ' = ' + tDST.FieldByName(PKeys.Strings[0]).AsString;
            2: FilterString := PKeys.Strings[0] + ' = ' + tDST.FieldByName(PKeys.Strings[0]).AsString + ' and ' +
                               PKeys.Strings[1] + ' = ' + tDST.FieldByName(PKeys.Strings[1]).AsString;
            else begin WriteLn ('Error ! Count of Keys bigger than 2 ! Exit...'); break; end;
        end;

        tSRC.Filtered := false;
        tSRC.Filter := FilterString;
        tSRC.Filtered := true;

        if (tSRC.RecordCount = 0) then
            WriteLn (OutFile, ExportString (tDST.Fields, DI))
        else begin
            NeedExport := true;
            for k := 0 to tSRC.RecordCount - 1 do begin
                with tSRC, coordSRC do begin
                    map := FieldByName ('map').AsInteger;
                    x   := FieldByName ('position_x').AsExtended;
                    y   := FieldByName ('position_y').AsExtended;
                    z   := FieldByName ('position_z').AsExtended;
                end;
                with tDST, coordDST do begin
                    map := FieldByName ('map').AsInteger;
                    x   := FieldByName ('position_x').AsExtended;
                    y   := FieldByName ('position_y').AsExtended;
                    z   := FieldByName ('position_z').AsExtended;
                end;
                if (
                    (coordSRC.map <> coordDST.map) or
                    ((coordSRC.x < coordDST.x) and (coordSRC.x + 30 < coordDST.x)) or
                    ((coordSRC.x > coordDST.x) and (coordSRC.x - 30 > coordDST.x)) or
                    ((coordSRC.y < coordDST.y) and (coordSRC.y + 30 < coordDST.y)) or
                    ((coordSRC.y > coordDST.y) and (coordSRC.y - 30 > coordDST.y)) or
                    ((coordSRC.z < coordDST.z) and (coordSRC.z + 20 < coordDST.z)) or
                    ((coordSRC.z > coordDST.z) and (coordSRC.z - 20 > coordDST.z))
                ) then begin
                    // Do nothing
                end else begin
                    NeedExport := false;
                    break;
                end;
                        {
                        WriteLn;
                        with tSRC do
                            WriteLn ('SRC guid: ' + FieldByName ('guid').AsString + ' id: ' + FieldByName ('id').AsString);
                        with coordSRC do
                            WriteLn ('SRC map: ' + IntToStr (map) + ' x: ' + FloatToStr (x) + ' y: ' + FloatToStr (y) + ' z: ' + FloatToStr (z));
                        with tDST do
                            WriteLn ('DST guid: ' + FieldByName ('guid').AsString + ' id: ' + FieldByName ('id').AsString);
                        with coordDST do
                            WriteLn ('DST map: ' + IntToStr (map) + ' x: ' + FloatToStr (x) + ' y: ' + FloatToStr (y) + ' z: ' + FloatToStr (z));
                        }
            end;
            if (NeedExport) then
                WriteLn (OutFile, ExportString (tDST.Fields, DI));
        end;
    end;

    CloseFile (OutFile);
    FreeAndNil (PKeys);
end;

function TMainDataModule.ExportString (Fields: TFields; DI: TDataInfo): string;
var
    OutS: TStringBuilder;
    i: integer;
begin
    OutS := TStringBuilder.Create ('insert into ' + DI.TableName + ' values (');
    try
        for i := 0 to Fields.Count - 1 do begin
            OutS.Append('''');
            if (i <> DI.clearFieldIndx)
                then OutS.Append(StringReplace(Fields[i].AsString, '''', '\''', [rfReplaceAll]));
            OutS.Append(''', ');
        end;
        OutS.Remove(OutS.Length - 2, 2);
        OutS.Append(');');
        Result := OutS.ToString;
    finally
        FreeAndNil (OutS);
    end;
end;

procedure TMainDataModule.Tmp1 (DI: TDataInfo);
var
    I, J: integer;
begin
    // Get SRC
    {qSRC.SQL.Clear;
    qSRC.SQL.Add(DI.Query);
    qSRC.Execute;
    WriteLn ('Source count: ' + IntToStr (qSRC.RecordCount));   }

    // Get DST
    {qDST.SQL.Clear;
    qDST.SQL.Add(DI.Query);
    qDST.Execute;
    WriteLn ('Destination count: ' + IntToStr (qDST.RecordCount));  }

    {for I := 0 to qSRC.Fields.Count - 1 do begin
        write ('Field: ' + qSRC.Fields[I].FullName + ' ');
        writeln;
    end;}

    {for I := 0 to qSRC.RecordCount do begin
        qSRC.RecNo := I;
        qDST.FilterSQL := 'criteria_id = ''' + qSRC.Fields[0].AsString + '''';
        writeln ('Found: ' + IntToStr (qDST.RecordCount));
    end;}

    WriteLn ('Parsing table: ' + DI.TableName); WriteLn;

    tSRC.TableName := DI.TableName;
    tSRC.Open;
    WriteLn ('SRC table rows count: ' + IntToStr (tSRC.RecordCount));

    tDST.TableName := DI.TableName;
    tDST.Open;
    WriteLn ('DST table rows count: ' + IntToStr (tDST.RecordCount));

    WriteLn;
    WriteLn ('Index is: ' +    tDST.IndexDefs.Find('PRIMARY').Fields);

    //if (tDST.Locate (tDST.IndexDefs.Find('PRIMARY').Fields, VarArrayOf ([204, 12]), [])) then
    //    WriteLn ('Curpos: ' + IntTostr (tDST.RecNo));

    {tDST.Filter := 'entry = 204';
    tDST.Filtered := true;
    WriteLn ('DST count with 1 filter: ' + IntToStr (tDST.RecordCount));

    tDST.Filtered := false;
    WriteLn ('DST count without filter: ' + IntToStr (tDST.RecordCount));

    tDST.Filter := 'entry = 5 or entry = 10 or entry = 45';
    tDST.Filtered := true;
    WriteLn ('DST count without 3 filters: ' + IntToStr (tDST.RecordCount));   }

    printHR;
end;

end.
