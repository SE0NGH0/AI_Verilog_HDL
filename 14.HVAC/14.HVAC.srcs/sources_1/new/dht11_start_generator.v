`timescale 1ns / 1ps

module dht11_start_generator (
    input wire clk,
    input wire reset,
    input wire tick_1Hz,     // 1초마다 펄스 입력
    output reg start         // 1클럭 펄스 출력
);

    reg tick_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tick_prev <= 1'b0;
            start <= 1'b0;
        end else begin
            tick_prev <= tick_1Hz;

            // tick_1Hz의 상승 엣지 감지 시 start 펄스 발생
            if (tick_1Hz && !tick_prev)
                start <= 1'b1;
            else
                start <= 1'b0;
        end
    end

endmodule
