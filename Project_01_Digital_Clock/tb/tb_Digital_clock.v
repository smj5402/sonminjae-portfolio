// tb_Digital_clock
// Testbench for Digital clock

`timescale 1ns/1ps

module tb_Digital_clock;
reg clk, rst_n;
wire [7:0] o_hour, o_min, o_sec;
wire is_am;
wire [3:0] sec_tens;
wire [3:0] sec_units;
wire [3:0] min_tens;
wire [3:0] min_units;
wire [3:0] hour_tens;
wire [3:0] hour_units;



assign o_hour = { hour_tens, hour_units};
assign o_min =  { min_tens, min_units};
assign o_sec =  { sec_tens, sec_units};

// Use small clock frequency for faster simulation 
localparam TB_CLK_FREQ = 100; // 1 second for 100 cycles
localparam PERIOD = 10;  // 24hours -> 100 cycles * 60 * 60 * 24  = 8,640,000 cycles

// Instantiate DUT
Digital_clock # (
    .CLK_FREQ       (TB_CLK_FREQ)
) i_digital_clock (
    .clk            (clk),
    .rst_n          (rst_n),
    .sec_tens       (sec_tens),
    .sec_units      (sec_units),
    .min_tens       (min_tens),
    .min_units      (min_units),
    .hour_tens      (hour_tens),
    .hour_units     (hour_units),
    .is_am          (is_am)
);

// clk gen
always #5 clk=~clk;

initial begin
    $display("Initialize values [%t]", $time);
    clk=0;
    rst_n=1;
    #100;

    $display("Reset [%t]", $time);
    rst_n=0;
    #10;
    rst_n=1;
 
    $display("Start Simulation [%t]", $time);
    #(100 * 60 * 60 * 24 * PERIOD);

    #1000;

    $display("Finish Simulation [%t]", $time);
    $finish;

end

endmodule