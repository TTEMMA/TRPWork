unit SwapBytes;

{
 Unit for Read\Write Big-Endian Value
 By TTEMMA
}

interface

uses System.Classes;

Function Swap16(Value:Word):Word;
Function Swap32(Value:LongWord):LongWord;
Function Swap64(Value: Int64):Int64;
Procedure Write_BE_Value(Stream:TStream;Value:LongWord);overload;
Procedure Write_BE_Value(Stream:TStream;Value:Word);overload;
Procedure Write_BE_Value(Stream:TStream;Value:Int64);overload;
Function Read_Byte(Stream:TStream):Byte;
Function Read_BE_Word(Stream:TStream):Word;
Function Read_BE_LongWord(Stream:TStream):LongWord;
Function Read_BE_Int64(Stream:TStream):Int64;

implementation

Function Swap16(Value:Word):Word;
asm
  xchg al,ah
end;

Function Swap32(Value:LongWord):LongWord;
asm
  bswap eax
end;

Function Swap64(Value: Int64):Int64;
asm
  mov edx, [esp+8]
  bswap edx
  mov eax, [esp+12]
  bswap eax
end;

Procedure Write_BE_Value(Stream:TStream;Value:LongWord);overload;
var
  TEMP:LongWord;
begin
  Temp := Swap32(Value);
  Stream.Write(Temp,4);
end;

Procedure Write_BE_Value(Stream:TStream;Value:Word);overload;
var
  TEMP:Word;
begin
  Temp := Swap16(Value);
  Stream.Write(Temp,2);
end;

Procedure Write_BE_Value(Stream:TStream;Value:Int64);overload;
var
  TEMP:Int64;
begin
  Temp := Swap64(Value);
  Stream.Write(Temp,8);
end;

Function Read_Byte(Stream:TStream):Byte;
begin
  Stream.Read(Result,1);
end;

Function Read_BE_Word(Stream:TStream):Word;
begin
  Stream.Read(Result,2);
  Result := Swap16(Result);
end;

Function Read_BE_LongWord(Stream:TStream):LongWord;
begin
  Stream.Read(Result,4);
  Result := Swap32(Result);
end;

Function Read_BE_Int64(Stream:TStream):Int64;
begin
  Stream.Read(Result,8);
  Result := Swap64(Result);
end;

end.
