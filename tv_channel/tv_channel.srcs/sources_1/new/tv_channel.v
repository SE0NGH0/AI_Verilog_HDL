`timescale 1ns / 1ps

module tv_channel(
    input wire clk,
    input wire rstn,
    input wire up,
    input wire dn,
    output [3:0] ch
    );

    reg [3:0] state, next_state;

    always @(up or dn or state) begin
        if (up & ~dn) begin
            if (state == 9) 
                next_state = 0;
            else 
                next_state = state + 1;
        end
        else if (~up & dn) begin
            if (state == 0) 
                next_state = 9;
            else 
                next_state = state - 1;
        end else begin
            next_state = state;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            state <= 4'h0;
        else 
            state <= next_state;
    end

    assign ch = state;

endmodule

