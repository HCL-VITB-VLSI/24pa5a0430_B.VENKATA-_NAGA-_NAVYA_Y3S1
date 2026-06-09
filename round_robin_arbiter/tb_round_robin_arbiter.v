// =============================================================================
// Testbench: Self-Checking Testbench for Parameterized Round-Robin Arbiter
// File: tb_round_robin_arbiter.v
// =============================================================================

`timescale 1ns/1ps

module tb_round_robin_arbiter;

    // Parameters
    parameter integer WIDTH = 4;
    localparam integer PTR_WIDTH = (WIDTH <= 2) ? 1 :
                                   (WIDTH <= 4) ? 2 :
                                   (WIDTH <= 8) ? 3 :
                                   (WIDTH <= 16) ? 4 : 8;

    // Inputs to UUT
    reg              clk;
    reg              rst_n;
    reg  [WIDTH-1:0] req;

    // Outputs from UUT
    wire [WIDTH-1:0] grant;
    wire             grant_valid;

    // Instantiate Unit Under Test (UUT)
    round_robin_arbiter #(
        .WIDTH(WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant),
        .grant_valid(grant_valid)
    );

    // Clock Generation (50MHz -> 20ns period)
    always begin
        #10 clk = ~clk;
    end

    // Golden Reference Model Logic
    reg [WIDTH-1:0]     prev_req;
    reg [PTR_WIDTH-1:0] prev_ptr;
    reg                 prev_valid;

    // Capture inputs and state at clock edge
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_req   <= 0;
            prev_ptr   <= 0;
            prev_valid <= 1'b0;
        end else begin
            prev_req   <= req;
            prev_ptr   <= uut.ptr; // Hierarchical reference to internal pointer register
            prev_valid <= 1'b1;
        end
    end

    // Golden reference calculation task
    task compute_golden(
        input  [WIDTH-1:0]     r,
        input  [PTR_WIDTH-1:0] p,
        output [WIDTH-1:0]     g,
        output                 g_valid
    );
        integer i, idx;
        reg found;
        begin
            g = 0;
            g_valid = 0;
            found = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                idx = (p + i) % WIDTH;
                if (r[idx] && !found) begin
                    g[idx] = 1'b1;
                    g_valid = 1'b1;
                    found = 1;
                end
            end
        end
    endtask

    // Output Verification
    reg [WIDTH-1:0] exp_grant;
    reg             exp_grant_valid;
    integer         mismatches = 0;
    integer         total_checks = 0;

    always @(posedge clk) begin
        #1; // Delay to let UUT registered outputs settle
        if (rst_n && prev_valid) begin
            compute_golden(prev_req, prev_ptr, exp_grant, exp_grant_valid);
            total_checks = total_checks + 1;
            
            if (grant !== exp_grant || grant_valid !== exp_grant_valid) begin
                $display("[ERROR] Mismatch at time %0t ps:", $time);
                $display("  State:   prev_ptr = %d", prev_ptr);
                $display("  Inputs:  req      = %b", prev_req);
                $display("  RTL:     grant    = %b, valid = %b", grant, grant_valid);
                $display("  Golden:  grant    = %b, valid = %b", exp_grant, exp_grant_valid);
                mismatches = mismatches + 1;
            end
        end
    end

    // Main Test Stimulus
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 1;
        req = 0;

        // VCD Dump
        $dumpfile("tb_round_robin_arbiter.vcd");
        $dumpvars(0, tb_round_robin_arbiter);

        $display("==================================================");
        $display("Starting Round-Robin Arbiter Testbench (WIDTH = %0d)", WIDTH);
        $display("==================================================");

        // Apply Reset synchronously on posedge clk
        @(posedge clk);
        rst_n <= 0;
        repeat (2) @(posedge clk);
        rst_n <= 1;

        // Align stimulus drive to negedge clk
        @(negedge clk);

        // ----------------------------------------------------
        // Case 1: Single Requester (req[0] = 1)
        // ----------------------------------------------------
        $display("[TEST] Case 1: Single Requester (req[0] = 1)");
        req <= { {WIDTH-1{1'b0}}, 1'b1 }; // req = 00...001
        
        repeat (5) @(negedge clk);

        // ----------------------------------------------------
        // Case 2: Two Alternating Requesters (01 and 10 patterns)
        // ----------------------------------------------------
        if (WIDTH >= 2) begin
            $display("[TEST] Case 2: Two Alternating Requesters");
            req <= { {WIDTH-2{1'b0}}, 2'b01 };
            @(negedge clk);
            req <= { {WIDTH-2{1'b0}}, 2'b10 };
            @(negedge clk);
            req <= { {WIDTH-2{1'b0}}, 2'b01 };
            @(negedge clk);
            req <= { {WIDTH-2{1'b0}}, 2'b10 };
            @(negedge clk);
            req <= { {WIDTH-2{1'b0}}, 2'b01 };
            @(negedge clk);
            req <= { {WIDTH-2{1'b0}}, 2'b10 };
            @(negedge clk);
        end

        // ----------------------------------------------------
        // Case 3: All Requesters Active (req = all 1s)
        // ----------------------------------------------------
        $display("[TEST] Case 3: All Requesters Active");
        req <= {WIDTH{1'b1}};
        repeat (WIDTH * 2) @(negedge clk);

        // ----------------------------------------------------
        // Case 4: Random Request Patterns
        // ----------------------------------------------------
        $display("[TEST] Case 4: Random Request Patterns");
        repeat (100) begin
            req <= $urandom;
            @(negedge clk);
        end
        
        // Final idle cycle
        req <= 0;
        repeat (3) @(negedge clk);

        // Simulation Summary
        $display("==================================================");
        $display("Simulation finished. Total Checks: %0d", total_checks);
        if (mismatches == 0) begin
            $display("STATUS: PASSED (0 mismatches detected)");
        end else begin
            $display("STATUS: FAILED (%0d mismatches detected)", mismatches);
        end
        $display("==================================================");
        $finish;
    end

    // Debug monitor
    always @(posedge clk) begin
        #2;
        $display("Cycle Check | Time: %0t ps | rst_n=%b | req=%b | uut.ptr=%d | grant_next=%b | uut.grant=%b | uut.grant_valid=%b", 
                 $time, rst_n, req, uut.ptr, uut.grant_next, grant, grant_valid);
    end

endmodule
