RotatorUnit
timescale 1ns/1ps
// -----------------------------------------------------------
// RotatorUnit
// - 8/parametric-bit rotate register
// - On each clk when enable=1:
//       if load=1: state <= data_in  (no rotate this cycle)
//      else     : state <= rotate-by-1 based on dir
//   dir=0 -> rotate-left; dir=1 -> rotate-right
// - When enable=0: state holds (pause).
// - Async active-low reset clears state to 0.
// -----------------------------------------------------------
// module rotatorunit #(
//    parameter int WIDTH = 8
// ) (
//    input  logic              clk,
//    input  logic              rst_n,      // async active-low
//    input  logic              enable,     // gate for load/rotate
//    input  logic              load,       // synchronous load
//    input  logic              dir,        // 0: left, 1: right
//    input  logic [WIDTH-1:0]  data_in,
//    output logic [WIDTH-1:0]  data_out
// );
module tb_rotatorunit;

    // Parameters
    localparam int WIDTH  = 8;
    localparam int CLK_NS = 10;  // 100 MHz

    // DUT I/Os
    logic clk, rst_n, enable, load, dir;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] data_out;

    // DUT
    rotatorunit #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .load(load),
        .dir(dir),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock
    initial clk = 1'b0;
    always #(CLK_NS/2) clk = ~clk;

    // VCD
    initial begin
        $dumpfile("rotatorunit_tb.vcd");
        $dumpvars(0, tb_rotatorunit);
    end

    // ---------------- Reference Model (scoreboard) ----------------
    function automatic [WIDTH-1:0] rol1(input [WIDTH-1:0] x);
        rol1 = {x[WIDTH-2:0], x[WIDTH-1]};
    endfunction
    function automatic [WIDTH-1:0] ror1(input [WIDTH-1:0] x);
        ror1 = {x[0], x[WIDTH-1:1]};
    endfunction

    logic [WIDTH-1:0] ref_state;

    // Mirror DUT semantics exactly
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_state <= '0;
        end else if (enable) begin
            if (load) ref_state <= data_in;
            else      ref_state <= (dir ? ror1(ref_state) : rol1(ref_state));
        end
    end

    // ---------------- Checker with assert + $fatal ----------------
    int errors;  // reset in checker
    int tests;   // incremented in stimulus

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            errors <= 0;
        end else begin
            assert (data_out === ref_state)
            else begin
                errors <= errors + 1;
                $fatal(1, "Mismatch t=%0t: data_out=%b REF=%b", $time, data_out, ref_state);
            end
        end
    end

    final begin
        if (errors == 0)
            $display("PASS: All %0d tests passed (errors=%0d).", tests, errors);
        else
            $display("FAIL: errors=%0d after %0d tests.", errors, tests);
    end

    // ---------------- Helpers ----------------
    task automatic wait_cycles(input int n);
        repeat (n) @(posedge clk);
    endtask

    // One-cycle synchronous load (enable gates load)
    task automatic do_load(input [WIDTH-1:0] val, input bit en);
        begin
            enable = en;
            load   = 1'b1;
            data_in= val;
            @(posedge clk);
            load   = 1'b0;
        end
    endtask

    // Rotate for n cycles with given dir and enable=1
    task automatic rotate_steps(input int n, input bit dir_right);
        begin
            dir    = dir_right;
            enable = 1'b1;
            load   = 1'b0;
            wait_cycles(n);
        end
    endtask

    // ---------------- Test Plan (deterministic) ----------------
    initial begin
        // Init
        tests   = 0;
        enable  = 0;
        load    = 0;
        dir     = 0;
        data_in = '0;

        // Reset
        rst_n   = 0; wait_cycles(4);
        rst_n   = 1; wait_cycles(2);

        // CASE 1: Post-reset state is zero; hold with enable=0
        $display("\nCASE 1: Reset & hold");
        wait_cycles(5);
        tests++;

        // CASE 2: Load with enable=1, then rotate LEFT several steps
        $display("\nCASE 2: Load 0x12, rotate LEFT 10 steps");
        do_load(8'h12, 1'b1);          // state = 0001_0010
        rotate_steps(10, /*dir_right=*/0);
        tests++;

        // CASE 3: Pause (enable=0), state must hold
        $display("\nCASE 3: Pause hold");
        enable = 1'b0; wait_cycles(8);
        tests++;

        // CASE 4: Rotate RIGHT several steps
        $display("\nCASE 4: Rotate RIGHT 9 steps");
        rotate_steps(9, /*dir_right=*/1);
        tests++;

        // CASE 5: Toggle dir each cycle for 16 cycles
        $display("\nCASE 5: Toggle dir every cycle");
        enable = 1'b1; load = 1'b0;
        repeat (16) begin
            @(posedge clk);
            dir <= ~dir;
        end
        tests++;

        // CASE 6: Load mid-run while enable=1, then rotate LEFT one step
        $display("\nCASE 6: Load 0x80 mid-run, then LEFT 1 step");
        do_load(8'h80, 1'b1);          // state = 1000_0000
        rotate_steps(1, /*dir_right=*/0);  // -> 0000_0001
        tests++;

        // CASE 7: Attempt load while enable=0 (should NOT load by spec)
        $display("\nCASE 7: Load attempt with enable=0 (ignored), then re-enable");
        do_load(8'hA5, 1'b0);          // ignored, state must hold
        enable = 1'b1; wait_cycles(4); // verify no sudden change
        tests++;

        // CASE 8: All-zero input -> stays zero after rotations
        $display("\nCASE 8: Load 0x00 and rotate");
        do_load(8'h00, 1'b1);
        rotate_steps(12, 0);
        rotate_steps(12, 1);
        tests++;

        // CASE 9: All-ones input -> stays 0xFF after rotations
        $display("\nCASE 9: Load 0xFF and rotate");
        do_load(8'hFF, 1'b1);
        rotate_steps(7, 0);
        rotate_steps(7, 1);
        tests++;

        // CASE 10: Wrap-around check: load 0x01, rotate LEFT WIDTH steps -> back to 0x01
        $display("\nCASE 10: Wrap-around LEFT WIDTH steps");
        do_load(8'h01, 1'b1);
        rotate_steps(WIDTH, 0);
        tests++;

        // End
        wait_cycles(5);
        $finish;
    end

endmodule
