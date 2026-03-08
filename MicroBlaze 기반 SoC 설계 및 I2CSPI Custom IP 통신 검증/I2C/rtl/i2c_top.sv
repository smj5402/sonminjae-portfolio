`timescale 1ns / 1ps
module i2c_top (
    input  logic       clk,
    input  logic       reset,
    // Master
    input  logic       m_i2c_en,
    input  logic       m_i2c_start,
    input  logic       m_i2c_stop,
    input  logic [7:0] m_tx_data,
    output logic       m_tx_done,
    output logic       m_tx_ready,
    output logic [7:0] m_rx_data,
    output logic       m_rx_done,
    // Slave
    input  logic [6:0] s_device_addr,
    input  logic [7:0] s_tx_data,
    output logic [7:0] s_rx_data,
    output logic       s_tx_done,
    output logic       s_tx_ready,
    output logic       s_rx_done,
    // external
    output logic       i2c_scl,
    inout  wire        i2c_sda
);

    wire w_scl;
    assign i2c_scl = w_scl;


    i2c_master U_I2C_Master (
        .clk      (clk),
        .reset    (reset),
        .i2c_en   (m_i2c_en),
        .i2c_start(m_i2c_start),
        .i2c_stop (m_i2c_stop),
        .tx_data  (m_tx_data),
        .tx_done  (m_tx_done),
        .tx_ready (m_tx_ready),
        .rx_data  (m_rx_data),
        .rx_done  (m_rx_done),
        .scl      (w_scl),
        .sda      (i2c_sda)
    );


    i2c_slave U_I2C_Slave (
        .clk        (clk),
        .reset      (reset),
        .scl        (w_scl),
        .sda        (i2c_sda),
        .device_addr(s_device_addr),
        .tx_data    (s_tx_data),
        .rx_data    (s_rx_data),
        .tx_done    (s_tx_done),
        .tx_ready   (s_tx_ready),
        .rx_done    (s_rx_done)
    );

endmodule
