    ____   ____ ______ ____    ___
    || \\ ||    | || | || \\  // \\
    ||_// ||==    ||   ||_// ((   ))
    || \\ ||___   ||   || \\  \\_//
    a personal, minimalistic forth

## Background

Retro is a dialect of Forth. It builds on the barebones Rx core, providing a much more flexible and useful language.

Retro has a history going back many years. It began as a 16-bit assembly implementation for x86 hardware, evolved into a 32-bit system with cmForth and ColorForth influences, and eventually started supporting mainstream OSes. Later it was rewritten for a small, portable virtual machine. Over the years the language implementation has varied substantially. This is the twelfth generation of Retro. It now targets a new virtual machine (called Nga), and is built over a barebones Forth kernel (called Rx).

## Using Retro

The primary interface is a block editor. There are 384 blocks displayed as 8 rows of 64 characters. Editing is modal, using a VI style approach.

| Key | Usage                           | Mode             |
| --- | ------------------------------- | ---------------- |
| [   | switch to prior block           | Command          |
| ]   | switch to next block            | Command          |
| h   | move cursor left                | Command          |
| j   | move cusor down                 | Command          |
| k   | move cursor up                  | Command          |
| l   | move cursor right               | Command          |
| H   | move cursor to leftmost column  | Command          |
| J   | move cursor to last row         | Command          |
| K   | move cursor to top row          | Command          |
| L   | move cursor to rightmost column | Command          |
| q   | exit the editor                 | Command          |
| e   | evaluate the block              | Command          |
| #   | insert number                   | Command          |
| $   | insert ASCII character          | Command          |
| '   | insert string                   | Command          |
| \   | switch modes                    | Command / Insert |

## Interface Elements

An empty screen looks like:

    
    
    
    
    
    
    
    
    ----------------------------------------------------------------
    Free: 320892 | Heap: 5248 | 11 : 0 : 0 | C

The first eight lines display the block. Below this is a separator line, then a status line showing the current free memory, heap value, block number, row, column, and mode indicator (C for command, I for insert). Any values on the stack will be displayed below this.

## Example

Starting with an empty block:

    
    
    
    
    
    
    
    
    ----------------------------------------------------------------
    Free: 320892 | Heap: 5248 | 11 : 0 : 0 | C


Press **\** to enter insert mode and enter something:

    #12 n:square
    
    
    
    
    
    
    
    ----------------------------------------------------------------
    Free: 320892 | Heap: 5248 | 11 : 0 : 0 | I

Press **\** to return to command mode, then **e** to run the code in the block.

    #12 n:square
    
    
    
    
    
    
    
    ----------------------------------------------------------------
    Free: 320892 | Heap: 5248 | 11 : 0 : 0 | I
    < 144 >

You can then position the cursor and hit **#** to insert the value into the block:

    #12 n:square
    #144
    
    
    
    
    
    
    ----------------------------------------------------------------
    Free: 320892 | Heap: 5248 | 11 : 0 : 0 | I

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
