`timescale 1 ns / 1 ps

module spi_master_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire sclk,
    output wire mosi,
    input  wire miso,
    output wire cs,
    // User ports ends

    // Ports of Axi Slave Bus Interface S00_AXI
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);

    wire       start;
    wire [7:0] tx_data;
    wire       tx_ready;
    wire [7:0] rx_data;
    wire       done;
    wire       cpol;
    wire       cpha;

    // Instantiation of Axi Bus Interface S00_AXI
    // NOTE: cs port removed from AXI slave — now driven by SPI_MASTER FSM
    spi_master_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) spi_master_v1_0_S00_AXI_inst (
        .start     (start),
        .tx_data   (tx_data),
        .tx_ready  (tx_ready),
        .rx_data   (rx_data),
        .done      (done),
        .cpol      (cpol),
        .cpha      (cpha),
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // SPI_MASTER now owns cs output
    SPI_MASTER u_spi_master (
        .clk     (s00_axi_aclk),
        .reset   (~s00_axi_aresetn),
        .start   (start),
        .tx_data (tx_data),
        .tx_ready(tx_ready),
        .rx_data (rx_data),
        .done    (done),
        .cpol    (cpol),
        .cpha    (cpha),
        .cs      (cs),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso)
    );

endmodule


// ============================================================================
// SPI Master Module — cs FSM-controlled (active-low)
// ============================================================================
module SPI_MASTER (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [7:0] tx_data,
    output wire       tx_ready,
    output wire [7:0] rx_data,
    output wire       done,
    input  wire       cpol,
    input  wire       cpha,
    output wire       cs,       // active-low chip select
    output wire       sclk,
    output wire       mosi,
    input  wire       miso
);

    localparam [1:0]
        IDLE     = 2'd0,
        CP0      = 2'd1,
        CP1      = 2'd2,
        CP_DELAY = 2'd3;

    reg [1:0] state, state_next;
    reg [7:0] tx_data_reg, tx_data_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg [5:0] clk_counter_reg, clk_counter_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg       sclk_reg;
    reg       done_reg;
    reg       tx_ready_reg;
    reg       cs_reg;           // registered active-low CS

    wire pclk;
    wire sclk_next;

    assign mosi     = tx_data_reg[7];
    assign rx_data  = rx_data_reg;
    assign sclk     = sclk_reg;
    assign done     = done_reg;
    assign tx_ready = tx_ready_reg;
    assign cs       = cs_reg;

    assign pclk      = ((state_next == CP0) && (cpha == 1'b1)) ||
                       ((state_next == CP1) && (cpha == 1'b0));
    assign sclk_next = cpol ? ~pclk : pclk;

    // -----------------------------------------------------------------------
    // Sequential
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state           <= IDLE;
            tx_data_reg     <= 8'd0;
            rx_data_reg     <= 8'd0;
            clk_counter_reg <= 6'd0;
            bit_counter_reg <= 3'd0;
            sclk_reg        <= 1'b0;
            done_reg        <= 1'b0;
            tx_ready_reg    <= 1'b0;
            cs_reg          <= 1'b1;   // deasserted at reset
        end else begin
            state           <= state_next;
            tx_data_reg     <= tx_data_next;
            rx_data_reg     <= rx_data_next;
            bit_counter_reg <= bit_counter_next;
            clk_counter_reg <= clk_counter_next;
            sclk_reg        <= sclk_next;

            // cs: assert (0) on departure from IDLE, deassert (1) on return to IDLE
            cs_reg <= (state_next == IDLE);

            // done pulse — one cycle wide
            done_reg <= (state == CP1      && clk_counter_reg == 6'd49 &&
                         bit_counter_reg == 3'd7 &&  cpha) ||
                        (state == CP_DELAY && clk_counter_reg == 6'd49 && !cpha);

            // tx_ready mirrors IDLE entry
            tx_ready_reg <= (state_next == IDLE);
        end
    end

    // -----------------------------------------------------------------------
    // Next-state / datapath combinational
    // -----------------------------------------------------------------------
    always @(*) begin
        state_next       = state;
        tx_data_next     = tx_data_reg;
        rx_data_next     = rx_data_reg;
        bit_counter_next = bit_counter_reg;
        clk_counter_next = clk_counter_reg;

        case (state)
            IDLE: begin
                if (start) begin
                    state_next       = cpha ? CP_DELAY : CP0;
                    tx_data_next     = tx_data;
                    clk_counter_next = 6'd0;
                end
            end

            CP0: begin
                if ($stable(clk_counter_reg) && clk_counter_reg == 6'd49) begin
                    rx_data_next     = {rx_data_reg[6:0], miso};
                    clk_counter_next = 6'd0;
                    state_next       = CP1;
                end else begin
                    clk_counter_next = clk_counter_reg + 1'b1;
                end
            end

            CP1: begin
                if ($stable(clk_counter_reg) && clk_counter_reg == 6'd49) begin
                    clk_counter_next = 6'd0;
                    if (bit_counter_reg == 3'd7) begin
                        bit_counter_next = 3'd0;
                        state_next       = cpha ? IDLE : CP_DELAY;
                    end else begin
                        tx_data_next     = {tx_data_reg[6:0], 1'b0};
                        bit_counter_next = bit_counter_reg + 1'b1;
                        state_next       = CP0;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1'b1;
                end
            end

            CP_DELAY: begin
                if ($stable(clk_counter_reg) && clk_counter_reg == 6'd49) begin
                    clk_counter_next = 6'd0;
                    state_next       = cpha ? CP0 : IDLE;
                end else begin
                    clk_counter_next = clk_counter_reg + 1'b1;
                end
            end

            default: state_next = IDLE;
        endcase
    end

endmodule