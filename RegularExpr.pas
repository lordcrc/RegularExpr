unit RegularExpr;

interface

uses
  System.SysUtils, RegularExpr.Detail;

type
  RegExOption = (
    RegExCaseInsensitive,
    RegExMultiLine,
    RegExSingleLine,
    RegExExtended,
    RegExAnchored
  );
  RegExOptions = set of RegExOption;

  RegExFlag = (
    RegExFlagNotBOL,
    RegExFlagNotEOL
  );
  RegExMatchFlags = set of RegExFlag;

  RegExMatch = record
  strict private
    FMatched: boolean;
    FLength: integer;
    FOffset: integer;
  private
    class function Create(const Matched: boolean; const Offset, Length: integer): RegExMatch; static;
  public
    class operator Implicit(const Match: RegExMatch): boolean;
    class operator LogicalNot(const Match: RegExMatch): boolean;

    property Matched: boolean read FMatched;
    property Offset: integer read FOffset;
    property Length: integer read FLength;
  end;

  RegEx = record
  strict private
    FImpl: RegularExpr.Detail.IRegExpr;
  private
    property Impl: RegularExpr.Detail.IRegExpr read FImpl;
  public
    class function Create(const Pattern: string; const Options: RegExOptions = []): RegEx; static;

    class operator Implicit(const Impl: RegularExpr.Detail.IRegExpr): RegEx;

    function Match(const Data: TBytes; const MatchFlags: RegExMatchFlags = []): RegExMatch; overload;
    function Match(const Data: PByte; const DataLength: integer; const MatchFlags: RegExMatchFlags): RegExMatch; overload;
    function Match(const Data: PByte; const DataLength: integer): RegExMatch; overload;
  end;


implementation

uses
  RegularExpressionsAPI;

function RegExOptionsToPCREOptions(const Options: RegExOptions): integer;
begin
  result := PCRE_NEWLINE_ANY;
  if (RegExCaseInsensitive in Options) then
    result := result OR PCRE_CASELESS;
  if (RegExMultiLine in Options) then
    result := result OR PCRE_MULTILINE;
  if (RegExSingleLine in Options) then
    result := result OR PCRE_DOTALL;
  if (RegExExtended in Options) then
    result := result OR PCRE_EXTENDED;
  if (RegExAnchored in Options) then
    result := result OR PCRE_ANCHORED;
end;

function RegExMatchFlagsToPCREFlags(const Flags: RegExMatchFlags): integer;
begin
  result := 0;
  if (RegExFlagNotBOL in Flags) then
    result := result or PCRE_NOTBOL;
  if (RegExFlagNotEOL in Flags) then
    result := result or PCRE_NOTEOL;
end;


{ RegExMatch }

class function RegExMatch.Create(const Matched: boolean; const Offset, Length: integer): RegExMatch;
begin
  result.FMatched := Matched;
  result.FOffset := Offset;
  result.FLength := Length;
end;

class operator RegExMatch.Implicit(const Match: RegExMatch): boolean;
begin
  result := Match.Matched;
end;

class operator RegExMatch.LogicalNot(const Match: RegExMatch): boolean;
begin
  result := not Match.Matched;
end;

{ RegEx }

class function RegEx.Create(const Pattern: string; const Options: RegExOptions): RegEx;
var
  opts: integer;
begin
  opts := RegExOptionsToPCREOptions(Options);

  result := TRegExprImpl.Create(Pattern, opts);
end;

class operator RegEx.Implicit(const Impl: RegularExpr.Detail.IRegExpr): RegEx;
begin
  result.FImpl := Impl;
end;

function RegEx.Match(const Data: PByte; const DataLength: integer): RegExMatch;
var
  matched: boolean;
  offset: integer;
  length: integer;
begin
  offset := -1;
  length := 0;

  matched := Impl.Match(Data, DataLength, 0, offset, length);

  result := RegExMatch.Create(matched, offset, length);
end;

function RegEx.Match(const Data: PByte; const DataLength: integer; const MatchFlags: RegExMatchFlags): RegExMatch;
var
  flags: integer;
  matched: boolean;
  offset: integer;
  length: integer;
begin
  flags := RegExMatchFlagsToPCREFlags(MatchFlags);
  offset := -1;
  length := 0;

  matched := Impl.Match(Data, DataLength, flags, offset, length);

  result := RegExMatch.Create(matched, offset, length);
end;

function RegEx.Match(const Data: TBytes; const MatchFlags: RegExMatchFlags): RegExMatch;
begin
  result := Match(@Data[0], Length(Data), MatchFlags);
end;

end.
