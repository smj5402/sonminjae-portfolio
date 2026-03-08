`timescale 1ns / 1ps
module uart_top (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,
    input        rx,
    output       rx_done,
    output [7:0] rx_data,
    output       tx,
    output       tx_busy
);
    wire w_b_tick;

    uart_tx U_UART_TX (
        .clk          (clk),
        .rst          (rst),
        .start_trigger(tx_start),
        .tx_data      (tx_data),
        .b_tick       (w_b_tick),
        .tx           (tx),
        .tx_busy      (tx_busy)
    );

    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rst),
        .rx     (rx),
        .b_tick (w_b_tick),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );


    baud_tick_gen U_BAUD_TICK_GEN (
        .clk   (clk),
        .rst   (rst),
        .b_tick(w_b_tick)
    );
endmodule

module baud_tick_gen (
    input  clk,
    input  rst,
    output b_tick
);
    // baudrate
    parameter BAUDRATE = 9600 * 16;
    localparam BAUD_COUNT = 100_000_000 / BAUDRATE;
    reg [$clog2(BAUD_COUNT)-1 : 0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    // output
    assign b_tick = tick_reg;

    // SL 
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_reg    <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg    <= tick_next;
        end
    end
    // next CL
    always @(*) begin
        counter_next = counter_reg;
        tick_next    = tick_reg;
        if (counter_reg == BAUD_COUNT - 1) begin
            counter_next = 0;
            tick_next    = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next    = 1'b0;
        end
    end

endmodule
