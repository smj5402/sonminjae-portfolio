// pulse_gen_1hz
// This module generates a 1Hz pulse from a input clock
// The output pulse_1hz goes HIGH for one clock cycle every 1 sec
`timescale 1ns/1ps
module pulse_gen_1hz #( parameter 
        CLK_FREQ = 50_000_000 // input clock frequency (Hz)
        )(
        input clk, // system clock
        input rst_n, // active-low async reset
        output pulse_1hz // 1 cycle pulse signal
        );
    
    // Maximum count value to generate 1Hz pulse
    parameter COUNT_MAX = CLK_FREQ;

    // Counter to divide clk
    reg [$clog2(COUNT_MAX)-1 : 0] cnt;

    // Output pulse reg
    reg r_pulse_1hz;

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_pulse_1hz <= 1'b0;
            cnt <= 'b0;
        end else if (cnt == COUNT_MAX - 1) begin
            r_pulse_1hz <= 1'b1;
            cnt <= 'b0;
        end else begin
            cnt <= cnt + 1'b1;
            r_pulse_1hz <= 1'b0;
        end
    end

// Assign internal pulse to output
assign pulse_1hz = r_pulse_1hz;
        
endmodule

/*============================================================================
This module divides input clock to generate a 1Hz square wave with 50 % duty.
It can also be used to implement a digital clock.
In this project, I implemented the digital clock with pulse generator.
==============================================================================
`timescale 1ns/1ps
// for system clock 50MHz 
module clk_divider #( parameter 
        CLK_FREQ = 50_000_000 // 50MHz
    ) (
        input clk, rst_n,
        output clk_1hz
    );

    parameter COUNT_MAX = (CLK_FREQ /2);

    reg[ $clog2(COUNT_MAX)-1 : 0] cnt;
    reg r_clk_1hz;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 'b0;
            r_clk_1hz <= 1'b0;
        end else if( cnt == COUNT_MAX-1) begin
            cnt <= 0;
            r_clk_1hz <= !r_clk_1hz;
        end else begin
            cnt <= cnt+ 1'b1;
        end
    end     

assign clk_1hz = r_clk_1hz;

endmodule
*/