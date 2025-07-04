`timescale 1ns / 1ps

module mytop (
    input  wire clk,     // Basys3 on‐board 100 MHz
    input  wire noisy_btn,    // Basys3 중앙 푸쉬버튼
    output wire led     // Basys3 LED
);

    // 1 ms 틱
    wire tick_1ms;
    tick_generator #(
        .INPUT_FREQ(100_000_000),
        .TICK_HZ   (1000)
    ) u_tg (
        .clk   (clk),
        .reset (1'b0),    // 리셋은 보통 FPGA 리셋 버튼을 쓰지 않으면 상수 0
        .tick  (tick_1ms)
    );

    // 디바운스
    wire clean_btn;
    button_debouncer u_db (
        .clk       (clk),
        .reset     (1'b0),
        .noisy_btn (noisy_btn),
        .clean_btn (clean_btn)
    );

    // 토글(LED)
    btn_toggle u_bt (
        .clk       (clk),
        .reset     (1'b0),
        .clean_btn (clean_btn),
        .led       (led)
    );

endmodule
