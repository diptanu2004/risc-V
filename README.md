# Barebones 5-Stage Pipelined RV32I CPU

This is a deliberately simplified interview/demo version of the original project. It keeps only what is needed to explain the resume bullets clearly.

## Architecture

Five stages:
1. IF - fetch instruction using PC
2. ID - decode and read register file
3. EX - ALU operation / branch comparison
4. MEM - load/store through the data-memory interface
5. WB - write result back to register file

## Supported instruction subset

- R-type: ADD, SUB, AND, OR, XOR, SLT
- ADDI
- LW
- SW
- BEQ

This is a practical RV32I subset, not the full ISA.

## Hazards

### Data forwarding
Forwarding unit selects operands from:
- ID/EX register file value: `00`
- MEM/WB result: `01`
- EX/MEM ALU result: `10`

This handles common ALU-to-ALU dependencies without waiting for writeback.

### Load-use hazard
If an instruction in EX is a load and the following instruction needs its destination register, one bubble is inserted. IF and ID are held for one cycle.

### Branch
BEQ is resolved in EX. A taken branch redirects the PC and flushes younger instructions.

## Simulation

Install Icarus Verilog and GTKWave, then double-click `run.bat`.

The simulation prints final register values and generates `cpu.vcd` for waveform inspection.

Expected ending:

`PASS: forwarding + load-use stall + memory path verified`

## Interview-level explanation

**Why five stages?**
"I split instruction execution into IF, ID, EX, MEM and WB so multiple instructions can be in flight simultaneously."

**Why forwarding?**
"A dependent instruction may need a result before it reaches WB. Instead of waiting, I forward the newer result from a later pipeline stage directly to the EX inputs."

**Why a stall is still needed?**
"For a load-use dependency, the loaded value is only available after MEM, so forwarding cannot provide it soon enough for the immediately following EX stage. I insert one bubble and hold IF/ID for one cycle."

**What is the memory interface?**
"The CPU exposes instruction-memory and data-memory signals: address, read/write enable and write data, while the testbench supplies the memory contents."

**How did you verify it?**
"I ran representative instructions including dependent arithmetic, store/load and a load-use dependency, then checked the results and inspected the pipeline signals in GTKWave."

## Important honesty point

If asked whether this is a complete RV32I implementation, say: "It implements the core RV32I subset needed for the project demonstration; it does not implement every RV32I instruction." Do not claim full ISA coverage.
