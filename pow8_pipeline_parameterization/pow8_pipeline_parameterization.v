// Operates i_data^(2^a)  a= LATENCY
`timescale 1ns/1ps
// 3 cycle latency and 1 throughput pipeline 
module pow8_pipeline_parameteriztion #( 
  parameter
  LATENCY = 3,
  TEST_TIMES = 100
)(
  input clk, rst_n,
  input [6:0] i_data, // 1~100
  input i_valid,
  output o_valid,
  output [63:0] o_data
);
  // LATENCY 3 
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
  assign pow[0] = i_data*i_data;
  //assign pow[1] = r_pow[0] * r_pow[0];
  //assign pow[2] = r_pow[1] * r_pow[1];
  //~~~
  // pow[0]= i_data^(2^1) ,  pow[1]= i_data^(2^2) , pow[2]= i_data^(2^3) ...
  
  // Generate
  genvar i;
  generate 
    for(i=1;i<LATENCY;i=i+1) begin : pow_gen
      assign pow[i] = r_pow[i-1] * r_pow[i-1];
    end
  endgenerate
  
  // Pipeline Registering
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