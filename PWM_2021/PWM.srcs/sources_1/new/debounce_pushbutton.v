`timescale 1ns / 1ps

//----------------- debounce_pushbutton -----------------
module debounce_pushbutton (
    input clk,   // 100MHz clock input 
    input increase_duty_btn,   // input to increase 10% duty cycle 
    input decrease_duty_btn,   // input to decrease 10% duty cycle 
    output debounced_inc_btn,     // debounce inc button
    output debounced_dec_btn
);

 wire w_clk4hz_enable;   // slow clock enable signal for debouncing FFs
 reg[27:0] r_counter_debounce=0;  // counter for creating slow clock enable signals 
 wire w_Q1_DFF1, w_Q2_DFF2;  // temporary flip-flop signals for debouncing the increasing button
 wire w_Q1_DFF3, w_Q2_DFF4;  // temporary flip-flop signals for debouncing the decreasing button
 reg[1:0] r_motor_dir; 
  // Debouncing 2 buttons for inc/dec duty cycle 
  // Firstly generate slow clock enable for debouncing flip-flop (4Hz)
  
 always @(posedge clk)
 begin
   r_counter_debounce <= r_counter_debounce + 1;
   if (r_counter_debounce >= 25000000)   
    r_counter_debounce <= 0;
 end

 // 0.00000001sec(10ns) x 25000000 = 0.25sec(250ms)
 // 250ms가 되면 4Hz의 1주기를 나타내는 w_clk4hz_enable이 1로 set하여
 // DFF의 4Hz clock이 동작 되도록 한다. 
 assign w_clk4hz_enable = r_counter_debounce == 25000000 ? 1:0;

 DFF u_PWM_DFF1(clk,w_clk4hz_enable,increase_duty_btn,w_Q1_DFF1);
 DFF u_DFF2(clk,w_clk4hz_enable,w_Q1_DFF1, w_Q2_DFF2); 
 assign debounced_inc_btn =  w_Q1_DFF1 & (~w_Q2_DFF2) & w_clk4hz_enable;

 // debouncing FFs for decreasing button
 DFF u_DFF3(clk, w_clk4hz_enable, decrease_duty_btn, w_Q1_DFF3);
 DFF u_DFF4(clk, w_clk4hz_enable, w_Q1_DFF3, w_Q2_DFF4); 
 // button의 debounce를 위해서 첫번째 DFF의 출력 w_Q1_DFF3(Q1) 두번째 DFF의 출력 w_Q2_DFF4(Q2바) 를 and 해서
 //  debounce 처리된 1(debounced_inc_btn, debounced_dec_btn)이 나온다. 
 assign debounced_dec_btn =  w_Q1_DFF3 & (~w_Q2_DFF4) & w_clk4hz_enable;
 // vary the duty cycle using the debounced buttons above
endmodule