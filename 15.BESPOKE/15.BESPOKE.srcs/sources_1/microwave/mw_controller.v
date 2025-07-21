`timescale 1ns / 1ps

module mw_controller(
        input clk,
        input reset,
        input btnC,
        input mw_enable,
        input [1:0] state,
        output reg [4:0] finish_time,
        output reg finish_toggle,
        output reg door_state
    );

    reg [31:0] r_counter_finish;
    reg prev_btnC = 1'b0;

    parameter IDLE   = 2'b00; // IDLE 모드에서는 문 열고 닫음, TIME 으로 천이 가능
    parameter TIME   = 2'b01; // TIME 모드에서는 문 열고 닫음, 시간제어, 그리고 동작 중으로 천이 가능
    parameter RUN    = 2'b10; // RUN 에서는 동작시간이 모두 지나면 동작 종료로 천이, 취소버튼 누르면 TIME 으로 천이
    parameter STOP   = 2'b11; // STOP 에서는 FND, BUZZER를 출력하고 IDLE로 천이

    parameter PUSHED = 1'b1;
    parameter OPEN   = 1'b1;
    parameter CLOSE  = 1'b0;

    always @(posedge clk or posedge reset or negedge mw_enable) begin
        if(reset || !mw_enable) begin
            r_counter_finish <= 32'b0;
            finish_time <= 5'b0;
            prev_btnC <= 1'b0;
            finish_toggle <= 1'b0;
            door_state <= CLOSE;
        end else if (state == IDLE) begin
            if (btnC && !prev_btnC) begin
                door_state <= ~door_state;
            end
            prev_btnC <= btnC;
        end else if (state == TIME) begin
            if (btnC && !prev_btnC) begin
                door_state <= ~door_state;
            end
            prev_btnC <= btnC;
        end else if (state == STOP) begin
            if (r_counter_finish == 32'd1_0000_0000 - 1) begin
                finish_time <= finish_time + 5'd1;
                r_counter_finish <= 32'b0;
                finish_toggle <= ~finish_toggle;
            end else begin
                r_counter_finish <= r_counter_finish + 1;
            end
        end else begin
            r_counter_finish <= 32'b0;
            finish_time <= 5'b0;
        end
    end

endmodule
