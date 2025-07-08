`timescale 1ns / 1ps

module fnd_controller (
    input wire clk,
    input wire rst,
    input wire [13:0] in_data,
    input wire [2:0] mode,  // 000: IDLE (애니메이션), 100: 숫자 모드
    output reg [3:0] an,
    output reg [7:0] seg
);
    // 내부 변수
    reg [3:0] bcd0, bcd1, bcd2, bcd3;
    reg [1:0] digit_sel = 0;
    reg [19:0] clkdiv = 0;
    reg [3:0] circle_state = 0;
    reg [26:0] anim_cnt = 0;
    wire anim_tick = (anim_cnt == 27'd25_000_000);  // 약 0.5초

    // 클럭 분주 및 자리 선택
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clkdiv <= 0;
            digit_sel <= 0;
            anim_cnt <= 0;
            circle_state <= 0;
        end else begin
            clkdiv <= clkdiv + 1;
            digit_sel <= clkdiv[17:16];

            if (mode == 3'b000) begin
                if (anim_cnt >= 27'd25_000_000)
                    anim_cnt <= 0;
                else
                    anim_cnt <= anim_cnt + 1;

                if (anim_tick) begin
                    if (circle_state == 11)
                        circle_state <= 0;
                    else
                        circle_state <= circle_state + 1;
                end
            end else begin
                anim_cnt <= 0;
                circle_state <= 0;
            end
        end
    end

    // BCD 변환
    integer i;
    reg [13:0] binary;
    always @(*) begin
        binary = in_data;
        bcd0 = 0; bcd1 = 0; bcd2 = 0; bcd3 = 0;

        for (i = 13; i >= 0; i = i - 1) begin
            if (bcd3 >= 5) bcd3 = bcd3 + 3;
            if (bcd2 >= 5) bcd2 = bcd2 + 3;
            if (bcd1 >= 5) bcd1 = bcd1 + 3;
            if (bcd0 >= 5) bcd0 = bcd0 + 3;

            bcd3 = bcd3 << 1; bcd3[0] = bcd2[3];
            bcd2 = bcd2 << 1; bcd2[0] = bcd1[3];
            bcd1 = bcd1 << 1; bcd1[0] = bcd0[3];
            bcd0 = bcd0 << 1; bcd0[0] = binary[i];
        end
    end

    // 출력 선택
    always @(*) begin
        if (mode == 3'b000) begin
            // 시계방향 애니메이션 모드
            case (circle_state)
                4'd0:  begin an = 4'b0111; seg = 8'b11111110; end // AN3 A
                4'd1:  begin an = 4'b1011; seg = 8'b11111110; end // AN2 A
                4'd2:  begin an = 4'b1101; seg = 8'b11111110; end // AN1 A
                4'd3:  begin an = 4'b1110; seg = 8'b11111110; end // AN0 A
                4'd4:  begin an = 4'b1110; seg = 8'b11111101; end // AN0 B
                4'd5:  begin an = 4'b1110; seg = 8'b11111011; end // AN0 C
                4'd6:  begin an = 4'b1110; seg = 8'b11110111; end // AN0 D
                4'd7:  begin an = 4'b1101; seg = 8'b11110111; end // AN1 D
                4'd8:  begin an = 4'b1011; seg = 8'b11110111; end // AN2 D
                4'd9:  begin an = 4'b0111; seg = 8'b11110111; end // AN3 D
                4'd10: begin an = 4'b0111; seg = 8'b11101111; end // AN3 E
                4'd11: begin an = 4'b0111; seg = 8'b11011111; end // AN3 F
                default: begin an = 4'b1111; seg = 8'b11111111; end
            endcase
        end else begin
            // 숫자 출력 모드
            case (digit_sel)
                2'd0: begin an = 4'b1110; seg = seg_decode(bcd0); end
                2'd1: begin an = 4'b1101; seg = seg_decode(bcd1); end
                2'd2: begin an = 4'b1011; seg = seg_decode(bcd2); end
                2'd3: begin an = 4'b0111; seg = seg_decode(bcd3); end
                default: begin an = 4'b1111; seg = 8'b11111111; end
            endcase
        end
    end

    // BCD → 7-Segment 디코더
    function [7:0] seg_decode;
        input [3:0] num;
        begin
            case (num)
                4'd0: seg_decode = 8'b11000000;
                4'd1: seg_decode = 8'b11111001;
                4'd2: seg_decode = 8'b10100100;
                4'd3: seg_decode = 8'b10110000;
                4'd4: seg_decode = 8'b10011001;
                4'd5: seg_decode = 8'b10010010;
                4'd6: seg_decode = 8'b10000010;
                4'd7: seg_decode = 8'b11111000;
                4'd8: seg_decode = 8'b10000000;
                4'd9: seg_decode = 8'b10010000;
                default: seg_decode = 8'b11111111;
            endcase
        end
    endfunction

endmodule
