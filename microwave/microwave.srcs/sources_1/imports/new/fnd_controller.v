`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input reset,
    input sw,              // 0: Rotate Mode, 1: Time Control Mode
    input pulse_U,         // Increase timer
    input pulse_D,         // Decrease timer
    input pulse_run,       // Start/Stop timer

    output reg [13:0] sw_time,     // Timer value
    output reg sw_state,           // Timer running status
    output [6:0] seg_data,
    output [3:0] an
);

    wire tick_1s;
    wire [6:0] seg_mode0;
    wire [3:0] an_mode0;

    reg [3:0] digit;
    reg [3:0] an_mode1;
    reg [6:0] seg_mode1;
    reg [19:0] refresh_counter;

    
    clk_division_1s u_clk_div (
        .clk(clk),
        .rst(reset),
        .sw_state(sw_state),
        .tick(tick_1s)
    );

    
    fnd_rotate u_rotate (
        .clk(clk),
        .reset(reset),
        .seg(seg_mode0),
        .an(an_mode0)
    );

    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sw_state <= 0;
            sw_time <= 0;
        end else if (sw == 1'b1) begin
            if (pulse_run) begin
                sw_state <= ~sw_state;
            end

            if (pulse_U) begin
                sw_time <= sw_time + 30;
            end else if (pulse_D) begin
                if (sw_time >= 30)
                    sw_time <= sw_time - 30;
                else
                    sw_time <= 0;
            end

            if (sw_state && tick_1s) begin
                if (sw_time > 0)
                    sw_time <= sw_time - 1;
                else
                    sw_state <= 0;  // 자동 정지
            end
        end else begin
            sw_state <= 0;
            sw_time <= 0;
        end
    end

    
    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_counter <= 0;
        else if (sw == 1'b1)
            refresh_counter <= refresh_counter + 1;
        else
            refresh_counter <= 0;
    end

    always @(*) begin
        if (sw == 1'b1) begin
            case (refresh_counter[19:18])
                2'b00: begin
                    an_mode1 = 4'b0111;
                    digit = sw_time / 1000;
                end
                2'b01: begin
                    an_mode1 = 4'b1011;
                    digit = (sw_time % 1000) / 100;
                end
                2'b10: begin
                    an_mode1 = 4'b1101;
                    digit = (sw_time % 100) / 10;
                end
                2'b11: begin
                    an_mode1 = 4'b1110;
                    digit = sw_time % 10;
                end
                default: begin
                    an_mode1 = 4'b1111;
                    digit = 0;
                end
            endcase
        end else begin
            an_mode1 = 4'b1111;
            digit = 4'd0;
        end
    end

   
    always @(*) begin
        case (digit)
            4'd0: seg_mode1 = 8'b11000000; //0
            4'd1: seg_mode1 = 8'b11111001; //1
            4'd2: seg_mode1 = 8'b10100100; //2
            4'd3: seg_mode1 = 8'b10110000; //3
            4'd4: seg_mode1 = 8'b10011001; //4
            4'd5: seg_mode1 = 8'b10010010; //5
            4'd6: seg_mode1 = 8'b10000010; //6
            4'd7: seg_mode1 = 8'b11111000; //7
            4'd8: seg_mode1 = 8'b10000000; //8
            4'd9: seg_mode1 = 8'b10010000; //9
            default: seg_mode1 = 8'b11111111;
        endcase
    end

    
    assign seg_data = (sw == 1'b1) ? seg_mode1 : seg_mode0;
    assign an       = (sw == 1'b1) ? an_mode1   : an_mode0;

endmodule
module clk_division_1s (
    input clk,
    input rst,
    input sw_state,
    output reg tick
);
    reg [26:0] cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin cnt <= 0; tick <= 0; end
        else if (sw_state) begin
            if (cnt == 100_000_000 - 1) begin
                cnt <= 0;
                tick <= 1;
            end else begin
                cnt <= cnt + 1;
                tick <= 0;
            end
        end else begin
            cnt <= 0;
            tick <= 0;
        end
    end
endmodule
module fnd_rotate (
    input clk,
    input reset,
    output reg [6:0] seg,
    output reg [3:0] an
);
    reg [3:0] step = 0;
    reg [26:0] counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin step <= 0; counter <= 0; end
        else if (counter == 10_000_000 - 1) begin
            counter <= 0;
            step <= (step == 11) ? 0 : step + 1;
        end else begin
            counter <= counter + 1;
        end
    end

    always @(*) begin
        case(step)
            0: begin an = 4'b0111; seg = 8'b11011111; end
            1: begin an = 4'b0111; seg = 8'b11111110; end
            2: begin an = 4'b1011; seg = 8'b11111110; end
            3: begin an = 4'b1101; seg = 8'b11111110; end
            4: begin an = 4'b1110; seg = 8'b11111110; end
            5: begin an = 4'b1110; seg = 8'b11111101; end
            6: begin an = 4'b1110; seg = 8'b11111011; end
            7: begin an = 4'b1110; seg = 8'b11110111; end
            8: begin an = 4'b1101; seg = 8'b11110111; end
            9: begin an = 4'b1011; seg = 8'b11110111; end
            10:begin an = 4'b0111; seg = 8'b11110111; end
            11:begin an = 4'b0111; seg = 8'b11101111; end
            default: begin an = 4'b1111; seg = 8'b11111111; end
        endcase
    end
endmodule
