f ?= main

all:
	nasm -f elf64 $(f).asm -o $(f).o
	ld -s -o $(f) $(f).o
	./$(f)

clean:
	rm -f *.o $(f)
