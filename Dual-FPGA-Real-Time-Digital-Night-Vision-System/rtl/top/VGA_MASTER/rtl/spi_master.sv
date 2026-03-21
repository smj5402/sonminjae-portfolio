`timescale 1ns / 1ps

module spi_master (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // internal signals
    input  logic       start,
    input  logic [7:0] tx_data,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       done,
    input  logic       cpol,
    input  logic       cpha,
    // external signals
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       cs
);

    typedef enum {
        IDLE,
        CP0,
        CP1,
        CP_DELAY
    } state_t;

    state_t state, state_next;

    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [5:0] clk_counter_reg, clk_counter_next;
    logic [2:0] bit_counter_reg, bit_counter_next;
    logic pclk, sclk_reg, sclk_next;
    logic cs_reg, cs_next;

    assign mosi = tx_data_reg[7];
    assign rx_data = rx_data_reg;

    assign pclk = ((state_next == CP0) && (cpha == 1)) ||
                  ((state_next == CP1) && (cpha == 0));

    assign sclk_next = cpol ? ~pclk : pclk;
    assign sclk = sclk_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            tx_data_reg     <= 0;
            rx_data_reg     <= 0;
            bit_counter_reg <= 0;
            clk_counter_reg <= 0;
            sclk_reg        <= 0;
            cs_reg          <= 1;
        end else begin
            state           <= state_next;
            tx_data_reg     <= tx_data_next;
            rx_data_reg     <= rx_data_next;
            bit_counter_reg <= bit_counter_next;
            clk_counter_reg <= clk_counter_next;
            sclk_reg        <= sclk_next;
            cs_reg          <= cs_next;
        end
    end

    always_comb begin
        state_next       = state;
        done             = 1'b0;
        tx_ready         = 1'b0;
        // sclk             = 1'b0;
        tx_data_next     = tx_data_reg;
        rx_data_next     = rx_data_reg;
        bit_counter_next = bit_counter_reg;
        clk_counter_next = clk_counter_reg;
        cs_next          = cs_reg;
        case (state)
            IDLE: begin
                done     = 1'b0;
                tx_ready = 1'b1;
                cs_next  = 1'b1;
                if (start) begin
                    // state_next       = CP0;
                    state_next       = cpha ? CP_DELAY : CP0;
                    tx_data_next     = tx_data;
                    clk_counter_next = 0;
                    cs_next          = 1'b0;
                end
            end

            CP0: begin
                // sclk = 1'b0;
                if (clk_counter_reg == 2) begin
                    rx_data_next     = {rx_data_reg[6:0], miso};
                    clk_counter_next = 0;
                    state_next       = CP1;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end

            CP1: begin
                // sclk = 1'b1;
                if (clk_counter_reg == 2) begin
                    clk_counter_next = 0;
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        if (cpha) begin
                            done = 1'b1;
                            cs_next = 1'b1;
                            state_next = IDLE;
                        end else begin
                            done = 1'b0;
                            state_next = CP_DELAY;
                        end
                    end else begin
                        tx_data_next     = {tx_data_reg[6:0], 1'b0};
                        bit_counter_next = bit_counter_reg + 1;
                        state_next       = CP0;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end

            CP_DELAY: begin
                if (clk_counter_reg == 2) begin
                    clk_counter_next = 0;
                    if (cpha) begin
                        done = 1'b0;
                        state_next = CP0;
                    end else begin
                        done = 1'b1;
                        cs_next = 1'b1;
                        state_next = IDLE;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
        endcase
    end

    assign cs = cs_reg;
endmodule
