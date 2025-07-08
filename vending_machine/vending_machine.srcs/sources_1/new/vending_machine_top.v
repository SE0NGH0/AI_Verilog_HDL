`timescale 1ns / 1ps

module vending_machine_top (
    input wire clk,        // 100MHz
    input wire btnU,       // Reset
    input wire btnL,       // 100원
    input wire btnC,       // 500원
    input wire btnR,       // 커피
    input wire btnD,       // 반환
    output wire [6:0] seg, // a~g
    output wire [3:0] an,  // AN0만 사용
    output wire [6:0] led
);

    //==================================================
    // 신호 선언
    //==================================================
    wire rst_pulse, in100_pulse, in500_pulse, buy_pulse, refund_pulse;
    wire [15:0] balance;

    wire clean_btnU, clean_btnL, clean_btnC, clean_btnR, clean_btnD;

    //==================================================
    // 디바운싱 + 원샷
    //==================================================
    button_debouncer d0 (.clk(clk), .noisy_btn(btnU), .clean_btn(clean_btnU));
    button_debouncer d1 (.clk(clk), .noisy_btn(btnL), .clean_btn(clean_btnL));
    button_debouncer d2 (.clk(clk), .noisy_btn(btnC), .clean_btn(clean_btnC));
    button_debouncer d3 (.clk(clk), .noisy_btn(btnR), .clean_btn(clean_btnR));
    button_debouncer d4 (.clk(clk), .noisy_btn(btnD), .clean_btn(clean_btnD));

    button_onepulse u0 (.clk(clk), .btn(clean_btnU), .out(rst_pulse));
    button_onepulse u1 (.clk(clk), .btn(clean_btnL), .out(in100_pulse));
    button_onepulse u2 (.clk(clk), .btn(clean_btnC), .out(in500_pulse));
    button_onepulse u3 (.clk(clk), .btn(clean_btnR), .out(buy_pulse));
    button_onepulse u4 (.clk(clk), .btn(clean_btnD), .out(refund_pulse));

    //==================================================
    // FSM (잔액 계산)
    //==================================================
    vending_fsm fsm (
        .clk(clk),
        .rst(rst_pulse),
        .in100(in100_pulse),
        .in500(in500_pulse),
        .buy(buy_pulse),
        .refund(refund_pulse),
        .balance(balance)
    );

    //==================================================
    // FND mode FSM (애니메이션 + 잔액 표시)
    //==================================================
    reg [2:0] fnd_mode = 3'b100;  // 기본: 숫자모드
    reg is_animating = 0;
    reg [3:0] anim_step = 0;
    reg [25:0] anim_cnt = 0;

    always @(posedge clk or posedge rst_pulse) begin
        if (rst_pulse) begin
            fnd_mode <= 3'b100;
            is_animating <= 0;
            anim_step <= 0;
            anim_cnt <= 0;
        end else begin
            if (buy_pulse && balance >= 300 && !is_animating) begin
                is_animating <= 1;
                fnd_mode <= 3'b000; // 애니메이션 모드
                anim_step <= 0;
                anim_cnt <= 0;
            end
            if (is_animating) begin
                anim_cnt <= anim_cnt + 1;
                if (anim_cnt == 25_000_000) begin // 0.5초 지남
                    anim_cnt <= 0;
                    anim_step <= anim_step + 1;
                end
                if (anim_step == 13) begin
                    is_animating <= 0;
                    fnd_mode <= 3'b100; // BCD 출력 복귀
                end
            end
        end
    end

    //==================================================
    // FND 표시기 (애니메이션 포함)
    //==================================================
    fnd_controller fnd_disp (
        .clk(clk),
        .rst(rst_pulse),
        .mode(fnd_mode),
        .in_data(balance),
        .an(an),
        .seg(seg)
    );

    //==================================================
    // LED 커피 구매 효과 (buy_pulse가 발생하고 잔액 >= 300일 때)
    //==================================================
    wire led_trigger = (balance >= 300) ? buy_pulse : 1'b0;

    led_coffee_effect led_effect (
        .clk(clk),
        .rst(rst_pulse),
        .trigger(led_trigger),
        .led(led)
    );

endmodule
