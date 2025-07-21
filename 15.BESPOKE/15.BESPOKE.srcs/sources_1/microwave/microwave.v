`timescale 1ns / 1ps

module microwave_top(
        input clk,
        input reset,
        input [4:0] btn,
        input  mw_enable,
        input  digit_sel,
        output buzzer,
        // output PWM_OUT_LED,
        output PWM_OUT,
        output PWM_SERVO,
        output [1:0] in1_in2,
        output [3:0] an,
        output [7:0] seg
    );

    wire [1:0] w_state;
    wire [3:0] w_circle_sec;
    wire [4:0] w_finish_time;
    wire [15:0] w_run_time;
    wire w_finish_toggle;
    wire w_run_toggle;
    wire w_door_state;

    // btn[0] : L, btn[1] : C, btn[2] : R, btn[3] : U, btn[4] : D

    mw_controller u_mw_controller(
        .clk(clk),
        .reset(reset),
        .btnC(btn[1]),
        .mw_enable(mw_enable),
        .state(w_state),
        .finish_time(w_finish_time),
        .finish_toggle(w_finish_toggle),
        .door_state(w_door_state)
    );

    mw_fsm_controller u_mw_fsm(
        .clk(clk),
        .reset(reset),
        .btnR(btn[2]),
        .mw_enable(mw_enable),
        .run_time(w_run_time),
        .finish_time(w_finish_time),
        .door_state(w_door_state),
        .state(w_state)        
    );

    mw_time_controller u_mw_time_controller(
        .clk(clk),
        .reset(reset),
        .btnU(btn[3]),
        .btnD(btn[4]),
        .digit_sel(digit_sel),
        .mw_enable(mw_enable),
        .state(w_state),
        .circle_sec(w_circle_sec),
        .run_toggle(w_run_toggle),
        .run_time(w_run_time) 
    );

    mw_servo_controller u_mw_servo(
    .clk(clk),       
    .reset(reset),
    .mw_enable(mw_enable),
    .door_state(w_door_state),
    .servo_pwm(PWM_SERVO)
    );

    fnd_controller_2 u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .finish_toggle(w_finish_toggle),
        .run_toggle(w_run_toggle),
        .state(w_state),
        .run_time(w_run_time),
        .circle_sec(w_circle_sec),
        .finish_time(w_finish_time),
        .an(an),
        .seg(seg)
    );

    button_buzzer u_button_buzzer(
        .clk(clk),
        .reset(reset),
        .mw_enable(mw_enable),
        .btn(btn[0] | btn[1] | btn[2] | btn[3] | btn[4]),
        .buzzer(buzzer)
    );

    pwm_dcmotor u_mw_pwm_dcmotor(
        .clk(clk),
        .PWM_OUT(PWM_OUT),
        // .PWM_OUT_LED(PWM_OUT_LED),
        .mw_enable(mw_enable),
        .state(w_state),
        .in1_in2(in1_in2)        
    );

endmodule
