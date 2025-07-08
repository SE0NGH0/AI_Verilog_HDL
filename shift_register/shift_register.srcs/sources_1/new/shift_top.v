`timescale 1ns / 1ps

module shift_top (
    input  wire       clk,      // 100 MHz 클럭
    input  wire       reset,    // Active-High 리셋
    input  wire       btnU,     // ‘1’ 입력 버튼 (Active-High)
    input  wire       btnD,     // ‘0’ 입력 버튼 (Active-High)
    output reg  [7:0] led       // [7]=패턴 플래그, [6:0]=시프트 레지스터
);

    //--------------------------------------------------------------------------
    // 1) 버튼 동기화 & 원샷 펄스 생성
    //--------------------------------------------------------------------------
    reg btnU_d, btnD_d;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            btnU_d <= 1'b0;
            btnD_d <= 1'b0;
        end else begin
            btnU_d <= btnU;
            btnD_d <= btnD;
        end
    end

    // 눌림 에지(0→1)에서 한 사이클만 1이 되는 펄스
    wire pulse1 = btnU & ~btnU_d;
    wire pulse0 = btnD & ~btnD_d;

    //--------------------------------------------------------------------------
    // 2) din 생성: pulse1→‘1’, pulse0→‘0’
    //--------------------------------------------------------------------------
    reg din;
    always @(posedge clk or posedge reset) begin
        if (reset)
            din <= 1'b0;
        else if (pulse1)
            din <= 1'b1;
        else if (pulse0)
            din <= 1'b0;
        // else din 유지
    end

    //--------------------------------------------------------------------------
    // 3) 7비트 Shift Register: pulse1 또는 pulse0일 때만 시프트
    //--------------------------------------------------------------------------
    reg [6:0] shift_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            shift_reg <= 7'b0;
        else if (pulse1)
            shift_reg <= { shift_reg[5:0], 1'b1 };
        else if (pulse0)
            shift_reg <= { shift_reg[5:0], 1'b0 };
        // else shift_reg 유지
    end

    //--------------------------------------------------------------------------
    // 4) 패턴 검출: shift_reg == 7'b1010111
    //--------------------------------------------------------------------------
    wire pattern_hit = (shift_reg == 7'b1010111) ? 1'b1 : 1'b0;

    //--------------------------------------------------------------------------
    // 5) LED 갱신
    //--------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            led <= 8'b0;
        else
            led <= { pattern_hit, shift_reg };
    end

endmodule
