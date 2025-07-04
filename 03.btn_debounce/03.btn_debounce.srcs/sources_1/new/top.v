`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input btnC,
    output [1:0] led
    );

    wire w_btn_debounce;
    reg r_led_toggle = 1'b0;
    reg r_led_500mstoggle = 1'b0;
    reg [$clog2(500)-1:0] r_ms_count = 0;
    reg [$clog2(100)-1:0] r_100ms_count = 0;
    reg r_led_100mstoggle = 1'b0;

    button_debounce u_button_debounce(
    .i_clk(clk),
    .i_reset(reset),
    .i_btn(btnC),
    .o_led(w_btn_debounce)
    );

    wire w_tick;

    tick_generator u_tick_generator(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    // always @(posedge w_btn_debounce or posedge reset) begin
    //     if (reset) begin
    //         r_ms_count <= 0;
    //     end else begin
    //         r_led_toggle <= ~r_led_toggle;
    //     end
    // end

    always @(posedge w_tick or posedge reset) begin
        
        if (reset) begin
            r_ms_count <= 0;
            r_100ms_count <= 0;
            r_led_500mstoggle <= 0;
            r_led_100mstoggle <= 0;
        end else begin
            if (r_ms_count == 500-1) begin // 500ms
                r_ms_count <= 0;
                r_led_500mstoggle <= ~r_led_500mstoggle;
            end else begin
                r_ms_count <= r_ms_count + 1;   
            end 
            
            if (r_100ms_count == 100-1) begin // 100ms
                r_100ms_count <= 0;
                r_led_100mstoggle <= ~r_led_100mstoggle;
            end else begin
                r_100ms_count <= r_100ms_count + 1;       
            end
        end
        r_led_toggle <= ~r_led_toggle;
    end

    assign led[1] = r_led_100mstoggle;
    assign led[0] = r_led_500mstoggle;

endmodule
