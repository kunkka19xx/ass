# Week 11 — argv & file I/O

**Goal:** accept command-line arguments and read real files — by the end you
have a working `cat` clone you built from nothing.

## Read (~40 min)

### Where argv hides: on the stack, before you run

There's no `main(argc, argv)` without libc — instead, Linux places the
arguments directly on the stack before jumping to `_start`:

```
[rsp]        argc                  (a number)
[rsp + 8]    argv[0]               (pointer to program name, 0-terminated)
[rsp + 16]   argv[1]               (pointer to first real argument)
...
             NULL                  (end of argv)
             envp[0], envp[1]...   (environment, also NULL-terminated)
```

So at the very top of `_start`, before any push disturbs rsp:

```nasm
_start:
        mov r12, [rsp]          ; argc      (r12/r13: callee-saved,
        lea r13, [rsp + 8]      ; &argv[0]   safe across our calls)
        ...
        mov rdi, [r13 + 8]      ; argv[1] — familiar addressing, week 6
```

Each argv[k] is a pointer to a 0-terminated string — exactly what your
`strlen`/`print_str` already handle. Everything connects.

### File descriptors and the open/read/close trio

A file descriptor is just a small number the kernel hands you — 0/1/2 are
pre-opened as stdin/stdout/stderr, `open` returns the next one (usually 3).

| call | rax | rdi | rsi | rdx | returns (rax) |
|---|---|---|---|---|---|
| open | 2 | path (0-terminated!) | flags (O_RDONLY = 0) | mode (0 for reading) | fd, or negative |
| read | 0 | fd | buffer | max bytes | bytes read; **0 = EOF**; negative = error |
| close | 3 | fd | | | 0 or negative |

**Errors:** a failed syscall returns `-errno` — open on a missing file gives
-2 (ENOENT). Check with `cmp rax, 0` / `jl .error`. From this week on, every
syscall result gets checked; unchecked syscalls are how silent garbage
happens.

**The read loop** — the pattern behind every file tool ever written:

```
loop:  n = read(fd, buf, BUFSIZE)
       if n < 0  → error
       if n == 0 → done (EOF)
       write(1, buf, n)          ← n, not BUFSIZE!
       goto loop
```

Writing BUFSIZE instead of n on the last chunk is the classic bug — the tail
of the previous chunk leaks out. You'll make this bug on purpose below.

## Type (~60 min)

`make new n=w11` — **build cat**:

1. Read argc; if argc < 2, print a usage string to **stderr** (fd 2) and
   exit(1).
2. `open(argv[1], O_RDONLY)`; on negative rax print an error and exit(1).
3. The read loop with a `resb 4096` buffer from `.bss`.
4. `close`, `exit(0)`.

Test it properly:

```sh
make w11
./w11 w11.asm               # prints its own source — always satisfying
./w11 /etc/hostname
./w11 /does/not/exist       # your error path; echo $? → 1
./w11                       # your usage path
make trace f=w11            # ← watch open→read→write→read→…→close. Beautiful.
```

Then make the classic bug on purpose: write BUFSIZE instead of n, shrink
BUFSIZE to 16, cat a file whose size isn't a multiple of 16. Look at the
trailing garbage. Fix it back. You are now permanently immune.

gdb note: `make debug f=w11` runs with no arguments. Inside gdb:
`run w11.asm` restarts with an argument (or `set args w11.asm` once).

## Solve (~20 min)

1. **wc -c**: sum the n's from each read instead of writing them; print the
   total with print_uint. Compare against the real `wc -c`.
2. **Multi-file cat**: loop over argv[1..argc-1] — real cat takes many
   files. The argv walk is `[r13 + rcx*8]`, week 6's idiom.
3. **echo**: print each argv[k] separated by spaces, newline at the end —
   no files involved, pure argv + lib.inc. Then check the environment
   rumor: is envp *really* after argv's NULL? Print envp[0] and find out.

## Tool tip of the week

strace is the truth-teller for this entire week: `-e trace=open,openat,
read,write,close` filters the noise. Compare `strace ./w11 f` with
`strace cat f` — real cat uses openat and a bigger buffer, otherwise you
wrote the same program. (`ltrace` shows library calls — nothing, for you:
no libc. Badge of honor.)

## Check yourself

- Where is argc the moment `_start` begins? argv[1]?
- What do read's three possible return classes mean?
- Why must the write use n and not the buffer size?
