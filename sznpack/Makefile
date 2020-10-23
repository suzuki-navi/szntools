build: bin/sznpack

bin/sznpack: src/szntar.pl FORCE
	bash src/main.sh
	mkdir -p bin
	cp var/out.sh bin/sznpack

src/szntar.pl: etc/download-szntar.sh
	bash etc/download-szntar.sh > src/szntar.pl

FORCE:

