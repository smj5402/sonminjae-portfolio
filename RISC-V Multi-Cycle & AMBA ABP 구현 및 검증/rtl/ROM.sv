`timescale 1ns / 1ps

module ROM (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:2**10-1];

    initial begin
        $readmemh("code.mem", rom);
        /*
        rom[0] = 32'h06400093;
        rom[1] = 32'h03200113;
        rom[2] = 32'h00000593;
        rom[3] = 32'h002081b3;
        rom[4] = 32'h40208233;
        rom[5] = 32'h0435a023;
        rom[6] = 32'h0445a223;
        rom[7] = 32'h0405a283;
        rom[8] = 32'h0445a303;
        */
    end

    assign data = rom[addr[31:2]];
endmodule
