`timescale 1ns / 1ps

module button_buzzer(
    input clk,
    input reset,
    input btn,
    output reg buzzer
);

    parameter CNT_0_5S = 26'd30_000_000;  
    parameter HALF_1K  = 17'd50_000;      // 대략 1kHz 토글

    // 버튼 엣지 검출용
    reg btn_d1, btn_d2;
    wire btn_edge = btn_d1 & ~btn_d2;

    always @(posedge clk) begin
        btn_d1 <= btn;
        btn_d2 <= btn_d1;
    end

    // 내부 상태
    reg [25:0] r_buzzer_cnt = 0;  // 시간 측정용 카운터
    reg [16:0] r_wave_cnt = 0; // 부저 주파수 생성용 카운터
    reg run = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            run      <= 0;
            r_buzzer_cnt  <= 0;
            r_wave_cnt <= 0;
            buzzer   <= 0;
        end else begin
            if (btn_edge) begin
                run <= 1;          // 버튼 누르면 시작
                r_buzzer_cnt <= 0;
            end

            if (run) begin
                if (r_buzzer_cnt < CNT_0_5S) begin
                    r_buzzer_cnt <= r_buzzer_cnt + 1;

                    // 주파수 제어: 1kHz
                    if (r_wave_cnt >= HALF_1K) begin
                        r_wave_cnt <= 0;
                        buzzer <= ~buzzer;
                    end else begin
                        r_wave_cnt <= r_wave_cnt + 1;
                    end

                end else begin
                    // 0.5초 끝 --> 부저 OFF
                    run <= 0;
                    buzzer <= 0;
                    r_wave_cnt <= 0;
                end
            end else begin
                buzzer <= 0;
                r_wave_cnt <= 0;
            end
        end
    end

endmodule
