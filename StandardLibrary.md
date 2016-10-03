    ____  _   _
    || \\ \\ //
    ||_//  )x(
    || \\ // \\ 2016.10
    a minimalist forth for nga

By itself Rx provides a very minimal Forth implementation. This, the *Rx Standard Library*, extends this into a more useful language.

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

Now we can do useful things like:

    :Red   #0 ; data
    :Green #1 ; data
    :Blue  #2 ; data

    :inline-100 &Compiler fetch [ #1 , #100 , ] [ #100 ] choose ; immediate

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
:nip       (xy-y) swap drop ;
:drop-pair (nn-) drop drop ;
:?dup dup 0; ;
:rot [ swap ] dip swap ;
````

Short for *top of return stack*, this returns the top item on the address stack. As an analog to traditional Forth, this is equivilent to **R@**.

````
:tors pop pop dup push swap push ;
````

## Math

The core Rx language provides addition, subtraction, multiplication, and a combined division/remainder. The standard library expands on this.

````
:/       (nq-d)  /mod swap drop ;
:mod     (nq-r)  /mod drop ;
:not     (n-n)   #-1 xor ;
:negate  (n-n)   #-1 * ;
:square  (n-n)   dup * ;
:min     (nn-n)  dup-pair lt? [ drop ] [ nip ] choose ;
:max     (nn-n)  dup-pair gt? [ drop ] [ nip ] choose ;
````

## Memory

````
:+!  (na-)  [ fetch + ] sip store ;
:-!  (na-)  [ fetch swap - ] sip store ;
:++      (n-n)   #1 swap +! ;
:--      (n-n)   #1 swap -! ;
````

## Prefixes

This adds handy **@** and **!** prefixes that can help make code more readable. E.g.,

    &Base fetch
    @Base

    #16 &Base store
    #16 !Base

````
:call, .data #8 , ;
:prefix:@ d:lookup d:xt fetch .data &fetch compiling? [ call, ] [ call ] choose ; immediate
:prefix:! d:lookup d:xt fetch .data &store compiling? [ call, ] [ call ] choose ; immediate
````

## Flow

Execute quote until quote returns a flag of 0.

````
:while [ repeat dup dip swap 0; drop again ] call drop ;
````

Execute quote until quote returns a flag of -1.

````
:until [ repeat dup dip swap not 0; drop again ] call drop ;
````

The **times** combinator runs a quote (n) times.

````
:times swap [ repeat 0; #1 - push &call sip pop again ] call drop ;
````

## Strings

Hash (using DJB2)

````
:<str:hash> repeat push #33 * pop fetch-next 0; swap push + pop again ;
:str:hash  (s-n)  #5381 swap <str:hash> drop ;
````
