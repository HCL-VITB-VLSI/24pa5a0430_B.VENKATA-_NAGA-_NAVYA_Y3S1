`timescale 1ns/1ps

module tb_ringbuffer;

    reg clk;
    reg rst;
    reg wr_en, rd_en;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire full, empty;

    // DUT
    ringbuffer DUT(
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Clock
    always #5 clk = ~clk;

    // Task to write data
    task write_byte(input [7:0] d);
        begin
            data_in = d; wr_en = 1; @(posedge clk); wr_en = 0;
        end
    endtask

    // Task to read data
    task read_byte;
        begin
            rd_en = 1; @(posedge clk); rd_en = 0;
        end
    endtask

    // Display status
    task show;
        begin
            $display("t=%0t wr_en=%b rd_en=%b data_in=%02h data_out=%02h full=%b empty=%b",
                     $time, wr_en, rd_en, data_in, data_out, full, empty);
        end
    endtask

    initial begin
        // --------------------------------------------------
        // VCD dump
        // --------------------------------------------------
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_ringbuffer);

        clk = 0;
        rst = 1;
        wr_en = 0; rd_en = 0;
        data_in = 0;

        @(posedge clk);
        rst = 0;

        // --------------------------------------------------
        // TEST 1: Fill FIFO
        // --------------------------------------------------
        $display("\n--- TEST 1: Fill FIFO ---");
        write_byte(8'hAA); show();
        write_byte(8'hBB); show();
        write_byte(8'hCC); show();
        write_byte(8'hDD); show();  // should become full
        write_byte(8'hEE); show();  // ignored, FIFO full

        // --------------------------------------------------
        // TEST 2: Empty FIFO
        // --------------------------------------------------
        $display("\n--- TEST 2: Empty FIFO ---");
        read_byte(); show();
        read_byte(); show();
        read_byte(); show();
        read_byte(); show();  // should become empty
        read_byte(); show();  // ignored, FIFO empty

        // --------------------------------------------------
        // TEST 3: Wrap-around
        // --------------------------------------------------
        $display("\n--- TEST 3: Wrap-around ---");
        write_byte(8'h11); show();
        write_byte(8'h22); show();
        read_byte(); show();
        write_byte(8'h33); show();
        write_byte(8'h44); show();  // wrap-around
        write_byte(8'h55); show();  // should be full

        // Read remaining
        read_byte(); show();
        read_byte(); show();
        read_byte(); show();
        read_byte(); show();

        $display("===== RingBuffer TEST COMPLETE =====");
        $finish;
    end

endmodule
