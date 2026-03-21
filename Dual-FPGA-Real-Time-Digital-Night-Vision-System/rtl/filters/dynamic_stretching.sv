`timescale 1ns / 1ps


module dynamic_stretching(
    input  logic        pclk,
    input  logic        reset,
    input  logic        valid_in,
    input  logic        vsync_edge,
    input  logic [7:0]  i_accumulated,
    output logic        valid_out,
    output logic        vsync_out,
    output logic [7:0]  o_stretched
    );

    //min max 추적
    logic [7:0] curr_min, curr_max;

    always_ff @(posedge pclk) begin
        if (reset || vsync_edge) begin
            curr_min <= 8'hFF;
            curr_max <= 8'h00;
        end else if(valid_in)begin
            if(i_accumulated < curr_min) curr_min <= i_accumulated;
            if(i_accumulated > curr_max) curr_max <= i_accumulated;
        end
    end
    // save frame
    logic [7:0] reg_min, reg_max;
    logic [8:0] diff;
    always_ff @(posedge pclk) begin
        if (reset) begin
            reg_min <= 8'h00;
            reg_max <= 8'hff;
        end else if(vsync_edge)begin
            reg_min <= curr_min;
            reg_max <= (curr_max == curr_min) ? (curr_max + 1) : curr_max;
        end
    end
    assign diff = reg_max - reg_min;

    //stretching calculate

    logic [7:0] sub_val;
    logic       v1,s1;
    always_ff @(posedge pclk) begin
            v1 <= valid_in;
            s1 <= vsync_edge;
            sub_val <= (i_accumulated <= reg_min) ? 8'd0 : (i_accumulated - reg_min);
    end

    //(input- min) * 255
    logic [15:0] mul_val;
    logic  v2,s2;

    always_ff @(posedge pclk) begin
            v2 <= v1;
            s2 <= s1;
            mul_val <= sub_val * 8'd255;
    end

    logic [15:0] div_val;
    always_ff @(posedge pclk) begin
        valid_out <= v2;
        vsync_out <= s2;
        
        // 나눗셈이 255가 넘지 않도록
        div_val <= mul_val / diff;
        o_stretched <= (div_val > 16'd255) ? 8'hFF : div_val[7:0];
    end

endmodule
