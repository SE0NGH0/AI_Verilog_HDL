`timescale 1ns / 1ps

module top(
    input           clk,
    input           reset,  // btnU
    input   [2:0]   btn,
    input   [7:0]   sw,
    input           RsRx,
    output          RsTx,
    output  [7:0]   seg,
    output  [3:0]   an,
    output  [15:0]  led
    );

    wire [2:0]  w_btn_debounce;
    wire [13:0] w_seg_data;
    wire        w_tick;
    wire [7:0]  w_rx_data;
    wire        w_rx_done;

    button_debounce u_button_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[0]),
        .o_btn_clean(w_btn_debounce)
    );

    tick_generator u_tick_generator(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    command_controller u_command_controller (
        .clk(clk),
        .reset(reset),  // btnU
        .btn(w_btn_debounce), // btn[0]: L btn[1]:C btn[2]:R
        .sw(sw),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .seg_data(w_seg_data),
        .led(led)
    );

    fnd_controller u_fnd_controller (
        .clk(clk),
        .reset(reset),
        .input_data(w_seg_data),
        .seg_data(seg),
        .an(an)    
    );

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .send_data(w_seg_data),
        .rx(RsRx),
        .tx(RsTx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    assign led[7:0] = w_rx_data;

endmodule
