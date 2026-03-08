`timescale 1 ns / 1 ps

module spi_master_v1_0_S00_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire       start,
    output wire [7:0] tx_data,
    input  wire       tx_ready,
    input  wire [7:0] rx_data,
    input  wire       done,
    output wire       cpol,
    output wire       cpha,
    output wire       cs,
    // User ports ends

    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1 : 0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0] axi_rresp;
    reg axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    //----------------------------------------------
    // Register Map (matches spi_hal.h):
    // 0x00: CR  - Control Register
    //       [0]: start (edge-triggered, auto-clear)
    //       [1]: cpol
    //       [2]: cpha
    //       [3]: cs (directly to output, active low)
    // 0x04: SR  - Status Register (Read Only)
    //       [0]: tx_ready
    //       [1]: done
    // 0x08: RXD - RX Data Register (Read Only)
    //       [7:0]: rx_data
    // 0x0C: TXD - TX Data Register
    //       [7:0]: tx_data
    //----------------------------------------------

    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  // CR
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;  // TXD
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    reg aw_en;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // axi_awready
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // axi_awaddr
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    // axi_wready
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // Register write logic
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 32'h00000008;  // CS = 1 (inactive) by default
            slv_reg3 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    2'h0: // CR
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1; byte_index = byte_index + 1)
                            if (S_AXI_WSTRB[byte_index] == 1) begin
                                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            end
                    2'h1: begin // SR - Read Only
                    end
                    2'h2: begin // RXD - Read Only
                    end
                    2'h3: // TXD
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1; byte_index = byte_index + 1)
                            if (S_AXI_WSTRB[byte_index] == 1) begin
                                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            end
                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end

    // Write response
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // axi_arready
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // axi_rvalid
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    // Read data mux
    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0:    reg_data_out = slv_reg0;                    // CR
            2'h1:    reg_data_out = {30'b0, done, tx_ready};     // SR
            2'h2:    reg_data_out = {24'b0, rx_data};            // RXD
            2'h3:    reg_data_out = slv_reg3;                    // TXD
            default: reg_data_out = 0;
        endcase
    end

    // axi_rdata
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;
            end
        end
    end

    // Add user logic here
    
    // Edge detection for start signal
    reg start_delay;
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            start_delay <= 1'b0;
        end else begin
            start_delay <= slv_reg0[0];
        end
    end

    assign start   = slv_reg0[0] & ~start_delay;  // Rising edge only
    assign cpol    = slv_reg0[1];
    assign cpha    = slv_reg0[2];
    assign cs      = slv_reg0[3];                 // Direct output
    assign tx_data = slv_reg3[7:0];
    
    // User logic ends

endmodule