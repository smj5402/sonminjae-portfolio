`timescale 1 ns / 1 ps

module i2c_slave_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    input  wire SCL,
    inout  wire SDA,
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

    wire [6:0] device_addr;
    wire [7:0] tx_data;
    wire       tx_done;
    wire       tx_ready;
    wire [7:0] rx_data;
    wire       rx_done;

    // Instantiation of Axi Bus Interface S00_AXI
    i2c_slave_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) i2c_slave_v1_0_S00_AXI_inst (
        .device_addr  (device_addr),
        .tx_data      (tx_data),
        .tx_done      (tx_done),
        .tx_ready     (tx_ready),
        .rx_data      (rx_data),
        .rx_done      (rx_done),
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
    I2C_SLAVE u_i2c_slave (
        .clk        (s00_axi_aclk),
        .reset      (~s00_axi_aresetn),
        .device_addr(device_addr),
        .SCL        (SCL),
        .SDA        (SDA),
        .tx_data    (tx_data),
        .rx_data    (rx_data),
        .tx_done    (tx_done),
        .tx_ready   (tx_ready),
        .rx_done    (rx_done)
    );
    // User logic ends

endmodule

// ============================================================================
// I2C Slave Module (Verilog version)
// ============================================================================
module I2C_SLAVE (
    input  wire       clk,
    input  wire       reset,
    input  wire [6:0] device_addr,
    input  wire       SCL,
    inout  wire       SDA,
    input  wire [7:0] tx_data,
    output wire [7:0] rx_data,
    output wire       tx_done,
    output wire       tx_ready,
    output wire       rx_done
);

    // State encoding
    localparam [2:0]
        IDLE       = 3'd0,
        ADDR_PHASE = 3'd1,
        ADDR_ACK   = 3'd2,
        WRITE_DATA = 3'd3,
        READ_DATA  = 3'd4,
        WRITE_ACK  = 3'd5,
        READ_ACK   = 3'd6;

    reg [2:0] state, state_next;

    // Synchronization registers
    reg scl_1d, scl_2d, scl_3d;
    reg sda_1d, sda_2d, sda_3d;

    wire scl_sync, sda_sync;
    wire scl_rising, scl_falling;
    wire sda_rising, sda_falling;
    wire start_signal, stop_signal;

    // Internal registers
    reg       sda_oe_reg, sda_oe_next;
    reg [7:0] shift_reg, shift_reg_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg       tx_done_reg, tx_done_next;
    reg       tx_ready_reg, tx_ready_next;
    reg       rx_done_reg, rx_done_next;
    reg [2:0] bit_counter_reg, bit_counter_next;

    // Output assignments
    assign SDA      = sda_oe_reg ? 1'b0 : 1'bz;
    assign scl_sync = scl_2d;
    assign sda_sync = sda_2d;
    assign tx_ready = tx_ready_reg;
    assign tx_done  = tx_done_reg;
    assign rx_done  = rx_done_reg;
    assign rx_data  = rx_data_reg;

    // Edge detection
    assign scl_rising  = !scl_3d && scl_2d;
    assign scl_falling = scl_3d && !scl_2d;
    assign sda_rising  = !sda_3d && sda_2d;
    assign sda_falling = sda_3d && !sda_2d;

    // Start/Stop detection
    assign start_signal = scl_sync && sda_falling;
    assign stop_signal  = scl_sync && sda_rising;

    // Synchronization flip-flops
    always @(posedge clk) begin
        if (reset) begin
            {scl_1d, scl_2d, scl_3d} <= 3'b111;
            {sda_1d, sda_2d, sda_3d} <= 3'b111;
        end else begin
            scl_1d <= SCL;
            scl_2d <= scl_1d;
            scl_3d <= scl_2d;
            sda_1d <= SDA;
            sda_2d <= sda_1d;
            sda_3d <= sda_2d;
        end
    end

    // State register
    always @(posedge clk) begin
        if (reset) begin
            state           <= IDLE;
            sda_oe_reg      <= 1'b0;
            shift_reg       <= 8'h00;
            tx_done_reg     <= 1'b0;
            tx_ready_reg    <= 1'b0;
            rx_done_reg     <= 1'b0;
            bit_counter_reg <= 3'd0;
            rx_data_reg     <= 8'h00;
        end else begin
            state           <= state_next;
            sda_oe_reg      <= sda_oe_next;
            shift_reg       <= shift_reg_next;
            tx_done_reg     <= tx_done_next;
            tx_ready_reg    <= tx_ready_next;
            rx_done_reg     <= rx_done_next;
            bit_counter_reg <= bit_counter_next;
            rx_data_reg     <= rx_data_next;
        end
    end

    // Next state logic
    always @(*) begin
        state_next       = state;
        sda_oe_next      = sda_oe_reg;
        shift_reg_next   = shift_reg;
        tx_done_next     = 1'b0;
        tx_ready_next    = 1'b0;
        rx_done_next     = 1'b0;
        bit_counter_next = bit_counter_reg;
        rx_data_next     = rx_data_reg;

        case (state)
            IDLE: begin
                sda_oe_next = 1'b0;
                if (start_signal) begin
                    state_next       = ADDR_PHASE;
                    bit_counter_next = 3'd0;
                end
            end

            ADDR_PHASE: begin
                sda_oe_next = 1'b0;
                if (stop_signal) begin
                    state_next = IDLE;
                end else if (start_signal) begin
                    state_next       = ADDR_PHASE;
                    bit_counter_next = 3'd0;
                end else if (scl_rising) begin
                    shift_reg_next = {shift_reg[6:0], sda_sync};
                    if (bit_counter_reg == 3'd7) begin
                        bit_counter_next = 3'd0;
                        state_next       = ADDR_ACK;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1'b1;
                    end
                end
            end

            ADDR_ACK: begin
                if (stop_signal) begin
                    state_next  = IDLE;
                    sda_oe_next = 1'b0;
                end else if (start_signal) begin
                    state_next       = ADDR_PHASE;
                    bit_counter_next = 3'd0;
                    sda_oe_next      = 1'b0;
                end else if (shift_reg[7:1] == device_addr) begin
                    if (scl_falling && !sda_oe_reg) begin
                        sda_oe_next = 1'b1;  // ACK
                    end else if (scl_falling && sda_oe_reg) begin
                        sda_oe_next = 1'b0;  // Release
                        if (shift_reg[0]) begin
                            // Read mode
                            state_next     = READ_DATA;
                            shift_reg_next = tx_data;
                        end else begin
                            // Write mode
                            state_next = WRITE_DATA;
                        end
                    end
                end else begin
                    // Address mismatch - NACK
                    sda_oe_next = 1'b0;
                    if (scl_falling) begin
                        state_next = IDLE;
                    end
                end
            end

            WRITE_DATA: begin
                sda_oe_next = 1'b0;
                if (stop_signal) begin
                    state_next = IDLE;
                end else if (start_signal) begin
                    state_next       = ADDR_PHASE;
                    bit_counter_next = 3'd0;
                end else if (scl_rising) begin
                    shift_reg_next = {shift_reg[6:0], sda_sync};
                    if (bit_counter_reg == 3'd7) begin
                        bit_counter_next = 3'd0;
                        rx_data_next     = {shift_reg[6:0], sda_sync};
                        rx_done_next     = 1'b1;
                        state_next       = WRITE_ACK;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1'b1;
                    end
                end
            end

            WRITE_ACK: begin
                if (stop_signal) begin
                    state_next  = IDLE;
                    sda_oe_next = 1'b0;
                end else if (start_signal) begin
                    state_next       = ADDR_PHASE;
                    bit_counter_next = 3'd0;
                    sda_oe_next      = 1'b0;
                end else if (scl_falling && !sda_oe_reg) begin
                    sda_oe_next = 1'b1;  // ACK
                end else if (scl_falling && sda_oe_reg) begin
                    sda_oe_next = 1'b0;
                    state_next  = WRITE_DATA;
                end
            end

            READ_DATA: begin
                if (stop_signal) begin
                    state_next  = IDLE;
                    sda_oe_next = 1'b0;
                end else if (start_signal) begin
                    state_next       = ADDR_PHASE;
                    bit_counter_next = 3'd0;
                    sda_oe_next      = 1'b0;
                end else if (scl_falling) begin
                    // Drive SDA based on MSB
                    if (shift_reg[7] == 1'b0) begin
                        sda_oe_next = 1'b1;  // Drive 0
                    end else begin
                        sda_oe_next = 1'b0;  // Release -> 1
                    end
                    shift_reg_next = {shift_reg[6:0], 1'b0};
                    if (bit_counter_reg == 3'd7) begin
                        bit_counter_next = 3'd0;
                        state_next       = READ_ACK;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1'b1;
                    end
                end
            end

            READ_ACK: begin
                if (stop_signal) begin
                    state_next  = IDLE;
                    sda_oe_next = 1'b0;
                end else if (start_signal) begin
                    state_next       = ADDR_PHASE;
                    bit_counter_next = 3'd0;
                    sda_oe_next      = 1'b0;
                end else begin
                    sda_oe_next = 1'b0;  // Release for master ACK/NACK
                    if (scl_rising) begin
                        if (sda_sync == 1'b0) begin
                            // Master ACK - continue reading
                            state_next     = READ_DATA;
                            shift_reg_next = tx_data;
                            tx_ready_next  = 1'b1;
                        end else begin
                            // Master NACK - end transfer
                            state_next   = IDLE;
                            tx_done_next = 1'b1;
                        end
                    end
                end
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule