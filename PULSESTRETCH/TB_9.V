`timescale 1ns/1ps

module tb_pulsestretch;

    reg clk;
    reg rst;
    reg in_pulse;
    wire out_pulse;

    // DUT
    pulsestretch DUT(
        .clk(clk),
        .rst(rst),
        .in_pulse(in_pulse),
        .out_pulse(out_pulse)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Display helper
    task show;
        begin
            $display("t=%0t in=%b out=%b", $time, in_pulse, out_pulse);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pulsestretch);

        clk = 0;
        rst = 1;
        in_pulse = 0;
        @(posedge clk);
        rst = 0;

        // ----------------------------------------
        // TEST 1: Single short pulse
        // ----------------------------------------
        $display("\n--- TEST 1: Single short pulse ---");
        in_pulse = 1; @(posedge clk); in_pulse = 0;
        repeat(6) @(posedge clk); show();

        // ----------------------------------------
        // TEST 2: Two rapid pulses
        // ----------------------------------------
        $display("\n--- TEST 2: Two rapid pulses ---");
        in_pulse = 1; @(posedge clk); in_pulse = 0;
        @(posedge clk);
        in_pulse = 1; @(posedge clk); in_pulse = 0;
        repeat(10) @(posedge clk); show();

        // ----------------------------------------
        // TEST 3: Long pulse input
        // ----------------------------------------
        $display("\n--- TEST 3: Long input pulse ---");
        in_pulse = 1; repeat(3) @(posedge clk); in_pulse = 0;
        repeat(6) @(posedge clk); show();

        $display("===== PulseStretch TEST COMPLETE =====");
        $finish;
    end

endmodule
