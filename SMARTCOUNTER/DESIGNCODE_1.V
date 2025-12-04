// ===========================================================
// 8-bit SmartCounter
// Async reset, synchronous load, enable-controlled increment
// ===========================================================

module smart_counter (
    input  wire        clk,
    input  wire        rst,     // async reset
    input  wire        load,    // synchronous load
    input  wire        enable,  // increment enable
    input  wire [7:0]  data_in, // load value
    output reg  [7:0]  count
);

    // Asynchronous Reset
    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 8'd0;
        else if (load)
            count <= data_in;
        else if (enable)
            count <= count + 1'b1;
    end

endmodule
