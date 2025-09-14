module rotatorunit #(
    parameter int WIDTH = 8
) (
    input  logic              clk,
    input  logic              rst_n,      // async active-low
    input  logic              enable,     // gate for load/rotate
    input  logic              load,       // synchronous load
    input  logic              dir,        // 0: left, 1: right
    input  logic [WIDTH-1:0]  data_in,
    output logic [WIDTH-1:0]  data_out
);

    // Internal state register
    logic [WIDTH-1:0] state;

    // Rotation functions
    function automatic [WIDTH-1:0] rol1(input [WIDTH-1:0] x);
        rol1 = {x[WIDTH-2:0], x[WIDTH-1]};
    endfunction

    function automatic [WIDTH-1:0] ror1(input [WIDTH-1:0] x);
        ror1 = {x[0], x[WIDTH-1:1]};
    endfunction

    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= '0;
        end else if (enable) begin
            if (load)
                state <= data_in;
            else
                state <= dir ? ror1(state) : rol1(state);
        end
    end

    assign data_out = state;

endmodule

