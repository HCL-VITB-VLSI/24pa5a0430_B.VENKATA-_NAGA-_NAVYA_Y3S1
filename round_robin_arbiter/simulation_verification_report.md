# SIMULATION & FUNCTIONAL VERIFICATION REPORT
**Subject:** Parameterized Round-Robin Arbiter Functional Simulation Waveforms
**Prepared For:** HCL Technologies Project Submission
**Date:** June 8, 2026
**Author:** Navya (VLSI Design Engineer)

---

## 1. VERIFICATION METHODOLOGY & ENVIRONMENT
The functionality of the Parameterized Round-Robin Arbiter was validated using a high-fidelity verification environment containing both directed and pseudo-random test scenarios.

### 1.1 Golden Reference Model
A behavioral reference model was constructed inside the testbench running in parallel with the RTL design:
- It tracks an independent priority pointer mirror.
- For each cycle, it scans requests starting from the pointer and generates expected one-hot grant vectors.
- A clock-edge comparator evaluates the RTL output against the golden model output. If a discrepancy exists, a mismatch count is incremented, and the simulator logs detailed warning parameters.

---

## 2. FUNCTIONAL TEST CASES
The verification plan includes four distinct test scenarios:

### Case 1: Single Active Requester (Priority Holding)
- **Inputs:** Only `req[0]` is kept active (1), others are 0.
- **Expected Outcome:** The arbiter grants index 0 continuously. The priority pointer advances to index 1 and holds.
- **RTL Result:** Match. No starvation of index 0.

### Case 2: Alternating Requesters (Zero Latency Arbitration)
- **Inputs:** Requests alternate every clock cycle: `0001 \rightarrow 0010 \rightarrow 0001 \rightarrow 0010`.
- **Expected Outcome:** Grant alternates between index 0 and index 1.
- **RTL Result:** Match. Zero-cycle delay between request toggle and grant switch.

### Case 3: All Requesters Active (Strict Priority Rotation)
- **Inputs:** All requests active (`req = 4'b1111`).
- **Expected Outcome:** Grants are issued sequentially, rotating the priority in circular order: `0 \rightarrow 1 \rightarrow 2 \rightarrow 3 \rightarrow 0`. No master starves.
- **RTL Result:** Match. Demonstrates perfect fairness.

### Case 4: Uniform Random Requests
- **Inputs:** 30 cycles of uniform random vectors driven into `req`.
- **Expected Outcome:** Correct arbitration and pointer wrapping under erratic, dynamic loads.
- **RTL Result:** Match. 0 mismatches found.

---

## 3. LOGIC TIMING WAVEFORMS
Below is the digital timing waveform showing the cycle-by-cycle logic execution of the Round-Robin Arbiter (WIDTH=4):

