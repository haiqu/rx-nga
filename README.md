
    ____  _   _
    || \\ \\ //
    ||_//  )x(
    || \\ // \\ 2016.10
    a minimalist forth for nga

*Rx* is an implementation of Forth for the Nga virtual machine. It's small, easy to extend, and has some unique aspects.

Like Nga this is intended to be used within a larger supporting framework adding I/O and other desired functionality. Example interface layers are included.

## General Notes on the Source

Rx is developed using a literate tool called *unu*. This allows extraction of fenced code blocks into a separate file for later compilation. Developing in a literate approach is beneficial as it makes it easier for me to keep documentation current and lets me approach the code in a more structured manner.

Since this targets Nga, it makes use of the Nga toolchain for building. The code is written in *nuance*. Nuance is a small preprocessor that converts a simple Forth-style language into assembly. I chose to do it this way to reduce the time needed to build and maintain this. Generally the syntax of Nuance is similar to the Rx language, though it adds some useful things like support for forward references. Nuance generates assembly language. This is built with *naje*, the standard Nga assembler.

The entire process of using *unu*, *nuance*, and *naje* to build an image for Nga takes around 0.1s on my Linode.

## Legalities

Rx is Copyright (c) 2016, Charles Childers

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

My thanks go out to Michal J Wallace, Luke Parrish, JGL, Marc Simpson, Oleksandr Kozachuk, Jay Skeer, Greg Copeland, Aleksej Saushev, Foucist, Erturk Kocalar, Kenneth Keating, Ashley Feniello, Peter Salvi, Christian Kellermann, Jorge Acereda, Remy Moueza, John M Harrison, and Todd Thomas. All of these great people helped in the development of Retro 10 & 11, without which Rx wouldn't have been possible.
