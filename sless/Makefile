build: bin/sless

bin/sless: ../sznpack/etc/sznpack src/*
	mkdir -p bin
	bash ../sznpack/etc/sznpack -o bin/sless

test: bin/sless FORCE
	cd test; bash ./test.sh

FORCE:

