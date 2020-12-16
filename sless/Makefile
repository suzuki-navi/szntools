build: bin/sless

bin/sless: etc/sznpack.sh src/*
	mkdir -p bin
	bash ./etc/sznpack.sh -o bin/sless

etc/sznpack.sh: ../sznpack/etc/sznpack
	cp ../sznpack/etc/sznpack etc/sznpack.sh

test: bin/sless FORCE
	cd test; bash ./test.sh

FORCE:

