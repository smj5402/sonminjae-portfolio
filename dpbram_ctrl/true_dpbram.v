`timescale 1ns/1ps
module true_dpbram #( parameter 
                     DATA_WIDTH = 8, // 1 byte
                     MEM_SIZE  	= 10000, 
                     ADDR_WIDTH = $clog2(MEM_SIZE)
                    )(
  input clk,rst_n,
  // Memory Interface  
  input [ADDR_WIDTH-1:0] addr,
  input en,
  input we,
  input [DATA_WIDTH-1 : 0] d,
  output reg [DATA_WIDTH-1 :0] q);
  
  //(* ram style = "block" *) 
  reg [DATA_WIDTH-1:0] BRAM [0: MEM_SIZE-1];
  integer i;

  initial begin
    q={DATA_WIDTH{1'b0}};
    
    for(i=0; i<MEM_SIZE; i=i+1) begin
      BRAM[i] = {DATA_WIDTH{1'b0}};
      end
  end
  
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      q={DATA_WIDTH{1'b0}};
    end
    else begin
        if(en) begin
          if(we)
            //write
            BRAM[addr] <= d;
          else
            //read
            q <= BRAM[addr];
        end // en
    end //!rst_n
  end // always
endmodule