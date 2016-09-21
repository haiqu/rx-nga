# Rx Standard Library

Rx is intended to be a clean, minimal base for experimental work. As such, the core language it provides is very small, with a handful of flow and stack control functions, and the essential bits for compiling and interpreting code. The *Rx Standard Library* provides a significantly expanded set of additional functions to help make Rx more useful as a Forth environment.

## Additional Prefixes

````
````

## Stack Shufflers

````
:rot push swap pop swap ;
:-rot swap push swap pop ;
````

## Variables

````
:on #-1 swap store ;
:off #0 swap store ;
:+! dup push fetch + pop store ;
:-! dup push fetch swap - pop store ;
````

````
:words &dictionary begin fetch 0; dup d:name puts #32 putc again ;
````

## Compiler

````
:d:reclass &Dictionary fetch d:class store ;
:macro &.macro d:reclass ;
:data &.data d:reclass ;
````

## I/O

````
:TIB `4096
:getToken #32 #2048 &TIB gets ;
````

variable SAFE
variable LATEST

: (reset-$)  SCRATCH-START # SAFE # !, ;
: (next)     1 # SAFE # +! ;
: (save)     repeat @+ 0; SAFE # @, !, (next) again ;

: tempString  ( a-a )
  (reset-$) (save) drop, 0 # SAFE # @, !, SCRATCH-START # ;

