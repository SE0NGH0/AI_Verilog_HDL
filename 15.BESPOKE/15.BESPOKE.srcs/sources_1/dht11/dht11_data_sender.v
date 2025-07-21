`timescale 1ns / 1ps

module dht11_data_sender(
    input        clk,
    input        reset,
    input [13:0] temperature,       // DHT11 온도값
    input [13:0] humidity,          // DHT11 습도값
    input        start_trigger,     // 1초마다 출력 트리거
    input        tx_done,
    input        tx_busy,

    output reg       tx_start,
    output reg [7:0] tx_data
);

    reg [7:0] message [0:24];      // "Temp:xxxxC Humi:xxxx%\r\n" → 총 23바이트
    reg [4:0] msg_index;           // 출력할 문자 위치 인덱스
    reg [13:0] latched_temp, latched_humi;
    reg [7:0] temp_ascii[3:0];
    reg [7:0] humi_ascii[3:0];

    function [7:0] to_ascii(input [3:0] value);
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
    endfunction

    // 온도/습도 숫자 -> ASCII 변환
    always @(*) begin
        temp_ascii[0] = to_ascii(temperature / 1000);
        temp_ascii[1] = to_ascii((temperature % 1000) / 100);
        temp_ascii[2] = to_ascii((temperature % 100) / 10);
        temp_ascii[3] = to_ascii(temperature % 10);

        humi_ascii[0] = to_ascii(humidity / 1000);
        humi_ascii[1] = to_ascii((humidity % 1000) / 100);
        humi_ascii[2] = to_ascii((humidity % 100) / 10);
        humi_ascii[3] = to_ascii(humidity % 10);
    end

    // 메시지 준비 및 송신 FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_start <= 0;
            tx_data <= 8'd0;
            msg_index <= 0;
        end else begin
            tx_start <= 0;
            if (start_trigger && !tx_busy) begin
                latched_temp <= temperature;
                latched_humi <= humidity;

                message[0]  <= "T";
                message[1]  <= "e";
                message[2]  <= "m";
                message[3]  <= "p";
                message[4]  <= ":";
                message[5]  <= temp_ascii[0];
                message[6]  <= temp_ascii[1];
                message[7] <= ".";
                message[8]  <= temp_ascii[2];
                message[9]  <= temp_ascii[3];
                message[10]  <= "C";
                message[11] <= " ";
                message[12] <= "H";
                message[13] <= "u";
                message[14] <= "m";
                message[15] <= "i";
                message[16] <= ":";
                message[17] <= humi_ascii[0];
                message[18] <= humi_ascii[1];
                message[19] <= ".";
                message[20] <= humi_ascii[2];
                message[21] <= humi_ascii[3];
                message[22] <= "%";
                message[23] <= "\r";
                message[24] <= "\n";

                msg_index <= 0;
                tx_data   <= message[0];
                tx_start  <= 1;
            end else if (tx_done && msg_index < 22) begin
                msg_index <= msg_index + 1;
                tx_data   <= message[msg_index + 1];
                tx_start  <= 1;
            end
        end
    end

endmodule
