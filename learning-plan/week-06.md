# Week 06 — Arrays & addressing modes

**Goal:** walk arrays with the full `[base + index*scale + disp]` machinery
and wield `lea`, the most misunderstood instruction on x86.

## Read (~40 min)

### The universal address formula

Every x86 memory operand is some subset of:

```
[ base_reg + index_reg * scale + displacement ]      scale ∈ {1,2,4,8}
```

All of these are valid — and *free*, computed by dedicated address hardware:

```nasm
mov rax, [table]                ; displacement only
mov rax, [rbx]                  ; base
mov rax, [rbx + 24]             ; base + disp
mov rax, [table + rcx*8]        ; disp + index*scale  ← THE array idiom
mov rax, [rbx + rcx*8 + 16]     ; everything at once
```

`[table + rcx*8]` *is* `table[rcx]` for a `dq` array. The scale matches the
element size: `*1` bytes, `*2` words, `*4` dwords, `*8` qwords. This is why
C pointer arithmetic multiplies by sizeof — you're looking at the reason.

Two hardware limits: no *two* index registers, and scale only 1/2/4/8.

### The two ways to walk an array

```nasm
; A: index walk — clearest
        xor ecx, ecx            ; i = 0
.loop:  mov rax, [table + rcx*8]
        ; ... use rax ...
        inc rcx
        cmp rcx, COUNT
        jb .loop

; B: pointer walk — what C's *p++ compiles to
        mov rsi, table
        lea rdx, [table + COUNT*8]   ; one-past-the-end
.loop:  mov rax, [rsi]
        ; ... use rax ...
        add rsi, 8
        cmp rsi, rdx
        jb .loop
```

### lea: the address calculator that doesn't touch memory

`lea dst, [expr]` computes the *address* `expr` and stores **the number
itself** — memory is never accessed. Two uses:

```nasm
lea rax, [table + rcx*8]    ; honest use: pointer to element i
lea rax, [rax + rax*4]      ; sneaky use: rax *= 5 — pure arithmetic!
lea rax, [rbx + rcx + 7]    ; a 3-operand add: rax = rbx + rcx + 7
```

The sneaky use is everywhere in compiler output: `lea` does
mul-and-add in one flag-preserving instruction on the address unit. You used
`lea rax, [rax + rax*2 + 1]` for 3n+1 last week — now you know why it worked.

## Type (~60 min)

`make new n=w06`. Find the **maximum of an array** and exit with it:

```nasm
_start:
        mov rax, [table]            ; current max = first element
        mov ecx, 1                  ; i = 1
.loop:
        cmp rcx, count
        jae .done
        cmp [table + rcx*8], rax
        jbe .next
        mov rax, [table + rcx*8]   ; new champion
.next:
        inc rcx
        jmp .loop
.done:
        mov rdi, rax
        mov rax, 60
        syscall

section .data
        table   dq 17, 4, 91, 33, 8, 76, 2
        count   equ ($ - table) / 8     ; self-measuring, week-3 style
```

Then, the satisfying one — **reverse a string in place** and print it:
two pointers (`lea rsi, [msg]`, `lea rdi, [msg + msglen - 2]`; -2 to skip
the newline), swap bytes through two byte registers, walk toward the middle,
stop when `rsi >= rdi`, then write(1, msg, msglen). Seeing `!dlrow olleh`
print means every piece of weeks 1–6 just worked at once.

gdb: `watch $rax` during the max loop stops exactly at each new champion.

## Solve (~20 min)

1. **Sum with both walks**: sum the table twice — index walk and pointer
   walk. Same answer, different code. Feel which one you prefer.
2. **lea golf**: compute 5·rax, 9·rax, and 40·rax with no `imul`, `lea` only
   (40 needs two — combine a lea with a shift or a second lea).
3. **Strided access**: interpret the same `table` as *dword* pairs and sum
   only the elements at even dword indexes (`[table + rcx*4]`, step 2).
   Little-endianness (week 3) explains the values you get — explain them.

## Tool tip of the week

`make dump f=w06` and find your `[table + rcx*8]` line: the disassembler
writes it as `mov rax, [rcx*8 + 0x402000]` — the label became a bare number.
Labels never survive into the machine; addressing hardware only sees the
formula. That's also why `p &table` and `x/8gx &table` work in gdb: the
DWARF debug info (your `-g -F dwarf` build flag) remembers what nasm knew.

## Check yourself

- Which scales are legal, and what goes wrong walking a `dq` array with `*4`?
- What is the difference between `mov rax, [rbx+8]` and `lea rax, [rbx+8]`?
- Why is `lea` usable for arithmetic at all?
