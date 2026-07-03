# Week 03 — Memory & sections

**Goal:** define data of every size, read and write it from registers, and
see with your own eyes how numbers are laid out in bytes (endianness).

## Read (~40 min)

### Sections: where things live

Your binary is split into sections, each with different permissions:

| Section | Holds | Permissions |
|---|---|---|
| `.text` | instructions | read + execute |
| `.data` | initialized data (`db 'hi'`) | read + write |
| `.bss` | *uninitialized* space (`resb 64`) | read + write, costs 0 bytes in the file |
| `.rodata` | read-only data | read only |

Why `.bss` exists: a 1 MB buffer as `times 1048576 db 0` makes a 1 MB binary;
`buf resb 1048576` makes the kernel hand you zeroed pages at load time — the
file stays tiny. Rule: constants → `.data`/`.rodata`, buffers → `.bss`.

Try writing to something in `.rodata` this week — the segfault you get is the
permission system working, and it's why "write to a string literal" crashes
in C too.

### Defining data

```nasm
section .data
        answer  db 42               ; 1 byte
        port    dw 8080             ; 2 bytes
        big     dd 1000000          ; 4 bytes
        huge    dq 12345678901234   ; 8 bytes
        msg     db 'hi', 10, 0      ; several bytes in a row; 0 = C terminator
        table   times 8 dq 0        ; eight zero qwords
        msglen  equ $ - msg         ; CONSTANT, occupies no memory

section .bss
        buf     resb 64             ; reserve 64 bytes
        nums    resq 10             ; reserve 10 qwords
```

`$` means "the address right here", so `$ - msg` = bytes since `msg` = its
length. `equ` names a number at assembly time — it never exists at runtime.

### Labels are addresses; brackets are contents

The single most important notation in NASM:

```nasm
mov rax, msg        ; rax = the ADDRESS of msg
mov rax, [msg]      ; rax = 8 bytes STORED AT msg
mov [huge], rax     ; store rax's 8 bytes at huge
mov al, [msg]       ; load just 1 byte (register size decides how much)
```

When *no register* reveals the size, you must say it:

```nasm
mov [answer], 5             ; ✗ error: how many bytes? nasm can't know
mov byte [answer], 5        ; ✓
mov qword [huge], 5         ; ✓
```

And the limit you already met: there is **no** instruction storing a 64-bit
*immediate* to memory. Your `4.asm` did `mov qword [name], 'Nuha Ali'` —
8 ASCII characters = a 64-bit immediate — so NASM truncated it to 4 bytes
with a warning, and only "Nuha" was written. The fix goes via a register:

```nasm
mov rax, 'Nuha Ali'     ; imm64 → register: this IS allowed
mov [name], rax         ; register → memory
```

### Endianness: bytes in "reverse"

x86 is **little-endian**: the *least* significant byte goes to the *lowest*
address. Store `0x1122334455667788` and memory reads, byte by byte:
`88 77 66 55 44 33 22 11`. It never matters while you stay in registers —
it matters the moment you look at raw memory (which you will, right now).

## Type (~60 min)

`make new n=w03`, then build a little memory playground:

```nasm
_start:
        mov rax, 0x1122334455667788
        mov [scratch], rax          ; store 8 bytes

        mov bl, [scratch]           ; load 1 byte back — which one?
        mov ecx, [scratch]          ; load 4 bytes — which ones?

        mov rax, 'Nuha Ali'         ; the week-3 fix for your 4.asm bug
        mov [name], rax

        ; print name to prove it worked (week-1 skills)
        mov rax, 1
        mov rdi, 1
        mov rsi, name
        mov rdx, 9
        syscall

        mov rax, 60
        xor rdi, rdi
        syscall

section .data
        name    db 'Zara Ali ', 10
section .bss
        scratch resq 1
```

Now inspect memory in gdb (`make debug f=w03`, then `si` past the store):

```
x/8xb &scratch      ; 8 bytes, hex — see little-endian with your own eyes
x/1gx &scratch      ; same memory as one giant (8-byte) value
x/s &name           ; as a string
```

Predict `bl` and `ecx` before stepping those loads. Check with `i r rbx rcx`.

Finally: actually go fix the real `4.asm` and `make run f=4` — the warnings
disappear and both names print fully (adjust `rdx`; count the bytes!).

## Solve (~20 min)

1. **Byte surgeon**: store `0x1122334455667788` at a label, then — using only
   *byte-sized* loads and stores — swap the first and last byte in memory.
   Verify with `x/8xb` in gdb.
2. **Read-only lab**: put a string in `section .rodata` and try to overwrite
   its first byte. Run it. Explain the result in one sentence.
3. **The self-measuring menu**: define three strings back to back, each with
   its own `equ` length, and print all three with three writes. No length
   may be a hand-counted number.

## Tool tip of the week

`x` is gdb's memory microscope: `x/NFU addr` = N units, format F (x hex,
d decimal, c char, s string), unit U (b byte, h half, w word, g giant).
`x/8xb`, `x/4gx`, `x/s` cover 95% of your needs.

## Check yourself

- Difference between `mov rax, msg` and `mov rax, [msg]`?
- Why does `mov [x], 1` fail to assemble but `mov byte [x], 1` work?
- You store `dq 1` and read the first byte. Is it 1 or 0 — and why?
