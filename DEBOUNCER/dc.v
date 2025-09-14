module debouncerlite #(parameter N = 4)(
    input wire clk,
    input wire rstn,
    input wire noisy_in,
    output reg clean_out
);

    reg [$clog2(N+1)-1:0] counter;
    reg stable_state;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            counter      <= 0;
            stable_state <= 0;
            clean_out    <= 0;
        end else begin
            if (noisy_in == stable_state) begin
                counter <= 0;  // No change needed
            end else begin
                counter <= counter + 1;
                if (counter == N - 1) begin
                    stable_state <= noisy_in;
                    clean_out    <= noisy_in;
                    counter      <= 0;
                end
            end
        end
    end

endmodule
