`timescale 1ns / 1ps

module top_detecing_moving (
    input logic clk,
    input logic reset,
    input logic btnU,
    input logic btnD,
    input logic btnL,
    input logic btnR,
    input logic de,
    input logic vsync,
    input logic [16:0] wAddr,
    input logic [11:0] i_scharr,
    output logic [11:0] detected_scahrr
);

    logic pixel_C, pixel_B, pixel_A;

    Detecing_Moving U_DETECTING_MOVING (
        .clk(clk),
        .reset(reset),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .de(de),
        .vsync(vsync),
        .addr(wAddr),
        .i_scharr(i_scharr),
        .pixel_C(pixel_C),  //현재 값
        .pixel_B(pixel_B),  //중간과거
        .pixel_A(pixel_A),  //제일과거
        .detected_scahrr(detected_scahrr)
    );


    moving_buffer U_MOVING_BUFFER (
        .clk(clk),
        .reset(reset),
        .de(de),
        .wAddr(wAddr),  //buff_reader의 addr
        .scharr_C(i_scharr[11]),  //MSB

        .pixel_C(pixel_C),
        .pixel_B(pixel_B),
        .pixel_A(pixel_A)
    );
endmodule
