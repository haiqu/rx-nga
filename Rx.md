# Rx: a minimal Forth for Nga
    ____  _   _
    || \\ \\ //
    ||_//  )x(
    || \\ // \\ 2016.09

*Rx* (*retro experimental*) is a minimal Forth implementation for the Nga virtual machine. Like Nga this is intended to be used within a larger supporting framework adding I/O and other desired functionality. Various example interface layers are included.

## General Notes on the Source

Rx is developed using a literate tool called *unu*. This allows extraction of fenced code blocks into a separate file for later compilation. Developing in a literate approach is beneficial as it makes it easier for me to keep documentation current and lets me approach the code in a more structured manner.

The code is written in *nuance*. Nuance is a small preprocessor that converts a simple Forth-style language into assembly. I chose to do it this way to reduce the time needed to build and maintain this. Generally the syntax of Nuance is similar to the Rx language, though it adds some useful things like support for forward references.

Nuance generates assembly language. This is built with *naje*, the standard Nga assembler.

The entire process of using *unu*, *nuance*, and *naje* to build an image for Nga takes around 0.1s on my Linode.

## In the Beginning..

All code built with the Nga toolchain starts with a jump to the main entry point. With cell packing, this takes two cells. We can take advantage of this knowledge to place a couple of variables at the start so they can be easily identified and interfaced with external tools. This is important as Nga allows for a variety of I/O models to be implemented and I don't want to tie Rx into any one specific model.

Here's the initial memory map:

| Offset | Contains                    |
| ------ | --------------------------- |
| 0      | lit call nop nop            |
| 1      | Pointer to main entry point |
| 2      | Dictionary                  |
| 3      | Heap                        |

Naje, the Nga assembler, compiles the initial instructions automatically. The two variables need to be declared next, so:

````
:Dictionary |9999
:Heap       `3072
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
````

## Stack Shufflers

These add additional operations on the stack elements that'll keep later code much more readable.

````
:tuck      "xy-yxy"   dup push swap pop ;
:over      "xy-xyx"   push dup pop swap ;
:nip       "xy-y"     swap drop ;
:dup-pair  "xy-xyxy"  over over ;
:drop-pair "xy-"      drop drop ;
````

## Math & Logic

The basic math operations are addition, subtraction, multiplication, and division/remainder. We define a couple more things that'll be useful later: separate division and remainder functions, and negation.

````
:/       "nq-d" /mod swap drop ;
:mod     "nq-r" /mod drop ;
:negate  "n-n"  #-1 * ;
:not     "n-n"  #-1 xor ;
````

## Memory

The basic memory accesses are handled via **fetch** and **store**. These two functions provide slightly easier access to linear sequences of data.

````
:@+     "a-An"  dup #1 + swap fetch ;
:!+     "na-A"  dup #1 + push store pop ;
````

## Strings

There are two basic string operations needed: obtaining the length and comparing for equality.

Strings in Rx are zero terminated. This is a bit less elegant than counted strings, but the implementation is quick and easy.

First up, string length. The process here is trivial:

* Make a copy of the starting point
* Fetch each character, comparing to zero

  * If zero, break the loop
  * Otherwise discard and repeat

* When done subtract the original address from the current one
* Then subtract one (to account for the zero terminator)

````
:count @+ 0; drop ^count
:str:length dup count #1 - swap - ;
````

String comparisons are harder.

````
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
  dup-pair str:length swap str:length dup &compare::maxlength store eq?
  [ compare_loop ] if
  drop drop
  &compare::flag fetch
  ;
````

## Conditionals

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

### Compiler Core

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

With the core functions above it's now possible to setup a few more things that make compilation at runtime more practical.

First, a variable indicating whether we should compile or run a function. This will be used by the *word classes*. I also define an accessor function named **compiling?** to aid in readability later on.

````
:Compiler `0
:compiling?  "-f"  &Compiler fetch ;
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

Rx will store the pointer to the most recent entry in a variable called **dictionary**. For simplicity, we just assign the last entry an arbitrary label of 9999. This is set at the start of the source. (See *In the Beginning...*)

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

### Number Conversion

This code converts a zero terminated string into a number. The approach is very simple:

