// Digital clock
// Top module for 12 hour format digital clock with AM/PM

`timescale 1ns/1ps
module Digital_clock # (
    parameter CLK_FREQ = 50_000_000 )( // 50 MHz 
    input clk,   // system clock input
    input rst_n,  // active-low async reset
    output [3:0] sec_tens,
    output [3:0] sec_units,
    output [3:0] min_tens,
    output [3:0] min_units,
    output [3:0] hour_tens,
    output [3:0] hour_units,
    output is_am
);

// Internal wires for cout and 1Hz pulse
wire one_hz_pulse;
wire sec_carry;
wire min_carry;
wire hr_carry;

// 1Hz pulse generator from 50MHz
pulse_gen_1hz # (
    .CLK_FREQ (CLK_FREQ)
) i_clk_divider ( 
    .clk        (clk),
    .rst_n      (rst_n),
    .pulse_1hz  (one_hz_pulse)    
);

// Seconds counter 00 ~ 59
BCD_counter_60 i_sec_counter (
    .clk        (one_hz_pulse),
    .rst_n      (rst_n),
    .tens       (sec_tens),
    .units      (sec_units),
    .cout       (sec_carry)
);

// Minutes counter 00 ~ 59
BCD_counter_60 i_min_counter (
    .clk        (sec_carry),
    .rst_n      (rst_n),
    .tens       (min_tens),
    .units      (min_units),
    .cout       (min_carry)
);

// Hours counter 01 ~ 12
BCD_counter_12 i_hour_counter (
    .clk        (min_carry),
    .rst_n      (rst_n),
    .tens       (hour_tens),
    .units      (hour_units),
    .cout       (hr_carry)
);

// AM/PM logic
am_pm_logic i_am_pm (
    .clk        (hr_carry),
    .rst_n      (rst_n),
    .min_carry  (min_carry),
    .hour_tens  (hour_tens),
    .hour_units (hour_units),
    .am         (is_am)
);
endmodule