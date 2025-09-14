module graycoder (
    input wire clk,
    input wire [3:0] bin_in,
    output reg [3:0] gray_out
);

    always @(posedge clk) begin
        // Gray code conversion: MSB remains same, rest are XORed
        gray_out[3] <= bin_in[3];
        gray_out[2] <= bin_in[3] ^ bin_in[2];
        gray_out[1] <= bin_in[2] ^ bin_in[1];
        gray_out[0] <= bin_in[1] ^ bin_in[0];
    end

endmodule
