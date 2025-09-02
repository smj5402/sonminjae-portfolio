// tb_bram_ctrl
// Test for writing and reading data to BRAM using Mod-100 counter

`timescale 1ns/1ps
`define ADDR_WIDTH 7
`define DATA_WIDTH 16
`define MEM_SIZE   128

module tb_bram_ctrl;
  reg  clk,rst_n;
  reg  i_run;
  reg  [`ADDR_WIDTH-1:0] i_cnt;
  wire o_idle;
  wire o_write;
  wire o_read;
  wire o_done;
 // Memory interface
  wire [`ADDR_WIDTH-1:0] addr;
  wire en;
  wire we;
  wire [`DATA_WIDTH-1:0] din;
  wire  [`DATA_WIDTH-1:0] qout;
 // output read value from BRAM
  wire o_valid;
  wire [`DATA_WIDTH-1:0] o_mem_data;


  bram_ctrl # (.DATA_WIDTH (`DATA_WIDTH),
               .MEM_SIZE   (`MEM_SIZE ),
               .ADDR_WIDTH  (`ADDR_WIDTH))
  simple_bram_ctrl (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_run      (i_run),
    .i_cnt      (i_cnt),
    .o_idle     (o_idle),
    .o_write    (o_write),
    .o_read     (o_read),
    .o_done     (o_done),
    .addr       (addr),
    .en         (en),
    .we         (we),
    .din        (din),
    .qout       (qout),
    .o_valid    (o_valid),
    .o_mem_data (o_mem_data)
  );
              
  true_dpbram #(.DATA_WIDTH (`DATA_WIDTH),
                .MEM_SIZE   (`MEM_SIZE),
                .ADDR_WIDTH  (`ADDR_WIDTH))
  u_tdpbram (
    .clk      (clk),
    .rst_n    (rst_n),
    .addr0     (addr),
    .en0       (en),
    .we0       (we),
    .d0	      (din),
    .q0	      (qout),
    .addr1     (),
    .en1       (),
    .we1       (),
    .d1	      (),
    .q1	      ()
  );

  //clk gen
  always #5 clk=~clk;
  
  initial begin
  $display("Initialize values [%t]", $time);
  clk=0;
  rst_n=1;
  i_run=0;
  i_cnt=0;
  #50

  $display("Reset [%t]", $time);
  rst_n = 0;
  #10;
  rst_n = 1;
  

  @(posedge clk)  
  $display("Check IDLE [%t]", $time);
  wait(o_idle);

  $display("Start Simulation [%t]", $time);
  i_run = 1;
  i_cnt = 7'd100;

  @(posedge clk);
  i_run = 0;

  $display("Wait Done [%t]", $time);
  wait(o_done);

  #100;

  $display("Finish Simulation [%t]", $time);
  $finish;
  end
endmodule


