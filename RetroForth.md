# RETRO 12

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
| #      | numbers                |
| &amp;  | pointers               |
| $      | characters             |

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
| 522751          | temporary strings (12 * 128) |
| 524287          | end of memory                |

````
:EOM       #524287 ;
:STRINGS   EOM #12 #128 * - ;
````

## Stack Comments

Retro provides a **(** prefix for stack comments. This will be used by all subsequent words so it comes first.

Example:

    (n-)

````
:prefix:( drop ;
  &class:macro
  &Dictionary fetch d:class store
````

## Dictionary

````
:d:last (-d) &Dictionary fetch ;
:d:last<xt> (-a) d:last d:xt fetch ;
:d:last<class> (-a) d:last d:class fetch ;
:d:last<name> (-s) d:last d:name ;
````

## Changing Word Classes

In implementing **prefix:(** a messy sequence follows the definition:

    &class:macro &Dictionary fetch d:class store

This is used to change the class from **class:word** to **class:macro**. Doing this is ugly and not very readable. The next few words provide easier means of changing the class of the most recently defined word.

````
:reclass    (a-) d:last d:class store ;
:immediate  (-)  &class:macro reclass ;
:data       (-)  &class:data reclass ;
````

## Compiler

````
:here  (-a) &Heap fetch ;
:compile:lit  (a-) #1 , , ;
:compile:jump (a-) compile:lit #7 , ;
:compile:call (a-) compile:lit #8 , ;
:compile:ret  (-)  #10 , ;
````

## Inlining

````
:prefix:` (s-) &Compiler fetch [ str:to-number , ] [ drop ] choose ; immediate
````

## Support for Variables, Constants

These aren't really useful until the **str:** namespace is compiled later on. With strings and the **'** prefix:

| To create a                  | Use a form like    |
| ---------------------------- | ------------------ |
| Variable                     | 'Base var`         |
| Variable, with initial value | `#10 'Base var<n>` |
| Constant                     | `#-1 'TRUE const`  |

````
:d:create (s-)
  (s-) &class:data #0 d:add-header
  here d:last d:xt store ;
:var    (s-)  d:create #0 , ;
:var<n> (ns-) d:create , ;
:const  (ns-) d:create d:last d:xt store ;
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

## Flow

Execute quote until quote returns a flag of 0.

````
:while  (q-)  [ repeat dup dip swap 0; drop again ] call drop ;
````

Execute quote until quote returns a flag of -1.

````
:until  (q-)  [ repeat dup dip swap #-1 xor 0; drop again ] call drop ;
````

The **times** combinator runs a quote (n) times.

````
:times  (q-)  swap [ repeat 0; #1 - push &call sip pop again ] call drop ;
````

## ...

````
:compiling?  (-f)  &Compiler fetch ;
````

## Stack Queries &amp; Cleaning

````
:depth (-n) #-1 fetch ;
:reset (...-) depth [ drop ] times ;
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
:n:pow     (bp-n)  #1 swap [ over * ] times nip ;
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

If you need to update a stored variable there are two typical forms:

    #1 'Next var<n>
    &Next fetch #10 * &Next store

Or:

    #1 'Next var<n>
    &Next [ fetch #10 * ] sip store

The **v:update-using** replaces this with:

    #1 'Next var<n>
    &Next [ #10 * ] v:update-using

It takes care of preserving the variable address, fetching the stored value, and updating with the resulting value.

````
:v:update-using (aq-) swap [ fetch swap call ] sip store ;
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
:{{ d:last dup &ScopeList store-next store ;
:---reveal--- d:last &ScopeList n:inc store ;
:}} &ScopeList fetch-next swap fetch eq? [ &ScopeList fetch &Dictionary store ] [ &ScopeList fetch [ &Dictionary repeat fetch dup fetch &ScopeList n:inc fetch -eq? 0; drop again ] call store ] choose ;
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
  :str:next    (-) &str:Current v:inc &str:Current fetch #12 eq? [ #0 &str:Current store ] if ;
---reveal---
  :str:temp (s-s) dup str:length n:inc str:pointer swap copy str:pointer str:next ;
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
:str:keep (s-s) compiling? [ &str:skip class:word ] if here [ s, ] dip class:data ;
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
:str:prepend (ss-s)
  str:temp [ dup str:length + [ dup str:length n:inc ] dip swap copy ] sip ;
:str:append (ss-s) swap str:prepend ;
````

````
{{
  :Needle `0 ; data
---reveal---
  :str:has-char?  (sc-f)
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
:chr:to-string    (c-s) '. str:temp [ store ] sip ;
:chr:visible?     (c-f) #31 #126 n:between? ;
````

## Number to String

Convert a decimal (base 10) number to a string.

````
{{
  :Value `0 ;
---reveal---
  :n:to-string  (n-s)
    here buffer:set dup &Value store n:abs
    [ #10 /mod swap $0 + buffer:add dup n:-zero? ] while drop
    &Value fetch n:negative? [ $- buffer:add ] if
    buffer:start str:reverse str:temp ;
}}
````

## Unsorted

````
:cons (nn-p) here [ swap , , ] dip ;
:curry (vp-p) here [ swap compile:lit compile:call compile:ret ] dip ;
:case
  [ over eq? ] dip swap
  [ nip call #-1 ] [ drop #0 ] choose 0; pop drop drop ;
:str:for-each (sq-)
  [ repeat
      over fetch 0; drop
      dup-pair
      [ [ [ fetch ] dip call ] dip ] dip
      [ n:inc ] dip
    again
  ] call drop-pair ;
:does (q-)
  d:last<xt> swap curry d:last d:xt store &class:word reclass ;
````

````
{{
  :SystemState `0 `0 `0 ;
---reveal---
  :mark
    &Heap  fetch &SystemState #0 + store
    d:last &SystemState #1 + store ;
  :sweep
    &SystemState #0 + fetch &Heap store
    &SystemState #1 + fetch &Dictionary store ;
}}
````

````
{{
  'Values var #8 allot
  :from str:length dup [ [ &Values + store ] sip n:dec ] times drop ;
  :to dup str:length [ fetch-next $a -  n:inc &Values + fetch swap ] times drop ;
---reveal---
  :reorder (...ss-?) [ from ] dip to ;
}}
````

## I/O

Retro really only provides one I/O function in the standard interface: pushing a character to the output log.

````
:putc (c-) `1000 ;
````

This can be used to implement words that push other item to the log.

````
:nl   (-)  chr:LF putc ;
:puts (s-) [ putc ] str:for-each ;
:putn (n-) n:to-string puts chr:SPACE putc ;
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
