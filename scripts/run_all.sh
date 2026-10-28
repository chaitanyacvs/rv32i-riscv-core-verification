#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p reports

run_test() {
    local top="$1"
    local tb="$2"
    local log="$3"
    local expected="$4"
    local output="/tmp/${top}_sim"

    echo ""
    echo "======================================"
    echo "Running: ${top}"
    echo "======================================"

    if [[ "$top" == "tb_rv32i_core" ]]; then
        if ! iverilog -g2012 -s "$top" -o "$output" \
            rtl/rv32i_core.sv assertions/rv32i_core_assertions.sv "$tb"; then
            echo "REGRESSION FAIL: compilation failed for $top"
            exit 1
        fi
    elif ! iverilog -g2012 -s "$top" -o "$output" \
        rtl/rv32i_core.sv "$tb"; then
        echo "REGRESSION FAIL: compilation failed for $top"
        exit 1
    fi

    if ! vvp "$output" 2>&1 | tee "$log"; then
        echo "REGRESSION FAIL: simulation failed for $top"
        exit 1
    fi

    if grep -Eq '(^FAIL|Errors: [1-9][0-9]*)' "$log"; then
        echo "REGRESSION FAIL: test errors in $top"
        exit 1
    fi

    if ! grep -Fq "$expected" "$log"; then
        echo "REGRESSION FAIL: expected PASS marker missing for $top"
        exit 1
    fi

    echo "REGRESSION PASS: $top"
}

run_test tb_rv32i_core \
    tb/tb_rv32i_core.sv \
    reports/tb_rv32i_core.log \
    "PASS: RV32I starter tests passed"

run_test tb_rv32i_extended \
    tb/tb_rv32i_extended.sv \
    reports/tb_rv32i_extended.log \
    "PASS: Extended RV32I tests passed"

run_test tb_rv32i_control_flow \
    tb/tb_rv32i_control_flow.sv \
    reports/tb_rv32i_control_flow.log \
    "PASS: Control-flow tests passed"

run_test tb_rv32i_upper_imm \
    tb/tb_rv32i_upper_imm.sv \
    reports/tb_rv32i_upper_imm.log \
    "PASS: LUI/AUIPC tests passed"

echo ""
echo "======================================"
echo "ALL FOUR REGRESSION TESTS PASSED"
echo "======================================"
