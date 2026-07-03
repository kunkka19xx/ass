# Week 04 — Arithmetic & flags

**Goal:** do real math (including the weird `div`), understand two's
complement sign, and read the RFLAGS register — the CPU's mood ring that
makes next week's branching possible.

## Read (~40 min)

### The easy ones

```nasm
add rax, rbx        ; rax += rbx      (also: add rax, 5 / add [mem], rax)
sub rax, rbx        ; rax -= rbx
inc rax             ; rax++
dec rax             ; rax--
neg rax             ; rax = -rax
```

### Signed numbers: two's complement in 60 seconds

There is no "signed register". A 64-bit register holds 64 bits; *you* decide
whether to read them as unsigned (0 … 2⁶⁴-1) or signed (-2⁶³ … 2⁶³-1).
Negative x is stored as 2⁶⁴ - x, which means: `-1` = all bits set =
`0xFFFF...FF`. The genius part: `add` and `sub` work identically for both
interpretations — only *comparisons* differ (that's week 5's jl vs jb).

### Multiplication and the strange division

```nasm
imul rax, rbx           ; rax *= rbx           (signed; the form you'll use)
imul rax, rbx, 10       ; rax = rbx * 10
mul rbx                 ; unsigned: rdx:rax = rax * rbx  (128-bit result!)
```

Division is the diva of x86. `div rbx` divides the **128-bit** value
`rdx:rax` by rbx: quotient → rax, remainder → rdx. Two consequences:

1. You must set rdx correctly *before* dividing, or you'll divide a garbage
   128-bit number — and likely crash with SIGFPE ("floating point exception",
   despite no floats — it means division overflow/by-zero).
2. The remainder lands in rdx for free — that's your modulo.

```nasm
; unsigned: c = a / b, remainder in rdx
mov rax, [a]
xor edx, edx        ; rdx = 0 — mandatory!
div qword [b]       ; rax = quotient, rdx = remainder

; signed: use cqo, which sign-extends rax into rdx
mov rax, [a]
cqo                 ; rdx = rax's sign spread across 64 bits
idiv qword [b]
```

### RFLAGS: the CPU takes notes

Almost every arithmetic instruction updates flag bits as a side effect:

| Flag | Set when… | Cares about |
|---|---|---|
| ZF (zero) | result == 0 | everyone |
| SF (sign) | top bit of result is 1 | signed |
| CF (carry) | unsigned overflow (borrow/carry out) | unsigned |
| OF (overflow) | signed overflow (sign flipped wrongly) | signed |

You never read flags with `mov` — conditional jumps (next week) read them.
This week you just learn to *see* them: gdb shows `eflags [ ZF PF ]` in
`info registers`. Note: `mov` never touches flags; `inc/dec` touch all
*except* CF (ancient trivia that becomes a real bug about once a decade).

## Type (~60 min)

`make new n=w04`. Compute `(a*b + c) / d` and return the result as the exit
status (keep results < 256 — remember week 2's smuggling exercise):

```nasm
_start:
        mov rax, 6          ; a
        imul rax, 7         ; * b        = 42
        add rax, 8          ; + c        = 50
        mov rbx, 5          ; d
        xor edx, edx
        div rbx             ;            = 10, remainder 0 in rdx
        mov rdi, rax
        mov rax, 60
        syscall
```

`make run` → `[exit status: 10]`. Congratulations: your program computes.

Now the flags safari in gdb (`make debug f=w04`):

1. Step each instruction with `si`, watch `eflags` in `i r`.
2. Insert `mov rax, -1` + `add rax, 1` — after the add, which flags are set?
   (Expect ZF and CF: result is zero, and unsigned it wrapped.)
3. Insert the signed-overflow classic:
   ```nasm
   mov rax, 0x7FFFFFFFFFFFFFFF   ; largest signed 64-bit number
   inc rax                       ; +1 → most NEGATIVE number. Check OF and SF.
   ```
4. Change the divisor to 0 and run. Meet SIGFPE. Now zero rdx improperly
   (delete `xor edx, edx`, put junk in rdx first) — SIGFPE again, different
   reason. Both are the two classic div crashes; you've now had both.

## Solve (~20 min)

1. **Digits by hand**: split 1234 into its four digits using only div/mod,
   and exit with the digit sum (10). This is a dry run for week 7's
   number printing — make it work.
2. **Average**: five numbers at a `dq` table (week 3 skills), compute the
   integer average, exit with it. Watch: what garbage is in rdx before your
   *second* div, and who put it there?
3. **Predict the flags**: for each, write ZF/SF/CF/OF before checking in gdb:
   `5 - 5`, `3 - 5`, `-3 + 3`, `0x8000000000000000 + 0x8000000000000000`.

## Tool tip of the week

`p/t $eflags` prints flags as raw bits, but plain `i r eflags` decodes them
by name: `[ CF ZF SF ]`. Also `p/d $rax` vs `p/x $rax` vs `p $rax` — decimal,
hex, gdb's guess. For signed inspection: `p (long)$rax`.

## Check yourself

- Where do quotient and remainder land after `div`? What must you do first?
- What's `-1` in hex in a 64-bit register, and why does `add rax,1` then set CF?
- Which flag pair answers "signed overflow" vs "unsigned overflow"?
