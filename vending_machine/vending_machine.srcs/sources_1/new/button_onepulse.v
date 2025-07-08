`timescale 1ns / 1ps

module button_onepulse (
    input wire clk,
    input wire btn,
    output reg out
);
    reg btn_sync_0, btn_sync_1, btn_prev;

    always @(posedge clk) begin
        btn_sync_0 <= btn;
        btn_sync_1 <= btn_sync_0;
        btn_prev   <= btn_sync_1;
        out        <= (btn_sync_1 && ~btn_prev);
    end
endmodule
