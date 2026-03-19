`timescale 1ns / 1ps

module TOP_VGA (
    // global signals
    input  logic       clk,
    input  logic       reset,
    input  logic       sw,
    // master side signals
    input  logic       sclk,
    output logic       miso,
    input  logic       mosi,
    input  logic       cs,
    input  logic       uart_rx,
    // VGA side signals
    output logic       v_sync,
    output logic       h_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,
    output logic [5:0] led,
    input  logic       vsync_in
);
    // frame buffer write
    logic we;
    logic [$clog2(320*240)-1:0] wAddr;
    logic [7:0] wData;

    // frame buffer read
    logic rclk;
    logic [$clog2(320*240)-1:0] rAddr;
    logic [7:0] rData;

    // VGA Decoder
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic DE;
    // logic frame_done;

    logic [7:0] distance;
    logic [3:0] w_port_red, w_port_green, w_port_blue;
    logic [11:0] green;

    uart_rx #(
        .BPS(9600)
    ) u_uart_rx (
        .clk(clk),
        .reset(reset),
        .rx(uart_rx),
        .data_out(distance),
        .rx_done()
    );


    // slave_top : SPI + FIFO + Addr_gen
    slave_top u_SPI_slave_top (
        .clk             (clk),
        .reset           (reset),
        // SPI external pins
        .spi_sclk        (sclk),
        .spi_miso        (miso),
        .spi_mosi        (mosi),
        .spi_cs_n        (cs),
        // downstream interface
        .downstream_ready(1'b1),     // 항상 준비됨 
        .output_data     (wData),
        .rx_fifo_empty   (),         // 사용 X 
        .waddr           (wAddr),
        .we              (we),
        .vsync_in        (vsync_in)
    );

    PingPong_Buffer u_PingPong_Buffer (
        .wclk (clk),
        .reset(reset),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .rAddr(rAddr),
        .rData(rData),
        .led  (led)
    );

    VGA_Decoder U_VGA_Decoder (
        .clk    (clk),
        .reset  (reset),
        .pclk   (rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE)
    );

    ImgMemReader_upscaler U_FBuffReader (
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .addr(rAddr),
        .imgData(rData),
        .port_red  (w_port_red),   
        .port_green(w_port_green),
        .port_blue(w_port_blue)
    );

    green_scale_filter U_GREENSCALE (
        .i_rgb({w_port_red, w_port_green, w_port_blue}),
        .o_rgb(green)
    );

    wire [11:0] green_on = sw ? green : {w_port_red, w_port_green, w_port_blue};

    overlay_all #(
        .x_start(500),
        .y_start(20)
    ) u_overlay_all (
        .clk     (rclk),
        .distance(distance),
        .x_number(),
        .y_number(),
        .x_pixel (x_pixel),
        .y_pixel (y_pixel),
        .i_rgb   (green_on),
        .o_rgb   ({port_red, port_green, port_blue})
    );
endmodule


module green_scale_filter (
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);

    logic [11:0] green;

    assign green = 16 * i_rgb[11:8];
    assign o_rgb = {green[11:8], green[7:4], green[3:0]};

endmodule
