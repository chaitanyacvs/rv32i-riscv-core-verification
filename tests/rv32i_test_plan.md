# RV32I Test Plan

## 1. Arithmetic and logical operations
- Addition and subtraction
- Signed and unsigned comparisons
- Bitwise AND, OR, and XOR
- Logical and arithmetic shifts
- Immediate arithmetic and logical operations

## 2. Register behavior
- Writes to general-purpose registers
- Register x0 remains zero
- Positive and negative operands
- Boundary values and sign extension

## 3. Control flow
- Conditional branch taken
- Conditional branch not taken
- Forward and backward branch targets
- Jump and link behavior
- Jump register behavior

## 4. Upper-immediate instructions
- LUI immediate loading
- AUIPC program-counter-relative calculation
- Positive and negative upper immediates

## 5. Regression procedure
1. Run ./scripts/run_all.sh.
2. Review every testbench result.
3. Confirm that error counters are zero.
4. Investigate compiler warnings and simulation failures.
5. Preserve the output as a verification report.

## Current regression
The four existing testbenches reported PASS with zero test errors
in the captured run on 2026-10-27.

This records the observed regression; it does not establish complete
compliance with every RV32I instruction or corner case.
