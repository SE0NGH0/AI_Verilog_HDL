`timescale 1ns / 1ps

module tb_pattern_detector;

    reg clk;
    reg rst;
    reg btnU;
    reg btnD;
    wire [15:0] led;

    pattern_detector_top uut (
        .clk(clk),
        .rst(rst),
        .btnU(btnU),
        .btnD(btnD),
        .led(led)
    );

    // 100 MHz 클럭
    always #5 clk = ~clk;

    initial begin
        $display("=== Pattern Detector Testbench ===");
        $dumpfile("dump.vcd");    // Optional for GTKWave
        $dumpvars(0, tb_pattern_detector);

        clk = 0;
        rst = 1;
        btnU = 0;
        btnD = 0;

        #50;  // 리셋 유지
        rst = 0;

        // 입력: 1
        btnU = 1; #20; btnU = 0; #20;

        // 입력: 0
        btnD = 1; #20; btnD = 0; #20;

        // 입력: 0
        btnD = 1; #20; btnD = 0; #20;

        // 입력: 1
        btnU = 1; #20; btnU = 0; #20;

        // 입력: 0
        btnD = 1; #20; btnD = 0; #20;

        // 입력: 1
        btnU = 1; #20; btnU = 0; #20;

        // 입력: 1
        btnU = 1; #20; btnU = 0; #20;

        #200;  // 충분한 관찰 시간
        $finish;
    end

endmodule
