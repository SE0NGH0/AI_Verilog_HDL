`timescale 1ns / 1ps

module fnd_display (
    input wire clk,
    input wire [13:0] value,  // 0 ~ 9999
    output reg [6:0] seg,
    output reg [3:0] an
);
    reg [3:0] bcd0, bcd1, bcd2, bcd3;  // 각 자리수 (일, 십, 백, 천)
    reg [1:0] sel = 0;
    reg [19:0] clkdiv = 0;

    reg [13:0] binary;
    integer i;

    // 클럭 분주기 (FND 4자리 순환 표시용)
    always @(posedge clk) begin
        clkdiv <= clkdiv + 1;
        sel <= clkdiv[17:16];  // 약 1kHz ~ 2kHz
    end

    // BCD 변환 (Shift-Add-3 알고리즘)
    always @(*) begin
        binary = value;
        bcd0 = 0; bcd1 = 0; bcd2 = 0; bcd3 = 0;

        for (i = 13; i >= 0; i = i - 1) begin
            if (bcd3 >= 5) bcd3 = bcd3 + 3;
            if (bcd2 >= 5) bcd2 = bcd2 + 3;
            if (bcd1 >= 5) bcd1 = bcd1 + 3;
            if (bcd0 >= 5) bcd0 = bcd0 + 3;

            bcd3 = bcd3 << 1;
            bcd3[0] = bcd2[3];
            bcd2 = bcd2 << 1;
            bcd2[0] = bcd1[3];
            bcd1 = bcd1 << 1;
            bcd1[0] = bcd0[3];
            bcd0 = bcd0 << 1;
            bcd0[0] = binary[i];
        end
    end

    // 자리 선택 및 세그먼트 출력
    always @(*) begin
        case (sel)
            2'd0: begin an = 4'b1110; seg = seg_decode(bcd0); end // 일의 자리
            2'd1: begin an = 4'b1101; seg = seg_decode(bcd1); end // 십의 자리
            2'd2: begin an = 4'b1011; seg = seg_decode(bcd2); end // 백의 자리
            2'd3: begin an = 4'b0111; seg = seg_decode(bcd3); end // 천의 자리
        endcase
    end

    // 7세그먼트 디코딩 함수
    function [6:0] seg_decode;
        input [3:0] num;
        begin
            case (num)
                4'd0: seg_decode = 7'b1000000;
                4'd1: seg_decode = 7'b1111001;
                4'd2: seg_decode = 7'b0100100;
                4'd3: seg_decode = 7'b0110000;
                4'd4: seg_decode = 7'b0011001;
                4'd5: seg_decode = 7'b0010010;
                4'd6: seg_decode = 7'b0000010;
                4'd7: seg_decode = 7'b1111000;
                4'd8: seg_decode = 7'b0000000;
                4'd9: seg_decode = 7'b0010000;
                default: seg_decode = 7'b1111111;
            endcase
        end
    endfunction
endmodule
