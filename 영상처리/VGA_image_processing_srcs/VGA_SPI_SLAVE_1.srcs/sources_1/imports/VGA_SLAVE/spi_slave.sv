`timescale 1ns / 1ps

module spi_slave (
    input  logic       clk,        // 100 MHz
    input  logic       reset,
    // SPI bus
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       cs,         
    // data interface
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done
);

    typedef enum logic [1:0] {
        IDLE,
        CP0,        
        CP1         
    } state_t;

    state_t state, nstate;

    logic [7:0] tx_reg,  tx_nxt;
    logic [7:0] rx_reg,  rx_nxt;
    logic [2:0] bit_cnt, bit_cnt_nxt;
    logic       done_r,  done_w;

    assign miso    = cs ? 1'bz : tx_reg[7];
    assign rx_data = rx_reg;
    assign done    = done_r;

    logic sclk_d1, sclk_d2;
    logic sclk_pos, sclk_neg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_d1 <= 1'b0;
            sclk_d2 <= 1'b0;
        end else begin
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
        end
    end

    assign sclk_pos = ~sclk_d2 &  sclk_d1;
    assign sclk_neg =  sclk_d2 & ~sclk_d1;

    //  state register 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state   <= IDLE;
            tx_reg  <= '0;
            rx_reg  <= '0;
            bit_cnt <= '0;
            done_r  <= 1'b0;
        end else begin
            state   <= nstate;
            tx_reg  <= tx_nxt;
            rx_reg  <= rx_nxt;
            bit_cnt <= bit_cnt_nxt;
            done_r  <= done_w;
        end
    end

    //  next-state / output 
    always_comb begin
        nstate      = state;
        tx_nxt      = tx_reg;
        rx_nxt      = rx_reg;
        bit_cnt_nxt = bit_cnt;
        done_w      = 1'b0;

        case (state)
            IDLE: begin
                tx_nxt      = tx_data;     
                bit_cnt_nxt = 3'd0;
                if (!cs) nstate = CP0;      
            end

            CP0: begin  // rising edge -> sample mosi
                if (cs) begin
                    nstate = IDLE;           
                end else if (sclk_pos) begin
                    rx_nxt = {rx_reg[6:0], mosi};
                    nstate = CP1;
                end
            end

            CP1: begin  // falling edge -> shift miso & check done
                if (cs) begin
                    nstate = IDLE;
                end else if (sclk_neg) begin
                    if (bit_cnt == 3'd7) begin
                        done_w      = 1'b1;
                        bit_cnt_nxt = 3'd0;
                        nstate      = IDLE;
                    end else begin
                        bit_cnt_nxt = bit_cnt + 1;
                        tx_nxt      = {tx_reg[6:0], 1'b0};
                        nstate      = CP0;
                    end
                end
            end
        endcase
    end

endmodule
