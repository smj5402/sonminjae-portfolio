`timescale 1ns / 1ps
module spi_slave (
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       cs,       // active low
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done
);

    typedef enum logic [2:0] {
        IDLE,
        WAIT_RISE,
        CP0,
        WAIT_FALL,
        CP1
    } state_t;

    state_t state, state_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [2:0] bit_counter_reg, bit_counter_next;


    assign miso    = cs ? 1'bz : tx_data_reg[7];
    assign rx_data = rx_data_reg;

    /////////negedge detector///////////////////////////////////// 
    logic sclk_1d, sclk_neg, sclk_pos;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_1d <= 1'b0;
        end else begin
            sclk_1d <= sclk;
        end
    end
    assign sclk_neg = sclk_1d & !sclk;
    assign sclk_pos = !sclk_1d & sclk;

    //////////////////////////////////////////////// state update
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            tx_data_reg     <= 0;
            rx_data_reg     <= 0;
            bit_counter_reg <= 0;
        end else begin
            state           <= state_next;
            tx_data_reg     <= tx_data_next;
            rx_data_reg     <= rx_data_next;
            bit_counter_reg <= bit_counter_next;
        end
    end

    //////////////////////////////////////////////// state transition and output logic
    always_comb begin
        done             = 1'b0;
        state_next       = state;
        tx_data_next     = tx_data_reg;
        rx_data_next     = rx_data_reg;
        bit_counter_next = bit_counter_reg;
        case (state)
            IDLE: begin
                tx_data_next = tx_data;
                state_next   = !cs ? WAIT_RISE : IDLE;
            end
            WAIT_RISE: begin
                state_next = sclk_pos ? CP0 : WAIT_RISE;
            end
            CP0: begin
                state_next   = WAIT_FALL;
                rx_data_next = {rx_data_reg[6:0], mosi};
            end
            WAIT_FALL: begin
                state_next = sclk_neg ? CP1 : WAIT_FALL;
            end
            CP1: begin
                if (bit_counter_reg == 7) begin
                    done             = 1'b1;
                    state_next       = IDLE;
                    bit_counter_next = 3'b0;
                end else begin
                    bit_counter_next = bit_counter_reg + 1;
                    tx_data_next     = {tx_data_reg[6:0], 1'b0};
                    state_next       = WAIT_RISE;
                end
            end
        endcase
    end


endmodule

