    ____   ____ ______ ____    ___
    || \\ ||    | || | || \\  // \\
    ||_// ||==    ||   ||_// ((   ))
    || \\ ||___   ||   || \\  \\_//
    a personal, minimalistic forth

## Background

Retro is a dialect of Forth. It builds on the barebones Rx core, providing a much more flexible and useful language.

Retro has a history going back many years. It began as a 16-bit assembly implementation for x86 hardware, evolved into a 32-bit system with cmForth and ColorForth influences, and eventually started supporting mainstream OSes. Later it was rewritten for a small, portable virtual machine. Over the years the language implementation has varied substantially. This is the twelfth generation of Retro. It now targets a new virtual machine (called Nga), and is built over a barebones Forth kernel (called Rx).

### Namespaces

Various past releases have had different methods of dealing with the dictionary. Retro 12 has a single global dictionary, with a convention of using a namespace prefix for grouping related words.

| namespace  | words related to   |
| ---------- | ------------------ |
| chr        | characters         |
| compile    | compiler functions |
| d          | dictionary headers |
| ed         | block editor       |
| err        | error handlers     |
| n          | numbers            |
| str        | strings            |
| v          | variables          |

### Prefixes

Prefixes are an integral part of Retro. These are single characters added to the start of a word which indicate to Retro how it should execute the word. These are processed at the start of interpreting a token.

