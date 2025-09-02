// BCD_counter_60
// This module counts from 0 to 59 for second and minute count in digital clock.
// Output cout goes HIGH for 1-cycle when counter is 59.

`timescale 1ns/1ps
module BCD_counter_60 (
    input clk, // 1Hz clock input
    input rst_n, // active-low async reset
    output [3:0] tens, // BCD tens digit 0~5
    output [3:0] units, // BCD units digit 0~9
    output cout // carry out 
);

    reg [3:0] r_tens;
    reg [3:0] r_units;
    reg r_cout;

    // Assignment output
    assign tens = r_tens;
    assign units = r_units;
    assign cout = r_cout;

    // Carry out logic : HIGH when count = 59
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_cout<=0;
        end else if(( r_tens == 4'h5) && (r_units == 4'h9)) begin
            r_cout<=1;
        end else begin
            r_cout<=0;
        end
    end
    
    // BCD counting logic  00 -> 59 -> 00
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_tens <= 4'h0;
            r_units <= 4'h0;
        end else begin
            if (r_units == 4'h9) begin
                r_units <= 4'h0;
                if(r_tens == 4'h5) begin
                    r_tens <= 4'h0;
                end else begin
                    r_tens <= r_tens + 1'h1;
                end
            end else begin
            r_units <= r_units + 1'h1;
            end
        end
    end
endmodule