program RegExTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  DateUtils,
  RegularExpr in 'RegularExpr.pas',
  RegularExpr.Tests in 'RegularExpr.Tests.pas',
  RegularExpr.Detail in 'RegularExpr.Detail.pas';

begin
  try
    TestRegExp;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
