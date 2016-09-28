
    ____  _   _
    || \\ \\ //
    ||_//  )x(
    || \\ // \\ 2016.09
    a minimalist forth for nga

*Rx* is an implementation of Forth for the Nga virtual machine. It's small, easy to extend, and has some unique aspects.

Like Nga this is intended to be used within a larger supporting framework adding I/O and other desired functionality. Example interface layers are included.

## General Notes on the Source

Rx is developed using a literate tool called *unu*. This allows extraction of fenced code blocks into a separate file for later compilation. Developing in a literate approach is beneficial as it makes it easier for me to keep documentation current and lets me approach the code in a more structured manner.

Since this targets Nga, it makes use of the Nga toolchain for building. The code is written in *nuance*. Nuance is a small preprocessor that converts a simple Forth-style language into assembly. I chose to do it this way to reduce the time needed to build and maintain this. Generally the syntax of Nuance is similar to the Rx language, though it adds some useful things like support for forward references. Nuance generates assembly language. This is built with *naje*, the standard Nga assembler.

The entire process of using *unu*, *nuance*, and *naje* to build an image for Nga takes around 0.1s on my Linode.

## Implementation Model

### Threading

Rx is a call threaded Forth, with some inlining optimizations. As an example:

    :square dup * #10 + ;

Compiles to:

    lit &dup
    call
    lit &*
    call
    lit 10
    lit &+
    call
    ret

### Interpreter / Compiler

Interpretation and compilation are handled via *word classes*. These are functions that decide how to execute or compile other functions based on system state. The main piece of state is the **Compiler** variable which indicates whether the classes should compile or call the functions passed to them. 

As an example, here's a simple class that can inline primitives or call a function wrapping then as needed.

    :.primitive (s-) d:lookup d:xt fetch &Compiler fetch [ fetch , ] [ call ] cond ;

And a test case for it:

    (2=nga_DUP_instruction)
    :test `2 ; &.primitive reclass

## Syntax

Rx is not a typical Forth. Drawing from Retro and Parable, it makes use of quotations and prefixes for many language elements.

### Defining a Word

Use the **:** prefix:

    :square dup * ;

### Numbers

Use the **#** prefix:

    #100
    #-33

### ASCII Characters

Use the **$** prefix:

    $h
    $i

### Pointers

Use the **&amp;** prefix:

    &+
    &notfound

### Conditionals

#### IF/ELSE

    #100 #22 eq? [ 'true ] [ 'false ] cond

#### IF TRUE

    #100 #22 eq? [ 'true ] if

#### IF FALSE

    #100 #22 eq? [ 'true ] -if

## Legalities

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

````
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
````
