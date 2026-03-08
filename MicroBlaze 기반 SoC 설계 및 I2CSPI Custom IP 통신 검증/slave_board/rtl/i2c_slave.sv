`timescale 1ns / 1ps

module I2C_SLA (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    input  logic       SCL,
    inout  logic       SDA,
    output logic  [7:0] LED_HIGH
);

    logic [2:0] r_SDA;
    logic sclk_rising, sclk_falling;
    logic r_SDA_rising, r_SDA_falling;
    logic [2:0] sclk_sync;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync <= 3'd0;
            r_SDA     <= 3'd0;
        end else begin
            sclk_sync <= {sclk_sync[1:0], SCL};
            r_SDA     <= {r_SDA[1:0], SDA};
        end
    end

    assign sclk_rising   = (sclk_sync[2:1] == 2'b01);
    assign sclk_falling  = (sclk_sync[2:1] == 2'b10);
    assign r_SDA_rising  = (r_SDA[2:1] == 2'b01);
    assign r_SDA_falling = (r_SDA[2:1] == 2'b10);

    parameter SLAV_ADDER = 7'b1111000;

    logic r_sda_oe, r_sda_oe_n;
    assign SDA = (r_sda_oe) ? 1'b0 : 1'hz;

    typedef enum {
        IDLE,
        START1,
        ADDR1,
        ADDR2,
        ADDR_ACK,
        READ1,
        READ2,
        DATA_ACK,
        WRITE1,
        WRITE2,
        WACK
    } state_t;

    state_t state, state_n;

    logic [7:0] r_rx_data, r_rx_data_n;
    logic [7:0] r_tx_data, r_tx_data_n;
    logic [2:0] bit_cnt, bit_cnt_n;
    logic r_rx_done, r_rx_done_n;
    logic r_tx_done, r_tx_done_n;
    logic r_addr_ok, r_addr_ok_n;
    logic r_is_reading, r_is_reading_n;

    assign rx_data = r_rx_data;
    assign rx_done = r_rx_done;
    assign tx_done = r_tx_done;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            LED_HIGH  <= 8'b0000_0001;
        end else begin
            if (state == ADDR2 && sclk_falling && bit_cnt == 7) begin
                if (r_rx_data == 8'b01111110) begin
                    LED_HIGH <= {LED_HIGH[6:0], LED_HIGH[7]}; 
                end
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            r_rx_data    <= 0;
            r_tx_data    <= 0;
            r_sda_oe     <= 0;
            bit_cnt      <= 0;
            r_rx_done    <= 0;
            r_tx_done    <= 0;
            r_addr_ok    <= 0;
            r_is_reading <= 0;
        end else begin
            state        <= state_n;
            r_rx_data    <= r_rx_data_n;
            r_tx_data    <= r_tx_data_n;
            r_sda_oe     <= r_sda_oe_n;
            bit_cnt      <= bit_cnt_n;
            r_rx_done    <= r_rx_done_n;
            r_tx_done    <= r_tx_done_n;
            r_addr_ok    <= r_addr_ok_n;
            r_is_reading <= r_is_reading_n;
        end
    end

    always_comb begin
        state_n        = state;
        r_rx_data_n    = r_rx_data;
        r_tx_data_n    = r_tx_data;
        r_sda_oe_n     = 1'b0;
        bit_cnt_n      = bit_cnt;
        r_rx_done_n    = 1'b0;
        r_tx_done_n    = 1'b0;  // 1클럭 펄스
        r_addr_ok_n    = r_addr_ok;
        r_is_reading_n = r_is_reading;

        if (r_SDA_rising && (sclk_sync[2:1] == 2'b11)) begin
            state_n = IDLE;
        end else if (r_SDA_falling && (sclk_sync[2:1] == 2'b11)) begin
            bit_cnt_n      = 0;
            r_addr_ok_n    = 1'b0;
            r_is_reading_n = 1'b0;
            state_n        = START1;
        end else begin
            case (state)
                IDLE: begin

                end

                START1: begin
                    if (!(sclk_sync[2]) && !(r_SDA[2])) begin
                        state_n = ADDR1;
                    end
                end

                ADDR1: begin
                    if (sclk_rising) begin
                        r_rx_data_n = {r_rx_data[6:0], r_SDA[2]};
                        state_n     = ADDR2;
                    end
                end

                ADDR2: begin
                    if (sclk_falling) begin
                        if (bit_cnt == 7) begin
                            bit_cnt_n = 0;
                            if (SLAV_ADDER == r_rx_data[7:1]) begin
                                r_addr_ok_n = 1'b1;
                            end else begin
                                r_addr_ok_n = 1'b0;
                            end

                            r_is_reading_n = r_rx_data[0];
                            state_n        = ADDR_ACK;
                        end else begin
                            bit_cnt_n = bit_cnt + 1'b1;
                            state_n   = ADDR1;
                        end
                    end
                end

                ADDR_ACK: begin
                    if (r_addr_ok) begin
                        r_sda_oe_n = 1'b1;
                    end else begin
                        r_sda_oe_n = 1'b0;
                    end

                    if (sclk_falling) begin
                        if (!r_addr_ok) begin
                            state_n = IDLE;
                        end else begin
                            if (r_is_reading) begin
                                r_tx_data_n = tx_data;
                                state_n = WRITE1;
                            end else begin
                                state_n = READ1;
                            end
                        end
                    end
                end

                READ1: begin
                    if (sclk_rising) begin
                        r_rx_data_n = {r_rx_data[6:0], SDA};
                        state_n = READ2;
                    end
                end

                READ2: begin
                    if (sclk_falling) begin
                        if (bit_cnt == 7) begin
                            bit_cnt_n = 0;
                            state_n   = DATA_ACK;
                        end else begin
                            bit_cnt_n = bit_cnt + 1'b1;
                            state_n   = READ1;
                        end
                    end
                end

                DATA_ACK: begin
                    r_sda_oe_n = 1'b1;
                    if (sclk_falling) begin
                        r_rx_done_n = 1'b1;
                        state_n     = READ1;
                    end
                end

                WRITE1: begin
                    r_sda_oe_n = ~r_tx_data[7];
                    if (sclk_rising) begin
                        state_n = WRITE2;
                    end
                end

                WRITE2: begin
                    r_sda_oe_n = ~r_tx_data[7];
                    if (sclk_falling) begin
                        if (bit_cnt == 7) begin
                            bit_cnt_n = 0;
                            state_n   = WACK;
                        end else begin
                            bit_cnt_n   = bit_cnt + 1'b1;
                            r_tx_data_n = {r_tx_data[6:0], 1'b0};
                            state_n     = WRITE1;
                        end
                    end
                end

                WACK: begin
                    r_sda_oe_n = 1'b0;
                    if (sclk_rising) begin

                    end
                    if (sclk_falling) begin
                        r_tx_done_n = 1'b1;
                        r_tx_data_n = tx_data;
                        state_n     = WRITE1;
                    end
                end
            endcase
        end
    end
endmodule
