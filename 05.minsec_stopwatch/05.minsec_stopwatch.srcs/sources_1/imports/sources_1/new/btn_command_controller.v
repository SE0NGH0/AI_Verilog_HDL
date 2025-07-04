`timescale 1ns / 1ps

module btn_command_controller(
    input clk,
    input reset, // btnU
    input [2:0] btn, // btn[0] : L btn[1] : C btn[2] : R
    output [13:0] seg_data,
    output reg [15:0] led,
    output [2:0] mode
    );

    // mode
    parameter IDLE_MODE = 3'b000;
    parameter MINSEC_WATCH = 3'b001;
    parameter STOPWATCH = 3'b010;

    reg [2:0] prev_btnL = 3'b000;
    reg [2:0] r_mode = 3'b000;
    reg [19:0] counter;
    reg [13:0] ms10_counter;
    reg clear = 0;
    reg run_state = 0;

    reg [7:0] sec_counter;
    reg [7:0] min_counter;
    reg [31:0] minsec_counter;

    // mode check
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_mode <= 0;
            prev_btnL[0] <= 0;
        end else begin
            if (btn[0] && !prev_btnL[0]) begin // 처음 눌러진 상태
                r_mode <= (r_mode == STOPWATCH) ? IDLE_MODE : r_mode + 1;
            end
            prev_btnL[0] <= btn[0];
        end
    end

    // run/stop
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            run_state <= 0;
            prev_btnL[1] <= 0;
        end else begin
            if (btn[1] && !prev_btnL[1]) begin // 처음 눌러진 상태
                run_state <= ~run_state;
            end
            prev_btnL[1] <= btn[1];
        end
    end

    // clear
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_btnL[2] <= 0;
            clear <= 0;
        end else begin
            if (btn[2] && !prev_btnL[2]) // 처음 눌러진 상태
                clear <= ~clear;
            else
                clear <= 0;
            prev_btnL[2] <= btn[2];
        end
    end

    // STOPWATCH
    always @(posedge clk or posedge reset) begin
        if (reset || clear) begin
            counter <= 0;
            ms10_counter <= 0;
        end else if (r_mode == STOPWATCH) begin
            if (counter == 20'd1_000_000-1) begin // 10ms
                ms10_counter <= ms10_counter + 1;
                counter <= 0;
            end else begin
                if (run_state)
                    counter <= counter + 1;
            end
        end else begin
            ms10_counter <= 0;
            counter <= 0;
        end
    end

    // MINSEC_WATCH
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sec_counter <= 0;
            min_counter <= 0;
            minsec_counter <= 0;
        end else if (r_mode == MINSEC_WATCH) begin
            if (minsec_counter == 32'd1_000_000-1) begin
                minsec_counter <= 0;
                if (sec_counter == 8'd59) begin
                    sec_counter <= 0;
                    min_counter <= min_counter + 1;
                end else begin
                    sec_counter <= sec_counter + 1;
                end
            end else begin
                minsec_counter <= minsec_counter + 1;
            end
        end else begin
            minsec_counter <= 0;
            sec_counter <= 0;
            min_counter <= 0;
        end
    end

    always @(r_mode) begin
        case (r_mode)
            IDLE_MODE: begin
                led[15:13] = 3'b100;
            end
            MINSEC_WATCH: begin
                led[15:13] = 3'b010;
            end
            STOPWATCH: begin
                led[15:13] = 3'b001;
            end
            default: led[15:13] = 3'b000;
        endcase
    end

    assign seg_data = (r_mode == IDLE_MODE) ? 14'd7777 :
                      (r_mode == MINSEC_WATCH) ? (min_counter*14'd60 + sec_counter) : ms10_counter;

endmodule
