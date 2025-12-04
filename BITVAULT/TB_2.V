`timescale 1ns/1ps

module tb_bitvault_regfile;

    reg         clk;
    reg         we;
    reg  [1:0]  addr;
    reg  [7:0]  data_in;
    wire [7:0]  data_out;

    // DUT
    bitvault_regfile DUT (
        .clk(clk),
        .we(we),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock
    always #5 clk = ~clk;

    // Checker task
    task check(input [7:0] expected);
    begin
        if (data_out !== expected)
            $display("❌ ERROR @ %0t: expected %0h, got %0h", $time, expected, data_out);
        else
            $display("✔ OK @ %0t: data_out = %0h", $time, data_out);
    end
    endtask

    initial begin
        // -------------------------------------------------
        // WAVEFORM DUMP (YOUR REQUEST)
        // -------------------------------------------------
        $dumpfile("dump.vcd");         // <-- separated clearly
        $dumpvars(0, tb_bitvault_regfile);

        $display("===== BITVAULT TEST START =====");

        clk = 0; we = 0; addr = 0; data_in = 0;

        // TEST 1: Multiple writes
        @(posedge clk); we = 1; addr = 0; data_in = 8'hAA;
        @(posedge clk); addr = 1; data_in = 8'h55;
        @(posedge clk); addr = 2; data_in = 8'hF0;
        @(posedge clk); addr = 3; data_in = 8'h0F;
        @(posedge clk); we = 0;

        // TEST 2: Readback
        addr = 0; #1; check(8'hAA);
        addr = 1; #1; check(8'h55);
        addr = 2; #1; check(8'hF0);
        addr = 3; #1; check(8'h0F);

        // TEST 3: Overwrite protection
        we = 0;
        addr = 1;
        data_in = 8'h99;    // attempt to overwrite when write disabled
        @(posedge clk);

        addr = 1; #1; check(8'h55);  // should not change

        // TEST 4: Valid overwrite
        we = 1;
        addr = 1;
        data_in = 8'h99;
        @(posedge clk);

        addr = 1; #1; check(8'h99);

        $display("===== BITVAULT TEST COMPLETE =====");
        $finish;
    end

endmodule
