d:
	@echo Targets: capi ngita rx sdk

capi: sdk rx
	./bin/naje rx.naje
	./bin/unu interfaces/C-Rx.md > c-rx.c
	cp nga/nga.c .
	$(CC) c-rx.c -DINTERACTIVE -Wall -o c-rx
	rm nga.c

clean-capi:
	rm -f c-rx.c c-rx *.log

ngita: sdk rx
	./bin/unu interfaces/Ngita-Rx.md >ngita-rx.nuance
	./bin/unu Ngita-Extend.md >ngita-extend.rx
	./bin/nuance ngita-rx.nuance >ngita-rx.naje
	cat rx.naje ngita-rx.naje >_.naje
	./bin/naje _.naje > build_ngita.log
	mv ngaImage ngita-rx.nga
	mv ngaImage.map ngita-rx.nga.map
	rm -f _.naje ngita-rx.nuance ngita-rx.naje
	cat ngita-extend.rx | ./bin/ngita ngita-rx.nga
	mv rx.nga ngita-rx.nga

clean-ngita:
	rm -f ngita-rx.nga ngita-rx.nga.map ngita-extend.rx *.log

rx: sdk
	./bin/unu Rx.md >rx.nuance
	./bin/nuance rx.nuance >rx.naje

clean-rx:
	rm -f rx.nuance rx.naje

sdk:
	cd nga && $(CC) unu.c -Wall -o ../bin/unu
	cd nga && $(CC) nga.c -DSTANDALONE -Wall -o ../bin/nga
	cd nga && $(CC) -DVERBOSE ngita.c -Wall -o ../bin/ngita
	cd nga && $(CC) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o ../bin/naje
	cd nga && $(CC) nuance.c -Wall -o ../bin/nuance

clean-sdk:
	rm -f bin/*

clean: clean-capi clean-ngita clean-rx clean-sdk
	rm -f ngaImage ngaImage.map
