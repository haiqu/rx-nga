    ____  _   _
    || \\ \\ //
    ||_//  )x(
    || \\ // \\ 2016.09
    a minimalist forth for nga

By itself Rx provides a very minimal Forth implementation. This, the *Rx Standard Library*, extends this into a more useful language.

## Lexical Scope

The dictionary is a simple linked list. Rx allows for some control over what is visible using the **{{**, **---reveal---**, and **}}** words.

As an example:

    {{
      :increment dup fetch #1 + swap store ;
      :Value `0 ;
    ---reveal---
      :next-number &Value fetch &Value increment ;
    }}

Only the **next-number** function will remain visible once **}}** is executed.

````
:{{ &Dictionary fetch dup &ScopeList store-next store ;
:---reveal--- &Dictionary fetch &ScopeList #1 + store ;
:}} &ScopeList fetch-next swap fetch eq? [ &ScopeList fetch &Dictionary store ] [ &ScopeList fetch [ &Dictionary begin fetch dup fetch &ScopeList #1 + fetch -eq? 0; drop again ] call store ] cond ;
````

## Word Classes

Rx uses word classes to determine the behavior of functions. There are three primary classes:

* .word
* .macro
* .data

The compiler defaults to using **.word**. The functions below add support for marking words as using other classses.

````
:reclass (a-) &Dictionary fetch d:class store ;
:immediate &.macro reclass ;
:data &.data reclass ;
````

## Stack Shufflers

````
:nip (xy-y) swap drop ;
:drop-pair (nn-) drop drop ;
:?dup dup 0; ;
````


## Math

````
:/       (nq-d)  /mod swap drop ;
:mod     (nq-r)  /mod drop ;
:not     (n-n)   #-1 xor ;
:negate  (n-n)   #-1 * ;
:square  (n-n)   dup * ;
:min     (nn-n)  dup-pair lt? [ drop ] [ nip ] cond ;
:max     (nn-n)  dup-pair gt? [ drop ] [ nip ] cond ;
````

## Prefixes

This adds handy **@** and **!** prefixes that can help make code more readable. E.g.,

    &Base fetch
    @Base

    #16 &Base store
    #16 !Base

````
:compiling? &Compiler fetch ;
{{
:call, .data #8 , ;
---reveal---
:prefix:@ d:lookup d:xt fetch .data &fetch compiling? [ call, ] [ call ] cond ; immediate
:prefix:! d:lookup d:xt fetch .data &store compiling? [ call, ] [ call ] cond ; immediate
}}
````

## TORS

Short for *top of return stack*, this returns the top item on the address stack. As an analog to traditional Forth, this is equivilent to **R@**.

````
:tors pop pop dup push swap push ;
````

## Combinators

````
:dip swap push call pop ;
:sip over &call dip ;
:bi &sip dip call ;
:bi* &dip dip call ;
:bi@ dup bi* ;
:tri [ &sip dip sip ] dip call ;
:tri* [ [ swap &dip dip ] dip dip ] dip call ;
:tri@ dup dup tri* ;
````

````
:+! [ fetch + ] sip store ;
:-! [ fetch swap - ] sip store ;
:++ #1 swap +! ;
:-- #1 swap -! ;
:rot [ swap ] dip swap ;
````

## Flow

````
:while [ begin dup dip swap 0; drop again ] call drop ;
:until [ begin dup dip swap not 0; drop again ] call drop ;
:when [ over swap call ] dip swap [ call #-1 ] [ drop #0 ] cond 0; pop drop-pair ;
:whend [ over swap call ] dip swap [ nip call #-1 ] [ drop #0 ] cond 0; pop drop-pair ;
:times swap [ begin 0; #1 - push &call sip pop again ] call drop ;
````

## Strings

Hash (using DJB2)


````
:(hash) begin push #33 * pop fetch-next 0; swap push + pop again ;
:str:hash #5381 swap (hash) drop ;
````
