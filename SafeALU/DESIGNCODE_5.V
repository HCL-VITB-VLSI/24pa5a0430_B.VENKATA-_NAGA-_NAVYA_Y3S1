module safealu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] opcode,   // 00=ADD, 01=SUB, 10=AND, 11=OR
    output reg  [7:0] result,
    output reg        zero,
    output reg        carry,
    output reg        overflow
);

    reg [8:0] sum; // 9-bit for carry detection
    reg [8:0] diff;

    always @(*) begin
        // default
        result   = 8'd0;
        zero     = 0;
        carry    = 0;
        overflow = 0;
        sum      = 9'd0;
        diff     = 9'd0;

        case (opcode)
            2'b00: begin // ADD
                sum = {1'b0, a} + {1'b0, b};
                result = sum[7:0];
                carry  = sum[8];
                // overflow detection: if signs of operands same, result sign differs
                overflow = (~a[7] & ~b[7] & result[7]) | (a[7] & b[7] & ~result[7]);
            end
            2'b01: begin // SUB
                diff = {1'b0, a} - {1'b0, b};
                result = diff[7:0];
                carry  = diff[8]; // borrow flag: 1 if a < b
                overflow = (a[7] & ~b[7] & ~result[7]) | (~a[7] & b[7] & result[7]);
            end
            2'b10: begin // AND
                result = a & b;
            end
            2'b11: begin // OR
                result = a | b;
            end
        endcase

        zero = (result == 8'd0);
    end

endmodule
