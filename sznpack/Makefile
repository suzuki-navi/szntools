build: bin/sznpack

# etc/sznpack: built by last version
# bin/sznpack: built by this source

bin/sznpack: src/szntar.pl var/out.2.sh
	./var/out.2.sh -o var/out.3.sh
	diff var/out.2.sh var/out.3.sh >/dev/null
	mkdir -p bin
	cp var/out.3.sh bin/sznpack

var/out.1.sh: ./etc/sznpack src/*
	mkdir -p var
	./etc/sznpack -o var/out.1.sh

var/out.2.sh: var/out.1.sh
	./var/out.1.sh -o var/out.2.sh

src/szntar.pl: ../szntar/szntar
	cp ../szntar/szntar src/szntar.pl

test: bin/sznpack FORCE
	cd test; bash ./test.sh

FORCE:

