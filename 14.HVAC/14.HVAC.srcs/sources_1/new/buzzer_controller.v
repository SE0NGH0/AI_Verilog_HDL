`timescale 1ns / 1ps

module buzzer_controller(
    input wire clk,
    input wire reset,
    input wire [13:0] distance,  // cm 단위 거리 입력
    output reg buzzer_out
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            buzzer_out <= 0;
        else begin
            if (distance <= 14'd5)  // 5cm 이하일 때 ON
                buzzer_out <= 1;
            else
                buzzer_out <= 0;
        end
    end

endmodule
