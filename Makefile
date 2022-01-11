all: build

build:
	zig build

install:
	zig build -Drelease
	sudo install -s ./zig-out/bin/caps-esc /usr/local/bin

clean:
	rm -rf zig-out
	rm -rf zig-cache
