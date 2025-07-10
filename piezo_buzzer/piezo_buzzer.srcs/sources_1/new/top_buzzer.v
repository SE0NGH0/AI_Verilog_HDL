`timescale 1ns / 1ps

module top_buzzer(
    input           clk,
    input           reset,
    input           btnU, // 도
    input           btnC, // 솔
    input           btnR, // 파
    input           btnD, // 미
    input           btnL, // 레
    output  [1:0]   led,
    output          buzzer
    );

    // 분주값 상수 정의 (100MHz 기준)
    parameter DO_DIV    = 382_222;
    parameter RE_DIV    = 340_136;
    parameter MI_DIV    = 303_030;
    parameter FA_DIV    = 286_336;
    parameter SOL_DIV   = 255_102;
    parameter LA_DIV    = 227_272;
    parameter SI_DIV    = 202_429;
    parameter DO_H_DIV  = 191_111;

    // Cleaned 버튼 신호
    wire w_btnU, w_btnC, w_btnR, w_btnD, w_btnL;

    // 디바운스 인스턴스
    button_debounce u_btnU(.i_clk(clk), .i_reset(reset), .i_btn(btnU), .o_btn_clean(w_btnU));
    button_debounce u_btnC(.i_clk(clk), .i_reset(reset), .i_btn(btnC), .o_btn_clean(w_btnC));
    button_debounce u_btnR(.i_clk(clk), .i_reset(reset), .i_btn(btnR), .o_btn_clean(w_btnR));
    button_debounce u_btnD(.i_clk(clk), .i_reset(reset), .i_btn(btnD), .o_btn_clean(w_btnD));
    button_debounce u_btnL(.i_clk(clk), .i_reset(reset), .i_btn(btnL), .o_btn_clean(w_btnL));

    // 카운터 및 출력 토글 신호
    reg [21:0] r_cnt_do, r_cnt_re, r_cnt_mi, r_cnt_fa, r_cnt_sol;
    reg r_out_do, r_out_re, r_out_mi, r_out_fa, r_out_sol;

    // 도 (C4)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_cnt_do <= 0; r_out_do <= 0;
        end else if (w_btnU) begin
            if (r_cnt_do == DO_DIV - 1) begin
                r_cnt_do <= 0;
                r_out_do <= ~r_out_do;
            end else begin
                r_cnt_do <= r_cnt_do + 1;
            end
        end else begin
            r_cnt_do <= 0; r_out_do <= 0;
        end
    end

    // 레 (D4)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_cnt_re <= 0; r_out_re <= 0;
        end else if (w_btnL) begin
            if (r_cnt_re == RE_DIV - 1) begin
                r_cnt_re <= 0;
                r_out_re <= ~r_out_re;
            end else begin
                r_cnt_re <= r_cnt_re + 1;
            end
        end else begin
            r_cnt_re <= 0; r_out_re <= 0;
        end
    end

    // 미 (E4)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_cnt_mi <= 0; r_out_mi <= 0;
        end else if (w_btnD) begin
            if (r_cnt_mi == MI_DIV - 1) begin
                r_cnt_mi <= 0;
                r_out_mi <= ~r_out_mi;
            end else begin
                r_cnt_mi <= r_cnt_mi + 1;
            end
        end else begin
            r_cnt_mi <= 0; r_out_mi <= 0;
        end
    end

    // 파 (F4)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_cnt_fa <= 0; r_out_fa <= 0;
        end else if (w_btnR) begin
            if (r_cnt_fa == FA_DIV - 1) begin
                r_cnt_fa <= 0;
                r_out_fa <= ~r_out_fa;
            end else begin
                r_cnt_fa <= r_cnt_fa + 1;
            end
        end else begin
            r_cnt_fa <= 0; r_out_fa <= 0;
        end
    end

    // 솔 (G4)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_cnt_sol <= 0; r_out_sol <= 0;
        end else if (w_btnC) begin
            if (r_cnt_sol == SOL_DIV - 1) begin
                r_cnt_sol <= 0;
                r_out_sol <= ~r_out_sol;
            end else begin
                r_cnt_sol <= r_cnt_sol + 1;
            end
        end else begin
            r_cnt_sol <= 0; r_out_sol <= 0;
        end
    end

    // 부저 출력
    assign buzzer = r_out_do | r_out_re | r_out_mi | r_out_fa | r_out_sol;

endmodule
