# Week 12 — String instructions

**Goal:** meet x86's built-in memory-crunching instructions — the `rep`
family — and rewrite your loops as single instructions.

## Read (~40 min)

### The idea: hardwired loops

x86 descends from CPUs that did string work in microcode. The surviving
instructions each do one step of a memory loop, using **fixed registers**:

| Registers | Role |
|---|---|
| rsi | source pointer ("s" = source — now the register names make sense!) |
| rdi | destination pointer |
| rcx | count |
| al/ax/eax/rax | the value (for store/scan/load) |

| Instruction | One step of… | After each step |
|---|---|---|
| `movsb` | copy byte [rsi] → [rdi] | rsi++, rdi++ |
| `stosb` | store al → [rdi] | rdi++ |
| `lodsb` | load [rsi] → al | rsi++ |
| `scasb` | compare al with [rdi] | rdi++ (sets flags) |
| `cmpsb` | compare [rsi] with [rdi] | both++ (sets flags) |

Each has b/w/d/q variants (step 1/2/4/8 bytes).

### rep: the loop in front

Prefixes repeat the step rcx times:

```nasm
rep movsb           ; memcpy: copy rcx bytes from [rsi] to [rdi]
rep stosb           ; memset: fill rcx bytes at [rdi] with al
repne scasb         ; scan: advance until [rdi] == al or rcx = 0  ("ne"
                    ;   = repeat while Not Equal)
repe cmpsb          ; compare: advance while bytes are equal (memcmp core)
```

So the classics become:

```nasm
; memcpy(dst=rdi, src=rsi, n=rcx)
        rep movsb

; memset(dst=rdi, byte=al, n=rcx)
        rep stosb

; strlen via scan for the 0 byte:
        mov rdi, string
        xor eax, eax            ; looking for 0
        mov rcx, -1             ; "unlimited" count (week 4: -1 = max unsigned)
        repne scasb             ; rdi now points ONE PAST the 0
        ; length = -rcx - 2     (count how much rcx decremented; off-by-2
        ;                        because rcx starts at -1 and scasb counts the 0)
```

That strlen is a famous idiom — derive the -2 yourself on paper; it's a
rite of passage.

### The direction flag (the one global you must respect)

The pointers go *up* only if DF (direction flag) is clear. `cld` clears it
(forward), `std` sets it (backward). The ABI says DF is clear on entry to
functions — keep it that way: if you ever `std`, `cld` before returning.
A leaked DF is a legendary heisenbug.

Modern-CPU footnote: `rep movsb` on your AMD Zen is genuinely fast (the
CPU special-cases it — "ERMS"), so this isn't retro trivia; glibc's memcpy
really uses it for many sizes. Week 15 will measure it.

## Type (~60 min)

`make new n=w12`, and upgrade **lib.inc**:

1. **strlen v2** with `repne scasb` — keep v1 as `strlen_slow`. Both must
   agree on: empty string, 1-char, your longest test string. gdb-verify the
   pointer-past-the-zero claim: after `repne scasb`, `x/1cb $rdi-1`.
2. **memcpy(rdi=dst, rsi=src, rdx=n)** — ABI puts n in rdx, `rep` wants it
   in rcx: `mov rcx, rdx` first. One-line body. Test: copy a string to a
   `.bss` buffer, print the copy.
3. **memset(rdi=dst, sil=byte, rdx=n)** — same shape (`mov al, sil`). Fill a
   buffer with '=' and print it: instant horizontal rule function.
4. **strcmp(rdi, rsi) → rax = 0 / nonzero**: length-check first or walk
   with `cmpsb` until inequality or the 0 terminator. This one has edge
   cases ("abc" vs "abcd"!) — write them as tests, print PASS/FAIL per case
   using print_str. Congratulations, you've invented the test harness.

## Solve (~20 min)

1. **Uppercase filter**: read stdin in a loop (week 11), uppercase a–z
   (bit trick: ASCII lower/upper differ by exactly bit 5 — week 10!), write
   out. Test: `echo hello | ./w12`. You've built `tr a-z A-Z`.
2. **memmove puzzle**: copy a buffer 3 bytes *forward into itself* with
   `rep movsb` (overlapping!). Look at the smear. Now do it correctly with
   `std` + pointers at the *ends* + `rep movsb` + **`cld`**. You now know
   the entire difference between memcpy and memmove.
3. **strchr(rdi=string, sil=char) → rax = pointer or 0**: `repne scasb`
   needs a count — get it from your own strlen first. Two string
   instructions cooperating.

## Tool tip of the week

Single-step a `rep movsb` in gdb: `si` treats the whole rep as one
instruction (it re-executes until rcx=0). To watch iterations, break before
it and `display $rcx, $rsi, $rdi`, or check state mid-flight with Ctrl-C on
a huge copy. `p $rcx` after tells you how many steps *didn't* run — that's
exactly what the strlen idiom exploits.

## Check yourself

- Which three registers does the rep machinery use, for what?
- Why does rdi end up one *past* the match after `repne scasb`?
- When must you `cld`, and why is forgetting it so nasty?
