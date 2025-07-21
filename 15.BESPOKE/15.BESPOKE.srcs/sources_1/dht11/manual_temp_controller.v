`timescale 1ns / 1ps

module manual_temp_controller (
    input wire clk,
    input wire reset,
    input wire man_enable,             // sw[1] == 1일 때만 동작
    input wire btn_inc,            // btn[1]: 온도 증가
    input wire btn_dec,            // btn[2]: 온도 감소
    output reg [13:0] temp_manual,  // 현재 조절 중인 온도 (FND에 출력)
    output reg [13:0] temp_applied  // 최종 확정된 온도 (저장만 함)
);

    // 초기 설정값 (예: 26도)
    localparam INIT_TEMP = 14'd2700;
    localparam TEMP_MIN  = 14'd1000;
    localparam TEMP_MAX  = 14'd5000;
    
    reg prev_btn_inc = 0;
    reg prev_btn_dec = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            temp_manual  <= INIT_TEMP;
            temp_applied <= INIT_TEMP;
            prev_btn_inc <= 0;
            prev_btn_dec <= 0;
        end else if (man_enable) begin
            // 온도 증가
            if(btn_inc && !prev_btn_inc) begin 
                if (btn_inc && temp_manual < TEMP_MAX)
                    temp_manual <= temp_manual + 14'd100;
            end

            // 온도 감소
            if(btn_dec && !prev_btn_dec) begin 
                if (btn_dec && temp_manual > TEMP_MIN)
                    temp_manual <= temp_manual - 14'd100;
            end

            prev_btn_inc <= btn_inc;
            prev_btn_dec <= btn_dec;
            // 설정 확정
            // else if (btn_set)
            temp_applied <= temp_manual;  // 항상 샘플링
        end
    end

endmodule
