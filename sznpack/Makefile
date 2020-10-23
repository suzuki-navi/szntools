build: bin/sznpack

# etc/sznpack: built by last version
# bin/sznpack: built by this source

bin/sznpack: src/szntar.pl var/out.2.sh
	./var/out.2.sh
	diff var/out.sh var/out.2.sh >/dev/null
	mv var/out.sh var/out.3.sh
	mkdir -p bin
	cp var/out.3.sh bin/sznpack

var/out.1.sh: FORCE
	./etc/sznpack
	mv var/out.sh var/out.1.sh

var/out.2.sh: var/out.1.sh
	./var/out.1.sh
	mv var/out.sh var/out.2.sh

src/szntar.pl: etc/download-szntar.sh
	bash etc/download-szntar.sh > src/szntar.pl

FORCE:

