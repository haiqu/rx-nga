# Rx Core

The *Rx Core* is the *retro experimental core*, a proto-Forth environment. Past incarnations of this have proved very successful, serving as both a basis for Retro and testbed for interesting concepts. *Rx* (as it will be called from this point on) is *not* intended to be used widely. Expect frequent breakages and bugs as new things are added, tested, and removed. It is my hope that this will prove beneficial in building the next generations of Retro and Parable.

As with all of my recent work, I'm attempting to develop this in  more literate style, intermixing commentary and keeping related things together. The sources are extracted with the *unu* tool, preprocessed by *nuance*, and then assembled using *naje*. On my Linode, this normally takes less than 0.01s.

## Nga Instruction Set

The core Nga instruction set consists of 27 instructions. Rx begins by assigning each to a separate function. These are not intended for direct use; in Rx the compiler will fetch the opcode values to use from these functions when compiling. Some of them will also be wrapped in normal functions later.

````
:_nop     `0 ;   :_lit     `1 ;   :_dup     `2 ;   :_drop    `3 ;
:_swap    `4 ;   :_push    `5 ;   :_pop     `6 ;   :_jump    `7 ;
:_call    `8 ;   :_ccall   `9 ;   :_ret     `10 ;  :_eq      `11 ;
:_neq     `12 ;  :_lt      `13 ;  :_gt      `14 ;  :_fetch   `15 ;
:_store   `16 ;  :_add     `17 ;  :_sub     `18 ;  :_mul     `19 ;
:_divmod  `20 ;  :_and     `21 ;  :_or      `22 ;  :_xor     `23 ;
:_shift   `24 ;  :_zret    `25 ;  :_end     `26 ;
````

## Essentials

### Primitives

Wrap the instructions into actual functions intended for use. Naming here is a blend of Forth, Retro, and Parable.

````
:dup   "n-nn"   _dup ;
:drop  "nx-n"   _drop ;
:swap  "nx-xn"  _swap ;
:call  "p-"     _call ;
:eq?   "nn-f"   _eq ;
:-eq?  "nn-f"   _neq ;
:lt?   "nn-f"   _lt ;
:gt?   "nn-f"   _gt ;
:fetch "p-n"    _fetch ;
:store "np-"    _store ;
:+     "nn-n"   _add ;
:-     "nn-n"   _sub ;
:*     "nn-n"   _mul ;
:/mod  "nn-mq"  _divmod ;
:and   "nn-n"   _and ;
:or    "nn-n"   _or ;
:xor   "nn-n"   _xor ;
:shift "nn-n"   _shift ;
:bye   "-"      _end ;
````

### Stack Shufflers

````
:rot       "xyz-yzx"  push swap pop swap ;
:-rot      "xyz-xzy"  swap push swap pop ;
:tuck      "xy-yxy"   dup -rot ;
:over      "xy-xyx"   push dup pop swap ;
:nip       "xy-y"     swap drop ;
:dup-pair  "xy-xyxy"  over over ;
:drop-pair "xy-"      drop drop ;
````

### Math & Logic

````
:/       "nq-d" /mod swap drop ;
:mod     "nq-r" /mod drop ;
:negate  "n-n"  #-1 * ;
:not     "n-n"  #-1 xor ;
````

### Memory

````
:@+     dup #1 + swap @ ;
:!+     dup #1 + push ! pop ;
:on     #-1 swap ! ;
:off    #0 swap ! ;
````

````
:@     "a-n"    _fetch ;
:!     "na-"    _store ;
````

Additional functions from Retro:

````
:do     _call ;
````

String comparisons

````
:count @+ 0; drop ^count
:getLength dup count #1 - swap - ;

:compare::flag `0
:compare::maxlength `0

:getSet @ swap @ ;
:nextSet #1 + swap #1 + ;

:compare_loop
  dup-pair
  getSet eq? &compare::flag ! nextSet
  &compare::maxlength @ #1 - &compare::maxlength !

  "Exit conditions"
  &compare::maxlength @ &compare::flag @ and 0; drop
  ^compare_loop

:compare
  #0 &compare::flag !
  dup getLength &compare::maxlength !
  compare_loop drop drop
  &compare::flag @
  ;
````

### Conditionals

Implement **cond**, a conditional combinator which will execute one of two functions, depending on the state of a flag. We take advantage of a little hack here. Store the pointers into a jump table with two fields, and use the flag as the index. Default to the *false* entry, since a *true* flag is -1.

````
:if::true  `0
:if::false `0
:cond  "bpp-" &if::false ! &if::true ! &if::false + @ _call ;
````

Next two additional forms:

````
:if   _ccall ;
:-if  push #0 eq? pop _ccall ;
````

## Interpreter

### Word Classes

````
:.data &compiler @ 0; drop &_lit opcode comma ;
:.word &compiler @ [ &_lit opcode comma &_call opcode ] [ _call ] cond ;
:.macro _call ;
````

### Dictionary

The dictionary is a simple linked list, with the following format.

| field | holds                                       |
| ----- | ------------------------------------------- |
| link  | link to the previous entry, 0 if last entry |
| xt    | link to start of the function               |
| class | link to the class handler function          |
| name  | zero terminated string                      |

The initial dictionary is constructed at the end of this file. It'll take a form like this:

    :0000  `0    |+     |.word '+'
    :0001  |0000 |-     |.word '-'

