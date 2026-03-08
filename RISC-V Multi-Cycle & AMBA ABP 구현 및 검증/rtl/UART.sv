`timescale 1ns / 1ps
module UART_Periph (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // External Signals
    output logic        tx,
    input  logic        rx
);

    logic [7:0] idr;
    logic [7:0] odr;
    logic       tx_full;
    logic       tx_empty;
    logic       rx_full;
    logic       rx_empty;
    logic       rx_rd;
    logic       tx_wr;

    uart_fifo #(
        .DATA_WIDTH(8),
        .MEM_SIZE  (8),
        .ADDR_WIDTH(3)
    ) U_UART_FIFO (
        .clk     (PCLK),
        .reset   (PRESET),
        .rx      (rx),
        .tx      (tx),
        // from APB
        .rx_rd   (rx_rd),
        .rx_data (idr),
        .tx_wr   (tx_wr),
        .tx_data (odr),
        // for control reg
        .tx_full (tx_full),
        .tx_empty(tx_empty),
        .rx_full (rx_full),
        .rx_empty(rx_empty)
    );


    APB_SlaveIntf_UART U_APB_INTF_UART (.*);

endmodule

module uart_fifo #(
    parameter DATA_WIDTH = 8,
    MEM_SIZE = 8,
    ADDR_WIDTH = 3
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    output logic       tx,
    // from APB
    input  logic       rx_rd,
    output logic [7:0] rx_data,
    input  logic       tx_wr,
    input  logic [7:0] tx_data,
    // for control reg
    output logic       tx_full,
    output logic       tx_empty,
    output logic       rx_full,
    output logic       rx_empty
);
    // from uart_top
    wire [DATA_WIDTH-1:0] w_rx_data;
    wire                  w_rx_done;
    wire                  w_tx_busy;

    // from FIFO rx
    // wire                  w_empty_rx;
    wire [DATA_WIDTH-1:0] w_rdata_rx;


    // from FIFO tx
    // wire                  w_empty_tx;
    wire [DATA_WIDTH-1:0] w_rdata_tx;
    // wire                  w_full_tx;

    uart_top U_UART_TOP (
        .clk     (clk),
        .rst     (reset),
        .tx_start(~tx_empty),   // from FIFO_tx
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
        .rd   (rx_rd),
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
        .rd   (~w_tx_busy & ~tx_empty),   // 
        .wdata(tx_data),
        .rdata(w_rdata_tx),
        .full (tx_full),
        .empty(tx_empty)
    );

endmodule


module APB_SlaveIntf_UART (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Internal Signals
    input  logic [ 7:0] idr,
    output logic [ 7:0] odr,
    output logic        tx_wr,
    output logic        rx_rd,
    input  logic        tx_full,
    input  logic        tx_empty,
    input  logic        rx_full,
    input  logic        rx_empty
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    assign odr = slv_reg2[7:0];
    assign tx_wr = (PSEL & PENABLE & PWRITE & (PADDR[3:2] == 2'd2) & ~tx_full);
    assign rx_rd = (PSEL & PENABLE & ~PWRITE & (PADDR[3:2] == 2'd1) & ~rx_empty );

    always_comb begin
        slv_reg3 = 0;
        slv_reg3[0] = tx_full;
        slv_reg3[1] = tx_empty;
        slv_reg3[2] = rx_full;
        slv_reg3[3] = rx_empty;
    end

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            PREADY <= 1'b0;
            if (PSEL & PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        // 2'd1: slv_reg1 <= PWDATA;  // idr  read only (No write)
                        2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    // read
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= {24'b0, idr};  ////////////////////
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end
        end
    end
endmodule
