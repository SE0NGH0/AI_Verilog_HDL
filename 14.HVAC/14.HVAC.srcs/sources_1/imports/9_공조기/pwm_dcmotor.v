`timescale 1ns / 1ps

module pwm_dcmotor (
    input wire clk,                  // 100MHz 클럭
    input wire [7:0] temperature,    // 온도 값 (0~255 범위)
    output wire PWM_OUT,            // PWM 출력
    output wire [1:0] in1_in2       // 모터 정방향 출력
);

    wire [3:0] duty_cycle;

    // 온도에 따라 duty cycle 결정 (정방향 회전 기준)
    assign duty_cycle = (temperature < 8'd26) ? 4'd4 :
                        (temperature == 8'd26) ? 4'd6 :
                        4'd9;
    // 2: 약하게 (20%), 9: 강하게 (90%)

    pwm_duty_cycle_control u_pwm_duty_control (
        .clk(clk),
        .duty_cycle(duty_cycle),
        .PWM_OUT(PWM_OUT)
    );

    // 모터 정방향 회전 고정
    assign in1_in2 = 2'b10;

endmodule
