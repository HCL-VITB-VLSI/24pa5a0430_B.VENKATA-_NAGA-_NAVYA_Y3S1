module PulseTracer #(parameter FILTER_LEN = 3)(
    input wire clk,
    input wire rst_n,
    input wire noisy_in,
    output reg pulse_out
);

    // Internal counter to track consecutive high cycles
    reg [$clog2(FILTER_LEN+1)-1:0] high_count;
    reg pulse_generated;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_count     <= 0;
            pulse_out      <= 0;
            pulse_generated <= 0;
        end else begin
            if (noisy_in) begin
                if (high_count < FILTER_LEN)
                    high_count <= high_count + 1;
            end else begin
                high_count <= 0;
                pulse_generated <= 0;  // Reset pulse flag when input goes low
            end

            // Generate pulse only once when FILTER_LEN is reached
            if (high_count == FILTER_LEN && !pulse_generated) begin
                pulse_out <= 1;
                pulse_generated <= 1;
            end else begin
                pulse_out <= 0;
            end
        end

