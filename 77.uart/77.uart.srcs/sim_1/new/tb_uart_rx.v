`timescale 1ns / 1ps

module tb_uart_rx();
    reg clk;
    reg reset;
    reg rx;
    wire [7:0] data_out;
    wire rx_done;

    uart_rx tb_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // bps : 9600bps
    // 1 bit 전송 time 1 / 9600 = 10417ns
    // 10426ns --> 10426ns / 2 --> 5208 
    localparam BAUD_PERIOD = (100_000_000 / 9600) * 10; // 10417ns

    always @(posedge rx_done) begin
        $display("1 byte received: %h time %t", data_out, $time);
    end
    // UART rx simulator
    initial begin
        #00 reset = 1; rx = 1; clk = 0;
        #100;
        reset = 0; // reset 해제
        #200; // after reset --> goto IDLE TIME
        //------- 'U' : 0x55 0101 0101 -------
        #BAUD_PERIOD rx = 0; // start bit 0
        #BAUD_PERIOD rx = 1; // bit0
        #BAUD_PERIOD rx = 0; // bit1
        #BAUD_PERIOD rx = 1; // bit2
        #BAUD_PERIOD rx = 0; // bit3
        #BAUD_PERIOD rx = 1; // bit4
        #BAUD_PERIOD rx = 0; // bit5
        #BAUD_PERIOD rx = 1; // bit6
        #BAUD_PERIOD rx = 0; // bit7
        #BAUD_PERIOD rx = 1; // stop bit 1
        #1000000; // 1ms 대기
        //------- 'u' : 0x55 0101 0101 -------
        #BAUD_PERIOD rx = 0; // start bit 0
        #BAUD_PERIOD rx = 1; // bit0
        #BAUD_PERIOD rx = 0; // bit1
        #BAUD_PERIOD rx = 1; // bit2
        #BAUD_PERIOD rx = 0; // bit3
        #BAUD_PERIOD rx = 1; // bit4
        #BAUD_PERIOD rx = 0; // bit5
        #BAUD_PERIOD rx = 1; // bit6
        #BAUD_PERIOD rx = 0; // bit7
        #BAUD_PERIOD rx = 1; // stop bit 1
        #1000000; // 1ms 대기
        $display("UART RX test finish");
        $finish;
    end

endmodule
