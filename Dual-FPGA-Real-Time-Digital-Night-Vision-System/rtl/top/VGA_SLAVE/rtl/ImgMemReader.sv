`timescale 1ns / 1ps

module ImgMemReader (
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [                7:0] imgData,
    output logic [                3:0] port_red,
    output logic [                3:0] port_green,
    output logic [                3:0] port_blue,
    output logic [                3:0] filter_sel
);

    logic qvga_de;
    logic qvga_de_0;
    logic qvga_de_1;
    logic qvga_de_2;
    logic qvga_de_3;

    assign qvga_de_0 = DE && (x_pixel < 320) && (y_pixel < 240);
    assign qvga_de_1 = DE && (x_pixel >= 320 && x_pixel < 640) && (y_pixel < 240);
    assign qvga_de_2 = DE && (x_pixel < 320)                   && (y_pixel >= 240 && y_pixel < 480);
    assign qvga_de_3 = DE && (x_pixel >= 320 && x_pixel < 640) && (y_pixel >= 240 && y_pixel < 480);

    assign filter_sel = {qvga_de_3, qvga_de_2, qvga_de_1, qvga_de_0};

    assign addr =  (qvga_de_0) ? (320 *  y_pixel        +  x_pixel       )
                 : (qvga_de_1) ? (320 *  y_pixel        +  x_pixel - 320 )
                 : (qvga_de_2) ? (320 * (y_pixel - 240) +  x_pixel       )
                 : (qvga_de_3) ? (320 * (y_pixel - 240) + (x_pixel - 320))
                 :'b0;
    assign {port_red, port_green, port_blue} = (qvga_de_0 | qvga_de_1 | qvga_de_2 | qvga_de_3) ? {imgData[7:4], imgData[7:4], imgData[7:4]} : 12'd0;

endmodule

// module ImgMemReader (
//     input  logic                       DE,
//     input  logic                [ 9:0] x_pixel,
//     input  logic                [ 9:0] y_pixel,
//     output logic [$clog2(320*240)-1:0] addr,
//     input  logic                [15:0] imgData,
//     output logic                [ 3:0] port_red,
//     output logic                [ 3:0] port_green,
//     output logic                [ 3:0] port_blue
// );

//     logic qvga_de;

//     assign qvga_de = DE && (x_pixel < 320) && (y_pixel < 240);

//     assign addr = qvga_de ? (320 * y_pixel + x_pixel) : 'bz;
//     assign {port_red, port_green, port_blue} = qvga_de ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 12'd0;

// endmodule



module ImgMemReader_upscaler (
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [                7:0] imgData,
    output logic [                3:0] port_red,
    output logic [                3:0] port_green,
    output logic [                3:0] port_blue
);

    assign addr = DE ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 'bz;
    assign {port_red, port_green, port_blue} = DE ? {imgData[7:4], imgData[7:4], imgData[7:4]} : 12'd0;

endmodule
