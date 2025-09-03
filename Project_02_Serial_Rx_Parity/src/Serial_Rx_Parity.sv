// Serial Receiver with parity check (Odd parity system)
// This module receives 8 bit serial data, start, parity and stop bit (11 bit)
// Asserts 'done' only when stop bit is received and has passed odd parity check
`timescale 1ns/1ps
module Serial_Rx_Parity (
    input clk, // clock input
    input rst_n, // active-low async reset
    input i_data, // input data
    output logic [7:0] out_byte, // output data
    output logic done // pulse for DONE
);

  // State Definition
  typedef enum logic [2:0] {
    IDLE,
    START_BIT, // A state that has received start bit 0
    RECEIVE_BYTE, // Receive all Serial data bits (8 bit)
    PARITY_BIT,
    STOP_BIT, // A state that has received stop bit 1
    WAIT // Wait when stop bit isn't 1
  } state_t;

  state_t curr_state, next_state;

  reg [7:0] r_out_byte;
  reg parity;
  reg [3:0] counter;
  
  // State filp-flops
  always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      curr_state <= IDLE;
    end else
      curr_state <= next_state;
  end
  
  // counter for receiving
  always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      counter <= 4'd0;
    end else begin
      case(next_state)
        START_BIT    : counter <= 4'd0;

        RECEIVE_BYTE : begin 
          if(counter <9) begin
          counter <= counter + 4'd1;
          end else if(counter == 8) begin
            counter <= 0;
          end
        end

        default : ;
      endcase
    end
  end

  // State transition logic
  always_comb begin
    next_state = IDLE;
    case(curr_state)
      IDLE 	        : next_state = !i_data ? START_BIT : IDLE;
      START_BIT	    : next_state = RECEIVE_BYTE;
      RECEIVE_BYTE  : next_state = (counter == 8) ? PARITY_BIT : RECEIVE_BYTE;
      PARITY_BIT    : next_state = i_data ? STOP_BIT : WAIT;
      STOP_BIT      : next_state = i_data ? IDLE : START_BIT;
      WAIT          : next_state = i_data ? IDLE : WAIT;
      default       : next_state = curr_state;
    endcase
  end

  // Data register update
  always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_out_byte <= 8'b0;
      parity   <= 1'b0;
    end else begin
      case(next_state)
        RECEIVE_BYTE : r_out_byte[counter] <= i_data;
        PARITY_BIT   : parity <= ~ (^r_out_byte); // receive parity bit
        STOP_BIT,
        WAIT         : r_out_byte <= 8'b0;

        default      : begin
          r_out_byte <= r_out_byte;
          parity <= 1'b0;
        end
      endcase
    end
  end

  // Output logic and Odd parity check
  wire [8:0] parity_check_bit;
  assign parity_check_bit = {out_byte, parity};
  assign done = (curr_state == STOP_BIT)&& ^parity_check_bit;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      out_byte <= 0;
    end else begin
      case(next_state) 
        PARITY_BIT : out_byte <= r_out_byte;
        default    : out_byte <= 0;
      endcase
    end
  end

endmodule