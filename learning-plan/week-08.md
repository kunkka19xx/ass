# Week 08 — The stack & functions

**Goal:** understand the stack as a data structure the CPU gives you for
free, and use `call`/`ret` to turn last week's routine into a real function
— including recursion.

## Read (~40 min)

### The stack: a downward-growing scratchpad

`rsp` points at the "top" of the stack — which grows **downward** (toward
lower addresses). Two instructions manage it:

```nasm
push rax        ; rsp -= 8, then [rsp] = rax
pop rbx         ; rbx = [rsp], then rsp += 8
```

Push and pop must balance. The stack is also plain memory — `[rsp + 8]`
peeks below the top without popping. Linux gives `_start` several megabytes
of it; you've had a stack all along and never touched it.

What's it for? (1) saving registers you're about to clobber, (2) return
addresses — right now — and (3) local variables and deep call chains, later.

### call and ret: the return-address machine

Last week's `jmp print_uint` / `jmp back` hack worked for exactly one call
site: the routine had no idea where to go back to. `call` fixes this:

```nasm
call print_uint     ; = push the address of the NEXT instruction, jmp there
...
print_uint:
        ...
        ret         ; = pop that address and jump to it
```

The return address lives *on the stack* — which is why recursion just works:
each nested call pushes its own return address.

The iron rule that follows: **inside a function, rsp must be back where it
started when you `ret`** — otherwise `ret` pops your data as an "address"
and jumps into the void. Every push needs its pop, in reverse order:

```nasm
myfunc: push rbx            ; save what we'll clobber
        push r12
        ; ... work that trashes rbx and r12 ...
        pop r12             ; reverse order!
        pop rbx
        ret
```

### Who saves what? (informal, this week)

If a function preserves the registers its caller cares about, callers can
keep values across calls. For now adopt the real-world rule, formalized next
week: **a function may trash rax, rcx, rdx, rsi, rdi, r8–r11; it must
preserve rbx, rbp, r12–r15, rsp.** rax carries the return value.

### Local labels, now official

`.next_digit` inside `print_uint` is really `print_uint.next_digit` —
NASM glues local labels to the last global label. Every function gets its
own private `.loop`, `.done`, `.next` namespace. (You've been using this
since week 5; gdb's `b print_uint.next_digit` syntax makes sense now.)

## Type (~60 min)

`make new n=w08`. Refactor week 7's `print_uint` into a true function:

- entry: number in **rax**  → prints it + newline
- `push rbx` at the top, `pop rbx` before `ret` (it uses rbx as divisor)
- replace the `jmp back` hack with `ret`

```nasm
_start:
        mov rax, 42
        call print_uint
        mov rax, 1000000
        call print_uint     ; two call sites — impossible last week!
        mov rax, 60
        xor rdi, rdi
        syscall
```

Then write **factorial, recursively** — gloriously inefficient, perfect
for feeling the stack breathe:

```nasm
; rax = n  →  rax = n!
factorial:
        cmp rax, 1
        jbe .base           ; 0! = 1! = 1
        push rax            ; save n across the recursive call
        dec rax
        call factorial      ; rax = (n-1)!
        pop rbx             ; rbx = our saved n
        imul rax, rbx       ; n * (n-1)!
        ret
.base:
        mov rax, 1
        ret
```

`call factorial` from `_start` with 10, `call print_uint` → 3628800.

Now *watch the stack* in gdb: `b factorial`, `c` until the third hit, then
`x/8gx $rsp` — you'll see the tower: saved n's interleaved with return
addresses (addresses inside your own .text — compare with `make dump`).
`bt` shows gdb's guess at the call chain.

Finally, sabotage on purpose: add one extra `push rax` before a `ret`, run,
and observe the crash. Diagnose it in gdb (`si` up to the `ret`, `x/1gx
$rsp` — is that an address of code?). This is the most common crash in all
of assembly programming; learn its face.

## Solve (~20 min)

1. **print_two**: a function taking numbers in rdi and rsi, printing
   `a b\n` (space-separated) by calling print_uint twice. Careful: which
   registers does print_uint destroy? Save what you need — on the stack.
2. **Fibonacci, recursive**: fib(20) = 6765. Two recursive calls means two
   saves. Then count the calls in a global counter (`.bss` qword) and print
   it — appreciate *why* naive fib is a benchmark.
3. **Stack-based reverse**: revisit week 7's digit problem — push each
   remainder, count them, then pop-and-print. Same output, stack instead of
   backwards buffer.

## Tool tip of the week

`bt` (backtrace) shows the call chain — it works because return addresses
sit on the stack at predictable spots. `finish` runs until the current
function returns (way better than holding `si`), and `ni` steps *over* a
`call` instead of into it.

## Check yourself

- What exactly does `call` push? What does `ret` assume is at [rsp]?
- Why must pops mirror pushes in reverse order?
- Why does recursion need no special support beyond call/ret?
