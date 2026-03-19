`timescale 1ns / 1ps

module OV7670_MemController (
    input  logic        pclk,
    input  logic        reset,
    // OV7670 side
    input  logic        href,
    input  logic        vsync,
    input  logic [ 7:0] data,
    // ISP side
    output logic        valid,
    output logic        vsync_edge,
    output logic [15:0] rgb_data
);


    logic [15:0] pixelData;
    logic pixelEvenOdd;

    assign rgb_data = pixelData;

    logic vsync_d1;

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            vsync_d1   <= 0;
            vsync_edge <= 0;
        end else begin
            vsync_d1   <= vsync;
            vsync_edge <= (vsync && !vsync_d1);
        end
    end

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            valid        <= 0;
            pixelData    <= 0;
            pixelEvenOdd <= 0;
        end else begin
            if (vsync_edge) begin
                valid        <= 0;
                pixelEvenOdd <= 0;
            end else begin
                if (href) begin
                    if (pixelEvenOdd == 1'b0) begin
                        valid           <= 1'b0;
                        pixelData[15:8] <= data;
                        pixelEvenOdd    <= 1'b1;
                    end else begin
                        valid          <= 1'b1;
                        pixelData[7:0] <= data;
                        pixelEvenOdd   <= 1'b0;
                    end
                end else begin
                    valid <= 1'b0;
                end
            end
        end
    end
endmodule
