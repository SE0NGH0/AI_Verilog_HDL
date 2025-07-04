`timescale 1ns / 1ps

module D_FF(
    input i_clk,
    input i_reset,
    input D,
    output reg Q,
    output reg Qbar
    );

    always @(posedge i_clk) begin // 8Hz
        if (i_reset) begin
            Q <= 1'b0;
            Qbar <= 1'b0;
        end else begin
            Q <= D;
            Qbar <= ~Q;
        end
    end
endmodule
