unit UDataTypes;

interface

type
    // �������� ����� ������
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
        // ��� �������
        tableName: string;
        // ��� ��������
        parseType: TParseType;

        // ���� ��� ��������
        // ������������ ��� �������� ���. �������, ������ �� ����� ����� ������� ������ ��� ������������ ���������
        // ���� �� ����� - ������������ Primary Key
        parseKey: string;

        // ���� ��� "�������" ��������� ������
        // ���������� ��� ��������� ������, � ���������� ���, ��� ����� ���������� ������� ����,
        // �� ���-���� ����������
        // ���������� ������ ��� ptypeByKey
        compareKey: string;

        // ���� ��� ������ merge
        mergeInfoKey: string;
        // ���. ������
        sqlFilter: string;
        // ������ ���������� ����
        clearFieldIndex: integer;
        // ��� �������������� ���� � �� ������� �����������
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
