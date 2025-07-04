`timescale 1ns / 1ps // 10.222

module gate_test(
    input wire a,
    input wire b, // 생략하면 wire 아무런 언급 안하면 1bit
    output [5:0] led
    // output led0,
    // output led1,
    // output led2,
    // output led3,
    // output led4,
    // output led5
    );

    assign led[0] = a & b; // and
    assign led[1] = a | b; // or
    assign led[2] = ~(a & b); // nand
    assign led[3] = ~(a | b); // nor
    assign led[4] = a ^ b; // xor
    assign led[5] = ~a; // not a

endmodule
