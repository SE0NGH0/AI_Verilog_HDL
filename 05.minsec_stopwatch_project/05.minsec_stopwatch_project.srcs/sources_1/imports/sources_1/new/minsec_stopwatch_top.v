`timescale 1ns / 1ps

module minsec_stopwatch_top(
    input clk,
    input reset,
    input [3:0] btn,
    output [3:0] an,
    output [7:0] seg,
    output [15:0] led
    );

    wire [13:0] w_seg_data;
    wire [3:0] w_o_clean_btn;
    wire [2:0] w_mode;

    btn_command_controller u_btn_command_controller(
        .clk(clk),
        .reset(reset),
        .btn(w_o_clean_btn), // btn[0] : L, btn[1] : C, btn[2] : R
        .seg_data(w_seg_data),
        .mode(w_mode),
        .led(led)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .mode(w_mode),
        .in_data(w_seg_data),
        .reset(reset),
        .an(an),
        .seg(seg)
    );

    none_dff_button u_none_dff_button(
        .i_clk(clk),
        .i_reset(reset),
        .i_noisy_btn(btn),
        .o_clean_btn(w_o_clean_btn)
    );

endmodule
