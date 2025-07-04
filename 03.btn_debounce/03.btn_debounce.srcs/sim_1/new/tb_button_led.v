// tb_button_debouncer.v
`timescale 1ns / 1ps

module tb_button_debouncer;

    // ------------------------------------------------------
    // 1) Signals
    reg  clk        = 0;
    reg  reset      = 1;
    reg  noisy_btn  = 0;
    wire tick_1ms;
    wire clean_btn;

    // ------------------------------------------------------
    // 2) Instantiate the 1 kHz tick generator
    tick_generator u_tick (
        .clk   (clk),
        .reset (reset),
        .tick  (tick_1ms)
    );

    // ------------------------------------------------------
    // 3) Instantiate the debouncer under test
    button_debouncer u_db (
        .clk       (clk),
        .reset     (reset),
        .noisy_btn (noisy_btn),
        .clean_btn (clean_btn)
    );

    // ------------------------------------------------------
    // 4) 100 MHz clock
    always #5 clk = ~clk;

    // ------------------------------------------------------
    // 5) Stimulus: reset, press with hold, release with hold
    initial begin
        // hold reset for 100 ns
        #100;
        reset = 0;

        // at t≈100 ns, press the button
        noisy_btn = 1;
        // hold for 30 ms
        #30_000_000;
        // release the button
        noisy_btn = 0;
        // hold released for 20 ms
        #20_000_000;
        // finish simulation
        $finish;
    end

endmodule
