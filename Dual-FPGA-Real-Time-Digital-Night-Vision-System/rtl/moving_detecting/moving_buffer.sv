`timescale 1ns / 1ps


module moving_buffer (
    input logic clk,
    input logic reset,
    input logic de,
    input logic [16:0] wAddr,
    input logic scharr_C,

    output logic pixel_C,
    output logic pixel_B,
    output logic pixel_A
);

    (* ram_style = "block" *) logic  ram0 [0:(320*240)-1];
    (* ram_style = "block" *) logic  ram1 [0:(320*240)-1];

    logic [16: 0] addr_reg ;
    logic    pixel_C_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_A <= 0;
            pixel_B <= 0;
            pixel_C <= 0;
            pixel_C_reg <= 0;
            addr_reg <= 0;
        end else begin
            if (de) begin
                addr_reg <= wAddr;
                pixel_C_reg <= scharr_C;  //방금 들어온

                pixel_C <= pixel_C_reg;
                pixel_B <= ram0[wAddr];  //덜 오래된
                pixel_A <= ram1[wAddr];  //제일 오래된

            end
        end
    end

    always_ff @(posedge clk) begin
        if (de) begin
            ram0[addr_reg] <= pixel_C_reg;
            ram1[addr_reg] <= ram0[wAddr];
        end
    end
endmodule
