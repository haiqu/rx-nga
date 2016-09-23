# Rx: a minimal Forth for Nga

*Rx* (*retro experimental*) is a minimal Forth implementation for the Nga virtual machine. Like Nga this is intended to be used within a larger supporting framework adding I/O and other desired functionality. Example interface layers are included.

## General Notes on the Source

Rx is developed using a literate tool called *unu*. This allows extraction of fenced code blocks into a separate file for later compilation. Developing in a literate approach is beneficial as it makes it easier for me to keep documentation current and lets me approach the code in a more structured manner.

The code is written in *nuance*. Nuance is a small preprocessor that converts a simple Forth-style language into assembly. I chose to do it this way to reduce the time needed to build and maintain this. Generally the syntax of Nuance is similar to the Rx language, though it adds some useful things like support for forward references.

Nuance generates assembly language. This is built with *naje*, the standard Nga assembler.

The entire process of using *unu*, *nuance*, and *naje* to build an image for Nga takes around 0.1s on my Linode.

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

