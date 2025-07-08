`timescale 1ns / 1ps

module fsm (
    input  wire clk,
    input  wire rstn,
    input  wire done,
    output reg ack,  // assign → reg 로 변경
    output reg [1:0] current_state
);

    // 상태 정의
    parameter READY = 2'b00;
    parameter TRANS = 2'b01;
    parameter WRITE = 2'b10;
    parameter READ  = 2'b11;

    reg [1:0] next_state;

    // 상태 전이 (순차 논리)
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            current_state <= READY;
        else
            current_state <= next_state;
    end

    // 다음 상태 결정 (조합 논리)
    always @(*) begin
        case (current_state)
            READY:  next_state = (done == 1) ? TRANS : READY;
            TRANS:  next_state = (done == 0) ? WRITE : TRANS;
            WRITE:  next_state = (done == 1) ? READ  : WRITE;
            READ:   next_state = (done == 1) ? READY : READ;
            default: next_state = READY;
        endcase
    end

    // Mealy 출력 로직
    always @(*) begin
        case (current_state)
            READY:  ack = 0;
            TRANS:  ack = (done == 1) ? 1'b1 : 1'b0;
            WRITE:  ack = 0;
            READ:   ack = (done == 1) ? 1'b1 : 1'b0;
            default: ack = 0;
        endcase
    end

endmodule
