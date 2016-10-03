CC = clang-3.5
CFLAGS = -Wall

d:
	@echo Targets: capi ngita rx sdk stl

stl: sdk
	./bin/unu StandardLibrary.md > startup.rx

capi: clean sdk stl rx
	./bin/naje rx.naje
	./bin/unu interfaces/C-Rx.md > c-rx.c
	cp nga/nga.c .
	$(CC) $(CFLAGS) c-rx.c -DINTERACTIVE -o c-rx
	rm nga.c

clean-capi:
	rm -f c-rx.c c-rx *.log

ngita: clean sdk rx stl
	./bin/unu interfaces/Ngita-Rx.md >ngita-rx.nuance
	./bin/unu Ngita-Extend.md >ngita-extend.rx
	./bin/nuance ngita-rx.nuance >ngita-rx.naje
	cat rx.naje ngita-rx.naje >_.naje
	./bin/naje _.naje > build_ngita.log
	rm -f _.naje ngita-rx.nuance ngita-rx.naje
	cat startup.rx ngita-extend.rx | ./bin/ngita
	mv rx.nga ngaImage

clean-ngita:
	rm -f ngaImage ngaImage.map ngita-extend.rx *.log

rx: sdk
	./bin/unu Rx.md >rx.nuance
	./bin/nuance rx.nuance >rx.naje

clean-rx:
	rm -f rx.nuance rx.naje

sdk:
	cd nga && $(CC) $(CFLAGS) unu.c -o ../bin/unu
	cd nga && $(CC) $(CFLAGS) nga.c -DSTANDALONE -o ../bin/nga
	cd nga && $(CC) $(CFLAGS) -DVERBOSE ngita.c -o ../bin/ngita
	cd nga && $(CC) $(CFLAGS) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -o ../bin/naje
	cd nga && $(CC) $(CFLAGS) nuance.c -o ../bin/nuance

clean-sdk:
	rm -f bin/*

clean: clean-capi clean-ngita clean-rx clean-sdk
	rm -f ngaImage ngaImage.map
