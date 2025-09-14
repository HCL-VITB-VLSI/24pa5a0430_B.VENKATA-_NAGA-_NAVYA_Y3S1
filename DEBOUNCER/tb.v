module evenoddfsm (
    input wire clk,
    input wire reset,
    input wire in_valid,
    input wire [7:0] data_in,
    output reg even,
    output reg odd
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            even <= 0;
            odd  <= 0;
        end else begin
            if (in_valid) begin
                if (data_in[0] == 1'b0) begin
                    even <= 1;
                    odd  <= 0;
                end else begin
                    even <= 0;
                    odd  <= 1;
                end
            end else begin
                even <= 0;
                odd  <= 0;
            end
        end
    end

endmodule

