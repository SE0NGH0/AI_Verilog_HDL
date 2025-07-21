`timescale 1ns / 1ps

module top(
    input clk,
    input reset,      // SW15
    input [4:0] btn,  // BTN[0] : L, BTN[1] : C, BTN[2] : R, BTN[3] : U, BTN[4] : D
    input [14:0] sw,
    input RsRx,
    input echo,
    inout dht11_data,
    output trig,
    output RsTx,
    output buzzer,
    output PWM_OUT,
    output PWM_SERVO,
    output [1:0] in1_in2,
    output PWM_OUT_HVAC,
    output [1:0] in1_in2_HVAC,
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led
    );

    localparam NO_BUZZER = 1'b0;

    /* BTN WIRE */
    /* BTN[0] : L, BTN[1] : C, BTN[2] : R, BTN[3] : U, BTN[4] : D */
    wire [4:0] w_btn_debounce; 
    wire buzzer_btn;
    /* FND WIRE */

    // 수동 온도 설정 모듈
    wire [13:0] w_temp_manual;
    wire [13:0] w_temp_applied;

    reg  [13:0] w_seg_data;
    wire [13:0] w_seg_data_dht11;
    wire [13:0] w_seg_data_tick;

    wire [7:0] w_seg_data_idle;
    wire [3:0] w_an_idle;

    wire [7:0] w_seg_data_auto;
    wire [3:0] w_an_auto;

    wire [7:0] w_seg_data_manual;
    wire [3:0] w_an_manual;

    wire [7:0] w_seg_data_mw;
    wire [3:0] w_an_mw;

    wire [7:0] w_seg_data_sw;
    wire [3:0] w_an_sw;

    /* ULTRA SONIC SENSOR WIRE */
    wire [13:0] w_distance_cm;
    wire [13:0] w_latched_distance;
    wire w_ultra_done;

    /* UART WIRE */
    wire w_rx_done;
    wire [7:0] w_rx_data;
    wire [7:0] w_send_data;

    /* DHT 11 WIRE */
    wire [$clog2(11600) - 1:0] w_dht11_humid;
    wire [$clog2(11600) - 1:0] w_dht11_temp;

    /* BUZZER WIRE */
    wire w_buzzer_ultra;
    wire w_buzzer_mw;
    wire w_buzzer_sw;

    /* command controller wire */
    wire [4:0] w_mode_enable;
    wire w_tick;
    reg r_tick;

    button_debounce u0_button_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[0]),
        .o_btn_clean(w_btn_debounce[0])
    );
    button_debounce u1_button_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[1]),
        .o_btn_clean(w_btn_debounce[1])
    );
    button_debounce u2_button_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[2]),
        .o_btn_clean(w_btn_debounce[2])
    );
    button_debounce u3_button_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[3]),
        .o_btn_clean(w_btn_debounce[3])
    );
    button_debounce u4_button_debounce(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[4]),
        .o_btn_clean(w_btn_debounce[4])
    );

    /* 전체 모드 controller */
    command_controller u_command_controller (
        .clk(clk),
        .reset(reset),  // SW15
        .btnL(w_btn_debounce[0]),       // Mode 변경 버튼
        .rx_done(w_rx_done),
        .rx_data(w_rx_data),
        .mode_enable(w_mode_enable) // 각 모드의 enable 신호    
    );

    // combinational MUX
    // 공조기 자동모드 이외 모드에서는 각 모듈에서 seg 를 8비트로 뽑아서 필요가 없음
    always @(*) begin
        case (1'b1)  // one‑hot 인코딩
        w_mode_enable[0] : w_seg_data <= 14'd0;    // IDLE MODE
        w_mode_enable[1] : w_seg_data <= (sw[0]) ? w_latched_distance : w_seg_data_dht11;  // 공조기 자동모드
        w_mode_enable[2] : w_seg_data <= 14'd0;    // 공조기 수동모드
        w_mode_enable[3] : w_seg_data <= 14'd0;    // 전자레인지
        w_mode_enable[4] : w_seg_data <= 14'd0;    // 스탑워치
        default:           w_seg_data <= 14'd0;    // 모두 off
        endcase
    end
    
    always @(posedge clk) begin
        if(w_tick)
            r_tick <= ~r_tick;
    end
    
    assign w_seg_data_tick  = (r_tick) ?  w_dht11_humid : w_dht11_temp;
    assign w_seg_data_dht11 = (w_mode_enable[1]) ? w_seg_data_tick : 14'd0;
    
    // 1s 타이머
    tick_generator #(
        .TICK_HZ(1)
    ) u_tick_generator (
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    /* 각 모드별 controller */
    dht11_controller u_dht11_controller(
        .clk(clk),
        .reset(reset),
        .data_io(dht11_data),
        .humidity(w_dht11_humid),       // 14bit
        .temperature(w_dht11_temp)      // 14bit
    );

    /* BTN[0] : L, BTN[1] : C, BTN[2] : R, BTN[3] : U, BTN[4] : D */

    uart_rx u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(RsRx),
        .data_out(w_rx_data),
        .rx_done(w_rx_done)
    );

    /* 공조기 수동모드 */
    manual_temp_controller u_temp_manual_ctrl (
        .clk(clk),
        .reset(reset),
        .man_enable(w_mode_enable[2]),
        .btn_inc(w_btn_debounce[3]),
        .btn_dec(w_btn_debounce[4]),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data),
        .temp_manual(w_temp_manual),
        .temp_applied(w_temp_applied)
    );

    /* Ultrasonic Sensor */

    hcsr04 u_hcsr04 (
        .clk(clk),
        .reset(reset),
        .start(w_tick),
        .trig(trig),
        .echo(echo),
        .distance_cm(w_distance_cm),
        .done(w_ultra_done) // 측정완료 signal
    );

    /* === Distance Latch 측정값 안정화 === */
    distance_latch_controller u_latch (
        .clk(clk),
        .reset(reset),
        .distance_cm(w_distance_cm),
        .done(w_ultra_done),
        .latched_distance(w_latched_distance)
    );
    
    /* === Ultrasonic UART === */
    wire tx_start_ultra;
    wire [7:0] tx_data_ultra;
    wire tx_done_ultra, tx_busy_ultra;
    wire RsTx_ultra;

    data_sender u_data_sender (
        .clk(clk),
        .reset(reset),
        .send_data(w_latched_distance),
        .start_trigger((w_mode_enable[1] | w_mode_enable[2]) & sw[14] & w_tick),
        .tx_start(tx_start_ultra),
        .tx_data(tx_data_ultra),
        .tx_done(tx_done_ultra),
        .tx_busy(tx_busy_ultra)
    );

    uart_tx u_uart_tx_ultra (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start_ultra),
        .tx_data(tx_data_ultra),
        .tx_done(tx_done_ultra),
        .tx(RsTx_ultra),
        .tx_busy(tx_busy_ultra)
    );

    /* === DHT11 UART data sender === */
    wire tx_start_dht;
    wire [7:0] tx_data_dht;
    wire tx_done_dht, tx_busy_dht;
    wire RsTx_dht;

    dht11_data_sender u_data_sender_dht (
        .clk(clk),
        .reset(reset),
        .temperature(w_dht11_temp),
        .humidity(w_dht11_humid),
        .start_trigger((w_mode_enable[1] | w_mode_enable[2]) & !sw[14] & w_tick),
        .tx_start(tx_start_dht),
        .tx_data(tx_data_dht),
        .tx_done(tx_done_dht),
        .tx_busy(tx_busy_dht)
    );

    uart_tx u_uart_tx_dht (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start_dht),
        .tx_data(tx_data_dht),
        .tx_done(tx_done_dht),
        .tx(RsTx_dht),
        .tx_busy(tx_busy_dht)
    );

    /* === RsTx MUX === */
    assign RsTx = (sw[14]) ? RsTx_ultra : RsTx_dht;

    /* === Buzzer === */
    // distance 값 5cm 이하일 때 부저 소리 출력

    ultra_buzzer_controller u_ultra_buzzer (
        .clk(clk),
        .reset(reset),
        .hvac_enable(w_mode_enable[1] | w_mode_enable[2]),
        .distance(w_latched_distance),
        .buzzer_out(w_buzzer_ultra)
    );

    /*
    // UART & FND //
    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .rx(RsRx),
        .send_data(w_send_data), // 14 bit
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .tx(RsTx)
    );
    */

    // 자동모드용 fnd //
    fnd_controller u_fnd_controller (
        .clk(clk),
        .reset(reset),
        .input_data(w_seg_data), // 14bit, 아마 fnd는 다른거 쓸듯(mw때 썻던거)
        .an(w_an_auto),
        .seg_data(w_seg_data_auto)
    );

    /* IDLE */
    fnd_rotate u_idle_fnd (
        .clk(clk),
        .reset(reset),
        .idle_enable(w_mode_enable[0]),
        .seg(w_seg_data_idle),
        .an(w_an_idle)
    );

    wire [13:0] display_value = (w_mode_enable[2] && !sw[1]) ? w_dht11_temp  :
                                (w_mode_enable[2] && sw[1])  ? w_temp_manual : 14'd0;

    /* 공조기 수동모드 */
    fnd_controller u_fnd_controller_hvac(
        .clk(clk),
        .reset(reset),
        .input_data(display_value),
        .seg_data(w_seg_data_manual),
        .an(w_an_manual)
    );

    // // == DC motor(정회전) ===
    wire [1:0] dc_motor_state = 2'b10;  // RUN 상태로 고정
    wire motor_enable = (w_latched_distance <= 14'd5) ? 1'b0 : 1'b1;

    hvac_pwm_dcmotor u_dc_motor (
        .clk(clk),
        .enable(motor_enable & (w_mode_enable[1] | w_mode_enable[2])),
        .measured_temp(w_dht11_temp),
        .target_temp(w_temp_applied),
        .manual_mode(w_mode_enable[2]),
        .PWM_OUT(PWM_OUT_HVAC),
        .in1_in2(in1_in2_HVAC)
    );

    /* Microwave */
    microwave_top u_mw_controller(
        .clk(clk),
        .reset(reset),
        .btn(w_btn_debounce),
        .mw_enable(w_mode_enable[3]),
        .digit_sel(sw[0]),
        .buzzer(w_buzzer_mw),
        .PWM_OUT(PWM_OUT),
        .PWM_SERVO(PWM_SERVO),
        .in1_in2(in1_in2),
        .an(w_an_mw),
        .seg(w_seg_data_mw)
    );

    /* Minsec StopWatch */
    minsec_stopwatch u_minsec_stopwatch(
        .clk(clk),
        .reset(reset),
        .sw_enable(w_mode_enable[4]),
        .btn({w_btn_debounce[4],w_btn_debounce[3],w_btn_debounce[1],w_btn_debounce[2]}), /* BTN[0] : R, BTN[1] : C, BTN[2] : U, BTN[3] : D */
        .buzzer_sw(w_buzzer_sw),
        .an(w_an_sw),
        .seg(w_seg_data_sw)
    );
    
    assign buzzer_btn = w_btn_debounce[0] | w_btn_debounce[1] | w_btn_debounce[2] | w_btn_debounce[3] | w_btn_debounce[4]; 

    assign seg = w_mode_enable[4] ? w_seg_data_sw     :
                 w_mode_enable[3] ? w_seg_data_mw     :
                 w_mode_enable[2] ? w_seg_data_manual :
                 w_mode_enable[1] ? w_seg_data_auto   :
                 w_mode_enable[0] ? w_seg_data_idle   :
                                    8'b1111_1111;
    assign an  = w_mode_enable[4] ? w_an_sw :
                 w_mode_enable[3] ? w_an_mw :
                 w_mode_enable[2] ? w_an_manual :
                 w_mode_enable[1] ? w_an_auto   :                  
                 w_mode_enable[0] ? w_an_idle : 
                                    4'b0000;
    
    assign led = w_mode_enable;
    assign buzzer = w_mode_enable[4] ? w_buzzer_sw    :   
                    w_mode_enable[3] ? w_buzzer_mw    :
                    w_mode_enable[2] ? w_buzzer_ultra | buzzer_btn :  
                    w_mode_enable[1] ? w_buzzer_ultra | buzzer_btn :
                    w_mode_enable[0] ? NO_BUZZER | buzzer_btn : NO_BUZZER;                    

    
endmodule