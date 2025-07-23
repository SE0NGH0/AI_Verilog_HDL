`timescale 1ns / 1ps

module top(
    input clk,
    input reset,  // btnU
    input RsRx,
    output [15:0] led
);

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .rx(RsRx),
        .led(led)
    );

    
endmodule
