# Week 02 — Registers & `mov`

**Goal:** know all 16 registers and their sub-register names, move data
between them confidently, and drive gdb well enough to watch it happen.

## Read (~40 min)

### The register file

You have 16 general-purpose 64-bit registers:

```
rax rbx rcx rdx rsi rdi rbp rsp r8 r9 r10 r11 r12 r13 r14 r15
```

"General-purpose" means you *can* use any of them for anything — but
conventions give them roles (see the cheatsheet table). Two are special in
practice: `rsp` (stack pointer — leave it alone until week 8) and `rbp`
(frame pointer by convention).

### Sub-registers: one box, four names

Each register can be addressed at four widths. For `rax`:

```
|63                              32|31             16|15     8|7      0|
|                                  |                 |   ah   |   al   |
|                                  |                 |        ax       |
|                                  |            eax                    |
|                                   rax                                |
```

- `al` = low byte, `ax` = low 2 bytes, `eax` = low 4 bytes, `rax` = all 8.
- Same pattern everywhere: `rbx/ebx/bx/bl`, `r8/r8d/r8w/r8b`, `rsi/esi/si/sil`.
- Only the four classic registers a/b/c/d have a *high-byte* name (`ah` etc.);
  you'll rarely use those.

### The rule that bites everyone

> Writing a **32-bit** register **zeroes the upper 32 bits**.
> Writing an 8- or 16-bit register **leaves the rest untouched**.

```nasm
mov rax, 0xFFFFFFFFFFFFFFFF
mov eax, 5          ; rax is now 5 — top 32 bits WIPED
mov rax, 0xFFFFFFFFFFFFFFFF
mov al, 5           ; rax is now 0xFFFFFFFFFFFFFF05 — rest kept
```

This is why you'll see compilers emit `mov eax, 1` instead of `mov rax, 1`:
it's a shorter instruction *and* it clears the whole register. Free trick:
`xor edi, edi` zeroes all of rdi.

### What `mov` can and cannot do

```nasm
mov rax, rbx        ; reg ← reg          ok
mov rax, 42         ; reg ← immediate    ok (even 64-bit immediates)
mov rax, [label]    ; reg ← memory       ok (week 3)
mov [label], rax    ; memory ← reg       ok
mov [a], [b]        ; memory ← memory    ✗ IMPOSSIBLE — go via a register
mov qword [a], big64constant ;           ✗ imm64→mem impossible (your 4.asm bug!)
```

`mov` never touches flags and never computes — it only copies. Also meet:

```nasm
xchg rax, rbx       ; swap two registers, one instruction
movzx rax, bl       ; copy 8→64 bits, zero-extending
movsx rax, bl       ; copy 8→64 bits, SIGN-extending (week 4 explains sign)
```

## Type (~60 min)

`make new n=w02`. Write a program that is *pure register shuffling* — no
output at all, ending in exit. For example:

```nasm
_start:
        mov rax, 0x1122334455667788
        mov rbx, rax
        mov ecx, ebx        ; what happens to the top of rcx?
        mov dl, bl          ; and to the rest of rdx?
        xchg rax, rbx
        movzx rsi, dl
        mov rax, 60
        xor rdi, rdi
        syscall
```

Now *watch it run* — this is the real lesson of the week:

```sh
make debug f=w02
```

gdb is stopped at `_start`. Drive it:

```
layout asm          ; see your instructions
layout regs         ; add live register view
si                  ; step ONE instruction — watch the regs change
p/x $rcx            ; print rcx in hex
i r rax rbx rcx rdx ; a few registers at once
```

Before each `si`, **predict** what the next instruction does to which
register. Say it out loud. Then step and check. Do this for the whole
program. Being wrong here is the fastest learning in the entire course.

## Solve (~20 min)

1. **Prediction game**: without running, write down rax after:
   ```nasm
   mov rax, -1
   mov eax, 0
   mov al, 0xFF
   ```
   Then verify in gdb. (Hint: -1 in a register is all bits set.)
2. **Three-register rotate**: given values in rax, rbx, rcx, rotate them
   (rax→rbx→rcx→rax) using exactly one spare register — then again using
   `xchg` and *no* spare register.
3. **Exit-code smuggling**: put 300 in `rdi` and exit with it. What status
   does `make run` report, and why? (Cheatsheet knows.)

## Tool tip of the week

`starti` inside plain gdb starts a program stopped at the very first
instruction — but `make debug` already breaks at `_start` for you. Add
`display/x $rax` and gdb reprints rax after every step: perfect for the
prediction game.

## Check yourself

- What does `mov eax, 5` do to the top half of rax? And `mov al, 5`?
- Why is `xor edi, edi` enough to zero all 64 bits of rdi?
- Which two operand combinations can `mov` *not* do?
