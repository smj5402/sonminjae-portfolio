`timescale 1 ns / 1 ps

module spi_slave_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    input  wire SCLK,
    input  wire MOSI,
    output wire MISO,
    input  wire SS,      // Slave Select (active low)
    // User ports ends
    // Do not modify the ports beyond this line


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

    wire [7:0] tx_data;
    wire [7:0] rx_data;
    wire       done;

    // Instantiation of Axi Bus Interface S00_AXI
    spi_slave_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) spi_slave_v1_0_S00_AXI_inst (
        .tx_data      (tx_data),
        .rx_data      (rx_data),
        .done         (done),
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

    // Add user logic here
    SPI_SLAVE u_spi_slave (
        .clk    (s00_axi_aclk),
        .reset  (~s00_axi_aresetn),
        .sclk   (SCLK),
        .mosi   (MOSI),
        .miso   (MISO),
        .cs     (SS),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .done   (done)
    );
    // User logic ends

endmodule

// ============================================================================
// SPI Slave Module (Verilog version)
// ============================================================================
module SPI_SLAVE (
    input  wire       clk,
    input  wire       reset,
    input  wire       sclk,
    input  wire       mosi,
    output wire       miso,
    input  wire       cs,       // active low
    input  wire [7:0] tx_data,
    output wire [7:0] rx_data,
    output wire       done
);

    // State encoding
    localparam [2:0]
        IDLE      = 3'd0,
        WAIT_RISE = 3'd1,
        CP0       = 3'd2,
        WAIT_FALL = 3'd3,
        CP1       = 3'd4;

    reg [2:0] state, state_next;
    reg [7:0] tx_data_reg, tx_data_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg       done_reg;

    // Output assignments
    assign miso    = cs ? 1'bz : tx_data_reg[7];
    assign rx_data = rx_data_reg;
    assign done    = done_reg;

    // SCLK edge detection
    reg sclk_1d;
    wire sclk_neg, sclk_pos;

    always @(posedge clk) begin
        if (reset) begin
            sclk_1d <= 1'b0;
        end else begin
            sclk_1d <= sclk;
        end
    end

    assign sclk_neg = sclk_1d & !sclk;
    assign sclk_pos = !sclk_1d & sclk;

    // State register
    always @(posedge clk) begin
        if (reset) begin
            state           <= IDLE;
            tx_data_reg     <= 8'd0;
            rx_data_reg     <= 8'd0;
            bit_counter_reg <= 3'd0;
            done_reg        <= 1'b0;
        end else begin
            state           <= state_next;
            tx_data_reg     <= tx_data_next;
            rx_data_reg     <= rx_data_next;
            bit_counter_reg <= bit_counter_next;
            
            // done pulse generation
            if (state == CP1 && bit_counter_reg == 3'd7) begin
                done_reg <= 1'b1;
            end else begin
                done_reg <= 1'b0;
            end
        end
    end

    // Next state logic
    always @(*) begin
        state_next       = state;
        tx_data_next     = tx_data_reg;
        rx_data_next     = rx_data_reg;
        bit_counter_next = bit_counter_reg;

        case (state)
            IDLE: begin
                tx_data_next = tx_data;
                if (!cs) begin
                    state_next = WAIT_RISE;
                end
            end

            WAIT_RISE: begin
                if (cs) begin
                    state_next = IDLE;
                end else if (sclk_pos) begin
                    state_next = CP0;
                end
            end

            CP0: begin
                if (cs) begin
                    state_next = IDLE;
                end else begin
                    state_next   = WAIT_FALL;
                    rx_data_next = {rx_data_reg[6:0], mosi};
                end
            end

            WAIT_FALL: begin
                if (cs) begin
                    state_next = IDLE;
                end else if (sclk_neg) begin
                    state_next = CP1;
                end
            end

            CP1: begin
                if (cs) begin
                    state_next       = IDLE;
                    bit_counter_next = 3'd0;
                end else if (bit_counter_reg == 3'd7) begin
                    state_next       = IDLE;
                    bit_counter_next = 3'd0;
                end else begin
                    bit_counter_next = bit_counter_reg + 1'b1;
                    tx_data_next     = {tx_data_reg[6:0], 1'b0};
                    state_next       = WAIT_RISE;
                end
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule