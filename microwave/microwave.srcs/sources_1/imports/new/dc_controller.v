`timescale 1ns / 1ps

module dc_controller(
    input clk,
    input reset,
    input enable,               // 타이머 작동 중이면 1, 아니면 0
    input [3:0] DUTY_SET,       // 외부에서 듀티 입력 (예: 4'd10 = 100%)
    output [3:0] DUTY_CYCLE, 
    output PWM_OUT,
    output PWM_OUT_LED
);

    reg [3:0] r_counter_PWM = 0;
    reg [3:0] r_DUTY_CYCLE = 0;

    always @(posedge clk) begin
        if (reset) begin
            r_DUTY_CYCLE <= 0;
            r_counter_PWM <= 0;
        end else begin
            // enable에 따라 듀티 설정
            if (enable)
                r_DUTY_CYCLE <= DUTY_SET;
            else
                r_DUTY_CYCLE <= 0;

            // PWM 카운터
            if (r_counter_PWM >= 9)
                r_counter_PWM <= 0;
            else
                r_counter_PWM <= r_counter_PWM + 1;
        end
    end

    assign PWM_OUT = (r_counter_PWM < r_DUTY_CYCLE) ? 1 : 0;
    assign PWM_OUT_LED = PWM_OUT;
    assign DUTY_CYCLE = r_DUTY_CYCLE;

endmodule
