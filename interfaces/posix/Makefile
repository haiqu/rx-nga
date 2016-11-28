UNU = ../../bin/unu
CC = clang
CFLAGS = -Wall

all: s o l c

s:
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
	$(CC) $(CFLAGS) nga.o listener.o -o listener

c:
	rm *.c *.h *.o
