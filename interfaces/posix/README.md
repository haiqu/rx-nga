# Listener for RETRO 12

The *listener* is the basic interactive interface to RETRO. It's modeled after the interfaces used in prior versions of RETRO and other Forth dialects.

## Building

### For Linux or macOS:

    make

### For Windows

You will need to extract the sources with Unu and then compile each file before linking.

    unu Listener.md > listener.c
    unu Bridge.md > bridge.c
    unu TerminalIO.md > TerminalIO.c
    unu TerminalIO-Headers.md > TerminalIO.h

Copy in nga.c and nga.h from the nga repo or the top level source directory.

Build (using mingw-gcc):

    mingw32-gcc.exe -std=c99 -Wall -pedantic  -g     -c nga.c -o nga.o
    mingw32-gcc.exe -std=c99 -Wall -pedantic  -g     -c listener.c -o listener.o
    mingw32-gcc.exe -std=c99 -Wall -pedantic  -g     -c TerminalIO.c -o TerminalIO.o -DWINDOWS
    mingw32-gcc.exe -std=c99 -Wall -pedantic  -g     -c bridge.c -o bridge.o
    mingw32-g++.exe  -o listener.exe nga.o listener.o bridge.o TerminalIO.o

## Other Notes

You will need a copy of ngaImage in the same directory to run this.

