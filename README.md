# RV32I RISC-V Core Verification Starter

A small, educational **single-cycle RV32I-style processor starter** with an Icarus-Verilog-compatible self-checking testbench. It is designed to be extended incrementally into a portfolio project.

## Current scope

The starter RTL implements a useful subset of RV32I instructions:
- R-type: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLTU`, `SLL`, `SRL`, `SRA`
- I-type: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLTIU`, `SLLI`, `SRLI`, `SRAI`
- Memory: `LW`, `SW`
- Control flow: `BEQ`, `BNE`, `JAL`, `JALR`
- Upper immediate: `LUI`, `AUIPC`

This is an educational starter, **not yet a complete/validated RV32I implementation**. In particular, the current simplified memory model assumes aligned word accesses and does not implement exceptions/CSRs, interrupts, privilege modes, or the `FENCE` family. Illegal-instruction handling is minimal. Treat unsupported encodings as out of scope until added and tested.

## Requirements

Install Icarus Verilog on macOS if needed:

```bash
brew install icarus-verilog
```

## Run

From the project root:

```bash
./scripts/run.sh
```

Or manually:

```bash
iverilog -g2012 -s tb_rv32i_core -o /tmp/rv32i_sim rtl/rv32i_core.sv tb/tb_rv32i_core.sv
vvp /tmp/rv32i_sim
```

Expected ending:

```text
PASS: RV32I starter tests passed
```

## Architecture

- `rtl/rv32i_core.sv`: single-cycle core with instruction input and simple data memory interface.
- `tb/tb_rv32i_core.sv`: self-checking testbench with a small instruction program.
- `tests/`: future directed and randomized test programs.
- `assertions/`: future assertions.
- `reports/`: generated logs.
- `scripts/run.sh`: compile and run.

## Interface

The core fetches an instruction from `instr` at `pc`. The testbench supplies instructions combinationally. Data memory is exposed via `mem_addr`, `mem_wdata`, `mem_wstrb`, `mem_we`, and `mem_rdata`.

## Roadmap

1. Add tests for every implemented instruction and corner cases.
2. Add an independent reference model and architectural scoreboard.
3. Add randomized instruction sequences and deterministic seeds.
4. Add assertion checks and coverage counters.
5. Add bug injection and regression automation.
6. Extend to full RV32I behavior and compare against an independent RISC-V reference tool.
7. Port to a UVM-capable simulator for class-based UVM verification.

**UVM note:** Icarus Verilog does not support the full standard class-based UVM environment. This starter intentionally uses a procedural testbench so it can run with Icarus first.
