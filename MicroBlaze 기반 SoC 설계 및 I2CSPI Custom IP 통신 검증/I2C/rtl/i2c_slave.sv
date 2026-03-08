`timescale 1ns / 1ps
module i2c_slave (
    input  logic       clk,
    input  logic       reset,
    input        [6:0] device_addr,
    input  logic       scl,
    inout  wire        sda,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic       rx_done
);

    typedef enum logic [2:0] {
        IDLE,
        ADDR_PHASE,
        ADDR_ACK,
        WRITE_DATA,
        READ_DATA,
        WRITE_ACK,
        READ_ACK
    } state_t;

    state_t state, state_next;
    logic start_signal, stop_signal;
    logic scl_rising, scl_falling;
    logic scl_1d, scl_2d, scl_3d;
    logic sda_1d, sda_2d, sda_3d;
    logic sda_oe_reg, sda_oe_next;
    logic sda_sync, scl_sync;
    logic [7:0] shift_reg, shift_reg_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic tx_done_reg, tx_done_next;
    logic tx_ready_reg, tx_ready_next;
    logic rx_done_reg, rx_done_next;
    logic [2:0] bit_counter_reg, bit_counter_next;


    assign sda = sda_oe_reg ? 1'b0 : 1'bz;
    assign scl_sync = scl_2d;
    assign sda_sync = sda_2d;
    assign tx_ready = tx_ready_reg;
    assign tx_done = tx_done_reg;
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            {scl_1d, scl_2d, scl_3d} <= 3'b000;
            {sda_1d, sda_2d, sda_3d} <= 3'b000;
        end else begin
            scl_1d <= scl;
            scl_2d <= scl_1d;
            scl_3d <= scl_2d;
            sda_1d <= sda;
            sda_2d <= sda_1d;
            sda_3d <= sda_2d;
        end
    end
    assign scl_rising   = !scl_3d && scl_2d;
    assign scl_falling  = scl_3d && !scl_2d;
    assign sda_rising   = !sda_3d && sda_2d;
    assign sda_falling  = sda_3d && !sda_2d;

    assign start_signal = scl_sync && sda_falling;
    assign stop_signal  = scl_sync && sda_rising;

    // state update
    always_ff @(posedge clk or posedge reset) begin
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


    // state transition and output logic
    always_comb begin
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
                    tx_done_next     = 1'b0;
                    tx_ready_next    = 1'b0;
                    rx_done_next     = 1'b0;
                end
            end
            ADDR_PHASE: begin
                sda_oe_next = 1'b0;
                if (scl_rising) begin
                    shift_reg_next = {shift_reg[6:0], sda_sync};
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        state_next    = ADDR_ACK;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end
            ADDR_ACK: begin
                if (stop_signal) begin
                    state_next = IDLE;
                end else if (start_signal) begin
                    state_next = ADDR_PHASE;
                end else if (shift_reg[7:1] == device_addr) begin
                    if (scl_falling && !sda_oe_reg) begin
                        sda_oe_next = 1'b1;  // ACK
                    end else if (scl_falling && sda_oe_reg) begin
                        sda_oe_next = 1'b0;  // release

                        if (shift_reg[0]) begin
                            state_next = READ_DATA;
                            shift_reg_next = tx_data;
                        end else begin
                            state_next = WRITE_DATA;
                        end
                    end
                    // end else begin
                    //     sda_oe_next = 1'b0;

                end else begin
                    sda_oe_next = 1'b0;
                end
            end
            WRITE_DATA: begin
                sda_oe_next = 1'b0;
                if (stop_signal) begin
                    state_next = IDLE;
                end else if (start_signal) begin
                    state_next = ADDR_PHASE;
                end else if (scl_rising) begin
                    shift_reg_next = {shift_reg[6:0], sda_sync};  // sampling
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        rx_data_next = {shift_reg[6:0], sda_sync};
                        rx_done_next = 1'b1;
                        state_next = WRITE_ACK;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end
            WRITE_ACK: begin
                // slave sends ack
                if (stop_signal) begin
                    state_next = IDLE;
                end else if (start_signal) begin
                    state_next = ADDR_PHASE;
                end else if (scl_falling && !sda_oe_reg) begin
                    sda_oe_next = 1'b1;  // ack
                end else if (scl_falling && sda_oe_reg) begin
                    sda_oe_next = 1'b0;
                    state_next  = WRITE_DATA;
                end
            end
            READ_DATA: begin
                // slave driving
                if (stop_signal) begin
                    state_next = IDLE;
                end else if (start_signal) begin
                    state_next = ADDR_PHASE;
                end else if (scl_falling) begin
                    if (shift_reg[7] == 0) begin
                        sda_oe_next = 1'b1;  // drive 0 
                    end else begin
                        sda_oe_next = 1'b0;  // release -> 1
                    end

                    shift_reg_next = {shift_reg[6:0], 1'b0};
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        state_next = READ_ACK;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end
            READ_ACK: begin
                // master sends ack to slave
                // slave sampling
                if (stop_signal) begin
                    state_next = IDLE;
                end else if (start_signal) begin
                    state_next = ADDR_PHASE;
                end else begin
                    sda_oe_next = 1'b0;
                    if (scl_rising) begin
                        if (sda_sync == 1'b0) begin
                            // ack
                            state_next = READ_DATA;
                            shift_reg_next = tx_data;
                            tx_ready_next = 1'b1;
                        end else begin
                            // nack 
                            state_next   = IDLE;
                            tx_done_next = 1'b1;
                        end
                    end
                end
            end
        endcase
    end
endmodule


