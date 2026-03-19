`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

import spi_pkg::*;

module tb_top;

    logic clk;
    logic clk_25;
    logic reset;

    // 100 MHz 10ns
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // 25 MHz 40ns
    initial clk_25 = 1'b0;
    always #20 clk_25 = ~clk_25;

    // Reset : assert for 20 clk cycles
    initial begin
        reset = 1'b1;
        repeat (20) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
    end

    spi_if dut_if (
        .clk(clk),
        .clk_25(clk_25)
    );

    assign dut_if.reset = reset;

    // DUT
    top_spi_fifo_loopback u_dut (
        .clk        (clk),
        .clk_25     (clk_25),
        .reset      (reset),
        // tx side
        .tx_wr_en   (dut_if.tx_wr_en),
        .tx_wr_data (dut_if.tx_wr_data),
        .tx_full    (dut_if.tx_full),
        .tx_empty   (dut_if.tx_empty),
        // rx side
        .rx_rd_en   (dut_if.rx_rd_en),
        .rx_rd_data (dut_if.rx_rd_data),
        .rx_full    (dut_if.rx_full),
        .rx_empty   (dut_if.rx_empty),
        // SPI interface 
        .spi_sclk   (dut_if.spi_sclk),
        .spi_mosi   (dut_if.spi_mosi),
        .spi_cs     (dut_if.spi_cs),
        .master_done(dut_if.master_done)
    );

    initial begin
        uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top.*", "vif",
                                            dut_if);
        run_test();
    end

    initial begin
        $fsdbDumpfile("build/wave.fsdb");
        $fsdbDumpvars(0, tb_top);
    end
endmodule
