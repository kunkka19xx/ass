# Cheatsheet - keep this open

## Registers (64-bit general purpose)

| 64-bit  | 32-bit | 16-bit | 8-bit | Conventional role                                 | Saved by   |
| ------- | ------ | ------ | ----- | ------------------------------------------------- | ---------- |
| rax     | eax    | ax     | al    | return value, syscall number                      | caller     |
| rbx     | ebx    | bx     | bl    | free                                              | **callee** |
| rcx     | ecx    | cx     | cl    | 4th arg, loop counter (**clobbered by syscall!**) | caller     |
| rdx     | edx    | dx     | dl    | 3rd arg, high half of mul/div                     | caller     |
| rsi     | esi    | si     | sil   | 2nd arg, string source                            | caller     |
| rdi     | edi    | di     | dil   | 1st arg, string destination                       | caller     |
| rbp     | ebp    | bp     | bpl   | frame pointer (optional)                          | **callee** |
| rsp     | esp    | sp     | spl   | stack pointer - don't play with it                | **callee** |
| r8–r9   | r8d    | r8w    | r8b   | 5th, 6th arg                                      | caller     |
| r10     | r10d   | r10w   | r10b  | 4th arg **for syscalls**                          | caller     |
| r11     | r11d   | r11w   | r11b  | free (**clobbered by syscall!**)                  | caller     |
| r12–r15 | r12d…  | r12w…  | r12b… | free                                              | **callee** |

⚠ Writing a **32-bit** register zeroes the top 32 bits: `mov eax, 1` also
clears the top of rax. Writing 8/16-bit registers does **not**.

### What the roles actually mean

First, the big picture: **any general-purpose register can hold any value.**
The CPU doesn't care. The "roles" are _conventions_ - agreements about who
puts what where, so your code can talk to the kernel (syscalls) and to other
functions (the C calling convention, "System V ABI"). A few instructions do
hard-wire specific registers, and those are called out below.

- **rax - the "result" register.** Two jobs: you put the _syscall number_ in
  it before `syscall`, and the return value of every syscall/function comes
  back in it. Also hard-wired by `mul`/`div`, which always operate on rax.
- **rdi, rsi, rdx, rcx, r8, r9 - argument slots, in that order.** When you
  call a function (or make a syscall), the 1st argument goes in rdi, 2nd in
  rsi, 3rd in rdx, and so on. That's why `write(fd, buf, count)` becomes
  "fd in rdi, buf in rsi, count in rdx". You don't have to memorize which
  register is "the buffer one" - it's just argument position.
  - One wrinkle: for **syscalls** the 4th argument goes in **r10**, not rcx,
    because the `syscall` instruction itself destroys rcx (it stashes the
    return address there).
  - Historical names: rsi = "source index", rdi = "destination index" - the
    string-copy instructions (`movsb` etc.) read from [rsi] and write to
    [rdi]. That's where "string source/destination" in the table comes from.
- **rcx - also the loop counter.** The `loop` instruction and shift-by-
  register (`shl rax, cl`) hard-wire rcx/cl. Otherwise it's just arg #4
  (for function calls, not syscalls - see above).
- **rdx - also the "overflow half".** `mul` puts the high 64 bits of the
  product in rdx; `div` divides the 128-bit pair rdx:rax. That's why you
  zero rdx before dividing.
- **rsp - the stack pointer.** Always points at the top of the stack.
  `push`, `pop`, `call`, `ret` all read and modify it behind your back -
  that's why you don't use it for anything else.
- **rbp - the frame pointer.** Convention: a function saves rsp into rbp on
  entry so it has a fixed reference point for its locals while rsp moves
  around. Entirely optional in hand-written asm; until you use it for that,
  treat it as a free callee-saved register.
- **rbx, r12–r15 - "free" = no assigned job.** No instruction or convention
  claims them. Best pick for values you want to keep for a long time,
  because they're callee-saved (next paragraph).

### "Saved by caller" vs "saved by callee"

This column answers one question: **who is responsible for a register's
value surviving a `call`?**

