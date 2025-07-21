`timescale 1ns / 1ps

//----------------- pwm_duty_cycle_control ---------------------
module pwm_duty_cycle_control (
    input clk,
    input [1:0] state,
    // input duty_inc,
    // input duty_dec,
    output [3:0] DUTY_CYCLE,
    output PWM_OUT       // 10MHz PWM output signal 
    // output PWM_OUT_LED
    ); 

    reg[3:0] r_DUTY_CYCLE=1;     // initial duty cycle is 50%
    reg[3:0] r_counter_PWM=0;    // counter for creating 10Mhz PWM signal

    parameter IDLE   = 2'b00; // IDLE 모드에서는 문 열고 닫음, TIME 으로 천이 가능
    parameter TIME   = 2'b01; // TIME 모드에서는 문 열고 닫음, 시간제어, 그리고 동작 중으로 천이 가능
    parameter RUN    = 2'b10; // RUN 에서는 동작시간이 모두 지나면 동작 종료로 천이, 취소버튼 누르면 TIME 으로 천이
    parameter STOP   = 2'b11; // STOP 에서는 FND, BUZZER를 출력하고 IDLE로 천이

//  always @(posedge clk)
//  begin
//    if (duty_inc==1 && r_DUTY_CYCLE <= 9) 
//       r_DUTY_CYCLE <= r_DUTY_CYCLE + 1; // increase duty cycle by 10%
//    else if(duty_dec==1 && r_DUTY_CYCLE >= 1) 
//       r_DUTY_CYCLE <= r_DUTY_CYCLE - 1; //decrease duty cycle by 10%
//  end 

// Create 10MHz PWM signal with variable duty cycle controlled by 2 buttons 
// DC로 10MHz PWM 신호를 보내도록 한다.
// default r_DUTY_CYCLE은 50%로 설정 r_counter_PWM는 10ns(1/100MHz) 마다 10%씩 증가
always @(posedge clk)
begin
    if(state==RUN) begin   
        r_counter_PWM <= r_counter_PWM + 1;
        if (r_counter_PWM >= 9) 
            r_counter_PWM <= 0;
    end else begin
        r_counter_PWM <= 0;  
    end
end

assign PWM_OUT = r_counter_PWM < r_DUTY_CYCLE ? 0:1;
// assign PWM_OUT_LED = PWM_OUT;
assign DUTY_CYCLE = r_DUTY_CYCLE;
 
endmodule