`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,  // btnU
    input [2:0] btn, // btn[0]: L btn[1]:C btn[2]:R
    input [7:0] sw,
    output [13:0] seg_data,
    output reg [15:0] led
    );

    // mode 
    parameter UP_COUNTER = 3'b000;
    parameter DOWN_COUNTER = 3'b001;
    parameter SLIDE_SW_READ = 3'b010;

    reg prev_btnL=0;
    reg [2:0] r_mode;
    reg [19:0] counter;
    reg [13:0] ms10_counter;

    // mode check 
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_mode <= 0;
            prev_btnL <= 0;
        end else begin 
            if (btn[0] && !prev_btnL) begin  // 처음 눌려진 상태 
                r_mode <= (r_mode == SLIDE_SW_READ) ? UP_COUNTER : r_mode + 1; 
            end
            prev_btnL <= btn[0];
        end 
    end 

    // up counter  
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            ms10_counter <= 0;
        end else if (r_mode == UP_COUNTER)  begin 
            if (counter == 20'd1_000_000-1) begin // 10ms
                ms10_counter <= ms10_counter + 1; 
                counter <= 0; 
            end else begin 
                counter <= counter + 1; 
            end 
        end else begin
            ms10_counter <= 0; 
            counter <= 0;            
        end 
    end 

    always @(r_mode) begin
        case(r_mode)
        UP_COUNTER: begin
            led[15:13] = 3'b100;
        end
        DOWN_COUNTER: begin
            led[15:13] = 3'b010;
        end
        SLIDE_SW_READ: begin
            led[15:13] = 3'b001;
        end 
        default: led[15:13] = 3'b000;
        endcase
    end 
    assign seg_data = (r_mode == UP_COUNTER) ? ms10_counter :
                      (r_mode == DOWN_COUNTER) ? ms10_counter : sw; 

endmodule
