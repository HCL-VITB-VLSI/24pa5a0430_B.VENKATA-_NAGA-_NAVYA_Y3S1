`timescale 1ns/1ps

module tb_modemux;

    reg clk;
    reg rst;
    reg [3:0] req;
    reg [7:0] data_in0, data_in1, data_in2, data_in3;
    reg mode; // 0=fixed, 1=round-robin
    wire [3:0] grant;
    wire [7:0] data_out;

    // DUT
    modemux DUT(
        .clk(clk),
        .rst(rst),
        .req(req),
        .data_in0(data_in0),
        .data_in1(data_in1),
        .data_in2(data_in2),
        .data_in3(data_in3),
        .mode(mode),
        .grant(grant),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Display task
    task show;
        begin
            $display("t=%0t mode=%b req=%b grant=%b data_out=%02h", 
                     $time, mode, req, grant, data_out);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_modemux);

        clk = 0;
        rst = 1;
        req = 0;
        mode = 0;
        data_in0 = 8'hA0; data_in1 = 8'hB1; data_in2 = 8'hC2; data_in3 = 8'hD3;
        @(posedge clk); rst = 0;

        // ----------------------------------------
        // TEST 1: Fixed-priority with multiple requests
        // ----------------------------------------
        $display("\n--- TEST 1: Fixed-priority ---");
        mode = 0;
        req = 4'b1101; @(posedge clk); show(); // inputs 0,2,3 requested
        req = 4'b0010; @(posedge clk); show(); // input 1 only
        req = 4'b0000; @(posedge clk); show(); // none

        // ----------------------------------------
        // TEST 2: Round-robin with multiple requests
        // ----------------------------------------
        $display("\n--- TEST 2: Round-robin ---");
        mode = 1;
        req = 4'b1111; @(posedge clk); show(); // grant rotates each clock
        req = 4'b1111; @(posedge clk); show();
        req = 4'b1111; @(posedge clk); show();
        req = 4'b1111; @(posedge clk); show();

        // ----------------------------------------
        // TEST 3: Round-robin with changing requests
        // ----------------------------------------
        $display("\n--- TEST 3: Mixed requests ---");
        req = 4'b1010; @(posedge clk); show();
        req = 4'b0011; @(posedge clk); show();
        req = 4'b0100; @(posedge clk); show();

        $display("===== ModeMux TEST COMPLETE =====");
        $finish;
    end

endmodule

