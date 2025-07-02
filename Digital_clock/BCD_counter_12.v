`timescale 1ns/1ps

module BCD_counter_12 (
    input clk, rst_n,
    output [3:0] tens,
    output [3:0] units,
    //output [7:0] o_cnt,
    output cout
);
    reg [3:0] r_tens; // 0 ~ 1 
    reg [3:0] r_units; // 1 ~ 9 
    //wire [7:0] o_cnt;
    assign tens = r_tens;
    assign units = r_units;
    //assign o_cnt = {r_tens, r_units};
    assign cout = ((r_tens==4'h1)  && (r_units== 4'h2));
/*
    reg r_cout;
    assign cout = r_cout;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_cout <= 0;
        end else if((r_tens==4'h1)  && (r_units== 4'h2)) begin
            r_cout <= 1;
        end else begin
            r_cout <= 0;
        end
    end
*/
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // Start from 12
            r_tens <= 4'h1;
            r_units <= 4'h2;
        end else begin
            if (cout) begin
                r_tens <= 4'h0;
                r_units <= 4'h1;
            end else if(r_units == 4'h9) begin
                r_tens <= 4'h1;
                r_units <= 4'h0;
            end else begin
                r_units <= r_units + 1'h1;
            end
        end
    end
endmodule