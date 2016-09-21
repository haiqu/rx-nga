# Rx: a minimal Forth for Nga

*Rx* (*retro experimental*) is a proto-Forth environment. Past incarnations of this have proved very successful, serving as both a basis for Retro and testbed for interesting concepts. *Rx* is *not* intended to be used widely at this time. Expect frequent breakages and bugs as new things are added, tested, and removed. It is my hope that this will prove beneficial in building new generations of Retro and Parable.

As with all of my recent work, I'm attempting to develop this in  more literate style, intermixing commentary and keeping related things together. The sources are extracted with the *unu* tool, preprocessed by *nuance*, and then assembled using *naje*. On my Linode, this normally takes less than 0.01s.

As with Retro and Parable, Rx will make extensive use of quotations for logic and flow control, and prefixes for controlling compilation. The general syntax is a bit more Forth-like at this point:

    :name . . . definition . . . ;

Note that **:** is a prefix that creates a new named entry and starts the compiler, **;** is a compiler macro that compiles a *return* instruction and stops the compiler.

Broadly speaking, this is a reimplementation of the approach used in Retro 11, but without the historical baggage. It's trying to take some lessons learned, and provide a tighter, cleaner core language suitable for expansion into something useful. The current plan is for a core language (sans I/O) of around 80 functions.

## Mapping

All code built with the Nga toolchain starts with a jump to the main entry point. With cell packing, this takes two cells. We can take advantage of this knowledge to place a couple of variables at the start so they can be easily identified and interfaced with external tools. This is important as Nga allows for a variety of I/O models to be implemented and I don't want to tie Rx into any one specific model.

Here's the initial memory map:

| Offset | Contains                    |
| ====== | =========================== |
| 0      | _lit / _call / _nop / _nop  |
| 1      | Pointer to main entry point |
| 2      | Dictionary                  |
| 3      | Heap                        |

Naje, the Nga assembler, compiles the initial instructions automatically. The two variables need to be declared next, so:

````
:Dictionary |9999
:Heap       `8192
````

Both of these are pointers. **Dictionary** points to the most recent dictionary entry. (See the *Dictionary* section at the end of this file.) **Heap** points to the next free memory address. For now this is hard coded to an address well beyond the end of the Rx kernel. It'll be fine tuned as development progresses. See the *Interpreter &amp; Compiler* section for more on this.

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

## Primitives

Here I wrap the instructions into actual functions intended for use. Naming conventions here are derived from Retro and Parable.

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

## Stack Shufflers

````
:tuck      "xy-yxy"   dup push swap pop ;
:over      "xy-xyx"   push dup pop swap ;
:nip       "xy-y"     swap drop ;
:dup-pair  "xy-xyxy"  over over ;
:drop-pair "xy-"      drop drop ;
````

## Math & Logic

````
:/       "nq-d" /mod swap drop ;
:mod     "nq-r" /mod drop ;
:negate  "n-n"  #-1 * ;
:not     "n-n"  #-1 xor ;
````

## Memory

````
:@+     "a-An"  dup #1 + swap fetch ;
:!+     "na-A"  dup #1 + push store pop ;
````

Additional functions from Retro:

## Strings

````
:count @+ 0; drop ^count
:str:length dup count #1 - swap - ;

:compare::flag `0
:compare::maxlength `0

:getSet fetch swap fetch ;
:nextSet #1 + swap #1 + ;

:compare_loop
  dup-pair
  getSet eq? &compare::flag store nextSet
  &compare::maxlength fetch #1 - &compare::maxlength store

  "Exit conditions"
  &compare::maxlength fetch &compare::flag fetch and 0; drop
  ^compare_loop

:str:compare
  #0 &compare::flag store
  dup-pair str:length swap str:length eq?
  [ dup str:length &compare::maxlength store compare_loop ] if
  drop drop
  &compare::flag fetch
  ;
````

### Conditionals

Implement **cond**, a conditional combinator which will execute one of two functions, depending on the state of a flag. We take advantage of a little hack here. Store the pointers into a jump table with two fields, and use the flag as the index. Default to the *false* entry, since a *true* flag is -1.

````
:if::true  `0
:if::false `0
:cond  "bpp-" &if::false store &if::true store &if::false + fetch call ;
````

Next two additional forms:

````
:if   "bp-"  _ccall ;
:-if  "bp-"  push #0 eq? pop _ccall ;
````

## Interpreter & Compiler

## Compiler Core

The heart of the compiler is **comma** which stores a value into memory and increments a variable (**heap**) pointing to the next free address. **here** is a helper function that returns the address stored in **heap**.

````
:here   "-n"  &Heap fetch ;
:comma  "n-"  here !+ &Heap store ;
````

With these we can add a couple of additional forms. **comma:opcode** is used to compile VM instructions into the current defintion. This is where those functions starting with an underscore come into play. Each wraps a single instruction. Using this we can avoid hard coding the opcodes.

````
:comma:opcode  "p-"  fetch comma ;
````

**comma:string** is used to compile a string into the current definition.

````
:($)           "a-a"  @+ 0; comma ^($)
:comma:string  "a-"  ($) drop #0 comma ;
````

## Compiler Extension

With the core functions above it's now possible to setup a few more things that make compilation at runtime more practical.

First, a variable indicating whether we should compile or run a function. This will be used by the *word classes*.

````
:Compiler `0
````

