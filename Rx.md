The core Nga instruction set consists of 27 instructions. Rx begins by 

assigning each to a separate function. These are not intended for direct 

use.

````
:_nop     `0 ;
:_lit     `1 ;
:_dup     `2 ;
:_drop    `3 ;
:_swap    `4 ;
:_push    `5 ;
:_pop     `6 ;
:_jump    `7 ;
:_call    `8 ;
:_ccall   `9 ;
:_ret     `10 ;
:_eq      `11 ;
:_neq     `12 ;
:_lt      `13 ;
:_gt      `14 ;
:_fetch   `15 ;
:_store   `16 ;
:_add     `17 ;
:_sub     `18 ;
:_mul     `19 ;
:_divmod  `20 ;
:_and     `21 ;
:_or      `22 ;
:_xor     `23 ;
:_shift   `24 ;
:_zret    `25 ;
:_end     `26 ;
````

Wrap the instructions into actual functions intended for use. Naming here is 

a blend of Forth, Retro, and Parable.

````
:+     "nn-n"   _add ;
:-     "nn-n"   _sub ;
:*     "nn-n"   _mul ;
:/mod  "nn-mq"  _divmod ;
:eq?   "nn-f"   _eq ;
:-eq?  "nn-f"   _neq ;
:lt?   "nn-f"   _lt ;
:gt?   "nn-f"   _gt ;
:and   "nn-n"   _and ;
:or    "nn-n"   _or ;
:xor   "nn-n"   _xor ;
:shift "nn-n"   _shift ;
:bye   "-"      _end ;
:@     "a-n"    _fetch ;
:!     "na-"    _store ;
:dup   "n-nn"   _dup ;
:drop  "nx-n"   _drop ;
:swap  "nx-xn"  _swap ;
````

Additional functions from Retro:

````
:@+ dup #1 + swap @ ;
:over push dup pop swap ;
:not #-1 xor ;
:on #-1 swap ! ;
:off #0 swap ! ;
:/ /mod swap drop ;
:mod /mod drop ;
:negate #-1 * ;
:do #-1 - push ;
:!+ dup #1 + push ! pop ;
````

String comparisons

````
:a$ 'word'

:count @+ 0; drop ^count
:getLength dup count #1 - swap - ;

:getSet @ swap @ ;
:nextSet #1 + swap #1 + ;

:flag      `0
:maxlength `0

:compare_loop
  over over
  getSet eq? &flag !
  nextSet
  &maxlength @ #1 - &maxlength !

  "Exit conditions"
  &maxlength @ 0; drop
  &flag @ 0; drop
  ^compare_loop

:compare
  #0 &flag !
  dup getLength &maxlength !
  compare_loop drop drop
  &flag @
  ;

:xtest #-1 eq? [ #5 ] _ccall #6 ;

:main
  token
  &TIB puts
  &a$ &TIB compare
  xtest
$a
 words
$b
  _end

:words
  &dictionary @
:w1
  0;
  dup #3 + puts
  @
^w1

````

----

````
:putc `100 ;
:putn `101 ;
:puts `102 ;
:putsc `103 ;
:cls `104 ;
:getc `110 ;
:getn `111 ;
:gets `112 ;
:fs.open `118 ;
:fs.close `119 ;
:fs.read `120 ;
:fs.write `121 ;
:fs.tell `122 ;
:fs.seek `123 ;
:fs.size `124 ;
:fs.delete `125 ;

:TIB `3000
:token #32 #3 &TIB gets ;
````

The dictionary is a linked list.

| field | holds                                       |
| ----- | ------------------------------------------- |
| link  | link to the previous entry, 0 if last entry |
| xt    | link to start of the function               |
| class | link to the class handler function          |
| name  | zero terminated string                      |

````
:.word _call ;

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

:dictionary |0012
````

