# SHORT WRITTEN NOTE: DESIGN ANALYSIS & ARCHITECTURAL SCALING
**Subject:** Parameterized Round-Robin Arbiter Analysis
**Prepared For:** HCL Technologies Project Submission
**Date:** June 8, 2026
**Author:** Navya (VLSI Design Engineer)

---

## 1. Why Round-Robin Enforces Fairness
In standard fixed-priority arbitration schemes, higher-priority masters can continuously monopolize a shared bus, causing lower-priority masters to starve indefinitely. 
A **Round-Robin Arbiter** enforces strict fairness by dynamically rotating the priority pointer. Once a master receives a grant, it becomes the lowest-priority requester for the subsequent arbitration cycle, and the highest-priority pointer shifts to the next index: `(granted_index + 1) mod WIDTH`. 
This guarantees a **bounded worst-case waiting time**: in the worst-case scenario where all masters request access simultaneously, any individual master is guaranteed to receive a grant within at most `WIDTH - 1` clock cycles. Therefore, no master is starved of bandwidth.

---

## 2. Observations on Resource Scaling (WIDTH = 4, 8, 16)
Based on the NanGate 45nm synthesis metrics:
- **Sequential Overhead (Flip-Flops):** The flip-flop count scales logarithmically, $O(\log N)$, requiring only $2, 3,$ and $4$ FFs for widths of $4, 8,$ and $16$ respectively. This represents a negligible sequential footprint.
- **Combinational Complexity & Area:** The gate counts and cell area scale in a highly **linear** fashion ($O(N)$). The area scales from $75.17\ \mu m^2$ (WIDTH=4) to $160.76\ \mu m^2$ (2.14x at WIDTH=8) and $329.44\ \mu m^2$ (4.38x at WIDTH=16). 
- **Analysis:** This linear scaling is achieved by employing a parallel prefix-adder based first-one detector (`x & (~x + 1)`) instead of nested multiplexer trees, which would scale quadratically ($O(N^2)$). The normalized area per port remains flat around $19\ \mu m^2$ to $20\ \mu m^2$, confirming no resource explosion in this range.

---

## 3. Design Enhancements for Large Widths (64, 128)
For massive port counts (64 or 128), a flat round-robin architecture becomes a bottleneck. The carry propagation delay of the prefix adder (`~req + 1`) increases linearly ($O(N)$), which degrades the maximum clock frequency ($F_{max}$). To scale successfully, we consider:
- **Hierarchical Arbiter:** Instead of a flat 64-input encoder, the design is structured into two levels (e.g., eight 8-input arbiters at level-0, feeding into a single 8-input arbiter at level-1). This limits the critical path to a small tree depth.
- **Tree-Structured (Ping-Pong) Arbiters:** Implementing a binary tree composed of 2-input arbiters. This structure reduces the combinational critical path delay to logarithmic complexity, $O(\log_2 N)$, preserving high timing performance.
- **Pipelined Arbitration:** Inserting pipeline register stages between the masking logic and the priority encoders. Pipelining decouples long combinational path delays, enabling gigahertz-range clock operations at the cost of 1 or 2 cycles of grant latency.
