`timescale 1ns / 1ps

module spi_rx_fifo (
    input logic clk,
    input logic reset,
    // SPI pins
    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs_n,
    // FIFO Interface
    input  logic       fifo_rd_en,
    output logic [7:0] fifo_rdata,
    output logic       fifo_empty
);

    logic [7:0] spi_rx_data;
    logic       spi_done;
    logic       fifo_full;
    logic       fifo_wr_en;

    assign fifo_wr_en = spi_done & ~fifo_full;

    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .sclk   (spi_sclk),
        .mosi   (spi_mosi),
        .miso   (spi_miso),
        .cs     (spi_cs_n),
        .tx_data(8'h00),
        .rx_data(spi_rx_data),
        .done   (spi_done)
    );

    fifo #(
        .DATA_WIDTH(8),
        .MEM_SIZE  (4096)
    ) U_SYNC_FIFO (
        .clk  (clk),
        .reset(reset),
        .wr   (fifo_wr_en),
        .rd   (fifo_rd_en),
        .wdata(spi_rx_data),
        .rdata(fifo_rdata),
        .full (fifo_full),
        .empty(fifo_empty)
    );

endmodule