| prefix | used for               |
| ------ | ---------------------- |
| :      | starting a definition  |
| &amp;  | obtaining pointers     |
| (      | stack comments         |
| `      | inlining bytecodes     |
| '      | strings                |

### Naming &amp; Style Conventions

* Names should start with their namespace (if appropriate)
* Word names should be lowercase
* Variable names should be Title case
* Constants should be UPPERCASE
* Names may not start with a prefix character
* Names returning a flag should end with a ?
* Words with an effect on the stack should have a stack comment

## Constants

Memory Map

| range           | contains                     |
| --------------- | ---------------------------- |
| 0 - 1470        | rx kernel                    |
| 1471 - 1535     | token input buffer           |
| 1536 +          | start of heap space          |
| 326140 - 327679 | temporary strings (12 * 128) |
| 327680 - 524287 | blocks (384 * 512 cells)     |
| 524287          | end of memory                |

````
:EOM       #524287 ;
:STRINGS   #326140 ;
:BLOCKS    #327680 ;
:LASTBLOCK #384 ;
````

## Stack Comments

Retro provides a **(** prefix for stack comments. This will be used by all subsequent words so it comes first.

Example:

    (n-)

````
:prefix:( drop ;
  &class:macro
  &Dictionary fetch d:class
  store
````

## Changing Word Classes

In implementing **prefix:(** a messy sequence follows the definition:

    &class:macro &Dictionary fetch d:class store

This is used to change the class from **class:word** to **class:macro**. Doing this is ugly and not very readable. The next few words provide easier means of changing the class of the most recently defined word.

````
:reclass    (a-) &Dictionary fetch d:class store ;
:immediate  (-)  &class:macro reclass ;
:data       (-)  &class:data reclass ;
````

## Compiler

````
:compile:lit  (a-) #1 , , ;
:compile:jump (a-) compile:lit #7 , ;
:compile:call (a-) compile:lit #8 , ;
:compile:ret  (-)  #10 , ;
````

## Inlining

````
:prefix:` (s-) &Compiler fetch [ str:to-number , ] [ drop ] choose ; &class:macro &Dictionary fetch d:class store
````

## Constants

````
:TRUE  (-n) #-1 ;
:FALSE (-n)  #0 ;
````

## Comparators

````
:n:zero?     (n-f)  #0 eq? ;
:n:-zero?    (n-f)  #0 -eq? ;
:n:negative?  (n-f)  #0 lt? ;
:n:positive?  (n-f)  #0 gt? ;
````

## Combinators

Retro makes use of anonymous functions called *quotations* for much of the execution flow and stack control. The words that operate on these quotations are called *combinators*.

**dip** executes a quotation after moving a value off the stack. The value is restored after execution completes. These are equivilent:

    #10 #12 [ #3 - ] dip
    #10 #12 push #3 - pop

````
:dip  (nq-n)  swap push call pop ;
````

**sip** is similar to dip, but leaves a copy of the value on the stack while the quotation is executed. These are equivilent:

    #10 [ #3 * ] sip
    #10 dup push #3 * pop

````
:sip  (nq-n)  push dup pop swap &call dip ;
````

Apply each quote to a copy of x

````
:bi  (xqq-)  &sip dip call ;
````

Apply q1 to x and q2 to y

````
:bi*  (xyqq-) &dip dip call ;
````

Apply q to x and y

````
:bi@  (xyq-)  dup bi* ;
````

Apply each quote to a copy of x

````
:tri  (xqqq-)  [ &sip dip sip ] dip call ;
````

Apply q1 to x, q2 to y, and q3 to z

````
:tri*  (xyzqqq-)  [ [ swap &dip dip ] dip dip ] dip call ;
````

Apply q to x, y, and z

````
:tri@ dup dup tri* ;
````

Now we can do useful things like:

    :Red   `0 ; data
    :Green `1 ; data
    :Blue  `2 ; data

    :inline-100 &Compiler fetch [ #100 compile:lit ] [ #100 ] choose ; immediate

## ...

````
:compiling?  (-f)  &Compiler fetch ;
````

## Stack Shufflers

The core Rx language provides a few basic stack shuffling words: **push**, **pop**, **drop**, **swap**, and **dup**. There are quite a few more that are useful. These are provided here.

````
:tuck      (xy-yxy)   dup push swap pop ;
:over      (xy-xyx)   push dup pop swap ;
:dup-pair  (xy-xyxy)  over over ;
:nip       (xy-y)     swap drop ;
:drop-pair (nn-)      drop drop ;
:?dup      (n-nn||n-n) dup 0; ;
:rot       (abc-bca)   [ swap ] dip swap ;
````

Short for *top of return stack*, this returns the top item on the address stack. As an analog to traditional Forth, this is equivilent to **R@**.

````
:tors (-n)  pop pop dup push swap push ;
````

## Math

The core Rx language provides addition, subtraction, multiplication, and a combined division/remainder. Retro expands on this.

````
:/         (nq-d)  /mod swap drop ;
:mod       (nq-r)  /mod drop ;
:*/        (nnn-n) push * pop / ;
:not       (n-n)   #-1 xor ;
:n:negate  (n-n)   #-1 * ;
:n:square  (n-n)   dup * ;
:n:sqrt    (n-n) #1 [ repeat dup-pair / over - #2 / 0; + again ] call nip ;
:n:min     (nn-n)  dup-pair lt? [ drop ] [ nip ] choose ;
:n:max     (nn-n)  dup-pair gt? [ drop ] [ nip ] choose ;
:n:abs     (n-n)   dup n:negate n:max ;
:n:limit   (nlu-n) swap push n:min pop n:max ;
:n:inc     (n-n)   #1 + ;
:n:dec     (n-n)   #1 - ;
:n:between? (nul-) rot [ rot rot n:limit ] sip eq? ;
````

## Memory

````
:v:inc-by  (na-)   [ fetch + ] sip store ;
:v:dec-by  (na-)   [ fetch swap - ] sip store ;
:v:inc     (n-n)   #1 swap v:inc-by ;
:v:dec     (n-n)   #1 swap v:dec-by ;
:v:limit   (alu-)  push push dup fetch pop pop n:limit swap store ;
:allot     (n-)    &Heap v:inc-by ;
````

## Lexical Scope

The dictionary is a simple linked list. Retro allows for some control over what is visible using the **{{**, **---reveal---**, and **}}** words.

As an example:

    {{
      :increment dup fetch n:inc swap store ;
      :Value `0 ;
    ---reveal---
      :next-number &Value fetch &Value increment ;
    }}

Only the **next-number** function will remain visible once **}}** is executed.

