// Serial Receiver with parity check (Odd parity system)
// This module receives 8 bit serial data, start, parity and stop bit (11 bit)
// Asserts 'done' only when stop bit is received and has passed odd parity check
`timescale 1ns/1ps
module Serial_Rx_Parity (
    input clk, // clock input
    input rst_n, // active-low async reset
    input i_data, // input data
    output [7:0] out_byte, // output data
    output done // pulse for DONE
);

  // State Definition
  typedef enum logic [3:0] {
    IDLE 	 	        = 4'd0,
    START_BIT	      = 4'd1, // Start bit should be 0
    B0_RECEIVED  	 	= 4'd2,
    B1_RECEIVED	    = 4'd3,
    B2_RECEIVED	    = 4'd4,
    B3_RECEIVED,    = 4'd5,
    B4_RECEIVED,		  = 4'd6,
    B5_RECEIVED,		  = 4'd7,
    B6_RECEIVED,		  = 4'd8,
    B7_RECEIVED,	  	= 4'd9, // Receive all Serial data bits (8 bit)
    PARITY_BIT,      = 4'd10,
    STOP_BIT,    	 	= 4'd11, // Stop bit should be 1
    WAIT         	 	= 4'd12 // Wait when stop bit isn't 1
  } state_t;

  state_t c_state, n_state;

  reg [7:0] r_out_byte;
  reg parity;
  
  // State filp-flops
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      c_state <= IDLE;
    end else
      c_state <= n_state;
  end

  // State transition logic
  always@(*) begin
    case(c_state)
      IDLE 	               : n_state = i_data ? IDLE : START_BIT;
      START_BIT	           : n_state = B0_RECEIVED;
      B0_RECEIVED	 	       : n_state = B1_RECEIVED;
      B1_RECEIVED	 	       : n_state = B2_RECEIVED;
      B2_RECEIVED 	       : n_state = B3_RECEIVED;
      B3_RECEIVED	  	     : n_state = B4_RECEIVED;
      B4_RECEIVED	         : n_state = B5_RECEIVED;
      B5_RECEIVED	 	       : n_state = B6_RECEIVED;
      B6_RECEIVED	 	       : n_state = B7_RECEIVED;
      B7_RECEIVED	 	       : n_state = PARITY_BIT;
      PARITY_BIT           : n_state = i_data ? STOP_BIT : WAIT;
      STOP_BIT             : n_state = i_data ? IDLE : START_BIT;
      WAIT                 : n_state = i_data ? IDLE : WAIT;
      default              : n_state = IDLE;
    endcase
  end

  // Data register update
  always@(posedge clk) begin
    case(n_state)
      B0_RECEIVED   	: r_out_byte[0]  <= i_data;
      B1_RECEIVED  		: r_out_byte[1]  <= i_data;
      B2_RECEIVED     : r_out_byte[2]  <= i_data;
      B3_RECEIVED  		: r_out_byte[3]  <= i_data;
      B4_RECEIVED   	: r_out_byte[4]  <= i_data;
      B5_RECEIVED   	: r_out_byte[5]  <= i_data;
      B6_RECEIVED   	: r_out_byte[6]  <= i_data;
      B7_RECEIVED  		: r_out_byte[7]  <= i_data;
      PARITY_BIT      : parity  		   <= i_data;  //  i_data here is received parity bit
    endcase
  end

  // Output logic and Odd parity check
  wire [8:0] parity_check_bit;
  assign parity_check_bit = {r_out_byte, parity};
  assign done =(c_state == STOP_BIT) && ^parity_check_bit;
  assign out_byte = r_out_byte[7:0];

endmodule





