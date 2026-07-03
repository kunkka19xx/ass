# Week 05 — Branches & loops

**Goal:** translate `if / else / while / for` into assembly without thinking,
and internalize the signed-vs-unsigned jump split.

## Read (~40 min)

### cmp and test: asking questions

```nasm
cmp rax, rbx        ; computes rax - rbx, THROWS AWAY the result, keeps flags
test rax, rax       ; computes rax AND rax, same idea — flags only
```

`cmp a, b` then a conditional jump = "compare a with b, jump if …".
`test rax, rax` is the idiomatic "is rax zero?" (ZF set ⇔ zero) — shorter
than `cmp rax, 0`.

### The jump family

`jmp label` always jumps. The conditional ones read flags from the last
flag-setting instruction:

| After `cmp a, b`, jump if… | Signed | Unsigned |
|---|---|---|
| a == b | `je` | `je` |
| a != b | `jne` | `jne` |
| a < b | `jl` | `jb` |
| a >= b | `jge` | `jae` |
| a > b | `jg` | `ja` |
| a <= b | `jle` | `jbe` |

Mnemonics: **l**ess/**g**reater = signed, **b**elow/**a**bove = unsigned.
Mixing them is THE classic asm bug: compare `-1 < 1` with `jb` and it's
false, because unsigned `-1` is the biggest number there is (week 4!).

### The patterns — learn these as vocabulary

**if / else:**
```nasm
        cmp rax, 10
        jge .else           ; note: INVERTED condition jumps AROUND the body
        ; ... then-body ...
        jmp .end
.else:
        ; ... else-body ...
.end:
```

**while (rcx != 0):**
```nasm
.loop:
        test rcx, rcx
        jz .done
        ; ... body ...
        jmp .loop
.done:
```

**do-while / counted loop** (the tightest form — condition at the bottom):
```nasm
        mov rcx, 10
.loop:
        ; ... body runs 10 times ...
        dec rcx
        jnz .loop           ; dec set ZF when rcx hit 0 — no cmp needed!
```

That last trick — arithmetic sets flags, jump uses them directly — is what
"thinking in assembly" feels like. (There's also a `loop` instruction that
does dec-rcx-and-jump; it's slower than `dec`+`jnz` on modern CPUs and
mostly a curiosity.)

Labels starting with a dot (`.loop`) are *local* to the previous normal
label — so every function can have its own `.loop` without collisions.
More in week 8.

## Type (~60 min)

`make new n=w05`. Build **Collatz**: start from n; if even, n/2; if odd,
3n+1; count steps until n == 1. Exit with the step count.

```nasm
_start:
        mov rax, 27         ; n  (27 is famous: 111 steps)
        xor rbx, rbx        ; step counter
.loop:
        cmp rax, 1
        je .done
        test rax, 1         ; lowest bit set = odd
        jnz .odd
        shr rax, 1          ; even: n /= 2  (shift preview — week 10)
        jmp .next
.odd:
        lea rax, [rax + rax*2 + 1]  ; n = 3n+1 — lea as math! (week 6)
.next:
        inc rbx
        jmp .loop
.done:
        mov rdi, rbx
        mov rax, 60
        syscall
```

- `make run` → 111. Try other n.
- In gdb: `break .loop` isn't valid — local labels need their parent:
  `b _start.loop` works. Watch a few iterations with `si`, `i r rax rbx`.
- **Foot-gun drill**: replace the exit-status with n = 1000000 iterations of
  a counting loop and exit with the count. You'll get status 64 — because
  exit truncates to one byte (1000000 mod 256 = 64). Burn this in: exit
  status is a *debug channel*, not a real output. Week 7 fixes this forever.

## Solve (~20 min)

1. **max3**: three values in rax, rbx, rcx → exit with the largest. Two
   compares, no memory.
2. **Signed trap, on purpose**: put -1 in rax and 1 in rbx; `cmp rax, rbx`
   then take `jb` vs `jl` branches to different exit codes. Run both. Explain
   the difference in one sentence (you already know why — week 4).
3. **FizzBuzz, asm edition**: for n = 1..15 print `Fizz\n`, `Buzz\n`,
   `FizzBuzz\n`, or `.\n` (a dot for plain numbers — you can't print numbers
   yet; week 7 upgrades this). Modulo = the div remainder, week 4.

## Tool tip of the week

`b _start.loop` + `c` (continue) + `i r` beats holding down `si`. Even
better: `watch $rbx` — gdb stops whenever rbx *changes*. And if a loop runs
away: Ctrl-C breaks in without killing the program.

## Check yourself

- Why does the if/else pattern jump on the *inverted* condition?
- `jl` vs `jb` — which flags does each read, and for which number
  interpretation?
- Why does `dec rcx` + `jnz` need no `cmp`?
