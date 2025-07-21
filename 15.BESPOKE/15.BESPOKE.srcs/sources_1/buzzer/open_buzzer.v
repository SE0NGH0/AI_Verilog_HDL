`timescale 1ns / 1ps

module open_buzzer(
    input clk,
    input reset,
    input btnR,
    output reg buzzer_R
);

    parameter CNT_70MS = 23'd7000000;
    parameter CNT_3S   = 29'd300000000;

    parameter HALF_261 = 18'd192000;
    parameter HALF_329 = 18'd152000;
    parameter HALF_392 = 18'd128000;
    parameter HALF_554 = 18'd90000;

    reg btnR_d1, btnR_d2;
    wire btnR_edge = btnR_d1 & ~btnR_d2;

    always @(posedge clk) begin
        btnR_d1 <= btnR;
        btnR_d2 <= btnR_d1;
    end

    reg run = 0;
    reg [2:0] step = 0;
    reg [28:0] dur_cnt = 0;
    reg [17:0] wave_cnt = 0;
    reg [17:0] half_cycle = 0;

    always @(*) begin
        case (step)
            0: half_cycle = HALF_261;
            1: half_cycle = HALF_329;
            2: half_cycle = HALF_392;
            3: half_cycle = HALF_554;
            default: half_cycle = 0;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            run <= 0; step <= 0; dur_cnt <= 0; wave_cnt <= 0; buzzer_R <= 0;
        end else begin
            if (btnR_edge) run <= ~run;
            if (!run) begin
                step <= 0; dur_cnt <= 0; wave_cnt <= 0; buzzer_R <= 0;
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
                        buzzer_R <= ~buzzer_R;
                    end else wave_cnt <= wave_cnt + 1;
                end else begin
                    buzzer_R <= 0;
                    wave_cnt <= 0;
                end
            end
        end
    end

endmodule
