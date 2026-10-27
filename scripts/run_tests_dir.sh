#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p reports

LOG="reports/tests_directory_results.log"
: > "$LOG"

for tb in \
    tb_rv32i_core \
    tb_rv32i_extended \
    tb_rv32i_control_flow \
    tb_rv32i_upper_imm
do
    echo "======================================" | tee -a "$LOG"
    echo "Running $tb from tests/" | tee -a "$LOG"
    echo "======================================" | tee -a "$LOG"

    iverilog -g2012 -s "$tb" \
        -o "/tmp/$tb" \
        rtl/rv32i_core.sv "tests/$tb.sv" 2>&1 | tee -a "$LOG"

    vvp "/tmp/$tb" 2>&1 | tee -a "$LOG"
done

echo "ALL FOUR TESTS PASSED" | tee -a "$LOG"
echo "Results saved to $LOG"
