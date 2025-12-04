`timescale 1ns/1ps

module tb_smart_counter;

    reg         clk;
    reg         rst;
    reg         load;
    reg         enable;
    reg  [7:0]  data_in;
    wire [7:0]  count;

    // Instantiate DUT
    smart_counter DUT (
        .clk(clk),
        .rst(rst),
        .load(load),
        .enable(enable),
        .data_in(data_in),
        .count(count)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Check task
    task check(input [7:0] expected);
        begin
            if (count !== expected)
                $display("❌ ERROR @ %0t: expected %0d, got %0d", $time, expected, count);
            else
                $display("✔ OK @ %0t: count = %0d", $time, count);
        end
    endtask

    initial begin
        // -----------------------------
        // Waveform dump
        // -----------------------------
        $dumpfile("dump.vcd");       // creates VCD file
        $dumpvars(0, tb_smart_counter);

        $display("===== STARTING SMART COUNTER TEST =====");

        clk = 0; rst = 0; load = 0;
        enable = 0; data_in = 8'h00;

        // Async reset test
        #3 rst = 1;
        #5;
        check(0);
        rst = 0;

        // Load test
        @(posedge clk);
        data_in = 8'h55;
        load = 1;
        @(posedge clk);
        load = 0;
        check(8'h55);

        // Increment test
        enable = 1;
        repeat(3) @(posedge clk);
        enable = 0;
        check(8'h55 + 3);

        // Reset + load + increment combined test
        @(posedge clk);
        rst = 1;
        #2;
        check(0);
        rst = 0;

        @(posedge clk);
        data_in = 8'hF0;
        load = 1;
        @(posedge clk);
        load = 0;
        check(8'hF0);

        enable = 1;
        @(posedge clk);
        @(posedge clk);
        enable = 0;
        check(8'hF0 + 2);

        $display("===== TEST COMPLETE =====");
        $finish;
    end

endmodule

