`timescale 1ns / 1ps

module mw_time_controller(
        input clk,
        input reset,
        input btnU,
        input btnD,
        input digit_sel,
        input mw_enable,
        input [1:0] state,
        output reg run_toggle,
        output reg [3:0] circle_sec,
        output reg [15:0] run_time // [15:8] 분, [7:0] 초
    );
                                 
    reg [2:0] prev_btn = 3'b000;
    reg [31:0] r_mw_counter;
    reg [31:0] r_circle_counter;

    parameter IDLE   = 2'b00; // IDLE 모드에서는 문 열고 닫음, TIME 으로 천이 가능
    parameter TIME   = 2'b01; // TIME 모드에서는 문 열고 닫음, 시간제어, 그리고 동작 중으로 천이 가능
    parameter RUN    = 2'b10; // RUN 에서는 동작시간이 모두 지나면 동작 종료로 천이, 취소버튼 누르면 TIME 으로 천이
    parameter STOP   = 2'b11; // STOP 에서는 FND, BUZZER를 출력하고 IDLE로 천이
    parameter MIN = 1'b1;
    parameter SEC = 1'b0;

    always @ (posedge clk or posedge reset or negedge mw_enable) begin
        if(reset || !mw_enable) begin
            prev_btn <= 3'd0;
            run_time <= 16'd0;
            r_mw_counter <= 0;
            r_circle_counter <= 0;
            run_toggle <= 0;
        end else if (state == TIME) begin
            r_mw_counter <= 0;
            // if (btnR && !prev_btn[0]) begin // 자리수 변경
            //     digit_sel <= ~digit_sel;
            // end
            if (btnU && !prev_btn[0]) begin // 숫자 증가
                if(digit_sel == MIN) begin
                    if (run_time[15:8] == 8'd59)
                        run_time[15:8] <= 8'd0;
                    else
                        run_time[15:8] <= run_time[15:8] + 8'd1;
                end
                else if(digit_sel == SEC) begin
                    if (run_time[7:0] == 8'd59)
                        run_time[7:0] <= 8'd0;
                    else
                        run_time[7:0] <= run_time[7:0] + 8'd1;
                end
            end
            if (btnD && !prev_btn[1]) begin // 숫자 감소
                if(digit_sel == MIN)
                    run_time[15:8] <= (run_time[15:8] == 0) ? 8'd59 : run_time[15:8] - 8'b1;
                else if(digit_sel == SEC)
                    run_time[7:0] <= (run_time[7:0] == 0) ? 8'd59 : run_time[7:0] - 8'b1;                
            end
            prev_btn <= {btnD,btnU}; // btnD 1 btnU 0
        end else if (state == RUN) begin
            if (r_mw_counter == 32'd1_0000_0000 - 1) begin
                r_mw_counter <= 0;
                if (run_time[7:0] == 8'd0) begin
                    if (run_time[15:8] != 8'd0) begin
                        run_time[15:8] <= run_time[15:8] - 1;  // 분 감소
                        run_time[7:0]  <= 8'd59;               // 초 = 59초로 세팅
                    end else begin
                        run_time[15:8] <= 8'd0;
                        run_time[7:0]  <= 8'd0;  // 0:0 유지 (완전 끝)
                    end
                end else begin
                    run_time[7:0] <= run_time[7:0] - 1;        // 초만 감소
                end
            end
            else begin
                r_mw_counter <= r_mw_counter + 1;
            end

            if (r_circle_counter == 32'd5000_0000 - 1) begin
                r_circle_counter <= 0;              
                if (circle_sec == 4'd13) begin
                    circle_sec <= 4'd0;
                end else begin
                    circle_sec <= circle_sec + 1;
                    run_toggle <= ~run_toggle;
                end
            end else begin
                r_circle_counter <= r_circle_counter + 1;
            end
        end else begin
            prev_btn <= 3'b0;
            r_mw_counter <= 0;
        end
    end    

endmodule