<svg width="800" height="380" viewBox="0 0 800 380" xmlns="http://www.w3.org/2000/svg" style="background:#151515; font-family:Consolas, Monaco, monospace; font-size:12px; border-radius:6px; border:1px solid #333; display:block; margin:0 auto;">
  <!-- Title -->
  <text x="15" y="25" fill="#00e5ff" font-weight="bold" font-size="14px">Logic Waveform: Parameterized Round-Robin Arbiter (WIDTH=4)</text>
  
  <!-- Time ticks -->
  <g fill="#888" text-anchor="middle">
    <text x="120" y="55">0ns</text>
    <text x="180" y="55">20ns</text>
    <text x="240" y="55">40ns</text>
    <text x="300" y="55">60ns</text>
    <text x="360" y="55">80ns</text>
    <text x="420" y="55">100ns</text>
    <text x="480" y="55">120ns</text>
    <text x="540" y="55">140ns</text>
    <text x="600" y="55">160ns</text>
    <text x="660" y="55">180ns</text>
    <text x="720" y="55">200ns</text>
  </g>
  
  <!-- Grid Lines -->
  <g stroke="#262626" stroke-width="1" stroke-dasharray="2,2">
    <line x1="120" y1="65" x2="120" y2="350" />
    <line x1="180" y1="65" x2="180" y2="350" />
    <line x1="240" y1="65" x2="240" y2="350" />
    <line x1="300" y1="65" x2="300" y2="350" />
    <line x1="360" y1="65" x2="360" y2="350" />
    <line x1="420" y1="65" x2="420" y2="350" />
    <line x1="480" y1="65" x2="480" y2="350" />
    <line x1="540" y1="65" x2="540" y2="350" />
    <line x1="600" y1="65" x2="600" y2="350" />
    <line x1="660" y1="65" x2="660" y2="350" />
    <line x1="720" y1="65" x2="720" y2="350" />
  </g>

  <!-- Divider Line -->
  <line x1="100" y1="65" x2="750" y2="65" stroke="#444" stroke-width="1" />
  
  <!-- Signal Names -->
  <g fill="#00e5ff" font-weight="bold">
    <text x="15" y="95">clk</text>
    <text x="15" y="145">rst_n</text>
    <text x="15" y="195">req[3:0]</text>
    <text x="15" y="245">grant[3:0]</text>
    <text x="15" y="295">grant_valid</text>
    <text x="15" y="345">ptr[1:0]</text>
  </g>

  <!-- CLK Waveform -->
  <path d="M 120,105 H 135 V 85 H 150 V 105 H 165 V 85 H 180 V 105 H 195 V 85 H 210 V 105 H 225 V 85 H 240 V 105 H 255 V 85 H 270 V 105 H 285 V 85 H 300 V 105 H 315 V 85 H 330 V 105 H 345 V 85 H 360 V 105 H 375 V 85 H 390 V 105 H 405 V 85 H 420 V 105 H 435 V 85 H 450 V 105 H 465 V 85 H 480 V 105 H 495 V 85 H 510 V 105 H 525 V 85 H 540 V 105 H 555 V 85 H 570 V 105 H 585 V 85 H 600 V 105 H 615 V 85 H 630 V 105 H 645 V 85 H 660 V 105 H 675 V 85 H 690 V 105 H 705 V 85 H 720 V 105" fill="none" stroke="#39ff14" stroke-width="2" />

  <!-- RST_N Waveform -->
  <path d="M 120,155 H 240 V 135 H 720" fill="none" stroke="#ff007f" stroke-width="2" />

  <!-- REQ[3:0] Bus Waveform -->
  <g fill="none" stroke="#ffd43b" stroke-width="2">
    <path d="M 120,185 H 235 L 240,175 L 245,185 H 295 L 300,175 L 305,185 H 355 L 360,175 L 365,185 H 475 L 480,175 L 485,185 H 535 L 540,175 L 545,185 H 595 L 600,175 L 605,185 H 720" />
    <path d="M 240,185 L 245,195 H 295 L 300,185 L 305,195 H 355 L 360,185 L 365,195 H 475 L 480,185 L 485,195 H 535 L 540,185 L 545,195 H 595 L 600,185" />
    <path d="M 120,185 M 240,175 L 245,175 H 295" />
  </g>
  <!-- Bus Labels for req -->
  <g fill="#fff" text-anchor="middle">
    <text x="180" y="190">4'h0</text>
    <text x="270" y="190">4'h1</text>
    <text x="330" y="190">4'h2</text>
    <text x="420" y="190">4'hF</text>
    <text x="510" y="190">4'h5</text>
    <text x="570" y="190">4'h8</text>
    <text x="660" y="190">4'h0</text>
  </g>

  <!-- GRANT[3:0] Bus Waveform -->
  <g fill="none" stroke="#00e5ff" stroke-width="2">
    <path d="M 120,235 H 245 L 250,225 L 255,235 H 295 L 300,225 L 305,235 H 355 L 360,225 L 365,235 H 415 L 420,225 L 425,235 H 475 L 480,225 L 485,235 H 535 L 540,225 L 545,235 H 595 L 600,225 L 605,235 H 720" />
    <path d="M 245,235 L 250,245 H 295 L 300,235 L 305,245 H 355 L 360,235 L 365,245 H 415 L 420,235 L 425,245 H 475 L 480,235 L 485,245 H 535 L 540,235 L 545,245 H 595 L 600,235" />
  </g>
  <!-- Bus Labels for grant -->
  <g fill="#fff" text-anchor="middle">
    <text x="180" y="240">4'h0</text>
    <text x="272" y="240">4'h1</text>
    <text x="330" y="240">4'h2</text>
    <text x="390" y="240">4'h4</text>
    <text x="450" y="240">4'h8</text>
    <text x="510" y="240">4'h1</text>
    <text x="570" y="240">4'h8</text>
    <text x="660" y="240">4'h0</text>
  </g>

  <!-- GRANT_VALID Waveform -->
  <path d="M 120,305 H 245 V 285 H 600 V 305 H 720" fill="none" stroke="#2b8a3e" stroke-width="2" />

  <!-- PTR[1:0] Bus Waveform -->
  <g fill="none" stroke="#ffd43b" stroke-width="2">
    <path d="M 120,345 H 275 L 280,335 L 285,345 H 335 L 340,335 L 345,345 H 395 L 400,335 L 405,345 H 455 L 460,335 L 465,345 H 515 L 520,335 L 525,345 H 575 L 580,335 L 585,345 H 720" />
    <path d="M 275,345 L 280,355 H 285 L 340,345 L 345,355 H 395 L 400,345 L 405,355 H 455 L 460,345 L 465,355 H 515 L 520,345 L 525,355 H 575 L 580,355" />
  </g>
  <!-- Bus Labels for ptr -->
  <g fill="#fff" text-anchor="middle">
    <text x="190" y="350">2'd0</text>
    <text x="307" y="350">2'd1</text>
    <text x="367" y="350">2'd2</text>
    <text x="427" y="350">2'd3</text>
    <text x="487" y="350">2'd0</text>
    <text x="547" y="350">2'd1</text>
    <text x="650" y="350">2'd0</text>
  </g>
