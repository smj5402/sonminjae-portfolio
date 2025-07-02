//Serial Receiver with parity check
`timescale 1ns/1ps
module Serial_Receiver_Parity (
    input clk,rst,
    input i_data,
    output [7:0] out_byte,
    output done
);
  // odd parity system
  // done -> parity bit 1? ??
  
  parameter [3:0] IDLE 	 	= 4'd0;
  parameter [3:0] START	 	= 4'd1;
  parameter [3:0] S1  	 	= 4'd2;
  parameter [3:0] S2	    = 4'd3;
  parameter [3:0] S3	    = 4'd4;
  parameter [3:0] S4	    = 4'd5;
  parameter [3:0] S5		= 4'd6;
  parameter [3:0] S6		= 4'd7;
  parameter [3:0] S7		= 4'd8;
  parameter [3:0] S8	 	= 4'd9;
  parameter [3:0] PARITY   	= 4'd10;
  parameter [3:0] STOP	 	= 4'd11;
  parameter [3:0] WAIT 	 	= 4'd12;
  reg [3:0] c_state, n_state;
  reg [7:0] r_out_byte;
  reg parity;
  
  always@(posedge clk) begin
    if(rst) begin
      c_state <= IDLE;
    end else
      c_state <= n_state;
  end

  // State transition
  always@(*) begin
    case(c_state)
      IDLE 	       : n_state = i_data ? IDLE : START;
      START	       : n_state = S1;
      S1	 	   : n_state = S2;
      S2	 	   : n_state = S3;
      S3 	       : n_state = S4;
      S4	  	   : n_state = S5;
      S5	       : n_state = S6;
      S6	 	   : n_state = S7;
      S7	 	   : n_state = S8;
      S8	 	   : n_state = PARITY;
      PARITY       : n_state = i_data ? STOP : WAIT;
      STOP	       : n_state = i_data ? IDLE : START;
      WAIT         : n_state = i_data ? IDLE : WAIT;
      default      : n_state = IDLE;
    endcase
  end

  always@(posedge clk) begin
    case(n_state)
      S1   		: r_out_byte[0]  <= i_data;
      S2  		: r_out_byte[1]  <= i_data;
      S3   		: r_out_byte[2]  <= i_data;
      S4  		: r_out_byte[3]  <= i_data;
      S5   		: r_out_byte[4]  <= i_data;
      S6   		: r_out_byte[5]  <= i_data;
      S7   		: r_out_byte[6]  <= i_data;
      S8  		: r_out_byte[7]  <= i_data;
      PARITY    : parity  		 <= i_data;  //  i_data here is received parity bit
      //STOP 	: stop bit (==1)
      default   : r_out_byte	 <= r_out_byte;
    endcase
  end

  // ?? ??? ???,  8?? ??? + parity ??? reduction XOR  ??? 1 ??? ?.
  wire [8:0] test_bit;
  assign test_bit = { r_out_byte, parity};
  assign done =(c_state == STOP) && ^test_bit;
  assign out_byte = r_out_byte[7:0];

endmodule





