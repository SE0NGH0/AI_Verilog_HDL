`timescale 1ns / 1ps

module uart_controller(
    input clk,
    input reset,
    input rx,
    output [15:0] led
);

    reg [7:0] string_queue [0:9][0:9];
    reg [7:0] temp_string [0:9];
    reg [3:0] temp_string_idx = 0;
    reg [3:0] rear = 0;
    reg [3:0] front = 0;

    wire [7:0] w_rx_data;
    wire       w_rx_done;

    reg [15:0] r_led_out;

    integer i, j;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            for (i=0; i<10; i=i+1) begin
                temp_string[i] <= 8'h00;
                for (j=0; j<10; j=j+1) begin
                    string_queue[i][j] <= 8'h00;
                end
            end
            temp_string_idx <= 0;
            rear <= 0;
        end else begin
            if(w_rx_done) begin
                if (w_rx_data == 8'h0A) begin
                    for (i=0; i<10; i=i+1) begin
                        string_queue[rear][i] <= temp_string[i];
                        temp_string[i] <= 8'h00;
                    end
                    rear <= (rear + 1) % 10;
                    temp_string_idx <= 0;
                end else begin
                    temp_string[temp_string_idx] <= w_rx_data;
                    temp_string_idx <= temp_string_idx + 1;
                end
            end
        end
    end

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_led_out <= 0;
            front <= 0;
        end else begin
             if (rear != front) begin
                if (
                    string_queue[front][0]=="l" && string_queue[front][1]=="e"&& string_queue[front][2]=="d"
                    && string_queue[front][3]=="a" && string_queue[front][4]=="l" && string_queue[front][5]=="l"
                    && string_queue[front][6]=="o" && string_queue[front][7]=="n"
                )
                    r_led_out <= 16'hFFFF; 
                else if (
                    string_queue[front][0]=="l" && string_queue[front][1]=="e" && string_queue[front][2]=="d"
                    && string_queue[front][3]=="a" && string_queue[front][4]=="l" && string_queue[front][5]=="l"
                    && string_queue[front][6]=="o" && string_queue[front][7]=="f" && string_queue[front][8]=="f"
                )
                    r_led_out <= 16'h0000; 
                else if (
                    string_queue[front][0]=="l" && string_queue[front][1]=="e" && string_queue[front][2]=="d"
                    && string_queue[front][3]=="0" && string_queue[front][4]=="0"
                    && string_queue[front][5]=="o" && string_queue[front][6]=="n"
                )
                    r_led_out <= r_led_out | 16'h0001;       
                else if (
                    string_queue[front][0]=="l" && string_queue[front][1]=="e" && string_queue[front][2]=="d"
                    && string_queue[front][3]=="0" && string_queue[front][4]=="0"
                    && string_queue[front][5]=="o" && string_queue[front][6]=="f" && string_queue[front][7]=="f"
                )
                    r_led_out <= r_led_out & 16'hFFFE;       
                
                front <= (front + 1) % 10;
            end
        end
    end

    uart_rx u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(w_rx_data),
        .rx_done(w_rx_done)
    );

    assign led = r_led_out;

endmodule
