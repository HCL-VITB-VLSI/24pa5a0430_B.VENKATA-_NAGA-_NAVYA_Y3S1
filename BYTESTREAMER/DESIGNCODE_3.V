module bytestreamer (
    input clk,
    input rst,
    input shift_enable,
    input serial_in,
    output reg [7:0] parallel_out,
    output reg byte_ready
);

    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg  <= 0;
            bit_count  <= 0;
            byte_ready <= 0;
        end else begin
            byte_ready <= 0;
            if (shift_enable) begin
                shift_reg <= {shift_reg[6:0], serial_in};
                bit_count <= bit_count + 1;
                if (bit_count == 7) begin
                    parallel_out <= {shift_reg[6:0], serial_in};
                    byte_ready <= 1;
                    bit_count <= 0;
                end
            end
        end
    end

endmodule
