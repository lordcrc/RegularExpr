unit RegularExpr.Tests;

interface

procedure TestRegExp;

implementation

uses
  System.SysUtils, System.StrUtils, RegularExpr;

function StrToASCII(const s: string): TBytes;
begin
  result := TEncoding.ASCII.GetBytes(s);
end;

function Bytes(const b: array of Byte): TBytes;
begin
  SetLength(result, Length(b));
  Move(b[0], result[0], Length(result));
end;

procedure Test1;
var
  re: RegEx;
  m: RegExMatch;
begin
  re := RegEx.Create('b+');

  m := re.Match(StrToASCII('abc'));
  if (m) then
    WriteLn('1 OK')
  else
    WriteLn('1 FAIL');

  m := re.Match(StrToASCII('abbbbbc'));
  if (m) then
    WriteLn('2 OK ' + MidStr('abbbbbc', m.Offset + 1, m.Length))
  else
    WriteLn('2 FAIL');

  m := re.Match(StrToASCII('def'));
  if (not m) then
    WriteLn('3 OK')
  else
    WriteLn('3 FAIL');


  //WriteLn(TEncoding.ANSI.GetBytes('ø')[0]);
  re := RegEx.Create('\x{F8}');
  m := re.Match(Bytes([$f8]));
  if (m) then
    WriteLn('4 OK')
  else
    WriteLn('4 FAIL');

  re := RegEx.Create('\w');
  m := re.Match(Bytes([$f8]));
  if (not m) then
    WriteLn('5 OK')
  else
    WriteLn('5 FAIL');
end;


procedure TestRegExp;
begin
  Test1;
end;

end.

