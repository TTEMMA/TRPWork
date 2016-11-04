program TRPWork;

{
 TROPHY.TRP Sony PlayStation Vita Extract\Repack v1.0
 By TTEMMA, 2016, Russian Studio Video 7
 You can write me, my email : TTEMMA3@gmail.com
 Please, write my Nickname in your project, if you use my program\source code :)
}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.Classes, System.Hash, SwapBytes;

Type
  TTRP_Entry = Record
    Name      : AnsiString;
    Offset    : Int64;
    Size      : Int64;
    File_Type : Int64;//???; 0 = Png, 1 = SFM
    Unk       : Int64;
  End;
  TTRP = record
    Version  : LongWord;//???
    TRP_Size : Int64;
    Count    : LongWord;
    Info_Off : LongWord;
    Dummy    : LongWord;
    Hash     : TBytes; // SHA-1 Hash
    Entry    : array of TTRP_Entry;

    const
    Magic : LongWord = $DCA24D00;
  end;

Function CalculateSHA1FromStream(Stream : TStream; Buffer_Size : Integer = 16384):TBytes;
var
  SHAHash : THashSha1;
  Read    : Integer;
  Buffer  : array of Byte;
begin
  Stream.Position := 0;
  SHAHash := THashSHA1.Create;
  SetLength(Buffer,Buffer_Size);

  repeat
    Read := Stream.Read(Buffer[0],Buffer_Size);
    SHAHash.Update(Buffer,Read);
  until (read <> Buffer_Size);

  Result := SHAHash.HashAsBytes;
end;

function ExtractOnlyFileName(const FileName: string): string;
begin
  result:=StringReplace(ExtractFileName(FileName),ExtractFileExt(FileName),'',[]);
end;

Procedure SeekValue(Stream:TStream;Value:Integer);
const null : Byte = $00;
begin
  while Stream.Position mod Value <> 00 do
    Stream.Write(null,1);
end;

Function ReadAnsiStringStream(Stream:TStream;Size:Integer):AnsiString;
var
  b:byte;
  i:integer;
begin
  Result:='';
  for I := 1 to Size do
    begin
      Stream.Read(b,1);
      if B>0 then
        Result:=Result + AnsiChar(B);
    end;
end;

Procedure WriteNull_Size(Stream:TStream;Size:Integer);
const null : Byte = $00;
var I:Integer;
begin
  for I := 1 to Size do
    Stream.Write(null,1);
end;

Procedure Read_TRP_Header(var TRP:TTRP; Stream:TStream);
var
  I : Integer;
begin
  if (Read_BE_LongWord(Stream) <> TTRP.Magic) then
    raise Exception.Create('ERROR_0: Bad TRP Magic');

  TRP.Version := Read_BE_LongWord(Stream);
  if TRP.Version <> 2 then
    raise Exception.Create('ERROR_1: Version TRP not support');

  TRP.TRP_Size := Read_BE_Int64(Stream);
  TRP.Count    := Read_BE_LongWord(Stream);
  TRP.Info_Off := Read_BE_LongWord(Stream);

  Stream.Position := TRP.Info_Off;
  SetLength(TRP.Entry,TRP.Count);

  for I := 0 to TRP.Count - 1 do
    with TRP.Entry[i] do
      begin
        Name      := ReadAnsiStringStream(Stream,$20);
        Offset    := Read_BE_Int64(Stream);
        Size      := Read_BE_Int64(Stream);
        File_Type := Read_BE_Int64(Stream);
        Unk       := Read_BE_Int64(Stream);
      end;
  Stream.Position := 0;
end;

Procedure ExtractTRP(FileName:String);
var
  TRP : TTRP;
  Stream_TRP, Stream_Out : TFileStream;
  I : Integer;
  Dir : String;
