# Week 15 — Performance & a peek at SIMD

**Goal:** measure your code honestly with rdtsc, learn the two or three
things that actually dominate performance on a modern AMD core, and meet
the XMM registers.

## Read (~40 min)

### Your CPU is not the week-1 model

The mental model so far — "one instruction after another" — is what the CPU
*pretends* to do. Your AMD Zen core actually:

- decodes several instructions per cycle and runs them **out of order**,
- **predicts branches** and speculates past them (a mispredict costs ~15
  cycles of thrown-away work),
- serves memory through **caches**: L1 hit ≈ 4 cycles, L2 ≈ 12, L3 ≈ 40,
  RAM ≈ 200+. Memory moves in **64-byte cache lines** — touching 1 byte
  fetches 64.

Three consequences worth more than all instruction-level tricks combined:

1. **Memory access pattern beats instruction count.** Walking an array
   forward (like `rep movsb`, like your week-6 loops) lets the prefetcher
   feed you; jumping around randomly starves the core.
2. **Predictable branches are nearly free; random ones are expensive.**
   Sorted data is faster to filter than shuffled data — same instructions!
3. Dependent instructions can't overlap: `add rax,1; add rax,1; ...` is a
   chain; summing into *two* registers and combining at the end lets the
   core run both chains at once.

### rdtsc: the cycle counter

```nasm
rdtsc               ; edx:eax = timestamp counter (clobbers rdx, rax!)
shl rdx, 32
or  rax, rdx        ; rax = full 64-bit tick count
```

Measure = read, run the code, read again, subtract, print (print_uint!).
Honest-measurement rules: run the thing in a loop (thousands of iterations)
and take the total; do a warm-up pass first (first run pays the cache
misses); expect noise between runs.

### XMM: registers that hold 16 bytes

SSE2 (baseline on every x86-64 CPU, so yours) adds registers xmm0–xmm15,
each **16 bytes wide**, with instructions operating on all bytes at once:

```nasm
movdqa xmm0, [a]        ; load 16 bytes  (a must be 16-byte ALIGNED — align 16)
movdqu xmm0, [a]        ;   ...unaligned version, u = unaligned
paddb  xmm0, [b]        ; 16 independent byte-additions in ONE instruction
paddq  xmm0, xmm1       ; or 2 qword-additions ("p" = packed)
movdqa [result], xmm0
```

This is SIMD — Single Instruction, Multiple Data. Modern memcpy, strlen,
image codecs, and your GPU's whole worldview run on this idea. Today is a
taste, not a course (that would be AVX2 and a rabbit hole worth months).

## Type (~60 min)

`make new n=w15` — build a small benchmark harness:

1. A `BENCH` macro (week 14!) that takes a label, rdtsc's around a `call`,
   and prints the delta.
2. **Race 1 — copy showdown**: your week-6 byte-loop copy vs `rep movsb`,
   copying the same 64 KB `.bss` buffer 1000 times. On Zen, expect rep
   movsb to win hard — this is ERMS from week 12, now with numbers.
3. **Race 2 — dependency chains**: sum a `dq` array of 100k elements
   (a) into one accumulator, (b) into two alternating accumulators, added
   at the end. Same instruction count, measurable difference — you're
   watching out-of-order execution exist.
4. **Race 3 — SIMD taste**: sum the array again 2 qwords at a time with
   `paddq xmm0, [table + rcx*8]`. Extract the two halves at the end
   (`movq rax, xmm0` gets the low one; `psrldq xmm0, 8` shifts the high one
   down — or just store xmm0 to memory and load both qwords, no shame).
   Don't forget `align 16` on the table, or movdqa will teach you about
   alignment faults the hard way (once is educational; it's a real crash
   with a real signal — SIGSEGV on an *aligned-load* instruction).

Print all times. Save this file — it's your lab bench for every future
"which is faster?" argument. The answer to those arguments is now always:
*"let's measure."*

## Solve (~20 min)

1. **Branch predictor safari**: filter-count elements > 500 in (a) an
   ascending table (`%assign`-generated, week 14) vs (b) the same values
   scrambled by hand. Same count, same instructions — time both. Explain
   the gap in one sentence.
2. **Cache line proof**: sum every byte of a 1 MB buffer with stride 1 vs
   stride 64 vs stride 4096. Ops shrink by 64× and 4096× — does time?
   (No. Why not?)
3. **memset showdown**: your rep stosb memset vs a qword-at-a-time store
   loop vs `movdqa` stores. Crown a champion at 4 KB and at 4 MB — is it
   the same champion? (L1 vs RAM: the sizes were chosen to disagree.)

## Tool tip of the week

`cat /proc/cpuinfo | grep flags` — your CPU's actual capabilities: find
`sse2`, `avx2`, `erms`… before using an instruction set. `lscpu` shows your
real cache sizes (compare with exercise 2!). And `perf stat ./w15` — if
available — counts branch-misses and cache-misses from hardware counters:
your explanations, fact-checked by silicon.

## Check yourself

- Rank: L1 hit, branch mispredict, RAM access — by cost.
- Why do two accumulators beat one for a sum?
- movdqa vs movdqu — the difference, the risk, the fix?
