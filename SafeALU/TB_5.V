`timescale 1ns/1ps

module tb_safealu;

    reg  [7:0] a, b;
    reg  [1:0] opcode;
    wire [7:0] result;
    wire zero, carry, overflow;

    // Instantiate ALU
    safealu DUT(
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result),
        .zero(zero),
        .carry(carry),
        .overflow(overflow)
    );

    // Simple task to display
    task show;
        begin
            $display("t=%0t  a=%02h b=%02h op=%b | res=%02h zero=%b carry=%b overflow=%b",
                     $time, a, b, opcode, result, zero, carry, overflow);
        end
    endtask

    initial begin
        // --------------------------------------------------
        // VCD dump
        // --------------------------------------------------
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_safealu);

        // --------------------------------------------------
        // TEST 1: ADD normal
        // --------------------------------------------------
        a = 8'd10; b = 8'd20; opcode = 2'b00; #10; show();
        a = 8'd100; b = 8'd155; opcode = 2'b00; #10; show(); // check carry + overflow

        // --------------------------------------------------
        // TEST 2: SUB normal and edge
        // --------------------------------------------------
        a = 8'd50; b = 8'd20; opcode = 2'b01; #10; show();
        a = 8'd20; b = 8'd50; opcode = 2'b01; #10; show(); // borrow + negative

        // Edge for overflow
        a = 8'd127; b = 8'd129; opcode = 2'b01; #10; show(); // signed overflow

        // --------------------------------------------------
        // TEST 3: AND
        // --------------------------------------------------
        a = 8'b10101010; b = 8'b11001100; opcode = 2'b10; #10; show();

        // --------------------------------------------------
        // TEST 4: OR
        // --------------------------------------------------
        a = 8'b10101010; b = 8'b01010101; opcode = 2'b11; #10; show();

        // --------------------------------------------------
        // TEST 5: Zero flag check
        // --------------------------------------------------
        a = 8'd0; b = 8'd0; opcode = 2'b00; #10; show();
        a = 8'd0; b = 8'd0; opcode = 2'b01; #10; show();
        a = 8'd0; b = 8'd0; opcode = 2'b10; #10; show();
        a = 8'd0; b = 8'd0; opcode = 2'b11; #10; show();

        $display("===== SafeALU TEST COMPLETE =====");
        $finish;
    end

endmodule
