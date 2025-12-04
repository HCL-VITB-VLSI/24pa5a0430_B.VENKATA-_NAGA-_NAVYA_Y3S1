module prioritylock_arbiter (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] req,
    output reg  [3:0] grant
);

    reg [1:0] ptr; // round-robin pointer 0-3

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ptr   <= 2'd0;
            grant <= 4'b0000;
        end else begin
            grant <= 4'b0000;

            // check requests in round-robin order
            case (ptr)
                2'd0: begin
                    if (req[0]) begin grant <= 4'b0001; ptr <= 2'd1; end
                    else if (req[1]) begin grant <= 4'b0010; ptr <= 2'd2; end
                    else if (req[2]) begin grant <= 4'b0100; ptr <= 2'd3; end
                    else if (req[3]) begin grant <= 4'b1000; ptr <= 2'd0; end
                end

                2'd1: begin
                    if (req[1]) begin grant <= 4'b0010; ptr <= 2'd2; end
                    else if (req[2]) begin grant <= 4'b0100; ptr <= 2'd3; end
                    else if (req[3]) begin grant <= 4'b1000; ptr <= 2'd0; end
                    else if (req[0]) begin grant <= 4'b0001; ptr <= 2'd1; end
                end

                2'd2: begin
                    if (req[2]) begin grant <= 4'b0100; ptr <= 2'd3; end
                    else if (req[3]) begin grant <= 4'b1000; ptr <= 2'd0; end
                    else if (req[0]) begin grant <= 4'b0001; ptr <= 2'd1; end
                    else if (req[1]) begin grant <= 4'b0010; ptr <= 2'd2; end
                end

                2'd3: begin
                    if (req[3]) begin grant <= 4'b1000; ptr <= 2'd0; end
                    else if (req[0]) begin grant <= 4'b0001; ptr <= 2'd1; end
                    else if (req[1]) begin grant <= 4'b0010; ptr <= 2'd2; end
                    else if (req[2]) begin grant <= 4'b0100; ptr <= 2'd3; end
                end
            endcase
        end
    end

endmodule
