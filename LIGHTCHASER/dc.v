module lightchaser #(
    parameter int WIDTH = 8,
    parameter int TICKS_PER_STEP = 4  // >=1: clocks per one rotation step
) (
    input  logic              clk,
    input  logic              rst_n,       // async active-low
    input  logic              enable,      // advance when 1
    output logic [WIDTH-1:0]  led_out
);

    // Internal counter and rotation logic
    logic [$clog2(TICKS_PER_STEP):0] tick;
    logic [WIDTH-1:0]                led;

    // Circular left shift function
    function automatic [WIDTH-1:0] rol1(input [WIDTH-1:0] x);
        rol1 = {x[WIDTH-2:0], x[WIDTH-1]};
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led  <= '0;
            led[0] <= 1'b1;  // Initial state: bit 0 high
            tick <= '0;
        end else begin
            if (enable) begin
                if (TICKS_PER_STEP == 1) begin
                    led  <= rol1(led);
                    tick <= '0;
                end else if (tick == TICKS_PER_STEP - 1) begin
                    led  <= rol1(led);
                    tick <= '0;
                end else begin
                    tick <= tick + 1;
                end
            end
        end
    end

    assign led_out = led;

endmodule
