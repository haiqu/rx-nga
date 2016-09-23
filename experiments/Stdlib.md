# Rx Core Standard Library

*Rx Core* ("*Rx*" from this point on) is the *retro experimental core*, a proto-Forth environment. It's intended to be a clean, minimalist base for experimenting with. The code contained here is the *standard library*, a collection of functions that makes the minimal language provided by Rx significantly more useful.

## Stack Shufflers

````
:rot       "xyz-yzx"  push swap pop swap ;
:-rot      "xyz-xzy"  swap push swap pop ;
:tuck      "xy-yxy"   dup -rot ;
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
:@+     dup #1 + swap fetch ;
:!+     dup #1 + push ! pop ;
:on     #-1 swap ! ;
:off    #0 swap ! ;
````

Additional functions from Retro:

String comparisons

````
:count @+ 0; drop ^count
:getLength dup count #1 - swap - ;

:compare::flag `0
:compare::maxlength `0

:getSet fetch swap fetch ;
:nextSet #1 + swap #1 + ;

:compare_loop
  dup-pair
  getSet eq? &compare::flag ! nextSet
  &compare::maxlength fetch #1 - &compare::maxlength !

  "Exit conditions"
  &compare::maxlength fetch &compare::flag fetch and 0; drop
  ^compare_loop

:compare
  #0 &compare::flag !
  dup-pair getLength swap getLength eq?
  [ dup getLength &compare::maxlength ! compare_loop ] if
  drop drop
  &compare::flag fetch
  ;
````

### Conditionals

Implement **cond**, a conditional combinator which will execute one of two functions, depending on the state of a flag. We take advantage of a little hack here. Store the pointers into a jump table with two fields, and use the flag as the index. Default to the *false* entry, since a *true* flag is -1.

````
:if::true  `0
:if::false `0
:cond  "bpp-" &if::false ! &if::true ! &if::false + fetch call ;
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
:heap   `8192
:here   "-n"  &heap fetch ;
:comma  "n-"  here !+ &heap ! ;
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
:compiler `0
````

Next a couple of functions to control compiler state. In a traditional Forth these would be ] and [. In Rx we use ]] and [[ instead as [ ] are used for quotations.

````
:]]   &compiler on ;
:[[   &compiler off ;
````

````
:fin   &_ret comma:opcode &compiler off ;
````

### Word Classes

Rx handles functions via handlers called *word classes*. Each of these is a function responsible for handling specific groupings of functions. The class handlers will either invoke the code in a function or compile the code needed to call them.

````
:.data  &compiler fetch 0; drop &_lit comma:opcode comma ;
:.word  &compiler fetch [ .data &_call comma:opcode ] [ call ] cond ;
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

A traditional Forth has **create** to make a new dictionary entry pointing to **here**. Rx has **newentry** which serves as a slightly more flexible base. You provide a string for the name, a pointer to the class handler, and a pointer to the start of the function. Rx does the rest.

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

Rx doesn't provide a traditional create as it's designed to avoid assuming a normal input stream and prefers to take its data from the stack.

### Dictionary Search

````
:which  `0
:needle `0

:find
  #0 &which !
  &dictionary fetch
:find_next
  0; dup #3 + &needle fetch compare [ dup &which ! ] if fetch
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

## Token Parser

````
:prefix:handler `0
:prefixed 'prefix:_'

:prefix:# asnumber .data ;
:prefix:: &.word here newentry here &dictionary fetch d:xt store ]] ;
:prefix:& lookup d:xt fetch .data ;

:prefix:prepare  "s-" fetch &prefixed #7 + store ;

:prefix?  "s-sb"
  prefix:prepare &prefixed lookup dup &prefix:handler store #0 -eq? ;
````


````
:notfound $? putc ;
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
  &compiler fetch [ ok ] -if getToken
  &TIB interpret
  &compiler fetch [ cr ] -if
  ^main_loop
````

````
:words &dictionary fetch :words:list 0; dup d:name puts space fetch ^words:list
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
