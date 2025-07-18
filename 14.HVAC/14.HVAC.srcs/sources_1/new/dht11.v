`timescale 1ns / 1ps

module dht11 (
    input wire clk,
    input wire reset,
    input wire start,              // 측정 시작 트리거 (1펄스)
    inout wire dht11_data,        // DHT11 bidirectional pin
    output reg [7:0] temperature,
    output reg [7:0] humidity,
    output reg done,              // 측정 완료 (1)
    output reg error              // 에러 발생 시 1
);

    // 타이밍 파라미터 (100MHz 기준)
    localparam CLK_1US  = 100;
    localparam CLK_20MS = 2_000_000;
    localparam CLK_80US = 8000;
    localparam CLK_40US = 4000;
    localparam CLK_70US = 7000;

    // 상태 정의
    localparam [3:0]
        S_IDLE       = 4'd0,
        S_START_LOW  = 4'd1,
        S_START_HIGH = 4'd2,
        S_WAIT_RESP_LOW = 4'd3,
        S_WAIT_RESP_HIGH = 4'd4,
        S_READ_LOW   = 4'd5,
        S_READ_HIGH  = 4'd6,
        S_STORE_BIT  = 4'd7,
        S_COMPLETE   = 4'd8,
        S_ERROR      = 4'd9;

    reg [3:0] state;
    reg [19:0] timer;
    reg [5:0] bit_index;
    reg [39:0] data_buf;

    reg dht11_out_en, dht11_out;
    wire dht11_in;

    assign dht11_data = dht11_out_en ? dht11_out : 1'bz;
    assign dht11_in = dht11_data;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            timer <= 0;
            bit_index <= 0;
            data_buf <= 0;
            dht11_out_en <= 0;
            dht11_out <= 1;
            done <= 0;
            error <= 0;
            temperature <= 0;
            humidity <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    error <= 0;
                    if (start) begin
                        dht11_out_en <= 1;
                        dht11_out <= 0;
                        timer <= 0;
                        state <= S_START_LOW;
                    end
                end

                S_START_LOW: begin
                    if (timer < CLK_20MS) begin
                        timer <= timer + 1;
                    end else begin
                        dht11_out <= 1;
                        dht11_out_en <= 0;
                        timer <= 0;
                        state <= S_WAIT_RESP_LOW;
                    end
                end

                S_WAIT_RESP_LOW: begin
                    if (!dht11_in) begin
                        timer <= 0;
                        state <= S_WAIT_RESP_HIGH;
                    end else if (timer > CLK_80US) begin
                        error <= 1;
                        state <= S_ERROR;
                    end else begin
                        timer <= timer + 1;
                    end
                end

                S_WAIT_RESP_HIGH: begin
                    if (dht11_in) begin
                        timer <= 0;
                        state <= S_READ_LOW;
                    end else if (timer > CLK_80US) begin
                        error <= 1;
                        state <= S_ERROR;
                    end else begin
                        timer <= timer + 1;
                    end
                end

                S_READ_LOW: begin
                    if (!dht11_in) begin
                        timer <= 0;
                        state <= S_READ_HIGH;
                    end
                end

                S_READ_HIGH: begin
                    if (dht11_in) begin
                        timer <= 0;
                        state <= S_STORE_BIT;
                    end
                end

                S_STORE_BIT: begin
                    timer <= timer + 1;
                    if (!dht11_in) begin
                        data_buf[39 - bit_index] <= (timer > CLK_40US);
                        bit_index <= bit_index + 1;
                        timer <= 0;

                        if (bit_index == 39) begin
                            state <= S_COMPLETE;
                        end else begin
                            state <= S_READ_LOW;
                        end
                    end else if (timer > CLK_70US) begin
                        error <= 1;
                        state <= S_ERROR;
                    end
                end

                S_COMPLETE: begin
                    humidity    <= data_buf[39:32];
                    temperature <= data_buf[23:16];
                    done <= 1;
                    state <= S_IDLE;
                end

                S_ERROR: begin
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
