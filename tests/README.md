# RV32I Verification Tests

This directory contains verification documentation and test coverage
for the RV32I processor core.

## Testbench locations

The executable SystemVerilog testbenches are maintained in `tb/`.

| Testbench | Coverage |
|---|---|
| tb_rv32i_core.sv | Core instruction checks |
| tb_rv32i_extended.sv | Extended arithmetic and logical operations |
| tb_rv32i_control_flow.sv | Branches and control-flow operations |
| tb_rv32i_upper_imm.sv | LUI and AUIPC instructions |

## Running the regression

From the repository root, run:

    ./scripts/run_all.sh

The script runs the four existing testbenches.

## Expected result

The regression should finish with:

    ALL FOUR REGRESSION TESTS PASSED

Review the simulation output and investigate any failures before
reporting a successful verification run.
