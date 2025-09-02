// True Dual Port Block RAM

`timescale 1ns/1ps

module true_dpbram #(
	parameter DATA_WIDTH = 16,
	parameter ADDR_WIDTH = $clog2(MEM_SIZE),
	parameter MEM_SIZE = 4095 // 2^12-1
	)(
    input clk, // clock input
    // Memory Interface
	input en0,en1, // Enable signals for port 0 and port 1
    input we0,we1, // Write enable for  port 0 and port 1
	input [DATA_WIDTH-1:0] d0,d1, // Data inputs for port 0 and port 1
	output reg [DATA_WIDTH-1:0] q0,q1, // Data outputs for port 0 and port 1
	input [ADDR_WIDTH-1:0] addr0,addr1 // Address inputs for port 0 and port 1
    );


// Declare Memory
(* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [0:MEM_SIZE-1];

// Initialize outputs
initial begin
	q0=0;
	q1=0;
end

// Port 0 
always@(posedge clk) begin
    if(en0) begin
        if(we0)
        // Write
            ram[addr0] <= d0;
        else
        // Read
            q0 <= ram[addr0];
    end
end


always@(posedge clk) begin
    if(en1) begin
        if(we1)
        // Write
            ram[addr1] <= d1; // write
        else
        // Read
            q1 <= ram[addr1]; // read
    end
end

endmodule