Each label will contain a reference to the prior one, the internal function name, its class, and a string indicating the name to expose to the Rx interpreter.

Rx will store the pointer to the most recent entry in a variable called **dictionary**. For simplicity, we just assign the last entry an arbitrary label of 9999.

````
:dictionary |9999
````

Rx provides accessor functions for each field. Since the number of fields (or their ordering) may change over time, using these reduces the number of places where field offsets are hard coded.

````
:d:link  "d-p"  #0 + ;
:d:xt    "d-p"  #1 + ;
:d:class "d-p"  #2 + ;
:d:name  "d-p"  #3 + ;
````

### Dictionary Search

````
:which `0

:find
  #0 &which !
  &dictionary @
:find_next
  0;
  dup #3 + &TIB compare [ dup &which ! ] if
  @
^find_next

:lookup find &which fetch ;
````

````
:notfound $? putc ;

lookup #0 -eq? [ &which @ dup d:xt @ swap d:class @ _call ] [ notfound ] cond
````

## Compiler

````
:opcode @ comma ;
:heap `8192
:compiler `0
:here &heap @ ;
:comma here !+ &heap ! ;
:fin   &_ret opcode &compiler off ;
:]]   &compiler on ;
:[[   &compiler off ;
````


````
:startup
  'rx-2016.09'

:okmsg
  'ok'

:ok &okmsg puts space ;

:main
  &startup puts cr cr words cr cr
:main_loop
  ok getToken
  find
  &which @ #0 -eq? [ &which @ dup #1 + @ swap #2 + @ _call ] [ $? putc ] cond
  &compiler @ [ cr ] -if
  ^main_loop

:words
  &dictionary @
:w1
  0;
  dup #3 + puts space
  @
^w1

````

## Dictionary

The dictionary is a linked list.


````
:0000  `0    |+     |.word '+'
:0001  |0000 |-     |.word '-'
:0002  |0001 |*     |.word '*'
:0003  |0002 |/mod  |.word '/mod'
:0004  |0003 |eq?   |.word 'eq?'
:0005  |0004 |-eq?  |.word '-eq?'
:0006  |0005 |lt?   |.word 'lt?'
:0007  |0006 |gt?   |.word 'gt?'
:0008  |0007 |and   |.word 'and'
:0009  |0008 |or    |.word 'or'
:0010  |0009 |xor   |.word 'xor'
:0011  |0010 |shift |.word 'shift'
:0012  |0011 |bye   |.word 'bye'

:0100  |0012 |heap  |.data  'heap'
:0101  |0100 |comma |.word  ','
:0103  |0101 |]]    |.word  ']]'
:0104  |0103 |[[    |.macro '[['
:0105  |0104 |@     |.word 'fetch'
:0106  |0105 |here  |.word 'here'
:0107  |0106 |do    |.word 'do'
:0108  |0107 |fin   |.macro ';'

:0200  |0108 |dup   |.word 'dup'
:0201  |0200 |drop  |.word 'drop'
:0202  |0201 |swap  |.word 'swap'
:0203  |0202 |over  |.word 'over'

:0900  |0203 |putc  |.word 'putc'
:0901  |0900 |putn  |.word 'putn'
:0902  |0901 |puts  |.word 'puts'
:0903  |0902 |cls   |.word 'cls'
:0904  |0903 |getc  |.word 'getc'
:0905  |0904 |getn  |.word 'getn'

:9999  |0905 |words |.word 'words'
````

## Ngura I/O

Rx does not attempt to become a complete Forth. As with Nga, I/O is generally left undefined. For testing purposes it is helpful though, so the following wraps the reference *Ngura* I/O instructions into functions.

````
:putc `100 ;
:putn `101 ;
:puts `102 ;
:putsc `103 ;
:cls `104 ;
:getc `110 ;
:getn #32 `111 ;
:gets `112 ;
:fs.open `118 ;
:fs.close `119 ;
:fs.read `120 ;
:fs.write `121 ;
:fs.tell `122 ;
:fs.seek `123 ;
:fs.size `124 ;
:fs.delete `125 ;
````

With this, we can build in some interactivity around a terminal I/O model.

````
:cr #10 putc ;
:space #32 putc ;

:getToken #32 #2048 &TIB gets ;
:TIB `4096
````
