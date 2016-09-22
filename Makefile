d: c buildnga rx lib ngita

ngita:
	./bin/unu Ngita-Rx.md >ngita-rx.nuance
	./bin/nuance ngita-rx.nuance >ngita-rx.naje
	./bin/unu Ngita-Extend.md >ngita-extend.rx
	cat rx.naje ngita-rx.naje >_.naje
	./bin/naje _.naje
	mv ngaImage ngita-rx.nga
	mv ngaImage.map ngita-rx.nga.map
	rm -f _.naje ngita-rx.nuance ngita-rx.naje
	cat ngita-extend.rx | ./bin/ngita ngita-rx.nga
	mv rx.nga ngita-rx.nga

rx:
	./bin/unu Rx.md >rx.nuance
	./bin/nuance rx.nuance >rx.naje

lib:
	./bin/unu Lib.md >lib.rx

buildnga:
	cd nga && $(CC) unu.c -Wall -o ../bin/unu
	cd nga && $(CC) nga.c -DSTANDALONE -Wall -o ../bin/nga
	cd nga && $(CC) -DVERBOSE ngita.c -Wall -o ../bin/ngita
	cd nga && $(CC) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o ../bin/naje
	cd nga && $(CC) nuance.c -Wall -o ../bin/nuance

c:
	rm -f bin/*
	rm -f rx.nuance
	rm -f rx.naje
	rm -f lib.rx
