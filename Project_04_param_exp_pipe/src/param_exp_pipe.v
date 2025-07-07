// param_exp_pipe
// This module computes i_data^(a^b) in pipelined architecture (b = LATENCY)
// To check pipeline's operation, I assumsed inputs are consecutive numbers from 0 to MAX_INPUT_VALUE
// 3 cycle latency and 1 throughput pipelined architecture
`timescale 1ns/1ps
module param_exp_pipe #( 
  parameter
  LATENCY = 3,
  MAX_INPUT_VALUE = 99 // 100 times
)(
  input clk, rst_n,
  input [6:0] i_data, // Input data range : 0 ~ 127 (2^7-1)
  input i_valid,      // Valid signal for input
  output o_valid,     // Valid signal for output
  output [63:0] o_data // Output result
);
  // Internal signals
  wire [63:0] pow [0:LATENCY-1]; 
  reg  [63:0] r_pow [0:LATENCY-1];

  reg  [LATENCY-1:0]  r_valid;
  
  assign o_valid = r_valid[LATENCY-1];
  assign o_data  = r_pow[LATENCY-1];
  
  // Valid shift register
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_valid <= {LATENCY{1'b0}};
    end else
      r_valid <= {r_valid [LATENCY-2:0],i_valid};
  end
  
  // Operation logic
  assign pow[0] = i_data*i_data; // -> i_data^2
  // pow[1] = r_pow[0] * r_pow[0];  -> i_data^4
  // pow[2] = r_pow[1] * r_pow[1];  -> i_data^8
  // pow[3] = r_pow[2] * r_pow[2];  -> i_data^16
  //~~~
  
  // Repetitive logic using generate block
  genvar i;
  generate 
    for(i=1;i<LATENCY;i=i+1) begin : pow_gen
      assign pow[i] = r_pow[i-1] * r_pow[i-1];
    end
  endgenerate
  
  // Pipeline Registering for each stage
  integer j,k;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      for(j=0; j<LATENCY; j=j+1)
        r_pow[j] <= 'b0;
    end else begin
      for(k=0; k<LATENCY; k=k+1)
        r_pow[k] <= pow[k];
    end
  end
endmodule