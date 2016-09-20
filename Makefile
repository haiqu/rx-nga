d: c buildnga buildrx

buildrx:
	./bin/unu Rx.md >rx.nuance
	./bin/unu Lib.md >lib.rx
	./bin/nuance rx.nuance >rx.naje
	./bin/naje rx.naje

buildnga:
	cd nga && $(CC) unu.c -Wall -o ../bin/unu
	cd nga && $(CC) nga.c -DSTANDALONE -Wall -o ../bin/nga
	cd nga && $(CC) -DVERBOSE ngita.c -Wall -o ../bin/ngita
	cd nga && $(CC) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o ../bin/naje
	cd nga && $(CC) nuance.c -Wall -o ../bin/nuance

buildcounts: c buildnga buildrx
	./bin/naje rx.naje | tail -n 1 | sed 's/ /\n/g' | sed 's/\^/\t/g' >rx.refcounts

c:
	rm -f bin/*
	rm -f rx.nuance
	rm -f rx.naje
