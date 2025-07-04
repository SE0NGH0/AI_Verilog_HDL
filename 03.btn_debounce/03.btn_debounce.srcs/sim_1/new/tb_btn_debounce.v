`timescale 1ns / 1ps

module tb_btn_debounce;
    reg clk;
    reg reset;
    reg btn;
    wire led;

    button_debounce u0_button_debounce(
    .i_clk(clk),
    .i_reset(reset),
    .i_btn(btn),
    .o_led(led)
    );

    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        #0 reset = 0; btn = 0;
        #10 reset = 1; 
        #20 reset = 0; btn = 1;
        #20 btn = 0;
        #20 btn = 1;
        #20 btn = 0;
        #20 btn = 1;
        #20 btn = 0;
        #20 btn = 1;
        #30_000_000 btn = 0;
        #20 btn = 1;
        #20 btn = 0;
        #20 btn = 1;
        #20 btn = 0;
        #20 btn = 1;
        #10 btn = 0;
        #30_000_000;
        $stop;
    end
endmodule
