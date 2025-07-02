`timescale 1ns/1ps
`define LATENCY 3
`define TEST_TIMES 100
module tb_pow8_pipeline_parameterization;
reg clk, rst_n;
reg [6:0] i_data;
reg i_valid;
wire o_valid;
wire [63:0] o_data;

pow8_pipeline_parameteriztion # ( 
    .LATENCY    (`LATENCY),
    .TEST_TIMES (`TEST_TIMES)
    ) pipeline_inst1 (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_data     (i_data),
    .i_valid    (i_valid),
    .o_valid    (o_valid),
    .o_data     (o_data)
);

integer i;

// clk gen
always #5 clk=~clk;

initial begin
   $display("Initialize values [%t]", $time);
   clk=0;
   rst_n=1;
   i_data=7'd0;
   i_valid=0;
   #50;

   $display("Reset [%t]", $time);
   rst_n=0;
   #10;
   rst_n=1;
   #10;

   $display("Start Simulation [%t]", $time);
   @(posedge clk);
   for(i=0;i<`TEST_TIMES; i=i+1) begin
    i_data = i;
    i_valid =1;
    @(posedge clk);
   end
   #10;
   @(negedge clk);
   i_data = 0;
   i_valid = 0;
   #100;
   
   $display("Finish Simulation [%t]", $time);
   $finish;
end
endmodule