````
:compiling? &Compiler fetch ;
````

````
:fin  "-"  &_ret comma:opcode #0 &Compiler store ;
````

### Word Classes

Rx handles functions via handlers called *word classes*. Each of these is a function responsible for handling specific groupings of functions. The class handlers will either invoke the code in a function or compile the code needed to call them.

````
:.data  compiling? 0; drop &_lit comma:opcode comma ;
:.word  compiling? [ .data &_call comma:opcode ] [ call ] cond ;
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
````

Rx provides accessor functions for each field. Since the number of fields (or their ordering) may change over time, using these reduces the number of places where field offsets are hard coded.

````
:d:link  "d-p"  #0 + ;
:d:xt    "d-p"  #1 + ;
:d:class "d-p"  #2 + ;
:d:name  "d-p"  #3 + ;
````

A traditional Forth has **create** to make a new dictionary entry pointing to **here**. Rx has **newentry** which serves as a slightly more flexible base. You provide a string for the name, a pointer to the class handler, and a pointer to the start of the function. Rx does the rest.

````
:newentry  "saa-"
  here push
    &Dictionary fetch comma  "link"
    comma "xt"
    comma "class"
    comma:string  "name"
  pop &Dictionary store
  ;
````

Rx doesn't provide a traditional create as it's designed to avoid assuming a normal input stream and prefers to take its data from the stack.

### Dictionary Search

````
:which  `0
:needle `0

:find
  #0 &which store
  &Dictionary fetch
:find_next
  0; dup #3 + &needle fetch str:compare [ dup &which store ] if fetch
^find_next

:lookup  "s-n"  &needle store find &which fetch ;
````

## Number Conversion

This code converts a zero terminated string into a number. The approach is very simple:

* Store an internal multiplier value (-1 for negative, 1 for positive)
* Clear an internal accumulator value
* Loop:

  * Fetch the accumulator value
  * Multiply by 10
  * For each character, convert to a numeric value and add to the accumulator
  * Store the updated accumulator

* When done, take the accumulator value and the modifier and multiply them to get the final result

````
:asnumber:mod `0  "modifier"
:asnumber:acc `0  "accumulator"

:asnumber:char>digit  "c-n"  $0 - ;

:asnumber:scale       "-n"  &asnumber:acc fetch #10 * ;

:asnumber:convert     "p-p"
  @+ 0; asnumber:char>digit asnumber:scale + &asnumber:acc store
  ^asnumber:convert

