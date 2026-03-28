all: exe

run: exe
	@./nes-odin test-files/roms/hello_world/example.nes

exe:
	odin build . -vet -debug

