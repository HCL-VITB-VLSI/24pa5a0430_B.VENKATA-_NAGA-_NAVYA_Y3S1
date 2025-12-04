module ringbuffer #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg                   full,
    output reg                   empty
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [1:0] wr_ptr, rd_ptr;   // 2-bit for depth 4
    reg [2:0] count;            // 0..4

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            full   <= 0;
            empty  <= 1;
            data_out <= 0;
        end else begin
            // Write
            if (wr_en && !full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end

            // Read
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end

            // Flags
            full  <= (count == DEPTH);
            empty <= (count == 0);
        end
    end

endmodule

