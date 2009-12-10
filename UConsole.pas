unit UConsole;

interface

uses
    Windows, SysUtils;

procedure printHR;
procedure printH1 (s: string);
procedure printH2 (s: string);
procedure updateProgress (ready, all: integer);
procedure UpdateString (charcount: byte; s: string);

implementation

var
    STDOutputHandle: THandle;
    LogFile: TextFile;

procedure printHR;
begin
    Writeln;
    Writeln ('----------------------------------------------------');
    writeln;
end;

procedure printH1 (s: string);
begin
    WriteLn;
    WriteLn ('####################################################');
    WriteLn (s);
    WriteLn;
end;

procedure printH2 (s: string);
begin
    WriteLn;
    WriteLn ('----------------------------------------------------');
    WriteLn (s);
    WriteLn;
end;

procedure updateProgress (ready, all: integer);
begin
    UpdateString (30, IntToStr (ready) + '/' + IntToStr (all));
end;

procedure UpdateString (charcount: byte; s: string);
var
    C: Coord;
    ScreenBufferInfo: _CONSOLE_SCREEN_BUFFER_INFO;
begin
    GetConsoleScreenBufferInfo (STDOutputHandle, ScreenBufferInfo);
    C.X := ScreenBufferInfo.dwCursorPosition.X - charcount;
    C.Y := ScreenBufferInfo.dwCursorPosition.Y;
    SetConsoleCursorPosition (STDOutputHandle, C);
    s := s + '                                                                                     ';
    SetLength (s, charcount);
    Write (s);
end;

initialization
    STDOutputHandle := GetStdHandle (STD_OUTPUT_HANDLE);

end.
