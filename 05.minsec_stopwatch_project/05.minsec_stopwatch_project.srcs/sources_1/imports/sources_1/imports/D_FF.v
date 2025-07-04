`timescale 1ns / 1ps

module D_FF(
    input i_clk,
    input D,
    input reset,
    output reg Q,
    output reg Qbar
    );

    always @ (posedge i_clk or posedge reset) begin // 8Hz
        if(reset) begin
            Q <= 1'b0;
            Qbar <= 1'b0;
        end else begin
            Q <= D;
            Qbar <= ~Q;
        end
    end

endmodule
