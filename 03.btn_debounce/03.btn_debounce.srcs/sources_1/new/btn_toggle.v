`timescale 1ns / 1ps

module btn_toggle(
    input wire clk,
    input wire reset,
    input wire clean_btn,
    output reg led
    );

    reg prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev <= 1'b0;
            led <= 1'b0;
        end else begin
            prev <= clean_btn;
            if (clean_btn & ~prev)
                led <= ~led; 
        end
    end
endmodule
