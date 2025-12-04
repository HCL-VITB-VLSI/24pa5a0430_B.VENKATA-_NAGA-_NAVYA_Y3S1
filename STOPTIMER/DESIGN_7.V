// =========================================================
// StopTimer - FSM-based Stopwatch Controller
// Inputs: start, stop, reset
// Output: 8-bit elapsed_time counter
// =========================================================

module stoptimer(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire stop,
    output reg  [7:0] elapsed_time
);

    // FSM states
    typedef enum reg [1:0] {IDLE=2'b00, RUN=2'b01, STOP=2'b10} state_t;
    state_t state, next_state;

    // FSM sequential
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    // FSM combinational
    always @(*) begin
        next_state = state;
        case(state)
            IDLE: begin
                if (start) next_state = RUN;
            end
            RUN: begin
                if (stop) next_state = STOP;
            end
            STOP: begin
                if (start) next_state = RUN;
                else if (rst) next_state = IDLE;
            end
        endcase
    end

    // Counter
    always @(posedge clk or posedge rst) begin
        if (rst) elapsed_time <= 8'd0;
        else if (state == RUN)
            elapsed_time <= elapsed_time + 1'b1;
    end

endmodule