* Store an internal multiplier value (-1 for negative, 1 for positive)
* Clear an internal accumulator value
* Loop:

  * Fetch the accumulator value
  * Multiply by 10
  * For each character, convert to a numeric value and add to the accumulator
  * Store the updated accumulator

* When done, take the accumulator value and the modifier and multiply them to get the final result

At this time Rx only supports decimal numbers.

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

### Token Processing

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

### Quotations

````
:begin here ;
:again &_lit comma:opcode comma &_jump comma:opcode ;
:t-[ &_lit comma:opcode here #0 comma &_jump comma:opcode here ;
:t-] &_ret comma:opcode here swap &_lit comma:opcode comma swap store ;

:t-0;    compiling? 0; drop &_zret comma:opcode ;
:t-push  compiling? 0; drop &_push comma:opcode ;
:t-pop   compiling? 0; drop &_pop comma:opcode ;
````

## Interpreter

The *interpreter* is what processes input. What it does is:

* Take a string
* See if the first character has a prefix handler

  * Yes: pass the rest of the string to the prefix handler for processing
  * No: lookup in the dictionary

    * Found: pass xt of word to the class handler for processing
    * Not found: report error via **notfound**

````
:notfound "-" ^_nop ;

:call:dt "d-" dup d:xt fetch swap d:class fetch call ;

:input:source `0

:interpret:prefix &prefix:handler fetch 0; &input:source fetch #1 + swap call:dt ;
:interpret:word   &which fetch call:dt ;

:interpret "s-"
  &input:source store
  &input:source fetch prefix?
  [ interpret:prefix ]
  [ &input:source fetch lookup #0 -eq? &interpret:word &notfound cond ] cond
;
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

:0021 |0020 |tuck          |.word  'tuck'
:0022 |0021 |over          |.word  'over'
:0023 |0022 |nip           |.word  'nip'
:0024 |0023 |dup-pair      |.word  'dup-pair'
:0025 |0024 |drop-pair     |.word  'drop-pair'
:0026 |0025 |/             |.word  '/'
:0027 |0026 |mod           |.word  'mod'
:0028 |0027 |negate        |.word  'negate'
:0029 |0028 |not           |.word  'not'

:0030 |0029 |@+            |.word  '@+'
:0031 |0030 |!+            |.word  '!+'
:0032 |0031 |str:compare   |.word  'str:compare'
:0033 |0032 |str:length    |.word  'str:length'
:0034 |0033 |cond          |.word  'cond'
:0035 |0034 |if            |.word  'if'
:0036 |0035 |-if           |.word  '-if'
:0037 |0036 |Compiler      |.data  'Compiler'
:0038 |0037 |Heap          |.data  'Heap'
:0039 |0038 |comma         |.word  ','

:0040 |0039 |comma:string  |.word  's,'
:0041 |0040 |here          |.word  'here'
:0042 |0041 |fin           |.macro ';'
:0043 |0042 |t-[           |.macro '['
:0044 |0043 |t-]           |.macro ']'
:0045 |0044 |Dictionary    |.data  'Dictionary'
:0046 |0045 |d:link        |.word  'd:link'
:0047 |0046 |d:xt          |.word  'd:xt'
:0048 |0047 |d:class       |.word  'd:class'
:0049 |0048 |d:name        |.word  'd:name'

:0050 |0049 |.word         |.word  '.word'
:0051 |0050 |.macro        |.word  '.macro'
:0052 |0051 |.data         |.word  '.data'
:0053 |0052 |newentry      |.word  'd:add-header'
:0054 |0053 |prefix:#      |.macro 'prefix:#'
:0055 |0054 |prefix::      |.macro 'prefix::'
:0056 |0055 |prefix:&      |.macro 'prefix:&'
:0057 |0056 |prefix:$      |.macro 'prefix:$'
:0058 |0057 |prefix:`      |.macro 'prefix:`'
:0059 |0058 |prefix:'      |.macro 'prefix:''

:0060 |0059 |begin         |.macro 'begin'
:0061 |0060 |again         |.macro 'again'
:0062 |0061 |interpret     |.word  'interpret'
:0063 |0062 |lookup        |.word  'd:lookup'
:9999 |0063 |notfound      |.word  'notfound'
````

## Appendix: Words, Stack Effects, and Usage

