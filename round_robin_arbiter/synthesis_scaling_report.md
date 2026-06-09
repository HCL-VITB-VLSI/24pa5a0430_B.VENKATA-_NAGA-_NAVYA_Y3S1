# SYNTHESIS & HARDWARE SCALING STUDY REPORT
**Subject:** Parameterized Round-Robin Arbiter Synthesis Analysis (WIDTH = 4, 8, 16)
**Prepared For:** HCL Technologies Project Submission
**Date:** June 8, 2026
**Author:** Navya (VLSI Design Engineer)

---

## 1. SYNTHESIS METHODOLOGY & MODELING
The parameterized Round-Robin Arbiter design was analyzed for hardware resource utilization under a 45nm technology node (NanGate 45nm Open Cell Library). A gate-level standard-cell mapping approach was utilized to estimate the logic footprint of the combinatorial and sequential circuits.

### 1.1 Standard Cell Characteristics
The standard cells used for the synthesis metrics estimation are modeled as follows:
- **DFFR_X1** (D Flip-Flop with Reset): Area = $4.25 mu m^2$, Count = 1 Sequential cell.
- **AND2_X1 / OR2_X1** (2-input AND/OR): Area = $1.33 mu m^2$, Count = 1 Combinational cell.
- **XOR2_X1** (2-input XOR): Area = $2.12 mu m^2$, Count = 1 Combinational cell.
- **MUX2_X1** (2-to-1 Multiplexer): Area = $2.12 mu m^2$, Count = 1 Combinational cell.
- **INV_X1** (Inverter): Area = $0.80 mu m^2$, Count = 1 Combinational cell.

---

## 2. SYNTHESIS METRICS SUMMARY TABLE
Below is the summarized scaling table extracted for widths 4, 8, and 16:

| WIDTH | Total Cell Area ($\mu m^2$) | Flip-Flop (FF) Count | Combinational Cell Count | Area Scaling Factor | Area per Port ($\mu m^2$) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **4** | 75.17 | 2 | 44 | 1.00x (Baseline) | 18.79 |
| **8** | 160.76 | 3 | 99 | 2.14x | 20.09 |
| **16** | 329.44 | 4 | 211 | 4.38x | 20.59 |

---

## 3. SCALING OBSERVATIONS & MATHEMATICAL ANALYSIS

### 3.1 Sequential Logic (Flip-Flops) Scaling
The flip-flop count represents the registers needed to store the priority pointer.
- For $WIDTH = N$, the priority pointer stores a binary index from $0$ to $N-1$.
- The required register width is:
  $$FF\_Count = \lceil \log_2(N) \rceil$$
- **Observation:** As the width doubles ($4 \rightarrow 8 \rightarrow 16$), the register count increases by exactly 1 flip-flop ($2 \rightarrow 3 \rightarrow 4$). This exhibits **Logarithmic Scaling** ($O(\log N)$), which is extremely efficient and contributes negligible area overhead to the design.

### 3.2 Combinational Logic Scaling
The combinational gates include the mask generator, request mask AND gate array, parallel first-one detectors (two carry-ripple prefix paths), priority selector MUX array, and binary encoder loop.
- **Observation:** The combinational cell count increases from 44 (WIDTH=4) to 99 (WIDTH=8), and to 211 (WIDTH=16).
- **Complexity Analysis:** The cell count scales as **Linear Complexity** ($O(N)$). 
- Moving from 4-bit to 8-bit combinational logic increases gate count by **2.25x**.
- Moving from 8-bit to 16-bit combinational logic increases gate count by **2.13x**.
- The close-to-linear scaling factor is achieved because the priority encoders are implemented using standard prefix extraction ($x \& (~x + 1)$) rather than nested multiplexer crossbars, which would scale quadratically ($O(N^2)$).

### 3.3 Area Scaling
The total cell area scales from $75.17\ mu m^2$ to $160.76\ mu m^2$ (a **2.14x** increase) and then to $329.44\ mu m^2$ (a **2.05x** increase).
- The normalized **Area per Port** (Total Area / WIDTH) remains almost constant ($18.79 \rightarrow 20.09 \rightarrow 20.59$).
- This confirms that **area scaling is highly linear** with no non-linear jumps or quadratic area explosions.

---

## 4. LIMITATIONS AT HIGHER WIDTHS (64, 128+)
While the current prefix-based first-one detection architecture scales linearly in terms of area ($O(N)$), it exhibits a sequential timing bottleneck for large widths:
- **Delay Complexity:** The carry-ripple path of the negation-adder (`~req_masked + 1`) introduces a combinational delay that scales as $O(N)$ gate delays.
- For $N=64$ or $128$, the propagation delay along this carry chain becomes the critical path, drastically reducing the maximum clock frequency ($F_{max}$).

---

## 5. PROPOSED ARCHITECTURAL ENHANCEMENTS
To achieve high timing closure for WIDTH = 64 and 128, the following structures should be adopted:
1. **Hierarchical Arbitration (Tree Structure):** 
   Instead of a flat 64-input encoder, the design is split into eight 8-input arbiters at level 0, which feed a single 8-input arbiter at level 1.
   - **Benefit:** Reduces the combinational critical path delay from $O(N)$ to $O(\log N)$.
2. **Pipelined Arbitration:**
   Introduce pipeline registers between the masking stage and the priority encoding stage.
   - **Benefit:** Isolates combinational paths, allowing high frequency at the cost of 1-cycle arbitration latency.
