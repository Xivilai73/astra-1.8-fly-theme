.PHONY: all deb install uninstall clean

all: deb

deb:
	./build-deb.sh

install:
	./install.sh

uninstall:
	./uninstall.sh

clean:
	rm -rf dist
