`timescale 1ns / 1ps

module fnd_controller_2(
    input clk,
    input reset,
    input finish_toggle,
    input run_toggle,
    input [1:0] state,
    input [3:0] circle_sec,
    input [4:0] finish_time,
    input [15:0] run_time,
    output [3:0] an,
    output [7:0] seg
    );
    
    wire [1:0] w_sel;
    wire [3:0] w_fnd_1;
    wire [3:0] w_fnd_2;
    wire [3:0] w_fnd_3;
    wire [3:0] w_fnd_4;

    fnd_digit_select_mw u_digit_select(
        .clk(clk),
        .reset(reset),
        .sel(w_sel)
    );

    digit_split_mw u_digit_split(
        .data(run_time),
        .state(state),
        .fnd_1(w_fnd_1),
        .fnd_2(w_fnd_2),
        .fnd_3(w_fnd_3),
        .fnd_4(w_fnd_4)
    );

    fnd_digit_display_mw u_digit_display(
        .digit_sel(w_sel),
        .fnd_1(w_fnd_1),
        .fnd_2(w_fnd_2),
        .fnd_3(w_fnd_3),
        .fnd_4(w_fnd_4),
        .state(state),
        .finish_time(finish_time),
        .run_toggle(run_toggle),
        .circle_sec(circle_sec),
        .an(an),
        .seg(seg)
    );

endmodule

module fnd_digit_select_mw(
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

module digit_split_mw(
    input [15:0] data,
    input [1:0] state,
    input finish_toggle,
    output [3:0] fnd_1,
    output [3:0] fnd_2,
    output [3:0] fnd_3,
    output [3:0] fnd_4
);
    parameter IDLE   = 2'b00; // IDLE 모드에서는 문 열고 닫음, TIME 으로 천이 가능
    parameter TIME   = 2'b01; // TIME 모드에서는 문 열고 닫음, 시간제어, 그리고 동작 중으로 천이 가능
    parameter RUN    = 2'b10; // RUN 에서는 동작시간이 모두 지나면 동작 종료로 천이, 취소버튼 누르면 TIME 으로 천이
    parameter STOP   = 2'b11; // STOP 에서는 FND, BUZZER를 출력하고 IDLE로 천이
    
    parameter IDLE_FND = 4'b0000;
 
    // fnd용 숫자 변환
    assign fnd_4 = (state == IDLE) ?  IDLE_FND : 
                   (state == TIME) ?  data[15:8] / 10:
                   (state == RUN)  ?  data[15:8] / 10:
                   (state == STOP) ?  finish_toggle : 4'b0;      
    assign fnd_3 = (state == IDLE) ?  IDLE_FND : 
                   (state == TIME) ?  data[15:8] % 10:
                   (state == RUN)  ?  data[15:8] % 10:
                   (state == STOP) ?  finish_toggle : 4'b0;
    assign fnd_2 = (state == IDLE) ?  IDLE_FND : 
                   (state == TIME) ?  data[7:0] / 10:
                   (state == RUN)  ?  data[7:0] / 10:
                   (state == STOP) ?  finish_toggle : 4'b0;
    assign fnd_1 = (state == IDLE) ?  IDLE_FND : 
                   (state == TIME) ?  data[7:0] % 10:
                   (state == RUN)  ?  data[7:0] % 10:
                   (state == STOP) ?  finish_toggle : 4'b0;                 
endmodule


module fnd_digit_display_mw(
    input [1:0] digit_sel,
    input [3:0] fnd_1,
    input [3:0] fnd_2,
    input [3:0] fnd_3,
    input [3:0] fnd_4,
    input [1:0] state,
    input [3:0] circle_sec,
    input [4:0] finish_time,
    input run_toggle,
    output reg [3:0] an,
    output reg [7:0] seg
);

    parameter IDLE   = 2'b00; // IDLE 모드에서는 문 열고 닫음, TIME 으로 천이 가능
    parameter TIME   = 2'b01; // TIME 모드에서는 문 열고 닫음, 시간제어, 그리고 동작 중으로 천이 가능
    parameter RUN    = 2'b10; // RUN 에서는 동작시간이 모두 지나면 동작 종료로 천이, 취소버튼 누르면 TIME 으로 천이
    parameter STOP   = 2'b11; // STOP 에서는 FND, BUZZER를 출력하고 IDLE로 천이

    parameter IDLE_FND1   = 4'd0;
    parameter IDLE_FND2   = 4'd1;
    parameter IDLE_FND3   = 4'd2;
    parameter IDLE_FND4   = 4'd3;
    parameter CIRCLE_FND1 = 4'd4;
    parameter CIRCLE_FND2 = 4'd5;
    parameter CIRCLE_FND3 = 4'd6;
    parameter CIRCLE_FND4 = 4'd7;
    parameter BCD_state   = 4'd8;
    parameter STOP_FND    = 4'd9;
    
    parameter CIRCLE_STATE = 1'b1;
    parameter TIME_STATE   = 1'b0;
    // FND display 출력
    reg [3:0] idle_data;
    reg [3:0] circle_data1;
    reg [3:0] circle_data2;
    reg [3:0] circle_data3;
    reg [3:0] circle_data4;
    reg [3:0] bcd_data;
    reg [1:0] toggle_data;
    
    reg [3:0] display_state; // display state : 
                             // 0 : IDLE 초기화면 FND 1,
                             // 1 : IDLE 초기화면 FND 2,
                             // 2 : IDLE 초기화면 FND 3,
                             // 3 : IDLE 초기화면 FND 4,
                             // 4 : CIRCLE FND 1, 
                             // 5 : CIRCLE FND 2, 
                             // 6 : CIRCLE FND 3, 
                             // 7 : CIRCLE FND 4, 
                             // 8 : TIME 화면
                             // 9 : STOP 화면(0 토글)

    always @(digit_sel) begin
        case (digit_sel)
            2'b00 : begin 
                an <= 4'b1110;
                if(state == IDLE) begin
                    idle_data <= fnd_1; // IDLE 화면
                    display_state <= 4'd0;
                end
                else if(state == TIME) begin
                    bcd_data <= fnd_1;     // FND 시간 표시
                    display_state <= 4'd8;
                end
                else if(state == RUN) begin
                    if(run_toggle == CIRCLE_STATE) begin// 동작중 서클시계 출력
                        circle_data1 <= circle_sec; 
                        display_state <= 4'd4;
                    end
                    else begin // 시간 출력
                        bcd_data <= fnd_1;     // FND 시간 표시
                        display_state <= 4'd8;
                    end
                end
                else if(state == STOP) begin
                    toggle_data <= finish_time % 2;
                    display_state <= 4'd9;
                end
            end
            2'b01 : begin 
                an <= 4'b1101;
                if(state == IDLE) begin
                    idle_data <= fnd_2; // IDLE 화면
                    display_state <= 4'd1;
                end
                else if(state == TIME) begin
                    bcd_data <= fnd_2;     // FND 시간 표시
                    display_state <= 4'd8;
                end
                else if(state == RUN) begin
                    if(run_toggle == CIRCLE_STATE) begin// 동작중 서클시계 출력
                        circle_data2 <= circle_sec;                          
                        display_state <= 4'd5;
                    end
                    else begin // 시간 출력
                        bcd_data <= fnd_2;     // FND 시간 표시
                        display_state <= 4'd8;
                    end
                end
                else if(state == STOP) begin
                    toggle_data <= finish_time % 2;
                    display_state <= 4'd9;
                end
            end
            2'b10 : begin 
                an <= 4'b1011;
                if(state == IDLE) begin
                    idle_data <= fnd_3; // IDLE 화면
                    display_state <= 4'd2;
                end
                else if(state == TIME) begin
                    bcd_data <= fnd_3;     // FND 시간 표시
                    display_state <= 4'd8;
                end
                else if(state == RUN) begin
                    if(run_toggle == CIRCLE_STATE) begin// 동작중 서클시계 출력
                        circle_data3 <= circle_sec; 
                        display_state <= 4'd6;
                    end
                    else begin // 시간 출력
                        bcd_data <= fnd_3;     // FND 시간 표시
                        display_state <= 4'd8;
                    end
                end                
                else if(state == STOP) begin
                    toggle_data <= finish_time % 2;
                    display_state <= 4'd9;
                end
            end
            2'b11 : begin 
                an <= 4'b0111;
                if(state == IDLE) begin
                    idle_data <= fnd_4; // IDLE 화면
                    display_state <= 4'd3;
                end
                else if(state == TIME) begin
                    bcd_data <= fnd_4;     // FND 시간 표시
                    display_state <= 4'd8;
                end
                else if(state == RUN) begin
                    if(run_toggle == CIRCLE_STATE) begin// 동작중 서클시계 출력
                        circle_data4 <= circle_sec; 
                        display_state <= 4'd7;
                    end
                    else begin // 시간 출력
                        bcd_data <= fnd_4;     // FND 시간 표시
                        display_state <= 4'd8;
                    end
                end                
                else if(state == STOP) begin
                    toggle_data <= finish_time % 2;
                    display_state <= 4'd9;
                end
            end 
        endcase
    end

    always @(*) begin
        case (display_state)

            IDLE_FND1 : seg <= 8'b1000_0110; // E

            IDLE_FND2 : seg <= 8'b1100_0111; // L
            
            IDLE_FND3 : seg <= 8'b1010_0001; // d
            
            IDLE_FND4 : seg <= 8'b1111_1001; // i
            
            CIRCLE_FND1 : begin
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

            CIRCLE_FND2 : begin
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

            CIRCLE_FND3 : begin
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

            CIRCLE_FND4 : begin
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

            BCD_state : begin
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
                    default: seg <= 8'hFF;
                endcase
            end

            STOP_FND : begin
                case(toggle_data)
                    0 : seg <= 8'hC0;
                    1 : seg <= 8'hFF;
                endcase
            end          
        endcase
    end
endmodule