:asnumber:prepare     "p-p"
  #1 &asnumber:mod store
  #0 &asnumber:acc store
  dup fetch $- eq? [ #-1 &asnumber:mod store #1 + ] if ;

:asnumber             "p-n"
  asnumber:prepare asnumber:convert drop
  &asnumber:acc fetch &asnumber:mod fetch * ;
````

## Token Processing

An input token has a form like:

    <prefix-char>string

Rx will check the first character to see if it matches a known prefix. If it does, it will pass the string (without the token) to the prefix handler. If not, it will attempt to find the token in the dictionary.

Prefixes are handled by functions with specific naming conventions. A prefix name should be:

    prefix:<prefix-char>

Where *&lt;prefix-char&gt;* is the character for the prefix. These should be compiler macros (using the **.macro** class) and watch the **compiler** state to decide how to deal with the token. To find a prefix, Rx stores the prefix character into a string named **prefixed**. It then searches for this string in the dictionary. If found, it sets an internal variable (**prefix:handler**) to the dictionary entry for the handler function. If not found, **prefix:handler** is set to zero. The check, done by **prefix?**, also returns a flag.

````
:prefix:handler `0
:prefixed 'prefix:_'
:prefix:prepare  "s-"
 fetch &prefixed #7 + store ;
:prefix?         "s-sb"
 prefix:prepare &prefixed lookup dup &prefix:handler store #0 -eq? ;
````

Rx uses prefixes for important bits of functionality including parsing numbers (prefix with **#**), obtaining pointers (prefix with **&amp;**), and starting new functions (using the **:** prefix).

````
:prefix:#  asnumber .data ;
:prefix:$  fetch .data ;
:prefix::  &.word here newentry here &Dictionary fetch d:xt store #-1 &Compiler store ;
:prefix:&  lookup d:xt fetch .data ;
:prefix:`  compiling? [ asnumber comma ] [ drop ] cond ;
:prefix:'  &_lit comma:opcode here push #0 comma &_jump comma:opcode
           here push comma:string pop
           here pop store .data ;
````

## Quotations

````
:notfound $? putc ;

:begin here ;
:again &_lit comma:opcode comma &_jump comma:opcode ;
:t-[ &_lit comma:opcode here #0 comma &_jump comma:opcode here ;
:t-] &_ret comma:opcode here swap &_lit comma:opcode comma swap store ;

:t-0;    compiling? 0; drop &_zret comma:opcode ;
:t-push  compiling? 0; drop &_push comma:opcode ;
:t-pop   compiling? 0; drop &_pop comma:opcode ;
````

````
:startup
  'rx-2016.09'

:okmsg
  'ok'

:ok &okmsg puts space ;

:call:dt dup d:xt fetch swap d:class fetch call ;

:input:source `0

:interpret:prefix &prefix:handler fetch 0; &input:source fetch #1 + swap call:dt ;
:interpret:word   &which fetch call:dt ;

:interpret "s-"
  &input:source store
  &input:source fetch prefix?
  [ interpret:prefix ]
  [ &input:source fetch lookup #0 -eq? &interpret:word &notfound cond ] cond
;

:main
  &startup puts cr cr words cr cr
:main_loop
  compiling? [ ok ] -if getToken
  &TIB interpret
  compiling? [ cr ] -if
  ^main_loop
````

````
:words &Dictionary fetch :words:list 0; dup d:name puts space fetch ^words:list
````

## Dictionary

The dictionary is a linked list.


````
:0000 `0    |dup           |.word  'dup'
:0001 |0000 |drop          |.word  'drop'
:0002 |0001 |swap          |.word  'swap'
:0003 |0002 |call          |.word  'call'
:0004 |0003 |eq?           |.word  'eq?'
:0005 |0004 |-eq?          |.word  '-eq?'
:0006 |0005 |lt?           |.word  'lt?'
:0007 |0006 |gt?           |.word  'gt?'
:0008 |0007 |fetch         |.word  'fetch'
:0009 |0008 |store         |.word  'store'
:0010 |0009 |+             |.word  '+'
:0011 |0010 |-             |.word  '-'
:0012 |0011 |*             |.word  '*'
:0013 |0012 |/mod          |.word  '/mod'
:0014 |0013 |and           |.word  'and'
:0015 |0014 |or            |.word  'or'
:0016 |0015 |xor           |.word  'xor'
:0017 |0016 |shift         |.word  'shift'
:0018 |0017 |t-push        |.macro 'push'
:0019 |0018 |t-pop         |.macro 'pop'
:0020 |0019 |t-0;          |.macro '0;'
:0021 |0020 |bye           |.word  'bye'
:0022 |0021 |tuck          |.word  'tuck'
:0023 |0022 |over          |.word  'over'
:0024 |0023 |nip           |.word  'nip'
:0025 |0024 |dup-pair      |.word  'dup-pair'
:0026 |0025 |drop-pair     |.word  'drop-pair'
:0027 |0026 |/             |.word  '/'
:0028 |0027 |mod           |.word  'mod'
:0029 |0028 |negate        |.word  'negate'
:0030 |0029 |not           |.word  'not'
:0031 |0030 |@+            |.word  '@+'
:0032 |0031 |!+            |.word  '!+'
:0033 |0022 |str:compare   |.word  'str:compare'
:0034 |0033 |str:length    |.word  'str:length'
:0035 |0034 |cond          |.word  'cond'
:0036 |0035 |if            |.word  'if'
:0037 |0036 |-if           |.word  '-if'
:0038 |0037 |Compiler      |.data  'Compiler'
:0039 |0038 |Heap          |.data  'Heap'
:0040 |0039 |comma         |.word  ','
:0041 |0040 |comma:string  |.word  's,'
:0042 |0041 |here          |.word  'here'
:0043 |0042 |fin           |.macro ';'
:0044 |0043 |t-[           |.macro '['
:0045 |0044 |t-]           |.macro ']'
:0046 |0045 |Dictionary    |.data  'Dictionary'
:0047 |0046 |d:link        |.word  'd:link'
:0048 |0047 |d:xt          |.word  'd:xt'
:0049 |0048 |d:class       |.word  'd:class'
:0050 |0049 |d:name        |.word  'd:name'
:0051 |0050 |.word         |.word  '.word'
:0052 |0051 |.macro        |.word  '.macro'
:0053 |0052 |.data         |.word  '.data'
:0054 |0053 |newentry      |.word  'd:add-header'
:0055 |0054 |prefix:#      |.macro 'prefix:#'
:0056 |0055 |prefix::      |.macro 'prefix::'
:0057 |0056 |prefix:&      |.macro 'prefix:&'
:0058 |0057 |prefix:$      |.macro 'prefix:$'
:0059 |0058 |prefix:`      |.macro 'prefix:`'
:0060 |0059 |prefix:'      |.macro 'prefix:''
:0061 |0060 |begin         |.macro 'begin'
:0062 |0061 |again         |.macro 'again'
:0063 |0062 |interpret     |.word  'interpret'
:0064 |0063 |lookup        |.word  'd:lookup'

:0900 |0064 |putc          |.word  'putc'
:0901 |0900 |putn          |.word  'putn'
:0902 |0901 |puts          |.word  'puts'
:0903 |0902 |cls           |.word  'cls'
:0904 |0903 |getc          |.word  'getc'
:0905 |0904 |getn          |.word  'getn'
:0906 |0905 |gets          |.word  'gets'
:0907 |0906 |save          |.word  'save'

:9999 |0907 |words         |.word  'words'
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
:save `130 ;
````

With this, we can build in some interactivity around a terminal I/O model.

````
:cr #10 putc ;
:space #32 putc ;
:getToken #32 #2048 &TIB gets ;
:TIB `4096
````
