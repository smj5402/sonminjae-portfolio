`timescale 1ns / 1ps
module spi_top (
    input  logic       clk,
    input  logic       reset,
    // Master interface
    input  logic       m_start,
    input  logic [7:0] m_tx_data,
    output logic       m_tx_ready,
    output logic [7:0] m_rx_data,
    output logic       m_done,
    // Slave interface
    input  logic [7:0] s_tx_data,
    output logic [7:0] s_rx_data,
    output logic       s_done
);

    // SPI bus signals
    logic sclk;
    logic mosi;
    logic miso;
    logic cs_n;

    // CS generation - active during transaction
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            cs_n <= 1'b1;
        else if (m_start && m_tx_ready)
            cs_n <= 1'b0;
        else if (m_done)
            cs_n <= 1'b1;
    end

    spi_master u_master (
        .clk      (clk),
        .reset    (reset),
        .start    (m_start),
        .tx_data  (m_tx_data),
        .tx_ready (m_tx_ready),
        .rx_data  (m_rx_data),
        .done     (m_done),
        .cpol     (1'b0),       // Mode 0
        .cpha     (1'b0),       // Mode 0
        .sclk     (sclk),
        .mosi     (mosi),
        .miso     (miso)
    );

    spi_slave u_slave (
        .clk      (clk),
        .reset    (reset),
        .sclk     (sclk),
        .mosi     (mosi),
        .miso     (miso),
        .cs       (cs_n),
        .tx_data  (s_tx_data),
        .rx_data  (s_rx_data),
        .done     (s_done)
    );

endmodule