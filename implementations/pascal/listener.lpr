// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

program listener;

{$mode objfpc}{$H+}
{$macro on}

uses
  SysUtils, bridge in 'bridge.pas', nga in 'nga.pas', vt100 in 'vt100.pas';

{$define ED_BUFFER:=327680}
{$define ED_BLOCKS:=384}
{$define TIB := 1471}
{$include 'termios.inc'}
{$include 'nga.inc'}


//implementation

procedure read_blocks();
var
  f : THandle;
  slot : Cell;
  i : Integer;
begin
  f := FileOpen('retro.blocks', fmOpenRead);
  if f <> THandle(-1) then
  begin
    for i := ED_BUFFER to IMAGE_SIZE - 1 do
      begin
        FileRead(f, slot, sizeof(Cell));
        memory[i] := slot;
    end;
    FileClose(f);
  end;
end;

procedure dump_stack();
var
  i : Cell;
begin
  write('Stack: ');
  for i := 1 to sp do
    if i = sp then
      write(format('< %d >', [data[i]]))
    else
      write(format('%d ', [data[i]]));
  writeln();
end;

procedure prompt();
begin
  if memory[Compiler] = 0 then
    write(LineEnding, 'ok  ');
end;


// ********************************************************
//  Main program
// ********************************************************
var
  input : array[0..1023] of Char;
  i, n : Cell;
begin
  nga.ngaPrepare();
  n := nga.ngaLoadImage('ngaImage');
    exit();
  update_rx();
  writeln(format('RETRO 12 (rx-%d.%d)', [memory[4] div 100, memory[4] mod 100]));
  //read_blocks();
  term_setup();
  writeln(format('%d MAX, TIB @ %d, Heap @ %d', [IMAGE_SIZE, TIB, Heap]));
  writeln();
  while true do
  begin
    prompt();
    Dictionary := memory[2];
    read_token(input);
    if strcomp(input, 'bye') = 0 then
    begin
      term_cleanup();
      exit();
    end
    else if strcomp(input, 'words') = 0 then
    begin
      i := Dictionary;
      while i <> 0 do
      begin
        string_extract(d_name(i));
        write(format('%s  ', [string_data]));
        i := memory[i];
      end;
      writeln(format('(%d entries)', [d_count_entries(Dictionary)]));
    end
    else if strcomp(input, '.p') = 0 then
      writeln(format('__%s__', [string_extract(data[sp])]))
    else if strcomp(input, '.s') = 0 then
      dump_stack()
    else
      evaluate(input);
  end;
  term_cleanup();
end.