| Word         | Stack     | Notes                                             |
| ------------ | --------- | ------------------------------------------------- |
| dup          | n-nn      | Duplicate the top item on the stack               |
| drop         | nx-n      | Discard the top item on the stack                 |
| swap         | nx-xn     | Switch the top two items on the stack             |
| call         | p-        | Call a function (via pointer)                     |
| eq?          | nn-f      | Compare two values for equality                   |
| -eq?         | nn-f      | Compare two values for inequality                 |
| lt?          | nn-f      | Compare two values for less than                  |
| gt?          | nn-f      | Compare two values for greater than               |
| fetch        | p-n       | Fetch a value stored at the pointer               |
| store        | np-       | Store a value into the address at pointer         |
| +            | nn-n      | Add two numbers                                   |
| -            | nn-n      | Subtract two numbers                              |
| *            | nn-n      | Multiply two numbers                              |
| /mod         | nn-mq     | Divide two numbers, return quotient and remainder |
| and          | nn-n      | Perform bitwise AND operation                     |
| or           | nn-n      | Perform bitwise OR operation                      |
| xor          | nn-n      | Perform bitwise XOR operation                     |
| shift        | nn-n      | Perform bitwise shift                             |
| tuck         | xy-yxy    | Put a copy of the top item under the second item  |
| over         | xy-xyx    | Make a copy of the second item on the stack       |
| nip          | xy-y      | Remove the second item on the stack               |
| dup-pair     | xy-xyxy   | Duplicate top two values fom the stack            |
| drop-pair    | xy-       | Drop top two values from the stack                |
| /            | nq-d      | Divide and return quotient                        |
| mod          | nq-r      | Divide and return remainder                       |
| negate       | n-n       | Invert the sign of a number                       |
| not          | n-n       | Perform a NOT operation                           |
| @+           | a-an      | Fetch a value and return next address             |
| !+           | na-a      | Store a value to address and return next address  |
| push         | n-        | Move value from data stack to address stack       |
| pop          | -n        | Move value from address stack to data stack       |
| 0;           | n-n OR n- | Exit word (and **drop**) if TOS is zero           |
| str:compare  | ss-f      | Compare two strings for equality                  |
| str:length   | s-n       | Return length of string                           |
| cond         | fpp-?     | Execute *p1* if *f* is -1, or *p2* if *f* is 0    |
| if           | fp-?      | Execute *p* if flag *f* is true (-1)              |
| -if          | fp-?      | Execute *p* if flag *f* is false (0)              |
| Compiler     | -p        | Variable; holds compiler state                    |
| Heap         | -p        | Variable; points to next free memory address      |
| ,            | n-        | Compile a value into memory at **here**           |
| s,           | s-        | Compile a string into memory at **here**          |
| here         | -p        | Return the value stored in **Heap**               |
| ;            | -         | End compilation and compile a *return* instruction|
| [            | -         | Begin a quotation                                 |
| ]            | -         | End a quotation                                   |
| Dictionary   | -p        | Variable; points to most recent header            |
| d:link       | p-p       | Given a DT, return the address of the link field  |
| d:xt         | p-p       | Given a DT, return the address of the xt field    |
| d:class      | p-p       | Given a DT, return the address of the class field |
| d:name       | p-p       | Given a DT, return the address of the name field  |
| .word        | p-        | Class handler for standard functions              |
| .macro       | p-        | Class handler for immediate functions             |
| .data        | p-        | Class handler for data                            |
| d:add-header | saa-      | Add an item to the dictionary                     |
| prefix:#     | s-        | # prefix for numbers                              |
| prefix::     | s-        | : prefix for definitions                          |
| prefix:&     | s-        | & prefix for pointers                             |
| prefix:$     | s-        | $ prefix for ASCII characters                     |
| prefix:`     | s-        | ` prefix for bytecode                             |
| prefix:'     | s-        | ' prefix for simple text                          |
| begin        | -a        | Start an unconditional loop                       |
| again        | a-        | End an unconditional loop                         |
| interpret    | s-?       | Evaluate a token                                  |
| d:lookup     | s-p       | Given a string, return the DT (or 0 if undefined) |
| notfound     | -         | Handler for token not found errors                |
