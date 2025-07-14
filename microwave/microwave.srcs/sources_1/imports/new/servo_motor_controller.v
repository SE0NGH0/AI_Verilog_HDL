`timescale 1ns / 1ps
module servo_motor_controller (
    input clk,                      // 100MHz 시스템 클럭
    input rst,                      // 리셋
    input [20:0] target_pulse_width, // High 유지할 펄스 폭 (100MHz 기준 사이클 수)
    output reg servo_out            // 서보 출력 (PWM)
);

    parameter PWM_PERIOD_CYCLES = 21'd2_000_000; // 20ms = 2,000,000 클럭 @ 100MHz

    reg [20:0] pwm_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_counter <= 0;
            servo_out <= 0;
        end else begin
            
            if (pwm_counter >= PWM_PERIOD_CYCLES - 1) begin
                pwm_counter <= 0;
                servo_out <= 1;  
            end else begin
                pwm_counter <= pwm_counter + 1;

                
                if (pwm_counter == target_pulse_width - 1)
                    servo_out <= 0;
            end
        end
    end

endmodule
