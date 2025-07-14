
module btn_controller (
    input clk,
    input reset,
    input btn_U,
    input btn_D,
    input btn_L,
    input btn_R,
    input btn_run,

    output pulse_U,
    output pulse_D,
    output pulse_L,
    output pulse_R,
    output pulse_run
);

    wire clean_U, clean_D, clean_L, clean_R, clean_run;

    // --- Debounce Instances ---
    button_debounce db_u (
        .i_clk(clk), .i_reset(reset), .i_btn(btn_U), .o_btn_clean(clean_U)
    );

    button_debounce db_d (
        .i_clk(clk), .i_reset(reset), .i_btn(btn_D), .o_btn_clean(clean_D)
    );

    button_debounce db_l (
        .i_clk(clk), .i_reset(reset), .i_btn(btn_L), .o_btn_clean(clean_L)
    );

    button_debounce db_r (
        .i_clk(clk), .i_reset(reset), .i_btn(btn_R), .o_btn_clean(clean_R)
    );

    button_debounce db_run (
        .i_clk(clk), .i_reset(reset), .i_btn(btn_run), .o_btn_clean(clean_run)
    );

    // --- One Pulse Instances ---
    one_pulse op_u (
        .clk(clk), .reset(reset), .d_in(clean_U), .d_out(pulse_U)
    );

    one_pulse op_d (
        .clk(clk), .reset(reset), .d_in(clean_D), .d_out(pulse_D)
    );

    one_pulse op_l (
        .clk(clk), .reset(reset), .d_in(clean_L), .d_out(pulse_L)
    );

    one_pulse op_r (
        .clk(clk), .reset(reset), .d_in(clean_R), .d_out(pulse_R)
    );

    one_pulse op_run (
        .clk(clk), .reset(reset), .d_in(clean_run), .d_out(pulse_run)
    );

endmodule

// --- Submodule 1: button_debounce.v ---

module button_debounce #(parameter DEBOUNCE_LIMIT = 20'd999_999) (
    input      i_clk,
    input      i_reset,
    input      i_btn,
    output    reg  o_btn_clean  
);
    reg [19:0] count;
    reg btn_state;
    reg btn_clean;

    always @(posedge i_clk, posedge i_reset) begin
        if (i_reset) begin
            count <= 0;
            btn_state <= 0;
            o_btn_clean <= 0;
        end else if (i_btn == btn_state) begin
            count <= 0;
        end else begin
            if (count < DEBOUNCE_LIMIT)
                count <= count + 1;
            else begin
                btn_state <= i_btn;
                o_btn_clean <= i_btn;
                count <= 0;  // 리셋하면 다음 변경을 다시 감지할 수 있음
            end
        end
    end
    
endmodule



// --- Submodule 2: one_pulse.v ---
module one_pulse (
    input clk,
    input reset,
    input d_in,
    output reg d_out
);
    reg d_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            d_prev <= 0;
            d_out <= 0;
        end else begin
            d_out <= d_in & (~d_prev);
            d_prev <= d_in;
        end
    end
endmodule