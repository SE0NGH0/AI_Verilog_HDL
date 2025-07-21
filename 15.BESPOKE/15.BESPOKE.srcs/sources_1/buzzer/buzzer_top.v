module top(
    input clk,
    input reset,
    input btnL,
    input btnR,
    input mw_enable,
    output buzzer
);

    wire clean_btnL, clean_btnR;
    wire buzzer_L, buzzer_R;

    // 버튼 디바운스
    button_debounce dbL (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnL),
        .o_btn_clean(clean_btnL)
    );

    button_debounce dbR (
        .i_clk(clk),
        .i_reset(reset),
        .i_btn(btnR),
        .o_btn_clean(clean_btnR)
    );

    // 파워 온 시퀀스 (btnL)
    power_on_buzzer u_power (
        .clk(clk),
        .reset(reset),
        .btnL(clean_btnL),
        .buzzer_L(buzzer_L)
    );

    // 오픈 시퀀스 (btnR)
    open_buzzer u_open (
        .clk(clk),
        .reset(reset),
        .btnR(clean_btnR),
        .buzzer_R(buzzer_R)
    );

    assign buzzer = buzzer_L | buzzer_R;

endmodule
