`timescale 1ns / 1ps

module one_pulse (
    input  wire clk,
    input  wire btn_in,
    output reg  pulse_out
);

    reg btn_delay;

    always @(posedge clk) begin
        btn_delay <= btn_in;
        pulse_out <= btn_in & ~btn_delay;
    end

endmodule
