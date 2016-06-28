.PHONY: clean

SRC=async-io.scm async-io.setup async-io.meta

default: build

build: $(SRC)
	chicken-install -n

install: $(SRC)
	chicken-install

uninstall:
	chicken-uninstall cooperative

test: build tests/run.scm
	csi -I ./ -s tests/run.scm

clean:
	$(RM) *.so *.import.scm *.o *.c salmonella.log