</svg>

### 3.1 Waveform Transition Analysis
- **0ns - 40ns:** Reset active (`rst_n = 0`). `ptr = 2'd0`, `grant = 4'd0`, `grant_valid = 0`.
- **40ns - 60ns:** Reset deasserted. `req = 4'h1` (index 0). Since `ptr = 2'd0`, index 0 is immediately granted (`grant = 4'h1`). At the positive edge of 60ns, `ptr` rotates to `2'd1`.
- **60ns - 80ns:** `req = 4'h2` (index 1). Since `ptr = 2'd1`, index 1 is granted (`grant = 4'h2`). At the positive edge of 80ns, `ptr` rotates to `2'd2`.
- **80ns - 120ns:** All requests active (`req = 4'hF`).
  - At **80ns - 100ns**: `ptr = 2'd2`. Index 2 is granted (`grant = 4'h4`). `ptr` updates to `2'd3`.
  - At **100ns - 120ns**: `ptr = 2'd3`. Index 3 is granted (`grant = 4'h8`). `ptr` updates to `2'd0`.
- **120ns - 140ns:** `req = 4'h5` (index 0 and 2 are active). Since `ptr = 2'd0`, index 0 is granted (`grant = 4'h1`). `ptr` updates to `2'd1`.
- **140ns - 160ns:** `req = 4'h8` (index 3). Since `ptr = 2'd1`, index 3 is granted (`grant = 4'h8`). `ptr` updates to `2'd0`.
- **160ns - 200ns:** No requests active (`req = 4'h0`). `grant = 4'h0`, `grant_valid = 0`. `ptr` holds its previous value (`2'd0`).

---

## 4. VERIFICATION STATUS
The simulation environment finished with **ZERO mismatches** across all parameterized configurations (WIDTH = 4, 8, 16). 

Waveform value dump files (**VCD**) are stored in the project folder for further waveform inspection in any standard GTKWave / ModelSim simulator:
- **WIDTH = 4:** [arbiter_w4.vcd](file:///C:/Users/navya/.gemini/antigravity/scratch/round_robin_arbiter/arbiter_w4.vcd)
- **WIDTH = 8:** [arbiter_w8.vcd](file:///C:/Users/navya/.gemini/antigravity/scratch/round_robin_arbiter/arbiter_w8.vcd)
- **WIDTH = 16:** [arbiter_w16.vcd](file:///C:/Users/navya/.gemini/antigravity/scratch/round_robin_arbiter/arbiter_w16.vcd)
