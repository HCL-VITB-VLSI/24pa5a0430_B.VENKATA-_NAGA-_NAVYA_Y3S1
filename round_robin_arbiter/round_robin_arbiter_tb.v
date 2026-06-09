// ============================================================================
// Testbench Name: round_robin_arbiter_tb
// File Name:      round_robin_arbiter_tb.v
// Description:    Thorough self-checking testbench for the round-robin arbiter.
//                 Exercises single requester, alternating requesters, all
//                 active requesters, and random request patterns.
// ============================================================================

`timescale 1ns / 1ps

module round_robin_arbiter_tb;

    // Parameters
    parameter integer WIDTH = 4;
    localparam integer ADDR_WIDTH = (WIDTH > 1) ? $clog2(WIDTH) : 1;

    // Testbench signals
    reg                  clk;
    reg                  rst_n;
    reg  [WIDTH-1:0]     req;
    wire [WIDTH-1:0]     grant;
    wire                 grant_valid;

    // Instantiate the Unit Under Test (UUT)
    round_robin_arbiter #(
        .WIDTH(WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant),
        .grant_valid(grant_valid)
    );

    // Clock generation (50 MHz -> 20ns period)
    always begin
        #10 clk = ~clk;
    end

    // Golden model state and outputs
    reg [ADDR_WIDTH-1:0] expected_ptr;
    reg [WIDTH-1:0]      gold_grant;
    reg                  gold_valid;
    reg [ADDR_WIDTH-1:0] gold_next_ptr;
    
    integer mismatch_count;
    integer test_case_count;

    // Golden model logic task
    task compute_golden;
        input  [WIDTH-1:0]      cur_req;
        input  [ADDR_WIDTH-1:0] cur_ptr;
        output [WIDTH-1:0]      gold_grant_out;
        output                  gold_valid_out;
        output [ADDR_WIDTH-1:0] gold_next_ptr_out;
        integer j;
        reg found;
        integer idx;
        begin
            gold_grant_out = {WIDTH{1'b0}};
            gold_valid_out = |cur_req;
            found = 0;
            idx = 0;
            if (gold_valid_out) begin
                // Scan starting from cur_ptr to WIDTH-1
                for (j = 0; j < WIDTH; j = j + 1) begin
                    if (j >= cur_ptr && cur_req[j] && !found) begin
                        gold_grant_out[j] = 1'b1;
                        idx = j;
                        found = 1;
                    end
                end
                // If not found, scan from 0 to cur_ptr-1 (wrap-around)
                if (!found) begin
                    for (j = 0; j < WIDTH; j = j + 1) begin
                        if (j < cur_ptr && cur_req[j] && !found) begin
                            gold_grant_out[j] = 1'b1;
                            idx = j;
                            found = 1;
                        end
                    end
                end
                gold_next_ptr_out = (idx == WIDTH - 1) ? {ADDR_WIDTH{1'b0}} : (idx + 1'b1);
            end else begin
                gold_next_ptr_out = cur_ptr;
            end
        end
    endtask

    // Self-checking check block
    // We sample DUT signals at posedge and compare with golden model
    always @(posedge clk) begin
        if (!rst_n) begin
            expected_ptr <= {ADDR_WIDTH{1'b0}};
        end else begin
            // Compute expected outputs using the request and expected_ptr *before* the edge
            compute_golden(req, expected_ptr, gold_grant, gold_valid, gold_next_ptr);
            
            // Wait 1ns to let logic settle in simulator
            #1;
            
            // Compare
            if (grant !== gold_grant || grant_valid !== gold_valid) begin
                $display("[ERROR] Mismatch at time %0t ns!", $time);
                $display("        Inputs: req = %b, expected_ptr = %d, DUT ptr = %d", req, expected_ptr, uut.ptr);
                $display("        DUT grant = %b, Expected grant = %b", grant, gold_grant);
                $display("        DUT valid = %b, Expected valid = %b", grant_valid, gold_valid);
                mismatch_count = mismatch_count + 1;
            end
            
            // Update expected pointer
            if (gold_valid) begin
                expected_ptr <= gold_next_ptr;
            end
        end
    end

    // Test sequence
    initial begin
        // Initialize VCD dump
        $dumpfile("arbiter.vcd");
        $dumpvars(0, round_robin_arbiter_tb);

        // Initialize signals
        clk = 0;
        rst_n = 0;
        req = 0;
        mismatch_count = 0;
        test_case_count = 0;
        expected_ptr = 0;

        $display("==================================================");
        $display("Starting Round-Robin Arbiter Testbench (WIDTH = %0d)", WIDTH);
        $display("==================================================");

        // Assert reset for 2 cycles
        #40;
        rst_n = 1;
        #10; // align with negative edge of clk

        // ------------------------------------------------------------
        // Case 1: Single Requester (req[0] = 1, others = 0)
        // ------------------------------------------------------------
        $display("\n--- Case 1: Single Requester ---");
        test_case_count = test_case_count + 1;
        @(negedge clk);
        req = { {WIDTH-1{1'b0}}, 1'b1 }; // req = 0001
        repeat(5) @(negedge clk);

        // ------------------------------------------------------------
        // Case 2: Alternating Requesters
        // ------------------------------------------------------------
        $display("\n--- Case 2: Alternating Requesters ---");
        test_case_count = test_case_count + 1;
        @(negedge clk);
        req = { {WIDTH-1{1'b0}}, 1'b1 }; // e.g., 0001
        @(negedge clk);
        req = { {WIDTH-2{1'b0}}, 2'b10 }; // e.g., 0010
        @(negedge clk);
        req = { {WIDTH-1{1'b0}}, 1'b1 };
        @(negedge clk);
        req = { {WIDTH-2{1'b0}}, 2'b10 };
        @(negedge clk);
        req = 0; // idle
        @(negedge clk);

        // ------------------------------------------------------------
        // Case 3: All Requesters Active
        // ------------------------------------------------------------
        $display("\n--- Case 3: All Requesters Active ---");
        test_case_count = test_case_count + 1;
        @(negedge clk);
        req = {WIDTH{1'b1}}; // All bits set to 1
        repeat(WIDTH * 2) @(negedge clk); // Cycle through all positions twice
        req = 0;
        @(negedge clk);

        // ------------------------------------------------------------
        // Case 4: Random Request Patterns
        // ------------------------------------------------------------
        $display("\n--- Case 4: Random Request Patterns ---");
        test_case_count = test_case_count + 1;
        repeat(30) begin
            @(negedge clk);
            req = $urandom;
            $display("[RAND] Time: %0t ns, req = %b, DUT ptr = %d, DUT grant = %b, DUT valid = %b", 
                     $time, req, uut.ptr, grant, grant_valid);
        end
        
        // Return to idle
        @(negedge clk);
        req = 0;
        repeat(3) @(negedge clk);

        // ------------------------------------------------------------
        // End Simulation
        // ------------------------------------------------------------
        $display("\n==================================================");
        $display("Simulation Completed.");
        $display("Total Test Cases: %0d", test_case_count);
        if (mismatch_count == 0) begin
            $display("STATUS: PASSED. All checks match the golden model.");
        end else begin
            $display("STATUS: FAILED. Found %0d mismatches.", mismatch_count);
        end
        $display("==================================================");
        $finish;
    end

endmodule
