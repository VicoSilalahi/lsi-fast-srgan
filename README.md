# Fast SRGAN Hardware Implementation
### GANtungan Kunci Team for LSI Contest 2026

## Simulation Guide

**Prerequisites:**
- Install Icarus Verilog (`iverilog`, `vvp`). On Debian/Ubuntu: `sudo apt install iverilog gtkwave`.
- (Optional) Install `gtkwave` to view `.vcd` waveforms.

**Files:**
- `rtl/conv_mac_3x3.v`: 3x3 convolution MAC RTL module.
- `tb/tb_conv_mac_3x3.v`: example testbench for the module.
- `scripts/run_sim.sh`: shell helper to build/run a testbench (macOS/Linux).
- `scripts/run_sim.ps1`: PowerShell helper to build/run a testbench (Windows).

### Run a single-module testbench (macOS / Linux)
From the project root run:

```bash
./scripts/run_sim.sh tb_conv_mac_3x3
```

Or pass any other testbench file placed in `tb/` (without the `.v` extension):

```bash
./scripts/run_sim.sh <MODULE_NAME>
# expects tb/<MODULE_NAME>.v
```

### Run a single-module testbench (Windows PowerShell)
From the project root (PowerShell):

```powershell
.
\scripts\run_sim.ps1 -Module tb_conv_mac_3x3
```

### Top-level / integration simulations
Create a top-level testbench in `tb/` (for example `tb/top_tb.v`) that instantiates the system-level top module and exercises it. Then run the same scripts specifying the top-level testbench name (without `.v`):

```bash
./scripts/run_sim.sh top_tb
```

### Waveform viewing
If a `.vcd` file is produced by the testbench the scripts will report it. Open it with:

```bash
gtkwave <file.vcd>
```

### Notes & recommendations
- Keep small, focused testbenches in `tb/` for unit testing modules (e.g., `tb_conv_mac_3x3.v`).
- Use a single top-level testbench for full-system/integration runs and place it in `tb/` as well.
- Name testbenches to match the `MODULE` argument used by the scripts (file `tb/<MODULE>.v`).
- For CI or automated runs, call the scripts from a shell or PowerShell job and collect the produced `.vcd` for regression checks.
