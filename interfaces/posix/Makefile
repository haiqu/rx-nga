UNU = ../../bin/unu
CC = clang
#CC = gcc
CFLAGS = -Wall

#EXT = .exe

all: s o l c

s:

	cp ../../source/cdefs.h .
	cp ../../source/ioctl.h .
	cp ../../source/termios.h .
	$(UNU) Listener.md > listener.c
	$(UNU) Editor.md > editor.c
	$(UNU) Extend.md > extend.c
	$(UNU) Bridge.md > bridge.c
	cp ../../source/nga.c .
	cp ../../source/nga.h .

o:
	$(CC) $(CFLAGS) -c nga.c -o nga.o
	$(CC) $(CFLAGS) -c listener.c -o listener.o

l:
	$(CC) $(CFLAGS) nga.o listener.o -o listener$(EXT)

c:
	rm *.c *.h *.o
