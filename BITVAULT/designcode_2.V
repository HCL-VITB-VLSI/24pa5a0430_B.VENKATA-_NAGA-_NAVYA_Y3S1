// BitVault - 4x8 Register File (DESIGN ONLY)

module bitvault_regfile (
    input  wire        clk,
    input  wire        we,        // write enable
    input  wire [1:0]  addr,      // read/write address
    input  wire [7:0]  data_in,   // data to write
    output wire [7:0]  data_out   // asynchronous read
);

    // 4 registers × 8 bits each
    reg [7:0] regfile [0:3];

    // synchronous write
    always @(posedge clk) begin
        if (we)
            regfile[addr] <= data_in;
    end

    // asynchronous read
    assign data_out = regfile[addr];

endmodule
