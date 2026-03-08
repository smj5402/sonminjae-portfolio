`timescale 1ns / 1ps
module uart_loopback #(
    parameter DATA_WIDTH = 8,
    MEM_SIZE = 8,
    ADDR_WIDTH = 3
) (
    input  logic clk,
    input  logic reset,
    input  logic rx,
    output logic tx,
    output logic tx_full,
    output logic tx_empty,
    output logic rx_full,
    output logic rx_empty
);
    // from uart_top
    wire [DATA_WIDTH-1:0] w_rx_data;
    wire                  w_rx_done;
    wire                  w_tx_busy;

    // from FIFO rx
    wire [DATA_WIDTH-1:0] w_rdata_rx;


    // from FIFO tx
    wire [DATA_WIDTH-1:0] w_rdata_tx;

    uart_top U_UART_TOP (
        .clk     (clk),
        .rst     (reset),
        .tx_start(~tx_empty),  // from FIFO_tx
        .tx_data (w_rdata_tx),
        .rx      (rx),
        .rx_done (w_rx_done),
        .rx_data (w_rx_data),
        .tx      (tx),
        .tx_busy (w_tx_busy)
    );

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SIZE  (MEM_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) FIFO_RX (
        .clk  (clk),
        .reset(reset),
        .wr   (w_rx_done),
        .rd   (rx_rd), // (~tx_full),
        .wdata(w_rx_data),
        .rdata(rx_data),
        .full (rx_full),
        .empty(rx_empty)
    );

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SIZE  (MEM_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) FIFO_TX (
        .clk  (clk),
        .reset(reset),
        .wr   (tx_wr),
        .rd   (~w_tx_busy),   // 
        .wdata(tx_data),
        .rdata(w_rdata_tx),
        .full (tx_full),
        .empty(tx_empty)
    );

endmodule
