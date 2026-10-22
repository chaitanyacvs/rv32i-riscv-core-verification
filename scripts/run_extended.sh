#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p reports

iverilog -g2012 -s tb_rv32i_extended \
    -o /tmp/rv32i_extended_sim \
    rtl/rv32i_core.sv tb/tb_rv32i_extended.sv

vvp /tmp/rv32i_extended_sim | tee reports/extended_run.log
