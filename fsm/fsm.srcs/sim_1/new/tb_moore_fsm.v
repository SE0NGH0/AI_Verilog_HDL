`timescale 1ns / 1ps

module tb_fsm_moore();

    reg clk, rstn;
    reg done;
    wire ack;
    wire [1:0] current_state;

    // ✅ Moore FSM DUT 인스턴스
    fsm_moore dut (
        .clk(clk),
        .rstn(rstn),
        .done(done),
        .ack(ack),
        .current_state(current_state)
    );

    // ✅ 클럭 생성: 10ns 주기 (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // ✅ 시뮬레이션 시나리오
    initial begin
        $dumpfile("fsm_moore_tb.vcd");  // 파형 저장 파일
        $dumpvars(0, tb_fsm_moore);

        // 초기값
        rstn = 0;
        done = 0;

        // 리셋 해제
        #20 rstn = 1;

        // 상태 전이 순서 (Moore FSM 기준)
        #10 done = 0; // READY 유지
        #10 done = 1; // TRANS로 전이
        #10 done = 1; // WRITE로 전이
        #10 done = 1; // READ로 전이
        #10 done = 1; // READY로 전이
        #10 done = 1; // TRANS로 전이
        #10 done = 0; // TRANS 유지
        #10 done = 1; // WRITE로 전이
        #10 done = 1; // READ로 전이
        #10 done = 0; // READ 유지
        #10 done = 1; // READY로 전이

        // 리셋 테스트
        #10 rstn = 0;
        #10 rstn = 1;
        #20 done = 0;

        #20 $finish;
    end

endmodule
