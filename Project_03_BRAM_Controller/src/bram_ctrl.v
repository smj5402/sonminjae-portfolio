// Block RAM Controller
// This module writes data 100 times to BRAM then reads it back
`timescale 1ns/1ps
module bram_ctrl #(
  parameter DATA_WIDTH = 8,
  parameter MEM_SIZE   = 2**12-1,
  parameter ADDR_WIDTH = $clog2(MEM_SIZE)
)(
  input clk,
  input rst_n, // active low async reset
  input i_run, // For start writing
  input [ADDR_WIDTH-1:0] i_cnt, // The number of operation(Write or Read) times 
  output o_idle,
  output o_write,
  output o_read,
  output o_done,
 // Memory interface
  output [ADDR_WIDTH-1:0] addr,
  output en,
  output we,
  output [DATA_WIDTH-1:0] din,
  input [DATA_WIDTH-1:0] qout,
 // Output read value from BRAM
  output o_valid,
  output [DATA_WIDTH-1:0] o_mem_data
);
  // State Definition
  parameter [1:0]
  IDLE  = 2'd0,
  WRITE = 2'd1,
  READ  = 2'd2,
  DONE  = 2'd3;
  
  reg [1:0] c_state, n_state;
  
  wire is_write_done;
  wire is_read_done;

  
  // State flip-flops
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      c_state <= IDLE;
    end else begin
      c_state <= n_state;
    end
  end
  
  // State transition logic
  always@(*) begin
    n_state = c_state;
    case(c_state) 
      
      IDLE : begin
        if (i_run && i_cnt>0) 
          n_state = WRITE;
      end
      
      WRITE : begin
        if(is_write_done) 
          n_state = READ;
      end
      
      READ : begin
        if(is_read_done)
          n_state = DONE;
      end
      
      DONE : n_state = IDLE;
      default : n_state = IDLE;
    endcase
  end    
      
  // Output logic
  assign o_idle  = (c_state == IDLE);
  assign o_write = (c_state == WRITE);
  assign o_read  = (c_state == READ);
  assign o_done = (c_state == DONE);
  
  // Registering i_cnt
  reg [ADDR_WIDTH-1:0] r_cnt;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_cnt <= {ADDR_WIDTH{1'b0}};
    end else if (o_done) begin
      r_cnt <= {ADDR_WIDTH{1'b0}}; 
    end else if (i_run) begin
      r_cnt <= i_cnt;
    end
  end  
  
  // add_cnt
  reg [ADDR_WIDTH-1:0] addr_cnt;
  assign is_write_done = o_write && (addr_cnt == r_cnt -1);
  assign is_read_done  = o_read  && (addr_cnt == r_cnt -1);
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      addr_cnt <= {ADDR_WIDTH{1'b0}}; 
    end else if(is_write_done || is_read_done) begin
      addr_cnt <= {ADDR_WIDTH{1'b0}}; 
    end else if (o_write || o_read) begin
      addr_cnt <= addr_cnt + 1'd1;
    end
  end
  
  // assign Memory Interface
  assign addr = addr_cnt;
  assign en   = o_write || o_read;
  assign we   = o_write;
  assign din  = o_write ? addr_cnt : {DATA_WIDTH{1'b0}}; 
  
  // delay valid 1 cycle
  // Read output has one cycle latency 
  reg r_valid;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_valid <= 1'b0;
    end else
      r_valid <= o_read;  // r_valid is one cycle delay signal of o_READ
  end
      
  
  // assign output
  assign o_valid = r_valid;
  assign o_mem_data = qout;
  
endmodule