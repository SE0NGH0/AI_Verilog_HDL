`timescale 1ns / 1ps

module data_sender(
    input        clk,
    input        reset,
    input [13:0] send_data,       // 거리(cm)
    input        start_trigger,   // 1초마다 거리 출력 시작
    input        tx_done,
    input        tx_busy,

    output reg       tx_start,
    output reg [7:0] tx_data
);

    reg [7:0] message [0:13];      // "Dist: xxxxcm\r\n" → 총 14바이트
    reg [3:0] msg_index;           // 출력할 문자 위치 인덱스
    reg [13:0] latched_data;       // 거리값 latch

    // 숫자 변환용
    reg [7:0] digit_ascii [3:0];

    function [7:0] to_ascii(input [3:0] value);
        begin
            case (value)
                4'd0: to_ascii = "0";
                4'd1: to_ascii = "1";
                4'd2: to_ascii = "2";
                4'd3: to_ascii = "3";
                4'd4: to_ascii = "4";
                4'd5: to_ascii = "5";
                4'd6: to_ascii = "6";
                4'd7: to_ascii = "7";
                4'd8: to_ascii = "8";
                4'd9: to_ascii = "9";
                default: to_ascii = "0";
            endcase
        end
    endfunction

    // 거리값 -> ASCII 문자 배열 변환
    always @(*) begin
        digit_ascii[0] = to_ascii(send_data / 1000);
        digit_ascii[1] = to_ascii((send_data % 1000) / 100);
        digit_ascii[2] = to_ascii((send_data % 100) / 10);
        digit_ascii[3] = to_ascii(send_data % 10);
    end

    // 메시지 준비
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            msg_index <= 0;
            tx_data   <= 8'd0;
            tx_start  <= 0;
        end else begin
            tx_start <= 0;

            if (start_trigger && !tx_busy) begin
                latched_data <= send_data;

                // 메시지 구성
                message[0]  <= "D";
                message[1]  <= "i";
                message[2]  <= "s";
                message[3]  <= "t";
                message[4]  <= ":";
                message[5]  <= " ";
                message[6]  <= digit_ascii[0];
                message[7]  <= digit_ascii[1];
                message[8]  <= digit_ascii[2];
                message[9]  <= digit_ascii[3];
                message[10] <= "c";
                message[11] <= "m";
                message[12] <= "\r"; // Carriage Return
                message[13] <= "\n"; // Line Feed

                msg_index <= 0;
                tx_data   <= message[0];
                tx_start  <= 1;
            end
            else if (tx_done && msg_index < 13) begin
                msg_index <= msg_index + 1;
                tx_data   <= message[msg_index + 1];
                tx_start  <= 1;
            end
        end
    end

endmodule
