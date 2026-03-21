`timescale 1ns / 1ps

module filter_top (
    input logic [11:0] i_rgb,
    input logic sw_green,
    // input  logic [3:0] filter_sel,
    output logic [11:0] o_rgb
);

    logic [11:0] i_rgb_grey, i_rgb_red, i_rgb_green, i_rgb_blue;
    logic [11:0] o_rgb_grey, o_rgb_red, o_rgb_green, o_rgb_blue;
    assign o_rgb = sw_green ? o_rgb_green : i_rgb;

    // mux_4x1 #(
    //     .WIDTH(12)
    // ) U_Mux_4x1 (
    //     .filter_sel(filter_sel),
    //     .x0(i_rgb),  // .x0(o_rgb_grey),
    //     .x1(i_rgb_red),
    //     .x2(o_rgb_green),
    //     .x3(o_rgb_blue),
    //     .y(o_rgb)
    // );

    // red_scale_filter U_REDSCALE (
    //     .i_rgb(i_rgb_red),
    //     .o_rgb(o_rgb_red)
    // );

    // green_scale_filter U_GREENSCALE (
    //     .i_rgb(i_rgb),
    //     .o_rgb(o_rgb_green)
    // );

    // blue_scale_filter U_BLUESCALE (
    //     .i_rgb(i_rgb_blue),
    //     .o_rgb(o_rgb_blue)
    // );

    // demux_1x4 #(
    //     .WIDTH(12)
    // ) U_demux_1x4 (
    //     .filter_sel(filter_sel),
    //     .y(i_rgb),
    //     .x0(i_rgb_grey),
    //     .x1(i_rgb_red),
    //     .x2(i_rgb_green),
    //     .x3(i_rgb_blue)
    // );

endmodule

// module green_scale_filter (
//     input  logic [11:0] i_rgb,
//     output logic [11:0] o_rgb
// );

//     logic [11:0] green;

//     assign green = 16 * i_rgb[11:8];
//     assign o_rgb = {green[11:8], green[7:4], green[3:0]};

// endmodule


// module red_scale_filter (
//     input  logic [11:0] i_rgb,
//     output logic [11:0] o_rgb
// );

//     logic [11:0] red;

//     assign red   = 256 * i_rgb[11:8];
//     assign o_rgb = {red[11:8], red[7:4], red[3:0]};

// endmodule


// module blue_scale_filter (
//     input  logic [11:0] i_rgb,
//     output logic [11:0] o_rgb
// );

//     logic [11:0] blue;

//     assign blue  = i_rgb[11:8];
//     assign o_rgb = {blue[11:8], blue[7:4], blue[3:0]};

// endmodule

// module negative_scale_filter (
//     input  logic [11:0] i_rgb,
//     output logic [11:0] o_rgb
// );

//     logic [11:0] negative;

//     assign o_rgb = ~i_rgb;

// endmodule



// module demux_1x4 #(
//     parameter WIDTH = 16
// ) (
//     input logic [3:0] filter_sel,
//     input logic [WIDTH-1:0] y,
//     output logic [WIDTH-1:0] x0,
//     output logic [WIDTH-1:0] x1,
//     output logic [WIDTH-1:0] x2,
//     output logic [WIDTH-1:0] x3
// );

//     always_comb begin
//         x0 = 0;
//         x1 = 0;
//         x2 = 0;
//         x3 = 0;
//         case (filter_sel)
//             4'b0001: x0 = y;
//             4'b0010: x1 = y;
//             4'b0100: x2 = y;
//             4'b1000: x3 = y;

//             default: begin
//                 x0 = 0;
//                 x1 = 0;
//                 x2 = 0;
//                 x3 = 0;
//             end
//         endcase
//     end

// endmodule


// module mux_4x1 #(
//     parameter WIDTH = 12
// ) (
//     input  logic [      3:0] filter_sel,
//     input  logic [WIDTH-1:0] x0,
//     input  logic [WIDTH-1:0] x1,
//     input  logic [WIDTH-1:0] x2,
//     input  logic [WIDTH-1:0] x3,
//     output logic [WIDTH-1:0] y
// );

//     always_comb begin
//         y = x0;
//         case (filter_sel)
//             4'b0001: y = x0;
//             4'b0010: y = x1;
//             4'b0100: y = x2;
//             4'b1000: y = x3;
//             default: y = x0;
//         endcase
//     end

// endmodule
