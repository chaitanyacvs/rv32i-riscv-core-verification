#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p reports

iverilog -g2012 -s tb_rv32i_control_flow \
    -o /tmp/rv32i_control_flow_sim \
    rtl/rv32i_core.sv tb/tb_rv32i_control_flow.sv

vvp /tmp/rv32i_control_flow_sim | tee reports/control_flow_run.log
