# Week 07 — Numbers ↔ text (milestone!)

**Goal:** print any number. This unlocks *real* debugging output and retires
the 255-limited exit-status trick forever. This is the course's first big
milestone — after today you can watch your programs think.

## Read (~40 min)

### Why you can't "just print" a number

`write` outputs **bytes**. The number 1234 in a register is the bits
`10011010010` — but on screen you want the four *characters* `'1' '2' '3'
'4'`, which are the bytes 49, 50, 51, 52. ASCII digits are contiguous:

> character of digit d = d + 48 (48 = `'0'`) — and back: digit = char - 48.

So printing a number = converting binary → a sequence of digit characters.

### The algorithm: divide by 10, collect remainders

1234 ÷ 10 = 123 remainder **4**
 123 ÷ 10 =  12 remainder **3**
  12 ÷ 10 =   1 remainder **2**
   1 ÷ 10 =   0 remainder **1** → stop when quotient is 0

The remainders arrive **last digit first**. Two classic fixes: fill a buffer
from its *end* backwards (what we'll do), or push remainders on the stack and
pop them (try after week 8). Everything needed is old news: `div` and
remainder-in-rdx (week 4), loops (week 5), byte stores and buffers (weeks 3/6).

### atoi: the reverse direction

Reading "1234" → number is the same idea mirrored, no division needed:

```
result = 0
for each char c:  result = result*10 + (c - 48)
```

## Type (~60 min)

`make new n=w07`. The routine below is one you will reuse for the rest of
the course — get it right and treasure it:

```nasm
; ---- print rax as unsigned decimal + newline -------------------
; uses: rax (input, destroyed), rbx, rcx, rdx, rsi, rdi
print_uint:
        lea rsi, [numbuf + numbuf_len]  ; rsi = one past buffer end
        dec rsi
        mov byte [rsi], 10              ; place the newline first
        mov rbx, 10                     ; divisor lives in rbx
.next_digit:
        xor edx, edx                    ; rdx = 0 before every div!
        div rbx                         ; rax = quot, rdx = remainder
        add dl, '0'                     ; digit → ASCII
        dec rsi
        mov [rsi], dl                   ; store, moving backwards
        test rax, rax
        jnz .next_digit                 ; until quotient is 0
        ; write(1, rsi, bytes_used)
        lea rdx, [numbuf + numbuf_len]
        sub rdx, rsi                    ; length = end - start
        mov rax, 1
        mov rdi, 1
        syscall
        jmp back                        ; crude return — week 8 fixes this

_start:
        mov rax, 1234567890
        jmp print_uint
back:
        mov rax, 60
        xor rdi, rdi
        syscall

section .bss
        numbuf      resb 21             ; 2^64 has 20 digits, +1 newline
        numbuf_len  equ 21
```

(That `jmp`/`jmp back` "return" is deliberately ugly — it only works for one
call site. Sit with the ugliness; week 8's `call`/`ret` is the cure and
you'll appreciate *why* it exists.)

Test the edges: 0 (does it print at all? why does the do-while shape save
it?), 9, 10, and 18446744073709551615 (that's -1 unsigned — week 4 grin).

Then upgrade last week's array-max and Collatz to *print* their answers.
Feel the difference a real output channel makes.

## Solve (~20 min)

1. **Squares table**: print n² for n = 1..12, one per line. (Loop + imul +
   your routine. Note which registers the routine destroys — plan around it.)
2. **atoi**: put `db "4096", 0` in .data, parse it with the multiply-by-10
   loop, print the result. Stop at the 0 terminator.
3. **Signed printing**: print -42 correctly: if the top bit is set
   (`test rax, rax` / `js`), print `'-'`, `neg rax`, then reuse print_uint.
   `js` = "jump if sign flag" — your week-4 flags knowledge paying rent.

## Tool tip of the week

Watch the buffer fill *backwards* in gdb: `b print_uint.next_digit`, `c` a
few times, `x/21cb &numbuf` each stop. Formats-within-x refresher: `c` shows
bytes as characters — you'll see digits appear right-to-left like a
type-writer in reverse.

## Check yourself

- Why do the digits come out in reverse order?
- Why must rdx be zeroed before every single `div` in the loop?
- What exactly does `add dl, '0'` do, numerically?
