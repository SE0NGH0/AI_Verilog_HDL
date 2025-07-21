`timescale 1ns / 1ps

module mw_fsm_controller(
        input clk,
        input reset, // 리셋은 스위치를 사용       
        input btnR,  // btnR로만 모드가 천이됨 나머지는 조건
        input mw_enable,
        input [15:0] run_time,
        input [4:0] finish_time,
        input door_state, // 문 열림/닫힘 상태
        output reg [1:0] state        
    );

    reg [1:0] next_state;

    parameter IDLE   = 2'b00; // IDLE 모드에서는 문 열고 닫음, TIME 으로 천이 가능
    parameter TIME   = 2'b01; // TIME 모드에서는 문 열고 닫음, 시간제어, 그리고 동작 중으로 천이 가능
    parameter RUN    = 2'b10; // RUN 에서는 동작시간이 모두 지나면 동작 종료로 천이, 취소버튼 누르면 TIME 으로 천이
    parameter STOP   = 2'b11; // STOP 에서는 FND, BUZZER를 출력하고 IDLE로 천이
    parameter OPEN   = 1'b1;
    parameter CLOSE  = 1'b0;

    reg prev_btnR;
    // 모든 버튼에 의한 동작은 문이 닫혀있을때만 성립

    always @(*) begin
        next_state = state;
        if(door_state == CLOSE) begin
            case(state)
                IDLE   : next_state = (btnR && !prev_btnR) ? TIME : IDLE;
                TIME   : next_state = ((btnR && !prev_btnR) && run_time != 0) ? RUN  : TIME;                                  
                RUN    : next_state = (btnR && !prev_btnR) ? TIME : 
                                      (run_time == 0) ? STOP : RUN;
                STOP   : next_state = IDLE;
                default : next_state = IDLE;
            endcase
        end
    end

    always @(posedge clk or posedge reset or negedge mw_enable) begin
        if(reset || !mw_enable)
            state <= IDLE;
        else if(state == STOP) begin
            if(finish_time == 5'd6)
                state <= next_state;
            else
                state <= state;
        end else 
            state <= next_state;
    end

    always @(posedge clk or posedge reset or negedge mw_enable) begin
        if (reset || !mw_enable) begin
            prev_btnR <= 1'b0;
        end else begin
            prev_btnR <= btnR;
        end
    end

endmodule