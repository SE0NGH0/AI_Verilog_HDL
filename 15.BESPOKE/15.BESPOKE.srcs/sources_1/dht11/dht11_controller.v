`timescale 1ns / 1ps

module dht11_controller(
    input clk,
    input reset,
    inout data_io,
    output reg [$clog2(11600) - 1:0] humidity,       // 14bit
    output reg [$clog2(11600) - 1:0] temperature     // 14bit
);

////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////  PARAMETERS   ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

    localparam IDLE = 4'b0001;
    localparam SEND_REQUEST = 4'b0010;
    localparam WAIT_RESPONSE_LOW = 4'b0011;
    localparam WAIT_RESPONSE_HIGH = 4'b0100;
    localparam READ_DATA = 4'b0101;
    localparam VERIFY_CHECKSUM = 4'b0110;

    localparam TIMEOUT = 100_000;

////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////  WIRE & REG   ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////


    reg [$clog2(TIMEOUT):0] timeout_counter;
    reg [5:0] bit_counter;  // For 40 bits (0 to 39)
    reg [39:0] data_buffer;
    reg read_state;

    /* Tri-state Control */
    reg data_tri;  // 0: Output, 1: Input
    reg data_tx;
    reg prev_data_io;
    assign data_io = (data_tri) ? 1'bZ : data_tx;

    /* Tick Counters*/
    reg [21:0] us_tick_counter;
    wire w_us_tick, w_ms_tick;

    reg [3:0] state, next_state;

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////  MODULE INSTANTIATIONS   ///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////    

    tick_generator #(
        .INPUT_FREQ(100_000_000),
        .TICK_HZ(1_000_000)     // 1us tick
    ) us_tick_generator (
        .clk  (clk),
        .reset(reset),
        .tick (w_us_tick)
    );


////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////  MODULE Logic   ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

    /* State Register */
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    /* State Transition */
    always @(*) begin

        next_state = state;

        if (w_us_tick) begin

            case (state)
                IDLE: begin
                    if (us_tick_counter > 3_000_000) begin
                        next_state = SEND_REQUEST;
                    end
                end
                
                SEND_REQUEST: begin
                    if (us_tick_counter > 18_000) begin
                        next_state = WAIT_RESPONSE_LOW;
                    end
                end
                
                WAIT_RESPONSE_LOW: begin
                    if (!data_io && prev_data_io) begin
                        next_state = WAIT_RESPONSE_HIGH;
                    end else if (us_tick_counter > TIMEOUT) begin
                        next_state = IDLE;
                    end
                end
                
                WAIT_RESPONSE_HIGH: begin
                    if (data_io && !prev_data_io) begin
                        next_state = READ_DATA;
                    end else if (us_tick_counter > TIMEOUT) begin
                        next_state = IDLE;
                    end
                end
                
                READ_DATA: begin
                    if (bit_counter >= 40) begin
                        next_state = VERIFY_CHECKSUM;
                    end else if (us_tick_counter > TIMEOUT) begin
                        next_state = IDLE;
                    end
                end
                
                VERIFY_CHECKSUM: begin
                    next_state = IDLE;
                end
                
                default: next_state = IDLE;
            endcase
        end 

    end


    /* State Logic */
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_tri <= 0;
            data_tx <= 1;
            bit_counter <= 0;
            data_buffer <= 0;
            humidity <= 0;
            temperature <= 0;
            read_state <= 0;
            prev_data_io <= 1;
            us_tick_counter <= 0;
        end else if (w_us_tick) begin
            prev_data_io <= data_io;
            
            case (state)
                IDLE: begin
                    if (us_tick_counter > 3_000_000) begin
                        data_tri <= 0;
                        data_tx <= 0;
                        us_tick_counter <= 0;
                    end else begin
                        us_tick_counter <= us_tick_counter + 1;
                    end
                end
                
                SEND_REQUEST: begin
                    if (us_tick_counter > 18_000) begin
                        data_tri <= 1;
                        data_tx <= 1;
                        us_tick_counter <= 0;
                    end else begin
                        us_tick_counter <= us_tick_counter + 1;
                    end
                end
                
                WAIT_RESPONSE_LOW: begin
                    us_tick_counter <= us_tick_counter + 1;
                end
                
                WAIT_RESPONSE_HIGH: begin
                    if (data_io && !prev_data_io) begin
                        bit_counter <= 0;
                        us_tick_counter <= 0;
                        read_state <= 0;
                    end else begin
                        us_tick_counter <= us_tick_counter + 1;
                    end
                end
                
                READ_DATA: begin
                    case (read_state)
                        0: begin
                            if (data_io && !prev_data_io) begin
                                us_tick_counter <= 0;
                                read_state <= 1;
                            end else begin
                                us_tick_counter <= us_tick_counter + 1;
                            end
                        end
                        1: begin
                            if (!data_io && prev_data_io) begin
                                us_tick_counter <= 0;
                                data_buffer[39 - bit_counter] <= (us_tick_counter > 50) ? 1'b1 : 1'b0;
                                bit_counter <= bit_counter + 1;
                                read_state <= 0;
                            end else begin
                                us_tick_counter <= us_tick_counter + 1;
                            end
                        end
                    endcase
                end
                
                VERIFY_CHECKSUM: begin
                    if(data_buffer[7:0] == data_buffer[39:32] + data_buffer[31:24] + data_buffer[23:16] + data_buffer[15:8]) begin
                        // humidity <= {data_buffer[39:32]};
                        humidity <= (data_buffer[39:32]) * 100 + (data_buffer[31:24]); 
                        temperature <= (data_buffer[23:16]) * 100 + (data_buffer[15:8]);
                    end
                end
            endcase
        end
    end

endmodule