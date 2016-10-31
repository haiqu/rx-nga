CC = clang-3.5
CFLAGS = -Wall

c: ax t i s o l ex

i:
	./bin/unu Rx.md >rx.naje
	./bin/naje rx.naje >rx.log

s:
	./bin/unu interfaces/C-Rx.md > c-rx.c
	./bin/unu Editor.md >editor.c
	./bin/unu Extend.md >extend.c
	./bin/unu Listener.md >listener.c
	./bin/unu RetroForth.md > retro.forth

o:
	$(CC) $(CFLAGS) -c nga/nga.c -o nga.o
	$(CC) $(CFLAGS) -c listener.c -o listener.o
	$(CC) $(CFLAGS) -c extend.c -o extend.o
	$(CC) $(CFLAGS) -c editor.c -o editor.o

l:
	$(CC) nga.o listener.o -o listener
	$(CC) nga.o extend.o -o extend
	$(CC) nga.o editor.o -o editor

x:
	rm -f bin/*
	rm -f c-rx.c c-rx *.log
	rm -f *.c
	rm -f *.o

ax: x
	rm -f rx.naje ngaImage ngaImage.map rx.log retro.forth

t:
	cd nga && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	cd nga && $(CC) $(CFLAGS) nga.c -DSTANDALONE -o ../bin/nga
	cd nga && $(CC) $(CFLAGS) -DVERBOSE ngita.c -o ../bin/ngita
	cd nga && $(CC) $(CFLAGS) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -o ../bin/naje

ex:
	./extend

