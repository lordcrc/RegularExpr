unit RegularExpr.Detail;

interface

uses
  System.SysUtils, RegularExpressionsAPI;

const
  MAX_SUBEXPRESSIONS = 99;
  WORKSPACE_SIZE = 100;

type
  IMatch = interface
    function GetMatched: boolean;
    function GetLength: integer;
    function GetOffset: integer;

    property Matched: boolean read GetMatched;
    property Offset: integer read GetOffset;
    property Length: integer read GetLength;
  end;

  IRegExpr = interface
    function Match(const Data: PByte; const DataLength: integer; const Flags: integer; out MatchOffset: integer; out MatchLength: integer): boolean;
  end;

  TRegExprImpl = class(TInterfacedObject, IRegExpr)
  strict private
    FRe: PPCRE;
    FReExtra: PPCREExtra;
    FOpts: integer;
    FOffsets: array[0..((MAX_SUBEXPRESSIONS + 1) * 3)] of Integer;
//    FWorkspace: array[0..WORKSPACE_SIZE-1] of Integer;
  private
    property Re: PPCRE read FRe;
    property ReExtra: PPCREExtra read FReExtra;
    property Opts: integer read FOpts;
  public
    constructor Create(const Pattern: string; const Options: integer);
    destructor Destroy; override;

    function Match(const Data: PByte; const DataLength: integer; const Flags: integer; out MatchOffset: integer; out MatchLength: integer): boolean;
    procedure Study;
  end;

implementation

uses
  WinAPI.Windows;

var
  PCRECharTable: MarshaledAString;


procedure CheckPcreResult(const ErrorCode: integer);
var
  s: string;
begin
  if (ErrorCode >= -1) then
    exit;

  case ErrorCode of
    PCRE_ERROR_NOMATCH: s := 'PCRE_ERROR_NOMATCH';
    PCRE_ERROR_NULL: s := 'PCRE_ERROR_NULL';
    PCRE_ERROR_BADOPTION: s := 'PCRE_ERROR_BADOPTION';
    PCRE_ERROR_BADMAGIC: s := 'PCRE_ERROR_BADMAGIC';
    PCRE_ERROR_UNKNOWN_NODE: s := 'PCRE_ERROR_UNKNOWN_NODE';
    PCRE_ERROR_NOMEMORY: s := 'PCRE_ERROR_NOMEMORY';
    PCRE_ERROR_NOSUBSTRING: s := 'PCRE_ERROR_NOSUBSTRING';
    PCRE_ERROR_MATCHLIMIT: s := 'PCRE_ERROR_MATCHLIMIT';
    PCRE_ERROR_CALLOUT: s := 'PCRE_ERROR_CALLOUT';
    PCRE_ERROR_BADUTF8: s := 'PCRE_ERROR_BADUTF8';
    PCRE_ERROR_BADUTF8_OFFSET: s := 'PCRE_ERROR_BADUTF8_OFFSET';
    PCRE_ERROR_PARTIAL: s := 'PCRE_ERROR_PARTIAL';
    PCRE_ERROR_BADPARTIAL: s := 'PCRE_ERROR_BADPARTIAL';
    PCRE_ERROR_INTERNAL: s := 'PCRE_ERROR_INTERNAL';
    PCRE_ERROR_BADCOUNT: s := 'PCRE_ERROR_BADCOUNT';
    PCRE_ERROR_DFA_UITEM: s := 'PCRE_ERROR_DFA_UITEM';
    PCRE_ERROR_DFA_UCOND: s := 'PCRE_ERROR_DFA_UCOND';
    PCRE_ERROR_DFA_UMLIMIT: s := 'PCRE_ERROR_DFA_UMLIMIT';
    PCRE_ERROR_DFA_WSSIZE: s := 'PCRE_ERROR_DFA_WSSIZE';
    PCRE_ERROR_DFA_RECURSE: s := 'PCRE_ERROR_DFA_RECURSE';
    PCRE_ERROR_RECURSIONLIMIT: s := 'PCRE_ERROR_RECURSIONLIMIT';
    PCRE_ERROR_NULLWSLIMIT: s := 'PCRE_ERROR_NULLWSLIMIT';
    PCRE_ERROR_BADNEWLINE: s := 'PCRE_ERROR_BADNEWLINE';
    PCRE_ERROR_BADOFFSET: s := 'PCRE_ERROR_BADOFFSET';
    PCRE_ERROR_SHORTUTF8: s := 'PCRE_ERROR_SHORTUTF8';
    PCRE_ERROR_RECURSELOOP: s := 'PCRE_ERROR_RECURSELOOP';
    PCRE_ERROR_JIT_STACKLIMIT: s := 'PCRE_ERROR_JIT_STACKLIMIT';
    PCRE_ERROR_BADMODE: s := 'PCRE_ERROR_BADMODE';
    PCRE_ERROR_BADENDIANNESS: s := 'PCRE_ERROR_BADENDIANNESS';
    PCRE_ERROR_DFA_BADRESTART: s := 'PCRE_ERROR_DFA_BADRESTART';
    PCRE_ERROR_JIT_BADOPTION: s := 'PCRE_ERROR_JIT_BADOPTION';
    PCRE_ERROR_BADLENGTH: s := 'PCRE_ERROR_BADLENGTH';
    PCRE_ERROR_UNSET: s := 'PCRE_ERROR_UNSET';
  else
    s := 'Unknown error: ' + IntToStr(ErrorCode);
  end;

  raise Exception.Create(s);
