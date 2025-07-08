module led_coffee_effect (
    input  wire clk,
    input  wire rst,
    input  wire trigger,         // buy_pulse 조건부
    output reg  [6:0] led
);

    reg [25:0] cnt;
    reg [3:0]  step;
    reg        active;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt    <= 0;
            step   <= 0;
            active <= 0;
            led    <= 7'b0000000;
        end else begin
            if (trigger && !active) begin
                active <= 1;
                step   <= 0;
                cnt    <= 0;
                led    <= 7'b0000000;
            end

            if (active) begin
                cnt <= cnt + 1;

                if (cnt == 25_000_000) begin  // 0.5초 @100MHz
                    cnt <= 0;
                    step <= step + 1;

                    case (step)
                        // 점점 켜짐 (0~6)
                        4'd0: led <= led | 7'b0000001;
                        4'd1: led <= led | 7'b0000010;
                        4'd2: led <= led | 7'b0000100;
                        4'd3: led <= led | 7'b0001000;
                        4'd4: led <= led | 7'b0010000;
                        4'd5: led <= led | 7'b0100000;
                        4'd6: led <= led | 7'b1000000;

                        // 점점 꺼짐 (7~13)
                        4'd7:  led <= led & ~(7'b1000000);
                        4'd8:  led <= led & ~(7'b0100000);
                        4'd9:  led <= led & ~(7'b0010000);
                        4'd10: led <= led & ~(7'b0001000);
                        4'd11: led <= led & ~(7'b0000100);
                        4'd12: led <= led & ~(7'b0000010);
                        4'd13: led <= led & ~(7'b0000001);

                        default: begin
                            active <= 0;
                            led    <= 7'b0000000;
                        end
                    endcase
                end
            end
        end
    end
endmodule
