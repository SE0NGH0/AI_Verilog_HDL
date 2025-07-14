`timescale 1ns / 1ps

module top_module (
    input clk,
    input reset,
    input sw,            // Mode select
    input btn_U,
    input btn_D,
    input btn_L,
    input btn_R,
    input btn_run,
    input [1:0] motor_direction,  // sw14 sw15 : motor direction
    output [1:0] in1_in2,         // motor direction switch
    output [6:0] seg_data,
    output [3:0] an,
    output buzzer,
    output PWM_OUT,
    output pwm_led_check,
    output servo_out
);

    // 버튼 펄스 신호
    wire pulse_U, pulse_D, pulse_L, pulse_R, pulse_run;

    // 타이머 정보
    wire [13:0] timer_value;
    wire timer_running;

    // 버튼 컨트롤러
    btn_controller u_btn (
        .clk(clk), .reset(reset),
        .btn_U(btn_U), .btn_D(btn_D),
        .btn_L(btn_L), .btn_R(btn_R),
        .btn_run(btn_run),
        .pulse_U(pulse_U), .pulse_D(pulse_D),
        .pulse_L(pulse_L), .pulse_R(pulse_R),
        .pulse_run(pulse_run)
    );

    // FND 제어
    fnd_controller u_fnd (
        .clk(clk), .reset(reset),
        .sw(sw),
        .pulse_U(pulse_U), .pulse_D(pulse_D),
        .pulse_run(pulse_run),
        .sw_time(timer_value),
        .sw_state(timer_running),
        .seg_data(seg_data), .an(an)
    );

    // 부저 제어
    buzzer_controller u_buzzer (
        .clk(clk), .reset(reset),
        .sw(sw),
        .pulse_U(pulse_U), .pulse_D(pulse_D),
        .pulse_L(pulse_L), .pulse_R(pulse_R),
        .pulse_run(pulse_run),
        .sw_state(timer_running),
        .sw_time(timer_value),
        .buzzer(buzzer)
    );

    // 서보모터: 문 열림/닫힘 수동 제어
    reg [17:0] target_pulse_width;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            target_pulse_width <= 18'd150000; // 중립 (1.5ms)
        end else begin
            if (pulse_L)
                target_pulse_width <= 18'd200000; // 열기 (2.0ms)
            else if (pulse_R)
                target_pulse_width <= 18'd100000; // 닫기 (1.0ms)
        end
    end

    servo_motor_controller u_servo (
        .clk(clk),
        .rst(reset),
        .target_pulse_width(target_pulse_width),
        .servo_out(servo_out)
    );

    // DC 모터: 타이머가 실행 중일 때 자동 회전, 종료 시 자동 정지
    wire [3:0] w_DUTY_CYCLE;
    assign w_DUTY_CYCLE = 4'd10; // 기본 듀티 설정 (10%)

dc_controller u_dc (
    .clk(clk),
    .reset(reset),
    .enable(timer_running),        // ✅ 이제 단순 enable 신호
    .DUTY_SET(4'd10),              // ✅ 10/10 = 100% duty 예시
    .DUTY_CYCLE(w_DUTY_CYCLE),
    .PWM_OUT(PWM_OUT),
    .PWM_OUT_LED(pwm_led_check)
);


    // 방향 스위치 그대로 전달
    assign in1_in2 = motor_direction;

endmodule
