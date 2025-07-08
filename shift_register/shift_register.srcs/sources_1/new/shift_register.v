`timescale 1ns / 1ps

module sr7_pattern_detect (
    input  wire        clk,    // 시스템 클럭
    input  wire        rst,    // Active-Low 리셋
    input  wire        din,    // 1비트 직렬 입력
    output reg  [6:0]  sr,     // 내부 시프트 레지스터 값 출력
    output wire        dout    // 패턴 검출 플래그
);
    // 7비트 시프트 레지스터 갱신
    always @(posedge clk or negedge rst) begin
        if (!rst)
            sr <= 7'b0;
        else
            sr <= { sr[5:0], din };
    end
    // 즉시 검출
    assign dout = (sr == 7'b1010111) ? 1'b1 : 1'b0;
endmodule