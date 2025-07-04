`timescale 1ns / 1ps
module full_adder_4bit(
    input cin,
    input [3:0] a,
    input [3:0] b,
    output carry_out,
    output [3:0] sum
);
    wire w_carry_out0;
    wire w_carry_out1;
    wire w_carry_out2;

    full_adder fa0(
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .carry_out(w_carry_out0),
        .sum(sum[0])
    );
    
    full_adder fa1(
        .a(a[1]),
        .b(b[1]),
        .cin(w_carry_out0),
        .carry_out(w_carry_out1),
        .sum(sum[1])
    );

    full_adder fa2(
        .a(a[2]),
        .b(b[2]),
        .cin(w_carry_out1),
        .carry_out(w_carry_out2),
        .sum(sum[2])
    );

    full_adder fa3(
        .a(a[3]),
        .b(b[3]),
        .cin(w_carry_out2),
        .carry_out(carry_out),
        .sum(sum[3])
    );        

endmodule



module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output carry_out
);

    wire w_sum1;
    wire w_carry_out1;
    wire w_carry_out2;

    adder u_half_ad1 (
        .a(a),
        .b(b),
        .sum(w_sum1),
        .carry_out(w_carry_out1)
    ); 

    adder u_half_ad2 (
        .a(w_sum1),
        .b(cin),
        .sum(sum),
        .carry_out(w_carry_out2)
    );

    assign carry_out = w_carry_out1 | w_carry_out2;

endmodule

module adder(
    input a, b,
    output sum, carry_out
    );

    assign sum = a ^ b;
    assign carry_out = a & b;
endmodule

