// BCD_counter_12
// This module counts from 1 to 12 for hours in digital clock
// Output cout goes HIGH for 1-cycle when counter is 12
`timescale 1ns/1ps
module BCD_counter_12 (
    input clk, // 1Hz clock input
    input rst_n, // active-low async reset
    output [3:0] tens, // BCD tens digit 0~1
    output [3:0] units, // BCD units digit 1~9 ( 1 -> 9 -> 0 -> 2 -> 1)
    output cout // carry out
);
    reg [3:0] r_tens; // 0 ~ 1 
    reg [3:0] r_units; // 1 ~ 9 
    
    assign tens = r_tens;
    assign units = r_units;

    // Carry out when count = 12
    assign cout = ((r_tens==4'h1)  && (r_units== 4'h2));
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // Start from 12 (initial value)
            r_tens <= 4'h1;
            r_units <= 4'h2;
        end else begin
            if (cout) begin
                // 12 -> 01
                r_tens <= 4'h0;
                r_units <= 4'h1;
            end else if(r_units == 4'h9) begin
                // 09 -> 10
                r_tens <= 4'h1;
                r_units <= 4'h0;
            end else begin
                r_units <= r_units + 1'h1;
            end
        end
    end
endmodule