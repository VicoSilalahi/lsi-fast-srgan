# Usage: .\run_sim.ps1 -Module tb_conv_mac_3x3
# Description: This script compiles and runs a Verilog testbench using Icarus Verilog
#              and opens the resulting waveform in GTKWave if available.

param(
  [string]$Module = "tb_conv_mac_3x3"
)

$ErrorActionPreference = 'Stop'

function Check-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Error "$name not found in PATH. Please install Icarus Verilog (iverilog) and vvp.";
    exit 1
  }
}

Check-Command iverilog
Check-Command vvp

$buildDir = "build"
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

$tbFile = "tb\$Module.v"
if (-not (Test-Path $tbFile)) {
  Write-Error "Testbench $tbFile not found."; exit 2
}

$vvpOut = "${buildDir}\${Module}.vvp"
Write-Output "Building $Module..."
iverilog -g2012 -o $vvpOut rtl\*.v $tbFile

Write-Output "Running $Module..."
vvp $vvpOut

# Open .gtkw (sim/*.gtkw) file in GTKWave if it exists
# Otherwise, open the generated .vcd (sim/*.vcd) file if it exists

$gtkwFile = "sim/$Module.gtkw"
if (Test-Path $gtkwFile) {
  Write-Output "Opening GTKWave with $gtkwFile..."
  if (Get-Command gtkwave -ErrorAction SilentlyContinue) {
    try { gtkwave $gtkwFile } catch { }
  } else {
    Write-Warning "GTKWave not found in PATH. Please install GTKWave to view waveforms."
  }
} else {
  $vcdFile = "sim/$Module.vcd"
  if (Test-Path $vcdFile) {
    Write-Output "Opening GTKWave with $vcdFile..."
    if (Get-Command gtkwave -ErrorAction SilentlyContinue) {
      try { gtkwave $vcdFile } catch { }
    } else {
      Write-Warning "GTKWave not found in PATH. Please install GTKWave to view waveforms."
    }
  } else {
    Write-Warning "No .gtkw or .vcd file found to open in GTKWave."
  }
}

Write-Output "Done."
