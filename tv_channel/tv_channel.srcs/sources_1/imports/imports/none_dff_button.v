`timescale 1ns / 1ps

module none_dff_button(
    input i_clk,
    input i_reset,
    input [3:0] i_noisy_btn,
    output reg [3:0] o_clean_btn
    );

    wire w_tick;
    reg [3:0] prev_btn; // 이전버튼 상태 저장하는 변수

    // reg o_clean_btn;
    // IDLE 상태에서 버튼을 누르면 --> high
    // 10ms 걸어줌
    // 10ms 뒤에 검사, 그때도 high --> high 출력(버튼이 눌린 상태)
    // 버튼을 떼면,, high --> low, 10ms 타이머 걸어줌
    // 마찬가지로 10ms 뒤에 검사, 그때도 low --> low 출력(버튼이 떼진 상태)
    
    // 100Hz, 10ms 타이머
    tick_generator #(
        .TICK_HZ(100)
    ) u_tick_generator (
        .clk(i_clk),
        .reset(i_reset),
        .tick(w_tick)
    );

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            o_clean_btn <= 4'b0000;
            prev_btn <= 4'b0000;
        end else if (w_tick) begin

            if (i_noisy_btn[0] == 1'b1 && prev_btn[0] == 1'b1) begin
                o_clean_btn[0] <= 1'b1;  // 10 ms 유지 후 출력 
            end
            else if (i_noisy_btn[0] == 1'b0 && prev_btn[0] == 1'b0) begin
                o_clean_btn[0] <= 1'b0;  // 10 ms 유지 후 출력
            end

            if (i_noisy_btn[1] == 1'b1 && prev_btn[1] == 1'b1) begin
                o_clean_btn[1] <= 1'b1;  // 10 ms 유지 후 출력 
            end
            else if (i_noisy_btn[1] == 1'b0 && prev_btn[1] == 1'b0) begin
                o_clean_btn[1] <= 1'b0;  // 10 ms 유지 후 출력
            end

            if (i_noisy_btn[2] == 1'b1 && prev_btn[2] == 1'b1) begin
                o_clean_btn[2] <= 1'b1;  // 10 ms 유지 후 출력 
            end
            else if (i_noisy_btn[2] == 1'b0 && prev_btn[2] == 1'b0) begin
                o_clean_btn[2] <= 1'b0;  // 10 ms 유지 후 출력
            end

            if (i_noisy_btn[3] == 1'b1 && prev_btn[3] == 1'b1) begin
                o_clean_btn[3] <= 1'b1;  // 10 ms 유지 후 출력 
            end
            else if (i_noisy_btn[3] == 1'b0 && prev_btn[3] == 1'b0) begin
                o_clean_btn[3] <= 1'b0;  // 10 ms 유지 후 출력
            end            
        end
            else begin 
                prev_btn <= i_noisy_btn;  // 버튼상태 샘플링
        end
    end

endmodule

