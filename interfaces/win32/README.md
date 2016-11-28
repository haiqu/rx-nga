# RETRO 12 Interfaces for Win32 API

## Console

This is a terminal based interface layer.

Building:

- compile nga.c from the main source/ directory to a .o
- compile listener.c to a .o and link with the nga.o

Using a mingw-gcc:

    mingw32-gcc.exe -std=c99 -Wall -pedantic  -g     -c nga.c -o nga.o
    mingw32-gcc.exe -std=c99 -Wall -pedantic  -g     -c listener.c -o listener.o
    mingw32-g++.exe  -o RETRO12-Win32.exe nga.o listener.o

You will need a copy of ngaImage in the same directory to run this.