````
:ScopeList `0 `0 ;
:{{ &Dictionary fetch dup &ScopeList store-next store ;
:---reveal--- &Dictionary fetch &ScopeList n:inc store ;
:}} &ScopeList fetch-next swap fetch eq? [ &ScopeList fetch &Dictionary store ] [ &ScopeList fetch [ &Dictionary repeat fetch dup fetch &ScopeList n:inc fetch -eq? 0; drop again ] call store ] choose ;
````

## Flow

Execute quote until quote returns a flag of 0.

````
:while  (q-)  [ repeat dup dip swap 0; drop again ] call drop ;
````

Execute quote until quote returns a flag of -1.

````
:until  (q-)  [ repeat dup dip swap not 0; drop again ] call drop ;
````

The **times** combinator runs a quote (n) times.

````
:times  (q-)  swap [ repeat 0; n:dec push &call sip pop again ] call drop ;
````

## Numbers

````
:n:pow  (bp-n)  #1 swap [ over * ] times nip ;
````

## Buffer

````
{{
  :Buffer `0 ; data
  :Ptr    `0 ; data
  :terminate (-) #0 &Ptr fetch store ;
---reveal---
  :buffer:start  (-a) &Buffer fetch ;
  :buffer:end    (-a) &Ptr fetch ;
  :buffer:add    (c-) buffer:end store &Ptr v:inc terminate ;
  :buffer:get    (-c) &Ptr v:dec buffer:end fetch terminate ;
  :buffer:empty  (-)  buffer:start &Ptr store terminate ;
  :buffer:size   (-n) buffer:end buffer:start - ;
  :buffer:set    (a-) &Buffer store buffer:empty ;
}}
````

## Incoming

**later** is a small tool for interleaving code execution paths. This is somewhat difficult to explain.

Let's look at an example:

    :a #1 later #3 ;
    :b a #2 ;

When *b* executes it begins by calling *a* which pushes #1 to the stack. **later** then returns control to *b*, which pushes #2 to the stack. When execution of *b* ends at the *;*, control returns to *a* which finishes executing by pushing the #3 to the stack.

You can use **later** to pass control back and forth:

    :a #1 later #2 ;
    :b a #33 * later + ;

````
:later pop pop swap push push ;
````

````
:copy   (aan-) [ &fetch-next dip store-next ] times drop drop ;
````

## Strings

Strings are zero terminated.

Temporary strings are allocated in a circular pool (at STRINGS).

````
{{
  :MAX-LENGTH #128 ;
  :str:Current `0 ; data

  :str:pointer (-p)  &str:Current fetch MAX-LENGTH * STRINGS + ;
  :str:next (-) &str:Current v:inc &str:Current fetch #12 eq? [ #0 &str:Current store ] if ;
---reveal---
  :str:temp (s-s) dup str:length str:pointer swap copy str:pointer str:next ;
  :str:empty (-s) str:pointer str:next ;
}}
````

Permanent strings are compiled into memory. To skip over them a helper function is used. When compiled into a definition this will look like:

    lit &str:skip
    call
    :stringbegins
    .data 98
    .data 99
    .data 100
    .data 0
    lit &stringbegins

The **str:skip** adjusts the Nga instruction pointer to skip to the code following the stored string.

````
:str:skip (-) pop [ fetch-next #0 -eq? ] while n:dec push ;
:str:keep (s-s) compiling? [ &str:skip class:word ] if &Heap fetch [ s, ] dip class:data ;
````

````
:prefix:' compiling? [ str:keep ] [ str:temp ] choose ; immediate
````

**str:chop** removes the last character from a string.

````
:str:chop (s-s) str:temp dup str:length over + n:dec #0 swap store ;
````

**str:reverse** reverses the order of a string. E.g.,

    'hello'  ->  'olleh'

````
:str:reverse (s-s)
  dup str:temp buffer:set &str:length [ dup str:length + n:dec ] bi swap
  [ dup fetch buffer:add n:dec ] times drop buffer:start str:temp ;
````

Trimming removes leading (**str:trim-left**) or trailing (**str:trim-right**) spaces from a string. **str:trim** removes both leading and trailing spaces.

````
:str:trim-left (s-s) str:temp [ fetch-next [ #32 eq? ] [ #0 -eq? ] bi and ] while n:dec ;
:str:trim-right (s-s) str:temp str:reverse str:trim-left str:reverse ;
:str:trim (s-s) str:trim-right str:trim-left ;
````

**str:prepend** and **str:append** for concatenating strings together.

````
{{
  :Buffer `0 ;
  :@Buffer &Buffer fetch ;
---reveal---
  :str:prepend (ss-s)
    str:empty &Buffer store
    dup str:length @Buffer swap &copy sip
    [ dup str:length ] dip @Buffer + swap copy @Buffer str:temp ;
  :str:append (ss-s) swap str:prepend ;
}}
````

