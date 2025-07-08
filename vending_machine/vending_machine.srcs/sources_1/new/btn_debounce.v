module button_debouncer (
    input  wire clk,          // 100MHz
    input  wire noisy_btn,    // 입력 스위치
    output reg  clean_btn     // 디바운싱된 출력
);

    reg [16:0] cnt = 0;
    reg btn_sync_0, btn_sync_1;
    reg btn_stable = 0;

    // 입력 동기화
    always @(posedge clk) begin
        btn_sync_0 <= noisy_btn;
        btn_sync_1 <= btn_sync_0;
    end

    // 디바운스 처리
    always @(posedge clk) begin
        if (btn_sync_1 != btn_stable) begin
            cnt <= 0;
        end else if (cnt < 100_000) begin
            cnt <= cnt + 1;
        end

        if (cnt == 100_000) begin
            clean_btn <= btn_sync_1;
            btn_stable <= btn_sync_1;
        end
    end
endmodule
