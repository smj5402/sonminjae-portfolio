`timescale 1ns / 1ps

module SPI_SLAVE (
    input logic clk,
    input logic reset,
    input logic sclk,
    input logic mosi,
    output logic miso,
    input logic cs_n,
    output logic [7:0] rx_data,
    output logic done,
    output logic [7:0] LED_LOW
);

    logic cpol = 1'b0;
    logic cpha = 1'b0;


    typedef enum {
        IDLE,
        CP0,
        CP1,
        CP_DELAY
    } state_t;

    state_t state, state_n;

    logic [2:0] bit_cnt, bit_cnt_n;
    logic r_done, r_done_n;
    logic [7:0] r_rx_data, r_rx_data_n;
    logic [7:0] r_slave, r_slave_n;

    assign miso = (!cs_n && ((cpha == 0) || (state == CP0) || (state == CP1))) ? r_slave[7] : 1'hz;
    assign done = r_done;
    assign rx_data = r_rx_data;

    logic [2:0] sclk_sync;
    logic sclk_rising, sclk_falling;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync <= 0;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
        end
    end

    assign sclk_rising  = (sclk_sync[2:1] == 2'b01);
    assign sclk_falling = (sclk_sync[2:1] == 2'b10);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            LED_LOW <= 8'b0000_0001;
        end else begin
            if (r_done_n == 1'b1 && r_done == 1'b0 && r_rx_data_n == 8'b11110000) begin
                LED_LOW <= {LED_LOW[6:0], LED_LOW[7]};
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            r_slave   <= 0;
            r_done    <= 0;
            bit_cnt   <= 0;
            r_rx_data <= 0;
        end else begin
            state     <= state_n;
            r_done    <= r_done_n;
            r_slave   <= r_slave_n;
            bit_cnt   <= bit_cnt_n;
            r_rx_data <= r_rx_data_n;
        end
    end

    always_comb begin
        state_n     = state;
        r_done_n    = r_done;
        r_slave_n   = r_slave;
        bit_cnt_n   = bit_cnt;
        r_rx_data_n = r_rx_data;
        case (state)
            IDLE: begin
                r_done_n = 1'b0;
                if (!cs_n) begin
                    bit_cnt_n = 0;
                    state_n   = cpha ? CP_DELAY : CP0;
                end
            end
            CP0: begin
                if (sclk_rising || sclk_falling) begin
                    r_slave_n = {r_slave[6:0], mosi};
                    state_n   = CP1;
                end
            end
            CP1: begin
                if (sclk_rising || sclk_falling) begin
                    if (bit_cnt == 7) begin
                        bit_cnt_n = 0;
                        r_done_n = 1'b1;
                        r_rx_data_n = r_slave;
                        state_n = cpha ? IDLE : CP_DELAY;
                    end else begin
                        bit_cnt_n = bit_cnt + 1;
                        state_n   = CP0;
                    end
                end else if (cpha == 1 && cs_n == 1'b1) begin
                    if (bit_cnt == 7) begin
                        bit_cnt_n   = 0;
                        r_done_n    = 1'b1;
                        r_rx_data_n = r_slave;
                    end
                    state_n = IDLE;
                end
            end
            CP_DELAY: begin
                if (cpha == 0) begin
                    if (cs_n == 1'b1) begin
                        state_n = IDLE;
                    end
                end else begin
                    if (sclk_falling || sclk_rising) begin
                        state_n = CP0;
                    end
                end
            end
        endcase
    end

endmodule
