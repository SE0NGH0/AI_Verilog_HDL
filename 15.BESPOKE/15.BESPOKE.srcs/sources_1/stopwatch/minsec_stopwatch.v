`timescale 1ns / 1ps

module minsec_stopwatch(
    input clk,
    input reset,
    input sw_enable,
    input [3:0] btn, /* BTN[0] : R, BTN[1] : C, BTN[2] : U, BTN[3] : D */
    output buzzer_sw,
    output [3:0] an,
    output [7:0] seg
    );

    wire [13:0] w_seg_data;
    wire [2:0] w_mode;

    sw_controller u_sw_controller(
        .clk(clk),
        .reset(reset),
        .sw_enable(sw_enable),
        .btn(btn), /* BTN[0] : R, BTN[1] : C, BTN[2] : U, BTN[3] : D */
        .mode(w_mode),
        .seg_data(w_seg_data)
    );

    sw_fnd_controller u_sw_fnd_controller(
        .clk(clk),
        .mode(w_mode),
        .in_data(w_seg_data),
        .reset(reset),
        .sw_enable(sw_enable),
        .an(an),
        .seg(seg)
    );

    assign buzzer_sw = btn[0] | btn[1] | btn[2] | btn[3];

endmodule
