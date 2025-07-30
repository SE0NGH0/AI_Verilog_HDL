`timescale 1ns / 1ps

module rotary(
    input clk,
    input reset,
    input clean_s1,
    input clean_s2,
    input clean_key,
    output [15:0] led
    );

    reg [1:0] r_prev_state = 2'b00;
    reg [1:0] r_curr_state = 2'b00;
    reg [1:0] r_direction = 2'b00;
    reg [7:0] r_count = 8'h00;

    reg [15:0] r_led = 16'b0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_prev_state <= 2'b00;
            r_curr_state <= 2'b00;
            r_direction <= 2'b00;
            r_count <= 8'h00;
            r_led <= 16'b0;
        end else begin
            r_prev_state <= r_curr_state;
            r_curr_state <= {clean_s1, clean_s2};

            case ({r_prev_state, r_curr_state})

            4'b0010, 4'b1011, 4'b1101, 4'b0100: begin // CW 00 -> 10 -> 11 -> 01 -> 00
                if (r_count < 8'hFF) // overflow 방지
                    r_count <= r_count + 1;
                r_direction <= 2'b01;
            end

            4'b0001, 4'b0111, 4'b1110, 4'b1000: begin // CCW 00 -> 01 -> 11 -> 10 -> 00
                if (r_count > 8'h00) // underflow 방지
                    r_count <= r_count - 1;
                r_direction <= 2'b10;
            end

            endcase

            // clean_key ON/OFF 제어
            r_led[13] <= ~clean_key;

            // LED 출력 구성
            r_led[15:14] <= r_direction;
            r_led[12:8]  <= 5'b0;
            r_led[7:0]   <= r_count;

        end
    end

    assign led = r_led;

endmodule
