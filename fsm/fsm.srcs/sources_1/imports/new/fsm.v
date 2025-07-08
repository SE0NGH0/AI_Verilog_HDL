`timescale 1ns / 1ps

module fsm (
    input  wire clk,
    input  wire rstn,
    input  wire done,
    output ack,
    output reg [1:0] current_state  // 상태를 외부에서도 관찰 가능하게
);

    // 상태 인코딩 정의
    parameter READY = 2'b00;
    parameter TRANS = 2'b01;
    parameter WRITE = 2'b10;
    parameter READ  = 2'b11;

    reg [1:0] next_state;

    // 순차 논리: 상태 전이
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            current_state <= READY;
        else
            current_state <= next_state;
    end

    // 조합 논리: next state 계산
    always @(current_state or done) begin
        case (current_state)
            READY:  next_state = (done == 1) ? TRANS : READY;
            TRANS:  next_state = (done == 0) ? TRANS : WRITE;
            WRITE:  next_state = (done == 1) ? READ  : WRITE;
            READ:   next_state = (done == 0) ? READ  : READY;
            default: next_state = READY;
        endcase
    end

    assign ack = 1;

endmodule
