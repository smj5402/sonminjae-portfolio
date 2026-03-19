`timescale 1ns / 1ps

interface spi_if (
    input logic clk,
    input logic clk_25
);
    logic       reset;

    //  tx side  (clk_25 domain) 
    logic        tx_wr_en;
    logic [7:0]  tx_wr_data;
    logic        tx_full;
    logic        tx_empty;

    //  rx side  clk domain
    logic        rx_rd_en;
    logic [7:0]  rx_rd_data;
    logic        rx_full;
    logic        rx_empty;

    // ── SPI interface  clk domain
    logic        spi_sclk;
    logic        spi_mosi;
    logic        spi_cs;
    logic        master_done;

    //  clocking blocks 
    // TX driver  :  write test vectors into async_fifo on clk_25
    clocking tx_cb @(posedge clk_25);
        default input #1 output #1;
        output tx_wr_en, tx_wr_data;
        input  tx_full, tx_empty;
    endclocking

    // RX monitor :  read received bytes from rx_fifo on clk
    clocking rx_cb @(posedge clk);
        default input #1 output #1;
        output rx_rd_en;
        input  rx_rd_data, rx_full, rx_empty, master_done;
    endclocking

    // SPI interface monitor (passive, clk domain)
    clocking spi_mon_cb @(posedge clk);
        default input #1;
        input spi_sclk, spi_mosi, spi_cs, master_done;
    endclocking

    clocking tx_mon_cb @(posedge clk_25);
        default input #1;
        input tx_wr_en, tx_wr_data, tx_full, tx_empty;
    endclocking

endinterface
