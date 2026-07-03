# Week 01 — Hello, machine

**Goal:** by the end of this week you can explain *every single line* of a
working assembly program, and you know how your program talks to Linux.

## Read (~40 min)

### The mental model

Forget variables, types, and functions for a moment. A CPU only has:

- **Registers** — 16 small named boxes inside the CPU, each holding 64 bits.
  Blazing fast. This is your entire "working memory".
- **Memory (RAM)** — a huge numbered array of bytes. Byte number = *address*.
  Slower. Your code AND your data both live here.
- **Instructions** — tiny commands like "copy this register to that one",
  "add", "jump to address X". The CPU executes them one after another.

Assembly is just these instructions written as text. NASM translates your
text 1:1 into the bytes the CPU executes. There is no magic layer — what you
write is what runs. That's the whole appeal.

### Talking to the outside world: syscalls

A CPU can compute, but it cannot print, read files, or exit — those belong to
the operating system. You ask Linux for them with the `syscall` instruction.
The contract:

1. Put the **syscall number** in `rax` (write = 1, exit = 60).
2. Put arguments in `rdi`, `rsi`, `rdx` (in that order).
3. Execute `syscall`. The kernel does the work, result comes back in `rax`.

That's it. Every program you write this course is "compute stuff, then
syscall to show it".

### Anatomy of template.asm

This is the file `make new` copies. Read it with fresh eyes:

```nasm
        BITS 64                 ; tell NASM: 64-bit instructions

        section .text           ; the code section
        global  _start          ; export the entry symbol for the linker

_start:                         ; execution begins here
        mov rax, 1              ; syscall number 1 = write
        mov rdi, 1              ; arg 1: file descriptor 1 = stdout
        mov rsi, msg            ; arg 2: address of the bytes to write
        mov rdx, msglen         ; arg 3: how many bytes
        syscall                 ; do it

        mov rax, 60             ; syscall number 60 = exit
        xor rdi, rdi            ; arg 1: status 0 (xor reg,reg = fast zero)
        syscall                 ; never returns

        section .data           ; initialized data section
        msg    db 'hello', 10   ; bytes: h e l l o \n   (10 = newline)
        msglen equ $ - msg      ; a constant: current position minus msg = 6
```

Things worth staring at:

- `msg` is not a string variable. It's a **label** — a name for an address.
  `mov rsi, msg` puts the *address* in rsi, not the letters.
- `db` means "put these literal bytes here". Text is just bytes.
- If you forget the exit syscall, the CPU runs past your code into garbage
  bytes and crashes. Try it later. Seriously — delete the exit and watch.
- Why `_start` and not `main`? `main` is a C convention; without libc the
  linker just needs *some* entry symbol, and `_start` is the default name.

### One historical trap: `int 0x80`

Your old `1.asm` uses `int 0x80` — that's the **32-bit** syscall interface
(different numbers: write=4, exit=1). It still works but truncates addresses
to 32 bits and is the wrong habit. This course uses `syscall` only.
`make trace f=1` even warns: "runs in 32 bit mode".

## Type (~60 min)

```sh
nix develop
make new n=w01     # creates w01.asm
```

1. Build and run the template as-is: `make run`. Note the `[exit status: 0]`.
2. Change the message to your name. Rebuild. Did you remember to fix the
   length? `msglen equ $ - msg` fixes itself — that's why it exists.
3. Add a **second** write syscall printing a different message. You'll need a
   second label in `.data`.
4. Change the exit status to 42: `mov rdi, 42`. Run — `make run` prints the
   status for exactly this reason.
5. Delete the exit syscall entirely. Run it. Meet your first segfault. Put it
   back.
6. Run `make trace`. You'll see your two `write`s and the `exit` exactly as
   you wrote them — strace is your syscall x-ray for the whole course.

## Solve (~20 min)

1. **Silence**: write a program that prints nothing and exits with status 7.
   (Smallest possible program — how many instructions do you need?)
2. **Off by one**: set `rdx` to 3 instead of the real length. What prints?
   Now set it to 100. What prints, and *why didn't it crash*? (Peek at what
   comes after your message in memory: `make dump` shows section layout.)
3. **Descriptor field trip**: write your message to fd **2** (stderr) instead
   of 1. Prove the difference: `./w01 > /dev/null` — message still visible?

## Tool tip of the week

`make dump f=w01` shows the disassembly of your binary. Compare it with your
source: every line of yours became exactly one instruction. Keep checking
this all course — it builds the "no magic" intuition.

## Check yourself

- What is in `rsi` during the write syscall — the text or an address?
- Why does the program crash without exit?
- Which register carries the syscall number? The return value?
