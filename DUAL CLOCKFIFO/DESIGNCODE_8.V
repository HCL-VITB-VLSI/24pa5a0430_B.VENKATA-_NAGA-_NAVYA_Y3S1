// =========================================================
// Dual-Clock FIFO (Depth 8, 8-bit data)
// Features:
//   • Separate write and read clocks
//   • Gray-code pointer synchronization
//   • Optional reset sync
// =========================================================
module dual_clock_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  rst,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output wire                  full,
    output wire                  empty
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write pointer (binary)
    reg [ADDR_WIDTH:0] wr_ptr_bin;
    reg [ADDR_WIDTH:0] wr_ptr_gray;

    // Read pointer (binary)
    reg [ADDR_WIDTH:0] rd_ptr_bin;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    // Synchronized pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray_rdclk;
    reg [ADDR_WIDTH:0] rd_ptr_gray_wrclk;

    // -----------------------------------------
    // Binary -> Gray
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    // Gray -> Binary
    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
        integer i;
        reg [ADDR_WIDTH:0] bin;
        begin
            bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >=0; i=i-1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // -----------------------------------------
    // Write pointer logic
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            wr_ptr_bin <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= data_in;
        end
    end

    // -----------------------------------------
    // Read pointer logic
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            data_out <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
            data_out <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

    // -----------------------------------------
    // Synchronize pointers across clock domains
    reg [ADDR_WIDTH:0] rd_ptr_gray_wrclk_1, rd_ptr_gray_wrclk_2;
    always @(posedge wr_clk) begin
        rd_ptr_gray_wrclk_1 <= rd_ptr_gray;
        rd_ptr_gray_wrclk_2 <= rd_ptr_gray_wrclk_1;
        rd_ptr_gray_wrclk <= rd_ptr_gray_wrclk_2;
    end

    reg [ADDR_WIDTH:0] wr_ptr_gray_rdclk_1, wr_ptr_gray_rdclk_2;
    always @(posedge rd_clk) begin
        wr_ptr_gray_rdclk_1 <= wr_ptr_gray;
        wr_ptr_gray_rdclk_2 <= wr_ptr_gray_rdclk_1;
        wr_ptr_gray_rdclk <= wr_ptr_gray_rdclk_2;
    end

    // -----------------------------------------
    // Full / Empty flags
    assign full  = (bin2gray(wr_ptr_bin + 1'b1) == {~rd_ptr_gray_wrclk[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_wrclk[ADDR_WIDTH-2:0]});
    assign empty = (rd_ptr_gray == wr_ptr_gray_rdclk);

endmodule