- **Caller-saved** (rax, rcx, rdx, rsi, rdi, r8–r11): the function you call
  may freely trash these. If _you_ (the caller) still need the value
  afterwards, push it before the call and pop it after - or just don't keep
  anything important there across a call.
- **Callee-saved** (rbx, rbp, rsp, r12–r15): a function must return these
  unchanged. So if you _write_ a function that uses rbx, you (the callee)
  must push it at entry and pop it before `ret`. The flip side: values you
  keep in r12–r15 safely survive any function call.

Rule of thumb: scratch work → caller-saved registers; anything that must
live across a `call` → callee-saved. `syscall` is gentler than a function
call: it only clobbers rax (the return value), rcx and r11.

## Syscalls (Linux x86-64)

Number in `rax`, args in `rdi, rsi, rdx, r10, r8, r9`, then `syscall`.
Return value in `rax` (negative = `-errno`). Clobbers `rcx` and `r11`.

| rax | name  | rdi                               | rsi    | rdx    |
| --- | ----- | --------------------------------- | ------ | ------ |
| 0   | read  | fd                                | buffer | count  |
| 1   | write | fd                                | buffer | count  |
| 2   | open  | path                              | flags  | mode   |
| 3   | close | fd                                |        |        |
| 8   | lseek | fd                                | offset | whence |
| 60  | exit  | status (only low 8 bits survive!) |        |        |

fd 0 = stdin, 1 = stdout, 2 = stderr.

## Defining data

| Directive           | Size             | Example              |
| ------------------- | ---------------- | -------------------- |
| db                  | 1 byte           | `msg db 'hi', 10`    |
| dw                  | 2                | `port dw 8080`       |
| dd                  | 4                | `pi dd 3.14159`      |
| dq                  | 8                | `big dq 123456789`   |
| resb/resw/resd/resq | reserve (`.bss`) | `buf resb 64`        |
| equ                 | constant         | `msglen equ $ - msg` |
| times               | repeat           | `times 8 db 0`       |

## Addressing modes

```nasm
mov rax, [label]              ; contents at label
mov rax, [rbx]                ; contents at address in rbx
mov rax, [rbx + 8]            ; ...plus displacement
mov rax, [rbx + rcx*8]        ; base + index*scale (scale: 1,2,4,8)
mov rax, [rbx + rcx*8 + 16]   ; the full form
lea rax, [rbx + rcx*8 + 16]   ; the ADDRESS itself, no memory access
mov qword [buf], 5            ; size keyword needed when no register tells it
```

No memory-to-memory `mov`. No 64-bit immediate to memory (go via a register).

## Conditional jumps (after `cmp a, b`)

| Meaning | Signed | Unsigned |
| ------- | ------ | -------- |
| a == b  | je     | je       |
| a != b  | jne    | jne      |
| a < b   | **jl** | **jb**   |
| a <= b  | jle    | jbe      |
| a > b   | **jg** | **ja**   |
| a >= b  | jge    | jae      |

Mixing these up is the classic bug: `jl` reads sign flags, `jb` reads carry.
Also: `jz`/`jnz` = `je`/`jne`; `test rax, rax` + `jz` = "is it zero?".

## gdb survival kit

```
make debug f=w05        starts gdb already broken at _start
si                      step one instruction (ni to skip over call)
info registers          all registers   (i r rax rbx - just some)
p/x $rax                print rax in hex   p/d = decimal  p/t = binary
x/8xb &label            examine 8 bytes at label, hex
x/s &msg                examine as string
x/4gx $rsp              top 4 qwords of the stack
layout asm              TUI: source/disasm view  (layout regs adds registers)
c                       continue    q  quit
```

## NASM gotchas collected along the course

- `mov [mem], 123` needs a size: `mov qword [mem], 123`
- `mov` can't do mem→mem or imm64→mem (weeks 2–3)
- 32-bit writes zero-extend, 8/16-bit writes don't (week 2)
- `div` uses rdx:rax - zero rdx first (`xor edx, edx`), or `cqo` before `idiv` (week 4)
- `syscall` clobbers rcx and r11 (week 9)
- exit status is one byte: `exit(256)` looks like `exit(0)` (week 5)
- local labels start with a dot: `.loop` belongs to the last normal label (week 8)
