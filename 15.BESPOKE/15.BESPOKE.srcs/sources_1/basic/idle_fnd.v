`timescale 1ns / 1ps

module fnd_rotate (
    input clk,
    input reset,
    input idle_enable,
    output reg [7:0] seg,
    output reg [3:0] an
);

    reg [3:0] step;
    reg [26:0] counter;  // 100MHz 기준, 0.5초 주기 = 50_000_000

    always @(posedge clk or posedge reset or negedge idle_enable) begin
        if (reset || !idle_enable) begin
            counter <= 0;
            step <= 0;
        end else begin
            if (counter >= 50_000_000 - 1) begin
                counter <= 0;
                step <= (step == 11) ? 0 : step + 1;  // 0~11까지 순환
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always @(*) begin
        case(step)
            0: begin an = 4'b0111; seg = 8'b11011111; end
            1: begin an = 4'b0111; seg = 8'b11111110; end
            2: begin an = 4'b1011; seg = 8'b11111110; end
            3: begin an = 4'b1101; seg = 8'b11111110; end
            4: begin an = 4'b1110; seg = 8'b11111110; end
            5: begin an = 4'b1110; seg = 8'b11111101; end
            6: begin an = 4'b1110; seg = 8'b11111011; end
            7: begin an = 4'b1110; seg = 8'b11110111; end
            8: begin an = 4'b1101; seg = 8'b11110111; end
            9: begin an = 4'b1011; seg = 8'b11110111; end
            10:begin an = 4'b0111; seg = 8'b11110111; end
            11:begin an = 4'b0111; seg = 8'b11101111; end
            default: begin an = 4'b1111; seg = 8'b11111111; end
        endcase
    end

endmodule
