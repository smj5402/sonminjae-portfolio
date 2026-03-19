module filter_sel (
    input  logic       clk,
    input  logic       reset,
    input  logic       vsync_edge,
    input  logic [8:0] sw,
    output logic       gamma_sel,
    output logic       histo_sel,
    output logic       median_sel,
    output logic       gaussian_sel,
    output logic       scharr_sel,
    output logic       erosion_sel,
    output logic       dilation_sel,
    output logic       temporal_sel,
    output logic       stretching_sel
);
    logic [8:0] filter_sel;
    assign {
        stretching_sel, // sw[8]
        temporal_sel,   // sw[7]
        dilation_sel,   // sw[6]
        erosion_sel,    // sw[5]
        scharr_sel,     // sw[4]
        gaussian_sel,   // sw[3]
        median_sel,     // sw[2]
        histo_sel,      // sw[1]
        gamma_sel       // sw[0]
        } = filter_sel;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            filter_sel <= 0;
        end else begin
            if (vsync_edge) begin
                filter_sel <= sw;
            end
        end
    end
endmodule