````
{{
  :Needle `0 ; data
  :Haystack `0 ; data
---reveal---
  :str:find-char
   &Needle store
   repeat
     fetch-next
     dup #0 eq? [ drop drop #0 #0 ] [ #-1 ] choose 0; drop
     &Needle fetch eq? [ #-1 #0 ] [ #-1 ] choose 0; drop
  again ;
}}
````

Hash (using DJB2)

````
{{
  :<str:hash> repeat push #33 * pop fetch-next 0; swap push + pop again ;
---reveal---
  :str:hash  (s-n)  #5381 swap <str:hash> drop ;
}}
````

## Characters

````
:chr:SPACE        (-c)  #32 ;
:chr:ESC          (-c)  #27 ;
:chr:TAB          (-c)  #9 ;
:chr:CR           (-c)  #13 ;
:chr:LF           (-c)  #10 ;
:chr:letter?      (c-f) $A $z n:between? ;
:chr:lowercase?   (c-f) $a $z n:between? ;
:chr:uppercase?   (c-f) $A $Z n:between? ;
:chr:digit?       (c-f) $0 $9 n:between? ;
:chr:whitespace?  (c-f) [ chr:SPACE eq? ] [ #9 eq? ] [ [ #10 eq? ] [ #13 eq? ] bi or ] tri or or ;
:chr:to-upper     (c-c) chr:SPACE - ;
:chr:to-lower     (c-c) chr:SPACE + ;
:chr:toggle-case  (c-c) dup chr:lowercase? [ chr:to-upper ] [ chr:to-lower ] choose ;
:chr:to-string    (c-s) '.' dup store str:temp ;
:chr:visible?     (c-f) #31 #126 n:between? ;
````

## Number to String

Convert a decimal (base 10) number to a string.

````
:n:to-string  (n-s)
  &Heap fetch buffer:set
  [ #10 /mod swap $0 + buffer:add dup n:-zero? ] while drop
  buffer:start str:reverse str:temp ;
````

## Unsorted

````
:cons (nn-p) &Heap fetch [ swap , , ] dip ;
:curry (vp-p) &Heap fetch [ swap compile:lit compile:call compile:ret ] dip ;
:case
  [ over eq? ] dip swap
  [ nip call #-1 ] [ drop #0 ] choose 0; pop drop drop ;
````

## I/O

````
:putc (c-) `1000 ;
:getc (-c) `1001 ;
````

# Retro Block Editor

This is one part of the Retro Block Editor. See *Editor.md* for the other portion.

The implementation is split into two parts: an *interface layer*, written in C, and the editor logic, which is written in Retro. The code here contains the editor logic including key handling.

This has been influenced by Sam Falvo II's VIBE. Key handlers are words in the dictionary. The interface layer will lookup names and call the words to handle each keystroke. Naming conventions for the key handlers are as follows:

| name   | used for             |
| ------ | -------------------- |
| ed:c_? | keys in command mode |
| ed:i_? | keys in insert mode  |

Replace the *?* with the ASCII symbol for the key you are handling.

## Variables

There are a few global variables. These will hold the few pieces of state that we need.

````
:ed:Current `0 ;
:ed:Row `0 ;
:ed:Col `0 ;
:ed:Mode `0 ;
````

## Constraints

The cursor position (determined by **ed:Row** and **ed:Col**) needs to be within the block coordinates. Blocks are 8 rows of 64 characters. Additionally, the current block (**ed:Current**) needs to be in the range of valid blocks so we can avoid memory corruption. This word is used to keep these values within the necessary boundaries. Any words that modify these bits of state should call this to keep things orderly.

````
:ed:wrap (-)
  &ed:Col fetch #63 gt? [  #0 &ed:Col store &ed:Row v:inc ] if
  &ed:Col fetch  #0 lt? [ #63 &ed:Col store &ed:Row v:dec ] if
  &ed:Row fetch  #7 gt? [  #0 &ed:Row store  #0 &ed:Col store ] if
  &ed:Row fetch  #0 lt? [  #7 &ed:Row store #63 &ed:Col store ] if ;

:ed:constrain
  ed:wrap
  &ed:Row #0 #7 v:limit
  &ed:Col #0 #63 v:limit
  &ed:Current #0 LASTBLOCK n:dec v:limit ;
````

## Commands

The editor has two modes: command and insertion. These words switch between them.

````
:ed:command-mode #0 &ed:Mode store ;
:ed:insert-mode  #1 &ed:Mode store ;
:ed:quit-mode    #2 &ed:Mode store ;
````

**ed:Current** contains the current block. These commands allow switching between blocks.

````
:ed:next-block   &ed:Current v:inc ed:constrain ;
:ed:prior-block  &ed:Current v:dec ed:constrain ;
````

The cursor (insertion point) is determined by the **ed:Row** and **ed:Col** variables. The next group of commands move the cursor.

````
:ed:cursor-up    &ed:Row v:dec ed:constrain ;
:ed:cursor-down  &ed:Row v:inc ed:constrain ;
:ed:cursor-left  &ed:Col v:dec ed:constrain ;
:ed:cursor-right &ed:Col v:inc ed:constrain ;
````

## Input

````
:ed:index (-a)
  &ed:Current fetch #512 *
  &ed:Row fetch #64 * +
  &ed:Col fetch + ;

:ed:control
   #8 [ ed:cursor-left ] case
  #10 [ #0 &ed:Col store &ed:Row v:inc ] case
  #13 [ #0 &ed:Col store &ed:Row v:inc ] case
 #127 [ ed:cursor-left ] case
 drop ;

:ed:insert-char
  dup chr:visible?
  [ ed:index BLOCKS + store ed:cursor-right ]
  [ ed:control ed:constrain ] choose ;
````

## Block Evaluation

The strategy here:

* Copy a token (ending with a space or end of block) to a buffer
* Interpret the buffer
* Repeat until the end of the block

````
{{
  :TIB #1471 ;
  :ed:End `0 ;
  :ed:Count `0 ;

  :getc
    BLOCKS
    &ed:Current fetch #512 * +
    &ed:End fetch +
    fetch
    &ed:End v:inc ;

  :append   (c-)  &ed:Count fetch TIB + store &ed:Count v:inc ;
  :-empty? (s-sf) dup str:length n:positive? ;
  :-end?    (-f)  &ed:End fetch #512 lt? ;
---reveal---
  :ed:token
    #0 &ed:Count store
    [ getc dup append #32 -eq? -end? and ] while
    #0 TIB &ed:Count fetch + n:dec store TIB ;
  :ed:evaluate-block
    #0 &ed:End store
    [ ed:token -empty? [ interpret ] [ drop ] choose -end? ] while ;
}}
````

## Key Handlers

### Command Mode

Command mode has a number of handlers since it's where most interactions take place.

| Key | Usage                           |
| --- | ------------------------------- |
| [   | switch to prior block           |
| ]   | switch to next block            |
| h   | move cursor left                |
| j   | move cusor down                 |
| k   | move cursor up                  |
| l   | move cursor right               |
| H   | move cursor to leftmost column  |
| J   | move cursor to last row         |
| K   | move cursor to top row          |
| L   | move cursor to rightmost column |
| q   | exit the editor                 |
| e   | evaluate the block              |
| \   | switch to insert mode           |

````
:ed:c_[ (-) ed:prior-block ;
:ed:c_] (-) ed:next-block ;
:ed:c_h (-) ed:cursor-left ;
:ed:c_j (-) ed:cursor-down ;
:ed:c_k (-) ed:cursor-up ;
:ed:c_l (-) ed:cursor-right ;
:ed:c_\ (-) ed:insert-mode ;
:ed:c_q (-) ed:quit-mode ;
:ed:c_e (-) ed:evaluate-block ed:constrain ;
:ed:c_H (-) #0 &ed:Col store ;
:ed:c_J (-) #7 &ed:Row store ;
:ed:c_K (-) #0 &ed:Row store ;
:ed:c_L (-) #63 &ed:Col store ;
````

````
:ed:c_# (n-)
  $# ed:insert-char
  n:to-string
  dup str:length [ fetch-next ed:insert-char ] times drop
  ed:cursor-right ;
:ed:c_$ (c-) $$ ed:insert-char ed:insert-char ed:cursor-right ;
:ed:c_' (s-)
  $' ed:insert-char
  dup str:length [ fetch-next ed:insert-char ] times drop
  ed:cursor-right ;
````

### Insertion Mode

This is intentionally kept to a minimal list as I don't want to restrict what can be input. Just one command, **\**, which returns to command mode.

| Key | Usage                  |
| --- | ---------------------- |
| \   | switch to insert mode  |

````
:ed:i_\ ed:command-mode ;
````


````
(------------------------------)
:nl chr:LF putc ;
:puts     (a-) [ repeat fetch-next 0; putc again ] call drop ;
:puts:n  (an-) [ fetch-next putc ] times drop ;
:putn     (n-) n:to-string puts #32 putc ;

:Count `0 ;
:line# &Count fetch dup #10 lt? [ #32 putc ] if putn &Count v:inc ;
(------------------------------)
:row (a-a)
 #32 [ fetch-next putc ] times ;
:[block]
 #0 &Count store
 &ed:Current fetch #512 * BLOCKS +
 #16 [ $| putc row nl ] times drop ;
:v nl --- [block] --- ;

(------------------------------)
:ed:line (n-a)
  #32 *
  &ed:Current fetch #512 *
  BLOCKS + + ;

:ia (slc-) swap ed:line + [ dup str:length ] dip swap copy v ;
:i  (sl-)  #0 ia ;
:ed:BLANK '                                ' ;
:el (l-)   ed:BLANK swap ed:line #32 copy v ;
:eb #0 #16 [ [ el ] sip n:inc ] times drop v ;
:ed:CB '                                ' ;
:cl (n-) ed:line ed:CB #32 copy v ;
:pl (n-) ed:CB swap ed:line #32 copy v ;
````


## The End


## Legalities

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

    Copyright (c) 2008 - 2016, Charles Childers
    Copyright (c) 2012 - 2013, Michal J Wallace
    Copyright (c) 2009 - 2011, Luke Parrish
    Copyright (c) 2009 - 2010, JGL
    Copyright (c) 2010 - 2011, Marc Simpson
    Copyright (c) 2011 - 2012, Oleksandr Kozachuk
    Copyright (c) 2010,        Jay Skeer
    Copyright (c) 2010,        Greg Copeland
    Copyright (c) 2011,        Aleksej Saushev
    Copyright (c) 2011,        Foucist
    Copyright (c) 2011,        Erturk Kocalar
    Copyright (c) 2011,        Kenneth Keating
    Copyright (c) 2011,        Ashley Feniello
    Copyright (c) 2011,        Peter Salvi
    Copyright (c) 2011,        Christian Kellermann
    Copyright (c) 2011,        Jorge Acereda
    Copyright (c) 2011,        Remy Moueza
    Copyright (c) 2012,        John M Harrison
    Copyright (c) 2012,        Todd Thomas

