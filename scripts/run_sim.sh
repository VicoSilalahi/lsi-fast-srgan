#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/run_sim.sh [MODULE]
# MODULE defaults to tb_conv_mac_3x3 (expects tb/<MODULE>.v)
# Description: Build and run the specified testbench using Icarus Verilog,
#              then open the corresponding GTKWave file if it exists.

MODULE=${1:-tb_conv_mac_3x3}
BUILD_DIR=build
RTL_DIR=rtl
TB_DIR=tb
VVP_OUT=${BUILD_DIR}/${MODULE}.vvp

command -v iverilog >/dev/null 2>&1 || { echo "Error: iverilog not found in PATH."; exit 1; }
command -v vvp >/dev/null 2>&1 || { echo "Error: vvp not found in PATH."; exit 1; }

mkdir -p "${BUILD_DIR}"

TB_FILE=${TB_DIR}/${MODULE}.v
if [ ! -f "${TB_FILE}" ]; then
  echo "Testbench ${TB_FILE} not found." >&2
  exit 2
fi

echo "Building ${MODULE}..."
iverilog -g2012 -o "${VVP_OUT}" ${RTL_DIR}/*.v "${TB_FILE}"

echo "Running ${MODULE}..."
vvp "${VVP_OUT}"

# Open .gtkw (sim/*.gtkw) file in GTKWave if it exists
# Otherwise, open the generated .vcd (sim/*.vcd) file if it exists

if [ -f "sim/${MODULE}.gtkw" ]; then
  echo "GTKWave file found: sim/${MODULE}.gtkw"
  if command -v gtkwave >/dev/null 2>&1; then
    echo "Launching gtkwave sim/${MODULE}.gtkw..."
    gtkwave "sim/${MODULE}.gtkw" >/dev/null 2>&1 || true
  else
    echo "Warning: gtkwave not found in PATH. Cannot open GTKWave file."
  fi
elif [ -f "sim/${MODULE}.vcd" ]; then
  echo "VCD file found: sim/${MODULE}.vcd"
  if command -v gtkwave >/dev/null 2>&1; then
    echo "Launching gtkwave sim/${MODULE}.vcd..."
    gtkwave "sim/${MODULE}.vcd" >/dev/null 2>&1 || true
  else
    echo "Warning: gtkwave not found in PATH. Cannot open VCD file."
  fi
else
  echo "No GTKWave or VCD file found for ${MODULE}."
fi

echo "Done."
