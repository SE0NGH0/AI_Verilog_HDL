`timescale 1ns / 1ps

module tb_adder();

    reg [3:0] r_a;
    reg [3:0] r_b;
    reg r_cin;
    wire [3:0] w_sum;
    wire w_carry_out;

    full_adder_4bit u_adder(
        .a(r_a), .b(r_b),
        .cin(r_cin),
        .sum(w_sum),
        .carry_out(w_carry_out)
    );

    initial begin
        
        r_a = 4'b0000; r_b = 4'b0000; r_cin = 0; #10;  // 0 + 0 + 0 = 0
        r_a = 4'b0001; r_b = 4'b0001; r_cin = 0; #10;  // 1 + 1 = 2
        r_a = 4'b0010; r_b = 4'b0100; r_cin = 1; #10;  // 2 + 4 + 1 = 7
        r_a = 4'b0111; r_b = 4'b0001; r_cin = 1; #10;  // 7 + 1 + 1 = 9
        r_a = 4'b1111; r_b = 4'b0001; r_cin = 0; #10;  // 15 + 1 = 16 (carry out = 1)
        r_a = 4'b1010; r_b = 4'b0101; r_cin = 1; #10;  // 10 + 5 + 1 = 16
        r_a = 4'b1100; r_b = 4'b0011; r_cin = 0; #10;  // 12 + 3 = 15
        r_a = 4'b1111; r_b = 4'b1111; r_cin = 1; #10;  // 15 + 15 + 1 = 31
        
        $finish;
    end

endmodule
