`timescale 1ns / 1ps

module top (
    input  wire       clk,      // 100 MHz 시스템 클럭
    input  wire       btnU,     // 리셋 버튼 (Active-High)
    input  wire       btnL,     // 100원 투입 버튼 (Active-High)
    input  wire       btnC,     // 500원 투입 버튼 (Active-High)
    input  wire       btnR,     // 커피 버튼 (Active-High)
    input  wire       btnD,     // 반환 버튼 (Active-High)
    output wire [6:0] seg,      // 7-세그먼트 a…g
    output wire [3:0] an        // 7-세그먼트 anode (AN0만)
);

    //---------------------------------------------------------------------------
    // Asynchronous Reset
    //---------------------------------------------------------------------------
    wire rst = btnU; // Active-High reset

    //---------------------------------------------------------------------------
    // Button Synchronizers and Debouncers (10 ms)
    //---------------------------------------------------------------------------
    // Debounce parameters
    localparam integer DB_CNT_MAX = 1_000_000; // 10ms at 100MHz

    // 5 buttons: L(100), C(500), R(vend), D(return)
    wire [4:0] raw_btn = {btnU, btnL, btnC, btnR, btnD};
    wire [4:0] clean_btn;
    wire [4:0] pulse;

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : btn_proc
            // two-stage synchronizer
            reg sync0, sync1;
            always @(posedge clk or posedge rst) begin
                if (rst) begin sync0 <= 1'b0; sync1 <= 1'b0; end
                else begin sync0 <= raw_btn[i]; sync1 <= sync0; end
            end
            // debounce counter
            reg [$clog2(DB_CNT_MAX)-1:0] cnt;
            reg clean;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    cnt   <= 0;
                    clean <= 1'b0;
                end else if (sync1 == clean) begin
                    cnt <= 0;
                end else if (cnt == DB_CNT_MAX-1) begin
                    cnt   <= 0;
                    clean <= sync1;
                end else begin
                    cnt <= cnt + 1;
                end
            end
            // one-shot pulse on rising edge of clean
            reg clean_d;
            always @(posedge clk or posedge rst) begin
                if (rst) clean_d <= 1'b0;
                else      clean_d <= clean;
            end
            assign clean_btn[i] = clean;
            assign pulse[i]     = clean && ~clean_d;
        end
    endgenerate

    // Map pulses
    wire pulseU   = pulse[0]; // reset
    wire pulse100 = pulse[1]; // 100원
    wire pulse500 = pulse[2]; // 500원
    wire pulseVend= pulse[3]; // 커피
    wire pulseRet = pulse[4]; // 반환

    //---------------------------------------------------------------------------
    // credit (100원 단위) state
    //---------------------------------------------------------------------------
    reg [3:0] credit;
    always @(posedge clk or posedge rst) begin
        if (rst)
            credit <= 4'd0;
        else if (pulse100)
            credit <= credit + 1;
        else if (pulse500)
            credit <= credit + 5;
        else if (pulseVend && credit >= 3)
            credit <= credit - 3;
        else if (pulseRet)
            credit <= 4'd0;
    end

    //---------------------------------------------------------------------------
    // 7-segment display (0~9:number, >=10: dash)
    //---------------------------------------------------------------------------
    reg [3:0] digit;
    always @(*) begin
        if (credit <= 4'd9) digit = credit;
        else                digit = 4'd10; // dash
    end

    reg [6:0] seg_lut;
    always @(*) begin
        case (digit)
            4'd0:  seg_lut = 7'b1000000;
            4'd1:  seg_lut = 7'b1111001;
            4'd2:  seg_lut = 7'b0100100;
            4'd3:  seg_lut = 7'b0110000;
            4'd4:  seg_lut = 7'b0011001;
            4'd5:  seg_lut = 7'b0010010;
            4'd6:  seg_lut = 7'b0000010;
            4'd7:  seg_lut = 7'b1111000;
            4'd8:  seg_lut = 7'b0000000;
            4'd9:  seg_lut = 7'b0010000;
            default: seg_lut = 7'b0100000; // dash '-'
        endcase
    end

    assign seg = seg_lut;
    assign an  = 4'b1110; // AN0 active-low

endmodule
