`timescale 1ns / 1ps

module power_on_buzzer(
    input clk,
    input reset,
    input btnL,
    output reg buzzer_L
);

    parameter CNT_70MS = 23'd7000000;
    parameter CNT_3S   = 29'd300000000;

    parameter HALF_1K = 17'd50000;
    parameter HALF_2K = 17'd25000;
    parameter HALF_3K = 17'd16667;
    parameter HALF_4K = 17'd12500;

    reg btnL_d1, btnL_d2;
    wire btnL_edge = btnL_d1 & ~btnL_d2;

    always @(posedge clk) begin
        btnL_d1 <= btnL;
        btnL_d2 <= btnL_d1;
    end

    reg run = 0;
    reg [2:0] step = 0;
    reg [28:0] dur_cnt = 0;
    reg [17:0] wave_cnt = 0;
    reg [17:0] half_cycle = 0;

    always @(*) begin
        case (step)
            0: half_cycle = HALF_1K;
            1: half_cycle = HALF_2K;
            2: half_cycle = HALF_3K;
            3: half_cycle = HALF_4K;
            default: half_cycle = 0;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            run <= 0; step <= 0; dur_cnt <= 0; wave_cnt <= 0; buzzer_L <= 0;
        end else begin
            if (btnL_edge) run <= ~run;
            if (!run) begin
                step <= 0; dur_cnt <= 0; wave_cnt <= 0; buzzer_L <= 0;
            end else begin
                if ((step < 4 && dur_cnt >= CNT_70MS) || (step == 4 && dur_cnt >= CNT_3S)) begin
                    dur_cnt <= 0;
                    step <= (step == 4) ? 0 : step + 1;
                end else begin
                    dur_cnt <= dur_cnt + 1;
                end

                if (half_cycle != 0) begin
                    if (wave_cnt >= half_cycle) begin
                        wave_cnt <= 0;
                        buzzer_L <= ~buzzer_L;
                    end else wave_cnt <= wave_cnt + 1;
                end else begin
                    buzzer_L <= 0;
                    wave_cnt <= 0;
                end
            end
        end
    end

endmodule
