// seg_mux.v
module seg_mux (
    input wire [1:0] mode,
    input wire [7:0] seg_distance,
    input wire [3:0] an_distance,
    input wire [6:0] seg_circle,
    input wire [3:0] an_circle,
    output wire [7:0] seg_out,
    output wire [3:0] an_out
);

    localparam MODE_IDLE = 2'd0;

    assign seg_out = (mode == MODE_IDLE) ? {1'b0, seg_circle} : seg_distance;
    assign an_out  = (mode == MODE_IDLE) ? an_circle : an_distance;
endmodule
