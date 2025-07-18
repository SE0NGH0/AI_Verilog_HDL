module pwm_duty_cycle_control (
    input wire clk,
    input wire [3:0] duty_cycle,
    output reg PWM_OUT
);

    reg [16:0] counter = 0;       // 100MHz / 1kHz = 100,000 → 17비트 필요
    parameter PERIOD = 100_000;   // 1kHz 주기

    always @(posedge clk) begin
        if (counter >= PERIOD - 1)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    always @(posedge clk) begin
        PWM_OUT <= (counter < (PERIOD * duty_cycle) / 10) ? 1'b1 : 1'b0;
    end

endmodule