end;

function StrToASCIIZ(const Str: string): TBytes;
var
  flags: cardinal;
  byteCount: integer;
  conversionError: LongBool;
begin
  result := nil;
  if (Str = '') then
    exit;

{$IFDEF MSWINDOWS}
  flags := WC_NO_BEST_FIT_CHARS;
{$ELSE}
  flags := WC_NO_BEST_FIT_CHARS or WC_ERR_INVALID_CHARS;
{$ENDIF}

  conversionError := False;

  byteCount := LocaleCharsFromUnicode(TEncoding.ASCII.CodePage, flags, @Str[1], Length(Str), nil, 0, nil, nil);
  if (Length(Str) > 0) and (byteCount = 0) then
    raise EConvertError.Create('String is not valid ASCII');

  SetLength(result, byteCount + 1);

  byteCount := LocaleCharsFromUnicode(TEncoding.ASCII.CodePage, flags, @Str[1], Length(Str), PAnsiChar(@result[0]), Length(result) - 1, nil, @conversionError);

  if (byteCount <> (Length(result) - 1)) then
    raise EConvertError.Create('String is not valid ASCII');

  if (conversionError) then
    raise EConvertError.Create('String is not valid ASCII');
end;

{ TRegExpr }

constructor TRegExprImpl.Create(const Pattern: string; const Options: integer);
var
  r: PPCRE;
  p: TBytes;
  errorMsg: MarshaledAString;
  errorOffset: integer;
begin
  inherited Create;

  errorMsg := nil;
  errorOffset := -1;

  p := StrToASCIIZ(Pattern);
  r := pcre_compile(MarshaledAString(p), Options, @errorMsg, @errorOffset, nil); //PCRECharTable);

  if (r = nil) then
    raise EArgumentException.CreateFmt('Error in pattern: %s (offset %d)', [errorMsg, errorOffset]);

  FRe := r;
  FReExtra := nil;
  FOpts := Options;

  // jitting is not available, so just study always since it's fast
  Study;
end;

destructor TRegExprImpl.Destroy;
begin
  if (Re <> nil) then
    pcre_dispose(Re, nil, nil);
  if (ReExtra <> nil) then
    pcre_free_study(ReExtra);

  inherited;
end;

function TRegExprImpl.Match(const Data: PByte; const DataLength, Flags: integer; out MatchOffset,
  MatchLength: integer): boolean;
var
  opts: integer;
  res: integer;
begin
//  FillChar(FWorkspace, SizeOf(FWorkspace), 0);
//  FillChar(FOffsets, SizeOf(FOffsets), 0);
  opts := Flags or PCRE_NOTEMPTY;
  res := pcre_exec(Re, ReExtra, MarshaledAString(Data), DataLength, 0, opts, @FOffsets, High(FOffsets));
  CheckPcreResult(res);
  result := res > 0;
  if result then
  begin
    MatchOffset := FOffsets[0];
    MatchLength := FOffsets[1] - FOffsets[0];
  end;
end;

procedure TRegExprImpl.Study;
var
  errorMsg: MarshaledAString;
begin
  errorMsg := nil;
  FReExtra := pcre_study(Re, 0, @errorMsg);
  if (ReExtra = nil) and (errorMsg <> nil) then
    raise EInvalidOpException.CreateFmt('Error studying pattern: %s', [errorMsg]);
end;

procedure InitTables;
begin
  PCRECharTable := pcre_maketables();
end;

initialization
  InitTables;
finalization
  pcre_dispose(nil, nil, PCRECharTable);
end.
