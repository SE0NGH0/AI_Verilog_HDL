`timescale 1ns / 1ps


module pattern_detector_fsm (
    input wire clk,
    input wire rst,
    input wire in1,             // btnU → 1
    input wire in0,             // btnD → 0
    output reg [15:0] led       // led[6:0]: 입력 표시, led[14]: 11 감지, led[15]: 00 감지
);

    // 상태 정의
    parameter S_IDLE = 2'b00;
    parameter S_1ST  = 2'b01;

    reg [1:0] current_state, next_state;

    reg prev_bit;
    reg din_bit;
    reg input_valid;

    // 입력 디코딩
    always @(*) begin
        if (in1) begin
            din_bit = 1'b1;
            input_valid = 1'b1;
        end else if (in0) begin
            din_bit = 1'b0;
            input_valid = 1'b1;
        end else begin
            input_valid = 1'b0;
        end
    end

    // 입력 시프트 저장 레지스터 (입력값 자체 shift)
    reg [6:0] input_shift;

    // 상태 전이 및 출력 동작
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= S_IDLE;
            prev_bit <= 1'b0;
            input_shift <= 7'b0000000;
            led[15:14] <= 2'b00;
        end else begin
            current_state <= next_state;

            if (input_valid) begin
                // ⬅ 왼쪽으로 입력값 shift (0 또는 1 입력 반영)
                input_shift <= {input_shift[5:0], din_bit};

                // 이전 입력과 비교하여 패턴 감지
                if (din_bit == 1'b0 && prev_bit == 1'b0) begin
                    led[15] <= 1'b1;  // 00
                    led[14] <= 1'b0;
                end else if (din_bit == 1'b1 && prev_bit == 1'b1) begin
                    led[15] <= 1'b0;
                    led[14] <= 1'b1;  // 11
                end else begin
                    led[15] <= 1'b0;
                    led[14] <= 1'b0;  // 01 or 10
                end

                prev_bit <= din_bit;
            end
        end
    end

    // 상태 천이 및 출력 결합
    always @(*) begin
        next_state = current_state;

        case (current_state)
            S_IDLE: begin
                if (input_valid)
                    next_state = S_1ST;
            end

            S_1ST: begin
                next_state = S_1ST;
            end
        endcase

        // 입력 시프트값 출력 연결
        led[6:0] = input_shift;
        // 나머지 led[13:7]는 0으로 유지
    end

endmodule
