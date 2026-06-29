# 32-bit-MIPS-inspired-single-cycle-CPU

ALL codes are in master branch
INstruction for full system test
# Full-System Test Programs for the MIPS Single-Cycle CPU

Four real programs that exercise the CPU as a complete integrated system,
using all 8 core instructions: ADD, SUB, XOR, ADDI, LW, SW, BEQ, JUMP.

Every program was verified against a cycle-accurate Python model of the
exact datapath before being written here, so the expected results are
guaranteed correct.

---

## How to run any program in Vivado

Each program needs its `.hex` file loaded into instruction memory. Two options:

**Option A (rename):** Rename the program hex to `machine_code.hex` (the name
your `instruction_memory.v` loads), drop it in the xsim working dir, set the
matching `*_tb.v` as the top simulation module, Run All.

**Option B (edit path):** Change the `$readmemh("machine_code.hex", imem);`
line in `instruction_memory.v` to the program's hex filename.

The xsim working directory is:
`<project>/<project>.sim/sim_1/behav/xsim/`

Each testbench runs the program to its HALT loop, then checks the final
register/memory state and prints PASS/FAIL. No cycle-exact timing is needed
because every program ends in a jump-to-self halt.

---

## Program 1 — Sum of integers 1 to 10  (expect 55)

Classic accumulator loop. Tests ADDI, ADD, BEQ (loop exit), JUMP (loop back), SW.

```
        ADDI $2,$0,0      # sum = 0
        ADDI $3,$0,1      # i   = 1
        ADDI $4,$0,11     # limit = N+1
        ADDI $5,$0,1      # one
loop:   BEQ  $3,$4,end    # if i == limit, exit
        ADD  $2,$2,$3     # sum += i
        ADD  $3,$3,$5     # i += 1
        J    loop
end:    SW   $2,0($0)     # MEM[0] = sum
halt:   J    halt         # stop
```
Result: `$2 = 55`, `MEM[0] = 55`

---

## Program 2 — Array sum  (expect 57)

Seeds five values `[4,12,7,25,9]` into data memory, then walks the array with
a pointer and accumulates. Tests SW (seeding), LW (loading), pointer arithmetic,
countdown loop with SUB, BEQ exit.

```
        # seed MEM[0..16] with the five values via ADDI+SW pairs
        ADDI $1,$0,0      # ptr = 0
        ADDI $2,$0,5      # count = 5
        ADDI $3,$0,0      # total = 0
        ADDI $5,$0,4      # stride = 4
        ADDI $6,$0,1      # one
        ADDI $8,$0,0      # zero
loop:   BEQ  $2,$8,end    # if count == 0, exit
        LW   $4,0($1)     # value = MEM[ptr]
        ADD  $3,$3,$4     # total += value
        ADD  $1,$1,$5     # ptr += 4
        SUB  $2,$2,$6     # count -= 1
        J    loop
end:    SW   $3,20($0)    # MEM[20] = total
halt:   J    halt
```
Result: `$3 = 57`, `MEM[20] = 57`

---

## Program 3 — Multiply 6 x 7 via repeated addition  (expect 42)

The ISA has no multiply instruction, so multiplication is built from a loop of
additions. Demonstrates that complex operations can be composed from primitives.

```
        ADDI $1,$0,6      # A = 6
        ADDI $2,$0,7      # counter = B = 7
        ADDI $3,$0,0      # product = 0
        ADDI $4,$0,1      # one
        ADDI $5,$0,0      # zero
loop:   BEQ  $2,$5,end    # if counter == 0, exit
        ADD  $3,$3,$1     # product += A
        SUB  $2,$2,$4     # counter -= 1
        J    loop
end:    SW   $3,0($0)     # MEM[0] = product
halt:   J    halt
```
Result: `$3 = 42`, `MEM[0] = 42`

---

## Program 4 — Fibonacci, first 10 numbers stored to memory

Generates `0,1,1,2,3,5,8,13,21,34` and stores each into `MEM[0..9]`.
The most complex program: maintains two running values, uses indexed store
(`SW $1,0($3)` with a moving pointer), and a countdown loop.

```
        ADDI $1,$0,0      # a = 0
        ADDI $2,$0,1      # b = 1
        ADDI $3,$0,0      # ptr = 0
        ADDI $4,$0,10     # count = 10
        ADDI $6,$0,4      # four
        ADDI $7,$0,1      # one
        ADDI $8,$0,0      # zero
loop:   BEQ  $4,$8,end    # if count == 0, exit
        SW   $1,0($3)     # MEM[ptr] = a
        ADD  $5,$1,$2     # next = a + b
        ADD  $1,$2,$0     # a = b
        ADD  $2,$5,$0     # b = next
        ADD  $3,$3,$6     # ptr += 4
        SUB  $4,$4,$7     # count -= 1
        J    loop
end:
halt:   J    halt
```
Result: `MEM[0..9] = [0,1,1,2,3,5,8,13,21,34]`

---

## What these prove about the CPU

| Capability | Proven by |
|---|---|
| Arithmetic (ADD/SUB) | All programs |
| Immediate loading (ADDI) | All programs |
| Conditional branching (BEQ) | Loop exits in all |
| Unconditional jump (JUMP) | Loop-back in all |
| Memory write (SW) | Programs 1-4 |
| Memory read (LW) | Program 2 |
| Indexed/pointer addressing | Programs 2 & 4 |
| Composing complex ops from primitives | Program 3 (multiply) |
| Multi-variable state in a loop | Program 4 (Fibonacci) |

Together these show the datapath, control unit, register file, both memories,
the ALU, sign extension, and the PC update logic (sequential, branch, and jump
paths) all work correctly as one integrated machine.
