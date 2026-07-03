# Week 13 — Talking to C

**Goal:** call libc's printf from assembly and call your assembly from C.
After this week, the entire C ecosystem is your standard library — and C
code is something you can read *through*, down to the metal.

## Read (~40 min)

### Two worlds, one ABI

Week 9's System V ABI is exactly what C uses — that was the point. To mix
with C you only need three mechanical changes:

**1. gcc links you, not ld.** libc needs startup code (the *real* `_start`
comes from libc, initializes stdio, then calls…) — so you provide `main`
instead:

```sh
nasm -f elf64 -g -F dwarf w13.asm -o w13.o
gcc w13.o -o w13          # gcc = linker driver here, no C files needed
```

(This week you'll run these by hand; your Makefile speaks raw `ld` only.)

**2. `main` is just a function** — return your exit status in rax; `ret`
instead of the exit syscall (libc flushes buffers and exits for you).

**3. Position-independent code.** Modern gcc builds PIE binaries (loaded at
a random base address), so absolute addresses like `mov rdi, fmt` won't
link. Use RIP-relative addressing — put this at the top of the file and
NASM does it automatically for `[fmt]`-style operands:

```nasm
        default rel                     ; make [label] rip-relative
        ...
        lea rdi, [fmt]                  ; lea instead of mov for addresses
```

Also, calls into shared libc go through the PLT: `call printf wrt ..plt`.
(Escape hatch while learning: `gcc -no-pie w13.o -o w13` makes both
complications vanish. Do it the real way at least once, though.)

### Calling a varargs function: two new rules

`printf` takes variable arguments, which adds:

- **al** must hold the number of *vector registers* used — no floats means
  `xor eax, eax` before the call.
- **rsp must be 16-byte aligned at the call.** After `call main` pushed the
  8-byte return address you're at 8-mod-16 — one `push` fixes it (and you
  need to save something callee-saved anyway). Misalignment crashes deep
  inside libc at the first SSE instruction: know that crash signature.

```nasm
        default rel
        extern  printf
        global  main
        section .text
main:
        push rbx                    ; callee-saved AND aligns rsp. Two birds.
        lea rdi, [fmt]              ; arg 1: format string
        mov esi, 42                 ; arg 2: %d
        lea rdx, [name]             ; arg 3: %s
        xor eax, eax                ; varargs: 0 vector args
        call printf wrt ..plt
        pop rbx
        xor eax, eax                ; return 0 from main
        ret
        section .data
fmt:    db 'the answer is %d, says %s', 10, 0
name:   db 'nasm', 0
```

### The other direction — C calls you

Any label you `global` with an ABI-compliant body *is* a C function:

```nasm
        global asm_max      ; int64_t asm_max(int64_t a, int64_t b);
asm_max:
        mov rax, rdi
        cmp rsi, rax
        cmovg rax, rsi      ; conditional move — an if with no jump!
        ret
```

## Type (~60 min)

1. Type the printf example. Assemble, link with gcc, run. Then break it on
   purpose, once each way, and *file the error messages in your memory*:
   - remove `wrt ..plt` and `default rel`, link without `-no-pie` →
     relocation errors at *link* time
   - remove the `push rbx` → alignment crash at *run* time (segfault inside
     libc — `bt` in gdb shows printf internals, your first foreign backtrace)
   - remove `xor eax, eax` → possibly works, possibly garbage: that's what
     "undefined behavior" looks like from below
2. The reverse direction — write `main.c`:
   ```c
   #include <stdio.h>
   #include <stdint.h>
   int64_t asm_max(int64_t a, int64_t b);
   int main(void) { printf("%ld\n", asm_max(-5, 3)); return 0; }
   ```
   `gcc main.c asm_max.o -o mix && ./mix` → 3. Your assembly, C's plumbing.
3. Round-trip test the ABI edge: call `asm_max(-5, 3)`. If you get a huge
   number instead of 3, you wrote `ja`/`cmova` (unsigned) — week 5's trap,
   now cross-language.

## Solve (~20 min)

1. **scanf**: read a number with `scanf("%ld", &x)` — the `&x` is a .bss
   qword's address (lea, rip-relative!), and scanf's return value tells you
   if parsing worked. Print the number doubled. You've replaced week 7's
   atoi with libc's.
2. **puts vs your print_str**: link a program that uses both libc's puts
   and your lib.inc print_str (raw syscall). It works — but run it with
   stdout to a pipe (`./w13 | cat`) and the *order* of output may scramble.
   Explain why (hint: libc buffers; syscalls don't).
3. **Port a week**: take week 8's factorial and print results via printf
   with a nice format string. Feel how much boilerplate vanishes.

## Tool tip of the week

gdb works seamlessly across the boundary: `b main`, `b printf` both work
(libc has symbols). `disas printf` shows you glibc's hand-tuned assembly —
you can now *read* it. Spot the `endbr64` prologue and the alignment games.

## Check yourself

- Why `main`+`ret` instead of `_start`+exit-syscall when libc is around?
- What are the two extra rules for calling a varargs function?
- What does `default rel` change, and why do PIE binaries need it?
