`timescale 1ns / 1ps

module filter_top (
    input logic [11:0] i_rgb,
    input logic sw_green,
    output logic [11:0] o_rgb
);

    logic [11:0] i_rgb_grey, i_rgb_red, i_rgb_green, i_rgb_blue;
    logic [11:0] o_rgb_grey, o_rgb_red, o_rgb_green, o_rgb_blue;
    assign o_rgb = sw_green ? o_rgb_green : i_rgb;

endmodule