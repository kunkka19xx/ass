# x86-64 Assembly with NASM — Zero to Hero

A 16-week course for this repo. Target: Linux, x86-64 (AMD), NASM, no libc
(until we deliberately add it in week 13). Budget: **2 hours per week**.

## How to use this course

Every week has the same shape:

| Segment | Time | What |
|---|---|---|
| Read | ~40 min | Concepts, explained from zero |
| Type | ~60 min | Guided example — **type it, don't paste it** |
| Solve | ~20 min | Exercises (hints at the bottom, no full solutions) |

Rules that make this actually work:

1. **Type every example by hand.** Muscle memory is half of assembly.
2. **Open gdb at least once per week** (`make debug f=...`). The debugger is
   how you *see* what the machine does; reading alone teaches you nothing here.
3. **Start each week with `make new n=wXX`** (e.g. `make new n=w03`) so every
   week leaves an artifact behind.
4. If a week doesn't fit in 2 hours, stop and continue next week. Never skip
   the exercises to "catch up" — they are the course.

## Your tools (already set up in this repo)

```sh
nix develop        # nasm, gdb, strace
make new n=w05     # new file from template.asm
make run           # assemble + run the file you edited last
make debug f=w05   # gdb, stopped at _start
make dump f=w05    # disassemble — see what nasm really produced
make trace f=w05   # strace — watch your syscalls
```

Keep [cheatsheet.md](cheatsheet.md) open in a second window. Always.

## Syllabus

### Phase 1 — Foundations (how the machine works)
| Week | Topic | You can then… |
|---|---|---|
| [01](week-01.md) | Hello, machine | explain every line of a working program |
| [02](week-02.md) | Registers & `mov` | move data anywhere, inspect it in gdb |
| [03](week-03.md) | Memory & sections | define data, read/write it, know endianness |
| [04](week-04.md) | Arithmetic & flags | add/mul/div and read RFLAGS |

### Phase 2 — Control & data (thinking in assembly)
| Week | Topic | You can then… |
|---|---|---|
| [05](week-05.md) | Branches & loops | translate if/while/for by hand |
| [06](week-06.md) | Arrays & addressing modes | walk data structures |
| [07](week-07.md) | Numbers ↔ text | **print any number** (milestone!) |
| [08](week-08.md) | The stack & functions | call/ret, recursion |

### Phase 3 — Real programs
| Week | Topic | You can then… |
|---|---|---|
| [09](week-09.md) | The System V ABI | write functions others can call |
| [10](week-10.md) | Bit manipulation | masks, shifts, bit tricks |
| [11](week-11.md) | argv & file I/O | build a working `cat` clone |
| [12](week-12.md) | String instructions | `rep movsb` and friends |

### Phase 4 — Hero
| Week | Topic | You can then… |
|---|---|---|
| [13](week-13.md) | Talking to C | call printf; be called from C |
| [14](week-14.md) | Macros & structure | organize multi-file projects |
| [15](week-15.md) | Performance & SIMD peek | time code, meet XMM registers |
| [16](week-16.md) | Capstone: hexdump | build a real utility, plan what's next |

## References you'll keep coming back to

- [Linux syscall table (x86-64 column)](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md)
- [NASM manual](https://www.nasm.us/doc/)
- [AMD64 Architecture Programmer's Manual](https://www.amd.com/en/search/documentation/hub.html) (vol. 1 & 3) — you run AMD, this is *your* CPU's spec
- [System V AMD64 ABI](https://gitlab.com/x86-psABIs/x86-64-ABI) (week 9+)
- Felix Cloutier's [instruction reference](https://www.felixcloutier.com/x86/) — fastest way to look up one instruction
