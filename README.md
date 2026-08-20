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

