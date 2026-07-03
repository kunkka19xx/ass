## I learn assembly for fun

### I use

1. NASM
2. NIXOS x86-64
3. AMD

### Workflow

```sh
nix develop     # enter the shell (nasm, gdb, strace)
make new          # create the next numbered exercise from template.asm
make new n=hello  # or create a named one: hello.asm
make run          # build + run the .asm you edited last
make run f=hello  # build + run a specific exercise
make debug f=2    # gdb, stopped at _start (si to step, info registers)
make dump f=2     # disassemble what nasm actually produced
make trace f=2    # strace: watch your syscalls happen
```

### Useful resources

[Syscall tbl](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md) 
[Sessions](https://www.tutorialspoint.com/assembly_programming/assembly_constants.htm) 

### Task 

- [ ] Follow the [16-week course](learning-plan/README.md) in `learning-plan/` (2h/week)
- [ ] Programming from the groundup [ref](https://download-mirror.savannah.gnu.org/releases/pgubook/ProgrammingGroundUp-1-0-booksize.pdf) 

