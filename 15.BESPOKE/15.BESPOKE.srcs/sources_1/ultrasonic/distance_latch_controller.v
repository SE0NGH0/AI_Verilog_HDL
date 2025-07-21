`timescale 1ns / 1ps

module distance_latch_controller (
    input wire clk,
    input wire reset,
    input wire [13:0] distance_cm,
    input wire done,  // 거리 측정 완료 신호

    output wire [13:0] latched_distance
);

    reg done_d;
    reg [13:0] distance_reg;

    // rising edge 감지
    wire done_rising = done & ~done_d;

    always @(posedge clk or posedge reset) begin
        if (reset)
            done_d <= 0;
        else
            done_d <= done;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            distance_reg <= 0;
        else if (done_rising)
            distance_reg <= distance_cm[13:0];
    end

    assign latched_distance = distance_reg;

endmodule
