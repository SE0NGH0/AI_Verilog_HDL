`timescale 1ns / 1ps

module dht11(
        input clk,
        input reset,
        input us_tick,
        inout dht11_data,
        output reg       dht11_valid,
        output reg [7:0] dht11_humid_int,
        output reg [7:0] dht11_humid_frac,
        output reg [7:0] dht11_temp_int,
        output reg [7:0] dht11_temp_frac,
        output reg [15:0] led
    );

    // 1. Power On 후 대기, 1초 동안 대기
    // 2. Start Signal 전송, 출력모드 설정
    //    Low 상태를 최소 18ms 유지
    //    입력 모드로 전환 20~40 us 대기
    // 3. Response Signal 전송
    //    80us Low -> 80us High
    // 4. 40bit 데이터 전송
    //    { 8bit 습도 정수부, 8bit 습도 소수부, 8bit 온도 정수부, 8bit 온도 소수부, 8bit checksum }
    //    각 비트의 시작은 항상 50us Low --> 이후 High 길이에 따라 0 또는 1
    //    26~28us High --> '0', 70us --> '1' // ex 50us low 28us high --> '0'
    // 5. End Signal
    //    전송이 끝난 후 50us Low --> 이후 데이터 라인은 풀업에 의해 High 상태로 복귀
    //    이후 DHT11은 다시 Sleep 모드로
    //    Checksum 확인 --> 마지막 8비트는 앞의 4바이트를 더한 값임. --> 이는 올바른 데이터 수신여부인지 검증

    /////// PARAMETER ///////
    parameter integer US_COUNT  = 100;
    parameter IDLE_STATE    = 3'b000; // 0
    parameter START_SIGNAL  = 3'b001; // 1
    parameter WAIT_HIGH     = 3'b010; // 2
    parameter RESPONSE_WAIT = 3'b011; // 3
    parameter DATA_RECEIVE  = 3'b100; // 4 
    parameter END_STATE     = 3'b101; // 5
    
    /////// WIRE & REG ///////

    
    reg [23:0]  us_tick_counter;
    reg [2:0]   state;      // state
    reg [2:0]   next_state; // next state

    /* Tri-state Control */
    reg         dht11_data_out;     // 출력할 dht11 데이터
    reg         dht11_data_oe;      // output enable: 1 -> 출력 활성화, 0 -> high-Z
    wire        dht11_data_in;      // 외부에서 들어오는 dht11 데이터 읽기용
    reg         prev_data_in;
    assign      dht11_data = (dht11_data_oe) ? dht11_data_out : 1'bZ; // 출력 또는 high-Z

    reg [39:0]  dht11_40bit_data;
    reg [5:0]   dht11_data_index;
    reg [7:0]   dht11_checksum;
    reg [7:0]   dht11_checksum_calc;
    
    /* State Register */
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= IDLE_STATE;
        end else begin
            state <= next_state;
        end
    end

    /* State Transition */
    always @(*) begin
        
        next_state = state;

        if (us_tick) begin

            case (state)
                IDLE_STATE : begin
                    
                end

            endcase
        end
    end
    /*
    // 1us 로 단위시간 통일.
    // us 카운터용 always 문
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_us        <= 0;
            r_us_cnt    <= 0;
        end else if(r_us_cnt == US_COUNT - 1) begin
            r_us_cnt <= 0;
            r_us <= r_us + 1;
            if(r_us_clear) begin
                r_us <= 0;
            end
        end else begin
            r_us_cnt <= r_us_cnt + 1;
            if(r_us_clear) begin
                r_us <= 0;
            end
        end
    end
    */
    
    // 1) reset 시 초기화, 2) 매 클럭마다 dht11_data_in 샘플링
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_data_in <= 1'b0;
        end else begin
            prev_data_in <= dht11_data_in;
        end
    end
    /*
    // 상태천이용 always 문
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_state           <= IDLE_STATE;
            dht11_data_oe     <= 0;
            dht11_data_out    <= 1;
            dht11_40bit_data  <= 0;
            dht11_data_index  <= 0;
            dht11_valid       <= 0;
            r_us_clear        <= 0;
            prev_data_in      <= 1'b0;
        end else begin
            case(r_state)
                IDLE_STATE : begin
                    led <= 16'b0000_0000_0000_0001;
                    if (r_us == 1_000_000) begin    // 1초 안정화 후 상태천이
                    // if (r_us == 10) begin // 시뮬용
                        r_state    <= START_SIGNAL;
                        r_us_clear <= 1;
                        r_response_check <= 0;      // 80us low, high 검사용
                        dht11_40bit_data <= 0;      // DHT11 data 초기화
                        dht11_data_index <= 0;
                        dht11_data_oe  <= 1'b1;      // 출력 활성화
                        dht11_data_out <= 1'b0;     // LOW 신호
                    end else begin
                        r_us_clear <= 0;
                        dht11_data_oe  <= 0;
                        dht11_data_out <= 1;
                        dht11_valid    <= 0;
                    end

                end

                START_SIGNAL : begin
                    led <= 16'b0000_0000_0000_0010;
                    dht11_data_oe  <= 1'b1;      // 출력 활성화
                    dht11_data_out <= 1'b0;     // LOW 신호
                    if (r_us == 20_000) begin   // 100ms 유지하고
                    // if (r_us == 18) begin    // 20ms 유지하고
                        r_state <= WAIT_HIGH;   // 입력모드로 전환하도록
                        r_us_clear <= 1;
                    end else begin
                        r_us_clear <= 0;
                    end
                end

                WAIT_HIGH : begin
                    led <= 16'b0000_0000_0000_0100;
                    dht11_data_oe <= 1'b0;      // 입력모드로 전환
                    if (r_us >= 50) begin       // 30us 유지하고 상태천이
                        r_state <= RESPONSE_WAIT;   
                        r_us_clear <= 1;
                    end else begin
                        r_us_clear <= 0;
                    end
                end

                RESPONSE_WAIT : begin
                    led <= 16'b0000_0000_0000_1000;
                    dht11_data_oe <= 1'b0;
                    // DHT11의 Low 응답 감지 시작
                    // 타이머 리셋해서 길이 측정

                    if (dht11_data_in == 1'b0 && r_us == 100) begin
                        r_us_clear <= 1;
                        r_response_check <= r_response_check + 1;     
                    end 
                    // DHT11의 80us Low가 끝나고 High 응답 시작
                    else if (dht11_data_in == 1'b1 && r_us == 100) begin
                        r_us_clear <= 1;
                        r_response_check <= r_response_check + 1;    
                    end
                    else begin
                        r_us_clear <= 0;
                    end

                    // 정상적으로 80us low, high 수신하면 DATA_RECEIVE 시작
                    if(r_response_check == 2) begin
                        r_state <= DATA_RECEIVE;
                        r_us_clear <= 1;        
                    end else begin
                        r_state <= RESPONSE_WAIT;
                    end

                    if (r_us > 300) begin // 300us 이상 응답 안 오면 timeout
                        r_state <= IDLE_STATE;
                        r_response_check <= 0;
                        r_us_clear <= 1;
                    end
                end

                DATA_RECEIVE : begin
                    led           <= 16'b0000_1111_0001_0000;
                    dht11_data_oe <= 1'b0;

                    // 1) rising-edge: High 유지 시간 측정 시작
                    if (!prev_data_in && dht11_data_in) begin
                        r_us_clear <= 1;           // r_us를 0으로 리셋
                    end 
                    // 2) falling-edge: 측정 종료 → r_us에 담긴 시간으로 bit 판별
                    else if (prev_data_in && !dht11_data_in) begin
                        // 예: r_us > 70us → '1', 아니면 '0'
                        if (r_us == 70) begin
                            dht11_40bit_data <= {dht11_40bit_data[38:0], 1'b1};
                            r_us_clear       <= 1;     // 다음 비트 측정 위해 리셋
                            dht11_data_index <= dht11_data_index + 1;
                        end else begin
                            dht11_40bit_data <= {dht11_40bit_data[38:0], 1'b0};
                            r_us_clear       <= 1;     // 다음 비트 측정 위해 리셋
                            dht11_data_index <= dht11_data_index + 1;
                        end
                    end 
                    // 그 외 시간 측정 중
                    else begin
                        r_us_clear <= 0;
                        // 40비트 모두 받았으면 다음 상태로
                    end

                    if (dht11_data_index == 6'd39) begin
                        r_state      <= END_STATE;
                        r_us_clear   <= 1;
                    end
                end      


                END_STATE : begin
                    led <= 16'b0000_0000_0010_0000;
                    dht11_data_oe <= 1'b0;
                    // 데이터 나누기
                    dht11_humid_int     <= dht11_40bit_data[39:32]; // 습도 정수부
                    dht11_humid_frac    <= dht11_40bit_data[31:24]; // 습도 소수부
                    dht11_temp_int      <= dht11_40bit_data[23:16]; // 온도 정수부
                    dht11_temp_frac     <= dht11_40bit_data[15:8];  // 온도 소수부
                    dht11_checksum      <= dht11_40bit_data[7:0];   // 체크섬

                    // 체크섬 계산
                    dht11_checksum_calc <= dht11_40bit_data[39:32] +
                                        dht11_40bit_data[31:24] + 
                                        dht11_40bit_data[23:16] +
                                        dht11_40bit_data[15:8];

                    // 유효성 검사
                    if (dht11_checksum == dht11_checksum_calc) begin
                        dht11_valid <= 1'b1;
                    end else begin
                        dht11_valid <= 1'b0;
                    end

                    // 50us Low 후, 라인이 High로 복귀한 상태 감지
                    if (dht11_data_in == 1'b0) begin
                        if (r_us >= 50) begin
                            r_us_clear <= 1'b1;
                        end else begin
                            r_us_clear <= 1'b0;
                        end
                    end else if (dht11_data_in == 1'b1 && r_us > 50) begin
                        // 전송 완료 후 대기 상태로 복귀
                        r_state <= IDLE_STATE;
                        r_us_clear <= 1'b1;
                    end else begin
                        r_us_clear <= 1'b0;
                    end
                end 

                default : r_state <= IDLE_STATE;
            endcase
        end
    end

    */
endmodule
