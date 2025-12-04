`timescale 1ns/1ps

module tb_bytestreamer;

    reg clk;
    reg rst;
    reg shift_enable;
    reg serial_in;

    wire [7:0] parallel_out;
    wire byte_ready;

    // Instantiate DUT
    bytestreamer DUT(
        .clk(clk),
        .rst(rst),
        .shift_enable(shift_enable),
        .serial_in(serial_in),
        .parallel_out(parallel_out),
        .byte_ready(byte_ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task WITHOUT arguments (old Verilog-safe)
    task send_byte;
        input [7:0] b;
        integer i;
        begin
            $display("Sending byte %h", b);
            for (i = 7; i >= 0; i = i - 1) begin
                serial_in = b[i];
                shift_enable = 1;
                @(posedge clk);
            end
            shift_enable = 0;
        end
    endtask

    initial begin
        // Waveform dump
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_bytestreamer);

        clk = 0;
        rst = 1;
        shift_enable = 0;
        serial_in = 0;

        @(posedge clk);
        rst = 0;

        // TEST 1
        send_byte(8'hA5);
        @(posedge clk);
        if (byte_ready) $display("Received: %h", parallel_out);
        else $display("Error: no byte_ready");

        // TEST 2
        send_byte(8'h3C);
        @(posedge clk);
        if (byte_ready) $display("Received: %h", parallel_out);
        else $display("Error: no byte_ready");

        $display("Test complete");
        $finish;
    end

endmodule
