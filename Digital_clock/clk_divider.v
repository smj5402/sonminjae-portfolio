`timescale 1ns/1ps
module pulse_gen_1hz #( parameter 
        CLK_FREQ = 50_000_000) (
        input clk, rst_n,
        output pulse_1hz
        );
    
    parameter COUNT_MAX = CLK_FREQ;
    reg [$clog2(COUNT_MAX)-1 : 0] cnt;
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

assign pulse_1hz = r_pulse_1hz;
        
endmodule

/*
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