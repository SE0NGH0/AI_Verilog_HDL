`timescale 1ns / 1ps

module servo_controller(
    input clk,        // 100MHz clock
    input reset,
    input door_state, // door OPEN : 1, door CLOSE : 0
    output reg servo_pwm
);

    // SG90: 20ms 주기 -> 100MHz 기준 2,000,000 클럭
    parameter PERIOD = 32'd2_000_000;  // 20ms

    // Pulse Width 계산 (1ms ~ 2ms -> 100,000 ~ 200,000 클럭)
    parameter MIN_PULSE = 32'd100_000;  // 1ms
    parameter MAX_PULSE = 32'd200_000;  // 2ms

    reg [31:0] r_servo_cnt = 0;
    reg [31:0] r_pulse_width = 0;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_servo_cnt <= 0;
            servo_pwm <= 0;
            r_pulse_width <= MIN_PULSE; // 초기값: 닫힘 위치 (0도)
        end else begin
            // door state : 문열림 90도, 닫힘 0도(초기값)            
            if (door_state == 1'b1)  // 문 열림 -> 90도 (1.5ms)
                r_pulse_width <= MIN_PULSE + ((MAX_PULSE - MIN_PULSE) * 150) / 180;
            else                     // 문 닫힘 -> 0도 (1ms)
                r_pulse_width <= MIN_PULSE;

            // PWM 생성
            if (r_servo_cnt < r_pulse_width)
                servo_pwm <= 1;
            else
                servo_pwm <= 0;

            if (r_servo_cnt < PERIOD - 1)
                r_servo_cnt <= r_servo_cnt + 1;
            else
                r_servo_cnt <= 0;
        end
    end

endmodule

