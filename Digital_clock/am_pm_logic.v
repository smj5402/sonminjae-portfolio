`timescale 1ns/1ps
module am_pm_logic (
    input clk, rst_n,
    input min_carry,
    input [3:0] hour_tens,
    input [3:0] hour_units,
    //output [7:0] o_cnt,
    //input hour_carry,
    output am // am when am=1, pm when am=0;
);
    reg r_am;
    //wire o_cnt;
    
    assign am=r_am;
    //assign o_cnt = {tens, units};

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_am <= 1;
        end else if (min_carry && hour_tens == 4'h1 && hour_units == 4'h2) begin
            r_am <= ~r_am;
        end
    end

endmodule