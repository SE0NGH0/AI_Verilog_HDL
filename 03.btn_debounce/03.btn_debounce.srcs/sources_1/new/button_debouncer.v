// button_debouncer.v
`timescale 1ns / 1ps

module button_debouncer (
    input  wire clk,        // 100 MHz system clock
    input  wire reset,      // synchronous reset, active high
    input  wire noisy_btn,  // raw, bouncy button input
    output reg  clean_btn   // debounced output (idle = 0)
);

    // ---------------------------------------------------------------------
    // 1) 파라미터 정의
    localparam integer DEBOUNCE_MS     = 10;          // 10 ms debounce time

    // ---------------------------------------------------------------------
    // 2) 1 ms 틱 생성
    wire tick_1ms;
    tick_generator u_tick (
        .clk   (clk),
        .reset (reset),
        .tick  (tick_1ms)
    );

    // ---------------------------------------------------------------------
    // 3) 카운터 & 디바운스 로직
    //    DEBOUNCE_TICKS 만큼 연속된 tick_1ms 동안 noisy_btn != clean_btn 이면
    //    clean_btn 을 noisy_btn 으로 업데이트
    reg [$clog2(DEBOUNCE_MS)-1:0] cnt;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt       <= 0;
            clean_btn <= 1'b0;
        end
        else if (tick_1ms) begin
            if (noisy_btn != clean_btn) begin
                // 변화 감지 시 카운트
                if (cnt == DEBOUNCE_MS) begin
                    clean_btn <= noisy_btn;
                    cnt       <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end else begin
                // 안정 상태면 카운터 리셋
                cnt <= 0;
            end
        end
    end

endmodule
