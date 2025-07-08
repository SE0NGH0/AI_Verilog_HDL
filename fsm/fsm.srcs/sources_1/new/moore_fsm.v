`timescale 1ns / 1ps

module fsm_moore (
    input  wire clk,
    input  wire rstn,
    input  wire done,
    output reg ack,                      // reg로 변경 (Moore는 상태 기반 출력)
    output reg [1:0] current_state       // 상태 관찰용 출력
);

    // 상태 인코딩
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
            READY:  next_state = (done) ? TRANS : READY;
            TRANS:  next_state = (done) ? WRITE : TRANS;
            WRITE:  next_state = (done) ? READ  : WRITE;
            READ:   next_state = (done) ? READY : READ;
            default: next_state = READY;
        endcase
    end

    // Moore 출력 로직: 상태에 따라 출력 결정
    always @(*) begin
        case (current_state)
            READY:  ack = 1'b0;
            TRANS:  ack = 1'b0;
            WRITE:  ack = 1'b0;
            READ:   ack = 1'b1;   // 예: READ 상태일 때만 ack=1
            default: ack = 1'b0;
        endcase
    end

endmodule
