program RegExTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  TestInsight.Client,
  TestInsight.DUnit,
  DUnitTestRunner,
  RegularExpr.Detail in '..\RegularExpr.Detail.pas',
  RegularExpr in '..\RegularExpr.pas',
  TestRegularExpr in 'TestRegularExpr.pas';

{$R *.RES}

function IsTestInsightRunning: Boolean;
var
  client: ITestInsightClient;
begin
  client := TTestInsightRestClient.Create;
  client.StartedTesting(0);
  Result := not client.HasError;
end;

begin
  if IsTestInsightRunning then
    TestInsight.DUnit.RunRegisteredTests
  else
    DUnitTestRunner.RunRegisteredTests;
end.

