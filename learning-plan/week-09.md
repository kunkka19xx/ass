# Week 09 — The System V ABI

**Goal:** adopt the calling convention every Linux x86-64 program uses, and
build your own utility library (`lib.inc`) that the rest of the course — and
week 13's C interop — will stand on.

## Read (~40 min)

### Why conventions matter

Last week your functions had homemade contracts ("number goes in rax").
Fine solo — but the moment two pieces of code meet (your code + my code,
your code + libc, your code + the kernel), both sides must agree on where
arguments go and who saves what. On Linux x86-64 that agreement is the
**System V AMD64 ABI**. Learn it once; it's the same for C, Rust, Go's
cgo, and everything else on your machine.

### The rules

**Arguments** (integers/pointers) go, in order:

```
rdi, rsi, rdx, rcx, r8, r9        — 7th and beyond: on the stack
```

**Return value:** rax.

**Register ownership:**

| Caller-saved (volatile) | Callee-saved (preserved) |
|---|---|
| rax rcx rdx rsi rdi r8–r11 | rbx rbp r12–r15 rsp |

- *Caller-saved*: a function may trash these freely. If the **caller** needs
  them after a call, the caller saves them.
- *Callee-saved*: a function that touches these must restore them before
  `ret` (push at entry, pop at exit).

**Kernel vs functions — almost the same, differently annoying:**

- syscalls take the 4th argument in **r10** (functions use rcx — the
  `syscall` instruction itself destroys rcx, so the kernel couldn't use it)
- `syscall` clobbers **rcx and r11**. If a value must survive a syscall,
  don't keep it there. This bug is invisible until it isn't.

**Also in the ABI** (matters at week 13, park it for now): `rsp` must be
16-byte aligned *at the point of `call`*, and there's a 128-byte "red zone"
below rsp that signal handlers won't touch.

### Designing your library

Today you start `lib.inc` — a file of functions included via NASM's
`%include` (textual include, like C's `#include`; multi-file *linking* comes
in week 14). Every function follows the ABI: args in rdi/rsi/…, result in
rax, callee-saved registers respected.

## Type (~60 min)

Create `lib.inc` **in the repo root** (it's course infrastructure, not a
weekly exercise). Port and write, ABI-style:

```nasm
; lib.inc — course utility library. ABI-compliant.

; print_uint(rdi = number) — prints decimal + newline
print_uint:
        push rbx
        mov rax, rdi                ; ABI arg → the old working register
        ; ... week-8 body unchanged ...
        pop rbx
        ret

; print_str(rdi = address of 0-terminated string)
print_str:
        push rdi
        call strlen                 ; rax = length (note: rdi survives? NO —
        pop rdi                     ;  strlen may trash it: caller saves!)
        mov rdx, rax
        mov rsi, rdi
        mov rax, 1
        mov rdi, 1
        syscall
        ret

; strlen(rdi = address) → rax = length up to the 0 byte
strlen:
        xor eax, eax
.scan:  cmp byte [rdi + rax], 0
        je .done
        inc rax
        jmp .scan
.done:  ret

; exit(rdi = status) — never returns
exit:
        mov rax, 60
        syscall
```

Then `make new n=w09` for a test-drive file:

```nasm
        BITS 64
        section .text
        global _start
        %include "lib.inc"

_start:
        lea rdi, [greeting]
        call print_str
        mov rdi, 40
        add rdi, 2
        call print_uint
        xor edi, edi
        call exit

        section .data
        greeting db 'lib.inc lives!', 10, 0
```

Now the week's real work — **hunt your own ABI violations**:

1. Does print_uint's body still expect its input in rax somewhere it now
   arrives in rdi? Step through with gdb.
2. In print_str, delete the push/pop around `call strlen` and observe the
   bug (strlen *happens* to preserve rdi today — so it *works*. Now add a
   `mov rdi, 0` scribble inside strlen — still "legal" per the ABI! — and
   watch print_str break). Lesson: code to the contract, not to luck.
3. Keep a loop counter in rcx across a syscall. Watch r11/rcx before and
   after with gdb. This is the clobber rule made visceral.

## Solve (~20 min)

1. **print_uint_n**: `(rdi = number)` — like print_uint but *no* newline.
   Then `print_space`. Compose them: print `1 2 3 ... 10` on one line.
2. **read_char**: no args → rax = one byte read from stdin (syscall 0 into a
   1-byte .bss buffer), or -1 at end-of-input (read returns 0 there). Test:
   echo a char back. `make run` then type; also try `echo hi | ./w09`.
3. **Contract audit**: for each lib.inc function, write a one-line comment:
   which registers it clobbers. Verify one of them empirically in gdb —
   `i r` before and after the call, diff by eye.

## Tool tip of the week

`make trace f=w09` now earns its keep: each syscall line shows the *ABI in
action* — `write(1, "lib.inc lives!\n", 15)` is literally your rdi, rsi,
rdx displayed back. If a syscall gets garbage args, strace shows the garbage.

## Check yourself

- Argument order for functions? And the syscall difference at arg 4?
- Which registers must a function preserve? Which may it trash?
- Why can't the kernel take arg 4 in rcx like functions do?
