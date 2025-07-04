`timescale 1ns / 1ps

module button_debounce(
    input i_clk,
    input i_reset,
    input i_btn,
    output o_led
    );

    wire w_out_clk;
    
    clock_8Hz u_clock_8Hz(
    .i_clk(i_clk), // 100MHz
    .i_reset(i_reset),
    .o_clk8Hz(w_out_clk) // 8Hz
    );

    wire w_Q1;

    D_FF u1_D_FF(
    .i_clk(w_out_clk),
    .i_reset(i_reset),
    .D(i_btn),
    .Q(w_Q1)
    );

    wire w_Q2;

    D_FF u2_D_FF(
    .i_clk(w_out_clk),
    .i_reset(i_reset),
    .D(w_Q1),
    .Q(w_Q2)
    );

    assign o_led = w_Q1 & ~w_Q2;

endmodule