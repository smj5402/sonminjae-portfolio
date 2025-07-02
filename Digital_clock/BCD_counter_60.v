`timescale 1ns/1ps
module BCD_counter_60 (
    input clk, rst_n,
    output [3:0] tens,
    output [3:0] units,
    output cout
);
    reg [3:0] r_tens;
    reg [3:0] r_units;
    //wire [7:0] o_cnt;
    assign tens = r_tens;
    assign units = r_units;
    //assign o_cnt = { r_tens, r_units};
    
    //assign cout = (( r_tens == 4'd5) && (r_units == 4'd9));

    reg r_cout;
    assign cout = r_cout;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_cout<=0;
        end else if(( r_tens == 4'h5) && (r_units == 4'h9)) begin
            r_cout<=1;
        end else begin
            r_cout<=0;
        end
    end
    
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