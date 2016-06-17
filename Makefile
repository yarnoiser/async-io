.PHONY: clean

test:
	csi -I ./ -s tests/run.scm

clean:
	$(RM) *.so *.import.scm *.o *.c 
