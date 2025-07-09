`timescale 1ns / 1ps

module pattern_detector_top (
    input  wire clk,
    input  wire rst,      // 동기 리셋
    input  wire btnU,     // 1 입력 버튼
    input  wire btnD,     // 0 입력 버튼
    output wire [15:0] led // led[6:0] = 입력 표시, led[7] = 패턴 감지
);

    wire clean_btnU, clean_btnD;
    wire pulse_btnU, pulse_btnD;

    // 디바운싱
    button_debouncer db_u (
        .clk(clk),
        .btn(btnU),
        .debounced(clean_btnU)
    );

    button_debouncer db_d (
        .clk(clk),
        .btn(btnD),
        .debounced(clean_btnD)
    );

    // 원샷
    one_pulse op_u (
        .clk(clk),
        .btn_in(clean_btnU),
        .pulse_out(pulse_btnU)
    );

    one_pulse op_d (
        .clk(clk),
        .btn_in(clean_btnD),
        .pulse_out(pulse_btnD)
    );

    // FSM 동작
    pattern_detector_fsm fsm (
        .clk(clk),
        .rst(rst),
        .in1(pulse_btnU),
        .in0(pulse_btnD),
        .led(led)
    );

endmodule
