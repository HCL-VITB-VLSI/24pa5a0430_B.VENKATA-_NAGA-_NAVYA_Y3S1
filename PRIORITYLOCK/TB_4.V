`timescale 1ns/1ps

module tb_prioritylock_arbiter;

    reg clk;
    reg rst;
    reg [3:0] req;
    wire [3:0] grant;

    // DUT
    prioritylock_arbiter DUT(
        .clk(clk),
        .rst(rst),
        .req(req),
        .grant(grant)
    );

    // Clock
    always #5 clk = ~clk;

    // Display helper
    task show;
        begin
            $display("t=%0t  req=%b  grant=%b", $time, req, grant);
        end
    endtask

    initial begin
        // Dumpfile for waveform output
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_prioritylock_arbiter);

        clk = 0;
        rst = 1;
        req = 4'b0000;

        @(posedge clk);
        rst = 0;

        // ----------------------------------------
        // TEST 1: Single request rotating
        // ----------------------------------------
        req = 4'b0001; repeat (4) begin @(posedge clk); show(); end
        req = 4'b0010; repeat (4) begin @(posedge clk); show(); end
        req = 4'b0100; repeat (4) begin @(posedge clk); show(); end
        req = 4'b1000; repeat (4) begin @(posedge clk); show(); end

        // ----------------------------------------
        // TEST 2: Overlapping requests
        // ----------------------------------------
        req = 4'b0111; repeat (8) begin @(posedge clk); show(); end

        // ----------------------------------------
        // TEST 3: Persistent multiple requests
        // ----------------------------------------
        req = 4'b1010; repeat (8) begin @(posedge clk); show(); end

        // ----------------------------------------
        // TEST 4: All requests active
        // ----------------------------------------
        req = 4'b1111; repeat (8) begin @(posedge clk); show(); end

        $display("\n==== TEST COMPLETE ====");
        $finish;
    end

endmodule
