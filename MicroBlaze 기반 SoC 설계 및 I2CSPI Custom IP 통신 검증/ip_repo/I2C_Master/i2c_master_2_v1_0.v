`timescale 1 ns / 1 ps

module i2c_master_2_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire scl,
    inout  wire sda,
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

    wire       i2c_en;
    wire       i2c_start;
    wire       i2c_stop;
    wire [7:0] tx_data;
    wire       tx_done;
    wire       tx_ready;
    wire [7:0] rx_data;
    wire       rx_done;

    // Instantiation of Axi Bus Interface S00_AXI
    i2c_master_2_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) i2c_master_2_v1_0_S00_AXI_inst (
        .i2c_en    (i2c_en),
        .i2c_start (i2c_start),
        .i2c_stop  (i2c_stop),
        .tx_data   (tx_data),
        .tx_done   (tx_done),
        .tx_ready  (tx_ready),
        .rx_data   (rx_data),
        .rx_done   (rx_done),
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    // Add user logic here
    I2C_MASTER u_i2c_master (
        .clk      (s00_axi_aclk),
        .reset    (~s00_axi_aresetn),
        .i2c_en   (i2c_en),
        .i2c_start(i2c_start),
        .i2c_stop (i2c_stop),
        .tx_data  (tx_data),
        .tx_done  (tx_done),
        .tx_ready (tx_ready),
        .rx_data  (rx_data),
        .rx_done  (rx_done),
        .scl      (scl),
        .sda      (sda)
    );
    // User logic ends

endmodule

// ============================================================================
// I2C Master Module (Verilog version)
// ============================================================================
module I2C_MASTER (
    input  wire       clk,
    input  wire       reset,
    input  wire       i2c_en,
    input  wire       i2c_start,
    input  wire       i2c_stop,
    input  wire [7:0] tx_data,
    output wire       tx_done,
    output wire       tx_ready,
    output wire [7:0] rx_data,
    output wire       rx_done,
    output wire       scl,
    inout  wire       sda
);

    // State encoding
    localparam [4:0] 
        IDLE       = 5'd0,
        START1     = 5'd1,
        START2     = 5'd2,
        DATA1      = 5'd3,
        DATA2      = 5'd4,
        DATA3      = 5'd5,
        DATA4      = 5'd6,
        READ_DATA1 = 5'd7,
        READ_DATA2 = 5'd8,
        READ_DATA3 = 5'd9,
        READ_DATA4 = 5'd10,
        ACK1       = 5'd11,
        ACK2       = 5'd12,
        ACK3       = 5'd13,
        ACK4       = 5'd14,
        STOP1      = 5'd15,
        STOP2      = 5'd16;

    reg [4:0] state, state_next;
    reg [7:0] r_tx_data, r_tx_data_next;
    reg [7:0] r_rx_data, r_rx_data_next;
    reg [8:0] clk_counter, clk_counter_next;
    reg       r_scl, r_scl_next;
    reg       r_sda_oe, r_sda_oe_next;
    reg       r_tx_ready, r_tx_ready_next;
    reg       r_tx_done, r_tx_done_next;
    reg [2:0] bit_counter, bit_counter_next;
    reg       is_read, is_read_next;
    reg       is_address_phase, is_address_phase_next;
    reg       r_rx_done, r_rx_done_next;

    // Output assignments
    assign sda      = r_sda_oe ? 1'b0 : 1'bz;
    assign scl      = r_scl;
    assign tx_ready = r_tx_ready;
    assign tx_done  = r_tx_done;
    assign rx_done  = r_rx_done;
    assign rx_data  = r_rx_data;

    // State register
    always @(posedge clk) begin
        if (reset) begin
            state            <= IDLE;
            r_scl            <= 1'b1;
            r_tx_data        <= 8'h00;
            clk_counter      <= 9'd0;
            r_sda_oe         <= 1'b0;
            bit_counter      <= 3'b0;
            r_tx_ready       <= 1'b0;
            r_tx_done        <= 1'b0;
            r_rx_data        <= 8'h00;
            is_read          <= 1'b0;
            is_address_phase <= 1'b0;
            r_rx_done        <= 1'b0;
        end else begin
            state            <= state_next;
            r_scl            <= r_scl_next;
            r_tx_data        <= r_tx_data_next;
            clk_counter      <= clk_counter_next;
            r_sda_oe         <= r_sda_oe_next;
            bit_counter      <= bit_counter_next;
            r_tx_ready       <= r_tx_ready_next;
            r_tx_done        <= r_tx_done_next;
            r_rx_data        <= r_rx_data_next;
            is_read          <= is_read_next;
            is_address_phase <= is_address_phase_next;
            r_rx_done        <= r_rx_done_next;
        end
    end

    // Next state logic
    always @(*) begin
        state_next            = state;
        r_scl_next            = r_scl;
        r_tx_data_next        = r_tx_data;
        clk_counter_next      = clk_counter;
        r_sda_oe_next         = r_sda_oe;
        bit_counter_next      = bit_counter;
        r_tx_ready_next       = 1'b0;
        r_tx_done_next        = 1'b0;
        is_read_next          = is_read;
        is_address_phase_next = is_address_phase;
        r_rx_data_next        = r_rx_data;
        r_rx_done_next        = 1'b0;

        case (state)
            IDLE: begin
                r_tx_ready_next = 1'b1;
                r_scl_next      = 1'b1;
                r_sda_oe_next   = 1'b0;
                if (i2c_en) begin
                    state_next            = START1;
                    r_tx_data_next        = tx_data;
                    is_read_next          = 1'b0;
                    is_address_phase_next = 1'b1;
                end else begin
                    is_address_phase_next = 1'b0;
                end
            end

            START1: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = 1'b1;
                if (clk_counter == 9'd499) begin
                    state_next       = START2;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            START2: begin
                r_scl_next    = 1'b0;
                r_sda_oe_next = 1'b1;
                if (clk_counter == 9'd499) begin
                    state_next       = DATA1;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            DATA1: begin
                r_scl_next    = 1'b0;
                r_sda_oe_next = ~r_tx_data[7];
                if (clk_counter == 9'd249) begin
                    state_next       = DATA2;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            DATA2: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = ~r_tx_data[7];
                if (clk_counter == 9'd249) begin
                    state_next       = DATA3;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            DATA3: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = ~r_tx_data[7];
                if (clk_counter == 9'd249) begin
                    state_next       = DATA4;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            DATA4: begin
                r_scl_next    = 1'b0;
                r_sda_oe_next = ~r_tx_data[7];
                if (clk_counter == 9'd249) begin
                    clk_counter_next = 9'd0;
                    if (bit_counter == 3'd7) begin
                        state_next       = ACK1;
                        bit_counter_next = 3'b0;
                        if (is_address_phase) begin
                            is_read_next = r_tx_data[7];
                        end
                    end else begin
                        state_next       = DATA1;
                        bit_counter_next = bit_counter + 1'b1;
                        r_tx_data_next   = {r_tx_data[6:0], 1'b0};
                    end
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            READ_DATA1: begin
                r_scl_next    = 1'b0;
                r_sda_oe_next = 1'b0;
                if (clk_counter == 9'd249) begin
                    state_next       = READ_DATA2;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            READ_DATA2: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = 1'b0;
                if (clk_counter == 9'd249) begin
                    state_next       = READ_DATA3;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            READ_DATA3: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = 1'b0;
                if (clk_counter == 9'd249) begin
                    state_next       = READ_DATA4;
                    r_rx_data_next   = {r_rx_data[6:0], sda};
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            READ_DATA4: begin
                r_scl_next    = 1'b0;
                r_sda_oe_next = 1'b0;
                if (clk_counter == 9'd249) begin
                    clk_counter_next = 9'd0;
                    if (bit_counter == 3'd7) begin
                        state_next       = ACK1;
                        bit_counter_next = 3'b0;
                    end else begin
                        state_next       = READ_DATA1;
                        bit_counter_next = bit_counter + 1'b1;
                    end
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            ACK1: begin
                r_scl_next    = 1'b0;
                r_sda_oe_next = 1'b0;
                if (is_read && !is_address_phase) begin
                    r_sda_oe_next = i2c_stop ? 1'b0 : 1'b1;
                end
                if (clk_counter == 9'd249) begin
                    state_next       = ACK2;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            ACK2: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = 1'b0;
                if (is_read && !is_address_phase) begin
                    r_sda_oe_next = i2c_stop ? 1'b0 : 1'b1;
                end
                if (clk_counter == 9'd249) begin
                    state_next       = ACK3;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            ACK3: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = 1'b0;
                if (is_read && !is_address_phase) begin
                    r_sda_oe_next = i2c_stop ? 1'b0 : 1'b1;
                end
                if (clk_counter == 9'd249) begin
                    state_next       = ACK4;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            ACK4: begin
                r_scl_next    = 1'b0;
                r_sda_oe_next = 1'b0;
                if (is_read && !is_address_phase) begin
                    r_sda_oe_next = i2c_stop ? 1'b0 : 1'b1;
                end
                if (clk_counter == 9'd249) begin
                    clk_counter_next = 9'd0;
                    if (is_read && !is_address_phase) begin
                        r_rx_done_next = 1'b1;
                    end
                    if (!is_read && !is_address_phase) begin
                        r_tx_done_next = 1'b1;
                    end
                    if (i2c_start && !i2c_stop) begin
                        state_next            = START1;
                        is_address_phase_next = 1'b1;
                        r_tx_ready_next       = 1'b1;
                    end else if (!i2c_start && i2c_stop) begin
                        state_next            = STOP1;
                        is_address_phase_next = 1'b0;
                    end else begin
                        state_next            = is_read ? READ_DATA1 : DATA1;
                        is_address_phase_next = 1'b0;
                        if (!is_read) begin
                            r_tx_data_next  = tx_data;
                            r_tx_ready_next = 1'b1;
                        end
                    end
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            STOP1: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = 1'b1;
                if (clk_counter == 9'd499) begin
                    state_next       = STOP2;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            STOP2: begin
                r_scl_next    = 1'b1;
                r_sda_oe_next = 1'b0;
                if (clk_counter == 9'd499) begin
                    state_next       = IDLE;
                    clk_counter_next = 9'd0;
                end else begin
                    clk_counter_next = clk_counter + 1'b1;
                end
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule