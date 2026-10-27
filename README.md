# RV32I RISC-V Core Verification

[![Language](https://img.shields.io/badge/Language-Verilog%2FSystemVerilog-blue)](https://www.systemverilog.io/)
[![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog-orange)](https://github.com/steveicarus/iverilog)
[![Formal Verification](https://img.shields.io/badge/Formal-Yosys%20%7C%20SBY-purple)](https://symbiyosys.readthedocs.io/)

A hardware verification project focused on validating the functional behavior of an RV32I RISC-V processor using simulation-based testing, assertions, and formal verification techniques.

## Overview

RISC-V is an open instruction set architecture (ISA) designed to support flexible processor implementations. The RV32I base integer instruction set operates on 32-bit registers and provides arithmetic, logical, memory-access, and control-flow instructions.

This project establishes a structured verification workflow for an RV32I processor implementation. It combines simulation testbenches with formal properties to detect functional errors, check design behavior, and improve confidence in the correctness of the RTL.

The verification environment emphasizes reproducibility, automated execution, clear pass/fail reporting, and preservation of test results.

## Project Objectives

- Verify the functional behavior of an RV32I processor implementation.
- Exercise instruction execution using directed simulation tests.
- Check expected results and detect mismatches using testbench checks.
- Express key design requirements as assertions and formal properties.
- Run simulation and formal verification with open-source EDA tools.
- Automate verification through scripts.
- Maintain verification logs and document known limitations.

## Verification Scope

The intended verification scope includes the following areas, depending on the features supported by the processor RTL.

| Area                                | Verification focus                                              |
| ----------------------------------- | --------------------------------------------------------------- |
| Arithmetic operations               | Addition, subtraction, and supported arithmetic instructions    |
| Logical operations                  | AND, OR, XOR, and immediate variants                            |
| Shift operations                    | Logical and arithmetic shifts                                   |
| Register operations                 | Register reads, writes, and architectural state updates         |
| Memory operations                   | Load and store instructions, address handling, and access sizes |
| Branch instructions                 | Conditional branch decisions and target calculation             |
| Jump instructions                   | Jump target calculation and link-register behavior              |
| Immediate decoding                  | Immediate extraction, sign extension, and instruction decoding  |
| Control logic                       | Instruction sequencing and control-signal consistency           |
| Reset behavior                      | Initial processor state and reset handling                      |
| Illegal or unsupported instructions | Behavior defined by the specific implementation                 |

_The actual supported verification scope depends on the RTL and testbenches present in the repository._

## Verification Architecture

```text
                 Verification Environment
                           |
                 +---------+---------+
                 |                   |
          Simulation Tests      Formal Checks
                 |                   |
          Testbench Stimulus    Assertions/Properties
                 |                   |
                 v                   v
             RV32I DUT         Formal Engine
                 |                   |
          Actual Outputs       Proof/Counterexample
                 |
                 v
          Expected-Value Checks
                 |
                 v
           PASS / FAIL Results
                 |
                 v
          Logs and Reports
```

### Simulation-Based Verification

Simulation testbenches apply instruction sequences and input conditions to the processor. Expected behavior is checked through assertions, reference-model comparisons, or explicit testbench checks, depending on the implementation.

### Formal Verification

Formal properties describe conditions that must hold under specified assumptions. The formal engine searches for counterexamples to those properties within the configured model and proof setup.

Simulation and formal verification complement each other: simulation exercises selected scenarios, while formal verification can explore a broader state space within its assumptions and proof limitations.

## Tools and Technologies

| Tool                    | Purpose                                 |
| ----------------------- | --------------------------------------- |
| Verilog / SystemVerilog | RTL design and verification testbenches |
| Icarus Verilog          | RTL compilation and simulation          |
| VVP                     | Execution of compiled simulations       |
| Yosys                   | RTL processing and formal preparation   |
| SymbiYosys (SBY)        | Formal verification orchestration       |
| `yosys-smtbmc`          | SMT-based formal property checking      |
| Z3                      | SMT solver                              |
| Bash                    | Verification automation                 |
| Git and GitHub          | Version control and project hosting     |

## Repository Structure

The following is a suggested organization. Keep only directories and files that actually exist in your repository.

```text
rv32i-riscv-core-verification/
├── rtl/                    # Processor RTL modules
├── tb/                     # Simulation testbenches
├── tests/                  # Directed and regression tests
├── assertions/             # SystemVerilog assertions/properties
├── formal/                 # Formal harnesses and configuration
├── scripts/
│   └── run_sim.sh          # Simulation entry point, if present
├── results/                # Simulation logs and reports
└── README.md
```

## Getting Started

### Prerequisites

Install the required tools for the verification flows you intend to run:

- Icarus Verilog
- VVP
- Yosys
- SymbiYosys
- `yosys-smtbmc`
- Z3

Check tool availability:

```bash
iverilog -V
vvp -V
yosys -V
sby --version
z3 --version
```

Some commands may be unavailable if the corresponding tools are not installed.

### Clone the Repository

```bash
git clone https://github.com/chaitanyacvs/rv32i-riscv-core-verification.git
cd rv32i-riscv-core-verification
```

If your GitHub repository uses a different name, replace the URL with the actual repository URL.

## Running Simulation Tests

If the repository contains `scripts/run_sim.sh`, run:

```bash
chmod +x scripts/run_sim.sh
./scripts/run_sim.sh
```

Alternatively, compile and execute a testbench directly using the source files and top module defined by your project:

```bash
iverilog -g2012 -o simulation.out \
    <rtl_source_files> <testbench_source_files>

vvp simulation.out
```

Replace the placeholders with the actual RTL and testbench paths. Review the simulation output for test failures, assertion errors, and pass/fail summaries.

## Running Formal Verification

If the repository includes a SymbiYosys configuration file, execute it using its actual filename:

```bash
sby -f <formal_configuration>.sby
```

The formal configuration should specify the appropriate source files, top module, engine, and proof mode.

Inspect the generated formal output to determine whether the properties passed, failed, or could not be proven. A failed property may produce a counterexample that can help identify a design or verification issue.

**Important:** A successful bounded check is not necessarily a proof for all possible execution lengths. Report the proof mode, assumptions, and bounds accurately.

## Verification Results

Use this section to summarize actual results from the latest committed simulation and formal logs.

Recommended reporting metrics include:

- Number of tests executed and passed.
- Number of failures and detected mismatches.
- Instruction categories exercised.
- Assertion pass/fail status.
- Formal proof status and depth.
- Counterexamples identified.
- Known unverified behaviors.

No numerical coverage percentage or formal pass claim is stated here because those results must be taken from the actual project logs.

## Debugging and Troubleshooting

### Simulation compilation errors

Check that all RTL dependencies and testbench files are included in the compilation command and that the selected top module is correct.

### Testbench mismatches

Inspect the failing instruction, input operands, expected result, actual result, and processor state to identify the source of the mismatch.

### Formal verification failures

Review the counterexample trace, assumptions, reset model, and property definitions. Distinguish a genuine RTL bug from an incorrect harness or overly restrictive assumption.

### Missing tool errors

Install the missing EDA tool and verify that its executable is available on your system's `PATH`.

## Engineering Practices

- Keep the RTL, testbench, and formal harness organized separately.
- Automate repeated simulation and formal runs.
- Preserve logs that support reported verification outcomes.
- Use deterministic tests for reproducible debugging.
- Add regression tests for discovered bugs.
- Document proof assumptions and known limitations.
- Avoid claiming complete ISA compliance
