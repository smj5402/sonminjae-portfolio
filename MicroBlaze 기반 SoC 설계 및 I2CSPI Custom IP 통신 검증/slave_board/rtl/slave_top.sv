`timescale 1ns / 1ps

module TOP (
    // global signals
    input logic clk,
    input logic reset,
    // SPI
    input logic sclk,
    input logic mosi,
    output logic miso,
    input logic cs_n,
    output logic [7:0] LED_LOW,
    // I2C
    input logic SCL,
    inout logic SDA,
    output logic [7:0] LED_HIGH
);

    logic [7:0] s_rx_data;
    logic       spi_done;
    logic       i2c_rx_done;

    // SPI Slave
    SPI_SLAVE u_SPI_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n),
        .rx_data(s_rx_data),
        .done   (spi_done),
        .LED_LOW(LED_LOW)
    );

    // I2C Slave
    I2C_SLA u_I2C_SLA (
        .clk     (clk),
        .reset   (reset),
        .tx_data (8'd0),
        .tx_done (),
        .tx_ready(),
        .rx_data (),
        .rx_done (i2c_rx_done),
        .SCL     (SCL),
        .SDA     (SDA),
        .LED_HIGH(LED_HIGH)
    );

endmodule
