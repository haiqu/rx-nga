    ____  _   _
    || \\ \\ //
    ||_//  )x(
    || \\ // \\ 2016.10
    a minimalist forth for nga

By itself Rx provides a very minimal Forth implementation. This, the *Rx Standard Library*, extends this into a more useful language.

## Stack Comments

The standard library provides a **(** prefix for stack comments. This will be used by all subsequent words so it comes first.

Example:

    (n-)

````
:prefix:( drop ; &class:macro &Dictionary fetch d:class store
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

Rx makes use of anonymous functions called *quotations* for much of the execution flow and stack control. The words that operate on these quotations are called *combinators*.

The standard library provides a number of these.

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

The core Rx language provides addition, subtraction, multiplication, and a combined division/remainder. The standard library expands on this.

````
:/       (nq-d)  /mod swap drop ;
:mod     (nq-r)  /mod drop ;
:not     (n-n)   #-1 xor ;
:n:negate  (n-n)   #-1 * ;
:n:square  (n-n)   dup * ;
:n:min     (nn-n)  dup-pair lt? [ drop ] [ nip ] choose ;
:n:max     (nn-n)  dup-pair gt? [ drop ] [ nip ] choose ;
:n:abs     (n-n)   dup n:negate n:max ;
:n:limit   (nlu-n) swap push n:min pop n:max ;
:n:inc     (n-n)   #1 + ;
:n:dec     (n-n)   #1 - ;
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

The dictionary is a simple linked list. Rx allows for some control over what is visible using the **{{**, **---reveal---**, and **}}** words.

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

## Strings

Hash (using DJB2)

````
{{
  :<str:hash> repeat push #33 * pop fetch-next 0; swap push + pop again ;
---reveal---
  :str:hash  (s-n)  #5381 swap <str:hash> drop ;
}}
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

Temporary strings are allocated in a circular pool.

````
{{
  :str:MAX-LENGTH #128 ;
  :str:POOL-SIZE  #12 ;
  :str:Current `0 ; data
  :str:Pool `0 ; data  str:MAX-LENGTH str:POOL-SIZE * allot

  :str:pointer (-p)  &str:Current fetch str:MAX-LENGTH * &str:Pool + ;
  :str:next (-) #1 &str:Current v:inc-by &str:Current fetch #12 eq? [ #0 &str:Current store ] if ;
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
:str:skip pop [ fetch-next #0 -eq? ] while n:dec push ;
:str:keep compiling? [ &str:skip class:word ] if &Heap fetch [ s, ] dip class:data ;
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
:n:pow  (bp-n)  #1 swap [ over * ] times nip ;
:n:between? (nul-) rot [ rot rot n:limit ] sip eq? ;
````

## Characters

````
:chr:letter?      (c-f) $A $z n:between? ;
:chr:lowercase?   (c-f) $a $z n:between? ;
:chr:uppercase?   (c-f) $A $Z n:between? ;
:chr:digit?       (c-f) $0 $9 n:between? ;
:chr:whitespace?  (c-f) [ #32 eq? ] [ #9 eq? ] [ [ #10 eq? ] [ #13 eq? ] bi or ] tri or or ;
:chr:to-upper     (c-f) #32 - ;
:chr:to-lower     (c-f) #32 + ;
:chr:to-string    (c-f) '.' dup store str:temp ;
:chr:visible?     (c-f) #31 #126 n:between? ;
````

## Unsorted

````
:cons (nn-p) &Heap fetch [ swap , , ] dip ;
:curry (vp-p) &Heap fetch [ swap compile:lit compile:call compile:ret ] dip ;
:case
  [ over eq? ] dip swap
  [ nip call #-1 ] [ drop #0 ] choose 0; pop drop drop ;
````

## Legalities

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above     Copyright notice and this permission notice appear in all
copies.

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