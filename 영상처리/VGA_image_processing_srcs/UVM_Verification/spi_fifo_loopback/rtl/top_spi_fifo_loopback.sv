`timescale 1ns / 1ps

module top_spi_fifo_loopback (
    //  global signals
    input  logic       clk,        // 100 MHz system clock
    input  logic       clk_25,     // 25 MHz  (async_fifo write-side)
    input  logic       reset,

    input  logic       tx_wr_en,
    input  logic [7:0] tx_wr_data,
    output logic       tx_full,
    output logic       tx_empty,   

    input  logic       rx_rd_en,
    output logic [7:0] rx_rd_data,
    output logic       rx_full,
    output logic       rx_empty,

    output logic       spi_sclk,
    output logic       spi_mosi,
    output logic       spi_cs,
    output logic       master_done 
);

    //  internal wires 
    // async_fifo (tx_fifo) rd-side
    logic       tx_rd_en;
    logic [7:0] tx_rd_data;

    // SPI interface (master <-> slave)
    logic spi_miso;

    // spi_master 
    logic       master_tx_ready;
    logic [7:0] master_rx_data;  // data master received through miso 

    // spi_slave output
    logic [7:0] slave_rx_data;
    logic       slave_done;

    // rx_fifo status
    logic       rx_fifo_full;


    async_fifo #(
        .DATA_WIDTH(8),
        .DEPTH     (16)
    ) u_tx_fifo (
        // write side  (clk_25 domain)
        .wr_clk   (clk_25),
        .wr_reset (reset),
        .wr_en    (tx_wr_en),
        .wr_data  (tx_wr_data),
        .full     (tx_full),
        // read side   (sys_clk domain)
        .rd_clk   (clk),
        .rd_reset (reset),
        .rd_en    (tx_rd_en),
        .rd_data  (tx_rd_data),
        .empty    (tx_empty)
    );


    assign tx_rd_en = master_tx_ready && !tx_empty;


    spi_master u_spi_master (
        .clk      (clk),
        .reset    (reset),
        // control
        .start    (tx_rd_en),      // transfer on the same cycle : pop tx_fifo
        .tx_data  (tx_rd_data),    // combinational read from tx_fifo
        .tx_ready (master_tx_ready),
        .rx_data  (master_rx_data),
        .done     (master_done),
        .cpol     (1'b0),   // mode 0 
        .cpha     (1'b0),   // mode 0 
        // SPI interface
        .sclk     (spi_sclk),
        .mosi     (spi_mosi),
        .miso     (spi_miso),
        .cs       (spi_cs)
    );


    spi_slave u_spi_slave (
        .clk      (clk),
        .reset    (reset),
        // SPI interface
        .sclk     (spi_sclk),
        .mosi     (spi_mosi),
        .miso     (spi_miso),
        .cs       (spi_cs),
        // data interface
        .tx_data  (8'h00),         // miso : tie to 0 
        .rx_data  (slave_rx_data),
        .done     (slave_done)
    );

    
    assign rx_full = rx_fifo_full;

    fifo #(
        .DATA_WIDTH(8),
        .MEM_SIZE  (8)
    ) u_rx_fifo (
        .clk   (clk),
        .reset (reset),
        .wr    (slave_done && !rx_fifo_full),  // push only when not full
        .rd    (rx_rd_en),
        .wdata (slave_rx_data),
        .rdata (rx_rd_data),
        .full  (rx_fifo_full),
        .empty (rx_empty)
    );

endmodule
