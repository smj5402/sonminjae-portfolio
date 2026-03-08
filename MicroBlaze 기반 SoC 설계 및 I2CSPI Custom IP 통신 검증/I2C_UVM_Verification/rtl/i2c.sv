`timescale 1ns / 1ps

module I2C_MASTER (
    input  logic       clk,
    input  logic       reset,
    input  logic       I2C_En,
    input  logic       I2C_start,
    input  logic       I2C_stop,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       SCL,
    inout  wire       SDA
);

    typedef enum {
        IDLE,
        START1,
        START2,
        DATA1,
        DATA2,
        DATA3,
        DATA4,
        READ1,
        READ2,
        READ3,
        READ4,
        WACK1,
        WACK2,
        WACK3,
        WACK4,
        RACK1,
        RACK2,
        RACK3,
        RACK4,
        HOLD,
        STOP1,
        STOP2
    } state_t;

    state_t state, state_n;

    logic r_sda_out, r_sda_out_n;
    logic r_sda_oe, r_sda_oe_n;
    assign SDA = (r_sda_oe) ? r_sda_out : 1'hz;

    logic r_SCL, r_SCL_n;
    logic [8:0] clk_cnt, clk_cnt_n;
    logic [2:0] bit_cnt, bit_cnt_n;
    logic [7:0] r_tx_data, r_tx_data_n;
    logic [7:0] r_rx_data, r_rx_data_n;
    logic r_tx_done, r_tx_done_n;
    logic r_tx_ready, r_tx_ready_n;
    logic r_rx_done, r_rx_done_n;
    logic r_reading, r_reading_n;

    assign rx_data  = r_rx_data;
    assign tx_done  = r_tx_done;
    assign tx_ready = r_tx_ready;
    assign rx_done  = r_rx_done;
    assign SCL      = r_SCL;

    always_ff @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            r_sda_out  <= 1'h0;
            r_sda_oe   <= 0;
            r_SCL      <= 1;
            clk_cnt    <= 0;
            bit_cnt    <= 0;
            r_tx_data  <= 0;
            r_tx_done  <= 0;
            r_tx_ready <= 0;
            r_rx_data  <= 0;
            r_rx_done  <= 0;
            r_reading  <= 0;
        end else begin
            state      <= state_n;
            r_sda_out  <= r_sda_out_n;
            r_sda_oe   <= r_sda_oe_n;
            r_SCL      <= r_SCL_n;
            clk_cnt    <= clk_cnt_n;
            bit_cnt    <= bit_cnt_n;
            r_tx_data  <= r_tx_data_n;
            r_tx_done  <= r_tx_done_n;
            r_tx_ready <= r_tx_ready_n;
            r_rx_data  <= r_rx_data_n;
            r_rx_done  <= r_rx_done_n;
            r_reading  <= r_reading_n;
        end
    end

    always_comb begin
        state_n      = state;
        r_sda_out_n  = r_sda_out;
        r_sda_oe_n   = r_sda_oe;
        r_SCL_n      = r_SCL;
        clk_cnt_n    = clk_cnt;
        bit_cnt_n    = bit_cnt;
        r_tx_data_n  = r_tx_data;
        r_tx_done_n  = r_tx_done;
        r_tx_ready_n = r_tx_ready;
        r_rx_data_n  = r_rx_data;
        r_rx_done_n  = r_rx_done;
        r_reading_n  = r_reading;

        case (state)

            IDLE: begin
                r_sda_oe_n   = 1'b0;
                r_sda_out_n  = 1'h0;
                r_SCL_n      = 1'b1;
                r_tx_done_n  = 1'b0;
                r_tx_ready_n = 1'b1;
                r_rx_done_n  = 1'b0;
                r_reading_n  = 1'b0;

                if (I2C_En) begin
                    clk_cnt_n    = 0;
                    r_tx_ready_n = 1'b0;
                    state_n      = START1;
                end
            end

            START1: begin
                r_sda_oe_n  = 1'b1;
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 499) begin
                    clk_cnt_n = 0;
                    state_n   = START2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            START2: begin
                r_sda_oe_n  = 1'b1;
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b0;

                if (clk_cnt == 499) begin
                    clk_cnt_n   = 0;
                    r_tx_data_n = tx_data;
                    state_n     = DATA1;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA1: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b0;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;
                    state_n   = DATA2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA2: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;
                    state_n   = DATA3;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA3: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;

                    if (bit_cnt == 7) begin
                        bit_cnt_n = 0;
                        state_n   = WACK1;
                    end else begin
                        bit_cnt_n   = bit_cnt + 1'b1;
                        r_tx_data_n = {r_tx_data[6:0], 1'b0};
                        state_n     = DATA4;
                    end
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA4: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b0;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;
                    state_n   = DATA1;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK1: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b0;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;
                    state_n   = WACK2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK2: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b1;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;
                    state_n   = WACK3;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK3: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b1;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;
                    state_n   = WACK4;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK4: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b0;

                if (clk_cnt == 249) begin
                    clk_cnt_n = 0;
                    state_n   = HOLD;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            HOLD: begin
                if ((I2C_start == 0) && (I2C_stop == 0)) begin
                    r_tx_data_n = tx_data;
                    bit_cnt_n   = 0;
                    state_n     = DATA1;
                end else if ((I2C_start == 0) && (I2C_stop == 1)) begin
                    state_n = STOP1;
                end
            end

            STOP1: begin
                r_sda_oe_n  = 1'b1;
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 499) begin
                    clk_cnt_n = 0;
                    state_n   = STOP2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            STOP2: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b1;

                if (clk_cnt == 499) begin
                    clk_cnt_n   = 0;
                    r_tx_done_n = 1'b1;
                    state_n     = IDLE;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

        endcase
    end

endmodule