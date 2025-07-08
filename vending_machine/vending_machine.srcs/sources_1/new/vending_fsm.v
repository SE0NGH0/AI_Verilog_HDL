`timescale 1ns / 1ps

module vending_fsm (
    input  wire clk,
    input  wire rst,
    input  wire in100,
    input  wire in500,
    input  wire buy,
    input  wire refund,
    output reg [15:0] balance  // 9900 이상 표현 위해 14비트
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            balance <= 0;
        end else begin
            // 9900원 이하일 때만 100원 추가
            if (in100 && balance <= 9800)
                balance <= balance + 100;

            // 9900원 이하일 때만 500원 추가
            else if (in500 && balance <= 9400)
                balance <= balance + 500;

            // 커피 구매 가능시 차감
            if (buy && balance >= 300)
                balance <= balance - 300;

            // 반환
            if (refund)
                balance <= 0;
        end
    end
endmodule
