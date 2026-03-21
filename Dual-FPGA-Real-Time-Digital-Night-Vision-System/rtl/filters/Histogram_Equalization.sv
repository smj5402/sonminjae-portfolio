`timescale 1ns / 1ps

module Histogram_Equalization #(
    parameter CDF_COUNT_SIZE = 256
    ) ( 
    input  logic pclk,          // 25MHz pclk
    input  logic reset,
    // signal
    input  logic valid_in,            // valid_in from MemController
    input  logic vsync_edge,         // vsync From OV7670
    // data
    input  logic [7:0] data,    // from gamma filter
    output logic valid_out,
    output logic vsync_out,
    output logic [7:0] he_data  // to sobel | to scharr
    );

    logic [16:0] PDF_RAM [0:255];
    logic [ 7:0] LUT_RAM [0:255];

    logic [ 7:0] c_count, n_count;
    logic [16:0] c_cdf,   n_cdf;

    logic [25:0] cdf_result;

    assign cdf_result = n_cdf * 870;
    // assign he_data    = LUT_RAM[data];


    // // vsync edge detector
    // logic prev_vsync, vsync_edge;
    
    // always_ff @(posedge pclk or posedge reset) begin
    //     if (reset) begin
    //         prev_vsync <= 0;
    //         vsync_edge <= 0;
    //     end else begin
    //         prev_vsync <= vsync;
    //         vsync_edge <= (vsync && !prev_vsync);
    //     end
    // end
        

    // state
    typedef enum { 
        PDF_CALC,
        CDF_CALC,
        CLEAR
    } state_t;

    state_t c_state, n_state;

    // state, count, cdf  Flip-Flop
    // Count Number of [Each Gamma Value] & Store In PDF_RAM
    // Store Corrected Data In LUT_RAM
    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            c_state <= PDF_CALC;
            c_count <= 0;
            c_cdf   <= 0;
        end else begin
            c_state <=  n_state;
            c_count <= n_count;
            c_cdf   <= n_cdf;

            if (c_state == CDF_CALC) begin  // Store Corrected Data In LUT_RAM
                LUT_RAM[c_count] <= cdf_result [25:18];

            end else if (c_state == PDF_CALC) begin
                if (valid_in)                     // Count Number of [Gamma Value] At the time of valid_in
                    PDF_RAM[data] <= PDF_RAM[data] + 1;

            end else begin                  // RAM Clear
                PDF_RAM[c_count] <= 0;
            end
        end
    end

    always_comb begin
        n_state = c_state;
        n_count = c_count;
        n_cdf   = c_cdf;

        case (c_state)
            PDF_CALC: begin
                if (vsync_edge) begin
                    n_state = CDF_CALC;
                end 
            end

            CDF_CALC: begin
                n_cdf   = c_cdf + PDF_RAM[c_count];       // next cdf
                n_count = c_count + 1;

                if (c_count == CDF_COUNT_SIZE - 1) begin
                    n_count = 0;
                    n_state = CLEAR;
                end
            end

            CLEAR: begin                                // for PDF_RAM Clear
                n_count = c_count + 1;

                if (c_count == 256 - 1) begin
                    n_cdf   = 0;
                    n_state = PDF_CALC;
                end
            end
        endcase
    end

    always_ff @(posedge pclk) begin
        he_data     <= LUT_RAM[data];
        valid_out   <= valid_in;   // 데이터와 함께 1클럭 지연
        vsync_out   <= vsync_edge; // 데이터와 함께 1클럭 지연
    end

    // assign valid_out = valid_in;
    // assign vsync_out = vsync_edge;


endmodule
