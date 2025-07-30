`timescale 1ns / 1ps

module tb_uart_tx();

    reg clk;
    reg reset;
    reg [7:0] tx_data;
    reg tx_start;
    wire  tx;
    wire  tx_done;
    wire  tx_busy;

    uart_tx  u_uart_tx (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_done(tx_done),
        .tx_busy(tx_busy)
    );

    initial  clk=0;
    always #5 clk = ~clk;

    initial begin
        #100 reset=1;
        #50;
         reset=0;
         // '5' ==> 0x35 00110101
         tx_data = 8'b00110101;  // '5'
         tx_start = 1'b1;
        #20;
         tx_start = 1'b0;
         wait (!tx_busy);  // tx_data가 전송 완료 될떄 까지 wait
        #50
          // '7' ==> 0x37 00110111
         tx_data = 8'b00110111;  // '7'
         tx_start = 1'b1;
        #30;
         tx_start = 1'b0;
         wait (!tx_busy);  // tx_data가 전송 완료 될떄 까지 wait
        #20 
        $display("UART TX test finish");
        $finish;
    end 


endmodule
