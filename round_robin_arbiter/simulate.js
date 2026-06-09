const fs = require('fs');
const path = require('path');

class RoundRobinArbiter {
  constructor(width) {
    this.width = width;
    this.addrWidth = Math.ceil(Math.log2(width));
    this.reset();
  }

  reset() {
    this.ptr = 0;
    this.grant = 0;
    this.grant_valid = 0;
  }

  step(req) {
    // Mask logic
    const mask = (1 << this.ptr) - 1;
    const req_masked = req & ~mask;

    let grant_comb = 0;
    
    // First-one detection
    const get_lowest_set_bit = (val) => {
      return val & (-val);
    };

    if (req_masked !== 0) {
      grant_comb = get_lowest_set_bit(req_masked);
    } else {
      grant_comb = get_lowest_set_bit(req);
    }

    // Output logic
    if (req !== 0) {
      this.grant = grant_comb;
      this.grant_valid = 1;

      // Find granted index
      let granted_index = 0;
      for (let i = 0; i < this.width; i++) {
        if ((this.grant & (1 << i)) !== 0) {
          granted_index = i;
          break;
        }
      }

      // Update pointer
      this.ptr = (granted_index + 1) % this.width;
    } else {
      this.grant = 0;
      this.grant_valid = 0;
      // ptr holds its value
    }

    return {
      grant: this.grant,
      grant_valid: this.grant_valid,
      ptr: this.ptr
    };
  }
}

// Golden model logic for comparison
function compute_golden(req, ptr, width) {
  let expected_grant = 0;
  let expected_valid = req !== 0 ? 1 : 0;
  let expected_next_ptr = ptr;

  if (expected_valid) {
    let found = false;
    let idx = 0;
    
    // Search masked region: from ptr to width-1
    for (let j = 0; j < width; j++) {
      if (j >= ptr && (req & (1 << j)) !== 0 && !found) {
        expected_grant = 1 << j;
        idx = j;
        found = true;
      }
    }
    
    // Search unmasked region: from 0 to ptr-1
    if (!found) {
      for (let j = 0; j < width; j++) {
        if (j < ptr && (req & (1 << j)) !== 0 && !found) {
          expected_grant = 1 << j;
          idx = j;
          found = true;
        }
      }
    }
    expected_next_ptr = (idx + 1) % width;
  }

  return {
    grant: expected_grant,
    grant_valid: expected_valid,
    next_ptr: expected_next_ptr
  };
}

function run_simulation(width) {
  console.log(`\n==================================================`);
  console.log(`Starting Simulation for WIDTH = ${width}`);
  console.log(`==================================================`);

  const arbiter = new RoundRobinArbiter(width);
  const vcdLines = [];
  let time = 0;

  // VCD Header
  vcdLines.push(`$date\n  ${new Date().toISOString()}\n$end`);
  vcdLines.push(`$version\n  NodeJS Arbiter Simulator\n$end`);
  vcdLines.push(`$timescale\n  1ns\n$end`);
  vcdLines.push(`$scope module tb $end`);
  vcdLines.push(`$var reg 1 c clk $end`);
  vcdLines.push(`$var reg 1 r rst_n $end`);
  vcdLines.push(`$var reg ${width} q req $end`);
  vcdLines.push(`$var wire ${width} g grant $end`);
  vcdLines.push(`$var wire 1 v grant_valid $end`);
  vcdLines.push(`$var reg ${arbiter.addrWidth} p ptr $end`);
  vcdLines.push(`$upscope $end`);
  vcdLines.push(`$enddefinitions $end`);

  // Initial state
  let clk = 0;
  let rst_n = 0;
  let req = 0;
  let grant = 0;
  let grant_valid = 0;
  let ptr = 0;

  function dumpState() {
    vcdLines.push(`#${time}`);
    vcdLines.push(`${clk}c`);
    vcdLines.push(`${rst_n}r`);
    vcdLines.push(`b${req.toString(2).padStart(width, '0')} q`);
    vcdLines.push(`b${grant.toString(2).padStart(width, '0')} g`);
    vcdLines.push(`${grant_valid}v`);
    vcdLines.push(`b${ptr.toString(2).padStart(arbiter.addrWidth, '0')} p`);
  }

  // Time 0: Reset active
  dumpState();

  // Reset phase
  time += 10; clk = 1; dumpState();
  time += 10; clk = 0; dumpState();
  time += 10; clk = 1; dumpState();
  time += 10; clk = 0; rst_n = 1; dumpState(); // reset deasserted

  let mismatches = 0;
  let steps = 0;

  function runCycle(newReq) {
    req = newReq;
    steps++;
    // Read current ptr and compute expected
    const golden = compute_golden(req, arbiter.ptr, width);
    
    // Tick clock high (posedge)
    time += 10; clk = 1;
    
    // Evaluate DUT step
    const out = arbiter.step(req);
    grant = out.grant;
    grant_valid = out.grant_valid;
    ptr = out.ptr;
    
    dumpState();

    // Check outputs
    if (out.grant !== golden.grant || out.grant_valid !== golden.grant_valid) {
      console.log(`[ERROR] Mismatch at step ${steps}!`);
      console.log(`  req = ${req.toString(2).padStart(width, '0')}, ptr = ${ptr}`);
      console.log(`  DUT grant = ${out.grant.toString(2).padStart(width, '0')}, Expected = ${golden.grant.toString(2).padStart(width, '0')}`);
      mismatches++;
    }

    // Tick clock low
    time += 10; clk = 0;
    dumpState();
  }

  // Case 1: Single Requester (req = 1)
  console.log(`--- Case 1: Single Requester ---`);
  for (let i = 0; i < 5; i++) {
    runCycle(1);
  }

  // Case 2: Alternating Requesters (01 -> 10 -> 01 -> 10)
  console.log(`--- Case 2: Alternating Requesters ---`);
  for (let i = 0; i < 2; i++) {
    runCycle(1);
    runCycle(2);
  }
  runCycle(0); // idle

  // Case 3: All Requesters Active
  console.log(`--- Case 3: All Requesters Active ---`);
  const allActive = (1 << width) - 1;
  for (let i = 0; i < width * 2; i++) {
    runCycle(allActive);
  }
  runCycle(0); // idle

  // Case 4: Random patterns
  console.log(`--- Case 4: Random Request Patterns ---`);
  const maskMax = (1 << width) - 1;
  for (let i = 0; i < 30; i++) {
    const randReq = Math.floor(Math.random() * (maskMax + 1));
    runCycle(randReq);
  }

  console.log(`Simulation finished. Mismatches: ${mismatches}`);
  
  // Save VCD
  fs.writeFileSync(path.join(__dirname, `arbiter_w${width}.vcd`), vcdLines.join('\n'));
  console.log(`Waveforms saved to arbiter_w${width}.vcd`);
  
  return mismatches;
}

// Run for 4, 8, 16
const m4 = run_simulation(4);
const m8 = run_simulation(8);
const m16 = run_simulation(16);

if (m4 === 0 && m8 === 0 && m16 === 0) {
  console.log('\n>>> ALL SIMULATIONS PASSED! <<<');
} else {
  console.log('\n>>> SIMULATION FAILED! <<<');
}
