`timescale 1ns / 1ps

module hcsr04_buzzer (
    input wire clk,
    input wire reset,
    input wire [15:0] distance_cm,
    input wire valid,           // 거리 유효 플래그 (ex: hcsr04의 done)
    output reg buzzer
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            buzzer <= 0;
        else if (valid) begin
            if (distance_cm <= 5)
                buzzer <= 1;
            else
                buzzer <= 0;
        end
    end

endmodule
