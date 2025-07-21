`timescale 1ns / 1ps

module ultra_buzzer_controller(
    input clk,
    input reset,
    input hvac_enable,
    input [13:0] distance,  // cm 단위 거리 입력
    output reg buzzer_out
);

    always @(posedge clk or posedge reset or negedge hvac_enable) begin
        if (reset || !hvac_enable)
            buzzer_out <= 0;
        else begin
            if (distance <= 14'd5)  // 5cm 이하일 때 ON
                buzzer_out <= 1;
            else
                buzzer_out <= 0;
        end
    end

endmodule
