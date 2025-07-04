`timescale 1ns / 1ps

module button_debounce(
    input i_clk,
    input i_reset,
    input i_btnC,
    output o_led
    );

    wire w_out_clk;
    wire w_Q1;
    wire w_Q2;

    clock_8Hz u_clock_8Hz(
        .i_clk(i_clk),    // 100MHz
        .i_reset(i_reset),
        .o_clk_8Hz(w_out_clk)    // 8Hz
    );

    D_FF u1_DFF(
    .i_clk(w_out_clk),
    .D(i_btnC),
    .reset(i_reset),
    .Q(w_Q1)
    );

    D_FF u2_DFF(
    .i_clk(w_out_clk),
    .D(w_Q1),
    .reset(i_reset),
    .Q(w_Q2)
    );

    assign o_led = w_Q1 & ~w_Q2;
    
endmodule
