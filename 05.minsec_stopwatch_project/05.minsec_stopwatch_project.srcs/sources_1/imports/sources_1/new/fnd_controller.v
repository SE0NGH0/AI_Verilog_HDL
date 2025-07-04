`timescale 1ns / 1ps

module fnd_controller(
    input clk,
    input [2:0] mode,
    input [13:0] in_data,
    input reset,
    output [3:0] an,
    output [7:0] seg
    );
    
    wire [1:0] w_sel;
    wire [3:0] w_fnd_1;
    wire [3:0] w_fnd_2;
    wire [3:0] w_fnd_3;
    wire [3:0] w_fnd_4;

    fnd_digit_select u_digit_select(
        .clk(clk),
        .reset(reset),
        .sel(w_sel)
    );

    digit_split u_digit_split(
        .in_data(in_data),
        .mode(mode),
        .fnd_1(w_fnd_1),
        .fnd_2(w_fnd_2),
        .fnd_3(w_fnd_3),
        .fnd_4(w_fnd_4)
    );

    fnd_digit_display u_digit_display(
        .digit_sel(w_sel),
        .fnd_1(w_fnd_1),
        .fnd_2(w_fnd_2),
        .fnd_3(w_fnd_3),
        .fnd_4(w_fnd_4),
        .mode(mode),
        .an(an),
        .seg(seg)
    );

endmodule

module fnd_digit_select(
    input clk,
    input reset,
    output reg [1:0] sel
);

    wire w_tick;
    reg [1:0] r_digit_sel = 0;
    
    // 1000Hz, 1ms 타이머
    tick_generator #(
        .TICK_HZ(1000)
    ) u_tick_generator (
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    always @(posedge w_tick or posedge reset) begin
        if(reset) begin
            r_digit_sel <= 0;
            sel <= 0;
        end else begin
            r_digit_sel <= r_digit_sel + 1;
            case (r_digit_sel)
                0 : sel <= 2'b00;
                1 : sel <= 2'b01;
                2 : sel <= 2'b10; 
                3 : sel <= 2'b11;    
            endcase
        end
    end

endmodule

module digit_split(
    input [13:0] in_data,
    input [2:0] mode,
    output [3:0] fnd_1,
    output [3:0] fnd_2,
    output [3:0] fnd_3,
    output [3:0] fnd_4
);

    parameter IDLE_MODE     = 3'b000;
    parameter MINSEC_WATCH  = 3'b001;
    parameter STOPWATCH     = 3'b010;

    // fnd용 숫자 변환 IDLE / MINSEC / STOPWATCH
    assign fnd_1 = (mode == IDLE_MODE) ? in_data[3:0] :
                   (mode == MINSEC_WATCH) ? in_data % 60 % 10 : in_data % 10;
   
    assign fnd_2 = (mode == IDLE_MODE) ? in_data[3:0] :
                   (mode == MINSEC_WATCH) ? (in_data % 60 ) / 10 % 10 : (in_data / 10) % 10;

    assign fnd_3 = (mode == IDLE_MODE) ? in_data[3:0] :
                   (mode == MINSEC_WATCH) ? (in_data / 60 ) % 10 : (in_data / 100) % 10;

    assign fnd_4 = (mode == IDLE_MODE) ? in_data[3:0] :
                   (mode == MINSEC_WATCH) ? (in_data / 60) / 10 % 10 : (in_data / 1000) % 10;

endmodule


module fnd_digit_display(
    input [1:0] digit_sel,
    input [3:0] fnd_1,
    input [3:0] fnd_2,
    input [3:0] fnd_3,
    input [3:0] fnd_4,
    input [2:0] mode,
    output reg [3:0] an,
    output reg [7:0] seg
);

    parameter IDLE_MODE     = 3'b000;
    parameter MINSEC_WATCH  = 3'b001;
    parameter STOPWATCH     = 3'b010;

    parameter IDLE_FND1 = 3'd0;
    parameter IDLE_FND2 = 3'd1;
    parameter IDLE_FND3 = 3'd2;
    parameter IDLE_FND4 = 3'd3;
    parameter BCD_MODE  = 3'd4;
    
    // FND display 출력
    reg [3:0] bcd_data;
    reg [3:0] circle_data1;
    reg [3:0] circle_data2;
    reg [3:0] circle_data3;
    reg [3:0] circle_data4;
    reg [2:0] display_mode; // display mode : 0 IDLE FND 1, 1 : IDLE FND 2, 2 : IDLE FND 3, 3 : IDLE FND 4, 4 : MINSEC, STOPWATCH

    always @(digit_sel) begin
        case (digit_sel)
            2'b00 : begin 
                an <= 4'b1110;
                if(mode == IDLE_MODE) begin
                    circle_data1 <= fnd_1; // circle 시계
                    display_mode <= 3'd0;
                end
                else begin
                    bcd_data <= fnd_1;     // stopwatch, minsec 시계
                    display_mode <= 3'd4;
                end
            end
            2'b01 : begin 
                an <= 4'b1101;
                if(mode == IDLE_MODE) begin
                    circle_data2 <= fnd_2; // circle 시계
                    display_mode <= 3'd1;
                end
                else begin
                    bcd_data <= fnd_2;
                    display_mode <= 3'd4;
                end
            end
            2'b10 : begin 
                an <= 4'b1011;
                if(mode == IDLE_MODE) begin
                    circle_data3 <= fnd_3; // circle 시계
                    display_mode <= 3'd2;
                end
                else begin
                    bcd_data <= fnd_3;
                    display_mode <= 3'd4;
                end
            end
            2'b11 : begin 
                an <= 4'b0111;
                if(mode == IDLE_MODE) begin
                    circle_data4 <= fnd_4; // circle 시계
                    display_mode <= 3'd3;
                end
                else begin
                    bcd_data <= fnd_4;
                    display_mode <= 3'd4;
                end
            end   
        endcase
    end

    always @(*) begin
        case (display_mode) 
            IDLE_FND1 : begin
                case(circle_data1) 
                    0  : seg <= 8'hFF;
                    1  : seg <= 8'hFF;
                    2  : seg <= 8'hFF;
                    3  : seg <= 8'hFF;
                    4  : seg <= 8'hFE;
                    5  : seg <= 8'hFC; 
                    6  : seg <= 8'hF8;  
                    7  : seg <= 8'hF0;  
                    8  : seg <= 8'hF0;
                    9  : seg <= 8'hF0;
                    10 : seg <= 8'hF0;
                    11 : seg <= 8'hF0;
                    12 : seg <= 8'hF0;
                    default: seg <= 8'hFF;     
                endcase
            end

            IDLE_FND2 : begin
                case(circle_data2)
                    0  : seg <= 8'hFF; 
                    1  : seg <= 8'hFF;
                    2  : seg <= 8'hFF;
                    3  : seg <= 8'hFE;
                    4  : seg <= 8'hFE;
                    5  : seg <= 8'hFE;
                    6  : seg <= 8'hFE;
                    7  : seg <= 8'hFE;
                    8  : seg <= 8'hF6;
                    9  : seg <= 8'hF6;
                    10 : seg <= 8'hF6;
                    11 : seg <= 8'hF6;
                    12 : seg <= 8'hF6;
                    default: seg <= 8'hFF;
                endcase
            end   

            IDLE_FND3 : begin
                case(circle_data3) 
                    0  : seg <= 8'hFF;
                    1  : seg <= 8'hFF;
                    2  : seg <= 8'hFE;
                    3  : seg <= 8'hFE;
                    4  : seg <= 8'hFE;
                    5  : seg <= 8'hFE;
                    6  : seg <= 8'hFE;
                    7  : seg <= 8'hFE;
                    8  : seg <= 8'hFE;
                    9  : seg <= 8'hF6;
                    10 : seg <= 8'hF6;
                    11 : seg <= 8'hF6;
                    12 : seg <= 8'hF6;
                    default: seg <= 8'hFF;
                endcase
            end

            IDLE_FND4 : begin
                case(circle_data4)     // . g f e d c b a
                    0  : seg <= 8'hFF; // 1 1 1 1 1 1 1 1 0
                    1  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 1
                    2  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 2
                    3  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 3
                    4  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 4
                    5  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 5
                    6  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 6
                    7  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 7
                    8  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 8 
                    9  : seg <= 8'hFE; // 1 1 1 1 1 1 1 0 9 
                    10 : seg <= 8'hF6; // 1 1 1 1 0 1 1 0 10
                    11 : seg <= 8'hE6; // 1 1 1 0 0 1 1 0 11
                    12 : seg <= 8'hC6; // 1 1 0 0 0 1 1 0 12
                    default: seg <= 8'hFF;         
                endcase
            end

            BCD_MODE : begin
                case(bcd_data)        // . g f e d c b a
                    0 : seg <= 8'hC0; // 
                    1 : seg <= 8'hF9; 
                    2 : seg <= 8'hA4; 
                    3 : seg <= 8'hB0; 
                    4 : seg <= 8'h99; 
                    5 : seg <= 8'h92; 
                    6 : seg <= 8'h82; 
                    7 : seg <= 8'hF8; 
                    8 : seg <= 8'h80; 
                    9 : seg <= 8'h90;
                    default: seg = 8'hFF;
                endcase
            end            


        endcase
    end

endmodule
