`timescale 1ns / 1ps

module button_debouncer (
    input  wire clk,
    input  wire btn,
    output reg  debounced
);

    reg [15:0] cnt;
    reg btn_sync, btn_prev;

    always @(posedge clk) begin
        btn_sync <= btn;
        if (btn_sync == btn_prev)
            cnt <= cnt + 1;
        else
            cnt <= 0;

        if (cnt == 16'hFFFF)
            debounced <= btn_sync;

        btn_prev <= btn_sync;
    end

endmodule
