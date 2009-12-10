unit UMaNGOSDB2;

interface

uses
    SysUtils,
    UDataTypes, UConsole, USQLDataModule, UMainDataModule, Classes;

type
    // Главный класс для разбора таблиц
    TMangosDB2 = class (TObject)
    private
        DataModule: TSQLDataModule;
    public
        constructor Create (tblsGroup: TTablesGroup);

        procedure ParseCreaturesData;
        procedure ParseRelationsData;

        procedure SaveCacheData (const dataName, Data: string);
        function  LoadCacheData (const dataName: string): string;
    end;

implementation

{ TMangosDB2 }

constructor TMangosDB2.Create (tblsGroup: TTablesGroup);
begin
    case tblsGroup of
        tblsCreature: ParseCreaturesData;
        else WriteLn ('This Tables Group Not Defined Yet...');
    end;
end;

procedure TMangosDB2.ParseCreaturesData;
var
    parseInfo: TParseInfo;
    miTemplates: TMergeInfo;
    miCopy: TMergeInfo;
begin
    // entry для всех таблиц - меньше 40000

    // Парсим таблицу Creature_Template
    // Выбираем все ентри, которых нет в оригинальной базе
    // Сохраняем список неправильных дубликатов
    {parseInfo.ReCreate ('creature_template', ptypeByKey);
    parseInfo.parseKey := 'entry';
    parseInfo.compareKey := 'entry;name';
    parseInfo.mergeInfoKey := 'entry';
    parseInfo.sqlFilter := 'entry < 40000'; //40000';
    parseInfo.incFieldName := 'equipment_id';
    parseInfo.incFieldCount := 10000;

    DataModule := TSQLDataModule.CreateExt (parseInfo, @miTemplates);
    FreeAndNil (DataModule);

    SaveCacheData ('creature_template.diffs', miTemplates.listDiffs); }

    // Парсим таблицу Creature
    // Выбираем все записи по координатам в игровом мире
    // Сохраняем список записей, которые мы скопировали
    parseInfo.ReCreate ('creature', ptypeByPos);
    parseInfo.parseKey := 'id';
    parseInfo.mergeInfoKey := 'guid';
    parseInfo.sqlFilter := '(id < 40000)';// and (id not in (' + miTemplates.listDiffs + '))'; // id < 40000 !
    parseInfo.incFieldName := 'guid';
    parseInfo.incFieldCount := 500000;

    DataModule := TSQLDataModule.CreateExt (parseInfo, @miCopy);
    FreeAndNil (DataModule);

    SaveCacheData ('creature.unique', miCopy.listUnique);

    // Парсим таблицу Creature_Template_Addon
    parseInfo.ReCreate ('creature_template_addon', ptypeByKey);
    parseInfo.mergeInfoKey := 'entry';
    parseInfo.sqlFilter := '(entry < 40000) and (entry not in (' + miTemplates.listDiffs + '))';

    DataModule := TSQLDataModule.CreateExt (parseInfo, nil);
    FreeAndNil (DataModule);

    // Парсим Creature_OnKill_Reputation
    parseInfo.ReCreate ('creature_onkill_reputation', ptypeByKey);
    parseInfo.mergeInfoKey := 'creature_id';
    parseInfo.sqlFilter := '(creature_id < 40000) and (creature_id not in (' + miTemplates.listDiffs + '))';

    DataModule := TSQLDataModule.CreateExt (parseInfo, nil);
    FreeAndNil (DataModule);

    // Парсим Creature_Movement
    parseInfo.ReCreate ('creature_movement', ptypeAll);
    parseInfo.mergeInfoKey := 'id';
    parseInfo.sqlFilter := '(id < 40000) and (id in (' + miCopy.listUnique + '))';
    parseInfo.incFieldName := 'id';
    parseInfo.incFieldCount := 500000;

    DataModule := TSQLDataModule.CreateExt (parseInfo, nil);
    FreeAndNil (DataModule);

    // Парсим Creature_Model_Info
    parseInfo.ReCreate ('creature_model_info', ptypeAll);
    parseInfo.mergeInfoKey := 'modelid';
    parseInfo.sqlFilter := '(modelid < 40000)';
    parseInfo.incFieldName := 'modelid';
    parseInfo.incFieldCount := 10000;

    DataModule := TSQLDataModule.CreateExt (parseInfo, nil);
    FreeAndNil (DataModule);

    // Парсим Creature_Addon
    parseInfo.ReCreate ('creature_addon', ptypeByKey);
    parseInfo.mergeInfoKey := 'guid';
    parseInfo.sqlFilter := '(guid in (' + miCopy.listUnique + '))';
    parseInfo.incFieldName := 'guid';
    parseInfo.incFieldCount := 500000;

    DataModule := TSQLDataModule.CreateExt (parseInfo, nil);
    FreeAndNil (DataModule);
end;

procedure TMangosDB2.ParseRelationsData;
var
    parseInfo: TParseInfo;
begin
    // Парсим Creature_Questrelation
    parseInfo.ReCreate ('creature_questrelation', ptypeByKey);
    parseInfo.mergeInfoKey := 'id';
    //parseInfo.sqlFilter := '(id < 400) and (id not in (' + miTemplates.listDiffs + '))';

    DataModule := TSQLDataModule.CreateExt(parseInfo, nil);
    FreeAndNil (DataModule);
end;

procedure TMangosDB2.SaveCacheData (const dataName, Data: string);
var
    DataStrings: TStrings;
    FileName: string;
begin
    FileName := ExtractFilePath (paramStr (0)) + 'cache\' + dataName + '.cache';

    DataStrings := TStringList.Create;
    try
        DataStrings.Delimiter := ' ';
        DataStrings.DelimitedText := Data;
        DataStrings.SaveToFile (FileName, TEncoding.UTF8);
    finally
        FreeAndNil (DataStrings);
    end;
end;

function TMangosDB2.LoadCacheData(const dataName: string): string;
var
    DataStrings: TStrings;
    FileName: string;
begin
    FileName := ExtractFilePath (paramStr (0)) + 'cache\' + dataName + '.cache';

    DataStrings := TStringList.Create;
    try
        DataStrings.Delimiter := ' ';
        DataStrings.LoadFromFile (FileName, TEncoding.UTF8);
        Result := DataStrings.DelimitedText;
    finally
        FreeAndNil (DataStrings);
    end;
end;

end.
