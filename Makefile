# Usage:
#   make                build every .asm (any name, template.asm excluded)
#   make asm123         build asm123.asm -> ./asm123
#   make run            build + run the most recently edited .asm
#   make run f=hello    build + run a specific one
#   make debug f=hello  build + open in gdb, stopped at _start
#   make dump f=hello   disassemble the binary (intel syntax)
#   make trace f=hello  run under strace to watch syscalls
#   make new            create the next numbered .asm from template.asm
#   make new n=hello    create hello.asm from template.asm
#   make clean

SRCS := $(filter-out template.asm,$(wildcard *.asm))
BINS := $(SRCS:.asm=)

# default target = the .asm you touched last
f ?= $(basename $(shell ls -t $(SRCS) 2>/dev/null | head -1))

all: $(BINS)

# -g -F dwarf keeps debug info so gdb can show your source lines
%: %.asm
	nasm -f elf64 -g -F dwarf $< -o $*.o
	ld -o $@ $*.o

run: $(f)
	@./$(f); echo "[exit status: $$?]"

debug: $(f)
	gdb -q -ex 'break _start' -ex run ./$(f)

dump: $(f)
	objdump -d -M intel ./$(f)

trace: $(f)
	-strace ./$(f)

new:
	@if [ -n "$(n)" ]; then next="$(n)"; else \
		last=$$(ls *.asm 2>/dev/null | sed 's/\.asm$$//' | grep -E '^[0-9]+$$' | sort -n | tail -1); \
		next=$$(( $${last:-0} + 1 )); \
	fi; \
	if [ -e "$$next.asm" ]; then echo "$$next.asm already exists" >&2; exit 1; fi; \
	cp template.asm "$$next.asm"; \
	echo "created $$next.asm"

clean:
	rm -f *.o $(BINS)

.PHONY: all run debug dump trace new clean
