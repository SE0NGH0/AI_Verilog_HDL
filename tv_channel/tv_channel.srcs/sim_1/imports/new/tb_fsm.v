`timescale 1ns / 1ps

module fsm_tb();

    // 신호 선언
    reg clk, rstn, done;
    wire ack;
    wire [1:0] current_state;

    // DUT 인스턴스
    fsm dut (
        .clk(clk),
        .rstn(rstn),
        .done(done),
        .ack(ack),
        .current_state(current_state)
    );

    // 클럭 생성 (10ns 주기)
    initial clk = 0;
    always #5 clk = ~clk;

    // 입력 시나리오
    initial begin

        // 초기화
        rstn = 0; done = 0;
        #12;           // 리셋 active
        rstn = 1;

        // 상태 전이: READY → TRANS
        #10 done = 1;
        #20 done = 0;  // TRANS → WRITE
        #20 done = 1;  // WRITE → READ
        #20 done = 0;  // READ → READY

        // 상태 반복 테스트
        #20 done = 1;
        #20 done = 0;

        // 종료
        #30 $finish;
    end

endmodule
