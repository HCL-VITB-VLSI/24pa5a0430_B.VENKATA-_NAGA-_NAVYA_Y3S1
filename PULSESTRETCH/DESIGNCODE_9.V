// =========================================================
// PulseStretch - Stretch input pulses to 5 clock cycles
// =========================================================
module pulsestretch #(
    parameter STRETCH = 5
)(
    input  wire clk,
    input  wire rst,
    input  wire in_pulse,
    output reg  out_pulse
);

    reg [2:0] counter;  // 3 bits enough for count 0-5
    reg busy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter   <= 0;
            busy      <= 0;
            out_pulse <= 0;
        end else begin
            if (busy) begin
                // Continue stretching current pulse
                counter   <= counter - 1;
                out_pulse <= 1;
                if (counter == 1)
                    busy <= 0; // Done after 5 cycles
            end else begin
                if (in_pulse) begin
                    busy      <= 1;
                    counter   <= STRETCH;
                    out_pulse <= 1;
                end else begin
                    out_pulse <= 0;
                end
            end
        end
    end

endmodule
