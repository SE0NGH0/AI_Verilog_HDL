module hcsr04(
    input wire clk,
    input wire reset,
    input wire start,                // 외부에서 측정 시작 신호
    output reg trig,
    input wire echo,
    output reg [13:0] distance_cm,
    output reg done                  // 1클럭만 high
);

    parameter CLK_FREQ = 100_000_000;
    parameter TRIG_PULSE = 1000;
    parameter TIMEOUT_CYCLE = 30_000_000;

    reg [31:0] cnt;
    reg [2:0] state;

    localparam IDLE            = 3'd0;
    localparam TRIG_ON         = 3'd1;
    localparam WAIT_ECHO_HIGH  = 3'd2;
    localparam MEASURE         = 3'd3;
    localparam DONE            = 3'd4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            trig <= 0;
            cnt <= 0;
            distance_cm <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    trig <= 0;
                    done <= 0;
                    cnt <= 0;
                    if (start) begin                 // start 신호 있을 때만 시작
                        state <= TRIG_ON;
                    end
                end

                TRIG_ON: begin
                    trig <= 1;
                    cnt <= cnt + 1;
                    if (cnt >= TRIG_PULSE) begin
                        trig <= 0;
                        cnt <= 0;
                        state <= WAIT_ECHO_HIGH;
                    end
                end

                WAIT_ECHO_HIGH: begin
                    if (echo) begin
                        cnt <= 0;
                        state <= MEASURE;
                    end else begin
                        cnt <= cnt + 1;
                        if (cnt >= TIMEOUT_CYCLE) begin
                            distance_cm <= 0;
                            state <= DONE;
                        end
                    end
                end

                MEASURE: begin
                    if (echo) begin
                        cnt <= cnt + 1;
                        if (cnt >= TIMEOUT_CYCLE) begin
                            distance_cm <= 0;
                            state <= DONE;
                        end
                    end else begin
                        distance_cm <= cnt / 5800;  // 거리 계산
                        state <= DONE;
                    end
                end

                DONE: begin
                    done <= 1;       // 1클럭만 HIGH
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
