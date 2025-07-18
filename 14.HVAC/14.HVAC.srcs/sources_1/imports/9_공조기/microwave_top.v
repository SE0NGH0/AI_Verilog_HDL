`timescale 1ns / 1ps

module microwave_top(
        input clk,
        input reset,
        input btnC,
        input btnU,
        input btnL,
        input btnR,
        input btnD,
        output buzzer,
        output PWM_OUT_LED,
        output PWM_OUT,
        output PWM_SERVO,
        output [1:0] in1_in2,
        output [13:0] led,
        output [3:0] an,
        output [7:0] seg
    );

    wire w_clean_btnC;
    wire w_clean_btnU;
    wire w_clean_btnL;
    wire w_clean_btnR;
    wire w_clean_btnD;


    wire [1:0] w_state;
    wire [3:0] w_circle_sec;
    wire [4:0] w_finish_time;
    wire [15:0] w_run_time;
    wire w_finish_toggle;
    wire w_run_toggle;
    wire w_door_state;

    // 버튼 디바운스
    button_debounce d_btnC (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnC),
        .led(led[0]),
        .o_btn_clean(w_clean_btnC)
    );

    button_debounce d_btnU (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnU),
        .led(led[1]),
        .o_btn_clean(w_clean_btnU)
    );

    button_debounce d_btnL (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnL),
        .led(led[2]),
        .o_btn_clean(w_clean_btnL)
    );

    button_debounce d_btnR (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnR),
        .led(led[3]),
        .o_btn_clean(w_clean_btnR)
    );

    button_debounce d_btnD (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnD),
        .led(led[4]),
        .o_btn_clean(w_clean_btnD)
    );


    controller u_mw_controller(
        .clk(clk),
        .reset(reset),
        .btnC(w_clean_btnC),
        .state(w_state),
        .finish_time(w_finish_time),
        .finish_toggle(w_finish_toggle),
        .door_state(w_door_state)
    );

    fsm_controller u_mw_fsm(
        .clk(clk),
        .reset(reset),
        .btnL(w_clean_btnL),
        .run_time(w_run_time),
        .finish_time(w_finish_time),
        .door_state(w_door_state),
        .state(w_state)        
    );

    time_controller u_time_controller(
        .clk(clk),
        .reset(reset),
        .btnU(w_clean_btnU),
        .btnD(w_clean_btnD),
        .btnR(w_clean_btnR),
        .state(w_state),
        .circle_sec(w_circle_sec),
        .run_toggle(w_run_toggle),
        .run_time(w_run_time) 
    );

    fnd_controller u_fnd_controller(
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
        .btn(w_clean_btnC | w_clean_btnU | w_clean_btnD | w_clean_btnL | w_clean_btnR),
        .buzzer(buzzer)
    );

    pwm_dcmotor u_mw_pwm_dcmotor(
        .clk(clk),
        .PWM_OUT(PWM_OUT),
        .PWM_OUT_LED(PWM_OUT_LED),
        .state(w_state),
        .in1_in2(in1_in2)        
    );

    servo_controller u_mw_servo(
    .clk(clk),       
    .reset(reset),
    .door_state(w_door_state),
    .servo_pwm(PWM_SERVO)
);

endmodule
