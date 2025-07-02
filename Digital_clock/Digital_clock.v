`timescale 1ns/1ps
module Digital_clock # (
    parameter CLK_FREQ = 50_000_000 )( // 50 MHz 
    input clk, rst_n,
    output [3:0] sec_tens,
    output [3:0] sec_units,
    output [3:0] min_tens,
    output [3:0] min_units,
    output [3:0] hour_tens,
    output [3:0] hour_units,
    output is_am
);

wire one_hz_pulse;
wire sec_carry;
wire min_carry;
wire hr_carry;

// clk
pulse_gen_1hz # (
    .CLK_FREQ (CLK_FREQ)
) i_clk_divider ( 
    .clk        (clk),
    .rst_n      (rst_n),
    .pulse_1hz  (one_hz_pulse)    
);

// second
BCD_counter_60 i_sec_counter (
    .clk        (one_hz_pulse),
    .rst_n      (rst_n),
    .tens       (sec_tens),
    .units      (sec_units),
    .cout       (sec_carry)
);

// minute
BCD_counter_60 i_min_counter (
    .clk        (sec_carry),
    .rst_n      (rst_n),
    .tens       (min_tens),
    .units      (min_units),
    .cout       (min_carry)
);

// hour
BCD_counter_12 i_hour_counter (
    .clk        (min_carry),
    .rst_n      (rst_n),
    .tens       (hour_tens),
    .units      (hour_units),
    .cout       (hr_carry)
);

// am/pm
am_pm_logic i_am_pm (
    .clk        (hr_carry),
    .rst_n      (rst_n),
    .min_carry  (min_carry),
    .hour_tens  (hour_tens),
    .hour_units (hour_units),
    //.hour_carry (hr_carry),
    .am         (is_am)
);
endmodule