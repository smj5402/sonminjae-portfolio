`timescale 1ns / 1ps
module tb_rv32i;

    logic clk, rst;
    rv32i_top U_RV32I (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        #20;

        rst = 0;

        // test start
        #200;
        $stop;
    end
endmodule
