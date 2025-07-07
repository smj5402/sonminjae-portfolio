// am_pm_logic
// This module toggles AM/PM at 12:00:00 (11:59:59 -> 12:00:00)
// am is HIGH during AM, low during PM
`timescale 1ns/1ps
module am_pm_logic (
    input clk, // 1Hz clock input
    input rst_n, // active low async reset
    input min_carry, // HIGH when minutes are 59 ( 59 -> 00)
    input [3:0] hour_tens, // BCD tens digit 
    input [3:0] hour_units, // BCD units digit
    output am // AM when am=1, PM when am=0;
);
    reg r_am;
    assign am=r_am;

    // Toggle AM/PM when hour is 12 and min_carry
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // Start from AM (initial value)
            r_am <= 1'b1;
        end else if (min_carry && hour_tens == 4'h1 && hour_units == 4'h2) begin
            r_am <= ~r_am;
        end
    end

endmodule