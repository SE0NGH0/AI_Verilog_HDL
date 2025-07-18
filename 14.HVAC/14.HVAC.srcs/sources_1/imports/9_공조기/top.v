`timescale 1ns / 1ps

module top (
    input wire clk,
    input wire reset,
    input wire echo,
    input wire [2:0] btn,
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
        .led(),
        .o_btn_clean(btn3_clean)
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

    // === RsTx MUX ===
    assign RsTx = (mode == MODE_ULTRA) ? RsTx_ultra : 1'b1;

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
    wire [7:0] seg_ultra, seg_idle, seg_temp;
    wire [3:0] an_ultra, an_idle, an_temp;

    fnd_controller u_fnd_ultra (
        .clk(clk),
        .reset(reset),
        .input_data(latched_distance),
        .seg_data(seg_ultra),
        .an(an_ultra)
    );

    wire [13:0] fnd_display_data;
    assign fnd_display_data = (sw[0]) ? w_dht11_humid : w_dht11_temp;

    fnd_controller u_fnd_controller (
        .clk(clk),
        .reset(reset),
        .input_data(fnd_display_data),
        .an(an_temp),
        .seg_data(seg_temp)
    );

    fnd_rotate u_fnd_idle (
        .clk(clk),
        .reset(reset),
        .seg(seg_idle),
        .an(an_idle)
    );

    assign seg = (mode == MODE_ULTRA)     ? seg_ultra :
                 (mode == MODE_TEMP_HUMI) ? seg_temp  : seg_idle;

    assign an  = (mode == MODE_ULTRA)     ? an_ultra  :
                 (mode == MODE_TEMP_HUMI) ? an_temp   : an_idle;

    // == DC motor(정회전) ===
    wire [1:0] dc_motor_state = 2'b10;  // RUN 상태로 고정
    wire motor_enable;
    assign motor_enable = (latched_distance <= 14'd5) ? 1'b0 : 1'b1;

    pwm_dcmotor u_dc_motor (
        .clk(clk),
        .temperature(w_dht11_temp / 100),  // 상위 8비트 사용
        .enable(motor_enable),             // 거리 조건에 따라 동작 여부 결정
        .PWM_OUT(PWM_OUT),         // PWM 출력 (Vivado XDC에선 J3)
        .in1_in2(in1_in2)        // 방향 신호 (L3, M2)
    );

    assign led[15:8] = w_dht11_temp / 100;

endmodule
