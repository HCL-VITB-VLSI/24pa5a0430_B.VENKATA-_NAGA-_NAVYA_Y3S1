module edgehighlighter #(
    parameter USE_SYNC = 1
)(
    input clk,
    input rst_n,
    input in_sig,
    output reg rise_pulse,
    output reg fall_pulse
);

    reg s1, s2;
    reg cur, prev;

    wire sync_in = (USE_SYNC) ? s2 : in_sig;

    // Optional synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1 <= 0; s2 <= 0;
        end else begin
            s1 <= in_sig;
            s2 <= s1;
        end
    end

    // Edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev       <= 0;
            rise_pulse <= 0;
            fall_pulse <= 0;
        end else begin
            cur        <= sync_in;
            rise_pulse <=  sync_in & ~prev;
            fall_pulse <= ~sync_in &  prev;
            prev       <= sync_in;
        end
    end
endmodule