begin
  Writeln('Extract: ' + ExtractFileName(FileName));

  Dir := ExtractFilePath(FileName) + ExtractOnlyFileName(FileName) + '\';

  Stream_TRP := TFileStream.Create(FileName,fmopenread);

  Read_TRP_Header(TRP,Stream_TRP);

  if DirectoryExists(dir) then
    RemoveDir(Dir);

  CreateDir(Dir);

  for I := 0 to TRP.Count-1 do
    begin
      Stream_TRP.Position := TRP.Entry[i].Offset;
      Stream_Out := TFileStream.Create(Dir+TRP.Entry[i].Name,fmcreate);
      Stream_Out.CopyFrom(Stream_TRP,TRP.Entry[i].Size);
      Stream_Out.Free;
    end;

  Stream_TRP.Position := 0;
  Stream_Out := TFileStream.Create(ExtractFilePath(FileName) + ExtractOnlyFileName(FileName) + '.index',fmcreate);
  Stream_Out.CopyFrom(Stream_TRP,TRP.Entry[0].Offset);
  Stream_Out.Free;

  Stream_TRP.Free;
end;

Procedure Repack_Trp(FileName:String);
var
  TRP : TTRP;
  Stream_TRP, Stream_Out : TFileStream;
  I : Integer;
  Dir : String;
begin
  Writeln('Repack: ' + ExtractFileName(FileName));

  Dir := ExtractFilePath(FileName) + ExtractOnlyFileName(FileName) + '\';

  Stream_Out := TFileStream.Create(FileName,fmopenread);
  Read_TRP_Header(TRP,Stream_Out);

  Stream_TRP := TFileStream.Create(ExtractFilePath(FileName) + ExtractOnlyFileName(FileName) + '.TRP',fmcreate);
  Stream_TRP.CopyFrom(Stream_Out,Stream_Out.Size);
  Stream_Out.Free;

  {Delete old hash}
  Stream_TRP.Position := $1C;
  WriteNull_Size(Stream_TRP,20);
  Stream_TRP.Position := Stream_TRP.Size;

  {Replace Files}
  for I := 0 to TRP.Count - 1 do
    with TRP.Entry[i] do
     begin
       Stream_Out := TFileStream.Create(Dir + Name,fmopenread);
       Offset := Stream_TRP.Position;
       Size   := Stream_Out.Size;

       Stream_TRP.CopyFrom(Stream_Out,Stream_Out.Size);
       Stream_Out.Free;
       SeekValue(Stream_TRP,$10);
     end;

  {Update Files Info}
  Stream_TRP.Position := 8;
  Write_BE_Value(Stream_TRP,Stream_TRP.Size);
  Stream_TRP.Position := TRP.Info_Off;
  for I := 0 to TRP.Count - 1 do
    With TRP.Entry[i] do
      begin
        Stream_TRP.Position := Stream_TRP.Position + $20;
        Write_BE_Value(Stream_TRP,Offset);
        Write_BE_Value(Stream_TRP,Size);
        Stream_TRP.Position := Stream_TRP.Position + $10;
      end;

  {Calculate new hash}
  TRP.Hash := CalculateSHA1FromStream(Stream_TRP);
  Stream_TRP.Position := $1C;
  Stream_TRP.Write(TRP.Hash,$14);
  Stream_TRP.Free;
end;

var
  I:Integer;

begin
  Writeln('TROPHY.TRP PlayStation Vita Extract\Repack v1.0' + #10 +
          'By TTEMMA, 2016' + #10 +
          'ttemma3@gmail.com'+#10);

  if ParamCount = 0 then
    begin
      Writeln('Using:'+#10+
              '      extract: TRPwork.exe <filename.trp>'+#10+
              '      repack : TRPwork.exe <filename.index>');
      readln;
      Exit;
    end;

  for I := 1 to ParamCount do
    begin
      if String.UpperCase(ExtractFileExt(ParamStr(I))) = '.TRP' then
        ExtractTRP(ParamStr(I));
      if String.UpperCase(ExtractFileExt(ParamStr(i))) = '.INDEX' then
        Repack_Trp(ParamStr(I));
    end;
end.

