`timescale 1ns / 1ps

module command_controller(
    input              clk,
    input              reset,      // SW15
    input              btnL,       // Mode 변경 버튼
    input              rx_done,
    input      [7:0]   rx_data,
    output reg [4:0]   mode_enable // 각 모드의 enable 신호    
    );

    /////// MODE PARAMETER ///////
    parameter IDLE_MODE   = 3'b000;
    parameter HVAC_AUTO   = 3'b001;
    parameter HVAC_MAN    = 3'b010;
    parameter MW_MODE     = 3'b011;
    parameter STOP_WATCH  = 3'b100;
    ///////////////////////////////

    ///////// WIRE & REG //////////
    reg         prev_btnL; 
    reg [2:0]   r_mode;
    ///////////////////////////////

    // 모드 변경 //
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_mode   <= IDLE_MODE;
            prev_btnL <= 0;
        end else begin 
            if (btnL && !prev_btnL) begin  // 처음 눌려진 상태 
                r_mode <= (r_mode == STOP_WATCH) ? IDLE_MODE : r_mode + 1; 
            end
            prev_btnL <= btnL; // 버튼 값 샘플링

            if(rx_done && rx_data == 8'h4D) begin // 4D : 'M'
                r_mode <= (r_mode == STOP_WATCH) ? IDLE_MODE : r_mode + 1; 
            end
        end 
    end 

    // 모드 en 신호 //
    always @(*) begin
        mode_enable = 5'b00000;
    case (r_mode)
        IDLE_MODE  :    mode_enable = 5'b00001;
        HVAC_AUTO  :    mode_enable = 5'b00010;
        HVAC_MAN   :    mode_enable = 5'b00100;
        MW_MODE    :    mode_enable = 5'b01000;
        STOP_WATCH :    mode_enable = 5'b10000;
        default    :    mode_enable = 5'b00000;
    endcase
    end

endmodule
