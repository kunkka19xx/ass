# Week 10 — Bit manipulation

**Goal:** treat a register as 64 individual switches: mask, set, clear,
test, and shift them — the vocabulary of flags, permissions, protocols, and
every low-level format you'll ever parse.

## Read (~40 min)

### The logic family

```nasm
and rax, rbx        ; 1 where BOTH are 1        → masking (keep some bits)
or  rax, rbx        ; 1 where EITHER is 1       → setting bits
xor rax, rbx        ; 1 where they DIFFER       → toggling / zeroing
not rax             ; flip every bit            (touches NO flags — the rebel)
```

The idioms, which you should read as words, not operations:

```nasm
and rax, 0xFF           ; "keep the low byte" (clear the rest)
and rax, ~0x10          ; "clear bit 4"        (~ done by you, at write time)
or  rax, 0x10           ; "set bit 4"
xor rax, 0x10           ; "flip bit 4"
test rax, 0x10          ; "is bit 4 set?" — and + flags, no result (week 5!)
xor eax, eax            ; "zero rax" — you've written this since week 1
```

### Shifts: movement and arithmetic at once

```nasm
shl rax, 3          ; shift left  — multiply by 8; bits fall off the top
shr rax, 3          ; LOGICAL right  — divide UNSIGNED by 8; zeros come in
sar rax, 3          ; ARITHMETIC right — divide SIGNED by 8; sign bit repeats
rol/ror rax, 3      ; rotate — fallen bits come back around the other side
```

shr vs sar is the signed/unsigned split again (week 5's jl/jb, now for
shifts): `-8 shr 1` gives a huge positive number; `-8 sar 1` gives -4.
Variable shift counts must live in **cl**: `shr rax, cl` (an ancient
hardware quirk).

The last bit shifted out lands in CF — so shift + `jc` reads a register
bit-by-bit. That's the key to today's exercise.

### Three classics worth knowing cold

```nasm
test rax, 1                 ; odd/even (you did this in Collatz, week 5)

; is rax a power of two?  x AND (x-1) clears the lowest set bit —
lea rbx, [rax - 1]          ; so for powers of two the result is 0
test rax, rbx               ; (careful: 0 sneaks through — handle it)

xor rax, rbx                ; swap two regs without a temp:
xor rbx, rax                ; the xor-swap party trick
xor rax, rbx                ; (use xchg in real code; know this anyway)
```

## Type (~60 min)

`make new n=w10`. Write **print_bin** for your `lib.inc`: print rdi as 64
binary digits + newline. Plan A — walk bits from the top:

```nasm
; print_bin(rdi = value) — prints 64 chars of 0/1 + newline
print_bin:
        lea rsi, [binbuf]
        mov ecx, 64
.bit:
        xor eax, eax
        shl rdi, 1          ; top bit falls into CF...
        adc al, '0'         ; al = '0' + CF — carry flag arithmetic!
        mov [rsi], al
        inc rsi
        dec ecx
        jnz .bit
        mov byte [rsi], 10
        ; write(1, binbuf, 65)
        mov rax, 1
        mov rdi, 1
        lea rsi, [binbuf]
        mov edx, 65
        syscall
        ret

section .bss
        binbuf resb 65
```

(`adc x, y` = add-with-carry: x + y + CF. Using flags as *data* — a small
epiphany. If it feels like a magic trick, single-step it in gdb watching CF.)

Test on 0, -1 (all ones!), 0xAA (10101010 pattern at the bottom), and
`1 << 63`. Then print some week-4 numbers in binary and *look* at two's
complement: print n and -n for a few n. The pattern you'll notice at the
low end is real — figure out the rule ("flip all bits above the lowest 1").

## Solve (~20 min)

1. **popcount**: count the 1-bits in rdi (loop with `shr` + `adc` or
   test-and-count). Check against gdb: gdb has no popcount, but
   `p/t $rdi` lets you count by eye for small cases. (x86 has a `popcnt`
   instruction — write the loop first, then try replacing it.)
2. **Nibble to hex**: print rdi as 16 hex digits — mask 4 bits at a time
   (`rol rdi, 4` + `and`), map 0–9→'0'-'9', 10–15→'a'-'f'. This function
   becomes the heart of the week-16 hexdump; build it well and keep it in
   lib.inc as **print_hex**.
3. **Flag pack**: pack three "booleans" (0/1 in rax, rbx, rcx) into bits
   0, 1, 2 of one register; then unpack bit 1 back out. Two shifts and an
   `and` each way.

## Tool tip of the week

`p/t $rax` prints a register in binary — instant check for every exercise
today. `p/x` for the hex one. And `p $rax >> 4 & 0xf` — gdb evaluates C
expressions, so you can prototype a mask before writing the asm.

## Check yourself

- Which right-shift belongs to which sign interpretation, and what fills in?
- What does `x & (x-1)` do, and what's the power-of-two catch?
- Where must a variable shift count live?
