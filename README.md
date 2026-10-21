# SAP-1 on an FPGA

A complete implementation of SAP-1 ("Simple As Possible"), the classic teaching microprocessor, written in Verilog and running on a Nexys A7 board (Xilinx Artix-7). The processor fetches, decodes and executes one instruction per clock cycle, and the board shows the contents of its accumulator live on the seven-segment display, at one instruction per second, so every step of a program can be watched as it happens.

I built it in the processor architecture lab at POLITEHNICA Bucharest (2026). The lab provided the instruction set, the top-level CPU module, the instruction memory and the testbench ([course repository](https://github.com/raresifrim/sap1-single-cycle-public)); the datapath and control modules, and the whole FPGA integration (clock divider, display driver and pin constraints), are my implementation.

## The instruction set

SAP-1 is an accumulator machine. There is a single working register, the accumulator (ACC), and every operation either loads a value into it or changes it. Instructions are 8 bits wide: the top two bits select the operation and the low six bits carry an immediate operand.

```
00_XXXXXX   LOAD X    ACC = X
01_XXXXXX   ADD  X    ACC = ACC + X
10_XXXXXX   SUB  X    ACC = ACC - X
11_000000   OUT       hold ACC on the output
11_111111   HALT      stop execution
```

Data is 6 bits wide and unsigned, so arithmetic wraps around modulo 64.

## Microarchitecture

The design is single-cycle: in every clock cycle, an instruction is fetched, decoded and executed, and its result is written back on the next rising edge.

- **PC.** An 8-bit program counter that starts at 0 on reset and increments on every rising edge while it is enabled. HALT disables it, which freezes the processor on the HALT instruction.
- **MEMORY.** A 256-byte instruction ROM, read asynchronously: the instruction appears as soon as the address changes. It is initialised from `code.mem` at synthesis or simulation time.
- **DECODER.** Purely combinational. It looks at the two opcode bits and produces the control signals: `LOAD_ACC` for LOAD, `OP` to choose between addition and subtraction (which is simply the most significant bit of the instruction), `OUT_ACC` and `HALT` for the two special encodings, and the immediate value routed either to the multiplexer (`A`, for LOAD) or to the ALU (`B`, for ADD and SUB).
- **ALU.** A combinational 6-bit adder and subtractor.
- **MUX.** Selects what is written into the accumulator: the immediate value for LOAD, or the ALU result for ADD and SUB.
- **ACCUMULATOR.** A 6-bit register built from D flip-flops, with an asynchronous reset and an enable. OUT disables it for that cycle, so the current value is held unchanged.

The control logic needs no state machine: every decision is a function of the current instruction alone, which is what makes a single-cycle design possible.

## Running it on the board

The Artix-7 runs from a 100 MHz oscillator, far too fast to follow by eye, so `top_fpga.v` wraps the processor with two pieces of logic.

**A clock divider.** A counter running on the 100 MHz clock toggles a slow clock every 50 million cycles, producing a 1 Hz signal that drives the processor. One instruction executes per second.

**A multiplexed display driver.** The eight digits of the Nexys A7 display share their segment lines, so only one digit can be lit at a time. A free-running counter alternates between the two rightmost digits fast enough (a few hundred times per second) for the eye to see both as continuously lit. The 6-bit accumulator is shown in hexadecimal: the low four bits on the right digit, the top two bits on the left. Each 4-bit value is converted to the active-low segment pattern for its hex digit.

The pin assignments for the clock, the reset button (BTNC) and the display are in `constrains.xdc`.

## Simulation

`cpu_testbench.v` holds the processor in reset for one cycle and then lets it run the test program. The program loads and modifies the accumulator, outputs 10, starts again from 0 and outputs 31:

```
00_000001   LOAD 1    ACC = 1
01_000010   ADD 2     ACC = 3
01_000011   ADD 3     ACC = 6
10_000100   SUB 4     ACC = 2
01_001110   ADD 14    ACC = 16
10_000110   SUB 6     ACC = 10
11_000000   OUT       10
00_000000   LOAD 0    ACC = 0
01_111111   ADD 63    ACC = 63
01_100000   ADD 32    ACC = 31  (95 mod 64)
11_000000   OUT       31
11_111111   HALT
```

The tenth instruction is a small trap in the original test program: it is commented as `SUB 32`, but its opcode is `01`, so it is actually `ADD 32`. Because arithmetic wraps around modulo 64, adding 32 and subtracting 32 give the same result, 63 + 32 = 95 ≡ 31 and 63 − 32 = 31, so the program outputs 31 either way and the mislabel is invisible in the results.

On the board, the same program counts through these values one per second, and the display stops at `1F` (31) when the processor halts.

## Building

The project targets the `xc7a100tcsg324-1` part (Nexys A7-100T) and was built with Vivado 2024.1. Open `SAP1.xpr`, run the behavioural simulation with `cpu_testbench` as the top module, or run synthesis and implementation with `top_fpga` as the top module, then program the board.

## Design notes

A few choices are worth stating plainly, because they are the first things I would change in a larger design.

- **The 1 Hz clock is generated in logic.** The divided clock comes out of a flip-flop and drives the processor's registers directly. This works at such a low frequency, but in general a clock produced in fabric logic does not use the FPGA's dedicated clock network and can introduce skew. The cleaner approach is to keep everything on the 100 MHz clock and give the processor a clock enable that pulses once per second.
- **The reset button is used asynchronously and is not debounced.** For a board demo this is harmless, but a production design would synchronise the button to the clock and filter its bounces.
- **The decoder has two separate immediate outputs**, `A` for LOAD and `B` for ADD and SUB, as specified by the lab. A single immediate bus would be more economical in hardware.

## Project structure

```
SAP1.srcs/sources_1/new/   processor modules, FPGA top level and test program (code.mem)
SAP1.srcs/sim_1/new/       testbench
SAP1.srcs/constrs_1/new/   pin constraints for the Nexys A7
SAP1.xpr                   Vivado project
```
