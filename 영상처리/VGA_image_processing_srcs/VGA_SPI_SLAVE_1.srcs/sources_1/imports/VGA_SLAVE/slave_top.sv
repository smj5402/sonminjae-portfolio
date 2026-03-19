`timescale 1ns / 1ps

module slave_top (
    input logic clk,
    input logic reset,

    // SPI external pins
    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs_n,

    // downstream interface (To PingPong Buffer)
    input  logic        downstream_ready, 
    output logic [7:0] output_data,
    output logic rx_fifo_empty,
    output logic [16:0] waddr,
    output logic we,
    input logic vsync_in
);

    // internal wires
    logic       fifo_rd_en;
    logic [7:0] fifo_rdata;

    spi_rx_fifo U_SPI_RX_FIFO (
        .clk       (clk),
        .reset     (reset),
        .spi_sclk  (spi_sclk),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .spi_cs_n  (spi_cs_n),
        .fifo_rd_en(fifo_rd_en),
        .fifo_rdata(fifo_rdata),
        .fifo_empty(rx_fifo_empty)
    );

    addr_gen U_ADDR_GEN (
        .clk       (clk),
        .reset     (reset),
        .fifo_empty(rx_fifo_empty),
        .fifo_rdata(fifo_rdata),
        .fifo_rd_en(fifo_rd_en),
        .waddr     (waddr),
        .wdata     (output_data),
        .we        (we),
        .vsync_in  (vsync_in)
    );

endmodule

`timescale 1ns / 1ps

module addr_gen (
    input logic clk,
    input logic reset,

    // From Stage 1 (FIFO)
    input  logic       fifo_empty,
    input  logic [7:0] fifo_rdata,
    output logic       fifo_rd_en,

    // To Stage 3 (PingPong Buffer)
    output logic [16:0] waddr,
    output logic [ 7:0] wdata,
    output logic        we,
    input  logic        vsync_in
);

    logic [16:0] current_addr;

    assign fifo_rd_en = ~fifo_empty;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_addr <= 17'd0;
            waddr        <= 17'd0;
            wdata        <= 8'd0;
            we           <= 1'b0;
        end else if (vsync_in) begin
            current_addr <= 17'd0;
            we           <= 1'b0;
        end else begin
            if (~fifo_empty) begin
                wdata <= fifo_rdata;
                waddr <= current_addr;
                we    <= 1'b1;

                // 320 x 240 - 1 = 76799
                if (current_addr == 17'd76799) begin
                    current_addr <= 17'd0;
                end else begin
                    current_addr <= current_addr + 17'd1;
                end
            end else begin
                we <= 1'b0;
            end
        end
    end

endmodule
