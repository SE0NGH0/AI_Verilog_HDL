`timescale 1ns / 1ps

module data_sender(
    input               clk,
    input               reset,
    input               start_trigger,
    input       [7:0]   send_data,
    input               tx_busy,
    input               tx_done,
    output  reg         tx_start,
    output  reg [7:0]   tx_data
);

    // 'PSH' 출력
    reg [1:0] state;
    reg [7:0] psh_msg [0:2];  // 고정 문자열: "P", "S", "H"

    initial begin
        psh_msg[0] = "P";
        psh_msg[1] = "S";
        psh_msg[2] = "H";
    end

    wire [1:0] index_offset = state;  // 현재 상태 = 보낼 인덱스
    wire [1:0] rom_index = send_data[1:0] + index_offset; // ROM 주소 제한 (0~2)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= 0;
            tx_start  <= 0;
        end else begin
            case (state)
                0: begin
                    if (start_trigger && !tx_busy) begin
                        tx_data  <= psh_msg[rom_index];
                        tx_start <= 1;
                        state    <= 1;
                    end else begin
                        tx_start <= 0;
                    end
                end

                1: begin
                    if (tx_done) begin
                        tx_data  <= psh_msg[rom_index];
                        tx_start <= 1;
                        state    <= 2;
                    end else begin
                        tx_start <= 0;
                    end
                end

                2: begin
                    if (tx_done) begin
                        tx_data  <= psh_msg[rom_index];
                        tx_start <= 1;
                        state    <= 3;
                    end else begin
                        tx_start <= 0;
                    end
                end

                3: begin
                    if (tx_done) begin
                        tx_start <= 0;
                        state    <= 0;
                    end else begin
                        tx_start <= 0;
                    end
                end
            endcase
        end
    end

    // // ASCII '0' ~ '9'
    // reg [6:0] r_data_cnt = 0;
 
    // always @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         tx_start    <= 0;
    //         r_data_cnt  <= 0;
    //     end 

    //     else begin
    //         if (start_trigger && !tx_busy) begin
    //             tx_start    <= 1'b1;
    //             // tx_data     <= send_data;
    //         end
    //         else if (tx_done) begin
    //             if (r_data_cnt == 7'd10) begin         // '0'~'9'로 총 10
    //                 r_data_cnt  <= 1;
    //                 tx_data <= send_data;
    //             end 
                
    //             else begin
    //                 tx_data     <= send_data + r_data_cnt;
    //                 r_data_cnt  <= r_data_cnt + 1;
    //                 // r_data_cnt  <= r_data_cnt + 1;
    //                 // r_temp_data <= r_temp_data + 1;
    //                 // tx_start    <= 1'b1;
    //             end
    //         end             
    //         else begin
    //             tx_start    <= 1'b0;
    //         end
    //     end
    // end

endmodule
