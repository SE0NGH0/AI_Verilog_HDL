`timescale 1ns / 1ps

module fnd_controller(
    input clk,
    input [13:0] input_data,
    input [2:0] mode,
    input reset,
    output [3:0] an, // 자릿수 선택
    output [7:0] seg_data
    );

    localparam MINSEC_WATCH = 3'b001;

    wire [1:0] w_sel;

    fnd_digit_select u_fnd_digit_select(
        .clk(clk),
        .reset(reset),
        .sel(w_sel) // 00 01 10 11
    );

    // 일반 BCD 변환 (0~9999)
    wire [3:0] w_d1, w_d10, w_d100, w_d1000;
    bin2bcd u_bin2bcd(
        .in_data(input_data),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000)
    );

    // 분·초 전용 BCD 변환
    wire [3:0] w_d_s1, w_d_s10, w_d_m1, w_d_m10;
    bin2bcd_minsec u_bin2bcd_minsec(
        .in_data(input_data),
        .d_s1(w_d_s1),
        .d_s10(w_d_s10),
        .d_m1(w_d_m1),
        .d_m10(w_d_m10)
    );

    // 모드에 따라 분·초 또는 일반 숫자 선택
    wire [3:0] d1_sel   = (mode == MINSEC_WATCH) ? w_d_m1   : w_d1;
    wire [3:0] d10_sel  = (mode == MINSEC_WATCH) ? w_d_m10  : w_d10;
    wire [3:0] d100_sel = (mode == MINSEC_WATCH) ? w_d_s1   : w_d100;
    wire [3:0] d1000_sel= (mode == MINSEC_WATCH) ? w_d_s10  : w_d1000;

    fnd_display u_fnd_display(
        .digit_sel(w_sel),
        .d1(d1_sel),
        .d10(d10_sel),
        .d100(d100_sel),
        .d1000(d1000_sel),
        .an(an),
        .seg(seg_data)
    );
endmodule


// 1ms마다 fnd를 display하기 위해 digit 1자리씩 선택
// 4ms까지는 잔상효과가 있다 그 이상이면 깜빡임 현상이 발생
module fnd_digit_select(
    input clk,
    input reset,
    output reg [1:0] sel // 00 01 10 11
    );

    reg [16:0] r_1ms_counter = 0;
    reg [1:0] r_digit_sel = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_1ms_counter <= 0;
            r_digit_sel <= 0;
            sel <= 0;
        end else begin
            if (r_1ms_counter == 100_000-1) begin // 1ms
                r_1ms_counter <= 0;
                r_digit_sel <= r_digit_sel + 1;
                sel <= r_digit_sel;
            end else begin
                r_1ms_counter <= r_1ms_counter + 1;
            end
        end
    end
    
endmodule

// bin2bcd
// 입력 : bin 14bit인 이유 최대 9999까지 표현 값이 들어있기 때문
// 0 ~ 9999 
// 출력 : bcd
// 일반 bin→BCD 변환 (0~9999)
module bin2bcd (
    input  [13:0] in_data,
    output [3:0]  d1,
    output [3:0]  d10,
    output [3:0]  d100,
    output [3:0]  d1000
);
    assign d1    = in_data % 10;
    assign d10   = (in_data / 10)   % 10;
    assign d100  = (in_data / 100)  % 10;
    assign d1000 = (in_data / 1000) % 10;
endmodule

// 분·초 전용 bin→BCD 변환
module bin2bcd_minsec (
    input  [13:0] in_data,
    output [3:0]  d_s1,
    output [3:0]  d_s10,
    output [3:0]  d_m1,
    output [3:0]  d_m10
);
    wire [7:0] minutes = in_data / 60;
    wire [7:0] seconds = in_data % 60;
    assign d_s1  = seconds % 10;
    assign d_s10 = seconds / 10;
    assign d_m1  = minutes % 10;
    assign d_m10 = minutes / 10;
endmodule

module fnd_display (
    input [1:0] digit_sel,
    input  [3:0] d1,
    input  [3:0] d10,
    input  [3:0] d100,
    input  [3:0] d1000,
    output reg [3:0] an,
    output reg [7:0] seg
    );

    reg [3:0] bcd;
    always @(*) begin
        case (digit_sel)
            2'b00: begin bcd = d1;    an = 4'b1110; end
            2'b01: begin bcd = d10;   an = 4'b1101; end
            2'b10: begin bcd = d100;  an = 4'b1011; end
            2'b11: begin bcd = d1000; an = 4'b0111; end
            default: begin bcd = 0;   an = 4'b1111; end
        endcase
    end

    always @(*) begin
        case (bcd)
            4'd0: seg <= 8'hC0; // 8'b11000000 : 0
            4'd1: seg <= 8'hF9; // 8'b11111001 : 1
            4'd2: seg <= 8'hA4; // 8'b10100100 : 2
            4'd3: seg <= 8'hB0; // 8'b10110000 : 3
            4'd4: seg <= 8'h99; // 8'b10011001 : 4
            4'd5: seg <= 8'h92; // 8'b10010010 : 5
            4'd6: seg <= 8'h82; // 8'b10000010 : 6
            4'd7: seg <= 8'hF8; // 8'b11111000 : 7
            4'd8: seg <= 8'h80; // 8'b10000000 : 8
            4'd9: seg <= 8'h90; // 8'b10010000 : 9
            default: seg = 8'hFF; // 8'b11111111 : all off
        endcase
    end
    
endmodule