`timescale 1ns / 1ps

module pwm_dcmotor (
    input wire clk,                  
    input wire [7:0] temperature,    
    input wire enable,               // <== 모터 동작 제어
    output wire PWM_OUT,            
    output wire [1:0] in1_in2       
);

    wire [3:0] duty_cycle;

    // 온도에 따라 duty cycle 결정
    assign duty_cycle = (temperature < 8'd26) ? 4'd4 :
                        (temperature == 8'd26) ? 4'd6 :
                        4'd9;

    pwm_duty_cycle_control u_pwm_duty_control (
        .clk(clk),
        .duty_cycle(enable ? duty_cycle : 4'd0), // <= enable이 0이면 0% 출력
        .PWM_OUT(PWM_OUT)
    );

    assign in1_in2 = (enable) ? 2'b10 : 2'b00;  // enable==0일 때 정지

endmodule
