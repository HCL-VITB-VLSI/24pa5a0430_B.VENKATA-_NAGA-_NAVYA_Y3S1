`timescale 1ns/1ps

module tb_stoptimer;

    reg clk;
    reg rst;
    reg start, stop;
    wire [7:0] elapsed_time;

    // DUT
    stoptimer DUT(
        .clk(clk),
        .rst(rst),
        .start(start),
        .stop(stop),
        .elapsed_time(elapsed_time)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Display helper
    task show;
        begin
            $display("t=%0t start=%b stop=%b elapsed=%0d", $time, start, stop, elapsed_time);
        end
    endtask

    initial begin
        // -------------------------
        // VCD dump
        // -------------------------
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_stoptimer);

        clk = 0;
        rst = 1;
        start = 0;
        stop = 0;

        @(posedge clk);
        rst = 0;

        // -------------------------
        // TEST 1: Simple Start
        // -------------------------
        $display("\n--- TEST 1: Simple Start ---");
        start = 1; @(posedge clk); start = 0;
        repeat(5) @(posedge clk); show();

        // -------------------------
        // TEST 2: Stop
        // -------------------------
        $display("\n--- TEST 2: Stop ---");
        stop = 1; @(posedge clk); stop = 0;
        repeat(3) @(posedge clk); show(); // counter should not increment

        // -------------------------
        // TEST 3: Restart
        // -------------------------
        $display("\n--- TEST 3: Restart ---");
        start = 1; @(posedge clk); start = 0;
        repeat(4) @(posedge clk); show();

        // -------------------------
        // TEST 4: Reset while stopped
        // -------------------------
        $display("\n--- TEST 4: Reset ---");
        rst = 1; @(posedge clk); rst = 0; show();

        // -------------------------
        // TEST 5: Continuous RUN after reset
        // -------------------------
        start = 1; @(posedge clk); start = 0;
        repeat(6) @(posedge clk); show();

        $display("===== StopTimer TEST COMPLETE =====");
        $finish;
    end

endmodule
