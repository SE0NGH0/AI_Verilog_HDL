`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    input start_trigger,
    input [13:0] send_data,
    input  tx_busy,
    input  tx_done,
    output reg tx_start,
    output reg [7:0] tx_data
    );

    reg [6:0] r_data_cnt=0;
    reg r_tx_ing = 1'b0;

    // ------- uart로 1초에 1회씩 up counter값 출력 하기  ------------
   always @(posedge clk or posedge reset) begin
        if (reset) begin
        end 
    end

//------- 이름 출력 하기 ------------
//    always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             tx_start <= 1'b0;
//             r_data_cnt <= 7'd0;
//         end else begin
//             if (start_trigger && !tx_busy) begin
//                 tx_start <= 1'b1;
//                 r_tx_ing = 1'b1;
//             end 
//             if (r_tx_ing) begin 
//                 if (!tx_busy) begin
//                     if (r_data_cnt == 7'd4) begin
//                         r_data_cnt <= 0;
//                         r_tx_ing <= 0;
//                     end else begin 
//                         case (r_data_cnt)
//                             8'd0 : tx_data <= 8'h4B;  // K
//                             8'd1 : tx_data <= 8'h53;  // S
//                             8'd2 : tx_data <= 8'h49;  // I
//                             8'd3 : tx_data <= 8'h0A; // LF
//                             default : tx_data <=  8'h0A; // LF
//                         endcase	
//                         r_data_cnt <= r_data_cnt + 1;
//                         tx_start <= 1'b1;
//                     end 
//                 end else begin
//                     tx_start <= 1'b0;
//                 end
//             end 
//         end
//     end

    // // ascii '0' ~ '9' 
    // always @(posedge  clk, posedge reset) begin
    //     if (reset) begin
    //         tx_start <= 0;
    //         r_data_cnt <= 0;
    //     end else begin
    //         if (start_trigger && !tx_busy) begin    
    //             tx_start <= 1'b1;      
    //             if (r_data_cnt == 7'd10) begin // '0'~'9 10자
    //                 r_data_cnt <= 1;
    //                 tx_data <= send_data;
    //             end else begin
    //                 tx_data <= send_data + r_data_cnt;
    //                 r_data_cnt <= r_data_cnt + 1; 
    //             end
    //         end else begin
    //             tx_start <= 1'b0;
    //         end 
    //     end 
    // end 

endmodule
