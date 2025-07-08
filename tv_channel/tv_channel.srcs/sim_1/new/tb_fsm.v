`timescale 1ns / 1ps

module tb_fsm();

    reg clk, rstn;
    reg done;
    wire ack;
    wire [1:0] current_state;

    // DUT 인스턴스
    fsm dut_fsm (
        .clk(clk), 
        .rstn(rstn), 
        .done(done), 
        .ack(ack),
        .current_state(current_state)
    );

    // 클럭 생성 (10ns 주기)
    initial clk = 0;
    always #5 clk = ~clk;

    // 테스트 시나리오
    initial begin
        // 파형 덤프 (GTKWave 등에서 보기 위해)
        $dumpfile("fsm_tb.vcd");
        $dumpvars(0, tb_fsm);

        // 초기화
        rstn = 0; done = 0;
        #12;           // reset 동안 대기
        rstn = 1;      // reset 해제

        // FSM 동작 시나리오
        // 상태: READY → done=1 → TRANS
        #10 done = 1;  // ack = 1
        #10 done = 1;  // TRANS 유지, ack = 0
        #10 done = 0;  // TRANS → WRITE, ack = 0
        #10 done = 0;  // WRITE 유지, ack = 0
        #10 done = 1;  // WRITE → READ, ack = 1
        #10 done = 0;  // READ 유지, ack = 0
        #10 done = 1;  // READ → READY, ack = 1
        #10 done = 0;  // READY 유지, ack = 0
        #10 done = 1;  // READY → TRANS, ack = 1
        #10 done = 1;  // TRANS 유지, ack = 0
        #10 done = 0;  // TRANS → WRITE, ack = 0

        // 리셋
        #10 rstn = 0;
        #10 rstn = 1;  // 상태 → READY
        #10 done = 1;  // READY → TRANS, ack = 1

        #20 $finish;
    end

endmodule
