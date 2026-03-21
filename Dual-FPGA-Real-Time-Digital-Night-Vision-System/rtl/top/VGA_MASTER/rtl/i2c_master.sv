`timescale 1ns / 1ps


module i2c_master (
    input  logic       clk,
    input  logic       reset,
    input  logic       I2C_En,
    input  logic       I2C_start,
    input  logic       I2C_stop,
    input  logic       rw_mode,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    //internal singals
    output logic       SCL,
    inout  wire        SDA
);

  typedef enum {
    IDLE,
    START1,
    START2,
    DATA1,
    DATA2,
    DATA3,
    DATA4,
    ACK1,
    ACK2,
    ACK3,
    ACK4,
    RX_DATA1,
    RX_DATA2,
    RX_DATA3,
    RX_DATA4,
    M_NACK1,
    M_NACK2,
    M_NACK3,
    M_NACK4,
    HOLD,
    STOP1,
    STOP2
  } state_t;

  state_t state, state_next;

  logic [9:0] clk_counter_reg, clk_counter_next;
  logic [2:0] bit_counter_reg, bit_counter_next;
  logic [7:0] tx_data_reg, tx_data_next;
  logic [7:0] rx_data_reg, rx_data_next;
  logic tx_done_reg, tx_done_next;
  logic rx_done_reg, rx_done_next;

  //SDA 제어 open drain
  logic sda_out;
  logic sda_en;
  assign SDA = (sda_en && sda_out == 1'b0) ? 1'b0 : 1'bz;
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state           <= IDLE;
      clk_counter_reg <= 0;
      bit_counter_reg <= 0;
      tx_data_reg     <= 0;
      tx_done_reg     <= 1'b0;
    end else begin
      state           <= state_next;
      clk_counter_reg <= clk_counter_next;
      bit_counter_reg <= bit_counter_next;
      tx_data_reg     <= tx_data_next;
      rx_data_reg     <= rx_data_next;
      tx_done_reg     <= tx_done_next;
      rx_done_reg     <= rx_done_next;
    end
  end


  always_comb begin
    state_next       = state;
    clk_counter_next = clk_counter_reg;
    bit_counter_next = bit_counter_reg;
    tx_data_next     = tx_data_reg;
    rx_data_next     = rx_data_reg;
    tx_done_next     = 1'b0;
    rx_done_next     = 1'b0;

    SCL              = 1'b1;
    sda_out          = 1'b1;
    sda_en           = 1'b1;
    tx_ready         = 1'b0;

    case (state)
      IDLE: begin
        SCL              = 1'b1;
        sda_out          = 1'b1;
        sda_en           = 1'b1;
        tx_ready         = 1'b1;
        bit_counter_next = 0;
        if (I2C_En) begin
          state_next       = START1;
          tx_data_next     = tx_data;
          clk_counter_next = 0;
        end
      end
      START1: begin
        SCL     = 1'b1;
        sda_en  = 1'b1;
        sda_out = 1'b0;
        if (clk_counter_reg == 499) begin
          clk_counter_next = 0;
          state_next = START2;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      START2: begin
        SCL     = 1'b0;
        sda_en  = 1'b1;
        sda_out = 1'b0;
        if (clk_counter_reg == 499) begin
          clk_counter_next = 0;
          state_next = DATA1;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      DATA1: begin
        SCL     = 1'b0;
        sda_out = tx_data_reg[7];
        sda_en  = 1'b1;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = DATA2;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      DATA2, DATA3: begin
        SCL = 1'b1;
        sda_out = tx_data_reg[7];
        sda_en = 1'b1;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = (state == DATA2) ? DATA3 : DATA4;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      DATA4: begin
        SCL     = 1'b0;
        sda_out = tx_data_reg[7];
        sda_en  = 1'b1;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          if (bit_counter_reg == 7) begin
            state_next       = ACK1;
            bit_counter_next = 0;
          end else begin
            bit_counter_next = bit_counter_reg + 1;
            tx_data_next     = {tx_data_reg[6:0], 1'b0};
            state_next       = DATA1;
          end
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      ACK1: begin
        SCL = 1'b0;
        sda_en = 1'b0;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = ACK2;
        end else clk_counter_next = clk_counter_reg + 1;
      end
      ACK2, ACK3: begin
        SCL = 1'b1;
        sda_en = 1'b0;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = (state == ACK2) ? ACK3 : ACK4;
        end else clk_counter_next = clk_counter_reg + 1;
      end
      ACK4: begin
        SCL = 1'b0;
        sda_en = 1'b0;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = HOLD;
          tx_done_next = 1'b1;
        end else clk_counter_next = clk_counter_reg + 1;
      end

      RX_DATA1: begin
        SCL = 1'b0;
        sda_en = 1'b0;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = RX_DATA2;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      RX_DATA2: begin
        SCL = 1'b1;
        sda_en = 1'b0;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          rx_data_next = {rx_data_reg[6:0], SDA};
          state_next = RX_DATA3;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      RX_DATA3: begin
        SCL = 1'b1;
        sda_en = 1'b0;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = RX_DATA4;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      RX_DATA4: begin
        SCL = 1'b0;
        sda_en = 1'b0;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          if (bit_counter_reg == 7) begin
            state_next = M_NACK1;
            bit_counter_next = 0;
          end else begin
            bit_counter_next = bit_counter_reg + 1;
            state_next = RX_DATA1;
          end
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      M_NACK1: begin
        SCL     = 1'b0;
        sda_en  = 1'b1;
        sda_out = 1'b1;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = M_NACK2;
        end else clk_counter_next = clk_counter_reg + 1;
      end
      M_NACK2, M_NACK3: begin
        SCL     = 1'b1;
        sda_en  = 1'b1;
        sda_out = 1'b1;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = (state == M_NACK2) ? M_NACK3 : M_NACK4;
        end else clk_counter_next = clk_counter_reg + 1;
      end
      M_NACK4: begin
        SCL     = 1'b0;
        sda_en  = 1'b1;
        sda_out = 1'b1;
        if (clk_counter_reg == 249) begin
          clk_counter_next = 0;
          state_next = HOLD;
          rx_done_next = 1'b1;
        end else clk_counter_next = clk_counter_reg + 1;
      end
      HOLD: begin
        SCL = 1'b0;
        tx_ready = 1'b1;
        if (I2C_stop) begin
          state_next = STOP1;
          clk_counter_next = 0;
        end else if (I2C_start) begin
          state_next = START1;
          clk_counter_next = 0;
        end else if (I2C_En) begin
          tx_data_next = tx_data;
          clk_counter_next = 0;
          state_next = (rw_mode == 1'b0) ? DATA1 : RX_DATA1;
        end

      end
      STOP1: begin
        SCL = 1'b1;
        sda_en = 1'b1;
        sda_out = 0;
        if (clk_counter_reg == 499) begin
          clk_counter_next = 0;
          state_next       = STOP2;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
      STOP2: begin
        SCL = 1'b1;
        sda_en = 1'b1;
        sda_out = 1;
        if (clk_counter_reg == 499) begin
          clk_counter_next = 0;
          state_next       = IDLE;
        end else begin
          clk_counter_next = clk_counter_reg + 1;
        end
      end
    endcase
  end

  assign tx_done = tx_done_reg;
  assign rx_data = rx_data_reg;
  assign rx_done = rx_done_reg;
endmodule
