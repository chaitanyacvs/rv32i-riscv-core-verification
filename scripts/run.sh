#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p reports
iverilog -g2012 -s tb_rv32i_core -o /tmp/rv32i_sim rtl/rv32i_core.sv tb/tb_rv32i_core.sv
vvp /tmp/rv32i_sim | tee reports/last_run.log
