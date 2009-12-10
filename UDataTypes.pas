unit UDataTypes;

interface

type
    // Описание групп таблиц
    TTablesGroup = (tblsCustom = 0, tblsCreature = 1, tblsGameObjects = 2);

    TParseType = (ptypeByKey = 0, ptypeByPos = 1, ptypeAll = 2);

    TGameCoord = record
        map: integer;
        x, y, z: integer;
    end;
    PGameCoord = ^TGameCoord;

    TMergeInfo = record
        listUnique: string;
        listDiffs: string;

        countDiffs: integer;
        countUnique: integer;
    end;
    PMergeInfo = ^TMergeInfo;

    TParseInfo = record
        // Имя таблицы
        tableName: string;
        // Тип парсинга
        parseType: TParseType;

        // Ключ для парсинга
        // Используется для создания доп. фильтра, именно по этому ключу находим записи для последующего сравнения
        // Если не задан - используется Primary Key
        parseKey: string;

        // Ключ для "полного" сравнения данных
        // Используем для сравнения данных, и нахождения тех, что имеют одинаковый главный ключ,
        // но все-таки отличаются
        // Используем только для ptypeByKey
        compareKey: string;

        // Ключ для списка merge
        mergeInfoKey: string;
        // Доп. фильтр
        sqlFilter: string;
        // Индекс очищаемого поля
        clearFieldIndex: integer;
        // Имя увеличиваемого поля и на сколько увеличиваем
        incFieldName: string;
        incFieldCount: integer;
    public
        procedure ReCreate (table: string; pType: TParseType);
    end;

implementation

{ TParseInfo }

procedure TParseInfo.ReCreate(table: string; pType: TParseType);
begin
    tableName := table;
    parseType := pType;

    parseKey := '';
    compareKey := '';
    mergeInfoKey := '';
    sqlFilter := '';
    clearFieldIndex := -1;
    incFieldName := '';
    incFieldCount := 0;
end;

end.
