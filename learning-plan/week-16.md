# Week 16 — Capstone: hexdump

**Goal:** build a real, useful utility from scratch — no guided code this
time. Then look back at how far you've come, and choose what's next.

## The mission

Build `hexdump`: dump any file as offset + hex bytes + ASCII, like
`xxd` / `hexdump -C`:

```
00000000  7f 45 4c 46 02 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
00000010  02 00 3e 00 01 00 00 00  78 00 40 00 00 00 00 00  |..>.....x.@.....|
```

Spec:

- `./hexdump FILE` — usage message on stderr + exit(1) if no argument
- each line: 8-hex-digit offset, 16 bytes as 2-digit hex (extra gap after
  8, like above), then the bytes as ASCII in `|…|` — printable characters
  (32–126) as themselves, everything else as `.`
- a short final line handles files whose size isn't a multiple of 16
  (align the `|` column by padding the hex area with spaces)
- errors from open/read handled; exit(0) on success

Check your output against the real tool: `diff <(./hexdump f) <(xxd -g1 f
| tr -s ' ')` won't match byte-for-byte — eyeball instead, or match
`hexdump -C` minus its duplicate-line `*` folding. Your own source, your
binary (`./hexdump hexdump`!), and `/etc/os-release` make good test files.

## You already own every piece

| Piece | Week |
|---|---|
| argv, usage to stderr | 11 |
| open / read-loop / close, error checks | 11 |
| print_hex (nibble → hex digit) | 10 |
| byte loads, buffers, addressing | 3, 6 |
| printable-range check (cmp 32 / cmp 126) | 5 |
| building an output line in a buffer, one write per line | 7 |
| functions, ABI, lib.o linking | 8, 9, 14 |
| macros for the boilerplate | 14 |

Suggested build order (each step runs and shows progress — never code blind
for an hour):

1. cat clone skeleton from week 11, reading 16 bytes at a time
2. print each chunk as raw hex pairs — no formatting (print_hex earns rent)
3. add the offset column (it's just a counter — print it as 8 hex digits)
4. add the ASCII gutter
5. gaps, padding, the short final line — the fiddly 20% that is 80%
6. polish: error messages that name the file (strlen + a few writes)

Estimated effort: 2 sessions. It's the point of the course — take the time.

## Debug like it's week 16, not week 1

- `make trace` on a small file first: are your reads/writes sane?
- format bugs: `./hexdump f | head -2` and stare; the bug is always the
  off-by-one in padding (everyone's is)
- `b` on your line-formatting function, `x/80cb` on the line buffer before
  the write — see the line as bytes before it ships

## Afterwards: the roadmap out

You now genuinely read and write x86-64 assembly. Directions, pick by pull:

**Go deeper on the metal**
- *AMD64 Architecture Programmer's Manual vol. 1–3* — your CPU's actual spec
- Agner Fog's optimization manuals (agner.org) — the performance bible
- AVX2/AVX-512: week 15's taste, as a meal

**Read the world's assembly** (superpower, immediately useful)
- godbolt.org — type C, watch the compiler's asm; guess-then-check
- `objdump -d` anything on your system; you'll recognize the idioms now
- Reverse engineering: crackmes.one, then Ghidra + your gdb skills

**Systems from below**
- *Programming from the Ground Up* — your README's original plan; it'll be
  a fast, confirming read now (it's 32-bit — you'll translate on the fly,
  which is itself a skill)
- write a tiny shell (fork/execve/wait syscalls — you know the calling side)
- OSDev wiki: a boot sector is ~512 bytes of real-mode asm; "hello world
  without an OS" is a weekend and a revelation

**Or go sideways**
- RISC-V assembly: learn a *clean* ISA and appreciate/curse x86 properly
- ARM64: your phone runs it; the register model will feel luxurious

One last habit to keep: whenever any language hands you something
"magic" — a closure, a syscall wrapper, a channel — you now have the tools
to `make dump` your way to what it really is. Use them.

— end of course. `make new n=whatever` and keep going. 🎓
