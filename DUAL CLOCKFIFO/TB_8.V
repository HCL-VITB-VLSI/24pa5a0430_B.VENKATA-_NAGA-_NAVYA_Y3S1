`timescale 1ns/1ps

module tb_dual_clock_fifo;

    reg wr_clk, rd_clk;
    reg rst;
    reg wr_en, rd_en;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire full, empty;

    // DUT
    dual_clock_fifo DUT(
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Clock generation
    initial begin
        wr_clk = 0; forever #5 wr_clk = ~wr_clk;  // 10ns period
    end
    initial begin
        rd_clk = 0; forever #7 rd_clk = ~rd_clk;  // 14ns period
    end

    // Task to write
    task write_byte(input [7:0] d);
        begin
            data_in = d;
            wr_en = 1; @(posedge wr_clk); wr_en = 0;
        end
    endtask

    // Task to read
    task read_byte;
        begin
            rd_en = 1; @(posedge rd_clk); rd_en = 0;
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
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_dual_clock_fifo);

        rst = 1; wr_en = 0; rd_en = 0; data_in = 0;
        @(posedge wr_clk); @(posedge rd_clk);
        rst = 0;

        // ----------------------------------------
        // TEST: write several bytes
        // ----------------------------------------
        write_byte(8'hA1); show();
        write_byte(8'hB2); show();
        write_byte(8'hC3); show();
        write_byte(8'hD4); show();

        // ----------------------------------------
        // TEST: read a few bytes
        // ----------------------------------------
        read_byte(); show();
        read_byte(); show();

        // ----------------------------------------
        // TEST: continue writing (wrap-around)
        // ----------------------------------------
        write_byte(8'hE5); show();
        write_byte(8'hF6); show();

        // ----------------------------------------
        // TEST: continue reading
        // ----------------------------------------
        read_byte(); show();
        read_byte(); show();
        read_byte(); show();
        read_byte(); show();

        $display("===== Dual Clock FIFO TEST COMPLETE =====");
        $finish;
    end

endmodule
