`timescale 1ns / 1ps

module dht11_data_sender (
    input wire clk,
    input wire reset,
    input wire done,               // dht11_done
    input wire [7:0] temp_data,    // t_data
    input wire [7:0] humi_data,    // rh_data
    input wire tx_busy,            // UART busy
    input wire [1:0] mode,         // 현재 mode

    output reg tx_start,
    output reg [7:0] tx_data,
    output reg busy,
    output reg [1:0] led
);

    localparam IDLE    = 2'd0;
    localparam PREPARE = 2'd1;
    localparam SEND    = 2'd2;

    reg [1:0] state, next_state;
    reg [7:0] message [0:21];
    reg [4:0] msg_index;
    reg [7:0] digit_ascii [3:0];

    // ASCII 변환 함수
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
            default: to_ascii = "?";
        endcase
    endfunction

    // done edge 감지 (단, mode == 2일 때만 latch)
    reg done_prev, done_latched;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done_prev <= 1'b0;
            done_latched <= 1'b0;
        end else begin
            done_prev <= done;
            if (done && !done_prev && mode == 2)
                done_latched <= 1'b1;
            else if (state == PREPARE)
                done_latched <= 1'b0;
        end
    end

    // 상태 전이 FSM
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 다음 상태 결정
    always @(*) begin
        tx_start = 1'b0;
        busy = 1'b0;
        led = state;
        next_state = state;

        case (state)
            IDLE: begin
                busy = 0;
                if (done_latched)
                    next_state = PREPARE;
            end

            PREPARE: begin
                busy = 1;
                next_state = SEND;
            end

            SEND: begin
                busy = 1;
                if (msg_index >= 22)
                    next_state = IDLE;
            end
        endcase
    end

    // 메시지 구성 및 송신
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            msg_index <= 0;
            tx_data <= 8'd0;
            tx_start <= 1'b0;
        end else begin
            tx_start <= 1'b0;

            case (state)
                PREPARE: begin
                    digit_ascii[0] = to_ascii(temp_data / 10);
                    digit_ascii[1] = to_ascii(temp_data % 10);
                    digit_ascii[2] = to_ascii(humi_data / 10);
                    digit_ascii[3] = to_ascii(humi_data % 10);

                    message[0]  <= "T";
                    message[1]  <= "e";
                    message[2]  <= "m";
                    message[3]  <= "p";
                    message[4]  <= ":";
                    message[5]  <= " ";
                    message[6]  <= digit_ascii[0];
                    message[7]  <= digit_ascii[1];
                    message[8]  <= "C";
                    message[9]  <= ",";
                    message[10] <= " ";
                    message[11] <= "H";
                    message[12] <= "u";
                    message[13] <= "m";
                    message[14] <= "i";
                    message[15] <= ":";
                    message[16] <= " ";
                    message[17] <= digit_ascii[2];
                    message[18] <= digit_ascii[3];
                    message[19] <= "%";
                    message[20] <= "\r";
                    message[21] <= "\n";

                    msg_index <= 0;
                end

                SEND: begin
                    if (!tx_busy && msg_index < 22) begin
                        tx_data <= message[msg_index];
                        tx_start <= 1;
                        msg_index <= msg_index + 1;
                    end
                end
            endcase
        end
    end

endmodule
