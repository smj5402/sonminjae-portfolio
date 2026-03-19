`timescale 1ns / 1ps
module top_VGA_OV7670 (
    input  logic       clk,
    input  logic       reset,
    input  logic [8:0] sw,
    input  logic       sw_servo,
    input  logic       sw_scale,
    input  logic       btnU,
    input  logic       btnD,
    input  logic       btnL,
    input  logic       btnR,
    // OV7670 side 
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    output logic       led,
    // SPI interface
    output logic       spi_sclk,
    output logic       spi_mosi,
    input  logic       spi_miso,
    output logic       spi_cs,
    // I2C
    inout  logic       sda,
    output logic       scl,
    output logic       vsync_out,
    //  Ultrasonic
    output logic       trig,
    input  logic       echo,
    // uart_tx
    output logic       uart_tx,
    // VGA 
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,
    output logic       h_sync,
    output logic       v_sync,
    // servo
    output logic       pwm
);

    logic                       clk_100m;
    logic [                9:0] x_pixel;
    logic [                9:0] y_pixel;
    logic                       DE;
    logic                       rclk;
    logic [$clog2(320*240)-1:0] rAddr;
    logic [                7:0] rData;
    logic                       we;
    logic [$clog2(320*240)-1:0] wAddr;
    logic [                7:0] wData;
    logic [3:0] w_port_red, w_port_green, w_port_blue;
    logic [15:0] rgb_data;

    // ISP control signals
    logic        valid;
    logic        vsync_edge;

    // filter sel
    logic        gamma_sel;
    logic        histo_sel;
    logic        median_sel;
    logic        gaussian_sel;
    logic        scharr_sel;
    logic        erosion_sel;
    logic        dilation_sel;
    logic        stretching_sel;
    logic        temporal_sel;

    // ultra sonic
    logic [ 7:0] distance;
    // PWM
    logic        clean_btnU;
    logic        clean_btnD;
    logic        clean_btnL;
    logic        clean_btnR;
    // Servo motor
    logic [ 7:0] degree;


    assign vsync_out = vsync_edge;

    // clk wizard
    clk_wiz_0 clk_wizard (
        .clk_out1(clk_100m), // 100
        .clk_out2(),     // 12.5
        .clk_out3(xclk),     // 25
        .clk_out4(), // 20
        .clk_out5(), //17.5
        .reset   (reset),
        .locked  (),
        .clk_in1 (clk)
    );

    filter_sel U_FILTER_SEL (
        .clk           (clk_100m),
        .reset         (reset),
        .vsync_edge    (vsync_edge),
        .sw            (sw),
        .gamma_sel     (gamma_sel),
        .histo_sel     (histo_sel),
        .median_sel    (median_sel),
        .gaussian_sel  (gaussian_sel),
        .scharr_sel    (scharr_sel),
        .erosion_sel   (erosion_sel),
        .dilation_sel  (dilation_sel),
        .temporal_sel  (temporal_sel),
        .stretching_sel(stretching_sel)
    );

    SCCB_Register_set U_SCCB_Register_set (
        .clk  (clk_100m),
        .reset(reset),
        .scl  (scl),
        .sda  (sda)
    );

    OV7670_MemController U_OV7670_MemController (
        .pclk      (pclk),
        .reset     (reset),
        .href      (href),
        .vsync     (vsync),
        .data      (data),
        .valid     (valid),
        .vsync_edge(vsync_edge),
        .rgb_data  (rgb_data)
    );

    ISP U_ISP (
        .pclk(pclk),
        .reset(reset),
        .clean_btnU(clean_btnU),
        .clean_btnD(clean_btnD),
        .valid(valid),
        .rgb_data(rgb_data),
        .vsync_edge(vsync_edge),
        .we(we),  //  FIFO의 wr_en으로 들어갈 신호
        .wdata(wData),  //  FIFO의 wr_data로 들어갈 신호
        .waddr(wAddr),
        .temporal_sel(temporal_sel),
        .stretching_sel(stretching_sel),
        .gamma_sel(gamma_sel),
        .histo_sel(histo_sel),
        .median_sel(median_sel),
        .gaussian_sel(gaussian_sel),
        .scharr_sel(scharr_sel),
        .erosion_sel(erosion_sel),
        .dilation_sel(dilation_sel),
        .gamma_mode(led)
    );

    // Async FIFO 연결 (ISP -> FIFO -> SPI)
    logic       fifo_full;
    logic       fifo_empty;
    logic       fifo_rd_en;
    logic [7:0] fifo_rdata;

    async_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(4096)  
    ) U_ASYNC_FIFO (
        // Write domain ISP side (pclk 25MHz)
        .wr_clk(pclk),
        .wr_reset(reset),
        .wr_en(we & ~fifo_full),  // when fifo is not full
        .wr_data(wData),  // ISP 처리 완료된 8비트 데이터
        .full(fifo_full),

        // Read domain SPI 측 (clk_100m 기준)
        .rd_clk  (clk_100m),
        .rd_reset(reset),
        .rd_en   (fifo_rd_en),
        .rd_data (fifo_rdata),
        .empty   (fifo_empty)
    );


    // SPI Master 연결 및 제어
    logic spi_tx_ready;
    logic spi_start;
    logic spi_done;

    assign spi_start  = (~fifo_empty) & spi_tx_ready;
    assign fifo_rd_en = spi_start;

    spi_master U_SPI_MASTER (
        // internal logic
        .clk(clk_100m),
        .reset(reset),
        .start(spi_start),  // start_trigger
        .tx_data(fifo_rdata),  // data from fifo
        .tx_ready(spi_tx_ready),  // when state is IDLE 
        .rx_data(),  // 카메라 TX만 하므로 필요없음
        .done(spi_done),
        .cpol(1'b0),  // SPI Mode 0 
        .cpha(1'b0),

        // SPI interface
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs  (spi_cs)
    );

    //////////////////////////////////////// ultrasonic + uart tx fifo


    logic       sonic_valid;
    logic       uart_fifo_wr;
    logic       uart_fifo_rd;
    logic [7:0] uart_fifo_rdata;
    logic       uart_fifo_full;
    logic       uart_fifo_empty;
    logic       b_tick;
    logic       tx_start;
    logic [7:0] tx_data_wire;
    logic       tx_busy;

    assign uart_fifo_wr = sonic_valid & ~uart_fifo_full;
    assign tx_start     = ~uart_fifo_empty & ~tx_busy;
    assign uart_fifo_rd = tx_start;

    ultrasonic_sensor u_ultrasonic_sensor (
        .clk       (clk_100m),
        .reset     (reset),
        .sw(sw_servo),
        .i_echo    (echo),
        .i_angle   (degree),
        .o_trig    (trig),
        .o_distance(distance),
        .o_valid   (sonic_valid)
    );

    fifo #(
        .DATA_WIDTH(8),
        .MEM_SIZE  (16)
    ) U_UART_TX_FIFO (
        .clk  (clk_100m),
        .reset(reset),
        .wr   (uart_fifo_wr),
        .rd   (uart_fifo_rd),
        .wdata(distance),
        .rdata(uart_fifo_rdata),
        .full (uart_fifo_full),
        .empty(uart_fifo_empty)
    );

    baud_tick_gen U_TICK_GEN (
        .clk   (clk_100m),
        .rst   (reset),
        .b_tick(b_tick)
    );

    uart_tx U_UART_TX (
        .clk          (clk_100m),
        .rst          (reset),
        .start_trigger(tx_start),
        .tx_data      (uart_fifo_rdata),
        .b_tick       (b_tick),
        .tx           (uart_tx),
        .tx_busy      (tx_busy)
    );


    ////////////////////////////////////////// btn debouncer
    btn_debouncer #(
        .DEBOUNCE_LIMIT(20'd999_999)
    ) U_BTNU_DEBOPUNCE (
        .clk(clk_100m),
        .reset(reset),
        .noisy_btn(btnU),  // raw noisy button input
        .clean_btn(clean_btnU)
    );

    btn_debouncer #(
        .DEBOUNCE_LIMIT(20'd999_999)
    ) U_BTND_DEBOPUNCE (
        .clk(clk_100m),
        .reset(reset),
        .noisy_btn(btnD),  // raw noisy button input
        .clean_btn(clean_btnD)
    );

    btn_debouncer #(
        .DEBOUNCE_LIMIT(20'd999_999)
    ) U_BTNL_DEBOPUNCE (
        .clk(clk_100m),
        .reset(reset),
        .noisy_btn(btnL),  // raw noisy button input
        .clean_btn(clean_btnL)
    );

    btn_debouncer #(
        .DEBOUNCE_LIMIT(20'd999_999)
    ) U_BTNR_DEBOPUNCE (
        .clk(clk_100m),
        .reset(reset),
        .noisy_btn(btnR),  // raw noisy button input
        .clean_btn(clean_btnR)
    );

    /////////////////////////////////////// overlay and VGA 


    VGA_Decoder U_VGA_DECODER (
        .clk    (clk_100m),
        .reset  (reset),
        .pclk   (rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE)
    );

    //////////////////////////////// servo motor
    servo_motor_controller U_SERVO_MOTOR_CTRL (
        .clk   (clk_100m),
        .reset (reset),
        .sw    (sw_servo),
        .btnL  (clean_btnL),
        .btnR  (clean_btnR),
        .pwm   (pwm),
        .degree(degree)
    );

    // Top 모듈 내 인스턴스 부분
    overlay_all U_OVERLAY_ALL (
        .clk       (clk_100m),
        .reset     (reset),
        .DE        (DE),
        .sw_scale  (sw_scale),
        .angle     (degree),
        .distance  (distance),
        .dist_valid(sonic_valid),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .i_rgb     (12'h000),
        .o_rgb     ({port_red, port_green, port_blue})
    );



endmodule














///////////////////////////////////// Button Debouncer
module btn_debouncer #(
    parameter DEBOUNCE_LIMIT = 20'd999_999
) (
    input      clk,
    input      reset,
    input      noisy_btn,  // raw noisy button input
    output reg clean_btn
);
    reg [19:0] count;
    reg btn_state = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin  // active-high reset
            count <= 0;
            btn_state <= 0;
            clean_btn <= 0;
        end else if (noisy_btn == btn_state) begin
            count <= 0;
        end else begin
            if (count < DEBOUNCE_LIMIT) count <= count + 1;
            else begin
                btn_state <= noisy_btn;
                clean_btn <= noisy_btn;
                count <= 0;
            end
        end
    end
endmodule



