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
:cond  "bpp-" &if::false ! &if::true ! &if::false + @ call ;
````

Next two additional forms:

````
:if   _ccall ;
:-if  push #0 eq? pop _ccall ;
````

## Interpreter & Compiler

## Compiler Core

The heart of the compiler is **comma** which stores a value into memory and increments a variable (**heap**) pointing to the next free address. **here** is a helper function that returns the address stored in **heap**.

````
:heap `8192
:here   "-n"  &heap @ ;
:comma  "n-"  here !+ &heap ! ;
````

With these we can add a couple of additional forms. **comma:opcode** is used to compile VM instructions into the current defintion. This is where those functions starting with an underscore come into play. Each wraps a single instruction. Using this we can avoid hard coding the opcodes.

````
:comma:opcode @ comma ;
````

**comma:string** is used to compile a string into the current definition.

````
:($)           "a-a"  @+ 0; comma ^($)
:comma:string  "a-"  ($) drop #0 comma ;
````

### Word Classes

Rx handles functions via handlers called *word classes*. Each of these is a function responsible for handling specific groupings of functions. The class handlers will either invoke the code in a function or compile the code needed to call them.

````
:.data &compiler @ 0; drop &_lit comma:opcode comma ;
:.word &compiler @ [ .data &_call comma:opcode ] [ call ] cond ;
:.macro call ;
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

Adding headers:

````
:newentry
  here push
    &dictionary fetch comma  "link"
    comma "xt"
    comma "class"
    comma:string  "name"
  pop &dictionary store
  ;
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
````

## Compiler

````
:compiler `0
:fin   &_ret comma:opcode &compiler off ;
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
  &test asnumber &test2 asnumber putn space putn cr cr
  &test &.macro &words newentry
:main_loop
  &compiler @ [ ok ] -if getToken
  lookup #0 -eq? [ &which @ dup d:xt @ swap d:class @ call ] [ notfound ] cond
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
:0000 `0    |dup   |.word 'dup'
:0001 |0000 |drop  |.word 'drop'
:0002 |0001 |swap  |.word 'swap'
:0003 |0002 |call  |.word 'call'
:0004 |0003 |eq?   |.word 'eq?'
:0005 |0004 |-eq?  |.word '-eq?'
:0006 |0005 |lt?   |.word 'lt?'
:0007 |0006 |gt?   |.word 'gt?'
:0008 |0007 |fetch |.word 'fetch'
:0009 |0008 |store |.word 'store'
:0010 |0009 |+     |.word '+'
:0011 |0010 |-     |.word '-'
:0012 |0011 |*     |.word '*'
:0013 |0012 |/mod  |.word '/mod'
:0014 |0013 |and   |.word 'and'
:0015 |0014 |or    |.word 'or'
:0016 |0015 |xor   |.word 'xor'
:0017 |0016 |shift |.word 'shift'
:0018 |0017 |bye   |.word 'bye'
:0019 |0018 |rot   |.word 'rot'
:0020 |0019 |-rot  |.word '-rot'
:0021 |0020 |tuck  |.word 'tuck'
:0022 |0021 |over  |.word 'over'
:0023 |0022 |nip   |.word 'nip'
:0024 |0023 |dup-pair  |.word 'dup-pair'
:0025 |0024 |drop-pair |.word 'drop-pair'
:0026 |0025 |/      |.word '/'
:0027 |0026 |mod    |.word 'mod'
:0028 |0027 |negate |.word 'negate'
:0029 |0028 |not    |.word 'not'
:0030 |0029 |@+     |.word '@+'
:0031 |0030 |!+     |.word '!+'
:0032 |0031 |on     |.word 'on'
:0033 |0032 |off     |.word 'off'
:0034 |0033 |compare |.word 'compare'
:0035 |0034 |cond    |.word 'cond'
:0036 |0035 |if      |.word 'if'
:0037 |0036 |-if     |.word '-if'

:0100  |0036 |heap  |.data  'heap'
:0101  |0100 |comma |.word  ','
:0103  |0101 |]]    |.word  ']]'
:0104  |0103 |[[    |.macro '[['
:0105  |0104 |@     |.word 'fetch'
:0106  |0105 |here  |.word 'here'
:0107  |0106 |call  |.word 'call'
:0108  |0107 |fin   |.macro ';'

:0900  |0108 |putc  |.word 'putc'
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

````
:asn:mod `0
:acc `0
:char>digit $0 - ;

:(convert)
    dup fetch 0; char>digit &acc fetch #10 * +
    &acc store #1 +
  ^(convert)

:asnumber:negative?  "p-p"
  #1 &asn:mod store
  #0 &acc store
  dup fetch $- eq? [ #-1 &asn:mod store #1 + ] if ;

:asnumber "p-n"
  asnumber:negative? (convert) drop &acc fetch &asn:mod fetch * ;

:test '9804'
:test2 '-4011'

````
