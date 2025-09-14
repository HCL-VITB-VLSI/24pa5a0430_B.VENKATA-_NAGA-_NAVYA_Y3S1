`timescale 1ns/1ps
// -----------------------------------------------------------
// LightChaser
// Rotating LED (circular left shift) every TICKS_PER_STEP clocks
// when enable=1. Holds state when enable=0. Async active-low reset.
// On reset: led_out = 1 (bit0 high).
// Counter pauses while enable=0 (resume behavior).
// -----------------------------------------------------------
//module lightchaser #(
//    parameter int WIDTH           = 8,
//    parameter int TICKS_PER_STEP  = 4      // >=1: clocks per one rotation step
//) (
//    input  logic              clk,
//    input  logic              rst_n,       // async active-low
//    input  logic              enable,      // advance when 1
//    output logic [WIDTH-1:0]  led_out
//);
module tb_lightchaser;

    // Parameters for simulation
    localparam int WIDTH          = 8;
    localparam int TICKS_PER_STEP = 3;   // rotate every 3 clk cycles
    localparam int CLK_NS         = 10;  // 100 MHz

    // DUT I/O
    logic clk, rst_n, enable;
    logic [WIDTH-1:0] led_out;

    // Instantiate DUT
    lightchaser #(
        .WIDTH(WIDTH),
        .TICKS_PER_STEP(TICKS_PER_STEP)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .led_out(led_out)
    );

    // Clock
    initial clk = 1'b0;
    always #(CLK_NS/2) clk = ~clk;

    // VCD
    initial begin
        $dumpfile("lightchaser_tb.vcd");
        $dumpvars(0, tb_lightchaser);
    end

    // ---------------- Reference Model (scoreboard) ----------------
    logic [WIDTH-1:0] led_ref;
    logic [31:0]      tick_ref;

    function automatic [WIDTH-1:0] rol1(input [WIDTH-1:0] x);
        rol1 = {x[WIDTH-2:0], x[WIDTH-1]};
    endfunction

    // REF updates exactly like DUT
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_ref        <= '0; 
            led_ref[0]     <= 1'b1;      // 0000_0001
            tick_ref       <= '0;
        end else begin
            if (enable) begin
                if (TICKS_PER_STEP == 1) begin
                    led_ref  <= rol1(led_ref);
                    tick_ref <= '0;
                end else if (tick_ref == TICKS_PER_STEP-1) begin
                    led_ref  <= rol1(led_ref);
                    tick_ref <= '0;
                end else begin
                    tick_ref <= tick_ref + 1;
                end
            end
        end
    end

    // ---------------- Checker with assert + $fatal ----------------
    int errors;   // reset in checker; no initializer here
    int tests;    // incremented in the stimulus

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            errors <= 0;
        end else begin
            // Hard guarantee: stop immediately on any mismatch
            assert (led_out === led_ref)
            else begin
                errors <= errors + 1;
                $fatal(1, "Mismatch t=%0t: led_out=%b REF=%b",
                       $time, led_out, led_ref);
            end
        end
    end

    // Final summary (prints only if no $fatal occurred)
    final begin
        if (errors == 0)
            $display("PASS: All %0d tests passed (errors=%0d).", tests, errors);
        else
            $display("FAIL: errors=%0d after %0d tests.", errors, tests);
    end

    // ---------------- Stimulus helpers ----------------
    task automatic wait_cycles(input int n);
        repeat (n) @(posedge clk);
    endtask

    // ---------------- Test Plan ----------------
    initial begin
        tests   = 0;
        enable  = 0;
        rst_n   = 0;
        wait_cycles(4);
        rst_n   = 1;
        wait_cycles(2);

        // CASE 1: Post-reset hold with enable=0
        $display("\nCASE 1: Post-reset hold with enable=0");
        wait_cycles(10);
        tests++;

        // CASE 2: Basic rotation with enable=1 (10 steps)
        $display("\nCASE 2: Run 10 steps");
        enable = 1;
        wait_cycles(10*TICKS_PER_STEP);
        tests++;

        // CASE 3: Pause/resume mid-step (partial tick)
        $display("\nCASE 3: Pause/resume mid-step");
        wait_cycles(2);          // start a step, accumulate partial ticks
        enable = 0;              // pause before boundary
        wait_cycles(7);          // hold (no movement)
        enable = 1;              // resume
        wait_cycles(1);          // completes that pending step
        wait_cycles(TICKS_PER_STEP); // plus one full extra step
        tests++;

        // CASE 4: Long hold with enable=0 -> no movement
        $display("\nCASE 4: Long hold (enable=0)");
        enable = 0;
        wait_cycles(20);
        tests++;

        // CASE 5: Wrap-around check: full WIDTH steps
        $display("\nCASE 5: Wrap-around");
        enable = 1;
        wait_cycles(WIDTH*TICKS_PER_STEP);
        tests++;

        // CASE 6: Toggle enable near boundaries repeatedly
        $display("\nCASE 6: Enable edge near boundary");
        repeat (3) begin
            // Bring tick near boundary then pause
            int rem = (TICKS_PER_STEP-1) - (tick_ref % TICKS_PER_STEP);
            if (rem < 0) rem = 0;
            wait_cycles(rem);
            enable = 0; wait_cycles(4);
            enable = 1; wait_cycles(2);
        end
        tests++;

        // CASE 7: Final cadence check (10 more steps)
        $display("\nCASE 7: Final cadence check");
        wait_cycles(10*TICKS_PER_STEP);
        tests++;

        // Graceful end if no $fatal was triggered
        wait_cycles(5);
        $finish;
    end

endmodule
