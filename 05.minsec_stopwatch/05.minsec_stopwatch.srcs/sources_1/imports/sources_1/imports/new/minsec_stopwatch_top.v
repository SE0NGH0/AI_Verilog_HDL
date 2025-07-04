`timescale 1ns / 1ps

module minsec_stopwatch_top(
    input clk,
    input reset, // btnU
    input [2:0] btn,
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led
    );

    wire [2:0] w_btn_debounce;

    button_debouncer u_button_debouncer (
        .clk(clk),
        .reset(reset),
        .noisy_btn(btn),
        .clean_btn(w_btn_debounce)
    );

    wire [13:0] w_seg_data;
    wire [2:0]  w_mode;

    btn_command_controller u_btn_command_controller(
        .clk(clk),
        .reset(reset), // btnU
        .btn(w_btn_debounce), // btn[0] : L btn[1] : C btn[2] : R
        .seg_data(w_seg_data),
        .mode(w_mode),
        .led(led)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .input_data(w_seg_data),
        .reset(reset),
        .mode(w_mode),
        .an(an),
        .seg_data(seg)
    );

endmodule
