build: bin/sznpack

# etc/sznpack: built by last version
# bin/sznpack: built by this source

bin/sznpack: src/szntar.pl FORCE
	./etc/sznpack
	mkdir -p bin
	cp var/out.sh bin/sznpack

src/szntar.pl: etc/download-szntar.sh
	bash etc/download-szntar.sh > src/szntar.pl

FORCE:

