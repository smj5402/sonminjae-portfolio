module ISP (
    input  logic        pclk,
    input  logic        reset,
    input  logic        clean_btnU,
    input  logic        clean_btnD,
    // memory controller side
    input  logic        valid,
    input  logic [15:0] rgb_data,
    input  logic        vsync_edge,
    // frame buffer side
    output logic        we,
    output logic [ 7:0] wdata,
    output logic [16:0] waddr,
    // FPGA
    input  logic        temporal_sel,
    input  logic        stretching_sel,
    input  logic        median_sel,
    input  logic        gamma_sel,
    input  logic        histo_sel,
    input  logic        gaussian_sel,
    input  logic        scharr_sel,
    input  logic        erosion_sel,
    input  logic        dilation_sel,
    // input  logic        green_sel,
    output logic        gamma_mode
);
    // data signals
    logic [7:0] gray;
    logic [7:0] temporal;
    logic [7:0] stretching;
    logic [7:0] gamma;
    logic [7:0] histo;
    logic [7:0] median;
    logic [7:0] gaussian;
    logic [7:0] scharr;
    logic [7:0] erosion;
    logic [7:0] dilation;
    // logic [7:0] green;


    logic [7:0] temporal_in;
    logic [7:0] stretching_in;
    logic [7:0] gamma_in;
    logic [7:0] histo_in;
    logic [7:0] median_in;
    logic [7:0] gaussian_in;
    logic [7:0] scharr_in;
    logic [7:0] erosion_in;
    logic [7:0] dilation_in;
    // logic [7:0] green_in;

    // control signals
    logic valid_out_temporal;
    logic valid_out_stretching;
    logic valid_out_median;
    logic valid_out_gamma;
    logic valid_out_histo;
    logic valid_out_gaussian;
    logic valid_out_scharr;
    logic valid_out_erosion;
    logic valid_out_dilation;
    logic valid_out_addr;

    logic vsync_out_temporal;
    logic vsync_out_stretching;
    logic vsync_out_median;
    logic vsync_out_gamma;
    logic vsync_out_histo;
    logic vsync_out_gaussian;
    logic vsync_out_scharr;
    logic vsync_out_erosion;
    logic vsync_out_dilation;
    logic vsync_out_addr;



    // assign gamma_in  = median_sel ? median : gray;

    // wire valid_in_gamma = median_sel ? valid_out_median : valid;
    // wire vsync_in_gamma = median_sel ? vsync_out_median : vsync_edge;
    // 




    // histogram equalization
    assign histo_in = gamma_sel ? gamma : gray;
    wire valid_in_histo = gamma_sel ? valid_out_gamma : valid;
    wire vsync_in_histo = gamma_sel ? vsync_out_gamma : vsync_edge;

    // median
    assign median_in = histo_sel ? histo : histo_in;
    wire valid_in_median = histo_sel ? valid_out_histo : valid_in_histo;
    wire vsync_in_median = histo_sel ? vsync_out_histo : vsync_in_histo;

    //temporal_accumulation
    assign temporal_in = median_sel ? median : median_in;
    wire valid_in_temporal = median_sel ? valid_out_median : valid_in_median;
    wire vsync_in_temporal = median_sel ? vsync_out_median : vsync_in_median;


    //dynamic_stretching
    assign stretching_in = temporal_sel ? temporal : temporal_in;
    wire valid_in_stretching =temporal_sel ? valid_out_temporal : valid_in_temporal;
    wire vsync_in_stretching =temporal_sel ? vsync_out_temporal : vsync_in_temporal;

    // gaussian
    assign gaussian_in = stretching_sel ? stretching : stretching_in;
    wire valid_in_gaussian = stretching_sel ? valid_out_stretching : valid_in_stretching;
    wire vsync_in_gaussian = stretching_sel ? vsync_out_stretching : vsync_in_stretching;

    // scharr
    assign scharr_in = gaussian_sel ? gaussian : gaussian_in;
    wire valid_in_scharr = gaussian_sel ? valid_out_gaussian : valid_in_gaussian;
    wire vsync_in_scharr = gaussian_sel ? vsync_out_gaussian : vsync_in_gaussian;

    // erosion
    assign erosion_in = scharr_sel ? scharr : scharr_in;
    wire valid_in_erosion = scharr_sel ? valid_out_scharr : valid_in_scharr;
    wire vsync_in_erosion = scharr_sel ? vsync_out_scharr : vsync_in_scharr;

    // dilation
    assign dilation_in = erosion_sel ? erosion : erosion_in;
    wire valid_in_dilation = erosion_sel ? valid_out_erosion : valid_in_erosion;
    wire vsync_in_dilation = erosion_sel ? vsync_out_erosion : vsync_in_erosion;

    // green
    // assign green_in = dilation_sel ? dilation : dilation_in;
    // output
    assign wdata = dilation_sel ? dilation : dilation_in;
    wire valid_in_addr = dilation_sel ? valid_out_dilation : valid_in_dilation;
    wire vsync_in_addr = dilation_sel ? vsync_out_dilation : vsync_in_dilation;


    grey_scale_filter U_GREYSCALE (
        .i_rgb ({rgb_data[15:12], rgb_data[10:7], rgb_data[4:1]}),
        .o_grey(gray)
    );

    //////////////////////////////////////////////////////////////////////////////////////////////////
    temporal_accumulation u_temporal_accumulation (
        .pclk         (pclk),
        .reset        (reset),
        .valid_in     (valid_in_temporal),
        .vsync_edge   (vsync_in_temporal),
        .i_gray       (temporal_in),
        .valid_out    (valid_out_temporal),
        .vsync_out    (vsync_out_temporal),
        .o_accumulated(temporal)
    );


    dynamic_stretching u_dynamic_stretching (
        .pclk         (pclk),
        .reset        (reset),
        .valid_in     (valid_in_stretching),
        .vsync_edge   (vsync_in_stretching),
        .i_accumulated(stretching_in),
        .valid_out    (valid_out_stretching),
        .vsync_out    (vsync_out_stretching),
        .o_stretched  (stretching)
    );
    //////////////////////////////////////////////////////////////////////////////////////////////////

    gamma_LUT_correct U_Gamma_CORRECT (
        .pclk           (pclk),
        .reset          (reset),
        .valid_in       (valid),
        .vsync_edge     (vsync_edge),
        .pixel_pre      (gray),
        .valid_out      (valid_out_gamma),
        .vsync_out      (vsync_out_gamma),
        .gamma_mode     (gamma_mode),       // led
        .corrected_pixel(gamma)
    );

    Histogram_Equalization #(
        .CDF_COUNT_SIZE(256)
    ) U_Histogram_Equalization (
        .pclk      (pclk),
        .reset     (reset),
        .valid_in  (valid_in_histo),
        .vsync_edge(vsync_in_histo),
        .data      (histo_in),
        .valid_out (valid_out_histo),
        .vsync_out (vsync_out_histo),
        .he_data   (histo)
    );

    median_filter U_medain_filter (
        .pclk      (pclk),
        .reset     (reset),
        .valid_in  (valid_in_median),
        .vsync_edge(vsync_in_median),
        .i_grey    (median_in),
        .valid_out (valid_out_median),
        .vsync_out (vsync_out_median),
        .o_grey    (median)
    );

    gaussian_filter u_gaussian_filter (
        .pclk      (pclk),
        .reset     (reset),
        .valid_in  (valid_in_gaussian),
        .vsync_edge(vsync_in_gaussian),
        .i_gray    (gaussian_in),
        .valid_out (valid_out_gaussian),
        .vsync_out (vsync_out_gaussian),
        .o_grey    (gaussian)
    );

    Sharr_filter U_Sharr_filter (
        .pclk      (pclk),
        .reset     (reset),
        .btnU      (clean_btnU),
        .btnD      (clean_btnD),
        .valid_in  (valid_in_scharr),
        .vsync_edge(vsync_in_scharr),
        .i_gray    (scharr_in),
        .valid_out (valid_out_scharr),
        .vsync_out (vsync_out_scharr),
        .o_rgb     (scharr)
    );

    morphology_filter u_erosion (
        .pclk      (pclk),
        .reset     (reset),
        .valid_in  (valid_in_erosion),
        .vsync_edge(vsync_in_erosion),
        .mode      (1'b0),
        .i_gray    (erosion_in),
        .valid_out (valid_out_erosion),
        .vsync_out (vsync_out_erosion),
        .o_pixel   (erosion)
    );

    morphology_filter u_dilation (
        .pclk      (pclk),
        .reset     (reset),
        .valid_in  (valid_in_dilation),
        .vsync_edge(vsync_in_dilation),
        .mode      (1'b1),
        .i_gray    (dilation_in),
        .valid_out (valid_out_dilation),
        .vsync_out (vsync_out_dilation),
        .o_pixel   (dilation)
    );

    // green_scale_filter U_GREENSCALE (
    //     .i_rgb(green_in),
    //     .o_rgb(green)
    // );

    addr_gen u_addr_gen (
        .clk       (pclk),
        .reset     (reset),
        .valid     (valid_in_addr),
        .vsync_edge(vsync_in_addr),
        .waddr     (waddr),
        .we        (we)
    );
endmodule

module grey_scale_filter (
    input  logic [11:0] i_rgb,
    output logic [ 7:0] o_grey
);

    logic [11:0] grey;

    assign grey   = 51 * i_rgb[11:8] + 179 * i_rgb[7:4] + 26 * i_rgb[3:0];
    assign o_grey = grey[11:4];

endmodule

// module green_scale_filter (
//     input  logic [7:0] i_rgb,
//     output logic [7:0] o_rgb
// );

//     logic [11:0] green;

//     assign green = 16 * i_rgb[7:4];
//     assign o_rgb = {green[11:8], green[7:4], green[3:0]};

// endmodule

module addr_gen (
    input  logic        clk,
    input  logic        reset,
    input  logic        vsync_edge,  // 프레임 시작
    input  logic        valid,       // 픽셀 단위 쓰기 펄스
    output logic [16:0] waddr,
    output logic        we
);
    logic [8:0] x_addr;
    logic [7:0] y_addr;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_addr <= 9'd0;
            y_addr <= 8'd0;
            waddr  <= 17'd0;
            we     <= 1'b0;
        end else if (vsync_edge) begin
            x_addr <= 9'd0;
            y_addr <= 8'd0;
            waddr  <= 17'd0;
            we     <= 1'b0;
        end else begin
            we <= 1'b0;  // 기본적으로 Write Disable

            if (valid) begin
                waddr <= y_addr * 17'd320 + x_addr;  // 현재 주소 계산
                we    <= 1'b1;  // 1클럭 동안 Write Enable

                if (x_addr == 9'd319) begin
                    x_addr <= 9'd0;
                    if (y_addr < 8'd239) y_addr <= y_addr + 8'd1;
                end else begin
                    x_addr <= x_addr + 9'd1;
                end
            end
        end
    end
endmodule

































// `timescale 1ns / 1ps

// module ISP (
//     input  logic        pclk,
//     input  logic        reset,
//     // memory controller side
//     input  logic        valid,
//     input  logic [15:0] rgb_data,
//     input  logic        vsync_edge,
//     // frame buffer side
//     output logic        we,
//     output logic [ 7:0] wdata,
//     output logic [16:0] waddr,
//     // FPGA
//     input  logic        median_sel,
//     input  logic        gamma_sel,
//     input  logic        histo_sel,
//     input  logic        gaussian_sel,
//     input  logic        scharr_sel,
//     input  logic        erosion_sel,
//     input  logic        dilation_sel,
//     output logic        gamma_mode
// );


//     // data signals
//     logic [7:0] gray;
//     logic [7:0] gamma;
//     logic [7:0] histo;
//     logic [7:0] median;
//     logic [7:0] gaussian;
//     logic [7:0] scharr;
//     logic [7:0] erosion;
//     logic [7:0] dilation;

//     logic [7:0] gamma_in;
//     logic [7:0] histo_in;
//     logic [7:0] median_in;
//     logic [7:0] gaussian_in;
//     logic [7:0] scharr_in;
//     logic [7:0] erosion_in;
//     logic [7:0] dilation_in;

//     // control signals
//     logic valid_out_median;
//     logic valid_out_gamma;
//     logic valid_out_histo;
//     logic valid_out_gaussian;
//     logic valid_out_scharr;
//     logic valid_out_erosion;
//     logic valid_out_dilation;
//     logic valid_out_addr;

//     logic vsync_out_median;
//     logic vsync_out_gamma;
//     logic vsync_out_histo;
//     logic vsync_out_gaussian;
//     logic vsync_out_scharr;
//     logic vsync_out_erosion;
//     logic vsync_out_dilation;
//     logic vsync_out_addr;



//     // assign gamma_in  = median_sel ? median : gray;

//     // wire valid_in_gamma = median_sel ? valid_out_median : valid;
//     // wire vsync_in_gamma = median_sel ? vsync_out_median : vsync_edge;

//     // histogram equalization
//     assign histo_in = gamma_sel ? gamma : gray;
//     wire valid_in_histo = gamma_sel ? valid_out_gamma : valid;
//     wire vsync_in_histo = gamma_sel ? vsync_out_gamma : vsync_edge;

//     // median
//     assign median_in = histo_sel ? histo : histo_in;
//     wire valid_in_median = histo_sel ? valid_out_histo : valid_in_histo;
//     wire vsync_in_median = histo_sel ? vsync_out_histo : vsync_in_histo;

//     // gaussian
//     assign gaussian_in = median_sel ? median : median_in;
//     wire valid_in_gaussian = median_sel ? valid_out_median : valid_in_median;
//     wire vsync_in_gaussian = median_sel ? vsync_out_median : vsync_in_median;

//     // scharr
//     assign scharr_in = gaussian_sel ? gaussian : gaussian_in;
//     wire valid_in_scharr = gaussian_sel ? valid_out_gaussian : valid_in_gaussian;
//     wire vsync_in_scharr = gaussian_sel ? vsync_out_gaussian : vsync_in_gaussian;

//     // erosion
//     assign erosion_in = scharr_sel ? scharr : scharr_in;
//     wire valid_in_erosion = scharr_sel ? valid_out_scharr : valid_in_scharr;
//     wire vsync_in_erosion = scharr_sel ? vsync_out_scharr : vsync_in_scharr;

//     // dilation
//     assign dilation_in = erosion_sel ? erosion : erosion_in;
//     wire valid_in_dilation = erosion_sel ? valid_out_erosion : valid_in_erosion;
//     wire vsync_in_dilation = erosion_sel ? vsync_out_erosion : vsync_in_erosion;

//     // output
//     assign wdata = dilation_sel ? dilation : dilation_in;
//     wire valid_in_addr = dilation_sel ? valid_out_dilation : valid_in_dilation;
//     wire vsync_in_addr = dilation_sel ? vsync_out_dilation : vsync_in_dilation;


//     grey_scale_filter U_GREYSCALE (
//         .i_rgb ({rgb_data[15:12], rgb_data[10:7], rgb_data[4:1]}),
//         .o_grey(gray)
//     );



//     gamma_LUT_correct U_Gamma_CORRECT (
//         .pclk           (pclk),
//         .reset          (reset),
//         .valid_in       (valid),
//         .vsync_edge     (vsync_edge),
//         .pixel_pre      (gray),
//         .valid_out      (valid_out_gamma),
//         .vsync_out      (vsync_out_gamma),
//         .gamma_mode     (gamma_mode),       // led
//         .corrected_pixel(gamma)
//     );

//     Histogram_Equalization #(
//         .CDF_COUNT_SIZE(256)
//     ) U_Histogram_Equalization (
//         .pclk      (pclk),
//         .reset     (reset),
//         .valid_in  (valid_in_histo),
//         .vsync_edge(vsync_in_histo),
//         .data      (histo_in),
//         .valid_out (valid_out_histo),
//         .vsync_out (vsync_out_histo),
//         .he_data   (histo)
//     );

//     median_filter U_medain_filter (
//         .pclk      (pclk),
//         .reset     (reset),
//         .valid_in  (valid_in_median),
//         .vsync_edge(vsync_in_median),
//         .i_grey    (median_in),
//         .valid_out (valid_out_median),
//         .vsync_out (vsync_out_median),
//         .o_grey    (median)
//     );

//     gaussian_filter u_gaussian_filter (
//         .pclk      (pclk),
//         .reset     (reset),
//         .valid_in  (valid_in_gaussian),
//         .vsync_edge(vsync_in_gaussian),
//         .i_gray    (gaussian_in),
//         .valid_out (valid_out_gaussian),
//         .vsync_out (vsync_out_gaussian),
//         .o_grey    (gaussian)
//     );

//     Sharr_filter U_Sharr_filter (
//         .pclk      (pclk),
//         .reset     (reset),
//         .valid_in  (valid_in_scharr),
//         .vsync_edge(vsync_in_scharr),
//         .i_gray    (scharr_in),
//         .valid_out (valid_out_scharr),
//         .vsync_out (vsync_out_scharr),
//         .o_rgb     (scharr)
//     );

//     morphology_filter u_erosion (
//         .pclk      (pclk),
//         .reset     (reset),
//         .valid_in  (valid_in_erosion),
//         .vsync_edge(vsync_in_erosion),
//         .mode      (1'b0),
//         .i_gray    (erosion_in),
//         .valid_out (valid_out_erosion),
//         .vsync_out (vsync_out_erosion),
//         .o_pixel   (erosion)
//     );

//     morphology_filter u_dilation (
//         .pclk      (pclk),
//         .reset     (reset),
//         .valid_in  (valid_in_dilation),
//         .vsync_edge(vsync_in_dilation),
//         .mode      (1'b1),
//         .i_gray    (dilation_in),
//         .valid_out (valid_out_dilation),
//         .vsync_out (vsync_out_dilation),
//         .o_pixel   (dilation)
//     );

//     addr_gen u_addr_gen (
//         .clk       (pclk),
//         .reset     (reset),
//         .valid     (valid_in_addr),
//         .vsync_edge(vsync_in_addr),
//         .waddr     (waddr),
//         .we        (we)
//     );
// endmodule

// module grey_scale_filter (
//     input  logic [11:0] i_rgb,
//     output logic [ 7:0] o_grey
// );

//     logic [11:0] grey;

//     assign grey   = 51 * i_rgb[11:8] + 179 * i_rgb[7:4] + 26 * i_rgb[3:0];
//     assign o_grey = grey[11:4];

// endmodule

// module addr_gen (
//     input  logic        clk,
//     input  logic        reset,
//     input  logic        vsync_edge,  // 프레임 시작
//     input  logic        valid,       // 픽셀 단위 쓰기 펄스
//     output logic [16:0] waddr,
//     output logic        we
// );
//     logic [8:0] x_addr;
//     logic [7:0] y_addr;

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             x_addr <= 9'd0;
//             y_addr <= 8'd0;
//             waddr  <= 17'd0;
//             we     <= 1'b0;
//         end else if (vsync_edge) begin
//             x_addr <= 9'd0;
//             y_addr <= 8'd0;
//             waddr  <= 17'd0;
//             we     <= 1'b0;
//         end else begin
//             we <= 1'b0;  // 기본적으로 Write Disable

//             if (valid) begin
//                 waddr <= y_addr * 17'd320 + x_addr;  // 현재 주소 계산
//                 we    <= 1'b1;  // 1클럭 동안 Write Enable

//                 if (x_addr == 9'd319) begin
//                     x_addr <= 9'd0;
//                     if (y_addr < 8'd239) y_addr <= y_addr + 8'd1;
//                 end else begin
//                     x_addr <= x_addr + 9'd1;
//                 end
//             end
//         end
//     end
// endmodule

