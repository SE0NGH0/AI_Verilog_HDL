module button_debounce #(parameter DEBOUNCE_LIMIT = 20'd499_999) (  // 약 5ms 정도
    input      i_clk,
    input      i_reset,
    input      i_btn,
    output     led,
    output reg o_btn_clean  
);
    reg [19:0] count;
    reg btn_state;
    reg btn_state_prev;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            count <= 0;
            btn_state <= 0;
            btn_state_prev <= 0;
            o_btn_clean <= 0;
        end else begin
            if (i_btn == btn_state)
                count <= 0;
            else begin
                if (count < DEBOUNCE_LIMIT)
                    count <= count + 1;
                else begin
                    btn_state <= i_btn;
                    count <= 0;
                end
            end

            // btn_state에서 rising edge 감지
            btn_state_prev <= btn_state;
            o_btn_clean <= (btn_state == 1'b1 && btn_state_prev == 1'b0);
        end
    end

    assign led = o_btn_clean;

endmodule
