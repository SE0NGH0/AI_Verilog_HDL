`timescale 1ns / 1ps

module mode_selector #(
    parameter NUM_MODES = 3  // 사용할 모드 수 (기본값: 3)
)(
    input wire clk,
    input wire reset,
    input wire btn_clean,           // 디바운싱된 버튼 입력
    output reg [$clog2(NUM_MODES)-1:0] mode     // 모드 출력 (log2(NUM_MODES) 비트)
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            mode <= 0;
        else if (btn_clean)
            mode <= (mode + 1) % NUM_MODES;
    end

endmodule
