`timescale 1ns / 1ps

module tb_fsm();

    reg clk, rstn;
    reg done;
    wire ack;
    wire [1:0] current_state;

    // ✅ 모듈 이름 일치시키기 (fsm)
    fsm dut_fsm (
        .clk(clk), 
        .rstn(rstn), 
        .done(done), 
        .ack(ack),
        .current_state(current_state)
    );

    // 클럭 생성
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns 주기

    // 테스트 시나리오
    initial begin
        // 파형 출력
        $dumpfile("fsm_tb.vcd");
        $dumpvars(0, tb_fsm);

        // 초기 조건
        rstn = 0; done = 0;

        // 리셋 → READY
        #20 rstn = 1;

        // 상태 전이 시퀀스
        #10 done = 0; // READY, ack = 1
        #10 done = 1; // TRANS, ack = 1
        #10 done = 1; // TRANS 유지
        #10 done = 0; // WRITE
        #10 done = 0; // WRITE 유지
        #10 done = 1; // READ
        #10 done = 0; // READ 유지
        #10 done = 1; // READY
        #10 done = 0; // READY
        #10 done = 1; // TRANS
        #10 rstn = 0; // 다시 RESET
        #10 rstn = 1; // RESET OFF

        #20 $finish;
    end

endmodule
