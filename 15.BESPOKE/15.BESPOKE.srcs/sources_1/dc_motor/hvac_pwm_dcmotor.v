`timescale 1ns / 1ps

module hvac_pwm_dcmotor (
    input wire clk,
    input wire enable,
    input wire [13:0] measured_temp,   // DHT11 온도 값 (w_dht11_temp / 100)
    input wire [13:0] target_temp,     // 수동 설정 온도 값 (temp_applied)
    input wire manual_mode,           //  (1: 수동 / 0: 자동)
    output wire PWM_OUT,
    output reg [1:0] in1_in2
);

    localparam AUTO_TARGET = 14'd2700;

    reg [9:0] duty_cycle;
    reg [9:0] pwm_counter = 0;

    // 방향: 항상 정회전
    always @(posedge clk) begin
        in1_in2 <= 2'b01;
    end

    // 온도 비교에 따라 duty cycle 결정
    always @(posedge clk) begin
        if (!enable) begin
            duty_cycle <= 0;
        end else if (manual_mode) begin
            // 수동모드: target_temp와 비교
            if (measured_temp > target_temp) begin
                duty_cycle <= 10'd900;  // 강하게
            end
            else begin // if (measured_temp > target_temp) begin
                duty_cycle <= 10'd500;  // 약하게
            end
        end else begin
            // 자동모드: 현재 온도 기준
            if (measured_temp < AUTO_TARGET)
                duty_cycle <= 10'd500;  // 약하게
            else if (measured_temp > AUTO_TARGET)
                duty_cycle <= 10'd900;  // 강하게
        end
    end

    // PWM 생성
    reg pwm_out_reg;
    always @(posedge clk) begin
        if (pwm_counter >= 10'd999)
            pwm_counter <= 10'd0;
        else
            pwm_counter <= pwm_counter + 1;

        pwm_out_reg <= (pwm_counter < duty_cycle);
    end

    assign PWM_OUT = pwm_out_reg;

endmodule
