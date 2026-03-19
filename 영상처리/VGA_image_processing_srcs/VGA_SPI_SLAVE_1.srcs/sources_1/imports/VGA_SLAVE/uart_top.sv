`timescale 1ns / 1ps
module uart_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       Rx,
    output logic [7:0] rx_data
);

    // UART RX
    logic [7:0] w_rx_data;
    logic       w_rx_done;
    logic       fifo_wr_en;
    logic       fifo_rd_en;
    logic       fifo_full;
    logic       fifo_empty;

    // assign fifo_rd_en = ~fifo_empty;
    // assign fifo_wr_en = w_rx_done & ~fifo_full;
    uart_rx #(
        .BPS(9600)
    ) u_uart_rx (
        .clk(clk),
        .reset(reset),
        .rx(Rx),
        .data_out(w_rx_data),
        .rx_done(w_rx_done)
    );


    // fifo #(
    //     .DATA_WIDTH(8),
    //     .MEM_SIZE  (16)
    // ) U_UART_FIFO (
    //     .clk  (clk),
    //     .reset(reset),
    //     .wr   (fifo_wr_en),
    //     .rd   (fifo_rd_en),
    //     .wdata(w_rx_data),
    //     .rdata(rx_data),
    //     .full (fifo_full),
    //     .empty(fifo_empty)
    // );
endmodule
