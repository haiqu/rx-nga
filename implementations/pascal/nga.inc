// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

type
  Cell = Longint;
 
{$define STACK_DEPTH  := 32}
{$define ADDRESSES    := 128}
{$define IMAGE_SIZE   := 524288}
{$define NUM_OPS      := 27}
{$define TOS          := data[sp]}
{$define NOS          := data[sp-1]}
{$define TOA          := address[ap]}

procedure inst_add(); external;
procedure inst_and(); external;
procedure inst_call(); external;
procedure inst_ccall(); external;
procedure inst_divmod(); external;
procedure inst_drop(); external;
procedure inst_dup(); external;
procedure inst_end(); external;
procedure inst_eq(); external;
procedure inst_fetch(); external;
procedure inst_gt(); external;
procedure inst_jump(); external;
procedure inst_lit(); external;
procedure inst_lt(); external;
procedure inst_mul(); external;
procedure inst_neq(); external;
procedure inst_nop(); external;
procedure inst_or(); external;
procedure inst_pop(); external;
procedure inst_push(); external;
procedure inst_return(); external;
procedure inst_shift(); external;
procedure inst_store(); external;
procedure inst_sub(); external;
procedure inst_swap(); external;
procedure inst_xor(); external;
procedure inst_zret(); external;
function ngaLoadImage(imageFile : PChar) : Cell; external;
procedure ngaPrepare(); external;
procedure ngaProcessOpcode(opcode : Cell); external;
procedure ngaProcessPackedOpcodes(opcode : Integer); external;
function ngaValidatePackedOpcodes(opcode : Cell) : Integer; external;

