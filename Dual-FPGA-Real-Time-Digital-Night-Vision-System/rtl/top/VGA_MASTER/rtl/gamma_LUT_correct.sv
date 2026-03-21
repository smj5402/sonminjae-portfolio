`timescale 1ns / 1ps

module gamma_LUT_correct (
    input  logic       pclk,
    input  logic       reset,
    input  logic       valid_in,
    input  logic       vsync_edge,
    input  logic [7:0] pixel_pre,
    output logic       gamma_mode,
    output logic [7:0] corrected_pixel,
    output logic       valid_out,
    output logic       vsync_out
);

    logic [7:0] gamma_lut[0:511];

    initial begin
        $readmemh("gamma_combine.mem", gamma_lut);
    end

    logic [24:0] gamma_sum;

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            gamma_mode <= 1'b0;
            gamma_sum  <= 0;
        end else begin
            if (vsync_edge) begin
                if (gamma_sum < 25'd6_500_000) begin
                    gamma_mode <= 1'b1;
                end else if (gamma_sum > 25'd7_200_000) begin
                    gamma_mode <= 1'b0;
                end
                gamma_sum <= 0;
            end else if (valid_in) begin
                gamma_sum <= gamma_sum + pixel_pre;
            end
        end
    end

    assign corrected_pixel = gamma_lut[{gamma_mode, pixel_pre}];
    assign valid_out = valid_in;
    assign vsync_out = vsync_edge;
endmodule
