# Fairness Engine: Parameterized Round-Robin Arbiter

**Course:** HCL VLSI Design — VS6 Y3S2  
**Team Members:**
| Name | Roll Number |
|------|-------------|
| PATI HARSHITHA | 23PA1A04C0 |
| D. SRI CHANDU | 23PA1A0439 |
| B. VENKATA NAGA NAVYA | 24PA5A0430 |

---

## Overview

A fully parameterized round-robin arbiter designed for on-chip interconnects where multiple masters compete for a shared bus. Uses a rotating priority pointer to guarantee fairness and prevent starvation.

**Supported widths:** WIDTH = 4, 8, 16

---

## Repository Structure

```
round_robin_arbiter/
├── rr_arbiter.v              # Parameterized RTL source
├── rr_arbiter_tb_w4.v        # Testbench for WIDTH=4
├── rr_arbiter_tb_w8.v        # Testbench for WIDTH=8
├── rr_arbiter_tb_w16.v       # Testbench for WIDTH=16
├── run_sim.bat               # One-click simulation script (Windows)
├── synth.bat                 # One-click synthesis script (Windows)
├── RR_Arbiter_Report.pdf     # Full project report
└── synth_out/
    ├── report_w4.txt         # Yosys synthesis report WIDTH=4
    ├── report_w8.txt         # Yosys synthesis report WIDTH=8
    ├── report_w16.txt        # Yosys synthesis report WIDTH=16
    ├── synth_w4.v            # Gate-level netlist WIDTH=4
    ├── synth_w8.v            # Gate-level netlist WIDTH=8
    └── synth_w16.v           # Gate-level netlist WIDTH=16
```

---

## Design Details

### Interface
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | Input | 1 | System clock |
| `rst_n` | Input | 1 | Active-low synchronous reset |
| `req` | Input | WIDTH | Request vector (1 = active) |
| `grant` | Output | WIDTH | One-hot grant output |
| `grant_valid` | Output | 1 | High when any grant is issued |

### How It Works
1. Internal pointer tracks the next highest-priority index
2. On each clock cycle, scans `req` starting from pointer (wrapping around)
3. First active requester gets the grant
4. Pointer advances to `(granted_index + 1) mod WIDTH` after each grant
5. Pointer holds if no requests are active

---

## Simulation Results

| WIDTH | Checks | Mismatches | Result |
|-------|--------|------------|--------|
| 4 | 224 | 0 | ✅ PASS |
| 8 | 264 | 0 | ✅ PASS |
| 16 | 304 | 0 | ✅ PASS |

### Test Cases Covered
- **Case 1:** Single requester (req[0] only)
- **Case 2:** Two alternating requesters
- **Case 3:** All requesters active — strict round-robin
- **Case 4:** Idle gaps between requests
- **Case 5:** 200 cycles of random patterns

---

## Synthesis Results (Yosys OSS CAD Suite v0.63)

| WIDTH | Total Cells | FF Count | Comb Cell Count | Comments |
|-------|-------------|----------|-----------------|---------|
| 4 | 38 | 6 | 32 | Pointer=2FF; tiny priority chain |
| 8 | 94 | 11 | 83 | Pointer=3FF; 16-bit masked chain |
| 16 | 231 | 20 | 211 | Pointer=4FF; 32-bit masked chain |

**Key Observation:** Area grows ~2.5x per doubling of WIDTH (super-linear). Combinational logic dominates — the doubled-vector priority encode chain grows as O(WIDTH × log WIDTH).

---

## How to Run

### Prerequisites
- [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) installed at `C:\oss-cad-suite`

### Simulation
```bat
cd C:\oss-cad-suite
environment.bat
cd <project_folder>
run_sim.bat
```

### Synthesis
```bat
synth.bat
```
Reports saved to `synth_out/` folder.

---

## Tools Used
- **Simulator:** Icarus Verilog (iverilog/vvp)
- **Waveform Viewer:** EDA Playground (EPWave)
- **Synthesis:** Yosys with ABC backend
- **Platform:** OSS CAD Suite v0.63 on Windows
