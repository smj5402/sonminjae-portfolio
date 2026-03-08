`timescale 1ns / 1ps
module i2c_master (
    input  logic       clk,
    input  logic       reset,
    input  logic       i2c_en,
    input  logic       i2c_start,
    input  logic       i2c_stop,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       scl,
    inout  wire        sda
);

    typedef enum logic [4:0] {
        IDLE,
        START1,
        START2,
        DATA1,
        DATA2,
        DATA3,
        DATA4,
        READ_DATA1,
        READ_DATA2,
        READ_DATA3,
        READ_DATA4,
        ACK1,
        ACK2,
        ACK3,
        ACK4,
        STOP1,
        STOP2
    } state_t;
    state_t state, state_next;

    logic [7:0] tx_data_next, tx_data_reg;
    logic [7:0] rx_data_next, rx_data_reg;
    logic [8:0] clk_counter_next, clk_counter_reg;
    logic scl_reg, scl_next;
    logic sda_oe_next, sda_oe_reg;
    logic tx_ready_next, tx_ready_reg;
    logic tx_done_next, tx_done_reg;
    // logic sda_out_next, sda_out_reg;
    logic [2:0] bit_counter_next, bit_counter_reg;
    logic is_read_next, is_read_reg;
    logic is_address_phase_next, is_address_phase_reg;
    logic rx_done_next, rx_done_reg;

    assign sda      = sda_oe_reg ? 1'b0 : 1'bz;
    assign scl      = scl_reg;
    assign tx_ready = tx_ready_reg;
    assign tx_done  = tx_done_reg;
    assign rx_done  = rx_done_reg;
    assign rx_data  = rx_data_reg;

    // state update
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state                <= IDLE;
            scl_reg              <= 1'b1;
            tx_data_reg          <= 8'h00;
            clk_counter_reg      <= 0;
            sda_oe_reg           <= 1'b0;
            // sda_out_reg          <= 1'b1;
            bit_counter_reg      <= 3'b0;
            tx_ready_reg         <= 1'b0;
            tx_done_reg          <= 1'b0;
            rx_data_reg          <= 8'h00;
            is_read_reg          <= 1'b0;
            is_address_phase_reg <= 1'b0;
            rx_done_reg          <= 1'b0;
        end else begin
            state                <= state_next;
            scl_reg              <= scl_next;
            tx_data_reg          <= tx_data_next;
            clk_counter_reg      <= clk_counter_next;
            sda_oe_reg           <= sda_oe_next;
            // sda_out_reg          <= sda_out_next;
            bit_counter_reg      <= bit_counter_next;
            tx_ready_reg         <= tx_ready_next;
            tx_done_reg          <= tx_done_next;
            rx_data_reg          <= rx_data_next;
            is_read_reg          <= is_read_next;
            is_address_phase_reg <= is_address_phase_next;
            rx_done_reg          <= rx_done_next;
        end
    end

    // state transition logic
    always_comb begin
        state_next            = state;
        scl_next              = scl_reg;
        tx_data_next          = tx_data_reg;
        clk_counter_next      = clk_counter_reg;
        sda_oe_next           = sda_oe_reg;
        // sda_out_next          = sda_out_reg;
        bit_counter_next      = bit_counter_reg;
        tx_ready_next         = 1'b0;
        tx_done_next          = 1'b0;
        is_read_next          = is_read_reg;
        is_address_phase_next = is_address_phase_reg;
        rx_data_next          = rx_data_reg;
        rx_done_next          = 1'b0;
        case (state)
            IDLE: begin
                tx_ready_next = 1'b1;
                scl_next      = 1'b1;
                sda_oe_next   = 1'b0;
                // sda_out_next  = 1'b1;
                if (i2c_en) begin
                    state_next = START1;
                    tx_data_next = tx_data;
                    is_read_next = 1'b0;
                    is_address_phase_next = 1'b1;
                end else begin
                    is_address_phase_next = 1'b0;
                end
            end
            /////////////////// Start signal
            START1: begin
                scl_next     = 1'b1;
                sda_oe_next  = 1'b1;
                // sda_out_next = 1'b0;
                if (clk_counter_reg == 499) begin
                    state_next = START2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            START2: begin
                scl_next     = 1'b0;
                sda_oe_next  = 1'b1;
                // sda_out_next = 1'b0;
                if (clk_counter_reg == 499) begin
                    state_next = DATA1;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            /////////////////// Data write
            DATA1: begin
                scl_next = 1'b0;
                sda_oe_next = ~tx_data_reg[7];
                // sda_out_next = tx_data_reg[7];
                if (clk_counter_reg == 249) begin
                    state_next = DATA2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA2: begin
                scl_next     = 1'b1;
                sda_oe_next  = ~tx_data_reg[7];
                // sda_out_next = tx_data_reg[7];
                if (clk_counter_reg == 249) begin
                    state_next = DATA3;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA3: begin
                scl_next     = 1'b1;
                sda_oe_next  = ~tx_data_reg[7];
                // sda_out_next = tx_data_reg[7];
                if (clk_counter_reg == 249) begin
                    state_next = DATA4;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA4: begin
                scl_next     = 1'b0;
                sda_oe_next  = ~tx_data_reg[7];
                // sda_out_next = tx_data_reg[7];
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    if (bit_counter_reg == 7) begin
                        state_next = ACK1;
                        bit_counter_next = 3'b0;
                        if (is_address_phase_reg) begin
                            is_read_next = tx_data_reg[7];
                        end
                    end else begin
                        state_next = DATA1;
                        bit_counter_next = bit_counter_reg + 1;
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            /////////////////// Data Read
            READ_DATA1: begin
                scl_next    = 1'b0;
                sda_oe_next = 1'b0;
                if (clk_counter_reg == 249) begin
                    state_next       = READ_DATA2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            READ_DATA2: begin
                scl_next    = 1'b1;
                sda_oe_next = 1'b0;
                if (clk_counter_reg == 249) begin
                    state_next       = READ_DATA3;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            READ_DATA3: begin
                scl_next    = 1'b1;
                sda_oe_next = 1'b0;
                if (clk_counter_reg == 249) begin
                    state_next       = READ_DATA4;
                    rx_data_next     = {rx_data_reg[6:0], sda};  // sampling
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            READ_DATA4: begin
                scl_next    = 1'b0;
                sda_oe_next = 1'b0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    if (bit_counter_reg == 7) begin
                        state_next       = ACK1;
                        bit_counter_next = 3'b0;
                    end else begin
                        state_next = READ_DATA1;
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            /////////////////// ACK
            ACK1: begin
                scl_next     = 1'b0;
                sda_oe_next  = 1'b0;
                // sda_out_next = 1'b0;
                if (is_read_reg && !is_address_phase_reg) begin
                    sda_oe_next  = i2c_stop ? 1'b0 : 1'b1;
                    // sda_out_next = i2c_stop ? 1'b1 : 1'b0;
                end else begin
                    sda_oe_next = 1'b0;
                end
                if (clk_counter_reg == 249) begin
                    state_next = ACK2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK2: begin
                scl_next     = 1'b1;
                sda_oe_next  = 1'b0;
                // sda_out_next = 1'b0;
                if (is_read_reg && !is_address_phase_reg) begin
                    sda_oe_next  = i2c_stop ? 1'b0 : 1'b1;
                    // sda_out_next = i2c_stop ? 1'b1 : 1'b0;
                end else begin
                    sda_oe_next = 1'b0;
                end
                if (clk_counter_reg == 249) begin
                    state_next = ACK3;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK3: begin
                scl_next     = 1'b1;
                sda_oe_next  = 1'b0;
                // sda_out_next = 1'b0;
                if (is_read_reg && !is_address_phase_reg) begin
                    sda_oe_next  = i2c_stop ? 1'b0 : 1'b1;
                    // sda_out_next = i2c_stop ? 1'b1 : 1'b0;
                end else begin
                    sda_oe_next = 1'b0;
                end
                if (clk_counter_reg == 249) begin
                    state_next = ACK4;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK4: begin
                scl_next     = 1'b0;
                sda_oe_next  = 1'b0;
                // sda_out_next = 1'b0;
                if (is_read_reg && !is_address_phase_reg) begin
                    sda_oe_next  = i2c_stop ? 1'b0 : 1'b1;
                    // sda_out_next = i2c_stop ? 1'b1 : 1'b0;
                end else begin
                    sda_oe_next = 1'b0;
                end
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    if (is_read_reg && !is_address_phase_reg) begin
                        rx_done_next = 1'b1;
                    end
                    if(!is_read_reg && !is_address_phase_reg) begin
                        tx_done_next = 1'b1;
                    end
                    if (i2c_start & !i2c_stop) begin
                        state_next = START1;
                        is_address_phase_next = 1'b1;
                        tx_ready_next  = 1'b1;
                    end else if (!i2c_start & i2c_stop) begin
                        state_next = STOP1;
                        is_address_phase_next = 1'b0;
                    end else begin
                        state_next = is_read_reg ? READ_DATA1 : DATA1;
                        is_address_phase_next = 1'b0;
                        if (!is_read_reg) begin
                            tx_data_next = tx_data;
                            tx_ready_next = 1'b1;
                        end
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            /////////////////// stop signal
            STOP1: begin
                scl_next     = 1'b1;
                sda_oe_next  = 1'b1;
                // sda_out_next = 1'b0;
                if (clk_counter_reg == 499) begin
                    state_next = STOP2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            STOP2: begin
                scl_next     = 1'b1;
                sda_oe_next  = 1'b0;
                // sda_out_next = 1'b1;
                if (clk_counter_reg == 499) begin
                    state_next       = IDLE;
                    clk_counter_next = 0;
                    // if (!is_read_reg) begin
                    //     tx_done_next = 1'b1;
                    // end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule
