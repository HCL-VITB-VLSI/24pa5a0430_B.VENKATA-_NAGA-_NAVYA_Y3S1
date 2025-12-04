// =========================================================
// ModeMux - 4-input multiplexer with Fixed-Priority / Round-Robin
// Inputs: req[3:0], mode (0=fixed-priority, 1=round-robin)
// Output: grant[3:0], selected output data_out
// =========================================================
module modemux #(
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire [3:0] req,
    input  wire [DATA_WIDTH-1:0] data_in0,
    input  wire [DATA_WIDTH-1:0] data_in1,
    input  wire [DATA_WIDTH-1:0] data_in2,
    input  wire [DATA_WIDTH-1:0] data_in3,
    input  wire mode,          // 0=fixed-priority, 1=round-robin
    output reg  [3:0] grant,
    output reg  [DATA_WIDTH-1:0] data_out
);

    reg [1:0] rr_ptr; // round-robin pointer

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 4'b0000;
            data_out <= {DATA_WIDTH{1'b0}};
            rr_ptr <= 0;
        end else begin
            grant <= 4'b0000;
            data_out <= {DATA_WIDTH{1'b0}};
            if (mode == 0) begin
                // Fixed-priority: 0 > 1 > 2 > 3
                if (req[0]) begin grant <= 4'b0001; data_out <= data_in0; end
                else if (req[1]) begin grant <= 4'b0010; data_out <= data_in1; end
                else if (req[2]) begin grant <= 4'b0100; data_out <= data_in2; end
                else if (req[3]) begin grant <= 4'b1000; data_out <= data_in3; end
            end else begin
                // Round-robin using "found" flag instead of disable
                integer i;
                reg [1:0] idx;
                reg found;
                found = 0;
                for (i=0; i<4; i=i+1) begin
                    idx = (rr_ptr + i) % 4;
                    if (req[idx] && !found) begin
                        grant <= 4'b0001 << idx;
                        case(idx)
                            0: data_out <= data_in0;
                            1: data_out <= data_in1;
                            2: data_out <= data_in2;
                            3: data_out <= data_in3;
                        endcase
                        rr_ptr <= (idx + 1) % 4;
                        found = 1;
                    end
                end
            end
        end
    end

endmodule
