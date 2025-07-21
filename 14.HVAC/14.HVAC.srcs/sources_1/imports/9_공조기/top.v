`timescale 1ns / 1ps

module top (
    input wire clk,
    input wire reset,
    input wire echo,
    input wire [3:0] btn,
    input [14:0] sw,
    output wire trig,
    output wire RsTx,
    output wire buzzer,
    output wire [7:0] seg,
    output wire [3:0] an,
    inout wire dht11_data,
    output wire [15:0] led,
    output wire PWM_OUT,
    output wire [1:0] in1_in2
);

    localparam MODE_IDLE  = 2'd0;
    localparam MODE_ULTRA = 2'd1;
    localparam MODE_TEMP_HUMI = 2'd2;

    // === Tick Generator ===
    wire tick_1Hz;
    tick_generator #(
        .INPUT_FREQ(100_000_000),
        .TICK_HZ(1)
    ) u_tick_gen (
        .clk(clk),
        .reset(reset),
        .tick(tick_1Hz)
    );

    // === Button Debounce ===
    wire btn0_clean;
    button_debounce u_debounce0 (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[0]),
        .led(),
        .o_btn_clean(btn0_clean)
    );

    wire btn1_clean;
    button_debounce u_debounce1 (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[1]),
        .led(),
        .o_btn_clean(btn1_clean)
    );

    wire btn2_clean;
    button_debounce u_debounce2 (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[2]),
        .led(),
        .o_btn_clean(btn2_clean)
    );

    wire btn3_clean;
    button_debounce u_debounce3 (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btn[3]),
        .led(led[6]),
        .o_btn_clean(btn3_clean)
    );

    // 수동 온도 설정 모듈
    wire [13:0] temp_manual;
    wire [13:0] temp_applied;

    manual_temp_controller u_temp_manual_ctrl (
        .clk(clk),
        .reset(reset),
        .enable(sw[1]),
        .btn_inc(btn1_clean),
        .btn_dec(btn2_clean),
        .btn_set(btn3_clean),
        .temp_manual(temp_manual),
        .temp_applied(temp_applied)
    );

    // === Mode Selector ===
    wire [1:0] mode;
    mode_selector #(
        .NUM_MODES(3)
    ) u_mode_selector (
        .clk(clk),
        .reset(reset),
        .btn_clean(btn0_clean),
        .mode(mode)
    );

    // === Ultrasonic Sensor ===
    wire [15:0] distance_cm;
    wire done;
    hcsr04 u_hcsr04 (
        .clk(clk),
        .reset(reset),
        .start(tick_1Hz),
        .trig(trig),
        .echo(echo),
        .distance_cm(distance_cm),
        .done(done)
    );

    // === Distance Latch ===
    wire [13:0] latched_distance;
    distance_latch_controller u_latch (
        .clk(clk),
        .reset(reset),
        .distance_cm(distance_cm),
        .done(done),
        .latched_distance(latched_distance)
    );

    // === Ultrasonic UART ===
    wire tx_start_ultra;
    wire [7:0] tx_data_ultra;
    wire tx_done_ultra, tx_busy_ultra;
    wire RsTx_ultra;

    data_sender u_data_sender (
        .clk(clk),
        .reset(reset),
        .send_data(latched_distance),
        .start_trigger((mode == MODE_ULTRA) ? tick_1Hz : 1'b0),
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

    // === DHT11 Sensor ===
    wire [$clog2(11600) - 1:0] w_dht11_humid;
    wire [$clog2(11600) - 1:0] w_dht11_temp;

    dht11_controller u_dht11_controller(
        .clk(clk),
        .reset(reset),
        .data_io(dht11_data),
        .humidity(w_dht11_humid),       // 14bit
        .temperature(w_dht11_temp),     // 14bit
        .led(led[7:0])
    );

    assign w_seg_data = (sw[0]) ?  w_dht11_humid : w_dht11_temp;

    // === DHT11 UART data sender ===
    wire tx_start_dht;
    wire [7:0] tx_data_dht;
    wire tx_done_dht, tx_busy_dht;
    wire RsTx_dht;

    dht11_data_sender u_data_sender_dht (
        .clk(clk),
        .reset(reset),
        .temperature(w_dht11_temp),
        .humidity(w_dht11_humid),
        .start_trigger((mode == MODE_TEMP_HUMI) ? tick_1Hz : 1'b0),
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

    // === RsTx MUX ===
    // assign RsTx = (mode == MODE_ULTRA) ? RsTx_ultra : 1'b1;
    assign RsTx = (mode == MODE_ULTRA) ? RsTx_ultra :
                  (mode == MODE_TEMP_HUMI) ? RsTx_dht : 1'b1;


    // === Buzzer ===
    wire buzzer_out_raw;
    buzzer_controller u_buzzer (
        .clk(clk),
        .reset(reset),
        .distance(latched_distance),
        .buzzer_out(buzzer_out_raw)
    );

    assign buzzer = (distance_cm <= 14'd5) ? 1'b1 : 1'b0;

    // === FND ===
    wire [13:0] display_value = (sw[1]) ? temp_manual :
                                (mode == MODE_ULTRA) ? latched_distance :
                                (mode == MODE_TEMP_HUMI) ? ((sw[0]) ? w_dht11_humid : w_dht11_temp) :
                                14'd0;

    wire [7:0] seg_main;
    wire [3:0] an_main;
    wire [7:0] seg_idle;
    wire [3:0] an_idle;

    fnd_controller u_fnd_main (
        .clk(clk), .reset(reset), .input_data(display_value), .seg_data(seg_main), .an(an_main)
    );

    fnd_rotate u_fnd_idle (
        .clk(clk), .reset(reset), .seg(seg_idle), .an(an_idle)
    );

    assign seg = (mode == MODE_IDLE && ~sw[1]) ? seg_idle : seg_main;
    assign an  = (mode == MODE_IDLE && ~sw[1]) ? an_idle  : an_main;

    // == DC motor(정회전) ===
    wire [1:0] dc_motor_state = 2'b10;  // RUN 상태로 고정
    wire motor_enable = (latched_distance <= 14'd5) ? 1'b0 : 1'b1;

    pwm_dcmotor u_dc_motor (
        .clk(clk),
        .enable(motor_enable),
        .measured_temp(w_dht11_temp),
        .target_temp(temp_applied),
        .manual_mode(sw[1]),
        .PWM_OUT(PWM_OUT),
        .d_led(led[7]),
        .in1_in2(in1_in2)
    );

    assign led[15:8] = w_dht11_temp / 100;

endmodule
